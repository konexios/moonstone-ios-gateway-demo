//
//  Device.swift
//  AcnGatewayiOS
//
//  Created by Tam Nguyen on 9/30/15.
//  Copyright © 2015 Arrow Electronics. All rights reserved.
//

import Foundation
import AcnSDK
import FirebaseCrash

protocol DeviceDelegate: class {
    func stateUpdated(sender: Device, newState: DeviceState)
    func telemetryUpdated(sender: Device, values: [SensorType: String])
    func statesUpdated(sender: Device, states: [String : Any])
    func nameUpdated(sender: Device, name: String)
}

extension Notification.Name {
    static let deviceStateChanged = Notification.Name("kDeviceStateChanged")
}

class Device : NSObject, IotDevice {
    
    // constants
    static let KeyDeviceIdPrefix = "device-id"
    static let KeyExternalIdPrefix = "external-id"
    
    static let DefaultDeviceNumSendingThreads = 2
    static let DefaultDeviceShutdownWaiting = 10000
    static let DefaultDeviceStartStopWaiting = 1000
    static let DefaultAccountRegistrationWaiting = 1000
    static let DefaultDeviceRetryInterval = 1000
    static let DefaultBleScanTimeout = 5000
    
    
    // MARK: Scan for device uuid
    var deviceScanUUID: UUID?
    
    var firmwareUpgradable: Bool {
        return false
    }
    
    // MARK: IotDevice
    
    var deviceUid: String? {
        preconditionFailure("[Device] abstract property!")
    }
    
    var userHid: String
    
    var gatewayHid: String
    
    var deviceName: String {
        return deviceType.rawValue
    }
    
    var deviceTypeName: String {
        return deviceType.rawValue
    }
    
    var properties: [String : AnyObject] {
        if deviceProperties != nil {
            return deviceProperties!.properties
        } else {
            return [String : AnyObject]()
        }
    }
    
    var softwareName: String {
        return ""
    }
    
    var softwareVersion: String {
        return ""
    }
    
    // MARK: Device
    
    var cloudName: String? {
        didSet {
            if let name = cloudName {
                delegate?.nameUpdated(sender: self, name: name)
            }
        }
    }
    
    var deviceType: DeviceType
    
    var deviceCategory: DeviceCategory {
        switch deviceType {
        case .SiLabsSensorPuck,
             .ThunderboardReact,
             .SensorTile,
             .SimbaPro,
             .OnSemiRSL10:          return .BLE
        case .IPhoneDevice:         return .None
        }
    }
    
    var state: DeviceState = .Disconnected
    
    var enabled: Bool = false
    
    var iotParams = [String: IotParameter]()
    
    var pollingTimer: Timer?
    
    weak var delegate: DeviceDelegate?
    
    var registered: Bool = false
    
    let delegateLock = NSLock()
    
    var deviceTelemetry = [Telemetry]() {
        didSet {
            for telemetry in self.deviceTelemetry  {
                self.deviceTelemetryDict[telemetry.type] = telemetry
            }
        }
    }
    var deviceTelemetryDict = [SensorType: Telemetry]()
    
    let lock = NSLock()
    
    var startTimerDate: Date?
    
    var deviceProperties: DeviceProperties?
    
    var deviceKey: String {
        return String(format: "%@/%@", arguments: [Device.KeyDeviceIdPrefix, deviceType.rawValue])
    }
    
    var externalIdKey: String {
        return String(format: "%@/%@", arguments: [Device.KeyExternalIdPrefix, deviceType.rawValue])
    }
   
    init(_ deviceType: DeviceType) {
        self.deviceType = deviceType
        userHid    = DatabaseManager.sharedInstance.currentAccount?.userId ?? ""
        gatewayHid = DatabaseManager.sharedInstance.gatewayId ?? ""
    }
    
    // function to enable/start the device
    func enable() {
        print("\(deviceType.rawValue) enable() ...")
        
        enabled    = true
        
        userHid    = DatabaseManager.sharedInstance.currentAccount?.userId ?? ""
        gatewayHid = DatabaseManager.sharedInstance.gatewayId ?? ""
        
        ArrowConnectIot.sharedInstance.sendingDevicesCount += 1
        startPollingTimer()
    }
    
    // function to disable/stop the device
    func disable() {
        print("[Device] disable() \(deviceType.rawValue) ...")
        enabled = false
        ArrowConnectIot.sharedInstance.sendingDevicesCount -= 1
        stopPollingTimer()
    }
    
    func disconnect() {
        //print("\(deviceType.rawValue) disconnect() ...")
    }
    
    func getTelemetryForDisplay(type: SensorType) -> TelemetryDisplay {
        let result = TelemetryDisplay()
        synchronized(delegateLock) {
            if let telemetry = self.deviceTelemetryDict[type] {
                result.label = telemetry.label
                result.value = telemetry.value
            }
        }
        return result
    }

    // function to load the deviceId from local storage (if exists)
    func loadDeviceId() -> String? {
        // print("loadDeviceId() ...")
        return UserDefaults.standard.string(forKey: deviceKey)
    }
    
    // function to save deviceId to local storage
    func saveDeviceId(deviceId: String) {
        print("[Device] saveDeviceId() --> \(deviceId)")
        let defaults = UserDefaults.standard
        defaults.setValue(deviceId, forKey: deviceKey)
        defaults.synchronize()
    }
    
    func loadExternalId() -> String {
        return UserDefaults.standard.string(forKey: externalIdKey) ?? ""
    }
    
    func saveExternalId(externalId: String) {
        print("[Device] saveExternalId() --> \(externalId)")
        let defaults = UserDefaults.standard
        defaults.setValue(externalId, forKey: externalIdKey)
        defaults.synchronize()
    }
    
    func checkAndRegisterDevice() {
        guard deviceUid != nil else {
            print("[Device] CheckAndRegisterDevice() - DeviceUid is nil, skip registering")
            return
        }
        
        ArrowConnectIot.sharedInstance.deviceApi.registerDevice(device: self) { (deviceId, externalId, error) in
            if let deviceId = deviceId {
                print("[Device] checkAndRegisterDevice() complete")
                
                // Save deviceId to disk
                self.saveDeviceId(deviceId: deviceId)
                self.registered = true
                
                if let externalId = externalId {
                    self.saveExternalId(externalId: externalId)
                }
                
                // Get name from the cloud
                ArrowConnectIot.sharedInstance.deviceApi.findDevice(hid: deviceId) { deviceModel in
                    self.cloudName = deviceModel?.name
                }                
            }
            else if let error = error {
                FIRCrashPrintMessage("[Device] - checkAndRegisterDevice() error: \(error)")
                HomeViewController.instance?.showAlert("Error Registering Device", message: error)
            }
        }
    }
    
    // function to queue IotParameter for upload
    func putIotParams(params: [IotParameter]) {
        // can't upload if registration failed!
        if registered {
            synchronized(lock) {
                for param in params {
                    self.iotParams[param.key] = param
                }
            }
        }
    }
    
    // function to retrieve IotParameters from queue for upload
    func getIotParams() -> [IotParameter] {
        var result = [IotParameter]()
        synchronized(lock) {
            for param in self.iotParams.values {
                result.append(param)
            }
            self.iotParams.removeAll()
        }
        return result
    }
    
    /// Set device state.
    /// Each device state will be pushed as notification in main thread
    func setState(newState: DeviceState)
    {
        state = newState
        
        // should post notification in the main thread
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .deviceStateChanged, object: self, userInfo: nil)
        }
        
        startTimerDate = newState == .Monitoring ? Date() : nil
       
        synchronized(delegateLock) {
            self.delegate?.stateUpdated(sender: self, newState: newState)
        }
    }
    
    func processSensorData(data: SensorDataProtocol) {
        let values = data.formatDisplay()
        
        synchronized(delegateLock)
        {
            values.forEach { type, value in
                self.deviceTelemetryDict[type]?.setValue(newValue: value)
            }
            self.delegate?.telemetryUpdated(sender: self, values: values)
        }
        
        putIotParams(params: data.writeIot())
    }
    
    private func startPollingTimer() {
        stopPollingTimer()
        
        let devicePollingInterval = DatabaseManager.sharedInstance.settings.devicePollingInterval
        
        print("[Device] startPollingTimer() ...");
        pollingTimer = Timer.scheduledTimer(
            timeInterval: devicePollingInterval / 1000.0,
            target: self,
            selector: #selector(Device.timerTask),
            userInfo: nil,
            repeats: true)
    }
    
    private func stopPollingTimer() {
        print("[Device] stopPollingTimer()...");
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    @objc func timerTask() {
        let params = self.getIotParams()
        if params.count > 0 {
            print("[Device] timerTask() sending \(params.count) parameters...")
            
            // build dataLoad
            let dataLoad = IotDataLoad(
                deviceId: loadDeviceId()!,
                externalId: loadExternalId(),
                deviceType: deviceTypeName,
                timestamp: Int64(NSDate().timeIntervalSince1970) * 1000,
                location: Location.sharedInstance.currentLocation(),
                parameters: params)
            
            IotDataPublisher.sharedInstance.sendData(data: dataLoad)
        }
//        else {
//             print("timerTask() nothing to send")
//        }
    }
    
    func saveProperties(properties: [String : AnyObject]) {
        deviceProperties?.saveProperties(properties: properties)
    }
    
    func updateProperty(property: DeviceProperty) {
        
    }
    
    func updateStates(states: [String : Any]) {
        delegate?.statesUpdated(sender: self, states: states)
    }
    
    func resetTelemetry() {
        for telemetry in deviceTelemetry {
            telemetry.reset()
        }
    }
    
    func enableTelemetry() {
        for telemetry in deviceTelemetry {
            telemetry.enable()
        }
    }
    
    func disableTelemetry() {
        for telemetry in deviceTelemetry {
            telemetry.disable()
        }
    }
}
