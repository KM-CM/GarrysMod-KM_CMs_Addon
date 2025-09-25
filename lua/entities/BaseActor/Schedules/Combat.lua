//TODO: Break Down The File into Files with The Name of The Schedule Like TakeCoverAdvance.lua

ENT.tPreScheduleResetVariables.bSuppressing = false

function ENT:RangeAttack()
	if self.bHoldFire then return end //No, This is Not Included by Default...
	self:WeaponPrimaryVolley()
	return true
end

//Small Suppressed, Does NOT want Someone Else to Help Yet
function ENT:DLG_Suppressed() end

//See The Code, I have No Easy Way of Explaining This One
ENT.flSuppressionTraceFraction = .8
//Basically The Same But Used for Stack Ups
ENT.flStackUpTraceFraction = .33

//Try to Guess from Where This Enemy Might Shoot Us from
function ENT:CalcEnemyShootPositions( enemy )
	local vPos = enemy:GetPos()
	local dir = ( self:GetPos() - vPos ):GetNormalized()
	local dright = dir:Angle():Right()
	if enemy.GetHull && enemy.GetHullDuck then
		local vMins, vMaxs = enemy:GetHull()
		local vDuckMins, vDuckMaxs = enemy:GetHullDuck()
		local vOffStanding, vOffDucking = Vector( 0, 0, vMaxs.z ), Vector( 0, 0, vDuckMaxs.z )
		local flOff = math.max( math.abs( enemy:OBBMaxs().x ), math.abs( enemy:OBBMins().x ) ) * 4
		local vLeft = vPos + dright * flOff
		local vRight = vPos - dright * flOff
		if util.TraceHull( {
			start = vLeft,
			endpos = vLeft,
			mins = enemy:OBBMins(),
			maxs = enemy:OBBMaxs(),
			filter = enemy
		} ).Hit then vLeft = nil end
		if util.TraceHull( {
			start = vRight,
			endpos = vRight,
			mins = enemy:OBBMins(),
			maxs = enemy:OBBMaxs(),
			filter = enemy
		} ).Hit then vRight = nil end
		if vLeft && vRight then return { vPos + enemy:OBBCenter(), vLeft + vOffStanding, vLeft + vOffDucking, vRight + vOffStanding, vRight + vOffDucking }
		elseif vLeft then return { vPos + vOffStanding, vPos + vOffDucking, vLeft + vOffStanding, vLeft + vOffDucking }
		elseif vRight then return { vPos + vOffStanding, vPos + vOffDucking, vRight + vOffStanding, vRight + vOffDucking }
		else return { vPos + vOffStanding, vPos + vOffDucking } end
		return
	end
	local flOff = math.max( math.abs( enemy:OBBMaxs().x ), math.abs( enemy:OBBMins().x ) ) * 4
	local vLeft = vPos + dright * flOff
	local vRight = vPos - dright * flOff
	if util.TraceHull( {
		start = vLeft,
		endpos = vLeft,
		mins = enemy:OBBMins(),
		maxs = enemy:OBBMaxs(),
		filter = enemy
	} ).Hit then vLeft = nil end
	if util.TraceHull( {
		start = vRight,
		endpos = vRight,
		mins = enemy:OBBMins(),
		maxs = enemy:OBBMaxs(),
		filter = enemy
	} ).Hit then vRight = nil end
	if vLeft && vRight then return { vPos + enemy:OBBCenter(), vLeft, vRight }
	elseif vLeft then return { vPos + enemy:OBBCenter(), vLeft }
	elseif vRight then return { vPos + enemy:OBBCenter(), vRight }
	else return { vPos + enemy:OBBCenter() } end
end

ENT.flCoverMoveStart = 1
ENT.flCoverMoveStartSuppressed = 0
ENT.flCoverMoveStep = 1
ENT.flCoverMoveShort = 4
ENT.flCoverMoveNotShort = 8

function ENT:CalcMyExposedShootPositions( enemy, vPos, bDuck, vStand, vDuck )
	local enemy, trueenemy = self:SetupEnemy( enemy )
	local t, bHasShort = {}
	local vShoot = enemy:GetPos() + enemy:OBBCenter()
	if vDuck && !util.TraceLine( {
		start = vPos + vDuck,
		endpos = vShoot,
		mask = MASK_SHOT_HULL,
		filter = { self, enemy, trueenemy }
	} ).Hit || !util.TraceLine( {
		start = vPos + vStand,
		endpos = vShoot,
		mask = MASK_SHOT_HULL,
		filter = { self, enemy, trueenemy }
	} ).Hit then table.insert( t, self:GetPos() ) bHasShort = true end
	local flBase = math.abs( self:OBBMaxs().x ) + math.abs( self:OBBMins().x )
	local flStart = CurTime() <= self.flSuppressedTime && self.flCoverMoveStart || self.flCoverMoveStartSuppressed
	local flShort = flBase * ( flStart + self.flCoverMoveShort )
	local flNotShort = flBase * ( flStart + self.flCoverMoveNotShort )
	local dir = ( vShoot - vPos ):Angle():Right()
	dir[ 1 ] = 0
	local vMins, vMaxs = self:OBBMins(), self:OBBMaxs()
	vMins.z = vMins.z + 12
	vMaxs.z = vMaxs.z + 12
	local vLeft, vRight, bLeftShort, bRightShort
	local ndir = -dir
	for flDist = flBase * flStart, flNotShort, flBase * self.flCoverMoveStep do
		local vec = vPos + ndir * flDist
		if util.TraceHull( {
			start = vPos,
			endpos = vec,
			mins = vMins,
			maxs = vMaxs,
			filter = self
		} ).Hit then break end
		if vDuck && !util.TraceLine( {
			start = vec + vDuck,
			endpos = vShoot,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		} ).Hit || !util.TraceLine( {
			start = vec + vStand,
			endpos = vShoot,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		} ).Hit then vLeft = vec if flDist < flShort then bLeftShort = true end break end
	end
	for flDist = flBase * flStart, flNotShort, flBase * self.flCoverMoveStep do
		local vec = vPos + dir * flDist
		if util.TraceHull( {
			start = vPos,
			endpos = vec,
			mins = vMins,
			maxs = vMaxs,
			filter = self
		} ).Hit then break end
		if vDuck && !util.TraceLine( {
			start = vec + vDuck,
			endpos = vShoot,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		} ).Hit || !util.TraceLine( {
			start = vec + vStand,
			endpos = vShoot,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		} ).Hit then vRight = vec if flDist < flShort then bRightShort = true end break end
	end
	if bLeftShort && bRightShort then
		table.insert( t, vLeft )
		table.insert( t, vRight )
	elseif bLeftShort then
		table.insert( t, vLeft )
	elseif bRightShort then
		table.insert( t, vRight )
	else
		if !bHasShort then
			table.insert( t, vLeft )
			table.insert( t, vRight )
		end
	end
	return t
end

function ENT:FindExposedEnemy( vShoot, tEnemies, bDuck )
	local tEnemiesDist = {}
	for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tEnemiesDist, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
	table.SortByMember( tEnemiesDist, 2, true )
	if table.IsEmpty( tEnemiesDist ) then return end
	local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	for _, d in pairs( tEnemiesDist ) do
		local enemy = d[ 1 ]
		local t = self:CalcMyExposedShootPositions( enemy, vShoot, bDuck, vStand, vDuck )
		if table.IsEmpty( t ) then continue end
		return table.Random( t ), enemy
	end
end

function ENT:CalcMySuppressionShootPositions( enemy, vPos, bDuck, vStand, vDuck )
	local enemy, trueenemy = self:SetupEnemy( enemy )
	local t, bHasShort = {}
	if bDuck then
		local tr = util.TraceLine {
			start = vPos + vStand,
			endpos = vShoot,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		}
		if tr.Fraction > self.flSuppressionTraceFraction && tr.HitPos:Distance( vPos ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
			bHasShort = true
			table.insert( t, { vPos, tr.HitPos } )
		end
	end
	local vShoot = enemy:GetPos() + enemy:OBBCenter()
	local flBase = math.abs( self:OBBMaxs().x ) + math.abs( self:OBBMins().x )
	local flStart = CurTime() <= self.flSuppressedTime && self.flCoverMoveStart || self.flCoverMoveStartSuppressed
	local flShort = flBase * ( flStart + self.flCoverMoveShort )
	local flNotShort = flBase * ( flStart + self.flCoverMoveNotShort )
	local dir = ( vShoot - vPos ):Angle():Right()
	dir[ 1 ] = 0
	local vMins, vMaxs = self:OBBMins(), self:OBBMaxs()
	vMins.z = vMins.z + 12
	vMaxs.z = vMaxs.z + 12
	local vLeft, vRight, vLeftTarget, vRightTarget, bLeftShort, bRightShort
	local ndir = -dir
	for flDist = flBase * flStart, flNotShort, flBase * self.flCoverMoveStep do
		local vec = vPos + ndir * flDist
		if util.TraceHull( {
			start = vPos,
			endpos = vec,
			mins = vMins,
			maxs = vMaxs,
			filter = self
		} ).Hit then break end
		if vDuck then
			local trStand = util.TraceLine {
				start = vec + vStand,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			local trDuck = util.TraceLine {
				start = vec + vDuck,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			local bStand = trStand.Fraction > self.flSuppressionTraceFraction && trStand.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
			local bDuck = trDuck.Fraction > self.flSuppressionTraceFraction && trDuck.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
			if bStand && bDuck then
				vLeft = vec
				vLeftTarget = math.random( 2 ) == 1 && trStand.HitPos || trDuck.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			elseif bStand then
				vLeft = vec
				vLeftTarget = trStand.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			elseif bDuck then
				vLeft = vec
				vLeftTarget = trDuck.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			end
		else
			local tr = util.TraceLine {
				start = vec + vStand,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			if tr.Fraction > self.flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
				vLeft = vec
				vLeftTarget = tr.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			end
		end
	end
	for flDist = flBase * flStart, flNotShort, flBase * self.flCoverMoveStep do
		local vec = vPos + dir * flDist
		if util.TraceHull( {
			start = vPos,
			endpos = vec,
			mins = vMins,
			maxs = vMaxs,
			filter = self
		} ).Hit then break end
		if vDuck then
			local trStand = util.TraceLine {
				start = vec + vStand,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			local trDuck = util.TraceLine {
				start = vec + vDuck,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			local bStand = trStand.Fraction > self.flSuppressionTraceFraction && trStand.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
			local bDuck = trDuck.Fraction > self.flSuppressionTraceFraction && trDuck.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
			if bStand && bDuck then
				vLeft = vec
				vLeftTarget = math.random( 2 ) == 1 && trStand.HitPos || trDuck.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			elseif bStand then
				vLeft = vec
				vLeftTarget = trStand.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			elseif bDuck then
				vLeft = vec
				vLeftTarget = trDuck.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			end
		else
			local tr = util.TraceLine {
				start = vec + vStand,
				endpos = vShoot,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
			if tr.Fraction > self.flSuppressionTraceFraction && tr.HitPos:Distance( vShoot ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
				vLeft = vec
				vLeftTarget = tr.HitPos
				if flDist < flShort then bLeftShort = true end
				break
			end
		end
	end
	if bLeftShort && bRightShort then
		table.insert( t, { vLeft, vLeftTarget } )
		table.insert( t, { vRight, vRightTarget } )
	elseif bLeftShort then
		table.insert( t, { vLeft, vLeftTarget } )
	elseif bRightShort then
		table.insert( t, { vRight, vRightTarget } )
	else
		if !bHasShort then
			table.insert( t, { vLeft, vLeftTarget } )
			table.insert( t, { vRight, vRightTarget } )
		end
	end
	return t
end

function ENT:FindSuppressEnemy( vShoot, tEnemies, bDuck )
	local tEnemiesDist = {}
	for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tEnemiesDist, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
	table.SortByMember( tEnemiesDist, 2, true )
	if table.IsEmpty( tEnemiesDist ) then return end
	local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
	if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
	for _, d in pairs( tEnemiesDist ) do
		local enemy = d[ 1 ]
		local t = self:CalcMySuppressionShootPositions( enemy, vShoot, bDuck, vStand, vDuck )
		if table.IsEmpty( t ) then continue end
		t = table.Random( t )
		if t[ 1 ] && t[ 2 ] then return t[ 1 ], t[ 2 ], enemy end
	end
end

Actor_RegisterSchedule( "CombatSoldier", function( self, sched )
	local tEnemies = sched.tEnemies || self.tEnemies
	if table.IsEmpty( tEnemies ) then return {} end
	local enemy = sched.Enemy
	if IsValid( enemy ) then enemy = self:SetupEnemy( enemy )
	else enemy = self.Enemy if !IsValid( enemy ) then return {} end end
	if self.vCover then
		local vec = self.vCover
		self.vActualCover = vec
		if !sched.Path then sched.Path = Path "Follow" end
		self:ComputePath( sched.Path, self.vCover )
		if math.abs( sched.Path:GetLength() - sched.Path:GetCursorPosition() ) > self.flPathGoalTolerance then self.vCover = nil self:SetSchedule "TakeCover" return end
		local tAllies = self:GetAlliesByClass()
		if tAllies then
			local pCover = self.pCover
			for ally in pairs( tAllies ) do
				if self == ally then continue end
				if ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= self:BoundingRadius() ^ 2 then self.vCover = nil self:SetSchedule "TakeCover" return end
			end
		end
		local o = vec + Vector( 0, 0, self.vHullMaxs.z )
		local v = o
		if self.vHullDuckMaxs && self.vHullDuckMaxs.z != self.vHullMaxs.z then v = vec + Vector( 0, 0, self.vHullDuckMaxs.z ) end
		local dir = enemy:GetPos() - vec
		dir.z = 0
		dir:Normalize()
		if !util.TraceLine( {
			start = v,
			endpos = v + dir * self.vHullMaxs.x * 4,
			mask = MASK_SHOT_HULL,
			filter = function( ent ) return !( ent:IsPlayer() || ent:IsNPC() || ent:IsNextBot() ) end
		} ).Hit then self.vCover = nil return end
		if !util.TraceLine( {
			start = o,
			endpos = o + dir * self.vHullMaxs.x * 4,
			mask = MASK_SHOT_HULL,
			filter = function( ent ) return !( ent:IsPlayer() || ent:IsNPC() || ent:IsNextBot() ) end
		} ).Hit then sched.bDuck = nil
		elseif sched.bDuck == nil then sched.bDuck = math.random( 3 ) == 1 end
		self:Stand( ( sched.bDuck == nil || sched.bDuck ) && 0 || 1 )
		self.vDesAim = dir
		if self:CanExpose() then
			if CurTime() > ( sched.flSuppressed || 0 ) then
				if self:MaybeCoverMove( tEnemies ) then return end
				local v, enemy = self:FindExposedEnemy( vec, tEnemies, sched.bDuck )
				if IsValid( enemy ) then
					local sched = self:SetSchedule "RangeAttack"
					sched.vFrom = v
					sched.Enemy = enemy
				else
					local vFrom, vTo, enemy = self:FindSuppressEnemy( vec, tEnemies, sched.bDuck )
					if IsValid( enemy ) then
						local sched = self:SetSchedule "RangeAttack"
						sched.vFrom = vFrom
						sched.vTo = vTo
						sched.Enemy = enemy
						sched.bSuppressing = true
					else sched.flSuppressed = CurTime() + math.Rand( 0, 4 ) end
				end
			end
		else sched.flSuppressed = CurTime() + math.Clamp( math.min( 0, ( self:GetExposedWeight() / self:Health() ) * .5 ), 0, 4 ) end
	else
		local vec = self:GetPos()
		local v, enemy = self:FindExposedEnemy( vec, tEnemies, sched.bDuck )
		if IsValid( enemy ) then
			local sched = self:SetSchedule "RangeAttack"
			sched.vFrom = v
			sched.Enemy = enemy
		else
			local vFrom, vTo, enemy = self:FindSuppressEnemy( vec, tEnemies, sched.bDuck )
			if IsValid( enemy ) then
				local sched = self:SetSchedule "RangeAttack"
				sched.vFrom = vFrom
				sched.vTo = vTo
				sched.Enemy = enemy
				sched.bSuppressing = true
			else self:SetSchedule "TakeCover" end
		end
		return
	end
end )

function ENT:DLG_FiringAtAnExposedTarget( enemy ) end
function ENT:DLG_Suppressing( enemy ) end

Actor_RegisterSchedule( "RangeAttack", function( self, sched )
	self.vActualCover = self.vCover
	self.bSuppressing = true
	local enemy, trueenemy = self:SetupEnemy( sched.Enemy )
	if !IsValid( enemy ) || !sched.vFrom then return {} end
	if !self:CanExpose() then self:SetSchedule "TakeCover" self:DLG_Suppressed() return end
	local tEnemies = sched.tEnemies || self.tEnemies
	if table.IsEmpty( tEnemies ) then return {} end
	local c = self:GetWeaponClipPrimary()
	if c != -1 && c <= 0 then self:WeaponReload() end
	if sched.bDuck == nil then sched.bDuck = math.random( 2 ) == 1 end
	if sched.bSuppressing then
		local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
		if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
		local v = enemy:GetPos() + enemy:OBBCenter()
		local trStand, trDuck = util.TraceLine {
			start = sched.vFrom + vStand,
			endpos = v,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		}
		if vDuck then
			trDuck = util.TraceLine {
				start = sched.vFrom + vDuck,
				endpos = v,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
		end
		if !trStand.Hit || trDuck && !trDuck.Hit then sched.bSuppressing = nil return end
		v = sched.vTo
		local trStand, trDuck = util.TraceLine {
			start = sched.vFrom + vStand,
			endpos = v,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		}
		if vDuck then
			trDuck = util.TraceLine {
				start = sched.vFrom + vDuck,
				endpos = v,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
		end
		if trStand.Hit && ( !trDuck || trDuck.Hit ) then self:SetSchedule "TakeCover" return end
		if !sched.Path then sched.Path = Path "Follow" end
		self:ComputePath( sched.Path, sched.vFrom )
		local flHealth = enemy:Health()
		local ws, w = 0 //Weapon Strength
		for wep in pairs( self.tWeapons ) do
			local t = wep.Primary_flDelay || 0
			if t <= 0 then continue end
			local d = wep.Primary_flDamage || 0
			if d <= 0 then continue end
			local nws = math.abs( flHealth - 1 / ( wep.Primary.Automatic && t || t + self.tWeaponPrimaryVolleyNonAutomaticDelay[ 2 ] ) * d * ( wep.Primary_flNum || 1 ) )
			if nws < ws then w, ws = wep, nws end
		end
		if math.abs( sched.Path:GetLength() - sched.Path:GetCursorPosition() ) <= self.flPathGoalTolerance then
			if !sched.Time then sched.Time = CurTime() + math.Rand( self.flShootTimeMin, self.flShootTimeMax ) end
			if CurTime() > sched.Time then self:SetSchedule "TakeCover" return end
			if !sched.bWasInShootPosition then self:DLG_Suppressing( enemy ) end
			sched.bWasInShootPosition = true
			if !trDuck || trDuck && trDuck.Hit then
				self:Stand( 1 )
			elseif trDuck then
				self:Stand( sched.bDuck && 0 || 1 )
			end
			self.vDesAim = ( v - self:GetShootPos() ):GetNormalized()
			if self:CanAttackHelper( v ) then self:RangeAttack() end
		else
			local tNearestEnemies = {}
			for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tNearestEnemies, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
			table.SortByMember( tNearestEnemies, 2, true )
			local tAllies, pEnemy = self:GetAlliesByClass()
			for _, d in ipairs( tNearestEnemies ) do
				local ent = d[ 1 ]
				local v = ent:GetPos() + ent:OBBCenter()
				local tr = util.TraceLine {
					start = self:GetShootPos(),
					endpos = v,
					mask = MASK_SHOT_HULL,
					filter = { self, ent }
				}
				if !tr.Hit || tr.Fraction > self.flSuppressionTraceFraction && tr.HitPos:Distance( v ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
					local b = true
					if !tr.Hit && CurTime() > self.flWeaponPrimaryVolleyTime && ent.GAME_tSuppressionAmount then
						local flMultiplier = 1
						if tAllies then
							for ent in pairs( tAllies ) do
								if ent.Schedule && !util.TraceLine( {
									start = self:GetShootPos(),
									endpos = ent:GetPos() + ent:OBBCenter(),
									mask = MASK_SHOT_HULL,
									filter = { self, ent }
								} ).Hit then flMultiplier = flMultiplier + 2 end
							end
						end
						local flThreshold = ent:Health() * flMultiplier * .1
						for other, am in pairs( ent.GAME_tSuppressionAmount ) do
							if other != self && am > flThreshold then b = nil break end
						end
					end
					if b then
						self.vDesAim = ( ent:GetPos() + ent:OBBCenter() - self:GetShootPos() ):GetNormalized()
						pEnemy = ent
						if self:CanAttackHelper( ent:GetPos() + ent:OBBCenter() ) then self:RangeAttack() end
						break
					end
				end
			end
			if IsValid( pEnemy ) then
				if sched.bDuck == nil then sched.bDuck = math.random( 2 ) == 1 end
				local flDist = self.flWalkSpeed * 4
				flDist = flDist * flDist
				if self:GetPos():DistToSqr( sched.vFrom ) > flDist || sched.bDuck then
					local flDist = self.flProwlSpeed * 4
					flDist = flDist * flDist
					if self:GetPos():DistToSqr( sched.vFrom ) > flDist then
						self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 )
					else self:MoveAlongPath( sched.Path, self.flProwlSpeed, 1 ) end
				else self:MoveAlongPath( sched.Path, self.flWalkSpeed, 0 ) end
			else
				local goal = sched.Path:GetCurrentGoal()
				if goal then
					self.vDesAim = ( goal.pos - self:GetPos() ):GetNormalized()
					//self:ModifyMoveAimVector( self.vDesAim, self.flTopSpeed, 1 )
				end
				if sched.bDuck == nil then sched.bDuck = math.random( 2 ) == 1 end
				local flDist = self.flWalkSpeed * 4
				flDist = flDist * flDist
				if self:GetPos():DistToSqr( sched.vFrom ) > flDist || sched.bDuck then
					local flDist = self.flProwlSpeed * 4
					flDist = flDist * flDist
					if self:GetPos():DistToSqr( sched.vFrom ) > flDist then
						self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 )
					else self:MoveAlongPath( sched.Path, self.flProwlSpeed, 1 ) end
				else self:MoveAlongPath( sched.Path, self.flWalkSpeed, 0 ) end
			end
		end
	else
		local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
		if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
		local v = enemy:GetPos() + enemy:OBBCenter()
		local trStand, trDuck = util.TraceLine {
			start = sched.vFrom + vStand,
			endpos = v,
			mask = MASK_SHOT_HULL,
			filter = { self, enemy, trueenemy }
		}
		if vDuck then
			trDuck = util.TraceLine {
				start = sched.vFrom + vDuck,
				endpos = v,
				mask = MASK_SHOT_HULL,
				filter = { self, enemy, trueenemy }
			}
		end
		if trStand.Hit && ( !trDuck || trDuck.Hit ) then self:SetSchedule "TakeCover" return end
		if !sched.Path then sched.Path = Path "Follow" end
		self:ComputePath( sched.Path, sched.vFrom )
		local flHealth = enemy:Health()
		local ws, w = 0 //Weapon Strength
		for wep in pairs( self.tWeapons ) do
			local t = wep.Primary_flDelay || 0
			if t <= 0 then continue end
			local d = wep.Primary_flDamage || 0
			if d <= 0 then continue end
			local nws = math.abs( flHealth - 1 / ( wep.Primary.Automatic && t || t + self.tWeaponPrimaryVolleyNonAutomaticDelay[ 2 ] ) * d * ( wep.Primary_flNum || 1 ) )
			if nws < ws then w, ws = wep, nws end
		end
		if IsValid( w ) then self:SetActiveWeapon( w ) end
		if math.abs( sched.Path:GetLength() - sched.Path:GetCursorPosition() ) <= self.flPathGoalTolerance then
			if !sched.flTime then sched.flTime = CurTime() + math.Rand( self.flShootTimeMin, self.flShootTimeMax ) end
			if CurTime() > sched.flTime then self:SetSchedule "TakeCover" return end
			if !sched.bWasInShootPosition then self:DLG_FiringAtAnExposedTarget( enemy ) end
			sched.bWasInShootPosition = true
			if !trDuck || trDuck && trDuck.Hit then
				self:Stand( 1 )
			elseif trDuck then
				self:Stand( sched.bDuck && 0 || 1 )
			end
			self.vDesAim = ( enemy:GetPos() + enemy:OBBCenter() - self:GetShootPos() ):GetNormalized()
			if self:CanAttackHelper( enemy:GetPos() + enemy:OBBCenter() ) then self:RangeAttack() end
		else
			local tNearestEnemies = {}
			for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tNearestEnemies, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
			table.SortByMember( tNearestEnemies, 2, true )
			local tAllies, pEnemy = self:GetAlliesByClass()
			for _, d in ipairs( tNearestEnemies ) do
				local ent = d[ 1 ]
				local v = ent:GetPos() + ent:OBBCenter()
				local tr = util.TraceLine {
					start = self:GetShootPos(),
					endpos = v,
					mask = MASK_SHOT_HULL,
					filter = { self, ent }
				}
				if !tr.Hit || tr.Fraction > self.flSuppressionTraceFraction && tr.HitPos:Distance( v ) <= RANGE_ATTACK_SUPPRESSION_BOUND_SIZE then
					local b = true
					if !tr.Hit && CurTime() > self.flWeaponPrimaryVolleyTime && ent.GAME_tSuppressionAmount then
						local flThreshold = ent:Health() * .1
						for other, am in pairs( ent.GAME_tSuppressionAmount ) do
							if other != self && am > flThreshold then b = nil break end
						end
					end
					if b then
						self.vDesAim = ( ent:GetPos() + ent:OBBCenter() - self:GetShootPos() ):GetNormalized()
						pEnemy = ent
						if self:CanAttackHelper( ent:GetPos() + ent:OBBCenter() ) then self:RangeAttack() end
						break
					end
				end
			end
			if IsValid( pEnemy ) then
				if sched.bDuck == nil then sched.bDuck = math.random( 2 ) == 1 end
				local flDist = self.flWalkSpeed * 4
				flDist = flDist * flDist
				if self:GetPos():DistToSqr( sched.vFrom ) > flDist || sched.bDuck then
					local flDist = self.flProwlSpeed * 4
					flDist = flDist * flDist
					if self:GetPos():DistToSqr( sched.vFrom ) > flDist then
						self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 )
					else self:MoveAlongPath( sched.Path, self.flProwlSpeed, 1 ) end
				else self:MoveAlongPath( sched.Path, self.flWalkSpeed, 0 ) end
			else
				local goal = sched.Path:GetCurrentGoal()
				if goal then
					self.vDesAim = ( goal.pos - self:GetPos() ):GetNormalized()
					//self:ModifyMoveAimVector( self.vDesAim, self.flTopSpeed, 1 )
				end
				if sched.bDuck == nil then sched.bDuck = math.random( 2 ) == 1 end
				local flDist = self.flWalkSpeed * 4
				flDist = flDist * flDist
				if self:GetPos():DistToSqr( sched.vFrom ) > flDist || sched.bDuck then
					local flDist = self.flProwlSpeed * 4
					flDist = flDist * flDist
					if self:GetPos():DistToSqr( sched.vFrom ) > flDist then
						self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 )
					else self:MoveAlongPath( sched.Path, self.flProwlSpeed, 1 ) end
				else self:MoveAlongPath( sched.Path, self.flWalkSpeed, 0 ) end
			end
		end
	end
end )
