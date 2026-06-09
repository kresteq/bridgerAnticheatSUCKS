task.wait(0.1)
repeat task.wait() until game:IsLoaded()
task.wait(10)
if type(clearteleportqueue) == "function" then pcall(clearteleportqueue)
elseif type(clearteleport_queue) == "function" then pcall(clearteleport_queue) end

if getgenv().RarityTSBLoaded then return end
getgenv().RarityTSBLoaded = true

-- ==========================================
-- SERVICES
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local Mouse = player:GetMouse()
local Camera = workspace.CurrentCamera
local Lighting = game:GetService("Lighting")

local oldGui = playerGui:FindFirstChild("rarity.tsb")
if oldGui then oldGui:Destroy() end

local SCRIPT_URL = "https://raw.githubusercontent.com/kresteq/bridgerAnticheatSUCKS/refs/heads/main/67.lua"
local ConfigFolder = "rarity.tsb"
if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

-- ==========================================
-- CONFIG VARS
-- ==========================================
local CurrentConfigName = "default"
local SHC = {MinPlayers=1, MaxPlayers=25}
local GuiKeybind = Enum.KeyCode.F1
local IsGuiHidden = false
local ServerHopRunning = false
local FlySpeed = 24
local FlySpeedMultiplier = 2.0
local SpeedHackValue = 50
local SafeModeHP = 30
local AimlockSmoothness = 0.5
local AimlockPrediction = 0.5
local FullBrightValue = 3
local ESPColor = Color3.fromRGB(147, 0, 211) -- Purple default
-- Void Kill timings: Flowing Water = 1.4s, Lethal Whirlwind Stream = 1.1s after skill activation

-- ==========================================
-- KEYBINDS REGISTRY
-- ==========================================
local Keybinds = {
    Fly = Enum.KeyCode.E,
    SpeedHack = Enum.KeyCode.X,
    ClickTp = Enum.UserInputType.MouseButton3,
    AutoM1Trade = Enum.KeyCode.M,
    AutoBlock = Enum.KeyCode.N,
    Aimlock = Enum.KeyCode.L,
    NoClip = Enum.KeyCode.J,
    SafeMode = Enum.KeyCode.K,
    VoidKill = Enum.KeyCode.F2,
}

-- ==========================================
-- FEATURES REGISTRY
-- ==========================================
local Features = {
    AutoM1Trade={E=false,C=nil},
    AutoBlock={E=false,C=nil},
    Aimlock={E=false,C=nil},
    NoStun={E=false,C=nil},
    NoDashCooldown={E=false,C=nil},

    Invisibility={E=false,C=nil},
    AntiDeathCounter={E=false,C=nil},
    ESP={E=false,C=nil,PlayerAdded=nil,PlayerRemoving=nil},
    Tracers={E=false,C=nil},
    Chams={E=false,C=nil},
    ClickTp={E=false,C=nil},
    Fly={E=false,C=nil},
    SpeedHack={E=false,C=nil},
    NoClip={E=false,C=nil},
    SafeMode={E=false,C=nil},
    FullBright={E=false,C=nil},
    VoidKills={E=false,C=nil},
    Fling={E=false,C=nil},
    AntiFling={E=false,C=nil},
    TrackEvasive={E=false,C=nil},
    TrackFrontDash={E=false,C=nil},
    TrackSideDash={E=false,C=nil},
}

-- ==========================================
-- MASTER CONNECTION SYSTEM
-- ==========================================
local MasterHeartbeat = nil
local HeartbeatTasks = {}
local MasterInput = nil
local InputActions = {}
local MasterStepped = nil
local SteppedTasks = {}

local function RegisterHeartbeatTask(name, fn)
    HeartbeatTasks[name] = fn
end

local function UnregisterHeartbeatTask(name)
    HeartbeatTasks[name] = nil
end

local function RegisterInputAction(key, fn)
    InputActions[key] = fn
end

local function UnregisterInputAction(key)
    InputActions[key] = nil
end

local function StartMasterConnections()
    if MasterHeartbeat then return end
    MasterHeartbeat = RunService.Heartbeat:Connect(function(dt)
        for name, fn in pairs(HeartbeatTasks) do
            local ok, err = pcall(fn, dt)
            if not ok then
                warn("[rarity.tsb] Heartbeat task '" .. name .. "' error: " .. tostring(err))
            end
        end
    end)

    MasterInput = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local action = InputActions[input.KeyCode]
            if action then
                local ok, err = pcall(action)
                if not ok then
                    warn("[rarity.tsb] Input action error: " .. tostring(err))
                end
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
            local action = InputActions[input.UserInputType]
            if action then
                local ok, err = pcall(action)
                if not ok then
                    warn("[rarity.tsb] Input action error: " .. tostring(err))
                end
            end
        end
    end)

    MasterStepped = RunService.Stepped:Connect(function()
        for name, fn in pairs(SteppedTasks) do
            local ok, err = pcall(fn)
            if not ok then
                warn("[rarity.tsb] Stepped task '" .. name .. "' error: " .. tostring(err))
            end
        end
    end)
end

local function StopMasterConnections()
    if MasterHeartbeat then MasterHeartbeat:Disconnect() MasterHeartbeat = nil end
    HeartbeatTasks = {}
    if MasterInput then MasterInput:Disconnect() MasterInput = nil end
    InputActions = {}
    if MasterStepped then MasterStepped:Disconnect() MasterStepped = nil end
    SteppedTasks = {}
end

StartMasterConnections()

-- ==========================================
-- NOTIFICATION SYSTEM
-- ==========================================
local Notify = (function()
    local NotifGui = Instance.new("ScreenGui")
    NotifGui.Name = "RarityTSBNotifications"
    NotifGui.ResetOnSpawn = false
    NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotifGui.DisplayOrder = 100
    NotifGui.Parent = playerGui

    local NotifContainer = Instance.new("Frame")
    NotifContainer.Name = "NotifContainer"
    NotifContainer.Size = UDim2.new(0, 280, 1, -20)
    NotifContainer.Position = UDim2.new(1, -290, 0, 10)
    NotifContainer.BackgroundTransparency = 1
    NotifContainer.Parent = NotifGui
    local NotifLayout = Instance.new("UIListLayout")
    NotifLayout.Padding = UDim.new(0, 6)
    NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifLayout.Parent = NotifContainer

    _G.UpdateNotificationTheme = function(t)
        _G.CurrentNotifColors = {
            Primary = t.Primary,
            Stroke = t.Stroke,
            Text = t.Text,
            BgImageTransparency = t.BgImageTransparency,
            RowBgTransparency = t.RowBgTransparency
        }
        for _, child in ipairs(NotifContainer:GetChildren()) do
            if child:IsA("ImageLabel") and child.Name == "RarityNotification" then
                child.ImageTransparency = t.BgImageTransparency
                local tint = child:FindFirstChild("Tint")
                if tint then
                    tint.BackgroundColor3 = t.Primary
                    tint.BackgroundTransparency = t.RowBgTransparency
                end
                local stroke = child:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Color = t.Stroke stroke.Thickness = 3 end
                local lbl = child:FindFirstChildOfClass("TextLabel")
                if lbl then lbl.TextColor3 = t.Text end
            end
        end
    end

    _G.CurrentNotifColors = {
        Primary = Color3.fromRGB(45, 20, 70),
        Stroke = Color3.fromRGB(100, 60, 140),
        Text = Color3.fromRGB(255, 255, 255),
        BgImageTransparency = 0,
        RowBgTransparency = 0.4
    }

    return function(text, dur)
        dur = dur or 3
        local colors = _G.CurrentNotifColors
        local f = Instance.new("ImageLabel")
        f.Name = "RarityNotification"
        f.Size = UDim2.new(1, 0, 0, 36)
        f.BackgroundTransparency = 1
        f.ScaleType = Enum.ScaleType.Crop
        f.ImageTransparency = colors.BgImageTransparency
        f.ZIndex = 1
        f.Image = "https://i.pinimg.com/1200x/75/36/a5/7536a5820661ebaa5e7a2fd129d57c3d.jpg"
        f.Parent = NotifContainer
        local tint = Instance.new("Frame", f)
        tint.Name = "Tint"
        tint.Size = UDim2.new(1, 0, 1, 0)
        tint.BackgroundColor3 = colors.Primary
        tint.BackgroundTransparency = colors.RowBgTransparency
        tint.BorderSizePixel = 0
        tint.ZIndex = 2
        local s = Instance.new("UIStroke", f)
        s.Color = colors.Stroke
        s.Thickness = 3
        s.Transparency = 1
        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1,-12,1,0)
        l.Position = UDim2.new(0,12,0,0)
        l.BackgroundTransparency = 1
        l.ZIndex = 3
        l.Text = text
        l.TextColor3 = colors.Text
        l.TextSize = 12
        l.Font = Enum.Font.GothamMedium
        local lStroke = Instance.new("UIStroke", l)
        lStroke.Color = colors.Text
        lStroke.Thickness = 3
        lStroke.Transparency = 0.7
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTransparency = 1
        TweenService:Create(tint,TweenInfo.new(0.3),{BackgroundTransparency=0.4}):Play()
        TweenService:Create(s,TweenInfo.new(0.3),{Transparency=0.4}):Play()
        TweenService:Create(l,TweenInfo.new(0.3),{TextTransparency=0}):Play()
        task.delay(dur, function()
            TweenService:Create(tint,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
            TweenService:Create(s,TweenInfo.new(0.3),{Transparency=1}):Play()
            TweenService:Create(l,TweenInfo.new(0.3),{TextTransparency=1}):Play()
            TweenService:Create(f,TweenInfo.new(0.3),{ImageTransparency=1}):Play()
            task.wait(0.3)
            pcall(function() f:Destroy() end)
        end)
    end
end)()

-- ==========================================
-- THEME SYSTEM
-- ==========================================
local Themes = {
    Rarity = {
        Name = "Rarity",
        Primary = Color3.fromRGB(45, 20, 70),
        Secondary = Color3.fromRGB(60, 30, 95),
        Accent = Color3.fromRGB(74, 23, 103),
        Highlight = Color3.fromRGB(125, 209, 245),
        Button = Color3.fromRGB(90, 55, 130),
        ButtonHover = Color3.fromRGB(125, 209, 245),
        ToggleOff = Color3.fromRGB(90, 55, 130),
        ToggleOn = Color3.fromRGB(125, 209, 245),
        ToggleCircleOff = Color3.fromRGB(100, 70, 130),
        ToggleCircleOn = Color3.new(1, 1, 1),
        Text = Color3.fromRGB(255, 255, 255),
        RowBg = Color3.fromRGB(45, 20, 70),
        RowBgTransparency = 0.6,
        Separator = Color3.fromRGB(180, 160, 220),
        Stroke = Color3.fromRGB(100, 60, 140),
        DropdownBg = Color3.fromRGB(60, 30, 95),
        DropdownBtn = Color3.fromRGB(75, 45, 110),
        DropdownBtnHover = Color3.fromRGB(125, 209, 245),
        InputBg = Color3.fromRGB(75, 45, 110),
        SliderTrack = Color3.fromRGB(90, 55, 130),
        SliderFill = Color3.fromRGB(125, 209, 245),
        BgImage = "https://i.pinimg.com/736x/08/18/77/0818775090ee00b2d5d0e67c735249cc.jpg",
        BgImageTransparency = 0,
        TitleBarTransparency = 0.25,
        TabsFrameTransparency = 0.25,
        MainFrameTransparency = 1,
    },
    Fluttershy = {
        Name = "Fluttershy",
        Primary = Color3.fromRGB(90, 60, 40),
        Secondary = Color3.fromRGB(120, 85, 55),
        Accent = Color3.fromRGB(180, 140, 80),
        Highlight = Color3.fromRGB(255, 220, 100),
        Button = Color3.fromRGB(160, 120, 70),
        ButtonHover = Color3.fromRGB(255, 200, 80),
        ToggleOff = Color3.fromRGB(120, 90, 50),
        ToggleOn = Color3.fromRGB(255, 200, 50),
        ToggleCircleOff = Color3.fromRGB(140, 110, 60),
        ToggleCircleOn = Color3.new(1, 1, 1),
        Text = Color3.fromRGB(255, 255, 255),
        RowBg = Color3.fromRGB(90, 60, 40),
        RowBgTransparency = 0.6,
        Separator = Color3.fromRGB(120, 200, 120),
        Stroke = Color3.fromRGB(100, 180, 100),
        DropdownBg = Color3.fromRGB(120, 85, 55),
        DropdownBtn = Color3.fromRGB(140, 100, 60),
        DropdownBtnHover = Color3.fromRGB(255, 200, 80),
        InputBg = Color3.fromRGB(140, 100, 60),
        SliderTrack = Color3.fromRGB(160, 120, 70),
        SliderFill = Color3.fromRGB(255, 220, 100),
        BgImage = "https://i.pinimg.com/736x/99/4e/43/994e43c38bcc8e92795b47ba087ec654.jpg",
        BgImageTransparency = 0,
        TitleBarTransparency = 0.25,
        TabsFrameTransparency = 0.25,
        MainFrameTransparency = 1,
    }
}
local CurrentTheme = "Rarity"
local ThemeButtons = {}

-- ==========================================
-- COOLDOWN TRACKERS GUI
-- ==========================================
local CooldownGui = Instance.new("ScreenGui")
CooldownGui.Name = "RarityTSBCooldowns"
CooldownGui.ResetOnSpawn = false
CooldownGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
CooldownGui.DisplayOrder = 99
CooldownGui.Parent = playerGui
CooldownGui.Enabled = false

local CooldownBars = {}
local CooldownData = {
    FrontBack = {Name = "Front/Back Dash", Max = 5, Current = 0, Active = false, LastUse = 0},
    Side = {Name = "Side Dash", Max = 2, Current = 0, Active = false, LastUse = 0},
    Evasive = {Name = "Evasive", Max = 30, Current = 0, Active = false, LastUse = 0},
}

local function CreateCooldownBar(name, order)
    local barFrame = Instance.new("Frame")
    barFrame.Size = UDim2.new(0, 180, 0, 20)
    barFrame.Position = UDim2.new(0, 10, 0, 10 + (order * 26))
    barFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    barFrame.BorderSizePixel = 0
    barFrame.Parent = CooldownGui
    Instance.new("UICorner", barFrame).CornerRadius = UDim.new(0, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    fill.BorderSizePixel = 0
    fill.Parent = barFrame
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = barFrame

    return {Frame = barFrame, Fill = fill, Label = lbl}
end

CooldownBars.FrontBack = CreateCooldownBar("Front/Back Dash", 0)
CooldownBars.Side = CreateCooldownBar("Side Dash", 1)
CooldownBars.Evasive = CreateCooldownBar("Evasive", 2)

local function UpdateCooldownBars(dt)
    for key, data in pairs(CooldownData) do
        if data.Active then
            data.Current = math.max(0, data.Current - dt)
            if data.Current <= 0.05 then
                data.Active = false
                data.Current = 0
            end
        end
        local bar = CooldownBars[key]
        if bar then
            local pct = data.Current / data.Max
            bar.Fill.Size = UDim2.new(pct, 0, 1, 0)
            bar.Fill.BackgroundColor3 = pct > 0.3 and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 100)
            bar.Label.Text = string.format("%s: %.1fs", data.Name, data.Current)
            local anyTracker = Features.TrackFrontDash.E or Features.TrackSideDash.E or Features.TrackEvasive.E
            bar.Frame.Visible = anyTracker and (data.Active or data.Current > 0)
        end
    end
end

RegisterHeartbeatTask("CooldownBars", UpdateCooldownBars)

-- ==========================================
-- GUI SETUP (IIFE)
-- ==========================================
local UI = (function()
    local ui = {}
    local ApplyTheme

    for _, child in ipairs(playerGui:GetChildren()) do
        if child.Name == "rarity.tsb" then child:Destroy() end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "rarity.tsb"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = playerGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0,400,0,520)
    MainFrame.Position = UDim2.new(0.5,-200,0.5,-260)
    MainFrame.BackgroundColor3 = Themes[CurrentTheme].Primary
    MainFrame.BackgroundTransparency = 1
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = false
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    local MStroke = Instance.new("UIStroke",MainFrame)
    MStroke.Color = Themes[CurrentTheme].Accent
    MStroke.Thickness = 3

    local BgImage = Instance.new("ImageLabel")
    BgImage.Name = "BgImage"
    BgImage.Size = UDim2.new(1, 0, 1, 0)
    BgImage.Position = UDim2.new(0, 0, 0, 0)
    BgImage.BackgroundTransparency = 1
    BgImage.ScaleType = Enum.ScaleType.Crop
    BgImage.ImageTransparency = 0
    BgImage.ZIndex = 0
    BgImage.Parent = MainFrame
    BgImage.AnchorPoint = Vector2.new(0, 1)
    BgImage.Position = UDim2.new(0, 0, 1, 0)

    local IMAGE_URL = "https://i.pinimg.com/736x/08/18/77/0818775090ee00b2d5d0e67c735249cc.jpg"
    local IMAGE_PATH = "rarity.tsb/bg.jpg"
    local IMAGE_LOADED = false

    local function loadImageViaCustomAsset(url, path)
        if not type(getcustomasset) == "function" then return false end
        if not type(writefile) == "function" then return false end
        if not type(isfile) == "function" then return false end
        if isfile(path) then
            local ok, assetId = pcall(getcustomasset, path)
            if ok and assetId then
                BgImage.Image = assetId
                IMAGE_LOADED = true
                return true
            end
        end
        local ok, data = pcall(function() return game:HttpGet(url) end)
        if ok and data and #data > 1000 then
            local writeOk = pcall(function() writefile(path, data) end)
            if writeOk then
                task.wait(0.1)
                local assetOk, assetId = pcall(getcustomasset, path)
                if assetOk and assetId then
                    BgImage.Image = assetId
                    IMAGE_LOADED = true
                    return true
                end
            end
        end
        return false
    end

    task.spawn(function()
        local attempts = 0
        while not IMAGE_LOADED and attempts < 3 do
            attempts = attempts + 1
            if loadImageViaCustomAsset(IMAGE_URL, IMAGE_PATH) then break end
            task.wait(0.5)
        end
        if not IMAGE_LOADED then BgImage.Image = IMAGE_URL end
    end)

    ui.MainFrame = MainFrame
    ui.ScreenGui = ScreenGui

    -- Dragging
    local Dragging = false
    local DragStart = nil
    local StartPos = nil

    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1,0,0,35)
    TitleBar.BackgroundColor3 = Themes[CurrentTheme].Secondary
    TitleBar.BackgroundTransparency = 0.25
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleText = Instance.new("TextLabel",TitleBar)
    TitleText.Size = UDim2.new(1,-15,1,0)
    TitleText.Position = UDim2.new(0,15,0,0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "▼ rarity.tsb ⚡"
    TitleText.TextColor3 = Themes[CurrentTheme].Text
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
            MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end
    end)

    local TabsFrame = Instance.new("Frame")
    TabsFrame.Size = UDim2.new(1,0,0,66)
    TabsFrame.Position = UDim2.new(0,0,0,35)
    TabsFrame.BackgroundColor3 = Themes[CurrentTheme].Secondary
    TabsFrame.BackgroundTransparency = 0.25
    TabsFrame.BorderSizePixel = 0
    TabsFrame.Parent = MainFrame

    local TabSep = Instance.new("Frame", TabsFrame)
    TabSep.Size = UDim2.new(1,0,0,2)
    TabSep.Position = UDim2.new(0,0,0,32)
    TabSep.BackgroundColor3 = Themes[CurrentTheme].Separator
    TabSep.BorderSizePixel = 0

    local TabNames = {"Combat","ESP","Movement","QoL","Players","Server","Settings"}
    local TabButtons = {}
    local TabContents = {}
    local ActiveTab = "Combat"
    ui.ActiveTab = function() return ActiveTab end
    ui.SetActiveTab = function(v) ActiveTab = v end

    for i,name in ipairs(TabNames) do
        local btn = Instance.new("TextButton")
        local col = (i-1) % 4
        local row = math.floor((i-1)/4)
        btn.Size = UDim2.new(1/4,-4,0,28)
        btn.Position = UDim2.new((1/4)*col,2,0,row*32 + 2)
        btn.BackgroundTransparency = 1
        btn.Text = name
        btn.TextColor3 = Themes[CurrentTheme].Text
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamMedium
        btn.Parent = TabsFrame
        local line = Instance.new("Frame",btn)
        line.Size = UDim2.new(0.8,0,0,2)
        line.Position = UDim2.new(0.1,0,1,-2)
        line.BackgroundColor3 = Themes[CurrentTheme].Text
        line.BorderSizePixel = 0
        line.Visible = name=="Combat"
        TabButtons[name] = {Button=btn,Line=line}

        local content = Instance.new("ScrollingFrame")
        content.Size = UDim2.new(1,-30,1,-117)
        content.Position = UDim2.new(0,15,0,107)
        content.BackgroundTransparency = 1
        content.Visible = name=="Combat"
        content.Parent = MainFrame
        content.ScrollBarThickness = 4
        content.ScrollingDirection = Enum.ScrollingDirection.Y
        content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        content.CanvasSize = UDim2.new(0,0,0,0)
        TabContents[name] = content

        btn.MouseButton1Click:Connect(function()
            for n,t in pairs(TabButtons) do
                t.Button.TextColor3 = Themes[CurrentTheme].Text
                t.Line.Visible = false
                TabContents[n].Visible = false
            end
            btn.TextColor3 = Themes[CurrentTheme].Text
            line.Visible = true
            content.Visible = true
            ActiveTab = name
            local ts = UDim2.new(0,400,0,520)
            if name=="ESP" then ts = UDim2.new(0,400,0,420)
            elseif name=="Movement" then ts = UDim2.new(0,400,0,520)
            elseif name=="QoL" then ts = UDim2.new(0,400,0,420)
            elseif name=="Players" then ts = UDim2.new(0,400,0,480)
            elseif name=="Server" then ts = UDim2.new(0,400,0,440)
            elseif name=="Settings" then ts = UDim2.new(0,400,0,420) end
            TweenService:Create(MainFrame,TweenInfo.new(0.3),{Size=ts}):Play()
        end)
    end

    -- GUI Helper Functions
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
        t.TextColor3 = Themes[CurrentTheme].Text
        t.TextSize = 12
        t.Font = Enum.Font.GothamBold
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextYAlignment = Enum.TextYAlignment.Center
        local tStroke = Instance.new("UIStroke", t)
        tStroke.Color = Themes[CurrentTheme].Text
        tStroke.Thickness = 2
        tStroke.Transparency = 0.7
        local ln = Instance.new("Frame",sec)
        ln.Size = UDim2.new(1,-90,0,2)
        ln.Position = UDim2.new(0,85,0.6,0)
        ln.BackgroundColor3 = Themes[CurrentTheme].Separator
        ln.BackgroundTransparency = 0.4
        ln.BorderSizePixel = 0
        return posY+28
    end

    local function CreateToggle(parent,text,posY,featName,hasKeybind)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,0,0,32)
        row.Position = UDim2.new(0,0,0,posY)
        row.BackgroundColor3 = Themes[CurrentTheme].RowBg
        row.BackgroundTransparency = Themes[CurrentTheme].RowBgTransparency
        row.Parent = parent
        table.insert(ThemeButtons, {Btn = row, Type = "RowBg"})
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
        local lbl = Instance.new("TextLabel",row)
        lbl.Size = UDim2.new(hasKeybind and 0.5 or 0.7,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Themes[CurrentTheme].Text
        lbl.TextSize = 13
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        local lblStroke = Instance.new("UIStroke", lbl)
        lblStroke.Color = Themes[CurrentTheme].Text
        lblStroke.Thickness = 2
        lblStroke.Transparency = 0.7

        local keybindBtn = nil
        if hasKeybind then
            keybindBtn = Instance.new("TextButton", row)
            keybindBtn.Size = UDim2.new(0, 40, 0, 20)
            keybindBtn.Position = UDim2.new(0.7, 0, 0.5, -10)
            keybindBtn.BackgroundColor3 = Themes[CurrentTheme].InputBg
            keybindBtn.Text = "Bind"
            keybindBtn.TextColor3 = Themes[CurrentTheme].Text
            keybindBtn.TextSize = 10
            keybindBtn.Font = Enum.Font.Gotham
            keybindBtn.AutoButtonColor = false
            Instance.new("UICorner", keybindBtn).CornerRadius = UDim.new(0, 4)
            table.insert(ThemeButtons, {Btn = keybindBtn, Type = "Keybind"})
        end

        local tbg = Instance.new("TextButton",row)
        tbg.Size = UDim2.new(0,36,0,20)
        tbg.Position = UDim2.new(1,-36,0.5,-10)
        tbg.BackgroundColor3 = Themes[CurrentTheme].ToggleOff
        tbg.Text = ""
        tbg.AutoButtonColor = false
        Instance.new("UICorner",tbg).CornerRadius = UDim.new(1,0)
        local circ = Instance.new("Frame",tbg)
        circ.Size = UDim2.new(0,16,0,16)
        circ.Position = UDim2.new(0,2,0,2)
        circ.BackgroundColor3 = Themes[CurrentTheme].ToggleCircleOff
        circ.BorderSizePixel = 0
        Instance.new("UICorner",circ).CornerRadius = UDim.new(1,0)
        local sd = Instance.new("TextLabel",row)
        sd.Size = UDim2.new(0,10,0,10)
        sd.Position = UDim2.new(0.7,-15,0.5,-5)
        sd.BackgroundTransparency = 1
        sd.Text = "●"
        sd.TextColor3 = Themes[CurrentTheme].Text
        sd.TextSize = 8
        sd.Visible = false
        return tbg, circ, sd, posY+36, row, keybindBtn
    end

    local function CreateButton(parent,text,posY,bName)
        local btn = Instance.new("TextButton")
        btn.Name = bName
        btn.Size = UDim2.new(1,0,0,32)
        btn.Position = UDim2.new(0,0,0,posY)
        btn.BackgroundColor3 = Themes[CurrentTheme].Button
        btn.Text = text
        btn.TextColor3 = Themes[CurrentTheme].Text
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamMedium
        btn.AutoButtonColor = false
        btn.Parent = parent
        Instance.new("UICorner",btn).CornerRadius = UDim.new(0,6)
        table.insert(ThemeButtons, {Btn = btn, Type = "Button"})
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Themes[CurrentTheme].ButtonHover end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Themes[CurrentTheme].Button end)
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
        lbl.TextColor3 = Themes[CurrentTheme].Text
        lbl.TextSize = 13
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        local vl = Instance.new("TextLabel",lr)
        vl.Size = UDim2.new(0.3,0,1,0)
        vl.Position = UDim2.new(0.7,0,0,0)
        vl.BackgroundTransparency = 1
        vl.Text = tostring(val)
        vl.TextColor3 = Themes[CurrentTheme].Text
        vl.TextSize = 13
        vl.Font = Enum.Font.GothamSemibold
        vl.TextXAlignment = Enum.TextXAlignment.Right
        local trk = Instance.new("TextButton",row)
        trk.Size = UDim2.new(1,0,0,8)
        trk.Position = UDim2.new(0,0,0,26)
        trk.BackgroundColor3 = Themes[CurrentTheme].SliderTrack
        trk.Text = ""
        trk.AutoButtonColor = false
        Instance.new("UICorner",trk).CornerRadius = UDim.new(1,0)
        local fl = Instance.new("Frame",trk)
        fl.Size = UDim2.new((val-min)/(max-min),0,1,0)
        fl.BackgroundColor3 = Themes[CurrentTheme].SliderFill
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
        trk.MouseButton1Down:Connect(function() d = true upd(Mouse.X) end)
        UserInputService.InputChanged:Connect(function(i)
            if d and i.UserInputType == Enum.UserInputType.MouseMovement then upd(Mouse.X) end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end
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
        row.BackgroundColor3 = Themes[CurrentTheme].RowBg
        row.BackgroundTransparency = Themes[CurrentTheme].RowBgTransparency
        row.Parent = parent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
        local lbl = Instance.new("TextLabel",row)
        lbl.Size = UDim2.new(0.4,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Themes[CurrentTheme].Text
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        local lblStroke = Instance.new("UIStroke", lbl)
        lblStroke.Color = Themes[CurrentTheme].Text
        lblStroke.Thickness = 2
        lblStroke.Transparency = 0.7
        local box = Instance.new("TextBox",row)
        box.Size = UDim2.new(0.6,-5,1,-4)
        box.Position = UDim2.new(0.4,5,0,2)
        box.BackgroundColor3 = Themes[CurrentTheme].InputBg
        box.TextColor3 = Themes[CurrentTheme].Text
        box.PlaceholderText = placeholder or ""
        box.Text = ""
        box.TextSize = 12
        box.Font = Enum.Font.Gotham
        box.ClearTextOnFocus = false
        Instance.new("UICorner",box).CornerRadius = UDim.new(0,4)
        return box, posY+36
    end

    local function CreateDropdown(parent, posY, labelText, featureName, listZIndex)
        listZIndex = listZIndex or 9999
        local Container = Instance.new("Frame")
        Container.Name = featureName.."Dropdown"
        Container.Size = UDim2.new(1, 0, 0, 28)
        Container.Position = UDim2.new(0, 0, 0, posY)
        Container.BackgroundTransparency = 1
        Container.ZIndex = 50
        Container.Parent = parent

        local Label = Instance.new("TextLabel")
        Label.Size = UDim2.new(0.45, 0, 1, 0)
        Label.BackgroundTransparency = 1
        Label.Text = labelText
        Label.TextColor3 = Themes[CurrentTheme].Text
        Label.TextSize = 12
        Label.Font = Enum.Font.Gotham
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextYAlignment = Enum.TextYAlignment.Center
        local LabelStroke = Instance.new("UIStroke", Label)
        LabelStroke.Color = Themes[CurrentTheme].Text
        LabelStroke.Thickness = 2
        LabelStroke.Transparency = 0.7
        Label.ZIndex = 51
        Label.Parent = Container

        local DropBtn = Instance.new("TextButton")
        DropBtn.Name = "DropBtn"
        DropBtn.Size = UDim2.new(0.55, 0, 1, 0)
        DropBtn.Position = UDim2.new(0.45, 0, 0, 0)
        DropBtn.BackgroundColor3 = Themes[CurrentTheme].Button
        DropBtn.Text = "None"
        DropBtn.TextColor3 = Themes[CurrentTheme].Text
        DropBtn.TextSize = 11
        DropBtn.Font = Enum.Font.GothamMedium
        DropBtn.AutoButtonColor = false
        DropBtn.ZIndex = 51
        DropBtn.Parent = Container

        Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 6)
        table.insert(ThemeButtons, {Btn = DropBtn, Type = "DropBtn"})

        local ListFrame = Instance.new("ScrollingFrame")
        ListFrame.Name = featureName.."List"
        ListFrame.Size = UDim2.new(0, 200, 0, 0)
        ListFrame.Position = UDim2.new(0, 0, 0, 0)
        ListFrame.BackgroundColor3 = Themes[CurrentTheme].DropdownBg
        ListFrame.BorderSizePixel = 0
        ListFrame.Visible = false
        ListFrame.ZIndex = listZIndex
        ListFrame.ScrollBarThickness = 3
        ListFrame.ScrollBarImageColor3 = Themes[CurrentTheme].Stroke
        ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        ListFrame.Parent = ScreenGui

        Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 6)

        local ListStroke = Instance.new("UIStroke")
        ListStroke.Color = Themes[CurrentTheme].DropdownBtn
        ListStroke.Thickness = 2
        ListStroke.Parent = ListFrame

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 2)
        ListLayout.Parent = ListFrame

        local currentSelection = nil
        local optionButtons = {}
        local open = false
        local FIXED_LIST_WIDTH = 200
        local MAX_LIST_HEIGHT = 200
        local ROW_HEIGHT = 26

        local function updateListPosition()
            task.defer(function()
                if not DropBtn or not DropBtn.Parent then return end
                local absPos = DropBtn.AbsolutePosition
                local absSize = DropBtn.AbsoluteSize
                if absSize.X > 0 then FIXED_LIST_WIDTH = absSize.X end
                ListFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
                local count = 0
                for _ in pairs(optionButtons) do count = count + 1 end
                local h = math.min(count * ROW_HEIGHT + 4, MAX_LIST_HEIGHT)
                ListFrame.Size = UDim2.new(0, FIXED_LIST_WIDTH, 0, h)
            end)
        end

        local function rebuildList(options)
            for _, btn in pairs(optionButtons) do btn:Destroy() end
            optionButtons = {}
            for _, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, -8, 0, 24)
                optBtn.Position = UDim2.new(0, 4, 0, 0)
                optBtn.BackgroundColor3 = Themes[CurrentTheme].DropdownBtn
                optBtn.Text = "  " .. opt
                optBtn.TextColor3 = Themes[CurrentTheme].Text
                local optBtnStroke = Instance.new("UIStroke", optBtn)
                optBtnStroke.Color = Themes[CurrentTheme].Text
                optBtnStroke.Thickness = 2
                optBtnStroke.Transparency = 0.7
                optBtn.TextSize = 11
                optBtn.Font = Enum.Font.Gotham
                optBtn.TextXAlignment = Enum.TextXAlignment.Left
                optBtn.AutoButtonColor = false
                optBtn.ZIndex = listZIndex + 1
                optBtn.Parent = ListFrame
                Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 4)
                optBtn.MouseButton1Click:Connect(function()
                    currentSelection = opt
                    DropBtn.Text = opt
                    open = false
                    ListFrame.Visible = false
                end)
                optionButtons[opt] = optBtn
            end
            local count = #options
            local h = math.min(count * ROW_HEIGHT + 4, MAX_LIST_HEIGHT)
            ListFrame.Size = UDim2.new(0, FIXED_LIST_WIDTH, 0, h)
            ListFrame.CanvasSize = UDim2.new(0, 0, 0, count * ROW_HEIGHT + 8)
        end

        DropBtn.MouseButton1Click:Connect(function()
            open = not open
            if open then updateListPosition() end
            ListFrame.Visible = open
        end)

        local clickAwayConn = nil
        clickAwayConn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                if open then
                    local mousePos = UserInputService:GetMouseLocation()
                    local listPos = ListFrame.AbsolutePosition
                    local listSize = ListFrame.AbsoluteSize
                    local btnPos = DropBtn.AbsolutePosition
                    local btnSize = DropBtn.AbsoluteSize
                    local inList = mousePos.X >= listPos.X and mousePos.X <= listPos.X + listSize.X
                        and mousePos.Y >= listPos.Y and mousePos.Y <= listPos.Y + listSize.Y
                    local inBtn = mousePos.X >= btnPos.X and mousePos.X <= btnPos.X + btnSize.X
                        and mousePos.Y >= btnPos.Y and mousePos.Y <= btnPos.Y + btnSize.Y
                    if not inList and not inBtn then
                        open = false
                        ListFrame.Visible = false
                    end
                end
            end
        end)

        RegisterHeartbeatTask("TabHide_" .. featureName, function()
            if open and Container and Container.Parent then
                if not Container.Parent.Visible then
                    open = false
                    ListFrame.Visible = false
                end
            end
        end)

        Container.Destroying:Connect(function()
            if clickAwayConn then clickAwayConn:Disconnect() end
            if ListFrame then ListFrame:Destroy() end
        end)

        return {
            Frame = Container,
            Rebuild = rebuildList,
            GetSelected = function() return currentSelection end,
            SetSelected = function(name)
                currentSelection = name
                DropBtn.Text = name or "None"
            end
        }, posY + 34
    end

    -- ==========================================
    -- COMBAT TAB
    -- ==========================================
    local CombatC = TabContents["Combat"]
    local cy = 0
    cy = CreateSection(CombatC,"Combat",cy)
    ui.AutoM1TradeT, ui.AutoM1TradeC, ui.AutoM1TradeS, cy, _, ui.AutoM1TradeKb = CreateToggle(CombatC,"Auto M1 Trade",cy,"AutoM1Trade", true)
    ui.AutoBlockT, ui.AutoBlockC, ui.AutoBlockS, cy, _, ui.AutoBlockKb = CreateToggle(CombatC,"Auto Block",cy,"AutoBlock", true)
    ui.AimlockT, ui.AimlockC, ui.AimlockS, cy, _, ui.AimlockKb = CreateToggle(CombatC,"Aimlock",cy,"Aimlock", true)
    cy = cy + 4
    ui.AimlockSmoothRow, ui.GetAimlockSmooth, cy, ui.SetAimlockSmooth = CreateSlider(CombatC,"Aimlock Smoothness",cy,1,10,5,function(v) AimlockSmoothness = v/10 end)
    ui.AimlockPredRow, ui.GetAimlockPred, cy, ui.SetAimlockPred = CreateSlider(CombatC,"Aimlock Prediction",cy,0,30,5,function(v) AimlockPrediction = v/10 end)
    cy = cy + 8
    cy = CreateSection(CombatC,"Combat Mods",cy+5)
    ui.NoStunT, ui.NoStunC, ui.NoStunS, cy = CreateToggle(CombatC,"No Stun (Doesn't work rn)",cy,"NoStun")
    ui.NoDashCooldownT, ui.NoDashCooldownC, ui.NoDashCooldownS, cy = CreateToggle(CombatC,"No Dash Cooldown (Doesn't work rn)",cy,"NoDashCooldown")

    ui.InvisibilityT, ui.InvisibilityC, ui.InvisibilityS, cy = CreateToggle(CombatC,"Invisibility",cy,"Invisibility")
    ui.AntiDeathCounterT, ui.AntiDeathCounterC, ui.AntiDeathCounterS, cy = CreateToggle(CombatC,"Anti Death Counter",cy,"AntiDeathCounter")
    cy = CreateSection(CombatC,"Cooldown Trackers",cy+5)
    ui.TrackEvasiveT, ui.TrackEvasiveC, ui.TrackEvasiveS, cy = CreateToggle(CombatC,"Track Evasive",cy,"TrackEvasive")
    ui.TrackFrontDashT, ui.TrackFrontDashC, ui.TrackFrontDashS, cy = CreateToggle(CombatC,"Track Front/Back Dash",cy,"TrackFrontDash")
    ui.TrackSideDashT, ui.TrackSideDashC, ui.TrackSideDashS, cy = CreateToggle(CombatC,"Track Side Dash",cy,"TrackSideDash")

    -- ==========================================
    -- ESP TAB
    -- ==========================================
    local EspC = TabContents["ESP"]
    local ey = 0
    ey = CreateSection(EspC,"Player ESP",ey)
    ui.EspT, ui.EspCir, ui.EspS, ey = CreateToggle(EspC,"Player ESP",ey,"ESP")
    ui.TracersT, ui.TracersC, ui.TracersS, ey = CreateToggle(EspC,"Tracers",ey,"Tracers")
    ui.ChamsT, ui.ChamsC, ui.ChamsS, ey = CreateToggle(EspC,"Chams",ey,"Chams")
    ey = ey + 4
    -- ESP Color TextBoxes (Bridger style)
    local espColorFrame = Instance.new("Frame")
    espColorFrame.Size = UDim2.new(1, 0, 0, 32)
    espColorFrame.Position = UDim2.new(0, 0, 0, ey)
    espColorFrame.BackgroundTransparency = 1
    espColorFrame.Parent = EspC

    local espColorLbl = Instance.new("TextLabel", espColorFrame)
    espColorLbl.Size = UDim2.new(0.25, 0, 1, 0)
    espColorLbl.BackgroundTransparency = 1
    espColorLbl.Text = "ESP Color"
    espColorLbl.TextColor3 = Themes[CurrentTheme].Text
    espColorLbl.TextSize = 12
    espColorLbl.Font = Enum.Font.Gotham
    espColorLbl.TextXAlignment = Enum.TextXAlignment.Left

    local function MakeColorBox(name, default, xPos, colorFunc)
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0.22, -4, 0.8, 0)
        box.Position = UDim2.new(xPos, 2, 0.1, 0)
        box.BackgroundColor3 = Themes[CurrentTheme].InputBg
        box.TextColor3 = Themes[CurrentTheme].Text
        box.Text = tostring(default)
        box.PlaceholderText = name
        box.TextSize = 11
        box.Font = Enum.Font.Gotham
        box.ClearTextOnFocus = false
        box.Parent = espColorFrame
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

        box.FocusLost:Connect(function()
            local num = tonumber(box.Text)
            if num then
                num = math.clamp(math.floor(num), 0, 255)
                box.Text = tostring(num)
                colorFunc(num)
            else
                box.Text = tostring(default)
            end
        end)
        return box
    end

    ui.ESPColorRBox = MakeColorBox("R", 147, 0.25, function(v)
        ESPColor = Color3.fromRGB(v, math.floor(ESPColor.G * 255), math.floor(ESPColor.B * 255))
        if ui.ESPColorGBox then ui.ESPColorGBox.Text = tostring(math.floor(ESPColor.G * 255)) end
        if ui.ESPColorBBox then ui.ESPColorBBox.Text = tostring(math.floor(ESPColor.B * 255)) end
    end)
    ui.ESPColorGBox = MakeColorBox("G", 0, 0.48, function(v)
        ESPColor = Color3.fromRGB(math.floor(ESPColor.R * 255), v, math.floor(ESPColor.B * 255))
        if ui.ESPColorRBox then ui.ESPColorRBox.Text = tostring(math.floor(ESPColor.R * 255)) end
        if ui.ESPColorBBox then ui.ESPColorBBox.Text = tostring(math.floor(ESPColor.B * 255)) end
    end)
    ui.ESPColorBBox = MakeColorBox("B", 211, 0.71, function(v)
        ESPColor = Color3.fromRGB(math.floor(ESPColor.R * 255), math.floor(ESPColor.G * 255), v)
        if ui.ESPColorRBox then ui.ESPColorRBox.Text = tostring(math.floor(ESPColor.R * 255)) end
        if ui.ESPColorGBox then ui.ESPColorGBox.Text = tostring(math.floor(ESPColor.G * 255)) end
    end)

    ey = ey + 40
    ui.ESPColorDropdown, ey = CreateDropdown(EspC, ey, "Color Preset", "ESPColorPreset", 9995)
    ui.ESPColorDropdown.Rebuild({"Red", "Green", "Blue", "Purple", "Cyan", "Yellow", "White", "Pink"})

    -- ==========================================
    -- MOVEMENT TAB
    -- ==========================================
    local MovC = TabContents["Movement"]
    local mvy = 0
    mvy = CreateSection(MovC,"Movement",mvy)
    ui.ClickTpT, ui.ClickTpC, ui.ClickTpS, mvy, _, ui.ClickTpKb = CreateToggle(MovC,"Click Teleport",mvy,"ClickTp", true)
    ui.FlyT, ui.FlyC, ui.FlyS, mvy, _, ui.FlyKb = CreateToggle(MovC,"Fly",mvy,"Fly", true)
    mvy = mvy + 4
    ui.SpeedRow, ui.GetFlySpeed, mvy, ui.SetFlySpeed = CreateSlider(MovC,"Fly Speed",mvy,10,100,24,function(v) FlySpeed = v end)
    mvy = mvy + 4
    ui.FlyMultRow, ui.GetFlyMult, mvy, ui.SetFlyMult = CreateSlider(MovC,"Fly Mult (press Left Alt)",mvy,10,50,20,function(v) FlySpeedMultiplier = v/10 end)
    mvy = mvy + 8
    ui.SpeedHackT, ui.SpeedHackC, ui.SpeedHackS, mvy, _, ui.SpeedHackKb = CreateToggle(MovC,"Speed Hack",mvy,"SpeedHack", true)
    mvy = mvy + 4
    ui.SpeedHackRow, ui.GetSpeedHack, mvy, ui.SetSpeedHack = CreateSlider(MovC,"Speed Value",mvy,1,200,50,function(v) SpeedHackValue = v end)
    mvy = mvy + 8
    ui.NoClipT, ui.NoClipC, ui.NoClipS, mvy, _, ui.NoClipKb = CreateToggle(MovC,"No Clip",mvy,"NoClip", true)

    -- ==========================================
    -- QOL TAB
    -- ==========================================
    local QoLC = TabContents["QoL"]
    local qolY = 0
    qolY = CreateSection(QoLC,"QoL Features",qolY)
    ui.SafeModeT, ui.SafeModeC, ui.SafeModeS, qolY, _, ui.SafeModeKb = CreateToggle(QoLC,"Safe Mode",qolY,"SafeMode", true)
    qolY = qolY + 4
    ui.SafeModeRow, ui.GetSafeModeHP, qolY, ui.SetSafeModeHP = CreateSlider(QoLC,"Safe Mode HP %",qolY,1,50,30,function(v) SafeModeHP = v end)
    qolY = qolY + 8
    ui.FullBrightT, ui.FullBrightC, ui.FullBrightS, qolY = CreateToggle(QoLC,"Full Brightness",qolY,"FullBright")
    qolY = qolY + 4
    ui.FullBrightRow, ui.GetFullBright, qolY, ui.SetFullBright = CreateSlider(QoLC,"Brightness",qolY,0,10,3,function(v) FullBrightValue = v end)

    -- ==========================================
    -- PLAYERS TAB
    -- ==========================================
    local PnC = TabContents["Players"]
    local pny = 0
    pny = CreateSection(PnC,"Players",pny)
    ui.PlayersDropdown, pny = CreateDropdown(PnC, pny, "Target", "PlayersTarget", 9998)
    ui.PlayersDropdown.Frame.Size = UDim2.new(0.58, -4, 0, 28)

    ui.TeleportPlayerBtn = Instance.new("TextButton")
    ui.TeleportPlayerBtn.Name = "TeleportPlayerBtn"
    ui.TeleportPlayerBtn.Size = UDim2.new(0.4, -2, 0, 28)
    ui.TeleportPlayerBtn.Position = UDim2.new(0.58, 2, 0, pny - 34)
    ui.TeleportPlayerBtn.BackgroundColor3 = Themes[CurrentTheme].Button
    ui.TeleportPlayerBtn.Text = "Teleport"
    ui.TeleportPlayerBtn.TextColor3 = Themes[CurrentTheme].Text
    ui.TeleportPlayerBtn.TextSize = 11
    ui.TeleportPlayerBtn.Font = Enum.Font.GothamMedium
    ui.TeleportPlayerBtn.AutoButtonColor = false
    ui.TeleportPlayerBtn.Parent = PnC
    Instance.new("UICorner", ui.TeleportPlayerBtn).CornerRadius = UDim.new(0, 6)
    table.insert(ThemeButtons, {Btn = ui.TeleportPlayerBtn, Type = "Button"})
    ui.TeleportPlayerBtn.MouseEnter:Connect(function() ui.TeleportPlayerBtn.BackgroundColor3 = Themes[CurrentTheme].ButtonHover end)
    ui.TeleportPlayerBtn.MouseLeave:Connect(function() ui.TeleportPlayerBtn.BackgroundColor3 = Themes[CurrentTheme].Button end)

    ui.PlayerHealthLbl = Instance.new("TextLabel")
    ui.PlayerHealthLbl.Size = UDim2.new(1, 0, 0, 20)
    ui.PlayerHealthLbl.Position = UDim2.new(0, 0, 0, pny)
    ui.PlayerHealthLbl.BackgroundTransparency = 1
    ui.PlayerHealthLbl.Text = "Health: --"
    ui.PlayerHealthLbl.TextColor3 = Themes[CurrentTheme].Text
    ui.PlayerHealthLbl.TextSize = 12
    ui.PlayerHealthLbl.Font = Enum.Font.Gotham
    ui.PlayerHealthLbl.TextXAlignment = Enum.TextXAlignment.Left
    ui.PlayerHealthLbl.Parent = PnC
    pny = pny + 24

    pny = CreateSection(PnC, "Exploits", pny + 8)
    ui.VoidKillsT, ui.VoidKillsC, ui.VoidKillsS, pny, _, ui.VoidKillsKb = CreateToggle(PnC, "Void Kills", pny, "VoidKills", true)
    pny = pny + 8
    ui.FlingT, ui.FlingC, ui.FlingS, pny = CreateToggle(PnC, "Fling", pny, "Fling")
    pny = pny + 4
    ui.FlingTargetDropdown, pny = CreateDropdown(PnC, pny, "Fling Target", "FlingTarget", 9994)
    ui.FlingTargetDropdown.Rebuild({"All"})
    ui.FlingTargetDropdown.SetSelected("All")
    ui.AntiFlingT, ui.AntiFlingC, ui.AntiFlingS, pny = CreateToggle(PnC, "Anti Fling", pny, "AntiFling")

    -- ==========================================
    -- SERVER TAB
    -- ==========================================
    local ServC = TabContents["Server"]
    local sv = 0
    sv = CreateSection(ServC,"Server Hop",sv)
    ui.MinRow, ui.GetMin, sv, ui.SetMin = CreateSlider(ServC,"Min Players",sv,1,25,1,function(v) SHC.MinPlayers=v end)
    ui.MaxRow, ui.GetMax, sv, ui.SetMax = CreateSlider(ServC,"Max Players",sv,1,25,25,function(v) SHC.MaxPlayers=v end)
    sv = CreateSection(ServC,"Actions",sv+5)
    ui.ServerHopBtn, sv = CreateButton(ServC,"Server Hop",sv,"ServerHopBtn")
    ui.RejoinBtn, sv = CreateButton(ServC,"Rejoin Server",sv,"RejoinBtn")

    -- ==========================================
    -- SETTINGS TAB
    -- ==========================================
    local SetC = TabContents["Settings"]
    local sy = 0
    sy = CreateSection(SetC,"Executor",sy)
    ui.ExecNameLbl = Instance.new("TextLabel",SetC)
    ui.ExecNameLbl.Size = UDim2.new(1,0,0,20)
    ui.ExecNameLbl.Position = UDim2.new(0,0,0,sy)
    ui.ExecNameLbl.BackgroundTransparency = 1
    ui.ExecNameLbl.Text = "Executor: Detecting..."
    ui.ExecNameLbl.TextColor3 = Themes[CurrentTheme].Text
    ui.ExecNameLbl.TextSize = 12
    ui.ExecNameLbl.Font = Enum.Font.Gotham
    ui.ExecNameLbl.TextXAlignment = Enum.TextXAlignment.Left
    sy = sy + 22
    ui.ExecStatusLbl = Instance.new("TextLabel",SetC)
    ui.ExecStatusLbl.Size = UDim2.new(1,0,0,20)
    ui.ExecStatusLbl.Position = UDim2.new(0,0,0,sy)
    ui.ExecStatusLbl.BackgroundTransparency = 1
    ui.ExecStatusLbl.Text = "Status: Detecting..."
    ui.ExecStatusLbl.TextColor3 = Color3.fromRGB(255, 220, 120)
    ui.ExecStatusLbl.TextSize = 12
    ui.ExecStatusLbl.Font = Enum.Font.Gotham
    ui.ExecStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
    sy = sy + 22
    sy = CreateSection(SetC,"Theme",sy+5)
    local themeOptions = {"Rarity", "Fluttershy"}
    ui.ThemeDropdown, sy = CreateDropdown(SetC, sy, "Select Theme", "ThemeSelect", 9996)
    ui.ThemeDropdown.Rebuild(themeOptions)
    ui.ThemeDropdown.SetSelected(CurrentTheme)
    ui.ApplyThemeBtn, sy = CreateButton(SetC,"Apply Theme",sy,"ApplyThemeBtn")
    ui.ApplyThemeBtn.MouseButton1Click:Connect(function()
        local selected = ui.ThemeDropdown.GetSelected()
        if selected and Themes[selected] then
            ApplyTheme(selected)
            Notify("Theme changed to " .. selected, 3)
        else
            Notify("Select a theme first", 2)
        end
    end)
    sy = sy + 8
    sy = CreateSection(SetC,"Config Management",sy+5)
    ui.ConfigNameBox, sy = CreateTextBox(SetC,"Config Name",sy,"Enter name...")
    sy = sy + 8
    ui.ConfigDropdown, sy = CreateDropdown(SetC, sy, "Config", "ConfigSelect", 9997)
    sy = sy + 8
    ui.SaveCfgBtn, sy = CreateButton(SetC,"Save Config",sy,"SaveCfgBtn")
    ui.LoadCfgBtn, sy = CreateButton(SetC,"Load Config",sy,"LoadCfgBtn")
    ui.DelCfgBtn, sy = CreateButton(SetC,"Delete Config",sy,"DelCfgBtn")
    ui.SetupAutoLoadBtn, sy = CreateButton(SetC,"Setup AutoLoad",sy,"SetupAutoLoadBtn")
    ui.DeleteAutoLoadBtn, sy = CreateButton(SetC,"Delete AutoLoad",sy,"DeleteAutoLoadBtn")
    sy = sy + 8
    local KbLbl = Instance.new("TextLabel",SetC)
    KbLbl.Size = UDim2.new(0.6,0,0,24)
    KbLbl.Position = UDim2.new(0,0,0,sy)
    KbLbl.BackgroundTransparency = 1
    KbLbl.Text = "GUI Keybind"
    KbLbl.TextColor3 = Themes[CurrentTheme].Text
    local KbLblStroke = Instance.new("UIStroke", KbLbl)
    KbLblStroke.Color = Themes[CurrentTheme].Text
    KbLblStroke.Thickness = 2
    KbLblStroke.Transparency = 0.7
    KbLbl.TextSize = 12
    KbLbl.Font = Enum.Font.Gotham
    KbLbl.TextXAlignment = Enum.TextXAlignment.Left
    ui.KbBtn = Instance.new("TextButton",SetC)
    ui.KbBtn.Size = UDim2.new(0,80,0,24)
    ui.KbBtn.Position = UDim2.new(1,-80,0,sy)
    ui.KbBtn.BackgroundColor3 = Themes[CurrentTheme].InputBg
    ui.KbBtn.Text = "F1"
    ui.KbBtn.TextColor3 = Themes[CurrentTheme].Text
    ui.KbBtn.TextSize = 11
    ui.KbBtn.Font = Enum.Font.GothamMedium
    ui.KbBtn.AutoButtonColor = false
    Instance.new("UICorner",ui.KbBtn).CornerRadius = UDim.new(0,6)
    table.insert(ThemeButtons, {Btn = ui.KbBtn, Type = "Keybind"})

    -- ==========================================
    -- THEME APPLICATION
    -- ==========================================
    ApplyTheme = function(themeName)
        if not Themes[themeName] then return end
        CurrentTheme = themeName
        local t = Themes[themeName]

        MainFrame.BackgroundColor3 = t.Primary
        MainFrame.BackgroundTransparency = t.MainFrameTransparency
        MStroke.Color = t.Stroke
        TitleBar.BackgroundColor3 = t.Secondary
        TitleBar.BackgroundTransparency = t.TitleBarTransparency
        TabsFrame.BackgroundColor3 = t.Secondary
        TabsFrame.BackgroundTransparency = t.TabsFrameTransparency
        TabSep.BackgroundColor3 = t.Separator

        for _, tabData in pairs(TabButtons) do
            tabData.Button.BackgroundTransparency = 1
            tabData.Button.TextColor3 = t.Text
            tabData.Line.BackgroundColor3 = t.Text
        end

        local imgUrl = t.BgImage
        local imgPath = "rarity.tsb/bg_" .. themeName .. ".jpg"
        local imgLoaded = false
        if type(getcustomasset) == "function" and type(writefile) == "function" and type(isfile) == "function" then
            if isfile(imgPath) then
                local ok, assetId = pcall(getcustomasset, imgPath)
                if ok and assetId then
                    BgImage.Image = assetId
                    imgLoaded = true
                end
            end
            if not imgLoaded then
                local ok, data = pcall(function() return game:HttpGet(imgUrl) end)
                if ok and data and #data > 1000 then
                    local writeOk = pcall(function() writefile(imgPath, data) end)
                    if writeOk then
                        task.wait(0.1)
                        local assetOk, assetId = pcall(getcustomasset, imgPath)
                        if assetOk and assetId then
                            BgImage.Image = assetId
                            imgLoaded = true
                        end
                    end
                end
            end
        end
        if not imgLoaded then
            BgImage.Image = imgUrl
        end
        BgImage.ImageTransparency = t.BgImageTransparency

        for _, entry in ipairs(ThemeButtons) do
            if entry.Btn and entry.Btn.Parent then
                if entry.Type == "Button" then
                    entry.Btn.BackgroundColor3 = t.Button
                    entry.Btn.TextColor3 = t.Text
                elseif entry.Type == "Keybind" then
                    entry.Btn.BackgroundColor3 = t.InputBg
                    entry.Btn.TextColor3 = t.Text
                elseif entry.Type == "RowBg" then
                    entry.Btn.BackgroundColor3 = t.RowBg
                    entry.Btn.BackgroundTransparency = t.RowBgTransparency
                elseif entry.Type == "DropBtn" then
                    entry.Btn.BackgroundColor3 = t.Button
                    entry.Btn.TextColor3 = t.Text
                end
            end
        end

        local togglePairs = {
            {ui.AutoM1TradeT, ui.AutoM1TradeC, "AutoM1Trade"},
            {ui.AutoBlockT, ui.AutoBlockC, "AutoBlock"},
            {ui.AimlockT, ui.AimlockC, "Aimlock"},
            {ui.NoStunT, ui.NoStunC, "NoStun"},
            {ui.NoDashCooldownT, ui.NoDashCooldownC, "NoDashCooldown"},

            {ui.InvisibilityT, ui.InvisibilityC, "Invisibility"},
            {ui.AntiDeathCounterT, ui.AntiDeathCounterC, "AntiDeathCounter"},
            {ui.TrackEvasiveT, ui.TrackEvasiveC, "TrackEvasive"},
            {ui.TrackFrontDashT, ui.TrackFrontDashC, "TrackFrontDash"},
            {ui.TrackSideDashT, ui.TrackSideDashC, "TrackSideDash"},
            {ui.EspT, ui.EspCir, "ESP"},
            {ui.TracersT, ui.TracersC, "Tracers"},
            {ui.ChamsT, ui.ChamsC, "Chams"},
            {ui.ClickTpT, ui.ClickTpC, "ClickTp"},
            {ui.FlyT, ui.FlyC, "Fly"},
            {ui.SpeedHackT, ui.SpeedHackC, "SpeedHack"},
            {ui.NoClipT, ui.NoClipC, "NoClip"},
            {ui.SafeModeT, ui.SafeModeC, "SafeMode"},
            {ui.FullBrightT, ui.FullBrightC, "FullBright"},
            {ui.VoidKillsT, ui.VoidKillsC, "VoidKills"},
            {ui.FlingT, ui.FlingC, "Fling"},
            {ui.AntiFlingT, ui.AntiFlingC, "AntiFling"},
        }
        for _, pair in ipairs(togglePairs) do
            local btn = pair[1]
            local circ = pair[2]
            local feat = pair[3]
            if btn and btn.Parent then
                local en = Features[feat] and Features[feat].E or false
                btn.BackgroundColor3 = en and t.ToggleOn or t.ToggleOff
                if circ and circ.Parent then
                    circ.BackgroundColor3 = en and t.ToggleCircleOn or t.ToggleCircleOff
                end
                local row = btn.Parent
                if row and row:IsA("Frame") then
                    row.BackgroundColor3 = t.RowBg
                    row.BackgroundTransparency = t.RowBgTransparency
                end
            end
        end

        local kbBtns = {ui.FlyKb, ui.SpeedHackKb, ui.ClickTpKb, ui.AutoM1TradeKb, ui.AutoBlockKb, ui.AimlockKb, ui.NoClipKb, ui.SafeModeKb, ui.VoidKillsKb, ui.KbBtn}
        for _, btn in ipairs(kbBtns) do
            if btn and btn.Parent then
                btn.BackgroundColor3 = t.InputBg
                btn.TextColor3 = t.Text
            end
        end

        local textBoxes = {ui.ConfigNameBox}
        for _, tb in ipairs(textBoxes) do
            if tb and tb.Parent then
                tb.BackgroundColor3 = t.InputBg
                tb.TextColor3 = t.Text
                local row = tb.Parent
                if row and row:IsA("Frame") then
                    row.BackgroundColor3 = t.RowBg
                    row.BackgroundTransparency = t.RowBgTransparency
                end
            end
        end

        local sliderRows = {ui.SpeedRow, ui.SpeedHackRow, ui.SafeModeRow, ui.MinRow, ui.MaxRow, ui.FullBrightRow, ui.AimlockSmoothRow, ui.AimlockPredRow}
        for _, row in ipairs(sliderRows) do
            if row then
                local trk = row:FindFirstChildOfClass("TextButton")
                if trk then trk.BackgroundColor3 = t.SliderTrack end
                local fl = trk and trk:FindFirstChildOfClass("Frame")
                if fl then fl.BackgroundColor3 = t.SliderFill end
                for _, child in ipairs(row:GetChildren()) do
                    if child:IsA("TextLabel") then
                        child.TextColor3 = t.Text
                    end
                end
            end
        end

        for _, tabContent in pairs(TabContents) do
            if tabContent and tabContent.Parent then
                for _, child in ipairs(tabContent:GetChildren()) do
                    if child:IsA("Frame") then
                        for _, sub in ipairs(child:GetChildren()) do
                            if sub:IsA("TextLabel") then
                                sub.TextColor3 = t.Text
                                local stroke = sub:FindFirstChildOfClass("UIStroke")
                                if stroke then stroke.Color = t.Text end
                            elseif sub:IsA("Frame") and sub.Size.Y.Offset == 2 then
                                sub.BackgroundColor3 = t.Separator
                            end
                        end
                    end
                end
            end
        end

        for _, child in ipairs(ScreenGui:GetChildren()) do
            if child.Name:find("List") and child:IsA("ScrollingFrame") then
                child.BackgroundColor3 = t.DropdownBg
                local stroke = child:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Color = t.DropdownBtn end
                for _, btn in ipairs(child:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.TextColor3 = t.Text
                        btn.BackgroundColor3 = t.DropdownBtn
                    end
                end
            end
        end

        -- ESP Color textboxes
        local espBoxes = {ui.ESPColorRBox, ui.ESPColorGBox, ui.ESPColorBBox}
        for _, box in ipairs(espBoxes) do
            if box and box.Parent then
                box.BackgroundColor3 = t.InputBg
                box.TextColor3 = t.Text
            end
        end

        if _G.UpdateNotificationTheme then
            _G.UpdateNotificationTheme(t)
        end
    end
    ui.ApplyTheme = ApplyTheme

    return ui
end)()

pcall(function() UI.ApplyTheme("Rarity") end)

-- ESP Color Preset handler
if UI.ESPColorDropdown then
    local dropBtn = UI.ESPColorDropdown.Frame:FindFirstChild("DropBtn")
    if dropBtn then
        -- The dropdown already has click handler in CreateDropdown, we need to watch for selection
        -- We'll use a heartbeat task to check selection change
        local lastPreset = nil
        RegisterHeartbeatTask("ESPColorPreset", function()
            local selected = UI.ESPColorDropdown.GetSelected()
            if selected and selected ~= lastPreset and selected ~= "None" then
                lastPreset = selected
                local preset = ESPColorPresets[selected]
                if preset then
                    ESPColor = preset
                    if UI.SetESPColor then UI.SetESPColor(math.floor(preset.R * 255)) end
                    if UI.SetESPColorG then UI.SetESPColorG(math.floor(preset.G * 255)) end
                    if UI.SetESPColorB then UI.SetESPColorB(math.floor(preset.B * 255)) end
                end
            end
        end)
    end
end

-- ==========================================
-- KEYBIND SETUP SYSTEM
-- ==========================================
local function SetupKeybindButton(btn, featureName, defaultKey, actionFn)
    if not btn then return end
    local currentKey = defaultKey
    Keybinds[featureName] = defaultKey

    local forbiddenKeys = {
        [Enum.KeyCode.W] = true, [Enum.KeyCode.A] = true, [Enum.KeyCode.S] = true, [Enum.KeyCode.D] = true,
        [Enum.KeyCode.Q] = true, [Enum.KeyCode.B] = true, [Enum.KeyCode.I] = true, [Enum.KeyCode.O] = true,
        [Enum.KeyCode.F] = true, [Enum.KeyCode.G] = true, [Enum.KeyCode.Tab] = true, [Enum.KeyCode.CapsLock] = true,
        [Enum.KeyCode.LeftShift] = true,
        [Enum.KeyCode.Zero] = true, [Enum.KeyCode.One] = true, [Enum.KeyCode.Two] = true,
        [Enum.KeyCode.Three] = true, [Enum.KeyCode.Four] = true, [Enum.KeyCode.Five] = true,
        [Enum.KeyCode.Six] = true, [Enum.KeyCode.Seven] = true, [Enum.KeyCode.Eight] = true,
        [Enum.KeyCode.Nine] = true,
        [Enum.UserInputType.MouseButton1] = true, [Enum.UserInputType.MouseButton2] = true,
    }

    local function updateText()
        if typeof(currentKey) == "EnumItem" then
            if currentKey.EnumType == Enum.KeyCode then
                btn.Text = currentKey.Name
            elseif currentKey.EnumType == Enum.UserInputType then
                btn.Text = currentKey.Name
            end
        else
            btn.Text = "Bind"
        end
    end
    updateText()

    -- Register action on startup
    if actionFn then
        RegisterInputAction(currentKey, actionFn)
    end

    local function rebindAction(newKey)
        if actionFn then
            UnregisterInputAction(currentKey)
            RegisterInputAction(newKey, actionFn)
        end
    end

    local listening = false
    btn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        btn.Text = "..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            local selected = nil
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                selected = input.KeyCode
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                selected = input.UserInputType
            else
                return
            end
            if forbiddenKeys[selected] then
                Notify("❌ Key forbidden: " .. selected.Name, 2)
                listening = false
                updateText()
                pcall(function() conn:Disconnect() end)
                return
            end
            rebindAction(selected)
            currentKey = selected
            Keybinds[featureName] = currentKey
            updateText()
            listening = false
            pcall(function() conn:Disconnect() end)
        end)
        task.delay(5, function()
            if listening then
                listening = false
                updateText()
                pcall(function() conn:Disconnect() end)
            end
        end)
    end)

    return currentKey
end

-- ==========================================
-- ==========================================
-- UTILS
-- ==========================================
local function AnimToggle(btn,circ,sd,en)
    local t = Themes[CurrentTheme]
    TweenService:Create(btn,TweenInfo.new(0.3),{BackgroundColor3=en and t.ToggleOn or t.ToggleOff}):Play()
    TweenService:Create(circ,TweenInfo.new(0.3),{Position=en and UDim2.new(0,18,0,2) or UDim2.new(0,2,0,2),BackgroundColor3=en and t.ToggleCircleOn or t.ToggleCircleOff}):Play()
    sd.Visible = en
end

local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then table.insert(list, p.Name) end
    end
    return list
end

local function getCharacter()
    return player.Character
end

local function getHRP()
    local char = getCharacter()
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getCharacter()
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

-- ==========================================
-- COMBAT FUNCTIONS
-- ==========================================
local CombatFuncs = (function()
    local cf = {}

    -- ==========================================
    -- AUTO M1 TRADE
    -- ==========================================
    local m1TradeActive = false
    local lastM1Time = 0
    local M1_COOLDOWN = 0.8

    function cf.StartAutoM1Trade()
        Notify("⚔️ Auto M1 Trade active")
        m1TradeActive = true
        RegisterHeartbeatTask("AutoM1Trade", function()
            if not m1TradeActive then UnregisterHeartbeatTask("AutoM1Trade") return end
            if tick() - lastM1Time < M1_COOLDOWN then return end
            local char = getCharacter()
            if not char then return end
            local hrp = getHRP()
            if not hrp then return end
            local closest = nil
            local minDist = math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local targetHRP = p.Character:FindFirstChild("HumanoidRootPart")
                    if targetHRP then
                        local dist = (targetHRP.Position - hrp.Position).Magnitude
                        if dist <= 7 and dist < minDist then
                            minDist = dist
                            closest = p
                        end
                    end
                end
            end
            if not closest then return end
            local targetChar = closest.Character
            local isAttacking = false
            local animator = targetChar:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    local name = track.Name:lower()
                    if name:find("m1") or name:find("punch") or name:find("attack") or name:find("swing") or name:find("hit") then
                        isAttacking = true
                        break
                    end
                end
            end
            if not isAttacking and targetChar:GetAttribute("HoldingM1") == true then
                isAttacking = true
            end
            if isAttacking then
                task.spawn(function()
                    pcall(function() keypress(0x46) end)
                    task.wait(0.5)
                    pcall(function() keyrelease(0x46) end)
                    task.wait(0.05)
                    pcall(function() mouse1click() end)
                end)
                lastM1Time = tick()
            end
        end)
    end

    function cf.StopAutoM1Trade()
        Notify("⚫ Auto M1 Trade disabled")
        m1TradeActive = false
        UnregisterHeartbeatTask("AutoM1Trade")
    end

    -- ==========================================
    -- AUTO BLOCK
    -- ==========================================
    local blockActive = false
    local isBlocking = false
    local BLOCK_KEY = 0x46

    function cf.StartAutoBlock()
        Notify("🛡️ Auto Block active")
        blockActive = true
        RegisterHeartbeatTask("AutoBlock", function()
            if not blockActive then UnregisterHeartbeatTask("AutoBlock") return end
            local char = getCharacter()
            if not char then return end
            local hrp = getHRP()
            if not hrp then return end
            local shouldBlock = false
            local closestAttacker = nil
            local minDist = math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local targetChar = p.Character
                    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                    if targetHRP then
                        local dist = (targetHRP.Position - hrp.Position).Magnitude
                        if dist <= 12 then
                            local isAttacking = false
                            local animator = targetChar:FindFirstChildOfClass("Animator")
                            if animator then
                                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                                    local name = track.Name:lower()
                                    if name:find("m1") or name:find("punch") or name:find("attack") or name:find("swing") or name:find("hit") then
                                        isAttacking = true
                                        break
                                    end
                                end
                            end
                            if not isAttacking and (targetChar:GetAttribute("HoldingM1") == true or targetChar:GetAttribute("DidDamage") == true) then
                                isAttacking = true
                            end
                            if isAttacking and dist < minDist then
                                minDist = dist
                                closestAttacker = targetHRP
                                shouldBlock = true
                            end
                        end
                    end
                end
            end
            -- Rotate to attacker + ShiftLock bypass
            if closestAttacker then
                hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(closestAttacker.Position.X, hrp.Position.Y, closestAttacker.Position.Z))
            end
            if shouldBlock and not isBlocking then
                pcall(function() keypress(BLOCK_KEY) end)
                isBlocking = true
                UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            elseif not shouldBlock and isBlocking then
                pcall(function() keyrelease(BLOCK_KEY) end)
                isBlocking = false
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
        end)
    end

    function cf.StopAutoBlock()
        Notify("⚫ Auto Block disabled")
        blockActive = false
        if isBlocking then
            pcall(function() keyrelease(BLOCK_KEY) end)
            isBlocking = false
        end
        UnregisterHeartbeatTask("AutoBlock")
    end

    -- ==========================================
    -- AIMLOCK
    -- ==========================================
    local aimlockActive = false
    local aimlockTarget = nil

    function cf.StartAimlock()
        Notify("🎯 Aimlock active")
        aimlockActive = true
        RegisterHeartbeatTask("Aimlock", function()
            if not aimlockActive then UnregisterHeartbeatTask("Aimlock") return end
            local char = getCharacter()
            if not char then return end
            local hrp = getHRP()
            if not hrp then return end
            local closest = nil
            local minDist = math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local targetHRP = p.Character:FindFirstChild("HumanoidRootPart")
                    if targetHRP then
                        local dist = (targetHRP.Position - hrp.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            closest = p
                        end
                    end
                end
            end
            if not closest then return end
            aimlockTarget = closest
            local targetChar = closest.Character
            local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
            if not targetHRP then return end
            local velocity = targetHRP.Velocity
            local predictedPos = targetHRP.Position + velocity * AimlockPrediction
            predictedPos = Vector3.new(predictedPos.X, targetHRP.Position.Y, predictedPos.Z)
            local currentCF = Camera.CFrame
            local targetLook = CFrame.lookAt(currentCF.Position, predictedPos)
            Camera.CFrame = currentCF:Lerp(targetLook, AimlockSmoothness)
        end)
    end

    function cf.StopAimlock()
        Notify("⚫ Aimlock disabled")
        aimlockActive = false
        aimlockTarget = nil
        UnregisterHeartbeatTask("Aimlock")
    end

    -- ==========================================
    -- NO STUN
    -- ==========================================
    local noStunActive = false

    function cf.StartNoStun()
        Notify("💪 No Stun (placeholder - not working yet)")
        noStunActive = true
    end

    function cf.StopNoStun()
        Notify("⚫ No Stun disabled")
        noStunActive = false
        UnregisterHeartbeatTask("NoStun")
    end

    -- ==========================================
    -- NO DASH COOLDOWN
    -- ==========================================
    local noDashActive = false

    function cf.StartNoDashCooldown()
        Notify("💨 No Dash Cooldown (placeholder - not working yet)")
        noDashActive = true
    end

    function cf.StopNoDashCooldown()
        Notify("⚫ No Dash Cooldown disabled")
        noDashActive = false
        UnregisterHeartbeatTask("NoDashCooldown")
    end



    -- ==========================================
    -- INVISIBLE BLOCK
    -- ==========================================
    local invisibleBlockActive = false
    local invisibleBlockTimer = 0

    local InvisibleBlockOriginalTransparency = {}

    function cf.StartInvisibleBlock()
        Notify("👻 Invisible Block active")
        invisibleBlockActive = true
        InvisibleBlockOriginalTransparency = {}
        RegisterHeartbeatTask("InvisibleBlock", function()
            if not invisibleBlockActive then UnregisterHeartbeatTask("InvisibleBlock") return end
            local char = getCharacter()
            if not char then return end

            -- Check if currently blocking
            local isBlocking = char:GetAttribute("Blocking")
            if isBlocking ~= true and isBlocking ~= "true" then
                -- Restore transparency if stopped blocking
                for part, orig in pairs(InvisibleBlockOriginalTransparency) do
                    if part and part.Parent then
                        part.Transparency = orig
                    end
                end
                InvisibleBlockOriginalTransparency = {}
                return
            end

            -- Only hide block-related visual elements
            for _, obj in ipairs(char:GetDescendants()) do
                -- Block animations
                if obj:IsA("Animator") then
                    for _, track in ipairs(obj:GetPlayingAnimationTracks()) do
                        local name = track.Name:lower()
                        if name:find("block") or name:find("blocking") then
                            track:AdjustSpeed(0)
                        end
                    end
                end

                -- Block accessories (shields, effects)
                if obj:IsA("Accessory") then
                    local accName = obj.Name:lower()
                    if accName:find("block") or accName:find("shield") or accName:find("guard") then
                        for _, part in ipairs(obj:GetDescendants()) do
                            if part:IsA("BasePart") then
                                if InvisibleBlockOriginalTransparency[part] == nil then
                                    InvisibleBlockOriginalTransparency[part] = part.Transparency
                                end
                                part.Transparency = 1
                            end
                        end
                    end
                end

                -- Block particles/effects on character
                if (obj:IsA("ParticleEmitter") or obj:IsA("Trail")) then
                    local parentName = obj.Parent and obj.Parent.Name:lower() or ""
                    if parentName:find("block") or parentName:find("shield") then
                        obj.Enabled = false
                    end
                end
            end
        end)
    end

    function cf.StopInvisibleBlock()
        Notify("⚫ Invisible Block disabled")
        invisibleBlockActive = false
        UnregisterHeartbeatTask("InvisibleBlock")
        -- Restore all saved transparency values
        for part, orig in pairs(InvisibleBlockOriginalTransparency) do
            if part and part.Parent then
                part.Transparency = orig
            end
        end
        InvisibleBlockOriginalTransparency = {}
    end

    -- ==========================================
    -- ANTI DEATH COUNTER
    -- ==========================================
    local antiDeathActive = false
    local lastHealth = 100

    function cf.StartAntiDeathCounter()
        Notify("☠️ Anti Death Counter active")
        antiDeathActive = true
        lastHealth = 100
        RegisterHeartbeatTask("AntiDeathCounter", function()
            if not antiDeathActive then UnregisterHeartbeatTask("AntiDeathCounter") return end
            local hum = getHumanoid()
            if not hum then return end
            local currentHealth = hum.Health
            if lastHealth - currentHealth > 20 then
                local hrp = getHRP()
                if hrp then
                    local randomOffset = Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
                    hrp.CFrame = hrp.CFrame + randomOffset
                end
            end
            lastHealth = currentHealth
        end)
    end

    function cf.StopAntiDeathCounter()
        Notify("⚫ Anti Death Counter disabled")
        antiDeathActive = false
        UnregisterHeartbeatTask("AntiDeathCounter")
    end

    -- ==========================================
    -- INVISIBILITY (local-only, hides character from your screen)
    -- NOTE: True server-side invisibility is not possible in TSB without server access
    -- ==========================================
    local invisActive = false
    local InvisConn = nil
    local InvisPoll = nil
    local InvisOriginals = {}

    function cf.StartInvisibility()
        Notify("🫥 Invisibility active (local)")
        invisActive = true
        InvisOriginals = {}

        local function storeAndHide(obj, prop, val)
            if not InvisOriginals[obj] then InvisOriginals[obj] = {} end
            if InvisOriginals[obj][prop] == nil then
                InvisOriginals[obj][prop] = obj[prop]
            end
            obj[prop] = val
        end

        local function applyInvis(c)
            if not c then return end
            for _, obj in ipairs(c:GetDescendants()) do
                if obj:IsA("BasePart") then
                    storeAndHide(obj, "Transparency", 1)
                    storeAndHide(obj, "CastShadow", false)
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    storeAndHide(obj, "Transparency", 1)
                elseif obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
                    storeAndHide(obj, "Enabled", false)
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                    storeAndHide(obj, "Enabled", false)
                elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
                    storeAndHide(obj, "Enabled", false)
                end
            end
            -- Hide name tag / overhead
            local head = c:FindFirstChild("Head")
            if head then
                for _, obj in ipairs(head:GetChildren()) do
                    if obj:IsA("BillboardGui") then
                        storeAndHide(obj, "Enabled", false)
                    end
                end
            end
        end

        applyInvis(player.Character)

        InvisPoll = RegisterHeartbeatTask("InvisPoll", function()
            if not invisActive then UnregisterHeartbeatTask("InvisPoll") return end
            local c = player.Character
            if c then applyInvis(c) end
        end)

        InvisConn = player.CharacterAdded:Connect(function(c)
            if not invisActive then return end
            task.wait(0.2)
            applyInvis(c)
        end)
    end

    function cf.StopInvisibility()
        Notify("⚫ Invisibility disabled")
        invisActive = false
        if InvisConn then InvisConn:Disconnect() InvisConn = nil end
        UnregisterHeartbeatTask("InvisPoll")
        for obj, props in pairs(InvisOriginals) do
            if obj and obj.Parent then
                for prop, val in pairs(props) do
                    pcall(function() obj[prop] = val end)
                end
            end
        end
        InvisOriginals = {}
    end

    return cf
end)()

-- ==========================================
-- ESP SYSTEM
-- ==========================================
local ESPFuncs = (function()
    local esp = {}
    local ESPDrawings = {}
    local TracerDrawings = {}
    local ChamHighlights = {}
    local HPBarDrawings = {}

    local function CreateESPText(plr)
        if plr == player or ESPDrawings[plr] then return end
        local d = Drawing.new("Text")
        d.Size = 13
        d.Center = true
        d.Outline = true
        d.Color = ESPColor
        d.Visible = false
        ESPDrawings[plr] = d
    end

    local function RemoveESPText(plr)
        local d = ESPDrawings[plr]
        if d then d:Remove() ESPDrawings[plr] = nil end
    end

    local function CreateTracer(plr)
        if plr == player or TracerDrawings[plr] then return end
        local d = Drawing.new("Line")
        d.Thickness = 1.5
        d.Color = ESPColor
        d.Visible = false
        TracerDrawings[plr] = d
    end

    local function RemoveTracer(plr)
        local d = TracerDrawings[plr]
        if d then d:Remove() TracerDrawings[plr] = nil end
    end

    local function CreateChams(plr)
        if plr == player or ChamHighlights[plr] then return end
        local highlight = Instance.new("Highlight")
        highlight.Name = "RarityChams"
        highlight.FillColor = ESPColor
        highlight.OutlineColor = ESPColor
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = playerGui
        ChamHighlights[plr] = highlight
    end

    local function RemoveChams(plr)
        local h = ChamHighlights[plr]
        if h then pcall(function() h:Destroy() end) ChamHighlights[plr] = nil end
    end

    local function CreateHPBar(plr)
        if plr == player or HPBarDrawings[plr] then return end
        local bg = Drawing.new("Quad")
        bg.Filled = true
        bg.Color = Color3.fromRGB(30, 30, 30)
        bg.Transparency = 0.5
        bg.Visible = false
        local fill = Drawing.new("Quad")
        fill.Filled = true
        fill.Color = Color3.fromRGB(0, 255, 100)
        fill.Transparency = 0.8
        fill.Visible = false
        HPBarDrawings[plr] = {Bg = bg, Fill = fill}
    end

    local function RemoveHPBar(plr)
        local bars = HPBarDrawings[plr]
        if bars then
            pcall(function() bars.Bg:Remove() end)
            pcall(function() bars.Fill:Remove() end)
            HPBarDrawings[plr] = nil
        end
    end

    local function UpdateESP()
        local cam = workspace.CurrentCamera
        local lc = player.Character
        local lhrp = lc and lc:FindFirstChild("HumanoidRootPart")
        local lp = lhrp and lhrp.Position or Vector3.new()
        local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)

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
                        txt.Text = string.format("%s [%sm]", plr.Name, math.floor(dist))
                        txt.Position = Vector2.new(pos.X, pos.Y)
                        txt.Color = ESPColor
                        txt.Visible = Features.ESP.E
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

        for plr, line in pairs(TracerDrawings) do
            if not plr.Parent then line.Visible = false continue end
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    line.From = screenCenter
                    line.To = Vector2.new(pos.X, pos.Y)
                    line.Color = ESPColor
                    line.Visible = Features.Tracers.E
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end

        for plr, bars in pairs(HPBarDrawings) do
            if not plr.Parent then bars.Bg.Visible = false bars.Fill.Visible = false continue end
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local headPos = char:FindFirstChild("Head")
                if headPos then
                    local topPos, topOnScreen = cam:WorldToViewportPoint(headPos.Position + Vector3.new(0, 0.5, 0))
                    local bottomPos, bottomOnScreen = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                    if topOnScreen and bottomOnScreen then
                        local height = math.abs(bottomPos.Y - topPos.Y)
                        local width = height * 0.25
                        local barWidth = 4
                        local barHeight = height
                        local barX = topPos.X - width - 6
                        local barY = topPos.Y
                        local hpPct = hum.Health / hum.MaxHealth
                        bars.Bg.PointA = Vector2.new(barX, barY)
                        bars.Bg.PointB = Vector2.new(barX + barWidth, barY)
                        bars.Bg.PointC = Vector2.new(barX + barWidth, barY + barHeight)
                        bars.Bg.PointD = Vector2.new(barX, barY + barHeight)
                        bars.Bg.Visible = Features.ESP.E
                        local fillHeight = barHeight * hpPct
                        bars.Fill.PointA = Vector2.new(barX, barY + (barHeight - fillHeight))
                        bars.Fill.PointB = Vector2.new(barX + barWidth, barY + (barHeight - fillHeight))
                        bars.Fill.PointC = Vector2.new(barX + barWidth, barY + barHeight)
                        bars.Fill.PointD = Vector2.new(barX, barY + barHeight)
                        bars.Fill.Color = hpPct > 0.5 and Color3.fromRGB(0, 255, 100) or (hpPct > 0.25 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0))
                        bars.Fill.Visible = Features.ESP.E
                    else
                        bars.Bg.Visible = false
                        bars.Fill.Visible = false
                    end
                else
                    bars.Bg.Visible = false
                    bars.Fill.Visible = false
                end
            else
                bars.Bg.Visible = false
                bars.Fill.Visible = false
            end
        end

        for plr, highlight in pairs(ChamHighlights) do
            if not plr.Parent then
                highlight.Adornee = nil
                continue
            end
            local char = plr.Character
            if char then
                highlight.Adornee = char
                highlight.FillColor = ESPColor
                highlight.OutlineColor = ESPColor
                highlight.Enabled = Features.Chams.E
            else
                highlight.Adornee = nil
            end
        end
    end

    function esp.StartESP()
        Notify("👁️ Player ESP active")
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then 
                CreateESPText(p)
                CreateTracer(p)
                CreateChams(p)
                CreateHPBar(p)
            end
        end
        RegisterHeartbeatTask("ESP", UpdateESP)
        Features.ESP.PlayerAdded = Players.PlayerAdded:Connect(function(p) 
            CreateESPText(p)
            CreateTracer(p)
            CreateChams(p)
            CreateHPBar(p)
        end)
        Features.ESP.PlayerRemoving = Players.PlayerRemoving:Connect(function(p) 
            RemoveESPText(p)
            RemoveTracer(p)
            RemoveChams(p)
            RemoveHPBar(p)
        end)
    end

    function esp.StopESP()
        Notify("⚫ Player ESP disabled")
        UnregisterHeartbeatTask("ESP")
        if Features.ESP.PlayerAdded then Features.ESP.PlayerAdded:Disconnect() Features.ESP.PlayerAdded = nil end
        if Features.ESP.PlayerRemoving then Features.ESP.PlayerRemoving:Disconnect() Features.ESP.PlayerRemoving = nil end
        for _, d in pairs(ESPDrawings) do d:Remove() end
        for _, d in pairs(TracerDrawings) do d:Remove() end
        for _, h in pairs(ChamHighlights) do pcall(function() h:Destroy() end) end
        for _, bars in pairs(HPBarDrawings) do
            pcall(function() bars.Bg:Remove() end)
            pcall(function() bars.Fill:Remove() end)
        end
        ESPDrawings = {}
        TracerDrawings = {}
        ChamHighlights = {}
        HPBarDrawings = {}
    end

    function esp.StartTracers()
        -- Handled by ESP heartbeat
    end

    function esp.StopTracers()
        -- Handled by ESP heartbeat
    end

    function esp.StartChams()
        -- Handled by ESP heartbeat
    end

    function esp.StopChams()
        -- Handled by ESP heartbeat
    end

    return esp
end)()

-- ==========================================
-- GLOBAL FLY MULTIPLIER STATE
-- ==========================================
getgenv().FlyMultActive = false

-- ==========================================
-- MOVEMENT FUNCTIONS
-- ==========================================
local MovementFuncs = (function()
    local mov = {}
    local FlyAct = false
    local SpeedHackActive = false
    local NoClipActive = false
    local OriginalCanCollide = {}

    -- ==========================================
    -- CLICK TP
    -- ==========================================
    function mov.StartClickTp()
        Notify("🖱️ ClickTP active")
        -- ClickTp is handled by keybind system, no need for separate InputAction
    end

    function mov.StopClickTp()
        Notify("⚫ ClickTP disabled")
        -- No cleanup needed, handled by keybind system
    end

    -- ==========================================
    -- FLY (BodyVelocity + BodyGyro - stable, no PlatformStand)
    -- ==========================================
    function mov.StartFly()
        Notify("🪽 Fly active")
        local c = player.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        FlyAct = true
        _G.RarityTSBOriginalGravity = Workspace.Gravity
        Workspace.Gravity = 0

        local bv = Instance.new("BodyVelocity")
        bv.Name = "RarityFlyBV"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = hrp

        local bg = Instance.new("BodyGyro")
        bg.Name = "RarityFlyBG"
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9e9
        bg.Parent = hrp

        RegisterHeartbeatTask("Fly", function(dt)
            if not FlyAct then UnregisterHeartbeatTask("Fly") return end
            if not hrp.Parent or not hum.Parent then return end

            local cam = workspace.CurrentCamera
            local md = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then md = md + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then md = md + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then md = md + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then md = md + Vector3.new(1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then md = md + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then md = md + Vector3.new(0, -1, 0) end

            local mult = getgenv().FlyMultActive and FlySpeedMultiplier or 1
            if md.Magnitude > 0 then
                md = md.Unit
                local moveDir = (cam.CFrame.LookVector * -md.Z + cam.CFrame.RightVector * md.X + Vector3.new(0, md.Y, 0)).Unit
                bv.Velocity = moveDir * FlySpeed * mult
            else
                bv.Velocity = Vector3.new(0, 0, 0)
            end

            -- Full 360 rotation matching camera
            bg.CFrame = cam.CFrame
        end)
    end

    function mov.StopFly()
        Notify("⚫ Fly disabled")
        FlyAct = false
        UnregisterHeartbeatTask("Fly")
        _G.RarityTSBOriginalGravity = _G.RarityTSBOriginalGravity or 196.2
        Workspace.Gravity = _G.RarityTSBOriginalGravity
        local c = player.Character
        if c then
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, child in ipairs(hrp:GetChildren()) do
                    if child.Name == "RarityFlyBV" or child.Name == "RarityFlyBG" then
                        pcall(function() child:Destroy() end)
                    end
                end
                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end

    -- ==========================================
    -- SPEED HACK (horizontal only)
    -- ==========================================
    function mov.StartSpeedHack()
        Notify("🏃 Speed Hack active")
        SpeedHackActive = true
        RegisterHeartbeatTask("SpeedHack", function()
            if not SpeedHackActive then UnregisterHeartbeatTask("SpeedHack") return end
            local char = getCharacter()
            if not char then return end
            local hrp = getHRP()
            if not hrp then return end
            local md = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then md = md + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then md = md + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then md = md + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then md = md + Vector3.new(1, 0, 0) end
            if md.Magnitude > 0 then
                md = md.Unit
                local cam = workspace.CurrentCamera
                local moveDir = (cam.CFrame.LookVector * -md.Z + cam.CFrame.RightVector * md.X)
                moveDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
                hrp.CFrame = hrp.CFrame + moveDir * (SpeedHackValue / 60)
            end
        end)
    end

    function mov.StopSpeedHack()
        Notify("⚫ Speed Hack disabled")
        SpeedHackActive = false
        UnregisterHeartbeatTask("SpeedHack")
    end

    -- ==========================================
    -- NO CLIP
    -- ==========================================
    function mov.StartNoClip()
        Notify("👻 NoClip active")
        NoClipActive = true
        OriginalCanCollide = {}
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    OriginalCanCollide[part] = part.CanCollide
                    part.CanCollide = false
                end
            end
        end
        SteppedTasks["NoClip"] = function()
            if not NoClipActive then SteppedTasks["NoClip"] = nil return end
            local c = player.Character
            if not c then return end
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    if OriginalCanCollide[part] == nil then OriginalCanCollide[part] = part.CanCollide end
                    part.CanCollide = false
                end
            end
        end
    end

    function mov.StopNoClip()
        Notify("⚫ NoClip disabled")
        NoClipActive = false
        SteppedTasks["NoClip"] = nil
        local c = player.Character
        if c then
            for part, orig in pairs(OriginalCanCollide) do
                if part and part.Parent then part.CanCollide = orig end
            end
        end
        OriginalCanCollide = {}
    end

    return mov
end)()

-- ==========================================
-- FLY MULTIPLIER KEYBIND (LeftAlt toggle)
-- ==========================================
RegisterInputAction(Enum.KeyCode.LeftAlt, function()
    getgenv().FlyMultActive = not getgenv().FlyMultActive
    if getgenv().FlyMultActive then
        Notify("⚡ Fly Multiplier ON (" .. FlySpeedMultiplier .. "x)", 2)
    else
        Notify("⚡ Fly Multiplier OFF", 2)
    end
end)

-- ==========================================
-- QOL FUNCTIONS
-- ==========================================
local QoLFuncs = (function()
    local qol = {}
    local safeModeActive = false
    local fullBrightActive = false
    local origLighting = {}
    local SafeModePlatform = nil

    -- ==========================================
    -- SAFE MODE
    -- ==========================================
    local safeModeTriggered = false
    local SafeModePlatform = nil

    -- Create platform high in sky on script load
    task.spawn(function()
        task.wait(2)
        SafeModePlatform = Instance.new("Part")
        SafeModePlatform.Name = "RaritySafeModePlatform"
        SafeModePlatform.Size = Vector3.new(100, 2, 100)
        SafeModePlatform.Position = Vector3.new(0, 2000, 0)
        SafeModePlatform.Anchored = true
        SafeModePlatform.CanCollide = true
        SafeModePlatform.Transparency = 1
        SafeModePlatform.Parent = workspace
    end)

    function qol.StartSafeMode()
        Notify("🛡️ Safe Mode active (< " .. SafeModeHP .. "% HP)")
        safeModeActive = true
        safeModeTriggered = false
        RegisterHeartbeatTask("SafeMode", function()
            if not safeModeActive then UnregisterHeartbeatTask("SafeMode") return end
            if safeModeTriggered then return end
            local hum = getHumanoid()
            if not hum then return end
            local hpPercent = (hum.Health / hum.MaxHealth) * 100
            if hpPercent <= SafeModeHP then
                safeModeTriggered = true
                local hrp = getHRP()
                if hrp and SafeModePlatform then
                    hrp.CFrame = CFrame.new(SafeModePlatform.Position + Vector3.new(0, 5, 0))
                    hrp.Velocity = Vector3.new(0, 0, 0)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    Notify("🚨 Safe Mode triggered! Teleported to safe platform.", 3)
                end
            end
        end)
    end

    function qol.StopSafeMode()
        Notify("⚫ Safe Mode disabled")
        safeModeActive = false
        safeModeTriggered = false
        UnregisterHeartbeatTask("SafeMode")
    end

    -- ==========================================
    -- FULL BRIGHT
    -- ==========================================
    function qol.StartFullBright()
        Notify("☀️ Full Brightness active")
        fullBrightActive = true
        origLighting.Brightness = Lighting.Brightness
        origLighting.ClockTime = Lighting.ClockTime
        origLighting.FogEnd = Lighting.FogEnd
        origLighting.FogStart = Lighting.FogStart
        origLighting.GlobalShadows = Lighting.GlobalShadows
        origLighting.OutdoorAmbient = Lighting.OutdoorAmbient
        origLighting.Ambient = Lighting.Ambient
        Lighting.Brightness = FullBrightValue
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.Ambient = Color3.new(1,1,1)
        RegisterHeartbeatTask("FullBrightCheck", function()
            if fullBrightActive and Lighting.Brightness ~= FullBrightValue then
                Lighting.Brightness = FullBrightValue
            end
        end)
    end

    function qol.StopFullBright()
        Notify("⚫ Full Brightness disabled")
        fullBrightActive = false
        UnregisterHeartbeatTask("FullBrightCheck")
        if origLighting.Brightness ~= nil then Lighting.Brightness = origLighting.Brightness end
        if origLighting.ClockTime ~= nil then Lighting.ClockTime = origLighting.ClockTime end
        if origLighting.FogEnd ~= nil then Lighting.FogEnd = origLighting.FogEnd end
        if origLighting.FogStart ~= nil then Lighting.FogStart = origLighting.FogStart end
        if origLighting.GlobalShadows ~= nil then Lighting.GlobalShadows = origLighting.GlobalShadows end
        if origLighting.OutdoorAmbient ~= nil then Lighting.OutdoorAmbient = origLighting.OutdoorAmbient end
        if origLighting.Ambient ~= nil then Lighting.Ambient = origLighting.Ambient end
        origLighting = {}
    end

    return qol
end)()

-- ==========================================
-- PLAYERS FUNCTIONS
-- ==========================================
local PlayersFuncs = (function()
    local pf = {}
    local flingActive = false
    local flingTargets = {}
    local antiFlingActive = false
    local voidKillActive = false
    local voidKillTarget = nil
    local voidKillOriginalCFrame = nil
    local SafeModePlatform = nil

    -- ==========================================
    -- VOID KILLS (Hero Hunter - TSB Tool-based)
    -- ==========================================
    local function GetCharacterName()
        local char = getCharacter()
        if not char then return nil end
        return char:GetAttribute("Character")
    end

    local function IsHeroHunter()
        local charName = GetCharacterName()
        if charName then
            local lower = charName:lower()
            if lower:find("hero") and lower:find("hunter") then
                return true
            end
        end
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    local name = tool.Name:lower()
                    if name:find("whirlwind") or name:find("flowing water") or name:find("water") then
                        return true
                    end
                end
            end
        end
        local char = getCharacter()
        if char then
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("Tool") then
                    local name = obj.Name:lower()
                    if name:find("whirlwind") or name:find("flowing water") or name:find("water") then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function GetSkillsFromBackpack()
        local backpack = player:FindFirstChild("Backpack")
        if not backpack then return {} end
        local skills = {}
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:find("flowing water") or name:find("whirlwind") then
                    table.insert(skills, tool)
                end
            end
        end
        return skills
    end

    local function ActivateSkill(tool)
        if not tool then return false end
        local ok = pcall(function()
            local char = getCharacter()
            if not char then return end
            -- Equip tool if in backpack
            if tool.Parent == player:FindFirstChild("Backpack") then
                tool.Parent = char
                task.wait(0.2)
            end
            -- Activate
            mouse1click()
            task.wait(0.1)
            firesignal(tool.Activated)
            task.wait(0.1)
        end)
        return ok
    end

    local function TeleportToTarget(targetPlayer)
        if not targetPlayer or not targetPlayer.Character then return false end
        local hrp = getHRP()
        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not targetHRP then return false end
        local targetCF = targetHRP.CFrame * CFrame.new(0, 0, 2)
        local distance = (hrp.Position - targetCF.Position).Magnitude
        local tweenTime = math.clamp(distance / 500, 0.15, 0.4)
        local tween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = targetCF})
        tween:Play()
        tween.Completed:Wait()
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        return true
    end

    local AttachHeartbeat = nil
    local TargetAttachHeartbeat = nil

    local function AttachToTarget(targetPlayer)
        if not targetPlayer or not targetPlayer.Character then return end
        local hrp = getHRP()
        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not targetHRP then return end
        -- Clean up old
        for _, child in ipairs(hrp:GetChildren()) do
            if child.Name == "RarityAttachAP" or child.Name == "RarityAttachAO" then
                pcall(function() child:Destroy() end)
            end
        end
        if AttachHeartbeat then
            pcall(function() AttachHeartbeat:Disconnect() end)
            AttachHeartbeat = nil
        end
        local att = hrp:FindFirstChildOfClass("Attachment")
        if not att then
            att = Instance.new("Attachment", hrp)
        end
        local ap = Instance.new("AlignPosition")
        ap.Name = "RarityAttachAP"
        ap.Mode = Enum.PositionAlignmentMode.OneAttachment
        ap.Attachment0 = att
        ap.RigidityEnabled = true
        ap.MaxForce = 9e9
        ap.MaxVelocity = 9e9
        ap.Position = targetHRP.Position
        ap.Parent = hrp
        local ao = Instance.new("AlignOrientation")
        ao.Name = "RarityAttachAO"
        ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
        ao.Attachment0 = att
        ao.RigidityEnabled = true
        ao.MaxTorque = 9e9
        ao.CFrame = targetHRP.CFrame
        ao.Parent = hrp
        -- Persistent update
        AttachHeartbeat = RunService.Heartbeat:Connect(function()
            if not targetPlayer or not targetPlayer.Character then return end
            local tHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if tHRP and ap and ap.Parent then
                ap.Position = tHRP.Position
            end
            if tHRP and ao and ao.Parent then
                ao.CFrame = tHRP.CFrame
            end
        end)
        task.wait(0.1)
    end

    local function AttachTargetToMe(targetPlayer)
        -- Method 1: Attach target's HRP to our HRP using AlignPosition
        if not targetPlayer or not targetPlayer.Character then return end
        local hrp = getHRP()
        local targetHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp or not targetHRP then return end
        -- Clean old target attachments
        for _, child in ipairs(targetHRP:GetChildren()) do
            if child.Name == "RarityTargetAP" or child.Name == "RarityTargetAO" then
                pcall(function() child:Destroy() end)
            end
        end
        if TargetAttachHeartbeat then
            pcall(function() TargetAttachHeartbeat:Disconnect() end)
            TargetAttachHeartbeat = nil
        end
        local myAtt = hrp:FindFirstChildOfClass("Attachment")
        if not myAtt then
            myAtt = Instance.new("Attachment", hrp)
        end
        local targetAtt = targetHRP:FindFirstChildOfClass("Attachment")
        if not targetAtt then
            targetAtt = Instance.new("Attachment", targetHRP)
        end
        local ap = Instance.new("AlignPosition")
        ap.Name = "RarityTargetAP"
        ap.Mode = Enum.PositionAlignmentMode.TwoAttachment
        ap.Attachment0 = targetAtt
        ap.Attachment1 = myAtt
        ap.RigidityEnabled = true
        ap.MaxForce = 9e9
        ap.MaxVelocity = 9e9
        ap.Responsiveness = 200
        ap.Parent = targetHRP
        local ao = Instance.new("AlignOrientation")
        ao.Name = "RarityTargetAO"
        ao.Mode = Enum.OrientationAlignmentMode.TwoAttachment
        ao.Attachment0 = targetAtt
        ao.Attachment1 = myAtt
        ao.RigidityEnabled = true
        ao.MaxTorque = 9e9
        ao.Responsiveness = 200
        ao.Parent = targetHRP
        TargetAttachHeartbeat = RunService.Heartbeat:Connect(function()
            if not targetPlayer or not targetPlayer.Character then
                pcall(function() ap:Destroy() end)
                pcall(function() ao:Destroy() end)
                return
            end
            local tHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not tHRP then
                pcall(function() ap:Destroy() end)
                pcall(function() ao:Destroy() end)
                return
            end
        end)
    end

    local function DetachTargetFromMe()
        if TargetAttachHeartbeat then
            pcall(function() TargetAttachHeartbeat:Disconnect() end)
            TargetAttachHeartbeat = nil
        end
        if TargetFreezeConn then
            pcall(function() TargetFreezeConn:Disconnect() end)
            TargetFreezeConn = nil
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local tHRP = p.Character:FindFirstChild("HumanoidRootPart")
                if tHRP then
                    for _, child in ipairs(tHRP:GetChildren()) do
                        if child.Name == "RarityTargetAP" or child.Name == "RarityTargetAO" or child.Name == "RarityTargetBV" then
                            pcall(function() child:Destroy() end)
                        end
                    end
                end
            end
        end
    end

    local TargetFreezeConn = nil

    local function MoveTargetToEdge(targetPlayer)
        if not targetPlayer or not targetPlayer.Character then return end
        local tHRP = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not tHRP then return end
        -- Clean old
        for _, child in ipairs(tHRP:GetChildren()) do
            if child.Name == "RarityTargetBV" then
                pcall(function() child:Destroy() end)
            end
        end
        if TargetFreezeConn then
            pcall(function() TargetFreezeConn:Disconnect() end)
            TargetFreezeConn = nil
        end
        -- Teleport target straight down to Y=-300, keeping same X and Z
        local underPos = Vector3.new(tHRP.Position.X, -300, tHRP.Position.Z)
        tHRP.CFrame = CFrame.new(underPos)
        tHRP.Velocity = Vector3.new(0, 0, 0)
        tHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        -- Also teleport all other parts of target character
        for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CFrame = CFrame.new(underPos)
                part.Velocity = Vector3.new(0, 0, 0)
                part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
        -- Keep target frozen under map - prevent server from moving them back
        TargetFreezeConn = RunService.Heartbeat:Connect(function()
            if not targetPlayer or not targetPlayer.Character then
                pcall(function() TargetFreezeConn:Disconnect() end)
                TargetFreezeConn = nil
                return
            end
            local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            if hrp.Position.Y > -200 then
                -- Server moved them back, teleport under map again
                hrp.CFrame = CFrame.new(hrp.Position.X, -300, hrp.Position.Z)
                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                for _, part in ipairs(targetPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.CFrame = CFrame.new(hrp.Position.X, -300, hrp.Position.Z)
                        part.Velocity = Vector3.new(0, 0, 0)
                        part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end)
    end

    local function UnfreezeTarget(targetPlayer)
        if TargetFreezeConn then
            pcall(function() TargetFreezeConn:Disconnect() end)
            TargetFreezeConn = nil
        end
    end

    local function DetachFromTarget()
        local hrp = getHRP()
        if not hrp then return end
        for _, child in ipairs(hrp:GetChildren()) do
            if child.Name == "RarityAttachAP" or child.Name == "RarityAttachAO" then
                pcall(function() child:Destroy() end)
            end
        end
        if AttachHeartbeat then
            pcall(function() AttachHeartbeat:Disconnect() end)
            AttachHeartbeat = nil
        end
        DetachTargetFromMe()
    end

    local function TeleportToEdge()
        local hrp = getHRP()
        if not hrp then return end
        -- Teleport straight down to Y=-300, keeping same X and Z
        hrp.CFrame = CFrame.new(hrp.Position.X, -300, hrp.Position.Z)
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end

    local function FreezeCharacter()
        local hrp = getHRP()
        if not hrp then return end
        hrp.Anchored = true
    end

    local function UnfreezeCharacter()
        local hrp = getHRP()
        if not hrp then return end
        hrp.Anchored = false
    end

    local function ReturnToOriginal()
        local hrp = getHRP()
        if not hrp then return end
        if voidKillOriginalCFrame then
            hrp.CFrame = voidKillOriginalCFrame
        end
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        voidKillOriginalCFrame = nil
    end

    local function CheckIfCaught()
        local char = getCharacter()
        if not char then return false end
        local freeze = char:FindFirstChild("Freeze")
        if freeze and (freeze:IsA("Accessory") or freeze:IsA("Part")) then
            return true
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local animator = hum:FindFirstChildOfClass("Animator")
            if animator then
                for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                    local name = track.Name:lower()
                    if name:find("grab") or name:find("throw") or name:find("void") or name:find("catch") then
                        return true
                    end
                end
            end
        end
        return false
    end

    function pf.StartVoidKills()
        if not IsHeroHunter() then
            Notify("❌ Switch to Hero Hunter!", 3)
            Features.VoidKills.E = false
            AnimToggle(UI.VoidKillsT, UI.VoidKillsC, UI.VoidKillsS, false)
            return
        end
        Notify("🕳️ Void Kills armed (Hero Hunter) — press keybind to execute")
        voidKillActive = true
    end

    function pf.StopVoidKills()
        Notify("⚫ Void Kills disabled")
        voidKillActive = false
        DetachFromTarget()
        UnfreezeCharacter()
        ReturnToOriginal()
    end

    local function DoVoidKill()
        if not Features.VoidKills.E then
            Notify("❌ Enable Void Kills toggle first", 2)
            return
        end
        if not IsHeroHunter() then
            Notify("❌ Switch to Hero Hunter!", 3)
            return
        end
        local targetName = UI.PlayersDropdown.GetSelected()
        if not targetName or targetName == "None" then
            Notify("❌ Select a target first", 2)
            return
        end
        local target = Players:FindFirstChild(targetName)
        if not target or not target.Character then
            Notify("❌ Target not found", 2)
            return
        end

        task.spawn(function()
            local hrp = getHRP()
            if not hrp then
                Notify("❌ No HRP", 2)
                return
            end

            -- Save original position
            voidKillOriginalCFrame = hrp.CFrame

            -- Get ALL skills (Backpack + Character)
            local allSkills = {}
            local backpack = player:FindFirstChild("Backpack")
            if backpack then
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        local name = tool.Name:lower()
                        if name:find("flowing water") or name:find("whirlwind") then
                            table.insert(allSkills, tool)
                        end
                    end
                end
            end
            local char = getCharacter()
            if char then
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        local name = tool.Name:lower()
                        if name:find("flowing water") or name:find("whirlwind") then
                            -- Check if already in list
                            local found = false
                            for _, existing in ipairs(allSkills) do
                                if existing == tool then found = true break end
                            end
                            if not found then
                                table.insert(allSkills, tool)
                            end
                        end
                    end
                end
            end

            if #allSkills == 0 then
                Notify("❌ No skills found", 2)
                ReturnToOriginal()
                return
            end

            -- Find skills by name for reliable rotation
            local flowingWaterSkill = nil
            local whirlwindSkill = nil
            for _, skill in ipairs(allSkills) do
                local name = skill.Name:lower()
                if name:find("flowing water") then
                    flowingWaterSkill = skill
                elseif name:find("whirlwind") then
                    whirlwindSkill = skill
                end
            end

            -- Determine which skill to use based on last used (guaranteed alternation)
            local lastSkillName = getgenv().RarityLastVoidSkill or ""
            local skillToUse = nil
            local skillName = ""

            if lastSkillName:find("Whirlwind") and flowingWaterSkill then
                -- Last was Whirlwind, use Flowing Water next
                skillToUse = flowingWaterSkill
                skillName = "Flowing Water"
            elseif whirlwindSkill then
                -- First use or last was Flowing Water -> use Whirlwind
                skillToUse = whirlwindSkill
                skillName = "Lethal Whirlwind Stream"
            elseif flowingWaterSkill then
                -- Only Flowing Water available
                skillToUse = flowingWaterSkill
                skillName = "Flowing Water"
            end

            if not skillToUse then
                Notify("❌ No valid skill found", 2)
                ReturnToOriginal()
                return
            end

            -- Delay based on skill type (v111 confirmed values)
            local delayTime = 1.4 -- Flowing Water
            if skillName:find("Whirlwind") then
                delayTime = 1.50 -- Lethal Whirlwind Stream (final timing attempt)
            end

            Notify("🎯 Void Kill: " .. targetName .. " | Skill: " .. skillName .. " | Delay: " .. delayTime .. "s", 2)

            -- Step 1: Teleport to target (instant)
            if not TeleportToTarget(target) then
                voidKillOriginalCFrame = nil
                return
            end

            -- Step 2: Attach to target (persistent via heartbeat)
            AttachToTarget(target)

            -- Step 3: Activate selected skill
            local activated = ActivateSkill(skillToUse)
            if not activated then
                Notify("❌ Failed to activate skill", 2)
                DetachFromTarget()
                ReturnToOriginal()
                return
            end
            task.wait(0.1)

            -- Step 4: Wait for skill grab (auto timing based on skill)
            Notify("⏳ Waiting " .. delayTime .. "s...", 1)
            task.wait(delayTime)

            -- Step 5: Teleport player UNDER MAP while still attached to target
            hrp.CFrame = CFrame.new(hrp.Position.X, -300, hrp.Position.Z)
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

            -- Step 6: Keep attached for a moment so skill pulls target down
            task.wait(0.5)

            -- Step 7: Detach from target
            DetachFromTarget()

            -- Step 8: Wait 0.5s then freeze
            task.wait(0.5)
            FreezeCharacter()

            -- Step 9: Wait 1s under map
            task.wait(1.0)
            UnfreezeCharacter()

            -- Step 10: Wait 0.3s then return
            task.wait(0.3)
            ReturnToOriginal()

            -- Step 11: Unequip ALL skill tools (move to Backpack)
            task.wait(0.2)
            local char2 = getCharacter()
            if char2 then
                for _, tool in ipairs(char2:GetChildren()) do
                    if tool:IsA("Tool") then
                        local name = tool.Name:lower()
                        if name:find("flowing water") or name:find("whirlwind") then
                            tool.Parent = player:FindFirstChild("Backpack")
                        end
                    end
                end
            end

            -- Save last used skill for guaranteed alternation on next use
            getgenv().RarityLastVoidSkill = skillName

            local nextSkillHint = ""
            if skillName:find("Whirlwind") and flowingWaterSkill then
                nextSkillHint = "Flowing Water"
            elseif whirlwindSkill then
                nextSkillHint = "Lethal Whirlwind Stream"
            elseif flowingWaterSkill then
                nextSkillHint = "Flowing Water"
            end
            Notify("✅ Done | Next: " .. nextSkillHint, 3)
        end)
    end



    

    

    -- ==========================================
    -- FLING - Dropdown target, queue, 5s interval
    -- ==========================================
    local FlingQueue = {}
    local FlingIndex = 1
    local FlingLastTime = 0
    local FlingOriginalPos = nil

    local function SkidFling(targetPlayer)
        local char = getCharacter()
        if not char then return end
        local hum = getHumanoid()
        local hrp = getHRP()
        if not hum or not hrp then return end
        local tChar = targetPlayer.Character
        if not tChar then return end
        local tHum = tChar:FindFirstChildOfClass("Humanoid")
        local tHRP = tHum and tHum.RootPart
        if not tHRP then return end

        if tHum and tHum.Sit then return end

        -- Save original position once
        if not FlingOriginalPos then
            FlingOriginalPos = hrp.CFrame
        end

        workspace.FallenPartsDestroyHeight = 0/0

        local bv = Instance.new("BodyVelocity")
        bv.Parent = hrp
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)

        local bg = Instance.new("BodyGyro")
        bg.Parent = hrp
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 9e9

        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

        local startTime = tick()
        local angle = 0
        repeat
            if hrp and tHRP and flingActive then
                angle = angle + 100
                hrp.CFrame = CFrame.new(tHRP.Position) * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(angle), 0, 0)
                hrp.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
                hrp.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
            end
            task.wait()
        until tick() - startTime > 2 or not flingActive

        bv:Destroy()
        bg:Destroy()
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    end

    function pf.StartFling()
        Notify("💨 Fling active")
        flingActive = true
        FlingQueue = {}
        FlingIndex = 1
        FlingLastTime = 0
        FlingOriginalPos = nil
        getgenv().FPDH = workspace.FallenPartsDestroyHeight
        RegisterHeartbeatTask("Fling", function()
            if not flingActive then UnregisterHeartbeatTask("Fling") return end
            if not Features.Fling.E then return end
            if tick() - FlingLastTime < 5 then return end

            local targetName = UI.FlingTargetDropdown and UI.FlingTargetDropdown.GetSelected() or "All"
            local targets = {}

            if targetName == "All" or not targetName or targetName == "None" then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= player and p.Character then
                        table.insert(targets, p)
                    end
                end
            else
                local p = Players:FindFirstChild(targetName)
                if p and p.Character then table.insert(targets, p) end
            end

            if #targets == 0 then return end

            if targetName == "All" then
                FlingIndex = (FlingIndex % #targets) + 1
                local target = targets[FlingIndex]
                if target then
                    FlingLastTime = tick()
                    task.spawn(function() SkidFling(target) end)
                end
            else
                FlingLastTime = tick()
                task.spawn(function() SkidFling(targets[1]) end)
            end
        end)
    end

    function pf.StopFling()
        Notify("⚫ Fling disabled")
        flingActive = false
        UnregisterHeartbeatTask("Fling")
        workspace.FallenPartsDestroyHeight = getgenv().FPDH or -500
        -- Return to original position safely
        local hrp = getHRP()
        if hrp and FlingOriginalPos then
            hrp.CFrame = FlingOriginalPos
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
        FlingOriginalPos = nil
    end

    -- ==========================================
    -- ANTI FLING - Resist external forces only
    -- ==========================================
    function pf.StartAntiFling()
        Notify("🛡️ Anti Fling active")
        antiFlingActive = true
        local antiFlingBV = nil
        local lastHRPPos = nil

        RegisterHeartbeatTask("AntiFling", function()
            if not antiFlingActive then UnregisterHeartbeatTask("AntiFling") return end
            if not Features.AntiFling.E then return end
            local char = getCharacter()
            if not char then return end
            local hrp = getHRP()
            if not hrp then return end

            -- Only apply resistance when velocity is abnormal (being flung)
            local vel = hrp.Velocity
            local speed = vel.Magnitude
            if speed > 100 then
                -- Being flung - apply counter-force
                if not antiFlingBV or not antiFlingBV.Parent then
                    antiFlingBV = Instance.new("BodyVelocity")
                    antiFlingBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    antiFlingBV.Velocity = Vector3.new(0, 0, 0)
                    antiFlingBV.Parent = hrp
                end
                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            else
                -- Normal movement - remove resistance
                if antiFlingBV and antiFlingBV.Parent then
                    pcall(function() antiFlingBV:Destroy() end)
                    antiFlingBV = nil
                end
            end

            -- Noclip only against other players (not environment)
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    for _, part in ipairs(p.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)
    end

    function pf.StopAntiFling()
        Notify("⚫ Anti Fling disabled")
        antiFlingActive = false
        UnregisterHeartbeatTask("AntiFling")
        -- Re-enable collision with other players
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
        local hrp = getHRP()
        if hrp then
            for _, child in ipairs(hrp:GetChildren()) do
                if child:IsA("BodyVelocity") then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end

    pf.DoVoidKill = DoVoidKill

    return pf
end)()

-- ==========================================
-- ESP COLOR PRESET HANDLER
-- ==========================================
local ESPColorPresets = {
    Red = Color3.fromRGB(255, 0, 0),
    Green = Color3.fromRGB(0, 255, 0),
    Blue = Color3.fromRGB(0, 0, 255),
    Purple = Color3.fromRGB(147, 0, 211),
    Cyan = Color3.fromRGB(0, 255, 255),
    Yellow = Color3.fromRGB(255, 255, 0),
    White = Color3.fromRGB(255, 255, 255),
    Pink = Color3.fromRGB(255, 105, 180),
}

local lastESPPreset = nil
RegisterHeartbeatTask("ESPColorPreset", function()
    if not UI.ESPColorDropdown then return end
    local selected = UI.ESPColorDropdown.GetSelected()
    if selected and selected ~= lastESPPreset and selected ~= "None" then
        lastESPPreset = selected
        local preset = ESPColorPresets[selected]
        if preset then
            ESPColor = preset
            if UI.ESPColorRBox then UI.ESPColorRBox.Text = tostring(math.floor(preset.R * 255)) end
            if UI.ESPColorGBox then UI.ESPColorGBox.Text = tostring(math.floor(preset.G * 255)) end
            if UI.ESPColorBBox then UI.ESPColorBBox.Text = tostring(math.floor(preset.B * 255)) end
        end
    end
end)

-- ==========================================
-- CONFIG FUNCTIONS
-- ==========================================
local ConfigFuncs = (function()
    local cfg = {}

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
                if not file:find("%.json$") then continue end
                local name = file:gsub(".*[\/]", ""):gsub("%.json$", "")
                if name and name ~= "" and name ~= "NotSameServers" and name ~= "autoexec" and name ~= "autoload" then
                    table.insert(list, name)
                end
            end
        end
        return list
    end

    local function BuildCfg()
        local c={}
        for n,f in pairs(Features) do c[n]=f.E end
        c.GuiKeybind=tostring(GuiKeybind)
        c.FlyKeybind=tostring(Keybinds.Fly)
        c.SpeedHackKeybind=tostring(Keybinds.SpeedHack)
        c.ClickTpKeybind=tostring(Keybinds.ClickTp)
        c.AutoM1TradeKeybind=tostring(Keybinds.AutoM1Trade)
        c.AutoBlockKeybind=tostring(Keybinds.AutoBlock)
        c.AimlockKeybind=tostring(Keybinds.Aimlock)
        c.NoClipKeybind=tostring(Keybinds.NoClip)
        c.SafeModeKeybind=tostring(Keybinds.SafeMode)
        c.VoidKillKeybind=tostring(Keybinds.VoidKill)
        c.FlySlider=UI.GetFlySpeed and UI.GetFlySpeed() or 24
        c.SpeedHackValue=UI.GetSpeedHack and UI.GetSpeedHack() or 50
        c.SafeModeHP=UI.GetSafeModeHP and UI.GetSafeModeHP() or 30
        c.FullBrightValue=UI.GetFullBright and UI.GetFullBright() or 3
        c.MinPlayers=UI.GetMin and UI.GetMin() or 1
        c.MaxPlayers=UI.GetMax and UI.GetMax() or 25
        c.Theme = CurrentTheme
        c.ESPR = math.floor(ESPColor.R * 255)
        c.ESPG = math.floor(ESPColor.G * 255)
        c.ESPB = math.floor(ESPColor.B * 255)
        c.ESPColorPreset = UI.ESPColorDropdown and UI.ESPColorDropdown.GetSelected() or "Purple"
        c.AimlockSmoothness = AimlockSmoothness
        c.AimlockPrediction = AimlockPrediction
        c.FlingTarget = UI.FlingTargetDropdown and UI.FlingTargetDropdown.GetSelected() or "All"
        return c
    end

    function cfg.RefreshConfigListUI()
        local configs = GetConfigList()
        UI.ConfigDropdown.Rebuild(configs)
    end

    function cfg.SaveCurrentConfig()
        local name = UI.ConfigNameBox.Text
        if name == "" then name = CurrentConfigName end
        name = name:gsub("[^%w_-]", "")
        if name == "" then name = "default" end
        CurrentConfigName = name
        local ok = SaveCfg(name, BuildCfg())
        if ok then
            Notify("💾 Config '"..name.."' saved!", 3)
            cfg.RefreshConfigListUI()
        else
            Notify("❌ Failed to save config", 3)
        end
    end

    function cfg.LoadCurrentConfig()
        local name = UI.ConfigNameBox.Text
        if name == "" then 
            Notify("⚠️ Enter config name first", 3)
            return
        end
        CurrentConfigName = name
        local data = LoadCfg(name)
        if not data then
            Notify("❌ Config '"..name.."' not found", 3)
            return
        end

        if data.MinPlayers and UI.SetMin then UI.SetMin(data.MinPlayers) end
        if data.MaxPlayers and UI.SetMax then UI.SetMax(data.MaxPlayers) end
        if data.FlySlider and UI.SetFlySpeed then UI.SetFlySpeed(data.FlySlider) end
        if data.FlySpeedMultiplier and UI.SetFlyMult then UI.SetFlyMult(data.FlySpeedMultiplier) end
        if data.SpeedHackValue and UI.SetSpeedHack then UI.SetSpeedHack(data.SpeedHackValue) end
        if data.SafeModeHP and UI.SetSafeModeHP then UI.SetSafeModeHP(data.SafeModeHP) end
        if data.FullBrightValue and UI.SetFullBright then UI.SetFullBright(data.FullBrightValue) end
        if data.ESPR and data.ESPG and data.ESPB then
            ESPColor = Color3.fromRGB(data.ESPR, data.ESPG, data.ESPB)
            if UI.ESPColorRBox then UI.ESPColorRBox.Text = tostring(data.ESPR) end
            if UI.ESPColorGBox then UI.ESPColorGBox.Text = tostring(data.ESPG) end
            if UI.ESPColorBBox then UI.ESPColorBBox.Text = tostring(data.ESPB) end
        end
        if data.ESPColorPreset and UI.ESPColorDropdown then
            UI.ESPColorDropdown.SetSelected(data.ESPColorPreset)
        end
        if data.AimlockSmoothness then
            AimlockSmoothness = data.AimlockSmoothness
            if UI.SetAimlockSmooth then UI.SetAimlockSmooth(math.floor(AimlockSmoothness * 10)) end
        end
        if data.AimlockPrediction then
            AimlockPrediction = data.AimlockPrediction
            if UI.SetAimlockPred then UI.SetAimlockPred(math.floor(AimlockPrediction * 10)) end
        end
        if data.FlingTarget and UI.FlingTargetDropdown then
            UI.FlingTargetDropdown.SetSelected(data.FlingTarget)
        end

        local function applyKeybind(keyName, featName, btn)
            if data[keyName] then
                local ok,kc=pcall(function() return Enum.KeyCode[data[keyName]] end)
                if ok and kc then
                    Keybinds[featName] = kc
                    if btn then btn.Text = kc.Name end
                else
                    local ok2,ut=pcall(function() return Enum.UserInputType[data[keyName]] end)
                    if ok2 and ut then
                        Keybinds[featName] = ut
                        if btn then btn.Text = ut.Name end
                    end
                end
            end
        end

        applyKeybind("GuiKeybind", "Gui", UI.KbBtn)
        applyKeybind("FlyKeybind", "Fly", UI.FlyKb)
        applyKeybind("SpeedHackKeybind", "SpeedHack", UI.SpeedHackKb)
        applyKeybind("ClickTpKeybind", "ClickTp", UI.ClickTpKb)
        applyKeybind("AutoM1TradeKeybind", "AutoM1Trade", UI.AutoM1TradeKb)
        applyKeybind("AutoBlockKeybind", "AutoBlock", UI.AutoBlockKb)
        applyKeybind("AimlockKeybind", "Aimlock", UI.AimlockKb)
        applyKeybind("NoClipKeybind", "NoClip", UI.NoClipKb)
        applyKeybind("SafeModeKeybind", "SafeMode", UI.SafeModeKb)
        applyKeybind("VoidKillKeybind", "VoidKill", UI.VoidKillsKb)

        if data.Theme then
            if Themes[data.Theme] then
                UI.ApplyTheme(data.Theme)
                if UI.ThemeDropdown then UI.ThemeDropdown.SetSelected(data.Theme) end
            end
        end

        for featName, enabled in pairs(data) do
            local isEnabled = (enabled == true) or (enabled == "true") or (enabled == 1)
            if isEnabled and Features[featName] and not Features[featName].E then
                Features[featName].E = true
                if _G.RarityTSBStarters[featName] then
                    task.spawn(_G.RarityTSBStarters[featName])
                end
            end
        end
        Notify("📂 Config '"..name.."' loaded!", 3)
    end

    function cfg.DeleteCurrentConfig()
        local name = UI.ConfigNameBox.Text
        if name == "" then Notify("Enter config name", 3) return end
        local path = ConfigFolder.."/"..name..".json"
        if isfile(path) then
            pcall(function() delfile(path) end)
            Notify("Config '"..name.."' deleted!", 3)
            cfg.RefreshConfigListUI()
        else
            Notify("❌ Config not found", 3)
        end
    end

    function cfg.SetupAutoLoad()
        local name = UI.ConfigNameBox.Text
        if name == "" then Notify("⚠️ Enter config name first", 3) return end
        name = name:gsub("[^%w_-]", "")
        if name == "" then Notify("Invalid config name", 3) return end
        local path = ConfigFolder .. "/autoload.txt"
        local ok = pcall(function() writefile(path, name) end)
        if ok then Notify("📌 AutoLoad set to '" .. name .. "'", 3)
        else Notify("Failed to set AutoLoad", 3) end
    end

    function cfg.DeleteAutoLoad()
        local path = ConfigFolder .. "/autoload.txt"
        if isfile(path) then
            pcall(function() delfile(path) end)
            Notify("🗑️ AutoLoad deleted", 3)
        else
            Notify("📭 AutoLoad is empty", 3)
        end
    end

    return cfg
end)()

-- ==========================================
-- SERVER HOP
-- ==========================================
ServerHop = (function()
    local function SetupAutoExec()
        local loaderTemplate = [[
repeat task.wait() until game:IsLoaded()
task.wait(1.5)
local url = "%s" .. "?nocache=" .. tostring(tick())
local ok, src = pcall(function() return game:HttpGet(url) end)
if ok and src and #src > 100 then loadstring(src)() else end
]]
        local loader = string.format(loaderTemplate, SCRIPT_URL)
        if type(queue_on_teleport) == "function" then pcall(queue_on_teleport, loader)
        elseif type(queueonteleport) == "function" then pcall(queueonteleport, loader) end
    end

    return function()
        if ServerHopRunning then
            Notify("🔄 Server hop already running", 3)
            return
        end
        ServerHopRunning = true
        local startJobId = game.JobId
        SetupAutoExec()

        task.delay(10, function()
            if not ServerHopRunning then return end
            if game.JobId == startJobId then
                Notify("🔄 Teleport failed, retrying...", 3)
                ServerHopRunning = false
                task.wait(1.5)
                ServerHop()
            end
        end)

        task.spawn(function()
            local ok, err = pcall(function()
                Notify("🔍 Fetching servers...", 2)
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
                local baseDelay = 0.3
                local failCount = 0

                for _, order in ipairs(orders) do
                    if found then break end
                    local fa = ""
                    local emptyCount = 0

                    for attempt = 1, 120 do
                        if found then break end

                        local url = 'https://games.roblox.com/v1/games/'..PID..'/servers/Public?sortOrder='..order..'&limit=100'..'&_nc='..tostring(tick())
                        if fa ~= "" and fa ~= "null" then
                            url = url .. '&cursor=' .. HttpService:UrlEncode(fa)
                        end

                        local response
                        local httpOk, httpErr = pcall(function() response = game:HttpGet(url) end)

                        if not httpOk then
                            failCount = failCount + 1
                            local backoff = math.min(failCount * 0.5, 3)
                            task.wait(backoff)
                        elseif not response or response == "" then
                            emptyCount = emptyCount + 1
                            if emptyCount >= 3 then
                                task.wait(2)
                                emptyCount = 0
                            else
                                task.wait(0.5)
                            end
                        else
                            local decodeOk, S = pcall(function() return HttpService:JSONDecode(response) end)
                            if not decodeOk or not S or not S.data then
                                task.wait(0.5)
                            else
                                failCount = 0
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
                                            pcall(function() writefile("NotSameServers.json", HttpService:JSONEncode(AIDs)) end)
                                            Notify("🚀 Teleporting (" .. pl .. "/" .. mp .. ")", 3)
                                            local hopOk = pcall(function() TeleportService:TeleportToPlaceInstance(PID, sid, player) end)
                                            if not hopOk then continue end
                                            found = true
                                            break
                                        end
                                    end
                                end
                                if fa == "" then break end
                                task.wait(baseDelay)
                            end
                        end
                    end
                end
                if not found then Notify("❌ No server found (try lower Min)", 5) end
            end)
            if not ok then
                Notify("Hop Error: " .. tostring(err):sub(1, 50), 5)
            end
            ServerHopRunning = false
        end)
    end
end)()

-- ==========================================
-- GLOBAL STARTERS / STOPPERS
-- ==========================================
_G.RarityTSBStarters = {
    AutoM1Trade = CombatFuncs.StartAutoM1Trade,
    AutoBlock = CombatFuncs.StartAutoBlock,
    Aimlock = CombatFuncs.StartAimlock,
    NoStun = CombatFuncs.StartNoStun,
    NoDashCooldown = CombatFuncs.StartNoDashCooldown,

    Invisibility = CombatFuncs.StartInvisibility,
    AntiDeathCounter = CombatFuncs.StartAntiDeathCounter,
    ESP = ESPFuncs.StartESP,
    Tracers = ESPFuncs.StartTracers,
    Chams = ESPFuncs.StartChams,
    ClickTp = MovementFuncs.StartClickTp,
    Fly = MovementFuncs.StartFly,
    SpeedHack = MovementFuncs.StartSpeedHack,
    NoClip = MovementFuncs.StartNoClip,
    SafeMode = QoLFuncs.StartSafeMode,
    FullBright = QoLFuncs.StartFullBright,
    VoidKills = PlayersFuncs.StartVoidKills,
    Fling = PlayersFuncs.StartFling,
    AntiFling = PlayersFuncs.StartAntiFling,
}
_G.RarityTSBStoppers = {
    AutoM1Trade = CombatFuncs.StopAutoM1Trade,
    AutoBlock = CombatFuncs.StopAutoBlock,
    Aimlock = CombatFuncs.StopAimlock,
    NoStun = CombatFuncs.StopNoStun,
    NoDashCooldown = CombatFuncs.StopNoDashCooldown,

    Invisibility = CombatFuncs.StopInvisibility,
    AntiDeathCounter = CombatFuncs.StopAntiDeathCounter,
    ESP = ESPFuncs.StopESP,
    Tracers = ESPFuncs.StopTracers,
    Chams = ESPFuncs.StopChams,
    ClickTp = MovementFuncs.StopClickTp,
    Fly = MovementFuncs.StopFly,
    SpeedHack = MovementFuncs.StopSpeedHack,
    NoClip = MovementFuncs.StopNoClip,
    SafeMode = QoLFuncs.StopSafeMode,
    FullBright = QoLFuncs.StopFullBright,
    VoidKills = PlayersFuncs.StopVoidKills,
    Fling = PlayersFuncs.StopFling,
    AntiFling = PlayersFuncs.StopAntiFling,
}

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

ST(UI.AutoM1TradeT, UI.AutoM1TradeC, UI.AutoM1TradeS, "AutoM1Trade", CombatFuncs.StartAutoM1Trade, CombatFuncs.StopAutoM1Trade)
ST(UI.AutoBlockT, UI.AutoBlockC, UI.AutoBlockS, "AutoBlock", CombatFuncs.StartAutoBlock, CombatFuncs.StopAutoBlock)
ST(UI.AimlockT, UI.AimlockC, UI.AimlockS, "Aimlock", CombatFuncs.StartAimlock, CombatFuncs.StopAimlock)
ST(UI.NoStunT, UI.NoStunC, UI.NoStunS, "NoStun", CombatFuncs.StartNoStun, CombatFuncs.StopNoStun)
ST(UI.NoDashCooldownT, UI.NoDashCooldownC, UI.NoDashCooldownS, "NoDashCooldown", CombatFuncs.StartNoDashCooldown, CombatFuncs.StopNoDashCooldown)

ST(UI.InvisibilityT, UI.InvisibilityC, UI.InvisibilityS, "Invisibility", CombatFuncs.StartInvisibility, CombatFuncs.StopInvisibility)
ST(UI.AntiDeathCounterT, UI.AntiDeathCounterC, UI.AntiDeathCounterS, "AntiDeathCounter", CombatFuncs.StartAntiDeathCounter, CombatFuncs.StopAntiDeathCounter)
ST(UI.EspT, UI.EspCir, UI.EspS, "ESP", ESPFuncs.StartESP, ESPFuncs.StopESP)
ST(UI.TracersT, UI.TracersC, UI.TracersS, "Tracers", ESPFuncs.StartTracers, ESPFuncs.StopTracers)
ST(UI.ChamsT, UI.ChamsC, UI.ChamsS, "Chams", ESPFuncs.StartChams, ESPFuncs.StopChams)
ST(UI.ClickTpT, UI.ClickTpC, UI.ClickTpS, "ClickTp", MovementFuncs.StartClickTp, MovementFuncs.StopClickTp)
ST(UI.FlyT, UI.FlyC, UI.FlyS, "Fly", MovementFuncs.StartFly, MovementFuncs.StopFly)
ST(UI.SpeedHackT, UI.SpeedHackC, UI.SpeedHackS, "SpeedHack", MovementFuncs.StartSpeedHack, MovementFuncs.StopSpeedHack)
ST(UI.NoClipT, UI.NoClipC, UI.NoClipS, "NoClip", MovementFuncs.StartNoClip, MovementFuncs.StopNoClip)
ST(UI.SafeModeT, UI.SafeModeC, UI.SafeModeS, "SafeMode", QoLFuncs.StartSafeMode, QoLFuncs.StopSafeMode)
ST(UI.FullBrightT, UI.FullBrightC, UI.FullBrightS, "FullBright", QoLFuncs.StartFullBright, QoLFuncs.StopFullBright)
ST(UI.VoidKillsT, UI.VoidKillsC, UI.VoidKillsS, "VoidKills", PlayersFuncs.StartVoidKills, PlayersFuncs.StopVoidKills)
ST(UI.FlingT, UI.FlingC, UI.FlingS, "Fling", PlayersFuncs.StartFling, PlayersFuncs.StopFling)
ST(UI.AntiFlingT, UI.AntiFlingC, UI.AntiFlingS, "AntiFling", PlayersFuncs.StartAntiFling, PlayersFuncs.StopAntiFling)
ST(UI.TrackEvasiveT, UI.TrackEvasiveC, UI.TrackEvasiveS, "TrackEvasive", function() CooldownGui.Enabled = true end, function() CooldownGui.Enabled = false end)
ST(UI.TrackFrontDashT, UI.TrackFrontDashC, UI.TrackFrontDashS, "TrackFrontDash", function() CooldownGui.Enabled = true end, function() CooldownGui.Enabled = false end)
ST(UI.TrackSideDashT, UI.TrackSideDashC, UI.TrackSideDashS, "TrackSideDash", function() CooldownGui.Enabled = true end, function() CooldownGui.Enabled = false end)

-- ==========================================
-- KEYBINDS SETUP
-- ==========================================
SetupKeybindButton(UI.FlyKb, "Fly", Keybinds.Fly, function()
    Features.Fly.E = not Features.Fly.E
    AnimToggle(UI.FlyT, UI.FlyC, UI.FlyS, Features.Fly.E)
    if Features.Fly.E then MovementFuncs.StartFly() else MovementFuncs.StopFly() end
end)
SetupKeybindButton(UI.SpeedHackKb, "SpeedHack", Keybinds.SpeedHack, function()
    Features.SpeedHack.E = not Features.SpeedHack.E
    AnimToggle(UI.SpeedHackT, UI.SpeedHackC, UI.SpeedHackS, Features.SpeedHack.E)
    if Features.SpeedHack.E then MovementFuncs.StartSpeedHack() else MovementFuncs.StopSpeedHack() end
end)
SetupKeybindButton(UI.ClickTpKb, "ClickTp", Keybinds.ClickTp, function()
    if Features.ClickTp.E then
        local c = player.Character
        if c then
            local r = c:FindFirstChild("HumanoidRootPart")
            if r then
                local pos = Mouse.Hit.Position + Vector3.new(0, 3, 0)
                r.CFrame = CFrame.new(pos)
                r.Velocity = Vector3.new(0, 0, 0)
                r.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end)
SetupKeybindButton(UI.AutoM1TradeKb, "AutoM1Trade", Keybinds.AutoM1Trade, function()
    Features.AutoM1Trade.E = not Features.AutoM1Trade.E
    AnimToggle(UI.AutoM1TradeT, UI.AutoM1TradeC, UI.AutoM1TradeS, Features.AutoM1Trade.E)
    if Features.AutoM1Trade.E then CombatFuncs.StartAutoM1Trade() else CombatFuncs.StopAutoM1Trade() end
end)
SetupKeybindButton(UI.AutoBlockKb, "AutoBlock", Keybinds.AutoBlock, function()
    Features.AutoBlock.E = not Features.AutoBlock.E
    AnimToggle(UI.AutoBlockT, UI.AutoBlockC, UI.AutoBlockS, Features.AutoBlock.E)
    if Features.AutoBlock.E then CombatFuncs.StartAutoBlock() else CombatFuncs.StopAutoBlock() end
end)
SetupKeybindButton(UI.AimlockKb, "Aimlock", Keybinds.Aimlock, function()
    Features.Aimlock.E = not Features.Aimlock.E
    AnimToggle(UI.AimlockT, UI.AimlockC, UI.AimlockS, Features.Aimlock.E)
    if Features.Aimlock.E then CombatFuncs.StartAimlock() else CombatFuncs.StopAimlock() end
end)
SetupKeybindButton(UI.NoClipKb, "NoClip", Keybinds.NoClip, function()
    Features.NoClip.E = not Features.NoClip.E
    AnimToggle(UI.NoClipT, UI.NoClipC, UI.NoClipS, Features.NoClip.E)
    if Features.NoClip.E then MovementFuncs.StartNoClip() else MovementFuncs.StopNoClip() end
end)
SetupKeybindButton(UI.SafeModeKb, "SafeMode", Keybinds.SafeMode, function()
    Features.SafeMode.E = not Features.SafeMode.E
    AnimToggle(UI.SafeModeT, UI.SafeModeC, UI.SafeModeS, Features.SafeMode.E)
    if Features.SafeMode.E then QoLFuncs.StartSafeMode() else QoLFuncs.StopSafeMode() end
end)
SetupKeybindButton(UI.VoidKillsKb, "VoidKill", Keybinds.VoidKill, PlayersFuncs.DoVoidKill)

-- Keybinds registered via SetupKeybindButton with actionFn




-- GUI Keybind via RegisterInputAction
RegisterInputAction(GuiKeybind, function()
    IsGuiHidden = not IsGuiHidden
    UI.MainFrame.Visible = not IsGuiHidden
    if not IsGuiHidden then
        local ts = UDim2.new(0, 400, 0, 520)
        local at = UI.ActiveTab()
        if at == "ESP" then ts = UDim2.new(0, 400, 0, 420)
        elseif at == "Movement" then ts = UDim2.new(0, 400, 0, 520)
        elseif at == "QoL" then ts = UDim2.new(0, 400, 0, 420)
        elseif at == "Players" then ts = UDim2.new(0, 400, 0, 480)
        elseif at == "Server" then ts = UDim2.new(0, 400, 0, 440)
        elseif at == "Settings" then ts = UDim2.new(0, 400, 0, 420) end
        UI.MainFrame.Size = ts
    end
end)

-- GUI Keybind button (rebind)
local guiKbListening = false
UI.KbBtn.MouseButton1Click:Connect(function()
    if guiKbListening then return end
    guiKbListening = true
    UI.KbBtn.Text = "..."
    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            UnregisterInputAction(GuiKeybind)
            GuiKeybind = input.KeyCode
            UI.KbBtn.Text = input.KeyCode.Name
            RegisterInputAction(GuiKeybind, function()
                IsGuiHidden = not IsGuiHidden
                UI.MainFrame.Visible = not IsGuiHidden
                if not IsGuiHidden then
                    local ts = UDim2.new(0, 400, 0, 520)
                    local at = UI.ActiveTab()
                    if at == "ESP" then ts = UDim2.new(0, 400, 0, 420)
                    elseif at == "Movement" then ts = UDim2.new(0, 400, 0, 520)
                    elseif at == "QoL" then ts = UDim2.new(0, 400, 0, 420)
                    elseif at == "Players" then ts = UDim2.new(0, 400, 0, 480)
                    elseif at == "Server" then ts = UDim2.new(0, 400, 0, 440)
                    elseif at == "Settings" then ts = UDim2.new(0, 400, 0, 420) end
                    UI.MainFrame.Size = ts
                end
            end)
            guiKbListening = false
            pcall(function() conn:Disconnect() end)
        end
    end)
    task.delay(5, function()
        if guiKbListening then
            guiKbListening = false
            UI.KbBtn.Text = GuiKeybind.Name
            pcall(function() conn:Disconnect() end)
        end
    end)
end)

-- ==========================================
-- DASH DETECTION FOR COOLDOWN TRACKERS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        local char = getCharacter()
        local isRagdoll = false
        if char then
            local hum = getHumanoid()
            if hum then
                if hum.PlatformStand or hum:GetState() == Enum.HumanoidStateType.Physics or hum:GetState() == Enum.HumanoidStateType.Ragdoll then
                    isRagdoll = true
                end
            end
            -- Check for ragdoll animations
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local animator = hum:FindFirstChildOfClass("Animator")
                if animator then
                    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                        if track.Name:lower():find("ragdoll") or track.Name:lower():find("knock") or track.Name:lower():find("down") then
                            isRagdoll = true
                            break
                        end
                    end
                end
            end
            -- Check for JustUnrag accessory (evasive indicator)
            if char:FindFirstChild("JustUnrag") then
                isRagdoll = true
            end
        end
        if isRagdoll then
            if not CooldownData.Evasive.Active then
                CooldownData.Evasive.Current = CooldownData.Evasive.Max
                CooldownData.Evasive.Active = true
                CooldownData.Evasive.LastUse = tick()
            end
        else
            local isSide = UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.D)
            if isSide then
                if not CooldownData.Side.Active then
                    CooldownData.Side.Current = CooldownData.Side.Max
                    CooldownData.Side.Active = true
                    CooldownData.Side.LastUse = tick()
                end
            else
                if not CooldownData.FrontBack.Active then
                    CooldownData.FrontBack.Current = CooldownData.FrontBack.Max
                    CooldownData.FrontBack.Active = true
                    CooldownData.FrontBack.LastUse = tick()
                end
            end
        end
    end
end)

-- ==========================================
-- BUTTONS
-- ==========================================
UI.SaveCfgBtn.MouseButton1Click:Connect(ConfigFuncs.SaveCurrentConfig)
UI.LoadCfgBtn.MouseButton1Click:Connect(ConfigFuncs.LoadCurrentConfig)
UI.DelCfgBtn.MouseButton1Click:Connect(ConfigFuncs.DeleteCurrentConfig)
UI.SetupAutoLoadBtn.MouseButton1Click:Connect(ConfigFuncs.SetupAutoLoad)
UI.DeleteAutoLoadBtn.MouseButton1Click:Connect(ConfigFuncs.DeleteAutoLoad)

UI.ServerHopBtn.MouseButton1Click:Connect(function()
    Notify("Starting server hop...", 2)
    ServerHop()
end)

UI.RejoinBtn.MouseButton1Click:Connect(function()
    Notify("🔄 Rejoining...", 3)
    local loaderTemplate = [[
repeat task.wait() until game:IsLoaded()
task.wait(1.5)
local url = "%s" .. "?nocache=" .. tostring(tick())
local ok, src = pcall(function() return game:HttpGet(url) end)
if ok and src and #src > 100 then loadstring(src)() else end
]]
    local loader = string.format(loaderTemplate, SCRIPT_URL)
    if type(queue_on_teleport) == "function" then pcall(queue_on_teleport, loader)
    elseif type(queueonteleport) == "function" then pcall(queueonteleport, loader) end
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end)

-- ==========================================
-- PLAYER DROPDOWN & BUTTONS
-- ==========================================
local function refreshPlayers()
    local list = getPlayerList()
    UI.PlayersDropdown.Rebuild(list)
    -- Update Fling target dropdown with current players + "All"
    local flingList = {"All"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then table.insert(flingList, p.Name) end
    end
    if UI.FlingTargetDropdown then
        UI.FlingTargetDropdown.Rebuild(flingList)
    end
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()

RegisterHeartbeatTask("HealthUpdate", function()
    local pName = UI.PlayersDropdown.GetSelected()
    if pName and pName ~= "None" then
        local target = Players:FindFirstChild(pName)
        if target and target.Character then
            local hum = target.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.MaxHealth > 0 then
                local pct = math.floor((hum.Health / hum.MaxHealth) * 100)
                UI.PlayerHealthLbl.Text = "Health: " .. pct .. "%"
            else
                UI.PlayerHealthLbl.Text = "Health: --"
            end
        else
            UI.PlayerHealthLbl.Text = "Health: --"
        end
    else
        UI.PlayerHealthLbl.Text = "Health: --"
    end
end)

UI.TeleportPlayerBtn.MouseButton1Click:Connect(function()
    local name = UI.PlayersDropdown.GetSelected()
    if not name or name == "None" then Notify("No player selected", 2) return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local target = Players:FindFirstChild(name)
    if not target or not target.Character then Notify("Player not found", 2) return end
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if targetHRP then
        hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 5)
        hrp.Velocity = Vector3.new(0, 0, 0)
        Notify("Teleported to " .. name, 2)
    else
        Notify("No root part found", 2)
    end
end)

-- ==========================================
-- EXECUTOR DETECTION
-- ==========================================
local function DetectExecutor()
    local name = "Unknown"
    if type(identifyexecutor) == "function" then
        local s,r = pcall(identifyexecutor)
        if s and r then name = r end
    elseif type(getexecutorname) == "function" then
        local s,r = pcall(getexecutorname)
        if s and r then name = r end
    end
    if name == "Unknown" then
        local env = {}
        if type(getgenv) == "function" then
            local s,r = pcall(getgenv)
            if s and type(r) == "table" then env = r end
        end
        local map = {potassium="Potassium",fluxus="Fluxus",syn="Synapse X",krnl="KRNL",volt="Volt",xeno="Xeno",arceus="Arceus X"}
        for k,v in pairs(map) do if env[k] ~= nil then name = v break end end
    end
    local lower = name:lower()
    local status = "🟠 Supported with issues"
    local color = Color3.fromRGB(255, 220, 120)
    if lower:find("potassium") or lower:find("volt") or lower:find("synapse") or lower:find("fluxus") then
        status = "🟢 Supported"
        color = Color3.fromRGB(120, 255, 150)
    elseif lower:find("xeno") or lower:find("arceus") then
        status = "🔴 Not supported"
        color = Color3.fromRGB(255, 120, 120)
    end
    return name, status, color
end

pcall(function()
    task.spawn(function()
        task.wait(0.5)
        local name, status, color = DetectExecutor()
        UI.ExecNameLbl.Text = "Executor: " .. name
        UI.ExecStatusLbl.Text = "Status: " .. status
        UI.ExecStatusLbl.TextColor3 = color
    end)
end)

-- ==========================================
-- AUTOLOAD
-- ==========================================
local HasAutoLoaded = false
local autoLoadTriggered = false
RegisterHeartbeatTask("AutoLoad", function()
    if autoLoadTriggered then UnregisterHeartbeatTask("AutoLoad") return end
    local char = player.Character
    if not char then return end
    if HasAutoLoaded then return end
    HasAutoLoaded = true
    task.wait(3)
    local autoLoadPath = ConfigFolder .. "/autoload.txt"
    if isfile(autoLoadPath) then
        local ok, name = pcall(function() return readfile(autoLoadPath) end)
        if ok and name and name ~= "" then
            name = name:gsub("%s+", "")
            if name ~= "" then
                UI.ConfigNameBox.Text = name
                CurrentConfigName = name
                ConfigFuncs.LoadCurrentConfig()
                return
            end
        end
    end
    Notify("📭 AutoLoad is empty", 3)
end)

-- ==========================================
-- CONFIG REFRESH
-- ==========================================
ConfigFuncs.RefreshConfigListUI()

-- ==========================================
-- CHARACTER ADDED HANDLERS
-- ==========================================
player.CharacterAdded:Connect(function(char)
    task.wait(1)
    if Features.Invisibility.E then
        CombatFuncs.StartInvisibility()
    end
    if Features.NoClip.E then
        MovementFuncs.StartNoClip()
    end
    if Features.AntiFling.E then
        PlayersFuncs.StartAntiFling()
    end
end)

-- ==========================================
-- GRAVITY SAFEGUARD
-- ==========================================
RegisterHeartbeatTask("GravityGuard", function()
    if not Features.Fly.E and Workspace.Gravity == 0 then
        Workspace.Gravity = _G.RarityTSBOriginalGravity or 196.2
    end
end)

-- ==========================================
-- CLEANUP ON DESTROY
-- ==========================================
UI.ScreenGui.Destroying:Connect(function()
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
    StopMasterConnections()
end)

Notify("✅ rarity.tsb loaded", 4)
task.wait(0.1)
