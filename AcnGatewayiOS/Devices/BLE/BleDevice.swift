//
//  BleDevice.swift
//  AcnGatewayiOS
//
//  Created by Tam Nguyen on 10/5/15.
//  Copyright © 2015 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreBluetooth

class BleDevice : Device, BleDeviceProtocol
{
    static let kDeviceReconnectTimeout: TimeInterval = 0.6
    
    var device: CBPeripheral?
    
    /// default lookup name
    var lookupName: String? {
        return nil
    }
    
    /// holds discovered sensors
    var sensorMap = [CBUUID: BleSensorProtocol]()
    
    /// default device name
    override var deviceName: String {
        preconditionFailure("[BleDevice] abstract property!")
    }
    
    override var deviceUid: String? {
        return device?.identifier.uuidString
    }
    
    var multipleDataServices: Bool
    {
        switch deviceType {
            case .ThunderboardReact,
                 .SensorTile,
                 .SimbaPro,
                 .OnSemiRSL10:
                return true
            
            default:
                return false
        }
    }
    
    /// returns true if BLE device is connected
    var connected: Bool {
        return device?.state == .connected
    }
    
    override func enable() {
        super.enable()
        
        if self.device == nil {            
            DispatchQueue.global().async {
                
                // search BLE device
                self.setState(newState: .Detecting)
                let lookupName = self.lookupName ?? self.deviceName
                self.device = BleUtils.sharedInstance.lookup(name: lookupName, timeOutInSec: 7)
                
                if self.device != nil {
                    print("[BleDevice] enable() found device: \(String(describing: self.device!.name))")
                    self.setState(newState: DeviceState.Connecting)
                    
                    // check and register device
                    print("[BleDevice] enable() checkAndRegisterDevice ...")
                    self.checkAndRegisterDevice()
                    
                    // lookup services
                    let services = BleUtils.sharedInstance.connect(peripheral: self.device!, timeOutInSec: 10)
                    print("[BleDevice] enable() found \(services.count) services")
                    
                    BleUtils.sharedInstance.registerDevice(self)
                    
                    if services.count > 0 {
                        self.setState(newState: DeviceState.Connected)
                        
                        for service in services {
                            // discover service characteristics
                            if let device = self.device {
                                BleUtils.sharedInstance.discover(peripheral: device, service: service, timeOutInSec: 5)
                            }
                            else {
                                print("[BleDevice] enable() - device was disconnected in the middle of service discovering")
                                BleUtils.sharedInstance.unregisterDevice(self)
                                self.enabled = false
                                self.setState(newState: .Error)
                                return
                            }
                            
                            // create sensor instances
                            if self.multipleDataServices {
                                self.createSensors(service)
                            }
                            else if let sensor = self.createSensor(service) {
                                self.sensorMap[service.uuid] = sensor
                            }
                        }
                        
                        self.enableSensors()
                    }
                    else {
                        print("[BleDevice] enable() - connecting is failed")
                        BleUtils.sharedInstance.unregisterDevice(self)
                        // reset CBPeripheral
                        self.device = nil
                        self.enabled = false
                        self.setState(newState: .Error)
                    }
                }
                else {
                    print("[BleDevice] enable() not found")
                    self.enabled = false
                    self.setState(newState: .NotFound)
                }
            }
        }
        else {
            DispatchQueue.global().async {
                self.enableSensors()
            }
        }
    }
    
    override func disable() {
        super.disable()

        for sensor in self.sensorMap.values {
            print("[BleDevice] disabling sensor \(sensor.name)")
            sensor.disable()
        }
        
        self.setState(newState: DeviceState.Stopped)
    }
    
    override func disconnect() {
        super.disconnect()
        if let device = device {
            BleUtils.sharedInstance.disconnect(peripheral: device)
        }        
    }
    
    // MARK: Device Properties
    
    override func saveProperties(properties: [String : AnyObject]) {
        super.saveProperties(properties: properties)
        
        if enabled && deviceProperties != nil {
            
            for propertyKey in properties.keys {
                if let property = deviceProperties!.propertyForKey(key: propertyKey) {
                    if let sensorUUID = property.sensorUUID {
                        if deviceProperties!.isSensorEnabled(key: property) {
                            DispatchQueue.global().async {
                                self.sensorMap[sensorUUID]?.enable()
                            }
                        } else {
                            DispatchQueue.global().async {
                                self.sensorMap[sensorUUID]?.disable()
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func updateProperty(property: DeviceProperty)
    {
        guard   enabled,
                let deviceProperties = deviceProperties,
                let sensorUUID = property.sensorUUID,
                let sensor = sensorMap[sensorUUID]
        else {
            print("[BleDevice] updateProperty() can not update property \(property.nameForDisplay)")
            return
        }
        
        let isEnabled = deviceProperties.isSensorEnabled(key: property)
        DispatchQueue.global().async {
            isEnabled ? sensor.enable() : sensor.disable()
        }
    }
    
    func enableSensors() {
        for (serviceUUID, sensor) in sensorMap {
            if deviceProperties != nil {
                if deviceProperties!.isSensorEnabled(serviceUUID: serviceUUID) {
                    print("[BleDevice] enableSensors() \(sensor.name)")
                    sensor.enable()
                }
            } else {
                print("[BleDevice] enableSensors() \(sensor.name)")
                sensor.enable()
            }
        }
        setState(newState: DeviceState.Monitoring)
    }
    
    func createSensor(_ service: CBService) -> BleSensorProtocol? {
        preconditionFailure("[BleDevice] abstract method!")
    }
    
    func createSensors(_ service: CBService) {
        preconditionFailure("[BleDevice] abstract method!")
    }  
    
    // MARK: BleDeviceProtocol
    
    func charChanged(char: CBCharacteristic)
    {
        let sensorUUID = multipleDataServices ?  char.uuid : char.service.uuid
        
        if let sensor = sensorMap[sensorUUID], let data = char.value {
            let sensorData = sensor.parse(data: data)
            processSensorData(data: sensorData)
        }
        else {
            print("[BleDevice] charChanged() empty data or sensor not found in sensorMap!")
        }
    }
    
    func deviceDisconnected()
    {
        print("[BleDevice] deviceDisconnected() \(deviceType.rawValue)")
        
        // should stop poling sensors
        sensorMap.forEach { _, sensor in
            sensor.stop()
        }
        
        BleUtils.sharedInstance.unregisterDevice(self)
        self.device = nil

        sensorMap.removeAll()
        
        setState(newState: .Disconnected)
        
        if enabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + BleDevice.kDeviceReconnectTimeout) {
                self.enable()
            }
        }        
    }
}
