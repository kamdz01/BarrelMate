//
//  BrewPackageContainer.swift
//  BarrelMate
//
//  Created by Kamil Dziedzic on 02/01/2025.
//

import Foundation
import SwiftData

let BrewPackageContainer: ModelContainer = {
    var container: ModelContainer
    do {
        let storeURL = URL.applicationSupportDirectory.appendingPathComponent("BarrelMate").appending(path: "db.store")
        let config = ModelConfiguration(url: storeURL)
        container = try ModelContainer(for: BrewPackage.self, configurations: config)
    } catch {
        fatalError("Failed to configure SwiftData container.")
    }
    return container
}()
