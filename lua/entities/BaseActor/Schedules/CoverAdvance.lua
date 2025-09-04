local math = math
local math_Clamp = math.Clamp
local math_min = math.min
local math_abs = math.abs

local navmesh_GetNearestNavArea = navmesh.GetNearestNavArea

function ENT:FindAdvanceCover( vCover, tEnemies )
	local Path = Path "Follow"
	local enemy = self.Enemy
	if !IsValid( enemy ) then return end
	self:ComputeFlankPath( Path, enemy )
	local _, _, t = self:FindSuppressEnemy( vCover, tEnemies, self.bCoverDuck )
	//If We can Hit Someone from Here - Dont Bother
	local flAdvance = self.flCoverMoveDistance * math_min( self.flCombatState, self.flCombatStateSmall )
	local flTarget = IsValid( t ) && flAdvance || self:FindPathBattleLine( Path, tEnemies )
	if flTarget == nil then return end
	local flAdvanceSqr = flAdvance * flAdvance
	local vPos = Path:GetPositionOnPath( flTarget )
	local area = navmesh.GetNearestNavArea( vPos )
	if !area then return end
	local vEnemy = enemy:GetPos()
	local o, v = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && self.vHullDuckMaxs.z != self.vHullMaxs.z then v = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	local tAllies, f = self:GetAlliesByClass(), self:BoundingRadius()
	f = f * f
	if v then
		for vec in self:SearchNodes( vPos ) do
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
