//
//  WxBeaconMonitor.swift
//  WxBeacon
//
//  Copyright © 2015年 Weathernews. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CoreBluetooth

let WxBeaconProxyimityUuid = "C722DB4C-5D91-1801-BEB5-001C4DE7B3FD"  // UUID for WxBeacon

// MARK: - protocol WxBeaconMonitorDelegate
@objc protocol WxBeaconMonitorDelegate: class {
    func didUpdateWeatherData(_ data: WxBeaconData?)
    func showAlert(_ message: String)
    @objc optional func didEnterBeaconRegion()
    @objc optional func didExitBeaconRegion()
}

// MARK: - class WxBeaconMonitor
class WxBeaconMonitor: NSObject, CLLocationManagerDelegate, CBCentralManagerDelegate {
    var delegate: WxBeaconMonitorDelegate?
    
    private var locationManager = CLLocationManager()
    private var centralManager  = CBCentralManager()

    private var beaconRegion:  CLBeaconRegion? = nil
    private var currentRegion: CLBeaconRegion? = nil
    private var markCurrentRegion = false

    private var backgroundEnable = true
    private var backgroundTask = UIBackgroundTaskInvalid
    
    // MARK: -
    override init() {
        super.init()
        
        locationManager.delegate = self

        let option = [ CBCentralManagerOptionShowPowerAlertKey: false ]
        centralManager = CBCentralManager.init(delegate: self, queue: nil, options: option)
        self.checkBluetoothStatus()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(self.enterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        notificationCenter.addObserver(self, selector: #selector(self.enterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Beaconのモニタリングを開始する
    func startMonitoring(_ backgroundFlag: Bool) {
        let uuid = UUID(uuidString: WxBeaconProxyimityUuid)
        
        print("startMonitoring UUID:\(uuid!.uuidString), backgroundFlag:\(backgroundFlag)")
        backgroundEnable = backgroundFlag

        switch( CLLocationManager.authorizationStatus() ){
        case .authorizedAlways, .authorizedWhenInUse:
            beaconRegion = CLBeaconRegion.init(proximityUUID: uuid!, identifier: "WxBeacon")
            locationManager.startMonitoring(for: beaconRegion!)
            locationManager.requestState(for: beaconRegion!)
        default:
            break
        }
    }
    
    // Beaconのモニタリングを停止する
    func stopMonitoring() {
        guard let beaconRegion = beaconRegion else { return }
        locationManager.stopRangingBeacons(in: beaconRegion)
        locationManager.stopMonitoring(for: beaconRegion)
        self.beaconRegion = nil
        
        guard let currentRegion = currentRegion else  { return }
        locationManager.stopMonitoring(for: currentRegion)
        self.currentRegion = nil
    }
    
    func suspendMonitoring() {
        guard let beaconRegion = beaconRegion else { return }
        locationManager.stopRangingBeacons(in: beaconRegion)
        locationManager.stopMonitoring(for: beaconRegion)
        
        guard let currentRegion = currentRegion else  { return }
        locationManager.stopMonitoring(for: currentRegion)
    }
    
    func resumeMonitoring() {
        guard let beaconRegion = beaconRegion else { return }
        locationManager.startMonitoring(for: beaconRegion)
        locationManager.requestState(for: beaconRegion)

        guard let currentRegion = currentRegion else  { return }
        locationManager.startMonitoring(for: currentRegion)
    }
    
    // アプリがバックグラウンドに入った時の処理
    func enterBackground() {
        if backgroundEnable {
            if backgroundTask == UIBackgroundTaskInvalid {
                print("Begin background task.")
                let application = UIApplication.shared
                backgroundTask = application.beginBackgroundTask(expirationHandler: {
                    print("End background task.")
                    application.endBackgroundTask(self.backgroundTask)
                    self.backgroundTask = UIBackgroundTaskInvalid
                })
            }
        } else {
            self.suspendMonitoring()
        }
    }
    
    // アプリがバックグラウンドから復帰した時の処理
    func enterForeground() {
        if backgroundEnable {
            if backgroundTask != UIBackgroundTaskInvalid {
                print("End background task.")
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTask = UIBackgroundTaskInvalid
            }
        } else {
            self.resumeMonitoring()
        }
    }
    
    func selectBeacon(_ beacons: [CLBeacon]) -> CLBeacon? {
        // beacons は RSSI の大きい順にソートされているが、
        // CLProximityUnknown の場合は RSSI が 127 になり、beacons の先頭に
        // 来るので、それを考慮して一番 RSSI の大きい beacon を返す。
        for beacon in beacons {
            if beacon.proximity != .unknown {
                return beacon
            }
        }

        // beacons.count = 0 か、beacons の全てが CLProximityUnknown の場合
        return beacons.first
    }

    func checkBluetoothStatus() {
        var message: String? = nil
        
        switch centralManager.state {
        case .unknown:
            print("Bluetooth Unknown")
        case .resetting:
            print("Bluetooth Resetting")
        case .unsupported:
            message = "この端末はBluetoorhをサポートしていません"
        case .unauthorized:
            message = "Bluetoothの利用を許可してください"
        case .poweredOff:
            message = "Bluetoothの利用を許可してください"
        case .poweredOn:
            print("Bluetooth PowerOn")
        }
        
        if let message = message {
            delegate?.showAlert(message)
        }
    }
    
    func CLRegionStateString(_ state: CLRegionState) -> String {
        switch state {
        case .inside:
            return "Inside"
        case .outside:
            return "OutSide"
        case .unknown:
            return "Unknown"
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("CLAuthorizationStatus NotDetermined")
            locationManager.requestAlwaysAuthorization()
            return
            
        case .authorizedAlways, .authorizedWhenInUse:
            print("CLAuthorizationStatus Authorized")
            if beaconRegion == nil {
                self.startMonitoring(backgroundEnable)
            }
            return
            
        case .restricted:
            print("CLAuthorizationStatus Restricted")
            
        case .denied:
            print("CLAuthorizationStatus Denied")
        }
        
        // Alert表示
        delegate?.showAlert("位置情報が利用できません。")
        delegate?.didUpdateWeatherData(nil)
        self.stopMonitoring()
    }
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if UIApplication.shared.applicationState == .background {
            self.enterBackground()
        }
        
        if region.identifier == beaconRegion?.identifier {
            print("BeaconRegion changed. \(self.CLRegionStateString(state))")
            
            switch state {
            case .inside:
                locationManager.startRangingBeacons(in: beaconRegion!)
                print("Ranging started. \(beaconRegion!.identifier)")
                markCurrentRegion = true
                
            case .outside:
                locationManager.stopRangingBeacons(in: beaconRegion!)
                print("Ranging stopped. \(beaconRegion!.identifier)")
                
            default:
                break
            }
        }
        
        if state == .outside && region.identifier == currentRegion?.identifier {
            // モニタしていたRegionからExitしたので、新たに現在のRegionをマークすることを要求する
            markCurrentRegion = true
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("didEnterRegion: \(region.identifier)")
        if region.identifier == beaconRegion?.identifier {
            delegate?.didEnterBeaconRegion?()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("didExitRegion: \(region.identifier)")
        if region.identifier == beaconRegion?.identifier {
            delegate?.didExitBeaconRegion?()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        //print("didRangeBeacons")
        // 複数のBeaconが見つかった場合一番近い1つを取得する
        guard let beacon = selectBeacon(beacons) else {
            print("beacon is nil !!!")
            return
        }
        
        // beacon の major, minor の値を気象観測値として解釈
        let wxdata = WxBeaconData(beacon: beacon)
        print("\(Date()) beacon rssi:\(beacon.rssi), \(wxdata.description)")
        delegate?.didUpdateWeatherData(wxdata)
        
        if markCurrentRegion {
            if let currentRegion = currentRegion {
                // 以前のRegionのモニタリングを停止する
                locationManager.stopMonitoring(for: currentRegion)
            }
            // 新たなRegionのモニタリングを開始する
            currentRegion = CLBeaconRegion.init(proximityUUID: beacon.proximityUUID,
                                                major: beacon.major.uint16Value,
                                                minor: beacon.minor.uint16Value,
                                                identifier: "currentRegion")
            locationManager.startMonitoring(for: currentRegion!)
            markCurrentRegion = false  // マーク要求をクリアする
        }
    }

    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.checkBluetoothStatus()
    }
    
}
