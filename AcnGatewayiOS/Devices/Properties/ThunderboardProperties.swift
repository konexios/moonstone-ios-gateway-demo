//
//  ThunderboardProperties.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 04/08/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreBluetooth

class ThunderboardProperty: DeviceProperty {
    
    enum ThunderboardPropertyKey: String {
        case HumiditySensorEnabled      = "HumiditySensor/enabled"
        case TemperatureSensorEnabled   = "TemperatureSensor/enabled"
        case UVSensorEnabled            = "UVSensor/enabled"
        case AmbientLightSensorEnabled  = "AmbientLightSensor/enabled"
        case AccelerometerSensorEnabled = "AccelerometerSensor/enabled"
        case OrientationSensorEnabled   = "OrientationSensor/enabled"
    }
    
    var propertyKey: ThunderboardPropertyKey
    
    init (key: ThunderboardPropertyKey) {
        propertyKey = key
    }
    
    override class var allValues: [DeviceProperty] {
        return [
            ThunderboardProperty(key: .HumiditySensorEnabled),
            ThunderboardProperty(key: .TemperatureSensorEnabled),
            ThunderboardProperty(key: .UVSensorEnabled),
            ThunderboardProperty(key: .AmbientLightSensorEnabled),
            ThunderboardProperty(key: .AccelerometerSensorEnabled),
            ThunderboardProperty(key: .OrientationSensorEnabled)
        ]
    }
    
    override var value: String {
        return propertyKey.rawValue
    }
    
    override var type: PropertyType {
        switch propertyKey {
        case
        .HumiditySensorEnabled,
        .TemperatureSensorEnabled,
        .UVSensorEnabled,
        .AmbientLightSensorEnabled,
        .AccelerometerSensorEnabled,
        .OrientationSensorEnabled:
            return .boolean
        }
    }
    
    override var nameForDisplay: String {
        switch propertyKey {
        case .HumiditySensorEnabled:      return "Humidity"
        case .TemperatureSensorEnabled:   return "Temperature"
        case .UVSensorEnabled:            return "UV Sensor"
        case .AmbientLightSensorEnabled:  return "Ambient light"
        case .AccelerometerSensorEnabled: return "Accelerometer"
        case .OrientationSensorEnabled:   return "Orientation"
        }
    }
    
    override var sensorUUID: CBUUID? {
        switch propertyKey {
        case .HumiditySensorEnabled:      return Thunderboard.HumiditySensor.SensorUUID
        case .TemperatureSensorEnabled:   return Thunderboard.TemperatureSensor.SensorUUID
        case .UVSensorEnabled:            return Thunderboard.UVSensor.SensorUUID
        case .AmbientLightSensorEnabled:  return Thunderboard.AmbientLightSensor.SensorUUID
        case .AccelerometerSensorEnabled: return Thunderboard.AccelerometerSensor.SensorUUID
        case .OrientationSensorEnabled:   return Thunderboard.OrientationSensor.SensorUUID
        }
    }
}

class ThunderboardProperties: DeviceProperties {
    
    override var userDefaultsPrefix: String {
        return "thunderboard-device-property"
    }
    
    static let sharedInstance = ThunderboardProperties()
    
    override fileprivate init() {
        super.init()
    }
    
    override func reload() {
        super.reload()
        loadProperties(keys: ThunderboardProperty.allValues)
    }
    
    override func propertyForKey(key: String) -> DeviceProperty? {
        if let propertyKey = ThunderboardProperty.ThunderboardPropertyKey(rawValue: key) {
            return ThunderboardProperty(key: propertyKey)
        } else {
            return nil
        }
    }
    
    override func isValidKey(key: String) -> Bool {
        if let _ = ThunderboardProperty.ThunderboardPropertyKey(rawValue: key) {
            return true
        } else {
            return false
        }
    }
    
    override func isSensorEnabled(serviceUUID: CBUUID) -> Bool {
        switch serviceUUID {
        case Thunderboard.HumiditySensor.SensorUUID:
            return isSensorEnabled(.HumiditySensorEnabled)
        case Thunderboard.TemperatureSensor.SensorUUID:
            return isSensorEnabled(.TemperatureSensorEnabled)
        case Thunderboard.UVSensor.SensorUUID:
            return isSensorEnabled(.UVSensorEnabled)
        case Thunderboard.AmbientLightSensor.SensorUUID:
            return isSensorEnabled(.AmbientLightSensorEnabled)
        case Thunderboard.AccelerometerSensor.SensorUUID:
            return isSensorEnabled(.AccelerometerSensorEnabled)
        case Thunderboard.OrientationSensor.SensorUUID:
            return isSensorEnabled(.OrientationSensorEnabled)
        default:
            return true
        }
    }
    
    func registerDefaults() {
        registerDefaults(keys: ThunderboardProperty.allValues)
    }
    
    func isSensorEnabled(_ key: ThunderboardProperty.ThunderboardPropertyKey) -> Bool {
        return boolPropertyForKey(key: key.rawValue)
    }
    
}
