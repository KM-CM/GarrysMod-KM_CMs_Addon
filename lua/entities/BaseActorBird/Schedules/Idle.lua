local util_TraceLine = util.TraceLine
function ENT:CanPeckRightNow()
	local vPos = self:GetPos()
	local vUp = self:GetUp()
	local vDown = vPos - vUp * self:OBBMins().z
	local tPeckable = self.tPeckable
	local trDown = util_TraceLine {
		start = vDown,
		endpos = vDown - vUp * self.flDownPeckableDist,
		mask = MASK_SOLID,
		filter = self
	}
	//Cant Peck when in Air!
	if !trDown.Hit then return {} end
	if tPeckable[ trDown.MatType ] == nil then trDown = nil end
	local vDirection = self:GetForward()
	local vForward = self:GetPos() + self:OBBCenter() + vDirection * self:OBBMaxs().x
	local trForward = util_TraceLine {
		start = vForward,
		endpos = vForward + vDirection * self.flForwardPeckableDist,
		mask = MASK_SOLID,
		filter = self
	}
	if tPeckable[ trForward.MatType ] == nil then trForward = nil end
	if trForward == nil && trDown == nil then return end
	return true
end

ENT.flNotHungryPeckStartChance = 15000
ENT.flReallyNotHungryPeckStartChance = 30000

Actor_RegisterSchedule( "BirdIdle", function( self, sched )
	local flHungerRatio = self.flHunger / self.flHungerLimit
	if flHungerRatio < self.flHungry then self:SetSchedule( self:CanPeckRightNow() && "BirdPeck" || "BirdFindFood" ) return end
	if flHungerRatio < 1 && math.random( math.Remap( flHungerRatio, self.flHungry, 1, self.flNotHungryPeckStartChance, self.flReallyNotHungryPeckStartChance ) * FrameTime() ) == 1 && self:CanPeckRightNow() then self:SetSchedule "BirdPeck" return end
	local pFlapLoop, pSoarLoop = self.pFlapLoop, self.pSoarLoop
	pFlapLoop:ChangeVolume( 0, FrameTime() * 4 )
	pSoarLoop:ChangeVolume( 0, FrameTime() * 4 )
end )

Actor_RegisterSchedule( "BirdFindFood", function( self, sched )
	if self:CanPeckRightNow() then self:SetSchedule "BirdPeck" end
end )

ENT.sPeckFloorSequence = "eat_a"
ENT.sPeckWallSequence = "eat_b"

//Those are Multipliers of The Current Health!
ENT.flPeckSaturationReFillBase = .012
ENT.flPeckHungerReFillBase = .012

ENT.flNotHungryPeckSpeed = .66
ENT.flReallyHungryPeckSpeed = 1.33

ENT.flDownPeckableDist = 12
ENT.flForwardPeckableDist = 46

//ENT.sPeckCooSound = nil

ENT.flNotHungryPeckCooChance = 20000
ENT.flReallyHungryPeckCooChance = 5000

ENT.flNotHungryPeckStopChance = 15000
ENT.flReallyNotHungryPeckStopChance = 5000

//1 = Limit, 0 = Ate Enough
Actor_RegisterSchedule( "BirdPeck", function( self, sched )
	if self.flHunger >= self.flHungerLimit then return { 1 } end
	local vPos = self:GetPos()
	local vUp = self:GetUp()
	local vDown = vPos - vUp * self:OBBMins().z
	local tPeckable = self.tPeckable
	local trDown = util_TraceLine {
		start = vDown,
		endpos = vDown - vUp * self.flDownPeckableDist,
		mask = MASK_SOLID,
		filter = self
	}
	//Cant Peck when in Air!
	if !trDown.Hit then return {} end
	local flDownPeckable = tPeckable[ trDown.MatType ]
	//That Material... It is... Impeccable!
	if flDownPeckable == nil then trDown = nil end
	local vDirection = self:GetForward()
	local vForward = self:GetPos() + self:OBBCenter() + vDirection * self:OBBMaxs().x
	local trForward = util_TraceLine {
		start = vForward,
		endpos = vForward + vDirection * self.flForwardPeckableDist,
		mask = MASK_SOLID,
		filter = self
	}
	local flForwardPeckable = tPeckable[ trForward.MatType ]
	if flForwardPeckable == nil then trForward = nil end
	if trForward == nil && trDown == nil then return {} end
	local bDown = flDownPeckable && ( !flForwardPeckable || flDownPeckable >= flForwardPeckable )
	local flHungerRatio = self.flHunger / self.flHungerLimit
	local f = flHungerRatio
	f = f <= self.flHungry && math.Remap( f, self.flHungry, 0, 1, self.flReallyHungryPeckSpeed ) || math.Remap( f, self.flHungry, 1, 1, self.flNotHungryPeckSpeed )
	if CurTime() > ( sched.flPeckFloorSequence || 0 ) then
		self:ResetSequenceInfo()
		sched.flPeckFloorSequence = CurTime() + self:SetSequence( bDown && self.sPeckFloorSequence || self.sPeckWallSequence ) * f
	end
	self:SetPlaybackRate( f )
	f = bDown && flDownPeckable || flForwardPeckable
	local flFrameTime = FrameTime()
	self.flHunger = math.Clamp( self.flHunger + flFrameTime * self:GetMaxHealth() * self.flPeckHungerReFillBase * f, 0, self.flHungerLimit )
	self.flSaturation = math.Clamp( self.flSaturation + flFrameTime * self:GetMaxHealth() * self.flPeckSaturationReFillBase * f, 0, self.flSaturationLimit )
	if flHungerRatio >= 1 then return { 1 }
	elseif flHungerRatio > self.flHungry && math.random( math.Remap( flHungerRatio, self.flHungry, 1, self.flNotHungryPeckStopChance, self.flReallyNotHungryPeckStopChance ) * flFrameTime ) == 1 then return { 0 } end
	local sPeckCooSound = self.sPeckCooSound
	if sPeckCooSound then
		f = flHungerRatio
		f = f <= self.flHungry && math.Remap( f, self.flHungry, 0, 1, self.flReallyHungryPeckCooChance ) || math.Remap( f, self.flHungry, 1, 1, self.flNotHungryPeckCooChance )
		if math.random( f * flFrameTime ) == 1 then self:EmitSound( sPeckCooSound ) end
	end
	local pFlapLoop, pSoarLoop = self.pFlapLoop, self.pSoarLoop
	pFlapLoop:ChangeVolume( 0, FrameTime() * 4 )
	pSoarLoop:ChangeVolume( 0, FrameTime() * 4 )
end )
