//
//  UIDeviceExtension.swift
//  SpriteKitExtension
//
//  Created by HanHaikun on 2020/2/21.
//  Copyright © 2020 HanHaikun. All rights reserved.
//

import Foundation
import UIKit


//该Extension用于识别设备类型和是否是刘海屏
//This Extension of UIDevice can recognize what kind Device
public extension UIDevice {
    var modelName: String {
        
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        var identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8 , value != 0 else
            {
                return identifier
            }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        if identifier == "x86_64" || identifier == "i386" {
            identifier = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? identifier
        }
        
        
        switch identifier {
        case "iPod1,1":                                 return "iPod Touch 1"
        case "iPod2,1":                                 return "iPod Touch 2"
        case "iPod3,1":                                 return "iPod Touch 3"
        case "iPod4,1":                                 return "iPod Touch 4"
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPod9,1":                                 return "iPod Touch 7"
            
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPhone9,1":                               return "iPhone 7 (CDMA)"
        case "iPhone9,3":                               return "iPhone 7 (GSM)"
        case "iPhone9,2":                               return "iPhone 7 Plus (CDMA)"
        case "iPhone9,4":                               return "iPhone 7 Plus (GSM)"
        case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
        case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6":                return "iPhone X"
        case "iPhone11,2":                              return "iPhone XS"
        case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
        case "iPhone11,8":                              return "iPhone XR"
        case "iPhone12,1":                              return "iPhone 11"
        case "iPhone12,3":                              return "iPhone 11 Pro"
        case "iPhone12,5":                              return "iPhone 11 Pro Max"
            
        case "iPad1,1", "iPad1,2":                      return "iPad 1"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4":                      return "iPad Pro 9,7"
        case "iPad6,7", "iPad6,8":                      return "iPad Pro 12.9"
            
        case "AppleTV2,1":                              return "Apple TV 2"
        case "AppleTV3,1", "AppleTV3,2":                return "Apple TV 3"
        case "AppleTV5,3":                              return "Apple TV 4"
        case "AppleTV6,2":                              return "Apple TV 4K"
            
        case "i386", "x86_64":                          return "Simulator"
            
        default:                                        return identifier
            
        }
    }
    
    //判断是否是刘海屏
    //determined whether the device is Notch Screen
    var isNotchScreen: Bool {
        switch modelName {
        case "iPhone X",
             "iPhone XS",
             "iPhone XS Max",
             "iPhone XR",
             "iPhone 11",
             "iPhone 11 Pro",
             "iPhone 11 Pro Max":
            return true
        default:
            return false
        }
    }
}
