local config = include("diject.just_an_incarnate.config")

local this = {}

local function messageBox(params)
    local m = tes3ui.createMenu{id = "JustAnIncarnate_MessageBox", fixedFrame = true}
    m.autoWidth = true
    m.autoHeight = true
    m.maxWidth = 700
    m.childAlignX = 0.5
    m.childAlignY = 0.5
    m.ignoreLayoutX = false
    m.ignoreLayoutY = false
    m.childAlignX = 0
    m.childAlignY = 0
    m.heightProportional = nil
    m.widthProportional = nil
    local label = m:createLabel{text = params.message}
    label.wrapText = true
    label.autoWidth = false
    label.width = 500
    for i, text in pairs(params.buttons) do
        local btn = m:createButton{text = text}
        btn:register(tes3.uiEvent.mouseClick, function(e)
            params.callback({button = i - 1, element = m})
        end)
    end
    m:updateLayout()
    return m
end

local function callback(e)
    if e.button == 0 then
        config.applyDefault()
    elseif e.button == 1 then
        config.setValueByPath("revive.interior.divineMarker", false)
        config.setValueByPath("revive.interior.templeMarker", false)
        config.setValueByPath("revive.interior.prisonMarker", false)
        config.setValueByPath("revive.interior.exteriorDoorMarker", true)
        config.setValueByPath("revive.interior.interiorDoorMarker", false)
        config.setValueByPath("revive.interior.exitFromInterior", false)
        config.setValueByPath("revive.interior.recall", false)

        config.setValueByPath("revive.exterior.divineMarker", false)
        config.setValueByPath("revive.exterior.templeMarker", false)
        config.setValueByPath("revive.exterior.prisonMarker", false)
        config.setValueByPath("revive.exterior.exteriorDoorMarker", true)
        config.setValueByPath("revive.exterior.exitFromInterior", false)
        config.setValueByPath("revive.exterior.recall", false)

        config.setValueByPath("change.race", true)
        config.setValueByPath("change.bodyParts", true)
        config.setValueByPath("change.sign", true)
        config.setValueByPath("change.sex", true)
        config.setValueByPath("change.class.enbled", true)

        config.setValueByPath("decrease.level.count", 1)
        config.setValueByPath("decrease.level.interval", 25)
        config.setValueByPath("decrease.skill.count", 1)
        config.setValueByPath("decrease.skill.interval", 8)
        config.setValueByPath("decrease.skill.levelUp.progress", true)
        config.setValueByPath("decrease.skill.levelUp.attributes", true)
        config.setValueByPath("decrease.spell.count", 1)
        config.setValueByPath("decrease.spell.interval", 15)
        config.setValueByPath("decrease.spell.random", true)
        config.setValueByPath("decrease.combine", true)

        config.setValueByPath("spawn.transfer.inPersent", true)
        config.setValueByPath("spawn.transfer.equipment", 100)
        config.setValueByPath("spawn.transfer.equipedItems", 100)
        config.setValueByPath("spawn.transfer.magicItems", 100)
        config.setValueByPath("spawn.transfer.misc", 100)
        config.setValueByPath("spawn.transfer.goldPercent", 100)
        config.setValueByPath("spawn.transfer.replace.enabled", true)
        config.setValueByPath("spawn.transfer.replace.regionSize", 100)
    elseif e.button == 2 then
        config.setValueByPath("revive.interior.divineMarker", true)
        config.setValueByPath("revive.interior.templeMarker", true)
        config.setValueByPath("revive.interior.prisonMarker", true)
        config.setValueByPath("revive.interior.exteriorDoorMarker", false)
        config.setValueByPath("revive.interior.interiorDoorMarker", false)
        config.setValueByPath("revive.interior.exitFromInterior", false)
        config.setValueByPath("revive.interior.recall", false)

        config.setValueByPath("revive.exterior.divineMarker", true)
        config.setValueByPath("revive.exterior.templeMarker", true)
        config.setValueByPath("revive.exterior.prisonMarker", true)
        config.setValueByPath("revive.exterior.exteriorDoorMarker", false)
        config.setValueByPath("revive.exterior.exitFromInterior", false)
        config.setValueByPath("revive.exterior.recall", false)

        config.setValueByPath("change.race", false)
        config.setValueByPath("change.bodyParts", false)
        config.setValueByPath("change.sign", false)
        config.setValueByPath("change.sex", false)
        config.setValueByPath("change.class.enbled", false)

        config.setValueByPath("decrease.level.count", 0)
        config.setValueByPath("decrease.skill.count", 0)
        config.setValueByPath("decrease.spell.count", 0)

        config.setValueByPath("spawn.transfer.equipment", 0)
        config.setValueByPath("spawn.transfer.equipedItems", 0)
        config.setValueByPath("spawn.transfer.magicItems", 0)
        config.setValueByPath("spawn.transfer.misc", 0)
        config.setValueByPath("spawn.transfer.goldPercent", 0)
        config.setValueByPath("spawn.transfer.replace.enabled", false)

        config.setValueByPath("spawn.body.chance", 0)
        config.setValueByPath("spawn.creature.chance", 0)
    elseif e.button == 3 then
        config.setValueByPath("spawn.transfer.inPersent", true)
        config.setValueByPath("spawn.transfer.equipment", 100)
        config.setValueByPath("spawn.transfer.equipedItems", 100)
        config.setValueByPath("spawn.transfer.magicItems", 100)
        config.setValueByPath("spawn.transfer.misc", 100)
        config.setValueByPath("spawn.transfer.goldPercent", 100)
        config.setValueByPath("spawn.transfer.books", 100)
    elseif e.button == 4 then
        config.setValueByPath("spawn.transfer.inPersent", true)
        config.setValueByPath("spawn.transfer.equipment", 0)
        config.setValueByPath("spawn.transfer.equipedItems", 0)
        config.setValueByPath("spawn.transfer.magicItems", 0)
        config.setValueByPath("spawn.transfer.misc", 0)
        config.setValueByPath("spawn.transfer.goldPercent", 0)
        config.setValueByPath("spawn.transfer.books", 0)
    elseif e.button == 5 then
        config.setValueByPath("spawn.body.chance", 0)
        config.setValueByPath("spawn.creature.chance", 100)
    elseif e.button == 6 then
        config.setValueByPath("spawn.body.chance", 100)
        config.setValueByPath("spawn.creature.chance", 0)
    elseif e.button == 7 then
        config.setValueByPath("decrease.level.count", 1)
        config.setValueByPath("decrease.level.interval", 12)
        config.setValueByPath("decrease.skill.count", 1)
        config.setValueByPath("decrease.skill.interval", 4)
        config.setValueByPath("decrease.skill.levelUp.progress", true)
        config.setValueByPath("decrease.skill.levelUp.attributes", true)
        config.setValueByPath("decrease.spell.count", 1)
        config.setValueByPath("decrease.spell.interval", 6)
        config.setValueByPath("decrease.spell.random", true)
        config.setValueByPath("decrease.combine", true)
    elseif e.button == 8 then
        config.setValueByPath("decrease.level.count", 1)
        config.setValueByPath("decrease.level.interval", 25)
        config.setValueByPath("decrease.skill.count", 1)
        config.setValueByPath("decrease.skill.interval", 8)
        config.setValueByPath("decrease.skill.levelUp.progress", true)
        config.setValueByPath("decrease.skill.levelUp.attributes", true)
        config.setValueByPath("decrease.spell.count", 1)
        config.setValueByPath("decrease.spell.interval", 15)
        config.setValueByPath("decrease.spell.random", true)
        config.setValueByPath("decrease.combine", false)
    elseif e.button == 9 then
        config.setValueByPath("decrease.level.count", 0)
        config.setValueByPath("decrease.skill.count", 0)
        config.setValueByPath("decrease.spell.count", 0)
    elseif e.button == 10 then
        config.setValueByPath("change.race", true)
        config.setValueByPath("change.bodyParts", true)
        config.setValueByPath("change.sign", true)
        config.setValueByPath("change.sex", true)
        config.setValueByPath("change.class.enbled", true)
    elseif e.button == 11 then
        config.setValueByPath("change.race", false)
        config.setValueByPath("change.bodyParts", false)
        config.setValueByPath("change.sign", false)
        config.setValueByPath("change.sex", false)
        config.setValueByPath("change.class.enbled", false)
    elseif e.button == 12 then
        config.setValueByPath("revive.interior.divineMarker", true)
        config.setValueByPath("revive.interior.templeMarker", true)
        config.setValueByPath("revive.interior.prisonMarker", false)
        config.setValueByPath("revive.interior.exteriorDoorMarker", false)
        config.setValueByPath("revive.interior.interiorDoorMarker", false)
        config.setValueByPath("revive.interior.exitFromInterior", false)
        config.setValueByPath("revive.interior.recall", false)

        config.setValueByPath("revive.exterior.divineMarker", true)
        config.setValueByPath("revive.exterior.templeMarker", true)
        config.setValueByPath("revive.exterior.prisonMarker", false)
        config.setValueByPath("revive.exterior.exteriorDoorMarker", false)
        config.setValueByPath("revive.exterior.exitFromInterior", false)
        config.setValueByPath("revive.exterior.recall", false)
    elseif e.button == 13 then
        config.setValueByPath("revive.interior.divineMarker", true)
        config.setValueByPath("revive.interior.templeMarker", true)
        config.setValueByPath("revive.interior.prisonMarker", false)
        config.setValueByPath("revive.interior.exteriorDoorMarker", false)
        config.setValueByPath("revive.interior.interiorDoorMarker", false)
        config.setValueByPath("revive.interior.exitFromInterior", true)
        config.setValueByPath("revive.interior.recall", true)

        config.setValueByPath("revive.exterior.divineMarker", true)
        config.setValueByPath("revive.exterior.templeMarker", true)
        config.setValueByPath("revive.exterior.prisonMarker", false)
        config.setValueByPath("revive.exterior.exteriorDoorMarker", false)
        config.setValueByPath("revive.exterior.exitFromInterior", false)
        config.setValueByPath("revive.exterior.recall", true)
    elseif e.button == 14 then
        config.setValueByPath("revive.interior.divineMarker", true)
        config.setValueByPath("revive.interior.templeMarker", true)
        config.setValueByPath("revive.interior.prisonMarker", true)
        config.setValueByPath("revive.interior.exteriorDoorMarker", true)
        config.setValueByPath("revive.interior.interiorDoorMarker", true)
        config.setValueByPath("revive.interior.exitFromInterior", true)
        config.setValueByPath("revive.interior.recall", true)

        config.setValueByPath("revive.exterior.divineMarker", true)
        config.setValueByPath("revive.exterior.templeMarker", true)
        config.setValueByPath("revive.exterior.prisonMarker", true)
        config.setValueByPath("revive.exterior.exteriorDoorMarker", true)
        config.setValueByPath("revive.exterior.exitFromInterior", true)
        config.setValueByPath("revive.exterior.recall", true)
    elseif e.button == 15 then
        e.element:destroy()
    end
end

function this.showMessage()
    messageBox({ message = "Select presets for the Just an Incarnate mod (a mod that allows you to respawn after death). You can select several presets one by one",
        buttons = {
            "I wanna all default",
            "I want sort of a roguelike (new character, spawn location and equipment + penalties)",
            "I wanna just respawn",
            "I want sort of like in souls games (all inventory transfer to the courpse)",
            "I don't want like in souls games (none of inventory transfer)",
            "I wanna spawn a ghost or something like that in place of the remains.",
            "Remains are the right choice",
            "I wanna hard penalties for death",
            "I wanna light penalties for death",
            "I don't want any penalties at all",
            "I wanna get a new character after death (new race, class and etc.)",
            "No, keep my old character",
            "I wanna respawn only at shrine markers",
            "I wanna respawn at shrine/recall markers and at the entrance for interior dungeons",
            "I wanna respawn everywhere randomly",
            "I'm done - close the menu"
        },
        callback = callback}
    )
end

return this