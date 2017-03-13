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
    
    private let beaconMonitor = WxBeaconMonitor()
    private let dateFormatter: DateFormatter = {
        let formatter        = DateFormatter()
        formatter.timeZone   = NSTimeZone.system
        formatter.locale     = Locale(identifier: "ja_JP")
        formatter.calendar   = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter
    }()
    
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        beaconMonitor.delegate = self
        beaconMonitor.startMonitoring(true)
        
        self.didUpdateWeatherData(nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - WxBeaconMonitorDelegate
    func didUpdateWeatherData(_ data: WxBeaconData?) {
        guard let data = data else {
            dateLabel.text        = "-"
            temperatureLabel.text = "-"
            humidityLabel.text    = "-"
            pressureLabel.text    = "-"
            return
        }
        
        dateLabel.text        = dateFormatter.string(from: Date())
        temperatureLabel.text = String(format: "%.1f℃",   data.temperature)
        humidityLabel.text    = String(format: "%.0f%%",  data.humidity)
        pressureLabel.text    = String(format: "%.1fhPa", data.pressure)
    }
    
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}

