function ENT:MaybeCoverMove( ... )
	local tAllies = self:GetAlliesByClass()
	if tAllies then
		local b, i
		for ent in pairs( tAllies ) do
			if ent != self then
				i = true
				if ent.bSuppressing then b = true break end
			end
		end
		if math.random( i && ( b && 2 || 3 ) || 3 ) == 1 then return self:DoCoverMove( ... ) end
	else
		if math.random( 3 ) == 1 then return self:DoCoverMove( ... ) end
	end
end

local math_min = math.min
function ENT:DoCoverMove( tEnemies )
	local n = math_min( self.flCombatState, self.flCombatStateSmall )
	if n > 0 then
		local pCover, vec, bDuck = self:FindAdvanceCover( self.vCover, tEnemies )
		if pCover != nil then
			if pCover == self.pActualCover || self.vActualCover && self.vActualCover:DistToSqr( vec ) <= self:BoundingRadius() then return end
			local sched = self:SetSchedule "TakeCoverMove"
			if n < .33 then sched.bTakeCoverAdvance = true else sched.bAdvancing = true end
			self.vCover = vec
			self.pCover = pCover
			self.bCoverDuck = bDuck
			return true
		end
	else
		local pCover, vec, bDuck = self:FindRetreatCover( self.vCover, tEnemies )
		if pCover != nil then
			if pCover == self.pActualCover || self.vActualCover && self.vActualCover:DistToSqr( vec ) <= self:BoundingRadius() then return end
			local sched = self:SetSchedule "TakeCoverMove"
			if n > -.33 then sched.bTakeCoverRetreat = true else sched.bRetreating = true end
			self.vCover = vec
			self.pCover = pCover
			self.bCoverDuck = bDuck
			return true
		end
	end
end

ENT.flCoverMoveDistance = 800

include "CoverAdvance.lua"
include "CoverRetreat.lua"

function ENT:DLG_Advancing() end
function ENT:DLG_Retreating() end
function ENT:DLG_TakeCoverGeneral() end
local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable
function ENT:DLG_TakeCoverAdvance() CEntity_GetTable( self ).DLG_TakeCoverGeneral( self ) end
function ENT:DLG_TakeCoverRetreat() CEntity_GetTable( self ).DLG_TakeCoverGeneral( self ) end

Actor_RegisterSchedule( "TakeCoverMove", function( self, sched )
	local tEnemies = sched.tEnemies || self.tEnemies
	if table.IsEmpty( tEnemies ) then return {} end
	if !self:CanExpose() then self.vCover = nil self.pCover = nil self:SetSchedule "TakeCover" return end
	local enemy = sched.Enemy
	if !IsValid( enemy ) then enemy = self.Enemy if !IsValid( enemy ) then return {} end end
	local enemy, trueenemy = self:SetupEnemy( enemy )
	if table.IsEmpty( __COVER_TABLE_STATIC__ ) && table.IsEmpty( __COVER_TABLE_DYNAMIC__ ) then ErrorNoHaltWithStack "No Cover Nodes!" return {} end
	local tShootables = {}
	for enemy in pairs( tEnemies ) do
		if !IsValid( enemy ) || !HasRangeAttack( enemy ) then continue end
		for _, vec in ipairs( self:CalcEnemyShootPositions( enemy ) ) do
			table.insert( tShootables, { vec, enemy } )
		end
	end
	local c = self:GetWeaponClipPrimary()
	if c != -1 && c <= 0 then self:WeaponReload() end
	if self.pCover && self.vCover then
		local vec = self.vCover
		local tAllies = self:GetAlliesByClass()
		if tAllies then
			local pCover = self.pCover
			for ally in pairs( tAllies ) do
				if self == ally then continue end
				if ally.pActualCover == pCover || ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= self:BoundingRadius() ^ 2 then self.vCover = nil self.pCover = nil self:SetSchedule "TakeCover" return end
			end
		end
		local vOffStanding, vOffDucking = Vector( 0, 0, self.vHullMaxs.z )
		if self.vHullDuckMaxs && self.vHullDuckMaxs.z != self.vHullMaxs.z then
			vOffDucking = Vector( 0, 0, self.vHullDuckMaxs.z )
		end
		local vStand, vDuck, bDuck = vec + vOffStanding
		if vOffDucking then vDuck = vec + vOffDucking end
		for _, d in pairs( tShootables ) do
			local vec, ent = unpack( d )
			if vDuck then
				if !util.TraceLine( {
					start = vec,
					endpos = vDuck,
					mask = MASK_SHOT_HULL,
					filter = { self, ent }
				} ).Hit then self.pCover = nil return end
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
				} ).Hit then self.pCover = nil return end
			end
		end
		local b = true
		local vStand, vDuck = vec + vOffStanding
		if vOffDucking then vDuck = vec + vOffDucking end
		local flOff = math.max( math.abs( self:OBBMaxs().x ), math.abs( self:OBBMins().x ) ) * 1.5
		local flOffDistSqr = flOff * 3
		flOffDistSqr = flOffDistSqr * flOffDistSqr
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
		if b then self.pCover = nil self.vCover = nil return end
		if sched.bActed == nil then
			if sched.bTakeCoverAdvance then self:DLG_TakeCoverAdvance()
			elseif sched.bTakeCoverRetreat then self:DLG_TakeCoverRetreat()
			elseif sched.bAdvancing then self:DLG_Advancing()
			elseif sched.bRetreating then self:DLG_Retreating() end
			sched.bActed = true
			local bSearch = true
			//If We can Shoot Them, Almost Always Go for It, UnLess Retreating
			if math.Rand( 0, 1.5 ) <= ( sched.bRetreating && 1 || .75 ) then
				local vec, enemy = self:FindExposedEnemy( self.vCover, tEnemies, self.bCoverDuck )
				if IsValid( enemy ) && math.Rand( 0, 1.5 ) <= ( sched.bRetreating && 1 || .75 ) then
					sched.vFrom = vec
					sched.pToShootEnemy = enemy
					sched.bToShoot = true
					bSearch = nil
				end
			end
			//OtherWise, Consider Doing It
			if bSearch && math.random( sched.bRetreating && 3 || 2 ) == 1 then
				local vFrom, vTo, enemy = self:FindSuppressEnemy( self.vCover, tEnemies, self.bCoverDuck )
				if IsValid( enemy ) then
					sched.vFrom = vFrom
					sched.vTo = vTo
					sched.pToShootEnemy = enemy
					sched.bSuppressing = true
					sched.bToShoot = true
				end
			end
		end
		if sched.bToShoot then
			local enemy = sched.pToShootEnemy
			if !IsValid( enemy ) then sched.bToShoot = nil return end
			local enemy, trueenemy = self:SetupEnemy( enemy )
			if sched.bDuck == nil then sched.bDuck = math.random( 2 ) == 1 end
			if sched.bSuppressing then
				local vStand, vDuck = Vector( 0, 0, self.vHullMaxs.z )
				if self.vHullDuckMaxs && vStand.z != self.vHullDuckMaxs.z then vDuck = Vector( 0, 0, self.vHullDuckMaxs.z ) end
				local v = sched.vTo
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
				if trStand.Hit && ( !trDuck || trDuck.Hit ) then sched.bToShoot = nil return end
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
					if !sched.Time then sched.Time = CurTime() + math.Rand( self.flShootTimeMin, self.flShootTimeMax ) end
					if CurTime() > sched.Time then return { true } end
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
										if ent.Schedule && ent.Schedule.m_sName == "TakeCover" && !util.TraceLine( {
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
						//local flDist = self.flWalkSpeed * 4
						//flDist = flDist * flDist
						//if self:GetPos():DistToSqr( self.vCover ) > flDist || sched.bDuck then
						local flDist = self.flProwlSpeed * 4
						flDist = flDist * flDist
						if self:GetPos():DistToSqr( self.vCover ) > flDist then
							self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 )
						else self:MoveAlongPath( sched.Path, self.flProwlSpeed, 1 ) end
						//else self:MoveAlongPath( sched.Path, self.flWalkSpeed, 0 ) end
					else
						local goal = sched.Path:GetCurrentGoal()
						if goal then self.vDesAim = ( goal.pos - self:GetPos() ):GetNormalized() end
						self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 )
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
				if trStand.Hit && ( !trDuck || trDuck.Hit ) then sched.bToShoot = nil return end
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
					if !sched.Time then sched.Time = CurTime() + math.Rand( self.flShootTimeMin, self.flShootTimeMax ) end
					if CurTime() > sched.Time then return { true } end
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
								local flMultiplier = 1
								if tAllies then
									for ent in pairs( tAllies ) do
										if ent.Schedule && ent.Schedule.m_sName == "TakeCover" && !util.TraceLine( {
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
						//local flDist = self.flWalkSpeed * 4
						//flDist = flDist * flDist
						//if self:GetPos():DistToSqr( self.vCover ) > flDist || sched.bDuck then
						local flDist = self.flProwlSpeed * 4
						flDist = flDist * flDist
						if self:GetPos():DistToSqr( self.vCover ) > flDist then
							self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 )
						else self:MoveAlongPath( sched.Path, self.flProwlSpeed, 1 ) end
						//else self:MoveAlongPath( sched.Path, self.flWalkSpeed, 0 ) end
					else
						local goal = sched.Path:GetCurrentGoal()
						if goal then self.vDesAim = ( goal.pos - self:GetPos() ):GetNormalized() end
						self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 )
					end
				end
			end
			return
		end
		if !sched.Path then sched.Path = Path "Follow" end
		self:ComputePath( sched.Path, self.vCover )
		if math.abs( sched.Path:GetLength() - sched.Path:GetCursorPosition() ) <= 8 then return { true } end
		self.pActualCover = self.pCover
		self.vActualCover = self.vCover
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
			if self.bCoverDuck == true then sched.bCoverStand = nil
			elseif sched.bCoverStand == nil then sched.bCoverStand = math.random( 2 ) == 1 end
			//local flDist = self.flWalkSpeed * 4
			//flDist = flDist * flDist
			//if self:GetPos():DistToSqr( self.vCover ) > flDist || sched.bCoverStand then
			local flDist = self.flProwlSpeed * 4
			flDist = flDist * flDist
			if self:GetPos():DistToSqr( self.vCover ) > flDist then
				self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 )
			else self:MoveAlongPath( sched.Path, self.flProwlSpeed, 1 ) end
			//else self:MoveAlongPath( sched.Path, self.flWalkSpeed, 0 ) end
		else
			local goal = sched.Path:GetCurrentGoal()
			if goal then
				self.vDesAim = ( goal.pos - self:GetPos() ):GetNormalized()
				self:ModifyMoveAimVector( self.vDesAim, self.flTopSpeed, 1 )
			end
			self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 )
		end
	else return {} end
end )
