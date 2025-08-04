dofile_once("mods/wand_workshop/files/scripts/altar.lua")

-- don't change the name of this or it breaks, big brain nolla hard coding.
function collision_trigger(colliding_entity_id)
    local altar_id = GetUpdatedEntityID()
    Collide(altar_id, colliding_entity_id)
end