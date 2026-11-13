class IGPlus_HitFeedbackMessage extends LocalMessage;

const DMG_Disabled = 0;
const DMG_SpecOnly = 1;
const DMG_AlwaysHUD = 2;
const DMG_AlwaysHUDConsole = 3;

static function ClientReceive(
	PlayerPawn P,
	optional int Sw,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
) {
	local ClientSettings Settings;
	local bool bInstigator;
	local bool bViewTarget;
	local bool bServerOnly;
	local bool bClientPlayed;
	local bbPlayer bbP;
	
	bbP = bbPlayer(P);

	if (RelatedPRI_1 == none || RelatedPRI_2 == none)
		return;

	if (RelatedPRI_1 == RelatedPRI_2)
		return; // self-damage doesnt need feedback

	if (P.IsA('bbPlayer'))
		Settings = bbPlayer(P).Settings;
	else if (P.IsA('bbCHSpectator'))
		Settings = bbCHSpectator(P).Settings;

	bInstigator = RelatedPRI_2.Owner == P;
	bViewTarget = RelatedPRI_2.Owner == P.ViewTarget;

	if ((bInstigator || bViewTarget) == false)
		return;

	// The Client source only counts while we carry a weapon that plays its own
	// hit response (bbPlayer.IGPlus_HasClientHitResponse). With any other
	// weapon nothing would play at all.
	bServerOnly = bViewTarget || Settings == none || bbP == none || bbP.IGPlus_HasClientHitResponse() == false;
	// A deterministic shot whose own trace played this hit at the click
	// (bbPlayer.IGPlus_ClientShotVerdict): what the Client source played then
	// is not played again. A hit only the server saw plays here, a ping late.
	bClientPlayed = bInstigator && Settings != none && bbP != none && bbP.IGPlus_TakeClientHit();
	if (bClientPlayed)
		bServerOnly = false;

	if (bServerOnly || Settings.HitMarkerSource == HMSRC_Server)
		class'bbPlayerStatics'.static.PlayHitMarker(P, Settings, Abs(Sw), RelatedPRI_2.Team, RelatedPRI_1.Team);


	if (bbP != none && (bbP.ShowDamageNumberMode == DMG_AlwaysHUD || bbP.ShowDamageNumberMode == DMG_AlwaysHUDConsole))
		class'bbPlayerStatics'.static.PlayDamageMarker(P, Abs(Sw), RelatedPRI_2.Team, RelatedPRI_1.Team, RelatedPRI_1);
	else if (bViewTarget && bbCHSpectator(P) != none && Settings != none && Settings.bSpectatorShowDamageNumbers && bbCHSpectator(P).ShowDamageNumberMode != DMG_Disabled)
		class'bbPlayerStatics'.static.PlayDamageMarker(P, Abs(Sw), RelatedPRI_2.Team, RelatedPRI_1.Team, RelatedPRI_1);

	if (bServerOnly || Settings.HitSoundSource == HSSRC_Server)
		class'bbPlayerStatics'.static.PlayHitSound(P, Settings, Abs(Sw), RelatedPRI_2.Team, RelatedPRI_1.Team);
}
