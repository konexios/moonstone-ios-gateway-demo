//
//  STDevice.swift
//  AcnGatewayiOS
//
//  Created by Alexey Chechetkin on 26/02/2018.
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

/// holds standard BlueST firmware version and
/// methods for extracting the version parts
struct STFwVersion {
    var name = ""
    var mcuType = ""
    var majoir = 0
    var minor = 0
    var patch = 0
    var fullname = ""
    
    var shortVersion: String {
        return "\(majoir).\(minor).\(patch)"
    }
    
    private static let fwVersionRegExPattern = "(.*)_(.*)_(\\d+)\\.(\\d+)\\.(\\d+)"
    
    // empty initializer
    init() { }
    
    // failable initializer, init from string
    init?(from s:String) {
        if extractFrom(s) == false {
            return nil
        }
    }
    
    mutating func extractFrom(_ str: String) -> Bool {
        
        let rx = try! NSRegularExpression(pattern: STFwVersion.fwVersionRegExPattern, options: .anchorsMatchLines)
        let matches = rx.matches(in: str, options: .anchored, range: NSMakeRange(0, str.count))
        
        guard matches.count > 0 else {
            return false
        }
        
        print("[STDevice] ==> Firmware detected")
        
        for match in matches {
            
            if match.numberOfRanges != 6 {
                continue
            }
            
            let typeRange = match.range(at: 1)
            let nameRage =  match.range(at: 2)
            let majoirRange = match.range(at: 3)
            let minorRange =  match.range(at: 4)
            let patchRange =  match.range(at: 5)
            
            let s = str as NSString
            
            name = s.substring(with: nameRage)
            mcuType = s.substring(with: typeRange)
            majoir = Int(s.substring(with: majoirRange))!
            minor = Int(s.substring(with: minorRange))!
            patch = Int(s.substring(with: patchRange))!
        }
        
        fullname = str
        
        return true
    }
}

/// Base class for all ST's family devices
class STDevice: BleDevice
{
    /// debug service uuid
    private static let kDebugServiceUUID = CBUUID(string: "00000000-000E-11E1-9AB4-0002A5D5C51B")
    
    /// debug characteristics uuids
    private static let termCharUUID = CBUUID(string: "00000001-000E-11E1-AC36-0002A5D5C51B")
    private static let errCharUUID = CBUUID(string: "00000002-000E-11E1-AC36-0002A5D5C51B")
    
    // default timeout for reading firmware version, seconds
    private static let kReadFirmwareVersionTimeout: TimeInterval = 3.0

    /// holds char references to debug and term services
    private var termChar: CBCharacteristic?
    private var errChar: CBCharacteristic?

    /// indicates that firmware upgrade is in progress
    private var fwStarted = false
    
    /// holds temporary debug console out
    private var debugTermOut = ""
    
    /// holds last readed version of firmware
    var firmwareVersion = STFwVersion()
    
    // firmware upgrader
    private var fwUpgrader: STDeviceFw?
    
    // firmware version reader handler
    private var fwVersionReadHandler: ((_ version: STFwVersion?, _ error: String?) -> Void)?
    
    /// returns mac address from advertising data, or nil
    /// - parameter data: data section from advertisment data
    /// - returns hex MAC address string with xx:xx:xx:xx:xx:xx or nil
    static func macAddressFromData(_ data: Data) -> String? {
        guard data.count == 12 else {
            return nil
        }
        
        return  String(format: "%02x:%02x:%02x:%02x:%02x:%02x", data[6], data[7], data[8], data[9], data[10], data[11])
    }

    /// by default all ST devices are OTA upgradable
    override var firmwareUpgradable: Bool {
        return true
    }
    
    /// software name and version
    override var softwareName: String {
        return firmwareVersion.name
    }
    
    override var softwareVersion: String {
        return firmwareVersion.shortVersion
    }
    
    /// read firmware version asynchronosly with completion handler (Version?, ErrorMessage?)
    func readFwVersion(_ completionHandler: @escaping (STFwVersion?, String?) -> Void)
    {
        guard let termChar = termChar else {
            completionHandler(nil, "Debug service is not available")
            return
        }
        
        // prepare command and write
        debugTermOut = ""
        let readFirmwareCommand = "versionFw\r\n" as NSString
        let data = readFirmwareCommand.data(using: 5) // ISOLatinEncoding
        
        if  let device = self.device,
            let data = data,
            device.state == .connected
        {
            print("[STDevice] ==> Sending read-firmware version command...")
            self.fwVersionReadHandler = completionHandler
            device.setNotifyValue(true, for: termChar)
            device.writeValue(data, for: termChar, type: .withResponse )
            perform(#selector(readFwVersionAborted), with: nil, afterDelay: STDevice.kReadFirmwareVersionTimeout)
        }
        else {
            completionHandler(nil, "Device is not connected")
        }
    }
    
    // read firmware version timeout handler
    @objc private func readFwVersionAborted() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        fwVersionReadHandler?( nil, "Can't get firmware version, timeout is reached")
    }
    
    /// start OTA upgrade
    /// - parameters:
    /// - data: firmware data to upgrade
    /// - notifyHanlder: in progress notification handler (progress 0...1, bytes sended)
    /// - completionHandler: completion handler (success, errorMessage?)
    func startUpgrade(_ data: Data, notifyHandler: @escaping (Float,Int) -> Void, completionHandler: @escaping (Bool, String?) -> Void  )
    {
        guard let device = device, let termChar = termChar else {
            completionHandler(false, "Device or debug service is not available")
            return
        }
        
        if device.state != .connected {
            completionHandler(false, "Device is not connected")
        }
        
        if let upgrader = fwUpgrader, upgrader.inProgress {
            completionHandler(false, "Upgrade already is in progress")
            return
        }
        
        // disable all sensors
        print("[STDevice] ==> Disabling all the sensors...")
        DispatchQueue.global().async {
            
            self.sensorMap.forEach { $1.disable() }
            
            DispatchQueue.main.async {
                let upgrader = STDeviceFw(device: device, termChar: termChar, firmwareData: data)
                self.fwUpgrader = upgrader
                
                device.setNotifyValue(true, for: termChar)
                upgrader.upgradeFirmware(notifyHandler: notifyHandler, completionHandler: completionHandler)
            }
        }
    }
    
    /// stops OTA
    func stopUgrade() {
        
        if let device = device, let termChar = termChar {
            device.setNotifyValue(false, for: termChar)
        }
        
        fwUpgrader = nil
    }
    
    /// read debug info from the console
    private func debugStdOutReceived(_ data: Data)
    {
        /// OTA is in progress
        if let fwUpgrader = fwUpgrader {
            fwUpgrader.processData(data)
            return
        }
        
        guard let msgString = NSString(data: data, encoding: 5) else {
            print("[STDevice] \(deviceType.rawValue) debugStdOutReceived() - data message is not ISOLatin")
            return
        }
        
        let msg = msgString as String
        
        // \r\n means end of the output message sequence
        if msg.hasSuffix("\r\n") {
            
            debugTermOut += msg.dropLast()
            
            print("[STDevice] ==> Debug: \(debugTermOut)")
            
            if let fwVersion = STFwVersion(from: debugTermOut), let termChar = termChar {
                // stop notifying
                device?.setNotifyValue(false, for: termChar)
                // stop timeout handler
                NSObject.cancelPreviousPerformRequests(withTarget: self)
                // save version and notify observer
                self.firmwareVersion = fwVersion
                self.fwVersionReadHandler?(fwVersion, nil)
            }
            
            // reset message
            debugTermOut = ""
        }
        else {
            debugTermOut += msg
        }
    }
    
    private func errorStdOutReceived(_ data: Data) {
        if let msg = NSString(data: data, encoding: 5) {
            print("[STDevice] \(deviceType.rawValue) - errorStdOutReceived() : \(msg)")
        }
        else {
            print("[STDevice] \(deviceType.rawValue) - errorStdOutReceived() - can't read error message, value isn't ISOLatin")
        }
    }
    
    // MARK: - BleDevice methods
    
    override func charChanged(char: CBCharacteristic) {
        if let termChar = termChar, termChar == char, let data = char.value {
            debugStdOutReceived(data)
        }
        else if let errChar = errChar, errChar == char, let data = char.value {
            errorStdOutReceived(data)
        }
        else {
            super.charChanged(char: char)
        }
    }
    
    override func createSensors(_ service: CBService)  {
        guard service.uuid == STDevice.kDebugServiceUUID, let chars = service.characteristics else {
            return
        }
     
        for char in chars {
            switch char.uuid {
            // debug char
            case SimbaPro.termCharUUID:
                print("[STDevice] - DEBUG char found for device \(deviceType.rawValue)")
                termChar = char
                
            // debug error char
            case SimbaPro.errCharUUID:
                print("[STDevice] - DEBUG_ERROR char found for device \(deviceType.rawValue)")
                errChar = char
            
            default:
                break
            }
        }
        
        // if terminal character is available - try to get version
        if termChar != nil {
            readFwVersion { version, error in
                guard version != nil else { return }
                // try to update device software version and name
                // if version is readed ok
                self.checkAndRegisterDevice()
            }
        }
    }
}
