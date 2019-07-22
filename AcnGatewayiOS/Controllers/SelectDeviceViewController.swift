//
//  SelectDeviceViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 04/03/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit

protocol SelectDeviceViewControllerDelegate: class {
    func didSelectDevice(sender: SelectDeviceViewController, device: DeviceType)
    func didSelectDevice(sender: SelectDeviceViewController, device: DeviceType, discoverData: DeviceDiscoverData)
}

class SelectDeviceViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {

    let MaxDeviceCount = 10
    
    @IBOutlet weak var deviceTableView: UITableView!
    
    weak var delegate: SelectDeviceViewControllerDelegate?
    
    var devices: [DeviceType] = [
        .SiLabsSensorPuck,
        .IPhoneDevice,
        .ThunderboardReact,
        .SensorTile,
        .SimbaPro,
        .OnSemiRSL10
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Devices"
        
        self.deviceTableView.dataSource = self
        self.deviceTableView.delegate = self
        
        self.deviceTableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func maxDeviceCount(deviceType: DeviceType) -> Int {
        switch deviceType {
        case .SiLabsSensorPuck:     return MaxDeviceCount
        case .IPhoneDevice:         return 1
        case .ThunderboardReact:    return 1
        case .SensorTile:           return 1
        case .SimbaPro:             return 1
        case .OnSemiRSL10:          return 1
            
        }
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectDeviceTableViewCell")!
        let device = devices[indexPath.row]
        cell.textLabel?.text = device.rawValue
        let count = DatabaseManager.sharedInstance.deviceCount(type: device)
        
        if count >= maxDeviceCount(deviceType: device) {
            cell.textLabel?.textColor = UIColor.gray
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let deviceType = devices[indexPath.row]
        
        // if device is allowed to be discovered via MAC address and Discovery UI
        // then show this UI to the user
        if let discoveryFilter = deviceType.discoveryFilter,
           let discoverVC = storyboard?.instantiateViewController(withIdentifier: "DiscoverDeviceListViewController") as? DiscoverDeviceListViewController,
           let navVC = navigationController
        {
            // before device discovering we have to be sure that BT is on
            if  !BleUtils.sharedInstance.enabled {
                showAlert("Bluetooth is off", message: "Please turn on Bluetooth to discover device")
                return
            }
            
            discoverVC.discoveryFilter = discoveryFilter
            discoverVC.selectDeviceHandler = { discoverData in
                
                self.delegate?.didSelectDevice(sender: self, device: deviceType, discoverData: discoverData )
                    self.navigationController?.popToViewController(HomeViewController.instance!, animated: true)
            }
            
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            navVC.pushViewController(discoverVC, animated: true)
        }
        else {
            delegate?.didSelectDevice(sender: self, device: deviceType)
            let _ = navigationController?.popViewController(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let device = devices[indexPath.row]
        let count = DatabaseManager.sharedInstance.deviceCount(type: device)
        if count >= maxDeviceCount(deviceType: device) {
            return false
        } else {
            return true
        }
    }
}
