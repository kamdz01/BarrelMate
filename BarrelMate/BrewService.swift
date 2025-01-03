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

actor OutputCollector {
    private var stdoutData = Data()
    private var stderrData = Data()
    
    func appendStdout(_ data: Data) {
        stdoutData.append(data)
    }
    
    func appendStderr(_ data: Data) {
        stderrData.append(data)
    }
    
    func getStdoutString() -> String {
        String(data: stdoutData, encoding: .utf8) ?? ""
    }
    
    func getStderrString() -> String {
        String(data: stderrData, encoding: .utf8) ?? ""
    }
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
    
    /// Executes a brew command and *streams* each line of stdout/stderr via `onLineUpdate`.
    /// Returns the entire stdout once the process completes.
    static func runBrewCommandStreaming(arguments: [String], onLineUpdate: @escaping (String) -> Void) async throws -> String {
        guard let brewPath = findBrewPath() else {
            throw BrewError.brewNotFound
        }

        // The actor that collects output concurrently.
        let collector = OutputCollector()
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: brewPath)
            task.arguments = arguments

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            task.standardOutput = stdoutPipe
            task.standardError  = stderrPipe
            
            // Handle stdout in real time.
            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                
                Task {
                    // Safely append to the actor.
                    await collector.appendStdout(data)
                    
                    // Convert any newly read chunk into lines, call back.
                    if let text = String(data: data, encoding: .utf8) {
                        for line in text.components(separatedBy: .newlines) where !line.isEmpty {
                            onLineUpdate(line)
                        }
                    }
                }
            }
            
            // Handle stderr similarly.
            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                
                Task {
                    await collector.appendStderr(data)
                    
                    if let text = String(data: data, encoding: .utf8) {
                        for line in text.components(separatedBy: .newlines) where !line.isEmpty {
                            onLineUpdate(line)
                        }
                    }
                }
            }

            // Termination handler is called once the process exits.
            task.terminationHandler = { process in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil

                Task {
                    // Retrieve final results from the actor.
                    let finalStdout = await collector.getStdoutString()
                    let finalStderr = await collector.getStderrString()

                    if process.terminationStatus == 0 {
                        continuation.resume(returning: finalStdout)
                    } else {
                        continuation.resume(throwing: BrewError.commandFailed(finalStderr))
                    }
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
    
    /// Installs a package, streaming the output and mapping lines to progress updates.
    static func installPackageWithProgress(name: String, type: BrewPackage.PackageType, onProgress: @escaping (Double) -> Void) async throws {
        let args: [String] = (type == .formula)
            ? ["install", name]
            : ["install", "--cask", name]

        // A naive example of progress states:
        let phases: [String: Double] = [
            "==> Downloading":               0.1,
            "==> Fetching dependencies":     0.2,
            "==> Installing dependencies":   0.4,
            "==> Installing \(name)":        0.6,
            "==> Summary":                   0.8
        ]
        onProgress(0.01)
        let _ = try await runBrewCommandStreaming(arguments: args) { line in
            // Each time brew outputs a line, we check if it matches one of our known phases
            for (key, progressValue) in phases {
                if line.contains(key) {
                    onProgress(progressValue)
                    break
                }
            }
        }
        onProgress(1.0)
    }
}
