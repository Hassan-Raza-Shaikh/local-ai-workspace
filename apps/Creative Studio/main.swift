import SwiftUI
import Foundation
import AppKit
import WebKit

// MARK: - App Entrypoint
@main
struct CreativeStudioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
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

// MARK: - Process Manager for Python Servers
class ServerManager: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var consoleLogs: String = ""
    @Published var statusMessage: String = "Stopped"
    @Published var port: String = "8188"
    @Published var showWebView: Bool = false
    
    private var process: Process?
    private var pipe: Pipe?
    
    let launchScript: String
    let workingDir: String
    let localUrl: String
    let successIndicator: String
    
    init(launchScript: String, workingDir: String, localUrl: String, successIndicator: String, defaultPort: String) {
        self.launchScript = launchScript
        self.workingDir = workingDir
        self.localUrl = localUrl
        self.successIndicator = successIndicator
        self.port = defaultPort
    }
    
    func startServer() {
        DispatchQueue.main.async {
            self.statusMessage = "Launching Python backend..."
            self.consoleLogs = "Starting offline generation server...\n"
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            self.process = process
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = [self.launchScript]
            process.currentDirectoryURL = URL(fileURLWithPath: self.workingDir)
            
            // Set high water mark ratio for MPS optimization
            var env = ProcessInfo.processInfo.environment
            env["PYTORCH_MPS_HIGH_WATERMARK_RATIO"] = "0.0"
            env["PYTORCH_ENABLE_MPS_FALLBACK"] = "1"
            process.environment = env
            
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
                        if outputString.contains(self.successIndicator) || outputString.contains("To see the GUI go to:") || outputString.contains("http://127.0.0.1:") || outputString.contains("Running on local URL:") {
                            self.statusMessage = "Running"
                            self.isRunning = true
                            self.showWebView = true
                        }
                    }
                }
            }
            
            do {
                try process.run()
                
                // Backup timer to show WebView after 8 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    if !self.isRunning {
                        self.isRunning = true
                        self.showWebView = true
                        self.statusMessage = "Running (Active)"
                    }
                }
                
                process.waitUntilExit()
            } catch {
                DispatchQueue.main.async {
                    self.statusMessage = "Failed: \(error.localizedDescription)"
                    self.isRunning = false
                }
            }
        }
    }
    
    func stopServer() {
        DispatchQueue.main.async {
            self.statusMessage = "Stopping..."
            self.showWebView = false
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let process = self.process, process.isRunning {
                process.terminate()
            }
            
            // Reclaim resources by forcefully termination of matching python processes
            let killProcess = Process()
            killProcess.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            if self.launchScript.contains("comfyui") {
                killProcess.arguments = ["-f", "comfyui.*main.py"]
            } else {
                killProcess.arguments = ["-f", "fooocus.*entry_with_update.py"]
            }
            try? killProcess.run()
            killProcess.waitUntilExit()
            
            DispatchQueue.main.async {
                self.isRunning = false
                self.statusMessage = "Stopped"
                self.consoleLogs += "\n[Server Terminated by User]\n"
            }
        }
    }
}

// MARK: - Presentation Layer (ContentView)
struct ContentView: View {
    @State private var selectedTab = 0
    
    // Manage local servers
    @StateObject private var comfyui = ServerManager(
        launchScript: "/Users/hassan/local-ai/start_comfyui.sh",
        workingDir: "/Users/hassan/local-ai/comfyui",
        localUrl: "http://localhost:8188",
        successIndicator: "To see the GUI go to:",
        defaultPort: "8188"
    )
    
    @StateObject private var fooocus = ServerManager(
        launchScript: "/Users/hassan/local-ai/start_fooocus.sh",
        workingDir: "/Users/hassan/local-ai/fooocus",
        localUrl: "http://localhost:7865",
        successIndicator: "Running on local URL:",
        defaultPort: "7865"
    )
    
    var body: some View {
        ZStack {
            VisualEffectView()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Drawer
                HStack(spacing: 12) {
                    Text("Creative Studio")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.leading, 20)
                    
                    Picker("", selection: $selectedTab) {
                        Text("ComfyUI Node Graph").tag(0)
                        Text("Fooocus Art Studio").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 380)
                    
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.04))
                
                Divider()
                
                // Server workspace rendering
                if selectedTab == 0 {
                    StudioWorkspaceView(manager: comfyui, title: "ComfyUI Node Generator", desc: "Start the local ComfyUI server to generate SDXL/Flux node logic workflow diagrams.")
                } else {
                    StudioWorkspaceView(manager: fooocus, title: "Fooocus Midjourney Alternative", desc: "Start the local Fooocus server to generate photorealistic image prompts.")
                }
            }
        }
    }
}

// MARK: - Studio Workspace Render Component
struct StudioWorkspaceView: View {
    @ObservedObject var manager: ServerManager
    let title: String
    let desc: String
    
    @State private var showLogs = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Server Controls bar
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .fontWeight(.semibold)
                    Text("Local Port: \(manager.port)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(manager.isRunning ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text("Server: \(manager.statusMessage)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    if manager.isRunning {
                        manager.stopServer()
                    } else {
                        manager.startServer()
                    }
                }) {
                    Text(manager.isRunning ? "Stop Server" : "Start Server")
                }
                .buttonStyle(.borderedProminent)
                .tint(manager.isRunning ? .red : .blue)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Divider()
            
            // Dynamic Web interface loader
            if manager.showWebView {
                WebView(url: URL(string: "http://localhost:\(manager.port)")!)
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text(title)
                        .font(.headline)
                    Text(desc)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Console diagnostics drawer
            Divider()
            Button(action: {
                withAnimation {
                    showLogs.toggle()
                }
            }) {
                HStack {
                    Text(showLogs ? "Hide Server Logs" : "Show Server Logs")
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
                        Text(manager.consoleLogs)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color(NSColor.textBackgroundColor).opacity(0.3))
                            .cornerRadius(4)
                            .id("logText")
                    }
                    .frame(maxHeight: 110)
                    .onChange(of: manager.consoleLogs) { _ in
                        proxy.scrollTo("logText", anchor: .bottom)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
