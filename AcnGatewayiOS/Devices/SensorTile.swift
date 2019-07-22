//
//  SensorTile.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 31/08/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreBluetooth

class SensorTile: STDevice {
    
    static let SensorTileServiceUUID = CBUUID(string: "00000000-0001-11E1-9AB4-0002A5D5C51B")
    
    static let AdvertisementName = "BM2V2"          // actually it is BM2V200
    static let DeviceTypeName = "st-sensortile"
    
    override var deviceName: String {
        return device?.name ?? SensorTile.AdvertisementName
    }
    
    override var deviceTypeName: String {
        return SensorTile.DeviceTypeName
    }
    
    static func isValidAdvertisingName(_ advName: String) -> Bool {
        let name = advName.lowercased()
        return name.hasPrefix( SensorTile.AdvertisementName.lowercased()  )
    }
    
    init() {
        super.init(DeviceType.SensorTile)
        
        deviceTelemetry = [
            Telemetry(type: SensorType.ambientTemperature, label: "Ambient Temperature"),
            Telemetry(type: SensorType.surfaceTemperature, label: "Surface Temperature"),
            Telemetry(type: SensorType.humidity, label: "Humidity"),
            Telemetry(type: SensorType.pressure, label: "Pressure"),
            Telemetry(type: SensorType.micLevel, label: "Mic Level"),
            Telemetry(type: SensorType.switchStatus, label: "Switch"),
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
        
        deviceProperties = SensorTileProperties.sharedInstance
        deviceProperties?.reload()
    }
    
    override func createSensors(_ service: CBService)
    {
        switch service.uuid {
        case SensorTile.SensorTileServiceUUID:
            createSensorTileSensors(service)
            break
        default:
            super.createSensors(service)
        }
    }
    
    func createSensorTileSensors(_ service: CBService) {
        
        guard let chars = service.characteristics else {
            print("SensorTile() createSensors - service chars is nil")
            return
        }

        for char in chars {
            var sensor: BleSensorProtocol?
            switch char.uuid {
            case EnvironmentSensor.SensorUUID:
                sensor = SensorTile.EnvironmentSensor(service)
                break
            case MovementSensor.SensorUUID:
                sensor = SensorTile.MovementSensor(service)
                break
            case MicLevelSensor.SensorUUID:
                sensor = SensorTile.MicLevelSensor(service)
                break
            case SwitchSensor.SensorUUID:
                sensor = SensorTile.SwitchSensor(service)
                break
            default:
                break
            }
            
            if sensor != nil {
                sensorMap[char.uuid] = sensor
            }
        }
    }    
}
