//
//  ContentView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 19.04.23.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var cameraModel: CameraViewModel = CameraViewModel()
    
    var body: some View {
        HomeScreen()
            .environmentObject(cameraModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
