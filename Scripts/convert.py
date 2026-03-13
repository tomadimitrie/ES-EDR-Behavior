import argparse
import glob
import os
import pprint
import re

from lark import Lark, Transformer
import ruamel.yaml
import ruamel.yaml.scalarstring

yaml = ruamel.yaml.YAML()
logsource_mapping = {
    "file_event": "OPEN",
    "process_creation": "EXEC",
}
attrs_mapping = {
    "file_event": {
        "TargetFilename": "file"  
    },
    "process_creation": {
        "Image": "path",
        "CommandLine": "commandLine",
        "ParentImage": "parentPath"
    },
}

comparator_mapping = {
    "equals": "equals",
    "contains": "contains",
    "startswith": "starts",
    "endswith": "ends",
    "re": "regex",
}

mitre = set()

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=str, default="../extern/sigma/rules/macos/")
    parser.add_argument("--destination", type=str, default="../Signatures/Heuristics/Sigma")
    return parser.parse_args()


def convert_condition(condition: str, data: dict) -> dict:
    print(condition)
    grammar = r"""
        start: expr

        ?expr: expr "or" term -> or_expr
            | expr "and" term -> and_expr
            | term

        ?term: "not" term -> not_expr
            | group
            | modifier
            | NAME -> simple_expr

        group: "(" expr ")" -> group

        modifier: ONE OF THEM -> one_of_them
            | ALL OF THEM -> all_of_them
            | ONE OF NAME -> one_of_pattern
            | ALL OF NAME -> all_of_pattern
        
        NAME: /[a-zA-Z_*][a-zA-Z0-9_*]*/
        ONE: "1"
        ALL: "all"
        OF: "of"
        THEM: "them"

        %import common.WS
        %ignore WS
    """

    class ConditionTransformer(Transformer):
        def NAME(self, name):
            return str(name)
        
        def group(self, args):
            return args[0]
        
        def simple_expr(self, args):
            return data[args[0]]
    
        def or_expr(self, args):
            return {"anyOf": args}
        
        def and_expr(self, args):
            return {"allOf": args}
        
        def not_expr(self, args):
            assert isinstance(args[0], dict)
            assert len(args[0]) == 1
            key, value = list(args[0].items())[0]
            return {f"!{key}": value}
        
        def one_of_them(self, _args):
            return {"anyOf": data.values()}

        def all_of_them(self, _args):
            return {'all_of': data.values()}

        def _all_matching(self, pattern: str) -> bool:
            assert pattern.endswith("*")
            pattern = pattern[:-1]
            return [value for key, value in data.items() if key.startswith(pattern)]

        def one_of_pattern(self, args):
            return {"anyOf": self._all_matching(args[2])}

        def all_of_pattern(self, args):
            return {"allOf": self._all_matching(args[2])}
        
    parser = Lark(grammar, parser="lalr", transformer=ConditionTransformer())
    parsed = parser.parse(condition)
    parsed = parsed.children[0]
    print(parsed)
    return parsed


def transform_match(key: str, value: str, event: str) -> dict:
    field, *others = key.split("|")
    comparator = others.pop(0) if len(others) > 0 else "equals"
    field = attrs_mapping[event][field]
    comparator = comparator_mapping[comparator]
    return {f"{field}+{comparator}": value}


def convert(source: str, destination: str):
    with open(source) as file:
        rule_str = file.read()
    rule = dict(yaml.load(rule_str))
    # pprint.pprint(rule)
    obj = {}
    obj["name"] = f"HEUR_{rule["title"].replace(' ', '_').upper()}"
    obj["points"] = 1
    obj["onDuplicate"] = "ignore"
    obj["tags"] = rule["tags"]

    for tag in rule["tags"]:
        group = re.search(r"attack.(t\d+(?:\.\d+)?)", tag)
        if group is not None:
            mitre.add(group.group(1))

    event = {}
    category = rule["logsource"]["category"]
    event["name"] = logsource_mapping[category]
    event["threshold"] = {"total": {"amount": 1}}

    condition = rule["detection"].pop("condition")
    selection_data = {}
    for selection_name, selection in rule["detection"].items():
        field_data = []
        aggregator = None
        if isinstance(selection, list) and all(isinstance(item, str) for item in selection):
            raise ValueError("Keyword-based selection not supported")
        if isinstance(selection, dict):
            aggregator = "allOf"
        elif isinstance(selection, list):
            aggregator = "anyOf"
            temp = {}
            for item in selection:
                if not (isinstance(item, dict) and len(item) == 1):
                    raise ValueError(f"This should be a dict with one entry but it's a {item}")
                temp |= item
            selection = temp
        else:
            raise ValueError(f"Why is this not a dict or list? {type(selection)}")
        for field, value in selection.items():
            if isinstance(value, str) or value is None:
                if value is None:
                    value = ""
                field_data.append(transform_match(field, value, category))
            elif isinstance(value, list):
                if field.endswith("|all"):
                    field = field[:-4]
                    this_aggregator = "allOf"
                else:
                    this_aggregator = "anyOf"
                inner = []
                for subvalue in value:
                    inner.append(transform_match(field, subvalue, category))
                field_data.append({this_aggregator: inner})
            else:
                raise ValueError(f"What? {type(value)}")
        selection_data[selection_name] = {aggregator: field_data}
    event["restrict"] = convert_condition(condition, selection_data)

    obj["match"] = [{"event": event}]
    event["_original_"] = ruamel.yaml.scalarstring.LiteralScalarString(rule_str)
    # pprint.pprint(obj, indent=4)
    with open(destination, "w") as file:
        yaml.dump(obj, file)


def main():
    args = parse_args()
    source = os.path.abspath(args.source)
    destination = os.path.abspath(args.destination)
    for file in glob.iglob(f"{source}/**/*.yml", recursive=True):
        convert(file, os.path.join(destination, os.path.basename(file)))

    print(f"{mitre = }")
    print(len(mitre))


if __name__ == "__main__":
    main()
