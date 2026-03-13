import Foundation
import SwiftUI

let glyphs: [AppMessage.Severity: String] = [
    .info: "ℹ️",
    .error: "❌",
    .success: "✅",
    .warning: "⚠️"
]

struct AppMessage {
    enum Severity {
        case info
        case error
        case warning
        case success
    }
    
    let message: String
    let severity: Severity
    
    init(message: String, severity: Severity) {
        self.message = message
        self.severity = severity
    }
}

extension AppMessage: CustomStringConvertible {
    var description: String {
        "\(glyphs[self.severity]!) \(self.message)"
    }
}

struct DebugView: View {
    @Binding var messages: [AppMessage]
    
    var body: some View {
        List(Array(messages.map { $0.description }.enumerated()), id: \.1.self) { index, message in
            Text(message)
                .textSelection(.enabled)
        }
    }
}
