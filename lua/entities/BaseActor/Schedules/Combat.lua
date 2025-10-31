local table_IsEmpty = table.IsEmpty
local HasRangeAttack, HasMeleeAttack = HasRangeAttack, HasMeleeAttack
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull
local math_Rand = math.Rand
local unpack = unpack
local CurTime = CurTime

function ENT:DLG_MeleeReachable( pEnemy ) end
function ENT:DLG_MeleeUnReachable( pEnemy ) end

local developer = GetConVar "developer"

Actor_RegisterSchedule( "Combat", function( self, sched )
	local tEnemies = sched.tEnemies || self.tEnemies
	if table_IsEmpty( tEnemies ) then return {} end
	local enemy = sched.Enemy
	if IsValid( enemy ) then enemy = enemy
	else enemy = self.Enemy if !IsValid( enemy ) then return {} end end
	local enemy, trueenemy = self:SetupEnemy( enemy )
	if CurTime() > ( self.flLastEnemy + self.flHoldFireTime ) && !self.bHoldFire then self:DLG_HoldFire() end
	if sched.bAdvance || sched.bRetreat then
		self.vActualCover = self.vCover
		self:Stand( self:GetCrouchTarget() )
		local bAdvance = sched.bAdvance
		local pIterator = sched[ bAdvance && "pAdvanceIterator" || "pRetreatIterator" ]
		local vEnemy = enemy:GetPos()
		local tFilter = IsValid( enemy.GAME_pVehicle ) && { self, enemy, enemy.GAME_pVehicle } || { self, enemy }
		if !pIterator then
			local vPos
			if bAdvance then
				local pPath = Path "Follow"
				self:ComputeFlankPath( pPath, enemy )
				local p = self:FindPathBattleLineNoAllies( pPath, tEnemies )
				if p then vPos = pPath:GetPositionOnPath( p ) end
			end
			pIterator = self:SearchNodes( vPos, nil, bAdvance && function( bIsArea, p, flDistSoFar, flDist )
				if bIsArea then
					return p:GetClosestPointOnArea( vEnemy ):Distance( vEnemy )
				else
					return p:Distance( vEnemy )
				end
			end || function( bIsArea, p, flDistSoFar, flDist )
				if bIsArea then
					return -p:GetClosestPointOnArea( vEnemy ):Distance( vEnemy )
				else
					return -p:Distance( vEnemy )
				end
			end )
			sched[ bAdvance && "pAdvanceIterator" || "pRetreatIterator" ] = pIterator
		end
		local v = sched.vCoverBounds || self:GatherCoverBounds()
		sched.vCoverBounds = v
		local tAllies = sched.tAllies || self:GetAlliesByClass()
		sched.tAllies = tAllies
		local f = sched.flBoundingRadiusTwo || ( self:BoundingRadius() ^ 2 )
		sched.flBoundingRadiusTwo = f
		local d = self.vHullMaxs.x * 4 // We check somewhat distant positions, so give them some range to consider "cover"...
		for _ = 0, 32 do
			local vec = pIterator()
			if vec == nil then
				// REPEAT!!! AND TRY HARDER!!!
				sched[ sched.bAdvance && "pAdvanceIterator" || "pRetreatIterator" ] = nil
				return
			end
			if vec:DistToSqr( self:GetPos() ) <= 134656/*256*/ then continue end
			local p = vec + v
			local dir = vEnemy - vec
			dir.z = 0
			dir:Normalize()
			if util_TraceLine( {
				start = p,
				endpos = p + dir * d,
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
				self.vActualCover = vec
				self.vCover = vec
				local s = self:SetSchedule "TakeCoverMove"
				s.bAdvancing = true
				return
			end
		end
		if !self.vCover && self:CanExpose() then return end
	end
	if self.vCover then
		local vec = self.vCover
		self.vActualCover = vec
		if !sched.Path then sched.Path = Path "Follow" end
		self:ComputePath( sched.Path, self.vCover )
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
		if !util_TraceLine( {
			start = v,
			endpos = v + dir * self.vHullMaxs.x * 4,
			mask = MASK_SHOT_HULL,
			filter = function( ent ) return !( ent:IsPlayer() || ent:IsNPC() || ent:IsNextBot() ) end
		} ).Hit then self.vCover = nil return end
		local v = self:GetPos() + self:GatherCoverBounds()
		local dir = enemy:GetPos() - vec
		dir.z = 0
		dir:Normalize()
		local f = self.flPathGoalTolerance
		if !util_TraceLine( {
			start = v,
			endpos = v + dir * self.vHullMaxs.x * 4,
			mask = MASK_SHOT_HULL,
			filter = function( ent ) return !( ent:IsPlayer() || ent:IsNPC() || ent:IsNextBot() ) end
		} ).Hit || self:GetPos():DistToSqr( vec ) > ( f * f ) then self.vCover = nil return end
		if !util_TraceLine( {
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
				local flAlarm, vPos, pAlarm = math.huge, self:GetShootPos(), NULL // NULL because ent.pAlarm ( if nil ) == pAlarm ( which is nil )
				local t = __ALARMS__[ self:Classify() ]
				if t then
					for ent in pairs( t ) do
						if !IsValid( ent ) || ent.bIsOn then continue end
						local d = ent:NearestPoint( vPos ):DistToSqr( vPos )
						// Don't go out of audible range, even if an ally alarm. Why?
						// Because it's not funny to run kilometers away from the battlefield to it like an idiot
						if d >= flAlarm || Either( ent.flAudibleDistSqr == 0, self:Visible( ent ), d >= ent.flAudibleDistSqr ) then continue end
						local b
						if tAllies then for ent in pairs( tAllies ) do if ent != self && IsValid( ent ) && ent.pAlarm == pAlarm then b = true break end end end
						if b then continue end
						pAlarm, flAlarm = ent, d
					end
				end
				if IsValid( pAlarm ) then
					local s = self:SetSchedule "PullAlarm"
					s.pAlarm = pAlarm
					self.pAlarm = pAlarm
					return
				end
				t = __ALARMS__[ CLASS_NONE ]
				if t then
					for ent in pairs( t ) do
						if !IsValid( ent ) || ent.bIsOn then continue end
						local d = ent:NearestPoint( vPos ):DistToSqr( vPos )
						if d >= flAlarm || Either( ent.flAudibleDistSqr == 0, self:Visible( ent ), d >= ent.flAudibleDistSqr ) then continue end
						local b
						if tAllies then for ent in pairs( tAllies ) do if ent != self && IsValid( ent ) && ent.pAlarm == pAlarm then b = true break end end end
						if b then continue end
						pAlarm, flAlarm = ent, d
					end
				end
				if IsValid( pAlarm ) then
					local s = self:SetSchedule "PullAlarm"
					s.pAlarm = pAlarm
					self.pAlarm = pAlarm
					return
				end
				local aDirection = ( enemy:GetPos() - vec ):Angle()
				local vTarget = enemy:GetPos() + enemy:OBBCenter()
				local vHeight = Vector( 0, 0, self.vHullDuckMaxs[ 3 ] )
				local tPitchAngles = { 0 }
				if enemy:GetPos().z > self:GetPos().z then
					for a = 5.625, 90, 5.625 do
						table.insert( tPitchAngles, a )
						table.insert( tPitchAngles, -a )
					end
				else
					for a = 5.625, 90, 5.625 do
						table.insert( tPitchAngles, -a )
						table.insert( tPitchAngles, a )
					end
				end
				local bCheckDistance, flDistSqr = self.flCombatState > 0
				if bCheckDistance then
					flDistSqr = RANGE_ATTACK_SUPPRESSION_BOUND_SIZE
					flDistSqr = flDistSqr * flDistSqr
				end
				local function fDo( tr, vOrigin, tAngles )
					if !tr.Hit then
						debugoverlay.SweptBox( vOrigin, vOrigin, self.vHullDuckMins, self.vHullDuckMaxs, angle_zero, 5, Color( 0, 255, 255 ) )
						local vPos = vOrigin + vHeight
						local tWholeFilter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
						for i, flGlobalAnglePitch in ipairs( tPitchAngles ) do
							for i, flGlobalAngleYaw in ipairs( tAngles ) do
								local aAim = aDirection + Angle( flGlobalAnglePitch, flGlobalAngleYaw )
								local vAim = aAim:Forward()
								local tr = util_TraceLine {
									start = vPos,
									endpos = vPos + vAim * 999999,
									mask = MASK_SHOT_HULL,
									filter = self
								}
								local _, vPoint = util.DistanceToLine( vPos, tr.HitPos, vTarget )
								if util_TraceLine( {
									start = vPoint,
									endpos = vTarget,
									mask = MASK_SHOT_HULL,
									filter = tWholeFilter
								} ).Hit && ( bCheckDistance && vPoint:DistToSqr( vTarget ) <= flDistSqr || !bCheckDistance ) then
									if developer:GetInt() > 0 then debugoverlay.Line( tr.StartPos, tr.HitPos, 5, Color( 255, 0, 0, 85 ), true ) end
									continue
								end
								if developer:GetInt() > 0 then
									debugoverlay.Line( tr.StartPos, tr.HitPos, 5, Color( 0, 255, 255 ), true )
									debugoverlay.Cross( vPoint, 10, 5, Color( 0, 255, 255 ), true )
								end
								return vPoint
							end
						end
					else debugoverlay.SweptBox( vOrigin, vOrigin, self.vHullDuckMins, self.vHullDuckMaxs, angle_zero, 5, Color( 255, 0, 0 ) ) end
				end
				local aGeneral = Angle( aDirection )
				aGeneral[ 1 ] = 0
				local dRight = aGeneral:Right()
				local dLeft = -dRight
				local flDistance = self:OBBMaxs().x * 2
				local vLeft = vec + dLeft * flDistance
				local trLeft = util_TraceLine {
					start = vec + vHeight,
					endpos = vLeft + vHeight,
					filter = self
				}
				local tAngles = { 0 }
				for a = 5.625, 90, 5.625 do
					table.insert( tAngles, -a )
					table.insert( tAngles, a )
				end
				local vLeftTarget = fDo( trLeft, vLeft, tAngles )
				local flDistance = self:OBBMaxs().x * 2
				local vRight = vec + dRight * flDistance
				local trRight = util_TraceLine {
					start = vec + vHeight,
					endpos = vRight + vHeight,
					filter = self
				}
				tAngles = { 0 }
				for a = 5.625, 90, 5.625 do
					table.insert( tAngles, a )
					table.insert( tAngles, -a )
				end
				local vRightTarget = fDo( trRight, vRight, tAngles )
				local function SetupSchedule( vOrigin, vTarget )
					local sched = self:SetSchedule "RangeAttack"
					sched.vFrom = vOrigin
					sched.vTo = vTarget
					sched.Enemy = enemy
					sched.bSuppressing = true
				end
				if vLeftTarget && vRightTarget then
					if math.random( 2 ) == 1 then
						SetupSchedule( vLeft, vLeftTarget )
					else
						SetupSchedule( vRight, vRightTarget )
					end
					return
				elseif vLeftTarget then
					SetupSchedule( vLeft, vLeftTarget )
					return
				elseif vRightTarget then
					SetupSchedule( vRight, vRightTarget )
					return
				else
					sched[ self.flCombatState > 0 && "bAdvance" || "bRetreat" ] = true
					return
				end
				if self.flCombatState < 0 && math.random( 2 ) == 1 then sched.bRetreat = true return else
					local tAllies = self:GetAlliesByClass()
					local iShootingAllies, iAllies = 0, table.Count( tAllies )
					if iAllies <= 1 then
						if math.random( 2 ) == 1 then sched[ self.flCombatState > 0 && "bAdvance" || "bRetreat" ] = true end
					else
						for ent in pairs( tAllies ) do if ent.bSuppressing then iShootingAllies = iShootingAllies + 1 end end
						if math_Rand( 0, iAllies / iShootingAllies ) <= 1 then sched[ self.flCombatState > 0 && "bAdvance" || "bRetreat" ] = true end
					end
				end
				if !sched.pEnemyPath then sched.pEnemyPath = Path "Follow" end
				self:ComputeFlankPath( sched.pEnemyPath, enemy )
				if self.flCombatState > 0 then
					local p = sched.pEnemyPath
					local i = self:FindPathStackUpLine( p, tEnemies )
					if i && i > 256 then
						p:MoveCursorTo( i )
						local g = p:GetCurrentGoal()
						if g then
							local b = self:CreateBehaviour "CombatFormation"
							local v = p:GetPositionOnPath( i )
							b.Vector = v
							b.Direction = ( p:GetPositionOnPath( i + 1 ) - v ):GetNormalized()
							b:AddParticipant( self )
							b:GatherParticipants()
							b:Initialize()
							return
						end
					end
				end
			end
		else sched.flSuppressed = CurTime() + math.Clamp( math.min( 0, ( self:GetExposedWeight() / self:Health() ) * .2 ), 0, 2 ) end
	else
		local vec = self:GetPos()
		local v, pEnemy = self:FindExposedEnemy( vec, tEnemies, sched.bDuck )
		if IsValid( pEnemy ) then
			local sched = self:SetSchedule "RangeAttack"
			sched.vFrom = v
			sched.Enemy = pEnemy
		else
			if !sched.pEnemyPath then sched.pEnemyPath = Path "Follow" end
			self:ComputeFlankPath( sched.pEnemyPath, enemy )
			local vFrom, vTo, pEnemy = self:FindSuppressEnemy( vec, tEnemies, sched.bDuck )
			if IsValid( pEnemy ) then
				local sched = self:SetSchedule "RangeAttack"
				sched.vFrom = vFrom
				sched.vTo = vTo
				sched.Enemy = pEnemy
				sched.bSuppressing = true
			else self:SetSchedule "TakeCover" end
		end
		return
	end
end )

include "CombatStuff.lua"
