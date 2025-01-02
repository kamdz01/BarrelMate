//
//  BarrelMateApp.swift
//  BarrelMate
//
//  Created by Kamil Dziedzic on 26/12/2024.
//

import SwiftUI
import SwiftData

@main
struct BarrelMateApp: App {
    @StateObject private var viewModel = BrewViewModel()
    var container: ModelContainer

    init() {
        do {
            let storeURL = URL.applicationSupportDirectory.appendingPathComponent("BarrelMate").appending(path: "db.store")
            let config = ModelConfiguration(url: storeURL)
            container = try ModelContainer(for: BrewPackage.self, configurations: config)
        } catch {
            fatalError("Failed to configure SwiftData container.")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Attach a SwiftData container for BrewPackage
                .modelContainer(container)
                // Provide the ViewModel as an environment object
                .environmentObject(viewModel)
        }
    }
}
