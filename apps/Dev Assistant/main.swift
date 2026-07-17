import SwiftUI
import Foundation
import AppKit
import WebKit

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



class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        // Terminate OpenHands Docker container if active
        let process = Process()
        var processEnv = ProcessInfo.processInfo.environment
        processEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
        process.environment = processEnv
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
        process.arguments = ["stop", "openhands-app"]
        try? process.run()
        process.waitUntilExit()
    }
}

// MARK: - App Entrypoint
@main
struct DevAssistantApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 720, maxWidth: .infinity, minHeight: 560, maxHeight: .infinity)
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
        view.material = .underWindowBackground // Liquid Glass refraction
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Embedded Native Web Viewer
struct WebView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        // Set standard user agent to avoid compatibility alerts
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        nsView.load(request)
    }
}

// MARK: - Conversation Struct for Aider Chat
struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: String // "User" or "Aider"
    let message: String
    let timestamp = Date()
}

// MARK: - Aider Chat State Manager
class AiderManager: ObservableObject {
    @Published var chatHistory: [ChatMessage] = []
    @Published var isRunning: Bool = false
    @Published var statusMessage: String = "Ready"
    @Published var consoleLogs: String = ""
    @Published var activeRepo: String = "/Users/hassan/local-ai"
    @Published var selectedModel: String = "gemini/gemini-2.5-flash"
    
    private var process: Process?
    private var outputPipe: Pipe?
    
    init() {
        // Load GEMINI_API_KEY if needed inside process environment
        chatHistory.append(ChatMessage(sender: "Aider", message: "Hello! I am your Git-integrated pair programming agent. Select your project repository and model above, and describe the changes you want me to write!"))
    }
    
    func sendMessage(_ text: String) {
        let userMessage = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessage.isEmpty else { return }
        
        DispatchQueue.main.async {
            self.chatHistory.append(ChatMessage(sender: "User", message: userMessage))
            self.isRunning = true
            self.statusMessage = "Analyzing repository map..."
            self.consoleLogs = "Initializing Aider process...\nRepository: \(self.activeRepo)\nModel: \(self.selectedModel)\n"
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.executeAider(prompt: userMessage)
        }
    }
    
    private func executeAider(prompt: String) {
        let process = Process()
        var processEnv = ProcessInfo.processInfo.environment
        processEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
        process.environment = processEnv
        self.process = process
        process.executableURL = URL(fileURLWithPath: "/opt/miniconda3/bin/aider")
        
        // Target model, instruction prompt, and auto-yes to write files without halts
        process.arguments = [
            "--model", selectedModel,
            "--message", prompt,
            "--yes"
        ]
        
        process.currentDirectoryURL = URL(fileURLWithPath: activeRepo)
        
        // Export Gemini key from environment
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
        if let envContent = try? String(contentsOfFile: "/Users/hassan/local-ai/.env", encoding: .utf8) {
            let lines = envContent.components(separatedBy: .newlines)
            for line in lines {
                let parts = line.components(separatedBy: "=")
                if parts.count >= 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let val = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !key.isEmpty && !key.hasPrefix("#") {
                        env[key] = val
                    }
                }
            }
        }
        process.environment = env
        
        let pipe = Pipe()
        self.outputPipe = pipe
        process.standardOutput = pipe
        process.standardError = pipe
        
        let fileHandle = pipe.fileHandleForReading
        fileHandle.readabilityHandler = { [weak self] handle in
            guard let self = self else { return }
            let data = handle.availableData
            guard !data.isEmpty else { return }
            if let outputString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.consoleLogs += outputString
                    self.updateStatus(outputString)
                }
            }
        }
        
        do {
            try process.run()
            process.waitUntilExit()
            
            fileHandle.readabilityHandler = nil
            let status = process.terminationStatus
            
            DispatchQueue.main.async {
                self.isRunning = false
                if status == 0 {
                    self.statusMessage = "Changes completed successfully!"
                    self.chatHistory.append(ChatMessage(sender: "Aider", message: "Task completed! I have modified the source code and staged the edits in Git.\nCheck the Diagnostics drawer below for the complete log."))
                } else if status == 15 {
                    self.statusMessage = "Cancelled"
                } else {
                    self.statusMessage = "Execution failed (Exit Code \(status))"
                    self.chatHistory.append(ChatMessage(sender: "Aider", message: "I encountered an error trying to process the instruction. Check the Diagnostics console for output logs."))
                }
            }
        } catch {
            fileHandle.readabilityHandler = nil
            DispatchQueue.main.async {
                self.isRunning = false
                self.statusMessage = "Execution failed: \(error.localizedDescription)"
            }
        }
    }
    
    func cancelTask() {
        if let process = process, process.isRunning {
            process.terminate()
            consoleLogs += "\n[Process Terminated by User]\n"
        }
    }
    
    func startWebGui() {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            var processEnv = ProcessInfo.processInfo.environment
            processEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
            process.environment = processEnv
            process.executableURL = URL(fileURLWithPath: "/opt/miniconda3/bin/aider")
            process.arguments = ["--model", self.selectedModel, "--gui"]
            process.currentDirectoryURL = URL(fileURLWithPath: self.activeRepo)
            
            var env = ProcessInfo.processInfo.environment
            env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
            if let envContent = try? String(contentsOfFile: "/Users/hassan/local-ai/.env", encoding: .utf8) {
                let lines = envContent.components(separatedBy: .newlines)
                for line in lines {
                    let parts = line.components(separatedBy: "=")
                    if parts.count >= 2 {
                        let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let val = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                        if !key.isEmpty && !key.hasPrefix("#") {
                            env[key] = val
                        }
                    }
                }
            }
            process.environment = env
            
            do {
                try process.run()
                // Let it run in background headlessly
                DispatchQueue.main.async {
                    self.statusMessage = "Web GUI launched!"
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusMessage = "Web GUI launch failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func updateStatus(_ output: String) {
        if output.contains("Loading repo map") {
            self.statusMessage = "Loading repository maps..."
        } else if output.contains("Git commit") {
            self.statusMessage = "Committing changes to Git..."
        } else if output.contains("Applied edit") {
            self.statusMessage = "Applying source file changes..."
        }
    }
}

// MARK: - OpenHands State Manager
class OpenHandsManager: ObservableObject {
    @Published var isServerRunning: Bool = false
    @Published var consoleLogs: String = ""
    @Published var statusMessage: String = "Stopped"
    @Published var activeWorkspace: String = "/Users/hassan/local-ai/openhands_workspace"
    @Published var showWebView: Bool = false
    
    private var process: Process?
    private var pipe: Pipe?
    
    func startContainer() {
        DispatchQueue.main.async {
            self.statusMessage = "Initializing Docker container..."
            self.consoleLogs = "Stopping existing OpenHands containers if any...\n"
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Stop old docker first
            let stopProcess = Process()
            var stopProcessEnv = ProcessInfo.processInfo.environment
            stopProcessEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
            stopProcess.environment = stopProcessEnv
            stopProcess.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
            stopProcess.arguments = ["stop", "openhands"]
            try? stopProcess.run()
            stopProcess.waitUntilExit()
            
            let rmProcess = Process()
            var rmProcessEnv = ProcessInfo.processInfo.environment
            rmProcessEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
            rmProcess.environment = rmProcessEnv
            rmProcess.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
            rmProcess.arguments = ["rm", "openhands"]
            try? rmProcess.run()
            rmProcess.waitUntilExit()
            
            // Run new container
            DispatchQueue.main.async {
                self.consoleLogs += "Launching OpenHands Docker container mapping to: \(self.activeWorkspace)...\n"
            }
            
            let runProcess = Process()
            var runProcessEnv = ProcessInfo.processInfo.environment
            runProcessEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
            runProcess.environment = runProcessEnv
            self.process = runProcess
            runProcess.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
            
            runProcess.arguments = [
                "run", "--name", "openhands",
                "-p", "3001:3000",
                "-e", "SANDBOX_VOLUMES=\(self.activeWorkspace):/workspace:rw",
                "-v", "/var/run/docker.sock:/var/run/docker.sock",
                "docker.openhands.dev/openhands/openhands:latest"
            ]
            
            let pipe = Pipe()
            self.pipe = pipe
            runProcess.standardOutput = pipe
            runProcess.standardError = pipe
            
            let fileHandle = pipe.fileHandleForReading
            fileHandle.readabilityHandler = { [weak self] handle in
                guard let self = self else { return }
                let data = handle.availableData
                guard !data.isEmpty else { return }
                if let outputString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.consoleLogs += outputString
                        if outputString.contains("Ready to accept connections") || outputString.contains("Server started") || outputString.contains("Listening on") {
                            self.statusMessage = "Running"
                            self.isServerRunning = true
                            self.showWebView = true
                        }
                    }
                }
            }
            
            do {
                try runProcess.run()
                
                // Set a timeout wait of 6 seconds, then show WebView as fallback if server is loading quietly
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    if !self.isServerRunning {
                        self.isServerRunning = true
                        self.showWebView = true
                        self.statusMessage = "Running (Workspace active)"
                    }
                }
                
                runProcess.waitUntilExit()
            } catch {
                DispatchQueue.main.async {
                    self.statusMessage = "Failed: \(error.localizedDescription)"
                    self.isServerRunning = false
                }
            }
        }
    }
    
    func stopContainer() {
        DispatchQueue.main.async {
            self.statusMessage = "Stopping container..."
            self.showWebView = false
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let stopProcess = Process()
            var stopProcessEnv = ProcessInfo.processInfo.environment
            stopProcessEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
            stopProcess.environment = stopProcessEnv
            stopProcess.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
            stopProcess.arguments = ["stop", "openhands"]
            try? stopProcess.run()
            stopProcess.waitUntilExit()
            
            DispatchQueue.main.async {
                self.isServerRunning = false
                self.statusMessage = "Stopped"
                self.consoleLogs += "\n[Container Terminated by User]\n"
            }
        }
    }
}

// MARK: - Browser-Use State Manager
class BrowserAgentManager: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var consoleLogs: String = ""
    @Published var statusMessage: String = "Ready"
    @Published var agentResult: String = ""
    @Published var taskText: String = ""
    @Published var runHeadless: Bool = false // false opens visible Chromium
    
    private var process: Process?
    private var pipe: Pipe?
    
    func startAgent() {
        let task = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !task.isEmpty else { return }
        
        DispatchQueue.main.async {
            self.isRunning = true
            self.statusMessage = "Launching browser context..."
            self.consoleLogs = "Starting Playwright automation script...\nTask: \"\(task)\"\nHeadless Mode: \(self.runHeadless)\n"
            self.agentResult = ""
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            var processEnv = ProcessInfo.processInfo.environment
            processEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
            process.environment = processEnv
            self.process = process
            process.executableURL = URL(fileURLWithPath: "/opt/miniconda3/bin/python")
            
            // Pass task and headless parameters
            process.arguments = [
                "/Users/hassan/local-ai/apps/Dev Assistant/run_browser_agent.py",
                task,
                self.runHeadless ? "true" : "false"
            ]
            
            let pipe = Pipe()
            self.pipe = pipe
            process.standardOutput = pipe
            process.standardError = pipe
            
            let fileHandle = pipe.fileHandleForReading
            fileHandle.readabilityHandler = { [weak self] handle in
                guard let self = self else { return }
                let data = handle.availableData
                guard !data.isEmpty else { return }
                if let outputString = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.consoleLogs += outputString
                        if outputString.contains("Executing browser agent task") {
                            self.statusMessage = "Automating browser..."
                        }
                    }
                }
            }
            
            do {
                try process.run()
                process.waitUntilExit()
                
                fileHandle.readabilityHandler = nil
                let status = process.terminationStatus
                
                DispatchQueue.main.async {
                    self.isRunning = false
                    if status == 0 {
                        self.statusMessage = "Completed!"
                        // Extract output from logs
                        if let resultRange = self.consoleLogs.range(of: "=== Agent Result ===[\\s\\S]*?====================", options: .regularExpression) {
                            let resultStr = String(self.consoleLogs[resultRange])
                                .replacingOccurrences(of: "=== Agent Result ===", with: "")
                                .replacingOccurrences(of: "====================", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            self.agentResult = resultStr
                        } else {
                            self.agentResult = "Task finished successfully. Check logs below for full logs."
                        }
                    } else if status == 15 {
                        self.statusMessage = "Stopped"
                    } else {
                        self.statusMessage = "Failed: Exit Code \(status)"
                    }
                }
            } catch {
                fileHandle.readabilityHandler = nil
                DispatchQueue.main.async {
                    self.isRunning = false
                    self.statusMessage = "Execution failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func terminateAgent() {
        if let process = process, process.isRunning {
            process.terminate()
            consoleLogs += "\n[Browser Agent Terminated by User]\n"
        }
    }
}

// MARK: - Presentation Layer (ContentView)
struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            VisualEffectView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Tab Header Drawer
                HStack(spacing: 12) {
                    Text("Dev Assistant")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.leading, 20)
                    
                    Picker("", selection: $selectedTab) {
                        Text("Aider Coding").tag(0)
                        Text("OpenHands Agent").tag(1)
                        Text("Browser-Use").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 360)
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.04))
                
                Divider()
                
                // Tab panels routing
                switch selectedTab {
                case 0:
                    AiderView()
                case 1:
                    OpenHandsView()
                default:
                    BrowserAgentView()
                }
            }
        }
    }
}

// MARK: - Aider Chat Panel (Tab 1)
struct AiderView: View {
    @StateObject private var aider = AiderManager()
    @State private var inputPrompt: String = ""
    @State private var showLogs: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Configuration Row
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Project Repository")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                    HStack(spacing: 6) {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.orange)
                        Text(aider.activeRepo)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Button("Change...") {
                            selectFolder()
                        }
                        .disabled(aider.isRunning)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Model Endpoint")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                    Picker("", selection: $aider.selectedModel) {
                        Text("Gemini 2.5 Flash").tag("gemini/gemini-2.5-flash")
                        Text("Gemini 2.5 Pro").tag("gemini/gemini-2.5-pro")
                        Text("DeepSeek R1 (8B)").tag("ollama/deepseek-r1:8b")
                        Text("Llama 3 (8B)").tag("ollama/llama3")
                    }
                    .frame(width: 180)
                    .disabled(aider.isRunning)
                }
                
                Button(action: {
                    aider.startWebGui()
                }) {
                    HStack {
                        Image(systemName: "safari")
                        Text("Web GUI")
                    }
                }
                .disabled(aider.isRunning)
                .help("Launch Aider Streamlit interface on port 8501")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Divider()
            
            // Conversation History Bubbles
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(aider.chatHistory) { msg in
                            HStack {
                                if msg.sender == "User" { Spacer() }
                                
                                Text(msg.message)
                                    .padding(10)
                                    .background(msg.sender == "User" ? Color.blue.opacity(0.85) : Color.primary.opacity(0.08))
                                    .foregroundColor(msg.sender == "User" ? .white : .primary)
                                    .cornerRadius(8)
                                    .frame(maxWidth: 420, alignment: msg.sender == "User" ? .trailing : .leading)
                                
                                if msg.sender == "Aider" { Spacer() }
                            }
                            .id(msg.id)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .onChange(of: aider.chatHistory.count) { _ in
                    if let lastMsg = aider.chatHistory.last {
                        withAnimation {
                            proxy.scrollTo(lastMsg.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Task status message
            if aider.isRunning {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(aider.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Cancel") {
                        aider.cancelTask()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 16)
            }
            
            // Prompt input area
            HStack(spacing: 12) {
                TextField("E.g., Add docstrings to convert_doc.py and commit the changes", text: $inputPrompt)
                    .textFieldStyle(.roundedBorder)
                    .disabled(aider.isRunning)
                
                Button(action: {
                    aider.sendMessage(inputPrompt)
                    inputPrompt = ""
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .disabled(aider.isRunning || inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // Console diagnostics drawer
            Divider()
            Button(action: {
                withAnimation {
                    showLogs.toggle()
                }
            }) {
                HStack {
                    Text(showLogs ? "Hide Console Output" : "Show Console Output")
                    Image(systemName: showLogs ? "chevron.up" : "chevron.down")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)
            
            if showLogs {
                ScrollViewReader { logProxy in
                    ScrollView {
                        Text(aider.consoleLogs)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor).opacity(0.3))
                            .cornerRadius(4)
                            .id("logText")
                    }
                    .frame(maxHeight: 110)
                    .onChange(of: aider.consoleLogs) { _ in
                        logProxy.scrollTo("logText", anchor: .bottom)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func selectFolder() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose Repository Folder"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK {
            if let path = openPanel.url?.path {
                aider.activeRepo = path
            }
        }
    }
}

// MARK: - OpenHands Sandbox Panel (Tab 2)
struct OpenHandsView: View {
    @StateObject private var openhands = OpenHandsManager()
    @State private var showLogs: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Configuration bar
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Agent Sandbox Directory")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.semibold)
                    HStack(spacing: 6) {
                        Image(systemName: "shippingbox.fill")
                            .foregroundColor(.blue)
                        Text(openhands.activeWorkspace)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Button("Change...") {
                            selectFolder()
                        }
                        .disabled(openhands.isServerRunning)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(openhands.isServerRunning ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text("Server Status: \(openhands.statusMessage)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    if openhands.isServerRunning {
                        openhands.stopContainer()
                    } else {
                        openhands.startContainer()
                    }
                }) {
                    Text(openhands.isServerRunning ? "Stop Container" : "Start Container")
                }
                .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                .tint(openhands.isServerRunning ? .red : .blue)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Divider()
            
            // Web view content
            if openhands.showWebView {
                WebView(url: URL(string: "http://localhost:3001")!)
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "shippingbox.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("OpenHands Sandbox is Stopped")
                        .font(.headline)
                    Text("Click 'Start Container' to launch the Docker workspace on port 3001. Once initialized, the interactive coding panel will load here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 380)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Diagnostics Drawer
            Divider()
            Button(action: {
                withAnimation {
                    showLogs.toggle()
                }
            }) {
                HStack {
                    Text(showLogs ? "Hide Container Logs" : "Show Container Logs")
                    Image(systemName: showLogs ? "chevron.up" : "chevron.down")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)
            
            if showLogs {
                ScrollViewReader { proxy in
                    ScrollView {
                        Text(openhands.consoleLogs)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor).opacity(0.3))
                            .cornerRadius(4)
                            .id("logText")
                    }
                    .frame(maxHeight: 110)
                    .onChange(of: openhands.consoleLogs) { _ in
                        proxy.scrollTo("logText", anchor: .bottom)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func selectFolder() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Choose Sandbox Workspace"
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        
        if openPanel.runModal() == .OK {
            if let path = openPanel.url?.path {
                openhands.activeWorkspace = path
            }
        }
    }
}

// MARK: - Browser Agent Panel (Tab 3 - browser-use)
struct BrowserAgentView: View {
    @StateObject private var agent = BrowserAgentManager()
    @State private var showLogs: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Browser Automation Agent")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("Describe a web automation task and watch the agent solve it locally via Playwright")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Describe What the Browser Should Do")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    TextEditor(text: $agent.taskText)
                        .frame(height: 72)
                        .padding(4)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                        .cornerRadius(6)
                        .disabled(agent.isRunning)
                }
                
                HStack {
                    Toggle("Visible Browser Window (watch actions)", isOn: Binding(
                        get: { !agent.runHeadless },
                        set: { agent.runHeadless = !$0 }
                    ))
                    .disabled(agent.isRunning)
                    
                    Spacer()
                }
                .padding(10)
                .background(.thinMaterial)
                .cornerRadius(6)
                
                if agent.isRunning {
                    VStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(.linear)
                        HStack {
                            Text(agent.statusMessage)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
                
                HStack {
                    if agent.isRunning {
                        Button(action: {
                            agent.terminateAgent()
                        }) {
                            HStack {
                                Image(systemName: "stop.circle.fill")
                                Text("Terminate Agent")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 32)
                        }
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                        .tint(.red)
                    } else {
                        Button(action: {
                            agent.startAgent()
                        }) {
                            HStack {
                                Image(systemName: "safari.fill")
                                Text("Execute Browser Agent")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, minHeight: 32)
                        }
                        .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                        .disabled(agent.taskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                if !agent.agentResult.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Agent Completion Result:")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        Text(agent.agentResult)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.textBackgroundColor).opacity(0.3))
                            .cornerRadius(6)
                    }
                }
                
                Divider()
                Button(action: {
                    withAnimation {
                        showLogs.toggle()
                    }
                }) {
                    HStack {
                        Text(showLogs ? "Hide Live Scraper Logs" : "Show Live Scraper Logs")
                        Image(systemName: showLogs ? "chevron.up" : "chevron.down")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                if showLogs {
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(agent.consoleLogs)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color(NSColor.textBackgroundColor).opacity(0.5))
                                .cornerRadius(4)
                                .id("logText")
                        }
                        .frame(maxHeight: 120)
                        .onChange(of: agent.consoleLogs) { _ in
                            proxy.scrollTo("logText", anchor: .bottom)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
    }
}
