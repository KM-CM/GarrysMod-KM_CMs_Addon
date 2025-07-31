AddCSLuaFile()
DEFINE_BASECLASS "base_nextbot"

ENT.__ACTOR__ = true

if SERVER then
	include "Server.lua"
	include "Aim.lua"
	include "Disposition.lua"
	include "Vehicles.lua"
	include "Weapons.lua"
	include "Senses.lua"
	include "Schedule.lua"
	include "Path.lua"
	include "Suppressed.lua"
	include "CombatState.lua"
	include "Script.lua"
end

scripted_ents.Register( ENT, "BaseActor" )