//
//  BleUtils.swift
//  AcnGatewayiOS
//
//  Created by Tam Nguyen on 10/2/15.
//  Copyright © 2015 Arrow Electronics. All rights reserved.
//

import Foundation
import CoreBluetooth
import ObjectiveC

protocol BeaconDataDelegate {
    func dataReceived(data: NSData)
}

protocol BleDeviceProtocol {
    func deviceDisconnected()
    func charChanged(char: CBCharacteristic)
}

private var _advNameAssociatedKey: UInt8 = 0
private var _macAddressAssociatedKey: UInt8 = 0

/// extend CBPeripheral to hold advertised name
extension CBPeripheral {
    var advName: String? {
        get { return objc_getAssociatedObject(self, &_advNameAssociatedKey) as? String }
        set { objc_setAssociatedObject(self, &_advNameAssociatedKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN) }
    }
    
    var macAddress: String? {
        get { return objc_getAssociatedObject(self, &_macAddressAssociatedKey) as? String }
        set { objc_setAssociatedObject(self, &_macAddressAssociatedKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN) }
    }
}

/// MARK: BleUtils - Singlton class with BL helper methods
class BleUtils: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate
{
    /// singlton instance
    static let sharedInstance: BleUtils = BleUtils()
    
    static let kDeviceMultiNamesSeparator: Character = "/"
    
    /// Returns true if Bluetooth is available and powered on
    var enabled: Bool {
        return centralManager?.state == .poweredOn
    }
    
    /// Returns true if BL is in beacon mode
    var isBeaconMode: Bool {
        return scanBeacon
    }
    
    // MARK: - Private
    private var centralManager: CBCentralManager?
    
    private var initialized = false
    private var scanBeacon = false

    private var peripheral: CBPeripheral?
    private var peripheralName: String?
    
    private var characteristic: CBCharacteristic?
    
    private var service: CBService?
    private var services: [CBService] = []
    
    private var semaphore: DispatchSemaphore?
    
    private var connectedDevices = Set<BleDevice>()
    private var beaconDataDelegate: BeaconDataDelegate?
    
    /// Device discover handler
    private var deviceDiscoverHandler: ((_ device:CBPeripheral, _ advData:[String: Any]) -> Void)?   

    private let lock = NSLock()
    
    override private init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: Beacon
    
    /// Start beacon scaning and set current discovery mode to beacon scaning
    /// while this mode is active not other BLE devices can be discovered
    func startScanBeacon(delegate: BeaconDataDelegate)
    {
        guard initialized, !scanBeacon, let manager = centralManager else {
            let msg = initialized ? "beacon scanining is already in progress" : "not initialized"
            FIRCrashPrintMessage("[BleUtils] startScanBeacon() ERROR \(msg)")
            return
        }
        
        beaconDataDelegate = delegate
        scanBeacon = true
        DispatchQueue.global().async {
            print("[BleUtils] Start beacon scanning...")
            manager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    /// Stop beacon scaning and set discovery mode to normal
    func stopScanBeacon()
    {
        guard initialized, scanBeacon, let manager = centralManager else {
            let msg = initialized ? "beacon scanining is not in progress" : "not initialized"
            FIRCrashPrintMessage("[BleUtils] stopScanBeacon() ERROR \(msg)")
            return
        }
        
        beaconDataDelegate = nil
        print("[BleUtils] Stop beacon scanning...")
        manager.stopScan()
        scanBeacon = false
    }
    
    // MARK: - Device lookup and discover
    
    /// Start scaning for devices with given name
    /// - Parameters:
    ///     - name:  Device searching name
    ///     - timeOutInSec: The amount of time (timeout) to search the device
    /// - returns: Peripheral device or nil if not found
    func lookup(name: String, timeOutInSec: Int) -> CBPeripheral?
    {
        guard initialized, !scanBeacon, let manager = centralManager else {
            let msg = initialized ? "beacon scanining is in progress" : "not initialized"
            FIRCrashPrintMessage("[BleUtils] lookup() ERROR \(msg)")
            return nil
        }

        var result: CBPeripheral?
        
        synchronized(lock) {
            self.peripheral = nil
            self.peripheralName = name
            
            self.semaphore = DispatchSemaphore(value: 0)
            
            manager.scanForPeripherals(withServices: nil, options: nil)
            
            let dispatchTime = DispatchTime.now() + .seconds(timeOutInSec)
            let ret = semaphore!.wait(timeout: dispatchTime)
            
            if ret == .success {
                result = self.peripheral
            } else {
                print("[BleUtils] lookup() timeout!")
            }
        }
        
        return result
    }
    
    /// Start discover any BLE device with feedback handler
    func startDiscover(_ deviceDescoverHandler: @escaping (_ device:CBPeripheral, _ advData:[String: Any]) -> Void ) {
        self.deviceDiscoverHandler = deviceDescoverHandler
        
        guard initialized, let manager = centralManager else {
            return
        }
        
        manager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    /// Stop discover any BLE device with feedback handler
    func stopDiscover() {
        deviceDiscoverHandler = nil
    }

    // MARK: - Connection
    
    /// Connect to the device with given timeout
    func connect(peripheral: CBPeripheral, timeOutInSec: Int) -> [CBService]
    {
        var result: [CBService] = []
        
        guard initialized, !scanBeacon, let manager = centralManager else {
            let msg = initialized ? "beacon scanining is in progress" : "not initialized"
            FIRCrashPrintMessage("[BleUtils] connect() ERROR \(msg)")
            return result
        }
        
        synchronized(lock) {
            self.peripheral = peripheral
            peripheral.delegate = self
            self.services.removeAll()
            
            self.semaphore = DispatchSemaphore(value: 0)
            
            manager.connect(peripheral, options: nil)
            
            let dispatchTime = DispatchTime.now() + .seconds(timeOutInSec)
            let ret = semaphore!.wait(timeout: dispatchTime)
            
            if ret == .success {
                result.append(contentsOf: self.services)
            }
            else {
                print("[BleUtils] connect() timeout!")
            }
        }
        return result
    }
    
    func disconnect(peripheral: CBPeripheral)
    {
        guard initialized, !scanBeacon, let manager = centralManager else {
            let msg = initialized ? "beacon scanining is in progress" : "not initialized"
            FIRCrashPrintMessage("[BleUtils] Disconnect - can not disconnect peripheral \(peripheral.name ?? "UNKNOWN") \(msg)")
            return
        }
        
        synchronized(lock) {
            print("[BleUtils] Canceling connection for \(peripheral.name ?? "UNKNOWN")")
            manager.cancelPeripheralConnection(peripheral)
        }
    }
    
    // MARK: - Service discover
    
    /// Discover all the characters for the service
    func discover(peripheral: CBPeripheral, service: CBService, timeOutInSec: Int)
    {
        guard initialized, !scanBeacon else {
            let msg = initialized ? "beacon scanining is in progress" : "not initialized"
            FIRCrashPrintMessage("[BleUtils] discover() ERROR \(msg)")
            return
        }
        
        synchronized(lock) {
            self.peripheral = peripheral
            self.service = service
            
            self.semaphore = DispatchSemaphore(value: 0)
            
            peripheral.discoverCharacteristics(nil, for: service)
            
            let dispatchTime = DispatchTime.now() + .seconds(timeOutInSec)
            let ret = semaphore!.wait(timeout: dispatchTime)
            
            if ret != .success {
                print("[BleUtils] discover() timeout!")
            }
        }
    }
    
    // MARK: - Characteristic

    /// Write data for characteristic with timeout
    func writeCharacteristic(peripheral: CBPeripheral, characteristic: CBCharacteristic, data: NSData, timeOutInSec: Int)
    {
        guard initialized else { return }
        
        synchronized(lock) {
            self.peripheral = peripheral
            self.characteristic = characteristic
            
            self.semaphore = DispatchSemaphore(value: 0)
            
            peripheral.writeValue(data as Data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
            
            let dispatchTime = DispatchTime.now() + .seconds(timeOutInSec)
            let ret = semaphore!.wait(timeout: dispatchTime)
            
            if ret != .success {
                print("[BleUtils] writeCharacteristic() timeout!")
            }
        }
    }

    /// Enable/Disable notification for characteristic
    /// - parameter value: True to enable, false to disable characteristic notifications
    /// - parameter timeOutInSec: Timeout to disable/enable characteristic
    func setNotifyValue(peripheral: CBPeripheral, characteristic: CBCharacteristic, value: Bool, timeOutInSec: Int)
    {
        guard initialized else { return }
        
        synchronized(lock) {
            self.peripheral = peripheral
            self.characteristic = characteristic
            
            self.semaphore = DispatchSemaphore(value: 0)
            
            peripheral.setNotifyValue(value, for: characteristic)
            
            let dispatchTime = DispatchTime.now() + .seconds(timeOutInSec)
            let ret = semaphore!.wait(timeout: dispatchTime)
            
            if ret != .success {
                print("[BleUtils] setNotifyValue() timeout!")
            }
        }
    }
    
    /// Read value for characteristic
    func readValueForCharacteristic(characteristic: CBCharacteristic) {
        peripheral?.readValue(for: characteristic)
    }
    
    
    // MARK: - Registration
    
    /// Register given BLE device for notifications
    /// device will get all the notifications when any device's characteristic will update/change
    /// also device will get disconnect/fail notifications
    /// - Parameter delegate: Device to register
    func registerDevice(_ delegate: BleDevice) {
        connectedDevices.insert(delegate)
    }
    
    /// Remove registration for given BLE device
    /// - Parameter delegate: Device to remove
    func unregisterDevice(_ delegate: BleDevice) {
        connectedDevices.remove(delegate)
    }
    
    // MARK: - CentralManager Delegate methods
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        guard let bleDevice = connectedDevices.first(where: { $0.device != nil && $0.device! == peripheral }) else {
            print("[BleUtils] didUpdateValue() - didn't found bleDevice for char: \(characteristic.uuid)")
            return
        }
        
        bleDevice.charChanged(char: characteristic)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("[BleUtils] PoweredOn")
            self.initialized = true
        }
        else {
            print("[BleUtils] Bluetooth is not available!")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        // we're discovering any devices with feedback handler
        if let discoverHandler = deviceDiscoverHandler {
            discoverHandler(peripheral, advertisementData)
            return
        }
        
        // gathering data for iBeacon devices
        if scanBeacon == true {
            if  let connectable = advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber,
                let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData,
                connectable.intValue == 0,
                let beaconDelegate = beaconDataDelegate
            {
                //print("BeaconScan(): FOUND \(peripheral.identifier) / \(advertisementData)")
                DispatchQueue.global().async {
                    beaconDelegate.dataReceived(data: data)
                }
            }
            
            return
        }
        
        // scaning for BLE devices
        if let foundPeripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String,
           let searchingName = peripheralName
        {
            // if device has a multiname (such as SensiBLE SimbaPro)
            // check for each name
            let peripheralNames = searchingName.split(separator: BleUtils.kDeviceMultiNamesSeparator, maxSplits: 5, omittingEmptySubsequences: true)
            
            if peripheralNames.first(where: { foundPeripheralName.contains($0) }) != nil || foundPeripheralName.contains(searchingName)
            {
                // check if this device should be found by its UUID (device was added via descovery sreen)
                if let uuid = DatabaseManager.deviceUUIDfor(lookupName: searchingName), peripheral.identifier.uuidString != uuid {
                    print("[BleUtils] - didDiscover(), device: \(foundPeripheralName) UUID is not matched with UUID in database: \(uuid), skip")
                    return
                }
                
                central.stopScan()
                peripheral.advName = foundPeripheralName
                self.peripheral = peripheral
                self.semaphore!.signal()
            }
        }
    }
    
    func centralManager(_ didConnectcentral: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if self.peripheral == peripheral {
            self.peripheral!.discoverServices(nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if self.peripheral == peripheral {
            self.semaphore!.signal()
        }
    }
    
//    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
//        print("willRestoreState() ...")
//    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        guard let bleDevice = connectedDevices.first(where: { $0.device != nil && $0.device! == peripheral }) else {
            print("[BleUtils] didDisconnectPeripheral() - BLE device \(peripheral.name ?? "UNKNOWN") not found for notification")
            return
        }
        
        print("[BleUtils] didDisconnectPeripheral() - \(String(describing: peripheral.name))")
        bleDevice.deviceDisconnected()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        guard error == nil, let services = peripheral.services, self.peripheral == peripheral else {
            print("[BleUtils] didDiscoverSerices() error = \(error?.localizedDescription ?? "")")
            return
        }
        
        self.services.append(contentsOf: services)
        self.semaphore!.signal()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if self.peripheral == peripheral && self.service == service {
            self.semaphore!.signal()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if self.peripheral == peripheral && self.characteristic == characteristic {
            self.semaphore!.signal()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("[BleUtils] didUpdateValueForDescriptor() \(descriptor.uuid) --> \(String(describing: error))")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if self.peripheral == peripheral && self.characteristic == characteristic {
            self.semaphore!.signal()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("[BleUtils] didWriteValueForDescriptor() \(descriptor.uuid) --> \(String(describing: error))")
    }
    
    // MARK: - Convenient methods
    
    static func readInt8(data: NSData, loc: Int) -> Int8 {
        var result: Int8 = 0
        data.getBytes(&result, range: NSMakeRange(loc, 1))
        return result
    }
    
    static func readInt16(data: NSData, loc: Int) -> Int16 {
        var result: Int16 = 0
        data.getBytes(&result, range: NSMakeRange(loc, 2))
        return result
    }   

    static func readUInt16(data: NSData, loc: Int) -> UInt16 {
        var result: UInt16 = 0
        data.getBytes(&result, range: NSMakeRange(loc, 2))
        return result
    }
    
    static func readInt24(data: NSData, loc: Int) -> Int32 {
        var result: Int32 = 0
        data.getBytes(&result, range: NSMakeRange(loc, 3))
        return result
    }
    
    static func readInt32(data: NSData, loc: Int) -> Int32 {
        var result: Int32 = 0
        data.getBytes(&result, range: NSMakeRange(loc, 4))
        return result
    }
    
    static func readFloat32BigEndian(data: Data, loc: Int = 0) -> Float {
        return Float(bitPattern: UInt32(bigEndian: data.withUnsafeBytes{ $0.pointee }))
    }
}
