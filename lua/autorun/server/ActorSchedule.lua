__SCHEDULE__ = __SCHEDULE__ || {}
local __SCHEDULE__ = __SCHEDULE__

function Actor_RegisterSchedule( Name, Func ) __SCHEDULE__[ Name ] = Func end
function Actor_RegisterScheduleSpecial( Name, Fall ) __SCHEDULE__[ Name ] = function( self, sched ) return self.__SCHEDULE__[ Fall ]( self, sched ) end end
