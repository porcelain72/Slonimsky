//
//  UInt8+Clamping.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

extension UInt8 {
    /// Creates a UInt8 value clamped to the valid MIDI velocity range (0-127)
    init(clamping value: Int) {
        if value < 0 {
            self = 0
        } else if value > 127 {
            self = 127
        } else {
            self = UInt8(value)
        }
    }
    
    /// Creates a UInt8 value clamped to the valid MIDI velocity range (0-127)
    init(clamping value: Double) {
        if value < 0 {
            self = 0
        } else if value > 127 {
            self = 127
        } else {
            self = UInt8(value)
        }
    }
} 