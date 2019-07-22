//
//  OnSemiRSL10Sensor.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import Foundation
import CoreBluetooth
import AcnSDK

extension OnSemiRSL10 {
    
    /// Poolling sensor - lux
    class LightSensor: BlePollingSensor<LightData> {
        
        static let SensorUUID = CBUUID(string: "E093F3B5-00A3-A9E5-9ECA-40036E0EDC24")
        
        override var name: String {
            return "LightSensor"
        }
        
        override var dataUUID: CBUUID {
            return LightSensor.SensorUUID
        }
        
        override var configUUID: CBUUID {
            return LightSensor.SensorUUID
        }
        
        override var periodUUID: CBUUID {
            return LightSensor.SensorUUID
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            return LightData( Double(BleUtils.readFloat32BigEndian(data: data)) )
        }
    }
    
    /// Passive InfraRed sensor - Movement Detector
    class PirSensor: BleSensor<PirData> {
        static let SensorUUID = CBUUID(string: "E093F3B5-00A3-A9E5-9ECA-40046E0EDC24")
        
        override var name: String {
            return "Movement Detector"
        }
        
        override var dataUUID: CBUUID {
            return PirSensor.SensorUUID
        }
        
        override var configUUID: CBUUID {
            return PirSensor.SensorUUID
        }
        
        override var periodUUID: CBUUID {
            return PirSensor.SensorUUID
        }
        
        override func parse(data: Data) -> SensorDataProtocol {
            return PirData( Int(BleUtils.readInt8(data: data as NSData, loc: 0)) )
        }
    }
}
