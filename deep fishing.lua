if not game:IsLoaded() then
    game.Loaded:Wait()
end

local cloneref = cloneref or function(instance)
    return instance
end

-- SERVICES
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- CONFIG
Config = Config or {
    ["Auto Rods"] = false,
    ["Auto Upgrade"] = false,
    ["Selected Upgrades"] = {},
    ["Auto Buy Rods"] = false,
    ["Selected Rods"] = {},
    ["Auto Buy Shop Items"] = false,
    ["Selected Shop Items"] = {},
    ["Selected Island"] = "Fernshore",
    ["Auto Sell"] = false,
    ["Auto Sell Rarities"] = {},
    ["Auto Sell Threshold"] = "10",
    ["Auto Trade"] = false,
    ["Auto Claim Trade"] = false,
    ["Trade Player"] = "",
}

-- MODULES
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local Client = PlayerScripts:WaitForChild("Client")
local Controllers = Client:WaitForChild("Controllers")
local FishingModule = Controllers:WaitForChild("Fishing")
local FishingController = require(FishingModule)
local AutoFishingModule = FishingModule:WaitForChild("AutoFishing")
local AutoFishingController = require(AutoFishingModule)

while rawget(FishingController, "AutoFishing") ~= AutoFishingController or AutoFishingController.On == nil do
    task.wait(0.1)
end

-- SHOP DATA
local UpgradeConfig = FishingController.Config.UpgradesConfig
local OfflineConfig = FishingController.Config.OfflineConfig
local PondConfig = FishingController.Config.PondConfig
local WorldsConfig = FishingController.Config.WorldsConfig
local ShopItemOptions = {}
local ShopItemsByOption = {}
local BaitShopItems = {}
local PondFoodItems = {}
local IslandOptions = {}
local IslandKeysByOption = {}

for WorldKey, WorldData in pairs(WorldsConfig.Worlds) do
    local Option = WorldData.DisplayName or WorldData.UIName
    table.insert(IslandOptions, Option)
    IslandKeysByOption[Option] = WorldKey
end

table.sort(IslandOptions, function(FirstOption, SecondOption)
    local FirstWorld = WorldsConfig.Get(IslandKeysByOption[FirstOption])
    local SecondWorld = WorldsConfig.Get(IslandKeysByOption[SecondOption])

    return FirstWorld.WorldNumber < SecondWorld.WorldNumber
end)

for ItemKey, ItemData in pairs(FishingController.Content.Item.Bait:GetCollection()) do
    local ItemName = ItemData.Name or ItemKey
    table.insert(BaitShopItems, {
        Name = ItemName,
        Title = ItemData.UIName or ItemName,
        Price = ItemData.Price or 0,
    })
end

table.sort(BaitShopItems, function(FirstItem, SecondItem)
    if FirstItem.Price == SecondItem.Price then
        return FirstItem.Title < SecondItem.Title
    end

    return FirstItem.Price < SecondItem.Price
end)

for _, Item in ipairs(BaitShopItems) do
    local Option = "Bait: " .. Item.Title
    table.insert(ShopItemOptions, Option)
    ShopItemsByOption[Option] = {
        Type = "Bait",
        Name = Item.Name,
        Price = Item.Price,
    }
end

for _, UpgradeName in ipairs(UpgradeConfig.Order) do
    local Option = "Upgrade: " .. UpgradeName
    table.insert(ShopItemOptions, Option)
    ShopItemsByOption[Option] = {
        Type = "Upgrade",
        Name = UpgradeName,
    }
end

local OfflineNetOption = "Offline Net: Next Upgrade"
table.insert(ShopItemOptions, OfflineNetOption)
ShopItemsByOption[OfflineNetOption] = {
    Type = "OfflineNet",
    Name = "Offline Net",
}

local PondCapacityOption = "Pond: Capacity Upgrade"
table.insert(ShopItemOptions, PondCapacityOption)
ShopItemsByOption[PondCapacityOption] = {
    Type = "PondUpgrade",
    Name = "Pond Capacity",
}

for ItemKey, ItemData in pairs(FishingController.Content.Item.Food:GetCollection()) do
    local ItemName = ItemData.Name or ItemKey
    table.insert(PondFoodItems, {
        Name = ItemName,
        Title = ItemData.UIName or ItemName,
        Price = ItemData.Price or 0,
    })
end

table.sort(PondFoodItems, function(FirstItem, SecondItem)
    if FirstItem.Price == SecondItem.Price then
        return FirstItem.Title < SecondItem.Title
    end

    return FirstItem.Price < SecondItem.Price
end)

for _, Item in ipairs(PondFoodItems) do
    local Option = "Pond Food: " .. Item.Title
    table.insert(ShopItemOptions, Option)
    ShopItemsByOption[Option] = {
        Type = "PondFood",
        Name = Item.Name,
        Price = Item.Price,
    }
end

local Window = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/latavee1399-dev/AKO/refs/heads/main/CC%20ui"
))({
    Author = "Deep Fishing",
    TagTitle = "Ako Dev",
})

local AutoTab = Window:Tab({
    Title = "Auto",
    Desc = "Automation",
    Icon = "zap",
})

local ShopTab = Window:Tab({
    Title = "Shop",
    Desc = "Shop",
    Icon = "shopping-bag",
})

local TeleportTab = Window:Tab({
    Title = "Teleport",
    Desc = "Travel between islands",
    Icon = "map-pin",
})

local TradeTab = Window:Tab({
    Title = "Trade",
    Desc = "Send and receive gifts",
    Icon = "repeat",
})

local BaseTabsOk, BaseTabsError = xpcall(function()
    if type(Window.InitBaseTabs) ~= "function" then
        error("The loaded CC ui does not expose Window:InitBaseTabs()")
    end

    Window:InitBaseTabs()
end, debug.traceback)

if not BaseTabsOk then
    warn("[S2] Window:InitBaseTabs() failed:\n" .. tostring(BaseTabsError))
end

-- FUNCTIONS
local function GetTargetSellValue(Target)
    if Target.special then
        return math.huge
    end

    if Target.boss then
        local CatchFight = AutoFishingController.Modules.CatchFight
        return CatchFight and CatchFight.Boss and CatchFight.Boss.SellPrice or 0
    end

    local FishData = AutoFishingController.Content.Item.Fish:Get(Target.name, true)

    if not (FishData and FishData.SellPrice) then
        return 0
    end

    local FishItem = {
        Type = "Fish",
        Name = Target.name,
        Data = {
            Size = Target.size or 1,
            Mutation = Target.mutation,
        },
    }

    return AutoFishingController.Services.Item:GetSellValue(LocalPlayer, FishItem)
end

local function TeleportToSelectedIsland()
    local SelectedIsland = Config["Selected Island"] or IslandOptions[1]
    local WorldKey = IslandKeysByOption[SelectedIsland]

    if not WorldKey then
        return false, "Select a valid island"
    end

    local TeleportInterface = FishingController.UI:Get("Teleport")
    local Success, Error = pcall(function()
        TeleportInterface.Controllers.Backpack:Unequip()
        TeleportInterface:RequestTeleport(WorldKey)
    end)

    if not Success then
        return false, tostring(Error)
    end

    return true, SelectedIsland
end

local function IsTargetValid(Target, Height)
    if not (Target and Target.model and Target.model.Parent) then
        return false
    end

    if Target.caught or Target.escaped then
        return false
    end

    local PrimaryPart = Target.model.PrimaryPart
    return PrimaryPart and Height <= PrimaryPart.Position.Y + PrimaryPart.Size.Y * 0.5 or false
end

local function PickBestTarget(Targets, Height)
    local BestTarget
    local BestValue = -math.huge

    for _, Target in ipairs(Targets) do
        if IsTargetValid(Target, Height) then
            local Value = GetTargetSellValue(Target)

            if Value > BestValue then
                BestTarget = Target
                BestValue = Value
            end
        end
    end

    return BestTarget
end

local RodItemModule = AutoFishingController.Content.Item.Rod
local RodItems = RodItemModule.Items or {}
local RodNames = {}

for RodName in pairs(RodItems) do
    table.insert(RodNames, RodName)
end

table.sort(RodNames, function(FirstName, SecondName)
    local FirstPrice = RodItems[FirstName].Price or 0
    local SecondPrice = RodItems[SecondName].Price or 0

    if FirstPrice == SecondPrice then
        return FirstName < SecondName
    end

    return FirstPrice < SecondPrice
end)

local RodShopEvent = AutoFishingController.Events.Client("RodShop")
local PendingRodPurchases = {}
local AutoBuyGeneration = 0
local AutoBuyShopGeneration = 0
local AutoUpgradeGeneration = 0
local AutoRodsGeneration = 0
local AutoSellGeneration = 0
local AutoTradeGeneration = 0
local AutoRodsAssistConnection
local AutoRodsTarget
local NextShopItemIndex = 1
local NextAutoUpgradeIndex = 1
local PendingUpgradePurchases = {}
local SellEvent = FishingController.Events.Client("Sell")
local BaitShopEvent = FishingController.Events.Client("BaitShop")
local UpgradeShopEvent = FishingController.Events.Client("Upgrades")
local PondShopEvent = FishingController.Events.Client("Pond")
local OfflineNetShopEvent = FishingController.Events.Client("OfflineNet")
local GiftEvent = FishingController.Events.Client("Gift")
local Ex_Function = {}
local TradePlayerDropdown
local TradePlayerOptions = {}
local TradePlayerByOption = {}

local function TryBuySelectedRod()
    local SelectedRods = Config["Selected Rods"] or {}
    local Profile = FishingController.PlayerData and FishingController.PlayerData:Get()

    if not Profile then
        return false, "Player data is unavailable"
    end

    local OwnedRods = Profile.Rods or {}
    local Cash = Profile.Cash or 0

    for _, RodName in ipairs(SelectedRods) do
        local RodData = RodItems[RodName]

        if RodData and not OwnedRods[RodName] then
            local Price = RodData.Price or 0
            local LastAttempt = PendingRodPurchases[RodName]

            if LastAttempt and os.clock() - LastAttempt < 5 then
                continue
            end

            if Cash >= Price then
                PendingRodPurchases[RodName] = os.clock()

                local Success = pcall(function()
                    RodShopEvent:Fire(true, "Buy", RodName)
                end)

                if not Success then
                    PendingRodPurchases[RodName] = nil
                    return false, "Purchase request failed for " .. RodName
                end

                return true, RodName
            end
        else
            PendingRodPurchases[RodName] = nil
        end
    end

    return false, "No selected rod is ready to buy"
end

Ex_Function["Auto Buy Rods"] = function()
    local Generation = AutoBuyGeneration

    while Config["Auto Buy Rods"] and Generation == AutoBuyGeneration and task.wait(1) do
        pcall(function()
            TryBuySelectedRod()
        end)
    end
end

local function SetAutoBuyRods(Enabled)
    AutoBuyGeneration += 1
    Config["Auto Buy Rods"] = Enabled == true

    if Config["Auto Buy Rods"] then
        task.spawn(Ex_Function["Auto Buy Rods"])
    end
end

local function BuildSelectionMap(Selection)
    local SelectionMap = {}

    if type(Selection) ~= "table" then
        return SelectionMap
    end

    for Key, Value in pairs(Selection) do
        if type(Key) == "number" then
            if type(Value) == "string" then
                SelectionMap[Value] = true
            end
        elseif Value == true then
            SelectionMap[Key] = true
        end
    end

    return SelectionMap
end

local function GetTradePlayerOption(Player)
    return string.format("%s (@%s)", Player.DisplayName, Player.Name)
end

local function FindTradePlayer(TargetText)
    local Target = string.lower(tostring(TargetText or ""))
    Target = Target:gsub("^%s+", ""):gsub("%s+$", "")
    Target = Target:gsub("^@", "")

    if Target == "" then
        return nil
    end

    local SelectedPlayer = TradePlayerByOption[TargetText]
    if SelectedPlayer and SelectedPlayer.Parent == Players then
        return SelectedPlayer
    end

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Option = string.lower(GetTradePlayerOption(Player))

            if string.lower(Player.Name) == Target
                or string.lower(Player.DisplayName) == Target
                or tostring(Player.UserId) == Target
                or Option == string.lower(tostring(TargetText or "")) then
                return Player
            end
        end
    end

    return nil
end

local function RefreshTradePlayerList()
    table.clear(TradePlayerOptions)
    table.clear(TradePlayerByOption)

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Option = GetTradePlayerOption(Player)
            table.insert(TradePlayerOptions, Option)
            TradePlayerByOption[Option] = Player
        end
    end

    table.sort(TradePlayerOptions)

    if TradePlayerDropdown then
        TradePlayerDropdown:Refresh(TradePlayerOptions, true)

        local SelectedPlayer = FindTradePlayer(Config["Trade Player"])
        local SelectedOption = SelectedPlayer and GetTradePlayerOption(SelectedPlayer)

        if SelectedOption and TradePlayerDropdown.Select then
            pcall(function()
                TradePlayerDropdown:Select(SelectedOption)
            end)
        end
    end
end

local function TryUpgradeSelected()
    local Profile = FishingController.PlayerData and FishingController.PlayerData:Get()

    if not Profile then
        return false, "Player data is unavailable"
    end

    local SelectedUpgrades = BuildSelectionMap(Config["Selected Upgrades"])
    local AvailableUpgrades = {}
    local UpgradeLevels = Profile.Upgrades or {}

    for _, UpgradeName in ipairs(UpgradeConfig.Order) do
        local UpgradeData = UpgradeConfig[UpgradeName]
        local CurrentLevel = UpgradeLevels[UpgradeName] or 0

        if SelectedUpgrades[UpgradeName] and UpgradeData and CurrentLevel < UpgradeData.MaxLevel then
            table.insert(AvailableUpgrades, UpgradeName)
        end
    end

    if #AvailableUpgrades == 0 then
        return false, "Select an upgrade that is not maxed"
    end

    local Cash = Profile.Cash or 0
    local PerUpgradeBudget = Cash / #AvailableUpgrades

    for Offset = 0, #UpgradeConfig.Order - 1 do
        local Index = ((NextAutoUpgradeIndex + Offset - 1) % #UpgradeConfig.Order) + 1
        local UpgradeName = UpgradeConfig.Order[Index]

        if SelectedUpgrades[UpgradeName] then
            local UpgradeData = UpgradeConfig[UpgradeName]
            local CurrentLevel = UpgradeLevels[UpgradeName] or 0

            if UpgradeData and CurrentLevel < UpgradeData.MaxLevel then
                local Price = UpgradeConfig.GetPrice(UpgradeName, CurrentLevel)
                local LastAttempt = PendingUpgradePurchases[UpgradeName]

                if Price <= PerUpgradeBudget and Cash >= Price
                    and (not LastAttempt or os.clock() - LastAttempt >= 3) then
                    PendingUpgradePurchases[UpgradeName] = os.clock()

                    local Success = pcall(function()
                        UpgradeShopEvent:Fire(true, "Buy", UpgradeName)
                    end)

                    if Success then
                        NextAutoUpgradeIndex = Index % #UpgradeConfig.Order + 1
                        return true, UpgradeName
                    end

                    PendingUpgradePurchases[UpgradeName] = nil
                    return false, "Upgrade request failed for " .. UpgradeName
                end
            end
        end
    end

    return false, "No selected upgrade fits its cash share"
end

local function TryBuySelectedShopItem()
    local Profile = FishingController.PlayerData and FishingController.PlayerData:Get()

    if not Profile then
        return false, "Player data is unavailable"
    end

    local SelectedItems = BuildSelectionMap(Config["Selected Shop Items"])
    local HasSelectedItem = false

    for _, Selected in pairs(SelectedItems) do
        if Selected then
            HasSelectedItem = true
            break
        end
    end

    if not HasSelectedItem then
        return false, "Select at least one shop item"
    end

    local Cash = Profile.Cash or 0

    for Offset = 0, #ShopItemOptions - 1 do
        local Index = ((NextShopItemIndex + Offset - 1) % #ShopItemOptions) + 1
        local Option = ShopItemOptions[Index]

        if SelectedItems[Option] then
            local ShopItem = ShopItemsByOption[Option]
            local Price = ShopItem.Price or 0
            local CanPurchase = true

            if ShopItem.Type == "Upgrade" then
                local UpgradeData = UpgradeConfig[ShopItem.Name]
                local CurrentLevel = (Profile.Upgrades or {})[ShopItem.Name] or 0
                local LastAttempt = PendingUpgradePurchases[ShopItem.Name]

                if UpgradeData and CurrentLevel < UpgradeData.MaxLevel
                    and (not LastAttempt or os.clock() - LastAttempt >= 3) then
                    Price = UpgradeConfig.GetPrice(ShopItem.Name, CurrentLevel)
                else
                    CanPurchase = false
                end
            elseif ShopItem.Type == "OfflineNet" then
                Price = OfflineConfig.PriceFor(OfflineConfig.LevelFor(Profile))
                CanPurchase = Price ~= nil
            elseif ShopItem.Type == "PondUpgrade" then
                local PondLevel = (Profile.Pond or {}).Level or 1
                Price = PondConfig.CapacityPrices[PondLevel]
                CanPurchase = Price ~= nil and PondConfig.CapacityLevels[PondLevel + 1] ~= nil
            end

            if CanPurchase and Cash >= Price then
                local Success = pcall(function()
                    if ShopItem.Type == "Upgrade" then
                        PendingUpgradePurchases[ShopItem.Name] = os.clock()
                        UpgradeShopEvent:Fire(true, "Buy", ShopItem.Name)
                    elseif ShopItem.Type == "OfflineNet" then
                        OfflineNetShopEvent:Fire(true, "Buy")
                    elseif ShopItem.Type == "PondUpgrade" then
                        PondShopEvent:Fire(true, "Upgrade")
                    elseif ShopItem.Type == "Bait" then
                        BaitShopEvent:Fire(true, "Buy", ShopItem.Name)
                    elseif ShopItem.Type == "PondFood" then
                        PondShopEvent:Fire(true, "BuyFood", ShopItem.Name)
                    end
                end)

                if Success then
                    NextShopItemIndex = Index % #ShopItemOptions + 1
                    return true, Option
                end

                if ShopItem.Type == "Upgrade" then
                    PendingUpgradePurchases[ShopItem.Name] = nil
                end

                return false, "Purchase request failed for " .. ShopItem.Name
            end
        end
    end

    return false, "No selected shop item is ready to buy"
end

Ex_Function["Auto Buy Shop Items"] = function()
    local Generation = AutoBuyShopGeneration

    while Config["Auto Buy Shop Items"] and Generation == AutoBuyShopGeneration and task.wait(1) do
        pcall(function()
            TryBuySelectedShopItem()
        end)
    end
end

local function SetAutoBuyShopItems(Enabled)
    AutoBuyShopGeneration += 1
    Config["Auto Buy Shop Items"] = Enabled == true

    if Config["Auto Buy Shop Items"] then
        task.spawn(Ex_Function["Auto Buy Shop Items"])
    end
end

Ex_Function["Auto Upgrade"] = function()
    local Generation = AutoUpgradeGeneration

    while Config["Auto Upgrade"] and Generation == AutoUpgradeGeneration and task.wait(1) do
        pcall(function()
            TryUpgradeSelected()
        end)
    end
end

local function SetAutoUpgrade(Enabled)
    AutoUpgradeGeneration += 1
    Config["Auto Upgrade"] = Enabled == true

    if Config["Auto Upgrade"] then
        task.spawn(Ex_Function["Auto Upgrade"])
    end
end

local function GetAutoSellCandidates()
    local Profile = FishingController.PlayerData and FishingController.PlayerData:Get()
    local Inventory = Profile and Profile.Inventory
    local Candidates = {}

    if type(Inventory) ~= "table" then
        return Candidates
    end

    local SelectionMap = BuildSelectionMap(Config["Auto Sell Rarities"])
    local SellAllRarities = SelectionMap.All == true

    for InventoryId, Item in pairs(Inventory) do
        if Item.Type == "Fish" and not FishingController.Modules.Lock.IsLocked(Item) then
            local FishData = FishingController.Content.Item.Fish:Get(Item.Name, true)

            if FishData and FishData.SellPrice then
                local Rarity = FishingController.Services.Item:GetRarityName(Item)

                if SellAllRarities or not SelectionMap[Rarity] then
                    table.insert(Candidates, InventoryId)
                end
            end
        end
    end

    return Candidates
end

local function SellEligibleFish(Generation)
    local Candidates = GetAutoSellCandidates()
    local Threshold = Config["Auto Sell Threshold"] or "10"
    local RequiredCount = Threshold == "Immediate" and 1 or tonumber(Threshold) or 10

    if #Candidates < RequiredCount then
        return
    end

    for _, InventoryId in ipairs(Candidates) do
        if not Config["Auto Sell"] or Generation ~= AutoSellGeneration then
            return
        end

        local Success, SellValue = pcall(function()
            return SellEvent:Invoke(5, InventoryId)
        end)

        if not Success or type(SellValue) ~= "number" or SellValue <= 0 then
            return
        end

        task.wait(0.12)
    end
end

Ex_Function["Auto Sell"] = function()
    local Generation = AutoSellGeneration

    while Config["Auto Sell"] and Generation == AutoSellGeneration and task.wait(1) do
        pcall(function()
            SellEligibleFish(Generation)
        end)
    end
end

local function SetAutoSell(Enabled)
    AutoSellGeneration += 1
    Config["Auto Sell"] = Enabled == true

    if Config["Auto Sell"] then
        task.spawn(Ex_Function["Auto Sell"])
    end
end

Ex_Function["Auto Trade"] = function()
    local Generation = AutoTradeGeneration

    while Config["Auto Trade"] and Generation == AutoTradeGeneration and task.wait(5) do
        pcall(function()
            local TargetPlayer = FindTradePlayer(Config["Trade Player"])

            if TargetPlayer and TargetPlayer ~= LocalPlayer then
                GiftEvent:Fire(true, "Request", TargetPlayer.UserId)
            end
        end)
    end
end

local function SetAutoTrade(Enabled)
    AutoTradeGeneration += 1
    Config["Auto Trade"] = Enabled == true

    if Config["Auto Trade"] then
        task.spawn(Ex_Function["Auto Trade"])
    end
end

local function SetAutoClaimTrade(Enabled)
    Config["Auto Claim Trade"] = Enabled == true
end

GiftEvent:Connect(function(Action, Payload)
    if Action ~= "Request" or not Config["Auto Claim Trade"] then
        return
    end

    local FromUserId = type(Payload) == "table" and Payload.FromUserId

    if type(FromUserId) ~= "number" then
        return
    end

    task.defer(function()
        if not Config["Auto Claim Trade"] then
            return
        end

        pcall(function()
            GiftEvent:Fire(true, "Accept", FromUserId)
        end)
    end)
end)

local function AimAutoRodsTarget(ThrowCinematic)
    if not (ThrowCinematic.Active and ThrowCinematic.Catchable and not ThrowCinematic.CatchWindowOver) then
        AutoRodsTarget = nil
        return
    end

    local CatchMinigame = ThrowCinematic.Sub and ThrowCinematic.Sub.CatchMinigame

    if CatchMinigame and CatchMinigame:IsActive() then
        return
    end

    local FishSchool = ThrowCinematic.Sub and ThrowCinematic.Sub.FishSchool
    local HangPoint = ThrowCinematic.HangPoint
    local ActiveLanding = ThrowCinematic.ActiveLanding

    if not (FishSchool and FishSchool.Fish and HangPoint and ActiveLanding) then
        return
    end

    AutoRodsTarget = PickBestTarget(FishSchool.Fish, HangPoint.Y)

    local PrimaryPart = AutoRodsTarget and AutoRodsTarget.model and AutoRodsTarget.model.PrimaryPart

    if not PrimaryPart then
        return
    end

    local Map = workspace:FindFirstChild("Map")
    Map = Map and Map:FindFirstChild("ThrowGuide")

    local Direction = Map and Map.CFrame.LookVector or Vector3.new(0, 0, -1)
    local Offset = ((PrimaryPart.Position - ActiveLanding) * Vector3.new(1, 0, 1)):Dot(Direction)

    ThrowCinematic.AimLocked = true
    ThrowCinematic.AimOffset = math.clamp(Offset, -50, 50)
end

local function StartAutoRodsAssist()
    if AutoRodsAssistConnection then
        AutoRodsAssistConnection:Disconnect()
    end

    AutoRodsAssistConnection = RunService.Heartbeat:Connect(function()
        if not Config["Auto Rods"] then
            return
        end

        pcall(function()
            local ThrowCinematic = FishingController.Controllers.ThrowCinematic
            local CatchMinigame = ThrowCinematic.Sub and ThrowCinematic.Sub.CatchMinigame

            if not ThrowCinematic.Active and not FishingController.Charging then
                AutoFishingController.DrivingThrow = false
            end

            if CatchMinigame and CatchMinigame:IsActive() then
                CatchMinigame:Click()
            end

            AimAutoRodsTarget(ThrowCinematic)
        end)
    end)
end

local function StopAutoRodsAssist()
    if AutoRodsAssistConnection then
        AutoRodsAssistConnection:Disconnect()
        AutoRodsAssistConnection = nil
    end

    AutoRodsTarget = nil
end

Ex_Function["Auto Rods"] = function()
    local Generation = AutoRodsGeneration

    while Config["Auto Rods"] and Generation == AutoRodsGeneration and task.wait(0.2) do
        pcall(function()
            local ThrowCinematic = FishingController.Controllers.ThrowCinematic

            if not FishingController:InArea() then
                return
            end

            if ThrowCinematic.Active or FishingController.Charging then
                return
            end

            if not FishingController:CanStartThrow() or FishingController:UIOwnsScreen() then
                return
            end

            if ThrowCinematic:GetBaitCapacity() <= 0 then
                return
            end

            AutoFishingController.DrivingThrow = true
            FishingController:StartHook()

            if FishingController.Charging then
                task.wait(0.03)

                if not Config["Auto Rods"] or Generation ~= AutoRodsGeneration then
                    FishingController:StopHook()
                    AutoFishingController.DrivingThrow = false
                    return
                end

                local HookSteps = FishingController:HUD():GetHookSteps()
                FishingController.HookT = math.clamp(9.5 / math.max(HookSteps - 1, 1), 0, 1)
                FishingController:StopHook()
            else
                AutoFishingController.DrivingThrow = false
            end
        end)
    end
end

local AutoRodsSection = AutoTab:Section({
    Title = "Auto Rods Fish",
    Desc = "Perfect casts, valuable fish, and special finds",
    Icon = "fish",
    Side = "left",
    Opened = true,
})

local AutoRodsToggle
local InitialAutoRodsEnabled = Config["Auto Rods"] == true

local function SetAutoRods(Enabled)
    Enabled = Enabled == true
    AutoRodsGeneration += 1
    Config["Auto Rods"] = Enabled

    if Enabled then
        AutoFishingController.On = true
        AutoFishingController.DrivingThrow = false
        AutoFishingController:EquipRod()
        StartAutoRodsAssist()
        task.spawn(Ex_Function["Auto Rods"])
    else
        AutoFishingController.On = false
        AutoFishingController.DrivingThrow = false
        StopAutoRodsAssist()

        local ThrowCinematic = FishingController.Controllers.ThrowCinematic
        if ThrowCinematic and ThrowCinematic.Active then
            pcall(function()
                ThrowCinematic:EndImmediate()
            end)
        end
    end
end

AutoRodsToggle = AutoRodsSection:Toggle({
    Title = "Auto Rods",
    Desc = "Auto cast, catch, and collect special finds",
    Value = InitialAutoRodsEnabled,
    Callback = SetAutoRods,
})

SetAutoRods(InitialAutoRodsEnabled)

local AutoUpgradeSection = AutoTab:Section({
    Title = "Auto Upgrade",
    Icon = "trending-up",
    Side = "left",
    Opened = true,
})

AutoUpgradeSection:Toggle({
    Title = "Auto Upgrade",
    Desc = "Splits available Cash evenly across selected upgrades",
    Icon = "repeat",
    Value = Config["Auto Upgrade"] == true,
    Callback = SetAutoUpgrade,
})

AutoUpgradeSection:Dropdown({
    Title = "Select Upgrades",
    Values = UpgradeConfig.Order,
    Value = Config["Selected Upgrades"] or {},
    AllowNone = true,
    SearchBarEnabled = true,
    Multi = true,
    Callback = function(SelectedUpgrades)
        Config["Selected Upgrades"] = SelectedUpgrades
    end,
})

local TeleportSection = TeleportTab:Section({
    Title = "Teleport",
    Icon = "map-pin",
    Side = "left",
    Opened = true,
})

TeleportSection:Dropdown({
    Title = "Select Island",
    Values = IslandOptions,
    Value = Config["Selected Island"] or IslandOptions[1],
    AllowNone = false,
    SearchBarEnabled = true,
    Callback = function(SelectedIsland)
        Config["Selected Island"] = SelectedIsland
    end,
})

TeleportSection:Button({
    Title = "Teleport Island",
    Icon = "map-pin",
    Color = Color3.fromRGB(0, 170, 255),
    Callback = function()
        local Success, Error = TeleportToSelectedIsland()
        local WindUI = Window.WindUI

        if not Success and WindUI then
            WindUI:Notify({
                Title = "Teleport",
                Content = Error,
                Duration = 3,
                Icon = "alert-circle",
            })
        end
    end,
})

local AutoBuySection = ShopTab:Section({
    Title = "Auto Buy",
    Icon = "shopping-cart",
    Side = "left",
    Opened = true,
})

AutoBuySection:Toggle({
    Title = "Auto Buy Rods",
    Icon = "repeat",
    Value = Config["Auto Buy Rods"] == true,
    Callback = SetAutoBuyRods,
})

AutoBuySection:Dropdown({
    Title = "Select Rods",
    Values = RodNames,
    Value = Config["Selected Rods"] or {},
    AllowNone = true,
    SearchBarEnabled = true,
    Multi = true,
    Callback = function(SelectedRods)
        Config["Selected Rods"] = SelectedRods
    end,
})

AutoBuySection:Button({
    Title = "Buy One Selected Rod",
    Icon = "shopping-bag",
    Color = Color3.fromRGB(57, 255, 20),
    Callback = function()
        local Success, Result = TryBuySelectedRod()
        local WindUI = Window.WindUI

        if WindUI then
            WindUI:Notify({
                Title = "Auto Buy Rods",
                Content = Success and ("Purchase requested: " .. Result) or Result,
                Duration = 3,
                Icon = Success and "check-circle" or "alert-circle",
            })
        end
    end,
})

local AutoBuyOtherShopsSection = ShopTab:Section({
    Title = "Auto Buy Other Shops",
    Icon = "store",
    Side = "left",
    Opened = true,
})

AutoBuyOtherShopsSection:Toggle({
    Title = "Auto Buy Shop Items",
    Desc = "Repeatedly buys selected Baits, Upgrades, Offline Net, Pond Capacity, and Pond Food with Cash",
    Icon = "repeat",
    Value = Config["Auto Buy Shop Items"] == true,
    Callback = SetAutoBuyShopItems,
})

AutoBuyOtherShopsSection:Dropdown({
    Title = "Select Shop Items",
    Values = ShopItemOptions,
    Value = Config["Selected Shop Items"] or {},
    AllowNone = true,
    SearchBarEnabled = true,
    Multi = true,
    Callback = function(SelectedItems)
        Config["Selected Shop Items"] = SelectedItems
    end,
})

AutoBuyOtherShopsSection:Button({
    Title = "Buy One Selected Item",
    Icon = "shopping-bag",
    Color = Color3.fromRGB(57, 255, 20),
    Callback = function()
        local Success, Result = TryBuySelectedShopItem()
        local WindUI = Window.WindUI

        if WindUI then
            WindUI:Notify({
                Title = "Auto Buy Other Shops",
                Content = Success and ("Purchase requested: " .. Result) or Result,
                Duration = 3,
                Icon = Success and "check-circle" or "alert-circle",
            })
        end
    end,
})

local AutoSellSection = ShopTab:Section({
    Title = "Auto Sell",
    Icon = "badge-dollar-sign",
    Side = "right",
    Opened = true,
})

local AutoSellRarityOptions = {}
local RarityConfig = FishingController.Config.RarityConfig

for Rarity in pairs(RarityConfig.Items) do
    table.insert(AutoSellRarityOptions, Rarity)
end

table.sort(AutoSellRarityOptions, function(FirstRarity, SecondRarity)
    return (RarityConfig.GetOrder(FirstRarity) or math.huge)
        < (RarityConfig.GetOrder(SecondRarity) or math.huge)
end)

table.insert(AutoSellRarityOptions, 1, "All")

local AutoSellThresholdOptions = { "Immediate" }

for Count = 10, 100, 10 do
    table.insert(AutoSellThresholdOptions, tostring(Count))
end

AutoSellSection:Toggle({
    Title = "Auto Sell",
    Desc = "Sells eligible fish while near a fish merchant",
    Icon = "banknote",
    Value = Config["Auto Sell"] == true,
    Callback = SetAutoSell,
})

AutoSellSection:Dropdown({
    Title = "Keep Rarities",
    Desc = "Selected rarities are kept. Choose All to sell fish of every rarity.",
    Values = AutoSellRarityOptions,
    Value = Config["Auto Sell Rarities"] or {},
    AllowNone = true,
    SearchBarEnabled = true,
    Multi = true,
    Callback = function(SelectedRarities)
        local SelectionMap = BuildSelectionMap(SelectedRarities)
        local StoredSelection = {}

        for _, Rarity in ipairs(AutoSellRarityOptions) do
            if SelectionMap[Rarity] then
                table.insert(StoredSelection, Rarity)
            end
        end

        Config["Auto Sell Rarities"] = StoredSelection
    end,
})

AutoSellSection:Dropdown({
    Title = "Sell When Fish Count Reaches",
    Values = AutoSellThresholdOptions,
    Value = Config["Auto Sell Threshold"] or "10",
    AllowNone = false,
    Callback = function(Threshold)
        Config["Auto Sell Threshold"] = Threshold
    end,
})

RefreshTradePlayerList()

local InitialTradePlayer = FindTradePlayer(Config["Trade Player"])
local InitialTradePlayerOption = InitialTradePlayer and GetTradePlayerOption(InitialTradePlayer)

local AutoTradeSection = TradeTab:Section({
    Title = "Auto Trade",
    Desc = "Send and accept gift requests automatically",
    Icon = "repeat",
    Side = "left",
    Opened = true,
})

AutoTradeSection:Toggle({
    Title = "Auto Trade",
    Desc = "Sends the held gift to the selected player",
    Value = Config["Auto Trade"] == true,
    Callback = SetAutoTrade,
})

AutoTradeSection:Toggle({
    Title = "Auto Claim Trade",
    Desc = "Automatically accepts incoming gift requests",
    Value = Config["Auto Claim Trade"] == true,
    Callback = SetAutoClaimTrade,
})

AutoTradeSection:Input({
    Title = "Target Player",
    Placeholder = "Enter username, display name, or UserId",
    Callback = function(Text)
        Config["Trade Player"] = tostring(Text or "")
    end,
})

TradePlayerDropdown = AutoTradeSection:Dropdown({
    Title = "Select Player",
    Values = TradePlayerOptions,
    Value = InitialTradePlayerOption,
    AllowNone = true,
    SearchBarEnabled = true,
    Callback = function(SelectedOption)
        local SelectedPlayer = TradePlayerByOption[SelectedOption]

        if SelectedPlayer then
            Config["Trade Player"] = SelectedPlayer.Name
        end
    end,
})

AutoTradeSection:Button({
    Title = "Refresh Player List",
    Icon = "refresh-cw",
    Color = Color3.fromRGB(255, 200, 0),
    Callback = function()
        RefreshTradePlayerList()

        local WindUI = Window.WindUI
        if WindUI then
            WindUI:Notify({
                Title = "Trade",
                Content = string.format("Found %d player(s)", #TradePlayerOptions),
                Duration = 3,
                Icon = "refresh-cw",
            })
        end
    end,
})

SetAutoBuyRods(Config["Auto Buy Rods"] == true)
SetAutoBuyShopItems(Config["Auto Buy Shop Items"] == true)
SetAutoUpgrade(Config["Auto Upgrade"] == true)
SetAutoSell(Config["Auto Sell"] == true)
SetAutoTrade(Config["Auto Trade"] == true)
SetAutoClaimTrade(Config["Auto Claim Trade"] == true)
