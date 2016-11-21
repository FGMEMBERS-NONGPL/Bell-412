# ======================================================================================================
# Bell412 Sounds Tweaks
# 	(for the Flightgear Flight Simulator)
# ------------------------------------------------------------------------------------------------------
#
# AUTHOR
# 	Valery Seys		valery@vslash.com
#
# REFS
#
# CHANGELOG
# 11/2016	: init
# ======================================================================================================

# Const
var SIMPLE_DOOR_DURATION_TIME = 1;					# sound 1 duration
var BIG_DOOR_DURATION_TIME = 3;						# sound 2 duration

var sound_door_reset = func {
	setprop("/controls/doors/soundopen",0);	
	setprop("/controls/doors/soundclose",0);	
}

var sound_door_open = func(node) {
	setprop("/controls/doors/soundopen",1);					# sound trigger
	interpolate(node,1,SIMPLE_DOOR_DURATION_TIME);			# animat
	settimer(sound_door_reset,SIMPLE_DOOR_DURATION_TIME);	# wait for the sound to be played, then reset triggers
}

var sound_door_close= func(node) {
	interpolate(node,0,SIMPLE_DOOR_DURATION_TIME);			# animat
	interpolate("/controls/doors/soundclose",1,SIMPLE_DOOR_DURATION_TIME);	# sound trigger
	settimer(sound_door_reset,SIMPLE_DOOR_DURATION_TIME);	# wait for the sound to be played, then reset triggers
}
