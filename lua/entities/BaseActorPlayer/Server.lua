ENT.vHullMins = HULL_HUMAN_MINS
ENT.vHullMaxs = HULL_HUMAN_MAXS
ENT.vHullDuckMins = HULL_HUMAN_DUCK_MINS
ENT.vHullDuckMaxs = HULL_HUMAN_DUCK_MAXS

ENT.bSimpleDuck = true
ENT.bCanMove = true
ENT.bCanMoveShoot = true
ENT.bCanDuck = true
ENT.bCanDuckShoot = true
ENT.bCanDuckMove = true
ENT.bCanDuckMoveShoot = true

ENT.flTopSpeed = HUMAN_RUN_SPEED
ENT.flProwlSpeed = HUMAN_PROWL_SPEED
ENT.flWalkSpeed = HUMAN_WALK_SPEED

ENT.iMotionActivity = -1

function ENT:BodyUpdate() if self:GetSequence() == self.CalcSeqOverride then self:BodyMoveXY() else self:FrameAdvance() end end

DEFINE_BASECLASS "BaseActor"
function ENT:Initialize()
	BaseClass.Initialize( self )
	if self:PhysicsInitShadow( false, false ) then self:GetPhysicsObject():SetMass( 85 ) end
end

function ENT:TranslateActivity( n ) return hook.Run( "TranslateActivity", self, n ) end

local sv_gravity = GetConVar "sv_gravity"
function ENT:Behaviour()
	local act, seq = hook.Run( "CalcMainActivity", self, self.loco:GetVelocity() )
	if !self.CalcIdeal then self.CalcIdeal = -1 end
	local act = self:TranslateActivity( self.CalcIdeal )
	//if self:GetActivity() != act then self:StartActivity( act ) end
	if seq == nil || seq == -1 then self.CalcSeqOverride = self:SelectWeightedSequence( act ) end
	if self:GetSequence() != self.CalcSeqOverride then
		self:ResetSequence( self.CalcSeqOverride )
		self:SetSequence( self.CalcSeqOverride )
	end
	local flMax, vel = self:GetSequenceGroundSpeed( self.CalcSeqOverride ), self.loco:GetVelocity()
	self:SetPlaybackRate( vel:Length() / flMax )
	hook.Run( "UpdateAnimation", self, vel, flMax )
	self.loco:SetGravity( sv_gravity:GetFloat() )
	self.loco:SetJumpHeight( self:CalcJumpHeight() )
	if self.CalcIdeal == ACT_MP_CROUCH_IDLE || self.CalcIdeal == ACT_MP_CROUCHWALK then
		local hm, hn, cm, cn = self.vHullDuckMins, self.vHullDuckMaxs, self:GetCollisionBounds()
		if hm != cm || hn != cn then
			self:SetCollisionBounds( hm, hn )
			if !IsValid( self:GetParent() ) && self:PhysicsInitShadow( false, false ) then
				local p = self:GetPhysicsObject()
				if IsValid( p ) then p:SetMass( 85 ) end
			end
		end
	else
		local hm, hn, cm, cn = self.vHullMins, self.vHullMaxs, self:GetCollisionBounds()
		if hm != cm || hn != cn then
			self:SetCollisionBounds( hm, hn )
			if !IsValid( self:GetParent() ) && self:PhysicsInitShadow( false, false ) then
				local p = self:GetPhysicsObject()
				if IsValid( p ) then p:SetMass( 85 ) end
			end
		end
	end
	self:RunMind()
end

function ENT:OnDeath( dmg ) end

function ENT:OnKilled( dmg )
	if self.bDead then return end
	self:EmitSound( dmg:IsDamageType( DMG_FALL ) && "Player.FallGib" || "Player.Death" )
	self:OnDeath( dmg )
	self.bDead = true
	self:ActorOnDeath()
	hook.Run( "OnNPCKilled", self, dmg:GetAttacker(), dmg:GetInflictor() )
	self:BecomeRagdoll( dmg )
end
