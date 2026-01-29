//
//  UnhabitApp.swift
//  Unhabit
//
//  Created by Evgenii Sukhov on 16.01.2026.
//

import SwiftUI

@main
struct UnhabitApp: App {
    @StateObject private var settings = AppSettings.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Проверяем при переходе в активное состояние
            if newPhase == .active {
                print("App became active, checking interval increase...")
                if settings.shouldIncreaseIntervalToday() {
                    settings.increaseTimerInterval()
                }
            }
        }
    }
}
