local CEntity = FindMetaTable "Entity"
if !CEntity.IgniteInternal then CEntity.IgniteInternal = CEntity.Ignite end
function CEntity:Ignite()
	if !self:IsOnFire() && self.OnIgnite then self:OnIgnite() end
	self:IgniteInternal( 10 )
end

function GetFlameStopChance( self ) return math.Remap( GetVelocity( self ):Length(), 0, 800, 20000, 1000 ) end

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
	if ent.HAS_MELEE_ATTACK then return true end
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

hook.Add( "PlayerDeath", "GameImprovements", function( ply ) for _, wep in ipairs( ply:GetWeapons() ) do ply:DropWeapon( wep ) end end )

local ents_Iterator = ents.Iterator
hook.Add( "Think", "GameImprovements", function()
	for _, ent in ents_Iterator() do
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
local CEntity_IsOnGround = CEntity.IsOnGround
local util_TraceLine = util.TraceLine
hook.Add( "StartCommand", "GameImprovements", function( ply, cmd )
	if FixBunnyHop:GetBool() then
		if CEntity_IsOnGround( ply ) then
			if CurTime() <= ( tFixBunnyHop[ ply ] || 0 ) then
				cmd:RemoveKey( IN_JUMP )
			else tFixBunnyHop[ ply ] = nil end
		else tFixBunnyHop[ ply ] = CurTime() + FixBunnyHopLength:GetFloat() end
	else tFixBunnyHop[ ply ] = nil end

	if cmd:KeyDown( IN_DUCK ) && cmd:KeyDown( IN_JUMP ) then cmd:RemoveKey( IN_DUCK ) cmd:RemoveKey( IN_JUMP ) end

	//TODO: Side Peeking Code
	local bInCover
	local bGunDoesntUseCoverStance //Used in Very Special Circumstances
	local PEEK = COVER_PEEK_NONE
	local VARIANTS = COVER_VARIANTS_CENTER
	local EyeAngles = ply:EyeAngles()
	local EyeVector = EyeAngles:Forward()
	local EyeVectorFlat = EyeAngles:Forward()
	EyeVectorFlat.z = 0
	EyeVectorFlat:Normalize()
	local trDuck = util_TraceLine {
		start = ply:GetPos() + ply:GetViewOffsetDucked(),
		endpos = ply:GetPos() + ply:GetViewOffsetDucked() + EyeVectorFlat * ply:OBBMaxs().x * 2,
		mask = MASK_SOLID,
		filter = ply
	}
	local trStand = util_TraceLine {
		start = ply:GetPos() + ply:GetViewOffset(),
		endpos = ply:GetPos() + ply:GetViewOffset() + EyeVectorFlat * ply:OBBMaxs().x * 2,
		mask = MASK_SOLID,
		filter = ply
	}
	if ply:IsOnGround() then
		if cmd:KeyDown( IN_DUCK ) then
			if trDuck.Hit || trStand.Hit then
				bInCover = true
			end
		else
			if trDuck.Hit && trStand.Hit then
				bInCover = true
			end
		end
	end
	if cmd:KeyDown( IN_ZOOM ) then cmd:RemoveKey( IN_SPEED ) cmd:AddKey( IN_WALK ) end
	if bInCover then
		if CurTime() > ( ply.CTRL_flCoverMoveTime || 0 ) then
			ply.CTRL_bMovingLeft = nil
			ply.CTRL_bMovingRight = nil
		end
		local b
		local bLeft, bRight
		if cmd:KeyDown( IN_DUCK ) && trDuck.Hit then
			local vStart = ply:GetPos() + ply:GetViewOffsetDucked()
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
			local vStart = ply:GetPos() + ply:GetViewOffset()
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
				if !bZoom then
					if ply.CTRL_bMovingLeft then
						PEEK = COVER_BLINDFIRE_LEFT
					elseif ply.CTRL_bMovingRight then
						PEEK = COVER_BLINDFIRE_RIGHT
					end
				end
				//Dont Use The Cover Gun Stance
				bGunDoesntUseCoverStance = true
			end
		else ply.CTRL_bInCoverDuck = nil ply.CTRL_bPeekZoom = nil end
	else
		local bZoom = ply:KeyDown( IN_ZOOM )
		if ply:KeyDown( IN_ATTACK ) || bZoom then
			ply.CTRL_flCoverMoveTime = CurTime() + ply:GetUnDuckSpeed()
		end
		if ply.CTRL_vCover && ply:GetPos():DistToSqr( ply.CTRL_vCover ) > 9216/*96*/ then
			ply.CTRL_flCoverMoveTime = nil
			ply.CTRL_bMovingLeft = nil
			ply.CTRL_bMovingRight = nil
			ply.CTRL_vCover = nil
		end
		if CurTime() > ( ply.CTRL_flCoverMoveTime || 0 ) then
			if ply.CTRL_bMovingLeft then
				cmd:SetSideMove( ply:GetRunSpeed() )
			elseif ply.CTRL_bMovingRight then
				cmd:SetSideMove( -ply:GetRunSpeed() )
			end
			ply.CTRL_bPeekZoom = nil
		else
			if !ply.CTRL_bPeekZoom then
				if ply.CTRL_bMovingLeft then
					PEEK = COVER_BLINDFIRE_LEFT
				elseif ply.CTRL_bMovingRight then
					PEEK = COVER_BLINDFIRE_RIGHT
				end
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
	if bGunDoesntUseCoverStance then
		ply:SetNW2Bool( "CTRL_bInCover", false )
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

local CPlayer = FindMetaTable "Player"

if !CLASS_HUMAN then Add_NPC_Class "CLASS_HUMAN" end

function CPlayer:GetNPCClass() return self.m_iClass || CLASS_HUMAN end
function CPlayer:Classify() return self:GetNPCClass() end
function CPlayer:SetNPCClass( i ) self.m_iClass = i end
