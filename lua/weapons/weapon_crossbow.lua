DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Crossbows"
SWEP.PrintName = "#weapon_crossbow"
SWEP.Instructions = "Primary to shoot, secondary + mouse forward/backward to zoom in/out."
SWEP.Purpose = "A Resistance crossbow."
SWEP.ViewModel = Model "models/weapons/c_crossbow.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model "models/weapons/w_crossbow.mdl"
SWEP.Primary.ClipSize = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "XBowBolt"
SWEP.Primary_flSpreadX = 0
SWEP.Primary_flSpreadY = 0
SWEP.Primary_flDamage = 140
SWEP.Primary_flDelay = .1
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = ""
SWEP.Spawnable = true
SWEP.Slot = 3
SWEP.vViewModelAim = Vector( -7.97, -13.74, 2.05 )
SWEP.Crosshair = "Sniper"
SWEP.vSprintArm = Vector( 1.358, -6.228, -.94 )
SWEP.sDryFire = ""
SWEP.bSniper = true
SWEP.flZoomFoVMin = 8.25
SWEP.flZoomFoVMax = 1.98
SWEP.flCustomZoomFoV = SWEP.flZoomFoVMin

function SWEP:FreezeMovement()
	local owner = self:GetOwner()
	if owner:KeyDown( IN_ZOOM ) && ( owner:KeyDown( IN_ATTACK2 ) || owner:KeyReleased( IN_ATTACK2 ) ) then return true end
end

function SWEP:SetCustomZoomFoV( v ) self.flCustomZoomFoV = tonumber( v ) end

function SWEP:Tick()
	local owner = self:GetOwner()
	if CLIENT && owner != LocalPlayer() then return end
	local cmd = owner:GetCurrentCommand()
	if !cmd:KeyDown( IN_ATTACK2 ) || !cmd:KeyDown( IN_ZOOM ) then return end
	self.flCustomZoomFoV = math.Clamp( self.flCustomZoomFoV + cmd:GetMouseY() * FrameTime() * 6.6, self.flZoomFoVMax, self.flZoomFoVMin )
	self:CallOnClient( "SetCustomZoomFoV", self.flCustomZoomFoV )
end

sound.Add {
	name = "CrossbowShot",
	channel = CHAN_WEAPON,
	level = 90,
	pitch = { 90, 110 },
	sound = "weapons/crossbow/fire1.wav"
}

sound.Add {
	name = "CrossbowLoad",
	channel = CHAN_WEAPON,
	level = 90,
	pitch = { 90, 110 },
	sound = {
		"weapons/crossbow/bolt_load1.wav",
		"weapons/crossbow/bolt_load2.wav"
	}
}

function SWEP:Initialize() self:SetHoldType "Crossbow" end

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	local owner = self:GetOwner()
	self:ShootEffects()
	owner:SetAnimation( PLAYER_ATTACK1 )
	self:EmitSound "CrossbowShot"
	self:TakePrimaryAmmo( 1 )
	self:SetNextPrimaryFire( CurTime() + self.Primary_flDelay )
end

function SWEP:Reload()
	if self:Clip1() > 0 then return end
	if self:DefaultReload( ACT_VM_RELOAD ) then
		timer.Simple( .9, function()
			if !IsValid( self ) then return end
			self:EmitSound "CrossbowLoad"
		end )
	end
end
