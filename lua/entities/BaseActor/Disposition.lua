//Please Never Try to Access These Directly, or Else I will Put You in a Maid Dress or Some Shit
//( I Dont Know How to Make Threats )
ENT.iDefaultClass = CLASS_NONE
//ENT.iClass = nil

//The Reason We Dont Do ENT.__ACTOR_TABLE_BY_CLASS__ = {} is Because
//Garry's Mod Lua Internally Does Magic That Makes The Table NOT Mutable.
//Usually, This is Extremely Useful, But Here, It's a Very Small Problem.
//local __ACTOR_TABLE_BY_CLASS__ = {}
__ACTOR_TABLE_BY_CLASS__ = __ACTOR_TABLE_BY_CLASS__ || {}
local __ACTOR_TABLE_BY_CLASS__ = __ACTOR_TABLE_BY_CLASS__
function ENT.GetActorTableByClass() return __ACTOR_TABLE_BY_CLASS__ end
local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable
local CLASS_NONE = CLASS_NONE
function ENT:GetAlliesByClass() local t = CEntity_GetTable( self ) if t == CLASS_NONE then return end return __ACTOR_TABLE_BY_CLASS__[ t.iClass || t.iDefaultClass ] end

//Getters Exist for a Reason. Use Them.
function ENT:GetNPCClass() return self.iClass || self.iDefaultClass end
//Use This Instead of GetNPCClass - Everything with FL_OBJECT should have a :Classify, But Not Neccessarily a :GetNPCClass
//( This is Just My Standard and Actually has Zero Relevance to Anything )
function ENT:Classify() return self:GetNPCClass() end
//Setters Also Exist for a Reason. Use Them too.
function ENT:SetNPCClass( iClass )
	local iPreviousClass = self:GetNPCClass()
	if iPreviousClass != CLASS_NONE then
		local t = __ACTOR_TABLE_BY_CLASS__[ iPreviousClass ]
		if t then t[ self ] = nil end
	end
	iClass = iClass || CLASS_NONE
	self.iClass = iClass
	if iClass != CLASS_NONE then
		local t = __ACTOR_TABLE_BY_CLASS__[ iClass ]
		if t then t[ self ] = true
		else __ACTOR_TABLE_BY_CLASS__[ iClass ] = { [ self ] = true } end
	end
end

ENT.tSpecialRelationships = {}
function ENT:AddEntityRelationship( ent, disp ) self.tSpecialRelationships[ ent ] = disp end

local D_ENUM = { D_ER = 0, D_HT = 1, D_FR = 2, D_LI = 3, D_NU = 4 }
function ENT:AddRelationship( sRelationship )
	local sPart1, sPart2 = sRelationship:find( " " ), sRelationship:find( " ", sRelationship:find( " " ) + 1 )
	local sClass = sRelationship:sub( 1, sPart1 - 1 )
	local Relationship = D_ENUM[ sRelationship:sub( sPart1 + 1, sPart2 - 1 ) ] || 0
	local bNotFound = true
	for _, ent in ipairs( ents.FindByName( sClass ) ) do
		self.tSpecialRelationships[ ent ] = Relationship
		bNotFound = nil
	end
	//ClassName-Based RelationShips are Only Semi-Supported Since We are Using a Completely New RelationShip System to VALVe's
	if bNotFound then for _, ent in ipairs( ents.FindByClass( sClass ) ) do self.tSpecialRelationships[ ent ] = Relationship end end
end

function ENT:GetRelationship( ent ) //Private
	local v = self.tSpecialRelationships[ ent ]
	if v then return v end
	if ent.Classify then
		if self:GetNPCClass() == CLASS_NONE then return D_HT end
		return ent:Classify() == self:Classify() && D_LI || D_HT
	end
	return D_NU
end

local ai_ignoreplayers = GetConVar "ai_ignoreplayers"
function ENT:Disposition( ent ) //Public
	if !IsValid( ent ) then return D_NU end
	if ent.__ACTOR_BULLSEYE__ then return ent.Owner == self && D_HT || D_NU end
	if !ent.Classify || ent:IsPlayer() && ai_ignoreplayers:GetInt() == 1 then return D_NU end
	return self:GetRelationship( ent )
end

function ENT:IsHateDisposition( ent ) local d = self:Disposition( ent ) return d == D_HT || d == D_FR end
