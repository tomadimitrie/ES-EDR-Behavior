import Foundation
import EndpointSecurity
import Shared

class Globals {
    static let shared = Globals()
    
    private init() {}
    
    class EndpointSecurity {
        public var client: OpaquePointer!
        public var subscribedEvents = Set<es_event_type_t>()
        public var processInfo = SafeDict<audit_token_t, ProcessData>()
        public var heurs = [String: Heuristic]()
        public var protectionMode = ProtectionMode.normal
    }
    
    let endpointSecurity = EndpointSecurity()
    
    class XPC {
        public let handle = XPCExtension()
    }
    
    let xpc = XPC()
    
    let config = Config.parsed()
}

