//
//  OnSemiRSL10Services.swift
//  AcnGatewayiOS
//
//  Created by Alexey Chechetkin on 14.03.2018.
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import Foundation
import CoreBluetooth
import AcnSDK

// common protocol for RSL10 service
protocol RSL10Service {
    var device: OnSemiRSL10? { get set }
    
    static var minValue: Int { get }
    static var maxValue: Int { get }
    
    init(service: CBService)
    
    @discardableResult
    func updateData(char: CBCharacteristic) -> Bool
    
    func updateStates(states: [String: Any]) -> Void
}

/// cloud state names for
/// OnSemiRSL10 services
struct RSL10CloudStateKeys {
    static let led1 = "led1value"
    static let led2 = "led2value"
    static let motor1 = "motor1angle"
    static let motor2 = "motor2angle"
    static let rotor = "rotorRPM"
}

/// this class is responsible for LED indicators
/// mounted on RSL10 board
class OnSemiRSL10LedService: RSL10Service {
    
    static let Led1SensorUUID = CBUUID(string: "669A0C20-0008-1A8F-E711-BED9317A52B3")
    static let Led2SensorUUID = CBUUID(string: "669A0C20-0008-1A8F-E711-BED9327A52B3")
    
    static let minValue = 0
    static let maxValue = 1023
    
    private var service: CBService?
    private var led1Char: CBCharacteristic?
    private var led2Char: CBCharacteristic?
    
    /// notification hander
    var led1notificationHanlder: ((_ value: Int) -> Void)?
    var led2notificationHandler: ((_ value: Int) -> Void)?
    
    // public
    var led1Value: UInt16 = 0
    var led2Value: UInt16 = 0
    
    weak var device: OnSemiRSL10?
    
    required init(service: CBService) {
        guard let chars = service.characteristics else {
            print("[OnSemiRSL10LedService] - init() chars is nil")
            return
        }
        
        self.service = service
        for char in chars {
            switch char.uuid {
            case OnSemiRSL10LedService.Led1SensorUUID:
                led1Char = char
                
            case OnSemiRSL10LedService.Led2SensorUUID:
                led2Char = char
                
            default:
                break
            }
        }
    }
    
    // update cloud states for this service
    func updateStates(states: [String: Any]) {
        if let dict = states[RSL10CloudStateKeys.led1] as? [String: Any], let str = dict["value"] as? NSString {
            let val = str.integerValue
            if led1Value != UInt16(val) {
                setValueFor(led: 0, value: val)
            }
        }
        
        if let dict = states[RSL10CloudStateKeys.led2] as? [String: Any], let str = dict["value"] as? NSString {
            let val = str.integerValue
            if led2Value != UInt16(val) {
                setValueFor(led: 1, value: val)
            }
        }
    }
    
    /// should be invoked from CharUpdate methods of the device
    /// - returns: true if value is processed
    @discardableResult
    func updateData(char: CBCharacteristic) -> Bool {
        
        guard   char.uuid == OnSemiRSL10LedService.Led2SensorUUID ||
                char.uuid == OnSemiRSL10LedService.Led1SensorUUID,
                let data = char.value
        else {
                return false
        }
        
        let value = BleUtils.readUInt16(data: data as NSData, loc: 0).bigEndian
        
        if char.uuid == OnSemiRSL10LedService.Led1SensorUUID {
            led1Value = value
            led1notificationHanlder?(Int(value))
            print("[OnSemiRSL10LedService] - readed LED1 value: \(value)")
        }
        else {
            led2Value = value
            led2notificationHandler?(Int(value))
            print("[OnSemiRSL10LedService] - readed LED2 value: \(value)")
        }
        
        return true
    }
    
    func requestLedValue(_ led: UInt) {
        let char = led == 0 ? led1Char : led2Char
        
        guard let ledChar = char, let service = service else {
            print("[OnSemiRSL10LedService] - readValueForLed, led char or service is nil")
            return
        }

        service.peripheral.readValue(for: ledChar)
    }
    
    func setValueFor(led: UInt, value: Int = 0) {
        let char = led == 0 ? led1Char : led2Char
        
        guard let ledChar = char, let service = service else {
            print("[OnSemiRSL10LedService] - setValueForLed, led char or service is nil")
            return
        }
        
        guard value >= OnSemiRSL10LedService.minValue && value <= OnSemiRSL10LedService.maxValue else {
            print("[OnSemiRSL10LedService] - setValueForLed:\(led), value: \(value) is out of bounds!")
            return
        }
        var shortVal: UInt16 = UInt16(value).bigEndian
        
        let data = NSData(bytes: &shortVal, length: 2)

        service.peripheral.writeValue(data as Data, for: ledChar, type: .withoutResponse)
        
        // update cloud values
        let currentStateKey = led == 0 ? RSL10CloudStateKeys.led1 : RSL10CloudStateKeys.led2
        let cloudState = StateModel(states: [currentStateKey : value])
        
        device?.updateCloudState(cloudState, serviceName: "LEDService")
        
        requestLedValue(led)
    }
}

/// This class is responsible for the step motors
class OnSemiRSL10MotorService: RSL10Service {
    
    static let Motor1SensorUUID = CBUUID(string: "669A0C20-0008-1A8F-E711-6DDAC17892D0")
    static let Motor2SensorUUID = CBUUID(string: "669A0C20-0008-1A8F-E711-6DDAC27892D0")
    
    static let minValue = 0
    static let maxValue = Int(UInt16.max)
    
    private var service: CBService?
    private var motor1Char: CBCharacteristic?
    private var motor2Char: CBCharacteristic?
    
    // public
    var motor1Value: UInt16 = 0
    var motor2Value: UInt16 = 0
    
    /// notification handler
    var motor1NotificationHandler: ((_ value: Int) -> Void)?
    var motor2NotificationHandler: ((_ value: Int) -> Void)?
    
    /// notification timer
    private var timer1: Timer?
    private var timer2: Timer?
 
    weak var device: OnSemiRSL10?

    required init(service: CBService) {
        guard let chars = service.characteristics else {
            print("[OnSemiRSL10MotorService] - init() chars is nil")
            return
        }
        
        self.service = service
        for char in chars {
            switch char.uuid {
            case OnSemiRSL10MotorService.Motor1SensorUUID:
                motor1Char = char
                
            case OnSemiRSL10MotorService.Motor2SensorUUID:
                motor2Char = char
                
            default:
                break
            }
        }
    }
    
    func stopNotification() {
        timer1?.invalidate()
        timer2?.invalidate()
    }
    
    // update cloud states for this service
    func updateStates(states: [String: Any]) {
        if let dict = states[RSL10CloudStateKeys.motor1] as? [String: Any], let str = dict["value"] as? NSString {
            let val = str.integerValue
            if motor1Value != UInt16(val) {
                setValueFor(motor: 0, value: val)
            }
        }
        
        if let dict = states[RSL10CloudStateKeys.motor2] as? [String: Any], let str = dict["value"] as? NSString {
            let val = str.integerValue
            if motor2Value != UInt16(val) {
                setValueFor(motor: 1, value: val)
            }
        }
    }
    
    /// should be invoked from CharUpdate methods of the device
    @discardableResult
    func updateData(char: CBCharacteristic) -> Bool {
        
        guard   char.uuid == OnSemiRSL10MotorService.Motor1SensorUUID ||
                char.uuid == OnSemiRSL10MotorService.Motor2SensorUUID,
                let data = char.value
        else
        {
                return false
        }
        
        let value = BleUtils.readUInt16(data: data as NSData, loc: 0).bigEndian
        
        if char.uuid == OnSemiRSL10MotorService.Motor1SensorUUID {
            motor1Value = value
            motor1NotificationHandler?(Int(value))
            print("[OnSemiRSL10MotorService] - readed Motor1 value: \(value)")
        }
        else {
            motor2Value = value
            motor2NotificationHandler?(Int(value))
            print("[OnSemiRSL10MotorService] - readed Motor2 value: \(value)")
        }
        
        return true
    }
    
    /// begin request value for motors
    /// - Parameter: motor - number of the motor, 0 | 1
    func requestMotorValue(_ motor: UInt) {
        let char = motor == 0 ? motor1Char : motor2Char
        
        guard let motorChar = char, let service = service else {
            print("[OnSemiRSL10MotorService] - readValueForMotor:\(motor), motor char or service is nil")
            return
        }
        
        service.peripheral.readValue(for: motorChar)
    }
    
    /// set value for motor and enable notification
    /// - parameter: motor - motor number
    /// - parameter: value - angle for the motor
    /// - parameter: notify - if true notification timer will be fired unitil value will be 0
    func setValueFor(motor: UInt, value: Int, notify: Bool = true) {
        let char = motor == 0 ? motor1Char : motor2Char
        
        guard let motorChar = char, let service = service else {
            print("[OnSemiRSL10MotorService] - setValueForMotor:\(motor), led char or service is nil")
            return
        }
        
        guard value >= OnSemiRSL10MotorService.minValue && value <= OnSemiRSL10MotorService.maxValue else {
            print("[OnSemiRSL10MotorService] - setValueForMotor:\(motor), value: \(value) is out of bounds!")
            return
        }
        
        var shortVal: UInt16 = UInt16(value).bigEndian
        let data = NSData(bytes: &shortVal, length: 2)

        service.peripheral.writeValue(data as Data, for: motorChar, type: .withoutResponse)

        print("[OnSemiRSL10MotorService] - setValueForMotor:\(motor) - \(value)")
        
        if service.peripheral.state != .connected {
            timer1?.invalidate()
            timer2?.invalidate()
            
            return
        }
        
        // update cloud state for the service
        let currentStateKey = motor == 0 ? RSL10CloudStateKeys.motor1 : RSL10CloudStateKeys.motor2
        let cloudState = StateModel(states: [currentStateKey : value])
        
        device?.updateCloudState(cloudState, serviceName: "MotorService")
        
        requestMotorValue(motor)
        
        // don't need to set notification timer
        if notify == false || value == 0 {
            return            
        }
        
        if motor == 0 {
            timer1?.invalidate()
            // schedule timer update
            timer1 = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(notifyTimer1(_:)), userInfo: nil, repeats: true)
            
            motor1Value = UInt16(value)
        }
        else {
            timer2?.invalidate()
            // schedule timer update
            timer2 = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(notifyTimer2(_:)), userInfo: nil, repeats: true)
            
            motor2Value = UInt16(value)
        }
    }
    
    // request new value for the motor
    private func timerFuncFor(motor: UInt) {
        requestMotorValue(motor)
        
        if motor == 0 && motor1Value == 0 {
            timer1?.invalidate()
            timer1 = nil
            print("[OnSemiRSL10MotorService] - Motor1 has stopped, notification stopped")
        }
        else if motor == 1 && motor2Value == 0 {
            timer2?.invalidate()
            timer2 = nil
            print("[OnSemiRSL10MotorService] - Motor2 has stopped, notification stopped")
        }
    }
    
    @objc private func notifyTimer1(_ sender: Timer) {
        //print("[OnSemiRSL10MotorService] - Motor1 notify timer fired")
        timerFuncFor(motor: 0)
    }
    
    @objc private func notifyTimer2(_ sender: Timer) {
        //print("[OnSemiRSL10MotorService] - Motor2 notify timer fired")
        timerFuncFor(motor: 1)
    }
}


/// This class is responsible for the rotor
class OnSemiRSL10RotorService: RSL10Service {
    
    static let RotorSensorUUID = CBUUID(string: "E093F3B5-00A3-A9E5-9ECA-40076E0EDC24")
    
    static let minValue = 4400
    static let maxValue = 13400
    
    private var service: CBService?
    private var rotorChar: CBCharacteristic?
    
    // public
    var rotorValue: UInt16 = 0
    
    /// notification handler
    var notificationHandler: ((_ value: Int) -> Void)?

    weak var device: OnSemiRSL10?

    required init(service: CBService) {
        guard let chars = service.characteristics else {
            print("[OnSemiRSL10MotorService] - init() chars is nil")
            return
        }
        
        self.service = service
        for char in chars {
            switch char.uuid {
            case OnSemiRSL10RotorService.RotorSensorUUID:
                rotorChar = char
                
            default:
                break
            }
        }
    }
    
    // update cloud states for this service
    func updateStates(states: [String: Any]) {
        guard let dict = states[RSL10CloudStateKeys.rotor] as? [String: Any],
              let str = dict["value"] as? NSString else {
            return
        }

        setValue(str.integerValue)
    }
    
    /// should be invoked from CharUpdate methods of the device
    @discardableResult
    func updateData(char: CBCharacteristic) -> Bool {
        
        guard char.uuid == OnSemiRSL10RotorService.RotorSensorUUID, let data = char.value else  {
            return false
        }
        
        rotorValue = BleUtils.readUInt16(data: data as NSData, loc: 0).bigEndian
        
        notificationHandler?(Int(rotorValue))
        print("[OnSemiRSL10RotorService] - readed Rotor value: \(rotorValue)")
        
        return true
    }
    
    /// begin request value for motors
    /// - Parameter: motor - number of the motor, 0 | 1
    func requestRotorValue() {
        guard let rotorChar = rotorChar, let service = service else {
            print("[OnSemiRSL10RotorService] - readValueForRotor, motor char or service is nil")
            return
        }
        
        service.peripheral.readValue(for: rotorChar)
    }
    
    func setValue(_ value: Int = 0) {
        guard let rotorChar = rotorChar, let service = service else {
            print("[OnSemiRSL10RotorService] - setValue, rotor char or service is nil")
            return
        }
        
        guard value == 0 || (value >= OnSemiRSL10RotorService.minValue && value <= OnSemiRSL10RotorService.maxValue) else {
            print("[OnSemiRSL10RotorService] - setValue, value: \(value) is out of bounds!")
            return
        }

        var shortVal: UInt16 = UInt16(value).bigEndian
        let data = NSData(bytes: &shortVal, length: 2)
        
        service.peripheral.writeValue(data as Data, for: rotorChar, type: .withoutResponse)
        
        let cloudState = StateModel(states: [RSL10CloudStateKeys.rotor : value])
        device?.updateCloudState(cloudState, serviceName: "RotorService")
        
        requestRotorValue()
    }
}

