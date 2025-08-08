AddCSLuaFile()
DEFINE_BASECLASS "BaseActorPlayer"

local VOICE_PITCH = { 90, 110 }
sound.Add {
	name = "Human_TakeCover",
	channel = CHAN_VOICE,
	level = 150,
	pitch = VOICE_PITCH,
	sound = {
		"vo/npc/$gender01/takecover02.wav",
		"vo/npc/$gender01/getdown02.wav"
	}
}

local CEntity_EmitSound = FindMetaTable( "Entity" ).EmitSound

function ENT:DLG_TakeCoverGeneral() CEntity_EmitSound( self, "Human_TakeCover" ) end

scripted_ents.Register( ENT, "BaseActorPlayerHuman" )
