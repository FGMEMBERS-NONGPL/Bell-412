# ======================================================================================================
# Bell412 Dual Control 
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
# 	DualControlTools
#
# NOTES
# I tried many things in order to reduce controls latency, but it didn't work with DCT. Helicopters 
# needs # accurate syncing btw pilot & copilot.
# So, pilot must say who is mastering the chopper (dual-control/flight/master). 
# Then, we sync pilot & copilot command according to who was master, then we copy everything
# do controls/dual-control/ which is read by our AFCS. 
# We use DCT for others values.
# Pilot side  is responsible of the timer life and syncing process.
#
# CHANGELOG
# 11/2017	: init
# 12/2017	: switches xchange, timers p & c
# ======================================================================================================
var DCT = dual_control_tools;

# Pilot/copilot aircraft identifiers.
var pilot_type   = "Aircraft/Bell-412/Models/Bell-412.xml";
var copilot_type = "Aircraft/Bell-412/Models/Bell-412-cop.xml";

var elevator	 		= "controls/flight/elevator";
var aileron				= "controls/flight/aileron";
var rudder 				= "controls/flight/rudder";
var elevator_t 			= "controls/flight/elevator-trim";
var aileron_t			= "controls/flight/aileron-trim";
var rudder_t 			= "controls/flight/rudder-trim";
var throttle			= "controls/engines/engine[0]/throttle";

# Master/Pilot MP
var pilot_connected		= "sim/multiplay/generic/int[13]";
var servos_elevator 	= "sim/multiplay/generic/float[13]";
var servos_aileron		= "sim/multiplay/generic/float[14]";
var servos_rudder 		= "sim/multiplay/generic/float[15]";
var servos_elevator_t 	= "sim/multiplay/generic/float[16]";
var servos_aileron_t	= "sim/multiplay/generic/float[17]";
var servos_rudder_t 	= "sim/multiplay/generic/float[18]";
var pilot_throttle		= "sim/multiplay/generic/float[19]";
var pilot_dual_master	= "sim/multiplay/generic/int[14]";
var pilot_dual_linked	= "sim/multiplay/generic/int[15]";
var pilot_elevator 		= "sim/multiplay/generic/float[20]";
var pilot_aileron		= "sim/multiplay/generic/float[21]";
var pilot_rudder 		= "sim/multiplay/generic/float[22]";
var pilot_elevator_t 	= "sim/multiplay/generic/float[23]";
var pilot_aileron_t		= "sim/multiplay/generic/float[24]";
var pilot_rudder_t 		= "sim/multiplay/generic/float[25]";
var pilot_pilotlt 		= "sim/multiplay/generic/float[26]";
var pilot_copilotlt 	= "sim/multiplay/generic/float[27]";
var pilot_conslt 		= "sim/multiplay/generic/float[28]";
var pilot_cautionlt 	= "sim/multiplay/generic/float[29]";
var pilot_airspeed		= "sim/multiplay/generic/float[6]";
var pilot_alt			= "sim/multiplay/generic/float[7]";
var pilot_vspeed		= "sim/multiplay/generic/float[8]";
var pilot_e1n1			= "sim/multiplay/generic/float[9]";
var pilot_e1n2			= "sim/multiplay/generic/float[30]";
var pilot_e2n1			= "sim/multiplay/generic/float[31]";
var pilot_e2n2			= "sim/multiplay/generic/float[32]";
var pilot_e1fuelpress	= "sim/multiplay/generic/float[33]";
var pilot_e2fuelpress	= "sim/multiplay/generic/float[34]";
var pilot_nr			= "sim/multiplay/generic/float[35]";
var pilot_torque		= "sim/multiplay/generic/float[36]";
var pilot_aipitch		= "sim/multiplay/generic/float[37]";
var pilot_airoll		= "sim/multiplay/generic/float[38]";

# Copilot MP /ai/models/multiplayer/
var copilot_connected	= "sim/multiplay/generic/int[1]";
var copilot_synced		= "sim/multiplay/generic/int[2]";
var copilot_elevator 	= "sim/multiplay/generic/float[0]";
var copilot_aileron		= "sim/multiplay/generic/float[1]";
var copilot_rudder 		= "sim/multiplay/generic/float[2]";
var copilot_elevator_t	= "sim/multiplay/generic/float[3]";
var copilot_aileron_t	= "sim/multiplay/generic/float[4]";
var copilot_rudder_t 	= "sim/multiplay/generic/float[5]";
var copilot_throttle	= "sim/multiplay/generic/float[6]";
# Dual
var dual_linked			= "/controls/dual-control/linked";
var dual_master	 		= "/controls/dual-control/flight/master";
var dual_elevator	 	= "/controls/dual-control/flight/elevator";
var dual_aileron		= "/controls/dual-control/flight/aileron";
var dual_rudder 		= "/controls/dual-control/flight/rudder";
var dual_elevator_t 	= "/controls/dual-control/flight/elevator-trim";
var dual_aileron_t		= "/controls/dual-control/flight/aileron-trim";
var dual_rudder_t 		= "/controls/dual-control/flight/rudder-trim";
var dual_throttle		= "/controls/dual-control/flight/throttle";

# MP switches properties
var sw_set1				= [
"controls/power/switches/bus1",				#0
"controls/power/switches/bus2",
"controls/power/switches/inv1",
"controls/power/switches/inv2",
"controls/power/switches/gen1",
"controls/power/switches/gen2",
"controls/power/switches/busne",
"controls/power/switches/emergency",
"controls/consoles/switches/bat1",
"controls/consoles/switches/bat2",
"controls/fuel/intcon",						#10
"controls/fuel/xfeed",
"controls/fuel/engine[0]/trans",
"controls/fuel/engine[0]/pump",
"controls/fuel/engine[0]/valve",
"controls/fuel/engine[1]/trans",
"controls/fuel/engine[1]/pump",
"controls/fuel/engine[1]/valve",
"controls/fuel/qtyselector",
"controls/engines/engine[0]/starter",
"controls/engines/engine[0]/gov",			#20
"controls/engines/engine[0]/partsep",
"controls/engines/engine[0]/hydr",
"controls/engines/engine[1]/starter",
"controls/engines/engine[1]/gov",
"controls/engines/engine[1]/partsep",
"controls/engines/engine[1]/hydr",
"controls/flight/afcs/ap1",
"controls/flight/afcs/ap2",					#28
];

var sw_set2				= [
"controls/sound/switch",					#0
"controls/sound/button",
"controls/sound/powerup",
"controls/sound/engine_s1",
"controls/sound/engine_s2",
"controls/sound/engine_s3",
"controls/sound/engine_s4",
"controls/sound/headset",
"controls/sound/headset-cop",				#8
];

var sw_set3				= [
"instrumentation/cautions/powered",			#0
"instrumentation/cautions/master",
"instrumentation/cautions/cycctr",
"instrumentation/cautions/rpm",
"instrumentation/cautions/overtorque",
"instrumentation/cautions/battery",
"instrumentation/cautions/rotorbrake",
"instrumentation/cautions/doorlock",
"instrumentation/cautions/externalpower",
"instrumentation/cautions/fuellow",
"instrumentation/cautions/genovht[0]",		#10
"instrumentation/cautions/genovht[1]",
"instrumentation/cautions/outstate[0]",
"instrumentation/cautions/outstate[1]",
"instrumentation/cautions/inverter[0]",
"instrumentation/cautions/inverter[1]",		#15
"instrumentation/cautions/dcgenerator[0]",
"instrumentation/cautions/dcgenerator[1]",
"instrumentation/cautions/fuelintcon",
"instrumentation/cautions/fuelxfeed",
"instrumentation/cautions/enginechip[0]",	#20
"instrumentation/cautions/enginechip[1]",
"instrumentation/cautions/fueltrans[0]",
"instrumentation/cautions/fuelboost[0]",
"instrumentation/cautions/fuelvalve[0]",
"instrumentation/cautions/govmanual[0]",	#25
"instrumentation/cautions/partsepoff[0]",
"instrumentation/cautions/hydraulic[0]",
"instrumentation/cautions/oilpressure[0]",
"instrumentation/cautions/fueltrans[1]",
"instrumentation/cautions/fuelboost[1]",	#30 (Switch Encoder support only 31, not 32 because of signed int)
];

var sw_set4				= [
"instrumentation/cautions/fuelvalve[1]",	#0
"instrumentation/cautions/govmanual[1]",
"instrumentation/cautions/partsepoff[1]",
"instrumentation/cautions/hydraulic[1]",
"instrumentation/cautions/oilpressure[1]",
"instrumentation/cautions/cboxoilpressure",
"instrumentation/cautions/xmsnoilpressure",
"instrumentation/cautions/raltdh",
"instrumentation/cautions/afcs[0]",
"instrumentation/cautions/afcs[1]",
"instrumentation/afcs[0]/powered",			#10
"instrumentation/afcs[1]/powered",
"controls/flight/afcs/sasatt",
];

var sw_encoding1		= "sim/multiplay/generic/int[18]";
var sw_encoding2		= "sim/multiplay/generic/int[19]";
var sw_encoding3		= "sim/multiplay/generic/int[16]";
var sw_encoding4		= "sim/multiplay/generic/int[17]";

# -----------------------------------------------------------------------------
# Timer & MPP Syncing
# -----------------------------------------------------------------------------
#
var synced_p = 0;
var synced_c = props.globals.getNode(copilot_synced);
var pilot_mpp = {};
var copilot_mpp = {};
var timerStarted_p = 0;
var timerStarted_c = 0;

var sync_pilot = func () {
	print("[Bell-412] X sync_pilot");
	props.globals.getNode(elevator  ).setValue(props.globals.getNode(dual_elevator  ).getValue());
	props.globals.getNode(aileron   ).setValue(props.globals.getNode(dual_aileron   ).getValue());
	props.globals.getNode(rudder    ).setValue(props.globals.getNode(dual_rudder    ).getValue());
	props.globals.getNode(elevator_t).setValue(props.globals.getNode(dual_elevator_t).getValue());
	props.globals.getNode(aileron_t ).setValue(props.globals.getNode(dual_aileron_t ).getValue());
	props.globals.getNode(rudder_t  ).setValue(props.globals.getNode(dual_rudder_t  ).getValue());
	props.globals.getNode(throttle  ).setValue(props.globals.getNode(dual_throttle  ).getValue());
	print("[Bell-412] X pilot synced.");
	synced_p = 1;
}

var sync_copilot = func () {
	print("[Bell-412] X sync_copilot");
	props.globals.getNode(elevator  ).setValue(pilot_mpp.getNode(pilot_elevator  ).getValue());
	props.globals.getNode(aileron   ).setValue(pilot_mpp.getNode(pilot_aileron   ).getValue());
	props.globals.getNode(rudder    ).setValue(pilot_mpp.getNode(pilot_rudder    ).getValue());
	props.globals.getNode(elevator_t).setValue(pilot_mpp.getNode(pilot_elevator_t).getValue());
	props.globals.getNode(aileron_t ).setValue(pilot_mpp.getNode(pilot_aileron_t ).getValue());
	props.globals.getNode(rudder_t  ).setValue(pilot_mpp.getNode(pilot_rudder_t  ).getValue());
	props.globals.getNode(throttle  ).setValue(pilot_mpp.getNode(pilot_throttle  ).getValue());
	print("[Bell-412] X copilot synced.");
	synced_c.setBoolValue(1);
}

var update_p = func () {
	#print("[Bell-412] X dual control update():cop:"~ copilot_mpp.getNode(copilot_connected).getValue() );
	var linked = props.globals.getNode(dual_linked).getBoolValue();
	if ( linked ) {
		var master = props.globals.getNode(dual_master).getValue();
		if ( master==0 ) {
			if ( !synced_p ) sync_pilot();
			props.globals.getNode(dual_elevator  ).setValue(props.globals.getNode(elevator  ).getValue());
			props.globals.getNode(dual_aileron   ).setValue(props.globals.getNode(aileron   ).getValue());
			props.globals.getNode(dual_rudder    ).setValue(props.globals.getNode(rudder    ).getValue());
			props.globals.getNode(dual_elevator_t).setValue(props.globals.getNode(elevator_t).getValue());
			props.globals.getNode(dual_aileron_t ).setValue(props.globals.getNode(aileron_t ).getValue());
			props.globals.getNode(dual_rudder_t  ).setValue(props.globals.getNode(rudder_t  ).getValue());
			props.globals.getNode(dual_throttle  ).setValue(props.globals.getNode(throttle  ).getValue());
		} else { 
			synced_p = 0;
			if ( copilot_mpp.getNode(copilot_synced).getBoolValue() ) {
				props.globals.getNode(dual_elevator  ).setValue(copilot_mpp.getNode(copilot_elevator  ).getValue());
				props.globals.getNode(dual_aileron   ).setValue(copilot_mpp.getNode(copilot_aileron   ).getValue());
				props.globals.getNode(dual_rudder    ).setValue(copilot_mpp.getNode(copilot_rudder    ).getValue());
				props.globals.getNode(dual_elevator_t).setValue(copilot_mpp.getNode(copilot_elevator_t).getValue());
				props.globals.getNode(dual_aileron_t ).setValue(copilot_mpp.getNode(copilot_aileron_t ).getValue());
				props.globals.getNode(dual_rudder_t  ).setValue(copilot_mpp.getNode(copilot_rudder_t  ).getValue());
				props.globals.getNode(dual_throttle  ).setValue(copilot_mpp.getNode(copilot_throttle  ).getValue());
				props.globals.getNode(throttle       ).setValue(copilot_mpp.getNode(copilot_throttle  ).getValue());
			}
		}
	}
}

var update_c = func() {
	var linked = pilot_mpp.getNode(pilot_dual_linked).getBoolValue();
	if ( linked ) {
		var master = pilot_mpp.getNode(pilot_dual_master).getValue();
		if ( master == 1 ) {
			if ( !synced_c.getBoolValue() ) sync_copilot();
		} else
			synced_c.setBoolValue(0);
	}
}

var timerDual_p = maketimer(0.001, func () {
	update_p();
});

var timerDual_c = maketimer(0.001, func () {
	update_c();
});

# -----------------------------------------------------------------------------
# Pilot get/map Copilot data -- code run on pilot side
# -----------------------------------------------------------------------------
var pilot_connect_copilot = func (copilot) {
	copilot_mpp = copilot;		# save to global
	print("[Bell-412] X pilot_connect_copilot");
	props.globals.getNode(pilot_connected).setBoolValue(1);
	#var L_pilot_master = setlistener(dual_master, func { sync_pilot(); });
	if ( copilot.getNode(copilot_connected).getBoolValue() and !timerStarted_p ) {
		props.globals.getNode(dual_linked).setBoolValue(1);
		timerDual_p.start();
		timerStarted_p = 1;
	}

	return [
      	DCT.Translator.new(props.globals.getNode(pilot_connected), props.globals.getNode("/controls/dual-control/connection/crew[0]")),
      	DCT.Translator.new(copilot.getNode(copilot_connected), props.globals.getNode("/controls/dual-control/connection/crew[1]")),

    	DCT.SwitchEncoder.new(
			[props.globals.getNode(sw_set1[0]),
			 props.globals.getNode(sw_set1[1]),
			 props.globals.getNode(sw_set1[2]),
			 props.globals.getNode(sw_set1[3]),
			 props.globals.getNode(sw_set1[4]),
			 props.globals.getNode(sw_set1[5]),
			 props.globals.getNode(sw_set1[6]),
			 props.globals.getNode(sw_set1[7]),
			 props.globals.getNode(sw_set1[8]),
			 props.globals.getNode(sw_set1[9]),
			 props.globals.getNode(sw_set1[10]),
			 props.globals.getNode(sw_set1[11]),
			 props.globals.getNode(sw_set1[12]),
			 props.globals.getNode(sw_set1[13]),
			 props.globals.getNode(sw_set1[14]),
			 props.globals.getNode(sw_set1[15]),
			 props.globals.getNode(sw_set1[16]),
			 props.globals.getNode(sw_set1[17]),
			 props.globals.getNode(sw_set1[18]),
			 props.globals.getNode(sw_set1[19]),
			 props.globals.getNode(sw_set1[20]),
			 props.globals.getNode(sw_set1[21]),
			 props.globals.getNode(sw_set1[22]),
			 props.globals.getNode(sw_set1[23]),
			 props.globals.getNode(sw_set1[24]),
			 props.globals.getNode(sw_set1[25]),
			 props.globals.getNode(sw_set1[26]),
			 props.globals.getNode(sw_set1[27]),
			 props.globals.getNode(sw_set1[28]),
       		],
	   		props.globals.getNode(sw_encoding1)
		),

    	DCT.SwitchEncoder.new(
			[props.globals.getNode(sw_set2[0]),
			 props.globals.getNode(sw_set2[1]),
			 props.globals.getNode(sw_set2[2]),
			 props.globals.getNode(sw_set2[3]),
			 props.globals.getNode(sw_set2[4]),
			 props.globals.getNode(sw_set2[5]),
			 props.globals.getNode(sw_set2[6]),
			 props.globals.getNode(sw_set2[7]),
			 props.globals.getNode(sw_set2[8]),
       		],
	   		props.globals.getNode(sw_encoding2)
		),
    	
		DCT.SwitchEncoder.new(
			[props.globals.getNode(sw_set3[0]),
			 props.globals.getNode(sw_set3[1]),
			 props.globals.getNode(sw_set3[2]),
			 props.globals.getNode(sw_set3[3]),
			 props.globals.getNode(sw_set3[4]),
			 props.globals.getNode(sw_set3[5]),
			 props.globals.getNode(sw_set3[6]),
			 props.globals.getNode(sw_set3[7]),
			 props.globals.getNode(sw_set3[8]),
			 props.globals.getNode(sw_set3[9]),
			 props.globals.getNode(sw_set3[10]),
			 props.globals.getNode(sw_set3[11]),
			 props.globals.getNode(sw_set3[12]),
			 props.globals.getNode(sw_set3[13]),
			 props.globals.getNode(sw_set3[14]),
			 props.globals.getNode(sw_set3[15]),
			 props.globals.getNode(sw_set3[16]),
			 props.globals.getNode(sw_set3[17]),
			 props.globals.getNode(sw_set3[18]),
			 props.globals.getNode(sw_set3[19]),
			 props.globals.getNode(sw_set3[20]),
			 props.globals.getNode(sw_set3[21]),
			 props.globals.getNode(sw_set3[22]),
			 props.globals.getNode(sw_set3[23]),
			 props.globals.getNode(sw_set3[24]),
			 props.globals.getNode(sw_set3[25]),
			 props.globals.getNode(sw_set3[26]),
			 props.globals.getNode(sw_set3[27]),
			 props.globals.getNode(sw_set3[28]),
			 props.globals.getNode(sw_set3[29]),
			 props.globals.getNode(sw_set3[30]),
       		],
	   		props.globals.getNode(sw_encoding3)
		),
		
		DCT.SwitchEncoder.new(
			[props.globals.getNode(sw_set4[0]),
			 props.globals.getNode(sw_set4[1]),
			 props.globals.getNode(sw_set4[2]),
			 props.globals.getNode(sw_set4[3]),
			 props.globals.getNode(sw_set4[4]),
			 props.globals.getNode(sw_set4[5]),
			 props.globals.getNode(sw_set4[6]),
			 props.globals.getNode(sw_set4[7]),
			 props.globals.getNode(sw_set4[8]),
			 props.globals.getNode(sw_set4[9]),
			 props.globals.getNode(sw_set4[10]),
			 props.globals.getNode(sw_set4[11]),
			 props.globals.getNode(sw_set4[12]),
       		],
	   		props.globals.getNode(sw_encoding4)
		),

		DCT.SwitchDecoder.new( 
			copilot.getNode(sw_encoding1),
       		[	
				func (b) { props.globals.getNode(sw_set1[0]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[1]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[2]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[3]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[4]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[5]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[6]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[7]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[8]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[9]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[10]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[11]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[12]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[13]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[14]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[15]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[16]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[17]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[18]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[19]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[20]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[21]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[22]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[23]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[24]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[25]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[26]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[27]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set1[28]).setBoolValue(b?1:0); },
			]),
		
		DCT.SwitchDecoder.new( 
			copilot.getNode(sw_encoding2),
       		[	
				func (b) { props.globals.getNode(sw_set2[0]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set2[1]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set2[2]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set2[3]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set2[4]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set2[5]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set2[6]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set2[7]).setBoolValue(b?1:0); },
				func (b) { props.globals.getNode(sw_set2[8]).setBoolValue(b?1:0); },
			]),
	];
}

var pilot_disconnect_copilot = func {
	props.globals.getNode(pilot_connected).setBoolValue(0);
	props.globals.getNode(dual_linked).setBoolValue(0);
	if ( timerStarted_p ) {
		timerDual_p.stop();
		timerStarted_p = 0;
	}
	print("[Bell-412] X pilot_disconnect_copilot");
}

# -----------------------------------------------------------------------------
# Copilot get/map Pilot data -- this code run on the copilot side.
# -----------------------------------------------------------------------------
var copilot_connect_pilot = func (pilot) {
	pilot_mpp = pilot;		# save to global
	print("[Bell-412] X copilot_connect_copilot");
	props.globals.getNode(copilot_connected).setBoolValue(1);
	if ( !timerStarted_c ) {
		timerDual_c.start();
		timerStarted_c = 1;
	}
	
	# Cast ..
	for ( var i=0; i<size(sw_set1); i=i+1) {
		pilot.initNode(sw_set1[i], 0, "BOOL");
	}
	for ( i=0; i<size(sw_set2); i=i+1) {
		pilot.initNode(sw_set2[i], 0, "BOOL");
	}
	# .. Anim
	pilot.initNode("controls/flight/servos/pitch", 0, "DOUBLE");
	pilot.initNode("controls/flight/servos/roll", 0, "DOUBLE");
	pilot.initNode("controls/flight/servos/yaw", 0, "DOUBLE");
	pilot.initNode("controls/flight/servos/pitch-trim", 0, "DOUBLE");
	pilot.initNode("controls/flight/servos/roll-trim", 0, "DOUBLE");
	pilot.initNode("controls/flight/servos/yaw-trim", 0, "DOUBLE");
	# .. HUD
	props.globals.initNode("controls/flight/servos/pitch", 0, "DOUBLE");
	props.globals.initNode("controls/flight/servos/roll", 0, "DOUBLE");
	props.globals.initNode("controls/flight/servos/yaw", 0, "DOUBLE");
	props.globals.initNode("controls/flight/servos/pitch-trim", 0, "DOUBLE");
	props.globals.initNode("controls/flight/servos/roll-trim", 0, "DOUBLE");
	props.globals.initNode("controls/flight/servos/yaw-trim", 0, "DOUBLE");
	return [
		# Dual Master
		DCT.Translator.new(pilot.getNode(pilot_dual_master),props.globals.getNode("/sim/remote/master")),
		# Local Animation - from multiplay to ai/models/multiplayer[x]/...
      	DCT.Translator.new(pilot.getNode(servos_elevator), 	pilot.getNode("controls/flight/servos/pitch")),
      	DCT.Translator.new(pilot.getNode(servos_aileron),	pilot.getNode("controls/flight/servos/roll")),
      	DCT.Translator.new(pilot.getNode(servos_rudder),	pilot.getNode("controls/flight/servos/yaw")),
      	DCT.Translator.new(pilot.getNode(servos_elevator_t),pilot.getNode("controls/flight/servos/pitch-trim",1)),
      	DCT.Translator.new(pilot.getNode(servos_aileron_t),	pilot.getNode("controls/flight/servos/roll-trim",1)),
      	DCT.Translator.new(pilot.getNode(servos_rudder_t),	pilot.getNode("controls/flight/servos/yaw-trim",1)),
      	DCT.Translator.new(pilot.getNode(pilot_throttle), 	pilot.getNode(throttle, 1)),
      	# HUD Need these
		DCT.Translator.new(pilot.getNode(servos_elevator), 	props.globals.getNode("controls/flight/servos/pitch")),
      	DCT.Translator.new(pilot.getNode(servos_aileron),	props.globals.getNode("controls/flight/servos/roll")),
      	DCT.Translator.new(pilot.getNode(servos_rudder),	props.globals.getNode("controls/flight/servos/yaw")),
      	DCT.Translator.new(pilot.getNode(servos_elevator_t),props.globals.getNode("controls/flight/servos/pitch-trim",1)),
      	DCT.Translator.new(pilot.getNode(servos_aileron_t),	props.globals.getNode("controls/flight/servos/roll-trim",1)),
      	DCT.Translator.new(pilot.getNode(servos_rudder_t),	props.globals.getNode("controls/flight/servos/yaw-trim",1)),
      	# Instruments Lightings
      	DCT.Translator.new(pilot.getNode(pilot_pilotlt),	pilot.getNode("bell412/electrical/output/lights/pilotlt",1)),
      	DCT.Translator.new(pilot.getNode(pilot_copilotlt),	pilot.getNode("bell412/electrical/output/lights/copilotlt",1)),
      	DCT.Translator.new(pilot.getNode(pilot_conslt),		pilot.getNode("bell412/electrical/output/lights/conslt",1)),
      	DCT.Translator.new(pilot.getNode(pilot_cautionlt),	pilot.getNode("bell412/electrical/output/lights/cautionlt",1)),
		# Instrumentation
   		DCT.Translator.new(pilot.getNode(pilot_airspeed		),pilot.getNode("instrumentation/airspeed-indicator/indicated-speed-kt",1)),
        DCT.Translator.new(pilot.getNode(pilot_alt			),pilot.getNode("instrumentation/altimeter/indicated-altitude-ft",1)),
        DCT.Translator.new(pilot.getNode(pilot_vspeed		),pilot.getNode("instrumentation/vertical-speed-indicator/indicated-speed-fpm",1)),
        DCT.Translator.new(pilot.getNode(pilot_e1n1			),pilot.getNode("bell412/mechanics/engines/engine[0]/n1",1)),
        DCT.Translator.new(pilot.getNode(pilot_e1n2			),pilot.getNode("bell412/mechanics/engines/engine[0]/n2",1)),
        DCT.Translator.new(pilot.getNode(pilot_e2n1			),pilot.getNode("bell412/mechanics/engines/engine[1]/n1",1)),
        DCT.Translator.new(pilot.getNode(pilot_e2n2			),pilot.getNode("bell412/mechanics/engines/engine[1]/n2",1)),
        DCT.Translator.new(pilot.getNode(pilot_e1fuelpress	),pilot.getNode("bell412/mechanics/engines/engine[0]/fuelpress",1)),
        DCT.Translator.new(pilot.getNode(pilot_e2fuelpress	),pilot.getNode("bell412/mechanics/engines/engine[1]/fuelpress",1)),
        DCT.Translator.new(pilot.getNode(pilot_nr			),pilot.getNode("bell412/mechanics/engines/nr",1)),
        DCT.Translator.new(pilot.getNode(pilot_torque		),pilot.getNode("bell412/mechanics/engines/torquepct",1)),
        DCT.Translator.new(pilot.getNode(pilot_aipitch		),pilot.getNode("instrumentation/ai/indicated-roll-deg",1)),
        DCT.Translator.new(pilot.getNode(pilot_airoll		),pilot.getNode("instrumentation/ai/indicated-pitch-deg",1)),

   		# TODO does Nasal support metaprog or smthg ? 
		DCT.SwitchDecoder.new( 
			pilot.getNode(sw_encoding1),
       		[	
				func (b) { pilot.getNode(sw_set1[0]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[1]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[2]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[3]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[4]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[5]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[6]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[7]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[8]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[9]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[10]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[11]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[12]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[13]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[14]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[15]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[16]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[17]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[18]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[19]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[20]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[21]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[22]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[23]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[24]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[25]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[26]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[27]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set1[28]).setBoolValue(b?1:0); },
			]
		),
		DCT.SwitchDecoder.new( 
			pilot.getNode(sw_encoding2),
       		[	
				func (b) { pilot.getNode(sw_set2[0]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set2[1]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set2[2]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set2[3]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set2[4]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set2[5]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set2[6]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set2[7]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set2[8]).setBoolValue(b?1:0); },
			]
		),
		DCT.SwitchDecoder.new( 
			pilot.getNode(sw_encoding3),
       		[	
				func (b) { pilot.getNode(sw_set3[0]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[1]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[2]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[3]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[4]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[5]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[6]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[7]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[8]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[9]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[10]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[11]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[12]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[13]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[14]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[15]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[16]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[17]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[18]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[19]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[20]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[21]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[22]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[23]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[24]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[25]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[26]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[27]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[28]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[29]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set3[30]).setBoolValue(b?1:0); },
			]
		),
		DCT.SwitchDecoder.new( 
			pilot.getNode(sw_encoding4),
       		[	
				func (b) { pilot.getNode(sw_set4[0]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set4[1]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set4[2]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set4[3]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set4[4]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set4[5]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set4[6]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set4[7]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set4[8]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set4[9]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set4[10]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set4[11]).setBoolValue(b?1:0); },
				func (b) { pilot.getNode(sw_set4[12]).setBoolValue(b?1:0); },
			]
		),

		DCT.SwitchEncoder.new(
			[pilot.getNode(sw_set1[0]),
			 pilot.getNode(sw_set1[1]),
			 pilot.getNode(sw_set1[2]),
			 pilot.getNode(sw_set1[3]),
			 pilot.getNode(sw_set1[4]),
			 pilot.getNode(sw_set1[5]),
			 pilot.getNode(sw_set1[6]),
			 pilot.getNode(sw_set1[7]),
			 pilot.getNode(sw_set1[8]),
			 pilot.getNode(sw_set1[9]),
			 pilot.getNode(sw_set1[10]),
			 pilot.getNode(sw_set1[11]),
			 pilot.getNode(sw_set1[12]),
			 pilot.getNode(sw_set1[13]),
			 pilot.getNode(sw_set1[14]),
			 pilot.getNode(sw_set1[15]),
			 pilot.getNode(sw_set1[16]),
			 pilot.getNode(sw_set1[17]),
			 pilot.getNode(sw_set1[18]),
			 pilot.getNode(sw_set1[19]),
			 pilot.getNode(sw_set1[20]),
			 pilot.getNode(sw_set1[21]),
			 pilot.getNode(sw_set1[22]),
			 pilot.getNode(sw_set1[23]),
			 pilot.getNode(sw_set1[24]),
			 pilot.getNode(sw_set1[25]),
			 pilot.getNode(sw_set1[26]),
			 pilot.getNode(sw_set1[27]),
			 pilot.getNode(sw_set1[28]),
       		],
	   		props.globals.getNode(sw_encoding1)
		),
		DCT.SwitchEncoder.new(
			[pilot.getNode(sw_set2[0]),
			 pilot.getNode(sw_set2[1]),
			 pilot.getNode(sw_set2[2]),
			 pilot.getNode(sw_set2[3]),
			 pilot.getNode(sw_set2[4]),
			 pilot.getNode(sw_set2[5]),
			 pilot.getNode(sw_set2[6]),
			 pilot.getNode(sw_set2[7]),
			 pilot.getNode(sw_set2[8]),
       		],
	   		props.globals.getNode(sw_encoding2)
		),
	];
}

var copilot_disconnect_pilot = func {
	props.globals.getNode(copilot_connected).setBoolValue(0);
	if ( timerStarted_c ) {
		timerDual_c.stop();
		timerStarted_c = 0;
	}
	print("[Bell-412] X copilot_disconnect_copilot");
}
