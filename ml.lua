local Window = loadstring(game:HttpGet("https://raw.githubusercontent.com/latavee1399-dev/AKO/refs/heads/main/CC%20ui"))()
local WindUI = Window.WindUI

-- Auto Tab
local AutoTab = Window:Tab({
    Title = "Auto",
    Icon = "zap"
})

-- Auto Farm Section
local AutoFarmSection = AutoTab:Section({
    Title = "Auto Farm",
    Icon = "zap",
    Opened = false
})

-- Variables
local autoFarmEnabled = false

-- Auto Farm Power Toggle
AutoFarmSection:Toggle({
    Title = "Auto Farm Power",
    Desc = "Automatically use skills to farm",
    Icon = "zap",
    Value = false,
    Callback = function(state)
        autoFarmEnabled = state

        if state then
            task.spawn(function()
                while autoFarmEnabled do
                    game:GetService("ReplicatedStorage").Msg.RemoteFunction.NetWorkRemoteFunction:InvokeServer(table.unpack({
                        [1] = "训练点屏",
                        [2] = {},
                    }))

                    task.wait(0.01) -- Spam rate
                end
            end)
        end
    end
})

-- Auto Dungeon
local autoDungeonEnabled = false
local autoDungeonLoopRunning = false
local autoReturnEnabled = false
local selectedDungeonStage = 1
local activeDungeonTween = nil
local dungeonBattleAreaName = "\230\136\152\230\150\151\229\140\186\229\159\159"
local dungeonTweenHeight = 5
local shouldResumeAutoDungeonAfterFullBag = false
local pausingAutoDungeonForFullBag = false

local dungeonStageValues = {}
for stage = 1, 30 do
    dungeonStageValues[#dungeonStageValues + 1] = "Stage " .. stage
end

local function getDungeonSceneFolder()
    local bestFolder = nil
    local bestStageCount = 0

    for _, folder in next, workspace:GetChildren() do
        if folder:IsA("Folder") or folder:IsA("Model") then
            local stageCount = 0
            for _, child in next, folder:GetChildren() do
                if child:IsA("Model") and tonumber(child.Name) and child:FindFirstChild("Root") then
                    stageCount = stageCount + 1
                end
            end

            if stageCount > bestStageCount then
                bestFolder = folder
                bestStageCount = stageCount
            end
        end
    end

    return bestFolder
end

local function getDungeonStageRoot(stage)
    local sceneFolder = getDungeonSceneFolder()
    local stageModel = sceneFolder and sceneFolder:FindFirstChild(tostring(stage))
    local target = stageModel and (stageModel:FindFirstChild(dungeonBattleAreaName) or stageModel:FindFirstChild("Root"))
    return target and target:IsA("BasePart") and target or nil
end

local function setDungeonFloating(state)
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    root.Anchored = false

    local oldVelocity = root:FindFirstChild("MagicLootDungeonHover")
    local oldAttachment = root:FindFirstChild("MagicLootDungeonHoverAttachment")
    if state and oldVelocity and oldAttachment then return end

    if oldVelocity then oldVelocity:Destroy() end
    if oldAttachment then oldAttachment:Destroy() end
    if not state then return end

    local attachment = Instance.new("Attachment")
    attachment.Name = "MagicLootDungeonHoverAttachment"
    attachment.Parent = root

    local velocity = Instance.new("LinearVelocity")
    velocity.Name = "MagicLootDungeonHover"
    velocity.Attachment0 = attachment
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World
    velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    velocity.VectorVelocity = Vector3.zero
    velocity.MaxForce = math.huge
    velocity.Parent = root
end

local function tweenToDungeonStage(stage)
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local target = getDungeonStageRoot(stage)
    if not root or not target then return false end

    local destination = target.CFrame + Vector3.new(0, dungeonTweenHeight, 0)
    local distance = (root.Position - destination.Position).Magnitude
    if distance <= 5 then
        setDungeonFloating(true)
        return true
    end

    setDungeonFloating(false)
    local duration = math.clamp(distance / 80, 0.2, 8)
    local tween = game:GetService("TweenService"):Create(
        root,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        { CFrame = destination }
    )
    activeDungeonTween = tween
    tween:Play()

    while autoDungeonEnabled and tween.PlaybackState == Enum.PlaybackState.Playing do
        task.wait(0.1)
    end

    if not autoDungeonEnabled then
        tween:Cancel()
    end
    if activeDungeonTween == tween then
        activeDungeonTween = nil
    end
    if autoDungeonEnabled then
        setDungeonFloating(true)
    end
    return autoDungeonEnabled
end

local function returnFromDungeon()
    local remoteFolder = game:GetService("ReplicatedStorage").Msg.RemoteEvent
    local remote = remoteFolder:FindFirstChild("NetWorkRemoteEvent")
    if not remote or not remote:IsA("RemoteEvent") then return false end

    local netMsg = require(game.ReplicatedFirst.AllSideCode.ToolBasic.NetMsg)
    setDungeonFloating(false)
    local success = pcall(function()
        remote:FireServer(netMsg.DUNGEON_RETURN_TOWN)
    end)
    return success
end

local function createAutoFarmControl(name, callback)
    local success, control = pcall(callback)
    if not success then
        warn("[Magic Loot] Failed to create " .. name .. ": " .. tostring(control))
        return nil
    end
    return control
end

createAutoFarmControl("Dungeon Stage Dropdown", function()
    return AutoFarmSection:Dropdown({
        Title = "Stop At Dungeon Stage",
        Description = "Select the stage where Auto Dungeon should stop or return",
        Values = dungeonStageValues,
        Default = "Stage 1",
        Callback = function(value)
            selectedDungeonStage = tonumber(string.match(tostring(value), "%d+")) or 1
        end
    })
end)

createAutoFarmControl("Dungeon Height Slider", function()
    return AutoFarmSection:Slider({
        Title = "Dungeon Height Offset",
        Description = "Positive values float up; negative values float down",
        Value = {
            Min = -20,
            Max = 30,
            Default = 5
        },
        Step = 1,
        Callback = function(value)
            dungeonTweenHeight = tonumber(value) or 5
        end
    })
end)

local autoDungeonToggle = createAutoFarmControl("Auto Dungeon Toggle", function()
    return AutoFarmSection:Toggle({
        Title = "Auto Dungeon",
        Desc = "Tween through Dungeon stages automatically",
        Icon = "swords",
        Value = false,
        Callback = function(state)
            autoDungeonEnabled = state
            if not state then
                if not pausingAutoDungeonForFullBag then
                    shouldResumeAutoDungeonAfterFullBag = false
                end
                if activeDungeonTween then
                    activeDungeonTween:Cancel()
                    activeDungeonTween = nil
                end
                setDungeonFloating(false)
                return
            end
            if autoDungeonLoopRunning then return end

            autoDungeonLoopRunning = true
            task.spawn(function()
                local player = game:GetService("Players").LocalPlayer

                while autoDungeonEnabled do
                    local clearedValue = player:FindFirstChild("DungeonRunMaxClear")
                    local clearedStage = clearedValue and math.floor(tonumber(clearedValue.Value) or 0) or 0

                    if clearedStage >= selectedDungeonStage then
                        if autoReturnEnabled then
                            returnFromDungeon()
                            task.wait(2)
                        else
                            task.wait(0.5)
                        end
                    else
                        tweenToDungeonStage(clearedStage + 1)
                        task.wait(0.25)
                    end
                end

                setDungeonFloating(false)
                autoDungeonLoopRunning = false
            end)
        end
    })
end)

createAutoFarmControl("Auto Return Toggle", function()
    return AutoFarmSection:Toggle({
        Title = "Auto Return",
        Desc = "Return to spawn after reaching the selected Dungeon stage",
        Icon = "refresh-cw",
        Value = false,
        Callback = function(state)
            autoReturnEnabled = state
        end
    })
end)

-- Auto Pick Item
local autoPickItemEnabled = false
local autoPickItemLoopRunning = false
local minimumPickupGoldValue = 1000000
local pickupAttemptTimes = setmetatable({}, { __mode = "k" })

local pickupRarityNames = {
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "Secret",
    [8] = "Ancient",
    [9] = "Supreme",
    [10] = "Astral"
}
local pickupRarityOptions = {}
local pickupRarityByOption = {}
local selectedPickupRarities = {}

for rarity = 1, 10 do
    local option = string.format("%s (Tier %d)", pickupRarityNames[rarity], rarity)
    pickupRarityOptions[#pickupRarityOptions + 1] = option
    pickupRarityByOption[option] = rarity
    selectedPickupRarities[rarity] = true
end

local pickupValueOptions = { "1M" }
local pickupValueByOption = { ["1M"] = 1000000 }
local pickupValueRanges = {
    { Min = 10, Max = 2000, Step = 10 },
    { Min = 3000, Max = 10000, Step = 1000 },
    { Min = 20000, Max = 100000, Step = 10000 },
    { Min = 200000, Max = 1000000, Step = 100000 },
    { Min = 2000000, Max = 10000000, Step = 1000000 }
}

for _, range in next, pickupValueRanges do
    for value = range.Min, range.Max, range.Step do
        local option = value .. "M"
        pickupValueOptions[#pickupValueOptions + 1] = option
        pickupValueByOption[option] = value * 1000000
    end
end

assert(#pickupRarityOptions == 10 and pickupValueByOption["1M"] == 1000000 and pickupValueByOption["10000000M"] == 10000000000000, "Auto Pick Item filter setup failed")

local function triggerDropPickup(drop)
    local root = drop.PrimaryPart or drop:FindFirstChild("Root")
    local prompt = root and root:FindFirstChild("PickupPrompt")
    if not prompt or not prompt:IsA("ProximityPrompt") then return false end

    if type(fireproximityprompt) == "function" then
        return pcall(fireproximityprompt, prompt)
    end
    if type(firesignal) == "function" then
        return pcall(firesignal, prompt.Triggered, game:GetService("Players").LocalPlayer)
    end
    return false
end

local function pickEligibleDrops()
    local dropsClient = workspace:FindFirstChild("DropsClient")
    if not dropsClient then return end

    local now = os.clock()
    for _, rarityFolder in next, dropsClient:GetChildren() do
        local folderRarity = tonumber(rarityFolder.Name)
        if folderRarity and selectedPickupRarities[folderRarity] then
            for _, drop in next, rarityFolder:GetChildren() do
                if drop:IsA("Model") and drop.Name == "DropItem" and drop:GetAttribute("DropLanded") == true then
                    local rarity = math.floor(tonumber(drop:GetAttribute("Xyd")) or folderRarity)
                    local goldValue = math.floor(tonumber(drop:GetAttribute("GoldValue")) or 0)
                    local lastAttempt = pickupAttemptTimes[drop] or 0

                    if selectedPickupRarities[rarity]
                        and goldValue >= minimumPickupGoldValue
                        and now - lastAttempt >= 1
                    then
                        pickupAttemptTimes[drop] = now
                        triggerDropPickup(drop)
                    end
                end
            end
        end
    end
end

createAutoFarmControl("Pick Item Rarity Dropdown", function()
    return AutoFarmSection:Dropdown({
        Title = "Pick Item Rarity",
        Description = "Select one or more item rarities to collect",
        Values = pickupRarityOptions,
        Value = pickupRarityOptions,
        Multi = true,
        AllowNone = false,
        SearchBarEnabled = true,
        Callback = function(values)
            selectedPickupRarities = {}
            for _, option in next, values do
                local rarity = pickupRarityByOption[option]
                if rarity then
                    selectedPickupRarities[rarity] = true
                end
            end
        end
    })
end)

createAutoFarmControl("Pick Item Value Dropdown", function()
    return AutoFarmSection:Dropdown({
        Title = "Minimum Item Value",
        Description = "Only collect items worth at least this amount",
        Values = pickupValueOptions,
        Value = "1M",
        SearchBarEnabled = true,
        Callback = function(value)
            minimumPickupGoldValue = pickupValueByOption[value] or 1000000
        end
    })
end)

local function parsePickupGoldValue(value)
    local text = string.lower(tostring(value or "")):gsub("%s+", ""):gsub(",", "")
    local amountText, suffix = text:match("^([%d%.]+)([kmbt]?)$")
    local amount = tonumber(amountText)
    local multipliers = {
        [""] = 1,
        k = 1000,
        m = 1000000,
        b = 1000000000,
        t = 1000000000000
    }
    local multiplier = multipliers[suffix]

    if not amount or amount < 0 or not multiplier then return nil end
    return math.floor(amount * multiplier)
end

createAutoFarmControl("Custom Pick Item Value Input", function()
    return AutoFarmSection:Input({
        Title = "Custom Minimum Value",
        Placeholder = "e.g. 250M, 2B, or 250000000",
        Callback = function(value)
            local customValue = parsePickupGoldValue(value)
            if customValue then
                minimumPickupGoldValue = customValue
            end
        end
    })
end)

createAutoFarmControl("Auto Pick Item Toggle", function()
    return AutoFarmSection:Toggle({
        Title = "Auto Pick Item",
        Desc = "Automatically collect matching monster drops",
        Icon = "package-plus",
        Value = false,
        Callback = function(state)
            autoPickItemEnabled = state
            if not state or autoPickItemLoopRunning then return end

            autoPickItemLoopRunning = true
            task.spawn(function()
                while autoPickItemEnabled do
                    pickEligibleDrops()
                    task.wait(0.25)
                end
                autoPickItemLoopRunning = false
            end)
        end
    })
end)

-- Auto Return Full Bag
local autoReturnFullBagEnabled = false
local autoReturnFullBagLoopRunning = false

local function isPickupBagFull()
    local player = game:GetService("Players").LocalPlayer
    local usedValue = player:FindFirstChild("LimitBagUsed")
    local bag = player:FindFirstChild("Bag")
    local sizeValue = bag and bag:FindFirstChild("5")
    local used = usedValue and math.floor(tonumber(usedValue.Value) or 0) or 0
    local size = sizeValue and math.floor(tonumber(sizeValue.Value) or 0) or 0
    return size > 0 and used >= size
end

local function stopAutoDungeonForFullBag()
    shouldResumeAutoDungeonAfterFullBag = autoDungeonEnabled
    autoDungeonEnabled = false
    if activeDungeonTween then
        activeDungeonTween:Cancel()
        activeDungeonTween = nil
    end
    setDungeonFloating(false)

    if autoDungeonToggle and type(autoDungeonToggle.Set) == "function" then
        pausingAutoDungeonForFullBag = true
        pcall(function()
            autoDungeonToggle:Set(false)
        end)
        pausingAutoDungeonForFullBag = false
    end
end

local function resumeAutoDungeonAfterFullBag()
    if not shouldResumeAutoDungeonAfterFullBag then return end

    task.spawn(function()
        task.wait(2)
        local deadline = os.clock() + 5
        while autoDungeonLoopRunning and os.clock() < deadline do
            task.wait(0.1)
        end

        if not autoReturnFullBagEnabled or not shouldResumeAutoDungeonAfterFullBag then return end
        shouldResumeAutoDungeonAfterFullBag = false

        if autoDungeonToggle and type(autoDungeonToggle.Set) == "function" then
            autoDungeonToggle:Set(true)
        else
            autoDungeonEnabled = true
        end
    end)
end

createAutoFarmControl("Auto Return Full Bag Toggle", function()
    return AutoFarmSection:Toggle({
        Title = "Auto Return Full Bag",
        Desc = "Return to spawn automatically when the pickup bag is full",
        Icon = "refresh-cw",
        Value = false,
        Callback = function(state)
            autoReturnFullBagEnabled = state
            if not state or autoReturnFullBagLoopRunning then return end

            autoReturnFullBagLoopRunning = true
            task.spawn(function()
                local returnedForCurrentFullBag = false

                while autoReturnFullBagEnabled do
                    if isPickupBagFull() then
                        if not returnedForCurrentFullBag then
                            stopAutoDungeonForFullBag()
                            returnedForCurrentFullBag = returnFromDungeon()
                            if returnedForCurrentFullBag then
                                resumeAutoDungeonAfterFullBag()
                            end
                        end
                        task.wait(1)
                    else
                        returnedForCurrentFullBag = false
                        task.wait(0.25)
                    end
                end

                autoReturnFullBagLoopRunning = false
            end)
        end
    })
end)

-- Auto Game Section
local AutoGameSection = AutoTab:Section({
    Title = "Auto Game",
    Icon = "gamepad-2",
    Opened = false
})

-- Auto Rebirth
local autoRebirthEnabled = false
local autoRebirthLoopRunning = false
local playerRebirthRemoteName = "\231\142\169\229\174\182\230\153\139\229\141\135"
local materialRewardRemoteName = "\233\162\134\229\143\150\229\155\190\233\137\180\232\191\155\229\186\166\229\165\150\229\138\177"

local function getRebirthRequirement()
    local player = game:GetService("Players").LocalPlayer
    local bag = player:FindFirstChild("Bag")
    if not bag then return nil end

    local rebirthValue = bag:FindFirstChild("2")
    local rebirthId = rebirthValue and math.floor(tonumber(rebirthValue.Value) or 0) + 1
    if not rebirthId then return nil end

    local config = require(game.ReplicatedFirst.AllSideCode.UtilsSystem).ConfigInstance
    local rebirthConf = config and config.rebirthConf
    local nextRebirth = rebirthConf and rebirthConf[rebirthId]
    return nextRebirth and math.floor(tonumber(nextRebirth.LvNeed) or 0) or nil
end

AutoGameSection:Toggle({
    Title = "Auto Rebirth",
    Desc = "Automatically rebirth when the required level is reached",
    Icon = "refresh-cw",
    Value = false,
    Callback = function(state)
        autoRebirthEnabled = state
        if not state or autoRebirthLoopRunning then return end

        autoRebirthLoopRunning = true
        task.spawn(function()
            local player = game:GetService("Players").LocalPlayer
            local remote = game:GetService("ReplicatedStorage").Msg.RemoteFunction.NetWorkRemoteFunction

            while autoRebirthEnabled do
                local bag = player:FindFirstChild("Bag")
                local levelValue = bag and bag:FindFirstChild("4")
                local requiredLevel = getRebirthRequirement()
                local currentLevel = levelValue and math.floor(tonumber(levelValue.Value) or 0) or 0

                if requiredLevel and currentLevel >= requiredLevel then
                    pcall(function()
                        remote:InvokeServer(playerRebirthRemoteName)
                    end)
                    task.wait(1.5)
                else
                    task.wait(0.5)
                end
            end

            autoRebirthLoopRunning = false
        end)
    end
})

-- Auto Complete Materials
local autoCompleteMaterialsEnabled = false
local autoCompleteMaterialsLoopRunning = false
local lastMaterialClaimTarget = nil
local autoCompletePotionsEnabled = false
local autoCompletePotionsLoopRunning = false
local lastPotionClaimTarget = nil

local function getClaimableIndexProgress(tag)
    local utilsSystem = require(game.ReplicatedFirst.AllSideCode.UtilsSystem)
    local indexData = utilsSystem.PlayerData.GetPlrDataByKey(utilsSystem.LocalPlayer, "Index")
    if type(indexData) ~= "table" then return nil end

    local tabData = type(indexData[tag]) == "table" and indexData[tag] or {}
    local rewardRoot = type(indexData.Reward) == "table" and indexData.Reward or {}
    local rewardData = type(rewardRoot[tag]) == "table" and rewardRoot[tag] or {}
    local unlockedCount = 0

    for _, unlocked in next, tabData do
        if tonumber(unlocked) == 1 then
            unlockedCount = unlockedCount + 1
        end
    end

    local claimableTarget = nil
    local rewardRows = utilsSystem.CfgFind.GetIndexRewardRowsByTag(tag)
    for _, row in next, rewardRows do
        local needCount = tonumber(row.NeedCount)
        local claimed = needCount and (rewardData[needCount] or rewardData[tostring(needCount)])
        if needCount and needCount <= unlockedCount and tonumber(claimed) ~= 1 then
            if not claimableTarget or needCount < claimableTarget then
                claimableTarget = needCount
            end
        end
    end

    return claimableTarget
end


AutoGameSection:Toggle({
    Title = "Auto Complete Materials",
    Desc = "Automatically claim completed material collection rewards",
    Icon = "package-check",
    Value = false,
    Callback = function(state)
        autoCompleteMaterialsEnabled = state
        if not state or autoCompleteMaterialsLoopRunning then return end

        lastMaterialClaimTarget = nil
        autoCompleteMaterialsLoopRunning = true
        task.spawn(function()
            local remote = game:GetService("ReplicatedStorage").Msg.RemoteFunction.NetWorkRemoteFunction

            while autoCompleteMaterialsEnabled do
                local target = getClaimableIndexProgress("Material")

                if target and target ~= lastMaterialClaimTarget then
                    local success, result = pcall(function()
                        return remote:InvokeServer(materialRewardRemoteName, {
                            progress = target,
                            tag = "Material"
                        })
                    end)
                    if success and result then
                        lastMaterialClaimTarget = target
                    end
                    task.wait(1.5)
                else
                    task.wait(0.5)
                end
            end

            autoCompleteMaterialsLoopRunning = false
        end)
    end
})

AutoGameSection:Toggle({
    Title = "Auto Complete Potions",
    Desc = "Automatically claim completed potion collection rewards",
    Icon = "flask-conical",
    Value = false,
    Callback = function(state)
        autoCompletePotionsEnabled = state
        if not state or autoCompletePotionsLoopRunning then return end

        lastPotionClaimTarget = nil
        autoCompletePotionsLoopRunning = true
        task.spawn(function()
            local remote = game:GetService("ReplicatedStorage").Msg.RemoteFunction.NetWorkRemoteFunction

            while autoCompletePotionsEnabled do
                local target = getClaimableIndexProgress("Potion")

                if target and target ~= lastPotionClaimTarget then
                    local success, result = pcall(function()
                        return remote:InvokeServer(materialRewardRemoteName, {
                            progress = target,
                            tag = "Potion"
                        })
                    end)
                    if success and result then
                        lastPotionClaimTarget = target
                    end
                    task.wait(1.5)
                else
                    task.wait(0.5)
                end
            end

            autoCompletePotionsLoopRunning = false
        end)
    end
})

-- Auto Claim Online Rewards
local autoClaimOnlineRewardEnabled = false
local autoClaimOnlineRewardLoopRunning = false
local onlineRewardUtilsSystem = require(game.ReplicatedFirst.AllSideCode.UtilsSystem)

local function getClaimableOnlineRewardIds()
    local player = onlineRewardUtilsSystem.LocalPlayer
    local onlineBox = onlineRewardUtilsSystem.PlayerData.GetPlrDataByKey(player, "OnlineBox")
    local claimableIds = {}
    if type(onlineBox) ~= "table" then return claimableIds end

    for _, reward in next, onlineRewardUtilsSystem.CfgFind.GetOnlineAwardList() do
        local rewardId = tonumber(reward.id) or 0
        if rewardId > 0 and not onlineRewardUtilsSystem.CfgFind.IsOnlineTierClaimed(onlineBox, rewardId) then
            local award = onlineRewardUtilsSystem.CfgFind.GetOnlineAward(rewardId)
            if award then
                local claimCheck = {}
                for key, value in next, award do
                    claimCheck[key] = value
                end
                claimCheck.id = rewardId

                if onlineRewardUtilsSystem.CfgFind.IsOnlineTierClaimable(onlineBox, claimCheck) then
                    claimableIds[#claimableIds + 1] = rewardId
                end
            end
        end
    end

    table.sort(claimableIds)
    return claimableIds
end

local function claimOnlineReward(rewardId)
    local success, result = pcall(function()
        return onlineRewardUtilsSystem.NetWork.InvokeServer(
            onlineRewardUtilsSystem.NetMsg.CLAIM_ONLINE_AWARD,
            rewardId
        )
    end)
    return success and result == true
end

AutoGameSection:Toggle({
    Title = "Auto Claim Reward Online",
    Desc = "Automatically claim unlocked Online Rewards",
    Icon = "gift",
    Value = false,
    Callback = function(state)
        autoClaimOnlineRewardEnabled = state
        if not state or autoClaimOnlineRewardLoopRunning then return end

        autoClaimOnlineRewardLoopRunning = true
        task.spawn(function()
            while autoClaimOnlineRewardEnabled do
                local claimableIds = getClaimableOnlineRewardIds()
                local claimedAny = false

                for _, rewardId in next, claimableIds do
                    if not autoClaimOnlineRewardEnabled then break end
                    if claimOnlineReward(rewardId) then
                        claimedAny = true
                    end
                    task.wait(0.75)
                end

                task.wait(claimedAny and 1 or 2)
            end
            autoClaimOnlineRewardLoopRunning = false
        end)
    end
})

-- Auto Alchemy Section
local AutoAlchemySection = AutoTab:Section({
    Title = "Auto Alchemy",
    Icon = "flask-conical",
    Opened = false
})

-- Auto Alchemy
local autoAlchemyEnabled = false
local autoAlchemyLoopRunning = false
local selectedAlchemyRecipeId = nil
local alchemyUtilsSystem = require(game.ReplicatedFirst.AllSideCode.UtilsSystem)
local alchemySystem = alchemyUtilsSystem.GetData.Alchemy
local alchemyPotionType = alchemyUtilsSystem.EnumMgr.ItemType.Potion
local alchemyPotionOptions = {}
local alchemyRecipeByOption = {}

for _, recipe in next, alchemySystem.GetRecipeList() do
    local recipeId = type(recipe) == "table" and math.floor(tonumber(recipe.recipeId) or 0)
    local potionId = type(recipe) == "table" and tonumber(recipe.PID)
    local potionConfig = potionId and alchemyUtilsSystem.CfgFind.FindCfgByID(potionId, alchemyPotionType)

    if recipeId > 0 and potionConfig then
        local potionName = potionConfig.ZhName or potionConfig.Name or "Potion"
        local translatedName = alchemyUtilsSystem.TranslationHelper.TranslateByKey(potionName) or potionName
        local option = string.format("%s (Recipe %d)", translatedName, recipeId)
        alchemyPotionOptions[#alchemyPotionOptions + 1] = option
        alchemyRecipeByOption[option] = recipeId
    end
end

table.sort(alchemyPotionOptions, function(left, right)
    return (alchemyRecipeByOption[left] or 0) < (alchemyRecipeByOption[right] or 0)
end)

selectedAlchemyRecipeId = alchemyRecipeByOption[alchemyPotionOptions[1]]
assert(selectedAlchemyRecipeId and #alchemyPotionOptions > 0, "Auto Alchemy recipe setup failed")

local function createAutoAlchemyControl(name, callback)
    local success, control = pcall(callback)
    if not success then
        warn("[Magic Loot] Failed to create " .. name .. ": " .. tostring(control))
        return nil
    end
    return control
end

local function getSelectedAlchemyRecipe()
    if not selectedAlchemyRecipeId then return nil end
    return alchemyUtilsSystem.CfgFind.FindAlchemyRecipeById(selectedAlchemyRecipeId)
end

local function canCraftSelectedAlchemyRecipe()
    local player = alchemyUtilsSystem.LocalPlayer
    local recipe = getSelectedAlchemyRecipe()
    if not recipe
        or not alchemySystem.CanUseAlchemy(player)
        or alchemySystem.IsPlayerMaterialBrewing(player)
        or not alchemySystem.CanMeetRecipeRebirth(player, recipe)
    then
        return false
    end

    local bag = alchemyUtilsSystem.PlayerData.GetPlrDataByKey(player, "Bag")
    return type(bag) == "table" and alchemySystem.CanCraftRecipe(bag, recipe)
end

local function craftSelectedAlchemyRecipe()
    if not selectedAlchemyRecipeId or not canCraftSelectedAlchemyRecipe() then return false end

    local success, result = pcall(function()
        return alchemyUtilsSystem.NetWork.InvokeServer(alchemyUtilsSystem.NetMsg.ALCHEMY_CRAFT_RECIPE, {
            recipeId = selectedAlchemyRecipeId
        })
    end)
    return success and result == true
end

createAutoAlchemyControl("Alchemy Potion Dropdown", function()
    return AutoAlchemySection:Dropdown({
        Title = "Alchemy Potion",
        Description = "Select the potion to craft automatically",
        Values = alchemyPotionOptions,
        Value = alchemyPotionOptions[1],
        SearchBarEnabled = true,
        Callback = function(value)
            selectedAlchemyRecipeId = alchemyRecipeByOption[value]
        end
    })
end)

createAutoAlchemyControl("Auto Alchemy Toggle", function()
    return AutoAlchemySection:Toggle({
        Title = "Auto Alchemy",
        Desc = "Automatically craft the selected potion when ready",
        Icon = "flask-conical",
        Value = false,
        Callback = function(state)
            autoAlchemyEnabled = state
            if not state or autoAlchemyLoopRunning then return end

            autoAlchemyLoopRunning = true
            task.spawn(function()
                while autoAlchemyEnabled do
                    if craftSelectedAlchemyRecipe() then
                        task.wait(1)
                    else
                        task.wait(0.5)
                    end
                end
                autoAlchemyLoopRunning = false
            end)
        end
    })
end)

-- Shop Tab
local ShopTab = Window:Tab({
    Title = "Shop",
    Icon = "shopping-cart"
})

-- Auto Sell Section
local AutoSellSection = ShopTab:Section({
    Title = "Auto Sell",
    Icon = "badge-dollar-sign",
    Opened = false
})

-- Auto Sell Materials
local autoSellEnabled = false
local autoSellLoopRunning = false
local maximumSellGoldValue = 1000000
local selectedSellRarities = {}
local sellRarityOptions = {}
local sellRarityByOption = {}
local sellUtilsSystem = require(game.ReplicatedFirst.AllSideCode.UtilsSystem)
local sellItemType = sellUtilsSystem.EnumMgr.ItemType.Material
local sellAlchemy = sellUtilsSystem.GetData.Alchemy

for rarity = 1, 10 do
    local option = string.format("%s (Tier %d)", pickupRarityNames[rarity], rarity)
    sellRarityOptions[#sellRarityOptions + 1] = option
    sellRarityByOption[option] = rarity
    selectedSellRarities[rarity] = true
end

assert(#sellRarityOptions == 10 and sellRarityByOption[sellRarityOptions[10]] == 10, "Auto Sell filter setup failed")

local function createAutoSellControl(name, callback)
    local success, control = pcall(callback)
    if not success then
        warn("[Magic Loot] Failed to create " .. name .. ": " .. tostring(control))
        return nil
    end
    return control
end

local function collectSellableMaterialOnlyIDs()
    local player = sellUtilsSystem.LocalPlayer
    local bag = sellUtilsSystem.PlayerData.GetPlrDataByKey(player, "Bag")
    local onlyIDList = {}
    if type(bag) ~= "table" then return onlyIDList end

    for _, item in next, bag do
        local itemID = type(item) == "table" and tonumber(item.id)
        local onlyID = type(item) == "table" and tonumber(item.onlyID)
        local locked = type(item) == "table" and (item.lock == true or item.lock == 1)

        if itemID and onlyID and not locked and tonumber(item.tp) == sellItemType then
            local config = sellUtilsSystem.CfgFind.FindCfgByID(itemID, sellItemType)
            if config then
                local rarity = math.floor(tonumber(config.xyd) or 0)
                local sellPrice = math.floor(tonumber(sellUtilsSystem.GetData.GetSellPrice(player, config)) or 0)
                local alchemyProtected = sellAlchemy and sellAlchemy.IsMarkedRecipeMaterial(player, itemID)

                if not alchemyProtected
                    and selectedSellRarities[rarity]
                    and sellPrice <= maximumSellGoldValue
                then
                    onlyIDList[#onlyIDList + 1] = onlyID
                end
            end
        end
    end

    return onlyIDList
end

local function sellMaterials(onlyIDList)
    if #onlyIDList == 0 then return false end

    local success, result = pcall(function()
        return sellUtilsSystem.NetWork.InvokeServer(sellUtilsSystem.NetMsg.SELL_MATERIAL, {
            onlyIDList = onlyIDList
        })
    end)
    return success and result == true
end

createAutoSellControl("Sell Item Rarity Dropdown", function()
    return AutoSellSection:Dropdown({
        Title = "Sell Item Rarity",
        Description = "Select one or more material rarities to sell",
        Values = sellRarityOptions,
        Value = sellRarityOptions,
        Multi = true,
        AllowNone = false,
        SearchBarEnabled = true,
        Callback = function(values)
            selectedSellRarities = {}
            for _, option in next, values do
                local rarity = sellRarityByOption[option]
                if rarity then
                    selectedSellRarities[rarity] = true
                end
            end
        end
    })
end)

createAutoSellControl("Maximum Sell Value Dropdown", function()
    return AutoSellSection:Dropdown({
        Title = "Maximum Sell Value",
        Description = "Sell materials worth this amount or less",
        Values = pickupValueOptions,
        Value = "1M",
        SearchBarEnabled = true,
        Callback = function(value)
            maximumSellGoldValue = pickupValueByOption[value] or 1000000
        end
    })
end)

createAutoSellControl("Custom Maximum Sell Value Input", function()
    return AutoSellSection:Input({
        Title = "Custom Maximum Value",
        Placeholder = "e.g. 10M, 2B, or 10000000",
        Callback = function(value)
            local customValue = parsePickupGoldValue(value)
            if customValue then
                maximumSellGoldValue = customValue
            end
        end
    })
end)

createAutoSellControl("Auto Sell Toggle", function()
    return AutoSellSection:Toggle({
        Title = "Auto Sell",
        Desc = "Automatically sell matching materials",
        Icon = "badge-dollar-sign",
        Value = false,
        Callback = function(state)
            autoSellEnabled = state
            if not state or autoSellLoopRunning then return end

            autoSellLoopRunning = true
            task.spawn(function()
                while autoSellEnabled do
                    local onlyIDList = collectSellableMaterialOnlyIDs()
                    if sellMaterials(onlyIDList) then
                        task.wait(1)
                    else
                        task.wait(0.5)
                    end
                end
                autoSellLoopRunning = false
            end)
        end
    })
end)

-- Auto Buy Section
local AutoBuySection = ShopTab:Section({
    Title = "Auto Buy",
    Icon = "shopping-cart",
    Opened = false
})

-- Variables
local autoBuyWandEnabled = false
local selectedWands = {}
local autoBuyArmourEnabled = false
local selectedArmours = {}

-- ฟังก์ชันดึงข้อมูล Wands จาก ConfigInstance
local function getWandsFromConfig()
    local ConfigInstance = require(game.ReplicatedFirst.AllSideCode.UtilsSystem).ConfigInstance
    local TranslationHelper = require(game.ReplicatedFirst.AllSideCode.ToolBasic.TranslationHelper)
    local wands = {}
    local wandNames = {}

    local weaponConf = ConfigInstance.weaponConf
    if weaponConf then
        for id, cfg in pairs(weaponConf) do
            if type(cfg) == "table" then
                local showInShop = cfg.ShowInShop
                if showInShop == nil or showInShop == 1 then
                    local price = tonumber(cfg.Price) or 0
                    if price >= 0 then
                        local zhName = cfg.ZhName or cfg.Name or cfg.Model or "Unknown"
                        local enName = TranslationHelper.TranslateByKey(zhName) or zhName
                        table.insert(wands, {
                            id = tonumber(id),
                            name = enName,
                            price = price
                        })
                    end
                end
            end
        end
    end

    table.sort(wands, function(a, b) return a.price < b.price end)

    for _, wand in ipairs(wands) do
        table.insert(wandNames, string.format("%s (%d)", wand.name, wand.price))
    end

    return wands, wandNames
end

-- ฟังก์ชันดึงข้อมูล Armour จาก ConfigInstance
local function getArmoursFromConfig()
    local ConfigInstance = require(game.ReplicatedFirst.AllSideCode.UtilsSystem).ConfigInstance
    local TranslationHelper = require(game.ReplicatedFirst.AllSideCode.ToolBasic.TranslationHelper)
    local armours = {}
    local armourNames = {}

    local armorConf = ConfigInstance.armorConf
    if armorConf then
        for id, cfg in pairs(armorConf) do
            if type(cfg) == "table" then
                local showInShop = cfg.ShowInShop
                if showInShop == nil or showInShop == 1 then
                    local price = tonumber(cfg.Price) or 0
                    if price >= 0 then
                        local zhName = cfg.ZhName or cfg.Name or cfg.Model or "Unknown"
                        local enName = TranslationHelper.TranslateByKey(zhName) or zhName
                        table.insert(armours, {
                            id = tonumber(id),
                            name = enName,
                            price = price
                        })
                    end
                end
            end
        end
    end

    table.sort(armours, function(a, b) return a.price < b.price end)

    for _, armour in ipairs(armours) do
        table.insert(armourNames, string.format("%s (%d)", armour.name, armour.price))
    end

    return armours, armourNames
end

-- ดึงข้อมูล Wands และ Armours
local wandsData, wandNames = getWandsFromConfig()
local armoursData, armourNames = getArmoursFromConfig()

-- Multi-select Dropdown for Wands
AutoBuySection:Dropdown({
    Title = "Select Wands",
    Description = "Choose wands to auto-buy",
    Values = wandNames,
    Multi = true,
    Default = {},
    Callback = function(selectedList)
        selectedWands = {}
        for _, displayName in ipairs(selectedList) do
            for i, name in ipairs(wandNames) do
                if name == displayName then
                    local wandId = wandsData[i].id
                    selectedWands[wandId] = true
                    break
                end
            end
        end
    end
})

-- Auto Buy Wands Toggle
AutoBuySection:Toggle({
    Title = "Auto Buy Selected Wands",
    Desc = "Automatically buy selected wands",
    Icon = "shopping-cart",
    Value = false,
    Callback = function(state)
        autoBuyWandEnabled = state

        if state then
            task.spawn(function()
                local successCount = 0
                while autoBuyWandEnabled do
                    for wandId, selected in pairs(selectedWands) do
                        if not autoBuyWandEnabled then break end
                        if selected then
                            local success = pcall(function()
                                game:GetService("ReplicatedStorage").Msg.RemoteFunction.NetWorkRemoteFunction:InvokeServer("购买装备", {
                                    equipID = wandId,
                                    itemType = 6
                                })
                            end)

                            if success then
                                successCount = successCount + 1
                                WindUI:Notify({
                                    Title = "Purchase Success",
                                    Content = "Bought Wand ID: " .. wandId,
                                    Duration = 3,
                                    Icon = "check-circle"
                                })
                            end
                            task.wait(0.1)
                        end
                    end
                    task.wait(1)
                end

                if successCount > 0 then
                    WindUI:Notify({
                        Title = "Auto Buy Complete",
                        Content = "Successfully bought " .. successCount .. " wands",
                        Duration = 5,
                        Icon = "shopping-cart"
                    })
                end
            end)
        end
    end
})

-- Multi-select Dropdown for Armour
AutoBuySection:Dropdown({
    Title = "Select Armour",
    Description = "Choose armour to auto-buy",
    Values = armourNames,
    Multi = true,
    Default = {},
    Callback = function(selectedList)
        selectedArmours = {}
        for _, displayName in ipairs(selectedList) do
            for i, name in ipairs(armourNames) do
                if name == displayName then
                    local armourId = armoursData[i].id
                    selectedArmours[armourId] = true
                    break
                end
            end
        end
    end
})

-- Auto Buy Armour Toggle
AutoBuySection:Toggle({
    Title = "Auto Buy Selected Armour",
    Desc = "Automatically buy selected armour",
    Icon = "shield",
    Value = false,
    Callback = function(state)
        autoBuyArmourEnabled = state

        if state then
            task.spawn(function()
                local successCount = 0
                while autoBuyArmourEnabled do
                    for armourId, selected in pairs(selectedArmours) do
                        if not autoBuyArmourEnabled then break end
                        if selected then
                            local success = pcall(function()
                                game:GetService("ReplicatedStorage").Msg.RemoteFunction.NetWorkRemoteFunction:InvokeServer("购买装备", {
                                    equipID = armourId,
                                    itemType = 13
                                })
                            end)

                            if success then
                                successCount = successCount + 1
                                WindUI:Notify({
                                    Title = "Purchase Success",
                                    Content = "Bought Armour ID: " .. armourId,
                                    Duration = 3,
                                    Icon = "check-circle"
                                })
                            end
                            task.wait(0.1)
                        end
                    end
                    task.wait(1)
                end

                if successCount > 0 then
                    WindUI:Notify({
                        Title = "Auto Buy Complete",
                        Content = "Successfully bought " .. successCount .. " armours",
                        Duration = 5,
                        Icon = "shield"
                    })
                end
            end)
        end
    end
})

-- Event Tab
local EventTab = Window:Tab({
    Title = "Event",
    Icon = "calendar-days"
})

-- Event Dino Treasures Section
local EventDinoTreasuresSection = EventTab:Section({
    Title = "Event Dino Treasures",
    Icon = "gem",
    Opened = false
})

-- Dino Treasures Event
local eventDinoUtilsSystem = require(game.ReplicatedFirst.AllSideCode.UtilsSystem)
local autoBuyEventShopEnabled = false
local autoBuyEventShopLoopRunning = false
local selectedEventShopId = nil
local autoClaimEventQuestsEnabled = false
local autoClaimEventQuestsLoopRunning = false
local autoEventRollEnabled = false
local autoEventRollLoopRunning = false
local eventShopOptions = {}
local eventShopIdByOption = {}
local eventTaskResetTypes = {
    eventDinoUtilsSystem.EnumMgr.TaskResetType.Timed,
    eventDinoUtilsSystem.EnumMgr.TaskResetType.Daily,
    eventDinoUtilsSystem.EnumMgr.TaskResetType.Once
}

local function createDinoEventControl(name, callback)
    local success, control = pcall(callback)
    if not success then
        warn("[Magic Loot] Failed to create " .. name .. ": " .. tostring(control))
        return nil
    end
    return control
end

for _, shopRow in next, eventDinoUtilsSystem.CfgFind.GetEventShopList() do
    local shopId = math.floor(tonumber(shopRow.id) or 0)
    local itemId = tonumber(shopRow.ItemId)
    local itemConfig = itemId and eventDinoUtilsSystem.CfgFind.FindCfgByID(itemId)
    if shopId > 0 and itemConfig then
        local itemName = itemConfig.ZhName or itemConfig.Name or ("Item " .. itemId)
        local translatedName = eventDinoUtilsSystem.TranslationHelper.TranslateByKey(itemName) or itemName
        local price = math.max(0, math.floor(tonumber(shopRow.price) or 0))
        local option = string.format("%s - %d Tokens (Shop %d)", translatedName, price, shopId)
        eventShopOptions[#eventShopOptions + 1] = option
        eventShopIdByOption[option] = shopId
    end
end

table.sort(eventShopOptions, function(left, right)
    return (eventShopIdByOption[left] or 0) < (eventShopIdByOption[right] or 0)
end)
selectedEventShopId = eventShopIdByOption[eventShopOptions[1]]

assert(#eventShopOptions > 0 and selectedEventShopId, "Dino Event shop setup failed")

local function getEventShopRow(shopId)
    for _, shopRow in next, eventDinoUtilsSystem.CfgFind.GetEventShopList() do
        if math.floor(tonumber(shopRow.id) or 0) == shopId then
            return shopRow
        end
    end
    return nil
end

local function getEventShopRemain(shopId, shopRow)
    local eventData = eventDinoUtilsSystem.PlayerData.GetPlrDataByKey(eventDinoUtilsSystem.LocalPlayer, "Event")
    local bought = type(eventData) == "table"
        and type(eventData.Shop) == "table"
        and tonumber(eventData.Shop[tostring(shopId)])
        or 0
    local stock = eventDinoUtilsSystem.CfgFind.ParseEventShopStock(shopRow)
    return eventDinoUtilsSystem.CfgFind.GetEventShopRemain(bought or 0, stock)
end

local function buySelectedEventShopItem()
    if not selectedEventShopId or not eventDinoUtilsSystem.CfgFind.IsEventActive() then return false end
    local shopRow = getEventShopRow(selectedEventShopId)
    if not shopRow or getEventShopRemain(selectedEventShopId, shopRow) <= 0 then return false end

    local currencyId = eventDinoUtilsSystem.CfgFind.GetEventCurrencyItemId()
    local currency = currencyId and eventDinoUtilsSystem.GetData.GetItemCountByIDOnClient(currencyId) or 0
    local price = math.max(0, math.floor(tonumber(shopRow.price) or 0))
    if not currencyId or currency < price then return false end

    local success, result = pcall(function()
        return eventDinoUtilsSystem.NetWork.InvokeServer(
            eventDinoUtilsSystem.NetMsg.EVENT_SHOP_BUY,
            selectedEventShopId
        )
    end)
    return success and result == true
end

local function getActiveEventTaskTags(resetType, eventTask)
    local onceState = type(eventTask.Once) == "table" and eventTask.Once or {}
    local completedOnce = type(onceState.Completed) == "table" and onceState.Completed or {}
    local gameConfig = eventDinoUtilsSystem.CfgFind.GetEventGameConfig()
    local onceRefill = gameConfig.OnceTaskRefill == true
    local maxTasks = math.max(1, math.floor(tonumber(gameConfig.MaxTasksPerResetType) or 3))
    local onceType = eventDinoUtilsSystem.EnumMgr.TaskResetType.Once

    if resetType == onceType and not onceRefill and type(onceState.Accepted) == "table" and #onceState.Accepted > 0 then
        local accepted = {}
        for _, onlyTag in next, onceState.Accepted do
            onlyTag = tostring(onlyTag or "")
            if onlyTag ~= "" then accepted[#accepted + 1] = onlyTag end
        end
        return accepted
    end

    local tags = {}
    for _, taskConfig in next, eventDinoUtilsSystem.CfgFind.GetTaskListByResetType(resetType) do
        local onlyTag = tostring(taskConfig.onlyTag or "")
        if onlyTag ~= "" and (resetType ~= onceType or tonumber(completedOnce[onlyTag]) ~= 1) then
            tags[#tags + 1] = onlyTag
            if #tags >= maxTasks then break end
        end
    end
    return tags
end

local function getClaimableEventQuestTags()
    local eventData = eventDinoUtilsSystem.PlayerData.GetPlrDataByKey(eventDinoUtilsSystem.LocalPlayer, "Event")
    local eventTask = type(eventData) == "table" and eventData.EventTask or nil
    local claimableTags = {}
    if not eventDinoUtilsSystem.CfgFind.IsEventActive() or type(eventTask) ~= "table" then
        return claimableTags
    end

    local resetTypeKeys = {
        [eventDinoUtilsSystem.EnumMgr.TaskResetType.Timed] = "Timed",
        [eventDinoUtilsSystem.EnumMgr.TaskResetType.Daily] = "Daily",
        [eventDinoUtilsSystem.EnumMgr.TaskResetType.Once] = "Once"
    }

    for _, resetType in next, eventTaskResetTypes do
        local state = type(eventTask[resetTypeKeys[resetType]]) == "table" and eventTask[resetTypeKeys[resetType]] or {}
        local progress = type(state.Progress) == "table" and state.Progress or {}
        local completed = type(state.Completed) == "table" and state.Completed or {}

        for _, onlyTag in next, getActiveEventTaskTags(resetType, eventTask) do
            local taskConfig = eventDinoUtilsSystem.CfgFind.GetTaskCfgByOnlyTag(onlyTag)
            if taskConfig then
                local need = type(taskConfig.need) == "table" and taskConfig.need[1] or taskConfig.need
                need = math.max(1, math.floor(tonumber(need) or 1))
                local current = math.floor(tonumber(progress[onlyTag]) or 0)
                if tonumber(completed[onlyTag]) ~= 1 and current >= need then
                    claimableTags[#claimableTags + 1] = onlyTag
                end
            end
        end
    end

    return claimableTags
end

local function claimEventQuest(onlyTag)
    local success, result = pcall(function()
        return eventDinoUtilsSystem.NetWork.InvokeServer(
            eventDinoUtilsSystem.NetMsg.EVENT_TASK_CLAIM,
            onlyTag
        )
    end)
    return success and result == true
end

local function rollDinoEventTicket()
    if not eventDinoUtilsSystem.CfgFind.IsEventActive() then return false end
    local ticketId = eventDinoUtilsSystem.EnumMgr.ItemID.EventTicket
    local ticketCount = eventDinoUtilsSystem.GetData.GetItemCountByIDOnClient(ticketId) or 0
    if ticketCount <= 0 then return false end

    local success, result = pcall(function()
        return eventDinoUtilsSystem.NetWork.InvokeServer(
            eventDinoUtilsSystem.NetMsg.EVENT_HATCH_DRAW,
            "ticket"
        )
    end)
    return success and type(result) == "table"
        and type(result.itemIds) == "table"
        and #result.itemIds > 0
end

createDinoEventControl("Event Shop Item Dropdown", function()
    return EventDinoTreasuresSection:Dropdown({
        Title = "Event Shop Item",
        Description = "Select the item to buy with Event Tokens",
        Values = eventShopOptions,
        Value = eventShopOptions[1],
        SearchBarEnabled = true,
        Callback = function(value)
            selectedEventShopId = eventShopIdByOption[value]
        end
    })
end)

createDinoEventControl("Auto Buy Event Shop Toggle", function()
    return EventDinoTreasuresSection:Toggle({
        Title = "Auto Buy Event Shop",
        Desc = "Automatically buy the selected item while currency and stock remain",
        Icon = "shopping-cart",
        Value = false,
        Callback = function(state)
            autoBuyEventShopEnabled = state
            if not state or autoBuyEventShopLoopRunning then return end

            autoBuyEventShopLoopRunning = true
            task.spawn(function()
                while autoBuyEventShopEnabled do
                    task.wait(buySelectedEventShopItem() and 0.75 or 2)
                end
                autoBuyEventShopLoopRunning = false
            end)
        end
    })
end)

createDinoEventControl("Auto Claim Event Quests Toggle", function()
    return EventDinoTreasuresSection:Toggle({
        Title = "Auto Claim Quests Event",
        Desc = "Automatically claim completed Dino Event quests",
        Icon = "list-checks",
        Value = false,
        Callback = function(state)
            autoClaimEventQuestsEnabled = state
            if not state or autoClaimEventQuestsLoopRunning then return end

            autoClaimEventQuestsLoopRunning = true
            task.spawn(function()
                while autoClaimEventQuestsEnabled do
                    local claimableTags = getClaimableEventQuestTags()
                    local claimedAny = false

                    for _, onlyTag in next, claimableTags do
                        if not autoClaimEventQuestsEnabled then break end
                        if claimEventQuest(onlyTag) then claimedAny = true end
                        task.wait(0.75)
                    end

                    task.wait(claimedAny and 1 or 2)
                end
                autoClaimEventQuestsLoopRunning = false
            end)
        end
    })
end)

createDinoEventControl("Auto Dino Event Roll Toggle", function()
    return EventDinoTreasuresSection:Toggle({
        Title = "Auto Roll",
        Desc = "Automatically roll with Event Tickets only; never uses Robux",
        Icon = "dices",
        Value = false,
        Callback = function(state)
            autoEventRollEnabled = state
            if not state or autoEventRollLoopRunning then return end

            autoEventRollLoopRunning = true
            task.spawn(function()
                while autoEventRollEnabled do
                    task.wait(rollDinoEventTicket() and 0.75 or 2)
                end
                autoEventRollLoopRunning = false
            end)
        end
    })
end)

-- Trade Tab
local TradeTab = Window:Tab({
    Title = "Trade",
    Icon = "handshake"
})

-- Auto Gift Section
local AutoGiftSection = TradeTab:Section({
    Title = "Auto Gift",
    Icon = "gift",
    Opened = false
})

-- Auto Gift
local autoGiftEnabled = false
local autoGiftLoopRunning = false
local selectedGiftPlayerUserId = nil
local selectedGiftPotionIds = {}
local selectedGiftMaterialIds = {}
local giftPlayerDropdown = nil
local giftPlayerByOption = {}
local giftUtilsSystem = require(game.ReplicatedFirst.AllSideCode.UtilsSystem)
local giftPlayers = game:GetService("Players")
local giftPotionType = giftUtilsSystem.EnumMgr.ItemType.Potion
local giftMaterialType = giftUtilsSystem.EnumMgr.ItemType.Material
local giftAlchemy = giftUtilsSystem.GetData.Alchemy

local function createAutoGiftControl(name, callback)
    local success, control = pcall(callback)
    if not success then
        warn("[Magic Loot] Failed to create " .. name .. ": " .. tostring(control))
        return nil
    end
    return control
end

local function buildGiftPlayerOptions()
    local options = {}
    giftPlayerByOption = {}

    for _, player in next, giftPlayers:GetPlayers() do
        if player ~= giftPlayers.LocalPlayer then
            local option = player.DisplayName == player.Name
                and player.Name
                or string.format("%s (@%s)", player.DisplayName, player.Name)
            options[#options + 1] = option
            giftPlayerByOption[option] = player.UserId
        end
    end

    table.sort(options)
    if #options == 0 then
        options[1] = "No players available"
    end
    return options
end

local function buildGiftItemOptions(configName, itemType)
    local options = {}
    local itemIdByOption = {}
    local config = giftUtilsSystem.CfgFind.GetCfgByName(configName) or {}

    for configId, itemConfig in next, config do
        local itemId = tonumber(configId)
        local paidPotion = itemType == giftPotionType and itemConfig and itemConfig.Pay == true
        if itemId and type(itemConfig) == "table" and tonumber(itemConfig.tp) == itemType and not paidPotion then
            local itemName = itemConfig.ZhName or itemConfig.Name or ("Item " .. itemId)
            local translatedName = giftUtilsSystem.TranslationHelper.TranslateByKey(itemName) or itemName
            local option = string.format("%s (ID %d)", translatedName, itemId)
            options[#options + 1] = option
            itemIdByOption[option] = itemId
        end
    end

    table.sort(options)
    return options, itemIdByOption
end

local giftPotionOptions, giftPotionIdByOption = buildGiftItemOptions("potionConf", giftPotionType)
local giftMaterialOptions, giftMaterialIdByOption = buildGiftItemOptions("materialConf", giftMaterialType)

assert(#giftPotionOptions > 0 and #giftMaterialOptions > 0, "Auto Gift item setup failed")

local function findBagItemByOnlyId(bag, onlyId)
    for _, item in next, bag do
        if type(item) == "table" and tonumber(item.onlyID) == onlyId then
            return item
        end
    end
    return nil
end

local function getSelectedGiftItems()
    local player = giftPlayers.LocalPlayer
    local bag = giftUtilsSystem.PlayerData.GetPlrDataByKey(player, "Bag")
    local items = {}
    if type(bag) ~= "table" then return items end

    for _, item in next, bag do
        local itemId = type(item) == "table" and tonumber(item.id)
        local onlyId = type(item) == "table" and tonumber(item.onlyID)
        local itemType = type(item) == "table" and tonumber(item.tp)
        local locked = type(item) == "table" and (item.lock == true or item.lock == 1)
        local selected = itemType == giftPotionType and selectedGiftPotionIds[itemId]
            or itemType == giftMaterialType and selectedGiftMaterialIds[itemId]

        if itemId and onlyId and selected and not locked then
            local config = giftUtilsSystem.CfgFind.FindCfgByID(itemId, itemType)
            local paidPotion = itemType == giftPotionType and config and config.Pay == true
            local alchemyProtected = itemType == giftMaterialType
                and giftAlchemy
                and giftAlchemy.IsMarkedRecipeMaterial(player, itemId)

            if config and not paidPotion and not alchemyProtected then
                items[#items + 1] = {
                    itemId = itemId,
                    onlyId = onlyId,
                    itemType = itemType
                }
            end
        end
    end

    table.sort(items, function(left, right)
        return left.onlyId < right.onlyId
    end)
    return items
end

local function waitForGiftHeldOnlyId(onlyId, timeoutSeconds)
    local deadline = os.clock() + timeoutSeconds
    while autoGiftEnabled and os.clock() < deadline do
        if giftUtilsSystem.GetData.GetHeldToolbarOnlyId(giftPlayers.LocalPlayer) == onlyId then
            return true
        end
        task.wait(0.1)
    end
    return false
end

local function holdGiftItem(onlyId)
    local player = giftPlayers.LocalPlayer
    if giftUtilsSystem.GetData.GetHeldToolbarOnlyId(player) == onlyId then
        return true, nil
    end

    local bag = giftUtilsSystem.PlayerData.GetPlrDataByKey(player, "Bag")
    if type(bag) ~= "table" or not findBagItemByOnlyId(bag, onlyId) then return false, nil end

    local slotMin = giftUtilsSystem.GetData.GetBackpackToolbarItemSlotMin()
    local slotMax = giftUtilsSystem.GetData.GetBackpackToolbarItemSlotMax()
    local targetSlot = nil
    local displacedOnlyId = nil

    for slot = slotMin, slotMax do
        local toolbarItem = giftUtilsSystem.GetData.GetBackpackToolbarItemAtUiSlot(bag, slot, player)
        if toolbarItem and tonumber(toolbarItem.onlyID) == onlyId then
            targetSlot = slot
            break
        end
        if not targetSlot and not toolbarItem then
            targetSlot = slot
        end
    end

    if not targetSlot then
        targetSlot = slotMin
        local toolbarItem = giftUtilsSystem.GetData.GetBackpackToolbarItemAtUiSlot(bag, targetSlot, player)
        displacedOnlyId = toolbarItem and tonumber(toolbarItem.onlyID) or nil
    end

    local toolbarItem = giftUtilsSystem.GetData.GetBackpackToolbarItemAtUiSlot(bag, targetSlot, player)
    if not toolbarItem or tonumber(toolbarItem.onlyID) ~= onlyId then
        giftUtilsSystem.NetWork.FireServer(giftUtilsSystem.NetMsg.BACKPACK_TOOLBAR_DRAG, {
            from = { zone = "warehouse", onlyID = onlyId },
            to = { zone = "toolbar", equipSlot = targetSlot }
        })
        task.wait(0.35)
    end

    giftUtilsSystem.NetWork.FireServer(giftUtilsSystem.NetMsg.BACKPACK_TOGGLE_HELD, {
        uiSlotIndex = targetSlot
    })
    return waitForGiftHeldOnlyId(onlyId, 2), displacedOnlyId and {
        onlyId = displacedOnlyId,
        slot = targetSlot
    } or nil
end

local function restoreGiftToolbarSlot(restoreData)
    if not restoreData then return end
    giftUtilsSystem.NetWork.FireServer(giftUtilsSystem.NetMsg.BACKPACK_TOOLBAR_DRAG, {
        from = { zone = "warehouse", onlyID = restoreData.onlyId },
        to = { zone = "toolbar", equipSlot = restoreData.slot }
    })
end

local function giftItemToSelectedPlayer(item)
    local targetPlayer = selectedGiftPlayerUserId and giftPlayers:GetPlayerByUserId(selectedGiftPlayerUserId)
    if not targetPlayer or targetPlayer == giftPlayers.LocalPlayer then return false end

    local held, restoreData = holdGiftItem(item.onlyId)
    if not held then return false end

    local bagBefore = giftUtilsSystem.PlayerData.GetPlrDataByKey(giftPlayers.LocalPlayer, "Bag")
    local itemBefore = type(bagBefore) == "table" and findBagItemByOnlyId(bagBefore, item.onlyId)
    local countBefore = itemBefore and math.max(1, math.floor(tonumber(itemBefore.count) or 1)) or 0
    if countBefore <= 0 then
        restoreGiftToolbarSlot(restoreData)
        return false
    end

    giftUtilsSystem.NetWork.FireServer(giftUtilsSystem.NetMsg.GIFT_REQUEST, targetPlayer.UserId)
    local deadline = os.clock() + 4
    local gifted = false

    while autoGiftEnabled and os.clock() < deadline do
        local bag = giftUtilsSystem.PlayerData.GetPlrDataByKey(giftPlayers.LocalPlayer, "Bag")
        local currentItem = type(bag) == "table" and findBagItemByOnlyId(bag, item.onlyId)
        local currentCount = currentItem and math.max(0, math.floor(tonumber(currentItem.count) or 0)) or 0
        if not currentItem or currentCount < countBefore then
            gifted = true
            break
        end
        task.wait(0.1)
    end

    restoreGiftToolbarSlot(restoreData)
    return gifted
end

local initialGiftPlayerOptions = buildGiftPlayerOptions()
selectedGiftPlayerUserId = giftPlayerByOption[initialGiftPlayerOptions[1]]

giftPlayerDropdown = createAutoGiftControl("Gift Player Dropdown", function()
    return AutoGiftSection:Dropdown({
        Title = "Gift Player",
        Description = "Select the player who will receive the gifts",
        Values = initialGiftPlayerOptions,
        Value = initialGiftPlayerOptions[1],
        SearchBarEnabled = true,
        Callback = function(value)
            selectedGiftPlayerUserId = giftPlayerByOption[value]
        end
    })
end)

createAutoGiftControl("Refresh Gift Players Button", function()
    return AutoGiftSection:Button({
        Title = "Refresh Players",
        Desc = "Refresh the list of players in this server",
        Icon = "refresh-cw",
        Color = Color3.fromRGB(220, 50, 50),
        Callback = function()
            local options = buildGiftPlayerOptions()
            selectedGiftPlayerUserId = giftPlayerByOption[options[1]]
            if giftPlayerDropdown then
                giftPlayerDropdown:Refresh(options)
                giftPlayerDropdown:Select(options[1])
            end
        end
    })
end)

createAutoGiftControl("Gift Potions Dropdown", function()
    return AutoGiftSection:Dropdown({
        Title = "Gift Potions",
        Description = "Select one or more potion types to gift",
        Values = giftPotionOptions,
        Value = {},
        Multi = true,
        AllowNone = true,
        SearchBarEnabled = true,
        Callback = function(values)
            selectedGiftPotionIds = {}
            for _, option in next, values do
                local itemId = giftPotionIdByOption[option]
                if itemId then selectedGiftPotionIds[itemId] = true end
            end
        end
    })
end)

createAutoGiftControl("Gift Materials Dropdown", function()
    return AutoGiftSection:Dropdown({
        Title = "Gift Materials",
        Description = "Select one or more material types to gift",
        Values = giftMaterialOptions,
        Value = {},
        Multi = true,
        AllowNone = true,
        SearchBarEnabled = true,
        Callback = function(values)
            selectedGiftMaterialIds = {}
            for _, option in next, values do
                local itemId = giftMaterialIdByOption[option]
                if itemId then selectedGiftMaterialIds[itemId] = true end
            end
        end
    })
end)

createAutoGiftControl("Auto Gift Toggle", function()
    return AutoGiftSection:Toggle({
        Title = "Auto Gift",
        Desc = "Automatically gift selected potions and materials",
        Icon = "gift",
        Value = false,
        Callback = function(state)
            autoGiftEnabled = state
            if not state or autoGiftLoopRunning then return end

            autoGiftLoopRunning = true
            task.spawn(function()
                while autoGiftEnabled do
                    local items = getSelectedGiftItems()
                    local attempted = false

                    for _, item in next, items do
                        if not autoGiftEnabled then break end
                        attempted = true
                        giftItemToSelectedPlayer(item)
                        task.wait(0.5)
                    end

                    task.wait(attempted and 0.5 or 1)
                end
                autoGiftLoopRunning = false
            end)
        end
    })
end)

-- Keep the built-in Misc and Settings tabs below the custom tabs.
-- Ensure sections remain collapsed after WindUI finishes laying out their controls.
task.defer(function()
    AutoFarmSection:Close()
    AutoGameSection:Close()
    AutoAlchemySection:Close()
    AutoSellSection:Close()
    AutoBuySection:Close()
    EventDinoTreasuresSection:Close()
    AutoGiftSection:Close()
end)

Window:InitBaseTabs()
