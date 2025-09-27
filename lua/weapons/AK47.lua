DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Assault Rifles"
SWEP.PrintName = "#AK47"
if CLIENT then language.Add( "AK47", "AK-47" ) end
SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Автомат Калашникова, also known as the AK-47, with the AK standing for its name, and the 47 being the year it was designed in."
SWEP.ViewModel = Model "models/weapons/cstrike/c_rif_ak47.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_rif_ak47.mdl"
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "SMG1"
SWEP.Primary_flDelay = .08571428571
SWEP.Primary_flSpreadX = .0073
SWEP.Primary_flSpreadY = .0073
SWEP.Primary_flDamage = 80
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.vViewModelAim = Vector( -6.61, -12, 3.4 )
SWEP.Crosshair = "Rifle"

// Have to Do This for Technical Reasons
sound.Add {
	name = "AK47_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^AK47Shot.wav"
}
sound.Add {
	name = "AK47_Shot_Auto",
	channel = CHAN_AUTO,
	level = 150,
	pitch = { 90, 110 },
	sound = "^AK47Shot.wav"
}

function SWEP:Initialize() self:SetHoldType "AR2" end

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	local owner = self:GetOwner()
	self:FireBullets {
		Attacker = owner,
		Src = owner:GetShootPos(),
		Dir = owner:GetAimVector(),
		Tracer = 1,
		Spread = Vector( self.Primary_flSpreadX, self.Primary_flSpreadY ),
		Damage = self.Primary_flDamage
	}
	self:ShootEffects()
	owner:SetAnimation( PLAYER_ATTACK1 )
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 1 )
	util.Effect( "MuzzleFlash", ed )
	self:EmitSound "AK47_Shot"
	self:EmitSound "AK47_Shot_Auto"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end

list.Add( "NPCUsableWeapons", { class = "AK47", title = "#AK47", category = SWEP.Category } )
