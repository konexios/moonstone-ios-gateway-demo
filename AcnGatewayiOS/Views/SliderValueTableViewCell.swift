//
//  SlderValueTableViewCell.swift
//  AcnGatewayiOS
//
//  Created by Alexey Chechetkin on 14.03.2018.
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import UIKit

class SliderValueTableViewCell: UITableViewCell {

    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelValue: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    weak var delegate: DeviceDetailsOnSemiRSL10ViewController?
    
    var type: OnSemiSensorType? {
        didSet {
            guard let type = type else { return }
            
            let (units, minValue, maxValue) = type.params
            
            self.minValue = minValue
            self.labelName.text = type.rawValue
            self.units = units
            
            // set slider params
            slider.minimumValue = 0
            slider.maximumValue = Float(maxValue - minValue)
            slider.value = 0
            
            guard let device = delegate?.device as? OnSemiRSL10 else { self.value = 0; return }
            
            let value: UInt16
            
            switch type {
            case .led1:
                value = device.ledService?.led1Value ?? 0
                device.ledService?.led1notificationHanlder = { value in
                    self.slider.value = Float(value - minValue)
                    self.value = value
                }
                
            case .led2:
                value = device.ledService?.led2Value ?? 0
                device.ledService?.led2notificationHandler = { value in
                    self.slider.value = Float(value - minValue)
                    self.value = value
                }
            
            case .motor1:
                value = device.motorService?.motor1Value ?? 0
                device.motorService?.motor1NotificationHandler = { value in
                    self.slider.value = Float(value - minValue)
                    self.value = value
                }

            case .motor2:
                value = device.motorService?.motor2Value ?? 0
                device.motorService?.motor2NotificationHandler = { value in
                    self.slider.value = Float(value - minValue)
                    self.value = value
                }
                
            case .rotor:
                value = device.rotorService?.rotorValue ?? 0
                device.rotorService?.notificationHandler = { value in
                    self.slider.value = Float(value - minValue)
                    self.value = value
                }
            }
            
            slider.value = Float(value)
            self.value = Int(value)
        }
    }
    
    private var units: String = ""
    private var minValue: Int = 0
    
    var value: Int = 0 {
        didSet {
            let stringValue = value == 0 ? "OFF" : "\(value) \(units)"
            labelValue.text = stringValue
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        guard let type = type else {
            print("[SliderValueTableViewCell] - slider value changed but cell type is nil")
            return
        }
        
        let sliderValue = Int(sender.value)
        // update value
        value = sliderValue > 0 ?  minValue + sliderValue : 0
        delegate?.changedValueForSensorType(type, value: value)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentView.backgroundColor = .gray0
        backgroundColor = .clear
        
        slider.tintColor = .mainColor
        slider.isContinuous = false
        
        updateSliderState()
    }
    
    override func prepareForReuse() {
        updateSliderState()
    }
    
    func updateSliderState() {
        //slider.isEnabled = delegate?.device?.enabled ?? true
    }
}
