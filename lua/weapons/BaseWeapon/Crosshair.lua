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
function SWEP:GatherCrosshairAlpha( MyTable ) return MyTable.bDontDrawCrosshairDuringZoom && ( 1 - MyTable.flZoom ) * 255 || 255 end

SWEP.CrosshairColorBase = Color( 255, 255, 255 )
SWEP.CrosshairColorOutLine = Color( 0, 0, 0 )
SWEP.flCrosshairBase = .001
SWEP.flCrosshairOutLine = .0008
__WEAPON_CROSSHAIR_TABLE__ = {
	Shotgun = function( MyTable, self )
		local flSpread = MyTable.GatherCrosshairSpread( self, MyTable, true )
		local flHeight, flWidth = ScrH(), ScrW()
		//I have ABSOLUTELY NO IDEA Why in The World This Works, But It Does
		local flRadius = flSpread * flHeight * .5
		local flX = flWidth * .5
		local flY = flHeight * .5
		local flAlpha = MyTable.GatherCrosshairAlpha( self, MyTable )
		if flAlpha == nil then return end
		local co = MyTable.CrosshairColorOutLine
		local f = MyTable.flCrosshairOutLine * flHeight
		local flStart, flEnd = flRadius, flRadius + f
		for I = flStart, flEnd, 1 do surface.DrawCircle( flX, flY, I, co.r, co.g, co.b, flAlpha ) end
		local c = MyTable.CrosshairColorBase
		local flStart = flEnd
		local flEnd = flEnd + MyTable.flCrosshairBase * flHeight
		for I = flStart, flEnd, 1 do surface.DrawCircle( flX, flY, I, c.r, c.g, c.b, flAlpha ) end
		local flStart = flEnd
		local flEnd = flEnd + f
		for I = flStart, flEnd, 1 do surface.DrawCircle( flX, flY, I, co.r, co.g, co.b, flAlpha ) end
		return true
	end
}
local __WEAPON_CROSSHAIR_TABLE__ = __WEAPON_CROSSHAIR_TABLE__

function SWEP.pCrosshairTable() return __WEAPON_CROSSHAIR_TABLE__ end

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable
local developer = GetConVar "developer"
function SWEP:DoDrawCrosshair()
	if developer:GetBool() then return end
	local MyTable = CEntity_GetTable( self )
	//if LocalPlayer():KeyDown( IN_ZOOM ) || SysTime() <= MyTable.flSecondaryAttackDefaultZoom then return true end
	local v = __WEAPON_CROSSHAIR_TABLE__[ MyTable.Crosshair ]
	if v != nil then return v( MyTable, self ) end
end
