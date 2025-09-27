ENT.tPreScheduleResetVariables.vActualCover = false

function ENT:GatherCoverBounds()
	if self.vHullDuckMaxs && self.vHullDuckMaxs.z != self.vHullMaxs.z then return Vector( 0, 0, self.vHullDuckMaxs.z * .65625 ) end
	return Vector( 0, 0, self.vHullMaxs.z )
end

include "CoverMove.lua"

Actor_RegisterSchedule( "TakeCover", function( self, sched )
	local tEnemies = sched.tEnemies || self.tEnemies
	if table.IsEmpty( tEnemies ) then return {} end
	local enemy = sched.Enemy
	if !IsValid( enemy ) then enemy = self.Enemy if !IsValid( enemy ) then return {} end end
	self.bWantsCover = true
	if self.vCover then
		local vec = self.vCover
		local tAllies = self:GetAlliesByClass()
		if tAllies then
			local pCover = self.pCover
			for ally in pairs( tAllies ) do
				if self == ally then continue end
				if ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= self:BoundingRadius() ^ 2 then self.vCover = nil return end
			end
		end
		local v = vec + self:GatherCoverBounds()
		local dir = enemy:GetPos() - vec
		dir.z = 0
		dir:Normalize()
		if !util.TraceLine( {
			start = v,
			endpos = v + dir * self.vHullMaxs.x * 4,
			mask = MASK_SHOT_HULL,
			filter = function( ent ) return !( ent:IsPlayer() || ent:IsNPC() || ent:IsNextBot() ) end
		} ).Hit then self.vCover = nil return end
		if !sched.Path then sched.Path = Path "Follow" end
		self:ComputePath( sched.Path, self.vCover )
		if math.abs( sched.Path:GetLength() - sched.Path:GetCursorPosition() ) <= self.flPathGoalTolerance then return { true } end
		self.vActualCover = self.vCover
		local tNearestEnemies = {}
		for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tNearestEnemies, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
		table.SortByMember( tNearestEnemies, 2, true )
		local c = self:GetWeaponClipPrimary()
		if c != -1 && c <= 0 then self:WeaponReload() end
		local tAllies, pEnemy = self:GetAlliesByClass()
		for _, d in ipairs( tNearestEnemies ) do
			local ent = d[ 1 ]
			local v = ent:GetPos() + ent:OBBCenter()
			local tr = util.TraceLine {
				start = self:GetShootPos(),
				endpos = v,
				mask = MASK_SHOT_HULL,
				filter = { self, ent }
			}
			if !tr.Hit || tr.Fraction > self.flSuppressionTraceFraction && tr.HitPos:Distance( v ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
				local b = true
				if ent.GAME_tSuppressionAmount then
					local flThreshold, flSoFar = ent:Health() * .1, 0
					for other, am in pairs( ent.GAME_tSuppressionAmount ) do
						if other == self || self:Disposition( other ) != D_LI || !other.bSuppressing then continue end
						flSoFar = flSoFar + am
						if flSoFar > flThreshold then continue end
					end
					if flSoFar > flThreshold then continue end
				else b = true end
				if b then
					self.vDesAim = ( ent:GetPos() + ent:OBBCenter() - self:GetShootPos() ):GetNormalized()
					pEnemy = ent
					if self:CanAttackHelper( ent:GetPos() + ent:OBBCenter() ) then self:RangeAttack() end
					break
				end
			end
		end
		if IsValid( pEnemy ) then
			if self:CanExpose() then
				if self.bCoverDuck == true then sched.bCoverStand = nil
				elseif sched.bCoverStand == nil then sched.bCoverStand = math.random( 2 ) == 1 end
				local flDist = self.flWalkSpeed * 4
				flDist = flDist * flDist
				if self:GetPos():DistToSqr( self.vCover ) > flDist || sched.bCoverStand then
					local flDist = self.flProwlSpeed * 4
					flDist = flDist * flDist
					if self:GetPos():DistToSqr( self.vCover ) > flDist then
						self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 )
					else self:MoveAlongPath( sched.Path, self.flProwlSpeed, 1 ) end
				else self:MoveAlongPath( sched.Path, self.flWalkSpeed, 0 ) end
			else self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 ) end
		else
			local goal = sched.Path:GetCurrentGoal()
			if goal then
				self.vDesAim = ( goal.pos - self:GetPos() ):GetNormalized()
				self:ModifyMoveAimVector( self.vDesAim, self.flTopSpeed, 1 )
			end
			self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 )
		end
	else
		self.vCover = nil
		local vEnemy = enemy:GetPos()
		local v = self:GatherCoverBounds()
		local tAllies = self:GetAlliesByClass()
		local f = self:BoundingRadius()
		f = f * f
		for vec in self:SearchNodes() do
			local p = vec + v
			local dir = vEnemy - vec
			dir.z = 0
			dir:Normalize()
			if util.TraceLine( {
				start = p,
				endpos = p + dir * self.vHullMaxs.x * 4, // Dont Check Often, so Give Them More Range to Consider "Cover"
				mask = MASK_SHOT_HULL,
				filter = function( ent ) return !( ent:IsPlayer() || ent:IsNPC() || ent:IsNextBot() ) end
			} ).Hit then
				if tAllies then
					for ally in pairs( tAllies ) do
						if self == ally then continue end
						if ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= f then continue end
					end
				end
				self.vActualCover = vec
				self.vCover = vec
				return
			end
		end
	end
end )
