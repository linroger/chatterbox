//
//  VoicePreset.swift
//  chatterbox
//
//  Created by Assistant on current date.
//

import Foundation

// MARK: - Voice Presets
struct VoicePreset {
    let exaggeration: Double
    let cfgWeight: Double
    let temperature: Double
    let repetitionPenalty: Double
    let minP: Double
    let topP: Double
    
    static let `default` = VoicePreset(
        exaggeration: 0.5,
        cfgWeight: 0.5,
        temperature: 0.8,
        repetitionPenalty: 1.2,
        minP: 0.05,
        topP: 1.0
    )
    
    static let natural = VoicePreset(
        exaggeration: 0.3,
        cfgWeight: 0.4,
        temperature: 0.7,
        repetitionPenalty: 1.1,
        minP: 0.03,
        topP: 0.9
    )
    
    static let energetic = VoicePreset(
        exaggeration: 1.2,
        cfgWeight: 0.6,
        temperature: 1.0,
        repetitionPenalty: 1.3,
        minP: 0.08,
        topP: 1.0
    )
    
    static let calm = VoicePreset(
        exaggeration: 0.2,
        cfgWeight: 0.3,
        temperature: 0.5,
        repetitionPenalty: 1.0,
        minP: 0.02,
        topP: 0.8
    )
    
    static let professional = VoicePreset(
        exaggeration: 0.4,
        cfgWeight: 0.5,
        temperature: 0.6,
        repetitionPenalty: 1.2,
        minP: 0.04,
        topP: 0.85
    )
    
    static let storyteller = VoicePreset(
        exaggeration: 1.5,
        cfgWeight: 0.7,
        temperature: 1.2,
        repetitionPenalty: 1.4,
        minP: 0.1,
        topP: 1.0
    )
}