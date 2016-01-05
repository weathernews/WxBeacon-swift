//
//  ViewController.swift
//  WxBeacon
//
//  Copyright © 2015年 Weathernews. All rights reserved.
//

import UIKit

class ViewController: UIViewController, WxBeaconMonitorDelegate {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var pressureLabel: UILabel!
    
    private var beaconMonitor: WxBeaconMonitor!
    private var dateFormatter: NSDateFormatter!
    
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "ja_JP")
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"

        beaconMonitor = WxBeaconMonitor()
        beaconMonitor.delegate = self
        beaconMonitor.startMonitoring(true)
        
        self.didUpdateWeatherData(nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - WxBeaconMonitorDelegate
    func didUpdateWeatherData(data: WxBeaconData?) {
        if data != nil {
            dateLabel.text        = dateFormatter.stringFromDate(NSDate())
            temperatureLabel.text = String(format: "%.1f℃",   data!.temperature)
            humidityLabel.text    = String(format: "%.0f%%",  data!.humidity)
            pressureLabel.text    = String(format: "%.1fhPa", data!.pressure)
        } else {
            dateLabel.text        = "-"
            temperatureLabel.text = "-"
            humidityLabel.text    = "-"
            pressureLabel.text    = "-"
        }
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

