AddCSLuaFile()
DEFINE_BASECLASS "BaseActorAnimal"

sound.Add {
	name = "CatPurrLoop",
	channel = CHAN_STATIC,
	level = 60,
	sound = "Cat/PurrLoop.wav"
}

sound.Add {
	name = "CatStartled",
	channel = CHAN_VOICE,
	level = 110,
	pitch = { 80, 120 },
	// TODO: We need WAY more startled cat sounds!!!
	sound = "Cat/Startled/1.wav"
}

list.Set( "NPC", "Cat", {
	Name = "#Cat",
	Class = "Cat",
	Category = "Felidae"
} )

if !SERVER then return end

ENT.Categorize = { Cat = true }

ENT.vHullMins = Vector( -24, -6, 0 )
ENT.vHullMaxs = Vector( 24, 6, 24 )
ENT.vHullDuckMaxs = ENT.vHullMaxs
ENT.vHullDuckMins = ENT.vHullMins

ENT.flHungerDepletion = .022
ENT.flHungerLimit = 6.7

ENT.flThirstDepletion = .0197
ENT.flThirstLimit = 6

ENT.bCantUse = true
ENT.bCanStartle = true

ENT.bCombatForgetLastHostile = true

local math = math
local math_Rand = math.Rand
local math_random = math.random

local CEntity = FindMetaTable "Entity"
local CEntity_GetTable = CEntity.GetTable
local CEntity_EmitSound = CEntity.EmitSound

local Color = Color

function ENT:Initialize()
	BaseClass.Initialize( self )
	// Random parameters for E A C H   K A T Z E   M O D E L
	local MyTable = CEntity_GetTable( self )
	if !MyTable.flTopSpeed then MyTable.flTopSpeed = math_Rand( 320, 520 ) end
	if !MyTable.flProwlSpeed then MyTable.flProwlSpeed = math_Rand( 120, 160 ) end
	if !MyTable.flWalkSpeed then MyTable.flWalkSpeed = math_Rand( 40, 80 ) end
	self:SetModel "models/jeezy/animals/siamese_cat/siamese_cat.mdl"
	if self:GetMaxHealth() == 0 then self:SetMaxHealth( math_Rand( 60, 80 ) ) end
	if MyTable.flBoldness == -1 then MyTable.flBoldness = math_Rand( .33, 3 ) end
	if self:Health() == 0 then self:SetHealth( self:GetMaxHealth() ) end
	if MyTable.flHearDistanceMultiplier == 1 then MyTable.flHearDistanceMultiplier = math_Rand( 4, 5 ) end
	if MyTable.flHunger == -1 then MyTable.flHunger = MyTable.flHungerLimit end
	if MyTable.flThirst == -1 then MyTable.flThirst = MyTable.flThirstLimit end
	if !MyTable.sGender then MyTable.sGender = math_random( 2 ) == 1 && "Male" || "Female" end
	local clColor = MyTable.clColor || Color( math_random( 192, 255 ), math_random( 192, 255 ), math_random( 192, 255 ) )
	MyTable.clColor = clColor
	self:SetColor( clColor )
	self:SetSolid( SOLID_OBB )
	self:PhysicsInitShadow( false, false )
	local iSkin = MyTable.iSkin || math_random( 0, 9 )
	MyTable.iSkin = iSkin
	self:SetSkin( iSkin )
end

function ENT:MoveAlongPath( Path, flSpeed, _/*flHeight*/, tFilter )
	self.loco:SetDesiredSpeed( flSpeed )
	local f = flSpeed * ACCELERATION_NORMAL
	self.loco:SetAcceleration( f )
	self.loco:SetDeceleration( f )
	self:HandleJumpingAlongPath( Path, flSpeed, tFilter )
	local f = GetVelocity( self ):Length()
	if f <= 12 then self:PromoteSequence "idle"
	elseif f > self.flProwlSpeed * .9 then
		self:PromoteSequence( "run", GetVelocity( self ):Length() / 200 )
	else
		self:PromoteSequence( "walk", GetVelocity( self ):Length() / 60 )
	end
end

function ENT:DLG_Startled() CEntity_EmitSound( self, "CatStartled" ) end

function ENT:HandlePurr( flVolume, flVolumeRate, flPitch, flPitchRate )
	local pPurrLoop = MyTable.pPurrLoop
	if !pPurrLoop then return end
	pPurrLoop:ChangeVolume( math.Approach( pPurrLoop:GetVolume(), flVolume, flVolumeRate * FrameTime() ) )
	pPurrLoop:ChangePitch( math.Approach( pPurrLoop:GetPitch(), flPitch, flPitchRate * FrameTime() ) )
end

function ENT:Behaviour( MyTable )
	local pPurrLoop = MyTable.pPurrLoop
	if !pPurrLoop then
		pPurrLoop = CreateSound( self, "CatPurrLoop" )
		pPurrLoop:PlayEx( 0, 0 )
		MyTable.pPurrLoop = pPurrLoop
	end
	BaseClass.Behaviour( self, MyTable )
end

function ENT:OnKilled( dDamage )
	if BaseClass.OnKilled( self, dDamage ) then return end
	local pPurrLoop = self.pPurrLoop
	if pPurrLoop then pPurrLoop:Stop() end
	self:BecomeRagdoll( dDamage )
end
