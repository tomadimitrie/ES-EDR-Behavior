import SwiftUI

func enumFolder(name: String) -> [String] {
    try! FileManager.default.contentsOfDirectory(atPath: name)
}

struct ContentView: View {
    @State private var allApps = [String: String?]()
    
    var body: some View {
        HStack {
            VStack {
                Button("HEUR_ENUM_APPS") {
                    let apps = enumFolder(name: "/Applications")
                    for app in apps {
                        self.allApps.updateValue(nil, forKey: app)
                    }
                }
                Button("HEUR_INSPECT_ENTITLEMENTS") {
                    Task {
                        for (app, _) in self.allApps {
                            do {
                                let task = Process()
                                task.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
                                task.arguments = ["-d", "--entitlements", "-", "--xml", "/Applications/\(app)"]
                                let stdout = Pipe()
                                task.standardOutput = stdout
                                try task.run()
                                task.waitUntilExit()
                                let outputData = stdout.fileHandleForReading.availableData
                                let output = String(decoding: outputData, as: UTF8.self)
                                await MainActor.run {
                                    self.allApps[app] = output
                                }
                            } catch {
                                print(error)
                            }
                        }
                    }
                }
            }
            List(Array(self.allApps), id: \.key) { app, entitlements in
                VStack {
                    Text(app)
                    if let entitlements {
                        Text(entitlements)
                    }
                }
            }
            .padding()
        }
        .padding()
    }
}
