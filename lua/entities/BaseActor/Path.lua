ENT.flPathTolerance = 32

local CEntity = FindMetaTable( "Entity" )
local CEntity_GetTable = CEntity.GetTable

function ENT:ComputePath( Path, vGoal, Weighter )
	local MyTable = CEntity_GetTable( self )
	local f = MyTable.flPathTolerance
	Path:SetGoalTolerance( f )
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
	local flSuppressionTraceFraction = self.flSuppressionTraceFraction
	local iBattleLine = self:FindPathBattleLine( Path, tEnemies, flTolerance )
	if !iBattleLine then return end
	local vBattleLine = Path:GetPositionOnPath( iBattleLine ) + Vector( 0, 0, self.vHullMaxs.z * .5 )
	local N
	for I = 0, Path:GetLength(), flTolerance do
		local vec = Path:GetPositionOnPath( I )
		local tr = util.TraceLine {
			start = vec + vStand,
			endpos = vBattleLine,
			mask = MASK_SHOT_HULL,
			filter = self
		}
		if tr.Fraction > flSuppressionTraceFraction then return N else N = I end
		if !vDuck then continue end
		local tr = util.TraceLine {
			start = vec + vDuck,
			endpos = vBattleLine,
			mask = MASK_SHOT_HULL,
			filter = self
		}
		if tr.Fraction > flSuppressionTraceFraction then return N else N = I end
	end
	return N
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

// I give up on implementing this, the lower one isn't that good anyway
function ENT:ComputeFlankPath( Path, pEnemy ) return self:ComputePath( Path, pEnemy:GetPos() ) end

//	// Really Roughly Done and Needs to be Improved... But Whatever
//	local ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE = 256
//	
//	__ACTOR_FLANK_PATHS__ = __ACTOR_FLANK_PATHS__ || {}
//	local __ACTOR_FLANK_PATHS_LOCAL__ = __ACTOR_FLANK_PATHS__
//	
//	hook.Add( "Think", "ActorFlankPath", function()
//		local tNew = {}
//		for iClass, tPartition in pairs( __ACTOR_FLANK_PATHS_LOCAL__ ) do
//			for sPartition, tActorToTable in pairs( tPartition ) do
//				for pActor, tData in pairs( tActorToTable ) do
//					if !IsValid( pActor ) then continue end
//					local v = tNew[ iClass ]
//					if v then
//						local n = v[ sPartition ]
//						if n then
//							n[ pActor ] = tData
//						else
//							v[ sPartition ] = { [ pActor ] = tData }
//						end
//					else tNew[ iClass ] = { [ sPartition ] = { [ pActor ] = tData } } end
//				end
//			end
//		end
//		__ACTOR_FLANK_PATHS__, __ACTOR_FLANK_PATHS_LOCAL__ = tNew, tNew
//	end )
//	
//	local CEntity_GetPos = CEntity.GetPos
//	
//	local math_Round = math.Round
//	
//	local Format = Format
//	
//	local IsValid = IsValid
//	
//	function ENT:ComputeFlankPath( Path, pEnemy )
//		local MyTable = CEntity_GetTable( self )
//		local f = MyTable.flPathTolerance
//		f = f * f
//		local vPos = CEntity_GetPos( self )
//		local vGoal = CEntity_GetPos( pEnemy )
//		Path:MoveCursorToClosestPosition( vPos )
//		if Path:GetPositionOnPath( Path:GetCursorPosition() ):DistToSqr( vPos ) <= f && Path:GetEnd():DistToSqr( vGoal ) <= f then return true end
//		local tPath, tAlready = {}, {}
//		local iClass = self:Classify()
//		local iX = math_Round( vGoal[ 1 ] / ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE ) * ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE
//		local iY = math_Round( vGoal[ 2 ] / ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE ) * ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE
//		local iZ = math_Round( vGoal[ 3 ] / ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE ) * ACTOR_FLANK_PATHS_SPATIAL_PARTITION_CELL_SIZE
//		local sPartition = tostring( iX ):gsub( "(%d)0+$", "%1" ):gsub( "%.$", "" ) .. "," .. tostring( iY ):gsub( "(%d)0+$", "%1" ):gsub( "%.$", "" ) .. "," .. tostring( iZ ):gsub( "(%d)0+$", "%1" ):gsub( "%.$", "" )
//		local iAlliesPathingTotal = 0
//		local v = __ACTOR_FLANK_PATHS_LOCAL__[ iClass ]
//		if v then
//			local n = v[ sPartition ]
//			if n then
//				for ent, t in pairs( n ) do
//					if !IsValid( ent ) || ent == self then continue end
//					iAlliesPathingTotal = iAlliesPathingTotal + 1
//					for area in pairs( t ) do
//						local v = area:GetID()
//						local i = tAlready[ v ]
//						tAlready[ v ] = i && ( i + 1 ) || 2
//					end
//				end
//				n[ self ] = tPath
//			else v[ sPartition ] = { [ self ] = tPath } end
//		else __ACTOR_FLANK_PATHS_LOCAL__[ iClass ] = { [ sPartition ] = { [ self ] = tPath } } end
//		local loco = MyTable.loco
//		local bCantClimb = !( MyTable.bCanClimb || MyTable.bCanFly )
//		local bDisAllowWater = !MyTable.bCanSwim
//		local flDeathDropNeg = -loco:GetDeathDropHeight()
//		local flStepHeight = loco:GetStepHeight()
//		local flJumpHeight
//		if bCantClimb then flJumpHeight = loco:GetMaxJumpHeight() end
//		local IsAreaTraversable = loco.IsAreaTraversable
//		local bStatus = Path:Compute( self, vGoal, function( area, from, ladder, elevator, length )
//			if !IsValid( from ) then return 0 end
//			if !IsAreaTraversable( loco, area ) || bDisAllowWater && area:IsUnderwater() then return -1 end
//			local dist = 0
//			if IsValid( ladder ) then
//				dist = ladder:GetLength()
//			elseif length > 0 then
//				dist = length
//			else
//				dist = ( area:GetCenter() - from:GetCenter() ):GetLength()
//			end
//			local cost = dist + from:GetCostSoFar()
//			local d = from:ComputeAdjacentConnectionHeightChange( area )
//			if d >= flStepHeight then
//				if bCantClimb && d >= flJumpHeight then return -1 end
//				cost = cost + 1.5 * dist
//			elseif d < flDeathDropNeg then return -1 end
//			return cost * ( ( tAlready[ area:GetID() ] || 1 ) / iAlliesPathingTotal )
//		end )
//		for _, seg in ipairs( Path:GetAllSegments() ) do tPath[ seg.area ] = true end
//		return Path, bStatus
//	end

local sv_gravity = GetConVar "sv_gravity"

// Tries to jump to vTarget
function ENT:Jump( vTarget )
	local flGravity = sv_gravity:GetFloat()
	local vVelocity = self.loco:GetVelocity()
	if vVelocity == vector_origin then vVelocity = ( vTarget - self:GetPos() ):GetNormalized() end
	local dVelocityFlat = Vector( vVelocity )
	dVelocityFlat.z = 0
	dVelocityFlat:Normalize()
	local dTargetFlat = vTarget - self:GetPos()
	dTargetFlat.z = 0
	dTargetFlat:Normalize()
	local flFlatDistance = self:GetPos():Distance2D( vTarget )
	local flDifference = ( 1 - math.max( 0, dVelocityFlat:Dot( dTargetFlat ) ) ) * flFlatDistance
	if flDifference > ( self.flPathTolerance * .5 ) then return end
	local flOriginal = self.loco:GetJumpHeight() // NOT flJumpHeight!!!
	local vStart = self:GetPos()
	local vMiddle = LerpVector( .5, vStart, vTarget )
	local flZ = vStart.z
	local flJumpHeight = flOriginal * math.min( util.TraceLine( {
		start = vStart,
		endpos = vStart + Vector( 0, 0, flOriginal ),
		mask = MASK_SOLID,
		filter = self
	} ).HitPos.z - flZ, util.TraceLine( {
		start = vMiddle,
		endpos = vMiddle + Vector( 0, 0, flOriginal ),
		mask = MASK_SOLID,
		filter = self
	} ).HitPos.z - flZ, util.TraceLine( {
		start = vTarget,
		endpos = vTarget + Vector( 0, 0, flOriginal ),
		mask = MASK_SOLID,
		filter = self
	} ).HitPos.z - flZ )
	local flJumpLength = vVelocity:Length() * 2 * ( 2 * flGravity * flJumpHeight ) ^ .5 / flGravity
	if self:GetPos():DistToSqr( vTarget ) > ( flJumpLength * flJumpLength ) then return end
	self.loco:SetJumpHeight( vTarget.z - vStart.z + ( flFlatDistance <= ( self.flPathTolerance * 8 ) && 0 || ( ( ( flFlatDistance * .5 + self:OBBMaxs().x ) / vVelocity:Length() ) * flGravity ) ^ 2 / ( 2 * flGravity ) ) )
	self.loco:Jump()
	self.loco:SetJumpHeight( flOriginal )
	self.m_flJumpStartTime = CurTime()
	self.m_bJumping = true
end

ENT.vLastAcceleration = Vector()
function ENT:HandleJumpingAlongPath( Path, tFilter )
	Path:Update( self )
	local goal, tNextGoal = Path:GetCurrentGoal(), Path:NextSegment()
	if goal && tNextGoal then
		if self:IsOnGround() then
			self.vLastAcceleration = Vector()
			self.loco:Approach( goal.pos, 1 )
			if goal.type == 2 || goal.type == 3 then
				self:Jump( tNextGoal.pos )
			end
		//	else
		//		// Air acceleration, maybe? I'm too lazy to find out how sv_airaccelerate works
		end
	end
end

function ENT:HandleStuck() self.loco:ClearStuck() end
