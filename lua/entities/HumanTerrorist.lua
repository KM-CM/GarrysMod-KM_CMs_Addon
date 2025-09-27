AddCSLuaFile()
DEFINE_BASECLASS "BaseActorPlayerHuman"

scripted_ents.Register( ENT, "HumanTerrorist" )

local VOICE_PITCH_MIN, VOICE_PITCH_MAX = 90, 110

ENT.CATEGORIZE = { Terrorist = true }

list.Set( "NPC", "HumanTerrorist", {
	Name = "#HumanTerrorist",
	Class = "HumanTerrorist",
	Category = "Humans",
	Weapons = { // My Humble Terrorist WeaponSet!
		"weapon_pistol", "USP", "DesertEagle",
		"AK47", "weapon_pistol,AK47", "USP,AK47", "DesertEagle,AK47",
		"MAC10", "weapon_pistol,MAC10", "USP,MAC10", "DesertEagle,MAC10",
		"AWM", "weapon_pistol,AWM", "USP,AWM", "DesertEagle,AWM",
		"weapon_smg1", "weapon_pistol,weapon_smg1", "USP,weapon_smg1", "DesertEagle,weapon_smg1",
		"weapon_shotgun", "weapon_pistol,weapon_shotgun", "USP,weapon_shotgun", "DesertEagle,weapon_shotgun"
	}
} )

if CLIENT then language.Add( "HumanTerrorist", "Terrorist" ) end

if !SERVER then return end

if !CLASS_HUMAN_TERRORIST then Add_NPC_Class "CLASS_HUMAN_TERRORIST" end
ENT.iDefaultClass = CLASS_HUMAN_TERRORIST

function ENT:Initialize()
	self:SetModel( math.random( 2 ) == 1 && "models/player/phoenix.mdl" || "models/player/arctic.mdl" )
	self:SetHealth( 100 )
	self:SetMaxHealth( 100 )
	BaseClass.Initialize( self )
end
