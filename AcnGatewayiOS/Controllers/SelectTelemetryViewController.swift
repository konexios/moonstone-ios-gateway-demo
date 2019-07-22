//
//  SelectTelemetryViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 22/12/2016.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

protocol SelectTelemetryViewControllerDelegate: class {
    func didSelectTelemetry(sender: SelectTelemetryViewController, telemetry: SensorType)
}

class SelectTelemetryViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: SelectTelemetryViewControllerDelegate?
    
    var telemetries: [SensorType] = []
    
    var device: Device? {
        didSet {
            for i in 0..<device!.deviceTelemetry.count {
                telemetries.append(device!.deviceTelemetry[i].type)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = UIImageView(image: UIImage(named:"Arrow_worm_white_nav"))
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return telemetries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "SelectTelemetryTableViewCell")
        let telemetry = telemetries[indexPath.row]
        cell!.textLabel?.text = telemetry.rawValue

        return cell!
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectTelemetry(sender: self, telemetry: telemetries[indexPath.row])
        let _ = navigationController?.popViewController(animated: true)
    }
}
