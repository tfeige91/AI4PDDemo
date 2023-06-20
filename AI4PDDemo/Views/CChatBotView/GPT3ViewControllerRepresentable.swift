//
//  GPT3ViewControllerRepresentable.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 19.06.23.
//

import Foundation
import SwiftUI

struct GPT3ViewControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = GPT3ViewController
    
    func makeUIViewController(context: Context) -> GPT3ViewController {
        let chatViewController = GPT3ViewController()
        return chatViewController
    }
    
    func updateUIViewController(_ uiViewController: GPT3ViewController, context: Context) {
        print("updated")
    }
}
