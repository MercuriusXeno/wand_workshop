dofile_once("mods/wand_workshop/files/entities/altar/altar.lua")

function item_pickup( entity_item, entity_who_picked, name )
  local entity_id = GetUpdatedEntityID()
  local altar_id = get_altar(entity_id)
  if altar_id == 0 then
    return
  end
  unlink_altar_wand(altar_id, entity_id)
end
