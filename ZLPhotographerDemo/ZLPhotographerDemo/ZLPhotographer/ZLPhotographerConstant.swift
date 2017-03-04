//
//  ZLPhotographerConstant.swift
//  ZLPhotographerDemo
//
//  Created by 朱子澜 on 16/12/22.
//  Copyright © 2016年 杉玉府. All rights reserved.
//

import Foundation
import AVFoundation

extension ZLPhotographer {
    
    // photo arguments
    static var argumentCountdownKey: String { return "countdown" }
    static var argumentExtraMessageKey: String { return "extras" }
    
    // capture device observe key paths
    static var adjustingFocusKeyPath: String { return "adjustingFocus" }
    static var adjustingExposureKeyPath: String { return "adjustingExposure" }
    static var adjustingWhiteBalanceKeyPath: String { return "adjustingWhiteBalance" }
    
    // custom keys
    static var focusPointKeyPath: String { return "focusPointOfInterest" }
    
    enum Position: Int {
        case front
        case back
        
        var captureDevicePosition: AVCaptureDevicePosition {
            switch self {
            case .front:
                return AVCaptureDevicePosition.front
            case .back:
                return AVCaptureDevicePosition.back
            }
        }
    }
    
    static let filterNames: [(title: String, name: String)] = {
        return [
            (title: "怀旧", name: "CIPhotoEffectInstant"),
            (title: "黑白", name: "CIPhotoEffectNoir"),
            (title: "色调", name: "CIPhotoEffectTonal"),
            (title: "岁月", name: "CIPhotoEffectTransfer"),
            (title: "单色", name: "CIPhotoEffectMono"),
            (title: "褪色", name: "CIPhotoEffectFade"),
            (title: "冲印", name: "CIPhotoEffectProcess"),
            (title: "铬黄", name: "CIPhotoEffectChrome")
        ]
    } ()
    
}
