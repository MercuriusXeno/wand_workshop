---@diagnostic disable: lowercase-global, missing-global-doc
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/wand_workshop/files/scripts/altar.lua")
dofile_once("mods/wand_workshop/files/scripts/debug.lua")

-- big chunk of setup is mostly to get the  and the entities within it
function Detect_Entities()
    local target_altar_tag = "target_altar"
    local altar_id = GetUpdatedEntityID()
    local is_target_altar = EntityHasTag(altar_id, target_altar_tag)
    local target_altar_width = 25
    local target_altar_radius = (target_altar_width + 1) / 2
    local offer_altar_width = 58
    local offer_altar_radius = (offer_altar_width + 1) / 2
    local radius = is_target_altar and target_altar_radius or offer_altar_radius
    local box_height = 10
    local altar_x, altar_y = EntityGetTransform(altar_id)
    local left_bound = altar_x - radius
    local right_bound = altar_x + radius
    local upper_bound = altar_y - box_height
    local lower_bound = altar_y + 1
    local near_entities = EntityGetInRadius(altar_x, altar_y, radius)

    -- get the target altar of this altar room if it isn't the target altar
    local target_altar_id = is_target_altar and altar_id or Get_Target_Altar(altar_id)

    -- get the target of the altar room, assuming it exists
    local target_id = Get_Target(target_altar_id)

    for _, entity_id in ipairs(near_entities) do
        local is_valid = is_target_altar and Is_Valid_Target(entity_id) or Is_Valid_Offer(target_id, entity_id)
        if is_valid and not Is_Attached_To_Altar(altar_id, entity_id) then
            local entity_x, entity_y = EntityGetTransform(entity_id)
            if entity_x >= left_bound and entity_x <= right_bound and entity_y >= upper_bound and entity_y <= lower_bound then
                Collide(altar_id, entity_id, is_target_altar, target_id)
            end
        end
    end
end

---Common logic shared by either altar for doing collisions with items.
---Attaches a pickup script to the item which will unlink it from the altar.
---Makes it hover as needed.
---@param item_id any
function Collide(altar_id, item_id, is_target_altar, target_id)
    -- if we are an empty target altar, try targeting this item
    if is_target_altar and not target_id then
        -- reserve the original item stats, whatever the item is
        Reserve_Original_Target_Item(altar_id, item_id)

        Link_Item(altar_id, item_id)

        -- disable our collision as long as we have our target
        Set_Target_Altar_Collision(altar_id, false)
        return
    end

    if not target_id then return end
    -- if we are the offering altar and the target exists
    -- determine the type of target and see if the colliding item is that type
    if not is_target_altar and Is_Type_Matched(target_id, item_id) then Link_Item(altar_id, item_id) end
end

Detect_Entities()
