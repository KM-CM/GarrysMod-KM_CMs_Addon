// ENT.Weapon = NULL
ENT.tWeapons = {}

local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_GetPos = CEntity.GetPos

function ENT:GetActiveWeapon() return CEntity_GetTable( self ).Weapon end
// See lower for SetActiveWeapon

local pairs = pairs
local table = table
local table_insert = table.insert
local table_IsEmpty = table.IsEmpty

function ENT:GetWeapons()
	local t = {}
	for wep in pairs( CEntity_GetTable( self ).tWeapons ) do table_insert( t, wep ) end
	return t
end

local IsValid = IsValid

function ENT:IsWeaponActive() return IsValid( CEntity_GetTable( self ).Weapon ) end
function ENT:HasWeapon() return !table_IsEmpty( CEntity_GetTable( self ).tWeapons ) end // HasWeapon(s)

local ents_Create = ents.Create
local hook_Run = hook.Run
function ENT:Give( sWeaponClass, MyTable )
	local wep = ents_Create( sWeaponClass )
	if !IsValid( wep ) then return end
	if !wep:IsScripted() then wep:Remove() return end
	wep:SetPos( CEntity_GetPos( self ) )
	wep:SetOwner( self )
	wep:Spawn()
	wep:Activate()
	hook_Run( "WeaponEquip", self, wep )
	MyTable = MyTable || CEntity_GetTable( self )
	return MyTable.SetActiveWeapon( self, wep, MyTable )
end

local FSOLID_TRIGGER = FSOLID_NOT_SOLID
local EF_ITEM_BLINK = EF_ITEM_BLINK
local MOVETYPE_NONE = MOVETYPE_NONE
local EF_BONEMERGE = EF_BONEMERGE
local FSOLID_NOT_SOLID = FSOLID_NOT_SOLID
function ENT:SetActiveWeapon( wep, MyTable )
	if !IsValid( wep ) || !wep:IsScripted() then return end
	MyTable = istable( MyTable ) && MyTable || CEntity_GetTable( self )
	local awep = MyTable.Weapon
	if IsValid( awep ) then awep:SetNoDraw( true ) end
	MyTable.Weapon = wep
	wep:SetNoDraw( false )
	wep:SetWeaponHoldType( wep:GetHoldType() )
	wep:SetVelocity( vector_origin )
	wep:RemoveSolidFlags( FSOLID_TRIGGER )
	wep:SetOwner( self )
	wep:RemoveEffects( EF_ITEM_BLINK )
	wep:PhysicsDestroy()
	wep:SetParent( self )
	wep:SetMoveType( MOVETYPE_NONE )
	wep:AddEffects( EF_BONEMERGE )
	wep:AddSolidFlags( FSOLID_NOT_SOLID )
	wep:SetLocalPos( vector_origin )
	wep:SetLocalAngles( angle_zero )
	wep:SetTransmitWithParent( true )
	MyTable.tWeapons[ wep ] = true
	return wep
end

local MOVETYPE_FLYGRAVITY = MOVETYPE_FLYGRAVITY
local SOLID_VPHYSICS = SOLID_VPHYSICS
local MOVETYPE_VPHYSICS = MOVETYPE_VPHYSICS
local SOLID_BBOX = SOLID_BBOX
local bit_bor = bit.bor
local FSOLID_TRIGGER = FSOLID_TRIGGER
local Vector = Vector
local ProtectedCall = ProtectedCall
function ENT:DropWeapon( wep, vVelocity, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	local wep = wep == nil && MyTable.Weapon || wep
	if !IsValid( wep ) then return end
	if wep == MyTable.Weapon then MyTable.Weapon = nil end
	if vVelocity == nil then vVelocity = vVelocity || MyTable.EyeAngles( self, MyTable ):Forward() * 400 end
	wep:SetNoDraw( false )
	wep:SetParent()
	wep:CollisionRulesChanged()
	wep:SetOwner( NULL )
	wep:RemoveEffects( EF_BONEMERGE )
	wep:SetMoveType( MOVETYPE_FLYGRAVITY )
	local SF = wep:GetSolidFlags()
	if wep:PhysicsInit( SOLID_VPHYSICS ) then
		wep:SetMoveType( MOVETYPE_VPHYSICS )
		wep:PhysWake()
	else
		wep:SetSolid( SOLID_BBOX )
	end
	wep:SetSolidFlags( bit_bor( SF, FSOLID_TRIGGER ) )
	wep:RemoveSolidFlags( FSOLID_NOT_SOLID )
	wep:SetTransmitWithParent( false )
	ProtectedCall( function() wep:OwnerChanged() end )
	ProtectedCall( function() wep:OnDrop() end )
	wep:SetPos( MyTable.GetShootPos( self, MyTable ) )
	wep:SetAngles( MyTable.EyeAngles( self, MyTable ) )
	local phys = wep:GetPhysicsObject()
	if IsValid( phys ) then
		phys:AddVelocity( vVelocity )
		phys:AddAngleVelocity( Vector( 200, 200, 200 ) )
	else
		wep:SetVelocity( vVelocity )
	end
	MyTable.tWeapons[ wep ] = nil
	hook_Run( "PlayerDroppedWeapon", self, wep )
	return wep
end

function ENT:TranslateWeaponActivity( act, MyTable )
	local wep = ( MyTable || CEntity_GetTable( self ) ).Weapon
	if !IsValid( wep ) then return act end
	ProtectedCall( function() act = wep:TranslateActivity( act ) end )
	return act
end

local ACT_MP_RELOAD_CROUCH = ACT_MP_RELOAD_CROUCH
local ACT_MP_RELOAD_STAND = ACT_MP_RELOAD_STAND
function ENT:DoReloadGesture( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	local act = MyTable.TranslateActivity( self, MyTable.Crouching( self, MyTable ) && ACT_MP_RELOAD_CROUCH || ACT_MP_RELOAD_STAND, MyTable )
	local seq = self:SelectWeightedSequence( act )
	self:AddGesture( act )
	return self:SequenceDuration( seq )
end

local CurTime = CurTime
local timer_Simple = timer.Simple
ENT.flWeaponReloadTime = 0
function ENT:WeaponReload( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	local wep = MyTable.Weapon
	if !IsValid( wep ) || CurTime() <= MyTable.flWeaponReloadTime then return end
	wep:SetClip1( 0 )
	local t = MyTable.DoReloadGesture( self, MyTable )
	MyTable.flWeaponReloadTime = CurTime() + t
	timer_Simple( t, function()
		if IsValid( wep ) && IsValid( self ) && MyTable.tWeapons && MyTable.tWeapons[ wep ] && MyTable.Weapon == wep then
			wep:SetClip1( wep:GetMaxClip1() )
		end
	end )
end

function ENT:WeaponPrimaryAttack( MyTable )
	local wep = ( MyTable || CEntity_GetTable( self ) ).Weapon
	if !IsValid( wep ) && CurTime() <= wep:GetNextPrimaryFire() then return end
	wep:PrimaryAttack()
	self:RestartGesture( MyTable.TranslateActivity( self, MyTable.Crouching( self, MyTable ) && ACT_MP_ATTACK_CROUCH_PRIMARYFIRE || ACT_MP_ATTACK_STAND_PRIMARYFIRE, MyTable ) )
	return true
end

local math = math
local math_Rand = math.Rand
local unpack = unpack

ENT.flWeaponPrimaryVolleyTime = 0
ENT.flWeaponPrimaryVolleyTimeNext = 0
ENT.tWeaponPrimaryVolleyTimes = { 0, 3 }
ENT.tWeaponPrimaryVolleyBreaks = { .33, .66 }
ENT.tWeaponPrimaryVolleyNonAutomaticDelay = { 0, .4 }
ENT.flWeaponPrimaryVolleyNonAutomaticDelay = 0
function ENT:WeaponPrimaryVolley( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	if CurTime() > MyTable.flWeaponPrimaryVolleyTimeNext then
		local t = CurTime() + math_Rand( unpack( MyTable.tWeaponPrimaryVolleyTimes ) )
		MyTable.flWeaponPrimaryVolleyTime = t
		MyTable.flWeaponPrimaryVolleyTimeNext = t + math_Rand( unpack( MyTable.tWeaponPrimaryVolleyBreaks ) )
	end
	if CurTime() <= MyTable.flWeaponPrimaryVolleyTime && CurTime() > MyTable.flWeaponPrimaryVolleyNonAutomaticDelay && MyTable.WeaponPrimaryAttack( self, MyTable ) then
		local wep = MyTable.Weapon
		if IsValid( wep ) then
			local p = wep.Primary
			if p && !p.Automatic then MyTable.flWeaponPrimaryVolleyNonAutomaticDelay = CurTime() + math_Rand( unpack( MyTable.tWeaponPrimaryVolleyNonAutomaticDelay ) ) end
		end
	end
end

function ENT:GetWeaponClipPrimary() local w = ( MyTable || CEntity_GetTable( self ) ).Weapon if IsValid( w ) then return w:Clip1() else return -1 end end
function ENT:GetWeaponClipSizePrimary() local w = ( MyTable || CEntity_GetTable( self ) ).Weapon if IsValid( w ) then return w:GetMaxClip1() else return -1 end end

local util_TraceLine = util.TraceLine
local math_abs = math.abs
local math_AngleDifference = math.AngleDifference
function ENT:CanAttackHelper( vec, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	if MyTable.GetWeaponClipPrimary( self, MyTable ) <= 0 then return end
	local v, a = MyTable.GetShootPos( self, MyTable ), MyTable.GetAimVector( self, MyTable )
	local tr = util_TraceLine {
		start = v,
		endpos = v + a * 999999,
		mask = MASK_SHOT_HULL,
		filter = self
	}
	local e = tr.Entity
	if IsValid( e ) && MyTable.Disposition( e, MyTable ) == D_LI then return end
	if vec then
		local ang, aim = ( vec - v ):Angle(), a:Angle()
		if math_abs( math_AngleDifference( ang.y, aim.y ) ) > 1 || math_abs( math_AngleDifference( ang.p, aim.p ) ) > 1 then return end
	end
	return true
end
