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
var ROTOR_MAIN_RPM_MAX = 324;
var BRAKE_LIMIT_PERCENT = 40;

# Globals
var alarm = props.globals.getNode("bell412/power/output/cautions/alarm");
var engine_state = props.globals.getNode("sim/model/bell412/state");								# TODO: oldvalue engine state [0..5]
var buses_state = props.globals.getNode("/bell412/power/buses/state");
var rotor_rpm = props.globals.getNode("rotors/main/rpm");											# set by Yasim
var radioalt_set = props.globals.getNode("controls/instruments/radioalt/set");
var radioalt_alarm = props.globals.getNode("controls/instruments/radioalt/alarm");
var radioalt_alt = props.globals.getNode("position/gear-agl-ft");
var rpmpct = props.globals.getNode("/bell412/mechanics/engines/nr");
var torquepct = props.globals.getNode("/bell412/mechanics/engines/torquepct");	# mast torque instrument

# Properties to monitor
var collectiv_throttle 	= props.globals.getNode("controls/engines/engine/throttle");
var rotor_brake			= props.globals.getNode("controls/engines/brake");

# Monitoring Functions
var check_collectiv = func() {
	if ( engine_state.getValue() == 0 ) {
		if ( collectiv_throttle.getValue() < 0.8 )		# 20% (min 1, max 0)
			alarm.setValue(1);
		else
			alarm.setValue(0);
	}
}

var check_rotorbrake = func() {
	if ( ((rotor_rpm.getValue()/ROTOR_MAIN_RPM_MAX)*100 ) > BRAKE_LIMIT_PERCENT ) {					#TODO: oldvalue
		if ( rotor_brake.getValue() > 5 )
			alarm.setValue(1);
		else
			alarm.setValue(0);
	}
}

var check_radioalt = func() {
	if ( (radioalt_set.getValue() != 0 ) and ( radioalt_alt.getValue() > 1 ) and ( radioalt_alt.getValue() < radioalt_set.getValue() ) ) {
		radioalt_alarm.setValue(1);
	} else
		radioalt_alarm.setValue(0);
}

var check_rpm = func() {
	state0 = iBell412.Rotor.Engines[0].state.getValue();
	state1 = iBell412.Rotor.Engines[1].state.getValue();
	
	if ( ( state0 == 5 or state1 == 5 ) and ( rpmpct.getValue() < 95 or rpmpct.getValue() > 104 ) )
			alarm.setValue(1);
		else
			alarm.setValue(0);
}	

# Thread loop
var monitor = func {
	if ( buses_state.getBoolValue() ) {					# check only if system is powered
		check_collectiv();
		check_rotorbrake();
		check_radioalt();
		check_rpm();
	}
	settimer(monitor, 0.5);								# more check ==> greater value (avoid overload)
}

# init
setlistener("/sim/signals/fdm-initialized", func {
	print("[Bell-412] * System Monitoring: ready.");
	monitor();
});
