ENT.flPathTolerance = 64
ENT.flPathGoalTolerance = 16

local CEntity = FindMetaTable( "Entity" )
local CEntity_GetTable = CEntity.GetTable

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

// How Far Do We have to Move Along The Path to be Able to Suppress Anyone? Can Return `nil`
// TODO: Return The Nearest Ally That can Suppress The Enemy if He is Farther Along The Path Than The Suppression Vector Along It

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
			if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return I end
			local tr = util.TraceLine {
				start = vec + vDuck,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return I end
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
			if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return I end
			local tr = util.TraceLine {
				start = vec + vDuck,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return I end
		end
	end
end
function ENT:FindPathBattleLineNoAlliesToVector( Path, vShoot, flTolerance )
	flTolerance = flTolerance || 256
	local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	local flSuppressionTraceFraction = self.flSuppressionTraceFraction
	for I = 0, Path:GetLength(), flTolerance do
		local vec = Path:GetPositionOnPath( I )
		local tr = util.TraceLine {
			start = vec + vStand,
			endpos = vShoot,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		}
		if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return I end
		local tr = util.TraceLine {
			start = vec + vDuck,
			endpos = vShoot,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		}
		if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return I end
	end
end
function ENT:FindPathStackUpLine( Path, tEnemies, flTolerance )
	flTolerance = flTolerance || 256
	local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	local flStackUpTraceFraction = self.flStackUpTraceFraction
	local flSuppressionTraceFraction = self.flSuppressionTraceFraction
	local N
	for I = 0, Path:GetLength(), flTolerance do
		if N then
			local vec = Path:GetPositionOnPath( I )
			for enemy in pairs( tEnemies ) do
				if !IsValid( enemy ) then continue end
				local vShoot = enemy:GetPos() + enemy:OBBCenter()
				local b
				local tr = util.TraceLine {
					start = vec + vStand,
					endpos = vShoot,
					mask = MASK_SHOT_HULL,
					filter = { self, enemy, trueenemy }
				}
				if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return N end
				local tr = util.TraceLine {
					start = vec + vDuck,
					endpos = vShoot,
					mask = MASK_SHOT_HULL,
					filter = { self, enemy, trueenemy }
				}
				if tr.Fraction > flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then return N end
			end
		end
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
			if tr.Fraction > flSuppressionTraceFraction then return end
			if tr.Fraction > flStackUpTraceFraction then N = I continue end
			local tr = util.TraceLine {
				start = vec + vDuck,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			if tr.Fraction > flSuppressionTraceFraction then return end
			if tr.Fraction > flStackUpTraceFraction then N = I continue end
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
		// Dont Jump Down into Water as It Usually Results in The Boat Getting Flipped Over
		bAllowWater && area:IsUnderwater() && d < flStepHeightNeg ) then return -1 end
		return cost
	end )
end

// Really Roughly Done and Needs to be Improved... But Whatever
local ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE = 256

__ACTOR_FLANK_PATHS__ = __ACTOR_FLANK_PATHS__ || {}
local __ACTOR_FLANK_PATHS_LOCAL__ = __ACTOR_FLANK_PATHS__

hook.Add( "Think", "ActorFlankPath", function()
	local tNew = {}
	for iClass, tPartition in pairs( __ACTOR_FLANK_PATHS_LOCAL__ ) do
		for sPartition, tActorToTable in pairs( tPartition ) do
			for pActor, tData in pairs( tActorToTable ) do
				if !IsValid( pActor ) then continue end
				local v = tNew[ iClass ]
				if v then
					local n = v[ sPartition ]
					if n then
						n[ pActor ] = tData
					else
						v[ sPartition ] = { [ pActor ] = tData }
					end
				else tNew[ iClass ] = { [ sPartition ] = { [ pActor ] = tData } } end
			end
		end
	end
	__ACTOR_FLANK_PATHS__, __ACTOR_FLANK_PATHS_LOCAL__ = tNew, tNew
end )

local CEntity_GetPos = CEntity.GetPos

local math_Round = math.Round

local Format = Format

local IsValid = IsValid

function ENT:ComputeFlankPath( Path, pEnemy )
	local MyTable = CEntity_GetTable( self )
	local f = MyTable.flPathTolerance
	f = f * f
	local vPos = CEntity_GetPos( self )
	local vGoal = CEntity_GetPos( pEnemy )
	Path:MoveCursorToClosestPosition( vPos )
	if Path:GetPositionOnPath( Path:GetCursorPosition() ):DistToSqr( vPos ) <= f && Path:GetEnd():DistToSqr( vGoal ) <= f then return true end
	local tPath, tAlready = {}, {}
	local iClass = self:Classify()
	local iX = math_Round( vGoal[ 1 ] / ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE ) * ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE
	local iY = math_Round( vGoal[ 2 ] / ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE ) * ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE
	local iZ = math_Round( vGoal[ 3 ] / ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE ) * ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE
	local sPartition = tostring( iX ):gsub( "(%d)0+$", "%1" ):gsub( "%.$", "" ) .. "," .. tostring( iY ):gsub( "(%d)0+$", "%1" ):gsub( "%.$", "" ) .. "," .. tostring( iZ ):gsub( "(%d)0+$", "%1" ):gsub( "%.$", "" )
	local iAlliesPathingTotal = 0
	local v = __ACTOR_FLANK_PATHS_LOCAL__[ iClass ]
	if v then
		local n = v[ sPartition ]
		if n then
			for ent, t in pairs( n ) do
				if !IsValid( ent ) || ent == self then continue end
				iAlliesPathingTotal = iAlliesPathingTotal + 1
				for area in pairs( t ) do
					local v = area:GetID()
					local i = tAlready[ v ]
					tAlready[ v ] = i && ( i + 1 ) || 2
				end
			end
			n[ self ] = tPath
		else v[ sPartition ] = { [ self ] = tPath } end
	else __ACTOR_FLANK_PATHS_LOCAL__[ iClass ] = { [ sPartition ] = { [ self ] = tPath } } end
	local loco = MyTable.loco
	local bCantClimb = !( MyTable.bCanClimb || MyTable.bCanFly )
	local bDisAllowWater = !MyTable.bCanSwim
	local flDeathDropNeg = -loco:GetDeathDropHeight()
	local flStepHeight = loco:GetStepHeight()
	local flJumpHeight
	if bCantClimb then flJumpHeight = loco:GetMaxJumpHeight() end
	local IsAreaTraversable = loco.IsAreaTraversable
	local bStatus = Path:Compute( self, vGoal, function( area, from, ladder, elevator, length )
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
		return cost * ( ( tAlready[ area:GetID() ] || 1 ) / iAlliesPathingTotal )
	end )
	for _, seg in ipairs( Path:GetAllSegments() ) do tPath[ seg.area ] = true end
	return Path, bStatus
end
