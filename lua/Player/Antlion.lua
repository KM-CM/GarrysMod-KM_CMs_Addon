player_manager.AddValidModel( "Antlion_Soldier", "models/antlion.mdl" )

local Antlion_Soldier_Health = CreateConVar( "Antlion_Soldier_Health", 600, FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_CHEAT )
local Antlion_Soldier_Melee_Damage = CreateConVar( "Antlion_Soldier_Melee_Damage", 640, FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_CHEAT )

IN_NOT_USE = bit.bnot( IN_USE )

__PLAYER_MODEL__[ "models/antlion.mdl" ] = {
	bCantSlide = true,
	bAllDirectionalSprint = true,
	bAllowMovingWhileInAir = true,
	CalcMainActivity = function( ply, MyTable )
		if SERVER then
			for _, wep in ipairs( ply:GetWeapons() ) do if wep:GetClass() != "hands" && wep:GetClass() != "gmod_tool" then ply:DropWeapon( wep ) end end
		end
		if ply:IsOnGround() then
			ply:SetBodygroup( 1, 0 )
			if !ply.MDL_bWasOnGround then
				ply:EmitSound "NPC_Antlion.Land"
				local s = ply:LookupSequence "jump_stop"
				ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_JUMP, s, 0, true )
				ply.MDL_flDontMoveTime = CurTime() + ply:SequenceDuration( s )
				ply.MDL_bWasOnGround = true
			end
		else
			ply.MDL_bWasOnGround = nil
			ply:SetBodygroup( 1, 1 )
			return ACT_GLIDE
		end
		local v = Vector( 0, 0, 24 )
		ply:SetViewOffset( v )
		ply:SetViewOffsetDucked( v )
		local vMins, vMaxs = Vector( -16, -16, 0 ), Vector( 16, 16, 64 )
		ply:SetHull( vMins, vMaxs )
		ply:SetHullDuck( vMins, vMaxs )
		if ( IsValid( ply:GetActiveWeapon() ) && ply:GetActiveWeapon():GetClass() == "hands" ) && CurTime() > ( ply.MDL_flDontMoveTime || 0 ) then
			ply:GetActiveWeapon().Crosshair = nil
			if ply:KeyDown( IN_ATTACK ) then
				// We Allow Ourselves to Use Non-Shared Randoms Because
				// We Dont Really Care What Animation is Going on
				// Since They All Hit The Same
				local s = ply:LookupSequence( table.Random { "attack1", "attack2", "attack3", "attack4", "attack5", "attack6", "pounce", "pounce2" } )
				ply:EmitSound( math.random( 2 ) == 1 && "NPC_Antlion.MeleeAttackSingle" || "NPC_Antlion.MeleeAttackDouble" )
				if SERVER then
					timer.Simple( .5, function()
						if !IsValid( ply ) then return end
						local vMins, vMaxs, v, bHit = ply:OBBMins(), ply:OBBMaxs(), ply:GetAimVector()
						vMins.z = vMins.z + 8
						v.z = 0
						v:Normalize()
						local tr = util.TraceHull {
							mins = vMins,
							maxs = vMaxs,
							filter = function( ent )
								if ent == ply then return end
								if IsValid( ent ) then
									local dmg = DamageInfo()
									dmg:SetDamage( Antlion_Soldier_Melee_Damage:GetFloat() )
									dmg:SetDamageType( DMG_SLASH )
									dmg:SetAttacker( ply )
									dmg:SetInflictor( ply )
									ent:TakeDamageInfo( dmg )
								end
								bHit = true
							end,
							start = ply:GetPos(),
							endpos = ply:GetPos() + v * vMaxs.x * 8,
							mask = MASK_SOLID
						}
						if tr.Hit || bHit then
							ply:EmitSound "NPC_Antlion.MeleeAttack"
						end
					end )
				end
				ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD, s, 0, true )
				ply.MDL_flDontMoveTime = CurTime() + ply:SequenceDuration( s )
				ply.MDL_flNextMelee = ply.MDL_flDontMoveTime
				return ACT_INVALID
			end
		end
		local v = ply:GetVelocity()
		ply:SetRunSpeed( ply:GetSequenceGroundSpeed( ply:LookupSequence "run_all" ) )
		local f = ply:GetSequenceGroundSpeed( ply:LookupSequence "walk_all" )
		ply:SetWalkSpeed( f )
		ply:SetSlowWalkSpeed( f )
		ply:SetJumpPower( ( 2 * GetConVarNumber "sv_gravity" * 512 ) ^ .5 )
		local c = ply:GetPoseParameter "move_yaw"
		if CLIENT then c = math.Remap( c, 0, 1, ply:GetPoseParameterRange( ply:LookupPoseParameter "move_yaw" ) ) end
		ply:SetPoseParameter( "move_yaw", c + math.Clamp( math.AngleDifference( v:Angle().y, ply:GetAngles().y + c ), -360 * FrameTime(), 360 * FrameTime() ) )
		local f = v:Length()
		return f > ply:GetRunSpeed() && ACT_RUN || f < 10 && ACT_IDLE || ACT_WALK
	end,
	TranslateActivity = function( ply, act ) return act == 0 && ply.CalcIdeal || act end,
	PlayerFootstep = function() return true end,
	PlayerHandleAnimEvent = function( ply, event )
		local s = util.GetAnimEventNameByID( event )
		if s == "AE_CITIZEN_HEAL" || s == "CL_EVEN_EJECTBRASS1" then ply:EmitSound "NPC_Antlion.Footstep" end
	end,
	PlayerSpawnAny = function( ply )
		timer.Simple( 0, function()
			local f = Antlion_Soldier_Health:GetInt()
			ply:SetHealth( f )
			ply:SetMaxHealth( f )
			ply:SetNPCClass( CLASS_ANTLION )
		end )
	end,
	GetFallDamage = function() return 0 end,
	StartCommand = function( ply, cmd )
		cmd:SetButtons( bit.band( cmd:GetButtons(), IN_NOT_USE ) )
		if CurTime() <= ( ply.MDL_flDontMoveTime || 0 ) then
			cmd:SetForwardMove( 0 )
			cmd:SetSideMove( 0 )
			cmd:SetButtons( 0 )
			return true
		end
	end
}

if !IsMounted "ep2" then return end

player_manager.AddValidModel( "Antlion_Worker", "models/antlion_worker.mdl" )

local Antlion_Worker_Health = CreateConVar( "Antlion_Worker_Health", 400, FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_CHEAT )
local Antlion_Worker_Melee_Damage = CreateConVar( "Antlion_Worker_Melee_Damage", 512, FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_CHEAT )
local Antlion_Worker_Acid_Speed = CreateConVar( "Antlion_Worker_Acid_Speed", 2000, FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_CHEAT )

IN_NOT_USE = bit.bnot( IN_USE )

__PLAYER_MODEL__[ "models/antlion_worker.mdl" ] = {
	bCantSlide = true,
	bAllDirectionalSprint = true,
	bAllowMovingWhileInAir = true,
	CalcMainActivity = function( ply, MyTable )
		if SERVER then
			for _, wep in ipairs( ply:GetWeapons() ) do if wep:GetClass() != "hands" && wep:GetClass() != "gmod_tool" then ply:DropWeapon( wep ) end end
		end
		if ply:IsOnGround() then
			ply:SetBodygroup( 1, 0 )
			if !ply.MDL_bWasOnGround then
				ply:EmitSound "NPC_Antlion.Land"
				local s = ply:LookupSequence "jump_stop"
				ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_JUMP, s, 0, true )
				ply.MDL_flDontMoveTime = CurTime() + ply:SequenceDuration( s )
				ply.MDL_bWasOnGround = true
			end
		else
			ply.MDL_bWasOnGround = nil
			ply:SetBodygroup( 1, 1 )
			return ACT_GLIDE
		end
		local v = Vector( 0, 0, 24 )
		ply:SetViewOffset( v )
		ply:SetViewOffsetDucked( v )
		local vMins, vMaxs = Vector( -16, -16, 0 ), Vector( 16, 16, 64 )
		ply:SetHull( vMins, vMaxs )
		ply:SetHullDuck( vMins, vMaxs )
		if ( IsValid( ply:GetActiveWeapon() ) && ply:GetActiveWeapon():GetClass() == "hands" ) && CurTime() > ( ply.MDL_flDontMoveTime || 0 ) then
			ply:GetActiveWeapon().Crosshair = nil
			if ply:KeyDown( IN_ATTACK ) then
				// We Allow Ourselves to Use Non-Shared Randoms Because
				// We Dont Really Care What Animation is Going on
				// Since They All Hit The Same
				local s = ply:LookupSequence( table.Random { "attack1", "attack2", "attack3", "attack4", "attack5", "attack6", "pounce", "pounce2" } )
				ply:EmitSound( math.random( 2 ) == 1 && "NPC_Antlion.MeleeAttackSingle" || "NPC_Antlion.MeleeAttackDouble" )
				if SERVER then
					timer.Simple( .5, function()
						if !IsValid( ply ) then return end
						local vMins, vMaxs, v, bHit = ply:OBBMins(), ply:OBBMaxs(), ply:GetAimVector()
						vMins.z = vMins.z + 8
						v.z = 0
						v:Normalize()
						local tr = util.TraceHull {
							mins = vMins,
							maxs = vMaxs,
							filter = function( ent )
								if ent == ply then return end
								if IsValid( ent ) then
									local dmg = DamageInfo()
									dmg:SetDamage( Antlion_Worker_Melee_Damage:GetFloat() )
									dmg:SetDamageType( DMG_SLASH )
									dmg:SetAttacker( ply )
									dmg:SetInflictor( ply )
									ent:TakeDamageInfo( dmg )
								end
								bHit = true
							end,
							start = ply:GetPos(),
							endpos = ply:GetPos() + v * vMaxs.x * 8,
							mask = MASK_SOLID
						}
						if tr.Hit || bHit then
							ply:EmitSound "NPC_Antlion.MeleeAttack"
						end
					end )
				end
				ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD, s, 0, true )
				ply.MDL_flDontMoveTime = CurTime() + ply:SequenceDuration( s )
				ply.MDL_flNextMelee = ply.MDL_flDontMoveTime
				return ACT_INVALID
			elseif ply:KeyDown( IN_ATTACK2 ) then
				local s = ply:LookupSequence "spit"
				ply:AddVCDSequenceToGestureSlot( GESTURE_SLOT_ATTACK_AND_RELOAD, s, 0, true )
				ply.MDL_flDontMoveTime = CurTime() + ply:SequenceDuration( s )
				ply:EmitSound "NPC_Antlion.PoisonShoot"
				if SERVER then
					timer.Simple( .5, function()
						if !IsValid( ply ) then return end
						local at = ply:GetAttachment( ply:LookupAttachment "mouth" )
						if !at then return end
						local vSpit, vVelocity, flVelocity = at.Pos, ply:GetAimVector(), Antlion_Worker_Acid_Speed:GetFloat()
						for i = 0, 6 do
							local pGrenade = ents.Create "grenade_spit"
							pGrenade:SetPos( vSpit )
							pGrenade:SetOwner( ply )
							pGrenade:Spawn()
							if i == 0 then
								pGrenade:SetModel "models/spitball_large.mdl"
								pGrenade:SetVelocity( vVelocity * flVelocity )
							else
								pGrenade:SetModel( math.random( 2 ) == 1 && "models/spitball_medium.mdl" || "models/spitball_small.mdl" )
								pGrenade:SetVelocity( ( vVelocity + VectorRand( -.035, .035 ) ) * flVelocity )
							end
							pGrenade:SetLocalAngularVelocity( Angle( math.Rand( -250, -500 ), math.Rand( -250, -500 ), math.Rand( -250, -500 ) ) )
						end
					end )
				end
			end
		end
		local v = ply:GetVelocity()
		ply:SetRunSpeed( ply:GetSequenceGroundSpeed( ply:LookupSequence "run_all" ) )
		local f = ply:GetSequenceGroundSpeed( ply:LookupSequence "walk_all" )
		ply:SetWalkSpeed( f )
		ply:SetSlowWalkSpeed( f )
		ply:SetJumpPower( ( 2 * GetConVarNumber "sv_gravity" * 512 ) ^ .5 )
		local c = ply:GetPoseParameter "move_yaw"
		if CLIENT then c = math.Remap( c, 0, 1, ply:GetPoseParameterRange( ply:LookupPoseParameter "move_yaw" ) ) end
		ply:SetPoseParameter( "move_yaw", c + math.Clamp( math.AngleDifference( v:Angle().y, ply:GetAngles().y + c ), -360 * FrameTime(), 360 * FrameTime() ) )
		local f = v:Length()
		return f > ply:GetRunSpeed() && ACT_RUN || f < 10 && ACT_IDLE || ACT_WALK
	end,
	TranslateActivity = function( ply, act ) return act == 0 && ply.CalcIdeal || act end,
	PlayerFootstep = function() return true end,
	PlayerHandleAnimEvent = function( ply, event )
		local s = util.GetAnimEventNameByID( event )
		if s == "AE_CITIZEN_HEAL" || s == "CL_EVEN_EJECTBRASS1" then ply:EmitSound "NPC_Antlion.Footstep" end
	end,
	PlayerSpawnAny = function( ply )
		timer.Simple( 0, function()
			local f = Antlion_Worker_Health:GetInt()
			ply:SetHealth( f )
			ply:SetMaxHealth( f )
			ply:SetNPCClass( CLASS_ANTLION )
		end )
	end,
	GetFallDamage = function() return 0 end,
	StartCommand = function( ply, cmd )
		cmd:SetButtons( bit.band( cmd:GetButtons(), IN_NOT_USE ) )
		if CurTime() <= ( ply.MDL_flDontMoveTime || 0 ) then
			cmd:SetForwardMove( 0 )
			cmd:SetSideMove( 0 )
			cmd:SetButtons( 0 )
			return true
		end
	end
}
