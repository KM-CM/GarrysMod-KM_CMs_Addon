function ENT:SetAimVector( v ) self.vAim = v end
function ENT:GetAimVector() return self.vAim || self:GetForward() end

ENT.flTurnRate = 128
ENT.flBodyTensity = .8 // 1 Means as Fast as Possible, Lower Values Make Us Turn Slower to Face Smaller Angles
function ENT:GetDesiredAimVector() return self.vDesAim || self:GetForward() end
function ENT:SetDesiredAimVector( v ) self.vDesAim = v end

function ENT:EyeAngles() return self:GetAimVector():Angle() end
function ENT:SetEyeAngles( a ) self.vAim = a:Forward() end
