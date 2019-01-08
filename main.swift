//
//  main.swift
//  Sample
//
//  Created by 津森智己 on 2018/10/11.
//  Copyright © 2018年 津森智己. All rights reserved.
//

// 使用可能コマンド一覧
//  sendFile        : ファイル送信
//  setSysColor     : システムカラー変更
//  resetColor      : システムカラーリセット
//  ~;              : コマンドモード
//  quit            : コマンドモード終了
//  disconnect      : 通信切断
//  ~.              : プログラム終了

import Foundation
import CoreBluetooth
import Cocoa

extension Data {
    private static let hexAlphabet = "0123456789abcdef".unicodeScalars.map { $0 }
    
    public func hexEncodedString() -> String {
        return String(self.reduce(into: "".unicodeScalars, { (result, value) in
            result.append(Data.hexAlphabet[Int(value/16)])
            result.append(Data.hexAlphabet[Int(value%16)])
        }))
    }
}

extension String {
    // ASCII文字(制御コード以外)判定
    func isAlphanumeric() -> Bool {
        return self >= "\u{20}" && self <= "\u{7e}"
    }
    // ASCII文字判定
    func isASCII() -> Bool {
        return self >= "\u{00}" && self <= "\u{7f}"
    }
}

// 一度にBluetoothデバイスに送信できる最大文字数
let maxLength = 20
// プログラム終了を検知するための配列
var end = [String]()
// 選択デバイス番号
var selectNumber = 0
// システムカラー
var highLightColor = "\u{1b}[36m"

class RN4020: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // Bluetooth関連変数
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var myservice: CBService!
    var settingCharacteristic: CBCharacteristic!
    var outputCharacteristic: CBCharacteristic!
    
    // 発見デバイス一覧
    var discoverDevice = [CBPeripheral]()
    // デバイス番号
    var deviceNumber = 0
    
    // その他の変数
    var isScanning = false
    var ready = false
    var full = false
    var count = 0
    
    // ターゲットデバイス名
    var target_peripheral_name = ""
    // MLDPのサービスのUUID
    let target_service_uuid = CBUUID(string: "00035B03-58E6-07DD-021A-08123A000300")
    let target_charactaristic_uuid = CBUUID(string: "00035B03-58E6-07DD-021A-08123A000301")
    let target_charactaristic_uuid2 = CBUUID(string: "00035B03-58E6-07DD-021A-08123A0003FF")
    
    let standardOutput = FileHandle.standardOutput
    
    // インスタンスの生成および初期化
    func generation() {
        // 生成後，centralManatgerDidUpdateState:メソッドを呼び出す(セントラルマネージャの状態を変化させる)
        centralManager = CBCentralManager(delegate: self as CBCentralManagerDelegate, queue: nil, options: nil)
    }
    
    // BLEデバイスの検出を開始
    func startScan() {
        // 第一引数でMLDPのサービスを指定
        centralManager.scanForPeripherals(withServices:[target_service_uuid], options: nil)
        isScanning = false
    }
    
    // セントラルマネージャの状態が変化すると呼ばれる
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // ペリフェラルスキャンを許可する
        isScanning = true
        
        switch central.state {
        case .poweredOff:
            systemOutput(str: "Bluetooth power OFF\r\n")
            exit(0)
        case .poweredOn:
            systemOutput(str: "Bluetooth power ON\r\n")
        case .resetting:
            systemOutput(str: "Resetting\r\n")
        case .unauthorized:
            systemOutput(str: "Unauthenticated\r\n")
            exit(0)
        case .unknown:
            systemOutput(str: "Unknown\r\n")
            exit(0)
        case .unsupported:
            systemOutput(str: "Unsupported\r\n")
            exit(0)
        }
    }
    
    // ペリフェラルを発見すると呼ばれる
    // CBPeripheralオブジェクトの形で発見したPeripheralを受け取る
    func centralManager(_ central: CBCentralManager,didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // ペリフェラル名がnilではない かつ 初回発見　のとき
        if peripheral.name != nil && !discoverDevice.contains(peripheral) {
            // デバイス番号を増やす
            deviceNumber += 1
            // 発見デバイスを表示する
            standardOutput.write("deviceNumber \(deviceNumber) : \(peripheral.name!)\r\n".data(using: .utf8)!)
            discoverDevice.append(peripheral)
        }
    }
    
    // ペリフェラルへ接続する関数
    func connect(_ number: Int) -> Bool {
        // デバイス番号が間違っているとき
        if number > discoverDevice.count || number < 1 {
            systemOutput(str: "Invalid Device Number\r\n")
            return false
        }
        
        // 接続するペリフェラルを記憶する
        self.peripheral = discoverDevice[number - 1]
        // 省電力のために探索を停止
        centralManager?.stopScan()
        //接続開始
        centralManager.connect(peripheral, options: nil)
    
        return true
    }
    
    // ペリフェラルへの接続が成功すると呼ばれる
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral.name != nil {
            systemOutput(str: "Connection Success\r\ndeviceName : \(peripheral.name!)\r\n")
        }
        
        // サービス探索結果を受け取るためにデリゲートをセット
        self.peripheral.delegate = self as CBPeripheralDelegate
        
        // サービス探索開始
        self.peripheral.discoverServices([target_service_uuid])
    }
    
    // サービス発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if error != nil {
            print(error.debugDescription)
            return
        }
        
        guard let services = peripheral.services, services.count > 0 else {
            systemOutput(str: "No Services\r\n")
            return
        }
        
        for service in services {
            // キャラクタリスティックを探索開始
            self.peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // キャラクタリスティック発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print(error.debugDescription)
            return
        }
        
        guard let characteristics = service.characteristics, characteristics.count > 0 else {
            systemOutput(str: "No Characteristics\r\n")
            return
        }
        
        for characteristic in characteristics where characteristic.uuid.isEqual(target_charactaristic_uuid) {
            
            // 文字を出力するキャラクタリスティックを指定する
            outputCharacteristic = characteristic
            
            peripheral.readValue(for: characteristic)
            
            // 更新通知受け取りを開始する
            peripheral.setNotifyValue(true, for: characteristic)
            
            // データを送信してMLDPモードにする
            let str = "CONNECT\r\n"
            let data = str.data(using: String.Encoding.utf8)
            peripheral.writeValue(data!, for: outputCharacteristic, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    // Notify開始／停止時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            systemOutput(str: "\(error.debugDescription)\r\n")
            return
        }
        
        // 書き込み許可のフラグをたてる
        ready = true
    }
    
    // データ更新時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            // 受け取ったデータがnilではないとき
            if characteristic.value != nil {
                systemOutput(str: "\(error.debugDescription)\r\n")
            }
            return
        }
        
        // Bluetoothから送信されたデータを取り出す
        let data = characteristic.value
        
        // データが存在するとき
        if data != nil {
            // 送信されたデータを標準出力する
            responseCommand(data: data!)
        }
    }
    
    // データ書き込みが完了すると呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        // 失敗したらエラー文を出力する
        if error != nil {
            systemOutput(str: "Write failed...error: \(error.debugDescription), characteristic uuid: \(characteristic.uuid)\r\n")
            return
        }
    }
    
    // Bluetoothからの入力を標準出力する
    func responseCommand(data: Data) {
        var response = data
        // CRの場合は改行に置き換える
        if String(data: data, encoding: .utf8) == "\r" {
            response = "\r\n".data(using: .utf8)!
        }
        // 標準出力
        let standardOutput = FileHandle.standardOutput
        standardOutput.write(response)
    }
    
}

// Bluetoothに書き込むプロセス
func writeProcess(_ rn: RN4020) {
    let standardInput = FileHandle.standardInput
    let standardOutput = FileHandle.standardOutput
    // モード切替のフラグ
    var cmdMode = false
    // コマンド
    var cmd = ""
    // 標準入力を待ち続ける
    while true {
        // 標準入力
        let input = standardInput.availableData
        let dataString = String(NSString(data: input, encoding: String.Encoding.utf8.rawValue) ?? "")
        
        // ASCII文字以外のとき
        if !dataString.isASCII() {
            continue
        }
        
        // コマンドモードのとき
        if cmdMode {
            // 改行のとき
            if dataString == "\r" {
                // 改行出力
                standardOutput.write("\r\n".data(using: .utf8)!)
                // コマンドを空白で分割する
                let cmdArray = cmd.components(separatedBy: " ")
                // 正しいコマンドのとき
                // ファイル送信コマンド
                if cmdArray[0] == "sendFile" {
                    // NSOpenPanel(viewの更新)はメインスレッドでのみ実行可能
                    DispatchQueue.main.async {
                        // 読み込みファイルを選択し，データを送信する
                        fileSelect(rn)
                    }
                }
                // 文字色変更コマンド
                else if cmdArray[0] == "setSysColor" {
                    if cmdArray.count == 1  || cmdArray[1] == "" {
                        systemOutput(str: "Syntax error : setSysColor [color]\r\n")
                    }
                    else {
                        var valid = true
                        switch cmdArray[1] {
                        case "black":
                            highLightColor = "\u{1b}[30m"
                        case "red":
                            highLightColor = "\u{1b}[31m"
                        case "green":
                            highLightColor = "\u{1b}[32m"
                        case "yellow":
                            highLightColor = "\u{1b}[33m"
                        case "blue":
                            highLightColor = "\u{1b}[34m"
                        case "magenta":
                            highLightColor = "\u{1b}[35m"
                        case "cyan":
                            highLightColor = "\u{1b}[36m"
                        case "white":
                            highLightColor = "\u{1b}[37m"
                        default :
                            systemOutput(str: "\(cmdArray[1]) is Invalid color\r\navailable color : [black, red, green, yellow, blue, magenta, cyan, white]\r\n")
                            valid = false
                        }
                        if valid {
                            systemOutput(str: "SystemColor Changed\r\n")
                        }
                    }
                }
                // 文字色初期化コマンド
                else if cmdArray[0] == "resetColor" {
                    highLightColor = "\u{1b}[36m"
                    systemOutput(str: "SystemColor Changed\r\n")
                }
                // cmdMode終了コマンド
                else if cmdArray[0] == "quit" {
                    // コマンドモードを終了する
                    cmdMode = false
                    // 終了を出力する
                    systemOutput(str: "rawMode\r\n")
                }
                // cmdModeコマンド
                else if cmdArray[0] == "~;" {
                    systemOutput(str: "Already in commandMode\r\n")
                }
                // 通信切断コマンド
                else if cmdArray[0] == "disconnect" {
                    // 通知を切る
                    rn.peripheral.setNotifyValue(false, for: rn.outputCharacteristic)
                    // 通信を切断する
                    rn.centralManager.cancelPeripheralConnection(rn.peripheral)
                    // スレッド終了
                    return
                }
                // コマンドではなかったとき
                else {
                    if cmdArray[0] != "" {
                        systemOutput(str: "\(cmdArray[0]): Command not found.\r\n")
                    }
                }
                // コマンドを初期化
                cmd = ""
            }
            // それ以外のとき
            else {
                // 標準出力
                standardOutput.write(dataString.data(using: .utf8)!)
                // 英数字のとき
                if dataString.isAlphanumeric() {
                    // コマンドとして記憶する
                    cmd.append(dataString)
                }
                // deleteのとき
                else if dataString == "\u{7f}" {
                    // コマンドから一文字削除する
                    if cmd.count > 0 {
                        cmd.removeLast()
                    }
                    // 表示を一字消す
                    standardOutput.write("\u{08}".data(using: .utf8)!)
                    standardOutput.write(" ".data(using: .utf8)!)
                    standardOutput.write("\u{08}".data(using: .utf8)!)
                }
            }
        }
        // 通信モードのとき
        else {
            // ペリフェラルにデータを書き込む
            let data = dataString.data(using: String.Encoding.utf8)
            // データが存在するとき
            if data != nil {
                rn.peripheral.writeValue(data!, for: rn.outputCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
        
        // 入力文字が"~."になると終了する
        // 入力文字が"~;"になるとコマンドモードになる
        if end.count == 2 {
            end[0] = end[1]
            end.removeLast()
        }
        end.append(dataString)
        // 終了コマンドのとき
        if end.joined() == "~." {
            close(rn)
        }
        // コマンドモードになるとき
        else if end.joined() == "~;" && !cmdMode {
            // コマンドモード用のフラグを立てる
            cmdMode = true
            // コマンドモードになったことを出力する
            systemOutput(str: "commandMode\r\n")
        }
    }

}

// 読み込みファイルを選択する関数
func fileSelect(_ rn: RN4020) {
    let openPanel = NSOpenPanel()
    // 複数ファイルの選択を許さない
    openPanel.allowsMultipleSelection = false
    // ディレクトリを選択させない
    openPanel.canChooseDirectories = false
    // ディレクトリを作成させない
    openPanel.canCreateDirectories = false
    // ファイルを選択させる
    openPanel.canChooseFiles = true
    // ファイルの種類を制限する
    openPanel.allowedFileTypes = ["out", "exe", "bin"]
    // ウィンドウを最前面に表示する
    openPanel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
    
    // OKが押されたとき
    if openPanel.runModal().rawValue == NSApplication.ModalResponse.OK.rawValue {
        if let url = openPanel.url {
            var content: Data? = nil
            do {
                content = try NSData(contentsOf: url) as Data
            }
            catch {
                print(error)
            }
            
            if content == nil {
                return
            }
            
            var index = 0
            var range = 0
            var end = false
            while !end {
                if content!.count - index < maxLength {
                    range = content!.count - index
                    end = true
                }
                else {
                    range = maxLength
                }
                rn.peripheral.writeValue(content!.subdata(in: index..<index + range), for: rn.outputCharacteristic, type: CBCharacteristicWriteType.withResponse)
                index += range
            }
            systemOutput(str: "Send Completely\r\n")
        }
    }
}

// 接続デバイスを選択するプロセス
func selectDevice(_ rn: RN4020) {
    let standardInput = FileHandle.standardInput
    systemOutput(str: "Please Select Device Number\r\n")
    // 標準入力を待ち続ける
    while true {
        // 標準入力
        let input = standardInput.availableData
        let dataString = String(NSString(data: input, encoding: String.Encoding.utf8.rawValue) ?? "")
        
        // 入力文字が"~."になると終了する
        if end.count == 2 {
            end[0] = end[1]
            end.removeLast()
        }
        end.append(dataString)
        if end.joined() == "~." {
            close(rn)
        }
        
        // 数字のとき
        if let number = Int(dataString) {
            standardOutput.write(String(number).data(using: .utf8)!)
            selectNumber = selectNumber * 10 + number
        }
        // 選択番号決定のとき
        else if dataString == "\r" {
            // 改行を出力する
            standardOutput.write("\r\n".data(using: .utf8)!)
            // 選択番号が正しいとき
            if rn.connect(selectNumber) {
                // スレッド終了
                return
            }
            // 選択番号が正しくないとき
            else {
                // 選択番号を初期化する
                selectNumber = 0
            }
        }
        // deleteのとき
        else if dataString == "\u{7f}" {
            selectNumber = selectNumber / 10
            // 表示を一字消す
            standardOutput.write("\u{08}".data(using: .utf8)!)
            standardOutput.write(" ".data(using: .utf8)!)
            standardOutput.write("\u{08}".data(using: .utf8)!)
        }
    }
}

// プログラムを終了する関数
func close(_ rn: RN4020) {
    // 改行を出力する
    rn.standardOutput.write("\r\n".data(using: .utf8)!)
    // rawモードを無効にする
    rawOff()
    exit(0)
}

// 出力色を変更する関数
func changeColor() {
    standardOutput.write(highLightColor.data(using: .utf8)!)
}

// 出力色を初期化する関数
func resetColor() {
    standardOutput.write("\u{1b}[0m".data(using: .utf8)!)
}

// 文字を出力する関数
func systemOutput(str: String) {
    changeColor()
    standardOutput.write(str.data(using: .utf8)!)
    resetColor()
}

// rawモードを有効にする関数
func rawOn() {
    let task: Process = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", "stty raw"]
    task.launch()
}

// rawモードを無効にする関数
func rawOff() {
    let task: Process = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", "stty -raw"]
    task.launch()
}

/* main関数 */

let standardOutput = FileHandle.standardOutput

rawOn()

// インスタンス生成
var rn = RN4020()
rn.generation()

let standardInput = FileHandle.standardInput

var enter = false

let runLoop = RunLoop.current
let distantFuture = Date.distantFuture
var running = true

// ループ
while running == true && runLoop.run(mode: RunLoop.Mode.default, before: distantFuture) {
    // centralManagerの状態を変化したらスキャンを開始する
    if rn.isScanning == true {
        rn.startScan()
    }
    
    // 接続デバイスを選択する
    if !enter {
        let dispatchQueue = DispatchQueue.global()
        dispatchQueue.async {
            // 別スレッドでデバイス選択を待つ
            selectDevice(rn)
        }
        // 最初以外のスレッドを作らないためにフラグを下ろす
        enter = true
    }
    
    // ペリフェラルの準備ができたら書き込みを開始する
    if rn.ready {
        // 改行を出力する
        standardOutput.write("\r\n".data(using: .utf8)!)
        // 別スレッドでキーボード入力を待つ
        let dispatchQueue = DispatchQueue.global(qos: .default)
        dispatchQueue.async {
            systemOutput(str: "Allow Writing\r\n\r\n")
            writeProcess(rn)
            // 通信切断コマンドの後で実行される
            systemOutput(str: "\r\nDisconnected\r\n\r\n")
            rn = RN4020()
            rn.generation()
            enter = false
        }
        // 最初以外のスレッドを作らないためにフラグを下ろす
        rn.ready = false
    }
    
}

