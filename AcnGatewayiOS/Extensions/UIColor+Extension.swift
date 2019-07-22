//
//  UIColor+Extension.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 19/04/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

extension UIColor {
    
    class var defaultTint: UIColor {
        return UIView().tintColor
    }
    
    // #29272a
    class var gray0: UIColor {
        return UIColor(red: 41.0 / 255.0, green: 39.0 / 255.0, blue: 42.0 / 255.0, alpha: 1)
    }
    
    // #7b7b7b
    class var gray1: UIColor {
        return UIColor(red: 123.0 / 255.0, green: 123.0 / 255.0, blue: 123.0 / 255.0, alpha: 1)
    }
    
    // #bbbbbb
    class var gray2: UIColor {
        return UIColor(red: 187.0 / 255.0, green: 187.0 / 255.0, blue: 187.0 / 255.0, alpha: 1)
    }
    
    // #333333
    class var gray3: UIColor {
        return UIColor(red: 51.0 / 255.0, green: 51.0 / 255.0, blue: 51.0 / 255.0, alpha: 1)
    }
    
    // 0 - 161 - 155
    class var mainColor: UIColor {
        return UIColor(red: 0.0 / 255.0, green: 161.0 / 255.0, blue: 155.0 / 255.0, alpha: 1)
    }
    
    class var mainColor2: UIColor {
        return UIColor(red: 28.0 / 255.0, green: 100.0 / 255.0, blue: 98.0 / 255.0, alpha: 1)
    }
    
    class var mainColor3: UIColor {
        return UIColor(red: 69.0 / 255.0, green: 233.0 / 255.0, blue: 148.0 / 255.0, alpha: 1)
    }
    
    
    // MARK: Home menu colors
    
    class func jabraPulseMenuColor() -> UIColor {
        return UIColor(red:0.33, green:0.51, blue:0.2, alpha:1)
    }
    
    class func microsoftBandMenuColor() -> UIColor {
        //return UIColor(red:0.18, green:0.34, blue:0.6, alpha:1)
        return UIColor(red:0.22, green:0.65, blue:0.94, alpha:1)
    }
    
    class func sensorTagMenuColor() -> UIColor {
        //return UIColor(red:0.76, green:0.57, blue:0, alpha:1)
        return UIColor(red:0.8, green:0.11, blue:0, alpha:1)
    }
    
    class func appleHealthKitMenuColor() -> UIColor {
        return UIColor(red:0.78, green:0.36, blue:0.06, alpha:1)
    }
    
    class func sensorPuckMenuColor() -> UIColor {
        //return UIColor(red:0.76, green:0.57, blue:0, alpha:1)
        return UIColor(red:0.85, green:0.12, blue:0.17, alpha:1)
    }
    
    class func iPhoneDeviceMenuColor() -> UIColor {
        return UIColor(red:0.8, green:0.11, blue:0, alpha:1)
    }
    
    class func senseAbilityMenuColor() -> UIColor {
        return UIColor(red:0.22, green:0.65, blue:0.94, alpha:1)
    }
    
    // MARK: Details view controller colors
    
    class func microsoftBandColor() -> UIColor {
        return UIColor(red:0.22, green:0.65, blue:0.94, alpha:1)
    }
    
    class func sensorTagColor() -> UIColor {
        return UIColor(red:0.8, green:0.11, blue:0, alpha:1)
    }
    
    class func sensorPuckColor() -> UIColor {
        return UIColor(red:0.85, green:0.12, blue:0.17, alpha:1)
    }
    
    class func iPhoneDeviceColor() -> UIColor {
        return UIColor(red:0.8, green:0.11, blue:0, alpha:1)
    }
    
    class func senseAbilityColor() -> UIColor {
        return UIColor(red:0.22, green:0.65, blue:0.94, alpha:1)
    }
    
    // MARK: LEDs
    
    class func led1Color() -> UIColor {
        return UIColor(red:0.25, green:0.73, blue:1, alpha:1)
    }
    
    class func led2Color() -> UIColor {
        return UIColor(red:0.81, green:0.97, blue:0.01, alpha:1)
    }
    
    // MARK: Dashboard
    
    class func telemetryDashboard() -> UIColor {
        return UIColor(red: 0.0 / 255.0, green: 161.0 / 255.0, blue: 155.0 / 255.0, alpha: 1)
    }
    
    class func notificationsDashboard() -> UIColor {
        return UIColor(red: 146.0 / 255.0, green: 39.0 / 255.0, blue: 143.0 / 255.0, alpha: 1)
    }
    
    
    
}
