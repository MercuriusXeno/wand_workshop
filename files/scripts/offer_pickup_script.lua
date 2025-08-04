dofile_once("mods/wand_workshop/files/scripts/altar.lua")

--don't rename this, big brain nolla hard coding
function item_pickup( entity_item, entity_who_picked, name )
  local entity_id = GetUpdatedEntityID()
  local altar_id = Get_Offer_Altar(entity_id)
  if altar_id == 0 then
    return
  end
  Unlink_Item(altar_id, entity_id)
end