//
//  ServerManager.swift
//  chatterbox
//
//  Created by Assistant on current date.
//
//  Manages the Python TTS server lifecycle
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ServerManager: ObservableObject {
    @Published var isServerRunning = false
    @Published var serverStatus = "Not started"
    @Published var serverError: String?
    
    private var serverProcess: Process?
    private var setupProcess: Process?
    private let processQueue = DispatchQueue(label: "com.chatterbox.server", qos: .userInitiated)
    private lazy var projectRoot: URL = {
        // Try to find the project root relative to the app bundle
        let appBundle = Bundle.main.bundleURL
        let possiblePaths = [
            appBundle.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent(),
            appBundle.deletingLastPathComponent().deletingLastPathComponent(),
            appBundle.deletingLastPathComponent(),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads/chatterbox-mac-OS-test-main")
        ]
        
        for path in possiblePaths {
            let serverScript = path.appendingPathComponent("chatterbox_server.py")
            if FileManager.default.fileExists(atPath: serverScript.path) {
                return path
            }
        }
        
        // Fallback to a default location
        return URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads/chatterbox-mac-OS-test-main")
    }()
    
    // Server configuration
    private var serverHost = "localhost"
    private var serverPort = 8765
    
    init() {
        // Start server when app launches
        Task {
            await startServer()
        }
    }
    
    var projectRootPath: String {
        projectRoot.path
    }
    
    deinit {
        // Terminate server process if running
        if let process = serverProcess, process.isRunning {
            process.terminate()
        }
    }
    
    // MARK: - Virtual Environment Setup
    
    private func checkVirtualEnvironment() async -> Bool {
        let venvPath = projectRoot.appendingPathComponent("venv")
        let venvConfigPath = projectRoot.appendingPathComponent("venv_config.json")
        
        // Check if venv exists
        if !FileManager.default.fileExists(atPath: venvPath.path) {
            serverStatus = "Setting up virtual environment..."
            return await setupVirtualEnvironment()
        }
        
        // Check if config exists
        if !FileManager.default.fileExists(atPath: venvConfigPath.path) {
            serverStatus = "Virtual environment incomplete..."
            return await setupVirtualEnvironment()
        }
        
        return true
    }
    
    private func setupVirtualEnvironment() async -> Bool {
        return await withCheckedContinuation { continuation in
            processQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }
                let setupScript = self.projectRoot.appendingPathComponent("setup_venv.py")
                
                // Check if setup script exists
                guard FileManager.default.fileExists(atPath: setupScript.path) else {
                    Task { @MainActor in
                        self.serverError = "Setup script not found"
                    }
                    continuation.resume(returning: false)
                    return
                }
                
                let process = Process()
                let pipe = Pipe()
                
                process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
                process.standardOutput = pipe
                process.standardError = pipe
                process.arguments = [setupScript.path]
                
                var environment = ProcessInfo.processInfo.environment
                environment["PYTHONUNBUFFERED"] = "1"
                process.environment = environment
                
                do {
                    try process.run()
                    Task { @MainActor in
                        self.setupProcess = process
                    }
                    
                    // Read output in real-time
                    let outputHandle = pipe.fileHandleForReading
                    outputHandle.readabilityHandler = { handle in
                        let data = handle.availableData
                        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                            DispatchQueue.main.async {
                                self.serverStatus = output.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        }
                    }
                    
                    process.waitUntilExit()
                    
                    outputHandle.readabilityHandler = nil
                    
                    if process.terminationStatus == 0 {
                        continuation.resume(returning: true)
                    } else {
                        Task { @MainActor in
                            self.serverError = "Virtual environment setup failed"
                        }
                        continuation.resume(returning: false)
                    }
                } catch {
                    Task { @MainActor in
                        self.serverError = "Failed to run setup script: \(error.localizedDescription)"
                        self.setupProcess = nil
                    }
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // MARK: - Server Management
    
    func startServer() async {
        guard !isServerRunning else { return }
        
        serverStatus = "Starting server..."
        serverError = nil
        
        // Check if server script exists
        let serverScript = projectRoot.appendingPathComponent("chatterbox_server.py")
        guard FileManager.default.fileExists(atPath: serverScript.path) else {
            serverError = "Server script not found at: \(serverScript.path)"
            serverStatus = "Server script missing"
            return
        }
        
        // Validate the script is readable and not a directory
        guard serverScript.path.hasSuffix(".py") else {
            serverError = "Invalid server script - must be a Python file"
            serverStatus = "Invalid server script"
            return
        }
        
        // Check and setup virtual environment if needed
        guard await checkVirtualEnvironment() else {
            serverStatus = "Failed to setup environment"
            return
        }
        
        // Get Python executable from venv
        guard let pythonPath = getVenvPython() else {
            serverError = "Python executable not found in virtual environment"
            serverStatus = "Server start failed"
            return
        }
        
        // Start the server process
        await startServerProcess(pythonPath: pythonPath)
    }
    
    private func getVenvPython() -> String? {
        let venvConfigPath = projectRoot.appendingPathComponent("venv_config.json")
        
        guard let data = try? Data(contentsOf: venvConfigPath),
              let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pythonPath = config["python_executable"] as? String else {
            return nil
        }
        
        return pythonPath
    }
    
    private func startServerProcess(pythonPath: String) async {
        await withCheckedContinuation { continuation in
            processQueue.async { [weak self] in
                guard let self = self else { 
                    continuation.resume()
                    return 
                }
                let serverScript = self.projectRoot.appendingPathComponent("chatterbox_server.py")
                
                let process = Process()
                let pipe = Pipe()
                
                process.executableURL = URL(fileURLWithPath: pythonPath)
                process.standardOutput = pipe
                process.standardError = pipe
                process.arguments = [serverScript.path]
                
                var environment = ProcessInfo.processInfo.environment
                environment["PYTHONUNBUFFERED"] = "1"
                environment["KMP_DUPLICATE_LIB_OK"] = "True"
                process.environment = environment
                
                do {
                    try process.run()
                    Task { @MainActor in
                        self.serverProcess = process
                    }
                    
                    // Monitor server output in background
                    let outputHandle = pipe.fileHandleForReading
                    outputHandle.readabilityHandler = { handle in
                        let data = handle.availableData
                        if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                            print("Server: \(output)")
                        }
                    }
                    
                    continuation.resume()
                } catch {
                    DispatchQueue.main.async {
                        self.serverError = "Failed to start server: \(error.localizedDescription)"
                        self.serverStatus = "Server start failed"
                    }
                    continuation.resume()
                }
            }
        }
        
        // Wait for server to be ready
        if await waitForServerReady() {
            isServerRunning = true
            serverStatus = "Server running and ready"
        } else {
            serverError = "Server failed to become ready"
            serverStatus = "Server start failed"
            
            // Terminate the process if health check failed
            if let process = serverProcess, process.isRunning {
                process.terminate()
            }
            serverProcess = nil
        }
    }
    
    func stopServer() async {
        guard isServerRunning else { return }
        
        // Send shutdown command to server
        _ = await sendServerCommand(command: "shutdown")
        
        // Terminate process if still running after delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        if let process = serverProcess, process.isRunning {
            process.terminate()
        }
        serverProcess = nil
        isServerRunning = false
        serverStatus = "Server stopped"
    }
    
    // MARK: - Server Communication
    
    func sendServerCommand(command: String, parameters: [String: Any]? = nil, timeout: TimeInterval = 60.0) async -> [String: Any]? {
        let url = URL(string: "http://\(serverHost):\(serverPort)")!
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["command": command]
        if let params = parameters {
            body["parameters"] = params
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            if let response = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return response
            }
        } catch {
            print("Server communication error: \(error)")
            serverError = "Communication error: \(error.localizedDescription)"
        }
        
        return nil
    }
    
    func checkServerHealth() async -> Bool {
        let url = URL(string: "http://\(serverHost):\(serverPort)/health")!
        
        do {
            let request = URLRequest(url: url, timeoutInterval: 5.0)
            let (data, _) = try await URLSession.shared.data(for: request)
            if let response = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = response["status"] as? String {
                return status == "success"
            }
        } catch {
            print("Health check failed: \(error)")
            return false
        }
        
        return false
    }
    
    func waitForServerReady(maxAttempts: Int = 30) async -> Bool {
        for attempt in 1...maxAttempts {
            if await checkServerHealth() {
                return true
            }
            
            await MainActor.run {
                self.serverStatus = "Waiting for server (attempt \(attempt)/\(maxAttempts))..."
            }
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        return false
    }
}
