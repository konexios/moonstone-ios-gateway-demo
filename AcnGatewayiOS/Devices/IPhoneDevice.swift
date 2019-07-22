//
//  IPhoneDevice.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 27/06/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreMotion

class IPhoneDevice: Device {
    
    let motionManager = CMMotionManager()
    
    override var deviceUid: String? {
        return UIDevice.UUID()
    }
    
    /// software version and name
    override var softwareVersion: String {
        return UIDevice.current.systemVersion
    }
    
    override var softwareName: String {
        return "iOS"
    }
    
    init() {
        super.init(DeviceType.IPhoneDevice)
        
        deviceTelemetry = [
            Telemetry(type: SensorType.accelerometerX, label: "Accelerometer"),
            Telemetry(type: SensorType.accelerometerY, label: ""),
            Telemetry(type: SensorType.accelerometerZ, label: ""),
            Telemetry(type: SensorType.gyroscopeX, label: "Gyroscope"),
            Telemetry(type: SensorType.gyroscopeY, label: ""),
            Telemetry(type: SensorType.gyroscopeZ, label: ""),
            Telemetry(type: SensorType.magnetometerX, label: "Magnetometer"),
            Telemetry(type: SensorType.magnetometerY, label: ""),
            Telemetry(type: SensorType.magnetometerZ, label: "")
        ]
        
        deviceProperties = IPhoneDeviceProperties.sharedInstance
        deviceProperties?.reload()
    }
    
    override func enable() {
        super.enable()
        
        checkAndRegisterDevice()
        
        let iPhoneDeviceProperties = deviceProperties as! IPhoneDeviceProperties
        
        if iPhoneDeviceProperties.isSensorEnabled(key: .AccelerometerSensorEnabled) {
            startAccelerometer()
        }
        
        if iPhoneDeviceProperties.isSensorEnabled(key: .GyroscopeSensorEnabled) {
            startGyroscope()
        }
        
        if iPhoneDeviceProperties.isSensorEnabled(key: .MagnetometerSensorEnabled) {
            startMagnetometer()
        }      
        
        setState(newState: .Monitoring)
    }
    
    override func disable() {
        super.disable()
        
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        motionManager.stopMagnetometerUpdates()
        
        setState(newState: .Stopped)
    }
    
    override func saveProperties(properties: [String : AnyObject]) {
        super.saveProperties(properties: properties)
        
        if enabled {
            let iPhoneDeviceProperties = deviceProperties as! IPhoneDeviceProperties
            
            for propertyKey in properties.keys {
                if let property = IPhoneDeviceProperty.IPhoneDevicePropertyKey(rawValue: propertyKey) {
                    if iPhoneDeviceProperties.isSensorEnabled(key: property) {
                        enableSensor(property)
                    } else {
                        disableSensor(property)
                    }
                }
            }
        }
    }
    
    override func updateProperty(property: DeviceProperty) {
        if enabled {
            let iPhoneDeviceProperties = deviceProperties as! IPhoneDeviceProperties
            if let iPhoneDeviceProperty = property as? IPhoneDeviceProperty {
                if iPhoneDeviceProperties.isSensorEnabled(key: property) {
                    enableSensor(iPhoneDeviceProperty.propertyKey)
                } else {
                    disableSensor(iPhoneDeviceProperty.propertyKey)
                }
            }
        }
    }
    
    func enableSensor(_ property: IPhoneDeviceProperty.IPhoneDevicePropertyKey) {
        switch property {
        case .AccelerometerSensorEnabled:
            startAccelerometer()
            break
        case .GyroscopeSensorEnabled:
            startGyroscope()
            break
        case .MagnetometerSensorEnabled:
            startMagnetometer()
            break
        }
    }
    
    func disableSensor(_ property: IPhoneDeviceProperty.IPhoneDevicePropertyKey) {
        switch property {
        case .AccelerometerSensorEnabled:
            motionManager.stopAccelerometerUpdates()
            break
        case .GyroscopeSensorEnabled:
            motionManager.stopGyroUpdates()
            break
        case .MagnetometerSensorEnabled:
            motionManager.stopMagnetometerUpdates()
            break
        }       
    }
    
    func startAccelerometer() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) { [weak self] (data, error) in
                if let acceleration = data?.acceleration {
                    self?.processSensorData(data: AccelerometerData(Vector(x: acceleration.x, y: acceleration.y, z: acceleration.z)))
                }
            }
        }
    }
    
    func startGyroscope() {
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1
            motionManager.startGyroUpdates(to: OperationQueue.main) { [weak self] (data, error) in
                if let rotationRate = data?.rotationRate {
                    self?.processSensorData(data: GyroscopeData(Vector(x: rotationRate.x, y: rotationRate.y, z: rotationRate.z)))
                }
            }
        }
    }
    
    func startMagnetometer() {
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = 0.1
            motionManager.startMagnetometerUpdates(to: OperationQueue.main) { [weak self] (data, error) in
                if let magneticField = data?.magneticField {
                    self?.processSensorData(data: MagnetometerData(Vector(x: magneticField.x, y: magneticField.y, z: magneticField.z)))
                    
                }
            }
        }
    }
}
