//
//  ZLPhotographer.swift
//  ZLPhotographerDemo
//
//  Created by 朱子澜 on 16/12/22.
//  Copyright © 2016年 杉玉府. All rights reserved.
//

import UIKit
import AVFoundation

class ZLPhotographer: UIViewController {
    
    // MARK: Configurable
    
    var devicePosition: Position = Position.back
    var automaticallyTakePhotoWhenAppears: Bool = false
    var numberOfPhotosOnce: Int = 1
    
    // MARK: Delegate
    
    weak var delegate: ZLPhotographerDelegate?
    
    // MARK: Control
    
    // holder view
    fileprivate var contentView: UIView!
    
    // display layer
    fileprivate var previewHolder: UIView!
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer!
    
    // control buttons
    fileprivate var controlHolder: UIView!
    fileprivate var photographButton: UIButton!
    fileprivate var cancelButton: UIButton!
    fileprivate var toggleDevicePositionButton: UIButton!
    
    // state label
    fileprivate weak var adjustingStateLabel: UILabel?
    
    // tap interest point
    fileprivate var interestPointAimView: AimView!
    fileprivate var interestPointGesture: UITapGestureRecognizer!
    
    // MARK: Property
    
    var session: AVCaptureSession!
    fileprivate var input: AVCaptureDeviceInput!
    fileprivate var output: AVCaptureStillImageOutput!
    fileprivate var device: AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as? [AVCaptureDevice] ?? []
        for device in devices {
            if device.position == self.devicePosition.captureDevicePosition {
                return device
            }
        }
        return nil
    }
    
    fileprivate var isHoldingPhotographButton: Bool = false
    fileprivate var isAdjustingFocus: Bool = true
    fileprivate var isAdjustingExposure: Bool = true
    fileprivate var isAdjustingWhiteBalance: Bool = true
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.constructViews()
        self.registerNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !self.session.isRunning {
            self.session.startRunning()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.automaticallyTakePhotoWhenAppears {
            self.takePhoto(count: self.numberOfPhotosOnce)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.session.isRunning {
            self.session.stopRunning()
        }
    }
    
    deinit {
        self.unregisterNotifications()
        self.delegate = nil
    }
    
    // MARK: Init Custom
    
    func constructViews() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.edgesForExtendedLayout = []
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.view.backgroundColor = UIColor.black
        self.constructCaptureSession()
        
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        
        self.contentView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight))
            view.backgroundColor = UIColor.black
            self.view.addSubview(view)
            return view
        } ()
        
        if self.automaticallyTakePhotoWhenAppears {
            self.view.alpha = 0.0
            self.contentView.isHidden = true
        }
        
        self.previewHolder = {
            let height = floor(screenWidth * 4 / 3)
            let view = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: height))
            self.contentView.addSubview(view)
            return view
        } ()
        
        self.previewLayer = {
            let layer = AVCaptureVideoPreviewLayer(session: self.session)!
            layer.frame = self.previewHolder.bounds
            layer.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.previewHolder.layer.masksToBounds = true
            self.previewHolder.layer.addSublayer(layer)
            return layer
        } ()
        
        self.interestPointAimView = {
            let view = AimView(frame: CGRect(x: 0, y: 0, width: 88, height: 88))
            view.center = self.previewHolder.center
            view.alpha = 0.0
            self.previewHolder.addSubview(view)
            return view
        } ()
        
        self.interestPointGesture = {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(interestPointGestureDidTrigger(_:)))
            gesture.numberOfTapsRequired = 1
            gesture.numberOfTouchesRequired = 1
            self.previewHolder.isUserInteractionEnabled = true
            self.previewHolder.addGestureRecognizer(gesture)
            return gesture
        } ()
        
        self.controlHolder = {
            let height = fmax(100, screenHeight - self.previewHolder.frame.size.height)
            let view = UIView(frame: CGRect(x: 0, y: screenHeight - height, width: screenWidth, height: height))
            view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.6)
            self.contentView.addSubview(view)
            return view
        } ()
        
        self.adjustingStateLabel = {
            let height = CGFloat(32)
            let label = UILabel(frame: CGRect(x: 0, y: self.controlHolder.frame.minY - height, width: screenWidth, height: height))
            label.font = UIFont.boldSystemFont(ofSize: 14)
            label.textColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
            label.textAlignment = .center
            label.isHidden = true
            self.previewHolder.addSubview(label)
            return label
        } ()
        
        self.photographButton = {
            let button = UIButton(type: UIButtonType.custom)
            button.frame = CGRect(x: 0, y: 0, width: 66, height: 66)
            button.center = CGPoint(x: screenWidth * 0.5, y: self.controlHolder.frame.size.height * 0.5)
            button.setImage(UIImage(named: "photograph_shoot"), for: .normal)
            button.addTarget(self, action: #selector(photographButtonDidTouchDown), for: .touchDown)
            button.addTarget(self, action: #selector(photographButtonDidTouchCancel), for: .touchCancel)
            button.addTarget(self, action: #selector(photographButtonDidTouchCancel), for: .touchUpInside)
            button.addTarget(self, action: #selector(photographButtonDidTouchCancel), for: .touchDragExit)
            self.controlHolder.addSubview(button)
            return button
        } ()
        
        self.cancelButton = {
            let height = self.controlHolder.frame.size.height
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: 0, y: screenHeight - height, width: 66, height: height)
            button.setTitle("关闭", for: .normal)
            button.setTitleColor(UIColor.white, for: .normal)
            button.setTitleColor(UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0), for: .highlighted)
            button.addTarget(self, action: #selector(cancelButtonDidClick), for: .touchUpInside)
            self.contentView.addSubview(button)
            return button
        } ()
        
        self.toggleDevicePositionButton = {
            let height = self.controlHolder.frame.size.height
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: screenWidth - 66, y: screenHeight - height, width: 66, height: height)
            button.setTitle("切换", for: .normal)
            button.setTitleColor(UIColor.white, for: .normal)
            button.setTitleColor(UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0), for: .highlighted)
            button.addTarget(self, action: #selector(toggleDevicePositionButtonDidClick), for: .touchUpInside)
            self.contentView.addSubview(button)
            return button
        } ()
    }
    
    // MARK: Observer
    
    func registerNotifications() {
        
        // start observing focus, explosure and white balance
        self.device?.addObserver(self, forKeyPath: ZLPhotographer.adjustingFocusKeyPath, options: .new, context: nil)
        self.device?.addObserver(self, forKeyPath: ZLPhotographer.adjustingExposureKeyPath , options: .new, context: nil)
        self.device?.addObserver(self, forKeyPath: ZLPhotographer.adjustingWhiteBalanceKeyPath, options: .new, context: nil)
    }
    
    func unregisterNotifications() {
        
        // stop observing focus, explosure and white balance
        self.device?.removeObserver(self, forKeyPath: ZLPhotographer.adjustingFocusKeyPath)
        self.device?.removeObserver(self, forKeyPath: ZLPhotographer.adjustingExposureKeyPath)
        self.device?.removeObserver(self, forKeyPath: ZLPhotographer.adjustingWhiteBalanceKeyPath)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == ZLPhotographer.adjustingFocusKeyPath {
            self.isAdjustingFocus = change?[NSKeyValueChangeKey.newKey] as? Bool ?? false
            self.reloadAdjustingStateLabel()
        } else if keyPath == ZLPhotographer.adjustingExposureKeyPath {
            self.isAdjustingExposure = change?[NSKeyValueChangeKey.newKey] as? Bool ?? false
            self.reloadAdjustingStateLabel()
        } else if keyPath == ZLPhotographer.adjustingWhiteBalanceKeyPath {
            self.isAdjustingWhiteBalance = change?[NSKeyValueChangeKey.newKey] as? Bool ?? false
        } else if keyPath == ZLPhotographer.focusPointKeyPath {
            ldb(change?[NSKeyValueChangeKey.newKey])
        }
    }
    
    func reloadAdjustingStateLabel() {
        if (self.isAdjustingFocus && self.isAdjustingExposure) {
            self.adjustingStateLabel?.text = "对焦、调整曝光中…"
        } else if (self.isAdjustingFocus) {
            self.adjustingStateLabel?.text = "对焦中…"
        } else if (self.isAdjustingExposure) {
            self.adjustingStateLabel?.text = "调整曝光中…"
        } else {
            self.adjustingStateLabel?.text = ""
        }
    }
    
}



// MARK: - Init Session

extension ZLPhotographer {
    
    @discardableResult
    func constructCaptureSession() -> Bool {
        self.session = AVCaptureSession()
        self.session.trySetSessionPreset(AVCaptureSessionPresetPhoto)
        
        // acquire device
        guard let device = self.device else {
            return false
        }
        
        // configure device
        if device.isFlashAvailable {
            do {
                try device.lockForConfiguration()
                device.flashMode = .off
                device.videoZoomFactor = 1.0
                device.unlockForConfiguration()
            } catch {
                ldb("error: \(error) during device configuring.")
                return false
            }
        }
        
        // configure still image input
        do {
            self.input = try AVCaptureDeviceInput(device: device)
            if self.session.canAddInput(self.input) {
                self.session.addInput(self.input)
            }
        } catch {
            ldb("error constructing device input: \(error)")
            return false
        }
        
        // configure still image output
        self.output = AVCaptureStillImageOutput()
        self.output.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        self.output.isHighResolutionStillImageOutputEnabled = true
        if self.session.canAddOutput(self.output) {
            self.session.addOutput(self.output)
        }
        
        return true
    }
    
    @discardableResult
    func constructVideoSession() -> Bool {
        
        
        return true
    }
    
    @discardableResult
    func toggleDevicePosition() -> Bool {
        self.unregisterNotifications()
        if self.devicePosition == .front {
            self.devicePosition = .back
        } else if self.devicePosition == .back {
            self.devicePosition = .front
        }
        self.registerNotifications()
        
        // acquire new device
        guard let device = self.device else {
            return false
        }
        
        // begin configuration
        self.session.beginConfiguration()
        
        // configure session preset
        self.session.trySetSessionPreset(AVCaptureSessionPresetPhoto)
        
        // configure device
        if device.isFlashAvailable {
            do {
                try device.lockForConfiguration()
                device.flashMode = .off
                device.videoZoomFactor = 1.0
                device.unlockForConfiguration()
            } catch {
                ldb("error: \(error) during device configuring.")
                return false
            }
        }
        
        // configure still image input
        do {
            let newInput = try AVCaptureDeviceInput(device: device)
            self.session.removeInput(self.input)
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.input = newInput
            } else {
                if self.session.canAddInput(self.input) {
                    self.session.addInput(self.input)
                }
                return false
            }
        } catch {
            ldb("error constructing device input: \(error)")
            return false
        }
        
        // configure still image output
        let newOutput = AVCaptureStillImageOutput()
        newOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        newOutput.isHighResolutionStillImageOutputEnabled = true
        self.session.removeOutput(self.output)
        if self.session.canAddOutput(newOutput) {
            self.session.addOutput(newOutput)
            self.output = newOutput
        } else {
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            return false
        }
        
        // commit switch
        self.session.commitConfiguration()
        return true
    }
}



// MARK: - Interaction

extension ZLPhotographer {
    
    func photographButtonDidTouchDown() {
        self.isHoldingPhotographButton = true
        self.takePhoto()
    }
    
    func photographButtonDidTouchCancel() {
        self.isHoldingPhotographButton = false
    }
    
    func cancelButtonDidClick() {
        self.dismiss()
    }
    
    func toggleDevicePositionButtonDidClick() {
        
        // try toggle device position.
        if !self.toggleDevicePosition() {
            self.toggleDevicePosition()
        }
    }
    
    func interestPointGestureDidTrigger(_ gesture: UITapGestureRecognizer) {
        
        // fetch point of interest by user finger,
        // and show an auto-dismiss aim view to let user know where he clicked.
        let size = self.previewHolder.bounds.size
        let point = gesture.location(in: gesture.view)
        let convertedPoint = CGPoint(x: point.y/size.height, y: 1-point.x/size.width);
        self.interestPointAimView.present(at: point, autoDismiss: true)
        
        // acquire current device
        guard let device = device else {
            return
        }
        
        // try start configuration
        do { try device.lockForConfiguration() } catch {
            ldb("error \(error) during lock for configuration.")
        }
        
        // set focus
        if device.isFocusPointOfInterestSupported, device.isFocusModeSupported(.autoFocus) {
            device.focusPointOfInterest = convertedPoint
            device.focusMode = .autoFocus
        }
        
        // set exposure
        if device.isExposurePointOfInterestSupported, device.isExposureModeSupported(.autoExpose) {
            device.exposurePointOfInterest = convertedPoint
            device.exposureMode = .autoExpose
        }
        
        // unlock after configured
        device.unlockForConfiguration()
    }
}



// MARK: - Public Interface

extension ZLPhotographer {
    
    /** Present photographer in root navigation controller. */
    func present() {
        self.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        self.modalPresentationStyle = UIModalPresentationStyle.custom
        UIApplication.shared.keyWindow?.rootViewController?.present(self, animated: false, completion: nil)
    }
    
    /** Dismiss self. */
    func dismiss() {
        self.delegate?.photographer(self, didCancel: nil)
        self.dismiss(animated: false, completion: nil)
    }
}



// MARK: - Photograph Logic

fileprivate extension ZLPhotographer {
    
    func takeShortVideo() {
        let videoOutput = AVCaptureVideoDataOutput()
        if self.session.canAddOutput(videoOutput) {
            self.session.addOutput(videoOutput)
        }
        
        let videoQueue = DispatchQueue(label: "ZLPhotographer.VideoOutputQueue")
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
    }
    
    /** Take photo with a continueous count greater or equal than 1. */
    func takePhoto(count: Int = 1) {
        // halt take picture if counted down
        if count < 1 {
            return;
        }
        
        // create video output connection
        guard let connection = self.output.connection(withMediaType: AVMediaTypeVideo) else { return }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = AVCaptureVideoOrientation.portrait
        }
        if connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
        }
        
        // bracket capture settings
        guard let exposureSettings = AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(withExposureTargetBias: AVCaptureExposureTargetBiasCurrent) else {
            return
        }
        let bracketSettings: [AVCaptureBracketedStillImageSettings] = [exposureSettings]
        
        // capture still image recursively
        self.output.prepareToCaptureStillImageBracket(from: connection, withSettingsArray: bracketSettings) { [weak self] (complete, error) in
            if let error = error {
                ldb("error: \(error)")
                return
            }
            if complete {
                self?.doTakePhoto(connection: connection, bracketSettings: bracketSettings, recursionCountdown: (count-1))
            } else {
                ldb("failed to prepare capture.")
            }
        }
    }
    
    /** Execute capture image with a recursion countdown, halt while recursion done. */
    private func doTakePhoto(connection: AVCaptureConnection, bracketSettings: [AVCaptureBracketedStillImageSettings], recursionCountdown: Int) {
        self.output.captureStillImageBracketAsynchronously(from: connection, withSettingsArray: [AVCaptureAutoExposureBracketedStillImageSettings()]) { [weak self] (buffer, settings, error) in
            let forceContinue: Bool = self?.isHoldingPhotographButton ?? false
            defer {
                // recursively take next photo
                if (recursionCountdown > 0 || forceContinue) {
                    let nextRecursionCountdown = forceContinue ? 1 : (recursionCountdown - 1)
                    self?.doTakePhoto(connection: connection, bracketSettings: bracketSettings, recursionCountdown: nextRecursionCountdown)
                } else if self?.automaticallyTakePhotoWhenAppears ?? false {
                    self?.dismiss()
                }
            }
            
            // discard photos with imcomplete exposure
            if (recursionCountdown > 1 && self?.isAdjustingExposure ?? false) {
                return
            }
            
            // error occurs when capturing still image.
            if let error = error {
                ldb("error: \(error)")
                return
            }
            
            // fetched empty data from sample buffer.
            guard let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer) else {
                ldb("fetched empty data from sample buffer: \(buffer)")
                return
            }
            
            // failed generating image from data.
            guard let image = UIImage(data: data) else {
                ldb("failed generating image from data: \(data)")
                return
            }
            let fixedImage = ZLPhotographerTool.fixedOrientationImage(from: image)
            
            // ignore deallocated photographer.
            guard let `self` = self else {
                return
            }
            
            // send captured image to delegate,
            // and take next photo determined by countdown.
            let extraMessage = "(\(self.isAdjustingFocus), \(self.isAdjustingExposure), \(self.isAdjustingWhiteBalance))"
            self.delegate?.photographer(self, didTakePhoto: fixedImage, argument: [
                ZLPhotographer.argumentCountdownKey: recursionCountdown + (forceContinue ? 1 : 0),
                ZLPhotographer.argumentExtraMessageKey: extraMessage
            ])
        }
    }
}



// MARK: - Protocol - Video Output

extension ZLPhotographer: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
}



// MARK: - Internal

fileprivate extension ZLPhotographer {
    
    class AimView: UIView {
        
        private var presentInterval: TimeInterval = 0
        
        override func willMove(toWindow newWindow: UIWindow?) {
            super.willMove(toWindow: newWindow)
            self.isOpaque = false
        }
        
        override func draw(_ rect: CGRect) {
            let length = CGFloat(fmin(rect.width, rect.height)/4)
            guard length > 0 else {
                return
            }
            
            // draw corner lines
            UIColor.white.setStroke()
            let aimBorderPath = UIBezierPath()
            aimBorderPath.lineWidth = 2
            aimBorderPath.move(to: CGPoint(x: 0, y: length))
            aimBorderPath.addLine(to: CGPoint(x: 0, y: 0))
            aimBorderPath.addLine(to: CGPoint(x: length, y: 0))
            aimBorderPath.move(to: CGPoint(x: rect.width - length, y: 0))
            aimBorderPath.addLine(to: CGPoint(x: rect.width, y: 0))
            aimBorderPath.addLine(to: CGPoint(x: rect.width, y: length))
            aimBorderPath.move(to: CGPoint(x: rect.width, y: rect.height - length))
            aimBorderPath.addLine(to: CGPoint(x: rect.width, y: rect.height))
            aimBorderPath.addLine(to: CGPoint(x: rect.width - length, y: rect.height))
            aimBorderPath.move(to: CGPoint(x: length, y: rect.height))
            aimBorderPath.addLine(to: CGPoint(x: 0, y: rect.height))
            aimBorderPath.addLine(to: CGPoint(x: 0, y: rect.height - length))
            aimBorderPath.stroke()
        }
        
        func present(at point: CGPoint, autoDismiss: Bool = true) {
            let currentInterval = Date().timeIntervalSince1970
            self.presentInterval = currentInterval
            self.center = point
            UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 2.5, initialSpringVelocity: 1.0, options: .beginFromCurrentState, animations: { [weak self] in
                self?.alpha = 1.0
            }) { (complete) in
                // auto dismiss aim view
                if (complete && autoDismiss) {
                    let deadline = DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(1000 * 1.5))
                    DispatchQueue.main.asyncAfter(deadline: deadline, execute: { [weak self] in
                        if (self?.presentInterval ?? 0 == currentInterval) {
                            self?.dismiss()
                        }
                    })
                }
            }
        }
        
        func dismiss() {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 2.0, initialSpringVelocity: 1.0, options: .beginFromCurrentState, animations: { [weak self] in
                self?.alpha = 0.0
            }) { (complete) in
                // ...
            }
        }
    }
    
}

fileprivate extension AVCaptureSession {
    
    @discardableResult
    func trySetSessionPreset(_ preset: String) -> Bool {
        if self.canSetSessionPreset(preset) {
            self.sessionPreset = preset
            return true
        } else {
            return false
        }
    }
}
