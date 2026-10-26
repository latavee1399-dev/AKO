-- ============================================================
-- Delex - library only
-- ไฟล์นี้ "ไม่" เปิด UI เอง มันคืนค่า Library ออกไป
-- วิธีใช้:
--   local Chunk = assert(loadstring(game:HttpGet("<url ของไฟล์นี้>")))
--   local Library = Chunk()
--   local Window = Library:CreateWindow({ Title = "Delex" })
-- โลโก้/ธีม แก้ที่บล็อก LOGO ด้านล่าง
-- ============================================================

-- ============================================================
-- compat: รองรับ executor ที่ไม่มี getgenv / get_hui / task
-- ============================================================
if type(getgenv) ~= "function" then
	function getgenv()
		return _G
	end
end

-- เลือก container ที่เอา ScreenGui ไปแปะได้จริง (บาง executor ไม่ให้เขียน CoreGui)
local function ResolveGuiParent()
	local Candidates = {}

	local OkHui, Hui = pcall(function()
		return gethui and gethui()
	end)
	if OkHui and typeof and typeof(Hui) == "Instance" then
		table.insert(Candidates, Hui)
	elseif OkHui and Hui ~= nil then
		table.insert(Candidates, Hui)
	end

	local OkCore, CoreGui = pcall(function()
		return game:GetService("CoreGui")
	end)
	if OkCore and CoreGui then
		table.insert(Candidates, CoreGui)
	end

	local OkPlayer, PlayerGui = pcall(function()
		return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 10)
	end)
	if OkPlayer and PlayerGui then
		table.insert(Candidates, PlayerGui)
	end

	for _, Parent in ipairs(Candidates) do
		local Ok, Test = pcall(function()
			local Probe = Instance.new("ScreenGui")
			Probe.Name = "DelexProbe"
			Probe.Parent = Parent
			Probe:Destroy()
			return true
		end)
		if Ok and Test then
			return Parent
		end
	end

	return nil
end

local GuiParent = ResolveGuiParent()

if getgenv().Nousigi then 
	if GuiParent and GuiParent:FindFirstChild("Delex GUI") then
		for i, v in ipairs(GuiParent:GetChildren()) do
			if string.find(v.Name,  "Delex") then
				v:Destroy()
			end
		end
	end
end
getgenv().Nousigi = true

-- เก็บกวาด UI ชื่อเก่า (Gravity Hub) ที่ยังค้างจากเวอร์ชันก่อน ถ้ามี
if GuiParent then
	for _, Gui in ipairs(GuiParent:GetChildren()) do
		if string.find(Gui.Name, "Gravity Hub", 1, true) then
			Gui:Destroy()
		end
	end
end

local DisableAnimation = game.Players.LocalPlayer.PlayerGui:FindFirstChild('TouchGui')

-- ============================================================
-- LOGO: แก้ตรงนี้ที่เดียว
--   LOGO_IMAGE     = รูปในเกม (rbxassetid://...) ใช้เมื่อ LOGO_URL ว่าง
--   LOGO_URL       = ลิงก์ .png ตรง ๆ (ต้องมี writefile + getcustomasset)
--                    *** ถ้า LOGO_URL ไม่ว่าง มันจะทับ LOGO_IMAGE เสมอ ***
--   LOGO_ASPECT    = ใส่เฉพาะตอนรู้สัดส่วน เช่น 1.5 สำหรับรูปแนวนอน
--                    ปล่อยเป็น nil ได้ รูปสี่เหลี่ยมจัตุรัสไม่ต้องใส่
--   LOGO_NATIVE_ID = รูปที่เลย์เอาต์ถูกจูนไว้แล้ว (4:3 มีขอบโปร่งใส) ไม่ต้องแก้
-- ============================================================
local LOGO_IMAGE = "rbxassetid://97074562899662"
local LOGO_URL = ""
local LOGO_ASPECT = nil
local LOGO_NATIVE_ID = "rbxassetid://85591093437630"

local T1UIColor = {
	["Border Color"] = Color3.fromRGB(0, 140, 255),
	["Click Effect Color"] = Color3.fromRGB(230, 230, 230),
	["Setting Icon Color"] = Color3.fromRGB(230, 230, 230),
	["Logo Image"] = LOGO_IMAGE,
	["Logo Url"] = LOGO_URL,
	["Logo Aspect"] = LOGO_ASPECT,
	["Search Icon Color"] = Color3.fromRGB(240, 240, 230),
	["Search Icon Highlight Color"] = Color3.fromRGB(0, 140, 255),
	["GUI Text Color"] = Color3.fromRGB(235, 235, 230),
	["Text Color"] = Color3.fromRGB(235, 235, 230),
	["Placeholder Text Color"] = Color3.fromRGB(170, 170, 160),
	["Title Text Color"] = Color3.fromRGB(0, 140, 255),
	["Background Main Color"] = Color3.fromRGB(14, 20, 32),
	["Background 1 Color"] = Color3.fromRGB(24, 32, 46),
	["Background 1 Transparency"] = 0.1,
	["Background 2 Color"] = Color3.fromRGB(34, 44, 62),
	["Background 3 Color"] = Color3.fromRGB(44, 56, 78),
	["Background Image"] = "",
	["Page Selected Color"] = Color3.fromRGB(0, 140, 255),
	["Section Text Color"] = Color3.fromRGB(220, 220, 210),
	["Section Underline Color"] = Color3.fromRGB(0, 140, 255),
	["Toggle Border Color"] = Color3.fromRGB(0, 140, 255),
	["Toggle Checked Color"] = Color3.fromRGB(230, 230, 230),
	["Toggle Desc Color"] = Color3.fromRGB(185, 185, 185),
	["Button Color"] = Color3.fromRGB(0, 140, 255),
	["Label Color"] = Color3.fromRGB(34, 44, 62),
	["Dropdown Icon Color"] = Color3.fromRGB(230, 230, 230),
	["Dropdown Selected Color"] = Color3.fromRGB(0, 140, 255),
	["Dropdown Selected Check Color"] = Color3.fromRGB(0, 75, 160),
	["Dropdown Selected Text Color"] = Color3.fromRGB(255, 255, 255),
	["Textbox Highlight Color"] = Color3.fromRGB(0, 140, 255),
	["Box Highlight Color"] = Color3.fromRGB(0, 140, 255),
	["Slider Line Color"] = Color3.fromRGB(0, 140, 255),
	["Slider Highlight Color"] = Color3.fromRGB(0, 100, 210),
	["Tween Animation 1 Speed"] = DisableAnimation and 0 or 0.25,
	["Tween Animation 2 Speed"] = DisableAnimation and 0 or 0.5,
	["Tween Animation 3 Speed"] = DisableAnimation and 0 or 0.1,
	["Text Stroke Transparency"] = 0.5
}

getgenv().UIColor = T1UIColor
getgenv().AllControls = {}
getgenv().UIToggled = true


local currcolor = {}
local Library = {};
local Library_Function = {}

-- pulls the logo straight from a raw url so roblox never re-compresses it
function Library_Function.LoadLogo()
	local Url = getgenv().UIColor["Logo Url"]
	if not Url or Url == "" then return false end
	if type(writefile) ~= "function" or type(getcustomasset) ~= "function" then return false end
	local File = "GravityHub/Logo_" .. tostring(#Url) .. ".png"
	return (pcall(function()
		if not isfolder("GravityHub") then
			makefolder("GravityHub")
		end
		if not isfile(File) or #readfile(File) < 8 then
			local Body = game:HttpGet(Url)
			assert(string.sub(Body, 2, 4) == "PNG", "logo url did not return a png")
			writefile(File, Body)
		end
		local Data = readfile(File)
		local Width = string.byte(Data, 17) * 16777216 + string.byte(Data, 18) * 65536 + string.byte(Data, 19) * 256 + string.byte(Data, 20)
		local Height = string.byte(Data, 21) * 16777216 + string.byte(Data, 22) * 65536 + string.byte(Data, 23) * 256 + string.byte(Data, 24)
		if Width > 0 and Height > 0 then
			getgenv().UIColor["Logo Aspect"] = Width / Height
		end
		getgenv().UIColor["Logo Image"] = getcustomasset(File)
	end))
end

local TweenService = game:GetService('TweenService')
local uis = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local function makeDraggable(topBarObject, object)
	local dragging = nil
	local dragInput = nil
	local dragStart = nil
	local startPosition = nil
	topBarObject.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = object.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	topBarObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	uis.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			if not djtmemay and cac then
				TweenService:Create(object, TweenInfo.new(DisableAnimation and 0 or 0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
					Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
				}):Play()
			elseif not djtmemay and not cac then
				object.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
			end
		end
	end)
end

Library_Function.Gui = Instance.new('ScreenGui')
Library_Function.Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Library_Function.Gui.Name = 'Delex GUI'
Library_Function.Gui.Enabled = true

getgenv().ReadyForGuiLoaded = false
local Spawn = spawn or (task and task.spawn) or function(Fn)
	coroutine.wrap(Fn)()
end
local TaskWait = (task and task.wait) or wait or function(Seconds)
	-- fallback สุดท้าย: ไม่มี task.wait และไม่มี wait
	local Deadline = os.clock() + (Seconds or 0)
	repeat
		RunService.Heartbeat:Wait()
	until os.clock() >= Deadline
end
local function Now()
	if type(tick) == "function" then
		return tick()
	end
	return os.clock()
end
Spawn(function()
	repeat
		TaskWait()
	until getgenv().ReadyForGuiLoaded
	if getgenv().UIToggled then
		Library_Function.Gui.Enabled = true
	end
end)


Library_Function.NotiGui = Instance.new('ScreenGui')
Library_Function.NotiGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Library_Function.NotiGui.Name = 'Delex Notification'


Library.ToggleUI = function()
	local Now = os.clock()
	if Now - (getgenv().LastUIToggle or 0) < 0.15 then return end
	getgenv().LastUIToggle = Now

	local Gui = GuiParent and GuiParent:FindFirstChild("Delex GUI")
	local Enabled = not (Gui and Gui.Enabled)
	getgenv().UIToggled = Enabled
	if Gui then
		Gui.Enabled = Enabled
	end
	-- ปุ่มลอยบอกสถานะตาม (เขียว = เปิด)
	local Refresh = getgenv().Delex and getgenv().Delex.RefreshToggleButton
	if type(Refresh) == "function" then
		pcall(Refresh)
	end
end
getgenv().ToggleUI = Library.ToggleUI


-- ============================================================
-- keybind สำหรับพับ/กาง UI (เปลี่ยนได้ผ่าน Library:SetToggleKey)
-- ============================================================
getgenv().DelexToggleKey = getgenv().DelexToggleKey or "RightControl"

local function KeyName(Key)
	local Text = tostring(Key or "")
	Text = Text:gsub("Enum%.KeyCode%.", "")
	Text = Text:gsub("Enum%.UserInputType%.", "")
	return Text
end

function Library:SetToggleKey(Key)
	getgenv().DelexToggleKey = KeyName(Key)
	return getgenv().DelexToggleKey
end

function Library:GetToggleKey()
	return getgenv().DelexToggleKey
end

-- one handler only even after re-running the script
if getgenv().GravityHubKeybind then
	pcall(function()
		getgenv().GravityHubKeybind:Disconnect()
	end)
end
getgenv().GravityHubKeybind = uis.InputBegan:Connect(function(Input)
	local Wanted = KeyName(getgenv().DelexToggleKey)
	if Wanted == "" then
		return
	end
	local Pressed
	if Input.UserInputType == Enum.UserInputType.Keyboard then
		Pressed = Input.KeyCode.Name
	elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
		Pressed = "MouseLeft"
	elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
		Pressed = "MouseRight"
	end
	if Pressed ~= Wanted then
		return
	end
	if uis:GetFocusedTextBox() then
		return
	end
	Library.ToggleUI()
end)

-- ============================================================
-- theme registry: ทุกคอนโทรลลงทะเบียน element ไว้ เพื่อเปลี่ยนสีสดได้ทันที
-- ============================================================
local Themes = nil
local ThemeNames = {}
local CurrentTheme = getgenv().DelexThemeName or "Blue"
local ThemeWatchers = {}

-- forward declaration: ApplyTheme เรียกใช้ก่อนที่ตัวจริงจะถูกประกาศ
local RegisterThemeTree

local function RegisterTheme(Element, Property, Key)
	table.insert(ThemeWatchers, {
		Element = Element,
		Property = Property,
		Key = Key
	})
end

local function ApplyWatcher(Entry)
	local Value = getgenv().UIColor[Entry.Key]
	if Value == nil then
		return
	end
	pcall(function()
		Entry.Element[Entry.Property] = Value
	end)
end

function Library:ApplyTheme(ColorTable)
	if type(ColorTable) ~= "table" then
		return false
	end
	for Key, Value in pairs(ColorTable) do
		getgenv().UIColor[Key] = Value
	end

	-- เดินสำรวจ GUI จริงทั้งหมด เพราะคอนโทรลถูกเพิ่มเข้า section ทีหลัง
	for _, Gui in ipairs({ Library_Function.Gui, Library_Function.NotiGui }) do
		if Gui then
			RegisterThemeTree(Gui)
		end
	end

	for _, Entry in ipairs(ThemeWatchers) do
		ApplyWatcher(Entry)
	end

	-- element ที่ไม่ใช่ descendant ของ Gui (เช่นปุ่มลอย)
	local Stroke = Library_Function.ToggleStroke
	if Stroke and getgenv().UIColor["Border Color"] then
		pcall(function()
			Stroke.Color = getgenv().UIColor["Border Color"]
		end)
	end

	for _, Callback in ipairs(ThemeBuckets or {}) do
		pcall(Callback, getgenv().UIColor)
	end
	return true
end

function Library:GetTheme()
	return getgenv().UIColor
end

function Library:GetThemeName()
	return getgenv().DelexThemeName or "Custom"
end

function Library:GetThemeNames()
	local List = {}
	for Name in pairs(Themes or {}) do
		table.insert(List, Name)
	end
	table.sort(List)
	return List
end

function Library:RegisterTheme(Name, ColorTable)
	Themes = Themes or {}
	Themes[Name] = ColorTable
	table.insert(ThemeNames, Name)
	return true
end

function Library:SetTheme(Name)
	Themes = Themes or {}
	local ColorTable = Themes[Name]
	if type(ColorTable) ~= "table" then
		return false
	end
	getgenv().DelexThemeName = Name
	return Library:ApplyTheme(ColorTable)
end

-- callback สำหรับ element ที่สร้างนอก registry (เรียกซ้ำเมื่อธีมเปลี่ยน)
ThemeBuckets = ThemeBuckets or {}
function Library:OnThemeChanged(Callback)
	if type(Callback) == "function" then
		table.insert(ThemeBuckets, Callback)
	end
end

-- ลงทะเบียน element ตามชื่อที่ไลบรารีนี้ใช้อยู่แล้ว
-- (เรียกหลังสร้างคอนโทรลเสร็จ เพื่อให้เปลี่ยนสีสดได้โดยไม่ต้องสร้าง UI ใหม่)
RegisterThemeTree = function(Root)
	if not Root then
		return
	end
	local function Walk(Target)
		local Name = Target.Name
		if Name == "TextColor" or Name == "GUITextColor" or Name == "SampleItemTitle" then
			RegisterTheme(Target, "TextColor3", "Text Color")
		elseif Name == "Sectiontitle" then
			RegisterTheme(Target, "TextColor3", "Section Text Color")
		elseif Name == "ToggleDesc" then
			RegisterTheme(Target, "TextColor3", "Toggle Desc Color")
		elseif Name == "PageInLine" then
			RegisterTheme(Target, "BackgroundColor3", "Page Selected Color")
		elseif Name == "Linesec" then
			RegisterTheme(Target, "BackgroundColor3", "Section Underline Color")
		elseif Name == "check" then
			RegisterTheme(Target, "BackgroundColor3", "Toggle Checked Color")
		elseif Name == "checkbox" then
			RegisterTheme(Target, "ImageColor3", "Toggle Border Color")
		elseif Name == "Bar" then
			RegisterTheme(Target, "BackgroundColor3", "Slider Line Color")
		elseif Name == "ImgDrop" then
			RegisterTheme(Target, "ImageColor3", "Dropdown Icon Color")
		elseif Name == "TextNSBoxLineeeee" then
			RegisterTheme(Target, "BackgroundColor3", "Box Highlight Color")
		elseif Name == "Background1" then
			RegisterTheme(Target, "BackgroundColor3", "Background 1 Color")
		elseif Name == "Background2" then
			RegisterTheme(Target, "BackgroundColor3", "Background 2 Color")
		elseif Name == "LabelBG" then
			RegisterTheme(Target, "BackgroundColor3", "Label Color")
		elseif Name == "TopStroke" then
			RegisterTheme(Target, "BackgroundColor3", "Border Color")
		end
		for _, Child in ipairs(Target:GetChildren()) do
			Walk(Child)
		end
	end
	Walk(Root)
end
Library_Function.RegisterThemeTree = RegisterThemeTree

-- ธีมสำเร็จรูป: เปลี่ยนเฉพาะสีเน้น (พื้นหลังคงไว้ให้อ่านง่าย)
local function MakeTheme(Accent, AccentDark, AccentDeep)
	return {
		["Border Color"] = Accent,
		["Search Icon Highlight Color"] = Accent,
		["Title Text Color"] = Accent,
		["Page Selected Color"] = Accent,
		["Section Underline Color"] = Accent,
		["Toggle Border Color"] = Accent,
		["Button Color"] = Accent,
		["Dropdown Selected Color"] = Accent,
		["Textbox Highlight Color"] = Accent,
		["Box Highlight Color"] = Accent,
		["Slider Line Color"] = Accent,
		["Slider Highlight Color"] = AccentDark,
		["Dropdown Selected Check Color"] = AccentDeep or AccentDark,
	}
end

Library:RegisterTheme("Blue", MakeTheme(
	Color3.fromRGB(0, 140, 255),
	Color3.fromRGB(0, 100, 210),
	Color3.fromRGB(0, 75, 160)
))
Library:RegisterTheme("Red", MakeTheme(
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(200, 0, 0),
	Color3.fromRGB(170, 0, 0)
))
Library:RegisterTheme("Green", MakeTheme(
	Color3.fromRGB(0, 220, 130),
	Color3.fromRGB(0, 170, 100),
	Color3.fromRGB(0, 130, 80)
))
Library:RegisterTheme("Purple", MakeTheme(
	Color3.fromRGB(170, 90, 255),
	Color3.fromRGB(130, 60, 210),
	Color3.fromRGB(100, 40, 170)
))
Library:RegisterTheme("Orange", MakeTheme(
	Color3.fromRGB(255, 150, 40),
	Color3.fromRGB(210, 110, 20),
	Color3.fromRGB(170, 85, 15)
))
Library:RegisterTheme("White", MakeTheme(
	Color3.fromRGB(235, 235, 230),
	Color3.fromRGB(200, 200, 195),
	Color3.fromRGB(170, 170, 165)
))

Library.DestroyUI = function()
	if GuiParent then
		for i, v in ipairs(GuiParent:GetChildren()) do
			if string.find(v.Name,  "Delex") then
				v:Destroy()
			end
		end
	end
end



local NotiContainer = Instance.new("Frame")
local NotiList = Instance.new("UIListLayout")

NotiContainer.Name = "NotiContainer"
NotiContainer.Parent = Library_Function.NotiGui
NotiContainer.AnchorPoint = Vector2.new(1, 1)
NotiContainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
NotiContainer.BackgroundTransparency = 1.000
NotiContainer.Position = UDim2.new(1, -5, 1, -5)
NotiContainer.Size = UDim2.new(0, 350, 1, -10)

NotiList.Name = "NotiList"
NotiList.Parent = NotiContainer
NotiList.SortOrder = Enum.SortOrder.LayoutOrder
NotiList.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotiList.Padding = UDim.new(0, 5)


getgenv().DelexGuiFolder = GuiParent
Library_Function.Gui.Parent = GuiParent
Library_Function.NotiGui.Parent = GuiParent

function Library_Function.Getcolor(color)
	return {
		math.floor(color.r * 255),
		math.floor(color.g * 255),
		math.floor(color.b * 255)
	}
end

local libCreateNoti = function(Setting)
	getgenv().TitleNameNoti = Setting.Title or ""; 
	local Description = Setting.Description or Setting.Desc or Setting.Content or ""; 
	local Duration = Setting.Duration or Setting.Timeshow or Setting.Delay or 10;

	local NotiFrame = Instance.new("Frame")
	local Noticontainer = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local Topnoti = Instance.new("Frame")
	local Ruafimg = Instance.new("ImageLabel")
	local RuafimgCorner = Instance.new("UICorner")
	local TextLabelNoti = Instance.new("TextLabel")
	local CloseContainer = Instance.new("Frame")
	local CloseImage = Instance.new("ImageLabel")
	local TextButton = Instance.new("TextButton")
	local TextLabelNoti2 = Instance.new("TextLabel")

	NotiFrame.Name = "NotiFrame"
	NotiFrame.Parent = NotiContainer
	NotiFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	NotiFrame.BackgroundTransparency = 1.000
	NotiFrame.ClipsDescendants = true
	NotiFrame.Position = UDim2.new(0, 0, 0, 0)
	NotiFrame.Size = UDim2.new(1, 0, 0, 0)
	NotiFrame.AutomaticSize = Enum.AutomaticSize.Y

	Noticontainer.Name = "Noticontainer"
	Noticontainer.Parent = NotiFrame
	Noticontainer.Position = UDim2.new(1, 0, 0, 0)
	Noticontainer.Size = UDim2.new(1, 0, 1, 6)
	Noticontainer.AutomaticSize = Enum.AutomaticSize.Y
	Noticontainer.BackgroundColor3 = getgenv().UIColor["Background 3 Color"]
	UICorner.CornerRadius = UDim.new(0, 4)
	UICorner.Parent = Noticontainer

	Topnoti.Name = "Topnoti"
	Topnoti.Parent = Noticontainer
	Topnoti.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	Topnoti.BackgroundTransparency = 1.000
	Topnoti.Position = UDim2.new(0, 0, 0, 5)
	Topnoti.Size = UDim2.new(1, 0, 0, 25)

	Ruafimg.Name = "Ruafimg"
	Ruafimg.Parent = Topnoti
	Ruafimg.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	Ruafimg.BackgroundTransparency = 1.000
	Ruafimg.Position = UDim2.new(0, 5, 0, 0)
	Ruafimg.Size = UDim2.new(0, 25, 0, 25)
	Ruafimg.Image = getgenv().UIColor["Logo Image"]
	Ruafimg.ScaleType = Enum.ScaleType.Fit

	RuafimgCorner.CornerRadius = UDim.new(1, 0)
	RuafimgCorner.Name = "RuafimgCorner"
	RuafimgCorner.Parent = Ruafimg
	
	local colorR = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[1])
	local colorG = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[2])
	local colorB = tostring(Library_Function.Getcolor(getgenv().UIColor['Title Text Color'])[3])
	local color = colorR .. ',' .. colorG .. ',' .. colorB
    TextLabelNoti.Text = "<font color=\"rgb(" .. tostring(color or "255,0,0") .. ")\">" .. tostring("Delex") .. "</font> " .. tostring(getgenv().TitleNameNoti or "")
    
	TextLabelNoti.Name = "TextLabelNoti"
	TextLabelNoti.Parent = Topnoti
	TextLabelNoti.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	TextLabelNoti.BackgroundTransparency = 1.000
	TextLabelNoti.Position = UDim2.new(0, getgenv().T1 and 40 or 35, 0, 0)
	TextLabelNoti.Size = UDim2.new(1, getgenv().T1 and -40 or -35, 1, 0)
	TextLabelNoti.Font = Enum.Font.GothamBold
	TextLabelNoti.TextSize = 14.000
	TextLabelNoti.TextWrapped = true
	TextLabelNoti.TextXAlignment = Enum.TextXAlignment.Left
	TextLabelNoti.RichText = true
	TextLabelNoti.TextColor3 = getgenv().UIColor["GUI Text Color"]

	CloseContainer.Name = "CloseContainer"
	CloseContainer.Parent = Topnoti
	CloseContainer.AnchorPoint = Vector2.new(1, 0.5)
	CloseContainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	CloseContainer.BackgroundTransparency = 1.000
	CloseContainer.Position = UDim2.new(1, -4, 0.5, 0)
	CloseContainer.Size = UDim2.new(0, 22, 0, 22)

	CloseImage.Name = "CloseImage"
	CloseImage.Parent = CloseContainer
	CloseImage.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	CloseImage.BackgroundTransparency = 1.000
	CloseImage.Size = UDim2.new(1, 0, 1, 0)
	CloseImage.Image = "rbxassetid://3926305904"
	CloseImage.ImageRectOffset = Vector2.new(284, 4)
	CloseImage.ImageRectSize = Vector2.new(24, 24)
	CloseImage.ImageColor3 = getgenv().UIColor["Search Icon Color"]

	TextButton.Parent = CloseContainer
	TextButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	TextButton.BackgroundTransparency = 1.000
	TextButton.Size = UDim2.new(1, 0, 1, 0)
	TextButton.Font = Enum.Font.SourceSans
	TextButton.Text = ""
	TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	TextButton.TextSize = 14.000

	if Description then
		TextLabelNoti2.Name = 'TextColor'
		TextLabelNoti2.Parent = Noticontainer
		TextLabelNoti2.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		TextLabelNoti2.BackgroundTransparency = 1.000
		TextLabelNoti2.Position = UDim2.new(0, 10, 0, 35)
		TextLabelNoti2.Size = UDim2.new(1, -15, 0, 0)
		TextLabelNoti2.Font = Enum.Font.GothamBold
		TextLabelNoti2.Text = Description
		TextLabelNoti2.TextSize = 14.000
		TextLabelNoti2.TextXAlignment = Enum.TextXAlignment.Left
		TextLabelNoti2.RichText = true
		TextLabelNoti2.TextColor3 = getgenv().UIColor["Text Color"]
		TextLabelNoti2.AutomaticSize = Enum.AutomaticSize.Y
		TextLabelNoti2.TextWrapped = true
	end

	local function remove()
		TweenService:Create(Noticontainer, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
			Position = UDim2.new(1, 0, 0, 0)
		}):Play()
		TaskWait(.25)
		NotiFrame:Destroy()
	end

	TweenService:Create(Noticontainer, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
		Position = UDim2.new(0, 0, 0, 0)
	}):Play()

	TextButton.MouseEnter:Connect(function()
		TweenService:Create(CloseImage, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
			ImageColor3 = getgenv().UIColor["Search Icon Highlight Color"]
		}):Play()
	end)

	TextButton.MouseLeave:Connect(function()
		TweenService:Create(CloseImage, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
			ImageColor3 = getgenv().UIColor["Search Icon Color"]
		}):Play()
	end)

	TextButton.MouseButton1Click:Connect(function()
		TaskWait(.25)
		remove()
	end)

	Spawn(function()
		TaskWait(Duration)
		remove()
	end)

end

function Library:Notify(Setting, bypass)
	if not getgenv().Config or bypass then
		local s, e = pcall(function()
			libCreateNoti(Setting)
		end)
		if e then
			print(e)
		end
	end
end

function Library:CreateWindow(Setting)
    local TitleNameMain = Setting.Title or "Delex"
    getgenv().MainDesc = Setting.Desc or Setting.Subtitle or ""
    
    if Setting.Image then
        getgenv().UIColor["Logo Image"] = Setting.Image
    end

    if Setting.LogoUrl then
        getgenv().UIColor["Logo Url"] = Setting.LogoUrl
    end
    Library_Function.LoadLogo()

-- ============================================================
-- floating toggle: ปุ่มลอยสำหรับพับ/กาง UI (รองรับมือถือ)
-- แตะ = พับ/กาง, ลาก = ย้ายตำแหน่ง, ขนาดใหญ่พอสำหรับนิ้ว
-- ============================================================
local function IsMobile()
	local UIService = game:GetService("UserInputService")
	return UIService.TouchEnabled and not UIService.KeyboardEnabled
end

local function MakeToggleButton()
	if getgenv().DelexToggleButton and getgenv().DelexToggleButton.Parent then
		return
	end

	local ToggleGui = Instance.new("ScreenGui")
	ToggleGui.Name = "Delex Toggle"
	ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ToggleGui.ResetOnSpawn = false
	ToggleGui.DisplayOrder = 999

	local ButtonSize = IsMobile() and 60 or 46

	local SavedPos = getgenv().DelexTogglePos
	local ToggleButton = Instance.new("TextButton")
	ToggleButton.Name = "ToggleButton"
	ToggleButton.Parent = ToggleGui
	ToggleButton.AnchorPoint = SavedPos and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5)
	ToggleButton.Position = SavedPos or UDim2.new(0, 14, 0.62, 0)
	ToggleButton.Size = UDim2.new(0, ButtonSize, 0, ButtonSize)
	ToggleButton.BackgroundColor3 = Color3.fromRGB(10, 16, 26)
	ToggleButton.BackgroundTransparency = 0.1
	ToggleButton.BorderSizePixel = 2
	ToggleButton.BorderColor3 = getgenv().UIColor["Border Color"]
	ToggleButton.AutoButtonColor = false
	ToggleButton.Active = true
	ToggleButton.Text = ""

	local ToggleCorner = Instance.new("UICorner", ToggleButton)
	ToggleCorner.CornerRadius = UDim.new(0, 14)

	local ToggleStroke = Instance.new("UIStroke", ToggleButton)
	ToggleStroke.Name = "DelexStroke"
	ToggleStroke.Color = getgenv().UIColor["Border Color"]
	ToggleStroke.Thickness = 1.5
	ToggleStroke.Transparency = 0.2

	local ToggleLogo = Instance.new("ImageLabel", ToggleButton)
	ToggleLogo.Name = "Logo"
	ToggleLogo.AnchorPoint = Vector2.new(0.5, 0.5)
	ToggleLogo.Position = UDim2.new(0.5, 0, 0.5, 0)
	ToggleLogo.Size = UDim2.new(1, -8, 1, -8)
	ToggleLogo.BackgroundTransparency = 1
	ToggleLogo.Image = getgenv().UIColor["Logo Image"]
	ToggleLogo.ScaleType = Enum.ScaleType.Fit
	local LogoAspect = getgenv().UIColor["Logo Aspect"]
	if LogoAspect and LogoAspect > 1.28 then
		ToggleLogo.Size = UDim2.new(1, -2, 1, -2)
		ToggleLogo.ScaleType = Enum.ScaleType.Crop
	end

	-- ถ้ารูปโลโก้โหลดไม่ขึ้น ให้เห็นตัวอักษรแทน (กันปุ่มกลายเป็นวงกลมเปล่า)
	ToggleLogo.Visible = ToggleLogo.Image ~= nil and tostring(ToggleLogo.Image) ~= ""
	local FallbackText = Instance.new("TextLabel", ToggleButton)
	FallbackText.Name = "FallbackText"
	FallbackText.AnchorPoint = Vector2.new(0.5, 0.5)
	FallbackText.Position = UDim2.new(0.5, 0, 0.5, 0)
	FallbackText.Size = UDim2.new(1, 0, 1, 0)
	FallbackText.BackgroundTransparency = 1
	FallbackText.Font = Enum.Font.GothamBlack
	FallbackText.Text = "D"
	FallbackText.TextSize = math.floor(ButtonSize * 0.45)
	FallbackText.TextColor3 = getgenv().UIColor["Border Color"]
	FallbackText.Visible = not ToggleLogo.Visible
	FallbackText.ZIndex = 2

	-- วงแหวนบอกสถานะ: เขียว = UI เปิดอยู่, จาง = UI ถูกพับไว้
	local StateDot = Instance.new("Frame", ToggleButton)
	StateDot.Name = "StateDot"
	StateDot.AnchorPoint = Vector2.new(1, 1)
	StateDot.Position = UDim2.new(1, -3, 1, -3)
	StateDot.Size = UDim2.new(0, 12, 0, 12)
	StateDot.BackgroundColor3 = Color3.fromRGB(0, 215, 130)
	StateDot.BorderSizePixel = 0
	StateDot.ZIndex = 3

	local DotCorner = Instance.new("UICorner", StateDot)
	DotCorner.CornerRadius = UDim.new(1, 0)

	local function RefreshStateDot()
		if getgenv().UIToggled == false then
			StateDot.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
			StateDot.BackgroundTransparency = 0.35
		else
			StateDot.BackgroundColor3 = Color3.fromRGB(0, 215, 130)
			StateDot.BackgroundTransparency = 0
		end
	end
	RefreshStateDot()

	-- กด = พับ/กาง UI, ลาก = ย้ายตำแหน่ง (จำตำแหน่งไว้ใน session)
	local DragStart = nil
	local DragOrigin = nil
	local Moved = false
	local TouchThreshold = IsMobile() and 12 or 4

	ToggleButton.InputBegan:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseButton1
			and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		DragStart = Input.Position
		DragOrigin = ToggleButton.Position
		Moved = false
	end)

	ToggleButton.InputChanged:Connect(function(Input)
		if not DragStart then
			return
		end
		if Input.UserInputType ~= Enum.UserInputType.MouseMovement
			and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local Delta = Input.Position - DragStart
		if math.abs(Delta.X) + math.abs(Delta.Y) > TouchThreshold then
			Moved = true
		end
		if Moved then
			ToggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
			ToggleButton.Position = UDim2.new(
				DragOrigin.X.Scale, DragOrigin.X.Offset + Delta.X,
				DragOrigin.Y.Scale, DragOrigin.Y.Offset + Delta.Y
			)
		end
	end)

	local function ClampToScreen()
		-- กันปุ่มหลุดขอบจอหลังหมุนจอ/เปลี่ยนความละเอียด
		local Camera = workspace.CurrentCamera
		if not Camera then
			return
		end
		local Viewport = Camera.ViewportSize
		if not Viewport or Viewport.X <= 0 or Viewport.Y <= 0 then
			return
		end
		local Absolute = ToggleButton.AbsolutePosition
		local Size = ToggleButton.AbsoluteSize
		local Half = Size.X / 2
		local X = math.clamp(Absolute.X + Half, Half + 4, Viewport.X - Half - 4)
		local Y = math.clamp(Absolute.Y + Size.Y / 2, Size.Y / 2 + 4, Viewport.Y - Size.Y / 2 - 4)
		ToggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
		ToggleButton.Position = UDim2.fromOffset(X, Y)
	end

	local function EndDrag()
		if not DragStart then
			return
		end
		DragStart = nil
		if Moved then
			ClampToScreen()
			getgenv().DelexTogglePos = ToggleButton.Position
		else
			Library.ToggleUI()
			RefreshStateDot()
		end
		Moved = false
	end

	-- ปิด/เปิดด้วยคีย์ลัดหรือปุ่มอื่น ก็ให้จุดสถานะอัปเดตตาม
	if ToggleGui.AncestryChanged then
		ToggleGui.AncestryChanged:Connect(function()
			RefreshStateDot()
		end)
	end

	ToggleButton.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then
			EndDrag()
		end
	end)

	-- หมุนจอ/ย่อหน้าต่าง: ดึงปุ่มกลับเข้ากรอบ
	local Camera = workspace.CurrentCamera
	if Camera then
		Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			ClampToScreen()
		end)
	end

	ToggleGui.Parent = GuiParent
	getgenv().DelexToggleButton = ToggleButton
	Library_Function.ToggleButton = ToggleButton
	Library_Function.ToggleStroke = ToggleStroke

	-- ให้ API เปลี่ยนสี/คีย์ลัด หาปุ่มนี้เจอ
	getgenv().Delex = getgenv().Delex or {}
	getgenv().Delex.ToggleButton = ToggleButton
	getgenv().Delex.ToggleStroke = ToggleStroke
	getgenv().Delex.GuiParent = GuiParent
	getgenv().Delex.RefreshToggleButton = RefreshStateDot
end

	-- สร้างปุ่มพับ UI ทันที (ถ้ามีอยู่แล้วจะไม่สร้างซ้ำ)
	MakeToggleButton()

	local djtmemay = false
	cac = false

	local Main = Instance.new("Frame")
	local maingui = Instance.new("ImageLabel")
	local MainCorner = Instance.new("UICorner")
	local TopMain = Instance.new("Frame")
	local Ruafimg = Instance.new("ImageLabel")
	local TextLabelMain = Instance.new("TextLabel")
	local PageControl = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local ControlList = Instance.new("ScrollingFrame")
	local UIListLayout = Instance.new("UIListLayout")
	local MainPage = Instance.new("Frame")
	local UIPage = Instance.new("UIPageLayout")
	local Concacontainer = Instance.new("Frame")
	local Concacmain = Instance.new("Frame")
	local MainContainer

	Main.Name = "Main"
	Main.Parent = Library_Function.Gui
	Main.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
	Main.BackgroundTransparency = 1.000
	Main.Position = UDim2.new(0.5, 0, 0.5, 0)
	Main.AnchorPoint = Vector2.new(0.5, 0.5)
	Main.Size = UDim2.new(0, 700, 0, 438)

	makeDraggable(Main, Main)

	maingui.Name = "maingui"
	maingui.Parent = Main
	maingui.AnchorPoint = Vector2.new(0.5, 0.5)
	maingui.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	maingui.BackgroundTransparency = 1.000
	maingui.Position = UDim2.new(0.5, 0, 0.5, 0)
	maingui.Selectable = true
	maingui.Size = UDim2.new(1, 30, 1, 30)
	maingui.Image = "rbxassetid://8068653048"
	maingui.ScaleType = Enum.ScaleType.Slice
	maingui.SliceCenter = Rect.new(15, 15, 175, 175)
	maingui.SliceScale = 1.300
	maingui.ImageColor3 = getgenv().UIColor["Border Color"]
	maingui.ImageTransparency = 1

	maingui.ImageColor3 = getgenv().UIColor['Title Text Color']

	MainContainer = Instance.new("ImageLabel")
	MainContainer.Name = "MainContainer"
	MainContainer.Parent = Main
	MainContainer.BackgroundColor3 = Color3.fromRGB(14, 20, 32)
	MainContainer.Size = UDim2.new(1, 0, 1, 0)

	local uistr = Instance.new("UIStroke", MainContainer);
	uistr.Thickness = 1;
	uistr.Color = Color3.fromRGB(0, 45, 95);

	local uigradient = Instance.new("UIGradient", MainContainer);
	uigradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
	}
	uigradient.Rotation = 90
	uigradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.04),
		NumberSequenceKeypoint.new(1, 0.10)
	}

	getgenv().ReadyForGuiLoaded = true
	
	MainCorner.CornerRadius = UDim.new(0, 5)
	MainCorner.Name = "MainCorner"
	MainCorner.Parent = MainContainer

	Concacontainer.Name = "Concacontainer"
	Concacontainer.Parent = MainContainer
	Concacontainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Concacontainer.BackgroundTransparency = 1.000
	Concacontainer.ClipsDescendants = true
	Concacontainer.Position = UDim2.new(0, 0, 0, 53)
	Concacontainer.Size = UDim2.new(1, 0, 1, -53)
	
	Concacmain.Name = "Concacmain"
	Concacmain.Parent = Concacontainer
	Concacmain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Concacmain.BackgroundTransparency = 1.000
	Concacmain.Selectable = true
	Concacmain.Size = UDim2.new(1, 0, 1, 0)
	
	TopMain.Name = "TopMain"
	TopMain.Parent = MainContainer
	TopMain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TopMain.BackgroundTransparency = 1.000
	TopMain.Size = UDim2.new(1, 0, 0, 48)
	
	local TopStroke = Instance.new("Frame", TopMain)
	TopStroke.Name = "TopStroke"
	TopStroke.BackgroundColor3 = Color3.fromRGB(0, 45, 95)
	TopStroke.BackgroundTransparency = 0.6
	TopStroke.BorderSizePixel = 0
	TopStroke.Position = UDim2.new(0, 0, 1, -1)
	TopStroke.Size = UDim2.new(1, 0, 0, 1)
	
	-- square cell; the artwork is oversized then clipped to its own bounds
	local LogoHolder = Instance.new("Frame", TopMain)
	LogoHolder.Name = "LogoHolder"
	LogoHolder.BackgroundTransparency = 1.000
	LogoHolder.ClipsDescendants = true
	LogoHolder.Position = UDim2.new(0, 7, 0, 3)
	LogoHolder.Size = UDim2.new(0, 42, 0, 42)

	Ruafimg.Name = "Ruafimg"
	Ruafimg.Parent = LogoHolder
	Ruafimg.AnchorPoint = Vector2.new(0.5, 0.5)
	Ruafimg.BackgroundTransparency = 1.000
	Ruafimg.Position = UDim2.new(0.5, 0, 0.5, 0)
	Ruafimg.Image = getgenv().UIColor["Logo Image"]
	if Ruafimg.Image == LOGO_NATIVE_ID then
		-- 4:3 canvas with transparent margin; oversized so the artwork fills the cell
		Ruafimg.Size = UDim2.new(0, 60, 0, 45)
	else
		local Aspect = getgenv().UIColor["Logo Aspect"]
		if Aspect and Aspect > 1.28 then
			-- wide canvas: the art sits inside transparent padding, so oversize and let the cell crop it
			Ruafimg.Size = UDim2.new(0, 45, 0, 45)
			Ruafimg.ScaleType = Enum.ScaleType.Crop
		else
			Ruafimg.Size = UDim2.new(0, 42, 0, 42)
			Ruafimg.ScaleType = Enum.ScaleType.Fit
		end
	end

	-- title + subtitle share the logo cell so both sit on one vertical center
	local TitleHolder = Instance.new("Frame", TopMain)
	TitleHolder.Name = "TitleHolder"
	TitleHolder.BackgroundTransparency = 1.000
	TitleHolder.Position = UDim2.new(0, 58, 0, 3)
	TitleHolder.Size = UDim2.new(1, -158, 0, 42)

	local TitleList = Instance.new("UIListLayout", TitleHolder)
	TitleList.FillDirection = Enum.FillDirection.Vertical
	TitleList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	TitleList.VerticalAlignment = Enum.VerticalAlignment.Center
	TitleList.SortOrder = Enum.SortOrder.LayoutOrder
	TitleList.Padding = UDim.new(0, 1)

	TextLabelMain.Name = "TextLabelMain"
	TextLabelMain.Parent = TitleHolder
	TextLabelMain.AutomaticSize = Enum.AutomaticSize.Y
	TextLabelMain.BackgroundTransparency = 1.000
	TextLabelMain.LayoutOrder = 1
	TextLabelMain.Size = UDim2.new(1, 0, 0, 0)
	TextLabelMain.Font = Enum.Font.GothamBold
	TextLabelMain.Text = tostring(TitleNameMain)
	TextLabelMain.TextSize = 19.000
	TextLabelMain.TextTruncate = Enum.TextTruncate.AtEnd
	TextLabelMain.TextXAlignment = Enum.TextXAlignment.Left
	TextLabelMain.TextColor3 = getgenv().UIColor["GUI Text Color"]

	local SubtitleLabel = Instance.new("TextLabel", TitleHolder)
	SubtitleLabel.Name = "SubtitleLabel"
	SubtitleLabel.AutomaticSize = Enum.AutomaticSize.Y
	SubtitleLabel.BackgroundTransparency = 1.000
	SubtitleLabel.LayoutOrder = 2
	SubtitleLabel.Size = UDim2.new(1, 0, 0, 0)
	SubtitleLabel.Font = Enum.Font.GothamBold
	SubtitleLabel.TextSize = 14.000
	SubtitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	SubtitleLabel.TextColor3 = getgenv().UIColor["Text Color"]
	SubtitleLabel.Text = (getgenv().MainDesc ~= "" and tostring(getgenv().MainDesc)) or "No Description"

	-- ปุ่มปิด UI บนหัวหน้าต่าง: แตะง่ายบนมือถือ (นิ้วโป้งขวา)
	local CloseButton = Instance.new("TextButton", TopMain)
	CloseButton.Name = "CloseButton"
	CloseButton.AnchorPoint = Vector2.new(1, 0.5)
	CloseButton.AutoButtonColor = false
	CloseButton.BackgroundColor3 = Color3.fromRGB(160, 40, 55)
	CloseButton.BackgroundTransparency = 0.15
	CloseButton.Position = UDim2.new(1, -8, 0, 24)
	CloseButton.Size = UDim2.new(0, 40, 0, 40)
	CloseButton.Text = "X"
	CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloseButton.TextSize = 20
	CloseButton.Font = Enum.Font.GothamBold

	local CloseCorner = Instance.new("UICorner", CloseButton)
	CloseCorner.CornerRadius = UDim.new(0, 10)

	local CloseStroke = Instance.new("UIStroke", CloseButton)
	CloseStroke.Name = "DelexStroke"
	CloseStroke.Color = getgenv().UIColor["Border Color"]
	CloseStroke.Thickness = 1.5
	CloseStroke.Transparency = 0.25

	CloseButton.MouseButton1Click:Connect(function()
		Library.ToggleUI()
	end)

	-- player avatar in a circle, top right of the header
	local AvatarHolder = Instance.new("Frame", TopMain)
	AvatarHolder.Name = "AvatarHolder"
	AvatarHolder.AnchorPoint = Vector2.new(1, 0.5)
	AvatarHolder.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
	AvatarHolder.BackgroundTransparency = 0.2
	AvatarHolder.BorderSizePixel = 0
	AvatarHolder.ClipsDescendants = true
	AvatarHolder.Position = UDim2.new(1, -56, 0, 24)
	AvatarHolder.Size = UDim2.new(0, 36, 0, 36)

	local AvatarCorner = Instance.new("UICorner", AvatarHolder)
	AvatarCorner.CornerRadius = UDim.new(1, 0)

	local AvatarStroke = Instance.new("UIStroke", AvatarHolder)
	AvatarStroke.Color = getgenv().UIColor["Border Color"]
	AvatarStroke.Thickness = 2
	AvatarStroke.Transparency = 0.15

	local AvatarImage = Instance.new("ImageLabel", AvatarHolder)
	AvatarImage.Name = "AvatarImage"
	AvatarImage.BackgroundTransparency = 1
	AvatarImage.Size = UDim2.new(1, 0, 1, 0)
	AvatarImage.ScaleType = Enum.ScaleType.Crop
	AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(game.Players.LocalPlayer.UserId) .. "&w=150&h=150"

	PageControl.Name = "Background1"
	PageControl.Parent = Concacmain
	PageControl.Position = UDim2.new(0, 5, 0, 5)
	PageControl.Size = UDim2.new(0, 150, 1, -10)
	PageControl.BackgroundColor3 = Color3.fromRGB(30, 42, 62)
	PageControl.BackgroundTransparency = 0.3

	local pageControlStroke = Instance.new("UIStroke", PageControl)
	pageControlStroke.Color = Color3.fromRGB(0, 45, 95)
	pageControlStroke.Thickness = 1

	local pageControlGradient = Instance.new("UIGradient", PageControl)
	pageControlGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 42, 62)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(44, 58, 82))
	}
	pageControlGradient.Rotation = 90
	pageControlGradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 0.55)
	}

	UICorner.CornerRadius = UDim.new(0, 4)
	UICorner.Parent = PageControl

	ControlList.Name = "ControlList"
	ControlList.Parent = PageControl
	ControlList.Active = true
	ControlList.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	ControlList.BackgroundTransparency = 1.000
	ControlList.BorderColor3 = Color3.fromRGB(27, 42, 53)
	ControlList.BorderSizePixel = 0
	ControlList.Position = UDim2.new(0, 0, 0, 5)
	ControlList.Size = UDim2.new(1, -10, 1, -10)
	ControlList.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	ControlList.CanvasSize = UDim2.new(0, 0, 0, 0)
	ControlList.ScrollBarThickness = 5
	ControlList.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"

	UIListLayout.Parent = ControlList
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0, 5)


	MainPage.Name = "MainPage"
	MainPage.Parent = Concacmain
	MainPage.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
	MainPage.BackgroundTransparency = 1.000
	MainPage.ClipsDescendants = true
	MainPage.Position = UDim2.new(0, 165, 0, 5)
	MainPage.Size = UDim2.new(1, -170, 1, -10)

	UIPage.Name = "UIPage"
	UIPage.Parent = MainPage
	UIPage.FillDirection = Enum.FillDirection.Vertical
	UIPage.SortOrder = Enum.SortOrder.LayoutOrder
	UIPage.EasingDirection = Enum.EasingDirection.InOut
	UIPage.EasingStyle = Enum.EasingStyle.Quart
	UIPage.Padding = UDim.new(0, 10)
	UIPage.TweenTime = getgenv().UIColor["Tween Animation 1 Speed"]

	-- pages change only through the tab buttons (no wheel / gamepad / swipe paging)
	UIPage.ScrollWheelInputEnabled = false
	UIPage.GamepadInputEnabled = false
	UIPage.TouchInputEnabled = false

	UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ControlList.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 5)
	end)

	local Shadow = Instance.new("ImageLabel", Main)
	Shadow.Name = "Shadow"
	Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	Shadow.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
	Shadow.BackgroundTransparency = 1
	Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	Shadow.Size = UDim2.new(1, 40, 1, 40)
	Shadow.ZIndex = 0
	Shadow.Image = "rbxassetid://5028857084"
	Shadow.ImageTransparency = 0.35
	Shadow.ScaleType = Enum.ScaleType.Slice
	Shadow.SliceCenter = Rect.new(24, 24, 276, 276)


	local Main_Function = {}

	local LayoutOrderBut = -1
	local LayoutOrder = -1
	local PageCounter = 1

	-- จัดลำดับแท็บ: ใช้ Window.layoutOrder.Set("Muse", "Settings")
	-- แท็บที่ระบุจะถูกตรึงไว้ล่างสุดเสมอ (ไม่ว่าแท็บอื่นจะถูกเพิ่มกี่แท็บ)
	local LayoutPinBase = 1000
	local layoutOrder = {}

	function layoutOrder.Set(...)
		local Pinned = 0
		for _, Name in ipairs({ ... }) do
			local Target = ControlList:FindFirstChild(tostring(Name) .. "_Control")
			if Target then
				Pinned = Pinned + 1
				Target.LayoutOrder = LayoutPinBase + Pinned
			end
		end
		return Pinned
	end

	setmetatable(layoutOrder, {
		__call = function(_, ...)
			return layoutOrder.Set(...)
		end
	})

	Main_Function.layoutOrder = layoutOrder

	function Main_Function:AddTab(PageName)

		local Page_Name = tostring(PageName)

		LayoutOrder = LayoutOrder + 1
		LayoutOrderBut = LayoutOrderBut + 1

		--Control 
		local PageName = Instance.new("Frame")
		local Frame = Instance.new("Frame")
		local TabNameCorner = Instance.new("UICorner")
		local Line = Instance.new("Frame")
		local InLine = Instance.new("Frame")
		local LineCorner = Instance.new("UICorner")
		local TabTitleContainer = Instance.new("Frame")
		local TabTitle = Instance.new("TextLabel")
		local PageButton = Instance.new("TextButton")


		PageName.Name = Page_Name .. "_Control"
		PageName.Parent = ControlList
		PageName.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		PageName.BackgroundTransparency = 1.000
		PageName.Size = UDim2.new(1, -10, 0, 30)
		PageName.LayoutOrder = LayoutOrderBut

		Frame.Parent = PageName
		Frame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		Frame.BackgroundTransparency = 1.000
		Frame.Position = UDim2.new(0, 2, 0, 0)
		Frame.Size = UDim2.new(1, -5, 1, 0)

		TabNameCorner.CornerRadius = UDim.new(0, 4)
		TabNameCorner.Name = "TabNameCorner"
		TabNameCorner.Parent = Frame

		Line.Name = "Line"
		Line.Parent = Frame
		Line.AnchorPoint = Vector2.new(0, 0.5)
		Line.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		Line.BackgroundTransparency = 1.000
		Line.Position = UDim2.new(0, 0, 0.5, 0)
		Line.Size = UDim2.new(0, 10, 1, 0)

		InLine.Name = "PageInLine"
		InLine.Parent = Line
		InLine.AnchorPoint = Vector2.new(0.5, 0.5)
		InLine.BorderSizePixel = 0
		InLine.Position = UDim2.new(0.5, 0, 0.5, 0)
		InLine.Size = UDim2.new(1, -4, 1, -10)
		InLine.BackgroundColor3 = getgenv().UIColor["Page Selected Color"]
		InLine.BackgroundTransparency = 1.000

		LineCorner.Name = "LineCorner"
		LineCorner.Parent = InLine

		TabTitleContainer.Name = "TabTitleContainer"
		TabTitleContainer.Parent = Frame
		TabTitleContainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		TabTitleContainer.BackgroundTransparency = 1.000
		TabTitleContainer.Position = UDim2.new(0, 13, 0, 0)
		TabTitleContainer.Size = UDim2.new(1, -15, 1, 0)

		TabTitle.Name = "GUITextColor"
		TabTitle.Parent = TabTitleContainer
		TabTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		TabTitle.BackgroundTransparency = 1.000
		TabTitle.Size = UDim2.new(1, 0, 1, 0)
		TabTitle.Font = Enum.Font.GothamBold
		TabTitle.Text = Page_Name
		TabTitle.TextColor3 = Color3.fromRGB(230, 230, 230)
		TabTitle.TextSize = 16.000
		TabTitle.TextXAlignment = Enum.TextXAlignment.Left
		TabTitle.TextColor3 = getgenv().UIColor["GUI Text Color"]

		PageButton.Name = "PageButton"
		PageButton.Parent = PageName
		PageButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		PageButton.BackgroundTransparency = 1.000
		PageButton.Size = UDim2.new(1, 0, 1, 0)
		PageButton.Font = Enum.Font.SourceSans
		PageButton.Text = ""
		PageButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		PageButton.TextSize = 14.000

		-- Container

		local PageContainer = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local PageList = Instance.new("ScrollingFrame")
		local Pagelistlayout = Instance.new("UIListLayout")

		local CurrentPage = PageCounter
		PageCounter = PageCounter + 1
		PageContainer.Name = "Page" .. CurrentPage
		PageContainer.Parent = MainPage
		PageContainer.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
		PageContainer.Position = UDim2.new(0, 0, 0, 0)
		PageContainer.Size = UDim2.new(1, 0, 1, 0)
		PageContainer.LayoutOrder = LayoutOrder
		PageContainer.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]

		UICorner.CornerRadius = UDim.new(0, 4)
		UICorner.Parent = PageContainer

		PageList.Name = "PageList"
		PageList.Parent = PageContainer
		PageList.Active = true
		PageList.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
		PageList.BackgroundTransparency = 1.000
		PageList.BorderColor3 = Color3.fromRGB(27, 42, 53)
		PageList.BorderSizePixel = 0
		PageList.Position = UDim2.new(0, 5, 0, 5)
		PageList.Size = UDim2.new(1, -10, 1, -10)
		PageList.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		PageList.ScrollBarThickness = 5
		PageList.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		PageList.ScrollingEnabled = true
		PageList.VerticalScrollBarInset = Enum.ScrollBarInset.Always

		Pagelistlayout.Name = "Pagelistlayout"
		Pagelistlayout.Parent = PageList
		Pagelistlayout.SortOrder = Enum.SortOrder.LayoutOrder
		Pagelistlayout.Padding = UDim.new(0, 5)
		Pagelistlayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			PageList.CanvasSize = UDim2.new(0, 0, 0, Pagelistlayout.AbsoluteContentSize.Y)
		end)

		-- แท็บแรกคือหน้าที่เปิดอยู่แล้ว จึงขีดเส้นใต้ที่แท็บนี้ตรง ๆ
		if LayoutOrderBut == 0 then
			InLine.BackgroundTransparency = 0
		end

		-- ลงทะเบียนสีของแท็บนี้ เพื่อให้เปลี่ยนธีมแล้วอัปเดตทันที
		if Library_Function.RegisterThemeTree then
			Library_Function.RegisterThemeTree(Frame)
		end

		PageButton.MouseButton1Click:Connect(function()
			if tostring(UIPage.CurrentPage) == PageContainer.Name then 
				return
			end

			for i, v in pairs(MainPage:GetChildren()) do
				if not (v:IsA('UIPageLayout')) and not (v:IsA('UICorner')) then
					v.Visible = false
				end
			end

			PageContainer.Visible = true 
			UIPage:JumpTo(PageContainer)

			for i, v in next, ControlList:GetChildren() do
				if not (v:IsA('UIListLayout')) then
					if v.Name == Page_Name .. "_Control" then 
						TweenService:Create(v.Frame.Line.PageInLine, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
							BackgroundTransparency = 0
						}):Play()
					else
						TweenService:Create(v.Frame.Line.PageInLine, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
							BackgroundTransparency = 1
						}):Play()
					end
				end
			end
		end)

		UIPage:GetPropertyChangedSignal("CurrentPage"):Connect(function()
			local Active = UIPage.CurrentPage == PageContainer
			TweenService:Create(PageName.Frame.Line.PageInLine, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
				BackgroundTransparency = Active and 0 or 1
			}):Play()
			if Active then
				PageContainer.Visible = true
			end
		end)

		local pageFunction = {}

		function pageFunction:AddSection(Section_Name, Toggleable, SectionGap, SectionColor)
			local Toggleable = Toggleable or false
			local Section = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local Topsec = Instance.new("Frame")
			local Sectiontitle = Instance.new("TextLabel")
			local Linesec = Instance.new("Frame")
			local UIGradient = Instance.new("UIGradient")
			local SectionList = Instance.new("UIListLayout")
			
			Section.Name = Section_Name .. "_Dot"
			Section.Parent = PageList
			Section.Size = UDim2.new(1, -5, 0, 30)
			Section.BackgroundColor3 = Color3.fromRGB(44, 56, 78)
			Section.BackgroundTransparency = 0.55
			Section.ClipsDescendants = true

			local sectionStroke = Instance.new("UIStroke", Section)
			sectionStroke.Color = Color3.fromRGB(0, 45, 95)
			sectionStroke.Thickness = 1

			local sectionGradient = Instance.new("UIGradient", Section)
			sectionGradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 44, 62)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(44, 56, 78))
			}
			sectionGradient.Rotation = 90
			sectionGradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0.35),
				NumberSequenceKeypoint.new(1, 0.45)
			}

			UICorner.CornerRadius = UDim.new(0, 4)
			UICorner.Parent = Section

			Topsec.Name = "Topsec"
			Topsec.Parent = Section
			Topsec.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
			Topsec.BackgroundTransparency = 1.000
			Topsec.Size = UDim2.new(1, 0, 0, 34)

			Sectiontitle.Name = "Sectiontitle"
			Sectiontitle.Parent = Topsec
			Sectiontitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
			Sectiontitle.BackgroundTransparency = 1.000
			Sectiontitle.Size = UDim2.new(1, 0, 1, 0)
			Sectiontitle.Font = Enum.Font.GothamBold
			Sectiontitle.Text = Section_Name
			Sectiontitle.TextSize = 16.000
			Sectiontitle.TextColor3 = getgenv().UIColor["Section Text Color"]

			Linesec.Name = "Linesec"
			Linesec.Parent = Topsec
			Linesec.AnchorPoint = Vector2.new(0.5, 1)
			Linesec.BorderSizePixel = 0
			Linesec.Position = UDim2.new(0.5, 0, 1, -2)
			Linesec.Size = UDim2.new(1, -10, 0, 2)
			Linesec.BackgroundColor3 = getgenv().UIColor["Section Underline Color"]

			local LineShadow = Instance.new("ImageLabel", Linesec)
			LineShadow.Name = "LineShadow"
			LineShadow.AnchorPoint = Vector2.new(0.5, 0.5)
			LineShadow.BackgroundColor3 = Color3.fromRGB(163,162,165)
			LineShadow.BackgroundTransparency = 1
			LineShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
			LineShadow.Size = UDim2.new(1, 8, 1, 8)
			LineShadow.ZIndex = 0
			LineShadow.Image = "rbxassetid://5028857084"
			LineShadow.ImageTransparency = 0.6
			LineShadow.ScaleType = Enum.ScaleType.Slice
			LineShadow.SliceCenter = Rect.new(24, 24, 276, 276)

			UIGradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(0.51, 0.02),
				NumberSequenceKeypoint.new(1, 1)
			}
			UIGradient.Parent = Linesec

			SectionList.Name = "SectionList"
			SectionList.Parent = Section
			SectionList.SortOrder = Enum.SortOrder.LayoutOrder
			SectionList.Padding = UDim.new(0, 5)

			local SizeSectionY
			local sectionIsVisible = false
			if Toggleable then
				local VisibilitySectionFrame = Instance.new("Frame")
				local VisibilitySectionFrameCorner = Instance.new("UICorner")
				local visibility = Instance.new("ImageButton")
				local visibility_off = Instance.new("ImageButton")
				local VisibilityButton = Instance.new("TextButton")
				VisibilityButton.Name = "VisibilityButton"
				VisibilityButton.Parent = Topsec
				VisibilityButton.AnchorPoint = Vector2.new(1, 0.5)
				VisibilityButton.BackgroundTransparency = 1.000
				VisibilityButton.Text = ""
				VisibilityButton.ZIndex = 4
				VisibilityButton.Position = UDim2.new(1, -5, 0.5, 0)
				VisibilityButton.Size = UDim2.new(0, 20, 0, 20)
				VisibilitySectionFrame.Name = "VisibilitySectionFrame"
				VisibilitySectionFrame.Parent = Topsec
				VisibilitySectionFrame.AnchorPoint = Vector2.new(1, 0.5)
				VisibilitySectionFrame.BackgroundColor3 = Color3.fromRGB(18, 26, 40)
				VisibilitySectionFrame.BorderSizePixel = 0
				VisibilitySectionFrame.Position = UDim2.new(1, -5, 0.5, 0)
				VisibilitySectionFrame.Size = UDim2.new(0, 20, 0, 20)
				VisibilitySectionFrameCorner.CornerRadius = UDim.new(0, 4)
				VisibilitySectionFrameCorner.Name = "VisibilitySectionFrameCorner"
				VisibilitySectionFrameCorner.Parent = VisibilitySectionFrame
				visibility.Name = "visibility"
				visibility.Parent = VisibilitySectionFrame
				visibility.AnchorPoint = Vector2.new(0.5, 0.5)
				visibility.BackgroundTransparency = 1.000
				visibility.Position = UDim2.new(0.5, 0, 0.5, 0)
				visibility.Size = UDim2.new(1, -4, 1, -4)
				visibility.ZIndex = 2
				visibility.Image = "rbxassetid://3926307971"
				visibility.ImageRectOffset = Vector2.new(84, 44)
				visibility.ImageRectSize = Vector2.new(36, 36)
				visibility.ImageTransparency = 1
				visibility_off.Name = "visibility_off"
				visibility_off.Parent = VisibilitySectionFrame
				visibility_off.AnchorPoint = Vector2.new(0.5, 0.5)
				visibility_off.BackgroundTransparency = 1.000
				visibility_off.Position = UDim2.new(0.5, 0, 0.5, 0)
				visibility_off.Size = UDim2.new(1, -4, 1, -4)
				visibility_off.ZIndex = 2
				visibility_off.Image = "rbxassetid://3926307971"
				visibility_off.ImageRectOffset = Vector2.new(564, 44)
				visibility_off.ImageRectSize = Vector2.new(36, 36)
				visibility_off.ImageTransparency = 0

				local function RefreshCollapse()
					TweenService:Create(Section, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
						Size = UDim2.new(1, -5, 0, sectionIsVisible and (SizeSectionY or 34) or 34)
					}):Play()
					visibility.ImageTransparency = sectionIsVisible and 0 or 1
					visibility_off.ImageTransparency = sectionIsVisible and 1 or 0
				end
				local function ToggleCollapse()
					sectionIsVisible = not sectionIsVisible
					RefreshCollapse()
				end

				-- the whole header is the collapse handle
				local CollapseButton = Instance.new("TextButton")
				CollapseButton.Name = "CollapseButton"
				CollapseButton.Parent = Topsec
				CollapseButton.BackgroundTransparency = 1
				CollapseButton.AutoButtonColor = false
				CollapseButton.Text = ""
				CollapseButton.Size = UDim2.new(1, -32, 1, 0)
				CollapseButton.ZIndex = 3

				VisibilityButton.MouseButton1Down:Connect(ToggleCollapse)
				CollapseButton.MouseButton1Down:Connect(ToggleCollapse)

				Section.Size = UDim2.new(1, -5, 0, 34)
			end
			if SectionGap then
				local SectionGap = Instance.new("Frame")
				SectionGap.Name = "SectionGap"
				SectionGap.Parent = PageList
				SectionGap.Size = UDim2.new(1, -5, 0, 30)
				SectionGap.ClipsDescendants = true
				SectionGap.Transparency = 1
			end

			SectionList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				SizeSectionY = SectionList.AbsoluteContentSize.Y + 5
				if not Toggleable or sectionIsVisible then
					Section.Size = UDim2.new(1, -5, 0, SizeSectionY)
				end
			end)

			-- เก็บสีของ section ไว้ให้ระบบธีมอัปเดต
			if Library_Function.RegisterThemeTree then
				Library_Function.RegisterThemeTree(Section)
			end
			local sectionFunction = {}
			function sectionFunction:AddToggle(idk,Setting)
				local Title = tostring(Setting.Text or Setting.Title) or ""
				local Desc = Setting.Desc or Setting.Description
				local Default = Setting.Default
				if Default == nil then
					Default = false
				end
				local Callback = Setting.Callback
				local ToggleFrame = Instance.new("Frame")
				local TogFrame1 = Instance.new("Frame")
				local checkbox = Instance.new("ImageLabel")
				local check = Instance.new("Frame")
				local ToggleDesc = Instance.new("TextLabel")
				local ToggleTitle = Instance.new("TextLabel")
				local ToggleBg = Instance.new("Frame")
				local ToggleCorner = Instance.new("UICorner")
				local ToggleButton = Instance.new("TextButton")
				local ToggleList = Instance.new("UIListLayout")
				ToggleFrame.Name = "ToggleFrame"
				ToggleFrame.Parent = Section
				ToggleFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
				ToggleFrame.BackgroundTransparency = 1.000
				ToggleFrame.Position = UDim2.new(0, 0, 0.300000012, 0)
				ToggleFrame.Size = UDim2.new(1, 0 , 0, 0)
				ToggleFrame.AutomaticSize = Enum.AutomaticSize.Y
				TogFrame1.Name = "TogFrame1"
				TogFrame1.Parent = ToggleFrame
				TogFrame1.AnchorPoint = Vector2.new(0.5, 0.5)
				TogFrame1.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
				TogFrame1.BackgroundTransparency = 1.000
				TogFrame1.Position = UDim2.new(0.5, 0, 0.5, 0)
				TogFrame1.Size = UDim2.new(1, -10, 0, 0)
				TogFrame1.AutomaticSize = Enum.AutomaticSize.Y
				checkbox.Name = "checkbox"
				checkbox.Parent = TogFrame1
				checkbox.AnchorPoint = Vector2.new(1, 0.5)
				checkbox.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
				checkbox.BackgroundTransparency = 1.000
				checkbox.Position = UDim2.new(1, -5, 0.5, 3)
				checkbox.Size = UDim2.new(0, 25, 0, 25)
				checkbox.Image = "rbxassetid://4552505888"
				checkbox.ImageColor3 = getgenv().UIColor["Toggle Border Color"]
				check.Name = "check"
				check.Parent = checkbox
				check.AnchorPoint = Vector2.new(0.5, 0.5)
				check.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
				check.Position = UDim2.new(0.5, 0, 0.5, 0)
				local cac = 5
				if Desc then
					cac = 0
					ToggleDesc.Name = "ToggleDesc"
					ToggleDesc.Parent = TogFrame1
					ToggleDesc.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
					ToggleDesc.BackgroundTransparency = 1.000
					ToggleDesc.Position = UDim2.new(0, 10, 0, 20)
					ToggleDesc.Size = UDim2.new(1, -50, 0, 0)
					ToggleDesc.Font = Enum.Font.GothamBlack
					ToggleDesc.Text = Desc
					ToggleDesc.TextSize = 13.000
					ToggleDesc.TextWrapped = true
					ToggleDesc.TextXAlignment = Enum.TextXAlignment.Left
					ToggleDesc.RichText = true
					ToggleDesc.AutomaticSize = Enum.AutomaticSize.Y
					ToggleDesc.TextColor3 = getgenv().UIColor["Toggle Desc Color"]
				else
					ToggleDesc.Text = ''
				end
				ToggleTitle.Name = "TextColor"
				ToggleTitle.Parent = TogFrame1
				ToggleTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
				ToggleTitle.BackgroundTransparency = 1.000
				ToggleTitle.Position = UDim2.new(0, 10, 0, cac)
				ToggleTitle.Size = UDim2.new(1, -10, 0, 20)
				ToggleTitle.Font = Enum.Font.GothamBlack
				ToggleTitle.Text = Title
				ToggleTitle.TextSize = 14.000
				ToggleTitle.TextXAlignment = Enum.TextXAlignment.Left
				ToggleTitle.TextYAlignment = Enum.TextYAlignment.Center
				ToggleTitle.RichText = true
				ToggleTitle.AutomaticSize = Enum.AutomaticSize.Y
				ToggleTitle.TextColor3 = getgenv().UIColor["Text Color"]
				ToggleBg.Name = "Background1"
				ToggleBg.Parent = TogFrame1
				ToggleBg.Size = UDim2.new(1, 0, 1, 6)
				ToggleBg.ZIndex = 0
				ToggleBg.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
				ToggleBg.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
				ToggleCorner.CornerRadius = UDim.new(0, 4)
				ToggleCorner.Name = "ToggleCorner"
				ToggleCorner.Parent = ToggleBg
				ToggleButton.Name = "ToggleButton"
				ToggleButton.Parent = TogFrame1
				ToggleButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
				ToggleButton.BackgroundTransparency = 1.000
				ToggleButton.AnchorPoint = Vector2.new(1, 0.5)
				ToggleButton.Size = UDim2.new(0, 25, 0, 25)
				ToggleButton.Position = UDim2.new(1, -5, 0.5, 3)
				ToggleButton.Font = Enum.Font.SourceSans
				ToggleButton.Text = ""
				ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
				ToggleButton.TextSize = 14.000
				ToggleList.Name = "ToggleList"
				ToggleList.Parent = ToggleFrame
				ToggleList.HorizontalAlignment = Enum.HorizontalAlignment.Center
				ToggleList.SortOrder = Enum.SortOrder.LayoutOrder
				ToggleList.VerticalAlignment = Enum.VerticalAlignment.Center
				ToggleList.Padding = UDim.new(0, 5)
				local function ChangeStage(val)
					local csize = val and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, 0, 0, 0)
					local pos = val and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0.5, 0, 0.5, 0)
					local apos = val and Vector2.new(0.5, 0.5) or Vector2.new(0.5, 0.5)
					game.TweenService:Create(check, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
						Size = csize,
						Position = pos,
						AnchorPoint = apos
					}):Play()
				end
				ChangeStage(Default)
				local function ButtonClick()
					Default = not Default
				    ChangeStage(Default)
				    if Callback then
				        pcall(Callback, Default)
				    end
				end
				ToggleButton.MouseButton1Down:Connect(function()
					ButtonClick()
				end)
				local toggleFunction = {}
				function toggleFunction.SetStage(value)
					if value ~= Default then
						ButtonClick()
					end
				end
				local controlData = {
                    Name = Title,
                    Section = Section,
                    Element = ToggleFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageName
                }
                table.insert(getgenv().AllControls, controlData)
                
				return toggleFunction
			end
        function sectionFunction:AddButton(Setting, Callback)
        	local Title = Setting.Title or Setting.Text or ""
        	local Callback = Setting.Callback or Setting.Func or function() end
            local Button = Instance.new("Frame")
            local RowBG_1 = Instance.new("Frame")
            local UICorner_1 = Instance.new("UICorner")
            local RowHover_1 = Instance.new("Frame")
            local UICorner_2 = Instance.new("UICorner")
            local TextColor_1 = Instance.new("TextLabel")
            local ClickArea_1 = Instance.new("Frame")
            local UICorner_3 = Instance.new("UICorner")
            local UIGradient_1 = Instance.new("UIGradient")
            local ImageLabel_1 = Instance.new("ImageLabel")
            local Frame_1 = Instance.new("Frame")
            local UICorner_4 = Instance.new("UICorner")
            local UIScale_1 = Instance.new("UIScale")
            local Button_1 = Instance.new("TextButton")
            
            Button.Name = "Button"
            Button.Parent = Section
            Button.BackgroundColor3 = Color3.fromRGB(163,162,165)
            Button.BackgroundTransparency = 1
            Button.Size = UDim2.new(1, 0,0, 40)
             
            RowBG_1.Name = "RowBG"
            RowBG_1.Parent = Button
            RowBG_1.AnchorPoint = Vector2.new(0.5, 0.5)
            RowBG_1.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
            RowBG_1.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
            RowBG_1.Position = UDim2.new(0.5, 0,0.5, 0)
            RowBG_1.Size = UDim2.new(1, -10,1, 0)
             
            UICorner_1.Parent = RowBG_1
            UICorner_1.CornerRadius = UDim.new(0,10)
             
            RowHover_1.Name = "RowHover"
            RowHover_1.Parent = RowBG_1
            RowHover_1.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
            RowHover_1.BackgroundTransparency = 1
            RowHover_1.Size = UDim2.new(1, 0,1, 0)
            RowHover_1.ZIndex = 2
             
            UICorner_2.Parent = RowHover_1
            UICorner_2.CornerRadius = UDim.new(0,10)
             
            TextColor_1.Name = "TextColor"
            TextColor_1.Parent = RowBG_1
             TextColor_1.BackgroundColor3 = Color3.fromRGB(163,162,165)
             TextColor_1.BackgroundTransparency = 1
             TextColor_1.Position = UDim2.new(0, 12,0, 0)
             TextColor_1.Size = UDim2.new(1, -110,1, 0)
             TextColor_1.Font = Enum.Font.GothamBold
             TextColor_1.Text = Title
             TextColor_1.TextColor3 = getgenv().UIColor["GUI Text Color"]
             TextColor_1.TextSize = 14
             TextColor_1.TextStrokeTransparency = 0.8500000238418579
             TextColor_1.TextXAlignment = Enum.TextXAlignment.Left
             
             ClickArea_1.Name = "ClickArea"
             ClickArea_1.Parent = RowBG_1
             ClickArea_1.AnchorPoint = Vector2.new(1, 0.5)
             ClickArea_1.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
             ClickArea_1.Position = UDim2.new(1, -8,0.5, 0)
             ClickArea_1.Size = UDim2.new(0, 94,0, 30)
             ClickArea_1.ClipsDescendants = true
             
             UICorner_3.Parent = ClickArea_1
             UICorner_3.CornerRadius = UDim.new(0,12)
             
             UIGradient_1.Parent = ClickArea_1
             UIGradient_1.Color = ColorSequence.new{
                 ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 175, 255)), 
                 ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 140, 255)), 
                 ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 105, 215)), 
                 ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 75, 160))
             }
             UIGradient_1.Rotation = 90
             
             ImageLabel_1.Parent = ClickArea_1
             ImageLabel_1.AnchorPoint = Vector2.new(0.5, 0.5)
             ImageLabel_1.BackgroundColor3 = Color3.fromRGB(163,162,165)
             ImageLabel_1.BackgroundTransparency = 1
             ImageLabel_1.Position = UDim2.new(0.5, 0,0.5, 0)
             ImageLabel_1.Size = UDim2.new(1, 14,1, 14)
             ImageLabel_1.ZIndex = 0
             ImageLabel_1.Image = "rbxassetid://5028857084"
             ImageLabel_1.ImageTransparency = 0.7
             ImageLabel_1.ScaleType = Enum.ScaleType.Slice
             ImageLabel_1.SliceCenter = Rect.new(24, 24, 276, 276)
             
             Frame_1.Parent = ClickArea_1
             Frame_1.AnchorPoint = Vector2.new(0.5, 0)
             Frame_1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
             Frame_1.BackgroundTransparency = 0.8
             Frame_1.Position = UDim2.new(0.5, 0,0, 2)
             Frame_1.Size = UDim2.new(1, -6,0, 10)
             Frame_1.ZIndex = 2
             
             UICorner_4.Parent = Frame_1
             UICorner_4.CornerRadius = UDim.new(0,10)
             
             UIScale_1.Parent = ClickArea_1
             
             Button_1.Name = "Button"
             Button_1.Parent = ClickArea_1
             Button_1.Active = true
             Button_1.AutoButtonColor = false
             Button_1.BackgroundColor3 = Color3.fromRGB(163,162,165)
             Button_1.BackgroundTransparency = 1
             Button_1.Size = UDim2.new(1, 0,1, 0)
             Button_1.Font = Enum.Font.GothamBold
             Button_1.Text = "Click"
             Button_1.TextColor3 = Color3.fromRGB(240, 240, 240)
             Button_1.TextSize = 13

             UIScale_1.Scale = 1
             
             local scaleHover = TweenService:Create(UIScale_1, TweenInfo.new(0.12, Enum.EasingStyle.Sine), { Scale = 1.05 })
             local scaleNormal = TweenService:Create(UIScale_1, TweenInfo.new(0.12, Enum.EasingStyle.Sine), { Scale = 1 })
             
             Button_1.MouseEnter:Connect(function()
             	scaleHover:Play()
             end)
             
             Button_1.MouseLeave:Connect(function()
             	scaleNormal:Play()
             end)
             
                Button_1.MouseButton1Down:Connect(function()
                    
                    local w = ClickArea_1.AbsoluteSize.X
                    local h = ClickArea_1.AbsoluteSize.Y
                    
                    local ripple = Instance.new("Frame")
                    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
                    ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
                    ripple.Size = UDim2.new(0, 0, 0, 0)
                    ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    ripple.BackgroundTransparency = 0.6
                    ripple.ZIndex = 20
                    ripple.Parent = ClickArea_1
                    
                    local rippleCorner = Instance.new("UICorner")
                    rippleCorner.CornerRadius = UICorner_3.CornerRadius
                    rippleCorner.Parent = ripple
                    
                    local rippleTween = TweenService:Create(
                        ripple,
                        TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                        {
                            Size = UDim2.new(1, 0, 1, 0),
                            BackgroundTransparency = 1,
                            Position = UDim2.new(0.5, 0, 0.5, 0)
                        }
                    )
                    
                    rippleTween:Play()
                    rippleTween.Completed:Connect(function()
                        ripple:Destroy()
                    end)
                    
                    Callback()
                end)
                local f = {}
                function f:SetTitle(vl)
                    TextColor_1.Text = vl
                end
                local controlData = {
                    Name = Title,
                    Section = Section,
                    Element = Button,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageName
                }
                table.insert(getgenv().AllControls, controlData)
                
                return f
            end
        
			function sectionFunction:AddLabel(text, ...)
				local Lines = { tostring(text) }
				for _, Extra in ipairs({ ... }) do
					table.insert(Lines, tostring(Extra))
				end
				local Title = (table.concat(Lines, "\n"):gsub("\\n", "\n"))
                local LabelFrame = Instance.new("Frame")
                local LabelBG = Instance.new("Frame")
                local UICorner = Instance.new("UICorner")
                local LabelPadding = Instance.new("UIPadding")
                local TextColor = Instance.new("TextLabel")
                
                LabelFrame.Name = "LabelFrame"
                LabelFrame.Parent = Section
                LabelFrame.AutomaticSize = Enum.AutomaticSize.Y
                LabelFrame.BackgroundColor3 = Color3.fromRGB(163,162,165)
                LabelFrame.BackgroundTransparency = 1
                LabelFrame.Size = UDim2.new(1, 0,0, 0)
                
                LabelBG.Name = "LabelBG"
                LabelBG.Parent = LabelFrame
                LabelBG.AnchorPoint = Vector2.new(0.5, 0)
                LabelBG.AutomaticSize = Enum.AutomaticSize.Y
                LabelBG.BackgroundColor3 = Color3.fromRGB(34, 44, 62)
                LabelBG.BackgroundTransparency = 0.25
                LabelBG.Position = UDim2.new(0.5, 0,0, 0)
                LabelBG.Size = UDim2.new(1, -10,0, 0)
                
                UICorner.Parent = LabelBG
                UICorner.CornerRadius = UDim.new(0,6)

                LabelPadding.Parent = LabelBG
                LabelPadding.PaddingTop = UDim.new(0, 6)
                LabelPadding.PaddingBottom = UDim.new(0, 6)
                LabelPadding.PaddingLeft = UDim.new(0, 12)
                LabelPadding.PaddingRight = UDim.new(0, 12)
                
                
                TextColor.Name = "TextColor"
                TextColor.Parent = LabelBG
                TextColor.AutomaticSize = Enum.AutomaticSize.Y
                TextColor.BackgroundColor3 = Color3.fromRGB(163,162,165)
                TextColor.BackgroundTransparency = 1
                TextColor.Position = UDim2.new(0, 0,0, 0)
                TextColor.Size = UDim2.new(1, 0,0, 0)
                TextColor.Font = Enum.Font.GothamMedium
                TextColor.Text = Title
                TextColor.TextColor3 = Color3.fromRGB(240,240,230)
                TextColor.TextSize = 14
                TextColor.TextStrokeTransparency = 0.8500000238418579
                TextColor.TextWrapped = true
                TextColor.TextXAlignment = Enum.TextXAlignment.Left
				local labelFunction = {}
				function labelFunction:SetText(text)
					TextColor.Text = (tostring(text):gsub("\\n", "\n"))
				end
				function labelFunction:SetColor(color)
					TextColor.TextColor3 = color
				end
				local controlData = {
                    Name = Title,
                    Section = Section,
                    Element = LabelFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageName
                }
                table.insert(getgenv().AllControls, controlData)
                
				return labelFunction
			end
            function sectionFunction:AddDropdownSection(Setting)
                local Title = tostring(Setting.Text or Setting.Title or "")
                local Search = Setting.Search or false
              
                local DropdownFrame = Instance.new("Frame")
                local Dropdownbg = Instance.new("Frame")
                local Dropdowncorner = Instance.new("UICorner")
                local Topdrop = Instance.new("Frame")
                local UICorner = Instance.new("UICorner")
                local ImgDrop = Instance.new("ImageLabel")
                local DropdownButton = Instance.new("TextButton")
                local Dropdownlisttt = Instance.new("Frame")
                local DropdownScroll = Instance.new("ScrollingFrame")
                local ScrollContainer = Instance.new("Frame")
                local ScrollContainerList = Instance.new("UIListLayout")
                
                DropdownFrame.Name = Title .. "DropdownSectionFrame"
                DropdownFrame.Parent = Section
                DropdownFrame.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                DropdownFrame.BackgroundTransparency = 1.000
                DropdownFrame.Position = UDim2.new(0, 0, 0, 0)
                DropdownFrame.Size = UDim2.new(1, 0, 0, 25)
                
                Dropdownbg.Name = "Background1"
                Dropdownbg.Parent = DropdownFrame
                Dropdownbg.AnchorPoint = Vector2.new(0.5, 0.5)
                Dropdownbg.Position = UDim2.new(0.5, 0, 0.5, 0)
                Dropdownbg.Size = UDim2.new(1, -10, 1, 0)
                Dropdownbg.ClipsDescendants = true
                Dropdownbg.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
                Dropdownbg.BackgroundTransparency = 0.25
                
                Dropdowncorner.CornerRadius = UDim.new(0, 4)
                Dropdowncorner.Name = "Dropdowncorner"
                Dropdowncorner.Parent = Dropdownbg
                
                Topdrop.Name = "Background2"
                Topdrop.Parent = Dropdownbg
                Topdrop.Size = UDim2.new(1, 0, 0, 25)
                Topdrop.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
                Topdrop.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
                
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Topdrop
                
                local Dropdowntitle
                if Search then
                    Dropdowntitle = Instance.new("TextBox")
                    Dropdowntitle.PlaceholderText = Title
                    Dropdowntitle.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
                else
                    Dropdowntitle = Instance.new("TextLabel")
                    Dropdowntitle.Text = Title
                end
                
                Dropdowntitle.Name = "TextColorPlaceholder"
                Dropdowntitle.Parent = Topdrop
                Dropdowntitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                Dropdowntitle.BackgroundTransparency = 1.000
                Dropdowntitle.Position = UDim2.new(0, 10, 0, 0)
                Dropdowntitle.Size = UDim2.new(1, -40, 1, 0)
                Dropdowntitle.Font = Enum.Font.GothamBlack
                Dropdowntitle.TextSize = 14.000
                Dropdowntitle.TextXAlignment = Enum.TextXAlignment.Left
                Dropdowntitle.ClipsDescendants = true
                Dropdowntitle.TextColor3 = getgenv().UIColor["Text Color"]
                
                ImgDrop.Name = "ImgDrop"
                ImgDrop.Parent = Topdrop
                ImgDrop.AnchorPoint = Vector2.new(1, 0.5)
                ImgDrop.BackgroundTransparency = 1.000
                ImgDrop.BorderColor3 = Color3.fromRGB(27, 42, 53)
                ImgDrop.Position = UDim2.new(1, -6, 0.5, 0)
                ImgDrop.Size = UDim2.new(0, 15, 0, 15)
                ImgDrop.Image = "rbxassetid://6954383209"
                ImgDrop.ImageColor3 = getgenv().UIColor["Dropdown Icon Color"]
                
                DropdownButton.Name = "DropdownButton"
                DropdownButton.Parent = Topdrop
                DropdownButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                DropdownButton.BackgroundTransparency = 1.000
                DropdownButton.Size = Search and UDim2.new(0, 30, 0, 30) or UDim2.new(1, 0, 1 , 0)
                DropdownButton.Position = Search and UDim2.new(1, -35, 0, 0) or UDim2.new(0 , 0 , 0 , 0)
                DropdownButton.Font = Enum.Font.GothamBold
                DropdownButton.Text = ""
                DropdownButton.TextColor3 = Color3.fromRGB(230, 230, 230)
                DropdownButton.TextSize = 14.000
                
                Dropdownlisttt.Name = "Dropdownlisttt"
                Dropdownlisttt.Parent = Dropdownbg
                Dropdownlisttt.BackgroundTransparency = 1.000
                Dropdownlisttt.BorderSizePixel = 0
                Dropdownlisttt.Position = UDim2.new(0, 0, 0, 25)
                Dropdownlisttt.Size = UDim2.new(1, 0, 0, 0)
                Dropdownlisttt.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                
                DropdownScroll.Name = "DropdownScroll"
                DropdownScroll.Parent = Dropdownlisttt
                DropdownScroll.Active = true
                DropdownScroll.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                DropdownScroll.BackgroundTransparency = 1.000
                DropdownScroll.BorderSizePixel = 0
                DropdownScroll.Size = UDim2.new(1, 0, 1, 0)
                DropdownScroll.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
                DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                DropdownScroll.ScrollBarThickness = 5
                DropdownScroll.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
                DropdownScroll.ScrollingEnabled = true
                DropdownScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always
                
                ScrollContainer.Name = "ScrollContainer"
                ScrollContainer.Parent = DropdownScroll
                ScrollContainer.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                ScrollContainer.BackgroundTransparency = 1.000
                ScrollContainer.Position = UDim2.new(0, 5, 0, 5)
                ScrollContainer.Size = UDim2.new(1, -15, 1, -5)
                
                ScrollContainerList.Name = "ScrollContainerList"
                ScrollContainerList.Parent = ScrollContainer
                ScrollContainerList.SortOrder = Enum.SortOrder.LayoutOrder
                ScrollContainerList.Padding = UDim.new(0, 5)
                
                local InternalSection = Instance.new("Frame")
                InternalSection.Name = "InternalSection"
                InternalSection.Parent = ScrollContainer
                InternalSection.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                InternalSection.BackgroundTransparency = 1.000
                InternalSection.Size = UDim2.new(1, 0, 0, 0)
                InternalSection.AutomaticSize = Enum.AutomaticSize.Y
                
                local InternalList = Instance.new("UIListLayout")
                InternalList.Name = "InternalList"
                InternalList.Parent = InternalSection
                InternalList.SortOrder = Enum.SortOrder.LayoutOrder
                InternalList.Padding = UDim.new(0, 5)
                
                local isOpen = false
                local dropdownSectionFunction = {}

                DropdownButton.MouseButton1Click:Connect(function()
                    dropdownSectionFunction:SetOpen(not isOpen)
                end)
                
                ScrollContainerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 10 + ScrollContainerList.AbsoluteContentSize.Y + 5)
                end)
                
                InternalList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    local contentHeight = math.min(InternalList.AbsoluteContentSize.Y + 10, 300)
                    local listsize = isOpen and UDim2.new(1, 0, 0, contentHeight) or UDim2.new(1, 0, 0, 0)
                    local mainsize = isOpen and UDim2.new(1, 0, 0, contentHeight + 25) or UDim2.new(1, 0, 0, 25)
                    
                    if isOpen then
                        TweenService:Create(Dropdownlisttt, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
                            Size = listsize
                        }):Play()
                        TweenService:Create(DropdownFrame, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
                            Size = mainsize
                        }):Play()
                    end
                end)
                
                function dropdownSectionFunction:AddSlider(Setting)
                    local TitleText = tostring(Setting.Text or Setting.Title) or ""
                    local minValue = tonumber(Setting.Min) or 0
                    local maxValue = tonumber(Setting.Max) or 100
                    local Precise = Setting.Precise or false
                    local DefaultValue = tonumber(Setting.Default) or 0
                    local Callback = Setting.Callback
                    local Rounding = Setting.Rouding or Setting.Rounding
                    
                    local SliderFrame = Instance.new("Frame")
                    local SliderCorner = Instance.new("UICorner")
                    local SliderBG = Instance.new("Frame")
                    local SliderBGCorner = Instance.new("UICorner")
                    local SliderTitle = Instance.new("TextLabel")
                    local SliderBar = Instance.new("Frame")
                    local SliderButton = Instance.new("TextButton")
                    local SliderBarCorner = Instance.new("UICorner")
                    local Bar = Instance.new("Frame")
                    local BarCorner = Instance.new("UICorner")
                    local Sliderboxframe = Instance.new("Frame")
                    local Sliderbox = Instance.new("UICorner")
                    local Sliderbox_2 = Instance.new("TextBox")
                    
                    SliderFrame.Name = TitleText
                    SliderFrame.Parent = InternalSection
                    SliderFrame.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
                    SliderFrame.BackgroundTransparency = 1.000
                    SliderFrame.Size = UDim2.new(1, 0, 0, 50)
                    
                    SliderCorner.CornerRadius = UDim.new(0, 4)
                    SliderCorner.Name = "SliderCorner"
                    SliderCorner.Parent = SliderFrame
                    
                    SliderBG.Name = "Background1"
                    SliderBG.Parent = SliderFrame
                    SliderBG.AnchorPoint = Vector2.new(0.5, 0.5)
                    SliderBG.Position = UDim2.new(0.5, 0, 0.5, 0)
                    SliderBG.Size = UDim2.new(1, -5, 1, 0)
                    SliderBG.BackgroundColor3 = Color3.fromRGB(24, 32, 46)
                    SliderBG.BackgroundTransparency = 0.25
                    
                    SliderBGCorner.CornerRadius = UDim.new(0, 4)
                    SliderBGCorner.Name = "SliderBGCorner"
                    SliderBGCorner.Parent = SliderBG
                    
                    SliderTitle.Name = "TextColor"
                    SliderTitle.Parent = SliderBG
                    SliderTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                    SliderTitle.BackgroundTransparency = 1.000
                    SliderTitle.Position = UDim2.new(0, 10, 0, 0)
                    SliderTitle.Size = UDim2.new(0.65, -10, 0, 25)
                    SliderTitle.Font = Enum.Font.GothamBlack
                    SliderTitle.Text = TitleText
                    SliderTitle.TextSize = 14.000
                    SliderTitle.RichText = true
                    SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
                    SliderTitle.TextColor3 = getgenv().UIColor["Text Color"]
                    
                    SliderBar.Name = "SliderBar"
                    SliderBar.Parent = SliderFrame
                    SliderBar.AnchorPoint = Vector2.new(0.5, 0.5)
                    SliderBar.Position = UDim2.new(0.5, 0, 0.5, 14)
                    SliderBar.Size = UDim2.new(0.9, 0, 0, 6)
                    SliderBar.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
                    
                    SliderButton.Name = "SliderButton"
                    SliderButton.Parent = SliderBar
                    SliderButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                    SliderButton.BackgroundTransparency = 1.000
                    SliderButton.Size = UDim2.new(1, 0, 1, 0)
                    SliderButton.Font = Enum.Font.GothamBold
                    SliderButton.Text = ""
                    SliderButton.TextColor3 = Color3.fromRGB(230, 230, 230)
                    SliderButton.TextSize = 14.000
                    
                    SliderBarCorner.CornerRadius = UDim.new(1, 0)
                    SliderBarCorner.Name = "SliderBarCorner"
                    SliderBarCorner.Parent = SliderBar
                    
                    Bar.Name = "Bar"
                    Bar.BorderSizePixel = 0
                    Bar.Parent = SliderBar
                    Bar.Size = UDim2.new(0, 0, 1, 0)
                    Bar.BackgroundColor3 = getgenv().UIColor["Slider Line Color"]
                    
                    BarCorner.CornerRadius = UDim.new(1, 0)
                    BarCorner.Name = "BarCorner"
                    BarCorner.Parent = Bar
                    
                    Sliderboxframe.Name = "Background2"
                    Sliderboxframe.Parent = SliderFrame
                    Sliderboxframe.AnchorPoint = Vector2.new(1, 0)
                    Sliderboxframe.Position = UDim2.new(1, -10, 0, 5)
                    Sliderboxframe.Size = UDim2.new(0.25, 0, 0, 25)
                    Sliderboxframe.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
                    
                    Sliderbox.CornerRadius = UDim.new(0, 4)
                    Sliderbox.Name = "Sliderbox"
                    Sliderbox.Parent = Sliderboxframe
                    
                    Sliderbox_2.Name = "TextColor"
                    Sliderbox_2.Parent = Sliderboxframe
                    Sliderbox_2.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                    Sliderbox_2.BackgroundTransparency = 1.000
                    Sliderbox_2.Size = UDim2.new(1, 0, 1, 0)
                    Sliderbox_2.Font = Enum.Font.GothamBold
                    Sliderbox_2.Text = ""
                    Sliderbox_2.TextSize = 14.000
                    Sliderbox_2.TextColor3 = getgenv().UIColor["Text Color"]
                    
                    SliderButton.MouseEnter:Connect(function()
                        TweenService:Create(Bar, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
                            BackgroundColor3 = getgenv().UIColor["Slider Highlight Color"]
                        }):Play()
                    end)
                    
                    SliderButton.MouseLeave:Connect(function()
                        TweenService:Create(Bar, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
                            BackgroundColor3 = getgenv().UIColor["Slider Line Color"]
                        }):Play()
                    end)
                    
                    local callBackAndSetText = function(val)
                        Sliderbox_2.Text = tostring(val)
                        Callback(tonumber(val))
                    end
                    if DefaultValue then
                        if DefaultValue <= minValue then
                            DefaultValue = minValue
                        elseif DefaultValue >= maxValue then
                            DefaultValue = maxValue
                        end
                        Bar.Size = UDim2.new(1 - ((maxValue - DefaultValue) / (maxValue - minValue)), 0, 0, 6)
                        Sliderbox_2.Text = tostring(DefaultValue)
                    end
                    
                    
                    local dragging = false
                    local dragInput
                    local holdTime = 0
                    local holdStarted = 0
                    
                    local function onInputBegan(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            holdStarted = Now()
                            
                            input.Changed:Connect(function()
                                if input.UserInputState == Enum.UserInputState.End then
                                    dragging = false
                                    holdStarted = 0
                                end
                            end)
                        end
                    end
                    
                    local function onInputEnded(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = false
                            holdStarted = 0
                        end
                    end
                    
                    local function onInputChanged(input)
                        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                            dragInput = input
                        end
                    end
                    
                    SliderButton.InputBegan:Connect(onInputBegan)
                    SliderButton.InputEnded:Connect(onInputEnded)
                    SliderButton.InputChanged:Connect(onInputChanged)
                    
                    RunService.RenderStepped:Connect(function()
                        if holdStarted > 0 and (Now() - holdStarted >= holdTime) and not dragging then
                            dragging = true
                        end
                        
                        if dragging and dragInput then
                            local barWidth = math.clamp(dragInput.Position.X - Bar.AbsolutePosition.X, 0, SliderBar.AbsoluteSize.X)
                            local percentage = barWidth / SliderBar.AbsoluteSize.X
                            local value = minValue + (maxValue - minValue) * percentage
                            
                            if Rounding then
                                value = tonumber(string.format("%.".. Rounding .."f", value))
                            elseif not Precise then
                                value = math.floor(value)
                            end
                            
                            value = math.clamp(value, minValue, maxValue)
                            
                            pcall(function()
                                callBackAndSetText(value)
                            end)
                            Bar.Size = UDim2.new(percentage, 0, 1, 0)
                        end
                    end)
                    
                    local function GetSliderValue(Value)
                        Value = tonumber(Value) or minValue
                        Value = math.clamp(Value, minValue, maxValue)
                        
                        if Rounding then
                            Value = tonumber(string.format("%.".. Rounding .."f", Value))
                        elseif not Precise then
                            Value = math.floor(Value)
                        end
                        
                        local percentage = (Value - minValue) / (maxValue - minValue)
                        Bar.Size = UDim2.new(percentage, 0, 1, 0)
                        callBackAndSetText(Value)
                    end
                    
                    Sliderbox_2.FocusLost:Connect(function()
                        GetSliderValue(Sliderbox_2.Text)
                    end)
                    
                    local slider_function = {}
                    function slider_function.SetValue(Value)
                        GetSliderValue(Value)
                    end
                    
                    function slider_function.GetValue()
                        return tonumber(Sliderbox_2.Text) or minValue
                    end
                    
                    return slider_function
                end
                
                function dropdownSectionFunction:SetOpen(state)
                    state = state and true or false
                    if state == isOpen then
                        return
                    end
                    isOpen = state
                    TweenService:Create(Dropdownlisttt, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
                        Size = isOpen and UDim2.new(1, 0, 0, 200) or UDim2.new(1, 0, 0, 0)
                    }):Play()
                    TweenService:Create(DropdownFrame, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
                        Size = isOpen and UDim2.new(1, 0, 0, 230) or UDim2.new(1, 0, 0, 25)
                    }):Play()
                    TweenService:Create(ImgDrop, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
                        Rotation = isOpen and 90 or 0
                    }):Play()
                end
                
                function dropdownSectionFunction:GetOpen()
                    return isOpen
                end
                
                function dropdownSectionFunction:SetTitle(newTitle)
                    if Search then
                        Dropdowntitle.PlaceholderText = newTitle
                    else
                        Dropdowntitle.Text = newTitle
                    end
                end
                
                local controlData = {
                    Name = Title,
                    Section = Section,
                    Element = DropdownFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageName
                }
                table.insert(getgenv().AllControls, controlData)
                
                return dropdownSectionFunction
            end
            
			function sectionFunction:AddDropdown(idk, Setting)
				local Title = tostring(Setting.Text or Setting.Title or "")
				local List = Setting.Values or {}
				local Multi = Setting.Multi == true or Setting.MultiSelect == true or Setting.Selected == true
				local Callback = Setting.Callback
				local Placeholder = tostring(Setting.SubText or Setting.Subtitle or "None")
				local Default = Setting.Default
				if Multi then
					if type(Default) == "number" then
						Default = { List[Default] }
					elseif type(Default) == "string" then
						Default = { Default }
					end
					if type(Default) ~= "table" then
						Default = {}
					end
				elseif type(Default) == "number" then
					Default = List[Default]
				end

				local ClosedHeight = 48
				local ListHeight = 180

				local DropdownFrame = Instance.new("Frame")
				local Dropdownbg = Instance.new("Frame")
				local Dropdowncorner = Instance.new("UICorner")
				local Topdrop = Instance.new("Frame")
				local TopdropCorner = Instance.new("UICorner")
				local TitleLabel = Instance.new("TextLabel")
				local SubTextLabel = Instance.new("TextLabel")
				local ImgDrop = Instance.new("ImageLabel")
				local DropdownButton = Instance.new("TextButton")
				local Dropdownlisttt = Instance.new("Frame")
				local ListSearch = Instance.new("TextBox")
				local DropdownScroll = Instance.new("ScrollingFrame")
				local ScrollContainer = Instance.new("Frame")
				local ScrollContainerList = Instance.new("UIListLayout")

				DropdownFrame.Name = Title .. "DropdownFrame"
				DropdownFrame.Parent = Section
				DropdownFrame.BackgroundTransparency = 1.000
				DropdownFrame.Position = UDim2.new(0, 0, 0, 0)
				DropdownFrame.Size = UDim2.new(1, 0, 0, ClosedHeight)

				Dropdownbg.Name = "Background1"
				Dropdownbg.Parent = DropdownFrame
				Dropdownbg.AnchorPoint = Vector2.new(0.5, 0.5)
				Dropdownbg.Position = UDim2.new(0.5, 0, 0.5, 0)
				Dropdownbg.Size = UDim2.new(1, -10, 1, 0)
				Dropdownbg.ClipsDescendants = true
				Dropdownbg.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
				Dropdownbg.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]

				Dropdowncorner.CornerRadius = UDim.new(0, 4)
				Dropdowncorner.Parent = Dropdownbg

				Topdrop.Name = "Background2"
				Topdrop.Parent = Dropdownbg
				Topdrop.Size = UDim2.new(1, 0, 0, ClosedHeight)
				Topdrop.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
				Topdrop.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]

				TopdropCorner.CornerRadius = UDim.new(0, 4)
				TopdropCorner.Parent = Topdrop

				TitleLabel.Name = "TextColorPlaceholder"
				TitleLabel.Parent = Topdrop
				TitleLabel.BackgroundTransparency = 1.000
				TitleLabel.Position = UDim2.new(0, 10, 0, 4)
				TitleLabel.Size = UDim2.new(1, -40, 0, 22)
				TitleLabel.Font = Enum.Font.GothamBold
				TitleLabel.Text = Title
				TitleLabel.TextSize = 15.000
				TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
				TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
				TitleLabel.TextColor3 = getgenv().UIColor["GUI Text Color"]

				SubTextLabel.Name = "SubText"
				SubTextLabel.Parent = Topdrop
				SubTextLabel.BackgroundTransparency = 1.000
				SubTextLabel.Position = UDim2.new(0, 10, 0, 25)
				SubTextLabel.Size = UDim2.new(1, -40, 0, 18)
				SubTextLabel.Font = Enum.Font.Gotham
				SubTextLabel.Text = Placeholder
				SubTextLabel.TextSize = 13.000
				SubTextLabel.TextXAlignment = Enum.TextXAlignment.Left
				SubTextLabel.TextTruncate = Enum.TextTruncate.AtEnd
				SubTextLabel.TextColor3 = getgenv().UIColor["Placeholder Text Color"]

				ImgDrop.Name = "ImgDrop"
				ImgDrop.Parent = Topdrop
				ImgDrop.AnchorPoint = Vector2.new(1, 0.5)
				ImgDrop.BackgroundTransparency = 1.000
				ImgDrop.Position = UDim2.new(1, -8, 0, ClosedHeight / 2)
				ImgDrop.Size = UDim2.new(0, 15, 0, 15)
				ImgDrop.Image = "rbxassetid://6954383209"
				ImgDrop.ImageColor3 = getgenv().UIColor["Dropdown Icon Color"]

				DropdownButton.Name = "DropdownButton"
				DropdownButton.Parent = Topdrop
				DropdownButton.BackgroundTransparency = 1.000
				DropdownButton.Size = UDim2.new(1, 0, 1, 0)
				DropdownButton.Font = Enum.Font.SourceSans
				DropdownButton.Text = ""
				DropdownButton.TextSize = 14.000

				Dropdownlisttt.Name = "Dropdownlisttt"
				Dropdownlisttt.Parent = Dropdownbg
				Dropdownlisttt.BackgroundTransparency = 1.000
				Dropdownlisttt.BorderSizePixel = 0
				Dropdownlisttt.Position = UDim2.new(0, 0, 0, ClosedHeight)
				Dropdownlisttt.Size = UDim2.new(1, 0, 0, 0)

				ListSearch.Name = "ListSearch"
				ListSearch.Parent = Dropdownlisttt
				ListSearch.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
				ListSearch.BackgroundTransparency = 0.1
				ListSearch.BorderSizePixel = 0
				ListSearch.Position = UDim2.new(0, 5, 0, 5)
				ListSearch.Size = UDim2.new(1, -10, 0, 26)
				ListSearch.Font = Enum.Font.GothamBold
				ListSearch.PlaceholderText = "Search..."
				ListSearch.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
				ListSearch.Text = ""
				ListSearch.TextColor3 = getgenv().UIColor["Text Color"]
				ListSearch.TextSize = 13.000
				ListSearch.TextXAlignment = Enum.TextXAlignment.Left
				ListSearch.ClearTextOnFocus = false

				local ListSearchCorner = Instance.new("UICorner", ListSearch)
				ListSearchCorner.CornerRadius = UDim.new(0, 4)

				DropdownScroll.Name = "DropdownScroll"
				DropdownScroll.Parent = Dropdownlisttt
				DropdownScroll.Active = true
				DropdownScroll.BackgroundTransparency = 1.000
				DropdownScroll.BorderSizePixel = 0
				DropdownScroll.Position = UDim2.new(0, 0, 0, 36)
				DropdownScroll.Size = UDim2.new(1, 0, 1, -36)
				DropdownScroll.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
				DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
				DropdownScroll.ScrollBarThickness = 5
				DropdownScroll.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
				DropdownScroll.ScrollingEnabled = true
				DropdownScroll.VerticalScrollBarInset = Enum.ScrollBarInset.Always

				ScrollContainer.Name = "ScrollContainer"
				ScrollContainer.Parent = DropdownScroll
				ScrollContainer.BackgroundTransparency = 1.000
				ScrollContainer.Position = UDim2.new(0, 5, 0, 5)
				ScrollContainer.Size = UDim2.new(1, -15, 1, -5)

				ScrollContainerList.Name = "ScrollContainerList"
				ScrollContainerList.Parent = ScrollContainer
				ScrollContainerList.SortOrder = Enum.SortOrder.LayoutOrder
				ScrollContainerList.Padding = UDim.new(0, 5)
				ScrollContainerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 10 + ScrollContainerList.AbsoluteContentSize.Y + 5)
				end)

				local isbusy = false
				local CurrentValue = nil
				local MultiSelection = {}

				if Multi then
					for _, Name in ipairs(Default) do
						if table.find(List, Name) then
							MultiSelection[Name] = true
						end
					end
				else
					CurrentValue = Default
				end

				local dropdownFunction = {}

				local function GetSelectedText()
					if not Multi then
						return CurrentValue
					end
					local Chosen = {}
					for _, Name in ipairs(List) do
						if MultiSelection[Name] then
							table.insert(Chosen, Name)
						end
					end
					if #Chosen == 0 then
						return nil
					end
					return table.concat(Chosen, ", ")
				end

				local function RefreshSubText()
					local Selected = GetSelectedText()
					if Selected == nil or tostring(Selected) == "" then
						SubTextLabel.Text = Placeholder
						SubTextLabel.TextColor3 = getgenv().UIColor["Placeholder Text Color"]
						return
					end
					local Text = tostring(Selected)
					if Multi then
						local Count = 0
						for _, Name in ipairs(List) do
							if MultiSelection[Name] then
								Count = Count + 1
							end
						end
						if Count > 2 then
							Text = Count .. " selected"
						end
					end
					SubTextLabel.Text = Text
					SubTextLabel.TextColor3 = getgenv().UIColor["Text Color"]
				end

				local function ApplyFilter()
					local Query = string.lower(ListSearch.Text)
					for _, Item in ipairs(ScrollContainer:GetChildren()) do
						if Item:IsA("Frame") then
							Item.Visible = Query == "" or string.find(Item.Name, Query, 1, true) ~= nil
						end
					end
				end

				local function BuildItems()
					for _, Item in ipairs(ScrollContainer:GetChildren()) do
						if Item:IsA("Frame") then
							Item:Destroy()
						end
					end
					for Index, Value in ipairs(List) do
						local IsActive = Multi and MultiSelection[Value] or (not Multi and CurrentValue == Value)

						local Row = Instance.new("Frame")
						Row.Name = string.lower(tostring(Value))
						Row.Parent = ScrollContainer
						Row.BackgroundTransparency = 1.000
						Row.Size = UDim2.new(1, 0, 0, 25)
						Row.LayoutOrder = Index

						local RowBG = Instance.new("Frame")
						RowBG.Name = "SampleItemBG"
						RowBG.Parent = Row
						RowBG.AnchorPoint = Vector2.new(0.5, 0.5)
						RowBG.Position = UDim2.new(0.5, 0, 0.5, 0)
						RowBG.Size = UDim2.new(1, 0, 1, 0)
						RowBG.BorderSizePixel = 0
						RowBG.BackgroundColor3 = IsActive and getgenv().UIColor["Dropdown Selected Check Color"] or Color3.fromRGB(255, 255, 255)
						RowBG.BackgroundTransparency = IsActive and 0.5 or 1

						local RowBGCorner = Instance.new("UICorner", RowBG)
						RowBGCorner.CornerRadius = UDim.new(0, 4)

						local RowTitle = Instance.new("TextLabel")
						RowTitle.Name = "SampleItemTitle"
						RowTitle.Parent = RowBG
						RowTitle.BackgroundTransparency = 1.000
						RowTitle.Position = UDim2.new(0, 10, 0, 0)
						RowTitle.Size = UDim2.new(1, -40, 1, 0)
						RowTitle.Font = Enum.Font.GothamBold
						RowTitle.Text = tostring(Value)
						RowTitle.TextSize = 13.000
						RowTitle.TextXAlignment = Enum.TextXAlignment.Left
						RowTitle.TextTruncate = Enum.TextTruncate.AtEnd
						RowTitle.TextColor3 = IsActive and getgenv().UIColor["Dropdown Selected Text Color"] or getgenv().UIColor["Text Color"]

						local RowCheck = Instance.new("ImageLabel")
						RowCheck.Name = "SampleItemCheck"
						RowCheck.Parent = RowBG
						RowCheck.AnchorPoint = Vector2.new(1, 0.5)
						RowCheck.BackgroundTransparency = 1.000
						RowCheck.Position = UDim2.new(1, -6, 0.5, 0)
						RowCheck.Size = UDim2.new(0, 16, 0, 16)
						RowCheck.Image = "rbxassetid://3926305904"
						RowCheck.ImageColor3 = getgenv().UIColor["Dropdown Selected Check Color"]
						RowCheck.ImageRectOffset = Vector2.new(312, 4)
						RowCheck.ImageRectSize = Vector2.new(24, 24)
						RowCheck.ImageTransparency = IsActive and 0 or 1

						local RowButton = Instance.new("TextButton")
						RowButton.Name = "SampleItemButton"
						RowButton.Parent = Row
						RowButton.BackgroundTransparency = 1.000
						RowButton.Font = Enum.Font.SourceSans
						RowButton.Size = UDim2.new(1, 0, 1, 0)
						RowButton.Text = ""

						RowButton.MouseEnter:Connect(function()
							if IsActive then
								return
							end
							TweenService:Create(RowBG, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
								BackgroundColor3 = Color3.fromRGB(255, 255, 255),
								BackgroundTransparency = 0.7
							}):Play()
						end)

						RowButton.MouseLeave:Connect(function()
							if IsActive then
								return
							end
							TweenService:Create(RowBG, TweenInfo.new(getgenv().UIColor["Tween Animation 1 Speed"]), {
								BackgroundTransparency = 1
							}):Play()
						end)

						RowButton.MouseButton1Click:Connect(function()
							if Multi then
								MultiSelection[Value] = not MultiSelection[Value]
								if Callback then
									Callback(Value, MultiSelection[Value])
								end
							else
								if CurrentValue == Value then
									return
								end
								CurrentValue = Value
								if Callback then
									Callback(Value)
								end
							end
							RefreshSubText()
							BuildItems()
							if not Multi then
								dropdownFunction:SetOpen(false)
							end
						end)
					end
					ApplyFilter()
				end

				function dropdownFunction:rf()
					BuildItems()
				end

				function dropdownFunction:SetOpen(state)
					state = state and true or false
					if state == isbusy then
						return
					end
					isbusy = state
					if isbusy then
						BuildItems()
						local Limit = math.huge
						local Node = DropdownFrame.Parent
						while Node and Node ~= game do
							if Node:IsA("GuiObject") and Node.ClipsDescendants then
								Limit = Node.AbsolutePosition.Y + Node.AbsoluteSize.Y
								break
							end
							Node = Node.Parent
						end
						local Space = Limit - (DropdownFrame.AbsolutePosition.Y + ClosedHeight) - 10
						if Space == Space and Space > 0 then
							ListHeight = math.clamp(Space, 86, 180)
						end
					end
					TweenService:Create(Dropdownlisttt, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
						Size = isbusy and UDim2.new(1, 0, 0, ListHeight) or UDim2.new(1, 0, 0, 0)
					}):Play()
					TweenService:Create(DropdownFrame, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
						Size = isbusy and UDim2.new(1, 0, 0, ClosedHeight + ListHeight) or UDim2.new(1, 0, 0, ClosedHeight)
					}):Play()
					TweenService:Create(ImgDrop, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
						Rotation = isbusy and 90 or 0
					}):Play()
					if not isbusy then
						ListSearch.Text = ""
					end
				end

				function dropdownFunction:GetOpen()
					return isbusy
				end

				function dropdownFunction:SetValue(Value, State)
					if Multi then
						if table.find(List, Value) == nil then
							return
						end
						if State == false then
							MultiSelection[Value] = nil
						else
							MultiSelection[Value] = true
						end
						if Callback then
							Callback(Value, MultiSelection[Value] == true)
						end
					else
						CurrentValue = Value
						if Callback then
							Callback(Value)
						end
					end
					RefreshSubText()
					BuildItems()
				end

				function dropdownFunction:GetValue()
					if not Multi then
						return CurrentValue
					end
					local Result = {}
					for _, Name in ipairs(List) do
						if MultiSelection[Name] then
							table.insert(Result, Name)
						end
					end
					return Result
				end

				function dropdownFunction:Clear()
					if Multi then
						for Name in pairs(MultiSelection) do
							MultiSelection[Name] = nil
						end
					else
						CurrentValue = nil
					end
					RefreshSubText()
					BuildItems()
				end

				function dropdownFunction:ClearText(Value)
					if Value == nil then
						RefreshSubText()
						return
					end
					SubTextLabel.Text = tostring(Value)
				end

				function dropdownFunction:GetNewList(NewList)
					List = NewList or {}
					CurrentValue = nil
					MultiSelection = {}
					RefreshSubText()
					BuildItems()
				end

				DropdownButton.MouseButton1Click:Connect(function()
					dropdownFunction:SetOpen(not isbusy)
				end)

				ListSearch:GetPropertyChangedSignal("Text"):Connect(ApplyFilter)

				RefreshSubText()
				BuildItems()

				local controlData = {
					Name = Title,
					Section = Section,
					Element = DropdownFrame,
					SectionName = Section_Name,
					TabName = Page_Name,
					TabButton = PageName,
					SetValue = dropdownFunction.SetValue,
					GetValue = dropdownFunction.GetValue
				}
				table.insert(getgenv().AllControls, controlData)

				return dropdownFunction
			end

function sectionFunction:AddKeyBind(Setting, Callback)
    local TitleText = tostring(Setting.Title or Setting.Text) or ""
    local Default = Setting.Default or Setting.Key or "F"
    local Mode = Setting.Mode or "Toggle"
    local Callback = Setting.Callback or Callback or function() end
    
    local function GetKeyString(key)
        local keyStr = tostring(key)
        keyStr = keyStr:gsub("Enum.UserInputType.", "")
        keyStr = keyStr:gsub("Enum.KeyCode.", "")
        return keyStr
    end
    
    local CurrentKey = GetKeyString(Default)
    local CurrentMode = Mode
    local Picking = false
    local ToggleState = false
    local HoldActive = false
    
    local BindFrame = Instance.new("Frame")
    local BindCorner = Instance.new("UICorner")
    local BindBG = Instance.new("Frame")
    local ButtonCorner = Instance.new("UICorner")
    local BindButtonTitle = Instance.new("TextLabel")
    local BindCor = Instance.new("Frame")
    local ButtonCorner_2 = Instance.new("UICorner")
    local Bindkey = Instance.new("TextButton")
    
    BindFrame.Name = TitleText .. "bguvl"
    BindFrame.Parent = Section
    BindFrame.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
    BindFrame.BackgroundTransparency = 1.000
    BindFrame.Position = UDim2.new(0, 0, 0.208333328, 0)
    BindFrame.Size = UDim2.new(1, 0, 0, 35)
    
    BindCorner.CornerRadius = UDim.new(0, 4)
    BindCorner.Name = "BindCorner"
    BindCorner.Parent = BindFrame
    
    BindBG.Name = "Background1"
    BindBG.Parent = BindFrame
    BindBG.AnchorPoint = Vector2.new(0.5, 0.5)
    BindBG.Position = UDim2.new(0.5, 0, 0.5, 0)
    BindBG.Size = UDim2.new(1, -10, 1, 0)
    BindBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
    BindBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
    
    ButtonCorner.CornerRadius = UDim.new(0, 4)
    ButtonCorner.Name = "ButtonCorner"
    ButtonCorner.Parent = BindBG
    
    BindButtonTitle.Name = "TextColor"
    BindButtonTitle.Parent = BindBG
    BindButtonTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    BindButtonTitle.BackgroundTransparency = 1.000
    BindButtonTitle.Position = UDim2.new(0, 10, 0, 0)
    BindButtonTitle.Size = UDim2.new(1, -10, 1, 0)
    BindButtonTitle.Font = Enum.Font.GothamBlack
    BindButtonTitle.Text = TitleText
    BindButtonTitle.TextSize = 14.000
    BindButtonTitle.TextXAlignment = Enum.TextXAlignment.Left
    BindButtonTitle.TextColor3 = getgenv().UIColor["Text Color"]
    
    BindCor.Name = "Background2"
    BindCor.Parent = BindBG
    BindCor.AnchorPoint = Vector2.new(1, 0.5)
    BindCor.Position = UDim2.new(1, -5, 0.5, 0)
    BindCor.Size = UDim2.new(0, 150, 0, 25)
    BindCor.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
    
    ButtonCorner_2.CornerRadius = UDim.new(0, 4)
    ButtonCorner_2.Name = "ButtonCorner"
    ButtonCorner_2.Parent = BindCor
    
    Bindkey.Name = "Bindkey"
    Bindkey.Parent = BindCor
    Bindkey.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    Bindkey.BackgroundTransparency = 1.000
    Bindkey.Size = UDim2.new(1, 0, 1, 0)
    Bindkey.Font = Enum.Font.GothamBold
    Bindkey.Text = CurrentKey
    Bindkey.TextSize = 14.000
    Bindkey.TextColor3 = getgenv().UIColor["Text Color"]
    
    -- Change Key
    Bindkey.MouseButton1Click:Connect(function()
        if Picking then return end
        
        Picking = true
        Bindkey.Text = "..."
        
        TaskWait(0.2)
        
        local Connection
        Connection = uis.InputBegan:Connect(function(input)
            if Picking then
                local Key
                
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    Key = input.KeyCode.Name
                elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                    Key = "MouseLeft"
                elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                    Key = "MouseRight"
                end
                
                if Key then
                    Picking = false
                    CurrentKey = Key
                    Bindkey.Text = Key
                    Connection:Disconnect()
                end
            end
        end)
    end)
    
    -- Input Began (Press)
    uis.InputBegan:Connect(function(input, gpe)
        if gpe or Picking then return end
        if uis:GetFocusedTextBox() then return end
        
        local pressedKey
        if input.UserInputType == Enum.UserInputType.Keyboard then
            pressedKey = input.KeyCode.Name
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressedKey = "MouseLeft"
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            pressedKey = "MouseRight"
        end
        
        if pressedKey == CurrentKey then
            if CurrentMode == "Toggle" then
                ToggleState = not ToggleState
                pcall(Callback, ToggleState)
            elseif CurrentMode == "Hold" then
                HoldActive = true
                pcall(Callback, true)
            end
        end
    end)
    
    -- Input Ended (Release) - Only for Hold mode
    uis.InputEnded:Connect(function(input)
        if Picking then return end
        if uis:GetFocusedTextBox() then return end
        
        local releasedKey
        if input.UserInputType == Enum.UserInputType.Keyboard then
            releasedKey = input.KeyCode.Name
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            releasedKey = "MouseLeft"
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            releasedKey = "MouseRight"
        end
        
        if releasedKey == CurrentKey and CurrentMode == "Hold" and HoldActive then
            HoldActive = false
            pcall(Callback, false)
        end
    end)
    
    local controlData = {
        Name = TitleText,
        Section = Section,
        Element = BindFrame,
        SectionName = Section_Name,
        TabName = Page_Name,
        TabButton = PageName
    }
    table.insert(getgenv().AllControls, controlData)
    
    local keybindFunction = {}
    
    function keybindFunction:Set(newKey)
        CurrentKey = GetKeyString(newKey)
        Bindkey.Text = CurrentKey
    end
    
    function keybindFunction:Get()
        return CurrentKey
    end
    
    function keybindFunction:SetMode(mode)
        if mode == "Hold" or mode == "Toggle" then
            CurrentMode = mode
            ToggleState = false
            HoldActive = false
        end
    end
    
    function keybindFunction:GetMode()
        return CurrentMode
    end
    
    function keybindFunction:GetState()
        if CurrentMode == "Toggle" then
            return ToggleState
        elseif CurrentMode == "Hold" then
            return HoldActive
        end
        return false
    end
    
    return keybindFunction
end
			function sectionFunction:AddInput(idk, Setting)
				local TitleText = tostring(Setting.Text or Setting.Title) or ""
				local Placeholder = tostring(Setting.Placeholder) or ""
				local Default = Setting.Default or false
				local Number_Only = Setting.Numeric or false
				local Callback = Setting.Callback
				local BoxFrame = Instance.new("Frame")
				local BoxCorner = Instance.new("UICorner")
				local BoxBG = Instance.new("Frame")
				local ButtonCorner = Instance.new("UICorner")
				local Boxtitle = Instance.new("TextLabel")
				local BoxCor = Instance.new("Frame")
				local ButtonCorner_2 = Instance.new("UICorner")
				local Boxxx = Instance.new("TextBox")
				local Lineeeee = Instance.new("Frame")
				local UICorner = Instance.new("UICorner")
				BoxFrame.Name = "BoxFrame"
				BoxFrame.Parent = Section
				BoxFrame.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
				BoxFrame.BackgroundTransparency = 1.000
				BoxFrame.Position = UDim2.new(0, 0, 0.208333328, 0)
				BoxFrame.Size = UDim2.new(1, 0, 0, 60)
				BoxCorner.CornerRadius = UDim.new(0, 4)
				BoxCorner.Name = "BoxCorner"
				BoxCorner.Parent = BoxFrame
				BoxBG.Name = "Background1"
				BoxBG.Parent = BoxFrame
				BoxBG.AnchorPoint = Vector2.new(0.5, 0.5)
				BoxBG.Position = UDim2.new(0.5, 0, 0.5, 0)
				BoxBG.Size = UDim2.new(1, -10, 1, 0)
				BoxBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
				BoxBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
				ButtonCorner.CornerRadius = UDim.new(0, 4)
				ButtonCorner.Name = "ButtonCorner"
				ButtonCorner.Parent = BoxBG
				Boxtitle.Name = "TextColor"
				Boxtitle.Parent = BoxBG
				Boxtitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
				Boxtitle.BackgroundTransparency = 1.000
				Boxtitle.Position = UDim2.new(0, 10, 0, 0)
				Boxtitle.Size = UDim2.new(1, -10, 0.5, 0)
				Boxtitle.Font = Enum.Font.GothamBlack
				Boxtitle.Text = TitleText
				Boxtitle.TextSize = 14.000
				Boxtitle.TextXAlignment = Enum.TextXAlignment.Left
				Boxtitle.TextColor3 = getgenv().UIColor["Text Color"]
				BoxCor.Name = "Background2"
				BoxCor.Parent = BoxBG
				BoxCor.AnchorPoint = Vector2.new(1, 0.5)
				BoxCor.ClipsDescendants = true
				BoxCor.Position = UDim2.new(1, -5, 0, 40)
				BoxCor.Size = UDim2.new(1, -10, 0, 25)
				BoxCor.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
				ButtonCorner_2.CornerRadius = UDim.new(0, 4)
				ButtonCorner_2.Name = "ButtonCorner"
				ButtonCorner_2.Parent = BoxCor
				Boxxx.Name = "TextColorPlaceholder"
				Boxxx.Parent = BoxCor
				Boxxx.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
				Boxxx.BackgroundTransparency = 1.000
				Boxxx.Position = UDim2.new(0, 5, 0, 0)
				Boxxx.Size = UDim2.new(1, -5, 1, 0)
				Boxxx.Font = Enum.Font.GothamBold
				Boxxx.PlaceholderText = Placeholder
				Boxxx.Text = ""
				Boxxx.TextSize = 14.000
				Boxxx.TextXAlignment = Enum.TextXAlignment.Left
				Boxxx.PlaceholderColor3 = getgenv().UIColor["Placeholder Text Color"]
				Boxxx.TextColor3 = getgenv().UIColor["Text Color"]
				Lineeeee.Name = "TextNSBoxLineeeee"
				Lineeeee.Parent = BoxCor
				Lineeeee.BackgroundTransparency = 1.000
				Lineeeee.Position = UDim2.new(0, 0, 1, -2)
				Lineeeee.Size = UDim2.new(1, 0, 0, 6)
				Lineeeee.BackgroundColor3 = getgenv().UIColor["Box Highlight Color"]
				UICorner.CornerRadius = UDim.new(1, 0)
				UICorner.Parent = Lineeeee
				Boxxx.Focused:Connect(function()
					TweenService:Create(Lineeeee, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
						BackgroundTransparency = 0
					}):Play()
				end)
				if Number_Only then
					Boxxx:GetPropertyChangedSignal("Text"):Connect(function()
						if tonumber(Boxxx.Text) then
						else
							Boxxx.PlaceholderText = Placeholder
							Boxxx.Text = ''
						end
					end)
				end
				Boxxx.FocusLost:Connect(function()
					TweenService:Create(Lineeeee, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
						BackgroundTransparency = 1
					}):Play()
					if Boxxx.Text ~= '' then
						Callback(Boxxx.Text)
					end
				end)
				local textbox_function = {}
				if Default then
					Boxxx.Text = Default
				end
				function textbox_function.SetValue(Value)
					Boxxx.Text = Value
					Callback(Value)
				end
				local controlData = {
                    Name = TitleText,
                    Section = Section,
                    Element = BoxFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageName
                }
                table.insert(getgenv().AllControls, controlData)
                
				return textbox_function;
			end
			function sectionFunction:AddSlider(Id, Setting)
				if type(Id) == "table" then
				    Setting = Id
				end
				local TitleText = tostring(Setting.Text or Setting.Title) or ""
				local minValue = tonumber(Setting.Min) or 0
				local maxValue = tonumber(Setting.Max) or 100
				local Precise = Setting.Precise or false
				local Rounding = Setting.Rouding or Setting.Rounding
				local DefaultValue = tonumber(Setting.Default) or 0
				local Callback = Setting.Callback
				local SizeChia = 400;
				local SliderFrame = Instance.new("Frame")
				local SliderCorner = Instance.new("UICorner")
				local SliderBG = Instance.new("Frame")
				local SliderBGCorner = Instance.new("UICorner")
				local SliderTitle = Instance.new("TextLabel")
				local SliderBar = Instance.new("Frame")
				local SliderButton = Instance.new("TextButton")
				local SliderBarCorner = Instance.new("UICorner")
				local Bar = Instance.new("Frame")
				local BarCorner = Instance.new("UICorner")
				local Sliderboxframe = Instance.new("Frame")
				local Sliderbox = Instance.new("UICorner")
				local Sliderbox_2 = Instance.new("TextBox")
				SliderFrame.Name = TitleText .. 'buda'
				SliderFrame.Parent = Section
				SliderFrame.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
				SliderFrame.BackgroundTransparency = 1.000
				SliderFrame.Position = UDim2.new(0, 0, 0.208333328, 0)
				SliderFrame.Size = UDim2.new(1, 0, 0, 50)
				SliderCorner.CornerRadius = UDim.new(0, 4)
				SliderCorner.Name = "SliderCorner"
				SliderCorner.Parent = SliderFrame
				SliderBG.Name = "Background1"
				SliderBG.Parent = SliderFrame
				SliderBG.AnchorPoint = Vector2.new(0.5, 0.5)
				SliderBG.Position = UDim2.new(0.5, 0, 0.5, 0)
				SliderBG.Size = UDim2.new(1, -10, 1, 0)
				SliderBG.BackgroundColor3 = getgenv().UIColor["Background 1 Color"]
				SliderBG.BackgroundTransparency = getgenv().UIColor["Background 1 Transparency"]
				SliderBGCorner.CornerRadius = UDim.new(0, 4)
				SliderBGCorner.Name = "SliderBGCorner"
				SliderBGCorner.Parent = SliderBG
				SliderTitle.Name = "TextColor"
				SliderTitle.Parent = SliderBG
				SliderTitle.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
				SliderTitle.BackgroundTransparency = 1.000
				SliderTitle.Position = UDim2.new(0, 10, 0, 0)
				SliderTitle.Size = UDim2.new(1, -10, 0, 25)
				SliderTitle.Font = Enum.Font.GothamBlack
				SliderTitle.Text = TitleText
				SliderTitle.TextSize = 14.000
				SliderTitle.RichText = true
				SliderTitle.TextXAlignment = Enum.TextXAlignment.Left
				SliderTitle.TextColor3 = getgenv().UIColor["Text Color"]
				SliderBar.Name = "SliderBar"
				SliderBar.Parent = SliderFrame
				SliderBar.AnchorPoint = Vector2.new(.5, 0.5)
				SliderBar.Position = UDim2.new(.5, 0, 0.5, 14)
				SliderBar.Size = UDim2.new(1, -20, 0, 6)
				SliderBar.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
				SliderButton.Name = "SliderButton "
				SliderButton.Parent = SliderBar
				SliderButton.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
				SliderButton.BackgroundTransparency = 1.000
				SliderButton.Size = UDim2.new(1, 0, 1, 0)
				SliderButton.Font = Enum.Font.GothamBold
				SliderButton.Text = ""
				SliderButton.TextColor3 = Color3.fromRGB(230, 230, 230)
				SliderButton.TextSize = 14.000
				SliderBarCorner.CornerRadius = UDim.new(1, 0)
				SliderBarCorner.Name = "SliderBarCorner"
				SliderBarCorner.Parent = SliderBar
				Bar.Name = "Bar"
				Bar.BorderSizePixel = 0
				Bar.Parent = SliderBar
				Bar.Size = UDim2.new(0, 0, 1, 0)
				Bar.BackgroundColor3 = getgenv().UIColor["Slider Line Color"]
				BarCorner.CornerRadius = UDim.new(1, 0)
				BarCorner.Name = "BarCorner"
				BarCorner.Parent = Bar
				Sliderboxframe.Name = "Background2"
				Sliderboxframe.Parent = SliderFrame
				Sliderboxframe.AnchorPoint = Vector2.new(1, 0)
				Sliderboxframe.Position = UDim2.new(1, -10, 0, 5)
				Sliderboxframe.Size = UDim2.new(0, 150, 0, 25)
				Sliderboxframe.BackgroundColor3 = getgenv().UIColor["Background 2 Color"]
				Sliderbox.CornerRadius = UDim.new(0, 4)
				Sliderbox.Name = "Sliderbox"
				Sliderbox.Parent = Sliderboxframe
				Sliderbox_2.Name = "TextColor"
				Sliderbox_2.Parent = Sliderboxframe
				Sliderbox_2.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
				Sliderbox_2.BackgroundTransparency = 1.000
				Sliderbox_2.Size = UDim2.new(1, 0, 1, 0)
				Sliderbox_2.Font = Enum.Font.GothamBold
				Sliderbox_2.Text = ""
				Sliderbox_2.TextSize = 14.000
				Sliderbox_2.TextColor3 = getgenv().UIColor["Text Color"]
				SliderButton.MouseEnter:Connect(function()
					TweenService:Create(Bar, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
						BackgroundColor3 = getgenv().UIColor["Slider Highlight Color"]
					}):Play()
				end)
				SliderButton.MouseLeave:Connect(function()
					TweenService:Create(Bar, TweenInfo.new(getgenv().UIColor["Tween Animation 2 Speed"]), {
						BackgroundColor3 = getgenv().UIColor["Slider Line Color"]
					}):Play()
				end)
				local callBackAndSetText = function(val)
					Sliderbox_2.Text = tostring(val)
					Callback(tonumber(val))
				end
				if DefaultValue then
					if DefaultValue <= minValue then
						DefaultValue = minValue
					elseif DefaultValue >= maxValue then
						DefaultValue = maxValue
					end
					Sliderbox_2.Text = tostring(DefaultValue)
					Bar.Size = UDim2.new(1 - ((maxValue - DefaultValue) / (maxValue - minValue)), 0, 0, 6)
				end
				local dragging = false
				local dragInput
				local holdTime = 0 -- Time to hold before dragging is enabled
				local holdStarted = 0

						-- Function to detect the start of dragging (for both mouse and touch)
				local function onInputBegan(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						holdStarted = Now() -- Record the time when holding starts
						
								-- Listen for release to stop dragging
						input.Changed:Connect(function()
							if input.UserInputState == Enum.UserInputState.End then
								dragging = false
								holdStarted = 0 -- Reset the hold timer
							end
						end)
					end
				end
						
						-- Function to detect when dragging stops
				local function onInputEnded(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = false
						holdStarted = 0 -- Reset the hold timer
					end
				end

						-- Detect input movement (for both mouse and touch)
				local function onInputChanged(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						dragInput = input
					end
				end
						
						-- Connect the events
				SliderButton.InputBegan:Connect(onInputBegan)
				SliderButton.InputEnded:Connect(onInputEnded)
				SliderButton.InputChanged:Connect(onInputChanged)
						
						-- RenderStepped updates the position while dragging
				RunService.RenderStepped:Connect(function()
					if holdStarted > 0 and (Now() - holdStarted >= holdTime) and not dragging then
						dragging = true
					end
					if dragging and dragInput then
						local BarWidth = math.max(SliderBar.AbsoluteSize.X, 1)
						local Percent = math.clamp((dragInput.Position.X - SliderBar.AbsolutePosition.X) / BarWidth, 0, 1)
						local value = minValue + (maxValue - minValue) * Percent
						if Rounding then
							value = tonumber(string.format("%." .. Rounding .. "f", value))
						elseif not Precise then
							value = math.floor(value)
						end
						value = math.clamp(value, minValue, maxValue)
						Bar.Size = UDim2.new(Percent, 0, 1, 0)
						pcall(function()
							callBackAndSetText(value)
						end)
					end
				end)
				local function GetSliderValue(Value)
					Value = math.clamp(tonumber(Value) or minValue, minValue, maxValue)
					if Rounding then
						Value = tonumber(string.format("%." .. Rounding .. "f", Value))
					elseif not Precise then
						Value = math.floor(Value)
					end
					local Percent = (maxValue > minValue) and ((Value - minValue) / (maxValue - minValue)) or 0
					Bar.Size = UDim2.new(Percent, 0, 1, 0)
					callBackAndSetText(Value)
				end
				Sliderbox_2.FocusLost:Connect(function()
					GetSliderValue(Sliderbox_2.Text)
				end)
				local slider_function = {}
				function slider_function.SetValue(Value)
					GetSliderValue(Value)
				end
				local controlData = {
                    Name = TitleText,
                    Section = Section,
                    Element = SliderFrame,
                    SectionName = Section_Name,
                    TabName = Page_Name,
                    TabButton = PageName
                }
                table.insert(getgenv().AllControls, controlData)
                
				return slider_function
			end
			return sectionFunction
		end
        local pagefunc = {}
        function pagefunc:AddLeftGroupbox(name, Toggleable)
            return pageFunction:AddSection(name, Toggleable ~= false)
        end
        function pagefunc:AddRightGroupbox(name, Toggleable)
            return pageFunction:AddSection(name, Toggleable ~= false)
        end
		return pagefunc
        end

	return Main_Function
end


return Library
