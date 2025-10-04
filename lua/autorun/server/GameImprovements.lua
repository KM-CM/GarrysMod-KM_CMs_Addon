local math = math
local math_Remap = math.Remap
function GetFlameStopChance( self ) return math_Remap( GetVelocity( self ):Length(), 0, 800, 20000, 1000 ) end

concommand.Add( "+drop", function() end )
concommand.Add( "-drop", function( ply ) ply:DropWeapon() end )

ACCELERATION_NORMAL = 5
ACCELERATION_ACTUAL = ACCELERATION_NORMAL

HUMAN_RUN_SPEED, HUMAN_PROWL_SPEED, HUMAN_WALK_SPEED, HUMAN_JUMP_HEIGHT = 300, 200, 75, 52

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

// Intentionally Generates UUIDs Instead of Truly Unique Numbers for Extremely Rare Funni Bugs
function EntityUniqueIdentifier( ent )
	if ent.__UNIQUE_IDENTIFIER__ then return ent.__UNIQUE_IDENTIFIER__ end
	local t = {}
	for _ = 1, 16 do
		local i = math.random( 1, 3 )
		if i == 1 then table.insert( t, string.char( math.random( 65, 90 ) ) ) // A-Z
		elseif i == 2 then table.insert( t, string.char( math.random( 97, 122 ) ) ) // a-z
		else table.insert( t, math.random( 0, 9 ) ) end
	end
	ent.__UNIQUE_IDENTIFIER__ = table.concat( t )
	return ent.__UNIQUE_IDENTIFIER__
end

// local tIgnoreRangeAttackDisp = { [ D_NU ] = true, [ D_LI ] = true }
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
		if ent.__ACTOR__ then
			if ent == Owner || Owner.Disposition && Owner:Disposition( ent ) == D_LI || ent.Disposition && ent:Disposition( Owner ) == D_LI then continue end
			local _, v = util_DistanceToLine( vStart, vEnd, ent:EyePos() )
			if ent:CanSee( v ) then ent.bHoldFire = nil ent:SetupBullseye( Owner, vStart, ang ) end
		end
	end
	/*Too Cheaty - Makes Silencers Almost Completely UseLess
	local ang = ( vEnd - vStart ):Angle()
	for ent in pairs( __ACTOR_LIST__ ) do
		if ent == Owner || Owner.Disposition && tIgnoreRangeAttackDisp[ Owner:Disposition( ent ) ] || ent.Disposition && tIgnoreRangeAttackDisp[ ent:Disposition( Owner ) ] then continue end
		local _, v = util_DistanceToLine( vStart, vEnd, ent:EyePos() )
		if ent:CanSee( v ) then ent:SetupBullseye( Owner, vStart, ang ) end
	end
	*/
end

hook.Add( "PlayerDeath", "GameImprovements", function( ply, _, at )
	if IsValid( ply.GAME_pFlashlight ) then ply.GAME_pFlashlight:Remove() end
	if IsValid( at ) && at:IsPlayer() then
		local v = __PLAYER_MODEL__[ at:GetModel() ]
		if v then
			v = v.OnKilledSomething
			if v then if v( at, ply ) then b = nil end end
		end
	end
end )
hook.Add( "PlayerDeathSilent", "GameImprovements", function( ply ) if IsValid( ply.GAME_pFlashlight ) then ply.GAME_pFlashlight:Remove() end end )

hook.Add( "OnNPCKilled", "GameImprovements", function( ent, at )
	if IsValid( at ) && at:IsPlayer() then
		local v = __PLAYER_MODEL__[ at:GetModel() ]
		if v then
			v = v.OnKilledSomething
			if v then if v( at, ent ) then b = nil end end
		end
	end
end )

hook.Add( "PlayerSwitchFlashlight", "GameImprovements", function( ply )
	if IsValid( ply.GAME_pFlashlight ) then ply:EmitSound "FlashlightOff" ply.GAME_pFlashlight:Remove() else
		local pt = ents.Create "env_projectedtexture"
		pt:SetPos( ply:EyePos() )
		pt:SetAngles( ply:EyeAngles() )
		pt:SetOwner( ply )
		pt:SetParent( ply )
		pt:SetKeyValue( "lightfov", "60" )
		pt:SetKeyValue( "lightcolor", "255 255 255 512" )
		pt:SetKeyValue( "NearZ", "1" )
		pt:SetKeyValue( "FarZ", "2048" )
		pt:Input( "SpotlightTexture", nil, nil, "effects/flashlight001" )
		pt:Spawn()
		ply:EmitSound "FlashlightOn"
		ply.GAME_pFlashlight = pt
	end
	return false
end )

local util_TraceLine = util.TraceLine

hook.Add( "OnEntityCreated", "GameImprovements", function( ent )
	if IsValid( ent ) && ent:IsWeapon() then
		timer.Simple( .01, function() if IsValid( ent ) then ent.GAME_bWeaponPickedUpOnce = true end end )
	end
end )

hook.Add( "PlayerCanPickupWeapon", "GameImprovements", function( ply, wep )
	if !wep.GAME_bWeaponPickedUpOnce then
		local w = ply:GetWeapon( wep:GetClass() )
		if IsValid( w ) then ply:DropWeapon( w ) end
		wep.GAME_bWeaponPickedUpOnce = true
		return true
	end
	if !ply:KeyDown( IN_USE ) then return false end
	local tr = util_TraceLine {
		start = ply:EyePos(),
		endpos = ply:EyePos() + ply:GetAimVector() * 999999,
		filter = ply
	}
	if tr.Entity != wep then return false end
	ply:DropObject()
	wep:ForcePlayerDrop()
	local c = wep:GetClass()
	// Make them switch to the gun because they CONSCIOUSLY picked it up,
	// not just randomly got it from the floor and accidentally self stunlocked in the deploy animation
	ply.GAME_sRestoreGun = c
	local w = ply:GetWeapon( c )
	if IsValid( w ) then ply:DropWeapon( w ) end
end )
hook.Add( "PlayerCanPickupItem", "GameImprovements", function( ply, item )
	if !ply:KeyDown( IN_USE ) then return false end
	local tr = util_TraceLine {
		start = ply:EyePos(),
		endpos = ply:EyePos() + ply:GetAimVector() * 999999,
		filter = ply
	}
	return tr.Entity == item
end )

hook.Add( "PlayerHurt", "GameImprovements", function( ply, pAttacker, flHealth, flDamage )
	local b = true
	local v = __PLAYER_MODEL__[ ply:GetModel() ]
	if v then
		v = v.Hurt
		if v then if v( ply, pAttacker, flHealth, flDamage ) then b = nil end end
	end
	if b then
		b = !ply.GAME_bSecondHurtViewPunch
		ply.GAME_bSecondHurtViewPunch = b
		ply:ViewPunch( Angle( 0, 0, flDamage * math.Remap( flHealth, 0, ply:GetMaxHealth(), .05, .01 ) * ( b && 1 || -1 ) ) )
	end
end )

TRACER_COLOR = {
	Bullet = "255 48 0 1024",
	AR2Tracer = "48 255 255 1024"
}
local TRACER_COLOR = TRACER_COLOR

TRACER_SIZE = {
	Bullet = 4,
	AR2Tracer = 4
}
local TRACER_SIZE = TRACER_SIZE

local IsValid = IsValid

hook.Add( "EntityFireBullets", "GameImprovements", function( ent, Data, _Comp )
	if _Comp then return end
	hook.Run( "EntityFireBullets", ent, Data, true )
	if Data.AmmoType != "" then Data.Damage = game.GetAmmoPlayerDamage( game.GetAmmoID( Data.AmmoType ) ) end
	local OldCallBack = Data.Callback || function() return { damage = true, effects = true } end
	local flDamage = Data.Damage
	local col = TRACER_COLOR[ Data.TracerName || "Bullet" ] || TRACER_COLOR.Bullet
	if Data.HullSize == 0 then Data.HullSize = TRACER_SIZE[ Data.TracerName || "Bullet" ] || TRACER_SIZE.Bullet end
	local pOwner = GetOwner( ent )
	Data.Callback = function( atk, tr, dmg )
		DispatchRangeAttack( atk, tr.StartPos, tr.HitPos, flDamage )
		local pTarget, vTargetVelocity, dDamage = tr.Entity
		local bTarget = IsValid( pTarget )
		if bTarget then
			vTargetVelocity = ent:GetVelocity()
			dDamage = DamageInfo()
			dDamage:SetAttacker( pOwner )
			// Prevents WALK and STEP MoveType KnockBack
			// dDamage:SetInflictor( ent )
			dDamage:SetDamage( dmg:GetDamage() )
			dDamage:SetDamageType( DMG_BULLET )
			dDamage:SetDamagePosition( tr.HitPos )
		end
		local t = OldCallBack( atk, tr, dDamage ) || { damage = true, effects = true }
		if t.damage && bTarget then pTarget:TakeDamageInfo( dDamage ) end
		local b = t.effects
		if b then
			local pt = ents.Create "env_projectedtexture"
			pt:SetPos( tr.StartPos )
			pt:SetAngles( ( tr.HitPos - tr.StartPos ):GetNormalized():Angle() )
			pt:SetKeyValue( "lightfov", "110" )
			pt:SetKeyValue( "lightcolor", col )
			pt:SetKeyValue( "spritedisabled", "1" )
			pt:SetKeyValue( "farz", "256" )
			pt:Input( "SpotlightTexture", _, _, "effects/flashlight/soft" )
			pt:SetOwner( GetOwner( ent ) )
			pt:Spawn()
			timer.Simple( .1, function() if IsValid( pt ) then pt:Remove() end end )
		end
		return { damage = false, effects = b }
	end
	return true
end )

local PersistAll = CreateConVar( "PersistAll", 1, FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_NOTIFY + FCVAR_ARCHIVE, "Everything Persists", 0, 1 )

hook.Add( "PhysgunPickup", "GameImprovements", function() return true end )

local CEntity = FindMetaTable "Entity"
local CEntity_IsOnFire = CEntity.IsOnFire
local CEntity_Ignite = CEntity.Ignite

function PhysicsCollide( ent, Data )
	local pOther = Data.HitEntity
	if CEntity_IsOnFire( ent ) || CEntity_IsOnFire( pOther ) then
		CEntity_Ignite( ent, 10 )
		CEntity_Ignite( pOther, 10 )
	end
end

hook.Add( "EntityTakeDamage", "GameImprovements", function( ent, dmg )
	local at = dmg:GetAttacker()
	if IsValid( at ) && at:IsPlayer() then
		local v = __PLAYER_MODEL__[ at:GetModel() ]
		if v then
			v = v.OnHurtSomething
			if v then if v( at, ent, dmg ) then b = nil end end
		end
	end
end )

local CEntity_WaterLevel = CEntity.WaterLevel
local CEntity_Extinguish = CEntity.Extinguish

local ents = ents
local ents_Iterator = ents.Iterator
hook.Add( "Think", "GameImprovements", function()
	for _, ent in ents_Iterator() do
		if !ent.GAME_bPhysCollideHook then ent:AddCallback( "PhysicsCollide", function( ... ) PhysicsCollide( ... ) end ) ent.GAME_bPhysCollideHook = true end
		if CEntity_WaterLevel( ent ) > 0 then CEntity_Extinguish( ent ) elseif CEntity_IsOnFire( ent ) then CEntity_Ignite( ent, 999999 ) end
		if CEntity_IsOnFire( ent ) && math.random( ( ent.GAME_bFireBall && 200000 || ( 400000 / ent:BoundingRadius() ) ) * FrameTime() ) == 1 then
			for _ = 0, 3 do
				local dir = VectorRand()
				local tr = util_TraceLine {
					start = ent:GetPos() + ent:OBBCenter(),
					endpos = ent:GetPos() + ent:OBBCenter() + VectorRand() * math.Rand( 0, ent:BoundingRadius() ),
					mask = MASK_SOLID,
					filter = ent
				}
				if tr.Entity == ent then continue end
				local p = ents.Create "prop_physics"
				p:SetPos( tr.HitPos )
				p:SetModel "models/combine_helicopter/helicopter_bomb01.mdl"
				p:SetNoDraw( true )
				p:Spawn()
				p.GAME_bFireBall = true
				local f = ents.Create "env_fire_trail"
				f:SetPos( p:GetPos() )
				f:SetParent( p )
				f:Spawn()
				p:GetPhysicsObject():AddVelocity( VectorRand() * math.Rand( 0, ent:BoundingRadius() * 24 ) )
				AddThinkToEntity( p, function( ent ) CEntity_Ignite( ent, 999999 ) if math.random( GetFlameStopChance( ent ) * FrameTime() ) == 1 || ent:WaterLevel() != 0 then ent:Remove() return true end end )
				break
			end
		end
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

local CEntity_IsOnGround = CEntity.IsOnGround
local math_max = math.max
local CEntity_WaterLevel = CEntity.WaterLevel
local CEntity_Remove = CEntity.Remove
local CPlayer = FindMetaTable "Player"
local CPlayer_GetRunSpeed = CPlayer.GetRunSpeed
local CPlayer_Give = CPlayer.Give
local ents_Create = ents.Create
hook.Add( "StartCommand", "GameImprovements", function( ply, cmd )
	if !ply:Alive() then return end

	ply:SetLadderClimbSpeed( ply:IsSprinting() && ply:GetRunSpeed() || ply:IsWalking() && ply:GetSlowWalkSpeed() || ply:GetWalkSpeed() )

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

	local c = ply:GetModel()
	local v = __PLAYER_MODEL__[ c ]
	if v then
		v = v.StartCommand
		if v && v( ply, cmd ) then return end
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

	if ply:GetNW2Bool "CTRL_bSliding" then cmd:RemoveKey( IN_ATTACK ) cmd:RemoveKey( IN_ATTACK2 ) end

	// if cmd:KeyDown( IN_ZOOM ) then cmd:RemoveKey( IN_SPEED ) cmd:AddKey( IN_WALK ) end

	local v = __PLAYER_MODEL__[ ply:GetModel() ]
	if !Either( v, v && v.bAllDirectionalSprint, ply.CTRL_bAllDirectionalSprint ) && ( ( !Either( ply.CTRL_bCantSlide == nil, __PLAYER_MODEL__[ ply:GetModel() ] && __PLAYER_MODEL__[ ply:GetModel() ].bCantSlide, ply.CTRL_bCantSlide ) && GetVelocity( ply ):Length() >= ply:GetRunSpeed() ) || !ply:Crouching() ) && cmd:KeyDown( IN_SPEED ) then
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
	else
		ply:SetNW2Bool( "CTRL_bSprinting", false )
		if cmd:KeyDown( IN_ZOOM ) then cmd:AddKey( IN_WALK ) end
	end
	if !ply:IsOnGround() then
		local v = __PLAYER_MODEL__[ ply:GetModel() ]
		if CEntity_WaterLevel( ply ) <= 0 && !Either( v == nil, ply.CTRL_bAllowMovingWhileInAir, v && v.bAllowMovingWhileInAir ) && ply:GetMoveType() == MOVETYPE_WALK then
			// cmd:SetForwardMove( 0 )
			cmd:SetSideMove( 0 )
		end
		// ply:SetNW2Bool( "CTRL_bSprinting", false )
	end

	local bInCover
	local bGunUsesCoverStance // Used in Very Special Circumstances
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
				// Dont Use The Cover Gun Stance
				bGunUsesCoverStance = true
			end
		else ply.CTRL_bInCoverDuck = nil ply.CTRL_bPeekZoom = nil end
	else
		local bZoom = ply:KeyDown( IN_ZOOM )
		if ply:KeyDown( IN_ATTACK ) || bZoom then
			ply.CTRL_flCoverMoveTime = CurTime() + ply:GetUnDuckSpeed()
			if bZoom then ply.CTRL_bPeekZoom = true end
		end
		if !bZoom then ply.CTRL_bPeekZoom = nil end
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
		ply:SetNW2Bool( "CTRL_bGunUsesCoverStance", true )
	elseif bInCover then
		// cmd:RemoveKey( IN_JUMP )
		ply:SetNW2Bool( "CTRL_bInCover", true ) 
		ply.CTRL_bInCover = true
		ply:SetNW2Bool( "CTRL_bGunUsesCoverStance", false )
	else
		ply:SetNW2Bool( "CTRL_bInCover", false )
		ply.CTRL_bInCover = nil
		ply:SetNW2Bool( "CTRL_bGunUsesCoverStance", false )
	end
	ply:SetNW2Int( "CTRL_Variants", VARIANTS )
	ply:SetNW2Int( "CTRL_Peek", PEEK )
end )

local CEntity_GetVelocity = CEntity.GetVelocity
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
local CEntity_GetTable = CEntity.GetTable

local CPlayer_KeyDown = CPlayer.KeyDown

function QuickSlide_Can( ply, t ) if t == nil then t = CEntity_GetTable( ply ) end return !Either( t.CTRL_bCantSlide == nil, __PLAYER_MODEL__[ ply:GetModel() ] && __PLAYER_MODEL__[ ply:GetModel() ].bCantSlide, t.CTRL_bCantSlide ) && CEntity_IsOnGround( ply ) && GetVelocity( ply ):Length() >= ply:GetRunSpeed() end
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
		if !CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) && QuickSlide_Can( ply ) then
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
