//
//  ZLPhotoEditorController.swift
//  ZLPhotographerDemo
//
//  Created by 朱子澜 on 16/12/25.
//  Copyright © 2016年 杉玉府. All rights reserved.
//

import UIKit

protocol ZLPhotoEditorControllerDelegate: NSObjectProtocol {
    
    func photoEditor(controller: ZLPhotoEditorController, didCommitWith image: UIImage)
    
}

class ZLPhotoEditorController: UIViewController {
    
    // MARK: Control
    
    fileprivate weak var navigationView: UIView!
    fileprivate weak var navigationTitleLabel: UILabel!
    fileprivate weak var navigationReturnButton: UIButton!
    fileprivate weak var navigationSaveButton: UIButton!
    
    fileprivate weak var controlView: UIView!
    
    fileprivate weak var contentView: TouchView!
    fileprivate weak var contentImageView: UIImageView!
    
    // MARK: Delegate
    
    weak var delegate: ZLPhotoEditorControllerDelegate?
    
    // MARK: Property
    
    var contentImage: UIImage = UIImage() {
        didSet (image) {
            self.reloadContentImageView()
        }
    }
    
    fileprivate var brushType: BrushType = .none        // brush type enumeration
    fileprivate var brushRadius: CGFloat = 20           // brush radius in pixel
    fileprivate var pixellateLevel: Int = 40
    
    fileprivate var latestTouchPoint: CGPoint? = nil
    fileprivate var latestOperationComplete: Bool = true
    
    fileprivate var isInited: Bool = false
    fileprivate var contentScale: CGFloat {
        if !self.isInited || self.contentImage.size.width == 0 || self.contentImage.size.height == 0 {
            return 1.0
        }
        return self.contentImageView.frame.width / self.contentImage.size.width
    }
    
    // MARK: Init

    override func viewDidLoad() {
        super.viewDidLoad()
        self.constructViews()
    }
    
    func constructViews() {
        self.view.backgroundColor = UIColor.black
        
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        
        self.navigationView = {
            let view = UIView()
            view.frame = CGRect(x: 0, y: 0, width: screenWidth, height: 64)
            view.backgroundColor = UIColor.white
            self.view.addSubview(view)
            return view
        } ()
        
        self.navigationTitleLabel = {
            let label = UILabel()
            label.frame = CGRect(x: 44, y: 20, width: screenWidth - 88, height: 44)
            label.font = UIFont.systemFont(ofSize: 17)
            label.text = "Editor"
            label.textColor = UIColor.black
            label.textAlignment = .center
            self.navigationView.addSubview(label)
            return label
        } ()
        
        self.navigationReturnButton = {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: 0, y: 20, width: 44, height: 44)
            button.setImage(UIImage(named: "common_return"), for: .normal)
            button.addTarget(self, action: #selector(navigationReturnButtonDidClick), for: .touchUpInside)
            self.navigationView.addSubview(button)
            return button
        } ()
        
        self.navigationSaveButton = {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: screenWidth - 44, y: 20, width: 44, height: 44)
            button.setImage(UIImage(named: "common_confirm"), for: .normal)
            button.addTarget(self, action: #selector(navigationSaveButtonDidClick), for: .touchUpInside)
            self.navigationView.addSubview(button)
            return button
        } ()
        
        self.controlView = {
            let height = CGFloat(88)
            let view = UIView()
            view.backgroundColor = UIColor.white
            view.frame = CGRect(x: 0, y: screenHeight - height, width: screenWidth, height: height)
            self.view.addSubview(view)
            return view
        } ()
        
        self.contentView = {
            let height = self.controlView.frame.minY - self.navigationView.frame.maxY
            let view = TouchView()
            view.frame = CGRect(x: 0, y: self.navigationView.frame.maxY, width: screenWidth, height: height)
            view.layer.masksToBounds = true
            view.delegate = self
            self.view.addSubview(view)
            return view
        } ()
        
        self.contentImageView = {
            let imageView = UIImageView()
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.layer.borderWidth = 1
            imageView.layer.masksToBounds = true
            self.contentView.addSubview(imageView)
            return imageView
        } ()
        
        self.isInited = true
        self.reloadContentImageView()
    }
    
    func reloadContentImageView() {
        if !self.isInited {
            return
        }
        let image = self.contentImage
        if image.size.width > 0 && image.size.height > 0 {
            let viewRatio = self.contentView.frame.width / self.contentView.frame.height
            let imageRatio = image.size.width / image.size.height
            var targetSize: CGSize = CGSize.zero
            if viewRatio > imageRatio {
                let scale = self.contentView.frame.height / image.size.height
                targetSize = CGSize(width: image.size.width * scale, height: self.contentView.frame.height)
            } else {
                let scale = self.contentView.frame.width / image.size.width
                targetSize = CGSize(width: self.contentView.frame.width, height: image.size.height * scale)
            }
            self.contentImageView.frame = CGRect(origin: CGPoint.zero, size: targetSize)
            self.contentImageView.center = CGPoint(x: self.contentView.frame.width * 0.5, y: self.contentView.frame.height * 0.5)
            self.contentImageView.image = image
        }
    }

}



// MARK: - Interaction

extension ZLPhotoEditorController {
    
    func navigationReturnButtonDidClick() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func navigationSaveButtonDidClick() {
        self.delegate?.photoEditor(controller: self, didCommitWith: self.contentImage)
        _ = self.navigationController?.popViewController(animated: true)
    }
    
}



// MARK: - Brush

extension ZLPhotoEditorController: TouchViewDelegate {
    
    fileprivate func convertedImageViewPoint(at contentPoint: CGPoint) -> CGPoint {
        return CGPoint(x: contentPoint.x - self.contentImageView.frame.origin.x,
                       y: contentPoint.y - self.contentImageView.frame.origin.y)
    }
    
    fileprivate func brushRect(at point: CGPoint, usingImageScale: Bool = true) -> CGRect {
        let radius = CGFloat(self.brushRadius)
        let scale = usingImageScale ? self.contentScale : CGFloat(1.0)
        return CGRect(x: (point.x - radius)/scale, y: (point.y - radius)/scale, width: (2 * radius)/scale, height: (2 * radius)/scale)
    }
    
    fileprivate func enqueueImagePixellateOperation(at originalPoint: CGPoint) {
        let convertedPoint = self.convertedImageViewPoint(at: originalPoint)
        let brushRect = self.brushRect(at: convertedPoint)
        self.latestOperationComplete = false
        ZLPhotographerTool.enqueueImageOperation { [weak self] in
            guard let image = self?.contentImage, let level = self?.pixellateLevel else {
                self?.latestOperationComplete = true
                return
            }
            ZLPhotographerTool.generatePixellateImage(from: image, level: level, boundingRect: brushRect, completion: { [weak self] (pixellatedImage) in
                if let pixellatedImage = pixellatedImage {
                    self?.contentImage = pixellatedImage
                    self?.contentImageView.image = pixellatedImage
                }
                self?.latestOperationComplete = true
            })
        }
    }
    
    fileprivate func touchView(_ view: ZLPhotoEditorController.TouchView, startTouch point: CGPoint) {
        self.latestTouchPoint = point
        self.executeTouch(at: point)
    }
    
    fileprivate func touchView(_ view: ZLPhotoEditorController.TouchView, moveTouch point: CGPoint) {
        if let latestPoint = self.latestTouchPoint {
            let distance = fabs(latestPoint.x - point.x) + fabs(latestPoint.y - point.y)
            if distance > 2 * self.brushRadius {
                self.latestTouchPoint = point
                self.executeTouch(at: point)
            }
        }
    }
    
    fileprivate func touchView(_ view: ZLPhotoEditorController.TouchView, endTouch point: CGPoint) {
        self.executeTouch(at: point)
        self.latestTouchPoint = nil
    }
    
    private func executeTouch(at point: CGPoint) {
        if !self.latestOperationComplete {
            return
        }
        
        // TODO: switch-case here to support different brush types.
        // now only pixellate available.
        self.enqueueImagePixellateOperation(at: point)
    }
}



// MARK: - Internal

fileprivate extension ZLPhotoEditorController {
    
    typealias ImageOperation = (() -> Swift.Void)
    
    enum BrushType {
        case none
        case pixellate
    }
    
    class TouchView: UIView {
        
        weak var delegate: TouchViewDelegate?
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            guard let touch = touches.first else {
                return
            }
            
            let point = touch.location(in: self)
            self.delegate?.touchView(self, startTouch: point)
        }
        
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesMoved(touches, with: event)
            guard let touch = touches.first else {
                return
            }
            
            let point = touch.location(in: self)
            self.delegate?.touchView(self, moveTouch: point)
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesEnded(touches, with: event)
            guard let touch = touches.first else {
                return
            }
            
            let point = touch.location(in: self)
            self.delegate?.touchView(self, endTouch: point)
        }
        
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesCancelled(touches, with: event)
            guard let touch = touches.first else {
                return
            }
            
            let point = touch.location(in: self)
            self.delegate?.touchView(self, endTouch: point)
        }
    }
}

fileprivate protocol TouchViewDelegate: NSObjectProtocol {
    
    func touchView(_ view: ZLPhotoEditorController.TouchView, startTouch point: CGPoint)
    func touchView(_ view: ZLPhotoEditorController.TouchView, moveTouch point: CGPoint)
    func touchView(_ view: ZLPhotoEditorController.TouchView, endTouch point: CGPoint)
}
