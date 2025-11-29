local player_Iterator = player.Iterator

local CEntity_GetTable = FindMetaTable( "Entity" ).GetTable

local IsValid = IsValid

local Vector = Vector

include "autorun/Director.lua"

local function Director_GetThreat( pPlayer, pEntity )
	if IsValid( pEntity.Enemy ) then return DIRECTOR_THREAT_COMBAT end
	local f = pEntity.GetEnemy
	if f && IsValid( f( pEntity ) ) then return DIRECTOR_THREAT_COMBAT end
	local f = pEntity.GetNPCState
	if f then
		f = f( pEntity )
		if f == NPC_STATE_COMBAT then
			return DIRECTOR_THREAT_COMBAT
		elseif f == NPC_STATE_ALERT then
			return DIRECTOR_THREAT_ALERT
		else
			local f = pEntity.Disposition
			if f then
				f = f( pEntity, pPlayer )
				if f == D_FR || f == D_HT then return DIRECTOR_THREAT_HEAT end
			end
		end
	else
		local f = pEntity.Disposition
		if f then
			f = f( pEntity, pPlayer )
			if f == D_FR || f == D_HT then return DIRECTOR_THREAT_HEAT end
		end
	end
	return DIRECTOR_THREAT_NULL
end

local VectorZ28 = Vector( 0, 0, 28 )
hook.Add( "Tick", "Director", function()
	for _, ply in player_Iterator() do
		local PlyTable = CEntity_GetTable( ply )
		local pFlashlight = PlyTable.GAME_pFlashlight
		if IsValid( pFlashlight ) then pFlashlight:SetPos( ply:GetShootPos() ) end
		local v = __PLAYER_MODEL__[ ply:GetModel() ]
		if v then
			v = v.Think
			if v then v( ply, PlyTable ) end
		end
		ply:SetNW2Float( "GAME_flOxygenLimit", PlyTable.GAME_flOxygenLimit || 30 )
		if ply:Alive() then
			local o = ply:GetNW2Float( "GAME_flOxygen", ply:GetNW2Float( "GAME_flOxygenLimit", -1 ) )
			if o == 0 then
				ply:SetHealth( 0 )
				local d = DamageInfo()
				d:SetAttacker( ply )
				d:SetInflictor( ply )
				d:SetDamage( 1 )
				d:SetDamageType( DMG_DROWN )
				ply:TakeDamageInfo( d )
				continue
			end
			local f = ply:GetNW2Float( "GAME_flBleeding", 0 )
			if f > 0 && f > .0016 && CurTime() > ( PlyTable.GAME_flNextBleed || 0 ) then
				ply:EmitSound "Bleed"
				local v = ply:GetPos()
				local f = ply:BoundingRadius()
				util.Decal( "Blood", v, v + Vector( 0, 0, ply:OBBMins()[ 3 ] - f * 12 ), ply )
				v = v + ply:OBBCenter()
				f = f * 4
				local d = ply:GetRight()
				v = ply:NearestPoint( v + d * 999999 )
				util.Decal( "Blood", v, v + d * f, ply )
				local d = -d
				v = ply:NearestPoint( v + d * 999999 )
				util.Decal( "Blood", v, v + d * f, ply )
				local d = ply:GetForward()
				v = ply:NearestPoint( v + d * 999999 )
				util.Decal( "Blood", v, v + d * f, ply )
				local d = -d
				v = ply:NearestPoint( v + d * 999999 )
				util.Decal( "Blood", v, v + d * f, ply )
				PlyTable.GAME_flNextBleed = CurTime() + math.Clamp( .033 / f, .5, 12 ) * math.Rand( .9, 1.1 )
			end
			local flBlood = math.Clamp( ply:GetNW2Float( "GAME_flBlood", 1 ) + ( f > 0 && ( .0016 - f ) || .016 ) * FrameTime(), 0, 1 )
			ply:SetNW2Float( "GAME_flBlood", flBlood )
			o = o - FrameTime()
			ply:SetNW2Float( "GAME_flOxygen", math.Clamp(

			o + ( ply:WaterLevel() >= 3 && 0 || (
			1 / ( 1 + math.exp( -18 * ( flBlood - .55 ) ) ) * // Blood efficiency formula
			( 1 + ( ply.GAME_flOxygenRegen || ( ply:GetNW2Float( "GAME_flOxygenLimit", 0 ) * .5 ) ) ) ) )

			* FrameTime(), 0, ply:GetNW2Float( "GAME_flOxygenLimit", 0 ) ) )
		else
			ply:SetNW2Float( "GAME_flOxygen", ply:GetNW2Float( "GAME_flOxygenLimit", 0 ) )
			ply:SetNW2Float( "GAME_flBlood", 1 )
			ply:SetNW2Float( "GAME_flBleeding", 0 )
		end
		ply:SetViewOffset( ply:GetViewOffset() )
		ply:SetViewOffsetDucked( ply:GetViewOffsetDucked() )
		ply:SetCanZoom( false )
		local h = ply:Health() / ply:GetMaxHealth()
		ply:SetDSP( h <= .165 && 16 || h <= .33 && 15 || h <= .66 && 14 || 1 )
		PlyTable.GAME_flSuppression = math.Approach( PlyTable.GAME_flSuppression || 0, 0, math.max( ply:Health() * 2, ( PlyTable.GAME_flSuppression || 0 ) * .33 ) * FrameTime() )
		local EThreat, flIntensity = DIRECTOR_THREAT_NULL, ply:GetNW2Float( "GAME_flSuppressionEffects", 0 ), 0
		local tMusicEntities = {}
		for pEntity in ipairs( PlyTable.DR_tMusicEntities || {} ) do
			if !IsValid( pEntity ) then continue end
			local ETheirThreat = Director_GetThreat( ply, pEntity )
			if ETheirThreat > EThreat then EThreat = ETheirThreat end
		end
		PlyTable.DR_tMusicEntities = tMusicEntities
		ply:SendLua( "DIRECTOR_THREAT=" .. tostring( EThreat ) )
		ply:SendLua( "DIRECTOR_MUSIC_INTENSITY=" .. tostring( flIntensity ) )
		local flTension = Lerp( .1 * FrameTime(), PlyTable.DR_flMusicTension || 0, flIntensity )
		PlyTable.DR_flMusicTension = flTension
		ply:SendLua( "DIRECTOR_MUSIC_TENSION=" .. tostring( flTension ) )
	end
end )
