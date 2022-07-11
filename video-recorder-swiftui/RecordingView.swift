//
//  RecordingView.swift
//  video-recorder-swiftui
//
//  Created by Prayag Gediya on 10/07/22.
//

import UIKit
import AVFoundation
import SwiftUI
import AVKit

enum RecordAction: String {
    case start
    case pause
    case stop
}

struct RecordginView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> RecordingViewController {
        RecordingViewController()
    }
    
    func updateUIViewController(_ uiViewController: RecordingViewController, context: Context) {
        
    }
}


class RecordingViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    let captureSession = AVCaptureSession()
    let movieOutput = AVCaptureMovieFileOutput()
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    var activeInput: AVCaptureDeviceInput!
    var outputURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if setupSession() {
            setupPreview()
            startSession()
            setupObserver()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupPreview() {
        // Configure previewLayer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }
    
    //MARK:- Setup Camera
    func setupSession() -> Bool {
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        
        // Setup Camera
        let camera = AVCaptureDevice.default(for: .video)
        
        do {
            let input = try AVCaptureDeviceInput(device: camera!)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            }
        } catch {
            print("Error setting device video input: \(error)")
            return false
        }
        
        // Setup Microphone
        let microphone = AVCaptureDevice.default(for: .audio)
        
        do {
            let micInput = try AVCaptureDeviceInput(device: microphone!)
            if captureSession.canAddInput(micInput) {
                captureSession.addInput(micInput)
            }
        } catch {
            print("Error setting device audio input: \(error)")
            return false
        }
        
        
        // Movie output
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        }
        
        return true
    }
    
    func setupCaptureMode(_ mode: Int) {
        // Video Mode
    }
    
    //MARK:- Camera Session
    func startSession() {
        if !captureSession.isRunning {
            videoQueue().async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            videoQueue().async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func videoQueue() -> DispatchQueue {
        return DispatchQueue.main
    }
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        return orientation
    }
    
    func startCapture() {
        startRecording()
    }
    
    //EDIT 1: I FORGOT THIS AT FIRST
    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    func startRecording() {
        if movieOutput.isRecording == false {
            let connection = movieOutput.connection(with: .video)
            if (connection?.isVideoOrientationSupported)! {
                connection?.videoOrientation = .portrait
            }
            
            if (connection?.isVideoStabilizationSupported)! {
                connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
            }
            
            let device = activeInput.device
            if (device.isSmoothAutoFocusSupported) {
                do {
                    try device.lockForConfiguration()
                    device.isSmoothAutoFocusEnabled = false
                    device.unlockForConfiguration()
                } catch {
                    print("Error setting configuration: \(error)")
                }
                
            }
            
            //EDIT2: And I forgot this
            outputURL = tempURL()
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        } else {
            stopRecording()
        }
    }
    
    func stopRecording() {
        if movieOutput.isRecording == true {
            movieOutput.stopRecording()
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Start recording to - ", fileURL)
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if (error != nil) {
            print("Error recording movie: \(error!.localizedDescription)")
        } else {
            let url = outputURL as URL
            print("Stop recording - ", url)
            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
        }
        outputURL = nil
    }
    
}

// MARK: Switching Camera
extension RecordingViewController {
    func switchCamera() {
#if arch(arm64)
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        let nextPosition = (activeInput?.device.position == .front) ? AVCaptureDevice.Position.back : .front
        
        if let currentCameraInput = activeInput {
            captureSession.removeInput(currentCameraInput)
        }
        
        if let newCamera = cameraDevice(position: nextPosition),
           let newVideoInput: AVCaptureDeviceInput = try? AVCaptureDeviceInput(device: newCamera),
           captureSession.canAddInput(newVideoInput) {
            
            captureSession.addInput(newVideoInput)
            activeInput = newVideoInput
            
            movieOutput.connection(with: .video)?.videoOrientation = .portrait
            movieOutput.connection(with: .video)?.automaticallyAdjustsVideoMirroring = false
            movieOutput.connection(with: .video)?.isVideoMirrored = nextPosition == .front
        }
        
#endif
    }
    
    private func cameraDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        for device in discoverySession.devices where device.position == position {
            return device
        }
        
        return nil
    }
}

extension RecordingViewController {
    
    private func setupObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.RecordAction, object: nil, queue: nil) { notification in
            if let info = notification.userInfo, let action = info["action"] as? RecordAction {
                switch action {
                case .start:
                    self.startRecording()
                case .pause: break
                case .stop:
                    self.stopRecording()
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.CameraSwitchAction, object: nil, queue: nil) { notification in
            self.switchCamera()
        }
    }
    
}
