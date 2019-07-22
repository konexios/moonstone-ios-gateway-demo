//
//  EventPopoverSelectionViewController.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import UIKit

class EventPopoverSelectionViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIPopoverPresentationControllerDelegate
{
    static let controllerId = "EventPopoverSelectionViewController"

    @IBOutlet weak var pickerView: UIPickerView!
    
    // handler that would be called when selection is happened
    var selectionHandler: ( (SocialEvent) -> Void )?
    
    var availableEvents: [SocialEvent]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        pickerView.selectRow(0, inComponent: 0, animated: true)
    }
    
    // MARK: - Popover presentation delegate methods
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    // MARK: - PickerView datasource and delegate methods
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return availableEvents!.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return availableEvents![row].name
    }
    
    // notify back of selected event
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let event = availableEvents?[row] {
            selectionHandler?( event )
        }
    }
}
