repeat
    task.wait()
until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Env = type(getgenv) == "function" and getgenv() or _G

Env.SuitLogConfig = Env.SuitLogConfig or {
    UpdateDelay = 15,
    Debug = false,
}

local Config = Env.SuitLogConfig

local MoneyNames = {
    "Money",
    "Coins",
    "Coin",
    "Cash",
    "Gold",
    "Beli",
    "Yen",
    "Currency",
}

local LevelNames = {
    "Level",
    "Lv",
    "PlayerLevel",
    "BattlepassLevel",
}

local SuitNames = {
    "Suit",
    "CurrentSuit",
    "EquippedSuit",
    "SuitEquipped",
    "SelectedSuit",
    "Skin",
    "CurrentSkin",
    "Outfit",
    "Costume",
}

local CurrencyLookupPaths = {
    { "Script", "Bag", "Basic", "ItemInventoryConst" },
    { "Script", "Shop", "Cfg", "ShopCfg" },
}

local SuitFieldLabels = {
    equipmenttitle = "Title #",
    titleid = "Title #",
    equipmentslotid = "Slot #",
    playermodelsetid = "Model #",
    currentmodelsetid = "Model #",
    modelsetid = "Model #",
    suitid = "Suit #",
    skinid = "Skin #",
    outfitid = "Outfit #",
    costumeid = "Costume #",
}

local PlayerModelFieldNames = {
    "currentSuit",
    "equippedSuit",
    "selectedSuit",
    "suitName",
    "currentSkin",
    "skinName",
    "outfitName",
    "costumeName",
    "displayName",
    "name",
    "playerModelSetName",
    "modelSetName",
    "playerModelSetId",
    "currentModelSetId",
    "modelSetId",
    "suitId",
    "skinId",
    "outfitId",
    "costumeId",
}

local TitleFieldNames = {
    "titleName",
    "displayName",
    "name",
    "equipmentTitle",
    "titleId",
}

local ProfessionFieldNames = {
    "suitName",
    "displayName",
    "name",
    "equippedProfessionId",
    "professionId",
    "equipmentSlotId",
}

local function normalizeText(value)
    if value == nil then
        return nil
    end

    local text = tostring(value):gsub("\n", " "):gsub("%s+", " ")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
        return nil
    end

    return text
end

local function sanitize(value)
    return (normalizeText(value) or "N/A"):gsub("[|;]", " ")
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function hasWord(text, words)
    local value = lower(text)

    for _, word in next, words do
        if value:find(lower(word), 1, true) then
            return true
        end
    end

    return false
end

local function readValue(object)
    if not object then
        return nil
    end

    local ok, result = pcall(function()
        return object.Value
    end)

    if ok then
        return result
    end

    return nil
end

local function isValueObject(object)
    return object and object:IsA("ValueBase")
end

local function scanChildren(root, callback, limit)
    if not root then
        return nil
    end

    local scanned = 0
    limit = limit or 2500

    local function walk(parent)
        if scanned >= limit then
            return nil
        end

        for _, child in next, parent:GetChildren() do
            scanned += 1

            if callback(child) then
                return child
            end

            local found = walk(child)
            if found then
                return found
            end

            if scanned >= limit then
                return nil
            end
        end

        return nil
    end

    return walk(root)
end

local function getPath(object)
    local names = {}
    local current = object

    while current and current ~= game do
        names[#names + 1] = current.Name
        current = current.Parent
    end

    local path = "game"
    for index = #names, 1, -1 do
        path ..= "." .. names[index]
    end

    return path
end

local function getPlayerGui()
    return LocalPlayer:FindFirstChild("PlayerGui")
end

local function isGuiVisible(object)
    local playerGui = getPlayerGui()
    if not playerGui then
        return false
    end

    local current = object
    while current and current ~= playerGui do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end

        if current:IsA("ScreenGui") and not current.Enabled then
            return false
        end

        current = current.Parent
    end

    return true
end

local function isTextObject(object)
    return object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
end

local function parseNumber(value)
    if type(value) == "number" then
        return value
    end

    local text = normalizeText(value)
    if not text then
        return nil
    end

    text = text:gsub(",", "")
    local numberText, suffix = text:match("([%d%.]+)%s*([KkMmBbTt]?)")
    local number = tonumber(numberText)
    if not number then
        return nil
    end

    local multiplier = ({
        K = 1000,
        M = 1000000,
        B = 1000000000,
        T = 1000000000000,
    })[string.upper(suffix or "")] or 1

    return number * multiplier
end

local function trimTrailingZero(value)
    value = value:gsub("%.00$", "")
    value = value:gsub("(%..-)0$", "%1")
    return value
end

local function formatCompactNumber(value)
    if type(value) == "string" then
        return sanitize(value)
    end

    local number = tonumber(value)
    if not number then
        return "N/A"
    end

    local absNumber = math.abs(number)
    local suffixes = {
        { Value = 1000000000000, Suffix = "T" },
        { Value = 1000000000, Suffix = "B" },
        { Value = 1000000, Suffix = "M" },
        { Value = 1000, Suffix = "K" },
    }

    for _, item in next, suffixes do
        if absNumber >= item.Value then
            return trimTrailingZero(string.format("%.2f", number / item.Value)) .. " " .. item.Suffix
        end
    end

    if number % 1 == 0 then
        return tostring(number)
    end

    return trimTrailingZero(string.format("%.2f", number))
end

local function formatPlainNumber(value)
    if type(value) == "string" then
        return sanitize(value)
    end

    local number = tonumber(value)
    if not number then
        return "N/A"
    end

    if number % 1 == 0 then
        return tostring(number)
    end

    return trimTrailingZero(string.format("%.2f", number))
end

local function getDataRoots()
    local roots = {}
    local names = {
        "Data",
        "leaderstats",
        "Stats",
        "Values",
        "PlayerData",
        "dataInstanceList",
    }

    for _, name in next, names do
        local root = LocalPlayer:FindFirstChild(name)
        if root then
            roots[#roots + 1] = root
        end
    end

    return roots
end

local function readAttributeByNames(names)
    for _, name in next, names do
        local value = LocalPlayer:GetAttribute(name)
        if value ~= nil then
            return value
        end
    end

    for attributeName, value in next, LocalPlayer:GetAttributes() do
        for _, name in next, names do
            if lower(attributeName) == lower(name) then
                return value
            end
        end
    end

    return nil
end

local function readNamedValue(names)
    for _, root in next, getDataRoots() do
        local exact = scanChildren(root, function(object)
            if not isValueObject(object) then
                return false
            end

            for _, name in next, names do
                if lower(object.Name) == lower(name) then
                    return true
                end
            end

            return false
        end)

        if exact then
            local value = readValue(exact)
            if value ~= nil then
                return value
            end
        end
    end

    for _, root in next, getDataRoots() do
        local contains = scanChildren(root, function(object)
            return isValueObject(object) and hasWord(object.Name, names)
        end)

        if contains then
            local value = readValue(contains)
            if value ~= nil then
                return value
            end
        end
    end

    return nil
end

local function safeRequire(moduleScript)
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return nil
    end

    local ok, module = pcall(require, moduleScript)
    if ok then
        return module
    end

    return nil
end

local function findChildPath(root, names)
    local current = root

    for _, name in next, names do
        if not current then
            return nil
        end

        current = current:FindFirstChild(name)
    end

    return current
end

local function safeRequireByPath(root, names)
    return safeRequire(findChildPath(root, names))
end

local StorageModuleCache = {}
local RequiredModuleCache = {}
local ProfessionNameCache = {}

local function getStorageModule(name)
    if StorageModuleCache[name] ~= nil then
        return StorageModuleCache[name] or nil
    end

    local storage = ReplicatedStorage:FindFirstChild("Storage")
    local module = storage and safeRequire(storage:FindFirstChild(name))
    StorageModuleCache[name] = module or false

    return module
end

local function getRequiredModule(cacheKey, path)
    if RequiredModuleCache[cacheKey] ~= nil then
        return RequiredModuleCache[cacheKey] or nil
    end

    local module = safeRequireByPath(ReplicatedStorage, path)
    RequiredModuleCache[cacheKey] = module or false

    return module
end

local function getLastNonNil(...)
    for index = select("#", ...), 1, -1 do
        local value = select(index, ...)
        if value ~= nil then
            return value
        end
    end

    return nil
end

local function safeCall(callback)
    local ok, value1, value2, value3, value4 = pcall(callback)
    if not ok then
        return nil
    end

    if type(value1) == "boolean" and (value2 ~= nil or value3 ~= nil or value4 ~= nil) then
        if not value1 then
            return nil
        end

        return getLastNonNil(value2, value3, value4)
    end

    if type(value1) == "number" then
        if value2 == nil and value3 == nil and value4 == nil then
            return nil
        end

        return getLastNonNil(value2, value3, value4)
    end

    return getLastNonNil(value1, value2, value3, value4)
end

local function cacheProfessionName(professionId, value)
    local name = sanitize(value)
    if name == "N/A" then
        return nil
    end

    ProfessionNameCache[professionId] = name
    return name
end

local function getProfessionNameFromService(professionId)
    local service = getRequiredModule("ProfessionService", { "Script", "Profession", "ProfessionService" })
    if type(service) ~= "table" or type(service.getProfessionInfo) ~= "function" then
        return nil
    end

    local info = safeCall(function()
        return service.getProfessionInfo(professionId)
    end)

    if type(info) ~= "table" and type(service.refreshStaticCache) == "function" then
        safeCall(function()
            return service.refreshStaticCache()
        end)

        info = safeCall(function()
            return service.getProfessionInfo(professionId)
        end)
    end

    if type(info) == "table" then
        return cacheProfessionName(professionId, info.name)
    end

    return nil
end

local function getProfessionNameFromConfigManager(professionId)
    local dataManager = getRequiredModule("ConfigDataManager", { "Core", "Config", "ConfigDataManager" })
    local configConst = getRequiredModule("ConfigConst", { "Core", "Config", "ConfigConst" })
    local configName = type(configConst) == "table" and type(configConst.ConfigName) == "table" and configConst.ConfigName.ITEM or nil

    if type(dataManager) ~= "table" or type(dataManager.getConfig) ~= "function" or configName == nil then
        return nil
    end

    local itemConfig = safeCall(function()
        return dataManager.getConfig(configName, professionId)
    end)

    if type(itemConfig) == "table" then
        return cacheProfessionName(professionId, itemConfig.name)
    end

    return nil
end

local function getProfessionNameFromItemConfig(professionId)
    local itemConfig = getRequiredModule("ItemConfig", { "Config", "ItemConfig" })
    local itemData = type(itemConfig) == "table" and (itemConfig[professionId] or itemConfig[tostring(professionId)]) or nil

    if type(itemData) == "table" then
        return cacheProfessionName(professionId, itemData.name)
    end

    return nil
end

local function getProfessionDisplayName(professionId)
    professionId = tonumber(professionId)
    if not professionId then
        return nil
    end

    if ProfessionNameCache[professionId] then
        return ProfessionNameCache[professionId]
    end

    return getProfessionNameFromService(professionId)
        or getProfessionNameFromConfigManager(professionId)
        or getProfessionNameFromItemConfig(professionId)
end

local function buildCurrencyItemIdLookup()
    local itemIds = {
        [1000001] = true,
    }

    for _, path in next, CurrencyLookupPaths do
        local module = safeRequireByPath(ReplicatedStorage, path)
        local currencyItemId = type(module) == "table" and module.CurrencyItemId or nil
        if type(currencyItemId) == "table" then
            local goldId = tonumber(currencyItemId.Gold)
            local coinId = tonumber(currencyItemId.Coin)

            if goldId and goldId > 0 then
                itemIds[goldId] = true
            end

            if coinId and coinId > 0 then
                itemIds[coinId] = true
            end
        end
    end

    return itemIds
end

local CurrencyItemIdLookup = buildCurrencyItemIdLookup()

local function readAmountField(data)
    if type(data) ~= "table" then
        return nil
    end

    for _, key in next, { "num", "amount", "count", "value", "total", "quantity" } do
        local amount = tonumber(data[key])
        if amount ~= nil then
            return amount
        end
    end

    return nil
end

local function getItemIdFromData(data)
    if type(data) ~= "table" then
        return nil
    end

    return tonumber(data.id or data.itemId or data.cfgId or data.configId)
end

local function countCurrencyInContainer(container, itemIdLookup, depth, visited)
    if type(container) ~= "table" then
        return 0, false
    end

    depth = depth or 0
    if depth > 5 then
        return 0, false
    end

    visited = visited or {}
    if visited[container] then
        return 0, false
    end

    visited[container] = true

    local total = 0
    local found = false

    for key, value in next, container do
        local handled = false
        local keyId = tonumber(key)

        if keyId and itemIdLookup[keyId] then
            local directAmount = tonumber(value)
            if directAmount ~= nil then
                total += directAmount
                found = true
                handled = true
            elseif type(value) == "table" then
                directAmount = readAmountField(value)
                if directAmount ~= nil then
                    total += directAmount
                    found = true
                    handled = true
                end
            end
        end

        if not handled and type(value) == "table" then
            local itemData = type(value.item) == "table" and value.item or value
            local itemId = getItemIdFromData(itemData)

            if itemId and itemIdLookup[itemId] then
                local amount = readAmountField(itemData)
                if amount == nil then
                    amount = readAmountField(value)
                end

                if amount ~= nil then
                    total += amount
                    found = true
                    handled = true
                end
            end
        end

        if not handled and type(value) == "table" then
            local nestedAmount, nestedFound = countCurrencyInContainer(value, itemIdLookup, depth + 1, visited)
            total += nestedAmount
            found = found or nestedFound
        end
    end

    visited[container] = nil

    return total, found
end

local function findNamedNumberInTable(data, names, depth, visited)
    if type(data) ~= "table" then
        return nil
    end

    depth = depth or 0
    if depth > 4 then
        return nil
    end

    visited = visited or {}
    if visited[data] then
        return nil
    end

    visited[data] = true

    for key, value in next, data do
        if type(key) == "string" and hasWord(key, names) then
            local number = parseNumber(value)
            if number ~= nil then
                visited[data] = nil
                return number
            end
        end

        if type(value) == "table" then
            local nested = findNamedNumberInTable(value, names, depth + 1, visited)
            if nested ~= nil then
                visited[data] = nil
                return nested
            end
        end
    end

    visited[data] = nil

    return nil
end

local function findFieldValue(data, fieldNames, depth, visited)
    if type(data) ~= "table" then
        return nil
    end

    depth = depth or 0
    if depth > 5 then
        return nil
    end

    visited = visited or {}
    if visited[data] then
        return nil
    end

    visited[data] = true

    for _, fieldName in next, fieldNames do
        local value = data[fieldName]
        if value ~= nil then
            visited[data] = nil
            return value, fieldName
        end

        local normalizedFieldName = lower(fieldName)
        for key, childValue in next, data do
            if type(key) == "string" and lower(key) == normalizedFieldName then
                visited[data] = nil
                return childValue, key
            end
        end
    end

    for _, value in next, data do
        if type(value) == "table" then
            local nestedValue, nestedField = findFieldValue(value, fieldNames, depth + 1, visited)
            if nestedValue ~= nil then
                visited[data] = nil
                return nestedValue, nestedField
            end
        end
    end

    visited[data] = nil

    return nil
end

local function formatModuleSuitValue(value, fieldName)
    if type(value) == "table" then
        local nestedValue, nestedFieldName = findFieldValue(value, {
            "displayName",
            "titleName",
            "suitName",
            "skinName",
            "outfitName",
            "costumeName",
            "name",
            "equipmentTitle",
            "titleId",
            "equippedProfessionId",
            "professionId",
            "equipmentSlotId",
            "playerModelSetId",
            "currentModelSetId",
            "modelSetId",
            "suitId",
            "skinId",
            "outfitId",
            "costumeId",
        })

        if nestedValue ~= nil then
            return formatModuleSuitValue(nestedValue, nestedFieldName)
        end

        return nil
    end

    local number = tonumber(value)
    if number ~= nil then
        if number <= 0 then
            return "No Suit"
        end

        local normalizedFieldName = lower(fieldName)
        if normalizedFieldName == "professionid" or normalizedFieldName == "equippedprofessionid" then
            local professionName = getProfessionDisplayName(number)
            if professionName then
                return professionName
            end

            return "Unknown Profession"
        end

        local prefix = SuitFieldLabels[normalizedFieldName]
        if prefix then
            return prefix .. formatPlainNumber(number)
        end
    end

    local text = normalizeText(value)
    if not text then
        return nil
    end

    local textNumber = tonumber(text)
    if textNumber and textNumber <= 0 then
        return "No Suit"
    end

    return sanitize(text)
end

local function getFormattedSuitFromTable(data, fieldNames)
    local value, fieldName = findFieldValue(data, fieldNames)
    if value == nil then
        return nil
    end

    local formatted = formatModuleSuitValue(value, fieldName)
    if not formatted then
        return nil
    end

    return formatted, value
end

local function getBagDataFromStorage()
    local module = getStorageModule("BagStorage")
    if type(module) ~= "table" then
        return nil
    end

    if type(module.getBagData) == "function" then
        local bagData = safeCall(function()
            return module:getBagData()
        end)

        if type(bagData) == "table" then
            return bagData
        end
    end

    if type(module.bagData) == "table" then
        return module.bagData
    end

    return nil
end

local function getMoneyFromBagStorage()
    local bagData = getBagDataFromStorage()
    if type(bagData) ~= "table" then
        return nil
    end

    local bestAmount = 0
    local found = false

    for _, key in next, {
        "itemList",
        "grids",
        "currencyList",
        "currencyData",
        "currencyMap",
        "currencies",
        "items",
        "itemMap",
    } do
        local amount, hasCurrency = countCurrencyInContainer(bagData[key], CurrencyItemIdLookup)
        if hasCurrency then
            bestAmount = math.max(bestAmount, amount)
            found = true
        end
    end

    if not found then
        local fallbackAmount, hasCurrency = countCurrencyInContainer(bagData, CurrencyItemIdLookup)
        if hasCurrency then
            bestAmount = fallbackAmount
            found = true
        end
    end

    if not found then
        local namedAmount = findNamedNumberInTable(bagData, MoneyNames)
        if namedAmount ~= nil then
            return namedAmount
        end

        return nil
    end

    return bestAmount
end

local function getPlayerModelDataFromStorage()
    local module = getStorageModule("PlayerModelStorage")
    if type(module) ~= "table" then
        return nil
    end

    if type(module.getPlayerModelSetData) == "function" then
        for _, reader in next, {
            function()
                return module.getPlayerModelSetData(LocalPlayer)
            end,
        } do
            local data = safeCall(reader)
            if type(data) == "table" then
                return data
            end
        end
    end

    if type(module.playerModelSetData) == "table" then
        return module.playerModelSetData
    end

    return nil
end

local function getSuitFromPlayerModelStorage()
    local data = getPlayerModelDataFromStorage()
    if type(data) ~= "table" then
        return nil
    end

    return getFormattedSuitFromTable(data, PlayerModelFieldNames)
end

local function getSuitFromTitleStorage()
    local module = getStorageModule("TitleStorage")
    if type(module) ~= "table" then
        return nil
    end

    if type(module.getTitleInfo) == "function" then
        local titleInfo = safeCall(function()
            return module.getTitleInfo()
        end)

        if type(titleInfo) == "table" then
            local formatted, rawValue = getFormattedSuitFromTable(titleInfo, TitleFieldNames)
            if formatted then
                return formatted, rawValue
            end
        end
    end

    if type(module.getEquipmentTitle) == "function" then
        local equipmentTitle = safeCall(function()
            return module.getEquipmentTitle()
        end)

        local formatted = formatModuleSuitValue(equipmentTitle, "equipmentTitle")
        if formatted then
            return formatted, equipmentTitle
        end
    end

    if type(module.titleInfo) == "table" then
        return getFormattedSuitFromTable(module.titleInfo, TitleFieldNames)
    end

    return nil
end

local function getSuitFromProfessionData(professionData)
    if type(professionData) ~= "table" then
        return nil
    end

    local slotId = tonumber(professionData.equipmentSlotId)
    if professionData.isShowAppearance == false then
        return "No Suit", slotId
    end

    if slotId and slotId > 0 then
        local slotList = professionData.slotList
        local slotData = type(slotList) == "table" and (slotList[slotId] or slotList[tostring(slotId)]) or nil

        if type(slotData) == "table" then
            local professionId = slotData.professionId or slotData.equippedProfessionId or slotData.id
            if professionId ~= nil then
                local professionName = getProfessionDisplayName(professionId)
                if professionName then
                    return professionName, professionId
                end

                local formatted = formatModuleSuitValue(professionId, "professionId")
                if formatted then
                    return formatted, professionId
                end
            end

            return "No Suit", slotId
        end
    end

    return getFormattedSuitFromTable(professionData, ProfessionFieldNames)
end

local function getSuitFromProfessionStorage()
    local module = getStorageModule("ProfessionStorage")
    if type(module) ~= "table" then
        return nil
    end

    if type(module.getProfessionData) == "function" then
        local professionData = safeCall(function()
            return module.getProfessionData()
        end)

        if type(professionData) == "table" then
            local formatted, rawValue = getSuitFromProfessionData(professionData)
            if formatted then
                return formatted, rawValue
            end
        end
    end

    if type(module.professionData) == "table" then
        return getSuitFromProfessionData(module.professionData)
    end

    return nil
end

local function getLevelFromLvStorage()
    local module = getStorageModule("LvStorage")
    if type(module) ~= "table" then
        return nil
    end

    if type(module.getLv) == "function" then
        local level = safeCall(function()
            return module.getLv()
        end)

        if level ~= nil then
            return level
        end
    end

    if type(module.getLvInfo) == "function" then
        local lvInfo = safeCall(function()
            return module.getLvInfo()
        end)

        if type(lvInfo) == "table" then
            return lvInfo.lv or lvInfo.level or lvInfo.Level
        end
    end

    return nil
end

local function getGuiTexts()
    local playerGui = getPlayerGui()
    local texts = {}

    if not playerGui then
        return texts
    end

    scanChildren(playerGui, function(object)
        if not isTextObject(object) or not isGuiVisible(object) then
            return false
        end

        local text = normalizeText(object.Text)
        if not text then
            return false
        end

        local path = getPath(object)
        local pathLower = lower(path)

        if pathLower:find("uiprefabs", 1, true) or pathLower:find("prefabs", 1, true) then
            return false
        end

        texts[#texts + 1] = {
            Object = object,
            Text = text,
            Name = object.Name,
            Path = path,
            Lower = lower(object.Name .. " " .. path .. " " .. text),
        }

        return false
    end, 6000)

    return texts
end

local function getGuiPositionScore(object, kind)
    local okPosition, position = pcall(function()
        return object.AbsolutePosition
    end)

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)

    if not okPosition then
        return 0
    end

    if kind == "money" and position.X <= viewport.X * 0.45 and position.Y <= viewport.Y * 0.75 then
        return 2
    end

    if kind == "level" and position.X <= viewport.X * 0.35 and position.Y <= viewport.Y * 0.75 then
        return 1
    end

    return 0
end

local function findSuitFromGui()
    local texts = getGuiTexts()

    for _, item in next, texts do
        if lower(item.Text) == "no suit" then
            return "No Suit"
        end
    end

    local bestText = nil
    local bestScore = -math.huge

    for _, item in next, texts do
        if item.Lower:find("suit", 1, true) then
            local textLower = lower(item.Text)
            local score = 1

            if textLower:find("slot", 1, true) or textLower:find("spin", 1, true) then
                score -= 5
            end

            if textLower:find("chance", 1, true) or textLower:find("show appearance", 1, true) then
                score -= 5
            end

            if item.Text:find("%%") then
                score -= 5
            end

            if score > bestScore then
                bestText = item.Text
                bestScore = score
            end
        end
    end

    if bestScore > 0 then
        return bestText
    end

    return nil
end

local function findMoneyFromGui()
    local texts = getGuiTexts()
    local bestText = nil
    local bestScore = -math.huge

    for _, item in next, texts do
        local text = item.Text
        local textLower = lower(text)

        if parseNumber(text) and not textLower:find("/", 1, true) and not textLower:find("%%") then
            local score = 0

            if item.Lower:find("coin", 1, true) or item.Lower:find("money", 1, true) then
                score += 8
            end

            if item.Lower:find("cash", 1, true) or item.Lower:find("gold", 1, true) then
                score += 8
            end

            if item.Lower:find("currency", 1, true) then
                score += 5
            end

            if text:match("[%d%.]+%s*[KkMmBbTt]$") then
                score += 3
            end

            if item.Lower:find("spin", 1, true) or item.Lower:find("cost", 1, true) then
                score -= 5
            end

            score += getGuiPositionScore(item.Object, "money")

            if score > bestScore then
                bestScore = score
                bestText = text
            end
        end
    end

    if bestScore > 0 then
        return bestText
    end

    return nil
end

local function findLevelFromGui()
    local texts = getGuiTexts()
    local bestText = nil
    local bestScore = -math.huge

    for _, item in next, texts do
        local number = parseNumber(item.Text)
        if number then
            local score = 0

            if item.Lower:find("level", 1, true) or item.Lower:find("lv", 1, true) then
                score += 4
            end

            if item.Lower:find("player", 1, true) or item.Lower:find("profile", 1, true) then
                score += 4
            end

            if item.Lower:find("area", 1, true) or item.Lower:find("wild", 1, true) then
                score -= 8
            end

            if item.Lower:find("pet", 1, true) or item.Lower:find("enemy", 1, true) then
                score -= 8
            end

            if item.Lower:find("need", 1, true) or item.Lower:find("reward", 1, true) then
                score -= 5
            end

            if item.Text:match("^%d+$") and number >= 1 and number <= 999 then
                score += getGuiPositionScore(item.Object, "level")
            end

            if score > bestScore then
                bestScore = score
                bestText = item.Text
            end
        end
    end

    if bestScore > 0 then
        return bestText
    end

    return nil
end

local function formatSuit(value)
    local text = normalizeText(value)
    if not text then
        return nil
    end

    local number = tonumber(text)
    if number and number <= 0 then
        return "No Suit"
    end

    return sanitize(text)
end

local function getCurrentSuit()
    local fallbackSuit = nil
    local fallbackRaw = nil

    local function useSuit(displayValue, rawValue)
        if not displayValue then
            return nil
        end

        if displayValue == "No Suit" then
            if fallbackSuit == nil then
                fallbackSuit = displayValue
                fallbackRaw = rawValue
            end

            return nil
        end

        return displayValue, rawValue
    end

    local fromPlayerModel, fromPlayerModelRaw = useSuit(getSuitFromPlayerModelStorage())
    if fromPlayerModel then
        return fromPlayerModel, fromPlayerModelRaw
    end

    local fromProfession, fromProfessionRaw = useSuit(getSuitFromProfessionStorage())
    if fromProfession then
        return fromProfession, fromProfessionRaw
    end

    local fromTitle, fromTitleRaw = useSuit(getSuitFromTitleStorage())
    if fromTitle then
        return fromTitle, fromTitleRaw
    end

    local rawAttribute = readAttributeByNames(SuitNames)
    local fromAttribute, fromAttributeRaw = useSuit(formatSuit(rawAttribute), rawAttribute)
    if fromAttribute then
        return fromAttribute, fromAttributeRaw
    end

    local rawValue = readNamedValue(SuitNames)
    local fromValue, fromValueRaw = useSuit(formatSuit(rawValue), rawValue)
    if fromValue then
        return fromValue, fromValueRaw
    end

    local fromGui = findSuitFromGui()
    if fromGui then
        return sanitize(fromGui), fromGui
    end

    if fallbackSuit then
        return fallbackSuit, fallbackRaw
    end

    return "No Suit", nil
end

local function getMoney()
    local fromBagStorage = getMoneyFromBagStorage()
    if fromBagStorage ~= nil then
        return formatCompactNumber(fromBagStorage), fromBagStorage
    end

    local fromAttribute = readAttributeByNames(MoneyNames)
    if fromAttribute ~= nil then
        return formatCompactNumber(fromAttribute), fromAttribute
    end

    local fromValue = readNamedValue(MoneyNames)
    if fromValue ~= nil then
        return formatCompactNumber(fromValue), fromValue
    end

    local fromGui = findMoneyFromGui()
    if fromGui then
        return sanitize(fromGui), fromGui
    end

    return "N/A", nil
end

local function getLevel()
    local fromModule = getLevelFromLvStorage()
    if fromModule ~= nil then
        return formatPlainNumber(fromModule), fromModule
    end

    local fromAttribute = readAttributeByNames(LevelNames)
    if fromAttribute ~= nil then
        return formatPlainNumber(fromAttribute), fromAttribute
    end

    local fromValue = readNamedValue(LevelNames)
    if fromValue ~= nil then
        return formatPlainNumber(fromValue), fromValue
    end

    local fromGui = findLevelFromGui()
    if fromGui then
        return sanitize(fromGui), fromGui
    end

    return "N/A", nil
end

local function buildState()
    local suitDisplay, suitRaw = getCurrentSuit()
    local moneyDisplay, moneyRaw = getMoney()
    local levelDisplay, levelRaw = getLevel()

    return {
        Player = LocalPlayer.Name,
        UserId = LocalPlayer.UserId,
        PlaceId = game.PlaceId,
        JobId = game.JobId,
        Suit = suitDisplay,
        SuitRaw = suitRaw,
        Money = moneyDisplay,
        MoneyRaw = moneyRaw,
        MoneyNumber = parseNumber(moneyRaw or moneyDisplay),
        Level = levelDisplay,
        LevelRaw = levelRaw,
        LevelNumber = parseNumber(levelRaw or levelDisplay),
        UpdatedAt = os.time(),
    }
end

local function buildDescription(state)
    return ("🎰 Suit Log 👕 Suit: %s, 💰 Money: %s, ⭐ Level: %s"):format(
        sanitize(state.Suit),
        sanitize(state.Money),
        sanitize(state.Level)
    )
end

assert(
    countCurrencyInContainer({
        { id = 1000001, num = 5 },
        { item = { id = 1000001, num = 7 } },
    }, { [1000001] = true }) == 12,
    "Currency counter failed"
)

do
    local zeroAmount, zeroFound = countCurrencyInContainer({ [1000001] = 0 }, { [1000001] = true })
    assert(zeroFound and zeroAmount == 0, "Zero currency counter failed")
end

assert(not buildDescription({ Suit = "A|B", Money = "1;2", Level = 3 }):find("|", 1, true), "Description sanitizer failed")
assert(not buildDescription({ Suit = "A|B", Money = "1;2", Level = 3 }):find(";", 1, true), "Description sanitizer failed")

local function getHorstSetDescription()
    if type(_G.Horst_SetDescription) == "function" then
        return _G.Horst_SetDescription
    end

    if type(Env.Horst_SetDescription) == "function" then
        return Env.Horst_SetDescription
    end

    return nil
end

local function sendDescription()
    local state = buildState()
    local description = buildDescription(state)
    local encoded = HttpService:JSONEncode(state)
    local setDescription = getHorstSetDescription()

    if not setDescription then
        warn("[SuitLog] _G.Horst_SetDescription not found:", description)
        return false, state
    end

    local ok, err = pcall(setDescription, description, encoded)
    if not ok then
        warn("[SuitLog] Failed to send Horst description:", err)
        return false, state
    end

    if Config.Debug then
        print("[SuitLog]", description)
    end
    return true, state
end

task.spawn(function()
    while task.wait(tonumber(Config.UpdateDelay) or 15) do
        sendDescription()
    end
end)

sendDescription()
