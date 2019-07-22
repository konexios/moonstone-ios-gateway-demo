//
//  DeviceTableViewDarkCell.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 31/05/2017.
//  Copyright © 2017 Arrow Electronics, Inc. All rights reserved.
//

import UIKit

class DeviceTableViewDarkCell: UITableViewCell {
    
    let onlineViewWidthDefault: CGFloat = 8.0
    let deviceNameLeftMarginDefault: CGFloat = 8.0
    
    @IBOutlet weak var gradientView: GradientView!
    
    @IBOutlet weak var deviceName: UILabel! 
    @IBOutlet weak var deviceType: UILabel!
    
    @IBOutlet weak var onlineView: OnlineIndicatorView!
    @IBOutlet weak var onlineViewWidth: NSLayoutConstraint!
    //@IBOutlet weak var deviceNameLeftMargin: NSLayoutConstraint!
    
    // MARK: Upgrade views
    
    @IBOutlet weak var upgradeView: UIView!
    @IBOutlet weak var upgradeProgress: UIProgressView!
    @IBOutlet weak var upgradeIndicator: UIActivityIndicatorView!
    @IBOutlet weak var upgradeLabel: UILabel!
    @IBOutlet weak var upgradeIcon: UIImageView!
    
    var online: Bool = false {
        didSet {
            setupCellWith(online: online)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
                
        contentView.backgroundColor = .gray0
        backgroundColor = .gray0
        
        online = false
        
        setupGradientView()
    }   
    
    func setupGradientView() {
        
        let layer = gradientView.layer as! CAGradientLayer
        
        layer.startPoint = CGPoint(x: 0.5, y: 0.7)
        layer.endPoint = CGPoint(x: 1.0, y: 1.0)

        layer.colors = [UIColor.gray3.cgColor,
                        UIColor.mainColor2.cgColor]
    }
    
    func setupCellWith(device: Device) {
        deviceName.text = device.cloudName ?? device.deviceType.rawValue
        deviceType.text = device.deviceType.rawValue
    }
    
    func setupCellWith(online: Bool) {
        onlineView.isHidden = !online
    }
    
    override func prepareForReuse() {
        updateUpgradeView()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    var upgradeInfo: [UpgradeInfoKeys: Any] = [.info: ""]
    var upgradeState: DeviceUpgradeState.State = .idle {
        didSet {
            updateUpgradeView()
        }
    }

    fileprivate func updateUpgradeView() {
        upgradeView.isHidden = false
        upgradeIndicator.isHidden = true
        upgradeProgress.isHidden = true
        upgradeProgress.tintColor = .defaultTint
        upgradeIcon.isHidden = true
        
        switch upgradeState {
            
        case .scheduled:
            upgradeLabel.text = Strings.kUpgradeScheduledForUpgrade
            
        case .downloading:
            let info = String( format: Strings.kUpgradeDownloadingFirmware, upgradeInfo[.progressString] as? String ?? "0" )
            upgradeLabel.text = info
            upgradeProgress.isHidden = false
            upgradeIndicator.isHidden = false
            upgradeProgress.progress = Float( upgradeInfo[.progress] as? Double ?? 0.0 )
            
        case .preparing:
            let infoStr = upgradeInfo[.info] as? String ?? ""
            upgradeLabel.text = "Starting: \(infoStr)..."
            upgradeIndicator.isHidden = false
            
        case .upgrading:
            let info = String( format: Strings.kUpgradeUpgradingFirmware, upgradeInfo[.progressString] as? String ?? "0" )
            upgradeLabel.text = info
            upgradeProgress.isHidden = false
            upgradeIndicator.isHidden = false
            upgradeProgress.progress = Float( upgradeInfo[.progress] as? Double ?? 0.0 )
            
        case .error:
            let errMsg = upgradeInfo[.errorMessage] as? String ?? "unknown error"
            let info = String( format: Strings.kUpgradeFailedFormat, errMsg )
            upgradeLabel.text = info
            upgradeIcon.image = UIImageView.templateImage(.exclamationTriangleSmall)
            upgradeIcon.tintColor = UIColor.white
            upgradeIcon.isHidden = false
            
        case .success:
            upgradeLabel.text = Strings.kUpgradeSuccedeedTitle
            upgradeIcon.image = UIImageView.templateImage(.checkmarkCircle)
            upgradeIcon.tintColor = UIColor.green
            upgradeIcon.isHidden = false
            
        case .idle:
            upgradeView.isHidden = true
        }
        
        // fix the animating issue
        if upgradeIndicator.isHidden == false {
            upgradeIndicator.startAnimating()
        }
    }
}
