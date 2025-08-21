local math_max = math.max
function SWEP:GatherCrosshairSpread( MyTable, bForceIdentical )
	local flSpreadX, flSpreadY
	local v = MyTable.Primary_flSpreadX
	if v then flSpreadX = v end
	local v = MyTable.Primary_flSpreadY
	if v then flSpreadX = v end
	if MyTable.bCrosshairSizeIdentical || bForceIdentical then
		local v = math_max( flSpreadX || flSpreadY, flSpreadY || flSpreadX )
		return v, v
	end
	return flSpreadX, flSpreadY
end

SWEP.CrosshairColorBase = Color( 255, 255, 255 )
SWEP.CrosshairColorOutLine = Color( 0, 0, 0 )
SWEP.flCrosshairBase = .0012
SWEP.flCrosshairOutLine = .0008
__WEAPON_CROSSHAIR_TABLE__ = {
	[ "" ] = function( MyTable, self ) return true end,
	Shotgun = function( MyTable, self )
		local flSpread = MyTable.GatherCrosshairSpread( self, MyTable, true )
		local flHeight, flWidth = ScrH(), ScrW()
		//I have ABSOLUTELY NO IDEA Why in The World This Works, But It Does
		local flRadius = flSpread * flWidth * ( 90 / MyTable.flFoV ) * .5
		local flX = flWidth * .5
		local flY = flHeight * .5
		local co = MyTable.CrosshairColorOutLine
		local f = MyTable.flCrosshairOutLine * flHeight
		local flStart, flEnd = flRadius, flRadius + f
		for I = flStart, flEnd, 1 do surface.DrawCircle( flX, flY, I, co.r, co.g, co.b, 255 ) end
		local c = MyTable.CrosshairColorBase
		local flStart = flEnd
		local flEnd = flEnd + MyTable.flCrosshairBase * flHeight
		for I = flStart, flEnd do surface.DrawCircle( flX, flY, I, c.r, c.g, c.b, 255 ) end
		local flStart = flEnd
		local flEnd = flEnd + f
		for I = flStart, flEnd do surface.DrawCircle( flX, flY, I, co.r, co.g, co.b, 255 ) end
		return true
	end
}
local __WEAPON_CROSSHAIR_TABLE__ = __WEAPON_CROSSHAIR_TABLE__

function SWEP.pCrosshairTable() return __WEAPON_CROSSHAIR_TABLE__ end

local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
local developer = GetConVar "developer"
local CPlayer = FindMetaTable "Player"
local CPlayer_KeyDown = CPlayer.KeyDown
SWEP.bDontDrawCrosshairDuringZoom = true
function SWEP:DoDrawCrosshair()
	if developer:GetBool() then return end
	local MyTable = CEntity_GetTable( self )
	local ply = LocalPlayer()
	if CEntity_GetNW2Bool( ply, "CTRL_bSprinting" ) || ( MyTable.bDontDrawCrosshairDuringZoom && MyTable.vViewModelAim && CPlayer_KeyDown( ply, IN_ZOOM ) ) then return true end
	local v = __WEAPON_CROSSHAIR_TABLE__[ MyTable.Crosshair ]
	if v != nil then return v( MyTable, self ) end
end
