import Foundation
import EndpointSecurity
import Shared

@objc class XPCExtension: NSObject {
    var connection: NSXPCConnection?
    var integratorProxy: XPCExtensionToIntegrator!
    var bundles = [String: String]()
    
    func setup() {
        SharedLog.info("setting up XPC")
        let listener = NSXPCListener(machServiceName: kXPCDriver)
        listener.delegate = self
        listener.resume()
        SharedLog.success("XPC configured")
    }
}

extension XPCExtension: NSXPCListenerDelegate {
    func listener(
        _ listener: NSXPCListener,
        shouldAcceptNewConnection newConnection: NSXPCConnection
    ) -> Bool {
        SharedLog.info("Accepting new XPC connection")
        newConnection.exportedInterface = NSXPCInterface(with: XPCIntegratorToExtension.self)
        newConnection.exportedObject = self
        newConnection.remoteObjectInterface = NSXPCInterface(with: XPCExtensionToIntegrator.self)
        newConnection.setCodeSigningRequirement("identifier \"\(kIntegratorBundleIdentifier)\" and anchor apple generic and certificate leaf[subject.OU] = \"\(kTeamID)\"")
        
        newConnection.resume()
        
        self.integratorProxy = newConnection.remoteObjectProxyWithErrorHandler { error in
            SharedLog.error("error in listen: \(error.localizedDescription)")
        } as? XPCExtensionToIntegrator
       
        self.integratorProxy.checkIn()
        return true
    }
}

extension XPCExtension: XPCIntegratorToExtension {
    func checkIn() {
        SharedLog.success("Client checked in")
    }
    
    func getProtectionMode(handler: @escaping (ProtectionMode) -> Void) {
        handler(Globals.shared.endpointSecurity.protectionMode)
    }
    
    func changeProtectionMode(to: ProtectionMode) {
        Globals.shared.endpointSecurity.protectionMode = to
        SharedLog.success("Changed protection mode to \(to)")
    }
}
