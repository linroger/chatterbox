//
//  chatterboxApp.swift
//  chatterbox
//
//  Created by Roger Lin on 6/23/25.
//

import SwiftUI

@main
struct chatterboxApp: App {
    @StateObject private var serverManager: ServerManager
    @StateObject private var ttsManager: TTSManager
    
    init() {
        let serverManager = ServerManager()
        _serverManager = StateObject(wrappedValue: serverManager)
        _ttsManager = StateObject(wrappedValue: TTSManager(serverManager: serverManager))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ttsManager)
                .environmentObject(serverManager)
                .frame(minWidth: 800, minHeight: 600)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    // Clean shutdown when app closes
                    Task {
                        await serverManager.stopServer()
                    }
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Chatterbox") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "Chatterbox",
                            .applicationVersion: "1.0",
                            .credits: NSAttributedString(string: "Text-to-Speech powered by MLX Audio on Apple Silicon")
                        ]
                    )
                }
            }
            
            CommandGroup(after: .newItem) {
                Button("Clear Text") {
                    // This will be handled by keyboard shortcut in ContentView
                }
                .keyboardShortcut("k", modifiers: .command)
            }
            
            CommandGroup(after: .toolbar) {
                Button("Generate Speech") {
                    // This will be handled by keyboard shortcut in ContentView
                }
                .keyboardShortcut(.return, modifiers: .command)
                
                Button("Toggle Playback") {
                    // This will be handled by keyboard shortcut in ContentView
                }
                .keyboardShortcut(.space, modifiers: .command)
            }
        }
    }
}
