COVER_PEEK_NONE = 0
COVER_BLINDFIRE_UP = 1
COVER_BLINDFIRE_LEFT = 2
COVER_BLINDFIRE_RIGHT = 3
COVER_FIRE_LEFT = 4
COVER_FIRE_RIGHT = 5

COVER_VARIANTS_CENTER = 0
COVER_VARIANTS_LEFT = 1
COVER_VARIANTS_RIGHT = 2

TRAVERSES_NONE = 0
TRAVERSES_WATER = 1
TRAVERSES_GROUND = 2
TRAVERSES_AIR = 4

if SERVER then
	__VEHICLE_TABLE__ = __VEHICLE_TABLE__ || {
		[ TRAVERSES_WATER ] = {},
		[ TRAVERSES_GROUND ] = {},
		[ TRAVERSES_AIR ] = {}
	}
end

local IsValid = IsValid

local hook = hook
local hook_Add = hook.Add
local hook_Remove = hook.Remove
function AddThinkToEntity( self, func )
	local n = EntityUniqueIdentifier( self )
	hook_Add( "Think", n, function()
		if !IsValid( self ) || func( self ) then hook_Remove( "Think", n ) end
	end )
end

//DO NOT EDIT THIS!
hook_Add( "HandlePlayerDrivingNew", "Base", function( ply, plyTable, pVehicle )
	if ( !pVehicle.HandleAnimation && pVehicle.GetVehicleClass ) then
		local c = pVehicle:GetVehicleClass()
		local t = list.Get( "Vehicles" )[ c ]
		if ( t && t.Members && t.Members.HandleAnimation ) then
			pVehicle.HandleAnimation = t.Members.HandleAnimation
		else
			pVehicle.HandleAnimation = true -- Prevent this if block from trying to assign HandleAnimation again.
		end
	end

	if ( isfunction( pVehicle.HandleAnimation ) ) then
		local seq = pVehicle:HandleAnimation( ply )
		if ( seq != nil ) then
			plyTable.CalcSeqOverride = seq
		end
	end

	if ( plyTable.CalcSeqOverride == -1 ) then -- pVehicle.HandleAnimation did not give us an animation
		local class = pVehicle:GetClass()
		if ( class == "prop_vehicle_jeep" ) then
			plyTable.CalcSeqOverride = ply:LookupSequence( "drive_jeep" )
		elseif ( class == "prop_vehicle_airboat" ) then
			plyTable.CalcSeqOverride = ply:LookupSequence( "drive_airboat" )
		elseif ( class == "prop_vehicle_prisoner_pod" && pVehicle:GetModel() == "models/vehicles/prisoner_pod_inner.mdl" ) then
			-- HACK!!
			plyTable.CalcSeqOverride = ply:LookupSequence( "drive_pd" )
		else
			plyTable.CalcSeqOverride = ply:LookupSequence( "sit_rollercoaster" )
		end
	end

	local use_anims = ( plyTable.CalcSeqOverride == ply:LookupSequence( "sit_rollercoaster" ) || plyTable.CalcSeqOverride == ply:LookupSequence( "sit" ) )
	if ( use_anims && ply:GetAllowWeaponsInVehicle() && IsValid( ply:GetActiveWeapon() ) ) then
		local holdtype = ply:GetActiveWeapon():GetHoldType()
		if ( holdtype == "smg" ) then holdtype = "smg1" end

		local seqid = ply:LookupSequence( "sit_" .. holdtype )
		if ( seqid != -1 ) then
			plyTable.CalcSeqOverride = seqid
		end
	end

	return true
end )

__PLAYER_MODEL__ = {}
local __PLAYER_MODEL__ = __PLAYER_MODEL__

local hook_Run = hook.Run
hook_Add( "CalcMainActivity", "Improvements", function( ply, vel )
	local veh = ply.GAME_pVehicle || ply:GetNW2Entity "GAME_pVehicle"
	if IsValid( veh ) then
		local t = ply:GetTable()
		hook_Run( "HandlePlayerDrivingNew", ply, t, veh )
		return t.CalcIdeal, t.CalcSeqOverride
	end
	local v = __PLAYER_MODEL__[ ply:GetModel() ]
	if v then
		v = v.CalcMainActivity
		if v then
			local t = ply:GetTable()
			local a, s = v( ply, t )
			t.CalcIdeal = a
			t.CalcSeqOverride = s
			return a, s
		end
	end
end )

hook.Add( "PlayerFootstep", "Improvements", function( ply, ... )
	local v = __PLAYER_MODEL__[ ply:GetModel() ]
	if v then
		v = v.PlayerFootstep
		if v then return v( ply, ... ) end
	end
end )

hook.Add( "PlayerSpawn", "Improvements", function( ply, ... )
	local v = __PLAYER_MODEL__[ ply:GetModel() ]
	if v then
		v = v.PlayerSpawn
		if v then return v( ply, ... ) end
	end
end )

hook.Add( "PlayerHandleAnimEvent", "Improvements", function( ply, ... )
	local v = __PLAYER_MODEL__[ ply:GetModel() ]
	if v then
		v = v.PlayerHandleAnimEvent
		if v then return v( ply, ... ) end
	end
end )

hook.Add( "TranslateActivity", "Improvements", function( ply, ... )
	local c = ply:GetModel()
	local v = __PLAYER_MODEL__[ c ]
	if v then
		v = v.TranslateActivity
		if v then return v( ply, ... ) end
	end
end )

hook.Add( "GetFallDamage", "Improvements", function( ply, ... )
	local c = ply:GetModel()
	local v = __PLAYER_MODEL__[ c ]
	if v then
		v = v.GetFallDamage
		if v then return v( ply, ... ) end
	end
end )

hook.Add( "CalcView", "Improvements", function( ply, ... )
	local c = ply:GetModel()
	local v = __PLAYER_MODEL__[ c ]
	if v then
		v = v.CalcView
		if v then return v( ply, ... ) end
	end
end )

local CEntity = FindMetaTable "Entity"
local CEntity_GetOwner = CEntity.GetOwner
function GetOwner( self )
	local owner = CEntity_GetOwner( self )
	if IsValid( owner ) then return GetOwner( owner ) end
	return self
end

local CEntity_GetTable = CEntity.GetTable
local CEntity_GetVelocity = CEntity.GetVelocity
local CEntity_GetPhysicsObject = CEntity.GetPhysicsObject
local Vector = Vector
function GetVelocity( ent )
	local EntTable = CEntity_GetTable( ent )
	local v = EntTable.GAME_pVehicle
	if IsValid( v ) then return GetVelocity( v ) end
	if EntTable.__GetVelocity__ then return EntTable:__GetVelocity__() end
	if ent:IsPlayer() || ent:IsNPC() then return CEntity_GetVelocity( ent ) else
		if ent:IsNextBot() then return EntTable.loco:GetVelocity() end
		local phys = CEntity_GetPhysicsObject( ent )
		if IsValid( phys ) then return phys:GetVelocity() end
	end
	return Vector( 0, 0, 0 )
end

for _, n in ipairs( file.Find( "Player/*.lua", "LUA" ) ) do ProtectedCall( function() include( "Player/" .. n ) end ) end
