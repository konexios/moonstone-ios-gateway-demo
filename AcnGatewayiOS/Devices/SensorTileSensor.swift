//
//  SensorTileSensor.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 31/08/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreBluetooth
import AcnSDK

extension SensorTile {
    
    class EnvironmentData: SensorData<[Double]> {
        
        var pressure : Double
        var humidity : Double
        var surfaceTemperature : Double
        var ambientTemperature : Double
        
        override init(_ data: [Double]) {
            pressure = data[0]
            humidity = data[1]
            surfaceTemperature = data[2] * 9.0 / 5.0 + 32
            ambientTemperature = data[3] * 9.0 / 5.0 + 32
            
            super.init(data)
        }
        
        override func writeIot() -> [IotParameter] {
            return [
                IotParameter(key: "f|pressure",           value: String(format: "%.2f", pressure)),
                IotParameter(key: "f|humidity",           value: String(format: "%.2f", humidity)),
                IotParameter(key: "f|surfaceTemperature", value: String(format: "%.2f", surfaceTemperature)),
                IotParameter(key: "f|ambientTemperature", value: String(format: "%.2f", ambientTemperature)),
            ]
        }
        
        override func formatDisplay() -> [SensorType: String] {
            return [                
                SensorType.ambientTemperature: String(format: "%.1f \u{00B0}F", ambientTemperature),
                SensorType.surfaceTemperature: String(format: "%.1f \u{00B0}F", surfaceTemperature),
                SensorType.humidity:           String(format: "%.1f %%", humidity),
                SensorType.pressure:           String(format: "%.1f mBar", pressure),
            ]
        }        
    }
    
    class EnvironmentSensor : BleSensor<EnvironmentData> {
        
        static let SensorUUID = CBUUID(string: "001D0000-0001-11E1-AC36-0002A5D5C51B")
        
        let Scale = 10.0
        let PressureScale = 100.0
        
        override init(_ service: CBService) {
            super.init(service)
        }
        
        override var name: String {
            return "EnvironmentSensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "001D0000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override var configUUID: CBUUID {
            return CBUUID(string: "001D0000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override var periodUUID: CBUUID {
            return CBUUID(string: "001D0000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            
            let pressure = Double(BleUtils.readInt32(data: data as NSData, loc: 2).littleEndian) / PressureScale
            let humidity = Double(BleUtils.readInt16(data: data as NSData, loc: 6).littleEndian) / Scale
            let surfaceTemperature = Double(BleUtils.readInt16(data: data as NSData, loc: 8).littleEndian) / Scale
            let ambientTemperature = Double(BleUtils.readInt16(data: data as NSData, loc: 10).littleEndian) / Scale
            
            return EnvironmentData([pressure, humidity, surfaceTemperature, ambientTemperature])
        }
    }
    
    class MovementSensor : BleSensor<MovementData> {
        
        static let SensorUUID = CBUUID(string: "00E00000-0001-11E1-AC36-0002A5D5C51B")
        
        override init(_ service: CBService) {
            super.init(service)
        }
        
        override var name: String {
            return "MovementSensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "00E00000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override var configUUID: CBUUID {
            return CBUUID(string: "00E00000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override var periodUUID: CBUUID {
            return CBUUID(string: "00E00000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            return MovementData(Movement(acc: readAcc(data), gyro: readGyro(data), mag: readMag(data)))
        }
        
        fileprivate func readAcc(_ data: Data) -> Vector {
            let x = Double(BleUtils.readInt16(data: data as NSData, loc: 2).littleEndian)
            let y = Double(BleUtils.readInt16(data: data as NSData, loc: 4).littleEndian)
            let z = Double(BleUtils.readInt16(data: data as NSData, loc: 6).littleEndian)
            return Vector(x: x, y: y, z: z)
        }
        
        fileprivate func readGyro(_ data: Data) -> Vector {
            let x = Double(BleUtils.readInt16(data: data as NSData, loc: 8).littleEndian)
            let y = Double(BleUtils.readInt16(data: data as NSData, loc: 10).littleEndian)
            let z = Double(BleUtils.readInt16(data: data as NSData, loc: 12).littleEndian)
            return Vector(x: x, y: y, z: z)
        }
        
        fileprivate func readMag(_ data: Data) -> Vector {
            let x = Double(BleUtils.readInt16(data: data as NSData, loc: 14).littleEndian)
            let y = Double(BleUtils.readInt16(data: data as NSData, loc: 16).littleEndian)
            let z = Double(BleUtils.readInt16(data: data as NSData, loc: 18).littleEndian)
            return Vector(x: x, y: y, z: z)
        }

    }
    
    class MicLevelSensor : BleSensor<MicLevelData> {
        
        static let SensorUUID = CBUUID(string: "04000000-0001-11E1-AC36-0002A5D5C51B")
        
        override init(_ service: CBService) {
            super.init(service)
        }
        
        override var name: String {
            return "MicLevelSensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "04000000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override var configUUID: CBUUID {
            return CBUUID(string: "04000000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override var periodUUID: CBUUID {
            return CBUUID(string: "04000000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            let level = Double(BleUtils.readInt8(data: data as NSData, loc: 2))
            return MicLevelData(level)
        }
    }
    
    class SwitchSensor : BleSensor<SwitchData> {
        
        static let SensorUUID = CBUUID(string: "20000000-0001-11E1-AC36-0002A5D5C51B")
        
        override init(_ service: CBService) {
            super.init(service)
        }
        
        override var name: String {
            return "SwitchSensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "20000000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override var configUUID: CBUUID {
            return CBUUID(string: "20000000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override var periodUUID: CBUUID {
            return CBUUID(string: "20000000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            let status = Int(BleUtils.readInt8(data: data as NSData, loc: 2))
            return SwitchData(status)
        }
    }
    
}
