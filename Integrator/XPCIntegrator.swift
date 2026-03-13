import Foundation
import Shared
import EndpointSecurity

class XPCIntegrator: NSObject {
    var connection: NSXPCConnection!
    var service: XPCIntegratorToExtension!
    
    func setup() {
        SharedLog.info("setting up XPC...")
        self.connection = NSXPCConnection(machServiceName: kXPCDriver, options: .privileged)
        self.connection.remoteObjectInterface = NSXPCInterface(with: XPCIntegratorToExtension.self)
        self.connection.exportedInterface = NSXPCInterface(with: XPCExtensionToIntegrator.self)
        self.connection.exportedObject = self
        self.connection.setCodeSigningRequirement("identifier \"\(kExtensionBundleIdentifier)\" and anchor apple generic and certificate leaf[subject.OU] = \"\(kTeamID)\"")
        
        self.connection.interruptionHandler = {
            SharedLog.error("XPC interrupt")
        }
        
        self.connection.resume()
        
        self.service = connection.remoteObjectProxyWithErrorHandler { error in
            SharedLog.error("XPC error: \(error.localizedDescription)")
        } as? XPCIntegratorToExtension
        
        self.service.checkIn()
        
        SharedLog.success("XPC configured")
    }
}

extension XPCIntegrator: XPCExtensionToIntegrator {
    
    func checkIn() {
        SharedLog.success("Driver checked in")
    }
    
    func subscribedTo(events: [UInt32]) {
        for event in events {
            let esEvent = es_event_type_t(rawValue: event)
            let eventInfo = EventInfo.byEsValue(esEvent.rawValue)!
            Globals.shared.endpointSecurity.subscribedEvents.append(eventInfo)
        }
    }
    
    func processCreated(data: PublicProcessData) {
        let newProc = ProcessViewItem(data)
        let parent = Globals.shared.endpointSecurity.processData[data.parentToken]
        if let parent {
            parent.children.append(newProc)
            newProc.parent = parent
        }
        Globals.shared.endpointSecurity.processData[data.token] = newProc
    }
    
    func processUpdated(data: PublicProcessData) {
        Globals.shared.endpointSecurity.processData[data.token]?.original = data
    }
    
    func processExited(token: audit_token_t, exitCode: Int) {
        guard let proc = Globals.shared.endpointSecurity.processData[token] else { return }
        proc.original.exitCode = exitCode
    }
    
    func processNewHeurs(token: audit_token_t, heurs: [String], points: Int) {
        guard let proc = Globals.shared.endpointSecurity.processData[token] else { return }
        proc.original.heurs = heurs
        proc.original.points = points
    }
    
    func processKilled(token: audit_token_t) {
        guard let proc = Globals.shared.endpointSecurity.processData[token] else { return }
        proc.original.killedByEdr = true
    }
}
