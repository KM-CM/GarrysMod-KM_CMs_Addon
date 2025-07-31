/*
In My Definition of Map Making, "Scripting" Things is Basically Using The Input Output System to Do Anything.
Do Not Confuse It with Writing Code ( Also Scripting, Just Different Context ).
This File is Made for The Ability to Script What Actors Do.
*/

function ENT:CustomInput( Input, Param, Activator, Caller ) end

local __INPUTS__ = {
	updateenemymemory = function( self, sName )
		local tPositions
		local c = string.find( sName, "," )
		if c then
			local bef = string.sub( sName, 1, c - 1 )
			local aft = string.sub( sName, c + 1 )
			tPositions = {}
			local bNotFound = true
			for _, ent in ipairs( ents.FindByName( aft ) ) do
				table.insert( tPositions, { ent:GetPos(), ent:GetAngles() } )
				bNotFound = nil
			end
			if bNotFound then
				for _, ent in ipairs( ents.FindByClass( aft ) ) do
					table.insert( tPositions, { ent:GetPos(), ent:GetAngles() } )
				end
			end
			sName = bef
			if table.IsEmpty( tPositions ) then tPositions = nil end
		end
		if tPositions then
			local l = #tPositions
			local bNotFound = true
			for _, ent in ipairs( ents.FindByName( sName ) ) do
				if self:IsHateDisposition( ent ) then
					self:SetupBullseye( ent, unpack( tPositions[ math.random( l ) ] ) )
					bNotFound = nil
				end
			end
			if bNotFound then
				for _, ent in ipairs( ents.FindByClass( sName ) ) do
					if self:IsHateDisposition( ent ) then
						self:SetupBullseye( ent, unpack( tPositions[ math.random( l ) ] ) )
					end
				end
			end
		else
			local bNotFound = true
			for _, ent in ipairs( ents.FindByName( sName ) ) do
				if self:IsHateDisposition( ent ) then
					self:SetupBullseye( ent, ent:GetPos(), ent:GetAngles() )
					bNotFound = nil
				end
			end
			if bNotFound then
				for _, ent in ipairs( ents.FindByClass( sName ) ) do
					if self:IsHateDisposition( ent ) then
						self:SetupBullseye( ent, ent:GetPos(), ent:GetAngles() )
					end
				end
			end
		end
	end,
	setrelationship = function( self, s ) self:AddRelationship( s ) end
}
function ENT:AcceptInput( Input, Activator, Caller, Param )
	local v = __INPUTS__[ string.lower( Input ) ]
	if v == nil then self:CustomInput( Input, Param, Activator, Caller ) else v( self, Param ) end
end
