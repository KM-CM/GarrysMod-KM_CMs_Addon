function SWEP:PrimaryAttack() end

function SWEP:Reload()
	self:SetClip1( 0 )
	self:DefaultReload( ACT_VM_RELOAD )
end

function SWEP:AllowsAutoSwitchFrom() return false end
function SWEP:AllowsAutoSwitchTo() return false end

SWEP.Primary_DryFireSound = "Weapon_Pistol.Empty"
SWEP.Secondary_DryFireSound = "Weapon_Pistol.Empty"

function SWEP:CanPrimaryAttack()
	//Believe It or Not, Some People ( Including VALVe ) have The AUDACITY to Ignore This Check!
	if CurTime() <= self:GetNextPrimaryFire() then return end
	if self:Clip1() <= 0 then
		self:EmitSound( self.Primary_DryFireSound )
		self:SetNextPrimaryFire( CurTime() + .2 )
		return
	end
	return true
end

function SWEP:CanSecondaryAttack()
	if CurTime() <= self:GetNextSecondaryFire() then return end
	if self:Clip2() <= 0 then
		self:EmitSound( self.Secondary_DryFireSound )
		self:SetNextSecondaryFire( CurTime() + .2 )
		return
	end
	return true
end

function SWEP:GetNPCBulletSpread() return 0 end
function SWEP:GetNPCBurstSettings() return 0, self:Clip1(), self.Primary.Automatic && 0 || math.Rand( .2, .8 ) end

function SWEP:Deploy() self:BaseWeaponDraw( ACT_VM_DRAW ) self:CallOnClient "ResetZoom" end
function SWEP:Holster() self:CallOnClient "ResetZoom" return true end

function SWEP:BaseWeaponDraw( act )
	local owner = self:GetOwner()
	if !IsValid( owner ) || !owner.GetViewModel then return end
	local vm = self:GetOwner():GetViewModel()
	local s = vm:SelectWeightedSequence( act )
	vm:SendViewModelMatchingSequence( s )
	local t = CurTime() + vm:SequenceDuration( s )
	if t > self:GetNextPrimaryFire() then self:SetNextPrimaryFire( t ) end
	if t > self:GetNextSecondaryFire() then self:SetNextSecondaryFire( t ) end
end

SWEP.BobScale = 0
SWEP.SwayScale = 0

if CLIENT then
	function SWEP:ResetZoom()
		self.flZoom = 0
		self.flSecondaryAttackDefaultZoom = 0
	end
	SWEP.flViewModelX = 0
	SWEP.flViewModelY = 0
	SWEP.flViewModelZ = 0
	SWEP.flViewModelAimX = 0
	SWEP.flViewModelAimY = 0
	SWEP.flViewModelAimZ = 0
	SWEP.flViewModelPitch = 0
	SWEP.flViewModelYaw = 0
	SWEP.flViewModelPitchMin = -5
	SWEP.flViewModelPitchMax = 5
	SWEP.flViewModelYawMin = -5
	SWEP.flViewModelYawMax = 5
	SWEP.flViewModelPitchExagg = 2
	SWEP.flViewModelYawExagg = 2
	SWEP.flViewModelPitchSpeed = 8
	SWEP.flViewModelYawSpeed = 8
	SWEP.flZoom = 0
	SWEP.flZoomSpeedIn = 8
	SWEP.flZoomSpeedOut = 3
	SWEP.flCustomZoomFoV = nil
	SWEP.flMaxZoom = .1 //As Seen in The Literal Line Below, FoV * ( 1 - This * flZoom )
	SWEP.flCurrentFoV = 0
	SWEP.bDontDrawCrosshairDuringZoom = true
	SWEP.flSecondaryAttackDefaultZoom = 0
	SWEP.Crosshair = ""
	local t = math
	local math_min, math_max = t.min, t.max
	local math_AngleDifference = t.AngleDifference
	local math_Approach = t.Approach
	local math_Clamp = t.Clamp
	local math_Round = t.Round
	function SWEP:CalcView( ply, pos, ang, fov ) local f = self.flCustomZoomFoV && math.Remap( self.flZoom, 0, 1, fov, self.flCustomZoomFoV ) || fov * ( 1 - self.flMaxZoom * self.flZoom ) self.flCurrentFoV = f return pos, ang, f end
	function SWEP:AdjustMouseSensitivity()
		local owner = LocalPlayer()
		if IsValid( owner ) then return self.flCurrentFoV / owner:GetFOV() end
	end
	local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable
	function SWEP:CalcViewModelView( vm, opos, oang, pos, ang )
		local MyTable = CEntity_GetTable( self )
		if LocalPlayer():KeyDown( IN_ZOOM ) then
			if MyTable.flZoom < 1 then
				MyTable.flZoom = math_min( MyTable.flZoom + ( 1 - MyTable.flZoom ) * MyTable.flZoomSpeedIn * FrameTime(), 1 )
			end
		else
			if MyTable.flZoom > 0 then
				MyTable.flZoom = math_max( MyTable.flZoom - MyTable.flZoom * MyTable.flZoomSpeedOut * FrameTime(), 0 )
			end
		end
		local flZoom = MyTable.flZoom
		local flZoomInv = 1 - flZoom
		if MyTable.aViewModelLastAng then
			local flDiffPitch, flDiffYaw = math_Clamp( math_Round( math_AngleDifference( MyTable.aViewModelLastAng[ 1 ], ang[ 1 ] ) ) * MyTable.flViewModelPitchExagg, MyTable.flViewModelPitchMin, MyTable.flViewModelPitchMax ), math_Clamp( math_Round( math_AngleDifference( MyTable.aViewModelLastAng[ 2 ], ang[ 2 ] ) ) * MyTable.flViewModelYawExagg, MyTable.flViewModelPitchMin, MyTable.flViewModelPitchMax )
			MyTable.aViewModelLastAng = Angle( ang )
			MyTable.flViewModelPitch = math_Approach( MyTable.flViewModelPitch, flDiffPitch * flZoomInv, MyTable.flViewModelPitchSpeed * FrameTime() )
			MyTable.flViewModelYaw = math_Approach( MyTable.flViewModelYaw, flDiffYaw * flZoomInv, MyTable.flViewModelYawSpeed * FrameTime() )
		else MyTable.aViewModelLastAng = ang end
		ang[ 1 ] = ang[ 1 ] - MyTable.flViewModelPitch
		ang[ 2 ] = ang[ 2 ] - MyTable.flViewModelYaw
		pos = pos + ang:Forward() * ( MyTable.flViewModelAimX * flZoom + MyTable.flViewModelX * flZoomInv ) + ang:Right() * ( MyTable.flViewModelAimY * flZoom + MyTable.flViewModelY * flZoomInv ) + ang:Up() * ( MyTable.flViewModelAimZ * flZoom + MyTable.flViewModelZ * flZoomInv )
		return pos, ang
	end
	include "Crosshair.lua"
end

weapons.Register( SWEP, "BaseWeapon" )

