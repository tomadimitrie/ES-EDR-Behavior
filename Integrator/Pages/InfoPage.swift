import SwiftUI
import Shared

struct InfoPage: View {
    @ObservedObject var esGlobal = Globals.shared.endpointSecurity
    @State var protectionMode: ProtectionMode?
    @State var protectionModePicker: ProtectionMode = .normal
    let protectionModeStrings = [
        nil: "unknown",
        ProtectionMode.normal: "normal",
        ProtectionMode.noKill: "no kill",
    ]
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Subscribed to:")) {
                    ForEach(self.esGlobal.subscribedEvents.map { $0.heurName }, id: \.self) { event in
                        Text(event)
                    }
                }
            }
            HStack {
                if self.protectionMode != nil {
                    Picker("Protection Mode", selection: self.$protectionModePicker) {
                        ForEach(ProtectionMode.allCases) { mode in
                            Text(self.protectionModeStrings[mode]!)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding()
        .onAppear {
            self.getCurrentProtectionMode()
        }
        .onChange(of: self.protectionModePicker) { oldValue, newValue in
            Globals.shared.xpc.handle.service.changeProtectionMode(to: newValue)
        }
    }
    
    func getCurrentProtectionMode() {
        Globals.shared.xpc.handle.service.getProtectionMode { mode in
            self.protectionMode = mode
        }
    }
}
