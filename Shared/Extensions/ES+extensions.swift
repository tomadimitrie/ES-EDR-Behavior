import EndpointSecurity

extension es_event_exec_t {
    public var args: [String] {
        withUnsafePointer(to: self) { event in
            let count = es_exec_arg_count(event)
            return (0..<count)
                .map {
                    es_exec_arg(event, $0)
                }
                .map(String.fromEs)
                .map { $0! }
        }
    }
    
    public var env: [String] {
        withUnsafePointer(to: self) { event in
            let count = es_exec_env_count(event)
            return (0..<count)
                .map {
                    es_exec_env(event, $0)
                }
                .map(String.fromEs)
                .map { $0! }
        }
    }
}

//extension audit_token_t: @retroactive Equatable {
//    public static func == (lhs: audit_token_t, rhs: audit_token_t) -> Bool {
//        let lhs = lhs.val
//        let rhs = rhs.val
//        return lhs.5 == rhs.5 &&
//               lhs.7 == rhs.7
//    }
//}
//
//extension audit_token_t: @retroactive Hashable {
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(self.val.0)
//        hasher.combine(self.val.1)
//        hasher.combine(self.val.2)
//        hasher.combine(self.val.3)
//        hasher.combine(self.val.4)
//        hasher.combine(self.val.5)
//        hasher.combine(self.val.6)
//        hasher.combine(self.val.7)
//    }
//}

//extension audit_token_t: @retroactive Codable {
//    public func encode(to encoder: any Encoder) throws {
//        var container = encoder.unkeyedContainer()
//        try container.encode(self.val.0)
//        try container.encode(self.val.1)
//        try container.encode(self.val.2)
//        try container.encode(self.val.3)
//        try container.encode(self.val.4)
//        try container.encode(self.val.5)
//        try container.encode(self.val.6)
//        try container.encode(self.val.7)
//    }
//    
//    public init(from decoder: any Decoder) throws {
//        var container = try decoder.unkeyedContainer()
//        self.init(val: (
//            try container.decode(UInt32.self),
//            try container.decode(UInt32.self),
//            try container.decode(UInt32.self),
//            try container.decode(UInt32.self),
//            try container.decode(UInt32.self),
//            try container.decode(UInt32.self),
//            try container.decode(UInt32.self),
//            try container.decode(UInt32.self),
//        ))
//    }
//}
//
extension audit_token_t {
    func toArray() -> [UInt32] {
        [
            self.val.0,
            self.val.1,
            self.val.2,
            self.val.3,
            self.val.4,
            self.val.5,
            self.val.6,
            self.val.7,
        ]
    }
    
    static func fromArray(_ array: [UInt32]) -> Self {
        Self(val: (
            array[0],
            array[1],
            array[2],
            array[3],
            array[4],
            array[5],
            array[6],
            array[7],
        ))
    }
}
