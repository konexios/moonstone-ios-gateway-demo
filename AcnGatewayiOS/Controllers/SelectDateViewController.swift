//
//  SelectDateViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 22/12/2016.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

protocol SelectDateViewControllerDelegate: class {
    func didSelect(sender: SelectDateViewController, fromDate: Date, toDate: Date)
}

class SelectDateViewController: BaseViewController {
    
    @IBOutlet weak var fromDatePicker: UIDatePicker!
    @IBOutlet weak var toDatePicker: UIDatePicker!

    var fromDate: Date = Date()
    var toDate: Date = Date()
    
    weak var delegate: SelectDateViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationBar()
        
        fromDatePicker.maximumDate = Date()
        toDatePicker.maximumDate = Date()
        
        fromDatePicker.date = fromDate
        toDatePicker.date = toDate
    }
    
    func setupWith(fromDate: Date, toDate: Date) {
        self.fromDate = fromDate
        self.toDate = toDate
    }
    
    func setupNavigationBar() {
        navigationItem.titleView = UIImageView(image: UIImage(named:"Arrow_worm_white_nav"))
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveAction))
        ]
    }
    
    @objc func saveAction() {
        if fromDatePicker.date.timeIntervalSince1970 < self.toDatePicker.date.timeIntervalSince1970 {
            delegate?.didSelect(sender: self, fromDate: fromDatePicker.date, toDate: toDatePicker.date)
            let _ = navigationController?.popViewController(animated: true)
        }
    }    
}
