DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Pistols"
SWEP.PrintName = "#weapon_pistol"
if CLIENT then language.Add( "weapon_pistol", "USP Match" ) end
SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Universal Self-Loading Pistol, Match Variant."
SWEP.ViewModel = Model "models/weapons/c_pistol.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_pistol.mdl"
SWEP.Primary.ClipSize = 15
SWEP.Primary.DefaultClip = 15
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "Pistol"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 1

SWEP.flViewModelAimX = -12
SWEP.flViewModelAimY = -5.52
SWEP.flViewModelAimZ = 3.15

sound.Add {
	name = "USP_Match_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "^HKP2000Shot.wav"
}

function SWEP:Initialize() self:SetHoldType "Pistol" end

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	local owner = self:GetOwner()
	self:FireBullets {
		Attacker = owner,
		Src = owner:GetShootPos(),
		Dir = owner:GetAimVector(),
		Tracer = 1,
		Spread = Vector( .017, .017 ),
		Damage = 60
	}
	self:ShootEffects()
	owner:SetAnimation( PLAYER_ATTACK1 )
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 1 )
	util.Effect( "MuzzleFlash", ed )
	self:EmitSound "USP_Match_Shot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + .08571428571 )
end
