repeat task.wait() until game:IsLoaded()

local ENV = (type(getgenv) == "function" and getgenv()) or _G
local GLOBAL_KEY = "DelexHub_CapybarasVSPlants"

if ENV[GLOBAL_KEY] and type(ENV[GLOBAL_KEY].Cleanup) == "function" then
    pcall(ENV[GLOBAL_KEY].Cleanup)
end

local Runtime = {
    Destroyed = false,
    Connections = {},
    Threads = {},
}

ENV[GLOBAL_KEY] = Runtime

function Runtime.Cleanup()
    Runtime.Destroyed = true

    if type(Runtime.LowCleanup) == "function" then
        pcall(Runtime.LowCleanup)
    end

    for _, connection in ipairs(Runtime.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    if type(table.clear) == "function" then
        table.clear(Runtime.Connections)
    else
        Runtime.Connections = {}
    end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui

pcall(function()
    CoreGui = game:GetService("CoreGui")
end)

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:FindFirstChild("Modules")

local Remote = {
    CollectionMachine = Remotes:WaitForChild("CollectionMachine"),
    BuyItem = Remotes:WaitForChild("BuyItem"),
    BuyMerchantItem = Remotes:FindFirstChild("BuyMerchantItem"),
    GiftItem = Remotes:FindFirstChild("GiftItem"),
    Sell = Remotes:FindFirstChild("Sell"),
    SummonBoss = Remotes:FindFirstChild("SummonBoss"),
    RequestPersonalStock = Remotes:FindFirstChild("RequestPersonalStock"),
    RequestMerchantStock = Remotes:FindFirstChild("RequestMerchantStock"),
    UpdatePersonalStock = Remotes:FindFirstChild("UpdatePersonalStock"),
    UpdateAllPersonalStock = Remotes:FindFirstChild("UpdateAllPersonalStock"),
    UpdateMerchantPersonalStock = Remotes:FindFirstChild("UpdateMerchantPersonalStock"),
    UpdateTravelingMerchantStock = Remotes:FindFirstChild("UpdateTravelingMerchantStock"),
    MerchantLeft = Remotes:FindFirstChild("MerchantLeft"),
    BossUpdate = Remotes:FindFirstChild("BossUpdate"),
}

local FALLBACK_EGG_ITEMS = {
    "Capybara Egg",
    "Alpha Capybara Egg",
    "Archer Capybara Egg",
    "Magic Capybara Egg",
    "Ghost Capybara Egg",
    "Golem Capybara Egg",
    "Robot Capybara Egg",
    "Disco Capybara Egg",
    "Angel Capybara Egg",
    "Dragon Capybara Egg",

}

local FALLBACK_GEAR_ITEMS = {
    "Hatch Hammer",
    "Nametag",
    "Mutation Sponge",
    "Boombox",
    "Bizarre Stopwatch",
    "Trading Ticket",

}

local FALLBACK_MERCHANT_CATEGORIES = {
    "King Capybara",
    "Timbles",
    "Martian",
    "Jester",
}

local FALLBACK_MERCHANT_ITEMS_BY_CATEGORY = {
    Martian = { "Raygun", "Alien Tesla", "Totem Of Stars" },
    Timbles = { "Totem Of Might", "Totem Of Marrow", "Rainbow Scroll" },
    ["King Capybara"] = { "Gilded Hatch Hammer", "Gold Scroll", "Totem Of Status" },
    Jester = { "Moonlit Scroll", "Chilly Scroll", "Toasty Scroll", "Tranquil Scroll", "Shocked Scroll", "Glitched Scroll" },
}

local BOSS_ITEMS = {
    "Scarlet Carrot",
    "Red Potato",
    "Dark Tomato",
    "Skull Flower",
    "Holy Grailic",
    "Carnivorous Jester",
    "Pumpkin Tyrant",
    "Golem King",
    "Conqueror Carrot"
}

local BOSS_DR_CARROT_ITEMS = {
    "Dr Carrot",
    "Dr Carbot MkI",
    "Dr Carbot MkII",
    "Dr Carbot MkIII"
}

local function cloneArray(source)
    local result = {}

    for index, value in ipairs(source) do
        result[index] = value
    end

    return result
end

local function getShopItems(shopName, fallback)
    if Modules then
        local shopDataModule = Modules:FindFirstChild("ShopData")

        if shopDataModule then
            local ok, shopData = pcall(require, shopDataModule)

            if ok and type(shopData) == "table" then
                local orders = shopData.ShopOrders

                if type(orders) == "table" and type(orders[shopName]) == "table" then
                    return cloneArray(orders[shopName])
                end
            end
        end
    end

    return cloneArray(fallback)
end

local function getMerchantCategories()
    if Modules then
        local shopDataModule = Modules:FindFirstChild("ShopData")

        if shopDataModule then
            local ok, shopData = pcall(require, shopDataModule)

            if ok and type(shopData) == "table" and type(shopData.TravelingMerchantPool) == "table" then
                return cloneArray(shopData.TravelingMerchantPool)
            end
        end
    end

    return cloneArray(FALLBACK_MERCHANT_CATEGORIES)
end

local function orderMerchantCategories(categories)
    local wantedOrder = {
        "King Capybara",
        "Timbles",
        "Martian",
        "Jester",
    }
    local lookup = {}
    local ordered = {}

    for _, merchantName in ipairs(categories) do
        lookup[merchantName] = true
    end

    for _, merchantName in ipairs(wantedOrder) do
        if lookup[merchantName] then
            table.insert(ordered, merchantName)
            lookup[merchantName] = nil
        end
    end

    for _, merchantName in ipairs(categories) do
        if lookup[merchantName] then
            table.insert(ordered, merchantName)
            lookup[merchantName] = nil
        end
    end

    return ordered
end

local EggItems = getShopItems("EggShop", FALLBACK_EGG_ITEMS)
local GearItems = getShopItems("GearShop", FALLBACK_GEAR_ITEMS)
local MerchantCategories = orderMerchantCategories(getMerchantCategories())
local MerchantItemsByCategory = {}
local MerchantItemToCategory = {}

for _, merchantName in ipairs(MerchantCategories) do
    local items = getShopItems(merchantName, FALLBACK_MERCHANT_ITEMS_BY_CATEGORY[merchantName] or {})
    MerchantItemsByCategory[merchantName] = items

    for _, itemName in ipairs(items) do
        MerchantItemToCategory[itemName] = merchantName
    end
end

local function buildDefaultSelectedEggs()
    local selected = {}

    for _, eggName in ipairs(EggItems) do
        selected[eggName] = false
    end

    return selected
end

local function buildDefaultSelectedGears()
    local selected = {}

    for _, gearName in ipairs(GearItems) do
        selected[gearName] = false
    end

    return selected
end

local function buildDefaultSelectedMerchantItems()
    local selected = {}

    for _, merchantName in ipairs(MerchantCategories) do
        selected[merchantName] = {}

        for _, itemName in ipairs(MerchantItemsByCategory[merchantName] or {}) do
            selected[merchantName][itemName] = false
        end
    end

    return selected
end

local function buildDefaultSelectedBosses()
    local selected = {}

    for _, bossName in ipairs(BOSS_ITEMS) do
        selected[bossName] = false
    end

    for _, bossName in ipairs(BOSS_DR_CARROT_ITEMS) do
        selected[bossName] = false
    end

    return selected
end

local DefaultConfig = {
    Main = {
        AutoCollectMoney = false,
        CollectDelay = 30,
    },
    Misc = {
        Low = false,
    },
    Shop = {
        AutoBuyEggs = false,
        AutoBuyGears = false,
        AutoBuyMerchant = false,
        BuyDelay = 2,
        SelectedEggs = buildDefaultSelectedEggs(),
        SelectedGears = buildDefaultSelectedGears(),
        SelectedMerchantItems = buildDefaultSelectedMerchantItems(),
    },
    Boss = {
        AutoSummon = false,
        SummonDelay = 5,
        SelectedBosses = buildDefaultSelectedBosses(),
        AutoSummonDrCarrot = false,
        SelectedDrCarrotBosses = buildDefaultSelectedBosses(),
    },
    Gift = {
        AutoAccept = false,
    },
    AutoSell = {
        Enabled = false,
        SelectedCapybaras = {},
        SelectedPlants = {},
    },
    Buttons = {
        CollectNow = {
            Cooldown = 0.75,
            Notify = true,
        },
    },
    Meta = {
        ConfigName = "Default",
    },
}

local Config = {}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local result = {}

    for key, child in pairs(value) do
        result[key] = deepCopy(child)
    end

    return result
end

local function mergeConfig(base, incoming)
    if type(incoming) ~= "table" then
        return base
    end

    for key, value in pairs(incoming) do
        if type(value) == "table" and type(base[key]) == "table" then
            mergeConfig(base[key], value)
        else
            base[key] = value
        end
    end

    return base
end

local function splitPath(path)
    local parts = {}

    for part in string.gmatch(path, "[^%.]+") do
        table.insert(parts, part)
    end

    return parts
end

local function getConfig(path, default)
    local current = Config

    for _, part in ipairs(splitPath(path)) do
        if type(current) ~= "table" then
            return default
        end

        current = current[part]
    end

    if current == nil then
        return default
    end

    return current
end

local function setConfig(path, value)
    local current = Config
    local parts = splitPath(path)

    for index = 1, #parts - 1 do
        local part = parts[index]

        if type(current[part]) ~= "table" then
            current[part] = {}
        end

        current = current[part]
    end

    current[parts[#parts]] = value
end

local CONFIG_ROOT = "Config"
local CONFIG_FOLDER = CONFIG_ROOT .. "/DelexHub"
local DEFAULT_CONFIG_FILE = CONFIG_FOLDER .. "/CapybarasVSPlants.json"

local function hasFileApi()
    return type(isfolder) == "function"
        and type(makefolder) == "function"
        and type(isfile) == "function"
        and type(writefile) == "function"
        and type(readfile) == "function"
end

local function ensureConfigFolder()
    if not hasFileApi() then
        return false
    end

    if not isfolder(CONFIG_ROOT) then
        makefolder(CONFIG_ROOT)
    end

    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end

    return true
end

local function sanitizeConfigName(name)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("[^%w%-%_ ]", "")

    if name == "" then
        return "Default"
    end

    return name
end

local function getConfigFilePath(name)
    return CONFIG_FOLDER .. "/" .. sanitizeConfigName(name) .. ".json"
end

local function saveConfig(name)
    if not ensureConfigFolder() then
        return false, "Executor does not support file config API."
    end

    local configName = sanitizeConfigName(name or getConfig("Meta.ConfigName", "Default"))
    setConfig("Meta.ConfigName", configName)

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(Config)
    end)

    if not ok then
        return false, encoded
    end

    local writeOk, writeErr = pcall(function()
        writefile(getConfigFilePath(configName), encoded)
        writefile(DEFAULT_CONFIG_FILE, encoded)
    end)

    if not writeOk then
        return false, writeErr
    end

    return true
end

local function loadConfig(name)
    Config = deepCopy(DefaultConfig)

    if not ensureConfigFolder() then
        return false, "Executor does not support file config API."
    end

    local configName = sanitizeConfigName(name or "Default")
    local path

    if name == nil and isfile(DEFAULT_CONFIG_FILE) then
        path = DEFAULT_CONFIG_FILE
    else
        path = getConfigFilePath(configName)

        if not isfile(path) and isfile(DEFAULT_CONFIG_FILE) then
            path = DEFAULT_CONFIG_FILE
        end
    end

    if not isfile(path) then
        setConfig("Meta.ConfigName", configName)
        return true
    end

    local readOk, body = pcall(readfile, path)

    if not readOk then
        return false, body
    end

    local decodeOk, decoded = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if not decodeOk then
        return false, decoded
    end

    mergeConfig(Config, decoded)

    if type(Config.Misc) ~= "table" then
        Config.Misc = {}
    end

    if type(decoded.Misc) ~= "table" or type(decoded.Misc.Low) ~= "boolean" then
        if type(decoded.Main) == "table" and type(decoded.Main.Low) == "boolean" then
            Config.Misc.Low = decoded.Main.Low
        elseif type(Config.Misc.Low) ~= "boolean" then
            Config.Misc.Low = false
        end
    end

    if type(Config.Main) == "table" then
        Config.Main.Low = nil
    end

    for _, eggName in ipairs(EggItems) do
        if Config.Shop.SelectedEggs[eggName] == nil then
            Config.Shop.SelectedEggs[eggName] = false
        end
    end

    for _, gearName in ipairs(GearItems) do
        if Config.Shop.SelectedGears[gearName] == nil then
            Config.Shop.SelectedGears[gearName] = false
        end
    end

    if type(Config.Shop.SelectedMerchantItems) ~= "table" then
        Config.Shop.SelectedMerchantItems = {}
    end

    for _, merchantName in ipairs(MerchantCategories) do
        if type(Config.Shop.SelectedMerchantItems[merchantName]) ~= "table" then
            Config.Shop.SelectedMerchantItems[merchantName] = {}
        end

        for _, itemName in ipairs(MerchantItemsByCategory[merchantName] or {}) do
            if Config.Shop.SelectedMerchantItems[merchantName][itemName] == nil then
                Config.Shop.SelectedMerchantItems[merchantName][itemName] = false
            end
        end
    end

    for _, bossName in ipairs(BOSS_ITEMS) do
        if Config.Boss.SelectedBosses[bossName] == nil then
            Config.Boss.SelectedBosses[bossName] = false
        end
    end

    for _, bossName in ipairs(BOSS_DR_CARROT_ITEMS) do
        if Config.Boss.SelectedBosses[bossName] == nil then
            Config.Boss.SelectedBosses[bossName] = false
        end
        if type(Config.Boss.SelectedDrCarrotBosses) == "table" and Config.Boss.SelectedDrCarrotBosses[bossName] == nil then
            Config.Boss.SelectedDrCarrotBosses[bossName] = false
        end
    end

    if type(Config.Boss.SelectedDrCarrotBosses) ~= "table" then
        Config.Boss.SelectedDrCarrotBosses = {}
        for _, bossName in ipairs(BOSS_DR_CARROT_ITEMS) do
            Config.Boss.SelectedDrCarrotBosses[bossName] = false
        end
    end

    if type(Config.Boss.AutoSummonDrCarrot) ~= "boolean" then
        Config.Boss.AutoSummonDrCarrot = false
    end

    if type(Config.AutoSell) ~= "table" then
        Config.AutoSell = {}
    end

    if type(Config.AutoSell.Enabled) ~= "boolean" then
        Config.AutoSell.Enabled = false
    end

    if type(Config.AutoSell.SelectedCapybaras) ~= "table" then
        Config.AutoSell.SelectedCapybaras = {}
    end

    if type(Config.AutoSell.SelectedPlants) ~= "table" then
        Config.AutoSell.SelectedPlants = {}
    end

    return true
end

local AutoLoadedConfigOk, AutoLoadedConfigMessage = loadConfig()

local function autoSaveConfig()
    task.defer(function()
        saveConfig(getConfig("Meta.ConfigName", "Default"))
    end)
end

local function cleanupOldToggleGuis()
    local guiNames = {
        DelexToggle = true,
        ChickChickToggle = true,
    }

    local parents = {}

    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)

        if ok and hui then
            table.insert(parents, hui)
        end
    end

    if CoreGui then
        table.insert(parents, CoreGui)
    end

    if LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") then
        table.insert(parents, LocalPlayer:FindFirstChildOfClass("PlayerGui"))
    end

    for _, parent in ipairs(parents) do
        pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                if guiNames[child.Name] then
                    child:Destroy()
                end
            end
        end)
    end
end

cleanupOldToggleGuis()

local notify, enableLow, disableLow

local UIOptions = {
    Author = "Capybaras VS Plants",
    Theme = "Sky",
    Tag = {
        Title = "Momo Mi",
        Icon = "star",
        Color = Color3.fromRGB(160, 196, 255),
    },
    Low = {
        Value = getConfig("Misc.Low", false),
        Callback = function(enabled)
            setConfig("Misc.Low", enabled == true)
            autoSaveConfig()

            if enabled then
                if type(enableLow) == "function" then
                    enableLow()
                end
            else
                if type(disableLow) == "function" then
                    disableLow()
                end
            end

            if notify then
                notify("Low", enabled and "Low mode enabled." or "Low mode disabled.", enabled and "check-circle" or "x-circle", 2)
            end
        end,
    },
}

local function loadDelexWindow()
    local uiUrls = {
        "http://mxzy.longong.xyz/uilua.lua",
    }

    local lastError

    for _, url in ipairs(uiUrls) do
        local okSource, source = pcall(function()
            return game:HttpGet(url)
        end)

        if okSource and type(source) == "string" and source ~= "" then
            source = source:gsub("^\239\187\191", "")
            local chunk, loadErr = loadstring(source)

            if chunk then
                local okWindow, window = pcall(chunk, UIOptions)

                if okWindow and window then
                    return window
                end

                lastError = window
            else
                lastError = loadErr
            end
        else
            lastError = source
        end
    end

    error("Failed to load Delex UI: " .. tostring(lastError))
end

local Window = loadDelexWindow()
local WindUI = Window.WindUI

function notify(title, content, icon, duration)
    if WindUI and type(WindUI.Notify) == "function" then
        pcall(function()
            WindUI:Notify({
                Title = title or "Delex Hub",
                Content = content or "",
                Icon = icon or "info",
                Duration = duration or 3,
            })
        end)
    end
end

local function connect(signal, callback)
    if signal then
        local ok, connection = pcall(function()
            return signal:Connect(callback)
        end)

        if ok and connection then
            table.insert(Runtime.Connections, connection)
        end
    end
end

local function waitWithStop(seconds)
    local finishAt = os.clock() + seconds

    repeat
        if Runtime.Destroyed then
            return false
        end

        task.wait(math.min(0.25, math.max(0.01, finishAt - os.clock())))
    until os.clock() >= finishAt

    return true
end

local ButtonLastRun = {}

local function runButton(buttonKey, callback)
    local buttonConfig = getConfig("Buttons." .. buttonKey, {})
    local cooldown = tonumber(buttonConfig.Cooldown) or 0.5
    local now = os.clock()

    if ButtonLastRun[buttonKey] and now - ButtonLastRun[buttonKey] < cooldown then
        return
    end

    ButtonLastRun[buttonKey] = now

    local ok, err = pcall(callback)

    if not ok then
        notify("Delex Hub", tostring(err), "x-circle", 4)
    end
end

local function collectAllMoney()
    local ok, err = pcall(function()
        Remote.CollectionMachine:FireServer()
    end)

    if not ok then
        notify("Collect All Money", tostring(err), "x-circle", 4)
        return false
    end

    return true
end

local StockCache = {}
local MerchantStockCache = {}
local ItemCostCache = {}
local LastBuyAt = {}
local LastMerchantBuyAt = {}
local CurrentMerchantName

local EggData
local GearData
local TotemData
local BossData

if Modules and Modules:FindFirstChild("EggData") then
    local ok, result = pcall(require, Modules.EggData)

    if ok and type(result) == "table" then
        EggData = result
    end
end

if Modules and Modules:FindFirstChild("GearData") then
    local ok, result = pcall(require, Modules.GearData)

    if ok and type(result) == "table" then
        GearData = result
    end
end

if Modules and Modules:FindFirstChild("TotemData") then
    local ok, result = pcall(require, Modules.TotemData)

    if ok and type(result) == "table" then
        TotemData = result
    end
end

if Modules and Modules:FindFirstChild("BossData") then
    local ok, result = pcall(require, Modules.BossData)

    if ok and type(result) == "table" then
        BossData = result
    end
end

local function isEggItem(itemName)
    for _, eggName in ipairs(EggItems) do
        if eggName == itemName then
            return true
        end
    end

    return false
end

local function isGearItem(itemName)
    for _, gearName in ipairs(GearItems) do
        if gearName == itemName then
            return true
        end
    end

    return false
end

local function isMerchantCategory(merchantName)
    return MerchantItemsByCategory[merchantName] ~= nil
end

local function isMerchantItem(itemName)
    return MerchantItemToCategory[itemName] ~= nil
end

local function getItemData(itemName)
    local function readFrom(dataSource)
        if dataSource and type(dataSource.getData) == "function" then
            local ok, itemFolder = pcall(function()
                return dataSource.getData(itemName)
            end)

            if ok and itemFolder then
                return itemFolder
            end
        end
    end

    return readFrom(EggData) or readFrom(GearData) or readFrom(TotemData)
end

local function getMerchantItems(merchantName)
    return MerchantItemsByCategory[merchantName] or {}
end

local function isMerchantItemInCategory(merchantName, itemName)
    for _, merchantItemName in ipairs(getMerchantItems(merchantName)) do
        if merchantItemName == itemName then
            return true
        end
    end

    return false
end

local function clearMerchantStockCache()
    if type(table.clear) == "function" then
        table.clear(MerchantStockCache)
    else
        MerchantStockCache = {}
    end
end

local function updateMerchantStockCache(merchantName, allStock, usedStock)
    CurrentMerchantName = isMerchantCategory(merchantName) and merchantName or nil
    clearMerchantStockCache()

    if not CurrentMerchantName or type(allStock) ~= "table" then
        return
    end

    if type(usedStock) ~= "table" then
        usedStock = {}
    end

    for _, itemName in ipairs(getMerchantItems(CurrentMerchantName)) do
        MerchantStockCache[itemName] = math.max(0, tonumber(allStock[itemName] or 0) - tonumber(usedStock[itemName] or 0))
    end
end

local function refreshMerchantStock()
    if not Remote.RequestMerchantStock then
        return false, "RequestMerchantStock remote not found."
    end

    local ok, merchantName, allStock, usedStock = pcall(function()
        return Remote.RequestMerchantStock:InvokeServer()
    end)

    if not ok then
        return false, merchantName
    end

    updateMerchantStockCache(merchantName, allStock, usedStock)

    return CurrentMerchantName ~= nil
end

local function getMerchantItemConfigPath(merchantName, itemName)
    return "Shop.SelectedMerchantItems." .. merchantName .. "." .. itemName
end

local function isMerchantItemSelected(merchantName, itemName)
    return getConfig(getMerchantItemConfigPath(merchantName, itemName), false) == true
end

local function setMerchantItemSelected(merchantName, itemName, selected)
    setConfig(getMerchantItemConfigPath(merchantName, itemName), selected == true)
end

local function getSelectedMerchantValues(merchantName)
    local selected = {}

    for _, itemName in ipairs(getMerchantItems(merchantName)) do
        if isMerchantItemSelected(merchantName, itemName) then
            table.insert(selected, itemName)
        end
    end

    return selected
end

local function setSelectedMerchantItemsFromDropdown(merchantName, values)
    local selectedLookup = {}

    if type(values) == "table" then
        for key, value in pairs(values) do
            if isMerchantItemInCategory(merchantName, value) then
                selectedLookup[value] = true
            elseif value == true and isMerchantItemInCategory(merchantName, key) then
                selectedLookup[key] = true
            end
        end
    elseif isMerchantItemInCategory(merchantName, values) then
        selectedLookup[values] = true
    end

    for _, itemName in ipairs(getMerchantItems(merchantName)) do
        setMerchantItemSelected(merchantName, itemName, selectedLookup[itemName] == true)
    end

    autoSaveConfig()

    return #getSelectedMerchantValues(merchantName)
end

local function getItemCost(itemName)
    if ItemCostCache[itemName] ~= nil then
        return ItemCostCache[itemName]
    end

    local cost
    local itemFolder = getItemData(itemName)

    if itemFolder then
        local costValue = itemFolder:FindFirstChild("Cost")

        if costValue then
            cost = tonumber(costValue.Value)
        end
    end

    ItemCostCache[itemName] = cost or false
    return ItemCostCache[itemName]
end

local function canAfford(itemName)
    local cost = getItemCost(itemName)

    if not cost then
        return true
    end

    local leaderstats = LocalPlayer and LocalPlayer:FindFirstChild("leaderstats")
    local money = leaderstats and leaderstats:FindFirstChild("Money")

    if not money then
        return true
    end

    return tonumber(money.Value) >= cost
end

local EMPTY_PLAYER_VALUE = "No players"
local EMPTY_CAPYBARA_VALUE = "No capybaras"
local EMPTY_PLANT_VALUE = "No plants"
local PLACEHOLDER_VALUES = {
    [EMPTY_PLAYER_VALUE] = true,
    [EMPTY_CAPYBARA_VALUE] = true,
    [EMPTY_PLANT_VALUE] = true,
}

local GiftState = {
    TargetPlayerName = nil,
    Amount = 0,
    AutoGift = false,
    Running = false,
    SelectedCapybaras = {},
    SelectedPlants = {},
}

local AutoSellRunning = false
local PlayerDropdownReady = false
local SuppressGiftPlayerDropdownNotify = false
local InventoryDropdownsReady = false
local InventoryRefreshQueued = false

local GiftPlayerDropdown
local GiftCapybarasDropdown
local GiftPlantsDropdown
local SellCapybarasDropdown
local SellPlantsDropdown

local function clearTable(target)
    for key in pairs(target) do
        target[key] = nil
    end
end

local function trimText(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function parsePositiveInteger(value)
    local number = tonumber(trimText(value))

    if not number or number <= 0 then
        return 0
    end

    return math.floor(number)
end

local function getBackpack()
    return LocalPlayer and LocalPlayer:FindFirstChild("Backpack")
end

local function getCharacter()
    return LocalPlayer and LocalPlayer.Character
end

local function getToolBaseName(tool)
    local trueName = tool and tool:GetAttribute("trueName")

    if type(trueName) == "string" and trueName ~= "" then
        return trimText(trueName)
    end

    local name = trimText(tool and tool.Name or "")
    name = name:gsub("%b[]%s*", "")
    name = trimText(name)
    name = name:match("^[^:]+") or name

    return trimText(name)
end

local function collectInventoryTools(attributeName, selectedLookup, skipFavorited)
    local tools = {}

    local function addFrom(container)
        if not container then
            return
        end

        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Tool") and child:GetAttribute(attributeName) == true then
                local baseName = getToolBaseName(child)

                if baseName ~= "" and (not selectedLookup or selectedLookup[baseName] == true) then
                    if not skipFavorited or child:GetAttribute("Favorited") ~= true then
                        table.insert(tools, child)
                    end
                end
            end
        end
    end

    addFrom(getBackpack())
    addFrom(getCharacter())

    return tools
end

local function getInventoryNameValues(attributeName, emptyValue)
    local seen = {}
    local values = {}

    for _, tool in ipairs(collectInventoryTools(attributeName)) do
        local baseName = getToolBaseName(tool)

        if baseName ~= "" and not seen[baseName] then
            seen[baseName] = true
            table.insert(values, baseName)
        end
    end

    table.sort(values)

    if #values == 0 then
        return { emptyValue }
    end

    return values
end

local function getCapybaraInventoryValues()
    return getInventoryNameValues("isTower", EMPTY_CAPYBARA_VALUE)
end

local function getPlantInventoryValues()
    return getInventoryNameValues("isPlant", EMPTY_PLANT_VALUE)
end

local function valuesToAllowedLookup(values)
    local lookup = {}

    for _, value in ipairs(values) do
        if not PLACEHOLDER_VALUES[value] then
            lookup[value] = true
        end
    end

    return lookup
end

local function getLookupSelectionValues(selectionLookup, allowedValues)
    local values = {}
    local allowedLookup = valuesToAllowedLookup(allowedValues)

    for _, value in ipairs(allowedValues) do
        if allowedLookup[value] and selectionLookup[value] == true then
            table.insert(values, value)
        end
    end

    return values
end

local function setLookupSelectionFromDropdown(selectionLookup, values, allowedValues)
    local allowedLookup = valuesToAllowedLookup(allowedValues)
    local count = 0

    clearTable(selectionLookup)

    local function trySelect(value)
        if allowedLookup[value] and not selectionLookup[value] then
            selectionLookup[value] = true
            count += 1
        end
    end

    if type(values) == "table" then
        for key, value in pairs(values) do
            if allowedLookup[value] then
                trySelect(value)
            elseif value == true and allowedLookup[key] then
                trySelect(key)
            end
        end
    else
        trySelect(values)
    end

    return count
end

local function getConfigSelectionValues(path, allowedValues)
    local selection = getConfig(path, {})

    if type(selection) ~= "table" then
        return {}
    end

    return getLookupSelectionValues(selection, allowedValues)
end

local function setConfigSelectionFromDropdown(path, values, allowedValues)
    local selection = {}
    local count = setLookupSelectionFromDropdown(selection, values, allowedValues)

    setConfig(path, selection)
    autoSaveConfig()

    return count
end

local function getGiftPlayerValues()
    local values = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(values, player.Name)
        end
    end

    table.sort(values)

    if #values == 0 then
        return { EMPTY_PLAYER_VALUE }
    end

    return values
end

local function getFirstGiftPlayerName()
    for _, playerName in ipairs(getGiftPlayerValues()) do
        if playerName ~= EMPTY_PLAYER_VALUE then
            return playerName
        end
    end

    return nil
end

local function getSelectedGiftPlayer()
    if GiftState.TargetPlayerName then
        local player = Players:FindFirstChild(GiftState.TargetPlayerName)

        if player and player ~= LocalPlayer then
            return player
        end
    end

    return nil
end

local function safeRefreshDropdown(dropdown, values)
    if dropdown and type(dropdown.Refresh) == "function" then
        pcall(function()
            dropdown:Refresh(values, true)
        end)
    end
end

local function refreshGiftPlayerDropdown()
    if not getSelectedGiftPlayer() then
        GiftState.TargetPlayerName = getFirstGiftPlayerName()
    end

    PlayerDropdownReady = true
    SuppressGiftPlayerDropdownNotify = true
    safeRefreshDropdown(GiftPlayerDropdown, getGiftPlayerValues())
    SuppressGiftPlayerDropdownNotify = false
end

local function refreshInventoryDropdowns()
    InventoryDropdownsReady = false

    local capybaraValues = getCapybaraInventoryValues()
    local plantValues = getPlantInventoryValues()

    safeRefreshDropdown(GiftCapybarasDropdown, capybaraValues)
    safeRefreshDropdown(GiftPlantsDropdown, plantValues)
    safeRefreshDropdown(SellCapybarasDropdown, capybaraValues)
    safeRefreshDropdown(SellPlantsDropdown, plantValues)

    task.defer(function()
        InventoryDropdownsReady = true
    end)
end

local function queueInventoryDropdownRefresh(force)
    if (GiftState.Running or AutoSellRunning) and not force then
        InventoryRefreshQueued = true
        return
    end

    if InventoryRefreshQueued and not force then
        return
    end

    InventoryRefreshQueued = true

    task.delay(force and 0.05 or 0.35, function()
        if Runtime.Destroyed then
            return
        end

        if (GiftState.Running or AutoSellRunning) and not force then
            return
        end

        InventoryRefreshQueued = false
        refreshInventoryDropdowns()
    end)
end

local function watchToolContainer(container)
    if not container then
        return
    end

    connect(container.ChildAdded, function(child)
        if child:IsA("Tool") then
            queueInventoryDropdownRefresh()
        end
    end)

    connect(container.ChildRemoved, function(child)
        if child:IsA("Tool") then
            queueInventoryDropdownRefresh()
        end
    end)
end

local function equipTool(tool)
    if Runtime.Destroyed or not tool or not tool.Parent or not tool:IsA("Tool") then
        return false
    end

    local character = getCharacter() or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character and (character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5))

    if not character or not humanoid then
        return false
    end

    if tool.Parent ~= character then
        pcall(function()
            humanoid:UnequipTools()
        end)

        task.wait(0.05)

        local ok = pcall(function()
            humanoid:EquipTool(tool)
        end)

        if not ok then
            return false
        end
    end

    local timeoutAt = os.clock() + 1.5

    repeat
        if Runtime.Destroyed or not tool.Parent then
            return false
        end

        if tool.Parent == character then
            return true
        end

        task.wait(0.05)
    until os.clock() >= timeoutAt

    return tool.Parent == character
end

local function getGiftPromptForPlayer(player)
    local character = player and player.Character

    if not character then
        return nil
    end

    local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 3)

    if not root then
        return nil
    end

    return root:FindFirstChild("GiftPrompt") or root:WaitForChild("GiftPrompt", 3)
end

local function giftEquippedToolToPlayer(player)
    if not player or player == LocalPlayer then
        return false
    end

    local prompt = getGiftPromptForPlayer(player)

    if prompt then
        pcall(function()
            prompt.Enabled = true
        end)

        if type(fireproximityprompt) == "function" then
            local ok = pcall(function()
                fireproximityprompt(prompt)
            end)

            if ok then
                return true
            end
        end
    end

    if not Remote.GiftItem then
        return false
    end

    local ok = pcall(function()
        Remote.GiftItem:FireServer(player)
    end)

    return ok
end

local function collectSelectedGiftTools()
    local tools = {}

    for _, tool in ipairs(collectInventoryTools("isTower", GiftState.SelectedCapybaras)) do
        table.insert(tools, tool)
    end

    for _, tool in ipairs(collectInventoryTools("isPlant", GiftState.SelectedPlants)) do
        table.insert(tools, tool)
    end

    return tools
end

local function runAutoGift(showWarnings)
    if GiftState.Running then
        if showWarnings then
            notify("Gift", "Auto gift is already running.", "alert-circle", 2)
        end

        return
    end

    local targetPlayer = getSelectedGiftPlayer()

    if not targetPlayer then
        if showWarnings then
            notify("Gift", "Select a player first.", "alert-circle", 3)
        end

        return
    end

    local tools = collectSelectedGiftTools()

    if #tools == 0 then
        if showWarnings then
            notify("Gift", "Select capybaras or plants from Backpack first.", "alert-circle", 3)
        end

        return
    end

    GiftState.Running = true

    local gifted = 0
    local limit = tonumber(GiftState.Amount) or 0

    for _, tool in ipairs(tools) do
        if Runtime.Destroyed or not GiftState.AutoGift or not GiftState.Running then
            break
        end

        if limit > 0 and gifted >= limit then
            break
        end

        if not targetPlayer.Parent then
            break
        end

        if tool.Parent and equipTool(tool) and giftEquippedToolToPlayer(targetPlayer) then
            gifted += 1
            task.wait(0.75)
        end
    end

    GiftState.Running = false

    if gifted > 0 or InventoryRefreshQueued then
        queueInventoryDropdownRefresh(true)
    end

    if gifted > 0 and showWarnings then
        notify("Gift", "Auto gift finished: " .. tostring(gifted), "check-circle", 3)
    end

    return gifted > 0
end

local function sellEquippedItem()
    if not Remote.Sell then
        return false
    end

    local ok = pcall(function()
        Remote.Sell:FireServer("equippedItem")
    end)

    return ok
end

local function getSelectedAutoSellTools()
    local tools = {}
    local selectedCapybaras = getConfig("AutoSell.SelectedCapybaras", {})
    local selectedPlants = getConfig("AutoSell.SelectedPlants", {})

    if type(selectedCapybaras) ~= "table" then
        selectedCapybaras = {}
    end

    if type(selectedPlants) ~= "table" then
        selectedPlants = {}
    end

    for _, tool in ipairs(collectInventoryTools("isTower", selectedCapybaras, true)) do
        table.insert(tools, tool)
    end

    for _, tool in ipairs(collectInventoryTools("isPlant", selectedPlants, true)) do
        table.insert(tools, tool)
    end

    return tools
end

local function runAutoSellSelected(showWarnings)
    if AutoSellRunning then
        if showWarnings then
            notify("Auto Sell", "Auto sell is already running.", "alert-circle", 2)
        end

        return false
    end

    local tools = getSelectedAutoSellTools()

    if #tools == 0 then
        if showWarnings then
            notify("Auto Sell", "Select capybaras or plants from Backpack first.", "alert-circle", 3)
        end

        return false
    end

    AutoSellRunning = true

    local sold = 0
    local maxPerCycle = 6

    for _, tool in ipairs(tools) do
        if Runtime.Destroyed or not AutoSellRunning or not getConfig("AutoSell.Enabled", false) then
            break
        end

        if sold >= maxPerCycle then
            break
        end

        if tool.Parent and tool:GetAttribute("Favorited") ~= true and equipTool(tool) and sellEquippedItem() then
            sold += 1
            task.wait(0.85)
        else
            task.wait(0.1)
        end
    end

    AutoSellRunning = false

    if sold > 0 or InventoryRefreshQueued then
        queueInventoryDropdownRefresh(true)
    end

    if sold > 0 and showWarnings then
        notify("Auto Sell", "Sold selected items: " .. tostring(sold), "check-circle", 3)
    end

    return sold > 0
end

GiftState.TargetPlayerName = getFirstGiftPlayerName()
watchToolContainer(getBackpack())

connect(LocalPlayer.ChildAdded, function(child)
    if child.Name == "Backpack" then
        watchToolContainer(child)
        queueInventoryDropdownRefresh()
    end
end)

if LocalPlayer.Character then
    watchToolContainer(LocalPlayer.Character)
end

connect(LocalPlayer.CharacterAdded, function(character)
    watchToolContainer(character)
    queueInventoryDropdownRefresh()
end)

connect(Players.PlayerAdded, function()
    task.defer(refreshGiftPlayerDropdown)
end)

connect(Players.PlayerRemoving, function(player)
    if GiftState.TargetPlayerName == player.Name then
        GiftState.TargetPlayerName = nil
    end

    task.defer(refreshGiftPlayerDropdown)
end)

local function refreshStock()
    if not Remote.RequestPersonalStock then
        return false, "RequestPersonalStock remote not found."
    end

    local ok, allStock, usedStock = pcall(function()
        return Remote.RequestPersonalStock:InvokeServer()
    end)

    if not ok then
        return false, allStock
    end

    if type(allStock) ~= "table" then
        return false, "Stock response is not a table."
    end

    if type(usedStock) ~= "table" then
        usedStock = {}
    end

    for _, eggName in ipairs(EggItems) do
        StockCache[eggName] = math.max(0, tonumber(allStock[eggName] or 0) - tonumber(usedStock[eggName] or 0))
    end

    for _, gearName in ipairs(GearItems) do
        StockCache[gearName] = math.max(0, tonumber(allStock[gearName] or 0) - tonumber(usedStock[gearName] or 0))
    end

    return true
end

local function buyEggOnce(itemName)
    if not isEggItem(itemName) and not isGearItem(itemName) then
        return false
    end

    local available = tonumber(StockCache[itemName] or 0)

    if available <= 0 then
        return false
    end

    if not canAfford(itemName) then
        return false
    end

    local now = os.clock()

    if LastBuyAt[itemName] and now - LastBuyAt[itemName] < 0.35 then
        return false
    end

    LastBuyAt[itemName] = now

    local ok, err = pcall(function()
        Remote.BuyItem:FireServer(itemName)
    end)

    if not ok then
        notify("Auto Shop", tostring(err), "x-circle", 4)
        return false
    end

    StockCache[itemName] = math.max(0, available - 1)
    return true
end

local function buySelectedEggsOnce()
    local bought = 0

    refreshStock()

    for _, eggName in ipairs(EggItems) do
        if Runtime.Destroyed then
            break
        end

        if getConfig("Shop.SelectedEggs." .. eggName, false) then
            while tonumber(StockCache[eggName] or 0) > 0 do
                if Runtime.Destroyed then
                    break
                end

                if not buyEggOnce(eggName) then
                    break
                end

                bought += 1
                task.wait(0.15)
            end
        end
    end

    return bought
end

local function buySelectedGearsOnce()
    local bought = 0

    refreshStock()

    for _, gearName in ipairs(GearItems) do
        if Runtime.Destroyed then
            break
        end

        if getConfig("Shop.SelectedGears." .. gearName, false) then
            while tonumber(StockCache[gearName] or 0) > 0 do
                if Runtime.Destroyed then
                    break
                end

                if not buyEggOnce(gearName) then
                    break
                end

                bought += 1
                task.wait(0.15)
            end
        end
    end

    return bought
end

local function buyMerchantItemOnce(itemName)
    if not isMerchantItem(itemName) or not Remote.BuyMerchantItem then
        return false
    end

    local merchantName = MerchantItemToCategory[itemName]

    if not CurrentMerchantName or CurrentMerchantName ~= merchantName then
        return false
    end

    local available = tonumber(MerchantStockCache[itemName] or 0)

    if available <= 0 then
        return false
    end

    if not canAfford(itemName) then
        return false
    end

    local now = os.clock()

    if LastMerchantBuyAt[itemName] and now - LastMerchantBuyAt[itemName] < 0.35 then
        return false
    end

    LastMerchantBuyAt[itemName] = now

    local ok, err = pcall(function()
        Remote.BuyMerchantItem:FireServer(itemName)
    end)

    if not ok then
        notify("Merchant", tostring(err), "x-circle", 4)
        return false
    end

    MerchantStockCache[itemName] = math.max(0, available - 1)
    return true
end

local function buySelectedMerchantItemsOnce()
    local bought = 0

    refreshMerchantStock()

    if not CurrentMerchantName then
        return bought
    end

    for _, itemName in ipairs(getMerchantItems(CurrentMerchantName)) do
        if Runtime.Destroyed then
            break
        end

        if isMerchantItemSelected(CurrentMerchantName, itemName) then
            while tonumber(MerchantStockCache[itemName] or 0) > 0 do
                if Runtime.Destroyed then
                    break
                end

                if not buyMerchantItemOnce(itemName) then
                    break
                end

                bought += 1
                task.wait(0.15)
            end
        end
    end

    return bought
end

local function tryBuyFromStockUpdate(itemName, amount)
    if not isEggItem(itemName) and not isGearItem(itemName) then
        return
    end

    StockCache[itemName] = math.max(0, tonumber(amount) or 0)

    local shouldBuy = false

    if isEggItem(itemName) then
        shouldBuy = getConfig("Shop.AutoBuyEggs", false) and getConfig("Shop.SelectedEggs." .. itemName, false)
    elseif isGearItem(itemName) then
        shouldBuy = getConfig("Shop.AutoBuyGears", false) and getConfig("Shop.SelectedGears." .. itemName, false)
    end

    if shouldBuy then
        task.defer(function()
            while not Runtime.Destroyed and tonumber(StockCache[itemName] or 0) > 0 do
                if not buyEggOnce(itemName) then
                    break
                end

                task.wait(0.15)
            end
        end)
    end
end

local function tryBuyFromMerchantStockUpdate(itemName, amount)
    if not isMerchantItem(itemName) then
        return
    end

    local merchantName = MerchantItemToCategory[itemName]

    if not CurrentMerchantName or CurrentMerchantName ~= merchantName then
        return
    end

    MerchantStockCache[itemName] = math.max(0, tonumber(amount) or 0)

    if getConfig("Shop.AutoBuyMerchant", false) and isMerchantItemSelected(merchantName, itemName) then
        task.defer(function()
            while not Runtime.Destroyed and tonumber(MerchantStockCache[itemName] or 0) > 0 do
                if not buyMerchantItemOnce(itemName) then
                    break
                end

                task.wait(0.15)
            end
        end)
    end
end

local LowState = {
    Running = false,
    Connections = {},
    Original = setmetatable({}, { __mode = "k" }),
}

local function disableIdleConnections()
    if type(getconnections) ~= "function" then
        return
    end

    local ok, connections = pcall(function()
        return getconnections(LocalPlayer.Idled)
    end)

    if not ok or type(connections) ~= "table" then
        return
    end

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disable()
        end)
    end
end

local function nudgeAntiAfk()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector3.new())
    end)
end

local function rememberLowProperty(object, property)
    local bucket = LowState.Original[object]

    if not bucket then
        bucket = {}
        LowState.Original[object] = bucket
    end

    if bucket[property] == nil then
        local ok, value = pcall(function()
            return object[property]
        end)

        if ok then
            bucket[property] = value
        end
    end
end

local function setLowProperty(object, property, value)
    rememberLowProperty(object, property)

    pcall(function()
        object[property] = value
    end)
end

local function boostLighting()
    setLowProperty(Lighting, "GlobalShadows", false)
    setLowProperty(Lighting, "EnvironmentDiffuseScale", 0)
    setLowProperty(Lighting, "EnvironmentSpecularScale", 0)
    setLowProperty(Lighting, "Brightness", 3)
    setLowProperty(Lighting, "FogEnd", 1000000)
    setLowProperty(Lighting, "ShadowSoftness", 0)

    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    pcall(function()
        UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    end)

    local terrain = Workspace:FindFirstChildOfClass("Terrain")

    if terrain then
        setLowProperty(terrain, "WaterWaveSize", 0)
        setLowProperty(terrain, "WaterWaveSpeed", 0)
        setLowProperty(terrain, "WaterReflectance", 0)
        setLowProperty(terrain, "WaterTransparency", 1)
        setLowProperty(terrain, "Decoration", false)
    end
end

local function boostObject(object)
    if object:IsA("BasePart") then
        setLowProperty(object, "CastShadow", false)
        setLowProperty(object, "Reflectance", 0)

        if object.Material ~= Enum.Material.Neon then
            setLowProperty(object, "Material", Enum.Material.SmoothPlastic)
        end

        if object:IsA("MeshPart") then
            setLowProperty(object, "RenderFidelity", Enum.RenderFidelity.Performance)
        end
    elseif object:IsA("Decal") or object:IsA("Texture") then
        setLowProperty(object, "Transparency", 1)
    elseif object:IsA("ParticleEmitter") then
        setLowProperty(object, "Enabled", false)
        setLowProperty(object, "Rate", 0)

        pcall(function()
            object:Clear()
        end)
    elseif object:IsA("Trail") or object:IsA("Beam") then
        setLowProperty(object, "Enabled", false)
    elseif object:IsA("Smoke") or object:IsA("Fire") or object:IsA("Sparkles") then
        setLowProperty(object, "Enabled", false)
    elseif object:IsA("PointLight") or object:IsA("SpotLight") or object:IsA("SurfaceLight") then
        setLowProperty(object, "Enabled", false)
    elseif object:IsA("PostEffect") then
        setLowProperty(object, "Enabled", false)
    elseif object:IsA("Atmosphere") then
        setLowProperty(object, "Density", 0)
        setLowProperty(object, "Haze", 0)
        setLowProperty(object, "Glare", 0)
    elseif object:IsA("Clouds") then
        setLowProperty(object, "Cover", 0)
        setLowProperty(object, "Density", 0)
    elseif object:IsA("Highlight") then
        setLowProperty(object, "Enabled", false)
    elseif object:IsA("Explosion") then
        setLowProperty(object, "Visible", false)
        setLowProperty(object, "BlastPressure", 0)
    end
end

local function applyLowReducer()
    if type(setfpscap) == "function" then
        pcall(setfpscap, 999)
    end

    boostLighting()

    for _, object in ipairs(game:GetDescendants()) do
        boostObject(object)
    end
end

local function restoreLowReducer()
    for object, properties in pairs(LowState.Original) do
        if object and object.Parent then
            for property, value in pairs(properties) do
                pcall(function()
                    object[property] = value
                end)
            end
        end
    end
end

function disableLow()
    LowState.Running = false

    for _, connection in ipairs(LowState.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    if type(table.clear) == "function" then
        table.clear(LowState.Connections)
    else
        LowState.Connections = {}
    end

    restoreLowReducer()
end

function enableLow()
    if LowState.Running then
        return
    end

    LowState.Running = true
    disableIdleConnections()
    applyLowReducer()

    table.insert(LowState.Connections, LocalPlayer.Idled:Connect(function()
        disableIdleConnections()
        nudgeAntiAfk()
    end))

    table.insert(LowState.Connections, game.DescendantAdded:Connect(function(object)
        if LowState.Running then
            task.defer(boostObject, object)
        end
    end))

    task.spawn(function()
        while LowState.Running and not Runtime.Destroyed do
            task.wait(60)

            if not LowState.Running or Runtime.Destroyed or not LocalPlayer.Parent then
                break
            end

            disableIdleConnections()
            nudgeAntiAfk()
        end
    end)
end

Runtime.LowCleanup = disableLow

if getConfig("Misc.Low", false) then
    task.defer(enableLow)
end

local function UpdatePrompt(prompt)
    if prompt:IsA("ProximityPrompt") then
        pcall(function()
            prompt.HoldDuration = 0
        end)
    end
end

task.defer(function()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        UpdatePrompt(obj)
    end
end)

connect(Workspace.DescendantAdded, UpdatePrompt)

connect(Remote.UpdatePersonalStock and Remote.UpdatePersonalStock.OnClientEvent, function(itemName, amount)
    tryBuyFromStockUpdate(itemName, amount)
end)

connect(Remote.UpdateAllPersonalStock and Remote.UpdateAllPersonalStock.OnClientEvent, function(stockTable)
    if type(stockTable) ~= "table" then
        return
    end

    for _, eggName in ipairs(EggItems) do
        local amount = stockTable[eggName] or 0
        tryBuyFromStockUpdate(eggName, amount)
    end

    for _, gearName in ipairs(GearItems) do
        local amount = stockTable[gearName] or 0
        tryBuyFromStockUpdate(gearName, amount)
    end
end)

connect(Remote.UpdateMerchantPersonalStock and Remote.UpdateMerchantPersonalStock.OnClientEvent, function(itemName, amount)
    tryBuyFromMerchantStockUpdate(itemName, amount)
end)

connect(Remote.UpdateTravelingMerchantStock and Remote.UpdateTravelingMerchantStock.OnClientEvent, function(merchantName, stockTable)
    updateMerchantStockCache(merchantName, stockTable, {})

    if not getConfig("Shop.AutoBuyMerchant", false) or not CurrentMerchantName then
        return
    end

    for _, itemName in ipairs(getMerchantItems(CurrentMerchantName)) do
        tryBuyFromMerchantStockUpdate(itemName, MerchantStockCache[itemName] or 0)
    end
end)

connect(Remote.MerchantLeft and Remote.MerchantLeft.OnClientEvent, function()
    CurrentMerchantName = nil
    clearMerchantStockCache()
end)

local function getSelectedEggCount()
    local count = 0

    for _, eggName in ipairs(EggItems) do
        if getConfig("Shop.SelectedEggs." .. eggName, false) then
            count += 1
        end
    end

    return count
end

local function getSelectedEggValues()
    local selected = {}

    for _, eggName in ipairs(EggItems) do
        if getConfig("Shop.SelectedEggs." .. eggName, false) then
            table.insert(selected, eggName)
        end
    end

    return selected
end

local function setSelectedEggsFromDropdown(values)
    local selectedLookup = {}

    if type(values) == "table" then
        for key, value in pairs(values) do
            if isEggItem(value) then
                selectedLookup[value] = true
            elseif value == true and isEggItem(key) then
                selectedLookup[key] = true
            end
        end
    elseif isEggItem(values) then
        selectedLookup[values] = true
    end

    for _, eggName in ipairs(EggItems) do
        setConfig("Shop.SelectedEggs." .. eggName, selectedLookup[eggName] == true)
    end

    autoSaveConfig()

    return getSelectedEggCount()
end

local function getSelectedGearValues()
    local selected = {}

    for _, gearName in ipairs(GearItems) do
        if getConfig("Shop.SelectedGears." .. gearName, false) then
            table.insert(selected, gearName)
        end
    end

    return selected
end

local function setSelectedGearsFromDropdown(values)
    local selectedLookup = {}

    if type(values) == "table" then
        for key, value in pairs(values) do
            if isGearItem(value) then
                selectedLookup[value] = true
            elseif value == true and isGearItem(key) then
                selectedLookup[key] = true
            end
        end
    elseif isGearItem(values) then
        selectedLookup[values] = true
    end

    for _, gearName in ipairs(GearItems) do
        setConfig("Shop.SelectedGears." .. gearName, selectedLookup[gearName] == true)
    end

    autoSaveConfig()

    return #getSelectedGearValues()
end

local function isBossItem(bossName)
    for _, itemName in ipairs(BOSS_ITEMS) do
        if itemName == bossName then
            return true
        end
    end

    return false
end

local function isDrCarrotBossItem(bossName)
    for _, itemName in ipairs(BOSS_DR_CARROT_ITEMS) do
        if itemName == bossName then
            return true
        end
    end

    return false
end

local function getSelectedBossValues()
    local selected = {}

    for _, bossName in ipairs(BOSS_ITEMS) do
        if getConfig("Boss.SelectedBosses." .. bossName, false) then
            table.insert(selected, bossName)
        end
    end

    return selected
end

local function getSelectedDrCarrotBossValues()
    local selected = {}

    for _, bossName in ipairs(BOSS_DR_CARROT_ITEMS) do
        if getConfig("Boss.SelectedDrCarrotBosses." .. bossName, false) then
            table.insert(selected, bossName)
        end
    end

    return selected
end

local BossQueueCursor = 1
local BossQueueSignature = ""

local function getBossQueueSignature(selected)
    return table.concat(selected, "|")
end

local function syncBossQueueCursor(selected)
    local signature = getBossQueueSignature(selected)

    if signature ~= BossQueueSignature then
        BossQueueCursor = 1
        BossQueueSignature = signature
    end

    if BossQueueCursor < 1 or BossQueueCursor > #selected then
        BossQueueCursor = 1
    end
end

local function advanceBossQueueCursor(selected)
    if #selected == 0 then
        BossQueueCursor = 1
        BossQueueSignature = ""
        return
    end

    BossQueueCursor += 1

    if BossQueueCursor > #selected then
        BossQueueCursor = 1
    end

    BossQueueSignature = getBossQueueSignature(selected)
end

local function setSelectedBossesFromDropdown(values)
    local selectedLookup = {}

    if type(values) == "table" then
        for key, value in pairs(values) do
            if isBossItem(value) then
                selectedLookup[value] = true
            elseif value == true and isBossItem(key) then
                selectedLookup[key] = true
            end
        end
    elseif isBossItem(values) then
        selectedLookup[values] = true
    end

    for _, bossName in ipairs(BOSS_ITEMS) do
        setConfig("Boss.SelectedBosses." .. bossName, selectedLookup[bossName] == true)
    end

    autoSaveConfig()
    BossQueueCursor = 1
    BossQueueSignature = ""

    return #getSelectedBossValues()
end

local BossDrCarrotQueueCursor = 1
local BossDrCarrotQueueSignature = ""

local function syncBossDrCarrotQueueCursor(selected)
    local signature = getBossQueueSignature(selected)

    if signature ~= BossDrCarrotQueueSignature then
        BossDrCarrotQueueCursor = 1
        BossDrCarrotQueueSignature = signature
    end

    if BossDrCarrotQueueCursor < 1 or BossDrCarrotQueueCursor > #selected then
        BossDrCarrotQueueCursor = 1
    end
end

local function advanceBossDrCarrotQueueCursor(selected)
    if #selected == 0 then
        BossDrCarrotQueueCursor = 1
        BossDrCarrotQueueSignature = ""
        return
    end

    BossDrCarrotQueueCursor += 1

    if BossDrCarrotQueueCursor > #selected then
        BossDrCarrotQueueCursor = 1
    end

    BossDrCarrotQueueSignature = getBossQueueSignature(selected)
end

local function setSelectedDrCarrotBossesFromDropdown(values)
    local selectedLookup = {}

    if type(values) == "table" then
        for key, value in pairs(values) do
            if isDrCarrotBossItem(value) then
                selectedLookup[value] = true
            elseif value == true and isDrCarrotBossItem(key) then
                selectedLookup[key] = true
            end
        end
    elseif isDrCarrotBossItem(values) then
        selectedLookup[values] = true
    end

    for _, bossName in ipairs(BOSS_DR_CARROT_ITEMS) do
        setConfig("Boss.SelectedDrCarrotBosses." .. bossName, selectedLookup[bossName] == true)
    end

    autoSaveConfig()
    BossDrCarrotQueueCursor = 1
    BossDrCarrotQueueSignature = ""

    return #getSelectedDrCarrotBossValues()
end

local BossState

local function requestBossState()
    if not Remote.SummonBoss then
        return nil, "SummonBoss remote not found."
    end

    local ok, state = pcall(function()
        return Remote.SummonBoss:InvokeServer("GetState")
    end)

    if not ok then
        return nil, state
    end

    if type(state) == "table" then
        BossState = state
        return state
    end

    return nil, "Boss state is not ready."
end

connect(Remote.BossUpdate and Remote.BossUpdate.OnClientEvent, function(state)
    if type(state) == "table" then
        BossState = state
    end
end)

local function bossMeetsRequirements(bossName, state)
    if not BossData or type(BossData.meetsRequirements) ~= "function" then
        return true
    end

    local ok, unlocked = pcall(function()
        return BossData.meetsRequirements(bossName, state.TreeLevel or 0, state.Defeated or {})
    end)

    return ok and unlocked == true
end

local function hasActiveBoss(state)
    local activeBoss = state and state.ActiveBoss

    return activeBoss ~= nil and activeBoss ~= false and activeBoss ~= ""
end

local function getBossCooldown(bossName, state)
    local cooldown = state and state.Cooldowns and tonumber(state.Cooldowns[bossName]) or 0

    return math.max(0, cooldown or 0)
end

local function summonBossOnce(bossName, state)
    if not isBossItem(bossName) and not isDrCarrotBossItem(bossName) then
        return false, "invalid"
    end

    if not Remote.SummonBoss then
        return false, "invalid"
    end

    state = state or requestBossState() or BossState

    if type(state) ~= "table" then
        return false, "state"
    end

    if hasActiveBoss(state) then
        return false, "active"
    end

    if not bossMeetsRequirements(bossName, state) then
        return false, "locked"
    end

    if getBossCooldown(bossName, state) > 0 then
        return false, "cooldown"
    end

    local ok, result = pcall(function()
        return Remote.SummonBoss:InvokeServer("Summon", bossName)
    end)

    task.defer(requestBossState)

    if not ok then
        return false, result
    end

    return result ~= false, result
end

local function summonSelectedBossesOnce()
    local selectedBosses = getSelectedBossValues()

    if #selectedBosses == 0 then
        BossQueueCursor = 1
        BossQueueSignature = ""
        return 0
    end

    syncBossQueueCursor(selectedBosses)

    local state = requestBossState() or BossState

    if type(state) ~= "table" or hasActiveBoss(state) then
        return 0
    end

    for _ = 1, #selectedBosses do
        if Runtime.Destroyed then
            break
        end

        local bossName = selectedBosses[BossQueueCursor]

        if not bossName then
            syncBossQueueCursor(selectedBosses)
            bossName = selectedBosses[BossQueueCursor]
        end

        if not bossName then
            return 0
        end

        if bossMeetsRequirements(bossName, state) then
            if getBossCooldown(bossName, state) > 0 then
                return 0
            end

            local summoned = summonBossOnce(bossName, state)

            if summoned then
                advanceBossQueueCursor(selectedBosses)
                return 1
            end

            return 0
        end

        advanceBossQueueCursor(selectedBosses)
    end

    return 0
end

local function summonSelectedDrCarrotBossesOnce()
    local selectedBosses = getSelectedDrCarrotBossValues()

    if #selectedBosses == 0 then
        BossDrCarrotQueueCursor = 1
        BossDrCarrotQueueSignature = ""
        return 0
    end

    syncBossDrCarrotQueueCursor(selectedBosses)

    local state = requestBossState() or BossState

    if type(state) ~= "table" or hasActiveBoss(state) then
        return 0
    end

    for _ = 1, #selectedBosses do
        if Runtime.Destroyed then
            break
        end

        local bossName = selectedBosses[BossDrCarrotQueueCursor]

        if not bossName then
            syncBossDrCarrotQueueCursor(selectedBosses)
            bossName = selectedBosses[BossDrCarrotQueueCursor]
        end

        if not bossName then
            return 0
        end

        if bossMeetsRequirements(bossName, state) then
            if getBossCooldown(bossName, state) > 0 then
                return 0
            end

            local summoned = summonBossOnce(bossName, state)

            if summoned then
                advanceBossDrCarrotQueueCursor(selectedBosses)
                return 1
            end

            return 0
        end

        advanceBossDrCarrotQueueCursor(selectedBosses)
    end

    return 0
end

local function getGiftYesButton()
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
    local root = mainGui and mainGui:FindFirstChild("Root")
    local frames = root and root:FindFirstChild("Frames")
    local giftRequest = frames and frames:FindFirstChild("GiftRequest")
    local yes = giftRequest and giftRequest:FindFirstChild("Yes")

    return yes and yes:FindFirstChild("Button"), giftRequest
end

local function clickGiftYes()
    local button, giftRequest = getGiftYesButton()

    if not button or not giftRequest then
        return false
    end

    if giftRequest.Visible == false then
        return false
    end

    local fired = false

    if type(firesignal) == "function" then
        fired = pcall(firesignal, button.Activated) or fired

        if button.MouseButton1Click then
            fired = pcall(firesignal, button.MouseButton1Click) or fired
        end
    end

    if not fired then
        fired = pcall(function()
            button:Activate()
        end)
    end

    return fired
end

do
    local MainTab = Window:Tab({
        Title = "Main",
        Desc = "Money automation",
        Icon = "wallet",
    })

    local MainSection = MainTab:Section({
    Title = "Collect All Money",
    Desc = "Collect machine money",
    Icon = "coins",
    Side = "left",
})

MainSection:Button({
    Title = "Collect Now",
    Description = "Fire CollectionMachine once",
    Icon = "hand-coins",
    Callback = function()
        runButton("CollectNow", function()
            if collectAllMoney() and getConfig("Buttons.CollectNow.Notify", true) then
                notify("Collect All Money", "Collected money once.", "check-circle", 2)
            end
        end)
    end,
})

MainSection:Slider({
    Title = "Collect Delay",
    Value = {
        Min = 30,
        Max = 600,
        Default = math.max(30, tonumber(getConfig("Main.CollectDelay", 30)) or 30),
    },
    Step = 1,
    Callback = function(value)
        setConfig("Main.CollectDelay", math.max(30, tonumber(value) or 30))
        autoSaveConfig()
    end,
})

MainSection:Toggle({
    Title = "Auto Collect Money",
    Description = "Minimum delay is 30 seconds",
    Icon = "repeat",
    Value = getConfig("Main.AutoCollectMoney", false),
    Callback = function(enabled)
        setConfig("Main.AutoCollectMoney", enabled == true)
        autoSaveConfig()
        notify("Collect All Money", enabled and "Auto collect enabled." or "Auto collect disabled.", enabled and "check-circle" or "x-circle", 2)
    end,
})

end

do
    local ShopTab = Window:Tab({
        Title = "Shop",
        Desc = "Shop auto buyer",
        Icon = "shopping-cart",
    })

    local ShopControlSection = ShopTab:Section({
    Title = "Auto Buy Eggs",
    Desc = "Buy selected eggs when stocked",
    Icon = "egg",
    Side = "left",
})

local EggDropdownReady = false

ShopControlSection:Dropdown({
    Title = "Select Egg",
    Description = "Pick multiple eggs for auto buy",
    Values = EggItems,
    Value = getSelectedEggValues(),
    Default = getSelectedEggValues(),
    Multi = true,
    AllowNone = true,
    Callback = function(value)
        if not EggDropdownReady then
            return
        end

        local count = setSelectedEggsFromDropdown(value)

        notify("Auto Shop", "Selected eggs: " .. tostring(count), "check-circle", 2)

        if getConfig("Shop.AutoBuyEggs", false) then
            refreshStock()

            for _, eggName in ipairs(getSelectedEggValues()) do
                tryBuyFromStockUpdate(eggName, StockCache[eggName] or 0)
            end
        end
    end,
})

task.defer(function()
    EggDropdownReady = true
end)

ShopControlSection:Toggle({
    Title = "Auto Buy Eggs",
    Description = "Uses stock update events and backup loop",
    Icon = "shopping-bag",
    Value = getConfig("Shop.AutoBuyEggs", false),
    Callback = function(enabled)
        setConfig("Shop.AutoBuyEggs", enabled == true)
        autoSaveConfig()

        if enabled then
            refreshStock()
        end

        notify("Auto Shop", enabled and "Auto buy enabled." or "Auto buy disabled.", enabled and "check-circle" or "x-circle", 2)
    end,
})

local GearControlSection = ShopTab:Section({
    Title = "Auto Buy Gears",
    Desc = "Buy selected gears when stocked",
    Icon = "hammer",
    Side = "right",
})

local GearDropdownReady = false

GearControlSection:Dropdown({
    Title = "Select Gear",
    Description = "Pick multiple gears for auto buy",
    Values = GearItems,
    Value = getSelectedGearValues(),
    Default = getSelectedGearValues(),
    Multi = true,
    AllowNone = true,
    Callback = function(value)
        if not GearDropdownReady then
            return
        end

        local count = setSelectedGearsFromDropdown(value)

        notify("Auto Shop", "Selected gears: " .. tostring(count), "check-circle", 2)

        if getConfig("Shop.AutoBuyGears", false) then
            refreshStock()

            for _, gearName in ipairs(getSelectedGearValues()) do
                tryBuyFromStockUpdate(gearName, StockCache[gearName] or 0)
            end
        end
    end,
})

task.defer(function()
    GearDropdownReady = true
end)

GearControlSection:Toggle({
    Title = "Auto Buy Gears",
    Description = "Uses stock update events and backup loop",
    Icon = "shopping-bag",
    Value = getConfig("Shop.AutoBuyGears", false),
    Callback = function(enabled)
        setConfig("Shop.AutoBuyGears", enabled == true)
        autoSaveConfig()

        if enabled then
            refreshStock()
        end

        notify("Auto Shop", enabled and "Auto gear buy enabled." or "Auto gear buy disabled.", enabled and "check-circle" or "x-circle", 2)
    end,
})

local MerchantSection = ShopTab:Section({
    Title = "Merchant Items",
    Desc = "Selected traveling merchant stock",
    Icon = "store",
    Side = "left",
})

local MerchantDropdownReady = {}

local function addMerchantDropdown(section, merchantName)
    MerchantDropdownReady[merchantName] = false

    section:Dropdown({
        Title = merchantName,
        Description = "Pick multiple merchant items",
        Values = getMerchantItems(merchantName),
        Value = getSelectedMerchantValues(merchantName),
        Default = getSelectedMerchantValues(merchantName),
        Multi = true,
        AllowNone = true,
        Callback = function(value)
            if not MerchantDropdownReady[merchantName] then
                return
            end

            local count = setSelectedMerchantItemsFromDropdown(merchantName, value)
            notify("Merchant", merchantName .. " selected: " .. tostring(count), "check-circle", 2)

            if getConfig("Shop.AutoBuyMerchant", false) and CurrentMerchantName == merchantName then
                for _, itemName in ipairs(getSelectedMerchantValues(merchantName)) do
                    tryBuyFromMerchantStockUpdate(itemName, MerchantStockCache[itemName] or 0)
                end
            end
        end,
    })

    task.defer(function()
        MerchantDropdownReady[merchantName] = true
    end)
end

for _, merchantName in ipairs(MerchantCategories) do
    addMerchantDropdown(MerchantSection, merchantName)
end

MerchantSection:Toggle({
    Title = "Auto Buy Merchant",
    Description = "Buys selected items when merchant arrives",
    Icon = "shopping-bag",
    Value = getConfig("Shop.AutoBuyMerchant", false),
    Callback = function(enabled)
        setConfig("Shop.AutoBuyMerchant", enabled == true)
        autoSaveConfig()

        if enabled then
            task.defer(buySelectedMerchantItemsOnce)
        end

        notify("Merchant", enabled and "Auto merchant buy enabled." or "Auto merchant buy disabled.", enabled and "check-circle" or "x-circle", 2)
    end,
})

end

PlayerDropdownReady = false
InventoryDropdownsReady = false

do
    local GiftTab = Window:Tab({
        Title = "Gift",
        Desc = "Gift selected items",
        Icon = "gift",
    })

    local SellTab = Window:Tab({
        Title = "Sell",
        Desc = "Sell selected items",
        Icon = "badge-dollar-sign",
    })

    local GiftSection = GiftTab:Section({
    Title = "Auto Gift",
    Desc = "Gift selected Backpack items",
    Icon = "gift",
    Side = "left",
})

GiftPlayerDropdown = GiftSection:Dropdown({
    Title = "Select Player",
    Description = "Updates when players join or leave",
    Values = getGiftPlayerValues(),
    Value = GiftState.TargetPlayerName or EMPTY_PLAYER_VALUE,
    Default = GiftState.TargetPlayerName or EMPTY_PLAYER_VALUE,
    Callback = function(value)
        if not PlayerDropdownReady then
            return
        end

        if value == EMPTY_PLAYER_VALUE then
            GiftState.TargetPlayerName = nil
            return
        end

        if Players:FindFirstChild(value) then
            GiftState.TargetPlayerName = value

            if not SuppressGiftPlayerDropdownNotify then
                notify("Gift", "Selected player: " .. tostring(value), "check-circle", 2)
            end
        end
    end,
})

local initialCapybaraValues = getCapybaraInventoryValues()
local initialPlantValues = getPlantInventoryValues()

GiftCapybarasDropdown = GiftSection:Dropdown({
    Title = "Capybaras",
    Description = "Select capybaras to gift",
    Values = initialCapybaraValues,
    Value = getLookupSelectionValues(GiftState.SelectedCapybaras, initialCapybaraValues),
    Default = getLookupSelectionValues(GiftState.SelectedCapybaras, initialCapybaraValues),
    Multi = true,
    AllowNone = true,
    Callback = function(value)
        if not InventoryDropdownsReady then
            return
        end

        local count = setLookupSelectionFromDropdown(GiftState.SelectedCapybaras, value, getCapybaraInventoryValues())
        notify("Gift", "Selected capybaras: " .. tostring(count), "check-circle", 2)
    end,
})

GiftPlantsDropdown = GiftSection:Dropdown({
    Title = "Plants",
    Description = "Select plants to gift",
    Values = initialPlantValues,
    Value = getLookupSelectionValues(GiftState.SelectedPlants, initialPlantValues),
    Default = getLookupSelectionValues(GiftState.SelectedPlants, initialPlantValues),
    Multi = true,
    AllowNone = true,
    Callback = function(value)
        if not InventoryDropdownsReady then
            return
        end

        local count = setLookupSelectionFromDropdown(GiftState.SelectedPlants, value, getPlantInventoryValues())
        notify("Gift", "Selected plants: " .. tostring(count), "check-circle", 2)
    end,
})

GiftSection:Input({
    Title = "Gift Amount",
    Placeholder = "0 = all selected",
    Callback = function(text)
        GiftState.Amount = parsePositiveInteger(text)
    end,
})

GiftSection:Toggle({
    Title = "Auto Gift",
    Description = "Hold selected items and gift them",
    Icon = "gift",
    Value = GiftState.AutoGift,
    Callback = function(enabled)
        GiftState.AutoGift = enabled == true

        if GiftState.AutoGift then
            if not getSelectedGiftPlayer() then
                notify("Gift", "Select a player first.", "alert-circle", 3)
            elseif #collectSelectedGiftTools() == 0 then
                notify("Gift", "Select capybaras or plants from Backpack first.", "alert-circle", 3)
            else
                notify("Gift", "Auto gift enabled.", "check-circle", 2)
            end
        else
            GiftState.Running = false
            queueInventoryDropdownRefresh(true)
            notify("Gift", "Auto gift disabled.", "x-circle", 2)
        end
    end,
})

GiftSection:Toggle({
    Title = "Auto Accept Gift",
    Description = "Clicks GiftRequest Yes button",
    Icon = "check",
    Value = getConfig("Gift.AutoAccept", false),
    Callback = function(enabled)
        setConfig("Gift.AutoAccept", enabled == true)
        autoSaveConfig()
        notify("Gift", enabled and "Auto accept enabled." or "Auto accept disabled.", enabled and "check-circle" or "x-circle", 2)
    end,
})

local SellSection = SellTab:Section({
    Title = "Auto Sell",
    Desc = "Sell selected Backpack items",
    Icon = "badge-dollar-sign",
    Side = "left",
})

SellCapybarasDropdown = SellSection:Dropdown({
    Title = "Capybaras",
    Description = "Select capybaras to sell",
    Values = initialCapybaraValues,
    Value = getConfigSelectionValues("AutoSell.SelectedCapybaras", initialCapybaraValues),
    Default = getConfigSelectionValues("AutoSell.SelectedCapybaras", initialCapybaraValues),
    Multi = true,
    AllowNone = true,
    Callback = function(value)
        if not InventoryDropdownsReady then
            return
        end

        local count = setConfigSelectionFromDropdown("AutoSell.SelectedCapybaras", value, getCapybaraInventoryValues())
        notify("Auto Sell", "Selected capybaras: " .. tostring(count), "check-circle", 2)
    end,
})

SellPlantsDropdown = SellSection:Dropdown({
    Title = "Plants",
    Description = "Select plants to sell",
    Values = initialPlantValues,
    Value = getConfigSelectionValues("AutoSell.SelectedPlants", initialPlantValues),
    Default = getConfigSelectionValues("AutoSell.SelectedPlants", initialPlantValues),
    Multi = true,
    AllowNone = true,
    Callback = function(value)
        if not InventoryDropdownsReady then
            return
        end

        local count = setConfigSelectionFromDropdown("AutoSell.SelectedPlants", value, getPlantInventoryValues())
        notify("Auto Sell", "Selected plants: " .. tostring(count), "check-circle", 2)
    end,
})

SellSection:Toggle({
    Title = "Auto Sell",
    Description = "Equip and sell selected items",
    Icon = "play",
    Value = getConfig("AutoSell.Enabled", false),
    Callback = function(enabled)
        setConfig("AutoSell.Enabled", enabled == true)
        autoSaveConfig()

        if enabled then
            if #getSelectedAutoSellTools() == 0 then
                notify("Auto Sell", "Select capybaras or plants from Backpack first.", "alert-circle", 3)
            else
                notify("Auto Sell", "Auto sell enabled.", "check-circle", 2)
            end
        else
            AutoSellRunning = false
            queueInventoryDropdownRefresh(true)
            notify("Auto Sell", "Auto sell disabled.", "x-circle", 2)
        end
    end,
})

task.defer(function()
    PlayerDropdownReady = true
    InventoryDropdownsReady = true
    refreshGiftPlayerDropdown()
    refreshInventoryDropdowns()
end)

end

do
    local BossTab = Window:Tab({
        Title = "Boss",
        Desc = "Boss summoner",
        Icon = "swords",
    })

    local BossSection = BossTab:Section({
    Title = "Summon Boss",
    Desc = "Summon selected bosses in order",
    Icon = "swords",
    Side = "left",
})

local BossDropdownReady = false

BossSection:Dropdown({
    Title = "Select Boss",
    Description = "Pick multiple bosses for queue order",
    Values = BOSS_ITEMS,
    Value = getSelectedBossValues(),
    Default = getSelectedBossValues(),
    Multi = true,
    AllowNone = true,
    Callback = function(value)
        if not BossDropdownReady then
            return
        end

        local count = setSelectedBossesFromDropdown(value)
        notify("Boss", "Selected bosses: " .. tostring(count), "check-circle", 2)
    end,
})

task.defer(function()
    BossDropdownReady = true
end)

BossSection:Toggle({
    Title = "Auto Summon Boss",
    Description = "Waits for active boss and cooldown",
    Icon = "repeat",
    Value = getConfig("Boss.AutoSummon", false),
    Callback = function(enabled)
        setConfig("Boss.AutoSummon", enabled == true)
        autoSaveConfig()

        if enabled then
            requestBossState()
        end

        notify("Boss", enabled and "Auto summon enabled." or "Auto summon disabled.", enabled and "check-circle" or "x-circle", 2)
    end,
})

local BossDrCarrotSection = BossTab:Section({
    Title = "Boss Dr. Carrot",
    Desc = "Event bosses - Dr Carrot series",
    Icon = "zap",
    Side = "right",
})

local BossDrCarrotDropdownReady = false

BossDrCarrotSection:Dropdown({
    Title = "Select Dr. Carrot Boss",
    Description = "Pick multiple Dr. Carrot bosses",
    Values = BOSS_DR_CARROT_ITEMS,
    Value = getSelectedDrCarrotBossValues(),
    Default = getSelectedDrCarrotBossValues(),
    Multi = true,
    AllowNone = true,
    Callback = function(value)
        if not BossDrCarrotDropdownReady then
            return
        end

        local count = setSelectedDrCarrotBossesFromDropdown(value)
        notify("Boss Dr. Carrot", "Selected bosses: " .. tostring(count), "check-circle", 2)
    end,
})

task.defer(function()
    BossDrCarrotDropdownReady = true
end)

BossDrCarrotSection:Toggle({
    Title = "Auto Summon Dr. Carrot",
    Description = "Waits for active boss and cooldown",
    Icon = "repeat",
    Value = getConfig("Boss.AutoSummonDrCarrot", false),
    Callback = function(enabled)
        setConfig("Boss.AutoSummonDrCarrot", enabled == true)
        autoSaveConfig()

        if enabled then
            requestBossState()
        end

        notify("Boss Dr. Carrot", enabled and "Auto summon enabled." or "Auto summon disabled.", enabled and "check-circle" or "x-circle", 2)
    end,
})

end

task.spawn(function()
    while not Runtime.Destroyed do
        if getConfig("Main.AutoCollectMoney", false) then
            collectAllMoney()
            waitWithStop(math.max(30, tonumber(getConfig("Main.CollectDelay", 30)) or 30))
        else
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    while not Runtime.Destroyed do
        if getConfig("Shop.AutoBuyEggs", false) then
            buySelectedEggsOnce()
            waitWithStop(math.max(1, tonumber(getConfig("Shop.BuyDelay", 2)) or 2))
        else
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    while not Runtime.Destroyed do
        if getConfig("Shop.AutoBuyGears", false) then
            buySelectedGearsOnce()
            waitWithStop(math.max(1, tonumber(getConfig("Shop.BuyDelay", 2)) or 2))
        else
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    while not Runtime.Destroyed do
        if getConfig("Shop.AutoBuyMerchant", false) then
            buySelectedMerchantItemsOnce()
            waitWithStop(math.max(1, tonumber(getConfig("Shop.BuyDelay", 2)) or 2))
        else
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    while not Runtime.Destroyed do
        if getConfig("Boss.AutoSummon", false) then
            summonSelectedBossesOnce()
            waitWithStop(math.max(1, tonumber(getConfig("Boss.SummonDelay", 5)) or 5))
        else
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    while not Runtime.Destroyed do
        if getConfig("Boss.AutoSummonDrCarrot", false) then
            summonSelectedDrCarrotBossesOnce()
            waitWithStop(math.max(1, tonumber(getConfig("Boss.SummonDelay", 5)) or 5))
        else
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    while not Runtime.Destroyed do
        if GiftState.AutoGift then
            local giftedAny = runAutoGift(false)
            waitWithStop(giftedAny and 1 or 1.5)
        else
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    while not Runtime.Destroyed do
        if getConfig("AutoSell.Enabled", false) then
            local soldAny = runAutoSellSelected(false)
            waitWithStop(soldAny and 1.25 or 2)
        else
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    while not Runtime.Destroyed do
        if getConfig("Gift.AutoAccept", false) then
            clickGiftYes()
            task.wait(0.5)
        else
            task.wait(0.25)
        end
    end
end)

if AutoLoadedConfigOk then
    notify("Delex Hub", "Capybaras VS Plants loaded. Auto config: " .. sanitizeConfigName(getConfig("Meta.ConfigName", "Default")), "check-circle", 4)
else
    notify("Delex Hub", "Loaded, but config auto-load failed: " .. tostring(AutoLoadedConfigMessage), "alert-circle", 5)
end

Window:InitBaseTabs()
