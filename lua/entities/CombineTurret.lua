// TODO: Find a way to make the weapon NOT stuck in the turret's ass,
// 'cause that looks very silly, and is supposed to be on top... I guess?
// The original Half-Life 2 turrets had a gun built-in, which's what made 'em unoriginal,
// these ones don't, so I think putting the weapons in the barrel place is a good idea

AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "CombineTurret" )
scripted_ents.Alias( "npc_turret_floor", "CombineTurret" )

ENT.CATEGORIZE = {
	Combine = true,
	Turret = true
}

sound.Add {
	name = "Combine_Turret_HoldFire",
	channel = CHAN_STATIC,
	level = 150,
	pitch = 100,
	sound = "npc/turret_floor/active.wav"
}

sound.Add {
	name = "Combine_Turret_Explode",
	channel = CHAN_AUTO,
	level = 150,
	pitch = 100,
	sound = "npc/turret_floor/die.wav"
}

list.Set( "NPC", "npc_turret_floor", {
	Name = "#CombineTurret",
	Class = "CombineTurret",
	Category = "Combine"
} )

if !SERVER then return end

ENT.bPhysics = true

ENT.bCantTurnBody = true

ENT.bCombatForgetLastHostile = true

local CEntity_EmitSound = FindMetaTable( "Entity" ).EmitSound

function ENT:DLG_FiringAtAnExposedTarget() CEntity_EmitSound( self, "Combine_Soldier_FiringAtAnExposedTarget" ) end
function ENT:DLG_Advancing() CEntity_EmitSound( self, "Combine_Soldier_Advancing" ) end
function ENT:DLG_Retreating() CEntity_EmitSound( self, "Combine_Soldier_Retreating" ) end
function ENT:DLG_TakeCoverGeneral() CEntity_EmitSound( self, "Combine_Soldier_TakeCover" ) end
function ENT:DLG_HoldFire() CEntity_EmitSound( self, "Combine_Soldier_HoldFire" ) BaseClass.DLG_HoldFire( self ) end

ENT.iDefaultClass = CLASS_COMBINE

function ENT:SelectSchedule() end

function ENT:GetShootPos() return self:GetBonePosition( 3 ) end

function ENT:DoReloadGesture() return 1 end

function ENT:RangeAttack()
	if self.bHoldFire then return end
	self:WeaponPrimaryAttack() // NOT WeaponPrimaryVolley!
end

function ENT:Behaviour()
	if IsValid( self.Enemy ) then
		local tNearestEnemies = {}
		for ent in pairs( tEnemies ) do if IsValid( ent ) then table.insert( tNearestEnemies, { ent, ent:GetPos():DistToSqr( self:GetPos() ) } ) end end
		table.SortByMember( tNearestEnemies, 2, true )
		local tAllies, pEnemy = self:GetAlliesByClass()
		for _, d in ipairs( tNearestEnemies ) do
			local pEnemy = d[ 1 ]
			local v = pEnemy:GetPos() + pEnemy:OBBCenter()
			self.vDesAim = ( v - self:GetShootPos() ):GetNormalized()
			local c = self:GetWeaponClipPrimary()
			if c != -1 && c <= 0 then self:WeaponReload() return end
			if !self:CanAttackHelper( v ) then return end
			if util.TraceLine( {
				start = self:GetShootPos(),
				endpos = v,
				filter = self,
				mask = MASK_SHOT_HULL
			} ).Fraction <= self.flSuppressionTraceFraction then return end
			self:RangeAttack()
			return
		end
	else
		self.vDesAim = self:GetForward()
		local c = self:GetWeaponClipPrimary()
		if c != -1 && c <= 0 then self:WeaponReload() return end
	end
end

function ENT:Initialize()
	self:SetModel "models/combine_turrets/floor_turret.mdl"
	self:SetHealth( 2048 )
	self:SetMaxHealth( 2048 )
	self:SetBloodColor( BLOOD_COLOR_MECH )
	self:SetUseType( SIMPLE_USE )
	self:PhysicsInit( SOLID_VPHYSICS )
	local pPhys = self:GetPhysicsObject()
	if IsValid( pPhys ) then pPhys:SetDamping( 0, 24 ) end
	BaseClass.Initialize( self )
end

function ENT:Use( _, pCaller )
	local pWeapon = self.Weapon
	if IsValid( pWeapon ) then
		local f = pCaller.PickupWeapon
		if !f then return end
		self:DropWeapon()
		f( pCaller, pWeapon )
		local f = pCaller.SelectWeapon
		if !f then return end
		f( pCaller, pWeapon )
	else
		local f = pCaller.GetActiveWeapon
		if !f then return end
		pWeapon = f( pCaller )
		f = pCaller.DropWeapon
		if !f then return end
		f( pCaller, pWeapon )
		self:SetActiveWeapon( pWeapon )
	end
end

function ENT:OnKilled( ... )
	if BaseClass.OnKilled( self, ... ) then return end
	CEntity_EmitSound( self, "Combine_Turret_Explode" )
	self:Remove()
end
