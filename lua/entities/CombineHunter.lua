AddCSLuaFile()
DEFINE_BASECLASS "BaseActor"

scripted_ents.Register( ENT, "CombineHunter" )
// scripted_ents.Alias( "npc_hunter", "CombineHunter" )

// https://github.com/KM-CM/GarrysMod-KM_CMs_Addon_CombineHunter
if file.Exists( "sound/CombineHunter/Fire.wav", "GAME" ) then
	sound.Add {
		name = "CombineHunterScan",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Scan/1.wav",
			"^CombineHunter/Scan/2.wav",
			"^CombineHunter/Scan/3.wav",
			"^CombineHunter/Scan/4.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.Scan",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Scan/1.wav",
			"^CombineHunter/Scan/2.wav",
			"^CombineHunter/Scan/3.wav",
			"^CombineHunter/Scan/4.wav"
		}
	}
	
	sound.Add {
		name = "CombineHunterSend",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Send/1.wav",
			"^CombineHunter/Send/2.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.FoundEnemy",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Send/1.wav",
			"^CombineHunter/Send/2.wav"
		}
	}
	
	sound.Add {
		name = "CombineHunterReceive",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Receive/1.wav",
			"^CombineHunter/Receive/2.wav",
			"^CombineHunter/Receive/3.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.FoundEnemyAck",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Receive/1.wav",
			"^CombineHunter/Receive/2.wav",
			"^CombineHunter/Receive/3.wav"
		}
	}
	
	sound.Add {
		name = "CombineHunterFlank",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Flank/1.wav",
			"^CombineHunter/Flank/2.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.FlankAnnounce",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Flank/1.wav",
			"^CombineHunter/Flank/2.wav"
		}
	}
	
	sound.Add {
		name = "CombineHunterCharge",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Charge/1.wav",
			"^CombineHunter/Charge/2.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.TackleAnnounce",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Charge/1.wav",
			"^CombineHunter/Charge/2.wav"
		}
	}
	
	sound.Add {
		name = "CombineHunterAlert",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Alert/1.wav",
			"^CombineHunter/Alert/2.wav",
			"^CombineHunter/Alert/3.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.Alert",
		channel = CHAN_VOICE,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Alert/1.wav",
			"^CombineHunter/Alert/2.wav",
			"^CombineHunter/Alert/3.wav"
		}
	}
	
	sound.Add {
		name = "CombineHunterFootstep",
		channel = CHAN_STATIC,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Footstep/1.wav",
			"^CombineHunter/Footstep/2.wav",
			"^CombineHunter/Footstep/3.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.Footstep",
		channel = CHAN_STATIC,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/Footstep/1.wav",
			"^CombineHunter/Footstep/2.wav",
			"^CombineHunter/Footstep/3.wav",
		}
	}
	
	sound.Add {
		name = "CombineHunterBackFootstep",
		channel = CHAN_STATIC,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/BackFootstep/1.wav",
			"^CombineHunter/BackFootstep/2.wav"
		}
	}
	sound.Add {
		name = "NPC_Hunter.BackFootstep",
		channel = CHAN_STATIC,
		level = 150,
		pitch = { 90, 110 },
		sound = {
			"^CombineHunter/BackFootstep/1.wav",
			"^CombineHunter/BackFootstep/2.wav",
		}
	}
	
	sound.Add {
		name = "CombineHunterFire",
		channel = CHAN_STATIC,
		level = 150,
		pitch = { 98, 104 },
		sound = "^CombineHunter/Fire.wav"
	}
	sound.Add {
		name = "NPC_Hunter.FlechetteShoot",
		channel = CHAN_STATIC,
		level = 150,
		pitch = { 98, 104 },
		sound = "^CombineHunter/Fire.wav"
	}
else
	// TODO: Redefine all of those sounds with better info instead of copying them
	local t = sound.GetProperties "NPC_Hunter.Scan" t.name = "CombineHunterScan" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.FoundEnemy" t.name = "CombineHunterSend" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.FoundEnemyAck" t.name = "CombineHunterReceive" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.FlankAnnounce" t.name = "CombineHunterFlank" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.TackleAnnounce" t.name = "CombineHunterCharge" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.Alert" t.name = "CombineHunterAlert" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.Footstep" t.name = "CombineHunterFootstep" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.BackFootstep" t.name = "CombineHunterBackFootstep" sound.Add( t )
	local t = sound.GetProperties "NPC_Hunter.FlechetteShoot" t.name = "CombineHunterFire" sound.Add( t )
end
