AddCSLuaFile()
DEFINE_BASECLASS "BaseActorPlayer"

scripted_ents.Register( ENT, "CombineCivilProtection" )
scripted_ents.Alias( "npc_combine_s", "CombineCivilProtection" )

local VOICE_PITCH_MIN, VOICE_PITCH_MAX = 90, 110

ENT.CATEGORIZE = {
	Combine = true,
	CivilProtection = true
}

sound.Add {
	name = "Combine_CivilProtection_Death",
	channel = CHAN_VOICE,
	level = 150,
	pitch = { VOICE_PITCH_MIN, VOICE_PITCH_MAX },
	sound = {
		"npc/metropolice/die1.wav",
		"npc/metropolice/die2.wav",
		"npc/metropolice/die3.wav",
		"npc/metropolice/die4.wav"
	}
}

sound.Add {
	name = "Combine_CivilProtection_CombatFormationGeneral",
	channel = CHAN_VOICE,
	level = 150,
	pitch = { VOICE_PITCH_MIN, VOICE_PITCH_MAX },
	sound = {
		"npc/metropolice/vo/holdthisposition.wav"
	}
}
sound.Add {
	name = "Combine_CivilProtection_CombatFormationReady",
	channel = CHAN_VOICE,
	level = 150,
	pitch = { VOICE_PITCH_MIN, VOICE_PITCH_MAX },
	sound = {
		"npc/metropolice/vo/inpositiononeready.wav",
		"npc/metropolice/vo/inpositionathardpoint.wav",
		"npc/metropolice/vo/inposition.wav",
		"npc/metropolice/vo/isreadytogo.wav"
	}
}
sound.Add {
	name = "Combine_CivilProtection_CombatFormationMove",
	channel = CHAN_VOICE,
	level = 150,
	pitch = { VOICE_PITCH_MIN, VOICE_PITCH_MAX },
	sound = {
		"npc/metropolice/vo/moveit.wav",
		"npc/metropolice/vo/moveit2.wav",
		"npc/metropolice/vo/teaminpositionadvance.wav",
		"npc/metropolice/vo/allunitscloseonsuspect.wav",
		"npc/metropolice/vo/allunitsmovein.wav",
		"npc/overwatch/radiovoice/allunitsapplyforwardpressure.wav"
	}
}
sound.Add {
	name = "Combine_CivilProtection_TakeCoverGeneral",
	channel = CHAN_VOICE,
	level = 150,
	pitch = { VOICE_PITCH_MIN, VOICE_PITCH_MAX },
	sound = {
		"npc/metropolice/vo/takecover.wav",
		"npc/metropolice/vo/movingtocover.wav",
		"npc/metropolice/vo/backmeupimout.wav",
		"npc/metropolice/vo/moveit.wav"
	}
}

list.Set( "NPC", "npc_metropolice", {
	Name = "#CombineCivilProtection",
	Class = "CombineCivilProtection",
	Category = "Combine",
	Weapons = {
		"weapon_pistol,weapon_smg1",
		"weapon_pistol"
	}
} )

if !SERVER then return end

local CEntity_EmitSound = FindMetaTable( "Entity" ).EmitSound

function ENT:DLG_CombatFormationGeneral() CEntity_EmitSound( self, "Combine_CivilProtection_CombatFormationGeneral" ) end
function ENT:DLG_CombatFormationReady() CEntity_EmitSound( self, "Combine_CivilProtection_CombatFormationReady" ) end
function ENT:DLG_CombatFormationMove() CEntity_EmitSound( self, "Combine_CivilProtection_CombatFormationMove" ) end
function ENT:DLG_TakeCoverGeneral() CEntity_EmitSound( self, "Combine_CivilProtection_TakeCoverGeneral" ) end

ENT.iDefaultClass = CLASS_COMBINE

function ENT:Initialize()
	self:SetModel( math.random( 3 ) == 1 && "models/player/police_fem.mdl" || "models/player/police.mdl" )
	self:SetHealth( 150 )
	self:SetMaxHealth( 150 )
	self:SetPlayerColor( Vector( 0, 0, 0 ) )
	BaseClass.Initialize( self )
end

function ENT:OnKilled( ... )
	CEntity_EmitSound( self, "Combine_CivilProtection_Death" )
	return BaseClass.OnKilled( self, ... )
end
