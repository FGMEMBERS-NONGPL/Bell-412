# ======================================================================================================
# Bell412 Warning System Monitoring 
# 	(for the Flightgear Flight Simulator)
# ------------------------------------------------------------------------------------------------------
#
# AUTHOR
# 	Valery Seys		vslash.com
#
# DESCR
# 	monitor some value and trig alarm sound if required
#
# REFS
# 	Textron BHT-412 Rotorcraft Flight Manual (rev. 9/2002)
# 	Flightgear Nasal Wiki: http://wiki.flightgear.org/Category:Nasal
#
# CHANGELOG
# 11/2016	: init
# ======================================================================================================

# Const
var ROTOR_MAIN_RPM_MAX 	= props.globals.getNode("bell412/limits/rotor_rpm_max").getValue();
var BRAKE_LIMIT_PERCENT = props.globals.getNode("bell412/limits/engine_brake-pct_max").getValue();
var TORQUE_MAX_PCT 		= props.globals.getNode("bell412/limits/xmsn_torque_max").getValue(); 

# Globals
var alarm = props.globals.getNode("bell412/electrical/output/cautions/alarm");
var buses_state = props.globals.getNode("bell412/electrical//buses/bus[0]/state");
var rotor_rpm = props.globals.getNode("rotors/main/rpm");											# set by Yasim
var radaralt_dh = props.globals.getNode(   "instrumentation/radar-altimeter/dh");
var radaralt_alarm = props.globals.getNode("instrumentation/radar-altimeter/caution");
var radaralt_alt = props.globals.getNode(  "instrumentation/radar-altimeter/gear-agl-ft");
var torquepct = props.globals.getNode("bell412/mechanics/engines/torquepct");	# mast torque instrument

# Properties to monitor
var collectiv_throttle 	= props.globals.getNode("controls/engines/engine/throttle");
var rotor_brake			= props.globals.getNode("controls/engines/brake");

# Monitoring Functions
var check_collectiv = func() {
	state0 = iBell412.Rotor.Engines[0].state.getValue();
	state1 = iBell412.Rotor.Engines[1].state.getValue();
	if ( (state0 == 0) and (state1 == 0) ) {
		if ( collectiv_throttle.getValue() < 0.8 ){		# 20% (min 1, max 0)
			#print("DEBUG: collectiv alert");
			return 0;
		}
		else
			return 1;
	}
	return 1;
}

var check_rotorbrake = func() {
	if ( ((rotor_rpm.getValue()/ROTOR_MAIN_RPM_MAX)*100 ) > BRAKE_LIMIT_PERCENT ) {					#TODO: oldvalue
		if ( rotor_brake.getValue() > 5 ) {
			#print("DEBUG: rotorbrake alert");
			return 0;
		}
		else
			return 1;
	}
	return 1;
}

var check_radaralt = func() {
	if ( (radaralt_dh.getValue() != 0 ) and ( radaralt_alt.getValue() > 1 ) and ( radaralt_alt.getValue() < radaralt_dh.getValue() ) ) {
		radaralt_alarm.setValue(1);
	} else
		radaralt_alarm.setValue(0);
}

var check_rpm = func() {
	state0 = iBell412.Rotor.Engines[0].state.getValue();
	state1 = iBell412.Rotor.Engines[1].state.getValue();
	nrpct = iBell412.Rotor.nr.getValue();

	if ( ( (state0 == 5) or (state1 == 5) ) and ( (nrpct < 95) or (nrpct > 104) ) ) {
		#print("DEBUG: rpm alert");
		return 0;
	}
	else
		return 1;
}	

var check_torque = func() {
	if ( ( torquepct.getValue() > TORQUE_MAX_PCT ) ) {
		#print("DEBUG: torque alert");
		return 0;
	}
	else
		return 1;
}	

# Thread loop
# TODO: reset alarm: reset set to 1 => alarm(0) until alarm are clear, then reset = 0, redo.
var monitor = func {
	if ( buses_state.getBoolValue() ) {					# check only if system is powered
		check_radaralt();								# independent system
		if ( check_collectiv() and check_rotorbrake() and check_rpm() and check_torque() )
			alarm.setValue(0);
		else {
			alarm.setValue(1);
		}
	} else
		alarm.setValue(0);
	settimer(monitor, 0.5);								# more check ==> greater value (avoid overload)
}

# init
setlistener("/sim/signals/fdm-initialized", func {
	#print("[Bell-412] * System Monitoring: ready.");
	monitor();
});
