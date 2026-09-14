if not game:IsLoaded() then
    game.Loaded:Wait()
end

local cloneref = cloneref or function(instance)
    return instance
end

-- SERVICES

local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local VirtualUser = cloneref(game:GetService("VirtualUser"))
local RunService = cloneref(game:GetService("RunService"))
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- CONFIG

Config = Config or {
    ["Auto Roll Anime"] = false,
    ["Auto Upgrade Dice"] = false,
    ["Auto Smart Equip Anime"] = false,
    ["Auto Money"] = false,
    ["Auto Upgrade Anime"] = false,
    ["Upgrade Anime Slot"] = 1,
    ["Auto Rebirth"] = false,
    ["Auto Upgrade"] = false,
    ["Upgrade Branch"] = "Money",
    ["Auto Towers"] = false,
    ["Selected Tower"] = "Dragon Tower",
    ["Auto Equip Best Tower Anime"] = false,
    ["Auto Claim Quest"] = false,
    ["Auto Buy Shop Quest"] = false,
    ["Selected Quest Shop Item"] = "Trait Reroll",
    ["Auto Sell Unit"] = false,
    ["Auto Sell Threshold"] = 0,
    ["Selected Dice"] = "Normal",
    ["Trade Player"] = "",
    ["Trade Unit Order"] = "Highest Income",
    ["Trade Unit Count"] = 1,
    ["Trade Items"] = {},
    ["Auto Trade"] = false,
    ["Anti AFK"] = true,
}
if Config["Anti AFK"] == nil then
    Config["Anti AFK"] = true
end
if type(Config["Trade Items"]) ~= "table" then
    Config["Trade Items"] = {}
end
Ex_Function = Ex_Function or {}

-- MODULES

local Network = require(ReplicatedStorage.Packages.Network)
local DataController = require(ReplicatedStorage.Framework.Features.Data.DataController)
local Dice = require(ReplicatedStorage.Framework.Features.Rolling.Dice)
local EntryRegistry = require(ReplicatedStorage.Framework.Features.Inventory.EntryRegistry)
local Towers = require(ReplicatedStorage.Framework.Features.Towers.Towers)
local TowerController = require(ReplicatedStorage.Framework.Features.Towers.TowerController)
local UIReferences = require(ReplicatedStorage.Framework.Features.UI.UIReferences)
local MenuController = require(ReplicatedStorage.Framework.Features.UI.MenuController)
local QuestConfig = require(ReplicatedStorage.Framework.Features.Quests.QuestConfig)

local RollComm = Network.ClientComm.new(ReplicatedStorage.Network, false, "RollService")
local DiceShopComm = Network.ClientComm.new(ReplicatedStorage.Network, false, "DiceShopService")
local PlotComm = Network.ClientComm.new(ReplicatedStorage.Network, false, "PlotService")
local RollDice = RollComm:GetFunction("RollDice")
local SetAutoRoll = RollComm:GetSignal("SetAutoRoll")
local BuyDice = DiceShopComm:GetSignal("BuyDice")
local EquipDice = DiceShopComm:GetSignal("EquipDice")
local EquipBest = PlotComm:GetSignal("EquipBest")
local CollectBalance = PlotComm:GetSignal("CollectBalance")
local LevelUpSlot = PlotComm:GetSignal("LevelUpSlot")
local RebirthComm = Network.ClientComm.new(ReplicatedStorage.Network, false, "RebirthService")
local RebirthSignal = RebirthComm:GetSignal("Rebirth")
local Rebirths = require(ReplicatedStorage.Framework.Features.Rebirth.Rebirths)
local SellComm = Network.ClientComm.new(ReplicatedStorage.Network, false, "SellService")
local SellInventory = SellComm:GetFunction("SellInventory")
local BuyUpgrade = Network.Client.GetSignal(ReplicatedStorage.Network, "BuyUpgrade")
local TreeStructure = require(ReplicatedStorage.Framework.Features.Upgrades.TreeStructure)
local Upgrades = require(ReplicatedStorage.Framework.Features.Upgrades.Upgrades)
local TowerComm = Network.ClientComm.new(ReplicatedStorage.Network, false, "Towers")
local PlayTower = TowerComm:GetFunction("PlayTower")
local CancelTower = TowerComm:GetFunction("CancelTower")
local EquipBestTowerTeam = TowerComm:GetSignal("EquipBestTowerTeam")
local QuestComm = Network.ClientComm.new(ReplicatedStorage.Network, false, "QuestService")
local ClaimQuest = QuestComm:GetSignal("Claim")
local BuyQuestShop = QuestComm:GetSignal("Buy")
local TradeComm = Network.ClientComm.new(ReplicatedStorage.Network, false, "TradeService")
local RequestTrade = TradeComm:GetSignal("RequestTrade")
local ChangeTradeOffer = TradeComm:GetSignal("ChangeOffer")
local AdvanceTrade = TradeComm:GetSignal("AdvanceTrade")

-- FUNCTIONS

local function formatMoney(value)
    local suffixes = {
        { 1e21, "sx" },
        { 1e18, "qi" },
        { 1e15, "qb" },
        { 1e12, "y" },
        { 1e9, "b" },
        { 1e6, "m" },
        { 1e3, "k" },
    }
    value = tonumber(value) or 0
    for _, item in ipairs(suffixes) do
        if value >= item[1] then
            return string.format("%.2f%s", value / item[1], item[2]):gsub("%.00", "")
        end
    end
    return tostring(math.floor(value))
end

local function parseUnitValue(value)
    local text = tostring(value or ""):lower():gsub("%s+", "")
    local number, suffix = text:match("^([%d%.]+)([kmbytqsi]*)$")
    number = tonumber(number)
    if not number then
        return nil
    end
    local multipliers = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, y = 1e12, qb = 1e15, qi = 1e18, sx = 1e21 }
    return number * (multipliers[suffix] or 1)
end

local function sortedDiceNames()
    local names = {}
    for name, data in pairs(Dice.GetAll()) do
        if data.price then
            table.insert(names, name)
        end
    end
    table.sort(names, function(a, b)
        return Dice.Get(a).price < Dice.Get(b).price
    end)
    return names
end

local function sortedTowerNames()
    local names = {}
    for name, data in pairs(Towers.GetAll()) do
        table.insert(names, name)
    end
    table.sort(names, function(a, b)
        local first = Towers.Get(a)
        local second = Towers.Get(b)
        return (first and first.order or math.huge) < (second and second.order or math.huge)
    end)
    return names
end

local function getTicketAmount()
    local tickets
    pcall(function()
        local entry = DataController.Inventory.Tickets()
        tickets = entry and entry.amount or 0
    end)
    return tonumber(tickets) or 0
end

local function sortedQuestShopItems()
    local items = {}
    for _, item in ipairs(QuestConfig.Shop) do
        table.insert(items, item.name .. "  (" .. tostring(item.tickets) .. " Tickets)")
    end
    return items
end

local function getQuestShopItem(name)
    for _, item in ipairs(QuestConfig.Shop) do
        if item.name == name then
            return item
        end
    end
end

local function toggleGameUI(candidates)
    local roots = {}
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        table.insert(roots, playerGui)
    end
    pcall(function()
        if typeof(UIReferences.Root) == "Instance" then
            table.insert(roots, UIReferences.Root)
        elseif type(UIReferences.Root) == "table" then
            for _, reference in pairs(UIReferences.Root) do
                if typeof(reference) == "Instance" then
                    table.insert(roots, reference)
                end
            end
        end
    end)

    local wanted = {}
    for _, name in ipairs(candidates) do
        wanted[string.lower(name)] = true
    end

    local function showAncestors(instance)
        local current = instance
        while current do
            if current:IsA("ScreenGui") then
                current.Enabled = true
            elseif current:IsA("GuiObject") then
                current.Visible = true
            end
            current = current.Parent
        end
    end

    local fallbackButton
    for _, root in ipairs(roots) do
        for _, instance in ipairs(root:GetDescendants()) do
            local instanceName = string.lower(instance.Name)
            local exact = wanted[instanceName]
            local fuzzy = false
            for candidate in pairs(wanted) do
                if instanceName:find(candidate, 1, true) then
                    fuzzy = true
                    break
                end
            end
            if exact or fuzzy then
                if instance:IsA("GuiButton") then
                    fallbackButton = fallbackButton or instance
                elseif instance:IsA("GuiObject") then
                    local nextVisible = not instance.Visible
                    if nextVisible then
                        showAncestors(instance)
                    end
                    instance.Visible = nextVisible
                    return true
                end
            end
        end
    end
    if fallbackButton then
        showAncestors(fallbackButton)
        local fired = false
        pcall(function()
            if getconnections then
                for _, eventName in ipairs({ "Activated", "MouseButton1Click", "MouseButton1Down" }) do
                    for _, connection in ipairs(getconnections(fallbackButton[eventName])) do
                        if type(connection.Function) == "function" then
                            connection.Function()
                            fired = true
                            break
                        end
                    end
                    if fired then
                        break
                    end
                end
            end
        end)
        if fired then
            return true
        end
        pcall(function()
            fallbackButton:Activate()
        end)
        return true
    end
    return false
end

local function clickGameButton(candidates)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        return false
    end
    local wanted = {}
    for index, name in ipairs(candidates) do
        wanted[string.lower(name)] = index
    end
    local bestButton
    local bestScore = math.huge
    for _, instance in ipairs(playerGui:GetDescendants()) do
        if instance:IsA("GuiButton") then
            local name = string.lower(instance.Name)
            local rawText = ""
            pcall(function()
                rawText = instance.Text or ""
            end)
            local text = string.lower(tostring(rawText))
            local score = wanted[name] or wanted[text]
            if not score then
                for candidate, index in pairs(wanted) do
                    if #candidate >= 6 and (name:find(candidate, 1, true) or text:find(candidate, 1, true)) then
                        score = index + 20
                        break
                    end
                end
            end
            if score and instance.Visible and score < bestScore then
                bestButton = instance
                bestScore = score
            end
        end
    end
    if not bestButton then
        return false
    end
    local current = bestButton
    while current do
        if current:IsA("ScreenGui") then
            current.Enabled = true
        elseif current:IsA("GuiObject") then
            current.Visible = true
        end
        current = current.Parent
    end
    local fired = false
    pcall(function()
        if getconnections then
            for _, eventName in ipairs({ "Activated", "MouseButton1Click", "MouseButton1Down" }) do
                for _, connection in ipairs(getconnections(bestButton[eventName])) do
                    if type(connection.Function) == "function" then
                        connection.Function()
                        fired = true
                        break
                    end
                end
                if fired then
                    break
                end
            end
        end
    end)
    if not fired then
        pcall(function()
            bestButton:Activate()
        end)
    end
    return true
end

local function openTradePlayerList()
    local playerList
    pcall(function()
        playerList = UIReferences.Menus.PlayerList
    end)
    if typeof(playerList) ~= "Instance" then
        return false
    end
    local ok = pcall(function()
        if MenuController.ActiveMenu() == playerList then
            MenuController.CloseMenu()
        else
            MenuController.OpenMenu(playerList)
        end
    end)
    return ok
end

local function openDiceShopMenu()
    local diceShop
    pcall(function()
        diceShop = UIReferences.Menus.DiceShop
    end)
    if typeof(diceShop) ~= "Instance" then
        return false
    end
    local ok = pcall(function()
        if MenuController.ActiveMenu() == diceShop then
            MenuController.CloseMenu()
        else
            MenuController.OpenMenu(diceShop)
        end
    end)
    return ok
end

local function destroyPreviousGui()
    local containers = {}
    local coreGui
    pcall(function()
        coreGui = cloneref(game:GetService("CoreGui"))
    end)
    if coreGui then
        table.insert(containers, coreGui)
        local robloxGui = coreGui:FindFirstChild("RobloxGui")
        if robloxGui then
            table.insert(containers, robloxGui)
        end
    end
    local hui
    pcall(function()
        if gethui then
            hui = gethui()
        end
    end)
    if typeof(hui) == "Instance" then
        table.insert(containers, hui)
    end
    table.insert(containers, LocalPlayer:WaitForChild("PlayerGui"))
    for _, container in ipairs(containers) do
        local old = container:FindFirstChild("AnimeDiceAutoRollResults")
        if old then
            old:Destroy()
        end
    end
end

local function createResultsGui()
    destroyPreviousGui()
    local gui = Instance.new("ScreenGui")
    gui.Name = "AnimeDiceAutoRollResults"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local parent
    pcall(function()
        if gethui then
            parent = gethui()
        end
    end)
    if not parent then
        pcall(function()
            parent = cloneref(game:GetService("CoreGui"))
        end)
    end
    if not parent then
        parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    local ok = pcall(function()
        gui.Parent = parent
    end)
    if not ok or not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local frame = Instance.new("Frame")
    frame.Name = "Results"
    frame.Size = UDim2.fromOffset(285, 245)
    frame.Position = UDim2.new(1, -305, 0, 24)
    frame.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(75, 185, 255)
    stroke.Transparency = 0.25
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 0, 30)
    title.Position = UDim2.fromOffset(8, 5)
    title.BackgroundTransparency = 1
    title.Text = "Auto Roll Anime | Latest Results"
    title.TextColor3 = Color3.fromRGB(240, 245, 255)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local list = Instance.new("ScrollingFrame")
    list.Name = "ResultList"
    list.Position = UDim2.fromOffset(8, 39)
    list.Size = UDim2.new(1, -16, 1, -47)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 3
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.Parent = frame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list

    local dragging, dragStart, startPosition
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    return gui, list
end

destroyPreviousGui()
local AutoRollToken = 0

local function addResult(resultName, mutation)
    if not ResultsGui or not ResultsGui.Parent or not ResultsList or not ResultsList.Parent then
        ResultsGui, ResultsList = createResultsGui()
    end
    local config = EntryRegistry.getEntryConfig(resultName)
    if not config then
        return
    end

    local chance, income = 0, 0
    pcall(function()
        chance = config.chance({ mutation = mutation })
        income = config.income({ mutation = mutation })
    end)

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 42)
    row.BackgroundColor3 = Color3.fromRGB(34, 39, 49)
    row.BorderSizePixel = 0
    row.LayoutOrder = -math.floor(os.clock() * 1000)
    row.Parent = ResultsList

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 5)
    rowCorner.Parent = row
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.fromOffset(34, 34)
    icon.Position = UDim2.fromOffset(4, 4)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://134876970337785"
    icon.Parent = row

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -45, 1, -4)
    text.Position = UDim2.fromOffset(43, 2)
    text.BackgroundTransparency = 1
    text.TextColor3 = Color3.fromRGB(232, 238, 248)
    text.TextSize = 11
    text.Font = Enum.Font.Gotham
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Center
    text.TextWrapped = true
    text.Text = (mutation and (mutation .. " ") or "") .. resultName .. " | 1 in " .. formatMoney(chance) .. " | $" .. formatMoney(income) .. "/s"
    text.Parent = row

    local count = 0
    for _, child in ipairs(ResultsList:GetChildren()) do
        if child:IsA("Frame") then
            count = count + 1
            if count > 8 then
                child:Destroy()
            end
        end
    end
end

local function setRollingHidden(hidden)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local root = playerGui and playerGui:FindFirstChild("Root")
    local rolling = root and root:FindFirstChild("Rolling")
    if rolling then
        local frame = rolling:FindFirstChild("Frame")
        if frame and frame:IsA("GuiObject") then
            frame.Visible = not hidden
        end
        local dark = rolling:FindFirstChild("DarkBackground")
        if dark and dark:IsA("GuiObject") then
            dark.Visible = not hidden
        end
    end
end

local GameHidden = false
local function setGameHide(hidden)
    if GameHidden == hidden then
        return
    end
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local root = playerGui and playerGui:FindFirstChild("Root")
    local rolling = root and root:FindFirstChild("Rolling")
    local options = rolling and rolling:FindFirstChild("Options")
    local hideButton = options and options:FindFirstChild("HiddenRoll")
    if not hideButton then
        return
    end

    local clicked = false
    for _, eventName in ipairs({ "Activated", "MouseButton1Click", "MouseButton1Down" }) do
        pcall(function()
            for _, connection in ipairs(getconnections(hideButton[eventName])) do
                if type(connection.Function) == "function" then
                    connection.Function()
                    clicked = true
                    break
                end
            end
        end)
        if clicked then
            break
        end
    end
    if not clicked then
        pcall(function()
            if hideButton:IsA("GuiButton") then
                hideButton:Activate()
                clicked = true
            end
        end)
    end
    if clicked then
        GameHidden = hidden
    end
end

local function buySelectedDice(name)
    local data = Dice.Get(name)
    if not data or not data.price then
        return
    end
    local owned = false
    pcall(function()
        owned = DataController.OwnedDice[name]() == true
    end)
    if owned then
        EquipDice:Fire(name)
    elseif DataController.Money() >= data.price then
        BuyDice:Fire(name)
    end
end

local function buyNextAffordableDice()
    local selected = Config["Selected Dice"]
    local selectedData = Dice.Get(selected)
    local selectedOwned = selectedData and DataController.OwnedDice[selected]() == true
    if selectedData and not selectedOwned and DataController.Money() >= selectedData.price then
        BuyDice:Fire(selected)
        return
    end
    for _, name in ipairs(sortedDiceNames()) do
        local data = Dice.Get(name)
        local owned = DataController.OwnedDice[name]() == true
        if not owned and DataController.Money() >= data.price then
            BuyDice:Fire(name)
            Config["Selected Dice"] = name
            return
        end
    end
end

-- LOOPS

local AutoRollRunning = false

Ex_Function["Auto Roll Anime"] = function()
    if AutoRollRunning then
        return
    end
    AutoRollRunning = true
    local token = AutoRollToken
    setGameHide(true)
    while Config["Auto Roll Anime"] and token == AutoRollToken and task.wait(0.12) do
            local ok, err = pcall(function()
                setRollingHidden(true)
                local results = RollDice()
            end)
            if not ok then
                warn("[Anime Dice] Auto Roll error:", err)
            end
    end
    setRollingHidden(false)
    setGameHide(false)
    AutoRollRunning = false
end

if _G.AnimeDiceAutoRollLoop then
    pcall(task.cancel, _G.AnimeDiceAutoRollLoop)
end
_G.AnimeDiceAutoRollLoop = task.spawn(function()
    while task.wait(0.2) do
        if Config["Auto Roll Anime"] and not AutoRollRunning then
            task.spawn(Ex_Function["Auto Roll Anime"])
        end
    end
end)
if _G.AnimeDiceAutoRollConnection then
    pcall(function() _G.AnimeDiceAutoRollConnection:Disconnect() end)
end
local rollClock = 0
_G.AnimeDiceAutoRollConnection = RunService.Heartbeat:Connect(function(delta)
    rollClock = rollClock + delta
    if Config["Auto Roll Anime"] and rollClock >= 0.2 and not AutoRollRunning then
        rollClock = 0
        task.spawn(Ex_Function["Auto Roll Anime"])
    end
end)

Ex_Function["Auto Upgrade Dice"] = function()
    while Config["Auto Upgrade Dice"] and task.wait(0.5) do
        pcall(function()
            buyNextAffordableDice()
        end)
    end
end

Ex_Function["Auto Smart Equip Anime"] = function()
    while Config["Auto Smart Equip Anime"] and task.wait(1) do
        pcall(function()
            EquipBest:Fire()
        end)
    end
end

Ex_Function["Auto Money"] = function()
    while Config["Auto Money"] and task.wait(0.75) do
        pcall(function()
            for slot = 1, 14 do
                CollectBalance:Fire(slot)
            end
        end)
    end
end

Ex_Function["Auto Upgrade Anime"] = function()
    while Config["Auto Upgrade Anime"] and task.wait(0.8) do
        pcall(function()
            LevelUpSlot:Fire(tonumber(Config["Upgrade Anime Slot"]) or 1)
        end)
    end
end

Ex_Function["Auto Rebirth"] = function()
    while Config["Auto Rebirth"] and task.wait(0.6) do
        pcall(function()
            local current = DataController.Rebirth()
            local nextRebirth = Rebirths.GetNext(current)
            if nextRebirth and DataController.Money() >= nextRebirth.cost then
                RebirthSignal:Fire()
            end
        end)
    end
end

Ex_Function["Auto Sell Unit"] = function()
    while Config["Auto Sell Unit"] and task.wait(0.6) do
        pcall(function()
            local threshold = tonumber(Config["Auto Sell Threshold"]) or 0
            if threshold <= 0 then return end
            local inventory = DataController.Inventory()
            local sellKeys = {}
            for key, entry in pairs(inventory) do
                local cfg = EntryRegistry.getEntryConfig(entry.name)
                if cfg and cfg.kind == "Unit" then
                    local chance = cfg.chance(entry.attributes or {})
                    if chance <= threshold then
                        table.insert(sellKeys, key)
                    end
                end
            end
            if #sellKeys > 0 then
                SellInventory(sellKeys)
            end
        end)
    end
end

local function getNextUpgrade(branch)
    local roots = TreeStructure.GetChildren("Start")
    local root
    for _, name in ipairs(roots) do
        if tostring(name):lower():find(tostring(branch):lower(), 1, true) then
            root = name
            break
        end
    end
    if not root then return nil end
    local queue = { root }
    local index = 1
    while queue[index] do
        local name = queue[index]
        index = index + 1
        if not DataController.Upgrades[name]() then
            return name
        end
        for _, child in ipairs(TreeStructure.GetChildren(name)) do
            table.insert(queue, child)
        end
    end
end

Ex_Function["Auto Upgrade"] = function()
    while Config["Auto Upgrade"] and task.wait(0.6) do
        pcall(function()
            local name = getNextUpgrade(Config["Upgrade Branch"])
            local data = name and Upgrades[name]
            if name and data and DataController.Money() >= data.price then
                BuyUpgrade:Fire(name)
            end
        end)
    end
end

Ex_Function["Auto Towers"] = function()
    while Config["Auto Towers"] do
        local ok, err = pcall(function()
            local towerName = Config["Selected Tower"]
            if towerName and Towers.Get(towerName) then
                if Config["Auto Equip Best Tower Anime"] then
                    EquipBestTowerTeam:Fire()
                    task.wait(0.25)
                end

                -- Use the game's controller so its own floor sequence and UI state stay in sync.
                local started = TowerController.startTower(towerName)
                -- Clear a stale server session once, then retry the normal game flow.
                if not started then
                    pcall(CancelTower)
                    task.wait(0.35)
                    started = TowerController.startTower(towerName)
                end
                if started then
                    local screen = UIReferences.Root.Tower.Screen
                    task.wait(0.2)
                    local timeout = 0
                    while Config["Auto Towers"] and timeout < 600 do
                        timeout = timeout + 1
                        if timeout > 4 and not screen.Visible then
                            break
                        end
                        task.wait(0.25)
                    end
                end
            end
        end)
        if not ok then
            warn("Auto Towers error:", err)
        end
        task.wait(3)
    end
end

Ex_Function["Auto Equip Best Tower Anime"] = function()
    while Config["Auto Equip Best Tower Anime"] and task.wait(1) do
        pcall(function()
            EquipBestTowerTeam:Fire()
        end)
    end
end

local function claimCompletedQuests()
    local now = math.floor(workspace:GetServerTimeNow())
    for _, period in ipairs({ "Daily", "Weekly" }) do
        pcall(function()
            local state = DataController.Quests[period]()
            if not state then return end
            for _, quest in ipairs(QuestConfig.Periods[period].quests) do
                local progress = tonumber(state.progress[quest.id]) or 0
                if progress >= quest.target and not state.claimed[quest.id] then
                    ClaimQuest:Fire(period, quest.id, state.expiresAt)
                end
            end
        end)
    end
end

local function buySelectedQuestShopItem()
    local itemName = Config["Selected Quest Shop Item"]
    local item = getQuestShopItem(itemName)
    if item and (item.gamepass or getTicketAmount() >= (tonumber(item.tickets) or math.huge)) then
        BuyQuestShop:Fire(item.name)
    end
end

Ex_Function["Auto Claim Quest"] = function()
    while Config["Auto Claim Quest"] and task.wait(1) do
        pcall(claimCompletedQuests)
    end
end

Ex_Function["Auto Buy Shop Quest"] = function()
    while Config["Auto Buy Shop Quest"] and task.wait(1.2) do
        pcall(function()
            local itemName = Config["Selected Quest Shop Item"]
            local item = getQuestShopItem(itemName)
            if item and not item.gamepass and getTicketAmount() >= (tonumber(item.tickets) or math.huge) then
                BuyQuestShop:Fire(item.name)
            end
        end)
    end
end

local function tradePlayers()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(names, player.DisplayName .. " (" .. player.Name .. ")")
        end
    end
    table.sort(names)
    return names
end

local function tradeUnits()
    local units = {}
    for key, entry in pairs(DataController.Inventory()) do
        local cfg = EntryRegistry.getEntryConfig(entry.name)
        if cfg and cfg.kind == "Unit" then
            local income = tonumber(cfg.income(entry.attributes or {})) or 0
            table.insert(units, {key = key, amount = tonumber(entry.amount) or 1, income = income})
        end
    end
    table.sort(units, function(a, b)
        if Config["Trade Unit Order"] == "Lowest Income" then return a.income < b.income end
        return a.income > b.income
    end)
    return units
end

local function tradeInventoryItems()
    local items = {}
    for key, entry in pairs(DataController.Inventory()) do
        local config = EntryRegistry.getEntryConfig(entry.name)
        local kind = config and config.kind or entry.kind
        if kind ~= "Unit" then
            local name = tostring(entry.name or key)
            local amount = tonumber(entry.amount) or 1
            table.insert(items, {
                Key = key,
                Title = name .. "  (x" .. tostring(amount) .. ")",
                Name = name,
                Amount = amount,
            })
        end
    end
    table.sort(items, function(a, b)
        return a.Title:lower() < b.Title:lower()
    end)
    return items
end

local function selectedTradeKeys()
    local keys = {}
    for _, selected in ipairs(Config["Trade Items"] or {}) do
        local key = type(selected) == "table" and selected.Key or selected
        if key ~= nil then
            keys[key] = true
        end
    end
    return keys
end

local function tradeOnce()
    local selected = tostring(Config["Trade Player"] or "")
    local username = selected:match("%((.-)%)") or selected
    local target = Players:FindFirstChild(username)
    if not target or target == LocalPlayer then return end
    RequestTrade:Fire(target)
    local tradeRoot = UIReferences.Root.Trading
    local screen = tradeRoot and tradeRoot.TradeScreen
    local waited = 0
    while screen and not screen.Visible and waited < 30 do
        waited = waited + 1
        task.wait(0.25)
    end
    if not screen or not screen.Visible then return end
    local selectedKeys = selectedTradeKeys()
    local hasSelectedItems = next(selectedKeys) ~= nil
    if hasSelectedItems then
        for key in pairs(selectedKeys) do
            ChangeTradeOffer:Fire(key, 1)
        end
    else
        local units = tradeUnits()
        for index, unit in ipairs(units) do
            if index <= (tonumber(Config["Trade Unit Count"]) or 1) then
                ChangeTradeOffer:Fire(unit.key, 1)
            end
        end
    end
    AdvanceTrade:Fire()
    task.wait(0.2)
    AdvanceTrade:Fire()
end

Ex_Function["Auto Trade"] = function()
    while Config["Auto Trade"] do
        pcall(tradeOnce)
        task.wait(8)
    end
end

-- ADVANCED ANTI-AFK
-- Uses Roblox's idle signal as the immediate path and a low-frequency background
-- input pulse as a fallback. The global handles make re-executing this script safe.
if _G.AnimeDiceAntiAFKConnection then
    pcall(function()
        _G.AnimeDiceAntiAFKConnection:Disconnect()
    end)
end
if _G.AnimeDiceAntiAFKLoop then
    pcall(task.cancel, _G.AnimeDiceAntiAFKLoop)
end

local function antiAFKPulse()
    pcall(function()
        VirtualUser:CaptureController()
        local camera = workspace.CurrentCamera
        local position = camera and (camera.ViewportSize / 2) or Vector2.new(0, 0)
        -- ClickButton2 is supported by most executors; Button2Down/Up is a
        -- compatibility fallback for clients that do not expose the helper.
        local clicked = pcall(function()
            VirtualUser:ClickButton2(position)
        end)
        if not clicked then
            VirtualUser:Button2Down(position, camera and camera.CFrame or CFrame.new())
            task.wait(0.05)
            VirtualUser:Button2Up(position, camera and camera.CFrame or CFrame.new())
        end
    end)
end

_G.AnimeDiceAntiAFKConnection = LocalPlayer.Idled:Connect(function()
    if Config["Anti AFK"] then
        antiAFKPulse()
    end
end)

_G.AnimeDiceAntiAFKLoop = task.spawn(function()
    while task.wait(math.random(45, 75)) do
        if Config["Anti AFK"] then
            antiAFKPulse()
        end
    end
end)

if _G.AnimeDiceAutoSellConnection then
    pcall(function() _G.AnimeDiceAutoSellConnection:Disconnect() end)
end
local autoSellClock = 0
_G.AnimeDiceAutoSellConnection = RunService.Heartbeat:Connect(function(delta)
    autoSellClock = autoSellClock + delta
    if Config["Auto Sell Unit"] and autoSellClock >= 0.6 then
        autoSellClock = 0
        pcall(function()
            local threshold = tonumber(Config["Auto Sell Threshold"]) or 0
            if threshold <= 0 then return end
            local sellKeys = {}
            for key, entry in pairs(DataController.Inventory()) do
                local cfg = EntryRegistry.getEntryConfig(entry.name)
                if cfg and cfg.kind == "Unit" and cfg.chance(entry.attributes or {}) <= threshold then
                    table.insert(sellKeys, key)
                end
            end
            if #sellKeys > 0 then
                SellInventory(sellKeys)
            end
        end)
    end
end)

if _G.AnimeDiceUpgradeConnection then
    pcall(function() _G.AnimeDiceUpgradeConnection:Disconnect() end)
end
local upgradeClock = 0
_G.AnimeDiceUpgradeConnection = RunService.Heartbeat:Connect(function(delta)
    upgradeClock = upgradeClock + delta
    if Config["Auto Upgrade Dice"] and upgradeClock >= 0.6 then
        upgradeClock = 0
        pcall(buyNextAffordableDice)
    end
end)
if _G.AnimeDiceSmartEquipConnection then
    pcall(function() _G.AnimeDiceSmartEquipConnection:Disconnect() end)
end
local smartEquipClock = 0
_G.AnimeDiceSmartEquipConnection = RunService.Heartbeat:Connect(function(delta)
    smartEquipClock = smartEquipClock + delta
    if Config["Auto Smart Equip Anime"] and smartEquipClock >= 1 then
        smartEquipClock = 0
        pcall(function()
            EquipBest:Fire()
        end)
    end
end)
if _G.AnimeDiceAutoMoneyConnection then
    pcall(function() _G.AnimeDiceAutoMoneyConnection:Disconnect() end)
end
local autoMoneyClock = 0
_G.AnimeDiceAutoMoneyConnection = RunService.Heartbeat:Connect(function(delta)
    autoMoneyClock = autoMoneyClock + delta
    if Config["Auto Money"] and autoMoneyClock >= 0.75 then
        autoMoneyClock = 0
        pcall(function()
            for slot = 1, 14 do
                CollectBalance:Fire(slot)
            end
        end)
    end
end)
if _G.AnimeDiceAutoUpgradeAnimeConnection then
    pcall(function() _G.AnimeDiceAutoUpgradeAnimeConnection:Disconnect() end)
end
local autoUpgradeAnimeClock = 0
_G.AnimeDiceAutoUpgradeAnimeConnection = RunService.Heartbeat:Connect(function(delta)
    autoUpgradeAnimeClock = autoUpgradeAnimeClock + delta
    if Config["Auto Upgrade Anime"] and autoUpgradeAnimeClock >= 0.8 then
        autoUpgradeAnimeClock = 0
        pcall(function()
            LevelUpSlot:Fire(tonumber(Config["Upgrade Anime Slot"]) or 1)
        end)
    end
end)
if _G.AnimeDiceAutoRebirthConnection then
    pcall(function() _G.AnimeDiceAutoRebirthConnection:Disconnect() end)
end
local autoRebirthClock = 0
_G.AnimeDiceAutoRebirthConnection = RunService.Heartbeat:Connect(function(delta)
    autoRebirthClock = autoRebirthClock + delta
    if Config["Auto Rebirth"] and autoRebirthClock >= 0.6 then
        autoRebirthClock = 0
        pcall(function()
            local current = DataController.Rebirth()
            local nextRebirth = Rebirths.GetNext(current)
            if nextRebirth and DataController.Money() >= nextRebirth.cost then
                RebirthSignal:Fire()
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(0.25) do
        if Config["Auto Roll Anime"] then
            if not AutoRollRunning then
                task.spawn(Ex_Function["Auto Roll Anime"])
            end
            setRollingHidden(true)
            setGameHide(true)
        end
    end
end)

-- UI

local coreGui
pcall(function()
    coreGui = cloneref(game:GetService("CoreGui"))
end)
local robloxGui = coreGui and coreGui:FindFirstChild("RobloxGui")
local oldWindUI = robloxGui and robloxGui:FindFirstChild("WindUI")
if oldWindUI then
    oldWindUI:Destroy()
end

local Window = loadstring(game:HttpGet("https://raw.githubusercontent.com/latavee1399-dev/AKO/refs/heads/main/CC%20ui"))()
local AutoGameTab = Window:Tab({
    Title = "Auto Game",
    Desc = "Automation features",
    Icon = "gamepad-2",
})

local AnimeSection = AutoGameTab:Section({
    Title = "Auto Roll Anime",
    Desc = "Roll silently and track results",
    Icon = "dices",
    Side = "left",
})

local AntiAFKSection = AutoGameTab:Section({
    Title = "Background Protection",
    Desc = "Keep the session active while automation runs",
    Icon = "shield-check",
    Side = "right",
})

AntiAFKSection:Toggle({
    Title = "Advanced Anti AFK",
    Desc = "Reconnect idle detection and send safe background input pulses",
    Icon = "user-round-check",
    Value = Config["Anti AFK"],
    Callback = function(state)
        Config["Anti AFK"] = state
        if state then
            antiAFKPulse()
        end
    end,
})

local AutoPlaceSection = AutoGameTab:Section({
    Title = "Auto Place Anime",
    Desc = "Anime placement controls",
    Icon = "layout-grid",
    Side = "left",
})

AutoPlaceSection:Toggle({
    Title = "Auto Smart Equip Anime",
    Desc = "Replace the lowest-income placed unit with your best unit",
    Icon = "layout-grid",
    Value = Config["Auto Smart Equip Anime"],
    Callback = function(state)
        Config["Auto Smart Equip Anime"] = state
        if state then
            task.spawn(Ex_Function["Auto Smart Equip Anime"])
        end
    end,
})

local UpgradeSection = AutoGameTab:Section({
    Title = "Auto Upgrade",
    Desc = "Upgrade a selected upgrade branch when affordable",
    Icon = "chevrons-up",
    Side = "right",
})
local upgradeBranches = { "Money", "Luck", "Damage", "Unit Storage", "Sell", "Roll Speed", "Fortune", "Health", "Walkspeed" }
UpgradeSection:Dropdown({
    Title = "Upgrade Branch",
    Desc = "Choose the upgrade path",
    Values = upgradeBranches,
    SearchBarEnabled = true,
    Default = Config["Upgrade Branch"],
    Callback = function(value)
        Config["Upgrade Branch"] = tostring(value)
    end,
})
UpgradeSection:Toggle({
    Title = "Auto Upgrade",
    Desc = "Buy the next upgrade only when you have enough money",
    Icon = "chevrons-up",
    Value = Config["Auto Upgrade"],
    Callback = function(state)
        Config["Auto Upgrade"] = state
        if state then task.spawn(Ex_Function["Auto Upgrade"]) end
    end,
})

AutoPlaceSection:Toggle({
    Title = "Auto Rebirth",
    Desc = "Rebirth immediately when the next requirement is affordable",
    Icon = "refresh-cw",
    Value = Config["Auto Rebirth"],
    Callback = function(state)
        Config["Auto Rebirth"] = state
        if state then
            task.spawn(Ex_Function["Auto Rebirth"])
        end
    end,
})

local slotValues = {}
for slot = 1, 14 do
    table.insert(slotValues, "Slot " .. slot)
end

AutoPlaceSection:Dropdown({
    Title = "Upgrade Slot",
    Desc = "Choose the Anime slot to upgrade",
    Values = slotValues,
    SearchBarEnabled = true,
    Default = "Slot " .. tostring(Config["Upgrade Anime Slot"]),
    Callback = function(value)
        local slot = tonumber(tostring(value):match("%d+"))
        if slot then
            Config["Upgrade Anime Slot"] = slot
        end
    end,
})

AutoPlaceSection:Toggle({
    Title = "Auto Upgrade Anime",
    Desc = "Automatically upgrade the selected Anime slot",
    Icon = "chevrons-up",
    Value = Config["Auto Upgrade Anime"],
    Callback = function(state)
        Config["Auto Upgrade Anime"] = state
        if state then
            task.spawn(Ex_Function["Auto Upgrade Anime"])
        end
    end,
})

AutoPlaceSection:Toggle({
    Title = "Auto Money",
    Desc = "Automatically collect money from every placed anime",
    Icon = "coins",
    Value = Config["Auto Money"],
    Callback = function(state)
        Config["Auto Money"] = state
        if state then
            task.spawn(Ex_Function["Auto Money"])
        end
    end,
})
AnimeSection:Toggle({
    Title = "Auto Roll Anime",
    Desc = "Hide the roll animation while rolling automatically",
    Icon = "repeat",
    Value = Config["Auto Roll Anime"],
    Callback = function(state)
        Config["Auto Roll Anime"] = state
        AutoRollToken = AutoRollToken + 1
        pcall(function()
            SetAutoRoll:Fire(state)
        end)
        if state then
            setRollingHidden(true)
            task.spawn(Ex_Function["Auto Roll Anime"])
        else
            setRollingHidden(false)
            setGameHide(false)
        end
    end,
})

AnimeSection:Input({
    Title = "Auto Sell 1 In",
    Desc = "Examples: 4000, 4k, 2.5m",
    Placeholder = "Enter chance (e.g. 4k)",
    Callback = function(value)
        local parsed = parseUnitValue(value)
        if parsed then
            Config["Auto Sell Threshold"] = parsed
        end
    end,
})

AnimeSection:Toggle({
    Title = "Auto Sell Unit",
    Desc = "Sell units with chance equal to or below the entered value",
    Icon = "trash-2",
    Value = Config["Auto Sell Unit"],
    Callback = function(state)
        Config["Auto Sell Unit"] = state
        if state then
            task.spawn(Ex_Function["Auto Sell Unit"])
        end
    end,
})
local DiceSection = AnimeSection

local diceValues = {}
for _, name in ipairs(sortedDiceNames()) do
    local data = Dice.Get(name)
    table.insert(diceValues, name .. "  ($" .. formatMoney(data.price) .. ")")
end

local selectedDice = Config["Selected Dice"]
DiceSection:Dropdown({
    Title = "Select Dice",
    Desc = "Search by name and price",
    Values = diceValues,
    SearchBarEnabled = true,
    Default = selectedDice,
    Callback = function(value)
        local name = tostring(value):match("^(.-)%s+%(%$") or tostring(value)
        if Dice.Get(name) then
            selectedDice = name
            Config["Selected Dice"] = name
        end
    end,
})
DiceSection:Toggle({
    Title = "Auto Upgrade Dice",
    Desc = "Purchase the selected dice whenever affordable",
    Icon = "chevrons-up",
    Value = Config["Auto Upgrade Dice"],
    Callback = function(state)
        Config["Auto Upgrade Dice"] = state
        if state then
            task.spawn(Ex_Function["Auto Upgrade Dice"])
        end
    end,
})
DiceSection:Button({
    Title = "Buy Selected Dice",
    Desc = "Buy or equip the selected dice",
    Icon = "shopping-cart",
    Color = Color3.fromRGB(45, 190, 95),
    Callback = function()
        buySelectedDice(selectedDice)
    end,
})

-- Start features when a saved/global Config already has them enabled.
if Config["Auto Roll Anime"] then
    pcall(function()
        SetAutoRoll:Fire(true)
    end)
    task.spawn(Ex_Function["Auto Roll Anime"])
end
if Config["Auto Upgrade Dice"] then
    task.spawn(Ex_Function["Auto Upgrade Dice"])
end
if Config["Auto Smart Equip Anime"] then
    task.spawn(Ex_Function["Auto Smart Equip Anime"])
end
if Config["Auto Money"] then
    task.spawn(Ex_Function["Auto Money"])
end
if Config["Auto Upgrade Anime"] then
    task.spawn(Ex_Function["Auto Upgrade Anime"])
end
if Config["Auto Rebirth"] then
    task.spawn(Ex_Function["Auto Rebirth"])
end
if Config["Auto Sell Unit"] then
    task.spawn(Ex_Function["Auto Sell Unit"])
end
if Config["Auto Upgrade"] then
    task.spawn(Ex_Function["Auto Upgrade"])
end
if Config["Auto Towers"] then
    task.spawn(Ex_Function["Auto Towers"])
end
if Config["Auto Equip Best Tower Anime"] then
    task.spawn(Ex_Function["Auto Equip Best Tower Anime"])
end
if Config["Auto Claim Quest"] then
    task.spawn(Ex_Function["Auto Claim Quest"])
end
if Config["Auto Buy Shop Quest"] then
    task.spawn(Ex_Function["Auto Buy Shop Quest"])
end

local EasyOpenTab = Window:Tab({
    Title = "Easy Open",
    Desc = "Quickly open game interfaces",
    Icon = "panel-top-open",
})

local EasyOpenSection = EasyOpenTab:Section({
    Title = "Easy Open",
    Desc = "Open commonly used game interfaces",
    Icon = "external-link",
    Side = "left",
})

local function addEasyOpenButton(title, description, icon, candidates)
    EasyOpenSection:Button({
        Title = title,
        Desc = description,
        Icon = icon,
        Color = Color3.fromRGB(45, 190, 95),
        Callback = function()
            local toggled
            if title == "Open Trade" then
                toggled = openTradePlayerList()
                if not toggled then
                    toggled = clickGameButton({ "TradeButton", "TradeMenuButton", "TradeIcon", "Trade" })
                end
            elseif title == "Open Dice Shop" then
                toggled = openDiceShopMenu()
                if not toggled then
                    toggled = clickGameButton({ "DiceShopButton", "DiceShopMenuButton", "DiceShopIcon", "Dice Shop", "DiceShop" })
                end
            end
            if not toggled then
                toggled = toggleGameUI(candidates)
            end
            if not toggled then
                warn("[Anime Dice] Easy Open UI not found: " .. title)
            end
        end,
    })
end

addEasyOpenButton("Open Dice Shop", "Open the Dice Shop interface", "shopping-bag", {
    "DiceShop", "DiceShopUI", "DiceShopFrame", "DiceShopScreen", "Dice Shop", "Dice",
})
addEasyOpenButton("Open Quest", "Open the Quest interface", "scroll-text", {
    "Quest", "Quests", "QuestUI", "QuestFrame", "QuestScreen",
})
addEasyOpenButton("Open Trade", "Open the Trade interface", "arrow-left-right", {
    "Trading", "Trade", "TradeUI", "TradeFrame", "TradeScreen", "TradeMenu", "TradeWindow",
})
addEasyOpenButton("Open Grader", "Open the Grader interface", "graduation-cap", {
    "Grader", "GraderUI", "GraderFrame", "Grade", "GradeUI",
})
addEasyOpenButton("Open Traits", "Open the Traits interface", "sparkles", {
    "Traits", "Trait", "TraitsUI", "TraitUI", "TraitsFrame", "TraitFrame",
})

local TowerTab = Window:Tab({
    Title = "Tower",
    Desc = "Tower features",
    Icon = "shield",
})

local TowerSection = TowerTab:Section({
    Title = "Auto Towers",
    Desc = "Automatically enter the selected Tower and prepare your best Anime team",
    Icon = "castle",
    Side = "left",
})

local towerValues = sortedTowerNames()
local selectedTower = Config["Selected Tower"]
if not Towers.Get(selectedTower) then
    selectedTower = towerValues[1]
    Config["Selected Tower"] = selectedTower
end

TowerSection:Dropdown({
    Title = "Tower Level",
    Desc = "Choose which Tower to enter",
    Values = towerValues,
    SearchBarEnabled = true,
    Default = selectedTower,
    Callback = function(value)
        local name = tostring(value)
        if Towers.Get(name) then
            Config["Selected Tower"] = name
        end
    end,
})

TowerSection:Toggle({
    Title = "Auto Towers",
    Desc = "Automatically enter the selected Tower when available",
    Icon = "castle",
    Value = Config["Auto Towers"],
    Callback = function(state)
        Config["Auto Towers"] = state
        if state then
            task.spawn(Ex_Function["Auto Towers"])
        end
    end,
})

TowerSection:Toggle({
    Title = "Auto Equip Best Anime Unit",
    Desc = "Use the game's Tower system to equip the strongest Anime units",
    Icon = "trophy",
    Value = Config["Auto Equip Best Tower Anime"],
    Callback = function(state)
        Config["Auto Equip Best Tower Anime"] = state
        if state then
            task.spawn(Ex_Function["Auto Equip Best Tower Anime"])
        end
    end,
})

local QuestTab = Window:Tab({
    Title = "Quest",
    Desc = "Quest automation and shop",
    Icon = "scroll-text",
})

local QuestSection = QuestTab:Section({
    Title = "Quest",
    Desc = "Claim quests and buy from the Quest Shop",
    Icon = "scroll-text",
    Side = "left",
})

local TicketInfo = QuestSection:Paragraph({
    Title = "Quest Tickets",
    Desc = "Tickets: " .. formatMoney(getTicketAmount()),
})

QuestSection:Toggle({
    Title = "Auto Claim Quest",
    Desc = "Claim completed Daily and Weekly quests automatically",
    Icon = "badge-check",
    Value = Config["Auto Claim Quest"],
    Callback = function(state)
        Config["Auto Claim Quest"] = state
        if state then
            task.spawn(Ex_Function["Auto Claim Quest"])
        end
    end,
})

local questShopValues = sortedQuestShopItems()
local selectedQuestItem = Config["Selected Quest Shop Item"]
if not getQuestShopItem(selectedQuestItem) then
    selectedQuestItem = QuestConfig.Shop[1].name
    Config["Selected Quest Shop Item"] = selectedQuestItem
end

QuestSection:Dropdown({
    Title = "Quest Shop Item",
    Desc = "Search and select an item to buy",
    Values = questShopValues,
    SearchBarEnabled = true,
    Default = selectedQuestItem,
    Callback = function(value)
        local name = tostring(value):match("^(.-)%s+%(%d+ Tickets%)$") or tostring(value)
        if getQuestShopItem(name) then
            Config["Selected Quest Shop Item"] = name
        end
    end,
})

QuestSection:Toggle({
    Title = "Auto Buy Shop Quest",
    Desc = "Automatically buy the selected Quest Shop item when affordable",
    Icon = "shopping-cart",
    Value = Config["Auto Buy Shop Quest"],
    Callback = function(state)
        Config["Auto Buy Shop Quest"] = state
        if state then
            task.spawn(Ex_Function["Auto Buy Shop Quest"])
        end
    end,
})

QuestSection:Button({
    Title = "Buy Shop Quest",
    Desc = "Buy the selected item once",
    Icon = "shopping-cart",
    Color = Color3.fromRGB(45, 190, 95),
    Callback = buySelectedQuestShopItem,
})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            TicketInfo:SetDesc("Tickets: " .. formatMoney(getTicketAmount()))
        end)
    end
end)

local TradeTab = Window:Tab({Title = "Trade", Desc = "Trade automation", Icon = "arrow-left-right"})
local TradeSection = TradeTab:Section({Title = "Auto Trade", Desc = "Choose a player and send selected Anime units or items", Icon = "repeat-2", Side = "left"})
local tradePlayerValues = tradePlayers()
if #tradePlayerValues == 0 then tradePlayerValues = {"No players"} end
local tradePlayerDropdown = TradeSection:Dropdown({Title = "Player", Desc = "Select a player to trade with", Values = tradePlayerValues, SearchBarEnabled = true, Default = Config["Trade Player"] ~= "" and Config["Trade Player"] or tradePlayerValues[1], Callback = function(value)
    if tostring(value) ~= "No players" then Config["Trade Player"] = tostring(value) end
end})
TradeSection:Button({Title = "Refresh Players", Desc = "Refresh the player list", Icon = "refresh-cw", Color = Color3.fromRGB(210, 55, 55), Callback = function()
    local values = tradePlayers(); if #values == 0 then values = {"No players"} end
    pcall(function() tradePlayerDropdown:Refresh(values) end)
end})
local tradeItemsDropdown
do
    local initialValues = tradeInventoryItems()
    local initialDefaults = {}
    for _, selected in ipairs(Config["Trade Items"] or {}) do
        local selectedKey = type(selected) == "table" and selected.Key or selected
        local selectedTitle = type(selected) == "table" and selected.Title or nil
        for _, item in ipairs(initialValues) do
            if item.Key == selectedKey or item.Title == selectedTitle then
                table.insert(initialDefaults, item)
                break
            end
        end
    end
    tradeItemsDropdown = TradeSection:Dropdown({
        Title = "Trade Items",
        Desc = "Pick one or more items to include in the trade offer (leave empty to use Unit Income)",
        Values = initialValues,
        Value = initialDefaults,
        Multi = true,
        SearchBarEnabled = true,
        Callback = function(value)
            local list = {}
            if type(value) == "table" then
                for _, item in ipairs(value) do
                    if type(item) == "table" then
                        table.insert(list, { Key = item.Key, Title = item.Title, Name = item.Name, Amount = item.Amount })
                    else
                        table.insert(list, item)
                    end
                end
            end
            Config["Trade Items"] = list
        end,
    })
end
TradeSection:Button({
    Title = "Refresh Items",
    Desc = "Reload items from your current inventory",
    Icon = "refresh-cw",
    Color = Color3.fromRGB(75, 140, 230),
    Callback = function()
        pcall(function()
            tradeItemsDropdown:Refresh(tradeInventoryItems())
        end)
    end,
})
TradeSection:Dropdown({Title = "Unit Income", Desc = "Fallback sort when no trade items are picked", Values = {"Highest Income", "Lowest Income"}, SearchBarEnabled = true, Default = Config["Trade Unit Order"], Callback = function(value) Config["Trade Unit Order"] = tostring(value) end})
local tradeCounts = {}; for i = 1, 10 do table.insert(tradeCounts, tostring(i)) end
TradeSection:Dropdown({Title = "Unit Count", Desc = "Number of units to offer when using fallback sort", Values = tradeCounts, SearchBarEnabled = true, Default = tostring(Config["Trade Unit Count"]), Callback = function(value) Config["Trade Unit Count"] = tonumber(value) or 1 end})
TradeSection:Toggle({Title = "Auto Trade", Desc = "Automatically send a trade request", Icon = "repeat-2", Value = Config["Auto Trade"], Callback = function(state)
    Config["Auto Trade"] = state; if state then task.spawn(Ex_Function["Auto Trade"]) end
end})
TradeSection:Button({Title = "Trade Once", Desc = "Send one trade request and offer", Icon = "arrow-left-right", Color = Color3.fromRGB(45, 190, 95), Callback = function() pcall(tradeOnce) end})

Window:InitBaseTabs()
