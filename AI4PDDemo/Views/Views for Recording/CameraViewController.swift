//
//  CameraController.swift
//  AI4PDDemo
//
//  Created by Tim_Feige on 19.04.23.
//

import SwiftUI
import AVFoundation

class CameraViewController: UIViewController {
    var featureDetector: FeatureDetector?
    
    private var permissionGranted = false
    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    let videoOutputQueue = DispatchQueue(
        label: "Video Output Queue",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    
    var preview: AVCaptureVideoPreviewLayer? {
        previewLayer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        featureDetector?.viewDelegate = self
        checkPermission()
//        faceDetector?.viewDelegate = self
//        configureMetal()
        //configureCaptureSession()
        sessionQueue.async { [unowned self] in
            guard permissionGranted else {return}
            self.setupCaptureSession()
        }
        
        
    }
}
// MARK: - Setup video capture
extension CameraViewController {
    
    func checkPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            self.permissionGranted = true
            break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { [unowned self] granted in
                if !granted {
                    fatalError("Camera permission is required.")
                }
                self.permissionGranted = true
                self.sessionQueue.resume()
            }
        default:
            fatalError("Camera permission is required.")
        }
    }
    
    func setupCaptureSession(){
        //capture device
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        
        //input
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice ) else { return }
        guard self.session.canAddInput(videoDeviceInput) else { return}
        self.session.addInput(videoDeviceInput)
        
        // Create the video data output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(featureDetector, queue: videoOutputQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        // Add the video output to the capture session
        session.addOutput(videoOutput)
        
        //preview Layer
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        if let connection = previewLayer?.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        previewLayer?.videoGravity = .resizeAspectFill
        // Adjust the contentsRect to specify which part of the video is visible
        
        
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let layer = self.previewLayer else {return}
            previewLayer?.frame = view.bounds
            
            self.view.layer.addSublayer(layer)
            
            
        }
        session.startRunning()
    }
}
    
// MARK: FaceDetectorDelegate methods

extension CameraViewController: FeatureDetectorDelegate {
  func convertFromMetadataToPreviewRect(rect: CGRect) -> CGRect {
    guard let previewLayer = previewLayer else {
      return CGRect.zero
    }

      return previewLayer.layerRectConverted(fromMetadataOutputRect: rect)
  }

}


struct CameraViewRepresentable: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = CameraViewController
    private(set) var model: CameraViewModel
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIViewController(context: Context) -> CameraViewController {
      let featureDetector = FeatureDetector()
      featureDetector.model = model

      let viewController = CameraViewController()
      viewController.featureDetector = featureDetector

      return viewController
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) { }
}
