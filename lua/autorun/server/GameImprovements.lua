local math = math
local math_Remap = math.Remap
function GetFlameStopChance( self ) return math_Remap( GetVelocity( self ):Length(), 0, 800, 20000, 1000 ) end

concommand.Add( "+drop", function() end )
concommand.Add( "-drop", function( ply ) ply:DropWeapon() end )

ACCELERATION_NORMAL = 5
ACCELERATION_ACTUAL = ACCELERATION_NORMAL

HUMAN_RUN_SPEED, HUMAN_PROWL_SPEED, HUMAN_WALK_SPEED = 300, 200, 75

RunConsoleCommand( "sv_accelerate", ACCELERATION_NORMAL )
RunConsoleCommand( "sv_friction", "4" )

HULL_HUMAN_MINS, HULL_HUMAN_MAXS = Vector( -16, -16, 0 ), Vector( 16, 16, 72 )
HULL_HUMAN_DUCK_MINS, HULL_HUMAN_DUCK_MAXS = Vector( -16, -16, 0 ), Vector( 16, 16, 36 )

function HasRangeAttack( ent )
	if ent.HAS_RANGE_ATTACK then return true end
	if ent.HAS_NOT_RANGE_ATTACK then return end
	if ent.CapabilitiesGet then
		local c = ent:CapabilitiesGet()
		if bit.band( c, CAP_WEAPON_RANGE_ATTACK1 ) != 0 ||
		bit.band( c, CAP_WEAPON_RANGE_ATTACK2 ) != 0 ||
		bit.band( c, CAP_INNATE_RANGE_ATTACK1 ) != 0 ||
		bit.band( c, CAP_INNATE_RANGE_ATTACK2 ) != 0 then return true end
	end
	if ent.tWeapons then
		for wep in pairs( ent.tWeapons ) do
			if !wep.GetCapabilities then continue end
			local c = wep:GetCapabilities()
			if bit.band( c, CAP_WEAPON_RANGE_ATTACK1 ) != 0 ||
			bit.band( c, CAP_WEAPON_RANGE_ATTACK2 ) != 0 ||
			bit.band( c, CAP_INNATE_RANGE_ATTACK1 ) != 0 ||
			bit.band( c, CAP_INNATE_RANGE_ATTACK2 ) != 0 then return true end
		end
	elseif ent.GetWeapons then
		for _, wep in ipairs( ent:GetWeapons() ) do
			if !wep.GetCapabilities then continue end
			local c = wep:GetCapabilities()
			if bit.band( c, CAP_WEAPON_RANGE_ATTACK1 ) != 0 ||
			bit.band( c, CAP_WEAPON_RANGE_ATTACK2 ) != 0 ||
			bit.band( c, CAP_INNATE_RANGE_ATTACK1 ) != 0 ||
			bit.band( c, CAP_INNATE_RANGE_ATTACK2 ) != 0 then return true end
		end
	end
end
function HasMeleeAttack( ent )
	if ent.HAS_MELEE_ATTACK || IsValid( ent.GAME_pVehicle ) then return true end
	if ent.HAS_NOT_MELEE_ATTACK then return end
	if ent.CapabilitiesGet then
		local c = ent:CapabilitiesGet()
		if bit.band( c, CAP_WEAPON_MELEE_ATTACK1 ) != 0 ||
		bit.band( c, CAP_WEAPON_MELEE_ATTACK2 ) != 0 ||
		bit.band( c, CAP_INNATE_MELEE_ATTACK1 ) != 0 ||
		bit.band( c, CAP_INNATE_MELEE_ATTACK2 ) != 0 then return true end
	end
	if ent.tWeapons then
		for wep in pairs( ent.tWeapons ) do
			if !wep.GetCapabilities then continue end
			local c = wep:GetCapabilities()
			if bit.band( c, CAP_WEAPON_MELEE_ATTACK1 ) != 0 ||
			bit.band( c, CAP_WEAPON_MELEE_ATTACK2 ) != 0 ||
			bit.band( c, CAP_INNATE_MELEE_ATTACK1 ) != 0 ||
			bit.band( c, CAP_INNATE_MELEE_ATTACK2 ) != 0 then return true end
		end
	elseif ent.GetWeapons then
		for _, wep in ipairs( ent:GetWeapons() ) do
			if !wep.GetCapabilities then continue end
			local c = wep:GetCapabilities()
			if bit.band( c, CAP_WEAPON_MELEE_ATTACK1 ) != 0 ||
			bit.band( c, CAP_WEAPON_MELEE_ATTACK2 ) != 0 ||
			bit.band( c, CAP_INNATE_MELEE_ATTACK1 ) != 0 ||
			bit.band( c, CAP_INNATE_MELEE_ATTACK2 ) != 0 then return true end
		end
	end
end

//Intentionally Generates UUIDs Instead of Truly Unique Numbers for Extremely Rare Funni Bugs
function EntityUniqueIdentifier( ent )
	if ent.__UNIQUE_IDENTIFIER__ then return ent.__UNIQUE_IDENTIFIER__ end
	local t = {}
	for _ = 1, 16 do
		local i = math.random( 1, 3 )
		if i == 1 then table.insert( t, string.char( math.random( 65, 90 ) ) ) //A-Z
		elseif i == 2 then table.insert( t, string.char( math.random( 97, 122 ) ) ) //a-z
		else table.insert( t, math.random( 0, 9 ) ) end
	end
	ent.__UNIQUE_IDENTIFIER__ = table.concat( t )
	return ent.__UNIQUE_IDENTIFIER__
end

local tIgnoreRagneAttackDisp = { [ D_NU ] = true, [ D_LI ] = true }
local util_ScreenShake, util_DistanceToLine = util.ScreenShake, util.DistanceToLine
RANGE_ATTACK_SUPPRESSION_BOUND_SIZE = 512
function DispatchRangeAttack( Owner, vStart, vEnd, flDamage )
	local flAmplitude, flFrequency, flDuration = flDamage * .024, flDamage * .0016, math.min( 4, flDamage * .1 )
	local ang = ( vEnd - vStart ):Angle()
	for _, ent in ipairs( ents.FindAlongRay( vStart, vEnd, Vector( -RANGE_ATTACK_SUPPRESSION_BOUND_SIZE, -RANGE_ATTACK_SUPPRESSION_BOUND_SIZE, -RANGE_ATTACK_SUPPRESSION_BOUND_SIZE ), Vector( RANGE_ATTACK_SUPPRESSION_BOUND_SIZE, RANGE_ATTACK_SUPPRESSION_BOUND_SIZE, RANGE_ATTACK_SUPPRESSION_BOUND_SIZE ) ) ) do
		if ent == Owner || Owner.Disposition && Owner:Disposition( ent ) == D_LI || ent.Disposition && ent:Disposition( Owner ) == D_LI then continue end
		if ent.GAME_tSuppressionAmount then
			ent.GAME_tSuppressionAmount[ Owner ] = ( ent.GAME_tSuppressionAmount[ Owner ] || 0 ) + flDamage
		else ent.GAME_tSuppressionAmount = { [ Owner ] = flDamage } end
		local f = ent.GAME_OnRangeAttacked
		if f == nil then if ent.GAME_flSuppression then ent.GAME_flSuppression = ent.GAME_flSuppression + flDamage end else f( ent, Owner, vStart, vEnd, flDamage ) end
		/*if ent:IsPlayer() then
			local f = RecipientFilter()
			f:AddPlayer( ent )
			util_ScreenShake( ent:GetPos(), flAmplitude, flFrequency, flDuration, 256, true, f )
		else*/if ent.__ACTOR__ then
			if ent == Owner || Owner.Disposition && Owner:Disposition( ent ) == D_LI || ent.Disposition && ent:Disposition( Owner ) == D_LI then continue end
			local _, v = util_DistanceToLine( vStart, vEnd, ent:EyePos() )
			if ent:CanSee( v ) then ent:SetupBullseye( Owner, vStart, ang ) end
		end
	end
	/*Too Cheaty - Makes Silencers Almost Completely UseLess
	local ang = ( vEnd - vStart ):Angle()
	for ent in pairs( __ACTOR_LIST__ ) do
		if ent == Owner || Owner.Disposition && tIgnoreRagneAttackDisp[ Owner:Disposition( ent ) ] || ent.Disposition && tIgnoreRagneAttackDisp[ ent:Disposition( Owner ) ] then continue end
		local _, v = util_DistanceToLine( vStart, vEnd, ent:EyePos() )
		if ent:CanSee( v ) then ent:SetupBullseye( Owner, vStart, ang ) end
	end
	*/
end

__TRACER_COLOR__ = {
	Bullet = "255 48 0 1024",
	AR2Tracer = "48 255 255 1024"
}
local __TRACER_COLOR__ = __TRACER_COLOR__

local IsValid = IsValid

hook.Add( "EntityFireBullets", "GameImprovements", function( ent, Data, _Comp )
	if _Comp then return end
	hook.Run( "EntityFireBullets", ent, Data, true )
	if Data.AmmoType != "" then Data.Damage = game.GetAmmoPlayerDamage( game.GetAmmoID( Data.AmmoType ) ) end
	local OldCallBack = Data.Callback || function() return { damage = true, effects = true } end
	local flDamage = Data.Damage
	local col = __TRACER_COLOR__[ Data.TracerName || "Bullet" ] || __TRACER_COLOR__[ "Bullet" ]
	Data.Callback = function( atk, tr, dmg )
		DispatchRangeAttack( atk, tr.StartPos, tr.HitPos, flDamage )
		local pt = ents.Create "env_projectedtexture"
		pt:SetPos( tr.StartPos )
		pt:SetAngles( ( tr.HitPos - tr.StartPos ):GetNormalized():Angle() )
		pt:SetKeyValue( "lightfov", "110" )
		pt:SetKeyValue( "lightcolor", col )
		pt:SetKeyValue( "spritedisabled", "1" )
		pt:SetKeyValue( "farz", "256" )
		pt:Input( "SpotlightTexture", _, _, "effects/flashlight/soft" )
		pt:Spawn()
		timer.Simple( .1, function() if IsValid( pt ) then pt:Remove() end end )
		return OldCallBack( atk, tr, dmg )
	end
	return true
end )

local PersistAll = CreateConVar( "PersistAll", 1, FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_NOTIFY + FCVAR_ARCHIVE, "Everything Persists", 0, 1 )

hook.Add( "PhysgunPickup", "GameImprovements", function() return true end )

local ents = ents
local ents_Iterator = ents.Iterator
hook.Add( "Think", "GameImprovements", function()
	for _, ent in ents_Iterator() do
		if PersistAll:GetBool() && ent:MapCreationID() != -1 && !ent:IsPlayer() && ( !ent:IsWeapon() || ent:IsWeapon() && ( !IsValid( ent:GetOwner() ) || IsValid( ent:GetOwner() ) && !ent:GetOwner():IsPlayer() ) ) then ent:SetPersistent( true ) end
		local tSuppressionAmount = {}
		if ent.GAME_tSuppressionAmount then
			for ent, am in pairs( ent.GAME_tSuppressionAmount ) do
				if IsValid( ent ) then
					am = math.Approach( am, 0, math.max( 1, am * .33 ) * FrameTime() )
					if am <= 0 then continue end
					tSuppressionAmount[ ent ] = am
				end
			end
		end
		ent.GAME_tSuppressionAmount = tSuppressionAmount
	end
end )

local FixBunnyHop = CreateConVar( "FixBunnyHop", 1, FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_NOTIFY, "Fixes Bunny Hopping by Not Allowing The Player to Jump The a Few MilliSeconds After He Hit The Ground", 0, 1 )
local FixBunnyHopLength = CreateConVar( "FixBunnyHopLength", .1, FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_NOTIFY, "The Amount of FixBunnyHop", 0, 1 )
local tFixBunnyHop = {}
local CEntity = FindMetaTable "Entity"
local CEntity_IsOnGround = CEntity.IsOnGround
local math_max = math.max
local util_TraceLine = util.TraceLine
local CEntity_WaterLevel = CEntity.WaterLevel
local CEntity_Remove = CEntity.Remove
local CPlayer = FindMetaTable "Player"
local CPlayer_GetRunSpeed = CPlayer.GetRunSpeed
local CPlayer_Give = CPlayer.Give
local ents_Create = ents.Create
hook.Add( "StartCommand", "GameImprovements", function( ply, cmd )
	if !ply:Alive() then return end

	local p = ply:GetWeapon "Hands"
	if !IsValid( p ) then p = CPlayer_Give( ply, "Hands" ) end
	local veh = ply.GAME_pVehicle
	if IsValid( veh ) then
		if !ply.GAME_sRestoreGun then
			local w = ply:GetActiveWeapon()
			if IsValid( w ) then ply.GAME_sRestoreGun = w:GetClass() end
		end
		if veh.bDriverHoldingUse then
			if !cmd:KeyDown( IN_USE ) then
				veh.bDriverHoldingUse = nil
			end
		else
			if ply:KeyDown( IN_USE ) && veh:ExitVehicle( ply ) then return end
		end
		veh:PlayerControls( ply, cmd )
		cmd:AddKey( IN_DUCK )
		cmd:SelectWeapon( p )
		return
	end

	local bGround = CEntity_IsOnGround( ply )
	if !bGround && CEntity_WaterLevel( ply ) > 0 then
		if !ply.GAME_sRestoreGun then
			local w = ply:GetActiveWeapon()
			if IsValid( w ) then ply.GAME_sRestoreGun = w:GetClass() end
		end
		cmd:SelectWeapon( p )
		ply:SetNW2Bool( "CTRL_bSliding", false )
		return
	end

	local s = ply.GAME_sRestoreGun
	if s then
		local w = ply:GetWeapon( s )
		if IsValid( w ) then cmd:SelectWeapon( w ) end
		ply.GAME_sRestoreGun = nil
	end

	if FixBunnyHop:GetBool() then
		if bGround then
			if CurTime() <= ( tFixBunnyHop[ ply ] || 0 ) then
				cmd:RemoveKey( IN_JUMP )
			else tFixBunnyHop[ ply ] = nil end
		else tFixBunnyHop[ ply ] = CurTime() + FixBunnyHopLength:GetFloat() end
	else tFixBunnyHop[ ply ] = nil end

	if ply:GetNW2Bool "CTRL_bSliding" then cmd:RemoveKey( IN_ATTACK ) cmd:RemoveKey( IN_ATTACK2 ) end

	if cmd:KeyDown( IN_ZOOM ) then cmd:RemoveKey( IN_SPEED ) cmd:AddKey( IN_WALK ) end

	if ply:IsOnGround() then
		//Trash
		//if cmd:KeyDown( IN_DUCK ) && cmd:KeyDown( IN_JUMP ) then cmd:RemoveKey( IN_DUCK ) cmd:RemoveKey( IN_JUMP ) end
		if !ply:Crouching() && cmd:KeyDown( IN_SPEED ) then
			if cmd:GetForwardMove() <= 0 || b then
				ply:SetNW2Bool( "CTRL_bSprinting", false )
				cmd:RemoveKey( IN_SPEED )
			else
				cmd:SetForwardMove( CPlayer_GetRunSpeed( ply ) )
				if cmd:GetSideMove() < 0 then
					cmd:SetSideMove( -cmd:GetForwardMove() )
				elseif cmd:GetSideMove() > 0 then
					cmd:SetSideMove( cmd:GetForwardMove() )
				end
				local b = ply:GetVelocity():Length() > ply:GetWalkSpeed()
				ply:SetNW2Bool( "CTRL_bSprinting", b )
				if b then
					cmd:RemoveKey( IN_ATTACK )
					cmd:RemoveKey( IN_ATTACK2 )
					cmd:RemoveKey( IN_ZOOM )
				end
			end
		else ply:SetNW2Bool( "CTRL_bSprinting", false ) end
	else
		if CEntity_WaterLevel( ply ) <= 0 && !ply.CTRL_bAllowMovingWhileInAir && ply:GetMoveType() == MOVETYPE_WALK then
			//cmd:SetForwardMove( 0 )
			cmd:SetSideMove( 0 )
		end
		ply:SetNW2Bool( "CTRL_bSprinting", false )
	end

	local bInCover
	local bGunUsesCoverStance //Used in Very Special Circumstances
	local PEEK = COVER_PEEK_NONE
	local VARIANTS = COVER_VARIANTS_CENTER
	local EyeAngles = ply:EyeAngles()
	local EyeVector = EyeAngles:Forward()
	local EyeVectorFlat = EyeAngles:Forward()
	EyeVectorFlat.z = 0
	EyeVectorFlat:Normalize()
	local vView = ply:GetPos() + ply:GetViewOffset()
	local trStand = util_TraceLine {
		start = vView,
		endpos = vView + EyeVectorFlat * ply:OBBMaxs().x * 2,
		mask = MASK_SOLID,
		filter = ply
	}
	local vViewDucked = ply:GetPos() + ply:GetViewOffsetDucked() * .5
	local trDuck = util_TraceLine {
		start = vViewDucked,
		endpos = vViewDucked + EyeVectorFlat * ply:OBBMaxs().x * 2,
		mask = MASK_SOLID,
		filter = ply
	}
	if ply:IsOnGround() then
		if cmd:KeyDown( IN_DUCK ) then
			if trDuck.Hit then
				bInCover = true
			end
		else
			if trDuck.Hit && trStand.Hit then
				bInCover = true
			end
		end
	end
	if bInCover then
		if CurTime() > ( ply.CTRL_flCoverMoveTime || 0 ) then
			ply.CTRL_bMovingLeft = nil
			ply.CTRL_bMovingRight = nil
		end
		local b
		local bLeft, bRight
		if cmd:KeyDown( IN_DUCK ) && trDuck.Hit then
			local vStart = vViewDucked
			local vec = vStart - trDuck.HitNormal:Angle():Right() * ply:OBBMaxs().x * 2
			if util_TraceLine( {
				start = vStart,
				endpos = ply:GetPos() - Vector( 0, 0, 12 ),
				mask = MASK_SOLID,
				filter = ply
			} ).Hit && !util_TraceLine( {
				start = vStart,
				endpos = vec,
				mask = MASK_SOLID,
				filter = ply
			} ).Hit then
				bLeft = util_TraceLine( {
					start = vec,
					endpos = vec + EyeVectorFlat * ply:OBBMaxs().x * 2,
					mask = MASK_SOLID,
					filter = ply
				} ).Hit
			end
			local vec = vStart + trDuck.HitNormal:Angle():Right() * ply:OBBMaxs().x * 2
			if util_TraceLine( {
				start = vStart,
				endpos = ply:GetPos() - Vector( 0, 0, 12 ),
				mask = MASK_SOLID,
				filter = ply
			} ).Hit && !util_TraceLine( {
				start = vStart,
				endpos = vec,
				mask = MASK_SOLID,
				filter = ply
			} ).Hit then
				bRight = util_TraceLine( {
					start = vec,
					endpos = vec + EyeVectorFlat * ply:OBBMaxs().x * 2,
					mask = MASK_SOLID,
					filter = ply
				} ).Hit
			end
		else
			local vStart = vView
			local vec = vStart - trDuck.HitNormal:Angle():Right() * ply:OBBMaxs().x * 2
			if util_TraceLine( {
				start = vStart,
				endpos = ply:GetPos() - Vector( 0, 0, 12 ),
				mask = MASK_SOLID,
				filter = ply
			} ).Hit && !util_TraceLine( {
				start = vStart,
				endpos = vec,
				mask = MASK_SOLID,
				filter = ply
			} ).Hit then
				bLeft = util_TraceLine( {
					start = vec,
					endpos = vec + EyeVectorFlat * ply:OBBMaxs().x * 2,
					mask = MASK_SOLID,
					filter = ply
				} ).Hit
			end
			local vec = vStart + trDuck.HitNormal:Angle():Right() * ply:OBBMaxs().x * 2
			if util_TraceLine( {
				start = vStart,
				endpos = ply:GetPos() - Vector( 0, 0, 12 ),
				mask = MASK_SOLID,
				filter = ply
			} ).Hit && !util_TraceLine( {
				start = vStart,
				endpos = vec,
				mask = MASK_SOLID,
				filter = ply
			} ).Hit then
				bRight = util_TraceLine( {
					start = vec,
					endpos = vec + EyeVectorFlat * ply:OBBMaxs().x * 2,
					mask = MASK_SOLID,
					filter = ply
				} ).Hit
			end
		end
		if bLeft && bRight then
		elseif bLeft then VARIANTS = COVER_VARIANTS_LEFT
		elseif bRight then VARIANTS = COVER_VARIANTS_RIGHT end
		if cmd:KeyDown( IN_ATTACK ) then b = true ply.CTRL_flCoverPeekTime = CurTime() + ply:GetUnDuckSpeed() end
		local bZoom = cmd:KeyDown( IN_ZOOM )
		if bZoom then ply.CTRL_bPeekZoom = true else ply.CTRL_bPeekZoom = nil end
		if bZoom || CurTime() <= ( ply.CTRL_flCoverPeekTime || 0 ) then
			cmd:RemoveKey( IN_SPEED )
			cmd:AddKey( IN_WALK )
			if trDuck.Hit && !trStand.Hit then
				local bDo = bLeft && bRight || !( bLeft || bRight )
				if !bDo then
					if ply.CTRL_bInCoverDuck then
						bDo = true
					else
						if EyeAngles.p < -10 then bDo = true end
					end
				end
				if bDo then
					bLeft, bRight = nil, nil
					if ply.CTRL_bInCoverDuck == nil then
						if b then ply.CTRL_flCoverDoShootTime = CurTime() + ply:GetUnDuckSpeed() end
						ply.CTRL_flCoverDontShootTime = CurTime() + ply:GetUnDuckSpeed()
					end
					bInCover = nil
					if ply.CTRL_bPeekZoom == nil then PEEK = COVER_BLINDFIRE_UP end
					ply.CTRL_bInCoverDuck = true
					cmd:RemoveKey( IN_DUCK )
				end
			else ply.CTRL_bInCoverDuck = nil end
			if bLeft && bRight then
			elseif bLeft then
				ply.CTRL_flCoverPeekTime = CurTime() + ply:GetUnDuckSpeed()
				ply.CTRL_flCoverMoveTime = CurTime() + ply:GetUnDuckSpeed()
				cmd:SetSideMove( -ply:GetRunSpeed() )
				ply.CTRL_bMovingLeft = true
				ply.CTRL_vCover = ply:GetPos()
				if !ply.CTRL_bPeekZoom && ( !ply.CTRL_flCoverDoShootTime || CurTime() <= ply.CTRL_flCoverDoShootTime ) then ply.CTRL_flCoverDoShootTime = CurTime() end
			elseif bRight then
				ply.CTRL_flCoverPeekTime = CurTime() + ply:GetUnDuckSpeed()
				ply.CTRL_flCoverMoveTime = CurTime() + ply:GetUnDuckSpeed()
				cmd:SetSideMove( ply:GetRunSpeed() )
				ply.CTRL_bMovingRight = true
				ply.CTRL_vCover = ply:GetPos()
				if !ply.CTRL_bPeekZoom && ( !ply.CTRL_flCoverDoShootTime || CurTime() <= ply.CTRL_flCoverDoShootTime ) then ply.CTRL_flCoverDoShootTime = CurTime() end
			end
			if CurTime() <= ( ply.CTRL_flCoverMoveTime || 0 ) then
				if ply.CTRL_bMovingLeft then
					PEEK = bZoom && COVER_FIRE_LEFT || COVER_BLINDFIRE_LEFT
				elseif ply.CTRL_bMovingRight then
					PEEK = bZoom && COVER_FIRE_RIGHT || COVER_BLINDFIRE_RIGHT
				end
				//Dont Use The Cover Gun Stance
				bGunUsesCoverStance = true
			end
		else ply.CTRL_bInCoverDuck = nil ply.CTRL_bPeekZoom = nil end
	else
		local bZoom = ply:KeyDown( IN_ZOOM )
		if ply:KeyDown( IN_ATTACK ) || bZoom then
			ply.CTRL_flCoverMoveTime = CurTime() + ply:GetUnDuckSpeed()
			if bZoom then ply.CTRL_bPeekZoom = true end
		end
		if ply.CTRL_vCover && ply:GetPos():DistToSqr( ply.CTRL_vCover ) > 9216/*96*/ then
			ply.CTRL_flCoverMoveTime = nil
			ply.CTRL_bMovingLeft = nil
			ply.CTRL_bMovingRight = nil
			ply.CTRL_vCover = nil
		end
		if CurTime() > ( ply.CTRL_flCoverMoveTime || 0 ) then
			if ply.CTRL_bMovingLeft then
				bGunUsesCoverStance = true
				cmd:SetSideMove( ply:GetRunSpeed() )
			elseif ply.CTRL_bMovingRight then
				bGunUsesCoverStance = true
				cmd:SetSideMove( -ply:GetRunSpeed() )
			end
			ply.CTRL_bPeekZoom = nil
		else
			if ply.CTRL_bMovingLeft then
				PEEK = ply.CTRL_bPeekZoom && COVER_FIRE_LEFT || COVER_BLINDFIRE_LEFT
			elseif ply.CTRL_bMovingRight then
				PEEK = ply.CTRL_bPeekZoom && COVER_FIRE_RIGHT || COVER_BLINDFIRE_RIGHT
			end
		end
		ply.CTRL_flCoverPeekTime = nil
		ply.CTRL_bInCoverDuck = nil
	end
	local v = ply.CTRL_flCoverDoShootTime
	if v then
		if CurTime() > v then
			cmd:AddKey( IN_ATTACK )
			ply.CTRL_flCoverDoShootTime = nil
		elseif CurTime() < v then cmd:RemoveKey( IN_ATTACK ) end
	end
	if bGunUsesCoverStance then
		ply:SetNW2Bool( "CTRL_bInCover", true )
	elseif bInCover then
		//cmd:RemoveKey( IN_JUMP )
		ply:SetNW2Bool( "CTRL_bInCover", true ) 
		ply.CTRL_bInCover = true
	else
		ply:SetNW2Bool( "CTRL_bInCover", false )
		ply.CTRL_bInCover = nil
	end
	ply:SetNW2Int( "CTRL_Variants", VARIANTS )
	ply:SetNW2Int( "CTRL_Peek", PEEK )
end )

local CEntity_GetVelocity = CEntity.GetVelocity
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
local CEntity_GetTable = CEntity.GetTable

local CPlayer_KeyDown = CPlayer.KeyDown

function QuickSlide_Can( ply, t ) if t == nil then t = CEntity_GetTable( ply ) end return !t.CTRL_bCantSlide && CEntity_IsOnGround( ply ) && GetVelocity( ply ):Length() >= ply:GetRunSpeed() end
local CEntity_SetNW2Bool = CEntity.SetNW2Bool
local CEntity_SetNW2Float = CEntity.SetNW2Float
local CEntity_GetNW2Float = CEntity.GetNW2Float
function QuickSlide_Handle( ply )
	local vel = CEntity_GetVelocity( ply )
	local f = CEntity_GetNW2Float( ply, "CTRL_flSlideSpeed", 0 )
	if ( !ply.Alive || ply.Alive && ply:Alive() ) && CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) && vel:Length() > 10 && CEntity_IsOnGround( ply ) && ( ply:IsPlayer() && CPlayer_KeyDown( ply, IN_DUCK ) && CPlayer_KeyDown( ply, IN_SPEED ) ) && f > 10 then
		local v = ply:GetAimVector()
		v.z = 0
		v:Normalize()
		local flRunSpeed = ply:GetRunSpeed()
		local t = CEntity_GetTable( ply )
		f = f - ( ply.GAME_flSlideSpeed || CPlayer_GetRunSpeed( ply ) * 1.5 ) * ( t.CTRL_flSlideSpeedDecay || .8 ) * FrameTime()
		CEntity_SetNW2Float( ply, "CTRL_flSlideSpeed", f )
		local s = t.CTRL_pSlideLoop
		if s then
			s:ChangeVolume( vel:Length() / flRunSpeed )
			local p = vel:Length() / flRunSpeed
			s:ChangeVolume( p )
			s:ChangePitch( math.Remap( p, 0, 1, 80, 100 ) )
		end
		return v * f
	else
		local t = CEntity_GetTable( ply )
		local v = t.CTRL_pSlideLoop
		if v then
			v:Stop()
			t.CTRL_pSlideLoop = nil
		end
		CEntity_SetNW2Bool( ply, "CTRL_bSliding", false )
	end
end
function QuickSlide_Start( ply, t )
	CEntity_SetNW2Bool( ply, "CTRL_bSliding", true )
	local f = ply.GAME_flSlideSpeed || ply:GetRunSpeed() * 1.5
	CEntity_SetNW2Float( ply, "CTRL_flSlideSpeed", f )
	CEntity_SetNW2Float( ply, "CTRL_flSlide", CurTime() )
	local t = CEntity_GetTable( ply )
	local s = CreateSound( ply, t.CTRL_sSlideLoop || "HumanSlideLoop" )
	t.CTRL_pSlideLoop = s
	s:Play()
end
function QuickSlide_CalcLength( ply )
	local v = ply.GAME_flSlideSpeed || ply:GetRunSpeed() * 1.5
	local d = v * ( CEntity_GetTable( ply ).CTRL_flSlideSpeedDecay || .8 )
	return ( v * v ) / ( 2 * d )
end
hook.Add( "Move", "GameImprovements", function( ply, mv )
	if ply:Alive() then
		if !CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) then
			local t = CEntity_GetTable( ply )
			if CPlayer_KeyDown( ply, IN_SPEED ) && CPlayer_KeyDown( ply, IN_DUCK ) && QuickSlide_Can( ply, t ) then QuickSlide_Start( ply, t ) end
		end
		local v = QuickSlide_Handle( ply ) if v then mv:SetVelocity( v ) end
	end
end )

local player_Iterator = player.Iterator
hook.Add( "EntityEmitSound", "GameImprovements", function( Data, _Comp )
	if _Comp then return end
	hook.Run( "EntityEmitSound", Data, true )
	local ent = Data.Entity
	local dent = GetOwner( ent )
	if ent.GAME_bNextSoundMute then ent.GAME_bNextSoundMute = nil return true end
	local dt = math.Clamp( Data.SoundLevel ^ ( Data.SoundLevel >= 80 && 1.65 || 1.5 ), 5, 18000 )
	local vPos = Data.Pos || ent:GetPos()
	for act in pairs( __ACTOR_LIST__ ) do
		if act == ent || act == dent then continue end
		if act.flHearDistanceMultiplier > 0 && act:GetPos():Distance( vPos ) <= ( dt * act.flHearDistanceMultiplier ) then
			act:OnHeardSomething( dent, Data )
		end
	end
	local dts = dt * dt
	for _, ply in player_Iterator() do if ply:EyePos():DistToSqr( vPos ) <= dts then Director_UpdateAwareness( ply, ent ) end end
	return true
end )

__SCALE_DAMAGE__ = { [ HITGROUP_HEAD ] = 4 }
local __SCALE_DAMAGE__ = __SCALE_DAMAGE__

hook.Add( "ScalePlayerDamage", "GameImprovements", function( _, hg, dmg ) dmg:ScaleDamage( __SCALE_DAMAGE__[ hg ] || 1 ) return false end )
hook.Add( "ScaleNPCDamage", "GameImprovements", function( _, hg, dmg ) dmg:ScaleDamage( __SCALE_DAMAGE__[ hg ] || 1 ) return false end )

if !CLASS_HUMAN then Add_NPC_Class "CLASS_HUMAN" end

function CPlayer:GetNPCClass() return self.m_iClass || CLASS_HUMAN end
function CPlayer:Classify() return self:GetNPCClass() end
function CPlayer:SetNPCClass( i ) self.m_iClass = i end
