//
//  ContentView.swift
//  chatterbox
//
//  Created by Roger Lin on 6/23/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var ttsManager: TTSManager
    @State private var selectedTab = 0
    @State private var isShowingVoiceFilePicker = false
    
    var body: some View {
        HSplitView {
            // Main content area
            VStack(spacing: 0) {
                // Header
                HeaderView()
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Text input section
                        TextInputSection()
                        
                        // Voice configuration section
                        VoiceConfigurationSection(isShowingVoiceFilePicker: $isShowingVoiceFilePicker)
                        
                        // Advanced settings
                        AdvancedSettingsSection()
                        
                        // Action buttons
                        ActionButtonsSection()
                        
                        // Status section
                        StatusSection()
                    }
                    .padding(20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 500)
            
            // Sidebar (optional - for presets/history)
            if selectedTab == 1 {
                PresetsView()
                    .frame(width: 250)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { selectedTab = 0 }) {
                    Label("Main", systemImage: "mic.fill")
                }
                .buttonStyle(.borderless)
                
                Button(action: { selectedTab = 1 }) {
                    Label("Presets", systemImage: "star.fill")
                }
                .buttonStyle(.borderless)
            }
        }
        .fileImporter(
            isPresented: $isShowingVoiceFilePicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    ttsManager.voicePromptURL = url
                }
            case .failure(let error):
                ttsManager.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "waveform.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Chatterbox")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Text-to-Speech powered by Resemble AI")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Text Input Section
struct TextInputSection: View {
    @EnvironmentObject var ttsManager: TTSManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Text to Speak", systemImage: "text.quote")
                .font(.headline)
            
            TextEditor(text: $ttsManager.text)
                .font(.system(.body))
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if ttsManager.text.isEmpty {
                        Text("Enter the text you want to convert to speech...")
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }
            
            HStack {
                HStack(spacing: 4) {
                    Text("\(ttsManager.text.count) / 1000 characters")
                        .font(.caption)
                        .foregroundColor(ttsManager.text.count > 1000 ? .red : (ttsManager.text.count > 800 ? .orange : .secondary))
                    
                    if ttsManager.text.count > 1000 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if ttsManager.text.count > 800 {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                Button("Clear") {
                    ttsManager.text = ""
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .disabled(ttsManager.text.isEmpty)
                .keyboardShortcut("k", modifiers: .command)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Voice Configuration Section
struct VoiceConfigurationSection: View {
    @EnvironmentObject var ttsManager: TTSManager
    @Binding var isShowingVoiceFilePicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Voice Configuration", systemImage: "person.wave.2")
                .font(.headline)
            
            HStack {
                Text("Voice Prompt:")
                    .frame(width: 100, alignment: .trailing)
                
                if let url = ttsManager.voicePromptURL {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(.accentColor)
                        Text(url.lastPathComponent)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Spacer()
                        
                        Button(action: { ttsManager.voicePromptURL = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                } else {
                    Button("Choose Audio File...") {
                        isShowingVoiceFilePicker = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Optional: Select an audio file to use as a voice reference")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Chatterbox will clone the voice characteristics from your audio sample. Works best with 3-10 second clear speech samples.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.8)
            }
            .padding(.leading, 105)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Advanced Settings Section
struct AdvancedSettingsSection: View {
    @EnvironmentObject var ttsManager: TTSManager
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 16) {
                ParameterSlider(
                    label: "Exaggeration",
                    value: $ttsManager.exaggeration,
                    range: 0...2,
                    step: 0.1,
                    helpText: "Controls emotional intensity and voice expressiveness. Higher values make speech more dramatic and energetic, lower values make it more neutral. Default: 0.5"
                )
                
                ParameterSlider(
                    label: "CFG Weight",
                    value: $ttsManager.cfgWeight,
                    range: 0...1,
                    step: 0.05,
                    helpText: "Classifier-free guidance strength. Controls adherence to voice prompt. Lower values (~0.3) work better for fast speakers or dramatic speech. Default: 0.5"
                )
                
                ParameterSlider(
                    label: "Temperature",
                    value: $ttsManager.temperature,
                    range: 0.1...2.0,
                    step: 0.1,
                    helpText: "Controls randomness in speech generation. Higher values create more varied/creative output, lower values are more predictable. Default: 0.8"
                )
                
                ParameterSlider(
                    label: "Repetition Penalty",
                    value: $ttsManager.repetitionPenalty,
                    range: 1.0...2.0,
                    step: 0.1,
                    helpText: "Prevents the model from repeating sounds or patterns. Higher values reduce repetition but may affect naturalness. Default: 1.2"
                )
                
                ParameterSlider(
                    label: "Min P",
                    value: $ttsManager.minP,
                    range: 0...0.2,
                    step: 0.01,
                    helpText: "Minimum probability threshold for token selection. Filters out very unlikely sounds. Lower values = more diversity. Default: 0.05"
                )
                
                ParameterSlider(
                    label: "Top P",
                    value: $ttsManager.topP,
                    range: 0.1...1.0,
                    step: 0.05,
                    helpText: "Nucleus sampling: considers only the most likely tokens that sum to this probability. Lower values = more focused/consistent. Default: 1.0"
                )
            }
            .padding(.top, 12)
        } label: {
            Label("Advanced Settings", systemImage: "slider.horizontal.3")
                .font(.headline)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Parameter Slider Component
struct ParameterSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let helpText: String
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 4) {
                    Text(label)
                        .frame(width: 100, alignment: .trailing)
                    
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(isHovering ? .accentColor : .secondary)
                        .help(helpText)
                }
                .frame(width: 120, alignment: .trailing)
                .onHover { hovering in
                    isHovering = hovering
                }
                
                Slider(value: $value, in: range, step: step)
                
                Text(String(format: "%.2f", value))
                    .font(.system(.body, design: .monospaced))
                    .frame(width: 50, alignment: .trailing)
                    .foregroundColor(.secondary)
            }
            
            if isHovering {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 125)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isHovering)
    }
}

// MARK: - Action Buttons Section
struct ActionButtonsSection: View {
    @EnvironmentObject var ttsManager: TTSManager
    
    private var buttonHelpText: String {
        if !ttsManager.isInitialized {
            return "Wait for model to initialize before generating speech"
        } else if ttsManager.text.isEmpty {
            return "Enter some text to generate speech"
        } else if ttsManager.text.count > 1000 {
            return "Text is too long. Maximum 1000 characters allowed."
        } else if ttsManager.isProcessing {
            return "Speech generation in progress..."
        } else {
            return "Generate speech from the entered text"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                Task {
                    await ttsManager.generateSpeech()
                }
            }) {
                HStack(spacing: 8) {
                    if ttsManager.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(ttsManager.isProcessing ? "Generating..." : "Generate Speech")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(ttsManager.text.isEmpty || ttsManager.text.count > 1000 || ttsManager.isProcessing || !ttsManager.isInitialized)
            .help(buttonHelpText)
            .keyboardShortcut(.return, modifiers: .command)
            
            if ttsManager.audioPlayer != nil {
                Button(action: {
                    Task {
                        await ttsManager.togglePlayback()
                    }
                }) {
                    Label(
                        ttsManager.isPlaying ? "Stop" : "Play",
                        systemImage: ttsManager.isPlaying ? "stop.fill" : "play.fill"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut(.space, modifiers: .command)
            }
        }
    }
}

// MARK: - Status Section
struct StatusSection: View {
    @EnvironmentObject var ttsManager: TTSManager
    @EnvironmentObject var serverManager: ServerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Progress bar
            if ttsManager.isProcessing {
                ProgressView(value: ttsManager.progress)
                    .progressViewStyle(.linear)
            }
            
            // Server status
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(serverManager.isServerRunning ? Color.green : (serverManager.serverError != nil ? Color.red : Color.orange))
                        .frame(width: 8, height: 8)
                    
                    Text("Server:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(serverManager.serverStatus)
                        .font(.caption)
                }
                
                Spacer()
                
                if !serverManager.isServerRunning && serverManager.serverError == nil {
                    Button("Retry") {
                        Task {
                            await serverManager.startServer()
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .font(.caption)
                }
            }
            
            // TTS status info
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(ttsManager.isInitialized ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text("Model:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(ttsManager.statusMessage)
                        .font(.caption)
                }
                
                Spacer()
                
                if ttsManager.isInitialized {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.caption)
                        Text("Device: \(ttsManager.device.uppercased())")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            // Error messages
            if let error = serverManager.serverError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Server Error:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
            
            if let error = ttsManager.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TTS Error:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Presets View
struct PresetsView: View {
    @EnvironmentObject var ttsManager: TTSManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Voice Presets")
                .font(.headline)
                .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    PresetRow(
                        name: "Natural",
                        icon: "person.fill",
                        description: "Balanced and conversational",
                        parameters: VoicePreset.natural
                    )
                    PresetRow(
                        name: "Energetic",
                        icon: "bolt.fill",
                        description: "High energy and expressive",
                        parameters: VoicePreset.energetic
                    )
                    PresetRow(
                        name: "Calm",
                        icon: "leaf.fill",
                        description: "Gentle and soothing",
                        parameters: VoicePreset.calm
                    )
                    PresetRow(
                        name: "Professional",
                        icon: "briefcase.fill",
                        description: "Clear and authoritative",
                        parameters: VoicePreset.professional
                    )
                    PresetRow(
                        name: "Storyteller",
                        icon: "book.fill",
                        description: "Dramatic and engaging",
                        parameters: VoicePreset.storyteller
                    )
                }
                .padding()
            }
            
            Spacer()
            
            // Reset to defaults button
            Button("Reset to Defaults") {
                ttsManager.applyPreset(VoicePreset.default)
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct PresetRow: View {
    let name: String
    let icon: String
    let description: String
    let parameters: VoicePreset
    @EnvironmentObject var ttsManager: TTSManager
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
        .onTapGesture {
            ttsManager.applyPreset(parameters)
        }
        .help("Apply \(name.lowercased()) voice settings")
    }
}


#Preview {
    let serverManager = ServerManager()
    ContentView()
        .environmentObject(TTSManager(serverManager: serverManager))
        .environmentObject(serverManager)
        .frame(width: 900, height: 700)
}