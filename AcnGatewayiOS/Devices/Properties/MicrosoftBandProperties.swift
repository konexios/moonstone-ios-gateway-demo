//
//  MicrosoftBandProperties.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 01/06/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

class MicrosoftBandProperty: DeviceProperty {
    
    enum MicrosoftBandPropertyKey: String {
        case SkinTemperatureSensorEnabled = "SkinTemperatureSensor/enabled"
        case AccelerometerSensorEnabled   = "AccelerometerSensor/enabled"
        case GyroscopeSensorEnabled       = "GyroscopeSensor/enabled"
        case UVSensorEnabled              = "UVSensor/enabled"
        case PedometerSensorEnabled       = "PedometerSensor/enabled"
        case DistanceSensorEnabled        = "DistanceSensor/enabled"
        case HeartRateSensorEnabled       = "HeartRateSensor/enabled"
    }
    
    var propertyKey: MicrosoftBandPropertyKey
    
    init (key: MicrosoftBandPropertyKey) {
        propertyKey = key
    }
    
    override class var allValues: [DeviceProperty] {
        return [
            MicrosoftBandProperty(key: .SkinTemperatureSensorEnabled),
            MicrosoftBandProperty(key: .AccelerometerSensorEnabled),
            MicrosoftBandProperty(key: .GyroscopeSensorEnabled),
            MicrosoftBandProperty(key: .UVSensorEnabled),
            MicrosoftBandProperty(key: .PedometerSensorEnabled),
            MicrosoftBandProperty(key: .DistanceSensorEnabled),
            MicrosoftBandProperty(key: .HeartRateSensorEnabled)
        ]
    }
    
    override var value: String {
        return propertyKey.rawValue
    }
    
    override var type: PropertyType {
        switch propertyKey {
        case
        .SkinTemperatureSensorEnabled,
        .AccelerometerSensorEnabled,
        .GyroscopeSensorEnabled,
        .UVSensorEnabled,
        .PedometerSensorEnabled,
        .DistanceSensorEnabled,
        .HeartRateSensorEnabled:
            return .boolean
        }
    }
    
    override var nameForDisplay: String {
        switch propertyKey {
        case .SkinTemperatureSensorEnabled: return "Skin Temperature"
        case .AccelerometerSensorEnabled:   return "Accelerometer"
        case .GyroscopeSensorEnabled:       return "Gyroscope"
        case .UVSensorEnabled:              return "UVSensor"
        case .PedometerSensorEnabled:       return "Pedometer"
        case .DistanceSensorEnabled:        return "Distance"
        case .HeartRateSensorEnabled:       return "HeartRate"
        }
    }
}


class MicrosoftBandProperties: DeviceProperties {
    
    override var userDefaultsPrefix: String {
        return "msband-device-property"
    }
    
    static let sharedInstance = MicrosoftBandProperties()

    override private init() {
        super.init()
    }
    
    override func reload() {
        super.reload()
        loadProperties(keys: MicrosoftBandProperty.allValues)
    }
    
    override func isValidKey(key: String) -> Bool {
        if let _ = MicrosoftBandProperty.MicrosoftBandPropertyKey(rawValue: key) {
            return true
        } else {
            return false
        }
    }
    
    func isSensorEnabled(key: MicrosoftBandProperty.MicrosoftBandPropertyKey) -> Bool {
        return boolPropertyForKey(key: key.rawValue)
    }
    
    func registerDefaults() {        
        registerDefaults(keys: MicrosoftBandProperty.allValues)
    }
}
