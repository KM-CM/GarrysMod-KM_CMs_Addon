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
	elseif ent:IsNextBot() then
		local phys = ent:GetPhysicsObject()
		if IsValid( phys ) then return phys:GetVelocity() end
		return ent.loco:GetVelocity()
	end
	return Vector( 0, 0, 0 )
end
