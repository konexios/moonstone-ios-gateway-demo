//
//  Thunderboard.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 26/07/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreBluetooth
import AcnSDK

class ThunderboardLEDService {
    
    static let DigitalUUID = CBUUID(string: "0x2A56")
    
    private var ledMask: UInt8 = 0
    private let digitalBits    = 2
    
    var service: CBService
    var characteristic: CBCharacteristic?
    
    init(service: CBService) {
        self.service = service
        
        for char in service.characteristics! {
            switch char.uuid {
            case ThunderboardLEDService.DigitalUUID:
                characteristic = char
                break
            default:
                break
            }
        }
    }
    
    func setLed(led: UInt, on: Bool) {
        
        let shift = led * UInt(digitalBits)
        var mask = ledMask
        
        if on {
            mask = mask | UInt8(1 << shift)
        }
        else {
            mask = mask & ~UInt8(1 << shift)
        }
        
        let data = NSData(bytes: [mask], length: 1)
        DispatchQueue.global().async {
            BleUtils.sharedInstance.writeCharacteristic(peripheral: self.service.peripheral, characteristic: self.characteristic!, data: data, timeOutInSec: 5)
        }
        
        ledMask = mask
    }
    
    func isLedOn(led: UInt) -> Bool {
        return isDigitalHigh(mask: ledMask, index: led)
    }
    
    private func isDigitalHigh(mask: UInt8, index: UInt) -> Bool {
        let shift = index * UInt(digitalBits)
        let isOn = (mask & UInt8(1 << shift)) != 0
        return isOn
    }
}

class Thunderboard: BleDevice {
    
    static let EnvironmentalSensingUUID = CBUUID(string: "0x181A")
    static let InertialMeasurementUUID  = CBUUID(string: "A4E649F4-4BE5-11E5-885D-FEFF819CDC9F")
    static let AmbientLightServiceUUID  = CBUUID(string: "D24C4F4E-17A7-4548-852C-ABF51127368B")
    static let AutomationIOServiceUUID  = CBUUID(string: "0x1815")
    
    static let DeviceInformationServiceUUID = CBUUID(string: "0x180A")
    static let SystemIdentifierUUID         = CBUUID(string: "0x2A23")
    
    var ledService: ThunderboardLEDService?
    
    var thunderboardId: String?
    
    override var deviceUid: String? {
        return thunderboardId
    }
    
    override var deviceName: String {
        return "Thunder React"
    }
    
    override var deviceTypeName: String {
        return "silabs-thunderboard-react"
    }
    
    init() {
        super.init(DeviceType.ThunderboardReact)
        
        deviceTelemetry = [
            Telemetry(type: SensorType.temperature, label: "Temperature"),
            Telemetry(type: SensorType.humidity, label: "Humidity"),
            Telemetry(type: SensorType.light, label: "Light"),
            Telemetry(type: SensorType.uv, label: "UV"),
            Telemetry(type: SensorType.accelerometerX, label: "Accelerometer"),
            Telemetry(type: SensorType.accelerometerY, label: ""),
            Telemetry(type: SensorType.accelerometerZ, label: ""),
            Telemetry(type: SensorType.orientationAlpha, label: "Orientation"),
            Telemetry(type: SensorType.orientationBeta, label: ""),
            Telemetry(type: SensorType.orientationGamma, label: ""),
            Telemetry(type: SensorType.led1Status, label: "Led 1"),
            Telemetry(type: SensorType.led2Status, label: "Led 2"),
        ]
        
        deviceProperties = ThunderboardProperties.sharedInstance
        deviceProperties?.reload()
    }
    
    override func createSensors(_ service: CBService) {
        
        switch service.uuid {
        case Thunderboard.EnvironmentalSensingUUID:
            createEnvironmentalSensors(service: service)
            break
        case Thunderboard.InertialMeasurementUUID:
            createInertialMeasurementSensors(service: service)
            break
        case Thunderboard.AmbientLightServiceUUID:
            createAmbientLightSensor(service: service)
            break
        case Thunderboard.AutomationIOServiceUUID:
            ledService = ThunderboardLEDService(service: service)
            processLedsStatusData()
            break
        case Thunderboard.DeviceInformationServiceUUID:
            for char in service.characteristics! {
                if char.uuid == Thunderboard.SystemIdentifierUUID {
                    BleUtils.sharedInstance.readValueForCharacteristic(characteristic: char)
                }
            }
        default:
            break
        }
    }
    
    func createEnvironmentalSensors(service: CBService)
    {
        guard let chars = service.characteristics else {
            print("Thunderboard() createSensors - service chars is nil")
            return
        }
        
        for char in chars {
            var sensor: BleSensorProtocol?
            switch char.uuid {
            case HumiditySensor.SensorUUID:
                sensor = Thunderboard.HumiditySensor(char: char)
                break
            case TemperatureSensor.SensorUUID:
                sensor = Thunderboard.TemperatureSensor(char: char)
                break
            case UVSensor.SensorUUID:
                sensor = Thunderboard.UVSensor(char: char)
                break
            default:
                break
            }
            
            if sensor != nil {
                sensorMap[char.uuid] = sensor
            }
        }
    }
    
    func createInertialMeasurementSensors(service: CBService)
    {
        guard let chars = service.characteristics else {
            print("Thunderboard() createSensors - service chars is nil")
            return
        }
        
        for char in chars {
            var sensor: BleSensorProtocol?
            switch char.uuid {
            case AccelerometerSensor.SensorUUID:
                sensor = Thunderboard.AccelerometerSensor(service)
                break
            case OrientationSensor.SensorUUID:
                sensor = Thunderboard.OrientationSensor(service)
                break
            default:
                break
            }
            
            if sensor != nil {
                sensorMap[char.uuid] = sensor
            }
        }
    }
    
    func createAmbientLightSensor(service: CBService)
    {        
        guard let chars = service.characteristics else {
            print("Thunderboard() createSensors - service chars is nil")
            return
        }

        for char in chars {
            var sensor: BleSensorProtocol?
            switch char.uuid {
            case AmbientLightSensor.SensorUUID:
                sensor = Thunderboard.AmbientLightSensor(char: char)
                break
            default:
                break
            }
            
            if sensor != nil {
                sensorMap[char.uuid] = sensor
            }
        }
    }
    
    func toggleLed(led: UInt) {
        if ledService != nil {
            let newState = !ledService!.isLedOn(led: led)
            ledService!.setLed(led: led, on: newState)
            processLedsStatusData()
        }
    }
    
    func isLedOn(led: UInt) -> Bool {
        if ledService != nil {
            return ledService!.isLedOn(led: led)
        }
        return false
    }
    
    func processLedsStatusData() {
        if ledService != nil {
            
            let led1 = ledService!.isLedOn(led: 0)
            let led2 = ledService!.isLedOn(led: 1)
            
            let data = LedsStatusData((led1, led2))
            processSensorData(data: data)
            
            if let hid = loadDeviceId() {
                let state = StateModel(states: ["led1status" : led1, "led2status" : led2])
                ArrowConnectIot.sharedInstance.deviceApi.deviceStateUpdate(hid: hid, state: state) { success in }
            }
        }
    }
    
    override func updateStates(states: [String : Any]) {
        if ledService != nil {
            if let led1 = isLedOn(led: 0, states: states) {
                if led1 != ledService!.isLedOn(led: 0) {
                    toggleLed(led: 0)
                }
            }
            
            if let led2 = isLedOn(led: 1, states: states) {
                if led2 != ledService!.isLedOn(led: 1) {
                    toggleLed(led: 1)
                }
            }
        }
        
        super.updateStates(states: states)
    }
    
    private func isLedOn(led: UInt, states: [String : Any]) -> Bool? {
        let key = led == 0 ? "led1status" : "led2status"
        if let dict = states[key] as? [String : Any] {
            return (dict["value"] as? NSString)?.boolValue
        }
        return nil
    }
    
    // MARK: CharChangeDelegate
    
    override func charChanged(char: CBCharacteristic) {
        if char.uuid == Thunderboard.SystemIdentifierUUID, let thunderboardId = getUniqueIdentifier(data: char.value) {
            self.thunderboardId = thunderboardId
            // register device when we've recieved updated device sid
            checkAndRegisterDevice()
        } else {
            super.charChanged(char: char)
        }
    }
    
    private func getUniqueIdentifier(data: Data?) -> String? {
        guard let data = data else {
            print("ThunderboardReact() - Can not get Unique identifier")
            return nil
        }
        
        var value: UInt64 = 0
        (data as NSData).getBytes(&value, length: 8)
        let uniqueIdentifier = value.bigEndian & 0xFFFFFF
        return "thunderboard-\(uniqueIdentifier)"
    }
    
}
