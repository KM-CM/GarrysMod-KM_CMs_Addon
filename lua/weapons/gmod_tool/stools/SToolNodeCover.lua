TOOL.Category = "Node"
TOOL.Name = "#tool.SToolNodeCover.name"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
	language.Add( "tool.SToolNodeCover.name", "Cover" )
	language.Add( "tool.SToolNodeCover.desc", "Allows You to See Cover Nodes Used by BaseActor and Add or Remove Static Ones. Requires `developer 1`." )
	language.Add( "tool.SToolNodeCover.0", "Left Click - Create, Right Click - Remove" )
end

if !SERVER then return end

//ENT.vStart = nil

local function PlaceOnGround( vec )
	return util.TraceLine( {
		start = vec,
		endpos = vec - Vector( 0, 0, 999999 ),
		mask = MASK_SOLID_BRUSHONLY
	} ).HitPos
end

function TOOL:LeftClick( tr )
	local vStart = self.vStart
	if vStart then
		local dir = tr.HitPos - vStart
		dir.z = 0
		dir:Normalize()
		CreateStaticCover( vStart, dir )
		self.vStart = nil
	else self.vStart = PlaceOnGround( tr.HitPos ) end
end

function TOOL:RightClick( tr )
	local vTarget = PlaceOnGround( tr.HitPos )
	local area = navmesh.GetNearestNavArea( vTarget )
	if area then
		local t = __COVER_TABLE_STATIC__[ area:GetID() ]
		if t then
			local ncd, nc = 4096 //64
			for Cover in pairs( t ) do
				local d = Cover.m_Vector:DistToSqr( vTarget )
				if d >= ncd then continue end
				nc, ncd = Cover, d
			end
			if nc then nc:Remove() end
		end
	end
end

function TOOL:Reload() self.vStart = nil end

function TOOL:Think()
	local vTarget = PlaceOnGround( self:GetOwner():GetEyeTrace().HitPos )
	local vStart = self.vStart
	if vStart then
		debugoverlay.Cross( vStart, 8, .1, COVER_COLOR_PICKER, true )
		debugoverlay.Line( vStart, vStart + ( vTarget - vStart ):GetNormalized() * 32, .1, COVER_COLOR_PICKER, true )
	end
	local area = navmesh.GetNearestNavArea( vTarget )
	if area then
		local Identifier = area:GetID()
		local t = __COVER_TABLE_STATIC__[ Identifier ]
		if t then
			for Cover in pairs( t ) do
				debugoverlay.Cross( Cover.m_Vector, 8, .1, COVER_COLOR_STATIC, true )
				debugoverlay.Line( Cover.m_Vector, Cover.m_Vector + Cover.m_vForward * 32, .1, COVER_COLOR_STATIC, true )
			end
		end
		local t = __COVER_TABLE_DYNAMIC__[ Identifier ]
		if t then
			for Cover in pairs( t ) do
				debugoverlay.Cross( Cover.m_Vector, 8, .1, COVER_COLOR_DYNAMIC, true )
				debugoverlay.Line( Cover.m_Vector, Cover.m_Vector + Cover.m_vForward * 32, .1, COVER_COLOR_DYNAMIC, true )
			end
		end
	end
end
