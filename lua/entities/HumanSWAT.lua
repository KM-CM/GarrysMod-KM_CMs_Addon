AddCSLuaFile()
DEFINE_BASECLASS "BaseActorPlayer"

scripted_ents.Register( ENT, "HumanSWAT" )

local VOICE_PITCH_MIN, VOICE_PITCH_MAX = 90, 110

ENT.CATEGORIZE = {
	LawEnforcement = true,
	SWAT = true
}

list.Set( "NPC", "HumanSWAT", {
	Name = "#HumanSWAT",
	Class = "HumanSWAT",
	Category = "Humans",
	Weapons = {
		"Glock18,M16A4",
		"Glock18,weapon_smg1",
		"Glock18,weapon_shotgun",
		"Glock18,UMP45",
		"Glock18,M16A4,M249SAW",
		"Glock18,UMP45,M249SAW",
		"Glock18,weapon_smg1,M249SAW",
		"Glock18,weapon_shotgun,M249SAW",
		"Glock18,M249SAW"
	}
} )

if CLIENT then language.Add( "HumanSWAT", "SWAT Operative" ) end

if !SERVER then return end

ENT.iDefaultClass = CLASS_HUMAN

function ENT:Initialize()
	self:SetModel "models/player/swat.mdl"
	self:SetHealth( 100 )
	self:SetMaxHealth( 100 )
	BaseClass.Initialize( self )
end
