//Whether We wanna Advance or Retreat, and How Fast
ENT.flCombatState = 1
//Same as Above, Except Caused Even by Small Amounts of GunFire
//When You're Retreating Via This, Dont Shout "FALL BACK TO COVER!!!"
ENT.flCombatStateSmall = 1

local math = math
local math_Clamp = math.Clamp
local math_Remap = math.Remap

ENT.flCombatStateSuppressionShort = 0
ENT.flCombatStateSuppressionShortMax = 2
ENT.flCombatStateSuppressionShortRec = 2
ENT.flCombatStateSuppressionShortEffect = 2

ENT.flCombatStateSuppressionLong = 0
ENT.flCombatStateSuppressionLongMax = 24
ENT.flCombatStateSuppressionLongRec = .2
ENT.flCombatStateSuppressionLongEffect = 12

local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_Health = CEntity.Health
function ENT:CalcCombatState()
	local MyTable = CEntity_GetTable( self )
	local h = CEntity_Health( self )
	local f = math_Clamp( math_Remap( MyTable.flCombatStateSuppressionLong, 0, h * MyTable.flCombatStateSuppressionLongEffect, 1, -1 ), -1, 1 )
	local fs = math_Clamp( math_Remap( MyTable.flCombatStateSuppressionShort, 0, h * MyTable.flCombatStateSuppressionShortEffect, 1, -1 ), -1, 1 )
	MyTable.flCombatState = f
	MyTable.flCombatStateSmall = fs
	return f, fs
end
