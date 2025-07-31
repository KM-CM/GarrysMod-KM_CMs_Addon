ENT.vHullMins = HULL_HUMAN_MINS
ENT.vHullMaxs = HULL_HUMAN_MAXS
ENT.vHullDuckMins = HULL_HUMAN_DUCK_MINS
ENT.vHullDuckMaxs = HULL_HUMAN_DUCK_MAXS

function ENT:ModifyMoveAimVector( vec, flSpeed, flDuck )
	if flDuck < .5 then return end
	local v = self.vDesAim:Angle()
	v.p = v.p + 35
	self.vDesAim = v:Forward()
end

ENT.flHearDistanceMultiplier = 1

ENT.iState = NPC_STATE_NONE
function ENT:GetNPCState() return self.iState end
function ENT:SetNPCState( i ) self.iState = i end

ENT.ShootBone = "ValveBiped.Bip01_R_Hand"
function ENT:GetShootPos() return self:GetBonePosition( self:LookupBone( self.ShootBone ) ) end
function ENT:EyePos() return self:GetShootPos() end

function ENT:GetHull() return self.vHullMins, self.vHullMaxs end
function ENT:GetHullDuck() return self.vHullDuckMins, self.vHullDuckMaxs end

function ENT:TranslateActivity( n ) return n end

__ACTOR_LIST__ = __ACTOR_LIST__ || {}
local __ACTOR_LIST__ = __ACTOR_LIST__

function ENT:OnRemove()
	__ACTOR_LIST__[ self ] = nil
	for _, d in pairs( self.tBullseyes ) do SafeRemoveEntity( d[ 1 ] ) end
	local iClass = self:GetNPCClass()
	if iClass != CLASS_NONE then
		local t = self.GetActorTableByClass()[ iClass ]
		if t then t[ self ] = true end
	end
end

function ENT:Tick() end

ENT.bPhysics = false
function ENT:Think()
	if !self.bPhysics then
		local phys = self:GetPhysicsObject()
		if IsValid( phys ) then
			if self:WaterLevel() == 0 then
				phys:SetPos( self:GetPos() )
				phys:SetAngles( self:GetAngles() )
			else
				phys:UpdateShadow( self:GetPos(), self:GetAngles(), 0 )
			end
		end
	end
	self:Tick()
end

local FL = FL_OBJECT + FL_NPC + FL_CLIENT + FL_FAKECLIENT
function ENT:Initialize()
	self:AddFlags( FL )
	__ACTOR_LIST__[ self ] = true
	self:SetNPCClass( self:GetNPCClass() ) //Required for Ally Searches to Work
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
		//if sWeaponClass != nil && sWeaponClass != '' then self:Give( sWeaponClass ) end
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
ENT.flSuppressionMax = 6
ENT.flSuppressionRec = .5
ENT.flSuppressionHide = .1

ENT.flCombatStateSuppressionShort = 0
ENT.flCombatStateSuppressionShortMax = 2
ENT.flCombatStateSuppressionShortRec = 2
ENT.flCombatStateSuppressionShortEffect = 2

ENT.flCombatStateSuppressionLong = 0
ENT.flCombatStateSuppressionLongMax = 24
ENT.flCombatStateSuppressionLongRec = .33
ENT.flCombatStateSuppressionLongEffect = 12

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable
function ENT:GAME_OnRangeAttacked( _, _, _, flDamage )
	local MyTable = CEntity_GetTable( self )
	MyTable.GAME_flSuppression = MyTable.GAME_flSuppression + flDamage
	MyTable.flCombatStateSuppressionShort = MyTable.flCombatStateSuppressionShort + flDamage
	MyTable.flCombatStateSuppressionLong = MyTable.flCombatStateSuppressionLong + flDamage
end

local ProtectedCall = ProtectedCall
local ai_disabled, developer = GetConVar "ai_disabled", GetConVar "developer"
function ENT:RunBehaviour()
	while true do
		if ai_disabled:GetInt() == 1 then coroutine.yield() continue end
		self.GAME_flSuppression = math.Approach( math.Clamp( self.GAME_flSuppression, 0, self:Health() * self.flSuppressionMax ), 0, self:Health() * self.flSuppressionRec * FrameTime() )
		self.flCombatStateSuppressionShort = math.Approach( math.Clamp( self.flCombatStateSuppressionShort, 0, self:Health() * self.flCombatStateSuppressionShortMax ), 0, self:Health() * self.flCombatStateSuppressionShortRec * FrameTime() )
		self.flCombatStateSuppressionLong = math.Approach( math.Clamp( self.flCombatStateSuppressionLong, 0, self:Health() * self.flCombatStateSuppressionLongMax ), 0, self:Health() * self.flCombatStateSuppressionLongRec * FrameTime() )
		local vDesAim = self:GetDesiredAimVector()
		local aDesAim = vDesAim:Angle()
		local ppAimPitch = self:LookupPoseParameter "aim_pitch"
		local aAim = self:GetAngles()
		if ppAimPitch != -1 then
			local des = math.AngleDifference( aDesAim.p, self:GetAngles().p + self:GetPoseParameter( "aim_pitch" ) )
			local f = self.flTurnRate / self.flBodyTensity * FrameTime()
			self:SetPoseParameter( "aim_pitch", self:GetPoseParameter( "aim_pitch" ) + math.Clamp( des * self.flBodyTensity, -f, f ) )
			aAim.p = aAim.p + self:GetPoseParameter "aim_pitch"
		end
		local ppAimYaw = self:LookupPoseParameter "aim_yaw"
		if ppAimYaw != -1 then
			local des = math.AngleDifference( aDesAim.y, self:GetAngles().y + self:GetPoseParameter( "aim_yaw" ) )
			local f = self.flTurnRate / self.flBodyTensity * FrameTime()
			self:SetPoseParameter( "aim_yaw", self:GetPoseParameter( "aim_yaw" ) + math.Clamp( des * self.flBodyTensity, -f, f ) )
			aAim.y = aAim.y + self:GetPoseParameter "aim_yaw"
		end
		self:CalcCombatState()
		self.vAim = aAim:Forward()
		self.loco:SetMaxYawRate( self.flTurnRate * math.Clamp( math.abs( math.AngleDifference( aDesAim.y, self:GetAngles().y ) ), 0, 90 ) * .01111111111 )
		for _ = 1, 8 do self.loco:FaceTowards( self:GetPos() + vDesAim ) end
		self:Look()
		ProtectedCall( function() self:Behaviour() end )
		coroutine.yield()
	end
end

/*
ENT.bCanClimbLadders = false
//Note That This is NOT Climbing Ladders, It's Climbing ANYTHING, Like Left 4 Dead 2 Infected
ENT.bCanClimb = false

ENT.bSimpleDuck = false //Can Only Duck Very Simply as The Name Suggests - Either Ducked, or Not Ducked
ENT.bCanMove = false
ENT.bCanMoveShoot = false
ENT.bCanDuck = false
ENT.bCanDuckShoot = false
ENT.bCanDuckMove = false
ENT.bCanDuckMoveShoot = false
*/

function ENT:Crouching() return false end
//Dont Worry, if bSimpleDuck is true, This will Only be Supplied with
//Either a 0 or a 1, as Opposed to Any Value in The [ 0, 1 ] Range
function ENT:SetCrouchTarget( flTarget ) end
function ENT:GetCrouchTarget() return 1 end
