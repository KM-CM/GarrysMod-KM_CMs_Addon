//I Might Add Some Code Here to Drive Vehicles, for Now a MockUp of Saying We arent in One

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

function ENT:InVehicle() return IsValid( CEntity_GetTable( self ).GAME_pVehicle ) end
function ENT:GetVehicle() return CEntity_GetTable( self ).GAME_pVehicle || NULL end

function ENT:EnterVehicle( veh ) CEntity_GetTable( veh ).EnterVehicle( veh, self ) end
function ENT:ExitVehicle() return CEntity_GetTable( self ).GAME_pVehicle:ExitVehicle( self ) end

function ENT:IsValidVehicle( veh ) return true end
