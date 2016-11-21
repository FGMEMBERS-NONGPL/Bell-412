# ======================================================================================================
# Bell412 Electrical Power System 
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
# CHANGELOG
# 06/2016	: init
# 11/2016	: complete redesign using Nasal OO: event driven, avoid 'if then', remove timer() thread
# ======================================================================================================

# ------------------------------------------------------------------------------------------------------
# Const
# TODO: ext temp and OAT battery limits (see 412 manual)
# ------------------------------------------------------------------------------------------------------
var DCLOAD_NOMINAL = 27;	# 27V +/- 1 DC BUS
var ACLOAD_NOMINAL = 115;	# 115V AC BUS
var ACLOAD_MINIMUM = 104;
var ACLOAD_MAXIMUM = 122;
var AMPLOAD_NOMINAL = 60;	# 60A GEN
var AMPLOAD_MINIMUM = 0;	#
var AMPLOAD_MAXIMUM = 75;	# 75 to 150 ==> CAUTION


# ------------------------------------------------------------------------------------------------------
# Class
# ------------------------------------------------------------------------------------------------------
var Bus = {
    new: func(busnr) {
		var m = { parents:[Bus] };
		var swnr = busnr + 1;
		# pilot switches ------------------------------------------------------------------------
		m.sw_power 	= props.globals.getNode("/controls/power/switches/bus"~swnr);
		m.sw_inverter = props.globals.getNode("/controls/power/switches/inv"~swnr);
		m.sw_generator= props.globals.getNode("/controls/power/switches/gen"~swnr);
		# properties ----------------------------------------------------------------------------
		m.id 		= busnr;
		m.state  	= props.globals.getNode("/bell412/power/buses/bus["~busnr~"]/state");
		m.dcload	= props.globals.getNode("/bell412/power/buses/bus["~busnr~"]/dcload");
		m.acload	= props.globals.getNode("/bell412/power/buses/bus["~busnr~"]/acload");
		m.ampload	= props.globals.getNode("/bell412/power/buses/bus["~busnr~"]/ampload");
		
		print("[Bell-412] + Bus["~busnr~"]: initialized.");
        return m;
    },
	set_load: func(node,v,t) {
		interpolate(node,v,t);		# t sec to value
	},
	
	check: func() {
		# bus On/Off
		print("[Bell-412] > Bus["~me.id~"]: checking.");
		if ( me.sw_power.getBoolValue() ) {
			me.state.setBoolValue(1);
			me.set_load(me.dcload,DCLOAD_NOMINAL,1,1);
			if ( me.sw_inverter.getBoolValue() )
				me.set_load(me.acload,ACLOAD_NOMINAL,1);
			else
				me.set_load(me.acload, 0,1);
		} else {
			me.set_load(me.dcload,0,0.3);
			me.set_load(me.acload,0,0.3);
			me.set_load(me.state,0,0.3);
		}
	}
};

# buses instances
#var Bus0 = Bus.new(0);
#var Bus1 = Bus.new(1);
#
#var Buses = [];
#append(Buses,Bus0);
#append(Buses,Bus1);
#var buses_state = props.globals.getNode("/bell412/power/buses/state");

var PowerSystem = {
    new: func() {
		var m = { parents:[PowerSystem] };
		m.Buses = [];
		m.bus0 = Bus.new(0);
		m.bus1 = Bus.new(1);
		append(m.Buses,m.bus0);
		append(m.Buses,m.bus1);
		
		# Controls
		#  lights dimmer
		m.dimmer_conslt = props.globals.getNode("/controls/lighting/switches/conslt");
		m.dimmer_pilotlt = props.globals.getNode("/controls/lighting/switches/pilotlt");
		m.dimmer_pedlt = props.globals.getNode("/controls/lighting/switches/pedlt");
		#  switches
		m.sw_console = props.globals.getNode("/controls/consoles/switches/bat1");
		m.sw_beaconlt= props.globals.getNode("/controls/lighting/switches/beacon");
		# other
		m.console_state = props.globals.getNode("/bell412/power/output/consoles/state");

		# Properties
		m.state		= props.globals.getNode("/bell412/power/buses/state");						# power system state
		m.charge	= props.globals.getNode("/bell412/power/buses/charge");
		m.soundstate= props.globals.getNode("/bell412/power/buses/soundstate");

		print("[Bell-412] + PowerSystem: initialized.");
		return m;
	},

	printout: func(msg) {
		print("[Bell-412] > PowerSystem: "~msg);
	},
	
	set_load: func(node,v,t) {
		interpolate(node,v,t);		# t sec to value
	},

	buses_check: func(n) {
		me.Buses[n].check();
		#settimer(func { buses_update(n) }, 0.5);	# wait Buses[n].state to be set, then update/notify
		var timer = maketimer(0.5, bell412.Power, func() {
			me.buses_update(n);
		});
		timer.singleShot = 1;
		timer.start();
	},
	
	buses_update: func(n) {
		me.state.setBoolValue( me.Buses[0].state.getBoolValue() or me.Buses[1].state.getBoolValue() );
		var bstate = me.state.getValue();
		var estate = (bstate and me.Buses[n].sw_inverter.getBoolValue());		# engine AC powered
		# (un)release power output
		interpolate(me.soundstate,bstate,(1+bstate));
		setprop("/bell412/power/output/engines/engine[0]/state",estate);	# engine (un)powered with one inverter ON (VAC)
		setprop("/bell412/power/output/engines/engine[1]/state",estate);	# engine (un)powered with one inverter ON (VAC)
		setprop("/bell412/power/output/engines/state",bstate);				# TODO old value
		setprop("/bell412/power/output/cautions/state",bstate);				# cautions light (un)powered
		setprop("/bell412/power/output/cautions/test_mode",bstate);			# TODO old value
		setprop("/bell412/power/output/consoles/state",bstate);				# console instrument (un)powered
		me.console_check();													# notify
		iBell412.engines_check();											# notify (Nasal/bell412.nas)
	},
	
	console_check: func() {
		var cstate = me.console_state.getBoolValue() and me.sw_console.getBoolValue();
		setprop("/bell412/power/output/consoles/instruments",cstate);
		setprop("/bell412/power/output/consoles/conslt",cstate * me.dimmer_conslt.getValue());
		setprop("/bell412/power/output/consoles/pilotlt",cstate * me.dimmer_pilotlt.getValue());
		setprop("/bell412/power/output/consoles/pedlt",cstate * me.dimmer_pedlt.getValue());
	},

	# TODO : power management update_charge(), currently only animate during the 1st 3 starting stages
	get_startingPower: func() {
		# if !enoughCharge then return 0
		# else updateCharge(), animate.
		interpolate(me.Buses[0].dcload,17,1,22,5.5,DCLOAD_NOMINAL,8);
		interpolate(me.Buses[1].dcload,17,1,22,5.5,DCLOAD_NOMINAL,8);
		interpolate(me.Buses[1].acload,120,1,116,5.5,ACLOAD_NOMINAL,8);
	},
	
	set_allNominal: func(dt) {
		me.set_load(me.Buses[0].dcload,DCLOAD_NOMINAL,dt);
		me.set_load(me.Buses[1].dcload,DCLOAD_NOMINAL,dt);
		me.set_load(me.Buses[0].acload,ACLOAD_NOMINAL,dt);
		me.set_load(me.Buses[1].acload,ACLOAD_NOMINAL,dt);
	}
};

var Power = PowerSystem.new();

# ------------------------------------------------------------------------------------------------------
# Globals
# ------------------------------------------------------------------------------------------------------
var sw_beaconlt= props.globals.initNode("/controls/lighting/switches/beacon");
aircraft.light.new("/controls/lighting/beacon-state",[0.10, 1.2], sw_beaconlt);	# beacon flash light

# ------------------------------------------------------------------------------------------------------
# Functions or Entry Points
# ------------------------------------------------------------------------------------------------------
var buses_check = func(n) {
	Power.buses_check(n);
}

var buses_update = func(n) {
	Power.buses_update(n);
}

var console_check = func() {
	Power.console_check();
}

setlistener("/sim/signals/fdm-initialized", func {
	print("[Bell-412] * Electrical System: ready.");
});
