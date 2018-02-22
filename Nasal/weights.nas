# ======================================================================================================
# Bell412 Weight Manager 
# 	(for the Flightgear Flight Simulator)
# ------------------------------------------------------------------------------------------------------
#
# AUTHOR
# 	Valery Seys		vslash.com
#
# REFS
# 	Textron BHT-412 Rotorcraft Flight Manual (rev. 9/2002)
# 	Flightgear Nasal Wiki: http://wiki.flightgear.org/Category:Nasal
#
#
# CHANGELOG
# 07/2017	: init
# ======================================================================================================
#
# Globals
#
var WEIGHT_DT = 1.5;	# (sec.) update time
var PFX_WEIGHT_NODE = "/bell412/weights";
var WEIGHT_NODES = { 	# testing a new way to use FG tree pty
	"antijitter" 		: props.globals.getNode(PFX_WEIGHT_NODE~"/antijitter"),
	"cdoorleftclosed" 	: props.globals.getNode(PFX_WEIGHT_NODE~"/cdoorleftclosed"),
	"cdoorrightclosed" : props.globals.getNode(PFX_WEIGHT_NODE~"/cdoorrightclosed"),
	"cdoorleftopened" 	: props.globals.getNode(PFX_WEIGHT_NODE~"/cdoorleftopened"),
	"cdoorrightopened" : props.globals.getNode(PFX_WEIGHT_NODE~"/cdoorrightopened"),
};


var nodenr 			= props.globals.getNode("bell412/mechanics/engines/nr");	# rotor pct

# 
# Functions
#
# weight: antijitter : partialy solve the Yasim jitter/slice bug
# its weight is 1/NR% when aircraft is on the ground
var weightAntijitterUpdate = func(nr) {
	var w = WEIGHT_NODES["antijitter"].getValues()["weight-lb"];						# current weight
	var max = WEIGHT_NODES["antijitter"].getValues()["max-lb"];							# max weight
	var speed 		= props.globals.getNode("velocities/groundspeed-kt").getValue();	# below 0.1 kt
	var radio_alt 	= props.globals.getNode("position/gear-agl-ft").getValue();			# below 0.5 ft
	#var nr = nodenr.getValue();

	if ( speed < 0.1 and radio_alt < 0.5 ) {											# aware with engine failure during cruise
		var j = max - ( max * nr / 100 );
		WEIGHT_NODES["antijitter"].setValues( { "weight-lb":j } );
	} else
		WEIGHT_NODES["antijitter"].setValues( { "weight-lb":0 } );
}

# Balance Cargo Doors : transfert weight from 'frompos' to 'topos'
var weightBalanceCdoor = func ( side, from, to, dt ) {
	var nodeNameFrom = "cdoor"~side~from ;
	var nodeNameTo = "cdoor"~side~to;
	
	var maxTo = WEIGHT_NODES[nodeNameTo].getValues()["max-lb"];					# max weight to  fill
	interpolate(PFX_WEIGHT_NODE~"/"~nodeNameFrom~"/weight-lb",0,dt);			# reset to 0
	interpolate(PFX_WEIGHT_NODE~"/"~nodeNameTo~"/weight-lb",maxTo,dt);			# set to maxTo
}

# 
# Timers
#
# Vibration according to Cargo doors position and speed
# 

var WEIGHT_VIB_FACTOR = 1;

var weightUpdateCargoDoorVibration = maketimer(0.10, bell412, func() {
	#print("DEBUG: weightUpdateVibration: running");
	WEIGHT_VIB_FACTOR = ~WEIGHT_VIB_FACTOR + 1;
	var lat = props.globals.getNode("/bell412/mechanics/vibration/lat");
	var long = props.globals.getNode("/bell412/mechanics/vibration/long");
	var antispeed = props.globals.getNode("/bell412/mechanics/vibration/counterspeed");
	var v = props.globals.getNode("/instrumentation/airspeed-indicator/indicated-speed-kt").getValue();

	if ( v > LIMITS.VNE_DOORSOPENED_MAX ) {
		var eMax = LIMITS.VNE_DOORSOPENED_MAX + 15;		# effect max vibration @ VNE_MAX + 15 Kn.
		var vib = (v - LIMITS.VNE_DOORSOPENED_MAX) / (eMax - LIMITS.VNE_DOORSOPENED_MAX );
		vib = ( vib > 1 ) ? 1 : vib;	# clamp
		#print("DEBUG: v:"~v~", Lim:"~LIMITS.VNE_DOORSOPENED_MAX~", eMax: "~eMax~", eLat:"~eLat);

		lat.setValue(WEIGHT_VIB_FACTOR * vib);
		long.setValue(WEIGHT_VIB_FACTOR * vib);

	} else {
		lat.setValue(0);
		long.setValue(0);
	}
});

var weightResetCargoDoorVibration = func() {
	#print("DEBUG: weightReset: "~getprop("/controls/doors/back/left")~", "~getprop("/controls/doors/back/right"));
	if ( getprop("/controls/doors/back/left") != 1 and getprop("/controls/doors/back/right") != 1 ) {
		weightUpdateCargoDoorVibration.stop();
		props.globals.getNode("/bell412/mechanics/vibration/lat").setValue(0);
		props.globals.getNode("/bell412/mechanics/vibration/long").setValue(0);
	}
}

# Update loop
var weightsUpdate = func() {
	var nr = nodenr.getValue();
	if ( nr ) {
		weightAntijitterUpdate(nr);
	}
}

#
# Timers
# TODO : setlistener on signal engineStart/Stop or nr != 0
var weightTimer = maketimer(WEIGHT_DT, bell412, func () {
	weightsUpdate();
});

setlistener("/sim/signals/fdm-initialized", func {
	weightTimer.start();
	print("[Bell-412] * Weight Manager: ready.");
});
