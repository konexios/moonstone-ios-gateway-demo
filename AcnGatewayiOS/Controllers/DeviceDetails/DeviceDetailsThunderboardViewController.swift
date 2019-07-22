//
//  DeviceDetailsThunderboardViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 08/08/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

class DeviceDetailsThunderboardViewController: DeviceDetailsCommonViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var led1Button: UIButton!
    @IBOutlet weak var led2Button: UIButton!
    
    var led1isOn = false
    var led2isOn = false
    
    var led1ButtonText: String {
        let text = led1isOn ? "LED 1 - ON" : "LED 1 - OFF"
        return text
    }
    
    var led2ButtonText: String {
        let text = led2isOn ? "LED 2 - ON" : "LED 2 - OFF"
        return text
    }
    
    var led1ButtonColor: UIColor {
        let color = led1isOn ? UIColor.led1Color() : UIColor.white
        return color
    }
    
    var led2ButtonColor: UIColor {
        let color = led2isOn ? UIColor.led2Color() : UIColor.white
        return color
    }
    
    let tableViewTelemetries: [SensorType] = [
        .temperature,
        .humidity,
        .uv,
        .light,
        .accelerometerX,
        .accelerometerY,
        .accelerometerZ,
        .orientationAlpha,
        .orientationBeta,
        .orientationGamma
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateLedsStatus()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLedButton(0, button: led1Button)
        updateLedButton(1, button: led2Button)
        
        view.backgroundColor = .gray0
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.backgroundColor = .gray0
        tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
    }
    
    func updateLedsStatus() {
        if let thunderboard = device as? Thunderboard {
            led1isOn = thunderboard.isLedOn(led: 0)
            led2isOn = thunderboard.isLedOn(led: 1)
        }
    }
    

    @IBAction func led1ButtonPressed(_ sender: UIButton) {
        if let thunderboard = device as? Thunderboard {
            if thunderboard.ledService != nil {
                led1isOn = !led1isOn
                updateLedButton(0, button: sender)
                thunderboard.toggleLed(led: 0)
            }            
        }
    }
    
    @IBAction func led2ButtonPressed(_ sender: UIButton) {
        if let thunderboard = device as? Thunderboard {
            if thunderboard.ledService != nil {
                led2isOn = !led2isOn
                updateLedButton(1, button: sender)
                thunderboard.toggleLed(led: 1)
            }            
        }
    }
    
    func updateLedButton(_ led: UInt, button: UIButton) {
        if led == 0 {
            button.setTitle(led1ButtonText, for: UIControlState())
            button.setTitleColor(led1ButtonColor, for: UIControlState())
        } else {
            button.setTitle(led2ButtonText, for: UIControlState())
            button.setTitleColor(led2ButtonColor, for: UIControlState())
        }
    }
    
    // MARK: DeviceDelegate
    
    override func stateUpdated(sender: Device, newState: DeviceState) {
        
    }
    
    override func telemetryUpdated(sender: Device, values: [SensorType: String]) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    override func statesUpdated(sender: Device, states: [String : Any]) {
        
        updateLedsStatus()
        
        updateLedButton(0, button: led1Button)
        updateLedButton(1, button: led2Button)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewTelemetries.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailsTableViewCell", for: indexPath)
        
        if let telemetry = self.device?.getTelemetryForDisplay(type: self.tableViewTelemetries[(indexPath as NSIndexPath).row]) {
            cell.textLabel?.text = telemetry.label
            cell.detailTextLabel?.text = telemetry.value
        }
        
        cell.contentView.backgroundColor = .gray0
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .white
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 25.0
    }
}
