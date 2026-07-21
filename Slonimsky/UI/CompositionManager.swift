//
//  CompositionManager.swift
//  Slonimsky
//
//  Owns the user-authored pattern composition and selected timeline slot.
//

import Foundation
import Combine

/// Manages the pattern composition timeline and selection sync with ParameterManager.
final class CompositionManager: ObservableObject {

    // MARK: - Published

    @Published private(set) var composition: PatternComposition
    @Published var selectedSlotID: UUID?

    /// True while pushing a slot into ParameterManager (suppresses write-back).
    private(set) var isApplyingSlotToEditor = false

    // MARK: - Init

    init(composition: PatternComposition = PatternComposition()) {
        self.composition = composition
        self.selectedSlotID = composition.slots.first?.id
    }

    // MARK: - Accessors

    var selectedSlot: PatternSlot? {
        guard let id = selectedSlotID else { return nil }
        return composition.slots.first { $0.id == id }
    }

    var playbackRepeatCount: Int {
        get { composition.playbackRepeatCount }
        set {
            var updated = composition
            updated.setPlaybackRepeatCount(newValue)
            composition = updated
        }
    }

    // MARK: - Bootstrap

    /// Ensure at least one slot exists, seeded from the current editor state.
    func ensureBootstrapped(
        parameters: PatternParameters,
        generatorNames: [String],
        combinationMode: PatternCombinationMode
    ) {
        guard composition.slots.isEmpty else { return }
        let boot = PatternComposition.bootstrapped(
            parameters: parameters,
            generatorNames: generatorNames,
            combinationMode: combinationMode
        )
        composition = boot
        selectedSlotID = boot.slots.first?.id
    }

    // MARK: - Slot CRUD

    func selectSlot(id: UUID?) {
        selectedSlotID = id
    }

    /// Add a new slot by copying the selected slot (or last / defaults).
    @discardableResult
    func addSlot(
        copyingFrom source: PatternSlot? = nil,
        parameters: PatternParameters? = nil,
        generatorNames: [String]? = nil,
        combinationMode: PatternCombinationMode? = nil
    ) -> PatternSlot {
        let template = source
            ?? selectedSlot
            ?? composition.slots.last

        let nextIndex = composition.slots.count + 1
        let newSlot: PatternSlot
        if let template = template {
            newSlot = PatternSlot(
                name: "Pattern \(nextIndex)",
                generatorNames: generatorNames ?? template.generatorNames,
                combinationMode: combinationMode ?? template.combinationMode,
                parameters: parameters ?? template.parameters
            )
        } else {
            newSlot = PatternSlot(
                name: "Pattern \(nextIndex)",
                generatorNames: generatorNames ?? ["Scale Pattern Generator"],
                combinationMode: combinationMode ?? .sequential,
                parameters: parameters ?? PatternParameters()
            )
        }

        var updated = composition
        updated.slots.append(newSlot)
        composition = updated
        selectedSlotID = newSlot.id
        return newSlot
    }

    @discardableResult
    func duplicateSelectedSlot() -> PatternSlot? {
        guard let selected = selectedSlot,
              let index = composition.slots.firstIndex(where: { $0.id == selected.id }) else {
            return nil
        }
        let copy = selected.duplicated(name: "\(selected.name) copy")
        var updated = composition
        updated.slots.insert(copy, at: index + 1)
        composition = updated
        selectedSlotID = copy.id
        return copy
    }

    func deleteSelectedSlot() {
        guard let id = selectedSlotID,
              let index = composition.slots.firstIndex(where: { $0.id == id }) else { return }
        // Keep at least one slot
        guard composition.slots.count > 1 else { return }

        var updated = composition
        updated.slots.remove(at: index)
        composition = updated

        let newIndex = min(index, updated.slots.count - 1)
        selectedSlotID = updated.slots[newIndex].id
    }

    func moveSlot(from source: IndexSet, to destination: Int) {
        var updated = composition
        updated.slots.move(fromOffsets: source, toOffset: destination)
        composition = updated
    }

    func moveSelectedSlot(by offset: Int) {
        guard let id = selectedSlotID,
              let index = composition.slots.firstIndex(where: { $0.id == id }) else { return }
        let newIndex = index + offset
        guard composition.slots.indices.contains(newIndex) else { return }
        var updated = composition
        updated.slots.swapAt(index, newIndex)
        composition = updated
    }

    func renameSlot(id: UUID, name: String) {
        guard let index = composition.slots.firstIndex(where: { $0.id == id }) else { return }
        var updated = composition
        updated.slots[index].name = name
        composition = updated
    }

    // MARK: - Editor sync

    /// Push the selected slot's settings into ParameterManager.
    func applySelectedSlot(to parameterManager: ParameterManager) {
        guard let slot = selectedSlot else { return }
        isApplyingSlotToEditor = true
        defer { isApplyingSlotToEditor = false }

        parameterManager.setParameters(slot.parameters)
        parameterManager.activeGenerators = slot.generatorNames
        parameterManager.combinationMode = slot.combinationMode
        if let first = slot.generatorNames.first {
            parameterManager.selectedGeneratorForAutoGeneration = first
        }
    }

    /// Write current ParameterManager state back into the selected slot.
    func writeEditorStateToSelectedSlot(from parameterManager: ParameterManager) {
        guard !isApplyingSlotToEditor else { return }
        guard let id = selectedSlotID,
              let index = composition.slots.firstIndex(where: { $0.id == id }) else { return }

        var updated = composition
        updated.slots[index].parameters = parameterManager.currentParameters
        updated.slots[index].generatorNames = parameterManager.activeGenerators
        updated.slots[index].combinationMode = parameterManager.combinationMode
        composition = updated
    }
}
