AddCSLuaFile()
DEFINE_BASECLASS "base_anim"

ENT.__VEHICLE__ = true

if SERVER then include "Server.lua" end

sound.Add {
	name = "AirBoat_Motor_Spin",
	channel = CHAN_STATIC,
	level = 120,
	sound = "vehicles/airboat/fan_motor_fullthrottle_loop1.wav"
}
sound.Add {
	name = "AirBoat_Motor_Idle",
	channel = CHAN_STATIC,
	level = 120,
	sound = "vehicles/airboat/fan_motor_idle_loop1.wav"
}

sound.Add {
	name = "AirBoat_Fan_Spin",
	channel = CHAN_STATIC,
	level = 120,
	sound = "vehicles/airboat/fan_blade_fullthrottle_loop1.wav"
}
sound.Add {
	name = "AirBoat_Fan_Idle",
	channel = CHAN_STATIC,
	level = 120,
	sound = "vehicles/airboat/fan_blade_idle_loop1.wav"
}

scripted_ents.Register( ENT, "BaseVehicle" )
