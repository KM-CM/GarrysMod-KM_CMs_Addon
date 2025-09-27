local table_IsEmpty = table.IsEmpty

function ENT:SelectSchedule( MyTable )
	if table_IsEmpty( MyTable.tEnemies ) then
		MyTable.SetNPCState( self, NPC_STATE_IDLE )
		MyTable.SetSchedule( self, "Idle", MyTable )
	else
		MyTable.SetNPCState( self, NPC_STATE_COMBAT )
		MyTable.SetSchedule( self, "CombatSoldier", MyTable )
	end
end
