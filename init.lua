dofile_once("mods/wand_workshop/files/scripts/debug.lua")

Log("wand_workshop init.lua running")

ModLuaFileAppend( "data/scripts/biomes/temple_altar_left.lua", "mods/wand_workshop/files/biomes/temple_altar_left.lua" )

Log("wand_workshop init.lua ran")

-- helpers to stop me from fat fingering keys
local emit_last_key = "wand_workshop.emit_last"
local emit_cooldown_key = "wand_workshop.emit_cooldown"
local is_debug_mode_key = "wand_workshop.is_debug_mode"
local is_debug_emit_allowed_key = "wand_workshop.is_debug_emit_allowed"

-- mod-global settings happen before world initialization
ModSettingSet(emit_cooldown_key, "60")
ModSettingSet(is_debug_mode_key, "true") -- this enables logging globally
ModSettingSet(is_debug_emit_allowed_key, "false") -- this enables logging globally    

function OnWorldInitialized() -- This is called once the game world is initialized. Doesn't ensure any world chunks actually exist. Use OnPlayerSpawned to ensure the chunks around player have been loaded or created.	
    -- Some global stuff I do for debugs to make my brain hurt less
    GlobalsSetValue(emit_last_key, "-60") -- this is for particles for showing stuff works
end

--[[
function OnModPreInit()
	print("Mod - OnModPreInit()") -- First this is called for all mods
end

function OnModInit()
	print("Mod - OnModInit()") -- After that this is called for all mods
end

function OnModPostInit()
	print("Mod - OnModPostInit()") -- Then this is called for all mods
end

function OnPlayerSpawned( player_entity ) -- This runs when player entity has been created
	GamePrint( "OnPlayerSpawned() - Player entity id: " .. tostring(player_entity) )
end

function OnWorldPreUpdate() -- This is called every time the game is about to start updating the world
	GamePrint( "Pre-update hook " .. tostring(GameGetFrameNum()) )
end

function OnWorldPostUpdate() -- This is called every time the game has finished updating the world
	GamePrint( "Post-update hook " .. tostring(GameGetFrameNum()) )
end
]]--