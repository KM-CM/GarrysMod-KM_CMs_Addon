ENT.vHullMins = HULL_HUMAN_MINS
ENT.vHullMaxs = HULL_HUMAN_MAXS
ENT.vHullDuckMins = HULL_HUMAN_DUCK_MINS
ENT.vHullDuckMaxs = HULL_HUMAN_DUCK_MAXS

ENT.flReach = 64

local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable

function ENT:ModifyMoveAimVector( vec, flSpeed, flDuck )
	if flDuck < .5 then return end
	local MyTable = CEntity_GetTable( self )
	local v = MyTable.vDesAim:Angle()
	v.p = v.p + 35
	MyTable.vDesAim = v:Forward()
end

function ENT:MoveAlongPathToCover( ... ) return self:MoveAlongPath( ... ) end

ENT.bHoldFire = false

ENT.flHearDistanceMultiplier = 1

ENT.iState = NPC_STATE_NONE
function ENT:GetNPCState() return self.iState end
function ENT:SetNPCState( i ) self.iState = i end

function ENT:GetShootPos() return self:GetPos() + Vector( 0, 0, self:OBBMaxs().z * .77777777777778 ) end
function ENT:EyePos() return self:GetShootPos() end

function ENT:GetHull() return self.vHullMins, self.vHullMaxs end
function ENT:GetHullDuck() return self.vHullDuckMins, self.vHullDuckMaxs end

function ENT:TranslateActivity( n ) return n end

__ACTOR_LIST__ = __ACTOR_LIST__ || {}
local __ACTOR_LIST__ = __ACTOR_LIST__

local SafeRemoveEntity = SafeRemoveEntity

function ENT:OnRemove()
	__ACTOR_LIST__[ self ] = nil
	local MyTable = CEntity_GetTable( self )
	for _, d in pairs( MyTable.tBullseyes ) do SafeRemoveEntity( d[ 1 ] ) end
	local iClass = MyTable.GetNPCClass( self )
	if iClass != CLASS_NONE then
		local t = MyTable.GetActorTableByClass()[ iClass ]
		if t then t[ self ] = true end
	end
end

function ENT:Tick( MyTable ) end

local CEntity_GetPhysicsObject = CEntity.GetPhysicsObject
local CEntity_GetParent = CEntity.GetParent
local CEntity_PhysicsDestroy = CEntity.PhysicsDestroy
local CEntity_WaterLevel = CEntity.WaterLevel
local CEntity_GetPos = CEntity.GetPos
local CEntity_GetAngles = CEntity.GetAngles

local IsValid = IsValid

ENT.bPhysics = false
function ENT:Think()
	local MyTable = CEntity_GetTable( self )
	if !MyTable.bPhysics then
		local phys = CEntity_GetPhysicsObject( self )
		if IsValid( phys ) then
			if IsValid( CEntity_GetParent( self ) ) then CEntity_PhysicsDestroy( self ) else
				if CEntity_WaterLevel( self ) == 0 then
					phys:SetPos( CEntity_GetPos( self ) )
					phys:SetAngles( CEntity_GetAngles( self ) )
				else
					phys:UpdateShadow( CEntity_GetPos( self ), CEntity_GetAngles( self ), 0 )
				end
			end
		end
	end
	if IsValid( MyTable.GAME_pVehicle ) then
		self:SetActiveWeapon( NULL )
		if self:GetCollisionGroup() != COLLISION_GROUP_WORLD then self:SetCollisionGroup( COLLISION_GROUP_WORLD ) end
	else if self:GetCollisionGroup() != COLLISION_GROUP_NPC then self:SetCollisionGroup( COLLISION_GROUP_NPC ) end end
	MyTable.Tick( self, MyTable )
end

local FL = FL_OBJECT + FL_NPC + FL_CLIENT + FL_FAKECLIENT
function ENT:Initialize()
	self:AddFlags( FL )
	__ACTOR_LIST__[ self ] = true
	self:SetNPCClass( self:GetNPCClass() ) // Required for Ally Searches to Work
	self:AddCallback( "PhysicsCollide", function( self, Data )
		local ent = Data.HitEntity
		if !IsValid( ent ) then return end
		local class = ent:GetClass()
		local phys = Data.HitObject
		if !ent:IsPlayerHolding() then
			local d = math.floor( ( Data.TheirOldVelocity:Length() * Data.HitObject:GetMass() ) * .001 )
			if d > 10 then
				local dmg = DamageInfo()
				if ent:IsVehicle() && IsValid( ent:GetDriver() ) then
					dmg:SetAttacker( ent:GetDriver() )
				elseif IsValid( ent:GetPhysicsAttacker() ) then
					dmg:SetAttacker( ent:GetPhysicsAttacker() )
				else dmg:SetAttacker( ent ) end
				dmg:SetInflictor( ent )
				dmg:SetDamage( d )
				if ent:IsVehicle() then dmg:SetDamageType( DMG_VEHICLE )
				else dmg:SetDamageType( DMG_CRUSH ) end
				dmg:SetDamageForce( phys:GetVelocity() )
				self:TakeDamageInfo( dmg )
			end
		end
	end )
end

function ENT:HandleKeyValue( Key, Value ) end

local DEFAULT_KEY_VALUES = {
	weapon = function( self, _, sWeapons )
		// if sWeaponClass != nil && sWeaponClass != '' then self:Give( sWeaponClass ) end
		for t in string.gmatch( sWeapons, "[^,]+" ) do self:Give( t ) end
	end,
	class = function( self, _, sClass )
		sClass = "CLASS_" .. sClass
		local v = _G[ sClass ]
		if v == nil then
			Add_NPC_Class( sClass )
			local v = _G[ sClass ]
			if v then self:SetNPCClass( v ) end
		else self:SetNPCClass( v ) end
	end
}
DEFAULT_KEY_VALUES.additionalequipment = DEFAULT_KEY_VALUES.weapon
function ENT:KeyValue( k, v )
	local f = DEFAULT_KEY_VALUES[ string.lower( k ) ]
	if f then f( self, k, v ) return end
	self:HandleKeyValue( k, v )
end

function ENT:Behaviour() end

function ENT:ActorOnDeath() for wep in pairs( self.tWeapons ) do self:DropWeapon( wep ) end end

ENT.GAME_flSuppression = 0
ENT.flSuppressionMax = 2
ENT.flSuppressionRec = 2
ENT.flSuppressionHide = .1

function ENT:GAME_OnRangeAttacked( _, _, _, flDamage )
	local MyTable = CEntity_GetTable( self )
	MyTable.GAME_flSuppression = MyTable.GAME_flSuppression + flDamage
	MyTable.flCombatStateSuppressionShort = MyTable.flCombatStateSuppressionShort + flDamage
	MyTable.flCombatStateSuppressionLong = MyTable.flCombatStateSuppressionLong + flDamage
end

local ProtectedCall = ProtectedCall
local ai_disabled, developer = GetConVar "ai_disabled", GetConVar "developer"
local coroutine_yield = coroutine.yield
local math = math
local math_Approach = math.Approach
local math_Clamp = math.Clamp
local math_abs = math.abs
local math_AngleDifference = math.AngleDifference
local FrameTime = FrameTime
local CEntity_Health = CEntity.Health
local CEntity_GetPoseParameter = CEntity.GetPoseParameter
local CEntity_SetPoseParameter = CEntity.SetPoseParameter
local CEntity_LookupPoseParameter = CEntity.LookupPoseParameter
local Angle = Angle
function ENT:RunBehaviour()
	while true do
		if ai_disabled:GetInt() == 1 then coroutine_yield() continue end
		local MyTable = CEntity_GetTable( self )
		local f = CEntity_Health( self )
		MyTable.GAME_flSuppression = math_Approach( math_Clamp( MyTable.GAME_flSuppression, 0, f * MyTable.flSuppressionMax ), 0, f * MyTable.flSuppressionRec * FrameTime() )
		MyTable.flCombatStateSuppressionShort = math_Approach( math_Clamp( MyTable.flCombatStateSuppressionShort, 0, f * MyTable.flCombatStateSuppressionShortMax ), 0, f * MyTable.flCombatStateSuppressionShortRec * FrameTime() )
		MyTable.flCombatStateSuppressionLong = math_Approach( math_Clamp( MyTable.flCombatStateSuppressionLong, 0, f * MyTable.flCombatStateSuppressionLongMax ), 0, f * MyTable.flCombatStateSuppressionLongRec * FrameTime() )
		local vDesAim = MyTable.GetDesiredAimVector( self )
		local aDesAim = vDesAim:Angle()
		local ppAimPitch = CEntity_LookupPoseParameter( self, "aim_pitch" )
		local Angles = CEntity_GetAngles( self )
		local aAim = Angle( Angles )
		local flTurnRate = MyTable.flTurnRate
		if ppAimPitch != -1 then
			local p = CEntity_GetPoseParameter( self, "aim_pitch" )
			local des = math_AngleDifference( aDesAim.p, Angles.p + p )
			local t = MyTable.flBodyTensity
			local f = flTurnRate / t * FrameTime()
			CEntity_SetPoseParameter( self, "aim_pitch", p + math_Clamp( des * t, -f, f ) )
			aAim.p = aAim.p + self:GetPoseParameter "aim_pitch"
		end
		local ppAimYaw = CEntity_LookupPoseParameter( self, "aim_yaw" )
		if ppAimYaw != -1 then
			local p = CEntity_GetPoseParameter( self, "aim_yaw" )
			local des = math_AngleDifference( aDesAim.y, Angles.y + p )
			local t = MyTable.flBodyTensity
			local f = flTurnRate / t * FrameTime()
			CEntity_SetPoseParameter( self, "aim_yaw", p + math_Clamp( des * t, -f, f ) )
			aAim.y = aAim.y + CEntity_GetPoseParameter( self, "aim_yaw" )
		end
		MyTable.CalcCombatState( self )
		MyTable.aAim = aAim
		MyTable.vAim = aAim:Forward()
		local loco = MyTable.loco
		loco:SetMaxYawRate( flTurnRate * math_Clamp( math_abs( math_AngleDifference( aDesAim.y, Angles.y ) ), 0, 90 ) * .01111111111 )
		local v = CEntity_GetPos( self ) + vDesAim
		for _ = 1, 8 do loco:FaceTowards( v ) end
		MyTable.Look( self, MyTable )
		ProtectedCall( function() MyTable.Behaviour( self, MyTable ) end )
		coroutine_yield()
	end
end

/*
ENT.bCanClimbLadders = false
// Note That This is NOT Climbing Ladders, It's Climbing ANYTHING, Like Left 4 Dead 2 Infected
ENT.bCanClimb = false

ENT.bSimpleDuck = false // Can Only Duck Very Simply as The Name Suggests - Either Ducked, or Not Ducked
ENT.bCanMove = false
ENT.bCanMoveShoot = false
ENT.bCanDuck = false
ENT.bCanDuckShoot = false
ENT.bCanDuckMove = false
ENT.bCanDuckMoveShoot = false
*/

function ENT:Crouching() return false end
// Dont Worry, if bSimpleDuck is true, This will Only be Supplied with
// Either a 0 or a 1, as Opposed to Any Value in The [ 0, 1 ] Range
function ENT:SetCrouchTarget( flTarget ) end
function ENT:GetCrouchTarget() return 1 end
