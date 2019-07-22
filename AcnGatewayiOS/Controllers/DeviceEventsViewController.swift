//
//  DeviceEventsViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 02/08/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import AcnSDK

class DeviceEventsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var eventsTableView: UITableView!
    
    var deviceHid: String?
    var events: [DeviceEvent] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        showActivityIndicator()
        
        ArrowConnectIot.sharedInstance.deviceApi.deviceEvents(hid: deviceHid!) { (events) -> Void in
            if events != nil {
                self.events = events!
                self.eventsTableView.reloadData()
            }
            self.hideActivityIndicator()
        }
    }
    
    func setupTableView() {
        eventsTableView.dataSource = self
        eventsTableView.delegate = self
        
        eventsTableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: EventTableViewCell = tableView.dequeueReusableCell(withIdentifier: "EventTableViewCell") as! EventTableViewCell
        cell.setupCellWithEventModel(events[indexPath.row])
        return cell
    }    
}
