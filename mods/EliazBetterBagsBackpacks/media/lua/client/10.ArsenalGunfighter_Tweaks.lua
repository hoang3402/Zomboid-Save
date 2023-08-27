require("ItemTweaker_Core");

if getActivatedMods():contains("Arsenal(26)GunFighter") then 

-- Fanny
TweakItem("Base.CCW_FannyPack","WeightReduction","95");
TweakItem("Base.CCW_FannyPack","Weight","0.1");
TweakItem("Base.CCW_FannyPack","Capacity","4");
TweakItem("Base.CCW_FannyPack","RunSpeedModifier","0.99");

-- Purse
TweakItem("Base.CCW_Purse","WeightReduction","70");
TweakItem("Base.CCW_Purse","Weight","0.25");
TweakItem("Base.CCW_Purse","Capacity","16");

-- Police
TweakItem("Base.Bag_Police","WeightReduction","80");
TweakItem("Base.Bag_Police","Weight","0.5");
TweakItem("Base.Bag_Police","Capacity","23");
TweakItem("Base.Bag_Police","RunSpeedModifier","0.99");

-- Bugout
TweakItem("Base.Bag_Bugout","WeightReduction","80");
TweakItem("Base.Bag_Bugout","Weight","0.5");
TweakItem("Base.Bag_Bugout","Capacity","23");
TweakItem("Base.Bag_Bugout","RunSpeedModifier","0.99");

end