//
//  ThunderboardSensor.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 27/07/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreBluetooth

extension Thunderboard {   
    
    class HumiditySensor : BlePollingSensor<HumidityData> {
        
        static let SensorUUID = CBUUID(string: "0x2A6F")
        
        override init(char: CBCharacteristic) {
            super.init(char: char)
        }
        
        override var name: String {
            return "HumiditySensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "0x2A6F")
        }
        
        override var configUUID: CBUUID {
            return CBUUID(string: "0x2A6F")
        }
        
        override var periodUUID: CBUUID {
            return CBUUID(string: "0x2A6F")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            var result: Double = Double(BleUtils.readInt16(data: data as NSData, loc: 0))
            result = result * 0.01
            return HumidityData(result)
        }
    }
    
    class TemperatureSensor : BlePollingSensor<TemperatureData> {
        
        static let SensorUUID = CBUUID(string: "0x2A6E")
        
        override init(char: CBCharacteristic) {
            super.init(char: char)
        }
        
        override var name: String {
            return "TemperatureSensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "0x2A6E")
        }
        
        override var configUUID: CBUUID {
            return CBUUID(string: "0x2A6E")
        }
        
        override var periodUUID: CBUUID {
            return CBUUID(string: "0x2A6E")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            var result: Double = Double(BleUtils.readInt16(data: data as NSData, loc: 0))
            result = result * 0.01
            result = (result * 9.0 / 5.0) + 32.0            
            return TemperatureData(result)
        }
    }
    
    class UVSensor : BlePollingSensor<UvData> {
        
        static let SensorUUID = CBUUID(string: "0x2A76")
        
        override init(char: CBCharacteristic) {
            super.init(char: char)
        }
        
        override var name: String {
            return "UVSensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "0x2A76")
        }
        
        override var configUUID: CBUUID {
            return CBUUID(string: "0x2A76")
        }
        
        override var periodUUID: CBUUID {
            return CBUUID(string: "0x2A76")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            let result: Double = Double(BleUtils.readInt8(data: data as NSData, loc: 0))
            return UvData(result)
        }
    }
    
    class AmbientLightSensor : BlePollingSensor<LightData> {
        
        static let SensorUUID = CBUUID(string: "C8546913-BFD9-45EB-8DDE-9F8754F4A32E")
        
        override init(char: CBCharacteristic) {
            super.init(char: char)
        }
        
        override var name: String {
            return "AmbientLightSensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "C8546913-BFD9-45EB-8DDE-9F8754F4A32E")
        }
        
        override var configUUID: CBUUID {
            return CBUUID(string: "C8546913-BFD9-45EB-8DDE-9F8754F4A32E")
        }
        
        override var periodUUID: CBUUID {
            return CBUUID(string: "C8546913-BFD9-45EB-8DDE-9F8754F4A32E")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            var result: Double = Double(BleUtils.readInt32(data: data as NSData, loc: 0))
            result = result * 0.01
            return LightData(result)
        }
    }
    
    class AccelerometerSensor : BleSensor<AccelerometerData> {

        static let SensorUUID = CBUUID(string: "C4C1F6E2-4BE5-11E5-885D-FEFF819CDC9F")
        
        override init(_ service: CBService) {
            super.init(service)
        }
        
        override var name: String {
            return "AccelerometerSensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "C4C1F6E2-4BE5-11E5-885D-FEFF819CDC9F")
        }
        
        override var configUUID: CBUUID {
            return CBUUID(string: "C4C1F6E2-4BE5-11E5-885D-FEFF819CDC9F")
        }
        
        override var periodUUID: CBUUID {
            return CBUUID(string: "C4C1F6E2-4BE5-11E5-885D-FEFF819CDC9F")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            
            let x = Double(BleUtils.readInt16(data: data as NSData, loc: 0))
            let y = Double(BleUtils.readInt16(data: data as NSData, loc: 2))
            let z = Double(BleUtils.readInt16(data: data as NSData, loc: 4))

            return AccelerometerData(Vector(x: x / 1000.0, y: y / 1000.0, z: z / 1000.0))
        }

    }
    
    class OrientationSensor : BleSensor<OrientationData> {
        
        static let SensorUUID = CBUUID(string: "B7C4B694-BEE3-45DD-BA9F-F3B5E994F49A")
        
        override init(_ service: CBService) {
            super.init(service)
        }
        
        override var name: String {
            return "OrientationSensor"
        }
        
        override var dataUUID: CBUUID {
            return CBUUID(string: "B7C4B694-BEE3-45DD-BA9F-F3B5E994F49A")
        }
        
        override var configUUID: CBUUID {
            return CBUUID(string: "B7C4B694-BEE3-45DD-BA9F-F3B5E994F49A")
        }
        
        override var periodUUID: CBUUID {
            return CBUUID(string: "B7C4B694-BEE3-45DD-BA9F-F3B5E994F49A")
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            
            let alpha = Double(BleUtils.readInt16(data: data as NSData, loc: 0))
            let beta  = Double(BleUtils.readInt16(data: data as NSData, loc: 2))
            let gamma = Double(BleUtils.readInt16(data: data as NSData, loc: 4))
            
            return OrientationData(Vector(x: alpha / 100.0, y: beta / 100.0, z: gamma / 100.0))
        }
    }
    
}
