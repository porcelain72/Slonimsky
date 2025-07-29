//
//  SlonimskyApp.swift
//  Slonimsky
//
//  Created by Peter Macdonald on 22/07/2025.
//

import SwiftUI

@main
struct SlonimskyApp: App {
    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1400, height: 900)
    }
}
