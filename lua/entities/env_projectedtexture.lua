AddCSLuaFile()

ENT.Base = "base_point"
ENT.Type = "point"
ENT.PrintName = "#env_projectedtexture"

function ENT:UpdateTransmitState() return TRANSMIT_ALWAYS end

function ENT:SetupDataTables()
	// Use 0-1 Everywhere EXCEPT `lightcolor`! Internally NOT Stored as a 0-255 Integer! In `lightcolor`, This is Remapped from 0-255 to 0-1!
	self:NetworkVar( "Float", 0, "Brightness", { KeyName = "raw.brightness" } )
	// Sprite Size if `SpriteDisabled` isnt On
	self:NetworkVar( "Float", 1, "SpriteSize", { KeyName = "raw.spritesize" } )
	// `Shadows`, Mode 1: The Distance to The Trace"s `HitPos`
	self:NetworkVar( "Float", 2, "TrueDistance", { KeyName = "raw.truedistance" } )
	// `Shadows`, Mode 1: Compute Shadow Distance Anyway
	self:NetworkVar( "Bool", 0, "ComputeTrueDistance", { KeyName = "raw.computetruedistance" } )
	// Doesnt Spawn a Sprite
	self:NetworkVar( "Bool", 1, "SpriteDisabled", { KeyName = "raw.spritedisabled" } )
	/*
	0: Use Splinter Cell: Blacklist ( Modified Unreal Engine 2 ) Inspired Shadows ( Recommended )
	1: Use EXTREMELY EXPENSIVE Shadows Drawn by Vulcan ( Doesnt Render AT ALL on Weak Platforms! )
	*/
	self:NetworkVar( "Bool", 2, "Shadows", { KeyName = "raw.shadows" } )
	// The Texture of The Light
	self:NetworkVar( "String", 0 ,"Texture", { KeyName = "raw.texture" } )
	// The Light Color
	self:NetworkVar( "Vector", 0 ,"LightColor", { KeyName = "raw.lightcolor" } )
	// Minimum Distance. Clamped if Less Than 10.
	self:NetworkVar( "Int", 0 , "MinDistance", { KeyName = "raw.mindistance" } )
	// How Far Does The Light Go?
	self:NetworkVar( "Int", 1 , "Distance", { KeyName = "raw.distance" } )
	// The Amount of Degrees to Light Up Vertically
	self:NetworkVar( "Int", 2 , "VerFOV", { KeyName = "raw.verfov" } )
	// The Amount of Degrees to Light Up Horizontally
	self:NetworkVar( "Int", 3 , "HorFOV", { KeyName = "raw.horfov" } )
end

if CLIENT then
	language.Add( "env_projectedtexture", "Light" )
	function ENT:Initialize() self:Update() end
	function ENT:Think()
		local d = self:GetShadows() && self:GetDistance() || self:GetTrueDistance()
		self:SetRenderBounds( Vector( -d, -d, -d ), Vector( d, d, d ) )
		self:Update()
		self:SetNextClientThink( CurTime() )
		return true
	end

	function ENT:Update()
		if #self:GetTexture() <= 0 then self:SetTexture "effects/flashlight/soft" end
		local pt = self.ProjectedTexture
		if !pt then self.ProjectedTexture = ProjectedTexture() pt = self.ProjectedTexture end
		pt:SetPos( self:GetPos() )
		pt:SetAngles( self:GetAngles() )
		pt:SetTexture( self:GetTexture() )
		pt:SetShadowFilter( 0 )
		pt:SetNearZ( math.max( tonumber( self:GetMinDistance() ), 10 ) )
		pt:SetFarZ( self:GetDistance() )
		pt:SetColor( self:GetLightColor():ToColor() )
		pt:SetBrightness( self:GetBrightness() )
		pt:SetQuadraticAttenuation( 100 * ( self:GetDistance() / self:GetTrueDistance() ) )
		pt:SetHorizontalFOV( self:GetHorFOV() )
		pt:SetVerticalFOV( self:GetVerFOV() )
		if self:GetShadows() then
			self.flShadowDist = nil
			self.flShadowUpdt = 0
			pt:SetEnableShadows( true )
		else
			pt:SetEnableShadows( false )
			pt:SetFarZ( self:GetTrueDistance() )
		end
		pt:Update()
	end

	function ENT:OnRemove() if IsValid( self.ProjectedTexture ) then self.ProjectedTexture:Remove() end end
else
	function ENT:Initialize() self:Update() end
	function ENT:Think()
		self:Update()
		self:NextThink( CurTime() + .01 )
		return true
	end
	local util_TraceLine = util.TraceLine
	local math = math
	local math_cos = math.cos
	local math_acos = math.acos
	local math_Clamp = math.Clamp
	function ENT:Update()
		if !self:GetShadows() || self:GetComputeTrueDistance() then
			local t = { [ self ] = true, [ self:GetOwner() ] = true }
			local tr = util_TraceLine {
				start = self:GetPos(),
				endpos = self:GetPos() + self:GetForward() * self:GetDistance(),
				filter = function( ent ) return t[ ent ] == nil end,
				mask = MASK_VISIBLE_AND_NPCS
			}
			local f = tr.HitNormal:Dot( -self:GetForward() )
			f = ( f != 0 && ( tr.HitPos:Distance( self:GetPos() ) / math_cos( math_acos( math_Clamp( f, -1, 1 ) ) ) ) || tr.HitPos:Distance( self:GetPos() ) ) + 128
			self.flShadowDist = f
			self:SetTrueDistance( f )
		end
		if self:GetSpriteDisabled() then if IsValid( self.Sprite ) then self.Sprite:Remove() end else
			if !IsValid( self.Sprite ) then
				local spr = ents.Create "env_sprite"
				spr:SetPos( self:GetPos() )
				spr:SetParent( self )
				spr:SetKeyValue( "model", "sprites/glow1.spr" )
				spr:SetKeyValue( "scale", self:GetSpriteSize() != 0 && tonumber( self:GetSpriteSize() )  ||  self:GetBrightness() * .1 )
				spr:SetKeyValue( "rendermode", "9" )
				local c = self:GetLightColor():ToColor()
				spr:Fire( "ColorRedValue", c.r )
				spr:Fire( "ColorGreenValue", c.g )
				spr:Fire( "ColorBlueValue", c.b )
				spr:Spawn()
				self.Sprite = spr
			else
				local spr = self.Sprite
				spr:SetKeyValue( "scale", self:GetSpriteSize() != 0 && tonumber( self:GetSpriteSize() )  ||  self:GetBrightness() * .1 )
				local c = self:GetLightColor():ToColor()
				spr:Fire( "ColorRedValue", c.r )
				spr:Fire( "ColorGreenValue", c.g )
				spr:Fire( "ColorBlueValue", c.b )
			end
		end
	end
	function ENT:KeyValue( k, v )
		k = string.lower( k )
		if self:SetNetworkKeyValue( k, v ) then return end
		if k == "brightness" then self:SetBrightness( v )
		elseif k == "color" || k == "lightcolor" then
			local t = {}
			for n in string.gmatch( v, "%S+" ) do table.insert( t, ( tonumber( n ) || 255 ) * .003921568627451 ) end
			self:SetLightColor( Vector( t[ 1 ], t[ 2 ], t[ 3 ] ) )
			if t[ 4 ] then self:SetBrightness( t[ 4 ] ) end
		elseif k == "horfov" then self:SetHorFOV( v )
		elseif k == "verfov" then self:SetVerFOV( v )
		elseif k == "fov" || k == "lightfov" then self:SetHorFOV( v ) self:SetVerFOV( v )
		elseif k == "mindistance" || k == "nearz" then self:SetMinDistance( v )
		elseif k == "distance" || k == "farz" then self:SetDistance( v )
		elseif k == "texture" then self:SetTexture( v )
		elseif k == "shadows" || k == "shadowquality" then self:SetShadows( v == "1" )
		elseif k == "spritesize" then self:SetSpriteSize( tonumber( v ) || 0 )
		elseif k == "spritedisabled" then self:SetSpriteDisabled( v == "1" ) end
	end
	function ENT:AcceptInput( k, _, _, v )
		k = string.lower( k )
		if k == "settexture" || k == "spotlighttexture" then self:SetTexture( v )
		elseif k == "setbrightness" then self:SetBrightness( v )
		elseif k == "setlightcolor" || k == "setcolor" then
			local t = {}
			for n in string.gmatch( v, "%S+" ) do table.insert( t, ( tonumber( n ) || 255 ) * 0.003921568627451 ) end
			self:SetLightColor( Vector( t[ 1 ], t[ 2 ], t[ 3 ] ) )
			if t[ 4 ] then self:SetBrightness( t[ 4 ] ) end
		elseif k == "setmindistance" || k == "setnearz" then self:SetMinDistance( v )
		elseif k == "setdistance" || k == "setfarz" then self:SetDistance( v )
		elseif k == "sethorfov" then self:SetHorFOV( v )
		elseif k == "setverfov" then self:SetVerFOV( v )
		elseif k == "setfov" || k == "fov" then self:SetHorFOV( v ) self:SetVerFOV( v )
		elseif k == "shadows"  ||  k  ==  "enableshadows" then self:SetShadows( v  ==  "1" )
		elseif k == "setspritesize" then self:SetSpriteSize(tonumber( v ) || 0)
		elseif k == "setspritedisabled" then self:SetSpriteDisabled(tonumber( v )) end
	end
end
