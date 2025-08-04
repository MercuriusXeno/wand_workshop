dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/wand_workshop/files/scripts/component_utils.lua")
dofile_once("mods/wand_workshop/files/scripts/debug.lua")

Log("altar script loaded")
-- important constants used for consistency/cleanup
local align_offset_x = 0
local hover_offset_y = -5
local target_stat_buffer = "target_statbuffer"
local offer_altar_tag = "offer_altar"
local target_altar_tag = "target_altar"
local target_pickup_script = "mods/wand_workshop/files/scripts/target_pickup_script.lua"
local offer_pickup_script = "mods/wand_workshop/files/scripts/offer_pickup_script.lua"

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
    if is_wand then Setup_Floating_Wands(item_id) end
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
    local result_x = (is_target_altar and altar_x or item_x) + align_offset_x
    local result_y = altar_y + hover_offset_y
    return result_x, result_y
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
---@param entity_id any
---@param tag any
---@return number
function Get_Closest_Altar(entity_id, tag)
    local x, y = EntityGetTransform(entity_id)
    return EntityGetClosestWithTag(x, y, tag)
end

---Get the target altar closest to a given entity
---@param entity_id any
---@return number
function Get_Target_Altar(entity_id)
    return Get_Closest_Altar(entity_id, target_altar_tag)
end

---Get the offering altar closest to a given entity
---@param entity_id any
---@return number
function Get_Offer_Altar(entity_id)
    return Get_Closest_Altar(entity_id, offer_altar_tag)
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
function Collide(altar_id, item_id, is_target_altar)
    -- don't collide with the player's inventory
    if Is_Inventory(item_id) then return end

    -- get the target altar of this altar room if it isn't the target altar
    local target_altar_id = is_target_altar and altar_id or Get_Target_Altar(altar_id)

    -- get the target of the altar room, assuming it exists
    local target_item_id = Get_Target(target_altar_id)

    -- if we are an empty target altar, try targeting this item
    if is_target_altar and target_item_id == nil then
        -- if it's valid
        if Is_Valid_Target(item_id) then
            -- reserve the original item stats, whatever the item is
            Reserve_Original_Target_Item(altar_id, item_id)
            Link_Item(altar_id, item_id)
            -- disable our collision as long as we have our target
            Set_Target_Altar_Collision(altar_id, false)
        end
        -- if we are the offering altar and the target exists
    elseif not is_target_altar and target_item_id ~= nil then
        -- determine the type of target and see if the colliding item is that type
        if Is_Type_Matched(target_item_id, item_id) and not Is_Attached_To_Altar(altar_id, item_id) then
            Link_Item(altar_id, item_id)
        end
    end
end

---Returns true if the given item_id is currently linked to the altar.
---@param altar_id integer
---@param item_id integer
---@return boolean
function Is_Attached_To_Altar(altar_id, item_id)
    local comps = EntityGetComponent(altar_id, "VariableStorageComponent") or {}
    for _, comp in ipairs(comps) do
        if ComponentHasTag(comp, "altar_link") then
            local linked_id = ComponentGetValue2(comp, "value_int")
            if linked_id == item_id then
                return true
            end
        end
    end
    return false
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
    -- link the item to the altar using a variable component
    Couple_Item_To_Altar(item_id, altar_id)

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

---Tethers an item to an altar using a variable storage component
---on the altar to remember that the wand is attached to it.
---@param item_id any
---@param altar_id any
function Couple_Item_To_Altar(item_id, altar_id)
    local is_wand = Is_Wand(item_id)
    local item_type = is_wand and "wand" or "flask"

    EntityAddComponent2(altar_id, "VariableStorageComponent", {
        _tags = "altar_link",
        name = "linked_item",
        value_int = item_id,
        value_string = item_type,
    })
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

---Handle decoupling an altar from any of its held items.
---@param altar_id any
---@param item_id any
function Unlink_Item(altar_id, item_id)
    -- unlink the item from this altar, assuming it is attached to it
    Decouple_Item_From_Altar(altar_id, item_id)

    -- the target altar is special for having its collision disabled when an item is on it
    Set_Target_Altar_Collision(altar_id, true)

    -- stop glowing
    Set_Altar_Glowing(altar_id, false)

    -- refresh the result of the recipe, whatever that entails.
    Update_Result(altar_id)
end

---Detaches an item from its altar "owner" so it is no
---longer considered in the pool for calculations/recipes
---@param altar_id any
---@param item_id any
function Decouple_Item_From_Altar(altar_id, item_id)
    local comps = EntityGetComponent(altar_id, "VariableStorageComponent") or {}
    for _, comp in ipairs(comps) do
        if ComponentHasTag(comp, "altar_link") and ComponentGetValue2(comp, "value_int") == item_id then
            EntityRemoveComponent(altar_id, comp)
        end
    end
end

---Called when the player picks up the target result from the altar.
---@param altar_id any
---@param item_id any
function Take_Result(altar_id, item_id)
    local offer_altar_id = Get_Offer_Altar(altar_id)

    -- if there are any linked offerings, destroy them
    Destroy_Recipe_Linked_Items(offer_altar_id)

    -- clean up the reference to the item so it isn't still considered linked.
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

---Gets any wands attached to the altar of the altar in question.
---@param altar_id any
---@return number[]
function Get_Wands(altar_id)
    local altar_items = Get_Altar_Items(altar_id)
    local result = {}
    if altar_items ~= nil then
        for i, item in ipairs(altar_items) do
            if EntityHasTag(item, "wand") then result[#result + 1] = item end
        end
    end
    return result
end

---Gets any flasks attached to the altar in question.
---@param altar_id any
---@return number[]
function Get_Flasks(altar_id)
    local altar_items = Get_Altar_Items(altar_id)
    local result = {}
    if altar_items ~= nil then
        for i, item in ipairs(altar_items) do
            if EntityHasTag(item, "potion") then result[#result + 1] = item end
        end
    end
    return result
end

---Returns the item ids that are attached to the altar by VSC.
---@param altar_id any
---@return table
function Get_Altar_Items(altar_id)
    local comps = EntityGetComponent(altar_id, "VariableStorageComponent") or {}
    local result = {}

    for _, comp in ipairs(comps) do
        if ComponentHasTag(comp, "altar_link") then
            local id = ComponentGetValue2(comp, "value_int")
            if EntityGetIsAlive(id) then
                result[#result + 1] = id
            end
        end
    end

    return result
end

---Recalculates the result of the inputs on the offering altar
---based on the target altar item, if one exists.
---@param altar_id any
function Update_Result(altar_id)
    -- find the offering altar
    local target_altar_id = Get_Target_Altar(altar_id)
    local target_item_id = Get_Target(target_altar_id)

    if target_item_id == nil then return end

    -- determine if the recipe is a wand or flask
    local offer_altar_id = Get_Offer_Altar(altar_id)
    if Is_Wand(target_item_id) then
        Calculate_Wand_Stats(target_item_id, target_altar_id, offer_altar_id)
    else
        Calculate_Flask_Stats(target_item_id, target_altar_id, offer_altar_id)
    end
end

---Called when linking a target item. Reserves the stats of a wand or flask
---so its original can be restored to the state it was prior to improvements.
---@param altar_id any
---@param item_id any
function Reserve_Original_Target_Item(altar_id, item_id)
    if Is_Wand(item_id) then
        Reserve_Wand_Stats(altar_id, item_id)
    elseif Is_Flask(item_id) then
        Reserve_Flask_State(altar_id, item_id)
    end
end

---Wipe out the old reserve stats of the variable storage component of the altar.
---This is called when reserving wand OR flask stats or when taking the result.
---@param altar_id any
function Clear_Old_Reserve_Stats(altar_id)
    local old_comps = EntityGetComponent(altar_id, "VariableStorageComponent") or {}
    for _, comp in ipairs(old_comps) do
        if ComponentHasTag(comp, target_stat_buffer) then
            EntityRemoveComponent(altar_id, comp)
        end
    end
end

--== WAND MERGING ==--


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

---Sets up wands for hovering with effects such as particles emitting,
---and the pickup animations for the target wand, in particular.
---@param item_id any
function Setup_Floating_Wands(item_id)
    Make_Wand_Glowy(item_id)
    Make_Wand_Pickup_Fancy(item_id)
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
                    value_int = math.floor(final + 0.5), -- round
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
    local unpack = unpack or table.unpack -- 5.1 v 5.2ism
    local pool = { unpack(values) }

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

    return pool[1] -- final result
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

--== FLASK MERGING ==--

local flask_enchantments = {
    tempered = { material = "ambrosia", max = 1, apply = Apply_Tempered },
    -- you can only have one "inert", but if you have reactive, you have to cancel them one level at a time
    inert = { material = "oil", max = 1, apply = Apply_Inert, negates = "reactive" },
    reactive = { material = "toxic_sludge", max = 4, apply = Apply_Reactive, negates = "inert" },
    remote = { material = "teleportatium", max = 1, apply = Apply_Remote }
}

local flask_enchant_prefix = "wand_workshop_flask_enchant_"

---Returns a table of { name, amount } materials inside the flask
---@param flask_id integer
---@return table[]
function Get_Flask_Materials(flask_id)
    local result = {}
    local comp = EntityGetFirstComponentIncludingDisabled(flask_id, "MaterialInventoryComponent")
    if not comp then return result end

    local count = ComponentGetValue2(comp, "count_per_material_type")
    local mats = ComponentGetValue2(comp, "material_slots")

    for i = 1, #mats do
        local mat_id = mats[i]
        if mat_id ~= 0 then
            local name = CellFactory_GetName(mat_id)
            local amount = count[i]
            if amount and amount > 0 then
                result[#result + 1] = {
                    name = name,
                    amount = amount
                }
            end
        end
    end

    return result
end

---Returns the amount of a given material in the flask
---@param flask_id integer
---@param material_name string
---@return integer
function Get_Material_Amount(flask_id, material_name)
    local materials = Get_Flask_Materials(flask_id)
    for _, entry in ipairs(materials) do
        if entry.name == material_name then
            return entry.amount
        end
    end
    return 0
end

---Check whether a flask has a specific enchantment.
---@param flask_id integer
---@param enchantment_key string
---@return number
function Get_Level_Of_Flask_Enchantment(flask_id, enchantment_key)
    local key = flask_enchant_prefix .. enchantment_key
    local comps = EntityGetComponentIncludingDisabled(flask_id, "VariableStorageComponent") or {}

    for _, comp in ipairs(comps) do
        if ComponentGetValue2(comp, "name") == key then
            return ComponentGetValue2(comp, "value_int")
        end
    end

    return 0
end

--- Reserve the current flask state (materials, enchantments) on the altar
---@param altar_id integer
---@param flask_id integer
function Reserve_Flask_State(altar_id, flask_id)
    -- clear old reservation
    Clear_Old_Reserve_Stats(altar_id)

    -- reserve material contents
    local materials = Get_Flask_Materials(flask_id)
    for i, mat in ipairs(materials) do
        EntityAddComponent2(altar_id, "VariableStorageComponent", {
            name = "reserved_material_" .. i,
            value_string = mat,
            _tags = target_stat_buffer
        })
    end

    -- reserve enchantments (and their levels)
    for key, _ in pairs(flask_enchantments) do
        local level = Get_Level_Of_Flask_Enchantment(flask_id, key)
        if level > 0 then
            EntityAddComponent2(altar_id, "VariableStorageComponent", {
                name = "reserved_enchant_" .. key,
                value_int = level,
                _tags = target_stat_buffer
            })
        end
    end
end

--- Retrieve reserved flask state from the target altar
---@param altar_id integer
---@return table state { materials: string[], enchantments: table<string, integer> }
function Get_Reserved_Flask_State(altar_id)
    local comps = EntityGetComponentIncludingDisabled(altar_id, "VariableStorageComponent") or {}
    local materials = {}
    local enchantments = {}

    for _, comp in ipairs(comps) do
        if ComponentHasTag(comp, target_stat_buffer) then
            local name = ComponentGetValue2(comp, "name")

            if string.sub(name, 1, 18) == "reserved_material_" then
                local material = ComponentGetValue2(comp, "value_string")
                if material ~= "" then
                    materials[#materials + 1] = material
                end
            elseif string.sub(name, 1, 17) == "reserved_enchant_" then
                local enchant = string.sub(name, 18)
                local level = ComponentGetValue2(comp, "value_int")
                enchantments[enchant] = level
            end
        end
    end

    return { materials = materials, enchantments = enchantments }
end

---Combine reserved flask state with enchantment effects and merged flask contents.
---@param reserved table
---@param effects table<string, boolean>
---@param merge_flasks integer[]
---@return table
function Combine_Flask_State(reserved, effects, merge_flasks)
  local result = {
    enchantments = {},
    materials = {},
    capacity = reserved.capacity or 0
  }

  -- Clone reserved materials
  local material_map = {}
  for _, mat in ipairs(reserved.materials or {}) do
    material_map[mat.name] = (material_map[mat.name] or 0) + mat.amount
  end

  -- Add enchantments, respecting max level
  for key, _ in pairs(effects) do
    local enchant = flask_enchantments[key]
    if enchant then
      local current = reserved.enchantments and reserved.enchantments[key] or 0
      local level = math.min(current + 1, enchant.max or 1)
      result.enchantments[key] = level
    end
  end

  -- Negation pass: cancel out conflicting enchantments
  for key, level in pairs(result.enchantments) do
    local def = flask_enchantments[key]
    local inverse = def and def.negates
    if inverse and result.enchantments[inverse] then
      local other = result.enchantments[inverse]
      local delta = level - other

      if delta > 0 then
        result.enchantments[key] = delta
        result.enchantments[inverse] = nil
      elseif delta < 0 then
        result.enchantments[inverse] = -delta
        result.enchantments[key] = nil
      else
        result.enchantments[key] = nil
        result.enchantments[inverse] = nil
      end
    end
  end

  -- Add merged flask contents and capacity
  for _, flask_id in ipairs(merge_flasks) do
    local mat_list = Get_Flask_Materials(flask_id)
    for _, mat in ipairs(mat_list) do
      material_map[mat.name] = (material_map[mat.name] or 0) + mat.amount
    end

    local comp = EntityGetFirstComponentIncludingDisabled(flask_id, "MaterialInventoryComponent")
    if comp then
      result.capacity = result.capacity + ComponentGetValue2(comp, "bar_max_amount")
    end
  end

  -- Collapse material map to array
  for name, amount in pairs(material_map) do
    result.materials[#result.materials + 1] = { name = name, amount = amount }
  end

  return result
end

---Apply the combined flask state to the given flask entity.
---@param flask_id integer
---@param combined table
function Apply_Flask_State(flask_id, combined)
  local comp = EntityGetFirstComponentIncludingDisabled(flask_id, "MaterialInventoryComponent")
  if not comp then
    GamePrint("Apply_Flask_State: no material component on flask")
    return
  end

  -- Apply enchantments
  for key, level in pairs(combined.enchantments or {}) do
    local enchant = flask_enchantments[key]
    if enchant and enchant.apply then
      enchant.apply(flask_id, level)
    end
  end

  -- Set new flask capacity
  ComponentSetValue2(comp, "bar_max_amount", combined.capacity)

  -- Clear all material slots
  local mat_slots = ComponentGetValue2(comp, "material_slots") or {}
  for i = 1, #mat_slots do
    mat_slots[i] = 0
  end

  local count_slots = {}
  for i = 1, #mat_slots do count_slots[i] = 0 end

  -- Add materials to available slots
  for _, mat in ipairs(combined.materials or {}) do
    local mat_id = CellFactory_GetType(mat.name)
    local slot_found = false

    for i = 1, #mat_slots do
      if mat_slots[i] == 0 then
        mat_slots[i] = mat_id
        count_slots[i] = mat.amount
        slot_found = true
        break
      elseif mat_slots[i] == mat_id then
        count_slots[i] = count_slots[i] + mat.amount
        slot_found = true
        break
      end
    end

    if not slot_found then
      GamePrint("Apply_Flask_State: ran out of slots for material " .. tostring(mat.name))
    end
  end

  -- Set back into component
  ComponentSetValue2(comp, "material_slots", mat_slots)
  ComponentSetValue2(comp, "count_per_material_type", count_slots)
end

--- Make flask unbreakable by removing its DamageModelComponent(s)
function Apply_Tempered(flask_id, level)
  local comps = EntityGetComponentIncludingDisabled(flask_id, "DamageModelComponent") or {}
  for _, comp in ipairs(comps) do
    EntityRemoveComponent(flask_id, comp)
  end
end

--- Reduce reaction rate by 20 × level (defaults to 20 if not present)
function Apply_Inert(flask_id, level)
  local comps = EntityGetComponentIncludingDisabled(flask_id, "MaterialInventoryComponent") or {}
  for _, comp in ipairs(comps) do
    local default = 20
    local rate = default - (20 * level)
    ComponentSetValue2(comp, "reaction_rate", math.max(0, rate))
  end
end

--- Increase reaction rate from 20 to 100 in 5 steps (Reactive I-V)
function Apply_Reactive(flask_id, level)
  local comps = EntityGetComponentIncludingDisabled(flask_id, "MaterialInventoryComponent") or {}
  for _, comp in ipairs(comps) do
    local rate = 20 + (level * 20)
    ComponentSetValue2(comp, "reaction_rate", math.min(rate, 100))
  end
end

--- Mark the flask as "Remote" using a VariableStorageComponent
---@param flask_id integer
---@param level integer
function Apply_Remote(flask_id, level)
  local key = flask_enchant_prefix .. "remote"

  -- Remove any existing component with this key
  local comps = EntityGetComponentIncludingDisabled(flask_id, "VariableStorageComponent") or {}
  for _, comp in ipairs(comps) do
    if ComponentGetValue2(comp, "name") == key then
      EntityRemoveComponent(flask_id, comp)
    end
  end

  -- Add new component with level set
  EntityAddComponent2(flask_id, "VariableStorageComponent", {
    name = key,
    value_int = level,
    value_string = "Remote Flask",
    _tags = "flask_enchantment"
  })
end

---@param target_flask_id integer
---@param target_altar_id integer
---@param offer_altar_id integer
function Calculate_Flask_Stats(target_flask_id, target_altar_id, offer_altar_id)
  local reserved = Get_Reserved_Flask_State(target_altar_id)
  local offer_flasks = Get_Flasks(offer_altar_id)

  local effects, merge_flasks = Scrape_Enchantments_From_Offerings(offer_flasks)

  local combined = Combine_Flask_State(reserved, effects, merge_flasks)
  Apply_Flask_State(target_flask_id, combined)
end

---@param flask_ids integer[]
---@return table<string, boolean> effects  -- map of enchantments to apply
---@return integer[] merge_flasks          -- flasks to merge
function Scrape_Enchantments_From_Offerings(flask_ids)
  local effects = {}
  local merge_flasks = {}

  for _, flask_id in ipairs(flask_ids) do
    local is_enchant = false

    for key, enchant in pairs(flask_enchantments) do
      local amount = Get_Material_Amount(flask_id, enchant.material)

      if amount >= 1000 then
        effects[key] = true
        is_enchant = true
        break -- only one enchantment per flask
      end
    end

    if not is_enchant then
      merge_flasks[#merge_flasks + 1] = flask_id
    end
  end

  return effects, merge_flasks
end