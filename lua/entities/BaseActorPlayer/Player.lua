// Player-Specific Shit Goes Here

ENT.tGestureSlotToLayer = {}
function ENT:AnimRestartGesture( slot, activity, autokill ) self.tGestureSlotToLayer[ slot ] = self:RestartGesture( activity, autokill ) end
function ENT:AnimRestartMainSequence() end

function ENT:SetActivity( act ) end

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable
function ENT:GetRunSpeed() return CEntity_GetTable( self ).flTopSpeed end
function ENT:GetWalkSpeed() return CEntity_GetTable( self ).flProwlSpeed end
function ENT:GetSlowWalkSpeed() return CEntity_GetTable( self ).flWalkSpeed end

// I Do Not Know Why I Cut That Comment, But IIRC We're Using a Hook
// :TranslateWeaponActivity Used to be Here, But was Moved to a Separate File (TranslateActivity.lua) Due to The Sheer Size of The Table

local FL = FL_DUCKING + FL_ANIMDUCKING
function ENT:Crouching() return self:IsFlagSet( FL ) end
function ENT:GetCrouchTarget() return self:IsCrouching() && 0 || 1 end
function ENT:SetCrouchTarget( flHeight ) if flHeight < .5 then self:AddFlags( FL ) else self:RemoveFlags( FL ) end end

ENT.flDefaultJumpHeight = HUMAN_JUMP_HEIGHT
function ENT:GetJumpPower() return self.flJumpPower || ( 2 * GetConVarNumber "sv_gravity" * self.flDefaultJumpHeight ) ^ .5 end
function ENT:SetJumpPower( p ) self.flJumpPower = p end
function ENT:CalcJumpHeight() return self.flJumpPower && ( self.flJumpPower ^ 2 / ( 2 * self.loco:GetGravity() ) ) || self.flDefaultJumpHeight end
/*
local sv_gravity = GetConVar "sv_gravity"
function ENT:CalcJumpHeight() return self:GetJumpPower() ^ 2 / ( 2 * sv_gravity:GetFloat() ) end
*/
