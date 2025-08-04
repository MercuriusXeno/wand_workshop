dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/wand_workshop/files/scripts/component_utils.lua")
dofile_once("mods/wand_workshop/files/scripts/debug.lua")
Log("altar script loaded")
-- important constants used for consistency/cleanup
local altar_offset_x = 0
local altar_offset_y = -5
local workshop_altar_tag = "workshop_altar"
local offer_altar_tag = "offer_altar"
local target_altar_tag = "target_altar"
local target_stat_buffer = "target_statbuffer"
local target_pickup_script = "mods/wand_workshop/files/scripts/target_pickup_script.lua"
local offer_pickup_script = "mods/wand_workshop/files/scripts/offer_pickup_script.lua"
local wand_stats = {
    {
        property = "fire_rate_wait",
        object = "gunaction_config",
        var_field = "value_int",
        formula = "min"
    },
    {
        property = "reload_time",
        object = "gun_config",
        var_field = "value_int",
        formula = "min"
    },
    {
        property = "mana_max",
        object = nil,
        var_field = "value_int",
        formula = "loop"
    },
    {
        property = "mana_charge_speed",
        object = nil,
        var_field = "value_int",
        formula = "loop"
    },
    {
        property = "spread_degrees",
        object = "gunaction_config",
        var_field = "value_int",
        formula = "min"
    },
    {
        property = "deck_capacity",
        object = "gun_config",
        var_field = "value_int",
        formula = "max"
    }
}

---Gets the item at the altar provided and makes it hover and glow particles.
---Centers it on the altar if it's the target altar, but offerings float wherever they
---land for a bit of extra style.
---@param altar_id any
---@param item_id any
function Do_Hover(altar_id, item_id)
    local is_target_altar = Is_Target_Altar(altar_id)
    local item_comp = EntityGetFirstComponentIncludingDisabled(item_id, "ItemComponent")
    if item_comp ~= nil then
        ComponentSetValue2(item_comp, "has_been_picked_by_player", false)
        ComponentSetValue2(item_comp, "play_hover_animation", true)
        local x, y = Get_Hover_Transform(item_id, altar_id, is_target_altar)
        ComponentSetValue2(item_comp, "spawn_pos", x, y)
    end

    -- disable the physics on it, not sure if this breaks for non-wands.
    local physics_comp = EntityGetFirstComponentIncludingDisabled(item_id, "SimplePhysicsComponent")
    if physics_comp ~= nil then EntitySetComponentIsEnabled(item_id, physics_comp, false) end

    -- if the item is a wand we do a couple more things to it for effect.
    local is_wand = EntityHasTag(item_id, "wand")
    if is_wand then Setup_Floating_Wands(item_id, is_target_altar) end
end

---Sets up wands for hovering with effects such as particles emitting,
---and the pickup animations for the target wand, in particular.
---@param item_id any
function Setup_Floating_Wands(item_id, is_target_altar)
    Make_Wand_Glowy(item_id)
    if is_target_altar then Make_Wand_Pickup_Fancy(item_id) end
end

---Makes the wand have some particles like shop wands and wands you're seeing for the first time.
---@param item_id any
function Make_Wand_Glowy(item_id)
    local particle_comp = EntityGetFirstComponentWithVariable(item_id, "SpriteParticleEmitterComponent",
        "velocity_always_away_from_center", nil)
    if particle_comp ~= nil then EntitySetComponentIsEnabled(item_id, particle_comp, true) end
end

---Gives the wand its snazzy pickup script for picking up new wands.
---@param item_id any
function Make_Wand_Pickup_Fancy(item_id)
    local luaComponent = EntityGetFirstComponentWithVariable(item_id, "LuaComponent", "script_item_picked_up",
        "data/scripts/particles/wand_pickup.lua")
    if luaComponent ~= nil then EntitySetComponentIsEnabled(item_id, luaComponent, true) end
end

---Return the x, y values of the place the item should hover. The centering
---depends on whether it is the target altar, which centers the item. Otherwise the item
---will hover wherever it touched the altar, so it will retain its x position.
---@param item_id any
---@param altar_id any
---@param is_target_altar any
---@return number x
---@return number y
function Get_Hover_Transform(item_id, altar_id, is_target_altar)
    local altar_x, altar_y = EntityGetTransform(altar_id)
    -- note the y is discarded here irrespective of anything. y is always the altar's.
    local item_x, item_y = EntityGetTransform(item_id)
    -- the target altar centers the hovered item, the offerings do not center
    local result_x = (is_target_altar and altar_x or item_x) + altar_offset_x
    local result_y = altar_y + altar_offset_y
    return result_x, result_y
end

---Returns the altar parent of a given item. This is the same regardless of what altar,
---but note there is a check to ensure we're not somehow calling this from a non-altar.
---This is probably unnecessary but there out of ignorant paranoia.
---@param item_id any
---@return number
function Get_Parent_Altar(item_id)
    local result = EntityGetParent(item_id)
    if not EntityHasTag(result, workshop_altar_tag) then
        result = 0
    end
    return result
end

---Detect if the inventory of a provided entity (presumed to be an item)
---is the quick inventory of the player. These are, weirdly, collidable. We don't want that.
---@param entity_id any
---@return boolean
function Is_Inventory(entity_id)
    local parent_id = EntityGetParent(entity_id)
    return parent_id ~= 0 and EntityGetName(parent_id) == "inventory_quick";
end

---Get the closest altar with the provided tag to another altar
---@param altar_id any
---@param tag any
---@return number
function Get_Closest_Altar(altar_id, tag)
    local x, y = EntityGetTransform(altar_id)
    return EntityGetClosestWithTag(x, y, tag)
end

---Get the target altar closest to a given altar
---@param altar_id any
---@return number
function Get_Target_Altar(altar_id)
    return Get_Closest_Altar(altar_id, target_altar_tag)
end

---Get the offering altar closest to a given altar
---@param altar_id any
---@return number
function Get_Offer_Altar(altar_id)
    return Get_Closest_Altar(altar_id, offer_altar_tag)
end

---Return the target item of the target altar
---@param target_altar_id any
function Get_Target(target_altar_id)
    local result = nil

    -- start with wands, if any is bound, the first result is what we return
    local wand_targets = Get_Wands(target_altar_id)
    if #wand_targets > 0 then result = wand_targets[1] end

    -- if result is still nil, look for the first flask
    if result == nil then
        local flask_targets = Get_Flasks(target_altar_id)
        if #flask_targets > 0 then result = flask_targets[1] end
    end

    -- we can't look for anything else, return whatever we found, or nil
    return result
end

---Returns true if the item passed in is a flask or wand
---@param item_id any
---@return boolean
function Is_Valid_Target(item_id)
    return Is_Wand(item_id) or Is_Flask(item_id)
end

---Returns true if the altar id provided has the target altar tag.
---@param altar_id any
---@return boolean
function Is_Target_Altar(altar_id)
    return EntityHasTag(altar_id, target_altar_tag)
end

---Returns true if the item ids passed in are both wands, or both flasks, otherwise false.
---@param target_item_id any
---@param offer_item_id any
---@return boolean
function Is_Type_Matched(target_item_id, offer_item_id)
    return (Is_Wand(target_item_id) and Is_Wand(offer_item_id)) or (Is_Flask(target_item_id) and Is_Flask(offer_item_id))
end

---Common logic shared by either altar for doing collisions with items.
---Attaches a pickup script to the item which will unlink it from the altar.
---Makes it hover as needed.
---@param altar_id any
---@param item_id any
function Collide(altar_id, item_id)
    -- don't collide with the player's inventory
    if Is_Inventory(item_id) then return end

    -- get the target altar of this altar room
    local target_altar_id = Get_Target_Altar(altar_id)

    -- get the target of the altar room, assuming it exists
    local target_item_id = Get_Target(target_altar_id)

    -- determine if the altar_id is for the target altar
    local is_target_altar = target_altar_id == altar_id

    -- if we are an empty target altar, try targeting this item
    if is_target_altar and target_item_id == nil then
        -- if it's valid
        if Is_Valid_Target(item_id) then
            -- reserve the original item stats, whatever the item is
            Reserve_Original_Target_Item(altar_id, item_id)
            -- link the item to the altar (it's a child)
            Link_Item(altar_id, item_id)
            -- disable our collision as long as we have our target
            Set_Target_Altar_Collision(altar_id, false)
        end
        -- if we are the offering altar and the target exists
    elseif not is_target_altar and target_item_id ~= nil then
        -- determine the type of target and see if the colliding item is that type
        if Is_Type_Matched(target_item_id, item_id) then
            -- link the item to the altar (it's a child)
            Link_Item(altar_id, item_id)
        end
    end
end

---Turn the glowy altar particles on
---@param altar_id any
---@param is_glowing any
function Set_Altar_Glowing(altar_id, is_glowing)
    EntitySetComponentsWithTagEnabled(altar_id, "item_effect", is_glowing)
end

---Links the item to the provided altar.
---@param altar_id any
---@param item_id any
function Link_Item(altar_id, item_id)
    -- make the item a child of the altar
    EntityAddChild(altar_id, item_id)

    -- make the item hover
    Do_Hover(altar_id, item_id)

    -- show the altar runes glowing to make it clear it is holding items by the altar
    Set_Altar_Glowing(altar_id, true)

    -- attach a pickup script to the item to unlink it from the altar
    -- and potentially destroy the recipe inputs, if it was the target
    Attach_Pickup_Script(altar_id, item_id)

    -- refresh the result of the recipe, whatever that entails.
    Update_Result(altar_id)
end

---Bind the pickup script to an item. This is the script responsible for unlinking
---an item from the altar and destroying any valid inputs attached to the offering altar
---whenever the target item is reclaimed from the target altar, finalizing the recipe.
---@param altar_id any
---@param item_id any
function Attach_Pickup_Script(altar_id, item_id)
    local is_target_altar = Is_Target_Altar(altar_id)
    local script = is_target_altar and target_pickup_script or offer_pickup_script
    local component_id = EntityAddComponent(item_id, "LuaComponent", {
        execute_every_n_frame = -1,
        script_item_picked_up = script,
        remove_after_executed = 1
    })
    EntitySetComponentIsEnabled(item_id, component_id, true)
end

---Handle decoupling an altar from any of its held items. The altar is the parent in either offering or target.
---@param altar_id any
---@param item_id any
function Unlink_Item(altar_id, item_id)
    -- unlink the item from this altar, assuming it is attached to it
    if EntityGetParent(item_id) == altar_id then EntityRemoveFromParent(item_id) end

    -- the target altar is special for having its collision disabled when an item is on it
    Set_Target_Altar_Collision(altar_id, true)

    -- stop glowing
    Set_Altar_Glowing(altar_id, false)

    -- refresh the result of the recipe, whatever that entails.
    Update_Result(altar_id)
end

---Called when the player picks up the target result from the altar.
---@param altar_id any
---@param item_id any
function Take_Result(altar_id, item_id)
    local offer_altar_id = Get_Offer_Altar(altar_id)

    -- if there are any linked offerings, destroy them
    Destroy_Recipe_Linked_Items(offer_altar_id)

    -- unlink the item at the end so the altar isn't glowing and they're not related anymore
    Unlink_Item(altar_id, item_id)
end

---Returns true if the item entity has an item component which matches
---the name input provided. This is the localization name eg. $item_brimstone
---@param entity_id any
---@param which_item any
---@return boolean|nil
function Is_Specific_Item(entity_id, which_item)
    local item_comp = EntityGetFirstComponent(entity_id, "ItemComponent")
    return item_comp and ComponentGetValue2(item_comp, "item_name") == which_item
end

---Return true if the provided entity_id has the wand tag.
---@param entity_id any
---@return boolean
function Is_Wand(entity_id)
    return EntityHasTag(entity_id, "wand")
end

---Returns true if the provided entity_id matches any sort of flask context.
---Any potion-type entity can be valid for this input.
---@param entity_id any
function Is_Flask(entity_id)
    return EntityHasTag(entity_id, "potion")
end

---Destroy any items that are the same type as the target item.
---@param altar_id any
function Destroy_Recipe_Linked_Items(altar_id)
    local target_altar_id = Get_Target_Altar(altar_id)
    local target_id = Get_Target(target_altar_id)
    local offering_altar_id = Get_Offer_Altar(altar_id)
    local destroy_list = {}
    if Is_Wand(target_id) then
        destroy_list = Get_Wands(offering_altar_id)
    elseif Is_Flask(target_id) then
        destroy_list = Get_Flasks(offering_altar_id)
    end

    for _, item_id in ipairs(destroy_list) do
        local x, y = EntityGetTransform(item_id)

        -- Optional: visual effect
        EntityLoad("data/entities/particles/destruction.xml", x, y)
        GamePlaySound("data/audio/Desktop/projectiles.bank", "magic/common_destroy", x, y)

        -- Kill the item
        EntityKill(item_id)
    end
end

---Enables the collision component of the altar if its tag is target_grab
---This is virtually the same as checking to see if the altar is the target altar
---before disabling the collision, so it could be replaced with something like that.
---@param altar_id any
---@param is_collision_enabled any
function Set_Target_Altar_Collision(altar_id, is_collision_enabled)
    EntitySetComponentsWithTagEnabled(altar_id, "target_grab", is_collision_enabled)
end

---Get the wand ability component of the provided wand id
---@param wand_id any
---@return number|nil
function Get_Wand_Ability_Component(wand_id)
    return EntityGetFirstComponentIncludingDisabled(wand_id, "AbilityComponent")
end

---Cleans the decimal places of a number to the nearest 100th (2 points of precision)
---@param d any
---@return any
function Clean_Precision(d)
    if d ~= math.floor(d * 100 + 0.5) / 100 then -- make it not an ugly number...
        d = math.floor(d * 100 + 0.5) / 100
    end
    return d
end

---Gets any wand-children of the altar in question.
---@param altar_id any
---@return number[]
function Get_Wands(altar_id)
    local children = EntityGetAllChildren(altar_id)
    local result = {}
    if children ~= nil then
        for i, child in ipairs(children) do
            if EntityHasTag(child, "wand") then result[#result + 1] = child end
        end
    end
    return result
end

---Gets any flask-children of the altar in question.
---@param altar_id any
---@return number[]
function Get_Flasks(altar_id)
    local children = EntityGetAllChildren(altar_id)
    local result = {}
    if children ~= nil then
        for i, child in ipairs(children) do
            if EntityHasTag(child, "potion") then result[#result + 1] = child end
        end
    end
    return result
end

---Recalculates the result of the inputs on the offering altar
---based on the target altar item, if one exists.
---@param altar_id any
function Update_Result(altar_id)
    -- find the offering altar
    local offer_altar_id = Get_Offer_Altar(altar_id)
    local target_altar_id = Get_Target_Altar(altar_id)
    local target_item_id = Get_Target(target_altar_id)

    -- determine if the recipe is a wand or flask
    if Is_Wand(target_item_id) then
        Calculate_Wand_Stats(target_item_id, target_altar_id, offer_altar_id)
    else
        Calculate_Flask_Stats(target_item_id, target_altar_id, offer_altar_id)
    end
end

---Calculate the stat buffer of the sacrifical 
---wands and apply it to the target wand.
---@param target_wand_id any
---@param target_altar_id any
---@param offer_altar_id any
function Calculate_Wand_Stats(target_wand_id, target_altar_id, offer_altar_id)
    local target_stats = Get_Reserved_Wand_Stats(target_altar_id)
    local offering_stats_list = Get_Offering_Wand_Stats(offer_altar_id)
    local combined_stats = Combine_Wand_Stats(target_stats, offering_stats_list)
    Apply_Wand_Stats(target_wand_id, combined_stats)
end

---Combine the stats from target + offerings into a new stat table
---@param target_stats table
---@param offering_stats_list table[]
---@return table
function Combine_Wand_Stats(target_stats, offering_stats_list)
    local combined_stats = {}
    local all_stats_by_name = {}

    -- Step 1: flatten all stats into stat_name → list of values
    for _, stat in ipairs(target_stats) do
        all_stats_by_name[stat.name] = { stat.value_int }
    end

    for _, stats in ipairs(offering_stats_list) do
        for _, stat in ipairs(stats) do
            local list = all_stats_by_name[stat.name]
            if list then
                list[#list + 1] = stat.value_int
            end
        end
    end

    -- Step 2: apply combination logic based on stat kind
    for _, def in ipairs(wand_stats) do
        local name = def.property
        local values = all_stats_by_name[name] or {}

        local final = nil
        if #values > 0 then
            if def.formula == "min" then
                final = math.huge
                for _, v in ipairs(values) do
                    final = math.min(final, v)
                end
            elseif def.formula == "max" then
                final = -math.huge
                for _, v in ipairs(values) do
                    final = math.max(final, v)
                end
            elseif def.formula == "loop" then
                final = Blend_Stat_Loop(values)
            end

            if final then
                combined_stats[#combined_stats + 1] = {
                    name = name,
                    value_int = math.floor(final + 0.5),  -- round
                    _tags = target_stat_buffer
                }
            end
        end
    end

    return combined_stats
end

---Blends mana/regen using recursive loop algorithm
---@param values number[]
---@return number
function Blend_Stat_Loop(values)
    local pool = { table.unpack(values) }

    -- Sort ascending (worst to best)
    table.sort(pool)

    while #pool > 1 do
        local worst = table.remove(pool, 1)
        local next_worst = table.remove(pool, 1)
        local result = next_worst + ((worst / next_worst) ^ 0.5) * worst

        -- insert result back into sorted position
        local inserted = false
        for i = 1, #pool do
            if result < pool[i] then
                table.insert(pool, i, result)
                inserted = true
                break
            end
        end
        if not inserted then
            pool[#pool + 1] = result
        end
    end

    return pool[1]  -- final result
end

---Apply a stat table back to a wand's AbilityComponent
---@param wand_id integer
---@param stats_table table[] list of { name, value_int }
function Apply_Wand_Stats(wand_id, stats_table)
    local ability_comp = Get_Wand_Ability_Component(wand_id)
    if not ability_comp then
        print("Apply_Wand_Stats: missing AbilityComponent")
        return
    end

    for _, entry in ipairs(stats_table) do
        local name = entry.name
        local value = entry.value_int

        -- Match stat against wand_stats definition
        for _, def in ipairs(wand_stats) do
            if def.property == name then
                if def.object then
                    ComponentObjectSetValue2(ability_comp, def.object, name, value)
                else
                    ComponentSetValue2(ability_comp, name, value)
                end
                break
            end
        end
    end
end

---Called when updating the results of altar offerings that are for flask merging.
---Determines any potential recipes to improve the target flask. Attempts to find
---material recipes eagerly, prior to falling back to more basic capacity merging.
---@param target_item_id any
---@param target_altar_id any
---@param offer_altar_id any
function Calculate_Flask_Stats(target_item_id, target_altar_id, offer_altar_id)
    --STUB
end

---Called when linking a target item. Reserves the stats of a wand or flask
---so its original can be restored to the state it was prior to improvements.
---@param altar_id any
---@param item_id any
function Reserve_Original_Target_Item(altar_id, item_id)
    if Is_Wand(item_id) then
        Reserve_Wand_Stats(altar_id, item_id)
    elseif Is_Flask(item_id) then
        Reserve_Flask_Stats(item_id)
    end
end

---Wipe out the old reserve stats of the variable storage component of the altar.
---This is called when reserving wand stats or when taking the result.
---@param altar_id any
function Clear_Old_Reserve_Stats(altar_id)
    local old_comps = EntityGetComponent(altar_id, "VariableStorageComponent") or {}
    for _, comp in ipairs(old_comps) do
        if ComponentHasTag(comp, target_stat_buffer) then
            EntityRemoveComponent(altar_id, comp)
        end
    end
end

---Reserves the wand stats of a target wand. Used when the player first puts it on the target altar.
---@param altar_id integer
---@param wand_id integer
function Reserve_Wand_Stats(altar_id, wand_id)
    Clear_Old_Reserve_Stats(altar_id)

    local stats = Get_Wand_Stats(wand_id)
    if not stats then return end

    for _, stat in ipairs(stats) do
        EntityAddComponent2(altar_id, "VariableStorageComponent", stat)
    end
end

---Retrieve the reserved stats previously stored on the altar
---@param altar_id integer
---@return table
function Get_Reserved_Wand_Stats(altar_id)
    local result = {}
    local comps = EntityGetComponent(altar_id, "VariableStorageComponent") or {}
    for _, comp in ipairs(comps) do
        if ComponentHasTag(comp, target_stat_buffer) then
            result[#result + 1] = {
                name = ComponentGetValue2(comp, "name"),
                value_int = ComponentGetValue2(comp, "value_int"),
                _tags = target_stat_buffer
            }
        end
    end
    return result
end

---Extracts wand stats into a flat table of { name, value_int, _tags } entries.
---@param wand_id integer
---@return table|nil
function Get_Wand_Stats(wand_id)
    local ability_comp = Get_Wand_Ability_Component(wand_id)
    if not ability_comp then return nil end

    local result = {}

    for _, stat in ipairs(wand_stats) do
        local value = Extract_Wand_Stat_Value(ability_comp, stat)

        if value ~= nil then
            result[#result + 1] = {
                name = stat.property,
                value_int = value,
                _tags = target_stat_buffer
            }
        end
    end

    return result
end

---Collect all wand stat tables from the offering altar's wands
---@param offer_altar_id integer
---@return table[] list_of_stat_tables
function Get_Offering_Wand_Stats(offer_altar_id)
    local wand_ids = Get_Wands(offer_altar_id)
    local stat_sets = {}

    for _, wand_id in ipairs(wand_ids) do
        local stats = Get_Wand_Stats(wand_id)
        if stats then
            stat_sets[#stat_sets + 1] = stats
        end
    end

    return stat_sets
end

---Extract a wand stat from the ability component using the stat definitions table.
---@param ability_comp any
---@param stat_def any
---@return any
function Extract_Wand_Stat_Value(ability_comp, stat_def)
    if stat_def.object then
        return ComponentObjectGetValue2(ability_comp, stat_def.object, stat_def.property)
    else
        return ComponentGetValue2(ability_comp, stat_def.property)
    end
end

function Reserve_Flask_Stats(item_id)
    -- STUB
end
