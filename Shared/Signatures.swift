import Foundation

public struct Heuristic: Codable {
    public enum MatchItem: Codable {
        public enum Threshold: Codable {
            public struct Total: Codable {
                public let amount: Int
                public let interval: Int?
                
                public init(amount: Int, interval: Int?) {
                    self.amount = amount
                    self.interval = interval
                }
            }
            
            case total(Total)
            
            enum CodingKeys: CodingKey {
                case total
            }
            
            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: Self.CodingKeys.self)
                if container.contains(.total) {
                    self = .total(try container.decode(Self.Total.self, forKey: .total))
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .total, in: container, debugDescription: "Invalid threshold")
                }
            }
        }
        
        public enum Restriction: Codable {
            case allOf([Restriction])
            case anyOf([Restriction])
            case notAllOf([Restriction])
            case notAnyOf([Restriction])
            case node(String, String)
            
            enum CodingKeys: String, CodingKey {
                case allOf = "allOf"
                case anyOf = "anyOf"
                case notAllOf = "!allOf"
                case notAnyOf = "!anyOf"
            }
            
            public init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: Self.CodingKeys.self)
                if container.contains(.allOf) {
                    self = .allOf(try container.decode([Self].self, forKey: .allOf))
                } else if container.contains(.anyOf) {
                    self = .anyOf(try container.decode([Self].self, forKey: .anyOf))
                } else if container.contains(.notAllOf) {
                    self = .notAllOf(try container.decode([Self].self, forKey: .notAllOf))
                } else if container.contains(.notAnyOf) {
                    self = .notAnyOf(try container.decode([Self].self, forKey: .notAnyOf))
                } else {
                    let rawContainer = try decoder.singleValueContainer()
                    let decoded = try rawContainer.decode([String: String].self)
                    self = .node(decoded.first!.key, decoded.first!.value)
                }
            }
        }
        
        public struct Event: Codable {
            public let name: String
            public let restrict: Restriction
            public let threshold: Threshold
            
            enum CodingKeys: CodingKey {
                case name
                case restrict
                case threshold
            }
            
            public init(name: String, restrict: Restriction, threshold: Threshold) {
                self.name = name
                self.restrict = restrict
                self.threshold = threshold
            }
        }
        
        public struct Heuristic: Codable {
            public let name: String
            public let threshold: Threshold
            
            public init(name: String, threshold: Threshold) {
                self.name = name
                self.threshold = threshold
            }
        }
        
        case event(Event)
        case heuristic(Heuristic)
        
        enum CodingKeys: CodingKey {
            case event
            case heuristic
        }
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: Self.CodingKeys.self)
            if container.contains(.event) {
                self = .event(try container.decode(Self.Event.self, forKey: .event))
            } else if container.contains(.heuristic) {
                self = .heuristic(try container.decode(Self.Heuristic.self, forKey: .heuristic))
            } else {
                throw DecodingError.dataCorruptedError(forKey: .event, in: container, debugDescription: "Event or heuristic needed")
            }
        }
    }
    
    public enum OnDuplicateHandler: String, Codable {
        case ignore
        case ignorePoints
        case add
    }
    
    public let name: String
    public let points: Int
    public let match: [MatchItem]
    public let onDuplicate: OnDuplicateHandler
    public let tags: [String]
    
    public init(name: String, points: Int, match: [MatchItem], onDuplicate: OnDuplicateHandler, tags: [String]) {
        self.name = name
        self.points = points
        self.match = match
        self.onDuplicate = onDuplicate
        self.tags = tags
    }
}

extension Heuristic: Equatable {
    static public func == (lhs: Heuristic, rhs: Heuristic) -> Bool {
        lhs.name == rhs.name
    }
}
