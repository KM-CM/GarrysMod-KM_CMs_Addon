//Player-Specific Shit Goes Here

ENT.tGestureSlotToLayer = {}
function ENT:AnimRestartGesture( slot, activity, autokill ) self.tGestureSlotToLayer[ slot ] = self:RestartGesture( activity, autokill ) end
function ENT:AnimRestartMainSequence() self:SetCycle( 0 ) end

function ENT:SetActivity( act ) self:StartActivity( act ) end

//:TranslateWeaponActivity Used to be Here, But was Moved to a Separate File (TranslateActivity.lua) Due to The Sheer Size of The Table

local FL = FL_DUCKING + FL_ANIMDUCKING
function ENT:Crouching() return self:IsFlagSet( FL ) end
function ENT:GetCrouchTarget() return self:IsCrouching() && 0 || 1 end
function ENT:SetCrouchTarget( flHeight ) if flHeight < .5 then self:AddFlags( FL ) else self:RemoveFlags( FL ) end end

ENT.flDefaultJumpPower = 200
function ENT:GetJumpPower() return self.flJumpPower || self.flDefaultJumpPower end
function ENT:SetJumpPower( p ) self.flJumpPower = p end

function ENT:CalcJumpHeight() return self:GetJumpPower() ^ 2 / ( 2 * self.loco:GetGravity() ) end
/*
local sv_gravity = GetConVar "sv_gravity"
function ENT:CalcJumpHeight() return self:GetJumpPower() ^ 2 / ( 2 * sv_gravity:GetFloat() ) end
*/
