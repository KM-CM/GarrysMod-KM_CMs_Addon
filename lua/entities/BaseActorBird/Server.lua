DEFINE_BASECLASS "BaseActorAnimal"

ENT.tPeckable = {
	[ MAT_DIRT ] = 3,
	[ MAT_GRASS ] = 2,
	[ MAT_SAND ] = 1,
	[ MAT_FOLIAGE ] = .4,
	[ MAT_SNOW ] = .3,
	[ MAT_WOOD ] = .2
}

ENT.bPhysics = true

ENT.sFlapLoop = "BaseActorBird_FlapLoopDefault"
ENT.sSoarLoop = "BaseActorBird_SoarLoopDefault"

ENT.bCanFly = true

ENT.flHunger = 0
ENT.flHungerLimit = 0 //How Much can We Eat?
ENT.flHungerDepletionRate = .2048
ENT.flSaturation = 0
ENT.flSaturationLimit = 0
ENT.flHungry = .8 //If ( flHunger / flHungerLimit ) <= This, I should Really be Focused on Finding Food
ENT.bMale = true

//Use This at The End of Your Custom Initialize, Not at The Start!
function ENT:Initialize()
	BaseClass.Initialize( self )
	local pFlapLoop, pSoarLoop = CreateSound( self, self.sFlapLoop ), CreateSound( self, self.sSoarLoop )
	pFlapLoop:PlayEx( 0, 100 )
	pSoarLoop:PlayEx( 0, 100 )
	self.pFlapLoop = pFlapLoop
	self.pSoarLoop = pSoarLoop
end

function ENT:OnRemove()
	if self.pFlapLoop then self.pFlapLoop:Stop() end
	if self.pSoarLoop then self.pSoarLoop:Stop() end
	BaseClass.OnRemove( self )
end

ENT.sFlapSequence = "fly01"
ENT.sSoarSequence = "soar"

local CEntity = FindMetaTable "Entity"
local CEntity_SetHealth = CEntity.SetHealth
local CEntity_Health = CEntity.Health
local CEntity_TakeDamageInfo = CEntity.TakeDamageInfo

local math = math
local DamageInfo, math_min = DamageInfo, math.min
function ENT:HungerDeath()
	local d = DamageInfo()
	d:SetAttacker( self )
	d:SetInflictor( self )
	d:SetDamage( 1 )
	d:SetDamageType( DMG_POISON )
	CEntity_SetHealth( self, math_min( CEntity_Health( self ), 0 ) )
	CEntity_TakeDamageInfo( self, d )
end

local CEntity_GetTable = CEntity.GetTable
local FrameTime, math_Clamp = FrameTime, math.Clamp

function ENT:Behaviour()
	local MyTable = CEntity_GetTable( self )
	if MyTable.flSaturation > 0 then MyTable.flSaturation = math_Clamp( MyTable.flSaturation - FrameTime(), 0, self.flSaturationLimit ) else
		MyTable.flHunger = math_Clamp( MyTable.flHunger - MyTable.flHungerDepletionRate * FrameTime(), 0, MyTable.flHungerLimit )
		if MyTable.flHunger <= 0 then MyTable.HungerDeath( self ) return end
	end
	MyTable.RunMind( self )
end

function ENT:SelectSchedule( Previous, PrevName, PrevReturn )
	self:SetSchedule "BirdIdle"
end

ENT.vHullMins = Vector( -12, -12, 0 )
ENT.vHullMaxs = Vector( 12, 12, 24 )

include "Schedules/Idle.lua"
