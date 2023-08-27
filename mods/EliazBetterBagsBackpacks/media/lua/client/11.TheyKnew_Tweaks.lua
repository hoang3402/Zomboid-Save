require("ItemTweaker_Core");

if getActivatedMods():contains("TheyKnew") then 

-- Tactical Satchel
TweakItem("TheyKnew.MysteriousSatchel","WeightReduction","95");
TweakItem("TheyKnew.MysteriousSatchel","Weight","0.5");
TweakItem("TheyKnew.MysteriousSatchel","Capacity","18");
TweakItem("TheyKnew.MysteriousSatchel","CanBeEquipped","FannyPackBack");
TweakItem("TheyKnew.MysteriousSatchel","BodyLocation","Nose");
TweakItem("TheyKnew.MysteriousSatchel","ClothingItemExtra","MysteriousSatchel");
TweakItem("TheyKnew.MysteriousSatchel","ClothingItemExtraOption","FannyPack_WearBack");

end