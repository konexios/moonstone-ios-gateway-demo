//
//  HomeViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 02/03/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit
import AcnSDK

class HomeViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, SelectDeviceViewControllerDelegate, DeviceCommandDelegate, UpgradeManagerDelegate {

    static var instance: HomeViewController?
    
    let visibleCellNumber = 5
    
    @IBOutlet weak var mainTableView: UITableView!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var profileLabel: UILabel!
    
    var detailsControllerItems = [
        DeviceType.SiLabsSensorPuck : DeviceDetailsControllerItem(deviceName: "Silicon Labs Sensor Puck", mainColor: UIColor.sensorPuckColor(), identifier: "DeviceDetailsSensorPuckViewController", settings: ""),
        DeviceType.IPhoneDevice     : DeviceDetailsControllerItem(deviceName: "iPhone", mainColor: UIColor.iPhoneDeviceColor(), identifier: "DeviceDetailsTableViewController", settings: "DeviceSettingsCommonViewController"),
        DeviceType.ThunderboardReact     : DeviceDetailsControllerItem(deviceName: "Thunderboard", mainColor: UIColor.sensorTagColor(), identifier: "DeviceDetailsThunderboardViewController", settings: "DeviceSettingsCommonViewController"),
        DeviceType.SensorTile       : DeviceDetailsControllerItem(deviceName: "SensorTile", mainColor: UIColor.sensorTagColor(), identifier: "DeviceDetailsTableViewController", settings: "DeviceSettingsCommonViewController"),
        DeviceType.SimbaPro         : DeviceDetailsControllerItem(deviceName: "SimbaPro", mainColor: UIColor.sensorTagColor(), identifier: "DeviceDetailsTableViewController", settings: "DeviceSettingsCommonViewController"),
        DeviceType.OnSemiRSL10         : DeviceDetailsControllerItem(deviceName: "OnSemi-BLE", mainColor: UIColor.sensorTagColor(), identifier: "DeviceDetailsOnSemiRSL10ViewController", settings: "DeviceSettingsCommonViewController")
    ]
    
    var deviceTypes: [DeviceType] = [
        .SiLabsSensorPuck,
        .IPhoneDevice,
        .ThunderboardReact,
        .SensorTile,
        .SimbaPro,
        .OnSemiRSL10
    ]
    
    var devices: [Device] {
        return DeviceManager.sharedInstance.devices
    }
    
    // social events vars
    var socialEventVC: EventAttendViewController?
    
    // MARK: - Common
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.titleView = UIImageView(image: UIImage(named:"Arrow_worm_white_nav"))
        
        navigationController?.navigationBar.barTintColor = .black
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barStyle = .black
        
        title = "Arrow"
        
        view.backgroundColor = .gray0
        mainTableView.backgroundColor = .gray0
        
        HomeViewController.instance = self
        
        mainTableView.dataSource = self
        mainTableView.delegate = self
        
        // fix for animation flickering on tableview row delete
        UITableViewCell.appearance().backgroundColor = .clear

        showNavigationNormalMode()
        setupRevealViewController()
        
        // start services
        Location.sharedInstance.start()
        
        // start BL layer
        _ = BleUtils.sharedInstance
        
        // start upgrade manager and check for pending upgrades
        UpgradeManager.sharedInstance.delegate = self
        UpgradeManager.sharedInstance.processPendingStates()
        
        // resond to MQTT commands
        ArrowConnectIot.sharedInstance.deviceCommandDelegate = self
        
        if let gatewayId = DatabaseManager.sharedInstance.gatewayId {
            ArrowConnectIot.sharedInstance.gatewayApi.checkinGateway(hid: gatewayId) { success in
                if success {
                    self.gatewayConfig(hid: gatewayId)
                } else {
                    FIRCrashPrintMessage("Checkin Gateway Error")
                }
            }
        }
        
        // check and launch account registration
        if DatabaseManager.sharedInstance.currentAccount == nil {
            
            // check if we have any active events
            if SocialEventManager.sharedInstance.events.count > 0 {
                let eventVC = EventAttendViewController.controller
                eventVC.showAsQuestion = true
                present(eventVC, animated: false)

                // store for latter use
                self.socialEventVC = eventVC
                socialEventRegisterForNotification()
            }
            // if there is no active events, show usual registration controller
            else if let accountVC = self.storyboard?.instantiateViewController(withIdentifier: "AccountViewController"),
                    let navVC = self.navigationController
            {
                navVC.pushViewController(accountVC, animated: true)
            }
            else {
                print("HomeViewController() - Can not show AccountVC in current navVC")
            }
        }
        
        DeviceManager.sharedInstance.reloadDeviceList()
        
        registerForDeviceStateNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isHidden = false
        navigationController?.isToolbarHidden = true
        
        if let account = DatabaseManager.sharedInstance.currentAccount {
            profileLabel.text = account.profileName
        }

        mainTableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
   
    func setupRevealViewController() {        
        if  let rvc = self.revealViewController(),
            let menuViewController = rvc.rearViewController as? MenuTableViewController {
            
            menuViewController.rootNavigationControler = self.navigationController
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            
            view.addGestureRecognizer(rvc.panGestureRecognizer())
            view.addGestureRecognizer(rvc.tapGestureRecognizer())
        }
    }
    
    func registerForDeviceStateNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceStateChanged(_:)), name: .deviceStateChanged, object: nil)
    }
    
    // MARK: SocialEvent
    
    func socialEventRegisterForNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(socialEventSignInWithExistingAccount(_:)), name: .socialEventSignInWithExistingAccCredentials, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(socialEventVerified(_:)), name: .socialEventVerificationSuccess, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(socialEventAttendDeclined(_:)), name: .socialEventAttendDecline, object: nil)
    }
    
    // attend of social event declined
    @objc func socialEventAttendDeclined(_ notification: Notification) {
        // show usual registration controller if user does not want to attend event
        if socialEventVC != nil, let regAccVC = self.storyboard?.instantiateViewController(withIdentifier: "AccountViewController") {
            self.navigationController?.pushViewController(regAccVC, animated: true)
        }
    }
    
    // need to show create account viewcontroller
    @objc func socialEventSignInWithExistingAccount(_ notification: Notification) {
        socialEventVC?.dismiss(animated: true) {
            
            guard let accVC = self.storyboard?.instantiateViewController(withIdentifier: "AccountViewController") as? AccountViewController
            else {
                print("HomeViewController() -> Error, can not instantiate AccountViewController upon social event code verification success")
                return
            }
            
            if let dic = notification.userInfo,
               let name = dic[AccountKeys.name] as? String,
               let email = dic[AccountKeys.email] as? String,
               let pass = dic[AccountKeys.pass] as? String
            {
                accVC.signInName = name
                accVC.signInEmail = email
                accVC.signInPass = pass
            }
            
            self.navigationController?.pushViewController(accVC, animated: true)
        }
    }
    
    // vefication of eventcode was successful
    @objc func socialEventVerified(_ notification: Notification) {
        socialEventVC?.dismiss(animated: true) {
            if let dict = notification.userInfo as? [String:String], let error = dict["error"] {
                self.alert("Error Registering Gateway!", message: error)
            }
            
            self.mainTableView.reloadData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Device state notifications
    @objc func deviceStateChanged(_ notification: Notification) {
        guard let device = notification.object as? Device,
              let deviceIdx = devices.index(of: device)
        else {
            print("HomeVC() - device stated updated but device is not found in the device list")
            return
        }

        if let cell = mainTableView.cellForRow(at: IndexPath(row: 0, section: deviceIdx)) as? DeviceTableViewDarkCell {
            //print("==> State updated for device \(device.deviceType.rawValue), state: \(device.state.rawValue)")
            cell.online = device.enabled
        }
    }
    
    // MARK: Navigation
    
    func showNavigationEditMode() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction)),
            UIBarButtonItem(image: UIImage(named: "fa-plus"), style: .plain, target: self, action: #selector(addAction))
        ]        
    }
    
    func showNavigationNormalMode() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(named: "im-pencil"), style: .plain, target: self, action: #selector(editAction))
        ]
    }
    
    // MARK: Navigation actions
    
    @objc func addAction() {
        if let storyboard = storyboard,
           let selectDeviceVC = storyboard.instantiateViewController(withIdentifier: "SelectDeviceViewController") as? SelectDeviceViewController,
           let navVC = navigationController
        {
            selectDeviceVC.delegate = self
            navVC.pushViewController(selectDeviceVC, animated: true)
        }
    }
    
    @objc func editAction() {
        guard mainTableView.isEditing == false else {
            mainTableView.setEditing(false, animated: true)
            return
        }
        
        showNavigationEditMode()
        mainTableView.setEditing(!mainTableView.isEditing, animated: true)
    }
    
    @objc func doneAction() {
        showNavigationNormalMode()
        mainTableView.setEditing(!mainTableView.isEditing, animated: true)
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1 //devices.count;
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView()
        footerView.isHidden = true
        return footerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceTableViewDarkCell") as! DeviceTableViewDarkCell
        let device = devices[indexPath.section]

        cell.setupCellWith(device: device)
        cell.online = device.enabled
        
        if let deviceHid = device.loadDeviceId() {
            let state = UpgradeManager.sharedInstance.currentUpgradeStateForDevice(deviceHid)
            
            cell.upgradeInfo = UpgradeManager.sharedInstance.stateInfoForDevice(deviceHid)
            cell.upgradeState = state
        }
        else {
            cell.upgradeView.isHidden = true
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {        
        return  max( tableView.frame.size.height / CGFloat(visibleCellNumber), 100.0 )
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            DeviceManager.sharedInstance.removeDevice(index: indexPath.section)
            //tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            tableView.beginUpdates()
                tableView.deleteSections([indexPath.section], with: .automatic)
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = devices[indexPath.section]
        
        // check if this device is under upgrade
        if let deviceHid = device.loadDeviceId() {
         
            if UpgradeManager.sharedInstance.currentUpgradeStateForDevice(deviceHid) != .idle, let upgradeVC = self.storyboard?.instantiateViewController(withIdentifier: "DeviceFirmwareViewController") as? DeviceFirmwareViewController {
                
                upgradeVC.device = device
                
                self.pushWithToolbar(controller: upgradeVC)
                
                return
            }
        }
        
        if  let controllerItem = detailsControllerItems[device.deviceType],
            let deviceTelemetryViewController = self.storyboard?.instantiateViewController(withIdentifier: "DeviceDetailsBaseViewController") as? DeviceDetailsBaseViewController,
            let navVC = navigationController
        {
            deviceTelemetryViewController.device = device
            deviceTelemetryViewController.controllerItem = controllerItem
            navVC.pushViewController( deviceTelemetryViewController, animated: true )
        }
    }
    
    // MARK: SelectDeviceViewControllerDelegate
    
    func didSelectDevice(sender: SelectDeviceViewController, device: DeviceType) {
        DeviceManager.sharedInstance.addDevice(type: device)
        mainTableView.reloadData()
    }
    
    // this delegate method is invoked for the devices that support adding via discovery screen
    func didSelectDevice(sender: SelectDeviceViewController, device: DeviceType, discoverData: DeviceDiscoverData) {
        DeviceManager.sharedInstance.addDevice(type: device)
        DatabaseManager.sharedInstance.updateDeviceUUID(deviceType: device, uuid: discoverData.uuid)
        mainTableView.reloadData()
    }
    
    // MARK: DeviceCommandDelete
    
    func startDevice(hid: String) {
        if let device = findDevice(deviceID: hid) {
            DispatchQueue.main.async {
                device.enable()
                self.mainTableView.reloadData()
            }
        }
    }
    
    func stopDevice(hid: String) {
        guard let device = findDevice(deviceID: hid) else {
            return
        }
        
        // we should skip device stopping from the cloud when this device is under upgrade
        if !UpgradeManager.sharedInstance.canScheduleUpgradeForDevice(hid) {
            print("[HomeViewController] - stopDevice(\(hid), device under upgrade, request to stop has been skipped")
            return
        }
        
        DispatchQueue.global().async {
            device.disable()
        }
        
        DispatchQueue.main.async {
            self.mainTableView.reloadData()
        }
    }
    
    func updateDeviceProperty(hid: String, commandID: String, parameters: [String : AnyObject]) {
        
        guard let device = findDevice(deviceID: hid) else {
            ArrowConnectIot.sharedInstance.coreApi.coreEventFailed(hid: hid, error: "device not found", completionHandler: {_ in })
            return
        }
        
        // don't allow to change device properties if this device is upgrading the firmware
        // i.e. STDevice upgade can fail if some sensors are enabled
        guard UpgradeManager.sharedInstance.canScheduleUpgradeForDevice(hid) else {
            print("[HomeViewController] - updateDeviceProperty(\(hid)), device under upgrade, request to update has been skipped")
            ArrowConnectIot.sharedInstance.coreApi.coreEventFailed(hid: hid, error: "device is upgrading firmware", completionHandler: {_ in })
            return
        }
        
        device.saveProperties(properties: parameters)
        
        DispatchQueue.main.async {
            self.updateSettingsController()
        }
        
        ArrowConnectIot.sharedInstance.coreApi.coreEventSucceeded(hid: hid, completionHandler: {_ in })
    }
    
    func requestDeviceState(hid: String, transHid: String, parameters: [String : Any]) {
        if let device = findDevice(deviceID: hid) {
            device.updateStates(states: parameters)
            ArrowConnectIot.sharedInstance.deviceApi.deviceStateSucceeded(hid: hid, transHid: transHid) { success in }
        } else {
            ArrowConnectIot.sharedInstance.deviceApi.deviceStateFailed(hid: hid, transHid: transHid, error: "Error: Unable to find device") { success in }
        }
    }
    
    func commandDevice(hid: String) {
        print("[HomeViewController] commandDevice: \(hid)")
    }
    
    /// update software on the device
    func updateDeviceSoftware(model: SoftwareReleaseCommandModel) {
        // retransmit the message to the upgrade manager
        UpgradeManager.sharedInstance.updateSoftwareReleaseReceived(command: model)
    }

    func findDevice(deviceID: String) -> Device? {
        for device in devices {
            if device.loadDeviceId() == deviceID {
                return device
            }
        }
        return nil
    }
    
    func updateSettingsController() {
        if let topViewController = self.navigationController?.topViewController {            
            if let settingsViewController = topViewController as? DeviceSettingsViewControllerProtocol {
                settingsViewController.reloadSettings()
            }
        }
    }
    
    func cellForDeviceHid(_ deviceHid: String) -> DeviceTableViewDarkCell? {
        for (idx, device) in devices.enumerated() {
            if device.loadDeviceId() == deviceHid, let cell = mainTableView.cellForRow(at: IndexPath(row: 0, section: idx)) as? DeviceTableViewDarkCell {
                return cell
            }
        }
        
        return nil
    }
    
    // MARK: UpgradeManagerDelegate
    
    func upgradeStateUpdated(_ deviceHid: String, state: DeviceUpgradeState.State, info: [UpgradeInfoKeys: Any]) {
        
        // update cell state
        if let cell = cellForDeviceHid(deviceHid) {
            cell.upgradeInfo = info
            cell.upgradeState = state
        }
        
        // if current top view controller is upgrade VC and its device is this upgraded device
        // - forward messages to this controller to update its state
        if  let topVC = navigationController?.topViewController as? DeviceFirmwareViewController,
            let topVCdeviceHid = topVC.device?.loadDeviceId(),
            topVCdeviceHid == deviceHid
        {
            topVC.upgradeStateUpdated(deviceHid, state: state, info: info)
            
            UpgradeManager.sharedInstance.processNextPendingState()
        }
        // if top view controller is settings VC, actions VC or telemetry we should show this controller
        // if its device is this upgraded device
        else if let topVC = navigationController?.topViewController as? DeviceSettingsCommonViewController,
                let topVCdeviceHid = topVC.device?.loadDeviceId(),
                topVCdeviceHid == deviceHid
        {
            // instantiate upgrade vc and update its s
            if let upgradeVC = storyboard?.instantiateViewController(withIdentifier: "DeviceFirmwareViewControoler") as? DeviceFirmwareViewController {
                upgradeVC.device = findDevice(deviceID: deviceHid)
                
                self.popAndPushWithToolbar(controller: upgradeVC)
                
                upgradeVC.upgradeStateUpdated(deviceHid, state: state, info: info)
                
                UpgradeManager.sharedInstance.processNextPendingState()
            }            
        }
        // shoud show error information on other states
        else {
            
            switch state {
            case .success:
                reportDeviceUpgradeSuccess(info)
                
            case .error:
                reportDeviceUpgradeFailure(info)
                
            default:
                break
            }
        }
    }
    
    // MARK: Reporting upgrade success/failure
    func reportDeviceUpgradeSuccess(_ info: [UpgradeInfoKeys: Any]) {
        
        print("[HomeViewController] - reportDeviceUpgradeSuccess()")
        
        let title = Strings.kUpgradeSuccessAlertTitle
        let body = String(format: Strings.kUpgradeSuccessAlertBody, info[.deviceName] as? String ?? "UNKNOWN", info[.timeString] as? String ?? "-")
        
        alertFromRoot(title, message: body) {
            // process next pending state only when this view controller is closed
            UpgradeManager.sharedInstance.processNextPendingState()
        }
        
        // report the success
        UIApplication.shared.showLocalNotification(title: title, body: body)
    }
    
    func reportDeviceUpgradeFailure(_ info: [UpgradeInfoKeys: Any]) {
        
        print("[HomeViewController] - reportDeviceUpgradeFailure()")
        
        let title = Strings.kUpgradeFailAlertTitle
        let body = String(format: Strings.kUpgradeFailAlertBody, info[.deviceName] as? String ?? "UNKNOWN", info[.errorMessage] as? String ?? "")
        
        alertFromRoot(title, message: body) {
            // process next pending state only when this view controller is closed
            UpgradeManager.sharedInstance.processNextPendingState()
        }
        
        // report the error
        UIApplication.shared.showLocalNotification(title: title, body: body)
    }
}
