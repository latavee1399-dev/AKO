-- LOAD MAP

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- SERVICES

local cloneref = cloneref or function(instance)
    return instance
end

local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

if _G.RideAPetUiCleanup then
    pcall(_G.RideAPetUiCleanup)
end

if _G.RideAPetEggWorldCleanup then
    pcall(_G.RideAPetEggWorldCleanup)
end

-- CONFIG

Config = Config or {
    ["Auto Pick Egg Best"] = false,
    ["Selected Eggs"] = {},
    ["Tween Speed"] = 300,
}

if Config["Auto Pick Egg Best"] == nil then
    Config["Auto Pick Egg Best"] = false
end

if type(Config["Selected Eggs"]) ~= "table" then
    Config["Selected Eggs"] = {}
end

local TweenSpeedConfig = tonumber(Config["Tween Speed"])

if not TweenSpeedConfig or TweenSpeedConfig < 20 or TweenSpeedConfig > 300 then
    Config["Tween Speed"] = 180
end

Ex_Function = Ex_Function or {}

-- MODULES

local EggsData = require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("Eggs"))
local ServerData = ReplicatedStorage:FindFirstChild("ServerData")
local ActiveEggs = (ServerData and ServerData:FindFirstChild("ActiveEggs"))
    or ReplicatedStorage:FindFirstChild("ActiveEggs")
    or workspace:FindFirstChild("ActiveEggs")

local ActiveEggContainer
local ActiveEggConnections = {}
local ActiveEggChildConnections = {}
local EggSelector
local EggsWorldParagraph
local EggRefreshQueued = false
local EggWorldSnapshot
local EggOptionsSnapshot
local RefreshEggWorldUi

-- FUNCTIONS

local function GetRootPart()
    local Character = LocalPlayer.Character
    return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local Character = LocalPlayer.Character
    return Character and Character:FindFirstChildOfClass("Humanoid")
end

local function GetBasketCount()
    local Basket = LocalPlayer:FindFirstChild("Basket")
    return Basket and #Basket:GetChildren() or 0
end

local function GetMyPlot()
    local Plots = workspace:FindFirstChild("Plots")

    if not Plots then
        return nil
    end

    for _, Plot in Plots:GetChildren() do
        local Data = Plot:FindFirstChild("Data")
        local Owner = Data and Data:FindFirstChild("Owner")

        if Owner and Owner.Value == LocalPlayer then
            return Plot
        end
    end

    return nil
end

local function ForEachDescendant(Root, Callback)
    for _, Child in Root:GetChildren() do
        Callback(Child)
        ForEachDescendant(Child, Callback)
    end
end

local function GetActiveEggsFolder()
    if ActiveEggs and ActiveEggs.Parent then
        return ActiveEggs
    end

    local ServerDataFolder = ReplicatedStorage:FindFirstChild("ServerData")
    local Candidates = {
        ServerDataFolder and ServerDataFolder:FindFirstChild("ActiveEggs"),
        ReplicatedStorage:FindFirstChild("ActiveEggs"),
        workspace:FindFirstChild("ActiveEggs"),
    }

    for _, Candidate in Candidates do
        if Candidate and Candidate.Parent then
            ActiveEggs = Candidate
            return Candidate
        end
    end

    return nil
end

local function GetActiveEggName(ActiveEgg)
    local EggName = ActiveEgg and ActiveEgg:GetAttribute("Egg")
    return type(EggName) == "string" and EggName ~= "" and EggName or nil
end

local function CopyEggSelection(Value)
    local Selection = {}
    local Seen = {}

    local function AddEgg(Egg)
        if type(Egg) == "table" then
            Egg = Egg.Title or Egg.Name
        end

        if type(Egg) == "string" and Egg ~= "" and not Seen[Egg] then
            Seen[Egg] = true
            table.insert(Selection, Egg)
        end
    end

    if type(Value) == "table" then
        for Key, Egg in pairs(Value) do
            if Egg == true and type(Key) == "string" then
                AddEgg(Key)
            else
                AddEgg(Egg)
            end
        end
    else
        AddEgg(Value)
    end

    return Selection
end

local function GetSelectedEggSet()
    local SelectedEggs = CopyEggSelection(Config["Selected Eggs"])
    local SelectedEggSet = {}

    for _, EggName in SelectedEggs do
        SelectedEggSet[EggName] = true
    end

    return SelectedEggSet, #SelectedEggs
end

local function DisconnectEggConnectionList(ConnectionList)
    for _, Connection in pairs(ConnectionList) do
        pcall(function()
            Connection:Disconnect()
        end)
    end
end

local function UnbindActiveEggChild(ActiveEgg)
    local Connections = ActiveEggChildConnections[ActiveEgg]

    if Connections then
        DisconnectEggConnectionList(Connections)
        ActiveEggChildConnections[ActiveEgg] = nil
    end
end

local function RequestEggWorldRefresh()
    if EggRefreshQueued then
        return
    end

    EggRefreshQueued = true

    task.delay(0.12, function()
        EggRefreshQueued = false

        if RefreshEggWorldUi then
            pcall(RefreshEggWorldUi)
        end
    end)
end

local function BindActiveEggChild(ActiveEgg)
    if not ActiveEgg or ActiveEggChildConnections[ActiveEgg] then
        return
    end

    local Connections = {}

    for _, AttributeName in {"Egg", "Position", "PrivateTo", "Weight"} do
        table.insert(Connections, ActiveEgg:GetAttributeChangedSignal(AttributeName):Connect(RequestEggWorldRefresh))
    end

    ActiveEggChildConnections[ActiveEgg] = Connections
end

local function BindActiveEggs(Container)
    if ActiveEggContainer == Container then
        return
    end

    DisconnectEggConnectionList(ActiveEggConnections)

    local PreviousChildConnections = ActiveEggChildConnections

    for _, Connections in pairs(PreviousChildConnections) do
        DisconnectEggConnectionList(Connections)
    end

    ActiveEggConnections = {}
    ActiveEggChildConnections = {}
    ActiveEggContainer = Container

    if not Container then
        return
    end

    table.insert(ActiveEggConnections, Container.ChildAdded:Connect(function(ActiveEgg)
        BindActiveEggChild(ActiveEgg)
        RequestEggWorldRefresh()
    end))

    table.insert(ActiveEggConnections, Container.ChildRemoved:Connect(function(ActiveEgg)
        UnbindActiveEggChild(ActiveEgg)
        RequestEggWorldRefresh()
    end))

    for _, ActiveEgg in Container:GetChildren() do
        BindActiveEggChild(ActiveEgg)
    end
end

local function GetEggWorldData(Container)
    local EggCounts = {}
    local TotalEggs = 0

    if Container then
        for _, ActiveEgg in Container:GetChildren() do
            local EggName = GetActiveEggName(ActiveEgg)
            local Position = ActiveEgg:GetAttribute("Position")

            if EggName and typeof(Position) == "Vector3" then
                EggCounts[EggName] = (EggCounts[EggName] or 0) + 1
                TotalEggs = TotalEggs + 1
            end
        end
    end

    local EggNames = {}

    for EggName in pairs(EggCounts) do
        table.insert(EggNames, EggName)
    end

    table.sort(EggNames, function(Left, Right)
        local LeftLower = string.lower(Left)
        local RightLower = string.lower(Right)

        if LeftLower == RightLower then
            return Left < Right
        end

        return LeftLower < RightLower
    end)

    local Summary = {}

    for _, EggName in EggNames do
        table.insert(Summary, string.format("%s x%d", EggName, EggCounts[EggName]))
    end

    local Content

    if #Summary == 0 then
        Content = Container and "No eggs currently in world." or "Waiting for active eggs..."
    else
        Content = table.concat(Summary, "\n") .. string.format("\n\nTotal: %d", TotalEggs)
    end

    return EggNames, Content
end

local function HaveSameEggNames(Left, Right)
    if not Left or not Right or #Left ~= #Right then
        return false
    end

    for Index, EggName in Left do
        if EggName ~= Right[Index] then
            return false
        end
    end

    return true
end

RefreshEggWorldUi = function()
    local Container = GetActiveEggsFolder()

    if Container ~= ActiveEggContainer then
        BindActiveEggs(Container)
    end

    local EggNames, Content = GetEggWorldData(Container)
    local OptionsChanged = not HaveSameEggNames(EggNames, EggOptionsSnapshot)
    local ContentChanged = Content ~= EggWorldSnapshot

    if OptionsChanged and EggSelector then
        pcall(function()
            EggSelector:Refresh(EggNames, true)
        end)
    end

    if ContentChanged and EggsWorldParagraph then
        pcall(function()
            EggsWorldParagraph:SetDesc(Content)
        end)
    end

    EggOptionsSnapshot = EggNames
    EggWorldSnapshot = Content
end

local ActiveTween
local NoclipConnection

local function SetNoclip(Enabled)
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end

    local Character = LocalPlayer.Character
    if not Character then
        return
    end

    if Enabled then
        NoclipConnection = RunService.Stepped:Connect(function()
            if Config["Auto Pick Egg Best"] then
                local CurrentCharacter = LocalPlayer.Character

                if CurrentCharacter then
                    ForEachDescendant(CurrentCharacter, function(Part)
                        if Part:IsA("BasePart") then
                            Part.CanCollide = false
                        end
                    end)
                end
            end
        end)
    else
        ForEachDescendant(Character, function(Part)
            if Part:IsA("BasePart") and Part.Name ~= "HumanoidRootPart" then
                Part.CanCollide = true
            end
        end)
    end
end

local function CancelActiveTween()
    if ActiveTween then
        ActiveTween:Cancel()
        ActiveTween:Destroy()
        ActiveTween = nil
    end
end

local function TweenCharacter(Position)
    local RootPart = GetRootPart()

    if not RootPart or typeof(Position) ~= "Vector3" or not Config["Auto Pick Egg Best"] then
        return false
    end

    local TargetPosition = Position + Vector3.new(0, 3, 0)
    local Distance = (RootPart.Position - TargetPosition).Magnitude

    if Distance <= 3 then
        return true
    end

    CancelActiveTween()
    SetNoclip(true)

    local TweenSpeed = tonumber(Config["Tween Speed"]) or 160
    local Tween = TweenService:Create(
        RootPart,
        TweenInfo.new(math.max(0.25, Distance / TweenSpeed), Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {
            CFrame = CFrame.new(TargetPosition, TargetPosition + RootPart.CFrame.LookVector),
        }
    )

    ActiveTween = Tween

    local Completed = false
    local PlaybackState
    local Connection = Tween.Completed:Connect(function(State)
        Completed = true
        PlaybackState = State
    end)

    Tween:Play()

    while not Completed and Config["Auto Pick Egg Best"] do
        task.wait(0.05)
    end

    if not Completed then
        Tween:Cancel()
    end

    Connection:Disconnect()
    Tween:Destroy()

    if ActiveTween == Tween then
        ActiveTween = nil
    end

    SetNoclip(false)

    return Completed and PlaybackState == Enum.PlaybackState.Completed
end

local function IsEggAvailable(ActiveEgg, EggName)
    local PrivateTo = ActiveEgg:GetAttribute("PrivateTo")

    if PrivateTo ~= nil and tonumber(PrivateTo) ~= LocalPlayer.UserId then
        return false
    end

    local CollectedEggs = LocalPlayer:GetAttribute("CollectedEggs")

    if typeof(CollectedEggs) == "string" and CollectedEggs ~= "" then
        if string.find(CollectedEggs, EggName .. ",", 1, true) then
            return false
        end
    end

    return typeof(ActiveEgg:GetAttribute("Position")) == "Vector3"
end

local function GetEggValue(EggName)
    local EggInfo = EggsData[EggName]

    if type(EggInfo) == "table" then
        return tonumber(EggInfo.Luck) or 0
    end

    return tonumber(EggInfo) or 0
end

local function FindBestEgg()
    local BestEgg
    local BestValue = -1
    local BestWeight = -1
    local ActiveEggsFolder = GetActiveEggsFolder()
    local SelectedEggSet, SelectedEggCount = GetSelectedEggSet()

    if not ActiveEggsFolder then
        return nil
    end

    for _, ActiveEgg in ActiveEggsFolder:GetChildren() do
        local EggName = GetActiveEggName(ActiveEgg)

        if EggName
            and (SelectedEggCount == 0 or SelectedEggSet[EggName])
            and IsEggAvailable(ActiveEgg, EggName)
        then
            local EggValue = GetEggValue(EggName)
            local Weight = tonumber(ActiveEgg:GetAttribute("Weight")) or 0

            if EggValue > BestValue or (EggValue == BestValue and Weight > BestWeight) then
                BestEgg = ActiveEgg
                BestValue = EggValue
                BestWeight = Weight
            end
        end
    end

    return BestEgg
end

local function FindPromptInEgg(Container)
    for _, Child in Container:GetChildren() do
        if Child:IsA("ProximityPrompt") and Child.Name == "Pickup" then
            return Child
        end

        local Prompt = FindPromptInEgg(Child)

        if Prompt then
            return Prompt
        end
    end

    return nil
end

local function GetPromptPosition(Prompt)
    local Parent = Prompt and Prompt.Parent

    if Parent and Parent:IsA("BasePart") then
        return Parent.Position
    end

    if Parent and Parent:IsA("Attachment") then
        return Parent.WorldPosition
    end

    while Parent and Parent ~= workspace do
        if Parent:IsA("BasePart") then
            return Parent.Position
        end

        Parent = Parent.Parent
    end

    return nil
end

local function FindRenderedEggPrompt(EggName, Position)
    local RenderedEggs = workspace:FindFirstChild("RenderedEggs")
    local BestPrompt
    local BestPosition
    local BestDistance = math.huge

    if not RenderedEggs or typeof(Position) ~= "Vector3" then
        return nil
    end

    for _, EggModel in RenderedEggs:GetChildren() do
        if EggModel.Name == EggName then
            local Prompt = FindPromptInEgg(EggModel)
            local PromptPosition = GetPromptPosition(Prompt)

            if Prompt and Prompt.Enabled and PromptPosition then
                local Distance = (PromptPosition - Position).Magnitude

                if Distance < BestDistance then
                    BestPrompt = Prompt
                    BestPosition = PromptPosition
                    BestDistance = Distance
                end
            end
        end
    end

    return BestPrompt, BestPosition
end

local function TriggerPickupPrompt(Prompt)
    if not Prompt or not Prompt.Parent or not Prompt.Enabled then
        return false
    end

    local Began = pcall(function()
        Prompt:InputHoldBegin()
    end)

    if Began then
        task.wait((tonumber(Prompt.HoldDuration) or 0) + 0.15)
        local Ended = pcall(function()
            Prompt:InputHoldEnd()
        end)

        return Ended
    end

    if fireproximityprompt then
        return pcall(function()
            fireproximityprompt(Prompt)
        end)
    end

    return false
end

local function WaitForBasketCount(Count, Timeout)
    local Deadline = os.clock() + Timeout

    while Config["Auto Pick Egg Best"] and os.clock() < Deadline do
        if GetBasketCount() >= Count then
            return true
        end

        task.wait(0.1)
    end

    return GetBasketCount() >= Count
end

local function WaitForBasketEmpty(Timeout)
    local Deadline = os.clock() + Timeout

    while Config["Auto Pick Egg Best"] and os.clock() < Deadline do
        if GetBasketCount() == 0 then
            return true
        end

        task.wait(0.1)
    end

    return GetBasketCount() == 0
end

local function ReturnToMyPlot()
    local Plot = GetMyPlot()
    local Baseplate = Plot and Plot:FindFirstChild("Baseplate")
    local Humanoid = GetHumanoid()

    if not (Baseplate and Baseplate:IsA("BasePart") and Humanoid) then
        return false
    end

    if GetBasketCount() > 0 then
        local EntryPosition = Baseplate.Position + Baseplate.CFrame.LookVector * (Baseplate.Size.Z / 2 + 8)

        if not TweenCharacter(EntryPosition) then
            return false
        end

        local Reached = false
        local Connection = Humanoid.MoveToFinished:Connect(function(DidReach)
            Reached = DidReach
        end)

        Humanoid:MoveTo(Baseplate.Position + Vector3.new(0, 3, 0))

        local Deadline = os.clock() + 8
        while not Reached and os.clock() < Deadline and Config["Auto Pick Egg Best"] do
            task.wait(0.1)
        end

        Connection:Disconnect()

        if not Reached then
            return false
        end
    end

    return WaitForBasketEmpty(5)
end

local function CollectBestEgg()
    if GetBasketCount() > 0 then
        return ReturnToMyPlot()
    end

    local BestEgg = FindBestEgg()
    local Position = BestEgg and BestEgg:GetAttribute("Position")
    local EggName = GetActiveEggName(BestEgg)

    if not (BestEgg and EggName and typeof(Position) == "Vector3") then
        return false
    end

    local Prompt, PromptPosition = FindRenderedEggPrompt(EggName, Position)

    if not (Prompt and PromptPosition) then
        return false
    end

    local BeforeCount = GetBasketCount()

    if not TweenCharacter(PromptPosition) then
        return false
    end

    task.wait(0.1)

    if not TriggerPickupPrompt(Prompt) then
        return false
    end

    if not WaitForBasketCount(BeforeCount + 1, 3) then
        return false
    end

    return ReturnToMyPlot()
end

-- LOOPS

local AutoPickRunning = false

Ex_Function["Auto Pick Egg Best"] = function()
    if AutoPickRunning then
        return
    end

    AutoPickRunning = true

    while Config["Auto Pick Egg Best"] and task.wait(0.2) do
        pcall(function()
            CollectBestEgg()
        end)
    end

    SetNoclip(false)
    AutoPickRunning = false
end

local EggWorldLoopToken = tostring(os.clock()) .. tostring({})
_G.RideAPetEggWorldLoopToken = EggWorldLoopToken

_G.RideAPetEggWorldCleanup = function()
    DisconnectEggConnectionList(ActiveEggConnections)

    local PreviousChildConnections = ActiveEggChildConnections

    for _, Connections in pairs(PreviousChildConnections) do
        DisconnectEggConnectionList(Connections)
    end

    ActiveEggConnections = {}
    ActiveEggChildConnections = {}
    ActiveEggContainer = nil

    if _G.RideAPetEggWorldLoopToken == EggWorldLoopToken then
        _G.RideAPetEggWorldLoopToken = nil
    end
end

Ex_Function["Eggs In World"] = function()
    while _G.RideAPetEggWorldLoopToken == EggWorldLoopToken and task.wait(1) do
        pcall(function()
            RefreshEggWorldUi()
        end)
    end
end

-- UI

local Window = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/latavee1399-dev/AKO/refs/heads/main/CC%20ui"
))()

_G.RideAPetUiCleanup = function()
    pcall(function()
        Window:Destroy()
    end)
end

local WindUI = Window.WindUI

local AutoGameTab = Window:Tab({
    Title = "Auto Game",
    Icon = "gamepad-2",
})

local AutoEggSection = AutoGameTab:Section({
    Title = "Auto Egg",
    Icon = "egg",
    Opened = true,
})

local InitialEggNames, InitialEggContent = GetEggWorldData(GetActiveEggsFolder())

EggsWorldParagraph = AutoEggSection:Paragraph({
    Title = "Eggs In World",
    Desc = InitialEggContent,
})

EggSelector = AutoEggSection:Dropdown({
    Title = "Eggs to Collect",
    Desc = "Select egg types; empty means all",
    Values = InitialEggNames,
    Value = CopyEggSelection(Config["Selected Eggs"]),
    Multi = true,
    AllowNone = true,
    SearchBarEnabled = true,
    Callback = function(Value)
        Config["Selected Eggs"] = CopyEggSelection(Value)
    end,
})

AutoEggSection:Toggle({
    Title = "Auto Pick Egg Best",
    Icon = "sparkles",
    Value = Config["Auto Pick Egg Best"],
    Callback = function(Value)
        Config["Auto Pick Egg Best"] = Value

        if Value then
            task.spawn(Ex_Function["Auto Pick Egg Best"])
        else
            CancelActiveTween()
            SetNoclip(false)
        end
    end,
})

AutoEggSection:Slider({
    Title = "Tween Speed",
    Icon = "gauge",
    Value = {
        Min = 20,
        Max = 320,
        Default = tonumber(Config["Tween Speed"]) or 300,
    },
    Step = 5,
    Callback = function(Value)
        Config["Tween Speed"] = tonumber(Value) or 300
    end,
})

EggWorldSnapshot = nil
EggOptionsSnapshot = nil
RefreshEggWorldUi()
task.spawn(Ex_Function["Eggs In World"])

Window:InitBaseTabs()
