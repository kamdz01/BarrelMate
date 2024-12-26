//
//  Item.swift
//  BarrelMate
//
//  Created by Kamil Dziedzic on 26/12/2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
