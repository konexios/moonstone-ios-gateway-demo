//
//  DeviceDetailsControllerItem.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 19/04/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

struct DeviceDetailsControllerItem {
    
    // name of the device
    var deviceName: String
    
    var mainColor: UIColor
    
    // content view controller id
    var identifier: String
    
    // settings view controller id
    var settings: String
    
    init(deviceName: String, mainColor: UIColor, identifier: String, settings: String) {
        self.deviceName = deviceName
        self.mainColor = mainColor
        self.identifier = identifier
        self.settings = settings
    }

}
