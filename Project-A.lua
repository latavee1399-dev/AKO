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

local PetsList = {"All", "Frog", "Bunny", "Owl", "Deer", "Robin", "Bee", "Monkey", "Black Dragon", "Golden Dragonfly", "Unicorn", "Raccoon"}

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

local PetsInfoParagraph = Tabs.Main:AddParagraph({
    Title = "🐾 Pets in Server (Real-time)",
    Content = "Loading pets data..."
})

local function updatePetsDisplay()
    task.spawn(function()
        pcall(function()
            local petsInfo = {}
            local mapFolder = workspace:FindFirstChild("Map")
            local spawnsFolder = mapFolder and mapFolder:FindFirstChild("WildPetSpawns")

            if spawnsFolder then
                for _, obj in ipairs(spawnsFolder:GetChildren()) do
                    if obj:IsA("Model") then
                        local petName = obj:GetAttribute("PetName")
                        if not petName or petName == "" then
                            local parts = obj.Name:split("_")
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

                        table.insert(petsInfo, {
                            name = petName,
                            price = price,
                            time = timeLeft
                        })
                    end
                end
            end

            local displayText = ""
            if #petsInfo > 0 then
                displayText = string.format("📊 Total Pets: %d\n━━━━━━━━━━━━━━━━━━━━━━\n\n", #petsInfo)

                for _, pet in ipairs(petsInfo) do
                    displayText = displayText .. string.format(
                        "🐾 %s\n💰 Price: %s\n⏱️ Time Left: %s\n\n",
                        pet.name,
                        pet.price,
                        pet.time
                    )
                end
            else
                displayText = "❌ No pets found in this server"
            end

            PetsInfoParagraph:SetDesc(displayText)
        end)
    end)
end

task.spawn(function()
    while getgenv().Gag2RunningID == currentID do
        updatePetsDisplay()
        task.wait(3)
    end
end)

Tabs.Main:AddParagraph({
    Title = "━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    Content = ""
})

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

local Toggle = Tabs.Farm:AddToggle("AutoHarvestToggle", {Title = "Auto Harvest (ULTRA SPEED ⚡)", Default = false })
Toggle:OnChanged(function()
    if Options.AutoHarvestToggle.Value then
        local lp = game.Players.LocalPlayer
        local workspace = game:GetService("Workspace")
        local RunService = game:GetService("RunService")

        local gardens = workspace:FindFirstChild("Gardens")

        local targetFruits, hasAllFruits
        local targetBuffs, hasAllBuffs

        local function updateSelections()
            local selectedFruits = Options.SelectFruitToHarvest.Value
            targetFruits = {}
            hasAllFruits = false

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

            local selectedBuffs = Options.SelectBuffToHarvest.Value
            targetBuffs = {}
            hasAllBuffs = false

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
        end

        local updateCounter = 0
        updateSelections()

        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not Options.AutoHarvestToggle.Value or getgenv().Gag2RunningID ~= currentID then
                connection:Disconnect()
                return
            end

            updateCounter = updateCounter + 1
            if updateCounter >= 10 then
                updateSelections()
                updateCounter = 0
            end

            pcall(function()
                local myPlotId = lp:GetAttribute("PlotId")
                if not myPlotId or not gardens then return end

                local plot = gardens:FindFirstChild("Plot" .. tostring(myPlotId))
                if not plot then return end

                local plants = plot:FindFirstChild("Plants")
                if not plants then return end

                for _, plant in ipairs(plants:GetChildren()) do
                    local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt and prompt.ActionText == "Harvest" and prompt.Enabled then
                        if hasAllFruits and hasAllBuffs then
                            fireproximityprompt(prompt)
                        else
                            local canHarvest = true

                            if not hasAllFruits then
                                local seedName = plant:GetAttribute("SeedName")
                                if not seedName or not targetFruits[seedName] then
                                    canHarvest = false
                                end
                            end

                            if canHarvest and not hasAllBuffs then
                                local mutation = plant:GetAttribute("Mutation") or "Normal"
                                if not targetBuffs[mutation] then
                                    canHarvest = false
                                end
                            end

                            if canHarvest then
                                fireproximityprompt(prompt)
                            end
                        end
                    end
                end
            end)
        end)

        AutoHarvestTask = connection
    else
        if AutoHarvestTask then
            if type(AutoHarvestTask) == "table" and AutoHarvestTask.Disconnect then
                AutoHarvestTask:Disconnect()
            else
                task.cancel(AutoHarvestTask)
            end
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
                        
                        local seedName = plant:GetAttribute("SeedName") or "Unknown"
                        local mutation = plant:GetAttribute("Mutation") or "Normal"
                        local fruitMatch = hasAllFruits or targetFruits[seedName]
                        local buffMatch = hasAllBuffs or targetBuffs[mutation]
                        return fruitMatch and buffMatch
                    end
                    
                    local function SafeTeleport(hrp, targetCFrame)
                        local distance = (hrp.Position - targetCFrame.Position).Magnitude
                        if distance > 15 then
                            local TweenService = game:GetService("TweenService")
                            local speed = 150 -- studs per second
                            local timeInfo = distance / speed
                            local tweenInfo = TweenInfo.new(timeInfo, Enum.EasingStyle.Linear)
                            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
                            
                            local oldAnchored = hrp.Anchored
                            hrp.Anchored = true
                            tween:Play()
                            tween.Completed:Wait()
                            hrp.Anchored = oldAnchored
                        else
                            hrp.CFrame = targetCFrame
                        end
                        task.wait(0.2) 
                    end
                    
                    local function waterPlant(plant)
                        local plantId = plant:GetAttribute("PlantId")
                        local pp = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
                        if not plantId or not pp or not tool then return end
                        
                        wateredPlantsCooldown[plantId] = os.clock()
                        
                        local oldCFrame = hrp.CFrame
                        
                        SafeTeleport(hrp, pp.CFrame + Vector3.new(0, 3, 0))
                        
                        pcall(function() tool:Activate() end)
                        
                        pcall(function()
                            Networking.WateringCan.UseWateringCan:Fire(pp.Position, tool.Name, tool)
                        end)
                        
                        task.wait(0.2)
                        
                        SafeTeleport(hrp, oldCFrame)
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

local RemoveFruitDropdown = Tabs.Plant:AddDropdown("SelectRemoveFruit", {
    Title = "Select Trees to Remove",
    Values = {"All", "Apple", "Blueberry", "Strawberry", "Tomato", "Pineapple", "Pumpkin", "Watermelon", "Potato", "Carrot", "Onion", "Corn", "Wheat", "Radish", "Turnip", "Cabbage", "Lettuce", "Pepper", "Eggplant", "Mushroom"},
    Multi = true,
    Default = {"Apple"},
})

local RemoveBuffDropdown = Tabs.Plant:AddDropdown("SelectRemoveBuff", {
    Title = "Select Tree Buffs to Remove",
    Values = {"All", "Normal", "Gold", "Rainbow", "Electric", "Bloodlit", "Frozen", "Chained", "Pizza", "Secret", "Starstruck", "Giant", "Shiny"},
    Multi = true,
    Default = {"Normal"},
})

local AutoRemoveTask
local RemoveToggle = Tabs.Plant:AddToggle("AutoRemoveToggle", {Title = "Auto Remove Trees (Shovel)", Default = false })
RemoveToggle:OnChanged(function()
    if Options.AutoRemoveToggle.Value then
        AutoRemoveTask = task.spawn(function()
            local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            while Options.AutoRemoveToggle.Value and getgenv().Gag2RunningID == currentID do
                pcall(function()
                    local lp = game.Players.LocalPlayer
                    local char = lp.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    
                    local tool = nil
                    if char then
                        for _, t in ipairs(char:GetChildren()) do
                            if t:IsA("Tool") and string.find(t.Name, "Shovel") then
                                tool = t
                                break
                            end
                        end
                    end
                    if not tool and lp:FindFirstChild("Backpack") then
                        for _, t in ipairs(lp.Backpack:GetChildren()) do
                            if t:IsA("Tool") and string.find(t.Name, "Shovel") then
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
                    
                    local selectedFruits = Options.SelectRemoveFruit.Value
                    local targetFruits = {}
                    local hasAllFruits = false
                    if type(selectedFruits) == "table" then
                        for k, v in pairs(selectedFruits) do
                            local name = type(k) == "number" and v or k
                            if name == "All" and (v == true or type(k) == "number") then hasAllFruits = true end
                            if v == true or type(k) == "number" then targetFruits[name] = true end
                        end
                    end
                    
                    local selectedBuffs = Options.SelectRemoveBuff.Value
                    local targetBuffs = {}
                    local hasAllBuffs = false
                    if type(selectedBuffs) == "table" then
                        for k, v in pairs(selectedBuffs) do
                            local name = type(k) == "number" and v or k
                            if name == "All" and (v == true or type(k) == "number") then hasAllBuffs = true end
                            if v == true or type(k) == "number" then targetBuffs[name] = true end
                        end
                    end
                    
                    local function shouldRemove(plant)
                        local seedName = plant:GetAttribute("SeedName") or "Unknown"
                        local mutation = plant:GetAttribute("Mutation") or "Normal"
                        local fruitMatch = hasAllFruits or targetFruits[seedName]
                        local buffMatch = hasAllBuffs or targetBuffs[mutation]
                        return fruitMatch and buffMatch
                    end
                    
                    local function SafeTeleport(hrp, targetCFrame)
                        local distance = (hrp.Position - targetCFrame.Position).Magnitude
                        if distance > 15 then
                            local TweenService = game:GetService("TweenService")
                            local timeInfo = distance / 150
                            local tween = TweenService:Create(hrp, TweenInfo.new(timeInfo, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
                            local oldAnchored = hrp.Anchored
                            hrp.Anchored = true
                            tween:Play()
                            tween.Completed:Wait()
                            hrp.Anchored = oldAnchored
                        else
                            hrp.CFrame = targetCFrame
                        end
                        task.wait(0.2)
                    end
                    
                    local gardens = workspace:FindFirstChild("Gardens")
                    if gardens then
                        local myPlotId = lp:GetAttribute("PlotId")
                        local plot = myPlotId and gardens:FindFirstChild("Plot" .. tostring(myPlotId))
                        if plot then
                            local plantsFolder = plot:FindFirstChild("Plants")
                            if plantsFolder then
                                for _, plant in ipairs(plantsFolder:GetChildren()) do
                                    if shouldRemove(plant) then
                                        local pp = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
                                        if pp then
                                            local oldCFrame = hrp.CFrame
                                            
                                            SafeTeleport(hrp, pp.CFrame + Vector3.new(0, 3, 0))
                                            
                                            local plantFullName = plant.Name
                                            if plantFullName then
                                                for i = 1, 15 do
                                                    if not plant or not plant.Parent then break end
                                                    
                                                    pcall(function() tool:Activate() end)
                                                    
                                                    pcall(function()
                                                        Networking.Shovel.UseShovel:Fire(plantFullName, tool.Name, tool)
                                                    end)
                                                    
                                                    task.wait(0.1)
                                                    pcall(function() Networking.Shovel.SwingShovel:Fire() end)
                                                    task.wait(0.3)
                                                end
                                            end
                                            
                                            task.wait(0.3)
                                            
                                            SafeTeleport(hrp, oldCFrame)
                                            break 
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.5)
            end
        end)
    else
        if AutoRemoveTask then
            task.cancel(AutoRemoveTask)
            AutoRemoveTask = nil
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
    local lp = game.Players.LocalPlayer
    local char = lp.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local selectedTypes = Options.SelectSprinklerType.Value
    local targetTypes = {}
    local hasAllTypes = false
    if type(selectedTypes) == "table" then
        for k, v in pairs(selectedTypes) do
            local name = type(k) == "number" and v or k
            if name == "All" and (v == true or type(k) == "number") then hasAllTypes = true end
            if v == true or type(k) == "number" then targetTypes[name] = true end
        end
    end

    local function isCorrectSprinkler(t)
        if t:IsA("Tool") and string.find(t.Name, "Sprinkler") then
            if hasAllTypes then return true end
            if targetTypes[t.Name] then return true end
        end
        return false
    end
    
    local tool = nil
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if isCorrectSprinkler(t) then
                tool = t
                break
            end
        end
    end
    if not tool and lp:FindFirstChild("Backpack") then
        for _, t in ipairs(lp.Backpack:GetChildren()) do
            if isCorrectSprinkler(t) then
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
    
    local selectedFruits = Options.SelectSprinklerFruit.Value
    local targetFruits = {}
    local hasAllFruits = false
    if type(selectedFruits) == "table" then
        for k, v in pairs(selectedFruits) do
            local name = type(k) == "number" and v or k
            if name == "All" and (v == true or type(k) == "number") then hasAllFruits = true end
            if v == true or type(k) == "number" then targetFruits[name] = true end
        end
    end
    
    local selectedBuffs = Options.SelectSprinklerBuff.Value
    local targetBuffs = {}
    local hasAllBuffs = false
    if type(selectedBuffs) == "table" then
        for k, v in pairs(selectedBuffs) do
            local name = type(k) == "number" and v or k
            if name == "All" and (v == true or type(k) == "number") then hasAllBuffs = true end
            if v == true or type(k) == "number" then targetBuffs[name] = true end
        end
    end
    
    local weightMode = Options.SelectSprinklerWeight.Value
    
    local function shouldSprinkler(plant)
        local seedName = plant:GetAttribute("SeedName") or "Unknown"
        local mutation = plant:GetAttribute("Mutation") or "Normal"
        local fruitMatch = hasAllFruits or targetFruits[seedName]
        local buffMatch = hasAllBuffs or targetBuffs[mutation]
        return fruitMatch and buffMatch
    end
    
    local gardens = workspace:FindFirstChild("Gardens")
    if not gardens then return end
    local myPlotId = lp:GetAttribute("PlotId")
    local plot = myPlotId and gardens:FindFirstChild("Plot" .. tostring(myPlotId))
    if not plot then return end
    
    local plantsFolder = plot:FindFirstChild("Plants")
    local sprinklersFolder = plot:FindFirstChild("Sprinklers")
    if not plantsFolder then return end
    
    local bestPlant = nil
    local bestVal = (weightMode == "Heaviest") and -math.huge or math.huge
    
    for _, plant in ipairs(plantsFolder:GetChildren()) do
        if shouldSprinkler(plant) then
            local pp = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
            if pp then
                local hasSprinkler = false
                if sprinklersFolder then
                    for _, s in ipairs(sprinklersFolder:GetChildren()) do
                        local s_pp = s.PrimaryPart or s:FindFirstChildWhichIsA("BasePart")
                        if s_pp and (s_pp.Position - pp.Position).Magnitude < 6 then
                            hasSprinkler = true
                            break
                        end
                    end
                end
                
                if not hasSprinkler then
                    if weightMode == "All" then
                        bestPlant = plant
                        break
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
        end
    end
    
    if bestPlant then
        local pp = bestPlant.PrimaryPart or bestPlant:FindFirstChildWhichIsA("BasePart")
        if pp then
            local oldCFrame = hrp.CFrame
            local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            
            local distance = (hrp.Position - pp.Position).Magnitude
            if distance > 15 then
                local TweenService = game:GetService("TweenService")
                local tween = TweenService:Create(hrp, TweenInfo.new(distance/150, Enum.EasingStyle.Linear), {CFrame = pp.CFrame + Vector3.new(0,3,0)})
                local oldAnch = hrp.Anchored
                hrp.Anchored = true
                tween:Play()
                tween.Completed:Wait()
                hrp.Anchored = oldAnch
            else
                hrp.CFrame = pp.CFrame + Vector3.new(0,3,0)
            end
            task.wait(0.2)
            
            pcall(function() tool:Activate() end)
            pcall(function() Networking.Place.PlaceSprinkler:Fire(pp.Position + Vector3.new(1.5, 0, 1.5), tool.Name, tool, 1) end)
            task.wait(0.3)
            
            local dist2 = (hrp.Position - oldCFrame.Position).Magnitude
            if dist2 > 15 then
                local TweenService = game:GetService("TweenService")
                local tween2 = TweenService:Create(hrp, TweenInfo.new(dist2/150, Enum.EasingStyle.Linear), {CFrame = oldCFrame})
                local oldAnch2 = hrp.Anchored
                hrp.Anchored = true
                tween2:Play()
                tween2.Completed:Wait()
                hrp.Anchored = oldAnch2
            else
                hrp.CFrame = oldCFrame
            end
        end
    end
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
                        local seedName = string.gsub(tool.Name, " Seed", "")

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

local PickToggle = Tabs.Farm:AddToggle("AutoPickEventToggle", {Title = "Auto Pick Event (ANTI-CHEAT BYPASS 🛡️)", Default = false })
PickToggle:OnChanged(function()
    if Options.AutoPickEventToggle.Value then
        AutoPickEventTask = task.spawn(function()
            local success, NetworkingModule = pcall(function()
                return require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            end)

            if not success then
                warn("[Auto Pick Event] Failed to load Networking module:", NetworkingModule)
                return
            end

            local Networking = NetworkingModule

            local lp = game.Players.LocalPlayer
            local pickedSeeds = {}
            local currentlyPickingSeed = nil

            local TARGET_SEEDS = {
                ["Rainbow"] = 100,
                ["Gold"] = 50,
                ["Rare"] = 10,
                ["Uncommon"] = 5,
                ["Common"] = 1,
            }

            local function getSeedPriority(seedName)
                for keyword, priority in pairs(TARGET_SEEDS) do
                    if string.find(string.lower(seedName), string.lower(keyword)) then
                        return priority
                    end
                end
                return 1
            end

            local function isSeedOnGround(seed)
                local part = seed:IsA("Model") and (seed.PrimaryPart or seed:FindFirstChildWhichIsA("BasePart", true)) or seed
                if not part or not part:IsA("BasePart") then return false end

                local velocity = part.AssemblyLinearVelocity
                if velocity and (velocity.Y < -1 or velocity.Y > 1) then return false end

                local rayOrigin = part.Position
                local rayDirection = Vector3.new(0, -10, 0)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {workspace.Gardens, seed}
                raycastParams.FilterType = Enum.RaycastFilterType.Include

                local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                if result and result.Distance < 2 then
                    return true
                end

                return false
            end

            local function instantTP(hrp, targetPos)
                if not hrp or not targetPos then return false end

                hrp.CFrame = CFrame.new(targetPos)
                task.wait(0.05)

                return true
            end

            local function tryPickSeed(seed)
                if pickedSeeds[seed] or currentlyPickingSeed == seed then return false end
                if not seed or not seed.Parent then return false end

                local waitStart = os.clock()
                while not isSeedOnGround(seed) and (os.clock() - waitStart < 2) do
                    if not seed or not seed.Parent then return false end
                    task.wait(0.05)
                end

                if not seed or not seed.Parent then return false end

                currentlyPickingSeed = seed
                pickedSeeds[seed] = true

                local char = lp.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChild("Humanoid")

                if not hrp or not hum then
                    currentlyPickingSeed = nil
                    return false
                end

                local part = seed:IsA("Model") and (seed.PrimaryPart or seed:FindFirstChildWhichIsA("BasePart", true)) or seed
                if not part or not part:IsA("BasePart") then
                    currentlyPickingSeed = nil
                    return false
                end

                local targetPos = part.Position + Vector3.new(0, 3, 0)
                pcall(function()
                    instantTP(hrp, targetPos)
                end)

                for attempt = 1, 10 do
                    if not seed or not seed.Parent then break end

                    task.spawn(function()
                        pcall(function()
                            Networking.SeedPack.ClickPack:Fire(seed)
                        end)
                    end)

                    task.spawn(function()
                        local prompt = seed:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if prompt then
                            pcall(function()
                                fireproximityprompt(prompt)
                            end)
                        end
                    end)

                    task.spawn(function()
                        if firetouchinterest and part then
                            pcall(function()
                                firetouchinterest(hrp, part, 0)
                                task.wait()
                                firetouchinterest(hrp, part, 1)
                            end)
                        end
                    end)

                    task.wait(0.05) 
                end

                local checkStart = os.clock()
                while seed and seed.Parent and (os.clock() - checkStart < 0.5) do
                    task.wait(0.03)
                end

                currentlyPickingSeed = nil
                return not seed or not seed.Parent
            end

            local function scanAndPickSeeds()
                local char = lp.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local seedsQueue = {}
                local mapFolder = workspace:FindFirstChild("Map")

                if mapFolder then
                    local foldersToScan = {
                        mapFolder:FindFirstChild("SeedPackSpawnClient"),
                        mapFolder:FindFirstChild("SeedPackSpawnServerLocations"),
                    }

                    for _, folder in ipairs(foldersToScan) do
                        if folder then
                            for _, seed in ipairs(folder:GetChildren()) do
                                if seed and seed.Parent and not pickedSeeds[seed] then
                                    local seedName = seed.Name or "Unknown"
                                    local priority = getSeedPriority(seedName)

                                    if priority >= 50 then
                                        local part = seed:IsA("Model") and (seed.PrimaryPart or seed:FindFirstChildWhichIsA("BasePart", true)) or seed
                                        if part and part:IsA("BasePart") then
                                            local distance = (hrp.Position - part.Position).Magnitude
                                            table.insert(seedsQueue, {
                                                seed = seed,
                                                priority = priority,
                                                distance = distance,
                                                score = priority * 1000 - distance
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                table.sort(seedsQueue, function(a, b) return a.score > b.score end)

                for _, info in ipairs(seedsQueue) do
                    if not Options.AutoPickEventToggle.Value or getgenv().Gag2RunningID ~= currentID then
                        break
                    end
                    tryPickSeed(info.seed)
                end
            end

            while Options.AutoPickEventToggle.Value and getgenv().Gag2RunningID == currentID do
                pcall(scanAndPickSeeds)
                task.wait(0.2) 
            end
        end)
    else
        if AutoPickEventTask then
            task.cancel(AutoPickEventTask)
            AutoPickEventTask = nil
        end
        for _, conn in ipairs(_seedPackConnections) do
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
                                if tool:IsA("Tool") then
                                    local fruitName = tool:GetAttribute("FruitName")
                                    if fruitName and selectedFruits[fruitName] then
                                        local id = tool:GetAttribute("Id")
                                        if id then table.insert(toolsToSell, id) end
                                    end
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

local SendPetDropdown = Tabs.Trade:AddDropdown("SelectPetToSend", {
    Title = "Select Pets to Send",
    Values = PetsList,
    Multi = true,
    Default = {},
})

local SendMailToggle = Tabs.Trade:AddToggle("AutoSendMailToggle", {Title = "Auto SendMail", Default = false })
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
                            local selPets = Options.SelectPetToSend.Value

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

                            local isAllPets = false
                            local petsDict = {}
                            if type(selPets) == "table" then
                                for k, v in pairs(selPets) do
                                    local name = type(k) == "number" and v or k
                                    if name == "All" and (v == true or type(k) == "number") then isAllPets = true end
                                    if v == true or type(k) == "number" then petsDict[name] = true end
                                end
                            end

                            for category, categoryItems in pairs(inventory) do
                                if category ~= "HarvestedFruits" then
                                    for itemKey, itemData in pairs(categoryItems) do
                                        -- Handle both number and table format
                                        local count = type(itemData) == "number" and itemData or (type(itemData) == "table" and 1 or 0)

                                        if count > 0 then
                                            local shouldSend = false
                                            if category == "Seeds" then
                                                if isAllSeeds or seedsDict[itemKey] then
                                                    shouldSend = true
                                                end
                                            elseif category == "Pets" then
                                                if isAllPets or petsDict[itemKey] then
                                                    shouldSend = true
                                                end
                                            else
                                                if isAllGears or gearsDict[itemKey] then
                                                    shouldSend = true
                                                end
                                            end
                                            
                                            if shouldSend then
                                                local finalCount = count
                                                if targetAmount > 0 then
                                                    local sent = sentTracker[itemKey] or 0
                                                    if sent >= targetAmount then
                                                        shouldSend = false
                                                    else
                                                        finalCount = math.min(count, targetAmount - sent)
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
            local selPets = Options.SelectPetToSend.Value

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

            local isAllPets = false
            local petsDict = {}
            if type(selPets) == "table" then
                for k, v in pairs(selPets) do
                    local name = type(k) == "number" and v or k
                    if name == "All" and (v == true or type(k) == "number") then isAllPets = true end
                    if v == true or type(k) == "number" then petsDict[name] = true end
                end
            end

            for category, categoryItems in pairs(inventory) do
                if category ~= "HarvestedFruits" then
                    for itemKey, itemData in pairs(categoryItems) do
                        -- Handle both number and table format
                        local count = type(itemData) == "number" and itemData or (type(itemData) == "table" and 1 or 0)

                        if count > 0 then
                            local shouldSend = false
                            if category == "Seeds" then
                                if isAllSeeds or seedsDict[itemKey] then shouldSend = true end
                            elseif category == "Pets" then
                                if isAllPets or petsDict[itemKey] then shouldSend = true end
                            else
                                if isAllGears or gearsDict[itemKey] then shouldSend = true end
                            end

                            if shouldSend then
                                local finalCount = count
                                if targetAmount > 0 then
                                    finalCount = math.min(count, targetAmount)
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

Tabs.Gift:AddParagraph({Title="Gift System V5 TURBO",Content="10 items/batch, 0.15s delay\nParallel send/claim, 6x faster!\nInventory + Tools + Safe"})
Tabs.Gift:AddInput("GiftTarget",{Title="Target Player Name",Default="",Placeholder="Enter player name",Numeric=false,Finished=false})
Tabs.Gift:AddDropdown("GiftSeeds",{Title="Seeds",Values=SeedsList,Multi=true,Default={}})
Tabs.Gift:AddDropdown("GiftFruits",{Title="Fruits",Values=SeedsList,Multi=true,Default={}})
Tabs.Gift:AddDropdown("GiftGears",{Title="Gears",Values=GearsList,Multi=true,Default={}})

local GiftCooldown={}
local function DoGift()
    local success, errorMsg = pcall(function()
        local target=Options.GiftTarget.Value
        if not target or target==""then
            Fluent:Notify({Title="Error",Content="Please enter recipient name!",Duration=2})
            return
        end

        if GiftCooldown[target] and (os.clock()-GiftCooldown[target])<2 then
            local remaining = math.ceil(2-(os.clock()-GiftCooldown[target]))
            Fluent:Notify({Title="Cooldown",Content="Wait "..remaining.." seconds",Duration=1})
            return
        end

        local Net, PSC
        local modSuccess = pcall(function()
            Net = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            PSC = require(game:GetService("ReplicatedStorage").ClientModules.PlayerStateClient)
        end)

        if not modSuccess or not Net or not PSC then
            Fluent:Notify({Title="Error",Content="Failed to load modules!",Duration=3})
            return
        end

        local lp = game.Players.LocalPlayer
        if not lp then return end

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
            Fluent:Notify({Title="Not Found",Content="Player '"..target.."' not found",Duration=3})
            return
        end

        local batch = {}
        local invSuccess, inv = pcall(function()
            return PSC.GetLocalReplica().Data.Inventory
        end)

        if not invSuccess or not inv then
            Fluent:Notify({Title="Error",Content="Failed to read Inventory!",Duration=3})
            return
        end

        local selS = Options.GiftSeeds.Value
        local selF = Options.GiftFruits.Value
        local selG = Options.GiftGears.Value
        local hasAllS, hasAllF, hasAllG = false, false, false

        if type(selS)=="table"then
            for k,v in pairs(selS)do
                if (type(k)=="number" and v=="All") or (k=="All" and v==true) then
                    hasAllS=true
                    break
                end
            end
        end

        if type(selF)=="table"then
            for k,v in pairs(selF)do
                if (type(k)=="number" and v=="All") or (k=="All" and v==true) then
                    hasAllF=true
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
                        elseif cat=="HarvestedFruits" then
                            ok = hasAllF
                            if not ok and type(selF)=="table" then
                                for k,v in pairs(selF) do
                                    if (type(k)=="number" and v==name) or (k==name and v==true) then
                                        ok=true
                                        break
                                    end
                                end
                            end
                        elseif cat~="Pets" then
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

        for _, folder in ipairs({lp:FindFirstChild("Backpack"), lp.Character}) do
            if folder then
                for _, tool in ipairs(folder:GetChildren()) do
                    if tool:IsA("Tool") then
                        local fname = tool:GetAttribute("FruitName")
                        if fname then
                            local ok = hasAllF
                            if not ok and type(selF)=="table" and selF[fname] then
                                ok = true
                            end
                            if ok then
                                table.insert(batch, {Category="HarvestedFruits", ItemKey=fname, Count=1})
                            end
                        end
                    end
                end
            end
        end

        if #batch == 0 then
            Fluent:Notify({Title="Empty",Content="No items to send! Select Seeds/Fruits/Gears",Duration=3})
            return
        end

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
        Fluent:Notify({Title="Success",Content="Sent "..sent.." items successfully!",Duration=2})
    end)

    if not success then
        Fluent:Notify({Title="Error",Content="Error occurred: "..tostring(errorMsg),Duration=3})
    end
end

Tabs.Gift:AddButton({
    Title="Send Gift Now (TURBO)",
    Description="Ultra fast: 10 items/batch, 0.15s delay",
    Callback=function()
        task.spawn(DoGift)
    end
})

local AGT
Tabs.Gift:AddToggle("AutoGift", {Title="Auto Gift (2.5s interval)", Default=false}):OnChanged(function()
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

Tabs.Gift:AddToggle("AutoClaim", {Title="Auto Claim TURBO (1s interval)", Default=false}):OnChanged(function()
    if Options.AutoClaim.Value then
        getgenv().ACT = task.spawn(function()
            local Net
            local modSuccess = pcall(function()
                Net = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            end)

            if not modSuccess or not Net then
                Fluent:Notify({Title="Error",Content="Failed to load Networking module!",Duration=3})
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
                            Fluent:Notify({Title="Claimed",Content="Received "..count.." items successfully!",Duration=1})
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

-- ============================================================
-- Pets Tab
-- ============================================================

local PetDropdown = Tabs.Pets:AddDropdown("SelectPetToBuy", {
    Title = "Select Pets to Auto Buy",
    Values = PetsList,
    Multi = true,
    Default = {"All"},
})

local AutoBuyPetTask
local BuyPetToggle = Tabs.Pets:AddToggle("AutoBuyPetToggle", {Title = "Auto Buy Selected Pets", Default = false })

BuyPetToggle:OnChanged(function()
    if Options.AutoBuyPetToggle.Value then
        AutoBuyPetTask = task.spawn(function()
            local PlayerStateClient = require(game:GetService("ReplicatedStorage").ClientModules.PlayerStateClient)
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

                    for _, obj in ipairs(workspace:GetDescendants()) do
                        local petNameMatch = nil
                        for tPet, _ in pairs(targetPets) do
                            if string.find(string.lower(obj.Name), string.lower(tPet)) then
                                petNameMatch = tPet
                                break
                            end
                        end
                        
                        if (obj:IsA("Model") or obj:IsA("BasePart")) and petNameMatch then
                            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                            if prompt and prompt.Enabled then
                                local targetCFrame = obj:IsA("Model") and (obj.PrimaryPart and obj.PrimaryPart.CFrame or obj:GetModelCFrame()) or obj.CFrame
                                if targetCFrame then
                                    hrp.CFrame = targetCFrame
                                    task.wait(0.3)
                                    
                                    local oldHold = prompt.HoldDuration
                                    prompt.HoldDuration = 0
                                    fireproximityprompt(prompt)
                                    task.wait(0.1)
                                    prompt.HoldDuration = oldHold
                                    
                                    task.wait(0.5)
                                    
                                    local plotId = lp:GetAttribute("PlotId")
                                    if plotId then
                                        local plot = workspace.Gardens:FindFirstChild("Plot" .. tostring(plotId))
                                        if plot then
                                            local plotCFrame = plot.PrimaryPart and plot.PrimaryPart.CFrame or plot:GetModelCFrame()
                                            hrp.CFrame = plotCFrame + Vector3.new(0, 10, 0)
                                            task.wait(2)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(3) 
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
    Title = "⚡ Auto Hop Pets",
    Content = "Automatically hop servers until the selected pet is found, then instantly buy it."
})

local HopPetDropdown = Tabs.Pets:AddDropdown("SelectHopPet", {
    Title = "🎯 Select Pets to Find",
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

                                    local char = lp.Character
                                    local hrp = char and char:FindFirstChild("HumanoidRootPart")

                                    if hrp then
                                        local tp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
                                        if tp then
                                            hrp.CFrame = tp.CFrame
                                            task.wait(0.3)
                                        end
                                    end

                                    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if prompt then
                                        local oldHold = prompt.HoldDuration
                                        prompt.HoldDuration = 0
                                        fireproximityprompt(prompt)
                                        task.wait(0.2)
                                        fireproximityprompt(prompt)
                                        prompt.HoldDuration = oldHold
                                    end

                                    HopPetToggle:SetValue(false)
                                    return
                                end
                            end
                        end
                    end

                    if _hopPetRunning then
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

local lp = game:GetService("Players").LocalPlayer or game:GetService("Players").PlayerAdded:Wait()
task.wait(2)

local Config = {
    TargetPets = {
        "Golden Dragonfly",
        "Unicorn",
        "Raccoon"
    },
    WebhookURL1 = "https://discord.com/api/webhooks/1519275368283111424/jK3_OYM_1zbEGflIS9LW7tkpglCOsytERwS_8KBGuB9f9uhBEZTVlAQ6x12axDKj8b5o",
    WebhookURL2 = "https://discord.com/api/webhooks/1516683892114067558/7PSc7KGuvoKct6TI97s_zTu-SxMHvuBtStypwM538Woc0QDu_ExeFQBcoo0rp0EJfonb", -- ใส่ลิงก์ Webhook ที่ 2 ตรงนี้
    WebAPIURL = "https://longong.xyz/receiveUi.php",
    CheckInterval = 0.5
}

local PetRarity = {
    frog = "Common", bunny = "Uncommon", owl = "Rare",
    deer = "Epic", robin = "Epic", bee = "Mythic",
    monkey = "Mythic", ["black dragon"] = "Mythic",
    ["golden dragonfly"] = "Legendary", unicorn = "Legendary",
    raccoon = "Legendary"
}

local RarityColors = {
    Common = 0xA8A8A8, Uncommon = 0x57F287, Rare = 0x3498DB,
    Epic = 0x9B59B6, Mythic = 0xF1C40F, Legendary = 0xE74C3C
}

local PetEmojis = {
    frog = "🐸", bunny = "🐰", owl = "🦉", deer = "🦌",
    robin = "🐦", bee = "🐝", monkey = "🐵",
    ["black dragon"] = "🐉", ["golden dragonfly"] = "✨",
    unicorn = "🦄", raccoon = "🦝"
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
    raccoon = "https://tr.rbxcdn.com/180DAY-5d1e95c4e5f36c5a32e29a15e4aafc82/150/150/Image/Png"
}

local DefaultImage = "https://tr.rbxcdn.com/391d1796dcd37e4da2405d415d8f6ab6/150/150/Image/Png"

local sentPets = {}  

local function getPetNameFromObject(obj)
    local petName = obj:GetAttribute("PetName")
    if not petName or petName == "" then
        if string.find(obj.Name, "_") then
            local parts = string.split(obj.Name, "_")
            petName = #parts >= 2 and parts[2] or obj.Name
        else
            petName = obj.Name
        end
    end
    return petName
end

local function sendToWeb(petName, playerCount, teleportCommand)
    local http_request = (syn and syn.request) or (http and http.request) or http_request or request
    if not http_request then return false end

    local jobId = game.JobId ~= "" and game.JobId or "NoJobId_" .. tostring(math.random(100000, 999999))
    local username = lp.Name or "Unknown"
    local placeId = tostring(game.PlaceId)

    local data = {
        jobId = jobId,
        placeId = placeId,
        players = playerCount,
        teleport = teleportCommand,
        petName = petName,
        username = username,
        timestamp = os.time()
    }

    pcall(function()
        http_request({
            Url = Config.WebAPIURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = game:GetService("HttpService"):JSONEncode(data)
        })
    end)

    return true
end

local function sendWebhook(petName, petObj)
    local http_request = (syn and syn.request) or (http and http.request) or http_request or request
    if not http_request then return end

    pcall(function()
        local lowerName = string.lower(petName)
        local rarity = PetRarity[lowerName] or "Common"
        local color = RarityColors[rarity] or 0x57F287
        local emoji = PetEmojis[lowerName] or "🐾"
        local imageUrl = PetImages[lowerName] or DefaultImage

        local price = "N/A"
        local costTimer = petObj:FindFirstChild("PetCostTimer", true)
        if costTimer then
            local label = costTimer:FindFirstChildWhichIsA("TextLabel")
            if label and label.Text ~= "" then
                price = label.Text:gsub("¢", "")
            end
        end

        local timeLeft = "N/A"
        local leaveTimer = petObj:FindFirstChild("PetLeaveTimer", true)
        if leaveTimer then
            local label = leaveTimer:FindFirstChildWhichIsA("TextLabel")
            if label and label.Text ~= "" then
                timeLeft = label.Text
            end
        end

        local jobId = game.JobId ~= "" and game.JobId or "NoJobId"
        local shortJobId = jobId == "NoJobId" and "Private/Test" or jobId:sub(1,8) .. "..."
        local placeId = tostring(game.PlaceId)
        local joinUrl = "https://afz-oos.github.io/tt/?placeId=" .. placeId .. "&jobId=" .. jobId
        local scriptCopy = "game:GetService('TeleportService'):TeleportToPlaceInstance(" .. placeId .. ", '" .. jobId .. "')"

        local data = {
            username = "🐾 Pet Alert",
            embeds = {{
                title = "🔔 พบสัตว์เลี้ยงใหม่!",
                description = "🚀 **[คลิกที่นี่เพื่อเปิดเข้าเกมทันที](" .. joinUrl .. ")**\n\n**Place ID:** `" .. placeId .. "`\n**Server ID:** `" .. jobId .. "`\n**Short JobId:** `" .. shortJobId .. "`\n**Players:** `" .. #game.Players:GetPlayers() .. "/" .. game.Players.MaxPlayers .. "`\n\n📌 **ก๊อปปี้ไปวางใน Executor เพื่อวาร์ปเข้าเซิร์ฟ:**\n```lua\n" .. scriptCopy .. "\n```",
                color = color,
                fields = {{
                    name = emoji .. " " .. petName,
                    value = "Rarity: `" .. rarity .. "`\nPrice: `¢" .. tostring(price) .. "`\nLeft: `" .. timeLeft .. "`",
                    inline = true
                }},
                thumbnail = { url = imageUrl },
                footer = { text = "วันนี้ เวลา " .. os.date("%H:%M") }
            }}
        }

        local jsonData = game:GetService("HttpService"):JSONEncode(data)

        task.spawn(function()
            pcall(function()
                http_request({
                    Url = Config.WebhookURL1,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = jsonData
                })
            end)
        end)

        task.spawn(function()
            pcall(function()
                http_request({
                    Url = Config.WebhookURL2,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = jsonData
                })
            end)
        end)
    end)
end

local function scanAndSend()
    local mapFolder = workspace:FindFirstChild("Map")
    if not mapFolder then return end

    local spawnsFolder = mapFolder:FindFirstChild("WildPetSpawns")
    if not spawnsFolder then return end

    local targetPets = {}
    for _, petName in next, Config.TargetPets do
        targetPets[string.lower(petName)] = petName
    end

    for _, obj in next, spawnsFolder:GetChildren() do
        if obj:IsA("Model") then
            local petName = getPetNameFromObject(obj)
            local lowerPet = string.lower(petName)

            for lowerKey, origName in next, targetPets do
                if lowerPet == lowerKey then
                    local petKey = obj:GetDebugId()

                    if sentPets[petKey] then
                        return false
                    end

                    local placeId = game.PlaceId
                    local jobId = game.JobId
                    local teleportCmd = "game:GetService('TeleportService'):TeleportToPlaceInstance(" ..
                                        tostring(placeId) .. ", '" .. jobId .. "')"
                    local playerCount = #game.Players:GetPlayers()

                    sendWebhook(petName, obj)
                    sendToWeb(petName, playerCount, teleportCmd)

                    sentPets[petKey] = true

                    task.spawn(function()
                        while obj and obj.Parent do
                            task.wait(1)
                        end
                        sentPets[petKey] = nil
                    end)

                    return true
                end
            end
        end
    end

    return false
end

task.spawn(function()
    while task.wait(Config.CheckInterval) do
        pcall(scanAndSend)
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
