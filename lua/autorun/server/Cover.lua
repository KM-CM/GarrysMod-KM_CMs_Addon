__COVER_TABLE_DYNAMIC__, __COVER_TABLE_STATIC__ = __COVER_TABLE_DYNAMIC__ || {}, __COVER_TABLE_STATIC__ || {}
local __COVER_TABLE_DYNAMIC__, __COVER_TABLE_STATIC__ = __COVER_TABLE_DYNAMIC__, __COVER_TABLE_STATIC__

local __REGISTRY__ = debug.getregistry()
local CActorCover = __REGISTRY__.CActorCover || {}
__REGISTRY__.CActorCover = CActorCover

CActorCover.__index = CActorCover

function CActorCover:GetPos() return self.m_Vector end
function CActorCover:SetPos( v ) self.m_Vector = v end

function CActorCover:GetForward() return self.m_vForward end
function CActorCover:SetForward( a ) self.m_vForward = a end

COVER_COLOR_PICKER = Color( 0, 128, 255 )
COVER_COLOR_STATIC = Color( 0, 255, 255 )
COVER_COLOR_DYNAMIC = Color( 255, 255, 0 )

function CActorCover:Update()
	local area = navmesh.GetNearestNavArea( self.m_Vector )
	if area then
		local Identifier = area:GetID()
		self.m_Area = Identifier
		local t = __COVER_TABLE_STATIC__[ Identifier ]
		if t then t[ self ] = true else __COVER_TABLE_STATIC__[ Identifier ] = { [ self ] = true } end
	else self:Remove() end
end

function CActorCover:Remove()
	local area = self.m_Area
	if area then
		local Identifier = self.m_Area
		local t = __COVER_TABLE_STATIC__[ Identifier ]
		if t then
			t[ self ] = nil
			if table.IsEmpty( t ) then __COVER_TABLE_STATIC__[ Identifier ] = nil end
		end
	end
end

function CreateStaticCover( vec, dir )
	local self = setmetatable( { m_Vector = vec, m_vForward = dir, m_bStatic = true }, CActorCover )
	self:Update()
	return self
end

if !__COVER_TABLE_LOADED__ then
	//Load Static Cover Nodes if They were Already Set
	if file.Exists( "ActorCover/" .. game.GetMap() .. ".json", "DATA" ) then
		local t = util.JSONToTable( file.Read( "ActorCover/" .. game.GetMap() .. ".json" ), true )
		//The Timer is Required. Dont Ask Why. It Just is. I have No Idea Why
		//Just Kidding I Do have an Idea Why It's Probably Just Some Loading Quirks
		timer.Simple( 0, function()
			for _, d in pairs( t ) do for _, d in ipairs( d ) do CreateStaticCover( d[ 1 ], d[ 2 ] ) end end
		end )
	elseif file.Exists( "ActorCoverBase/" .. game.GetMap() .. ".json", "DATA" ) then
		local t = util.JSONToTable( file.Read( "ActorCoverBase/" .. game.GetMap() .. ".json" ), true )
		//The Timer is Required. Dont Ask Why. It Just is. I have No Idea Why
		//Just Kidding I Do have an Idea Why It's Probably Just Some Loading Quirks
		timer.Simple( 0, function()
			for _, d in pairs( t ) do for _, d in ipairs( d ) do CreateStaticCover( d[ 1 ], d[ 2 ] ) end end
		end )
	end
	__COVER_TABLE_LOADED__ = true
end

//Save Static Cover Nodes
hook.Add( "Think", "ActorCover", function()
	if file.Exists( "ActorCover/" .. game.GetMap() .. ".json", "DATA" ) then
		local t = {}
		for i, d in pairs( __COVER_TABLE_STATIC__ ) do
			if d.m_bCreatedByMap then continue end //NodeCover
			local tbl = {}
			t[ i ] = tbl
			for Cover in pairs( d ) do table.insert( tbl, { Cover.m_Vector, Cover.m_vForward } ) end
		end
		file.Write( "ActorCover/" .. game.GetMap() .. ".json", util.TableToJSON( t ) )
	else file.CreateDir "ActorCover" file.Write( "ActorCover/" .. game.GetMap() .. ".json", "" ) end
end )
