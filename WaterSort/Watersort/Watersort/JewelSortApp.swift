//
//  JewelSortApp.swift
//  JewelSort
//
//  Created by 前村　真之介 on 2025/08/28.
//

import SwiftUI

@main
struct JewelSortApp: App {
    @StateObject private var progressStore = ProgressStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(progressStore)
        }
    }
}
