# fpgaCameraToVGA
FPGAでカメラを繋いでみました。2018年頃、電子工作で作りました。

電子工作用のカメラをFPGAに繋ぐやり方です。迷っている方も多いと思います。
その手助けになればと、参考用に、古いコードも公開することにしました。

Verilogで書かれたコード.vファイルのインデント（字下げ）が見づらいのでブラウザのURL欄の文末に「?ts=3」をつけると
空白が揃うようになります。
例）https://github.com/ritsuro/fpgaCameraToVGA/blob/main/testCamera01AndSetup/testCamera01.v?ts=3

FPGAボードは  terasic DE0-Nano (ALTERA Cyclone IV EP4CE22F17C6N FPGA)　です。  
開発ツールはQuartus Prime Version 17 Lite Edition（無償版）です。  
CMOSカラーカメラモジュールは『OV7670』（秋月電子にて980円で購入）、表示は標準の液晶モニター、VGA（640x480）です。
メモリを介さずに直接回路で繋いでいるため、走査線は240本に減らしています。30fpsです。  

（１）カメラの出力信号を直接VGA信号に送る

    CCDカメラの出力信号から、赤、青、緑をそれぞれ3ビットの信号に置き換えて3本ずつ
    V-SyncとH-Syncの2本と合わせて11本の出力線となります。赤青緑の３ビット信号はラダー抵抗を組んで
    アナログ信号にしてVGAケーブルに繋げる必要があります。電子工作ではブレッドボードに繋ぎラダー抵抗を
    組みます。その出力をVGAケーブルのコネクタ口に直接ジャンパー線で繋ぎました。
    V-SyncとH-Syncの出力線もジャンパー線で直結させます。
    液晶モニターは壊れても良いものを使いました。

（２）フォルダ、testCamera01AndSetup　の内容

    ファイルとその内容の説明です。

    connectCamera01.v　カメラと接続する回路です。直接VGA信号に変換しています。
    connectI2C.v　I2C通信です。自作しました。
    connectVGA.v　VGA出力です。
    drawBox01.v　箱型の描線を発生させます。
    drawLine01.v　直線の描線を発生させます。サンプルでは未使用です。
    testCamera01.v　メイン処理です。
    textDraw02.v　画面の描画をします。
    ov7670.txt　カメラの設定ファイルです。初期設定値が書いてあります。
    testCamera01.qpf　プロジェクトファイル
    testCamera01.qsf　プロジェクトの設定ファイル
    testCamera01.sdc　プロジェクトのタイミング制約用ファイル
    testCamera01.stp　プロジェクトのSignal Tap ファイル
    txt　テキスト表示のフォントデータです。自作しました。
    
（３）VGAにつなぐラダー抵抗について  

    私は、カーボン抵抗１kΩ 12本と、510Ω 6本で、GNDにぶら下げる方式でつくりました。
    どのやり方が一番よいのか、わかりません。うちのジャンク品の液晶モニターでは保護回路に
    守られて試行錯誤できました。壊れてもよい電子工作用のモニターを用意しましょう。  
    ラダー抵抗が面倒くさいときは、信号線を一本だけ、直結でも絵は出せます。
     
（４）フォントについて

   ツールで自作したものなので自由に使ってください。

--------------------------  
Camera to VGA  
!["picture"](pic01.jpg)
  
VGA signal line  
!["picture"](pic02.jpg)
  
Breadboard  
!["picture"](pic03.jpg)
  
Connecter to VGA  
!["picture"](pic04.jpg)
   
r.h 2025/5/18
   
