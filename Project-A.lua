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

-- อัปเดต Mutations ใหม่ล่าสุดที่เจอจากการเจาะข้อมูลตัวเกม
local MutationList = {
    "All", "Normal", "Gold", "Rainbow", "Giant", "Huge", "Shiny",
    "Electric", "Aurora", "Bloodlit", "Starstruck", "Frozen"
}

-- ตัวแปรเก็บค่าปัจจุบันที่เลือก
local SelectedFruits = {"All"}
local SelectedBuffs = {"All"}
local AutoHarvestEnabled = false
local AutoHarvestTask = nil

-- UI Components
local FruitDropdown = HarvestSection:Dropdown({
    Title = "Select Fruits to Harvest",
    Desc = "Select fruits to target",
    Values = SeedsList,
    Value = {"All"},
    Multi = true,
    Flag = "selected_fruits",
    Callback = function(selected)
        SelectedFruits = selected
    end
})
_G.FruitDropdown = FruitDropdown -- เก็บไว้เพื่อใช้อัพเดทค่าจาก MCP

local BuffDropdown = HarvestSection:Dropdown({
    Title = "Select Fruit Buffs/Mutations to Harvest",
    Desc = "Select fruit buffs",
    Values = MutationList,
    Value = {"All"},
    Multi = true,
    Flag = "selected_buffs",
    Callback = function(selected)
        SelectedBuffs = selected
    end
})
_G.BuffDropdown = BuffDropdown -- เก็บไว้เพื่อใช้อัพเดทค่าจาก MCP

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
            local targetBuffs, hasAllBuffs

            -- ฟังก์ชันอัปเดตตารางผลไม้/บัฟที่ถูกเลือก เพื่อประหยัดการเช็คในลูป
            local function updateSelections()
                targetFruits = {}
                hasAllFruits = false

                if type(SelectedFruits) == "table" then
                    for k, v in pairs(SelectedFruits) do
                        local name = type(k) == "number" and v or k
                        if name == "All" and (v == true or type(k) == "number") then
                            hasAllFruits = true
                            break 
                        end
                        if v == true or type(k) == "number" then targetFruits[name] = true end
                    end
                end

                targetBuffs = {}
                hasAllBuffs = false

                if type(SelectedBuffs) == "table" then
                    for k, v in pairs(SelectedBuffs) do
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

            -- เริ่มการทำ Auto Harvest (TURBO MAX VERSION - Heartbeat + Parallel Processing)
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

                    -- ใช้ GetChildren แทน ipairs (เร็วกว่า)
                    local plantsList = plants:GetChildren()
                    local totalPlants = #plantsList

                    -- ประมวลผลแบบ Parallel - แบ่งเป็น batch ๆ ละ 15 ต้น
                    local batchSize = 15
                    for i = 1, totalPlants, batchSize do
                        task.spawn(function()
                            for j = i, math.min(i + batchSize - 1, totalPlants) do
                                local plant = plantsList[j]

                                -- หา Prompt โดยตรง (ไม่ใช้ Cache เพราะ FindFirstChildWhichIsA เร็วพอแล้ว)
                                local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt", true)

                                -- เช็คว่าเก็บได้หรือไม่
                                if prompt and prompt.ActionText == "Harvest" and prompt.Enabled then

                                    local shouldHarvest = false

                                    -- Fast path: ถ้าเลือก All ทั้งหมด
                                    if hasAllFruits and hasAllBuffs then
                                        shouldHarvest = true
                                    else
                                        -- Slow path: เช็คเงื่อนไข
                                        local seedMatch = hasAllFruits or targetFruits[plant:GetAttribute("SeedName")]
                                        local mutationMatch = hasAllBuffs or targetBuffs[plant:GetAttribute("Mutation") or "Normal"]
                                        shouldHarvest = seedMatch and mutationMatch
                                    end

                                    -- เก็บเกี่ยวแบบ Fire-and-Forget (ไม่รอ ไม่ spawn)
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
            -- ปิดลูปเมื่อ Toggle ปิด
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
    Values = {"Random", "Group By Type"},
    Value = "Random",
    Multi = false,
    Flag = "auto_plant_mode",
    Callback = function(selected)
        PlantMode = selected
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
                                
                                -- แบบ Random (หรือ Group หาที่ลงไม่ได้) ให้สุ่มลง PlantArea แบบใน ui.lua แท้ๆ
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

-- 7.3 Auto Sell Fruit
local AutoSellSection = ShopTab:Section({
    Title = "Auto Sell Fruit",
    Desc = "Automatically sell fruits in your inventory",
    Icon = "coins"
})

local SelectedSellFruits = {}
local SellFruitDropdown = AutoSellSection:Dropdown({
    Title = "Select Fruits to Sell",
    Desc = "Which fruits should be sold automatically?",
    Values = SeedsList,
    Value = {},
    Multi = true,
    Flag = "sell_fruits",
    Callback = function(selected)
        SelectedSellFruits = selected
    end
})

local AutoSellEnabled = false
local AutoSellTask = nil

local function DoAutoSell()
    pcall(function()
        local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)

        -- ตรวจสอบว่าเลือก "All" หรือไม่
        local isAll = false
        for k, v in pairs(SelectedSellFruits) do
            local fn = type(k) == "number" and v or k
            if (v == true or type(k) == "number") and fn == "All" then
                isAll = true break
            end
        end

        -- ถ้าเลือก All หรือเลือกผลไม้อะไรก็ตาม ให้ขายทั้งหมดเลย
        if isAll or (type(SelectedSellFruits) == "table" and #SelectedSellFruits > 0) then
            Networking.NPCS.SellAll:Fire()
        end
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
                    DoAutoSell()
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
                            task.wait(0.5) -- หน่วงนิดนึงหลังจากขายเสร็จเพื่อป้องกันการรัวเกินไป
                        end
                    end)
                    task.wait(0.05) -- เช็คถี่ๆ ทุก 0.05 วินาที
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

                        -- ตรวจสอบว่าเป็นผลไม้จริงๆ (มี Id และชื่ออยู่ใน SeedsList หรือเลือก All)
                        if fruitId and fname and (isAllFruits or fruitsDict[fname]) then
                            if not fruitToolsList[fname] then
                                fruitToolsList[fname] = {}
                            end
                            table.insert(fruitToolsList[fname], fruitId)
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

                        if fruitId and fname and (isAllFruits or fruitsDict[fname]) then
                            if not fruitToolsList[fname] then
                                fruitToolsList[fname] = {}
                            end
                            table.insert(fruitToolsList[fname], fruitId)
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

            -- 3. ส่ง Mail ในชุดละ 100 ชิ้น
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
                                                    task.wait(0.5) -- รอสักพักเพื่อให้ระบบเซิร์ฟเวอร์อัปเดตว่าเก็บเข้ากระเป๋าแล้ว
                                                end
                                                task.wait(0.1) -- หน่วงนิดหน่อยกันแลคเวลาไล่ตามเมล็ดที่กำลังร่วง
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    task.wait(1) -- เช็คทุกๆ 1 วินาทีว่า Event มาหรือยัง
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
            
            -- Remove Textures and Decals
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("Texture") or v:IsA("Decal") or v:IsA("ParticleEmitter") then
                    v:Destroy()
                elseif v:IsA("BasePart") then
                    v.Material = Enum.Material.SmoothPlastic
                    v.Reflectance = 0
                end
            end
            
            -- Optimize Rendering Settings
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
        
        -- à¸—à¸³à¸‡à¸²à¸™à¹€à¸›à¹‡à¸™à¸¥à¸¹à¸›à¸­à¸­à¹‚à¸•à¹‰à¸•à¸¥à¸­à¸”à¹€à¸§à¸¥à¸²
        task.spawn(function()
            local Workspace = game:GetService("Workspace")
            local lp = game.Players.LocalPlayer
            
            while true do
                pcall(function()
                    local myPlotId = lp:GetAttribute("PlotId")
                    -- à¸–à¹‰à¸²à¸¢à¸±à¸‡à¹„à¸¡à¹ˆà¸¡à¸µà¸žà¸¥à¹‡à¸­à¸•à¸‚à¸­à¸‡à¸•à¸±à¸§à¹€à¸­à¸‡ à¹ƒà¸«à¹‰à¸›à¸¥à¹ˆà¸­à¸¢à¸§à¹ˆà¸²à¸‡à¹„à¸§à¹‰à¹€à¸žà¸·à¹ˆà¸­à¸›à¹‰à¸­à¸‡à¸à¸±à¸™à¸¥à¸šà¸žà¸¥à¹‡à¸­à¸•à¸•à¸±à¸§à¹€à¸­à¸‡à¸œà¸´à¸”
                    local myPlotName = myPlotId and ("Plot" .. tostring(myPlotId)) or "NO_PLOT"
                    
                    local gardens = Workspace:FindFirstChild("Gardens")
                    if gardens then
                        for _, plot in ipairs(gardens:GetChildren()) do
                            -- à¸¥à¸šà¸—à¸¸à¸à¸­à¸¢à¹ˆà¸²à¸‡à¹ƒà¸™à¸žà¸¥à¹‡à¸­à¸•à¸—à¸µà¹ˆà¹„à¸¡à¹ˆà¹ƒà¸Šà¹ˆà¸žà¸¥à¹‡à¸­à¸•à¸‚à¸­à¸‡à¹€à¸£à¸²
                            if plot.Name ~= myPlotName then
                                
                                -- à¸¥à¸šà¸•à¹‰à¸™à¹„à¸¡à¹‰
                                local plants = plot:FindFirstChild("Plants")
                                if plants then
                                    for _, v in ipairs(plants:GetChildren()) do
                                        v:Destroy()
                                    end
                                end
                                
                                -- à¸¥à¸šà¸ªà¸›à¸£à¸´à¸‡à¹€à¸à¸­à¸£à¹Œ
                                local sprinklers = plot:FindFirstChild("Sprinklers")
                                if sprinklers then
                                    for _, v in ipairs(sprinklers:GetChildren()) do
                                        v:Destroy()
                                    end
                                end
                                
                                -- à¸¥à¸šà¸›à¹‰à¸²à¸¢à¸•à¹ˆà¸²à¸‡à¹† (à¸¥à¸”à¹à¸¥à¸„)
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
                -- à¹€à¸Šà¹‡à¸„à¸­à¸­à¹‚à¸•à¹‰à¸—à¸¸à¸à¹† 1 à¸§à¸´à¸™à¸²à¸—à¸µà¹€à¸œà¸·à¹ˆà¸­à¸¡à¸µà¸„à¸™à¸›à¸¥à¸¹à¸à¹ƒà¸«à¸¡à¹ˆà¸«à¸£à¸·à¸­à¸¡à¸µà¸„à¸™à¹ƒà¸«à¸¡à¹ˆà¹€à¸‚à¹‰à¸²à¸¡à¸²
                task.wait(1)
            end
        end)
    end
})

Window:InitBaseTabs()
