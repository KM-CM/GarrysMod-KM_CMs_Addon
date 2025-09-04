AddCSLuaFile()
DEFINE_BASECLASS "BaseVehicle"

if SERVER then include "Server.lua" end

scripted_ents.Register( ENT, "BaseVehicleAirBoat" )
