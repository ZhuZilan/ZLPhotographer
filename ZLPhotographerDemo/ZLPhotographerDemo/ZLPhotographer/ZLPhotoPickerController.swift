//
//  ZLPhotoPickerController.swift
//  ZLPhotographerDemo
//
//  Created by 朱子澜 on 16/12/22.
//  Copyright © 2016年 杉玉府. All rights reserved.
//

import UIKit

class ZLPhotoPickerController: ZLPhotographer {
    
    // MARK: Property
    
    fileprivate var models: [UIImage] = []
    
    // MARK: Init
    
    override func constructViews() {
        super.constructViews()
        self.delegate = self
    }

}



// MARK: - Interaction

extension ZLPhotoPickerController {
    
    override func dismiss() {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}



// MARK: - Data

extension ZLPhotoPickerController {
    
    func openGalleryUsingCurrentModels() {
        let controller = ZLPhotoGalleryController(models: self.models)
        self.navigationController?.pushViewController(controller, animated: true)
        self.models = []
    }
}



// MARK: - Protocol - Photographer

extension ZLPhotoPickerController: ZLPhotographerDelegate {
    
    func photographer(_ photographer: ZLPhotographer, didTakePhoto photo: UIImage, argument: [String : Any]?) {
        let countdown = argument?[ZLPhotographer.argumentCountdownKey] as? Int ?? -1
        let model = photo
        self.models.append(model)
        if (countdown == 0) {
            self.openGalleryUsingCurrentModels()
        }
    }
    
    func photographer(_ photographer: ZLPhotographer, didCancel _: Any?) {
        
    }
}
