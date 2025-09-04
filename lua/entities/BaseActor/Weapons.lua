//ENT.Weapon = NULL
ENT.tWeapons = {}

function ENT:GetActiveWeapon() return self.Weapon end
//See Lower for SetActiveWeapon

function ENT:GetWeapons()
	local t = {}
	for wep in pairs( self.tWeapons ) do table.insert( t, wep ) end
	return t
end

function ENT:IsWeaponActive() return IsValid( self.Weapon ) end
function ENT:HasWeapon() return !table.IsEmpty( self.tWeapons ) end //HasWeapon(s)

function ENT:Give( sWeaponClass )
	local wep = ents.Create( sWeaponClass )
	if !IsValid( wep ) then return NULL end
	if !wep:IsScripted() then wep:Remove() return NULL end
	wep:SetPos( self:GetPos() )
	wep:SetOwner( self )
	wep:Spawn()
	wep:Activate()
	hook.Run( "WeaponEquip", self, wep )
	return self:SetActiveWeapon( wep )
end

function ENT:SetActiveWeapon( wep )
	if !IsValid( wep ) || !wep:IsScripted() then return end
	local awep = self.Weapon
	if IsValid( awep ) then awep:SetNoDraw( true ) end
	self.Weapon = wep
	wep:SetNoDraw( false )
	wep:SetWeaponHoldType( wep:GetHoldType() )
	wep:SetVelocity( vector_origin )
	wep:RemoveSolidFlags( FSOLID_TRIGGER )
	wep:SetOwner( self )
	wep:RemoveEffects( EF_ITEM_BLINK )
	wep:PhysicsDestroy()
	wep:SetParent( self )
	wep:SetMoveType( MOVETYPE_NONE )
	wep:AddEffects( EF_BONEMERGE )
	wep:AddSolidFlags( FSOLID_NOT_SOLID )
	wep:SetLocalPos( vector_origin )
	wep:SetLocalAngles( angle_zero )
	wep:SetTransmitWithParent( true )
	self.tWeapons[ wep ] = true
	return wep
end

function ENT:DropWeapon( wep, Velocity )
	local wep = wep == nil && self:GetActiveWeapon() || wep
	if !IsValid( wep ) then return end
	if Velocity == nil then Velocity = Velocity || self:EyeAngles():Forward() * 400 end
	wep:SetNoDraw( false )
	wep:SetParent()
	wep:RemoveEffects( EF_BONEMERGE )
	wep:RemoveSolidFlags( FSOLID_NOT_SOLID )
	wep:CollisionRulesChanged()
	wep:SetOwner( NULL )
	wep:SetMoveType( MOVETYPE_FLYGRAVITY )
	local SF = wep:GetSolidFlags()
	if wep:PhysicsInit( SOLID_VPHYSICS ) then
		wep:SetMoveType( MOVETYPE_VPHYSICS )
		wep:PhysWake()
	else
		wep:SetSolid( SOLID_BBOX )
	end
	wep:SetSolidFlags( bit.bor( SF, FSOLID_TRIGGER ) )
	wep:SetTransmitWithParent( false )
	ProtectedCall( function() wep:OwnerChanged() end )
	ProtectedCall( function() wep:OnDrop() end )
	wep:SetPos( self:GetShootPos() )
	wep:SetAngles( self:EyeAngles() )
	local phys = wep:GetPhysicsObject()
	if IsValid( phys ) then
		phys:AddVelocity( Velocity )
		phys:AddAngleVelocity( Vector( 200, 200, 200 ) )
	else
		wep:SetVelocity( Velocity )
	end
	self.tWeapons[ wep ] = nil
	hook.Run( "PlayerDroppedWeapon", self, wep )
	return wep
end

function ENT:TranslateWeaponActivity( act )
	local wep = self.Weapon
	if !IsValid( wep ) then return act end
	ProtectedCall( function() act = wep:TranslateActivity( act ) end )
	return act
end

function ENT:DoReloadGesture()
	local act = self:TranslateActivity( self:Crouching() && ACT_MP_RELOAD_CROUCH || ACT_MP_RELOAD_STAND )
	local seq = self:SelectWeightedSequence( act )
	self:AddGesture( act )
	return self:SequenceDuration( seq )
end

ENT.flWeaponReloadTime = 0
function ENT:WeaponReload()
	local wep = self.Weapon
	if !IsValid( wep ) || CurTime() <= self.flWeaponReloadTime then return end
	wep:SetClip1( 0 )
	local t = self:DoReloadGesture()
	self.flWeaponReloadTime = CurTime() + t
	timer.Simple( t, function()
		if IsValid( wep ) && IsValid( self ) && self.tWeapons && self.tWeapons[ wep ] then
			wep:SetClip1( wep:GetMaxClip1() )
		end
	end )
end

function ENT:WeaponPrimaryAttack()
	local wep = self.Weapon
	if CurTime() <= wep:GetNextPrimaryFire() then return end
	wep:PrimaryAttack()
	return true
end

ENT.flWeaponPrimaryVolleyTime = 0
ENT.flWeaponPrimaryVolleyTimeNext = 0
ENT.tWeaponPrimaryVolleyTimes = { 0, 3 }
ENT.tWeaponPrimaryVolleyBreaks = { .33, .66 }
ENT.tWeaponPrimaryVolleyNonAutomaticDelay = { 0, .4 }
ENT.flWeaponPrimaryVolleyNonAutomaticDelay = 0
function ENT:WeaponPrimaryVolley()
	if CurTime() > self.flWeaponPrimaryVolleyTimeNext then
		local t = CurTime() + math.Rand( unpack( self.tWeaponPrimaryVolleyTimes ) )
		self.flWeaponPrimaryVolleyTime = t
		self.flWeaponPrimaryVolleyTimeNext = t + math.Rand( unpack( self.tWeaponPrimaryVolleyBreaks ) )
	end
	if CurTime() <= self.flWeaponPrimaryVolleyTime && CurTime() > self.flWeaponPrimaryVolleyNonAutomaticDelay && self:WeaponPrimaryAttack() then
		local wep = self.Weapon
		if IsValid( wep ) then
			local p = wep.Primary
			if p && !p.Automatic then self.flWeaponPrimaryVolleyNonAutomaticDelay = CurTime() + math.Rand( unpack( self.tWeaponPrimaryVolleyNonAutomaticDelay ) ) end
		end
	end
end

function ENT:GetWeaponClipPrimary() if IsValid( self.Weapon ) then return self.Weapon:Clip1() else return -1 end end
function ENT:GetWeaponClipSizePrimary() if IsValid( self.Weapon ) then return self.Weapon:GetMaxClip1() else return -1 end end

function ENT:CanAttackHelper( vec )
	if self:GetWeaponClipPrimary() <= 0 then return end
	local tr = util.TraceLine {
		start = self:GetShootPos(),
		endpos = self:GetShootPos() + self:GetAimVector() * 999999,
		mask = MASK_SHOT_HULL,
		filter = self
	}
	if IsValid( tr.Entity ) && self:Disposition( tr.Entity ) == D_LI then return end
	if vec then
		local ang, aim = ( vec - self:GetShootPos() ):Angle(), self:GetAimVector():Angle()
		if math.abs( math.AngleDifference( ang.y, aim.y ) ) > 1 || math.abs( math.AngleDifference( ang.p, aim.p ) ) > 1 then return end
	end
	return true
end
