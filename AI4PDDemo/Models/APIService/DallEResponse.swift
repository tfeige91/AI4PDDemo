//
//  DallEResponse.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 19.06.23.
//

import Foundation

struct ImageURL: Decodable {
let url: String
}


struct DallEResponse: Decodable {
    let data: [ImageURL]
    
}
