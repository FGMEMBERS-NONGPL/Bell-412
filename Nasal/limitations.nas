# ======================================================================================================
# Bell412 Limitation Constants 
# 	(for the Flightgear Flight Simulator)
# ------------------------------------------------------------------------------------------------------
#
# AUTHOR
# 	Valery Seys		valery@vslash.com
#
# REFS
# 	Textron BHT-412 Rotorcraft Flight Manual (rev. 9/2002)
#
# CHANGELOG
# 07/2017	: init
# 18/10/17 	: limits now @ bell412/limits/ can be used by digital filters
#
# TODO:
# 21/07/17 19:05	: gather every limitation data from other nasal
# ======================================================================================================
#

var Limitations = {
	new: func() {
		var m = { parents:[Limitations] };

		# Speed
		m.VNE_MAX 				= props.globals.getNode("bell412/limits/vne_max").getValue();
		m.VNE_DOORSOPENED_MAX	= props.globals.getNode("bell412/limits/vne_doorsopened_max").getValue();

		# Electrical Power
		m.POWER_DCLOAD_NOM = props.globals.getNode("bell412/limits/power_dc_load_nom").getValue();
		m.POWER_DCLOAD_MIN = props.globals.getNode("bell412/limits/power_dc_load_min").getValue();
		m.POWER_DCLOAD_MAX = props.globals.getNode("bell412/limits/power_dc_load_max").getValue();
		m.POWER_ACLOAD_NOM = props.globals.getNode("bell412/limits/power_ac_load_nom").getValue();
		m.POWER_ACLOAD_MIN = props.globals.getNode("bell412/limits/power_ac_load_min").getValue();
		m.POWER_ACLOAD_MAX = props.globals.getNode("bell412/limits/power_ac_load_max").getValue();
		m.POWER_AMLOAD_NOM = props.globals.getNode("bell412/limits/power_am_load_nom").getValue();
		m.POWER_AMLOAD_MIN = props.globals.getNode("bell412/limits/power_am_load_min").getValue();
		m.POWER_AMLOAD_MAX = props.globals.getNode("bell412/limits/power_am_load_max").getValue();

		m.ENGINE_RPM_CBOX_MAX 	= props.globals.getNode("bell412/limits/engine_rpm_cbox_max").getValue();
		m.ENGINE_RPM_N2_MAX 	= props.globals.getNode("bell412/limits/engine_rpm_n2_max").getValue();

		print("[Bell-412] + Limitations: const initialized.");
		return m;
	},
};

var LIMITS = Limitations.new();


