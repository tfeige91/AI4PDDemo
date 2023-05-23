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
    weak var model: CameraViewModel?
    var sequenceHandler = VNSequenceRequestHandler()
    var currentFrameBuffer: CVImageBuffer?

    var subscriptions = Set<AnyCancellable>()
    
    var orientation: CGImagePropertyOrientation = .up

    let imageProcessingQueue = DispatchQueue(
      label: "Image Processing Queue",
      qos: .userInitiated,
      attributes: [],
      autoreleaseFrequency: .workItem
    )
    
}

extension FeatureDetector: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let detectHumanRectanglesRequest = VNDetectHumanRectanglesRequest(completionHandler: detectedHumanRectangle)
        //Detect entire Body
        detectHumanRectanglesRequest.upperBodyOnly = false
        detectHumanRectanglesRequest.revision = VNDetectHumanRectanglesRequestRevision2
        
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
            print("no human detected")
            model.perform(action: .noHumanDetected)
            return
        }
        print("human detected")
        print("orientation", String(reflecting: orientation))
        //get the converted Boundingbox
        let convertedBoundingBox = viewDelegate.convertFromMetadataToPreviewRect(rect: result.boundingBox)
        //Create a bodyObservationModel with the bounding Box
        let bodyObservationModel = BodyGeometryModel(boundingBox: convertedBoundingBox)
        
        //send the new Model to the CameraViewModel and perform the detected function
        model.perform(action: .humanObservationDetected(bodyObservationModel))
    }
}
    
