//
//  HHConstants.swift
//  Hohenheim
//
//  Created by Elias Abel on 2015/08/31.
//  Copyright © 2015 Meniny Lab. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

internal extension TimeInterval {
    func format(units: NSCalendar.Unit = [.second, .minute, .hour],
                style: DateComponentsFormatter.UnitsStyle = .abbreviated) -> String? {
        let formatter = DateComponentsFormatter.init()
        formatter.unitsStyle = style
        formatter.allowedUnits = units
        return formatter.string(from: self)
    }
}

// Extension
internal extension UIColor {
    class func hex (_ hexStr : NSString, alpha : CGFloat) -> UIColor {
        
        let realHexStr = hexStr.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: realHexStr as String)
        var color: UInt32 = 0
        if scanner.scanHexInt32(&color) {
            let r = CGFloat((color & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((color & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(color & 0x0000FF) / 255.0
            return UIColor(red:r,green:g,blue:b,alpha:alpha)
        } else {
            print("invalid hex string", terminator: "")
            return UIColor.white
        }
    }
}

extension UIView {
    
    func addBottomBorder(_ color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.borderColor = color.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width:  self.frame.size.width, height: width)
        border.borderWidth = width
        self.layer.addSublayer(border)
    }

}

public extension AVCaptureDevice {
    public enum CurrentFlashMode {
        case off
        case on
        case auto
    }
    
    public func getSettings(flashMode: CurrentFlashMode) -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings()
        
        if self.hasFlash {
            switch flashMode {
            case .auto: settings.flashMode = .auto
            case .on: settings.flashMode = .on
            default: settings.flashMode = .off
            }
        }
        return settings
    }
    
    public static func device(_ types: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera],
                              at position: AVCaptureDevice.Position,
                              mediaType: AVMediaType? = .video) -> AVCaptureDevice? {
        let devicesIOS10 = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: mediaType, position: position)
        for device in devicesIOS10.devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
}

