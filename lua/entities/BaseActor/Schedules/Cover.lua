ENT.tPreScheduleResetVariables.vActualCover = false

function ENT:GatherCoverBounds()
	if self.vHullDuckMaxs && self.vHullDuckMaxs.z != self.vHullMaxs.z then return Vector( 0, 0, self.vHullDuckMaxs.z * .65625 ) end
	return Vector( 0, 0, self.vHullMaxs.z )
end

include "CoverMove.lua"
include "CoverUnReachable.lua"

local util_TraceLine = util.TraceLine

Actor_RegisterSchedule( "TakeCover", function( self, sched )
	local tEnemies = sched.tEnemies || self.tEnemies
	if table.IsEmpty( tEnemies ) then return {} end
	local enemy = sched.Enemy
	if !IsValid( enemy ) then enemy = self.Enemy if !IsValid( enemy ) then return {} end end
	self.bWantsCover = true
	if self.vCover then
		sched.pIterator = nil
		local vec = self.vCover
		self.vActualCover = self.vCover
		local v = vec + self:GatherCoverBounds()
		local dir = enemy:GetPos() - vec
		dir.z = 0
		dir:Normalize()
		if !util_TraceLine( {
			start = v,
			endpos = v + dir * self.vHullMaxs.x * 4,
			mask = MASK_SHOT_HULL,
			filter = function( ent ) return !( ent:IsPlayer() || ent:IsNPC() || ent:IsNextBot() ) end
		} ).Hit then self.vCover = nil return end
		local v = self:GetPos() + self:GatherCoverBounds()
		local dir = enemy:GetPos() - vec
		dir.z = 0
		dir:Normalize()
		local f = self.flPathGoalTolerance
		if util_TraceLine( {
			start = v,
			endpos = v + dir * self.vHullMaxs.x * 4,
			mask = MASK_SHOT_HULL,
			filter = function( ent ) return !( ent:IsPlayer() || ent:IsNPC() || ent:IsNextBot() ) end
		} ).Hit && self:GetPos():DistToSqr( vec ) <= ( f * f ) then return true end
		if !sched.Path then sched.Path = Path "Follow" end
		self:ComputePath( sched.Path, self.vCover )
		local tNearestEnemies = {}
		for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tNearestEnemies, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
		table.SortByMember( tNearestEnemies, 2, true )
		local c = self:GetWeaponClipPrimary()
		if c != -1 && c <= 0 then self:WeaponReload() end
		local tAllies, pEnemy = self:GetAlliesByClass()
		for _, d in ipairs( tNearestEnemies ) do
			local ent = d[ 1 ]
			local v = ent:GetPos() + ent:OBBCenter()
			local tr = util_TraceLine {
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
						if other == self || self:Disposition( other ) != D_LI || CurTime() <= ( other.flWeaponReloadTime || 0 ) then continue end
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
			self:MoveAlongPath( sched.Path, self.flProwlSpeed, 1 )
		else
			local goal = sched.Path:GetCurrentGoal()
			if goal then
				self.vDesAim = ( goal.pos - self:GetPos() ):GetNormalized()
				self:ModifyMoveAimVector( self.vDesAim, self.flTopSpeed, 1 )
			end
			self:MoveAlongPathToCover( sched.Path )
		end
	else
		self.vCover = nil
		local tNearestEnemies = {}
		for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tNearestEnemies, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
		table.SortByMember( tNearestEnemies, 2, true )
		local tAllies, pEnemy = self:GetAlliesByClass()
		for _, d in ipairs( tNearestEnemies ) do
			local ent = d[ 1 ]
			local v = ent:GetPos() + ent:OBBCenter()
			local tr = util_TraceLine {
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
						if other == self || self:Disposition( other ) != D_LI || CurTime() <= ( other.flWeaponReloadTime || 0 ) then continue end
						flSoFar = flSoFar + am
						if flSoFar > flThreshold then continue end
					end
					if flSoFar > flThreshold then continue end
				else b = true end
				if b then
					self.vDesAim = ( ent:GetPos() + ent:OBBCenter() - self:GetShootPos() ):GetNormalized()
					if self:CanAttackHelper( ent:GetPos() + ent:OBBCenter() ) then self:RangeAttack() end
					break
				end
			end
		end
		self:Stand( self:GetCrouchTarget() )
		local pIterator = sched.pIterator
		if !sched.pIterator then
			pIterator = self:SearchNodes()
			sched.pIterator = pIterator
		end
		local vEnemy = enemy:GetPos()
		local v = sched.vCoverBounds || self:GatherCoverBounds()
		sched.vCoverBounds = v
		local tAllies = sched.tAllies || self:GetAlliesByClass()
		sched.tAllies = tAllies
		local f = sched.flBoundingRadiusTwo || ( self:BoundingRadius() ^ 2 )
		sched.flBoundingRadiusTwo = f
		local d = self.vHullMaxs.x * 4 // We check somewhat distant positions, so give them some range to consider "cover"...
		for _ = 0, 16 do
			local vec = pIterator()
			if vec == nil then
				// REPEAT!!! AND TRY HARDER!!!
				sched.pIterator = nil
				return
			end
			local p = vec + v
			local dir = vEnemy - vec
			dir.z = 0
			dir:Normalize()
			if util_TraceLine( {
				start = p,
				endpos = p + dir * d,
				mask = MASK_SHOT_HULL,
				filter = function( ent ) return !( ent:IsPlayer() || ent:IsNPC() || ent:IsNextBot() ) end
			} ).Hit then
				if tAllies then
					local b
					for ally in pairs( tAllies ) do
						if self == ally then continue end
						if ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= f then b = true break end
					end
					if b then continue end
				end
				self.vActualCover = vec
				self.vCover = vec
				return
			end
		end
	end
end )
