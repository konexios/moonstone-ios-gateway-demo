//
//  DeviceSettingsCommonViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 13/09/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

class DeviceSettingsCommonViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate, DeviceSettingsViewControllerProtocol {
    
    @IBOutlet weak var tableView: UITableView!
    
    var device: Device?
    
    var deviceProperties: [DeviceProperty]? {
        if let device = device {
            switch device.deviceType {
            case .IPhoneDevice:         return IPhoneDeviceProperty.allValues
            case .ThunderboardReact:    return ThunderboardProperty.allValues
            case .SensorTile:           return SensorTileProperty.allValues
            case .SimbaPro:             return SimbaProProperty.allValues
            case .OnSemiRSL10:          return OnSemiRSL10Property.allValues
                
            default:                    return nil
            }
        }
        else {
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = UIImageView(image: UIImage(named:"Arrow_worm_white_nav"))
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.backgroundColor = .gray0
        tableView.separatorColor = .black
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if deviceProperties != nil {
            return deviceProperties!.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: SensorEnableTableViewCell = tableView.dequeueReusableCell(withIdentifier: "SensorEnableTableViewCell") as! SensorEnableTableViewCell
        cell.device = device        
        if deviceProperties != nil {
            cell.setupCellWithProperty(property: deviceProperties![indexPath.row])
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Sensors"
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int){
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .white
        }
    }
    
    // MARK: DeviceSettingsViewControllerProtocol
    
    func reloadSettings() {
        self.tableView.reloadData()
    }
}
