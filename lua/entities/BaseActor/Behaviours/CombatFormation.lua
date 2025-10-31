// “ALL OF YOU BEHIND ME, WE'RE GOING IN!”
//  - A Hostile, 2011, Tom Clancy's Splinter Cell: Blacklist

// A Simple One Person Wide Stack
function ENT:DLG_CombatFormationStack() return self:DLG_CombatFormationGeneral() end
// Used by SWAT; Stack Up by The Sides of The Lead
function ENT:DLG_CombatFormationSide() return self:DLG_CombatFormationGeneral() end
// Used Mid-Combat; Find Covers Around The Lead
function ENT:DLG_CombatFormationCover() return self:DLG_CombatFormationGeneral() end // “WE'RE GOING IN, IN POSITION!”

function ENT:DLG_CombatFormationReady() end // “BEHIND COVER AND IN POSITION!”
function ENT:DLG_CombatFormationMove() end // “Harakha, Yalla!”

function ENT:DLG_CombatFormationGeneral() end

Actor_RegisterSchedule( "CombatFormationMove", function( self, sched )
	local vec = sched.Vector
	if !vec then return end
	local dir = sched.Direction
	if !dir then return end
	if !sched.Path then sched.Path = Path "Follow" end
	self:ComputePath( sched.Path, vec )
	if sched.bLead && !sched.bDialogue then
		self[ "DLG_CombatFormation" .. sched.sType ]( self )
		sched.bDialogue = true
	end
	local f = self.flPathGoalTolerance
	f = f * f
	if self:GetPos():DistToSqr( vec ) <= f then
		self:Stand( 1 )
		self.vDesAim = dir
		if !sched.bDialogue then
			self:DLG_CombatFormationReady()
			sched.bDialogue = true
		end
		sched.bReached = true
	else
		local goal = sched.Path:GetCurrentGoal()
		if goal then
			self.vDesAim = ( goal.pos - self:GetPos() ):GetNormalized()
			self:ModifyMoveAimVector( self.vDesAim, self.flTopSpeed, 1 )
		end
		self:MoveAlongPath( sched.Path, self.flTopSpeed, 1 )
		sched.bReached = nil
		sched.bDialogue = nil
	end
end )

Actor_RegisterBehaviour( "CombatFormation", {
	Initialize = function( self )
		self.sType = "Stack" // Only this for now
	end,
	GatherParticipants = function( self )
		local pCurrent = next( self.m_tParticipants )
		if !IsValid( pCurrent ) then ErrorNoHaltWithStack "GatherParticipants Requires at least one participant" end
		local tAllies = pCurrent:GetAlliesByClass()
		if tAllies then
			local vPos = self.Vector
			for ent in pairs( tAllies ) do
				if !IsValid( ent ) || ent:GetPos():DistToSqr( vPos ) > 9437184/*3072*/ || ent.Schedule && ent.Schedule.bFromCombatFormation then continue end
				self:AddParticipant( ent )
			end
		end
	end,
	Tick = function( self )
		local d = self.Direction
		d.z = 0
		d:Normalize()
		if self.sType == "Stack" then
			if !IsValid( self.pLead ) then
				local npd, v, np = math.huge, self.Vector
				for ent in pairs( self.m_tParticipants ) do
					if !IsValid( ent ) then continue end
					local d = ent:GetPos():DistToSqr( v )
					if d < npd then np, npd = ent, d end
				end
				if IsValid( np ) then self.pLead = np else
					self:Remove()
					return
				end
			end
			local lead = self.pLead
			local s
			if !lead.Schedule || lead.Schedule.m_sName != "CombatFormationMove" then
				s = lead:SetSchedule "CombatFormationMove"
			else s = lead.Schedule end
			s.Vector = self.Vector
			s.Direction = self.Direction
			s.bLead = true
			s.sType = self.sType
			if self.tPositions then
				local v, d, iCount, iNum = self.Vector, self.Direction, 0, 0
				for ent, dist in pairs( self.tPositions ) do
					if !IsValid( ent ) then self.tPositions = nil return end
					iCount = iCount + 1
					local s
					if !ent.Schedule || ent.Schedule.m_sName != "CombatFormationMove" then
						s = ent:SetSchedule "CombatFormationMove"
					else s = ent.Schedule end
					s.Vector = v - d * dist
					s.Direction = d
					s.sType = self.sType
					s.bLead = nil
					if s.bReached then iNum = iNum + 1 end
				end
				if iCount >= iNum then
					lead:DLG_CombatFormationMove()
					for ent in pairs( self.tPositions ) do
						ent:SetSchedule( "Combat" ).bAdvance = true
					end
					self:Finish()
					return
				end
			else
				local v = self.Vector
				local t = {}
				for ent in pairs( self.m_tParticipants ) do
					if !IsValid( ent ) then continue end
					table.insert( t, { ent, ent:GetPos():DistToSqr( v ) } )
				end
				table.SortByMember( t, 2, true )
				local tPositions = {}
				local iSoFar = ( lead:OBBMaxs().x - lead:OBBMins().x ) * 1.5
				for _, d in ipairs( t ) do
					local ent = d[ 1 ]
					local m, n = ent:OBBMaxs().x, ent:OBBMins().x
					local d = m - n
					iSoFar = iSoFar + d * .5 // The First Half of Our Bounding Box is Where We Stand
					tPositions[ ent ] = iSoFar
					iSoFar = iSoFar + d // Add The Entirety of It Because ( d + d * .5 ) = 1.5
				end
				self.tPositions = tPositions
			end
		elseif self.sType == "Side" then
		elseif self.sType == "Cover" then
		end
	end
} )
