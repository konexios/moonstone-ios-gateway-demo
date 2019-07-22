//
//  BleSensor.swift
//  AcnGatewayiOS
//
//  Created by Tam Nguyen on 10/3/15.
//  Copyright © 2015 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BleSensorProtocol
{
    var name: String { get }
    
    var dataUUID: CBUUID { get }
    
    var configUUID: CBUUID { get }
    
    var periodUUID: CBUUID { get }
    
    func parse(data: Data) -> SensorDataProtocol
    
    func enable()
    
    func disable()
    
    func readValue()
    
    func stop()
}

class BleSensor<Type: SensorDataProtocol> : BleSensorProtocol
{
    private var service: CBService
    private var dataChar, configChar, periodChar: CBCharacteristic?
    
    private var period: Int = 50 // default of 500ms
    private var enableBytes:  [UInt8] = [0x01]
    private var disableBytes: [UInt8] = [0x00]
    private var waitTimeout: Int = 5 // seconds
    
    init(_ service: CBService) {
        self.service = service

        guard let chars = service.characteristics else {
            print("[BleSensor] init() service has no available characteristics")
            return
        }
        
        // scan for characteristics
        for char in chars {
            switch char.uuid {
            case dataUUID: dataChar = char
            case configUUID: configChar = char
            case periodUUID: periodChar = char
            default: break
            }
        }
    }
    
    func enable() {
        print("[BleSensor] \(name).enable() setNotifyValue ...")
        
        if let dataChar = dataChar {
            BleUtils.sharedInstance.setNotifyValue(peripheral: self.service.peripheral, characteristic: dataChar, value: true, timeOutInSec: waitTimeout)
        }
        else {
            print("[BleSensor] \(name).enable() can not enable - data char is nil")
        }
        
        if configChar != nil {
            print("[BleSensor] \(name).enable() turn on ...")
            BleUtils.sharedInstance.writeCharacteristic(peripheral: self.service.peripheral, characteristic: configChar!, data: NSData(bytes: enableBytes, length: enableBytes.count), timeOutInSec: waitTimeout)
        }
        
        if periodChar != nil {
            print("[BleSensor] \(name).enable() update period ...")
            BleUtils.sharedInstance.writeCharacteristic(peripheral: self.service.peripheral, characteristic: periodChar!, data: NSData(bytes: [period], length: 1), timeOutInSec: waitTimeout)
        }       
    }
    
    func disable() {
        print("[BleSensor] \(name).disable()...")
        
        if let dataChar = dataChar {
            BleUtils.sharedInstance.setNotifyValue(peripheral: self.service.peripheral, characteristic: dataChar, value: false, timeOutInSec: waitTimeout)
        }
        else {
            print("[BleSensor] \(name).disable() can not disable -  data char is nil")
        }
        
        if configChar != nil {
            print("[BleSensor] \(name).disable() turning off ...")
            BleUtils.sharedInstance.writeCharacteristic(peripheral: self.service.peripheral, characteristic: configChar!, data: NSData(bytes: disableBytes, length: disableBytes.count), timeOutInSec: waitTimeout)
        }
    }
    
    func readValue() {
        BleUtils.sharedInstance.readValueForCharacteristic(characteristic: dataChar!)
        print("[BleSensor] readValue()...")
    }
    
    func stop() { }
    
    // MARK: abstract methods and properties

    var name: String {
        preconditionFailure("[BleSensor] abstract property!")
    }
    
    var dataUUID: CBUUID {
        preconditionFailure("[BleSensor] abstract property!")
    }
    
    var configUUID : CBUUID {
        preconditionFailure("[BleSensor] abstract method!")
    }
    
    var periodUUID : CBUUID {
        preconditionFailure("[BleSensor] abstract method!")
    }

    func parse(data: Data) -> SensorDataProtocol {
        preconditionFailure("[BleSensor] abstract method!")
    }    
}

class BlePollingSensor<Type: SensorDataProtocol> : NSObject, BleSensorProtocol
{
    private var characteristic: CBCharacteristic
    private var pollingTimer: Timer?
    private var pollingInterval: Double = 1.0

    init(char: CBCharacteristic) {
        self.characteristic = char
    }
    
    private func startPollingTimer() {
        stopPollingTimer()
        pollingTimer = Timer(timeInterval: pollingInterval, target: self, selector: #selector(readValue), userInfo: nil, repeats: true)
        RunLoop.main.add(pollingTimer!, forMode: .defaultRunLoopMode)
    }
    
    private func stopPollingTimer() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    deinit {
        stopPollingTimer()
    }

    // MARK: - BleSensorProtocol
    
    func enable() {
        print("[BlePolingSensor] \(name).enable()")
        startPollingTimer()
    }
    
    func disable() {
        print("[BlePolingSensor] \(name).disable()")
        stopPollingTimer()
    }    
    
    func stop() {
        disable()
    }
    
    @objc func readValue() {
        guard pollingTimer != nil else {
            return
        }
        
        let device = characteristic.service.peripheral
        if device.state == .connected {            
            device.readValue(for: characteristic)
        }
    }
    
    // MARK: abstract methods and properties
    
    var name: String {
        preconditionFailure("[BlePolingSensor] abstract property!")
    }
    
    var dataUUID: CBUUID {
        preconditionFailure("[BlePolingSensor] abstract property!")
    }
    
    var configUUID : CBUUID {
        preconditionFailure("[BlePolingSensor] abstract method!")
    }
    
    var periodUUID : CBUUID {
        preconditionFailure("[BlePolingSensor] abstract method!")
    }
    
    func parse(data: Data) -> SensorDataProtocol {
        preconditionFailure("[BlePolingSensor] abstract method!")
    }
}
