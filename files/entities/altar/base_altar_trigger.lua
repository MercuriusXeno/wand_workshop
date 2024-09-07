local s,e = dofile_once("mods/wand_workshop/files/scripts/config.lua")
if e ~= nil then
	print(e)
	return
end
s,e = dofile_once("mods/wand_workshop/files/entities/altar/altar.lua")
if e ~= nil then
	print(e)
	return
end

function collision_trigger(colliding_entity_id)
  local entity_id = GetUpdatedEntityID()
  if EntityHasTag(colliding_entity_id, "wand") then
    local parent_id = EntityGetParent(colliding_entity_id)
    if parent_id ~= 0 then
      local parent_name = EntityGetName(parent_id)
      if parent_name == "inventory_quick" then
        return
      end
    end
    local pickup_script = "mods/wand_workshop/files/scripts/sacrifice_wand_pickup.lua"
    if EntityHasTag(entity_id, "Wand_Altar") then
      pickup_script = "mods/wand_workshop/files/entities/altar/main_wand_pickup.lua"
    end
    link_altar_wand(entity_id, colliding_entity_id)
    hover_wand(colliding_entity_id, entity_id)
    
    component_id = EntityAddComponent(colliding_entity_id, "LuaComponent", {
        execute_every_n_frame = -1,
        script_item_picked_up = pickup_script,
        remove_after_executed = 1
      } )
    EntitySetComponentIsEnabled(colliding_entity_id, component_id, true )
  end
end
