local log = require("diject.just_an_incarnate.utils.log")

---@class fileSysLib
local this = {}

local function mkdir(path)
    local sep, pStr = package.config:sub(1, 1), ""
    for dir in path:gmatch("[^" .. sep .. "]+") do
        pStr = pStr .. dir .. sep
        lfs.mkdir(pStr)
    end
end

---@param fileExtension string|nil
---@return table<table<integer,string>>
function this:files(fileExtension)
    local out = {}
    for fileName in lfs.dir(self.__directory) do
        local path = self.__directory..fileName
        if lfs.attributes(path, "mode") == "file" and (not fileExtension or fileName:sub(-fileExtension:len()) == fileExtension) then
            table.insert(out, {fileName, path})
        end
    end
    return out
end

---@return table<table<integer,string>>
function this:directories()
    local out = {}
    for name in lfs.dir(self.__directory) do
        local path = self.__directory..name
        if lfs.attributes(path, "mode") == "directory" then
            table.insert(out, {name, path.."\\"})
        end
    end
    return out
end

---@param fileName string
---@param data table
function this:createTomlFile(fileName, data)
    toml.saveFile(self.__directory..fileName, data)
end

---@param directoryPath string
function this:new(directoryPath)
    mkdir(directoryPath)
    local out = {}
    setmetatable(out, self)
    self.__index = self
    self.__directory = directoryPath
    ---@type fileSysLib
    return out
end

return this