//
//  Item.swift
//  life-blocks
//
//  Created by Ege Atar on 2026-03-07.
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
