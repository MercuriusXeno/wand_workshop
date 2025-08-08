---@diagnostic disable: lowercase-global, missing-global-doc
dofile_once("mods/wand_workshop/files/scripts/altar.lua")
function interacting(player_id, altar_id, interactable_name)
    Pickup_Item_From_Altar(altar_id, player_id, interactable_name)
end