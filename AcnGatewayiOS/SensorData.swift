//
//  BleSensor.swift
//  AcnGatewayiOS
//
//  Created by Tam Nguyen on 10/2/15.
//  Copyright © 2015 Arrow Electronics. All rights reserved.
//

import Foundation
import AcnSDK

struct Vector {
    var x, y, z : Double
    
    init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }
}

struct Movement {
    var acc, gyro, mag : Vector
    
    init(acc: Vector, gyro: Vector, mag: Vector) {
        self.acc = acc
        self.gyro = gyro
        self.mag = mag
    }
}

protocol SensorDataProtocol {
    func writeIot() -> [IotParameter]
    func formatDisplay() -> [SensorType: String]
}

class SensorData<Type> : SensorDataProtocol {
    var data: Type
    
    init(_ data: Type) {
        self.data = data
    }
    
    func writeIot() -> [IotParameter] {
        preconditionFailure("abstract method!")
    }
    
    func formatDisplay() -> [SensorType: String] {
        preconditionFailure("abstract method!")
    }
}

class HeartRateData : SensorData<UInt> {

    override init(_ data: UInt) {
        super.init(data)
    }

    override func writeIot() -> [IotParameter] {
        return [IotParameter(key: "i|heartRate", value: String(data))]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        //return [SensorType.HeartRate: String(format: "%d bpm", data)]
        return [SensorType.heartRate: String(format: "%d", data)]
    }
}

class PedometerData : SensorData<Int64> {
    
    override init(_ data: Int64) {
        super.init(data)
    }

    override func writeIot() -> [IotParameter] {
        return [IotParameter(key: "i|pedometer", value: String(data))]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        return [SensorType.pedometer: String(format: "%d steps", data)]
    }
}

class DistanceData : SensorData<Int64> {
    
    override init(_ data: Int64) {
        super.init(data)
    }
    
    override func writeIot() -> [IotParameter] {
        return [IotParameter(key: "i|distance", value: String(data))]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        return [SensorType.distance: String(format: "%d ft", data)]
    }
}

class UvLevelData : SensorData<String> {

    override init(_ data: String) {
        super.init(data)
    }

    override func writeIot() -> [IotParameter] {
        return [IotParameter(key: "s|uvLevel", value: data)]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        return [SensorType.uv: data]
    }
}

class UvData : SensorData<Double> {
    
    override init(_ data: Double) {
        super.init(data)
    }
    
    override func writeIot() -> [IotParameter] {
        return [IotParameter(key: "f|uvLevel", value: String(format: "%.1f", data))]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        return [SensorType.uv: String(format: "%.1f", data)]
    }
}

class BarometerData : SensorData<Double> {
    
    override init(_ data: Double) {
        super.init(data)
    }

    override func writeIot() -> [IotParameter] {
        return [IotParameter(key: "f|barometer", value: String(format: "%.2f", data))]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        //return [SensorType.Barometer: String(format: "%.1f mbar", data)]
        return [SensorType.barometer: String(format: "%.1f mBar", data)]
    }
}

class PressureData : SensorData<Double> {
    
    override init(_ data: Double) {
        super.init(data)
    }
    
    override func writeIot() -> [IotParameter] {
        return [IotParameter(key: "f|pressure", value: String(format: "%.2f", data))]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        return [SensorType.pressure: String(format: "%.1f mBar", data)]
        //return [SensorType.pressure: String(format: "%.1f", data)]
    }
}

class TemperatureData : SensorData<Double> {
    
    override init(_ data: Double) {
        super.init(data)
    }
    
    override func writeIot() -> [IotParameter] {
        return [IotParameter(key: "f|temperature", value: String(format: "%.2f", data))]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        return [SensorType.temperature: String(format: "%.1f \u{2109}", data)]
        //return [SensorType.temperature: String(format: "%.1f", data)]
    }
}

class SkinTemperatureData : SensorData<Double> {
    
    override init(_ data: Double) {
        super.init(data)
    }
    
    override func writeIot() -> [IotParameter] {
        return [IotParameter(key: "f|skinTemperature", value: String(format: "%.2f", data))]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        return [SensorType.skinTemperature: String(format: "%.1f \u{00B0}", data)]
    }
}

class HumidityData : SensorData<Double> {
    
    override init(_ data: Double) {
        super.init(data)
    }

    override func writeIot() -> [IotParameter] {
        return [IotParameter(key: "f|humidity", value: String(format: "%.2f", data))]
    }

    override func formatDisplay() -> [SensorType: String] {
        //return [SensorType.Humidity: String(format: "%.1f%% RH", data)]
        return [SensorType.humidity: String(format: "%.1f %%", data)]
    }
}

/// Passive InfraRed data
/// this data is using for movement detection
/// when value is 1 - movement detected, when 0 - movement ended
class PirData: SensorData<Int> {
    override func writeIot() -> [IotParameter] {
        return [IotParameter(key:"i|pir", value: String(data))]
    }
    
    override func formatDisplay() -> [SensorType : String] {
        return [SensorType.pir: String(format:"%d", data)]
    }
}

class LightData : SensorData<Double> {
    
    override init(_ data: Double) {
        super.init(data)
    }

    override func writeIot() -> [IotParameter] {
        return [IotParameter(key: "f|light", value: String(format: "%.2f", data))]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        return [SensorType.light: String(format: "%.1f lx", data)]
    }
}

class MicLevelData : SensorData<Double> {
    
    override init(_ data: Double) {
        super.init(data)
    }
    
    override func writeIot() -> [IotParameter] {
        return [IotParameter(key: "f|micLevel", value: String(format: "%.1f", data))]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        return [SensorType.micLevel: String(format: "%.1f db", data)]
    }
}

class SwitchData : SensorData<Int> {
    
    override init(_ data: Int) {
        super.init(data)
    }
    
    override func writeIot() -> [IotParameter] {
        return [IotParameter(key: "i|switch", value: String(data))]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        return [SensorType.switchStatus: String(format: "%d", data)]
    }
}

class LedsStatusData : SensorData<(Bool, Bool)> {
    
    override init(_ data: (Bool, Bool)) {
        super.init(data)
    }
    
    override func writeIot() -> [IotParameter] {
        return [
            IotParameter(key: "b|led1status", value: String(format: "%@", String(data.0))),
            IotParameter(key: "b|led2status", value: String(format: "%@", String(data.1)))
        ]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        return [
            SensorType.led1Status: String(format: "%@", String(data.0)),
            SensorType.led2Status: String(format: "%@", String(data.1))
        ]
    }
}

class AccelerometerData : SensorData<Vector> {
    
    override init(_ data: Vector) {
        super.init(data)
    }

    override func writeIot() -> [IotParameter] {
        return [
            IotParameter(key: "f|accelerometerX", value: String(format: "%.9f", data.x)),
            IotParameter(key: "f|accelerometerY", value: String(format: "%.9f", data.y)),
            IotParameter(key: "f|accelerometerZ", value: String(format: "%.9f", data.z)),
            IotParameter(key: "f3|accelerometerXYZ", value: String(format: "%.9f|%.9f|%.9f", data.x, data.y, data.z))]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        return [
            SensorType.accelerometerX: String(format: "%.9f m/s\u{00B2}", data.x),
            SensorType.accelerometerY: String(format: "%.9f m/s\u{00B2}", data.y),
            SensorType.accelerometerZ: String(format: "%.9f m/s\u{00B2}", data.z)]
    }
}

class GyroscopeData : SensorData<Vector> {
    
    override init(_ data: Vector) {
        super.init(data)
    }

    override func writeIot() -> [IotParameter] {
        return [
            IotParameter(key: "f|gyrometerX", value: String(format: "%.9f", data.x)),
            IotParameter(key: "f|gyrometerY", value: String(format: "%.9f", data.y)),
            IotParameter(key: "f|gyrometerZ", value: String(format: "%.9f", data.z)),
            IotParameter(key: "f3|gyrometerXYZ", value: String(format: "%.9f|%.9f|%.9f", data.x, data.y, data.z)),
            IotParameter(key: "f2|GyroXY", value: String(format: "%.9f|%.9f", data.x, data.y))]
    }

    override func formatDisplay() -> [SensorType: String] {
        return [
            SensorType.gyroscopeX: String(format: "%.9f \u{00B0}/s", data.x),
            SensorType.gyroscopeY: String(format: "%.9f \u{00B0}/s", data.y),
            SensorType.gyroscopeZ: String(format: "%.9f \u{00B0}/s", data.z)]
    }
}

class MagnetometerData : SensorData<Vector> {
    
    override init(_ data: Vector) {
        super.init(data)
    }

    override func writeIot() -> [IotParameter] {
        return [
            IotParameter(key: "f|magnetometerX", value: String(format: "%.9f", data.x)),
            IotParameter(key: "f|magnetometerY", value: String(format: "%.9f", data.y)),
            IotParameter(key: "f|magnetometerZ", value: String(format: "%.9f", data.z)),
            IotParameter(key: "f3|magnetometerXYZ", value: String(format: "%.9f|%.9f|%.9f", data.x, data.y, data.z))]
    }

    override func formatDisplay() -> [SensorType: String] {
        return [
            SensorType.magnetometerX: String(format: "%.9f uT", data.x),
            SensorType.magnetometerY: String(format: "%.9f uT", data.y),
            SensorType.magnetometerZ: String(format: "%.9f uT", data.z)]
    }
}

class OrientationData: SensorData<Vector> {
    
    override init(_ data: Vector) {
        super.init(data)
    }

    override func writeIot() -> [IotParameter] {
        return [
            IotParameter(key: "f|orientationAlpha", value: String(format: "%.2f", data.x)),
            IotParameter(key: "f|orientationBeta", value: String(format: "%.2f", data.y)),
            IotParameter(key: "f|orientationGamma", value: String(format: "%.2f", data.z)),
            IotParameter(key: "f3|orientationABG", value: String(format: "%.2f|%.2f|%.2f", data.x, data.y, data.z))]
    }
    
    override func formatDisplay() -> [SensorType: String] {
        return [
            SensorType.orientationAlpha: String(format: "%.2f\u{00B0}", data.x),
            SensorType.orientationBeta: String(format: "%.2f\u{00B0}", data.y),
            SensorType.orientationGamma: String(format: "%.2f\u{00B0}", data.z)]
    }
}

class MovementData : SensorData<Movement> {
    
    override init(_ data: Movement) {
        super.init(data)
    }

    override func writeIot() -> [IotParameter] {
        return [
            IotParameter(key: "f|accelerometerX", value: String(format: "%.9f", data.acc.x)),
            IotParameter(key: "f|accelerometerY", value: String(format: "%.9f", data.acc.y)),
            IotParameter(key: "f|accelerometerZ", value: String(format: "%.9f", data.acc.z)),
            IotParameter(key: "f3|accelerometerXYZ", value: String(format: "%.9f|%.9f|%.9f", data.acc.x, data.acc.y, data.acc.z)),
            IotParameter(key: "f|gyrometerX", value: String(format: "%.9f", data.gyro.x)),
            IotParameter(key: "f|gyrometerY", value: String(format: "%.9f", data.gyro.y)),
            IotParameter(key: "f|gyrometerZ", value: String(format: "%.9f", data.gyro.z)),
            IotParameter(key: "f3|gyrometerXYZ", value: String(format: "%.9f|%.9f|%.9f", data.gyro.x, data.gyro.y, data.gyro.z)),
            IotParameter(key: "f|magnetometerX", value: String(format: "%.9f", data.mag.x)),
            IotParameter(key: "f|magnetometerY", value: String(format: "%.9f", data.mag.y)),
            IotParameter(key: "f|magnetometerZ", value: String(format: "%.9f", data.mag.z)),
            IotParameter(key: "f3|magnetometerXYZ", value: String(format: "%.9f|%.9f|%.9f", data.mag.x, data.mag.y, data.mag.z))]
    }

    override func formatDisplay() -> [SensorType: String] {
        return [
            SensorType.accelerometerX: String(format: "%.9f m/s\u{00B2}", data.acc.x),
            SensorType.accelerometerY: String(format: "%.9f m/s\u{00B2}", data.acc.y),
            SensorType.accelerometerZ: String(format: "%.9f m/s\u{00B2}", data.acc.z),
            SensorType.gyroscopeX: String(format: "%.9f \u{00B0}/s", data.gyro.x),
            SensorType.gyroscopeY: String(format: "%.9f \u{00B0}/s", data.gyro.y),
            SensorType.gyroscopeZ: String(format: "%.9f \u{00B0}/s", data.gyro.z),
            SensorType.magnetometerX: String(format: "%.9f uT", data.mag.x),
            SensorType.magnetometerY: String(format: "%.9f uT", data.mag.y),
            SensorType.magnetometerZ: String(format: "%.9f uT", data.mag.z)]
    }
}
