//
//  DevicesCount.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 26/10/2016.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import RealmSwift


class DevicesCount: Object {
    @objc dynamic var microsoftBandCount = 0
    
    @objc dynamic var siLabsSensorPuckCount = 0
    
    @objc dynamic var iPhoneDeviceCount = 1
    
    @objc dynamic var senseAbility2Count = 0
    
    @objc dynamic var thunderboardCount = 0
    
    @objc dynamic var sensorTileCount = 0
    @objc dynamic var sensorTileDeviceUUID = ""
    
    @objc dynamic var simbaProCount = 0
    @objc dynamic var simbaProDeviceUUID = ""
    
    @objc dynamic var onSemiBleCount = 0
    @objc dynamic var onSemiRSL10DeviceUUID = ""
    
    func deviceCount(device: DeviceType) -> Int {
        switch device {
        case .SiLabsSensorPuck:     return siLabsSensorPuckCount
        case .IPhoneDevice:         return iPhoneDeviceCount
        case .ThunderboardReact:    return thunderboardCount
        case .SensorTile:           return sensorTileCount
        case .SimbaPro:             return simbaProCount
        case .OnSemiRSL10:          return onSemiBleCount
        }
    }
}
