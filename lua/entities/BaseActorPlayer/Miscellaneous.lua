local sv_friction, sv_gravity = GetConVar "sv_friction", GetConVar "sv_gravity"
ENT.flNextJumpInternal = 0
function ENT:MoveAlongPath( Path, flSpeed, flHeight, tFilter )
	if flHeight == nil then flHeight = 1 end
	self:SetCrouchTarget( flHeight )
	if flHeight > .5 then flSpeed = math.min( self.flTopSpeed, flSpeed ) else flSpeed = math.min( self.flWalkSpeed, flSpeed ) end
	self.loco:SetDesiredSpeed( flSpeed )
	local f = flSpeed * ACCELERATION_NORMAL
	self.loco:SetAcceleration( f )
	self.loco:SetDeceleration( f )
	local goal = Path:GetCurrentGoal()
	if goal && CurTime() > self.flNextJumpInternal then
		local vel = GetVelocity( self )
		local vlen = vel:Length()
		local len = math.max( self:OBBMaxs().z * 2, vlen )
		local dir
		if Path:GetClosestPosition( self:GetPos() ):DistToSqr( self:GetPos() ) <= ( self.flPathTolerance * self.flPathTolerance ) then
			dir = goal.forward
			dir.z = 0
			dir:Normalize()
		else
			dir = goal.pos - self:GetPos()
			dir.z = 0
			dir:Normalize()
		end
		local tr = util.TraceLine {
			start = self:GetPos() + self:OBBCenter(),
			endpos = self:GetPos() + self:OBBCenter() + dir * len,
			filter = tFilter || { self },
			mask = MASK_SOLID
		}
		local ent = tr.Entity
		/*At First I Thought It was a Good Idea to Jump Above Allies, But in Practice,
		That Just Made Hordes of Antlion Chaotic. Because They werent Jumping to Intercept,
		Which was a Mechanic I was Creating, But Instead Jumping Above EachOther*/
		if tr.Hit && ( !IsValid( ent ) || self:Disposition( ent ) != D_LI ) then
			if self:IsOnGround() then
				local flNewHeight = 0 // NOT Related to flHeight!
				local flMaxJumpLength = ( 2 * sv_gravity:GetFloat() * self.loco:GetJumpHeight() ) ^ .5
				local bCantClimb = !self.bCanClimb
				while true do
					flNewHeight = flNewHeight + 16
					if bCantClimb && flNewHeight > self.loco:GetJumpHeight() || util.TraceLine( {
						start = self:GetPos() + self:GetUp() * self:OBBMaxs().z,
						endpos = self:GetPos() + self:GetUp() * self:OBBMaxs().z + Vector( 0, 0, flNewHeight ),
						filter = { self },
						mask = MASK_SOLID
					} ).Hit then break end
					local tr = util.TraceLine {
						start = self:GetPos() + self:OBBCenter() + Vector( 0, 0, flNewHeight ),
						endpos = self:GetPos() + self:OBBCenter() + Vector( 0, 0, flNewHeight ) + dir * len,
						filter = { self },
						mask = MASK_SOLID
					}
					if tr.Hit then continue end
					local flDist = tr.HitPos:Distance( self:GetPos() )
					if tr.HitPos:Distance2D( self:GetPos() ) > flMaxJumpLength then break end
					local ntr = util.TraceLine {
						start = tr.HitPos,
						endpos = tr.HitPos + Vector( 0, 0, flDist ),
						filter = { self },
						mask = MASK_SOLID
					}
					if ntr.Hit then continue end
					self:SetCrouchTarget( 0 )
					self.loco:JumpAcrossGap( tr.HitPos, self:GetForward() )
					hook.Run( "OnPlayerJump", self, self:GetJumpPower() )
					self.flNextJumpInternal = CurTime() + .1
				end
			end
		end
	end
	Path:Update( self )
end

function ENT:Stand( flHeight )
	if flHeight == nil then flHeight = 1 end
	self:SetCrouchTarget( flHeight )
end

function ENT:Tick()
	local ang = self:GetAngles()
	if ang[ 1 ] != 0 || ang[ 3 ] != 0 then self:SetAngles( Angle( 0, ang[ 2 ], 0 ) ) end
end
