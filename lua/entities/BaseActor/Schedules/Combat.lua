local table_IsEmpty = table.IsEmpty
local HasRangeAttack, HasMeleeAttack = HasRangeAttack, HasMeleeAttack
local util = util
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull
local util_DistanceToLine = util.DistanceToLine
local math = math
local math_Rand = math.Rand
local unpack = unpack
local CurTime = CurTime

function ENT:DLG_MeleeReachable( pEnemy ) end
function ENT:DLG_MeleeUnReachable( pEnemy ) end

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

// ENT.bMeleeChargeAgainstRange - Far Cry 3 Pirate Beheader
// ENT.flMeleeChargeTauntMultiplier = 1

function ENT:DLG_MeleeTaunt() end

ENT.flCoverMoveDistance = 768

include "HoldFireCheckEnemy.lua"

Actor_RegisterSchedule( "Combat", function( self, sched )
	local tEnemies = sched.tEnemies || self.tEnemies
	if table_IsEmpty( tEnemies ) then return {} end
	local enemy = sched.Enemy
	if IsValid( enemy ) then enemy = enemy
	else enemy = self.Enemy if !IsValid( enemy ) then return {} end end
	local enemy, trueenemy = self:SetupEnemy( enemy )
	if !self.bHoldFire && CurTime() > ( self.flLastEnemy + self.flHoldFireTime ) then self:DLG_HoldFire() end
	if HasMeleeAttack( self ) && !HasRangeAttack( self ) then
		if !self.bEnemiesHaveRangeAttack || self.bMeleeChargeAgainstRange then
			// TODO: Melee vs melee dance behavior
			/*if self.bEnemiesHaveMeleeAttack then
				local pPath = sched.pEnemyPath
				if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
				self:ComputeFlankPath( pPath, enemy )
				if self:Visible( enemy ) then
					local vTarget, vShoot = enemy:GetPos() + enemy:OBBCenter(), self:GetShootPos()
					self.vDesAim = ( vTarget - vShoot ):GetNormalized()
					local d = self.GAME_flReach || 64
					local wep = self.Weapon
					if IsValid( wep ) then d = d + wep.Melee_flRangeAdd || 0 end
					local vMins, vMaxs = self:GatherShootingBounds()
					local flDistance = vTarget:Distance( vShoot )
					if flDistance <= d && self:Disposition( util_TraceLine( {
						start = vShoot,
						endpos = vShoot + self:GetAimVector() * d,
						filter = self,
						mask = MASK_SHOT_HULL,
						mins = vMins, maxs = vMaxs
					} ).Entity ) != D_LI then self:WeaponPrimaryAttack() end
					if flDistance <= d * 3 || flDistance > d * 6 then
						self:MoveAlongPath( pPath, self.flTopSpeed, 1 )
					else
						self:MoveAlongPath( pPath, self.flRunSpeed, 1 )
					end
				else
					self:ComputeFlankPath( pPath, enemy )
					self:MoveAlongPath( pPath, self.flTopSpeed, 1 )
					local goal = pPath:GetCurrentGoal()
					local v = self:GetPos()
					if goal then self.vDesAim = ( goal.pos - v ):GetNormalized() end
				end
			else*/
				local pPath = sched.pEnemyPath
				if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
				self:ComputeFlankPath( pPath, enemy )
				self:MoveAlongPath( pPath, self.flTopSpeed, 1 )
				if self:Visible( enemy ) then
					if math.random( 10000 * ( self.flMeleeChargeTauntMultiplier || 1 ) * FrameTime() ) == 1 then self:DLG_MeleeTaunt() return end
					local vTarget, vShoot = enemy:GetPos() + enemy:OBBCenter(), self:GetShootPos()
					self.vDesAim = ( vTarget - vShoot ):GetNormalized()
					local d = self.GAME_flReach || 64
					local wep = self.Weapon
					if IsValid( wep ) then d = d + wep.Melee_flRangeAdd || 0 end
					local vMins, vMaxs = self:GatherShootingBounds()
					if vTarget:Distance( vShoot ) <= d && self:Disposition( util_TraceLine( {
						start = vShoot,
						endpos = vShoot + self:GetAimVector() * d,
						filter = self,
						mask = MASK_SHOT_HULL,
						mins = vMins, maxs = vMaxs
					} ).Entity ) != D_LI then self:WeaponPrimaryAttack() end
				else
					local goal = pPath:GetCurrentGoal()
					local v = self:GetPos()
					if goal then self.vDesAim = ( goal.pos - v ):GetNormalized() end
				end
			//end
		else self:SetSchedule "TakeCover" end
		return
	end
	if sched.bAdvance || sched.bRetreat then
		local pPath = sched.pEnemyPath
		if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
		if !sched.bStartedSearching then
			self:ComputeFlankPath( pPath, enemy )
			if !sched.bFromCombatFormation && sched.bAdvance then
				local i = self:FindPathStackUpLine( pPath, tEnemies )
				if i then
					self.iLastEnemyPathStackUpCursor = i
					pPath:MoveCursorTo( i )
					local g = pPath:GetCurrentGoal()
					if g then
						local b = self:CreateBehaviour "CombatFormation"
						local v = pPath:GetPositionOnPath( i )
						b.Vector = v
						b.Direction = ( pPath:GetPositionOnPath( i + 1 ) - v ):GetNormalized()
						b:AddParticipant( self )
						b:GatherParticipants()
						b:Initialize()
						return
					end
				end
			end
			sched.bStartedSearching = true
		end
		local vEnemy = enemy:GetPos()
		local pIterator = sched.pIterator
		local bAdvance = sched.bAdvance
		if !sched.pIterator then
			if bAdvance then
				pPath:MoveCursorToClosestPosition( self.vCover || self:GetPos() )
				pPath:MoveCursor( self.flCombatState * self.flCoverMoveDistance )
				pIterator = self:SearchAreas( pPath:GetPositionOnPath( pPath:GetCursorPosition() ), function( _/*pFrom*/, pTo ) return pTo:GetClosestPointOnArea( vEnemy ):Distance( vEnemy ) end )
			else
				pIterator = self:SearchAreas( nil, function( _/*pFrom*/, pTo ) return -pTo:GetClosestPointOnArea( vEnemy ):Distance( vEnemy ) end )
			end
			sched.pIterator = pIterator
		end
		local v = sched.vCoverBounds || self:GatherCoverBounds()
		sched.vCoverBounds = v
		local tAllies = self:GetAlliesByClass()
		local f = sched.flBoundingRadiusTwo || ( self:BoundingRadius() ^ 2 )
		sched.flBoundingRadiusTwo = f
		local vMaxs = self.vHullDuckMaxs || self.vHullMaxs
		local tCovers = {}
		local tOldCover = self.tCover
		local d = self.vHullMaxs.x * 4
		local iLastEnemyPathStackUpCursor = bAdvance && self.iLastEnemyPathStackUpCursor || 0
		for _ = 0, 64 do
			local pArea = pIterator()
			if pArea == nil then
				// REPEAT!!! AND TRY HARDER!!!
				sched.pIterator = nil
				return
			end
			table.Empty( tCovers )
			for _, t in ipairs( __COVERS_STATIC__[ pArea:GetID() ] || {} ) do table.insert( tCovers, { t, util.DistanceToLine( t[ 1 ], t[ 2 ], self:GetPos() ) } ) end
			for _, t in ipairs( __COVERS_DYNAMIC__[ pArea:GetID() ] || {} ) do table.insert( tCovers, { t, util.DistanceToLine( t[ 1 ], t[ 2 ], self:GetPos() ) } ) end
			table.SortByMember( tCovers, 2, true )
			for _, t in ipairs( tCovers ) do
				local tCover = t[ 1 ]
				if tCover == tOldCover then continue end
				local vStart, vEnd = tCover[ 1 ], tCover[ 2 ]
				local vDirection = vEnd - vStart
				local flStep, flStart, flEnd
				if vStart:DistToSqr( self:GetPos() ) <= vEnd:DistToSqr( self:GetPos() ) then
					flStart, flEnd, flStep = 0, vDirection:Length(), vMaxs[ 1 ]
				else
					flStart, flEnd, flStep = vDirection:Length(), 0, -vMaxs[ 1 ]
				end
				vDirection:Normalize()
				local vOff = tCover[ 3 ] && vDirection:Angle():Right() || -vDirection:Angle():Right()
				vOff = vOff * vMaxs[ 1 ] * math.max( 1.25, COVER_BOUND_SIZE * .5 )
				for iCurrent = flStart, flEnd, flStep do
					local vCover = vStart + vDirection * iCurrent + vOff
					pPath:MoveCursorToClosestPosition( vCover )
					local iCursor = pPath:GetCursorPosition()
					if bAdvance && iCursor <= iLastEnemyPathStackUpCursor then continue end
					local dDirection = pPath:GetPositionOnPath( iCursor )
					pPath:MoveCursor( 1 )
					dDirection = pPath:GetPositionOnPath( pPath:GetCursorPosition() ) - dDirection
					dDirection[ 3 ] = 0
					dDirection:Normalize()
					if util_TraceHull( {
						start = vCover,
						endpos = vCover,
						mins = vMins,
						maxs = vMaxs,
						filter = self
					} ).Hit then continue end
					local v = vCover + Vector( 0, 0, vMaxs[ 3 ] )
					if !util_TraceLine( {
						start = v,
						endpos = v + dDirection * vMaxs[ 1 ] * COVER_BOUND_SIZE,
						filter = self
					} ).Hit then continue end
					if tAllies then
						local b
						for pAlly in pairs( tAllies ) do
							if self == pAlly then continue end
							if pAlly.vActualCover && pAlly.vActualCover:DistToSqr( vCover ) <= f || pAlly.vActualTarget && pAlly.vActualTarget:DistToSqr( vCover ) <= f then b = true break end
						end
						if b then continue end
					end
					self.vCover = vCover
					self.tCover = tCover
					return
				end
			end
		end
	else sched.bStartedSearching = nil end
	if self.vCover then
		local vec = self.vCover
		self.vActualCover = vec
		if !sched.Path then sched.Path = Path "Follow" end
		self:ComputePath( sched.Path, self.vCover )
		local tAllies = self:GetAlliesByClass()
		if tAllies then
			local f = self:BoundingRadius()
			f = f * f
			for ally in pairs( tAllies ) do
				if self == ally then continue end
				if ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= f || ally.vActualTarget && ally.vActualTarget:DistToSqr( vec ) <= f then self.vCover = nil self:SetSchedule "TakeCover" return end
			end
		end
		local f = self.flPathTolerance
		if self:GetPos():DistToSqr( vec ) > ( f * f ) then self.vCover = nil self.tCover = nil return end
		local v = vec + Vector( 0, 0, self.vHullDuckMaxs[ 3 ] )
		// Don't even try to repath often!
		local pEnemyPath = self.pLastEnemyPath || sched.pEnemyPath
		if !pEnemyPath then
			pEnemyPath = Path "Follow"
			self:ComputeFlankPath( pEnemyPath, enemy )
			self.pLastEnemyPath = pEnemyPath
			sched.pEnemyPath = pEnemyPath
		end
		pEnemyPath:MoveCursorToClosestPosition( vec )
		local d = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() )
		pEnemyPath:MoveCursor( 1 )
		d = pEnemyPath:GetPositionOnPath( pEnemyPath:GetCursorPosition() ) - d
		d[ 3 ] = 0
		d:Normalize()
		if !util_TraceLine( {
			start = v,
			endpos = v + d * self.vHullMaxs[ 1 ] * COVER_BOUND_SIZE,
			mask = MASK_SHOT_HULL,
			filter = self
		} ).Hit then
			self.vCover = nil
			self.tCover = nil
			self:SetSchedule "TakeCover"
			return
		end
		v = vec + Vector( 0, 0, self.vHullMaxs[ 3 ] )
		sched.bDuck = nil
		self:Stand( util_TraceLine( {
			start = v,
			endpos = v + d * self.vHullMaxs[ 1 ] * COVER_BOUND_SIZE,
			filter = self
		} ).Hit && 0 || 1 )
		self.vDesAim = d
		if self:CanExpose() then
			if CurTime() > ( self.flSuppressed || 0 ) then
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
				local pPath = sched.pEnemyPath
				if !pPath then pPath = Path "Follow" sched.pEnemyPath = pPath end
				self:ComputeFlankPath( pPath, enemy )
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
				local aDirection
				local tGoal = pPath:NextSegment()
				if tGoal then aDirection = ( tGoal.pos - vec ):Angle()
				else aDirection = ( enemy:GetPos() - vec ):Angle() end
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
						local vPos = vOrigin + vHeight
						local tWholeFilter = IsValid( trueenemy ) && { self, enemy, trueenemy } || { self, enemy }
						for i, flGlobalAnglePitch in ipairs( tPitchAngles ) do
							for i, flGlobalAngleYaw in ipairs( tAngles ) do
								// local aAim = aDirection + Angle( flGlobalAnglePitch, flGlobalAngleYaw )
								local aAim = aDirection + Angle( 0, flGlobalAngleYaw )
								aAim[ 1 ] = flGlobalAnglePitch
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
								} ).Hit || bCheckDistance && vPoint:DistToSqr( vTarget ) > flDistSqr then
									continue
								end
								return vPoint
							end
						end
					end
				end
				if self.bHoldFire then
					local tAllies = self:GetAlliesByClass()
					if tAllies then
						local b = true
						for ent in pairs( tAllies ) do
							if !IsValid( ent ) || ent == self || !ent.__ACTOR__ || !IsValid( ent.Enemy ) || !ent:IsCurrentSchedule "HoldFireCheckEnemy" then continue end
							local _, pTrueEnemy = ent:SetupEnemy( ent.Enemy )
							if pTrueEnemy == trueenemy then b = nil break end
						end
						if b then
							self:SetSchedule( "HoldFireCheckEnemy" ).pEnemy = enemy
							return
						end
					else self:SetSchedule( "HoldFireCheckEnemy" ).pEnemy = enemy end
				end
				local aGeneral = Angle( aDirection )
				aGeneral[ 1 ] = 0
				local dRight = aGeneral:Right()
				local dLeft = -dRight
				local flDistance = self:OBBMaxs().x * 2
				local vLeft = vec + dLeft * flDistance
				local flAdd = self:OBBMaxs().x
				local trLeft = util_TraceHull {
					start = vec + vHeight,
					endpos = vLeft + dLeft * flAdd + vHeight,
					mins = vMins,
					maxs = vMaxs,
					filter = self
				}
				local tAngles = { 0 }
				for a = 5.625, 22.5, 5.625 do
					table.insert( tAngles, -a )
					table.insert( tAngles, a )
				end
				local vLeftTarget = fDo( trLeft, vLeft, tAngles )
				local flDistance = self:OBBMaxs().x * 2
				local vRight = vec + dRight * flDistance
				local trRight = util_TraceHull {
					start = vec + vHeight,
					endpos = vRight + dRight * flAdd + vHeight,
					mins = vMins,
					maxs = vMaxs,
					filter = self
				}
				tAngles = { 0 }
				for a = 5.625, 22.5, 5.625 do
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
				if !sched.pEnemyPath then sched.pEnemyPath = Path "Follow" end
				self:ComputeFlankPath( sched.pEnemyPath, enemy )
				if !sched.bFromCombatFormation && self.flCombatState > 0 then
					local p = sched.pEnemyPath
					local i = self:FindPathStackUpLine( p, tEnemies )
					if i then
						self.iLastEnemyPathStackUpCursor = i
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
		else self.flSuppressed = CurTime() + math.Clamp( math.min( 0, ( self:GetExposedWeight() / self:Health() ) * .2 ), 0, 2 ) end
	else self:SetSchedule "TakeCover" end
end )

include "CombatStuff.lua"
