//
//  AddPackageView.swift
//  BarrelMate
//
//  Created by Kamil Dziedzic on 03/01/2025.
//

import SwiftUI

enum SelectedPackage {
    case formula(Formula)
    case cask(Cask)
}

struct AddPackageView: View {
    @EnvironmentObject private var viewModel: BrewViewModel
    @State private var selectedPackage: SelectedPackage?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if selectedPackage != nil {
                PackageDetailsView(selectedPackage: $selectedPackage)
                    .environmentObject(viewModel)
            } else {
                ListPackageView(selectedPackage: $selectedPackage)
                    .environmentObject(viewModel)
            }
        }
    }
}

#Preview {
    @Previewable @StateObject var viewModel = BrewViewModel()
    AddPackageView()
        .environmentObject(viewModel)
        .onAppear {
            Task {
                await viewModel.fetchPackages()
            }
        }
}
