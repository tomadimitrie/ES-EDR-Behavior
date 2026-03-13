import Foundation

public func getProcessPathByPid(_ pid: pid_t) -> String? {
    var buffer = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_SIZE))
    guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else {
        return nil
    }
    return String(cString: buffer)
}
