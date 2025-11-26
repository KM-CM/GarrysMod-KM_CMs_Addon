local sound_Add = sound.Add

sound_Add {
	name = "Concrete.StepLeft",
	channel = CHAN_STATIC,
	volume = 1,
	level = 75,
	pitch = { 90, 110 },
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
	pitch = { 90, 110 },
	sound = {
		"Footsteps/Concrete/R1.wav",
		"Footsteps/Concrete/R2.wav"
	}
}

sound_Add {
	name = "Bleed",
	channel = CHAN_STATIC,
	volume = 1,
	level = 50,
	pitch = { 90, 110 },
	sound = {
		"ambient/water/distant_drip1.wav",
		"ambient/water/distant_drip2.wav",
		"ambient/water/distant_drip3.wav",
		"ambient/water/distant_drip4.wav"
	}
}
