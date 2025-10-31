ENT.tSequences = {}
ENT.tPromoteSequences = {}
ENT.flAnimationSpeed = 4

function ENT:PromoteSequence( seq, flSpeed )
	if isnumber( seq ) then seq = self:GetSequenceName( seq ) end
	self.tPromoteSequences[ seq ] = flSpeed
end

function ENT:AnimationSystemTick()
	local tPromote, tSequences, flSpeed = self.tPromoteSequences, self.tSequences, self.flAnimationSpeed
	for seq in pairs( tPromote ) do
		if !tSequences[ seq ] then
			local lay = self:AddGestureSequence( self:LookupSequence( seq ), false )
			self:SetLayerWeight( lay, 0 )
			tSequences[ seq ] = lay
		end
	end
	for seq, lay in pairs( tSequences ) do
		local s = self:LookupSequence( seq )
		if self:GetLayerSequence( lay ) != s then self:SetLayerSequence( lay, s ) end
		local f = tPromote[ seq ]
		if f then
			self:SetLayerPlaybackRate( lay, f )
			local l = self:GetLayerWeight( lay )
			self:SetLayerWeight( lay, math.Clamp( l + ( 1 - l ) * flSpeed * FrameTime(), 0, 1 ) )
		else
			local l = self:GetLayerWeight( lay )
			self:SetLayerWeight( lay, math.Clamp( l - l * flSpeed * FrameTime(), 0, 1 ) )
		end
	end
	table.Empty( tPromote )
end

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

function ENT:AnimationSystemHalt( MyTable )
	for seq, lay in pairs( ( MyTable || CEntity_GetTable( self ) ).tSequences ) do
		local s = self:LookupSequence( seq )
		if self:GetLayerSequence( lay ) != s then self:SetLayerSequence( lay, s ) end
		self:SetLayerWeight( lay, 0 )
	end
end
