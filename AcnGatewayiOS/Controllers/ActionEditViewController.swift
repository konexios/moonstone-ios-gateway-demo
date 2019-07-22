//
//  ActionEditViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 21/07/16.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import AcnSDK

class ActionEditViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    var actionModel: ActionModel? {
        didSet {
            tempActionModel = ActionModel(model: actionModel!)
        }
    }
    var tempActionModel: ActionModel?
    var isNewAction = false
    
    var actionsViewController: ActionsViewController? {
        didSet {
            deviceHid = actionsViewController?.deviceHid
        }
    }
    var deviceHid: String?
    
    @IBOutlet weak var actionTypeButton: AcnButton!
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBOutlet weak var actionEditTableView: UITableView!
    
    var editFields: [ActionEditField] {
        if tempActionModel != nil {
            return tempActionModel!.editFields
        } else {
            return ActionModel.defaultFields
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupNavigationBar()
        
        if actionModel == nil {
            actionModel = ActionModel()
            isNewAction = true            
        } else {            
            actionTypeButton.setTitle(actionModel!.actionType.nameForDisplay, for: UIControlState.normal)
            actionTypeButton.isUserInteractionEnabled = false
            actionTypeButton.isArrowHidden = true
            
            enableSwitch.setOn(actionModel!.enabled, animated: false)
        }
        
        actionEditTableView.dataSource = self
        actionEditTableView.delegate = self
        
        actionEditTableView.tableFooterView = UIView(frame: CGRect.zero)

        NotificationCenter.default.addObserver(self, selector: #selector(ActionEditViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ActionEditViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                actionEditTableView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0)
            }            
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        actionEditTableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
    func setupUI() {
        view.backgroundColor = .gray0
        actionEditTableView.backgroundColor = .gray0
        
        enableSwitch.onTintColor = .mainColor
    }
    
    func setupNavigationBar() {
        navigationItem.titleView = UIImageView(image: UIImage(named:"Arrow_worm_white_nav"))
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(saveAction))
        ]
    }
    
    @objc func saveAction() {
        if tempActionModel!.actionType != .NoType && !tempActionModel!.criteria.isEmpty {
            actionModel?.copy(model: tempActionModel!)
            if isNewAction {
                ArrowConnectIot.sharedInstance.deviceApi.addDeviceAction(hid: deviceHid!, action: actionModel!)
                actionsViewController?.updateWithAction(action: actionModel!)
            } else {
                ArrowConnectIot.sharedInstance.deviceApi.updateDeviceAction(hid: deviceHid!, action: actionModel!)
                actionsViewController?.updateWithAction(action: nil)
            }
            let _ = navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func selectActionTypePressed(_ sender: UIButton) {
        
        let alert = UIAlertController(title: nil, message: "Please select action type", preferredStyle: .actionSheet)        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
    
        }
        alert.addAction(cancelAction)
        
        alert.addAction(alertActionForType(actionType: .SendEmail))
        alert.addAction(alertActionForType(actionType: .SkypeCall))
        alert.addAction(alertActionForType(actionType: .SkypeMeeting))
        alert.addAction(alertActionForType(actionType: .ArrowInsightAlarm))

        alert.view.tintColor = .defaultTint
        present(alert, animated: true) {
            // fix: iOS9.x tint color should be reapplyed
            alert.view.tintColor = .defaultTint
        }
    }
    
    @IBAction func enabledStateChanged(_ sender: UISwitch) {
        tempActionModel!.enabled = sender.isOn
    }
    
    func alertActionForType(actionType: ActionType) ->  UIAlertAction {
        let action = UIAlertAction(title: actionType.nameForDisplay, style: .default) { (action) in
            self.actionTypeButton.setTitle(actionType.nameForDisplay, for: UIControlState.normal)
            self.tempActionModel?.actionType = actionType
            self.actionEditTableView.reloadData()
        }
        return action        
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return editFields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: ActionEditTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ActionEditTableViewCell") as! ActionEditTableViewCell
        cell.setupCellWithActionEditField(actionEditField: editFields[indexPath.row], model: tempActionModel!)

        return cell
    }
}
