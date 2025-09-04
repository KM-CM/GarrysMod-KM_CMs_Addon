/*

There has been a debate going on if it is called the Airboat or the Mudskipper.
Airboat is actually the general term, like "jeep" or "car", and the MudSkipper is the model.
End of story. There is just nothing else to say.

*/

AddCSLuaFile()
DEFINE_BASECLASS "BaseVehicleAirBoat"

scripted_ents.Register( ENT, "MudSkipper" )
scripted_ents.Alias( "prop_vehicle_airboat", "MudSkipper" )

if CLIENT then language.Add( "MudSkipper", "Mudskipper" ) end

local CEntity_LookupSequence = FindMetaTable( "Entity" ).LookupSequence
function ENT:HandleAnimation( ply ) return CEntity_LookupSequence( ply, "drive_airboat" ) end

function ENT:GetForwardDirection() return -self:GetRight() end

if !SERVER then return end

ENT.vSeat = Vector( 0, -8, 32 )
ENT.aSeat = Angle( 0, 0, 0 )

function ENT:Initialize()
	self:SetModel "models/airboat.mdl"
	local vMins, vMaxs = self:GetCollisionBounds()
	self:PhysicsInit( SOLID_VPHYSICS, ( vMins + vMaxs ) * .5 - Vector( 0, 0, 256 ) )
	BaseClass.Initialize( self )
end
