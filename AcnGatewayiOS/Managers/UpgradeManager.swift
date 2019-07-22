//
//  UpgradeManager.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import Foundation
import CoreBluetooth
import AcnSDK

/// enum keys for info dictionary of upgrade notifications
enum UpgradeInfoKeys {
    case errorMessage       // holds error message
    case successMessage     // holds success message
    case progress           // holds 0..1 double
    case deviceName         // holds device name
    case timeString         // holds formatted time string
    case fileSizeString     // holds formatted file size string
    case progressString     // holds formatted progress string
    case info               // holds additional info string
}

/// Delegate to notify status of upgrade process
protocol UpgradeManagerDelegate: class {
    func upgradeStateUpdated(_ deviceHid: String, state: DeviceUpgradeState.State, info: [UpgradeInfoKeys : Any])
}

/// Upgrade manager is used to support firmware update over the air
class UpgradeManager {
    
    // singleton
    static let sharedInstance = UpgradeManager()
    
    weak var delegate: UpgradeManagerDelegate?
    
    // holds reachability object
    private var iotReachability: Reachability?
    
    // holds pended states for all objects
    // that were not processed
    private var pendedStates = [DeviceUpgradeState]()
    
    
    // init is occured only once when app is starting
    private init() {
        print("[UpgradeManager] - initialized()")
        
        // to prevent current account upgrade state from bloating
        // we should clear all the records with .idle state
        clearAllWithState(.idle)
        
        let iotHost = Connection.iotHost
        print("[UpgradeManager] - setting reachability with host: \(iotHost)")
        iotReachability = Reachability(hostname: iotHost)
        
        iotReachability?.whenReachable = { _ in
            print("[UpgradeManager] - the internet connection to the host \(iotHost) is available")
            DispatchQueue.main.async {
                self.processPendedTransactions()
            }
        }
        
        iotReachability?.whenUnreachable = { _ in
            print("[UpgradeManager] - the internet connection to the host \(iotHost) is lost")
        }
        
        // start monitoring
        try? iotReachability?.startNotifier()
    }
    
    
    //  handle all the states
    func processPendingStates() {
        
        guard let states = DatabaseManager.sharedInstance.currentAccount?.upgradeStates else {
            // nothing to process
            print("[UpgradeManager] - processing, no pending states...")
            
            return
        }
        
        // iterate for all states and skip all idle states
        // though all idle states should be deleted
        states.forEach { if $0.state != .idle { self.pendedStates.append($0) } }

        processNextPendingState()
    }
    
    /// process next pending state
    func processNextPendingState() {
        
        guard let state = pendedStates.popLast() else {
            // no pended states available
            //print("[UpgradeManager] - all pending states were processed")
            
            return
        }
        
        switch state.state {
            
        case .scheduled:
            errorState(deviceHid: state.deviceHid, errorMessage: Strings.kUpgradeJobInterrupted)
            
        case .downloading:
            errorState(deviceHid: state.deviceHid, errorMessage: Strings.kUpgradeDownloadInterrupted)
            
        // try to recover upgrade process for this device
        case .preparing, .upgrading:
            recoverUpgradeForState(state)
            
        case .error:
            errorState(deviceHid: state.deviceHid, errorMessage: Strings.kUpgradeUnexpectedInterruption)
            
        case .success:
            successState(deviceHid: state.deviceHid)    // maybe we should set the state as .idle
            
        default:
            break
        }
    }
    
    /// process pended transactions
    /// the pended transactions are those, who were not
    /// confirmed as succeeded or failed, unconfirmed transactions
    /// prevent to scheduling new firmware upgrade jobs
    func processPendedTransactions() {
        guard let trans = DatabaseManager.sharedInstance.currentAccount?.pendedUpgradeTransactions, trans.count > 0 else {
            // the list is empty
            return
        }
        
        print("[UpgradeManager] - processPendedTransactions(), processing \(trans.count) pending transaction")
        
        // we're trying to confirm each of the pended transactions only once
        // and remove that transaction from the list, because we don't have options
        // to check why request is failed to complete
        trans.forEach { trans in
            
            switch trans.type {
             
            case .failure:
                ArrowConnectIot.sharedInstance.softwareReleaseApi.transactionFailed(hid: trans.transactionHid, error: trans.message) { success in
                    print("[UpgradeManager] - processPendedTransactions(), failure transaction: \(trans.transactionHid) \(success ? "was confirmed OK" : "failed to confirm")")
                }
                
            case .success:
                ArrowConnectIot.sharedInstance.softwareReleaseApi.transactionSucceeded(hid: trans.transactionHid) { success in
                    print("[UpgradeManager] - processPendedTransactions(), success transaction: \(trans.transactionHid) \(success ? "was confirmed OK" : "failed to confirm")")
                }
            }
        }
        
        // we should remove all transactions
        DatabaseManager.sharedInstance.clearAllUpgradePendedTransactions()
    }
    
    /// try to restart upgrade for state
    func recoverUpgradeForState(_ state: DeviceUpgradeState) {
        
        // reset cancel state
        DatabaseManager.sharedInstance.with {
            state.canceled = false
        }
        
        let body = String(format: Strings.kUpgradeRestartAlertBody, state.deviceName)
        
        let alertVC = UIAlertController(title: Strings.kUpgradeRestartAlertTitle,
                                        message: body,
                                        preferredStyle: .alert)
        
        alertVC.view.tintColor = .defaultTint
        
        // user wants to restart the upgrade (not from sratch)
        // by this time, the firmware file is still exists on the disk and MD5 checked
        // so we should to move current state to .preparing
        let actionYes = UIAlertAction(title: Strings.kAlertYesButtonTitle, style: .default) { _ in
            self.preparingState(deviceHid: state.deviceHid)
        }
        
        // user is already knows, that upgrade process for this device was interrupted
        // so we should just fail the transaction and set the idle state
        let actionNo = UIAlertAction(title: Strings.kAlertNoButtonTitle, style: .cancel) { _ in
            self.transactionFailed(deviceHid: state.deviceHid)
        }
        
        alertVC.addAction(actionYes)
        alertVC.addAction(actionNo)
        
        UIApplication.shared.keyWindow?.rootViewController?.present(alertVC, animated: true) {
            alertVC.view.tintColor = .defaultTint
        }
    }
    
    /// clear all records for given state
    func clearAllWithState(_ state: DeviceUpgradeState.State) {
        
        print("[UpgradeManager] - clearing all records for state \(state.rawValue)...")
        
        guard let states = DatabaseManager.sharedInstance.currentAccount?.upgradeStates else {
            // nothing to process
            print("[UpgradeManager] - clearAllWithState(), states list is empty...")
            
            return
        }

        // clearing the idle states
        var keepClearing: Bool
        
        repeat {
            keepClearing = false
            for (idx, obj) in states.enumerated() {
                if obj.state == state {
                    DatabaseManager.sharedInstance.with {
                        states.remove(at: idx)
                    }
                    print("[UpgradeManager] - clearAllWithState(), removed idle state for device \(obj.deviceHid)")
                    keepClearing = true
                    break
                }
            }
        } while keepClearing
    }
    
    /// initiate software update for device
    func checkAndStartDeviceUpgrade(_ deviceHid: String, transactionHid: String, fileToken: String, md5checksum: String) {
        
        // check if we have such device
        guard let device = DeviceManager.sharedInstance.deviceWithHid(deviceHid) else {
            print("[UpgradeManager] - checkAndStartDeviceUpgrade(), device with hid: \(deviceHid) not found, update skipped")
            return
        }
        
        let state = currentUpgradeStateForDevice(deviceHid)
        
        // only idle devices can be upgraded
        guard state == .idle || state == .scheduled else {
            print("[UpgradeManager] - checkAndStartDeviceUpgrade(), device \(deviceHid) is not in idle state")
            // we should fail the transaction
            ArrowConnectIot.sharedInstance.softwareReleaseApi.transactionFailed(hid: transactionHid, error: "Device is already in upgrade state")
            { success in
                assert(Thread.isMainThread)
                
                let body = String(format: Strings.kUpgradeAlreadyInProgressNotificationBody, device.deviceType.rawValue)
                
                UIApplication.shared.showLocalNotification(title: Strings.kUpgradeAlreadyInProgressNotificationTitle,
                                                           body: body)
            }
            
            return
        }
        
        downloadingState(deviceHid: deviceHid, fileToken: fileToken, md5checksum: md5checksum, transactionHid: transactionHid)
    }
    
    /// report to the manager that mqtt command to upgrade device is received
    func updateSoftwareReleaseReceived(command model: SoftwareReleaseCommandModel) {
        
        // we should confirm trasaction
        let transId = model.softwareReleaseTransHid
        let deviceId = model.hid
        let md5Original = model.md5Checksum.trimmedLowercased
        
        // confirm transaction as recieved
        // TODO: in any case the transaction should be marked as recieved otherwise
        // the upgrade job will be holding as incompleted, may be we should add the internet
        // checking first and if internet connection is unavailable to postpone the confirmance later
        // The chance of that case is very low, because update mqtt command has come and the internet connection is
        // active.
        ArrowConnectIot.sharedInstance.softwareReleaseApi.transactionReceived(hid: transId) {  [unowned self]
            success in
            
            print("[UpgradeManager] - updateSoftwareReleaseReceived(), transaction received - \(success ? "OK" : "Failed")")
            
            // not confirmed
            guard success else {
                return
            }
            
            // try to update this device
            self.checkAndStartDeviceUpgrade(deviceId, transactionHid: transId, fileToken: model.tempToken, md5checksum: md5Original)
        }
    }
    
    // MARK: Upgrade states
    
    /// set error state for the device with error message
    func errorState(deviceHid: String, errorMessage: String) {
        
        guard let state = DatabaseManager.sharedInstance.upgradeStateForDevice(deviceHid) else {
            print("[UpgradeManager] - errorState() failed to get state for device \(deviceHid), state is not in the DB")
            return
        }
        
        print("[UpgradeManager] - errorState(), set error state for device \(deviceHid): \(errorMessage)")

        DatabaseManager.sharedInstance.with {
            state.state = .error
            state.errorMessage = errorMessage
        }
        
        // notify delegate
        delegate?.upgradeStateUpdated(deviceHid, state: .error, info: [.deviceName: state.deviceName,
                                                                       .errorMessage: errorMessage])
        // mark this transaction as failed
        transactionFailed(deviceHid: deviceHid)
    }
    
    /// set success state for the device
    func successState(deviceHid: String) {
        
        guard let state = DatabaseManager.sharedInstance.upgradeStateForDevice(deviceHid) else {
            print("[UpgradeManager] - successState() failed to get state for device \(deviceHid), state is not in the DB")
            return
        }
        
        print("[UpgradeManager] - successState() set success state for device \(deviceHid)")
        
        DatabaseManager.sharedInstance.with {
            state.state = .success
        }
        
        // as info we pass total upgrade time
        let upgradeTime = CACurrentMediaTime() - state.startUpgradeTime        
        //let upgradeTimeStr = String(format: "%d seconds", Int(upgradeTime))
        
        let dateFormatter = DateComponentsFormatter()
        dateFormatter.allowedUnits = [.minute, .second]
        let upgradeTimeStr = dateFormatter.string(from: upgradeTime) ?? ""
        
        // notify delegate
        delegate?.upgradeStateUpdated(deviceHid, state: .success, info: [.timeString: "\(upgradeTimeStr) m",
                                                                         .deviceName : state.deviceName])
        // mark the transaction as succeeded
        transactionSucceeded(deviceHid: deviceHid)
    }
    
    /// set idle state for the device
    /// the idle state is the default state and
    func idleState(deviceHid: String) {
        
        guard let state = DatabaseManager.sharedInstance.upgradeStateForDevice(deviceHid) else {
            print("[UpgradeManager] - idleState() failed to get state for device \(deviceHid), state is not in the DB")
            return
        }
        
        print("[UpgradeManager] - idleState(), setting the idle state for device: \(deviceHid)")
        
        deleteFileAtPath(state.firmwareFileUrl, info: "[UpgradeManager] - idleState()")
        
        DatabaseManager.sharedInstance.with {
            state.deviceHid = deviceHid
            state.state = .idle
        }
        
        // add this state to the current account
        DatabaseManager.sharedInstance.updateUpgradeState(state)
        
        // TODO: should we notify about idle state?
    }
    
    /// set downloading state for the device
    func downloadingState(deviceHid: String, fileToken: String, md5checksum: String, transactionHid: String) {
        
        let state: DeviceUpgradeState
        
        if let existedState = DatabaseManager.sharedInstance.upgradeStateForDevice(deviceHid)  {
            state = existedState
        }
        else {
            state = DeviceUpgradeState()
        }
        
        DatabaseManager.sharedInstance.with {
            state.deviceHid = deviceHid
            state.deviceName = deviceType(deviceHid)
            state.state = .downloading
            state.md5checksum = md5checksum
            state.fileToken = fileToken
            state.transactionHid = transactionHid
            state.canceled = false
        }
        
        // add this state to the account
        DatabaseManager.sharedInstance.updateUpgradeState(state)
        
        print("[UpgradeManager] - downloadingState(), start downloading firmware for device \(deviceHid)")
        
        delegate?.upgradeStateUpdated(deviceHid, state: .downloading, info: [.progress: Double(0.0),
                                                                             .progressString: "0"])
        
        // try to download firmware file.
        // Important: after success download, file is persisten on the disk
        // we shoud save the location and remove the file on error or success
        ArrowConnectIot.sharedInstance.softwareReleaseApi.transactionDownloadFile(
            hid: transactionHid,
            fileToken: fileToken,
            progressHandler:
        {
            // only main thread allowed
            assert(Thread.isMainThread)
            
            let progressString = String(format: Strings.kUpgradeDownloadProgressFormat, $0 * 100.0)
            
            // should notify delegate about downloading progress
            self.delegate?.upgradeStateUpdated(deviceHid, state: .downloading, info: [.progress: Double($0),
                                                                                      .progressString: progressString])

            // cancel file downloading if this upgrade was canceled
            if state.canceled {
                print("[UpgradeManager] - downloadingState(), download was canceled at progress \(progressString)%, canceling download request ...")
                if let downloadRequest = ArrowConnectIot.sharedInstance.softwareReleaseApi.downloadRequests[fileToken] {
                    downloadRequest.cancel()
                }
                else {
                    print("[UpgradeManager] - downloadingState(), download request for \(fileToken) was not found to cancel")
                }
            }
        })
        {
            [unowned self]
            success, url in
            
            // only main thread allowed
            assert(Thread.isMainThread)
            
            if state.canceled {
                return
            }
            
            guard success, let url = url else {
                print("[UpgradeManager] - downloadingState(), failed to load firmware file for device \(deviceHid)")
                
                self.errorState(deviceHid: deviceHid,
                                errorMessage: Strings.kUpgradeDownloadFailed)
                
                return
            }

            print("[UpgradeManager] - downloadinState(), reading file \(url.lastPathComponent)...")
            
            self.delegate?.upgradeStateUpdated(deviceHid, state: .downloading, info: [.progress: Double(1.0),
                                                                                      .progressString: "100",
                                                                                      .info : Strings.kUpgradeReadingFile])
                
            // try to check existanse of this file
            if FileManager.default.fileExists(atPath: url.path) {
                print("[UpgradeManager] - downloadingState(), file exits at path \(url.path)")
            }
            else {
                print("[UpgradeManager] - downloadingState(), file does not exist at path \(url.path)")
            }
            
            let data: Data
            do {
                data = try Data.init(contentsOf: url, options: [.uncached])
            }
            catch {
                print("[UpgradeManger] - downloadingState(), failed to read firmware file for device \(deviceHid), error: \(error.localizedDescription)")
                self.errorState(deviceHid: deviceHid, errorMessage: Strings.kUpgradeReadingFileFailed)
                return
            }
            
            // format file size
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB]
            let fileSize = formatter.string(fromByteCount: Int64(data.count))
            
            print("[UpgradeManager] - downloadingState(), file readed OK, file length: \(fileSize)")
            print("[UpgradeManager] - downloadingState(), checking md5 checksum for file \(url.lastPathComponent)...")
            
            let md5Downloaded = data.md5.trimmedLowercased
            
            print("[UpgradeManager] - downloadingState(), MD5 checksum: \(md5Downloaded)")
            print("[UpgradeManager] - downloadingState(), MD5 original checksum: \(md5checksum)")

            // checking MD5
            guard md5Downloaded == md5checksum else {
                print("[UpgradeManger] - downloadingState(), md5 checking failed for device \(deviceHid)")
                self.errorState(deviceHid: deviceHid, errorMessage: Strings.kUpgradeMD5CheckFailed)
                
                return
            }
            
            print("[UpgradeManager] - downloadingState(), MD5 checksum verified OK")
            
            // store firmware file properties
            DatabaseManager.sharedInstance.with {
                state.firmwareFileUrl = url.absoluteString
                state.firmwareFileSize = fileSize
            }
            
            // move to the preparing state
            self.preparingState(deviceHid: deviceHid)
        }
    }
    
    /// set preparing state for the device
    func preparingState(deviceHid: String) {
        
        guard let state = DatabaseManager.sharedInstance.upgradeStateForDevice(deviceHid) else {
            print("[UpgradeManager] - prepearingState() failed to get state for device \(deviceHid), state is not in the DB")
            return
        }
        
        if state.canceled {
            print("[UpgradeManager] - prepearingState(), upgrade was canceled for device \(deviceHid)")

            return
        }
        
        DatabaseManager.sharedInstance.with {
            state.state = .preparing
        }
        
        delegate?.upgradeStateUpdated(deviceHid, state: .preparing, info: [.deviceName: state.deviceName,
                                                                           .fileSizeString: state.firmwareFileSize,
                                                                           .info: Strings.kUpgradeChekingDevice])
        
        // check if bluetooth is powered on
        // check if the device is connected
        // check if device is upgradable
        // check if device is ST deivice
        // note: for now we only support ST device family
        
        guard BleUtils.sharedInstance.enabled else {
            print("[UpgradeManager] - preparingState(), bluetooth is not powered on")
            errorState(deviceHid: deviceHid, errorMessage: Strings.kUpgradeBTNotPowered)
            
            return
        }
        
        guard let device = DeviceManager.sharedInstance.deviceWithHid(deviceHid) else {
            print("[UpgradeManager] - preparingState(), device with id \(deviceHid) is not found")
            errorState(deviceHid: deviceHid, errorMessage: Strings.kUpgradeDeviceNotFound)

            return
        }
        
        guard let bleDevice = device as? BleDevice, bleDevice.firmwareUpgradable else {
            print("[UpgradeManager] - preparingState(), device does not support firmware upgrade")
            errorState(deviceHid: deviceHid, errorMessage: Strings.kUpgradeDeviceNotSupportUpgrade)
            
            return
        }
        
        // we support only symba-pro device for now
        guard let upgradeDevice = bleDevice as? STDevice else {
            print("[UpgradeManager] - preparingState(), this device is not supported")
            errorState(deviceHid: deviceHid, errorMessage: Strings.kUpgradeDeviceUpgradeIsNotSupportedByTheApp)
            
            return
        }
        
        switch upgradeDevice.state {
        
        case .Connected, .Monitoring:
            // device is connected, so we should go to upgrading state
            upgradingState(deviceHid: deviceHid, device: upgradeDevice)
            
        default:
            // we should try to enable and connect device again or fail
            upgradeDevice.enable()
            print("[UpgradeManager] - preparingState(), device is not connected, try to enable and start device, recheck after 5 sec...")
            
            // notify delegate
            delegate?.upgradeStateUpdated(deviceHid, state: .preparing, info: [.deviceName: state.deviceName,
                                                                               .fileSizeString: state.firmwareFileSize,
                                                                               .info: Strings.kUpgradeConnectingDevice])
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                
                if state.canceled {
                    print("[UpgradeManager] - preparingState(), recheck after timeout, upgrade was canceled")
                    
                    return
                }
                
                print("[UpgradeManager] - preparingState(), rechecking device connection state...")
                
                guard upgradeDevice.state == .Monitoring || upgradeDevice.state == .Connected else {
                    print("[UpgradeManager] - preparingState(), device is not connected")
                    self.errorState(deviceHid: deviceHid, errorMessage: Strings.kUpgradeFailedToConnect)
                    
                    return
                }
                
                print("[UpgradeManager] - preparingState(), device is paired OK")
                self.upgradingState(deviceHid: deviceHid, device: upgradeDevice)
            }
        }
    }

    /// set upgrading state for the device and start upgrade
    func upgradingState(deviceHid: String, device: BleDevice) {
        
        guard let state = DatabaseManager.sharedInstance.upgradeStateForDevice(deviceHid) else {
            print("[UpgradeManager] - upgradingState() failed to get state for device \(deviceHid), state is not in the DB")
            return
        }
        
        if state.canceled {
            print("[UpgradeManager] - upgradingState(), upgrade was canceled for device \(deviceHid)")
            
            return
        }
        
        DatabaseManager.sharedInstance.with {
            state.state = .upgrading
            state.startUpgradeTime = CACurrentMediaTime()
        }
        
        // should add delegate notification
        delegate?.upgradeStateUpdated(deviceHid, state: .upgrading, info: [.deviceName: state.deviceName,
                                                                           .progress: Double(0.0),
                                                                           .progressString: "0"])
        
        guard let fileUrl = URL(string: state.firmwareFileUrl), let data = try? Data(contentsOf: fileUrl) else {
            print("[UpgradeManager] - upgradingState(), can not read firmware data")
            errorState(deviceHid: deviceHid, errorMessage: Strings.kUpgradeFailedToReadFileData)

            return
        }
        
        // for now we support only ST device family
        guard let stDevice = device as? STDevice else {
            print("[UpgradeManager] - upgradingState(), this device is not supported")
            errorState(deviceHid: deviceHid, errorMessage: Strings.kUpgradeDeviceUpgradeIsNotSupportedByTheApp)
            
            return
        }
        
        stDevice.startUpgrade(data, notifyHandler: { progress, units in
            
            assert(Thread.isMainThread)
            //  should notify delegate
            if units % 10 == 0 {
                let progressStr = String(format: Strings.kUpgradeProgressFormat, progress * 100)
                
                // notify delegate
                self.delegate?.upgradeStateUpdated(deviceHid, state: .upgrading, info: [.deviceName: state.deviceName,
                                                                                        .progress: Double(progress),
                                                                                        .progressString: progressStr])
            }
            
            if state.canceled {
                print("[UpgradeManager] - upgradingState(), cancel upgrade for device \(deviceHid)")
                stDevice.stopUgrade()
                
                // we should disconnect with device to stop all
                // data transmission
                stDevice.disable()
                stDevice.disconnect()
            }
        })
        {
            [unowned self]
            success, errorMessage in
            
            stDevice.stopUgrade()
            
            guard success else {
                print("[UpgradeManager] - upgradingState(), upgrade failure: \(errorMessage!)")
                self.errorState(deviceHid: deviceHid, errorMessage: errorMessage!)
                
                return
            }
            
            // all went ok we should set success state
            print("[UpgradeManager] - upgradingState(), device was upgraded OK")
            
            // notify delegate
            self.delegate?.upgradeStateUpdated(deviceHid, state: .upgrading, info: [.deviceName: state.deviceName,
                                                                                    .progress: Double(1.0),
                                                                                    .progressString: "100"])

            self.successState(deviceHid: deviceHid)
            
            // usually STDevice is restarting after 5 seconds after upgrade
            // the app will try to reconnect to the device upon connection lost
            // and after 5 seconds will stop trying to reestablish the connection,
            // to prevent this case, we're trying to reestablish device connection
            // after 15 seconds after upgrade success
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                stDevice.enable()
            }
        }
    }
    
    /// set device state as scheduled with
    func scheduledState(deviceHid: String, releaseHid: String) {
        
        let state = DeviceUpgradeState()
        
        DatabaseManager.sharedInstance.with {
            state.state = .scheduled
            state.deviceHid = deviceHid
            state.userHid = DatabaseManager.sharedInstance.currentAccount?.userId ?? ""
            state.releaseHid = releaseHid
            state.deviceName = deviceType(deviceHid)
        }
        
        // add this state to the current account
        DatabaseManager.sharedInstance.updateUpgradeState(state)
        
        // nofity delegate
        delegate?.upgradeStateUpdated(deviceHid, state: .scheduled, info: [.deviceName: state.deviceName,
                                                                           .info: Strings.kUpgradeScheduledForUpgrade])
    }
    
    // MARK: Helper methods
    
    /// return device type for device with given hid
    /// - returns: found device type or "Unknown"
    private func deviceType(_ deviceHid: String) -> String {
        
        guard let device = DeviceManager.sharedInstance.deviceWithHid(deviceHid) else {
            return "Unknown"
        }
        
        return device.deviceType.rawValue
    }
    
    /// report release transaction as failed
    /// - parameter goToIdle: if true the state is changing to .idle
    func transactionFailed(deviceHid: String, goToIdle: Bool = true) {
        
        guard let state = DatabaseManager.sharedInstance.upgradeStateForDevice(deviceHid) else {
            print("[UpgradeManager] - transactionFailed() failed to get state for device \(deviceHid), state is not in the DB")
            return
        }
        
        // check if the internet connection is active, and if it's not
        // add this transaction to the account and resend the failure request when
        // internet connection will be active
        if  let reach = iotReachability, !reach.isReachable {
            print("[UpgradeManager] - transactionFailed(), network is unreachable for now, transaction \(state.transactionHid) is pended to confirm later ")
            DatabaseManager.sharedInstance.addUpgradePendedTransaction(state.transactionHid, type: .failure, message: state.errorMessage)
            
            return
        }
        
        ArrowConnectIot.sharedInstance.softwareReleaseApi.transactionFailed(hid: state.transactionHid, error: state.errorMessage) { success in
            
            if success {
                print("[UpgradeManager] - transactionFailed() transaction \(state.transactionHid) reported OK")
            }
            else {
                print("[UpgradeManager] - transactionFailed() the transaction \(state.transactionHid) is failed to report")
            }
            
            // set the idle state for the current device
            if goToIdle {
                self.idleState(deviceHid: deviceHid)
            }
        }
    }
    
    /// report release transaction as succeeded
    /// in any case the current state will be moved to .idle by default
    /// - parameter goToIdle: if true the state is changing to .idle
    func transactionSucceeded(deviceHid: String, goToIdle: Bool = true) {
        
        guard let state = DatabaseManager.sharedInstance.upgradeStateForDevice(deviceHid) else {
            print("[UpgradeManager] - transactionSucceeded() failed to get state for device \(deviceHid), state is not in the DB")
            return
        }
        
        // check if the internet connection is active, and if it's not
        // add this transaction to the account and resend the success request when
        // internet connection will be active (reachability delegate + transaction id)
        // The chance that case can happen very high.
        if  let reach = iotReachability, !reach.isReachable {
            print("[UpgradeManager] - transactionSucceeded(), network is unreachable for now, transaction \(state.transactionHid) is pended to confirm later ")
            DatabaseManager.sharedInstance.addUpgradePendedTransaction(state.transactionHid, type: .success)
            
            return
        }
        
        // confirm transaction as succeeded
        ArrowConnectIot.sharedInstance.softwareReleaseApi.transactionSucceeded(hid: state.transactionHid) { success in
            
            if success {
                print("[UpgradeManager] - transactionSucceeded() transaction \(state.transactionHid) reported OK")
            }
            else {
                print("[UpgradeManager] - transactionSucceeded() the transaction \(state.transactionHid) is failed to report")
            }
            
            // set the idle state for the current device
            if goToIdle {
                self.idleState(deviceHid: deviceHid)
            }
        }
    }
    
    /// cancel upgrade for device with deviceHid
    func cancelUpgradeForAllDevices() {
        
        print("[UpgradeManager] - canceling all upgrades...")
        
        guard let states = DatabaseManager.sharedInstance.currentAccount?.upgradeStates else {
            // nothing to process
            print("[UpgradeManager] - cancelUpgradeForAllDevices(), no states found..")
            
            return
        }

        for state in states {
            
            switch state.state {
                
            case .downloading, .preparing, .upgrading:
                print("[UpgradeManager] - cancelUpgradeForAllDevices(), cancel device upgrade for device \(state.deviceName) : \(state.deviceHid)...")
                DatabaseManager.sharedInstance.with {
                    state.canceled = true
                    state.errorMessage = Strings.kUpgradeFailedCanceledByUser
                }
                transactionFailed(deviceHid: state.deviceHid)
                
            default:
                break
            }
        }
    }
    
    /// Ask the manager wether we can start the upgrade process for the given device
    /// - parameter deviceHid: device hid
    /// - returns: true if we can start upgrade process otherwise false
    func canScheduleUpgradeForDevice(_ deviceHid: String) -> Bool {
        
        // state not found for current device, we can start / schedule upgrade
        guard let state = DatabaseManager.sharedInstance.upgradeStateForDevice(deviceHid) else {
            return true
        }
        
        // only idle state allowed to start the device upgrade
        return state.state == .idle
    }
    
    /// Get current upgrade state for the device
    /// - parameter deviceHid: device (object) hid
    /// - returns: current state of the device or .idle if state is not found
    func currentUpgradeStateForDevice(_ deviceHid: String) -> DeviceUpgradeState.State {
        
        // if state not found - default state is .idle
        guard let state = DatabaseManager.sharedInstance.upgradeStateForDevice(deviceHid) else {
            return .idle
        }
        
        return state.state
    }
    
    /// delete file at given path and put debug message with info
    /// - parameter path: the path to the file
    /// - parameter info: info message to put in debug output
    private func deleteFileAtPath(_ path: String, info: String = "") {
        
        guard let url = URL(string: path), FileManager.default.fileExists(atPath: url.path)  else {
            print("\(info) file not exists at path \(path) ...")
            
            return
        }
        
        do {
            try FileManager.default.removeItem(at: url)
            print("\(info) file at \(url.path) deleted OK")
        }
        catch {
            print("\(info) failed to delete firmware file at path \(url.path), error: \(error.localizedDescription)")
        }
    }
    
    /// helper func to get info message for current state
    /// - returns: state info for device
    func stateInfoForDevice(_ deviceHid: String) -> [UpgradeInfoKeys: Any] {
        
        // if state not found - default state is .idle
        guard let state = DatabaseManager.sharedInstance.upgradeStateForDevice(deviceHid) else {
            return [.info: ""]
        }
        
        switch  state.state {
            
        case .error:
            return [.deviceName: state.deviceName, .errorMessage: state.errorMessage]
            
        case .success:
            return [.deviceName: state.deviceName, .successMessage: Strings.kUpgradeSuccessDefaultInfo]
            
        case .scheduled:
            return [.deviceName: state.deviceName, .info: Strings.kUpgradeScheduledDefaultInfo]
            
        case .preparing:
            return [.deviceName: state.deviceName, .info: Strings.kUpgradePrepearingDefaultInfo]
            
        case .idle:
            return [.deviceName: state.deviceName, .info: Strings.kUpgradeIdleDefaultInfo]
        
        case .downloading:
            return [.deviceName: state.deviceName, .progress: Double(0.0),  .progressString: "0"]
            
        case .upgrading:
            return [.deviceName: state.deviceName, .progress: Double(0.0),  .progressString: "0"]
        }
    }
    
    /// return the count of devices that are currently upgrading, i.e.
    /// device is under upgrade when it's state is not .idle, .error, .success
    var upgradingDevicesCount: Int {
        
        guard let states = DatabaseManager.sharedInstance.currentAccount?.upgradeStates else {
            // nothing to count
            return 0
        }
        
        var count = 0
        
        for state in states {
            
            switch state.state {
            case .idle, .error, .success:
                break
                
            default:
                count += 1
            }
        }
        
        return count
    }
}
