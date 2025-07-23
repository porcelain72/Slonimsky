//
//  VelocityVisualizer.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 23/07/2025.
//
import SwiftUI

struct VelocityVisualizer: View {
    let sequence: [MIDIInfo]
    let currentNoteIndex: Int?

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .bottom, spacing: 1) {
                ForEach(sequence.indices, id: \.self) { i in
                    let note = sequence[i]
                    let velocity = Double(note.velocity)
                    let isCurrent = (i == currentNoteIndex)

                    Rectangle()
                        .fill(isCurrent ? Color.red : Color.blue)
                        .frame(
                            width: max(1, geo.size.width / CGFloat(sequence.count)),
                            height: CGFloat(velocity / 127.0) * geo.size.height
                        )
                        .overlay(
                            Text("\(note.note)")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(-90)),
                            alignment: .bottom
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 1)
                                .stroke(isCurrent ? Color.white : Color.clear, lineWidth: 1)
                        )
                }
            }
        }
        .frame(height: 200)
        .background(Color.black.opacity(0.1))
        .cornerRadius(8)
        .padding()
    }
}
