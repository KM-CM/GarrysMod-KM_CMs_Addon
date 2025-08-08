COVER_PEEK_NONE = 0
COVER_BLINDFIRE_UP = 1
COVER_BLINDFIRE_LEFT = 2
COVER_BLINDFIRE_RIGHT = 3
COVER_FIRE_LEFT = 4
COVER_FIRE_RIGHT = 5

COVER_VARIANTS_CENTER = 0
COVER_VARIANTS_LEFT = 1
COVER_VARIANTS_RIGHT = 2

function AddThinkToEntity( self, func )
	local n = EntityUniqueIdentifier( self )
	hook.Add( "Think", n, function()
		if !IsValid( self ) || func( self ) then hook.Remove( "Think", n ) end
	end )
end

function GetOwner( self )
	local owner = self:GetOwner()
	if IsValid( owner ) then return GetOwner( owner ) end
	return self
end

function GetVelocity( ent )
	if ent.__GetVelocity__ then return ent:__GetVelocity__() end
	if ent:IsPlayer() || ent:IsNPC() then return ent:GetVelocity()
	else
		local phys = ent:GetPhysicsObject()
		if IsValid( phys ) then return phys:GetVelocity() end
	end
	if ent:IsNextBot() then return ent.loco:GetVelocity() end
	return Vector( 0, 0, 0 )
end
