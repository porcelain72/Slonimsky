//
//  ParameterInfoPopupView.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import SwiftUI

/// Popup view for displaying parameter section information
struct ParameterInfoPopupView: View {
    
    // MARK: - Properties
    let category: ParameterCategory
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerView
            
            // Description
            descriptionView
            
            // Parameter Details
            parameterDetailsView
            
            // Close Button
            closeButton
        }
        .padding(20)
        .frame(width: 400, height: 500)
        .background(Color.garageBandBackground)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(Color.garageBandAccent)
            
            Text(ParameterDescriptionHelper.sectionTitle(for: category))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color.garageBandText)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color.garageBandSecondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Description
    
    private var descriptionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.garageBandText)
            
            Text(ParameterDescriptionHelper.sectionDescription(for: category))
                .font(.body)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(Color.garageBandText)
        }
    }
    
    // MARK: - Parameter Details
    
    private var parameterDetailsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parameters")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.garageBandText)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(ParameterDescriptionHelper.parameterDetails(for: category), id: \.self) { detail in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                                .foregroundColor(Color.garageBandAccent)
                                .padding(.top, 4)
                            
                            Text(detail)
                                .font(.body)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(Color.garageBandText)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Close Button
    
    private var closeButton: some View {
        HStack {
            Spacer()
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Helper Properties
    
    private var iconName: String {
        switch category {
        case .presets:
            return "square.grid.2x2"
        case .melody:
            return "pianokeys"
        case .basic:
            return "music.note"
        case .intervals:
            return "arrow.up.and.down"
        case .modulations:
            return "waveform.path.ecg"
        case .directional:
            return "arrow.triangle.turn.up.right.circle"
        case .rhythmic:
            return "clock"
        case .harmonic:
            return "music.note.list"
        case .expression:
            return "slider.horizontal.3"
        case .accompaniment:
            return "drumsticks"
        }
    }
}

// MARK: - Preview

struct ParameterInfoPopupView_Previews: PreviewProvider {
    static var previews: some View {
        ParameterInfoPopupView(category: .basic)
            .frame(width: 400, height: 500)
    }
} 