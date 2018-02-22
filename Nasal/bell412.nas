# ======================================================================================================
# Bell412 Engine System 
# 	(for the Flightgear Flight Simulator)
# ------------------------------------------------------------------------------------------------------
#
# AUTHOR
# 	Valery Seys		valery@vslash.com
#
# COPYRIGHT
# 	Valery Seys, Paris /\
# 	no distribution allowed
# 	no commercial use
# 	please contact the author for any use or question, thank you.
# 	https://sourceforge.net/projects/bell-412/
#
# REFS
# 	Textron BHT-412 Rotorcraft Flight Manual (rev. 9/2002)
# 	Flightgear Nasal Wiki: http://wiki.flightgear.org/Category:Nasal
#	youtube: AgustaBell AB 412HP Engine Start-Up (PT6T-3D Twin Pac) _HD1080p [ YTref. zl51qoP4ZOQ ]
#	Helicopter Aerodynamic by Paul Cantrell
#
# CHANGELOG
# 06/2016	: init
# 11/2016	: complete redesign using Nasal OO
# 05/06/17	: anti jitter weight
# ======================================================================================================
#
# NOTES PERSO
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MAST: maximum available stem torque
# 		Couple de tige admissible maximale 
# SI:
# moment of force 	newton meter 	N·m
# surface tension 	newton per meter 	N/m
# 
# Torque (lb.in) = 63,025 x Power (HP) / Speed (RPM)
# Power (HP) = Torque (lb.in) x Speed (RPM) / 63,025
# Torque (N.m) = 9.5488 x Power (kW) / Speed (RPM)
# Power (kW) = Torque (N.m) x Speed (RPM) / 9.5488 
#
# PT6T power								: 1342kW
# Rotor RPM									: 324 
# C'BOX RPM									: 6603.12
# C'BOX kW 									: 671
# Turbine RPM								: 38100
# P&W PT6T : Engine-to-rotor gear ratio 	: 20.38:1 (RotorRPM/C'BOX RPM)
# Max Torque (N.m)							: 39494 @ 1340kW
# Max cont Power							: 828kW
# Max torque @cont power					: 24403
# Fuel Consumption							: 0.600 lb/hp/h (365 g/kW/h)
# Air mass flow: 							: 5.3 lb (2 kg)/second
# (https://mdmetric.com/tech/powercalc.htm)
# 
# Required Thrust = ( Weight x 2 ) / NrOfRotor
#
# starting state
#
#		0	1..4	5
#0		1	0	   	2		
#1..4	0	0		0		
#5		2	0		0
#
#0	no start
#1	alone
#2	twin mode
#
#me.Engine[n].state == 0 and Engine[other].state == 0
#	start(twin=off)
#
#Chopper
#	Rotorgear
#		nr
#		reltorque
#		rpm
#		Engines[]
#			Engine
#				n1
#				n2
#	Buses[]
#		Bus
#
#iBell412
#	Rotor
#		engine0
#		engine1
#	Power
#		bus0
#		bus1
#
# Chopper
# 		Engine
# 			Turbines[]
# 				Turbine1
# 				Turbine2
# 			Rotorgear
# 			GearBox
#
# 		Power
# 			Buses[]
# 				Bus1
# 				Bus2
# 			External
# 			Generators[]
# 				Gen1
# 				Gen2
#			Output
# 		
# 		Fuel
# 			Tanks[]
# 				Tank1
# 				Tank2
#
# 		Loads
# 			Passenger[]
# 			Weights[]
# Nasal & Pty Tree
# var w = props.globals.getNode("/bell412/weights");
#
# weights/
# 	antijitter/
# 		...
# 	test/
# 		...
# 
# debug.dump(bell412.weights.getValues());
# print("--");
# var t = bell412.weights.getValues()["test"]["max-lb"];
# print(t);
# 
# ==>
# { 	antijitter: { 'max-lb': 3000, 'weight-lb': 3000 }, 
# 	test: { 'max-lb': 50, 'weight-lb': 20 } 
# }
# --
# 30
# 
# 
# weights/
# 	weight n=0/
# 		<name>antijitter</name>
# 		...
# 	weight n=1/
# 		<name>test</name>
# 		...
# 
# debug.dump(bell412.weights.getValues());
# print("--");
# 
# t = bell412.weights.getValues()["weight"][0]["name"];
# print(t);
# 
# { weight: [	{ 'max-lb': 3000, 'weight-lb': 3000, name: 'Fake Anti Jitter' }, 
# 			{ 'max-lb': 2000, 'weight-lb': 2000, name: 'Test' }] 
# }
# --
# antijitter
#
# { antijitter: { 'max-lb': 3000, 'weight-lb': 3000 }, test: { 'max-lb': 50, 'weight-lb': 20 } }
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ------------------------------------------------------------------------------------------------------
# Globals
# ------------------------------------------------------------------------------------------------------
var rg_start = props.globals.getNode("controls/rotorgear/starter");					# rotorgear init
var rg_reltarget = props.globals.getNode("controls/rotorgear/reltarget");			# rotorgear target rel rpm
var rg_maxreltorque = props.globals.getNode("controls/rotorgear/maxreltorque");		# rotorgear
var yasim_rotor_rpm = props.globals.getNode("rotors/main/rpm");						# set by Yasim (?)
var engine_brake	= props.globals.getNode("controls/engines/brake");				# Rotorgear.update_nr() timer need this

var ANIM_DOORS_DT = 1;																# time to open/close doors

# ------------------------------------------------------------------------------------------------------
# Const (Bell412 Limitationss) 
# TODO : shared object limitations.nas at top of load order 21/07/17 07:28
# ------------------------------------------------------------------------------------------------------
var FUELPRESS_MINIMUM = 6;
var FUELPRESS_MAXIMUM = 35;
var FUELPRESS_NOMINAL = 12;
var HYDRPRESS_MINIMUM = 600;
var HYDRPRESS_NOMINAL = 1000;
var OILTEMP_DEFAULT = -50;			# lowest needle position
var OILTEMP_MINIMUM = 1;			# cannot start below this
var OILTEMP_MAXIMUM = 115;			# failure
var OILTEMP_NOMINAL = 30;			# preheat / tostart
var OILPRESS_MINIMUM = 40;			# psi
var OILPRESS_MAXIMUM = 115;
var OILPRESS_NOMINAL = 78;

var N1_MAX_OEI = 103.4;				# % (follw. instr. P/N 212-075-037-113)
var N1_MAX_TAKEOFF = 100.8;			# %
var N2_MINIMUM = 97;				# %
var N2_NOMINAL = 100;				# %
var N2_MAXIMUM = 104.5;				# % torque < 30%
var ITT_NOMINAL = 765;				# degC cont. op.
var ITT_MAX_TAKEOFF = 810;			# degC
var ITT_MAXIMUM = 1090;				# degC

var THROTTLE_START_MIN = 12;		# 12% minimum to start
var COLLECTIV_START_MAX = 0.9;		# 10% maxi

var ROTOR_MAX_RPM = 324;			# rpm
var ENGINE_POWER = 1340;			# kW
var ENGINE_MAX_CONT_POWER = 828; 	# kW
var ENGINE_MAX_TORQUE = 41000;		# N.m Max True 39494, Max@ContOp: 24403 -- 02/06/17 09:23 according to inertia tensor

# ------------------------------------------------------------------------------------------------------
# Functions stuff
# ------------------------------------------------------------------------------------------------------
var help_win = screen.window.new( 0, 0, 1, 5 );
help_win.fg = [1,1,1,1];

# Displaying info
var display_thrust = func(n) {
	help_win.write("EngineThrottle["~n~"]: "~iBell412.Rotor.Engines[n].sw_thrust.getValue());
}

var display_brake = func() {
	brake = props.globals.getNode("/controls/engines/brake");
	help_win.write("Engine Brake: "~brake.getValue());
}

var help_dev = screen.display.new(10,20);

var display_dev = func() {
	
	#help_dev.setcolor(0.4,1.0,0.0);
	help_dev.add("/controls/flight/elevator");
	help_dev.add("/controls/flight/rudder");
	help_dev.add("/bell412/mechanics/engines/nr");
}

var close_dev = func { help_dev.close(); }

# Engines stuff
# power/torque/rpm have a constant relationship as of:
var calc_power = func(torque,speed) {
	var power = (torque * speed / 9.549296) / 1000;
	return power;
}

var calc_torque = func(power,speed) {
	var torque = power * 9549.296 / speed;
	return torque
}

var calc_speed = func(power,torque) {
	var speed = power * 9549.296 / torque;
	return speed;
}

var rpm2rad = func(rpm) {
	return rpm * 0.10471975512;
}

var rad2rpm = func(omega) {
	return omega * 9.54929658548;
}


# ------------------------------------------------------------------------------------------------------
# Classes
# ------------------------------------------------------------------------------------------------------
# Turbine state:
#
var Turbine = {
	#          #    rpm      kW         m        %            %           %        l/kW 
	new: func(_num, _maxrpm, _maxpower, _maxalt, _n1_lowIdle, _n1_hiIdle, _n1_max, _fuelflow) {
        var m = { parents:[Turbine] };
		# init
		m.number = _num;
		m.maxrpm = _maxrpm;
		m.maxpower = _maxpower;
		m.maxtorque = calc_torque(_maxpower,_maxrpm); # (power/omega) * _rho0 / Atmosphere::getStdDensity(alt);
		m.maxalt = _maxalt;
		m.n1_lowIdle = _n1_lowIdle;
		m.n1_hiIdle = _n1_hiIdle;
		m.n1_max = _n1_max;
		m.n1_target = m.n1_lowIdle;
		m.n1_min 	= m.n1_lowIdle;
		m.n1 		= m.n1_lowIdle;
		m.rho0 = 1.2133; 				# athmosphere at 0 alt TODO
		m.rho = m.rho0;
		m.omega = 0;					# angular speed
		m.torque = 0;
		#m.maxtorque = ( m.maxpower / rpm2rad(m.maxrpm) ); #* m.rho0 / 0.413; # getStdDensity(max.alt)

		m.fuelflow = _fuelflow;
		
		# controls
		m.sw_start 	= props.globals.getNode("controls/engines/engine["~_num~"]/starter");				# n1 start to idle
		#m.sw_stop  	= props.globals.getNode("/controls/engines/engine["~_num~"]/stop");				# idle stop (gas < 3% ) TODO
		m.sw_thrust = props.globals.getNode("controls/engines/engine["~_num~"]/thrust");				# gas throttle
		m.masttorque_pct = props.globals.getNode("bell412/mechanics/engines/torquepct");				# mast torque instrument
	
		# output
		m.out_n1_speed = props.globals.getNode("bell412/mechanics/turbine/rpm");
		m.out_torque = props.globals.getNode("bell412/mechanics/turbine/torque");
		m.out_n1 = props.globals.getNode("bell412/mechanics/turbine/n1");
		m.out_power = props.globals.getNode("bell412/mechanics/turbine/power");
		m.out_omega = props.globals.getNode("bell412/mechanics/turbine/omega");
		
		m.state = 0;	# stop, n1_idle, start, running
		print("[Bell-412] + Turbine["~_num~"]: initialized (power: "~m.maxpower~", rpm: "~m.maxrpm~", maxtorque: "~m.maxtorque~", rho0: "~m.rho0);
		return m;
	},
	
	getAirDensity: func(alt) { # TODO ARDC Model
		return 1.2133;		# alt 0
	},

	update_fuel: func() {
		 # _bsfc * _torque 
	},

	update_n1: func(thrust,rotorTorque) {
		# set speed(thrust)
		# set torque(speed,rotorTorque)
		# update_n2(speed);
		torque = _throttle * _maxTorque * (_rho / _rho0);
		power = torque * omega;
	},

	update_torque: func() {
		var g = me.sw_thrust.getValue();
		var t = me.torquepct.getValue();
		me.update_n1(g,t);
	},

	start: func() {
		me.state = 1;	# n1 idle
	},

	update: func() {
		if ( me.state == 0 ) {				# not running
			if ( me.sw_start.getBoolValue() )
				me.start();
		} 
		else if ( me.state == 3 ) { 		# running
			me.update_torque();
		}
	},

	calc: func(alt,omega) {	
		if ( omega == 0.0 ) 
			omega = 0.001;
		me.omega = omega;
		me.out_omega.setValue(me.omega);

		var thrust = me.sw_thrust.getValue() / 100; # 0..1

		me.n1_min = me.n1_lowIdle + ( me.n1_hiIdle - me.n1_lowIdle ) * ( thrust + 0.001 ); # thrust <=> lever
		me.rho = me.getAirDensity(alt);
		var torque = thrust * me.maxtorque * (me.rho / me.rho0);
		me.out_power.setValue(torque * omega);
		var frac = torque / ( me.maxtorque * ( me.rho / me.rho0 ) );
		me.n1_target = me.n1_min + ( me.n1_max - me.n1_min ) * frac;
		print("DEBUG: Turbine.calc(): omega: "~omega~", torque: "~torque~", power: "~me.out_power.getValue()~", n1_target: "~me.n1_target);
	},

	calc_n1: func(dt) {				# integrate
		var DECAY = 1.15;
		me.n1 = ( me.n1 + dt * DECAY * me.n1_target ) / ( 1 + dt * DECAY);
		me.out_n1.setValue(me.n1);
		me.calc_torque();
	},
	
	calc_torque: func() {
		var frac = ( me.n1 - me.n1_min ) / ( me.n1_max - me.n1_min);
		me.torque = frac * me.maxtorque * ( me.rho / me.rho0 );
		me.out_torque.setValue(me.torque);
		print("DEBUG: Turbine.calc_torque(): frac: "~frac~", torque: "~me.torque);
	},

	update: func(dt) { # see propEngine.cpp
		var moment = 1;	# don't have a moment for this turbine.
		var gearRatio = 20.38;

		me.calc(0,me.omega);
		me.calc_n1(dt); 				# calc torque as well
		moment = moment * gearRatio;	# gearRatio = ratio engine to gear
		#var rotacc = me.torque / math.abs(moment);  #TODO
		var rotacc = 1 / me.torque;
		me.omega += dt * rotacc;
		if ( me.omega < 0 )
			me.omega = 0 - me.omega;

		print("DEBUG: Turbine.update(): rotacc: "~rotacc~", omega: "~me.omega);
	},
};

# N2 RPM: 38100 CBOX RPM: 6600, kW 671
#zTurbine = Turbine.new(0,6600,671,10000,40,70,103,0.001);






var Engine = {
    new: func(engNum) {
        var m = { parents:[Engine] };
		m.id = engNum;
		m.twin = !engNum;	# my bro
		m.twinmode = 0;		# how i'm starting
		m.sw_trans 	= props.globals.getNode("/controls/fuel/engine["~engNum~"]/trans");
		m.sw_pump  	= props.globals.getNode("/controls/fuel/engine["~engNum~"]/pump");
		m.sw_valve 	= props.globals.getNode("/controls/fuel/engine["~engNum~"]/valve");
		m.sw_hydr 	= props.globals.getNode("/controls/engines/engine["~engNum~"]/hydr");
		m.sw_partsep= props.globals.getNode("/controls/engines/engine["~engNum~"]/partsep");
		m.sw_gov	= props.globals.getNode("/controls/engines/engine["~engNum~"]/gov");
		
		m.sw_start 	= props.globals.getNode("/controls/engines/engine["~engNum~"]/starter");
		m.sw_starton= props.globals.getNode("/controls/engines/starteron");
		m.sw_collectiv 	= props.globals.getNode("/controls/engines/engine["~engNum~"]/throttle");		# collectiv
		m.sw_thrust = props.globals.getNode("controls/engines/engine["~engNum~"]/thrust");				# throttle on collectiv
		m.sw_brake	= props.globals.getNode("/controls/engines/brake");									# TODO : one brake per engine

        m.fuelpress	= props.globals.getNode("/bell412/mechanics/engines/engine["~engNum~"]/fuelpress");
		m.oilpress	= props.globals.getNode("/bell412/mechanics/engines/engine["~engNum~"]/oilpress");
		m.oiltemp 	= props.globals.getNode("/bell412/mechanics/engines/engine["~engNum~"]/oiltemp");
		m.hydrpress	= props.globals.getNode("/bell412/mechanics/engines/hydr["~engNum~"]/press");
		m.hydrtemp 	= props.globals.getNode("/bell412/mechanics/engines/hydr["~engNum~"]/temp");

		m.powered	= props.globals.getNode("/bell412/electrical/output/engines/igniter["~engNum~"]");	# engine (un)powered
		m.state		= props.globals.getNode("/bell412/mechanics/engines/engine["~engNum~"]/state");		# engine state [0:OFF,1-5:STARTING,6:RUNNING]
		m.runnable	= props.globals.getNode("/bell412/mechanics/engines/engine["~engNum~"]/runnable");	# engine check OK
		m.n1 		= props.globals.getNode("/bell412/mechanics/engines/engine["~engNum~"]/n1");
		m.n2 		= props.globals.getNode("/bell412/mechanics/engines/engine["~engNum~"]/n2");
		m.itt 		= props.globals.getNode("/bell412/mechanics/engines/engine["~engNum~"]/itt");
		m.rpm		= props.globals.getNode("/bell412/mechanics/engines/engine["~engNum~"]/rpm");
		m.torque_pct = props.globals.getNode("/bell412/mechanics/engines/torquepct");					# mast torque instrument

		m.sw_collectiv.setValue(1);	# FG bug: only engine[0] has coll. to 1
		print("[Bell-412] + Engine["~engNum~"]: initialized.");
        return m;
    },
	set_state: func(n) { me.state.setValue(n); },
	get_state: func() { return me.state.getValue(); },
	set_runnable: func(s) { me.runnable.setBoolValue(s); },
	set_hydrpress: func(v) { interpolate(me.hydrpress,v,4); },
	set_hydrtemp: func(v,t)  { interpolate(me.hydrtemp,v,t); },
	set_oiltemp: func(v,t)  { interpolate(me.oiltemp,v,t); },

	update_n1: func() {	# n1 depends on gas throttle TODO and collectiv needs
		var gas = math.clamp(me.sw_thrust.getValue(),2,100);
		var n1 = math.clamp(me.n1.getValue(),2,100);
		var dt = 4; var dt1 = 0; var dt2 = 0;
		target = gas - n1;
		if ( target > 0 ) {	# n1 < gasprod => increase N1
			# formula: 	w/ small gas throttle, 'infinite' time to get 100% N1 when N1 is small
			# 			dt is proportional to gas (engine throttle) with a log10() curve. 
			# 			power: adjust the log10() curve (and so dt1 - dt2)
			# 			20: minimum time at 100% gas to get 100% N1
			dt1 = 20/math.pow(gas/(math.log10(100)*50),1.5);		# current gas throttle
			dt2 = 20/math.pow(gas/(math.log10(n1)*50),1.5);			# current value of N1
			dt = math.clamp(dt1 - dt2,3,600);	# 3 sec. minimum latency, 600 as 'infinite' time (10mn.)
		}
		#print("DEBUG: dt: "~dt~", gas:"~gas~", n1:"~n1~" target:"~target);
		interpolate(me.n1,gas,dt);
	},

	update_n2: func() {	 # TODO current n2 follows rotorgear which depends on n1, it must depend on n1, then nr on n2
		var rpmpct = yasim_rotor_rpm.getValue() / ROTOR_MAX_RPM * 100;
		if ( me.state.getValue() < 5 )
			me.set_load(me.n2,rpmpct,1);		# 't' is based upon TimerN2 refresh rate
		else
			me.set_load(me.n2,me.n1.getValue(),1);

		me.rpm.setValue( LIMITS.ENGINE_RPM_N2_MAX * rpmpct / 100)
	},

	printout: func(msg) {
		print("[Bell-412] > engine["~me.id~"]["~me.get_state()~"]: "~msg);
	},
	
	set_load: func(node,v,t) {
		interpolate(node,v,t);		# t sec to value
	},

	check_power: func() {
		#if ( me.powered.getBoolValue() and ( me.charge.getValue() > .25) ) {		# TODO : Power will set it and will change me.powered as needed
		if ( me.powered.getBoolValue() ) {
			return 1;																# powered + enough charge
		}
		me.printout("power check: failed");
		return 0;
	},

	check_fuelpress: func() {
		if ( me.powered.getBoolValue() and me.fuelpress.getValue() >= FUELPRESS_MINIMUM ) {
			#me.printout("fuel pressure: OK");
			return 1;
		}
		me.printout("fuel pressure: failed");
		return 0;
	},

	check_hydr: func() {
	# trigger: pilot hydrau system switch
		# TODO : get engine state and set temp proportional to itt
		# TODO : check pressure
		var exttemp = props.globals.getNode("/environment/temperature-degc").getValue();
		if ( me.powered.getBoolValue() ) {							# ENGINE IS POWERED
			if ( me.hydrtemp.getValue() < exttemp )					# temp is less than ambiant temp (starting)
				me.set_hydrtemp(exttemp,2);							# hydr T instrument set to external temp
			if ( me.oiltemp.getValue() < exttemp )					# temp is less than ambiant temp (starting)
				me.set_oiltemp(exttemp,2);							# oil T instrument set to external temp
			
			if ( me.sw_hydr.getBoolValue() ) {						# HYDR SWITCH ON
				me.preheat(exttemp);								# heating hydrau
				#me.printout("hydraulics check: OK");
				return 1;
			} else {												# HYDR SWITCH OFF
				if ( me.hydrtemp.getValue() > exttemp )
					me.set_hydrtemp(exttemp,30);					# slowly cooling to external temp
				if ( me.oiltemp.getValue() > exttemp )
					me.set_oiltemp(exttemp,30);		
				
				me.printout("hydraulics check: failed");
				return 0;
			}
		}
		else {														# ENGINE UNPOWERED
			me.set_hydrtemp(OILTEMP_DEFAULT,2);
			me.set_oiltemp(OILTEMP_DEFAULT,2);
			me.printout("hydraulics check: failed");
			return 0;
		}
	},

	preheat: func(exttemp) {
	# trigger: me.check_hydr()
		if ( me.hydrtemp.getValue() < OILTEMP_NOMINAL ) {
			if ( me.hydrtemp.getValue() < exttemp ) {
				interpolate(me.hydrtemp,exttemp,2,OILTEMP_NOMINAL,30);		# coldstart: quickly up to external temp, then slowly heating
			} else {
				interpolate(me.hydrtemp,OILTEMP_NOMINAL,15);				# warmstart: up to nominal
			}
		}
		if ( me.oiltemp.getValue() < OILTEMP_NOMINAL ) {
			if ( me.oiltemp.getValue() < exttemp )
				interpolate(me.oiltemp,exttemp,2,OILTEMP_NOMINAL,30);
			else
				interpolate(me.oiltemp,OILTEMP_NOMINAL,15);
		}
	},
	
	check_prestart: func() {
		if ( (me.sw_brake.getValue() == 0) 
			  and ( me.sw_collectiv.getValue() >= COLLECTIV_START_MAX ) 
			  and ( me.sw_thrust.getValue() >= THROTTLE_START_MIN ) 
			  and ( me.sw_partsep.getBoolValue() )
			  and ( me.sw_gov.getBoolValue() )
		   ) {
			#me.printout("prestart check (brake,collectiv,throttle,gov,partsep): OK");
			return 1;
		}
		
		me.printout("prestart check (brake,collectiv,throttle,gov,partsep): failed");
		return 0;
	},

	check: func() {
		me.set_runnable( me.check_power() and me.check_fuelpress() and me.check_hydr() );
		return me.runnable.getBoolValue();
	},

	check_running: func() {
		# TODO: update_engine() : model fuel,itt,n1,n2
		if ( me.state.getValue() == 5 ) {
			if ( ! me.check_fuelpress() )
				me.die();
		}
	},

	start: func(twinmode) {
		me.set_state(1);																# must override update_nr()
		if ( me.sw_start.getBoolValue() and me.check() and me.check_prestart() ) {		# start switch ON + check OK + prestart OK
			me.printout("starting ...");
			me.sw_starton.setValue(me.id+1);											# 0->1, 1->2
			me.twinmode = twinmode;														# we need this 'cause timer don't supp. stack data
			TimerN1[me.id].start();
			var nextstep = maketimer(1, bell412.iBell412.Rotor.Engines[me.id], func() {
				me.start1();
			});
		} else {
			me.printout("not runnable.");
			var nextstep = maketimer(2, bell412.iBell412.Rotor.Engines[me.id], func() {
				me.start_failed();
			});
		}
		nextstep.singleShot = 1;
		nextstep.start();
	},

	start1: func() {	# get enough ac power 			[0-1]	+1
		me.set_state(1);
		me.printout("stage 1");
		var dt = 1;	# duration of this stage

		if ( me.twinmode == 0 ) 						# alone, n2/nr=0
			Electrical.get_startingPower();					# tell Power we suck it

		#me.set_load(me.fuelpress,8,dt);
		me.set_load(me.itt,100,dt);
		interpolate(me.sw_thrust,40,dt);
		
		var timer = maketimer(dt, bell412.iBell412.Rotor.Engines[me.id], func() {
			me.start2();
		});
		timer.singleShot = 1;
		timer.start();
	},

	start2: func() {	# warm up                   	[1-7]	+6
		me.set_state(2);
		me.printout("stage 2");
		var dt = 5.5;	# duration of this stage 
	
		#me.set_load(me.fuelpress,6,dt);
		me.set_load(me.itt,300,dt);
		me.set_load(me.oilpress,30,dt);
		interpolate(me.sw_thrust,60,1);			# throttle warm up
		
		var timer = maketimer(dt, bell412.iBell412.Rotor.Engines[me.id], func() {
			me.start3();
		});
		timer.singleShot = 1;
		timer.start();
	},

	start3: func() {	# n1 strt combustion + rg start	[7-15]	+8
		me.set_state(3);
		me.printout("stage 3");
		var dt = 8;
		
		if ( me.twinmode == 0 ) {			# alone, n2/nr=0
			me.printout("rotorgear start");
			# rotorgear start				#
			rg_start.setValue(1);
			rg_maxreltorque.setValue(0.01);
			rg_reltarget.setValue(0.1);
		}
		
		Electrical.set_allNominal(dt);
		#me.set_load(me.fuelpress,FUELPRESS_NOMINAL-2,dt);
		interpolate(me.itt,700,4,720,1,550,3);		# TODO update_itt()
		me.set_load(me.oilpress,80,dt);
		interpolate(me.sw_thrust,90,1,90,3,55,dt-4); # max thrust during 4 sec., then back to 55%
		if ( me.twinmode == 0 ) 			# alone, n2/nr=0
			TimerN2[me.id].start();
		else								# twin mode
			interpolate(me.n2,40,dt);
		
		var timer = maketimer(dt, bell412.iBell412.Rotor.Engines[me.id], func() {
			me.start4();
		});
		timer.singleShot = 1;
		timer.start();
	},

	start4: func() { # gently goes up to N1 NOMINAL;	[15-75] +60
		me.set_state(4);
		me.printout("stage 4");
		var dt = 60;
		if ( me.twinmode == 1 )				# twin mode
			dt = 12;
			
		if ( me.twinmode == 0 ) { 			# alone
			# rotorgear
			interpolate(rg_maxreltorque,0.05,4, 0.2,1, 0.5,30, 0.90,27);
			interpolate(rg_reltarget,   0.2,4,                 0.95,dt-4);
		}

		#me.set_load(me.fuelpress,FUELPRESS_NOMINAL,dt);
		me.set_load(me.itt,620,dt);
		me.set_load(me.oilpress,OILPRESS_NOMINAL,dt);
		interpolate(me.sw_thrust,95,dt);	# TODO twin mode ==> OEI
		if ( me.twinmode == 1 ) 			# twin mode
			interpolate(me.n2,95,dt);
		
		var timer = maketimer(dt, bell412.iBell412.Rotor.Engines[me.id], func() {
			me.start5();
		});
		timer.singleShot = 1;
		timer.start();
	},

	start5: func() { #engine running
		var dt = 10;
		interpolate(me.state,5,dt);			# state5 after dt, only when func ended.
		me.printout("stage 5");
		
		if ( me.twinmode == 0 ) { 			# alone
			# rotorgear
			interpolate(rg_maxreltorque,1.0,dt);
			interpolate(rg_reltarget,1.0,dt);
		} else
			TimerN2[me.id].start();
		
		me.set_load(me.itt,ITT_NOMINAL,dt);
		interpolate(me.sw_thrust,100,dt);
		me.sw_start.setBoolValue(0);	# reset starter
		me.sw_starton.setValue(0);		# rotate switch 
		TimerCheckRunning[me.id].start();
	},

	start_failed: func() {
		var soundshutdown = props.globals.getNode("controls/sound/engineshutdown");
		if ( me.state.getValue() > 2 ) {
			soundshutdown.setValue(1);
			interpolate(soundshutdown,0,5);
		}

		me.printout("engine failed: reset");
		me.sw_starton.setValue(0);		# rotate switch 
		me.sw_start.setBoolValue(0);	# reset starter
		me.set_state(0);				# state off
		
		#rg_start.setValue(0);			# reset rotorgear TODO override Rotorgear.update_nr()
		#rg_maxreltorque.setValue(0);
		#rg_reltarget.setValue(0);
		
		# reset all system to nominal
		var dt = 4;
		Electrical.set_allNominal(dt);
		me.check_hydr();
		me.check_fuelpress();
		me.set_load(me.itt,0,dt);
		me.set_load(me.oilpress,0,dt);
		me.set_load(me.sw_thrust,15,dt);
		TimerN1[me.id].stop();			# stop n1 thread 
		TimerN2[me.id].stop();			# stop n2 thread 
		me.set_load(me.n1,0,dt);		# slowdown n1
		me.set_load(me.n2,0,dt);		# slowdown n2
	},

	die: func() {
		var soundshutdown = props.globals.getNode("controls/sound/engineshutdown");
		me.printout("out of service");
		var dt = 8;
		me.set_state(0);				# state off
		soundshutdown.setValue(1);
		interpolate(soundshutdown,0,dt*2);
		me.set_load(me.itt,0,dt*2);
		me.set_load(me.oilpress,0,dt);
		me.set_load(me.sw_thrust,0,dt);
		TimerN1[me.id].stop();			# stop n1 thread 
		TimerN2[me.id].stop();			# stop n2 thread 
		TimerCheckRunning[me.id].stop(); # stop thread
		me.set_load(me.n1,0,dt);		# slowdown n1
		me.set_load(me.n2,0,dt);		# slowdown n2
		me.set_load(me.rpm,0,dt);		# slowdown engine rpm
	}

};

var Rotorgear = {
# TODO : 	
#	autostart(),
    new: func() {
        var m = { parents:[Rotorgear] };
		m.Engines = [];
		m.engine0 = Engine.new(0);														# PT6T TwinPac: turbine 1
		m.engine1 = Engine.new(1);														# PT6T TwinPac: turbine 2
		append(m.Engines,m.engine0);
		append(m.Engines,m.engine1);

		m.starteron= props.globals.getNode("controls/engines/starteron");				# who is starting
		m.rg_start = props.globals.getNode("controls/rotorgear/starter");				# rotorgear init
		m.rg_reltarget 		= props.globals.getNode("controls/rotorgear/reltarget");	# rotorgear target rel rpm
		m.rg_reltargetDamp 	= props.globals.getNode("controls/rotorgear/reltarget-gov"); # rotorgear target rel rpm damp
		m.rg_maxreltorque = props.globals.getNode("controls/rotorgear/maxreltorque");	# rotorgear
		m.yasim_rotor_rpm = props.globals.getNode("rotors/main/rpm");					# set by Yasim
		m.nr = props.globals.getNode("/bell412/mechanics/engines/nr");
		m.torque_pct = props.globals.getNode("/bell412/mechanics/engines/torquepct");	# mast torque instrument
		m.torque = props.globals.getNode("rotors/main/torque",1);						# set by Yasim
		m.torque_sound_filtered = props.globals.getNode("rotors/gear/torque-sound-filtered"); # sounds trick
		m.brake	= props.globals.getNode("/controls/engines/brake");
		m.dt = props.globals.getNode("/sim/time/delta-realtime-sec", 1);				# delta-time
		m.torque_val = 0;
		
		print("[Bell-412] + Rotorgear: initialized.");
        return m;
	},
	
	printout: func(msg) {
		print("[Bell-412] > Rotorgear: "~msg);
	},

	engines_check: func() {																# triggered on bus switch
		me.Engines[0].check();
		me.Engines[1].check();
	},
	
	engine_noneStarting: func() {														# check engines starting state
		state0 = me.Engines[0].state.getValue();
		state1 = me.Engines[1].state.getValue();
		if ( ((state0==0) or (state0==5)) and ((state1==0) or (state1==5)) )			# none is starting
			return 1;
	
		return 0;
	},

	nstarted: func() {																	# nb of engines started
		return ( ( me.Engines[0].state.getValue()>0 ) + ( me.Engines[1].state.getValue()>0) );
	},

	engine_start: func(enr) {															# triggered on 's/S' key or on starter[n] switch
		me.printout("request start on engine["~enr~"]");
		if ( ! me.engine_noneStarting() ) {												# ensure other engine is not starting 
			me.printout("cannot start engine["~enr~"] if started or while other is starting.");
		} 
		else {
			if ( me.Engines[enr].state.getValue() == 5 )
				me.printout("engine["~enr~"] already started.");
			else {
				if ( me.nstarted() == 0 ) {
					me.Engines[enr].start(0);	# start engine with twin mode off
				}
				else {
					me.Engines[enr].start(1);	# start in twin mode on
				}
				if ( ! TimerNR.isRunning )
					TimerNR.start()
			}
		}
	},

	update_nr: func() {
		#me.printout("DEBUG: update_nr()");
		var rpmpct = yasim_rotor_rpm.getValue() / ROTOR_MAX_RPM * 100;
		state0 = me.Engines[0].state.getValue();
		state1 = me.Engines[1].state.getValue();
		if ( (state0==5) or (state1==5) ) {		# running state: set rg_reltarget according to max(e0.n1,e1.n1)
			#me.printout("DEBUG: update_nr(): running");
			target = math.max(me.Engines[0].n1.getValue(),me.Engines[1].n1.getValue())/100 + me.rg_reltargetDamp.getValue();
			interpolate(me.rg_reltarget,target,1.0);	
			# XXX 21/01/18 06:39 
			# 	Ti0.7, td0.01 kp 0.005
			# 	1.9 0.04 0.005
		}
		if ( (state0==0) and (state1==0) ) {	# all engines out
			#me.printout("DEBUG: update_nr(): ended");
			me.rg_start.setValue(0);
			#me.brake.setValue(5);
			interpolate(me.rg_reltarget,0,1);
			interpolate(me.rg_maxreltorque,0,1);
			#interpolate(me.nr,0,20);			# TODO not realistic, must follow n2
			#interpolate(props.globals.getNode("bell412/weights/"~IDX_WEIGHT_ANTIJITTER~"/weight-lb"),WEIGHT_ANTIJITTER,20);	# anti jitter weight
			interpolate(me.torque_pct,0,2);
			#TimerNR.stop();
			#settimer(func { TimerNR.stop() }, 10);
			#settimer(func { engine_brake.setValue(0); }, 24);	# reset brake to default
		} #else 
		interpolate(me.nr,rpmpct,2);
	},

	update_torque: func() {
		#me.printout("DEBUG: update_torque()");
		var torquepct = me.torque.getValue() / ENGINE_MAX_TORQUE * 100;
		interpolate(me.torque_pct,torquepct,2);
	}, 

	# modify sound by torque	 TODO
	update_torque_sound_filtered: func() {
		state0 = me.Engines[0].state.getValue();
		state1 = me.Engines[1].state.getValue();
		var f = 4 * me.nr.getValue() / 100;					# 0 < nr < 100 ==> 0 < f < 4
		if ( (state0==0) and (state1==0) ) 	# all engines out
			interpolate(me.torque_sound_filtered,0.0,30);
		else 
			interpolate(me.torque_sound_filtered,f,2);		# ln(4) = 1.38 (sound.xml)
	},

	# blade blur spin max @ 50, see Rotors/412-rotors.xml
	update_bladesblur_spin: func() {
		var MAX_BLUR_SPIN = 50; # bladesblur max spinning factor @ max rpm ie RPM=324 => SPIN=MAX_BLUR_SPIN
		var rpm = me.yasim_rotor_rpm.getValue();
		var spin = rpm * ( ROTOR_MAX_RPM - ( rpm-MAX_BLUR_SPIN )) / ROTOR_MAX_RPM;
		props.globals.getNode("/controls/effects/rotor-spin").setValue(spin);
	},
};


# Chopper : main entry points
var Chopper = {
    new: func() {
        var m = { parents:[Chopper] };
		m.Rotor = Rotorgear.new();				# Twin turbine engine Bell412 Pratt & Whitney PT6T Twinpac / Yasim Rotorgear System
		
		print("[Bell-412] + Chopper: initialized.");
        return m;
	},
	
	printout: func(msg) {
		print("[Bell-412] > Chopper: "~msg);
	},

	engines_check: func() {						# triggered on OH Bus switch
		me.check_fuel(2);						# power to pump
		me.Rotor.engines_check();
	},

	engine_start: func(n) {						# triggered on 'sS' keys or collectiv starter switch
		me.Rotor.engine_start(n);
	},
	
	check_fuel: func(n) {						# pedestal fuel switch
		FuelSystem.checkFlow(n);
	},

	check_hydr: func(n) {						# pedestal hydr switch
		me.Rotor.Engines[n].check_hydr();
	}

};

var iBell412 = Chopper.new();

# ------------------------------------------------------------------------------------------------------
# Animat
# ------------------------------------------------------------------------------------------------------

var cargoDoorOpen = func (node,side) {
	sound_door_crew_open(node);						# sound trigger + animat
	weightBalanceCdoor(side,"closed","opened",ANIM_DOORS_DT);	# transfert load from opened to closed weights
	weightUpdateCargoDoorVibration.start();
}

var cargoDoorClose = func (node,side) {
	sound_door_crew_close(node);					# sound trigger + animat
	weightBalanceCdoor(side,"opened","closed",ANIM_DOORS_DT);
	settimer(weightResetCargoDoorVibration,ANIM_DOORS_DT + 0.2);	# self reset if all doors closed
}

# ------------------------------------------------------------------------------------------------------
# timers thread tweaks
# ------------------------------------------------------------------------------------------------------

var timern10 = maketimer(1.0,bell412, func () {
	iBell412.Rotor.Engines[0].update_n1();
});
var timern11 = maketimer(2.0,bell412, func () {
	iBell412.Rotor.Engines[1].update_n1();
});

var timern20 = maketimer(1.0, bell412, func() {
	iBell412.Rotor.Engines[0].update_n2();
});
var timern21 = maketimer(1.0, bell412, func() {
	iBell412.Rotor.Engines[1].update_n2();
});

var TimerN1 = [];			# started/stoped by the Engines themselves
append(TimerN1,timern10);
append(TimerN1,timern11);

var TimerN2 = [];			# started/stoped by the Engines themselves
append(TimerN2,timern20);
append(TimerN2,timern21);

var TimerNR = maketimer(1.0, bell412, func() {
	FuelSystem.update();
	iBell412.Rotor.update_nr();
	iBell412.Rotor.update_torque();
	iBell412.Rotor.update_torque_sound_filtered();
	iBell412.Rotor.update_bladesblur_spin();
});

var timerchk1 = maketimer(2.0,bell412, func() {
	iBell412.Rotor.Engines[0].check_running();
});

var timerchk2 = maketimer(2.0,bell412, func() {
	iBell412.Rotor.Engines[1].check_running();
});
var TimerCheckRunning = [];			# started/stoped by the Engines themselves
append(TimerCheckRunning,timerchk1);
append(TimerCheckRunning,timerchk2);

# ------------------------------------------------------------------------------------------------------
# User Data
# ------------------------------------------------------------------------------------------------------
var checkUse = func () {
	var totalUse = props.globals.getNode("/bell412/data/total-use");
	if ( totalUse.getValue() == 0 ) {
    	fgcommand("dialog-show", props.Node.new({ "dialog-name" : "bell412-apropos-dialog" }));
	}
	totalUse.setValue(totalUse.getValue() + 1);
}

# ------------------------------------------------------------------------------------------------------
# Listeners
# ------------------------------------------------------------------------------------------------------

setlistener("/sim/signals/click", func {
  if (__kbd.shift.getBoolValue()) {
    if (__kbd.ctrl.getBoolValue()) {
      var click_pos = geo.click_position();
	  click_pos.dump();
      wildfire.ignite(click_pos);
    }
  }
});

setlistener("/sim/signals/fdm-initialized", func {

	setprop("/sim/signals/fcs-initialized", 1);
	setprop("/sim/signals/bell412-initialized",1);
	print("[Bell-412] * Chopper: ready.");
	checkUse();
});
