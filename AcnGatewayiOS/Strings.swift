//
//  Strings.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import Foundation


/// Base file for string resources

struct Strings {
    
    // MARK: UIAlertController
    
    static let kAlertYesButtonTitle = "Yes"
    static let kAlertNoButtonTitle = "No"
    
    
    // MARK: STDeviceFw
    
    // upgrade error messages
    static let kUpgradeAlreadyInProgress = "can't start - upgrade is already in progress"
    static let kUpgradeDeviceIsNotConnected = "can not start upgrade, device is not connected"
    static let kUpgradeWrongCrc = "can't start - wrong CRC calculated"
    static let kUpgradeWrongCrcReceived = "wrong crc checksum received"
    static let kUpgradeDataTransmissionTimeout = "data transmission timeout during upgrade"
    static let kUpgradeCantSendDeviceIsNotConnected = "can not send data, device is not connected"
    
   
    // MARK: UpgradeManager
    
    // error messages
    static let kUpgradeJobInterrupted = "upgrade job initiation was interrupted"
    static let kUpgradeDownloadInterrupted = "firmware downloading was interrupted"
    static let kUpgradeUnexpectedInterruption = "unexpected interruption"
    static let kUpgradeDownloadFailed = "failed to download firmware file"
    static let kUpgradeReadingFileFailed = "failed to read firmware file"
    static let kUpgradeMD5CheckFailed = "MD5 file checksum verification failed"
    static let kUpgradeBTNotPowered = "bluetooth is not powered on"
    static let kUpgradeDeviceNotFound = "device is not found"
    static let kUpgradeDeviceNotSupportUpgrade = "device does not support firmware upgrade"
    static let kUpgradeDeviceUpgradeIsNotSupportedByTheApp = "device is not supported for upgrade"
    static let kUpgradeFailedToConnect = "device is not connected and failed to pair"
    static let kUpgradeFailedToReadFileData = "can't read firmware file data"
    static let kUpgradeFailedCanceledByUser = "canceled by user"
    
    // informational descriptions
    static let kUpgradeReadingFile = "Reading file"
    static let kUpgradeChekingDevice = "Checking device"
    static let kUpgradeConnectingDevice = "Connecting device"
    static let kUpgradeProgressFormat = "%0.1f"
    static let kUpgradeDownloadProgressFormat = "%0.1f"
    static let kUpgradeScheduledForUpgrade = "Scheduled for upgrade"
    static let kUpgradeSuccedeedTitle = "Upgrade succeeded"
    static let kUpgradeDownloadingFirmware = "Downloading firmware %@%%..."
    static let kUpgradeUpgradingFirmware = "Upgrading firmware %@%%..."
    static let kUpgradeFailedFormat = "Failed: %@"
    
    // default states info
    static let kUpgradeSuccessDefaultInfo = "Device has been upgraded successfully"
    static let kUpgradeScheduledDefaultInfo = "The upgrade for this device was scheduled successfully. The upgrade will start automaticaly."
    static let kUpgradeIdleDefaultInfo = "Device is available to upgrade"
    static let kUpgradePrepearingDefaultInfo = "Preparing device"
    
    // UIAlertController - restarting upgrade
    // (%@ - holds device name, i.e - SIMBA-PRO)
    static let kUpgradeRestartAlertTitle = "Restart Upgrade"
    static let kUpgradeRestartAlertBody =  "The firmware upgrade for device %@ has been interrupted. Do you want to restart?"
    
    // UILocalNotification - try to start upgrade when device is already under upgrade
    // (%@ - holds device name, i.e - SIMBA-PRO)
    static let kUpgradeAlreadyInProgressNotificationTitle = "Upgrade failed"
    static let kUpgradeAlreadyInProgressNotificationBody = "Can not start the sofware upgrade for device %@. The device is already upgrading."
    
    
    // MARK: HomeViewController
    
    // UIAlertViewController / UILocalNotification - upgrade success
    static let kUpgradeSuccessAlertTitle = "Upgrade success"
    static let kUpgradeSuccessAlertBody = "The upgrade for the device %@ is succeeded, upgrade time: %@"
    
    // UIAlertViewController / UILocalNotification - upgrade failure
    static let kUpgradeFailAlertTitle = "Upgrade failed"
    static let kUpgradeFailAlertBody = "The upgrade for device %@ failed: %@"
    
    
    // MARK: DeviceFirmwareViewController
    
    // tableview background messages
    static let kDFVCGettingAvailableFirmwares = "Getting available firmwares..."
    static let kDFVCFailedToFetchReleases = "Failed to fetch available releases"
    static let kDFVCNoReleasesAvailable = "No releases available"
    
    // info view - messages
    static let kDFVCCantFindDevice = "Can not find device. Device is not registered in the IoT cloud"
    static let kDFVCCantStartAlreadyUpgrading = "Can not start upgrade, device is already upgrading"
    static let kDFVCCantStartScheduleAlreadyUpgrading = "Can not schedule device upgrade, upgrade is already in progress"
    static let kDFVCFailToScheduleUpgrade = "Failed to schedule upgrade: %@"
    static let kDFVCFaileToUpgrade = "Upgrade error: %@"
    
    // HUD view titles
    static let kDFVCHudTitleUpgradeFailed = "Failed"
    static let kDFVCHudTitleUpgradeSuccess = "Done"
    static let kDFVCHudTitleDeviceRebooting = "Rebooting..."
    static let kDFVCHudDetailsDeviceRebooting = "Device is rebooting"
    static let kDFVCHudTitleDownloading = "Downloading..."
    static let kDFVCHudTitlePrepearing = "Prepearing..."
    static let kDFVCHudTitleUpgrading = "Upgrading..."
    
    // UIAlertView - titles/body
    static let kDFVCAlertTitleConfirmToUpgrade = "Upgrade device firmware"
    static let kDFVCAlertBodyConfirmToUpgrade = "Do you want to upgrade this device to version %@?"
    
    // MARK: AccountViewController
    
    static let kACCAlertChangeAccTitle = "Change account"
    static let kACCAlertChangeAccBody = "Some devices are still upgrading, do you want to cancel firmware upgrade and switch to this account?"
}
