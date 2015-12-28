WxBeacon
========

概要
------
WxBeacon は気温、湿度、気圧を観測し、iBeacon の仕組みを利用して送信するデバイスです。  
本ライブラリは、iOS端末で WxBeacon のデータを受信して画面に観測値を表示するサンプルコードです。  
WxBeacon はウェザーニュースタッチの有料会員のうち、ウェザーリポート送信などで 2000pt を達成した方にプレゼントしています。  
![WxBeacon](WxBeacon.jpg)

Requirement
--------
iOS 8.0以降、Bluetooth, 位置情報の利用許可が必要です。  
(WxBeacon の受信自体はiOS 7.0以降で可能ですが、本サンプルではエラー表示にUIAlertController を使用しているため、iOS 8.0以降を対象としています。)


How to use
--------
1. `WxBeaconData.swift` と `WxBeaconMonitor.swift` をあなたのXcode の project にコピーしてください。
2. データ表示を行いたいclass で、WxBeaconMonitorDelegate protocol に沿って実装してください。
3. 下記のように WxBeaconMonitor を初期化してください。
    let beaconMonitor = WxBeaconMonitor()
    beaconMonitor.delegate = self
    beaconMonitor.startMonitoring(nil, backgroundFlag: true)
4. WxBeacon の値を受信すると、func didUpdateWeatherData(data: WxBeaconData?) が呼び出されます。
