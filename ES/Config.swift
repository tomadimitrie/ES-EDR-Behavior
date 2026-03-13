import Foundation
import Yams
import Shared

class Config: Codable {
    let useAuthEventsWhenPossible: Bool
    
    static func parsed() -> Self {
        let file = Bundle.main.resourceURL!.appending(path: "/Signatures").appending(path: "/config.yml")
        let decoder = YAMLDecoder()
        guard let content = try? String(contentsOf: file, encoding: .utf8) else {
            SharedLog.fatal("Cannot read config file")
        }
        guard let decoded = try? decoder.decode(Self.self, from: content) else {
            SharedLog.fatal("Cannot decode config")
        }
        return decoded
    }
}
