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
        // Stop Core Tools Compose Stack
        let coreProcess = Process()
        var coreProcessEnv = ProcessInfo.processInfo.environment
        coreProcessEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
        coreProcess.environment = coreProcessEnv
        coreProcess.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
        coreProcess.arguments = ["compose", "-f", "/Users/hassan/local-ai/docker-compose.tools.yml", "down"]
        try? coreProcess.run()
        coreProcess.waitUntilExit()
        
        // Stop Dify Compose Stack
        let difyProcess = Process()
        var difyProcessEnv = ProcessInfo.processInfo.environment
        difyProcessEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
        difyProcess.environment = difyProcessEnv
        difyProcess.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
        difyProcess.arguments = ["compose", "-f", "/Users/hassan/local-ai/dify/docker/docker-compose.yaml", "down"]
        try? difyProcess.run()
        difyProcess.waitUntilExit()
        
        // Stop Maxun Compose Stack
        let maxunProcess = Process()
        var maxunProcessEnv = ProcessInfo.processInfo.environment
        maxunProcessEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
        maxunProcess.environment = maxunProcessEnv
        maxunProcess.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
        maxunProcess.arguments = ["compose", "-f", "/Users/hassan/local-ai/maxun/docker-compose.yml", "down"]
        try? maxunProcess.run()
        maxunProcess.waitUntilExit()
        
        // Stop Letta Agent containers
        let lettaProcess = Process()
        var lettaProcessEnv = ProcessInfo.processInfo.environment
        lettaProcessEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
        lettaProcess.environment = lettaProcessEnv
        lettaProcess.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
        lettaProcess.arguments = ["stop", "letta-server", "letta-db"]
        try? lettaProcess.run()
        lettaProcess.waitUntilExit()
    }
}

// MARK: - App Entrypoint
@main
struct AIOrchestratorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 840, maxWidth: .infinity, minHeight: 620, maxHeight: .infinity)
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
        view.material = .underWindowBackground // Liquid Glass translucency
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Embedded WebView Wrapper
struct WebView: NSViewRepresentable {
    let url: URL
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        nsView.load(request)
    }
}

// MARK: - Docker Stack State Controller
class StackManager: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var consoleLogs: String = ""
    @Published var statusMessage: String = "Stopped"
    
    let displayName: String
    let startExecutable: String
    let startArgs: [String]
    let stopExecutable: String
    let stopArgs: [String]
    let workingDir: String
    let containerName: String
    
    init(name: String, startExe: String, start: [String], stopExe: String, stop: [String], dir: String, container: String) {
        self.displayName = name
        self.startExecutable = startExe
        self.startArgs = start
        self.stopExecutable = stopExe
        self.stopArgs = stop
        self.workingDir = dir
        self.containerName = container
        checkStatus()
    }
    
    func checkStatus() {
        let process = Process()
        var processEnv = ProcessInfo.processInfo.environment
        processEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
        process.environment = processEnv
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
        process.arguments = ["ps", "-a", "--filter", "name=\(containerName)", "--format", "{{.State}}"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        DispatchQueue.main.async {
            if output.contains("running") || output.contains("up") {
                self.isRunning = true
                self.statusMessage = "Running"
            } else if !output.isEmpty {
                self.isRunning = false
                self.statusMessage = output.capitalized
            } else {
                self.isRunning = false
                self.statusMessage = "Stopped"
            }
        }
    }
    
    func startStack() {
        DispatchQueue.main.async {
            self.statusMessage = "Deploying stack..."
            self.consoleLogs = "Running Docker compose build hooks for \(self.displayName)...\n"
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            var processEnv = ProcessInfo.processInfo.environment
            processEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
            process.environment = processEnv
            process.executableURL = URL(fileURLWithPath: self.startExecutable)
            process.arguments = self.startArgs
            process.currentDirectoryURL = URL(fileURLWithPath: self.workingDir)
            
            let pipe = Pipe()
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
                    }
                }
            }
            
            do {
                try process.run()
                process.waitUntilExit()
                fileHandle.readabilityHandler = nil
                
                // Let the server settle, then query state
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.checkStatus()
                }
            } catch {
                fileHandle.readabilityHandler = nil
                DispatchQueue.main.async {
                    self.statusMessage = "Launch error: \(error.localizedDescription)"
                    self.isRunning = false
                }
            }
        }
    }
    
    func stopStack() {
        DispatchQueue.main.async {
            self.statusMessage = "Tearing down stack..."
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            var processEnv = ProcessInfo.processInfo.environment
            processEnv["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:/opt/miniconda3/bin"
            process.environment = processEnv
            process.executableURL = URL(fileURLWithPath: self.stopExecutable)
            process.arguments = self.stopArgs
            process.currentDirectoryURL = URL(fileURLWithPath: self.workingDir)
            
            let pipe = Pipe()
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
                    }
                }
            }
            
            do {
                try process.run()
                process.waitUntilExit()
                fileHandle.readabilityHandler = nil
                
                DispatchQueue.main.async {
                    self.isRunning = false
                    self.statusMessage = "Stopped"
                    self.consoleLogs += "\n[Stack Stopped by User]\n"
                }
            } catch {
                fileHandle.readabilityHandler = nil
                DispatchQueue.main.async {
                    self.statusMessage = "Error on teardown: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Presentation Layer (ContentView)
struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showLogs = false
    
    // Core compose managers
    @StateObject private var toolsStack = StackManager(
        name: "Core Tools",
        startExe: "/usr/local/bin/docker",
        start: ["compose", "-f", "/Users/hassan/local-ai/docker-compose.tools.yml", "up", "-d"],
        stopExe: "/usr/local/bin/docker",
        stop: ["compose", "-f", "/Users/hassan/local-ai/docker-compose.tools.yml", "down"],
        dir: "/Users/hassan/local-ai",
        container: "open-webui"
    )
    
    @StateObject private var difyStack = StackManager(
        name: "Dify Platform",
        startExe: "/usr/local/bin/docker",
        start: ["compose", "-f", "/Users/hassan/local-ai/dify/docker/docker-compose.yaml", "up", "-d"],
        stopExe: "/usr/local/bin/docker",
        stop: ["compose", "-f", "/Users/hassan/local-ai/dify/docker/docker-compose.yaml", "down"],
        dir: "/Users/hassan/local-ai/dify/docker",
        container: "dify-web"
    )
    
    @StateObject private var maxunStack = StackManager(
        name: "Maxun Scraper",
        startExe: "/usr/local/bin/docker",
        start: ["compose", "-f", "/Users/hassan/local-ai/maxun/docker-compose.yml", "up", "-d"],
        stopExe: "/usr/local/bin/docker",
        stop: ["compose", "-f", "/Users/hassan/local-ai/maxun/docker-compose.yml", "down"],
        dir: "/Users/hassan/local-ai/maxun",
        container: "maxun-api"
    )
    
    @StateObject private var lettaStack = StackManager(
        name: "Letta Agents",
        startExe: "/bin/bash",
        start: ["/Users/hassan/local-ai/start_letta.sh"],
        stopExe: "/usr/local/bin/docker",
        stop: ["stop", "letta-server", "letta-db"],
        dir: "/Users/hassan/local-ai",
        container: "letta-server"
    )
    
    var body: some View {
        ZStack {
            VisualEffectView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Drawer
                HStack(spacing: 12) {
                    Text("AI Orchestrator")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.leading, 20)
                    
                    Picker("", selection: $selectedTab) {
                        Text("Dashboard").tag(0)
                        Text("Open WebUI").tag(1)
                        Text("Stirling-PDF").tag(2)
                        Text("n8n").tag(3)
                        Text("Langflow").tag(4)
                        Text("Dify").tag(5)
                        Text("Maxun").tag(6)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 10)
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.04))
                
                Divider()
                
                // Tab Selection Routing
                switch selectedTab {
                case 0:
                    DashboardView(tools: toolsStack, dify: difyStack, maxun: maxunStack, letta: lettaStack)
                case 1:
                    OrchestratedWebView(manager: toolsStack, url: "http://localhost:3000", title: "Open WebUI Chat")
                case 2:
                    OrchestratedWebView(manager: toolsStack, url: "http://localhost:8082", title: "Stirling-PDF Suite")
                case 3:
                    OrchestratedWebView(manager: toolsStack, url: "http://localhost:5678", title: "n8n Automation")
                case 4:
                    OrchestratedWebView(manager: toolsStack, url: "http://localhost:7860", title: "Langflow Agent Graph")
                case 5:
                    OrchestratedWebView(manager: difyStack, url: "http://localhost:8090", title: "Dify LLM Builder")
                default:
                    OrchestratedWebView(manager: maxunStack, url: "http://localhost:8086", title: "Maxun Visual Scraper")
                }
            }
        }
    }
}

// MARK: - Tab 0: Core Dashboard controls
struct DashboardView: View {
    @ObservedObject var tools: StackManager
    @ObservedObject var dify: StackManager
    @ObservedObject var maxun: StackManager
    @ObservedObject var letta: StackManager
    
    @State private var showLogs = false
    @State private var activeLogs = ""
    @State private var activeLogsTitle = ""
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Container Orchestration Dashboard")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Manage the local Docker container engines and backend services on your system")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 12) {
                    // Stack row 1
                    StackRowView(manager: tools, icon: "shippingbox.fill", tint: .blue, logsAction: {
                        self.activeLogs = tools.consoleLogs
                        self.activeLogsTitle = tools.displayName
                        self.showLogs = true
                    })
                    
                    // Stack row 2
                    StackRowView(manager: dify, icon: "cpu.fill", tint: .purple, logsAction: {
                        self.activeLogs = dify.consoleLogs
                        self.activeLogsTitle = dify.displayName
                        self.showLogs = true
                    })
                    
                    // Stack row 3
                    StackRowView(manager: maxun, icon: "network", tint: .green, logsAction: {
                        self.activeLogs = maxun.consoleLogs
                        self.activeLogsTitle = maxun.displayName
                        self.showLogs = true
                    })
                    
                    // Stack row 4
                    StackRowView(manager: letta, icon: "memorychip", tint: .orange, logsAction: {
                        self.activeLogs = letta.consoleLogs
                        self.activeLogsTitle = letta.displayName
                        self.showLogs = true
                    })
                }
                .padding(.horizontal, 20)
            }
            
            if showLogs {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(activeLogsTitle) Live Console Logs:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Close logs") {
                            self.showLogs = false
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                    }
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            Text(activeLogs)
                                .font(.system(.caption, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color(NSColor.textBackgroundColor).opacity(0.3))
                                .cornerRadius(4)
                                .id("logText")
                        }
                        .frame(maxHeight: 120)
                        .onChange(of: activeLogs) { _ in
                            proxy.scrollTo("logText", anchor: .bottom)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Helper UI Row for Stacks
struct StackRowView: View {
    @ObservedObject var manager: StackManager
    let icon: String
    let tint: Color
    let logsAction: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(tint)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(manager.displayName)
                    .fontWeight(.bold)
                HStack(spacing: 6) {
                    Circle()
                        .fill(manager.isRunning ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text("State: \(manager.statusMessage)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Logs") {
                logsAction()
            }
            .buttonStyle(LiquidGlassButtonStyle(isProminent: false))
            
            Button(action: {
                if manager.isRunning {
                    manager.stopStack()
                } else {
                    manager.startStack()
                }
            }) {
                Text(manager.isRunning ? "Stop Stack" : "Start Stack")
                    .fontWeight(.semibold)
            }
            .buttonStyle(LiquidGlassButtonStyle(isProminent: true, accentColor: manager.isRunning ? .red : .blue))
        }
        .padding(12)
        .background(.thinMaterial)
        .cornerRadius(8)
    }
}

// MARK: - Tab 1-6: Container Web Views
struct OrchestratedWebView: View {
    @ObservedObject var manager: StackManager
    let url: String
    let title: String
    
    var body: some View {
        VStack(spacing: 0) {
            if manager.isRunning {
                WebView(url: URL(string: url)!)
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "shippingbox.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("\(title) Stack is Stopped")
                        .font(.headline)
                    Text("Please navigate back to the Dashboard tab and click 'Start Stack' under \(manager.displayName) to deploy the backend containers and access this interface.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
