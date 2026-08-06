local Window = loadstring(game:HttpGet("https://raw.githubusercontent.com/latavee1399-dev/AKO/refs/heads/main/CC%20ui"))()

local OriginalInitBaseTabs = Window.InitBaseTabs

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")

local LocalPlayer = Players.LocalPlayer
local AimRandom = Random.new()
local TARGET_PART_CANDIDATE_NAMES = { "Head", "HumanoidRootPart", "UpperTorso", "Torso" }
local MODEL_TYPE_ATTRIBUTE_NAMES = { "NPCType", "MonsterType", "ZombieType", "EnemyType", "Type" }
local BOX_CORNER_OFFSETS = {
    Vector3.new(-1, -1, -1),
    Vector3.new(-1, -1, 1),
    Vector3.new(-1, 1, -1),
    Vector3.new(-1, 1, 1),
    Vector3.new(1, -1, -1),
    Vector3.new(1, -1, 1),
    Vector3.new(1, 1, -1),
    Vector3.new(1, 1, 1),
}

local function clearTableValues(tbl)
    for key in next, tbl do
        tbl[key] = nil
    end
end

local function trimText(text)
    return (tostring(text or "")):gsub("^%s*(.-)%s*$", "%1")
end

local function lowerText(text)
    return string.lower(trimText(text))
end

local function containsAnyKeyword(text, keywords)
    local source = lowerText(text)

    for _, keyword in next, keywords do
        if string.find(source, keyword, 1, true) then
            return true
        end
    end

    return false
end

local function roundNumber(value, decimals)
    local factor = 10 ^ (decimals or 0)
    return math.floor((value * factor) + 0.5) / factor
end

local function studsToMeters(studs)
    return studs * 0.28
end

local NIGHT_VISION_EFFECT_NAME = "TWDONightVision"
local NIGHT_VISION_STATE_KEY = "_twdoNightVisionOriginal"
local NightVisionConnection = nil

local function captureLightingState()
    return {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
        ColorShift_Top = Lighting.ColorShift_Top,
        FogColor = Lighting.FogColor,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        ExposureCompensation = Lighting.ExposureCompensation,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
    }
end

local function restoreLightingState(state)
    if type(state) ~= "table" then
        return
    end

    for property, value in next, state do
        pcall(function()
            Lighting[property] = value
        end)
    end
end

local function getNightVisionEffect()
    local effect = Lighting:FindFirstChild(NIGHT_VISION_EFFECT_NAME)
    if effect and not effect:IsA("ColorCorrectionEffect") then
        pcall(function()
            effect:Destroy()
        end)
        effect = nil
    end

    if not effect then
        effect = Instance.new("ColorCorrectionEffect")
        effect.Name = NIGHT_VISION_EFFECT_NAME
        effect.Parent = Lighting
    end

    return effect
end

local function applyNightVisionVisuals()
    local effect = getNightVisionEffect()
    effect.Enabled = true
    -- ค่า NVG จริง: tint เขียวแรง, saturation สูง, brightness อย่าให้พุ่ง
    effect.Brightness = 0.04
    effect.Contrast = 0.25
    effect.Saturation = 0.85
    effect.TintColor = Color3.fromRGB(0, 255, 70)

    -- SET ค่าตรงๆ ห้ามใช้ math.max เพราะถ้าค่าเดิมสูงอยู่แล้วจะขาวทันที
    Lighting.Brightness = 1.8
    Lighting.Ambient = Color3.fromRGB(45, 105, 55)
    Lighting.OutdoorAmbient = Color3.fromRGB(55, 115, 65)
    Lighting.ColorShift_Bottom = Color3.fromRGB(8, 40, 12)
    Lighting.ColorShift_Top = Color3.fromRGB(35, 95, 45)
    Lighting.FogStart = 0
    Lighting.FogEnd = 400
    Lighting.GlobalShadows = false
    Lighting.ExposureCompensation = 0.6
    Lighting.EnvironmentDiffuseScale = 0.55
    Lighting.EnvironmentSpecularScale = 0.2
end

local function clearNightVisionEffect()
    local effect = Lighting:FindFirstChild(NIGHT_VISION_EFFECT_NAME)
    if effect then
        pcall(function()
            effect:Destroy()
        end)
    end
end

local function setNightVisionEnabled(enabled)
    if enabled then
        if not _G[NIGHT_VISION_STATE_KEY] then
            _G[NIGHT_VISION_STATE_KEY] = captureLightingState()
        end

        applyNightVisionVisuals()

        if NightVisionConnection then
            NightVisionConnection:Disconnect()
            NightVisionConnection = nil
        end
        _G._twdoNightVisionConnection = nil
    else
        if NightVisionConnection then
            NightVisionConnection:Disconnect()
            NightVisionConnection = nil
        end
        _G._twdoNightVisionConnection = nil
        restoreLightingState(_G[NIGHT_VISION_STATE_KEY])
        _G[NIGHT_VISION_STATE_KEY] = nil
        clearNightVisionEffect()
    end
end

if Lighting:FindFirstChild(NIGHT_VISION_EFFECT_NAME) and _G[NIGHT_VISION_STATE_KEY] then
    restoreLightingState(_G[NIGHT_VISION_STATE_KEY])
    _G[NIGHT_VISION_STATE_KEY] = nil
    clearNightVisionEffect()
end

local function getCamera()
    return Workspace.CurrentCamera
end

local function getCharacterHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function getCharacterRoot(character)
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
end

local function getAliveCharacter(player)
    local character = player and player.Character
    local humanoid = getCharacterHumanoid(character)

    if not character or not humanoid or humanoid.Health <= 0 then
        return nil
    end

    return character
end

local function getLocalOrigin()
    local root = getCharacterRoot(LocalPlayer.Character)
    if root then
        return root.Position
    end

    local camera = getCamera()
    if camera then
        return camera.CFrame.Position
    end

    return Vector3.zero
end

local function getBestPartFromModel(model)
    if not model then
        return nil
    end

    for _, name in next, TARGET_PART_CANDIDATE_NAMES do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end

    if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
        return model.PrimaryPart
    end

    for _, child in next, model:GetChildren() do
        if child:IsA("BasePart") then
            return child
        end
    end

    return nil
end

local function getDisplayPosition(instance, extraYOffset)
    extraYOffset = extraYOffset or 0

    if not instance then
        return nil
    end

    if instance:IsA("BasePart") then
        return instance.Position + Vector3.new(0, extraYOffset, 0)
    end

    if instance:IsA("Model") then
        local ok, boxCFrame, boxSize = pcall(function()
            return instance:GetBoundingBox()
        end)

        if ok and boxCFrame and boxSize then
            return boxCFrame.Position + Vector3.new(0, (boxSize.Y * 0.5) + extraYOffset, 0)
        end

        local part = getBestPartFromModel(instance)
        if part then
            return part.Position + Vector3.new(0, extraYOffset, 0)
        end
    end

    return nil
end

local function getScreenPosition(worldPosition)
    local camera = getCamera()
    if not camera or not worldPosition then
        return nil, false
    end

    local viewportPoint, onScreen = camera:WorldToViewportPoint(worldPosition)
    if viewportPoint.Z <= 0 then
        return nil, false
    end

    return Vector2.new(viewportPoint.X, viewportPoint.Y), onScreen
end

local function getCharacterBoxBounds(character)
    local camera = getCamera()
    if not camera or not character then
        return nil
    end

    local head = character:FindFirstChild("Head")
    local root = getCharacterRoot(character)
    local topPart = head or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or root
    local bottomPart = root or getBestPartFromModel(character)

    if not topPart or not bottomPart then
        return nil
    end

    local topPoint = camera:WorldToViewportPoint(topPart.Position + Vector3.new(0, 0.5, 0))
    local bottomPoint = camera:WorldToViewportPoint(bottomPart.Position)

    if topPoint.Z <= 0 or bottomPoint.Z <= 0 then
        return nil
    end

    local height = math.abs(bottomPoint.Y - topPoint.Y)
    if height < 18 then
        height = 18
    end

    local width = math.max(height * 0.55, 12)
    local position = Vector2.new(topPoint.X - (width * 0.5), topPoint.Y - 4)
    local size = Vector2.new(width, height + 8)
    local textPos = Vector2.new(topPoint.X, topPoint.Y - 14)

    return position, size, textPos
end

local function createTextDrawing()
    if not Drawing or not Drawing.new then
        return nil
    end

    local text = Drawing.new("Text")
    text.Visible = false
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0, 0, 0)
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Size = 16
    text.Transparency = 1
    text.ZIndex = 3
    return text
end

local function createSquareDrawing()
    if not Drawing or not Drawing.new then
        return nil
    end

    local square = Drawing.new("Square")
    square.Visible = false
    square.Filled = false
    square.Thickness = 1.5
    square.Transparency = 1
    square.Color = Color3.fromRGB(255, 255, 255)
    square.ZIndex = 2
    return square
end

local function createHighlightInstance(color)
    local highlight = Instance.new("Highlight")
    highlight.Name = "TWDOESPHighlight"
    highlight.Enabled = false
    highlight.FillColor = color or Color3.fromRGB(255, 255, 255)
    highlight.OutlineColor = color or Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = Workspace
    return highlight
end

local function safeDestroyDrawing(drawing)
    if not drawing then
        return
    end

    pcall(function()
        drawing.Visible = false
    end)
    pcall(function()
        drawing:Remove()
    end)
    pcall(function()
        drawing:Destroy()
    end)
end

local function destroyEspEntry(entry)
    if type(entry) == "table" then
        safeDestroyDrawing(entry.Box)
        safeDestroyDrawing(entry.Text)
        safeDestroyDrawing(entry.TopText)
        safeDestroyDrawing(entry.Highlight)
        return
    end

    safeDestroyDrawing(entry)
end

local function getBoxBounds(instance)
    local camera = getCamera()
    if not camera or not instance then
        return nil
    end

    local boxCFrame
    local boxSize

    if instance:IsA("BasePart") then
        boxCFrame = instance.CFrame
        boxSize = instance.Size
    elseif instance:IsA("Model") then
        local ok, cframe, size = pcall(function()
            return instance:GetBoundingBox()
        end)

        if ok then
            boxCFrame = cframe
            boxSize = size
        end
    end

    if not boxCFrame or not boxSize then
        return nil
    end

    local half = boxSize * 0.5
    local minX = math.huge
    local minY = math.huge
    local maxX = -math.huge
    local maxY = -math.huge
    local visible = false

    for _, corner in next, BOX_CORNER_OFFSETS do
        local offset = Vector3.new(corner.X * half.X, corner.Y * half.Y, corner.Z * half.Z)
        local worldPoint = boxCFrame:PointToWorldSpace(offset)
        local viewportPoint = camera:WorldToViewportPoint(worldPoint)
        if viewportPoint.Z > 0 then
            visible = true
            minX = math.min(minX, viewportPoint.X)
            minY = math.min(minY, viewportPoint.Y)
            maxX = math.max(maxX, viewportPoint.X)
            maxY = math.max(maxY, viewportPoint.Y)
        end
    end

    if not visible then
        return nil
    end

    local padding = 2
    local position = Vector2.new(minX - padding, minY - padding)
    local size = Vector2.new((maxX - minX) + (padding * 2), (maxY - minY) + (padding * 2))
    local topCenter = Vector2.new(minX + ((maxX - minX) * 0.5), minY - 16)

    return position, size, topCenter, boxCFrame.Position
end

local function walkInstances(root, callback, yieldEvery)
    local visited = 0

    local function scan(node)
        for _, child in next, node:GetChildren() do
            callback(child)

            if yieldEvery and yieldEvery > 0 then
                visited = visited + 1

                if visited % yieldEvery == 0 then
                    task.wait()
                end
            end

            scan(child)
        end
    end

    scan(root)
end

local function getModelTypeName(model, fallback)
    for _, attributeName in next, MODEL_TYPE_ATTRIBUTE_NAMES do
        local value = model and model:GetAttribute(attributeName)
        if type(value) == "string" and trimText(value) ~= "" then
            return trimText(value)
        end
    end

    if fallback and trimText(fallback) ~= "" then
        return trimText(fallback)
    end

    return model and model.Name or "Unknown"
end

local ZombieKeywords = { "zombie", "walker", "infected", "monster", "enemy" }
local ChestKeywords = { "chest", "loot", "crate", "supply", "container", "box", "stash", "cache" }

local function isZombieCandidate(instance)
    if not instance or not instance:IsA("Model") then
        return false
    end

    if Players:GetPlayerFromCharacter(instance) then
        return false
    end

    local humanoid = instance:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    if containsAnyKeyword(instance.Name, ZombieKeywords) then
        return true
    end

    local typeName = getModelTypeName(instance, "")
    if containsAnyKeyword(typeName, ZombieKeywords) then
        return true
    end

    return false
end

local function isCharacterLikeInstance(instance)
    local current = instance

    while current do
        if current:IsA("Model") then
            if Players:GetPlayerFromCharacter(current) then
                return true
            end

            if current:FindFirstChildOfClass("Humanoid") then
                return true
            end
        end

        current = current.Parent
    end

    return false
end

local function isChestCandidate(instance)
    if not instance then
        return false
    end

    if instance:IsA("Model") or instance:IsA("BasePart") then
        if isCharacterLikeInstance(instance) then
            return false
        end

        if containsAnyKeyword(instance.Name, ChestKeywords) then
            return true
        end

        local typeName = getModelTypeName(instance, "")
        if containsAnyKeyword(typeName, ChestKeywords) then
            return true
        end
    end

    return false
end

local SharedMonsterTargets = {}
local SharedChestTargets = {}
local SharedMonsterLastRefresh = 0
local SharedChestLastRefresh = 0

local function refreshSharedMonsterTargets()
    local targets = {}

    walkInstances(Workspace, function(instance)
        if isZombieCandidate(instance) then
            targets[#targets + 1] = instance
        end
    end)

    SharedMonsterTargets = targets
    SharedMonsterLastRefresh = os.clock()
    return targets
end

local function getSharedMonsterTargets(maxAge)
    if SharedMonsterLastRefresh == 0 or (os.clock() - SharedMonsterLastRefresh) >= (maxAge or 2.5) then
        return refreshSharedMonsterTargets()
    end

    return SharedMonsterTargets
end

local function resetSharedMonsterTargets()
    SharedMonsterTargets = {}
    SharedMonsterLastRefresh = 0
end

local function refreshSharedChestTargets()
    local targets = {}

    walkInstances(Workspace, function(instance)
        if isChestCandidate(instance) then
            targets[#targets + 1] = instance
        end
    end, 120)

    SharedChestTargets = targets
    SharedChestLastRefresh = os.clock()
    return targets
end

local function getSharedChestTargets(maxAge)
    if SharedChestLastRefresh == 0 or (os.clock() - SharedChestLastRefresh) >= (maxAge or 4) then
        return refreshSharedChestTargets()
    end

    return SharedChestTargets
end

local function resetSharedChestTargets()
    SharedChestTargets = {}
    SharedChestLastRefresh = 0
end

local function flattenLootValue(value, addLine)
    local valueType = typeof(value)

    if valueType == "string" then
        local trimmed = trimText(value)
        if trimmed ~= "" then
            for token in trimmed:gmatch("[^,%|;/\n]+") do
                local text = trimText(token)
                if text ~= "" then
                    addLine(text)
                end
            end
        end
    elseif valueType == "number" or valueType == "boolean" then
        addLine(tostring(value))
    elseif valueType == "table" then
        for _, item in next, value do
            flattenLootValue(item, addLine)
        end
    end
end

local function extractLootItems(chest)
    local items = {}
    local seen = {}

    local function addLine(text)
        local value = trimText(text)
        if value ~= "" and not seen[value] then
            seen[value] = true
            items[#items + 1] = value
        end
    end

    local ok, attributes = pcall(function()
        return chest:GetAttributes()
    end)

    if ok and type(attributes) == "table" then
        for key, value in next, attributes do
            local keyName = lowerText(key)
            if string.find(keyName, "loot", 1, true)
                or string.find(keyName, "item", 1, true)
                or string.find(keyName, "reward", 1, true)
                or string.find(keyName, "content", 1, true)
                or string.find(keyName, "drop", 1, true) then
                flattenLootValue(value, addLine)
            end
        end
    end

    local function scan(node, depth)
        if depth > 2 then
            return
        end

        for _, child in next, node:GetChildren() do
            if child:IsA("StringValue") then
                flattenLootValue(child.Value, addLine)
                if containsAnyKeyword(child.Name, ChestKeywords) then
                    addLine(child.Name)
                end
            elseif child:IsA("ObjectValue") then
                if child.Value then
                    addLine(child.Value.Name)
                end
            elseif child:IsA("Tool") then
                addLine(child.Name)
            elseif child:IsA("Folder") or child:IsA("Configuration") or child:IsA("Model") then
                scan(child, depth + 1)
            end
        end
    end

    scan(chest, 0)

    if #items == 0 then
        addLine("Unknown")
    end

    return items
end

local function collectTextLines(prefix, values)
    local lines = { prefix }

    for _, value in next, values do
        lines[#lines + 1] = "- " .. value
    end

    return table.concat(lines, "\n")
end

local function getModelInfoPosition(model, offset)
    offset = offset or 0

    local worldPosition = getDisplayPosition(model, offset)
    if worldPosition then
        return worldPosition
    end

    return nil
end

local function getDistanceMeters(instance)
    local origin = getLocalOrigin()
    local position = getDisplayPosition(instance, 0)
    if not position then
        return nil
    end

    return roundNumber(studsToMeters((position - origin).Magnitude), 1)
end

local AimState = {
    Enabled = false,
    Holding = false,
    HoldBind = Enum.UserInputType.MouseButton2,
    UseFOV = false,
    FOVRadius = 120,
    TargetType = "Player",
    TargetPart = "Head",
    Smoothing = true,
    SmoothingFactor = 0.18,
    Prediction = true,
    PredictionStrength = 0.12,
    StickyTarget = true,
    VisibilityCheck = true,
    AutoShoot = false,
}

assert(AimState.HoldBind == Enum.UserInputType.MouseButton2, "Aimbot hold key default must be MouseButton2")
assert(AimState.TargetType == "Player", "Aimbot target type default must be Player")

local AimConnection = nil
local FOVCircle = nil
local AimMonsterTargets = {}
local AimMonsterRefreshAt = 0
local AimCurrentTarget = nil

if _G._twdoAimConnection then
    pcall(function()
        _G._twdoAimConnection:Disconnect()
    end)
    _G._twdoAimConnection = nil
end

if _G._twdoAimInputBegan then
    pcall(function()
        _G._twdoAimInputBegan:Disconnect()
    end)
    _G._twdoAimInputBegan = nil
end

if _G._twdoAimInputEnded then
    pcall(function()
        _G._twdoAimInputEnded:Disconnect()
    end)
    _G._twdoAimInputEnded = nil
end

if _G._twdoFOVCircle then
    safeDestroyDrawing(_G._twdoFOVCircle)
    _G._twdoFOVCircle = nil
end

if _G._twdoNightVisionConnection then
    pcall(function()
        _G._twdoNightVisionConnection:Disconnect()
    end)
    _G._twdoNightVisionConnection = nil
end

if _G._twdoTeleportLocationInputBegan then
    pcall(function()
        _G._twdoTeleportLocationInputBegan:Disconnect()
    end)
    _G._twdoTeleportLocationInputBegan = nil
end

if _G._twdoTeleportChestInputBegan then
    pcall(function()
        _G._twdoTeleportChestInputBegan:Disconnect()
    end)
    _G._twdoTeleportChestInputBegan = nil
end

local function destroyFOVCircle()
    if not FOVCircle then
        return
    end

    safeDestroyDrawing(FOVCircle)
    FOVCircle = nil
    _G._twdoFOVCircle = nil
end

local function ensureFOVCircle()
    if FOVCircle then
        return FOVCircle
    end

    if not Drawing or not Drawing.new then
        return nil
    end

    local circle = Drawing.new("Circle")
    circle.Visible = false
    circle.Color = Color3.fromRGB(255, 0, 0)
    circle.Thickness = 1.5
    circle.NumSides = 64
    circle.Radius = AimState.FOVRadius
    circle.Filled = false
    circle.Transparency = 0.35
    circle.ZIndex = 100

    FOVCircle = circle
    _G._twdoFOVCircle = circle
    return circle
end

local function getTargetPart(character)
    if not character then
        return nil
    end

    if AimState.TargetPart == "Head" then
        local head = character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            return head
        end

        return getBestPartFromModel(character)
    end

    if AimState.TargetPart == "Body" then
        local body = getCharacterRoot(character)
        if body and body:IsA("BasePart") then
            return body
        end

        return getBestPartFromModel(character)
    end

    local head = character:FindFirstChild("Head")
    local body = getCharacterRoot(character)
    local hasHead = head and head:IsA("BasePart")
    local hasBody = body and body:IsA("BasePart")

    if hasHead and hasBody then
        if AimRandom:NextInteger(1, 2) == 1 then
            return head
        end

        return body
    end

    if hasHead then
        return head
    end

    if hasBody then
        return body
    end

    return getBestPartFromModel(character)
end

local function refreshAimMonsterTargets()
    AimMonsterTargets = getSharedMonsterTargets(1)
end

local function getAimMonsterTargets()
    local now = os.clock()
    if now >= AimMonsterRefreshAt then
        refreshAimMonsterTargets()
        AimMonsterRefreshAt = now + 0.75
    end

    return AimMonsterTargets
end

local function isTargetVisible(targetPart)
    if not AimState.VisibilityCheck then
        return true
    end

    local camera = getCamera()
    local origin = camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit
    local distance = (targetPart.Position - origin).Magnitude

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = { LocalPlayer.Character, targetPart.Parent }
    raycastParams.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction * distance, raycastParams)

    return not result or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function getTargetVelocity(targetPart)
    if not targetPart or not targetPart:IsA("BasePart") then
        return Vector3.new(0, 0, 0)
    end

    local velocity = targetPart.AssemblyLinearVelocity
    if velocity and velocity.Magnitude > 0 then
        return velocity
    end

    return Vector3.new(0, 0, 0)
end

local function getPredictedPosition(targetPart)
    if not AimState.Prediction or not targetPart then
        return targetPart.Position
    end

    local velocity = getTargetVelocity(targetPart)
    local predictionTime = AimState.PredictionStrength

    return targetPart.Position + (velocity * predictionTime)
end

local function getAimTargetScore(camera, mouseLocation, targetPart, bestScore)
    if not targetPart or not targetPart:IsA("BasePart") then
        return nil, nil
    end

    if not isTargetVisible(targetPart) then
        return nil, nil
    end

    local targetPosition = getPredictedPosition(targetPart)
    local viewportPoint, onScreen = camera:WorldToViewportPoint(targetPosition)

    if viewportPoint.Z <= 0 then
        return nil, nil
    end

    local offsetX = viewportPoint.X - mouseLocation.X
    local offsetY = viewportPoint.Y - mouseLocation.Y
    local screenDistance = math.sqrt((offsetX * offsetX) + (offsetY * offsetY))

    local origin = getLocalOrigin()
    local worldDistance = (targetPosition - origin).Magnitude

    -- คะแนนผสม: ระยะบนหน้าจอ (70%) + ระยะในโลก (30%)
    local score = (screenDistance * 0.7) + ((worldDistance / 100) * 0.3)

    if (not AimState.UseFOV or (onScreen and screenDistance <= AimState.FOVRadius)) and score < bestScore then
        return score, targetPosition
    end

    return nil, nil
end

local function getBestTarget()
    local camera = getCamera()
    if not camera then
        return nil, nil
    end

    local mouseLocation = UserInputService:GetMouseLocation()
    local bestPart = nil
    local bestPosition = nil
    local bestScore = math.huge

    -- ถ้ามี Sticky Target และเป้าเดิมยังอยู่ใน FOV ให้ใช้เป้าเดิมต่อ
    if AimState.StickyTarget and AimCurrentTarget and AimCurrentTarget.Parent then
        local currentScore, currentPosition = getAimTargetScore(camera, mouseLocation, AimCurrentTarget, math.huge)
        if currentScore then
            return AimCurrentTarget, currentPosition
        end
    end

    if AimState.TargetType == "Monster" then
        for _, monster in next, getAimMonsterTargets() do
            local humanoid = getCharacterHumanoid(monster)
            if monster and monster.Parent and humanoid and humanoid.Health > 0 then
                local targetPart = getTargetPart(monster)
                local score, position = getAimTargetScore(camera, mouseLocation, targetPart, bestScore)

                if score then
                    bestScore = score
                    bestPart = targetPart
                    bestPosition = position
                end
            end
        end
    else
        for _, player in next, Players:GetPlayers() do
            if player ~= LocalPlayer then
                local character = getAliveCharacter(player)
                if character then
                    local targetPart = getTargetPart(character)
                    local score, position = getAimTargetScore(camera, mouseLocation, targetPart, bestScore)

                    if score then
                        bestScore = score
                        bestPart = targetPart
                        bestPosition = position
                    end
                end
            end
        end
    end

    return bestPart, bestPosition
end

local function stopAimLoop()
    if AimConnection then
        AimConnection:Disconnect()
        AimConnection = nil
    end

    _G._twdoAimConnection = nil
    AimMonsterTargets = {}
    AimMonsterRefreshAt = 0
    AimCurrentTarget = nil
    resetSharedMonsterTargets()
    destroyFOVCircle()
end

local function startAimLoop()
    if AimConnection then
        return
    end

    AimConnection = RunService.RenderStepped:Connect(function()
        local shouldAim = AimState.Enabled and AimState.Holding
        if not AimState.UseFOV and not shouldAim then
            return
        end

        local camera = getCamera()
        if not camera then
            return
        end

        if AimState.UseFOV then
            local circle = ensureFOVCircle()
            if circle then
                local mouseLocation = UserInputService:GetMouseLocation()
                circle.Visible = true
                circle.Radius = AimState.FOVRadius
                circle.Position = Vector2.new(mouseLocation.X, mouseLocation.Y)
            end
        elseif FOVCircle then
            FOVCircle.Visible = false
        end

        if not shouldAim then
            return
        end

        local targetPart, targetPosition = getBestTarget()
        if targetPart and targetPosition then
            -- อัพเดท current target
            AimCurrentTarget = targetPart

            local cameraCFrame = camera.CFrame
            local targetDirection = (targetPosition - cameraCFrame.Position).Unit

            if AimState.Smoothing then
                -- Smoothing แบบ exponential
                local currentDirection = cameraCFrame.LookVector
                local smoothedDirection = currentDirection:Lerp(targetDirection, AimState.SmoothingFactor)
                camera.CFrame = CFrame.new(cameraCFrame.Position, cameraCFrame.Position + smoothedDirection)
            else
                -- Lock แบบทันที
                camera.CFrame = CFrame.new(cameraCFrame.Position, targetPosition)
            end
        else
            -- หลุดเป้า
            AimCurrentTarget = nil
        end
    end)

    _G._twdoAimConnection = AimConnection
end

local function refreshAimLoop()
    if AimState.Enabled or AimState.UseFOV then
        startAimLoop()
    else
        stopAimLoop()
    end
end

local function isAimHoldInput(input)
    return input.UserInputType == AimState.HoldBind or input.KeyCode == AimState.HoldBind
end

local function setAimHoldBind(key)
    if typeof(key) ~= "EnumItem" then
        return
    end

    AimState.HoldBind = key
    AimState.Holding = false
end

_G._twdoAimInputBegan = UserInputService.InputBegan:Connect(function(input)
    if UserInputService:GetFocusedTextBox() then
        return
    end

    if isAimHoldInput(input) then
        AimState.Holding = true
    end
end)

_G._twdoAimInputEnded = UserInputService.InputEnded:Connect(function(input)
    if isAimHoldInput(input) then
        AimState.Holding = false
    end
end)

local ESPState = {
    Player = {
        Enabled = false,
        Color = Color3.fromRGB(255, 0, 0),
    },
    Monster = {
        Enabled = false,
        Color = Color3.fromRGB(0, 255, 0),
    },
    Chest = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 0),
    },
}

-- Performance settings (declare ก่อนใช้งาน)
local ESP_MAX_DISTANCE_STUDS = 2500
local ESP_PLAYER_UPDATE_RATE = 0.1
local ESP_MONSTER_UPDATE_RATE = 0.35
local ESP_CHEST_UPDATE_RATE = 0.7
local ESP_MAX_VISIBLE_ITEMS = 50

local ESPConnection = nil
local ESPRefreshMonsterAt = 0
local ESPRefreshChestAt = 0
local ESPLastPlayerUpdate = 0
local ESPLastMonsterUpdate = 0
local ESPLastChestUpdate = 0
local ESPWorkerRunning = false

local ESPDrawings = {
    Player = {},
    Monster = {},
    Chest = {},
}

local ESPSeen = {
    Player = {},
    Monster = {},
    Chest = {},
}

local MonsterTargets = {}
local ChestTargets = {}
local ChestInfoCache = {}
local CHEST_INFO_CACHE_SECONDS = 3

local function clearDrawingMap(map)
    for key, drawing in next, map do
        destroyEspEntry(drawing)
        map[key] = nil
    end
end

local function refreshMonsterTargets()
    MonsterTargets = getSharedMonsterTargets(2.5)
end

local function refreshChestTargets()
    ChestTargets = getSharedChestTargets(4)
end

local function updatePlayerESP()
    local seen = ESPSeen.Player
    clearTableValues(seen)
    local origin = getLocalOrigin()
    local camera = getCamera()
    if not camera then
        return
    end

    local playerCount = 0

    for _, player in next, Players:GetPlayers() do
        if player ~= LocalPlayer then
            local character = getAliveCharacter(player)
            local root = character and getCharacterRoot(character)
            local humanoid = getCharacterHumanoid(character)

            if character and root and humanoid then
                local rawDistance = (root.Position - origin).Magnitude

                -- Skip players ที่ไกลเกินไป
                if rawDistance <= ESP_MAX_DISTANCE_STUDS then
                    playerCount = playerCount + 1
                    if playerCount <= ESP_MAX_VISIBLE_ITEMS then
                        local bundle = ESPDrawings.Player[player]
                        if not bundle then
                            bundle = {
                                Box = createSquareDrawing(),
                                Text = createTextDrawing(),
                                TopText = createTextDrawing(),
                                Highlight = createHighlightInstance(ESPState.Player.Color),
                            }
                            ESPDrawings.Player[player] = bundle
                        end

                        local hp = math.floor(humanoid.Health + 0.5)
                        local maxHp = math.floor((humanoid.MaxHealth > 0 and humanoid.MaxHealth) or humanoid.Health + 0.5)
                        local distanceMeters = roundNumber(studsToMeters(rawDistance), 1)

                        if bundle and bundle.Highlight then
                            bundle.Highlight.Adornee = character
                            bundle.Highlight.FillColor = ESPState.Player.Color
                            bundle.Highlight.OutlineColor = ESPState.Player.Color
                            bundle.Highlight.FillTransparency = 1
                            bundle.Highlight.OutlineTransparency = 0
                            bundle.Highlight.Enabled = true
                        end

                        local boxPos, boxSize, textPos = getCharacterBoxBounds(character)
                        if boxPos and boxSize and textPos then
                            if bundle and bundle.Box then
                                bundle.Box.Color = ESPState.Player.Color
                                bundle.Box.Position = boxPos
                                bundle.Box.Size = boxSize
                                bundle.Box.Visible = true
                            end

                            if bundle and bundle.Text then
                                bundle.Text.Text = player.Name .. "\n" .. hp .. "/" .. maxHp .. "\n" .. distanceMeters .. "m"
                                bundle.Text.Color = ESPState.Player.Color
                                bundle.Text.Size = 13
                                bundle.Text.Position = Vector2.new(textPos.X, textPos.Y + 6)
                                bundle.Text.Visible = true
                            end

                            if bundle and bundle.TopText then
                                bundle.TopText.Visible = false
                            end
                        elseif bundle then
                            if bundle.Box then
                                bundle.Box.Visible = false
                            end
                            if bundle.Text then
                                bundle.Text.Visible = false
                            end
                            if bundle.TopText then
                                bundle.TopText.Visible = false
                            end
                        end

                        seen[player] = true
                    end
                end
            end
        end
    end

    for player, entry in next, ESPDrawings.Player do
        if not seen[player] then
            if player.Parent ~= Players then
                destroyEspEntry(entry)
                ESPDrawings.Player[player] = nil
            elseif type(entry) == "table" then
                if entry.Box then
                    entry.Box.Visible = false
                end
                if entry.Text then
                    entry.Text.Visible = false
                end
                if entry.TopText then
                    entry.TopText.Visible = false
                end
                if entry.Highlight then
                    entry.Highlight.Enabled = false
                end
            end
        end
    end
end

local function updateMonsterESP()
    local seen = ESPSeen.Monster
    clearTableValues(seen)
    local origin = getLocalOrigin()
    local camera = getCamera()
    if not camera then
        return
    end

    if os.clock() >= ESPRefreshMonsterAt then
        refreshMonsterTargets()
        ESPRefreshMonsterAt = os.clock() + 3
    end

    local monsterCount = 0

    for _, monster in next, MonsterTargets do
        if monster and monster.Parent then
            local anchorPart = getCharacterRoot(monster) or getBestPartFromModel(monster)
            if anchorPart then
                local rawDistance = (anchorPart.Position - origin).Magnitude
                if rawDistance <= ESP_MAX_DISTANCE_STUDS then
                    monsterCount = monsterCount + 1
                    if monsterCount <= ESP_MAX_VISIBLE_ITEMS then
                        local bundle = ESPDrawings.Monster[monster]
                        if not bundle then
                            bundle = {
                                Box = createSquareDrawing(),
                                Text = createTextDrawing(),
                                Highlight = createHighlightInstance(ESPState.Monster.Color),
                            }
                            ESPDrawings.Monster[monster] = bundle
                        end

                        if bundle and bundle.Highlight then
                            bundle.Highlight.Adornee = monster
                            bundle.Highlight.FillColor = ESPState.Monster.Color
                            bundle.Highlight.OutlineColor = ESPState.Monster.Color
                            bundle.Highlight.FillTransparency = 1
                            bundle.Highlight.OutlineTransparency = 0
                            bundle.Highlight.Enabled = true
                        end

                        local boxPos, boxSize, textPos = getCharacterBoxBounds(monster)
                        if boxPos and boxSize and textPos then
                            if bundle and bundle.Box then
                                bundle.Box.Color = ESPState.Monster.Color
                                bundle.Box.Position = boxPos
                                bundle.Box.Size = boxSize
                                bundle.Box.Visible = true
                            end

                            if bundle and bundle.Text then
                                local typeName = getModelTypeName(monster, monster.Name)
                                local distanceMeters = roundNumber(studsToMeters(rawDistance), 1)

                                bundle.Text.Text = typeName .. "\n" .. distanceMeters .. "m"
                                bundle.Text.Color = ESPState.Monster.Color
                                bundle.Text.Size = 13
                                bundle.Text.Position = textPos
                                bundle.Text.Visible = true
                            end
                        elseif bundle then
                            if bundle.Box then
                                bundle.Box.Visible = false
                            end
                            if bundle.Text then
                                bundle.Text.Visible = false
                            end
                        end

                        seen[monster] = true
                    end
                end
            end
        end
    end

    for monster, entry in next, ESPDrawings.Monster do
        if not seen[monster] then
            if not monster or monster.Parent == nil then
                destroyEspEntry(entry)
                ESPDrawings.Monster[monster] = nil
            elseif type(entry) == "table" then
                if entry.Box then
                    entry.Box.Visible = false
                end
                if entry.Text then
                    entry.Text.Visible = false
                end
                if entry.Highlight then
                    entry.Highlight.Enabled = false
                end
            end
        end
    end
end

local function formatLootText(items)
    local lines = { "Loot:" }
    local maxItems = math.min(#items, 6)

    if #items == 0 then
        lines[#lines + 1] = "- Unknown"
    else
        for index = 1, maxItems do
            lines[#lines + 1] = "- " .. items[index]
        end

        if #items > maxItems then
            lines[#lines + 1] = "- +" .. tostring(#items - maxItems) .. " more"
        end
    end

    return table.concat(lines, "\n")
end

local function getCachedChestLootText(chest)
    local now = os.clock()
    local entry = ChestInfoCache[chest]

    if entry and (now - entry.UpdatedAt) <= CHEST_INFO_CACHE_SECONDS then
        return entry.Text
    end

    local lootItems = extractLootItems(chest)
    local text = formatLootText(lootItems)

    ChestInfoCache[chest] = {
        Text = text,
        UpdatedAt = now,
    }

    return text
end

local function updateChestESP()
    local seen = ESPSeen.Chest
    clearTableValues(seen)
    local origin = getLocalOrigin()
    local camera = getCamera()
    if not camera then
        return
    end

    if os.clock() >= ESPRefreshChestAt then
        refreshChestTargets()
        ESPRefreshChestAt = os.clock() + 5
    end

    local chestCount = 0

    for _, chest in next, ChestTargets do
        if chest and chest.Parent then
            local boxPos, boxSize, textPos, anchor = getBoxBounds(chest)
            if boxPos and boxSize and textPos then
                local rawDistance = (anchor - origin).Magnitude
                if rawDistance <= ESP_MAX_DISTANCE_STUDS then
                    chestCount = chestCount + 1
                    if chestCount <= ESP_MAX_VISIBLE_ITEMS then
                        local bundle = ESPDrawings.Chest[chest]
                        if not bundle then
                            bundle = {
                                Box = createSquareDrawing(),
                                Text = createTextDrawing(),
                            }
                            ESPDrawings.Chest[chest] = bundle
                        end

                        if bundle and bundle.Box then
                            bundle.Box.Color = ESPState.Chest.Color
                            bundle.Box.Position = boxPos
                            bundle.Box.Size = boxSize
                            bundle.Box.Visible = true
                        end

                        if bundle and bundle.Text then
                            local distanceMeters = roundNumber(studsToMeters(rawDistance), 1)
                            local chestName = chest.Name:gsub("Loot_", ""):gsub("loot_", ""):gsub("_", " ")
                            local text = chestName .. "\n" .. distanceMeters .. "m"

                            bundle.Text.Text = text
                            bundle.Text.Color = ESPState.Chest.Color
                            bundle.Text.Size = 13
                            bundle.Text.Position = textPos
                            bundle.Text.Visible = true
                        end

                        seen[chest] = true
                    end
                end
            end
        end
    end

    for chest, entry in next, ESPDrawings.Chest do
        if not seen[chest] then
            if not chest or chest.Parent == nil then
                destroyEspEntry(entry)
                ESPDrawings.Chest[chest] = nil
                ChestInfoCache[chest] = nil
            elseif type(entry) == "table" then
                if entry.Box then
                    entry.Box.Visible = false
                end
                if entry.Text then
                    entry.Text.Visible = false
                end
                if entry.TopText then
                    entry.TopText.Visible = false
                end
            end
        end
    end
end

local function refreshESPConnection()
    local shouldRun = ESPState.Player.Enabled or ESPState.Monster.Enabled or ESPState.Chest.Enabled

    if shouldRun then
        if ESPWorkerRunning then
            return
        end

        ESPWorkerRunning = true
        ESPConnection = task.spawn(function()
            while ESPWorkerRunning do
                local now = os.clock()

                if ESPState.Player.Enabled and (now - ESPLastPlayerUpdate) >= ESP_PLAYER_UPDATE_RATE then
                    updatePlayerESP()
                    ESPLastPlayerUpdate = now
                elseif not ESPState.Player.Enabled then
                    clearDrawingMap(ESPDrawings.Player)
                end

                if ESPState.Monster.Enabled and (now - ESPLastMonsterUpdate) >= ESP_MONSTER_UPDATE_RATE then
                    updateMonsterESP()
                    ESPLastMonsterUpdate = now
                elseif not ESPState.Monster.Enabled then
                    clearDrawingMap(ESPDrawings.Monster)
                    MonsterTargets = {}
                end

                if ESPState.Chest.Enabled and (now - ESPLastChestUpdate) >= ESP_CHEST_UPDATE_RATE then
                    updateChestESP()
                    ESPLastChestUpdate = now
                elseif not ESPState.Chest.Enabled then
                    clearDrawingMap(ESPDrawings.Chest)
                    ChestTargets = {}
                end

                task.wait(0.05)
            end
        end)
    else
        ESPWorkerRunning = false
        ESPConnection = nil
        ESPLastPlayerUpdate = 0
        ESPLastMonsterUpdate = 0
        ESPLastChestUpdate = 0

        clearDrawingMap(ESPDrawings.Player)
        clearDrawingMap(ESPDrawings.Monster)
        clearDrawingMap(ESPDrawings.Chest)
        MonsterTargets = {}
        ChestTargets = {}
        resetSharedMonsterTargets()
        resetSharedChestTargets()
        clearTableValues(ChestInfoCache)
    end
end

local GAME_BOOST_STATE_KEY = "_twdoGameBoostOriginal"
local GameBoostOriginal = _G[GAME_BOOST_STATE_KEY] or {
    Instances = {},
    Lighting = nil,
    Terrain = nil,
    Rendering = nil,
}
_G[GAME_BOOST_STATE_KEY] = GameBoostOriginal

local GameBoostState = {
    FpsBoost = false,
    LowParts = false,
    HideEffects = false,
    TreesRemoved = false,
}

assert(type(GameBoostState) == "table", "Game Boots state must be a table")

local TreeKeywords = {
    "tree",
    "trees",
    "trunk",
    "branch",
    "branches",
    "leaf",
    "leaves",
    "foliage",
    "bush",
    "stump",
    "pine",
    "oak",
}

local function safeSetProperty(instance, property, value)
    pcall(function()
        instance[property] = value
    end)
end

local function captureInstanceProperty(instance, property)
    local entry = GameBoostOriginal.Instances[instance]
    if not entry then
        entry = {}
        GameBoostOriginal.Instances[instance] = entry
    end

    if entry[property] ~= nil then
        return
    end

    local ok, value = pcall(function()
        return instance[property]
    end)

    if ok then
        entry[property] = value
    end
end

local function restoreInstanceProperties(properties)
    for instance, entry in next, GameBoostOriginal.Instances do
        if instance and instance.Parent and type(entry) == "table" then
            for _, property in next, properties do
                if entry[property] ~= nil then
                    safeSetProperty(instance, property, entry[property])
                    entry[property] = nil
                end
            end
        end

        if type(entry) ~= "table" or next(entry) == nil then
            GameBoostOriginal.Instances[instance] = nil
        end
    end
end

local function walkBoostInstances(root, callback)
    local visited = 0

    local function scan(node)
        for _, child in next, node:GetChildren() do
            callback(child)
            visited = visited + 1

            if visited % 120 == 0 then
                task.wait()
            end

            scan(child)
        end
    end

    scan(root)
end

local function getRenderingSettings()
    local ok, rendering = pcall(function()
        return settings().Rendering
    end)

    if ok then
        return rendering
    end

    return nil
end

local function setFpsBoostEnabled(enabled)
    GameBoostState.FpsBoost = enabled

    if enabled then
        if not GameBoostOriginal.Lighting then
            GameBoostOriginal.Lighting = captureLightingState()
        end

        if not GameBoostOriginal.Terrain and Terrain then
            GameBoostOriginal.Terrain = {
                WaterWaveSize = Terrain.WaterWaveSize,
                WaterWaveSpeed = Terrain.WaterWaveSpeed,
                WaterReflectance = Terrain.WaterReflectance,
                WaterTransparency = Terrain.WaterTransparency,
            }
        end

        local rendering = getRenderingSettings()
        if rendering and not GameBoostOriginal.Rendering then
            local ok, quality = pcall(function()
                return rendering.QualityLevel
            end)

            if ok then
                GameBoostOriginal.Rendering = quality
            end
        end

        safeSetProperty(Lighting, "GlobalShadows", false)
        safeSetProperty(Lighting, "FogEnd", 100000)
        safeSetProperty(Lighting, "EnvironmentDiffuseScale", 0)
        safeSetProperty(Lighting, "EnvironmentSpecularScale", 0)

        if Terrain then
            safeSetProperty(Terrain, "WaterWaveSize", 0)
            safeSetProperty(Terrain, "WaterWaveSpeed", 0)
            safeSetProperty(Terrain, "WaterReflectance", 0)
            safeSetProperty(Terrain, "WaterTransparency", 1)
        end

        if rendering then
            safeSetProperty(rendering, "QualityLevel", Enum.QualityLevel.Level01)
        end
    else
        if GameBoostOriginal.Lighting then
            if _G[NIGHT_VISION_STATE_KEY] then
                applyNightVisionVisuals()
            else
                restoreLightingState(GameBoostOriginal.Lighting)
            end
            GameBoostOriginal.Lighting = nil
        end

        if GameBoostOriginal.Terrain and Terrain then
            for property, value in next, GameBoostOriginal.Terrain do
                safeSetProperty(Terrain, property, value)
            end
            GameBoostOriginal.Terrain = nil
        end

        local rendering = getRenderingSettings()
        if rendering and GameBoostOriginal.Rendering then
            safeSetProperty(rendering, "QualityLevel", GameBoostOriginal.Rendering)
            GameBoostOriginal.Rendering = nil
        end
    end
end

local function setLowPartsEnabled(enabled)
    GameBoostState.LowParts = enabled

    if enabled then
        task.spawn(function()
            walkBoostInstances(Workspace, function(instance)
                if not GameBoostState.LowParts then
                    return
                end

                if instance:IsA("BasePart") then
                    captureInstanceProperty(instance, "Material")
                    captureInstanceProperty(instance, "Reflectance")
                    captureInstanceProperty(instance, "CastShadow")

                    safeSetProperty(instance, "Material", Enum.Material.SmoothPlastic)
                    safeSetProperty(instance, "Reflectance", 0)
                    safeSetProperty(instance, "CastShadow", false)
                end
            end)
        end)
    else
        restoreInstanceProperties({ "Material", "Reflectance", "CastShadow" })
    end
end

local function setHideEffectsEnabled(enabled)
    GameBoostState.HideEffects = enabled

    if enabled then
        task.spawn(function()
            local function disableEffect(instance)
                if not GameBoostState.HideEffects then
                    return
                end

                if instance:IsA("ParticleEmitter")
                    or instance:IsA("Trail")
                    or instance:IsA("Beam")
                    or instance:IsA("Smoke")
                    or instance:IsA("Fire")
                    or instance:IsA("Sparkles")
                    or instance:IsA("BloomEffect")
                    or instance:IsA("BlurEffect")
                    or instance:IsA("SunRaysEffect")
                    or instance:IsA("DepthOfFieldEffect") then
                    captureInstanceProperty(instance, "Enabled")
                    safeSetProperty(instance, "Enabled", false)
                end
            end

            walkBoostInstances(Workspace, disableEffect)
            walkBoostInstances(Lighting, disableEffect)
        end)
    else
        restoreInstanceProperties({ "Enabled" })
    end
end

local function hasTreeKeywordInHierarchy(instance)
    local current = instance

    while current and current ~= Workspace do
        if containsAnyKeyword(current.Name, TreeKeywords) then
            return true
        end

        current = current.Parent
    end

    return false
end

local function removeGameTrees()
    if GameBoostState.TreesRemoved then
        return
    end

    GameBoostState.TreesRemoved = true

    task.spawn(function()
        walkBoostInstances(Workspace, function(instance)
            if not GameBoostState.TreesRemoved then
                return
            end

            if hasTreeKeywordInHierarchy(instance) then
                if instance:IsA("BasePart") then
                    captureInstanceProperty(instance, "Transparency")
                    captureInstanceProperty(instance, "CanCollide")
                    captureInstanceProperty(instance, "CanTouch")
                    captureInstanceProperty(instance, "CanQuery")
                    captureInstanceProperty(instance, "CastShadow")

                    safeSetProperty(instance, "Transparency", 1)
                    safeSetProperty(instance, "CanCollide", false)
                    safeSetProperty(instance, "CanTouch", false)
                    safeSetProperty(instance, "CanQuery", false)
                    safeSetProperty(instance, "CastShadow", false)
                elseif instance:IsA("Decal") or instance:IsA("Texture") then
                    captureInstanceProperty(instance, "Transparency")
                    safeSetProperty(instance, "Transparency", 1)
                elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") then
                    captureInstanceProperty(instance, "Enabled")
                    safeSetProperty(instance, "Enabled", false)
                end
            end
        end)
    end)
end

local function restoreGameBoots()
    GameBoostState.TreesRemoved = false
    setHideEffectsEnabled(false)
    setLowPartsEnabled(false)
    setFpsBoostEnabled(false)
    restoreInstanceProperties({ "Transparency", "CanCollide", "CanTouch", "CanQuery", "CastShadow", "Enabled" })
end

local TELEPORT_NO_LOCATION = "No Locations"
local TELEPORT_NO_CHEST = "No Chests"
local TELEPORT_NO_PLAYER = "No Players"
local TeleportState = {
    SelectedLocation = nil,
    SelectedChest = nil,
    SelectedPlayer = nil,
    LocationBind = Enum.KeyCode.T,
    ChestBind = Enum.KeyCode.Y,
}

assert(TeleportState.LocationBind == Enum.KeyCode.T, "Teleport location default key must be T")
assert(TeleportState.ChestBind == Enum.KeyCode.Y, "Teleport chest default key must be Y")

local TeleportLocationDropdown = nil
local TeleportLocationMap = {}
local TeleportLocationRefreshRunning = false
local TeleportChestDropdown = nil
local TeleportChestMap = {}
local TeleportChestRefreshRunning = false
local TeleportPlayerDropdown = nil
local TeleportPlayerMap = {}
local TeleportPlayerRefreshRunning = false

local TeleportLocationKeywords = {
    "apartment",
    "bridge",
    "building",
    "store",
    "woodbury",
    "car",
    "wreck",
    "cargo",
    "wagon",
    "easter",
    "farm",
    "gas",
    "station",
    "pitstop",
    "hay",
    "bale",
    "house",
    "hunting",
    "cabin",
    "hilltop",
    "town",
    "city",
    "prison",
    "hospital",
    "motel",
    "camp",
    "police",
    "church",
    "barn",
    "school",
    "warehouse",
    "garage",
    "diner",
    "shop",
    "tower",
}

local TeleportLocationBlockedKeywords = {
    "tree",
    "trees",
    "branch",
    "branches",
    "leaf",
    "leaves",
    "foliage",
    "bush",
    "forest",
    "grass",
    "rock",
    "stone",
    "road",
    "roadsegment",
    "fence",
    "fencepole",
    "border",
    "pack",
}

local TELEPORT_LOCATION_SCAN_RADIUS_STUDS = 3000
local TELEPORT_CHEST_SCAN_RADIUS_STUDS = 2200
local TELEPORT_SPATIAL_SCAN_MAX_PARTS = 1800

local TeleportExcludedNames = {
    baseplate = true,
    camera = true,
    terrain = true,
    humanoidrootpart = true,
    head = true,
    torso = true,
    uppertorso = true,
    lowertorso = true,
    leftarm = true,
    rightarm = true,
    leftleg = true,
    rightleg = true,
    leftupperarm = true,
    rightupperarm = true,
    leftlowerarm = true,
    rightlowerarm = true,
    leftupperleg = true,
    rightupperleg = true,
    leftlowerleg = true,
    rightlowerleg = true,
}

local function getPlayerNameSet()
    local names = {}

    for _, player in next, Players:GetPlayers() do
        names[lowerText(player.Name)] = true
    end

    return names
end

local function getTeleportSpatialParts(radius)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.MaxParts = TELEPORT_SPATIAL_SCAN_MAX_PARTS

    if LocalPlayer.Character then
        params.FilterDescendantsInstances = { LocalPlayer.Character }
    end

    local ok, parts = pcall(function()
        return Workspace:GetPartBoundsInRadius(getLocalOrigin(), radius, params)
    end)

    if ok and type(parts) == "table" then
        return parts
    end

    return {}
end

local function isTeleportLocationCandidate(instance, playerNameSet)
    if not instance or not instance:IsA("BasePart") then
        return false
    end

    local name = trimText(instance.Name)
    local lowerName = lowerText(name)

    if name == "" or TeleportExcludedNames[lowerName] or playerNameSet[lowerName] then
        return false
    end

    if containsAnyKeyword(name, TeleportLocationBlockedKeywords) then
        return false
    end

    if isCharacterLikeInstance(instance) then
        return false
    end

    return containsAnyKeyword(name, TeleportLocationKeywords)
end

local function getTeleportPlayerPart(player)
    local character = player and player.Character
    return getCharacterRoot(character) or getBestPartFromModel(character)
end

local function refreshTeleportPlayerList()
    if TeleportPlayerRefreshRunning then
        return
    end

    TeleportPlayerRefreshRunning = true
    clearTableValues(TeleportPlayerMap)

    local entries = {}
    local origin = getLocalOrigin()

    for _, player in next, Players:GetPlayers() do
        local playerName = trimText(player.Name)
        local playerPart = getTeleportPlayerPart(player)

        if playerName ~= "" and playerPart then
            entries[#entries + 1] = {
                Label = playerName,
                Player = player,
                Distance = roundNumber(studsToMeters((playerPart.Position - origin).Magnitude), 1),
            }
        end
    end

    table.sort(entries, function(a, b)
        if a.Distance ~= b.Distance then
            return a.Distance < b.Distance
        end

        return lowerText(a.Label) < lowerText(b.Label)
    end)

    local names = {}

    for _, entry in next, entries do
        local label = entry.Label .. " - " .. tostring(entry.Distance) .. "m"
        local baseLabel = label
        local duplicateIndex = 2

        while TeleportPlayerMap[label] do
            label = baseLabel .. " (" .. tostring(duplicateIndex) .. ")"
            duplicateIndex = duplicateIndex + 1
        end

        TeleportPlayerMap[label] = entry.Player
        names[#names + 1] = label
    end

    if #names == 0 then
        names[1] = TELEPORT_NO_PLAYER
        TeleportState.SelectedPlayer = nil
    elseif not TeleportPlayerMap[TeleportState.SelectedPlayer] then
        TeleportState.SelectedPlayer = names[1]
    end

    if TeleportPlayerDropdown then
        TeleportPlayerDropdown:Refresh(names, true)
    end

    TeleportPlayerRefreshRunning = false
end

local function isTeleportChestName(name)
    return string.sub(lowerText(name), 1, 5) == "loot_"
end

local function refreshTeleportLocationList()
    if TeleportLocationRefreshRunning then
        return
    end

    TeleportLocationRefreshRunning = true
    clearTableValues(TeleportLocationMap)

    local playerNameSet = getPlayerNameSet()
    local names = {}
    local seenNames = {}

    for _, instance in next, getTeleportSpatialParts(TELEPORT_LOCATION_SCAN_RADIUS_STUDS) do
        if isTeleportLocationCandidate(instance, playerNameSet) then
            local baseName = trimText(instance.Name)
            local key = lowerText(baseName)

            if not seenNames[key] then
                seenNames[key] = true
                TeleportLocationMap[baseName] = instance
                names[#names + 1] = baseName
            end
        end
    end

    table.sort(names, function(a, b)
        return lowerText(a) < lowerText(b)
    end)

    if #names == 0 then
        names[1] = TELEPORT_NO_LOCATION
        TeleportState.SelectedLocation = nil
    elseif not TeleportLocationMap[TeleportState.SelectedLocation] then
        TeleportState.SelectedLocation = names[1]
    end

    if TeleportLocationDropdown then
        TeleportLocationDropdown:Refresh(names, true)
    end

    TeleportLocationRefreshRunning = false
end

local function isTeleportChestCandidate(instance)
    if not instance or isCharacterLikeInstance(instance) then
        return false
    end

    if instance:IsA("Model") or instance:IsA("BasePart") then
        return isTeleportChestName(instance.Name)
    end

    return false
end

local function getTeleportChestRoot(instance)
    local current = instance

    while current and current ~= Workspace do
        if current:IsA("Model") and isTeleportChestCandidate(current) then
            return current
        end

        current = current.Parent
    end

    if isTeleportChestCandidate(instance) then
        return instance
    end

    return nil
end

local function getReadableTeleportChestName(chest)
    local name = getModelTypeName(chest, chest and chest.Name or "")
    name = name:gsub("^Loot_", "")
    name = name:gsub("^loot_", "")
    name = name:gsub("_", " ")
    name = name:gsub("(%l)(%u)", "%1 %2")
    name = trimText(name)

    if name == "" and chest then
        return chest.Name
    end

    return name
end

local function refreshTeleportChestList()
    if TeleportChestRefreshRunning then
        return
    end

    TeleportChestRefreshRunning = true
    clearTableValues(TeleportChestMap)

    local entries = {}
    local seenInstances = {}
    local origin = getLocalOrigin()

    for _, instance in next, getTeleportSpatialParts(TELEPORT_CHEST_SCAN_RADIUS_STUDS) do
        local chest = getTeleportChestRoot(instance)

        if chest and chest.Parent and not seenInstances[chest] then
            local position = getDisplayPosition(chest, 0)

            if position then
                seenInstances[chest] = true
                entries[#entries + 1] = {
                    Instance = chest,
                    Name = getReadableTeleportChestName(chest),
                    Distance = roundNumber(studsToMeters((position - origin).Magnitude), 1),
                }
            end
        end
    end

    table.sort(entries, function(a, b)
        if a.Distance ~= b.Distance then
            return a.Distance < b.Distance
        end

        return lowerText(a.Name) < lowerText(b.Name)
    end)

    local names = {}
    local nameTotals = {}
    local nameIndexes = {}

    for _, entry in next, entries do
        nameTotals[entry.Name] = (nameTotals[entry.Name] or 0) + 1
    end

    for _, entry in next, entries do
        nameIndexes[entry.Name] = (nameIndexes[entry.Name] or 0) + 1

        local label = entry.Name
        if nameTotals[entry.Name] > 1 then
            label = label .. " #" .. tostring(nameIndexes[entry.Name])
        end

        label = label .. " - " .. tostring(entry.Distance) .. "m"

        local baseLabel = label
        local duplicateIndex = 2
        while TeleportChestMap[label] do
            label = baseLabel .. " (" .. tostring(duplicateIndex) .. ")"
            duplicateIndex = duplicateIndex + 1
        end

        TeleportChestMap[label] = entry.Instance
        names[#names + 1] = label
    end

    if #names == 0 then
        names[1] = TELEPORT_NO_CHEST
        TeleportState.SelectedChest = nil
    elseif not TeleportChestMap[TeleportState.SelectedChest] then
        TeleportState.SelectedChest = names[1]
    end

    if TeleportChestDropdown then
        TeleportChestDropdown:Refresh(names, true)
    end

    TeleportChestRefreshRunning = false
end

local function getLocalTeleportRoot()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = getCharacterRoot(character) or getBestPartFromModel(character)

    return character, root
end

local function clearTeleportVelocity(root)
    if not root then
        return
    end

    safeSetProperty(root, "AssemblyLinearVelocity", Vector3.zero)
    safeSetProperty(root, "AssemblyAngularVelocity", Vector3.zero)
end

local function teleportToLocation(locationPart)
    if not locationPart or not locationPart.Parent then
        return false
    end

    local character, root = getLocalTeleportRoot()
    if not character or not root then
        return false
    end

    local yOffset = math.max((locationPart.Size.Y * 0.5) + 6, 8)
    local destination = locationPart.CFrame + Vector3.new(0, yOffset, 0)

    local pivotOk = pcall(function()
        character:PivotTo(destination)
    end)

    pcall(function()
        root.CFrame = destination
    end)

    clearTeleportVelocity(root)
    return pivotOk
end

local function getChestTeleportCFrame(chest)
    if not chest then
        return nil
    end

    if chest:IsA("BasePart") then
        local yOffset = math.max((chest.Size.Y * 0.5) + 5, 6)
        return chest.CFrame + Vector3.new(0, yOffset, 0)
    end

    if chest:IsA("Model") then
        local ok, boxCFrame, boxSize = pcall(function()
            return chest:GetBoundingBox()
        end)

        if ok and boxCFrame and boxSize then
            local yOffset = math.max((boxSize.Y * 0.5) + 5, 6)
            return boxCFrame + Vector3.new(0, yOffset, 0)
        end

        local part = getBestPartFromModel(chest)
        if part then
            local yOffset = math.max((part.Size.Y * 0.5) + 5, 6)
            return part.CFrame + Vector3.new(0, yOffset, 0)
        end
    end

    return nil
end

local function teleportToChest(chest)
    if not chest or not chest.Parent then
        return false
    end

    local destination = getChestTeleportCFrame(chest)
    if not destination then
        return false
    end

    local character, root = getLocalTeleportRoot()
    if not character or not root then
        return false
    end

    local pivotOk = pcall(function()
        character:PivotTo(destination)
    end)

    pcall(function()
        root.CFrame = destination
    end)

    clearTeleportVelocity(root)
    return pivotOk
end

local function teleportToSelectedLocation()
    local selected = TeleportState.SelectedLocation
    local locationPart = selected and TeleportLocationMap[selected]

    if not locationPart or not locationPart.Parent then
        return false
    end

    return teleportToLocation(locationPart)
end

local function teleportToSelectedPlayer()
    local selected = TeleportState.SelectedPlayer
    local player = selected and TeleportPlayerMap[selected]
    local playerPart = getTeleportPlayerPart(player)

    if not playerPart or not playerPart.Parent then
        return false
    end

    return teleportToLocation(playerPart)
end

local function teleportToSelectedChest()
    local selected = TeleportState.SelectedChest
    local chest = selected and TeleportChestMap[selected]

    if not chest or not chest.Parent then
        return false
    end

    return teleportToChest(chest)
end

local function isTeleportLocationInput(input)
    return input.UserInputType == TeleportState.LocationBind or input.KeyCode == TeleportState.LocationBind
end

local function isTeleportChestInput(input)
    return input.UserInputType == TeleportState.ChestBind or input.KeyCode == TeleportState.ChestBind
end

local function setTeleportLocationBind(key)
    if typeof(key) ~= "EnumItem" then
        return
    end

    TeleportState.LocationBind = key
end

local function setTeleportChestBind(key)
    if typeof(key) ~= "EnumItem" then
        return
    end

    TeleportState.ChestBind = key
end

_G._twdoTeleportLocationInputBegan = UserInputService.InputBegan:Connect(function(input)
    if UserInputService:GetFocusedTextBox() then
        return
    end

    if isTeleportLocationInput(input) then
        teleportToSelectedLocation()
    end
end)

_G._twdoTeleportChestInputBegan = UserInputService.InputBegan:Connect(function(input)
    if UserInputService:GetFocusedTextBox() then
        return
    end

    if isTeleportChestInput(input) then
        teleportToSelectedChest()
    end
end)

local function CreateMainTab(self)
    local TabMain = self:Tab({
        Title = "Main",
        Desc = "Core controls",
        Icon = "crosshair",
    })

    local SectionAim = TabMain:Section({
        Title = "Aim Lock",
        Desc = "Hold to lock target",
        Icon = "target",
        Side = "left",
    })

    SectionAim:Toggle({
        Title = "Aimbot",
        Icon = "crosshair",
        Value = false,
        Callback = function(state)
            AimState.Enabled = state
            if not state then
                AimState.Holding = false
                AimCurrentTarget = nil
            end
            refreshAimLoop()
        end,
    })

    SectionAim:Keybind({
        Title = "Aimbot Hold Key",
        Desc = "Default right-click",
        Default = Enum.UserInputType.MouseButton2,
        Callback = function()
        end,
        ChangedCallback = function(key)
            setAimHoldBind(key)
        end,
    })

    SectionAim:Dropdown({
        Title = "Target Type",
        Values = { "Player", "Monster" },
        Default = "Player",
        Callback = function(value)
            AimState.TargetType = value
            AimMonsterRefreshAt = 0
            AimCurrentTarget = nil
            if value == "Monster" then
                resetSharedMonsterTargets()
            end
        end,
    })

    SectionAim:Dropdown({
        Title = "Target Part",
        Values = { "Head", "Body", "Random" },
        Default = "Head",
        Callback = function(value)
            AimState.TargetPart = value
        end,
    })

    SectionAim:Toggle({
        Title = "Smoothing",
        Desc = "Smooth camera movement",
        Icon = "waves",
        Value = true,
        Callback = function(state)
            AimState.Smoothing = state
        end,
    })

    SectionAim:Slider({
        Title = "Smooth Speed",
        Desc = "Higher = faster aim",
        Value = {
            Min = 0.05,
            Max = 1,
            Default = 0.18,
        },
        Step = 0.01,
        Callback = function(value)
            AimState.SmoothingFactor = value
        end,
    })

    SectionAim:Toggle({
        Title = "Prediction",
        Desc = "Predict target movement",
        Icon = "crosshair",
        Value = true,
        Callback = function(state)
            AimState.Prediction = state
        end,
    })

    SectionAim:Slider({
        Title = "Prediction Strength",
        Desc = "Prediction time multiplier",
        Value = {
            Min = 0.05,
            Max = 0.5,
            Default = 0.12,
        },
        Step = 0.01,
        Callback = function(value)
            AimState.PredictionStrength = value
        end,
    })

    SectionAim:Toggle({
        Title = "Sticky Target",
        Desc = "Keep locked on same target",
        Icon = "link",
        Value = true,
        Callback = function(state)
            AimState.StickyTarget = state
            if not state then
                AimCurrentTarget = nil
            end
        end,
    })

    SectionAim:Toggle({
        Title = "Visibility Check",
        Desc = "Only aim at visible targets",
        Icon = "eye",
        Value = true,
        Callback = function(state)
            AimState.VisibilityCheck = state
        end,
    })

    local SectionFOV = TabMain:Section({
        Title = "FOV",
        Desc = "Range control",
        Icon = "circle-dot",
        Side = "right",
    })

    SectionFOV:Toggle({
        Title = "FOV System",
        Icon = "radar",
        Value = false,
        Callback = function(state)
            AimState.UseFOV = state
            if not state and FOVCircle then
                FOVCircle.Visible = false
            end
            refreshAimLoop()
        end,
    })

    SectionFOV:Slider({
        Title = "FOV Size",
        Value = {
            Min = 30,
            Max = 500,
            Default = 120,
        },
        Step = 1,
        Callback = function(value)
            AimState.FOVRadius = value
            if FOVCircle then
                FOVCircle.Radius = value
            end
        end,
    })

    local SectionESP = TabMain:Section({
        Title = "ESP",
        Desc = "Player, zombie and chest info",
        Icon = "eye",
        Side = "right",
    })

    SectionESP:Toggle({
        Title = "Player ESP",
        Icon = "users",
        Value = false,
        Callback = function(state)
            ESPState.Player.Enabled = state
            if not state then
                clearDrawingMap(ESPDrawings.Player)
            end
            refreshESPConnection()
        end,
    })

    SectionESP:Toggle({
        Title = "Zombie ESP",
        Icon = "skull",
        Value = false,
        Callback = function(state)
            ESPState.Monster.Enabled = state
            if not state then
                clearDrawingMap(ESPDrawings.Monster)
                MonsterTargets = {}
                if AimState.TargetType ~= "Monster" then
                    resetSharedMonsterTargets()
                end
            end
            refreshESPConnection()
        end,
    })

    SectionESP:Toggle({
        Title = "Chest ESP",
        Icon = "package",
        Value = false,
        Callback = function(state)
            ESPState.Chest.Enabled = state
            if not state then
                clearDrawingMap(ESPDrawings.Chest)
                ChestTargets = {}
                resetSharedChestTargets()
                clearTableValues(ChestInfoCache)
            end
            refreshESPConnection()
        end,
    })

    SectionESP:Slider({
        Title = "Max Distance",
        Desc = "ESP render distance (studs)",
        Value = {
            Min = 500,
            Max = 5000,
            Default = 2500,
        },
        Step = 100,
        Callback = function(value)
            ESP_MAX_DISTANCE_STUDS = value
        end,
    })

    SectionESP:Slider({
        Title = "Max Visible",
        Desc = "Max items to show per type",
        Value = {
            Min = 10,
            Max = 100,
            Default = 50,
        },
        Step = 5,
        Callback = function(value)
            ESP_MAX_VISIBLE_ITEMS = value
        end,
    })

    SectionESP:Toggle({
        Title = "Night ESP",
        Desc = "Night vision mode",
        Icon = "moon",
        Value = false,
        Callback = function(state)
            setNightVisionEnabled(state)
        end,
    })
end

local function CreateGameBootsTab(self)
    local TabGameBoots = self:Tab({
        Title = "Game Boots",
        Desc = "FPS and visual tweaks",
        Icon = "zap",
    })

    local SectionPerformance = TabGameBoots:Section({
        Title = "Performance",
        Desc = "Client-side boost controls",
        Icon = "gauge",
        Side = "left",
    })

    SectionPerformance:Toggle({
        Title = "FPS Boost",
        Desc = "Lower shadows, water and quality",
        Icon = "zap",
        Value = false,
        Callback = function(state)
            setFpsBoostEnabled(state)
        end,
    })

    SectionPerformance:Toggle({
        Title = "Low Parts",
        Desc = "Smooth parts and remove cast shadows",
        Icon = "box",
        Value = false,
        Callback = function(state)
            setLowPartsEnabled(state)
        end,
    })

    SectionPerformance:Toggle({
        Title = "Hide Effects",
        Desc = "Disable particles, beams and post effects",
        Icon = "sparkles",
        Value = false,
        Callback = function(state)
            setHideEffectsEnabled(state)
        end,
    })

    SectionPerformance:Button({
        Title = "Remove Trees",
        Desc = "Hide tree objects locally",
        Description = "Hide tree objects locally",
        Color = Color3.fromRGB(20, 95, 45),
        Icon = "tree-pine",
        Callback = function()
            removeGameTrees()
        end,
    })

    local SectionRestore = TabGameBoots:Section({
        Title = "Restore",
        Desc = "Return visual settings",
        Icon = "rotate-ccw",
        Side = "right",
    })

    SectionRestore:Button({
        Title = "Restore Visuals",
        Desc = "Restore cached graphics settings",
        Description = "Restore cached graphics settings",
        Icon = "rotate-ccw",
        Callback = function()
            restoreGameBoots()
        end,
    })
end

local function CreateTeleportTab(self)
    local TabTeleport = self:Tab({
        Title = "Teleport",
        Desc = "Movement tools",
        Icon = "navigation",
    })

    local SectionLocation = TabTeleport:Section({
        Title = "Location Teleport",
        Desc = "Teleport to Workspace locations",
        Icon = "map-pin",
        Side = "left",
    })

    TeleportLocationDropdown = SectionLocation:Dropdown({
        Title = "Select Location",
        Values = { TELEPORT_NO_LOCATION },
        Default = TELEPORT_NO_LOCATION,
        Callback = function(value)
            if TeleportLocationMap[value] then
                TeleportState.SelectedLocation = value
            else
                TeleportState.SelectedLocation = nil
            end
        end,
    })

    SectionLocation:Button({
        Title = "Teleport Location",
        Desc = "Teleport to selected location",
        Description = "Teleport to selected location",
        Color = Color3.fromRGB(210, 35, 35),
        Icon = "navigation",
        Callback = function()
            teleportToSelectedLocation()
        end,
    })

    SectionLocation:Keybind({
        Title = "Teleport Hotkey",
        Desc = "Press to teleport selected location",
        Default = Enum.KeyCode.T,
        Callback = function()
            teleportToSelectedLocation()
        end,
        ChangedCallback = function(key)
            setTeleportLocationBind(key)
        end,
    })

    SectionLocation:Button({
        Title = "Refresh Locations",
        Desc = "Refresh location dropdown",
        Description = "Refresh location dropdown",
        Color = Color3.fromRGB(255, 255, 255),
        Icon = "refresh-cw",
        Callback = function()
            task.spawn(refreshTeleportLocationList)
        end,
    })

    local SectionPlayer = TabTeleport:Section({
        Title = "Player Teleport",
        Desc = "Teleport to player markers",
        Icon = "users",
        Side = "left",
    })

    TeleportPlayerDropdown = SectionPlayer:Dropdown({
        Title = "Select Player",
        Values = { TELEPORT_NO_PLAYER },
        Default = TELEPORT_NO_PLAYER,
        Callback = function(value)
            if TeleportPlayerMap[value] then
                TeleportState.SelectedPlayer = value
            else
                TeleportState.SelectedPlayer = nil
            end
        end,
    })

    SectionPlayer:Button({
        Title = "Teleport Player",
        Desc = "Teleport to selected player",
        Description = "Teleport to selected player",
        Color = Color3.fromRGB(210, 35, 35),
        Icon = "user-round",
        Callback = function()
            teleportToSelectedPlayer()
        end,
    })

    SectionPlayer:Button({
        Title = "Refresh Players",
        Desc = "Refresh player dropdown",
        Description = "Refresh player dropdown",
        Color = Color3.fromRGB(255, 255, 255),
        Icon = "refresh-cw",
        Callback = function()
            task.spawn(refreshTeleportPlayerList)
        end,
    })

    local SectionChest = TabTeleport:Section({
        Title = "Chest Teleport",
        Desc = "Teleport to loot chests",
        Icon = "package",
        Side = "right",
    })

    TeleportChestDropdown = SectionChest:Dropdown({
        Title = "Select Chest",
        Values = { TELEPORT_NO_CHEST },
        Default = TELEPORT_NO_CHEST,
        Callback = function(value)
            if TeleportChestMap[value] then
                TeleportState.SelectedChest = value
            else
                TeleportState.SelectedChest = nil
            end
        end,
    })

    SectionChest:Button({
        Title = "Teleport Chest",
        Desc = "Teleport to selected loot chest",
        Description = "Teleport to selected loot chest",
        Color = Color3.fromRGB(210, 35, 35),
        Icon = "package-open",
        Callback = function()
            teleportToSelectedChest()
        end,
    })

    SectionChest:Keybind({
        Title = "Chest Hotkey",
        Desc = "Press to teleport selected chest",
        Default = Enum.KeyCode.Y,
        Callback = function()
            teleportToSelectedChest()
        end,
        ChangedCallback = function(key)
            setTeleportChestBind(key)
        end,
    })

    SectionChest:Button({
        Title = "Refresh Chests",
        Desc = "Refresh chest dropdown",
        Description = "Refresh chest dropdown",
        Color = Color3.fromRGB(255, 255, 255),
        Icon = "refresh-cw",
        Callback = function()
            task.spawn(refreshTeleportChestList)
        end,
    })
end

function Window:InitBaseTabs()
    CreateMainTab(self)
    CreateGameBootsTab(self)
    CreateTeleportTab(self)

    if OriginalInitBaseTabs then
        OriginalInitBaseTabs(self)
    end
end

Window:InitBaseTabs()
