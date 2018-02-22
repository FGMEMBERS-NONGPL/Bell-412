# ======================================================================================================
# Bell412 Electrical Power System 
# 	(for the Flightgear Flight Simulator)
# ------------------------------------------------------------------------------------------------------
#
# AUTHOR
# 	Valery Seys		vslash.com
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
# 	Textron Bell 412 Maintenance Manual Vol12 Chapter98
# 	Flightgear Nasal Wiki: http://wiki.flightgear.org/Category:Nasal
#	http://www.concordebattery.com/flyerprint.php?id=2
#
# NOTE
# 	The B412 features one amongst 3 different schematics ; 
# 	the following model rely upon S/N 33001 through 33107
#	nonesntl automatically powered when both gen activ
# 	DC Voltmeter : essentl bus voltage
#
# DATA
#	RG-380E/44 Platinum Series Aircraft Battery Specifications:
#	Primary Aircraft Purpose 	Turbine Starting Aircraft Battery
#	Voltage 	24v
#	Rated Capacity C1 = 1 hr. rate in Ampere Hour
#	rate in ampere hours 	42.00
#	Max Weight 	86.00 lb / 39.0 kg
#	Total Capacity in A: 1008 A
#
#	IPP	IPR 	IPP	IPR 	IPP	IPR
#	23°C (74°F) -18°C (0°F) -30°C (-22°F)
#	A 	 A 		A 	A 		A 	A
#	1350 1000 	875	750 	750	600
#
#	IPP : 	IEC aircraft battery rating (0.3/15s power discharge)
#	IPR : 	Aircraft battery rating according to IEC (15s power discharge)
# 
#	B412 MM VA vs W
#	P = UI
#	I(A) = S(VA) / V(V)
#
#	BAT LIFE : =[ 1-ABS(LOG(bell412/electrical/suppliers/supplier[x]/charge))^2 ] by +/- temperature_factor
#
#	B412 FM : pp86 : 	A fully charged battery provideselectrical power for approximately 30 mn. under normal 
#						conditions. With EMERG LOAD switch in EMERG LOAD position, provides battery the 90 minutes of
#						approximately electrical power => ie less instrumentation powered.
#
#* Capa @24V
#1008*24= 24192 W
#
#450VA/27V = 16.66 A
#
#
#capacity (in Ah) / load (in A) = battery life (in h)
#
#1008 / 17 = 59.9
#
#250+120+15 = 385
#
#real power P = apparent power S * power factor PF
#			 = apparent power S * cos(thetA)
#with PF : [0..1]
#
#P(W) 	= S(VA) * PF
#		= S(VA) * cos theta
#
#S(VA) 	= P(W) / PF
#
#PF 		= P(W) / |S(VA)|
# CHANGELOG
# 06/2016	: init
# 11/2016	: complete redesign using Nasal OO: event driven, avoid 'if then', remove timer() thread
# 07/2017	: design according to the real B412 S/N 33001 Busing Schematic
# 10/2017	: v0.6: new via property rules and nasal
# ======================================================================================================
# ------------------------------------------------------------------------------------------------------
# Const
# TODO: ext temp and OAT battery limits (see 412 manual)
# ------------------------------------------------------------------------------------------------------

# Capacity vs Ambient Temperature
var POWER_DATA_TEMP2AMP = [
			   			[ -30, 0750 ],
						[ -18, 0875 ],
						[ 23, 1350 ],
			    		[ 50, 1380 ],
];
var BATTERY_CAPA_AH = props.globals.getNode("/bell412/limits/battery_capa_ah").getValue();
var DCLOAD_NOMINAL = props.globals.getNode("/bell412/limits/power_dc_load_nom").getValue();
var ELECTRICAL_SYNC_DT = 2;

# ------------------------------------------------------------------------------------------------------
# Classes
# ------------------------------------------------------------------------------------------------------
#
# Electrical System v0.6
var ElectricalSystem = { 
    new: func() {
		var m = { parents:[ElectricalSystem] };
		
		# Main Battery
		m.batinuse = props.globals.getNode("/bell412/electrical/suppliers/supplier[0]/inuse");
		m.batload = props.globals.getNode("/bell412/electrical/suppliers/supplier[0]/charge");
		m.batlife = props.globals.getNode("/bell412/electrical/suppliers/supplier[0]/life-factor");
		m.batspin = props.globals.getNode("/bell412/electrical/suppliers/supplier[0]/spin-factor");
		m.capa_ah = props.globals.getNode("/bell412/electrical/suppliers/supplier[0]/capacity_ah");

		#TimerPowerCheck[0].start();
		print("[Bell-412] + Electrical System: initialized.");
		return m;
	},

	printout: func(msg) {
		print("[Bell-412] > Electrical System: "~msg);
	},
	
	set_load: func(node,v,t) {
		interpolate(node,v,t);		# t sec to value
	},


	#	BAT LIFE : =[ 1-ABS(LOG(bell412/electrical/suppliers/supplier[x]/charge))^2 ] +/- temperature_factor
	#	Total discharge after 30mn. w/ essential instr. (B412 FM)
	#	30*60sec = 1800 sec / 5sec = 360.00 ; 1/360 = 0.002777 )
	#	TODO battery temperature, external temperature discharge factor
	update_batteryLife: func() {
		var dt = ELECTRICAL_SYNC_DT - 0.5;
		var batinuse = me.batinuse.getBoolValue();
		var currentBatload = me.batload.getValue();
		#me.printout("DEBUG: currentBatLoad: "~currentBatload);
		if ( batinuse and currentBatload > 0.1 ) {
			me.set_load(me.batload, currentBatload - 0.002777, dt);
			#me.batload.setValue( currentBatload - 0.002777 );								# discharge
		} else {
			if ( currentBatload < 1.0 )
				me.set_load(me.batload, currentBatload + 4*( 0.002777 * me.batspin.getValue() ), dt);
				#me.batload.setValue( currentBatload + 4*( 0.002777 * me.batspin.getValue() )); 	# charge x4
		}
		if ( currentBatload < 0.1 )
			currentBatload = 0.1;
		var logBatload = math.log10(math.abs(currentBatload));
		#me.batlife.setValue(1-math.abs(logBatload*logBatload));
		me.set_load(me.batlife, 1-math.abs(logBatload*logBatload), dt);
		#me.capa_ah.setValue(BATTERY_CAPA_AH * me.batlife.getValue());
		me.set_load(me.capa_ah, BATTERY_CAPA_AH * me.batlife.getValue(), dt);
	},
	
	# TODO : lazy way / power management update_charge(), currently only animate during the 1st 3 starting stages
	get_startingPower: func() {
		# if !enoughCharge then return 0
		# else updateCharge(), animate.
		interpolate("bell412/electrical/suppliers/supplier[0]/overload",4,2,2,5.5,0,8);
		return 1;
	},
	
	# TODO : old stuff
	set_allNominal: func(dt) {
		#me.set_load(me.Buses[0].dcload,DCLOAD_NOMINAL,dt);
		#me.set_load(me.Buses[1].dcload,DCLOAD_NOMINAL,dt);
		#me.set_load(me.Buses[0].acload,ACLOAD_NOMINAL,dt);
		#me.set_load(me.Buses[1].acload,ACLOAD_NOMINAL,dt);
	}
};

var Electrical = ElectricalSystem.new();

# ------------------------------------------------------------------------------------------------------
# Functions or Entry Points
# ------------------------------------------------------------------------------------------------------
var buses_check = func(n) {
	#Power.buses_check(n);
}

var buses_update = func(n) {
	#Power.buses_update(n);
}

var console_check = func() {
	#Power.console_check();
}

# ------------------------------------------------------------------------------------------------------
# timers thread tweaks
# ------------------------------------------------------------------------------------------------------


var electricalUpdateTimer = maketimer(ELECTRICAL_SYNC_DT, bell412, func () {
	Electrical.update_batteryLife();
});

var electricalTimers = [];			# started/stoped by the Engines themselves
append(electricalTimers,electricalUpdateTimer);


#setlistener("/bell412/electrical/suppliers/supplier[0]/inuse", func {
#	print("[Bell-412] ! Electrical System: BAT INUSE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
#});

setlistener("/sim/signals/fdm-initialized", func {
	electricalTimers[0].start();
	print("[Bell-412] * Electrical System: ready.");
});
