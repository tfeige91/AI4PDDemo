//
//  ChatbotAvatarView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 19.04.23.
//

import SwiftUI


struct ChatbotAvatarView: View {
    
    let size: CGSize
    
    var body: some View {
       
            VStack(spacing: 30) {
                // Add your chatbot avatar here
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: size.width * 0.6,height: size.width * 0.6)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.blue)
                
                    
                Text("Hallo,\nich bin Botty, dein Assistent.")
                    .font(.headline.bold())
                    .lineLimit(nil)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            .padding(.all,10)
            .frame(width: size.width, height: size.height)
            .background(.ultraThinMaterial.opacity(0.99), in: RoundedRectangle(cornerRadius: 20))
            
       
       
    }
    
}

struct ChatbotAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        ChatbotAvatarView(size: CGSize(width: 300, height: 400))
    }
}
