include "autorun/Director.lua"

local sound_Add = sound.Add
local CHAN_STATIC = CHAN_STATIC
function Director_Music( sName, sPath )
	sound_Add {
		name = sName,
		channel = CHAN_STATIC,
		level = 0,
		sound = sPath
	}
end

DIRECTOR_MUSIC_TABLE = DIRECTOR_MUSIC_TABLE || {
	[ DIRECTOR_THREAT_HEAT ] = {},
	[ DIRECTOR_THREAT_ALERT ] = {},
	[ DIRECTOR_THREAT_COMBAT ] = {},
}

function Director_Music_Container( sClass )
	return {
		tHandles = {},
		sClass = sClass,
		m_flVolume = 0
	}
end

local game_GetWorld = game.GetWorld
local table_insert = table.insert
function Director_Music_Play( self, Index, sName, flVolume, flPitch )
	local pSound = CreateSound( game_GetWorld(), sName )
	flVolume = flVolume || 1
	flPitch = flPitch || 100
	pSound:PlayEx( flVolume * self.m_flVolume, flPitch )
	self.tHandles[ Index ] = { pSound, RealTime() + SoundDuration( sound.GetProperties( sName ).sound ), flVolume, flPitch }
end

function Director_Music_UpdateInternal( self )
	local tNewHandles = {}
	local flVolume = self.m_flVolume
	for Index, tData in pairs( self.tHandles ) do
		if RealTime() > tData[ 2 ] then tData[ 1 ]:Stop() continue end
		tNewHandles[ Index ] = tData
		local pSound = tData[ 1 ]
		// pSound:SetDSP( 0 ) // TODO: Doesn't work! Find a way to make it work!
		pSound:ChangeVolume( flVolume * tData[ 3 ] )
		pSound:ChangePitch( tData[ 4 ] )
	end
	self.tHandles = tNewHandles
end

DIRECTOR_MUSIC_INTENSITY = 0 // Intensity right now
DIRECTOR_MUSIC_TENSION = 0 // General battle intensity

DIRECTOR_MUSIC_LAST_THREAT = DIRECTOR_MUSIC_LAST_THREAT || DIRECTOR_THREAT_NULL

local LocalPlayer = LocalPlayer
hook.Add( "RenderScreenspaceEffects", "Director", function()
	local ply = LocalPlayer()
end )
