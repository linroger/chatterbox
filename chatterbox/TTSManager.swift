//
//  TTSManager.swift
//  chatterbox
//
//  Updated to use server-based architecture
//

import Foundation
import SwiftUI
import AVFoundation
import Combine

// MARK: - TTS Parameters
struct TTSParameters: Codable {
    var text: String
    var outputPath: String
    var audioPromptPath: String?
    var exaggeration: Double = 0.5
    var cfgWeight: Double = 0.5
    var temperature: Double = 0.8
    var repetitionPenalty: Double = 1.2
    var minP: Double = 0.05
    var topP: Double = 1.0
    
    private enum CodingKeys: String, CodingKey {
        case text
        case outputPath = "output_path"
        case audioPromptPath = "audio_prompt_path"
        case exaggeration
        case cfgWeight = "cfg_weight"
        case temperature
        case repetitionPenalty = "repetition_penalty"
        case minP = "min_p"
        case topP = "top_p"
    }
}

// MARK: - TTS Manager
@MainActor
class TTSManager: NSObject, ObservableObject {
    @Published var isInitialized = false
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = "Not initialized"
    @Published var errorMessage: String?
    @Published var device = "Unknown"
    
    // Parameters
    @Published var text = ""
    @Published var voicePromptURL: URL?
    @Published var exaggeration: Double = 0.5
    @Published var cfgWeight: Double = 0.5
    @Published var temperature: Double = 0.8
    @Published var repetitionPenalty: Double = 1.2
    @Published var minP: Double = 0.05
    @Published var topP: Double = 1.0
    
    // Audio player
    var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false
    private var audioPlayerDelegate: AudioPlayerDelegate?
    
    // Server manager
    private let serverManager: ServerManager
    private var initializationTimer: Timer?
    
    init(serverManager: ServerManager) {
        self.serverManager = serverManager
        super.init()
        
        // Wait for server to start, then initialize
        initializationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if self.serverManager.isServerRunning && !self.isInitialized {
                    await self.initializeModel()
                }
            }
        }
    }
    
    deinit {
        initializationTimer?.invalidate()
        audioPlayer?.stop()
        audioPlayer = nil
        audioPlayerDelegate = nil
    }
    
    // MARK: - Model Initialization
    func initializeModel() async {
        statusMessage = "Initializing model..."
        isProcessing = true
        errorMessage = nil
        
        do {
            // Check if server is running first
            guard serverManager.isServerRunning else {
                throw TTSError.serverNotRunning
            }
            
            // Use longer timeout for model initialization
            guard let result = await serverManager.sendServerCommand(command: "init", timeout: 120.0) else {
                throw TTSError.serverCommunicationFailed
            }
            
            if let status = result["status"] as? String, status == "success" {
                isInitialized = true
                device = result["device"] as? String ?? "Unknown"
                
                // Update status message with more details
                if let deviceName = result["device_name"] as? String {
                    statusMessage = "Model initialized on \(deviceName)"
                } else {
                    statusMessage = "Model initialized on \(device)"
                }
                
                initializationTimer?.invalidate()
                initializationTimer = nil
            } else {
                let error = result["message"] as? String ?? "Unknown error"
                throw TTSError.initializationFailed(error)
            }
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Initialization failed"
            print("Model initialization error: \(error)")
            
            // If server is not running, don't spam retries
            if case TTSError.serverNotRunning = error {
                initializationTimer?.invalidate()
                initializationTimer = nil
            }
        }
        
        isProcessing = false
    }
    
    // MARK: - Input Validation
    private func validateInputs() -> Bool {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter some text to generate speech"
            return false
        }
        
        guard text.count <= 1000 else {
            errorMessage = "Text too long (\(text.count) characters). Maximum 1000 characters allowed. Please split into shorter segments."
            return false
        }
        
        // Validate parameter ranges
        guard (0...2).contains(exaggeration) else {
            errorMessage = "Exaggeration must be between 0.0 and 2.0"
            return false
        }
        
        guard (0...1).contains(cfgWeight) else {
            errorMessage = "CFG Weight must be between 0.0 and 1.0"
            return false
        }
        
        guard (0.1...2.0).contains(temperature) else {
            errorMessage = "Temperature must be between 0.1 and 2.0"
            return false
        }
        
        guard (1.0...2.0).contains(repetitionPenalty) else {
            errorMessage = "Repetition Penalty must be between 1.0 and 2.0"
            return false
        }
        
        guard (0...0.2).contains(minP) else {
            errorMessage = "Min P must be between 0.0 and 0.2"
            return false
        }
        
        guard (0.1...1.0).contains(topP) else {
            errorMessage = "Top P must be between 0.1 and 1.0"
            return false
        }
        
        return true
    }
    
    // MARK: - Text-to-Speech Generation
    func generateSpeech() async {
        // Clear previous errors
        errorMessage = nil
        
        // Validate inputs
        guard validateInputs() else {
            return
        }
        
        guard isInitialized else {
            errorMessage = "Model not initialized. Please wait for initialization to complete."
            return
        }
        
        guard serverManager.isServerRunning else {
            errorMessage = "Server not running. Please wait for server to start."
            return
        }
        
        isProcessing = true
        errorMessage = nil
        statusMessage = "Generating speech..."
        progress = 0.2
        
        // Create temporary output file
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        
        let parameters = TTSParameters(
            text: text,
            outputPath: outputURL.path,
            audioPromptPath: voicePromptURL?.path,
            exaggeration: exaggeration,
            cfgWeight: cfgWeight,
            temperature: temperature,
            repetitionPenalty: repetitionPenalty,
            minP: minP,
            topP: topP
        )
        
        do {
            progress = 0.5
            
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(parameters)
            guard let paramsDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                throw TTSError.invalidParameters
            }
            
            guard let result = await serverManager.sendServerCommand(command: "generate", parameters: paramsDict) else {
                throw TTSError.serverCommunicationFailed
            }
            
            progress = 0.8
            
            if let status = result["status"] as? String, status == "success" {
                statusMessage = "Speech generated successfully"
                if let duration = result["duration"] as? Double {
                    statusMessage += " (\(String(format: "%.1f", duration))s)"
                }
                progress = 1.0
                
                // Play the generated audio
                await playAudio(at: outputURL)
            } else {
                let error = result["message"] as? String ?? "Unknown error"
                throw TTSError.generationFailed(error)
            }
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Generation failed"
        }
        
        isProcessing = false
        progress = 0.0
    }
    
    // MARK: - Audio Playback
    func playAudio(at url: URL) async {
        do {
            // Clean up previous player
            audioPlayer?.stop()
            audioPlayer = nil
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayerDelegate = AudioPlayerDelegate { [weak self] in
                Task { @MainActor in
                    self?.isPlaying = false
                }
            }
            audioPlayer?.delegate = audioPlayerDelegate
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            errorMessage = "Failed to play audio: \(error.localizedDescription)"
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    func togglePlayback() async {
        if isPlaying {
            stopAudio()
        } else if let player = audioPlayer {
            player.play()
            isPlaying = true
        }
    }
    
    // MARK: - Presets
    func applyPreset(_ preset: VoicePreset) {
        exaggeration = preset.exaggeration
        cfgWeight = preset.cfgWeight
        temperature = preset.temperature
        repetitionPenalty = preset.repetitionPenalty
        minP = preset.minP
        topP = preset.topP
    }
}

// MARK: - Audio Player Delegate Helper
private class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        super.init()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

// MARK: - Audio Player Delegate
extension TTSManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
        }
    }
}

// MARK: - Error Types
enum TTSError: LocalizedError {
    case initializationFailed(String)
    case generationFailed(String)
    case invalidResponse
    case invalidParameters
    case serverCommunicationFailed
    case serverNotRunning
    case pythonNotFound
    
    var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "Model initialization failed: \(message)"
        case .generationFailed(let message):
            return "Speech generation failed: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidParameters:
            return "Invalid parameters for generation"
        case .serverCommunicationFailed:
            return "Failed to communicate with server"
        case .serverNotRunning:
            return "Server is not running. Please wait for server to start."
        case .pythonNotFound:
            return "Python executable not found"
        }
    }
}
