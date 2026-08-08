//
//  RhythmLibrary.swift
//  Slonimsky
//
//  Built-in rhythm patterns mapped to General MIDI percussion notes.
//  Patterns are written on a step grid using compact lane strings, so the
//  catalog reads like a drum chart: "X..x..X..x..X..." etc.
//

import Foundation

// MARK: - Drum voices (General MIDI percussion map)

/// A percussion lane. Raw values are the General MIDI note numbers heard on
/// MIDI channel 10 (channel index 9).
enum DrumVoice: String, CaseIterable, Codable, Hashable {
    case kick, sideStick, snare, clap, closedHat, pedalHat, openHat
    case tomLow, tomMid, tomHigh
    case crash, ride, rideBell, cowbell, tambourine, shaker, guiro, triangle
    case claves, woodblockHigh, woodblockLow
    case congaHigh, congaLow, bongoHigh, bongoLow, agogoHigh, agogoLow

    /// General MIDI percussion note number.
    var midiNote: Int {
        switch self {
        case .kick: return 36          // Bass Drum 1
        case .sideStick: return 37
        case .snare: return 38         // Acoustic Snare
        case .clap: return 39
        case .closedHat: return 42
        case .pedalHat: return 44
        case .openHat: return 46
        case .tomLow: return 45
        case .tomMid: return 47
        case .tomHigh: return 50
        case .crash: return 49
        case .ride: return 51
        case .rideBell: return 53
        case .tambourine: return 54
        case .cowbell: return 56
        case .bongoHigh: return 60
        case .bongoLow: return 61
        case .congaHigh: return 63     // Open High Conga
        case .congaLow: return 64      // Low Conga
        case .agogoHigh: return 67
        case .agogoLow: return 68
        case .guiro: return 74         // Long Guiro
        case .claves: return 75
        case .woodblockHigh: return 76
        case .woodblockLow: return 77
        case .shaker: return 82
        case .triangle: return 81      // Open Triangle
        }
    }

    var displayName: String {
        switch self {
        case .kick: return "Kick"
        case .sideStick: return "Side Stick"
        case .snare: return "Snare"
        case .clap: return "Clap"
        case .closedHat: return "Closed Hat"
        case .pedalHat: return "Pedal Hat"
        case .openHat: return "Open Hat"
        case .tomLow: return "Low Tom"
        case .tomMid: return "Mid Tom"
        case .tomHigh: return "High Tom"
        case .crash: return "Crash"
        case .ride: return "Ride"
        case .rideBell: return "Ride Bell"
        case .cowbell: return "Cowbell"
        case .tambourine: return "Tambourine"
        case .shaker: return "Shaker"
        case .guiro: return "Guiro"
        case .triangle: return "Triangle"
        case .claves: return "Claves"
        case .woodblockHigh: return "Woodblock Hi"
        case .woodblockLow: return "Woodblock Lo"
        case .congaHigh: return "Conga Hi"
        case .congaLow: return "Conga Lo"
        case .bongoHigh: return "Bongo Hi"
        case .bongoLow: return "Bongo Lo"
        case .agogoHigh: return "Agogo Hi"
        case .agogoLow: return "Agogo Lo"
        }
    }
}

// MARK: - Pattern

/// A single struck step in a pattern.
struct RhythmHit: Codable, Equatable, Hashable {
    var step: Int
    var voice: DrumVoice
    var accent: Bool = false
}

/// A built-in rhythm: a step grid of hits in a declared meter.
struct RhythmPattern: Codable, Equatable, Hashable {
    /// Unique display name — also the stored identifier in settings.
    var name: String
    var family: String
    /// Native meter; selecting the pattern applies this to the app.
    var meter: Meter
    /// Grid resolution: steps per bar (16 = sixteenths in 4/4).
    var stepsPerBar: Int
    var bars: Int
    var hits: [RhythmHit]
    /// One-line description shown in the browser.
    var note: String

    /// Length of one grid step in beats (quarter note = 1.0).
    var stepBeats: Double {
        guard stepsPerBar > 0 else { return 0.25 }
        return meter.beatsPerBar / Double(stepsPerBar)
    }

    var totalSteps: Int { stepsPerBar * max(1, bars) }

    var totalBeats: Double { Double(totalSteps) * stepBeats }

    /// Lanes used by this pattern, in catalog order (kick first, etc.).
    var voicesUsed: [DrumVoice] {
        var seen: [DrumVoice] = []
        for voice in DrumVoice.allCases where hits.contains(where: { $0.voice == voice }) {
            seen.append(voice)
        }
        return seen
    }

    /// Distinct struck steps across the given lanes, in order — the rhythmic
    /// skeleton used when the pattern drives pitched material.
    func onsetSteps(excluding muted: Set<DrumVoice> = []) -> [Int] {
        let steps = hits.filter { !muted.contains($0.voice) }.map { $0.step }
        return Array(Set(steps)).sorted()
    }

    var isValid: Bool {
        !name.isEmpty
            && stepsPerBar > 0
            && bars >= 1
            && meter.isValid
            && !hits.isEmpty
            && hits.allSatisfy { $0.step >= 0 && $0.step < totalSteps }
    }

    /// Build a pattern from compact lane strings: `x` = hit, `X` = accented
    /// hit, any other character (`.`, `-`, space) = rest. Every lane string
    /// must be `stepsPerBar * bars` characters long.
    static func build(
        _ name: String,
        family: String,
        meter: Meter,
        stepsPerBar: Int,
        bars: Int = 1,
        note: String,
        lanes: [(DrumVoice, String)]
    ) -> RhythmPattern {
        var hits: [RhythmHit] = []
        for (voice, line) in lanes {
            for (step, character) in line.enumerated() {
                switch character {
                case "x": hits.append(RhythmHit(step: step, voice: voice, accent: false))
                case "X": hits.append(RhythmHit(step: step, voice: voice, accent: true))
                default: break
                }
            }
        }
        return RhythmPattern(
            name: name,
            family: family,
            meter: meter,
            stepsPerBar: stepsPerBar,
            bars: bars,
            hits: hits.sorted { $0.step < $1.step },
            note: note
        )
    }
}

// MARK: - Catalog

enum RhythmLibrary {

    // Meters not in Meter.presets
    static let twelveEight = Meter(numerator: 12, denominator: 8, groupings: [3, 3, 3, 3])
    static let fiveEight = Meter(numerator: 5, denominator: 8, groupings: [3, 2])
    static let karsilamaNine = Meter(numerator: 9, denominator: 8, groupings: [2, 2, 2, 3])
    static let kopanitsaEleven = Meter(numerator: 11, denominator: 16, groupings: [2, 2, 3, 2, 2])

    /// Every built-in pattern, grouped by family in catalog order.
    static let patterns: [RhythmPattern] = rockAndPop + funk + jazz + afroCuban + brazilian
        + africanBell + middleEastAndBalkan + electronic + oddMeter

    static func pattern(named name: String) -> RhythmPattern? {
        patterns.first { $0.name == name }
    }

    /// Families in catalog order.
    static var families: [String] {
        var seen: [String] = []
        for pattern in patterns where !seen.contains(pattern.family) {
            seen.append(pattern.family)
        }
        return seen
    }

    /// Distinct meters present in the catalog, in catalog order.
    static var meters: [Meter] {
        var seen: [Meter] = []
        for pattern in patterns where !seen.contains(pattern.meter) {
            seen.append(pattern.meter)
        }
        return seen
    }

    static let defaultPatternName = "Basic Rock"

    // MARK: Rock & Pop (4/4 sixteenths unless noted)

    private static let rockAndPop: [RhythmPattern] = [
        .build("Basic Rock", family: "Rock & Pop", meter: .fourFour, stepsPerBar: 16,
               note: "Backbeat on 2 and 4 with eighth-note hats",
               lanes: [(.closedHat, "x.x.x.x.x.x.x.x."),
                       (.snare,     "....X.......X..."),
                       (.kick,      "X.......X.......")]),

        .build("Four on the Floor", family: "Rock & Pop", meter: .fourFour, stepsPerBar: 16,
               note: "Kick on every beat, hats on the offbeats",
               lanes: [(.openHat,   "..x...x...x...x."),
                       (.clap,      "....x.......x..."),
                       (.kick,      "X...X...X...X...")]),

        .build("Half-Time", family: "Rock & Pop", meter: .fourFour, stepsPerBar: 16,
               note: "Snare on 3 — the pattern feels twice as slow",
               lanes: [(.closedHat, "x.x.x.x.x.x.x.x."),
                       (.snare,     "........X......."),
                       (.kick,      "X.........x.....")]),

        .build("Rock Shuffle", family: "Rock & Pop", meter: .fourFour, stepsPerBar: 12,
               note: "Triplet swing feel with a backbeat",
               lanes: [(.closedHat, "x.xx.xx.xx.x"),
                       (.snare,     "...X.....X.."),
                       (.kick,      "X.....X.....")]),

        .build("Motown", family: "Rock & Pop", meter: .fourFour, stepsPerBar: 16,
               note: "Tambourine eighths over a driving backbeat",
               lanes: [(.tambourine, "x.x.x.x.x.x.x.x."),
                       (.snare,      "....X.......X..."),
                       (.kick,       "X.....x.X.....x.")]),

        .build("Boom Bap", family: "Rock & Pop", meter: .fourFour, stepsPerBar: 16,
               note: "Hip-hop backbeat with a syncopated kick",
               lanes: [(.closedHat, "x.x.x.x.x.x.x.x."),
                       (.snare,     "....X.......X..."),
                       (.kick,      "X..x......X.....")])
    ]

    // MARK: Funk

    private static let funk: [RhythmPattern] = [
        .build("Funk Sixteenths", family: "Funk", meter: .fourFour, stepsPerBar: 16,
               note: "Sixteenth-note hats with a syncopated kick",
               lanes: [(.closedHat, "XxxxXxxxXxxxXxxx"),
                       (.snare,     "....X.......X..."),
                       (.kick,      "X.....x...x.....")]),

        .build("Purdie-style Shuffle", family: "Funk", meter: .fourFour, stepsPerBar: 12,
               note: "Triplet shuffle with ghosted snares",
               lanes: [(.closedHat, "x.xx.xx.xx.x"),
                       (.sideStick, "..x..x..x..x"),
                       (.snare,     "...X.....X.."),
                       (.kick,      "X.....X..x..")]),

        .build("Disco", family: "Funk", meter: .fourFour, stepsPerBar: 16,
               note: "Four-on-the-floor with open hats between beats",
               lanes: [(.openHat, "..x...x...x...x."),
                       (.closedHat, "x...x...x...x..."),
                       (.snare,   "....X.......X..."),
                       (.kick,    "X...X...X...X...")])
    ]

    // MARK: Jazz

    private static let jazz: [RhythmPattern] = [
        .build("Swing Ride", family: "Jazz", meter: .fourFour, stepsPerBar: 12,
               note: "Ding — ding-a-ding ride pattern with hi-hat on 2 and 4",
               lanes: [(.ride,     "X..X.xX..X.x"),
                       (.pedalHat, "...x.....x.."),
                       (.kick,     "X...........")]),

        .build("Jazz Waltz", family: "Jazz", meter: .threeFour, stepsPerBar: 9,
               note: "Three-four ride figure with hi-hat on 2 and 3",
               lanes: [(.ride,     "X..X.xX.."),
                       (.pedalHat, "...x..x.."),
                       (.kick,     "X........")]),

        .build("Brush Ballad", family: "Jazz", meter: .fourFour, stepsPerBar: 12,
               note: "Sparse ballad pulse with side stick",
               lanes: [(.ride,      "X..x..X..x.."),
                       (.sideStick, "...X.....X.."),
                       (.kick,      "X.....x.....")])
    ]

    // MARK: Afro-Cuban

    private static let afroCuban: [RhythmPattern] = [
        .build("Son Clave 3-2", family: "Afro-Cuban", meter: .fourFour, stepsPerBar: 16,
               note: "The five-stroke key of Cuban music: three-side first",
               lanes: [(.claves, "X..x..x...X.x...")]),

        .build("Son Clave 2-3", family: "Afro-Cuban", meter: .fourFour, stepsPerBar: 16,
               note: "Son clave with the two-side leading",
               lanes: [(.claves, "..X.X...x..x..x.")]),

        .build("Rumba Clave 3-2", family: "Afro-Cuban", meter: .fourFour, stepsPerBar: 16,
               note: "Rumba key — third stroke a sixteenth later than son",
               lanes: [(.claves, "X..x...x..X.x...")]),

        .build("Cascara", family: "Afro-Cuban", meter: .fourFour, stepsPerBar: 16,
               note: "Shell pattern played on the side of the timbale",
               lanes: [(.woodblockHigh, "X.x.x..x..x.x.x."),
                       (.claves,        "X..x..x...X.x...")]),

        .build("Tumbao", family: "Afro-Cuban", meter: .fourFour, stepsPerBar: 16,
               note: "Conga tumbao: slaps and open tones",
               lanes: [(.congaLow,  "..x.......x....."),
                       (.congaHigh, "......xx......xx"),
                       (.kick,      "......X.......X.")]),

        .build("Mambo Bell", family: "Afro-Cuban", meter: .fourFour, stepsPerBar: 16,
               note: "Bongo bell mambo figure",
               lanes: [(.cowbell, "X.xxX.xxX.xxX.xx"),
                       (.kick,    "......X.......X.")]),

        .build("Cha-Cha", family: "Afro-Cuban", meter: .fourFour, stepsPerBar: 16,
               note: "Cowbell quarters with the cha-cha-cha turnaround",
               lanes: [(.cowbell,   "X...x...X...x..."),
                       (.congaHigh, "............x.xx"),
                       (.kick,      "X.......X.......")]),

        .build("Songo", family: "Afro-Cuban", meter: .fourFour, stepsPerBar: 16,
               note: "Modern Cuban kit groove with clave-aligned kick",
               lanes: [(.closedHat,  "x.x.x.x.x.x.x.x."),
                       (.sideStick,  "....X.......X..."),
                       (.congaHigh,  ".......x.......x"),
                       (.kick,       "X.....x...X.....")])
    ]

    // MARK: Brazilian

    private static let brazilian: [RhythmPattern] = [
        .build("Bossa Nova", family: "Brazilian", meter: .fourFour, stepsPerBar: 16,
               note: "Bossa clave on rim with a soft surdo kick",
               lanes: [(.closedHat, "x.x.x.x.x.x.x.x."),
                       (.sideStick, "X..x..x...x..x.."),
                       (.kick,      "X.....x.X.....x.")]),

        .build("Samba", family: "Brazilian", meter: .fourFour, stepsPerBar: 16,
               note: "Surdo on 2 and 4 under continuous shaker",
               lanes: [(.shaker,        "xxxxxxxxxxxxxxxx"),
                       (.woodblockHigh, "X..x..x...x..x.."),
                       (.kick,          "x...X...x...X...")]),

        .build("Partido Alto", family: "Brazilian", meter: .fourFour, stepsPerBar: 16,
               note: "Syncopated pandeiro-style figure",
               lanes: [(.tambourine, "X..x..X.x..x..X."),
                       (.kick,       "X.......X.......")]),

        .build("Baião", family: "Brazilian", meter: .fourFour, stepsPerBar: 16,
               note: "Zabumba pattern from the Brazilian northeast",
               lanes: [(.sideStick, "....X.......X..."),
                       (.kick,      "X.....X.X.....X.")])
    ]

    // MARK: African bell patterns

    private static let africanBell: [RhythmPattern] = [
        .build("Short Bell 6/8", family: "African Bell", meter: .sixEight, stepsPerBar: 6,
               note: "The six-pulse bell that underpins much of West Africa",
               lanes: [(.cowbell, "X.xx.x"),
                       (.kick,    "X..x..")]),

        .build("Bembé 12/8", family: "African Bell", meter: twelveEight, stepsPerBar: 12,
               note: "Standard seven-stroke bell across twelve pulses",
               lanes: [(.cowbell, "X.x.xx.x.x.x"),
                       (.congaLow, "X.....x.....")]),

        .build("Highlife", family: "African Bell", meter: .fourFour, stepsPerBar: 16,
               note: "West African guitar-band groove",
               lanes: [(.cowbell, "X.x.X.x.X.x.X.x."),
                       (.congaHigh, "..x..x....x..x.."),
                       (.kick,    "X.....x.X.....x.")]),

        .build("Afro 12/8 Kit", family: "African Bell", meter: twelveEight, stepsPerBar: 12,
               note: "Bembé bell voiced for the drum kit",
               lanes: [(.ride,     "X.x.xx.x.x.x"),
                       (.pedalHat, "...x...x...x"),
                       (.kick,     "X.....x.....")])
    ]

    // MARK: Middle East & Balkan

    private static let middleEastAndBalkan: [RhythmPattern] = [
        .build("Maqsum", family: "Middle East & Balkan", meter: .fourFour, stepsPerBar: 8,
               note: "Dum-tek-tek — the most common Arabic rhythm",
               lanes: [(.kick,  "X..X...."),
                       (.snare, "..x...x."),
                       (.closedHat, "xxxxxxxx")]),

        .build("Baladi", family: "Middle East & Balkan", meter: .fourFour, stepsPerBar: 8,
               note: "Two dums up front, then the tek answer",
               lanes: [(.kick,  "XX..x..."),
                       (.snare, "....x.x."),
                       (.closedHat, "xxxxxxxx")]),

        .build("Ayub", family: "Middle East & Balkan", meter: .twoFour, stepsPerBar: 8,
               note: "Driving Egyptian rhythm in two",
               lanes: [(.kick,  "X..X...."),
                       (.snare, "....x..x"),
                       (.shaker, "xxxxxxxx")]),

        .build("Karsilama 9/8", family: "Middle East & Balkan", meter: karsilamaNine, stepsPerBar: 9,
               note: "Turkish 9/8 grouped 2+2+2+3",
               lanes: [(.kick,      "X...X...."),
                       (.snare,     "..x...x.x"),
                       (.closedHat, "xxxxxxxxx")]),

        .build("Balkan 7/8", family: "Middle East & Balkan", meter: .sevenEight, stepsPerBar: 7,
               note: "Seven grouped 2+2+3 — the Balkan limp",
               lanes: [(.kick,      "X...X.."),
                       (.snare,     "..x...x"),
                       (.closedHat, "xxxxxxx")]),

        .build("Kopanitsa 11/16", family: "Middle East & Balkan", meter: kopanitsaEleven, stepsPerBar: 11,
               note: "Bulgarian eleven grouped 2+2+3+2+2",
               lanes: [(.kick,      "X...X......"),
                       (.snare,     "..x....x.x."),
                       (.closedHat, "xxxxxxxxxxx")])
    ]

    // MARK: Electronic

    private static let electronic: [RhythmPattern] = [
        .build("House", family: "Electronic", meter: .fourFour, stepsPerBar: 16,
               note: "Four-on-the-floor with offbeat open hats and claps",
               lanes: [(.openHat,   "..x...x...x...x."),
                       (.clap,      "....X.......X..."),
                       (.closedHat, "x.x.x.x.x.x.x.x."),
                       (.kick,      "X...X...X...X...")]),

        .build("Techno", family: "Electronic", meter: .fourFour, stepsPerBar: 16,
               note: "Relentless kick with sixteenth hats",
               lanes: [(.closedHat, "xXxxxXxxxXxxxXxx"),
                       (.clap,      "........X......."),
                       (.kick,      "X...X...X...X...")]),

        .build("Breakbeat", family: "Electronic", meter: .fourFour, stepsPerBar: 16,
               note: "Amen-style break with ghosted snares",
               lanes: [(.closedHat, "x.x.x.x.x.x.x.x."),
                       (.snare,     "....X..x....X.x."),
                       (.kick,      "X.........X.....")]),

        .build("Drum and Bass", family: "Electronic", meter: .fourFour, stepsPerBar: 16,
               note: "Two-step break at double-time feel",
               lanes: [(.closedHat, "x.x.x.x.x.x.x.x."),
                       (.snare,     "....X.......X..."),
                       (.kick,      "X........x......")]),

        .build("Trap Hats", family: "Electronic", meter: .fourFour, stepsPerBar: 16,
               note: "Rolling hats with a sparse 808 kick",
               lanes: [(.closedHat, "XxxXxxXxXxxXxxXx"),
                       (.snare,     "........X......."),
                       (.kick,      "X.....x....x....")]),

        .build("Two-Step Garage", family: "Electronic", meter: .fourFour, stepsPerBar: 16,
               note: "Skipping UK garage shuffle",
               lanes: [(.closedHat, "x.xx.x.xx.x.x.xx"),
                       (.snare,     "....X......X...."),
                       (.kick,      "X.......x.......")])
    ]

    // MARK: Odd meter

    private static let oddMeter: [RhythmPattern] = [
        .build("Take Five", family: "Odd Meter", meter: .fiveFour, stepsPerBar: 20,
               note: "Five-four grouped 3+2, ride through the bar",
               lanes: [(.ride,  "x.x.x.x.x.x.x.x.x.x."),
                       (.snare, "....x...........x..."),
                       (.kick,  "X...........X.......")]),

        .build("Prog 7/8", family: "Odd Meter", meter: .sevenEight, stepsPerBar: 14,
               note: "Seven-eight rock grouped 2+2+3",
               lanes: [(.closedHat, "x.x.x.x.x.x.x."),
                       (.snare,     "....X.....X..."),
                       (.kick,      "X.....x.......")]),

        .build("Five-Eight Drive", family: "Odd Meter", meter: fiveEight, stepsPerBar: 5,
               note: "Fast five grouped 3+2",
               lanes: [(.closedHat, "xxxxx"),
                       (.snare,     "..x.."),
                       (.kick,      "X..x.")]),

        .build("Tresillo", family: "Odd Meter", meter: .fourFour, stepsPerBar: 8,
               note: "The 3+3+2 cell behind countless grooves",
               lanes: [(.claves, "X..X..X."),
                       (.kick,   "X..x..x.")]),

        .build("Cinquillo", family: "Odd Meter", meter: .fourFour, stepsPerBar: 8,
               note: "Five-stroke Cuban cell — tresillo filled in",
               lanes: [(.claves, "X.XX.XX.")])
    ]
}

// MARK: - Settings

/// How a selected rhythm participates in generation.
enum RhythmLibraryRole: String, CaseIterable, Codable, Hashable {
    case source = "Pattern Source"
    case layer = "Layer Under Pattern"

    var explanation: String {
        switch self {
        case .source:
            return "The rhythm becomes the pattern; every other panel transforms it"
        case .layer:
            return "The rhythm plays underneath the scale or melody pattern"
        }
    }
}

/// What the rhythm's hits sound as.
enum RhythmLibraryOutput: String, CaseIterable, Codable, Hashable {
    case drumKit = "Drum Kit (GM)"
    case pitched = "Pitched"

    var explanation: String {
        switch self {
        case .drumKit:
            return "Each lane plays its General MIDI percussion note on channel 10"
        case .pitched:
            return "The rhythm's onsets carry pitches from the scale or custom melody"
        }
    }
}

/// Rhythm library selection and playback options.
struct RhythmLibrarySettings: Codable, Equatable, Hashable {
    var isEnabled: Bool = false
    var patternName: String = RhythmLibrary.defaultPatternName
    var role: RhythmLibraryRole = .source
    var output: RhythmLibraryOutput = .drumKit
    var mutedVoices: Set<DrumVoice> = []
    /// Circular shift of the whole pattern, in grid steps.
    var rotationSteps: Int = 0
    /// Velocity added to accented hits.
    var accentBoost: Int = 18

    /// The selected pattern, resolved from the catalog.
    var pattern: RhythmPattern? {
        RhythmLibrary.pattern(named: patternName)
    }

    /// Lanes that will actually sound.
    var audibleVoices: [DrumVoice] {
        (pattern?.voicesUsed ?? []).filter { !mutedVoices.contains($0) }
    }

    func validate() -> Bool {
        guard accentBoost >= 0 && accentBoost <= 64 else { return false }
        guard rotationSteps >= 0 else { return false }
        if isEnabled {
            guard let pattern = pattern, pattern.isValid else { return false }
            guard !audibleVoices.isEmpty else { return false }
        }
        return true
    }
}
