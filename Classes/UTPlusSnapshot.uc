class UTPlusSnapshot extends Object;

var vector Loc, Vel, Acc;
var rotator Rot, VR;
var float BaseEyeHeight;
var float EyeHeight;
var float DuckFraction;
var float CollisionRadius;
var float CollisionHeight;
var bool bBasedOnMover;
var Actor BaseMover;
var float MoverZ;

var bool bSnapCollideActors;
var bool bSnapBlockActors;
var bool bSnapBlockPlayers;
var bool bSnapProjTarget;

var float ServerTimeStamp;
// Jitter Compensation held the player still from this snapshot on (their
// move queue ran empty), and the other clients drew them standing there.
var bool bHeld;
var float ClientTimeStamp;

var name  AnimSequence;
var float AnimFrame;

defaultproperties
{
}