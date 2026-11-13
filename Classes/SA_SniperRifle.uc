class SA_SniperRifle extends ST_SniperRifle;

// NextSA's rifle. It is ST_SniperRifle with two rules of its own, kept here
// so the sniper of the other modes does not change with them. Both hold for
// client and server alike, because both read them off the weapon's class.
//
// - Client-side shell case and muzzle flash always, with no client setting:
//   NextSA's players come from the NewNet rifle, which has no such setting.
// - Instant hit feedback: the shooter's own trace plays the hit sound and
//   marker at the click (ST_SniperRifle.ClientTraceFire). The sniper is the
//   only weapon here, which the matching of the server's hit message needs.

simulated function bool IGPlus_ClientAnims(bbPlayer BP) {
	return BP != None;
}

simulated function bool IGPlus_InstantHitFeedback() {
	return true;
}

defaultproperties {
}
