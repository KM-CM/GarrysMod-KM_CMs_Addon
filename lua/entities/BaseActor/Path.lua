ENT.flPathTolerance = 64
ENT.flPathGoalTolerance = 16

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable
function ENT:ComputePath( Path, vGoal, Weighter )
	local MyTable = CEntity_GetTable( self )
	local f = MyTable.flPathTolerance
	f = f * f
	Path:MoveCursorToClosestPosition( self:GetPos() )
	if Path:GetPositionOnPath( Path:GetCursorPosition() ):DistToSqr( self:GetPos() ) <= f && Path:GetEnd():DistToSqr( vGoal ) <= f then return true end
	if Weighter then return Path, Path:Compute( self, vGoal, Weighter ) end
	local loco = MyTable.loco
	local bCantClimb = !( MyTable.bCanClimb || MyTable.bCanFly )
	local bDisAllowWater = !MyTable.bCanSwim
	local flDeathDropNeg = -loco:GetDeathDropHeight()
	local flStepHeight = loco:GetStepHeight()
	local flJumpHeight
	if bCantClimb then flJumpHeight = loco:GetMaxJumpHeight() end
	local IsAreaTraversable = loco.IsAreaTraversable
	return Path, Path:Compute( self, vGoal, function( area, from, ladder, elevator, length )
		if !IsValid( from ) then return 0 end
		if !IsAreaTraversable( loco, area ) || bDisAllowWater && area:IsUnderwater() then return -1 end
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
			if !IsValid( enemy ) then continue end
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

function ENT:FindPathBattleLineNoAllies( Path, tEnemies, flTolerance )
	flTolerance = flTolerance || 256
	local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	local flSuppressionTraceFraction = self.flSuppressionTraceFraction
	for I = 0, Path:GetLength(), flTolerance do
		local vec = Path:GetPositionOnPath( I )
		for enemy in pairs( tEnemies ) do
			if !IsValid( enemy ) then continue end
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

local bit_band = bit.band
function ENT:ComputeVehiclePath( Path, vGoal )
	local MyTable = CEntity_GetTable( self )
	local f = MyTable.flPathTolerance
	f = f * f
	local veh = MyTable.GAME_pVehicle
	Path:MoveCursorToClosestPosition( veh:GetPos() )
	if Path:GetPositionOnPath( Path:GetCursorPosition() ):Distance2DSqr( veh:GetPos() ) <= f && Path:GetEnd():DistToSqr( vGoal ) <= f then return true end
	local loco = MyTable.loco
	local flStepHeight = loco:GetStepHeight()
	local VehTable = CEntity_GetTable( veh )
	local t = veh.TRAVERSES
	local bDoCheck, bDisAllowWater, bDisAllowGround, bAllowWater = true
	if bit_band( t, TRAVERSES_AIR ) == 0 then
		bDisAllowWater, bDisAllowGround = bit_band( t, TRAVERSES_WATER ) == 0, bit_band( t, TRAVERSES_GROUND ) == 0
		bAllowWater = !bDisAllowWater
	else bDoCheck = nil end
	local flStepHeightNeg
	if bAllowWater then flStepHeightNeg = veh:BoundingRadius() end
	local IsAreaTraversable = loco.IsAreaTraversable
	return Path, Path:Compute( self, vGoal, function( area, from, ladder, elevator, length )
		if !IsValid( fromArea ) then return 0 end
		if !IsAreaTraversable( loco, area ) then return -1 end
		local bUnderwater
		if bDoCheck then
			bUnderwater = area:IsUnderwater()
			if bUnderwater then if bDisAllowWater then return -1 end
			elseif bDisAllowGround then return -1 end
		end
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
		if ( bDoCheck && bAllowWater && bUnderwater && from:IsUnderwater() || !bDoCheck ) && ( d > flStepHeight ||
		//Dont Jump Down into Water as It Usually Results in The Boat Getting Flipped Over
		bAllowWater && area:IsUnderwater() && d < flStepHeightNeg ) then return -1 end
		return cost
	end )
end

function ENT:ComputeFlankPath( Path, pEnemy ) return self:ComputePath( Path, pEnemy:GetPos() ) end
