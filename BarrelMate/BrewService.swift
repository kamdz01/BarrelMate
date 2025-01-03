//
//  BrewService.swift
//  BarrelMate
//
//  Created by Kamil Dziedzic on 26/12/2024.
//

import Foundation

enum BrewError: Error {
    case brewNotFound
    case commandFailed(String)
}

struct BrewService {
    /// Returns a path to brew if it’s found in common locations.
    static func findBrewPath() -> String? {
        let possiblePaths = [
            "/usr/local/bin/brew",
            "/opt/homebrew/bin/brew"
        ]
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    /// Executes a brew command and returns its standard output.
    static func runBrewCommand(arguments: [String]) async throws -> String {
        guard let brewPath = findBrewPath() else {
            throw BrewError.brewNotFound
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: brewPath)
            task.arguments = arguments
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            task.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(decoding: data, as: UTF8.self)
                
                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: BrewError.commandFailed(output))
                }
            }
            
            do {
                try task.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Public Brew Actions
    
    /// Returns the version string from `brew --version`
    static func getBrewVersion() async throws -> String {
        let output = try await runBrewCommand(arguments: ["--version"])
        return String(output.components(separatedBy: "\n").first?.split(separator: " ").last ?? "Unknown")
    }
    
    /// Returns a list of installed packages (formula or cask).
    static func listInstalled(type: BrewPackage.PackageType) async throws -> [BrewPackage] {
        let args = (type == .formula)
            ? ["list", "--versions"]
            : ["list", "--cask", "--versions"]
        
        let output = try await runBrewCommand(arguments: args)
        // Lines look like: "wget 1.21.1", "visual-studio-code 1.2.3", etc.
        let lines = output.split(separator: "\n")
        
        return lines.compactMap { line in
            let components = line.split(separator: " ")
            guard components.count >= 2 else { return nil }
            
            let name = String(components[0])
            let version = String(components[1])
            return BrewPackage(name: name,
                               version: version,
                               packageType: type)
        }
    }
    
    static func installPackage(name: String, type: BrewPackage.PackageType) async throws {
        let args: [String] = (type == .formula)
            ? ["install", name]
            : ["install", "--cask", name]
        
        _ = try await runBrewCommand(arguments: args)
    }
    
    static func uninstallPackage(name: String, type: BrewPackage.PackageType) async throws {
        let args: [String] = (type == .formula)
            ? ["uninstall", name]
            : ["uninstall", "--cask", name]
        
        _ = try await runBrewCommand(arguments: args)
    }
    
    static func upgradePackage(name: String, type: BrewPackage.PackageType) async throws {
        let args: [String] = (type == .formula)
            ? ["upgrade", name]
            : ["upgrade", "--cask", name]
        
        _ = try await runBrewCommand(arguments: args)
    }
}
