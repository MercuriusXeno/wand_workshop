
dofile_once("data/scripts/lib/utilities.lua")
DEBUG_MODE = true
function Log(s)
    if DEBUG_MODE then
        GamePrint("-== WAND_WORKSHOP_DEBUG ==-" .. s)
        print("-== WAND_WORKSHOP_DEBUG ==-" .. s)
    end
end
Log("Debug lua loaded")