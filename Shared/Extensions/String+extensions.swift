import Foundation
import EndpointSecurity

extension String {
    public static func fromSized(data: UnsafePointer<CChar>, length: Int) -> Self? {
        let data = Data(bytes: data, count: length)
        return String(data: data, encoding: .utf8)
    }
    
    public static func fromEs(_ data: es_string_token_t) -> Self? {
        Self.fromSized(data: data.data, length: data.length)
    }
}
