//
//  ZLPhotoGalleryThumbCell.swift
//  ZLPhotographerDemo
//
//  Created by 朱子澜 on 16/12/22.
//  Copyright © 2016年 杉玉府. All rights reserved.
//

import UIKit

class ZLPhotoGalleryThumbCell: UICollectionViewCell {
    
    class var identifier: String {
        return "ZLPhotoGalleryThumbCell.Identifier"
    }
    
    class var cellSize: CGSize {
        return CGSize(width: 80, height: 80)
    }
    
    class var sectionInsets: UIEdgeInsets {
        return UIEdgeInsetsMake(0, 16, 0, 16)
    }
    
    // MARK: Control
    
    weak var thumbImageView: UIImageView!
    
    // MARK: Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.constructViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func constructViews() {
        self.thumbImageView = {
            let size = ZLPhotoGalleryThumbCell.cellSize
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            imageView.contentMode = .scaleAspectFill
            imageView.layer.masksToBounds = true
            imageView.layer.borderWidth = 2
            self.addSubview(imageView)
            return imageView
        } ()
    }
    
}



// MARK: - Data

extension ZLPhotoGalleryThumbCell {
    
    func render(with image: UIImage, at indexPath: IndexPath, selected: Bool) {
        self.thumbImageView.image = image
        self.thumbImageView.layer.borderColor = (selected ? UIColor.white : UIColor.clear).cgColor
    }
}
