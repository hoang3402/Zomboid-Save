local Mod = require("MaintenanceImprovesRepair/mod")

local workshopId = "2920089312"

MaintenanceImprovesRepair = Mod:new(workshopId)

-- To automatically exclude certain skills, items, fixers use this code:
-- require("MaintenanceImprovesRepair/patchFixers") -- very important, this makes sure that your file is run after this one

-- We use the table like a hash map instead of array, to make the lookup easier later
MaintenanceImprovesRepair.skipSkills = {}
-- example of how to remove patching for a specific skill
-- MaintenanceImprovesRepair.skipSkills["Mechanics"] = true

MaintenanceImprovesRepair.skipItems = {}
-- example of how to remove patching for a specific item
-- MaintenanceImprovesRepair.skipItems["Axe"] = true

MaintenanceImprovesRepair.skipFixers = { }
-- example of how to remove patching for a specific fixer (i.e. item that you repair with)
-- MaintenanceImprovesRepair.skipFixers["DuctTape"] = true

function parseSandboxOption(optionString)
    local tokens = string.split(optionString, ';')
    local values = {}
    for i=1,#tokens do
        values[i] = string.trim(tokens[i])
    end
    return values
end

function convertSkillNames(skills)
    local nameMap = {
        ["carpentry"] = "Woodwork",
        ["metalworking"] = "MetalWelding",
        ["first aid"] = "Doctor",
        ["firstaid"] = "Doctor",
        ["foraging"] = "PlantScavenging",
        ["electrical"] = "Electricity"
    }
    local newSkills = {}
    for i=1,#skills do
        local skill = string.lower(skills[i])
        local converted = nameMap[skill]
        if converted ~= nil then
            skill = converted
        end
        skill = string.format("%s%s", string.upper(string.sub(skill, 1, 1)), string.sub(skill, 2))
        newSkills[#newSkills + 1] = skill
    end
    return newSkills
end

function addListToTable(list, tbl)
    for i=1,#list do
        tbl[list[i]] = true
    end
end

function MaintenanceImprovesRepair.eventHandlers.OnGameStart()
    addListToTable(parseSandboxOption(SandboxVars.MIR.SkipItems), MaintenanceImprovesRepair.skipItems)
    addListToTable(convertSkillNames(parseSandboxOption(SandboxVars.MIR.SkipSkills)), MaintenanceImprovesRepair.skipSkills)
    addListToTable(parseSandboxOption(SandboxVars.MIR.SkipFixers), MaintenanceImprovesRepair.skipFixers)

    local allFixing = getScriptManager():getAllFixing(ArrayList:new())
    for i=0,allFixing:size()-1 do
        local fixing = allFixing:get(i)
        local requiredItems = fixing:getRequiredItem() -- returns a list, even tho the name suggests otherwise
        local skipItem = false
        for j=0,requiredItems:size()-1 do
            if MaintenanceImprovesRepair.skipItems[requiredItems:get(j)] ~= nil then
                skipItem = true
            end
        end
        if not skipItem then
            local fixers = fixing:getFixers()
            local fixersToDelete = ArrayList:new()
            local newFixers = ArrayList:new()
            for j=0,fixers:size()-1 do
                local fixer = fixers:get(j)
                if MaintenanceImprovesRepair.skipFixers[fixer:getFixerName()] == nil then
                    local skills = fixer:getFixerSkills()
                    -- print(string.format("Creating new fixer for item %s, fixer %s", fixing:getName(), fixer:getFixerName()))
                    if skills == nil then
                        -- print(string.format("Fixer %s has no associated skills, creating new fixer", fixing:getName(), fixer:getFixerName()))
                        local newFixer = Fixer.new(fixer:getFixerName(), LinkedList:new(), fixer:getNumberOfUse())
                        fixersToDelete:add(fixer)
                        newFixers:add(newFixer)
                        skills = newFixer:getFixerSkills()
                        local maintenanceSkill = FixerSkill.new("Maintenance", 0)
                        skills:add(maintenanceSkill)
                    else
                        local skipFixer = false
                        for s=0,skills:size()-1 do
                            local skill = skills:get(s)
                            if MaintenanceImprovesRepair.skipSkills[skill:getSkillName()] ~= nil then
                                skipFixer = true
                            end
                        end
                        if skipFixer then
                            -- print(string.format("Fixer %s-%s is mechanics, skipping", fixing:getName(), fixer:getFixerName()))
                        else
                            local maintenanceSkill = FixerSkill.new("Maintenance", 0)
                            skills:add(maintenanceSkill)
                        end
                    end
                end
            end

            for j=0,fixersToDelete:size()-1 do
                local oldFixer = fixersToDelete:get(j)
                -- print(string.format("Delete fixer %s", oldFixer:getFixerName()))
                fixers:remove(oldFixer)
            end
            for j=0,newFixers:size()-1 do
                local newFixer = newFixers:get(j)
                -- print(string.format("Add new fixer %s", newFixer:getFixerName()))
                fixers:add(newFixer)
            end
        end
    end
end

MaintenanceImprovesRepair:init()
