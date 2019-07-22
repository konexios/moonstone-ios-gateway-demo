//
//  DeviceDetailsTableViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 08/07/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

class DeviceDetailsTableViewController: DeviceDetailsCommonViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var tableViewTelemetries: [SensorType] {
        if let device = device {
            switch device.deviceType {
            case .IPhoneDevice:
                return [
                    .accelerometerX,
                    .accelerometerY,
                    .accelerometerZ,
                    .gyroscopeX,
                    .gyroscopeY,
                    .gyroscopeZ,
                    .magnetometerX,
                    .magnetometerY,
                    .magnetometerZ
                ]
            case .ThunderboardReact:
                return  [
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
            case .SensorTile:
                return [
                    .ambientTemperature,
                    .surfaceTemperature,
                    .humidity,
                    .pressure,
                    .micLevel,
                    .switchStatus,
                    .accelerometerX,
                    .accelerometerY,
                    .accelerometerZ,
                    .gyroscopeX,
                    .gyroscopeY,
                    .gyroscopeZ,
                    .magnetometerX,
                    .magnetometerY,
                    .magnetometerZ
                ]
                
            case .SimbaPro:
                return [
                    .temperature,
                    .light,
                    .humidity,
                    .pressure,
                    .micLevel,
                    .accelerometerX,
                    .accelerometerY,
                    .accelerometerZ,
                    .gyroscopeX,
                    .gyroscopeY,
                    .gyroscopeZ,
                    .magnetometerX,
                    .magnetometerY,
                    .magnetometerZ
                ]
                
            case .OnSemiRSL10:
                return [
                    .light,
                    .pir
                ]
                
            default:
                return []
            }
        }
        return []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()       
        setupTableView()
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.backgroundColor = .gray0
        tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0)
    }
    
    // MARK: DeviceDelegate
    
    override func stateUpdated(sender: Device, newState: DeviceState) {
        
    }
    
    override func telemetryUpdated(sender: Device, values: [SensorType: String]) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewTelemetries.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailsTableViewCell", for: indexPath)
        
        if let telemetry = self.device?.getTelemetryForDisplay(type: self.tableViewTelemetries[indexPath.row]) {
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
