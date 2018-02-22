# ======================================================================================================
# Bell412 AFCS 
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
# 	Textron BHT-412 Rotorcraft Flight Manual (rev. 9/2002)
# 	Flightgear Nasal Wiki: http://wiki.flightgear.org/Category:Nasal
# 	Textron 212-PTM (Campbel 2013)
#
# CHANGELOG
# 07/2017	: init
# 11/2017	: full input/output + hydr check 
# 			  Tail Rotor Adjuster
# 01/2018	: force trim v0.1
# ======================================================================================================
#
# NOTES PERSO
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ======================================================================================================
# ------------------------------------------------------------------------------------------------------
# Const/Glo
# ------------------------------------------------------------------------------------------------------
var hydr0_power = props.globals.getNode("instrumentation/hydr[0]/powered");
var hydr1_power = props.globals.getNode("instrumentation/hydr[1]/powered");

# ------------------------------------------------------------------------------------------------------
# Classes
# ------------------------------------------------------------------------------------------------------
var Servos = {
	new: func() {
		var m = { parents:[Servos] };
		
		# Input Control
		m.pilot_pitch		= props.globals.getNode("/controls/flight/elevator");
		m.pilot_roll 		= props.globals.getNode("/controls/flight/aileron");
		m.pilot_yaw 		= props.globals.getNode("/controls/flight/rudder");
		m.pilot_pitch_t		= props.globals.getNode("/controls/flight/elevator-trim");
		m.pilot_roll_t 		= props.globals.getNode("/controls/flight/aileron-trim");
		m.pilot_yaw_t 		= props.globals.getNode("/controls/flight/rudder-trim");
		m.pilot_throttle	= props.globals.getNode("/controls/engines/engine[0]/throttle");
		
		m.dual_linked		= props.globals.getNode("/controls/dual-control/linked");
		m.dual_pitch		= props.globals.getNode("/controls/dual-control/flight/elevator");
		m.dual_roll 		= props.globals.getNode("/controls/dual-control/flight/aileron");
		m.dual_yaw 			= props.globals.getNode("/controls/dual-control/flight/rudder");
		m.dual_pitch_t		= props.globals.getNode("/controls/dual-control/flight/elevator-trim");
		m.dual_roll_t 		= props.globals.getNode("/controls/dual-control/flight/aileron-trim");
		m.dual_yaw_t 		= props.globals.getNode("/controls/dual-control/flight/rudder-trim");
		m.dual_throttle 	= props.globals.getNode("/controls/dual-control/flight/throttle");

		# Cyclic
		m.cyclic_damp_limit = props.globals.getNode("/bell412/afcs/gains/sas/cyclic-damp-limit");
		m.ubody_fps_max		=props.globals.getNode("/bell412/afcs/gains/sas/ubody-fps-max"); 
		m.forcetrim 		=props.globals.getNode("/controls/flight/cyclic/force-trim");
		m.ftrimSynced		= 0;

		# Output
		m.pitch 			= props.globals.getNode("/controls/flight/servos/pitch");
		m.roll 				= props.globals.getNode("/controls/flight/servos/roll");
		m.yaw 				= props.globals.getNode("/controls/flight/servos/yaw");
		m.pitch_t 			= props.globals.getNode("/controls/flight/servos/pitch-trim");
		m.roll_t 			= props.globals.getNode("/controls/flight/servos/roll-trim");
		m.yaw_t 			= props.globals.getNode("/controls/flight/servos/yaw-trim");
		
		print("[Bell-412] + Servos: initialized.");

		return m;
	},

	printout: func(msg) {
		print("[Bell-412] > Servos: "~msg);
	},

	# Force Trim
	reciprocalDampPower: func(v) {
		var hilim = me.cyclic_damp_limit.getValue();
		var uBodyFpsMax= me.ubody_fps_max.getValue();
		return ((hilim+1) - (hilim * (uBodyFpsMax + v) / 100));
	},

	update: func() {
		var hydr0 = hydr0_power.getBoolValue();	# TODO pressure
		var hydr1 = hydr1_power.getBoolValue();	# TODO pressure
		var linked = me.dual_linked.getBoolValue();
		var ftrim  = me.forcetrim.getBoolValue();
		var uBody = math.clamp(props.globals.getNode("velocities/uBody-fps").getValue(),0,50);
		var vBody = math.clamp(props.globals.getNode("velocities/vBody-fps").getValue(),0,50);
		var v = 0.0;

		#if ( hydr0 or hydr1 ) { TODO : AFCS update if hydr pressure OK
		if ( ! linked ) {
			var ipitch 	= me.pilot_pitch.getValue();
			var iroll  	= me.pilot_roll.getValue();
			var iyaw	= me.pilot_yaw.getValue();
			var ipitch_t= me.pilot_pitch_t.getValue();
			var iroll_t = me.pilot_roll_t.getValue();
			var iyaw_t	= me.pilot_yaw_t.getValue();
		} else {
			var ipitch 	= me.dual_pitch.getValue();
			var iroll  	= me.dual_roll.getValue();
			var iyaw	= me.dual_yaw.getValue();
			var ipitch_t= me.dual_pitch_t.getValue();
			var iroll_t = me.dual_roll_t.getValue();
			var iyaw_t	= me.dual_yaw_t.getValue();
		}
		# Trimmers
		me.pitch_t.setValue	( ipitch_t );
		me.roll_t.setValue	( iroll_t  );
		me.yaw_t.setValue	( iyaw_t   );
		
		# FORCE TRIM
		# when uBody increase, damp factor decrease so we have a stick more accurate arround its neutral position at low speed (50 ft/s max)
		# this gradient of force is more or less like to the Bell412's force trim electro-magnetic system.
		# here, when speed increase (until 50 ft/s), accuracy decrease, then over 50 ft/s we have a 'one to one' transfer (no damping).
		# formula: f(x) = power(|x|,reciprocalDampPower(uBody-fps))
		# for uBody[0..50] we have power[n..1] 
		# so pitch damping depends on cyclic position AND ground speed (uBody-fps).
		# hovering is easier this way, pilot can be very accurate.
		
		# 01/01/18 23:15 TODO : trim off ==> cyclic at pos ==> /controls/flight/aileron+elevator at the same previous position
		if ( ftrim ) {
			v = math.sgn(ipitch) * math.pow(math.abs(ipitch),me.reciprocalDampPower(math.abs(uBody))) - ipitch_t;
			if ( me.ftrimSynced )
				interpolate(me.cyclic_damp_limit,1,3);	# smoothly going back to neutral damp
			me.ftrimSynced = 0;
		} else {
			if ( ! me.ftrimSynced ) {
				# syncing cyclic from real servos position
				me.ftrimSynced = 1;
				me.cyclic_damp_limit.setValue(0);	# cancel damp
				me.pilot_pitch.setValue(me.pitch.getValue());
				me.pilot_roll.setValue(me.roll.getValue());
				v = me.pilot_pitch.getValue() - ipitch_t;
			} else
				v = ipitch - ipitch_t;
		}
		me.pitch.setValue(v);
		# we use uBodyFps for roll too, so we apply same damping factor. TODO : vBody must temporize output
		if ( ftrim ) {
			v = math.sgn(iroll) * math.pow(math.abs(iroll),me.reciprocalDampPower(math.abs(uBody))) - iroll_t;
		} else {
			v = iroll - iroll_t;
		}
		me.roll.setValue(v);

		me.yaw.setValue(iyaw);
	},
};

# spc : 32			0
# a-z : 97-122		1-26
# 0-9 : 48-57		29-38
# -.  : 45-46		27-28
var AL300 = {
	new: func() {
		var m = { parents:[AL300] };
		m.class_name = "AL300";
		m.msg_queue = [];
		m.msg_queue_idx = 0;
		
		m.dsp("--.--");;
		print("[Bell-412] + AL300: initialized.");
		return m;
	},

	printout: func(msg) {
		print("[Bell-412] > "~me.class_name~": "~msg);
	},

	dsp: func(s) {
		var offset = 0;
		s = string.lc(s);
		if ( size(s) > 5 )
			s = utf8.substr(0, 5);
		for ( var i=0; i<size(s); i=i+1 ) {
			c = int(s[i]);
			if ( c == 32 )
				offset = 32;
			elsif ( c == 45 or c == 46 ) 
				offset = 18;
			elsif ( c <=57 and c>=48 ) 
				offset = 19;
			elsif ( c <=122 and c>=97 )
				offset = 96;
			
			props.globals.getNode("instrumentation/al300/digit["~i~"]").setValue(c-offset);
		}
	},

	addMsgQueue: func(s) {
		append(me.msg_queue,s);
	},

	clearMsgQueue: func() {
		me.msg_queue = [];
		me.msg_queue_idx = 0;
	},

	displayMsgQueue: func() {
		var dt = 0.8;
		if ( size(me.msg_queue) != 0 ) {
			if ( me.msg_queue_idx < size(me.msg_queue) ) {
				me.dsp(me.msg_queue[me.msg_queue_idx]);
				var timer = maketimer(dt, bell412.al300, func() {
					me.displayMsgQueue();
				});
				timer.singleShot = 1;
				timer.start();
				me.msg_queue_idx += 1;
			} else
				me.clearMsgQueue();
		}
	},

	init: func() {
		append(me.msg_queue,"- - -");
		append(me.msg_queue," - - ");
		append(me.msg_queue,"- - -");
		append(me.msg_queue,"     ");
		append(me.msg_queue,"2LE 1");
		append(me.msg_queue,"2LE 2");
		append(me.msg_queue,"2LE 3");
		append(me.msg_queue,"1LE 1");
		append(me.msg_queue,"1LE 2");
		append(me.msg_queue,"1LE 3");
		append(me.msg_queue,"  END");
		append(me.msg_queue,"-----");
		me.displayMsgQueue();
	},
};

# ------------------------------------------------------------------------------------------------------
# Instances
# ------------------------------------------------------------------------------------------------------
var serv = Servos.new();

var al300 = AL300.new();

# ------------------------------------------------------------------------------------------------------
# Thread/Listener Func.
# ------------------------------------------------------------------------------------------------------
var update = func() {
	serv.update();
}

var alinit = func() {
	if ( props.globals.getNode("instrumentation/al300/serviceable").getBoolValue() )		# pty has changed, init on servicing only
		al300.init();
}

# Balance rudder-trim / rudder when TRA is disabled.
var yawBalance = func() {
	var tra = props.globals.getNode("/controls/flight/afcs/tra").getBoolValue();
	var ap1 = props.globals.getNode("instrumentation/afcs[0]/powered").getBoolValue();
	var ap2 = props.globals.getNode("instrumentation/afcs[1]/powered").getBoolValue();
	var rudder 		= props.globals.getNode("controls/flight/rudder");
	var rudder_t 	= props.globals.getNode("controls/flight/rudder-trim");
	if ( ap1 or ap2 ) {
		if ( ! tra ) {
			#print("[Bell-412] ! DEBUG: rudder/trim balance");
			var r = rudder.getValue();
			var rtrim = rudder_t.getValue();
			interpolate(rudder,r+rtrim,1);
			interpolate(rudder_t,0,1);
		} else
			interpolate(rudder,0,1);
	}
}

setlistener("/rotors/main/cone-deg", update );
setlistener("/instrumentation/al300/serviceable", alinit, 1, 0 );
setlistener("/controls/flight/afcs/tra", yawBalance, 1, 0 );
