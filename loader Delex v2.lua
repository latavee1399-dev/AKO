-- ============================================================
-- Delex UI - loader (executor-agnostic)
-- รองรับ executor หลากหลาย: มี fallback สำหรับทุกฟังก์ชันที่ใช้
-- RightCtrl = เปิด/ปิด UI
--
-- โครงไฟล์ config ที่ระบบสร้างให้:
--   Delex/GameNames.json                         <- ชื่อโฟลเดอร์ของแต่ละเกม (แคช)
--   Delex/SaveMode.json                          <- จำโหมดแชร์/แยก
--   Delex/<ชื่อเกม>_<PlaceId>/<ชื่อผู้เล่น>.json   <- ค่าที่ตั้งไว้
--
-- โหมด Save:
--   Separate Per Client = แต่ละ client แยกค่ากัน
--   Link All Clients    = ทุก client ในโฟลเดอร์เกมใช้ค่าเดียวกัน
--
-- วิธีตั้งชื่อโฟลเดอร์เกม
--   A) แก้ CONFIG.GameNames ด้านล่าง (ถาวร ใช้ได้ทุกเครื่อง)
--   B) ตั้งก่อนโหลด loader (ไม่ต้องแก้ไฟล์บน GitHub):
--        getgenv().DelexLoaderConfig = { GameName = "Durian Garden" }
--        loadstring(game:HttpGet(url))()
--   C) แก้ในเกม: Settings > Save Setting Config > Game Folder Name
--   D) ปล่อยว่าง ระบบถาม Roblox API ให้เอง (เกมทั่วไปได้ชื่อจริง)
--
-- ข้อความที่แสดงในเกมต้องเป็นอังกฤษ เพราะฟอนต์ Roblox ไม่มีไทย
-- ============================================================

-- ============================================================
-- 0) CONFIG — ค่าเริ่มต้น (แก้ในไฟล์นี้ หรือส่งเข้ามาตอน loadstring ก็ได้)
-- ============================================================
local CONFIG = {
	-- ตั้งชื่อโฟลเดอร์ของแต่ละเกมเอง: [PlaceId] = "ชื่อโฟลเดอร์"
	-- เกมที่ไม่อยู่ในตารางนี้ ระบบจะหาชื่อจริงให้เอง (API -> game.Name -> Game_<PlaceId>)
	-- ดู PlaceId ได้จาก print(game.PlaceId) หรือบรรทัด PlaceId ในแท็บ Settings
	GameNames = {
		[54849] = "Durian Garden",
	},

	-- true = ไม่ต้องถาม API ของ Roblox (เร็วขึ้น แต่เกมที่ชื่อภายในจะได้ Game_<PlaceId>)
	SkipNameApi = false,

	-- ปิดท้ายชื่อโฟลเดอร์ด้วย PlaceId อัตโนมัติ (กันเกมชื่อซ้ำกันเขียนทับกัน)
	AppendPlaceId = true,

	-- โฟลเดอร์รากของ config
	RootFolder = "Delex",
}

-- ============================================================
-- 0.1) ตั้งชื่อเกมจากภายนอก (ก่อน loadstring)
--   getgenv().DelexLoaderConfig = { GameName = "Durian Garden" }
--   loadstring(game:HttpGet(url))()
-- หรือใช้ getgenv().Config = { GameName = "..." } ก็ได้
-- มีผลกับโฟลเดอร์ของ "เกมที่กำลังเล่นอยู่" เท่านั้น
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
-- 1) compat shims (ทำงานก่อนทุกอย่าง)
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

-- ชื่อ executor: แต่ละตัวมีฟังก์ชันไม่เหมือนกัน และบางตัวไม่มีเลย
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

	-- จับจาก global ที่แต่ละ executor ทิ้งไว้
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

-- HTTP: game.HttpGet เป็นหลัก ถ้าไม่มีค่อยลองอย่างอื่น
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

-- กันกรณีวันหลังอัปไฟล์แบบ all-in-one (ที่มี runner ในตัว) จะได้ไม่เปิด 2 หน้าต่าง
Genv.GravityHubManual = true

local Library = Chunk()
if type(Library) ~= "table" or type(Library.CreateWindow) ~= "function" then
	error("[Delex] library did not return a Library table (file must end with: return Library)", 0)
end

local HttpService = game:GetService("HttpService")

-- ============================================================
-- 2) file API (ตรวจแล้วใช้ fallback ถ้าขาด)
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

-- ชื่อผู้เล่น Roblox ใช้เป็นชื่อไฟล์ config
local function PlayerName()
	local Ok, Player = pcall(function()
		return game:GetService("Players").LocalPlayer
	end)
	if Ok and Player and Player.Name ~= "" then
		return Sanitize(Player.Name)
	end
	return "Player"
end

-- ชื่อโฟลเดอร์เฉพาะเกมอยู่ใน CONFIG ด้านบนสุดของไฟล์ (CONFIG.GameNames)

-- แคชชื่อเกม: จำไว้ที่ Delex/GameNames.json ตั้งชื่อเกมหนึ่งครั้งใช้ได้ตลอด
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

-- เขียนชื่อเกมลงแคช (Delex/GameNames.json)
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
	-- ต้องมีโฟลเดอร์ Delex ก่อน ไม่งั้น writefile ล้มเหลว
	if type(makefolder) == "function" and type(isfolder) == "function" then
		if not isfolder(CONFIG.RootFolder) then
			pcall(makefolder, CONFIG.RootFolder)
		end
	end
	return (pcall(writefile, NAMES_FILE, Encoded))
end

-- ชื่อแบบภายในของ Roblox เช่น "Ugc", "Ugc_91350038154849", "Place_123", "12345"
-- เก็บที่มาของชื่อ เพื่อโชว์ใน UI ว่ามาจากไหน
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

-- ชื่อเกมจาก API ตัวเดียวกับที่หน้าเว็บ Roblox ใช้ (แม่นกว่า game.Name)
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
		-- ไม่ได้ universeId: ลองใช้ placeDetails ซึ่งคืนชื่อ place ตรง ๆ
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

-- MarketplaceService เป็นทางสำรอง (บาง place คืนชื่อภายในจึงต้องกรองออก)
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
	-- 1) ชื่อจาก CONFIG.GameNames (ตารางด้านบนของไฟล์) — ชนะทุกอย่าง
	local Override = CONFIG.GameNames[game.PlaceId]
		or CONFIG.GameNames[tostring(game.PlaceId)]
	if type(Override) == "string" and Override ~= "" then
		GameNameSource = "config"
		return Sanitize(Override)
	end

	-- 2) ชื่อที่เคยตั้งไว้ในเกมนี้ (Delex/GameNames.json)
	local Cached = NameCache[tostring(game.PlaceId)]
	if type(Cached) == "string" and Cached ~= "" then
		GameNameSource = "saved"
		return Sanitize(Cached)
	end

	-- 3) ชื่อจาก Roblox API
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

	-- 5) ไม่รู้อะไรเลย
	GameNameSource = "fallback"
	return "Game_" .. tostring(game.PlaceId)
end

LoadNameCache()
local GameName = ResolveGameName()

-- จำชื่อที่เจออัตโนมัติไว้ใน GameNames.json เพื่อไม่ต้องถามซ้ำในครั้งหน้า
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

-- ต่อ PlaceId ท้ายชื่อเสมอ กันเกมชื่อซ้ำกันเขียนทับกัน
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
	-- บาง executor คืนมาแค่ชื่อไฟล์ ไม่ใช่ path เต็ม
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
		-- ลองสร้างโฟลเดอร์แม่แล้วเขียนอีกรอบ
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
-- 4) bind helpers (สร้างคอนโทรล + เซฟอัตโนมัติ)
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

-- ===== แท็บเริ่มต้น (อยู่บนสุดของกลุ่มล่างเสมอ) =====
local MiscTab = Window:AddTab("Misc")
MiscTab:AddLeftGroupbox("Welcome"):AddLabel(
	"Delex UI",
	"Executor: " .. Executor,
	"Pick a tab on the left to begin."
)

-- ============================================================
-- Misc Player: ฟีเจอร์ช่วยเหลือผู้เล่น (client-side)
-- ทุกอย่างผูกกับ Character ปัจจุบัน และกู้ค่าเดิมเมื่อปิด/respawn
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

-- เรียกซ้ำทุกครั้งที่ respawn เพื่อไม่ให้ค่าหาย
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

-- ===== แท็บล่างสุด: Settings =====
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
		-- เข้าลิงก์: ดันค่าปัจจุบันของเราลงทุกไฟล์ที่มีในโฟลเดอร์เกม
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

-- ตั้งชื่อโฟลเดอร์เกมนี้เองได้ (บันทึกลง Delex/GameNames.json มีผลรอบถัดไป)
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

-- บอก PlaceId ให้เห็นชัด ๆ เพื่อเอาไปใส่ใน CONFIG.GameNames ของ loader
SaveGroup:AddLabel("PlaceId of this game: " .. tostring(game.PlaceId))

local InfoGroup = SettingsTab:AddRightGroupbox("Info")
InfoGroup:AddLabel(
	"Executor: " .. Executor,
	"File API: " .. CompatLine()
)

-- ===== ช่องทางติดต่อ: Discord =====
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

-- ===== Settings UI: เปลี่ยนสี + ปุ่มคีย์ลัด =====
local UiGroup = SettingsTab:AddLeftGroupbox("Settings UI")

-- พาเลตต์สำรองฝังใน loader: ถ้า lib บน GitHub ยังเป็นเวอร์ชันเก่า (ไม่มี SetTheme)
-- สีจะยังเปลี่ยนได้ โดยไม่ต้องรออัปไฟล์ไลบรารี
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

-- เปลี่ยนสีด้วยการเดินสำรวจ GUI จริง (ไม่ต้องพึ่ง API ใน lib)
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

	-- ปุ่มลอยอยู่นอก GUI หลัก
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

	-- ใช้ API ของ lib ถ้ามี (อัปเดตครบกว่า) ถ้าไม่มีก็ใช้วิธีสำรวจ GUI
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
	-- ตั้งแต่รอบสองเป็นต้นไป สีใน UIColor ถูกเปลี่ยนแล้ว จึงเรียกซ้ำได้ผล
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
			-- สำรอง: ตั้งค่าที่ตัวแปรเดียวกับที่ handler ใน lib อ่าน
			getgenv().DelexToggleKey = Key
		end
		Config.Set("UiToggleKey", Key)
	end
})

UiGroup:AddLabel("The key above folds / unfolds this UI.")

-- ค่าที่เซฟไว้มีผลตั้งแต่เปิดสคริปต์
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

-- ===== เพิ่มแท็บของคุณตรงนี้ (จะไปอยู่เหนือ Misc) =====
-- ตัวอย่าง:
-- local Tab = Window:AddTab("Farm")
-- local Group = Tab:AddLeftGroupbox("Farm")
-- Delex.Bind.Toggle(Group, "AutoFarm", { Text = "Enable Farm", Default = false })
-- Delex.Bind.Slider(Group, "FarmDelay", { Text = "Delay", Min = 0, Max = 5, Rouding = 1, Default = 0.5 })

-- สั่งให้ Misc อยู่บนสุดของกลุ่มล่าง และ Settings ล่างสุดตลอด
local Ordered = pcall(function()
	Window.layoutOrder("Misc", "Settings")
end)
if not Ordered then
	Log("layoutOrder is missing - upload the latest lib.lua to GitHub")
end

-- เขียนไฟล์ตั้งต้นรอบแรก เพื่อให้เห็นโครงโฟลเดอร์ทันที
SaveNow()
PathLabel:SetText(PathText())

Library:Notify({
	Title = "Loaded",
	Description = HasFiles and ("Config: " .. ClientFile) or "Config saving unavailable",
	Duration = 4
}, true)

return Library
