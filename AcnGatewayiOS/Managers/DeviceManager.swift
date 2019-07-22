//
//  DeviceManager.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 23/11/2016.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

class DeviceManager {
    
    static let sharedInstance = DeviceManager()
    
    var deviceTypes: [DeviceType] = [
        .SiLabsSensorPuck,
        .IPhoneDevice,
        .ThunderboardReact,
        .SensorTile,
        .SimbaPro,
        .OnSemiRSL10
    ]
    
    var devices = [Device]()
    
    private init() {
    }
    
    func hasActiveDevice() -> Bool {
        for device in devices {
            if device.enabled {
                return true
            }
        }
        return false
    }
    
    /// Find device with given deviceHid (objectHid)
    /// - parameter deviceHid: device hid to find
    /// - returns: device or nil if not found
    func deviceWithHid(_ deviceHid: String) -> Device? {
        guard let device = devices.first(where: { ($0.loadDeviceId() ?? "") == deviceHid }) else {
            return nil
        }
        
        return device
    }
    
    func reloadDeviceList() {
        
        let devicesCopy = self.devices
        
        DispatchQueue.global().async {            
            for device in devicesCopy {
                if device.enabled {
                    device.disable()
                }                
                device.disconnect()
            }
        }
        
        devices.removeAll()
        
        for i in 0..<deviceTypes.count {
            let type = deviceTypes[i]
            let count = DatabaseManager.sharedInstance.deviceCount(type: type)
            addDevicesForType(type: type, count: count)
        }
    }
    
    func addDevice(type: DeviceType) {
        devices.append(deviceForType(type: type))
        DatabaseManager.sharedInstance.increaseDeviceCount(device: type)
    }
    
    func removeDevice(index: Int) {
        let device =  devices[index]
        DatabaseManager.sharedInstance.decreaseDeviceCount(device: device.deviceType)
        devices.remove(at: index)
        
        if let bleDevice = device as? BleDevice, bleDevice.connected {
            DispatchQueue.global().async {
                bleDevice.disable()
                bleDevice.disconnect()
            }
        }
        else if let sensorPuck = device as? SiLabsSensorPuck {
            DispatchQueue.global().async {
                sensorPuck.disable()
            }
        }
    }
    
    private func addDevicesForType(type: DeviceType, count: Int) {
        for _ in 0..<count {
            devices.append(deviceForType(type: type))
        }
    }
    
    private func deviceForType(type: DeviceType) -> Device {
        switch type {
        case .SiLabsSensorPuck:
            return SiLabsSensorPuck()
            
        case .IPhoneDevice:
            return IPhoneDevice()
            
        case .ThunderboardReact:
            return Thunderboard()
            
        case .SensorTile:
            return SensorTile()
            
        case .SimbaPro:
            return SimbaPro()
            
        case .OnSemiRSL10:
            return OnSemiRSL10()
        }
    }    
    
}
