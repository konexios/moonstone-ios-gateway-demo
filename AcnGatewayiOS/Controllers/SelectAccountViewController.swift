//
//  SelectAccountViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 27/10/2016.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation

class SelectAccountViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var accounts: [Account] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // iPhoneX fix:
        self.view.backgroundColor = .gray0
        
        setupTableView()
        setupNavigationBar()
        
        accounts = DatabaseManager.sharedInstance.accounts()
    }
    
    func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.backgroundColor = .gray0
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func setupNavigationBar() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(named: "fa-plus"), style: .plain, target: self, action: #selector(addAction))
        ]
    }
    
    @objc func addAction() {
        if let accountViewController = self.storyboard?.instantiateViewController(withIdentifier: "AccountViewController") as? AccountViewController {
            accountViewController.owner = self
            navigationController?.pushViewController(accountViewController, animated: true)
        }
    }
    
    func update() {
        accounts = DatabaseManager.sharedInstance.accounts()
        tableView.reloadData()
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        let cell: AccountTableViewCell = tableView.dequeueReusableCell(withIdentifier: "AccountTableViewCell") as! AccountTableViewCell
        cell.setupCellWithAccountModel(accounts[indexPath.row])
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let accountViewController = self.storyboard?.instantiateViewController(withIdentifier: "AccountViewController") as? AccountViewController {
            accountViewController.accountModel = accounts[indexPath.row]
            accountViewController.owner = self
            navigationController?.pushViewController(accountViewController, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
}
