//
//  EventVerifyCodeViewController.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import AcnSDK
import IHKeyboardAvoiding
import UIKit

// default hide/show animation duration
let kHideShowAnimDuration: TimeInterval = 0.3

class EventVerifyCodeViewController: UIViewController, UITextFieldDelegate, ValidationDelegate {
    static let controllerId = "EventVerifyCodeViewController"
    
    // keeps error feed back of verify code action
    @IBOutlet var errorMsgView: UIView!
    @IBOutlet var errorMsgLabel: UILabel!
    
    @IBOutlet var resendEmailTextField: UITextField!
    @IBOutlet var resendCodeButton: UIButton!
    
    @IBOutlet var verifyButton: UIButton!
    @IBOutlet var verificationCodeTextField: UITextField!
    
    // keeps feedback message of resend code action
    @IBOutlet var resendMsgView: UIView!
    @IBOutlet var resendMsgLabel: UILabel!
    
    @IBOutlet var resendView: UIView!
    
    @IBOutlet weak var topSpaceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var resendMsgTopLabel: UILabel!
    let validator = Validator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithArrowLogo()
        
        errorMsgView.isHidden = true
        resendMsgView.isHidden = true
        
        navigationController?.navigationBar.isHidden = true
        
        hideKeyboardOnTap()
        
        validator.registerField(resendEmailTextField, rules: [RequiredRule(), EmailRule()])
        
        // set default tint color for text views
        let defaultTintColor = UIButton().tintColor
        verificationCodeTextField.tintColor = defaultTintColor
        resendEmailTextField.tintColor = defaultTintColor
    }
    
    // hide message view if visible
    func hideErrView() {
        if errorMsgView.isHidden == false {
            UIView.animate(withDuration: kHideShowAnimDuration) {
                self.errorMsgView.isHidden = true
                self.topSpaceConstraint.constant = 40.0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // show message view if hidden
    func showErrView() {
        if errorMsgView.isHidden {
            UIView.animate(withDuration: kHideShowAnimDuration) {
                self.errorMsgView.isHidden = false
                self.topSpaceConstraint.constant = 8.0
                self.view.layoutIfNeeded()
            }
        }
    }
    
    // MARK: - Button handlers
    @IBAction func verifyButtonPressed(_ sender: UIButton) {
        
        hideErrView()
        hideKeyboard(nil)
        
        guard let verifyCode = self.verificationCodeTextField.text, !verifyCode.trimmed.isEmpty else {
            errorMsgLabel.text = "Please type your verification code"
            showErrView()
            return
        }
        
        let ud = UserDefaults.standard       

        // get the pending values for registration
        guard   let name = ud.string(forKey: PendingRegKeys.name),
                //let profileName = ud.string(forKey: PendingRegKeys.eventName),
                let email = ud.string(forKey: PendingRegKeys.email),
                //let pass = ud.string(forKey: PendingRegKeys.pass),
                let zoneSystemName = ud.string(forKey:  PendingRegKeys.eventZoneSystemName)
        else
        {
                print("EventVerifyCodeViewController() - Error: Can not get pending Account data from UserDefaults")
                errorMsgLabel.text = "It seems you didn't register on this device"
                showErrView()
                return
        }
        
        Connection.reconfigConnectionWithZoneName(zoneSystemName)

        let hud = MBProgressHUD.showAdded(to: navigationController?.view ?? view, animated: true)
        hud.label.text = "Verifying..."
        
        ArrowConnectIot.sharedInstance.verifyVerificationCode(code: verifyCode.trimmed) { resp, errMsg in
            hud.hide(animated: true)
            
            if let errMsg = errMsg {
                self.errorMsgLabel.text = errMsg
                self.showErrView()
            }
            else if let resp = resp {
                print("Response OK - registering new account \(resp.appHid)...")
                
                Profile.sharedInstance.cloudConfig = nil
                
                let account = Account()
                account.email = email
                account.name = name
                account.profileName = name // fix: Name the profile the same as the name
                account.applicationHid = resp.appHid
                account.userId = resp.userHid
                account.zoneSystemName = zoneSystemName
                
                DatabaseManager.sharedInstance.addAccount(account)
                DatabaseManager.sharedInstance.saveDemoConfigurationStatus(status: false)
                
                DeviceManager.sharedInstance.reloadDeviceList()
                
                // register gateway
                let gatewayModel = CreateGatewayModel()
                gatewayModel.userHid = account.userId
                gatewayModel.applicationHid = account.applicationHid
                gatewayModel.softwareName = SoftwareVersion.Name
                gatewayModel.softwareVersion = "\(SoftwareVersion.Version).\(SoftwareVersion.BuildNumber)"
                
                Connection.reconfigConnection()
                
                // reset wait-for-verificatoin flag
                SocialEventManager.sharedInstance.waitingForVerification = false
                // reset registration peinding values
                SocialEventManager.sharedInstance.resetAccountRegistrationPendingValues()
                
                ArrowConnectIot.sharedInstance.gatewayApi.registerGateway(gateway: gatewayModel) { hid, error in
                    
                    if let error = error {
                        FIRCrashPrintMessage("Registering Gateway Error: \(error)")
                        print("Register Gateway Error: \(error)")
                    }
                    else if let hid = hid {
                        DatabaseManager.sharedInstance.saveGatewayId(hid)
                        self.gatewayConfig(hid: hid)
                    }
                    
                    self.dismiss(animated: true) {
                        NotificationCenter.default.post(name: .socialEventVerificationSuccess, object: error == nil ? nil : ["error": error!])
                    }
                }
            }
        }
    }
    
    @IBAction func resendCodeButtonPressed(_ sender: UIButton) {
        
        hideErrView()
        hideKeyboard()
        
        // fix: should trim email
        if let email = resendEmailTextField.text {
            resendEmailTextField.text = email.trimmed
        }

        validator.validate(self)
    }
    
    @IBAction func resendAgainButtonPressed(_ sender: UIButton) {
        resendMsgView.isHidden = true
        UIView.animate(withDuration: kHideShowAnimDuration) {
            self.resendView.isHidden = false
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Validator delegate
    
    // validation of resend email text field
    func validationSuccessful() {
        
        guard let email = resendEmailTextField.text else {
            print("==> nil email returned")
            return
        }
        
        markView(view: resendEmailTextField, valid: true)
        
        if let zoneName = UserDefaults.standard.string(forKey: PendingRegKeys.eventZoneSystemName) {
            Connection.reconfigConnectionWithZoneName(zoneName)            
        }
        else {
            print("ResendVerificationCode() -> Can not get eventZoneSystemName")
        }
        
        let hud = MBProgressHUD.showAdded(to: navigationController?.view ?? view, animated: true)
        hud.label.text = "Resending..."
        
        ArrowConnectIot.sharedInstance.resendEventVerificationCode(email: email) { _, errMsg in
            hud.hide(animated: true)
            
            if let errMsg = errMsg {
                // fix: not to put the user in confusion, show frendly message
                self.resendMsgTopLabel.text = /*(errMsg.lowercased() == "invalid email address") ? "Can't resend code for this email" :*/ errMsg
            }
            else {
                self.resendMsgTopLabel.text = "The verification code has been sent"
            }
            
//            self.resendView.isHidden = true
//            UIView.animate(withDuration: kHideShowAnimDuration) {
//                self.resendMsgView.isHidden = false
//                self.view.layoutIfNeeded()
//            }
        }
        
    }
    
    func validationFailed(_ errors: [(Validatable, ValidationError)]) {
        for (field, _) in errors {
            if let field = field as? UITextField {
                markView(view: field, valid: false)
            }
        }
    }

    
    // MARK: - TextFieldDelegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        switch textField {
            //case verificationCodeTextField:
            //     IHKeyboardAvoiding.setAvoiding( view, withTriggerView: verifyButton)
                //print("Begin edit of verification text")
            
            case resendEmailTextField:
                hideErrView()
                KeyboardAvoiding.setAvoidingView(view, withTriggerView: resendCodeButton)
            
            default:
                break
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case resendEmailTextField:
            KeyboardAvoiding.setAvoidingView(view, withTriggerView: verifyButton)
            
        default:
            break
        }
    }
    
    // MARK: - Helpers
    func gatewayConfig(hid: String) {
        ArrowConnectIot.sharedInstance.gatewayApi.gatewayConfig(hid: hid) { success in
            if success {
                DispatchQueue.global().async {
                    ArrowConnectIot.sharedInstance.connectMQTT(gatewayId: hid)
                }
                ArrowConnectIot.sharedInstance.startHeartbeat(interval: DatabaseManager.sharedInstance.settings.heartbeatInterval, gatewayId: hid)
            }
            else {
                FIRCrashPrintMessage("Gateway Config Error")
            }
        }
    }
}
