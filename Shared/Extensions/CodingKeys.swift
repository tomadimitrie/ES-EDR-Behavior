import Foundation

public struct StringCodingKey: CodingKey {
    public var stringValue: String
    public var intValue: Int?

    public init?(intValue: Int) {
        nil
    }
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
    }
}
