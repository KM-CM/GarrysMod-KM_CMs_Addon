__SCHEDULE__ = __SCHEDULE__ || {}
local __SCHEDULE__ = __SCHEDULE__

function Actor_RegisterSchedule( Name, Func ) __SCHEDULE__[ Name ] = Func end
function Actor_RegisterScheduleSpecial( Name, Fall ) __SCHEDULE__[ Name ] = function( self, sched ) return ( self.__SCHEDULE__[ Fall ] || __SCHEDULE__[ Fall ] )( self, sched ) end end

__BEHAVIOUR__ = __BEHAVIOUR__ || {}
local __BEHAVIOUR__ = __BEHAVIOUR__

function Actor_RegisterBehaviour( Name, Data ) __BEHAVIOUR__[ Name ] = Data end

__ALARMS__ = __ALARMS__ || {}

// Cover: ( Vector vStart, Vector vEnd, Boolean bRightSide )
__COVERS_STATIC__ = __COVERS_STATIC__ || {} // CNavArea:GetID() -> SequentialTable[ Cover ]
__COVERS_DYNAMIC__ = __COVERS_DYNAMIC__ || {} // CNavArea:GetID() -> { Any -> Cover }
