//
//  FeatureDetector.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 20.04.23.
//

import Foundation
import AVFoundation
import Vision
import Combine
import UIKit

protocol FeatureDetectorDelegate: NSObjectProtocol {
  func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect
}

class FeatureDetector: NSObject {
    weak var viewDelegate: FeatureDetectorDelegate?
    weak var model: CameraViewModel? {
        didSet {
            model?.shouldRecord.sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure(let error):
                    print("error: \(error)")
                }
            } receiveValue: { _ in
                self.shouldRecord = true
                print("shouldrecord",self.shouldRecord)
            }
            .store(in: &subscriptions)
            
            model?.didFinishWriting.sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure(let error):
                    print("error: \(error)")
                }
            } receiveValue: { _ in
                self.modelFinishedWriting = true
                self.shouldRecord = false
            }
            .store(in: &subscriptions)
            
            model?.startedNextTrial.sink { completion in
                switch completion {
                case .finished:
                    return
                case .failure(let error):
                    print("error: \(error)")
                }
            } receiveValue: { _ in
                self.modelAssetWriterPrepared = false
            }
            .store(in: &subscriptions)
                
                                        
        }
    }
    var subscriptions = Set<AnyCancellable>()
    
    var sequenceHandler = VNSequenceRequestHandler()
    var currentFrameBuffer: CVImageBuffer?

    
    var orientation: CGImagePropertyOrientation = .up
    
    var performVisionRequests = true
    var shouldRecord = false

    let imageProcessingQueue = DispatchQueue(
      label: "Image Processing Queue",
      qos: .userInitiated,
      attributes: [],
      autoreleaseFrequency: .workItem
    )
    
    //Writing File
    var modelAssetWriterPrepared = false
    
    //reaction Variables to writing status
    var modelFinishedWriting = false
    
}

extension FeatureDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        //since Writer Preparation might take some time, initiate it here already
        if !modelAssetWriterPrepared {
            modelAssetWriterPrepared = true
            model?.perform(action: .prepareWriter(sampleBuffer))
        }
        
        if !shouldRecord {
            //perform vision Requests
            if performVisionRequests {
                let detectHumanRectanglesRequest = VNDetectHumanRectanglesRequest(completionHandler: detectedHumanRectangle)
                //Detect entire Body
                detectHumanRectanglesRequest.upperBodyOnly = false
                detectHumanRectanglesRequest.revision = VNDetectHumanRectanglesRequestRevision2
                
                do {
                  try sequenceHandler.perform(
                    [detectHumanRectanglesRequest],
                    on: imageBuffer,
                    orientation: .upMirrored)
                } catch {
                  print(error.localizedDescription)
                }
            }
            
            
        }
        
        
        if shouldRecord {
            guard let model = model else {return}
//            print("should record")
            model.perform(action: .writingVideo(sampleBuffer))
        }
        
        
        
    }
    
    
    
}
    
    
//completion Handlers
extension FeatureDetector {
    func detectedHumanRectangle(request: VNRequest, error: Error?) {
        guard let model = model, let viewDelegate = viewDelegate else {
            return
        }
        //check if there is a result
        guard let results = request.results as? [VNHumanObservation],
              let result = results.first else{
            //publish no human detected
//            print("no human detected")
            model.perform(action: .noHumanDetected)
            return
        }
//        print("human detected")
        //get the converted Boundingbox
        let convertedBoundingBox = viewDelegate.convertFromMetadataToPreviewRect(rect: result.boundingBox)
        //Create a bodyObservationModel with the bounding Box
        let bodyObservationModel = BodyGeometryModel(boundingBox: convertedBoundingBox)
        
        //send the new Model to the CameraViewModel and perform the detected function
        model.perform(action: .humanObservationDetected(bodyObservationModel))
    }
}
    


//        switch UIDevice.current.orientation {
//        case .portrait:
//            orientation = .right
//        case .portraitUpsideDown:
//            orientation = .left
//        case .landscapeLeft:
//            orientation = .up
//        case .landscapeRight:
//            orientation = .down
//        default:
//            orientation = .right
//        }
