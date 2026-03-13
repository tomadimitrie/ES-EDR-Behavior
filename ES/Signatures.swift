import Foundation
import Yams
import EndpointSecurity
import Shared

class Signatures {
    static let shared = Signatures()
    
    private init() {}
    
    func parse() {
        do {
            let heuristics = Bundle.main.resourceURL!.appending(path: "/Signatures").appending(path: "/Heuristics")
            let enumerator = FileManager.default.enumerator(at: heuristics, includingPropertiesForKeys: nil)!
            let decoder = YAMLDecoder()
            
            Globals.shared.endpointSecurity.subscribedEvents.formUnion([
                Globals.shared.config.useAuthEventsWhenPossible ? ES_EVENT_TYPE_AUTH_EXEC : ES_EVENT_TYPE_NOTIFY_EXEC,
                ES_EVENT_TYPE_NOTIFY_EXIT
            ])
            
            SharedLog.info("\(extendedEventMapping)")

            for case let url as URL in enumerator {
                guard !(try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory!) else { continue }
                guard url.absoluteString.hasSuffix(".yml") else { continue }
                SharedLog.info("Parsing \(url.absoluteString)")
                let content = try String(contentsOf: url, encoding: .utf8)
                let heuristic = try decoder.decode(Heuristic.self, from: content)
                SharedLog.info("\(heuristic)")
                Globals.shared.endpointSecurity.heurs[heuristic.name] = heuristic
                for case let Heuristic.MatchItem.event(event) in heuristic.match {
                    guard let event = ExtendedEventInfo.byHeurNameExtended(event.name) else {
                        SharedLog.fatal("Cannot find event for \(event.name)")
                    }
                    Globals.shared.endpointSecurity.subscribedEvents.insert(event.esValue)
                }
            }
            
            let ret = es_subscribe(
                Globals.shared.endpointSecurity.client,
                Array(Globals.shared.endpointSecurity.subscribedEvents),
                UInt32(Globals.shared.endpointSecurity.subscribedEvents.count)
            )
            
            if ret != ES_RETURN_SUCCESS {
                throw NSError(domain: "", code: Int(ret.rawValue), userInfo: [NSLocalizedDescriptionKey: "Cannot subscribe"])
            }
            
            Globals.shared.xpc.handle.integratorProxy.subscribedTo(events: Globals.shared.endpointSecurity.subscribedEvents.map { $0.rawValue })
            for event in Globals.shared.endpointSecurity.subscribedEvents {
                guard let event = ExtendedEventInfo.byEsValueExtended(event.rawValue) else {
                    SharedLog.fatal("Cannot find event for \(event.rawValue)")
                }
                SharedLog.success("Subscribed to \(event.heurName)")
            }
        } catch {
            SharedLog.error(error.localizedDescription)
        }
    }
}
