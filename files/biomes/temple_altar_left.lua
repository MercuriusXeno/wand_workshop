RegisterSpawnFunction( 0xff0a17a0 , "spawn_wand_altar")
RegisterSpawnFunction( 0xff1a17a1 , "spawn_speed_altar")
RegisterSpawnFunction( 0xff2a17a2 , "spawn_reload_altar")
RegisterSpawnFunction( 0xff3a17a3 , "spawn_mana_altar")
RegisterSpawnFunction( 0xff4a17a4 , "spawn_recharge_altar")
RegisterSpawnFunction( 0xff5a17a5 , "spawn_shuffle_altar")
RegisterSpawnFunction( 0xff6a17a6 , "spawn_simulcast_altar")
 -- tempting to fix these to pattern ff6 -> ff7 through 9 
 -- but they're not broken in the png so i left it alone
RegisterSpawnFunction( 0xff6a17a7 , "spawn_spread_altar")
RegisterSpawnFunction( 0xff6a17a8 , "spawn_capacity_altar")
RegisterSpawnFunction( 0xff6a17a9 , "spawn_omni_altar")

function spawn_wand_altar(x, y)
  EntityLoad("mods/wand_workshop/files/entities/altar/main_altar.xml", x, y)
end

function spawn_speed_altar(x, y)
  EntityLoad("mods/wand_workshop/files/entities/altar/sacrificial_altars/speed_altar.xml", x, y)
end

function spawn_reload_altar(x, y)
  EntityLoad("mods/wand_workshop/files/entities/altar/sacrificial_altars/reload_altar.xml", x, y)
end

function spawn_mana_altar(x, y)
  EntityLoad("mods/wand_workshop/files/entities/altar/sacrificial_altars/mana_altar.xml", x, y)
end

function spawn_recharge_altar(x, y)
  EntityLoad("mods/wand_workshop/files/entities/altar/sacrificial_altars/recharge_altar.xml", x, y)
end

function spawn_shuffle_altar(x, y)
  EntityLoad("mods/wand_workshop/files/entities/altar/sacrificial_altars/shuffle_altar.xml", x, y)
end

function spawn_simulcast_altar(x, y)
  EntityLoad("mods/wand_workshop/files/entities/altar/sacrificial_altars/simulcast_altar.xml", x, y)
end

function spawn_spread_altar(x, y)
  EntityLoad("mods/wand_workshop/files/entities/altar/sacrificial_altars/spread_altar.xml", x, y)
end

function spawn_capacity_altar(x, y)
  EntityLoad("mods/wand_workshop/files/entities/altar/sacrificial_altars/capacity_altar.xml", x, y)
end

function spawn_omni_altar(x, y)
  EntityLoad("mods/wand_workshop/files/entities/altar/sacrificial_altars/omni_altar.xml", x, y)
end