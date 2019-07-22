//
//  EventAttendViewController.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import UIKit
import AcnSDK

class EventAttendViewController: UIViewController {
    static let controllerId = "EventAttendViewController"
    
    @IBOutlet weak var questionView: UIView!
    @IBOutlet weak var launchView: UIView!
    
    var showAsQuestion = false
    var shoudShowVerificationFlow = false
    
    // returns instance of viewcontroller instantiated from storyboard
    static var controller: EventAttendViewController {
        let storyboard = UIStoryboard(name: "Event", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "EventAttendViewController") as! EventAttendViewController
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if showAsQuestion {
            launchView.isHidden = true
            
            // if we registred but not verified yet, show verification screen with no question
            if  SocialEventManager.sharedInstance.waitingForVerification
            {
                shoudShowVerificationFlow = true
            }
            else {
                questionView.isHidden = false
            }
        }
        else {
            // set initial configuration for AcnSDK
            ArrowConnectIot.sharedInstance.setKeys(apiKey: Constants.Keys.DefaultApiKey, secretKey: Constants.Keys.DefaultSecretKey)
            
            // set default connections according to the current profile
            if DatabaseManager.sharedInstance.currentAccount != nil {
                Connection.reconfigConnection(demo: DatabaseManager.sharedInstance.demoConfiguration)
            }
            else {
                // empty account should to reconfig to the default urls
                Connection.reconfigConnection()
            }

            // make ~3 second pause before fetching social events list
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.fetchSocialEvents()
                self.registerDefaults()
                IotDataPublisher.sharedInstance.start()
            }
        }
    }
    
    func fetchSocialEvents() {
        questionView.isHidden = true
        launchView.isHidden = false
        
        // should we check active account before making request?
        // try to fetch list of social events on start
        ArrowConnectIot.sharedInstance.socialEvents { events  in
            if let events = events {
                print("Got list of social events \(events.count)")
                SocialEventManager.sharedInstance.events = events
            }
            else {
                print("Can not get list of social events")
            }
            
            // instantiate initial view controller and make as root view controller
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if  let vc = storyboard.instantiateInitialViewController(),
                let window = UIApplication.shared.delegate?.window,
                let snapshot = window?.snapshotView(afterScreenUpdates: true)
            {
                vc.view.addSubview(snapshot)
                window?.rootViewController = vc
                UIView.animate(withDuration: 0.3, animations: {
                    snapshot.alpha = 0.0
                }, completion: { success in
                    snapshot.removeFromSuperview()
                })
            }
        }
    }    
    
    // register default values for all devices
    func registerDefaults() {
        Profile.sharedInstance.reload()
        
        MicrosoftBandProperties.sharedInstance.registerDefaults()
        IPhoneDeviceProperties.sharedInstance.registerDefaults()
        ThunderboardProperties.sharedInstance.registerDefaults()
        SensorTileProperties.sharedInstance.registerDefaults()
        SimbaProProperties.sharedInstance.registerDefaults()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if  shoudShowVerificationFlow,
            let verifyVC = storyboard?.instantiateViewController(withIdentifier: EventVerifyCodeViewController.controllerId)
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let navVC = UINavigationController(rootViewController: verifyVC)
                self.present(navVC, animated: true)
            }
        }
    }
    
    // MARK: - Button Handlers
    
    @IBAction func noButtonPressed(_ sender: UIButton) {
        dismiss(animated: true) {
            NotificationCenter.default.post(name: .socialEventAttendDecline, object: nil)
        }
    }
    
    @IBAction func attendEventPressed(_ sender: UIButton) {
        guard  let eventChooseVC = storyboard?.instantiateViewController(withIdentifier: EventChooseViewController.controllerId) as? EventChooseViewController else
        {
            print("EventAttendVC() -> Can not instantiate EventChooseVC")
            return
        }
        
        eventChooseVC.events = SocialEventManager.sharedInstance.events
        let navVC = UINavigationController(rootViewController: eventChooseVC)
        
        present(navVC, animated: true)
    }
}
