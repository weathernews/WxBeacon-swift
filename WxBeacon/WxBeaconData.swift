//
//  WxBeaconData.swift
//  WxBeacon
//
//  Copyright © 2015年 Weathernews. All rights reserved.
//

import Foundation
import CoreLocation

class WxBeaconData {
    var temperature: Double  // -30.0〜72.3℃
    var humidity: Double     // 0〜100%
    var pressure: Double     // 300.0〜1119.1 hPa
    var counter: Int
    
    // MARK: -
    init(beacon:CLBeacon!) {
        let major: u_short = beacon.major.unsignedShortValue;
        let minor: u_short = beacon.minor.unsignedShortValue;
        
        let tempData = (major >> 4) & 0x3ff;
        let humiData = (((major << 3) & 0x78) | ((minor >> 13) & 0x0007));
        let presData = minor & 0x1fff;
        
        temperature = (Double(tempData) * 100 - 30000) / 1000.0
        humidity    = (Double(humiData) * 1000) / 1000.0
        if( humidity > 100.0 ){
            humidity = 100.0
        }
        pressure = (Double(presData) + 3000) / 10.0
        counter  = Int(major >> 14)
    }
    
    func description() -> String {
        return String(format: "temperature:%.1fC, humidity:%.0f%%, pressure:%.1fhPa, counter:%d", temperature, humidity, pressure, counter)
    }
}