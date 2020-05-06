import ddf.minim.*;

Minim minim;
AudioInput in;
PImage offscr;
PFont txtfont = null;

//-------------------------------------------
int timelength = 15; //一つのパターンが流れる秒数
float globalAdjust = 2.0;//波形に対する感度
String message = "LOVE BEER?"; //画面に出す文字列

//テキスト描画フォント指定※要事前変換
//指定しなければデフォルトフォントで描画します
//txtfont = loadFont("Brandish-64.vlw");
//-------------------------------------------

//プログラム開始時間
int starttime = millis();

int frontTypes = 6; //前景パターン数
int backTypes = 6; //背景パターン数
int colorTypes = 5; //色パターン数

//実行中のパターン番号
int backdraw = 0;
int frontdraw = 0;
int frontdraw2 = 0;
int colorType = 0;
int colorType2 = 0;

//-----------------------------------------------------------------
void setup() {
  //audio
  minim = new Minim(this);
  //16bitでも24bitでも44.1kHzでも48kHzでも開ける（でも指定できるのは16bitまで）
  //もしここでエラーが出た場合、デバイスが無効になっているか
  //プライバシー設定でマイクを無効にしてないかチェックすること
  in = minim.getLineIn(Minim.STEREO, 1440);
  if(in == null) {
    println("オーディオデバイスが開けません！");
    exit();
  }

  //screen
  frameRate(30);
  size(1280, 720, P3D);
  background(0);
  offscr = createImage(width, height, RGB);
  offscr.pixels = pixels;
  loadPixels();

  //init
  frontdraw = (int)random(frontTypes);
  frontdraw2 = (int)random(frontTypes);
  backdraw = (int)random(backTypes);
  colorType = (int)random(colorTypes);
  colorType2 = (int)random(colorTypes);
}

//-----------------------------------------------------------------
//通常描画関数
void draw() {

  //経過時間
  int pasttime = (millis() - starttime)/1000;

  // test
  //int pasttime = 0;
  //frontdraw = 3;
  //backdraw = 5;
  
  //一定時間経過したら次のプログラムに行く。ループする。
  if(pasttime >= timelength) {
    backdraw   = changePattern(backdraw, backTypes);
    frontdraw  = changePattern(frontdraw, frontTypes);
    frontdraw2 = changePattern(frontdraw2,frontTypes);
    colorType  = changePattern(colorType, colorTypes);
    colorType2 = changePattern(colorType2, colorTypes);

    //同じパターンは避ける
    if(frontdraw2 == frontdraw) {
      frontdraw2 = (frontdraw2+1)%frontTypes;
    }
    if(colorType2 == colorType) {
      colorType2 = (colorType2+1)%colorTypes;
    }

    //経過時間のリセット
    starttime = millis();
    
    println(String.format("Front1:%d/Front2:%d/Back:%d/Color:%d", frontdraw, frontdraw2, backdraw, colorType));
  }
  
  colorMode(RGB, 255);
  translate(0, 0, 0); 
  if(txtfont != null) textFont(txtfont, 32);

  drawBack(backdraw);
  drawFront(frontdraw, colorType);
  drawFront(frontdraw2, colorType2);
 
  //ちょっとだけ輝度を落としておくことでブラー効果を狙います
  fill(color(0,0,0,255/10));
  noStroke();
  rect(0,0, width, height);
}


//-----------------------------------------------------------------
//背景描画
void drawBack(int backdraw) {
  float leftLevel = in.left.level();

  switch( backdraw ) {
    case 1:
      //ボリュームに合わせて青→赤
      background(blue2red(leftLevel, globalAdjust));
      break;

    case 2:
      //拡大
      offscr.pixels = pixels;
      loadPixels();
      offscr.updatePixels();
      image(offscr, -20, -20, width + 40, height + 40);
      break;

    case 3:
      //横に拡大
      offscr.pixels = pixels;
      loadPixels();
      offscr.updatePixels();
      float shake = map(leftLevel, 0.0, 1.0, 20, 40);
      image(offscr, -shake, shake, width + shake*2, height - shake*2);
      break;

    case 4:
      //４つに分裂
      offscr.pixels = pixels;
      loadPixels();
      offscr.updatePixels();
      image(offscr,       0,        0, width/2, height/2);
      image(offscr, width/2,        0, width/2, height/2);
      image(offscr,       0, height/2, width/2, height/2);
      image(offscr, width/2, height/2, width/2, height/2);
      break;

    case 5:
      //回転
      offscr.pixels = pixels;
      loadPixels();
      offscr.updatePixels();

      //原点移動→回転→描画→回転戻す→原点戻す
      translate(width/2, height/2, 0); 
      rotate(radians(1));
      image(offscr, -width/2, -height/2, width, height);
      rotate(radians(-1));
      translate(-width/2, -height/2, 0); 
      break;

    default:
      //何もしない（黒で塗りつぶす）
      background(0);
  }
 
}

//-----------------------------------------------------------------
//前景オブジェクト描画
void drawFront(int frontdraw, int colortype) {
  //汎用数値計算--------------
  int centerX = width / 2;
  int centerY = height / 2;
  float leftLevel = in.left.level();
  float rightLevel = in.right.level();
  color drawcolor;
  
  switch (colortype) {
    case 0:
      //循環色 
      drawcolor = rotateColor();
      break;
    case 1:
      //ランダムカラー
      drawcolor = rndColor();
      break;
    case 2:
      //ボリュームに合わせて赤→青になる
      drawcolor = red2blue(leftLevel, globalAdjust);
      break;
    case 3:
      //ボリュームに合わせて緑→黄色になる
      drawcolor = green2yellow(leftLevel, globalAdjust);
      break;
    default :
      //白
      drawcolor = color(255);
  }


  switch( frontdraw ) {
  case 0:
    //同心円-------------------------
    noFill();
    strokeWeight(10);
    stroke(drawcolor);
    
    float maxSize = 720;
    float minSize = 720/2;

    float innerSize = range(leftLevel, minSize, maxSize, globalAdjust);
    circle(centerX, centerY, innerSize);
    circle(centerX, centerY, innerSize*1.5);
    circle(centerX, centerY, innerSize*2);

    float outerSize = range(rightLevel, minSize-100, maxSize+100, globalAdjust);
    circle(centerX, centerY, outerSize);
    circle(centerX, centerY, outerSize*1.5);
    circle(centerX, centerY, outerSize*2);
  
  break;
  
  
  case 1:
    //円を並べる-------------------------
    fill(drawcolor);
    noStroke();

    for (int x = 0; x < (1280/40); x++) {
      for (int y = 0; y < (720/40); y++) {
        float radius = map(leftLevel*globalAdjust, 0, 1.0, 0, 40);
        ellipse(20+x*40, 20+y*40, radius*2, radius*2);
      }
    }
  break;
  
  case 2:
    //波形ーーーーーーーーーーーーーーーーーーー
    strokeWeight(2);
    stroke(drawcolor);

    int count = in.bufferSize()-1;
    if(count > 200) count = 200;
    int waveH = 720/4;

    for (int i = 1; i < count; i++) {
      int x_1 = (int)map(i-1, 0,200, 0,width); 
      int x_0 = (int)map(i  , 0,200, 0,width); 
      float lb_1 = in.left.get(i-1)*waveH;
      float lb_0 = in.left.get(i  )*waveH;
      float rb_1 = in.right.get(i-1)*waveH;
      float rb_0 = in.right.get(i  )*waveH;
      line(x_1,  50+lb_1, x_0,  50+lb_0);
      line(x_1, 250+rb_1, x_0, 250+rb_0);
      line(x_1, 450+lb_1, x_0, 450+lb_0);
      line(x_1, 650+rb_1, x_0, 650+rb_0);
    }
  break ; 
  
  
  case 3:
    //ボックスを２つーーーーーーーーーーーーーーーーーー

    noFill();
    strokeWeight(10);
    stroke(drawcolor);

    int speed = 2000;
    int ms = millis()%speed;

    //原点移動
    translate(centerX, centerY, 300); 
    //-------
    float ry = map(ms, 0, speed, -1.0, 1.0)*PI; 
    rotateY(ry);
    //translate(0, 0, -100); 
    box(range(rightLevel, 100, 200, globalAdjust));
    //translate(0, 0, +100);//もとに戻す
    rotateY(-ry);//もとに戻す

    //-------
    ry = map(1000-ms, 0, speed, -1.0, 1.0)*PI; 
    rotateY(ry);
    //translate(0, 0, -100); 
    box(range(leftLevel, 250, 350, globalAdjust));
    //translate(0, 0, +100);//もとに戻す
    rotateY(-ry);//もとに戻す
    
    translate(-centerX, -centerY, -300); 
    break;
  
  case 4:
    //ランダムテキストーーーーーーーーーーーーーーーーーー
    fill(drawcolor);
    textSize(range(rightLevel, 8, 64, globalAdjust));

    for (int i = 0; i < 25; i++) {
      float x = random(width);
      float y = random(height);
      text(message, x, y);
    }
  break;
  
  case 5:
    //トライアングルーーーーーーーーーーーーーーーーーー
    noStroke();
    fill(drawcolor);
    
    float angle = map(millis()%2000, 0,2000, 0,360);
    float size = map(rightLevel*globalAdjust, 0.0, 1.0, 200, 800);
    
    int p1x = centerX - (int)(cos(radians(angle))*size);
    int p1y = centerY - (int)(sin(radians(angle))*size);
    int p2x = centerX - (int)(cos(radians(angle+120))*size);
    int p2y = centerY - (int)(sin(radians(angle+120))*size);
    int p3x = centerX - (int)(cos(radians(angle+240))*size);
    int p3y = centerY - (int)(sin(radians(angle+240))*size);
    
    triangle(p1x,p1y, p2x,p2y, p3x,p3y);

  break;

  }

}

//-----------------------------------------------------------------
//終了処理
void stop() {
  in.close();
  minim.stop();
  super.stop();
}

//-----------------------------------------------------------------
//汎用関数

//min～max間、リミッターあり
float range(float value, float min, float max, float adjust) {
  value = value * adjust;
  if(value > 1.00) value = 1.00;
  return (max - min)* value + min;
}

//同じパターンが連続しないようにパターンをランダムに変更
int changePattern(int pattern, int types) {
  int newPattern = (pattern + (int)random(types)+1) % types;
  //連続してしまったら、とりあえず次のパターンにしておく
  if(newPattern == pattern) {
    newPattern = (newPattern + 1) % types;
  }
  return newPattern;
}

//青から赤へ色が変わる（back用）
color blue2red(float value, float adjust) {
  float c = range(value, 0, 255, adjust);
  return color(c, 0, 255-c);
}
//赤から青へ色が変わる（front用）
color red2blue(float value, float adjust) {
  float c = range(value, 0, 255, adjust);
  return color(255-c, 0, c);
}
//緑から黃へ色が変わる（back用）
color green2yellow(float value, float adjust) {
  float c = range(value, 0, 255, adjust);
  return color(c, 255-c, c);
}
//黃から緑へ色が変わる（front用）
color yellow2green(float value, float adjust) {
  float c = range(value, 0, 255, adjust);
  return color(255-c, c, 255-c);
}
//ランダムカラー
color rndColor() {
  return color(random(255), random(255), random(255));
}

//時間経過で赤、緑、青に色が変わる
float colorwave(int shift) {
  int ms = (millis()+shift) % 10000;
  float x = map(ms, 0, 10000, 0.0, 2.0);
  //振幅-1.5～1.0のsin波
  float siny = (sin(TWO_PI*x) * 1.50) - 0.5;
  if(siny <= 0) siny = 0.0;
  return map(siny, 0.0, 1.0, 0,255);
}
color rotateColor() {
  float r = colorwave(0);
  float g = colorwave(3333);
  float b = colorwave(6666);
  return color(r, g, b);

}
