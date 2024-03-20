local log = include("diject.just_an_incarnate.utils.log")
local config = include("diject.just_an_incarnate.config")
local playerLib = include("diject.just_an_incarnate.player")
local localStorage = include("diject.just_an_incarnate.storage.localStorage")
local logger = include("diject.just_an_incarnate.storage.playerDataLogger")
local npc = include("diject.just_an_incarnate.libs.npc")
local customClassLib = include("diject.just_an_incarnate.libs.customClass")
local advTable = include("diject.just_an_incarnate.utils.table")
local cellLib = include("diject.just_an_incarnate.libs.cell")
local dataStorage = include("diject.just_an_incarnate.storage.dataStorage")
local mapSpawner = include("diject.just_an_incarnate.mapSpawner")


local onDamagePriority = 1749

local isDead = false

--- @param e loadedEventData
local function loadedCallback(e)
    localStorage.initPlayerStorage()
    config.initLocalData()

    if e.newGame then return end
    if customClassLib.isGameCustomClass() then
        customClassLib.saveClassData(tes3.player.object.class)
    end
end
event.register(tes3.event.loaded, loadedCallback)

--- @param e loadEventData
local function loadCallback(e)
    config.resetLocalToDefault()
    localStorage.reset()
    local class = customClassLib.getCustomClassRecord()
    if not class then return end
    class.modified = false
end
event.register(tes3.event.load, loadCallback, {priority = -9999})

--- @param e saveEventData
local function saveCallback(e)
    local class = customClassLib.getCustomClassRecord()
    if not class then return end
    class.modified = true
end
event.register(tes3.event.save, saveCallback)


local function processDead()

    local isWerewolf = tes3.mobilePlayer.werewolf
    if isWerewolf then
        tes3.runLegacyScript{command = "set PCWerewolf to 0", reference = tes3.player} ---@diagnostic disable-line: missing-fields
        tes3.runLegacyScript{command = "UndoWerewolf", reference = tes3.player} ---@diagnostic disable-line: missing-fields
    end

    dataStorage.savePlayerDeathInfo(config.localConfig.id)

    if config.data.misc.bounty.reset then
        tes3.mobilePlayer.bounty = 0
        if config.data.misc.bounty.removeStolen then
            tes3.runLegacyScript{command = "PayFine"} ---@diagnostic disable-line: missing-fields
        else
            tes3.runLegacyScript{command = "PayFineThief"} ---@diagnostic disable-line: missing-fields
        end
    end

    for _, cell in pairs(tes3.getActiveCells()) do
        for ref in cell:iterateReferences({tes3.objectType.npc, tes3.objectType.creature}) do
            local mobile = ref.mobile
            if mobile and mobile.health.current > 0 and mobile ~= tes3.mobilePlayer then
                local baseObject = mobile.object.baseObject
                if not baseObject.id:find("jai_dpl_") then
                    mobile.fight = baseObject.aiConfig.fight
                end
                if mobile.object.baseDisposition then
                    mobile.object.baseDisposition = baseObject.baseDisposition
                end
                mobile:stopCombat(true)
                tes3.modStatistic{reference = mobile, name = "health", current = 99999, limitToBase = true,}
                tes3.modStatistic{reference = mobile, name = "magicka", current = 99999, limitToBase = true,}
                tes3.modStatistic{reference = mobile, name = "fatigue", current = 99999, limitToBase = true,}
            end
        end
    end

    playerLib.createDuplicate()

    if not tes3.worldController.flagTeleportingDisabled then
        local markers = {}

        local configTable = tes3.player.cell.isOrBehavesAsExterior and config.data.revive.exterior or config.data.revive.interior

        if configTable.divineMarker then
            local marker = tes3.findClosestExteriorReferenceOfObject{object = tes3.getObject("DivineMarker")}
            if marker then
                table.insert(markers, {position = marker.position, orientation = marker.orientation, cell = marker.cell})
            end
        end
        if configTable.templeMarker then
            local marker = tes3.findClosestExteriorReferenceOfObject{object = tes3.getObject("TempleMarker")}
            if marker then
                table.insert(markers, {position = marker.position, orientation = marker.orientation, cell = marker.cell})
            end
        end
        if configTable.prisonMarker then
            local marker = tes3.findClosestExteriorReferenceOfObject{object = tes3.getObject("PrisonMarker")}
            if marker then
                table.insert(markers, {position = marker.position, orientation = marker.orientation, cell = marker.cell})
            end
        end
        if configTable.exteriorDoorMarker then
            local marker = cellLib.getRandomExteriorDoorMarker()
            if marker then
                table.insert(markers, {position = marker.position, orientation = marker.orientation, cell = marker.cell})
            end
        end
        if configTable.interiorDoorMarker and tes3.player.cell.isInterior then
            local marker = cellLib.getRandomDoorMarker(tes3.player.cell)
            if marker then
                table.insert(markers, {position = marker.position, orientation = marker.orientation, cell = marker.cell})
            end
        end
        if configTable.recall and tes3.mobilePlayer.markLocation then
            table.insert(markers, {position = tes3.mobilePlayer.markLocation.position, cell = tes3.mobilePlayer.markLocation.cell,
                orientation = tes3vector3.new(0, 0, tes3.mobilePlayer.markLocation.rotation)})
        end
        if configTable.exitFromInterior and tes3.player.cell.isInterior then
            local marker = cellLib.getExitExteriorMarker(tes3.player.cell)
            if marker then
                table.insert(markers, {position = marker.position, orientation = marker.orientation, cell = marker.cell})
            end
        end

        if #markers > 0 then
            local posData = markers[math.random(#markers)]

            tes3.positionCell{position = posData.position, orientation = posData.orientation, cell = posData.cell, forceCellChange = true}
            tes3.fadeOut{duration = 0.0001}
        end
    end

    tes3.modStatistic({
        reference = tes3.mobilePlayer,
        name = "health",
        current = 999999,
        limitToBase = true,
    })

    local decreaseExecuted = false
    if config.data.decrease.skill.count > 0 and config.localConfig.count % config.data.decrease.skill.interval == 0 then
        playerLib.skillDown(config.data.decrease.skill.count)
        decreaseExecuted = true
    end
    if config.data.decrease.level.count > 0 and config.localConfig.count % config.data.decrease.level.interval == 0 and
            (config.data.decrease.combine or not decreaseExecuted) then
        playerLib.levelDown(config.data.decrease.level.count)
    end

    if config.data.misc.rechargePower then
        for _, spell in pairs(tes3.player.object.spells) do
            if spell.castType == tes3.spellType.power then
                tes3.mobilePlayer:rechargePower(spell)
            end
        end
    end

    playerLib.reevaluateMissedPlayerEquipment()
    if config.data.spawn.transfer.replace.enabled then
        timer.delayOneFrame(function()
            playerLib.giveEquipmentFromRandomNPC(config.data.spawn.transfer.replace.regionSize / 100)
        end)
    else
        timer.delayOneFrame(function()
            playerLib.giveDefaultEquipment()
        end)
    end

    tes3.modStatistic({
        reference = tes3.mobilePlayer,
        name = "health",
        current = 999999,
        limitToBase = true,
    })
    tes3.modStatistic({
        reference = tes3.mobilePlayer,
        name = "magicka",
        current = 999999,
        limitToBase = true,
    })
    tes3.modStatistic({
        reference = tes3.mobilePlayer,
        name = "fatigue",
        current = 999999,
        limitToBase = true,
    })

    config.localConfig.count = config.localConfig.count + 1 ---@diagnostic disable-line: inject-field

    local statMenu = tes3ui.findMenu("MenuStat")
    if statMenu then
        event.trigger(tes3.event.uiActivated, {element = statMenu, newlyCreated = false}, {filter = "MenuStat"})
        statMenu:updateLayout()
    end

    playerLib.changePlayer()

    tes3.worldController.charGenState.value = -1

    timer.start{duration = 2, callback = function()
        playerLib.menuMode = false
        if isWerewolf then
            tes3.runLegacyScript{command = "set PCWerewolf to 1", reference = tes3.player} ---@diagnostic disable-line: missing-fields
        end
        timer.start{duration = config.data.revive.safeTime, callback = function() isDead = false end}
        timer.delayOneFrame(function() tes3.fadeIn{duration = config.data.revive.delay} end)
        playerLib.addRestoreSpells(math.max(1, config.data.revive.safeTime))
        tes3.setPlayerControlState{enabled = true,}
        tes3.mobilePlayer.paralyze = 0
        tes3.cancelAnimationLoop{reference = tes3.player}
    end}
end

local function getDamageMul()
    local fDifficultyMult = tes3.findGMST(tes3.gmst.fDifficultyMult).value
    local difficultyTerm = tes3.worldController.difficulty
    local res = 0
    if difficultyTerm > 0 then
        res = 1 + fDifficultyMult * difficultyTerm
    else
        res = 1 + difficultyTerm / fDifficultyMult
    end
    return res
end

local function onDamage(e)
    if e.reference ~= tes3.player then
        return
    end

    local damageValue = math.abs(e.damage) * getDamageMul()
    if isDead then
        if e.damage < 0 then
            tes3.mobilePlayer.health.current = 2 + damageValue
        end
        e.damage = 0
        e.claim = true
        e.block = true
        return false
    end

    if tes3.mobilePlayer.health.current - math.abs(damageValue) <= 1 then
        e.damage = 0
        e.claim = true
        e.block = true
        if isDead then return false end
        isDead = true
        log("triggered", "h",tes3.mobilePlayer.health.current)
        tes3.setPlayerControlState{enabled = false,}
        tes3.worldController.charGenState.value = 10
        if config.data.text.death then
            tes3.messageBox{message = config.data.text.death, duration = 10}
        end
        tes3.setStatistic({
            reference = tes3.mobilePlayer,
            name = "health",
            current = 2,
            limitToBase = false,
        })
        if tes3.mobilePlayer.isSwimming then
            tes3.playAnimation{reference = tes3.player, group = tes3.animationGroup.swimKnockOut,}
            tes3.playAnimation{reference = tes3.player1stPerson, group = tes3.animationGroup.swimKnockOut,}
        else
            tes3.playAnimation{reference = tes3.player, group = tes3.animationGroup.knockOut,}
            tes3.playAnimation{reference = tes3.player1stPerson, group = tes3.animationGroup.knockOut,}
        end
        tes3.mobilePlayer.paralyze = 1
        tes3.fadeOut{duration = config.data.revive.delay}
        timer.start{duration = config.data.revive.delay, callback = processDead}
    end
    log("damage", e.damage, "value", damageValue, "health", tes3.mobilePlayer.health.current, "new health", tes3.mobilePlayer.health.current - damageValue)
end

event.register(tes3.event.damage, onDamage, {priority = onDamagePriority})

--- @param e cellActivatedEventData
local function cellActivatedCallback(e)
    if not localStorage.isReady() then return end
    local spawner = mapSpawner:new(e.cell, config.localConfig.id, localStorage.data)

    local cellInfo = spawner:getCellLocalInfo()
    if cellInfo.lastSpawnTimestamp and cellInfo.lastSpawnTimestamp + config.data.map.spawn.interval > tes3.getSimulationTimestamp() then return end
    cellInfo.lastSpawnTimestamp = tes3.getSimulationTimestamp()

    ---@type jai.item.decreaseItemStats.params
    local itemStatMultipliers
    if config.data.map.spawn.items.change.enbaled then
        itemStatMultipliers = {multiplier = config.data.map.spawn.items.change.multiplier, valueMul = config.data.map.spawn.items.change.costMul}
    end
    local count = 0
    for i = 1, config.data.map.spawn.count do
        if config.data.map.spawn.chance / 100 > math.random() then
            count = count + 1
        end
    end
    if count > 0 then
        spawner:spawn{count = count, maxCount = config.data.map.spawn.maxCount,
            actorParams = {spawnConfig = config.data.map.spawn.body, transferConfig = config.data.map.spawn.transfer,
            createNewItemRecord = config.data.map.spawn.items.change.enbaled, itemStatMultipliers = itemStatMultipliers, newItemPrefix = config.data.text.itemPrefix}}
    end
end
event.register(tes3.event.cellActivated, cellActivatedCallback)

--- @param e bodyPartAssignedEventData
local function bodyPartAssignedCallback(e)
    if not e.reference or not e.bodyPart or e.bodyPart.partType ~= tes3.activeBodyPartLayer.base then return end
    if (e.reference == tes3.player or e.reference == tes3.player1stPerson) and
            (e.index ~= tes3.activeBodyPart.hair and e.index ~= tes3.activeBodyPart.head) then

        e.bodyPart = npc.getRaceBaseBodyPart(e.reference, e.index)
    else
        local savedBodyPart = npc.getSavedBodyPart(e.reference, e.index)
        if savedBodyPart then
            e.bodyPart = savedBodyPart
        end
    end
end
event.register(tes3.event.bodyPartAssigned, bodyPartAssignedCallback)

--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
    if e.reference and e.reference.baseObject.id:find("jai_dpl_") then
        local tooltip = npc.getTooltip(e.reference)
        if tooltip and e.tooltip then
            local nameContainer = e.tooltip:findChild("PartHelpMenu_main")
            if not nameContainer then return end
            local nameLabel = nameContainer:findChild("HelpMenu_name")
            if not nameLabel then return end
            nameLabel.text = tooltip
            e.tooltip:getTopLevelMenu():updateLayout()
        end
    end
end
event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)

--- @param e mobileActivatedEventData
local function mobileActivatedCallback(e)
    if e.mobile.actorType == tes3.actorType.npc and e.mobile.chameleon > 0 then
        e.mobile:updateOpacity()
    end
end
event.register(tes3.event.mobileActivated, mobileActivatedCallback)