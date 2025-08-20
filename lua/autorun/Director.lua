/*NOTE: Pitch Shifting is Not Supported for Now!
Do NOT Use CSoundPatch::ChangePitch UnTil It is Implemented,
Because when It is ( and if It is ) - It Might Break!*/

function Director_RegisterMusicSound( Name, Path )
	sound.Add {
		name = "MUS_" .. Name,
		sound = "Music/" .. Path,
		level = 0,
		volume = 1,
		channel = CHAN_STATIC
	}
end
function Director_RegisterNonStandardMusicSound( Name, Path )
	sound.Add {
		name = "MUS_" .. Name,
		sound = Path,
		level = 0,
		volume = 1,
		channel = CHAN_STATIC
	}
end

if SERVER then

DIRECTOR_THREAT_NULL = 0 //Nothing
DIRECTOR_THREAT_HEAT = 1 //Hostiles Nearby
DIRECTOR_THREAT_ALERT = 2 //Things are Alerted or Searching
DIRECTOR_THREAT_COMBAT = 3 //Things are in Combat

local _ThreatValueToName = {
	[ DIRECTOR_THREAT_NULL ] = "DIRECTOR_THREAT_NULL",
	[ DIRECTOR_THREAT_HEAT ] = "DIRECTOR_THREAT_HEAT",
	[ DIRECTOR_THREAT_ALERT ] = "DIRECTOR_THREAT_ALERT",
	[ DIRECTOR_THREAT_COMBAT ] = "DIRECTOR_THREAT_COMBAT"
}
function Director_ThreatValueToName( n ) return _ThreatValueToName[ n ] || "DIRECTOR_THREAT_NULL" end

local Director_Debug = CreateConVar( "Director_Debug", 0, FCVAR_CHEAT + FCVAR_NEVER_AS_STRING, "", 0, 1 )
local Player_Debug_EyeOffset = CreateConVar( "Player_Debug_EyeOffset", 0, FCVAR_CHEAT + FCVAR_NEVER_AS_STRING, "", 0, 1 )

function Director_GetThreat( ply, ent )
	if ent.GetEnemy && IsValid( ent:GetEnemy() ) then
		return DIRECTOR_THREAT_COMBAT
	else
		if ent.GetNPCState && ent:GetNPCState() == NPC_STATE_ALERT then
			return DIRECTOR_THREAT_ALERT
		end
		if ent.Disposition then
			local d = ent:Disposition( ply )
			if d == D_HT || d == D_FR then return DIRECTOR_THREAT_HEAT end
		end
		return DIRECTOR_THREAT_NULL
	end
end

DIRECTOR_STOP_THREAT_TIME = 12

function Director_UpdateAwareness( ply, ent )
	local t = Director_GetThreat( ply, ent )
	if ply.DR_tMusicEntities && t > DIRECTOR_THREAT_NULL then ply.DR_tMusicEntities[ ent ] = true end
	if t > ( ply.DR_ThreatAware || 0 ) then ply.DR_ThreatAware = t end
	if t > ( ply.DR_Threat || 0 ) then ply.DR_Threat = t end
	local v = ply.DR_tStopThreat
	if v then v[ t ] = CurTime() + DIRECTOR_STOP_THREAT_TIME end
	return t
end

DIRECTOR_MUSIC_TABLE = DIRECTOR_MUSIC_TABLE || {
	[ DIRECTOR_THREAT_NULL ] = {},
	[ DIRECTOR_THREAT_HEAT ] = {},
	[ DIRECTOR_THREAT_ALERT ] = {},
	[ DIRECTOR_THREAT_COMBAT ] = {}
}
local DIRECTOR_MUSIC_TABLE = DIRECTOR_MUSIC_TABLE

local _reg = debug.getregistry()
local CDirectorMusicPlayer = _reg.CDirectorMusicPlayer || {}
_reg.CDirectorMusicPlayer = CDirectorMusicPlayer
//__index is NOT Used and I am Adding This Here Just in Case You have a Great But Schizophrenic Idea!
CDirectorMusicPlayer.__index = CDirectorMusicPlayer

//Override This!
function CDirectorMusicPlayer:Tick() ErrorNoHaltWithStack "CDirectorMusicPlayer::Tick Not Overriden!" end

function CDirectorMusicPlayer:Length() return math.Rand( 0, 360 ) end

//Sheesh, That's a Long Ass Name!
function Director_CreateMusicPlayerFromTableInternal( ply, tbl )
	local self = setmetatable( {
		m_flVolume = 0,
		m_pOwner = ply,
		m_pSource = tbl,
		//flVolume is Completely Up to The User,
		//The Actual Volume is Chosen in CDirectorMusicPlayer::UpdateInternal
		tHandles = {}, //This One is Used for Public Handles and Uses The User's Custom Time
		m_tHandles = {} //This One is Used for Private Handles and Uses The Sound's True End Time
	}, { __index = function( self, Key )
		v = rawget( tbl, Key )
		if v == nil then return rawget( CDirectorMusicPlayer, Key )
		else return v end
	end } )
	return self
end

function CDirectorMusicPlayer:StopAll()
	if Director_Debug:GetBool() then print "CDirectorMusicPlayer::StopAll" end
	for _, d in pairs( self.m_tHandles ) do d[ 1 ]:Stop() end
	table.Empty( self.tHandles )
	table.Empty( self.m_tHandles )
end

local SysTime = SysTime
function CDirectorMusicPlayer:Play( Index, Sound, flVolume, flHandleLength, flActualLength )
	if Director_Debug:GetBool() then
		print "<CDirectorMusicPlayer::Play>"
		print( "\tIndex: " .. tostring( Index ) )
		print( "\tSound: " .. tostring( Sound ) )
		print( "\tflVolume: " .. tostring( flVolume ) )
		print( "\tflHandleLength: " .. tostring( flHandleLength ) )
		print( "\tflActualLength: " .. tostring( flActualLength ) )
		print "</CDirectorMusicPlayer::Play>"
	end
	local ply = self.m_pOwner
	local f = RecipientFilter()
	f:AddPlayer( ply )
	Sound = CreateSound( ply, Sound, f )
	ply.GAME_bNextSoundMute = true
	Sound:Play()
	self.tHandles[ Index ] = { Sound, SysTime() + flHandleLength }
	self.m_tHandles[ Index ] = { Sound, flVolume || 1, SysTime() + ( flActualLength || flHandleLength ) }
	self:UpdateInternal()
	return Sound //Just in Case
end

function CDirectorMusicPlayer:ApproachVolume( Index, flVolume, flSpeed )
	local t = self.m_tHandles[ Index ]
	if t then
		t[ 2 ] = math.Approach( t[ 2 ], flVolume || 0, flSpeed || 1 )
		self:UpdateInternal()
		return t[ 2 ]
	end
end

function CDirectorMusicPlayer:GetVolume( Index )
	local t = self.m_tHandles[ Index ]
	if t then return t[ 2 ] end
end

function CDirectorMusicPlayer:GetIntensity() return self.m_pOwner.DR_flIntensity || 0 end

DIRECTOR_CROSSFADE_SPEED = .08

function CDirectorMusicPlayer:UpdateInternal( f, s )
	local flVolume = math.Approach( self.m_flVolume, f || self.m_flVolume, s || 1 )
	self.m_flVolume = flVolume
	local tHandles = {}
	for i, d in pairs( self.tHandles ) do
		if SysTime() > d[ 2 ] then d[ 1 ]:Stop() continue end
		tHandles[ i ] = d
	end
	self.tHandles = tHandles
	local m_tHandles = {}
	for i, d in pairs( self.m_tHandles ) do
		if SysTime() > d[ 3 ] then d[ 1 ]:Stop() continue end
		local s = d[ 1 ]
		s:ChangeVolume( math.Clamp( .03, d[ 2 ] * flVolume, 1 ) )
		m_tHandles[ i ] = d
	end
	self.m_tHandles = m_tHandles
end

local player_Iterator, ents_Iterator, util_TraceLine = player.Iterator, ents.Iterator, util.TraceLine

DIRECTOR_MELEE_DANGER = 2

local VectorZ28 = Vector( 0, 0, 28 )
hook.Add( "Tick", "Director", function() //Important - We Need Tick and Not Think!
	for _, ply in player_Iterator() do
		if Player_Debug_EyeOffset:GetBool() then
			if ply:GetViewOffsetDucked() == VectorZ28 then
				ply:SetViewOffsetDucked( Vector( 0, 0, 42 ) )
			end
			local dir = ply:EyeAngles()
			dir.p = 0
			dir = dir:Forward()
			local flDist = ply:OBBMaxs().x * 2
			local v = ply:GetPos() + ply:GetViewOffset()
			debugoverlay.Line( v, v + dir * flDist, .1, Color( 128, 128, 255 ), true )
			local v = ply:GetPos() + ply:GetViewOffsetDucked()
			debugoverlay.Line( v, v + dir * flDist, .1, Color( 128, 128, 255 ), true )
		end
		ply:SetViewOffset( ply:GetViewOffset() )
		ply:SetViewOffsetDucked( ply:GetViewOffsetDucked() )
		ply:SetCanZoom( false )
		ply:SetDuckSpeed( .25 )
		ply:SetUnDuckSpeed( .25 )
		local h = ply:Health() / ply:GetMaxHealth()
		ply:SetDSP( h <= .165 && 16 || h <= .33 && 15 || h <= .66 && 14 || 1 )
		if !ply.DR_ThreatAware then ply.DR_ThreatAware = DIRECTOR_THREAT_NULL end
		if !ply.DR_Threat then ply.DR_Threat = DIRECTOR_THREAT_NULL end
		//This is Used when a Theme Changes to CrossFade It
		if !ply.DR_tShutMeUp then ply.DR_tShutMeUp = {} end
		if !ply.DR_tMusic then ply.DR_tMusic = {} end
		if !ply.DR_tMusicNext then ply.DR_tMusicNext = {} end
		if !ply.DR_tStopThreat then ply.DR_tStopThreat = {} end
		/*This is Made so The Music Doesnt Stop when We're Running Backwards to Whoever is Chasing Us,
		Because Technically, We Dont See Him, But The Human Brain is on Average More Aware Than a Mote of Dust,
		so It Approximates Where The Chaser is, Even While Moving Backwards and Not Seeing Him.*/
		local tMusicEntities = {}
		//Why Did I Put This Here? This Needs to be Lower
		//ply.DR_tMusicEntities = tMusicEntities
		ply.GAME_flSuppression = math.Approach( ply.GAME_flSuppression || 0, 0, math.max( ply:Health() * .3, ( ply.GAME_flSuppression || 0 ) * .3 ) * FrameTime() )
		if CurTime() > ( ply.DR_flNextUpdate || 0 ) then
			local THREAT, flIntensity = DIRECTOR_THREAT_NULL, 0
			for _, ent in ents_Iterator() do
				local bVisible = util_TraceLine( {
					start = ply:EyePos(),
					endpos = ent:GetPos() + ent:OBBCenter(),
					mask = MASK_VISIBLE_AND_NPCS,
					filter = { ply, ent }
				} ).HitPos:DistToSqr( ent:GetPos() + ent:OBBCenter() ) <= 262144
				local b = bVisible
				if b then
					local c = ent:GetPos() + ent:OBBCenter()
					local e = ply:EyeAngles()
					local d = ( c - ply:EyePos() ):Angle()
					if math.abs( math.AngleDifference( e.y, d.y ) ) > ply:GetFOV() then b = nil end
					if b then
						if math.abs( math.AngleDifference( e.p, d.p ) ) > ply:GetFOV() * .5625/*9:16*/ then b = nil end
					end
				end
				if b then Director_UpdateAwareness( ply, ent ) end
				if !bVisible && ent:GetPos():DistToSqr( ply:GetPos() ) > 16777216/*4096*/ then continue end
				local t = Director_GetThreat( ply, ent )
				if t > THREAT then THREAT = t end
				if t > 0 then
					local h = ent:Health()
					local a = 0
					if bVisible && HasMeleeAttack( ent ) then
						local d = ply:GetPos():Distance( ent:GetPos() )
						if d < 384 then
							a = a + h * DIRECTOR_MELEE_DANGER
						elseif d < 512 then
							a = a + h * math.Remap( d, 384, 768, DIRECTOR_MELEE_DANGER, 1 )
						elseif d < 1024 then
							a = a + h * math.Remap( d, 512, 1024, 1, 0 )
						end
					end
					flIntensity = flIntensity + math.max( a, ent.DR_bMusicActive && h || 0 )
				end
			end
			ply.DR_flIntensity = math.Clamp( ( flIntensity + ply.GAME_flSuppression ) / ( ply:Health() * ( ply.GAME_flMaxIntensityHealthMultiplier || 4 ) ), 0, 1 )
			ply.DR_Threat = THREAT
			if ply.DR_ThreatAware > ply.DR_Threat then ply.DR_ThreatAware = ply.DR_Threat end
			ply.DR_flNextUpdate = CurTime() + math.Rand( .1, .2 )
			for ent in pairs( ply.DR_tMusicEntities || {} ) do
				if IsValid( ent ) && util_TraceLine( {
					start = ply:EyePos(),
					endpos = ent:GetPos() + ent:OBBCenter(),
					mask = MASK_VISIBLE_AND_NPCS,
					filter = { ply, ent }
				} ).HitPos:DistToSqr( ent:GetPos() + ent:OBBCenter() ) <= 262144/*512*/ then
					if Director_UpdateAwareness( ply, ent ) <= DIRECTOR_THREAT_NULL then continue end
					tMusicEntities[ ent ] = true
				end
			end
		end
		//Lower Here, if You Even Read The Comment Above
		ply.DR_tMusicEntities = tMusicEntities
		local ThreatAware, bLayerFound, bNoLayer = ply.DR_ThreatAware
		local tMusic = {}
		for l, s in pairs( ply.DR_tMusic ) do
			s:Tick()
			if l == ThreatAware then
				bLayerFound = true
				s:UpdateInternal( 1, DIRECTOR_CROSSFADE_SPEED * FrameTime() )
			else s:UpdateInternal( 0, DIRECTOR_CROSSFADE_SPEED * FrameTime() ) end
			if CurTime() > ( ply.DR_tMusicNext[ l ] || 0 ) then
				local t = table.Random( DIRECTOR_MUSIC_TABLE[ l ] )
				if t then
					local b = true
					for mus in pairs( ply.DR_tShutMeUp ) do if mus.m_pSource == t then b = nil break end end
					if b then for _, mus in pairs( ply.DR_tMusic ) do if mus.m_pSource == t then b = nil break end end end
					if b then
						if Director_Debug:GetBool() then print( "Next Track of Type " .. Director_ThreatValueToName( l ) ) end
						ply.DR_tShutMeUp[ s ] = true
						tMusic[ l ] = Director_CreateMusicPlayerFromTableInternal( ply, t )
						ply.DR_tMusicNext[ l ] = CurTime() + tMusic[ l ]:Length()
					else
						bNoLayer = true
						if Director_Debug:GetBool() then print( "No Next Track of Type " .. Director_ThreatValueToName( l ) ) end
						ply.DR_tMusicNext[ l ] = CurTime() + s:Length()
					end
					continue
				else
					bNoLayer = true
					//if Director_Debug:GetBool() then print( "No Next Track of Type " .. Director_ThreatValueToName( l ) ) end
					tMusic[ l ] = s
					ply.DR_tMusicNext[ l ] = CurTime() + ply.DR_tMusic[ l ]:Length()
				end
			end
			tMusic[ l ] = s
		end
		ply.DR_tMusic = tMusic
		if !bLayerFound && !bNoLayer && ThreatAware > DIRECTOR_THREAT_NULL then
			local t = table.Random( DIRECTOR_MUSIC_TABLE[ ThreatAware ] )
			if t then
				local b = true
				for mus in pairs( ply.DR_tShutMeUp ) do if mus.m_pSource == t then b = nil break end end
				if b then for _, mus in pairs( ply.DR_tMusic ) do if mus.m_pSource == t then b = nil break end end end
				if b then
					if Director_Debug:GetBool() then print( "Creating New Track for Layer " .. Director_ThreatValueToName( ThreatAware ) ) end
					tMusic[ ThreatAware ] = Director_CreateMusicPlayerFromTableInternal( ply, t )
					ply.DR_tMusicNext[ ThreatAware ] = CurTime() + tMusic[ ThreatAware ]:Length()
				end
			elseif Director_Debug:GetBool() then print( "No Next Track for Layer " .. Director_ThreatValueToName( l ) ) end
		end
		local t, bLayerFound = {}
		for lv, tm in pairs( ply.DR_tStopThreat ) do
			if lv == ThreatAware then
				if CurTime() > tm then
					bLayerFound = true
					t[ ThreatAware ] = nil
					ply.DR_ThreatAware = math.Clamp( ply.DR_ThreatAware - 1, DIRECTOR_THREAT_NULL, DIRECTOR_THREAT_COMBAT )
				end
			else t[ lv ] = CurTime() + DIRECTOR_STOP_THREAT_TIME end
		end
		if !bLayerFound then t[ ThreatAware ] = CurTime() + DIRECTOR_STOP_THREAT_TIME end
		ply.DR_tStopThreat = t
		local tShutMeUp = {}
		for mus in pairs( ply.DR_tShutMeUp ) do
			mus:UpdateInternal( 0, DIRECTOR_CROSSFADE_SPEED * FrameTime() )
			//If It is Already Quiet,
			if mus.m_flVolume <= 0 then
				if Director_Debug:GetBool() then print "Removing a DR_tShutMeUp Track ( m_flVolume <= 0 )" end
				//M U R D E R   I T
				mus:StopAll()
			else mus:Tick() tShutMeUp[ mus ] = true end //OtherWise, Play It so It Doesnt Get Cut Off
		end
		ply.DR_tShutMeUp = tShutMeUp
	end
end )

end //SERVER

for _, n in ipairs( file.Find( "Director/*.lua", "LUA" ) ) do ProtectedCall( function() include( "Director/" .. n ) end ) end

if !SERVER then return end

if IsMounted "left4dead2" then
	Director_RegisterNonStandardMusicSound( "Default_Left4Dead2_Horde_Slayer_Electric", "music/zombat/slayer/lectric/slayer_01a.wav" )
	Director_RegisterNonStandardMusicSound( "Default_Left4Dead2_Horde_Drums1", "music/zombat/horde/drums01b.wav" )
	Director_RegisterNonStandardMusicSound( "Default_Left4Dead2_Horde_Drums2", "music/zombat/horde/drums01c.wav" )
	Director_RegisterNonStandardMusicSound( "Default_Left4Dead2_Horde_Drums3", "music/zombat/horde/drums01d.wav" )
	local math_random = math.random
	DIRECTOR_MUSIC_TABLE[ DIRECTOR_THREAT_COMBAT ].Default_Left4Dead2_Horde = {
		flBlockLength = 5.627,
		Tick = function( self )
			if !self.tHandles.Drums then
				self:Play( "Drums", "MUS_Default_Left4Dead2_Horde_Drums" .. tostring( math_random( 3 ) ), 1, 5.627 )
				self:Play( "Slayer", "MUS_Default_Left4Dead2_Horde_Slayer_Electric", self.flSlayerVolume || 0, 5.627 )
			end
			self.flSlayerVolume = self:ApproachVolume( "Slayer", self:GetIntensity(), .4 * FrameTime() )
		end
	}
end
