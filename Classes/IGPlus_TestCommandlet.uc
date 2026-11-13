class IGPlus_TestCommandlet extends Commandlet;

function LogTestResult(bool Result, string TestName) {
	if (Result)
		Log(TestName@"succeeded");
	else
		Warn(TestName@"failed");
}

function bool TestDataBuffer() {
	LogTestResult(DataBuffer_by_default_is_empty(), "DataBuffer_by_default_is_empty");
	LogTestResult(DataBuffer_stores_bits(), "DataBuffer_stores_bits");
	LogTestResult(DataBuffer_stores_more_than_32_bits(), "DataBuffer_stores_more_than_32_bits");

	LogTestResult(Can_pass_buffer_to_functions(), "Can_pass_buffer_to_functions");

	return true;
}

function bool TestFunction(int test[3], int expected0, int expected1, int expected2) {
	return test[0] == expected0 && test[1] == expected1 && test[2] == expected2;
}

function bool Can_pass_buffer_to_functions() {
	local int buffer[3];

	buffer[0] = 0xDEADBEEF;
	buffer[1] = 0xC0FFEE;
	buffer[2] = 0xBAADD00D;

	return TestFunction(buffer, buffer[0], buffer[1], buffer[2]);
}

function bool DataBuffer_by_default_is_empty() {
	local IGPlus_DataBuffer B;
	B = new class'IGPlus_DataBuffer';

	return B.NumBits == 0;
}

function bool DataBuffer_stores_bits() {
	local IGPlus_DataBuffer B;
	local int Result;
	B = new class'IGPlus_DataBuffer';

	B.AddBits(3, 0xFF);
	B.ConsumeBits(3, Result);

	return B.NumBits == 3 && Result == 0x7;
}

function bool DataBuffer_stores_more_than_32_bits() {
	local IGPlus_DataBuffer B;
	local int Result;
	B = new class'IGPlus_DataBuffer';

	B.AddBits(32, 0xDEADBEEF);
	B.AddBits(16, 0xDEADBEEF);
	B.AddBits(8, 0xBA);
	B.AddBits(32, 0xC0FFEE);
	B.AddBits(16, 0xDEAD);
	B.AddBits(32, 0xDEADBEEF);

	// if (B.NumBits != 80) return false;

	// if (B.BitsData[0] != 0xDEADBEEF) return false;
	// if (B.BitsData[1] != 0xFFEEBEEF) return false;
	// if (B.BitsData[2] != 0x00C0) return false;

	Log(B.BitsData[0]@B.BitsData[1]@B.BitsData[2]);

	B.ConsumeBits(32, Result);
	Log("Result 1"@Result);
	if (Result != 0xDEADBEEF) return false;

	B.ConsumeBits(16, Result);
	Log("Result 2"@Result);
	if (Result != 0xBEEF) return false;

	B.ConsumeBits(8, Result);
	Log("Result 3"@Result);
	if (Result != 0xBA) return false;

	B.ConsumeBits(32, Result);
	Log("Result 4"@Result);
	if (Result != 0xC0FFEE) return false;

	B.ConsumeBits(16, Result);
	Log("Result 5"@Result);
	if (Result != 0xDEAD) return false;

	B.ConsumeBits(32, Result);
	Log("Result 6"@Result);
	if (Result != 0xDEADBEEF) return false;

	return B.NumBits == B.NumBitsConsumed;
}

function bool TestDetEffectiveAnimTime() {
	LogTestResult(
		Abs(class'bbPlayer'.static.IGPlus_DetEffectiveAnimTime(0.25, 0.5) - 0.25) < 0.0001,
		"Det_anim_time_config_below_default"
	);
	LogTestResult(
		Abs(class'bbPlayer'.static.IGPlus_DetEffectiveAnimTime(0.75, 0.5) - 0.75) < 0.0001,
		"Det_anim_time_config_above_default"
	);
	LogTestResult(
		Abs(class'bbPlayer'.static.IGPlus_DetEffectiveAnimTime(0.0, 0.5) - 0.005) < 0.0001,
		"Det_anim_time_zero_config_hits_speed_cap"
	);
	LogTestResult(
		Abs(class'bbPlayer'.static.IGPlus_DetEffectiveAnimTime(0.001, 0.5) - 0.005) < 0.0001,
		"Det_anim_time_tiny_config_hits_speed_cap"
	);
	return true;
}

function TestTranslocatorFireMerging() {
	LogTestResult(!class'ST_Translocator'.static.CanMergeFireInput(true, false, false, true),
		"Translocator_throw_then_teleport_stays_separate");
	LogTestResult(!class'ST_Translocator'.static.CanMergeFireInput(false, true, true, false),
		"Translocator_teleport_then_throw_stays_separate");
	LogTestResult(!class'ST_Translocator'.static.CanMergeFireInput(true, false, false, false),
		"Translocator_primary_release_stays_separate");
	LogTestResult(!class'ST_Translocator'.static.CanMergeFireInput(false, true, false, false),
		"Translocator_alt_release_stays_separate");
	LogTestResult(!class'ST_Translocator'.static.CanMergeFireInput(true, true, true, false),
		"Translocator_dual_hold_release_stays_separate");
	LogTestResult(class'ST_Translocator'.static.CanMergeFireInput(true, true, true, true),
		"Translocator_real_dual_hold_is_preserved");
	LogTestResult(class'ST_Translocator'.static.CanMergeFireInput(true, false, true, false),
		"Translocator_unchanged_primary_hold_can_merge");
}

// Simulates 200 Hz moves against a server ticking every 10 ms. The client
// clock runs at ClientRate from HackAt on; a spike holds packets in flight
// and delivers them together. Returns the highest lead after the 2 s learn.
function float SimFireClockLead(float ClientRate, float Seconds, optional float SpikeAt, optional float SpikeLen, optional float HackAt) {
	local float Baseline, Lead, MaxLead, T, ClientT, ServerT, LastServerT;
	local int i, N;
	local bool bInit;

	N = int(Seconds / 0.005);
	for (i = 0; i < N; i++) {
		T = i * 0.005;
		if (T < HackAt)
			ClientT = T;
		else
			ClientT = HackAt + (T - HackAt) * ClientRate;
		if (SpikeLen > 0 && T >= SpikeAt && T < SpikeAt + SpikeLen)
			ServerT = SpikeAt + SpikeLen;
		else
			ServerT = T;
		ServerT = int(ServerT / 0.01) * 0.01;
		if (!bInit) {
			Baseline = ClientT - ServerT;
			bInit = true;
		} else {
			Baseline = class'bbPlayer'.static.IGPlus_DetNextClockBaseline(
				Baseline, ClientT - ServerT, ServerT - LastServerT, ServerT < 2.0);
		}
		LastServerT = ServerT;
		Lead = (ClientT - ServerT) - Baseline;
		if (ServerT >= 2.0)
			MaxLead = FMax(MaxLead, Lead);
	}
	return MaxLead;
}

function TestDetFireClockLead() {
	LogTestResult(SimFireClockLead(1.0, 10.0) < 0.02, "FireClockLead_synced_clock_stays_near_zero");
	LogTestResult(SimFireClockLead(1.005, 60.0) < 0.05, "FireClockLead_small_drift_is_absorbed");
	LogTestResult(SimFireClockLead(1.0, 30.0, 5.0, 1.0) < 0.05, "FireClockLead_1s_lag_spike_never_builds_lead");
	LogTestResult(SimFireClockLead(1.0, 10.0, 0.0, 1.5) < 0.05, "FireClockLead_hitch_while_connecting_is_learned");
	LogTestResult(SimFireClockLead(1.5, 5.0, 0, 0, 3.0) > 0.5, "FireClockLead_speedhack_exceeds_default_margin_within_2s");
}

function TestPreciseRewindTimeReport() {
	LogTestResult(class'bbPlayer'.static.IGPlus_PRTTicksBack(500, class'bbPlayer'.static.IGPlus_PRTPack(497, 0.0123)) == 3,
		"PRT_report_finds_its_tick");
	LogTestResult(Abs(class'bbPlayer'.static.IGPlus_PRTAge(class'bbPlayer'.static.IGPlus_PRTPack(497, 0.0123)) - 0.0123) < 0.0001,
		"PRT_report_keeps_its_age");
	LogTestResult(class'bbPlayer'.static.IGPlus_PRTTicksBack(32772, class'bbPlayer'.static.IGPlus_PRTPack(32770, 0)) == 2,
		"PRT_report_tick_survives_wrap");
	LogTestResult(class'bbPlayer'.static.IGPlus_PRTTicksBack(10, class'bbPlayer'.static.IGPlus_PRTPack(12, 0)) >= 64,
		"PRT_report_from_the_future_is_too_old");
	LogTestResult(Abs(class'bbPlayer'.static.IGPlus_PRTAge(class'bbPlayer'.static.IGPlus_PRTPack(5, 9.0)) - 6.5535) < 0.0001,
		"PRT_report_long_age_clamps_and_stays_positive");
	LogTestResult((class'bbPlayer'.static.IGPlus_PRTPack(0, 0) & 0x8000) != 0,
		"PRT_report_is_always_marked");
}

// A traded shot leaves from the client's spot only within this reach of
// where we died (stock speeds: dodge 600, JumpZ 325, accel 2048, gravity 950).
function TestTradeReach() {
	LogTestResult(class'bbPlayer'.static.IGPlus_TradeReach(440, 600, 325, 2048, 950, 0.0) == 16.0,
		"TradeReach_no_time_allows_16uu");
	// Running at 440, dodging sideways for 0.15s: about 113uu.
	LogTestResult(class'bbPlayer'.static.IGPlus_TradeReach(440, 600, 325, 2048, 950, 0.15) > 113.0,
		"TradeReach_covers_a_dodge_while_running");
	LogTestResult(class'bbPlayer'.static.IGPlus_TradeReach(0, 600, 325, 2048, 950, 0.1) < 150.0,
		"TradeReach_standing_still_stays_under_150uu_in_0.1s");
}

// A shot's eye height and its move's time share one int (bbPlayer.SendSavedMove).
function TestShotEyePacking() {
	local int P;

	LogTestResult(class'bbPlayer'.static.IGPlus_EyeUnpack(class'bbPlayer'.static.IGPlus_EyePack(27.0)) == 27.0,
		"ShotEye_default_eye_height_survives");
	LogTestResult(Abs(class'bbPlayer'.static.IGPlus_EyeUnpack(class'bbPlayer'.static.IGPlus_EyePack(12.37)) - 12.37) <= 0.25,
		"ShotEye_is_within_a_quarter_unit");
	LogTestResult(Abs(class'bbPlayer'.static.IGPlus_EyeUnpack(class'bbPlayer'.static.IGPlus_EyePack(-14.85)) + 14.85) <= 0.25,
		"ShotEye_below_the_body_centre_survives");
	LogTestResult(class'bbPlayer'.static.IGPlus_EyePack(-500.0) == 1 && class'bbPlayer'.static.IGPlus_EyePack(500.0) == 255,
		"ShotEye_clamps_and_is_never_zero");
	P = class'bbPlayer'.static.IGPlus_PackDeltaEye(0.016, 150);
	LogTestResult(Abs(class'bbPlayer'.static.IGPlus_UnpackDelta(P) - 0.016) < 0.00002 && (P >>> 24) == 150 && (P & 0xFF) == 0,
		"MoveDelta_and_eye_unpack_apart");
	P = class'bbPlayer'.static.IGPlus_PackDeltaEye(0.4, 255);
	LogTestResult(Abs(class'bbPlayer'.static.IGPlus_UnpackDelta(P) - 0.4) < 0.00002 && (P >>> 24) == 255,
		"MoveDelta_longest_frame_with_highest_eye");
	P = class'bbPlayer'.static.IGPlus_PackDeltaEye(5.0, 0);
	LogTestResult(class'bbPlayer'.static.IGPlus_UnpackDelta(P) < 1.0 && class'bbPlayer'.static.IGPlus_UnpackDelta(P) > 0.999 && (P >>> 24) == 0,
		"MoveDelta_clamps_under_a_second_and_leaves_the_eye_alone");
}

// Where the client's own trace stands another player (bbPlayer.IGPlus_PRTRulePos).
function TestPRTRulePos() {
	LogTestResult(VSize(class'bbPlayer'.static.IGPlus_PRTRulePos(vect(100,200,300), vect(400,0,-100), 0.02, false) - vect(108,200,298)) < 0.001,
		"PRTRule_carries_the_update_on_by_its_velocity");
	LogTestResult(class'bbPlayer'.static.IGPlus_PRTRulePos(vect(100,200,300), vect(400,0,0), 0.0, false) == vect(100,200,300),
		"PRTRule_no_time_past_the_update_is_the_update");
	LogTestResult(VSize(class'bbPlayer'.static.IGPlus_PRTRulePos(vect(0,0,0), vect(1000,0,0), 5.0, false) - vect(200,0,0)) < 0.001,
		"PRTRule_carry_is_capped_at_200ms");
	LogTestResult(class'bbPlayer'.static.IGPlus_PRTRulePos(vect(7,8,9), vect(1000,0,0), 0.5, true) == vect(7,8,9),
		"PRTRule_a_held_player_stays_at_the_update");
	// Update and tick counter came in one frame, 4 ms before the shown frame.
	LogTestResult(Abs(class'bbPlayer'.static.IGPlus_PRTRuleAge(10.004, 10.0) - 0.004) < 0.00001,
		"PRTRuleAge_is_the_time_since_the_update");
	// No update for 40 ms: the server carries its old snapshot for all of it.
	LogTestResult(Abs(class'bbPlayer'.static.IGPlus_PRTRuleAge(10.040, 10.0) - 0.040) < 0.00001,
		"PRTRuleAge_a_stalled_player_is_carried_for_the_whole_stall");
	LogTestResult(class'bbPlayer'.static.IGPlus_PRTRuleAge(9.9, 10.0) == 0.0,
		"PRTRuleAge_never_negative");
	LogTestResult(class'bbPlayer'.static.IGPlus_Fmt1(12.34) == "12.3" && class'bbPlayer'.static.IGPlus_Fmt1(-0.26) == "-0.3"
		&& class'bbPlayer'.static.IGPlus_Fmt1(-0.04) == "0.0" && class'bbPlayer'.static.IGPlus_Fmt1(7.96) == "8.0",
		"Fmt1_one_decimal_with_sign");
	// A line along X at height 0. A body 20 to the side with radius 17 is 3 away.
	LogTestResult(Abs(class'bbPlayer'.static.IGPlus_LineCylinderGap(vect(0,0,0), vect(1,0,0), vect(500,20,0), 17, 39) - 3.0) < 0.001,
		"LineCylinderGap_side");
	LogTestResult(class'bbPlayer'.static.IGPlus_LineCylinderGap(vect(0,0,0), vect(1,0,0), vect(500,10,30), 17, 39) == 0.0,
		"LineCylinderGap_inside_is_zero");
	LogTestResult(Abs(class'bbPlayer'.static.IGPlus_LineCylinderGap(vect(0,0,0), vect(1,0,0), vect(500,0,50), 17, 39) - 11.0) < 0.001,
		"LineCylinderGap_above");
}

event int main(string Params) {
	TestDataBuffer();
	TestDetEffectiveAnimTime();
	TestTranslocatorFireMerging();
	TestDetFireClockLead();
	TestPreciseRewindTimeReport();
	TestTradeReach();
	TestShotEyePacking();
	TestPRTRulePos();
	return 0;
}
