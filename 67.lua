repeat task.wait() until game:IsLoaded()

-- Очистка мусора от предыдущих сессий
if type(clearteleportqueue) == "function" then
    pcall(clearteleportqueue)
elseif type(clearteleport_queue) == "function" then
    pcall(clearteleport_queue)
end

-- Предотвращение повторного запуска
if getgenv().NezurHubLoaded then
    print("[Nezur] Already loaded, skipping...")
    return
end
getgenv().NezurHubLoaded = true

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Удаление старых GUI если они остались
local oldGui = playerGui:FindFirstChild("NezurHub")
if oldGui then oldGui:Destroy() end
local oldNotif = playerGui:FindFirstChild("NezurNotifications")
if oldNotif then oldNotif:Destroy() end


local GuiService = game:GetService("GuiService")
local VIM = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Mouse = player:GetMouse()

-- ==========================================
-- AUTO EXECUTE CORE (URL-based)
-- Compatible: Potassium, Volt, Fluxus, Synapse X
-- ==========================================
local SCRIPT_URL = "https://raw.githubusercontent.com/kresteq/bridgerAnticheatSUCKS/refs/heads/main/67.lua"

local ConfigFolder = "Nezur"

-- Утилита: ставим queue_on_teleport с HttpGet-загрузкой
local function SetupAutoExec()
    local loaderTemplate = [[
repeat task.wait() until game:IsLoaded()
task.wait(1.5)
local ok, src = pcall(function()
    return game:HttpGet("%s")
end)
if ok and src and #src > 100 then
    loadstring(src)()
else
    warn("[Nezur] AutoExec failed: could not fetch script from URL")
end
]]

    local loader = string.format(loaderTemplate, SCRIPT_URL)

    if type(queue_on_teleport) == "function" then
        pcall(queue_on_teleport, loader)
    elseif type(queueonteleport) == "function" then
        pcall(queueonteleport, loader)
    end
end

if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

-- ==========================================
-- CONFIG SYSTEM
-- ==========================================
local CurrentConfigName = "default"

local function SaveCfg(name, t)
    if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
    local path = ConfigFolder.."/"..name..".json"
    return pcall(function() writefile(path, HttpService:JSONEncode(t)) end)
end

local function LoadCfg(name)
    local path = ConfigFolder.."/"..name..".json"
    if isfile(path) then
        local s,r = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if s and type(r)=="table" then return r end
    end
    return nil
end

local function GetConfigList()
    local list = {}
    if isfolder(ConfigFolder) then
        for _, file in ipairs(listfiles(ConfigFolder)) do
            local name = file:match("([^/\\]+)%.json$")
            if name and name ~= "NotSameServers" and name ~= "autoexec" then
                table.insert(list, name)
            end
        end
    end
    return list
end

-- ==========================================
-- AUTO EQUIP RANDOM TOOL
-- ==========================================
local function AutoEquipRandom()
    task.wait(3)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local bp = player:FindFirstChild("Backpack")
    if not bp then return end
    
    local tools = {}
    for _, item in ipairs(bp:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(tools, item)
        end
    end
    
    if #tools > 0 then
        local tool = tools[math.random(1, #tools)]
        pcall(function()
            hum:EquipTool(tool)
        end)
    end
end

-- Подписываемся на респавн
player.CharacterAdded:Connect(function()
    task.spawn(AutoEquipRandom)
end)

-- ==========================================
-- AUTO PLAY
-- ==========================================
local function PressPlayButton()
    local mainMenu = playerGui:FindFirstChild("MainMenu")
    if not mainMenu then return false end
    local bc = mainMenu:FindFirstChild("ButtonContainer")
    if not bc then return false end
    local pb = bc:FindFirstChild("PlayButton")
    if not pb then return false end
    GuiService.SelectedObject = pb
    task.wait(0.2)
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
    end)
    return true
end

while true do
    if Workspace.Entities:FindFirstChild(player.Name) then break end
    if PressPlayButton() then
        task.delay(0.5, function()
            GuiService.SelectedObject = nil
        end)
    end
    task.wait(3)
end

-- После успешного входа экипируем предмет
task.spawn(AutoEquipRandom)

-- ==========================================
-- NOTIFICATIONS
-- ==========================================
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "NezurNotifications"
NotifGui.ResetOnSpawn = false
NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
NotifGui.DisplayOrder = 100
NotifGui.Parent = playerGui
local NotifContainer = Instance.new("Frame")
NotifContainer.Size = UDim2.new(0, 280, 1, -20)
NotifContainer.Position = UDim2.new(1, -290, 0, 10)
NotifContainer.BackgroundTransparency = 1
NotifContainer.Parent = NotifGui
local NotifLayout = Instance.new("UIListLayout")
NotifLayout.Padding = UDim.new(0, 6)
NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.Parent = NotifContainer

local function Notify(text, dur)
    dur = dur or 3
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 36)
    f.BackgroundColor3 = Color3.fromRGB(22,22,29)
    f.BorderSizePixel = 0
    f.BackgroundTransparency = 1
    f.Parent = NotifContainer
    local c = Instance.new("UICorner", f)
    c.CornerRadius = UDim.new(0,6)
    local s = Instance.new("UIStroke", f)
    s.Color = Color3.fromRGB(139,123,184)
    s.Thickness = 1
    s.Transparency = 1
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1,-12,1,0)
    l.Position = UDim2.new(0,12,0,0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(192,192,192)
    l.TextSize = 12
    l.Font = Enum.Font.GothamMedium
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextTransparency = 1
    TweenService:Create(f,TweenInfo.new(0.3),{BackgroundTransparency=0}):Play()
    TweenService:Create(s,TweenInfo.new(0.3),{Transparency=0.4}):Play()
    TweenService:Create(l,TweenInfo.new(0.3),{TextTransparency=0}):Play()
    task.delay(dur, function()
        TweenService:Create(f,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
        TweenService:Create(s,TweenInfo.new(0.3),{Transparency=1}):Play()
        TweenService:Create(l,TweenInfo.new(0.3),{TextTransparency=1}):Play()
        task.wait(0.3)
        f:Destroy()
    end)
end

-- ==========================================
-- GUI FRAMEWORK
-- ==========================================
-- Дополнительная защита от дублирования GUI
for _, child in ipairs(playerGui:GetChildren()) do
    if child.Name == "NezurHub" or child.Name == "NezurNotifications" then
        child:Destroy()
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NezurHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0,400,0,520)
MainFrame.Position = UDim2.new(0.5,-200,0.5,-260)
MainFrame.BackgroundColor3 = Color3.fromRGB(22,22,29)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = false
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner",MainFrame).CornerRadius = UDim.new(0,8)
local MStroke = Instance.new("UIStroke",MainFrame)
MStroke.Color = Color3.fromRGB(42,42,53)
MStroke.Thickness = 1

-- Custom Drag (only TitleBar)
local Dragging = false
local DragStart = nil
local StartPos = nil

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1,0,0,35)
TitleBar.BackgroundColor3 = Color3.fromRGB(30,30,40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
Instance.new("UICorner",TitleBar).CornerRadius = UDim.new(0,8)
local tf = Instance.new("Frame",TitleBar)
tf.Size = UDim2.new(1,0,0,10)
tf.Position = UDim2.new(0,0,1,-10)
tf.BackgroundColor3 = Color3.fromRGB(30,30,40)
tf.BorderSizePixel = 0

local TitleText = Instance.new("TextLabel",TitleBar)
TitleText.Size = UDim2.new(1,-15,1,0)
TitleText.Position = UDim2.new(0,15,0,0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "▼ Nezur"
TitleText.TextColor3 = Color3.fromRGB(192,192,192)
TitleText.TextSize = 14
TitleText.Font = Enum.Font.GothamSemibold
TitleText.TextXAlignment = Enum.TextXAlignment.Left

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true
        DragStart = input.Position
        StartPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - DragStart
        MainFrame.Position = UDim2.new(
            StartPos.X.Scale, StartPos.X.Offset + delta.X,
            StartPos.Y.Scale, StartPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = false
    end
end)

-- Tabs
local TabsFrame = Instance.new("Frame")
TabsFrame.Size = UDim2.new(1,0,0,32)
TabsFrame.Position = UDim2.new(0,0,0,35)
TabsFrame.BackgroundColor3 = Color3.fromRGB(30,30,40)
TabsFrame.BorderSizePixel = 0
TabsFrame.Parent = MainFrame
local tf2 = Instance.new("Frame",TabsFrame)
tf2.Size = UDim2.new(1,0,0,10)
tf2.Position = UDim2.new(0,0,1,-10)
tf2.BackgroundColor3 = Color3.fromRGB(30,30,40)
tf2.BorderSizePixel = 0

local TabNames = {"Auto Farms","ESP","Movement","Misc","Server","Settings"}
local TabButtons = {}
local TabContents = {}
local ActiveTab = "Auto Farms"

for i,name in ipairs(TabNames) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/6,-2,1,0)
    btn.Position = UDim2.new((1/6)*(i-1),1,0,0)
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.TextColor3 = name=="Auto Farms" and Color3.fromRGB(184,168,216) or Color3.fromRGB(139,139,154)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamMedium
    btn.Parent = TabsFrame
    local line = Instance.new("Frame",btn)
    line.Size = UDim2.new(0.8,0,0,2)
    line.Position = UDim2.new(0.1,0,1,-2)
    line.BackgroundColor3 = Color3.fromRGB(139,123,184)
    line.BorderSizePixel = 0
    line.Visible = name=="Auto Farms"
    TabButtons[name] = {Button=btn,Line=line}
    
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1,-30,1,-85)
    content.Position = UDim2.new(0,15,0,75)
    content.BackgroundTransparency = 1
    content.Visible = name=="Auto Farms"
    content.Parent = MainFrame
    content.ScrollBarThickness = 4
    content.ScrollingDirection = Enum.ScrollingDirection.Y
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.CanvasSize = UDim2.new(0,0,0,0)
    TabContents[name] = content
    
    btn.MouseButton1Click:Connect(function()
        for n,t in pairs(TabButtons) do
            t.Button.TextColor3 = Color3.fromRGB(139,139,154)
            t.Line.Visible = false
            TabContents[n].Visible = false
        end
        btn.TextColor3 = Color3.fromRGB(184,168,216)
        line.Visible = true
        content.Visible = true
        ActiveTab = name
        local ts = UDim2.new(0,400,0,520)
        if name=="ESP" then ts = UDim2.new(0,400,0,360)
        elseif name=="Movement" then ts = UDim2.new(0,400,0,520)
        elseif name=="Misc" then ts = UDim2.new(0,400,0,420)
        elseif name=="Server" then ts = UDim2.new(0,400,0,460)
        elseif name=="Settings" then ts = UDim2.new(0,400,0,560) end
        TweenService:Create(MainFrame,TweenInfo.new(0.3),{Size=ts}):Play()
    end)
end

-- ==========================================
-- FEATURES & CONFIG
-- ==========================================
local Features = {
    Corpse={E=false,C=nil}, Bank={E=false,C=nil}, Chest={E=false,C=nil},
    SaintScanner={E=false,C=nil}, ESP={E=false,C=nil,PlayerAdded=nil,PlayerRemoving=nil},
    ClickTp={E=false,C=nil}, Fly={E=false,C=nil,KC=nil},
    RaknetDesync={E=false,C=nil}, HideName={E=false,C=nil}
}
local SHC = {MinPlayers=1, MaxPlayers=25}
local GuiKeybind = Enum.KeyCode.F1
local FlyKeybind = Enum.KeyCode.E
local FlySpeed = 24
local IsListening = false
local IsFlyListening = false
local IsGuiHidden = false

local ScannerData = {DP=nil,DPos=nil,Scan=false}
local saintsPartNames = {"SaintsLeftArm","SaintsRightArm","SaintsLeftLeg","SaintsRightLeg","SaintsRibcage"}
local SAINT_COORDS = {
    Vector3.new(-4114,65,-4982),Vector3.new(-3803,243,-6001),
    Vector3.new(-7982,59,-3252),Vector3.new(-4496,45,-2004),
    Vector3.new(-4183,46,-3999),Vector3.new(-5511,54,-4653),
    Vector3.new(-4016,45,-2764),Vector3.new(-7780,47,-4511),
    Vector3.new(-1756,58,-2980)
}

-- ==========================================
-- CREATOR FUNCTIONS
-- ==========================================
local function CreateSection(parent,text,posY)
    local sec = Instance.new("Frame")
    sec.Size = UDim2.new(1,0,0,24)
    sec.Position = UDim2.new(0,0,0,posY)
    sec.BackgroundTransparency = 1
    sec.Parent = parent
    local t = Instance.new("TextLabel",sec)
    t.Size = UDim2.new(0,80,1,0)
    t.BackgroundTransparency = 1
    t.Text = text
    t.TextColor3 = Color3.fromRGB(139,123,184)
    t.TextSize = 12
    t.Font = Enum.Font.GothamBold
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextYAlignment = Enum.TextYAlignment.Center
    local ln = Instance.new("Frame",sec)
    ln.Size = UDim2.new(1,-90,0,2)
    ln.Position = UDim2.new(0,85,0.6,0)
    ln.BackgroundColor3 = Color3.fromRGB(139,123,184)
    ln.BackgroundTransparency = 0.4
    ln.BorderSizePixel = 0
    return posY+28
end

local function CreateToggle(parent,text,posY,featName)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,32)
    row.Position = UDim2.new(0,0,0,posY)
    row.BackgroundTransparency = 1
    row.Parent = parent
    local lbl = Instance.new("TextLabel",row)
    lbl.Size = UDim2.new(0.7,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(192,192,192)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    local tbg = Instance.new("TextButton",row)
    tbg.Size = UDim2.new(0,36,0,20)
    tbg.Position = UDim2.new(1,-36,0.5,-10)
    tbg.BackgroundColor3 = Color3.fromRGB(58,58,69)
    tbg.Text = ""
    tbg.AutoButtonColor = false
    Instance.new("UICorner",tbg).CornerRadius = UDim.new(1,0)
    local circ = Instance.new("Frame",tbg)
    circ.Size = UDim2.new(0,16,0,16)
    circ.Position = UDim2.new(0,2,0,2)
    circ.BackgroundColor3 = Color3.fromRGB(139,139,154)
    circ.BorderSizePixel = 0
    Instance.new("UICorner",circ).CornerRadius = UDim.new(1,0)
    local sd = Instance.new("TextLabel",row)
    sd.Size = UDim2.new(0,10,0,10)
    sd.Position = UDim2.new(0.7,-15,0.5,-5)
    sd.BackgroundTransparency = 1
    sd.Text = "●"
    sd.TextColor3 = Color3.fromRGB(107,91,149)
    sd.TextSize = 8
    sd.Visible = false
    row.MouseEnter:Connect(function() lbl.TextColor3 = Color3.fromRGB(255,255,255) end)
    row.MouseLeave:Connect(function() lbl.TextColor3 = Color3.fromRGB(192,192,192) end)
    return tbg, circ, sd, posY+36
end

local function CreateButton(parent,text,posY,bName)
    local btn = Instance.new("TextButton")
    btn.Name = bName
    btn.Size = UDim2.new(1,0,0,32)
    btn.Position = UDim2.new(0,0,0,posY)
    btn.BackgroundColor3 = Color3.fromRGB(58,58,69)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(192,192,192)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamMedium
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,6)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(107,91,149)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(58,58,69)}):Play()
    end)
    return btn, posY+40
end

local function CreateSlider(parent,text,posY,min,max,def,onChange)
    local val = def
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,44)
    row.Position = UDim2.new(0,0,0,posY)
    row.BackgroundTransparency = 1
    row.Parent = parent
    local lr = Instance.new("Frame",row)
    lr.Size = UDim2.new(1,0,0,18)
    lr.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel",lr)
    lbl.Size = UDim2.new(0.7,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(192,192,192)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local vl = Instance.new("TextLabel",lr)
    vl.Size = UDim2.new(0.3,0,1,0)
    vl.Position = UDim2.new(0.7,0,0,0)
    vl.BackgroundTransparency = 1
    vl.Text = tostring(val)
    vl.TextColor3 = Color3.fromRGB(139,123,184)
    vl.TextSize = 13
    vl.Font = Enum.Font.GothamSemibold
    vl.TextXAlignment = Enum.TextXAlignment.Right
    local trk = Instance.new("TextButton",row)
    trk.Size = UDim2.new(1,0,0,8)
    trk.Position = UDim2.new(0,0,0,26)
    trk.BackgroundColor3 = Color3.fromRGB(58,58,69)
    trk.Text = ""
    trk.AutoButtonColor = false
    Instance.new("UICorner",trk).CornerRadius = UDim.new(1,0)
    local fl = Instance.new("Frame",trk)
    fl.Size = UDim2.new((val-min)/(max-min),0,1,0)
    fl.BackgroundColor3 = Color3.fromRGB(107,91,149)
    fl.BorderSizePixel = 0
    Instance.new("UICorner",fl).CornerRadius = UDim.new(1,0)
    
    local function upd(x)
        local tp = trk.AbsolutePosition.X
        local ts = trk.AbsoluteSize.X
        local r = math.clamp((x-tp)/ts,0,1)
        local s = math.round(r*(max-min))+min
        val = s
        fl.Size = UDim2.new((val-min)/(max-min),0,1,0)
        vl.Text = tostring(val)
        if onChange then onChange(val) end
    end
    
    local d = false
    trk.MouseButton1Down:Connect(function()
        d = true
        upd(Mouse.X)
    end)
    UserInputService.InputChanged:Connect(function(i)
        if d and i.UserInputType == Enum.UserInputType.MouseMovement then
            upd(Mouse.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            d = false
        end
    end)
    
    local function SetValue(v)
        v = math.clamp(v, min, max)
        val = v
        fl.Size = UDim2.new((val-min)/(max-min),0,1,0)
        vl.Text = tostring(val)
        if onChange then onChange(val) end
    end

    return row, function() return val end, posY+50, SetValue
end

local function CreateTextBox(parent,text,posY,placeholder)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,32)
    row.Position = UDim2.new(0,0,0,posY)
    row.BackgroundTransparency = 1
    row.Parent = parent
    local lbl = Instance.new("TextLabel",row)
    lbl.Size = UDim2.new(0.4,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(192,192,192)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    local box = Instance.new("TextBox",row)
    box.Size = UDim2.new(0.6,-5,1,-4)
    box.Position = UDim2.new(0.4,5,0,2)
    box.BackgroundColor3 = Color3.fromRGB(42,42,53)
    box.TextColor3 = Color3.fromRGB(192,192,192)
    box.PlaceholderText = placeholder or ""
    box.Text = ""
    box.TextSize = 12
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    Instance.new("UICorner",box).CornerRadius = UDim.new(0,4)
    return box, posY+36
end

-- ==========================================
-- TABS SETUP
-- ==========================================
-- Auto Farms Tab
local FarmC = TabContents["Auto Farms"]
local fy = 0
fy = CreateSection(FarmC,"Auto Farms",fy)
local CorpseT, CorpseC, CorpseS, fy = CreateToggle(FarmC,"Auto Corpse",fy,"Corpse")
local BankT, BankC, BankS, fy = CreateToggle(FarmC,"Auto Bank",fy,"Bank")
local ChestT, ChestC, ChestS, fy = CreateToggle(FarmC,"Auto Chest",fy,"Chest")
fy = CreateSection(FarmC,"Scanner",fy+5)
local ScanT, ScanC, ScanS, fy = CreateToggle(FarmC,"Saint Scanner",fy,"SaintScanner")
local TeleportBtn, fy = CreateButton(FarmC,"Teleport to Saint",fy,"TeleportBtn")
TeleportBtn.BackgroundColor3 = Color3.fromRGB(42,42,53)
TeleportBtn.TextColor3 = Color3.fromRGB(139,123,184)
TeleportBtn.Visible = false

-- ESP Tab
local EspC = TabContents["ESP"]
local ey = 0
ey = CreateSection(EspC,"Player ESP",ey)
local EspT, EspCir, EspS, ey = CreateToggle(EspC,"Player ESP",ey,"ESP")

-- Movement Tab
local MovC = TabContents["Movement"]
local mvy = 0
mvy = CreateSection(MovC,"Movement",mvy)
local ClickTpT, ClickTpC, ClickTpS, mvy = CreateToggle(MovC,"Click Teleport",mvy,"ClickTp")
local FlyT, FlyC, FlyS, mvy = CreateToggle(MovC,"Fly",mvy,"Fly")
mvy = mvy + 4
local FlyKbLbl = Instance.new("TextLabel",MovC)
FlyKbLbl.Size = UDim2.new(0.6,0,0,24)
FlyKbLbl.Position = UDim2.new(0,0,0,mvy)
FlyKbLbl.BackgroundTransparency = 1
FlyKbLbl.Text = "Fly Keybind"
FlyKbLbl.TextColor3 = Color3.fromRGB(192,192,192)
FlyKbLbl.TextSize = 12
FlyKbLbl.Font = Enum.Font.Gotham
FlyKbLbl.TextXAlignment = Enum.TextXAlignment.Left
local FlyKbBtn = Instance.new("TextButton",MovC)
FlyKbBtn.Size = UDim2.new(0,80,0,24)
FlyKbBtn.Position = UDim2.new(1,-80,0,mvy)
FlyKbBtn.BackgroundColor3 = Color3.fromRGB(42,42,53)
FlyKbBtn.Text = "E"
FlyKbBtn.TextColor3 = Color3.fromRGB(184,168,216)
FlyKbBtn.TextSize = 11
FlyKbBtn.Font = Enum.Font.GothamMedium
FlyKbBtn.AutoButtonColor = false
Instance.new("UICorner",FlyKbBtn).CornerRadius = UDim.new(0,6)
mvy = mvy + 30
local SpeedRow, GetFlySpeed, mvy, SetFlySpeed = CreateSlider(MovC,"Fly Speed",mvy,10,50,20,function(v) FlySpeed = v + (v * v) / 100 end)

-- Misc Tab
local MiscC = TabContents["Misc"]
local miy = 0
miy = CreateSection(MiscC,"Exploits",miy)
local RakT, RakC, RakS, miy = CreateToggle(MiscC,"Raknet Desync",miy,"RaknetDesync")
miy = CreateSection(MiscC,"General",miy+5)
local HideT, HideC, HideS, miy = CreateToggle(MiscC,"Hide Name",miy,"HideName")
miy = miy+8
local KbLbl = Instance.new("TextLabel",MiscC)
KbLbl.Size = UDim2.new(0.6,0,0,24)
KbLbl.Position = UDim2.new(0,0,0,miy)
KbLbl.BackgroundTransparency = 1
KbLbl.Text = "GUI Keybind"
KbLbl.TextColor3 = Color3.fromRGB(192,192,192)
KbLbl.TextSize = 12
KbLbl.Font = Enum.Font.Gotham
KbLbl.TextXAlignment = Enum.TextXAlignment.Left
local KbBtn = Instance.new("TextButton",MiscC)
KbBtn.Size = UDim2.new(0,80,0,24)
KbBtn.Position = UDim2.new(1,-80,0,miy)
KbBtn.BackgroundColor3 = Color3.fromRGB(42,42,53)
KbBtn.Text = "F1"
KbBtn.TextColor3 = Color3.fromRGB(184,168,216)
KbBtn.TextSize = 11
KbBtn.Font = Enum.Font.GothamMedium
KbBtn.AutoButtonColor = false
Instance.new("UICorner",KbBtn).CornerRadius = UDim.new(0,6)

-- Server Tab
local ServC = TabContents["Server"]
local sv = 0
sv = CreateSection(ServC,"Server Hop",sv)
local MinRow, GetMin, sv, SetMin = CreateSlider(ServC,"Min Players",sv,1,25,1,function(v) SHC.MinPlayers=v end)
local MaxRow, GetMax, sv, SetMax = CreateSlider(ServC,"Max Players",sv,1,25,25,function(v) SHC.MaxPlayers=v end)
sv = CreateSection(ServC,"Actions",sv+5)
local ServerHopBtn, sv = CreateButton(ServC,"Server Hop",sv,"ServerHopBtn")
local RejoinBtn, sv = CreateButton(ServC,"Rejoin Server",sv,"RejoinBtn")

-- Settings Tab
local SetC = TabContents["Settings"]
local sy = 0
sy = CreateSection(SetC,"Config Management",sy)
local ConfigNameBox, sy = CreateTextBox(SetC,"Config Name",sy,"Enter name...")
sy = sy + 5

local ConfigListFrame = Instance.new("ScrollingFrame")
ConfigListFrame.Size = UDim2.new(1,0,0,140)
ConfigListFrame.Position = UDim2.new(0,0,0,sy)
ConfigListFrame.BackgroundColor3 = Color3.fromRGB(30,30,40)
ConfigListFrame.BorderSizePixel = 0
ConfigListFrame.ScrollBarThickness = 4
ConfigListFrame.Parent = SetC
Instance.new("UICorner", ConfigListFrame).CornerRadius = UDim.new(0,6)
local listLayout = Instance.new("UIListLayout", ConfigListFrame)
listLayout.Padding = UDim.new(0,2)
sy = sy + 105

local SaveCfgBtn, sy = CreateButton(SetC,"Save Config",sy,"SaveCfgBtn")
local LoadCfgBtn, sy = CreateButton(SetC,"Load Config",sy,"LoadCfgBtn")
local DelCfgBtn, sy = CreateButton(SetC,"Delete Config",sy,"DelCfgBtn")
local SetupAutoLoadBtn, sy = CreateButton(SetC,"Setup AutoLoad",sy,"SetupAutoLoadBtn")
local DeleteAutoLoadBtn, sy = CreateButton(SetC,"Delete AutoLoad",sy,"DeleteAutoLoadBtn")


-- ==========================================
-- UTILS
-- ==========================================
local function AnimToggle(btn,circ,sd,en)
    TweenService:Create(btn,TweenInfo.new(0.3),{BackgroundColor3=en and Color3.fromRGB(107,91,149) or Color3.fromRGB(58,58,69)}):Play()
    TweenService:Create(circ,TweenInfo.new(0.3),{Position=en and UDim2.new(0,18,0,2) or UDim2.new(0,2,0,2),BackgroundColor3=en and Color3.new(1,1,1) or Color3.fromRGB(139,139,154)}):Play()
    sd.Visible = en
end

local function findSaint()
    for _,o in ipairs(Workspace:GetChildren()) do
        if table.find(saintsPartNames,o.Name) and o:IsA("BasePart") then
            for _,c in ipairs(SAINT_COORDS) do if (o.Position-c).Magnitude<=60 then return o end end
        end
    end
    return nil
end

-- Executor Detection
-- ==========================================
-- CONFIG LIST UI
-- ==========================================
local function RefreshConfigListUI()
    for _, child in ipairs(ConfigListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local configs = GetConfigList()
    for _, name in ipairs(configs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -4, 0, 24)
        btn.BackgroundColor3 = Color3.fromRGB(42, 42, 53)
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(192, 192, 192)
        btn.TextSize = 11
        btn.Font = Enum.Font.Gotham
        btn.Parent = ConfigListFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(function()
            ConfigNameBox.Text = name
            CurrentConfigName = name
        end)
    end
    ConfigListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
end

local function BuildCfg()
    local c={} for n,f in pairs(Features) do c[n]=f.E end
    c.GuiKeybind=tostring(GuiKeybind)
    c.FlyKeybind=tostring(FlyKeybind)
    c.FlySlider=GetFlySpeed and GetFlySpeed() or 20
    c.MinPlayers=GetMin and GetMin() or 1
    c.MaxPlayers=GetMax and GetMax() or 25
    return c
end

local function SaveCurrentConfig()
    local name = ConfigNameBox.Text
    if name == "" then name = CurrentConfigName end
    name = name:gsub("[^%w_-]", "")
    if name == "" then name = "default" end
    CurrentConfigName = name
    local ok = SaveCfg(name, BuildCfg())
    if ok then
        Notify("Config '"..name.."' saved!", 3)
        RefreshConfigListUI()
    else
        Notify("Failed to save config", 3)
    end
end

local function LoadCurrentConfig()
    print("[Nezur] LoadCurrentConfig called, textbox: '" .. tostring(ConfigNameBox.Text) .. "'")
    local name = ConfigNameBox.Text
    if name == "" then 
        Notify("Enter config name first", 3)
        return
    end
    CurrentConfigName = name
    local data = LoadCfg(name)
    print("[Nezur] LoadCfg returned: " .. tostring(data ~= nil))
    if not data then
        Notify("Config '"..name.."' not found", 3)
        return
    end

    -- Восстанавливаем слайдеры
    if data.MinPlayers and SetMin then 
        SetMin(data.MinPlayers) 
    end
    if data.MaxPlayers and SetMax then 
        SetMax(data.MaxPlayers) 
    end
    if data.FlySlider and SetFlySpeed then 
        SetFlySpeed(data.FlySlider) 
    elseif data.FlySpeed then
        FlySpeed = data.FlySpeed
    end

    -- Восстанавливаем кейбинды
    if data.GuiKeybind then
        local ok,kc=pcall(function() return Enum.KeyCode[data.GuiKeybind] end)
        if ok and kc then GuiKeybind=kc KbBtn.Text=data.GuiKeybind end
    end
    if data.FlyKeybind then
        local ok,kc=pcall(function() return Enum.KeyCode[data.FlyKeybind] end)
        if ok and kc then FlyKeybind=kc FlyKbBtn.Text=data.FlyKeybind end
    end

    -- Восстанавливаем включенные фичи
    local starters = {
        Corpse=StartCorpse, Bank=StartBank, Chest=StartChest,
        SaintScanner=StartScanner, ESP=StartESP, ClickTp=StartClickTp,
        Fly=StartFly, RaknetDesync=StartRaknet, HideName=StartHide
    }

    for featName, enabled in pairs(data) do
        local isEnabled = (enabled == true) or (enabled == "true") or (enabled == 1)
        if isEnabled and Features[featName] then
            if not Features[featName].E then
                Features[featName].E = true
                local funcName = "Start" .. featName
                local ok, starterFunc = pcall(function()
                    return _G[funcName] or loadstring("return " .. funcName)()
                end)
                if ok and type(starterFunc) == "function" then
                    task.spawn(starterFunc)
                    print("[Nezur] LoadConfig: ENABLED " .. featName)
                else
                    print("[Nezur] LoadConfig: FAILED to find " .. funcName .. " type=" .. type(starterFunc))
                end
            end

            -- Обновляем визуал тогглов
            if featName == "Corpse" then AnimToggle(CorpseT, CorpseC, CorpseS, true) end
            if featName == "Bank" then AnimToggle(BankT, BankC, BankS, true) end
            if featName == "Chest" then AnimToggle(ChestT, ChestC, ChestS, true) end
            if featName == "SaintScanner" then AnimToggle(ScanT, ScanC, ScanS, true) end
            if featName == "ESP" then AnimToggle(EspT, EspCir, EspS, true) end
            if featName == "ClickTp" then AnimToggle(ClickTpT, ClickTpC, ClickTpS, true) end
            if featName == "Fly" then AnimToggle(FlyT, FlyC, FlyS, true) end
            if featName == "RaknetDesync" then AnimToggle(RakT, RakC, RakS, true) end
            if featName == "HideName" then AnimToggle(HideT, HideC, HideS, true) end
        end
    end

    Notify("Config '"..name.."' loaded!", 3)
end

local function DeleteCurrentConfig()
    local name = ConfigNameBox.Text
    if name == "" then Notify("Enter config name", 3) return end
    local path = ConfigFolder.."/"..name..".json"
    if isfile(path) then
        pcall(function() delfile(path) end)
        Notify("Config '"..name.."' deleted!", 3)
        RefreshConfigListUI()
    else
        Notify("Config not found", 3)
    end
end

-- ==========================================
-- AUTOLOAD FUNCTIONS
-- ==========================================
local function SetupAutoLoad()
    local name = ConfigNameBox.Text
    if name == "" then
        Notify("Enter config name first", 3)
        return
    end
    name = name:gsub("[^%w_-]", "")
    if name == "" then
        Notify("Invalid config name", 3)
        return
    end
    local path = ConfigFolder .. "/autoload.txt"
    local ok = pcall(function() writefile(path, name) end)
    if ok then
        Notify("AutoLoad set to '" .. name .. "'", 3)
    else
        Notify("Failed to set AutoLoad", 3)
    end
end

local function DeleteAutoLoad()
    local path = ConfigFolder .. "/autoload.txt"
    if isfile(path) then
        pcall(function() delfile(path) end)
        Notify("AutoLoad deleted", 3)
    else
        Notify("AutoLoad is empty", 3)
    end
end

-- ==========================================
-- AUTO EXECUTE PREPARE
-- ==========================================
-- ==========================================
-- SERVER HOP (единая функция)
-- ==========================================
local ServerHopRunning = false

local function ServerHop()
    if ServerHopRunning then
        Notify("Server hop already running", 3)
        return
    end
    ServerHopRunning = true

    local startJobId = game.JobId
    SetupAutoExec()

    -- Retry: if still on same server after 7s, try again
    task.delay(7, function()
        if not ServerHopRunning then return end
        if game.JobId == startJobId then
            Notify("Teleport failed, retrying...", 3)
            ServerHopRunning = false
            task.wait(1)
            ServerHop()
        end
    end)

    task.spawn(function()
        local ok, err = pcall(function()
            Notify("Fetching servers...", 2)
            local PID = game.PlaceId
            local CJID = game.JobId
            local Mn = SHC.MinPlayers
            local Mx = SHC.MaxPlayers

            local AIDs = {}
            pcall(function()
                local data = readfile("NotSameServers.json")
                AIDs = HttpService:JSONDecode(data)
            end)
            if #AIDs == 0 then
                table.insert(AIDs, os.date("!*t").hour)
                pcall(function() writefile("NotSameServers.json", HttpService:JSONEncode(AIDs)) end)
            end

            local orders = {"Desc", "Asc"}
            local found = false

            for _, order in ipairs(orders) do
                if found then break end
                local fa = ""
                local emptyCount = 0

                for attempt = 1, 100 do
                    if found then break end
                    
                    local url = 'https://games.roblox.com/v1/games/'..PID
                        ..'/servers/Public?sortOrder='..order
                        ..'&limit=100'
                        ..'&_nc='..tostring(tick())
                    if fa ~= "" and fa ~= "null" then
                        url = url .. '&cursor=' .. HttpService:UrlEncode(fa)
                    end

                    local response
                    local httpOk, httpErr = pcall(function()
                        response = game:HttpGet(url)
                    end)

                    if not httpOk then
                        Notify("HTTP Error: " .. tostring(httpErr):sub(1, 40), 3)
                        task.wait(0.5)
                    elseif not response or response == "" then
                        emptyCount = emptyCount + 1
                        if emptyCount >= 3 then
                            Notify("API empty, retrying...", 3)
                            task.wait(2)
                            emptyCount = 0
                        else
                            task.wait(0.5)
                        end
                    else
                        local decodeOk, S = pcall(function()
                            return HttpService:JSONDecode(response)
                        end)

                        if not decodeOk then
                            Notify("JSON Error", 2)
                            task.wait(0.5)
                        elseif not S or not S.data then
                            Notify("No server data", 2)
                            task.wait(0.5)
                        else
                            if S.nextPageCursor and S.nextPageCursor ~= "null" and S.nextPageCursor ~= "" then
                                fa = tostring(S.nextPageCursor)
                            else
                                fa = ""
                            end

                            for _, v in ipairs(S.data) do
                                local pl = tonumber(v.playing)
                                local mp = tonumber(v.maxPlayers)
                                local sid = tostring(v.id)

                                if pl and mp and sid and pl >= Mn and pl <= Mx and sid ~= CJID and pl < mp then
                                    if not table.find(AIDs, sid) then
                                        table.insert(AIDs, sid)
                                        pcall(function()
                                            writefile("NotSameServers.json", HttpService:JSONEncode(AIDs))
                                        end)
                                        Notify("Teleporting (" .. pl .. "/" .. mp .. ")", 3)
                                        pcall(function()
                                            TeleportService:TeleportToPlaceInstance(PID, sid, player)
                                        end)
                                        found = true
                                        break
                                    end
                                end
                            end

                            if fa == "" then break end
                            task.wait(0.3)
                        end
                    end
                end
            end

            if not found then
                Notify("No server found (try lower Min)", 5)
            end
        end)

        if not ok then
            Notify("Hop Error: " .. tostring(err):sub(1, 50), 5)
            warn("ServerHop Error:", err)
        end

        ServerHopRunning = false
    end)
end

-- ==========================================
-- AUTO CORPSE
-- ==========================================
local function StartCorpse()
    Notify("Auto corpse active")
    local VIM = game:GetService("VirtualInputManager")
    local SAFE = CFrame.new(-4387.25,217.5,-4482.04)
    local processing = false
    local function wfc()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then return player.Character end
        return player.CharacterAdded:Wait()
    end
    local function equipRandom()
        local bp = player:FindFirstChild("Backpack")
        if not bp then return end
        local t = {}
        for _, i in ipairs(bp:GetChildren()) do if i:IsA("Tool") then table.insert(t, i) end end
        if #t > 0 then
            local h = player.Character and player.Character:FindFirstChild("Humanoid")
            if h then h:EquipTool(t[math.random(1, #t)]) end
        end
    end
    local function nearSaint()
        local c = player.Character
        if not c or not c:FindFirstChild("HumanoidRootPart") then return nil end
        for _, o in ipairs(Workspace:GetDescendants()) do
            if table.find(saintsPartNames, o.Name) and o:IsA("BasePart") then
                if (o.Position - c.HumanoidRootPart.Position).Magnitude < 20 then return o end
            end
        end
        return nil
    end
    local function tapWA()
        VIM:SendKeyEvent(true, Enum.KeyCode.W, false, game) task.wait(0.12)
        VIM:SendKeyEvent(false, Enum.KeyCode.W, false, game) task.wait(0.2)
        VIM:SendKeyEvent(true, Enum.KeyCode.A, false, game) task.wait(0.12)
        VIM:SendKeyEvent(false, Enum.KeyCode.A, false, game) task.wait(0.3)
    end
    local function rejoin()
        local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if r then r.Anchored = true end
        ServerHop()
    end
    local function holdPrompt(p)
        if not p then return end
        for _ = 1, 3 do
            pcall(function() p:InputHoldBegin() end) task.wait(6)
            pcall(function() p:InputHoldEnd() end) task.wait(0.5)
            if not p.Parent then return true end
        end
    end
    local ch = wfc()
    local rt = ch:WaitForChild("HumanoidRootPart")
    equipRandom() task.wait(2)
    local nb = nearSaint()
    if nb then
        tapWA() task.wait(0.5)
        rt.CFrame = nb.CFrame + Vector3.new(0, 3, 0) task.wait(0.6)
        holdPrompt(nb:FindFirstChildOfClass("ProximityPrompt") or nb.Parent:FindFirstChildOfClass("ProximityPrompt"))
    else
        rt.CFrame = SAFE task.wait(1.5)
        Features.Corpse.C = RunService.Heartbeat:Connect(function()
            if processing then return end
            local s = findSaint()
            if s then
                processing = true
                local cc = wfc()
                local cr = cc:WaitForChild("HumanoidRootPart")
                cr.CFrame = s.CFrame + Vector3.new(0, 4, 0)
                cr.Velocity = Vector3.new(0, 0, 0) task.wait(1.2)
                rejoin()
            end
        end)
    end
    task.spawn(function()
        repeat task.wait() until game:IsLoaded() task.wait(1.5)
        local nc = wfc()
        local nr = nc:WaitForChild("HumanoidRootPart") task.wait(1)
        local ns = nearSaint()
        if ns then
            tapWA() task.wait(0.5)
            nr.CFrame = ns.CFrame + Vector3.new(0, 3, 0) task.wait(0.6)
            holdPrompt(ns:FindFirstChildOfClass("ProximityPrompt") or ns.Parent:FindFirstChildOfClass("ProximityPrompt"))
        end
    end)
end
local function StopCorpse()
    Notify("Auto corpse disabled")
    if Features.Corpse.C then Features.Corpse.C:Disconnect() Features.Corpse.C = nil end
end

-- ==========================================
-- AUTO BANK
-- ==========================================
local BankRunning = false
local BankThread = nil

local function StartBank()
    if BankRunning then return end
    BankRunning = true
    Notify("Auto rob bank")
    
    BankThread = task.spawn(function()
        local ok, err = pcall(function()
            local bd = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("BlastDoor")
            if bd and bd:FindFirstChild("RobberyCD") then ServerHop() return end
            repeat
                task.wait()
                if not BankRunning then return end
            until game:IsLoaded()
            
            local VIM = game:GetService("VirtualInputManager")
            local ch = player.Character or player.CharacterAdded:Wait()
            local rt = ch:WaitForChild("HumanoidRootPart")
            
            local function tp(x, y, z)
                if not BankRunning then return end
                rt.CFrame = CFrame.new(x, y, z)
                rt.Velocity = Vector3.new(0, 0, 0)
                rt.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                task.wait(0.2)
            end
            local function clickD(o)
                if not BankRunning then return false end
                if not o then return false end
                local cd = o:FindFirstChildOfClass("ClickDetector")
                if cd then fireclickdetector(cd) return true end
                return false
            end
            local function hasItem(n)
                local bp = player:WaitForChild("Backpack")
                if bp:FindFirstChild(n) then return true end
                local c = player.Character
                if c and c:FindFirstChild(n) then return true end
                return false
            end
            local function getChoices()
                local g = player:WaitForChild("PlayerGui")
                local d = g:FindFirstChild("DialogueGui") if not d then return {} end
                local m = d:FindFirstChild("MainFrame") if not m then return {} end
                local cl = m:FindFirstChild("ChoiceList") if not cl then return {} end
                local t = {}
                for _, c in ipairs(cl:GetChildren()) do
                    if c.Name:match("^Choice_%d+$") then table.insert(t, c) end
                end
                return t
            end
            local function clickChoice(n)
                if not BankRunning then return false end
                local g = player:WaitForChild("PlayerGui")
                local d = g:FindFirstChild("DialogueGui") if not d then return false end
                local m = d:FindFirstChild("MainFrame") if not m then return false end
                local cl = m:FindFirstChild("ChoiceList") if not cl then return false end
                local b = cl:FindFirstChild("Choice_"..n) if not b then return false end
                pcall(function() if b:IsA("GuiButton") then b.MouseButton1Click:Fire() end end)
                pcall(function() for _, c in ipairs(getconnections(b.MouseButton1Click)) do c:Fire() end end)
                pcall(function() firesignal(b.MouseButton1Click) end)
                pcall(function()
                    if b.AbsolutePosition and b.AbsoluteSize then
                        local x = b.AbsolutePosition.X + b.AbsoluteSize.X / 2
                        local y = b.AbsolutePosition.Y + b.AbsoluteSize.Y / 2
                        VIM:SendMouseButtonEvent(x, y, 0, true, game, 0) task.wait(0.03)
                        VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
                    end
                end)
                return true
            end
            local function waitDialog(t)
                t = t or 5
                local st = tick()
                while tick() - st < t do
                    if not BankRunning then return false end
                    if #getChoices() > 0 then task.wait(0.2) return true end
                    task.wait(0.05)
                end
                return false
            end
            local function acceptQuest()
                for i = 1, 2 do
                    if not BankRunning then return false end
                    clickChoice(1) task.wait(0.3)
                    if #getChoices() == 0 then return true end
                end
                return false
            end
            local function equipItem(n)
                if not BankRunning then return false end
                local bp = player:WaitForChild("Backpack")
                local t = bp:FindFirstChild(n) if not t then return false end
                local h = ch:FindFirstChildOfClass("Humanoid") if not h then return false end
                h:EquipTool(t) task.wait(0.15) return true
            end
            local function clickOnce()
                if not BankRunning then return end
                VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0) task.wait(0.05)
                VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
            local function findCash()
                local t = {}
                for _, c in ipairs(Workspace:GetChildren()) do
                    if c.Name == "Cash" then
                        local p = c:FindFirstChild("Part")
                        if p then
                            local cd = p:FindFirstChildOfClass("ClickDetector")
                            if cd then table.insert(t, { co = c, po = p, cd = cd }) end
                        end
                    end
                end
                return t
            end
            local function collectCash()
                local col = 0
                local att = 0
                while att < 30 do
                    if not BankRunning then break end
                    local cash = findCash()
                    if #cash == 0 then break end
                    tp(-5764.15, 48.4, -4035.92) task.wait(0.15)
                    for _, d in ipairs(cash) do
                        for i = 1, 3 do
                            fireclickdetector(d.cd)
                            task.wait(0.08)
                        end
                        col = col + 1
                        task.wait(0.15)
                    end
                    att = att + 1
                    task.wait(0.2)
                end
                return col
            end
            
            local hasExp = false
            while not hasExp do
                if not BankRunning then return end
                if hasItem("Makeshift Explosive") then hasExp = true break end
                tp(-2561.91, 45.03, -2594.83)
                local ad = Workspace:FindFirstChild("Arms Dealer")
                if ad then clickD(ad) task.wait(0.2) end
                if waitDialog(5) then
                    acceptQuest()
                    local a = 0
                    while not hasItem("Makeshift Explosive") and a < 15 do
                        if not BankRunning then return end
                        if #getChoices() > 0 then clickChoice(1) task.wait(0.4)
                        else if ad then clickD(ad) task.wait(0.5) waitDialog(3) end end
                        a = a + 1
                    end
                end
                if hasItem("Makeshift Explosive") then hasExp = true else task.wait(1) end
            end
            
            if not BankRunning then return end
            tp(-5744.06, 47.5, -4032.02)
            if equipItem("Makeshift Explosive") then task.wait(0.2) clickOnce() task.wait(0.5) end
            
            local ew = tick()
            local ef = false
            while tick() - ew < 10 do
                if not BankRunning then return end
                if Workspace:FindFirstChild("Explosive") then
                    ef = true
                    tp(-5743.32, 78.7, -4037.94)
                    break
                end
                task.wait(0.2)
            end
            
            if not BankRunning then return end
            if not ef then Notify("Explosive not found") task.wait(0.5) ServerHop() return end
            
            local cw = tick()
            local cr = false
            while tick() - cw < 20 do
                if not BankRunning then return end
                if #findCash() > 0 then cr = true break end
                task.wait(0.3)
            end
            
            if not BankRunning then return end
            if cr then task.wait(0.5) collectCash() end
            
            tp(-2594.37, 261.48, -2375.87) task.wait(25)
            
            if not BankRunning then return end
            tp(-2561.91, 45.03, -2594.83)
            local ad = Workspace:FindFirstChild("Arms Dealer")
            if ad then clickD(ad) task.wait(0.2) end
            if waitDialog(5) then clickChoice(1) task.wait(0.4) if #getChoices() > 0 then clickChoice(1) task.wait(0.4) end end
            task.wait(1)
            ServerHop()
        end)
        
        BankRunning = false
        if not ok and err then
            if not tostring(err):find("STOP") then
                warn("Auto Bank error:", err)
            end
        end
    end)
    
    Features.Bank.C = {
        Disconnect = function()
            BankRunning = false
            if BankThread then
                pcall(function() coroutine.close(BankThread) end)
                BankThread = nil
            end
        end
    }
end

local function StopBank()
    Notify("Auto bank disabled")
    BankRunning = false
    if BankThread then
        pcall(function() coroutine.close(BankThread) end)
        BankThread = nil
    end
    Features.Bank.C = nil
end

-- ==========================================
-- AUTO CHEST
-- ==========================================
local function StartChest()
    Notify("Auto chest enabled")
    repeat task.wait() until game:IsLoaded()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local cf = workspace:FindFirstChild("Chests")
    if not cf then Notify("No chests found") return end
    
    local function openChest(chest)
        if not chest or not chest.Parent then return end
        local part = chest:FindFirstChildWhichIsA("BasePart") or chest.PrimaryPart
        if not part then return end
        hrp.CFrame = part.CFrame * CFrame.new(0, 5, 0)
        task.wait(0.3)
        for _, desc in ipairs(chest:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                pcall(function() fireproximityprompt(desc) end)
            end
        end
        task.wait(0.2)
    end
    
    for _, chest in ipairs(cf:GetChildren()) do
        if chest:IsA("Model") or chest:IsA("Part") or chest:IsA("MeshPart") then
            openChest(chest)
        end
    end
    task.wait(1)
    ServerHop()
end
local function StopChest()
    Notify("Auto chest disabled")
    if Features.Chest.C then Features.Chest.C:Disconnect() Features.Chest.C = nil end
end

-- ==========================================
-- SAINT SCANNER
-- ==========================================
local function StartScanner()
    Notify("Saint scanner enabled")
    ScannerData.Scan = true
    local last = nil
    Features.SaintScanner.C = RunService.Heartbeat:Connect(function()
        if not ScannerData.Scan then return end
        local s = findSaint()
        if s then
            if last ~= s then
                last = s
                ScannerData.DP = s
                ScannerData.DPos = s.Position
                TeleportBtn.Visible = true
                Notify("Saint detected!", 4)
            end
        else
            last = nil
            ScannerData.DP = nil
            ScannerData.DPos = nil
            TeleportBtn.Visible = false
        end
        task.wait(2)
    end)
end
local function StopScanner()
    Notify("Saint scanner disabled")
    ScannerData.Scan = false
    ScannerData.DP = nil
    ScannerData.DPos = nil
    TeleportBtn.Visible = false
    if Features.SaintScanner.C then Features.SaintScanner.C:Disconnect() Features.SaintScanner.C = nil end
end
TeleportBtn.MouseButton1Click:Connect(function()
    if ScannerData.DP and ScannerData.DP.Parent then
        local c = player.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            c.HumanoidRootPart.CFrame = ScannerData.DP.CFrame + Vector3.new(0, 5, 0)
            Notify("Teleported", 3)
        end
    else
        Notify("No saint found", 3)
    end
end)

-- ==========================================
-- ESP SYSTEM
-- ==========================================
local ESPDrawings = {}

local function CreateESPText(plr)
    if plr == player or ESPDrawings[plr] then return end
    local d = Drawing.new("Text")
    d.Size = 13
    d.Center = true
    d.Outline = true
    d.Color = Color3.new(1, 1, 1)
    d.Visible = false
    ESPDrawings[plr] = d
end

local function RemoveESPText(plr)
    local d = ESPDrawings[plr]
    if d then d:Remove() ESPDrawings[plr] = nil end
end

local function UpdateESP()
    local cam = workspace.CurrentCamera
    local lc = player.Character
    local lhrp = lc and lc:FindFirstChild("HumanoidRootPart")
    local lp = lhrp and lhrp.Position or Vector3.new()
    
    for plr, txt in pairs(ESPDrawings) do
        if not plr.Parent then txt.Visible = false continue end
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and hum and hum.Health > 0 then
            local dist = (hrp.Position - lp).Magnitude
            if dist <= 5000 then
                local pos, onScreen = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                if onScreen then
                    txt.Text = string.format("%s [%s/%s] %sm", plr.Name, math.floor(hum.Health), math.floor(hum.MaxHealth), math.floor(dist))
                    txt.Position = Vector2.new(pos.X, pos.Y)
                    txt.Visible = true
                else
                    txt.Visible = false
                end
            else
                txt.Visible = false
            end
        else
            txt.Visible = false
        end
    end
end

local function StartESP()
    Notify("Player ESP enabled")
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then CreateESPText(p) end
    end
    Features.ESP.C = RunService.RenderStepped:Connect(UpdateESP)
    Features.ESP.PlayerAdded = Players.PlayerAdded:Connect(function(p) CreateESPText(p) end)
    Features.ESP.PlayerRemoving = Players.PlayerRemoving:Connect(function(p) RemoveESPText(p) end)
end

local function StopESP()
    Notify("Player ESP disabled")
    if Features.ESP.C then Features.ESP.C:Disconnect() Features.ESP.C = nil end
    if Features.ESP.PlayerAdded then Features.ESP.PlayerAdded:Disconnect() Features.ESP.PlayerAdded = nil end
    if Features.ESP.PlayerRemoving then Features.ESP.PlayerRemoving:Disconnect() Features.ESP.PlayerRemoving = nil end
    for _, d in pairs(ESPDrawings) do d:Remove() end
    ESPDrawings = {}
end

-- ==========================================
-- CLICK TP
-- ==========================================
local function StartClickTp()
    Notify("ClickTP enabled (Shift+Click)")
    Features.ClickTp.C = UserInputService.InputBegan:Connect(function(i, g)
        if g then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            local c = player.Character
            if c then
                local r = c:FindFirstChild("HumanoidRootPart")
                if r then
                    r.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
                    r.Velocity = Vector3.new(0, 0, 0)
                    r.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                end
            end
        end
    end)
end
local function StopClickTp()
    Notify("ClickTP disabled")
    if Features.ClickTp.C then Features.ClickTp.C:Disconnect() Features.ClickTp.C = nil end
end

-- ==========================================
-- FLY
-- ==========================================
local FlyConn = nil
local FlyAct = false

local function StartFly()
    Notify("Fly enabled")
    task.delay(0.5, function()
        Notify("!!CAUTION!! If Fly resets your HP to 0 after 10 seconds of flying - DONT TURN IT OFF WHILE LOW HP", 6)
    end)
    local c = player.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    
    FlyAct = true
    hum.PlatformStand = true
    
    FlyConn = RunService.Heartbeat:Connect(function()
        if not hrp.Parent or not hum.Parent then return end
        if FlyAct then
            hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            local md = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then md = md + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then md = md + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then md = md + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then md = md + Vector3.new(1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then md = md + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then md = md + Vector3.new(0, -1, 0) end
            
            if md.Magnitude > 0 then
                md = md.Unit
                local cam = workspace.CurrentCamera
                local moveDir = (cam.CFrame.LookVector * -md.Z + cam.CFrame.RightVector * md.X + Vector3.new(0, md.Y, 0)).Unit
                hrp.Velocity = moveDir * FlySpeed
                hrp.CFrame = CFrame.new(hrp.Position + moveDir * 0.5)
            else
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                hrp.Velocity = Vector3.new(0, 0, 0)
            end
        else
            hrp.Velocity = Vector3.new()
        end
    end)
end

local function StopFly()
    Notify("Fly disabled")
    FlyAct = false
    if FlyConn then FlyConn:Disconnect() FlyConn = nil end
    local c = player.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Velocity = Vector3.new() end
    end
end

-- ==========================================
-- RAKNET
-- ==========================================
local function StartRaknet()
    Notify("Raknet enabled (U)")
    local uis = game:GetService("UserInputService")
    local h = false
    local function rh(p)
        if p.PacketId == 0x1B then
            local b = p.AsBuffer
            buffer.writeu32(b, 1, 0xFFFFFFFF)
            p:SetData(b)
        end
    end
    Features.RaknetDesync.C = uis.InputBegan:Connect(function(o)
        if o.KeyCode ~= Enum.KeyCode.U then return end
        if h then raknet.remove_send_hook(rh) else raknet.add_send_hook(rh) end
        h = not h
    end)
end
local function StopRaknet()
    Notify("Raknet disabled")
    if Features.RaknetDesync.C then Features.RaknetDesync.C:Disconnect() Features.RaknetDesync.C = nil end
end

-- ==========================================
-- HIDE NAME
-- ==========================================
local function StartHide()
    Notify("Hide name enabled")
    local function upd()
        local g = player:FindFirstChild("PlayerGui")
        if not g then return end
        local s = g:FindFirstChild("ServerInfoGui")
        if not s then return end
        local c = s:FindFirstChild("Container")
        if not c then return end
        local l = c:FindFirstChild("NameLabel")
        if l then l.Text = "discord.gg/nexonix" end
    end
    upd()
    Features.HideName.C = RunService.Heartbeat:Connect(upd)
end
local function StopHide()
    Notify("Hide name disabled")
    if Features.HideName.C then Features.HideName.C:Disconnect() Features.HideName.C = nil end
end

-- ==========================================
-- TOGGLE SETUP
-- ==========================================
local function ST(tbtn, circ, sd, fn, sf, spf)
    tbtn.MouseButton1Click:Connect(function()
        Features[fn].E = not Features[fn].E
        AnimToggle(tbtn, circ, sd, Features[fn].E)
        if Features[fn].E then sf() else spf() end
    end)
end

ST(CorpseT, CorpseC, CorpseS, "Corpse", StartCorpse, StopCorpse)
ST(BankT, BankC, BankS, "Bank", StartBank, StopBank)
ST(ChestT, ChestC, ChestS, "Chest", StartChest, StopChest)
ST(ScanT, ScanC, ScanS, "SaintScanner", StartScanner, StopScanner)
ST(EspT, EspCir, EspS, "ESP", StartESP, StopESP)
ST(ClickTpT, ClickTpC, ClickTpS, "ClickTp", StartClickTp, StopClickTp)
ST(FlyT, FlyC, FlyS, "Fly", StartFly, StopFly)
ST(RakT, RakC, RakS, "RaknetDesync", StartRaknet, StopRaknet)
ST(HideT, HideC, HideS, "HideName", StartHide, StopHide)

-- ==========================================
-- KEYBINDS
-- ==========================================
KbBtn.MouseButton1Click:Connect(function()
    if IsListening then return end
    IsListening = true
    KbBtn.Text = "Press key"
    KbBtn.TextColor3 = Color3.new(1, 1, 1)
    local conn
    conn = UserInputService.InputBegan:Connect(function(i, g)
        if g then return end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            GuiKeybind = i.KeyCode
            KbBtn.Text = tostring(i.KeyCode):gsub("Enum.KeyCode.", "")
            KbBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
            IsListening = false
            if conn then conn:Disconnect() end
        end
    end)
    task.delay(5, function()
        if IsListening then
            IsListening = false
            KbBtn.Text = tostring(GuiKeybind):gsub("Enum.KeyCode.", "")
            KbBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
            if conn then conn:Disconnect() end
        end
    end)
end)

FlyKbBtn.MouseButton1Click:Connect(function()
    if IsFlyListening then return end
    IsFlyListening = true
    FlyKbBtn.Text = "Press key"
    FlyKbBtn.TextColor3 = Color3.new(1, 1, 1)
    local conn
    conn = UserInputService.InputBegan:Connect(function(i, g)
        if g then return end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            FlyKeybind = i.KeyCode
            FlyKbBtn.Text = tostring(i.KeyCode):gsub("Enum.KeyCode.", "")
            FlyKbBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
            IsFlyListening = false
            if conn then conn:Disconnect() end
        end
    end)
    task.delay(5, function()
        if IsFlyListening then
            IsFlyListening = false
            FlyKbBtn.Text = tostring(FlyKeybind):gsub("Enum.KeyCode.", "")
            FlyKbBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
            if conn then conn:Disconnect() end
        end
    end)
end)

UserInputService.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == FlyKeybind then
        Features.Fly.E = not Features.Fly.E
        AnimToggle(FlyT, FlyC, FlyS, Features.Fly.E)
        if Features.Fly.E then StartFly() else StopFly() end
    end
end)

UserInputService.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == GuiKeybind then
        IsGuiHidden = not IsGuiHidden
        MainFrame.Visible = not IsGuiHidden
        NotifGui.Enabled = not IsGuiHidden
        if not IsGuiHidden then
            local ts = UDim2.new(0, 360, 0, 420)
            if ActiveTab == "ESP" then ts = UDim2.new(0, 360, 0, 300)
            elseif ActiveTab == "Movement" then ts = UDim2.new(0, 360, 0, 440)
            elseif ActiveTab == "Misc" then ts = UDim2.new(0, 360, 0, 340)
            elseif ActiveTab == "Server" then ts = UDim2.new(0, 360, 0, 380)
            elseif ActiveTab == "Settings" then ts = UDim2.new(0, 360, 0, 480) end
            MainFrame.Size = ts
        end
    end
end)

-- ==========================================
-- BUTTONS
-- ==========================================
SaveCfgBtn.MouseButton1Click:Connect(SaveCurrentConfig)
LoadCfgBtn.MouseButton1Click:Connect(LoadCurrentConfig)
DelCfgBtn.MouseButton1Click:Connect(DeleteCurrentConfig)
ServerHopBtn.MouseButton1Click:Connect(function()
    Notify("Starting server hop...", 2)
    ServerHop()
end)
RejoinBtn.MouseButton1Click:Connect(function()
    Notify("Rejoining...", 3)
    SetupAutoExec()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end)

SetupAutoLoadBtn.MouseButton1Click:Connect(SetupAutoLoad)
DeleteAutoLoadBtn.MouseButton1Click:Connect(DeleteAutoLoad)

-- ==========================================
-- AUTO-RESTORE (при заходе на новый сервер)
-- ==========================================
task.delay(3, function()
    local autoLoadPath = ConfigFolder .. "/autoload.txt"
    if isfile(autoLoadPath) then
        local ok, name = pcall(function() return readfile(autoLoadPath) end)
        if ok and name and name ~= "" then
            name = name:gsub("%s+", "")
            if name ~= "" then
                ConfigNameBox.Text = name
                CurrentConfigName = name
                local data = LoadCfg(name)
                if data then
                    -- Восстанавливаем слайдеры
                    if data.MinPlayers and SetMin then SetMin(data.MinPlayers) end
                    if data.MaxPlayers and SetMax then SetMax(data.MaxPlayers) end
                    if data.FlySlider and SetFlySpeed then 
                        SetFlySpeed(data.FlySlider) 
                    elseif data.FlySpeed then
                        FlySpeed = data.FlySpeed
                    end

                    -- Восстанавливаем кейбинды
                    if data.GuiKeybind then
                        local ok2,kc=pcall(function() return Enum.KeyCode[data.GuiKeybind] end)
                        if ok2 and kc then GuiKeybind=kc KbBtn.Text=data.GuiKeybind end
                    end
                    if data.FlyKeybind then
                        local ok2,kc=pcall(function() return Enum.KeyCode[data.FlyKeybind] end)
                        if ok2 and kc then FlyKeybind=kc FlyKbBtn.Text=data.FlyKeybind end
                    end

                    -- Восстанавливаем включенные фичи
                    local starters = {
                        Corpse=StartCorpse, Bank=StartBank, Chest=StartChest,
                        SaintScanner=StartScanner, ESP=StartESP, ClickTp=StartClickTp,
                        Fly=StartFly, RaknetDesync=StartRaknet, HideName=StartHide
                    }

                    for featName, enabled in pairs(data) do
                        if enabled == true and Features[featName] and starters[featName] then
                            Features[featName].E = true
                            task.spawn(starters[featName])

                            -- Обновляем визуал тогглов
                            if featName == "Corpse" then AnimToggle(CorpseT, CorpseC, CorpseS, true) end
                            if featName == "Bank" then AnimToggle(BankT, BankC, BankS, true) end
                            if featName == "Chest" then AnimToggle(ChestT, ChestC, ChestS, true) end
                            if featName == "SaintScanner" then AnimToggle(ScanT, ScanC, ScanS, true) end
                            if featName == "ESP" then AnimToggle(EspT, EspCir, EspS, true) end
                            if featName == "ClickTp" then AnimToggle(ClickTpT, ClickTpC, ClickTpS, true) end
                            if featName == "Fly" then AnimToggle(FlyT, FlyC, FlyS, true) end
                            if featName == "RaknetDesync" then AnimToggle(RakT, RakC, RakS, true) end
                            if featName == "HideName" then AnimToggle(HideT, HideC, HideS, true) end
                        end
                    end

                    Notify("AutoLoad successful", 3)
                else
                    Notify("AutoLoad failed: config '" .. name .. "' not found", 3)
                end
            else
                Notify("AutoLoad is empty", 3)
            end
        else
            Notify("AutoLoad is empty", 3)
        end
    else
        Notify("AutoLoad is empty", 3)
    end
end)

-- ==========================================
-- INIT
-- ==========================================
RefreshConfigListUI()

ScreenGui.Destroying:Connect(function()
    for _, f in pairs(Features) do
        if f.C then
            if typeof(f.C) == "RBXScriptConnection" then
                f.C:Disconnect()
            elseif type(f.C) == "table" and f.C.Disconnect then
                f.C:Disconnect()
            end
            f.C = nil
        end
        if f.PlayerAdded then f.PlayerAdded:Disconnect() f.PlayerAdded = nil end
        if f.PlayerRemoving then f.PlayerRemoving:Disconnect() f.PlayerRemoving = nil end
    end
    for _, d in pairs(ESPDrawings) do d:Remove() end
    ESPDrawings = {}
end)

Notify("Nezur loaded successfully", 4)
