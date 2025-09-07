if !IsMounted "ep2" then return end

player_manager.AddValidModel( "Combine_Hunter", "models/hunter.mdl" )

__PLAYER_MODEL__[ "models/hunter.mdl" ] = {
	bCantSlide = true,
	bAllDirectionalSprint = true,
	bAllowMovingWhileInAir = true,
	CalcMainActivity = function( ply, MyTable )
		ply:SetRunSpeed( ply:GetSequenceGroundSpeed( ply:LookupSequence "canter_all" ) )
		ply:SetWalkSpeed( ply:GetSequenceGroundSpeed( ply:LookupSequence "prowl_all" ) )
		ply:SetSlowWalkSpeed( ply:GetSequenceGroundSpeed( ply:LookupSequence "walk_all" ) )
		ply:SetJumpPower( ( 2 * GetConVarNumber "sv_gravity" * 220 ) ^ .5 )
		ply:SetViewOffsetDucked( ply:GetViewOffset() )
		local flPitch, flYaw = ply:GetPoseParameter "aim_pitch", ply:GetPoseParameter "aim_yaw"
		if CLIENT then
			flPitch = math.Remap( flPitch, 0, 1, ply:GetPoseParameterRange( ply:LookupPoseParameter "aim_pitch" ) )
			flYaw = math.Remap( flYaw, 0, 1, ply:GetPoseParameterRange( ply:LookupPoseParameter "aim_yaw" ) )
		end
		local ang = ply:GetAimVector():Angle()
		if ply:GetNW2Int "DR_ThreatAware" == DIRECTOR_THREAT_COMBAT then
			ply:SetPoseParameter( "aim_pitch", flPitch + .8 * math.Clamp( math.AngleDifference( ang.p, ply:GetAngles().p + flPitch ), -20 * FrameTime(), 20 * FrameTime() ) )
			ply:SetPoseParameter( "aim_yaw", flYaw + .6 * math.AngleDifference( ang.y, ply:GetAngles().y + flYaw ) )
		else
			ply:SetPoseParameter( "aim_pitch", flPitch + .6 * math.Clamp( math.AngleDifference( ang.p, ply:GetAngles().p + flPitch ), -20 * FrameTime(), 20 * FrameTime() ) )
			ply:SetPoseParameter( "aim_yaw", flYaw + .6 * math.AngleDifference( ang.y, ply:GetAngles().y + flYaw ) )
		end
		if SERVER then
			for _, wep in ipairs( ply:GetWeapons() ) do if wep:GetClass() != "hands" then ply:DropWeapon( wep ) end end
			if ply:KeyDown( IN_ATTACK ) && CurTime() > ( ply.MDL_flNextShot || 0 ) && ( ply.MDL_bPlanted || CurTime() > ( ply.MDL_flNextIdleVolleyTime || 0 ) ) then
				local fs = ply.MDL_flIdleShots
				if fs then fs = fs - 1 ply.MDL_flIdleShots = fs else ply.MDL_flIdleShots = math.Rand( 1, 3 ) end
				ply.MDL_bShoot = !ply.MDL_bShoot
				local f = ents.Create "hunter_flechette"
				f:SetPos( ply:GetBonePosition( ply:LookupBone( ply.MDL_bShoot && "MiniStrider.low_eye_bone" || "MiniStrider.top_eye_bone" ) ) )
				local d = ply:GetAimVector()
				f:SetAngles( d:Angle() )
				f:SetOwner( ply )
				f:Spawn()
				f:SetVelocity( d * GetConVarNumber "hunter_flechette_speed" )
				ply:EmitSound "NPC_Hunter.FlechetteShoot"
				ply.MDL_flNextShot = CurTime() + .1
				if !ply.MDL_bPlanted then if ply.MDL_flIdleShots <= 0 then ply.MDL_flNextIdleVolleyTime = CurTime() + math.Rand( .33, .66 ) ply.MDL_flIdleShots = nil end end
			end
		elseif CLIENT then
			local w = ply:GetWeapon "hands"
			if IsValid( w ) then w.Crosshair = nil end
		end
		if CurTime() <= ( ply.MDL_flDontMoveTime || 0 ) then return ACT_INVALID end
		local b = ply:IsOnGround()
		if b then
			if !ply.MDL_bWasOnGround then
				ply:AnimRestartGesture( GESTURE_SLOT_JUMP, ACT_LAND, true )
				ply.MDL_flDontMoveTime = CurTime() + ply:SequenceDuration( ply:LookupSequence "jump_land" )
				ply.MDL_bWasOnGround = true
				return
			end
			if ply:KeyDown( IN_DUCK ) then
				if !ply.MDL_bPlanted then
					local s = ply:LookupSequence "plant"
					ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD, s, 0, true )
					ply.MDL_flDontMoveTime = CurTime() + ply:SequenceDuration( s )
					ply.MDL_bPlanted = true
					ply.MDL_bShootSequence = nil
				elseif !ply.MDL_bShootSequence then
					ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD, ply:LookupSequence "shoot_minigun" )
					ply.MDL_bShootSequence = true
				end
			elseif ply.MDL_bPlanted then
				local s = ply:LookupSequence "unplant"
				ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD, s, 0, true )
				ply.MDL_flDontMoveTime = CurTime() + ply:SequenceDuration( s )
				ply.MDL_bPlanted = nil
			end
			if ply.MDL_bPlanted then
				ply.MDL_flDontOnlyMoveTime = CurTime() + ply:SequenceDuration( ply:LookupSequence "unplant" )
				return ACT_INVALID
			elseif ply:KeyDown( IN_ATTACK2 ) && CurTime() > ( ply.MDL_flNextMelee || 0 ) then
				if ply:KeyDown( IN_SPEED ) then
				else
					//We Allow Ourselves to Use Shared Randoms Because
					//We Dont Really Care What Animation is Going on
					//Since They All Hit The Same
					local s = ply:LookupSequence( table.Random { "meleeleft", "meleert", "melee_02" } )
					ply:EmitSound "NPC_Hunter.MeleeAnnounce"
					if SERVER then
						timer.Simple( .5, function()
							if !IsValid( ply ) then return end
							local vMins, vMaxs = ply:OBBMins(), ply:OBBMaxs()
							vMins.z = vMins.x
							vMaxs.z = vMaxs.x
							local tr = util.TraceHull {
								mins = vMins,
								maxs = vMaxs,
								filter = ply,
								start = ply:EyePos(),
								endpos = ply:EyePos() + ply:GetAimVector() * vMaxs.x * 6,
							}
							if tr.Hit then
								local ent = tr.Entity
								if IsValid( ent ) then
									local dmg = DamageInfo()
									dmg:SetDamage( 40 )
									dmg:SetDamageType( DMG_SLASH )
									dmg:SetAttacker( ply )
									dmg:SetInflictor( ply )
									ent:TakeDamageInfo( dmg )
								end
								ply:EmitSound "NPC_Hunter.MeleeHit"
								ply:EmitSound "NPC_Hunter.TackleHit"
							end
						end )
					end
					ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD, s, 0, true )
					ply.MDL_flDontMoveTime = CurTime() + ply:SequenceDuration( s )
					ply.MDL_flNextMelee = ply.MDL_flDontMoveTime
					return ACT_INVALID
				end
			end
		else
			ply.MDL_bWasOnGround = nil
			return ACT_GLIDE
		end
		local vel = ply:GetVelocity()
		local c = ply:GetPoseParameter "move_yaw"
		if CLIENT then c = math.Remap( c, 0, 1, ply:GetPoseParameterRange( ply:LookupPoseParameter "move_yaw" ) ) end
		ply:SetPoseParameter( "move_yaw", c + math.Clamp( math.AngleDifference( vel:Angle().y, ply:GetAngles().y + c ), -360 * FrameTime(), 360 * FrameTime() ) )
		local f = vel:Length()
		local bSprinting = ply:IsSprinting()
		return f >= ( bSprinting && 12 || 24 ) && (
			bSprinting && ACT_RUN ||
			(
				f >= ply:GetWalkSpeed() * .8
				|| ply:GetNW2Int "DR_ThreatAware" == DIRECTOR_THREAT_COMBAT
			) && ply:GetSequenceActivity( ply:LookupSequence "prowl_all" )
			|| ACT_WALK
		) || ACT_IDLE
	end,
	TranslateActivity = function( ply, act ) return act == 0 && ply.CalcIdeal || act end,
	PlayerFootstep = function() return true end,
	PlayerHandleAnimEvent = function( ply, event )
		local s = util.GetAnimEventNameByID( event )
		if s == "CL_EVENT_EJECTBRASS1" || s == "AE_CITIZEN_HEAL" then ply:EmitSound "NPC_Hunter.Footstep"
		elseif s == "COMBINE_AE_ALTFIRE" then ply:EmitSound "NPC_Hunter.BackFootstep" end
	end,
	PlayerSpawnAny = function( ply )
		timer.Simple( 0, function()
			local f = 20000
			ply:SetHealth( f )
			ply:SetMaxHealth( f )
		end )
	end,
	GetFallDamage = function() return 0 end,
	StartCommand = function( ply, cmd )
		if CurTime() <= ( ply.MDL_flDontMoveTime || 0 ) then
			cmd:SetForwardMove( 0 )
			cmd:SetSideMove( 0 )
			cmd:SetButtons( 0 )
		elseif CurTime() <= ( ply.MDL_flDontOnlyMoveTime || 0 ) then
			cmd:SetForwardMove( 0 )
			cmd:SetSideMove( 0 )
		end
	end
}
