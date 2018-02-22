// PT6T - ref.: 
//    EASA TCDS_IM.E.059_20153010 [1]
//    FM BHT-412-FM-2 [2]
//    BELL 412EP PRODUCT SPECIFICATIONS [3]
//
// PT6T-3B Twin: 
//    max takeoff(kW)    : 1342 (single 671)
//    max cont. power(kW): 1193 (single 597)
//    cbox speed(rpm)    : 6600 (6798 takeoff = 103%)
//    turbine speed(rpm) : 38800 (takeoff = 100.8%)
//    max torque takeoff : 1000 N.m (at cbox)
//    max torque OEI     : 1104 N.m (at cbox)


// rel. charts from Gas to N1 to N2 max %power at sea level with 1013hPa. and rel. Air Density
// data calculated by empirism from observation and from the PT6T limitations
   
// How we design:
// The purpose of N1 is to maintain N2 at 100%
// The purpose of N2 is to maintain CBOX/XMSN at 100% (ie rotor at 324rpm)
// The power of N1 depends on the needs of N2
// The power of N2 depends on the torque of the Rotor ie the RotorTorque decrease the power of N2 until N1 increase it
// the torque of N2 depends on the torque of the CBOX/XMSN/Rotorgear
// as the rotor increase the torque of N2, N1 decrease it as well until it reach its limit or 100% N2
// Of course, N1 depends on the gas throttle, air density and fuel flow.
// Altitude/AirDensity: 
//     - we increase N1_MIN_IDLE so the minimum power of N1 increase with altitude, so the whole power of N1
//     - we don't use AOT yet

class Turbine {
    // throttle_%, maxN1_%, maxN2_%, dtn1_sec, dtn2_sec, maxN1oei_%, maxN2oei_%
    final float gnn[][] = {
    { 00,  12,    00,    2,  2,  12,    00    }, 
    { 02,  15,    00,    2,  3,  20,    00    },
    { 03,  64.3,  50.5, 12, 14,  68.6,  56.4  },
    { 10,  67,    54,    3,  4,  70.9,  59.5  },
    { 20,  70,    59,    3,  4,  73.6,  63.9  }, 
    { 30,  74,    62,    2,  3,  77,    66.5  },
    { 40,  79,    67,    2,  3,  80,    70.9  },
    { 50,  82,    70,    2,  3,  83,    73.6  },
    { 60,  85,    75,    2,  3,  87,    78    },
    { 70,  87,    78,    2,  3,  90,    80.6  },
    { 80,  90,    82,    2,  3,  92,    84.1  },
    { 90,  95,    90,    2,  3,  95.6,  91.2  },
    {100, 100,   100,    2,  3, 100,   100    },
    {100, 100.8, 100,    3,  2, 100.8, 100    }
    };

	final int IDX_GNN_IDLE = 2;
	final int IDX_GNN_MAX = 13;
    final int IDX_THROTTLE = 0;
    final int IDX_N1_MAX = 1;
    final int IDX_N2_MAX = 2;
    final int IDX_N1_DT = 3;
    final int IDX_N2_DT = 4;
	final int IDX_N1_MAX_OEI = 5;
	final int IDX_N2_MAX_OEI = 6;
    
    // PT6T-3B -- from [1] and [2]
    final float MIN_THROTTLE_IDLE = 3;
          float MIN_N1_IDLE = gnn[IDX_GNN_IDLE][IDX_N1_MAX_OEI];	//
          float MAX_N1 		= gnn[IDX_GNN_MAX][IDX_N1_MAX_OEI];		//
          float MIN_N2_IDLE = gnn[IDX_GNN_IDLE][IDX_N2_MAX_OEI];	//
          float MAX_N2 		= gnn[IDX_GNN_MAX][IDX_N2_MAX_OEI];
    
    final float MAX_POWER_CONT = 597;      	// single shaft
    final float MAX_RPM_CONT = 38800;      	// 100.8%
    final float MAX_TORQUE_CONT = 145;     	// deduced
    
    final float MAX_POWER_OEI = 764;     	// from [3]
    final float MAX_RPM_OEI = 38800;     	//
    final float MAX_TORQUE_OEI = 188;    	// deduced
    
    final float MAX_POWER_TAKEOFF = 671;   // single shaft
    final float MAX_RPM_TAKEOFF = 38800;   // 103.2% turbine, we use it as OEI too, though it's actually 103.7
    final float MAX_TORQUE_TAKEOFF = 165;  // deduced
    
    final float MAX_ITT_CONT = 765;        // degC
    final float MAX_ITT_TAKEOFF = 810;     // degC
    
    // Initialization Data
    float maxPower;                 // kW at Turbine single shaft
    float maxTorque;                // N.m at Turbine
    float maxSpeed;                 // rpm at Turbine
    float accelFactor;              // 0..1 acceleration factor
    float power, torque, speed;     // current power,torque and speed at N2
    float torque_pct;               // engine torque pct for instrument
    float n1;                       // % N1 current
    float n1Target;                 // % N1 target
    float n1t0;                     // % N1 at t0 data storage
    float n1Max;                    // % N1 maximum power available
    float n1Speed;                  // RPM
    float n1Torque;                 // torque factor [0..1]
    float n1PowerNeeds;             // power need to maintain N2 at 100%
    float n2;                       // % N2 current
    float n2Target;                 // target storage
    float n2t0;                     // n2 data storage
    float n2Max;
    float rho, rho0;
    
    float fracn1;    // XXX temp
    float minN1Rho; // XXX temp
    float n1accelSpeed; // rpm
    float n2accelSpeed; // rpm
    final float MAX_ACCEL_SPEED = 1350; // rpm acceleration/sec.
    
    float itt_deg;                  // degC ITT
	float ittTarget, ittTransit;
	final float ITT_LATENCY = 4000;	// ITT update time (millis)
    float availableN1;              // % max available power from N1
    
    final int STATE_DOWN = -1;      // engine stopped
    final int STATE_STOP = 0;       // going to stop
    final int STATE_START = 1;      // let's go
    final int STATE_IDLE = 2;       // idle
    final int STATE_STARTING = 3;   // going to start
    final int STATE_RUNNING = 4;    // running
    int state;                      // -1:down, 0:stop, 1:start, 2:idle, 3:starting, 4:running
    boolean autoStart;
    boolean oeiState;
    
    boolean onAccelN1;
    boolean onAccelN2;
    
    // input
    float throttle;
    float throttle0;
    
    // Interpolation metrics
    Ease easeN1, easeN2, easeThrottle, easeItt;
    
    // elapsed time storage
    float etime0, etime1, etimeItt0, etimeItt1;
    
    // Instruments display
    float x, y;
    int margin;
    final int instrumentSize = 200;    // our instrument
    WidgetEngine instrumentN1;    // our N1 display
    WidgetEngine instrumentN2;    // our N2 display
    WidgetLabel labelPower;       // power box display
    //WidgetLabel labelThrust;      // thrust box display
    //WidgetLabel labelAD;          // Air Density box display
    WidgetLabel labelN1;          // N1 pct box 
    WidgetLabel labelN2;          // N1 pct box
    WidgetLabel labelITT;         // ITT 
    WidgetLabel labelTorque;      // Engine Torque
    
    // Turbine(x,y,minIdle,maxIdle)
    Turbine(float ix, float iy) 
    {
        x = ix; y = iy;
        margin = 150;
        maxPower = MAX_POWER_OEI;
        maxSpeed = MAX_RPM_OEI;
        maxTorque = calcTorque(maxPower,maxSpeed);    // max torque at N2
        accelFactor = 0;
        n1 = n1t0 = n1Target = n1Torque = n1PowerNeeds = 0;
        n2 = n2t0 = n2Target = 0;
        power = torque = speed = throttle = throttle0 = 0;
        itt_deg = 0;
		ittTarget = ittTransit = 0;
        rho = rho0 = ARDC.getAirDensity(alt);                    // TODO nasal getAltitude();
        n2accelSpeed = 0; // rpm
        
        state = STATE_DOWN;
        autoStart = false;
        oeiState = true;    // default to OEI
        
        // Displaying
        float rad = instrumentSize / 2;
        instrumentN1 = new WidgetEngine("N1",ix,iy,rad,maxSpeed);
        instrumentN2 = new WidgetEngine("N2",ix,iy,rad,maxSpeed);
        labelPower = new WidgetLabel("000.0 kW","CENTER",1,ix,iy);
        //labelThrust = new WidgetLabel("T: 000.00 %","LEFT",0.75,ix,iy);
        //labelAD = new WidgetLabel("A: 0.000 kg/m3","LEFT",0.75,ix,iy);
        labelN1 = new WidgetLabel("000 %","CENTER",1,ix,iy);
        labelN2 = new WidgetLabel("000 %","CENTER",1,ix,iy);
        labelITT = new WidgetLabel("0000 °C","CENTER",1,ix,iy);
        labelTorque = new WidgetLabel("0000 %N.m","CENTER",1,ix,iy);
        setDisplayAt(ix,iy);
        
        // Ease metrics
        easeN1 = new Ease("linearEaseIn");
        easeN2 = new Ease("linearEaseIn");
        easeThrottle = new Ease("linearEaseIn");
        easeItt = new Ease("linearEaseIn");
        
        // init time counters
        etime0 = etime1 = etimeItt0 = etimeItt1 = millis();
        onAccelN1 = onAccelN2 = false;
    }
    
    float getGnnData(float refValue, int IDX_REF, int IDX_DATA) {
        int i=0; float hiBound=0, loBound=0, loRef=0, hiRef=0;
        float weightedData = 0;
        while ( ( gnn[i][IDX_REF] < refValue ) && (i < gnn.length) )
            i++;
        if ( i != 0 ) {
            loBound = gnn[i-1][IDX_DATA];
            hiBound = gnn[i][IDX_DATA];
            loRef = gnn[i-1][IDX_REF];
            hiRef = gnn[i][IDX_REF];
            weightedData = loBound + ( ( refValue - loRef ) / ( hiRef - loRef) ) * (hiBound - loBound);
        }
        else
            weightedData = gnn[i][IDX_DATA];
        
		//println("==> Ref: " + refValue + " [" + loBound + ".." + hiBound + "] : " + weightedData );
        return weightedData;
    }
    
    float getN1Max(float ref) {
		if ( oeiState )
        	return getGnnData(ref, IDX_THROTTLE, IDX_N1_MAX_OEI);
		else 
        	return getGnnData(ref, IDX_THROTTLE, IDX_N1_MAX);
    }
    
    float getN2Max(float ref) {
		if ( oeiState )
        	return getGnnData(ref, IDX_THROTTLE, IDX_N2_MAX_OEI);
		else
        	return getGnnData(ref, IDX_THROTTLE, IDX_N2_MAX);
    }
    
    // return the whole weighted time from the range [fromRef,toRef]
    float getN1Dt(float fromRef, float toRef) {
        float dt = 0; 
        int i=0;
        while ( ( gnn[i][IDX_N1_MAX] < fromRef ) && ( i < gnn.length ) )
            i++;
        // calculate remaining time from fromRef to next step
        if ( fromRef == 0 )
            dt = gnn[i][IDX_N1_DT];
        else {
            if ( gnn[i][IDX_N1_MAX] != fromRef ) // we ignore time if fromRef == N1_MAX   
                dt = ( ( gnn[i][IDX_N1_MAX] - fromRef) / gnn[i][IDX_N1_MAX] ) * gnn[i][IDX_N1_DT];
        }
        // now calculate how many time to toRef
        if ( toRef > gnn[i][IDX_N1_MAX] ) { 
            while ( ( gnn[i][IDX_N1_MAX] < toRef ) && ( i < gnn.length ) ) {
                i++;
                dt += gnn[i][IDX_N1_DT];
            }
            dt -= ( ( gnn[i][IDX_N1_MAX] - toRef ) / ( gnn[i][IDX_N1_MAX] - gnn[i-1][IDX_N1_MAX] ) ) * gnn[i][IDX_N1_DT];
        } else
            dt -= ( ( gnn[i][IDX_N1_MAX] - toRef ) / gnn[i][IDX_N1_MAX] ) * gnn[i][IDX_N1_DT];
            
        //println("["+i+"] Total time from: "+fromRef+" to: "+toRef+" = "+dt);
        return ( 1 + dt );    // minimum 1 sec., some range could be very small
    }
    
    float getN2Dt(float fromRef, float toRef) {
        float dt = 0; 
        int i=0;
        while ( ( gnn[i][IDX_N2_MAX] < fromRef ) && ( i < gnn.length ) )
            i++;
        // calculate remaining time from fromRef to next step
        if ( fromRef == 0 )
            dt = gnn[i][IDX_N2_DT];
        else {
            if ( gnn[i][IDX_N2_MAX] != fromRef ) // we ignore time if fromRef == N2_MAX   
                dt = ( ( gnn[i][IDX_N2_MAX] - fromRef) / gnn[i][IDX_N2_MAX] ) * gnn[i][IDX_N2_DT];
        }
        // now calculate how many time to toRef
        if ( toRef > gnn[i][IDX_N2_MAX] ) { 
            while ( ( gnn[i][IDX_N2_MAX] < toRef ) && ( i < gnn.length ) ) {
                i++;
                dt += gnn[i][IDX_N2_DT];
            }
            dt -= ( ( gnn[i][IDX_N2_MAX] - toRef ) / ( gnn[i][IDX_N2_MAX] - gnn[i-1][IDX_N2_MAX] ) ) * gnn[i][IDX_N2_DT];
        } else
            dt -= ( ( gnn[i][IDX_N2_MAX] - toRef ) / gnn[i][IDX_N2_MAX] ) * gnn[i][IDX_N2_DT];
        
        //println("["+i+"] Total time from: "+fromRef+" to: "+toRef+" = "+dt);
        return ( 1 + dt );    // minimum 1 sec., some range can be very small
    }
    
    void updateN1() {
        float maxAvailablePower = getN1Max(throttle);
        if ( n1PowerNeeds < maxAvailablePower )
            n1Target = n1PowerNeeds;
        else
            n1Target = maxAvailablePower * ( ( state != STATE_STOP ) ? 1:0); // we need to override gnnData
        if ( n1Target > n1 ) {                // accelerate
            if ( !onAccelN1 ) {
                onAccelN1 = true;
                easeN1.reset();
                n1t0 = n1;
            }
            float dt = getN1Dt(n1t0,n1Target);
            //println("N1 accel dt: "+dt);
            n1 = easeN1.interpolate("sineEaseInOut",dt, n1, n1t0, n1Target);
            if ( n1 >= n1Target ) {
                n1t0 = n1 = n1Target;
                easeN1.reset();
                onAccelN1 = false;
            }
            //println("N1 th: " + throttle + ", n1: " + n1 + ", n1_0:" + n1t0 + ", target:" + n1Target + ", dt: " + dt);
        }
        if ( n1Target < n1 ) {                // decelerate
            if ( onAccelN1 ) {
                onAccelN1 = false;
                easeN1.reset();
                n1t0 = n1;
            }
            float dt = 2 + (n1t0 - n1Target) / 2.0;
            n1 = n1t0 - easeN1.interpolate("cubicEaseOut",dt, n1t0 - n1, 0, n1t0 - n1Target);
            if ( n1 <= n1Target ) {
                n1t0 = n1 = n1Target;
                easeN1.reset();
            }
            //println("- thrust:" + throttle + ", n1: " + n1 + ", n1_0:" + n1_0 + ", target:" + n1Target + ", dt: " + dt);
        }
    }
    
    void updateN2() {
        n2Target = getN2Max(throttle); // max decrease with ad.
        //println("+ thrust:" + throttle + ", n2: " + n2 + ", n2_0:" + n2t0 + ", target:" + n2Target);
        if ( n2Target > n2 ) {
            if ( !onAccelN2 ) {
                onAccelN2 = true;
                easeN2.reset();
                n2t0 = n2;
            }
            float dt = getN2Dt(n2t0,n2Target);
            onAccelN2 = true;
            n2 = easeN2.interpolate("sineEaseInOut",dt, n2, n2t0, n2Target);
            if ( n2 >= n2Target ) {
                n2t0 = n2 = n2Target;
                easeN2.reset();
                onAccelN2 = false;
            }
            //println("+ thrust:" + throttle + ", n2: " + n2 + ", n2_0:" + n2t0 + ", target:" + n2Target + ", dt: " + dt);
        }
        if ( n2Target < n2 ) {                // decelerate
            if ( onAccelN2 ) {
                onAccelN2 = false;
                easeN2.reset();
                n2t0 = n2;
            }
            float dt = 2 + (n2t0 - n2Target) / 2.5;
            n2 = n2t0 - easeN2.interpolate("cubicEaseOut",dt, n2t0 - n2, 0, n2t0 - n2Target);
            if ( n2 <= n2Target ) {
                n2t0 = n2 = n2Target;
                easeN2.reset();
            }
            //println("- thrust:" + throttle + ", n2: " + n2 + ", n2_0:" + n2t0 + ", target:" + n2Target + ", dt: " + dt);
        }
    }
    
    void updateTorque() {
        float rtorque = changeScale(rtorquepct,0,100,0,MIN_N2_IDLE); // 0..100 => 0..MIN_N2 ( can't decrease under MIN_N2 )
        float frac = (n2 - rtorque )  / 100;
        //torque = (frac * maxTorque * ( rho / rho0) ); TODO RHO
        torque = frac * maxTorque;
        //torque_pct = (maxTorque - torque ) / maxTorque * 100;
    }

    void updateSpeed() {
        speed = calcSpeed(maxPower * n2 / 100, maxTorque);
    }
    
    void updatePower() {
        fracn1 = clamp(changeScale(n1, minN1Rho, MAX_N1, 0, 100),0,100);
        power = calcPower(torque,speed) + (power * fracn1 / 100);
    }
        
    void updateN1PowerNeeds() {
        float t = ((maxTorque - torque) / maxTorque * 100 );
        n1PowerNeeds = changeScale(t, 0, 100, minN1Rho, MAX_N1);
    }
    
    void updateN1Speed() {
        n1Speed = maxSpeed * n1 / 100;
    }
    
    //void updateN2Speed() {
    //    this.speed = maxSpeed * n2 / 100;
    //}
    
    void updateAirDensity() {
        float altitude = alt;                     // TODO nasal getAlt();
        rho = ARDC.getAirDensity(altitude);
        minN1Rho = MAX_N1 - (( MAX_N1 - MIN_N1_IDLE ) * rho/rho0 );
    }
   
	void updateITT(float target_pct) {
		float frac = (MAX_ACCEL_SPEED) / (MAX_ACCEL_SPEED - n2accelSpeed);
		itt_deg = frac * (MAX_ITT_CONT * target_pct)/100;
		//target = frac * (MAX_ITT_CONT * target_pct)/100;
		//itt_deg = easeItt.interpolate("sineEaseInOut", dt, itt_deg, 0, target);
	}

    void updateLimits() {
		if ( oeiState ) {
			maxPower = MAX_POWER_OEI;
        	maxSpeed = MAX_RPM_OEI;
        	maxTorque = calcTorque(maxPower,maxSpeed);    // max torque at N2
          	MIN_N1_IDLE = gnn[IDX_GNN_IDLE][IDX_N1_MAX_OEI];	//
          	MAX_N1 		= gnn[IDX_GNN_MAX][IDX_N1_MAX_OEI];	//
          	MIN_N2_IDLE = gnn[IDX_GNN_IDLE][IDX_N2_MAX_OEI];	//
          	MAX_N2 		= 100;
		} else {
			maxPower = MAX_POWER_CONT;
			maxSpeed = MAX_RPM_CONT;
			maxTorque = calcTorque(maxPower,maxSpeed);
          	MIN_N1_IDLE = gnn[IDX_GNN_IDLE][IDX_N1_MAX];	//
          	MAX_N1 		= gnn[IDX_GNN_MAX][IDX_N1_MAX];	//
          	MIN_N2_IDLE = gnn[IDX_GNN_IDLE][IDX_N2_MAX];	//
          	MAX_N2 		= 100;
		}
        updateAirDensity();    // minN1Rho
    }
    
    void update() {
        float speed0 = speed;
        etime1 = eTimeFrom(etime0);
        etimeItt1 = eTimeFrom(etimeItt0);
        if ( state >= STATE_START ) {
            updateLimits();
            updateTorque();
            updateSpeed();
            updatePower();
            updateN2();
            updateN1PowerNeeds();
            updateN1();
            updateN1Speed();
			ittTarget = n1;
			if ( etimeItt1 > ITT_LATENCY ) {
				easeItt.reset();
				ittTransit = ittTarget;
				etimeItt0 = millis();
			}
			updateITT(ittTarget);
        } else if ( state == STATE_STOP ) {
            setThrottle(0);
            updateTorque();
            updateSpeed();
            updatePower();
            updateN2();
            updateN1PowerNeeds();
            updateN1();
            updateN1Speed();
			updateITT(n1);
            if ( n1 == 0 && n2 == 0 )
                state = STATE_DOWN;
        }
        display();
        n2accelSpeed = calcAccelSpeed(rpm2rad(speed0),rpm2rad(speed),etime1);
        n2accelSpeed = rad2rpm(n2accelSpeed);
        etime0 = millis();
    }
    
    void start() {
        state = STATE_START;
    }
    
    void stop() {
        state = STATE_STOP;
    }
    
    void startIdle() {
        setThrottle(3);
        state = STATE_IDLE;
    }
    
    int getState() { return state; }
    boolean isStarted() { return ( state >= STATE_START); }
    
    void setThrottle(float v) {
        throttle = v;
        if ( throttle != throttle0 ) {
            easeN1.reset();
            n1t0 = n1;
            onAccelN1 = false;
            easeN2.reset();
            n2t0 = n2;
            onAccelN2 = false;
            throttle0 = throttle;
        }
    }

	float getPower() { return power; }

	void setOeiState(boolean omode) { oeiState = omode; }
        
    boolean isRunning() {
        return (state != 0);
    }
    
    float eTimeFrom(float dt0) {
        return millis() - dt0;
    }

    // Displaying   
    void setDisplayAt(float ix, float iy) {
        x = ix; y=iy;
        float rad = instrumentSize / 2;
        instrumentN1.setXY(x+margin+rad,y+rad);
        instrumentN2.setXY(x+margin+rad*3+10,y+rad);
        labelPower.setXY(x+margin+(rad*4)+10,y+rad);
        //labelAD.setXY(x,y);
        //labelThrust.setXY(x,y+labelAD.geth());
        labelN1.setXY(instrumentN1.getx(),instrumentN1.gety()+rad/2+10);
        labelN2.setXY(instrumentN2.getx(),instrumentN2.gety()+rad/2+10);
        labelITT.setXY(x+margin+(rad*2)+5,y+rad*1.8);
        labelTorque.setXY(x+margin+(rad*2)+5,y+rad*2.1);
    }
    
    void display() {
        instrumentN1.displayAtRpm(n1Speed);
        instrumentN2.displayAtRpm(this.speed);
        //labelThrust.display("T: "+(int)throttle+" %");
        //labelAD.display("A: " + rho + " kg/m3");
        labelPower.display(""+(int)power+" kW");
        labelN1.display(""+(int)n1+" %");
        labelN2.display(""+(int)n2+" %");
        labelITT.display(""+(int)itt_deg+" °C");
        labelTorque.display(""+(int)torque_pct+" %N.m");
        printData();
    }
    
    void printData() {
        final int CH = 12; // char height
        float posx=x;
        float posy=y;
        String s = "";
        String d = "";
        noStroke();
        
        fill(0);
        rectMode(CORNER);
        rect(posx, posy-CH, margin-2, 130);
        fill(255);
    
        textFont(font);
        textAlign(LEFT);
    
        posy += 5;
        d = String.format("%.5g%n", throttle);
        s = "Throttle    : " + d;
        text(s,posx,posy);
        
        posy += CH;
        d = String.format("%.5g%n", MIN_N1_IDLE);
        s = "Min N1 IDLE : " + d;
        text(s,posx,posy);
        
        posy += CH;
        d = String.format("%.5g%n", MAX_N1);
        s = "Max N1      : " + d;
        text(s,posx,posy);
        
        posy += CH;
        d = String.format("%.5g%n", rho);
        s = "AirDensity  : " + d;
        text(s, posx, posy);
        
        posy += CH;
        d = String.format("%.5g%n",minN1Rho);
        s = "min n1 rho  : " + d;
        text(s, posx, posy);
        
        posy += CH;
        d = String.format("%.5g%n",n1PowerNeeds);
        s = "n1PowerNeeds: " + d;
        text(s, posx, posy);
        
        posy += CH;
        d = String.format("%.5g%n",fracn1);
        s = "frac n1     : " + d;
        text(s, posx, posy);        
        
        posy += CH;
        d = String.format("%.5g%n",n2accelSpeed);
        s = "n2accelSpeed: " + d;
        text(s, posx, posy);

        posy += CH;
        d = String.format("%.5g%n",torque_pct);
        s = "Torque %    : " + d;
        text(s, posx, posy);
        
    }
    
    int getInstrumentSize() { return instrumentSize; }
    
    // return x from [a0,b0] scaled to [a1,b1]
    float changeScale(float x, float a0, float b0, float a1, float b1) {
        return a1 + ( (x-a0) / (b0-a0) ) * (b1-a1);
    }
    
    float clamp(float x, float mn, float mx) {
        return min(max(x, mn), mx);
    }

    // Engines stuff
    // power/torque/rpm have a constant relationship as of:
    float calcPower (float itorque, float ispeed) {
	return (itorque * ispeed / 9.549296) / 1000;

    }

    float calcTorque (float ipower, float ispeed) {
	return ( ipower * 9549.296 / ispeed);
    }

    float calcSpeed (float ipower, float itorque) {
	return ( ipower * 9549.296 / itorque);

    }

    float rpm2rad (float irpm ) {
	return irpm * 0.10471975512;
    }

    float rad2rpm (float iomega) {
	return iomega * 9.54929658548;
    }
    
    // calculate the angular velocity from a delta angle since an elapsed time
    float calcAccelSpeed(float a0_rad, float a1_rad, float etime_millis) {
        float delta = (((a1_rad - a0_rad)/etime_millis) * 1000) / (2*PI); // in sec.
        
        return delta * 60 / round(frameRate); // delta in rad per minute
    }
}
