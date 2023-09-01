local vehicleName = "Base.Van"

RVInterior.addInterior(vehicleName, { 24300, 12900, 0 }, {0, 13, 0})
RVInterior.canEnterFromBack(vehicleName,true)

local sharedVehicles = {
    "Base.VanRadio",
    "Base.Radio_3N",
    "Base.VanSpecial",
    "Base.VanSpiffo",
    "Base.Van_KnoxDisti",
    "Base.Van_LectroMax",
    "Base.Van_MassGenFac",
    "Base.Van_Transit"
}

for i=1,#sharedVehicles do
    RVInterior.shareInterior(sharedVehicles[i], vehicleName)
    RVInterior.canEnterFromBack(sharedVehicles[i], true)
end