
ControlP5 cp5;

void setupGui() {
  cp5 = new ControlP5(this);
  //cp5.setAutoDraw(false);
  //cp5.setWindow(this);
  
  //ControlWindow guiWin = cp5.addControlWindow("P5Win",10,10,300,200);
  //guiWin.setBackground(color(0));
  //guiWin.setColorForeground(color(0));
  
  int marginx = 10;
  int marginy = 80;
  int posx = 0 + marginx;
  int posy = height - marginy;
  
  controlP5.Toggle ctlStarter = cp5.addToggle("starter0")
    .setPosition(posx,posy)
    .setSize(20,20)
    .setValue(false);
  
  posx += 40 + marginx;
  
  controlP5.Slider ctlThrottle = cp5.addSlider("throttle0")
    .setPosition(posx,posy)
    .setSize(70,20)
    .setRange(0,100)
    .setValue(0);
  //ctlspeedMove.setWindow(this);
  
  posx += 120 + marginx;
  
  controlP5.Slider ctlalt = cp5.addSlider("alt")
      .setPosition(posx,posy)
      .setSize(80,20)
      .setRange(0,10000)
      .setValue(0);
      
  posx += 120 + marginx;
  
  controlP5.Slider ctlRotorTorque = cp5.addSlider("rtorquepct")
      .setPosition(posx,posy)
      .setSize(80,20)
      .setRange(0,100)
      .setValue(0);
    
  posx += 130 + marginx;
  
  controlP5.Toggle ctlTotEngine = cp5.addToggle("oeiMode")
      .setPosition(posx,posy)
      .setSize(20,20)
      .setValue(true);
 
  marginy = 40;     
  posx = 0 + marginx;
  posy = height - marginy;
  
  controlP5.Toggle ctlStarter1 = cp5.addToggle("starter1")
    .setPosition(posx,posy)
    .setSize(20,20)
    .setValue(false);
  
  posx += 40 + marginx;
  
  controlP5.Slider ctlThrottle1 = cp5.addSlider("throttle1")
    .setPosition(posx,posy)
    .setSize(70,20)
    .setRange(0,100)
    .setValue(0);
}
