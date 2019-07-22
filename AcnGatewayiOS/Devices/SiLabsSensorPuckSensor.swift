//
//  SiLabsSensorPuckSensor.swift
//  AcnGatewayiOS
//
//  Created by Tam Nguyen on 2/8/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreBluetooth
import AcnSDK

extension SiLabsSensorPuck {
    
    class SensorPuckData : SensorData<[Double]> {
        
        override init(_ data: [Double]) {
            super.init(data)
        }
        
        override func writeIot() -> [IotParameter] {
            var result = [IotParameter]()
            if data[0] != -1 {
                result.append(IotParameter(key: "f|temperature", value: String(format: "%.2f", data[0])))
            }
            if data[1] != -1 {
                result.append(IotParameter(key: "f|humidity", value: String(format: "%.1f", data[1])))
            }
            if data[2] != -1 {
                result.append(IotParameter(key: "f|light", value: String(format: "%.2f", data[2])))
            }
            if data[3] != -1 {
                result.append(IotParameter(key: "i|uvLevel", value: String(UInt(data[3]))))
            }
            if data[4] != -1 && data[4] > 0.0 {
                result.append(IotParameter(key: "i|heartRate", value: String(UInt(data[4]))))
            }
            return result
        }
        
        override func formatDisplay() -> [SensorType: String] {
            var result = [SensorType: String]()
            if data[0] != -1 {
                result[SensorType.ambientTemperature] = String(format: "%.1f\u{00B0}", data[0])
            } else {
                result[SensorType.ambientTemperature] = ""
            }
            if data[1] != -1 {
                result[SensorType.humidity] = String(format: "%.1f%%", data[1])
            } else {
                result[SensorType.humidity] = ""
            }
            if data[2] != -1 {
                result[SensorType.light] = String(format: "%.1f lx", data[2])
            } else {
                result[SensorType.light] = ""
            }
            if data[3] != -1 {
                result[SensorType.uv] = String(format: "%d", UInt(data[3]))
            } else {
                result[SensorType.uv] = ""
            }
            if data[4] != -1 && data[4] > 0.0 {
                result[SensorType.heartRate] = String(format: "%d", UInt(data[4]))
            } else {
                result[SensorType.heartRate] = ""
            }
            return result
        }
    }
}
