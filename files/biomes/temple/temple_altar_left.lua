---@diagnostic disable: lowercase-global, missing-global-doc
dofile_once("mods/wand_workshop/files/scripts/debug.lua")
local old_init = init
Log("Overwriting old_init in temple_altar_left")
function init(x, y, w, h, ...)
  old_init(x, y, w, h, ...)
  local scene_x = x + 314
  -- even though the actual offset in the file is 86
  -- the vanilla pixel scene has a +260 y offset. We apply that here.
  local scene_y = y + 346
  LoadPixelScene(
    "mods/wand_workshop/files/biomes/temple/altar_left.png",
    "mods/wand_workshop/files/biomes/temple/altar_left_visual.png",
    scene_x, scene_y, "", true) -- needs the duplicate loader to work at all
  -- transforms have been standardized to a 58x58 that always has the same proportions/relative distances
  local y_offset = -5
  local target_altar_x = scene_x + 28
  local target_altar_y = scene_y + y_offset
  local offer_altar_x = target_altar_x
  local offer_altar_y = target_altar_y + 48
  Log("Spawning target altar at " .. target_altar_x .. " " .. target_altar_y)
  EntityLoad("mods/wand_workshop/files/entities/target_altar.xml", target_altar_x, target_altar_y)

  Log("Spawning offer altar at " .. offer_altar_x .. " " .. offer_altar_y)
  EntityLoad("mods/wand_workshop/files/entities/offer_altar.xml", offer_altar_x, offer_altar_y)
end
