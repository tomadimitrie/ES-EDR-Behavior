import SwiftUI
import Shared
import AppKit

struct ProcessPage: View {
    @ObservedObject var esGlobal = Globals.shared.endpointSecurity
    @State private var selectedItem: ProcessViewItem.ID?
    
    func coloredText(data: ProcessViewItem, content: () -> String) -> some View {
        let data = data.original
        var inner = Text(content())
        if data.killedByEdr {
            inner = inner.foregroundStyle(.red)
        } else if data.points > PublicProcessData.maxPoints {
            inner = inner.foregroundStyle(.orange)
        } else if data.exitCode != nil {
            inner = inner.foregroundStyle(.blue)
        } else if data.points > 0 {
            inner = inner.foregroundStyle(.yellow)
        }
        return inner
    }
    
    var processes: [ProcessViewItem] {
        let processes = self.esGlobal.processData.dict
            .map { $0.1 }
            .sorted {
                func sortCategory(_ item: PublicProcessData) -> Int {
                    if item.points > 0 {
                        return 0
                    } else if item.points == 0 && item.exitCode == nil {
                        return 1
                    } else {
                        return 2
                    }
                }
                
                let catA = sortCategory($0.original)
                let catB = sortCategory($1.original)
                
                if catA != catB {
                    return catA < catB
                }
                
                switch catA {
                case 0:
                    return $0.original.points > $1.original.points
                case 1, 2:
                    return $0.original.timestamp < $1.original.timestamp
                default:
                    return false
                }
            }
        
        return processes
    }
    
    var body: some View {
        VStack {
            Table(of: ProcessViewItem.self, selection: self.$selectedItem) {
                TableColumn("PID") { data in
                    self.coloredText(data: data) {
                        "\(data.original.pid)"
                    }
                }
                TableColumn("PPID") { data in
                    self.coloredText(data: data) {
                        "\(data.original.ppid)"
                    }
                }
                TableColumn("Executable") { data in
                    self.coloredText(data: data) {
                        data.original.executable
                    }
                }
                TableColumn("Bundle ID") { data in
                    self.coloredText(data: data) {
                        data.original.bundleId
                    }
                }
                TableColumn("Args") { data in
                    self.coloredText(data: data) {
                        data.original.args.joined(separator: ", ")
                    }
                }
                TableColumn("Created at") { data in
                    self.coloredText(data: data) {
                        Date(timeIntervalSince1970: Double(data.original.timestamp)).formatted(date: .complete, time: .complete)
                    }
                }
                TableColumn("Points") { data in
                    self.coloredText(data: data) {
                        "\(data.original.points)"
                    }
                }
                TableColumn("State") { data in
                    self.coloredText(data: data) {
                        if data.original.killedByEdr {
                            "Terminated"
                        } else if data.original.points > PublicProcessData.maxPoints {
                            "Awaiting termination"
                        } else if let exitCode = data.original.exitCode {
                            "Exited (\(exitCode))"
                        } else {
                            "Running"
                        }
                    }
                }
            } rows: {
                OutlineGroup(self.processes.filter { $0.parent == nil }, id: \.id, children: \.optionalChildren) { item in
                    TableRow(item)
                }
            }
            
            if let id = selectedItem, let item = self.esGlobal.processData[id] {
                VStack {
                    Text("Heuristics: ")
                        .font(.headline)
                    List(item.original.heurs, id: \.self) { heur in
                        Text("- \(heur)")
                    }
                }
            }
            
            Button("Export as JSON") {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let content = String(data: try! encoder.encode(Globals.shared.endpointSecurity.processData.dict.map { $0.1.original }), encoding: .utf8)!
                let panel = NSSavePanel()
                panel.title = "Export"
                panel.nameFieldStringValue = "processes.json"
                panel.begin { response in
                    if response == .OK, let url = panel.url {
                        try! content.write(to: url, atomically: true, encoding: .utf8)
                    }
                }
            }
        }
        .padding()
        .animation(.default, value: selectedItem)
    }
}
