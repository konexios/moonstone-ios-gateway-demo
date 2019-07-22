//
//  SimbaPro.swift
//  AcnGatewayiOS
//
//  Created by Alexey Chechetkin on 22/12/2017.
//  Copyright © 2017 Arrow Electronics, Inc. All rights reserved.
//

import Foundation
import CoreBluetooth


class SimbaPro: STDevice
{
    // main services
    static let kCommonServiceUUID = CBUUID(string: "00000000-0001-11E1-9AB4-0002A5D5C51B")
    
    static let AdvertisementName = "SensiBLE/SensBLE/SIM-BS1/AM1V300"    
    static let DeviceTypeName = "simba-pro"
    
    // SensiBLE SimbaPRO device from time to time advertises itself as SIM-BS1 or SensiBLE or SensBLE or AM1V300
    override var lookupName: String? {
        return SimbaPro.AdvertisementName
    }
    
    override var deviceName: String {
        return deviceType.rawValue
    }
    
    override var deviceTypeName: String {
        return SimbaPro.DeviceTypeName
    }
    
    // cloud name should always be SIMBA-PRO
    override var cloudName: String? {
        get { return deviceType.rawValue }
        set { }
    }
    
    // returns true if advertising name is valid for simba-pro device
    static func isValidAdvertisingName(_ advName: String) -> Bool {
        let name = advName.lowercased()        
        return name.hasPrefix("sensble") || name.hasPrefix("sensible") || name.hasPrefix("sim-bs1") || name.hasPrefix("am1v300")
    }
    
    init() {
        super.init(.SimbaPro)
        
        deviceTelemetry = [
            Telemetry(type: SensorType.light, label: "Light"),
            Telemetry(type: SensorType.temperature, label: "Temperature"),
            Telemetry(type: SensorType.humidity, label: "Humidity"),
            Telemetry(type: SensorType.pressure, label: "Pressure"),
            Telemetry(type: SensorType.micLevel, label: "Mic Level"),
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
        
        deviceProperties = SimbaProProperties.sharedInstance
        deviceProperties?.reload()
    }
    
    override func createSensors(_ service: CBService)
    {
        if service.uuid == SimbaPro.kCommonServiceUUID {
            createDeviceSensors(service)
        }
        else {
            super.createSensors(service)
        }
    }
    
    func createDeviceSensors(_ service: CBService) {
        
        guard let chars = service.characteristics else {
            print("SymbaPro - CreateDeviceSensors() - can not get chars for serivice \(service)")
            return
        }
       
        for char in chars {
            var sensor: BleSensorProtocol?
            switch char.uuid
            {
            case EnvironmentSensor.SensorUUID:
                sensor = SimbaPro.EnvironmentSensor(service)
                
            case MovementSensor.SensorUUID:
                sensor = SimbaPro.MovementSensor(service)

            case MicLevelSensor.SensorUUID:
                sensor = SimbaPro.MicLevelSensor(service)

            case HumiditySensor.SensorUUID:
                sensor = SimbaPro.HumiditySensor(service)

            case TemperatureSensor.SensorUUID:
                sensor = SimbaPro.TemperatureSensor(service)

            case PressureSensor.SensorUUID:
                sensor = SimbaPro.PressureSensor(service)

            case AmbientLightSensor.SensorUUID:
                sensor = SimbaPro.AmbientLightSensor(service)

            default:
                break
            }

            if sensor != nil {
                sensorMap[char.uuid] = sensor
            }
        }        
    }
}
