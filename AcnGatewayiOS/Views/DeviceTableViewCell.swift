//
//  DeviceTableViewCell.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 02/03/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit

class DeviceTableViewCell: UITableViewCell, UITableViewDataSource, UITableViewDelegate, DeviceDelegate {

    // constants
    static let DeviceTableViewCellBaseHeight: CGFloat = 88.0
    static let DeviceTableViewCellTelemetryHeight: CGFloat = 16.0
    
    
    @IBOutlet weak var deviceContentView: UIView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var deviceStatusLabel: UILabel!
    @IBOutlet weak var deviceSwitch: UISwitch!
    @IBOutlet weak var deviceTableView: UITableView!
    
    var deviceState: DeviceState = DeviceState.Disconnected
    
    var device: Device? {
        didSet {
            self.device!.delegate = self
            updateCell()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        applyPanelEffect(view: deviceContentView)
        
        deviceSwitch.setOn(false, animated: false)
        deviceStatusLabel.text = DeviceState.Disconnected.rawValue
        
        deviceTableView.dataSource = self
        deviceTableView.delegate = self
    }
    
    override func prepareForReuse() {
        deviceSwitch.setOn(false, animated: false)
        deviceStatusLabel.text = DeviceState.Disconnected.rawValue
        deviceState = DeviceState.Disconnected
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @IBAction func switchValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            device!.enable()
        } else {
            device!.disable()
        }
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.device!.deviceTelemetry.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "customCell")
        
        let telemetry: Telemetry = self.device!.deviceTelemetry[indexPath.row]
        
        cell!.textLabel?.text = telemetry.label
        cell!.textLabel?.textColor = telemetry.labelColor
        cell!.detailTextLabel?.text! = telemetry.value
        cell!.detailTextLabel?.textColor = telemetry.valueColor
        
        return cell!
    }
    
    // MARK: DeviceDelegate
    
    func stateUpdated(sender: Device, newState: DeviceState) {
        if self.deviceState != newState {
            self.updateState(newState: newState)
        }
    }
    
    func telemetryUpdated(sender: Device, values: [SensorType: String]) {        
        DispatchQueue.main.async {
            self.deviceTableView.reloadData()
        }
    }
    
    func statesUpdated(sender: Device, states: [String : Any]) {
        
    }
    
    func nameUpdated(sender: Device, name: String) {
        
    }
    
    // MARK: Helpers
    
    func updateState(newState: DeviceState) {
        DispatchQueue.main.async {
            self.deviceStatusLabel.text! = newState.rawValue
        }
        self.deviceState = newState
        
        if self.deviceState == DeviceState.Monitoring {
            self.deviceStatusLabel.textColor = UIColor.green
            self.device!.enableTelemetry()
        } else {
            self.deviceStatusLabel.textColor = UIColor.white
            self.device!.disableTelemetry()
        }
        
        DispatchQueue.main.async {
            self.deviceTableView.reloadData()
        }
    }
    
    func updateCell() {
        deviceNameLabel.text = device?.deviceType.rawValue
        deviceSwitch.setOn(self.device!.enabled, animated: false)
        self.updateState(newState: device!.state)
        deviceTableView.reloadData()
    }
    
    func applyPanelEffect(view: UIView) {
        let layer = view.layer
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 6, height: 6)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 5
        layer.cornerRadius = 5
    }
    
    class func cellHeightForRowCount(rowCount: Int) -> CGFloat {
        return DeviceTableViewCellBaseHeight + (CGFloat(rowCount) * DeviceTableViewCellTelemetryHeight)
    }
}
