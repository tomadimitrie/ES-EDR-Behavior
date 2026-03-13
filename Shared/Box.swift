public class Box<T> {
    public let boxed: T
    
    public init(_ thing: T) {
        self.boxed = thing
    }
}
