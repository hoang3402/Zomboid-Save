local vehicleName = "Base.StepVan"

RVInterior.addInterior(vehicleName, { 24300, 13200, 0 }, {0, 13, 0})
RVInterior.canEnterFromBack(vehicleName,true)

local sharedVehicles = {
    "Base.StepVanMail",
    "Base.StepVan_Heralds",
    "Base.StepVan_Scarlet",
    "Base.Trailermovingmedium",
    "Base.moveurself",
    "Base.TwinkiesVan",
    "Base.SC_StepVanP30BunnyBread",
    "Base.SC_StepVanP30ParkRanger",
    "Base.SC_StepVanP30Police"
}

for i=1,#sharedVehicles do
    RVInterior.shareInterior(sharedVehicles[i], vehicleName)
    RVInterior.canEnterFromBack(sharedVehicles[i], true)
end
