# ======================================================================================================
# Bell412 Instrumentation Processes
# 	(for the Flightgear Flight Simulator)
# ------------------------------------------------------------------------------------------------------
#
# AUTHOR
# 	Valery Seys		valery@vslash.com
#
# COPYRIGHT
# 	Valéry Seys - vslash.com
# 	non-free ; personal use only , 
# 	no distribution allowed
# 	no commercial use allowed
# 
# REFS
#
# CHANGELOG
# 01/2018	: init: DAVTRON M800 logic
# ======================================================================================================
#
# ------------------------------------------------------------------------------------------------------
# Const/Glo
# ------------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------------
# MD800
# ------------------------------------------------------------------------------------------------------
var num_digit = 4;	# HHMM
var num_mode = 3;	# 0:GMT 1:LT 2:ET

var clock_mode 		= props.globals.getNode("instrumentation/clock/selector");	# GMT,LT,ET
var clock_colon 	= props.globals.getNode("instrumentation/clock/colon");		# ":"
var clock_ctrl		= props.globals.getNode("instrumentation/clock/control");	# 0:nop 1:start/stop 2:reset
var clock_reset 	= 0;														# 

var sim_elapsed		= props.globals.getNode("sim/time/elapsed-sec"); 			# double like 196.233546
var et_state		= props.globals.getNode("instrumentation/clock/etstate");	# 0:stop/freeze 1:run
var et_elapsed	 	= 0;														# ET counter

digits = {};
for ( var i=0; i<num_mode; i=i+1) {
#				 H H M M
	digits[i] = [0,0,0,0];
}

updateGMT = func() {
	var timeString = props.globals.getNode("sim/time/gmt-string").getValue();
	digits[0][0] = int(utf8.chstr(timeString[0]));	# H
	digits[0][1] = int(utf8.chstr(timeString[1]));	# H
	digits[0][2] = int(utf8.chstr(timeString[3]));	# M
	digits[0][3] = int(utf8.chstr(timeString[4]));	# M
}

updateLT = func() {
	var timeString = props.globals.getNode("instrumentation/clock/local-short-string").getValue();
	digits[1][0] = int(utf8.chstr(timeString[0]));	# H
	digits[1][1] = int(utf8.chstr(timeString[1]));	# H
	digits[1][2] = int(utf8.chstr(timeString[3]));	# M
	digits[1][3] = int(utf8.chstr(timeString[4]));	# M
}

var timerET = maketimer(1.0, func () {
	et_elapsed = et_elapsed + 1;	
});

updateET = func() {
	var control = clock_ctrl.getValue();
	var state 	= et_state.getBoolValue();
	var hh = mm = ss = 0;
	
	if ( control == 1 )	{
		#print("updateET(): control 1");
		clock_reset = 4;
		if ( !state ) {
			timerET.start();
			et_state.setBoolValue(1);
		} else {
			timerET.stop();
			et_state.setBoolValue(0);
		}
	} elsif ( control == 2 ) {
		#print("updateET(): control 2");
		clock_reset = 4;
		et_elapsed = 0;
		et_state.setBoolValue(0);
		if ( timerET.isRunning )
			timerET.stop();
	}
	
	mm = int(et_elapsed / 60);
	ss = math.mod(et_elapsed,60);
	hh = int(mm/60);

	if ( mm > 99 ) { 
		#print("updateET(): MM > 99");
		mm = math.mod(mm,60);
		digits[2][0] = int(hh / 10);
		digits[2][1] = math.mod(hh,10);
		digits[2][2] = int(mm / 10);
		digits[2][3] = math.mod(mm,10);
	} else {
		#print("updateET(): MM < 99");
		digits[2][0] = int(mm / 10);
		digits[2][1] = math.mod(mm,10);
		digits[2][2] = int(ss / 10);
		digits[2][3] = math.mod(ss,10);
	}
}

updateModeFunc = [ updateGMT, updateLT, updateET ];

updateClockDigit = func(mode) {
	updateModeFunc[mode]();								# call update func according to selected mode
	for ( var i=0; i<num_digit; i=i+1) {				# update clock digit from selected mode
		props.globals.getNode("instrumentation/clock/digit["~i~"]").setValue(digits[mode][i]);
	}
}

updateClock = func() {
	clock_colon.setValue(!clock_colon.getBoolValue());	# update colon ':' blink
	# CTL
	if ( clock_reset == 4 ) {							# 2 seconds elapsed
		clock_ctrl.setValue(0);							# reset ctrl
		clock_reset = 0;								# reset countdown
	}
	if ( clock_ctrl.getValue() != 0)					# user has pushed ctl
		clock_reset = clock_reset + 1;					# start countdown before reset 
	# Update
	updateClockDigit(clock_mode.getValue());			# update our digit array
}

# ------------------------------------------------------------------------------------------------------
# Thread Func.
# ------------------------------------------------------------------------------------------------------
var timerClock = maketimer(0.5, func () {
	updateClock();
});

var init = func() {
	timerClock.start();
}

setlistener("/sim/signals/fdm-initialized", init );
