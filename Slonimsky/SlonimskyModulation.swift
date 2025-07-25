import Foundation

enum ModulationType: String, CaseIterable, Identifiable {
    case none
    case interpolation
    case infrapolation
    case ultrapolation

    var id: String { self.rawValue }
}

struct SlonimskyModulation: Identifiable {
    let id = UUID() // For SwiftUI List iteration
    var type: ModulationType
    var numberOfNewNotes: Int // How many notes to insert/add
    var intervalBetweenNewNotes: Int // The step size for new notes

    static var defaultModulation: SlonimskyModulation {
        SlonimskyModulation(type: .interpolation, numberOfNewNotes: 3, intervalBetweenNewNotes: 1)
    }
}
