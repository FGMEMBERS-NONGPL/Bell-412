# battery switches ==================================================
var electrical_bus1_sw = props.globals.initNode("/controls/electrical/switches/bus1", 0, "BOOL");
var electrical_bus2_sw = props.globals.initNode("/controls/electrical/switches/bus2", 0, "BOOL");
var electrical_buses_state = props.globals.initNode("/controls/electrical/buses", 0, "BOOL");

# beacons/nav ========================================================
var light_beacon_sw = props.globals.initNode("/controls/lighting/switches/beacon", 0, "BOOL");
var light_navlights_sw = props.globals.initNode("/controls/lighting/switches/navlights", 0, "BOOL");
var light_beacon = props.globals.getNode("/controls/lighting/beacon", 1);
aircraft.light.new("/controls/lighting/beacon-state", [0.10, 1.2], light_beacon);
#var light_nav = props.globals.getNode("/controls/lighting/nav-lights", 1);

#aircraft.light.new("sim/model/bell412/lighting/beacon-top", [0.62, 0.62], beacon_switch);
#aircraft.light.new("sim/model/bell412/lighting/beacon-bottom", [0.63, 0.63], beacon_switch);

# Misc.
var esound = props.globals.initNode("/sim/sound/electrical", 0.0, "DOUBLE");

# power ========================================================
var ampload1 = props.globals.initNode("/bell412/electrical/bus1/ampload", 0, "DOUBLE");
var ampload2 = props.globals.initNode("/bell412/electrical/bus2/ampload", 0, "DOUBLE");

var update_virtual_bus = func {
	# bus1
	if ( electrical_bus1_sw.getBoolValue() ) {
		setprop("/bell412/electrical/bus1/ampload", 60);
		setprop("/bell412/electrical/bus1/voltacload", 115);
		setprop("/bell412/electrical/bus1/voltdcload", 28);
	} else {
		setprop("/bell412/electrical/bus1/ampload", 0);
		setprop("/bell412/electrical/bus1/voltacload", 0);
		setprop("/bell412/electrical/bus1/voltdcload", 0);
	}

	# bus2
	if ( electrical_bus2_sw.getBoolValue() ) {
		setprop("/bell412/electrical/bus2/ampload", 60);
		setprop("/bell412/electrical/bus2/voltacload", 115);
		setprop("/bell412/electrical/bus2/voltdcload", 28);
	} else {
		setprop("/bell412/electrical/bus2/ampload", 0);
		setprop("/bell412/electrical/bus2/voltacload", 0);
		setprop("/bell412/electrical/bus2/voltdcload", 0);
	}

	# buses
	if ( electrical_bus1_sw.getBoolValue() or electrical_bus2_sw.getBoolValue() ) {
		interpolate("/sim/sound/electrical",1.0,3);
		setprop("/bell412/electrical/output/console/pilot", 1);
		setprop("/bell412/electrical/output/console/copilot", 1);
	} else { 
		interpolate("/sim/sound/electrical",0.0,1);
		setprop("/bell412/electrical/output/console/pilot", 0);
		setprop("/bell412/electrical/output/console/copilot", 0);
	}
		
	if ( electrical_bus1_sw.getBoolValue() and electrical_bus2_sw.getBoolValue() ) {
		setprop("/controls/electrical/buses", 1);
		setprop("/bell412/electrical/buses", 1);
	} else {
		setprop("/controls/electrical/buses", 0);
		setprop("/bell412/electrical/buses",0);
	}
	
	# lights switches
	if ( light_beacon_sw.getBoolValue() ) {			# texture appearance depends on electrical_buses_state, see lights.xml
		setprop("/controls/lighting/beacon", 1);
	} else {
		setprop("/controls/lighting/beacon", 0);
	}

  	if ( light_navlights_sw.getBoolValue() ) {		# texture appearance depends on electrical_buses_state, see lights.xml
  		setprop("/controls/lighting/nav-lights", 1);
  	} else {
	  	setprop("/controls/lighting/nav-lights", 0);
	}		  
}

var update_electrical = func {
  	update_virtual_bus();
	settimer(update_electrical, 0);
}


setlistener("/sim/signals/fdm-initialized", func {
	#init_switches();
	setprop("/sim/sound/electrical", 0.0);
	setprop("/controls/electrical/buses", 0);
	settimer(update_electrical,5);
    
	print("[Bell-412] - Electrical System ... Initialized");
    
	#setprop("controls/engines/msg", 1);
});
