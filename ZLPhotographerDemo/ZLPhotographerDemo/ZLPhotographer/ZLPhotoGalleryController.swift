//
//  ZLPhotoGalleryController.swift
//  ZLPhotographerDemo
//
//  Created by 朱子澜 on 16/12/22.
//  Copyright © 2016年 杉玉府. All rights reserved.
//

import UIKit

protocol ZLPhotoGalleryControllerDelegate: NSObjectProtocol {
    
    func photoGallery(controller: ZLPhotoGalleryController, didAppear _: Any?)
    
    func photoGallery(controller: ZLPhotoGalleryController, willDisappear _: Any?)
}

class ZLPhotoGalleryController: UIViewController {
    
    // MARK: Control
    
    weak var navigationView: UIView!
    weak var navigationTitleLabel: UILabel!
    weak var navigationReturnButton: UIButton!
    
    weak var centerImageView: UIImageView!
    weak var bottomCollectionView: UICollectionView!
    
    weak var editButton: UIButton!
    weak var saveButton: UIButton!
    
    // MARK: Delegate
    
    weak var delegate: ZLPhotoGalleryControllerDelegate?
    
    // MARK: Property
    
    fileprivate var models: [UIImage] = []
    fileprivate var isControlHiding: Bool = false
    fileprivate var selectedIndex: Int = 0
    
    // MARK: Init
    
    init(models: [UIImage]) {
        super.init(nibName: nil, bundle: nil)
        self.models = models
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
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
            view.alpha = 0.8
            self.view.addSubview(view)
            return view
        } ()
        
        self.navigationTitleLabel = {
            let label = UILabel()
            label.frame = CGRect(x: 44, y: 20, width: screenWidth - 88, height: 44)
            label.font = UIFont.systemFont(ofSize: 17)
            label.text = "Gallery"
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
        
        self.centerImageView = {
            let imageView = UIImageView()
            imageView.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
            imageView.contentMode = .scaleAspectFit
            imageView.layer.masksToBounds = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(centerImageViewDidClick))
            imageView.addGestureRecognizer(gesture)
            imageView.isUserInteractionEnabled = true
            self.view.addSubview(imageView)
            return imageView
        } ()
        
        self.bottomCollectionView = {
            let height = CGFloat(132)
            let frame = CGRect(x: 0, y: screenHeight - height, width: screenWidth, height: height)
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            let collectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
            collectionView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)
            collectionView.register(ZLPhotoGalleryThumbCell.self, forCellWithReuseIdentifier: ZLPhotoGalleryThumbCell.identifier)
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.alwaysBounceHorizontal = true
            self.view.addSubview(collectionView)
            return collectionView
        } ()
        
        self.saveButton = {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: screenWidth - 44, y: 20, width: 44, height: 44)
            button.setTitle("Save", for: .normal)
            button.setTitleColor(UIColor.black, for: .normal)
            button.addTarget(self, action: #selector(saveButtonDidClick), for: .touchUpInside)
            self.navigationView.addSubview(button)
            return button
        } ()
        
        self.editButton = {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: screenWidth - 88, y: 20, width: 44, height: 44)
            button.setTitle("Edit", for: .normal)
            button.setTitleColor(UIColor.black, for: .normal)
            button.addTarget(self, action: #selector(editButtonDidClick), for: .touchUpInside)
            self.navigationView.addSubview(button)
            return button
        } ()
        
        self.view.bringSubview(toFront: self.navigationView)
        self.selectImage(at: 0)
    }

}



// MARK: - Interaction

extension ZLPhotoGalleryController {
    
    func navigationReturnButtonDidClick() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    func centerImageViewDidClick() {
        self.isControlHiding = !self.isControlHiding
        self.navigationView.isHidden = self.isControlHiding
        self.bottomCollectionView.isHidden = self.isControlHiding
    }
    
    func saveButtonDidClick() {
        guard self.selectedIndex >= 0 && self.selectedIndex < self.models.count else {
            ldb("没有图片了")
            return
        }
        
        let index = self.selectedIndex
        let image = self.models[index]
        ZLPhotographerTool.saveToAlbum(image: image) { [weak self] (complete, localIdentifier) in
            if complete {
                self?.models.remove(at: index)
                self?.selectImage(at: max(index - 1, 0))
                let `localIdentifier` = localIdentifier ?? ""
                ldb("保存成功 localIdentifier: \(localIdentifier)")
            } else {
                ldb("保存失败")
            }
        }
    }
    
    func editButtonDidClick() {
        guard self.selectedIndex >= 0 && self.selectedIndex < self.models.count else {
            ldb("没有图片了")
            return
        }
        
        let image = self.models[self.selectedIndex]
        let controller = ZLPhotoEditorController()
        controller.contentImage = image
        controller.delegate = self
        self.navigationController?.pushViewController(controller, animated: true)
    }
}



// MARK: - Data

extension ZLPhotoGalleryController {
    
    func selectImage(at index: Int) {
        self.selectedIndex = index
        self.reloadData()
    }
    
    func reloadData() {
        if self.selectedIndex >= 0 && self.selectedIndex < self.models.count {
            let image = self.models[self.selectedIndex]
            self.centerImageView.image = image
            self.bottomCollectionView.reloadData()
        } else {
            self.centerImageView.image = nil
            self.bottomCollectionView.reloadData()
        }
    }
    
}



// MARK: - Protocol - Editor

extension ZLPhotoGalleryController: ZLPhotoEditorControllerDelegate {
    
    func photoEditor(controller: ZLPhotoEditorController, didCommitWith image: UIImage) {
        if (self.selectedIndex >= 0 && self.selectedIndex < self.models.count) {
            self.models.remove(at: self.selectedIndex)
            self.models.insert(image, at: self.selectedIndex)
            self.reloadData()
        }
    }
}



// MARK: - Protocol - Collection View

extension ZLPhotoGalleryController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    // count
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.models.count
    }
    
    // layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return ZLPhotoGalleryThumbCell.sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return ZLPhotoGalleryThumbCell.cellSize
    }
    
    // item
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLPhotoGalleryThumbCell.identifier, for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? ZLPhotoGalleryThumbCell else {
            return
        }
        
        let image = self.models[indexPath.item]
        cell.render(with: image, at: indexPath, selected: (self.selectedIndex == indexPath.item))
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectImage(at: indexPath.item)
        collectionView.reloadItems(at: [indexPath])
    }
}
