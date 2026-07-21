//
//  CompositionTimelineView.swift
//  Slonimsky
//
//  Horizontal timeline of composition slots with add/duplicate/delete/reorder.
//

import SwiftUI

struct CompositionTimelineView: View {

    @ObservedObject var compositionManager: CompositionManager
    @ObservedObject var parameterManager: ParameterManager
    var onSelectionChanged: (() -> Void)?
    var onCompositionChanged: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("Pattern Chain")
                    .font(.headline)
                    .foregroundColor(Color.garageBandText)

                Spacer()

                HStack(spacing: 6) {
                    Text("Repeat")
                        .font(.caption)
                        .foregroundColor(Color.garageBandSecondary)
                    Stepper(
                        value: Binding(
                            get: { compositionManager.playbackRepeatCount },
                            set: { newValue in
                                compositionManager.playbackRepeatCount = newValue
                                onCompositionChanged?()
                            }
                        ),
                        in: PatternComposition.minRepeatCount...PatternComposition.maxRepeatCount
                    ) {
                        Text("\(compositionManager.playbackRepeatCount)×")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.garageBandText)
                            .frame(minWidth: 28, alignment: .trailing)
                    }
                    .help("How many times the full chain plays and exports")
                }

                HStack(spacing: 4) {
                    timelineButton(systemName: "plus", help: "Add pattern") {
                        compositionManager.writeEditorStateToSelectedSlot(from: parameterManager)
                        _ = compositionManager.addSlot()
                        compositionManager.applySelectedSlot(to: parameterManager)
                        onSelectionChanged?()
                        onCompositionChanged?()
                    }
                    timelineButton(systemName: "doc.on.doc", help: "Duplicate selected") {
                        compositionManager.writeEditorStateToSelectedSlot(from: parameterManager)
                        _ = compositionManager.duplicateSelectedSlot()
                        compositionManager.applySelectedSlot(to: parameterManager)
                        onSelectionChanged?()
                        onCompositionChanged?()
                    }
                    .disabled(compositionManager.selectedSlot == nil)

                    timelineButton(systemName: "trash", help: "Delete selected") {
                        compositionManager.deleteSelectedSlot()
                        compositionManager.applySelectedSlot(to: parameterManager)
                        onSelectionChanged?()
                        onCompositionChanged?()
                    }
                    .disabled(compositionManager.composition.slots.count <= 1)

                    timelineButton(systemName: "chevron.left", help: "Move left") {
                        compositionManager.writeEditorStateToSelectedSlot(from: parameterManager)
                        compositionManager.moveSelectedSlot(by: -1)
                        onCompositionChanged?()
                    }
                    .disabled(!canMoveSelected(by: -1))

                    timelineButton(systemName: "chevron.right", help: "Move right") {
                        compositionManager.writeEditorStateToSelectedSlot(from: parameterManager)
                        compositionManager.moveSelectedSlot(by: 1)
                        onCompositionChanged?()
                    }
                    .disabled(!canMoveSelected(by: 1))
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 8) {
                    ForEach(Array(compositionManager.composition.slots.enumerated()), id: \.element.id) { index, slot in
                        slotBlock(slot: slot, index: index)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
        .background(Color.garageBandPanel)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.garageBandBorder),
            alignment: .bottom
        )
    }

    // MARK: - Slot block

    private func slotBlock(slot: PatternSlot, index: Int) -> some View {
        let isSelected = slot.id == compositionManager.selectedSlotID

        return Button {
            guard slot.id != compositionManager.selectedSlotID else { return }
            compositionManager.writeEditorStateToSelectedSlot(from: parameterManager)
            compositionManager.selectSlot(id: slot.id)
            compositionManager.applySelectedSlot(to: parameterManager)
            onSelectionChanged?()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(slot.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.garageBandText)
                    .lineLimit(1)
                Text(slot.displayGeneratorName)
                    .font(.system(size: 10))
                    .foregroundColor(Color.garageBandSecondary)
                    .lineLimit(1)
                Text("\(Int(slot.parameters.tempo)) BPM")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.garageBandSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minWidth: 120, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.garageBandAccent.opacity(0.25) : Color.garageBandBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isSelected ? Color.garageBandAccent : Color.garageBandBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .help("Pattern \(index + 1): \(slot.name)")
    }

    // MARK: - Helpers

    private func timelineButton(
        systemName: String,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.garageBandText)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.garageBandBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.garageBandBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func canMoveSelected(by offset: Int) -> Bool {
        guard let id = compositionManager.selectedSlotID,
              let index = compositionManager.composition.slots.firstIndex(where: { $0.id == id }) else {
            return false
        }
        return compositionManager.composition.slots.indices.contains(index + offset)
    }
}
