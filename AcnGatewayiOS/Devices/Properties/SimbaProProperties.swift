//
//  SimbaProProperties.swift
//  AcnGatewayiOS
//
//  Created by Alexey Chechetkin on 22/12/2017.
//  Copyright © 2017 Arrow Electronics, Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

class SimbaProProperty: DeviceProperty {
    
    enum SimbaProPropertyKey: String {
        case EnvironmentSensorEnabled   = "EnvironmentSensor/enabled"
        case MovementSensorEnabled      = "MovementSensor/enabled"
        case MicLevelSensorEnabled      = "MicLevelSensor/enabled"
        case AmbientLightSensorEnabled  = "AmbientLightSensor/enabled"
    }
    
    var propertyKey: SimbaProPropertyKey
    
    init (key: SimbaProPropertyKey) {
        propertyKey = key
    }
    
    override class var allValues: [DeviceProperty] {
        return [
            SimbaProProperty(key: .EnvironmentSensorEnabled),
            SimbaProProperty(key: .AmbientLightSensorEnabled),
            SimbaProProperty(key: .MovementSensorEnabled),
            SimbaProProperty(key: .MicLevelSensorEnabled)
        ]
    }
    
    override var value: String {
        return propertyKey.rawValue
    }
    
    override var type: PropertyType {
        switch propertyKey
        {
        case
        .EnvironmentSensorEnabled,
        .AmbientLightSensorEnabled,
        .MovementSensorEnabled,
        .MicLevelSensorEnabled:
            return .boolean
        }
    }
    
    override var nameForDisplay: String {
        switch propertyKey
        {
        case .EnvironmentSensorEnabled:     return "Environment"
        case .AmbientLightSensorEnabled:    return "Light"
        case .MovementSensorEnabled:        return "Movement"
        case .MicLevelSensorEnabled:        return "Mic Level"
        }
    }
    
    override var sensorUUID: CBUUID? {
        switch propertyKey
        {
        case .EnvironmentSensorEnabled:     return SimbaPro.EnvironmentSensor.SensorUUID
        case .AmbientLightSensorEnabled:    return SimbaPro.AmbientLightSensor.SensorUUID
        case .MovementSensorEnabled:        return SimbaPro.MovementSensor.SensorUUID
        case .MicLevelSensorEnabled:        return SimbaPro.MicLevelSensor.SensorUUID
        }
    }
}

class SimbaProProperties: DeviceProperties {
    
    override var userDefaultsPrefix: String {
        return "simbapro-device-property"
    }
    
    static let sharedInstance = SimbaProProperties()
    
    override private init() {
        super.init()
    }
    
    override func reload() {
        super.reload()
        loadProperties(keys: SimbaProProperty.allValues)
    }
    
    override func propertyForKey(key: String) -> DeviceProperty? {
        if let propertyKey = SimbaProProperty.SimbaProPropertyKey(rawValue: key) {
            return SimbaProProperty(key: propertyKey)
        } else {
            return nil
        }
    }
    
    override func isValidKey(key: String) -> Bool {
        if let _ = SimbaProProperty.SimbaProPropertyKey(rawValue: key) {
            return true
        } else {
            return false
        }
    }
    
    override func isSensorEnabled(serviceUUID: CBUUID) -> Bool {
        switch serviceUUID
        {
        case SimbaPro.EnvironmentSensor.SensorUUID:     return isSensorEnabled(key: .EnvironmentSensorEnabled)
        case SimbaPro.AmbientLightSensor.SensorUUID:    return isSensorEnabled(key: .AmbientLightSensorEnabled)
        case SimbaPro.MovementSensor.SensorUUID:        return isSensorEnabled(key: .MovementSensorEnabled)
        case SimbaPro.MicLevelSensor.SensorUUID:        return isSensorEnabled(key: .MicLevelSensorEnabled)
            
        default:
            return true
        }
    }
    
    func registerDefaults() {
        registerDefaults(keys: SimbaProProperty.allValues)
    }
    
    func isSensorEnabled(key: SimbaProProperty.SimbaProPropertyKey) -> Bool {
        return boolPropertyForKey(key: key.rawValue)
    }
}

