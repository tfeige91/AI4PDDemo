//
//  UPDRSItem.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 12.06.23.
//

import Foundation

enum ItemRating: Int {
    case veryBad = 1
    case bad = 2
    case middle = 3
    case good = 4
    case veryGood = 5
}

struct UPDRSItem {
    let orderNumber: Int
    let date: Date?
    let itemName: String
    let instructionTest: String
    let url: URL?
    let rating: ItemRating?
    
}
