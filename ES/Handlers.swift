import Foundation
import EndpointSecurity
import Shared

class Handlers {
    static func processEvent(client: OpaquePointer, message: UnsafePointer<es_message_t>) {
        guard let info = ExtendedEventInfo.byEsValueExtended(message.pointee.event_type.rawValue) else {
            SharedLog.fatal("Cannot find event with value \(message.pointee.event_type.rawValue)")
        }
        
        let token = message.pointee.process.pointee.audit_token
        let data = Globals.shared.endpointSecurity.processInfo[token]
        
        var responded = false
        
        if message.pointee.action_type == ES_ACTION_TYPE_AUTH, data?.public.killedByEdr ?? false {
            switch info.type {
            case .authSimple:
                es_respond_auth_result(client, message, ES_AUTH_RESULT_DENY, false)
            case .authFlags:
                es_respond_flags_result(client, message, 0, false)
            default:
                SharedLog.fatal("Unexpected event type \(info)")
            }
            responded = true
        }
        
        es_retain_message(message)

        Task {
            if [ES_EVENT_TYPE_NOTIFY_EXEC, ES_EVENT_TYPE_AUTH_EXEC].contains(message.pointee.event_type) {
                handleExec(message: message.pointee)
            }
            
            if [ES_EVENT_TYPE_NOTIFY_EXIT].contains(message.pointee.event_type) {
                handleExit(message: message.pointee)
            }
            
            dispatch(message: message)
            
            if message.pointee.action_type == ES_ACTION_TYPE_AUTH, !responded {
                switch info.type {
                case .authSimple:
                    es_respond_auth_result(client, message, ES_AUTH_RESULT_ALLOW, false)
                case .authFlags:
                    es_respond_flags_result(client, message, 0xffffffff, false)
                default:
                    SharedLog.fatal("Unexpected event type \(info)")
                }
            }
        }
    }
}

func handleExit(message: es_message_t) {
    let event = message.event.exit
    let token = message.process.pointee.audit_token
    guard let data = Globals.shared.endpointSecurity.processInfo[token] else { return }
    data.public.exitCode = Int(event.stat)
    Globals.shared.xpc.handle.integratorProxy.processExited(token: token, exitCode: Int(event.stat))
}

func handleExec(message: es_message_t) {
    let event = message.event.exec
    let token = event.target.pointee.audit_token
    let pid = audit_token_to_pid(token)
    let parentToken = event.target.pointee.parent_audit_token
    let ppid = event.target.pointee.ppid
    let executable = String.fromEs(event.target.pointee.executable.pointee.path) ?? ""
    let bundleId = String.fromEs(event.target.pointee.signing_id) ?? ""
    let timestamp = message.time.tv_sec
    let parent = Globals.shared.endpointSecurity.processInfo[parentToken]
    
    let data = ProcessData(
        publicData: PublicProcessData(
            token: token,
            pid: Int(pid),
            parentToken: parentToken,
            ppid: Int(ppid),
            executable: executable,
            args: event.args,
            bundleId: bundleId,
            timestamp: timestamp,
        ),
        privateData: PrivateProcessData(
            parent: parent,
        )
    )
    
    parent?.private.children.append(data)

    Globals.shared.endpointSecurity.processInfo[token] = data
    Globals.shared.xpc.handle.integratorProxy.processCreated(data: data.public)
}

func dispatch(message: UnsafePointer<es_message_t>) {
    let isExec = [ES_EVENT_TYPE_NOTIFY_EXEC, ES_EVENT_TYPE_AUTH_EXEC].contains(message.pointee.event_type)
    
    let currentProcessToken = message.pointee.process.pointee.audit_token
    let currentProcess = Globals.shared.endpointSecurity.processInfo[currentProcessToken]
    
    let parentProcessToken = message.pointee.process.pointee.parent_audit_token
    let parentProcess = Globals.shared.endpointSecurity.processInfo[parentProcessToken]
    
    if isExec {
        guard parentProcess != nil else {
            return
        }
    } else {
        guard currentProcess != nil else {
            return
        }
    }
    
    if isExec {
        parentProcess!.private.messages.append(message)
    } else {
        currentProcess!.private.messages.append(message)
    }
    let targetProcess = if isExec {
        parentProcess!
    } else {
        currentProcess!
    }
    let result = HeuristicsPipeline.shared.pipe(message: message.pointee, processData: targetProcess)
    switch result {
    case .newHeur, .shouldKill:
        Globals.shared.xpc.handle.integratorProxy.processNewHeurs(
            token: targetProcess.public.token,
            heurs: targetProcess.public.heurs,
            points: targetProcess.public.points
        )
    default:
        ()
    }
    if case .shouldKill = result {
        targetProcess.public.killedByEdr = true
        Globals.shared.xpc.handle.integratorProxy.processKilled(token: targetProcess.public.token)
        let status = kill(pid_t(targetProcess.public.pid), 9)
        if status == 0 {
            SharedLog.success("Killed \(targetProcess.public.pid)")
        } else {
            SharedLog.error("Cannot kill \(targetProcess.public.pid): \(status), \(errno)")
        }
    }
}
