//
//  RegisterViewController.swift
//  AcnGatewayiOS
//
//  Created by Tam Nguyen on 9/30/15.
//  Copyright © 2015 Arrow Electronics. All rights reserved.
//

import UIKit
import AcnSDK
import IHKeyboardAvoiding

class AccountViewController: BaseViewController, UITextFieldDelegate, ValidationDelegate {
    
    let registerText   = "REGISTER"
    let makeActiveText = "MAKE ACTIVE"
    let myProfileText  = "My Profile"
    let accountText    = "Account"
    
    @IBOutlet weak var textFieldProfile: AcnTextField!
    @IBOutlet weak var textFieldName: AcnTextField!
    @IBOutlet weak var textFieldEmail: AcnTextField!
    @IBOutlet weak var textFieldPassword: AcnTextField!
    @IBOutlet weak var textFieldCode: AcnTextField!
    
    @IBOutlet weak var buttonRegister: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var demoConfigurationSwitch: UISwitch!

    @IBOutlet weak var titleLable: UILabel!
    
    @IBOutlet weak var buttonRegisterHeight: NSLayoutConstraint!
    @IBOutlet weak var deleteButtonHeight: NSLayoutConstraint!
    @IBOutlet weak var logoHeight: NSLayoutConstraint!
    @IBOutlet weak var logoTopMargin: NSLayoutConstraint!
    
    var accountModel: Account?
    var owner: SelectAccountViewController?
    
    var demoConfiguration = true
    
    let validator = Validator()
    
    var viewOffsetDelta: CGFloat?
    
    // for signin with existing acc
    var signInName: String?
    var signInEmail: String?
    var signInPass: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        validator.registerField(textFieldProfile, rules: [RequiredRule()])
        validator.registerField(textFieldName, rules: [RequiredRule()])
        validator.registerField(textFieldEmail, rules: [RequiredRule(), EmailRule()])
        validator.registerField(textFieldPassword, rules: [RequiredRule()])
        validator.registerField(textFieldCode, rules: [RequiredRule()])
        
        setupUI()
        
        // prefill data from event registration phase
        if let signInName = signInName, let signInEmail = signInEmail, let signInPass = signInPass {
            textFieldName.text = signInName
            textFieldEmail.text = signInEmail
            textFieldPassword.text = signInPass
        }

        hideKeyboardOnTap()
        
        textFieldName.delegate = self
        textFieldEmail.delegate = self
        textFieldPassword.delegate = self
        textFieldCode.delegate = self
    }
    
    override var prefersStatusBarHidden: Bool {
        if DatabaseManager.sharedInstance.currentAccount == nil {
            return true
        } else {
            return false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if DatabaseManager.sharedInstance.currentAccount == nil {
            navigationController?.navigationBar.isHidden = true
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
        
        super.viewWillAppear(true)
    }
    
    func setupUI() {
        
        buttonRegister.backgroundColor = .mainColor
        buttonRegister.layer.cornerRadius = 5
        
        deleteButton.layer.cornerRadius = 5
        
        demoConfigurationSwitch.onTintColor = .mainColor
        
        if accountModel != nil {
            buttonRegisterHeight.constant = 50.0
            deleteButtonHeight.constant = 50.0
            
            logoHeight.constant = 0
            logoTopMargin.constant = 0
            
            titleLable.text = accountText
            
            setupUI(account: accountModel!)
            
            demoConfiguration = accountModel!.profileSettings!.demoConfiguration
            demoConfigurationSwitch.setOn(demoConfiguration, animated: false)
        } else {
            deleteButton.isHidden = true
            
            buttonRegisterHeight.constant = 50.0
            deleteButtonHeight.constant = 0.0
            
            if DatabaseManager.sharedInstance.currentAccount == nil {
                navigationController?.navigationBar.isHidden = true
                textFieldProfile.text = myProfileText
            } else {
                logoHeight.constant = 0
                logoTopMargin.constant = 0
                textFieldProfile.text = "\(myProfileText) \(DatabaseManager.sharedInstance.accounts().count + 1)"
            }
            
            demoConfiguration = true
            demoConfigurationSwitch.setOn(true, animated: false)
        }
    }
    
    func restoreTextFieldsAppearence() {
        let textFields = [textFieldCode, textFieldName, textFieldEmail, textFieldPassword, textFieldProfile]
        
        for case let textField? in textFields {
            markView(view: textField, valid: true)
        }
    }

    func setupUI(account: Account) {
        textFieldProfile.text = account.profileName
        textFieldProfile.isEnabled = false
        textFieldName.text = account.name
        textFieldName.isEnabled = false
        textFieldEmail.text = account.email
        textFieldEmail.isEnabled = false
        textFieldPassword.text = "********"
        textFieldPassword.isEnabled = false
        textFieldCode.isEnabled = false
        demoConfigurationSwitch.isEnabled = false
        
        if accountModel!.isActive {
            buttonRegister.isHidden = true
            deleteButton.isHidden = true
        } else {
            buttonRegister.setTitle(makeActiveText, for: UIControlState.normal)
        }
    }
    
    // MARK: - Button Handlers
    
    @IBAction func registerButtonClicked(_ sender: UIButton) {
        if accountModel == nil {
            restoreTextFieldsAppearence()
            validator.validate(self)
        } else {
            // user account - we should show alert view to allow user cancel-activate-new-account
            // or just to wait while all upgrades are finished
            if UpgradeManager.sharedInstance.upgradingDevicesCount > 0 {
                let alert = UIAlertController(title: Strings.kACCAlertChangeAccTitle,
                                              message: Strings.kACCAlertChangeAccBody ,
                                              preferredStyle: .alert)
                
                alert.view.tintColor = .defaultTint
                
                let actionYes = UIAlertAction(title: Strings.kAlertYesButtonTitle, style: .default) { _ in
                    
                    UpgradeManager.sharedInstance.cancelUpgradeForAllDevices()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.switchAccount()
                    }
                }
                
                let actionNo = UIAlertAction(title: Strings.kAlertNoButtonTitle, style: .cancel)
                
                alert.addAction(actionYes)
                alert.addAction(actionNo)
                
                present(alert, animated: true) {
                    alert.view.tintColor = .defaultTint
                }
            }
            else {
                switchAccount()
            }
        }
    }
    
    func switchAccount() {
        DatabaseManager.sharedInstance.switchAccount(accountModel!)
        DeviceManager.sharedInstance.reloadDeviceList()
        Connection.reconfigConnection(demo: demoConfiguration)
        resetGatewayConfig()
        owner?.update()
        let _ = navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteButtonClicked(_ sender: UIButton) {
        if accountModel != nil {
            DatabaseManager.sharedInstance.deleteAccount(accountModel!)
            owner?.update()
            let _ = navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func demoConfigurationStatusChanged(_ sender: UISwitch) {
        
        demoConfiguration = sender.isOn
        
        if accountModel != nil {
            DatabaseManager.sharedInstance.saveDemoConfigurationStatus(account: accountModel!, status: demoConfiguration)
        }
    }
    
    func resetGatewayConfig() {
        Profile.sharedInstance.cloudConfig = nil
        if let gatewayId = DatabaseManager.sharedInstance.gatewayId {
            gatewayConfig(hid: gatewayId)
        }
    }
    
    // MARK: ValidationDelegate
    
    func validationSuccessful() {
        
        //showActivityIndicator()
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = "Registering..."
        
        let name = self.textFieldName.text!
        let email = self.textFieldEmail.text!.trimmedLowercased
        let password = self.textFieldPassword.text!
        let applicationCode = self.textFieldCode.text!.trimmed
        let profileName = self.textFieldProfile.text!
        
        let accountModel = UserAppAuthenticationModel(username: email,
                                                      password: password,
                                                      applicationCode: applicationCode)
        
        Profile.sharedInstance.cloudConfig = nil
        Connection.reconfigConnection(demo: demoConfiguration)
        
        ArrowConnectIot.sharedInstance.authenticate2(model: accountModel) { response, error in
            //self.hideActivityIndicator()
            hud.hide(animated: true)
            
            if let response = response {
                
                // save account
                let account = Account()
                
                // default for backward compatible
                account.name = name
                account.email = email
                
                account.updateWith(authResponse: response)
                account.profileName = profileName
                
                DatabaseManager.sharedInstance.addAccount(account)
                DatabaseManager.sharedInstance.saveDemoConfigurationStatus(status: self.demoConfiguration)
                
                DeviceManager.sharedInstance.reloadDeviceList()
                
                // register gateway
                let gatewayModel = CreateGatewayModel()
                gatewayModel.userHid         = account.userId
                gatewayModel.applicationHid  = account.applicationHid
                gatewayModel.softwareName    = SoftwareVersion.Name
                gatewayModel.softwareVersion = "\(SoftwareVersion.Version).\(SoftwareVersion.BuildNumber)"
                
                Connection.reconfigConnection(demo: self.demoConfiguration)
                
                ArrowConnectIot.sharedInstance.gatewayApi.registerGateway(gateway: gatewayModel) { (hid, error) in
                    if let error = error {
                        FIRCrashPrintMessage("Registering Gateway Error: \(error)")
                        self.showAlert("Error Registering Gateway!", message: error)
                    } else if let hid = hid {
                        DatabaseManager.sharedInstance.saveGatewayId(hid)
                        self.gatewayConfig(hid: hid)
                    }
                    
                    self.owner?.update()
                    self.navigationController?.popViewController(animated: true)
                }
                
            }
            else if var errMsg = error {
                FIRCrashPrintMessage("System Error: Unable to register account")
                
                // workaround to show userfriendly message
                if errMsg.lowercased().hasPrefix( "invalid login" ) {
                    errMsg = "Invalid login or password, please type another login/password"
                }
                
                self.showAlert("Unable to register account", message: errMsg)
            }
            else {
                FIRCrashPrintMessage("System Error: Unable to register account!")
                self.showAlert("Error", message: "Unable to register account!")
            }
        }
    }
    
    func validationFailed(_ errors: [(Validatable, ValidationError)]) {
        for (field, _) in errors {
            markView(view: field as! UIView, valid: false)
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Set avoiding params
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        switch textField {
        case textFieldName:
            KeyboardAvoiding.setAvoidingView(view, withTriggerView: textFieldEmail)

        case textFieldEmail:
            KeyboardAvoiding.setAvoidingView(view, withTriggerView: textFieldPassword)
            
        case textFieldPassword:
            KeyboardAvoiding.setAvoidingView(view, withTriggerView: textFieldCode)
            
        case textFieldCode:
            KeyboardAvoiding.setAvoidingView(view, withTriggerView: demoConfigurationSwitch)
            
        default:
            break
        }
        
        return true
    }
}
