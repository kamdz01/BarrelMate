//
//  BrewAPIDataModels.swift
//  BarrelMate
//
//  Created by Kamil Dziedzic on 03/01/2025.
//

import Foundation

// Formula structure
struct Formula: Codable {
    let name: String
    let fullName: String?
    let desc: String?
    let homepage: String
    let versions: Versions
    let dependencies: [String]
    
    enum CodingKeys: String, CodingKey {
        case name
        case fullName = "full_name"
        case desc
        case homepage
        case versions
        case dependencies
    }
}

struct Versions: Codable {
    let stable: String?
    let head: String?
    let bottle: Bool
}

// Cask structure
struct Cask: Codable {
    let token: String
    let name: [String]
    let desc: String?
    let homepage: String
    let version: String
    let url: String
}
