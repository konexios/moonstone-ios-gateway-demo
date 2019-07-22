//
//  SettingsViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 31/03/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit
import AcnSDK

class SettingsViewController: UITableViewController {

    @IBOutlet weak var sendingRateTextField: UITextField!
    @IBOutlet weak var heartbeatTextField: UITextField!
    @IBOutlet weak var locationServicesSwitch: UISwitch!    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settings = DatabaseManager.sharedInstance.settings!
        
        locationServicesSwitch.setOn(settings.locationServices, animated: false)
        sendingRateTextField.text = String(settings.devicePollingInterval)
        heartbeatTextField.text = String(settings.heartbeatInterval)
        
        setupUI()
        setupToolbar()
    }
    
    func setupUI() {
        tableView.backgroundColor = .gray0
        tableView.separatorColor = .black
        
        sendingRateTextField.backgroundColor = .gray1
        sendingRateTextField.textColor = .white
        sendingRateTextField.borderStyle = .none
        
        heartbeatTextField.backgroundColor = .gray1
        heartbeatTextField.textColor = .white
        heartbeatTextField.borderStyle = .none
        
        locationServicesSwitch.onTintColor = .mainColor
    }
    
    func setupToolbar() {
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        toolbar.items = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
                         UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(doneAction))]
        toolbar.sizeToFit()
        
        sendingRateTextField.inputAccessoryView = toolbar
        heartbeatTextField.inputAccessoryView = toolbar
    }
    
    @objc func doneAction() {
        sendingRateTextField.resignFirstResponder()
        heartbeatTextField.resignFirstResponder()
    }
    
    @IBAction func locationServicesStatusChanged(_ sender: UISwitch) {
        let status = sender.isOn
        DatabaseManager.sharedInstance.saveLocationServicesStatus(status: status)
        if status {
            Location.sharedInstance.start()
        } else {
            Location.sharedInstance.stop()
        }
    }
    
    @IBAction func sendingRateDidChange(_ sender: UITextField) {
        DatabaseManager.sharedInstance.saveDevicePollingInterval(interval: (sender.text! as NSString).doubleValue)
    }
    
    @IBAction func heartbeatIntervalDidChange(_ sender: UITextField) {
        let interval = (sender.text! as NSString).doubleValue
        if interval != 0.0 {
            DatabaseManager.sharedInstance.saveHeartbeatInterval(interval: interval)
            ArrowConnectIot.sharedInstance.startHeartbeat(interval: interval, gatewayId: DatabaseManager.sharedInstance.gatewayId!)
        } else {
            heartbeatTextField.text = String(DatabaseManager.sharedInstance.settings.heartbeatInterval)
        }
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .gray1
        cell.contentView.backgroundColor = .gray1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        doneAction()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int){
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = .white
        }
    }
}
