local COVERED_MOVE_CHANCE, COVERED_NOT_MOVE_CHANCE = 3, 6

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
		if math.random( i && ( b && COVERED_MOVE_CHANCE || COVERED_NOT_MOVE_CHANCE ) || COVERED_NOT_MOVE_CHANCE ) == 1 then return self:DoCoverMove( ... ) end
	else
		if math.random( COVERED_NOT_MOVE_CHANCE ) == 1 then return self:DoCoverMove( ... ) end
	end
end

local math = math
local math_min = math.min
local math_abs = math.abs
function ENT:DoCoverMove( tEnemies )
	local enemy = self.Enemy
	if !IsValid( enemy ) then return end
	local a = self.flCombatState
	local n = math_min( a, self.flCombatStateSmall )
	if n > 0 then
		local p = Path "Follow"
		//self:ComputeFlankPath( p, enemy )
		self:ComputePath( p, enemy:GetPos() )
		local i = self:FindPathStackUpLine( p, tEnemies )
		if i && i > 512 then
			p:MoveCursorTo( i )
			local g = p:GetCurrentGoal()
			if g then
				local b = self:CreateBehaviour "CombatFormation"
				b.Vector = p:GetPositionOnPath( i )
				b.Direction = g.forward
				b:AddParticipant( self )
				b:GatherParticipants()
				b:Initialize()
				return
			end
		end
		local vec, bDuck = self:FindAdvanceCover( self.vCover, tEnemies )
		if vec then
			if self.vActualCover:DistToSqr( vec ) <= self:BoundingRadius() then return end
			local sched = self:SetSchedule "TakeCoverMove"
			if a < .33 then sched.bTakeCoverAdvance = true else sched.bAdvancing = a > .33 end
			self.vCover = vec
			self.pCover = pCover
			self.bCoverDuck = bDuck
			return true
		end
	else
		local vec, bDuck = self:FindRetreatCover( self.vCover, tEnemies )
		if vec then
			if self.vActualCover:DistToSqr( vec ) <= self:BoundingRadius() then return end
			local sched = self:SetSchedule "TakeCoverMove"
			if a > -.33 then sched.bTakeCoverRetreat = true else sched.bRetreating = a < -.33 end
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
	local tShootables = {}
	for enemy in pairs( tEnemies ) do
		if !IsValid( enemy ) || !HasRangeAttack( enemy ) then continue end
		for _, vec in ipairs( self:CalcEnemyShootPositions( enemy ) ) do
			table.insert( tShootables, { vec, enemy } )
		end
	end
	local c = self:GetWeaponClipPrimary()
	if c != -1 && c <= 0 then self:WeaponReload() end
	if self.vCover then
		local vec = self.vCover
		local tAllies = self:GetAlliesByClass()
		if tAllies then
			local pCover = self.pCover
			for ally in pairs( tAllies ) do
				if self == ally then continue end
				if ally.vActualCover && ally.vActualCover:DistToSqr( vec ) <= self:BoundingRadius() ^ 2 then self.vCover = nil self.pCover = nil self:SetSchedule "TakeCover" return end
			end
		end
		local v = vec + self:GatherCoverBounds()
		local dir = enemy:GetPos() - vec
		dir.z = 0
		dir:Normalize()
		if !util.TraceLine( {
			start = v,
			endpos = v + dir * self.vHullMaxs.x * 4,
			mask = MASK_SHOT_HULL,
			filter = function( ent ) return !( ent:IsPlayer() || ent:IsNPC() || ent:IsNextBot() ) end
		} ).Hit then self.vCover = nil self:SetSchedule "TakeCover" return end
		if sched.bActed == nil then
			if sched.bTakeCoverAdvance then self:DLG_TakeCoverAdvance()
			elseif sched.bTakeCoverRetreat then self:DLG_TakeCoverRetreat()
			elseif sched.bAdvancing then self:DLG_Advancing()
			elseif sched.bRetreating then self:DLG_Retreating() end
			sched.bActed = true
		end
		if !sched.Path then sched.Path = Path "Follow" end
		self:ComputePath( sched.Path, self.vCover )
		if math.abs( sched.Path:GetLength() - sched.Path:GetCursorPosition() ) <= self.flPathGoalTolerance then return { true } end
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
			self:MoveAlongPath( sched.Path, self.flProwlSpeed, 1 )
		else
			local goal = sched.Path:GetCurrentGoal()
			if goal then
				self.vDesAim = ( goal.pos - self:GetPos() ):GetNormalized()
				self:ModifyMoveAimVector( self.vDesAim, self.flTopSpeed, 1 )
			end
			self:MoveAlongPathToCover( sched.Path )
		end
	else return {} end
end )
