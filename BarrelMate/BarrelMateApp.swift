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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Attach a SwiftData container for BrewPackage
                .modelContainer(BrewPackageContainer)
                // Provide the ViewModel as an environment object
                .environmentObject(viewModel)
        }
    }
}
