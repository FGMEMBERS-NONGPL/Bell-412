class WidgetEngine {
    float x;
    float y;
    float r;
    
    float speed;
    float maxSpeed;
    float angle_rad;
    
    String label;
    
    WidgetEngine() {
        x = y = r = speed = maxSpeed = 0;
    }
    
    WidgetEngine(String ilabel, float ix, float iy, float iRadius, float iMaxSpeed) {
        label = ilabel;
        x = ix;
        y = iy;
        r = iRadius;
        speed = 0;
        maxSpeed = iMaxSpeed;
    }
    
    void init(String ilabel, float ix, float iy, float iRadius, float iMaxSpeed) {
        label = ilabel;
        x = ix;
        y = iy;
        r = iRadius;
        speed = 0;
        maxSpeed = iMaxSpeed;
    }
    
    void setXY(float ix, float iy) {
        x = ix;
        y = iy;
    }
    
    float getx() { return x; }
    float gety() { return y; }
    
    void display(float angle) {
        this.angle_rad += angle;
        float h;
        colorMode(HSB, 360,100,100);
        h = 240 + this.speed * ( (330-240) / maxSpeed );
        fill(h,80,100);
        noStroke();
        translate(x,y);
        ellipse(0, 0, r*2+4, r*2+4);
        stroke(0,0,100);
        strokeWeight(3);
        line(0,0, r*sin(angle_rad), -r*cos(angle_rad)); // cw
        displaySpeed();
        displayLabel();
        translate(-x,-y);    // restore
    }
    
    void displayAtRpm(float irpm) {
        this.speed = irpm;
        display( this.speed * ( 1/maxSpeed) * (2*PI/10));
    }
    
    void displaySpeed() {
        textFont(font1);
        fill(0);
        strokeWeight(2);
        ellipse(0,0,r/1.4,r/1.4);
        textAlign(CENTER);
        fill(255);
        text((int)this.speed,0,0+5);
    }
    
    void displayLabel() {
        float posx = 0;
        float posy = r+15;
        textFont(font1);
        colorMode(RGB,255);
        strokeWeight(1);
        stroke(128);
        fill(255);
        rectMode(CENTER);
        rect(posx,posy,50,20);
        fill(0);
        textAlign(CENTER,CENTER);
        text(label,posx,posy);
    }
}

class WidgetLabel {
    //PFont font_label;
    float fontSize;
    float charSize;
    float x;
    float y;
    float w;
    float h;
    String label;
    String alignMode;
    //final String DEFAULT_FONT_NAME = "HelveticaRounded-Bold-20.vlw";
    final int DEFAULT_FONT_SIZE = 20;
    final int DEFAULT_CHAR_SIZE = 13;    // single char 'box' size
    final float DEFAULT_COLOR = 200;
    float c;
    
    WidgetLabel(String ilabel, String ialign, float iFontSizeRatio, float ix, float iy) {
        label = ilabel;
        alignMode = ialign;
        x = ix;
        y = iy;        
        c = DEFAULT_COLOR;
        //font_label = loadFont("HelveticaRounded-Bold-20.vlw");
        fontSize = DEFAULT_FONT_SIZE * iFontSizeRatio;
        charSize = DEFAULT_CHAR_SIZE * iFontSizeRatio;
        w = label.length()*charSize;
        h = charSize + (iFontSizeRatio * 10);
    }
    
//    WidgetLabel(float ilabel, float ix, float iy) {
//        WidgetLabel(""+ilabel,"CENTER",1.0,ix,iy);
//    }
    
    void setLabel(String ilabel) {
        label = ilabel;
    }
    
    void setLabel(float ilabel) {
        label = "" + ilabel;
    }
    void setLabel(int ilabel) {
        label = "" + ilabel;
    }
    
    void setXY(float ix, float iy) {
        x = ix;
        y = iy;
    }
    
    void setColor(float ic) {
        c = ic;
    }
    
    float getx() { return x; }
    float gety() { return y; }
    float getw() { return w; }
    float geth() { return h; }
    
    void display() {
        textFont(font_label,fontSize);
        colorMode(RGB,255);
        strokeWeight(1);
        stroke(128);
        fill(0);
        if ( alignMode == "CENTER") {
            rectMode(CENTER);
            rect(x,y,w,h);
            textAlign(CENTER,CENTER);
            fill(c);
            text(label,x,y);
        }
        if ( alignMode == "LEFT") {
            rectMode(CORNER);
            rect(x,y,w,h);
            textAlign(LEFT,TOP);
            fill(c);
            text(label,x+2,y+2);
        }
    }
    
    void display(String newLabel) {
        setLabel(newLabel);
        display();
    }
}
        
