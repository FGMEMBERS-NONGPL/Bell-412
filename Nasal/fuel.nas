# ======================================================================================================
# Bell412 Fuel Manager 
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
# DATA
#
# CHANGELOG
# 06/2017	: init
# ======================================================================================================
# 
# Working Data
# ------------------------------------------------------------------------------------------------------
# 1 bar = 14.504 psi
# gallon [US liquid] 3.78541 litres
# 
# ENDURANCE
# 
# Approximate Fuel Flows (70 degrees F Outside Air Temp, both Engines Running):
# 43% TORQUE: 575 Pounds Per Hour
# 53% TORQUE: 625 Pounds Per Hour
# 70.5% TORQUE: 725 Pounds Per Hour
# 
# Maximum Range: 423nm
# 
# Avg. Fuel Consumption 390 ltr/hr = 103.02 USgal.
# 103.02
# 
# 
# Fuel Capacity: 330.5 US Gallons. (Weight 6.6 lbs per gallon)
# Max Fuel Weight: approx 2180 LBS.
# 
# from 1fee8-ghs_aircraft-spec-sheet-ab412-dhfq.pdf
# Fuel consumption 395 ltr/hr
# 
# NOTES
# pression initiale
# débit requis
# temps de réponse de la pompe => si débit requis trop grand, pression chute via le temps de régulation de la pompe.
# ! : les pompes des 2 engins sont couplées (cf video), càd que si l'un chute, l'autre chute aussi.
# 07/07/17 23:16: le couple est réalisé si XFEED sur NORM
# 
# 12% N1 for the engine driven fuel pump
# 
# Array consumption:
# alt_coef : 1
# yasim total fuel : 2218 lbs
# torque_pct vs lbs/h vs frac	
# 	0	0	
# 	43	575
# 	53	625
# 	70	725
# 	90	830
# 
# 
# bell412.fuel.capacity.left
# bell412.fuel.capacity.right
# bell412.fuel.capacity.fwd
# bell412.fuel.capacity.mid
# 
# consumables.fuel.total-fuel-gals
# consumables.fuel.total-fuel-lbs
# consumables.fuel.level-norm
# 
# consumables.fuel.tank[n].capacity-gal_us
# consumables.fuel.tank[n].level-gal_us
# consumables.fuel.tank[n].level-lbs
# consumables.fuel.tank[n].level-norm
# consumables.fuel.tank[n].selected [true/false]
# 
# Bell412 - Yasim Tankers position:
# tank[0] : left front 1
# tank[1] : right  front 1
# tank[2] : left front 2
# tank[3] : right  front 2
# tank[4] : mid left side
# tank[5] : mid right side
# tank[6] : aft left (half part of real mid1 + mid2)
# tank[7] : aft right (half part of real mid1 + mid2)
# 
# bell412.fuel.capacity.left  = tank[1] + tank[3] + tank[4]/2 + tank[5]/2 + tank[7]
# bell412.fuel.capacity.right = tank[0] + tank[2] + tank[4]/2 + tank[5]/2 + tank[6]
# bell412.fuel.capacity.fwd   = tank[0] + tank[1] + tank[2] + tank[3]
# bell412.fuel.capcity.mid = tank[4] + tank[5] + tank[6] + tank[7]

# LOGIC
# we must find values : engine[n].hasFuel and tank[n].inUse
# we have 2 tank compounds : fwd + mid.
# for each compound, we have 4 possible flow defined as fl1, fl2, fl3 and fl4
# each flow 'fln' is a logical sum of switches position  
# mid[n] compound is 'inUse' if one of these flows is True AND any valve True
# fwd[n] compound is 'inUse' if mid[n] is 'inUse' AND trans[n] is True
# we add yasim tank for each ones following the Bell features. 
# Algo:
# thread at 3 sec.
# 	
# 	lph = calc lbs/h
#	cons = lph/20 (for 5 sec.)
#
# ------------------------------------------------------------------------------------------------------
# Const (Bell412 Limitations & data)
# ------------------------------------------------------------------------------------------------------
var FUELPRESS_MINIMUM = props.globals.getNode("/bell412/limits/fuelpress_min").getValue();
var FUELPRESS_MAXIMUM = props.globals.getNode("/bell412/limits/fuelpress_max").getValue();
var FUELPRESS_NOMINAL = props.globals.getNode("/bell412/limits/fuelpress_nom").getValue();

var FUEL_TOTAL_LBS = 2218;		# all cells total lbs
var FUEL_CONSIDLE_LBS = 0.03;	# min. consumption at idle

var FUEL_SYNC_DT = 1;		# (sec.) delta time balancing

# Fuel cons: torque% vs lbs/sec.
var CONSDATA = [ 
			    [ 00, 0.000 ],
				[ 20, 0.077 ],	# 280 lbs/h
				[ 40, 0.158 ],  # 570
			    [ 50, 0.172 ],  # 620
			    [ 70, 0.201 ],	# 725
			    [ 90, 0.230 ],	# 830
			    [100, 0.238 ],	# 860
				[999, 0.277 ]	# 1000
];

# TANKSDATA
var IDX_TANKS_NUM = 0;
var IDX_TANKS_ENG = 1;
var IDX_TANKS_USE = 2;
var IDX_TANKS_POS = 3;
var TANKS_POS_FWD = 0;
var TANKS_POS_MID = 1;
# 	number, turbine, inUse, pos
var TANKSDATA = [   
				[ 0, 0, 0, 0 ],
				[ 1, 1, 0, 0 ],
				[ 2, 0, 0, 0 ],
				[ 3, 1, 0, 0 ],
				[ 4, 0, 0, 1 ],
				[ 5, 1, 0, 1 ],
				[ 6, 0, 0, 1 ],
				[ 7, 1, 0, 1 ]
];

# 
# Tanker : tank cells compound
#
var Tanker = {
	new: func(_num) {
		var m = { parents:[Tanker] };
		m.num  = _num;					# engine number for which this compound is dedicated
		m.twin = !_num;					# twin part number (only 2 turbines!)

		m.midInUse = 0;					# mid tanks in use (so valve is opened)
		m.fwdinUse = 0;					# fwd tanks in use

		m.f1 = 0;						# flow paths, manager needs to know them.
		m.f2 = 0;						#
		m.f3 = 0;						#
		m.f4 = 0;						#

		# switches
		m.sw_trans 		= props.globals.getNode("/controls/fuel/engine["~_num~"]/trans");					# transfer btw fwd and aft, 1st 2 tanks
		m.sw_pump  		= props.globals.getNode("/controls/fuel/engine["~_num~"]/pump");					# pump
		m.sw_pumppower	= props.globals.getNode("/bell412/electrical/output/fuel/pump["~_num~"]");			# pump powered state
		m.sw_valve 		= props.globals.getNode("/controls/fuel/engine["~_num~"]/valve");					# main valve to engine
		m.sw_xfeed		= props.globals.getNode("/controls/fuel/xfeed");									# pump xfeed
		m.sw_intcon 	= props.globals.getNode("/controls/fuel/intcon");									# mid tank interconn.
		# twin part
		m.sw_xvalve = props.globals.getNode("/controls/fuel/engine["~!_num~"]/valve");						# twin part main valve to engine
		m.sw_xpump  = props.globals.getNode("/controls/fuel/engine["~!_num~"]/pump");						# twin part pump
		m.sw_xpumppower	= props.globals.getNode("/bell412/electrical/output/fuel/pump["~!_num~"]"); 		# pump powered state
		
		# instruments
		m.instrQty = props.globals.getNode("bell412/fuel/engine["~_num~"]/level-lbs");
		
		
		print("[Bell-412] + Tanker["~_num~"]: initialized.");
		return m;
	},
	
	printout: func(msg) {
		print("[Bell-412] > Tanker["~me.num~"]: "~msg);
	},

	# is a compound (fwd,mid) fueled 
	# return : 0,1
	hasFuelAtPos: func(pos) {
		foreach ( t; TANKSDATA ) {
			if ( (t[IDX_TANKS_ENG] == me.num) and (t[IDX_TANKS_POS] == pos) ) {
				if ( props.globals.getNode("/consumables/fuel/tank["~t[IDX_TANKS_NUM]~"]/level-norm").getValue() > 0.01 ) {
					return 1;
				}
			}
		}
		return 0;
	},

	setInUseAtPos: func(pos,state) {
		foreach ( t; TANKSDATA ) {
			if ( (t[IDX_TANKS_ENG] == me.num) and (t[IDX_TANKS_POS] == pos) ) {
				t[IDX_TANKS_USE] = state;
			}
		}
	},
	
	# check all possible path from which engines could get fuel.
	# set inUse state for mid and fwd tanks.
	checkFlowPath: func() {
		var mid = me.hasFuelAtPos(TANKS_POS_MID);
		var fwd = me.hasFuelAtPos(TANKS_POS_FWD);
		var trans = me.sw_trans.getBoolValue();
		var pump = me.sw_pump.getBoolValue() and me.sw_pumppower.getBoolValue();
		var valve = me.sw_valve.getBoolValue();
		var pump2 = me.sw_xpump.getBoolValue() and me.sw_pumppower.getBoolValue();
		var valve2 = me.sw_xvalve.getBoolValue();
		var xfeed = me.sw_xfeed.getBoolValue();
		var intcon = me.sw_intcon.getBoolValue();

		# 4 flow paths 
		me.f1 = mid and pump;
		me.f2 = me.f1 and xfeed;
		me.f3 = mid and intcon and pump2;
		me.f4 = me.f3 and xfeed;

		# a tank compound is in use only if the valve is opened and tank has enough fuel
		me.midInUse = ( me.f1 and valve ) or ( me.f2 and valve2 ) or ( me.f3 and valve2) or ( me.f4 and valve );
		me.fwdInUse = fwd and me.midInUse and trans;

		me.setInUseAtPos(TANKS_POS_MID,me.midInUse);
		me.setInUseAtPos(TANKS_POS_FWD,me.fwdInUse);

		#me.printout("DEBUG: f1:"~me.f1~", f2:"~me.f2~", f3:"~me.f3~", f4:"~me.f4~", mid:"~mid~", use:"~me.midInUse~", fwd:"~fwd~", use:"~me.fwdInUse);
	},

	# sync fwd and mid tanks at same level
	transBalance: func() {
		var v0 = 0; var v1 = 0; var d=0;
		var trans = me.sw_trans.getBoolValue();
					
		if ( trans ) {
			v0 = me.getFracAtPos(TANKS_POS_FWD);
			v1 = me.getFracAtPos(TANKS_POS_MID);
			d = 0;
			
			if ( v0 < v1 ) {
				d = (v1 - v0) / 2;
				me.setFracAtPos(v0 + d,TANKS_POS_FWD);
				me.setFracAtPos(v0 + d,TANKS_POS_MID);
			}
			else if ( v0 > v1 ) {
				d = (v0 - v1) / 2;
				me.setFracAtPos(v1 + d,TANKS_POS_FWD);
				me.setFracAtPos(v1 + d,TANKS_POS_MID);
			} 
			else { 
				me.setFracAtPos(v0,TANKS_POS_FWD);
				me.setFracAtPos(v0,TANKS_POS_MID);
			}
		}
		
	},

	# remove a fraction [0..1] at 'pos'
	removeFracAtPos: func(frac, pos) {
		var f=0;
		foreach( t; TANKSDATA ) {
			if ( t[IDX_TANKS_ENG] == me.num and t[IDX_TANKS_POS] == pos ) {
				f = props.globals.getNode("consumables/fuel/tank["~t[IDX_TANKS_NUM]~"]/level-norm").getValue();
				f = f - frac;
				interpolate(props.globals.getNode("consumables/fuel/tank["~t[IDX_TANKS_NUM]~"]/level-norm"),f,FUEL_SYNC_DT);
			}
		}
	},
	
	# add a fraction [0..1] at 'pos'
	addFracAtPos: func(frac, pos) {
		var f=0;
		foreach( t; TANKSDATA ) {
			if ( t[IDX_TANKS_ENG] == me.num and t[IDX_TANKS_POS] == pos ) {
				f = props.globals.getNode("consumables/fuel/tank["~t[IDX_TANKS_NUM]~"]/level-norm").getValue() + frac;
				interpolate(props.globals.getNode("consumables/fuel/tank["~t[IDX_TANKS_NUM]~"]/level-norm"),f,FUEL_SYNC_DT);
			}
		}
	},
	
	# return a fraction [0..1] from 'pos'
	getFracAtPos: func(pos) {
		var f=0; var tot=0;
		foreach( t; TANKSDATA ) {
			if ( t[IDX_TANKS_ENG] == me.num and t[IDX_TANKS_POS] == pos ) {
				f = f + props.globals.getNode("consumables/fuel/tank["~t[IDX_TANKS_NUM]~"]/level-norm").getValue();
				tot = tot+1;
			}
		}
		return f/tot;
	},
	
	# set at a fraction [0..1] at 'pos'
	setFracAtPos: func(frac, pos) {
		foreach( t; TANKSDATA ) {
			if ( t[IDX_TANKS_ENG] == me.num and t[IDX_TANKS_POS] == pos ) {
				interpolate(props.globals.getNode("consumables/fuel/tank["~t[IDX_TANKS_NUM]~"]/level-norm"),frac,FUEL_SYNC_DT);
			}
		}
	},

	# return qty level in US Gal. at Pos (qty selector)
	getGalAtPos: func(pos) {
		var tot=0;
		var v=0;
		foreach( t; TANKSDATA ) {
			if ( t[IDX_TANKS_ENG] == me.num and t[IDX_TANKS_POS] == pos ) {
				tot += props.globals.getNode("consumables/fuel/tank["~t[IDX_TANKS_NUM]~"]/level-gal_us").getValue();
			}
		}
		return tot;
	},

	# return total qty in Pounds for fwd/mid location
	getLbsAtPos: func(pos) {
		var tot=0;
		foreach( t; TANKSDATA ) { 
			if ( t[IDX_TANKS_ENG] == me.num and t[IDX_TANKS_POS] == pos ) {
				tot += props.globals.getNode("consumables/fuel/tank["~t[IDX_TANKS_NUM]~"]/level-lbs").getValue();
			}
		}
		return tot;
	},

	# remove lbs/2 (we have 2 tanks) from mid compound ; if fwd is in 'transit', will be selfbalanced.
	# called by FuelManager consumption function
	removeLbsAtMid: func(lbs) {
		var current = 0;
		foreach( t; TANKSDATA ) { 
			if ( t[IDX_TANKS_ENG] == me.num and t[IDX_TANKS_POS] == TANKS_POS_MID and t[IDX_TANKS_USE] == 1 ) {
				current = props.globals.getNode("consumables/fuel/tank["~t[IDX_TANKS_NUM]~"]/level-lbs").getValue();
				props.globals.getNode("consumables/fuel/tank["~t[IDX_TANKS_NUM]~"]/level-lbs").setValue(current - (lbs/2));
			}
		}
	},

	updateInstrQty: func(factor) {
		interpolate(me.instrQty, (me.getLbsAtPos(TANKS_POS_MID) + me.getLbsAtPos(TANKS_POS_FWD))*factor, FUEL_SYNC_DT);
	},
};

# Manage all tanker compounds (on the Bell412, they depend on each other) :
# - manage switches
# - tell to Tanker to check their flow path
# - set & sync fuelpress via xfeed
# - balance mid tanks via intcon
# - 
var FuelManager = {
	new: func() {
		var m = { parents:[FuelManager] };
		m.Tankers = [];
		m.tanker0 = Tanker.new(0);		# left side compound
		m.tanker1 = Tanker.new(1);		# right side compound
		append(m.Tankers,m.tanker0);
		append(m.Tankers,m.tanker1);
		
		# switches
		m.sw_xfeed	= props.globals.getNode("/controls/fuel/xfeed");					# pump xfeed
		m.sw_intcon = props.globals.getNode("/controls/fuel/intcon");					# mid tank interconn.
		m.sw_valve0 = props.globals.getNode("/controls/fuel/engine[0]/valve");			# main valve to engine
		m.sw_valve1 = props.globals.getNode("/controls/fuel/engine[1]/valve");			# main valve to engine
		m.sw_qtyselector = props.globals.getNode("/controls/fuel/qtyselector");			# fuel qty selector
		
		# engine
		m.fuelpress = [];
        m.fuelpress0= props.globals.getNode("/bell412/mechanics/engines/engine[0]/fuelpress");
        m.fuelpress1= props.globals.getNode("/bell412/mechanics/engines/engine[1]/fuelpress");
		append(m.fuelpress, m.fuelpress0);
		append(m.fuelpress, m.fuelpress1);

		m.torque_pct = props.globals.getNode("/bell412/mechanics/engines/torquepct");
		
		# power
		m.powerInstr = props.globals.getNode("/instrumentation/fuelgauge/powered");

		# TOTAL/FWD/MID digital instr. level
		m.instrQtyDigital = props.globals.getNode("bell412/fuel/total-fuel-gals");

		print("[Bell-412] + FuelManager: initialized.");
		return m;
	},
	
	printout: func(msg) {
		print("[Bell-412] > FuelManager: "~msg);
	},
	
	# return cons. in lbs/s (pounds by seconds)
	getConsData: func(torque) {
        var i=0;
        var hiBound=0; var loBound=0; var loTorque=0; var hiTorque=0;
        var cons = 0;
        while ( ( CONSDATA[i][0] < torque ) and ( i < size(CONSDATA) ) ) {
            i = i + 1;
		}
        if ( i != 0 ) {
            loBound = CONSDATA[i-1][1];
            hiBound = CONSDATA[i][1];
            loTorque = CONSDATA[i-1][0];
            hiTorque = CONSDATA[i][0];
            cons = loBound + ( (torque - loTorque) / (hiTorque - loTorque) ) * (hiBound - loBound);
        }
        else { 
            cons = CONSDATA[i][1];
		}
        return cons;
    },
	
	removeFrac: func(frac) {
	
	},
	# intcon balance btw l/r mid
	intconBalance: func() {
		var v0 = 0; var v1 = 0; var d=0;
		var intcon = me.sw_intcon.getBoolValue();
					
		if ( intcon ) {
			v0 = me.Tankers[0].getFracAtPos(TANKS_POS_MID);
			v1 = me.Tankers[1].getFracAtPos(TANKS_POS_MID);
			d = 0;
			
			if ( v0 < v1 ) {
				d = (v1 - v0) / 2;
				me.Tankers[0].setFracAtPos(v0 + d,TANKS_POS_MID);
				me.Tankers[1].setFracAtPos(v0 + d,TANKS_POS_MID);
			}
			else if ( v0 > v1 ) {
				d = (v0 - v1) / 2;
				me.Tankers[0].setFracAtPos(v1 + d,TANKS_POS_MID);
				me.Tankers[1].setFracAtPos(v1 + d,TANKS_POS_MID);
			} 
			else { 
				me.Tankers[0].setFracAtPos(v0,TANKS_POS_MID);
				me.Tankers[1].setFracAtPos(v0,TANKS_POS_MID);
			}
		}
	},

	setFuelPress: func(n,value) {
		interpolate(me.fuelpress[n],value,1);
	},

	# Check flow paths and sync tanks level
	# entry point called from Chopper.checkFuel(n) and TimerNR loop 
	checkFlow: func(n) {
		if ( n == 2 ) {
			me.Tankers[0].checkFlowPath();
			me.Tankers[1].checkFlowPath();
			me.Tankers[0].transBalance();
			me.Tankers[1].transBalance();
			# we wait before syncing
			var timer = maketimer(FUEL_SYNC_DT, bell412.FuelSystem, func() {
				me.intconBalance();
			});
			timer.singleShot = 1;
			timer.start();
			me.intconBalance();
		} 
		else {
			me.Tankers[n].checkFlowPath();
			me.Tankers[n].transBalance();
		}
		me.updateFuelPress();
	},

	# fuelpress > 0  if valve opened and fuel flow ok
	# TODO : must follow N1, not torque_pct
	updateFuelPress: func() {
		var e0 = me.sw_valve0.getBoolValue() and 
				 ( me.Tankers[0].f1 or me.Tankers[0].f4 or me.Tankers[1].f2 or me.Tankers[1].f3 );

		var e1 = me.sw_valve1.getBoolValue() and
				 ( me.Tankers[1].f1 or me.Tankers[1].f4 or me.Tankers[0].f2 or me.Tankers[0].f3 );
		
		var factor = FUELPRESS_NOMINAL + (FUELPRESS_NOMINAL * me.torque_pct.getValue() / 100);
		me.setFuelPress(0, e0 * factor);
		me.setFuelPress(1, e1 * factor);
		
		#me.printout("DEBUG Fuel to Engine: 0:"~e0~", 1:"~e1);
	},
	
	# member called by bell412.TimerNR()
	# TODO : FUEL_CONSIDLE_LBS depends on engines running
	update: func() {
		#me.printout("DEBUG Updating");
		var torque = abs(me.torque_pct.getValue());
		var divider = me.Tankers[0].midInUse + me.Tankers[1].midInUse;
		var fraclbs = me.getConsData(torque)/divider;

		if ( torque != 0 ) {	# TODO engine running
			# me.printout("DEBUG: torque at: "~torque~" removing frac: "~fraclbs~" on "~divider~" compounds");
			if ( me.Tankers[0].midInUse == 1 )
				me.Tankers[0].removeLbsAtMid(FUEL_CONSIDLE_LBS + fraclbs);
		
			if ( me.Tankers[1].midInUse == 1 )
				me.Tankers[0].removeLbsAtMid(FUEL_CONSIDLE_LBS + fraclbs);
		}
		me.checkFlow(2);
		me.updateFuelPress();
	},

	updateInstrQty: func() {
		qtySelector = me.sw_qtyselector.getValue();
		powerInstr = me.powerInstr.getBoolValue();

		me.Tankers[0].updateInstrQty(powerInstr);
		me.Tankers[1].updateInstrQty(powerInstr);
		if ( qtySelector == 0 )						# qty selector to normal => get value from default FG computed 
			me.instrQtyDigital.setValue(props.globals.getNode("/consumables/fuel/total-fuel-gals").getValue());
		else {
			var tot=0;
			tot = me.Tankers[0].getGalAtPos(qtySelector-1) + me.Tankers[1].getGalAtPos(qtySelector-1);	# TANKS_POS_FWD=1 TANKS_POS_MID=2
			me.instrQtyDigital.setValue(tot);
		}
	},
};

var FuelSystem = FuelManager.new();

# ------------------------------------------------------------------------------------------------------
# timers thread tweaks
# ------------------------------------------------------------------------------------------------------

var FUEL_TIMER_INSTR = 0;

# lbs Qty must be computed, so we need a Timer to update them in realtime
# independantly of timerNR
var fuelTimerInstr = maketimer(FUEL_SYNC_DT, bell412, func () {
	FuelSystem.updateInstrQty();
});

var fuelTimers = [];			# started/stoped by the Engines themselves
append(fuelTimers,fuelTimerInstr);

setlistener("/sim/signals/fdm-initialized", func {
	fuelTimers[FUEL_TIMER_INSTR].start();
	print("[Bell-412] * Fuel Management System: ready.");
});
