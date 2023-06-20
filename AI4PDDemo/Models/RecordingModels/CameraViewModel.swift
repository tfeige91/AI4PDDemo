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
    
    //Writing Video
    case prepareWriter(CMSampleBuffer)
    case writingVideo(CMSampleBuffer)
    case stopWriting
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
    
    var updrsItems = [UPDRSItem(orderNumber: 0,
                                date: nil,
                                itemName: "PronationSupination",
                                instructionTest: "Strecken Sie den Arm vor Ihrem Körper mit der Handfläche nach unten aus. Wenden Sie nun Ihre Handfläche mit größtmöglicher Amplitude alternierend 10 Mal nach oben und nach unten",
                                url: nil,
                                rating: nil),
                      UPDRSItem(orderNumber: 1,
                                date: nil,
                                itemName: "Finger_Tippen",
                                instructionTest: "Berühren Sie mit Ihrem Zeigefinger die Kuppe Ihres Daumens. Öffnen Sie nun beide Finger soweit wie möglich von einander und führen Sie anschließend die Fingerkuppen wieder zusammen. Wiederholen Sie das nun bitte 10 mal und versuchen Sie bitte die Bewegung so schnell wie möglich und mit der größtmöglichen Amplitude auszuführen.",
                                url: nil,
                                rating: nil),
                      UPDRSItem(orderNumber: 2,
                                date: nil,
                                itemName: "Bewegungstremor",
                                instructionTest: "Strecken Sie zunächst Ihren Arm mit ausgestrecktem Zeigefinger weit nach vorn und führen Sie anschließend den Zeigefinger an Ihre Nasenspitze. Danach strecken Sie den Arm wieder weit aus. Wiederholen Sie das bitte fünf mal.",
                                url: nil,
                                rating: nil)]
    
    //Published Variables TestItems
    @Published var currentItem: Int = 0
    
    // MARK: - Private variables
    var bodyLayoutGuideFrame = CGRect(x: 0, y: 40, width: 370, height: 800)
    
    //Combine Streaming variables to propagate writing status back
    let shouldRecord = PassthroughSubject<Void, Never>()
    let didFinishWriting = PassthroughSubject<Void, Never>()
    let startedNextTrial = PassthroughSubject<Void, Never>()
    
    //Speech Synthesizer
    let synthesizer = AVSpeechSynthesizer()
    var timer: Timer?
    var currentInstruction: String = ""
    
    //Saving Video Files
    private var assetWriter: AVAssetWriter? = nil
    private var assetWriterInput: AVAssetWriterInput? = nil
    private let writingQueue = DispatchQueue(label: "videoWritingQueue")
    var sessionNumber: Int?
    var sessionURL: URL?
    var itemURL: URL?
    var sessionAtSourceTime: CMTime?
    var frame = 0
    var stopRecordingSet = false
    var stopped = false
    let fileManager = VideoFileManager.instance
    
    //CoreData
    private let viewContext = PersistenceController.shared.viewContext
    private var session: Session?
    
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
        case .writingVideo(let sampleBuffer):
            writeVideo(sampleBuffer: sampleBuffer)
        case .prepareWriter(let sampleBuffer):
            prepareWriter(sampleBuffer: sampleBuffer)
        case .stopWriting:
            print("stop writing")
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
    
    
    //record Video to File
    
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
        if boundingBox.width > 1.8 * bodyLayoutGuideFrame.width {
          isAcceptableBounds = .detectedBodyTooLarge
        } else if boundingBox.width * 1.5 < bodyLayoutGuideFrame.width {
          isAcceptableBounds = .detectedBodyTooSmall
        } else if boundingBox.height * 1.05 < bodyLayoutGuideFrame.height {
          isAcceptableBounds = .detectedBodyTooSmall
        } else if boundingBox.height > 1.05 * bodyLayoutGuideFrame.height {
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

//MARK: - Writing Video
extension CameraViewModel {
    private func prepareWriter(sampleBuffer: CMSampleBuffer) {
        self.sessionAtSourceTime = nil
        print("prepare Writer")
        //get the correct URL
        if self.sessionURL == nil {
            guard let (sessionNumber, sessionFolder) = fileManager.getNewSessionFolder() else  {print("could not create Session Folder"); return}
            self.sessionNumber = sessionNumber
            self.sessionURL = sessionFolder
            //Add the current Session to Core data
            addSessionToCoreData()
        }
        if self.itemURL == nil {
            self.itemURL = URL(filePath: self.sessionURL!.path())
                .appendingPathComponent(self.updrsItems[self.currentItem].itemName)
                .appendingPathExtension("mov")
        }
        
        guard let videoOutputUrl = self.itemURL else  {print("could not create FilePath"); return}
        
        print(videoOutputUrl)
        
        //Set Up AVAssetWriter
        do {
            assetWriter = try AVAssetWriter(url: videoOutputUrl, fileType: .mov)
            
            //set Video Settings
            //get samplebuffer properties
            guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {return}
            let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
            let width = dimensions.width
            let height = dimensions.height
            
            let videoOutputSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(width),
                AVVideoHeightKey: Int(height),
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey : 2300000]
            ]
            
            assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
            
            guard let assetWriterInput = assetWriterInput, let assetWriter = assetWriter else { return }
            assetWriterInput.expectsMediaDataInRealTime = true
            
            // Adapt to portrait mode
            assetWriterInput.transform = CGAffineTransform(rotationAngle: .pi/2)
            
            if assetWriter.canAdd(assetWriterInput) {
                assetWriter.add(assetWriterInput)
                print("asset input added")
            } else {
                print("no input added")
            }

            assetWriter.startWriting()
            
            self.assetWriter = assetWriter
            self.assetWriterInput = assetWriterInput
            
            
        } catch let error {
            debugPrint(error.localizedDescription)
        }
            
    }
    
    //write Video
    private func writeVideo(sampleBuffer: CMSampleBuffer) {
        
        guard !stopped else {return}
        
        print("write video")
       
        switch self.assetWriter?.status {
        case .writing:
            print("status writing")
        case .failed:
            print("status failed")
        case .cancelled:
            print("status cancelled")
        case .unknown:
            print("status unknown")
        default:
            print("status completed")
        }
        
        //set the stop once
        if !stopRecordingSet {
            stopRecordingSet = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.stopRecording()
                print("stop recording scheduled")
            }
        }
        
        //start Writing Session
        if assetWriter?.status == .writing && self.sessionAtSourceTime == nil {
            let sessionAtSourceTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
            self.assetWriter?.startSession(atSourceTime: sessionAtSourceTime)
          
        }
        
        //append current Samplebuffer
        guard let assetWriterInput = self.assetWriterInput else {return}
        if assetWriter?.status == .writing, assetWriterInput.isReadyForMoreMediaData {
            assetWriterInput.append(sampleBuffer)
            self.frame += 1
//            print("assetwriter is writing frame \(frame)")
//            print("Writer appended Input")
        }
    }
    
    private func stopRecording(){
        self.didFinishWriting.send()
        self.assetWriterInput?.markAsFinished()
        Task{
            await assetWriter?.finishWriting()
            //self.sessionAtSourceTime = nil
            
            print("Recording finished")
        }
        stopRecordingSet = false
        frame = 0
        stopped = false
        //save Item to CoreData
        addItemToCoreData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.nextTrial()
        }
    }
    
}
//MARK: - Recording Routing
extension CameraViewModel {
    
    private func nextTrial() {
        if currentItem+1 < updrsItems.count {
            currentItem += 1
            itemURL = nil
            startedNextTrial.send()
            guideNewVideo()
        }else {
            print("done")
        }
        
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
    
    func guideNewVideo(){
        let newTask = "Sehr gut, wir machen nun weiter mit der Aufgabe \(updrsItems[currentItem].itemName). Ich schaue zunächst wieder, ob sie gut zur Kamera positioniert sind."
        synthesizer.speak(createUtterance(from: newTask))
        
        DispatchQueue.main.asyncAfter(deadline: .now()+5){
            self.guidanceInstruction()
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
            
            self.currentInstruction = "Sehr gut! Wir können nun mit der Aufgabe beginnen. \(updrsItems[currentItem].instructionTest). Ich starte die Aufnahme in Drei...Zwei...Eins. Die Aufnahme läuft."
            
            synthesizer.speak(createUtterance(from: self.currentInstruction))
            timer?.invalidate()
            
        }
        
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        //check if speaking correct is done
        if utterance.speechString == self.currentInstruction{
            DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                //tells FeatureDetector (RENAME) to initiate recording
                self.shouldRecord.send()
            }
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

//MARK: - CoreData

extension CameraViewModel {
    
    func addItemToCoreData() {
        print("Session_\(self.sessionNumber!)/\(itemURL!.lastPathComponent)")
        print("URL to save: ",self.itemURL)
        guard let session = self.session,
              let itemUrl = self.itemURL,
              let urlToSave = URL(string: itemUrl.lastPathComponent)
        else {
            
            print("error saving to CoreData")
            return
        }
        print(urlToSave)
        let curIt = updrsItems[currentItem]
        let item = UPDRSRecordedItem(context: viewContext)
        item.orderNumber = Int16(curIt.orderNumber)
        item.date = Date()
        item.name = curIt.itemName
        item.rating = 0
        item.session = session
        item.videoURL = URL(string:itemUrl.lastPathComponent)
        save()
    }
    
    func addSessionToCoreData() {
        let session = Session(context: viewContext)
        session.id = Int16(self.sessionNumber ?? 0)
        session.date = Date()
        self.session = session
        save()
    }
    
    func save() {
        do {
            try viewContext.save()
        }catch {
            print("Error saving")
        }
    }
    
}
