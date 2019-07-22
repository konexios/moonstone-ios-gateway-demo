//
//  IPhoneDeviceProperties.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 01/07/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

class IPhoneDeviceProperty: DeviceProperty {
    
    enum IPhoneDevicePropertyKey: String {
        case AccelerometerSensorEnabled = "AccelerometerSensor/enabled"
        case GyroscopeSensorEnabled     = "GyroscopeSensor/enabled"
        case MagnetometerSensorEnabled  = "MagnetometerSensor/enabled"
    }
    
    var propertyKey: IPhoneDevicePropertyKey
    
    init (key: IPhoneDevicePropertyKey) {
        propertyKey = key
    }
    
    override class var allValues: [DeviceProperty] {
        return [
            IPhoneDeviceProperty(key: .AccelerometerSensorEnabled),
            IPhoneDeviceProperty(key: .GyroscopeSensorEnabled),
            IPhoneDeviceProperty(key: .MagnetometerSensorEnabled)
        ]
    }
    
    override var value: String {
        return propertyKey.rawValue
    }
    
    override var type: PropertyType {
        switch propertyKey {
        case
        .AccelerometerSensorEnabled,
        .GyroscopeSensorEnabled,
        .MagnetometerSensorEnabled:
            return .boolean
        }
    }
    
    override var nameForDisplay: String {
        switch propertyKey {
        case .AccelerometerSensorEnabled: return "Accelerometer"
        case .GyroscopeSensorEnabled:     return "Gyroscope"
        case .MagnetometerSensorEnabled:  return "Magnetometer"
        }
    }
}

class IPhoneDeviceProperties: DeviceProperties {
    
    override var userDefaultsPrefix: String {
        return "iphone-device-property"
    }
    
    static let sharedInstance = IPhoneDeviceProperties()
    
    override private init() {
        super.init()
    }
    
    override func reload() {
        super.reload()
        loadProperties(keys: IPhoneDeviceProperty.allValues)
    }
    
    override func isValidKey(key: String) -> Bool {
        if let _ = IPhoneDeviceProperty.IPhoneDevicePropertyKey(rawValue: key) {
            return true
        } else {
            return false
        }
    }
    
    func isSensorEnabled(key: IPhoneDeviceProperty.IPhoneDevicePropertyKey) -> Bool {
        return boolPropertyForKey(key: key.rawValue)
    }
    
    func registerDefaults() {
        registerDefaults(keys: IPhoneDeviceProperty.allValues)
    }
}
