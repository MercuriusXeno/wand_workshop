dofile_once("mods/wand_workshop/files/scripts/altar.lua")
dofile_once("mods/wand_workshop/files/scripts/debug.lua")
Log("altar collision loaded")

-- don't change the name of this or it breaks, big brain nolla hard coding.
function collision_trigger(colliding_entity_id)
    Log("Collision fired!")
    local altar_id = GetUpdatedEntityID()
    local x, y = EntityGetTransform(altar_id)
    EntityLoad("data/entities/particles/poof_blue.xml", x, y)
    Collide(altar_id, colliding_entity_id)
end