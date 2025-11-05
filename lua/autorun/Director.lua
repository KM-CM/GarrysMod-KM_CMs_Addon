/*NOTE: Pitch Shifting is Not Supported for Now!
Do NOT Use CSoundPatch::ChangePitch UnTil It is Implemented,
Because when It is ( and if It is ) - It Might Break!*/

local sound_Add = sound.Add
sound_Add {
	name = "FlashlightOn",
	sound = "buttons/lightswitch2.wav",
	level = 40,
	volume = 1,
	channel = CHAN_AUTO
}
sound_Add {
	name = "FlashlightOff",
	sound = "buttons/lightswitch2.wav",
	level = 40,
	volume = 1,
	channel = CHAN_AUTO
}
function Director_RegisterNonStandardMusicSound( Name, Path )
	Name = "MUS_" .. Name
	sound_Add {
		name = Name,
		sound = Path,
		level = 0,
		volume = 1,
		channel = CHAN_STATIC
	}
	return Name, Path
end
function Director_RegisterMusicSound( Name, Path ) return Director_RegisterNonStandardMusicSound( Name, "Music/" .. Path ) end

DIRECTOR_THREAT_NULL = 0 // Nothing
DIRECTOR_THREAT_HEAT = 1 // Hostiles nearby
DIRECTOR_THREAT_ALERT = 2 // Things are alerted or searching
DIRECTOR_THREAT_COMBAT = 3 // Things are in combat
DIRECTOR_THREAT_TERROR = 4 // Things are in combat AND we're scared of them

if SERVER then

local _ThreatValueToName = {
	[ DIRECTOR_THREAT_NULL ] = "DIRECTOR_THREAT_NULL",
	[ DIRECTOR_THREAT_HEAT ] = "DIRECTOR_THREAT_HEAT",
	[ DIRECTOR_THREAT_ALERT ] = "DIRECTOR_THREAT_ALERT",
	[ DIRECTOR_THREAT_COMBAT ] = "DIRECTOR_THREAT_COMBAT",
	[ DIRECTOR_THREAT_TERROR ] = "DIRECTOR_THREAT_TERROR"
}
function Director_ThreatValueToName( n ) return _ThreatValueToName[ n ] || "DIRECTOR_THREAT_NULL" end

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

function Director_UpdateAwareness( ply, ent )
	local t = Director_GetThreat( ply, ent )
	if ply.DR_tMusicEntities && t > DIRECTOR_THREAT_NULL then ply.DR_tMusicEntities[ ent ] = true end
	if t > ( ply.DR_ThreatAware || 0 ) then ply.DR_ThreatAware = t end
	if t > ( ply.DR_Threat || 0 ) then ply.DR_Threat = t end
	return t
end

DIRECTOR_MUSIC_TABLE = DIRECTOR_MUSIC_TABLE || {
	[ DIRECTOR_THREAT_NULL ] = {},
	[ DIRECTOR_THREAT_HEAT ] = {},
	[ DIRECTOR_THREAT_ALERT ] = {},
	[ DIRECTOR_THREAT_COMBAT ] = {},
	[ DIRECTOR_THREAT_TERROR ] = {}
}
local DIRECTOR_MUSIC_TABLE = DIRECTOR_MUSIC_TABLE

local _reg = debug.getregistry()
local CDirectorMusicPlayer = _reg.DirectorMusicPlayer || {}
_reg.DirectorMusicPlayer = CDirectorMusicPlayer
// __index is NOT Used and I am Adding This Here Just in Case You have a Great But Schizophrenic Idea!
CDirectorMusicPlayer.__index = CDirectorMusicPlayer

// Override This!
function CDirectorMusicPlayer:Tick() ErrorNoHaltWithStack "CDirectorMusicPlayer::Tick not overriden!" end

function CDirectorMusicPlayer:Length() return math.Rand( 0, 360 ) end

// Sheesh, That's a Long Ass Name!
function Director_CreateMusicPlayerFromTableInternal( ply, tbl, sSource )
	local self = setmetatable( {
		m_flVolume = 0,
		m_pOwner = ply,
		m_sSource = sSource,
		// flVolume is Completely Up to The User,
		// The Actual Volume is Chosen in CDirectorMusicPlayer::UpdateInternal
		tHandles = {}, // This One is Used for Public Handles and Uses The User's Custom Time
		m_tHandles = {} // This One is Used for Private Handles and Uses The Sound's True End Time
	}, { __index = function( self, Key )
		v = rawget( tbl, Key )
		if v == nil then return rawget( CDirectorMusicPlayer, Key )
		else return v end
	end } )
	return self
end

local SysTime = SysTime
local engine_TickInterval = engine.TickInterval
function CDirectorMusicPlayer:Play( Index, Sound, flVolume, flHandleLength, flActualLength )
	if !flActualLength then flActualLength = SoundDuration( sound.GetProperties( Sound ).sound ) end
	if !flHandleLength then flHandleLength = SoundDuration( sound.GetProperties( Sound ).sound ) end
	flVolume = flVolume || 1
	local ply = self.m_pOwner
	local f = RecipientFilter()
	f:AddPlayer( ply )
	Sound = CreateSound( ply, Sound, f )
	ply.GAME_bNextSoundMute = true
	Sound:Play()
	self.tHandles[ Index ] = { Sound, SysTime() + flHandleLength - engine_TickInterval() * 2 }
	self.m_tHandles[ Index ] = { Sound, flVolume, SysTime() + ( flActualLength || flHandleLength ) }
	self:UpdateInternal()
	return Sound // Just in Case
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

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

local VectorZ28 = Vector( 0, 0, 28 )
hook.Add( "Tick", "Director", function()
	for _, ply in player_Iterator() do
		local PlyTable = CEntity_GetTable( ply )
		local v = __PLAYER_MODEL__[ ply:GetModel() ]
		if v then
			v = v.Think
			if v then v( ply, PlyTable ) end
		end
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
		ply:SetNW2Float( "GAME_flOxygenLimit", ply.GAME_flOxygenLimit || 30 )
		if ply:Alive() then
			local o = ply:GetNW2Float( "GAME_flOxygen", -1 )
			if o == 0 then
				ply:SetHealth( 0 )
				local d = DamageInfo()
				d:SetAttacker( ply )
				d:SetInflictor( ply )
				d:SetDamage( 1 )
				d:SetDamageType( DMG_DROWN )
				ply:TakeDamageInfo( d )
				continue
			end
			if ply:WaterLevel() >= 3 then
				ply:SetNW2Float( "GAME_flOxygen", math.Clamp( ply:GetNW2Float( "GAME_flOxygen", 0 ) - FrameTime(), 0, ply:GetNW2Float( "GAME_flOxygenLimit", -1 ) ) )
			else
				ply:SetNW2Float( "GAME_flOxygen", math.Clamp( ply:GetNW2Float( "GAME_flOxygen", 0 ) + FrameTime() * ( ply.GAME_flOxygenRegen || ( ply:GetNW2Float( "GAME_flOxygenLimit", 0 ) * .5 ) ), 0, ply:GetNW2Float( "GAME_flOxygenLimit", 0 ) ) )
			end
		else ply:SetNW2Float( "GAME_flOxygen", ply:GetNW2Float( "GAME_flOxygenLimit", 0 ) ) end
		ply:SetViewOffset( ply:GetViewOffset() )
		ply:SetViewOffsetDucked( ply:GetViewOffsetDucked() )
		ply:SetCanZoom( false )
		local h = ply:Health() / ply:GetMaxHealth()
		ply:SetDSP( h <= .165 && 16 || h <= .33 && 15 || h <= .66 && 14 || 1 )
		if !PlyTable.DR_ThreatAware then PlyTable.DR_ThreatAware = DIRECTOR_THREAT_NULL end
		if !PlyTable.DR_Threat then PlyTable.DR_Threat = DIRECTOR_THREAT_NULL end
		// This is Used when a Theme Changes to CrossFade It
		if !PlyTable.DR_tShutMeUp then PlyTable.DR_tShutMeUp = {} end
		if !PlyTable.DR_tMusic then PlyTable.DR_tMusic = {} end
		if !PlyTable.DR_tMusicNext then PlyTable.DR_tMusicNext = {} end
		local tMusicEntities = {}
		PlyTable.GAME_flSuppression = math.Approach( PlyTable.GAME_flSuppression || 0, 0, math.max( ply:Health() * .3, ( PlyTable.GAME_flSuppression || 0 ) * .3 ) * FrameTime() )
		if CurTime() > ( ply.DR_flNextUpdate || 0 ) then
			local THREAT, flIntensity = DIRECTOR_THREAT_NULL, 0
			local vEye = ply:EyePos()
			for _, ent in ents_Iterator() do
				local bVisible = !util_TraceLine( {
					start = vEye,
					endpos = ent:GetPos() + ent:OBBCenter(),
					mask = MASK_VISIBLE_AND_NPCS,
					filter = { ply, ent }
				} ).Hit
				local b = bVisible
				if b then
					local c = ent:GetPos() + ent:OBBCenter()
					local e = ply:EyeAngles()
					local d = ( c - vEye ):Angle()
					if math.abs( math.AngleDifference( e.y, d.y ) ) > ply:GetFOV() then b = nil end
					if b then
						if math.abs( math.AngleDifference( e.p, d.p ) ) > ply:GetFOV() * .5625/*9 / 16*/ then b = nil end
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
			PlyTable.DR_flIntensity = math.Clamp( ( flIntensity + PlyTable.GAME_flSuppression ) / ( ply:Health() * ( PlyTable.GAME_flMaxIntensityHealthMultiplier || 4 ) ), 0, 1 )
			PlyTable.DR_Threat = THREAT
			if PlyTable.DR_ThreatAware > PlyTable.DR_Threat then PlyTable.DR_ThreatAware = PlyTable.DR_Threat end
			if PlyTable.DR_ThreatAware == DIRECTOR_THREAT_COMBAT && !table.IsEmpty( DIRECTOR_MUSIC_TABLE[ DIRECTOR_THREAT_TERROR ] ) &&
			( ply:Health() <= ply:GetMaxHealth() * .33 || !HasMeleeAttack( ply ) && !HasRangeAttack( ply ) ) then PlyTable.DR_ThreatAware = DIRECTOR_THREAT_TERROR end
			PlyTable.DR_flNextUpdate = CurTime() + math.Rand( .1, .2 )
			local f = ply:OBBMaxs().x * 2
			for ent in pairs( PlyTable.DR_tMusicEntities || {} ) do
				if !IsValid( ent ) then continue end
				local vTarget = ent:GetPos() + ent:OBBCenter()
				if util_TraceLine( {
					start = vEye + ( vTarget - vEye ):GetNormalized() * f,
					endpos = vTarget,
					mask = MASK_VISIBLE_AND_NPCS,
					filter = { ply, ent }
				} ).Fraction <= .66 then continue end
				if Director_UpdateAwareness( ply, ent ) <= DIRECTOR_THREAT_NULL then continue end
				tMusicEntities[ ent ] = true
			end
		end
		ply:SetNW2Int( "DR_ThreatAware", PlyTable.DR_ThreatAware )
		PlyTable.DR_tMusicEntities = tMusicEntities
		local ThreatAware, bLayer = PlyTable.DR_ThreatAware, true
		local tMusic = {}
		for l, s in pairs( PlyTable.DR_tMusic ) do
			s:Tick()
			if l == ThreatAware then
				bLayer = nil
				s:UpdateInternal( 1, DIRECTOR_CROSSFADE_SPEED * FrameTime() )
			else s:UpdateInternal( 0, DIRECTOR_CROSSFADE_SPEED * FrameTime() ) end
			if CurTime() > ( PlyTable.DR_tMusicNext[ l ] || 0 ) then
				local t, n = table.Random( DIRECTOR_MUSIC_TABLE[ l ] )
				if t then
					local b = true
					for mus in pairs( PlyTable.DR_tShutMeUp ) do if mus.m_sSource == n then b = nil break end end
					if b then
						for _, mus in pairs( PlyTable.DR_tMusic ) do if mus.m_sSource == n then b = nil break end end
						if b then
							bLayer = nil
							PlyTable.DR_tShutMeUp[ s ] = true
							local p = Director_CreateMusicPlayerFromTableInternal( ply, t, n )
							tMusic[ l ] = p
							PlyTable.DR_tMusicNext[ l ] = CurTime() + p:Length()
							continue
						else
							bLayer = nil
							tMusic[ l ] = s
							PlyTable.DR_tMusicNext[ l ] = CurTime() + s:Length()
						end
					end
				else
					bLayer = nil
					tMusic[ l ] = s
					PlyTable.DR_tMusicNext[ l ] = CurTime() + s:Length()
				end
			else tMusic[ l ] = s end
		end
		PlyTable.DR_tMusic = tMusic
		if bLayer && ThreatAware > DIRECTOR_THREAT_NULL then
			local t, n = table.Random( DIRECTOR_MUSIC_TABLE[ ThreatAware ] )
			if t then
				local b = true
				for mus in pairs( PlyTable.DR_tShutMeUp ) do if mus.m_sSource == n then b = nil break end end
				if b then for _, mus in pairs( PlyTable.DR_tMusic ) do if mus.m_sSource == n then b = nil break end end end
				if b then
					tMusic[ ThreatAware ] = Director_CreateMusicPlayerFromTableInternal( ply, t, n )
					PlyTable.DR_tMusicNext[ ThreatAware ] = CurTime() + tMusic[ ThreatAware ]:Length()
				end
			end
		end
		local tShutMeUp = {}
		for mus in pairs( PlyTable.DR_tShutMeUp ) do
			// If it is already quiet,
			if mus.m_flVolume <= 0 then
				// M U R D E R   I T
				continue
			end
			// Otherwise, play it so it doesn't get cut off
			mus:UpdateInternal( 0, DIRECTOR_CROSSFADE_SPEED * FrameTime() )
			mus:Tick()
			tShutMeUp[ mus ] = true
		end
		PlyTable.DR_tShutMeUp = tShutMeUp
	end
end )

hook.Add( "PostCleanupMap", "Director", function()
	for _, ply in player_Iterator() do
		table.Empty( ply.DR_tMusic )
		table.Empty( ply.DR_tMusicNext )
		table.Empty( ply.DR_tShutMeUp )
		ply:ConCommand "stopsound"
	end
end )

end // SERVER

// Do This Here so It'll be Shared
local CEntity = FindMetaTable "Entity"
local CEntity_LookupSequence = CEntity.LookupSequence
local CEntity_GetTable = CEntity.GetTable
local CEntity_GetNW2Bool = CEntity.GetNW2Bool
hook.Add( "CalcMainActivity", "GameImprovements", function( ply, vel )
	if IsValid( ply ) && CEntity_GetNW2Bool( ply, "CTRL_bSliding" ) then
		local a = ACT_MP_WALK
		ply.CalcIdeal = a
		local s = CEntity_LookupSequence( ply, CEntity_GetTable( ply ).CTRL_sSlidingSequence || "zombie_slump_idle_02" )
		ply.CalcSeqOverride = s
		return a, s
	end
end )

if SERVER then
	function Director_CreateSimpleMusicPlayer( iCat, sName, sPath, flLength )
		local sActualName = Director_RegisterNonStandardMusicSound( sName, "Music/" .. sPath .. ".wav" )
		local t = {
			Tick = function( self )
				if !self.tHandles.Main then
					self:Play( "Main", sActualName, 1, flLength )
				end
			end
		}
		DIRECTOR_MUSIC_TABLE[ iCat ][ sName ] = t
		return t
	end
else function Director_CreateSimpleMusicPlayer( _, sName, sPath, _ ) Director_RegisterNonStandardMusicSound( sName, "Music/" .. sPath .. ".wav" ) end end

for _, n in ipairs( file.Find( "Director/*.lua", "LUA" ) ) do ProtectedCall( function() include( "Director/" .. n ) end ) end
