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

function Director_Music_Container()
	return {
		tHandles = {},
		m_flVolume = 0
	}
end

local LocalPlayer = LocalPlayer
// local game_GetWorld = game.GetWorld
local table_insert = table.insert
function Director_Music_Play( self, Index, sName, flVolume, flPitch )
	// local pSound = CreateSound( game_GetWorld(), sName )
	local pSound = CreateSound( LocalPlayer(), sName )
	flVolume = flVolume || 1
	flPitch = flPitch || 100
	pSound:PlayEx( flVolume * self.m_flVolume, flPitch )
	self.tHandles[ Index ] = { pSound, flVolume, flPitch, RealTime() + SoundDuration( sound.GetProperties( sName ).sound ) - engine.TickInterval() }
end

Director_Music( "MUS_TransitionTo_Instant", "Music/Default/Transition_Instant.wav" )

DIRECTOR_MUSIC_TRANSITIONS_TO_COMBAT = DIRECTOR_MUSIC_TRANSITIONS_TO_COMBAT || {}
DIRECTOR_MUSIC_TRANSITIONS_FROM_COMBAT = DIRECTOR_MUSIC_TRANSITIONS_FROM_COMBAT || {}
DIRECTOR_MUSIC_TRANSITIONS_TO_COMBAT.Default_Instant = function( self )
	if !self.tHandles.Main then
		if self.bPartStarted then
			self.sIndex = "Idle"
			self.bPartStarted = nil
			self.bA = nil
			return true
		end
		self.bPartStarted = true
		Director_Music_Play( self, "Main", "MUS_TransitionTo_Instant" )
	end
	return false, 0, 1
end
DIRECTOR_MUSIC_TRANSITIONS_FROM_COMBAT.Default_Fade = function( self, flVolumeA, flVolumeB, bCorrect )
	if !bCorrect then return true end
	if flVolumeA > 0 then
		flVolumeA = flVolumeA < .1 && math.Approach( flVolumeA, 0, FrameTime() ) || Lerp( .1 * FrameTime(), flVolumeA, 0 )
		return false, flVolumeA, flVolumeB
	end
	if self.m_ELayerTo == DIRECTOR_THREAT_NULL then return true end
	if flVolumeB == 1 then return true end
	flVolumeB = flVolumeB > .9 && math.Approach( flVolumeB, 1, FrameTime() ) || Lerp( .1 * FrameTime(), flVolumeB, 1 )
	return false, 0, flVolumeB
end
function Director_Music_UpdateInternal( self, ... )
	local tNewHandles = {}
	local flVolume = self.m_flVolume
	for Index, tData in pairs( self.tHandles ) do
		if RealTime() > tData[ 4 ] then tData[ 1 ]:Stop() continue end
		tNewHandles[ Index ] = tData
		local pSound = tData[ 1 ]
		// pSound:SetDSP( 0 ) // TODO: Doesn't work! Find a way to make it work!
		pSound:ChangeVolume( math.max( .05, flVolume * tData[ 2 ] ) )
		pSound:ChangePitch( tData[ 3 ] )
	end
	self.tHandles = tNewHandles
	return self:m_fExecute( ... )
end

DIRECTOR_MUSIC_INTENSITY = 0 // Intensity right now
DIRECTOR_MUSIC_TENSION = 0 // General battle intensity

DIRECTOR_THREAT = DIRECTOR_THREAT || DIRECTOR_THREAT_NULL
DIRECTOR_MUSIC_LAST_THREAT = DIRECTOR_MUSIC_LAST_THREAT || DIRECTOR_THREAT_NULL

DIRECTOR_MUSIC = DIRECTOR_MUSIC || {}

function Director_VoiceLineHook(
		flDuration ) // sName - This is actually a String of the sound's name ( Data.SoundName )
	flDuration = SoundDuration( flDuration )
	if !flDuration then return end
	DIRECTOR_MUSIC_VO_TIME = RealTime() + math.min( flDuration, 8 ) + 1
	DIRECTOR_MUSIC_IN_VO = true
end

local LocalPlayer = LocalPlayer
hook.Add( "RenderScreenspaceEffects", "Director", function()
	local ply = LocalPlayer()
	for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
		if !DIRECTOR_MUSIC[ ELayer ] then
			local f = table.Random( DIRECTOR_MUSIC_TABLE[ ELayer ] )
			if f then
				local p = Director_Music_Container()
				p.m_fExecute = f.Execute
				p.m_pSource = f
				DIRECTOR_MUSIC[ ELayer ] = p
			end
		end
	end
	if !DIRECTOR_MUSIC[ DIRECTOR_THREAT_NULL ] then
		local p = Director_Music_Container()
		p.m_fExecute = function() end
		p.m_pSource = {}
		DIRECTOR_MUSIC[ DIRECTOR_THREAT_NULL ] = p
	end
	if DIRECTOR_MUSIC_IN_VO then
		DIRECTOR_MUSIC_LAST_THREAT = DIRECTOR_THREAT_COMBAT
		if RealTime() > DIRECTOR_MUSIC_VO_TIME then
			DIRECTOR_MUSIC_IN_VO = nil
			DIRECTOR_TRANSITION = nil
			for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
				local pContainer = DIRECTOR_MUSIC[ ELayer ]
				if pContainer then
					Director_Music_UpdateInternal( pContainer )
					if ELayer == DIRECTOR_THREAT_COMBAT then
						pContainer.m_flVolume = 1
					else pContainer.m_flVolume = 0 end
				end
			end
		else
			if DIRECTOR_TRANSITION then
				if DIRECTOR_TRANSITION.m_flVolume <= 0 then DIRECTOR_TRANSITION = nil end
				DIRECTOR_TRANSITION.m_flVolume = math.Approach( DIRECTOR_TRANSITION.m_flVolume, 0, FrameTime() )
			end
			for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
				local pContainer = DIRECTOR_MUSIC[ ELayer ]
				if pContainer then
					Director_Music_UpdateInternal( pContainer )
					pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, FrameTime() )
				end
			end
		end
		return
	end
	if DIRECTOR_TRANSITION then
		local b
		if DIRECTOR_TRANSITION.m_bToCombat then
			b = DIRECTOR_THREAT >= DIRECTOR_THREAT_COMBAT
		else b = DIRECTOR_THREAT < DIRECTOR_THREAT_COMBAT end
		local ELayerFrom, ELayerTo, flInitialVolumeA, flInitialVolumeB = DIRECTOR_TRANSITION.m_ELayerFrom, DIRECTOR_TRANSITION.m_ELayerTo
		for ELayer, pContainer in pairs( DIRECTOR_MUSIC ) do
			if ELayer == ELayerFrom then
				flInitialVolumeA = pContainer.m_flVolume
			elseif ELayer == ELayerTo then
				flInitialVolumeB = pContainer.m_flVolume
			end
			if flInitialVolumeA && flInitialVolumeB then break end
		end
		local bDone, flVolumeA, flVolumeB = Director_Music_UpdateInternal( DIRECTOR_TRANSITION, flInitialVolumeA || 0, flInitialVolumeB || 0, b )
		DIRECTOR_MUSIC_LAST_THREAT = ELayerTo
		if bDone then
			DIRECTOR_TRANSITION = nil
			flVolumeA = flVolumeA || 0
			flVolumeB = flVolumeB || 1
		else
			flVolumeA = flVolumeA || 0
			flVolumeB = flVolumeB || 0
		end
		for ELayer, pContainer in pairs( DIRECTOR_MUSIC ) do
			if pContainer then
				Director_Music_UpdateInternal( pContainer )
				if ELayer == ELayerFrom then
					pContainer.m_flVolume = flVolumeA
				elseif ELayer == ELayerTo then
					pContainer.m_flVolume = flVolumeB
				else
					pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, FrameTime() )
				end
			end
		end
		return
	end
	if DIRECTOR_MUSIC_LAST_THREAT < DIRECTOR_THREAT_COMBAT && DIRECTOR_THREAT >= DIRECTOR_THREAT_COMBAT then
		DIRECTOR_TRANSITION = Director_Music_Container()
		local t = table.Random( DIRECTOR_MUSIC_TRANSITIONS_TO_COMBAT )
		DIRECTOR_TRANSITION.m_fExecute = t.Execute
		DIRECTOR_TRANSITION.m_pSource = t
		DIRECTOR_TRANSITION.m_flVolume = 1
		DIRECTOR_TRANSITION.m_bToCombat = true
		DIRECTOR_TRANSITION.m_ELayerFrom = DIRECTOR_MUSIC_LAST_THREAT
		DIRECTOR_TRANSITION.m_ELayerTo = DIRECTOR_THREAT
		return
	elseif DIRECTOR_MUSIC_LAST_THREAT >= DIRECTOR_THREAT_COMBAT && DIRECTOR_THREAT < DIRECTOR_THREAT_COMBAT then
		DIRECTOR_TRANSITION = Director_Music_Container()
		local t = table.Random( DIRECTOR_MUSIC_TRANSITIONS_FROM_COMBAT )
		DIRECTOR_TRANSITION.m_fExecute = t.Execute
		DIRECTOR_TRANSITION.m_pSource = t
		DIRECTOR_TRANSITION.m_flVolume = 1
		DIRECTOR_TRANSITION.m_ELayerFrom = DIRECTOR_MUSIC_LAST_THREAT
		DIRECTOR_TRANSITION.m_ELayerTo = DIRECTOR_THREAT
		return
	end
	// Do NOT mistake this for the fade transition!
	// This is completely different, and used to fade between
	// idle/heat/alert tracks!
	for _, ELayer in ipairs( DIRECTOR_LAYER_TABLE ) do
		local pContainer = DIRECTOR_MUSIC[ ELayer ]
		if pContainer then
			Director_Music_UpdateInternal( pContainer )
			if ELayer == DIRECTOR_THREAT then
				pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 1, .1 * FrameTime() )
			else pContainer.m_flVolume = math.Approach( pContainer.m_flVolume, 0, .1 * FrameTime() ) end
		end
	end
end )

hook.Add( "PostCleanupMap", "Director", function()
	table.Empty( DIRECTOR_MUSIC )
	DIRECTOR_TRANSITION = nil
	DIRECTOR_MUSIC_LAST_THREAT = DIRECTOR_THREAT_NULL
end )
