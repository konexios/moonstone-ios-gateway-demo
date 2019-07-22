//
//  AcnGatewayiOS
//
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit

fileprivate let sectionHeaderHeight: CGFloat = 8
fileprivate let kSliderCellId = "SliderValueTableViewCell"
fileprivate let kDetailsCellId = "DetailsTableViewCell"

enum OnSemiSensorType: String {
    case led1       = "LED 1"
    case led2       = "LED 2"
    case motor1     = "Motor 1"
    case motor2     = "Motor 2"
    case rotor      = "Rotor"
    
    /// retrun config params for each of the sensors
    var params: (units: String, minValue: Int, maxValue: Int) {
        switch self {
        case .led1, .led2:
            return (units: "", minValue: OnSemiRSL10LedService.minValue, maxValue: OnSemiRSL10LedService.maxValue)
    
        case .motor1, .motor2:
            return (units: "\u{00B0}", minValue: OnSemiRSL10MotorService.minValue, maxValue: OnSemiRSL10MotorService.maxValue)
            
        case .rotor:
            return (units: "RPM", minValue: OnSemiRSL10RotorService.minValue, maxValue: OnSemiRSL10RotorService.maxValue)
        }
    }
}

class DeviceDetailsOnSemiRSL10ViewController: DeviceDetailsCommonViewController, UITableViewDataSource, UITableViewDelegate
{
    
    @IBOutlet weak var led1Value: UILabel!
    @IBOutlet weak var led2Value: UILabel!
    
    @IBOutlet weak var led1Slider: UISlider!
    @IBOutlet weak var led2Slider: UISlider!
    
    @IBOutlet weak var motor1Value: UILabel!
    @IBOutlet weak var motor1Slider: UISlider!
    
    @IBOutlet weak var motor2Value: UILabel!
    @IBOutlet weak var motor2Slider: UISlider!
    
    @IBOutlet weak var rotorValue: UILabel!
    @IBOutlet weak var rotorSlider: UISlider!
    
    @IBOutlet weak var tableView: UITableView!
    
    let tableViewTelemetries: [SensorType] = [ .light, .pir ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        view.backgroundColor = .gray0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // should update led views
        tableView.reloadSections([1, 2, 3], with: .none)
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.backgroundColor = .gray0
        tableView.contentInset = UIEdgeInsetsMake(16, 0, 0, 0)
    }
    
    /// this func is called as delegate func for
    /// table view cells when user drag the slider
    func changedValueForSensorType(_ type: OnSemiSensorType, value: Int) {
        
        guard let device = device as? OnSemiRSL10 else {
            print("[DeviceDetailsViewController for OnSemiRSL10] - changedValueForSensor() device is not OnSemiRSL10")
            return
        }
        
        switch( type ) {
        case .led1:
            device.ledService?.setValueFor(led: 0, value: value)
        
        case .led2:
            device.ledService?.setValueFor(led: 1, value: value)
            
        case .motor1:
            device.motorService?.setValueFor(motor: 0, value: value)
            
        case .motor2:
            device.motorService?.setValueFor(motor: 1, value: value)
            
        case .rotor:
            device.rotorService?.setValue(value)
        }
    }
    
    // MARK: DeviceDelegate
    
    override func stateUpdated(sender: Device, newState: DeviceState) {
        DispatchQueue.main.async {
            switch newState {
                case .Monitoring,
                     .Stopped,
                     .Error,
                     .NotFound:
                    self.tableView.reloadSections([1,2,3], with: .none)
            default: break
            }
        }
    }
    
    override func telemetryUpdated(sender: Device, values: [SensorType: String]) {
        DispatchQueue.main.async { [weak self] in
            //self?.tableView.reloadData()
            self?.tableView.reloadSections([0], with: .none)
        }
    }
    
    override func statesUpdated(sender: Device, states: [String : Any]) {
        print("[DeviceDetailsOnSemiRSL10] - states updated from cloud")
        tableView.reloadData()
    }
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        // we've got 4 section
        // 0 - telemetry section
        // 1 - led section
        // 2 - motor section
        // 3 - rotor section
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch( section ) {
        // telemetry section
        case 0:
            return tableViewTelemetries.count

        // LED section
        case 1:
            return 2
            
        // Motor section
        case 2:
            return 2
            
        // Rotor section
        case 3:
            return 1
            
        default:
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view: UIView
        
//        if section == 0 {
//            view = UIView(frame: CGRect.zero)
//        }
//        else {
            view = UIView(frame: .zero)
            view.backgroundColor = .gray0
            
            let lineView = UIView(frame: CGRect(x: 16.0, y: sectionHeaderHeight/2.0, width: tableView.bounds.width - 32, height: 1.0))
            
            lineView.backgroundColor = .darkGray
        
            view.addSubview(lineView)
            
            let labels = ["Telemetry", "LED", "Motor", "Rotor"]
            
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 10.0)
            label.textColor = .white
            label.text = labels[section]
            label.sizeToFit()
            label.frame.origin.x = ( tableView.bounds.width - label.bounds.width) / 2.0
            label.frame.origin.y = (sectionHeaderHeight - label.frame.height) / 2.0

            var backFrame = label.frame
            backFrame.origin.x -= 8
            backFrame.size.width += 16
            let backView = UIView(frame: backFrame)
            backView.backgroundColor = .gray0
            
            view.addSubview(backView)
            view.addSubview(label)
        //}
        
        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            return telemetryCellForIndexPath(indexPath)
        
        case 1:
            return ledCellForIndexPath(indexPath)
        
        case 2:
            return motorCellForIndexPath(indexPath)
            
        case 3:
            return rotorCellForIndexPath(indexPath)
            
        default:
            return UITableViewCell()
        }
    }
    
    func rotorCellForIndexPath(_ path: IndexPath) -> SliderValueTableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: kSliderCellId, for: path) as! SliderValueTableViewCell
        
        // we should set delegate before type
        // to allow read initial values for services
        cell.delegate = self
        cell.type = .rotor
        
        return cell
    }
    
    func motorCellForIndexPath(_ path: IndexPath) -> SliderValueTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kSliderCellId, for: path) as! SliderValueTableViewCell
        
        cell.delegate = self
        cell.type = path.row == 0 ? .motor1 : .motor2
        
        return cell
    }
    
    func ledCellForIndexPath(_ path: IndexPath) -> SliderValueTableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kSliderCellId, for: path) as! SliderValueTableViewCell
        
        cell.delegate = self
        cell.type = path.row == 0 ? .led1 : .led2
        
        return cell
    }
    
    func telemetryCellForIndexPath(_ path: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kDetailsCellId, for: path)
        
        if let telemetry = self.device?.getTelemetryForDisplay(type: tableViewTelemetries[path.row]) {
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return sectionHeaderHeight
        default:
            return sectionHeaderHeight
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 36.0
        }
        else {
            return 75.0
        }
    }
}

