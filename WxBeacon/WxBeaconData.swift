//
//  WxBeaconData.swift
//  WxBeacon
//
//  Copyright © 2015年 Weathernews. All rights reserved.
//

import Foundation
import CoreLocation

@objc class WxBeaconData: NSObject {
    let temperature: Double  // -30.0〜72.3℃
    let humidity: Double     // 0〜100%
    let pressure: Double     // 300.0〜1119.1 hPa
    let counter: Int
    
    // MARK: -
    init(beacon: CLBeacon) {
        let major = beacon.major.uint16Value
        let minor = beacon.minor.uint16Value
        
        let tempData = (major >> 4) & 0x3ff
        let humiData = (((major << 3) & 0x78) | ((minor >> 13) & 0x0007))
        let presData = minor & 0x1fff
        
        temperature = (Double(tempData) * 100 - 30000) / 1000.0
        let hum = (Double(humiData) * 1000) / 1000.0
        humidity = ( hum < 100.0 ) ? hum : 100.0
        pressure = (Double(presData) + 3000) / 10.0
        counter  = Int(major >> 14)
    }
    
    override var description: String {
        return String(format: "temperature:%.1fC, humidity:%.0f%%, pressure:%.1fhPa, counter:%d", temperature, humidity, pressure, counter)
    }
}
