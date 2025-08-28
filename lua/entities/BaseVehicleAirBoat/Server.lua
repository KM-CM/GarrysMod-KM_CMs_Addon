ENT.TRAVERSES = TRAVERSES_WATER + TRAVERSES_GROUND

ENT.flMass = 500
ENT.flBuoyancy = .5

ENT.sMotorSpin = "AirBoat_Motor_Spin"
ENT.sMotorIdle = "AirBoat_Motor_Idle"

ENT.sFanSpin = "AirBoat_Fan_Spin"
ENT.sFanIdle = "AirBoat_Fan_Idle"

ENT.flRoundsPerMinute = 0
ENT.flRoundsPerMinuteSpeed = 1200
ENT.flRoundsPerMinuteIdle = 800
ENT.flRoundsPerMinuteLimit = 3000

ENT.flTopSpeed = 1400
ENT.flAcceleration = 1400
ENT.flTurnSpeedBase = 200 //When Not Moving
ENT.flTurnSpeedSpin = 100 //This is Added as We Go to Full Throttle

ENT.flTurnSpeed = 0

ENT.sPropBodyGroupSolid = "Prop_Solid"
ENT.sPropBodyGroupBlurry = "Prop_Blur2"

ENT.sWeaponBodyGroup = "Weapon"
ENT.sWeaponAttachment = "gun" //This Sucks... WHO THE HELL NAMED THE ATTACHMENTS?!
ENT.sWeaponPitchPoseParameter = "vehicle_weapon_pitch"
ENT.sWeaponYawPoseParameter = "vehicle_weapon_yaw"
ENT.flAimSpeed = 180
ENT.Weapon_flDelay = .1
ENT.Weapon_flDamage = 80
ENT.Weapon_flSpreadX = .02
ENT.Weapon_flSpreadY = .02
function ENT:CanWeapon() return self:FindBodygroupByName( self.sWeaponBodyGroup ) != -1 end
function ENT:HasWeapon() return self:GetBodygroup( self:FindBodygroupByName( self.sWeaponBodyGroup ) ) == 1 end

ENT.flNextShot = 0

function ENT:FireWeapon()
	if !self:HasWeapon() || CurTime() <= self.flNextShot then return end
	local l = self:LookupAttachment( self.sWeaponAttachment )
	local at = self:GetAttachment( l )
	if !at then return end
	self:FireBullets {
		Src = at.Pos,
		Dir = at.Ang:Forward(),
		Damage = self.Weapon_flDamage,
		Spread = Vector( self.Weapon_flSpreadX, self.Weapon_flSpreadY ),
		Attacker = IsValid( self.pDriver ) && self.pDriver || self
	}
	self:EmitSound "M249SAW_Shot"
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( l )
	ed:SetFlags( 7 )
	util.Effect( "MuzzleFlash", ed )
	self.flNextShot = CurTime() + self.Weapon_flDelay
end

ENT.sPropSpinSequence = "propeller_spin1"
//As Sequence PlayBack Rate of sPropSpinSequence
ENT.flPropSolidUnTil = 3.5
ENT.flPropBlurryAfter = 1.5
ENT.flMaxRotorSequenceSpeed = 4

DEFINE_BASECLASS "BaseVehicle" //For The BaseClass Variable...

function ENT:Initialize()
	local s = CreateSound( self, self.sMotorSpin )
	s:PlayEx( 0, 100 )
	self.pMotorSpin = s
	local s = CreateSound( self, self.sMotorIdle )
	s:PlayEx( 0, 100 )
	self.pMotorIdle = s
	local s = CreateSound( self, self.sFanSpin )
	s:PlayEx( 0, 100 )
	self.pFanSpin = s
	local s = CreateSound( self, self.sFanIdle )
	s:PlayEx( 0, 100 )
	self.pFanIdle = s
	BaseClass.Initialize( self )
end

function ENT:OnRemove()
	local s = self.pMotorSpin
	if s then s:Stop() end
	local s = self.pMotorIdle
	if s then s:Stop() end
	local s = self.pFanSpin
	if s then s:Stop() end
	local s = self.pFanIdle
	if s then s:Stop() end
end

function ENT:TurnLeft()
	local p = self:GetPhysicsObject()
	if IsValid( p ) then
		p:AddAngleVelocity( Vector( 0, 0, self.flTurnSpeed * FrameTime() ) )
	end
end
function ENT:TurnRight()
	local p = self:GetPhysicsObject()
	if IsValid( p ) then
		p:AddAngleVelocity( Vector( 0, 0, -self.flTurnSpeed * FrameTime() ) )
	end
end

function ENT:DoesWeaponHit( v )
	local at = self:GetAttachment( self:LookupAttachment( self.sWeaponAttachment ) )
	if !at then return end
	local a = at.Ang
	local d = ( v - at.Pos ):Angle()
	if math.AngleDifference( a[ 1 ], d[ 1 ] ) > 1 || math.AngleDifference( a[ 2 ], d[ 2 ] ) > 1 then return end
	if util.TraceLine( {
		start = at.Pos,
		endpos = v,
		filter = { self },
		mask = MASK_SHOT_HULL
	} ).Hit then return end
	return true
end

function ENT:AimWeapon( vAim )
	if !self:HasWeapon() then return end
	local at = self:GetAttachment( self:LookupAttachment( self.sWeaponAttachment ) )
	if !at then return end
	local aLocalTarget = WorldToLocal( vAim, Angle(), at.Pos, at.Ang ):Angle()
	local p, y = math.NormalizeAngle( aLocalTarget.p ), math.NormalizeAngle( aLocalTarget.y )
	local flSpeed = self.flAimSpeed * FrameTime()
	local flSpeedNeg = -flSpeed
	self:SetPoseParameter( self.sWeaponPitchPoseParameter, self:GetPoseParameter( self.sWeaponPitchPoseParameter ) + math.Clamp( p, flSpeedNeg, flSpeed ) )
	self:SetPoseParameter( self.sWeaponYawPoseParameter, self:GetPoseParameter( self.sWeaponYawPoseParameter ) + math.Clamp( y, flSpeedNeg, flSpeed ) )
end

function ENT:Tick()
	local f = self.flRoundsPerMinute
	local flIdle = self.flRoundsPerMinuteIdle
	local flLimit = self.flRoundsPerMinuteLimit
	local s = self.pMotorSpin
	local flSpin
	if s then
		flSpin = math.Clamp( math.Remap( f, flIdle, flLimit, 0, 1 ), 0, 1 )
		s:ChangeVolume( flSpin )
		s:ChangePitch( math.Clamp( math.Remap( f, 0, flLimit, 0, 100 ), 0, 100 ) )
	end
	local s = self.pMotorIdle
	if s then
		s:ChangeVolume( 1 - flSpin )
		s:ChangePitch( math.Clamp( math.Remap( f, 0, flIdle, 0, 100 ), 0, 100 ) )
	end
	local iPropLayer = self.iPropLayer
	local flMaxRotorSequenceSpeed = self.flMaxRotorSequenceSpeed
	local s = math.Clamp( math.Remap( f, flIdle, flLimit, 0, flMaxRotorSequenceSpeed ), 0, flMaxRotorSequenceSpeed )
	if iPropLayer then
		self:SetLayerPlaybackRate( iPropLayer, self.bPropReverse && -s || s )
		if s <= self.flPropSolidUnTil then
			self:SetBodygroup( self:FindBodygroupByName( self.sPropBodyGroupSolid ), 1 )
		else
			self:SetBodygroup( self:FindBodygroupByName( self.sPropBodyGroupSolid ), 0 )
		end
		if s > self.flPropBlurryAfter then
			self:SetBodygroup( self:FindBodygroupByName( self.sPropBodyGroupBlurry ), 1 )
		else
			self:SetBodygroup( self:FindBodygroupByName( self.sPropBodyGroupBlurry ), 0 )
		end
	else
		iPropLayer = self:AddGestureSequence( self:LookupSequence( self.sPropSpinSequence ), false )
		self.iPropLayer = iPropLayer
		self:SetLayerPlaybackRate( iPropLayer, 0 )
	end
	local p = self:GetPhysicsObject()
	if IsValid( p ) then
		local flSpeed = math.Remap( s, 0, flMaxRotorSequenceSpeed, 0, self.flTopSpeed )
		self.flTurnSpeed = self.flTurnSpeedBase + self.flTurnSpeedSpin * s
		local v = self:GetRight() * ( self.bPropReverse && flSpeed || -flSpeed ) - p:GetVelocity()
		p:AddVelocity( v:GetNormalized() * math.min( v:Length(), self.flAcceleration ) * FrameTime() )
	end
	if !IsValid( self.pDriver ) then self.flRoundsPerMinute = math.Approach( self.flRoundsPerMinute, 0, self.flRoundsPerMinuteSpeed * FrameTime() ) end
end
function ENT:PlayerControls( ply, cmd )
	local b
	if cmd:KeyDown( IN_FORWARD ) then
		self.bPropReverse = nil
		b = true
	elseif cmd:KeyDown( IN_BACK ) then
		self.bPropReverse = true
		b = true
	end
	if cmd:KeyDown( IN_ATTACK ) then self:FireWeapon() end
	if self:HasWeapon() then
		self:AimWeapon( util.TraceLine( {
			start = ply:EyePos(),
			endpos = ply:EyePos() + ply:GetAimVector() * 999999,
			mask = MASK_SOLID,
			filter = { self, ply }
		} ).HitPos )
	end
	local bLeft, bRight = cmd:KeyDown( IN_MOVELEFT ), cmd:KeyDown( IN_MOVERIGHT )
	if bLeft && bRight then
	elseif bLeft then self:TurnLeft()
	elseif bRight then self:TurnRight() end
	if b then
		self.flRoundsPerMinute = math.Approach( self.flRoundsPerMinute, self.flRoundsPerMinuteLimit, self.flRoundsPerMinuteSpeed * FrameTime() )
	else
		self.flRoundsPerMinute = math.Approach( self.flRoundsPerMinute, self.flRoundsPerMinuteIdle, self.flRoundsPerMinuteSpeed * FrameTime() )
	end
end

function ENT:GetShootPos()
	if !self:HasWeapon() then return end
	local at = self:GetAttachment( self:LookupAttachment( self.sWeaponAttachment ) )
	if !at then return end
	return at.Pos
end

function ENT:Move( vDirection, flSpeed )
	flSpeed = flSpeed * math.abs( self:GetRight():Dot( vDirection ) )
	self.flRoundsPerMinute = math.Approach( self.flRoundsPerMinute, math.max( self.flRoundsPerMinuteIdle, math.Remap( flSpeed, 0, self.flTopSpeed, self.flRoundsPerMinuteIdle, self.flRoundsPerMinuteLimit ) ), self.flRoundsPerMinuteSpeed * FrameTime() )
	self.bPropReverse = vDirection:Dot( self:GetRight() ) > 0
end
function ENT:Stay() self.flRoundsPerMinute = math.Approach( self.flRoundsPerMinute, self.flRoundsPerMinuteIdle, self.flRoundsPerMinuteSpeed * FrameTime() ) end
function ENT:Turn( vDirection )
	local p = self:GetPhysicsObject()
	if IsValid( p ) then
		local f = self.flTurnSpeed
		p:AddAngleVelocity( Vector( 0, 0, math.Clamp( math.AngleDifference( vDirection:Angle().y, self:GetForwardDirection():Angle().y ) * .0055555555555556 * f - p:GetAngleVelocity().z, -f, f ) * FrameTime() ) )
	end
end
