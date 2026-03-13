import EndpointSecurity
import Shared

public protocol AttributeComparator {
    associatedtype Attribute
    var extractor: (es_message_t) -> Attribute { get }
    
    subscript(comparator: String, message: es_message_t) -> (String) -> Bool { get }
}

public class StringComparator: AttributeComparator {
    public var extractor: (es_message_t) -> String
    
    init(extractor: @escaping (es_message_t) -> String) {
        self.extractor = extractor
    }
    
    public subscript(comparator: String, message: es_message_t) -> (String) -> Bool {
        let field = self.extractor(message)
        let handler = Self.apply(field: field, comparator: comparator)
        guard let handler else {
            SharedLog.fatal("Cannot find comparator for \(comparator) in \(Self.self)")
        }
        return handler
    }
    
    static func apply(field: String, comparator: String) -> ((String) -> Bool)? {
        return [
            "equals": { arg in
                field == arg
            },
            "ends": { arg in
                field.hasSuffix(arg)
            },
            "starts": { arg in
                field.hasPrefix(arg)
            },
            "contains": { arg in
                field.contains(arg)
            },
            "regex": { arg in
                let regex = try? Regex(arg)
                guard let regex else {
                    SharedLog.fatal("Cannot parse regex \(arg)")
                }
                return field.firstMatch(of: regex) != nil
            }
        ][comparator]
    }
}

public class StringArrayComparator: AttributeComparator {
    public var extractor: (es_message_t) -> [String]
    
    init(extractor: @escaping (es_message_t) -> [String]) {
        self.extractor = extractor
    }
    
    public subscript(comparator: String, message: es_message_t) -> (String) -> Bool {
        let field = self.extractor(message)
        let result = [
            "contains": { arg in
                field.contains(arg)
            },
            "containsInner": { arg in
                for item in field {
                    if item.contains(arg) {
                        return true
                    }
                }
                return false
            },
            "equals": { arg in
                if arg == "" {
                    field.isEmpty
                } else {
                    field == [arg]
                }
            },
        ][comparator] ?? StringComparator.apply(field: field.joined(separator: " "), comparator: comparator)
        guard let result else {
            SharedLog.fatal("Cannot find comparator for \(comparator) in \(Self.self)")
        }
        return result
    }
}
