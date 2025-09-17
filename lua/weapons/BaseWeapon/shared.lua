function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end

SWEP.__WEAPON__ = true

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

function SWEP:Deploy() self:BaseWeaponDraw( ACT_VM_DRAW ) end

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

local CPlayer = FindMetaTable "Player"
local CPlayer_KeyDown = CPlayer.KeyDown
local CPlayer_GetRunSpeed = CPlayer.GetRunSpeed
local CEntity_GetVelocity = CEntity.GetVelocity
local CEntity_IsOnGround = CEntity.IsOnGround
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
local CEntity_GetTable = CEntity.GetTable

local math = math
local math_min = math.min

if CLIENT then
	local Vector = Vector
	local vFinal = Vector( 0, 0, 0 )
	local vFinalAngle = Vector( 0, 0, 0 )
	local vTarget = Vector( 0, 0, 0 )
	local vTargetAngle = Vector( 0, 0, 0 )
	local vViewFinal = Vector( 0, 0, 0 )
	local vViewFinalAngle = Vector( 0, 0, 0 )
	local vViewTarget = Vector( 0, 0, 0 )
	local vViewTargetAngle = Vector( 0, 0, 0 )
	local aAim, aViewAim = Angle( 0, 0, 0 ), Angle( 0, 0, 0 )
	local flLandTime, flJumpTime = 0, 0
	SWEP.ViewModelFOV = 62
	SWEP.flViewModelX = 0
	SWEP.flViewModelY = 0
	SWEP.flViewModelZ = 0
	SWEP.vViewModelAim = false
	SWEP.vViewModelAimAngle = false
	SWEP.flSwayScale = 60
	SWEP.flSwayAngle = 4
	SWEP.flSwayVector = 1.5
	SWEP.SwayScale = 0
	SWEP.BobScale = 0
	SWEP.vSprintArm = Vector( 1.358, 1.228, -.94 )
	SWEP.vSprintArmAngle = Vector( -10.554, 34.167, -20 )
	SWEP.flAimMultiplier = 1
	SWEP.flFoV = 99
	local MOVE_LEFT_ROLL, MOVE_RIGHT_ROLL = -5.625, 5.625
	local math_cos = math.cos
	local math_sin = math.sin
	local math_Clamp = math.Clamp
	local math_AngleDifference = math.AngleDifference
	local math_NormalizeAngle = math.NormalizeAngle
	local CEntity_WaterLevel = CEntity.WaterLevel
	local CPlayer_GetWalkSpeed = CPlayer.GetWalkSpeed
	local CPlayer_InVehicle = CPlayer.InVehicle
	local bOnGroundLast
	local function BezierY( f, a, b, c )
		f = f * 3.2258
		return ( 1 - f ) ^ 2 * a + 2 * ( 1 - f ) * f * b + ( f ^ 2 ) * c
	end
	local BEZIER_MIMICRY_RATIO = .5
	local math_Remap = math.Remap
	function SWEP:AdjustMouseSensitivity() local v = CEntity_GetTable( self ).flFoV if v then return v / LocalPlayer():GetInfoNum( "fov_desired", 99 ) end end
	local CPlayer_IsSprinting = CPlayer.IsSprinting
	local CPlayer_Crouching = CPlayer.Crouching
	local CEntity_GetNW2Int = CEntity.GetNW2Int
	function SWEP:CalcView( ply, pos, ang, fov )
		local MyTable = CEntity_GetTable( self )
		vViewTarget, vViewTargetAngle = Vector( 0, 0, 0 ), Vector( 0, 0, 0 )
		if CEntity_IsOnGround( ply ) && ( bSprinting || CPlayer_IsSprinting( ply ) ) then
			local flVelocity = CEntity_GetVelocity( ply ):Length()
			if flVelocity > 10 then
				local flBreathe = RealTime() * 18
				local f = flVelocity / CPlayer_GetRunSpeed( ply ) * 4
				local v = Vector( ( -math_cos( flBreathe * .5 ) / 5 ) * f, 0, 0 )
				vTarget = vTarget - v
				vViewTarget = vViewTarget - v
				local v = Vector( ( math_Clamp( math_cos( flBreathe ), -.3, .3 ) * 1.2 ) * f, ( -math_cos( flBreathe * .5 ) * 1.2 ) * f, 0 )
				vTargetAngle = vTargetAngle - v
				vViewTargetAngle = vViewTargetAngle - v
			end
		end
		local p = CEntity_GetNW2Int( ply, "CTRL_Peek" )
		if p == COVER_FIRE_LEFT then
			vViewTargetAngle.z = vViewTargetAngle.z - 11.25
		elseif p == COVER_FIRE_RIGHT then
			vViewTargetAngle.z = vViewTargetAngle.z + 11.25
		elseif p == COVER_BLINDFIRE_LEFT then
			vViewTargetAngle.z = vViewTargetAngle.z - 22.5
		elseif p == COVER_BLINDFIRE_RIGHT then
			vViewTargetAngle.z = vViewTargetAngle.z + 22.5
		end
		local bLeft, bRight = CPlayer_KeyDown( ply, IN_MOVELEFT ), CPlayer_KeyDown( ply, IN_MOVERIGHT )
		if bLeft && bRight then
		elseif bLeft then
			vViewTargetAngle.z = vViewTargetAngle.z + MOVE_LEFT_ROLL
		elseif bRight then
			vViewTargetAngle.z = vViewTargetAngle.z + MOVE_RIGHT_ROLL
		end
		local f = MyTable.vBezier
		if f then vViewTarget = vViewTarget + f * BEZIER_MIMICRY_RATIO end
		f = MyTable.vBezierAngle
		if f then f = f.x vViewTargetAngle.x = vViewTargetAngle.x + f * BEZIER_MIMICRY_RATIO end
		vViewFinal = LerpVector( 5 * FrameTime(), vViewFinal, vViewTarget )
		vViewFinalAngle = LerpVector( 5 * FrameTime(), vViewFinalAngle, vViewTargetAngle )
		ang:RotateAroundAxis( ang:Right(), vViewFinalAngle.x )
		ang:RotateAroundAxis( ang:Up(), vViewFinalAngle.y )
		ang:RotateAroundAxis( ang:Forward(), vViewFinalAngle.z )
		pos = pos + vViewFinal.z * ang:Up()
		pos = pos + vViewFinal.y * ang:Forward()
		pos = pos + vViewFinal.x * ang:Right()
		aViewAim = LerpAngle( 5 * FrameTime(), aViewAim, ply:EyeAngles() )
		MyTable.aLastViewEyePosition = aViewAim - ply:EyeAngles()
		MyTable.aLastViewEyePosition.y = math_AngleDifference( aViewAim.y, math_NormalizeAngle( ply:EyeAngles().y ) )
		local flMultiplier = MyTable.flAimMultiplier || 0
		local flSwayAngle = MyTable.flSwayAngle * flMultiplier
		local flSwayAngleNeg = -flSwayAngle
		ang:RotateAroundAxis( ang:Right(), -math_Clamp( flSwayAngle * MyTable.aLastViewEyePosition.p / MyTable.flSwayScale, flSwayAngleNeg, flSwayAngle ) )
		ang:RotateAroundAxis( ang:Up(), -math_Clamp( flSwayAngleNeg * MyTable.aLastViewEyePosition.y / MyTable.flSwayScale, flSwayAngleNeg, flSwayAngle ) )
		local flSwayVector = MyTable.flSwayVector * flMultiplier
		local flSwayVectorNeg = -flSwayVector
		pos = pos - math_Clamp( ( flSwayVectorNeg * MyTable.aLastViewEyePosition.p / MyTable.flSwayScale ), flSwayVectorNeg, flSwayVector ) * ang:Up()
		pos = pos - math_Clamp( ( flSwayVectorNeg * MyTable.aLastViewEyePosition.y / MyTable.flSwayScale ), flSwayVectorNeg, flSwayVector ) * ang:Right()
		local v = MyTable.flCustomZoomFoV
		if v then
			local f = math_Remap( MyTable.flAimMultiplier, 1, 0, fov, v )
			MyTable.flFoV = f
			return pos, ang, f
		else MyTable.flFoV = fov end
		return pos, ang, fov
	end
	function SWEP:GatherCrosshairPosition( MyTable )
		local t = LocalPlayer():GetEyeTrace().HitPos:ToScreen()
		return t.x, t.y
	end
	function SWEP:CalcViewModelView( _, pos, ang )
		local MyTable = CEntity_GetTable( self )
		local ply = LocalPlayer()
		local bSprinting = CEntity_GetNW2Bool( ply, "CTRL_bSprinting" )
		local bSliding = CEntity_GetNW2Bool( ply, "CTRL_bSliding" )
		local bInCover = CEntity_GetNW2Bool( ply, "CTRL_bInCover" ) && !CEntity_GetNW2Bool( ply, "CTRL_bGunUsesCoverStance" )
		local bZoom = !bSprinting && !bSliding && !bInCover && CPlayer_KeyDown( ply, IN_ZOOM )
		local vAim
		if bZoom then vAim = MyTable.vViewModelAim if !vAim then bZoom = nil end end
		if bZoom then
			vTarget = Vector( vAim )
			local vAimAngle = MyTable.vViewModelAimAngle
			vTargetAngle = vAimAngle && Vector( vAimAngle ) || Vector( 0, 0, 0 )
		else
			vTarget = Vector( 0, 0, 0 )
			vTargetAngle = Vector( 0, 0, 0 )
		end
		if bInCover then
			if MyTable.__VIEWMODEL_FULLY_MODELED__ then
				local f = CEntity_GetNW2Int( ply, "CTRL_Variants" )
				if f == COVER_VARIANTS_RIGHT then
					vTargetAngle.x = vTargetAngle.x + 22.5
					vTarget.z = vTarget.z - 10
					vTarget.x = vTarget.x + 4
				elseif f == COVER_VARIANTS_LEFT then
					vTargetAngle.x = vTargetAngle.x + 22.5
					vTarget.z = vTarget.z - 10
					vTarget.x = vTarget.x - 18
				else
					vTargetAngle.x = vTargetAngle.x + 22.5
					vTarget.z = vTarget.z - 10
				end
			else
				vTargetAngle.x = vTargetAngle.x + 22.5
				vTarget.z = vTarget.z - 10
			end
		else
			if MyTable.__VIEWMODEL_FULLY_MODELED__ then
				local p = CEntity_GetNW2Int( ply, "CTRL_Peek" )
				if p == COVER_FIRE_LEFT then
				elseif p == COVER_FIRE_RIGHT then
				elseif p == COVER_BLINDFIRE_UP then
					vTargetAngle.z = vTargetAngle.z + 180
					vTarget.z = vTarget.z - 8
					vTarget.x = vTarget.x - 18
				elseif p == COVER_BLINDFIRE_LEFT then
					vTarget.x = vTarget.x - 18
				elseif p == COVER_BLINDFIRE_RIGHT then
					vTarget.x = vTarget.x + 4
				end
			end
			local bOnGround = CEntity_IsOnGround( ply )
			if CPlayer_InVehicle( ply ) then
				bOnGroundLast = true
			elseif bOnGround then
				bOnGroundLast = true
				if !bSliding && bSprinting || CPlayer_IsSprinting( ply ) then
					vTarget = vTarget + MyTable.vSprintArm
					vTargetAngle = vTargetAngle + MyTable.vSprintArmAngle
				else
					if bSliding || CEntity_GetNW2Int( ply, "CTRL_Peek" ) == COVER_PEEK_NONE && CurTime() > self:GetNextPrimaryFire() && CurTime() > self:GetNextSecondaryFire() && CPlayer_KeyDown( ply, IN_DUCK ) && !bZoom then
						vTargetAngle.x = vTargetAngle.x - 11.25
						vTarget.z = vTarget.z + 2.25
						if !bSliding then
							local flVelocity = CEntity_GetVelocity( ply ):Length()
							if flVelocity > 10 then
								local flBreathe = RealTime() * 18
								local f = flVelocity / CPlayer_GetWalkSpeed( ply ) * 4
								vTarget = vTarget - Vector( ( -math_cos( flBreathe * .5 ) / 5 ) * f, 0, 0 )
								vTargetAngle = vTargetAngle - Vector( ( math_Clamp( math_cos( flBreathe ), -.3, .3 ) * 1.2 ) * f, ( -math_cos( flBreathe * .5 ) * 1.2 ) * f, 0 )
							end
						end
					else
						local flVelocity = CEntity_GetVelocity( ply ):Length()
						if flVelocity > 10 then
							local flBreathe = RealTime() * 16
							local f = flVelocity / CPlayer_GetWalkSpeed( ply )
							vTarget = vTarget - Vector( ( -math_cos( flBreathe * .5 ) / 5 ) * f, 0, 0 )
							vTargetAngle = vTargetAngle - Vector( ( math_Clamp( math_cos( flBreathe ), -.3, .3 ) * 1.2 ) * f, ( -math_cos( flBreathe * .5 ) * 1.2 ) * f, 0 )
						end
					end
				end
			else
				flLandTime = RealTime() + .31
				if bOnGroundLast then
					flJumpTime = RealTime() + .31
					flLandTime = 0
					bOnGroundLast = nil
				end
			end
			if !bZoom && CEntity_WaterLevel( ply ) < 1 then
				if RealTime() <= flJumpTime then
					local f = .31 - ( flJumpTime - RealTime() )
					local xx = BezierY( f, 0, -4, 0 )
					local yy = 0
					local zz = BezierY( f, 0, -2, -5 )
					local pt = BezierY( f, 0, -4.36, 10 )
					local yw = xx
					local rl = BezierY( f, 0, -10.82, -5 )
					local v = Vector( xx, yy, zz )
					MyTable.vBezier = v
					vTarget = vTarget + v * 2
					local v = Vector( pt, yw, rl )
					MyTable.vBezierAngle = v
					vTargetAngle = vTargetAngle + v * ( 1 / BEZIER_MIMICRY_RATIO )
				elseif !bOnGround then
					local flBreathe = RealTime() * 30
					MyTable.vBezier = Vector( 0, 0, -5 )
					MyTable.vBezierAngle = Vector( 10, 0, -5 )
					local f = ( 1 / BEZIER_MIMICRY_RATIO )
					vTarget = vTarget + Vector( math_cos( flBreathe * .5 ) * .0625, 0, -5 * f + ( math_sin( flBreathe / 3 ) * .0625 ) )
					vTargetAngle = vTargetAngle + Vector( 10 * f - ( math_sin( flBreathe / 3 ) * .25 ), math_cos( flBreathe * .5 ) * .25, -5 )
				elseif RealTime() <= flLandTime then
					local f = flLandTime - RealTime()
					local xx = BezierY( f, 0, -4, 0 )
					local yy = 0
					local zz = BezierY( f, 0, -2, -5 )
					local pt = BezierY( f, 0, -4.36, 10 )
					local yw = xx
					local rl = BezierY( f, 0, -10.82, -5 )
					local v = Vector( xx, yy, zz )
					MyTable.vBezier = v
					vTarget = vTarget + v * 2
					local v = Vector( pt, yw, rl )
					MyTable.vBezierAngle = v
					vTargetAngle = vTargetAngle + v * ( 1 / BEZIER_MIMICRY_RATIO )
				else MyTable.vBezier = nil MyTable.vBezierAngle = nil end
			else MyTable.vBezier = nil MyTable.vBezierAngle = nil end
		end
		if MyTable.aLastEyePosition == nil then MyTable.aLastEyePosition = Angle( 0, 0, 0 ) end
		vTarget, vTargetAngle = vTarget, vTargetAngle
		local flAnimSpeed = 5
		vFinal = LerpVector( 5 * FrameTime(), vFinal, vTarget )
		vFinalAngle = LerpVector( 5 * FrameTime(), vFinalAngle, vTargetAngle )
		pos = pos + ang:Forward() * MyTable.flViewModelX + ang:Right() * MyTable.flViewModelY + ang:Up() * MyTable.flViewModelZ
		ang:RotateAroundAxis( ang:Right(), vFinalAngle.x )
		ang:RotateAroundAxis( ang:Up(), vFinalAngle.y )
		ang:RotateAroundAxis( ang:Forward(), vFinalAngle.z )
		pos = pos + vFinal.z * ang:Up()
		pos = pos + vFinal.y * ang:Forward()
		pos = pos + vFinal.x * ang:Right()
		aAim = LerpAngle( 5 * FrameTime(), aAim, ply:EyeAngles() )
		MyTable.aLastEyePosition = aAim - ply:EyeAngles()
		MyTable.aLastEyePosition.y = math_AngleDifference( aAim.y, math_NormalizeAngle( ply:EyeAngles().y ) )
		local flMultiplier
		if bZoom then
			flMultiplier = vFinal:Distance( vTarget ) / vTarget:Length()
		else
			flMultiplier = math_Clamp( MyTable.flAimMultiplier + FrameTime(), 0, 1 )
		end
		MyTable.flAimMultiplier = flMultiplier
		local flSwayAngle = MyTable.flSwayAngle * flMultiplier
		local flSwayAngleNeg = -flSwayAngle
		ang:RotateAroundAxis( ang:Right(), math_Clamp( flSwayAngle * MyTable.aLastEyePosition.p / MyTable.flSwayScale, flSwayAngleNeg, flSwayAngle ) )
		ang:RotateAroundAxis( ang:Up(), math_Clamp( flSwayAngleNeg * MyTable.aLastEyePosition.y / MyTable.flSwayScale, flSwayAngleNeg, flSwayAngle ) )
		local flSwayVector = MyTable.flSwayVector * flMultiplier
		local flSwayVectorNeg = -flSwayVector
		pos = pos + math_Clamp( ( flSwayVectorNeg * MyTable.aLastEyePosition.p / MyTable.flSwayScale ), flSwayVectorNeg, flSwayVector ) * ang:Up()
		pos = pos + math_Clamp( ( flSwayVectorNeg * MyTable.aLastEyePosition.y / MyTable.flSwayScale ), flSwayVectorNeg, flSwayVector ) * ang:Right()
		return pos, ang
	end
	include "Crosshair.lua"
end

sound.Add {
	name = "HumanSlideLoop",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 70,
	sound = "physics/flesh/flesh_scrape_rough_loop.wav"
}

weapons.Register( SWEP, "BaseWeapon" )
