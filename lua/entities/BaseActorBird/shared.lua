AddCSLuaFile()
DEFINE_BASECLASS "BaseActorAnimal"

sound.Add {
	name = "BaseActorBird_FlapLoopDefault",
	channel = CHAN_STATIC,
	volume = 1,
	level = 110,
	sound = "npc/crow/flap2.wav"
}
sound.Add {
	name = "BaseActorBird_SoarLoopDefault",
	channel = CHAN_STATIC,
	volume = 1,
	level = 110,
	sound = "vehicles/fast_windloop1.wav"
}

if SERVER then include "Server.lua" end

scripted_ents.Register( ENT, "BaseActorBird" )
