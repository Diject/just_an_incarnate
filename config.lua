local advTable = include("diject.just_an_incarnate.utils.table")
local localStorage = include("diject.just_an_incarnate.storage.localStorage")

local globalStorageName = "JustAnIncarnateByDiject_Config"
local localStorageName = "localConfig"

local this = {}

---@class config.globalData
this.default = {
    revive = {
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
        transfer = {
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
    map = {
        ---@class jai.config.mapSpawn
        spawn = {
            interval = 72, -- game hours
            chance = 25,
            count = 2,
            maxCount = 2,
            items = {
                change = {
                    enbaled = true,
                    multiplier = 0.8,
                    costMul = 0.05,
                },
            },
            transfer = {
                equipment = 100,
                equipedItems = 100,
                magicItems = 100,
                misc = 100,
                goldPercent = 20,
                books = 100,
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
    },
    text = {
        death = "With your death, the thread of prophecy continues. You were a false incarnate.",
        itemPrefix = "Weak",
    },
}

---@class config.globalData
this.data = advTable.deepcopy(this.default)

-- do
--     local data = mwse.loadConfig(globalStorageName)
--     if data then
--         this.data = data
--         advTable.addMissing(this.data, this.default)
--     else
--         mwse.saveConfig(globalStorageName, this.data)
--     end
-- end

---@class config.localData
this.localDefault = {
    count = 0, -- number of deaths
    id = nil,
}

---@class config.localData
this.localConfig = advTable.deepcopy(this.localDefault)


function this.initLocalData()
    if localStorage.isReady() then
        local storageData = localStorage.data[localStorageName]
        if not storageData then
            local id = tostring(os.time())
            this.localConfig.id = id:sub(3, id:len())
            localStorage.data[localStorageName] = this.localConfig
        else
            this.localConfig = storageData
            advTable.addMissing(this.localConfig, this.localDefault)
        end
        return true
    end
    return false
end

function this.resetLocalToDefault()
    if not localStorage.isReady() then return end
    advTable.applyChanges(this.localConfig, this.localDefault)
end

return this