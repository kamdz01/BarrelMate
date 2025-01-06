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
    
    @State private var isAddPackageSheetPresented = false
    @State private var isShowingLoadingIndicator = false
    
    var body: some View {
        ZStack {
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
                                        .frame(width: 100, alignment: .leading)
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
                                    isShowingLoadingIndicator = true
                                    await viewModel.uninstall(pkg)
                                    isShowingLoadingIndicator = false
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Error feedback
                if let error = viewModel.lastError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .disabled(isShowingLoadingIndicator)
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
                    Button("Add Package", systemImage: "plus.circle", action: {
                        isAddPackageSheetPresented.toggle()
                    })
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh", systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90", action: {
                        Task {
                            await withTaskGroup(of: Void.self) { group in
                                group.addTask { await viewModel.checkBrew() }
                                group.addTask { await viewModel.refreshPackages() }
                                group.addTask { await viewModel.fetchPackages() }
                            }
                        }
                    })
                }
            }
            .sheet(isPresented: $isAddPackageSheetPresented) {
                AddPackageView()
                    .environmentObject(viewModel)
            }
            .padding()
            .onAppear {
                // Let the view model know our ModelContext
                viewModel.modelContext = context
                
                // Initial checks
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.checkBrew() }
                        group.addTask { await viewModel.refreshPackages() }
                        group.addTask { await viewModel.fetchPackages() }
                    }
                }
            }
            HStack{
                if isShowingLoadingIndicator {
                    ProgressView()
                }
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
