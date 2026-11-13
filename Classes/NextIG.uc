class NextIG extends ST_Mutator;
// Description="InstaGib with the deterministic SuperShockRifle"

// InstaGib on the IG+ weapons: everyone gets ST_SuperShockRifle, which fires
// on the server with ping compensation (and Precise Rewind Time, if on).
//
// The rules are NewNetIG's (an Arena with no weapon string):
// - Only the rifle we hand out and its ammo exist, and no other mutator can
//   take them away (AlwaysKeep). Both come full, as under an Arena.
// - Every weapon in the map is removed, rifles too.
// - No translocator, whatever the game setting says.
// - No health, armour, belt, invisibility or damage amplifier.
//
// Load this in place of ST_Mutator, not together with it: each brings its own
// weapon settings.

function InitializeWeapons() {
	WImp = Spawn(class'IGPlus_WeaponImplementationBase');
	WImp.InitWeaponSettings("WeaponSettingsInstaGib", 1);
}

// As Arena.AlwaysKeep.
function bool AlwaysKeep(Actor Other) {
	if (Other.IsA('ST_SuperShockRifle')) {
		Weapon(Other).PickupAmmoCount = Weapon(Other).AmmoName.Default.MaxAmmo;
		return true;
	}
	if (Other.IsA('SuperShockCore')) {
		Ammo(Other).AmmoAmount = Ammo(Other).MaxAmmo;
		return true;
	}
	return Super.AlwaysKeep(Other);
}

// No weapon is swapped: the only one left is the rifle we hand out.
function bool CheckReplaceWeapon(Actor A) {
	return false;
}

function bool CheckReplacement(Actor Other, out byte bSuperRelevant) {
	// As stock InstaGibDM.
	if (Other.IsA('TournamentHealth') || Other.IsA('UT_Shieldbelt')
		|| Other.IsA('Armor2') || Other.IsA('ThighPads')
		|| Other.IsA('UT_Invisibility') || Other.IsA('UDamage'))
		return false;

	// The rifle and its ammo never get here (AlwaysKeep).
	if (Other.IsA('Weapon') || Other.IsA('Ammo'))
		return false;

	return Super.CheckReplacement(Other, bSuperRelevant);
}

defaultproperties {
	DefaultWeapon=Class'ST_SuperShockRifle'
}
