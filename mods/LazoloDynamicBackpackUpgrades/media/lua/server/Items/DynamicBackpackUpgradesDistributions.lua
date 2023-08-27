require 'Items/ProceduralDistributions'

local Military = {"DynamicBackpacks.UpgradeCapacityMilitary","DynamicBackpacks.UpgradeWeightReductionMilitary"}
local MilitaryModifier = SandboxVars.DynamicBackpacks.MilitaryLootSpawns or 1
local Leather = {"DynamicBackpacks.UpgradeCapacityLeather","DynamicBackpacks.UpgradeWeightReductionLeather"}
local LeatherModifier = SandboxVars.DynamicBackpacks.LeatherLootSpawns or 1
local Jean = {"DynamicBackpacks.UpgradeCapacityJean","DynamicBackpacks.UpgradeWeightReductionJean"}
local JeanModifier = SandboxVars.DynamicBackpacks.JeanLootSpawns or 1
local Cloth = {"DynamicBackpacks.UpgradeCapacityCloth","DynamicBackpacks.UpgradeWeightReductionCloth"}
local ClothModifier = SandboxVars.DynamicBackpacks.ClothLootSpawns or 1


local Army = {"ArmyHangarOutfit","ArmyStorageOutfit","LockerArmyBedroom"}
local Surplus = {"ArmySurplusBackpacks","ArmySurplusMisc","ArmySurplusOutfit"}
local Police = {"PoliceStorageOutfit","PoliceLockers","SecurityLockers"}
local CampingStore = {"CampingLockers","CampingStoreBackpacks","CampingStoreClothes","CampingStoreGear"}
local GunStore = {"GunStoreCounter","GunStoreShelf"}
local Safehouse = {"SafehouseArmor"}
local ClothingStoreLeather = {"ClothingStoresJacketsLeather","ClothingStoresPantsLeather","CrateLeather","ClothingStoresSport"}
local ClothingStoreJean = {"ClothingStoresJeans","ClothingStoresOvershirts"}
local ClothingStoreCloth = {"ClothingStoresJumpers","ClothingStoresPants","ClothingStoresShirts","ClothingStoresSummer"}
local ClothingStorage = {"ClothingStorageAllShirts","ClothingStorageAllJackets"}
local House = {"DresserGeneric","LivingRoomSideTable","LivingRoomSideTableNoRemote","BedroomSideTable","ClosetShelfGeneric","WardrobeMan","WardrobeManClassy","WardrobeRedneck","WardrobeWoman","WardrobeWomanClassy"}
local Garage = {"GarageTools","GarageMetalwork","GarageCarpentry","GarageMechanics"}
local Gigamart = {"GigamartSchool","GigamartTools"}
local Misc = {"ImprovisedCrafts","FactoryLockers","GymLockers","BarCounterMisc","CrateTailoring","CrateClothesRandom"}


--Context spawn values
-- Car magazines in house bookshelves is 0.1
-- all of Brita's bags in army bedroom lockers is 0.8 
function Round2(Input)
	return math.floor((Input*100)+0.5)/100
end
function Drops(Item,SpawnMod,Table,Value)
	if Round2(Value*SpawnMod) > 0 then
		for i,v in pairs(Item) do
			for i2,v2 in pairs(Table) do
				table.insert(ProceduralDistributions.list[v2].items, v);
				table.insert(ProceduralDistributions.list[v2].items, Round2(Value*SpawnMod));
			end
		end
	end
end

--Army Drops
Drops(Military,MilitaryModifier,Army,1)
Drops(Military,MilitaryModifier,Police,1)
Drops(Military,MilitaryModifier,Surplus,2)
Drops(Military,MilitaryModifier,CampingStore,0.6)
Drops(Military,MilitaryModifier,GunStore,0.3)
Drops(Military,MilitaryModifier,Gigamart,0.01)
Drops(Military,MilitaryModifier,Safehouse,0.8)



--Leather Drops
Drops(Leather,LeatherModifier,Safehouse,2)
Drops(Leather,LeatherModifier,ClothingStoreLeather,1)
Drops(Leather,LeatherModifier,ClothingStorage,0.8)
Drops(Leather,LeatherModifier,CampingStore,1.6)
Drops(Leather,LeatherModifier,Police,4)
Drops(Leather,LeatherModifier,Misc,0.3)
Drops(Leather,LeatherModifier,GunStore,1.2)
Drops(Leather,LeatherModifier,House,0.1)
Drops(Leather,LeatherModifier,Gigamart,0.5)
Drops(Leather,LeatherModifier,Garage,0.5)

 -- Jean Drops
Drops(Jean,JeanModifier,Safehouse,4)
Drops(Jean,JeanModifier,ClothingStoreJean,3)
Drops(Jean,JeanModifier,ClothingStorage,1.2)
Drops(Jean,JeanModifier,Misc,1)
Drops(Jean,JeanModifier,House,0.6)
Drops(Jean,JeanModifier,CampingStore,2)
Drops(Jean,JeanModifier,Garage,1)
Drops(Jean,JeanModifier,Gigamart,2)

--Cloth Drops
Drops(Cloth,ClothModifier,ClothingStoreCloth,3)
Drops(Cloth,ClothModifier,ClothingStorage,1.6)
Drops(Cloth,ClothModifier,House,2)
Drops(Cloth,ClothModifier,CampingStore,3)
Drops(Cloth,ClothModifier,Misc,1)
Drops(Cloth,ClothModifier,Gigamart,3)

