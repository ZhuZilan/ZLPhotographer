//
//  ZLPhotographerDelegate.swift
//  ZLPhotographerDemo
//
//  Created by 朱子澜 on 16/12/22.
//  Copyright © 2016年 杉玉府. All rights reserved.
//

import UIKit

protocol ZLPhotographerDelegate: NSObjectProtocol {
    
    // triggers when photographer received a photo.
    // todo: the argument should be upgraded to specified object, 
    //       or deprecated by using a subclass of UIImage with custom properties to replace photo.
    func photographer(_ photographer: ZLPhotographer, didTakePhoto photo: UIImage, argument: [String: Any]?)
    
    // triggers when photographer's cancel action confirmed.
    func photographer(_ photographer: ZLPhotographer, didCancel _: Any?)
    
}

// default implementation makes delegate method optional.
extension ZLPhotographerDelegate {
    
    func photographer(_ photographer: ZLPhotographer, didTakePhoto photo: UIImage, argument: [String: Any]?) { }
    
    func photographer(_ photographer: ZLPhotographer, didCancel _: Any?) { }
    
}
