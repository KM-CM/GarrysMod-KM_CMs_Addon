local math = math
local math_Clamp = math.Clamp
local math_min = math.min
local math_abs = math.abs

local navmesh_GetNearestNavArea = navmesh.GetNearestNavArea

function ENT:FindRetreatCover( vCover, tEnemies )
	local Path = Path "Follow"
	local enemy = self.Enemy
	if !IsValid( enemy ) then return end
	local area = navmesh.GetNearestNavArea( self:GetPos() )
	if area == nil then return end
	local flDistSqr = self:GetPos():Distance( enemy:GetPos() ) + self.flCoverMoveDistance * math_abs( math_min( 0, self.flCombatState, self.flCombatStateSmall ) )
	flDistSqr = flDistSqr * flDistSqr
	local tQueue, tVisited = { { area, 0 } }, {}
	local bCantClimb, flJumpHeight, flNegDeathDrop = !self.bCanClimb, self.loco:GetJumpHeight(), -self.loco:GetDeathDropHeight()
	local tAllies = self:GetAlliesByClass()
	local flOff = math.max( math.abs( self:OBBMaxs().x ), math.abs( self:OBBMins().x ) ) * 1.5
	local flOffDistSqr = flOff * 3
	flOffDistSqr = flOffDistSqr * flOffDistSqr
	local vOffStanding, vOffDucking = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && self.vHullDuckMaxs.z != self.vHullMaxs.z then vOffDucking = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	local tShootables = {}
	for enemy in pairs( tEnemies ) do
		if !IsValid( enemy ) || !HasRangeAttack( enemy ) then continue end
		for _, vec in ipairs( self:CalcEnemyShootPositions( enemy ) ) do
			table.insert( tShootables, { vec, enemy } )
		end
	end
	local vEnemy = enemy:GetPos()
	local vToEnemy = vEnemy - vCover
	vToEnemy.z = 0
	vToEnemy:Normalize()
	local o, v = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && self.vHullDuckMaxs.z != self.vHullMaxs.z then v = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	local tAllies, f = self:GetAlliesByClass(), self:BoundingRadius()
	f = f * f
	if v then
		for vec in self:SearchNodes() do
			local p = vec + v
			local dir = vEnemy - vec
			dir.z = 0
			dir:Normalize()
			local v = vec - vCover
			v.z = 0
			if v:GetNormalized():Dot( vToEnemy ) > 0 then continue end
			if util.TraceLine( {
				start = p,
				endpos = p + dir * self.vHullMaxs.x * 2,
				mask = MASK_SHOT_HULL,
				filter = function( ent ) return !( ent:IsPlayer() || ent:IsNPC() || ent:IsNextBot() ) end
			} ).Hit then
				if tAllies then
					for ally in pairs( tAllies ) do
						if self == ally then continue end
						if ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= f then self.vCover = nil return end
					end
				end
				return vec, !util.TraceLine( {
					start = vec + o,
					endpos = vec + o + dir * self.vHullMaxs.x * 2,
					mask = MASK_SHOT_HULL,
					filter = function( ent ) return !( ent:IsPlayer() || ent:IsNPC() || ent:IsNextBot() ) end
				} ).Hit
			end
		end
	else
		for vec in self:SearchNodes() do
			local p = vec + v
			local dir = vEnemy - vec
			dir.z = 0
			dir:Normalize()
			if util.TraceLine( {
				start = p,
				endpos = p + dir * self.vHullMaxs.x * 2,
				mask = MASK_SHOT_HULL,
				filter = function( ent ) return !( ent:IsPlayer() || ent:IsNPC() || ent:IsNextBot() ) end
			} ).Hit then
				if tAllies then
					for ally in pairs( tAllies ) do
						if self == ally then continue end
						if ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= f then self.vCover = nil return end
					end
				end
				return vec
			end
		end
	end
end
