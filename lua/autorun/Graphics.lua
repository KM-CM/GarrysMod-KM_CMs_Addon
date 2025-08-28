//This is Shared for a Reason, and Includes More Than Just Client Graphics

//Gets The Human Percieved Brightness of a Color
function GetBrightness( c ) return c[ 1 ] * .00083372549 + c[ 2 ] * .00280470588 + c[ 3 ] * .00028313725 end
//Same as Above Except Uses Vector Colors
function GetBrightnessVC( v ) return v[ 1 ]  * .2126 + v[ 2 ] * .7152  + v[ 3 ] * .0722 end
//Also Same as Above Except Uses Red/Green/Blue Floats
function GetBrightnessRGB( r, g, b ) return r * .00083372549 + g * .00280470588 + b * .00028313725 end

if !CLIENT_DLL then return end

local util_TraceLine = util.TraceLine
local MASK_VISIBLE_AND_NPCS = MASK_VISIBLE_AND_NPCS
local LocalPlayer = LocalPlayer
local EyePos = EyePos
local vUpHuge = Vector( 0, 0, 999999 )

//Similar to util.IsSkyboxVisibleFromPoint
function UTIL_IsUnderSkybox()
	return util_TraceLine( {
		start = EyePos(),
		endpos = EyePos() + vUpHuge,
		filter = LocalPlayer(),
		mask = MASK_VISIBLE_AND_NPCS
	} ).HitSky
end

//These Shall NOT be Overriden by ANYTHING!
local BLEED_MAX_COLOR_MULTIPLY = 1
local BLEED_MAX_COLOR_ADD = .5

local BLEED_COLORLESS_LOWER_THRESHOLD = .2
local BLEED_COLORLESS_UPPER_THRESHOLD = .6

local util_TraceLine = util.TraceLine

local function VectorSum( v ) return abs( v[ 1 ] ) + abs( v[ 2 ] ) + abs( v[ 3 ] ) end
setfenv( VectorSum, { abs = math.abs } )

function DrawBlur( flIntensity ) DrawBokehDOF( flIntensity, 0, 0 ) end

local MAX_WATER_BLUR = 3
//[ 0, 1 ], Not [ 0, MAX_WATER_BLUR ]!
local WATER_BLUR_CHANGE_SPEED_TO = .8
local WATER_BLUR_CHANGE_SPEED_FROM = .2

local VECTOR_HUGE_Z = Vector( 0, 0, 999999 )

hook.Add( "RenderScreenspaceEffects", "Graphics", function()
	local self = LocalPlayer()
	if !IsValid( self ) then return end
	local tDrawColorModify = {
		[ "$pp_colour_addr" ] = 0,
		[ "$pp_colour_addg" ] = 0,
		[ "$pp_colour_addb" ] = 0,
		[ "$pp_colour_brightness" ] = 0,
		[ "$pp_colour_contrast" ] = 1,
		[ "$pp_colour_colour" ] = 1,
		[ "$pp_colour_mulr" ] = 0,
		[ "$pp_colour_mulg" ] = 0,
		[ "$pp_colour_mulb" ] = 0
	}
	local flDeath = math.Clamp( self:Health() / self:GetMaxHealth(), 0, 1 )
	if flDeath > BLEED_COLORLESS_UPPER_THRESHOLD then
		local flBleed = math.Remap( flDeath, BLEED_COLORLESS_UPPER_THRESHOLD, 1, 1, 0 )
		tDrawColorModify[ "$pp_colour_mulr" ] = flBleed * BLEED_MAX_COLOR_MULTIPLY
		tDrawColorModify[ "$pp_colour_addr" ] = flBleed * BLEED_MAX_COLOR_ADD
	elseif flDeath > BLEED_COLORLESS_LOWER_THRESHOLD then
		local flBleed = math.Remap( flDeath, BLEED_COLORLESS_LOWER_THRESHOLD, BLEED_COLORLESS_UPPER_THRESHOLD, 0, 1 )
		tDrawColorModify[ "$pp_colour_mulr" ] = flBleed * BLEED_MAX_COLOR_MULTIPLY
		tDrawColorModify[ "$pp_colour_addr" ] = flBleed * BLEED_MAX_COLOR_ADD
		tDrawColorModify[ "$pp_colour_colour" ] = math.Remap( flDeath, BLEED_COLORLESS_UPPER_THRESHOLD, BLEED_COLORLESS_LOWER_THRESHOLD, 1, 0 )
	else
		tDrawColorModify[ "$pp_colour_colour" ] = 0
	end
	local flOxygen, flOxygenLimit = self:GetNW2Float( "GAME_flOxygen", -1 ), self:GetNW2Float( "GAME_flOxygenLimit", -1 )
	if flOxygen != -1 && flOxygenLimit != -1 then
		local f = flOxygenLimit * .33
		if flOxygen <= f then
			tDrawColorModify[ "$pp_colour_contrast" ] = tDrawColorModify[ "$pp_colour_contrast" ] * math.Remap( flOxygen, f, 0, 1, 0 )
		end
	end
	local tr = util_TraceLine {
		start = EyePos(),
		endpos = EyePos() - VECTOR_HUGE_Z,
		mask = MASK_VISIBLE_AND_NPCS,
		filter = self
	}
	local vColor = ( render.ComputeLighting( tr.HitPos, tr.HitNormal ) + render.ComputeDynamicLighting( tr.HitPos, tr.HitNormal ) ) * 33
	local flColor = math.Clamp( VectorSum( vColor ), 0, 1 )
	local flBloom = math.Approach( self.GP_flBloom || 0, 1 - flColor, FrameTime() )
	self.GP_flBloom = flBloom
	if self:WaterLevel() >= 3 then
		self.GP_flWaterBlur = math.Approach( self.GP_flWaterBlur || 0, 1, WATER_BLUR_CHANGE_SPEED_TO * FrameTime() )
	else self.GP_flWaterBlur = math.Approach( self.GP_flWaterBlur || 0, 0, WATER_BLUR_CHANGE_SPEED_FROM * FrameTime() ) end
	if self.GP_flWaterBlur > 0 then
		DrawBlur( self.GP_flWaterBlur * MAX_WATER_BLUR )
		DrawMaterialOverlay( "effects/water_warp01", self.GP_flWaterBlur * .01 )
		flBloom = math.Clamp( flBloom + self.GP_flWaterBlur * .2, 0, 1 )
	end
	local vColorNorm = vColor:GetNormalized()
	self.GP_FogDensityMul = math.Approach( self.GP_FogDensityMul || .1, math.Remap( flColor, 0, 1, .1, .2 ), 1 * FrameTime() )
	self.GP_FogR = math.Approach( self.GP_FogR || 255, vColorNorm[ 1 ] * 255, 32 * FrameTime() )
	self.GP_FogG = math.Approach( self.GP_FogG || 255, vColorNorm[ 2 ] * 255, 32 * FrameTime() )
	self.GP_FogB = math.Approach( self.GP_FogB || 255, vColorNorm[ 3 ] * 255, 32 * FrameTime() )
	local flFogR, flFogG, flFogB = self.GP_FogR, self.GP_FogG, self.GP_FogB
	local flBrightness = GetBrightnessRGB( flFogR, flFogG, flFogB )
	local flMultiplier = math.Remap( flBrightness, 0, 1, 1, 0 )
	flFogR, flFogG, flFogB = flFogR * .00392156862, flFogG * .00392156862, flFogB * .00392156862
	tDrawColorModify[ "$pp_colour_addr" ] = tDrawColorModify[ "$pp_colour_addr" ] + flFogR * .2 * flMultiplier
	tDrawColorModify[ "$pp_colour_addg" ] = tDrawColorModify[ "$pp_colour_addg" ] + flFogG * .2 * flMultiplier
	tDrawColorModify[ "$pp_colour_addb" ] = tDrawColorModify[ "$pp_colour_addb" ] + flFogB * .2 * flMultiplier
	tDrawColorModify[ "$pp_colour_mulr" ] = tDrawColorModify[ "$pp_colour_mulr" ] + flFogR * flMultiplier
	tDrawColorModify[ "$pp_colour_mulg" ] = tDrawColorModify[ "$pp_colour_mulg" ] + flFogG * flMultiplier
	tDrawColorModify[ "$pp_colour_mulb" ] = tDrawColorModify[ "$pp_colour_mulb" ] + flFogB * flMultiplier
	local flTarget = UTIL_IsUnderSkybox() && math.Remap( flColor, 0, 1, 512, 6084 ) || math.Remap( flColor, 0, 1, 512, 3072 )
	self.GP_FogDistance = math.Approach( self.GP_FogDistance || 0, flTarget, math.max( 64, math.abs( flTarget - ( self.GP_FogDistance || 0 ) ) * .2 ) * FrameTime() )
	DrawBloom( math.Remap( flBloom, 0, 1, .25, 0 ), math.Remap( flBloom, 0, 1, .9, 2 ), 10, 10, 5, math.Remap( flBloom, 0, 1, 1, 2 ), 1, 1, 1 )
	DrawColorModify( tDrawColorModify )
end )

hook.Add( "SetupWorldFog", "Graphics", function()
	local self = LocalPlayer()
	if !IsValid( self ) then return end
	render.FogMode( MATERIAL_FOG_LINEAR )
	render.FogColor( self.GP_FogR || 255, self.GP_FogG || 255, self.GP_FogB || 255 )
	render.FogStart( 0 )
	render.FogEnd( self.GP_FogDistance || 0 )
	local flBrightness = GetBrightnessRGB( self.GP_FogR || 255, self.GP_FogG || 255, self.GP_FogB || 255 )
	render.FogMaxDensity( ( flBrightness < .5 && math.Remap( flBrightness, 0, .5, 0, 1 ) || math.Remap( flBrightness, .5, 1, 1, 0 ) ) * ( self.GP_FogDensityMul || 0 ) )
	return true
end )

__HUD_SHOULD_NOT_DRAW__ = { CHudHistoryResource = true, CHudGeiger = true, CHudDamageIndicator = true }
hook.Add( "HUDShouldDraw", "Graphics", function( sName ) return __HUD_SHOULD_NOT_DRAW__[ sName ] == nil end )
