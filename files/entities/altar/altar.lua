-- advanced wand workshop 2.0 wand growth + omni pillar edit
dofile_once("mods/wand_workshop/files/scripts/lib/ComponentUtils.lua") -- Put your Lua here-- advanced wand workshop 2.0 wand growth edit (omni pillar)
dofile_once("mods/wand_workshop/files/scripts/config.lua")
dofile_once("data/scripts/lib/utilities.lua")
function hover_wand(wand_id, altar_id)
    local x, y = EntityGetTransform(altar_id)
    local component_id = EntityGetFirstComponentIncludingDisabled(wand_id, "ItemComponent")
    if component_id ~= nil then
        ComponentSetValue2(component_id, "has_been_picked_by_player", false)
        ComponentSetValue2(component_id, "play_hover_animation", true)
        ComponentSetValue2(component_id, "spawn_pos", x + altar_wand_offset_x, y + altar_wand_offset_y)
    end

    component_id = EntityGetFirstComponentWithVariable(wand_id, "LuaComponent", "script_item_picked_up", "data/scripts/particles/wand_pickup.lua")
    if component_id ~= nil then EntitySetComponentIsEnabled(wand_id, component_id, true) end
    component_id = EntityGetFirstComponentIncludingDisabled(wand_id, "SimplePhysicsComponent")
    if component_id ~= nil then EntitySetComponentIsEnabled(wand_id, component_id, false) end
    component_id = EntityGetFirstComponentWithVariable(wand_id, "SpriteParticleEmitterComponent", "velocity_always_away_from_center", nil)
    if component_id ~= nil then EntitySetComponentIsEnabled(wand_id, component_id, true) end
end

function get_wand_ability_component(wand_id)
    return EntityGetFirstComponentIncludingDisabled(wand_id, "AbilityComponent")
end

local main_altar_tag = "Wand_Altar"
local wand_stat_buffer_tag = "wand_altar_statbuffer"
local altars = {
    {
        tag = "Speed_Altar",
        omni = nil,
        object = "gunaction_config",
        property = "fire_rate_wait",
        var_field = "value_int",
        material = "spark_yellow",
        operator = "reductive"
    },
    {
        tag = "Reload_Altar",
        omni = nil,
        object = "gun_config",
        property = "reload_time",
        var_field = "value_int",
        material = "spark_red",
        operator = "reductive"
    },
    {
        tag = "Mana_Altar",
        omni = nil,
        object = nil,
        property = "mana_max",
        var_field = "value_int",
        material = "spark_blue",
        operator = "additive"
    },
    {
        tag = "Recharge_Altar",
        omni = nil,
        object = nil,
        property = "mana_charge_speed",
        var_field = "value_int",
        material = "spark_teal",
        operator = "additive"
    },
    {
        tag = "Shuffle_Altar",
        omni = nil,
        object = "gun_config",
        property = "shuffle_deck_when_empty",
        var_field = "value_bool",
        material = "spark_green",
        operator = nil
    },
    {
        tag = "Simulcast_Altar",
        omni = nil,
        object = "gun_config",
        property = "actions_per_round",
        var_field = "value_int",
        material = "spark_player",
        operator = nil
    },
    {
        tag = "Spread_Altar",
        omni = nil,
        object = "gunaction_config",
        property = "spread_degrees",
        var_field = "value_int",
        material = "spark_yellow",
        operator = "reductive"
    },
    {
        tag = "Capacity_Altar",
        omni = nil,
        object = "gun_config",
        property = "deck_capacity",
        var_field = "value_int",
        material = "spark_white",
        operator = "additive"
    },
    {
        tag = "Omni_Altar",
        omni = {
            {
                object = "gunaction_config", -- all the altars in one, kinda -- speed
                property = "fire_rate_wait",
                var_field = "value_int",
                operator = "reductive"
            },
            {
                object = "gun_config", -- reload
                property = "reload_time",
                var_field = "value_int",
                operator = "reductive"
            },
            {
                object = nil, -- mana
                property = "mana_max",
                var_field = "value_int",
                operator = "additive"
            },
            {
                object = nil, -- recharge
                property = "mana_charge_speed",
                var_field = "value_int",
                operator = "additive"
            },
            {
                object = "gunaction_config", -- spread
                property = "spread_degrees",
                var_field = "value_int",
                operator = "reductive"
            },
            {
                object = "gun_config", -- capacity
                property = "deck_capacity",
                var_field = "value_int",
                operator = "additive"
            },
        },
        object = nil,
        property = nil,
        var_field = nil,
        material = "spark_teal",
        operator = nil
    }
}

function link_altar_wand(altar_id, wand_id)
    EntityAddChild(wand_id, altar_id)
    EntitySetComponentsWithTagEnabled(altar_id, "wand_pickup", false)
    EntitySetComponentsWithTagEnabled(altar_id, "wand_effect", true)
    if not EntityHasTag(altar_id, main_altar_tag) then
        --print("linking wand " .. wand_id .. " to sacrifice pillar " .. altar_id)
        reset_wands(altar_id)
        merge_wands(altar_id)
    else
        --print("linking target wand " .. wand_id .. " to central pillar " .. altar_id)
        merge_wands(altar_id, wand_id)
    end
end

-- fired when a wand is picked up from the pillar
function unlink_altar_wand(altar_id, wand_id)
    EntityRemoveFromParent(altar_id)
    EntitySetComponentsWithTagEnabled(altar_id, "wand_pickup", true)
    EntitySetComponentsWithTagEnabled(altar_id, "wand_effect", false)
    if not EntityHasTag(altar_id, main_altar_tag) then
        --print("removing wand " .. wand_id .. " from pillar " .. altar_id)
        reset_wands(altar_id)
        merge_wands(altar_id)
    else
        --print("taking target wand " .. wand_id .. " from central pillar " .. altar_id)
        local component_ids = EntityGetComponentIncludingDisabled(wand_id, "VariableStorageComponent", wand_stat_buffer_tag)
        if component_ids ~= nil then
            for j, component_id in pairs(component_ids) do
                EntityRemoveComponent(wand_id, component_id)
            end
        end
        kill_wands(altar_id)
    end
end

function get_wand(altar_id)
    local wand_id = EntityGetParent(altar_id)
    if wand_id ~= 0 and not EntityHasTag(wand_id, "wand") then
        print("Error: Altar has non-wand parent.")
        return 0
    end
    return wand_id
end

function get_altar(wand_id)
    local children = EntityGetAllChildren(wand_id)
    if children ~= nil then
        for i, child in ipairs(children) do
            if EntityHasTag(child, "wand_workshop_altar") then return child end
        end
    end
    return nil
end

function kill_wand(wand_id, altar_id, material)
    local wand_x, wand_y = EntityGetTransform(wand_id)
    if material ~= nil then
        local particle_id = EntityLoad("mods/wand_workshop/files/entities/particles/small_effect.xml", wand_x, wand_y)
        local component_id = EntityGetFirstComponentIncludingDisabled(particle_id, "ParticleEmitterComponent")
        ComponentSetValue2(component_id, "emitted_material_name", material)
    end

    unlink_altar_wand(altar_id, wand_id)
    local children = EntityGetAllChildren(wand_id)
    if children ~= nil then
        for i, child in ipairs(children) do
            if EntityHasTag(child, "card_action") then
                local item_component = EntityGetFirstComponentIncludingDisabled(child, "ItemComponent")
                if item_component ~= nil then
                    if ComponentGetValue2(item_component, "permanently_attached") or ComponentGetValue2(item_component, "is_frozen") then
                        print("Found always cast spell")
                    else --EntityAddComponent(child, "LuaComponent"
                        EntityRemoveFromParent(child)
                        EntitySetComponentsWithTagEnabled(child, "enabled_in_world", true)
                        EntitySetTransform(child, wand_x, wand_y)
                        SetRandomSeed(wand_x + wand_id, wand_y + child)
                        local rangle = Randomf(-math.pi, math.pi)
                        local force = RandomDistributionf(0, 100, 50)
                        ComponentSetValue2(EntityGetFirstComponentIncludingDisabled(child, "VelocityComponent"), "mVelocity", force * math.sin(rangle), force * math.cos(rangle))
                    end
                else
                    print("Spell without ItemComponent found. This should not happen: Erasing")
                end
            end
        end
    end
    --print("destroying wand id " .. wand_id .. " at altar " .. altar_id)
    EntityConvertToMaterial(wand_id, "gold")
    EntityKill(wand_id)
end

function kill_wands(altar_id)
    local pos_x, pos_y = EntityGetTransform(altar_id)
    for i = 1, #altars do
        local altar = altars[i]
        local sub_altar_id = EntityGetClosestWithTag(pos_x, pos_y, altar.tag)
        local wand_id = get_wand(sub_altar_id)
        if wand_id ~= 0 then kill_wand(wand_id, sub_altar_id, altar.material) end
    end
end

-- called when unlinking wands from any pillar
function reset_wands(altar_id)
    if not EntityHasTag(altar_id, main_altar_tag) then
        local pos_x, pos_y = EntityGetTransform(altar_id)
        altar_id = EntityGetClosestWithTag(pos_x, pos_y, main_altar_tag)
    end
    -- always the central (target) wand as a result of the above calibration
    local wand_id = get_wand(altar_id)
    -- abort if there's no wand on the central pillar
    if wand_id == nil then return end
    local ability_component_id = get_wand_ability_component(wand_id)
    if ability_component_id == nil then return end
    for j = 1, #altars do
        local altar = altars[j]
        -- the reason we skip omni here is that the other pillars already
        -- cover every property, so we can skip "resetting" omni, it's redundant.
        if altar.omni == nil then
            local component_id = EntityGetFirstComponentWithVariable(wand_id, "VariableStorageComponent", "name", altar.property, wand_stat_buffer_tag)
            if component_id ~= nil then
                local value = ComponentGetValue2(component_id, altar.var_field)
                print("reset wand " .. altar.property .. " to buffer value " .. value)
                if altar.object == nil then
                    ComponentSetValue2(ability_component_id, altar.property, value)
                else
                    ComponentObjectSetValue2(ability_component_id, altar.object, altar.property, value)
                end

                EntityRemoveComponent(wand_id, component_id)
            end
        end
    end
end

-- called when resetting the wands due to link or unlink
function merge_wands(altar_id, target_wand)
    if not EntityHasTag(altar_id, main_altar_tag) then
        local pos_x, pos_y = EntityGetTransform(altar_id)
        altar_id = EntityGetClosestWithTag(pos_x, pos_y, main_altar_tag)
    end
    if target_wand == nil or target_wand == 0 then
        target_wand = get_wand(altar_id)
        if target_wand == 0 then return end
    end
    local trg_component_id = get_wand_ability_component(target_wand)
    if trg_component_id == nil then
        print("Error, bad wand on Main_Altar")
        return
    end
    local pos_x, pos_y = EntityGetTransform(altar_id)
    for i = 1, #altars do
        local altar = altars[i]
        local sub_altar_id = EntityGetClosestWithTag(pos_x, pos_y, altar.tag)
        local wand_id = get_wand(sub_altar_id)
        if wand_id ~= 0 then
            local src_component_id = get_wand_ability_component(wand_id)
            if src_component_id ~= nil then
                combine_wand_stats(trg_component_id, src_component_id, altar, target_wand)
            else
                print("Error, bad wand on " .. altar.tag .. "; skipping")
            end
        end
    end
end

function combine_wand_stats(trg_component_id, src_component_id, altar, target_wand)
    if altar.omni == nil then
        local var_component_id = ensure_stat_buffer_exists_and_return_component(trg_component_id, target_wand, altar)
        set_component_stats(trg_component_id, src_component_id, var_component_id, altar, false)
    else
        local omnis = altar.omni
        for o = 1, #omnis do            
            local omni = omnis[o]
            local var_component_id = ensure_stat_buffer_exists_and_return_component(trg_component_id, target_wand, omni)
            -- omni doesn't set the stat buffer because that would set it twice, there's no need to do that.            
            set_component_stats(trg_component_id, src_component_id, var_component_id, omni, true)
        end
    end
end

-- importantly this sets the buffer value only once, if it doesn't exist.
-- repeat access to the buffer with this property name will not overwrite it
function ensure_stat_buffer_exists_and_return_component(trg_component_id, target_wand, altar)
    local var_component_id = EntityGetFirstComponentWithVariable(target_wand, "VariableStorageComponent", "name", altar.property, wand_stat_buffer_tag)
    if var_component_id == nil then
        var_component_id = EntityAddComponent(target_wand, "VariableStorageComponent", { name = altar.property, _tags = wand_stat_buffer_tag })
        ComponentSetValue2(var_component_id, altar.var_field, get_altar_property_of_component(trg_component_id, altar))
    end
    return var_component_id
end

function get_altar_property_of_component(component_id, altar)
    local value = nil
    print("getting altar property of component " .. component_id .. " for altar property " .. altar.property)
    if altar.object ~= nil then
        value = ComponentObjectGetValue2(component_id, altar.object, altar.property)
    else
        value = ComponentGetValue2(component_id, altar.property)
    end
    return value
end

function set_component_stats(trg_component_id, src_component_id, var_component_id, altar, isOmni)
    local last = get_altar_property_of_component(trg_component_id, altar)
    local value = get_altar_property_of_component(src_component_id, altar)
    if type(value) == "number" and type(last) == "number" then
        value = adjust_value_for_growth(last, value, isOmni, altar)
    end
    set_altar_property_of_component(trg_component_id, altar, value)
end

function set_altar_property_of_component(trg_component_id, altar, value)
    if altar.object == nil then        
        ComponentSetValue2(trg_component_id, altar.property, value)
    else
        ComponentObjectSetValue2(trg_component_id, altar.object, altar.property, value)
    end
end

function adjust_value_for_growth(last, value, isOmni, altar)
    local baseValue = get_base_value(last, value, isOmni, altar)
    local growth = get_growth_value(last, value, isOmni, altar)
    local improvedValue = baseValue + growth
    if altar.tag == "Capacity_Altar" then
        print("capacity altar base " + baseValue + " with growth " + growth)
        local capacityLimit = ModSettingGet("wand_workshop.capacity_max")
        improvedValue = math.max(baseValue, math.min(baseValue + growth, capacityLimit))
        print("capacity limited to " + capacityLimit + " so improved value clamped to " + improvedValue)
    end
    return improvedValue
end

-- gets the "original" value at the moment of the calculation
function get_base_value(last, value, isOmni, altar)
    local ratio = ModSettingGet("wand_workshop.mix_fraction")
    if type(ratio) == "number" and not isOmni then
        local isAdditive = altar.operator == "additive"
        local isReductive = altar.operator == "reductive"
        local isImproved = (isAdditive and last >= value) or (isReductive and last <= value)
        ratio = clean_precision(ratio)
        if ratio > 1 then -- if ratio is > 100% and the target has better stats than the sacrifice
            if isImproved then
                value = last -- don't replace the value, it's worse than the old one!
            end
            ratio = 1
        end
        -- most pillars apply their mix ratio
        value = ratio * value + (1 - ratio) * last
        -- clean up partials so we are integral and clean
        if isAdditive and value ~= 0 then
            value = math.ceil(value)
        elseif isReductive and value ~= 0 then
            value = math.floor(value)
        end            
    else
        value = last -- omni leaves the stats wherever they are. no "swapping"
    end
    
    return value
end

-- needed to determine how much growth comes from
-- a given pillar or the omni pillar, potentially
function get_growth_value(last, value, isOmni, altar)
    local override = ModSettingGet("wand_workshop.omni_override")
    local ratio = ModSettingGet("wand_workshop.mix_fraction")
    if type(override) == "number" and override > 0 then
        ratio = clean_precision(override)
        --print("overridden growth ratio " .. ratio)
    elseif type(ratio) == "number" and ratio > 1 then
        ratio = clean_precision((ratio - 1) / 2)
        --print("default growth ratio " .. ratio)
    else
        ratio = 0
    end
    local growth = 0  
    if ratio > 0 then       
        local isAdditive = altar.operator == "additive"
        local isReductive = altar.operator == "reductive"    
        local hasImprovement = ((isAdditive and last >= value) or (isReductive and last <= value))
        -- other pillars replace the stat unless the wand is better
        if isOmni or hasImprovement then
            growth = ratio * value
        end
        -- ensure that growth happens. when reductive values go negative
        -- we don't want them to make a malus. just make their value absolute.
        if (isReductive and growth > 0) or (isAdditive and growth < 0) then
            growth = growth * -1
        end        
    end
    -- make sure values are integral numbers. under the hood, speed is in frames, not fractional.
    if growth ~= 0 then
        if growth > 0 then
            growth = math.ceil(growth)
        else
            growth = math.floor(growth)
        end
    end
    print("growth at " + growth)
    return growth
end

function clean_precision(d)
    if d ~= math.floor(d * 100 + 0.5) / 100 then -- make it not an ugly number...
        d = math.floor(d * 100 + 0.5) / 100
    end
    return d
end