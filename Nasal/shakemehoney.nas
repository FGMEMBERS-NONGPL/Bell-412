# ======================================================================================================
# Bell412 Shake effect
# 	(for the Flightgear Flight Simulator)
# ------------------------------------------------------------------------------------------------------
# DESC
# 	Shake effect when chopper is landed and rpm is > 100
#
# AUTHOR
# 	Valery Seys		valery@vslash.com
#
# CHANGELOG
# 18/11/16	: init
# ======================================================================================================
# ------------------------------------------------------------------------------------------------------
# Const
# ------------------------------------------------------------------------------------------------------
var ROTOR_MAX_RPM = 324;

# ------------------------------------------------------------------------------------------------------
# Globals
# ------------------------------------------------------------------------------------------------------
var speed = props.globals.getNode("rotors/main/rpm");
var shake_effect_state = props.globals.getNode("controls/options/shake");
var userview_heading = props.globals.getNode("sim/current-view/x-offset-m");
var ralt = props.globals.getNode("position/gear-agl-ft");

# ------------------------------------------------------------------------------------------------------
# Functions stuff
# ------------------------------------------------------------------------------------------------------
var theShakeEffect = func() {
	var current_userview_heading = userview_heading.getValue();
	#var factor = 0.001 + (1/(speed.getValue()/324)*0.0001); # inv.
	var factor = speed.getValue()/ROTOR_MAX_RPM * 0.0010;
	var dt = 1;

	if ( shake_effect_state.getBoolValue() ) {
		#if ( speed.getValue() > 100 and ralt.getValue() < 0.001 ) {
		if ( speed.getValue() > 100 ) {
			settimer(func {
				userview_heading.setValue(current_userview_heading + factor );
				}, 0.02);

			settimer(func {	
				userview_heading.setValue(current_userview_heading - factor );
				}, 0.04);

			settimer(func {	
				userview_heading.setValue(current_userview_heading);
				}, 0.06);

			dt = 0.08;
		}
		settimer(theShakeEffect,dt);
	}
}

# ------------------------------------------------------------------------------------------------------
# Listeners
# ------------------------------------------------------------------------------------------------------
setlistener("controls/options/shake", func(state){
	if(state.getBoolValue()){
		theShakeEffect();
	}
},1,0);
