dofile_once("mods/wand_workshop/files/scripts/altar.lua")
dofile_once("mods/wand_workshop/files/scripts/debug.lua")
Log("altar collision loaded")

-- don't change the name of this or it breaks, big brain nolla hard coding.
function collision_trigger(colliding_entity_id)
    local altar_id = GetUpdatedEntityID()
    local is_target_altar = EntityHasTag(altar_id, "target_altar")
    --Log("collision firing on " .. colliding_entity_id)
    Collide(altar_id, colliding_entity_id, is_target_altar)
end