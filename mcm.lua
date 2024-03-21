local config = include("diject.just_an_incarnate.config")
local log = include("diject.just_an_incarnate.utils.log")
local EasyMCM = require("easyMCM.EasyMCM")
local mcm = mwse.mcm

local this = {}

---@type mwseMCMTemplate|nil
this.modData = nil

local function getSettingColor(isLocal)
    return isLocal and tes3ui.getPalette(tes3.palette.bigAnswerPressedColor) or tes3ui.getPalette("normal_color")
end


---@class jai.mcm.createLabel
---@field self mwseMCMExclusionsPage|mwseMCMFilterPage|mwseMCMMouseOverPage|mwseMCMPage|mwseMCMSideBarPage
---@field labelColor tes3.palette|string|nil
---@field textColor tes3.palette|string|nil

---@param params mwseMCMCategory.createInfo.data|jai.mcm.createLabel
---@return mwseMCMActiveInfo|mwseMCMHyperlink|mwseMCMInfo|mwseMCMMouseOverInfo
local function createLabel(params)
    local info = params.self:createInfo(params)
    info.postCreate = function(self)
        self.elements.label.color = params.labelColor and tes3ui.getPalette(params.labelColor) or self.elements.label.color
        self.elements.info.color = params.textColor and tes3ui.getPalette(params.textColor) or self.elements.info.color
        self:update()
    end
    return info
end


---@class jai.mcm.configPath
---@field path string table with the value
---@field name string the value

---@class jai.mcm.createYesNo
---@field self mwseMCMExclusionsPage|mwseMCMFilterPage|mwseMCMMouseOverPage|mwseMCMPage|mwseMCMSideBarPage
---@field variable mwseMCMCustomVariable|mwseMCMVariable|nil
---@field config jai.mcm.configPath

---@param params mwseMCMCategory.createYesNoButton.data|jai.mcm.createYesNo
---@return mwseMCMYesNoButton
local function createYesNo(params)
    ---@type mwseMCMYesNoButton
    local button
    ---@type mwse.mcm.createCustom.variable
    local variable = params.variable or {}
    variable.setter = function(self, newValue)
        local path = params.config.path.."."..params.config.name
        local configValue = config.getValueByPath(path)
        if configValue ~= newValue then
            if not config.setValueByPath(path, newValue) then
                log("config value is not set", params.config.path.."."..params.config.name)
            end
            button.elements.label.color = getSettingColor(tes3.player)
            button.elements.label:getTopLevelMenu():updateLayout()
        end
    end
    variable.getter = function(self)
        local path = params.config.path.."."..params.config.name
        local value = config.getValueByPath(path)
        if value == nil then log("config value not found", path) end
        return value or false
    end
    params.variable = mcm.createCustom(variable)
    button = params.self:createYesNoButton(params)
    button.postCreate = function(self)
        local _, isLocal = config.getValueByPath(params.config.path.."."..params.config.name)
        self.elements.label.color = getSettingColor(isLocal)
        self.elements.label:getTopLevelMenu():updateLayout()
    end
    return button
end

---@class jai.mcm.minMax
---@field min number|nil
---@field max number|nil

---@class jai.mcm.createNumberEdit
---@field self mwseMCMExclusionsPage|mwseMCMFilterPage|mwseMCMMouseOverPage|mwseMCMPage|mwseMCMSideBarPage
---@field variable mwseMCMCustomVariable|mwseMCMVariable|nil
---@field labelMaxWidth number|nil
---@field config jai.mcm.configPath
---@field limits jai.mcm.minMax|nil
---@field maxForLinkedGroup number|nil

---@param params mwseMCMCategory.createTextField.data|jai.mcm.createNumberEdit
---@return mwseMCMTextField
local function createNumberEdit(params)

    if not params.limits then params.limits = {min = -math.huge, max = math.huge} end

    ---@type mwseMCMTextField
    local field
    local label

    local function getConfigValue()
        local path = params.config.path.."."..params.config.name
        local value = config.getValueByPath(path)
        if value == nil then log("config value not found", path) end
        return value or 0
    end

    local function setValue(value)
        local val = tonumber(value)
        if not val then return end
        if params.limits.max and params.limits.max < val then val = params.limits.max end
        if params.limits.min and params.limits.min > val then val = params.limits.min end
        local path = params.config.path.."."..params.config.name
        local configValue = getConfigValue()
        if configValue ~= val then
            if not config.setValueByPath(path, val) then
                log("config value is not set", params.config.path.."."..params.config.name)
            end
            label.elements.label.color = getSettingColor(tes3.player)
            field.elements.inputField.text = tostring(val)

            if params.maxForLinkedGroup then
                local sum = 0
                for _, elem in pairs(field.customLinkedElements) do
                    if not elem then break end
                    local v = tonumber(elem.customGetValue()) or elem.customGetConfigValue()
                    if not v then break end
                    sum = sum + v
                end
                sum = sum + val - params.maxForLinkedGroup
                if sum > 0 then
                    for _, elem in pairs(field.customLinkedElements) do
                        local elemVal = tonumber(elem.customGetValue()) or elem.customGetConfigValue()
                        local v = math.min(elemVal, sum)
                        elem.customSetValue(elemVal - v)
                        sum = sum - v
                        if sum <= 0 then break end -- neat part
                    end
                end
            end

            label.elements.label:getTopLevelMenu():updateLayout()
        end
    end

    local function getElementValue()
        return field.elements.inputField.text
    end

    local block = params.self:createSideBySideBlock{
        indent = 0,
        childIndent = 0,
        childSpacing = 1,
        description = params.description,
        inGameOnly = params.inGameOnly,
        paddingBottom = 0,
        postCreate = function(self)
            self.elements.subcomponentsContainer.childAlignX = 0.5
            self.elements.subcomponentsContainer.childAlignY = 0.5
        end
    }

    label = block:createInfo{
        label = params.label,
        description = params.description,
        postCreate = function(self)
            self.elements.info.minWidth = 100
            self.elements.info.maxWidth = params.labelMaxWidth or 250
            self.elements.info.borderBottom = 0
            local _, isLocal = config.getValueByPath(params.config.path.."."..params.config.name)
            self.elements.label.color = getSettingColor(isLocal)
        end
    }

    ---@type mwse.mcm.createCustom.variable
    local variable = params.variable or {}
    variable.setter = function(self, newValue)
        setValue(newValue)
    end
    variable.getter = function(self)
        return getConfigValue()
    end
    params.variable = mcm.createCustom(variable)
    params.numbersOnly = true
    ---@param self mwseMCMTextField
    params.postCreate = function(self)
        -- self.elements.submitButton:destroy()
        self.elements.inputField.justifyText = "right"
        self.elements.inputField.borderRight = 5
        self.elements.border.minWidth = 100
        self.elements.border.maxWidth = 100
        self.elements.inputField:register("destroy", function()
            setValue(self.elements.inputField.text)
        end)
    end
    params.paddingBottom = 0
    params.label = nil

    field = block:createTextField(params)

    local buttonBlock = block:createSideBySideBlock{
        indent = 0,
        childIndent = 0,
        childSpacing = 0,
        description = params.description,
        inGameOnly = params.inGameOnly,
        paddingBottom = 0,
        postCreate = function(self)
            self.elements.subcomponentsContainer.flowDirection = tes3.flowDirection.topToBottom
        end
    }
    buttonBlock:createButton{
        buttonText = "+",
        paddingBottom = 0,
        childIndent = 0,
        childSpacing = 0,
        indent = 0,
        postCreate = function(self)
            self.elements.button.autoWidth = false
            self.elements.button.width = 24
            self.elements.outerContainer.borderAllSides = 0
            self.elements.outerContainer.maxHeight = 24
            self.elements.outerContainer.maxWidth = 24
        end,
        callback = function(self)
            setValue((tonumber(field.elements.inputField.text) or 0) + 1)
        end
    }
    buttonBlock:createButton{
        buttonText = "-",
        paddingBottom = 0,
        childIndent = 0,
        childSpacing = 0,
        indent = 0,
        postCreate = function(self)
            self.elements.button.autoWidth = false
            self.elements.button.width = 24
            self.elements.outerContainer.borderAllSides = 0
            self.elements.outerContainer.maxHeight = 24
            self.elements.outerContainer.maxWidth = 24
        end,
        callback = function(self)
            setValue((tonumber(field.elements.inputField.text) or 0) - 1)
        end
    }

    field.customSetValue = setValue ---@diagnostic disable-line: inject-field
    field.customGetValue = getElementValue ---@diagnostic disable-line: inject-field
    field.customGetConfigValue = getConfigValue ---@diagnostic disable-line: inject-field
    field.customLinkedElements = {} ---@diagnostic disable-line: inject-field

    return field
end

-- ##################################################

local function registerTemplate(self)
    local modData = {}

	--- @param container tes3uiElement
	modData.onCreate = function(container)
		self:create(container)
		modData.onClose = self.onClose
	end

	--- @param searchText string
	--- @return boolean
	modData.onSearch = function(searchText)
		return self:onSearchInternal(searchText)
	end

	mwse.registerModConfig(self.name, modData)
	mwse.log("%s mod config registered", self.name)
    return modData
end

---@param e tes3uiElement
local function onClose(e)
    config.save()
end

function this.registerModConfig()

    local template = mcm.createTemplate{name = "Just an Incarnate", onClose = onClose}
    local mainPage = template:createPage{label = "Main"}

    do
        local respawnPage = template:createPage{label = "Respawn"}
        createNumberEdit{self = respawnPage, config = {path = "revive", name = "delay"}, label = "Delay before respawn", limits = {min = 2, max = 10}}
        createNumberEdit{self = respawnPage, config = {path = "revive", name = "safeTime"}, label = "Safe time after respawn", limits = {min = 0, max = 10}}
        local interiorGroup = respawnPage:createCategory{label = "Respawn after death in an interior cell"}
        createYesNo{self = interiorGroup, config = {path = "revive.interior", name = "divineMarker"}, label = "On an imperial shrine"}
        createYesNo{self = interiorGroup, config = {path = "revive.interior", name = "templeMarker"}, label = "On an Almsivi shrine"}
        createYesNo{self = interiorGroup, config = {path = "revive.interior", name = "prisonMarker"}, label = "On a prison marker"}
        createYesNo{self = interiorGroup, config = {path = "revive.interior", name = "exteriorDoorMarker"}, label = "Near the door in a random exterior cell"}
        createYesNo{self = interiorGroup, config = {path = "revive.interior", name = "interiorDoorMarker"}, label = "Near a door in the current cell"}
        createYesNo{self = interiorGroup, config = {path = "revive.interior", name = "exitFromInterior"}, label = "Near the exit door leading to exterior cell from the current one"}
        createYesNo{self = interiorGroup, config = {path = "revive.interior", name = "recall"}, label = "On the recall mark"}
        local exteriorGroup = respawnPage:createCategory{label = "Respawn after death in an exterior cell"}
        createYesNo{self = exteriorGroup, config = {path = "revive.exterior", name = "divineMarker"}, label = "On an imperial shrine"}
        createYesNo{self = exteriorGroup, config = {path = "revive.exterior", name = "templeMarker"}, label = "On an Almsivi shrine"}
        createYesNo{self = exteriorGroup, config = {path = "revive.exterior", name = "prisonMarker"}, label = "On a prison marker"}
        createYesNo{self = exteriorGroup, config = {path = "revive.exterior", name = "exteriorDoorMarker"}, label = "Near the door in a random exterior cell"}
        createYesNo{self = exteriorGroup, config = {path = "revive.exterior", name = "recall"}, label = "On the recall mark"}
    end

    do
        local penaltyPage = template:createPage{label = "Penalties"}
        createLabel{self = penaltyPage, label = "Penalties applied to the player after death", labelColor = tes3.palette.headerColor}
        createYesNo{self = penaltyPage, config = {path = "decrease", name = "combine"}, label = "Can these penalties be combined in one death? Otherwise, only leveldown will apply if the conditions for this are met"}
        createLabel{self = penaltyPage, label = "Decrease the player's level and all gained attributes for that level", labelColor = tes3.palette.bigAnswerOverColor}
        createNumberEdit{self = penaltyPage, config = {path = "decrease.level", name = "count"}, label = "The value by which the player's level will be reduced", limits = {min = 0}}
        createNumberEdit{self = penaltyPage, config = {path = "decrease.level", name = "interval"}, label = "The interval in player deaths to apply this penalty", limits = {min = 1}}

        createLabel{self = penaltyPage, label = "Decrease player's last increased skills", labelColor = tes3.palette.bigAnswerOverColor}
        createNumberEdit{self = penaltyPage, config = {path = "decrease.skill", name = "count"}, label = "The number of skillups that will be reduced", limits = {min = 0}}
        createNumberEdit{self = penaltyPage, config = {path = "decrease.skill", name = "interval"}, label = "The interval in player deaths to apply this penalty", limits = {min = 1}}
        createYesNo{self = penaltyPage, config = {path = "decrease.skill.levelUp", name = "progress"}, label = "Remove progression in levelup for the removed skill"}
        createYesNo{self = penaltyPage, config = {path = "decrease.skill.levelUp", name = "attributes"}, label = "Remove progression in attribute levelup for the removed skill"}

        createLabel{self = penaltyPage, label = ""}
        createLabel{self = penaltyPage, label = "Change player parameters to random ones after death", labelColor = tes3.palette.bigAnswerOverColor}
        createYesNo{self = penaltyPage, config = {path = "change", name = "race"}, label = "Change race"}
        createYesNo{self = penaltyPage, config = {path = "change", name = "bodyParts"}, label = "Change head and hairs"}
        createYesNo{self = penaltyPage, config = {path = "change", name = "sex"}, label = "Change sex"}
        createYesNo{self = penaltyPage, config = {path = "change", name = "sign"}, label = "Change birthsign"}
        local classGroup = penaltyPage:createCategory{label = ""}
        createYesNo{self = penaltyPage, config = {path = "change.class", name = "enbled"}, label = "Change class"}
        local changeClassToPlCustom = createNumberEdit{self = classGroup, config = {path = "change.class", name = "chanceToPlayerCustom"}, label = "Chance in % to change player's class to the class from another player's character from another game session", limits = {min = 0, max = 100}, maxForLinkedGroup = 100}
        local changeClassToCustom = createNumberEdit{self = classGroup, config = {path = "change.class", name = "chanceToCustom"}, label = "Chance in % to change player's class to the class with random major/minor skills", limits = {min = 0, max = 100}, maxForLinkedGroup = 100}
        table.insert(changeClassToPlCustom.customLinkedElements, changeClassToCustom) ---@diagnostic disable-line: undefined-field
        table.insert(changeClassToCustom.customLinkedElements, changeClassToPlCustom) ---@diagnostic disable-line: undefined-field
        createLabel{self = classGroup, label = "Otherwise the class will be from default game classes"}
    end

    do
        local corpsePage = template:createPage{label = "Corpse"}
        createLabel{self = corpsePage, label = "The settings for courpses that stay after the player's death", labelColor = tes3.palette.headerColor}

        local bodyGroup = corpsePage:createCategory{label = "Copy of the player"}
        local spawnBody = createNumberEdit{self = bodyGroup, config = {path = "spawn.body", name = "chance"}, label = "Chance in % to create a copy of the player after death. If the copy is alive, it will be transparent", limits = {min = 0, max = 100}, maxForLinkedGroup = 100}
        createNumberEdit{self = bodyGroup, config = {path = "spawn.body", name = "chanceToCorpse"}, label = "Chance in % to kill the copy (it will spawn as a dead)", limits = {min = 0, max = 100}}
        createNumberEdit{self = bodyGroup, config = {path = "spawn.body.stats", name = "health"}, label = "Health multiplier (in %) for the copy", limits = {min = 0}}
        createNumberEdit{self = bodyGroup, config = {path = "spawn.body.stats", name = "fatigue"}, label = "Fatigue multiplier (in %) for the copy", limits = {min = 0}}
        createNumberEdit{self = bodyGroup, config = {path = "spawn.body.stats", name = "magicka"}, label = "Magicka multiplier (in %) for the copy", limits = {min = 0}}

        local creaGroup = corpsePage:createCategory{label = "Creature with the player's stats"}
        local spawnCrea = createNumberEdit{self = creaGroup, config = {path = "spawn.creature", name = "chance"}, label = "Chance in % to create a creature with the player's stats", limits = {min = 0, max = 100}, maxForLinkedGroup = 100}
        createNumberEdit{self = creaGroup, config = {path = "spawn.creature", name = "chanceToCorpse"}, label = "Chance in % to kill the creature (it will spawn as a dead)", limits = {min = 0, max = 100}}
        createNumberEdit{self = creaGroup, config = {path = "spawn.creature.stats", name = "health"}, label = "Health multiplier (in %) for the creature", limits = {min = 0}}
        createNumberEdit{self = creaGroup, config = {path = "spawn.creature.stats", name = "fatigue"}, label = "Fatigue multiplier (in %) for the creature", limits = {min = 0}}
        createNumberEdit{self = creaGroup, config = {path = "spawn.creature.stats", name = "magicka"}, label = "Magicka multiplier (in %) for the creature", limits = {min = 0}}
        table.insert(spawnBody.customLinkedElements, spawnCrea) ---@diagnostic disable-line: undefined-field
        table.insert(spawnCrea.customLinkedElements, spawnBody) ---@diagnostic disable-line: undefined-field

        local transferGroup = corpsePage:createCategory{label = "Transferring items from the player to the copy(creature)"}
        createLabel{self = transferGroup, label = "Most of the settings below are % of item stacks in your inventory. Each stack may contain several identical items"}
        createNumberEdit{self = transferGroup, config = {path = "spawn.transfer", name = "equipedItems"}, label = "Transfer this % of equipped items", limits = {min = 0, max = 100}}
        createNumberEdit{self = transferGroup, config = {path = "spawn.transfer", name = "equipment"}, label = "Transfer this % of items that you can equip but are currently unequipped", limits = {min = 0, max = 100}}
        createNumberEdit{self = transferGroup, config = {path = "spawn.transfer", name = "magicItems"}, label = "Transfer this % of items like scrolls or potions", limits = {min = 0, max = 100}}
        createNumberEdit{self = transferGroup, config = {path = "spawn.transfer", name = "misc"}, label = "Transfer this % of miscellaneous items", limits = {min = 0, max = 100}}
        createNumberEdit{self = transferGroup, config = {path = "spawn.transfer", name = "books"}, label = "Transfer this % of books", limits = {min = 0, max = 100}}
        createNumberEdit{self = transferGroup, config = {path = "spawn.transfer", name = "goldPercent"}, label = "Transfer this % of your gold", limits = {min = 0, max = 100}}
        createYesNo{self = transferGroup, config = {path = "spawn.transfer.replace", name = "enabled"}, label = "Give a chance to replace transferred equipped items by items from a random NPC"}
        createNumberEdit{self = transferGroup, config = {path = "spawn.transfer.replace", name = "regionSize"}, label = "The higher the value, the more varied the items will be selected", limits = {min = 5, max = 100}}
    end

    do
        local mapPage = template:createPage{label = "Map"}
        createLabel{self = mapPage, label = "The settings related to spawning characters from other playthroughs", labelColor = tes3.palette.headerColor}

        createNumberEdit{self = mapPage, config = {path = "map.spawn", name = "count"}, label = "Number of attempts to spawn a character per cell (0 - disabled)", limits = {min = 0}}
        createNumberEdit{self = mapPage, config = {path = "map.spawn", name = "chance"}, label = "Chance to spawn per each attempt", limits = {min = 0, max = 100}}
        createNumberEdit{self = mapPage, config = {path = "map.spawn", name = "interval"}, label = "Interval in game hours between attempts", limits = {min = 0}}
        createNumberEdit{self = mapPage, config = {path = "map.spawn", name = "maxCount"}, label = "Maximum number of spawned characters per cell", limits = {min = 0}}

        local itemGroup = mapPage:createCategory{label = "Inventory of the spawned characters"}
        createYesNo{self = itemGroup, config = {path = "map.spawn.items.change", name = "enbaled"}, label = "Recreate items in the inventory of a created character with unique ids. It will prevent quest abuse"}
        createNumberEdit{self = itemGroup, config = {path = "map.spawn.items.change", name = "multiplier"}, label = "Multiplier for stats for these recreated items", limits = {min = 0, max = 1}}
        createNumberEdit{self = itemGroup, config = {path = "map.spawn.items.change", name = "costMul"}, label = "Multiplier for the value of these recreated items", limits = {min = 0, max = 1}}

        local bodyGroup = mapPage:createCategory{label = "Copy of the character"}
        local spawnBody = createNumberEdit{self = bodyGroup, config = {path = "map.spawn.body", name = "chance"}, label = "Chance in % to create a copy of the player after death. If the copy is alive, it will be transparent", limits = {min = 0, max = 100}, maxForLinkedGroup = 100}
        createNumberEdit{self = bodyGroup, config = {path = "map.spawn.body", name = "chanceToCorpse"}, label = "Chance in % to kill the copy (it will spawn as a dead)", limits = {min = 0, max = 100}}
        createNumberEdit{self = bodyGroup, config = {path = "map.spawn.body.stats", name = "health"}, label = "Health multiplier (in %) for the copy", limits = {min = 0}}
        createNumberEdit{self = bodyGroup, config = {path = "map.spawn.body.stats", name = "fatigue"}, label = "Fatigue multiplier (in %) for the copy", limits = {min = 0}}
        createNumberEdit{self = bodyGroup, config = {path = "map.spawn.body.stats", name = "magicka"}, label = "Magicka multiplier (in %) for the copy", limits = {min = 0}}

        local creaGroup = mapPage:createCategory{label = "Creature with the player's stats"}
        local spawnCrea = createNumberEdit{self = creaGroup, config = {path = "map.spawn.creature", name = "chance"}, label = "Chance in % to create a creature with the player's stats", limits = {min = 0, max = 100}, maxForLinkedGroup = 100}
        createNumberEdit{self = creaGroup, config = {path = "map.spawn.creature", name = "chanceToCorpse"}, label = "Chance in % to kill the creature (it will spawn as a dead)", limits = {min = 0, max = 100}}
        createNumberEdit{self = creaGroup, config = {path = "map.spawn.creature.stats", name = "health"}, label = "Health multiplier (in %) for the creature", limits = {min = 0}}
        createNumberEdit{self = creaGroup, config = {path = "map.spawn.creature.stats", name = "fatigue"}, label = "Fatigue multiplier (in %) for the creature", limits = {min = 0}}
        createNumberEdit{self = creaGroup, config = {path = "map.spawn.creature.stats", name = "magicka"}, label = "Magicka multiplier (in %) for the creature", limits = {min = 0}}
        table.insert(spawnBody.customLinkedElements, spawnCrea) ---@diagnostic disable-line: undefined-field
        table.insert(spawnCrea.customLinkedElements, spawnBody) ---@diagnostic disable-line: undefined-field

        local transferGroup = mapPage:createCategory{label = "Transferring items from the player to the copy(creature)"}
        createLabel{self = transferGroup, label = "Most of the settings below are % of item stacks in your inventory. Each stack may contain several identical items"}
        createNumberEdit{self = transferGroup, config = {path = "map.spawn.transfer", name = "equipedItems"}, label = "Transfer this % of equipped items", limits = {min = 0, max = 100}}
        createNumberEdit{self = transferGroup, config = {path = "map.spawn.transfer", name = "equipment"}, label = "Transfer this % of items that you can equip but are currently unequipped", limits = {min = 0, max = 100}}
        createNumberEdit{self = transferGroup, config = {path = "map.spawn.transfer", name = "magicItems"}, label = "Transfer this % of items like scrolls or potions", limits = {min = 0, max = 100}}
        createNumberEdit{self = transferGroup, config = {path = "map.spawn.transfer", name = "misc"}, label = "Transfer this % of miscellaneous items", limits = {min = 0, max = 100}}
        createNumberEdit{self = transferGroup, config = {path = "map.spawn.transfer", name = "books"}, label = "Transfer this % of books", limits = {min = 0, max = 100}}
        createNumberEdit{self = transferGroup, config = {path = "map.spawn.transfer", name = "goldPercent"}, label = "Transfer this % of your gold", limits = {min = 0, max = 100}}
    end

    -- template:register()
    this.modData = registerTemplate(template)
end

event.register(tes3.event.modConfigReady, this.registerModConfig)

return this