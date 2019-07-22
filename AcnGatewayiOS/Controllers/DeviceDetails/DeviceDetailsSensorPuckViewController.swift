//
//  DeviceDetailsSensorPuckViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 19/04/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit

class DeviceDetailsSensorPuckViewController: DeviceDetailsCommonViewController {
    
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var lightLabel: UILabel!
    @IBOutlet weak var UVLabel: UILabel!
    
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var bottomSeparatorView: UIView!    
    
    @IBOutlet weak var heartRateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        separatorView.backgroundColor = .gray2
        bottomSeparatorView.backgroundColor = .gray2
        
        tempLabel.text = "00\u{00B0}"
        heartRateLabel.text = "00"
        
        tempLabel.textColor = .mainColor
        humidityLabel.textColor = .mainColor
        heartRateLabel.textColor = .mainColor
    }
    
    func updateWithValues(_ values: [SensorType: String]) {
        
        for type in values.keys {
            
            if let text = values[type] {
                if text.isEmpty {
                    continue
                }
            } else {
                continue
            }
            
            switch type {
            case .heartRate:
                DispatchQueue.main.async {
                    self.heartRateLabel.text = values[type]
                }
                break
            case .ambientTemperature:
                DispatchQueue.main.async {
                    self.tempLabel.text = values[type]
                }
                break
            case .humidity:
                DispatchQueue.main.async {
                    self.humidityLabel.text = values[type]
                }
                break
            case .light:
                DispatchQueue.main.async {
                    self.lightLabel.text = values[type]
                }
                break
            case .uv:
                DispatchQueue.main.async {
                    self.UVLabel.text = values[type]
                }
                break
            default:
                break
            }
        }
    }
    
    // MARK: DeviceDelegate
    
    override func telemetryUpdated(sender: Device, values: [SensorType: String]) {
        updateWithValues(values)
    }


}
