repeat task.wait() until game:IsLoaded()

if type(clearteleportqueue) == "function" then pcall(clearteleportqueue)
elseif type(clearteleport_queue) == "function" then pcall(clearteleport_queue) end

if getgenv().NezurHubLoaded then print("[Nezur] Already loaded, skipping...") return end
getgenv().NezurHubLoaded = true

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GuiService = game:GetService("GuiService")
local VIM = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local Mouse = player:GetMouse()

local oldGui = playerGui:FindFirstChild("NezurHub")
if oldGui then oldGui:Destroy() end

local SCRIPT_URL = "https://raw.githubusercontent.com/kresteq/bridgerAnticheatSUCKS/refs/heads/main/1337.lua"
local ConfigFolder = "Nezur"
if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

local CurrentConfigName = "default"
local SHC = {MinPlayers=1, MaxPlayers=25}
local GuiKeybind = Enum.KeyCode.F1
local FlyKeybind = Enum.KeyCode.E
local SpectatorKeybind = Enum.KeyCode.RightControl
local FlySpeed = 24
local IsListening = false
local IsFlyListening = false
local IsGuiHidden = false
local ServerHopRunning = false

local Features = {
    Corpse={E=false,C=nil}, Bank={E=false,C=nil}, Chest={E=false,C=nil},
    SaintScanner={E=false,C=nil}, ESP={E=false,C=nil,PlayerAdded=nil,PlayerRemoving=nil},
    ClickTp={E=false,C=nil}, Fly={E=false,C=nil,KC=nil},
    RaknetDesync={E=false,C=nil}, HideName={E=false,C=nil},
    AutoBuy={E=false,C=nil}, AttachPlayer={E=false,C=nil},
    NoClip={E=false,C=nil}, Invisible={E=false,C=nil},
    Spectator={E=false,C=nil}
}

local saintsPartNames = {"SaintsLeftArm","SaintsRightArm","SaintsLeftLeg","SaintsRightLeg","SaintsRibcage"}
local SAINT_COORDS = {
    Vector3.new(-4114,65,-4982),Vector3.new(-3803,243,-6001),
    Vector3.new(-7982,59,-3252),Vector3.new(-4496,45,-2004),
    Vector3.new(-4183,46,-3999),Vector3.new(-5511,54,-4653),
    Vector3.new(-4016,45,-2764),Vector3.new(-7780,47,-4511),
    Vector3.new(-1756,58,-2980)
}

-- ==========================================
-- AUTO PLAY & EQUIP
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
    for _, item in ipairs(bp:GetChildren()) do if item:IsA("Tool") then table.insert(tools, item) end end
    if #tools > 0 then pcall(function() hum:EquipTool(tools[math.random(1, #tools)]) end) end
end
player.CharacterAdded:Connect(function() task.spawn(AutoEquipRandom) end)

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
    if PressPlayButton() then task.delay(0.5, function() GuiService.SelectedObject = nil end) end
    task.wait(3)
end
task.spawn(AutoEquipRandom)

-- ==========================================
-- NOTIFICATIONS (IIFE)
-- ==========================================
local Notify = (function()
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

    return function(text, dur)
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
end)()

-- ==========================================
-- GUI SETUP (IIFE)
-- ==========================================
local UI = (function()
    local ui = {}

    for _, child in ipairs(playerGui:GetChildren()) do
        if child.Name == "NezurHub" then child:Destroy() end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NezurHub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = playerGui
    ui.ScreenGui = ScreenGui

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
    ui.MainFrame = MainFrame

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
    TitleText.Text = "▼ Nezur 🔮"
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
            MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end
    end)

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

    local TabNames = {"Auto Farms","ESP","Movement","QoL","Players & NPCs","Misc","Server","Settings"}
    local TabButtons = {}
    local TabContents = {}
    local ActiveTab = "Auto Farms"
    ui.ActiveTab = function() return ActiveTab end
    ui.SetActiveTab = function(v) ActiveTab = v end

    for i,name in ipairs(TabNames) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1/8,-2,1,0)
        btn.Position = UDim2.new((1/8)*(i-1),1,0,0)
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
            elseif name=="QoL" then ts = UDim2.new(0,400,0,420)
            elseif name=="Players & NPCs" then ts = UDim2.new(0,400,0,420)
            elseif name=="Misc" then ts = UDim2.new(0,400,0,480)
            elseif name=="Server" then ts = UDim2.new(0,400,0,460)
            elseif name=="Settings" then ts = UDim2.new(0,400,0,560) end
            TweenService:Create(MainFrame,TweenInfo.new(0.3),{Size=ts}):Play()
        end)
    end

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

    local function CreateMultiDropdown(parent, posY, labelText, optionsTable, featureName)
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
        Label.TextColor3 = Color3.fromRGB(192, 192, 192)
        Label.TextSize = 12
        Label.Font = Enum.Font.Gotham
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextYAlignment = Enum.TextYAlignment.Center
        Label.ZIndex = 51
        Label.Parent = Container

        local DropBtn = Instance.new("TextButton")
        DropBtn.Name = "DropBtn"
        DropBtn.Size = UDim2.new(0.55, 0, 1, 0)
        DropBtn.Position = UDim2.new(0.45, 0, 0, 0)
        DropBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 53)
        DropBtn.Text = "Select..."
        DropBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
        DropBtn.TextSize = 11
        DropBtn.Font = Enum.Font.GothamMedium
        DropBtn.AutoButtonColor = false
        DropBtn.ZIndex = 51
        DropBtn.Parent = Container

        Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 6)

        -- Overlay frame parented to ScreenGui
        local ListFrame = Instance.new("ScrollingFrame")
        ListFrame.Name = featureName.."List"
        ListFrame.Size = UDim2.new(0, DropBtn.AbsoluteSize.X, 0, 0)
        ListFrame.Position = UDim2.new(0, 0, 0, 0)
        ListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        ListFrame.BorderSizePixel = 0
        ListFrame.Visible = false
        ListFrame.ZIndex = 9999
        ListFrame.ScrollBarThickness = 3
        ListFrame.ScrollBarImageColor3 = Color3.fromRGB(139, 123, 184)
        ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        ListFrame.Parent = ScreenGui

        Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 6)

        local ListStroke = Instance.new("UIStroke")
        ListStroke.Color = Color3.fromRGB(42, 42, 53)
        ListStroke.Thickness = 1
        ListStroke.Parent = ListFrame

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 2)
        ListLayout.Parent = ListFrame

        local selected = {}
        local optionButtons = {}

        local function updateListPosition()
            local absPos = DropBtn.AbsolutePosition
            local absSize = DropBtn.AbsoluteSize
            ListFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
            ListFrame.Size = UDim2.new(0, absSize.X, 0, math.min(#optionsTable * 26 + 4, 140))
        end

        for _, opt in ipairs(optionsTable) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, -8, 0, 24)
            optBtn.Position = UDim2.new(0, 4, 0, 0)
            optBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 53)
            optBtn.Text = "  " .. opt
            optBtn.TextColor3 = Color3.fromRGB(192, 192, 192)
            optBtn.TextSize = 11
            optBtn.Font = Enum.Font.Gotham
            optBtn.TextXAlignment = Enum.TextXAlignment.Left
            optBtn.AutoButtonColor = false
            optBtn.ZIndex = 10000
            optBtn.Parent = ListFrame

            Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 4)

            optBtn.MouseButton1Click:Connect(function()
                if selected[opt] then
                    selected[opt] = nil
                    optBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 53)
                    optBtn.TextColor3 = Color3.fromRGB(192, 192, 192)
                else
                    selected[opt] = true
                    optBtn.BackgroundColor3 = Color3.fromRGB(107, 91, 149)
                    optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
                local names = {}
                for name, _ in pairs(selected) do table.insert(names, name) end
                if #names == 0 then DropBtn.Text = "Select..."
                elseif #names == 1 then DropBtn.Text = names[1]
                else DropBtn.Text = #names .. " selected" end
            end)

            optionButtons[opt] = optBtn
        end

        local listHeight = math.min(#optionsTable * 26 + 4, 140)
        ListFrame.Size = UDim2.new(0, DropBtn.AbsoluteSize.X, 0, listHeight)
        ListFrame.CanvasSize = UDim2.new(0, 0, 0, #optionsTable * 26 + 8)

        local open = false
        DropBtn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                updateListPosition()
            end
            ListFrame.Visible = open
        end)

        -- Global click-away for this dropdown
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

        Container.Destroying:Connect(function()
            if clickAwayConn then clickAwayConn:Disconnect() end
            if ListFrame then ListFrame:Destroy() end
        end)

        return {
            Frame = Container,
            GetSelected = function()
                local t = {}
                for name, _ in pairs(selected) do table.insert(t, name) end
                return t
            end,
            SetSelected = function(names)
                selected = {}
                for _, name in ipairs(names) do
                    selected[name] = true
                    if optionButtons[name] then
                        optionButtons[name].BackgroundColor3 = Color3.fromRGB(107, 91, 149)
                        optionButtons[name].TextColor3 = Color3.fromRGB(255, 255, 255)
                    end
                end
                if #names == 0 then DropBtn.Text = "Select..."
                elseif #names == 1 then DropBtn.Text = names[1]
                else DropBtn.Text = #names .. " selected" end
            end
        }, posY + 34
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
        Label.TextColor3 = Color3.fromRGB(192, 192, 192)
        Label.TextSize = 12
        Label.Font = Enum.Font.Gotham
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextYAlignment = Enum.TextYAlignment.Center
        Label.ZIndex = 51
        Label.Parent = Container

        local DropBtn = Instance.new("TextButton")
        DropBtn.Name = "DropBtn"
        DropBtn.Size = UDim2.new(0.55, 0, 1, 0)
        DropBtn.Position = UDim2.new(0.45, 0, 0, 0)
        DropBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 53)
        DropBtn.Text = "None"
        DropBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
        DropBtn.TextSize = 11
        DropBtn.Font = Enum.Font.GothamMedium
        DropBtn.AutoButtonColor = false
        DropBtn.ZIndex = 51
        DropBtn.Parent = Container

        Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 6)

        -- Overlay frame parented to ScreenGui for proper rendering above all
        local ListFrame = Instance.new("ScrollingFrame")
        ListFrame.Name = featureName.."List"
        ListFrame.Size = UDim2.new(0, DropBtn.AbsoluteSize.X, 0, 0)
        ListFrame.Position = UDim2.new(0, 0, 0, 0)
        ListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        ListFrame.BorderSizePixel = 0
        ListFrame.Visible = false
        ListFrame.ZIndex = listZIndex
        ListFrame.ScrollBarThickness = 3
        ListFrame.ScrollBarImageColor3 = Color3.fromRGB(139, 123, 184)
        ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        ListFrame.Parent = ScreenGui

        Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 6)

        local ListStroke = Instance.new("UIStroke")
        ListStroke.Color = Color3.fromRGB(42, 42, 53)
        ListStroke.Thickness = 1
        ListStroke.Parent = ListFrame

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 2)
        ListLayout.Parent = ListFrame

        local currentSelection = nil
        local optionButtons = {}
        local open = false

        local function updateListPosition()
            local absPos = DropBtn.AbsolutePosition
            local absSize = DropBtn.AbsoluteSize
            ListFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
            ListFrame.Size = UDim2.new(0, absSize.X, 0, math.min(#optionButtons * 26 + 4, 160))
        end

        local function rebuildList(options)
            for _, btn in pairs(optionButtons) do btn:Destroy() end
            optionButtons = {}
            for _, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, -8, 0, 24)
                optBtn.Position = UDim2.new(0, 4, 0, 0)
                optBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 53)
                optBtn.Text = "  " .. opt
                optBtn.TextColor3 = Color3.fromRGB(192, 192, 192)
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
            local listHeight = math.min(#options * 26 + 4, 160)
            ListFrame.Size = UDim2.new(0, DropBtn.AbsoluteSize.X, 0, listHeight)
            ListFrame.CanvasSize = UDim2.new(0, 0, 0, #options * 26 + 8)
        end

        DropBtn.MouseButton1Click:Connect(function()
            open = not open
            if open then
                updateListPosition()
            end
            ListFrame.Visible = open
        end)

        -- Global click-away handler for THIS dropdown
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

        -- Cleanup on destroy
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

    -- Auto Farms Tab
    local FarmC = TabContents["Auto Farms"]
    local fy = 0
    fy = CreateSection(FarmC,"Auto Farms",fy)
    ui.CorpseT, ui.CorpseC, ui.CorpseS, fy = CreateToggle(FarmC,"Auto Corpse",fy,"Corpse")
    ui.BankT, ui.BankC, ui.BankS, fy = CreateToggle(FarmC,"Auto Bank",fy,"Bank")
    ui.ChestT, ui.ChestC, ui.ChestS, fy = CreateToggle(FarmC,"Auto Chest",fy,"Chest")
    fy = CreateSection(FarmC,"Scanner",fy+5)
    ui.ScanT, ui.ScanC, ui.ScanS, fy = CreateToggle(FarmC,"Saint Scanner",fy,"SaintScanner")
    ui.TeleportBtn, fy = CreateButton(FarmC,"Teleport to Saint",fy,"TeleportBtn")
    ui.TeleportBtn.BackgroundColor3 = Color3.fromRGB(42,42,53)
    ui.TeleportBtn.TextColor3 = Color3.fromRGB(139,123,184)
    ui.TeleportBtn.Visible = false

    -- ESP Tab
    local EspC = TabContents["ESP"]
    local ey = 0
    ey = CreateSection(EspC,"Player ESP",ey)
    ui.EspT, ui.EspCir, ui.EspS, ey = CreateToggle(EspC,"Player ESP",ey,"ESP")

    -- Movement Tab
    local MovC = TabContents["Movement"]
    local mvy = 0
    mvy = CreateSection(MovC,"Movement",mvy)
    ui.ClickTpT, ui.ClickTpC, ui.ClickTpS, mvy = CreateToggle(MovC,"Click Teleport",mvy,"ClickTp")
    local FlyWarn = Instance.new("TextLabel",MovC)
    FlyWarn.Size = UDim2.new(1,0,0,40)
    FlyWarn.Position = UDim2.new(0,0,0,mvy)
    FlyWarn.BackgroundTransparency = 1
    FlyWarn.Text = "⚠️CAUTION⚠️After 10s of flying, AntiCheat drops HP to 0⚠️DONT TURN OFF FLY AT LOW HP⚠️"
    FlyWarn.TextColor3 = Color3.fromRGB(255,100,100)
    FlyWarn.TextSize = 10
    FlyWarn.Font = Enum.Font.GothamBold
    FlyWarn.TextXAlignment = Enum.TextXAlignment.Left
    FlyWarn.TextYAlignment = Enum.TextYAlignment.Top
    FlyWarn.TextWrapped = true
    mvy = mvy + 44
    ui.FlyT, ui.FlyC, ui.FlyS, mvy = CreateToggle(MovC,"Fly",mvy,"Fly")
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
    ui.FlyKbBtn = Instance.new("TextButton",MovC)
    ui.FlyKbBtn.Size = UDim2.new(0,80,0,24)
    ui.FlyKbBtn.Position = UDim2.new(1,-80,0,mvy)
    ui.FlyKbBtn.BackgroundColor3 = Color3.fromRGB(42,42,53)
    ui.FlyKbBtn.Text = "E"
    ui.FlyKbBtn.TextColor3 = Color3.fromRGB(184,168,216)
    ui.FlyKbBtn.TextSize = 11
    ui.FlyKbBtn.Font = Enum.Font.GothamMedium
    ui.FlyKbBtn.AutoButtonColor = false
    Instance.new("UICorner",ui.FlyKbBtn).CornerRadius = UDim.new(0,6)
    mvy = mvy + 30
    ui.SpeedRow, ui.GetFlySpeed, mvy, ui.SetFlySpeed = CreateSlider(MovC,"Fly Speed",mvy,10,100,20,function(v) FlySpeed = v + (v * v) / 100 end)

    -- QoL Tab
    local QoLC = TabContents["QoL"]
    local qolY = 0
    qolY = CreateSection(QoLC, "Auto Buy", qolY)
    local buyableItems = {"Tonic", "AmmoPack", "SilverAmmoPack", "ArrowPack", "FlameArrowPack", "Knives"}
    ui.ItemDropdown, qolY = CreateMultiDropdown(QoLC, qolY, "Items", buyableItems, "BuyItems")
    ui.AutoBuyT, ui.AutoBuyC, ui.AutoBuyS, qolY = CreateToggle(QoLC, "Auto Buy", qolY, "AutoBuy")
    ui.BuyItemBtn, qolY = CreateButton(QoLC, "Buy Item", qolY, "BuyItemBtn")
    qolY = CreateSection(QoLC, "Attach", qolY + 8)
    ui.PlayerDropdown, qolY = CreateDropdown(QoLC, qolY, "Target", "AttachPlayer")
    ui.AttachT, ui.AttachC, ui.AttachS, qolY = CreateToggle(QoLC, "Attach", qolY, "AttachPlayer")
    local AttachKbLbl = Instance.new("TextLabel", QoLC)
    AttachKbLbl.Size = UDim2.new(0.6, 0, 0, 24)
    AttachKbLbl.Position = UDim2.new(0, 0, 0, qolY)
    AttachKbLbl.BackgroundTransparency = 1
    AttachKbLbl.Text = "Attach Keybind"
    AttachKbLbl.TextColor3 = Color3.fromRGB(192, 192, 192)
    AttachKbLbl.TextSize = 12
    AttachKbLbl.Font = Enum.Font.Gotham
    AttachKbLbl.TextXAlignment = Enum.TextXAlignment.Left
    ui.AttachKbBtn = Instance.new("TextButton", QoLC)
    ui.AttachKbBtn.Size = UDim2.new(0, 80, 0, 24)
    ui.AttachKbBtn.Position = UDim2.new(1, -80, 0, qolY)
    ui.AttachKbBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 53)
    ui.AttachKbBtn.Text = "G"
    ui.AttachKbBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
    ui.AttachKbBtn.TextSize = 11
    ui.AttachKbBtn.Font = Enum.Font.GothamMedium
    ui.AttachKbBtn.AutoButtonColor = false
    Instance.new("UICorner", ui.AttachKbBtn).CornerRadius = UDim.new(0, 6)

    -- Players & NPCs Tab
    local PnC = TabContents["Players & NPCs"]
    local pny = 0
    pny = CreateSection(PnC, "Players", pny)

    local playerRowY = pny
    ui.PlayersDropdown, pny = CreateDropdown(PnC, pny, "Target", "PlayersTarget", 9998)
    ui.PlayersDropdown.Frame.Size = UDim2.new(0.58, -4, 0, 28)

    ui.SpectatePlayerBtn = Instance.new("TextButton")
    ui.SpectatePlayerBtn.Name = "SpectatePlayerBtn"
    ui.SpectatePlayerBtn.Size = UDim2.new(0.19, -2, 0, 28)
    ui.SpectatePlayerBtn.Position = UDim2.new(0.58, 2, 0, playerRowY)
    ui.SpectatePlayerBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 69)
    ui.SpectatePlayerBtn.Text = "Spectate"
    ui.SpectatePlayerBtn.TextColor3 = Color3.fromRGB(192, 192, 192)
    ui.SpectatePlayerBtn.TextSize = 11
    ui.SpectatePlayerBtn.Font = Enum.Font.GothamMedium
    ui.SpectatePlayerBtn.AutoButtonColor = false
    ui.SpectatePlayerBtn.Parent = PnC
    Instance.new("UICorner", ui.SpectatePlayerBtn).CornerRadius = UDim.new(0, 6)
    ui.SpectatePlayerBtn.MouseEnter:Connect(function()
        TweenService:Create(ui.SpectatePlayerBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(107, 91, 149)}):Play()
    end)
    ui.SpectatePlayerBtn.MouseLeave:Connect(function()
        TweenService:Create(ui.SpectatePlayerBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(58, 58, 69)}):Play()
    end)

    ui.TeleportPlayerBtn = Instance.new("TextButton")
    ui.TeleportPlayerBtn.Name = "TeleportPlayerBtn"
    ui.TeleportPlayerBtn.Size = UDim2.new(0.19, -2, 0, 28)
    ui.TeleportPlayerBtn.Position = UDim2.new(0.77, 4, 0, playerRowY)
    ui.TeleportPlayerBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 69)
    ui.TeleportPlayerBtn.Text = "Teleport"
    ui.TeleportPlayerBtn.TextColor3 = Color3.fromRGB(192, 192, 192)
    ui.TeleportPlayerBtn.TextSize = 11
    ui.TeleportPlayerBtn.Font = Enum.Font.GothamMedium
    ui.TeleportPlayerBtn.AutoButtonColor = false
    ui.TeleportPlayerBtn.Parent = PnC
    Instance.new("UICorner", ui.TeleportPlayerBtn).CornerRadius = UDim.new(0, 6)
    ui.TeleportPlayerBtn.MouseEnter:Connect(function()
        TweenService:Create(ui.TeleportPlayerBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(107, 91, 149)}):Play()
    end)
    ui.TeleportPlayerBtn.MouseLeave:Connect(function()
        TweenService:Create(ui.TeleportPlayerBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(58, 58, 69)}):Play()
    end)

    ui.PlayerHealthLbl = Instance.new("TextLabel")
    ui.PlayerHealthLbl.Size = UDim2.new(1, 0, 0, 20)
    ui.PlayerHealthLbl.Position = UDim2.new(0, 0, 0, pny)
    ui.PlayerHealthLbl.BackgroundTransparency = 1
    ui.PlayerHealthLbl.Text = "Health: --"
    ui.PlayerHealthLbl.TextColor3 = Color3.fromRGB(192, 192, 192)
    ui.PlayerHealthLbl.TextSize = 12
    ui.PlayerHealthLbl.Font = Enum.Font.Gotham
    ui.PlayerHealthLbl.TextXAlignment = Enum.TextXAlignment.Left
    ui.PlayerHealthLbl.Parent = PnC
    pny = pny + 24

    pny = CreateSection(PnC, "NPCs", pny + 8)

    local npcRowY = pny
    ui.NPCDropdown, pny = CreateDropdown(PnC, pny, "Target", "NPCTarget", 10001)
    ui.NPCDropdown.Frame.Size = UDim2.new(0.58, -4, 0, 28)

    ui.TeleportNPCBtn = Instance.new("TextButton")
    ui.TeleportNPCBtn.Name = "TeleportNPCBtn"
    ui.TeleportNPCBtn.Size = UDim2.new(0.19, -2, 0, 28)
    ui.TeleportNPCBtn.Position = UDim2.new(0.77, 4, 0, npcRowY)
    ui.TeleportNPCBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 69)
    ui.TeleportNPCBtn.Text = "Teleport"
    ui.TeleportNPCBtn.TextColor3 = Color3.fromRGB(192, 192, 192)
    ui.TeleportNPCBtn.TextSize = 11
    ui.TeleportNPCBtn.Font = Enum.Font.GothamMedium
    ui.TeleportNPCBtn.AutoButtonColor = false
    ui.TeleportNPCBtn.Parent = PnC
    Instance.new("UICorner", ui.TeleportNPCBtn).CornerRadius = UDim.new(0, 6)
    ui.TeleportNPCBtn.MouseEnter:Connect(function()
        TweenService:Create(ui.TeleportNPCBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(107, 91, 149)}):Play()
    end)
    ui.TeleportNPCBtn.MouseLeave:Connect(function()
        TweenService:Create(ui.TeleportNPCBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(58, 58, 69)}):Play()
    end)



    -- Misc Tab
    local MiscC = TabContents["Misc"]
    local miy = 0
    miy = CreateSection(MiscC,"Exploits",miy)
    ui.RakT, ui.RakC, ui.RakS, miy = CreateToggle(MiscC,"Raknet Desync",miy,"RaknetDesync")
    ui.NoClipT, ui.NoClipC, ui.NoClipS, miy = CreateToggle(MiscC,"NoClip",miy,"NoClip")
    ui.InvisT, ui.InvisC, ui.InvisS, miy = CreateToggle(MiscC,"Invisible",miy,"Invisible")
    miy = CreateSection(MiscC,"General",miy+5)
    ui.HideT, ui.HideC, ui.HideS, miy = CreateToggle(MiscC,"Hide Name",miy,"HideName")
    miy = CreateSection(MiscC,"TEST",miy+5)
    ui.SpectatorT, ui.SpectatorC, ui.SpectatorS, miy = CreateToggle(MiscC,"Spectator Mode",miy,"Spectator")
    ui.SpectatorKbBtn = Instance.new("TextButton",MiscC)
    ui.SpectatorKbBtn.Size = UDim2.new(0,80,0,24)
    ui.SpectatorKbBtn.Position = UDim2.new(1,-80,0,miy)
    ui.SpectatorKbBtn.BackgroundColor3 = Color3.fromRGB(42,42,53)
    ui.SpectatorKbBtn.Text = "RightCtrl"
    ui.SpectatorKbBtn.TextColor3 = Color3.fromRGB(184,168,216)
    ui.SpectatorKbBtn.TextSize = 11
    ui.SpectatorKbBtn.Font = Enum.Font.GothamMedium
    ui.SpectatorKbBtn.AutoButtonColor = false
    Instance.new("UICorner",ui.SpectatorKbBtn).CornerRadius = UDim.new(0,6)
    miy = miy + 30
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
    ui.KbBtn = Instance.new("TextButton",MiscC)
    ui.KbBtn.Size = UDim2.new(0,80,0,24)
    ui.KbBtn.Position = UDim2.new(1,-80,0,miy)
    ui.KbBtn.BackgroundColor3 = Color3.fromRGB(42,42,53)
    ui.KbBtn.Text = "F1"
    ui.KbBtn.TextColor3 = Color3.fromRGB(184,168,216)
    ui.KbBtn.TextSize = 11
    ui.KbBtn.Font = Enum.Font.GothamMedium
    ui.KbBtn.AutoButtonColor = false
    Instance.new("UICorner",ui.KbBtn).CornerRadius = UDim.new(0,6)

    -- Server Tab
    local ServC = TabContents["Server"]
    local sv = 0
    sv = CreateSection(ServC,"Server Hop",sv)
    ui.MinRow, ui.GetMin, sv, ui.SetMin = CreateSlider(ServC,"Min Players",sv,1,25,1,function(v) SHC.MinPlayers=v end)
    ui.MaxRow, ui.GetMax, sv, ui.SetMax = CreateSlider(ServC,"Max Players",sv,1,25,25,function(v) SHC.MaxPlayers=v end)
    sv = CreateSection(ServC,"Actions",sv+5)
    ui.ServerHopBtn, sv = CreateButton(ServC,"Server Hop",sv,"ServerHopBtn")
    ui.RejoinBtn, sv = CreateButton(ServC,"Rejoin Server",sv,"RejoinBtn")

    -- Settings Tab
    local SetC = TabContents["Settings"]
    local sy = 0
    sy = CreateSection(SetC,"Executor",sy)
    ui.ExecNameLbl = Instance.new("TextLabel",SetC)
    ui.ExecNameLbl.Size = UDim2.new(1,0,0,20)
    ui.ExecNameLbl.Position = UDim2.new(0,0,0,sy)
    ui.ExecNameLbl.BackgroundTransparency = 1
    ui.ExecNameLbl.Text = "Executor: Detecting..."
    ui.ExecNameLbl.TextColor3 = Color3.fromRGB(192,192,192)
    ui.ExecNameLbl.TextSize = 12
    ui.ExecNameLbl.Font = Enum.Font.Gotham
    ui.ExecNameLbl.TextXAlignment = Enum.TextXAlignment.Left
    sy = sy + 22
    ui.ExecStatusLbl = Instance.new("TextLabel",SetC)
    ui.ExecStatusLbl.Size = UDim2.new(1,0,0,20)
    ui.ExecStatusLbl.Position = UDim2.new(0,0,0,sy)
    ui.ExecStatusLbl.BackgroundTransparency = 1
    ui.ExecStatusLbl.Text = "Status: Detecting..."
    ui.ExecStatusLbl.TextColor3 = Color3.fromRGB(255,200,100)
    ui.ExecStatusLbl.TextSize = 12
    ui.ExecStatusLbl.Font = Enum.Font.Gotham
    ui.ExecStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
    sy = sy + 22
    sy = CreateSection(SetC,"Config Management",sy+5)
    ui.ConfigNameBox, sy = CreateTextBox(SetC,"Config Name",sy,"Enter name...")
    sy = sy + 5
    ui.ConfigListFrame = Instance.new("ScrollingFrame")
    ui.ConfigListFrame.Size = UDim2.new(1,0,0,140)
    ui.ConfigListFrame.Position = UDim2.new(0,0,0,sy)
    ui.ConfigListFrame.BackgroundColor3 = Color3.fromRGB(30,30,40)
    ui.ConfigListFrame.BorderSizePixel = 0
    ui.ConfigListFrame.ScrollBarThickness = 4
    ui.ConfigListFrame.Parent = SetC
    Instance.new("UICorner", ui.ConfigListFrame).CornerRadius = UDim.new(0,6)
    ui.listLayout = Instance.new("UIListLayout", ui.ConfigListFrame)
    ui.listLayout.Padding = UDim.new(0,2)
    sy = sy + 105
    ui.SaveCfgBtn, sy = CreateButton(SetC,"Save Config",sy,"SaveCfgBtn")
    ui.LoadCfgBtn, sy = CreateButton(SetC,"Load Config",sy,"LoadCfgBtn")
    ui.DelCfgBtn, sy = CreateButton(SetC,"Delete Config",sy,"DelCfgBtn")
    ui.SetupAutoLoadBtn, sy = CreateButton(SetC,"Setup AutoLoad",sy,"SetupAutoLoadBtn")
    ui.DeleteAutoLoadBtn, sy = CreateButton(SetC,"Delete AutoLoad",sy,"DeleteAutoLoadBtn")

    return ui
end)()

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

local function getNPCList()
    local list = {}
    local npcFolder = Workspace:FindFirstChild("NPC")
    if npcFolder then
        for _, npc in ipairs(npcFolder:GetChildren()) do
            if npc:IsA("Model") then
                table.insert(list, npc.Name)
            end
        end
    end
    return list
end

-- ==========================================
-- QoL FUNCTIONS (IIFE)
-- ==========================================
local QoLFuncs = (function()
    local qol = {}
    local ITEM_LIMITS = {
        Tonic = 5, AmmoPack = 5, ArrowPack = 5,
        FlameArrowPack = 1, SilverAmmoPack = 1, Knives = 1000,
    }
    local autoBuyRunning = false
    local attachConnection = nil
    local attachActive = false
    local AttachKeybind = Enum.KeyCode.G
    local IsAttachListening = false
local IsSpectatorListening = false
    local lastBuyNotif = 0

    local function countItem(itemName)
        local backpack = player:FindFirstChild("Backpack")
        if not backpack then return 0 end
        local count = 0
        for _, item in ipairs(backpack:GetChildren()) do
            if item.Name == itemName then count = count + 1 end
        end
        local char = player.Character
        if char then
            for _, item in ipairs(char:GetChildren()) do
                if item.Name == itemName then count = count + 1 end
            end
        end
        return count
    end

    local function buyItems(itemNames, buyOnce)
        if not Workspace:FindFirstChild("PurchasePads") then return end
        local bought = {}
        local purchasedItems = {}
        for _, pad in ipairs(Workspace.PurchasePads:GetChildren()) do
            local bb = pad:FindFirstChildOfClass("BillboardGui")
            local label = bb and bb:FindFirstChildOfClass("TextLabel")
            if label then
                for _, itemName in ipairs(itemNames) do
                    if not buyOnce or not purchasedItems[itemName] then
                        if label.Text:find(itemName) then
                            local current = countItem(itemName)
                            local limit = ITEM_LIMITS[itemName] or 999
                            if current < limit then
                                local cd = pad:FindFirstChildOfClass("ClickDetector")
                                if cd then
                                    fireclickdetector(cd)
                                    table.insert(bought, itemName)
                                    if buyOnce then purchasedItems[itemName] = true end
                                end
                            end
                        end
                    end
                end
            end
        end
        if #bought > 0 then
            local now = tick()
            if now - lastBuyNotif > 2 then
                lastBuyNotif = now
                Notify("Bought " .. table.concat(bought, ", "), 2)
            end
        end
    end

    local function getPlayerList()
        local list = {}
        local entities = Workspace:FindFirstChild("Entities")
        if not entities then return list end
        local realPlayers = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then realPlayers[p.Name] = true end
        end
        for _, ent in ipairs(entities:GetChildren()) do
            if ent:IsA("Model") and realPlayers[ent.Name] then table.insert(list, ent.Name) end
        end
        return list
    end

    local function getSaintPartPlayers()
        local list = {}
        local entities = Workspace:FindFirstChild("Entities")
        if not entities then return list end
        local realPlayers = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then realPlayers[p.Name] = true end
        end
        for _, ent in ipairs(entities:GetChildren()) do
            if ent:IsA("Model") and realPlayers[ent.Name] then
                for _, partName in ipairs(saintsPartNames) do
                    if ent:FindFirstChild(partName) then
                        table.insert(list, ent.Name)
                        break
                    end
                end
            end
        end
        return list
    end

    function qol.startAutoBuy()
        if autoBuyRunning then return end
        autoBuyRunning = true
        task.spawn(function()
            while Features.AutoBuy.E and autoBuyRunning do
                local items = UI.ItemDropdown.GetSelected()
                if #items > 0 then buyItems(items) end
                task.wait(0.5)
            end
            autoBuyRunning = false
        end)
    end

    function qol.stopAutoBuy()
        Features.AutoBuy.E = false
        autoBuyRunning = false
    end

    function qol.startAttach()
        attachActive = true
        if attachConnection then attachConnection:Disconnect() end
        attachConnection = RunService.Heartbeat:Connect(function()
            if not attachActive then return end
            local selected = UI.PlayerDropdown.GetSelected()
            if not selected or selected == "None" then return end
            local char = player.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local targetName = selected:gsub("^%[SAINT%] ", "")
            local targetModel = Workspace:FindFirstChild("Entities") and Workspace.Entities:FindFirstChild(targetName)
            if not targetModel then targetModel = Workspace:FindFirstChild(targetName) end
            if not targetModel then return end
            local targetHrp = targetModel:FindFirstChild("HumanoidRootPart")
            if targetHrp then hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3) end
        end)
    end

    function qol.stopAttach()
        attachActive = false
        if attachConnection then
            attachConnection:Disconnect()
            attachConnection = nil
        end
    end

    function qol.getPlayerList() return getPlayerList() end
    function qol.getSaintPartPlayers() return getSaintPartPlayers() end
    function qol.buyItems(items, once) return buyItems(items, once) end
    qol.AttachKeybind = function() return AttachKeybind end
    qol.SetAttachKeybind = function(v) AttachKeybind = v end
    qol.IsAttachListening = function() return IsAttachListening end
    qol.SetIsAttachListening = function(v) IsAttachListening = v end

    return qol
end)()

-- ==========================================
-- PLAYER DROPDOWN REFRESH
-- ==========================================
task.spawn(function()
    while true do
        local saintPlayers = QoLFuncs.getSaintPartPlayers()
        local displayList = {}
        for _, name in ipairs(saintPlayers) do table.insert(displayList, "[SAINT] " .. name) end
        for _, name in ipairs(QoLFuncs.getPlayerList()) do
            local isSaint = false
            for _, sname in ipairs(saintPlayers) do
                if sname == name then isSaint = true break end
            end
            if not isSaint then table.insert(displayList, name) end
        end
        UI.PlayerDropdown.Rebuild(displayList)
        if UI.PlayersDropdown then UI.PlayersDropdown.Rebuild(displayList) end
        task.wait(5)
    end
end)

-- ==========================================
-- AUTO CORPSE (IIFE)
-- ==========================================
local FarmFuncs = (function()
    local farm = {}

    function farm.StartCorpse()
        Notify("🟣 Auto Corpse active")
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

    function farm.StopCorpse()
        Notify("⚫ Auto Corpse disabled")
        if Features.Corpse.C then Features.Corpse.C:Disconnect() Features.Corpse.C = nil end
    end

    -- ==========================================
    -- AUTO BANK
    -- ==========================================
    local BankRunning = false
    local BankThread = nil

    function farm.StartBank()
        if BankRunning then return end
        BankRunning = true
        Notify("🟣 Auto Bank active")

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
                if not tostring(err):find("STOP") then warn("Auto Bank error:", err) end
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

    function farm.StopBank()
        Notify("⚫ Auto Bank disabled")
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
    function farm.StartChest()
        Notify("🟣 Auto Chest active")
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

    function farm.StopChest()
        Notify("⚫ Auto Chest disabled")
        if Features.Chest.C then Features.Chest.C:Disconnect() Features.Chest.C = nil end
    end

    return farm
end)()

-- ==========================================
-- SAINT SCANNER (IIFE)
-- ==========================================
local ScannerFuncs = (function()
    local scan = {}
    local ScannerData = {DP=nil,DPos=nil,Scan=false}

    function scan.StartScanner()
        Notify("🔮 Saint Scanner active")
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
                    UI.TeleportBtn.Visible = true
                    Notify("Saint detected!", 4)
                end
            else
                last = nil
                ScannerData.DP = nil
                ScannerData.DPos = nil
                UI.TeleportBtn.Visible = false
            end
            task.wait(2)
        end)
    end

    function scan.StopScanner()
        Notify("⚫ Saint Scanner disabled")
        ScannerData.Scan = false
        ScannerData.DP = nil
        ScannerData.DPos = nil
        UI.TeleportBtn.Visible = false
        if Features.SaintScanner.C then Features.SaintScanner.C:Disconnect() Features.SaintScanner.C = nil end
    end

    UI.TeleportBtn.MouseButton1Click:Connect(function()
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

    return scan
end)()

-- ==========================================
-- ESP SYSTEM (IIFE)
-- ==========================================
local ESPFuncs = (function()
    local esp = {}
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

    function esp.StartESP()
        Notify("👁️ Player ESP active")
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player then CreateESPText(p) end
        end
        Features.ESP.C = RunService.RenderStepped:Connect(UpdateESP)
        Features.ESP.PlayerAdded = Players.PlayerAdded:Connect(function(p) CreateESPText(p) end)
        Features.ESP.PlayerRemoving = Players.PlayerRemoving:Connect(function(p) RemoveESPText(p) end)
    end

    function esp.StopESP()
        Notify("⚫ Player ESP disabled")
        if Features.ESP.C then Features.ESP.C:Disconnect() Features.ESP.C = nil end
        if Features.ESP.PlayerAdded then Features.ESP.PlayerAdded:Disconnect() Features.ESP.PlayerAdded = nil end
        if Features.ESP.PlayerRemoving then Features.ESP.PlayerRemoving:Disconnect() Features.ESP.PlayerRemoving = nil end
        for _, d in pairs(ESPDrawings) do d:Remove() end
        ESPDrawings = {}
    end

    return esp
end)()

-- ==========================================
-- CLICK TP & FLY (IIFE)
-- ==========================================
local MovementFuncs = (function()
    local mov = {}

    function mov.StartClickTp()
        Notify("🖱️ ClickTP active (Shift+Click)")
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

    function mov.StopClickTp()
        Notify("⚫ ClickTP disabled")
        if Features.ClickTp.C then Features.ClickTp.C:Disconnect() Features.ClickTp.C = nil end
    end

    local FlyConn = nil
    local FlyAct = false

    function mov.StartFly()
        Notify("🪽 Fly active")
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

    function mov.StopFly()
        Notify("⚫ Fly disabled")
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

    return mov
end)()

-- ==========================================
-- SPECTATOR MODE (IIFE)
-- ==========================================
local SpectatorFuncs = (function()
    local spec = {}
    local active = false
    local originalPos = nil
    local originalCFrame = nil
    local targetY = nil
    local charConnections = {}
    local rsConnection = nil
    local renderConnection = nil
    local replicationPart = nil
    local lastFocusPos = nil
    local FLY_HEIGHT = 50000
    local MOVE_SPEED = 50
    local REPFOCUS_UPDATE_DIST = 500

    local function cleanupCharConnections()
        for _, conn in ipairs(charConnections) do
            if conn then conn:Disconnect() end
        end
        charConnections = {}
    end

    local function destroyReplicationPart()
        if replicationPart and replicationPart.Parent then
            replicationPart:Destroy()
        end
        replicationPart = nil
    end

    function spec.StartSpectator()
        Notify("👁 Spectator Mode active")
        local char = player.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not hrp then return end

        active = true
        originalPos = hrp.Position
        originalCFrame = hrp.CFrame
        targetY = originalPos.Y + FLY_HEIGHT
        lastFocusPos = originalPos

        -- Replication focus at ground level
        destroyReplicationPart()
        local repPart = Instance.new("Part")
        repPart.Name = "_SPEC_REPFOCUS_"
        repPart.Anchored = true
        repPart.CanCollide = false
        repPart.Transparency = 1
        repPart.Size = Vector3.new(1, 1, 1)
        repPart.CFrame = CFrame.new(originalPos)
        repPart.Parent = Workspace
        replicationPart = repPart
        player.ReplicationFocus = repPart

        -- PlatformStand + stop physics
        humanoid.PlatformStand = true
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        hrp.Velocity = Vector3.new(0, 0, 0)

        -- Teleport up
        local lookDir = hrp.CFrame.LookVector
        local newPos = Vector3.new(originalPos.X, targetY, originalPos.Z)
        hrp.CFrame = CFrame.lookAt(newPos, newPos + Vector3.new(lookDir.X, 0, lookDir.Z))

        -- Heartbeat: Fly movement + ReplicationFocus follows CAMERA
        rsConnection = RunService.Heartbeat:Connect(function()
            if not active then return end
            if not hrp.Parent or not humanoid.Parent then return end

            humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)

            local md = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then md = md + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then md = md + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then md = md + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then md = md + Vector3.new(1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then md = md + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then md = md + Vector3.new(0, -1, 0) end

            if md.Magnitude > 0 then
                md = md.Unit
                local cam = Workspace.CurrentCamera
                local moveDir = (cam.CFrame.LookVector * -md.Z + cam.CFrame.RightVector * md.X + Vector3.new(0, md.Y, 0)).Unit
                hrp.Velocity = moveDir * MOVE_SPEED
                hrp.CFrame = CFrame.new(hrp.Position + moveDir * 0.5)
            else
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                hrp.Velocity = Vector3.new(0, 0, 0)
            end

            -- ReplicationFocus follows CAMERA position
            if replicationPart then
                local camPos = camera.CFrame.Position
                local distFromLast = (Vector3.new(camPos.X, 0, camPos.Z) - Vector3.new(lastFocusPos.X, 0, lastFocusPos.Z)).Magnitude
                if distFromLast > REPFOCUS_UPDATE_DIST then
                    replicationPart.CFrame = CFrame.new(camPos.X, originalPos.Y, camPos.Z)
                    lastFocusPos = replicationPart.Position
                end
            end
        end)

        -- RenderStepped: shift camera down
        renderConnection = RunService.RenderStepped:Connect(function()
            if not active then return end
            camera.CFrame = camera.CFrame - Vector3.new(0, FLY_HEIGHT, 0)
        end)

        -- Death handler
        local diedConn = humanoid.Died:Connect(function()
            spec.StopSpectator()
        end)
        table.insert(charConnections, diedConn)
    end

    function spec.StopSpectator()
        Notify("⚫ Spectator Mode disabled")
        active = false
        cleanupCharConnections()

        if rsConnection then rsConnection:Disconnect() rsConnection = nil end
        if renderConnection then renderConnection:Disconnect() renderConnection = nil end

        local char = player.Character
        if not char then
            player.ReplicationFocus = nil
            destroyReplicationPart()
            return
        end

        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if not hrp or not humanoid or not originalPos then
            player.ReplicationFocus = nil
            destroyReplicationPart()
            return
        end

        -- Staged return with landing platform
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        hrp.Velocity = Vector3.new(0, 0, 0)

        local landPlatform = Instance.new("Part")
        landPlatform.Name = "_SPEC_LAND_"
        landPlatform.Size = Vector3.new(50, 1, 50)
        landPlatform.Anchored = true
        landPlatform.CanCollide = true
        landPlatform.Transparency = 1
        landPlatform.Position = Vector3.new(originalPos.X, originalPos.Y - 0.5, originalPos.Z)
        landPlatform.Parent = Workspace

        humanoid.PlatformStand = false
        task.wait(0.1)
        hrp.CFrame = CFrame.new(originalPos.X, originalPos.Y + 5, originalPos.Z)
            * CFrame.Angles(0, math.atan2(hrp.CFrame.LookVector.X, hrp.CFrame.LookVector.Z), 0)

        task.wait(0.3)
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        task.wait(0.1)

        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.CFrame = CFrame.new(originalPos.X, originalPos.Y + 3, originalPos.Z)
            * CFrame.Angles(0, math.atan2(hrp.CFrame.LookVector.X, hrp.CFrame.LookVector.Z), 0)

        landPlatform:Destroy()
        player.ReplicationFocus = nil
        destroyReplicationPart()

        originalPos = nil
        originalCFrame = nil
        targetY = nil
        lastFocusPos = nil
    end

    function spec.SpectatorKeybind() return SpectatorKeybind end
    function spec.SetSpectatorKeybind(v) SpectatorKeybind = v end
    function spec.IsSpectatorListening() return IsSpectatorListening end
    function spec.SetIsSpectatorListening(v) IsSpectatorListening = v end

    return spec
end)()

-- ==========================================
-- RAKNET & HIDE NAME (IIFE)
-- ==========================================
local ExploitFuncs = (function()
    local exp = {}

    function exp.StartRaknet()
        Notify("📡 Raknet active (U)")
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

    function exp.StopRaknet()
        Notify("⚫ Raknet disabled")
        if Features.RaknetDesync.C then Features.RaknetDesync.C:Disconnect() Features.RaknetDesync.C = nil end
    end

    function exp.StartHide()
        Notify("👤 Hide Name active")
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

    function exp.StopHide()
        Notify("⚫ Hide Name disabled")
        if Features.HideName.C then Features.HideName.C:Disconnect() Features.HideName.C = nil end
    end

    return exp
end)()

-- ==========================================
-- NOCLIP & INVISIBLE (IIFE)
-- ==========================================
local NoClipFuncs = (function()
    local nc = {}
    local NoClipConn = nil
    local NoClipActive = false
    local InvisConn = nil
    local InvisActive = false
    local OriginalCanCollide = {}

    function nc.StartNoClip()
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
        NoClipConn = RunService.Stepped:Connect(function()
            if not NoClipActive then return end
            local c = player.Character
            if not c then return end
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    if OriginalCanCollide[part] == nil then
                        OriginalCanCollide[part] = part.CanCollide
                    end
                    part.CanCollide = false
                end
            end
        end)
        nc.CharAddedConn = player.CharacterAdded:Connect(function(c)
            if not NoClipActive then return end
            task.wait(0.1)
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    OriginalCanCollide[part] = part.CanCollide
                    part.CanCollide = false
                end
            end
        end)
    end

    function nc.StopNoClip()
        Notify("⚫ NoClip disabled")
        NoClipActive = false
        if NoClipConn then NoClipConn:Disconnect() NoClipConn = nil end
        if nc.CharAddedConn then nc.CharAddedConn:Disconnect() nc.CharAddedConn = nil end
        local c = player.Character
        if c then
            for part, orig in pairs(OriginalCanCollide) do
                if part and part.Parent then
                    part.CanCollide = orig
                end
            end
        end
        OriginalCanCollide = {}
    end

    local InvisOriginals = {}
    local InvisDescendantConn = nil
    local InvisToolConn = nil

    function nc.StartInvisible()
        Notify("🫥 Invisible active")
        InvisActive = true
        InvisOriginals = {}

        local function storeAndHide(obj, prop, val)
            if not InvisOriginals[obj] then InvisOriginals[obj] = {} end
            if InvisOriginals[obj][prop] == nil then
                InvisOriginals[obj][prop] = obj[prop]
            end
            obj[prop] = val
        end

        local function hidePart(part)
            if not part or not part:IsA("BasePart") then return end
            if part.Name == "HumanoidRootPart" then return end
            -- Use Transparency (not LocalTransparencyModifier) for SurfaceAppearance compatibility
            storeAndHide(part, "Transparency", 1)
            storeAndHide(part, "CastShadow", false)
            -- Handle SurfaceAppearance
            if part:FindFirstChildOfClass("SurfaceAppearance") then
                local sa = part:FindFirstChildOfClass("SurfaceAppearance")
                storeAndHide(sa, "AlphaMode", Enum.AlphaMode.Overlay)
            end
        end

        local function hideDecal(dec)
            if not dec then return end
            storeAndHide(dec, "Transparency", 1)
        end

        local function applyInvis(c)
            if not c then return end
            -- All BaseParts (MeshParts, Parts, Unions) - use Transparency for SurfaceAppearance compat
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    hidePart(part)
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    hideDecal(part)
                elseif part:IsA("SurfaceGui") or part:IsA("BillboardGui") then
                    storeAndHide(part, "Enabled", false)
                elseif part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") then
                    storeAndHide(part, "Enabled", false)
                elseif part:IsA("PointLight") or part:IsA("SpotLight") or part:IsA("SurfaceLight") then
                    storeAndHide(part, "Enabled", false)
                elseif part:IsA("SurfaceAppearance") then
                    storeAndHide(part, "AlphaMode", Enum.AlphaMode.Overlay)
                end
            end
            -- Also handle direct children (tools)
            for _, child in ipairs(c:GetChildren()) do
                if child:IsA("Tool") then
                    for _, part in ipairs(child:GetDescendants()) do
                        if part:IsA("BasePart") then hidePart(part)
                        elseif part:IsA("Decal") or part:IsA("Texture") then hideDecal(part) end
                    end
                end
            end
        end

        local function onDescendantAdded(desc)
            if not InvisActive then return end
            if desc:IsA("BasePart") then
                hidePart(desc)
            elseif desc:IsA("Decal") or desc:IsA("Texture") then
                hideDecal(desc)
            elseif desc:IsA("SurfaceGui") or desc:IsA("BillboardGui") then
                storeAndHide(desc, "Enabled", false)
            elseif desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") then
                storeAndHide(desc, "Enabled", false)
            elseif desc:IsA("PointLight") or desc:IsA("SpotLight") or desc:IsA("SurfaceLight") then
                storeAndHide(desc, "Enabled", false)
            elseif desc:IsA("SurfaceAppearance") then
                storeAndHide(desc, "AlphaMode", Enum.AlphaMode.Overlay)
            elseif desc:IsA("Tool") then
                for _, part in ipairs(desc:GetDescendants()) do
                    if part:IsA("BasePart") then hidePart(part)
                    elseif part:IsA("Decal") or part:IsA("Texture") then hideDecal(part) end
                end
            end
        end

        local function setupCharacter(c)
            if not c then return end
            applyInvis(c)
            if InvisDescendantConn then InvisDescendantConn:Disconnect() end
            InvisDescendantConn = c.DescendantAdded:Connect(onDescendantAdded)
        end

        setupCharacter(player.Character)
        InvisConn = player.CharacterAdded:Connect(function(c)
            if not InvisActive then return end
            task.wait(0.3)
            setupCharacter(c)
        end)
    end

    function nc.StopInvisible()
        Notify("⚫ Invisible disabled")
        InvisActive = false
        if InvisConn then InvisConn:Disconnect() InvisConn = nil end
        if InvisDescendantConn then InvisDescendantConn:Disconnect() InvisDescendantConn = nil end
        if InvisToolConn then InvisToolConn:Disconnect() InvisToolConn = nil end
        for obj, props in pairs(InvisOriginals) do
            if obj and obj.Parent then
                for prop, val in pairs(props) do
                    pcall(function() obj[prop] = val end)
                end
            end
        end
        InvisOriginals = {}
    end

    return nc
end)()

-- ==========================================
-- SERVER HOP (IIFE)
-- ==========================================
ServerHop = (function()
    local function SetupAutoExec()
        local loaderTemplate = [[
repeat task.wait() until game:IsLoaded()
task.wait(1.5)
local url = "%s" .. "?nocache=" .. tostring(tick())
local ok, src = pcall(function() return game:HttpGet(url) end)
if ok and src and #src > 100 then loadstring(src)()
else warn("[Nezur] AutoExec failed") end
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

        task.delay(7, function()
            if not ServerHopRunning then return end
            if game.JobId == startJobId then
                Notify("🔄 Teleport failed, retrying...", 3)
                ServerHopRunning = false
                task.wait(1)
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

                for _, order in ipairs(orders) do
                    if found then break end
                    local fa = ""
                    local emptyCount = 0

                    for attempt = 1, 100 do
                        if found then break end

                        local url = 'https://games.roblox.com/v1/games/'..PID..'/servers/Public?sortOrder='..order..'&limit=100'..'&_nc='..tostring(tick())
                        if fa ~= "" and fa ~= "null" then
                            url = url .. '&cursor=' .. HttpService:UrlEncode(fa)
                        end

                        local response
                        local httpOk, httpErr = pcall(function() response = game:HttpGet(url) end)

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
                            local decodeOk, S = pcall(function() return HttpService:JSONDecode(response) end)
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
                                            pcall(function() writefile("NotSameServers.json", HttpService:JSONEncode(AIDs)) end)
                                            Notify("🚀 Teleporting (" .. pl .. "/" .. mp .. ")", 3)
                                            pcall(function() TeleportService:TeleportToPlaceInstance(PID, sid, player) end)
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
                if not found then Notify("❌ No server found (try lower Min)", 5) end
            end)
            if not ok then
                Notify("Hop Error: " .. tostring(err):sub(1, 50), 5)
                warn("ServerHop Error:", err)
            end
            ServerHopRunning = false
        end)
    end
end)()

-- ==========================================
-- CONFIG FUNCTIONS (IIFE)
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
                local name = file:gsub(".*[\\/]", ""):gsub("%.json$", "")
                if name and name ~= "" and name ~= "NotSameServers" and name ~= "autoexec" then
                    table.insert(list, name)
                end
            end
        end
        return list
    end

    local function BuildCfg()
        local c={} for n,f in pairs(Features) do c[n]=f.E end
        c.GuiKeybind=tostring(GuiKeybind)
        c.FlyKeybind=tostring(FlyKeybind)
        c.FlySlider=UI.GetFlySpeed and UI.GetFlySpeed() or 20
        c.MinPlayers=UI.GetMin and UI.GetMin() or 1
        c.MaxPlayers=UI.GetMax and UI.GetMax() or 25
        c.BuyItems = UI.ItemDropdown.GetSelected()
        c.AttachTarget = UI.PlayerDropdown.GetSelected()
        c.PlayersTarget = UI.PlayersDropdown.GetSelected()
        c.NPCTarget = UI.NPCDropdown.GetSelected()
        c.AttachKeybind = tostring(QoLFuncs.AttachKeybind())
        c.SpectatorKeybind = tostring(SpectatorFuncs.SpectatorKeybind())
        c.NoClip = Features.NoClip.E
        c.Invisible = Features.Invisible.E
        c.Spectator = Features.Spectator.E
        return c
    end

    function cfg.RefreshConfigListUI()
        for _, child in ipairs(UI.ConfigListFrame:GetChildren()) do
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
            btn.Parent = UI.ConfigListFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            btn.MouseButton1Click:Connect(function()
                UI.ConfigNameBox.Text = name
                CurrentConfigName = name
            end)
        end
        UI.ConfigListFrame.CanvasSize = UDim2.new(0, 0, 0, UI.listLayout.AbsoluteContentSize.Y + 4)
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
        if data.FlySlider and UI.SetFlySpeed then UI.SetFlySpeed(data.FlySlider) elseif data.FlySpeed then FlySpeed = data.FlySpeed end

        if data.GuiKeybind then
            local ok,kc=pcall(function() return Enum.KeyCode[data.GuiKeybind] end)
            if ok and kc then GuiKeybind=kc UI.KbBtn.Text=data.GuiKeybind end
        end
        if data.FlyKeybind then
            local ok,kc=pcall(function() return Enum.KeyCode[data.FlyKeybind] end)
            if ok and kc then FlyKeybind=kc UI.FlyKbBtn.Text=data.FlyKeybind end
        end

        if data.BuyItems and #data.BuyItems > 0 then UI.ItemDropdown.SetSelected(data.BuyItems) end
        if data.AttachTarget then UI.PlayerDropdown.SetSelected(data.AttachTarget) end
        if data.PlayersTarget then UI.PlayersDropdown.SetSelected(data.PlayersTarget) end
        if data.NPCTarget then UI.NPCDropdown.SetSelected(data.NPCTarget) end
        if data.AttachKeybind then
            local ok2,kc2=pcall(function() return Enum.KeyCode[data.AttachKeybind] end)
            if ok2 and kc2 then QoLFuncs.SetAttachKeybind(kc2) UI.AttachKbBtn.Text=data.AttachKeybind end
        end
        if data.SpectatorKeybind then
            local ok2,kc2=pcall(function() return Enum.KeyCode[data.SpectatorKeybind] end)
            if ok2 and kc2 then SpectatorFuncs.SetSpectatorKeybind(kc2) UI.SpectatorKbBtn.Text=data.SpectatorKeybind end
        end

        local starters = {
            Corpse=FarmFuncs.StartCorpse, Bank=FarmFuncs.StartBank, Chest=FarmFuncs.StartChest,
            SaintScanner=ScannerFuncs.StartScanner, ESP=ESPFuncs.StartESP, ClickTp=MovementFuncs.StartClickTp,
            Fly=MovementFuncs.StartFly, RaknetDesync=ExploitFuncs.StartRaknet, HideName=ExploitFuncs.StartHide,
            AutoBuy=QoLFuncs.startAutoBuy, AttachPlayer=QoLFuncs.startAttach,
            NoClip=NoClipFuncs.StartNoClip, Invisible=NoClipFuncs.StartInvisible
        }

        for featName, enabled in pairs(data) do
            local isEnabled = (enabled == true) or (enabled == "true") or (enabled == 1)
            if isEnabled and Features[featName] then
                if featName == "Corpse" then AnimToggle(UI.CorpseT, UI.CorpseC, UI.CorpseS, true) end
                if featName == "Bank" then AnimToggle(UI.BankT, UI.BankC, UI.BankS, true) end
                if featName == "Chest" then AnimToggle(UI.ChestT, UI.ChestC, UI.ChestS, true) end
                if featName == "SaintScanner" then AnimToggle(UI.ScanT, UI.ScanC, UI.ScanS, true) end
                if featName == "ESP" then AnimToggle(UI.EspT, UI.EspCir, UI.EspS, true) end
                if featName == "ClickTp" then AnimToggle(UI.ClickTpT, UI.ClickTpC, UI.ClickTpS, true) end
                if featName == "Fly" then AnimToggle(UI.FlyT, UI.FlyC, UI.FlyS, true) end
                if featName == "RaknetDesync" then AnimToggle(UI.RakT, UI.RakC, UI.RakS, true) end
                if featName == "HideName" then AnimToggle(UI.HideT, UI.HideC, UI.HideS, true) end
                if featName == "AutoBuy" then AnimToggle(UI.AutoBuyT, UI.AutoBuyC, UI.AutoBuyS, true) end
                if featName == "AttachPlayer" then AnimToggle(UI.AttachT, UI.AttachC, UI.AttachS, true) end
                if featName == "NoClip" then AnimToggle(UI.NoClipT, UI.NoClipC, UI.NoClipS, true) end
                if featName == "Invisible" then AnimToggle(UI.InvisT, UI.InvisC, UI.InvisS, true) end

                if not Features[featName].E then
                    Features[featName].E = true
                    local starterFunc = starters[featName]
                    if starterFunc then task.spawn(starterFunc) end
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
-- GLOBAL STARTERS / STOPPERS
-- ==========================================
_G.NezurStarters = {
    Corpse = FarmFuncs.StartCorpse,
    Bank = FarmFuncs.StartBank,
    Chest = FarmFuncs.StartChest,
    SaintScanner = ScannerFuncs.StartScanner,
    ESP = ESPFuncs.StartESP,
    ClickTp = MovementFuncs.StartClickTp,
    Fly = MovementFuncs.StartFly,
    RaknetDesync = ExploitFuncs.StartRaknet,
    HideName = ExploitFuncs.StartHide,
    AutoBuy = QoLFuncs.startAutoBuy,
    AttachPlayer = QoLFuncs.startAttach,
    NoClip = NoClipFuncs.StartNoClip,
    Invisible = NoClipFuncs.StartInvisible
}
_G.NezurStoppers = {
    Corpse = FarmFuncs.StopCorpse,
    Bank = FarmFuncs.StopBank,
    Chest = FarmFuncs.StopChest,
    SaintScanner = ScannerFuncs.StopScanner,
    ESP = ESPFuncs.StopESP,
    ClickTp = MovementFuncs.StopClickTp,
    Fly = MovementFuncs.StopFly,
    RaknetDesync = ExploitFuncs.StopRaknet,
    HideName = ExploitFuncs.StopHide,
    AutoBuy = QoLFuncs.stopAutoBuy,
    AttachPlayer = QoLFuncs.stopAttach,
    NoClip = NoClipFuncs.StopNoClip,
    Invisible = NoClipFuncs.StopInvisible
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

ST(UI.CorpseT, UI.CorpseC, UI.CorpseS, "Corpse", FarmFuncs.StartCorpse, FarmFuncs.StopCorpse)
ST(UI.BankT, UI.BankC, UI.BankS, "Bank", FarmFuncs.StartBank, FarmFuncs.StopBank)
ST(UI.ChestT, UI.ChestC, UI.ChestS, "Chest", FarmFuncs.StartChest, FarmFuncs.StopChest)
ST(UI.ScanT, UI.ScanC, UI.ScanS, "SaintScanner", ScannerFuncs.StartScanner, ScannerFuncs.StopScanner)
ST(UI.EspT, UI.EspCir, UI.EspS, "ESP", ESPFuncs.StartESP, ESPFuncs.StopESP)
ST(UI.ClickTpT, UI.ClickTpC, UI.ClickTpS, "ClickTp", MovementFuncs.StartClickTp, MovementFuncs.StopClickTp)
ST(UI.FlyT, UI.FlyC, UI.FlyS, "Fly", MovementFuncs.StartFly, MovementFuncs.StopFly)
ST(UI.RakT, UI.RakC, UI.RakS, "RaknetDesync", ExploitFuncs.StartRaknet, ExploitFuncs.StopRaknet)
ST(UI.HideT, UI.HideC, UI.HideS, "HideName", ExploitFuncs.StartHide, ExploitFuncs.StopHide)
ST(UI.AutoBuyT, UI.AutoBuyC, UI.AutoBuyS, "AutoBuy", QoLFuncs.startAutoBuy, QoLFuncs.stopAutoBuy)
ST(UI.AttachT, UI.AttachC, UI.AttachS, "AttachPlayer", QoLFuncs.startAttach, QoLFuncs.stopAttach)
ST(UI.NoClipT, UI.NoClipC, UI.NoClipS, "NoClip", NoClipFuncs.StartNoClip, NoClipFuncs.StopNoClip)
ST(UI.InvisT, UI.InvisC, UI.InvisS, "Invisible", NoClipFuncs.StartInvisible, NoClipFuncs.StopInvisible)
ST(UI.SpectatorT, UI.SpectatorC, UI.SpectatorS, "Spectator", SpectatorFuncs.StartSpectator, SpectatorFuncs.StopSpectator)

-- ==========================================
-- KEYBINDS
-- ==========================================
UI.KbBtn.MouseButton1Click:Connect(function()
    if IsListening then return end
    IsListening = true
    UI.KbBtn.Text = "Press key"
    UI.KbBtn.TextColor3 = Color3.new(1, 1, 1)
    local conn
    conn = UserInputService.InputBegan:Connect(function(i, g)
        if g then return end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            GuiKeybind = i.KeyCode
            UI.KbBtn.Text = tostring(i.KeyCode):gsub("Enum.KeyCode.", "")
            UI.KbBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
            IsListening = false
            if conn then conn:Disconnect() end
        end
    end)
    task.delay(5, function()
        if IsListening then
            IsListening = false
            UI.KbBtn.Text = tostring(GuiKeybind):gsub("Enum.KeyCode.", "")
            UI.KbBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
            if conn then conn:Disconnect() end
        end
    end)
end)

UI.FlyKbBtn.MouseButton1Click:Connect(function()
    if IsFlyListening then return end
    IsFlyListening = true
    UI.FlyKbBtn.Text = "Press key"
    UI.FlyKbBtn.TextColor3 = Color3.new(1, 1, 1)
    local conn
    conn = UserInputService.InputBegan:Connect(function(i, g)
        if g then return end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            FlyKeybind = i.KeyCode
            UI.FlyKbBtn.Text = tostring(i.KeyCode):gsub("Enum.KeyCode.", "")
            UI.FlyKbBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
            IsFlyListening = false
            if conn then conn:Disconnect() end
        end
    end)
    task.delay(5, function()
        if IsFlyListening then
            IsFlyListening = false
            UI.FlyKbBtn.Text = tostring(FlyKeybind):gsub("Enum.KeyCode.", "")
            UI.FlyKbBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
            if conn then conn:Disconnect() end
        end
    end)
end)

UI.SpectatorKbBtn.MouseButton1Click:Connect(function()
    if IsSpectatorListening then return end
    IsSpectatorListening = true
    UI.SpectatorKbBtn.Text = "Press key"
    UI.SpectatorKbBtn.TextColor3 = Color3.new(1, 1, 1)
    local conn
    conn = UserInputService.InputBegan:Connect(function(i, g)
        if g then return end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            SpectatorKeybind = i.KeyCode
            UI.SpectatorKbBtn.Text = tostring(i.KeyCode):gsub("Enum.KeyCode.", "")
            UI.SpectatorKbBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
            IsSpectatorListening = false
            if conn then conn:Disconnect() end
        end
    end)
    task.delay(5, function()
        if IsSpectatorListening then
            IsSpectatorListening = false
            UI.SpectatorKbBtn.Text = tostring(SpectatorKeybind):gsub("Enum.KeyCode.", "")
            UI.SpectatorKbBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
            if conn then conn:Disconnect() end
        end
    end)
end)

UserInputService.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == FlyKeybind then
        Features.Fly.E = not Features.Fly.E
        AnimToggle(UI.FlyT, UI.FlyC, UI.FlyS, Features.Fly.E)
        if Features.Fly.E then MovementFuncs.StartFly() else MovementFuncs.StopFly() end
    end
end)

UserInputService.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == SpectatorKeybind then
        Features.Spectator.E = not Features.Spectator.E
        AnimToggle(UI.SpectatorT, UI.SpectatorC, UI.SpectatorS, Features.Spectator.E)
        if Features.Spectator.E then SpectatorFuncs.StartSpectator() else SpectatorFuncs.StopSpectator() end
    end
end)

UserInputService.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == QoLFuncs.AttachKeybind() then
        Features.AttachPlayer.E = not Features.AttachPlayer.E
        AnimToggle(UI.AttachT, UI.AttachC, UI.AttachS, Features.AttachPlayer.E)
        if Features.AttachPlayer.E then QoLFuncs.startAttach() else QoLFuncs.stopAttach() end
    end
end)

UserInputService.InputBegan:Connect(function(i, g)
    if g then return end
    if i.KeyCode == GuiKeybind then
        IsGuiHidden = not IsGuiHidden
        UI.MainFrame.Visible = not IsGuiHidden
        -- NotifGui.Enabled = not IsGuiHidden
        if not IsGuiHidden then
            local ts = UDim2.new(0, 400, 0, 520)
            local at = UI.ActiveTab()
            if at == "ESP" then ts = UDim2.new(0, 400, 0, 360)
            elseif at == "Movement" then ts = UDim2.new(0, 400, 0, 520)
            elseif at == "QoL" then ts = UDim2.new(0, 400, 0, 420)
            elseif at == "Misc" then ts = UDim2.new(0, 400, 0, 420)
            elseif at == "Server" then ts = UDim2.new(0, 400, 0, 460)
            elseif at == "Settings" then ts = UDim2.new(0, 400, 0, 560) end
            UI.MainFrame.Size = ts
        end
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
    local color = Color3.fromRGB(255,200,100)
    if lower:find("potassium") or lower:find("volt") or lower:find("synapse") or lower:find("fluxus") then
        status = "🟢 Supported"
        color = Color3.fromRGB(100,255,100)
    elseif lower:find("xeno") or lower:find("arceus") then
        status = "🔴 Not supported"
        color = Color3.fromRGB(255,100,100)
    end
    return name, status, color
end

-- ==========================================
-- BUTTONS
-- ==========================================
UI.SaveCfgBtn.MouseButton1Click:Connect(ConfigFuncs.SaveCurrentConfig)
UI.LoadCfgBtn.MouseButton1Click:Connect(ConfigFuncs.LoadCurrentConfig)
UI.DelCfgBtn.MouseButton1Click:Connect(ConfigFuncs.DeleteCurrentConfig)
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
if ok and src and #src > 100 then loadstring(src)() else warn("[Nezur] AutoExec failed") end
]]
    local loader = string.format(loaderTemplate, SCRIPT_URL)
    if type(queue_on_teleport) == "function" then pcall(queue_on_teleport, loader)
    elseif type(queueonteleport) == "function" then pcall(queueonteleport, loader) end
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end)
UI.SetupAutoLoadBtn.MouseButton1Click:Connect(ConfigFuncs.SetupAutoLoad)
UI.DeleteAutoLoadBtn.MouseButton1Click:Connect(ConfigFuncs.DeleteAutoLoad)

UI.BuyItemBtn.MouseButton1Click:Connect(function()
    local items = UI.ItemDropdown.GetSelected()
    if #items == 0 then Notify("No items selected", 2) return end
    QoLFuncs.buyItems(items, true)
end)

UI.AttachKbBtn.MouseButton1Click:Connect(function()
    if QoLFuncs.IsAttachListening() then return end
    QoLFuncs.SetIsAttachListening(true)
    UI.AttachKbBtn.Text = "Press key"
    UI.AttachKbBtn.TextColor3 = Color3.new(1, 1, 1)
    local conn
    conn = UserInputService.InputBegan:Connect(function(i, g)
        if g then return end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            QoLFuncs.SetAttachKeybind(i.KeyCode)
            UI.AttachKbBtn.Text = tostring(i.KeyCode):gsub("Enum.KeyCode.", "")
            UI.AttachKbBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
            QoLFuncs.SetIsAttachListening(false)
            if conn then conn:Disconnect() end
        end
    end)
    task.delay(5, function()
        if QoLFuncs.IsAttachListening() then
            QoLFuncs.SetIsAttachListening(false)
            UI.AttachKbBtn.Text = tostring(QoLFuncs.AttachKeybind()):gsub("Enum.KeyCode.", "")
            UI.AttachKbBtn.TextColor3 = Color3.fromRGB(184, 168, 216)
            if conn then conn:Disconnect() end
        end
    end)
end)

-- Players & NPCs Buttons
local currentSpectateSubject = nil
UI.SpectatePlayerBtn.MouseButton1Click:Connect(function()
    local name = UI.PlayersDropdown.GetSelected()
    if not name or name == "None" then Notify("No player selected", 2) return end
    local entities = Workspace:FindFirstChild("Entities")
    if not entities then Notify("Entities not found", 2) return end
    local target = entities:FindFirstChild(name)
    if not target then Notify("Player not found", 2) return end
    local hum = target:FindFirstChildOfClass("Humanoid") or target:FindFirstChild("Humanoid")
    if not hum then Notify("No humanoid found", 2) return end
    local cam = workspace.CurrentCamera
    if cam.CameraSubject == hum then
        local myChar = player.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        cam.CameraSubject = myHum or hum
        currentSpectateSubject = nil
        Notify("Stopped spectating", 2)
    else
        cam.CameraSubject = hum
        currentSpectateSubject = hum
        Notify("Spectating " .. name, 2)
    end
end)

UI.TeleportPlayerBtn.MouseButton1Click:Connect(function()
    local name = UI.PlayersDropdown.GetSelected()
    if not name or name == "None" then Notify("No player selected", 2) return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local entities = Workspace:FindFirstChild("Entities")
    if not entities then Notify("Entities not found", 2) return end
    local target = entities:FindFirstChild(name)
    if not target then Notify("Player not found", 2) return end
    local targetHrp = target:FindFirstChild("HumanoidRootPart")
    if targetHrp then
        hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 5)
        Notify("Teleported to " .. name, 2)
    else
        Notify("No root part found", 2)
    end
end)

UI.TeleportNPCBtn.MouseButton1Click:Connect(function()
    local name = UI.NPCDropdown.GetSelected()
    if not name or name == "None" then Notify("No NPC selected", 2) return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local npcFolder = Workspace:FindFirstChild("NPC")
    if not npcFolder then Notify("NPC folder not found", 2) return end
    local target = npcFolder:FindFirstChild(name)
    if not target then Notify("NPC not found", 2) return end
    local targetPart = target:FindFirstChild("HumanoidRootPart")
    if not targetPart then targetPart = target.PrimaryPart end
    if not targetPart then
        for _, child in ipairs(target:GetChildren()) do
            if child:IsA("BasePart") then targetPart = child break end
        end
    end
    if targetPart then
        local head = target:FindFirstChild("Head")
        local targetPos = head and head.Position or targetPart.Position
        local abovePos = targetPos + Vector3.new(0, (head and head.Size.Y or 2) + 1, 0)
        hrp.CFrame = CFrame.new(abovePos)
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        Notify("Teleported to " .. name, 2)
    else
        Notify("No part found on NPC", 2)
    end
end)

-- ==========================================
-- AUTO-RESTORE
-- ==========================================
task.delay(3, function()
    local autoLoadPath = ConfigFolder .. "/autoload.txt"
    if isfile(autoLoadPath) then
        local ok, name = pcall(function() return readfile(autoLoadPath) end)
        if ok and name and name ~= "" then
            name = name:gsub("%s+", "")
            if name ~= "" then
                UI.ConfigNameBox.Text = name
                CurrentConfigName = name
                local data = (function()
                    local path = ConfigFolder.."/"..name..".json"
                    if isfile(path) then
                        local s,r = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
                        if s and type(r)=="table" then return r end
                    end
                    return nil
                end)()
                if data then
                    if data.MinPlayers and UI.SetMin then UI.SetMin(data.MinPlayers) end
                    if data.MaxPlayers and UI.SetMax then UI.SetMax(data.MaxPlayers) end
                    if data.FlySlider and UI.SetFlySpeed then UI.SetFlySpeed(data.FlySlider) elseif data.FlySpeed then FlySpeed = data.FlySpeed end
                    if data.GuiKeybind then
                        local ok2,kc=pcall(function() return Enum.KeyCode[data.GuiKeybind] end)
                        if ok2 and kc then GuiKeybind=kc UI.KbBtn.Text=data.GuiKeybind end
                    end
                    if data.FlyKeybind then
                        local ok2,kc=pcall(function() return Enum.KeyCode[data.FlyKeybind] end)
                        if ok2 and kc then FlyKeybind=kc UI.FlyKbBtn.Text=data.FlyKeybind end
                    end
                    if data.BuyItems and #data.BuyItems > 0 then UI.ItemDropdown.SetSelected(data.BuyItems) end
                    if data.AttachTarget then UI.PlayerDropdown.SetSelected(data.AttachTarget) end
                    if data.PlayersTarget then UI.PlayersDropdown.SetSelected(data.PlayersTarget) end
                    if data.NPCTarget then UI.NPCDropdown.SetSelected(data.NPCTarget) end
                    if data.AttachKeybind then
                        local ok2,kc2=pcall(function() return Enum.KeyCode[data.AttachKeybind] end)
                        if ok2 and kc2 then QoLFuncs.SetAttachKeybind(kc2) UI.AttachKbBtn.Text=data.AttachKeybind end
                    end
                    if data.SpectatorKeybind then
                        local ok2,kc2=pcall(function() return Enum.KeyCode[data.SpectatorKeybind] end)
                        if ok2 and kc2 then SpectatorFuncs.SetSpectatorKeybind(kc2) UI.SpectatorKbBtn.Text=data.SpectatorKeybind end
                    end

                    local starters = {
                        Corpse=FarmFuncs.StartCorpse, Bank=FarmFuncs.StartBank, Chest=FarmFuncs.StartChest,
                        SaintScanner=ScannerFuncs.StartScanner, ESP=ESPFuncs.StartESP, ClickTp=MovementFuncs.StartClickTp,
                        Fly=MovementFuncs.StartFly, RaknetDesync=ExploitFuncs.StartRaknet, HideName=ExploitFuncs.StartHide,
                        AutoBuy=QoLFuncs.startAutoBuy, AttachPlayer=QoLFuncs.startAttach,
                        NoClip=NoClipFuncs.StartNoClip, Invisible=NoClipFuncs.StartInvisible,
                        Spectator=SpectatorFuncs.StartSpectator
                    }

                    for featName, enabled in pairs(data) do
                        local isEnabled = (enabled == true) or (enabled == "true") or (enabled == 1)
                        if isEnabled and Features[featName] then
                            if featName == "Corpse" then AnimToggle(UI.CorpseT, UI.CorpseC, UI.CorpseS, true) end
                            if featName == "Bank" then AnimToggle(UI.BankT, UI.BankC, UI.BankS, true) end
                            if featName == "Chest" then AnimToggle(UI.ChestT, UI.ChestC, UI.ChestS, true) end
                            if featName == "SaintScanner" then AnimToggle(UI.ScanT, UI.ScanC, UI.ScanS, true) end
                            if featName == "ESP" then AnimToggle(UI.EspT, UI.EspCir, UI.EspS, true) end
                            if featName == "ClickTp" then AnimToggle(UI.ClickTpT, UI.ClickTpC, UI.ClickTpS, true) end
                            if featName == "Fly" then AnimToggle(UI.FlyT, UI.FlyC, UI.FlyS, true) end
                            if featName == "RaknetDesync" then AnimToggle(UI.RakT, UI.RakC, UI.RakS, true) end
                            if featName == "HideName" then AnimToggle(UI.HideT, UI.HideC, UI.HideS, true) end
                            if featName == "AutoBuy" then AnimToggle(UI.AutoBuyT, UI.AutoBuyC, UI.AutoBuyS, true) end
                            if featName == "AttachPlayer" then AnimToggle(UI.AttachT, UI.AttachC, UI.AttachS, true) end
                            if featName == "NoClip" then AnimToggle(UI.NoClipT, UI.NoClipC, UI.NoClipS, true) end
                            if featName == "Invisible" then AnimToggle(UI.InvisT, UI.InvisC, UI.InvisS, true) end
                            if not Features[featName].E then
                                Features[featName].E = true
                                local starterFunc = starters[featName]
                                if starterFunc then task.spawn(starterFunc) end
                            end
                        end
                    end
                    Notify("✅ AutoLoad successful", 3)
                else
                    Notify("❌ AutoLoad failed: config '" .. name .. "' not found", 3)
                end
            else
                Notify("📭 AutoLoad is empty", 3)
            end
        else
            Notify("📭 AutoLoad is empty", 3)
        end
    else
        Notify("📭 AutoLoad is empty", 3)
    end
end)

-- ==========================================
-- PLAYERS & NPCs UPDATERS
-- ==========================================
task.spawn(function()
    while true do
        local npcs = getNPCList()
        UI.NPCDropdown.Rebuild(npcs)
        task.wait(5)
    end
end)

task.spawn(function()
    while true do
        local pName = UI.PlayersDropdown.GetSelected()
        if pName and pName ~= "None" then
            local entities = Workspace:FindFirstChild("Entities")
            local ent = entities and entities:FindFirstChild(pName)
            if ent then
                local hum = ent:FindFirstChildOfClass("Humanoid")
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

        task.wait(0.5)
    end
end)

-- ==========================================
-- INIT
-- ==========================================
ConfigFuncs.RefreshConfigListUI()

pcall(function()
    task.spawn(function()
        task.wait(0.5)
        local name, status, color = DetectExecutor()
        UI.ExecNameLbl.Text = "Executor: " .. name
        UI.ExecStatusLbl.Text = "Status: " .. status
        UI.ExecStatusLbl.TextColor3 = color
    end)
end)

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
end)

Notify("✅ Nezur loaded successfully", 4)
