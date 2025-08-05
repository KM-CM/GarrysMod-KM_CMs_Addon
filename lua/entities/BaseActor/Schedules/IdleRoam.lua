Actor_RegisterSchedule( "IdleRoam", function( self, sched )
	if !table.IsEmpty( self.tEnemies ) then return {} end
	if CurTime() > self.flWeaponReloadTime then
		local t = {}
		for wep in pairs( self.tWeapons ) do if wep:Clip1() < wep:GetMaxClip1() then table.insert( t, wep ) end end
		if !table.IsEmpty( t ) then
			self:SetActiveWeapon( table.Random( t ) )
			self:WeaponReload()
		end
	end
	if CurTime() > ( sched.flStandTime || 0 ) then
		if !sched.Path then sched.Path = Path "Follow" sched.Path:SetGoalTolerance( self.flPathTolerance ) end
		if !sched.vGoal then
			local area, vec = self:GetLastKnownArea() || navmesh.GetNearestNavArea( self:GetPos() )
			if !area then sched.flStandTime = CurTime() + math.Rand( 0, 4 ) return end
			local tQueue, tVisited, flDistSqr = { { area, 0 } }, {}, math.Rand( 0, 1024 )
			flDistSqr = flDistSqr * flDistSqr
			while !table.IsEmpty( tQueue ) do
				local area, dist = unpack( table.remove( tQueue ) )
				for _, t in ipairs( area:GetAdjacentAreaDistances() ) do
					local new = t.area
					if tVisited[ new:GetID() ] then continue end
					table.insert( tQueue, { new, dist + t.dist } )
					tVisited[ new:GetID() ] = true
				end
				table.SortByMember( tQueue, 2 )
				local v = area:GetRandomPoint()
				if v:DistToSqr( self:GetPos() ) >= flDistSqr then vec = v break end
			end
			if vec then sched.vGoal = vec else sched.flStandTime = CurTime() + math.Rand( 0, 4 ) return end
		end
		local goal = sched.Path:GetCurrentGoal()
		if goal then self.vDesAim = ( goal.pos - self:GetPos() ):GetNormalized() end
		self:ComputePath( sched.Path, sched.vGoal )
		self:MoveAlongPath( sched.Path, self.flWalkSpeed )
		if math.abs( sched.Path:GetCursorPosition() - sched.Path:GetLength() ) <= self.flPathTolerance then sched.flStandTime = CurTime() + math.Rand( 0, 4 ) end
	else self.vDesAim = nil sched.Path = nil sched.vGoal = nil end
end )
