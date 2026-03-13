import Foundation
import EndpointSecurity


@objc(XPCIntegratorToExtension)
public protocol XPCIntegratorToExtension {
    func checkIn()
    func getProtectionMode(handler: @escaping (ProtectionMode) -> Void)
    func changeProtectionMode(to: ProtectionMode)
}

@objc(XPCExtensionToIntegrator)
public protocol XPCExtensionToIntegrator {
    func checkIn()
    func subscribedTo(events: [UInt32])
    func processCreated(data: PublicProcessData)
    func processExited(token: audit_token_t, exitCode: Int)
    func processNewHeurs(token: audit_token_t, heurs: [String], points: Int)
    func processKilled(token: audit_token_t)
}
