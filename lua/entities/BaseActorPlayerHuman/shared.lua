AddCSLuaFile()
DEFINE_BASECLASS "BaseActorPlayer"

local VOICE_PITCH = { 90, 110 }

sound.Add {
	name = "Human_TakeCover",
	channel = CHAN_VOICE,
	level = 150,
	pitch = VOICE_PITCH,
	sound = {
		"vo/npc/male01/takecover02.wav"
	}
}

sound.Add {
	name = "Human_Retreat",
	channel = CHAN_VOICE,
	level = 150,
	pitch = VOICE_PITCH,
	sound = {
		"vo/npc/male01/gethellout.wav",
		"vo/npc/male01/runforyourlife01.wav",
		"vo/npc/male01/runforyourlife02.wav",
		"vo/npc/male01/runforyourlife03.wav"
	}
}

sound.Add {
	name = "Human_CombatFormation",
	channel = CHAN_VOICE,
	level = 150,
	pitch = VOICE_PITCH,
	sound = {
		"vo/npc/male01/takecover02.wav",
		"vo/npc/male01/squad_away02.wav",
		"vo/npc/male01/squad_away03.wav"
	}
}
sound.Add {
	name = "Human_CombatFormationReady",
	channel = CHAN_VOICE,
	level = 150,
	pitch = VOICE_PITCH,
	sound = {
		"vo/npc/male01/leadtheway01.wav",
		"vo/npc/male01/leadtheway02.wav",
		"vo/npc/male01/readywhenyouare01.wav",
		"vo/npc/male01/readywhenyouare02.wav",
		"vo/npc/male01/okimready03.wav"
	}
}
sound.Add {
	name = "Human_CombatFormationMove",
	channel = CHAN_VOICE,
	level = 150,
	pitch = VOICE_PITCH,
	sound = {
		"vo/npc/male01/letsgo01.wav",
		"vo/npc/male01/letsgo02.wav",
		"vo/npc/male01/squad_follow02.wav",
		"vo/npc/male01/squad_follow03.wav",
		"vo/npc/male01/squad_approach02.wav",
		"vo/npc/male01/squad_approach03.wav"
	}
}

if SERVER then
	local CEntity_EmitSound = FindMetaTable( "Entity" ).EmitSound

	function ENT:DLG_State_TakeCover() CEntity_EmitSound( self, "Human_TakeCover" ) end
	function ENT:DLG_State_Retreat() CEntity_EmitSound( self, "Human_Retreat" ) end

	function ENT:DLG_CombatFormationGeneral() CEntity_EmitSound( self, "Human_CombatFormation" ) end
	function ENT:DLG_CombatFormationReady() CEntity_EmitSound( self, "Human_CombatFormationReady" ) end
	function ENT:DLG_CombatFormationMove() CEntity_EmitSound( self, "Human_CombatFormationMove" ) end
end

scripted_ents.Register( ENT, "BaseActorPlayerHuman" )
