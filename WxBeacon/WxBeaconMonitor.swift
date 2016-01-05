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
    func didUpdateWeatherData(data: WxBeaconData?)
    func showAlert(message: String)
    optional func didEnterBeaconRegion()
    optional func didExitBeaconRegion()
}

// MARK: - class WxBeaconMonitor
class WxBeaconMonitor: NSObject, CLLocationManagerDelegate, CBCentralManagerDelegate {
    var delegate: WxBeaconMonitorDelegate?
    
    private var locationManager: CLLocationManager = CLLocationManager()
    private var centralManager: CBCentralManager = CBCentralManager()

    private var beaconRegion: CLBeaconRegion? = nil
    private var currentRegion: CLBeaconRegion? = nil
    private var markCurrentRegion: Bool = false

    private var backgroundEnable: Bool = true
    private var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    // MARK: -
    override init() {
        super.init()
        locationManager.delegate = self

        let option = [ CBCentralManagerOptionShowPowerAlertKey: false ]
        centralManager = CBCentralManager.init(delegate: self, queue: nil, options: option)
        self.checkBluetoothStatus()
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "enterBackground", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: "enterForeground", name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    deinit {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    // Beaconのモニタリングを開始する
    func startMonitoring(backgroundFlag:Bool) {
        let uuid = NSUUID(UUIDString: WxBeaconProxyimityUuid)
        
        print("startMonitoring UUID:\(uuid!.UUIDString), backgroundFlag:\(backgroundFlag)")
        backgroundEnable = backgroundFlag

        switch( CLLocationManager.authorizationStatus() ){
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            beaconRegion = CLBeaconRegion.init(proximityUUID: uuid!, identifier: "WxBeacon")
            locationManager.startMonitoringForRegion(beaconRegion!)
            locationManager.requestStateForRegion(beaconRegion!)
            break
        default:
            break
        }
    }
    
    // Beaconのモニタリングを停止する
    func stopMonitoring() {
        if beaconRegion != nil {
            locationManager.stopRangingBeaconsInRegion(beaconRegion!)
            locationManager.stopMonitoringForRegion(beaconRegion!)
            beaconRegion = nil
            
            if currentRegion != nil {
                locationManager.stopMonitoringForRegion(currentRegion!)
                currentRegion = nil
            }
        }
    }
    
    func suspendMonitoring() {
        if beaconRegion != nil {
            locationManager.stopRangingBeaconsInRegion(beaconRegion!)
            locationManager.stopMonitoringForRegion(beaconRegion!)
            if currentRegion != nil {
                locationManager.stopMonitoringForRegion(currentRegion!)
            }
        }
    }
    
    func resumeMonitoring() {
        if beaconRegion != nil {
            locationManager.startMonitoringForRegion(beaconRegion!)
            locationManager.requestStateForRegion(beaconRegion!)
            if currentRegion != nil {
                locationManager.startMonitoringForRegion(currentRegion!)
            }
        }
    }
    
    // アプリがバックグラウンドに入った時の処理
    func enterBackground() {
        if backgroundEnable {
            if backgroundTask == UIBackgroundTaskInvalid {
                print("Begin background task.")
                let application = UIApplication.sharedApplication()
                backgroundTask = application.beginBackgroundTaskWithExpirationHandler({
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
                UIApplication.sharedApplication().endBackgroundTask(backgroundTask)
                backgroundTask = UIBackgroundTaskInvalid
            }
        } else {
            self.resumeMonitoring()
        }
    }
    
    func selectBeacon(beacons: [CLBeacon]) -> CLBeacon? {
        // beacons は RSSI の大きい順にソートされているが、
        // CLProximityUnknown の場合は RSSI が 127 になり、beacons の先頭に
        // 来るので、それを考慮して一番 RSSI の大きい beacon を返す。
        for beacon in beacons {
            if beacon.proximity != .Unknown {
                return beacon
            }
        }

        // beacons.count = 0 か、beacons の全てが CLProximityUnknown の場合
        return beacons.first
    }

    func checkBluetoothStatus() {
        var message: String? = nil
        
        switch centralManager.state {
        case .Unknown:
            print("Bluetooth Unknown")
        case .Resetting:
            print("Bluetooth Resetting")
        case .Unsupported:
            message = "この端末はBluetoorhをサポートしていません"
        case .Unauthorized:
            message = "Bluetoothの利用を許可してください"
        case .PoweredOff:
            message = "Bluetoothの利用を許可してください"
        case .PoweredOn:
            print("Bluetooth PowerOn")
        }
        
        if message != nil {
            delegate?.showAlert(message!)
        }
    }
    
    func CLRegionStateString(state: CLRegionState) -> String {
        switch state {
        case .Inside:
            return "Inside"
        case .Outside:
            return "OutSide"
        case .Unknown:
            return "Unknown"
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .NotDetermined:
            print("CLAuthorizationStatus NotDetermined")
            locationManager.requestAlwaysAuthorization()
            return
            
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            print("CLAuthorizationStatus Authorized")
            if beaconRegion == nil {
                self.startMonitoring(backgroundEnable)
            }
            return
            
        case .Restricted:
            print("CLAuthorizationStatus Restricted")
            break
            
        case .Denied:
            print("CLAuthorizationStatus Denied")
            break
        }
        
        // Alert表示
        delegate?.showAlert("位置情報が利用できません。")
        delegate?.didUpdateWeatherData(nil)
        self.stopMonitoring()
    }
    
    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        if UIApplication.sharedApplication().applicationState == .Background {
            self.enterBackground()
        }
        
        if region.identifier == beaconRegion?.identifier {
            print("BeaconRegion changed. \(self.CLRegionStateString(state))")
            
            switch state {
            case .Inside:
                locationManager.startRangingBeaconsInRegion(beaconRegion!)
                print("Ranging started. \(beaconRegion!.identifier)")
                markCurrentRegion = true
                
            case .Outside:
                locationManager.stopRangingBeaconsInRegion(beaconRegion!)
                print("Ranging stopped. \(beaconRegion!.identifier)")
                
            default:
                break
            }
        }
        
        if state == .Outside && region.identifier == currentRegion?.identifier {
            // モニタしていたRegionからExitしたので、新たに現在のRegionをマークすることを要求する
            markCurrentRegion = true
        }
    }

    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("didEnterRegion: \(region.identifier)")
        if region.identifier == beaconRegion?.identifier {
            delegate?.didEnterBeaconRegion?()
        }
    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("didExitRegion: \(region.identifier)")
        if region.identifier == beaconRegion?.identifier {
            delegate?.didExitBeaconRegion?()
        }
    }
    
    func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        //print("didRangeBeacons")
        // 複数のBeaconが見つかった場合一番近い1つを取得する
        let beacon = selectBeacon(beacons)
        
        if beacon != nil {
            // beacon の major, minor の値を気象観測値として解釈
            let wxdata = WxBeaconData.init(beacon: beacon)
            print("\(NSDate()) beacon rssi:\(beacon!.rssi), \(wxdata.description)")
            delegate?.didUpdateWeatherData(wxdata)
            
            if markCurrentRegion {
                if currentRegion != nil {
                    // 以前のRegionのモニタリングを停止する
                    locationManager.stopMonitoringForRegion(currentRegion!)
                }
                // 新たなRegionのモニタリングを開始する
                currentRegion = CLBeaconRegion.init(proximityUUID: beacon!.proximityUUID,
                                                            major: beacon!.major.unsignedShortValue,
                                                            minor: beacon!.minor.unsignedShortValue,
                                                       identifier: "currentRegion")
                locationManager.startMonitoringForRegion(currentRegion!)
                markCurrentRegion = false  // マーク要求をクリアする
            }
        } else {
            print("beacon is nil !!!")
        }
    }

    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager) {
        self.checkBluetoothStatus()
    }
    
}