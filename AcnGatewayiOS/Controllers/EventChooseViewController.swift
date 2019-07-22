//
//  EventChooseViewController.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import UIKit

class EventChooseViewController: UIViewController
{
    static let controllerId = "EventChooseViewController"
    
    @IBOutlet weak var chooseEventButton: UIButton!
    @IBOutlet weak var chooseEventButtonIcon: UIImageView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var verifyView: UIView!
    
    var events: [SocialEvent]?
    var selectedEvent: SocialEvent?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()

        if let event = SocialEventManager.sharedInstance.events.first {
            selectedEvent = event
        }
        
        navigationController?.navigationBar.isHidden = true
        
        verifyView.isHidden = !SocialEventManager.sharedInstance.waitingForVerification
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateSelectedEventButton()
        super.viewWillAppear(animated)
    }
    
    func updateSelectedEventButton() {
        if let event = selectedEvent {
            self.chooseEventButton.setTitle(event.name, for: .normal)
            enableNextButton(enable: true)
        }
        else {
            enableNextButton(enable: false)
        }
    }
    
    func enableNextButton(enable:Bool) {
        nextButton.isEnabled = enable
        nextButton.backgroundColor = enable ? UIColor.mainColor : UIColor.gray0
    }
    
    func setupNavBar() {
        
        //navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonPressed(_:)))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        setupNavBarWithArrowLogo()
    }
    
    
    // MARK: - Button handlers
    
    @IBAction func backButtonPressed(_ sender: UIControl) {
        dismiss(animated: true)
    }
    
    @IBAction func verifyButtonPressed(_ sender: UIButton) {
        guard let evc = storyboard?.instantiateViewController(withIdentifier: EventVerifyCodeViewController.controllerId) as? EventVerifyCodeViewController
        else {
            print("Can not instantiate EventVerifyCode view controller")
            return
        }
        
        navigationController?.pushViewController(evc, animated: true)
    }
    
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        
        guard let accountVC = storyboard?.instantiateViewController(withIdentifier: EventAccountViewController.controllerId) as? EventAccountViewController
        else {
            print("Cann not instantiate EventAccountViewController")
            return
        }
        
        // pass the event to the VC
        accountVC.event = selectedEvent
        navigationController?.pushViewController(accountVC, animated: true)
    }
    
    @IBAction func showEventsPopup(_ sender: UIButton) {
        guard let eventSelectionVC = storyboard?.instantiateViewController(withIdentifier: EventPopoverSelectionViewController.controllerId) as? EventPopoverSelectionViewController else
        {
            print("Can not instantiate eventselection popover vc")
            return
        }
        
        eventSelectionVC.availableEvents = events
        eventSelectionVC.selectionHandler = { event in
            
            self.chooseEventButton.setTitle( event.name, for: .normal)
            self.enableNextButton(enable: true)
            
            self.selectedEvent = event
        }
        
        // show this controller as popover
        
        eventSelectionVC.modalPresentationStyle = .popover
        
        if let popover = eventSelectionVC.popoverPresentationController {
            popover.delegate = eventSelectionVC
            popover.permittedArrowDirections = .up
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
            
            let p0 = sender.convert(CGPoint.zero, to: self.view)
            let p1 = infoLabel.convert(CGPoint.zero, to: self.view)
            
            let hight = p1.y - p0.y - sender.bounds.height
            
            eventSelectionVC.preferredContentSize = CGSize(width: sender.bounds.width, height: max(hight, 120) )
            
            present(eventSelectionVC, animated: true)
        }
    }
}
