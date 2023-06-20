//
//  HomeScreen.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 05.06.23.
//

import SwiftUI

struct HomeScreen: View {
    
    @EnvironmentObject var model: CameraViewModel
    
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack{
                    Text("Willkommen zu Ihrem")
                        .font(.system(size: 30).bold())
                    Spacer().frame(height: 15)
                    Text("Parkinson \nAssistent")
                        .font(.system(size: 70).bold())
                        .multilineTextAlignment(.center)
                    
                }
                .padding(.bottom, 90)
                
                VStack{
                    //ChatbotButton
                    NavigationLink(destination:GPT3ViewControllerRepresentable().navigationTitle("Parkinson-Assistent")) {
                        ZStack{
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                            
                            VStack{
                                Text("Mit dem Assistenen reden")
                                    .font(.system(size: 25).bold())
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    
                    HStack(spacing: 40){
                        
                        NavigationLink(destination:RecordingsView()) {
                            ZStack{
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.blue)
                                    .frame(width: 230, height: 230)
                                VStack{
                                    Text("Videotagebuch\nansehen")
                                        .font(.system(size: 25).bold())
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.white)
                                        
                                }
                            }
                        }
                        NavigationLink(destination: RecordingView()) {
                            ZStack{
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.green)
                                    .frame(width: 230, height: 230)
                                
                                VStack{
                                    Text("Videotagebuch \n Eintrag starten")
                                        .font(.system(size: 25).bold())
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        
                    }
                    
                    NavigationLink(destination: DoctorsView()) {
                        ZStack{
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.yellow)
                                .frame(maxWidth: .infinity)
                                .frame(height: 80)
                            
                            VStack{
                                Text("Videovorstellung für den Arzt")
                                    .font(.system(size: 25).bold())
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
                .frame(width: 500)
                
            }
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
