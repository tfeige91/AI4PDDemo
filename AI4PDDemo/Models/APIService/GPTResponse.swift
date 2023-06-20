//
//  GPTResponse.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 19.06.23.
//

import Foundation

struct GPTResponse: Decodable{
let choices: [GPTCompletion]
}

struct GPTCompletion:Decodable {
let text: String
let finishReason: String
}
