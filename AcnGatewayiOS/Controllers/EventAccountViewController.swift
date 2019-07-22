//
//  EventAccountViewController.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import UIKit
import IHKeyboardAvoiding
import AcnSDK

class EventAccountViewController: UIViewController, ValidationDelegate, UITextFieldDelegate
{
    static let controllerId = "EventAccountViewController"
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var nameTextField: AcnTextField!
    @IBOutlet weak var emailTextField: AcnTextField!
    @IBOutlet weak var passwordTextField: AcnTextField!
    @IBOutlet weak var retypePasswordTextField: AcnTextField!
    @IBOutlet weak var eventCodeTextField: AcnTextField!
    
    @IBOutlet weak var accountView: UIView!
    @IBOutlet weak var messageView: UIView!
    
    @IBOutlet weak var errMsgView: UIView!
    @IBOutlet weak var errMsgLabel: UILabel!
    
    @IBOutlet weak var topSpaceContraint: NSLayoutConstraint!
    // this is the selected socialevent from previous state
    var event: SocialEvent?
    
    let validator = Validator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithArrowLogo()
        hideKeyboardOnTap()
        
        navigationController?.navigationBar.isHidden = true
        
        messageView.isHidden = true
        
        // add validation rules for all text fields
        validator.registerField(nameTextField, rules: [RequiredRule()])
        validator.registerField(passwordTextField, rules: [RequiredRule()])
        validator.registerField(emailTextField, rules: [RequiredRule(), EmailRule()])
        validator.registerField(retypePasswordTextField, rules: [RequiredRule()])
        validator.registerField(eventCodeTextField, rules: [RequiredRule()])
        
        KeyboardAvoiding.setAvoidingView(view, withTriggerView: eventCodeTextField)
    }
   
    // restore initial appearence of all text fields
    func restoreTextFieldsAppearence() {
        let textFields = [nameTextField, emailTextField, passwordTextField, retypePasswordTextField, eventCodeTextField]
        
        for case let textField? in textFields {
            markView(view: textField, valid: true)
        }
    }
    
    func hideShowErrMsg(hide: Bool ) {
        guard errMsgView.isHidden != hide else {
            return
        }
        
        UIView.animate(withDuration: 0.3) {
            self.errMsgView.isHidden = hide
            self.topSpaceContraint.constant = hide ? 40.0 : 8.0
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        hideShowErrMsg(hide: true)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        hideKeyboard(nil)
        validator.validate(self)
        return false
    }
    
    // MARK: - Button handlers
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        restoreTextFieldsAppearence()
        validator.validate(self)
    }
    
    @IBAction func signInButtonPressed(_ sender: UIButton) {
        let infoDict: [String : Any] = [
            AccountKeys.name  : nameTextField.text!,
            AccountKeys.email : emailTextField.text!,
            AccountKeys.pass  : passwordTextField.text!
        ]
        
        dismiss(animated: true) {
            NotificationCenter.default.post(name: .socialEventSignInWithExistingAccCredentials, object: self, userInfo: infoDict)
        }
    }
    
    @IBAction func msgViewBackButtonPressed(_ sender: UIButton) {
        self.messageView.isHidden = true
        UIView.animate(withDuration: 0.3) {
            self.accountView.isHidden = false
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Validation delegate
    
    func validationFailed(_ errors: [(Validatable, ValidationError)]) {
        for (field, _) in errors {
            if let field = field as? UITextField {
                    markView(view: field, valid: false)
            }
        }
    }
    
    func validationSuccessful() {
        restoreTextFieldsAppearence()

        guard let pass = passwordTextField.text,
              let repass = retypePasswordTextField.text,
              pass == repass,
              let email = emailTextField.text,
              let name = nameTextField.text,
              let eventCode = eventCodeTextField.text,
              let eventHid = event?.hid,
              let eventName = event?.name,
              let zoneSystemName = event?.zoneSystemName
        else {
            markView(view: passwordTextField, valid: false)
            markView(view: retypePasswordTextField, valid: false)
            errMsgLabel.text = "Passwords are not equal"
            hideShowErrMsg(hide: false)
            return
        }
        
        hideShowErrMsg(hide: true)
        
        // enable next button
        nextButton.isEnabled = true
        nextButton.backgroundColor = UIColor.mainColor
        
        let hud = MBProgressHUD.showAdded(to: self.navigationController?.view ?? view, animated: true)
        hud.label.text = "Registering account..."
        
        let regModel = EventRegisterAccModel(email: email.trimmed, eventCode: eventCode.trimmed, name: name.trimmed, password: pass, eventHid: eventHid, eventZoneSystemName: zoneSystemName)
        
        // fix: reconfig connection using zone name from event registration
        Connection.reconfigConnectionWithZoneName(zoneSystemName)
        
        ArrowConnectIot.sharedInstance.eventRegisterAccount(accModel: regModel) { (hid, errMsg) in
            hud.hide(animated: true)
            
            if let errMsg = errMsg {
                
                if errMsg == "You already have an account, please sign in using your existing account" {
                    self.accountView.isHidden = true
                    UIView.animate(withDuration: 0.3) {
                        self.messageView.isHidden = false
                        self.view.layoutIfNeeded()
                    }
                }
                else {
                    self.errMsgLabel.text = errMsg
                    self.hideShowErrMsg(hide: false)
                }
            }
            else {
                
                // save values for pending state
                SocialEventManager.sharedInstance.saveAccountRegistrationPeindingValues(name: name, email: email, pass: pass, code: eventCode, eventHid: eventHid, eventName: eventName, zoneName: zoneSystemName)
                
                // successully registred, should set wait-for-verification flag
                SocialEventManager.sharedInstance.waitingForVerification = true
                
                // show verify code view controller
                if let vc = self.storyboard?.instantiateViewController(withIdentifier: EventVerifyCodeViewController.controllerId) as? EventVerifyCodeViewController {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
}
