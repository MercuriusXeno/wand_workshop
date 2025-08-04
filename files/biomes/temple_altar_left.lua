dofile_once("mods/wand_workshop/files/scripts/debug.lua")
Log("wand_workshop altar_left.lua running")

RegisterSpawnFunction( 0xff6a17a9 , "spawn_target_altar")
RegisterSpawnFunction( 0xff0a17a0 , "spawn_offer_altar")

function spawn_target_altar(x, y)
  Log("Target altar spawned")
  EntityLoad("mods/wand_workshop/files/entities/target_altar.xml", x, y)
end

function spawn_offer_altar(x, y)
  Log("Offering altar spawned")
  EntityLoad("mods/wand_workshop/files/entities/offer_altar.xml", x, y)
end

Log("wand_workshop altar_left.lua ran")