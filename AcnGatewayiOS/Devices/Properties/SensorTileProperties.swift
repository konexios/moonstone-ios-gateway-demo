//
//  SensorTileProperties.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 12/09/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreBluetooth

class SensorTileProperty: DeviceProperty {
    
    enum SensorTilePropertyKey: String {
        case EnvironmentSensorEnabled = "EnvironmentSensor/enabled"
        case MovementSensorEnabled    = "MovementSensor/enabled"
        case MicLevelSensorEnabled    = "MicLevelSensor/enabled"
        case SwitchSensorEnabled      = "SwitchSensor/enabled"
    }
    
    var propertyKey: SensorTilePropertyKey
    
    init (key: SensorTilePropertyKey) {
        propertyKey = key
    }
    
    override class var allValues: [DeviceProperty] {
        return [
            SensorTileProperty(key: .EnvironmentSensorEnabled),
            SensorTileProperty(key: .MovementSensorEnabled),
            SensorTileProperty(key: .MicLevelSensorEnabled),
            SensorTileProperty(key: .SwitchSensorEnabled)
        ]
    }
    
    override var value: String {
        return propertyKey.rawValue
    }
    
    override var type: PropertyType {
        switch propertyKey {
        case
        .EnvironmentSensorEnabled,
        .MovementSensorEnabled,
        .MicLevelSensorEnabled,
        .SwitchSensorEnabled:
            return .boolean
        }
    }
    
    override var nameForDisplay: String {
        switch propertyKey {
        case .EnvironmentSensorEnabled: return "Environment"
        case .MovementSensorEnabled:    return "Movement"
        case .MicLevelSensorEnabled:    return "Mic Level"
        case .SwitchSensorEnabled:      return "Switch"

        }
    }
    
    override var sensorUUID: CBUUID? {
        switch propertyKey {
        case .EnvironmentSensorEnabled: return SensorTile.EnvironmentSensor.SensorUUID
        case .MovementSensorEnabled:    return SensorTile.MovementSensor.SensorUUID
        case .MicLevelSensorEnabled:    return SensorTile.MicLevelSensor.SensorUUID
        case .SwitchSensorEnabled:      return SensorTile.SwitchSensor.SensorUUID
        }
    }
}

class SensorTileProperties: DeviceProperties {
    
    override var userDefaultsPrefix: String {
        return "sensortile-device-property"
    }
    
    static let sharedInstance = SensorTileProperties()
    
    override private init() {
        super.init()
    }
    
    override func reload() {
        super.reload()
        loadProperties(keys: SensorTileProperty.allValues)
    }
    
    override func propertyForKey(key: String) -> DeviceProperty? {
        if let propertyKey = SensorTileProperty.SensorTilePropertyKey(rawValue: key) {
            return SensorTileProperty(key: propertyKey)
        } else {
            return nil
        }
    }
    
    override func isValidKey(key: String) -> Bool {
        if let _ = SensorTileProperty.SensorTilePropertyKey(rawValue: key) {
            return true
        } else {
            return false
        }
    }
    
    override func isSensorEnabled(serviceUUID: CBUUID) -> Bool {
        switch serviceUUID {
        case SensorTile.EnvironmentSensor.SensorUUID:
            return isSensorEnabled(key: .EnvironmentSensorEnabled)
        case SensorTile.MovementSensor.SensorUUID:
            return isSensorEnabled(key: .MovementSensorEnabled)
        case SensorTile.MicLevelSensor.SensorUUID:
            return isSensorEnabled(key: .MicLevelSensorEnabled)
        case SensorTile.SwitchSensor.SensorUUID:
            return isSensorEnabled(key: .SwitchSensorEnabled)
        default:
            return true
        }
    }
    
    func registerDefaults() {
        registerDefaults(keys: SensorTileProperty.allValues)
    }
    
    func isSensorEnabled(key: SensorTileProperty.SensorTilePropertyKey) -> Bool {
        return boolPropertyForKey(key: key.rawValue)
    }    
}
