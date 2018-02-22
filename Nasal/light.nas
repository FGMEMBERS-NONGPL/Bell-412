# ======================================================================================================
# Bell412 Lights Stuff
# 	(for the Flightgear Flight Simulator)
# ------------------------------------------------------------------------------------------------------
#
# AUTHOR
# 	Valery Seys		valery@vslash.com
#
# REFS
#
# CHANGELOG
# 06/2016	: init
# 11/2016	: landing light
# ======================================================================================================

var sw_beaconlt= props.globals.getNode("/bell412/electrical/output/lights/beacon");
aircraft.light.new("/controls/lighting/beacon-bottom",[0.1, 1.2], sw_beaconlt);		# beacon flash light bottom
aircraft.light.new("/controls/lighting/beacon-top",[0,0.10, 0,0.9], sw_beaconlt);	# beacon flash light top

# Const
var LANDING_LIGHT_EXT_DURATION = 3;				# sound 1 duration


# tweak for ALS rendering
var set_alslighting = func(v) {
	var rembrandt = props.globals.getNode("sim/rendering/rembrandt/enabled").getBoolValue();
	var internalview = props.globals.getNode("sim/current-view/internal").getBoolValue();
	var landinglt = props.globals.getNode("controls/lighting/switches/landing").getBoolValue();

	#print("set_alslighting: "~rembrandt~", "~internalview~", "~landinglt~", "~v);
	if ( internalview and !rembrandt and v and landinglt ) {
        setprop("/sim/rendering/als-secondary-lights/use-landing-light",1);
    } else 
		setprop("/sim/rendering/als-secondary-lights/use-landing-light",0);
}

# smooth set extensor/retractor to 0 or 1 
# trigger: user landingre switch
var set_landingre = func() {
	var lre = props.globals.getNode("controls/lighting/switches/landingre");
	if ( lre.getValue() < 0.1 ) {
		interpolate(lre,1,LANDING_LIGHT_EXT_DURATION);			# animat on
		set_alslighting(1);
	}
	else {
		if ( lre.getValue() > 0.9 ) {
			interpolate(lre,0,LANDING_LIGHT_EXT_DURATION);		# animat off
			set_alslighting(0);
		}
	}
}
