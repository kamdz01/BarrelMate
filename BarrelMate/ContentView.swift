//
//  ContentView.swift
//  BarrelMate
//
//  Created by Kamil Dziedzic on 26/12/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var viewModel: BrewViewModel
    @Environment(\.modelContext) private var context
    
    // SwiftData auto-fetch of BrewPackage items
    @Query private var installedPackages: [BrewPackage]
    
    @State private var newPackageName = ""
    @State private var newPackageType: BrewPackage.PackageType = .formula
    
    var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // List installed packages
                Text("Installed Packages").font(.headline)
                
                List {
                    ForEach(installedPackages, id: \.id) { pkg in
                        HStack {
                            Text(pkg.name)
                            Spacer()
                            Text(pkg.version)
                            Spacer()
                            Button("Upgrade") {
                                Task {
                                    await viewModel.upgrade(pkg)
                                }
                            }
                            Button("Uninstall") {
                                Task {
                                    await viewModel.uninstall(pkg)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Install new
                Text("Install New").font(.headline)
                HStack {
                    TextField("Package name", text: $newPackageName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                    
                    Picker("", selection: $newPackageType) {
                        Text("Formula").tag(BrewPackage.PackageType.formula)
                        Text("Cask").tag(BrewPackage.PackageType.cask)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Button("Install") {
                        guard !newPackageName.isEmpty else { return }
                        Task {
                            await viewModel.install(name: newPackageName, type: newPackageType)
                            newPackageName = ""
                        }
                    }
                }
                
                // Error feedback
                if let error = viewModel.lastError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Homebrew")
                            .font(.headline)
                        Spacer()
                        if viewModel.brewPathFound {
                            Text("Version: \(viewModel.brewVersion)")
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                        } else {
                            Text("Not Installed")
                            Image(systemName: "multiply.circle")
                                .foregroundColor(.red)
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh", systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90", action: {
                        Task {
                            await viewModel.checkBrew()
                            await viewModel.refreshPackages()
                        }
                    })
                }
            }
            .padding()
            .onAppear {
                // Let the view model know our ModelContext
                viewModel.modelContext = context
                
                // Initial checks
                Task {
                    await viewModel.checkBrew()
//                    await viewModel.refreshPackages()
                }
            }
    }
}


#Preview {
    @Previewable @StateObject var viewModel = BrewViewModel()
    var container: ModelContainer
    do {
        let storeURL = URL.applicationSupportDirectory.appendingPathComponent("BarrelMate").appending(path: "db.store")
        let config = ModelConfiguration(url: storeURL)
        container = try ModelContainer(for: BrewPackage.self, configurations: config)
    } catch {
        fatalError("Failed to configure SwiftData container.")
    }
    return ContentView()
        .modelContainer(container)
        .environmentObject(viewModel)
}
