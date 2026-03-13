import Foundation
import SwiftUI
import EndpointSecurity
import SystemExtensions
import Shared

enum InstallerState: String {
    case checking = "Checking state"
    case installed = "Installed"
    case notInstalled = "Not installed"
    case installing = "Installing"
    case uninstalling = "Uninstalling"
    case awaitingApproval = "Awaiting approval"
    case error = "Error"
}

enum RequestType {
    case install
    case uninstall
}

class Installer: NSObject, ObservableObject {
    @Published var state: InstallerState = .checking
    @Published var messages = [AppMessage]()
    
    var currentRequest: OSSystemExtensionRequest? = nil
    var requestType: RequestType?

    func logMessage(_ message: AppMessage) {
        SharedLog.info(message.description)
        self.messages.append(message)
    }
    
    func check() {
        let task = Process()
        task.executableURL = URL(filePath: "/usr/bin/systemextensionsctl")
        task.arguments = ["list"]
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        guard let _ = try? task.run() else { return }
        guard let outputData = try? outputPipe.fileHandleForReading.readToEnd() else { return }
        guard let output = String(data: outputData, encoding: .utf8) else { return }
        
        let pattern = #"^\s*\*\s*\*\s*\#(kTeamID)\s*\#(kExtensionBundleIdentifier.replacingOccurrences(of: ".", with: #"\."#))"#
        guard let regex = try? Regex(pattern) else { return }
        
        var isEnabled = false
        
        for line in output.components(separatedBy: "\n") {
            if line.contains(regex) {
                isEnabled = true
            }
        }
        
        self.state = if isEnabled {
            .installed
        } else {
            .notInstalled
        }
    }
    
    func install() {
        guard currentRequest == nil else {
            self.logMessage(.init(message: "Another request is in progress", severity: .error))
            return
        }
        
        self.state = .installing
        self.logMessage(.init(message: "Beginning installation...", severity: .info))
        
        self.logMessage(.init(message: "Installing extension...", severity: .info))
        
        let request = OSSystemExtensionRequest.activationRequest(
            forExtensionWithIdentifier: kExtensionBundleIdentifier,
            queue: .main
        )
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
        self.currentRequest = request
        self.requestType = .install
        self.logMessage(.init(message: "Installation submitted", severity: .info))
    }
    
    func uninstall() {
        guard self.currentRequest == nil else {
            self.logMessage(.init(message: "Another request is in progress", severity: .error))
            return
        }
        
        self.state = .uninstalling
        self.logMessage(.init(message: "Beginning uninstallation...", severity: .info))
        let request = OSSystemExtensionRequest.deactivationRequest(
            forExtensionWithIdentifier: kExtensionBundleIdentifier,
            queue: .main
        )
        request.delegate = self
        OSSystemExtensionManager.shared.submitRequest(request)
        self.currentRequest = request
        self.requestType = .uninstall
        self.logMessage(.init(message: "Uninstallation submitted", severity: .info))
    }
}

extension Installer: OSSystemExtensionRequestDelegate {
    func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension ext: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        self.logMessage(.init(message: "Got upgrade request from \(existing.bundleVersion) to \(ext.bundleVersion)", severity: .info))
        
        return .replace
    }
    
    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        guard request === currentRequest else {
            self.logMessage(.init(message: "Request mismatch", severity: .error))
            return
        }
        
        let message = requestType == .install ? "Installed" : "Uninstalled"
        self.logMessage(.init(message: "\(message) successfully", severity: .success))
        self.state = if requestType == .install {
            .installed
        } else {
            .notInstalled
        }
        self.currentRequest = nil
        self.requestType = nil
        Globals.shared.xpc.handle.setup()
    }
    
    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        guard request === currentRequest else {
            self.logMessage(.init(message: "Request mismatch", severity: .error))
            return
        }
        
        let message = requestType == .install ? "Installation" : "Uninstallation"
        self.logMessage(.init(message: "\(message) failed with error: \((error as NSError).description)", severity: .error))
        self.currentRequest = nil
        self.state = .error
        self.requestType = nil
    }
    
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        guard request === currentRequest else {
            self.logMessage(.init(message: "Request mismatch", severity: .error))
            return
        }
        
        self.logMessage(.init(message: "Awaiting approval...", severity: .info))
        self.state = .awaitingApproval
    }
}
