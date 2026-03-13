import Synchronization

public struct SafeDict<Key: Hashable, Value>: ~Copyable {
    private let dict = Mutex([Key: Value]())
    
    public init() {}
    
    public subscript(key: Key) -> Value? {
        get {
            self.dict.withLock {
                $0[key]
            }
        }
        set {
            self.dict.withLock {
                $0[key] = newValue
            }
        }
    }
    
    public func remove(_ key: Key) {
        _ = self.dict.withLock {
            $0.removeValue(forKey: key)
        }
    }
}
