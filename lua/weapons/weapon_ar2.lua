DEFINE_BASECLASS "BaseWeapon"

if SERVER then ACHIEVEMENT_ACQUIRE "weapon_ar2" end

SWEP.Category = "Assault Rifles"
SWEP.PrintName = "#weapon_ar2"
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
		Dir = self:GetAimVector(),
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

local EffectData = EffectData
local util_Effect = util.Effect
function SWEP:DoImpactEffect( tr, dt )
	if tr.HitSky then return end
	local p = EffectData()
	local d = tr.HitNormal
	p:SetOrigin( tr.HitPos + d )
	p:SetNormal( d )
	util_Effect( "AR2Impact", p ) 
end
