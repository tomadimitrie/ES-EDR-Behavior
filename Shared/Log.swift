import os.log
import Foundation

public struct SharedLog {
    public static func fatal(_ message: String) -> Never {
        Self.error(message)
        fatalError(message)
    }
    
    public static func error(_ message: String) {
        os_log("[-] %{public}s", type: .error, message)
        os_log("%{public}s", Thread.callStackSymbols.joined(separator: "\n"))
    }
    
    public static func info(_ message: String) {
        os_log("[*] %{public}s", message)
    }
    
    public static func success(_ message: String) {
        os_log("[+] %{public}s", message)
    }
}
