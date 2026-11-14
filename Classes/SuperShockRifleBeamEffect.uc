class SuperShockRifleBeamEffect extends SuperShockRifleWeaponEffect
	abstract;

// The beam with no ring at its end. The shooter's own beam on a player while
// Hit Effect Source is Server: the ring follows when the server has counted
// the hit (SuperShockRifleRingEffect).

defaultproperties
{
	bPlayRing=False
}
