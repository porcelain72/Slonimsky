//
//  String+Localization.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 27/01/2025.
//

import Foundation

extension String {
    
    /// Load a localized string from the Localizable.strings file
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Load a localized string with a specific comment
    func localized(comment: String) -> String {
        return NSLocalizedString(self, comment: comment)
    }
    
    /// Load a localized string with format arguments
    func localizedFormat(_ arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
} 