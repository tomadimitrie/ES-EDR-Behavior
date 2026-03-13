import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct GenerateESEventNamesMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let pattern = #"(ES_EVENT_TYPE_[^,\s]+)"#
        let regex = try Regex(pattern)
        
        let matches = Array(Set(esTypes.matches(of: regex).map {
            String($0.output[1].substring!)
        }))
        
        var events = [ExprSyntax]()
        for element in matches {
            if element.hasSuffix("_LAST") {
                continue
            }
            if element.hasPrefix("ES_EVENT_TYPE_AUTH_") {
                continue
            }
            events.append("""
                .init(
                    heurName: \(literal: element.trimmingPrefix("ES_EVENT_TYPE_NOTIFY_")),
                    esValue: \(raw: element),
                    attrs: [:]
                )
            """)
        }
        
        return ["""
            let allEvents: [EventInfo] = \(ArrayExprSyntax(expressions: events))
        """]
    }
}

@main
struct CodegenMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        GenerateESEventNamesMacro.self
    ]
}
