import EndpointSecurity

public enum EventType {
    case notify
    case notifyOnly
    case authSimple
    case authFlags
}

open class EventInfo {
    public var heurName: String
    public var esValue: es_event_type_t
    public var type: EventType
    
    public init(heurName: String, esValue: es_event_type_t, type: EventType) {
        self.heurName = heurName
        self.esValue = esValue
        self.type = type
    }
    
    public static func byHeurName(_ heurName: String) -> EventInfo? {
        eventMapping.first { $0.heurName == heurName }
    }
    
    public static func byEsValue(_ esValue: UInt32) -> EventInfo? {
        eventMapping.first { $0.esValue.rawValue == esValue }
    }
}

extension EventInfo: CustomStringConvertible {
    public var description: String {
        "EventInfo(heurName: \(self.heurName), esValue: \(self.esValue), type: \(self.type))"
    }
}

public let eventMapping: [EventInfo] = [
    .init(heurName: "EXEC", esValue: ES_EVENT_TYPE_NOTIFY_EXEC, type: .notify),
    .init(heurName: "EXEC", esValue: ES_EVENT_TYPE_AUTH_EXEC, type: .authSimple),
    .init(heurName: "READDIR", esValue: ES_EVENT_TYPE_NOTIFY_READDIR, type: .notify),
    .init(heurName: "READDIR", esValue: ES_EVENT_TYPE_AUTH_READDIR, type: .authSimple),
    .init(heurName: "EXIT", esValue: ES_EVENT_TYPE_NOTIFY_EXIT, type: .notifyOnly),
    .init(heurName: "OPEN", esValue: ES_EVENT_TYPE_NOTIFY_OPEN, type: .notify),
    .init(heurName: "OPEN", esValue: ES_EVENT_TYPE_AUTH_OPEN, type: .authFlags),
    .init(heurName: "COPY", esValue: ES_EVENT_TYPE_NOTIFY_COPYFILE, type: .notify),
    .init(heurName: "COPY", esValue: ES_EVENT_TYPE_AUTH_COPYFILE, type: .authSimple),
    .init(heurName: "WRITE", esValue: ES_EVENT_TYPE_NOTIFY_WRITE, type: .notifyOnly),
    .init(heurName: "CHMOD", esValue: ES_EVENT_TYPE_NOTIFY_SETMODE, type: .notify),
    .init(heurName: "CHMOD", esValue: ES_EVENT_TYPE_AUTH_SETMODE, type: .authSimple),
    .init(heurName: "CHOWN", esValue: ES_EVENT_TYPE_NOTIFY_SETOWNER, type: .notify),
    .init(heurName: "CHOWN", esValue: ES_EVENT_TYPE_AUTH_SETOWNER, type: .authSimple),
    .init(heurName: "SETATTR", esValue: ES_EVENT_TYPE_NOTIFY_SETATTRLIST, type: .notify),
    .init(heurName: "SETATTR", esValue: ES_EVENT_TYPE_AUTH_SETATTRLIST, type: .authSimple),
    .init(heurName: "SETXATTR", esValue: ES_EVENT_TYPE_NOTIFY_SETEXTATTR, type: .notify),
    .init(heurName: "SETXATTR", esValue: ES_EVENT_TYPE_AUTH_SETEXTATTR, type: .authSimple),
]
