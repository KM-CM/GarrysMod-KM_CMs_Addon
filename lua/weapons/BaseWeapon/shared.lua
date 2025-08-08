function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end

function SWEP:Reload()
	self:SetClip1( 0 )
	self:DefaultReload( ACT_VM_RELOAD )
end

function SWEP:AllowsAutoSwitchFrom() return false end
function SWEP:AllowsAutoSwitchTo() return false end

SWEP.Primary_DryFireSound = "Weapon_Pistol.Empty"
SWEP.Secondary_DryFireSound = "Weapon_Pistol.Empty"

local CEntity = FindMetaTable "Entity"
local CEntity_GetOwner = CEntity.GetOwner
SWEP.bDisAllowPrimaryInCover = true
function SWEP:CanPrimaryAttack()
	//Believe It or Not, Some People ( Including VALVe ) have The AUDACITY to Ignore This Check!
	if CurTime() <= self:GetNextPrimaryFire() then return end
	local owner = CEntity_GetOwner( self )
	if CurTime() <= ( owner.CTRL_flCoverDontShootTime || 0 ) then return end
	if self.bDisAllowPrimaryInCover then
		if IsValid( owner ) && owner.CTRL_bInCover then return end
	end
	if self:Clip1() <= 0 then
		self:EmitSound( self.Primary_DryFireSound )
		self:SetNextPrimaryFire( CurTime() + .2 )
		return
	end
	return true
end

SWEP.bDisAllowSecondaryInCover = false
function SWEP:CanSecondaryAttack()
	if CurTime() <= self:GetNextSecondaryFire() then return end
	local owner = CEntity_GetOwner( self )
	if CurTime() <= ( owner.CTRL_flCoverDontShootTime || 0 ) then return end
	if self.bDisAllowSecondaryInCover then
		if IsValid( owner ) && owner.CTRL_bInCover then return end
	end
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
	local CEntity_GetTable = CEntity.GetTable
	function SWEP:ResetZoom()
		local MyTable = CEntity_GetTable( self )
		MyTable.flZoom = 0
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
	//These Use flZoomSpeedIn for Both In and Out
	SWEP.flCover = 0
	SWEP.flCoverBlindFireUp = 0
	SWEP.flCoverBlindFireUpY = 14
	SWEP.flCoverBlindFireLeft = 0
	SWEP.flCoverBlindFireRight = 0
	SWEP.flCoverBlindFireLeftZ = -4
	SWEP.flCoverBlindFireRightZ = -8
	SWEP.flCoverVariantsCenter = 0
	SWEP.flCoverVariantsCenterY = -4
	SWEP.flCoverVariantsRight = 0
	SWEP.flCoverVariantsRightY = 2
	SWEP.flCoverVariantsLeft = 0
	SWEP.flCoverVariantsLeftY = -14
	SWEP.flCoverFireLeft = 0
	SWEP.flCoverFireRight = 0
	SWEP.flCustomZoomFoV = nil
	SWEP.flMaxZoom = .1 //As Seen in The Literal Line Below, FoV * ( 1 - This * flZoom )
	SWEP.flCurrentFoV = 0
	SWEP.bDontDrawCrosshairDuringZoom = true
	SWEP.Crosshair = ""
	SWEP.__VIEWMODEL_FULLY_MODELED__ = false
	local t = math
	local math_min, math_max = t.min, t.max
	local math_AngleDifference = t.AngleDifference
	local math_Approach = t.Approach
	local math_Clamp = t.Clamp
	local math_Round = t.Round
	function SWEP:CalcView( ply, pos, ang, fov )
		local MyTable = CEntity_GetTable( self )
		ang[ 3 ] = ang[ 3 ] - 22.5 * MyTable.flCoverBlindFireLeft + 22.5 * MyTable.flCoverBlindFireRight - 11.25 * MyTable.flCoverFireLeft + 11.25 * MyTable.flCoverFireRight
		local f = MyTable.flCustomZoomFoV && math.Remap( MyTable.flZoom, 0, 1, fov, MyTable.flCustomZoomFoV ) || fov * ( 1 - MyTable.flMaxZoom * MyTable.flZoom )
		MyTable.flCurrentFoV = f
		return pos, ang, f
	end
	function SWEP:AdjustMouseSensitivity()
		local owner = LocalPlayer()
		if IsValid( owner ) then return CEntity_GetTable( self ).flCurrentFoV / owner:GetFOV() end
	end
	function SWEP:CalcViewModelView( vm, opos, oang, pos, ang )
		local MyTable = CEntity_GetTable( self )
		local ply = LocalPlayer()
		local bInCover = ply:GetNW2Bool( "CTRL_bInCover", false )
		local bCoverStance = bInCover
		if !bInCover then
			if MyTable.flCoverVariantsCenter > 0 then
				MyTable.flCoverVariantsCenter = math_max( MyTable.flCoverVariantsCenter - MyTable.flCoverVariantsCenter * MyTable.flZoomSpeedIn * FrameTime(), 0 )
			end
			if MyTable.flCoverVariantsRight > 0 then
				MyTable.flCoverVariantsRight = math_max( MyTable.flCoverVariantsRight - MyTable.flCoverVariantsRight * MyTable.flZoomSpeedIn * FrameTime(), 0 )
			end
			if MyTable.flCoverVariantsLeft > 0 then
				MyTable.flCoverVariantsLeft = math_max( MyTable.flCoverVariantsLeft - MyTable.flCoverVariantsLeft * MyTable.flZoomSpeedIn * FrameTime(), 0 )
			end
		end
		pos = pos - ang:Up() * 8 * MyTable.flCover
		local flZoom = MyTable.flZoom
		local flZoomInv = 1 - flZoom
		if MyTable.aViewModelLastAng then
			local flDiffPitch, flDiffYaw = math_Clamp( math_Round( math_AngleDifference( MyTable.aViewModelLastAng[ 1 ], ang[ 1 ] ) ) * MyTable.flViewModelPitchExagg, MyTable.flViewModelPitchMin, MyTable.flViewModelPitchMax ), math_Clamp( math_Round( math_AngleDifference( MyTable.aViewModelLastAng[ 2 ], ang[ 2 ] ) ) * MyTable.flViewModelYawExagg, MyTable.flViewModelPitchMin, MyTable.flViewModelPitchMax )
			MyTable.aViewModelLastAng = Angle( ang )
			MyTable.flViewModelPitch = math_Approach( MyTable.flViewModelPitch, flDiffPitch * flZoomInv, MyTable.flViewModelPitchSpeed * FrameTime() )
			MyTable.flViewModelYaw = math_Approach( MyTable.flViewModelYaw, flDiffYaw * flZoomInv, MyTable.flViewModelYawSpeed * FrameTime() )
		else MyTable.aViewModelLastAng = ang end
		local PEEK = ply:GetNW2Int( "CTRL_Peek", COVER_PEEK_NONE )
		if PEEK == COVER_BLINDFIRE_UP then
			bCoverStance = nil
			if MyTable.flCoverBlindFireUp < 1 then
				MyTable.flCoverBlindFireUp = math_min( MyTable.flCoverBlindFireUp + ( 1 - MyTable.flCoverBlindFireUp ) * MyTable.flZoomSpeedIn * FrameTime(), 1 )
			end
		else
			if MyTable.flCoverBlindFireUp > 0 then
				MyTable.flCoverBlindFireUp = math_max( MyTable.flCoverBlindFireUp - MyTable.flCoverBlindFireUp * MyTable.flZoomSpeedIn * FrameTime(), 0 )
			end
		end
		if PEEK == COVER_BLINDFIRE_LEFT then
			bCoverStance = nil
			if MyTable.flCoverBlindFireLeft < 1 then
				MyTable.flCoverBlindFireLeft = math_min( MyTable.flCoverBlindFireLeft + ( 1 - MyTable.flCoverBlindFireLeft ) * MyTable.flZoomSpeedIn * FrameTime(), 1 )
			end
		else
			if MyTable.flCoverBlindFireLeft > 0 then
				MyTable.flCoverBlindFireLeft = math_max( MyTable.flCoverBlindFireLeft - MyTable.flCoverBlindFireLeft * MyTable.flZoomSpeedIn * FrameTime(), 0 )
			end
		end
		if PEEK == COVER_BLINDFIRE_RIGHT then
			bCoverStance = nil
			if MyTable.flCoverBlindFireRight < 1 then
				MyTable.flCoverBlindFireRight = math_min( MyTable.flCoverBlindFireRight + ( 1 - MyTable.flCoverBlindFireRight ) * MyTable.flZoomSpeedIn * FrameTime(), 1 )
			end
		else
			if MyTable.flCoverBlindFireRight > 0 then
				MyTable.flCoverBlindFireRight = math_max( MyTable.flCoverBlindFireRight - MyTable.flCoverBlindFireRight * MyTable.flZoomSpeedIn * FrameTime(), 0 )
			end
		end
		if PEEK == COVER_FIRE_LEFT then
			if MyTable.flCoverFireLeft < 1 then
				MyTable.flCoverFireLeft = math_min( MyTable.flCoverFireLeft + ( 1 - MyTable.flCoverFireLeft ) * MyTable.flZoomSpeedIn * FrameTime(), 1 )
			end
		else
			if MyTable.flCoverFireLeft > 0 then
				MyTable.flCoverFireLeft = math_max( MyTable.flCoverFireLeft - MyTable.flCoverFireLeft * MyTable.flZoomSpeedIn * FrameTime(), 0 )
			end
		end
		if PEEK == COVER_FIRE_RIGHT then
			if MyTable.flCoverFireRight < 1 then
				MyTable.flCoverFireRight = math_min( MyTable.flCoverFireRight + ( 1 - MyTable.flCoverFireRight ) * MyTable.flZoomSpeedIn * FrameTime(), 1 )
			end
		else
			if MyTable.flCoverFireRight > 0 then
				MyTable.flCoverFireRight = math_max( MyTable.flCoverFireRight - MyTable.flCoverFireRight * MyTable.flZoomSpeedIn * FrameTime(), 0 )
			end
		end
		if bCoverStance then
			if MyTable.flCover < 1 then
				MyTable.flCover = math_min( MyTable.flCover + ( 1 - MyTable.flCover ) * MyTable.flZoomSpeedIn * FrameTime(), 1 )
			end
			if MyTable.flZoom > 0 then
				MyTable.flZoom = math_max( MyTable.flZoom - MyTable.flZoom * MyTable.flZoomSpeedOut * FrameTime(), 0 )
			end
		else
			if MyTable.flCover > 0 then
				MyTable.flCover = math_max( MyTable.flCover - MyTable.flCover * MyTable.flZoomSpeedIn * FrameTime(), 0 )
			end
			if ply:KeyDown( IN_ZOOM ) then
				if MyTable.flZoom < 1 then
					MyTable.flZoom = math_min( MyTable.flZoom + ( 1 - MyTable.flZoom ) * MyTable.flZoomSpeedIn * FrameTime(), 1 )
				end
			else
				if MyTable.flZoom > 0 then
					MyTable.flZoom = math_max( MyTable.flZoom - MyTable.flZoom * MyTable.flZoomSpeedOut * FrameTime(), 0 )
				end
			end
		end
		if bInCover then
			local VARIANTS = ply:GetNW2Int( "CTRL_Variants", COVER_VARIANTS_CENTER )
			if VARIANTS == COVER_VARIANTS_CENTER then
				if MyTable.flCoverVariantsCenter < 1 then
					MyTable.flCoverVariantsCenter = math_min( MyTable.flCoverVariantsCenter + ( 1 - MyTable.flCoverVariantsCenter ) * MyTable.flZoomSpeedIn * FrameTime(), 1 )
				end
			else
				if MyTable.flCoverVariantsCenter > 0 then
					MyTable.flCoverVariantsCenter = math_max( MyTable.flCoverVariantsCenter - MyTable.flCoverVariantsCenter * MyTable.flZoomSpeedIn * FrameTime(), 0 )
				end
			end
			if VARIANTS == COVER_VARIANTS_RIGHT then
				if MyTable.flCoverVariantsRight < 1 then
					MyTable.flCoverVariantsRight = math_min( MyTable.flCoverVariantsRight + ( 1 - MyTable.flCoverVariantsRight ) * MyTable.flZoomSpeedIn * FrameTime(), 1 )
				end
			else
				if MyTable.flCoverVariantsRight > 0 then
					MyTable.flCoverVariantsRight = math_max( MyTable.flCoverVariantsRight - MyTable.flCoverVariantsRight * MyTable.flZoomSpeedIn * FrameTime(), 0 )
				end
			end
			if VARIANTS == COVER_VARIANTS_LEFT then
				if MyTable.flCoverVariantsLeft < 1 then
					MyTable.flCoverVariantsLeft = math_min( MyTable.flCoverVariantsLeft + ( 1 - MyTable.flCoverVariantsLeft ) * MyTable.flZoomSpeedIn * FrameTime(), 1 )
				end
			else
				if MyTable.flCoverVariantsLeft > 0 then
					MyTable.flCoverVariantsLeft = math_max( MyTable.flCoverVariantsLeft - MyTable.flCoverVariantsLeft * MyTable.flZoomSpeedIn * FrameTime(), 0 )
				end
			end
		end
		ang[ 1 ] = ang[ 1 ] - MyTable.flViewModelPitch
		ang[ 2 ] = ang[ 2 ] - MyTable.flViewModelYaw
		pos = pos + ang:Forward() * ( MyTable.flViewModelAimX * flZoom + MyTable.flViewModelX * flZoomInv ) + ang:Right() * ( MyTable.flViewModelAimY * flZoom + MyTable.flViewModelY * flZoomInv ) + ang:Up() * ( MyTable.flViewModelAimZ * flZoom + MyTable.flViewModelZ * flZoomInv )
		if MyTable.__VIEWMODEL_FULLY_MODELED__ then
			pos = pos + ang:Right() * ( MyTable.flCoverBlindFireUp * MyTable.flCoverBlindFireUpY + MyTable.flCoverVariantsCenter * MyTable.flCoverVariantsCenterY + MyTable.flCoverVariantsRight * MyTable.flCoverVariantsRightY + MyTable.flCoverVariantsLeft * MyTable.flCoverVariantsLeftY )
			pos = pos + ang:Up() * ( MyTable.flCoverBlindFireRight * MyTable.flCoverBlindFireRightZ - MyTable.flCoverBlindFireLeft * MyTable.flCoverBlindFireLeftZ )
			ang.r = ang.r - 180 * MyTable.flCoverBlindFireUp + 90 * MyTable.flCoverBlindFireLeft - 90 * MyTable.flCoverBlindFireRight
		end
		ang.p = ang.p - 22.5 * MyTable.flCover
		return pos, ang
	end
	include "Crosshair.lua"
end

weapons.Register( SWEP, "BaseWeapon" )
