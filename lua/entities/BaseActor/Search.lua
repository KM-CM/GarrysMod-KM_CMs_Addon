function ENT:SearchAreas()
	local vPos = self:GetPos()
	local area = navmesh.GetNearestNavArea( vPos )
	if !area then return {} end
	local tQueue, tVisited = { { area, 0 } }, {}
	local bCantClimb, flJumpHeight, flNegDeathDrop = !self.bCanClimb, self.loco:GetJumpHeight(), -self.loco:GetDeathDropHeight()
	local tAllies = self:GetAlliesByClass()
	local flOff = math.max( math.abs( self:OBBMaxs().x ), math.abs( self:OBBMins().x ) ) * 1.5
	local flOffDistSqr = flOff * 3
	flOffDistSqr = flOffDistSqr * flOffDistSqr
	local vOffStanding, vOffDucking = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && self.vHullDuckMaxs.z != self.vHullMaxs.z then vOffDucking = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	local bDisAllowWater = !self.bCanSwim
	return function()
		if !table.IsEmpty( tQueue ) then
			local area, dist = unpack( table.remove( tQueue ) )
			for _, t in ipairs( area:GetAdjacentAreaDistances() ) do
				local new = t.area
				local id = new:GetID()
				if tVisited[ id ] then continue end
				tVisited[ id ] = true
				if bDisAllowWater && area:IsUnderwater() then continue end
				local d = area:ComputeAdjacentConnectionHeightChange( new )
				if bCantClimb && d > flJumpHeight || d <= flNegDeathDrop then continue end
				table.insert( tQueue, { new, t.dist + dist } )
			end
			return area, dist
		end
	end
end

function ENT:SearchNodes( vPos, flSpacing )
	if !vPos then vPos = self:GetPos() end
	local area = navmesh.GetNearestNavArea( vPos )
	if !area then return {} end
	if !flSpacing then flSpacing = self:BoundingRadius() end
	local tQueue, tVisited = { { area, 0 } }, {}
	local bCantClimb, flJumpHeight, flNegDeathDrop = !self.bCanClimb, self.loco:GetJumpHeight(), -self.loco:GetDeathDropHeight()
	local tAllies = self:GetAlliesByClass()
	local flOff = math.max( math.abs( self:OBBMaxs().x ), math.abs( self:OBBMins().x ) ) * 1.5
	local flOffDistSqr = flOff * 3
	flOffDistSqr = flOffDistSqr * flOffDistSqr
	local vOffStanding, vOffDucking = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && self.vHullDuckMaxs.z != self.vHullMaxs.z then vOffDucking = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	local bDisAllowWater = !self.bCanSwim
	local z = self:OBBMaxs().z
	local s = z * .16
	z = Vector( 0, 0, z )
	s = Vector( 0, 0, s )
	local veh = self.GAME_pVehicle
	local tFilter = IsValid( veh ) && { self, veh } || self
	local t = {}
	return function()
		if t then
			local v = table.remove( t )
			if v then return v[ 1 ] else t = nil end
		end
		if !table.IsEmpty( tQueue ) then
			local area, dist = unpack( table.remove( tQueue ) )
			for _, t in ipairs( area:GetAdjacentAreaDistances() ) do
				local new = t.area
				local id = new:GetID()
				if tVisited[ id ] then continue end
				tVisited[ id ] = true
				if bDisAllowWater && area:IsUnderwater() then continue end
				local d = area:ComputeAdjacentConnectionHeightChange( new )
				if bCantClimb && d > flJumpHeight || d <= flNegDeathDrop then continue end
				table.insert( tQueue, { new, t.dist + dist } )
			end
			local v = area:GetCorner( 0 ) //NORTH_WEST
			local flCornerX, flCornerY = v.x, v.y
			local flSizeX, flSizeY = area:GetSizeX(), area:GetSizeY()
			t = {}
			for x = flCornerX, flCornerX + flSizeX, flSpacing do
				for y = flCornerY, flCornerY + flSizeY, flSpacing do
					local v = Vector( x, y )
					v.z = area:GetZ( v )
					if util.TraceLine( {
						start = v + s,
						endpos = v + z,
						mask = MASK_SOLID,
						filter = tFilter
					} ).Hit then continue end
					table.insert( t, { v, v:DistToSqr( vPos ) } )
				end
			end
			table.SortByMember( t, 2 )
			if t then return table.remove( t )[ 1 ] else return area:GetCenter() end
		end
	end
end
