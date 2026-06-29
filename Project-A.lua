repeat wait() until game:IsLoaded()

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function AdvancedTP(hrp, targetCFrame)
    if not hrp then return end
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    
    -- ถ้าใกล้ๆ ให้วาร์ปไปเลย
    if distance <= 15 then
        hrp.CFrame = targetCFrame
        task.wait(0.1)
        return
    end

    -- ป้องกันการเด้งกลับ (Rubberbanding)
    -- เกมนี้มีระบบจับความเร็ว ถ้าพุ่งพรวดเดียว 50 studs/frame เซิร์ฟเวอร์จะมองว่าวาร์ปแล้วดึงกลับ
    -- เราจึงสับระยะทางให้ไม่เกิน 12 studs ต่อเฟรม (ซึ่งก็ยังเร็วมาก = 720 studs/วินาที! เร็วกว่า Tween เก่า 5 เท่า)
    local maxSafeDistancePerFrame = 12 
    local chunks = math.ceil(distance / maxSafeDistancePerFrame)
    local startCFrame = hrp.CFrame
    
    -- แช่แข็งตัวละครไม่ให้ร่วงหรือปลิว
    local oldAnchored = hrp.Anchored
    hrp.Anchored = true
    
    for i = 1, chunks do
        hrp.CFrame = startCFrame:Lerp(targetCFrame, i / chunks)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        game:GetService("RunService").Heartbeat:Wait() -- ใช้ Heartbeat เพื่อความลื่นไหลสุดๆ
    end
    
    hrp.Anchored = oldAnchored
    task.wait(0.1)
end

local Window = loadstring(game:HttpGet("https://raw.githubusercontent.com/latavee1399-dev/AKO/refs/heads/main/CC%20ui"))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SeedsList = {"All"}
local GearsList = {"All"}
local PetsList = {"All"}
local AllItemsList = {"All"}

pcall(function()
    local SeedData = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("SeedData"))
    for _, v in pairs(SeedData) do
        if type(v) == "table" and v.SeedName then
            table.insert(SeedsList, v.SeedName)
        end
    end
end)

pcall(function()
    local GearData = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("GearShopData"))
    if GearData and GearData.Data then
        for _, v in pairs(GearData.Data) do
            if type(v) == "table" and v.ItemName then
                table.insert(GearsList, v.ItemName)
            end
        end
    end
end)

pcall(function()
    local PetModules = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("PetModules"))
    for k, _ in pairs(PetModules) do
        if type(k) == "string" then
            table.insert(PetsList, k)
        end
    end
end)

local PetRaritiesList = {"All"}
local PetSizesList = {"All"}

pcall(function()
    local PetData = require(ReplicatedStorage:WaitForChild("SharedData"):WaitForChild("PetData"))
    local found = {}
    for _, v in pairs(PetData) do
        if type(v) == "table" and v.Rarity and not found[v.Rarity] then
            found[v.Rarity] = true
            table.insert(PetRaritiesList, v.Rarity)
        end
    end
end)

pcall(function()
    local PetSizes = require(ReplicatedStorage:WaitForChild("SharedData"):WaitForChild("PetSizes"))
    for k, _ in pairs(PetSizes) do
        if type(k) == "string" then
            table.insert(PetSizesList, k)
        end
    end
end)

-- อัปเดต Mutations ใหม่ล่าสุดที่เจอจากการเจาะข้อมูลตัวเกม
local MutationList = {
    "All", "Normal", "Gold", "Rainbow", "Giant", "Huge", "Shiny",
    "Electric", "Aurora", "Bloodlit", "Starstruck", "Frozen"
}

for i = 2, #SeedsList do table.insert(AllItemsList, SeedsList[i]) end
for i = 2, #GearsList do table.insert(AllItemsList, GearsList[i]) end
for i = 2, #PetsList do table.insert(AllItemsList, PetsList[i]) end

-- 1. สร้าง Tab Main
local MainTab = Window:Tab({
    Title = "Plant",
    Desc = "Farming & Harvesting Features",
    Icon = "tractor",
})

-- 2. สร้าง Section Harvest ภายใน Tab Main
local HarvestSection = MainTab:Section({
    Title = "Harvest",
    Desc = "Auto harvest settings",
    Icon = "leaf",
})

-- (MutationList was moved to the top for global access)

-- ตัวแปรเก็บค่าปัจจุบันที่เลือก
local SelectedFruits = {"All"}
local SelectedRarities = {"All"}
local SelectedBuffs = {"All"}
local HarvestThresholdMode = "Harvest All"
local HarvestWeightThreshold = 0

local AutoHarvestEnabled = false
local AutoHarvestTask = nil

-- UI Components
local FruitDropdown = HarvestSection:Dropdown({
    Title = "Select Fruit",
    Desc = "Select fruits to target",
    Values = SeedsList,
    Value = {"All"},
    Multi = true,
    Flag = "selected_fruits",
    Callback = function(selected)
        SelectedFruits = selected
    end
})
_G.FruitDropdown = FruitDropdown

local RarityDropdown = HarvestSection:Dropdown({
    Title = "Select Rarity",
    Desc = "Select fruit rarity (if applicable)",
    Values = {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical"},
    Value = {"All"},
    Multi = true,
    Flag = "selected_rarities",
    Callback = function(selected)
        SelectedRarities = selected
    end
})

local MutationDropdown = HarvestSection:Dropdown({
    Title = "Select Mutation",
    Desc = "Select fruit mutations",
    Values = MutationList,
    Value = {"All"},
    Multi = true,
    Flag = "selected_buffs",
    Callback = function(selected)
        SelectedBuffs = selected
    end
})
_G.BuffDropdown = MutationDropdown

local ThresholdModeDropdown = HarvestSection:Dropdown({
    Title = "Select Threshold Mode",
    Desc = "Choose how to filter harvest by weight",
    Values = {"Harvest All", "Harvest < Weight", "Harvest > Weight"},
    Value = "Harvest All",
    Multi = false,
    Flag = "harvest_threshold_mode",
    Callback = function(val)
        HarvestThresholdMode = val
    end
})

local WeightThresholdInput = HarvestSection:Input({
    Title = "Weight Threshold (kg)",
    Desc = "Enter the weight threshold number",
    Placeholder = "e.g. 50",
    Numeric = true,
    Finished = false,
    Flag = "harvest_weight_threshold",
    Callback = function(val)
        local num = tonumber(val)
        if num then
            HarvestWeightThreshold = num
        end
    end
})

local HarvestToggle = HarvestSection:Toggle({
    Title = "Auto Harvest (ULTRA SPEED ⚡)",
    Desc = "Fastest & Lag-free Auto Harvest",
    Icon = "power",
    Value = false,
    Flag = "auto_harvest",
    Callback = function(state)
        AutoHarvestEnabled = state
        
        if AutoHarvestEnabled then
            local lp = game.Players.LocalPlayer
            local workspace = game:GetService("Workspace")
            local RunService = game:GetService("RunService")
            local gardens = workspace:FindFirstChild("Gardens")

            local targetFruits, hasAllFruits
            local targetRarities, hasAllRarities
            local targetBuffs, hasAllBuffs

            local function updateSelections()
                targetFruits = {}
                hasAllFruits = false
                if type(SelectedFruits) == "table" then
                    for k, v in pairs(SelectedFruits) do
                        local name = type(k) == "number" and v or k
                        if name == "All" and (v == true or type(k) == "number") then hasAllFruits = true break end
                        if v == true or type(k) == "number" then targetFruits[name] = true end
                    end
                end

                targetRarities = {}
                hasAllRarities = false
                if type(SelectedRarities) == "table" then
                    for k, v in pairs(SelectedRarities) do
                        local name = type(k) == "number" and v or k
                        if name == "All" and (v == true or type(k) == "number") then hasAllRarities = true break end
                        if v == true or type(k) == "number" then targetRarities[name] = true end
                    end
                end

                targetBuffs = {}
                hasAllBuffs = false
                if type(SelectedBuffs) == "table" then
                    for k, v in pairs(SelectedBuffs) do
                        local name = type(k) == "number" and v or k
                        if name == "All" and (v == true or type(k) == "number") then hasAllBuffs = true break end
                        if v == true or type(k) == "number" then targetBuffs[name] = true end
                    end
                end
            end

            updateSelections()
            local myPlotId = lp:GetAttribute("PlotId")
            local plotName = "Plot" .. tostring(myPlotId)

            AutoHarvestTask = RunService.Heartbeat:Connect(function()
                if not AutoHarvestEnabled then return end

                pcall(function()
                    if not myPlotId or not gardens then return end
                    local plot = gardens:FindFirstChild(plotName)
                    if not plot then return end
                    local plants = plot:FindFirstChild("Plants")
                    if not plants then return end

                    local plantsList = plants:GetChildren()
                    local totalPlants = #plantsList

                    local batchSize = 15
                    for i = 1, totalPlants, batchSize do
                        task.spawn(function()
                            for j = i, math.min(i + batchSize - 1, totalPlants) do
                                local plant = plantsList[j]
                                local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt", true)

                                if prompt and prompt.ActionText == "Harvest" and prompt.Enabled then
                                    -- Find the fruit part inside the plant to check its attributes
                                    local fruitPart = nil
                                    for _, child in ipairs(plant:GetDescendants()) do
                                        if child:GetAttribute("SizeMulti") or child:GetAttribute("Mutation") then
                                            fruitPart = child
                                            break
                                        end
                                    end

                                    local shouldHarvest = false
                                    
                                    if fruitPart then
                                        local fName = fruitPart:GetAttribute("FruitId") or plant:GetAttribute("SeedName") or "Unknown"
                                        local fRarity = fruitPart:GetAttribute("Rarity") or "Common"
                                        local fMutation = fruitPart:GetAttribute("Mutation") or "Normal"
                                        local fSize = fruitPart:GetAttribute("SizeMulti") or 0 -- SizeMulti acts as Weight reference
                                        
                                        local seedMatch = hasAllFruits or targetFruits[fName]
                                        local rarityMatch = hasAllRarities or targetRarities[fRarity]
                                        local mutationMatch = hasAllBuffs or targetBuffs[fMutation]
                                        
                                        local weightMatch = true
                                        if HarvestThresholdMode == "Harvest < Weight" then
                                            weightMatch = fSize < HarvestWeightThreshold
                                        elseif HarvestThresholdMode == "Harvest > Weight" then
                                            weightMatch = fSize > HarvestWeightThreshold
                                        end

                                        shouldHarvest = seedMatch and rarityMatch and mutationMatch and weightMatch
                                    else
                                        -- Fallback if fruit part not found yet (just check plant)
                                        local seedMatch = hasAllFruits or targetFruits[plant:GetAttribute("SeedName")]
                                        local mutationMatch = hasAllBuffs or targetBuffs[plant:GetAttribute("Mutation") or "Normal"]
                                        shouldHarvest = seedMatch and mutationMatch and (HarvestThresholdMode == "Harvest All" or HarvestWeightThreshold == 0)
                                    end

                                    if shouldHarvest then
                                        prompt.HoldDuration = 0
                                        fireproximityprompt(prompt)
                                    end
                                end
                            end
                        end)
                    end
                end)
            end)
        else
            if AutoHarvestTask then
                AutoHarvestTask:Disconnect()
                AutoHarvestTask = nil
            end
        end
    end
})

-- 3. สร้าง Section Auto Plant ภายใน Tab Main
local AutoPlantSection = MainTab:Section({
    Title = "Auto Plant",
    Desc = "Auto plant seeds from your inventory",
    Icon = "sprout",
})

local PlantMode = "Random"
local SelectedPlantSeeds = {"All"}
local AutoPlantEnabled = false
local AutoPlantTask = nil

local PlantSeedDropdown = AutoPlantSection:Dropdown({
    Title = "Select Seeds to Plant",
    Desc = "Choose which seeds to auto plant",
    Values = SeedsList,
    Value = {"All"},
    Multi = true,
    Flag = "auto_plant_seeds",
    Callback = function(selected)
        SelectedPlantSeeds = selected
    end
})
_G.PlantSeedDropdown = PlantSeedDropdown -- เผื่ออัพเดทรายชื่อเมล็ดใหม่

local PlantModeDropdown = AutoPlantSection:Dropdown({
    Title = "Planting Mode",
    Desc = "Choose how seeds are arranged",
    Values = {"Random", "Group By Type", "Saved Position"},
    Value = "Random",
    Multi = false,
    Flag = "auto_plant_mode",
    Callback = function(selected)
        PlantMode = selected
    end
})

local SavedPlantPosition = nil
local SavePositionButton = AutoPlantSection:Button({
    Title = "Save Position",
    Color = Color3.fromRGB(251, 196, 3),
    Desc = "Save your current character position for Planting Mode",
    Callback = function()
        pcall(function()
            local lp = game.Players.LocalPlayer
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                local pos = lp.Character.HumanoidRootPart.Position
                SavedPlantPosition = Vector3.new(pos.X, 0, pos.Z)
                WindUI:Notify({ Title = "Success", Content = "Saved position: " .. tostring(math.floor(pos.X)) .. ", " .. tostring(math.floor(pos.Z)), Duration = 3 })
            end
        end)
    end
})

local AutoPlantLastTick = 0

local AutoPlantToggle = AutoPlantSection:Toggle({
    Title = "Auto Plant",
    Desc = "Automatically plants seeds on empty slots",
    Icon = "leaf",
    Value = false,
    Flag = "auto_plant",
    Callback = function(state)
        AutoPlantEnabled = state
        
        if AutoPlantEnabled then
            local RunService = game:GetService("RunService")
            AutoPlantTask = RunService.Heartbeat:Connect(function()
                if not AutoPlantEnabled then
                    if AutoPlantTask then AutoPlantTask:Disconnect() end
                    return
                end
                
                -- หน่วงเวลา ปลูกทุกๆ 1 วินาที เพื่อไม่ให้เซิร์ฟเวอร์เตะ (Rate Limit)
                if tick() - AutoPlantLastTick < 1 then return end
                AutoPlantLastTick = tick()
                
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
                    local existingPlants = plantsFolder and plantsFolder:GetChildren() or {}
                    
                    -- เช็คเมล็ดในกระเป๋า (ใช้ Attribute SeedTool แบบใน UI ของแท้)
                    local invSeeds = {}
                    local function checkInv(parent)
                        for _, v in ipairs(parent:GetChildren()) do
                            if v:IsA("Tool") and v:GetAttribute("SeedTool") then
                                local seedName = v:GetAttribute("SeedTool")
                                if not invSeeds[seedName] then invSeeds[seedName] = {} end
                                table.insert(invSeeds[seedName], v)
                            end
                        end
                    end
                    if lp.Character then checkInv(lp.Character) end
                    if lp:FindFirstChild("Backpack") then checkInv(lp.Backpack) end
                    
                    -- เช็คเมล็ดที่ถูกเลือกใน UI
                    local targetSeeds = {}
                    local hasAll = false
                    if type(SelectedPlantSeeds) == "table" then
                        for k, v in pairs(SelectedPlantSeeds) do
                            local name = type(k) == "number" and v or k
                            if name == "All" and (v == true or type(k) == "number") then hasAll = true break end
                            if v == true or type(k) == "number" then targetSeeds[name] = true end
                        end
                    end
                    
                    local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
                    
                    -- ฟังก์ชันเช็คการชน (เว้นระยะห่าง 3.5 Studs เพื่อป้องกันบัคทับ)
                    local function isOccupied(tryPos)
                        for _, plant in ipairs(existingPlants) do
                            if plant:IsA("Model") and plant.PrimaryPart then
                                local pPos = plant.PrimaryPart.Position
                                if (Vector2.new(tryPos.X, tryPos.Z) - Vector2.new(pPos.X, pPos.Z)).Magnitude < 3.5 then
                                    return true
                                end
                            end
                        end
                        return false
                    end
                    
                    local function getRandomPosInArea(area)
                        local size = area.Size
                        local cf = area.CFrame
                        -- หักขอบออกนิดหน่อยเพื่อไม่ให้ชิดขอบแปลงเกินไป
                        local rx = (math.random() - 0.5) * math.max(1, size.X - 4)
                        local rz = (math.random() - 0.5) * math.max(1, size.Z - 4)
                        return cf * Vector3.new(rx, size.Y/2, rz)
                    end
                    
                    -- ลูปพยายามปลูกทีละเมล็ด
                    for seedName, tools in pairs(invSeeds) do
                        if hasAll or targetSeeds[seedName] then
                            for _, toolToPlant in ipairs(tools) do
                                local spot = nil
                                
                                -- แบบ Group By Type (หาเพื่อนต้นเดียวกันแล้วปลูกข้างๆ)
                                if PlantMode == "Group By Type" then
                                    for _, p in ipairs(existingPlants) do
                                        if p:GetAttribute("SeedName") == seedName and p.PrimaryPart then
                                            local pPos = p.PrimaryPart.Position
                                            local offsets = {Vector3.new(1.0,0,0), Vector3.new(-1.0,0,0), Vector3.new(0,0,1.0), Vector3.new(0,0,-1.0)}
                                            
                                            for _, offset in ipairs(offsets) do
                                                local testPos = pPos + offset
                                                local inArea = false
                                                local finalTryPos = nil
                                                
                                                -- ตรวจสอบว่าตำแหน่งนี้อยู่ใน PlantArea ไหนบ้าง
                                                for _, area in ipairs(plantAreas) do
                                                    local localPos = area.CFrame:PointToObjectSpace(testPos)
                                                    if math.abs(localPos.X) <= area.Size.X/2 and math.abs(localPos.Z) <= area.Size.Z/2 then
                                                        inArea = true
                                                        finalTryPos = area.CFrame * Vector3.new(localPos.X, area.Size.Y/2, localPos.Z)
                                                        break
                                                    end
                                                end
                                                
                                                if inArea and finalTryPos and not isOccupied(finalTryPos) then
                                                    spot = finalTryPos
                                                    break
                                                end
                                            end
                                        end
                                        if spot then break end
                                    end
                                end
                                
                                -- แบบ Saved Position (ปลูกซ้อนจุดเดียวกันทั้งหมดโดยใช้ Y-Offset Bypass)
                                if not spot and PlantMode == "Saved Position" and SavedPlantPosition then
                                    local testPos = SavedPlantPosition
                                    local finalTryPos = nil
                                    
                                    -- ปรับระดับ Y ให้ตรงกับแปลง (PlantArea) ถ้ายืนอยู่บนแปลง
                                    for _, area in ipairs(plantAreas) do
                                        local localPos = area.CFrame:PointToObjectSpace(testPos)
                                        if math.abs(localPos.X) <= area.Size.X/2 and math.abs(localPos.Z) <= area.Size.Z/2 then
                                            finalTryPos = area.CFrame * Vector3.new(localPos.X, area.Size.Y/2, localPos.Z)
                                            break
                                        end
                                    end
                                    
                                    -- คำนวณจำนวนต้นไม้ที่มีอยู่แล้วที่จุดนี้ เพื่อเพิ่มความสูง Y หลบระบบเช็คระยะห่างของเซิร์ฟเวอร์
                                    local stackCount = 0
                                    for _, p in ipairs(existingPlants) do
                                        if p.PrimaryPart then
                                            local dist = Vector2.new(p.PrimaryPart.Position.X, p.PrimaryPart.Position.Z) - Vector2.new(testPos.X, testPos.Z)
                                            if dist.Magnitude < 1 then
                                                stackCount = stackCount + 1
                                            end
                                        end
                                    end
                                    
                                    local baseSpot = finalTryPos or testPos
                                    
                                    -- แกน Y สลับขึ้นลงทีละ 3.55 studs เพื่อให้ต้นไม้ดูต่ำที่สุดเท่าที่จะทำได้
                                    local yOffset = math.ceil(stackCount / 2) * 3.55
                                    if stackCount % 2 == 0 and stackCount > 0 then
                                        yOffset = -yOffset
                                    end
                                    
                                    spot = baseSpot + Vector3.new(0, yOffset, 0)
                                end
                                
                                -- แบบ Random (หรือ Group/Saved หาที่ลงไม่ได้) ให้สุ่มลง PlantArea แบบใน ui.lua แท้ๆ
                                if not spot then
                                    for i = 1, 20 do
                                        local area = plantAreas[math.random(1, #plantAreas)]
                                        local tryPos = getRandomPosInArea(area)
                                        if not isOccupied(tryPos) then
                                            spot = tryPos
                                            break
                                        end
                                    end
                                end
                                
                                -- ถ้าหาจุดว่างได้ ทำการยิง Remote ปลูกทันที!
                                if spot then
                                    local seedId = toolToPlant:GetAttribute("SeedTool")
                                    Networking.Plant.PlantSeed:Fire(spot, seedId, toolToPlant)
                                    
                                    -- จำลองว่าตรงนี้มีต้นไม้แล้ว เผื่อลูปนี้ปลูกหลายต้นติดกัน จะได้ไม่ทับ
                                    local fakePlant = Instance.new("Model")
                                    local fakeBase = Instance.new("Part", fakePlant)
                                    fakeBase.Name = "PrimaryPart"
                                    fakeBase.Position = spot
                                    fakePlant.PrimaryPart = fakeBase
                                    fakePlant:SetAttribute("SeedName", seedName)
                                    table.insert(existingPlants, fakePlant)
                                    
                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                end)
            end)
        else
            if AutoPlantTask then
                AutoPlantTask:Disconnect()
                AutoPlantTask = nil
            end
        end
    end
})

-- 5. สร้าง Section Auto Water Trees ภายใน Tab Main
local AutoWaterSection = MainTab:Section({
    Title = "Auto Water Trees",
    Desc = "Automatically water your plants with the watering can",
    Icon = "droplets",
})

local SelectedWaterFruits = {"All"}
local WaterFruitDropdown = AutoWaterSection:Dropdown({
    Title = "Select Fruits to Water",
    Desc = "Which types of trees should be watered?",
    Values = SeedsList,
    Value = {"All"},
    Multi = true,
    Flag = "water_fruits",
    Callback = function(selected)
        SelectedWaterFruits = selected
    end
})

local SelectedWaterBuffs = {"All"}
local WaterBuffDropdown = AutoWaterSection:Dropdown({
    Title = "Select Buffs to Water",
    Desc = "Which mutations/buffs should be watered?",
    Values = {"All", "Normal", "Gold", "Rainbow", "Electric", "Bloodlit", "Frozen", "Chained", "Pizza", "Secret", "Starstruck", "Giant", "Shiny"},
    Value = {"All"},
    Multi = true,
    Flag = "water_buffs",
    Callback = function(selected)
        SelectedWaterBuffs = selected
    end
})

local WaterWeightMode = "All"
local WaterWeightDropdown = AutoWaterSection:Dropdown({
    Title = "Select Weight Priority",
    Desc = "Prioritize Heaviest/Lightest or water All",
    Values = {"All", "Heaviest", "Lightest"},
    Value = "All",
    Multi = false,
    Flag = "water_weight",
    Callback = function(v)
        WaterWeightMode = v
    end
})

local AutoWaterEnabled = false
local AutoWaterTask = nil
local wateredPlantsCooldown = {}

local function DoWaterTrees()
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
        
        local targetFruits = {}
        local hasAllFruits = false
        if type(SelectedWaterFruits) == "table" then
            for k, v in pairs(SelectedWaterFruits) do
                local name = type(k) == "number" and v or k
                if name == "All" and (v == true or type(k) == "number") then hasAllFruits = true break end
                if v == true or type(k) == "number" then targetFruits[name] = true end
            end
        end
        
        local targetBuffs = {}
        local hasAllBuffs = false
        if type(SelectedWaterBuffs) == "table" then
            for k, v in pairs(SelectedWaterBuffs) do
                local name = type(k) == "number" and v or k
                if name == "All" and (v == true or type(k) == "number") then hasAllBuffs = true break end
                if v == true or type(k) == "number" then targetBuffs[name] = true end
            end
        end
        
        local gardens = workspace:FindFirstChild("Gardens")
        if not gardens then return end
        local myPlotId = lp:GetAttribute("PlotId")
        local plot = myPlotId and gardens:FindFirstChild("Plot" .. tostring(myPlotId))
        if not plot then return end
        
        local plantsFolder = plot:FindFirstChild("Plants")
        if not plantsFolder then return end
        
        local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
        
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
        
        local function waterPlant(plant)
            local plantId = plant:GetAttribute("PlantId") or plant.Name
            local pp = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
            if not plantId or not pp or not tool then return end
            
            wateredPlantsCooldown[plantId] = os.clock()
            
            local oldCFrame = hrp.CFrame
            local targetCFrame = pp.CFrame + Vector3.new(0, 3, 0)
            AdvancedTP(hrp, targetCFrame)
            
            if tool.Parent ~= char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then hum:EquipTool(tool) end
                task.wait(0.2)
            end
            
            local targetId = plantId
            local fruitsFolder = plant:FindFirstChild("Fruits")
            if fruitsFolder then
                local firstFruit = fruitsFolder:GetChildren()[1]
                if firstFruit then
                    targetId = firstFruit:GetAttribute("FruitId") or firstFruit.Name
                end
            end
            
            pcall(function() tool:Activate() end)
            
            -- Reverting to the old way because the user confirmed Gag2 ui.lua works.
            pcall(function()
                Networking.WateringCan.UseWateringCan:Fire(pp.Position, tool.Name, tool)
            end)
            
            task.wait(0.2)
            
            AdvancedTP(hrp, oldCFrame)
        end
        
        local bestPlant = nil
        local bestVal = (WaterWeightMode == "Heaviest") and -math.huge or math.huge
        
        for _, plant in ipairs(plantsFolder:GetChildren()) do
            if shouldWater(plant) then
                if WaterWeightMode == "All" then
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
                    
                    if WaterWeightMode == "Heaviest" and maxPlantSize > bestVal then
                        bestVal = maxPlantSize
                        bestPlant = plant
                    elseif WaterWeightMode == "Lightest" and maxPlantSize < bestVal then
                        bestVal = maxPlantSize
                        bestPlant = plant
                    end
                end
            end
        end
        
        if bestPlant and WaterWeightMode ~= "All" then
            waterPlant(bestPlant)
        end
    end)
end

local AutoWaterToggle = AutoWaterSection:Toggle({
    Title = "Auto Watering",
    Desc = "Automatically equip watering can and water trees",
    Icon = "droplets",
    Value = false,
    Flag = "auto_water",
    Callback = function(state)
        AutoWaterEnabled = state
        if AutoWaterEnabled then
            AutoWaterTask = task.spawn(function()
                while AutoWaterEnabled do
                    DoWaterTrees()
                    task.wait(0.5)
                end
            end)
        else
            if AutoWaterTask then
                task.cancel(AutoWaterTask)
                AutoWaterTask = nil
            end
        end
    end
})

local WaterButton = AutoWaterSection:Button({
    Title = "Water Trees Now",
    Color = Color3.fromRGB(251, 196, 3),
    Desc = "Manually trigger the watering function once",
    Callback = function()
        task.spawn(DoWaterTrees)
    end
})

-- 6. สร้าง Section Auto Sprinkle Trees ภายใน Tab Main
local AutoSprinkleSection = MainTab:Section({
    Title = "Auto Sprinkle Trees",
    Desc = "Automatically place sprinklers next to your plants",
    Icon = "droplets",
})

local SelectedSprinklerTypes = {"All"}
local SprinklerTypeDropdown = AutoSprinkleSection:Dropdown({
    Title = "Select Sprinkler Type",
    Desc = "Which sprinklers do you want to use?",
    Values = {"All", "Common Sprinkler", "Gold Sprinkler", "Rainbow Sprinkler", "Electric Sprinkler", "Bloodlit Sprinkler", "Frozen Sprinkler", "Chained Sprinkler", "Pizza Sprinkler", "Secret Sprinkler", "Starstruck Sprinkler", "Giant Sprinkler", "Shiny Sprinkler"},
    Value = {"All"},
    Multi = true,
    Flag = "sprinkler_types",
    Callback = function(selected)
        SelectedSprinklerTypes = selected
    end
})

local SelectedSprinklerFruits = {"All"}
local SprinklerFruitDropdown = AutoSprinkleSection:Dropdown({
    Title = "Select Trees for Sprinkler",
    Desc = "Which types of trees should get sprinklers?",
    Values = SeedsList,
    Value = {"All"},
    Multi = true,
    Flag = "sprinkler_fruits",
    Callback = function(selected)
        SelectedSprinklerFruits = selected
    end
})

local SelectedSprinklerBuffs = {"All"}
local SprinklerBuffDropdown = AutoSprinkleSection:Dropdown({
    Title = "Select Tree Buffs for Sprinkler",
    Desc = "Which mutations/buffs should get sprinklers?",
    Values = {"All", "Normal", "Gold", "Rainbow", "Electric", "Bloodlit", "Frozen", "Chained", "Pizza", "Secret", "Starstruck", "Giant", "Shiny"},
    Value = {"All"},
    Multi = true,
    Flag = "sprinkler_buffs",
    Callback = function(selected)
        SelectedSprinklerBuffs = selected
    end
})

local SprinklerWeightMode = "All"
local SprinklerWeightDropdown = AutoSprinkleSection:Dropdown({
    Title = "Select Sprinkler Priority",
    Desc = "Prioritize Heaviest/Lightest or sprinkle All",
    Values = {"All", "Heaviest", "Lightest"},
    Value = "All",
    Multi = false,
    Flag = "sprinkler_weight",
    Callback = function(v)
        SprinklerWeightMode = v
    end
})

local AutoSprinklerEnabled = false
local AutoSprinklerTask = nil

local function DoPlaceSprinkler(placeOnlyOne)
    pcall(function()
        local lp = game.Players.LocalPlayer
        local char = lp.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local HttpService = game:GetService("HttpService")
        
        local tool = nil
        
        -- ตรวจสอบประเภท Sprinkler ที่เลือก
        local targetTypes = {}
        local hasAllTypes = false
        if type(SelectedSprinklerTypes) == "table" then
            for k, v in pairs(SelectedSprinklerTypes) do
                local name = type(k) == "number" and v or k
                if name == "All" and (v == true or type(k) == "number") then hasAllTypes = true break end
                if v == true or type(k) == "number" then targetTypes[name] = true end
            end
        end
        
        local function isCorrectSprinkler(t)
            if t:IsA("Tool") and string.find(t.Name, "Sprinkler") then
                if hasAllTypes or targetTypes[t.Name] then
                    return true
                end
            end
            return false
        end
        
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
        
        local targetFruits = {}
        local hasAllFruits = false
        if type(SelectedSprinklerFruits) == "table" then
            for k, v in pairs(SelectedSprinklerFruits) do
                local name = type(k) == "number" and v or k
                if name == "All" and (v == true or type(k) == "number") then hasAllFruits = true break end
                if v == true or type(k) == "number" then targetFruits[name] = true end
            end
        end
        
        local targetBuffs = {}
        local hasAllBuffs = false
        if type(SelectedSprinklerBuffs) == "table" then
            for k, v in pairs(SelectedSprinklerBuffs) do
                local name = type(k) == "number" and v or k
                if name == "All" and (v == true or type(k) == "number") then hasAllBuffs = true break end
                if v == true or type(k) == "number" then targetBuffs[name] = true end
            end
        end
        
        local gardens = workspace:FindFirstChild("Gardens")
        if not gardens then return end
        local myPlotId = lp:GetAttribute("PlotId")
        local plot = myPlotId and gardens:FindFirstChild("Plot" .. tostring(myPlotId))
        if not plot then return end
        
        local plantsFolder = plot:FindFirstChild("Plants")
        if not plantsFolder then return end
        local sprinklersFolder = plot:FindFirstChild("Sprinklers")
        
        local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
        
        local function shouldSprinkler(plant)
            local seedName = plant:GetAttribute("SeedName") or "Unknown"
            local mutation = plant:GetAttribute("Mutation") or "Normal"
            local fruitMatch = hasAllFruits or targetFruits[seedName]
            local buffMatch = hasAllBuffs or targetBuffs[mutation]
            return fruitMatch and buffMatch
        end
        
        local function placeSprinklerAt(plant)
            local plantId = plant:GetAttribute("PlantId") or plant.Name
            local pp = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
            if not plantId or not pp or not tool then return end
            
            local oldCFrame = hrp.CFrame
            local targetCFrame = pp.CFrame + Vector3.new(0, 3, 0)
            
            AdvancedTP(hrp, targetCFrame)
            
            if tool.Parent ~= char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then hum:EquipTool(tool) end
                task.wait(0.2)
            end
            
            local targetId = plantId
            local fruitsFolder = plant:FindFirstChild("Fruits")
            if fruitsFolder then
                local firstFruit = fruitsFolder:GetChildren()[1]
                if firstFruit then
                    targetId = firstFruit:GetAttribute("FruitId") or firstFruit.Name
                end
            end
            
            pcall(function() tool:Activate() end)
            
            -- ใช้ระบบดั้งเดิมของ Gag2 ui.lua (ที่มันใช้ได้!)
            pcall(function()
                Networking.Place.PlaceSprinkler:Fire(pp.Position + Vector3.new(1.5, 0, 1.5), tool.Name, tool, 1)
            end)
            
            task.wait(0.2)
            AdvancedTP(hrp, oldCFrame)
        end
        
        local bestPlant = nil
        local bestVal = (SprinklerWeightMode == "Heaviest") and -math.huge or math.huge
        
        for _, plant in ipairs(plantsFolder:GetChildren()) do
            if shouldSprinkler(plant) then
                local hasSprinkler = false
                if sprinklersFolder then
                    for _, s in ipairs(sprinklersFolder:GetChildren()) do
                        local spp = s.PrimaryPart or s:FindFirstChildWhichIsA("BasePart")
                        local pp = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
                        if spp and pp and (spp.Position - pp.Position).Magnitude <= 10 then
                            hasSprinkler = true
                            break
                        end
                    end
                end
                
                if not hasSprinkler then
                    if SprinklerWeightMode == "All" then
                        placeSprinklerAt(plant)
                        if placeOnlyOne then return end
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
                        
                        if SprinklerWeightMode == "Heaviest" and maxPlantSize > bestVal then
                            bestVal = maxPlantSize
                            bestPlant = plant
                        elseif SprinklerWeightMode == "Lightest" and maxPlantSize < bestVal then
                            bestVal = maxPlantSize
                            bestPlant = plant
                        end
                    end
                end
            end
        end
        
        if bestPlant and SprinklerWeightMode ~= "All" then
            placeSprinklerAt(bestPlant)
        end
    end)
end

local AutoSprinklerToggle = AutoSprinkleSection:Toggle({
    Title = "Auto Place Sprinklers",
    Desc = "Automatically equip and place sprinklers on valid trees",
    Icon = "settings",
    Value = false,
    Flag = "auto_sprinkle",
    Callback = function(state)
        AutoSprinklerEnabled = state
        if AutoSprinklerEnabled then
            AutoSprinklerTask = task.spawn(function()
                while AutoSprinklerEnabled do
                    DoPlaceSprinkler(false)
                    task.wait(1)
                end
            end)
        else
            if AutoSprinklerTask then
                task.cancel(AutoSprinklerTask)
                AutoSprinklerTask = nil
            end
        end
    end
})

local SprinkleButton = AutoSprinkleSection:Button({
    Title = "Place Sprinklers Now",
    Color = Color3.fromRGB(251, 196, 3),
    Desc = "Manually trigger the sprinkler placement once",
    Callback = function()
        task.spawn(function() DoPlaceSprinkler(true) end)
    end
})

-- ======================================================================
-- 7. Shop Tab
-- ======================================================================
local ShopTab = Window:Tab({
    Title = "Shop",
    Desc = "Auto Buy/Sell",
    Icon = "shopping-cart"
})

-- 7.1 Auto Buy Seeds
local AutoBuySeedSection = ShopTab:Section({
    Title = "Auto Buy Seeds",
    Desc = "Automatically buy seeds from the shop when in stock",
    Icon = "shopping-cart"
})

local SelectedBuySeeds = {}
local BuySeedDropdown = AutoBuySeedSection:Dropdown({
    Title = "Select Seeds to Buy",
    Desc = "Which seeds should be automatically bought?",
    Values = SeedsList,
    Value = {},
    Multi = true,
    Flag = "buy_seeds",
    Callback = function(selected)
        SelectedBuySeeds = selected
    end
})

local AutoBuySeedEnabled = false
local AutoBuySeedTask = nil

local function DoAutoBuySeeds()
    pcall(function()
        local lp = game.Players.LocalPlayer
        local pg = lp:FindFirstChild("PlayerGui")
        if not pg then return end
        local seedShop = pg:FindFirstChild("SeedShop")
        if not seedShop then return end
        local normalShop = seedShop:FindFirstChild("Frame") and seedShop.Frame:FindFirstChild("NormalShop")
        if not normalShop then return end
        
        local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
        
        local seedList = {"Apple", "Blueberry", "Strawberry", "Tomato", "Pineapple", "Pumpkin", "Watermelon", "Potato", "Carrot", "Onion", "Corn", "Wheat", "Radish", "Turnip", "Cabbage", "Lettuce", "Pepper", "Eggplant", "Mushroom", "Banana", "Grape", "Bamboo"}
        local isAll = false
        for k, v in pairs(SelectedBuySeeds) do
            local sn = type(k) == "number" and v or k
            if (v == true or type(k) == "number") and sn == "All" then
                isAll = true break
            end
        end
        
        local targetSeeds = {}
        if isAll then
            for _, v in ipairs(seedList) do targetSeeds[v] = true end
        else
            for k, v in pairs(SelectedBuySeeds) do
                local sn = type(k) == "number" and v or k
                if (v == true or type(k) == "number") and sn ~= "All" then targetSeeds[sn] = true end
            end
        end
        
        for seedName, _ in pairs(targetSeeds) do
            local itemFrame = normalShop:FindFirstChild(seedName)
            if itemFrame then
                local mainFrame = itemFrame:FindFirstChild("Main_Frame")
                local stockText = mainFrame and mainFrame:FindFirstChild("Stock_Text")
                if stockText then
                    local txt = stockText.Text
                    local numStr = string.match(txt, "x(%d+) in Stock")
                    if numStr and tonumber(numStr) > 0 then
                        Networking.SeedShop.PurchaseSeed:Fire(seedName)
                        task.wait(0.2)
                    end
                end
            end
        end
    end)
end

local AutoBuySeedToggle = AutoBuySeedSection:Toggle({
    Title = "Auto Buy Seeds",
    Desc = "Toggle automatic seed buying",
    Icon = "shopping-cart",
    Value = false,
    Flag = "auto_buy_seeds",
    Callback = function(state)
        AutoBuySeedEnabled = state
        if AutoBuySeedEnabled then
            AutoBuySeedTask = task.spawn(function()
                while AutoBuySeedEnabled do
                    DoAutoBuySeeds()
                    task.wait(1)
                end
            end)
        else
            if AutoBuySeedTask then
                task.cancel(AutoBuySeedTask)
                AutoBuySeedTask = nil
            end
        end
    end
})

-- 7.2 Auto Buy Gear
local AutoBuyGearSection = ShopTab:Section({
    Title = "Auto Buy Gear",
    Desc = "Automatically buy gear from the shop when in stock",
    Icon = "shopping-bag"
})

local SelectedBuyGear = {}
local BuyGearDropdown = AutoBuyGearSection:Dropdown({
    Title = "Select Gear to Buy",
    Desc = "Which gear should be automatically bought?",
    Values = {"All", "Common Watering Can", "Common Sprinkler", "Rare Sprinkler", "Legendary Sprinkler", "Uncommon Sprinkler", "Super Sprinkler", "Trowel", "Basic Pot", "Jump Mushroom", "Speed Mushroom", "Supersize Mushroom", "Shrink Mushroom", "Invisibility Mushroom", "Flashbang"},
    Value = {},
    Multi = true,
    Flag = "buy_gear",
    Callback = function(selected)
        SelectedBuyGear = selected
    end
})

local AutoBuyGearEnabled = false
local AutoBuyGearTask = nil

local function DoAutoBuyGear()
    pcall(function()
        local lp = game.Players.LocalPlayer
        local pg = lp:FindFirstChild("PlayerGui")
        if not pg then return end
        local gearShop = pg:FindFirstChild("GearShop")
        if not gearShop then return end
        local scrollFrame = gearShop:FindFirstChild("Frame") and gearShop.Frame:FindFirstChild("ScrollingFrame")
        if not scrollFrame then return end
        
        local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
        
        local gearList = {"Common Watering Can", "Common Sprinkler", "Rare Sprinkler", "Legendary Sprinkler", "Uncommon Sprinkler", "Super Sprinkler", "Trowel", "Basic Pot", "Jump Mushroom", "Speed Mushroom", "Supersize Mushroom", "Shrink Mushroom", "Invisibility Mushroom", "Flashbang"}
        local isAll = false
        for k, v in pairs(SelectedBuyGear) do
            local gn = type(k) == "number" and v or k
            if (v == true or type(k) == "number") and gn == "All" then
                isAll = true break
            end
        end
        
        local targetGear = {}
        if isAll then
            for _, v in ipairs(gearList) do targetGear[v] = true end
        else
            for k, v in pairs(SelectedBuyGear) do
                local gn = type(k) == "number" and v or k
                if (v == true or type(k) == "number") and gn ~= "All" then targetGear[gn] = true end
            end
        end
        
        for gearName, _ in pairs(targetGear) do
            local itemFrame = scrollFrame:FindFirstChild(gearName)
            if itemFrame then
                local mainFrame = itemFrame:FindFirstChild("Main_Frame")
                local stockText = mainFrame and mainFrame:FindFirstChild("Stock_Text")
                if stockText then
                    local txt = stockText.Text
                    local numStr = string.match(txt, "x(%d+) in Stock")
                    if numStr and tonumber(numStr) > 0 then
                        Networking.GearShop.PurchaseGear:Fire(gearName)
                        task.wait(0.2)
                    end
                end
            end
        end
    end)
end

local AutoBuyGearToggle = AutoBuyGearSection:Toggle({
    Title = "Auto Buy Gear",
    Desc = "Toggle automatic gear buying",
    Icon = "shopping-bag",
    Value = false,
    Flag = "auto_buy_gear",
    Callback = function(state)
        AutoBuyGearEnabled = state
        if AutoBuyGearEnabled then
            AutoBuyGearTask = task.spawn(function()
                while AutoBuyGearEnabled do
                    DoAutoBuyGear()
                    task.wait(1)
                end
            end)
        else
            if AutoBuyGearTask then
                task.cancel(AutoBuyGearTask)
                AutoBuyGearTask = nil
            end
        end
    end
})

-- 7.3 Auto Sell (Fruits & Pets)
-- 7.3 Auto Sell (Fruits & Pets)
local AutoSellSection = ShopTab:Section({
    Title = "Auto Sell",
    Desc = "Automatically sell fruits and pets in your inventory",
    Icon = "coins"
})

local SelectedSellFruits = {}
local SellFruitDropdown = AutoSellSection:Dropdown({
    Title = "Select Sell Fruit",
    Desc = "Which fruits should be sold automatically?",
    Values = SeedsList,
    Value = {},
    Multi = true,
    Flag = "sell_fruits",
    Callback = function(selected)
        SelectedSellFruits = selected
    end
})

local SelectedSellMutations = {}
local SellMutationDropdown = AutoSellSection:Dropdown({
    Title = "Select Sell Mutation",
    Desc = "Which mutations should be sold?",
    Values = MutationList,
    Value = {"All"},
    Multi = true,
    Flag = "sell_mutations",
    Callback = function(selected)
        SelectedSellMutations = selected
    end
})

local SellThresholdMode = "Sell All"
local SellThresholdDropdown = AutoSellSection:Dropdown({
    Title = "Select Threshold Mode",
    Desc = "Choose condition for selling fruits",
    Values = {"Sell All", "Sell > Weight Threshold", "Sell < Weight Threshold"},
    Value = "Sell All",
    Multi = false,
    Flag = "sell_threshold_mode",
    Callback = function(selected)
        SellThresholdMode = selected
    end
})

local SellWeightThreshold = 0
local SellWeightInput = AutoSellSection:Input({
    Title = "Weight Threshold",
    Desc = "if you don't want use this, just input '0'",
    Placeholder = "0",
    Callback = function(text)
        SellWeightThreshold = tonumber(text) or 0
    end
})

local AutoSellEnabled = false
local AutoSellTask = nil

local function checkMatch(selections, value)
    local hasAll = false
    local dict = {}
    for k, v in pairs(selections) do
        local n = type(k) == "number" and v or k
        if n == "All" and (v == true or type(k) == "number") then hasAll = true end
        if v == true or type(k) == "number" then dict[n] = true end
    end
    return hasAll or dict[value]
end

local function DoAutoSellFruits()
    pcall(function()
        local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
        local lp = game.Players.LocalPlayer
        
        local isAllFruits = checkMatch(SelectedSellFruits, "All")
        local isAllMutations = checkMatch(SelectedSellMutations, "All")
        
        -- ถ้าไม่มี Filter พิเศษ ให้ใช้ SellAll แบบเร็ว
        if isAllFruits and isAllMutations and SellThresholdMode == "Sell All" then
            Networking.NPCS.SellAll:Fire()
            return
        end
        
        local function scanAndSell(parent)
            for _, tool in ipairs(parent:GetChildren()) do
                if tool:IsA("Tool") then
                    local fName = tool:GetAttribute("FruitName") or tool:GetAttribute("Fruit") or tool.Name
                    local mutation = tool:GetAttribute("Mutation") or "Normal"
                    local weight = tool:GetAttribute("Weight") or 0
                    local fruitId = tool:GetAttribute("Id") or tool:GetAttribute("FruitId")
                    
                    if fruitId and (isAllFruits or checkMatch(SelectedSellFruits, fName)) then
                        if checkMatch(SelectedSellMutations, mutation) then
                            local passWeight = true
                            if SellThresholdMode == "Sell > Weight Threshold" and weight <= SellWeightThreshold then passWeight = false end
                            if SellThresholdMode == "Sell < Weight Threshold" and weight >= SellWeightThreshold then passWeight = false end
                            
                            if passWeight then
                                Networking.NPCS.SellFruit:Fire(tool.Name, tool)
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end
        end
        
        if lp:FindFirstChild("Backpack") then scanAndSell(lp.Backpack) end
        if lp.Character then scanAndSell(lp.Character) end
    end)
end

local AutoSellToggle = AutoSellSection:Toggle({
    Title = "Auto Sell Fruits",
    Desc = "Toggle automatic fruit selling",
    Icon = "coins",
    Value = false,
    Flag = "auto_sell_fruits",
    Callback = function(state)
        AutoSellEnabled = state
        if AutoSellEnabled then
            AutoSellTask = task.spawn(function()
                while AutoSellEnabled do
                    DoAutoSellFruits()
                    task.wait(2)
                end
            end)
        else
            if AutoSellTask then
                task.cancel(AutoSellTask)
                AutoSellTask = nil
            end
        end
    end
})

local AutoSellWhenFullEnabled = false
local AutoSellWhenFullTask = nil
local AutoSellWhenFullToggle = AutoSellSection:Toggle({
    Title = "Auto Sell When Full",
    Desc = "Automatically sell fruits only when your backpack capacity is reached",
    Icon = "package",
    Value = false,
    Flag = "auto_sell_when_full",
    Callback = function(state)
        AutoSellWhenFullEnabled = state
        if AutoSellWhenFullEnabled then
            AutoSellWhenFullTask = task.spawn(function()
                local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
                local lp = game.Players.LocalPlayer
                
                while AutoSellWhenFullEnabled do
                    pcall(function()
                        local current = lp:GetAttribute("FruitCount") or 0
                        local max = lp:GetAttribute("MaxFruitCapacity") or 100
                        
                        if current >= max then
                            Networking.NPCS.SellAll:Fire()
                            task.wait(0.5)
                        end
                    end)
                    task.wait(0.05)
                end
            end)
        else
            if AutoSellWhenFullTask then
                task.cancel(AutoSellWhenFullTask)
                AutoSellWhenFullTask = nil
            end
        end
    end
})

local SelectedPets = {}
local SellPetsDropdown = AutoSellSection:Dropdown({
    Title = "Select Pets",
    Desc = "Which pets should be sold?",
    Values = PetsList,
    Value = {"All"},
    Multi = true,
    Flag = "sell_pets",
    Callback = function(selected)
        SelectedPets = selected
    end
})

local SelectedRarityPets = {}
local SellPetsRarityDropdown = AutoSellSection:Dropdown({
    Title = "Select Rarity Pets",
    Desc = "Which pet rarities to sell?",
    Values = PetRaritiesList,
    Value = {"All"},
    Multi = true,
    Flag = "sell_pets_rarity",
    Callback = function(selected)
        SelectedRarityPets = selected
    end
})

local SelectedSizePets = {}
local SellPetsSizeDropdown = AutoSellSection:Dropdown({
    Title = "Select Size Pets",
    Desc = "Which pet sizes to sell?",
    Values = PetSizesList,
    Value = {"All"},
    Multi = true,
    Flag = "sell_pets_size",
    Callback = function(selected)
        SelectedSizePets = selected
    end
})

local AutoSellPetEnabled = false
local AutoSellPetTask = nil

local function DoAutoSellPets()
    pcall(function()
        local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
        local lp = game.Players.LocalPlayer
        
        local function scanAndSellPet(parent)
            for _, tool in ipairs(parent:GetChildren()) do
                local isPet = (tool:IsA("Tool") or tool:IsA("Model")) and (tool:GetAttribute("PetId") or tool:GetAttribute("PetName"))
                if isPet then
                    local pName = tool:GetAttribute("PetName") or tool.Name
                    local pRarity = tool:GetAttribute("Rarity") or "Common"
                    local pSize = tool:GetAttribute("Size") or "Normal"
                    
                    if checkMatch(SelectedPets, pName) and checkMatch(SelectedRarityPets, pRarity) and checkMatch(SelectedSizePets, pSize) then
                        Networking.NPCS.SellPet:Fire(tool.Name, tool)
                        task.wait(0.5) -- Delay 0.5s per pet
                    end
                end
            end
        end
        
        if lp:FindFirstChild("Backpack") then scanAndSellPet(lp.Backpack) end
        if lp.Character then scanAndSellPet(lp.Character) end
    end)
end

local AutoSellPetToggle = AutoSellSection:Toggle({
    Title = "Auto Sell Pets",
    Desc = "Automatically sell filtered pets (One by one)",
    Icon = "cat",
    Value = false,
    Flag = "auto_sell_pets",
    Callback = function(state)
        AutoSellPetEnabled = state
        if AutoSellPetEnabled then
            AutoSellPetTask = task.spawn(function()
                while AutoSellPetEnabled do
                    DoAutoSellPets()
                    task.wait(2)
                end
            end)
        else
            if AutoSellPetTask then
                task.cancel(AutoSellPetTask)
                AutoSellPetTask = nil
            end
        end
    end
})

-- 7.4 Auto Buy Auction
local AutoBuyAuctionSection = ShopTab:Section({
    Title = "Auto Buy Auction",
    Desc = "Automatically buy items from the Auction",
    Icon = "gavel"
})

local SelectedAuctionItems = {"All"}
local AuctionDropdown = AutoBuyAuctionSection:Dropdown({
    Title = "Select Items to Buy",
    Desc = "Items will update automatically based on current auction.",
    Values = {"All"},
    Value = {"All"},
    Multi = true,
    Flag = "buy_auction_items",
    Callback = function(selected)
        SelectedAuctionItems = selected
    end
})

local AutoBuyAuctionEnabled = false
local AutoBuyAuctionTask = nil
local AuctionUpdateTask = nil

local LastAuctionItems = {}

-- ฟังก์ชันอัปเดต Dropdown (แยกออกมาเพื่อให้ปุ่ม Refresh เรียกใช้ได้)
local function UpdateAuctionDropdown()
    pcall(function()
        local lp = game.Players.LocalPlayer
        local pg = lp:FindFirstChild("PlayerGui")
        if not pg then return end

        local currentItems = {"All"}
        local foundItems = {}

        -- ดึงข้อมูลจาก Auction GUI โดยตรง
        local auctionGui = pg:FindFirstChild("Auction")
        if auctionGui then
            local scrollingFrame = auctionGui:FindFirstChild("Frame")
                and auctionGui.Frame:FindFirstChild("ScrollingFrame")

            if scrollingFrame then
                for _, lot in ipairs(scrollingFrame:GetChildren()) do
                    if string.find(lot.Name, "Lot_auction") then
                        local itemNameLabel = lot:FindFirstChild("ItemName", true)

                        if itemNameLabel and itemNameLabel.Text then
                            local itemName = itemNameLabel.Text

                            -- เพิ่มเฉพาะไอเทมที่ยังไม่ซ้ำ
                            if not foundItems[itemName] then
                                foundItems[itemName] = true
                                table.insert(currentItems, itemName)
                            end
                        end
                    end
                end
            end
        end

        -- ตรวจสอบว่ารายการมีการเปลี่ยนแปลงหรือไม่
        local isDifferent = false
        if #currentItems ~= #LastAuctionItems then
            isDifferent = true
        else
            for i, v in ipairs(currentItems) do
                if v ~= LastAuctionItems[i] then
                    isDifferent = true
                    break
                end
            end
        end

        -- อัปเดต Dropdown ถ้ามีการเปลี่ยนแปลง
        if isDifferent then
            LastAuctionItems = currentItems
            if #currentItems > 1 then
                AuctionDropdown:Refresh(currentItems, true)
            end
        end
    end)
end

-- ปุ่ม Refresh สำหรับอัปเดท Dropdown ทันที
local RefreshAuctionButton = AutoBuyAuctionSection:Button({
    Title = "Refresh Auction Items",
    Color = Color3.fromRGB(251, 196, 3),
    Desc = "Manually update the dropdown with current auction items",
    Callback = function()
        UpdateAuctionDropdown()
    end
})

-- Task to update Dropdown items automatically from Auction GUI
AuctionUpdateTask = task.spawn(function()
    while task.wait(600) do -- อัปเดททุก 10 นาที (600 วินาที)
        UpdateAuctionDropdown()
    end
end)


local AutoBuyAuctionToggle = AutoBuyAuctionSection:Toggle({
    Title = "Auto Buy Auction",
    Desc = "Toggle automatic purchasing from auction",
    Icon = "gavel",
    Value = false,
    Flag = "auto_buy_auction",
    Callback = function(state)
        AutoBuyAuctionEnabled = state
        if AutoBuyAuctionEnabled then
            AutoBuyAuctionTask = task.spawn(function()
                local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
                while AutoBuyAuctionEnabled do
                    pcall(function()
                        local auctionGui = PlayerGui:FindFirstChild("Auction")
                        if auctionGui then
                            local scrollingFrame = auctionGui:FindFirstChild("Frame") and auctionGui.Frame:FindFirstChild("ScrollingFrame")
                            if scrollingFrame then
                                for _, lot in ipairs(scrollingFrame:GetChildren()) do
                                    if string.find(lot.Name, "Lot_auction") then
                                        local itemNameLabel = lot:FindFirstChild("ItemName", true)
                                        local stockLabel = lot:FindFirstChild("Stock_Text", true)
                                        local buyBtn = lot:FindFirstChild("BuyButton", true)
                                        
                                        if itemNameLabel and stockLabel and buyBtn then
                                            local name = itemNameLabel.Text
                                            local stockText = stockLabel.Text
                                            
                                            -- Check if item is selected
                                            local isSelected = false
                                            for _, selectedName in ipairs(SelectedAuctionItems) do
                                                if selectedName == "All" or selectedName == name then
                                                    isSelected = true
                                                    break
                                                end
                                            end
                                            
                                            if isSelected then
                                                -- Check if in stock
                                                if not string.find(string.lower(stockText), "out of stock") and not string.find(string.lower(stockText), "expired") then
                                                    -- Simulate click
                                                    local conns = getconnections(buyBtn.Activated)
                                                    if conns and conns[1] then
                                                        conns[1].Function()
                                                        task.wait(0.5) -- delay between buys to prevent lag/spam
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(1)
                end
            end)
        else
            if AutoBuyAuctionTask then
                task.cancel(AutoBuyAuctionTask)
                AutoBuyAuctionTask = nil
            end
        end
    end
})


-- 8. สร้าง Tab Trade
local TradeTab = Window:Tab({
    Title = "Trade",
    Desc = "Trading & Gifting op Drop Features",
    Icon = "gift"
})

-- 8.1 Auto Send Mail
local AutoMailSection = TradeTab:Section({
    Title = "Auto Send Mail",
    Desc = "Send items via Mailbox",
    Icon = "mail"
})

local MailTargetPlayer = ""
local MailTargetInput = AutoMailSection:Input({
    Title = "Target Player Name",
    Desc = "Enter the username of the player to send to",
    Placeholder = "Username...",
    Callback = function(text)
        MailTargetPlayer = text
    end
})

local MailSendAmount = 0
local MailAmountInput = AutoMailSection:Input({
    Title = "Send Amount (0 = All)",
    Desc = "Amount of each item to send",
    Placeholder = "0",
    Callback = function(text)
        MailSendAmount = tonumber(text) or 0
    end
})

local MailMaxWeight = 0
local MailMaxWeightInput = AutoMailSection:Input({
    Title = "Max Fruit Weight (kg)",
    Desc = "Send fruits ONLY IF weight is LESS than this value (0 = Send All)",
    Placeholder = "0",
    Callback = function(text)
        MailMaxWeight = tonumber(text) or 0
    end
})

local SelectedMailSeeds = {}
local MailSeedsDropdown = AutoMailSection:Dropdown({
    Title = "Select Seeds to Send",
    Desc = "Which seeds should be sent?",
    Values = SeedsList,
    Value = {},
    Multi = true,
    Flag = "mail_seeds",
    Callback = function(selected)
        SelectedMailSeeds = selected
    end
})

local SelectedMailFruits = {}
local MailFruitsDropdown = AutoMailSection:Dropdown({
    Title = "Select Fruits to Send",
    Desc = "Which harvested fruits should be sent?",
    Values = SeedsList,
    Value = {},
    Multi = true,
    Flag = "mail_fruits",
    Callback = function(selected)
        SelectedMailFruits = selected
    end
})

local SelectedMailGears = {}
local MailGearsDropdown = AutoMailSection:Dropdown({
    Title = "Select Gears to Send",
    Desc = "Which gears should be sent?",
    Values = GearsList,
    Value = {},
    Multi = true,
    Flag = "mail_gears",
    Callback = function(selected)
        SelectedMailGears = selected
    end
})

local SelectedMailPets = {}
local MailPetsDropdown = AutoMailSection:Dropdown({
    Title = "Select Pets to Send",
    Desc = "Which pets should be sent?",
    Values = PetsList,
    Value = {},
    Multi = true,
    Flag = "mail_pets",
    Callback = function(selected)
        SelectedMailPets = selected
    end
})

local AutoMailEnabled = false
local AutoMailTask = nil
local TargetUserIdCache = {}

local function DoAutoMail()
    local targetName = MailTargetPlayer
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
            local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
            local PlayerStateClient = require(game:GetService("ReplicatedStorage").ClientModules.PlayerStateClient)
            local inventory = PlayerStateClient.GetLocalReplica().Data.Inventory
            local lp = game.Players.LocalPlayer

            -- สร้าง dictionary สำหรับเช็คว่าเลือกอะไรบ้าง
            local isAllSeeds = false
            local seedsDict = {}
            for _, v in ipairs(SelectedMailSeeds) do
                if v == "All" then isAllSeeds = true end
                seedsDict[v] = true
            end

            local isAllGears = false
            local gearsDict = {}
            for _, v in ipairs(SelectedMailGears) do
                if v == "All" then isAllGears = true end
                gearsDict[v] = true
            end

            local isAllPets = false
            local petsDict = {}
            for _, v in ipairs(SelectedMailPets) do
                if v == "All" then isAllPets = true end
                petsDict[v] = true
            end

            local isAllFruits = false
            local fruitsDict = {}
            for _, v in ipairs(SelectedMailFruits) do
                if v == "All" then isAllFruits = true end
                fruitsDict[v] = true
            end

            -- ตัวนับจำนวนที่ส่งไปแล้วของแต่ละชนิด
            local sentTracker = {}

            -- เก็บรายการสิ่งของที่จะส่งทั้งหมด
            local itemsToSend = {}

            -- 1. ส่งจาก Inventory (Seeds, Gears, Pets)
            for category, categoryItems in pairs(inventory) do
                if category ~= "HarvestedFruits" and type(categoryItems) == "table" then
                    for itemKey, itemData in pairs(categoryItems) do
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
                                if MailSendAmount > 0 then
                                    local sent = sentTracker[itemKey] or 0
                                    if sent >= MailSendAmount then
                                        shouldSend = false
                                    else
                                        finalCount = math.min(count, MailSendAmount - sent)
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

            -- 2. ส่งผลไม้จากกระเป๋า/ตัวละคร (HarvestedFruits)
            -- เก็บรายการผลไม้ทั้งหมดจากทุกที่ก่อน
            local fruitToolsList = {}

            -- 2.1 เช็คจาก Backpack
            local backpack = lp:FindFirstChild("Backpack")
            if backpack then
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        -- ลองหา Attribute หลายแบบ
                        local fname = tool:GetAttribute("FruitName") or tool:GetAttribute("Fruit") or tool.Name
                        local fruitId = tool:GetAttribute("Id") or tool:GetAttribute("FruitId")
                        local weight = tool:GetAttribute("Weight") or 0

                        -- ตรวจสอบว่าเป็นผลไม้จริงๆ (มี Id และชื่ออยู่ใน SeedsList หรือเลือก All)
                        if fruitId and fname and (isAllFruits or fruitsDict[fname]) then
                            if MailMaxWeight == 0 or weight < MailMaxWeight then
                                if not fruitToolsList[fname] then
                                    fruitToolsList[fname] = {}
                                end
                                table.insert(fruitToolsList[fname], fruitId)
                            end
                        end
                    end
                end
            end

            -- 2.2 เช็คจาก Character (ที่อยู่ในมือ)
            if lp.Character then
                for _, tool in ipairs(lp.Character:GetChildren()) do
                    if tool:IsA("Tool") then
                        local fname = tool:GetAttribute("FruitName") or tool:GetAttribute("Fruit") or tool.Name
                        local fruitId = tool:GetAttribute("Id") or tool:GetAttribute("FruitId")
                        local weight = tool:GetAttribute("Weight") or 0

                        if fruitId and fname and (isAllFruits or fruitsDict[fname]) then
                            if MailMaxWeight == 0 or weight < MailMaxWeight then
                                if not fruitToolsList[fname] then
                                    fruitToolsList[fname] = {}
                                end
                                table.insert(fruitToolsList[fname], fruitId)
                            end
                        end
                    end
                end
            end

            -- 2.3 เพิ่มผลไม้ลงในรายการส่ง โดยคำนึงถึง MailSendAmount
            for fruitName, fruitIds in pairs(fruitToolsList) do
                local totalAvailable = #fruitIds
                local amountToSend = totalAvailable

                -- ถ้ากำหนดจำนวนส่ง ให้ส่งแค่ที่กำหนด
                if MailSendAmount > 0 then
                    local alreadySent = sentTracker[fruitName] or 0
                    if alreadySent >= MailSendAmount then
                        amountToSend = 0 -- ส่งครบแล้ว
                    else
                        amountToSend = math.min(totalAvailable, MailSendAmount - alreadySent)
                        sentTracker[fruitName] = alreadySent + amountToSend
                    end
                end

                -- ส่งผลไม้ทีละชิ้น
                for i = 1, amountToSend do
                    table.insert(itemsToSend, {
                        Category = "HarvestedFruits",
                        ItemKey = fruitIds[i],
                        Count = 1
                    })
                end
            end

            -- 4. ส่ง Mail ในชุดละ 100 ชิ้น
            if #itemsToSend > 0 then
                local batch = {}
                for _, item in ipairs(itemsToSend) do
                    table.insert(batch, item)
                    if #batch >= 100 then
                        pcall(function()
                            Networking.Mailbox.SendBatch:Fire(targetUserId, batch, "Gift")
                        end)
                        task.wait(2)
                        batch = {}
                    end
                end
                -- ส่งส่วนที่เหลือ
                if #batch > 0 then
                    pcall(function()
                        Networking.Mailbox.SendBatch:Fire(targetUserId, batch, "Gift")
                    end)
                    task.wait(2)
                end
            end
        end
    end
end

local SendMailButton = AutoMailSection:Button({
    Title = "Send Mail Now (Once)",
    Color = Color3.fromRGB(251, 196, 3),
    Desc = "Send the selected items immediately in one click",
    Callback = function()
        task.spawn(DoAutoMail)
    end
})

local AutoMailToggle = AutoMailSection:Toggle({
    Title = "Auto Send Mail",
    Desc = "Toggle automatic mail sending",
    Icon = "mail",
    Value = false,
    Flag = "auto_send_mail",
    Callback = function(state)
        AutoMailEnabled = state
        if AutoMailEnabled then
            AutoMailTask = task.spawn(function()
                while AutoMailEnabled do
                    pcall(function() DoAutoMail() end)
                    task.wait(2)
                end
            end)
        else
            if AutoMailTask then
                task.cancel(AutoMailTask)
                AutoMailTask = nil
            end
        end
    end
})

-- 8.2 Auto Gift
local AutoGiftSection = TradeTab:Section({
    Title = "Auto Gift",
    Desc = "Send gifts to players",
    Icon = "gift"
})

local GiftTargetPlayer = ""
local GiftTargetInput = AutoGiftSection:Input({
    Title = "Target Player Name",
    Desc = "Enter the username of the player to gift to",
    Placeholder = "Username...",
    Callback = function(text)
        GiftTargetPlayer = text
    end
})

local SelectedGiftSeeds = {}
local GiftSeedsDropdown = AutoGiftSection:Dropdown({
    Title = "Select Seeds/Fruits to Gift",
    Desc = "Which seeds or fruits should be gifted?",
    Values = SeedsList,
    Value = {},
    Multi = true,
    Flag = "gift_seeds",
    Callback = function(selected)
        SelectedGiftSeeds = selected
    end
})

local SelectedGiftGears = {}
local GiftGearsDropdown = AutoGiftSection:Dropdown({
    Title = "Select Gears to Gift",
    Desc = "Which gears should be gifted?",
    Values = GearsList,
    Value = {},
    Multi = true,
    Flag = "gift_gears",
    Callback = function(selected)
        SelectedGiftGears = selected
    end
})

local SelectedGiftPets = {}
local GiftPetsDropdown = AutoGiftSection:Dropdown({
    Title = "Select Pets to Gift",
    Desc = "Which pets should be gifted?",
    Values = PetsList,
    Value = {},
    Multi = true,
    Flag = "gift_pets",
    Callback = function(selected)
        SelectedGiftPets = selected
    end
})

local AutoGiftEnabled = false
local AutoGiftTask = nil

local function DoAutoGift()
    local targetName = GiftTargetPlayer
    if not targetName or targetName == "" then return end
    
    local targetUserId = TargetUserIdCache[targetName]
    if not targetUserId then
        local s, r = pcall(function()
            return game.Players:GetUserIdFromNameAsync(targetName)
        end)
        if s and r then
            targetUserId = r
            TargetUserIdCache[targetName] = r
        else
            return
        end
    end
    
    if targetUserId then
        local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
        local PlayerStateClient = require(game:GetService("ReplicatedStorage").ClientModules.PlayerStateClient)
        local inventory = PlayerStateClient.GetLocalReplica().Data.Inventory
        
        local isAllSeeds = false
        local seedsDict = {}
        for _, v in ipairs(SelectedGiftSeeds) do
            if v == "All" then isAllSeeds = true end
            seedsDict[v] = true
        end
        
        local isAllGears = false
        local gearsDict = {}
        for _, v in ipairs(SelectedGiftGears) do
            if v == "All" then isAllGears = true end
            gearsDict[v] = true
        end
        
        local isAllPets = false
        local petsDict = {}
        for _, v in ipairs(SelectedGiftPets) do
            if v == "All" then isAllPets = true end
            petsDict[v] = true
        end
        
        local batch = {}
        for category, categoryItems in pairs(inventory) do
            if type(categoryItems) == "table" and category ~= "HarvestedFruits" then
                for itemKey, itemData in pairs(categoryItems) do
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
                            table.insert(batch, {Category = category, ItemKey = itemKey, Count = count})
                        end
                    end
                end
            end
        end
        
        -- HarvestedFruits logic (tools in backpack/character)
        for _, folder in ipairs({game.Players.LocalPlayer:FindFirstChild("Backpack"), game.Players.LocalPlayer.Character}) do
            if folder then
                for _, tool in ipairs(folder:GetChildren()) do
                    if tool:IsA("Tool") then
                        local fname = tool:GetAttribute("FruitName")
                        if fname and (isAllSeeds or seedsDict[fname]) then
                            local fruitId = tool:GetAttribute("Id") or fname
                            table.insert(batch, {Category = "HarvestedFruits", ItemKey = fruitId, Count = 1})
                        end
                    end
                end
            end
        end
        
        if #batch > 0 then
            -- TURBO SENDING (From Gag2 ui.lua)
            for i = 1, #batch, 10 do
                local sub = {}
                for j = i, math.min(i + 9, #batch) do
                    table.insert(sub, batch[j])
                end
                
                task.spawn(function()
                    pcall(function()
                        Networking.Mailbox.SendBatch:Fire(targetUserId, sub, "Gift")
                    end)
                end)
                
                task.wait(0.15)
            end
        end
    end
end

local SendGiftButton = AutoGiftSection:Button({
    Title = "Send Gift Now (TURBO)",
    Color = Color3.fromRGB(251, 196, 3),
    Desc = "Ultra fast: 10 items/batch, 0.15s delay",
    Callback = function()
        task.spawn(DoAutoGift)
    end
})

local AutoGiftToggle = AutoGiftSection:Toggle({
    Title = "Auto Gift",
    Desc = "Toggle automatic gifting",
    Icon = "gift",
    Value = false,
    Flag = "auto_gift",
    Callback = function(state)
        AutoGiftEnabled = state
        if AutoGiftEnabled then
            AutoGiftTask = task.spawn(function()
                while AutoGiftEnabled do
                    pcall(function() DoAutoGift() end)
                    task.wait(2)
                end
            end)
        else
            if AutoGiftTask then
                task.cancel(AutoGiftTask)
                AutoGiftTask = nil
            end
        end
    end
})

local GameTab = Window:Tab({
    Title = "Game",
    Desc = "Game systems and general settings",
    Icon = "gamepad-2", -- Changed to standard icon name, or can use "rbxassetid://..." if preferred
})

local EventSection = GameTab:Section({
    Title = "Event Game",
    Desc = "Game Event features",
    Icon = "calendar", -- Changed to standard icon name
})

-- TODO: Add buttons, toggles, or sliders for System Game here

local AutoPickEventEnabled = false
local AutoPickEventTask = nil

local AutoPickEventToggle = EventSection:Toggle({
    Title = "Auto Pick Event (Rainbow/Gold)",
    Desc = "Checks for active server events and Auto Chunk-TP to collect dropped Rainbow/Gold seeds.",
    Value = false,
    Icon = "power",
    Flag = "auto_pick_event",
    Callback = function(state)
        AutoPickEventEnabled = state
        if AutoPickEventEnabled then
            AutoPickEventTask = task.spawn(function()
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                local Workspace = game:GetService("Workspace")
                local lp = game.Players.LocalPlayer
                
                while AutoPickEventEnabled do
                    pcall(function()
                        local weatherValues = ReplicatedStorage:FindFirstChild("WeatherValues")
                        local isEventActive = false
                        
                        -- เช็คว่า Event กำลังมาหรือไม่ (เช็คโฟลเดอร์ WeatherValues)
                        if weatherValues then
                            for _, event in ipairs(weatherValues:GetChildren()) do
                                local playing = event:FindFirstChild("Playing")
                                if playing and playing.Value == true then
                                    isEventActive = true
                                    break
                                end
                            end
                        end
                        
                        -- หรือเช็คจาก DroppedItems โดยตรงเผื่อว่า Event จบแล้วแต่เมล็ดตกพื้นอยู่
                        local droppedItemsFolder = Workspace:FindFirstChild("DroppedItems")
                        if droppedItemsFolder then
                            for _, item in ipairs(droppedItemsFolder:GetChildren()) do
                                local name = item.Name:lower()
                                if string.find(name, "rainbow") or string.find(name, "gold") or string.find(name, "meteor") then
                                    isEventActive = true
                                    break
                                end
                            end
                        end
                        
                        -- ถ้า Event กำลังมา หรือมีเมล็ดดรอปที่พื้น
                        if isEventActive and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                            local hrp = lp.Character.HumanoidRootPart
                            
                            -- วนหาไอเทมเพื่อเก็บ
                            if droppedItemsFolder then
                                for _, item in ipairs(droppedItemsFolder:GetChildren()) do
                                    if not AutoPickEventEnabled then break end -- หยุดถ้าผู้เล่นปิดปุ่ม
                                    
                                    local name = item.Name:lower()
                                    if string.find(name, "rainbow") or string.find(name, "gold") or string.find(name, "meteor") then
                                        local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
                                        
                                        -- ถ้าเจอปุ่มเก็บ
                                        if prompt and prompt.Enabled then
                                            -- ลูปทำจนกว่าจะเก็บสำเร็จ (ชิ้นนั้นหายไปหรือกดเก็บสำเร็จ)
                                            while AutoPickEventEnabled and item.Parent and prompt.Enabled do
                                                local targetPos = item:GetPivot()
                                                local dist = (hrp.Position - targetPos.Position).Magnitude
                                                
                                                if dist > 10 then
                                                    -- ใช้ระบบ Chunk TP วาร์ปไปหาเมล็ด
                                                    AdvancedTP(hrp, targetPos)
                                                else
                                                    -- เมื่อถึงระยะใกล้ๆ (10 studs) ให้กดเก็บ
                                                    task.spawn(function()
                                                        prompt.HoldDuration = 0
                                                        fireproximityprompt(prompt)
                                                    end)
                                                    task.wait(0.5) 
                                                end
                                                task.wait(0.1) 
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(1) 
                end
            end)
        else
            if AutoPickEventTask then
                task.cancel(AutoPickEventTask)
                AutoPickEventTask = nil
            end
        end
    end
})
local BoostFpsSection = GameTab:Section({
    Title = "Game Boost FPS",
    Desc = "Optimize the game for maximum performance",
    Icon = "zap",
})

local BoostFpsButton = BoostFpsSection:Button({
    Title = "Boost FPS (Potato Mode)",
    Desc = "Removes textures, shadows, and effects to maximize FPS.",
    Color = Color3.fromRGB(251, 196, 3),
    Callback = function()
        pcall(function()
            local Lighting = game:GetService("Lighting")
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            Lighting.ShadowSoftness = 0
            if sethiddenproperty then
                sethiddenproperty(Lighting, "Technology", 2)
            end
            
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("Texture") or v:IsA("Decal") or v:IsA("ParticleEmitter") then
                    v:Destroy()
                elseif v:IsA("BasePart") then
                    v.Material = Enum.Material.SmoothPlastic
                    v.Reflectance = 0
                end
            end
            
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
    end
})
local AutoDeleteTaskStarted = false

local AutoDeleteOthersButton = BoostFpsSection:Button({
    Title = "Auto Delete Others' Gardens",
    Desc = "Click to automatically delete other players' trees & gardens permanently.",
    Color = Color3.fromRGB(251, 196, 3),
    Callback = function()
        if AutoDeleteTaskStarted then return end
        AutoDeleteTaskStarted = true
        
        task.spawn(function()
            local Workspace = game:GetService("Workspace")
            local lp = game.Players.LocalPlayer
            
            while true do
                pcall(function()
                    local myPlotId = lp:GetAttribute("PlotId")
                    local myPlotName = myPlotId and ("Plot" .. tostring(myPlotId)) or "NO_PLOT"
                    
                    local gardens = Workspace:FindFirstChild("Gardens")
                    if gardens then
                        for _, plot in ipairs(gardens:GetChildren()) do
                            if plot.Name ~= myPlotName then
                                
                                local plants = plot:FindFirstChild("Plants")
                                if plants then
                                    for _, v in ipairs(plants:GetChildren()) do
                                        v:Destroy()
                                    end
                                end
                                
                                local sprinklers = plot:FindFirstChild("Sprinklers")
                                if sprinklers then
                                    for _, v in ipairs(sprinklers:GetChildren()) do
                                        v:Destroy()
                                    end
                                end
                                
                                local signs = plot:FindFirstChild("Signs")
                                if signs then
                                    for _, v in ipairs(signs:GetChildren()) do
                                        v:Destroy()
                                    end
                                end
                                
                            end
                        end
                    end
                end)
                task.wait(1)
            end
        end)
    end
})

Window:InitBaseTabs()

-------------------------------------------------------------------------------
-- [ PET ALERT SYSTEM - WEBHOOK & WEB API ]
-------------------------------------------------------------------------------
task.spawn(function()
    local lp = game:GetService("Players").LocalPlayer or game:GetService("Players").PlayerAdded:Wait()
    task.wait(2)

    local Config = {
        TargetPets = {
            "Golden Dragonfly",
            "Unicorn",
            "Raccoon"
        },
        WebhookURL1 = "https://discord.com/api/webhooks/1519275368283111424/jK3_OYM_1zbEGflIS9LW7tkpglCOsytERwS_8KBGuB9f9uhBEZTVlAQ6x12axDKj8b5o",
        WebhookURL2 = "https://discord.com/api/webhooks/1516683892114067558/7PSc7KGuvoKct6TI97s_zTu-SxMHvuBtStypwM538Woc0QDu_ExeFQBcoo0rp0EJfonb",
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
                    description = "🚀 **[คลิกที่นี่เพื่อเปิดเข้าเกมทันที](" .. joinUrl .. ")**\\n\\n**Place ID:** `" .. placeId .. "`\\n**Server ID:** `" .. jobId .. "`\\n**Short JobId:** `" .. shortJobId .. "`\\n**Players:** `" .. #game.Players:GetPlayers() .. "/" .. game.Players.MaxPlayers .. "`\\n\\n📌 **ก๊อปปี้ไปวางใน Executor เพื่อวาร์ปเข้าเซิร์ฟ:**\\n```lua\\n" .. scriptCopy .. "\\n```",
                    color = color,
                    fields = {{
                        name = emoji .. " " .. petName,
                        value = "Rarity: `" .. rarity .. "`\\nPrice: `¢" .. tostring(price) .. "`\\nLeft: `" .. timeLeft .. "`",
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

    while task.wait(Config.CheckInterval) do
        pcall(scanAndSend)
    end
end)
