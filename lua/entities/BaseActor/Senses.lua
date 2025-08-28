//ENT.Enemy = NULL
function ENT:SetEnemy( e ) self:UpdateEnemyMemory( e, e:GetPos() ) end
function ENT:GetEnemy() return self.Enemy end

function ENT:SetupEnemy( enemy )
	local ent = enemy
	if ent.__ACTOR_BULLSEYE__ then
		while ent.__ACTOR_BULLSEYE__ && IsValid( ent.Enemy ) do
			ent = ent.Enemy
		end
	end
	return enemy, ent
end

ENT.bCantSeeUnderWater = true
ENT.bVisNot360 = true
ENT.flVisionYaw = 99
ENT.flVisionPitch = 33 //Rougly 99 * ( 6 / 19 ). 31 would be More Exact But 33 Looks Cooler
function ENT:CanSee( vec )
	local veh, ent
	if isentity( vec ) then
		veh = vec.GAME_pVehicle
		if self.bCantSeeUnderWater && vec:WaterLevel() == 3 then return end
		ent = vec
		vec = vec:GetPos() + vec:OBBCenter()
	end
	if self.bVisNot360 then
		local des, aim = ( vec - self:EyePos() ):Angle(), self:EyeAngles()
		if math.abs( math.AngleDifference( des.y, aim.y ) ) > self.flVisionYaw then return end
		if math.abs( math.AngleDifference( des.p, aim.p ) ) > self.flVisionPitch then return end
	end
	local t = { self }
	if IsValid( ent ) then table.insert( t, ent ) end
	if IsValid( veh ) then table.insert( t, veh ) end
	veh = self.GAME_pVehicle
	if IsValid( veh ) then table.insert( t, veh ) end
	return !util.TraceLine( {
		start = self:EyePos(),
		endpos = vec,
		mask = MASK_VISIBLE_AND_NPCS,
		filter = t
	} ).Hit
end

ENT.tEnemies = {} //Entity ( Even InValid, will be Filtered ) -> true
ENT.tBullseyes = {} //EntityUniqueIdentifier -> { BaseActorBullseye ( Even InValid ), Source Entity ( Even InValid ), Entity ( Even InValid ) }

//function ENT:UpdateEnemyMemory( enemy, vec ) self:SetupBullseye( enemy, vec, enemy:GetAngles() ) end
function ENT:UpdateEnemyMemory( enemy, vec, ang ) self:SetupBullseye( enemy, vec || enemy:GetPos(), ang || enemy:GetAngles() ) end

function ENT:SetupBullseye( enemy, vec, ang )
	if vec then
		local center = enemy:GetPos() + enemy:OBBCenter()
		if self:CanSee( center ) then vec = center end
	else vec = enemy:GetPos() + enemy:OBBCenter() end
	if !ang then ang = ( enemy.GetAimVector && enemy:GetAimVector() || enemy:GetForward() ):Angle() end
	local ent = enemy
	if ent.__ACTOR_BULLSEYE__ then
		//We Dont want to Create Billions of Bullseyes for Others' Bullseyes so They Create Them for Our Bullseyes and Then Recursion
		//( Because That is Literally Stupid I have No Idea Why I Clarified That It's Obvious )
		while ent.__ACTOR_BULLSEYE__ && IsValid( ent.Enemy ) do
			ent = ent.Enemy
		end
	end
	local id = EntityUniqueIdentifier( ent )
	local beye = self.tBullseyes[ id ]
	if beye then beye = beye[ 1 ] end
	if !IsValid( beye ) then beye = ents.Create "BaseActorBullseye" beye:Spawn() end
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
end

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

ENT.flMaxVisionRange = 9000

function ENT:GetVisionStrengthIncreaseSpeed( VecOrEnt )
	if isentity( VecOrEnt ) then VecOrEnt = VecOrEnt:GetPos() + VecOrEnt:OBBCenter() end
	return 3 * math.Remap( self:GetPos():Distance( VecOrEnt ), 0, self.flMaxVisionRange, 1, 0 )
end

local util_TraceLine = util.TraceLine
local HUGE_Z = Vector( 0, 0, 999999 )

ENT.flLastLookTime = 0
ENT.flNextLookTime = 0
/*If We've Seen Something, and Then It went Out of Sight, Dont Delete It Yet!
Instead, Decrease The Vision Strength of It by This and Only Delete It when It's Zero.
This Way, It's Harder for Enemies to Run Away, Since Every Half a Second They're Re-Noticed,
as Opposed to having to Wait The Whole Spot Time Over and Over Again when They're a Pixel Out of LoS

NOTE: This Does NOT Grant The Actors Free Knowledge! tVisionStrength is Only Used to Determine
How Much We've Spotted Something, NOT to Decide if We can or cant See Something.

The Formula is 1 / SecondsToLoseCompletely*/
ENT.flLoseSpeed = .2 //5
ENT.tVisionStrength = {} //Entity ( Even InValid, will be Filtered ) -> Float [ 0, 1 ]
function ENT:Look()
	if CurTime() <= self.flNextLookTime then return end
	self.flNextLookTime = CurTime() + math.Rand( .08, .12 )
	local tVisionStrength = {}
	local tVisibleEnemies = {}
	local tEnemies = {}
	local tOldVisionStrength = self.tVisionStrength
	local flFrameTime = math.abs( CurTime() - self.flLastLookTime )
	local flVisionDistSqr = self.flMaxVisionRange * self.flMaxVisionRange
	local vEyePos = self:EyePos()
	for _, ent in ipairs( ents.FindInPVS( self ) ) do
		if vEyePos:DistToSqr( ent:GetPos() + ent:OBBCenter() ) > flVisionDistSqr then continue end
		if !ent.__FLARE_ACTIVE__ && !self:IsHateDisposition( ent ) || !self:CanSee( ent ) then continue end
		if tOldVisionStrength[ ent ] then
			if ent.__FLARE_ACTIVE__ then
				if ent.Classify then
					if !ent.FLARE_tFoundByClass || !ent.FLARE_tFoundByClass[ self:Classify() ] then
						local f = tOldVisionStrength[ ent ]
						if f && f >= 1 then
							if ent:Classify() == self:Classify() then //Go Over to Ally Flares to Help
								if ent:GetPos():DistToSqr( self:GetPos() ) > 9437184/*3072*/ then
									self:SetupBullseye( ent, util_TraceLine( {
										start = ent:GetPos() + ent:OBBCenter(),
										endpos = ent:GetPos() + ent:OBBCenter() - HUGE_Z,
										filter = ent,
										mask = MASK_VISIBLE_AND_NPCS
									} ).HitPos, ent:GetAngles() )
								end
							else
								local p = ent:GetOwner()
								if IsValid( p ) then
									self:SetupBullseye( p, util_TraceLine( {
										start = ent:GetPos() + ent:OBBCenter(),
										endpos = ent:GetPos() + ent:OBBCenter() - HUGE_Z,
										filter = ent,
										mask = MASK_VISIBLE_AND_NPCS
									} ).HitPos, ent:GetAngles() )
								end
							end
							if ent.FLARE_tFoundByClass then ent.FLARE_tFoundByClass[ self:Classify() ] = true
							else ent.FLARE_tFoundByClass = { [ self:Classify() ] = true } end
						else
							if ent:Classify() == self:Classify() then
								tVisionStrength[ ent ] = math.Clamp( tOldVisionStrength[ ent ] + self:GetVisionStrengthIncreaseSpeed( ent ) * .33 * flFrameTime, 0, 1 )
							else
								tVisionStrength[ ent ] = math.Clamp( tOldVisionStrength[ ent ] + self:GetVisionStrengthIncreaseSpeed( ent ) * flFrameTime, 0, 1 )
							end
						end
					end
				end
			else
				tVisionStrength[ ent ] = math.Clamp( tOldVisionStrength[ ent ] + self:GetVisionStrengthIncreaseSpeed( ent ) * flFrameTime, 0, 1 )
				if tVisionStrength[ ent ] >= 1 then
					tEnemies[ ent ] = true
					tVisibleEnemies[ EntityUniqueIdentifier( ent ) ] = true
					self:SetupBullseye( ent )
				end
			end
		else tVisionStrength[ ent ] = 0 end
	end
	local f = self.flLoseSpeed
	for ent, flt in pairs( tOldVisionStrength ) do
		if !IsValid( ent ) || flt <= 0 || tVisionStrength[ ent ] then continue end
		tVisionStrength[ ent ] = flt - f * FrameTime()
	end
	local tBullseyes = {}
	for id, data in pairs( self.tBullseyes ) do
		local ent = data[ 1 ]
		if !IsValid( ent ) then continue end
		tBullseyes[ id ] = data
		if tVisibleEnemies[ id ] then continue end
		tEnemies[ ent ] = true
	end
	self.tBullseyes = tBullseyes
	local ned, ne = math.huge
	for ent in pairs( self.tEnemies ) do
		if !IsValid( ent ) then continue end
		local d = ent:GetPos():DistToSqr( self:GetPos() )
		if d >= ned then continue end
		ne, ned = ent, d
	end
	self.Enemy = ne
	self.tEnemies = tEnemies
	self.flLastLookTime = CurTime()
	self.tVisionStrength = tVisionStrength
end

function ENT:OnHeardSomething( Other, Data )
	local d = self:Disposition( Other )
	if d == D_LI && Other.__ACTOR__ then
		for _, d in pairs( Other.tBullseyes ) do
			local beye = d[ 1 ]
			if IsValid( beye ) then
				local ent = d[ 2 ]
				if IsValid( ent ) then
					self:SetupBullseye( ent, beye:GetPos(), beye:GetAngles() )
				end
			end
		end
	elseif d == D_HT || d == D_FR then
		self:SetupBullseye( Other )
	end
end
