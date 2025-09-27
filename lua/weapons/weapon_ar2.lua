DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Assault Rifles"
SWEP.PrintName = "#weapon_ar2"
if CLIENT then language.Add( "weapon_ar2", "OSIPR" ) end
SWEP.Instructions = "Primary to shoot."
SWEP.Purpose = "Overwatch Standard Issue Pulse Rifle."
SWEP.ViewModel = Model "models/weapons/c_irifle.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_irifle.mdl"
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "AR2"
SWEP.Primary_flSpreadX = .0037
SWEP.Primary_flSpreadY = .0037
SWEP.Primary_flDamage = 80
SWEP.Primary_flDelay = .07
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = 1
SWEP.Slot = 2
SWEP.DrawAmmo = true
SWEP.vViewModelAim = Vector( -5.82, -8, 1.255 )
SWEP.Crosshair = "Rifle"
SWEP.ViewModelFOV = 62

sound.Add {
	name = "OSIPR_Shot",
	channel = CHAN_WEAPON,
	level = 150,
	pitch = { 90, 110 },
	sound = "weapons/ar2/fire1.wav"
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
		TracerName = "AR2Tracer",
		Spread = Vector( self.Primary_flSpreadX, self.Primary_flSpreadY ),
		Damage = self.Primary_flDamage
	}
	self:ShootEffects()
	owner:SetAnimation( PLAYER_ATTACK1 )
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 5 )
	util.Effect( "MuzzleFlash", ed )
	self:EmitSound "OSIPR_Shot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end

function SWEP:DoImpactEffect( tr, dt )
	if tr.HitSky then return end
	local ed = EffectData()
	ed:SetOrigin( tr.HitPos + tr.HitNormal )
	ed:SetNormal( tr.HitNormal )
	util.Effect( "AR2Impact", ed ) 
end
