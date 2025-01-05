//
//  BrewPackage.swift
//  BarrelMate
//
//  Created by Kamil Dziedzic on 26/12/2024.
//

import Foundation
import SwiftUI
import SwiftData

@Model
class BrewPackage {
    enum PackageType: String, Codable {
        case formula
        case cask
    }
    
    var id: UUID
    var name: String
    var version: String
    var packageType: PackageType
    
    init(name: String, version: String, packageType: PackageType) {
        self.id = UUID()
        self.name = name
        self.version = version
        self.packageType = packageType
    }
}
