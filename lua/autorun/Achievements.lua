// NOTE: Achievements have a VERY limited API for now!

if CLIENT then
	local surface_PlaySound = surface.PlaySound
	local chat_AddText = chat.AddText
	local language_GetPhrase = language.GetPhrase
	// Called when we get an achievement
	local cAchievementTextColor = Color( 255, 255, 0 )
	function Achievement_Acquire( sName )
		surface_PlaySound "Achievement.wav"
		sName = "Achievement_Acquire_" .. sName
		chat_AddText( cAchievementTextColor, "✦ ", language_GetPhrase( sName .. "_Header" ), cAchievementTextColor, " : ", language_GetPhrase( sName .. "_Text" ), cAchievementTextColor, " ✦" )
	end
	function Achievement_Miscellaneous( sName )
		surface_PlaySound "Achievement.wav"
		sName = "Achievement_Miscellaneous_" .. sName
		chat_AddText( cAchievementTextColor, "✦ ", language_GetPhrase( sName .. "_Header" ), cAchievementTextColor, " : ", language_GetPhrase( sName .. "_Text" ), cAchievementTextColor, " ✦" )
	end
	return
end

__ACHIEVEMENTS__ = __ACHIEVEMENTS__ || {}

// SteamID64 -> { String = true }
__ACHIEVEMENTS_ACQUIRED__ = __ACHIEVEMENTS_ACQUIRED__ || util.JSONToTable( file.Read( "Achievements/" .. engine.ActiveGamemode() .. ".json" ) || "[]", true, true )

function ACHIEVEMENT_ACQUIRE( sClass ) __ACHIEVEMENTS__[ "Acquire_" .. sClass ] = true end

function ACHIEVEMENT_MISCELLANEOUS( sName ) __ACHIEVEMENTS__[ "Miscellaneous_" .. sName ] = true end

function Achievement_Miscellaneous( ply, sName )
	local s = ply:SteamID64()
	local t = __ACHIEVEMENTS_ACQUIRED__[ s ]
	local sAchievement = "Miscellaneous_" .. sName
	if t then
		if !t[ sAchievement ] then
			ply:SendLua( "Achievement_Miscellaneous(\"" .. sName ..  "\")" )
			t[ sAchievement ] = true
		end
	else
		ply:SendLua( "Achievement_Miscellaneous(\"" .. sName .. "\")" )
		__ACHIEVEMENTS_ACQUIRED__[ s ] = { [ sAchievement ] = true }
	end
end

function Achievement_Has( ply, sName )
	local s = ply:SteamID64()
	local t = __ACHIEVEMENTS_ACQUIRED__[ s ]
	if t then if t[ sName ] then return true end end
end

function Achievement_Miscellaneous_Grant( ply, sName )
	local s = ply:SteamID64()
	local t = __ACHIEVEMENTS_ACQUIRED__[ s ]
	if t then
		ply:SendLua( "Achievement_Miscellaneous(\"" .. sName ..  "\")" )
		t[ "Miscellaneous_" .. sName ] = true
	else
		ply:SendLua( "Achievement_Miscellaneous(\"" .. sName .. "\")" )
		__ACHIEVEMENTS_ACQUIRED__[ s ] = { [ sName ] = true }
	end
end
