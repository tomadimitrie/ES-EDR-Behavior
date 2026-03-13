import Foundation
import EndpointSecurity
import Shared
import SwiftUI
import Darwin

class ProcessViewItem {
    var children = [ProcessViewItem]()
    var parent: ProcessViewItem?
    var original: PublicProcessData
    
    init(_ data: PublicProcessData) {
        self.original = data
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}

extension ProcessViewItem {
    var optionalChildren: [ProcessViewItem]? {
        if self.children.isEmpty {
            nil
        } else {
            self.children
        }
    }
}

extension ProcessViewItem: Identifiable {
    var id: audit_token_t {
        self.original.token
    }
}

struct ProcessStore {
    var dict = [audit_token_t: ProcessViewItem]()
    
    subscript(token: audit_token_t) -> ProcessViewItem? {
        get {
            self.dict[token]
        }
        set {
            self.dict[token] = newValue
        }
    }
    
    func unsafeLookupByPid(_ pid: pid_t) -> ProcessViewItem? {
        self.dict
            .map { $0.value }
            .filter { $0.original.pid == pid }
            .sorted { $0.original.timestamp > $1.original.timestamp }
            .first
    }
    
    mutating func clear() {
        self.dict.removeAll()
    }
}

extension Array where Element == ProcessViewItem {
    var allPoints: Int {
        self.map { $0.original.points }.reduce(0, +)
    }
    
    var allHeurs: Set<String> {
        Set(self.map { $0.original.heurs }.reduce([], +))
    }
}

class Globals: ObservableObject {
    static let shared = Globals()
    
    private init() {}
    
    class EndpointSecurity: ObservableObject {
        @Published var subscribedEvents = [EventInfo]()
        @Published var processData = ProcessStore()
    }
    @Published var endpointSecurity = EndpointSecurity()
    
    class XPC {
        let handle = XPCIntegrator()
    }
    let xpc = XPC()
}
