import SwiftUI
import Foundation

// MARK: - macOS 27 Liquid Glass Style System
struct LiquidGlassButtonStyle: ButtonStyle {
    @State private var isHovered = false
    var isProminent: Bool = false
    var accentColor: Color = .blue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .font(.system(.body, design: .rounded))
            .fontWeight(.semibold)
            .foregroundColor(isProminent ? .white : .primary)
            .background(
                ZStack {
                    if isProminent {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: [accentColor.opacity(0.85), accentColor],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                            .opacity(configuration.isPressed ? 0.75 : (isHovered ? 0.95 : 0.85))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.15), Color.black.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
            .shadow(color: Color.black.opacity(isHovered ? 0.12 : 0.05), radius: isHovered ? 4 : 2, x: 0, y: 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.65, blendDuration: 0), value: isHovered)
            .animation(.spring(response: 0.25, dampingFraction: 0.65, blendDuration: 0), value: configuration.isPressed)
            .onHover { hover in
                isHovered = hover
            }
    }
}

struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.black.opacity(0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

extension View {
    func liquidGlassCard() -> some View {
        self.modifier(LiquidGlassModifier())
    }
}


import AppKit

// MARK: - App Entrypoint
@main
struct LocalChatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 620, maxWidth: .infinity, minHeight: 520, maxHeight: .infinity)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

// MARK: - Native macOS Translucent Glass Background
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .underWindowBackground // Liquid Glass style
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Codable Structs for Ollama API Interaction
struct OllamaMessage: Codable {
    let role: String
    var content: String
}

struct OllamaChatRequest: Codable {
    let model: String
    let messages: [OllamaMessage]
    let stream: Bool
}

struct OllamaChatResponseChunk: Codable {
    let message: OllamaMessage?
    let done: Bool
}

struct OllamaModelList: Codable {
    let models: [OllamaLocalModel]
}

struct OllamaLocalModel: Codable, Identifiable {
    var id: String { name }
    let name: String
    let size: Int64
}

// MARK: - Chat UI Bubble Struct
struct LocalChatMessage: Identifiable {
    let id = UUID()
    let sender: String // "User" or "AI"
    var content: String
    let timestamp = Date()
}

// MARK: - Local Chat State Manager
class ChatManager: ObservableObject {
    @Published var messages: [LocalChatMessage] = []
    @Published var installedModels: [OllamaLocalModel] = []
    @Published var selectedModel: String = ""
    @Published var isStreaming: Bool = false
    @Published var statusMessage: String = "Ready"
    
    @Published var pullProgress: Double = 0.0
    @Published var pullStatus: String = ""
    @Published var isPulling: Bool = false
    
    @Published var ollamaRunning: Bool = false
    @Published var cpuUsage: String = "0.0%"
    @Published var ramUsage: String = "Free: 0 GB"
    @Published var odysseusDockerStatus: String = "Stopped"
    
    private var timer: Timer?
    
    init() {
        messages.append(LocalChatMessage(sender: "AI", content: "Hi! I am your local chat client connected directly to the Ollama server. Select an installed model above to begin."))
        checkOllamaStatus()
        fetchModels()
        startStatsTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Ollama API Calls
    func fetchModels() {
        guard let url = URL(string: "http://localhost:11434/api/tags") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.statusMessage = "Offline (Ollama API unavailable)"
                    self.ollamaRunning = false
                }
                return
            }
            
            guard let data = data else { return }
            do {
                let decoded = try JSONDecoder().decode(OllamaModelList.self, from: data)
                DispatchQueue.main.async {
                    self.installedModels = decoded.models
                    self.ollamaRunning = true
                    if self.selectedModel.isEmpty && !decoded.models.isEmpty {
                        self.selectedModel = decoded.models[0].name
                    }
                    self.statusMessage = "Connected to Ollama"
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusMessage = "Failed to parse model list"
                }
            }
        }.resume()
    }
    
    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !selectedModel.isEmpty else {
            statusMessage = "Please select or download a model first!"
            return
        }
        
        DispatchQueue.main.async {
            self.messages.append(LocalChatMessage(sender: "User", content: trimmed))
            self.messages.append(LocalChatMessage(sender: "AI", content: ""))
            self.isStreaming = true
            self.statusMessage = "Generating tokens..."
        }
        
        let promptHistory = self.messages.dropLast().map { msg in
            OllamaMessage(role: msg.sender == "User" ? "user" : "assistant", content: msg.content)
        }
        
        Task {
            await runStreamingRequest(history: promptHistory)
        }
    }
    
    private func runStreamingRequest(history: [OllamaMessage]) async {
        guard let url = URL(string: "http://localhost:11434/api/chat") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let reqBody = OllamaChatRequest(model: selectedModel, messages: history, stream: true)
        guard let encoded = try? JSONEncoder().encode(reqBody) else { return }
        request.httpBody = encoded
        
        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                updateStreamingError("Server responded with error status.")
                return
            }
            
            for try await line in bytes.lines {
                guard let data = line.data(using: .utf8) else { continue }
                if let decoded = try? JSONDecoder().decode(OllamaChatResponseChunk.self, from: data) {
                    if let chunkText = decoded.message?.content {
                        DispatchQueue.main.async {
                            if var lastMsg = self.messages.last {
                                lastMsg.content += chunkText
                                self.messages[self.messages.count - 1] = lastMsg
                            }
                        }
                    }
                    if decoded.done {
                        break
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.isStreaming = false
                self.statusMessage = "Ready"
            }
        } catch {
            updateStreamingError("Connection error: \(error.localizedDescription)")
        }
    }
    
    private func updateStreamingError(_ err: String) {
        DispatchQueue.main.async {
            self.isStreaming = false
            self.statusMessage = "Error: API request failed"
            if var lastMsg = self.messages.last {
                lastMsg.content = "⚠️ [Failed to generate response: \(err)]"
                self.messages[self.messages.count - 1] = lastMsg
            }
        }
    }
    
    // MARK: - Model Pull (Download)
    func pullModel(name: String) {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        
        DispatchQueue.main.async {
            self.isPulling = true
            self.pullProgress = 0.0
            self.pullStatus = "Contacting repository..."
        }
        
        Task {
            await runPullRequest(name: cleaned)
        }
    }
    
    private func runPullRequest(name: String) async {
        guard let url = URL(string: "http://localhost:11434/api/pull") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["name": name, "stream": true]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.isPulling = false
                    self.pullStatus = "Model download failed. Check name."
                }
                return
            }
            
            for try await line in bytes.lines {
                guard let data = line.data(using: .utf8) else { continue }
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let status = json["status"] as? String ?? ""
                    let completed = json["completed"] as? Double ?? 0.0
                    let total = json["total"] as? Double ?? 0.0
                    
                    DispatchQueue.main.async {
                        self.pullStatus = status
                        if total > 0 {
                            self.pullProgress = completed / total
                            self.pullStatus = "\(status) (\(Int(self.pullProgress * 100))%)"
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.isPulling = false
                self.pullStatus = "Completed!"
                self.fetchModels()
            }
        } catch {
            DispatchQueue.main.async {
                self.isPulling = false
                self.pullStatus = "Failed: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteModel(name: String) {
        guard let url = URL(string: "http://localhost:11434/api/delete") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["name": name]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { [weak self] _, response, _ in
            guard let self = self else { return }
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            DispatchQueue.main.async {
                if code == 200 {
                    self.statusMessage = "Model deleted: \(name)"
                    self.fetchModels()
                } else {
                    self.statusMessage = "Delete failed: \(code)"
                }
            }
        }.resume()
    }
    
    // MARK: - Server Control & Statistics
    func startOllama() {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Ollama"]
            try? process.run()
            process.waitUntilExit()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.fetchModels()
            }
        }
    }
    
    func stopOllama() {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            process.arguments = ["Ollama"]
            try? process.run()
            process.waitUntilExit()
            
            DispatchQueue.main.async {
                self.ollamaRunning = false
                self.statusMessage = "Ollama stopped"
            }
        }
    }
    
    private func checkOllamaStatus() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", "Ollama"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        DispatchQueue.main.async {
            self.ollamaRunning = !output.isEmpty
        }
    }
    
    private func startStatsTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.checkOllamaStatus()
            self?.querySystemStats()
        }
    }
    
    private func querySystemStats() {
        // Query CPU Usage
        let cpuProcess = Process()
        cpuProcess.executableURL = URL(fileURLWithPath: "/usr/bin/top")
        cpuProcess.arguments = ["-l", "1", "-n", "0"]
        let cpuPipe = Pipe()
        cpuProcess.standardOutput = cpuPipe
        try? cpuProcess.run()
        cpuProcess.waitUntilExit()
        
        let cpuData = cpuPipe.fileHandleForReading.readDataToEndOfFile()
        if let cpuOutput = String(data: cpuData, encoding: .utf8) {
            let lines = cpuOutput.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("CPU usage:") {
                    let parts = line.components(separatedBy: ",")
                    if !parts.isEmpty {
                        let usageStr = parts[0].replacingOccurrences(of: "CPU usage:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        DispatchQueue.main.async {
                            self.cpuUsage = usageStr
                        }
                    }
                }
            }
        }
        
        // Query Memory Usage (Free RAM)
        let memProcess = Process()
        memProcess.executableURL = URL(fileURLWithPath: "/usr/bin/vm_stat")
        let memPipe = Pipe()
        memProcess.standardOutput = memPipe
        try? memProcess.run()
        memProcess.waitUntilExit()
        
        let memData = memPipe.fileHandleForReading.readDataToEndOfFile()
        if let memOutput = String(data: memData, encoding: .utf8) {
            let lines = memOutput.components(separatedBy: .newlines)
            var freePages: Double = 0
            var specPages: Double = 0
            for line in lines {
                if line.contains("Pages free:") {
                    let val = Double(line.components(separatedBy: ":")[1].replacingOccurrences(of: ".", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
                    freePages = val
                } else if line.contains("Pages speculative:") {
                    let val = Double(line.components(separatedBy: ":")[1].replacingOccurrences(of: ".", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
                    specPages = val
                }
            }
            // 1 page = 4096 bytes on intel, but Apple Silicon uses 16384 bytes (16KB) pages
            let pageSize: Double = 16384
            let freeRAMBytes = (freePages + specPages) * pageSize
            let freeRAMGB = freeRAMBytes / (1024 * 1024 * 1024)
            
            DispatchQueue.main.async {
                self.ramUsage = String(format: "Free: %.1f GB (of 32GB)", freeRAMGB)
            }
        }
        
        // Check Odysseus Container state
        let docProcess = Process()
        docProcess.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
        docProcess.arguments = ["ps", "-a", "--filter", "name=odysseus-app", "--format", "{{.State}}"]
        let docPipe = Pipe()
        docProcess.standardOutput = docPipe
        try? docProcess.run()
        docProcess.waitUntilExit()
        
        let docData = docPipe.fileHandleForReading.readDataToEndOfFile()
        let docOutput = String(data: docData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        DispatchQueue.main.async {
            if docOutput.isEmpty {
                self.odysseusDockerStatus = "Offline"
            } else {
                self.odysseusDockerStatus = docOutput.capitalized
            }
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var chat = ChatManager()
    
    var body: some View {
        ZStack {
            VisualEffectView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Panel
                HStack(spacing: 12) {
                    Text("Local Chat")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.leading, 20)
                    
                    Picker("", selection: $selectedTab) {
                        Text("Chat").tag(0)
                        Text("Manage Models").tag(1)
                        Text("System Dashboard").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 380)
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.04))
                
                Divider()
                
                // Tab Selection Routing
                switch selectedTab {
                case 0:
                    ChatView(chat: chat)
                case 1:
                    ModelManagerView(chat: chat)
                default:
                    SystemDashboardView(chat: chat)
                }
            }
        }
    }
}

// MARK: - Tab 1: Chat interface
struct ChatView: View {
    @ObservedObject var chat: ChatManager
    @State private var textPrompt: String = ""
    
    var body: some View {
        VStack(spacing: 10) {
            // Model Selector Dropdown
            HStack {
                Text("Select Model:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)
                
                Picker("", selection: $chat.selectedModel) {
                    if chat.installedModels.isEmpty {
                        Text("No Models Found").tag("")
                    } else {
                        ForEach(chat.installedModels) { model in
                            Text(model.name).tag(model.name)
                        }
                    }
                }
                .frame(width: 220)
                .disabled(chat.isStreaming)
                
                Button(action: {
                    chat.fetchModels()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(chat.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            Divider()
            
            // Conversation messages
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(chat.messages) { msg in
                            HStack {
                                if msg.sender == "User" { Spacer() }
                                
                                Text(msg.content.isEmpty ? "..." : msg.content)
                                    .padding(10)
                                    .background(msg.sender == "User" ? Color.blue.opacity(0.85) : Color.primary.opacity(0.08))
                                    .foregroundColor(msg.sender == "User" ? .white : .primary)
                                    .cornerRadius(8)
                                    .frame(maxWidth: 460, alignment: msg.sender == "User" ? .trailing : .leading)
                                
                                if msg.sender == "AI" { Spacer() }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .onChange(of: chat.messages.count) { _ in
                    if let lastMsg = chat.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMsg.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: chat.messages.last?.content) { _ in
                    if let lastMsg = chat.messages.last {
                        proxy.scrollTo(lastMsg.id, anchor: .bottom)
                    }
                }
            }
            
            // Prompt input row
            HStack(spacing: 12) {
                TextField("Ask anything...", text: $textPrompt)
                    .textFieldStyle(.roundedBorder)
                    .disabled(chat.isStreaming || !chat.ollamaRunning)
                
                Button(action: {
                    chat.sendMessage(textPrompt)
                    textPrompt = ""
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(chat.ollamaRunning ? Color.blue : Color.secondary)
                }
                .disabled(chat.isStreaming || textPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !chat.ollamaRunning)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tab 2: Model Manager View
struct ModelManagerView: View {
    @ObservedObject var chat: ChatManager
    @State private var modelNameInput: String = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Model Pull Field
            VStack(alignment: .leading, spacing: 6) {
                Text("Download New Models from Ollama Registry")
                    .font(.headline)
                    .padding(.top, 10)
                
                HStack(spacing: 12) {
                    TextField("E.g., deepseek-r1:8b, llama3, gemma2:2b", text: $modelNameInput)
                        .textFieldStyle(.roundedBorder)
                        .disabled(chat.isPulling)
                    
                    Button("Pull Model") {
                        chat.pullModel(name: modelNameInput)
                        modelNameInput = ""
                    }
                    .disabled(chat.isPulling || modelNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 16)
            
            // Pull Progress View
            if chat.isPulling {
                VStack(spacing: 6) {
                    ProgressView(value: chat.pullProgress)
                        .progressViewStyle(.linear)
                    
                    HStack {
                        Text(chat.pullStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Divider()
            
            // Installed models listing
            VStack(alignment: .leading, spacing: 6) {
                Text("Installed Models on Your System")
                    .font(.headline)
                
                ScrollView {
                    VStack(spacing: 8) {
                        if chat.installedModels.isEmpty {
                            Text("No local models installed. Pull a model above.")
                                .foregroundColor(.secondary)
                                .padding(.top, 20)
                        } else {
                            ForEach(chat.installedModels) { model in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.name)
                                            .fontWeight(.bold)
                                        Text(String(format: "Size: %.2f GB", Double(model.size) / (1024 * 1024 * 1024)))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    
                                    Button("Delete") {
                                        chat.deleteModel(name: model.name)
                                    }
                                    .buttonStyle(LiquidGlassButtonStyle(isProminent: false))
                                    .tint(.red)
                                }
                                .padding(8)
                                .background(Color.primary.opacity(0.04))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tab 3: System Stats & Dashboard View
struct SystemDashboardView: View {
    @ObservedObject var chat: ChatManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Server Toggles
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ollama Server Service")
                        .font(.headline)
                    
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(chat.ollamaRunning ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(chat.ollamaRunning ? "Ollama Active" : "Ollama Stopped")
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if chat.ollamaRunning {
                                chat.stopOllama()
                            } else {
                                chat.startOllama()
                            }
                        }) {
                            Text(chat.ollamaRunning ? "Stop Service" : "Start Service")
                        }
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                        .tint(chat.ollamaRunning ? .red : .blue)
                    }
                    .padding(12)
                    .background(.thinMaterial)
                    .cornerRadius(8)
                }
                
                Divider()
                
                // M1 Pro Resources gauges
                VStack(alignment: .leading, spacing: 10) {
                    Text("Apple Silicon M1 Pro Hardware Resources")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        // CPU load
                        VStack(spacing: 6) {
                            Text("CPU Usage")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(chat.cpuUsage)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(.thinMaterial)
                        .cornerRadius(8)
                        
                        // RAM load
                        VStack(spacing: 6) {
                            Text("System Unified RAM")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(chat.ramUsage)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(.thinMaterial)
                        .cornerRadius(8)
                    }
                }
                
                Divider()
                
                // Core Docker stacks
                VStack(alignment: .leading, spacing: 10) {
                    Text("Odysseus Stack Status")
                        .font(.headline)
                    
                    HStack {
                        Text("Search & RAG Container (odysseus-app)")
                        Spacer()
                        HStack(spacing: 8) {
                            Circle()
                                .fill(chat.odysseusDockerStatus.contains("Up") ? Color.green : Color.secondary)
                                .frame(width: 8, height: 8)
                            Text(chat.odysseusDockerStatus)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(12)
                    .background(.thinMaterial)
                    .cornerRadius(8)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
