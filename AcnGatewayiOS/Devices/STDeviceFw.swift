//
//  STDeviceFw.swift
//  AcnGatewayiOS
//
//  Created by Alexey Chechetkin on 25/01/2018.
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import Foundation
import CoreBluetooth

// class is using for device firmware upgrade for ST device type
class STDeviceFw: NSObject
{
    // MARK: - Crc checksum implementation
    private struct Crc {
        private static let crc: [UInt32] = [ 0x00000000, 0x04C11DB7, 0x09823B6E, 0x0D4326D9, 0x130476DC,
                                             0x17C56B6B, 0x1A864DB2, 0x1E475005, 0x2608EDB8, 0x22C9F00F,
                                             0x2F8AD6D6, 0x2B4BCB61, 0x350C9B64, 0x31CD86D3, 0x3C8EA00A,
                                             0x384FBDBD ]
        
        private static func Crc32Fast(_ CrcInit : UInt32, _ Data : UInt32) -> UInt32 {
            var Crc = CrcInit ^ Data
            
            Crc = (Crc << 4) ^ crc[Int(Crc >> 28)]
            Crc = (Crc << 4) ^ crc[Int(Crc >> 28)]
            Crc = (Crc << 4) ^ crc[Int(Crc >> 28)]
            Crc = (Crc << 4) ^ crc[Int(Crc >> 28)]
            Crc = (Crc << 4) ^ crc[Int(Crc >> 28)]
            Crc = (Crc << 4) ^ crc[Int(Crc >> 28)]
            Crc = (Crc << 4) ^ crc[Int(Crc >> 28)]
            Crc = (Crc << 4) ^ crc[Int(Crc >> 28)]
            
            return Crc
        }
        
        // calculate crc checksum
        static func upgrade(_ data: NSData) -> UInt32 {
            guard (data.length % 4) == 0  else {
                print("[STDeviceFw Crc] ==> upgrade() - Crc32 error: data length for CRC should be 4 bytes aligned, \(data.length)")
                return 0
            }
            
            var value: UInt32 = 0
            var crcValue: UInt32 = 0xffffffff
            
            for i in stride(from: 0, to: data.length, by: 4) {
                data.getBytes(&value, range: NSMakeRange(i, 4))
                crcValue = Crc32Fast(crcValue, value);
            }
            
            return crcValue
        }
    }

    /// check if upgrader has started upgrade
    var inProgress: Bool {
        switch state {
        case .none:
            return false
        default:
            return true
        }
    }
    
    // MARK: - Constants
    
    /// default response timeout
    private static let kResponseTimeout: TimeInterval = 5.0 // 2 sec would be ok for foreground app
    
    /// timeout between sending firmware data blocks to the device
    private static let kDataChunksTransmissionTimeout =  1.0 / 90.0 // fase 1/120.0
    
    /// max firmware block size to send to the device
    private static let kMaxBlockSize = 16
    
    /// finish acknoledge byte
    private static let kFinishingAck: UInt8 = 0x01
    
    // device and terminal debug character
    private var device: CBPeripheral
    private var termChar: CBCharacteristic
    
    // holds firmware data
    private var fwData: NSData
    
    // holds precalculated crc
    private var crc: UInt32 = 0
    
    // notification handlers
    private var notifyHandler: (_ progress: Float, _ packagesSended: Int) -> Void
    private var completionHandler: (_ success: Bool, _ errorMessage: String?) -> Void
    
    /// upgrade states
    private enum UpgradeState {
        case started           // upgrade has started
        case ackCrcWait        // initial crc ack wait
        case dataUpload        // data is being uploaded
        case ackFinishWait     // waiting finishing ack
        case finished          // upgrade finished
        case error(String)     // error is happened during upgrade
        case none              // initial state
    }
    
    // main state
    private var state: UpgradeState = .none {
        didSet {
            switch state {
            case let .error(errMsg):
                completionHandler(false, errMsg)
                print("[STDeviceFw] - error upgrade device: \(errMsg)")
            
            case .started:
                print("[STDeviceFw] - started, sending initial upgrade command...")
            
            case .ackCrcWait:
                print("[STDeviceFw] - waiting initial crc ack")
                
            case .ackFinishWait:
                print("[STDeviceFw] - data uploaded, waiting finishing ack...")
            
            case .dataUpload:
                print("[STDeviceFw] - crc ack ok, start uploading data...")
                
            case .finished:
                let delta = String(format:"%.02f min", (CACurrentMediaTime() - startTime)/60.0) // upgrade duration in min
                print("[STDeviceFw] - upgrade finished successfuly, upgrade time: \(delta)")
                completionHandler(true, nil)
            
            default:
                break
            }
        }
    }
    
    private var bytesSent = 0
    private var packageSent = 0
    
    // timers
    private var startTime: CFTimeInterval = 0
    
    // progress meter
    private var progressEdge = 0
    
    // initializer
    init(device: CBPeripheral, termChar: CBCharacteristic, firmwareData: Data) {
        self.device = device
        self.termChar = termChar
        self.fwData = firmwareData as NSData
        
        self.notifyHandler = {_,_ in }
        self.completionHandler = {_,_ in}
    }
    
    // start upgrade
    func upgradeFirmware( notifyHandler: @escaping (_ progress: Float, _ packagesSended: Int) -> Void,
                          completionHandler: @escaping (_ success: Bool, _ errorMessage: String?) -> Void )
    {
        guard case .none = state else {
            state = .error(Strings.kUpgradeAlreadyInProgress)
            return
        }
        
        guard device.state == .connected else {
            state = .error(Strings.kUpgradeDeviceIsNotConnected)
            return
        }
        
        // mark start time
        startTime = CACurrentMediaTime()
        
        state = .started
        
        // store handlers
        self.notifyHandler = notifyHandler
        self.completionHandler = completionHandler
        
        // data length should be aligned to 4
        let length = fwData.length - (fwData.length % 4)
        // get the truncated slice of firwmare data with no copy
        let tmpData = fwData.subdata(with: NSMakeRange(0, length)) as NSData
        // save the crc
        crc = Crc.upgrade(tmpData)
        
        guard crc != 0 else {
            state = .error(Strings.kUpgradeWrongCrc)
            return
        }
        
        var fwLength: UInt32 = UInt32( fwData.length )
        
        let cmdData = ("upgradeFw" as NSString).data(using: String.Encoding.isoLatin1.rawValue)!
        
        let mData = NSMutableData(data: cmdData)
        mData.append(&fwLength, length: 4)
        mData.append(&crc, length: 4)
        
        let crcString = String(format:"0x%0x", crc)
        print( "[STDeviceFw] - crc32: \(crcString), data length: \(fwLength)" )
        
        // send start firmware update command to the device
        device.writeValue(mData as Data, for: termChar, type: .withResponse)
        state = .ackCrcWait
        
        // set timeout handler while waiting initial CRC ack
        perform(#selector(responseTimeout), with: nil, afterDelay: STDeviceFw.kResponseTimeout)
    }
    
    /// timeout handler
    @objc private func responseTimeout() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        // Fix: workaround when we upgrade device while the app in the background
        // When we did all the data transmission and waiting for the finishing ack
        // and the app is not in active state (background, suspended)
        // this ack is not being sent by the ST device and we pass to this timeout
        // handler though the device is actually upgraded and goes to rebooting phase
        if case .ackFinishWait = state, UIApplication.shared.applicationState != .active {
            print("[STDeviceFw] - responseTimeout() in ackFinishWait state and application is not active")
            state = .finished
            return
        }
        
        state = .error(Strings.kUpgradeDataTransmissionTimeout)
    }
    
    /// this func shoud be called whenever terminal outdata is received
    /// and FOTA is in progress by the STDevice
    func processData(_ data: Data)
    {
        switch state {
            
        case .ackCrcWait:
            // data should be 4 bytes to hold only crc checksum
            guard data.count == 4 else { return }
            
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            
            var crc: UInt32 = 0
            (data as NSData).getBytes(&crc, length: 4)
            
            guard crc == self.crc else {
                state = .error(Strings.kUpgradeWrongCrcReceived)
                return
            }
            
            // reset all counters
            bytesSent = 0
            packageSent = 0
            state = .dataUpload
            
            // start to send blocks
            scheduleBlockSend()
            
        case .ackFinishWait:
            guard data.count > 0, data[0] == STDeviceFw.kFinishingAck else { return }
            
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            state = .finished
            
        default:
            break
        }
    }
    
    /// dispatch sending the next block of firmware data
    /// the data is being sent in the main thread
    private func scheduleBlockSend() {
        DispatchQueue.main.asyncAfter(deadline: .now() + STDeviceFw.kDataChunksTransmissionTimeout )
        {
            guard case .dataUpload = self.state, self.sendDataPackage() else {
                return
            }
            // reschedule sending the next block
            self.scheduleBlockSend()
        }
    }
    
    /// send the next chunk of firmware data to the device
    /// - returns: true if the next data block has been sent to the device
    private func sendDataPackage() -> Bool
    {
        // reset timeout
        NSObject.cancelPreviousPerformRequests(withTarget: self)

        guard device.state == .connected else {
            state = .error(Strings.kUpgradeCantSendDeviceIsNotConnected)
            return false
        }
        
        let lastPackageSize = min( fwData.length - bytesSent, STDeviceFw.kMaxBlockSize )
        
        // set timeout handler
        perform(#selector(responseTimeout), with: nil, afterDelay: STDeviceFw.kResponseTimeout)
        
        // nothing to send any more
        if lastPackageSize == 0 {
            state = .ackFinishWait
            return false
        }
        
        let dataPkg = fwData.subdata(with: NSMakeRange(bytesSent, lastPackageSize))
        device.writeValue(dataPkg, for: termChar, type: .withoutResponse)

        bytesSent += lastPackageSize;
        packageSent += 1
        
        let progress = Float(bytesSent) / Float(fwData.length)
        
        /*
        let progressPercents = Int(progress * 100)
        if progressPercents >= progressEdge {
            print("[STDeviceFw] - upgrading \(progressPercents)%...")
            progressEdge += 2
        }
        */
        
        // should notify for progress
        notifyHandler(progress, packageSent)
        
        return true
    }
}
