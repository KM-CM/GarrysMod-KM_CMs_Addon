local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_GetPos = CEntity.GetPos

// ENT.Enemy = NULL
function ENT:SetEnemy( e ) local MyTable = CEntity_GetTable( self ) MyTable.UpdateEnemyMemory( e, CEntity_GetPos( e ), MyTable ) end
function ENT:GetEnemy() return CEntity_GetTable( self ).Enemy end

local IsValid = IsValid

function ENT:SetupEnemy( enemy )
	local ent = enemy
	if ent.__ACTOR_BULLSEYE__ then
		while ent.__ACTOR_BULLSEYE__ && IsValid( ent.Enemy ) do
			ent = ent.Enemy
		end
	end
	return enemy, ent
end

local util_TraceLine = util.TraceLine

local math = math
local math_abs = math.abs
local math_AngleDifference = math.AngleDifference

local table_insert = table.insert

local MASK_VISIBLE_AND_NPCS = MASK_VISIBLE_AND_NPCS

local isentity = isentity

local CEntity_OBBCenter = CEntity.OBBCenter
local CEntity_WaterLevel = CEntity.WaterLevel
local CEntity_GetOwner = CEntity.GetOwner
local CEntity_GetAngles = CEntity.GetAngles

ENT.flLastEnemy = 0

ENT.bCantSeeUnderWater = true
ENT.bVisNot360 = true
ENT.flVisionYaw = 99
ENT.flVisionPitch = 33 // Rougly 99 * ( 6 / 19 ). 31 would be More Exact But 33 Looks Cooler
function ENT:CanSee( vec, MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	local veh, ent
	if isentity( vec ) then
		local TheirTable = CEntity_GetTable( vec )
		veh = TheirTable.GAME_pVehicle
		if MyTable.bCantSeeUnderWater && CEntity_WaterLevel( vec ) == 3 then return end
		ent = vec
		vec = CEntity_GetPos( vec ) + CEntity_OBBCenter( vec )
	end
	if MyTable.bVisNot360 then
		local des, aim = ( vec - MyTable.GetShootPos( self ) ):Angle(), MyTable.aAim || CEntity_GetAngles( self )
		if math_abs( math_AngleDifference( des.y, aim.y ) ) > MyTable.flVisionYaw then return end
		if math_abs( math_AngleDifference( des.p, aim.p ) ) > MyTable.flVisionPitch then return end
	end
	local t = { self }
	if IsValid( ent ) then table_insert( t, ent ) end
	if IsValid( veh ) then table_insert( t, veh ) end
	veh = self.GAME_pVehicle
	if IsValid( veh ) then table_insert( t, veh ) end
	return !util_TraceLine( {
		start = MyTable.GetShootPos( self ),
		endpos = vec,
		mask = MASK_VISIBLE_AND_NPCS,
		filter = t
	} ).Hit
end

ENT.tEnemies = {} // Entity ( Even InValid, will be Filtered ) -> true
ENT.tBullseyes = {} // EntityUniqueIdentifier -> { BaseActorBullseye ( Even InValid ), Source Entity ( Even InValid ), Entity ( Even InValid ) }

// function ENT:UpdateEnemyMemory( enemy, vec ) self:SetupBullseye( enemy, vec, enemy:GetAngles() ) end
function ENT:UpdateEnemyMemory( enemy, vec, ang ) self:SetupBullseye( enemy, vec || enemy:GetPos(), ang || enemy:GetAngles() ) end

local EntityUniqueIdentifier = EntityUniqueIdentifier

function ENT:SetupBullseye( enemy, vec, ang )
	if vec then
		local center = enemy:GetPos() + enemy:OBBCenter()
		if self:CanSee( center ) then vec = center end
	else vec = enemy:GetPos() + enemy:OBBCenter() end
	if !ang then ang = ( enemy.GetAimVector && enemy:GetAimVector() || enemy:GetForward() ):Angle() end
	local ent = enemy
	if ent.__ACTOR_BULLSEYE__ then
		// We Dont want to Create Billions of Bullseyes for Others' Bullseyes so They Create Them for Our Bullseyes and Then Recursion
		// ( Because That is Literally Stupid I have No Idea Why I Clarified That It's Obvious )
		while ent.__ACTOR_BULLSEYE__ && IsValid( ent.Enemy ) do
			ent = ent.Enemy
		end
	end
	local id = EntityUniqueIdentifier( ent )
	local beye = self.tBullseyes[ id ]
	if beye then beye = beye[ 1 ] end
	if !IsValid( beye ) then beye = ents.Create "BaseActorBullseye" beye:Spawn() end
	beye.flTime = CurTime()
	self.tBullseyes[ id ] = { beye, enemy, ent }
	beye.Enemy = ent
	beye.Owner = self
	beye:SetPos( vec )
	beye:SetAngles( ang )
	beye.GAME_BoundMins = ent:OBBMins()
	beye.GAME_BoundMaxs = ent:OBBMaxs()
	if HasRangeAttack( ent ) then
		beye.HAS_RANGE_ATTACK = true
		beye.HAS_NOT_RANGE_ATTACK = nil
	else
		beye.HAS_RANGE_ATTACK = nil
		beye.HAS_NOT_RANGE_ATTACK = true
	end
	if HasMeleeAttack( ent ) then
		beye.HAS_MELEE_ATTACK = true
		beye.HAS_NOT_MELEE_ATTACK = nil
	else
		beye.HAS_MELEE_ATTACK = nil
		beye.HAS_NOT_MELEE_ATTACK = true
	end
	beye:SetHealth( enemy:Health() )
	beye:SetMaxHealth( enemy:GetMaxHealth() )
	return beye
end

local pairs = pairs

function ENT:OnOtherKilled( ent )
	local n, t = EntityUniqueIdentifier( ent ), self:GetAlliesByClass()
	if t then
		for ally in pairs( t ) do
			if !ally.__ACTOR__ then continue end
			local b = ally.tBullseyes
			if b then
				local t = b[ n ]
				if t then
					local v = t[ 1 ]
					if IsValid( v ) then v:Remove() end
					b[ n ] = nil
				end
			end
		end
	end
end

ENT.flMaxVisionRange = 8192

local math_Remap = math.Remap

function ENT:GetVisionStrengthIncreaseSpeed( VecOrEnt, vEyePos )
	if isentity( VecOrEnt ) then VecOrEnt = VecOrEnt:GetPos() + VecOrEnt:OBBCenter() end
	return 3 * math_Remap( vEyePos:Distance( VecOrEnt ), 0, self.flMaxVisionRange, 1, 0 )
end

local HUGE_Z = Vector( 0, 0, 999999 )

local ents_FindInPVS = ents.FindInPVS

local table_Count = table.Count

local math_Rand = math.Rand

local math_Clamp = math.Clamp

local CurTime = CurTime

// If We are in Combat with Multiple Enemies, and We See That There is
// No Enemy at One Position, We can Remove That Bullseye
ENT.bCombatForgetHostiles = true
ENT.flLastLookTime = 0
ENT.flNextLookTime = 0
// If we've seen something, and then it went out of sight, don't delete the info about it yet!
// Instead, decrease the vision strength ofit by this and only delete the info about it when it's zero.
// This way, it's harder for enemies to run away, since every half a second they're re-noticed,
// as opposed to having to wait the whole spot time over and over again when they're a pixel out of sight
//
// NOTE: This does NOT grant the Actors free knowledge! tVisionStrength is only used to determine
// how much we've spotted something, NOT to decide if we can or can't see it.
//
// 1 / Seconds to lose completely
ENT.flLoseSpeed = .2 // 5
ENT.tVisionStrength = {} // Entity ( Even invalid, will be filtered ) -> Float [ 0, 1 ]
local ipairs = ipairs
function ENT:Look( MyTable )
	MyTable = MyTable || CEntity_GetTable( self )
	if CurTime() <= MyTable.flNextLookTime then return end
	MyTable.flNextLookTime = CurTime() + math_Rand( .08, .12 )
	local tVisionStrength = {}
	local tVisibleEnemies = {}
	local iNumEnemies = table_Count( MyTable.tEnemies )
	local tEnemies = {}
	local tOldVisionStrength = MyTable.tVisionStrength
	local flFrameTime = math_abs( CurTime() - MyTable.flLastLookTime )
	local flVisionDistSqr = MyTable.flMaxVisionRange * MyTable.flMaxVisionRange
	local vEyePos = MyTable.GetShootPos( self )
	local tAllies = MyTable.GetAlliesByClass( self )
	for _, ent in ipairs(
		// This is the piece of shit that is necessary but absolutely CONSUMES the CPU!
		// I am 100% sure, and I have tested it.
		// If you add
		// if true then ents_FindInPVS( self ) return end
		// below
		// MyTable.flNextLookTime = CurTime() + math_Rand( .08, .12 )
		// it will not become less CPU consuming than it is already.
		// So sadly, major optimizations cannot be done without making the Actors blinder,
		// and that is not something that I will ever do
		ents_FindInPVS( self )
	) do
		if vEyePos:DistToSqr( CEntity_GetPos( ent ) + CEntity_OBBCenter( ent ) ) > flVisionDistSqr then continue end
		local TheirTable = CEntity_GetTable( ent )
		if !TheirTable.__FLARE_ACTIVE__ && !TheirTable.__ACTOR_BULLSEYE__ && !MyTable.IsHateDisposition( self, ent ) || !MyTable.CanSee( self, ent ) then continue end
		if tOldVisionStrength[ ent ] then
			if ent.__ACTOR_BULLSEYE__ then
				if tAllies && TheirTable.Owner == self then
					local f = tOldVisionStrength[ ent ]
					if f && f >= 1 then
						if iNumEnemies > 1 then
							local p = ent.Enemy
							if IsValid( p ) then
								local v = tOldVisionStrength[ p ]
								if v && v >= 1 then continue end
							end
							local sOwner = EntityUniqueIdentifier( p )
							if sOwner then
								for ent in pairs( tAllies ) do
									local t = ent.tBullseyes
									local p = t[ sOwner ]
									if p then
										p = p[ 1 ]
										if IsValid( p ) then p:Remove() end
									end
									t[ sOwner ] = nil
								end
							end
							ent:Remove()
							iNumEnemies = iNumEnemies - 1
						end
					else tVisionStrength[ ent ] = math.Clamp( f + MyTable.GetVisionStrengthIncreaseSpeed( self, ent, vEyePos ) * flFrameTime, 0, 1 ) end
				end
			elseif ent.__FLARE_ACTIVE__ then
				if ent.Classify then
					if !ent.FLARE_tFoundByClass || !ent.FLARE_tFoundByClass[ self:Classify() ] then
						local f = tOldVisionStrength[ ent ]
						if f && f >= 1 then
							if ent:Classify() == self:Classify() then // Go Over to Ally Flares to Help
								if ent:GetPos():DistToSqr( self:GetPos() ) > 9437184/*3072*/ then
									local p = self:SetupBullseye( ent, util_TraceLine( {
										start = CEntity_GetPos( ent ) + CEntity_OBBCenter( ent ),
										endpos = CEntity_GetPos( ent ) + CEntity_OBBCenter( ent ) - HUGE_Z,
										filter = ent,
										mask = MASK_VISIBLE_AND_NPCS
									} ).HitPos, CEntity_GetAngles( ent ) )
									if IsValid( p ) then p.flTime = CurTime() end
								end
							else
								local p = CEntity_GetOwner( ent )
								if IsValid( p ) then
									local p = self:SetupBullseye( p, util_TraceLine( {
										start = CEntity_GetPos( ent ) + CEntity_OBBCenter( ent ),
										endpos = CEntity_GetPos( ent ) + CEntity_OBBCenter( ent ) - HUGE_Z,
										filter = ent,
										mask = MASK_VISIBLE_AND_NPCS
									} ).HitPos, CEntity_GetAngles( ent ) )
									if IsValid( p ) then p.flTime = CurTime() end
								end
							end
							if ent.FLARE_tFoundByClass then ent.FLARE_tFoundByClass[ self:Classify() ] = true
							else ent.FLARE_tFoundByClass = { [ self:Classify() ] = true } end
						else tVisionStrength[ ent ] = math_Clamp( tOldVisionStrength[ ent ] + MyTable.GetVisionStrengthIncreaseSpeed( self, ent, vEyePos ) * flFrameTime, 0, 1 ) end
					end
				end
			else
				tVisionStrength[ ent ] = math_Clamp( tOldVisionStrength[ ent ] + MyTable.GetVisionStrengthIncreaseSpeed( self, ent, vEyePos ) * flFrameTime, 0, 1 )
				if tVisionStrength[ ent ] >= 1 then
					self.bHoldFire = nil
					self.flLastEnemy = CurTime()
					tEnemies[ ent ] = true
					tVisibleEnemies[ EntityUniqueIdentifier( ent ) ] = true
					self:SetupBullseye( ent )
				end
			end
		else tVisionStrength[ ent ] = 0 end
	end
	local f = MyTable.flLoseSpeed
	for ent, flt in pairs( tOldVisionStrength ) do
		if !IsValid( ent ) || flt <= 0 || tVisionStrength[ ent ] then continue end
		tVisionStrength[ ent ] = flt - f * FrameTime()
	end
	local tBullseyes = {}
	for id, data in pairs( MyTable.tBullseyes ) do
		local ent = data[ 1 ]
		if !IsValid( ent ) then continue end
		tBullseyes[ id ] = data
		if tVisibleEnemies[ id ] then continue end
		tEnemies[ ent ] = true
	end
	MyTable.tBullseyes = tBullseyes
	local ned, ne = math.huge
	for ent in pairs( MyTable.tEnemies ) do
		if !IsValid( ent ) then continue end
		local d = ( CEntity_GetPos( ent ) + CEntity_OBBCenter( ent ) ):DistToSqr( vEyePos )
		if d >= ned then continue end
		ne, ned = ent, d
	end
	MyTable.Enemy = ne
	MyTable.tEnemies = tEnemies
	MyTable.flLastLookTime = CurTime()
	MyTable.tVisionStrength = tVisionStrength
end

function ENT:OnHeardSomething( Other, Data )
	local MyTable = CEntity_GetTable( self )
	local d = MyTable.Disposition( self, Other, MyTable )
	if d == D_LI then
		local OtherTable = CEntity_GetTable( Other )
		if !OtherTable.__ACTOR__ then return end
		if !OtherTable.bHoldFire then MyTable.bHoldFire = nil end
		for k, d in pairs( OtherTable.tBullseyes ) do
			local beye = d[ 1 ]
			if IsValid( beye ) then
				local ent = d[ 2 ]
				if IsValid( ent ) then
					local t = self.tBullseyes[ k ]
					if t then
						local meye = t[ 1 ]
						if IsValid( meye ) && meye.flTime > beye.flTime then
							OtherTable.SetupBullseye( Other, ent, CEntity_GetPos( meye ), CEntity_GetAngles( meye ), OtherTable )
						else MyTable.SetupBullseye( self, ent, CEntity_GetPos( beye ), CEntity_GetAngles( beye ), MyTable ) end
					else
						MyTable.SetupBullseye( self, ent, CEntity_GetPos( beye ), CEntity_GetAngles( beye ), MyTable )
					end
				end
			end
		end
	elseif d == D_HT || d == D_FR then
		MyTable.SetupBullseye( self, Other, nil, nil, MyTable )
	end
end
