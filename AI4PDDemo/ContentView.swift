//
//  ContentView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 19.04.23.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject private(set) var model: CameraViewModel
    
    init(model: CameraViewModel) {
      self.model = model
    }
    
    var body: some View {
        HStack {
            ChatbotAvatarView()
                .frame(width: UIScreen.main.bounds.width / 3, alignment: .leading)
            
            GeometryReader { geo in
                ZStack {
                    CameraView(model: model)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now()+2) {
                                model.startInstruction()
                            }
                        }
                        
                    LayoutGuideView(
                        layoutGuideFrame: model.bodyLayoutGuideFrame,
                        hasDetectedValidBody: model.hasDetectedValidBody)
                    
                    BodyBoundingBoxView(model: model)

                }
                .ignoresSafeArea()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(model: CameraViewModel())
    }
}
