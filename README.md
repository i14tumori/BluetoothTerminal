# BluetoothTerminal
Microchip社のRN4020 Bluetooth Low Energy Moduleを通じてMacターミナル上で動作するターミナルエミュレータ．

## RN4020 初期設定
1. Macにシリアル通信ソフトCoolTermをインストールする．
2. CoolTermを起動し，以下のように設定する．
  <pre>  [options] → [Serial Port] → [Port] → RN4020を接続しているUSB Serialポートを選択
  [options] → [Serial Port] → [Baudrate] → 115200を選択</pre>
3. CoolTermに'+'とEnterキーを入力する．Echo Onと出力されれば，接続成功．
4. CoolTermに以下のコマンドを打ち込む．
  <pre>  SF,2           // 工場出荷状態までリセット
  SR,32104C00    // RN4020起動時に自動アドバタイズおよびMLDPモードとして動作するように設定
  R,1            // 再起動</pre>  
  ※ RN4020が正常に動作していれば入力に対して'AOK'と返ってくる．
    使用するデバイスに応じて，SBコマンドによりボーレートを変更する必要がある．
 
## 使い方
### 実行方法
BlueTerm.shとmain.swiftをダウンロードして同一ディレクトリに配置し，`./BlueTerm.sh`を実行する．
### 使用可能コマンド
  <pre>  ~.       : プログラム終了
  ~;       : コマンドモード
  quit     : コマンドモード終了
  sendFile : 実行形式ファイルの送信(コマンドモードのみ)</pre>

## 開発環境
macOS Mojave(10.14.1)  
Xcode 10.1  
Swift 4.2.1
