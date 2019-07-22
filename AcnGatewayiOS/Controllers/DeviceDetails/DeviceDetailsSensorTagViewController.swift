//
//  DeviceDetailsSensorTagViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 20/04/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit

class DeviceDetailsSensorTagViewController: DeviceDetailsCommonViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var barometerLabel: UILabel!    
    @IBOutlet weak var lightLabel: UILabel!
    
    @IBOutlet weak var separatorView: UIView!
    
    @IBOutlet weak var detailsTableView: UITableView!
    
    let tableViewTelemetries: [SensorType] = [
        .irTemperature,
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        separatorView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        
        tempLabel.text = "00\u{00B0}"
        humidityLabel.text = "00%"
        
        setupTableView()
    }
    
    func setupTableView() {
        detailsTableView.dataSource = self
        detailsTableView.delegate = self
        
        detailsTableView.backgroundColor = UIColor.clear
    }
    
    func updateWithValues(values: [SensorType: String]) {
        
        for type in values.keys {
            switch type {
            case .ambientTemperature:
                DispatchQueue.main.async {
                    self.tempLabel.text = values[type]
                }
                break;
            case .humidity:
                DispatchQueue.main.async {
                    self.humidityLabel.text = values[type]
                }
                break;
            case .barometer:
                DispatchQueue.main.async {
                    self.barometerLabel.text = values[type]
                }
                break;
            case .light:
                DispatchQueue.main.async {
                    self.lightLabel.text = values[type]
                }
                break;
            default:
                DispatchQueue.main.async {
                    self.detailsTableView.reloadData()
                }
                break;
            }
        }
    }
    
    // MARK: DeviceDelegate
    
    override func telemetryUpdated(sender: Device, values: [SensorType: String]) {
        updateWithValues(values: values)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewTelemetries.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailsSensorTagTableViewCell", for: indexPath)
        
        if let telemetry = self.device?.getTelemetryForDisplay(type: tableViewTelemetries[indexPath.row]) {
            cell.textLabel?.text = telemetry.label
            cell.detailTextLabel?.text = telemetry.value
        }
        
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 20.0
    }



}
