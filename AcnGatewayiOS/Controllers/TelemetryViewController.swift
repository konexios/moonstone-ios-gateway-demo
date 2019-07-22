//
//  TelemetryViewController.swift
//  AcnGatewayiOS
//
//  Created by Michael Kalinin on 21/12/2016.
//  Copyright © 2016 Arrow Electronics. All rights reserved.
//

import Foundation
import Charts
import AcnSDK

class TelemetryViewController: BaseViewController, IAxisValueFormatter, SelectTelemetryViewControllerDelegate, SelectDateViewControllerDelegate {
    
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var selectTelemetryButton: UIButton!
    
    @IBOutlet weak var fromButton: AcnButton!
    @IBOutlet weak var toButton: AcnButton!
    
    @IBOutlet weak var separatorView: UIView!
    
    var fromDate: Date = Date()
    var toDate: Date = Date()
    
    var device: Device?
    
    var selectedTelemetry: SensorType?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.titleView = UIImageView(image: UIImage(named:"Arrow_worm_white_nav"))
        
        view.backgroundColor = .gray0
        separatorView.backgroundColor = .gray1
        
        setupDateButtons()
        setupChart()
    }
    
    func setupDateButtons() {        
        fromButton.isArrowHidden = true
        fromButton.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        fromButton.setTitle(fromDate.formattedString, for: UIControlState.normal)
        
        toButton.isArrowHidden = true
        toButton.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        toButton.setTitle(toDate.formattedString, for: UIControlState.normal)
    }
    
    func setupChart() {
        chartView.noDataText = "No telemetry data available"
        
        chartView.backgroundColor = .gray1
        
        chartView.minOffset = 20.0
        
        chartView.extraLeftOffset = 10.0
        chartView.extraBottomOffset = 10.0
        
        chartView.chartDescription?.enabled  = false
        chartView.legend.enabled = false
        
        chartView.scaleYEnabled = false
        
        chartView.rightAxis.enabled = false

        chartView.leftAxis.drawAxisLineEnabled = false
        chartView.leftAxis.axisLineColor = .gray2
        chartView.leftAxis.gridColor = .gray2
        chartView.leftAxis.labelTextColor = .white
        
        chartView.xAxis.axisLineColor = .gray2
        chartView.xAxis.labelTextColor = .white
        chartView.xAxis.valueFormatter = self
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.labelCount = 4
        chartView.xAxis.drawGridLinesEnabled = false
    }
    
    func loadTelemetries() {
        
        if let deviceHid = device?.loadDeviceId() {
            if selectedTelemetry != nil {
                
                showActivityIndicator(forView: chartView)                
                
                ArrowConnectIot.sharedInstance.deviceTelemetries(hid: deviceHid, fromDate: fromDate, toDate: toDate, telemetry: self.selectedTelemetry!.telemetryName) { telemetries in
                    
                    DispatchQueue.main.async { [unowned self] in
                        if telemetries != nil {
                            
                            var dataEntries: [ChartDataEntry] = []
                            
                            for telemetry in telemetries! {
                                if telemetry.name == self.selectedTelemetry!.telemetryName {
                                    if let dataEntry = self.getDataEntry(from: telemetry) {
                                        dataEntries.append(dataEntry)
                                    }
                                }
                            }
                            
                            if dataEntries.count > 0 {
                                let chartDataSet = LineChartDataSet(values: dataEntries, label: self.selectedTelemetry!.rawValue)
                                chartDataSet.drawValuesEnabled = false
                                chartDataSet.setColor(.mainColor2)
                                chartDataSet.setCircleColor(.mainColor2)
                                chartDataSet.lineWidth = 3.0
                                chartDataSet.circleRadius = 5.0
                                chartDataSet.drawCircleHoleEnabled = false
                                
                                let chartData = LineChartData(dataSet: chartDataSet)
                                self.chartView.data = chartData
                            } else {
                                self.chartView.clear()
                            }
                            
                            
                        }
                        self.hideActivityIndicator()
                    }
                }
            }
        }
    }
    
    func getDataEntry(from telemetry: TelemetryModel) -> ChartDataEntry? {
        
        let x = telemetry.timestamp / 1000 - fromDate.timeIntervalSince1970

        if telemetry.type == "Float" {
            return ChartDataEntry(x: x, y: telemetry.floatValue!)
        } else if telemetry.type == "Integer" {
            return ChartDataEntry(x: x, y: Double(telemetry.intValue!))
        } else {
            return nil
        }
    }
    
    @IBAction func dateButtonClicked(_ sender: UIButton) {
        if let selectDateViewController = self.storyboard?.instantiateViewController(withIdentifier: "SelectDateViewController") as? SelectDateViewController {
            selectDateViewController.setupWith(fromDate: fromDate, toDate: toDate)
            selectDateViewController.delegate = self
            pushWithToolbar(controller: selectDateViewController)
        }
    }
    
    @IBAction func selectTelemetryClicked(_ sender: UIButton) {
        if let selectTelemetryViewController = self.storyboard?.instantiateViewController(withIdentifier: "SelectTelemetryViewController") as? SelectTelemetryViewController {
            selectTelemetryViewController.device = device
            selectTelemetryViewController.delegate = self
            pushWithToolbar(controller: selectTelemetryViewController)
        }
    }
    
    // MARK: SelectDateViewControllerDelegate
    
    func didSelect(sender: SelectDateViewController, fromDate: Date, toDate: Date) {
        self.fromDate = fromDate
        self.toDate = toDate
        setupDateButtons()
        loadTelemetries()
    }
    
    // MARK: SelectTelemetryViewControllerDelegate
    
    func didSelectTelemetry(sender: SelectTelemetryViewController, telemetry: SensorType) {
        selectedTelemetry = telemetry
        selectTelemetryButton.setTitle(telemetry.rawValue, for: UIControlState.normal)
        loadTelemetries()
    }
    
    // MARK: IAxisValueFormatter
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter.string(from: Date(timeIntervalSince1970: value + self.fromDate.timeIntervalSince1970))
    }
}

