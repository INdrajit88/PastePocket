//
//  Item.swift
//  Pastemac
//
//  Created by Indrajit Ari on 20/03/26.
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
