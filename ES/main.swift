import EndpointSecurity
import Foundation
import Shared

Globals.shared.xpc.handle.setup()

let error = es_new_client(&Globals.shared.endpointSecurity.client, Handlers.processEvent)

guard error == ES_NEW_CLIENT_RESULT_SUCCESS else {
    SharedLog.error("Failed to create ES client: \(error.rawValue)")
    exit(EXIT_FAILURE)
}
SharedLog.success("Created new ES client")

Signatures.shared.parse()

dispatchMain()
