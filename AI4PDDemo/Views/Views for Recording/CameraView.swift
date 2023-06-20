//
//  CameraView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 12.06.23.
//

import SwiftUI

struct CameraView: View {
    
    @State private var speakHelp: Bool = true
    @EnvironmentObject var model: CameraViewModel
    
    
    var body: some View {
        ZStack {
            CameraViewRepresentable(model: model)
            LayoutGuideView(
                layoutGuideFrame: model.bodyLayoutGuideFrame,
                hasDetectedValidBody: model.hasDetectedValidBody)
        }
        .onAppear {
            if speakHelp {
                DispatchQueue.main.asyncAfter(deadline: .now()+2) {
                    model.startInstruction()
                }
            }   
        }
//        .edgesIgnoringSafeArea(.all)
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
