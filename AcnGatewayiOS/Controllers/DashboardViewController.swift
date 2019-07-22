//
//  DashboardViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 26/12/2016.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import UIKit
import Charts
import AcnSDK

class DashboardViewController: BaseViewController, IAxisValueFormatter {

    let secondsInDay: TimeInterval = 3600 * 24
    let dayCount: Int = 7
    
    var device: Device?
    var deviceHid: String?
    
    var telemetryLoaded = 0 {
        didSet {
            if telemetryLoaded == dayCount && eventsLoaded {
                DispatchQueue.main.async { [weak self] in
                    self?.showData()
                }
            }
        }
    }
    
    var eventsLoaded = false {
        didSet {
            if telemetryLoaded == dayCount && eventsLoaded {
                DispatchQueue.main.async { [weak self] in
                    self?.showData()
                }
            }
        }
    }
    
    var telemetryData = [TimeInterval : Int]()
    var eventsData = [TimeInterval : Int]()

    @IBOutlet weak var telemetryLabel: UILabel!
    @IBOutlet weak var notificationsLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!

    @IBOutlet weak var chartView: LineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .gray0
        separatorView.backgroundColor = .gray1
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.titleView = UIImageView(image: UIImage(named:"Arrow_worm_white_nav"))

        showActivityIndicator()

        setupNavigationItems()
        setupChart()
        loadData()
    }
    
    func setupNavigationItems() {
        let navigationItems = [
            UIBarButtonItem(image: UIImage(named: "im-pencil"), style: .plain, target: self, action: #selector(showTelemetry))
        ]
        navigationItem.rightBarButtonItems = navigationItems
    }
    
    @objc func showTelemetry() {
        if let telemetryViewController = self.storyboard?.instantiateViewController(withIdentifier: "TelemetryViewController") as? TelemetryViewController {
            telemetryViewController.device = device
            pushWithToolbar(controller: telemetryViewController)
        }
    }
    
    func setupChart() {
        chartView.noDataText = "No data available"
        
        chartView.backgroundColor = .gray1
        
        chartView.minOffset = 20.0
        
        chartView.extraLeftOffset = 10.0
        chartView.extraBottomOffset = 10.0
        
        chartView.chartDescription?.enabled  = false
        chartView.legend.enabled = false        
        
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        
        chartView.rightAxis.enabled = false

        chartView.leftAxis.axisMinimum = 0.0
        chartView.leftAxis.axisLineColor = .gray2
        chartView.leftAxis.gridColor = .gray2
        chartView.leftAxis.labelTextColor = .white
        chartView.leftAxis.xOffset = 10.0
        
        chartView.xAxis.axisLineColor = .gray2
        chartView.xAxis.labelTextColor = .white
        chartView.xAxis.valueFormatter = self
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.granularity = secondsInDay
        chartView.xAxis.setLabelCount(dayCount, force: true)
        chartView.xAxis.yOffset = 10.0
    }
    
    func loadData() {
        
        if deviceHid != nil {
            
            var toDate = Date()
            var fromDate = toDate.dateWithoutTime
            let fromTimeInterval = fromDate.timeIntervalSince1970
            
            for i in 0..<dayCount {
                let interval = fromTimeInterval - TimeInterval(i) * secondsInDay
                telemetryData[interval] = 0
                eventsData[interval] = 0
            }
            
            for i in 0..<dayCount {
                
                ArrowConnectIot.sharedInstance.deviceTelemetryCount(hid: deviceHid!, telemetry: "*", fromDate: fromDate, toDate: toDate) { count in
                    if count != nil {
                        let interval = fromTimeInterval - TimeInterval(i) * self.secondsInDay
                        if let _ = self.telemetryData[interval] {
                            self.telemetryData[interval] = count!.value
                        }
                    }
                    
                    self.telemetryLoaded += 1
                }
                
                toDate = fromDate
                fromDate.addTimeInterval(-secondsInDay)
            }
            
            ArrowConnectIot.sharedInstance.deviceApi.deviceEvents(hid: deviceHid!) { events in
                
                if events != nil {
                    for event in events! {
                        if let timeInterval = event.createdDate?.dateWithoutTime.timeIntervalSince1970 {
                            if let _ = self.eventsData[timeInterval] {
                                self.eventsData[timeInterval]! += 1
                            }
                        }
                    }
                    
                    self.notificationsLabel.text = self.countText(count: events!.count)
                }
                
                self.eventsLoaded = true
            }            
        }        
    }
    
    func showData() {
        
        var telemetryEntries: [ChartDataEntry] = []
        var eventsEntries: [ChartDataEntry] = []
        
        let intervals = telemetryData.keys.sorted {$0 < $1}
        var telemetryCount = 0
        
        for interval in intervals {
            let telemetryEntry = ChartDataEntry(x: interval, y: Double(telemetryData[interval]!))
            telemetryEntries.append(telemetryEntry)
            telemetryCount += telemetryData[interval]!
            
            let eventEntry = ChartDataEntry(x: interval, y: Double(eventsData[interval]!))
            eventsEntries.append(eventEntry)
        }
        
        telemetryLabel.text = countText(count: telemetryCount)
        
        let telemetryDataSet = LineChartDataSet(values: telemetryEntries, label: "Telemetry")
        telemetryDataSet.lineWidth = 0.0
        telemetryDataSet.mode = .horizontalBezier
        telemetryDataSet.drawCirclesEnabled = false        
        telemetryDataSet.drawCircleHoleEnabled = false
        telemetryDataSet.drawValuesEnabled = false        
        
        let colors = [UIColor.mainColor.cgColor, UIColor.mainColor3.cgColor]
        let gradient = CGGradient(colorsSpace: nil, colors: colors as CFArray, locations: nil)
        telemetryDataSet.fill = Fill(linearGradient: gradient!, angle: 0.0)
        telemetryDataSet.fillAlpha = 0.7
        telemetryDataSet.drawFilledEnabled = true
        
        let eventsDataSet = LineChartDataSet(values: eventsEntries, label: "Notifications")
        eventsDataSet.setColor(UIColor.white)
        eventsDataSet.setCircleColor(UIColor.white)
        eventsDataSet.lineWidth = 3.0
        eventsDataSet.circleRadius = 5.0
        eventsDataSet.drawCircleHoleEnabled = false
        eventsDataSet.drawValuesEnabled = false
        
        let chartData = LineChartData(dataSets: [telemetryDataSet, eventsDataSet])
        chartData.highlightEnabled = false
        
        chartView.data = chartData
        
        hideActivityIndicator()
    }
    
    // MARK: IAxisValueFormatter
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US")
        return dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
    
    // MARK: Count
    
    let millionUnit = 1000000
    let thousandUnit = 10000
    
    func countText(count: Int) -> String {
        if count >= millionUnit  {
            let double = Double(count) / Double(millionUnit)
            return countText(double) + " M"
        } else if count >= thousandUnit {
            let double = Double(count) / 1000
            return countText(double) + " K"
        } else {
            return "\(count)"
        }
    }
    
    func countText(_ double: Double) -> String {
        let rounded = round(double * 10) / 10
        if rint(rounded) == rounded {
            return String(format: "%.0f", rounded)
        } else {
            return String(format: "%.1f", rounded)
        }
    }
}
