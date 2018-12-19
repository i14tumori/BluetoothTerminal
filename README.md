# BluetoothTerminal
Microchip社のRN4020 Bluetooth Low Energy Moduleを通じて動作するターミナルエミュレータ．

# 動作環境

## RN4020 初期設定
1. Macにシリアル通信ソフトCoolTermをインストールする．
1. CoolTermを起動し，以下のように設定する．
  - <pre>[options] → [Serial Port] → [Port] → RN4020を接続しているUSB Serialポートを選択</pre>
  - <pre>[options] → [Serial Port] → [Baudrate] → 115200を選択</pre>
1. CoolTermに'+'とEnterキーを入力する．Echo Onと出力されれば，接続成功．
1. CoolTermに以下のコマンドを打ち込む．
  - <pre>SF,2           // 工場出荷状態までリセット
  SR,32104C00    // RN4020起動時に自動アドバタイズおよびMLDPモードとして動作するように設定</pre>
  R,1            // 再起動</pre>  
  ※ RN4020が正常に動作していれば入力に対して'AOK'と返ってくる．
    使用するデバイスに応じて，SBコマンドによりボーレートを変更する必要がある．
 
