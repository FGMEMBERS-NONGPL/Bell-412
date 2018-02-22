// ===============================================================
// PT6T-3D Twin Pac Engine Simulator
// 
// Desc
//     proof of concept of the PT6T Engine System for the 
//     Bell412 Flightgear rotorcraft.
// 
// Refs:
//     Engine_PT6T-EASA_TCDS_IM.E.059_20153010_1.0 [1]
//     FM BHT-412-FM-2 [2]
//     BELL 412EP PRODUCT SPECIFICATIONS [3]
//
// Author
// Valéry Seys
//
// Changelog
// 2016/11    - init
// ===============================================================
// 
// 
//import penner.easing.*;
import controlP5.*;

float time0, etime, atime;     // time_now, elapsedTime, accumulatorTime
PFont font, font1, font_label;

// Turbine(x,y,power,speed,accelFactor,minIdle,maxIdle)
//Turbine engine = new Turbine(0,0,597,38800,0.05,40,103.2);

Engine engine = new Engine();

// gui control
boolean starter0 = false;
boolean starter1 = false;
float throttle0 = 0;
float throttle1 = 0;
float alt=0;
int rtorquepct = 0;
boolean oeiMode = true;

void setup() {
    size(800, 700);
    frameRate(30);
    time0 = etime = millis();
    atime = 0;
    smooth();
    background(0);
    font = loadFont("LucidaSans-Typewriter-10.vlw");
    font1 = loadFont("HelveticaRounded-Bold-20.vlw");
    font_label = loadFont("HelveticaRounded-Bold-20.vlw");
    textFont(font);
    
    initEasings();    // init hashmap of ease methods
    engine.setDisplayAt(10,10);
    //cbox.setDisplayAt(520,height/2-cbox.getInstrumentSize()/2);
    //noLoop();
    setupGui();
}

void draw() {
    etime = elapsedTimeFrom(time0);
    
    if ( starter0 )
        engine.start(0);
    if ( !starter0 )
        engine.stop(0);
        
    if ( starter1 )
        engine.start(1);
    if ( !starter1 )
        engine.stop(1);
    
	engine.setOeiState(0,oeiMode);
    engine.update();
    printFrame();

    time0 = millis(); // dt1 - dt0 = fps
}

float elapsedTimeFrom(float dt0) {
    return millis() - dt0;
}

void mousePressed() {
}

void keyPressed() {
    if ( key == ' ' ) {
    }
}

void printFrame() {
    String s = "";
    String d = "";
    int x = width - 150;
    int y = height;
    noStroke();
    fill(0);
    rectMode(CORNER);
    rect(x, height-100, 200, 100);
    fill(255);
    
//    if ( atime < .25 ) {
//        atime += (etime/1000);
//        //rpm0 = rpm;
//    }
//    else {
//        atime = 0;
//        //rpm_mean = round((rpm0 + rpm) / 2);
//    }
    
    fill(255);
    rect(x, y-80, 150, 54);
    textFont(font1);
    textAlign(LEFT);
    fill(0);
    text("PT6T-3B",x+2,y-60);
    textFont(font1,15);
    text("Engine Simulator",x+2,y-46);
    text("vslash.com/2016",x+2,y-30);
    
    fill(255);
    textFont(font);
    textAlign(LEFT);
    
//    d = String.format("%.4g%n",etime/1000);
//    s = "eTime(sec)    : " + d;
//    text(s, x, y - 12);
    
    d = String.format("%.4g%n",frameRate);
    s = "fps           : " + d;
    text(s, x, y - 2);  
}
