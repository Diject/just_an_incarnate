local advTable = include("diject.just_an_incarnate.utils.table")
local localStorage = include("diject.just_an_incarnate.storage.localStorage")
local log = include("diject.just_an_incarnate.utils.log")

local globalStorageName = "JustAnIncarnateByDiject_Config"
local localStorageName = "localConfig"
local version = 0

local this = {}

---@class config.globalData
this.default = {
    revive = {
        enabled = true,
        delay = 5,
        safeTime = 3,
        interior = {
            divineMarker = false,
            templeMarker = false,
            prisonMarker = false,
            exteriorDoorMarker = false,
            interiorDoorMarker = false,
            exitFromInterior = false,
            recall = false,
        },
        exterior = {
            divineMarker = false,
            templeMarker = false,
            prisonMarker = false,
            exteriorDoorMarker = false,
            interiorDoorMarker = false,
            exitFromInterior = false,
            recall = false,
        },
    },
    misc = {
        bounty = {
            reset = true,
            removeStolen = true,
        },
        rechargePower = true,
        sendDeathEvent = true,
        sendLoadedEvent = true,
    },
    change = {
        race = true,
        bodyParts = true,
        class = {
            enbled = true,
            chanceToCustom = 0,
            chanceToPlayerCustom = 100,
        },
        sign = true,
        sex = true,
    },
    decrease = {
        level = {
            count = 0,
            interval = 2,
        },
        skill = {
            count = 1,
            interval = 1,
            levelUp = {
                progress = true,
                attributes = true,
            },
        },
        combine = true,
    },
    spawn = {
        addSummonSpell = true,
        transfer = {
            inPersent = true,
            equipment = 100,
            equipedItems = 100,
            magicItems = 100,
            misc = 100,
            goldPercent = 0,
            books = 100,
            replace = {
                enabled = true,
                regionSize = 10,
            }
        },
        body = {
            chance = 100,
            stats = {
                health = 200,
                fatigue = 200,
                magicka = 200,
            },
            chanceToCorpse = 100,
        },
        creature = {
            chance = 0,
            stats = {
                health = 200,
                fatigue = 150,
                magicka = 200,
            },
            chanceToCorpse = 0,
        },
    },
    text = {
        death = "You have met your destiny and no longer carry the burden of prophecy. You were a false incarnate.",
        summonSpellDescription = "Teleports all false incarnates from the current location to you",
    },
}

---@class config.globalData
this.data = advTable.deepcopy(this.default)

---@class config.globalData
this.global = advTable.deepcopy(this.default)

do
    local data = mwse.loadConfig(globalStorageName)
    if data then
        this.data = data
        advTable.addMissing(this.data, this.default)
        this.global = advTable.deepcopy(this.data)
    else
        mwse.saveConfig(globalStorageName, this.data)
    end
end

---@class config.localData
this.localDefault = {
    version = version,
    count = 0, -- number of deaths
    id = nil,
    config = {},
}

---@class config.localData
this.localConfig = advTable.deepcopy(this.localDefault)


function this.initLocalData()
    if localStorage.isReady() then
        advTable.applyChanges(this.data, this.global)
        local storageData = localStorage.data[localStorageName]
        if not storageData then
            local id = tostring(os.time())
            this.localConfig.id = id:sub(3, id:len())
            localStorage.data[localStorageName] = this.localConfig
        else
            this.localConfig = storageData
            advTable.addMissing(this.localConfig, this.localDefault)
            advTable.applyChanges(this.data, this.localConfig.config)
        end
        return true
    end
    return false
end

function this.resetLocalToDefault()
    if not localStorage.isReady() then return end
    advTable.applyChanges(this.localConfig, this.localDefault)
end

---@param path string
---@return any, boolean return return value and is the value from the local config
function this.getValueByPath(path)
    local value = advTable.getValueByPath(this.localConfig.config, path)
    if value ~= nil then
        return value, true
    end
    return advTable.getValueByPath(this.data, path), false
end

---@param path string
---@param newValue any
---@return boolean success
function this.setValueByPath(path, newValue)
    if tes3.player then
        advTable.setValueByPath(this.localConfig.config, path, newValue)
        log("Local config value", path, newValue)
    else
        advTable.setValueByPath(this.global, path, newValue)
        log("Global config value", path, newValue)
    end
    return advTable.setValueByPath(this.data, path, newValue)
end

---@param path string
---@param newValue any
---@return boolean success
function this.setGlobalValueByPath(path, newValue)
    advTable.setValueByPath(this.global, path, newValue)
    log("Global config value", path, newValue)
    return advTable.setValueByPath(this.data, path, newValue)
end

function this.resetValueToGlobal(path)
    local globalVal = advTable.getValueByPath(this.global, path)
    if tes3.player then
        advTable.setValueByPath(this.localConfig.config, path, nil)
        log("Local config value", path, "nil")
    end
    log("Global config value", path, globalVal)
    advTable.setValueByPath(this.data, path, globalVal)
    return globalVal
end

function this.save()
    mwse.saveConfig(globalStorageName, this.global)
end

function this.updateVersionInPlayerStorage()
    this.localConfig.version = version
end

return this