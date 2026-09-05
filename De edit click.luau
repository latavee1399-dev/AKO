repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if game.PlaceId == 99421106727783 then
    pcall(function()
        local Event = game:GetService("ReplicatedStorage").Remotes.AFKServer
        Event:FireServer(
            "LeaveButton"
        )
    end)
    game:GetService("TeleportService"):Teleport(3351674303, LocalPlayer)
    return
end

repeat task.wait() until LocalPlayer.Character and LocalPlayer:FindFirstChild("PlayerGui")

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

if game.PlaceId == 3351674303 then
    task.spawn(function()
        while task.wait(1) do
            if game.PlaceId == 99421106727783 then
                pcall(function()
                    local Event = game:GetService("ReplicatedStorage").Remotes.AFKServer
                    Event:FireServer(
                        "LeaveButton"
                    )
                end)
                game:GetService("TeleportService"):Teleport(3351674303, LocalPlayer)
            end
        end
    end)
end

local Camera = Workspace.CurrentCamera

local UserConfig = (getgenv and getgenv().Config) or _G.Config or {}
local TargetMiles = UserConfig.TargetMiles or 100
local EnableAutoFarm = UserConfig.EnableAutoFarm
if EnableAutoFarm == nil then EnableAutoFarm = true end
local EnableWhiteScreen = UserConfig.WhiteScreen or false
local EnableSuperBoostFPS = UserConfig.SuperBoostFPS or false
local EnableAntiLag = UserConfig.AntiLag
if EnableAntiLag == nil then EnableAntiLag = true end
local EnableBlockAFKServerTeleport = UserConfig.BlockAFKServerTeleport
if EnableBlockAFKServerTeleport == nil then EnableBlockAFKServerTeleport = true end
local AntiAfkInputInterval = tonumber(UserConfig.AntiAfkInputInterval) or 60

if EnableWhiteScreen then
    task.spawn(function()
        local RunService = game:GetService("RunService")
        pcall(function() RunService:Set3dRenderingEnabled(false) end)
        local gui = Instance.new("ScreenGui")
        gui.Name = "WhiteScreen"
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        local frame = Instance.new("Frame")
        frame.BackgroundColor3 = Color3.new(1, 1, 1)
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.Parent = gui
        pcall(function()
            gui.Parent = game:GetService("CoreGui")
        end)
        if not gui.Parent then
            gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
    end)
end

if EnableSuperBoostFPS then
    task.spawn(function()
        local Lighting = game:GetService("Lighting")
        local Terrain = Workspace.Terrain

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        pcall(function() sethiddenproperty(Lighting, "Technology", 2) end)

        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0

        Lighting:ClearAllChildren()

        local function applyFPSBoost(v)
            if v:IsA("BasePart") and not v:IsA("MeshPart") then
                v.Material = "Plastic"
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            elseif v:IsA("Explosion") then
                v.BlastPressure = 1
                v.BlastRadius = 1
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            elseif v:IsA("MeshPart") then
                v.Material = "Plastic"
                v.Reflectance = 0
            end
        end

        for i, v in pairs(Workspace:GetDescendants()) do
            applyFPSBoost(v)
        end

        Workspace.DescendantAdded:Connect(applyFPSBoost)
    end)
end

-- Anti-Lag System (ลดแลคเพิ่มเติม)
if EnableAntiLag then
    task.spawn(function()
        local RunService = game:GetService("RunService")
        local Players = game:GetService("Players")
        local Workspace = game:GetService("Workspace")

        -- ปิด 3D Rendering ถ้าใช้ WhiteScreen
        if EnableWhiteScreen then
            pcall(function()
                RunService:Set3dRenderingEnabled(false)
            end)
        end

        -- ตั้งค่า Graphics Quality ต่ำสุด
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)

        -- ลบ Sound Effects ที่ไม่จำเป็น
        task.spawn(function()
            for _, sound in pairs(Workspace:GetDescendants()) do
                if sound:IsA("Sound") then
                    sound.Volume = 0
                    sound:Stop()
                end
            end

            Workspace.DescendantAdded:Connect(function(sound)
                if sound:IsA("Sound") then
                    sound.Volume = 0
                    sound:Stop()
                end
            end)
        end)

        -- ซ่อนตัวละครผู้เล่นอื่นเพื่อลด Rendering
        task.spawn(function()
            local function hidePlayer(player)
                if player ~= LocalPlayer then
                    local char = player.Character or player.CharacterAdded:Wait()
                    pcall(function()
                        for _, part in pairs(char:GetDescendants()) do
                            if part:IsA("BasePart") or part:IsA("Decal") or part:IsA("Texture") then
                                part.Transparency = 1
                            elseif part:IsA("Accessory") or part:IsA("Hat") then
                                part:Destroy()
                            end
                        end
                    end)
                end
            end

            for _, player in pairs(Players:GetPlayers()) do
                task.spawn(hidePlayer, player)
            end

            Players.PlayerAdded:Connect(function(player)
                player.CharacterAdded:Connect(function()
                    hidePlayer(player)
                end)
            end)
        end)

        -- ลบ Effects และ GUI ที่ไม่จำเป็น
        task.spawn(function()
            pcall(function()
                local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
                for _, gui in pairs(PlayerGui:GetChildren()) do
                    if gui.Name ~= "MainHUD" and gui.Name ~= "LoadingUI" and gui.Name ~= "WhiteScreen" then
                        pcall(function()
                            if gui:IsA("ScreenGui") then
                                gui.Enabled = false
                            end
                        end)
                    end
                end
            end)
        end)

        -- Memory Management - Clear Cache ทุก 30 วินาที
        task.spawn(function()
            while task.wait(30) do
                pcall(function()
                    for _, v in pairs(Workspace:GetDescendants()) do
                        if v:IsA("Part") and not v:IsDescendantOf(LocalPlayer.Character) and not v:IsDescendantOf(GetCurrentVehicle() or {}) then
                            if (v.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 500 then
                                v.CanCollide = false
                                v.Transparency = 1
                            end
                        end
                    end
                end)
            end
        end)
    end)
end

local AutoFarm = EnableAutoFarm
local TouchTheRoad = false
local AutoFarmRunning = false
local LastNotif = 0
local LastAntiAfkInput = 0
local AFKTeleportReasons = {
	["Idle Auto-Teleport"] = true,
	["Idle Detection"] = true,
}

local function GetCurrentVehicle()
	local Char = LocalPlayer.Character
	if Char and Char:FindFirstChild("Humanoid") then
		local SeatPart = Char.Humanoid.SeatPart
		if SeatPart then
			return SeatPart.Parent
		end
	end
	return nil
end

local function IsAFKTeleportReason(Reason)
	return AFKTeleportReasons[Reason] == true
end

assert(IsAFKTeleportReason("Idle Auto-Teleport") and not IsAFKTeleportReason("LeaveButton"), "AFK reason filter failed")

local function DisableRobloxIdleConnections()
	if not getconnections then
		return
	end

	for _, Connection in next, getconnections(LocalPlayer.Idled) do
		pcall(function()
			Connection:Disable()
		end)
	end
end

local function InstallAFKServerBlock()
	if not EnableBlockAFKServerTeleport then
		return
	end

	pcall(function()
		local PlayerIdleDetectionController = require(ReplicatedStorage.Modules.Client.AFK.PlayerIdleDetectionController)
		local Signals = { "PlayerIdle", "PlayerAFK" }

		for _, SignalName in next, Signals do
			local Signal = PlayerIdleDetectionController[SignalName]
			if type(Signal) == "table" then
				Signal.Fire = function() end
				if type(Signal.Connections) == "table" then
					table.clear(Signal.Connections)
				end
			end
		end
	end)

	pcall(function()
		if not hookmetamethod or not getnamecallmethod or not newcclosure then
			return
		end

		local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local AFKServer = Remotes and Remotes:FindFirstChild("AFKServer")
		if not AFKServer then
			return
		end

		local ENV = (getgenv and getgenv()) or _G
		if ENV.DE_AFK_SERVER_BLOCK_HOOKED then
			return
		end
		ENV.DE_AFK_SERVER_BLOCK_HOOKED = true

		local OldNamecall
		OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(Self, ...)
			local Args = { ... }
			local Method = getnamecallmethod()
			local FromExecutor = checkcaller and checkcaller()

			if not FromExecutor and Self == AFKServer and Method == "FireServer" and IsAFKTeleportReason(Args[1]) then
				return nil
			end

			return OldNamecall(Self, ...)
		end))
	end)
end

local function SendAntiAfkInput(Force)
	local Now = os.clock()
	if not Force and Now - LastAntiAfkInput < AntiAfkInputInterval then
		return
	end
	LastAntiAfkInput = Now

	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
		task.wait()
		VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
	end)

	pcall(function()
		local VirtualInputManager = game:GetService("VirtualInputManager")
		local Offset = math.floor(Now) % 2
		local MouseLocation = UserInputService:GetMouseLocation()
		VirtualInputManager:SendMouseMoveEvent(MouseLocation.X + Offset, MouseLocation.Y, game)
	end)
end

DisableRobloxIdleConnections()
InstallAFKServerBlock()
SendAntiAfkInput(true)

task.spawn(function()
	while task.wait(AntiAfkInputInterval) do
		local ENV = (getgenv and getgenv()) or _G
		if AutoFarm or ENV.DY_DELIVERY_FARM_ENABLED == true then
			SendAntiAfkInput(true)
		end
	end
end)

local function TP(cframe)
	local Vehicle = GetCurrentVehicle()
	if Vehicle and Vehicle.PrimaryPart then
		Vehicle:SetPrimaryPartCFrame(cframe)
	end
end

local function VelocityTP(cframe)
	local Vehicle = GetCurrentVehicle()
	if not Vehicle or not Vehicle.PrimaryPart then
		return
	end

	local TeleportSpeed = math.random(700, 700)
	local PrimaryPart = Vehicle.PrimaryPart

	local BodyGyro = Instance.new("BodyGyro", PrimaryPart)
	BodyGyro.P = 5000
	BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	BodyGyro.CFrame = PrimaryPart.CFrame

	local BodyVelocity = Instance.new("BodyVelocity", PrimaryPart)
	BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	BodyVelocity.Velocity = CFrame.new(PrimaryPart.Position, cframe.Position).LookVector * TeleportSpeed

	task.wait((PrimaryPart.Position - cframe.Position).Magnitude / TeleportSpeed)
	BodyVelocity.Velocity = Vector3.new()

	task.wait(0.1)
	BodyVelocity:Destroy()
	BodyGyro:Destroy()
end

local EndPosition = CFrame.new(Vector3.new(-34567.375, 34.895652770996094, -32846.046875), Vector3.new())
local StartPosition = CFrame.new(Vector3.new(-31448.3515625, 34.925010681152344, -26616.25), Vector3.new())

function ClickGui(v__1)
	local v__2 = {"Activated", "MouseButton1Down", "MouseButton1Click", "MouseButton1Up"}
	for _, v__3 in next, v__2 do
		pcall(function()
			if v__1[v__3] then
				for _, v__4 in next, getconnections(v__1[v__3]) do
					v__4.Function()
				end
			end
		end)
	end
end

--game:GetService("Players").LocalPlayer.PlayerGui.Loading.Menu.Main.Play

task.spawn(function() 
    while task.wait() do 
		local Load = LocalPlayer.PlayerGui:FindFirstChild("LoadingUI")
        if Load and Load.Enabled then 
            ClickGui(LocalPlayer.PlayerGui.LoadingUI.Menu.Main.Play)
        end 
		if LocalPlayer.PlayerGui.MainHUD.StarterCars.Visible then 
			ClickGui(LocalPlayer.PlayerGui.MainHUD.StarterCars.StarterCarsWindow.InnerFrame.CarList["McLaren-600LTCoupe"].SelectionCanvas.SelectionFrame.Button)
		end
    end 
end)

task.spawn(function()
	while task.wait() do
		if not AutoFarm then
			AutoFarmRunning = false
			continue
		end
		AutoFarmRunning = true
		SendAntiAfkInput()
		pcall(function()
			local Vehicle = GetCurrentVehicle()
			if not Vehicle then
				if tick() - LastNotif > 5 then
					LastNotif = tick()
					LocalPlayer.Character.HumanoidRootPart.CFrame = EndPosition
					ReplicatedStorage.Remotes.VehicleEvent:FireServer("Spawn","McLaren-600LTCoupe")
				end
				return
			end
			TP(StartPosition + Vector3.new(0, -3, 0))
			VelocityTP(EndPosition + Vector3.new(0, -3, 0))
			TP(EndPosition + Vector3.new(0, -3, 0))
			VelocityTP(StartPosition + Vector3.new(0, -3, 0))
		end)
	end
end)

-- ฟังก์ชัน Auto Delivery แบบสมบูรณ์
local function AutoDelivery()
    local ENV = (getgenv and getgenv()) or _G

    local DEFAULT_CONFIG = {
        TeleportHeight = 4,
        AfterTeleportDelay = 0.35,           -- ลดจาก 0.75 เป็น 0.35
        AfterLeaveDelay = 0.25,              -- ลดจาก 0.6 เป็น 0.25
        StatePollDelay = 0.1,                -- ลดจาก 0.2 เป็น 0.1
        LoopDelay = 0.2,                     -- ลดจาก 0.5 เป็น 0.2
        InteractDelay = 0.5,                 -- ลดจาก 1.0 เป็น 0.5
        StartTimeout = 8,
        CollectTimeout = 10,                 -- ลดจาก 14 เป็น 10
        DropTimeout = 8,                     -- ลดจาก 12 เป็น 8
        NextStateTimeout = 4,                -- ลดจาก 6 เป็น 4
        UseDirectFunctions = true,           -- เปิดใช้งาน direct functions
        UseDirectPickupFunction = true,      -- เปิดใช้งาน direct pickup
        UseDirectCompleteFunction = true,    -- เปิดใช้งาน direct complete
        MinDropoffWait = 8.0,                -- ลดจาก 10.5 เป็น 8.0
        CollectingStopTimeout = 2,           -- ลดจาก 4 เป็น 2
        QuitOtherJobs = true,
        AntiAfk = true,
        Debug = false,                       -- ปิด debug เพื่อลด overhead
        UseRandomDelay = true,               -- เพิ่ม: ใช้ระบบ random delay
        RandomDelayMin = 0.05,               -- เพิ่ม: delay ต่ำสุด
        RandomDelayMax = 0.15,               -- เพิ่ม: delay สูงสุด
    }

    ENV.DY_DELIVERY_FARM_CONFIG = ENV.DY_DELIVERY_FARM_CONFIG or {}
    local CONFIG = ENV.DY_DELIVERY_FARM_CONFIG
    for key, value in pairs(DEFAULT_CONFIG) do
        if CONFIG[key] == nil then
            CONFIG[key] = value
        end
    end

    local runId = tostring(os.clock()) .. ":" .. tostring(math.random(1, 1e9))
    ENV.DY_DELIVERY_FARM_ENABLED = true
    ENV.DY_DELIVERY_FARM_RUN_ID = runId

    local function isEnabled()
        return ENV.DY_DELIVERY_FARM_ENABLED == true and ENV.DY_DELIVERY_FARM_RUN_ID == runId
    end

    local function randomDelay()
        if CONFIG.UseRandomDelay then
            local delay = CONFIG.RandomDelayMin + math.random() * (CONFIG.RandomDelayMax - CONFIG.RandomDelayMin)
            task.wait(delay)
        end
    end

    local function log(...)
        -- Disabled: if CONFIG.Debug then print("[Dy Delivery]", ...) end
    end

    local function warnLog(...)
        -- Disabled: warn("[Dy Delivery]", ...)
    end

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local CollectionService = game:GetService("CollectionService")
    local Workspace = game:GetService("Workspace")
    local VirtualUser = game:GetService("VirtualUser")

    local LocalPlayer = Players.LocalPlayer
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")

    local RequestStartJobSession = Remotes:WaitForChild("RequestStartJobSession")
    local RequestEndJobSession = Remotes:WaitForChild("RequestEndJobSession")
    local DeliveryLocationInteracted = Remotes:WaitForChild("DeliveryLocationInteracted")
    local DeliveryLocationLeft = Remotes:WaitForChild("DeliveryLocationLeft")
    local DeliveryStateChanged = Remotes:WaitForChild("DeliveryStateChanged")
    local DeliveryCompleted = Remotes:WaitForChild("DeliveryCompleted")
    local AttemptDeliveryPickup = Remotes:FindFirstChild("AttemptDeliveryPickup")
    local AttemptDeliveryComplete = Remotes:FindFirstChild("AttemptDeliveryComplete")

    local DeliveryJobTask
    local DeliveryUtil

    pcall(function()
        DeliveryJobTask = require(ReplicatedStorage.Modules.Client.Jobs.Tasks.DeliveryJobTask)
    end)

    pcall(function()
        DeliveryUtil = require(ReplicatedStorage.Modules.Shared.Jobs.Delivery.DeliveryUtil)
    end)

    local pickupRadius = 25
    pcall(function()
        if DeliveryUtil then
            pickupRadius = DeliveryUtil.GetPickupRadius()
        end
    end)

    local currentState = nil
    local lastCompletedAt = 0
    local lastCompletedPayload = nil

    DeliveryStateChanged.OnClientEvent:Connect(function(state)
        currentState = state
    end)

    DeliveryCompleted.OnClientEvent:Connect(function(payload)
        lastCompletedAt = os.clock()
        lastCompletedPayload = payload
    end)

    if CONFIG.AntiAfk then
        LocalPlayer.Idled:Connect(function()
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
            end)
        end)
    end

    local function getState()
        if DeliveryJobTask then
            local ok, state = pcall(function()
                return DeliveryJobTask.GetCurrentDeliveryState()
            end)

            if ok then
                currentState = state
            end
        end

        return currentState
    end

    local function waitFor(predicate, timeout)
        local start = os.clock()

        repeat
            local state = getState()
            if predicate(state) then
                return state
            end

            task.wait(CONFIG.StatePollDelay)
        until not isEnabled() or os.clock() - start >= timeout

        return getState()
    end

    local function getCharacter()
        return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    end

    local function getRootPart()
        local character = getCharacter()
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")

        if humanoid and humanoid.SeatPart then
            humanoid.Sit = false
            task.wait(0.15)
        end

        return character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
    end

    local function teleportTo(position)
        local root = getRootPart()
        if not root then
            return false
        end

        root.CFrame = CFrame.new(position + Vector3.new(0, CONFIG.TeleportHeight, 0))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        randomDelay()  -- เพิ่ม random delay เพื่อความปลอดภัย
        task.wait(CONFIG.AfterTeleportDelay)
        return true
    end

    local function getDeliveryLocations()
        local locations = {}

        for _, instance in ipairs(CollectionService:GetTagged("DeliveryLocation")) do
            if instance:IsA("BasePart") and instance:IsDescendantOf(Workspace) then
                table.insert(locations, instance)
            end
        end

        if #locations > 0 then
            return locations
        end

        local deliveryFolder = Workspace:FindFirstChild("Game")
            and Workspace.Game:FindFirstChild("Jobs")
            and Workspace.Game.Jobs:FindFirstChild("Delivery")
            and Workspace.Game.Jobs.Delivery:FindFirstChild("DeliveryLocations")

        if deliveryFolder then
            for _, instance in ipairs(deliveryFolder:GetChildren()) do
                if instance:IsA("BasePart") then
                    table.insert(locations, instance)
                end
            end
        end

        return locations
    end

    local function findClosestLocation(position)
        local bestLocation = nil
        local bestDistance = math.huge

        for _, location in ipairs(getDeliveryLocations()) do
            local distance = (location.Position - position).Magnitude
            if distance < bestDistance then
                bestLocation = location
                bestDistance = distance
            end
        end

        return bestLocation, bestDistance
    end

    local function findClosestLocationToPlayer()
        local root = getRootPart()
        if not root then
            return nil, math.huge
        end

        return findClosestLocation(root.Position)
    end

    local function fireInteract(location)
        if not location or not location.Parent then
            return
        end

        pcall(function()
            DeliveryLocationInteracted:FireServer(location)
        end)
    end

    local function fireLeave(location)
        if not location or not location.Parent then
            return
        end

        pcall(function()
            DeliveryLocationLeft:FireServer(location)
        end)
    end

    local function invokeRemote(remote, location)
        if not remote or not location or not location.Parent then
            return nil
        end

        local ok, result = pcall(function()
            return remote:InvokeServer(location)
        end)

        if not ok then
            return nil
        end

        return result
    end

    local function samePosition(a, b)
        return typeof(a) == "Vector3" and typeof(b) == "Vector3" and (a - b).Magnitude < 1
    end

    local function getMinDropoffWait(state)
        local minWait = CONFIG.MinDropoffWait or 0

        if DeliveryUtil and state and state.DeliveryTypeId then
            local ok, typeMinCutoff = pcall(function()
                return DeliveryUtil.GetTypeMinCutoff(state.DeliveryTypeId, LocalPlayer)
            end)

            if ok and typeof(typeMinCutoff) == "number" then
                minWait = math.max(minWait, typeMinCutoff)
            end
        end

        return minWait
    end

    local function waitForDropoffWindow(state)
        if not state or not state.DeliveryStartTime or state.DeliveryStartTime <= 0 then
            return
        end

        local minWait = getMinDropoffWait(state)
        if minWait <= 0 then
            return
        end

        local elapsed = Workspace:GetServerTimeNow() - state.DeliveryStartTime
        if elapsed >= minWait then
            return
        end

        local remaining = minWait - elapsed
        log("waiting dropoff window:", string.format("%.1fs", remaining))

        local start = os.clock()
        while isEnabled() and os.clock() - start < remaining do
            task.wait(math.min(CONFIG.StatePollDelay, math.max(remaining - (os.clock() - start), 0.05)))
        end
    end

    local function ensureDeliveryJob()
        local jobId = LocalPlayer:GetAttribute("JobId")

        if jobId and jobId ~= "Delivery" and CONFIG.QuitOtherJobs then
            log("ending current job:", jobId)
            RequestEndJobSession:FireServer("jobPad")
            task.wait(1)
        end

        if LocalPlayer:GetAttribute("JobId") ~= "Delivery" then
            log("starting Delivery job")
            RequestStartJobSession:FireServer("Delivery", "jobPad")

            waitFor(function()
                return LocalPlayer:GetAttribute("JobId") == "Delivery"
            end, CONFIG.StartTimeout)
        end

        if getState() then
            return true
        end

        local location = findClosestLocationToPlayer()
        if location then
            log("requesting first delivery plan")
            teleportTo(location.Position)
            fireInteract(location)
            waitFor(function(state)
                return state ~= nil
            end, CONFIG.StartTimeout)
        end

        return LocalPlayer:GetAttribute("JobId") == "Delivery"
    end

    local function collectPickup(state)
        if not state or not state.PickupPosition then
            return false
        end

        local pickupLocation = findClosestLocation(state.PickupPosition)
        if not pickupLocation then
            warnLog("pickup location not found")
            return false
        end

        log("pickup:", pickupLocation:GetFullName())
        teleportTo(state.PickupPosition)

        local start = os.clock()
        local interactCount = 0
        repeat
            state = getState() or state

            if state.DestinationPosition and (state.ItemsCarried or 0) >= (state.MaxCapacity or 4) then
                break
            end

            if state.PickupPosition and not samePosition(state.PickupPosition, pickupLocation.Position) then
                pickupLocation = findClosestLocation(state.PickupPosition) or pickupLocation
                teleportTo(state.PickupPosition)
            end

            -- ใช้ Direct Function ก่อน (เร็วกว่า)
            if CONFIG.UseDirectFunctions or CONFIG.UseDirectPickupFunction then
                invokeRemote(AttemptDeliveryPickup, pickupLocation)
                randomDelay()
            end

            -- ใช้ FireServer เป็น backup
            fireInteract(pickupLocation)
            interactCount = interactCount + 1

            -- ลด delay หากเก็บของได้แล้ว
            if (state.ItemsCarried or 0) > 0 and interactCount > 2 then
                task.wait(CONFIG.InteractDelay * 0.5)  -- ลด delay ลง 50%
            else
                task.wait(CONFIG.InteractDelay)
            end
        until not isEnabled() or os.clock() - start >= CONFIG.CollectTimeout

        fireLeave(pickupLocation)
        randomDelay()
        task.wait(CONFIG.AfterLeaveDelay)

        state = waitFor(function(nextState)
            return nextState
                and nextState.DestinationPosition ~= nil
                and (nextState.ItemsCarried or 0) > 0
        end, 2)

        if state and state.IsCollecting then
            state = waitFor(function(nextState)
                return nextState
                    and nextState.DestinationPosition ~= nil
                    and (nextState.ItemsCarried or 0) > 0
                    and nextState.IsCollecting ~= true
            end, CONFIG.CollectingStopTimeout)
        end

        if state and state.DestinationPosition and (state.ItemsCarried or 0) > 0 then
            log("collected:", tostring(state.ItemsCarried), "/", tostring(state.MaxCapacity or "?"))
            return true
        end

        warnLog("pickup timed out")
        return false
    end

    local function completeDropoff(state)
        if not state or not state.DestinationPosition or (state.ItemsCarried or 0) <= 0 then
            return false
        end

        local destinationLocation = findClosestLocation(state.DestinationPosition)
        if not destinationLocation then
            warnLog("dropoff location not found")
            return false
        end

        local oldPickupPosition = state.PickupPosition
        local completedBefore = lastCompletedAt

        log("dropoff:", destinationLocation:GetFullName())
        waitForDropoffWindow(state)
        teleportTo(state.DestinationPosition)

        local start = os.clock()
        local dropoffAttempts = 0
        repeat
            state = getState() or state

            if not state or state.IsPlanned or (state.ItemsCarried or 0) <= 0 then
                break
            end

            if state.DestinationPosition and not samePosition(state.DestinationPosition, destinationLocation.Position) then
                destinationLocation = findClosestLocation(state.DestinationPosition) or destinationLocation
                teleportTo(state.DestinationPosition)
            end

            -- ใช้ Direct Function ก่อน (เร็วกว่า)
            if CONFIG.UseDirectFunctions or CONFIG.UseDirectCompleteFunction then
                invokeRemote(AttemptDeliveryComplete, destinationLocation)
                randomDelay()
            end

            -- ใช้ FireServer เป็น backup
            fireInteract(destinationLocation)
            dropoffAttempts = dropoffAttempts + 1

            if lastCompletedAt > completedBefore then
                break
            end

            -- ลด delay หลังจากส่งของได้แล้ว
            if dropoffAttempts > 3 then
                task.wait(CONFIG.InteractDelay * 0.6)  -- ลด delay ลง 40%
            else
                task.wait(CONFIG.InteractDelay)
            end
        until not isEnabled() or os.clock() - start >= CONFIG.DropTimeout

        fireLeave(destinationLocation)
        randomDelay()
        task.wait(CONFIG.AfterLeaveDelay)

        waitFor(function(nextState)
            if lastCompletedAt > completedBefore then
                return true
            end

            if not nextState then
                return true
            end

            if nextState.IsPlanned and (nextState.ItemsCarried or 0) == 0 then
                return true
            end

            return oldPickupPosition and nextState.PickupPosition and not samePosition(oldPickupPosition, nextState.PickupPosition)
        end, CONFIG.NextStateTimeout)

        if lastCompletedPayload then
            log("last payout:", tostring(lastCompletedPayload.CashReward or 0))
        end

        return lastCompletedAt > completedBefore
    end

    task.spawn(function()
        log("started. Stop with: getgenv().DY_DELIVERY_FARM_ENABLED = false")

        while isEnabled() do
            SendAntiAfkInput()
            local ok, err = pcall(function()
                if not ensureDeliveryJob() then
                    task.wait(1)
                    return
                end

                local state = waitFor(function(nextState)
                    return nextState ~= nil
                end, CONFIG.StartTimeout)

                if not state then
                    local location = findClosestLocationToPlayer()
                    if location then
                        teleportTo(location.Position)
                        fireInteract(location)
                    end
                    task.wait(1)
                    return
                end

                if state.DestinationPosition and (state.ItemsCarried or 0) > 0 then
                    completeDropoff(state)
                elseif state.PickupPosition then
                    collectPickup(state)
                else
                    local location = findClosestLocationToPlayer()
                    if location then
                        teleportTo(location.Position)
                        fireInteract(location)
                    end
                end
            end)

            if not ok then
                warnLog(err)
                task.wait(1)
            end

            task.wait(CONFIG.LoopDelay)
        end

        ENV.DY_DELIVERY_FARM_RUNNING = false
        log("stopped")
    end)

    ENV.DY_DELIVERY_FARM_RUNNING = true
end

task.spawn(function()
    local leaderstats = LocalPlayer:WaitForChild("leaderstats", 9e9)
    local miles = leaderstats:WaitForChild("Miles", 9e9)

    local function checkAndStartJob()
        local currentMiles = tonumber(miles.Value) or 0
        -- Removed: print("[System] กำลังเช็คระยะทาง...")

        if not EnableAutoFarm or currentMiles >= TargetMiles then
            -- Removed: print statements
            -- 1. ปิดออโต้ฟาร์ม (หยุด loop วาร์ป)
            AutoFarm = false
            
            -- 2. รีเซ็ตตัวละครให้ตายและเกิดใหม่
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.Health = 0
                LocalPlayer.CharacterAdded:Wait()
                task.wait(1.5) -- รอโหลดแมพสักครู่
            end

            -- 3. รันรีโมทเริ่มงาน
            local Event = ReplicatedStorage:WaitForChild("Remotes", 5)
            if Event then
                local reqEvent = Event:WaitForChild("RequestStartJobSession", 5)
                if reqEvent then
                    reqEvent:FireServer("Delivery", "jobPad")
                end
            end
            
            -- 4. เรียกใช้ฟังก์ชัน Auto Delivery
            AutoDelivery()
        else
            -- Removed: print statement about miles not reaching target
        end
    end

    checkAndStartJob()

    miles:GetPropertyChangedSignal("Value"):Connect(checkAndStartJob)
end)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local leaderstats = LocalPlayer:WaitForChild("leaderstats")
local Cash = leaderstats:WaitForChild("Cash")
local Miles = leaderstats:WaitForChild("Miles")

local function FormatNumber(num)
	num = tonumber(num) or 0

	local formatted = tostring(math.floor(num))
	repeat
		local count
		formatted, count = formatted:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
	until count == 0

	return formatted
end

local function UpdateDescription()
	local messages = string.format(
		"💰 Cash : %s , 🚗 Miles : %s",
		FormatNumber(Cash.Value),
		FormatNumber(Miles.Value)
	)

	if _G.Horst_SetDescription then
		pcall(_G.Horst_SetDescription, messages)
	end
end

UpdateDescription()

Cash:GetPropertyChangedSignal("Value"):Connect(UpdateDescription)
Miles:GetPropertyChangedSignal("Value"):Connect(UpdateDescription)

task.spawn(function()
	while task.wait(5) do
		UpdateDescription()
	end
end)

-- ========================================
-- UI Status Display System
-- ========================================
task.spawn(function()
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local CoreGui = game:GetService("CoreGui")

	-- สร้าง ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DrivingEmpireStatusUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	pcall(function()
		screenGui.Parent = CoreGui
	end)

	if not screenGui.Parent then
		screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	-- Main Frame (พื้นหลัง)
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 320, 0, 180)
	mainFrame.Position = UDim2.new(1, -330, 0, 10)
	mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	-- Corner Radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame

	-- Shadow/Stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 60, 70)
	stroke.Thickness = 2
	stroke.Parent = mainFrame

	-- Header Frame
	local headerFrame = Instance.new("Frame")
	headerFrame.Name = "Header"
	headerFrame.Size = UDim2.new(1, 0, 0, 40)
	headerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	headerFrame.BorderSizePixel = 0
	headerFrame.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = headerFrame

	-- Header Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -20, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🚗 Driving Empire Farm"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = headerFrame

	-- Status Container
	local statusContainer = Instance.new("Frame")
	statusContainer.Name = "StatusContainer"
	statusContainer.Size = UDim2.new(1, -20, 1, -50)
	statusContainer.Position = UDim2.new(0, 10, 0, 45)
	statusContainer.BackgroundTransparency = 1
	statusContainer.Parent = mainFrame

	-- Function to create status row
	local function createStatusRow(name, yPos, icon, defaultText)
		local rowFrame = Instance.new("Frame")
		rowFrame.Name = name
		rowFrame.Size = UDim2.new(1, 0, 0, 25)
		rowFrame.Position = UDim2.new(0, 0, 0, yPos)
		rowFrame.BackgroundTransparency = 1
		rowFrame.Parent = statusContainer

		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(0, 25, 1, 0)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = icon
		iconLabel.TextSize = 16
		iconLabel.Font = Enum.Font.Gotham
		iconLabel.TextXAlignment = Enum.TextXAlignment.Left
		iconLabel.Parent = rowFrame

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "Value"
		valueLabel.Size = UDim2.new(1, -30, 1, 0)
		valueLabel.Position = UDim2.new(0, 30, 0, 0)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = defaultText
		valueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		valueLabel.TextSize = 13
		valueLabel.Font = Enum.Font.Gotham
		valueLabel.TextXAlignment = Enum.TextXAlignment.Left
		valueLabel.Parent = rowFrame

		return valueLabel
	end

	-- Create Status Rows
	local modeLabel = createStatusRow("Mode", 0, "🎯", "Mode: Initializing...")
	local statusLabel = createStatusRow("Status", 30, "⚡", "Status: Starting...")
	local milesLabel = createStatusRow("Miles", 60, "🏁", "Miles: 0 / 100")
	local cashLabel = createStatusRow("Cash", 90, "💰", "Cash: $0")

	-- Toggle Button (ปุ่มซ่อน/แสดง)
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(0, 30, 0, 30)
	toggleButton.Position = UDim2.new(1, -35, 0, 5)
	toggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	toggleButton.BorderSizePixel = 0
	toggleButton.Text = "−"
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.TextSize = 20
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.Parent = mainFrame

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 8)
	toggleCorner.Parent = toggleButton

	local isMinimized = false
	toggleButton.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		if isMinimized then
			mainFrame:TweenSize(UDim2.new(0, 320, 0, 40), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
			toggleButton.Text = "+"
			statusContainer.Visible = false
		else
			mainFrame:TweenSize(UDim2.new(0, 320, 0, 180), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
			toggleButton.Text = "−"
			task.wait(0.15)
			statusContainer.Visible = true
		end
	end)

	-- Update Function
	local function updateUI()
		local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
		if leaderstats then
			local miles = leaderstats:FindFirstChild("Miles")
			local cash = leaderstats:FindFirstChild("Cash")

			if miles then
				local currentMiles = tonumber(miles.Value) or 0
				local targetMiles = TargetMiles or 100
				milesLabel.Text = string.format("Miles: %s / %s", FormatNumber(currentMiles), FormatNumber(targetMiles))

				-- เปลี่ยนสีตาม progress
				local progress = currentMiles / targetMiles
				if progress >= 1 then
					milesLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				elseif progress >= 0.5 then
					milesLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
				else
					milesLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				end
			end

			if cash then
				cashLabel.Text = string.format("Cash: $%s", FormatNumber(cash.Value))
				cashLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			end
		end

		-- Update Mode
		local ENV = (getgenv and getgenv()) or _G
		if ENV.DY_DELIVERY_FARM_ENABLED then
			modeLabel.Text = "Mode: Auto Delivery 📦"
			modeLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
			statusLabel.Text = "Status: Farming Delivery..."
			statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		elseif AutoFarm then
			modeLabel.Text = "Mode: Auto Farm Miles 🏎️"
			modeLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
			statusLabel.Text = "Status: Farming Miles..."
			statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		else
			modeLabel.Text = "Mode: Idle 💤"
			modeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			statusLabel.Text = "Status: Waiting..."
			statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		end
	end

	-- Update Loop
	task.spawn(function()
		task.wait(1)
		while task.wait(0.5) do
			pcall(updateUI)
		end
	end)

	-- Initial Update
	updateUI()
end)
