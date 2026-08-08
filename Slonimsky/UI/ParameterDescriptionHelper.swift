//
//  ParameterDescriptionHelper.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

/// Helper struct for managing parameter descriptions and localized strings
struct ParameterDescriptionHelper {
    
    // MARK: - Section Descriptions
    
    static func sectionDescription(for category: ParameterCategory) -> String {
        switch category {
        case .presets:
            return "Ready-made configurations that demonstrate meters, meter cycles, isorhythm, Euclidean rhythms, phase curves, and the pattern process. Applying a preset loads every panel so you can inspect and tweak it."
        case .rhythms:
            return "Pick from ~40 built-in grooves — rock, funk, jazz, Afro-Cuban, Brazilian, African bell, Middle Eastern, Balkan, electronic and odd-meter — each in its native time signature. Play them as General MIDI drums on channel 10 or as pitched material on the rhythm's grid, either as the pattern source or layered under it."
        case .melody:
            return "Enter a custom melody by step entry — pick a note value or rest, then click keys. The melody becomes the base material that every other panel transforms: mirror, modulations, rhythm modes, meter cycles, curves, processes, and phasing."
        case .basic:
            return "basic_parameters_description".localized
        case .intervals:
            return "interval_parameters_description".localized
        case .modulations:
            return "modulation_parameters_description".localized
        case .directional:
            return "directional_parameters_description".localized
        case .rhythmic:
            return "rhythmic_parameters_description".localized
        case .harmonic:
            return "harmonic_parameters_description".localized
        case .expression:
            return "expression_parameters_description".localized
        case .accompaniment:
            return "rhythmic_accompaniment_parameters_description".localized
        }
    }
    
    static func sectionTitle(for category: ParameterCategory) -> String {
        switch category {
        case .presets:
            return "Presets"
        case .melody:
            return "Custom Melody"
        case .rhythms:
            return "Rhythm Library"
        case .basic:
            return "basic_parameters_title".localized
        case .intervals:
            return "interval_parameters_title".localized
        case .modulations:
            return "modulation_parameters_title".localized
        case .directional:
            return "directional_parameters_title".localized
        case .rhythmic:
            return "rhythmic_parameters_title".localized
        case .harmonic:
            return "harmonic_parameters_title".localized
        case .expression:
            return "expression_parameters_title".localized
        case .accompaniment:
            return "rhythmic_accompaniment_parameters_title".localized
        }
    }
    
    // MARK: - Parameter Details
    
    static func parameterDetails(for category: ParameterCategory) -> [String] {
        switch category {
        case .presets:
            return [
                "Rhythm Engine Showcase — meters, isorhythm, Euclidean, curves, process",
                "Classic — original generator presets"
            ]
        case .rhythms:
            return [
                "Filter by time signature and family",
                "Drum Kit (GM) or Pitched output",
                "Pattern source or layered under the melody",
                "Lane mutes, rotation, accent boost"
            ]
        case .melody:
            return [
                "Step entry — duration palette, rests, on-screen keyboard",
                "Preview with barlines; click a note to delete",
                "Maximum 8 bars of the current meter cycle"
            ]
        case .basic:
            return [
                "basic_parameters_root_note".localized,
                "basic_parameters_scale_type".localized,
                "basic_parameters_octaves".localized,
                "basic_parameters_divisions".localized,
                "basic_parameters_tempo".localized,
                "basic_parameters_time_signature".localized
            ]
        case .intervals:
            return [
                "interval_parameters_primary_interval".localized,
                "interval_parameters_secondary_interval".localized,
                "interval_parameters_pattern".localized,
                "interval_parameters_inversion".localized,
                "interval_parameters_symmetrical".localized
            ]
        case .modulations:
            return [
                "modulation_parameters_interpolation".localized,
                "modulation_parameters_infrapolation".localized,
                "modulation_parameters_ultrapolation".localized
            ]
        case .directional:
            return [
                "directional_parameters_direction".localized,
                "directional_parameters_mirror_points".localized,
                "directional_parameters_retrograde".localized,
                "directional_parameters_register_shifts".localized,
                "directional_parameters_contour".localized
            ]
        case .rhythmic:
            return [
                "rhythmic_parameters_base_duration".localized
            ]
        case .harmonic:
            return [
                "harmonic_parameters_harmonic_mode".localized,
                "harmonic_parameters_chord_generation".localized,
                "harmonic_parameters_harmonic_rhythm".localized
            ]
        case .expression:
            return [
                "expression_parameters_velocity".localized,
                "expression_parameters_tone_shifting".localized
            ]
        case .accompaniment:
            return [
                "rhythmic_accompaniment_parameters_enabled".localized,
                "rhythmic_accompaniment_parameters_style".localized,
                "rhythmic_accompaniment_parameters_density".localized,
                "rhythmic_accompaniment_parameters_velocity".localized
            ]
        }
    }
    
    // MARK: - Popup Titles
    
    static var sectionInfoTitle: String {
        return "parameter_section_info".localized
    }
    
    static var parameterInfoTitle: String {
        return "parameter_info_title".localized
    }
} 