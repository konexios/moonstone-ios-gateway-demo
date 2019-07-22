//
//  DiscoverDeviceListViewController.swift
//  AcnGatewayiOS
//
//  Copyright © 2018 Arrow Electronics, Inc. All rights reserved.
//

import UIKit
import CoreBluetooth
import AcnSDK

/// devices that allow to be discovered with MAC addresses
/// and be presented as MAC->PIN Discovery UI should
/// implement discovery filter
protocol DeviceDiscoveryFilter {
    // used for fetching and mapping deviceType to MAC adddress <-> PIN code
    var mapDeviceType: String { get }
    
    // filter should return mac address or nil
    func macAddressFromAdvData(_ advDic: [String : Any]) -> String?
}

/// extension for DeviceType to return
/// device discovery filter for given device
extension DeviceType {
    
    var discoveryFilter: DeviceDiscoveryFilter? {
        switch self {
        case .SimbaPro:
            return SimbaProDiscoveryFilter()
        
        case .OnSemiRSL10:
            return OnSemiRSL10DiscoveryFilter()
            
//        case .SensorTile:
//            return SensorTileDiscoveryFilter()
            
        default:
            return nil
        }
    }
}

/// Discovery filter for SimbaPRO devices
class SimbaProDiscoveryFilter: DeviceDiscoveryFilter {
    
    func macAddressFromAdvData(_ advDic: [String : Any]) -> String?
    {
        guard   let advName = advDic[CBAdvertisementDataLocalNameKey] as? String,
                SimbaPro.isValidAdvertisingName(advName),
                let data = advDic[CBAdvertisementDataManufacturerDataKey] as? Data,
                let mac = SimbaPro.macAddressFromData(data)
        else
        {
            return nil
        }

        return mac
    }
    
    var mapDeviceType: String {
        return SimbaPro.DeviceTypeName
    }
}

/// Discovery filter for OnSemiRSL10 devices
class OnSemiRSL10DiscoveryFilter: DeviceDiscoveryFilter {
    
    func macAddressFromAdvData(_ advDic: [String : Any]) -> String?
    {
        guard   let advName = advDic[CBAdvertisementDataLocalNameKey] as? String,
                OnSemiRSL10.isValidAdvertisingName(advName),
                let data = advDic[CBAdvertisementDataManufacturerDataKey] as? Data,
                let mac = OnSemiRSL10.macAddressFromData(data)
        else
        {
            return nil
        }
        
        return mac
    }
    
    var mapDeviceType: String {
        return OnSemiRSL10.DeviceTypeName
    }
}

/// Discovery filter for SimbaPRO devices
class SensorTileDiscoveryFilter: DeviceDiscoveryFilter {
    
    func macAddressFromAdvData(_ advDic: [String : Any]) -> String?
    {
        guard   let advName = advDic[CBAdvertisementDataLocalNameKey] as? String,
                SensorTile.isValidAdvertisingName(advName),
                let data = advDic[CBAdvertisementDataManufacturerDataKey] as? Data,
                let mac = SensorTile.macAddressFromData(data)
        else
        {
            return nil
        }
        
        return mac
    }
    
    var mapDeviceType: String {
        return SensorTile.DeviceTypeName
    }
}

// Keeps device discovery data
struct DeviceDiscoverData {
    var uuid: UUID      // uuid of the device
    var name: String    // peripheral name
    var mac: String     // mac address
    var pin: String     // pin code
}

class DiscoverDeviceListViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var devicesFoundCountLabel: UILabel!

    var discoveryFilter: DeviceDiscoveryFilter?
    var selectDeviceHandler: ( (_ deviceDiscoverData: DeviceDiscoverData) -> Void )?
    
    private var data = [DeviceDiscoverData]()
    private var pins = [String : String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Select Device"
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.backgroundView = {
            let label = UILabel(frame: CGRect.zero)
            label.font = UIFont.boldSystemFont(ofSize: 18)
            label.textColor = UIColor.lightGray
            label.textAlignment = NSTextAlignment.center
            label.text = "No devices found"
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            
            let bgView = UIView(frame: self.view.bounds)
            bgView.addSubview(label)
            
            label.centerXAnchor.constraint(equalTo: bgView.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: bgView.centerYAnchor, constant: -60).isActive = true
            label.widthAnchor.constraint(equalTo: bgView.widthAnchor, multiplier: 0.8)
            
            label.sizeToFit()
            
            return bgView
        } ()
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let filter = discoveryFilter else {
            print("[DiscoverDeviceListViewController] - viewDidAppear(), Discovery filter is not provided!")
            return
        }

        ArrowConnectIot.sharedInstance.fetchDevicesMap(type: filter.mapDeviceType) { deviceMap in
            if let map = deviceMap {
                self.pins.removeAll()
                map.forEach { self.pins[$0.macAddress] = $0.pinCode  }
            }
            
            // start discovering only upon finished request
            self.startDiscover()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        BleUtils.sharedInstance.stopDiscover()
    }
    
    private func startDiscover() {
        // device - CBPeripheral, advDic - advertismentDataDict
        BleUtils.sharedInstance.startDiscover { (device, advDic) in
            
            guard let filter = self.discoveryFilter else {
                print("[DiscoverDeviceListViewController] - StartDiscover(), Discovery filter is not provided!")
                return
            }
            
            guard let mac = filter.macAddressFromAdvData(advDic) else {
                return
            }            
            
            // skip if this device is already in the list
            guard self.data.first(where: { $0.uuid == device.identifier }) == nil else {
                return
            }
            
            let pinCode = self.pins[mac, default: ""]
            
            self.data.append( DeviceDiscoverData(uuid: device.identifier, name: device.name ?? "", mac: mac, pin: pinCode) )
            
            self.devicesFoundCountLabel.text = "\(self.data.count)"
            self.collectionView.reloadData()
        }
    }
    
    // MARK: - CollectionView delegate
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       
        collectionView.backgroundView?.isHidden = data.count > 0
        
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let discoveryItem = data[indexPath.row]
        let itemName = discoveryItem.pin.isEmpty ? discoveryItem.mac.uppercased() : discoveryItem.pin
        let alert = UIAlertController(title: "Confirm", message: "Are you sure you want to add \(itemName)?", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .default) { action in
            self.selectDeviceHandler?( discoveryItem )
        }

        let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
        
        alert.addAction(yesAction)
        alert.addAction(noAction)

        alert.view.tintColor = .defaultTint
        
        present(alert, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverDeviceViewCell", for: indexPath) as? DiscoverDeviceViewCell
        else
        {
            preconditionFailure("[DiscoveryDeviceListViewController] - Can not instantiate a cell")
        }
        
        let device = data[indexPath.row]
        
        cell.pinCodeLabel.text = device.pin
        cell.macAddressLabel.text = device.mac.uppercased()
        cell.layer.borderColor = UIColor.gray2.cgColor
        
        return cell
    }
}
