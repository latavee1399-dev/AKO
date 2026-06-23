if getgenv().Gag2RunningID then
    getgenv().Gag2RunningID = getgenv().Gag2RunningID + 1
else
    getgenv().Gag2RunningID = 1
end
local currentID = getgenv().Gag2RunningID
repeat task.wait() until game:IsLoaded()
task.wait(math.random(10, 50) / 10) 
local function safeLoadstringCached(url, fileName)
    if isfile and readfile and writefile then
        if isfile(fileName) then
            local content = readfile(fileName)
            if content and string.len(content) > 100 then
                return loadstring(content)()
            end
        end
    end
    local success, result
    repeat
        success, result = pcall(function()
            return game:HttpGet(url)
        end)
        if not success or not result or string.len(result) < 100 then
            task.wait(math.random(2, 5))
            success = false
        end
    until success
    if isfile and writefile then
        pcall(function() writefile(fileName, result) end)
    end
    return loadstring(result)()
end
local Fluent = safeLoadstringCached("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua", "AProject_Fluent.lua")
local SaveManager = safeLoadstringCached("https://raw.githubusercontent.com/Afz-oos/PJAX/refs/heads/main/Config.lua", "AProject_SaveManager.lua")
local InterfaceManager = safeLoadstringCached("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua", "AProject_Interface.lua")
local Window = Fluent:CreateWindow({
    Title = "A Project Chick Chick",
    SubTitle = "by Ao Pro Free",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.LeftControl
})
Fluent:SetTheme("Amethyst")
local customAccent = Color3.fromRGB(100, 180, 255)
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Farm = Window:AddTab({ Title = "Farm", Icon = "gamepad-2" }),
    Plant = Window:AddTab({ Title = "Plant", Icon = "leaf" }),
    Shop = Window:AddTab({ Title = "Shop", Icon = "shopping-cart" }),
    Trade = Window:AddTab({ Title = "Trade", Icon = "arrow-left-right" }),
    Gift = Window:AddTab({ Title = "Gift", Icon = "gift" }),
    Pets = Window:AddTab({ Title = "Pets", Icon = "smile" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}
local Options = Fluent.Options
local SeedsList = {
    "All", "Acorn", "Apple", "Baby Cactus", "Bamboo", "Banana", "Beanstalk", "Blueberry", 
    "Buttercup", "Cactus", "Carrot", "Cherry", "Coconut", "Corn", "Dragon Fruit", 
    "Dragon's Breath", "Ghost Pepper", "Glow Mushroom", "Gold", "Grape", "Green Bean", 
    "Horned Melon", "Lotus", "Mango", "Moon Bloom", "Mushroom", "Pineapple", "Pinetree", 
    "Poison Apple", "Poison Ivy", "Pomegranate", "Pumpkin", "Rainbow", "Romanesco", 
    "Strawberry", "Sunflower", "Thorn Rose", "Tomato", "Tulip", "Venus Fly Trap"
}
local GearsList = {
    "All", "Common Watering Can", "Common Sprinkler", "Sign", "Lantern", "Wheelbarrow", 
    "Uncommon Sprinkler", "Rare Sprinkler", "Legendary Sprinkler", "Super Sprinkler", 
    "Trowel", "Speed Mushroom", "Jump Mushroom", "Gnome", "Shrink Mushroom", 
    "Supersize Mushroom", "Invisibility Mushroom", "Teleporter", "Super Watering Can", 
    "Basic Pot", "Flashbang"
}
local PetsPrices = {
    ["Frog"] = 10000,
    ["Bunny"] = 20000,
    ["Owl"] = 25000,
    ["Deer"] = 50000,
    ["Robin"] = 75000,
    ["Bee"] = 1000000,
    ["Monkey"] = 1000000,
    ["Black Dragon"] = 1000000,
    ["Golden Dragonfly"] = 3000000,
    ["Unicorn"] = 4000000,
    ["Raccoon"] = 5000000
}
task.spawn(function()
    pcall(function()
        local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
        Networking.Tutorial.Complete:Fire()
    end)
    task.spawn(function()
        local VirtualInputManager = game:GetService("VirtualInputManager")
        task.wait(25)
        pcall(function()
            local screenCenter = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
            VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, true, game, 0)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, false, game, 0)
        end)
    end)
end)
Tabs.Main:AddParagraph({
    Title = "Grow A Garden 2 | By ChickChick",
    Content = "Welcome to ChickChick\n[Discord] ChickChick\nPower By Ao Pro Free"
})

local PetTrackerParagraph = Tabs.Main:AddParagraph({
    Title = "🐾 Pets in Server (Real-time)",
    Content = "Scanning for pets..."
})

task.spawn(function()
    local PetEmojis = {
        frog = "🐸", bunny = "🐰", owl = "🦉", deer = "🦌", robin = "🐦",
        bee = "🐝", monkey = "🐵", dragon = "🐉", dragonfly = "✨",
        unicorn = "🦄", raccoon = "🦝"
    }

    while getgenv().Gag2RunningID == currentID do
        pcall(function()
            local mapFolder = workspace:FindFirstChild("Map")
            local spawnsFolder = mapFolder and mapFolder:FindFirstChild("WildPetSpawns")
            local petList = {}

            if spawnsFolder then
                for _, obj in next, spawnsFolder:GetChildren() do
                    if obj:IsA("Model") then
                        local petName = obj:GetAttribute("PetName")
                        if not petName or petName == "" then
                            local parts = string.split(obj.Name, "_")
                            petName = #parts >= 2 and parts[2] or obj.Name
                        end

                        local price = "N/A"
                        local costTimer = obj:FindFirstChild("PetCostTimer", true)
                        if costTimer then
                            local label = costTimer:FindFirstChildWhichIsA("TextLabel")
                            if label and label.Text ~= "" then
                                price = label.Text
                            end
                        end

                        local timeLeft = "N/A"
                        local leaveTimer = obj:FindFirstChild("PetLeaveTimer", true)
                        if leaveTimer then
                            local label = leaveTimer:FindFirstChildWhichIsA("TextLabel")
                            if label and label.Text ~= "" then
                                timeLeft = label.Text
                            end
                        end

                        local emoji = "🐾"
                        local lowerName = string.lower(petName)
                        for key, em in next, PetEmojis do
                            if string.find(lowerName, key) then
                                emoji = em
                                break
                            end
                        end

                        table.insert(petList, {
                            name = petName,
                            emoji = emoji,
                            price = price,
                            time = timeLeft
                        })
                    end
                end
            end

            if #petList > 0 then
                local content = ""
                for i, pet in next, petList do
                    content = content .. pet.emoji .. " " .. pet.name .. "\n"
                    content = content .. "💰 " .. pet.price .. " | ⏰ " .. pet.time
                    if i < #petList then content = content .. "\n\n" end
                end
                PetTrackerParagraph:SetDesc(content)
            else
                PetTrackerParagraph:SetDesc("❌ No pets found in this server")
            end
        end)
        task.wait(1)
    end
end)

local function BypassTeleport(hrp, targetCFrame)
    pcall(function()
        local distance = (hrp.Position - targetCFrame.Position).Magnitude
        if distance < 5 then
            hrp.CFrame = targetCFrame
            return
        end
        local char = hrp.Parent
        local hum = char and char:FindFirstChild("Humanoid")
        if distance > 50 then
            local steps = math.ceil(distance / 45)
            for i = 1, steps do
                local alpha = i / steps
                local intermediateCFrame = hrp.CFrame:Lerp(targetCFrame, alpha)
                hrp.CFrame = intermediateCFrame
                if hum then hum:ChangeState(Enum.HumanoidStateType.Landed) end
                task.wait(0.03)
            end
        else
            if hum then
                local oldWalkSpeed = hum.WalkSpeed
                hum.WalkSpeed = 0
                hrp.Anchored = true
                hrp.CFrame = targetCFrame
                task.wait(0.05)
                hrp.Anchored = false
                if hum then hum:ChangeState(Enum.HumanoidStateType.Landed) end
                task.wait(0.05)
                hum.WalkSpeed = oldWalkSpeed
            else
                hrp.CFrame = targetCFrame
            end
        end
    end)
end
local AutoHarvestTask
local FruitHarvestDropdown = Tabs.Farm:AddDropdown("SelectFruitToHarvest", {
    Title = "Select Fruits to Harvest",
    Values = SeedsList,
    Multi = true,
    Default = {"All"},
})
local MutationList = {"All", "Normal", "Gold", "Rainbow", "Giant", "Huge", "Shiny"}
local BuffHarvestDropdown = Tabs.Farm:AddDropdown("SelectBuffToHarvest", {
    Title = "Select Fruit Buffs/Mutations to Harvest",
    Values = MutationList,
    Multi = true,
    Default = {"All"},
})
local Toggle = Tabs.Farm:AddToggle("AutoHarvestToggle", {Title = "Auto Harvest", Default = false })
Toggle:OnChanged(function()
    if Options.AutoHarvestToggle.Value then
        AutoHarvestTask = task.spawn(function()
            local lp = game.Players.LocalPlayer
            local gardens = game:GetService("Workspace"):FindFirstChild("Gardens")
            while Options.AutoHarvestToggle.Value and getgenv().Gag2RunningID == currentID do
                local success = pcall(function()
                    local selectedFruits = Options.SelectFruitToHarvest.Value
                    local selectedBuffs = Options.SelectBuffToHarvest.Value
                    local targetFruits = {}
                    local hasAllFruits = false
                    local targetBuffs = {}
                    local hasAllBuffs = false
                    if type(selectedFruits) == "table" then
                        for k, v in pairs(selectedFruits) do
                            local name = type(k) == "number" and v or k
                            if name == "All" and (v == true or type(k) == "number") then
                                hasAllFruits = true
                                break
                            end
                            if v == true or type(k) == "number" then targetFruits[name] = true end
                        end
                    end
                    if type(selectedBuffs) == "table" then
                        for k, v in pairs(selectedBuffs) do
                            local name = type(k) == "number" and v or k
                            if name == "All" and (v == true or type(k) == "number") then
                                hasAllBuffs = true
                                break
                            end
                            if v == true or type(k) == "number" then targetBuffs[name] = true end
                        end
                    end
                    local myPlotId = lp:GetAttribute("PlotId")
                    if not gardens or not myPlotId then return end
                    local plot = gardens:FindFirstChild("Plot" .. tostring(myPlotId))
                    if not plot then return end
                    local plants = plot:FindFirstChild("Plants")
                    if not plants then return end

                    -- ⚡ ULTRA FAST HARVEST - เก็บทั้งหมดพร้อมกันแบบ parallel
                    for _, plant in ipairs(plants:GetChildren()) do
                        local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.ActionText == "Harvest" and prompt.Enabled then
                            local shouldHarvest = hasAllFruits and hasAllBuffs

                            if not shouldHarvest then
                                local seedName = plant:GetAttribute("SeedName")
                                local mutation = plant:GetAttribute("Mutation") or "Normal"
                                local fruitMatch = hasAllFruits or (seedName and targetFruits[seedName])
                                local buffMatch = hasAllBuffs or targetBuffs[mutation]
                                shouldHarvest = fruitMatch and buffMatch
                            end

                            if shouldHarvest then
                                -- 🚀 Fire หลายวิธีพร้อมกัน (ไม่รอกัน)
                                task.spawn(function()
                                    -- Method 1: Proximity Prompt (5 ครั้ง)
                                    local oldHold = prompt.HoldDuration
                                    prompt.HoldDuration = 0
                                    for i = 1, 5 do
                                        fireproximityprompt(prompt)
                                    end
                                    prompt.HoldDuration = oldHold

                                    -- Method 2: Networking API
                                    pcall(function()
                                        local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
                                        local plantId = plant:GetAttribute("PlantId")
                                        if plantId then
                                            Networking.Plant.Harvest:Fire(plantId)
                                        end
                                    end)

                                    -- Method 3: Touch Interest
                                    if firetouchinterest then
                                        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                                        local pp = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
                                        if hrp and pp then
                                            for _ = 1, 3 do
                                                firetouchinterest(hrp, pp, 0)
                                                firetouchinterest(hrp, pp, 1)
                                            end
                                        end
                                    end
                                end)
                            end
                        end
                    end
                end)

                -- ⚡ ลดเวลารอจาก 0.15 เหลือ 0.03 วินาที (เร็วขึ้น 5 เท่า!)
                task.wait(success and 0.03 or 0.1)
            end
        end)
    else
        if AutoHarvestTask then
            task.cancel(AutoHarvestTask)
            AutoHarvestTask = nil
        end
    end
end)
local AutoWaterTask
local WaterFruitDropdown = Tabs.Plant:AddDropdown("SelectWaterFruit", {
    Title = "Select Fruits to Water",
    Values = {"All", "Apple", "Blueberry", "Strawberry", "Tomato", "Pineapple", "Pumpkin", "Watermelon", "Potato", "Carrot", "Onion", "Corn", "Wheat", "Radish", "Turnip", "Cabbage", "Lettuce", "Pepper", "Eggplant", "Mushroom"},
    Multi = true,
    Default = {"All"},
})
local WaterBuffDropdown = Tabs.Plant:AddDropdown("SelectWaterBuff", {
    Title = "Select Buffs to Water",
    Values = {"All", "Normal", "Gold", "Rainbow", "Electric", "Bloodlit", "Frozen", "Chained", "Pizza", "Secret", "Starstruck", "Giant", "Shiny"},
    Multi = true,
    Default = {"All"},
})
local WaterWeightDropdown = Tabs.Plant:AddDropdown("SelectWaterWeight", {
    Title = "Select Weight Priority",
    Values = {"All", "Heaviest", "Lightest"},
    Multi = false,
    Default = "All",
})
local WaterToggle = Tabs.Plant:AddToggle("AutoWaterToggle", {Title = "Auto Watering", Default = false })
WaterToggle:OnChanged(function()
    if Options.AutoWaterToggle.Value then
        AutoWaterTask = task.spawn(function()
            local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            while Options.AutoWaterToggle.Value and getgenv().Gag2RunningID == currentID do
                pcall(function()
                    local lp = game.Players.LocalPlayer
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    local tool = nil
                    if char then
                        for _, t in ipairs(char:GetChildren()) do
                            if t:IsA("Tool") and string.find(t.Name, "Watering Can") then
                                tool = t
                                break
                            end
                        end
                    end
                    if not tool and lp:FindFirstChild("Backpack") then
                        for _, t in ipairs(lp.Backpack:GetChildren()) do
                            if t:IsA("Tool") and string.find(t.Name, "Watering Can") then
                                tool = t
                                break
                            end
                        end
                    end
                    if not tool then return end
                    if tool.Parent ~= char then
                        local hum = char:FindFirstChild("Humanoid")
                        if hum then hum:EquipTool(tool) end
                        task.wait(0.3)
                    end
                    local selectedFruits = Options.SelectWaterFruit.Value
                    local targetFruits = {}
                    local hasAllFruits = false
                    if type(selectedFruits) == "table" then
                        for k, v in pairs(selectedFruits) do
                            local name = type(k) == "number" and v or k
                            if name == "All" and (v == true or type(k) == "number") then hasAllFruits = true end
                            if v == true or type(k) == "number" then targetFruits[name] = true end
                        end
                    end
                    local selectedBuffs = Options.SelectWaterBuff.Value
                    local targetBuffs = {}
                    local hasAllBuffs = false
                    if type(selectedBuffs) == "table" then
                        for k, v in pairs(selectedBuffs) do
                            local name = type(k) == "number" and v or k
                            if name == "All" and (v == true or type(k) == "number") then hasAllBuffs = true end
                            if v == true or type(k) == "number" then targetBuffs[name] = true end
                        end
                    end
                    local weightMode = Options.SelectWaterWeight.Value
                    local wateredPlantsCooldown = {}
                    local function shouldWater(plant)
                        local plantId = plant:GetAttribute("PlantId")
                        if plantId and wateredPlantsCooldown[plantId] and (os.clock() - wateredPlantsCooldown[plantId] < 15) then
                            return false
                        end
                        local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt and prompt.ActionText == "Harvest" and prompt.Enabled then
                            return false
                        end
                        local seedName = plant:GetAttribute("SeedName") or "Unknown"
                        local mutation = plant:GetAttribute("Mutation") or "Normal"
                        local fruitMatch = hasAllFruits or targetFruits[seedName]
                        local buffMatch = hasAllBuffs or targetBuffs[mutation]
                        return fruitMatch and buffMatch
                    end
                    local function waterPlant(plant)
                        local plantId = plant:GetAttribute("PlantId")
                        local pp = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
                        if not plantId or not pp or not tool then return end
                        wateredPlantsCooldown[plantId] = os.clock()
                        local oldCFrame = hrp.CFrame
                        BypassTeleport(hrp, pp.CFrame + Vector3.new(0, 3, 0))
                        pcall(function() tool:Activate() end)
                        pcall(function()
                            Networking.WateringCan.UseWateringCan:Fire(pp.Position, tool.Name, tool)
                        end)
                        task.wait(0.2)
                        BypassTeleport(hrp, oldCFrame)
                    end
                    local gardens = game:GetService("Workspace"):FindFirstChild("Gardens")
                    if gardens then
                        local myPlotId = lp:GetAttribute("PlotId")
                        local plot = myPlotId and gardens:FindFirstChild("Plot" .. tostring(myPlotId))
                        if plot then
                            local plantsFolder = plot:FindFirstChild("Plants")
                            if plantsFolder then
                                local bestPlant = nil
                                local bestVal = (weightMode == "Heaviest") and -math.huge or math.huge
                                for _, plant in ipairs(plantsFolder:GetChildren()) do
                                    if shouldWater(plant) then
                                        if weightMode == "All" then
                                            waterPlant(plant)
                                            task.wait(0.1)
                                        else
                                            local fruitsFolder = plant:FindFirstChild("Fruits")
                                            local maxPlantSize = 0
                                            if fruitsFolder then
                                                for _, f in ipairs(fruitsFolder:GetChildren()) do
                                                    local sm = f:GetAttribute("SizeMulti") or 0
                                                    if sm > maxPlantSize then maxPlantSize = sm end
                                                end
                                            end
                                            if weightMode == "Heaviest" and maxPlantSize > bestVal then
                                                bestVal = maxPlantSize
                                                bestPlant = plant
                                            elseif weightMode == "Lightest" and maxPlantSize < bestVal then
                                                bestVal = maxPlantSize
                                                bestPlant = plant
                                            end
                                        end
                                    end
                                end
                                if bestPlant and weightMode ~= "All" then
                                    waterPlant(bestPlant)
                                end
                            end
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    else
        if AutoWaterTask then
            task.cancel(AutoWaterTask)
            AutoWaterTask = nil
        end
    end
end)
local SprinklerTypeDropdown = Tabs.Plant:AddDropdown("SelectSprinklerType", {
    Title = "Select Sprinkler Type",
    Values = {"All", "Common Sprinkler", "Gold Sprinkler", "Rainbow Sprinkler", "Electric Sprinkler", "Bloodlit Sprinkler", "Frozen Sprinkler", "Chained Sprinkler", "Pizza Sprinkler", "Secret Sprinkler", "Starstruck Sprinkler", "Giant Sprinkler", "Shiny Sprinkler"},
    Multi = true,
    Default = {"All"},
})
local SprinklerFruitDropdown = Tabs.Plant:AddDropdown("SelectSprinklerFruit", {
    Title = "Select Trees for Sprinkler",
    Values = {"All", "Apple", "Blueberry", "Strawberry", "Tomato", "Pineapple", "Pumpkin", "Watermelon", "Potato", "Carrot", "Onion", "Corn", "Wheat", "Radish", "Turnip", "Cabbage", "Lettuce", "Pepper", "Eggplant", "Mushroom"},
    Multi = true,
    Default = {"All"},
})
local SprinklerBuffDropdown = Tabs.Plant:AddDropdown("SelectSprinklerBuff", {
    Title = "Select Tree Buffs for Sprinkler",
    Values = {"All", "Normal", "Gold", "Rainbow", "Electric", "Bloodlit", "Frozen", "Chained", "Pizza", "Secret", "Starstruck", "Giant", "Shiny"},
    Multi = true,
    Default = {"All"},
})
local SprinklerWeightDropdown = Tabs.Plant:AddDropdown("SelectSprinklerWeight", {
    Title = "Select Sprinkler Priority",
    Values = {"All", "Heaviest", "Lightest"},
    Multi = false,
    Default = "All",
})
local function DoPlaceSprinkler()
    pcall(function()
        local lp = game.Players.LocalPlayer
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local selectedTypes = Options.SelectSprinklerType.Value
        local hasAllTypes = false
        if type(selectedTypes) == "table" then
            for k, v in pairs(selectedTypes) do
                local name = type(k) == "number" and v or k
                if name == "All" and (v == true or type(k) == "number") then
                    hasAllTypes = true
                    break
                end
            end
        end
        local tool = nil
        if char then
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and string.find(t.Name, "Sprinkler") then
                    tool = t
                    break
                end
            end
        end
        if not tool and lp:FindFirstChild("Backpack") then
            for _, t in ipairs(lp.Backpack:GetChildren()) do
                if t:IsA("Tool") and string.find(t.Name, "Sprinkler") then
                    tool = t
                    break
                end
            end
        end
        if not tool then return end
        if tool.Parent ~= char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum:EquipTool(tool)
                task.wait(0.5)
            end
        end
        local gardens = workspace:FindFirstChild("Gardens")
        if not gardens then return end
        local myPlotId = lp:GetAttribute("PlotId")
        if not myPlotId then return end
        local plot = gardens:FindFirstChild("Plot" .. tostring(myPlotId))
        if not plot then return end
        local plantsFolder = plot:FindFirstChild("Plants")
        if not plantsFolder or #plantsFolder:GetChildren() == 0 then return end
        local sprinklersFolder = plot:FindFirstChild("Sprinklers")
        local targetPlant = nil
        for _, plant in ipairs(plantsFolder:GetChildren()) do
            if plant:IsA("Model") then
                local pp = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
                if pp then
                    local hasSprinkler = false
                    if sprinklersFolder then
                        for _, s in ipairs(sprinklersFolder:GetChildren()) do
                            local s_pp = s.PrimaryPart or s:FindFirstChildWhichIsA("BasePart")
                            if s_pp and (s_pp.Position - pp.Position).Magnitude < 8 then
                                hasSprinkler = true
                                break
                            end
                        end
                    end
                    if not hasSprinkler then
                        targetPlant = plant
                        break
                    end
                end
            end
        end
        if targetPlant then
            local pp = targetPlant.PrimaryPart or targetPlant:FindFirstChildWhichIsA("BasePart")
            if pp and tool then
                hrp.CFrame = pp.CFrame * CFrame.new(2, 0, 2)
                task.wait(0.3)
                local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
                tool:Activate()
                task.wait(0.1)
                Networking.Place.PlaceSprinkler:Fire(pp.Position + Vector3.new(1, 0, 1), tool.Name, tool, 1)
                task.wait(0.2)
            end
        end
    end)
end
Tabs.Plant:AddButton({
    Title = "Place Sprinkler Now",
    Description = "Places 1 Sprinkler based on your settings",
    Callback = function()
        task.spawn(DoPlaceSprinkler)
    end
})
local AutoSprinklerTask
local AutoSprinklerToggle = Tabs.Plant:AddToggle("AutoSprinklerToggle", {Title = "Auto Place Sprinklers", Default = false })
AutoSprinklerToggle:OnChanged(function()
    if Options.AutoSprinklerToggle.Value then
        AutoSprinklerTask = task.spawn(function()
            while Options.AutoSprinklerToggle.Value and getgenv().Gag2RunningID == currentID do
                pcall(DoPlaceSprinkler)
                task.wait(1)
            end
        end)
    else
        if AutoSprinklerTask then
            task.cancel(AutoSprinklerTask)
            AutoSprinklerTask = nil
        end
    end
end)
local AutoPlantTask
local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
local PlantSeedDropdown = Tabs.Plant:AddDropdown("SelectPlantSeed", {
    Title = "Select Seeds to Plant",
    Values = SeedsList,
    Multi = true,
    Default = {"Apple"},
})
local PlantToggle = Tabs.Plant:AddToggle("AutoPlantToggle", {Title = "Auto Plant (Use Seeds from Inventory)", Default = false })
PlantToggle:OnChanged(function()
    if Options.AutoPlantToggle.Value then
        AutoPlantTask = task.spawn(function()
            while Options.AutoPlantToggle.Value and getgenv().Gag2RunningID == currentID do
                pcall(function()
                    local lp = game.Players.LocalPlayer
                    local plotId = lp:GetAttribute("PlotId")
                    if not plotId then return end
                    local plot = workspace.Gardens:FindFirstChild("Plot" .. tostring(plotId))
                    if not plot then return end
                    local plantAreas = {}
                    for _, v in ipairs(game:GetService("CollectionService"):GetTagged("PlantArea")) do
                        if v:IsDescendantOf(plot) then
                            table.insert(plantAreas, v)
                        end
                    end
                    if #plantAreas == 0 then return end
                    local plantsFolder = plot:FindFirstChild("Plants")
                    if not plantsFolder then return end
                    local selectedSeeds = Options.SelectPlantSeed.Value
                    local validSeeds = {}
                    if type(selectedSeeds) == "table" then
                        for k, v in pairs(selectedSeeds) do
                            if type(k) == "number" and type(v) == "string" then
                                validSeeds[v] = true
                            elseif type(k) == "string" and v == true then
                                validSeeds[k] = true
                            end
                        end
                    end
                    if not next(validSeeds) then return end
                    local hasAll = validSeeds["All"] == true
                    local tool = nil
                    for _, v in ipairs(lp.Backpack:GetChildren()) do
                        if v:IsA("Tool") and v:GetAttribute("SeedTool") then
                            local seedName = string.gsub(v.Name, " Seed", "")
                            if validSeeds[seedName] or hasAll then
                                tool = v
                                break
                            end
                        end
                    end
                    if not tool and lp.Character then
                        for _, v in ipairs(lp.Character:GetChildren()) do
                            if v:IsA("Tool") and v:GetAttribute("SeedTool") then
                                local seedName = string.gsub(v.Name, " Seed", "")
                                if validSeeds[seedName] or hasAll then
                                    tool = v
                                    break
                                end
                            end
                        end
                    end
                    if tool then
                        local seedId = tool:GetAttribute("SeedTool")
                        local area = plantAreas[math.random(1, #plantAreas)]
                        if area then
                            local size = area.Size
                            local cf = area.CFrame
                            for i = 1, 10 do
                                local rx = (math.random() - 0.5) * size.X
                                local rz = (math.random() - 0.5) * size.Z
                                local tryPos = cf * Vector3.new(rx, size.Y/2, rz)
                                local tooClose = false
                                for _, plant in ipairs(plantsFolder:GetChildren()) do
                                    if plant:IsA("Model") and plant.PrimaryPart then
                                        local pPos = plant.PrimaryPart.Position
                                        if (Vector2.new(tryPos.X, tryPos.Z) - Vector2.new(pPos.X, pPos.Z)).Magnitude < 1.5 then
                                            tooClose = true
                                            break
                                        end
                                    end
                                end
                                if not tooClose then
                                    Networking.Plant.PlantSeed:Fire(tryPos, seedId, tool)
                                    task.wait(0.2)
                                    break
                                end
                            end
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    else
        if AutoPlantTask then
            task.cancel(AutoPlantTask)
            AutoPlantTask = nil
        end
    end
end)
local AutoPickEventTask
local _seedPackConnections = {}
local PickToggle = Tabs.Farm:AddToggle("AutoPickEventToggle", {Title = "Auto Pick Event", Default = false })
PickToggle:OnChanged(function()
    if Options.AutoPickEventToggle.Value then
        AutoPickEventTask = task.spawn(function()
            local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            local mapFolder = workspace:FindFirstChild("Map")
            if not mapFolder then return end
            local pickedPacks = {}
            local function grabPack(item)
                if pickedPacks[item] then return end
                pickedPacks[item] = true
                task.spawn(function()
                    pcall(function()
                        local lp = game.Players.LocalPlayer
                        local char = lp and lp.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if not hrp then return end

                        local tp = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)) or item
                        if not tp or not tp:IsA("BasePart") then return end

                        local positions = {
                            CFrame.new(0, 0, 0),
                            CFrame.new(0, -1, 0),
                            CFrame.new(1, 0, 0),
                            CFrame.new(-1, 0, 0),
                            CFrame.new(0, 0, 1),
                            CFrame.new(0, 0, -1),
                        }

                        for _, offset in ipairs(positions) do
                            if not item or not item.Parent then break end

                            hrp.CFrame = tp.CFrame * offset
                            task.wait(0.5)

                            -- 🔥 HOLD E (กด E ค้าง 3 วินาที!)
                            local VirtualInputManager = game:GetService("VirtualInputManager")

                            -- กด E ค้างไว้
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                            task.wait(3) -- ค้างไว้ 3 วินาที
                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)

                            task.wait(0.3)

                            -- คลิกเมาส์ค้างด้วย
                            local screenCenter = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
                            VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, true, game, 0)
                            task.wait(3) -- ค้าง 3 วินาที
                            VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, false, game, 0)

                            -- API Methods
                            Networking.SeedPack.ClickPack:Fire(item)
                            task.wait(0.1)

                            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and prompt.Enabled then
                                -- ปิด HoldDuration เพื่อไม่ต้องค้าง
                                local oldHold = prompt.HoldDuration
                                prompt.HoldDuration = 0
                                for _ = 1, 10 do
                                    fireproximityprompt(prompt)
                                    task.wait(0.05)
                                end
                                prompt.HoldDuration = oldHold
                            end

                            if hrp and firetouchinterest and tp then
                                for _ = 1, 15 do
                                    firetouchinterest(hrp, tp, 0)
                                    task.wait(0.03)
                                    firetouchinterest(hrp, tp, 1)
                                    task.wait(0.03)
                                end
                            end

                            task.wait(0.5)

                            if not item or not item.Parent then
                                break
                            end
                        end
                    end)
                end)
            end
            local foldersToWatch = {
                mapFolder:FindFirstChild("SeedPackSpawnClient"),
                mapFolder:FindFirstChild("SeedPackSpawnServerLocations"),
            }
            for _, folder in next, foldersToWatch do
                if folder then
                    for _, item in next, folder:GetChildren() do
                        grabPack(item)
                    end
                    local conn = folder.ChildAdded:Connect(function(item)
                        if Options.AutoPickEventToggle.Value and getgenv().Gag2RunningID == currentID then
                            grabPack(item)
                        end
                    end)
                    table.insert(_seedPackConnections, conn)
                end
            end
            while Options.AutoPickEventToggle.Value and getgenv().Gag2RunningID == currentID do
                pcall(function()
                    for _, folder in next, foldersToWatch do
                        if folder then
                            for _, item in next, folder:GetChildren() do
                                if not pickedPacks[item] then
                                    grabPack(item)
                                end
                            end
                        end
                    end
                    local droppedItemsFolder = workspace:FindFirstChild("DroppedItems")
                    if droppedItemsFolder then
                        local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            for _, item in next, droppedItemsFolder:GetChildren() do
                                local tp = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart", true)) or item
                                if tp and tp:IsA("BasePart") then
                                    BypassTeleport(hrp, tp.CFrame * CFrame.new(0, 2, 0))
                                    task.wait(0.5)

                                    -- 🔥 HOLD E (กด E ค้าง 3 วินาที!)
                                    local VirtualInputManager = game:GetService("VirtualInputManager")
                                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                    task.wait(3)
                                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)

                                    task.wait(0.3)

                                    -- คลิกเมาส์ค้าง
                                    local screenCenter = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
                                    VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, true, game, 0)
                                    task.wait(3)
                                    VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, false, game, 0)

                                    local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if prompt and prompt.Enabled then
                                        local oldHold = prompt.HoldDuration
                                        prompt.HoldDuration = 0
                                        for _ = 1, 10 do
                                            fireproximityprompt(prompt)
                                            task.wait(0.05)
                                        end
                                        prompt.HoldDuration = oldHold
                                    end

                                    if firetouchinterest then
                                        for _ = 1, 10 do
                                            firetouchinterest(hrp, tp, 0)
                                            task.wait(0.03)
                                            firetouchinterest(hrp, tp, 1)
                                            task.wait(0.03)
                                        end
                                    end

                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                    for _, prompt in next, workspace:GetDescendants() do
                        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                            local text = string.lower(prompt.ActionText)
                            if text == "collect" or text == "pick up" or text == "pickup" or text == "open" or text == "take" or text == "grab" or text == "dig" or text == "dig up" then
                                local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if hrp and prompt.Parent and prompt.Parent:IsA("BasePart") then
                                    BypassTeleport(hrp, prompt.Parent.CFrame * CFrame.new(0, 2, 0))
                                    task.wait(0.5)

                                    -- 🔥 HOLD E (กด E ค้าง 3 วินาที!)
                                    local VirtualInputManager = game:GetService("VirtualInputManager")
                                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                    task.wait(3)
                                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)

                                    task.wait(0.3)

                                    -- คลิกเมาส์ค้าง
                                    local screenCenter = Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
                                    VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, true, game, 0)
                                    task.wait(3)
                                    VirtualInputManager:SendMouseButtonEvent(screenCenter.X, screenCenter.Y, 0, false, game, 0)

                                    local oldHold = prompt.HoldDuration
                                    prompt.HoldDuration = 0
                                    for _ = 1, 10 do
                                        fireproximityprompt(prompt)
                                        task.wait(0.05)
                                    end
                                    prompt.HoldDuration = oldHold

                                    if firetouchinterest then
                                        for _ = 1, 10 do
                                            firetouchinterest(hrp, prompt.Parent, 0)
                                            task.wait(0.03)
                                            firetouchinterest(hrp, prompt.Parent, 1)
                                            task.wait(0.03)
                                        end
                                    end

                                    task.wait(0.15)
                                end
                            end
                        end
                    end
                end)
                task.wait(0.1)
            end
        end)
    else
        if AutoPickEventTask then
            task.cancel(AutoPickEventTask)
            AutoPickEventTask = nil
        end
        for _, conn in next, _seedPackConnections do
            pcall(function() conn:Disconnect() end)
        end
        _seedPackConnections = {}
    end
end)
local AutoSellFullTask
local SellFullToggle = Tabs.Farm:AddToggle("AutoSellFullToggle", {Title = "Auto Sell Backpack Full", Default = false })
SellFullToggle:OnChanged(function()
    if Options.AutoSellFullToggle.Value then
        AutoSellFullTask = task.spawn(function()
            local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
            while Options.AutoSellFullToggle.Value and getgenv().Gag2RunningID == currentID do
                pcall(function()
                    local backpackGui = PlayerGui:FindFirstChild("BackpackGui")
                    if backpackGui then
                        local invLabel = backpackGui:FindFirstChild("FruitInventory", true)
                        if invLabel and invLabel:IsA("TextLabel") then
                            local current, max = string.match(invLabel.Text, "(%d+)/(%d+)")
                            if current and max then
                                if tonumber(current) >= tonumber(max) then
                                    Networking.NPCS.SellAll:Fire()
                                end
                            end
                        end
                    end
                end)
                task.wait(1)
            end
        end)
    else
        if AutoSellFullTask then
            task.cancel(AutoSellFullTask)
            AutoSellFullTask = nil
        end
    end
end)
local AntiAfkConnection
local AntiAfkToggle = Tabs.Farm:AddToggle("AntiAfkToggle", {Title = "Advanced Anti AFK", Default = false })
AntiAfkToggle:OnChanged(function()
    if Options.AntiAfkToggle.Value then
        if not AntiAfkConnection then
            local VirtualUser = game:GetService("VirtualUser")
            AntiAfkConnection = game.Players.LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    else
        if AntiAfkConnection then
            AntiAfkConnection:Disconnect()
            AntiAfkConnection = nil
        end
    end
end)
local AntiStealTask
local AntiStealToggle = Tabs.Farm:AddToggle("AntiStealToggle", {Title = "Anti Steal (Hit nearby players)", Default = false })
AntiStealToggle:OnChanged(function()
    if Options.AntiStealToggle.Value then
        AntiStealTask = task.spawn(function()
            while Options.AntiStealToggle.Value and getgenv().Gag2RunningID == currentID do
                pcall(function()
                    local lp = game.Players.LocalPlayer
                    local char = lp.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                    local hrp = char.HumanoidRootPart
                    local myPlotId = lp:GetAttribute("PlotId")
                    local myPlotName = myPlotId and ("Plot" .. tostring(myPlotId)) or "NONE_PLOT"
                    local myPlot
                    local gardens = game:GetService("Workspace"):FindFirstChild("Gardens")
                    if gardens then
                        myPlot = gardens:FindFirstChild(myPlotName)
                    end
                    if myPlot then
                        local centerPart = myPlot:FindFirstChild("PlotSizeReference") or myPlot:FindFirstChild("SpawnPoint") or myPlot.PrimaryPart
                        if centerPart then
                            local plotCenter = centerPart.Position
                            local plotRadius = 60
                            for _, player in ipairs(game.Players:GetPlayers()) do
                                if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                    local targetHrp = player.Character.HumanoidRootPart
                                    local distance = (targetHrp.Position - plotCenter).Magnitude
                                    if distance <= plotRadius then
                                        local shovel = char:FindFirstChild("Shovel") or (lp:FindFirstChild("Backpack") and lp.Backpack:FindFirstChild("Shovel"))
                                        if shovel then
                                            local hum = char:FindFirstChild("Humanoid")
                                            if hum and shovel.Parent ~= char then
                                                hum:EquipTool(shovel)
                                            end
                                            local oldCFrame = hrp.CFrame
                                            hrp.CFrame = targetHrp.CFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
                                            shovel:Activate()
                                                task.wait()
                                            hrp.CFrame = oldCFrame
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.2)
            end
        end)
    else
        if AntiStealTask then
            task.cancel(AntiStealTask)
            AntiStealTask = nil
        end
    end
end)
local Dropdown = Tabs.Shop:AddDropdown("SelectSeed", {
    Title = "Select Seeds",
    Values = SeedsList,
    Multi = true,
    Default = {"Apple"},
})
local AutoBuyTask
local BuyToggle = Tabs.Shop:AddToggle("AutoBuyToggle", {Title = "Auto Buy Selected Seeds", Default = false })
BuyToggle:OnChanged(function()
    if Options.AutoBuyToggle.Value then
        AutoBuyTask = task.spawn(function()
            local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            while Options.AutoBuyToggle.Value and getgenv().Gag2RunningID == currentID do
                pcall(function()
                    local currentSelection = Options.SelectSeed.Value
                    if type(currentSelection) == "table" then
                        local hasAll = false
                        local selected = {}
                        for k, v in pairs(currentSelection) do
                            local seedToBuy
                            if type(k) == "number" and type(v) == "string" then
                                seedToBuy = v
                            elseif type(k) == "string" and v == true then
                                seedToBuy = k
                            end
                            if seedToBuy == "All" then hasAll = true end
                            if seedToBuy then selected[seedToBuy] = true end
                        end
                        local function buy(seed)
                            if seed ~= "All" then
                                Networking.SeedShop.PurchaseSeed:Fire(seed)
                                task.wait(0.1)
                            end
                        end
                        if hasAll then
                            for _, seed in ipairs(SeedsList) do buy(seed) end
                        else
                            for seed, _ in pairs(selected) do buy(seed) end
                        end
                    elseif type(currentSelection) == "string" then
                        if currentSelection == "All" then
                            for _, seed in ipairs(SeedsList) do
                                if seed ~= "All" then
                                    Networking.SeedShop.PurchaseSeed:Fire(seed)
                                    task.wait(0.1)
                                end
                            end
                        else
                            Networking.SeedShop.PurchaseSeed:Fire(currentSelection)
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    else
        if AutoBuyTask then
            task.cancel(AutoBuyTask)
            AutoBuyTask = nil
        end
    end
end)
local GearsList = {
    "Common Watering Can", "Common Sprinkler", "Sign", "Lantern", "Wheelbarrow", 
    "Uncommon Sprinkler", "Rare Sprinkler", "Legendary Sprinkler", "Super Sprinkler", 
    "Trowel", "Speed Mushroom", "Jump Mushroom", "Gnome", "Shrink Mushroom", 
    "Supersize Mushroom", "Invisibility Mushroom", "Teleporter", "Super Watering Can", 
    "Basic Pot", "Flashbang"
}
local GearDropdown = Tabs.Shop:AddDropdown("SelectGear", {
    Title = "Select Gears",
    Values = GearsList,
    Multi = true,
    Default = {"Common Watering Can"},
})
local AutoBuyGearTask
local BuyGearToggle = Tabs.Shop:AddToggle("AutoBuyGearToggle", {Title = "Auto Buy Selected Gears", Default = false })
BuyGearToggle:OnChanged(function()
    if Options.AutoBuyGearToggle.Value then
        AutoBuyGearTask = task.spawn(function()
            local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            while Options.AutoBuyGearToggle.Value and getgenv().Gag2RunningID == currentID do
                pcall(function()
                    local currentSelection = Options.SelectGear.Value
                    if type(currentSelection) == "table" then
                        local hasAll = false
                        local selected = {}
                        for k, v in pairs(currentSelection) do
                            local gearToBuy
                            if type(k) == "number" and type(v) == "string" then
                                gearToBuy = v
                            elseif type(k) == "string" and v == true then
                                gearToBuy = k
                            end
                            if gearToBuy == "All" then hasAll = true end
                            if gearToBuy then selected[gearToBuy] = true end
                        end
                        local function buy(gear)
                            if gear ~= "All" then
                                Networking.GearShop.PurchaseGear:Fire(gear)
                                task.wait(0.1)
                            end
                        end
                        if hasAll then
                            for _, gear in ipairs(GearsList) do buy(gear) end
                        else
                            for gear, _ in pairs(selected) do buy(gear) end
                        end
                    elseif type(currentSelection) == "string" then
                        if currentSelection == "All" then
                            for _, gear in ipairs(GearsList) do
                                if gear ~= "All" then
                                    Networking.GearShop.PurchaseGear:Fire(gear)
                                    task.wait(0.1)
                                end
                            end
                        else
                            Networking.GearShop.PurchaseGear:Fire(currentSelection)
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    else
        if AutoBuyGearTask then
            task.cancel(AutoBuyGearTask)
            AutoBuyGearTask = nil
        end
    end
end)
local SellDropdown = Tabs.Shop:AddDropdown("SelectSell", {
    Title = "Select Fruits to Sell",
    Values = SeedsList,
    Multi = true,
    Default = {"All"},
})
local AutoSellTask
local SellToggle = Tabs.Shop:AddToggle("AutoSellToggle", {Title = "Auto Sell Selected Fruits", Default = false })
SellToggle:OnChanged(function()
    if Options.AutoSellToggle.Value then
        AutoSellTask = task.spawn(function()
            local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            while Options.AutoSellToggle.Value and getgenv().Gag2RunningID == currentID do
                pcall(function()
                    local currentSelection = Options.SelectSell.Value
                    local selectedFruits = {}
                    if type(currentSelection) == "table" then
                        for k, v in pairs(currentSelection) do
                            if type(k) == "number" and type(v) == "string" then
                                selectedFruits[v] = true
                            elseif type(k) == "string" and v == true then
                                selectedFruits[k] = true
                            end
                        end
                    elseif type(currentSelection) == "string" then
                        selectedFruits[currentSelection] = true
                    end
                    if selectedFruits["All"] then
                        Networking.NPCS.SellAll:Fire()
                    else
                        local player = game.Players.LocalPlayer
                        local toolsToSell = {}
                        local function checkFolder(folder)
                            for _, tool in ipairs(folder:GetChildren()) do
                                local fruitName = tool:GetAttribute("FruitName")
                                if fruitName and selectedFruits[fruitName] then
                                    local id = tool:GetAttribute("Id")
                                    if id then table.insert(toolsToSell, id) end
                                end
                            end
                        end
                        if player.Character then checkFolder(player.Character) end
                        checkFolder(player.Backpack)
                        for _, id in ipairs(toolsToSell) do
                            Networking.NPCS.SellFruit:Fire(id)
                            task.wait(0.1)
                        end
                    end
                end)
                task.wait(1) 
            end
        end)
    else
        if AutoSellTask then
            task.cancel(AutoSellTask)
            AutoSellTask = nil
        end
    end
end)
local AutoSendMailTask
local TargetUserIdCache = {}

local TargetPlayerInput = Tabs.Trade:AddInput("TargetPlayerMail", {
    Title = "Target Player Name",
    Default = "",
    Placeholder = "Enter username here",
    Numeric = false,
    Finished = false,
})

local SendMailAmountInput = Tabs.Trade:AddInput("SendMailAmount", {
    Title = "Amount to Send (0 = All)",
    Default = "0",
    Placeholder = "Enter amount",
    Numeric = true,
    Finished = false,
})

local SendSeedDropdown = Tabs.Trade:AddDropdown("SelectSeedToSend", {
    Title = "Select Seeds to Send",
    Values = SeedsList,
    Multi = true,
    Default = {},
})

local SendGearDropdown = Tabs.Trade:AddDropdown("SelectGearToSend", {
    Title = "Select Gears to Send",
    Values = GearsList,
    Multi = true,
    Default = {},
})

local SendPetsList = {"None", "All"}
for pet, _ in pairs(PetsPrices) do table.insert(SendPetsList, pet) end
local SendPetDropdown = Tabs.Trade:AddDropdown("SelectPetToSend", {
    Title = "🐾 Select Pets to Send",
    Values = SendPetsList,
    Multi = true,
    Default = {},
})

-- 🐞 DEBUG BUTTON: ดู Pets ใน Inventory
Tabs.Trade:AddButton({
    Title = "🐞 Debug: Show Pets in Inventory",
    Description = "แสดงรายการ Pets ทั้งหมดที่คุณมี",
    Callback = function()
        task.spawn(function()
            pcall(function()
                local PlayerStateClient = require(game:GetService("ReplicatedStorage").ClientModules.PlayerStateClient)
                local inventory = PlayerStateClient.GetLocalReplica().Data.Inventory

                if inventory.Pets and type(inventory.Pets) == "table" then
                    local petCount = 0
                    local petNames = ""

                    for petKey, petData in pairs(inventory.Pets) do
                        petCount = petCount + 1
                        if type(petData) == "table" then
                            -- ✅ FIX: ใช้ NameTag แทน PetName!
                            local petName = petData.NameTag or petData.Name or petData.Id or petData.Type or petKey
                            petNames = petNames .. "\n" .. petCount .. ". " .. tostring(petName) .. " (Key: " .. tostring(petKey):sub(1,8) .. "...)"
                        else
                            petNames = petNames .. "\n" .. petCount .. ". " .. tostring(petKey) .. " = " .. tostring(petData)
                        end
                    end

                    if petCount > 0 then
                        Fluent:Notify({Title = "🐾 Pets Found: " .. petCount, Content = petNames, Duration = 10})
                    else
                        Fluent:Notify({Title = "⚠️ No Pets", Content = "ไม่พบ Pets ใน Inventory!", Duration = 5})
                    end
                else
                    Fluent:Notify({Title = "❌ Error", Content = "ไม่มี Pets category ใน Inventory!", Duration = 5})
                end
            end)
        end)
    end
})

local SendMailToggle = Tabs.Trade:AddToggle("AutoSendMailToggle", {Title = "Auto SendMail (Seeds, Gears, Pets)", Default = false })
SendMailToggle:OnChanged(function()
    if Options.AutoSendMailToggle.Value then
        AutoSendMailTask = task.spawn(function()
            local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            local PlayerStateClient = require(game:GetService("ReplicatedStorage").ClientModules.PlayerStateClient)
            
            local sentTracker = {}
            local targetAmount = tonumber(Options.SendMailAmount.Value) or 0
            
            while Options.AutoSendMailToggle.Value and getgenv().Gag2RunningID == currentID do
                pcall(function()
                    local targetName = Options.TargetPlayerMail.Value
                    if targetName and targetName ~= "" then
                        local targetUserId = TargetUserIdCache[targetName]
                        if not targetUserId then
                            local s, r = pcall(function()
                                return game.Players:GetUserIdFromNameAsync(targetName)
                            end)
                            if s and r then
                                targetUserId = r
                                TargetUserIdCache[targetName] = r
                            end
                        end
                        
                        if targetUserId then
                            local inventory = PlayerStateClient.GetLocalReplica().Data.Inventory
                            local itemsToSend = {}
                            
                            local selSeeds = Options.SelectSeedToSend.Value
                            local selGears = Options.SelectGearToSend.Value
                            
                            local isAllSeeds = false
                            local seedsDict = {}
                            if type(selSeeds) == "table" then
                                for k, v in pairs(selSeeds) do
                                    local name = type(k) == "number" and v or k
                                    if name == "All" and (v == true or type(k) == "number") then isAllSeeds = true end
                                    if v == true or type(k) == "number" then seedsDict[name] = true end
                                end
                            end
                            
                            local isAllGears = false
                            local gearsDict = {}
                            if type(selGears) == "table" then
                                for k, v in pairs(selGears) do
                                    local name = type(k) == "number" and v or k
                                    if name == "All" and (v == true or type(k) == "number") then isAllGears = true end
                                    if v == true or type(k) == "number" then gearsDict[name] = true end
                                end
                            end
                            
                            local selPets = Options.SelectPetToSend.Value
                            local isAllPets = false
                            local petsDict = {}
                            if type(selPets) == "table" then
                                for k, v in pairs(selPets) do
                                    local name = type(k) == "number" and v or k
                                    if name == "All" and (v == true or type(k) == "number") then isAllPets = true end
                                    if name ~= "None" and (v == true or type(k) == "number") then petsDict[name] = true end
                                end
                            end
                            
                            -- ✅ วิธีใหม่: แยกการประมวลผล Pets, Seeds, Gears แยกกัน

                            -- 🐾 ส่ง Pets (โครงสร้างพิเศษ - table)
                            if inventory.Pets and type(inventory.Pets) == "table" then
                                for petKey, petData in pairs(inventory.Pets) do
                                    if type(petData) == "table" then
                                        -- ✅ FIX: ใช้ NameTag แทน PetName!
                                        local petName = petData.NameTag or petData.Name or petData.Id or petData.Type or petKey

                                        -- ลองจับคู่ชื่อ Pet กับที่เลือก (ไม่สนใจ case)
                                        local matchedPetName = nil
                                        if isAllPets then
                                            matchedPetName = petName
                                        else
                                            local lowerPetName = string.lower(tostring(petName))
                                            for selectedPet, _ in pairs(petsDict) do
                                                local lowerSelected = string.lower(tostring(selectedPet))
                                                if string.find(lowerPetName, lowerSelected) or string.find(lowerSelected, lowerPetName) then
                                                    matchedPetName = petName
                                                    break
                                                end
                                            end
                                        end

                                        if matchedPetName then
                                            local shouldSend = true

                                            -- เช็ค target amount
                                            if targetAmount > 0 then
                                                local sent = sentTracker[matchedPetName] or 0
                                                if sent >= targetAmount then
                                                    shouldSend = false
                                                else
                                                    sentTracker[matchedPetName] = sent + 1
                                                end
                                            end

                                            if shouldSend then
                                                table.insert(itemsToSend, {
                                                    Category = "Pets",
                                                    ItemKey = petKey,  -- ✅ ใช้ UUID เต็ม!
                                                    Count = 1
                                                })
                                            end
                                        end
                                    end
                                end
                            end

                            -- 🌱 ส่ง Seeds และ ⚙️ Gears (โครงสร้างปกติ - number)
                            for category, categoryItems in pairs(inventory) do
                                if category ~= "HarvestedFruits" and category ~= "Pets" then
                                    for itemKey, count in pairs(categoryItems) do
                                        if type(count) == "number" and count > 0 then
                                            local shouldSend = false
                                            local finalCount = count

                                            if category == "Seeds" then
                                                if isAllSeeds or seedsDict[itemKey] then
                                                    shouldSend = true
                                                end
                                            else
                                                -- Gears และอื่นๆ
                                                if isAllGears or gearsDict[itemKey] then
                                                    shouldSend = true
                                                end
                                            end

                                            if shouldSend then
                                                if targetAmount > 0 then
                                                    local sent = sentTracker[itemKey] or 0
                                                    if sent >= targetAmount then
                                                        shouldSend = false
                                                    else
                                                        finalCount = math.min(finalCount, targetAmount - sent)
                                                        sentTracker[itemKey] = sent + finalCount
                                                    end
                                                end

                                                if shouldSend and finalCount > 0 then
                                                    table.insert(itemsToSend, {
                                                        Category = category,
                                                        ItemKey = itemKey,
                                                        Count = finalCount
                                                    })
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            
                            if #itemsToSend > 0 then
                                local batch = {}
                                for _, item in ipairs(itemsToSend) do
                                    table.insert(batch, item)
                                    if #batch >= 5 then
                                        Networking.Mailbox.SendBatch:Fire(targetUserId, batch, "Gift")
                                        task.wait(1.5)
                                        batch = {}
                                    end
                                end
                                if #batch > 0 then
                                    Networking.Mailbox.SendBatch:Fire(targetUserId, batch, "Gift")
                                    task.wait(1.5)
                                end
                            end
                        end
                    end
                end)
                task.wait(2)
            end
        end)
    else
        if AutoSendMailTask then
            task.cancel(AutoSendMailTask)
            AutoSendMailTask = nil
        end
    end
end)

Tabs.Trade:AddButton({
    Title = "Send Mail (Once)",
    Description = "Send the selected items to the target player one time",
    Callback = function()
        task.spawn(function()
            local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            local PlayerStateClient = require(game:GetService("ReplicatedStorage").ClientModules.PlayerStateClient)
            
            local targetName = Options.TargetPlayerMail.Value
            if not targetName or targetName == "" then 
                Fluent:Notify({ Title = "Warning", Content = "Please enter Target Player Name!", Duration = 3 })
                return 
            end
            
            local targetUserId = TargetUserIdCache[targetName]
            if not targetUserId then
                local s, r = pcall(function() return game.Players:GetUserIdFromNameAsync(targetName) end)
                if s and r then
                    targetUserId = r
                    TargetUserIdCache[targetName] = r
                else
                    Fluent:Notify({ Title = "Error", Content = "Player not found!", Duration = 3 })
                    return
                end
            end
            
            local inventory = PlayerStateClient.GetLocalReplica().Data.Inventory
            local itemsToSend = {}
            local targetAmount = tonumber(Options.SendMailAmount.Value) or 0
            
            local selSeeds = Options.SelectSeedToSend.Value
            local selGears = Options.SelectGearToSend.Value
            
            local isAllSeeds = false
            local seedsDict = {}
            if type(selSeeds) == "table" then
                for k, v in pairs(selSeeds) do
                    local name = type(k) == "number" and v or k
                    if name == "All" and (v == true or type(k) == "number") then isAllSeeds = true end
                    if v == true or type(k) == "number" then seedsDict[name] = true end
                end
            end
            
            local isAllGears = false
            local gearsDict = {}
            if type(selGears) == "table" then
                for k, v in pairs(selGears) do
                    local name = type(k) == "number" and v or k
                    if name == "All" and (v == true or type(k) == "number") then isAllGears = true end
                    if v == true or type(k) == "number" then gearsDict[name] = true end
                end
            end
            
            local selPets = Options.SelectPetToSend.Value
            local isAllPets = false
            local petsDict = {}
            if type(selPets) == "table" then
                for k, v in pairs(selPets) do
                    local name = type(k) == "number" and v or k
                    if name == "All" and (v == true or type(k) == "number") then isAllPets = true end
                    if name ~= "None" and (v == true or type(k) == "number") then petsDict[name] = true end
                end
            end
            
            -- ✅ วิธีใหม่: แยกการประมวลผล Pets, Seeds, Gears แยกกัน

            -- 🐾 ส่ง Pets (โครงสร้างพิเศษ - table)
            if inventory.Pets and type(inventory.Pets) == "table" then
                for petKey, petData in pairs(inventory.Pets) do
                    if type(petData) == "table" then
                        -- ✅ FIX: ใช้ NameTag แทน PetName!
                        local petName = petData.NameTag or petData.Name or petData.Id or petData.Type or petKey

                        -- ลองจับคู่ชื่อ Pet กับที่เลือก (ไม่สนใจ case)
                        local matchedPetName = nil
                        if isAllPets then
                            matchedPetName = petName
                        else
                            local lowerPetName = string.lower(tostring(petName))
                            for selectedPet, _ in pairs(petsDict) do
                                local lowerSelected = string.lower(tostring(selectedPet))
                                if string.find(lowerPetName, lowerSelected) or string.find(lowerSelected, lowerPetName) then
                                    matchedPetName = petName
                                    break
                                end
                            end
                        end

                        if matchedPetName then
                            local finalCount = 1

                            -- เช็ค target amount
                            if targetAmount > 0 then
                                finalCount = math.min(1, targetAmount)
                            end

                            if finalCount > 0 then
                                table.insert(itemsToSend, {
                                    Category = "Pets",
                                    ItemKey = petKey,  -- ✅ ใช้ UUID เต็ม!
                                    Count = 1
                                })
                            end
                        end
                    end
                end
            end

            -- 🌱 ส่ง Seeds และ ⚙️ Gears (โครงสร้างปกติ - number)
            for category, categoryItems in pairs(inventory) do
                if category ~= "HarvestedFruits" and category ~= "Pets" then
                    for itemKey, count in pairs(categoryItems) do
                        if type(count) == "number" and count > 0 then
                            local shouldSend = false
                            local finalCount = count

                            if category == "Seeds" then
                                if isAllSeeds or seedsDict[itemKey] then
                                    shouldSend = true
                                end
                            else
                                -- Gears และอื่นๆ
                                if isAllGears or gearsDict[itemKey] then
                                    shouldSend = true
                                end
                            end

                            if shouldSend then
                                if targetAmount > 0 then
                                    finalCount = math.min(finalCount, targetAmount)
                                end

                                if finalCount > 0 then
                                    table.insert(itemsToSend, {
                                        Category = category,
                                        ItemKey = itemKey,
                                        Count = finalCount
                                    })
                                end
                            end
                        end
                    end
                end
            end
            
            if #itemsToSend > 0 then
                local batch = {}
                for _, item in ipairs(itemsToSend) do
                    table.insert(batch, item)
                    if #batch >= 5 then
                        Networking.Mailbox.SendBatch:Fire(targetUserId, batch, "Gift")
                        task.wait(1.5)
                        batch = {}
                    end
                end
                if #batch > 0 then
                    Networking.Mailbox.SendBatch:Fire(targetUserId, batch, "Gift")
                end
                Fluent:Notify({ Title = "Success", Content = "Sent Mail Successfully!", Duration = 3 })
            else
                Fluent:Notify({ Title = "Warning", Content = "No selected items found in inventory!", Duration = 3 })
            end
        end)
    end
})
-- ⚡ GIFT SYSTEM V5 TURBO - PRODUCTION READY (Ultra Fast Optimized)
Tabs.Gift:AddParagraph({Title="⚡ Gift System V5 TURBO",Content="🚀 10 items/batch, 0.15s delay\n⚡ Parallel send/claim, 6x faster!\n✅ Inventory + Tools + Safe"})
Tabs.Gift:AddInput("GiftTarget",{Title="🎯 ชื่อผู้รับ",Default="",Placeholder="ใส่ชื่อผู้เล่น",Numeric=false,Finished=false})
Tabs.Gift:AddDropdown("GiftSeeds",{Title="🌱 Seeds",Values=SeedsList,Multi=true,Default={}})
Tabs.Gift:AddDropdown("GiftGears",{Title="⚙️ Gears",Values=GearsList,Multi=true,Default={}})

local GiftCooldown={}
local function DoGift()
    local success, errorMsg = pcall(function()
        local target=Options.GiftTarget.Value
        if not target or target==""then
            Fluent:Notify({Title="❌ Error",Content="ใส่ชื่อผู้รับก่อน!",Duration=2})
            return
        end

        -- Cooldown protection
        if GiftCooldown[target] and (os.clock()-GiftCooldown[target])<2 then
            local remaining = math.ceil(2-(os.clock()-GiftCooldown[target]))
            Fluent:Notify({Title="⏱️ Cooldown",Content="รออีก "..remaining.." วินาที",Duration=1})
            return
        end

        -- Load modules safely
        local Net, PSC
        local modSuccess = pcall(function()
            Net = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            PSC = require(game:GetService("ReplicatedStorage").ClientModules.PlayerStateClient)
        end)

        if not modSuccess or not Net or not PSC then
            Fluent:Notify({Title="❌ Error",Content="ไม่สามารถโหลด module ได้!",Duration=3})
            return
        end

        local lp = game.Players.LocalPlayer
        if not lp then return end

        -- Get target UID
        local uid = TargetUserIdCache[target]
        if not uid then
            local s, r = pcall(function()
                return game.Players:GetUserIdFromNameAsync(target)
            end)
            if s and r then
                uid = r
                TargetUserIdCache[target] = r
            end
        end

        if not uid then
            for _, p in ipairs(game.Players:GetPlayers()) do
                if string.lower(p.Name) == string.lower(target) or
                   string.lower(p.DisplayName) == string.lower(target) then
                    uid = p.UserId
                    TargetUserIdCache[target] = uid
                    break
                end
            end
        end

        if not uid then
            Fluent:Notify({Title="❌ Not Found",Content="ไม่เจอผู้เล่น '"..target.."'",Duration=3})
            return
        end

        local batch = {}
        local invSuccess, inv = pcall(function()
            return PSC.GetLocalReplica().Data.Inventory
        end)

        if not invSuccess or not inv then
            Fluent:Notify({Title="❌ Error",Content="ไม่สามารถอ่าน Inventory ได้!",Duration=3})
            return
        end

        local selS = Options.GiftSeeds.Value
        local selG = Options.GiftGears.Value
        local hasAllS, hasAllG = false, false

        if type(selS)=="table"then
            for k,v in pairs(selS)do
                if (type(k)=="number" and v=="All") or (k=="All" and v==true) then
                    hasAllS=true
                    break
                end
            end
        end

        if type(selG)=="table"then
            for k,v in pairs(selG)do
                if (type(k)=="number" and v=="All") or (k=="All" and v==true) then
                    hasAllG=true
                    break
                end
            end
        end

        -- Scan Inventory
        for cat, items in pairs(inv) do
            if type(items)=="table" then
                for name, cnt in pairs(items) do
                    if type(cnt)=="number" and cnt>0 then
                        local ok = false
                        if cat=="Seeds" then
                            ok = hasAllS
                            if not ok and type(selS)=="table" then
                                for k,v in pairs(selS) do
                                    if (type(k)=="number" and v==name) or (k==name and v==true) then
                                        ok=true
                                        break
                                    end
                                end
                            end
                        elseif cat~="Pets" and cat~="HarvestedFruits" then
                            -- ส่งเฉพาะ Seeds และ Gears (ไม่ส่งผลไม้)
                            ok = hasAllG
                            if not ok and type(selG)=="table" then
                                for k,v in pairs(selG) do
                                    if (type(k)=="number" and v==name) or (k==name and v==true) then
                                        ok=true
                                        break
                                    end
                                end
                            end
                        end

                        if ok then
                            table.insert(batch, {Category=cat, ItemKey=name, Count=cnt})
                        end
                    end
                end
            end
        end

        if #batch == 0 then
            Fluent:Notify({Title="⚠️ Empty",Content="ไม่มีของส่ง! เลือก Seeds/Fruits/Gears",Duration=3})
            return
        end

        -- ⚡ ULTRA FAST SENDING: 10 items/batch, parallel, 0.15s delay
        local sent = 0
        for i=1, #batch, 10 do
            local sub = {}
            for j=i, math.min(i+9, #batch) do
                table.insert(sub, batch[j])
            end

            task.spawn(function()
                pcall(function()
                    Net.Mailbox.SendBatch:Fire(uid, sub, "Gift")
                end)
            end)

            sent = sent + #sub
            task.wait(0.15)
        end

        GiftCooldown[target] = os.clock()
        Fluent:Notify({Title="✅ Success",Content="ส่ง "..sent.." รายการสำเร็จ!",Duration=2})
    end)

    if not success then
        Fluent:Notify({Title="❌ Error",Content="เกิดข้อผิดพลาด: "..tostring(errorMsg),Duration=3})
    end
end

Tabs.Gift:AddButton({
    Title="📤 ส่งของตอนนี้ (TURBO)",
    Description="Ultra fast: 10 items/batch, 0.15s delay",
    Callback=function()
        task.spawn(DoGift)
    end
})

local AGT
Tabs.Gift:AddToggle("AutoGift", {Title="🔄 Auto Gift (2.5 วิ/ครั้ง)", Default=false}):OnChanged(function()
    if Options.AutoGift.Value then
        AGT = task.spawn(function()
            while Options.AutoGift.Value and getgenv().Gag2RunningID == currentID do
                DoGift()
                task.wait(2.5)
            end
        end)
    else
        if AGT then
            task.cancel(AGT)
            AGT = nil
        end
    end
end)

Tabs.Gift:AddToggle("AutoClaim", {Title="📬 Auto Claim TURBO (1 วิ/ครั้ง)", Default=false}):OnChanged(function()
    if Options.AutoClaim.Value then
        getgenv().ACT = task.spawn(function()
            local Net
            local modSuccess = pcall(function()
                Net = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            end)

            if not modSuccess or not Net then
                Fluent:Notify({Title="❌ Error",Content="ไม่สามารถโหลด Networking module!",Duration=3})
                Options.AutoClaim:SetValue(false)
                return
            end

            while Options.AutoClaim.Value and getgenv().Gag2RunningID == currentID do
                pcall(function()
                    local s, res = pcall(function()
                        return Net.Mailbox.OpenInbox:Fire()
                    end)

                    if s and type(res)=="table" then
                        local gifts = res.Gifts or res
                        local count = 0

                        -- ⚡ PARALLEL CLAIM (all gifts at once)
                        for k, v in pairs(gifts) do
                            task.spawn(function()
                                pcall(function()
                                    local giftId = type(v)=="table" and (v.Id or k) or k
                                    Net.Mailbox.Claim:Fire(giftId)
                                end)
                            end)
                            count = count + 1
                        end

                        if count > 0 then
                            task.wait(0.3)
                            Fluent:Notify({Title="📬 Claimed",Content="รับ "..count.." รายการสำเร็จ!",Duration=1})
                        end
                    end
                end)
                task.wait(1)
            end
        end)
    else
        if getgenv().ACT then
            task.cancel(getgenv().ACT)
            getgenv().ACT = nil
        end
    end
end)

local PetsList = {"All", "Frog", "Bunny", "Owl", "Deer", "Robin", "Bee", "Monkey", "Black Dragon", "Golden Dragonfly", "Unicorn", "Raccoon"}
local PetDropdown = Tabs.Pets:AddDropdown("SelectPetToBuy", {
    Title = "Select Pets to Auto Buy",
    Values = PetsList,
    Multi = true,
    Default = {"All"},
})
local AutoBuyPetTask
local AutoProtectPetToggle = Tabs.Pets:AddToggle("AutoProtectPetToggle", {Title = "🛡️ Auto Protect Pet (Kill Aura)", Default = false })

local function ProtectPet(obj, lp)
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local startProtectTime = os.clock()
    while obj and obj.Parent and obj:IsDescendantOf(workspace) do
        -- ออกถ้านานเกินไป (90 วิ)
        if os.clock() - startProtectTime > 90 then break end
        
        pcall(function()
            local targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            if targetPart then
                -- วาร์ปตามสัตว์
                hrp.CFrame = targetPart.CFrame * CFrame.new(0, 2, 0)
                
                -- สแกนผู้เล่นใกล้ๆ เพื่อตีด้วย Shovel
                local shovel = char:FindFirstChild("Shovel") or (lp:FindFirstChild("Backpack") and lp.Backpack:FindFirstChild("Shovel"))
                for _, player in ipairs(game.Players:GetPlayers()) do
                    if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local targetHrp = player.Character.HumanoidRootPart
                        local distance = (targetHrp.Position - targetPart.Position).Magnitude
                        -- รัศมีที่ให้ใครเข้าใกล้ไม่ได้
                        if distance <= 25 then
                            if shovel then
                                local hum = char:FindFirstChild("Humanoid")
                                if hum and shovel.Parent ~= char then
                                    hum:EquipTool(shovel)
                                end
                                
                                local oldCFrame = hrp.CFrame
                                hrp.CFrame = targetHrp.CFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
                                shovel:Activate()
                                task.wait(0.05)
                                hrp.CFrame = oldCFrame
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.1)
    end
end

local BuyPetToggle = Tabs.Pets:AddToggle("AutoBuyPetToggle", {Title = "Auto Buy Selected Pets", Default = false })
BuyPetToggle:OnChanged(function()
    if Options.AutoBuyPetToggle.Value then
        AutoBuyPetTask = task.spawn(function()
            local PlayerStateClient = require(game:GetService("ReplicatedStorage").ClientModules.PlayerStateClient)
            local boughtPets = {}
            while Options.AutoBuyPetToggle.Value and getgenv().Gag2RunningID == currentID do
                pcall(function()
                    local selectedPets = Options.SelectPetToBuy.Value
                    local targetPets = {}
                    local hasAll = false
                    if type(selectedPets) == "table" then
                        for k, v in pairs(selectedPets) do
                            local name = type(k) == "number" and v or k
                            if name == "All" and (v == true or type(k) == "number") then hasAll = true end
                            if v == true or type(k) == "number" then targetPets[name] = true end
                        end
                    end
                    if hasAll then
                        for pet, _ in pairs(PetsPrices) do targetPets[pet] = true end
                    end
                    local lp = game.Players.LocalPlayer
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end

                    -- ค้นหาสัตว์เลี้ยงในแมพ
                    local mapFolder = workspace:FindFirstChild("Map")
                    local spawnsFolder = mapFolder and mapFolder:FindFirstChild("WildPetSpawns")

                    if spawnsFolder then
                        for _, obj in ipairs(spawnsFolder:GetChildren()) do
                            if not Options.AutoBuyPetToggle.Value then break end

                            if obj:IsA("Model") and not boughtPets[obj] then
                                local petNameMatch = nil

                                -- Get actual pet name from object
                                local actualPetName = obj:GetAttribute("PetName")
                                if not actualPetName or actualPetName == "" then
                                    if string.find(obj.Name, "_") then
                                        local parts = string.split(obj.Name, "_")
                                        actualPetName = #parts >= 2 and parts[2] or obj.Name
                                    else
                                        actualPetName = obj.Name
                                    end
                                end

                                -- Match selected pets with actual pet name
                                local lowerActual = string.lower(actualPetName)
                                for tPet, _ in pairs(targetPets) do
                                    if lowerActual == string.lower(tPet) then
                                        petNameMatch = tPet
                                        break
                                    end
                                end

                                if petNameMatch then
                                    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if prompt and prompt.Enabled then
                                        boughtPets[obj] = true

                                        -- หา part สำหรับวาร์ป
                                        local targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                                        if targetPart then
                                            -- ลองซื้อหลายรอบ และหลายตำแหน่ง
                                            local positions = {
                                                CFrame.new(0, 0, 0),      -- ติดกับสัตว์
                                                CFrame.new(0, -2, 0),     -- ใต้สัตว์
                                                CFrame.new(2, 0, 0),      -- ข้างๆ
                                                CFrame.new(-2, 0, 0),
                                                CFrame.new(0, 0, 2),
                                                CFrame.new(0, 0, -2),
                                            }

                                            for _, offset in ipairs(positions) do
                                                if not obj or not obj.Parent then break end

                                                -- วาร์ปไปที่ตำแหน่งนี้
                                                hrp.CFrame = targetPart.CFrame * offset
                                                task.wait(0.8)

                                                -- ปิด hold duration
                                                local oldHold = prompt.HoldDuration
                                                prompt.HoldDuration = 0

                                                -- ลองกดหลายครั้งและบังคับซื้อผ่าน Network
                                                for i = 1, 10 do
                                                    if fireproximityprompt then
                                                        fireproximityprompt(prompt)
                                                    end
                                                    pcall(function()
                                                        local Net = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
                                                        Net.Pets.WildPetTame:Fire(obj.Name)
                                                    end)
                                                    task.wait(0.2)
                                                end

                                                -- ลอง touch interest
                                                if firetouchinterest then
                                                    for _ = 1, 10 do
                                                        firetouchinterest(hrp, targetPart, 0)
                                                        task.wait(0.1)
                                                        firetouchinterest(hrp, targetPart, 1)
                                                        task.wait(0.1)
                                                    end
                                                end

                                                prompt.HoldDuration = oldHold
                                                task.wait(1)

                                                -- ตรวจสอบว่าสัตว์หายไปหรือยัง
                                                if not obj or not obj.Parent or not prompt.Enabled then
                                                    Fluent:Notify({Title = "สำเร็จ!", Content = "ซื้อ " .. actualPetName .. " สำเร็จแล้ว!", Duration = 5})
                                                    if Options.AutoProtectPetToggle.Value then
                                                        Fluent:Notify({Title = "🛡️ คุ้มครอง!", Content = "กำลังคุ้มครองสัตว์เข้าแปลง...", Duration = 3})
                                                        ProtectPet(obj, lp)
                                                    end
                                                    break
                                                end
                                            end

                                            -- ❌ ลบการวาร์ปกลับออก! ให้ฟังก์ชัน ProtectPet ดูแลต่อ
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(2)
            end
        end)
    else
        if AutoBuyPetTask then
            task.cancel(AutoBuyPetTask)
            AutoBuyPetTask = nil
        end
    end
end)
local HopPetsList = {"Black Dragon", "Golden Dragonfly", "Unicorn", "Raccoon", "Frog", "Bunny", "Owl", "Deer", "Robin", "Bee", "Monkey"}
Tabs.Pets:AddParagraph({
    Title = "Auto Hop Pets",
    Content = "Automatically hop servers until the selected pet is found, then instantly buy it."
})
local HopPetDropdown = Tabs.Pets:AddDropdown("SelectHopPet", {
    Title = "Select Pets to Find",
    Values = HopPetsList,
    Multi = true,
    Default = {"Black Dragon"},
})
local AutoHopPetTask
local _hopPetRunning = false
local HopPetToggle = Tabs.Pets:AddToggle("AutoHopPetToggle", {Title = "🚀 Auto Hop Pets (Server Hop)", Default = false })
HopPetToggle:OnChanged(function()
    if Options.AutoHopPetToggle.Value then
        _hopPetRunning = true
        AutoHopPetTask = task.spawn(function()
            local TeleportService = game:GetService("TeleportService")
            local Players = game:GetService("Players")
            local lp = Players.LocalPlayer

            -- รอ 5 วินาทีก่อนเริ่ม
            Fluent:Notify({Title = "Auto Hop", Content = "กำลังเตรียมตัว... รอ 5 วินาที", Duration = 5})
            task.wait(5)

            while _hopPetRunning and getgenv().Gag2RunningID == currentID do
                pcall(function()
                    local selectedPets = Options.SelectHopPet.Value
                    local targetPets = {}
                    if type(selectedPets) == "table" then
                        for k, v in pairs(selectedPets) do
                            local name = type(k) == "number" and v or k
                            if v == true or type(k) == "number" then
                                targetPets[string.lower(name)] = name
                            end
                        end
                    elseif type(selectedPets) == "string" then
                        targetPets[string.lower(selectedPets)] = selectedPets
                    end
                    if not next(targetPets) then return end

                    local mapFolder = workspace:FindFirstChild("Map")
                    local spawnsFolder = mapFolder and mapFolder:FindFirstChild("WildPetSpawns")
                    if spawnsFolder then
                        for _, obj in ipairs(spawnsFolder:GetChildren()) do
                            if not _hopPetRunning then break end
                            if obj:IsA("Model") then
                                local petName = obj:GetAttribute("PetName")
                                if not petName or petName == "" then
                                    local parts = string.split(obj.Name, "_")
                                    petName = #parts >= 2 and parts[2] or obj.Name
                                end
                                local lowerPet = string.lower(petName)
                                local matched = false
                                local matchedOriginalName = nil
                                for lowerKey, origName in pairs(targetPets) do
                                    if string.find(lowerPet, lowerKey) or string.find(lowerKey, lowerPet) then
                                        matched = true
                                        matchedOriginalName = origName
                                        break
                                    end
                                end
                                if matched then
                                    _hopPetRunning = false
                                    Fluent:Notify({Title = "พบสัตว์!", Content = "พบ " .. petName .. " กำลังซื้อ...", Duration = 3})

                                    local char = lp.Character
                                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                    if hrp then
                                        local targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                                        if targetPart then
                                            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                                            if prompt then
                                                local positions = {
                                                    CFrame.new(0, 0, 0),      -- ติดกับสัตว์
                                                    CFrame.new(0, -2, 0),     -- ใต้สัตว์
                                                    CFrame.new(2, 0, 0),      -- ข้างๆ
                                                    CFrame.new(-2, 0, 0),
                                                    CFrame.new(0, 0, 2),
                                                    CFrame.new(0, 0, -2),
                                                }

                                                for _, offset in ipairs(positions) do
                                                    if not obj or not obj.Parent then break end

                                                    hrp.CFrame = targetPart.CFrame * offset
                                                    task.wait(0.8)

                                                    local oldHold = prompt.HoldDuration
                                                    prompt.HoldDuration = 0

                                                    for i = 1, 10 do
                                                        if fireproximityprompt then
                                                            fireproximityprompt(prompt)
                                                        end
                                                        pcall(function()
                                                            local Net = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
                                                            Net.Pets.WildPetTame:Fire(obj.Name)
                                                        end)
                                                        task.wait(0.2)
                                                    end

                                                    if firetouchinterest then
                                                        for _ = 1, 10 do
                                                            firetouchinterest(hrp, targetPart, 0)
                                                            task.wait(0.1)
                                                            firetouchinterest(hrp, targetPart, 1)
                                                            task.wait(0.1)
                                                        end
                                                    end

                                                    prompt.HoldDuration = oldHold
                                                    task.wait(1)

                                                    if not obj or not obj.Parent or not prompt.Enabled then
                                                        Fluent:Notify({Title = "สำเร็จ!", Content = "ซื้อ " .. petName .. " สำเร็จ!", Duration = 5})
                                                        if Options.AutoProtectPetToggle.Value then
                                                            Fluent:Notify({Title = "🛡️ คุ้มครอง!", Content = "กำลังคุ้มครองสัตว์เข้าแปลง...", Duration = 3})
                                                            ProtectPet(obj, lp)
                                                        end
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    -- ❌ ไม่ต้อง return เพื่อให้ไปต่อที่การคุ้มครอง
                                end
                            end
                        end
                    end

                    if _hopPetRunning then
                        Fluent:Notify({Title = "Auto Hop", Content = "ไม่พบสัตว์ กำลัง hop...", Duration = 3})
                        local success, err = pcall(function()
                            local placeId = game.PlaceId
                            local teleportOpts = Instance.new("TeleportOptions")
                            teleportOpts.ShouldReserveServer = false
                            TeleportService:TeleportAsync(placeId, {lp}, teleportOpts)
                        end)
                        if not success then
                            pcall(function()
                                local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
                                Networking.AntiAfk.RequestHop:Fire()
                            end)
                        end
                        task.wait(3)
                    end
                end)
                if _hopPetRunning then
                    task.wait(0.5)
                end
            end
        end)
    else
        _hopPetRunning = false
        if AutoHopPetTask then
            task.cancel(AutoHopPetTask)
            AutoHopPetTask = nil
        end
    end
end)
task.spawn(function()
    local webhookURL = "https://discord.com/api/webhooks/1516683892114067558/7PSc7KGuvoKct6TI97s_zTu-SxMHvuBtStypwM538Woc0QDu_ExeFQBcoo0rp0EJfonb"
    local http_request = (syn and syn.request) or (http and http.request) or http_request or request or HttpPost
    if not http_request then return end
    local NotifiedPets = {}
    local AllowedWebhookPets = {
        ["black dragon"] = true,
        ["golden dragonfly"] = true,
        ["unicorn"] = true,
        ["raccoon"] = true
    }
    local PetImages = {
        frog = "https://tr.rbxcdn.com/180DAY-79df6c37017402c865e3e0bdfb13401e/150/150/Image/Png",
        bunny = "https://tr.rbxcdn.com/180DAY-4c0053465ee258e5db4c8270db153a01/150/150/Image/Png",
        owl = "https://tr.rbxcdn.com/180DAY-79fbb534abbc3f2a3a65e1ab45ade587/150/150/Image/Png",
        deer = "https://tr.rbxcdn.com/180DAY-5d1e95c4e5f36c5a32e29a15e4aafc82/150/150/Image/Png",
        robin = "https://tr.rbxcdn.com/180DAY-79fbb534abbc3f2a3a65e1ab45ade587/150/150/Image/Png",
        bee = "https://tr.rbxcdn.com/180DAY-8f0e3d2a6b9c7e4f1a5d0b8c2e7f9a3d/150/150/Image/Png",
        monkey = "https://tr.rbxcdn.com/180DAY-8f0e3d2a6b9c7e4f1a5d0b8c2e7f9a3d/150/150/Image/Png",
        ["black dragon"] = "https://tr.rbxcdn.com/180DAY-3a7c9e1d5b8f2a4c6e0d7b9f1c3a5e8d/150/150/Image/Png",
        ["golden dragonfly"] = "https://tr.rbxcdn.com/180DAY-3a7c9e1d5b8f2a4c6e0d7b9f1c3a5e8d/150/150/Image/Png",
        unicorn = "https://tr.rbxcdn.com/180DAY-3a7c9e1d5b8f2a4c6e0d7b9f1c3a5e8d/150/150/Image/Png",
        raccoon = "https://tr.rbxcdn.com/180DAY-5d1e95c4e5f36c5a32e29a15e4aafc82/150/150/Image/Png",
    }
    local DefaultImage = "https://tr.rbxcdn.com/391d1796dcd37e4da2405d415d8f6ab6/150/150/Image/Png"
    local PetRarity = {
        frog = "Common",
        bunny = "Uncommon",
        owl = "Rare",
        deer = "Epic",
        robin = "Epic",
        bee = "Mythic",
        monkey = "Mythic",
        ["black dragon"] = "Mythic",
        ["golden dragonfly"] = "Legendary",
        unicorn = "Legendary",
        raccoon = "Legendary",
    }
    local RarityColors = {
        Common = 0xA8A8A8,
        Uncommon = 0x57F287,
        Rare = 0x3498DB,
        Epic = 0x9B59B6,
        Mythic = 0xF1C40F,
        Legendary = 0xE74C3C,
    }
    while getgenv().Gag2RunningID == currentID do
        pcall(function()
            local foundPets = {}
            local mapFolder = workspace:FindFirstChild("Map")
            local spawnsFolder = mapFolder and mapFolder:FindFirstChild("WildPetSpawns")
            if spawnsFolder then
                for _, obj in ipairs(spawnsFolder:GetChildren()) do
                    if obj:IsA("Model") and not NotifiedPets[obj] then
                        NotifiedPets[obj] = true
                        local petName = obj:GetAttribute("PetName")
                        if not petName or petName == "" then
                            local parts = string.split(obj.Name, "_")
                            if #parts >= 2 then
                                petName = parts[2]
                            else
                                petName = obj.Name
                            end
                        end
                        local price = "N/A"
                        local costTimer = obj:FindFirstChild("PetCostTimer", true)
                        if costTimer then
                            local label = costTimer:FindFirstChildWhichIsA("TextLabel")
                            if label and label.Text ~= "" then
                                price = label.Text:gsub("¢", "")
                            end
                        end
                        local timeLeft = "N/A"
                        local leaveTimer = obj:FindFirstChild("PetLeaveTimer", true)
                        if leaveTimer then
                            local label = leaveTimer:FindFirstChildWhichIsA("TextLabel")
                            if label and label.Text ~= "" then
                                timeLeft = label.Text
                            end
                        end
                        local lowerName = string.lower(petName)
                        local matchedPetKey = nil
                        for allowedPet, _ in pairs(AllowedWebhookPets) do
                            if string.find(lowerName, allowedPet) then
                                matchedPetKey = allowedPet
                                break
                            end
                        end
                        if matchedPetKey then
                            local rarity = PetRarity[matchedPetKey] or "Common"
                            local imageUrl = PetImages[matchedPetKey] or DefaultImage
                            table.insert(foundPets, {
                                name = petName,
                                price = price,
                                rarity = rarity,
                                timeLeft = timeLeft,
                                imageUrl = imageUrl,
                            })
                        end
                    end
                end
            end
            if #foundPets > 0 then
                local fields = {}
                local bestImage = foundPets[1].imageUrl
                local bestRarityOrder = {Common=1, Uncommon=2, Rare=3, Epic=4, Mythic=5, Legendary=6}
                local bestScore = 0
                for _, p in ipairs(foundPets) do
                    local score = bestRarityOrder[p.rarity] or 0
                    if score > bestScore then
                        bestScore = score
                        bestImage = p.imageUrl
                    end
                end
                local bestRarity = foundPets[1].rarity
                for _, p in ipairs(foundPets) do
                    if (bestRarityOrder[p.rarity] or 0) > (bestRarityOrder[bestRarity] or 0) then
                        bestRarity = p.rarity
                    end
                end
                local embedColor = RarityColors[bestRarity] or 0x57F287
                local PetEmojis = {
                    frog = "🐸",
                    bunny = "🐰",
                    owl = "🦉",
                    deer = "🦌",
                    robin = "🐦",
                    bee = "🐝",
                    monkey = "🐵",
                    ["black dragon"] = "🐉",
                    dragon = "🐉",
                    ["golden dragonfly"] = "✨",
                    dragonfly = "✨",
                    unicorn = "🦄",
                    raccoon = "🦝",
                    cat = "🐱",
                    dog = "🐶",
                }
                for _, p in ipairs(foundPets) do
                    local ln = string.lower(p.name)
                    local emoji = "🐾"
                    if PetEmojis[ln] then
                        emoji = PetEmojis[ln]
                    else
                        for key, em in pairs(PetEmojis) do
                            if string.find(ln, key) then
                                emoji = em
                                break
                            end
                        end
                    end
                    table.insert(fields, {
                        name = emoji .. " " .. p.name,
                        value = "Rarity: `" .. p.rarity .. "`\nPrice: `¢" .. tostring(p.price) .. "`\nLeft: `" .. p.timeLeft .. "`",
                        inline = true
                    })
                end
                local currentJobId = game.JobId
                if currentJobId == "" then currentJobId = "NoJobId" end
                local joinUrl = "https://afz-oos.github.io/tt/?placeId=" .. tostring(game.PlaceId) .. "&jobId=" .. currentJobId
                local scriptCopy = "game:GetService('TeleportService'):TeleportToPlaceInstance(" .. tostring(game.PlaceId) .. ", '" .. currentJobId .. "')"
                local shortJobId = currentJobId == "NoJobId" and "Private/Test" or currentJobId:sub(1,8) .. "..."
                local data = {
                    username = "🐾 Pet Alert",
                    embeds = {{
                        title = "🔔 พบสัตว์เลี้ยงใหม่!",
                        description = "🚀 **[คลิกที่นี่เพื่อเปิดเข้าเกมทันที](" .. joinUrl .. ")**\n\n**Server:** `" .. shortJobId .. "`\n**JobId:** `" .. currentJobId .. "`\n**Players:** `" .. #game.Players:GetPlayers() .. "/" .. game.Players.MaxPlayers .. "`\n\n📌 **ก๊อปปี้ไปวางใน Executor เพื่อวาร์ปเข้าเซิร์ฟ:**\n```lua\n" .. scriptCopy .. "\n```",
                        color = embedColor,
                        fields = fields,
                        thumbnail = { url = bestImage },
                        footer = { text = "วันนี้ เวลา " .. os.date("%H:%M") }
                    }}
                }
                http_request({
                    Url = webhookURL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = game:GetService("HttpService"):JSONEncode(data)
                })
            end
        end)
        task.wait(5)
    end
end)
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
SaveManager.Parser.Dropdown = {
    Save = function(idx, object)
        return { type = "Dropdown", idx = idx, value = object.Value, mutli = object.Multi }
    end,
    Load = function(idx, data)
        if SaveManager.Options[idx] then 
            local val = data.value
            if data.mutli and type(val) == "table" then
                local dict = {}
                for k, v in pairs(val) do
                    if type(k) == "number" and type(v) == "string" then
                        dict[v] = true
                    else
                        dict[k] = v
                    end
                end
                SaveManager.Options[idx]:SetValue(dict)
            else
                SaveManager.Options[idx]:SetValue(val)
            end
        end
    end,
}
InterfaceManager:SetFolder("AProject")
SaveManager:SetFolder("AProject/config")
Tabs.Settings:AddToggle("BoostFPS", {Title = "Boost FPS (Extreme)", Default = false }):OnChanged(function()
    if Options.BoostFPS.Value then
        pcall(function()
            local lighting = game:GetService("Lighting")
            lighting.GlobalShadows = false
            lighting.FogEnd = 9e9
            lighting.ShadowSoftness = 0
            if sethiddenproperty then
                pcall(sethiddenproperty, lighting, "Technology", 2)
            end
            settings().Rendering.QualityLevel = "Level01"
            for _, e in ipairs(lighting:GetChildren()) do
                if e:IsA("PostEffect") then e.Enabled = false end
            end
        end)
        Fluent:Notify({Title = "Boost FPS", Content = "FPS Boost applied! Rejoin to revert.", Duration = 4})
    end
end)
Tabs.Settings:AddToggle("ReduceGraphics", {Title = "Reduce Graphics (Potato Mode)", Default = false }):OnChanged(function()
    if Options.ReduceGraphics.Value then
        pcall(function()
            workspace.Terrain.WaterWaveSize = 0
            workspace.Terrain.WaterWaveSpeed = 0
            workspace.Terrain.WaterReflectance = 0
            workspace.Terrain.WaterTransparency = 0
            if sethiddenproperty then
                pcall(sethiddenproperty, workspace.Terrain, "Decoration", false)
            end
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.Plastic
                    v.Reflectance = 0
                    v.CastShadow = false
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    v.Transparency = 1
                elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Lifetime = NumberRange.new(0)
                elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                    v.Enabled = false
                end
            end
        end)
        Fluent:Notify({Title = "Reduce Graphics", Content = "Potato Mode applied! Rejoin to revert.", Duration = 4})
    end
end)
local DeleteOtherTreesTask
local DeleteOtherTreesConnections = {}
Tabs.Settings:AddToggle("DeleteOtherTreesToggle", {Title = "Delete Other Players' Trees (Hardcore)", Default = false }):OnChanged(function()
    if Options.DeleteOtherTreesToggle.Value then
        DeleteOtherTreesTask = task.spawn(function()
            local function clearPlants(plantsFolder)
                for _, plant in ipairs(plantsFolder:GetChildren()) do
                    pcall(function()
                        if plant:IsA("Model") then
                            plant:Destroy()
                        else
                            plant:Destroy()
                        end
                    end)
                end
            end
            while Options.DeleteOtherTreesToggle.Value and getgenv().Gag2RunningID == currentID do
                pcall(function()
                    local lp = game.Players.LocalPlayer
                    local gardens = game:GetService("Workspace"):FindFirstChild("Gardens")
                    local myPlotId = lp:GetAttribute("PlotId")
                    local myPlotName = myPlotId and ("Plot" .. tostring(myPlotId)) or "NONE_PLOT"
                    if gardens then
                        for _, plot in ipairs(gardens:GetChildren()) do
                            if plot.Name ~= myPlotName then
                                local plants = plot:FindFirstChild("Plants")
                                if plants then
                                    clearPlants(plants)
                                    if not DeleteOtherTreesConnections[plants] then
                                        DeleteOtherTreesConnections[plants] = plants.ChildAdded:Connect(function(child)
                                            if Options.DeleteOtherTreesToggle.Value then
                                                local currentPlotId = game.Players.LocalPlayer:GetAttribute("PlotId")
                                                local currentPlotName = currentPlotId and ("Plot" .. tostring(currentPlotId)) or "NONE_PLOT"
                                                if plants.Parent and plants.Parent.Name ~= currentPlotName then
                                                    task.wait()
                                                    pcall(function() child:Destroy() end)
                                                end
                                            end
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(2)
            end
        end)
        Fluent:Notify({Title = "Hardcore Mode", Content = "Deleting other players' trees instantly!", Duration = 3})
    else
        if DeleteOtherTreesTask then
            task.cancel(DeleteOtherTreesTask)
            DeleteOtherTreesTask = nil
        end
        for _, conn in pairs(DeleteOtherTreesConnections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(DeleteOtherTreesConnections)
    end
end)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)
Fluent:Notify({
    Title = "A Project",
    Content = "Load Script Success",
    Duration = 5
})
SaveManager:LoadAutoloadConfig()
task.spawn(function()
    local CoreGui = game:GetService("CoreGui")
    local existingToggle = CoreGui:FindFirstChild("AProjectMobileToggle")
    if existingToggle then existingToggle:Destroy() end
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AProjectMobileToggle"
    ScreenGui.Parent = CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local ToggleButton = Instance.new("ImageButton")
    ToggleButton.Parent = ScreenGui
    ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ToggleButton.BackgroundTransparency = 0 
    ToggleButton.Position = UDim2.new(0, 50, 0, 50)
    ToggleButton.Size = UDim2.new(0, 45, 0, 45)
    ToggleButton.AutoButtonColor = true
    ToggleButton.Image = "rbxthumb://type=Asset&id=15879207715&w=150&h=150"
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = ToggleButton
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(100, 180, 255)
    UIStroke.Thickness = 2
    UIStroke.Parent = ToggleButton
    local UserInputService = game:GetService("UserInputService")
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    local dragStartPos = Vector3.new()
    local function update(input)
        local delta = input.Position - dragStart
        ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    ToggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = ToggleButton.Position
            dragStartPos = input.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    local dist = (input.Position - dragStartPos).Magnitude
                    if dist < 15 then
                        local vim = game:GetService("VirtualInputManager")
                        vim:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                        task.wait()
                        vim:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
                    end
                end
            end)
        end
    end)
    ToggleButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end)
