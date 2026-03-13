@objc public enum ProtectionMode: UInt32, CaseIterable, Identifiable {
    case normal
    case noKill
    
    public var id: Self { self }
}
