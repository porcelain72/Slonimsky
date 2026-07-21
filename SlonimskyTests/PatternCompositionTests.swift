//
//  PatternCompositionTests.swift
//  SlonimskyTests
//
//  Tests for composition concatenation, repeats, and edge cases.
//

import XCTest
@testable import Slonimsky

final class PatternCompositionTests: XCTestCase {

    // MARK: - Repeat clamping

    func testRepeatCountClampedToRange() {
        var composition = PatternComposition(slots: [], playbackRepeatCount: 1)
        composition.setPlaybackRepeatCount(0)
        XCTAssertEqual(composition.playbackRepeatCount, 1)
        composition.setPlaybackRepeatCount(100)
        XCTAssertEqual(composition.playbackRepeatCount, 99)
        composition.setPlaybackRepeatCount(3)
        XCTAssertEqual(composition.playbackRepeatCount, 3)
    }

    // MARK: - Concatenation

    func testConcatenateSlotNotesOffsetsOnsets() {
        let slotA = [
            MIDIInfo(note: 60, velocity: 80, onset: 0, duration: 1),
            MIDIInfo(note: 62, velocity: 80, onset: 1, duration: 1)
        ]
        let slotB = [
            MIDIInfo(note: 64, velocity: 80, onset: 0, duration: 0.5),
            MIDIInfo(note: 65, velocity: 80, onset: 0.5, duration: 0.5)
        ]

        let (notes, starts) = CompositionNoteBuilder.concatenateSlotNotes([slotA, slotB])

        XCTAssertEqual(starts.count, 2)
        XCTAssertEqual(starts[0], 0, accuracy: 1e-9)
        XCTAssertEqual(starts[1], 2, accuracy: 1e-9)
        XCTAssertEqual(notes.count, 4)
        XCTAssertEqual(notes[0].onset, 0, accuracy: 1e-9)
        XCTAssertEqual(notes[1].onset, 1, accuracy: 1e-9)
        XCTAssertEqual(notes[2].onset, 2, accuracy: 1e-9)
        XCTAssertEqual(notes[3].onset, 2.5, accuracy: 1e-9)
        XCTAssertEqual(notes.totalLength, 3, accuracy: 1e-9)
    }

    func testConcatenateEmptySlots() {
        let (notes, starts) = CompositionNoteBuilder.concatenateSlotNotes([])
        XCTAssertTrue(notes.isEmpty)
        XCTAssertTrue(starts.isEmpty)
    }

    // MARK: - Repeats

    func testApplyRepeatsDuplicatesTimeline() {
        let pass = [
            MIDIInfo(note: 60, velocity: 80, onset: 0, duration: 1),
            MIDIInfo(note: 62, velocity: 80, onset: 1, duration: 1)
        ]
        let repeated = CompositionNoteBuilder.applyRepeats(notes: pass, count: 3)

        XCTAssertEqual(repeated.count, 6)
        XCTAssertEqual(repeated[0].onset, 0, accuracy: 1e-9)
        XCTAssertEqual(repeated[2].onset, 2, accuracy: 1e-9)
        XCTAssertEqual(repeated[4].onset, 4, accuracy: 1e-9)
        XCTAssertEqual(repeated.totalLength, 6, accuracy: 1e-9)
    }

    func testApplyRepeatsCountOneIsIdentity() {
        let pass = [MIDIInfo(note: 60, velocity: 80, onset: 0, duration: 1)]
        let repeated = CompositionNoteBuilder.applyRepeats(notes: pass, count: 1)
        XCTAssertEqual(repeated, pass)
    }

    // MARK: - Tempo markers

    func testTempoMarkersAtSlotBoundariesAndRepeats() {
        let markers = CompositionNoteBuilder.tempoMarkers(
            slotTempos: [120, 90],
            slotStartBeats: [0, 4],
            singlePassDuration: 8,
            repeatCount: 2
        )

        // Pass 0: 120@0, 90@4; Pass 1: 120@8, 90@12 — consecutive identical collapsed only when bpm matches
        XCTAssertEqual(markers.count, 4)
        XCTAssertEqual(markers[0].beat, 0, accuracy: 1e-9)
        XCTAssertEqual(markers[0].bpm, 120, accuracy: 1e-9)
        XCTAssertEqual(markers[1].beat, 4, accuracy: 1e-9)
        XCTAssertEqual(markers[1].bpm, 90, accuracy: 1e-9)
        XCTAssertEqual(markers[2].beat, 8, accuracy: 1e-9)
        XCTAssertEqual(markers[2].bpm, 120, accuracy: 1e-9)
        XCTAssertEqual(markers[3].beat, 12, accuracy: 1e-9)
        XCTAssertEqual(markers[3].bpm, 90, accuracy: 1e-9)
    }

    func testTempoMarkersCollapseIdenticalConsecutiveBPM() {
        let markers = CompositionNoteBuilder.tempoMarkers(
            slotTempos: [100, 100],
            slotStartBeats: [0, 2],
            singlePassDuration: 4,
            repeatCount: 1
        )
        XCTAssertEqual(markers.count, 1)
        XCTAssertEqual(markers[0].bpm, 100, accuracy: 1e-9)
    }

    // MARK: - Composition generator

    func testCompositionGeneratorBuildsMultiSlotResult() {
        var paramsA = PatternParameters(rootNote: 60, tempo: 120, iterations: 1)
        paramsA.rhythmSettings.accentBoost = 0
        var paramsB = PatternParameters(rootNote: 62, tempo: 90, iterations: 1)
        paramsB.rhythmSettings.accentBoost = 0

        let composition = PatternComposition(
            slots: [
                PatternSlot(name: "A", generatorNames: ["Scale Pattern Generator"], parameters: paramsA),
                PatternSlot(name: "B", generatorNames: ["Scale Pattern Generator"], parameters: paramsB)
            ],
            playbackRepeatCount: 2
        )

        let generator = CompositionGenerator()
        guard let built = generator.build(composition) else {
            XCTFail("Expected composition build to succeed")
            return
        }

        XCTAssertGreaterThan(built.result.notes.count, 0)
        XCTAssertEqual(built.primaryParameters.tempo, 120, accuracy: 1e-9)
        XCTAssertEqual(built.result.metadata.totalCycles, 2)
        // Two passes: duration should be ~2× single pass
        XCTAssertEqual(built.result.notes.totalLength, built.singlePassDuration * 2, accuracy: 1e-6)
        XCTAssertFalse(built.tempoMarkers.isEmpty)
    }

    func testCompositionGeneratorRejectsEmptyComposition() {
        let generator = CompositionGenerator()
        let built = generator.build(PatternComposition(slots: [], playbackRepeatCount: 1))
        XCTAssertNil(built)
    }

    // MARK: - CompositionManager

    func testCompositionManagerAddDuplicateDelete() {
        let manager = CompositionManager(
            composition: PatternComposition.bootstrapped(
                parameters: PatternParameters(),
                generatorNames: ["Scale Pattern Generator"]
            )
        )
        XCTAssertEqual(manager.composition.slots.count, 1)

        manager.addSlot()
        XCTAssertEqual(manager.composition.slots.count, 2)

        manager.duplicateSelectedSlot()
        XCTAssertEqual(manager.composition.slots.count, 3)

        manager.deleteSelectedSlot()
        XCTAssertEqual(manager.composition.slots.count, 2)

        // Cannot delete last remaining when only one left after deletes
        manager.deleteSelectedSlot()
        XCTAssertEqual(manager.composition.slots.count, 1)
        manager.deleteSelectedSlot()
        XCTAssertEqual(manager.composition.slots.count, 1)
    }

    func testCompositionManagerWriteBackToSelectedSlot() {
        let manager = CompositionManager(
            composition: PatternComposition.bootstrapped(
                parameters: PatternParameters(rootNote: 60),
                generatorNames: ["Scale Pattern Generator"]
            )
        )
        let parameterManager = ParameterManager()
        parameterManager.rootNote = 72
        parameterManager.activeGenerators = ["Interval Pattern Generator"]

        manager.writeEditorStateToSelectedSlot(from: parameterManager)

        XCTAssertEqual(manager.selectedSlot?.parameters.rootNote, 72)
        XCTAssertEqual(manager.selectedSlot?.generatorNames, ["Interval Pattern Generator"])
    }
}
