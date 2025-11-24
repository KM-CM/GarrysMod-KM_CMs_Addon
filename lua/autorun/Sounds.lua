local sound_Add = sound.Add

sound_Add {
	name = "Concrete.StepLeft",
	channel = CHAN_STATIC,
	volume = 1,
	level = 75,
	pitch = { 95, 110 },
	sound = {
		"Footsteps/Concrete/L1.wav",
		"Footsteps/Concrete/L2.wav"
	}
}

sound_Add {
	name = "Concrete.StepRight",
	channel = CHAN_STATIC,
	volume = 1,
	level = 75,
	pitch = { 95, 110 },
	sound = {
		"Footsteps/Concrete/R1.wav",
		"Footsteps/Concrete/R2.wav"
	}
}
