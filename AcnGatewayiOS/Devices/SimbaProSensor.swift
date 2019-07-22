//
//  SimbaProSensor.swift
//  AcnGatewayiOS
//
//  Created by Alexey Chechetkin on 22/12/2017.
//  Copyright © 2017 Arrow Electronics, Inc. All rights reserved.
//

import Foundation
import CoreBluetooth
import AcnSDK

extension SimbaPro {
    
    // MARK: Sesnsors' data
    
    // Since FW 3.0, all environment data was
    // encapsulated in one service characteristic 
    class EnvironmentData: SensorData<[Double]> {
        
        var pressure : Double
        var humidity : Double
        var temperature : Double
        
        init(pressure:Double, humidity:Double, temperature:Double) {
            self.pressure = pressure
            self.humidity = humidity
            self.temperature = temperature * 9.0 / 5.0 + 32 // F
            
            super.init([pressure, humidity, temperature])
        }
        
        override func writeIot() -> [IotParameter] {
            return [
                IotParameter(key: "f|pressure",    value: String(format: "%.2f", pressure)),
                IotParameter(key: "f|humidity",    value: String(format: "%.2f", humidity)),
                IotParameter(key: "f|temperature", value: String(format: "%.2f", temperature))
            ]
        }
        
        override func formatDisplay() -> [SensorType: String] {
            return [
                SensorType.temperature: String(format: "%.1f \u{00B0}F", temperature),
                SensorType.humidity:           String(format: "%.1f %%", humidity),
                SensorType.pressure:           String(format: "%.1f mBar", pressure)
            ]
        }
    }
    
    // MARK: Sensors
    
    class EnvironmentSensor : BleSensor<EnvironmentData> {
        
        static let SensorUUID = CBUUID(string: "001C0000-0001-11E1-AC36-0002A5D5C51B")
        
        let HumidityScale = 10.0
        let PressureScale = 100.0
        let TemperatureScale = 10.0
        
        override init(_ service: CBService) {
            super.init(service)
        }
        
        override var name: String {
            return "EnvironmentSensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "001C0000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override var configUUID: CBUUID {
            return CBUUID(string: "001C0000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override var periodUUID: CBUUID {
            return CBUUID(string: "001C0000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            
            let pressure = Double(BleUtils.readInt32(data: data as NSData, loc: 2).littleEndian) / PressureScale
            let humidity = Double(BleUtils.readInt16(data: data as NSData, loc: 6).littleEndian) / HumidityScale
            let temperature = Double(BleUtils.readInt16(data: data as NSData, loc: 8).littleEndian) / TemperatureScale
            
            return EnvironmentData(pressure: pressure, humidity: humidity, temperature: temperature)
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
            let x = Double(BleUtils.readInt16(data: data as NSData, loc: 8).littleEndian) * 0.1
            let y = Double(BleUtils.readInt16(data: data as NSData, loc: 10).littleEndian) * 0.1
            let z = Double(BleUtils.readInt16(data: data as NSData, loc: 12).littleEndian) * 0.1
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
    
    class HumiditySensor : BleSensor<HumidityData> {
        
        static let SensorUUID = CBUUID(string: "00080000-0001-11E1-AC36-0002A5D5C51B")
        
        override init(_ service: CBService) {
            super.init(service)
        }

        override var name: String {
            return "HumiditySensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "00080000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override var configUUID: CBUUID {
            return CBUUID(string: "00080000-0001-11E1-AC36-0002A5D5C51A")
        }
        
        override var periodUUID: CBUUID {
            return CBUUID(string: "00080000-0001-11E1-AC36-0002A5D5C51A")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            var result: Double = Double(BleUtils.readInt16(data: data as NSData, loc: 2))
            result = result * 0.1
            return HumidityData(result)
        }
    }
    
    class TemperatureSensor : BleSensor<TemperatureData> {
        
        static let SensorUUID = CBUUID(string: "00040000-0001-11E1-AC36-0002A5D5C51B")
        
        override init(_ service: CBService) {
            super.init(service)
        }

        override var name: String {
            return "TemperatureSensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "00040000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override var configUUID: CBUUID {
            return CBUUID(string: "00040000-0001-11E1-AC36-0002A5D5C51A")
        }
        
        override var periodUUID: CBUUID {
            return CBUUID(string: "00040000-0001-11E1-AC36-0002A5D5C51A")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            var result: Double = Double(BleUtils.readInt16(data: data as NSData, loc: 2))
            result = result * 0.1
            result = (result * 9.0 / 5.0) + 32.0
            return TemperatureData(result)
        }
    }
    

    class AmbientLightSensor : BleSensor<LightData> {
        
        static let SensorUUID = CBUUID(string: "01000000-0001-11E1-AC36-0002A5D5C51B")
        
        override init(_ service: CBService) {
            super.init(service)
        }

        override var name: String {
            return "AmbientLightSensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "01000000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        
        override var configUUID: CBUUID {
            return CBUUID(string: "01000000-0001-11E1-AC36-0002A5D5C51A")
        }

        override var periodUUID: CBUUID {
            return CBUUID(string: "01000000-0001-11E1-AC36-0002A5D5C51A")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            let result: Double = Double(BleUtils.readInt16(data: data as NSData, loc: 2))
            return LightData(result)
        }
    }
    
    class PressureSensor : BleSensor<BarometerData> {
        
        static let SensorUUID = CBUUID(string: "00100000-0001-11E1-AC36-0002A5D5C51B")
        
        override init(_ service: CBService) {
            super.init(service)
        }

        override var name: String {
            return "PressureSensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "00100000-0001-11E1-AC36-0002A5D5C51B")
        }
        
        override var configUUID: CBUUID {
            return CBUUID(string: "00100000-0001-11E1-AC36-0002A5D5C51A")
        }
        
        override var periodUUID: CBUUID {
            return CBUUID(string: "00100000-0001-11E1-AC36-0002A5D5C51A")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            let result: Double = Double(BleUtils.readInt32(data: data as NSData, loc: 2)) * 0.01
            return PressureData(result)
        }
    }

}
