//
//  SiLabsSensorPuck.swift
//  AcnGatewayiOS
//
//  Created by Tam Nguyen on 2/8/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreBluetooth

class SiLabsSensorPuck : Device, BeaconDataDelegate {
    static let ManufacturerId = "1235"
    
    var puckId: String?
    var firstTime = true
    
    override var deviceKey: String {
        if puckId != nil {
            return String(format: "%@/%@/%@", arguments: [Device.KeyDeviceIdPrefix, deviceType.rawValue, puckId!])
        }
        return String(format: "%@/%@", arguments: [Device.KeyDeviceIdPrefix, deviceType.rawValue])
    }
    
    override var deviceUid: String? {
        return puckId
    }
    
    override var deviceTypeName: String {
        return "silabs-sensor-puck"
    }
    
    init() {
        super.init(DeviceType.SiLabsSensorPuck)
        
        deviceTelemetry = [
            Telemetry(type: .ambientTemperature, label: "Temperature"),
            Telemetry(type: .humidity, label: "Humidity"),
            Telemetry(type: .light, label: "Light"),
            Telemetry(type: .uv, label: "UV"),
            Telemetry(type: .heartRate, label: "Heart Rate")
        ]
        
        SiLabsSensorPuckManager.sharedInstance.registerDevice(self)
    }
    
    override func enable() {
        super.enable()
        SiLabsSensorPuckManager.sharedInstance.startScanBeacon()
        setState(newState: DeviceState.Detecting)
    }
    
    override func disable() {
        super.disable()
        SiLabsSensorPuckManager.sharedInstance.unregisterDevice(self)
        SiLabsSensorPuckManager.sharedInstance.stopScanBeacon()
        setState(newState: DeviceState.Disconnected)
    }
    
    func dataReceived(data: NSData) {
        let mfid = String(format:"%2X", BleUtils.readInt16(data: data as NSData, loc: 0))
        let id = String(format:"%2X", BleUtils.readInt16(data: data as NSData, loc: 4))
        let type = BleUtils.readInt8(data: data as NSData, loc: 2)
        
        if firstTime {
            puckId = "SensorPuck-" + id
            print("mfid: \(mfid), puckId: \(String(describing: puckId))")
            firstTime = false
            checkAndRegisterDevice()
        }
        
        if type == 0 {
            
            // set state to Monitoring if current in Detecting
            if self.state == DeviceState.Detecting {
                self.setState(newState: DeviceState.Monitoring)
            }
            
            // environment
            let humidity = Double(BleUtils.readInt16(data: data as NSData, loc: 6)) / 10.0
            let temperature = ((Double(BleUtils.readInt16(data: data as NSData, loc: 8)) / 10.0) * 9.0 / 5.0) + 32.0
            let light = Double(BleUtils.readInt16(data: data as NSData, loc: 10)) * 2.0
            let uv = Double(BleUtils.readInt8(data: data as NSData, loc: 12))
            //print("-----> Humidity: \(humidity), temperature: \(temperature), light: \(light), uv: \(uv)")
            processSensorData(data: SensorPuckData([temperature, humidity, light, uv, -1]))
            
        }
        else {
            // biometric
            let state = BleUtils.readInt8(data: data as NSData, loc: 6);
            
            // reset to Detecting
            if state != 3 && self.state == DeviceState.Monitoring {
                setState(newState: DeviceState.Detecting)
            }
            
            // set back to Monitoring
            if state == 3 && self.state == DeviceState.Detecting {
                setState(newState: DeviceState.Monitoring)
            }
            
            //var hrState = ""
            if state == 0 {
                //hrState = "Idle"
            } else if state == 1 {
                //hrState = "No Signal"
            } else if state == 2 {
                //hrState = "Acquiring"
            } else if state == 3 {
                //hrState = "Active"
                let heartRate = Double(BleUtils.readInt8(data: data as NSData, loc: 7))
                //print("-----> HeartRate: \(heartRate)")
                processSensorData(data: SensorPuckData([-1, -1, -1, -1, heartRate]))
            } else if state == 4 {
                //hrState = "Invalid"
            } else if state == 5 {
                //hrState = "Error"
            }
            //print("hrState: \(hrState)")
        }
    }
}
