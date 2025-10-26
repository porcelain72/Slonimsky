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
                .onAppear {
                    print("🎵 SlonimskyApp: Application started")
                    print("🎵 SlonimskyApp: Default window size: 1400x1000")
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1400, height: 1000)
    }
}
