DEFINE_BASECLASS "BaseWeapon"

SWEP.Crosshair = "Rifle"
SWEP.sHoldType = "AR2"

SWEP.Primary_flSpreadX = 0
SWEP.Primary_flSpreadY = 0
SWEP.Primary_flDamage = 0
SWEP.Primary_flDelay = 0
SWEP.Primary_iNum = 1
SWEP.Primary_iTracer = 1
SWEP.Primary_sTracer = "Bullet"
// SWEP.Primary_sSound = nil
// SWEP.Primary_sSoundAuto = nil

SWEP.Instructions = "Primary to shoot."

local CEntity, CWeapon = FindMetaTable "Entity", FindMetaTable "Weapon"

local CEntity_GetTable = CEntity.GetTable
local CEntity_GetOwner = CEntity.GetOwner
local CEntity_FireBullets = CEntity.FireBullets
local CEntity_EmitSound = CEntity.EmitSound
local CWeapon_SetHoldType = CWeapon.SetHoldType
local CWeapon_TakePrimaryAmmo = CWeapon.TakePrimaryAmmo
local CWeapon_SetNextPrimaryFire = CWeapon.SetNextPrimaryFire
local Vector = Vector
local PLAYER_ATTACK1 = PLAYER_ATTACK1
local EffectData = EffectData
local util_Effect = util.Effect
local CurTime = CurTime

function SWEP:Initialize() CWeapon_SetHoldType( self, CEntity_GetTable( self ).sHoldType ) end

function SWEP:PrimaryAttack()
	local MyTable = CEntity_GetTable( self )
	if !MyTable.CanPrimaryAttack( self, MyTable ) then return end
	local owner = CEntity_GetOwner( self )
	CEntity_FireBullets( self, {
		Attacker = owner,
		Src = owner:GetShootPos(),
		Dir = MyTable.GetAimVector( self, MyTable ),
		Tracer = MyTable.Primary_iTracer,
		TracerName = MyTable.Primary_sTracer,
		Spread = Vector( MyTable.Primary_flSpreadX, MyTable.Primary_flSpreadY ),
		Damage = MyTable.Primary_flDamage,
		Num = MyTable.Primary_iNum
	} )
	MyTable.ShootEffects( self, MyTable )
	owner:SetAnimation( PLAYER_ATTACK1 ) // CPlayer?
	local ed = EffectData()
	ed:SetEntity( self )
	ed:SetAttachment( 1 )
	ed:SetFlags( 1 )
	util_Effect( "MuzzleFlash", ed )
	local s = MyTable.sSound
	if s then CEntity_EmitSound( self, s ) end
	s = MyTable.sSoundAuto
	if s then CEntity_EmitSound( self, s ) end
	CWeapon_TakePrimaryAmmo( self, 1 )
	CWeapon_SetNextPrimaryFire( self, CurTime() + MyTable.Primary_flDelay )
end

weapons.Register( SWEP, "BaseBulletWeapon" )
