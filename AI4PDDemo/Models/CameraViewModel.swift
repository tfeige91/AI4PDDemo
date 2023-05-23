//
//  CameraViewModel.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 20.04.23.
//

import Combine
import CoreGraphics
import UIKit
import Vision
import AVFoundation

//Overall
enum BodyObservation<T> {
  case bodyFound(T)
  case bodyNotFound
  case errored(Error)
}

enum CameraViewModelAction {
    //View Setup and configuration action
    case windowSizeDetected(CGRect)
    
    //Body detection actions
    case noHumanDetected
    case humanObservationDetected(BodyGeometryModel)
}

enum BodyDetectedState {
    case bodyDetected
    case noBodyDetected
    case BodyDetectionErrored
}

enum BodyBoundsState {
  case unknown
  case detectedBodyTooSmall
  case detectedBodyTooLarge
  case detectedBodyOffCentre
  case detectedBodyAppropriateSizeAndPosition
}

enum Instructions: String {
    case comeNear = "bitte kommen Sie noch einen Schritt näher"
    case goAway = "bitte gehen Sie etwas weiter zurück"
    case beginn = "Ich werde Ihnen helfen, die richtige Position einzunehmen. Stellen Sie sich bitte so weit von der Kamera weg, bis Sie genau im roten Kästchen stehen"
    case correct = "Sehr gut! Wir können nun mit der Aufgabe beginnen. Ich starte die Aufnahme in 3...2...1. Die Aufnahme läuft."
}


struct BodyGeometryModel {
    let boundingBox: CGRect
}

final class CameraViewModel: NSObject, ObservableObject {
    
    // MARK: - Publishers of derived state
    @Published private(set) var hasDetectedValidBody: Bool
    
    @Published private(set) var isAcceptableBounds: BodyBoundsState {
      didSet {
        calculateDetectedBodyValidity()
      }
    }
    
    // MARK: - Publishers of Vision data directly
    @Published private(set) var bodyDetectedState: BodyDetectedState
    
    //Will be called when a Body-Observation was found
    @Published private(set) var bodyGeometryState: BodyObservation<BodyGeometryModel> {
      didSet {
          processUpdatedBodyGeometry()
      }
    }
    
    // MARK: - Private variables
    var bodyLayoutGuideFrame = CGRect(x: 0, y: 0, width: 250, height: 750)
    
    //Speech Synthesizer
    let synthesizer = AVSpeechSynthesizer()
    
    
    
    var timer: Timer?
    
    
    override init() {
        
        self.hasDetectedValidBody = false
        self.isAcceptableBounds = .unknown
        self.bodyDetectedState = .noBodyDetected
        self.bodyGeometryState = .bodyNotFound
        
        super.init()
        
        synthesizer.delegate = self
    }
    
}

extension CameraViewModel {
    func perform(action: CameraViewModelAction){
        switch action {
        case .windowSizeDetected(let windowRect):
            handleWindowSizeChanged(toRect: windowRect)
        case .noHumanDetected:
            publishNoBodyObserved()
        case .humanObservationDetected(let bodyObservation):
            publishBodyObservation(bodyObservation)
        }
    }
    
    // MARK: Action handlers

    private func handleWindowSizeChanged(toRect: CGRect) {
      bodyLayoutGuideFrame = CGRect(
        x: toRect.midX - bodyLayoutGuideFrame.width / 2,
        y: toRect.midY - bodyLayoutGuideFrame.height / 2,
        width: bodyLayoutGuideFrame.width,
        height: bodyLayoutGuideFrame.height
      )
    }
    
    private func publishNoBodyObserved() {
      DispatchQueue.main.async { [self] in
          bodyDetectedState = .noBodyDetected
          bodyGeometryState = .bodyNotFound
      }
    }
    
    private func publishBodyObservation(_ bodyGeometryModel: BodyGeometryModel) {
      DispatchQueue.main.async { [self] in
          bodyDetectedState = .bodyDetected
          //the didset above will call processUpdatedBodyGeometry
          bodyGeometryState = .bodyFound(bodyGeometryModel)
      }
    }
    
    //MARK: - Helpers
    func invalidateBodyGeometryState() {
      isAcceptableBounds = .unknown
    }
    
    func processUpdatedBodyGeometry() {
      switch bodyGeometryState {
      case .bodyNotFound:
        invalidateBodyGeometryState()
      case .errored(let error):
        print(error.localizedDescription)
        invalidateBodyGeometryState()
      case .bodyFound(let bodyGeometryModel):
          let boundingBox = bodyGeometryModel.boundingBox

        updateAcceptableBounds(using: boundingBox)
      }
    }
    
    func updateAcceptableBounds(using boundingBox: CGRect) {
        
      // First, check face is roughly the same size as the layout guide
        if boundingBox.width > 1.5 * bodyLayoutGuideFrame.width {
          isAcceptableBounds = .detectedBodyTooLarge
        } else if boundingBox.width * 1.5 < bodyLayoutGuideFrame.width {
          isAcceptableBounds = .detectedBodyTooSmall
        } else if boundingBox.height * 1.05 < bodyLayoutGuideFrame.height {
          isAcceptableBounds = .detectedBodyTooSmall
        } else if boundingBox.height > 1.02 * bodyLayoutGuideFrame.height {
          isAcceptableBounds = .detectedBodyTooLarge
      } else {
          isAcceptableBounds = .detectedBodyAppropriateSizeAndPosition
      }
//        else {
//        // Next, check face is roughly centered in the frame
//        if abs(boundingBox.midX - bodyLayoutGuideFrame.midX) > 50 {
//            isAcceptableBounds = .detectedBodyOffCentre
//        } else if abs(boundingBox.midY - bodyLayoutGuideFrame.midY) > 50 {
//            isAcceptableBounds = .detectedBodyOffCentre
//        } else {
//            isAcceptableBounds = .detectedBodyAppropriateSizeAndPosition
//        }
//      }
        calculateDetectedBodyValidity()
    }
    
    

}

extension CameraViewModel {
    func calculateDetectedBodyValidity() {
        hasDetectedValidBody =
        isAcceptableBounds == .detectedBodyAppropriateSizeAndPosition
        
    }
}

//MARK: - Speech Instruction
extension CameraViewModel: AVSpeechSynthesizerDelegate {
    
    
    
    func startInstruction() {
        synthesizer.speak(createUtterance(from: Instructions.beginn.rawValue))
        
        DispatchQueue.main.asyncAfter(deadline: .now()+6){
            self.guidanceInstruction()
        }
    }
    
    func guidanceInstruction(){
        timer = Timer.scheduledTimer(withTimeInterval: 4.5, repeats: true) { (timer) in
            self.speakGuidanceInstruction()
        }
        
    }
                                     
    func speakGuidanceInstruction(){
        switch isAcceptableBounds {
        case .detectedBodyTooLarge:
            synthesizer.speak(createUtterance(from: Instructions.goAway.rawValue))
        case .unknown:
            print("unknown")
        case .detectedBodyTooSmall:
            synthesizer.speak(createUtterance(from: Instructions.comeNear.rawValue))
        case .detectedBodyOffCentre:
            print("of center")
        case .detectedBodyAppropriateSizeAndPosition:
            synthesizer.speak(createUtterance(from: Instructions.correct.rawValue))
            timer?.invalidate()
        }
    }
    
    private func createUtterance(from string: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        utterance.rate = 0.5 // slower speech rate for a relaxed and friendly tone
        utterance.pitchMultiplier = 1.2 // slightly higher pitch for a more upbeat and friendly tone
        utterance.volume = 1.0 // maximum volume for a clear and friendly voice
        return utterance
    }
                                     
}
