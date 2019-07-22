//
//  Copyright © 2017 Arrow Electronics, Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

class OnSemiRSL10Property: DeviceProperty {
    
    enum OnSemiRSL10PropertyKey: String {
        case PirSensorEnabled    = "PirSensor/enabled"
        case LightSensorEnabled  = "LightSensor/enabled"
    }
    
    private var propertyKey: OnSemiRSL10PropertyKey
    
    init (key: OnSemiRSL10PropertyKey) {
        propertyKey = key
    }
    
    override class var allValues: [DeviceProperty] {
        return [
            OnSemiRSL10Property(key: .LightSensorEnabled),
            OnSemiRSL10Property(key: .PirSensorEnabled)
        ]
    }
    
    override var value: String {
        return propertyKey.rawValue
    }
    
    override var type: PropertyType {
        return .boolean
    }
    
    override var nameForDisplay: String {
        switch propertyKey
        {
        case .LightSensorEnabled:   return "Light"
        case .PirSensorEnabled:     return "Movement detector"
        }
    }
    
    override var sensorUUID: CBUUID? {
        switch propertyKey
        {
        case .LightSensorEnabled:   return OnSemiRSL10.LightSensor.SensorUUID
        case .PirSensorEnabled:     return OnSemiRSL10.PirSensor.SensorUUID
        }
    }
}

class OnSemiRSL10Properties: DeviceProperties {
    
    override var userDefaultsPrefix: String {
        return "onsemirsl10-device-property"
    }
    
    static let sharedInstance = OnSemiRSL10Properties()
    
    override func reload() {
        super.reload()
        loadProperties(keys: OnSemiRSL10Property.allValues)
    }
    
    override func propertyForKey(key: String) -> DeviceProperty? {
        if let propertyKey = OnSemiRSL10Property.OnSemiRSL10PropertyKey(rawValue: key) {
            return OnSemiRSL10Property(key: propertyKey)
        } else {
            return nil
        }
    }
    
    override func isValidKey(key: String) -> Bool {
        if let _ = OnSemiRSL10Property.OnSemiRSL10PropertyKey(rawValue: key) {
            return true
        } else {
            return false
        }
    }
    
    override func isSensorEnabled(serviceUUID: CBUUID) -> Bool {
        switch serviceUUID
        {
        case OnSemiRSL10.PirSensor.SensorUUID:      return isSensorEnabled(key: .PirSensorEnabled)
        case OnSemiRSL10.LightSensor.SensorUUID:    return isSensorEnabled(key: .LightSensorEnabled)
            
        default:
            return true
        }
    }
    
    func registerDefaults() {
        registerDefaults(keys: OnSemiRSL10Property.allValues)
    }
    
    func isSensorEnabled(key: OnSemiRSL10Property.OnSemiRSL10PropertyKey) -> Bool {
        return boolPropertyForKey(key: key.rawValue)
    }
}


