//
//  DeviceFirmwareViewController.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import UIKit
import AcnSDK

class DeviceFirmwareViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UpgradeManagerDelegate
{
    var device: Device?

    // MARK: UI outlets
    @IBOutlet weak var firmwareVersionLabel: UILabel!
    @IBOutlet weak var logView: UITextView!
    @IBOutlet weak var upgradeButton: UIButton!
    @IBOutlet weak var firmwaresTableView: UITableView!
    
    @IBOutlet weak var infoView: InfoView!

    // firmwares data
    var firmwares = [DeviceSoftwareRelease]()

    // firmware releases tableview background controls
    var backgroundLabel: UILabel?
    var backgroundSpiner: UIActivityIndicatorView?
    
    var status: String = "" {
        didSet {
            logView.text = "\(logView.text ?? "")\(status)\r\n"
            logView.scrollRangeToVisible(NSRange(location: logView.text.count - 1, length: 1))
        }
    }
    
    // keeps main hud view
    var hudView: MBProgressHUD?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.gray0
        setupNavBarWithArrowLogo()
        
        status = "Fetching firmwares ..."
        
        createFirmwareTableBackgroundView()
        
        guard let device = device, let deviceHid = device.loadDeviceId() else {
            backgroundSpiner?.stopAnimating()
            backgroundLabel?.text = "No device id found"
            status = "Device hid not found"
            return
        }
        
        updateVersionInfo()
        
        // getting software releases
        ArrowConnectIot.sharedInstance.deviceApi.deviceSoftwareReleases(hid: deviceHid) { releases, errorMessage in
            
            self.backgroundSpiner?.stopAnimating()
            
            guard let releases = releases else {
                self.backgroundLabel?.text = Strings.kDFVCFailedToFetchReleases
                self.status = "Failed to fetch data: \(errorMessage ?? "")"
                return
            }
            
            self.status = "Found \(releases.count) releases"
            
            // store this releases
            self.firmwares = releases
            
            if releases.count == 0 {
                self.backgroundLabel?.text = Strings.kDFVCNoReleasesAvailable
            }
            
            self.firmwaresTableView.reloadData()
        }
        
        // try to update current state of the view controller
        let state = UpgradeManager.sharedInstance.currentUpgradeStateForDevice(deviceHid)
        let info = UpgradeManager.sharedInstance.stateInfoForDevice(deviceHid)

        upgradeStateUpdated(deviceHid, state: state, info: info)
    }
    
    // update software version info
    func updateVersionInfo() {
        guard let device = device else {
            firmwareVersionLabel.text = "Verson: -"
            return
        }
        
        firmwareVersionLabel.text = "Version: \(device.softwareName) \(device.softwareVersion)"
    }
    
    func createFirmwareTableBackgroundView() {
        
        let view = UIView(frame: firmwaresTableView.bounds)
        view.backgroundColor = UIColor.clear
        firmwaresTableView.backgroundView = view
        
        //let label = UILabel(frame: firmwaresTableView.bounds)
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = Strings.kDFVCGettingAvailableFirmwares
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.lightGray
        label.textAlignment = .center
        
        view.addSubview(label)
        
        label.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        label.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        let spiner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        spiner.translatesAutoresizingMaskIntoConstraints = false
        spiner.startAnimating()
        spiner.hidesWhenStopped = true
        
        view.addSubview(spiner)
        
        spiner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spiner.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -8.0).isActive = true
        
        backgroundLabel = label
        backgroundSpiner = spiner
        
        firmwaresTableView.tableFooterView = UIView()
        firmwaresTableView.backgroundView = view
    }
    
    // MARK: - TableView delegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // if there are not available firmwares - show info for user
        tableView.backgroundView?.isHidden = firmwares.count > 0
    
        return firmwares.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FirmwareTableViewCell") as! FirmwareTableViewCell
        
        let version = firmwares[indexPath.row].releaseVersion
        
        cell.nameLabel.text = firmwares[indexPath.row].releaseLabel
        cell.rightLabel.text = version
        
        if let deviceVersion = device?.softwareVersion, deviceVersion == version {
            cell.checkLabel.isHidden = false
        }
        else {
            cell.checkLabel.isHidden = true
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let deviceHid = device?.loadDeviceId() else {
            
            infoView.warnText = Strings.kDFVCCantFindDevice
            infoView.isHidden = false
            
            return
        }
        
        guard UpgradeManager.sharedInstance.canScheduleUpgradeForDevice(deviceHid) else {
            
            infoView.warnText = Strings.kDFVCCantStartAlreadyUpgrading
            
            return
        }
        
        infoView.isHidden = true
        upgradeButton.isHidden = false
        upgradeButton.isEnabled = true
    }
    
    // MARK: - UI handlers
    
    @IBAction func upgradeButtonPressed(_ sender: UIButton) {
        
        sender.isEnabled = false
        
        guard let device = device, let deviceHid = device.loadDeviceId() else {
            status = "Device is not set"
            return
        }
        
        guard let idx = firmwaresTableView.indexPathForSelectedRow else {
            status = "Upgrade release not selected"
            return
        }
        
        guard let userId = DatabaseManager.sharedInstance.currentAccount?.userId else {
            status = "User id is not found"
            return
        }
        
        guard UpgradeManager.sharedInstance.canScheduleUpgradeForDevice(deviceHid) else {
            status = Strings.kDFVCCantStartScheduleAlreadyUpgrading
            infoView.isHidden = false
            sender.isHidden = true
            infoView.warnText = Strings.kDFVCCantStartScheduleAlreadyUpgrading
            
            return
        }
        
        let release = firmwares[idx.row]
        
        // present YES/NO VC to confirm upgrading of the device to the new version
        let body = String( format: Strings.kDFVCAlertBodyConfirmToUpgrade, release.releaseVersion )
        let alertVC = UIAlertController(title: Strings.kDFVCAlertTitleConfirmToUpgrade,
                                        message: body,
                                        preferredStyle: .alert)
        
        alertVC.view.tintColor = UIColor.defaultTint
        
        let actionYes = UIAlertAction(title: Strings.kAlertYesButtonTitle, style: .default) { _ in
            self.scheduleDeviceUpgrade(deviceHid, releaseHid: release.releaseHid, userHid: userId)
        }
        
        let actionNo = UIAlertAction(title: Strings.kAlertNoButtonTitle, style: .cancel, handler: nil)
        
        alertVC.addAction(actionYes)
        alertVC.addAction(actionNo)
        
        self.present(alertVC, animated: true) {
            alertVC.view.tintColor = UIColor.defaultTint
        }
    }
    
    func scheduleDeviceUpgrade(_ deviceHid: String, releaseHid: String, userHid: String) {
        
        // try to schedule this release for update
        status = "Scheduling the device upgrade..."
        
        ArrowConnectIot.sharedInstance.softwareReleaseApi.createScheduleAndStart(category: .DEVICE, releaseHid: releaseHid, deviceHids: [deviceHid], userHid: userHid) { success, errorMessage in
            
            self.upgradeButton.isEnabled = true
            self.upgradeButton.isHidden = true
            self.infoView.isHidden = false
            
            guard success else {
                self.status = "Schedule failed with error: \(errorMessage!)"
                self.infoView.warnText = String(format: Strings.kDFVCFailToScheduleUpgrade, errorMessage!)
                
                return
            }
            
            self.status = "Schedule was created OK"
            
            // scheduling upgrade
            UpgradeManager.sharedInstance.scheduledState(deviceHid: deviceHid, releaseHid: releaseHid)
        }
    }
    
    // MARK: UpgradeManagerDelegate
    func upgradeStateUpdated(_ deviceHid: String, state: DeviceUpgradeState.State, info: [UpgradeInfoKeys: Any]) {
       
        // if we are presenting something now, dismiss it
        if state != .idle {
            dismissAnyPresentedVC()
        }
        
        upgradeButton.isHidden = true
        infoView.isHidden = true
        
        var rightSwipeEnabled = true
        
        switch state {
            
        case .error:
            let errMessage = info[.errorMessage] as? String ?? "unknown error"
            let infoStr = String(format: Strings.kDFVCFaileToUpgrade, errMessage)
            status = infoStr
            infoView.warnText = infoStr
            infoView.isHidden = false
            createHudView()
            // show hud with error
            hudView?.label.text = Strings.kDFVCHudTitleUpgradeFailed
            hudView?.mode = .customView
            hudView?.customView = UIImageView.iconExclamationTriangleSmall
            hudView?.detailsLabel.text = errMessage
            hudView?.hide(animated: true, afterDelay: 5.0)

        case .success:
            let timeStr = info[.timeString] as? String ?? "-"
            let deviceName = info[.deviceName] as? String ?? ""
            let infoStr = String(format: Strings.kUpgradeSuccessAlertBody, deviceName, timeStr)
            status = "Device upgraded successfully: \(timeStr)"
            infoView.successText = infoStr
            infoView.isHidden = false
            // show hud with success
            hudView?.label.text = Strings.kDFVCHudTitleUpgradeSuccess
            hudView?.mode = .customView
            hudView?.customView = UIImageView.iconCheckmark
            hudView?.detailsLabel.text = infoStr
            
            // update device version
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                // Show rebooting view
                self.hudView?.mode = .indeterminate
                self.hudView?.label.text = Strings.kDFVCHudTitleDeviceRebooting
                self.hudView?.detailsLabel.text = Strings.kDFVCHudDetailsDeviceRebooting
                self.hudView?.hide(animated: true, afterDelay: 25)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                self.updateVersionInfo()
            }
    
        case .scheduled:
            status = "Upgrade was scheduled OK"
            infoView.waitText = Strings.kUpgradeScheduledDefaultInfo
            infoView.isHidden = false
            hideHudView()

        case .preparing:
            createHudView()
            let infoStr = info[.info] as? String ?? ""
            status = "Preparing for upgrade: \(infoStr)"
            hudView?.label.text = Strings.kDFVCHudTitlePrepearing
            hudView?.mode = .indeterminate
            hudView?.detailsLabel.text = infoStr
            rightSwipeEnabled = false

        case .downloading:
            createHudView()
            hudView?.label.text = Strings.kDFVCHudTitleDownloading
            hudView?.mode = .determinateHorizontalBar
            hudView?.progress = Float( info[.progress] as? Double ?? 0.0 )
            hudView?.detailsLabel.text = String(format: Strings.kUpgradeDownloadingFirmware, info[.progressString] as? String ?? "0")
            rightSwipeEnabled = false

        case .upgrading:
            createHudView()
            hudView?.label.text = Strings.kDFVCHudTitleUpgrading
            hudView?.mode = .determinateHorizontalBar
            hudView?.progress = Float( info[.progress] as? Double ?? 0.0 )
            hudView?.detailsLabel.text = String(format: Strings.kUpgradeUpgradingFirmware, info[.progressString] as? String ?? "0")
            rightSwipeEnabled = false

        case .idle:
            hideHudView()
        }
        
        // fix:
        // if hud view is visible don't allow right swipe for
        // navigation controller
        navigationController?.interactivePopGestureRecognizer?.isEnabled = rightSwipeEnabled
    }
    
    private func hideHudView() {
        hudView?.hide(animated: true)
        hudView = nil
    }
    
    private func createHudView() {
        if hudView == nil {
            hudView = MBProgressHUD.showAdded(to: navigationController!.view, animated: true)
            hudView?.backgroundView.style = .solidColor
            hudView?.backgroundView.color = UIColor(white:0, alpha:0.4)
            // should set hud min size
            let minSizeWidth = self.view.bounds.width * 0.7
            let minSizeHeight = self.view.bounds.height * 0.20
            hudView?.minSize = CGSize(width: minSizeWidth, height: minSizeHeight)
        }
    }
    
    /// this method is released any presented view controller
    private func dismissAnyPresentedVC() {
        if let presentedVC = presentedViewController {
            presentedVC.dismiss(animated: true, completion: nil)
        }
    }
}
