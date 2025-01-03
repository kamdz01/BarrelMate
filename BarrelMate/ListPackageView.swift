//
//  ListPackageView.swift
//  BarrelMate
//
//  Created by Kamil Dziedzic on 03/01/2025.
//

import SwiftUI

struct ListPackageView: View {
    @EnvironmentObject private var viewModel: BrewViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var newPackageName = ""
    
    @State private var filteredFormulae: [Formula] = []
    @State private var filteredCasks: [Cask] = []
    @State private var filterTask: Task<Void, Never>?

    @Binding var selectedPackage: SelectedPackage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Install New Package").font(.headline)
            HStack {
                TextField("Package name", text: $newPackageName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: newPackageName, { filterData(for: newPackageName) })
                    .onAppear() {
                        filteredFormulae = viewModel.formulae
                        filteredCasks = viewModel.casks
                    }
            }
            List {
                Section(header: Text("Formulae")) {
                    ForEach(filteredFormulae, id: \.name) { formula in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(formula.name)
                                if formula.desc != nil {
                                    Text(formula.desc!)
                                        .font(.footnote)
                                }
                            }
                            Spacer()
                            Button(action: {
                                selectedPackage = .formula(formula)
                            }) {
                                Text("Details")
                            }
                        }
                    }
                }
                
                Section(header: Text("Casks")) {
                    ForEach(filteredCasks, id: \.token) { cask in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(cask.token)
                                if cask.desc != nil {
                                    Text(cask.desc!)
                                        .font(.footnote)
                                }
                            }
                            Spacer()
                            Button(action: {
                                selectedPackage = .cask(cask)
                            }) {
                                Text("Details")
                            }
                        }
                    }
                }
            }
            .id(UUID())
            
            // Error feedback
            if let error = viewModel.lastError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    func filterData(for query: String) {
        filterTask?.cancel() // Cancel any ongoing task
        filterTask = Task {
            let formulae = viewModel.formulae
            let casks = viewModel.casks
            
            // Perform filtering
            let filteredFormulae = formulae.filter { formula in
                if Task.isCancelled { return false }
                return query.isEmpty || formula.name.localizedCaseInsensitiveContains(query)
            }
            let filteredCasks = casks.filter { cask in
                if Task.isCancelled { return false }
                return query.isEmpty || cask.token.localizedCaseInsensitiveContains(query)
            }
            
            if Task.isCancelled { return }
            // Update UI on the main actor
            await MainActor.run {
                self.filteredFormulae = filteredFormulae
                self.filteredCasks = filteredCasks
            }
        }
    }
}

#Preview {
    @Previewable @StateObject var viewModel = BrewViewModel()
    ListPackageView(selectedPackage: .constant(nil))
        .environmentObject(viewModel)
        .onAppear {
            Task {
                await viewModel.fetchPackages()
            }
        }
}
