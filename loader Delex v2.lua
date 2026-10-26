-- ============================================================
-- Delex UI - loader (executor-agnostic)
-- Supports multiple executors with capability fallbacks.
-- รองรับ executor หลายตัว โดยตรวจความสามารถและมี fallback ให้ API ที่อาจไม่มี
-- RightControl toggles the UI by default. / ค่าเริ่มต้น RightControl ใช้พับ/กาง UI
--
-- ============================================================
-- AI / maintainer guide: read this before editing the loader or library.
-- ============================================================
-- Architecture:
--   1) lib.lua is the UI library. This loader downloads it from LibUrl, compiles it,
--      and receives a Library table with CreateWindow, Notify, theme, and UI APIs.
--   2) loader.lua creates the actual Delex window and tabs, wires feature callbacks,
--      and manages per-player JSON settings.
--   3) Add game-specific features in this loader. Edit lib.lua only for shared UI
--      behavior, control rendering, or window behavior.
--   4) After editing either file, upload that file to the matching GitHub path.
--
-- Loading from GitHub:
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/latavee1399-dev/AKO/refs/heads/main/loader%20Delex%20v2.lua"))()
--   LibUrl below must point to raw.githubusercontent.com. A github.com/.../blob/... URL
--   returns HTML instead of Lua source and will fail compilation.
--
-- Game-folder naming:
--   * Set getgenv().DelexLoaderConfig BEFORE running the loader to override this run:
--       getgenv().DelexLoaderConfig = { GameName = "Durian Garden" }
--       loadstring(game:HttpGet(url))()
--     Supported fields: GameName (current PlaceId only), GameNames (PlaceId-to-name map),
--     SkipNameApi, AppendPlaceId, and RootFolder. Prefer DelexLoaderConfig to avoid
--     collisions with another script's global Config table.
--   * Name resolution order: CONFIG.GameNames -> Delex/GameNames.json cache -> Roblox
--     API -> MarketplaceService -> game.Name -> Game_<PlaceId> fallback.
--   * Names discovered automatically are cached. Some experiences do not expose public
--     metadata (for example this Durian Garden place); set an override for those games.
--   * Names are sanitized for executor file-system compatibility. PlaceId is appended
--     by default to prevent different experiences with the same name sharing a folder.
--
-- Files created by the loader:
--   <RootFolder>/GameNames.json                         cached PlaceId-to-name mappings
--   <RootFolder>/SaveMode.json                          save mode shared across games
--   <RootFolder>/<GameName>_<PlaceId>/<PlayerName>.json saved values for one username
--   PlayerName is Players.LocalPlayer.Name, not DisplayName. Executor name is metadata.
--
-- UI object model:
--   Library:CreateWindow({...}) -> Window
--   Window:AddTab("Name") -> Tab
--   Tab:AddLeftGroupbox("Name") / AddRightGroupbox("Name") -> Section
--   Sections support AddToggle, AddButton, AddLabel, AddDropdown, AddKeyBind,
--   AddInput, and AddSlider. The current tabs are Misc and Settings.
--   Add new tabs in the "Add your tabs here" block near the bottom. The call
--   Window.layoutOrder("Misc", "Settings") keeps Misc and Settings at the bottom.
--
-- Automatic settings persistence:
--   Use Delex.Bind.Toggle/Slider/Dropdown/Multi/Input/Keybind instead of calling
--   Group:Add... directly. Signature: Delex.Bind.<Type>(Group, StableKey, Options).
--   StableKey must be unique and should remain unchanged between script revisions.
--   Bind wrappers load defaults from saved Values and queue a JSON save after changes
--   (about 0.6 seconds). Options.Callback applies the value to the actual feature.
--   Example:
--     local Tab = Window:AddTab("Farm")
--     local Group = Tab:AddLeftGroupbox("Farm")
--     Delex.Bind.Toggle(Group, "AutoFarm", {
--       Text = "Auto Farm", Default = false,
--       Callback = function(enabled) -- start/stop the feature here end
--     })
--     Delex.Bind.Slider(Group, "FarmDelay", {
--       Text = "Delay", Min = 0, Max = 5, Default = 1, Rouding = 1,
--       Callback = function(value) -- apply the value here end
--     })
--   Direct Group:AddToggle/AddSlider/... calls are NOT auto-saved unless their callback
--   calls Delex.Config.Set(key, value) or Delex.Config.Save(). Config API:
--   Delex.Config.Get/Set/Save/QueueSave/Path/Mode and Delex.Config.Values.
--   Bind.Keybind stores the chosen key name; its Options.Callback receives active state.
--
-- Save Setting Config behavior:
--   Separate Per Client: each Roblox username has a separate JSON file.
--   Link All Clients: saves the same payload to other client files returned by listfiles
--   in the current game's folder. Without listfiles, only the current file can be written.
--   Reload From File reapplies registered Toggle/Slider/Dropdown/Multi/Input controls.
--   Keybind is loaded when the control is first created but is not reapplied by Reload.
--   Persistent saving requires readfile and writefile; without them the UI can still open.
--
-- Library APIs used or exposed by this loader:
--   Library:Notify(settings, true), :SetTheme(name), :GetThemeNames(), :GetTheme(),
--   :RegisterTheme(name, colorTable), :ApplyTheme(colorTable), :OnThemeChanged(callback),
--   :SetToggleKey(key), :GetToggleKey(), Library.ToggleUI(), Library.DestroyUI().
--   Built-in themes: Blue, Red, Green, Purple, Orange, White.
--
-- AI editing rules:
--   * Use English for text rendered inside Roblox UI; comments may use any language.
--   * The current library expects the slider precision option named Rouding (misspelled).
--   * Feature callbacks must handle character respawn and feature shutdown where needed.
--   * Do not rename existing StableKeys without migrating their saved values.
--   * Check executor capabilities before using HTTP/file APIs; availability varies.
--   * Misc Player features are client-side and may be restricted by the experience/server.
-- ============================================================

-- ============================================================
-- คู่มือภาษาไทย / Thai guide
-- ============================================================
-- ภาพรวม:
--   * lib.lua คือ UI library; loader ดาวน์โหลดและ compile แล้วเรียก CreateWindow()
--   * loader.lua สร้างหน้าต่าง, tabs, controls, callbacks และระบบบันทึก config
--   * เพิ่มฟีเจอร์เกมใน loader.lua; แก้ lib.lua เฉพาะเมื่อแก้พฤติกรรม UI พื้นฐาน
--
-- เรียกใช้:
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/latavee1399-dev/AKO/refs/heads/main/loader%20Delex%20v2.lua"))()
--   URL ของ Library แยกอยู่ในตัวแปร LibUrl. ใช้ raw URL ไม่ใช่หน้า GitHub แบบ blob
--
-- ตั้งชื่อเกม:
--   * อัตโนมัติ: CONFIG.GameNames -> Delex/GameNames.json -> Roblox API ->
--     MarketplaceService -> game.Name -> Game_<PlaceId>
--   * ตั้งก่อนโหลด: getgenv().DelexLoaderConfig = { GameName = "Durian Garden" }
--   * ตั้งจาก UI: Settings > Save Setting Config > Game Folder Name; มีผลรอบถัดไป
--   * CONFIG.GameNames ใช้ PlaceId เป็น key. AppendPlaceId เปิดไว้เพื่อกันชื่อซ้ำ
--
-- เพิ่ม controls พร้อม auto-save:
--   local Tab = Window:AddTab("Farm")
--   local Group = Tab:AddLeftGroupbox("Farm")
--   Delex.Bind.Toggle(Group, "AutoFarm", {
--     Text = "Auto Farm", Default = false,
--     Callback = function(enabled) -- เริ่ม/หยุดฟีเจอร์จริงตรงนี้ end
--   })
--   ใช้ StableKey ที่ไม่ซ้ำและอย่าเปลี่ยนชื่อโดยไม่ย้ายค่าเก่า. Bind helpers จะโหลด
--   default จาก JSON และเซฟหลังเปลี่ยนค่าประมาณ 0.6 วินาที. Group:AddToggle โดยตรง
--   จะไม่ auto-save เว้นแต่ callback เรียก Delex.Config.Set/Save เอง
--
-- ระบบ Save:
--   Separate Per Client แยกไฟล์ตาม username; Link All Clients เขียนค่าร่วมไปยังไฟล์
--   client อื่นในโฟลเดอร์เกมที่ listfiles มองเห็น. ต้องมี readfile/writefile จึงจะเซฟได้.
--   Reload From File apply กลับ Toggle/Slider/Dropdown/Multi/Input; Keybind ไม่ apply
--   ใหม่หลังสร้างแล้ว. Config API อยู่ใน Delex.Config และ Bind API อยู่ใน Delex.Bind
--
-- โครงสร้าง UI:
--   Window -> AddTab -> AddLeftGroupbox/AddRightGroupbox -> controls
--   ปัจจุบันมี Misc และ Settings; เพิ่มแท็บใหม่ในบล็อกตัวอย่างท้าย loader.
--   Misc/Settings ถูกตรึงไว้ท้ายรายการด้วย Window.layoutOrder().
--
-- หมายเหตุ:
--   * ข้อความที่แสดงใน Roblox UI ควรเป็นอังกฤษเพื่อให้ฟอนต์แสดงได้แน่นอน
--   * slider precision ใช้ option ชื่อ Rouding ตามชื่อที่ library ปัจจุบันรองรับ
--   * ฟีเจอร์ Misc Player ทำงานฝั่ง client และอาจถูกเกม/เซิร์ฟเวอร์จำกัด
--   * ตรวจ capability ของ executor ก่อนเรียก HTTP หรือ file APIs เสมอ
-- ============================================================
-- File layout created by the loader:
--   Delex/GameNames.json                         cached game-folder names
--   Delex/SaveMode.json                          shared save-mode selection
--   Delex/<GameName>_<PlaceId>/<PlayerName>.json saved settings
-- ============================================================

--
-- Save modes:
--   Separate Per Client = each Roblox username has its own config file.
--   Link All Clients    = saves the same data to visible client files in this game's folder.
--
-- Configure game-folder names:
--   A) Edit CONFIG.GameNames below (persistent for every run using this loader).
--   B) Set getgenv().DelexLoaderConfig before loading (no GitHub edit required).
--   C) Enter the name in Settings > Save Setting Config > Game Folder Name.
--   D) Leave it unset to let the loader query Roblox APIs when possible.
--
-- Text rendered inside Roblox UI should be English; the default Roblox font may not support Thai.
-- ============================================================

-- ============================================================
-- 0) Default configuration (edit here or pass overrides before loadstring).
-- ============================================================
local CONFIG = {
	-- Set a custom folder name per experience: [PlaceId] = "folder name".
	-- Unlisted games use auto-detection, then fall back to Game_<PlaceId>.
	-- Get the current PlaceId with print(game.PlaceId) or from the Settings tab.
	GameNames = {
		[54849] = "Durian Garden",
	},

	-- true skips Roblox API lookups. Internal game names then fall back to Game_<PlaceId>.
	SkipNameApi = false,

	-- Append PlaceId to prevent experiences with duplicate names from sharing folders.
	AppendPlaceId = true,

	-- Root folder for all Delex data.
	RootFolder = "Delex",
}

-- ============================================================
-- 0.1) External game-name/config overrides (set these before running loadstring).
--   getgenv().DelexLoaderConfig = { GameName = "Durian Garden" }
--   loadstring(game:HttpGet(url))()
-- You may also pass GameNames = { [PlaceId] = "name", ... }, SkipNameApi,
-- AppendPlaceId, and RootFolder. Prefer DelexLoaderConfig to avoid collisions
-- with another script's global Config table.
-- Overrides apply only to the currently running loader/game.
-- ============================================================
local function CollectOverride()
	local Sources = {}

	local OkGenv, GenvTable = pcall(function()
		return getgenv and getgenv() or _G
	end)
	if OkGenv and type(GenvTable) == "table" then
		table.insert(Sources, GenvTable.DelexLoaderConfig)
		table.insert(Sources, GenvTable.Config)
	end
	table.insert(Sources, _G.DelexLoaderConfig)
	table.insert(Sources, _G.Config)

	for _, Candidate in ipairs(Sources) do
		if type(Candidate) == "table" then
			return Candidate
		end
	end
	return nil
end

do
	local User = CollectOverride()
	if type(User) == "table" then
		if type(User.GameName) == "string" and User.GameName ~= "" then
			CONFIG.GameNames[game.PlaceId] = User.GameName
		end
		if type(User.GameNames) == "table" then
			for PlaceId, Name in pairs(User.GameNames) do
				CONFIG.GameNames[PlaceId] = Name
			end
		end
		if User.SkipNameApi ~= nil then
			CONFIG.SkipNameApi = User.SkipNameApi and true or false
		end
		if User.AppendPlaceId ~= nil then
			CONFIG.AppendPlaceId = User.AppendPlaceId and true or false
		end
		if type(User.RootFolder) == "string" and User.RootFolder ~= "" then
			CONFIG.RootFolder = User.RootFolder
		end
	end
end

-- ============================================================
-- 1) Compatibility shims (run before using optional executor APIs).
-- ============================================================
if type(getgenv) ~= "function" then
	function getgenv()
		return _G
	end
end

local Genv = getgenv()

local function Log(...)
	print("[Delex]", ...)
end

local function Delay(Seconds, Fn)
	if type(task) == "table" and type(task.delay) == "function" then
		task.delay(Seconds, Fn)
		return
	end
	if type(spawn) == "function" and type(wait) == "function" then
		spawn(function()
			wait(Seconds)
			Fn()
		end)
	end
end

local TableFind = table.find or function(List, Value)
	for Index, Item in ipairs(List) do
		if Item == Value then
			return Index
		end
	end
	return nil
end

-- Executor identification: names and helper functions vary by executor.
local function RawExecutorName()
	if type(identifyexecutor) == "function" then
		local Ok, Name = pcall(identifyexecutor)
		if Ok and type(Name) == "string" and Name ~= "" then
			return Name
		end
	end

	if type(getexecutorname) == "function" then
		local Ok, Name = pcall(getexecutorname)
		if Ok and type(Name) == "string" and Name ~= "" then
			return Name
		end
	end

	local FromGenv = Genv.identifyexecutor
	if type(FromGenv) == "function" then
		local Ok, Name = pcall(FromGenv)
		if Ok and type(Name) == "string" and Name ~= "" then
			return Name
		end
	end

	-- Identify executor-specific globals left behind by the runtime.
	local Marks = {
		{ "syn", "Synapse" },
		{ "KRNL_LOADED", "Krnl" },
		{ "fluxus", "Fluxus" },
		{ "is_sirhurt_closure", "SirHurt" },
		{ "OwlHub", "Owl" },
		{ "Wave", "Wave" },
	}
	for _, Entry in ipairs(Marks) do
		if rawget(_G, Entry[1]) ~= nil then
			return Entry[2]
		end
	end

	return nil
end

-- HTTP helper: prefer game.HttpGet, then try executor-specific request functions.
local function HttpGet(Url)
	if type(game.HttpGet) == "function" then
		local Ok, Body = pcall(game.HttpGet, game, Url)
		if Ok and type(Body) == "string" and Body ~= "" then
			return Body
		end
	end

	if type(httpget) == "function" then
		local Ok, Body = pcall(httpget, Url)
		if Ok and type(Body) == "string" and Body ~= "" then
			return Body
		end
	end

	local Request = Genv.request or (type(syn) == "table" and syn.request) or (type(http) == "table" and http.request)
	if type(Request) == "function" then
		local Ok, Response = pcall(Request, { Url = Url, Method = "GET" })
		if Ok and type(Response) == "table" and type(Response.Body) == "string" then
			return Response.Body
		end
	end

	return nil
end

local LibUrl = "https://raw.githubusercontent.com/latavee1399-dev/AKO/refs/heads/main/Delex%20ui.lua"
local Url = LibUrl .. (string.find(LibUrl, "?", 1, true) and "&" or "?") .. "v=" .. tostring(os.time())

local Source = HttpGet(Url)
if type(Source) ~= "string" or #Source < 256 then
	error("[Delex] download failed (check executor http + url): " .. Url, 0)
end

local Compile = loadstring or load
local Chunk, CompileError = Compile(Source, "=DelexLibrary")
if not Chunk then
	error("[Delex] compile failed: " .. tostring(CompileError), 0)
end

-- Remove the old all-in-one UI before running, to prevent duplicate windows.
Genv.GravityHubManual = true

local Library = Chunk()
if type(Library) ~= "table" or type(Library.CreateWindow) ~= "function" then
	error("[Delex] library did not return a Library table (file must end with: return Library)", 0)
end

local HttpService = game:GetService("HttpService")

-- ============================================================
-- 2) File APIs, with fallbacks for missing optional functions.
-- ============================================================
local CanWrite = type(writefile) == "function"
local CanRead = type(readfile) == "function"
local CanFolder = type(makefolder) == "function"
local CanList = type(listfiles) == "function"
local HasFiles = CanWrite and CanRead

local ROOT = CONFIG.RootFolder
local MODE_FILE = ROOT .. "/SaveMode.json"
local MODE_SEPARATE = "Separate Per Client"
local MODE_LINK = "Link All Clients"

-- เก็บเฉพาะ ascii: บาง executor รับชื่อไฟล์ที่มีอักษรต่างชาติไม่ได้
local function Sanitize(Name)
	local Text = tostring(Name or "")
	Text = Text:gsub("[^%w%-%._ ]", "")
	Text = Text:gsub("%s+", "_")
	Text = Text:gsub("_+", "_")
	Text = Text:gsub("^_+", "")
	Text = Text:gsub("_+$", "")
	Text = Text:gsub("^%.+", "")
	if Text == "" then
		Text = "Unknown"
	end
	return Text
end

local Executor = Sanitize(RawExecutorName() or "UnknownClient")

-- Use the Roblox username as the config filename.
local function PlayerName()
	local Ok, Player = pcall(function()
		return game:GetService("Players").LocalPlayer
	end)
	if Ok and Player and Player.Name ~= "" then
		return Sanitize(Player.Name)
	end
	return "Player"
end

-- The per-game folder name is configured in CONFIG.GameNames near the top of this file.

-- Cache detected game names in Delex/GameNames.json so each game only needs to be resolved once.
local NAMES_FILE = CONFIG.RootFolder .. "/GameNames.json"
local NameCache = {}

local function LoadNameCache()
	if not HasFiles then
		return
	end
	local Ok, Raw = pcall(readfile, NAMES_FILE)
	if not Ok or type(Raw) ~= "string" or Raw == "" then
		return
	end
	local Decoded, Data = pcall(function()
		return HttpService:JSONDecode(Raw)
	end)
	if Decoded and type(Data) == "table" then
		NameCache = Data
	end
end

-- Store a game name in the Delex/GameNames.json cache.
local function StoreGameName(PlaceId, Name)
	if not HasFiles then
		return false
	end
	local Clean = Sanitize(Name)
	NameCache[tostring(PlaceId)] = Clean
	local Ok, Encoded = pcall(function()
		return HttpService:JSONEncode(NameCache)
	end)
	if not Ok or type(Encoded) ~= "string" then
		return false
	end
	-- Create the Delex folder before writing the cache file.
	if type(makefolder) == "function" and type(isfolder) == "function" then
		if not isfolder(CONFIG.RootFolder) then
			pcall(makefolder, CONFIG.RootFolder)
		end
	end
	return (pcall(writefile, NAMES_FILE, Encoded))
end

-- Roblox internal names such as "Ugc", "Ugc_91350038154849", "Place_123", or numeric IDs.
-- Track where the selected game-folder name came from for the Settings UI.
local GameNameSource = "unknown"

local function LooksInternalName(Name)
	local Text = tostring(Name or "")
	if Text == "" then
		return true
	end
	if Text:match("^[Uu]gc_?%d*$") then
		return true
	end
	if Text:match("^[Pp]lace_?%d*$") then
		return true
	end
	if Text:match("^%d+$") then
		return true
	end
	if #Text <= 3 then
		return true
	end
	return false
end

local function JsonGet(Url)
	local Body = HttpGet(Url)
	if type(Body) ~= "string" or Body == "" then
		return nil
	end
	local Ok, Data = pcall(function()
		return HttpService:JSONDecode(Body)
	end)
	if Ok and type(Data) == "table" then
		return Data
	end
	return nil
end

-- Query the Roblox API used by the public experience listing.
local function FetchGameNameFromApi()
	local PlaceId = tostring(game.PlaceId)

	local UniverseData = JsonGet("https://apis.roblox.com/universes/v1/places/" .. PlaceId .. "/universe")
	local UniverseId
	if type(UniverseData) == "table" then
		UniverseId = UniverseData.universeId
	end

	if UniverseId ~= nil then
		local GameData = JsonGet("https://games.roblox.com/v1/games?universeIds=" .. tostring(UniverseId))
		if type(GameData) == "table" and type(GameData.data) == "table" then
			local First = GameData.data[1]
			if type(First) == "table" and type(First.name) == "string" and First.name ~= "" then
				return First.name, First.creator
			end
		end
	else
		-- No universeId was returned; try the endpoint that returns place details directly.
		local PlaceData = JsonGet("https://games.roblox.com/v1/games/multiget-place-details?placeIds=" .. PlaceId)
		if type(PlaceData) == "table" and type(PlaceData[1]) == "table" then
			local Name = PlaceData[1].name
			if type(Name) == "string" and Name ~= "" then
				return Name
			end
		end
	end

	return nil
end

-- MarketplaceService is a fallback; some places return internal names, which are filtered out.
local function FetchGameNameFromMarketplace()
	local Ok, Info = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
	end)
	if Ok and type(Info) == "table" and type(Info.Name) == "string" then
		return Info.Name
	end
	return nil
end

local function ResolveGameName()
	-- 1) Explicit per-place name from CONFIG.GameNames takes precedence.
	local Override = CONFIG.GameNames[game.PlaceId]
		or CONFIG.GameNames[tostring(game.PlaceId)]
	if type(Override) == "string" and Override ~= "" then
		GameNameSource = "config"
		return Sanitize(Override)
	end

	-- 2) Name previously saved for this PlaceId in Delex/GameNames.json.
	local Cached = NameCache[tostring(game.PlaceId)]
	if type(Cached) == "string" and Cached ~= "" then
		GameNameSource = "saved"
		return Sanitize(Cached)
	end

	-- 3) Resolve the name through Roblox APIs.
	if not CONFIG.SkipNameApi then
		local FromApi = FetchGameNameFromApi()
		if type(FromApi) == "string" and not LooksInternalName(FromApi) then
			GameNameSource = "roblox api"
			return Sanitize(FromApi)
		end

		local FromMarket = FetchGameNameFromMarketplace()
		if type(FromMarket) == "string" and not LooksInternalName(FromMarket) then
			GameNameSource = "marketplace"
			return Sanitize(FromMarket)
		end
	end

	-- 4) game.Name
	local FromGame = tostring(game.Name or "")
	if not LooksInternalName(FromGame) then
		GameNameSource = "game.name"
		return Sanitize(FromGame)
	end

	-- 5) Fall back to a generic PlaceId-based folder name.
	GameNameSource = "fallback"
	return "Game_" .. tostring(game.PlaceId)
end

LoadNameCache()
local GameName = ResolveGameName()

-- Cache automatically detected names in GameNames.json to avoid resolving them again next time.
do
	local Cached = NameCache[tostring(game.PlaceId)]
	local HasOverride = CONFIG.GameNames[game.PlaceId] ~= nil
		or CONFIG.GameNames[tostring(game.PlaceId)] ~= nil
	if not HasOverride and (Cached == nil or Cached ~= GameName) then
		local LooksAuto = GameName:match("^Game_%d+$") == nil
		if LooksAuto then
			pcall(StoreGameName, game.PlaceId, GameName)
		end
	end
end
local ClientName = PlayerName()

-- Append PlaceId to avoid folder collisions between experiences with the same name.
local function WithPlaceId(Name)
	if not CONFIG.AppendPlaceId then
		return Name
	end
	local Id = tostring(game.PlaceId)
	if string.find(Name, Id, 1, true) then
		return Name
	end
	return Name .. "_" .. Id
end

local GameFolder = ROOT .. "/" .. WithPlaceId(GameName)
local ClientFile = GameFolder .. "/" .. ClientName .. ".json"

local function FileExists(Path)
	if type(isfile) == "function" then
		local Ok, Exists = pcall(isfile, Path)
		if Ok then
			return Exists == true
		end
	end
	if CanRead then
		return (pcall(readfile, Path)) == true
	end
	return false
end

local function FolderExists(Path)
	if type(isfolder) == "function" then
		local Ok, Exists = pcall(isfolder, Path)
		if Ok then
			return Exists == true
		end
	end
	return false
end

local function EnsureFolder(Path)
	if not Path or Path == "" then
		return false
	end
	if FolderExists(Path) then
		return true
	end
	if CanFolder then
		pcall(makefolder, Path)
	end
	return FolderExists(Path)
end

local function NormalizePath(Path)
	if type(Path) ~= "string" or Path == "" then
		return nil
	end
	local Clean = Path:gsub("\\", "/")
	if string.find(Clean, "/", 1, true) then
		return Clean
	end
	-- Some executors return only a filename instead of a full path.
	return GameFolder .. "/" .. Clean
end

local function ReadJson(Path)
	if not CanRead or not Path or not FileExists(Path) then
		return nil
	end
	local Ok, Raw = pcall(readfile, Path)
	if not Ok or type(Raw) ~= "string" or Raw == "" then
		return nil
	end
	local Decoded, Data = pcall(function()
		return HttpService:JSONDecode(Raw)
	end)
	if Decoded and type(Data) == "table" then
		return Data
	end
	return nil
end

local function WriteJson(Path, Data)
	if not HasFiles or not Path then
		return false
	end
	local OkEncode, Encoded = pcall(function()
		return HttpService:JSONEncode(Data)
	end)
	if not OkEncode or type(Encoded) ~= "string" then
		return false
	end

	if FileExists(Path) then
		local OkRead, Existing = pcall(readfile, Path)
		if OkRead and Existing == Encoded then
			return true
		end
	end

	EnsureFolder(GameFolder)
	local Ok = pcall(writefile, Path, Encoded)
	if not Ok then
		-- Create the parent folder and retry the write.
		local Parent = string.match(Path, "^(.*)/[^/]+$")
		EnsureFolder(Parent)
		Ok = pcall(writefile, Path, Encoded)
	end
	return Ok
end

local function ClientFiles()
	local Files = {}
	if not CanList or not FolderExists(GameFolder) then
		return Files
	end
	local Ok, List = pcall(listfiles, GameFolder)
	if not Ok or type(List) ~= "table" then
		return Files
	end
	for _, Entry in ipairs(List) do
		local Path = NormalizePath(Entry)
		if Path and string.sub(Path, -5) == ".json" then
			table.insert(Files, Path)
		end
	end
	return Files
end

-- ============================================================
-- 3) config store + auto save
-- ============================================================
if HasFiles then
	EnsureFolder(ROOT)
	EnsureFolder(GameFolder)
end

local Config = {}
local Values = {}
local Appliers = {}

local SaveMode = MODE_SEPARATE
do
	local Meta = ReadJson(MODE_FILE)
	if Meta and Meta.Mode == MODE_LINK then
		SaveMode = MODE_LINK
	end
end

local StatusText = HasFiles and "Ready" or "File API not available"

local function PickData()
	local Data = ReadJson(ClientFile)
	if Data then
		return Data
	end
	if SaveMode == MODE_LINK then
		for _, Path in ipairs(ClientFiles()) do
			Data = ReadJson(Path)
			if Data then
				return Data
			end
		end
	end
	return nil
end

local function LoadValues()
	local Data = PickData()
	if type(Data) == "table" and type(Data.Values) == "table" then
		Values = Data.Values
	end
end

local function SaveNow()
	if not HasFiles then
		StatusText = "File API not available"
		return false
	end
	EnsureFolder(ROOT)
	EnsureFolder(GameFolder)

	local Payload = {
		Client = ClientName,
		Executor = Executor,
		Game = game.Name,
		PlaceId = game.PlaceId,
		Mode = SaveMode,
		Updated = os.date("%Y-%m-%d %H:%M:%S"),
		Values = Values
	}

	local Saved = WriteJson(ClientFile, Payload)

	if SaveMode == MODE_LINK then
		for _, Path in ipairs(ClientFiles()) do
			if Path ~= ClientFile then
				WriteJson(Path, Payload)
			end
		end
	end

	StatusText = (Saved and "Saved " or "Save failed ") .. os.date("%H:%M:%S")
	return Saved
end

local SaveQueued = false
local Applying = false

local function QueueSave()
	if Applying or not HasFiles or SaveQueued then
		return
	end
	SaveQueued = true
	Delay(0.6, function()
		SaveQueued = false
		SaveNow()
	end)
end

Config.Values = Values
Config.Save = SaveNow
Config.QueueSave = QueueSave
Config.Mode = function()
	return SaveMode
end
Config.Path = function()
	return ClientFile
end

function Config.Get(Key, Fallback)
	local Value = Values[Key]
	if Value == nil then
		return Fallback
	end
	return Value
end

function Config.Set(Key, Value)
	Values[Key] = Value
	QueueSave()
end

-- ============================================================
-- 4) Bind helpers: create controls and enable automatic saving.
-- ============================================================
local Bind = {}

function Bind.Toggle(Group, Key, Option)
	Option = Option or {}
	local Control = Group:AddToggle(Key, {
		Text = Option.Text or Key,
		Desc = Option.Desc,
		Default = Config.Get(Key, Option.Default) == true,
		Callback = function(Value)
			Config.Set(Key, Value)
			if Option.Callback then
				Option.Callback(Value)
			end
		end
	})
	Appliers[Key] = function(Value)
		Control.SetStage(Value == true)
	end
	return Control
end

function Bind.Slider(Group, Key, Option)
	Option = Option or {}
	local Control = Group:AddSlider(Key, {
		Text = Option.Text or Key,
		Min = Option.Min or 0,
		Max = Option.Max or 100,
		Default = Config.Get(Key, Option.Default) or 0,
		Rouding = Option.Rouding,
		Callback = function(Value)
			Config.Set(Key, Value)
			if Option.Callback then
				Option.Callback(Value)
			end
		end
	})
	Appliers[Key] = function(Value)
		Control.SetValue(Value)
	end
	return Control
end

function Bind.Dropdown(Group, Key, Option)
	Option = Option or {}
	local Control = Group:AddDropdown(Key, {
		Text = Option.Text or Key,
		SubText = Option.SubText,
		Values = Option.Values,
		Default = Config.Get(Key, Option.Default),
		Callback = function(Value)
			Config.Set(Key, Value)
			if Option.Callback then
				Option.Callback(Value)
			end
		end
	})
	Appliers[Key] = function(Value)
		Control:SetValue(Value)
	end
	return Control
end

function Bind.Multi(Group, Key, Option)
	Option = Option or {}
	local Saved = Config.Get(Key, Option.Default)
	if type(Saved) ~= "table" then
		Saved = {}
	end
	local Control = Group:AddDropdown(Key, {
		Text = Option.Text or Key,
		SubText = Option.SubText,
		Multi = true,
		Values = Option.Values,
		Default = Saved,
		Callback = function(Value, IsSelected)
			local List = Values[Key]
			if type(List) ~= "table" then
				List = {}
				Values[Key] = List
			end
			local Index = TableFind(List, Value)
			if IsSelected and not Index then
				table.insert(List, Value)
			elseif not IsSelected and Index then
				table.remove(List, Index)
			end
			QueueSave()
			if Option.Callback then
				Option.Callback(Value, IsSelected)
			end
		end
	})
	Appliers[Key] = function(Value)
		Control:Clear()
		if type(Value) == "table" then
			for _, Name in ipairs(Value) do
				Control:SetValue(Name, true)
			end
		end
	end
	return Control
end

function Bind.Input(Group, Key, Option)
	Option = Option or {}
	local Control = Group:AddInput(Key, {
		Text = Option.Text or Key,
		Placeholder = Option.Placeholder,
		Default = Config.Get(Key, Option.Default),
		Callback = function(Value)
			Config.Set(Key, Value)
			if Option.Callback then
				Option.Callback(Value)
			end
		end
	})
	Appliers[Key] = function(Value)
		Control.SetValue(Value)
	end
	return Control
end

function Bind.Keybind(Group, Key, Option)
	Option = Option or {}
	local Control
	Control = Group:AddKeyBind({
		Title = Option.Text or Key,
		Default = Config.Get(Key, Option.Default) or "F",
		Mode = Option.Mode or "Toggle",
		Callback = function(Active)
			Config.Set(Key, Control:Get())
			if Option.Callback then
				Option.Callback(Active)
			end
		end
	})
	return Control
end

LoadValues()

Genv.Delex = {
	Config = Config,
	Bind = Bind,
	Folder = GameFolder,
	GameName = GameName,
	ClientFile = ClientFile,
	Client = ClientName,
	Executor = Executor,
	Compat = {
		Write = CanWrite,
		Read = CanRead,
		Folder = CanFolder,
		List = CanList,
		HttpGet = type(game.HttpGet) == "function",
		Loadstring = type(loadstring) == "function",
		Task = type(task) == "table",
	},
}

-- ============================================================
-- 5) window
-- ============================================================
local Window = Library:CreateWindow({
	Title = "Delex",
	Subtitle = os.date("%d/%m/%Y")
})

-- ===== Default tab (pinned just above Settings) =====
local MiscTab = Window:AddTab("Misc")
MiscTab:AddLeftGroupbox("Welcome"):AddLabel(
	"Delex UI",
	"Executor: " .. Executor,
	"Pick a tab on the left to begin."
)

-- ============================================================
-- Misc Player: client-side player utilities.
-- Features track the current Character and reapply after respawn.
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local PlayerGroup = MiscTab:AddRightGroupbox("Misc Player")

local PlayerState = {
	WalkSpeed = 16,
	JumpPower = 50,
	Flying = false,
	NoClip = false,
}

local Defaults = {
	Humanoid = nil,
	WalkSpeed = nil,
	JumpPower = nil,
	JumpHeight = nil,
	UseJumpHeight = false,
}

local FlyConn = nil
local NoClipConn = nil
local FlyBodyVelocity = nil
local FlyBodyGyro = nil
local FlyControl = nil
local FlyRenderConn = nil

local function GetHumanoid()
	local Character = LocalPlayer.Character
	if not Character then
		return nil
	end
	return Character:FindFirstChildOfClass("Humanoid")
end

local function GetRoot()
	local Character = LocalPlayer.Character
	if not Character then
		return nil
	end
	return Character:FindFirstChild("HumanoidRootPart") or Character.PrimaryPart
end

local function RememberDefaults(Humanoid)
	if not Humanoid or Defaults.Humanoid == Humanoid then
		return
	end
	Defaults.Humanoid = Humanoid
	Defaults.WalkSpeed = Humanoid.WalkSpeed
	Defaults.JumpPower = Humanoid.JumpPower
	Defaults.JumpHeight = Humanoid.JumpHeight
	Defaults.UseJumpHeight = Humanoid.UseJumpPower == false
end

local function ApplyMovement()
	local Humanoid = GetHumanoid()
	if not Humanoid then
		return
	end
	pcall(function()
		Humanoid.WalkSpeed = PlayerState.WalkSpeed
	end)
	pcall(function()
		if Defaults.UseJumpHeight then
			Humanoid.UseJumpPower = false
			Humanoid.JumpHeight = PlayerState.JumpPower / 7 * 2.5
		else
			Humanoid.UseJumpPower = true
			Humanoid.JumpPower = PlayerState.JumpPower
		end
	end)
end

-- Reapply enabled features after each character respawn.
local ApplyNoClip, ApplyFly, StopFly

local function OnCharacterAdded(Character)
	task.defer(function()
		local Humanoid = Character:WaitForChild("Humanoid", 10)
		if not Humanoid then
			return
		end
		Defaults.Humanoid = nil
		RememberDefaults(Humanoid)
		ApplyMovement()

		if PlayerState.NoClip then
			ApplyNoClip(true)
		end

		if PlayerState.Flying then
			ApplyFly(true)
		end
	end)
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
if LocalPlayer.Character then
	RememberDefaults(GetHumanoid())
end

-- ---------- speed & jump ----------
Delex.Bind.Slider(PlayerGroup, "WalkSpeed", {
	Text = "Walk Speed",
	Desc = "Default is 16",
	Min = 16,
	Max = 500,
	Default = 16,
	Rouding = 0,
	Callback = function(Value)
		PlayerState.WalkSpeed = Value
		ApplyMovement()
	end
})

Delex.Bind.Slider(PlayerGroup, "JumpPower", {
	Text = "Jump Power",
	Desc = "Default is 50",
	Min = 50,
	Max = 500,
	Default = 50,
	Rouding = 0,
	Callback = function(Value)
		PlayerState.JumpPower = Value
		ApplyMovement()
	end
})

PlayerGroup:AddButton({
	Text = "Reset Speed & Jump",
	Func = function()
		local Humanoid = GetHumanoid()
		PlayerState.WalkSpeed = 16
		PlayerState.JumpPower = 50
		if Humanoid and Defaults.WalkSpeed then
			pcall(function()
				Humanoid.WalkSpeed = Defaults.WalkSpeed
			end)
		end
		Library:Notify({
			Title = "Misc Player",
			Description = "Speed and jump reset to 16 / 50",
			Duration = 3
		}, true)
	end
})

-- ---------- noclip ----------
ApplyNoClip = function(Enable)
	if NoClipConn then
		NoClipConn:Disconnect()
		NoClipConn = nil
	end
	if not Enable then
		local Character = LocalPlayer.Character
		if Character then
			for _, Part in ipairs(Character:GetDescendants()) do
				if Part:IsA("BasePart") and Part.CanCollide == false then
					pcall(function()
						Part.CanCollide = true
					end)
				end
			end
		end
		return
	end

	NoClipConn = RunService.Stepped:Connect(function()
		local Character = LocalPlayer.Character
		if not Character then
			return
		end
		for _, Part in ipairs(Character:GetDescendants()) do
			if Part:IsA("BasePart") and Part.CanCollide then
				Part.CanCollide = false
			end
		end
	end)
end

Delex.Bind.Toggle(PlayerGroup, "NoClip", {
	Text = "No Clip",
	Desc = "Walk through walls",
	Default = false,
	Callback = function(Value)
		PlayerState.NoClip = Value
		ApplyNoClip(Value)
	end
})

-- ---------- fly ----------
StopFly = function()
	if FlyConn then
		FlyConn:Disconnect()
		FlyConn = nil
	end
	if FlyRenderConn then
		FlyRenderConn:Disconnect()
		FlyRenderConn = nil
	end
	if FlyControl then
		FlyControl:Destroy()
		FlyControl = nil
	end
	if FlyBodyVelocity then
		FlyBodyVelocity:Destroy()
		FlyBodyVelocity = nil
	end
	if FlyBodyGyro then
		FlyBodyGyro:Destroy()
		FlyBodyGyro = nil
	end
	local Humanoid = GetHumanoid()
	if Humanoid then
		pcall(function()
			Humanoid.PlatformStand = false
		end)
	end
end

ApplyFly = function(Enable)
	StopFly()
	if not Enable then
		return
	end

	local Root = GetRoot()
	local Humanoid = GetHumanoid()
	if not Root or not Humanoid then
		PlayerState.Flying = false
		return
	end

	pcall(function()
		Humanoid.PlatformStand = true
	end)

	local Camera = workspace.CurrentCamera

	FlyBodyVelocity = Instance.new("BodyVelocity")
	FlyBodyVelocity.Name = "DelexFly"
	FlyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	FlyBodyVelocity.Velocity = Vector3.zero
	FlyBodyVelocity.Parent = Root

	FlyBodyGyro = Instance.new("BodyGyro")
	FlyBodyGyro.Name = "DelexFlyGyro"
	FlyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	FlyBodyGyro.P = 2000
	FlyBodyGyro.Parent = Root

	local UIS = game:GetService("UserInputService")

	FlyRenderConn = RunService.RenderStepped:Connect(function()
		if not Root or not Root.Parent then
			return
		end
		local Look = Camera and Camera.CFrame.LookVector or Vector3.new(0, 0, -1)
		FlyBodyGyro.CFrame = CFrame.new(Root.Position, Root.Position + Look)

		local Move = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then
			Move = Move + Look
		end
		if UIS:IsKeyDown(Enum.KeyCode.S) then
			Move = Move - Look
		end
		if UIS:IsKeyDown(Enum.KeyCode.A) then
			Move = Move - (Look:Cross(Vector3.new(0, 1, 0)))
		end
		if UIS:IsKeyDown(Enum.KeyCode.D) then
			Move = Move + (Look:Cross(Vector3.new(0, 1, 0)))
		end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then
			Move = Move + Vector3.new(0, 1, 0)
		end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
			Move = Move - Vector3.new(0, 1, 0)
		end

		if Move.Magnitude > 0 then
			FlyBodyVelocity.Velocity = Move.Unit * PlayerState.FlySpeed
		else
			FlyBodyVelocity.Velocity = Vector3.zero
		end
	end)
end

PlayerState.FlySpeed = 60

Delex.Bind.Slider(PlayerGroup, "FlySpeed", {
	Text = "Fly Speed",
	Desc = "WASD to move, Space up, Left Ctrl down",
	Min = 10,
	Max = 500,
	Default = 60,
	Rouding = 0,
	Callback = function(Value)
		PlayerState.FlySpeed = Value
	end
})

Delex.Bind.Toggle(PlayerGroup, "Fly", {
	Text = "Fly",
	Desc = "Toggle the fly system",
	Default = false,
	Callback = function(Value)
		PlayerState.Flying = Value
		ApplyFly(Value)
	end
})

-- ===== Final tab: Settings =====
local SettingsTab = Window:AddTab("Settings")
local SaveGroup = SettingsTab:AddLeftGroupbox("Save Setting Config")

local function CompatLine()
	local Parts = {}
	if CanWrite then table.insert(Parts, "write") end
	if CanRead then table.insert(Parts, "read") end
	if CanFolder then table.insert(Parts, "folder") end
	if CanList then table.insert(Parts, "list") end
	if #Parts == 0 then
		return "none"
	end
	return table.concat(Parts, ", ")
end

local function PathText()
	if not HasFiles then
		return "File API not available on this executor.\nConfig will not be saved."
	end
	local Count = #ClientFiles()
	local Lines = {
		"Folder: " .. GameFolder,
		"PlaceId: " .. tostring(game.PlaceId),
		"Name from: " .. GameNameSource,
		"Client: " .. ClientName .. " (" .. Executor .. ")",
		"Files: " .. tostring(Count),
		"File API: " .. CompatLine(),
		"Status: " .. StatusText,
	}
	if not CanList then
		table.insert(Lines, "Note: listfiles missing - link mode only writes own file")
	end
	return table.concat(Lines, "\n")
end

local PathLabel = SaveGroup:AddLabel(PathText())

local SaveModeControl = SaveGroup:AddDropdown("SaveMode", {
	Text = "Save Mode",
	SubText = "Separate per client or linked",
	Values = { MODE_SEPARATE, MODE_LINK },
	Default = SaveMode,
	Callback = function(Value)
		SaveMode = Value
		EnsureFolder(ROOT)
		WriteJson(MODE_FILE, { Mode = SaveMode })
		-- In linked mode, copy the current values to every existing client file in this game's folder.
		Applying = true
		SaveNow()
		Applying = false
		PathLabel:SetText(PathText())
	end
})
SaveModeControl:ClearText(SaveMode)

SaveGroup:AddButton({
	Text = "Save Now",
	Func = function()
		SaveNow()
		PathLabel:SetText(PathText())
		Library:Notify({
			Title = "Config",
			Description = StatusText,
			Duration = 3
		}, true)
	end
})

SaveGroup:AddButton({
	Text = "Reload From File",
	Func = function()
		local Data = PickData()
		if type(Data) ~= "table" or type(Data.Values) ~= "table" then
			Library:Notify({
				Title = "Config",
				Description = "No saved file found",
				Duration = 3
			}, true)
			return
		end

		Applying = true
		Values = Data.Values
		Config.Values = Values
		for Key, Applier in pairs(Appliers) do
			local Value = Values[Key]
			if Value ~= nil then
				pcall(Applier, Value)
			end
		end
		Applying = false
		PathLabel:SetText(PathText())

		Library:Notify({
			Title = "Config",
			Description = "Reloaded from file",
			Duration = 3
		}, true)
	end
})

-- Set a custom folder name for this game (saved in Delex/GameNames.json; applies after restart).
SaveGroup:AddInput("GameFolderName", {
	Text = "Game Folder Name",
	Placeholder = "e.g. Durian Garden (restart to apply)",
	Default = GameName,
	Callback = function(Value)
		if Value == nil or Value == "" then
			return
		end
		local Saved = StoreGameName(game.PlaceId, Value)
		Library:Notify({
			Title = "Config",
			Description = Saved
				and ("Saved: " .. Sanitize(Value) .. " - restart script to apply")
				or "Save failed (file API unavailable)",
			Duration = 5
		}, true)
		PathLabel:SetText(PathText())
	end
})

-- Show the PlaceId so it can be added to CONFIG.GameNames in this loader.
SaveGroup:AddLabel("PlaceId of this game: " .. tostring(game.PlaceId))

local InfoGroup = SettingsTab:AddRightGroupbox("Info")
InfoGroup:AddLabel(
	"Executor: " .. Executor,
	"File API: " .. CompatLine()
)

-- ===== Contact information: Discord =====
local DiscordInvite = "https://discord.gg/wpewEjDhCs"

local function CopyToClipboard(Text)
	local Ok = pcall(function()
		if type(setclipboard) == "function" then
			setclipboard(Text)
			return true
		end
		if type(toclipboard) == "function" then
			toclipboard(Text)
			return true
		end
		if type(writeclipboard) == "function" then
			writeclipboard(Text)
			return true
		end
		error("no clipboard api")
	end)
	return Ok
end

InfoGroup:AddLabel("Discord: " .. DiscordInvite)

InfoGroup:AddButton({
	Text = "Copy Discord Link",
	Func = function()
		local Ok = CopyToClipboard(DiscordInvite)
		Library:Notify({
			Title = "Discord",
			Description = Ok and "Invite link copied" or ("Copy failed: " .. DiscordInvite),
			Duration = 4
		}, true)
	end
})

-- ===== Settings UI: theme and toggle-key controls =====
local UiGroup = SettingsTab:AddLeftGroupbox("Settings UI")

-- Fallback palette is built into the loader for older GitHub library versions.
-- Theme selection still works without uploading the latest library file.
local FallbackThemes = {
	Blue = { 0, 140, 255, 0, 100, 210, 0, 75, 160 },
	Red = { 255, 0, 0, 200, 0, 0, 170, 0, 0 },
	Green = { 0, 220, 130, 0, 170, 100, 0, 130, 80 },
	Purple = { 170, 90, 255, 130, 60, 210, 100, 40, 170 },
	Orange = { 255, 150, 40, 210, 110, 20, 170, 85, 15 },
	White = { 235, 235, 230, 200, 200, 195, 170, 170, 165 },
}
local AccentKeys = {
	"Border Color", "Search Icon Highlight Color", "Title Text Color", "Page Selected Color",
	"Section Underline Color", "Toggle Border Color", "Button Color", "Dropdown Selected Color",
	"Textbox Highlight Color", "Box Highlight Color", "Slider Line Color",
}

local function ThemeTable(Name)
	local Set = FallbackThemes[Name]
	if not Set then
		return nil
	end
	local Accent = Color3.fromRGB(Set[1], Set[2], Set[3])
	local Dark = Color3.fromRGB(Set[4], Set[5], Set[6])
	local Deep = Color3.fromRGB(Set[7], Set[8], Set[9])
	local Colors = {}
	for _, Key in ipairs(AccentKeys) do
		Colors[Key] = Accent
	end
	Colors["Slider Highlight Color"] = Dark
	Colors["Dropdown Selected Check Color"] = Deep
	return Colors
end

-- Change colors by walking the live GUI tree (does not require library theme APIs).
local function ForceTheme(Colors)
	if type(Colors) ~= "table" then
		return false
	end
	local UIColors = getgenv().UIColor
	if type(UIColors) ~= "table" then
		return false
	end
	for Key, Value in pairs(Colors) do
		UIColors[Key] = Value
	end

	local Map = {
		TextColor = { "TextColor3", "Text Color" },
		GUITextColor = { "TextColor3", "Text Color" },
		Sectiontitle = { "TextColor3", "Section Text Color" },
		ToggleDesc = { "TextColor3", "Toggle Desc Color" },
		PageInLine = { "BackgroundColor3", "Page Selected Color" },
		Linesec = { "BackgroundColor3", "Section Underline Color" },
		check = { "BackgroundColor3", "Toggle Border Color" },
		checkbox = { "ImageColor3", "Toggle Border Color" },
		Bar = { "BackgroundColor3", "Slider Line Color" },
		ImgDrop = { "ImageColor3", "Dropdown Icon Color" },
		TextNSBoxLineeeee = { "BackgroundColor3", "Box Highlight Color" },
		Background1 = { "BackgroundColor3", "Background 1 Color" },
		Background2 = { "BackgroundColor3", "Background 2 Color" },
		LabelBG = { "BackgroundColor3", "Label Color" },
		TopStroke = { "BackgroundColor3", "Border Color" },
	}

	local Count = 0
	local function Walk(Instance_)
		local Rule = Map[Instance_.Name]
		if Rule then
			local Value = UIColors[Rule[2]]
			if Value ~= nil then
				local Ok = pcall(function()
					Instance_[Rule[1]] = Value
				end)
				if Ok then
					Count = Count + 1
				end
			end
		end
		for _, Child in ipairs(Instance_:GetChildren()) do
			Walk(Child)
		end
	end

	local CoreGui = getgenv().DelexGuiFolder
	local Roots = {}
	for _, Candidate in ipairs({ CoreGui, game:GetService("CoreGui"), LocalPlayer:FindFirstChild("PlayerGui") }) do
		if Candidate and typeof(Candidate) == "Instance" then
			table.insert(Roots, Candidate)
		end
	end

	for _, Root in ipairs(Roots) do
		for _, Child in ipairs(Root:GetChildren()) do
			if string.find(Child.Name, "Delex", 1, true) then
				Walk(Child)
			end
		end
	end

	-- The floating toggle button is outside the main window GUI.
	local ToggleButton = getgenv().DelexToggleButton
	if ToggleButton then
		for _, Child in ipairs(ToggleButton:GetChildren()) do
			if Child:IsA("UIStroke") then
				pcall(function()
					Child.Color = UIColors["Border Color"]
				end)
			end
		end
	end
	return Count > 0
end

local function ApplyThemeByName(Name)
	local Colors = ThemeTable(Name)
	if not Colors then
		return false
	end

	-- Prefer the library theme API when available; otherwise walk the live GUI tree.
	if type(Library.SetTheme) == "function" then
		local Ok = pcall(function()
			Library:SetTheme(Name)
		end)
		if Ok then
			return true
		end
	end

	local Ok = pcall(ForceTheme, Colors)
	if not Ok then
		return false
	end
	-- The updated UIColor values allow this fallback to reapply the theme on later calls.
	return true
end

local ThemeNames = {}
do
	local FromLib = nil
	if type(Library.GetThemeNames) == "function" then
		local Ok, List = pcall(function()
			return Library:GetThemeNames()
		end)
		if Ok and type(List) == "table" and #List > 0 then
			FromLib = List
		end
	end
	if FromLib then
		ThemeNames = FromLib
	else
		for Name in pairs(FallbackThemes) do
			table.insert(ThemeNames, Name)
		end
		table.sort(ThemeNames)
	end
end

local CurrentTheme = Config.Get("UiTheme", nil) or "Blue"

local ThemeControl = UiGroup:AddDropdown("UiTheme", {
	Text = "UI Color",
	SubText = "Accent color of the whole UI",
	Values = ThemeNames,
	Default = CurrentTheme,
	Callback = function(Value)
		local Changed = ApplyThemeByName(Value)
		Config.Set("UiTheme", Value)
		Library:Notify({
			Title = "Theme",
			Description = Changed and ("Color changed to " .. tostring(Value)) or "Color change failed",
			Duration = 2
		}, true)
	end
})
ThemeControl:ClearText(CurrentTheme)

local KeyControl
KeyControl = UiGroup:AddKeyBind({
	Title = "Toggle UI Key",
	Default = Config.Get("UiToggleKey", "RightControl"),
	Mode = "Toggle",
	Callback = function()
		local Key = KeyControl:Get()
		if type(Library.SetToggleKey) == "function" then
			Library:SetToggleKey(Key)
		else
			-- Fallback: write the variable read by the key handler in the library.
			getgenv().DelexToggleKey = Key
		end
		Config.Set("UiToggleKey", Key)
	end
})

UiGroup:AddLabel("The key above folds / unfolds this UI.")

-- Apply saved settings during startup.
local SavedTheme = Config.Get("UiTheme", nil)
if SavedTheme then
	ApplyThemeByName(SavedTheme)
	ThemeControl:ClearText(SavedTheme)
end
local SavedKey = Config.Get("UiToggleKey", nil)
if SavedKey then
	getgenv().DelexToggleKey = SavedKey
	if type(Library.SetToggleKey) == "function" then
		pcall(function()
			Library:SetToggleKey(SavedKey)
		end)
	end
	pcall(function()
		KeyControl:Set(SavedKey)
	end)
end

-- ===== Add your tabs here (they will appear above Misc) =====
-- Example:
-- local Tab = Window:AddTab("Farm")
-- local Group = Tab:AddLeftGroupbox("Farm")
-- Delex.Bind.Toggle(Group, "AutoFarm", { Text = "Enable Farm", Default = false })
-- Delex.Bind.Slider(Group, "FarmDelay", { Text = "Delay", Min = 0, Max = 5, Rouding = 1, Default = 0.5 })

-- Pin Misc above Settings at the bottom of the tab list.
local Ordered = pcall(function()
	Window.layoutOrder("Misc", "Settings")
end)
if not Ordered then
	Log("layoutOrder is missing - upload the latest lib.lua to GitHub")
end

-- Write an initial config file so the folder structure exists immediately.
SaveNow()
PathLabel:SetText(PathText())

Library:Notify({
	Title = "Loaded",
	Description = HasFiles and ("Config: " .. ClientFile) or "Config saving unavailable",
	Duration = 4
}, true)

return Library
