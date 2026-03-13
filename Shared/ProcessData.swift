import EndpointSecurity
import Foundation

@objc
open class PublicProcessData: NSObject, NSSecureCoding, Codable {
    public let token: audit_token_t
    public let pid: Int
    public let parentToken: audit_token_t
    public let ppid: Int
    public let executable: String
    public var args: [String]
    public let bundleId: String
    public let timestamp: Int
    public var points = 0
    public var heurs = [String]()
    public var exitCode: Int? = nil
    public var killedByEdr = false
    
    public static let maxPoints = 50

    public static var supportsSecureCoding: Bool {
        true
    }
    
    public required init?(coder: NSCoder) {
        self.token = .fromArray(coder.decodeArrayOfObjects(ofClass: NSNumber.self, forKey: "token")!.map { $0.uint32Value })
        self.pid = coder.decodeInteger(forKey: "pid")
        self.parentToken = .fromArray(coder.decodeArrayOfObjects(ofClass: NSNumber.self, forKey: "parentToken")!.map { $0.uint32Value })
        self.ppid = coder.decodeInteger(forKey: "ppid")
        self.executable = coder.decodeObject(of: NSString.self, forKey: "executable")! as String
        self.args = coder.decodeArrayOfObjects(ofClass: NSString.self, forKey: "args")!.map { $0 as String }
        self.bundleId = coder.decodeObject(of: NSString.self, forKey: "bundleId")! as String
        self.timestamp = coder.decodeInteger(forKey: "timestamp")
        self.points = coder.decodeInteger(forKey: "points")
        self.heurs = coder.decodeArrayOfObjects(ofClass: NSString.self, forKey: "heurs")!.map { $0 as String }
        if coder.containsValue(forKey: "exitCode") {
            self.exitCode = coder.decodeInteger(forKey: "exitCode")
        }
        self.killedByEdr = coder.decodeBool(forKey: "killedByEdr")
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(self.token.toArray().map { $0 as NSNumber } as NSArray, forKey: "token")
        coder.encode(self.pid as NSNumber, forKey: "pid")
        coder.encode(self.parentToken.toArray().map { $0 as NSNumber } as NSArray, forKey: "parentToken")
        coder.encode(self.ppid as NSNumber, forKey: "ppid")
        coder.encode(self.executable as NSString, forKey: "executable")
        coder.encode(self.args.map { $0 as NSString }, forKey: "args")
        coder.encode(self.bundleId as NSString, forKey: "bundleId")
        coder.encode(self.timestamp as NSNumber, forKey: "timestamp")
        coder.encode(self.points as NSNumber, forKey: "points")
        coder.encode(self.heurs.map { $0 as NSString } as NSArray, forKey: "heurs")
        if let exitCode = self.exitCode {
            coder.encode(exitCode as NSNumber, forKey: "exitCode")
        }
        coder.encode(self.killedByEdr, forKey: "killedByEdr")
    }
    
    @objc public init(
        token: audit_token_t,
        pid: Int,
        parentToken: audit_token_t,
        ppid: Int,
        executable: String,
        args: [String],
        bundleId: String,
        timestamp: Int
    ) {
        self.token = token
        self.pid = pid
        self.parentToken = parentToken
        self.ppid = ppid
        self.executable = executable
        self.args = args
        self.bundleId = bundleId
        self.timestamp = timestamp
    }
}

public class PrivateProcessData {
    public var messages = [UnsafePointer<es_message_t>]()
    public var parent: ProcessData?
    public var children = [ProcessData]()
    
    public init(parent: ProcessData?) {
        self.parent = parent
    }
}

public struct ProcessData {
    public var `public`: PublicProcessData
    public var `private`: PrivateProcessData
    
    public init(publicData: PublicProcessData, privateData: PrivateProcessData) {
        self.public = publicData
        self.private = privateData
    }
}

extension PublicProcessData: Identifiable {
    public var id: Int {
        self.pid
    }
}

extension ProcessData: Identifiable {
    public var id: Int {
        self.public.pid
    }
}

