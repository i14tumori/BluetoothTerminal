# BluetoothTerminal
Microchip社のRN4020 Bluetooth Low Energy Moduleを通じてMacターミナル上で動作するターミナルエミュレータ．  
通信にはMLDP(Microchip Low Energy Data Profile)を使用する．

## RN4020 初期化
TeC7bに搭載されたRN4020は，ボード上のジャンパを二本横差しすることで工場出荷時までリセットすることができる．

## RN4020 初期設定
1. Macにシリアル通信ソフトCoolTermをインストールする．  
2. TeC7bのジャンパをDEMO1に設定し，MacとUSBケーブルで接続する．　　
3. CoolTermを起動し，以下のように設定する．
  <pre>  [options] → [Serial Port] → [Port] → TeC7bを接続しているUSB Serialポートを選択
  [options] → [Terminal] → [Enter Key Emulation] → CRを選択  
  
  ※ TeC7bのファームウェアが最新版(2018/12/1現在)でない場合はさらに
      [options] → [Serial Port] → [Baudrate] → 11520を選択
    の設定が必要になる．</pre>
4. CoolTermに'+'とEnterキーを入力する．Echo Onと出力されれば，接続成功．
5. CoolTermに以下のコマンドを打ち込む．
  <pre>  SF,2           // 工場出荷状態までリセット
  SR,32104C00    // RN4020起動時に自動アドバタイズおよびMLDPモードとして動作するように設定
  R,1            // 再起動</pre>  
  ※ RN4020が正常に動作していればSF，SRに対して'AOK'と返ってくる．`R,1`の実行後，CMDが表示されると設定が終了する．
 
## 使い方
### 実行方法
BlueTerm.shとmain.swiftをダウンロードして同一ディレクトリに配置し，`./BlueTerm.sh`を実行する．
### 使用可能コマンド
  <pre>  ~.       : プログラム終了
  ~;       : コマンドモード
  quit     : コマンドモード終了
  sendFile : 実行形式ファイル(.out, .exe, .bin)の送信   ※コマンドモード時のみ</pre>

## 開発環境
macOS Mojave(10.14.1)  
Xcode 10.1  
CoolTerm 1.5.0  
Swift 4.2.1
