RegisterSpawnFunction( 0xff0a17a9 , "SpawnTargetAltar")
RegisterSpawnFunction( 0xff6a17a0 , "SpawnOfferAltar")

function SpawnTargetAltar(x, y)
  EntityLoad("mods/wand_workshop/files/entities/altar/target_altar.xml", x, y)
end

function SpawnOfferAltar(x, y)
  EntityLoad("mods/wand_workshop/files/entities/altar/offer_altar.xml", x, y)
end