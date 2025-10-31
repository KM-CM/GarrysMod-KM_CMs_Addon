/*
I Like to Call Player-Like Actors "Pawns". Inspired by Ubisoft's Unreal Engine's Name of The "Body" of a Thing.
But There is No Real Reason Other Than Me Sounding Cool.
*/

AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

if SERVER then
	include "Server.lua"
	include "Player.lua"
	include "Miscellaneous.lua"
end

scripted_ents.Register( ENT, "BaseActorPlayer" )