local npc = include("diject.just_an_incarnate.libs.npc")
local dataStorage = include("diject.just_an_incarnate.storage.dataStorage")
local stringLib = include("diject.just_an_incarnate.utils.string")

local mapStorageLabel = "map"

---@class jai.mapSpawner
local this = {}

---@param cell tes3cell
---@param playerId string
function this:new(cell, playerId, localStorageData)
    local out = {}
    setmetatable(out, self)
    self.__index = self
    self.__cell = cell
    self.__playerId = playerId
    self.__playerData = localStorageData
    self.__cellInfo = nil
    ---@type jai.mapSpawner
    return out
end

---@class jai.mapSpawmer.localInfo
---@field spawned table<string, boolean|integer>
---@field spawned.count integer
---@field lastSpawnTimestamp integer|nil


---@return jai.mapSpawmer.localInfo
function this:getCellLocalInfo()
    if self.__cellInfo then return self.__cellInfo end
    local storage = self.__playerData[mapStorageLabel]
    if not storage then
        self.__playerData[mapStorageLabel] = {}
        storage = self.__playerData[mapStorageLabel]
    end
    local cellName = stringLib.getCellName(self.__cell)
    storage = storage[cellName]
    if not storage then
        self.__playerData[mapStorageLabel][cellName] = {spawned = {count = 0}}
        storage = self.__playerData[mapStorageLabel][cellName]
    end
    self.__cellInfo = storage
    return storage
end

---@class jai.mapSpawner.spawn.params
---@field count integer
---@field maxCount integer
---@field actorParams jai.npc.createActorDuplicate.params

---@param params jai.mapSpawner.spawn.params
function this:spawn(params)
    local count = params.count
    local maxCount = params.maxCount
    local structure = dataStorage.loadDeathMapFileStructureForCell(self.__cell)
    local localInfo = self.__cellInfo or self:getCellLocalInfo()

    localInfo.lastSpawnTimestamp = tes3.getSimulationTimestamp()
    count = math.min(count, maxCount - localInfo.spawned.count)
    if count <= 0 then return end

    local matched = {}
    for playerId, data in pairs(structure) do
        if playerId == self.__playerId then
            goto continue
        end

        for _, path in pairs(data) do
            local actorData = dataStorage.loadRecordFromDeathMapByPath(path)
            if actorData and not localInfo.spawned[actorData.recordId] then
                table.insert(matched, actorData)
            end
        end

        ::continue::
    end

    while #matched > 0 and count > 0 do
        local actorPos = math.random(#matched)
        local actorData = matched[actorPos]
        npc.createDuplicate(actorData, params.actorParams)
        localInfo.spawned[actorData.recordId] = true
        localInfo.spawned.count = localInfo.spawned.count + 1
        count = count - 1
        table.remove(matched, actorPos)
    end
end

return this