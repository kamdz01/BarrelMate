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
    @Published var formulae: [Formula] = []
    @Published var casks: [Cask] = []
    
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
    
    func fetchPackages() async {
        do {
            let formulaURL = URL(string: "https://formulae.brew.sh/api/formula.json")!
            let caskURL = URL(string: "https://formulae.brew.sh/api/cask.json")!

            async let fetchedFormulae: [Formula] = fetchJSON(url: formulaURL, decodeAs: [Formula].self)
            async let fetchedCasks: [Cask] = fetchJSON(url: caskURL, decodeAs: [Cask].self)

            // Update the properties
            formulae = try await fetchedFormulae
            casks = try await fetchedCasks

            print("Successfully fetched \(formulae.count) formulae and \(casks.count) casks")
        } catch {
            print("Failed to fetch packages: \(error)")
        }
    }

    private func fetchJSON<T: Decodable>(url: URL, decodeAs type: T.Type) async throws -> T {
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
