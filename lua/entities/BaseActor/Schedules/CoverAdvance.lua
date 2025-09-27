local math = math
local math_Clamp = math.Clamp
local math_min = math.min
local math_abs = math.abs

local navmesh_GetNearestNavArea = navmesh.GetNearestNavArea

function ENT:FindAdvanceCover( vCover, tEnemies, flCombatStateOverride, flBattleLine )
	local Path = Path "Follow"
	local enemy = self.Enemy
	if !IsValid( enemy ) then return end
	self:ComputeFlankPath( Path, enemy )
	local flAdvance
	if flCombatStateOverride then
		flAdvance = self.flCoverMoveDistance * flCombatStateOverride
	else
		// If We can Hit Someone from Here - Dont Bother
		flAdvance = self.flCoverMoveDistance * math_min( self.flCombatState, self.flCombatStateSmall )
	end
	local flTarget = IsValid( self:FindSuppressEnemy( vCover, tEnemies, self.bCoverDuck ) ) && flAdvance || ( flBattleLine || self:FindPathBattleLine( Path, tEnemies ) )
	if flTarget == nil then return end
	local flAdvanceSqr = flAdvance * flAdvance
	local vPos = Path:GetPositionOnPath( flTarget )
	local area = navmesh.GetNearestNavArea( vPos )
	if !area then return end
	local vEnemy = enemy:GetPos()
	local o, v = Vector( 0, 0, self.vHullMaxs.z ), self:GatherCoverBounds()
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
				endpos = p + dir * self.vHullMaxs.x * 4, // Dont Check Often, so Give Them More Range to Consider "Cover"
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
				return vec, !util.TraceLine( {
					start = vec + o,
					endpos = vec + o + dir * self.vHullMaxs.x * 4,
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
				endpos = p + dir * self.vHullMaxs.x * 4, // Dont Check Often, so Give Them More Range to Consider "Cover"
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
				return vec
			end
		end
	end
end
