//
//  AcnGatewayiOS
//
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreBluetooth
import AcnSDK

class OnSemiRSL10: BleDevice {
    
    // services UUIDS
    static let TelemetryServiceUUID = CBUUID(string: "E093F3B5-00A3-A9E5-9ECA-40016E0EDC24")
    static let LedServiceUUID       = CBUUID(string: "669A0C20-0008-1A8F-E711-BED9307A52B3")
    static let MotorServiceUUID     = CBUUID(string: "669A0C20-0008-1A8F-E711-6DDAC07892D0")
    static let RotorServiceUUID     = CBUUID(string: "669A0C20-0008-1A8F-E711-6DDAD0F05DE1")
    
    static let AdvertisementName     = "Arrow_BB-GEVK"
    
    static let DeviceTypeName = "onsemi-ble"
    
    override var deviceName: String {
        return deviceType.rawValue
    }
    
    override var deviceTypeName: String {
        return OnSemiRSL10.DeviceTypeName
    }
    
    override var lookupName: String? {
        return OnSemiRSL10.AdvertisementName
    }
    
    static func isValidAdvertisingName(_ advName: String) -> Bool {
        let name = advName.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).lowercased()
        
        return ( name == OnSemiRSL10.AdvertisementName.lowercased() )
    }
    
    /// returns mac address from advertising data, or nil
    /// - Parameter - data - data section from advertisment data
    /// - returns: hex MAC address string with xx:xx:xx:xx:xx:xx or nil
    static func macAddressFromData(_ data: Data) -> String? {
        guard data.count == 10 else {
            return nil
        }
        
        return  String(format: "%02x:%02x:%02x:%02x:%02x:%02x", data[9], data[8], data[7], data[6], data[5], data[4])
    }

    private(set) var ledService: OnSemiRSL10LedService?
    private(set) var motorService: OnSemiRSL10MotorService?
    private(set) var rotorService: OnSemiRSL10RotorService?
    
    init() {
        super.init(DeviceType.OnSemiRSL10)
        
        deviceTelemetry = [
            Telemetry(type: SensorType.light, label: "Light"),
            Telemetry(type: SensorType.pir, label: "Movement Detector")
        ]

        deviceProperties = OnSemiRSL10Properties.sharedInstance
        deviceProperties?.reload()
    }
    
    /// update states for various services in the cloud
    func updateCloudState(_ state: StateModel, serviceName: String = "") {
        guard let hid = loadDeviceId() else {
            print("[OnSemiRSL10] - UpdateCloudState() for \(serviceName), device hid is nil!")
            return
        }
        
        print( "[OnSemiRSL10] - UpdateCloudState() for \(serviceName)..." )
        ArrowConnectIot.sharedInstance.deviceApi.deviceStateUpdate(hid: hid, state: state) { success in
            if !success {
                print("[OnSemiRSL10] - UpdateCloudState() failed to update state for \(serviceName)!")
            }
        }
    }
    
    // update service states gotten from the cloud
    override func updateStates(states: [String : Any]) {
        print("[OnSemiRSL10] - updateStates")
        
        ledService?.updateStates(states: states)
        motorService?.updateStates(states: states)
        rotorService?.updateStates(states: states)
    }
    
    override func disable() {
        super.disable()
        motorService?.stopNotification()
    }
    
    override func createSensors(_ service: CBService) {
        
        switch service.uuid {
        case OnSemiRSL10.TelemetryServiceUUID:
            createTelemetrySensors(service: service)
        
        case OnSemiRSL10.LedServiceUUID:
            ledService = OnSemiRSL10LedService(service: service)
            ledService?.device = self
            ledService?.requestLedValue(0)
            ledService?.requestLedValue(1)
            
        case OnSemiRSL10.MotorServiceUUID:
            motorService = OnSemiRSL10MotorService(service: service)
            motorService?.device = self
            motorService?.requestMotorValue(0)
            motorService?.requestMotorValue(1)
            
        case OnSemiRSL10.RotorServiceUUID:
            rotorService = OnSemiRSL10RotorService(service: service)
            rotorService?.device = self
            rotorService?.requestRotorValue()
            
        default:
            break
        }
    }
    
    func createTelemetrySensors(service: CBService) {
        
        guard let chars = service.characteristics else {
            print("[OnSemiRSL10] - createTelemetrySensors - service chars is nil")
            return
        }
        
        var sensor: BleSensorProtocol?

        for char in chars {
            sensor = nil
            
            switch char.uuid {
            case LightSensor.SensorUUID:
                sensor = OnSemiRSL10.LightSensor(char: char)
                
            case PirSensor.SensorUUID:
                sensor = OnSemiRSL10.PirSensor(service)
                
            default:
                break
            }
            
            if sensor != nil {
                sensorMap[char.uuid] = sensor
            }
        }
    }
    
    // MARK: - BLE char delegate
    
    /// get updates for chars 
    override func charChanged(char: CBCharacteristic) {
        
        if let ledService = ledService, ledService.updateData(char: char) {
            return
        }
        
        if let motorService = motorService, motorService.updateData(char: char) {
            return
        }
            
        if let rotorService = rotorService, rotorService.updateData(char: char) {
            return
        }
        
        super.charChanged(char: char)
    }
}

