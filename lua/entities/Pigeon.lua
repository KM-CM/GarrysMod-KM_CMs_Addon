AddCSLuaFile()
DEFINE_BASECLASS "BaseActorBird"

scripted_ents.Register( ENT, "Pigeon" )
scripted_ents.Alias( "npc_pigeon", "Pigeon" )

sound.Add {
	name = "Pigeon_Coo",
	channel = CHAN_AUTO,
	volume = 1,
	level = 110,
	pitch = { 80, 120 },
	sound = {
		"ambient/creatures/pigeon_idle1.wav",
		"ambient/creatures/pigeon_idle2.wav",
		"ambient/creatures/pigeon_idle3.wav",
		"ambient/creatures/pigeon_idle4.wav"
	}
}
sound.Add {
	name = "Pigeon_Coo_Voice",
	channel = CHAN_VOICE,
	volume = 1,
	level = 110,
	pitch = { 80, 120 },
	sound = {
		"ambient/creatures/pigeon_idle1.wav",
		"ambient/creatures/pigeon_idle2.wav",
		"ambient/creatures/pigeon_idle3.wav",
		"ambient/creatures/pigeon_idle4.wav"
	}
}

if CLIENT then language.Add( "Pigeon", "Pigeon" ) end

if !SERVER then return end

ENT.flVisionYaw = 340
ENT.flVisionPitch = 135
ENT.flHungerDepletionRate = .2084

if !CLASS_PIGEON then Add_NPC_Class "CLASS_PIGEON" end
ENT.iDefaultClass = CLASS_PIGEON

ENT.sPeckCooSound = "Pigeon_Coo"

function ENT:Initialize()
	self.bMale = math.random( 2 ) == 1
	self:SetModel "models/pigeon.mdl"
	self:SetCollisionBounds( self.vHullMins, self.vHullMaxs )
	self:PhysicsInit( SOLID_OBB, Vector( 0, 0, self.vHullMaxs * .5 ) )
	self:SetHealth( 50 )
	self:SetMaxHealth( 50 )
	self.flHungerLimit = self:GetMaxHealth() * .5
	self.flHunger = self.flHungerLimit
	self.flSaturationLimit = self:GetMaxHealth() * .4
	//self.flSaturation = self.flSaturationLimit
	self:SetColor( math.random( 2 ) == 1 && Color( math.Rand( 0, 55 ), math.Rand( 0, 55 ), math.Rand( 0, 55 ) ) || Color( 255, 255, 255 ) )
	BaseClass.Initialize( self )
end
