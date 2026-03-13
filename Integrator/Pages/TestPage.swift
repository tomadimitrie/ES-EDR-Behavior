import SwiftUI
import Yams
import Shared

let kAtomicRepoPath = "/tmp/atomic-red-team/atomics"

struct Atomic: Codable {
    struct Test: Codable {
        struct Executor: Codable {
            let command: String?
            let cleanup_command: String?
        }
        
        struct InputArg: Codable {
            let `default`: String
            let type: String
            
            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: Self.CodingKeys.self)
                self.type = try container.decode(String.self, forKey: .type).lowercased()
                if let valueStr = try? container.decode(String.self, forKey: .default) {
                    self.default = valueStr
                } else {
                    switch self.type {
                    case "string", "path", "url":
                        SharedLog.fatal("Should have already been parsed")
                    case "integer":
                        let value = try container.decode(Int.self, forKey: .default)
                        self.default = String(value)
                    case "float":
                        let value = try container.decode(Double.self, forKey: .default)
                        self.default = String(value)
                    default:
                        SharedLog.fatal("Invalid type \(self.type)")
                    }
                }
            }
        }
        
        struct Dependency: Codable {
            let description: String
            let prereq_command: String?
            let get_prereq_command: String
        }
        
        var name: String
        let supported_platforms: [String]
        let executor: Executor
        let input_arguments: [String: InputArg]?
        let dependencies: [Dependency]?
        let disabled: Bool?
    }
    
    let attack_technique: String
    let display_name: String
    var atomic_tests: [Test]
    let disabled: Bool?
}

struct TestPage: View {
    @State var atomics = [Atomic]()
    
    func parseRepo() {
        Task {
            do {
                let fileManager = FileManager.default
                let items = try fileManager.contentsOfDirectory(atPath: kAtomicRepoPath)
                let yaml = YAMLDecoder()
                for item in items.sorted() where item.starts(with: "T") {
                    let content = try String(contentsOf: URL(fileURLWithPath: "\(kAtomicRepoPath)/\(item)/\(item).yaml"), encoding: .utf8)
                    var decoded = try yaml.decode(Atomic.self, from: content)
                    if decoded.disabled ?? false {
                        continue
                    }
                    
                    decoded.atomic_tests = decoded.atomic_tests
                        .filter {
                            !($0.disabled ?? false) &&
                            $0.supported_platforms.contains("macos") &&
                            $0.executor.command != nil
                        }
                        .enumerated()
                        .map { index, test in
                            var test = test
                            test.name = "\(index + 1). \(test.name)"
                            return test
                        }
                    
                    if decoded.atomic_tests.isEmpty {
                        continue
                    }
                    await MainActor.run {
                        self.atomics.append(decoded)
                    }
                }
            } catch let error as NSError {
                SharedLog.error(error.debugDescription)
            }
        }
    }
    
    var body: some View {
        AllAtomicsView(AllAtomicsViewModel(self.atomics))
            .padding()
            .onFirstAppear {
                self.parseRepo()
            }
    }
}

@Observable
class AllAtomicsViewModel {
    let atomicModels: [AtomicViewModel]
    
    init(_ atomics: [Atomic]) {
        self.atomicModels = atomics.map { .init($0) }
    }
    
    func run() async {
        for atomic in self.atomicModels {
            await atomic.run()
        }
    }
}

struct AllAtomicsView: View {
    @Bindable var viewModel: AllAtomicsViewModel
    @State private var scrollTo: String?
    
    init(_ model: AllAtomicsViewModel) {
        self.viewModel = model
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Button("Run all") {
                Task {
                    await self.viewModel.run()
                }
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 15)]) {
                ForEach(self.viewModel.atomicModels, id: \.atomic.attack_technique) { atomic in
                    Button {
                        self.scrollTo = nil
                        self.scrollTo = atomic.atomic.attack_technique
                    } label: {
                        Text(atomic.atomic.attack_technique)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(self.viewModel.atomicModels, id: \.atomic.attack_technique) { atomic in
                            AtomicView(atomic)
                                .id(atomic.atomic.attack_technique)
                            Divider()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .onChange(of: self.scrollTo) { old, new in
                    if let new {
                        withAnimation {
                            proxy.scrollTo(new, anchor: .top)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

@Observable
class AtomicViewModel {
    let atomic: Atomic
    let testModels: [TestViewModel]
    
    var state: CommandState {
        let states = self.testModels.map(\.state)
        if states.contains(.unknown) {
            return .unknown
        }
        if states.contains(.failed) {
            return .failed
        }
        return .succeeded
    }
    
    init(_ atomic: Atomic) {
        self.atomic = atomic
        self.testModels = atomic.atomic_tests.map { .init($0) }
    }
    
    func run() async {
        for test in self.testModels {
            await test.run()
        }
    }
}

struct AtomicView: View {
    @Bindable var viewModel: AtomicViewModel
    
    init(_ model: AtomicViewModel) {
        self.viewModel = model
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(self.viewModel.atomic.attack_technique)
                    .font(.largeTitle)
                    .textSelection(.enabled)
                Button("Run") {
                    Task {
                        await self.viewModel.run()
                    }
                }
            }
            VStack(alignment: .leading, spacing: 15) {
                ForEach(self.viewModel.testModels, id: \.test.name) { test in
                    TestView(test)
                }
            }
        }
        .padding(15)
        .background(self.viewModel.state.color.tune(brightness: -0.5))
        .clipShape(.rect(cornerRadius: 15))
    }
}

@Observable
class TestViewModel {
    let test: Atomic.Test
    let commandModel: CommandPaneModel
    let cleanupModel: CommandPaneModel?
    let depModels: [DependencyViewModel]
    var isExpanded = false

    var state: CommandState {
        let states = [
            self.commandModel.state,
//            self.cleanupModel?.state ?? .succeeded
        ] //+ self.depModels.map(\.state)
        if states.contains(.unknown) {
            return .unknown
        }
        if states.contains(.failed) {
            return .failed
        }
        return .succeeded
    }
    
    init(_ test: Atomic.Test) {
        self.test = test
        
        let args = self.test.input_arguments
        self.commandModel = .init(command: self.test.executor.command!, args: args) { model in
            guard model.exitCode != nil else {
                return .unknown
            }
            return model.processes.allHeurs.isEmpty ? .failed : .succeeded
        }
        if let cleanup = self.test.executor.cleanup_command {
            self.cleanupModel = .init(command: cleanup, args: args) { model in
                guard let exitCode = model.exitCode else {
                    return .unknown
                }
                return exitCode == 0 ? .succeeded : .failed
            }
        } else {
            self.cleanupModel = nil
        }
        self.depModels = (self.test.dependencies ?? []).map { dep in
            .init(
                description: dep.description.trimmingCharacters(in: .whitespacesAndNewlines),
                checker: { (dep: Atomic.Test.Dependency) -> CommandPaneModel? in
                    guard let checker = dep.prereq_command else {
                        return nil
                    }
                    return .init(command: checker, args: args) { model in
                        guard model.exitCode != nil else {
                            return .unknown
                        }
                        return .succeeded
                    }
                }(dep),
                runner: .init(command: dep.get_prereq_command, args: args) { model in
                    guard let exitCode = model.exitCode else {
                        return .unknown
                    }
                    return exitCode == 0 ? .succeeded : .failed
                }
            )
        }
    }
    
    func run() async {
        self.isExpanded = true
        for dep in self.depModels {
            await dep.run()
        }
        await self.commandModel.run()
        await self.cleanupModel?.run()
        self.isExpanded = false
    }
}

struct TestView: View {
    @Bindable var viewModel: TestViewModel
    
    init(_ model: TestViewModel) {
        self.viewModel = model
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: self.$viewModel.isExpanded) {
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading) {
                    if let args = self.viewModel.test.input_arguments {
                        ForEach(Array(args), id: \.key) { name, value in
                            HStack {
                                Text(name)
                                TextField(name, text: .constant(value.default))
                            }
                        }
                    }
                }
                .padding(.leading, 10)
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(self.viewModel.depModels, id: \.description) { dep in
                        VStack(alignment: .leading) {
                            DependencyView(model: dep)
                        }
                    }
                    
                    CommandPane("Command:", self.viewModel.commandModel)
                    if let cleanupModel = self.viewModel.cleanupModel {
                        CommandPane("Cleanup", cleanupModel)
                    }
                }
            }
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    Text(self.viewModel.test.name)
                        .font(.title)
                        .textSelection(.enabled)
                    Button("Run") {
                        Task {
                            await self.viewModel.run()
                        }
                    }
                }
                if !self.viewModel.commandModel.processes.isEmpty {
                    Text("Points: \(self.viewModel.commandModel.processes.allPoints)")
                    Text("Heurs: \(self.viewModel.commandModel.processes.allHeurs.joined(separator: ", "))")
                }
            }
            .padding(.leading, 5)
            .padding(.bottom, 5)
        }
        .padding(15)
        .background(self.viewModel.state.color.tune(brightness: -0.55))
        .clipShape(.rect(cornerRadius: 15))
    }
}

@Observable
class DependencyViewModel {
    let description: String
    let checker: CommandPaneModel?
    let runner: CommandPaneModel
    
    var state: CommandState {
        var states = [
            self.checker?.state ?? .succeeded,
        ]
        if self.checker == nil || (self.checker!.exitCode != nil && self.checker!.exitCode != 0) {
            states.append(self.runner.state)
        }
        if states.contains(.unknown) {
            return .unknown
        }
        if states.contains(.failed) {
            return .failed
        }
        return .succeeded
    }
    
    init(description: String, checker: CommandPaneModel? = nil, runner: CommandPaneModel) {
        self.description = description
        self.checker = checker
        self.runner = runner
    }
    
    func run() async {
        var runDep = true
        if let checker = self.checker {
            await checker.run()
            if checker.exitCode == 0 {
                runDep = false
            }
        }
        if runDep {
            await self.runner.run()
        }
    }
}

struct DependencyView: View {
    @Bindable var viewModel: DependencyViewModel
    
    init(model: DependencyViewModel) {
        self.viewModel = model
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Dependency: \(self.viewModel.description)")
                    .bold()
                    .font(.title2)
                Button("Run") {
                    Task {
                        await self.viewModel.run()
                    }
                }
            }
            Group {
                if let checker = self.viewModel.checker {
                    CommandPane("Checker:", checker)
                }
                CommandPane("Runner", self.viewModel.runner)
            }
        }
        .padding(15)
        .background(self.viewModel.state.color.tune(brightness: -0.6))
        .clipShape(.rect(cornerRadius: 15))
    }
}

enum CommandState {
    case succeeded
    case failed
    case unknown
    
    var color: Color {
        switch self {
        case .succeeded:
            .green
        case .failed:
            .red
        case .unknown:
            .yellow
        }
    }
}

@Observable
class CommandPaneModel {
    let command: String
    let args: [String: Atomic.Test.InputArg]?
    let stateFunc: (CommandPaneModel) -> CommandState
    var stdout: String?
    var stderr: String?
    var exitCode: Int32?
    var isRunning = false
    var processes = [ProcessViewItem]()
    
    var state: CommandState {
        self.stateFunc(self)
    }
    
    var resolvedCommand: String {
        var command = self.command
        
        if let args = self.args {
            for (key, value) in args {
                command = command.replacingOccurrences(of: "#{\(key)}", with: value.default)
            }
        }
        command = command.replacingOccurrences(of: "$PathToAtomicsFolder", with: kAtomicRepoPath)
        command = command.replacingOccurrences(of: "PathToAtomicsFolder", with: kAtomicRepoPath)
        command = command.replacingOccurrences(of: "AtomicRedTeam", with: "atomic-red-team")

        return command
    }
    
    init(command: String, args: [String: Atomic.Test.InputArg]?, stateFunc: @escaping (CommandPaneModel) -> CommandState) {
        self.command = command
        self.args = args
        self.stateFunc = stateFunc
    }
    
    func run() async {
        self.isRunning = true
        do {
            Globals.shared.endpointSecurity.processData.clear()
            
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
            let finalCommand = "export PATH=\"/opt/homebrew/bin:$PATH\"\n" + self.resolvedCommand
            let scriptPath = "/tmp/run.sh"
            try finalCommand.write(to: URL(filePath: scriptPath, directoryHint: .notDirectory), atomically: true, encoding: .utf8)
            task.arguments = [scriptPath]
            task.currentDirectoryURL = .init(filePath: "/tmp", directoryHint: .isDirectory)
            
            let stdout = Pipe()
            task.standardOutput = stdout
            
            let stderr = Pipe()
            task.standardError = stderr
            
            try task.run()
            task.waitUntilExit()
            
            let outputData = stdout.fileHandleForReading.availableData
            let output = String(decoding: outputData, as: UTF8.self)
            
            let errorData = stderr.fileHandleForReading.availableData
            let error = String(decoding: errorData, as: UTF8.self)
            
            try await Task.sleep(for: .seconds(2))

            await MainActor.run {
                self.stdout = output
                self.stderr = error
                self.exitCode = task.terminationStatus
                self.isRunning = false
                self.processes = Globals.shared.endpointSecurity.processData.dict.map { $0.value }
            }
        } catch let error as NSError {
            SharedLog.error(error.debugDescription)
            await MainActor.run {
                self.isRunning = true
            }
        }
    }
}

struct CommandPane: View {
    let name: String
    @Bindable var viewModel: CommandPaneModel
    
    init(_ name: String, _ model: CommandPaneModel) {
        self.name = name
        self.viewModel = model
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(self.name)
                .bold()
                .font(.title2)
            TextEditor(text: .constant(self.viewModel.command))
            TextEditor(text: .constant(self.viewModel.resolvedCommand))
            HStack {
                Button("Run") {
                    Task {
                        await self.viewModel.run()
                    }
                }
                .disabled(self.viewModel.isRunning)
                
                if self.viewModel.isRunning {
                    ProgressView()
                }
            }
            
            if !self.viewModel.processes.isEmpty {
                Text("PIDs: \(self.viewModel.processes.map(\.original.pid).map { String($0) }.joined(separator: ", ")))")
            }
            if let exitCode = self.viewModel.exitCode {
                Text("Exit code: \(exitCode)")
            }
            if let stdout = Binding<String>(self.$viewModel.stdout) {
                Text("Stdout:")
                TextEditor(text: stdout)
            }
            if let stderr = Binding<String>(self.$viewModel.stderr) {
                Text("Stderr:")
                TextEditor(text: stderr)
            }
        }
        .padding(15)
        .background(self.viewModel.state.color.tune(brightness: -0.65))
        .clipShape(.rect(cornerRadius: 15))
    }
}
