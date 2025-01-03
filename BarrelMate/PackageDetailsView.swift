//
//  PackageDetailsView.swift
//  BarrelMate
//
//  Created by Kamil Dziedzic on 03/01/2025.
//

import SwiftUI

struct PackageDetailsView: View {
    @EnvironmentObject private var viewModel: BrewViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPackage: SelectedPackage?
    @State var installProgress: Double = 0.0

    var body: some View {
        VStack {
            switch selectedPackage {
            case .formula(let formula):
                VStack(alignment: .leading, spacing: 10) {
                    Text("Formula details")
                        .font(.title3)
                    Divider()
                    Text("Name: \(formula.name)")
                    if let description = formula.desc {
                        Text("Description: \(description)")
                            .font(.body)
                    }
                    HStack(spacing: 0) {
                        Text("Homepage: ")
                        Link(formula.homepage, destination: URL(string: formula.homepage)!)
                            .underline()
                    }
                    Divider()
                    Text("Version (stable): \(formula.versions.stable ?? "")")
                    Text("Bottle: \(formula.versions.bottle)")
                    if installProgress > 0 {
                        ProgressView(value: installProgress)
                            .padding()
                    }
                    if installProgress == 1 {
                        VStack(alignment: .center) {
                            Text("Installation complete")
                                .font(.headline)
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(.green)
                                .font(.largeTitle)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    if (!viewModel.installedPackages.contains(where: {tmp in
                        return tmp.name == formula.name
                    }) && installProgress == 0) {
                        VStack(alignment: .center) {
                            Button("Install", action: {
                                Task {
                                    do {
                                        try await BrewService.installPackageWithProgress(
                                            name: formula.name,
                                            type: .formula
                                        ) { progress in
                                            Task { @MainActor in
                                                withAnimation{
                                                    installProgress = progress
                                                }
                                            }
                                        }
                                        await viewModel.refreshPackages()
                                    } catch {
                                        print("Install failed with error: \(error)")
                                    }
                                }
                            })
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            case .cask(let cask):
                VStack(alignment: .leading, spacing: 10) {
                    Text("Cask details")
                        .font(.title3)
                    Divider()
                    Text("Token: \(cask.token)")
                    Text("Name: \(cask.name)")
                    if let description = cask.desc {
                        Text("Description: \(description)")
                            .font(.body)
                    }
                    Text("Version: \(cask.version)")
                    Button("Install", action: {
                        Task {
                            await viewModel.install(name: cask.token, type: .cask)
                        }
                    })

                }
            default:
                Text("No Package Selected")
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .automatic) {
                Button("Back") {
                    selectedPackage = nil
                }
            }
        }
    }
}


#Preview {
    @Previewable @StateObject var viewModel = BrewViewModel()
    let formula = Formula(name: "name", fullName: "fullName", desc: "description", homepage: "homepage", versions: Versions(stable: "stable", head: "head", bottle: true), dependencies: ["dependency", "dependency"])
    PackageDetailsView(selectedPackage: .constant(.formula(formula)))
        .environmentObject(viewModel)
}
