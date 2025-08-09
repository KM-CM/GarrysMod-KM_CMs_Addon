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
	//local flDist = self:GetPos():Distance( enemy:GetPos() ) + self.flCoverMoveDistance * math_abs( math_min( 0, self.flCombatState, self.flCombatStateSmall ) )
	//local flDistSqr = flDist * flDist
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
	if table.IsEmpty( __COVER_TABLE_STATIC__ ) && table.IsEmpty( __COVER_TABLE_DYNAMIC__ ) then ErrorNoHaltWithStack "No Cover Nodes!" return {} end
	local tShootables = {}
	for enemy in pairs( tEnemies ) do
		if !IsValid( enemy ) || !HasRangeAttack( enemy ) then continue end
		for _, vec in ipairs( self:CalcEnemyShootPositions( enemy ) ) do
			table.insert( tShootables, { vec, enemy } )
		end
	end
	local vToEnemy = ( enemy:GetPos() - self:GetPos() ):GetNormalized()
	//local flGiveUpDist = flDist * 4
	local pBestCover, vBestCover, bBestCoverDuck
	while !table.IsEmpty( tQueue ) do
		local area, dist = unpack( table.remove( tQueue ) )
		//if dist > flGiveUpDist then return pBestCover, vBestCover, bBestCoverDuck end //Give Up
		for _, t in ipairs( area:GetAdjacentAreaDistances() ) do
			local new = t.area
			local id = new:GetID()
			if tVisited[ id ] then continue end
			tVisited[ id ] = true
			if ( area:GetClosestPointOnArea( self:GetPos() ) - self:GetPos() ):GetNormalized():Dot( vToEnemy ) > 0 then continue end
			local d = area:ComputeAdjacentConnectionHeightChange( new )
			if bCantClimb && d > flJumpHeight || d <= flNegDeathDrop then continue end
			table.insert( tQueue, { new, t.dist + dist } )
		end
		table.SortByMember( tQueue, 2 )
		local tCovers = {}
		local id = area:GetID()
		local t = __COVER_TABLE_STATIC__[ id ]
		if t then
			for Cover in pairs( t ) do
				table.insert( tCovers, { Cover, Cover.m_Vector:DistToSqr( self:GetPos() ) } )
			end
		end
		local t = __COVER_TABLE_DYNAMIC__[ id ]
		if t then
			for Cover in pairs( t ) do
				table.insert( tCovers, { Cover, Cover.m_Vector:DistToSqr( self:GetPos() ) } )
			end
		end
		table.SortByMember( tCovers, 2, true )
		local bFound
		for _, d in ipairs( tCovers ) do
			local Cover = d[ 1 ]
			local vec = Cover.m_Vector + Cover.m_vForward * flOff
			if ( vec - self:GetPos() ):GetNormalized():Dot( vToEnemy ) > 0 then continue end
			local b
			if tAllies then
				for ally in pairs( tAllies ) do
					if self == ally then continue end
					if ally.pActualCover == Cover then b = true break end
				end
			end
			if b then continue end
			b = true
			local vStand, vDuck, bDuck = vec + vOffStanding
			if vOffDucking then vDuck = vec + vOffDucking end
			for ent in pairs( tEnemies ) do
				if !IsValid( ent ) then continue end
				if vDuck then
					local v = ent:GetPos() + ent:OBBCenter()
					v.z = vStand.z
					if util.TraceLine( {
						start = vDuck,
						endpos = v,
						mask = MASK_SHOT_HULL,
						filter = { self, ent }
					} ).HitPos:DistToSqr( vec ) <= flOffDistSqr then
						b = nil
						break
					end
				else
					local v = ent:GetPos() + ent:OBBCenter()
					v.z = vStand.z
					if util.TraceLine( {
						start = vStand,
						endpos = v,
						mask = MASK_SHOT_HULL,
						filter = { self, ent }
					} ).HitPos:DistToSqr( vec ) <= flOffDistSqr then
						b = nil
						break
					end
				end
			end
			if b then continue end
			if util.TraceHull( {
				start = vec,
				endpos = vec,
				mins = self:OBBMins(),
				maxs = self:OBBMaxs(),
				filter = self
			} ).Hit then continue end
			for _, d in pairs( tShootables ) do
				local vec, ent = unpack( d )
				if vDuck then
					if !util.TraceLine( {
						start = vec,
						endpos = vDuck,
						mask = MASK_SHOT_HULL,
						filter = { self, ent }
					} ).Hit then b = true break end
					if !util.TraceLine( {
						start = vec,
						endpos = vStand,
						mask = MASK_SHOT_HULL,
						filter = { self, ent }
					} ).Hit then bDuck = true end
				else
					if !util.TraceLine( {
						start = vec,
						endpos = vStand,
						mask = MASK_SHOT_HULL,
						filter = { self, ent }
					} ).Hit then b = true break end
				end
			end
			if b then continue end
			pBestCover, vBestCover, bBestCoverDuck = Cover, vec, bDuck
			if vec:DistToSqr( enemy:GetPos() ) > flDistSqr then
				return Cover, vec, bDuck
			end
		end
	end
end
