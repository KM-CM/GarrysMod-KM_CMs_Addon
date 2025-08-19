COVER_PEEK_NONE = 0
COVER_BLINDFIRE_UP = 1
COVER_BLINDFIRE_LEFT = 2
COVER_BLINDFIRE_RIGHT = 3
COVER_FIRE_LEFT = 4
COVER_FIRE_RIGHT = 5

COVER_VARIANTS_CENTER = 0
COVER_VARIANTS_LEFT = 1
COVER_VARIANTS_RIGHT = 2

local IsValid = IsValid

local hook = hook
local hook_Add = hook.Add
local hook_Remove = hook.Remove
function AddThinkToEntity( self, func )
	local n = EntityUniqueIdentifier( self )
	hook_Add( "Think", n, function()
		if !IsValid( self ) || func( self ) then hook_Remove( "Think", n ) end
	end )
end

local CEntity = FindMetaTable "Entity"
local CEntity_GetOwner = CEntity.GetOwner
function GetOwner( self )
	local owner = CEntity_GetOwner( self )
	if IsValid( owner ) then return GetOwner( owner ) end
	return self
end

local CEntity_GetTable = CEntity.GetTable
local CEntity_IsPlayer = CEntity.IsPlayer
local CEntity_IsNPC = CEntity.IsNPC
local CEntity_GetVelocity = CEntity.GetVelocity
local CEntity_GetPhysicsObject = CEntity.GetPhysicsObject
local CEntity_IsNextBot = CEntity.IsNextBot
local Vector = Vector
function GetVelocity( ent )
	local EntTable = CEntity_GetTable( ent )
	if EntTable.__GetVelocity__ then return EntTable:__GetVelocity__() end
	if CEntity_IsPlayer( ent ) || CEntity_IsNPC( ent ) then return CEntity_GetVelocity( ent )
	else
		local phys = CEntity_GetPhysicsObject( ent )
		if IsValid( phys ) then return phys:GetVelocity() end
	end
	if CEntity_IsNextBot( ent ) then return EntTable.loco:GetVelocity() end
	return Vector( 0, 0, 0 )
end
