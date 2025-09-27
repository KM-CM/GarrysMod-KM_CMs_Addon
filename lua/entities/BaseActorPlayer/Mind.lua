function ENT:SelectSchedule( Previous, PrevName, PrevReturn )
	if table.IsEmpty( self.tEnemies ) then
		self:SetNPCState( NPC_STATE_IDLE )
		self:SetSchedule "Idle"
	else
		self:SetNPCState( NPC_STATE_COMBAT )
		self:SetSchedule "CombatSoldier"
	end
end
