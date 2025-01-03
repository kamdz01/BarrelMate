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
    @Query(sort: [
        SortDescriptor(\BrewPackage.name, order: .forward),
        SortDescriptor(\BrewPackage.version, order: .forward)
    ]) private var installedPackages: [BrewPackage]

    
    @State private var newPackageName = ""
    @State private var newPackageType: BrewPackage.PackageType = .formula
    
    var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // List installed packages
                Text("Installed Packages").font(.headline)
                
                List {
                    ForEach(installedPackages, id: \.id) { pkg in
                        HStack {
                            Grid(alignment: .leading) {
                                GridRow {
                                    Text(pkg.name)
                                        .gridColumnAlignment(.leading)
                                    Spacer()
                                    Text(pkg.version)
                                        .frame(width: 100, alignment: .leading) // Stała szerokość dla wersji
                                }
                            }
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
                        if viewModel.brewPathFound {
                            Text("Homebrew version: \(viewModel.brewVersion)")
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                        } else {
                            Text("Homebrew not installed")
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
                    await viewModel.refreshPackages()
                }
            }
    }
}

#Preview {
    @Previewable @StateObject var viewModel = BrewViewModel()
    ContentView()
        .modelContainer(BrewPackageContainer)
        .environmentObject(viewModel)
}
