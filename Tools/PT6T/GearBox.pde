
class GearBox {
    final float MAX_CBOX_RPM_CONT = 6600;
    final float MAX_CBOX_POWER_CONT = 1193;
    final float MAX_CBOX_POWER_OEI = 1104;      // at CBOX, max continuous OEI
    final float MAX_CBOX_RPM_TAKEOFF = 6798;  // gearbox
    final float MAX_CBOX_TORQUE_TAKEOFF = 1000; // at CBOX, from [1] that gives 712kW at 6600rpm ; we really got 942N.m from standard physic metrics
    // from values above, we could deduce that the CBOX gives more power than N2. Don't know where it comes from. -- V.S./2016
    
    float power, powert0, powerTarget, powerTransit;
    float speed, speedt0, speedTarget;
    float torque;
    float cboxpct;
    
    float maxPower;
    float maxSpeed;
    float maxTorque;
    
    final float instrumentSize = 150;
    WidgetEngine instrument;    // our display
    WidgetLabel labelpct;          // CBOX
    WidgetLabel labelPower;
    
	Ease easeSpeed, easePower;
	boolean onAccelSpeed;
	boolean onAccelPower;

	float etime0, etime1;
	final float UPDATE_LATENCY = 1200;	// millis
    
    GearBox(float ix, float iy) {
        maxPower = MAX_CBOX_POWER_CONT;
        maxSpeed = MAX_CBOX_RPM_CONT;
        //maxTorque = MAX_CBOX_TORQUE_OEI; // 1727 at standard metrics
        
        power = powert0 = powerTarget = powerTransit = speed = speedt0 = torque = cboxpct = 0;
        
        instrument = new WidgetEngine("GBX",ix,iy,instrumentSize/2,maxSpeed);
        labelpct = new WidgetLabel("000 %","CENTER",1,ix,iy);
        labelPower = new WidgetLabel("000 kW","CENTER",1,ix,iy);
        
		easeSpeed = new Ease("linearEaseIn");
		easePower = new Ease("linearEaseIn");
		etime0 = etime1 = millis();
        onAccelSpeed = onAccelPower = false;
        
        setDisplayAt(ix,iy);
    }
   
	void updatePower(float target) {
        if ( target > power ) {
            if ( !onAccelPower ) {
                onAccelPower = true;
                easePower.reset();
                powert0 = power;
            }
            float dt = UPDATE_LATENCY / 1000;
            onAccelPower = true;
            power = easePower.interpolate("linearEaseNone",dt, power, powert0, target);
            if ( power >= target ) {
                powert0 = power = target;
                easePower.reset();
                onAccelPower = false;
            }
        }
        if ( target < power ) {                // decelerate
            if ( onAccelPower ) {
                onAccelPower = false;
                easePower.reset();
                powert0 = power;
            }
            //float dt = (powert0 - target) / 10;
            float dt = UPDATE_LATENCY / 1000;
            power = powert0 - easePower.interpolate("cubicEaseOut",dt, powert0 - power, 0, powert0 - target);
            if ( power <= target ) {
                powert0 = power = target;
                easePower.reset();
            }
            //println("- thrust:" + throttle + ", n1: " + n1 + ", n1_0:" + n1_0 + ", target:" + n1Target + ", dt: " + dt);
        }
		cboxpct = 100 - (( maxPower - power ) / maxPower * 100);
	}

	void updateSpeed() {
		speed = maxSpeed * ( power/maxPower);
	}

    void update() {
        etime1 = eTimeFrom(etime0);
		if ( etime1 > UPDATE_LATENCY ) {
			powerTransit = powerTarget;
			etime0 = millis();
		}
		updatePower(powerTransit);
		updateSpeed();
		display();
    }

	void setSpeed(float ispeed) { speedTarget = ispeed; }
	void setPower(float ipower) { powerTarget = ipower; }
    
    float eTimeFrom(float dt0) {
        return millis() - dt0;
    }

    void display() { 
        instrument.displayAtRpm(speed);
        labelpct.display(""+(int)cboxpct+" %");
        labelPower.display(""+(int)power+" kW");
    }
    
    void setDisplayAt(float ix, float iy) {
        float margin = 20;
        float rad = instrumentSize / 2;
        instrument.setXY(ix+margin+rad,iy+rad);
        labelpct.setXY(instrument.getx(),instrument.gety()+rad/2+10);
        labelPower.setXY(ix+margin+rad*2,iy+rad);       
    }
    
    float getInstrumentSize() { return instrumentSize; }
    
}
