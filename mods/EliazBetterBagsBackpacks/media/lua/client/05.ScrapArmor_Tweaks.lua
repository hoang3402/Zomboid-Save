require("ItemTweaker_Core");


if getActivatedMods():contains("ScrapArmor(new version)") then 

--BAGS--
TweakItem("Base.Rucksack","WeightReduction","95");
TweakItem("Base.Rucksack","Weight","1");
TweakItem("Base.Rucksack","Capacity","35");
TweakItem("Base.Rucksack","RunSpeedModifier","0.99");

--POUCHES-
TweakItem("Base.ScrapLegPouchL","WeightReduction","95");
TweakItem("Base.ScrapLegPouchL","Weight","0.2");

TweakItem("Base.ScrapLegPouchR","WeightReduction","95");
TweakItem("Base.ScrapLegPouchR","Weight","0.2");

end

if getActivatedMods():contains("ScrapArmor") then 

--BAGS--
TweakItem("Base.Rucksack","WeightReduction","95");
TweakItem("Base.Rucksack","Weight","1");
TweakItem("Base.Rucksack","Capacity","35");
TweakItem("Base.Rucksack","RunSpeedModifier","0.99");

--POUCHES-
TweakItem("Base.ScrapLegPouchL","WeightReduction","95");
TweakItem("Base.ScrapLegPouchL","Weight","0.2");

TweakItem("Base.ScrapLegPouchR","WeightReduction","95");
TweakItem("Base.ScrapLegPouchR","Weight","0.2");

end

