ENT.__ALARM__ = true

// 0 means audible when visible
ENT.flAudibleDistSqr = 0

function ENT:Initialize()
	self:SetUseType( SIMPLE_USE )
	local iClass = self:Classify()
	local t = __ALARMS__[ iClass ]
	if t then t[ self ] = true
	else __ALARMS__[ iClass ] = { [ self ] = true } end
end

local isentity, IsValid = isentity, IsValid
hook.Add( "Think", "Alarm", function()
	local t = {}
	for cls, tbl in pairs( __ALARMS__ ) do
		for ent in pairs( tbl ) do
			if !isentity( ent ) || !IsValid( ent ) then continue end
			local v = t[ cls ]
			if v then v[ ent ] = true else t[ cls ] = { [ ent ] = true } end
		end
	end
	__ALARMS__ = t
end )

ENT.iDefaultClass = 0
ENT.iClass = 0
function ENT:Classify() return self.iClass || self.iDefaultClass end
function ENT:GetNPCClass() return self.iClass || self.iDefaultClass end
function ENT:SetNPCClass( iClass )
	local iPreviousClass = self:GetNPCClass()
	local t = __ALARMS__[ iPreviousClass ]
	if t then t[ self ] = nil end
	iClass = iClass || CLASS_NONE
	self.iClass = iClass
	local t = __ALARMS__[ iClass ]
	if t then t[ self ] = true
	else __ALARMS__[ iClass ] = { [ self ] = true } end
end

function ENT:CanToggle( ent ) local c = self:Classify() return c == CLASS_NONE || ent.Classify && ent:Classify() == c end

ENT.flTelepathyRangeSqr = 4194304/*2048*/

function ENT:TurnOn( ent )
	if self:CanToggle( ent ) then
		self.bIsOn = true
		local t = __ALARMS__[ self:Classify() ]
		if t then
			local flDist, vPos = self.flTelepathyRangeSqr, self:GetPos()
			for ent in pairs( t ) do
				if vPos:DistToSqr( ent:GetPos() ) > flDist then continue end
				ent.bIsOn = true
			end
		end
	end
end
function ENT:TurnOff( ent )
	if self:CanToggle( ent ) then
		self.bIsOn = nil
		local t = __ALARMS__[ self:Classify() ]
		if t then
			local flDist, vPos = self.flTelepathyRangeSqr, self:GetPos()
			for ent in pairs( t ) do
				if vPos:DistToSqr( ent:GetPos() ) > flDist then continue end
				ent.bIsOn = nil
			end
		end
	end
end
function ENT:Toggle( ent )
	if self:CanToggle( ent ) then
		if self.bIsOn then
			self:TurnOff()
		else
			self:TurnOn()
		end
	end
end

function ENT:Use() self:Toggle() end
