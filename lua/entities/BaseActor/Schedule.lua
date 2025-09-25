local _reg = debug.getregistry()
local CActorSchedule = _reg.CActorSchedule || {}
_reg.CActorSchedule = CActorSchedule

CActorSchedule.__index = CActorSchedule

//ENT.Schedule = nil

function ENT:SelectSchedule( Previous, PrevName, PrevReturn ) ErrorNoHaltWithStack "SelectSchedule Not Overriden" end

local __SCHEDULE__ = __SCHEDULE__

ENT.__SCHEDULE__ = __SCHEDULE__

function ENT:SetSchedule( Name )
	local sched = setmetatable( { m_pOwner = self, m_sName = Name }, { __index = function( self, Key, Value )
		local v = rawget( self, Key )
		if v == nil then return rawget( CActorSchedule, Key )
		else return v end
	end } )
	self.Schedule = sched
	return sched
end

ENT.tPreScheduleResetVariables = {}

function ENT:SelectScheduleInternal( ... )
	self.Schedule = nil
	local p = self.GAME_pBehaviour
	if p then if p:SelectSchedule( self, ... ) then return end end
	local veh = self.GAME_pVehicle
	if IsValid( veh ) then self:SetSchedule "Vehicle_Base"
	else self:SelectSchedule( ... ) end
end

function ENT:RunMind()
	for k, v in pairs( self.tPreScheduleResetVariables ) do self[ k ] = Either( v == false, nil, v ) end
	local v = self.Schedule
	if !v then self:SelectScheduleInternal() return end
	local s = v.m_sName || ''
	local f = self.__SCHEDULE__[ s ]
	local b = IsValid( self.GAME_pVehicle )
	if !f || ( b && !s:match "^Vehicle_" || !b && s:match "^Vehicle_" ) then self.Schedule = nil self:SelectScheduleInternal( v, s ) return end
	local r = f( self, v )
	if r != nil then self:SelectScheduleInternal( v, s, r ) end
end

------ Include Default Schedules ------

include "Schedules/IdleRoam.lua"
include "Schedules/Combat.lua"
include "Schedules/Cover.lua"
include "Schedules/Vehicle/Base.lua"
