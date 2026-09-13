repeat task.wait() until game:IsLoaded()

local ENV = (type(getgenv) == "function" and getgenv()) or _G
local GLOBAL_KEY = "MXZY_HUB"

if ENV[GLOBAL_KEY] and type(ENV[GLOBAL_KEY].Cleanup) == "function" then
    pcall(ENV[GLOBAL_KEY].Cleanup)
end

local Runtime = {
    Destroyed = false,
    Connections = {},
}

ENV[GLOBAL_KEY] = Runtime

function Runtime.Cleanup()
    Runtime.Destroyed = true

    for _, connection in ipairs(Runtime.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    if type(table.clear) == "function" then
        table.clear(Runtime.Connections)
    else
        Runtime.Connections = {}
    end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")

local CONFIG_ROOT = "Config"
local CONFIG_FOLDER = CONFIG_ROOT .. "/TTDMacro"

local function hasFileApi()
    return type(isfolder) == "function"
        and type(makefolder) == "function"
        and type(isfile) == "function"
        and type(writefile) == "function"
        and type(readfile) == "function"
end

local function ensureConfigFolder()
    if not hasFileApi() then
        return false
    end

    if not isfolder(CONFIG_ROOT) then
        makefolder(CONFIG_ROOT)
    end

    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end

    return true
end

local function listMacroFiles()
    if not hasFileApi() or not ensureConfigFolder() then
        return {}
    end

    local files = {}

    if type(listfiles) == "function" then
        local ok, allFiles = pcall(function()
            return listfiles(CONFIG_FOLDER)
        end)

        if ok and type(allFiles) == "table" then
            for _, path in ipairs(allFiles) do
                local name = path:match("([^/\\]+)%.json$")
                if name then
                    table.insert(files, name)
                end
            end
        end
    end

    table.sort(files)
    return files
end

local function deleteMacroFile(name)
    if not ensureConfigFolder() then
        return false, "File API not supported"
    end

    local path = CONFIG_FOLDER .. "/" .. name .. ".json"

    if not isfile(path) then
        return false, "File not found"
    end

    local deleteOk, deleteErr = pcall(function()
        delfile(path)
    end)

    if not deleteOk then
        return false, deleteErr
    end

    return true
end

local function saveMacroToFile(name, macroData)
    if not ensureConfigFolder() then
        return false, "File API not supported"
    end

    local sanitized = tostring(name):gsub("[^%w%-%_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "")

    if sanitized == "" then
        return false, "Invalid macro name"
    end

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(macroData)
    end)

    if not ok then
        return false, encoded
    end

    local writeOk, writeErr = pcall(function()
        writefile(CONFIG_FOLDER .. "/" .. sanitized .. ".json", encoded)
    end)

    if not writeOk then
        return false, writeErr
    end

    return true
end

local function loadMacroFromFile(name)
    if not ensureConfigFolder() then
        return nil, "File API not supported"
    end

    local path = CONFIG_FOLDER .. "/" .. name .. ".json"

    if not isfile(path) then
        return nil, "File not found"
    end

    local readOk, body = pcall(readfile, path)

    if not readOk then
        return nil, body
    end

    local decodeOk, decoded = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if not decodeOk then
        return nil, decoded
    end

    return decoded
end

local notify, enableLow, disableLow

local UIOptions = {
    Author = "Tower Defense Macro",
    Theme = "Sky",
    Tag = {
        Title = "Mxzy Hub",
        Icon = "star",
        Color = Color3.fromRGB(160, 196, 255),
    },
    Low = {
        Value = false,
        Callback = function(enabled)
            if enabled then
                if type(enableLow) == "function" then
                    enableLow()
                end
            else
                if type(disableLow) == "function" then
                    disableLow()
                end
            end

            if notify then
                notify("Low", enabled and "Low mode enabled." or "Low mode disabled.", enabled and "check-circle" or "x-circle", 2)
            end
        end,
    },
}

local function loadDelexWindow()
    local uiUrls = {
        "http://mxzy.longong.xyz/uilua.lua",
    }

    local lastError

    for _, url in ipairs(uiUrls) do
        local okSource, source = pcall(function()
            return game:HttpGet(url)
        end)

        if okSource and type(source) == "string" and source ~= "" then
            source = source:gsub("^\239\187\191", "")
            local chunk, loadErr = loadstring(source)

            if chunk then
                local okWindow, window = pcall(chunk, UIOptions)

                if okWindow and window then
                    return window
                end

                lastError = window
            else
                lastError = loadErr
            end
        else
            lastError = source
        end
    end

    error("Failed to load Delex UI: " .. tostring(lastError))
end

local Window = loadDelexWindow()
local WindUI = Window.WindUI

function notify(title, content, icon, duration)
    if WindUI and type(WindUI.Notify) == "function" then
        pcall(function()
            WindUI:Notify({
                Title = title or "TTD Macro",
                Content = content or "",
                Icon = icon or "info",
                Duration = duration or 3,
            })
        end)
    end
end

local MacroState = {
    CurrentName = "",
    Recording = false,
    Playing = false,
    PlayMacroEnabled = false,
    Actions = {},
    SelectedMacro = nil,
    SelectedMacroName = "",
    SelectedMacroToSave = "No Macro",
    AutoSkipWave = false,
    ToLobby = false,
    AutoReplay = false,
    GameSpeed = "1",
}

local PlayState = {
    SelectedMap = "City",
    SelectedPlayers = "1",
    AutoStartMap = false,
}

local MainState = {
    SummonAmount = "1",
    AutoSummon = false,
    AutoClaimQuests = false,
}

-- ฟังก์ชันบันทึก config
local function saveConfig()
    if not hasFileApi() then
        return
    end

    local config = {
        SelectedMacroName = MacroState.SelectedMacroName,
        PlayMacroEnabled = MacroState.PlayMacroEnabled,
        Recording = MacroState.Recording,
        SelectedMacroToSave = MacroState.SelectedMacroToSave,
        SelectedMap = PlayState.SelectedMap,
        SelectedPlayers = PlayState.SelectedPlayers,
        AutoStartMap = PlayState.AutoStartMap,
        AutoSkipWave = MacroState.AutoSkipWave,
        ToLobby = MacroState.ToLobby,
        AutoReplay = MacroState.AutoReplay,
        GameSpeed = MacroState.GameSpeed,
        SummonAmount = MainState.SummonAmount,
        AutoClaimQuests = MainState.AutoClaimQuests,
    }

    local encoded = HttpService:JSONEncode(config)
    pcall(function()
        writefile(CONFIG_ROOT .. "/TTDConfig.json", encoded)
    end)
end

-- ฟังก์ชันโหลด config
local function loadConfig()
    if not hasFileApi() then
        return
    end

    local path = CONFIG_ROOT .. "/TTDConfig.json"
    if not isfile(path) then
        return
    end

    local ok, body = pcall(readfile, path)
    if not ok then
        return
    end

    local success, config = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if success and config then
        MacroState.SelectedMacroName = config.SelectedMacroName or ""
        MacroState.PlayMacroEnabled = config.PlayMacroEnabled or false
        MacroState.Recording = config.Recording or false
        MacroState.SelectedMacroToSave = config.SelectedMacroToSave or "No Macro"
        PlayState.SelectedMap = config.SelectedMap or "City"
        PlayState.SelectedPlayers = config.SelectedPlayers or "1"
        PlayState.AutoStartMap = config.AutoStartMap or false
        MacroState.AutoSkipWave = config.AutoSkipWave or false
        MacroState.ToLobby = config.ToLobby or false
        MacroState.AutoReplay = config.AutoReplay or false
        MacroState.GameSpeed = config.GameSpeed or "1"
        MainState.SummonAmount = config.SummonAmount or "1"
        MainState.AutoClaimQuests = config.AutoClaimQuests or false
    end
end

-- เก็บ MacroState ใน global environment เพื่อให้ hook function เข้าถึงได้
if type(getgenv) == "function" then
    getgenv().TTD_MacroState = MacroState
end

local function getCash()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local cash = leaderstats and leaderstats:FindFirstChild("Cash")

    if cash then
        return tonumber(cash.Value) or 0
    end

    return 0
end

-- WaveState เก็บสถานะ wave ปัจจุบันไว้เป็น attribute (CurrentWave / TotalWaves / MatchState)
local WaveStateFolder = ReplicatedStorage:FindFirstChild("WaveState")

local function getWaveAttribute(name)
    local folder = WaveStateFolder

    if not folder or not folder.Parent then
        folder = ReplicatedStorage:FindFirstChild("WaveState")
        WaveStateFolder = folder
    end

    if not folder then
        return nil
    end

    local ok, value = pcall(function()
        return folder:GetAttribute(name)
    end)

    if not ok then
        return nil
    end

    return value
end

local function getCurrentWave()
    local wave = getWaveAttribute("CurrentWave")
    return tonumber(wave) or 0
end

local function isMatchRunning()
    local matchState = getWaveAttribute("MatchState")

    if matchState == nil then
        return true
    end

    return matchState ~= "Finished"
end

-- เจ้าของทาวเวอร์: attribute Owner ก่อน แล้วค่อย fallback ไป Config.Owner (ตาม TowerController)
local function getTowerOwnerName(tower)
    local ok, owner = pcall(function()
        return tower:GetAttribute("Owner")
    end)

    if ok and type(owner) == "string" and owner ~= "" then
        return owner
    end

    local config = tower:FindFirstChild("Config")
    local ownerValue = config and config:FindFirstChild("Owner")

    if ownerValue and ownerValue:IsA("StringValue") and ownerValue.Value ~= "" then
        return ownerValue.Value
    end

    return nil
end

local function isOwnTower(tower)
    local owner = getTowerOwnerName(tower)
    return owner == nil or owner == LocalPlayer.Name
end

local function getTowersFolder()
    return Workspace:FindFirstChild("Towers")
end

-- นับว่าทาวเวอร์ตัวนี้เป็นตัวที่เท่าไหร่ของชื่อเดียวกันที่เราเป็นเจ้าของ
local function getOwnOccurrence(towerInstance)
    local folder = getTowersFolder()

    if not folder then
        return 1
    end

    local occurrence = 0

    for _, tower in ipairs(folder:GetChildren()) do
        if tower.Name == towerInstance.Name and isOwnTower(tower) then
            occurrence = occurrence + 1

            if tower == towerInstance then
                return occurrence
            end
        end
    end

    return occurrence > 0 and occurrence or 1
end

-- แผนที่ instance ของทาวเวอร์ -> index ของ action PlaceTower ที่วางมัน (ใช้ตอนอัด)
local RecordedPlacements = setmetatable({}, {__mode = "k"})

-- คิวของ PlaceTower ที่ยิงไปแล้วแต่ยังไม่รู้ว่าได้ instance ตัวไหน
local PendingPlacements = {}

local function startRecording()
    local state = (type(getgenv) == "function" and getgenv().TTD_MacroState) or MacroState

    if state.Recording then
        return false, "Already recording"
    end

    if state.CurrentName == "" then
        return false, "Please enter a macro name"
    end

    state.Recording = true
    state.Actions = {}

    if type(table.clear) == "function" then
        table.clear(RecordedPlacements)
        table.clear(PendingPlacements)
    else
        RecordedPlacements = setmetatable({}, {__mode = "k"})
        PendingPlacements = {}
    end

    -- อัพเดททั้ง local และ global
    MacroState.Recording = true
    MacroState.Actions = {}
    if type(getgenv) == "function" then
        getgenv().TTD_MacroState.Recording = true
        getgenv().TTD_MacroState.Actions = {}
    end

    notify("Macro", "Recording started: " .. state.CurrentName)
    return true
end

local function stopRecording()
    local state = (type(getgenv) == "function" and getgenv().TTD_MacroState) or MacroState

    if not state.Recording then
        return false, "Not recording"
    end

    state.Recording = false

    -- อัพเดททั้ง local และ global
    MacroState.Recording = false
    if type(getgenv) == "function" then
        getgenv().TTD_MacroState.Recording = false
    end

    notify("Macro", "Recording stopped. Actions: " .. #state.Actions)
    return true
end

-- ผูก instance ของทาวเวอร์ที่เพิ่งวางเข้ากับ action ที่อัดไว้
-- ห้ามอ่านค่าที่ PlaceTower คืนมาใน hook เพราะการเก็บค่าไว้จะทำให้ frame ของ hook ค้าง
-- แล้ว InvokeServer จะ yield ข้าม metamethod boundary → remote ไม่ถูกส่งไปเซิร์ฟเวอร์เลย
-- จึงรอ instance ผ่าน Towers.ChildAdded แทน
local function consumePlacement(towerInstance)
    local now = os.clock()

    for i = #PendingPlacements, 1, -1 do
        if PendingPlacements[i].ExpiresAt < now then
            table.remove(PendingPlacements, i)
        end
    end

    -- จับคู่ตามชื่อ เรียงตามลำดับที่วาง (ตอน ChildAdded ยังอ่าน attribute Owner ไม่ได้)
    for i, pending in ipairs(PendingPlacements) do
        if pending.Tower == towerInstance.Name then
            RecordedPlacements[towerInstance] = pending.ActionIndex
            table.remove(PendingPlacements, i)
            return
        end
    end
end

local TowerFolderWatched = nil

local function watchTowerFolder()
    local folder = getTowersFolder()

    if not folder or folder == TowerFolderWatched then
        return
    end

    TowerFolderWatched = folder

    local connection = folder.ChildAdded:Connect(function(child)
        pcall(consumePlacement, child)
    end)

    table.insert(Runtime.Connections, connection)
end

local function recordPlaceTower(towerName, cframe)
    local state = (type(getgenv) == "function" and getgenv().TTD_MacroState) or MacroState

    if not state or not state.Recording then
        return nil
    end

    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local cash = leaderstats and leaderstats:FindFirstChild("Cash")
    local cashBefore = cash and tonumber(cash.Value) or 0

    table.insert(state.Actions, {
        Type = "PlaceTower",
        Tower = towerName,
        CFrame = {
            Position = {cframe.Position.X, cframe.Position.Y, cframe.Position.Z},
            LookVector = {cframe.LookVector.X, cframe.LookVector.Y, cframe.LookVector.Z},
        },
        CashBefore = cashBefore,
        Wave = getCurrentWave(),
    })

    local actionIndex = #state.Actions

    -- จองคิวรอ instance จริงจาก Towers.ChildAdded
    watchTowerFolder()
    table.insert(PendingPlacements, {
        ActionIndex = actionIndex,
        Tower = towerName,
        ExpiresAt = os.clock() + 10,
    })

    return actionIndex
end

local function recordUpgradeTower(towerInstance)
    local state = (type(getgenv) == "function" and getgenv().TTD_MacroState) or MacroState

    if not state or not state.Recording then
        return
    end

    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local cash = leaderstats and leaderstats:FindFirstChild("Cash")
    local cashBefore = cash and tonumber(cash.Value) or 0

    -- หา index ที่แท้จริงของ tower ใน Workspace.Towers
    local folder = getTowersFolder()
    local allTowers = folder and folder:GetChildren() or {}
    local towerIndex = nil
    local isFirstOfName = true

    for i, tower in ipairs(allTowers) do
        if tower == towerInstance then
            towerIndex = i
        elseif tower.Name == towerInstance.Name and not towerIndex then
            -- ถ้ามี tower ชื่อเดียวกันก่อนหน้านี้ แสดงว่าไม่ใช่ตัวแรก
            isFirstOfName = false
        end
    end

    table.insert(state.Actions, {
        Type = "UpgradeTower",
        TowerIndex = towerIndex or #allTowers,
        Tower = towerInstance.Name,
        IsFirstOfName = isFirstOfName,
        PlacedBy = RecordedPlacements[towerInstance],
        Occurrence = getOwnOccurrence(towerInstance),
        CashBefore = cashBefore,
        Wave = getCurrentWave(),
    })
end

-- ขายทาวเวอร์: ไม่ผูกกับเงินเหมือน place/upgrade แต่ผูกกับ wave ที่ขาย
-- ต้องเรียกผ่าน task.spawn จาก hook เท่านั้น (ห้ามเรียกตรงๆ ในฮุค)
-- เพราะฟังก์ชันนี้ยิง namecall หลายครั้ง ถ้ารันในเธรดเดียวกับฮุคจะทับ state
-- ของ getnamecallmethod() ทำให้ remote เดิมไม่ถูกส่งไปเซิร์ฟเวอร์
-- task.spawn รันทันทีก่อน remote จะถูกส่ง ทาวเวอร์จึงยังอยู่ใน Workspace ให้อ่านค่าได้
local function recordSellTower(towerInstance)
    local state = (type(getgenv) == "function" and getgenv().TTD_MacroState) or MacroState

    if not state or not state.Recording then
        return
    end

    local folder = getTowersFolder()
    local allTowers = folder and folder:GetChildren() or {}
    local towerIndex = nil
    local isFirstOfName = true

    for i, tower in ipairs(allTowers) do
        if tower == towerInstance then
            towerIndex = i
        elseif tower.Name == towerInstance.Name and not towerIndex then
            isFirstOfName = false
        end
    end

    local placedBy = RecordedPlacements[towerInstance]

    table.insert(state.Actions, {
        Type = "SellTower",
        Tower = towerInstance.Name,
        TowerIndex = towerIndex or #allTowers,
        IsFirstOfName = isFirstOfName,
        PlacedBy = placedBy,
        Occurrence = getOwnOccurrence(towerInstance),
        Wave = getCurrentWave(),
    })

    -- ทาวเวอร์ตัวนี้ไม่มีอยู่แล้ว เลิกจองสล็อตของมัน
    if placedBy then
        RecordedPlacements[towerInstance] = nil
    end
end

local function saveMacro()
    local state = (type(getgenv) == "function" and getgenv().TTD_MacroState) or MacroState

    if state.CurrentName == "" then
        notify("Macro", "Please enter a macro name")
        return false
    end

    if #state.Actions == 0 then
        notify("Macro", "No actions to save")
        return false
    end

    local macroData = {
        Name = state.CurrentName,
        Actions = state.Actions,
        CreatedAt = os.time(),
    }

    local ok, err = saveMacroToFile(state.CurrentName, macroData)

    if ok then
        notify("Macro", "Saved: " .. state.CurrentName)
        return true
    else
        notify("Macro", "Save failed: " .. tostring(err))
        return false
    end
end

-- หาทาวเวอร์ที่ action อ้างถึงตอนเล่นมาโคร
-- ลำดับความแม่นยำ: instance ที่ได้จาก PlaceTower ตอนเล่น > ลำดับที่ของชื่อเดียวกัน > index ดิบ
local function resolveActionTower(action, playedPlacements)
    local folder = getTowersFolder()

    if not folder then
        return nil
    end

    if action.PlacedBy then
        local placed = playedPlacements[action.PlacedBy]

        if placed and placed.Parent then
            return placed
        end
    end

    local allTowers = folder:GetChildren()

    if action.Occurrence then
        local occurrence = 0

        for _, tower in ipairs(allTowers) do
            if tower.Name == action.Tower and isOwnTower(tower) then
                occurrence = occurrence + 1

                if occurrence == action.Occurrence then
                    return tower
                end
            end
        end
    end

    -- มาโครเก่าที่ยังไม่มี Occurrence
    if action.IsFirstOfName then
        for _, tower in ipairs(allTowers) do
            if tower.Name == action.Tower then
                return tower
            end
        end
    elseif action.TowerIndex and allTowers[action.TowerIndex] then
        local candidate = allTowers[action.TowerIndex]

        if candidate.Name == action.Tower then
            return candidate
        end
    end

    -- สุดท้ายเอาตัวไหนก็ได้ที่ชื่อตรงและเป็นของเรา
    for _, tower in ipairs(allTowers) do
        if tower.Name == action.Tower and isOwnTower(tower) then
            return tower
        end
    end

    return nil
end

-- รอเงินให้ถึงยอดที่ต้องใช้ (สำหรับ place / upgrade)
local function waitForCash(amount)
    while getCash() < amount and MacroState.Playing and not Runtime.Destroyed do
        if not isMatchRunning() then
            return false
        end

        task.wait(0.1)
    end

    return MacroState.Playing and not Runtime.Destroyed
end

-- รอให้ถึง wave ที่กำหนด (สำหรับ sell — ไม่อิงเงิน)
local function waitForWave(targetWave)
    while getCurrentWave() < targetWave and MacroState.Playing and not Runtime.Destroyed do
        if not isMatchRunning() then
            return false
        end

        task.wait(0.25)
    end

    return MacroState.Playing and not Runtime.Destroyed
end

local function playMacro(macroData)
    if MacroState.Playing then
        return false, "Already playing"
    end

    if not macroData or type(macroData.Actions) ~= "table" then
        return false, "Invalid macro data"
    end

    MacroState.Playing = true

    task.spawn(function()
        local PlaceTowerRemote = RemoteFunctions:FindFirstChild("PlaceTower")
        local UpgradeTowerRemote = RemoteFunctions:FindFirstChild("UpgradeTower")
        local SellTowerRemote = RemoteFunctions:FindFirstChild("SellTower")

        -- actionIndex ของ PlaceTower -> instance ที่ server คืนมาในรอบเล่นนี้
        local playedPlacements = {}

        for i, action in ipairs(macroData.Actions) do
            if Runtime.Destroyed or not MacroState.Playing then
                break
            end

            if action.Type == "SellTower" then
                -- ขายอิง wave ไม่อิงเงิน
                local targetWave = tonumber(action.Wave) or 0

                if not waitForWave(targetWave) then
                    break
                end

                if SellTowerRemote then
                    local tower = resolveActionTower(action, playedPlacements)

                    if tower then
                        local success, err = pcall(function()
                            return SellTowerRemote:InvokeServer(tower)
                        end)

                        if success then
                            if action.PlacedBy then
                                playedPlacements[action.PlacedBy] = nil
                            end
                        else
                            notify("Macro", "Failed to sell " .. tostring(action.Tower) .. ": " .. tostring(err))
                        end
                    else
                        notify("Macro", "Sell target not found: " .. tostring(action.Tower))
                    end
                end
            else
                local cashNeeded = action.CashBefore or 0

                if not waitForCash(cashNeeded) then
                    break
                end

                if action.Type == "PlaceTower" and PlaceTowerRemote then
                    local pos = action.CFrame.Position
                    local look = action.CFrame.LookVector

                    -- สร้าง CFrame อย่างถูกต้อง: CFrame.new(position, position + lookVector)
                    local position = Vector3.new(pos[1], pos[2], pos[3])
                    local lookVector = Vector3.new(look[1], look[2], look[3])
                    local cf = CFrame.new(position, position + lookVector)

                    local success, result = pcall(function()
                        return PlaceTowerRemote:InvokeServer(action.Tower, cf)
                    end)

                    if success then
                        -- server คืน Model ของทาวเวอร์ที่วางสำเร็จ เก็บไว้ให้ upgrade/sell อ้างถึง
                        if typeof(result) == "Instance" and result:IsA("Model") then
                            playedPlacements[i] = result
                        end
                    else
                        notify("Macro", "Failed to place " .. action.Tower .. ": " .. tostring(result))
                    end

                elseif action.Type == "UpgradeTower" and UpgradeTowerRemote then
                    local tower = resolveActionTower(action, playedPlacements)

                    if tower then
                        local success, err = pcall(function()
                            return UpgradeTowerRemote:InvokeServer(tower)
                        end)

                        if not success then
                            notify("Macro", "Failed to upgrade " .. action.Tower .. ": " .. tostring(err))
                        end
                    else
                        notify("Macro", "Tower not found: " .. action.Tower)
                    end
                end
            end

            task.wait(0.05)
        end

        MacroState.Playing = false
        notify("Macro", "Playback completed")
    end)

    return true
end

local function hookRemotes()
    -- ใช้ namecall hook แทน hookfunction เพราะเสถียรกว่า
    -- สำคัญ: ห้าม yield หรือรอค่าที่ server คืนมาในนี้ ไม่งั้น remote จะไม่ถูกส่งจริง
    -- ต้องส่งต่อ oldNamecall ทันทีเสมอ ส่วนงานบันทึกให้ทำผ่าน task.spawn
    if type(hookmetamethod) == "function" then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()

            if method == "InvokeServer" then
                local args = {...}
                local remoteName

                local nameOk, name = pcall(function()
                    return self.Name
                end)

                if nameOk then
                    remoteName = name
                end

                -- ตรวจจับ PlaceTower
                if remoteName == "PlaceTower" then
                    local towerName = args[1]
                    local cframe = args[2]

                    if towerName and cframe then
                        task.spawn(recordPlaceTower, towerName, cframe)
                    end

                -- ตรวจจับ UpgradeTower
                elseif remoteName == "UpgradeTower" then
                    local towerInstance = args[1]

                    if typeof(towerInstance) == "Instance" then
                        task.spawn(recordUpgradeTower, towerInstance)
                    end

                -- ตรวจจับ SellTower
                elseif remoteName == "SellTower" then
                    local towerInstance = args[1]

                    if typeof(towerInstance) == "Instance" and towerInstance.Parent then
                        task.spawn(recordSellTower, towerInstance)
                    end
                end
            end

            return oldNamecall(self, ...)
        end)
    end
end

local MacroDropdown
local SaveMacroDropdown
local DeleteMacroDropdown
local ExportMacroDropdown

local function refreshMacroDropdown()
    local files = listMacroFiles()
    local playOptions = #files > 0 and files or {"No macros"}
    local saveOptions = #files > 0 and files or {"No Macro"}

    -- รีเฟรช Play dropdown
    if MacroDropdown and type(MacroDropdown.Refresh) == "function" then
        pcall(function()
            MacroDropdown:Refresh(playOptions, true)
        end)
    end

    -- รีเฟรช Save dropdown
    if SaveMacroDropdown and type(SaveMacroDropdown.Refresh) == "function" then
        pcall(function()
            SaveMacroDropdown:Refresh(saveOptions, true)
        end)
    end

    -- รีเฟรช Delete dropdown
    if DeleteMacroDropdown and type(DeleteMacroDropdown.Refresh) == "function" then
        pcall(function()
            DeleteMacroDropdown:Refresh(playOptions, true)
        end)
    end

    -- รีเฟรช Export dropdown
    if ExportMacroDropdown and type(ExportMacroDropdown.Refresh) == "function" then
        pcall(function()
            ExportMacroDropdown:Refresh(playOptions, true)
        end)
    end
end

local function isInLobby()
    local ok, hasButton = pcall(function()
        return LocalPlayer.PlayerGui.MainGameUI.UpSide.InfoDop.AutoSkip ~= nil
    end)

    return not (ok and hasButton)
end

local function isGameEndUIVisible()
    local ok, visible = pcall(function()
        local gameEndUI = LocalPlayer.PlayerGui:FindFirstChild("GameEndUI")
        return gameEndUI and gameEndUI.Enabled
    end)

    return ok and visible
end

local function clickLobbyButton()
    if not isGameEndUIVisible() then
        return false
    end

    local ok = pcall(function()
        local button = LocalPlayer.PlayerGui.GameEndUI.Frame.Selector.Lobby.Use

        if button and button:IsA("TextButton") then
            if type(firesignal) == "function" then
                firesignal(button.Activated)

                if button.MouseButton1Click then
                    firesignal(button.MouseButton1Click)
                end
            end
        end
    end)

    return ok
end

local function clickReplayButton()
    if not isGameEndUIVisible() then
        return false
    end

    local ok = pcall(function()
        local button = LocalPlayer.PlayerGui.GameEndUI.Frame.Selector.Replay.Use

        if button and button:IsA("TextButton") then
            if type(firesignal) == "function" then
                firesignal(button.Activated)

                if button.MouseButton1Click then
                    firesignal(button.MouseButton1Click)
                end
            end
        end
    end)

    return ok
end

local function setGameSpeed(speed)
    local ok = pcall(function()
        local Event = ReplicatedStorage.RemoteEvents.SetGameSpeed
        Event:FireServer(speed)
    end)

    return ok
end

local function joinQueue()
    if not isInLobby() then
        return false
    end

    local mapName = PlayState.SelectedMap
    local playerCount = tonumber(PlayState.SelectedPlayers) or 1

    local ok = pcall(function()
        local Event = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.MatchmakingService.RF.JoinQueue
        Event:InvokeServer(mapName, playerCount)
    end)

    return ok
end

local function isAutoSkipEnabled()
    local ok, enabled = pcall(function()
        local autoSkipMove = LocalPlayer.PlayerGui.MainGameUI.UpSide.InfoDop.AutoSkip.Move
        local autoOff = autoSkipMove:FindFirstChild("AutoOff")

        if autoOff and autoOff.Enabled then
            return false
        end

        return true
    end)

    return ok and enabled
end

local function clickAutoSkipButton()
    if isAutoSkipEnabled() then
        return false
    end

    local ok, err = pcall(function()
        local button = LocalPlayer.PlayerGui.MainGameUI.UpSide.InfoDop.AutoSkip.Move.Use

        if button and button:IsA("TextButton") then
            if type(firesignal) == "function" then
                firesignal(button.Activated)

                if button.MouseButton1Click then
                    firesignal(button.MouseButton1Click)
                end
            else
                button:Invoke()
            end
        end
    end)

    return ok
end

local function summonUnits(amount)
    local ok = pcall(function()
        local Event = ReplicatedStorage.RemoteFunctions.SummonUnits
        Event:InvokeServer(amount)
    end)

    return ok
end

local function openQuestsUI()
    local ok = pcall(function()
        local button = LocalPlayer.PlayerGui._MainUI.Buttons.Mini.Quests

        if button and button:IsA("TextButton") then
            if type(firesignal) == "function" then
                firesignal(button.Activated)

                if button.MouseButton1Click then
                    firesignal(button.MouseButton1Click)
                end
            end
        end
    end)

    return ok
end

local function claimQuests()
    local ok = pcall(function()
        local questsUI = LocalPlayer.PlayerGui._LobbyUI.Quests

        if not questsUI or not questsUI.Enabled then
            return false
        end

        local questsList = questsUI.Frame.CurrentFrame.Hour.QuestsList

        for i = 1, 3 do
            local quest = questsList:FindFirstChild("Quest_" .. i)
            if quest then
                local claimButton = quest:FindFirstChild("Claim")
                if claimButton then
                    local useButton = claimButton:FindFirstChild("Use")
                    if useButton and useButton:IsA("TextButton") then
                        if type(firesignal) == "function" then
                            firesignal(useButton.Activated)

                            if useButton.MouseButton1Click then
                                firesignal(useButton.MouseButton1Click)
                            end
                        end
                        task.wait(0.2)
                    end
                end
            end
        end

        return true
    end)

    return ok
end

hookRemotes()
watchTowerFolder()

-- Towers folder ถูกสร้างใหม่ทุกครั้งที่เข้าแมพ ต้องต่อ ChildAdded ใหม่ด้วย
table.insert(Runtime.Connections, Workspace.ChildAdded:Connect(function(child)
    if child.Name == "Towers" then
        watchTowerFolder()
    end
end))

-- Low mode implementation
local LowState = {
    Running = false,
    Connections = {},
    Original = setmetatable({}, { __mode = "k" }),
}

local function disableIdleConnections()
    if type(getconnections) ~= "function" then
        return
    end

    local ok, connections = pcall(function()
        return getconnections(LocalPlayer.Idled)
    end)

    if not ok or type(connections) ~= "table" then
        return
    end

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disable()
        end)
    end
end

local function nudgeAntiAfk()
    pcall(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector3.new())
    end)
end

local function rememberLowProperty(object, property)
    local bucket = LowState.Original[object]

    if not bucket then
        bucket = {}
        LowState.Original[object] = bucket
    end

    if bucket[property] == nil then
        local ok, value = pcall(function()
            return object[property]
        end)

        if ok then
            bucket[property] = value
        end
    end
end

local function setLowProperty(object, property, value)
    rememberLowProperty(object, property)

    pcall(function()
        object[property] = value
    end)
end

local function boostLighting()
    setLowProperty(Lighting, "GlobalShadows", false)
    setLowProperty(Lighting, "EnvironmentDiffuseScale", 0)
    setLowProperty(Lighting, "EnvironmentSpecularScale", 0)
    setLowProperty(Lighting, "Brightness", 3)
    setLowProperty(Lighting, "FogEnd", 1000000)
    setLowProperty(Lighting, "ShadowSoftness", 0)

    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)

    pcall(function()
        UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
    end)

    local terrain = Workspace:FindFirstChildOfClass("Terrain")

    if terrain then
        setLowProperty(terrain, "WaterWaveSize", 0)
        setLowProperty(terrain, "WaterWaveSpeed", 0)
        setLowProperty(terrain, "WaterReflectance", 0)
        setLowProperty(terrain, "WaterTransparency", 1)
        setLowProperty(terrain, "Decoration", false)
    end
end

local function boostObject(object)
    if object:IsA("BasePart") then
        setLowProperty(object, "CastShadow", false)
        setLowProperty(object, "Reflectance", 0)

        if object.Material ~= Enum.Material.Neon then
            setLowProperty(object, "Material", Enum.Material.SmoothPlastic)
        end

        if object:IsA("MeshPart") then
            setLowProperty(object, "RenderFidelity", Enum.RenderFidelity.Performance)
        end
    elseif object:IsA("Decal") or object:IsA("Texture") then
        setLowProperty(object, "Transparency", 1)
    elseif object:IsA("ParticleEmitter") then
        setLowProperty(object, "Enabled", false)
        setLowProperty(object, "Rate", 0)

        pcall(function()
            object:Clear()
        end)
    elseif object:IsA("Trail") or object:IsA("Beam") then
        setLowProperty(object, "Enabled", false)
    elseif object:IsA("Smoke") or object:IsA("Fire") or object:IsA("Sparkles") then
        setLowProperty(object, "Enabled", false)
    elseif object:IsA("PointLight") or object:IsA("SpotLight") or object:IsA("SurfaceLight") then
        setLowProperty(object, "Enabled", false)
    elseif object:IsA("PostEffect") then
        setLowProperty(object, "Enabled", false)
    elseif object:IsA("Atmosphere") then
        setLowProperty(object, "Density", 0)
        setLowProperty(object, "Haze", 0)
        setLowProperty(object, "Glare", 0)
    elseif object:IsA("Clouds") then
        setLowProperty(object, "Cover", 0)
        setLowProperty(object, "Density", 0)
    elseif object:IsA("Highlight") then
        setLowProperty(object, "Enabled", false)
    elseif object:IsA("Explosion") then
        setLowProperty(object, "Visible", false)
        setLowProperty(object, "BlastPressure", 0)
    end
end

local function applyLowReducer()
    if type(setfpscap) == "function" then
        pcall(setfpscap, 999)
    end

    boostLighting()

    for _, object in ipairs(game:GetDescendants()) do
        boostObject(object)
    end
end

local function restoreLowReducer()
    for object, properties in pairs(LowState.Original) do
        if object and object.Parent then
            for property, value in pairs(properties) do
                pcall(function()
                    object[property] = value
                end)
            end
        end
    end
end

function disableLow()
    LowState.Running = false

    for _, connection in ipairs(LowState.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    if type(table.clear) == "function" then
        table.clear(LowState.Connections)
    else
        LowState.Connections = {}
    end

    restoreLowReducer()
end

function enableLow()
    if LowState.Running then
        return
    end

    LowState.Running = true
    disableIdleConnections()
    applyLowReducer()

    table.insert(LowState.Connections, LocalPlayer.Idled:Connect(function()
        disableIdleConnections()
        nudgeAntiAfk()
    end))

    table.insert(LowState.Connections, game.DescendantAdded:Connect(function(object)
        if LowState.Running then
            task.defer(boostObject, object)
        end
    end))

    task.spawn(function()
        while LowState.Running and not Runtime.Destroyed do
            task.wait(60)

            if not LowState.Running or Runtime.Destroyed or not LocalPlayer.Parent then
                break
            end

            disableIdleConnections()
            nudgeAntiAfk()
        end
    end)
end

Runtime.LowCleanup = disableLow

-- Load config before creating UI
loadConfig()

local MainTab = Window:Tab({
    Title = "Main",
    Desc = "Main automation features",
    Icon = "house",
})

local SummonSection = MainTab:Section({
    Title = "Auto Summon",
    Desc = "Summon units automatically",
    Icon = "sparkles",
    Side = "left",
})

SummonSection:Dropdown({
    Title = "Summon Amount",
    Description = "Select amount per summon",
    Values = {"1", "10"},
    Value = MainState.SummonAmount,
    Default = MainState.SummonAmount,
    Callback = function(value)
        MainState.SummonAmount = value
        notify("Main", "Summon amount: " .. tostring(value), "info", 2)
        saveConfig()
    end,
})

SummonSection:Toggle({
    Title = "Auto Summon",
    Description = "Automatically summon units",
    Value = MainState.AutoSummon,
    Callback = function(enabled)
        MainState.AutoSummon = enabled
        notify("Main", enabled and "Auto Summon enabled" or "Auto Summon disabled", enabled and "check-circle" or "x-circle", 2)
        saveConfig()
    end,
})

local PlayTab = Window:Tab({
    Title = "Play",
    Desc = "Map and game settings",
    Icon = "play",
})

local MapSection = PlayTab:Section({
    Title = "Map Selection",
    Desc = "Choose map and players",
    Icon = "map",
    Side = "left",
})

MapSection:Dropdown({
    Title = "Select Map",
    Description = "Choose map to play",
    Values = {"City", "Canyon Bridge", "Wild Desert", "Camera Lab", "ToiletBunker"},
    Value = PlayState.SelectedMap,
    Default = PlayState.SelectedMap,
    Callback = function(value)
        PlayState.SelectedMap = value
        notify("Play", "Selected map: " .. tostring(value), "map", 2)
        saveConfig()
    end,
})

MapSection:Dropdown({
    Title = "Number of Players",
    Description = "Select player count",
    Values = {"1", "2", "3", "4"},
    Value = PlayState.SelectedPlayers,
    Default = PlayState.SelectedPlayers,
    Callback = function(value)
        PlayState.SelectedPlayers = value
        notify("Play", "Selected players: " .. tostring(value), "users", 2)
        saveConfig()
    end,
})

MapSection:Toggle({
    Title = "Auto Start Map",
    Description = "Automatically join queue",
    Value = PlayState.AutoStartMap,
    Callback = function(enabled)
        PlayState.AutoStartMap = enabled
        notify("Play", enabled and "Auto Start Map enabled" or "Auto Start Map disabled", enabled and "check-circle" or "x-circle", 2)
        saveConfig()
    end,
})

local AutoFeaturesSection = PlayTab:Section({
    Title = "Auto Features",
    Desc = "Game automation settings",
    Icon = "settings",
    Side = "right",
})

AutoFeaturesSection:Dropdown({
    Title = "Game Speed",
    Description = "Set game speed multiplier",
    Values = {"1", "1.50", "2"},
    Value = MacroState.GameSpeed,
    Default = MacroState.GameSpeed,
    Callback = function(value)
        MacroState.GameSpeed = value

        if not isInLobby() then
            local speed = tonumber(value) or 1
            if setGameSpeed(speed) then
                notify("Auto", "Game speed set to: " .. value, "zap", 2)
            end
        end

        saveConfig()
    end,
})

AutoFeaturesSection:Toggle({
    Title = "Auto Skip Wave",
    Description = "Automatically skip waves",
    Value = MacroState.AutoSkipWave,
    Callback = function(enabled)
        MacroState.AutoSkipWave = enabled
        notify("Auto", enabled and "Auto skip wave enabled" or "Auto skip wave disabled", enabled and "check-circle" or "x-circle", 2)
        saveConfig()
    end,
})

AutoFeaturesSection:Toggle({
    Title = "Auto Replay",
    Description = "Automatically replay on victory",
    Value = MacroState.AutoReplay,
    Callback = function(enabled)
        MacroState.AutoReplay = enabled
        notify("Auto", enabled and "Auto Replay enabled" or "Auto Replay disabled", enabled and "check-circle" or "x-circle", 2)
        saveConfig()
    end,
})

AutoFeaturesSection:Toggle({
    Title = "To Lobby",
    Description = "Return to lobby after game",
    Value = MacroState.ToLobby,
    Callback = function(enabled)
        MacroState.ToLobby = enabled
        notify("Auto", enabled and "To Lobby enabled" or "To Lobby disabled", enabled and "check-circle" or "x-circle", 2)
        saveConfig()
    end,
})

local MacroTab = Window:Tab({
    Title = "Macro",
    Desc = "Record and play macros",
    Icon = "circle-dot",
})

local ShareTab = Window:Tab({
    Title = "Share",
    Desc = "Import and export macros",
    Icon = "share-2",
})

local ShareSection = ShareTab:Section({
    Title = "Export Macro",
    Desc = "Copy macro config to clipboard",
    Icon = "upload",
    Side = "left",
})

ExportMacroDropdown = ShareSection:Dropdown({
    Title = "Select Macro to Export",
    Description = "Choose macro to copy",
    Values = (function()
        local files = listMacroFiles()
        return #files > 0 and files or {"No macros"}
    end)(),
    Value = "No macros",
    Default = "No macros",
    Callback = function(value)
        -- Store for copy button
    end,
})

ShareSection:Button({
    Title = "Copy Macro Config",
    Description = "Copy selected macro to clipboard",
    Icon = "copy",
    Callback = function()
        local selectedMacro = ExportMacroDropdown.Value
        if not selectedMacro or selectedMacro == "No macros" then
            notify("Share", "Please select a macro first", "alert-circle", 3)
            return
        end

        local macroData, err = loadMacroFromFile(selectedMacro)
        if not macroData then
            notify("Share", "Load failed: " .. tostring(err), "x-circle", 3)
            return
        end

        local encoded = HttpService:JSONEncode(macroData)

        if type(setclipboard) == "function" then
            setclipboard(encoded)
            notify("Share", "Copied: " .. selectedMacro, "check-circle", 2)
        else
            notify("Share", "Clipboard not supported", "x-circle", 3)
        end
    end,
})

local ImportSection = ShareTab:Section({
    Title = "Import Macro",
    Desc = "Paste and save macro config",
    Icon = "download",
    Side = "right",
})

local ImportedConfig = ""

ImportSection:Input({
    Title = "Paste Macro Config",
    Placeholder = "Paste JSON here...",
    Callback = function(text)
        ImportedConfig = text
    end,
})

ImportSection:Button({
    Title = "Import & Save Macro",
    Description = "Save imported macro to file",
    Icon = "save",
    Callback = function()
        if ImportedConfig == "" then
            notify("Share", "Please paste macro config first", "alert-circle", 3)
            return
        end

        local success, macroData = pcall(function()
            return HttpService:JSONDecode(ImportedConfig)
        end)

        if not success or not macroData then
            notify("Share", "Invalid macro config", "x-circle", 3)
            return
        end

        if not macroData.Name or not macroData.Actions then
            notify("Share", "Invalid macro format", "x-circle", 3)
            return
        end

        if not hasFileApi() then
            notify("Share", "Your executor doesn't support file saving. Contact the macro creator for help.", "x-circle", 4)
            return
        end

        local ok, err = saveMacroToFile(macroData.Name, macroData)

        if ok then
            notify("Share", "Imported: " .. macroData.Name, "check-circle", 3)

            task.delay(0.1, function()
                refreshMacroDropdown()
            end)

            ImportedConfig = ""
        else
            notify("Share", "Import failed: " .. tostring(err), "x-circle", 3)
        end
    end,
})

local RecordSection = MacroTab:Section({
    Title = "Record Macro",
    Desc = "Create and record new macros",
    Icon = "circle",
    Side = "left",
})

RecordSection:Input({
    Title = "Macro Name (Optional)",
    Placeholder = "name...",
    Callback = function(text)
        local name = tostring(text):gsub("^%s+", ""):gsub("%s+$", "")
        if name ~= "" then
            MacroState.CurrentName = name

            if type(getgenv) == "function" then
                getgenv().TTD_MacroState.CurrentName = name
            end
        end
    end,
})

RecordSection:Button({
    Title = "Create New Macro",
    Description = "Create empty macro file",
    Icon = "save",
    Callback = function()
        if MacroState.CurrentName == "" then
            local timestamp = os.date("%Y%m%d_%H%M%S")
            MacroState.CurrentName = "Macro_" .. timestamp

            if type(getgenv) == "function" then
                getgenv().TTD_MacroState.CurrentName = MacroState.CurrentName
            end
        end

        local emptyMacroData = {
            Name = MacroState.CurrentName,
            Actions = {},
            CreatedAt = os.time(),
        }

        local ok, err = saveMacroToFile(MacroState.CurrentName, emptyMacroData)

        if ok then
            notify("Macro", "Created: " .. MacroState.CurrentName, "check-circle", 2)

            task.delay(0.1, function()
                refreshMacroDropdown()
                MacroState.SelectedMacroToSave = MacroState.CurrentName
            end)
        else
            notify("Macro", "Failed to create: " .. tostring(err), "x-circle", 3)
        end
    end,
})

local SelectedMacroToSave = "No Macro"

SaveMacroDropdown = RecordSection:Dropdown({
    Title = "Save to Macro",
    Description = "Select macro file to save into",
    Values = (function()
        local files = listMacroFiles()
        if #files > 0 then
            return files
        else
            return {"No Macro"}
        end
    end)(),
    Value = (function()
        local files = listMacroFiles()
        if #files > 0 then
            if MacroState.SelectedMacroToSave ~= "No Macro" then
                return MacroState.SelectedMacroToSave
            else
                return files[1]
            end
        else
            return "No Macro"
        end
    end)(),
    Default = (function()
        local files = listMacroFiles()
        if #files > 0 then
            if MacroState.SelectedMacroToSave ~= "No Macro" then
                return MacroState.SelectedMacroToSave
            else
                return files[1]
            end
        else
            return "No Macro"
        end
    end)(),
    Callback = function(value)
        MacroState.SelectedMacroToSave = value
        saveConfig()
    end,
})

RecordSection:Toggle({
    Title = "Record Macro",
    Description = "Start/stop recording actions",
    Value = MacroState.Recording,
    Callback = function(enabled)
        if enabled then
            if MacroState.SelectedMacroToSave == "No Macro" then
                notify("Macro", "Please create a macro first", "alert-circle", 3)
                return
            end

            MacroState.CurrentName = MacroState.SelectedMacroToSave

            if type(getgenv) == "function" then
                getgenv().TTD_MacroState.CurrentName = MacroState.SelectedMacroToSave
            end

            local ok, err = startRecording()
            if not ok then
                notify("Macro", tostring(err), "x-circle", 3)
            else
                saveConfig()
            end
        else
            stopRecording()

            local state = (type(getgenv) == "function" and getgenv().TTD_MacroState) or MacroState

            if #state.Actions > 0 then
                local finalName = MacroState.SelectedMacroToSave

                local macroData = {
                    Name = finalName,
                    Actions = state.Actions,
                    CreatedAt = os.time(),
                }

                local ok, err = saveMacroToFile(finalName, macroData)

                if ok then
                    notify("Macro", "Auto-saved: " .. finalName, "check-circle", 2)

                    task.delay(0.1, function()
                        refreshMacroDropdown()
                    end)
                else
                    notify("Macro", "Auto-save failed: " .. tostring(err), "x-circle", 3)
                end
            end

            saveConfig()
        end
    end,
})

task.spawn(function()
    while not Runtime.Destroyed do
        local state = (type(getgenv) == "function" and getgenv().TTD_MacroState) or MacroState
        local actions = (state and state.Actions) or {}
        local place, upgrade, sell = 0, 0, 0

        for _, action in ipairs(actions) do
            if action.Type == "PlaceTower" then
                place = place + 1
            elseif action.Type == "UpgradeTower" then
                upgrade = upgrade + 1
            elseif action.Type == "SellTower" then
                sell = sell + 1
            end
        end

        task.wait(0.5)
    end
end)

local PlaySection = MacroTab:Section({
    Title = "Play Macro",
    Desc = "Load and execute macros",
    Icon = "play",
    Side = "right",
})

MacroDropdown = PlaySection:Dropdown({
    Title = "Select Macro",
    Description = "Choose macro to play",
    Values = (function()
        local files = listMacroFiles()
        return #files > 0 and files or {"No macros"}
    end)(),
    Value = MacroState.SelectedMacroName ~= "" and MacroState.SelectedMacroName or "No macros",
    Default = MacroState.SelectedMacroName ~= "" and MacroState.SelectedMacroName or "No macros",
    Callback = function(value)
        if value == "No macros" then
            MacroState.SelectedMacro = nil
            MacroState.SelectedMacroName = ""
            saveConfig()
            return
        end

        local macroData, err = loadMacroFromFile(value)
        if macroData then
            MacroState.SelectedMacro = macroData
            MacroState.SelectedMacroName = value
            notify("Macro", "Loaded: " .. value, "check-circle", 2)
            saveConfig()
        else
            notify("Macro", "Load failed: " .. tostring(err), "x-circle", 3)
            MacroState.SelectedMacro = nil
            MacroState.SelectedMacroName = ""
            saveConfig()
        end
    end,
})

PlaySection:Toggle({
    Title = "Play Macro",
    Description = "Execute loaded macro",
    Value = MacroState.PlayMacroEnabled,
    Callback = function(enabled)
        MacroState.PlayMacroEnabled = enabled
        saveConfig()

        if enabled then
            if not MacroState.SelectedMacro then
                notify("Macro", "Please select a macro first", "alert-circle", 3)
                MacroState.PlayMacroEnabled = false
                saveConfig()
                return
            end

            local ok, err = playMacro(MacroState.SelectedMacro)
            if not ok then
                notify("Macro", tostring(err), "x-circle", 3)
                MacroState.PlayMacroEnabled = false
                saveConfig()
            else
                notify("Macro", "Playing macro...", "play-circle", 2)
            end
        else
            MacroState.Playing = false
            notify("Macro", "Playback stopped", "x-circle", 2)
        end
    end,
})

local ManageSection = MacroTab:Section({
    Title = "Manage Macros",
    Desc = "Delete macro files",
    Icon = "trash-2",
    Side = "left",
})

local SelectedMacroToDelete = "No macros"

DeleteMacroDropdown = ManageSection:Dropdown({
    Title = "Select Macro to Delete",
    Description = "Choose macro to remove",
    Values = (function()
        local files = listMacroFiles()
        return #files > 0 and files or {"No macros"}
    end)(),
    Value = "No macros",
    Default = "No macros",
    Callback = function(value)
        SelectedMacroToDelete = value
    end,
})

ManageSection:Button({
    Title = "Delete Macro",
    Description = "Permanently delete selected macro",
    Icon = "trash-2",
    Callback = function()
        if not SelectedMacroToDelete or SelectedMacroToDelete == "No macros" then
            notify("Macro", "Please select a macro to delete", "alert-circle", 3)
            return
        end

        local ok, err = deleteMacroFile(SelectedMacroToDelete)

        if ok then
            notify("Macro", "Deleted: " .. SelectedMacroToDelete, "check-circle", 2)

            if MacroState.SelectedMacroToSave == SelectedMacroToDelete then
                MacroState.SelectedMacroToSave = "No Macro"
                saveConfig()
            end

            SelectedMacroToDelete = "No macros"

            task.delay(0.1, function()
                refreshMacroDropdown()
            end)
        else
            notify("Macro", "Delete failed: " .. tostring(err), "x-circle", 3)
        end
    end,
})

task.spawn(function()
    while not Runtime.Destroyed do
        if MainState.AutoSummon then
            local amount = tonumber(MainState.SummonAmount) or 1
            if summonUnits(amount) then
                notify("Main", "Summoned: " .. amount .. " unit(s)")
            end
            task.wait(1)
        else
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    while not Runtime.Destroyed do
        if MacroState.AutoSkipWave then
            clickAutoSkipButton()
            task.wait(1)
        else
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    while not Runtime.Destroyed do
        if PlayState.AutoStartMap then
            if isInLobby() then
                -- รับเควสก่อนถ้าเปิด Auto Claim Quests
                if PlayState.AutoClaimQuests then
                    if openQuestsUI() then
                        task.wait(0.5)
                        if claimQuests() then
                            notify("Play", "Quests claimed")
                        end
                        task.wait(0.5)
                    end
                end

                -- เริ่มแมพ
                if joinQueue() then
                    notify("Play", "Joining queue: " .. PlayState.SelectedMap .. " (" .. PlayState.SelectedPlayers .. " players)")
                    task.wait(3)
                end
            end
            task.wait(1)
        else
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    while not Runtime.Destroyed do
        if MacroState.ToLobby then
            if clickLobbyButton() then
                notify("Auto", "Returning to lobby")
                task.wait(2)
            end
            task.wait(1)
        else
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    while not Runtime.Destroyed do
        if MacroState.AutoReplay then
            if clickReplayButton() then
                notify("Auto", "Replaying map")
                task.wait(2)
            end
            task.wait(1)
        else
            task.wait(0.25)
        end
    end
end)

task.spawn(function()
    while not Runtime.Destroyed do
        -- ตั้งความเร็วเกมถ้าอยู่ในเกม (ไม่ใช่ lobby)
        if not isInLobby() then
            local speed = tonumber(MacroState.GameSpeed) or 1
            setGameSpeed(speed)
            task.wait(2)
        else
            task.wait(0.5)
        end
    end
end)

-- โหลด macro ที่บันทึกไว้หลังจาก UI โหลดเสร็จ
task.delay(1, function()
    if MacroState.SelectedMacroName ~= "" then
        local macroData, err = loadMacroFromFile(MacroState.SelectedMacroName)
        if macroData then
            MacroState.SelectedMacro = macroData
            notify("Macro", "Auto-loaded: " .. MacroState.SelectedMacroName, "check-circle", 2)

            -- ถ้าเคยเปิดปุ่ม Play Macro ไว้ ให้เล่นอัตโนมัติ
            if MacroState.PlayMacroEnabled then
                task.delay(0.5, function()
                    local ok, err = playMacro(MacroState.SelectedMacro)
                    if ok then
                        notify("Macro", "Auto-playing macro...", "play-circle", 2)
                    end
                end)
            end
        end
    end
end)

notify("Mxzy Hub", "Macro system loaded successfully", "check-circle", 3)

Window:InitBaseTabs()
