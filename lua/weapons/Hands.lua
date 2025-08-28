DEFINE_BASECLASS "BaseWeapon"

SWEP.Category = "Hands"
SWEP.PrintName = "#Hands"
if CLIENT then language.Add( "Hands", "Hands" ) end
SWEP.Instructions = ""
SWEP.Purpose = ""
SWEP.ViewModel = Model "models/weapons/c_arms.mdl"
SWEP.UseHands = true
SWEP.WorldModel = Model ""
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Weight = -1
SWEP.Slot = 0
SWEP.DrawAmmo = false
SWEP.Crosshair = ""

local CWeapon_SetHoldType = FindMetaTable( "Weapon" ).SetHoldType
function SWEP:Initialize() CWeapon_SetHoldType( self, "Normal" ) end

local CEntity_Remove = FindMetaTable( "Entity" ).Remove
function SWEP:OnDrop() CEntity_Remove( self ) end
