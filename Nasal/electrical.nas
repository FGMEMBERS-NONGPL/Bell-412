# battery switches ==================================================
var power_bus1_sw = props.globals.initNode("/controls/power/switches/bus1", 0, "BOOL");
var power_bus2_sw = props.globals.initNode("/controls/power/switches/bus2", 0, "BOOL");
var power_inv1_sw = props.globals.initNode("/controls/power/switches/inv1", 0, "BOOL");
var power_inv2_sw = props.globals.initNode("/controls/power/switches/inv2", 0, "BOOL");

# consoles switches ==================================================
var console_bat1_sw = props.globals.initNode("/controls/consoles/switches/bat1", 0, "BOOL");
var console_bat2_sw = props.globals.initNode("/controls/consoles/switches/bat2", 0, "BOOL");

# lights dimmer ======================================================
var dimmer_conslt = props.globals.initNode("/controls/lighting/switches/conslt", 0, "DOUBLE");
var dimmer_pilotlt = props.globals.initNode("/controls/lighting/switches/pilotlt", 0, "DOUBLE");
var dimmer_pedlt = props.globals.initNode("/controls/lighting/switches/pedestallt", 0, "DOUBLE");

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
var power_buses_state = props.globals.initNode("/bell412/power/buses", 0, "DOUBLE");
var ampload1 = props.globals.initNode("/bell412/power/bus1/ampload", 0, "DOUBLE");
var ampload2 = props.globals.initNode("/bell412/power/bus2/ampload", 0, "DOUBLE");
var consoles_state = props.globals.initNode("/bell412/power/output/consoles/state", 0, "BOOL");

var update_virtual_bus = func {
	# bus1 On/Off
	if ( power_bus1_sw.getBoolValue() ) {
		setprop("/bell412/power/bus1/ampload", 60);
		setprop("/bell412/power/bus1/acload", 115);
		setprop("/bell412/power/bus1/dcload", 28);
	} else {
		setprop("/bell412/power/bus1/ampload", 0);
		setprop("/bell412/power/bus1/acload", 0);
		setprop("/bell412/power/bus1/dcload", 0);
		#interpolate("/bell412/power/buses",0,2);
		setprop("/bell412/power/buses",0);
	}
	# bus2 On/Off
	if ( power_bus2_sw.getBoolValue() ) {
		setprop("/bell412/power/bus2/ampload", 60);
		setprop("/bell412/power/bus2/acload", 115);
		setprop("/bell412/power/bus2/dcload", 28);
	} else {
		setprop("/bell412/power/bus2/ampload", 0);
		setprop("/bell412/power/bus2/acload", 0);
		setprop("/bell412/power/bus2/dcload", 0);
		#interpolate("/bell412/power/buses",0,2);
		setprop("/bell412/power/buses",0);
	}
	
	# buses check
	if ( power_buses_state.getValue() == 0 ) {
	 	# reset outputs to 0
		setprop("/bell412/power/output/consoles/state",0);
		setprop("/bell412/power/output/consoles/instruments",0);
		setprop("/bell412/power/output/consoles/conslt",0);
		setprop("/bell412/power/output/consoles/pilotlt",0);
		setprop("/bell412/power/output/consoles/pedestallt",0);
		setprop("/bell412/power/output/engines/state",0);
		
		if ( power_bus1_sw.getBoolValue() and power_bus2_sw.getBoolValue() ) {
			#setprop("/bell412/power/buses", 1);
			interpolate("/bell412/power/buses",1.0,2);	# sounds need this
			#help_win.write(sprintf("buses load: %.0f ", power_buses_state.getValue()));
			help_win.write("buses loaded");
		}
	# buses On, powering all electrical devices
	} else {
		if ( console_bat1_sw.getBoolValue() or console_bat2_sw.getBoolValue() ) {
			setprop("/bell412/power/output/consoles/state",1);
		} else {
			setprop("/bell412/power/output/consoles/state",0);
		}
		if ( consoles_state.getBoolValue() ) {
			setprop("/bell412/power/output/consoles/instruments",1);
			setprop("/bell412/power/output/consoles/conslt", 1 * dimmer_conslt.getValue());
			setprop("/bell412/power/output/consoles/pilotlt",1 * dimmer_pilotlt.getValue());
			setprop("/bell412/power/output/consoles/pedestallt",1 * dimmer_pedlt.getValue());
		} else {
			setprop("/bell412/power/output/consoles/instruments",0);
			setprop("/bell412/power/output/consoles/conslt",0);
			setprop("/bell412/power/output/consoles/pilotlt",0);
			setprop("/bell412/power/output/consoles/pedestallt",0);
		}
		setprop("/bell412/power/output/engines/state",1);
	}
}

var update_power = func {
  	update_virtual_bus();
	settimer(update_power, 0);
}


setlistener("/sim/signals/fdm-initialized", func {
	#init_switches();	# TODO + user prefs saved
	setprop("/sim/sound/electrical", 0.0);
	# dimmer default
	setprop("/controls/lighting/switches/conslt", 1.0);
	setprop("/controls/lighting/switches/pilotlt",1.0);
	setprop("/controls/lighting/switches/pedestallt",1.0);
	settimer(update_power,5);
    
	print("[Bell-412] - Electrical System ... Initialized");
    
	#setprop("controls/engines/msg", 1);
});
