class Engine {
    Turbine[] turbines;
    GearBox gearbox;
 
    Engine() {
        turbines = new Turbine[2];
        turbines[0] = new Turbine(0,0);
        turbines[1] = new Turbine(0,0);
        gearbox = new GearBox(0,0);
        
        setDisplayAt(10,10);
    } 
    
    Turbine getTurbine(int enr) {
        return turbines[enr];
    }
    
    void update() {
        turbines[0].setThrottle(throttle0);
        turbines[1].setThrottle(throttle1);
        turbines[0].update();
        turbines[1].update();
		gearbox.setPower( ( turbines[0].getPower() + turbines[1].getPower() ) );
        gearbox.update();
    }
    
    void start(int enr) {
        if ( ! turbines[enr].isStarted() )
            turbines[enr].start();
    }
    
    void stop(int enr) {
        if ( turbines[enr].isStarted() )
            turbines[enr].stop();
    }
    
	void setOeiState(int enr, boolean omode) {
		turbines[0].setOeiState(omode);
		turbines[1].setOeiState(omode);
	}
	
    void setDisplayAt(float ix, float iy) {
        turbines[0].setDisplayAt(ix,iy);
        turbines[1].setDisplayAt(ix,turbines[1].getInstrumentSize()+100);
        gearbox.setDisplayAt(ix+540, height/2 - gearbox.getInstrumentSize()/2 - 100 );
    }
    
    void display() { 
        turbines[0].display();
        turbines[1].display();
        gearbox.display(); 
    }
}
