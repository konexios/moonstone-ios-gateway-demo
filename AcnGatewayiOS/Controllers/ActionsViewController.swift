//
//  ActionsViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 21/07/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import AcnSDK

class ActionsViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var actionsTableView: UITableView!

    var actions: [ActionModel] = []   
    
    var deviceHid: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: nil)
        navigationItem.titleView = UIImageView(image: UIImage(named:"Arrow_worm_white_nav"))
        
        view.backgroundColor = .gray0
        
        setupTableView()
        setupNavigationBar()
        
        showActivityIndicator()
        
        ArrowConnectIot.sharedInstance.deviceApi.deviceActions(hid: deviceHid!) { (actions) -> Void in
            if actions != nil {
                self.actions = actions!
                self.actionsTableView.reloadData()
            }            
            self.hideActivityIndicator()
        }
    }
    
    func setupTableView() {
        actionsTableView.dataSource = self
        actionsTableView.delegate = self
        
        actionsTableView.backgroundColor = .gray0
        actionsTableView.separatorColor = .black
        actionsTableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func setupNavigationBar() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.organize, target: self, action: #selector(eventsAction)),
            UIBarButtonItem(image: UIImage(named: "fa-plus"), style: .plain, target: self, action: #selector(addAction))
        ]
    }
    
    @objc func eventsAction() {
        if let eventsViewController = self.storyboard?.instantiateViewController(withIdentifier: "DeviceEventsViewController") as? DeviceEventsViewController {
            eventsViewController.deviceHid = deviceHid
            pushWithToolbar(controller: eventsViewController)
        }
    }
    
    @objc func addAction() {
        if let actionEditViewController = self.storyboard?.instantiateViewController(withIdentifier: "ActionEditViewController") as? ActionEditViewController {
            actionEditViewController.actionsViewController = self
            pushWithToolbar(controller: actionEditViewController)
        }
    }
    
    func updateWithAction(action: ActionModel?) {
        if action != nil {
            actions.append(action!)
        }
        actionsTableView.reloadData()       
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        let cell: ActionTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ActionTableViewCell") as! ActionTableViewCell
        cell.setupCellWithActionModel(model: actions[indexPath.row], deviceHid: deviceHid!)
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let actionEditViewController = self.storyboard?.instantiateViewController(withIdentifier: "ActionEditViewController") as? ActionEditViewController {
            actionEditViewController.actionsViewController = self
            actionEditViewController.actionModel = actions[indexPath.row]
            pushWithToolbar(controller: actionEditViewController)
        }

    }
    
}
