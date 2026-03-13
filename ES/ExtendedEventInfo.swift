import EndpointSecurity
import Shared

extension EventInfo {
    var matchesConfig: Bool {
        if Globals.shared.config.useAuthEventsWhenPossible {
            self.type == .authSimple || self.type == .authFlags || self.type == .notifyOnly
        } else {
            self.type == .notify || self.type == .notifyOnly
        }
    }
}

public class ExtendedEventInfo: EventInfo {
    public var attrs: [String: any AttributeComparator]
    
    init(info: EventInfo, attrs: [String: any AttributeComparator]) {
        self.attrs = attrs
        super.init(heurName: info.heurName, esValue: info.esValue, type: info.type)
    }
    
    public static func byHeurNameExtended(_ heurName: String) -> ExtendedEventInfo? {
        extendedEventMapping.first { $0.heurName == heurName }
    }

    public static func byEsValueExtended(_ esValue: UInt32) -> ExtendedEventInfo? {
        extendedEventMapping.first { $0.esValue.rawValue == esValue }
    }
}

let attrsMapping: [String: [String: any AttributeComparator]] = [
    "EXEC": [
        "path": StringComparator { message in
            String.fromEs(message.event.exec.target.pointee.executable.pointee.path) ?? ""
        },
        "args": StringArrayComparator { message in
            message.event.exec.args
        },
        "env": StringArrayComparator { message in
            message.event.exec.env
        },
        "commandLine": StringComparator { message in
            message.event.exec.args.joined(separator: " ")
        },
        "parentPath": StringComparator { message in
            getProcessPathByPid(message.event.exec.target.pointee.ppid) ?? ""
        }
    ],
    "READDIR": [
        "path": StringComparator { message in
            String.fromEs(message.event.readdir.target.pointee.path) ?? ""
        },
    ],
    "OPEN": [
        "file": StringComparator { message in
            String.fromEs(message.event.open.file.pointee.path) ?? ""
        }
    ],
    "COPY": [
        "sourceFile": StringComparator { message in
            String.fromEs(message.event.copyfile.source.pointee.path) ?? ""
        },
    ],
    "WRITE": [
        "path": StringComparator { message in
            String.fromEs(message.event.write.target.pointee.path) ?? ""
        },
    ],
    "CHMOD": [
        "path": StringComparator { message in
            String.fromEs(message.event.setmode.target.pointee.path) ?? ""
        },
    ],
    "CHOWN": [
        "path": StringComparator { message in
            String.fromEs(message.event.setowner.target.pointee.path) ?? ""
        },
    ],
    "SETATTR": [
        "path": StringComparator { message in
            String.fromEs(message.event.setattrlist.target.pointee.path) ?? ""
        },
    ],
    "SETXATTR": [
        "path": StringComparator { message in
            String.fromEs(message.event.setextattr.target.pointee.path) ?? ""
        },
        "attr": StringComparator { message in
            String.fromEs(message.event.setextattr.extattr) ?? ""
        },
    ],
]

let extendedEventMapping: [ExtendedEventInfo] = eventMapping.filter {
    $0.matchesConfig
}.map {
    .init(info: $0, attrs: attrsMapping[$0.heurName] ?? [:])
}
