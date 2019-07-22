//
//  SiLabsSensorPuckManager.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 13/07/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

class SiLabsSensorPuckManager: BeaconDataDelegate {    
    
    var devices = [SiLabsSensorPuck]()
    var connectedDevices = [String : SiLabsSensorPuck]()
    
    // singleton
    static let sharedInstance = SiLabsSensorPuckManager()
    
    private init() {}
    
    func startScanBeacon() {
        BleUtils.sharedInstance.startScanBeacon(delegate: self)
    }
    
    func stopScanBeacon() {
        var shouldStopScanBeacon = true
        for device in connectedDevices.values {
            if device.enabled {
                shouldStopScanBeacon = false
                break
            }
        }
        
        if shouldStopScanBeacon {
            BleUtils.sharedInstance.stopScanBeacon()
            print("==> SiLabsSensorPuckManager() - stop iBeacon scaning")
        }        
    }
    
    func registerDevice(_ device: SiLabsSensorPuck) {
        devices.append(device)
    }
    
    func unregisterDevice(_ device: SiLabsSensorPuck) {
        if let idx = devices.index(of: device) {
            devices.remove(at: idx)
        }
        
        if let (key, _) = connectedDevices.first(where: { $1 == device }) {
            connectedDevices.removeValue(forKey: key)
        }
    }
    
    func dataReceived(data: NSData) {
        let mfid = String(format:"%2X", BleUtils.readInt16(data: data, loc: 0))
        let id = String(format:"%2X", BleUtils.readInt16(data: data, loc: 4))
        
        guard mfid == SiLabsSensorPuck.ManufacturerId else {
            return
        }
        
        if let device = connectedDevices[id], device.enabled {
            device.dataReceived(data: data)
        }
        else if devices.count > 0 {
            let newDevice = devices.removeFirst()
            connectedDevices[id] = newDevice
            if newDevice.enabled {
                newDevice.dataReceived(data: data)
            }
        }
        else {
            print("[SiLabsSensorPuckManager][Warning!] Not registered device \(id)")
        }
    }
}
