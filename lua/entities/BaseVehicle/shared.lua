AddCSLuaFile()
DEFINE_BASECLASS "base_anim"

ENT.__VEHICLE__ = true

if SERVER then include "Server.lua" end

scripted_ents.Register( ENT, "BaseVehicle" )
