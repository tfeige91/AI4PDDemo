//
//  ChatbotAvatarView.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 19.04.23.
//

import SwiftUI
import AVFoundation

struct ChatbotAvatarView: View {
    
    let synthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        VStack {
            // Add your chatbot avatar here
            Image(systemName: "person.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
            Button {
                speak()
            } label: {
                Image(systemName: "mic")
                    .font(.title)
                    .foregroundColor(.red)
            }

            Spacer()
        }
    }
    func speak() {
        let speech = ["Willkommen zum Reiseführer nach Wien! Die Hauptstadt Österreichs, auch bekannt als die Stadt der Musik und die Stadt der Träume, bietet eine Fülle an kulturellen, historischen und kulinarischen Erlebnissen für jeden Reisenden. Von beeindruckenden Barockgebäuden bis hin zu charmanten Cafés und einer lebendigen Kunstszene ist Wien ein einzigartiges Reiseziel, das es zu entdecken gilt."]
        let text = speech.randomElement()!
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        utterance.rate = 0.5 // slower speech rate for a relaxed and friendly tone
        utterance.pitchMultiplier = 1.2 // slightly higher pitch for a more upbeat and friendly tone
        utterance.volume = 1.0 // maximum volume for a clear and friendly voice
        synthesizer.speak(utterance)
    
    }
}

struct ChatbotAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        ChatbotAvatarView()
    }
}
