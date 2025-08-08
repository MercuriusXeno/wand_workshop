---@diagnostic disable: lowercase-global, missing-global-doc
local old_init = init
function init(x, y, w, h, ...)
  old_init(x, y, w, h, ...)
  local scene_x = x + 195
  local scene_y = y + 378
  LoadPixelScene("mods/wand_workshop/files/biomes/mountain/hall.png",
    "mods/wand_workshop/files/biomes/mountain/hall_visual.png",
    scene_x, scene_y, "", true)
  -- transforms have been standardized to a 58x58 that always has the same proportions/relative distances
  local y_offset = -5
  local target_altar_x = scene_x + 28
  local target_altar_y = scene_y + y_offset
  local offer_altar_x = target_altar_x
  local offer_altar_y = target_altar_y + 48
  EntityLoad("mods/wand_workshop/files/entities/target_altar.xml", target_altar_x, target_altar_y)
  EntityLoad("mods/wand_workshop/files/entities/offer_altar.xml", offer_altar_x, offer_altar_y)
end