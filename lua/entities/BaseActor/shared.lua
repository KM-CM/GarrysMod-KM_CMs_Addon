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
	include "Search.lua"
	include "Behaviour.lua"
	include "Animation.lua"

	local CEntity_SetNWVector = FindMetaTable( "Entity" ).SetNWVector
	function ENT:SetPlayerColor( v ) CEntity_SetNWVector( self, "m_vcPlayerColor", v ) end
end

local CEntity_GetNWVector = FindMetaTable( "Entity" ).GetNWVector
// Such a bright fallback because that means unset.
// In simpler words, we're trying to scream "ERROR!!!"
local v = Vector( 1, 1, 1 )
function ENT:GetPlayerColor() return CEntity_GetNWVector( self, "m_vcPlayerColor", v ) end

scripted_ents.Register( ENT, "BaseActor" )