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
    
    fileprivate var controlView: UIView!
    fileprivate var controlBrushButton: UIButton!
    fileprivate var controlFilterButton: UIButton!
    
    fileprivate var controlPanel: UIView!
    fileprivate var controlPanelCommitButton: UIButton!
    fileprivate var controlPanelCancelButton: UIView!
    
    fileprivate var filterCollectionView: UICollectionView!
    
    fileprivate weak var contentView: TouchView!
    fileprivate weak var contentImageView: UIImageView!
    
    // MARK: Delegate
    
    weak var delegate: ZLPhotoEditorControllerDelegate?
    
    // MARK: Effect Data
    
    fileprivate lazy var originalThumbImage: UIImage = {
        return ZLPhotographerTool.resize(image: self.originalImage, to: ThumbCell.size)
    } ()
    fileprivate var filteredThumbImages: [String: UIImage] = [:]
    fileprivate var selectedFilterIndex: Int = 0
    fileprivate lazy var filterContext: CIContext = { return CIContext() } ()
    fileprivate lazy var filterDataSource: [(title: String, name: String)] = {
        var filters = ZLPhotographer.filterNames
        filters.insert((title: "原图", name: ""), at: 0)
        filters.insert((title: "自动", name: "auto"), at: 1)
        return filters
    } ()
    
    // MARK: Property
    
    var originalImage: UIImage = UIImage()
    var contentImage: UIImage = UIImage() {
        didSet (image) {
            self.reloadContentImageView()
        }
    }
    
    fileprivate var editType: EditType = .none {
        didSet (type) {
            switch (type) {
            case .none:
                self.hideControlPanel()
            case .brush:
                self.showControlPanel()
                // add brush collection view
            case .filter:
                self.showControlPanel()
                self.controlView.addSubview(self.filterCollectionView)
            }
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
        
        let controlSize = CGFloat(88)
        
        self.controlView = {
            let height = controlSize
            let view = UIView()
            view.backgroundColor = UIColor.white
            view.frame = CGRect(x: 0, y: screenHeight - height, width: screenWidth, height: height)
            self.view.addSubview(view)
            return view
        } ()
        
        self.controlBrushButton = {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: 0, y: 0, width: controlSize, height: controlSize)
            button.setImage(UIImage(named: "editor_brush_normal"), for: .normal)
            button.setImage(UIImage(named: "editor_brush_selected"), for: .selected)
            button.setImage(UIImage(named: "editor_brush_highlighted"), for: .highlighted)
            button.addTarget(self, action: #selector(controlBrushButtonDidClick), for: .touchUpInside)
            self.controlView.addSubview(button)
            return button
        } ()
        
        self.controlFilterButton = {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: controlSize, y: 0, width: controlSize, height: controlSize)
            button.setImage(UIImage(named: "editor_filter_normal"), for: .normal)
            button.setImage(UIImage(named: "editor_filter_selected"), for: .selected)
            button.setImage(UIImage(named: "editor_filter_highlighted"), for: .highlighted)
            button.addTarget(self, action: #selector(controlBrushButtonDidClick), for: .touchUpInside)
            self.controlView.addSubview(button)
            return button
        } ()
        
        self.controlPanel = {
            let view = UIView()
            view.backgroundColor = UIColor.lightGray
            view.frame = self.controlView.frame
            self.view.addSubview(view)
            return view
        } ()
        
        self.controlPanelCancelButton = {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: 0, y: 0, width: controlSize, height: controlSize)
            button.setImage(UIImage(named: "editor_brush_normal"), for: .normal)
            button.setImage(UIImage(named: "editor_brush_selected"), for: .selected)
            button.setImage(UIImage(named: "editor_brush_highlighted"), for: .highlighted)
            button.addTarget(self, action: #selector(controlPanelCancelButtonDidClick), for: .touchUpInside)
            self.controlPanel.addSubview(button)
            return button
        } ()
        
        self.controlPanelCommitButton = {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: screenWidth - controlSize, y: 0, width: controlSize, height: controlSize)
            button.setImage(UIImage(named: "editor_brush_normal"), for: .normal)
            button.setImage(UIImage(named: "editor_brush_selected"), for: .selected)
            button.setImage(UIImage(named: "editor_brush_highlighted"), for: .highlighted)
            button.addTarget(self, action: #selector(controlPanelCommitButtonDidClick), for: .touchUpInside)
            self.controlPanel.addSubview(button)
            return button
        } ()
        
        self.filterCollectionView = {
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .horizontal
            let collectionView = UICollectionView(
                frame: CGRect(x: controlSize, y: 0, width: screenWidth - 2 * controlSize, height: controlSize),
                collectionViewLayout: flowLayout)
            collectionView.backgroundColor = UIColor.white
            collectionView.showsHorizontalScrollIndicator = false
            collectionView.register(ThumbCell.self, forCellWithReuseIdentifier: ThumbCell.identifier)
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.layer.borderWidth = 3
            collectionView.layer.borderColor = UIColor.blue.cgColor
            return collectionView
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
            imageView.layer.masksToBounds = true
            self.contentView.addSubview(imageView)
            return imageView
        } ()
        
        self.isInited = true
        self.reloadContentImageView()
        self.hideControlPanel()
        self.generateFilteredThumbImages()
    }
    
    func generateFilteredThumbImages() {
        let thumbImage = self.originalThumbImage
        DispatchQueue(label: "ZLPhotoEditor.Filter").async { [weak self] in
            for model in self?.filterDataSource ?? [] {
                if model.name == "" {
                    self?.filteredThumbImages[model.name] = thumbImage
                } else if model.name == "auto" {
                    self?.filteredThumbImages[model.name] = ZLPhotographerTool.getAutoFilteredImage(from: thumbImage, context: self?.filterContext)
                } else if model.name.hasPrefix("CIPhotoEffect") {
                    self?.filteredThumbImages[model.name] = ZLPhotographerTool.getFilteredImage(from: thumbImage, filterName: model.name, context: self?.filterContext)
                }
            }
            DispatchQueue.main.async { [weak self] in
                self?.filterCollectionView.reloadData()
            }
        }
        
        
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
    
    // control view buttons
    
    func controlBrushButtonDidClick() {
        self.editType = .brush
    }
    
    func controlFilterButtonDidClick() {
        self.editType = .filter
    }
    
    // control panel buttons
    
    func controlPanelCommitButtonDidClick() {
        if !self.latestOperationComplete {
            return
        }
        
        self.originalImage = self.contentImage
        self.editType = .none
    }
    
    func controlPanelCancelButtonDidClick() {
        if !self.latestOperationComplete {
            return
        }
        
        self.contentImage = self.originalImage
        self.editType = .none
    }
    
}



// MARK: - Control Panel Effect

extension ZLPhotoEditorController {
    
    func showControlPanel() {
        self.controlView.isHidden = true
        self.controlPanel.isHidden = false
    }
    
    func hideControlPanel() {
        self.controlPanel.isHidden = true
        self.controlView.isHidden = false
        self.clearControlPanel()
    }
    
    func clearControlPanel() {
        for subview in self.controlPanel.subviews {
            if subview == self.controlPanelCancelButton || subview == self.controlPanelCommitButton {
                continue
            }
            subview.removeFromSuperview()
        }
    }
}



// MARK: - Filter

extension ZLPhotoEditorController {
    
    func filterImageWithAutoFilters() {
        self.latestOperationComplete = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let image = self.originalImage
        DispatchQueue(label: "ZLPhotoEditor.Filter", attributes: .concurrent).async {
            let resultImage = ZLPhotographerTool.getAutoFilteredImage(from: image, context: self.filterContext)
            DispatchQueue.main.async { [weak self] in
                self?.contentImage = resultImage
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.latestOperationComplete = true
            }
        }
    }
    
    func filterImage(filterName: String) {
        self.latestOperationComplete = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let image = self.originalImage
        DispatchQueue(label: "ZLPhotoEditor.Filter", attributes: .concurrent).async {
            let resultImage = ZLPhotographerTool.getFilteredImage(from: image, filterName: filterName, context: self.filterContext)
            DispatchQueue.main.async { [weak self] in
                self?.contentImage = resultImage
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.latestOperationComplete = true
            }
        }
    }
}



// MARK: - Protocol - Collection View

extension ZLPhotoEditorController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    fileprivate class ThumbCell: UICollectionViewCell {
        
        static let identifier: String = "ZLPhotoEditor.ThumbCell"
        static let size: CGSize = CGSize(width: 80, height: 80)
        
        var contentImageView: UIImageView!
        var contentLabel: UILabel!
        var selectionMark: UIImageView!
        
        private var filterName: String = "not initialized"
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.constructViews()
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            self.constructViews()
        }
        
        func constructViews() {
            let size = ThumbCell.size
            
            self.contentImageView = {
                let imageView = UIImageView()
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                imageView.contentMode = .scaleAspectFill
                imageView.layer.masksToBounds = true
                imageView.layer.borderColor = UIColor.black.cgColor
                imageView.layer.borderWidth = 1
                self.addSubview(imageView)
                return imageView
            } ()
            
            self.contentLabel = {
                let height = CGFloat(24)
                let label = UILabel()
                label.frame = CGRect(x: 0, y: size.height - height, width: size.width, height: height)
                label.font = UIFont.systemFont(ofSize: 14)
                label.textColor = UIColor.white
                label.textAlignment = .center
                label.numberOfLines = 0
                self.addSubview(label)
                return label
            } ()
            
            self.selectionMark = {
                let imageView = UIImageView()
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                imageView.contentMode = .scaleAspectFill
                imageView.layer.masksToBounds = true
                imageView.layer.borderColor = UIColor.lightGray.cgColor
                imageView.layer.borderWidth = 5
                imageView.isHidden = true
                self.addSubview(imageView)
                return imageView
            } ()
        }
        
        func fill(title: String, image: UIImage?, isSelected: Bool) {
            self.contentLabel.text = title
            self.contentImageView.image = image
            self.selectionMark.isHidden = !isSelected
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.filterDataSource.count
    }
    
    // layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return ThumbCell.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    }
    
    // cell
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThumbCell.identifier, for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? ThumbCell else {
            return
        }
        
        let model = self.filterDataSource[indexPath.item]
        let image = self.filteredThumbImages[model.name] ?? self.originalThumbImage
        cell.fill(title: model.title, image: image, isSelected: (self.selectedFilterIndex == indexPath.item))
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        // content image is locked for previous operation.
        if !self.latestOperationComplete {
            return
        }
        
        // duplication check
        if self.selectedFilterIndex == indexPath.item {
            return
        }
        self.selectedFilterIndex = indexPath.item
        
        // filter image
        let model = self.filterDataSource[indexPath.item]
        if model.name == "" {
            self.contentImage = self.originalImage
        } else if model.name == "auto" {
            self.filterImageWithAutoFilters()
        } else if model.name.hasPrefix("CIPhotoEffect") {
            self.filterImage(filterName: model.name)
        }
        
        // reload collection view
        collectionView.reloadData()
    }
    
}



// MARK: - Protocol - Brush

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
        if self.editType != .brush {
            return
        }
        
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
    
    enum EditType {
        case none
        case brush
        case filter
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
