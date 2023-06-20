//
//  RecordingView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 12.06.23.
//

import SwiftUI

struct RecordingView: View {
    
    @EnvironmentObject var model: CameraViewModel
    
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            CameraView()
            
            //TopView with some information
            VStack {
                Text(model.updrsItems[model.currentItem].itemName)
                    .font(.title.bold())
                    .frame(height: 60)
                    .padding(.bottom)
            }
            .frame(maxWidth: .infinity)
            .background(.thickMaterial)
            
//            ChatbotAvatarView(size: CGSize(width: 250, height: 350))
//                .padding()
        }
        //.edgesIgnoringSafeArea(.all)
        
    }
}

struct RecordingView_Previews: PreviewProvider {
    static var previews: some View {
        RecordingView()
    }
}
