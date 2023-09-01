require('NPCs/MainCreationMethods');

function createTrait()
    TraitFactory.addTrait("schizophrenia", getText("UI_trait_Schizophrenia"), -7, getText("UI_trait_Schizophreniaheader")..getText("\n")..getText("UI_trait_Schizophreniapoint1")..getText("\n")..getText("UI_trait_Schizophreniapoint2")..getText("\n")..getText("UI_trait_Schizophreniapoint3")..getText("\n")..getText("UI_trait_Schizophreniapoint4"), false, false);
    TraitFactory.setMutualExclusive("schizophrenia", "Deaf");
    TraitFactory.setMutualExclusive("schizophrenia", "AdrenalineJunkie");
end

Events.OnGameBoot.Add(createTrait)