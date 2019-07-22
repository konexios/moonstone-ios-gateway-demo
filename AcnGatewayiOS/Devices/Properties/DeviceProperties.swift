//
//  DeviceProperties.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 01/06/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreBluetooth

enum PropertyType {
    case boolean
    case integer
    case string
}

class DeviceProperty {
    
    class var allValues: [DeviceProperty] {
        preconditionFailure("Abstract property")
    }
    
    var value: String {
        preconditionFailure("Abstract property")
    }
    
    var type: PropertyType {
        preconditionFailure("Abstract property")
    }
    
    var nameForDisplay: String {
        preconditionFailure("Abstract property")
    }
    
    var sensorUUID: CBUUID? { 
        return nil
    }
}

class DeviceProperties {
    
    var userDefaultsPrefix: String {
        preconditionFailure("Abstract property")
    }
    
    let DefaultBooleanValue = true
    let DefaultIntegerValue = 200
    let DefaultStringValue = ""

    var properties = [String : AnyObject]()
    
    func reload() {
        properties.removeAll()
    }
    
    func loadProperties(keys: [DeviceProperty]) {
        for property in keys {
            switch property.type {
            case .boolean:
                properties[property.value] = boolPropertyForKey(key: property.value) as AnyObject?
                break;
            case .integer:
                properties[property.value] = integerPropertyForKey(key: property.value) as AnyObject?
                break;
            case .string:
                properties[property.value] = stringPropertyForKey(key: property.value) as AnyObject?
                break;
            }
        }
    }
    
    func registerDefaults(keys: [DeviceProperty]) {
        var defaults = [String: AnyObject]()
        
        for key in keys {
            switch key.type {
            case .boolean:
                defaults["\(userDefaultsPrefix)-\(key.value)"] = DefaultBooleanValue as AnyObject?
                break;
            case .integer:
                defaults["\(userDefaultsPrefix)-\(key.value)"] = DefaultIntegerValue as AnyObject?
                break;
            case .string:
                defaults["\(userDefaultsPrefix)-\(key.value)"] = DefaultStringValue as AnyObject?
                break;
            }
        }
        
        UserDefaults.standard.register(defaults: defaults)
    }
    
    func propertyForKey(key: String) -> DeviceProperty? {
        return nil
    }
    
    func isValidKey(key: String) -> Bool {
        return false
    }
    
    func isSensorEnabled(serviceUUID: CBUUID) -> Bool {
        return true
    }
    
    func isSensorEnabled(key: DeviceProperty) -> Bool {
        return boolPropertyForKey(key: key.value)
    }
    
    func saveProperties(properties: [String : AnyObject]) {        
        for (key, value) in properties {
            if isValidKey(key: key) {
                saveProperty(property: value, forKey: key)
            }
        }
    }
    
    func saveProperty(property: AnyObject, forKey key: String) {
        let defaults = UserDefaults.standard
        defaults.setValue(property, forKey: "\(userDefaultsPrefix)-\(key)")
        defaults.synchronize()
        reload()
    }
    
    func boolPropertyForKey(key: String) -> Bool {
        let defaults = UserDefaults.standard
        return defaults.bool(forKey: "\(userDefaultsPrefix)-\(key)")
    }
    
    func integerPropertyForKey(key: String) -> Int {
        let defaults = UserDefaults.standard
        return defaults.integer(forKey: "\(userDefaultsPrefix)-\(key)")
    }
    
    func stringPropertyForKey(key: String) -> String {
        let defaults = UserDefaults.standard
        if let property = defaults.string(forKey: "\(userDefaultsPrefix)-\(key)") {
            return property
        }
        return DefaultStringValue
    }
}
