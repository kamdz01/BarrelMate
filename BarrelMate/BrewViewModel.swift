//
//  BrewViewModel.swift
//  BarrelMate
//
//  Created by Kamil Dziedzic on 26/12/2024.
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
class BrewViewModel: ObservableObject {
    @Published var brewPathFound: Bool = false
    @Published var brewVersion: String = "Not Installed"
    @Published var lastError: String?
    
    // We'll store a reference to SwiftData context to insert/delete/save packages
    var modelContext: ModelContext?
    
    /// Checks if brew is present and fetches version
    func checkBrew() async {
        if BrewService.findBrewPath() != nil {
            brewPathFound = true
            do {
                let version = try await BrewService.getBrewVersion()
                brewVersion = version
            } catch {
                lastError = error.localizedDescription
            }
        } else {
            brewPathFound = false
            brewVersion = "Not Installed"
        }
    }
    
    /// Fetch installed formulae/casks and sync them to SwiftData
    func refreshPackages() async {
        guard let context = modelContext else { return }
        
        do {
            // Execute the two async calls concurrently
            async let formulae = BrewService.listInstalled(type: .formula)
            async let casks = BrewService.listInstalled(type: .cask)
            
            // Await both results
            let formulaeResult = try await formulae
            let casksResult = try await casks
            
            // Remove existing packages in the store
            let existing = try context.fetch(FetchDescriptor<BrewPackage>())
            for pkg in existing {
                context.delete(pkg)
            }
            
            // Insert the newly fetched packages
            for pkg in formulaeResult + casksResult {
                context.insert(pkg)
            }
            
            // Save changes
            try context.save()
            
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    func install(name: String, type: BrewPackage.PackageType) async {
        do {
            try await BrewService.installPackage(name: name, type: type)
            await refreshPackages()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    func uninstall(_ pkg: BrewPackage) async {
        do {
            try await BrewService.uninstallPackage(name: pkg.name, type: pkg.packageType)
            await refreshPackages()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    func upgrade(_ pkg: BrewPackage) async {
        do {
            try await BrewService.upgradePackage(name: pkg.name, type: pkg.packageType)
            await refreshPackages()
        } catch {
            lastError = error.localizedDescription
        }
    }
}
