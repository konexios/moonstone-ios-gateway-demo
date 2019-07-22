//
//  MenuTableViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 12/05/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit

enum MenuItem: String {
    case Accounts
    case Settings
    case About
}

class MenuTableViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    var rootNavigationControler: UINavigationController?
    
    let items: [MenuItem] = [
        .Accounts,
        .Settings,
        .About
    ]
    
    let controllers: [MenuItem : String] = [
        .Accounts : "SelectAccountViewController",
        .Settings : "SettingsViewController",
        .About    : "AboutViewController",
    ]

    @IBOutlet weak var gradientView: GradientView!    
    @IBOutlet weak var profileLabel: UILabel!
    @IBOutlet weak var dateLastLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientView()
        setupStatusBar()
        setupTableView()
        
        separatorView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)        
        dateLastLabel.text = "last used \(DatabaseManager.sharedInstance.lastUsedDateString)"
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.backgroundColor = .clear
        tableView.contentInset = UIEdgeInsetsMake(0, -15, 0, 0)
    }
    
    func setupStatusBar() {
        let statusBarView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: 20.0))
        statusBarView.backgroundColor = .mainColor
        view.addSubview(statusBarView)
    }
    
    func setupGradientView() {
        
        let layer = gradientView.layer as! CAGradientLayer
        
        layer.startPoint = CGPoint(x: 0.5, y: 0.5)
        layer.endPoint = CGPoint(x: 1.0, y: 1.0)
        
        layer.colors = [UIColor.mainColor.cgColor,
                        UIColor.mainColor3.cgColor]
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuTableViewCell", for: indexPath)
        let item = items[indexPath.row]
        
        cell.textLabel?.text = item.rawValue
        
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.detailTextLabel?.textColor = .white
       
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.revealViewController().revealToggle(animated: true)
        
        let item = items[indexPath.row]        
        
        if let identifier = controllers[item] {
            if let settingsViewController = self.storyboard?.instantiateViewController(withIdentifier: identifier) {
                self.rootNavigationControler?.pushViewController(settingsViewController, animated: false)
            }
        }
    }
}
