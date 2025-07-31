ENT.flPathTolerance = 64
ENT.flPathGoalTolerance = 8

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable
function ENT:ComputePath( Path, vGoal, Weighter )
	local goal = Path:LastSegment()
	local MyTable = CEntity_GetTable( self )
	local f = MyTable.flPathTolerance
	if goal && goal.pos:DistToSqr( vGoal ) <= ( f * f ) then return true end
	if Weighter then return Path, Path:Compute( self, vGoal, Weighter ) end
	local loco = MyTable.loco
	local bCantClimb = !( MyTable.bCanClimb || MyTable.bCanFly )
	local flDeathDropNeg = -loco:GetDeathDropHeight()
	local flStepHeight = loco:GetStepHeight()
	local flJumpHeight
	if bCantClimb then flJumpHeight = loco:GetMaxJumpHeight() end
	local IsAreaTraversable = loco.IsAreaTraversable
	return Path, Path:Compute( self, vGoal, function( area, from, ladder, elevator, length )
		if !IsValid( fromArea ) then return 0 end
		if !IsAreaTraversable( loco, area ) then return -1 end
		local dist = 0
		if IsValid( ladder ) then
			dist = ladder:GetLength()
		elseif length > 0 then
			dist = length
		else
			dist = ( area:GetCenter() - from:GetCenter() ):GetLength()
		end
		local cost = dist + from:GetCostSoFar()
		local d = from:ComputeAdjacentConnectionHeightChange( area )
		if d >= flStepHeight then
			if bCantClimb && d >= flJumpHeight then return -1 end
			cost = cost + 1.5 * dist
		elseif d < flDeathDropNeg then return -1 end
		return cost
	end )
end

//How Far Do We have to Move Along The Path to be Able to Suppress Anyone? Can Return `nil`
//TODO: Return The Nearest Ally That can Suppress The Enemy if He is Farther Along The Path Than The Suppression Vector Along It
function ENT:FindPathBattleLine( Path, tEnemies, flTolerance )
	flTolerance = flTolerance || 256
	local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	local flSuppressionTraceFraction = self.flSuppressionTraceFraction
	for I = 0, Path:GetLength(), flTolerance do
		local vec = Path:GetPositionOnPath( I )
		for enemy in pairs( tEnemies ) do
			local vShoot = enemy:GetPos() + enemy:OBBCenter()
			local tr = util.TraceLine {
				start = vec + vStand,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vec ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return I end
			local tr = util.TraceLine {
				start = vec + vDuck,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vec ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return I end
		end
	end
end

function ENT:ComputeFlankPath( Path, pEnemy ) return self:ComputePath( Path, pEnemy:GetPos() ) end
