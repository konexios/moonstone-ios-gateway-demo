//
//  HomeMenuItem.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 28/03/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

enum DeviceCategory {
    case BLE
    case LTE
    case WiFi
    case None
}

struct HomeMenuItem {
    
    var title: String
    var color: UIColor
    var category: DeviceCategory
    var iconName: String?
    
    var categoryIconImage: UIImage? {
        get {
            switch category {
                case .BLE:  return UIImage(named: "bluetooth-128")
                case .LTE:  return UIImage(named: "")
                case .WiFi: return UIImage(named: "")
                case .None: return nil
            }
        }
    }
    
    var iconImage: UIImage? {
        get {
            if iconName != nil {
                return UIImage(named: iconName!)
            }
            return nil
        }
    }
    
    init(title: String, color: UIColor, category: DeviceCategory, iconName: String?) {
        self.title = title
        self.color = color
        self.category = category
        self.iconName = iconName
    }
}
