//
//  DeviceDetailsBaseViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 18/04/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit

class DeviceDetailsBaseViewController: BaseViewController, DeviceDelegate
{
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var deviceIDLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var deviceSwitch: UISwitch!
    @IBOutlet weak var separatorView: UIView!
    
    var controllerItem: DeviceDetailsControllerItem?
    
    var timer: Timer?
    
    var childViewController: DeviceDetailsCommonViewController?
    
    var device: Device? {
        didSet {
            self.device?.delegate = self
        }
    }
    
    var actionsButtonItem: UIBarButtonItem?
    var dashboardButtonItem: UIBarButtonItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.titleView = UIImageView(image: UIImage(named:"Arrow_worm_white_nav"))
        
        navigationController?.isToolbarHidden = false
        navigationController?.toolbar.barTintColor = .mainColor

        setupDeviceIDLabel()
        setupDeviceNameLabel()
        
        setupDetailsView()
        setupDeviceSwitch()
        setupDevice()
        
        setupToolbar()
    }
    
    func setupToolbar() {
        
        guard let controllerItem = controllerItem else {
            print("Error: No controller item available")
            return
        }
        
        var navigationItems: [UIBarButtonItem]
        
        let fixed = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixed.width = 20.0
        
        let flexed = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let settingsButtonItem = UIBarButtonItem(image: UIImage(named: "im-cog"), style: .plain, target: self, action: #selector(showSettings))
        let actionsButtonItem = UIBarButtonItem(image: UIImage(named: "fa-upload"), style: .plain, target: self, action: #selector(showActions))
        let dashboardButtonItem = UIBarButtonItem(image: UIImage(named: "fa-line-chart"), style: .plain, target: self, action: #selector(showDashboard))
        let fwupdateButtonItem = UIBarButtonItem(image: UIImage(named: "im-fw-update") , style: .plain, target: self, action: #selector(showFirmwareUpdate))
        fwupdateButtonItem.tintColor = UIColor.white
        
        // save items
        self.actionsButtonItem = actionsButtonItem
        self.dashboardButtonItem = dashboardButtonItem
        
        let isDeviceRegistred = device?.loadDeviceId() != nil
        
        actionsButtonItem.isEnabled = isDeviceRegistred
        dashboardButtonItem.isEnabled = isDeviceRegistred
        
        if !controllerItem.settings.isEmpty {
            // Comment this section for OTA section for a while, will return to this later
            if let dev = device, dev.firmwareUpgradable {
                navigationItems = [ fixed, settingsButtonItem, fixed, actionsButtonItem, fixed, dashboardButtonItem, flexed, fwupdateButtonItem, fixed ]
            }
            else {
                navigationItems = [ fixed, settingsButtonItem, flexed, actionsButtonItem, flexed, dashboardButtonItem, fixed ]
            }
        }
        else {
            navigationItems = [ fixed, actionsButtonItem,  flexed, dashboardButtonItem, fixed ]
        }
        
        setToolbarItems(navigationItems, animated: false)
    }
    
    /// Show device sensors settings button handler
    @objc func showSettings() {
        
        guard let item = controllerItem, item.settings.isEmpty == false else {
            print("[DeviceDetailsBaseViewController] showSettings() - settings VC name is nil")
            return
        }
        
        if navigationController?.topViewController is DeviceSettingsViewControllerProtocol {
            // already opened settigns
            return
        }
        
        if  let settingsViewController = self.storyboard?.instantiateViewController(withIdentifier: item.settings),
            var deviceSettingsViewController = settingsViewController as? DeviceSettingsViewControllerProtocol
        {
            deviceSettingsViewController.device = device
            popAndPushWithToolbar(controller: settingsViewController)
        }
    }
    
    /// Show device actions button handler
    @objc func showActions() {
        if let deviceHid = device?.loadDeviceId() {
            if let actionsViewController = self.storyboard?.instantiateViewController(withIdentifier: "ActionsViewController") as? ActionsViewController {
                actionsViewController.deviceHid = deviceHid
                
                popAndPushWithToolbar(controller: actionsViewController)
            }
        }
    }
    
    /// Show device telemetry chart button handler
    @objc func showDashboard() {
        if let deviceHid = device?.loadDeviceId() {
            if let dashboardViewController = self.storyboard?.instantiateViewController(withIdentifier: "DashboardViewController") as? DashboardViewController {
                dashboardViewController.device = device
                dashboardViewController.deviceHid = deviceHid
                
                popAndPushWithToolbar(controller: dashboardViewController)
            }
        }
    }
    
    /// Show device upgrade dashboard button handler
    @objc func showFirmwareUpdate() {
        
        guard let bleDevice = device as? BleDevice, bleDevice.firmwareUpgradable else {
            self.alert("Device Error", message: "This device does not support OTA")
            return
        }

        // if dashboard is already on the screen - doing nothing
        if navigationController?.topViewController is DeviceFirmwareViewController {
            return
        }
        
        guard let firmwareVC = self.storyboard?.instantiateViewController(withIdentifier: "DeviceFirmwareViewController") as? DeviceFirmwareViewController else {
            self.alert("Can not get view controller", message: "Firmware dashboard VC is not available")
            return
        }
        
        firmwareVC.device = bleDevice
        popAndPushWithToolbar(controller: firmwareVC)
    }
    
    func setupDetailsView() {
        let detailsViewController = self.storyboard!.instantiateViewController(withIdentifier: controllerItem!.identifier) as! DeviceDetailsCommonViewController
        detailsViewController.device = device
        
        detailsViewController.view.frame = CGRect(x: 0.0, y: 0.0, width: containerView.frame.size.width, height: containerView.frame.size.height)
        detailsViewController.view.backgroundColor = .clear
        containerView.backgroundColor = .clear

        addChildViewController(detailsViewController)
        containerView.addSubview(detailsViewController.view)
        
        detailsViewController.didMove(toParentViewController: self)
        
        childViewController = detailsViewController
    }
    
    func setupDeviceIDLabel() {
        deviceIDLabel.text = controllerItem?.deviceName
    }
    
    func setupDeviceNameLabel() {
            deviceNameLabel.text = device?.cloudName ?? controllerItem?.deviceName
    }
    
    func setupDeviceSwitch() {
        deviceSwitch.onTintColor = .mainColor
        
        if let device = device,
           device.state != .NotFound,
           device.state != .Error
        {
            deviceSwitch.setOn(device.enabled, animated: true)
        }
        else {
            deviceSwitch.setOn(false, animated: true)
        }
    }
    
    func setupDevice() {
        if device != nil {
            if (device!.enabled) {
                updateState(state: device!.state)
            }
        }
    }
    
    func updateState(state: DeviceState) {
        switch state {
        case .Monitoring:
            if let deviceID = device?.deviceUid {
                deviceIDLabel.text = deviceID.lowercased()
            }
            
        default:
            deviceIDLabel.text = state.rawValue
        }
        
        setupDeviceSwitch()
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if let device = device {
            if sender.isOn {
                if device.deviceCategory == .BLE {
                    enableBleDevice()
                } else {
                    device.enable()
                }
            } else {
                DispatchQueue.global().async {
                    device.disable()
                }
            }
        }
    }
    
    func enableBleDevice() {
        
        guard let device = device else {
            print("EnableBleDevice() device is nil")
            deviceSwitch.setOn(false, animated: false)
            return
        }
        
        if BleUtils.sharedInstance.enabled {
           
            // we are trying to enable device while scan beacon in the progerss
            if device.deviceType != .SiLabsSensorPuck && BleUtils.sharedInstance.isBeaconMode {
                deviceSwitch.setOn(false, animated: true)
                showAlert("SensorPuck is active", message: "Please disable iBeacon SensorPuck device before enabling this device")
                return
            }
            
            device.enable()
        } else {
            let alert = UIAlertController(title: "Bluetooth is off", message: "Please turn on Bluetooth to connect to device", preferredStyle: .alert)
            
            alert.view.tintColor = .defaultTint
            
            let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
                self.deviceSwitch.setOn(false, animated: true)
            })
            
            alert.addAction(action)
            alert.view.tintColor = .defaultTint
            
            present(alert, animated: true) {
                alert.view.tintColor = .defaultTint // fix: iOS9.x tint color should be reapplied
            }
        }
    }
    
    // MARK: DeviceDelegate
    
    func stateUpdated(sender: Device, newState: DeviceState) {
        childViewController?.stateUpdated(sender: sender, newState: newState)
        DispatchQueue.main.async {
            self.updateState(state: newState)
            
            let toolbarButtonsIsEnabled = sender.loadDeviceId() != nil
            self.actionsButtonItem?.isEnabled = toolbarButtonsIsEnabled
            self.dashboardButtonItem?.isEnabled = toolbarButtonsIsEnabled
        }
    }
    
    func telemetryUpdated(sender: Device, values: [SensorType: String]) {
        childViewController?.telemetryUpdated(sender: sender, values: values)
    }
    
    func statesUpdated(sender: Device, states: [String : Any]) {
        childViewController?.statesUpdated(sender: sender, states: states)
    }
    
    func nameUpdated(sender: Device, name: String) {
        deviceNameLabel.text = (sender.deviceType == .SimbaPro) ? DeviceType.SimbaPro.rawValue : name
    }    
}
