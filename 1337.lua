repeat task.wait() until game:IsLoaded()

if type(clearteleportqueue) == "function" then pcall(clearteleportqueue)
elseif type(clearteleport_queue) == "function" then pcall(clearteleport_queue) end

if getgenv().RarityHubLoaded then return end
getgenv().RarityHubLoaded = true

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

local oldGui = playerGui:FindFirstChild("rarity.bw")
if oldGui then oldGui:Destroy() end

local SCRIPT_URL = "https://raw.githubusercontent.com/kresteq/bridgerAnticheatSUCKS/refs/heads/main/1337.lua"
local ConfigFolder = "rarity.bw"
if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end

local CurrentConfigName = "default"
local SHC = {MinPlayers=1, MaxPlayers=25}
local GuiKeybind = Enum.KeyCode.F1
local FlyKeybind = Enum.KeyCode.E
local SpectatorKeybind = Enum.KeyCode.RightControl
local FlySpeed = 24
local IsListening = false
local IsTreeListening = false
local TreeKeybind = Enum.KeyCode.F2
local IsFlyListening = false
local IsGuiHidden = false
local ServerHopRunning = false

local Features = {
    Corpse={E=false,C=nil}, Bank={E=false,C=nil}, Chest={E=false,C=nil}, Tree={E=false,C=nil},
    Fish={E=false,C=nil}, Chams={E=false,C=nil,PlayerAdded=nil}, SaintESP={E=false,C=nil}, PosTracker={E=false,C=nil},
    SaintScanner={E=false,C=nil}, ESP={E=false,C=nil,PlayerAdded=nil,PlayerRemoving=nil},
    ClickTp={E=false,C=nil}, Fly={E=false,C=nil,KC=nil},
    RaknetDesync={E=false,C=nil}, HideName={E=false,C=nil},
    AutoBuy={E=false,C=nil}, AttachPlayer={E=false,C=nil},
    NoClip={E=false,C=nil}, Invisible={E=false,C=nil},
    Spectator={E=false,C=nil}, FullBright={E=false,C=nil}
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
    if not pb or not pb:IsA("GuiButton") then return false end

    -- Method 3: VIM + SelectedObject (works on Potassium)
    local ok3 = pcall(function()
        GuiService.SelectedObject = pb
        task.wait(0.2)
        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(0.1)
        GuiService.SelectedObject = nil
    end)
    if ok3 then return true end

    -- Method 7: AutoSelectGuiEnabled + Enter (works on Volt)
    local ok7 = pcall(function()
        local oldAuto = GuiService.AutoSelectGuiEnabled
        GuiService.AutoSelectGuiEnabled = true
        GuiService.SelectedObject = pb
        task.wait(0.3)
        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(0.1)
        GuiService.SelectedObject = nil
        GuiService.AutoSelectGuiEnabled = oldAuto
    end)
    if ok7 then return true end

    return false
end

while true do
    if Workspace.Entities:FindFirstChild(player.Name) then break end
    PressPlayButton()
    task.wait(1.5)
end
task.spawn(AutoEquipRandom)

-- ==========================================
-- NOTIFICATIONS (IIFE)
-- ==========================================
local Notify = (function()
    local NotifGui = Instance.new("ScreenGui")
    NotifGui.Name = "RarityNotifications"
    NotifGui.ResetOnSpawn = false
    NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotifGui.DisplayOrder = 100
    NotifGui.Parent = playerGui

    -- Notification background image
    local NotifBg = Instance.new("ImageLabel")
    NotifBg.Name = "NotifBg"
    NotifBg.Size = UDim2.new(1, 0, 1, 0)
    NotifBg.BackgroundTransparency = 1
    NotifBg.Image = "https://i.pinimg.com/736x/08/18/77/0818775090ee00b2d5d0e67c735249cc.jpg"
    NotifBg.ScaleType = Enum.ScaleType.Crop
    NotifBg.ImageTransparency = 0.85
    NotifBg.ZIndex = 0
    NotifBg.Parent = NotifGui
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
        f.BackgroundColor3 = Color3.fromRGB(45, 20, 70)
        f.BorderSizePixel = 0
        f.BackgroundTransparency = 1
        f.Parent = NotifContainer
        local c = Instance.new("UICorner", f)
        c.CornerRadius = UDim.new(0,6)
        local s = Instance.new("UIStroke", f)
        s.Color = Color3.fromRGB(100, 60, 140)
        s.Thickness = 1
        s.Transparency = 1
        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1,-12,1,0)
        l.Position = UDim2.new(0,12,0,0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.fromRGB(255, 255, 255)
        l.TextSize = 12
        l.Font = Enum.Font.GothamMedium
        local lStroke = Instance.new("UIStroke", l)
        lStroke.Color = Color3.fromRGB(255, 255, 255)
        lStroke.Thickness = 2
        lStroke.Transparency = 0.7
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
        if child.Name == "rarity.bw" then child:Destroy() end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "rarity.bw"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = playerGui
    ui.ScreenGui = ScreenGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0,520,0,600)
    MainFrame.Position = UDim2.new(0.5,-260,0.5,-300)
    MainFrame.BackgroundColor3 = Color3.fromRGB(45, 20, 70)
    MainFrame.BackgroundTransparency = 1
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = false
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    -- MainFrame: square corners
    local MStroke = Instance.new("UIStroke",MainFrame)
    MStroke.Color = Color3.fromRGB(74, 23, 103)
    MStroke.Thickness = 1

    -- Background image (Rarity MLP) — getcustomasset override
    local BgImage = Instance.new("ImageLabel")
    BgImage.Name = "BgImage"
    BgImage.Size = UDim2.new(1, 0, 1, 0)
    BgImage.Position = UDim2.new(0, 0, 0, 0)
    BgImage.BackgroundTransparency = 1
    BgImage.Image = "https://i.pinimg.com/736x/08/18/77/0818775090ee00b2d5d0e67c735249cc.jpg"
    BgImage.ScaleType = Enum.ScaleType.Crop
    BgImage.ImageTransparency = 0.05
    BgImage.ZIndex = 0
    BgImage.Parent = MainFrame

    -- Anchor to bottom so Rarity shows at bottom
    BgImage.AnchorPoint = Vector2.new(0, 1)
    BgImage.Position = UDim2.new(0, 0, 1, 0)

    -- Try getcustomasset for better compatibility (Potassium/Volt)
    pcall(function()
        if type(writefile) == "function" and type(getcustomasset) == "function" then
            local imgFile = "rarity_bg_" .. tostring(game.PlaceId) .. ".jpg"
            local data = game:HttpGet("https://i.pinimg.com/736x/08/18/77/0818775090ee00b2d5d0e67c735249cc.jpg")
            if data and #data > 100 then
                writefile(imgFile, data)
                local asset = getcustomasset(imgFile)
                if asset and type(asset) == "string" and #asset > 5 then
                    BgImage.Image = asset
                end
            end
        end
    end)

    ui.MainFrame = MainFrame

    local Dragging = false
    local DragStart = nil
    local StartPos = nil

    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1,0,0,35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(60, 30, 95)
    TitleBar.BackgroundTransparency = 0.25
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    -- TitleBar: square corners
    
    local TitleText = Instance.new("TextLabel",TitleBar)
    TitleText.Size = UDim2.new(1,-15,1,0)
    TitleText.Position = UDim2.new(0,15,0,0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "▼ rarity.bw 💎"
    TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    TabsFrame.BackgroundColor3 = Color3.fromRGB(60, 30, 95)
    TabsFrame.BackgroundTransparency = 0.25
    TabsFrame.BorderSizePixel = 0
    TabsFrame.Parent = MainFrame
    
    local TabSep = Instance.new("Frame", TabsFrame)
    TabSep.Size = UDim2.new(1,0,0,2)
    TabSep.Position = UDim2.new(0,0,0,32)
    TabSep.BackgroundColor3 = Color3.fromRGB(180, 160, 220)
    TabSep.BorderSizePixel = 0

    local TabNames = {"Auto Farms","ESP","Movement","QoL","Players & NPCs","Misc","Server","Settings"}
    local TabButtons = {}
    local TabContents = {}
    local ActiveTab = "Auto Farms"
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
        btn.TextColor3 = name=="Auto Farms" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 255, 255)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamMedium
        btn.Parent = TabsFrame
        local line = Instance.new("Frame",btn)
        line.Size = UDim2.new(0.8,0,0,2)
        line.Position = UDim2.new(0.1,0,1,-2)
        line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        line.BorderSizePixel = 0
        line.Visible = name=="Auto Farms"
        TabButtons[name] = {Button=btn,Line=line}

        local content = Instance.new("ScrollingFrame")
        content.Size = UDim2.new(1,-30,1,-117)
        content.Position = UDim2.new(0,15,0,107)
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
                t.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                t.Line.Visible = false
                TabContents[n].Visible = false
            end
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            line.Visible = true
            content.Visible = true
            ActiveTab = name
            local ts = UDim2.new(0,520,0,600)
            if name=="ESP" then ts = UDim2.new(0,520,0,440)
            elseif name=="Movement" then ts = UDim2.new(0,520,0,600)
            elseif name=="QoL" then ts = UDim2.new(0,520,0,520)
            elseif name=="Players & NPCs" then ts = UDim2.new(0,520,0,520)
            elseif name=="Misc" then ts = UDim2.new(0,520,0,560)
            elseif name=="Server" then ts = UDim2.new(0,520,0,540)
            elseif name=="Settings" then ts = UDim2.new(0,520,0,520) end
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
        t.TextColor3 = Color3.fromRGB(255, 255, 255)
        t.TextSize = 12
        t.Font = Enum.Font.GothamBold
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextYAlignment = Enum.TextYAlignment.Center
        local tStroke = Instance.new("UIStroke", t)
        tStroke.Color = Color3.fromRGB(255, 255, 255)
        tStroke.Thickness = 2
        tStroke.Transparency = 0.7
        local ln = Instance.new("Frame",sec)
        ln.Size = UDim2.new(1,-90,0,2)
        ln.Position = UDim2.new(0,85,0.6,0)
        ln.BackgroundColor3 = Color3.fromRGB(180, 160, 220)
        ln.BackgroundTransparency = 0.4
        ln.BorderSizePixel = 0
        return posY+28
    end

    local function CreateToggle(parent,text,posY,featName)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,0,0,32)
        row.Position = UDim2.new(0,0,0,posY)
        row.BackgroundColor3 = Color3.fromRGB(45, 20, 70)
        row.BackgroundTransparency = 1
        row.Parent = parent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
        local lbl = Instance.new("TextLabel",row)
        lbl.Size = UDim2.new(0.7,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        local lblStroke = Instance.new("UIStroke", lbl)
        lblStroke.Color = Color3.fromRGB(255, 255, 255)
        lblStroke.Thickness = 2
        lblStroke.Transparency = 0.7
        local tbg = Instance.new("TextButton",row)
        tbg.Size = UDim2.new(0,36,0,20)
        tbg.Position = UDim2.new(1,-36,0.5,-10)
        tbg.BackgroundColor3 = Color3.fromRGB(90, 55, 130)
        tbg.Text = ""
        tbg.AutoButtonColor = false
        Instance.new("UICorner",tbg).CornerRadius = UDim.new(1,0)
        local circ = Instance.new("Frame",tbg)
        circ.Size = UDim2.new(0,16,0,16)
        circ.Position = UDim2.new(0,2,0,2)
        circ.BackgroundColor3 = Color3.fromRGB(100, 70, 130)
        circ.BorderSizePixel = 0
        Instance.new("UICorner",circ).CornerRadius = UDim.new(1,0)
        local sd = Instance.new("TextLabel",row)
        sd.Size = UDim2.new(0,10,0,10)
        sd.Position = UDim2.new(0.7,-15,0.5,-5)
        sd.BackgroundTransparency = 1
        sd.Text = "●"
        sd.TextColor3 = Color3.fromRGB(255, 255, 255)
        sd.TextSize = 8
        sd.Visible = false
        row.MouseEnter:Connect(function() lbl.TextColor3 = Color3.fromRGB(255, 255, 255) end)
        row.MouseLeave:Connect(function() lbl.TextColor3 = Color3.fromRGB(255, 255, 255) end)
        return tbg, circ, sd, posY+36, row
    end

    local function CreateButton(parent,text,posY,bName)
        local btn = Instance.new("TextButton")
        btn.Name = bName
        btn.Size = UDim2.new(1,0,0,32)
        btn.Position = UDim2.new(0,0,0,posY)
        btn.BackgroundColor3 = Color3.fromRGB(90, 55, 130)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamMedium
        btn.AutoButtonColor = false
        btn.Parent = parent
        Instance.new("UICorner",btn).CornerRadius = UDim.new(0,6)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(125, 209, 245)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(90, 55, 130)}):Play()
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
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        local vl = Instance.new("TextLabel",lr)
        vl.Size = UDim2.new(0.3,0,1,0)
        vl.Position = UDim2.new(0.7,0,0,0)
        vl.BackgroundTransparency = 1
        vl.Text = tostring(val)
        vl.TextColor3 = Color3.fromRGB(255, 255, 255)
        vl.TextSize = 13
        vl.Font = Enum.Font.GothamSemibold
        vl.TextXAlignment = Enum.TextXAlignment.Right
        local trk = Instance.new("TextButton",row)
        trk.Size = UDim2.new(1,0,0,8)
        trk.Position = UDim2.new(0,0,0,26)
        trk.BackgroundColor3 = Color3.fromRGB(90, 55, 130)
        trk.Text = ""
        trk.AutoButtonColor = false
        Instance.new("UICorner",trk).CornerRadius = UDim.new(1,0)
        local fl = Instance.new("Frame",trk)
        fl.Size = UDim2.new((val-min)/(max-min),0,1,0)
        fl.BackgroundColor3 = Color3.fromRGB(125, 209, 245)
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
        row.BackgroundColor3 = Color3.fromRGB(45, 20, 70)
        row.BackgroundTransparency = 1
        row.Parent = parent
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
        local lbl = Instance.new("TextLabel",row)
        lbl.Size = UDim2.new(0.4,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextYAlignment = Enum.TextYAlignment.Center
        local lblStroke = Instance.new("UIStroke", lbl)
        lblStroke.Color = Color3.fromRGB(255, 255, 255)
        lblStroke.Thickness = 2
        lblStroke.Transparency = 0.7
        local box = Instance.new("TextBox",row)
        box.Size = UDim2.new(0.6,-5,1,-4)
        box.Position = UDim2.new(0.4,5,0,2)
        box.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
        box.TextColor3 = Color3.fromRGB(255, 255, 255)
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
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.TextSize = 12
        Label.Font = Enum.Font.Gotham
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextYAlignment = Enum.TextYAlignment.Center
        local LabelStroke = Instance.new("UIStroke", Label)
        LabelStroke.Color = Color3.fromRGB(255, 255, 255)
        LabelStroke.Thickness = 2
        LabelStroke.Transparency = 0.7
        Label.ZIndex = 51
        Label.Parent = Container

        local DropBtn = Instance.new("TextButton")
        DropBtn.Name = "DropBtn"
        DropBtn.Size = UDim2.new(0.55, 0, 1, 0)
        DropBtn.Position = UDim2.new(0.45, 0, 0, 0)
        DropBtn.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
        DropBtn.Text = "Select..."
        DropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        DropBtn.TextSize = 11
        DropBtn.Font = Enum.Font.GothamMedium
        DropBtn.AutoButtonColor = false
        DropBtn.ZIndex = 51
        DropBtn.Parent = Container

        Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 6)

        -- Overlay frame parented to ScreenGui
        local ListFrame = Instance.new("ScrollingFrame")
        ListFrame.Name = featureName.."List"
        ListFrame.Size = UDim2.new(0, 200, 0, 0)
        ListFrame.Position = UDim2.new(0, 0, 0, 0)
        ListFrame.BackgroundColor3 = Color3.fromRGB(60, 30, 95)
        ListFrame.BorderSizePixel = 0
        ListFrame.Visible = false
        ListFrame.ZIndex = 9999
        ListFrame.ScrollBarThickness = 3
        ListFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 60, 140)
        ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        ListFrame.Parent = ScreenGui

        Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 6)

        local ListStroke = Instance.new("UIStroke")
        ListStroke.Color = Color3.fromRGB(75, 45, 110)
        ListStroke.Thickness = 2
        ListStroke.Parent = ListFrame

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 2)
        ListLayout.Parent = ListFrame

        local selected = {}
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
                if absSize.X > 0 then
                    FIXED_LIST_WIDTH = absSize.X
                end
                ListFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
                local count = #optionsTable
                local h = math.min(count * ROW_HEIGHT + 4, MAX_LIST_HEIGHT)
                ListFrame.Size = UDim2.new(0, FIXED_LIST_WIDTH, 0, h)
            end)
        end

        for _, opt in ipairs(optionsTable) do
            local optBtn = Instance.new("TextButton")
            optBtn.Size = UDim2.new(1, -8, 0, 24)
            optBtn.Position = UDim2.new(0, 4, 0, 0)
            optBtn.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
            optBtn.Text = "  " .. opt
            optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        local optBtnStroke = Instance.new("UIStroke", optBtn)
        optBtnStroke.Color = Color3.fromRGB(255, 255, 255)
        optBtnStroke.Thickness = 2
        optBtnStroke.Transparency = 0.7
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
                    optBtn.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
                    optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        local optBtnStroke = Instance.new("UIStroke", optBtn)
        optBtnStroke.Color = Color3.fromRGB(255, 255, 255)
        optBtnStroke.Thickness = 2
        optBtnStroke.Transparency = 0.7
                else
                    selected[opt] = true
                    optBtn.BackgroundColor3 = Color3.fromRGB(125, 209, 245)
                    optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        local optBtnStroke = Instance.new("UIStroke", optBtn)
        optBtnStroke.Color = Color3.fromRGB(255, 255, 255)
        optBtnStroke.Thickness = 2
        optBtnStroke.Transparency = 0.7
                end
                local names = {}
                for name, _ in pairs(selected) do table.insert(names, name) end
                if #names == 0 then DropBtn.Text = "Select..."
                elseif #names == 1 then DropBtn.Text = names[1]
                else DropBtn.Text = #names .. " selected" end
            end)

            optionButtons[opt] = optBtn
        end

        local count = #optionsTable
        local h = math.min(count * ROW_HEIGHT + 4, MAX_LIST_HEIGHT)
        ListFrame.Size = UDim2.new(0, FIXED_LIST_WIDTH, 0, h)
        ListFrame.CanvasSize = UDim2.new(0, 0, 0, count * ROW_HEIGHT + 8)

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

        -- Auto-hide when parent tab becomes invisible
        local tabHideConn = nil
        tabHideConn = RunService.Heartbeat:Connect(function()
            if open and Container and Container.Parent then
                if not Container.Parent.Visible then
                    open = false
                    ListFrame.Visible = false
                end
            end
        end)

        Container.Destroying:Connect(function()
            if clickAwayConn then clickAwayConn:Disconnect() end
            if tabHideConn then tabHideConn:Disconnect() end
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
                        optionButtons[name].BackgroundColor3 = Color3.fromRGB(125, 209, 245)
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
        Label.TextColor3 = Color3.fromRGB(255, 255, 255)
        Label.TextSize = 12
        Label.Font = Enum.Font.Gotham
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextYAlignment = Enum.TextYAlignment.Center
        local LabelStroke = Instance.new("UIStroke", Label)
        LabelStroke.Color = Color3.fromRGB(255, 255, 255)
        LabelStroke.Thickness = 2
        LabelStroke.Transparency = 0.7
        Label.ZIndex = 51
        Label.Parent = Container

        local DropBtn = Instance.new("TextButton")
        DropBtn.Name = "DropBtn"
        DropBtn.Size = UDim2.new(0.55, 0, 1, 0)
        DropBtn.Position = UDim2.new(0.45, 0, 0, 0)
        DropBtn.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
        DropBtn.Text = "None"
        DropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        DropBtn.TextSize = 11
        DropBtn.Font = Enum.Font.GothamMedium
        DropBtn.AutoButtonColor = false
        DropBtn.ZIndex = 51
        DropBtn.Parent = Container

        Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 6)

        -- Overlay frame parented to ScreenGui for proper rendering above all
        local ListFrame = Instance.new("ScrollingFrame")
        ListFrame.Name = featureName.."List"
        ListFrame.Size = UDim2.new(0, 200, 0, 0)
        ListFrame.Position = UDim2.new(0, 0, 0, 0)
        ListFrame.BackgroundColor3 = Color3.fromRGB(60, 30, 95)
        ListFrame.BorderSizePixel = 0
        ListFrame.Visible = false
        ListFrame.ZIndex = listZIndex
        ListFrame.ScrollBarThickness = 3
        ListFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 60, 140)
        ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        ListFrame.Parent = ScreenGui

        Instance.new("UICorner", ListFrame).CornerRadius = UDim.new(0, 6)

        local ListStroke = Instance.new("UIStroke")
        ListStroke.Color = Color3.fromRGB(75, 45, 110)
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
            -- Wait one frame for AbsolutePosition to be valid
            task.defer(function()
                if not DropBtn or not DropBtn.Parent then return end
                local absPos = DropBtn.AbsolutePosition
                local absSize = DropBtn.AbsoluteSize
                if absSize.X > 0 then
                    FIXED_LIST_WIDTH = absSize.X
                end
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
                optBtn.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
                optBtn.Text = "  " .. opt
                optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        local optBtnStroke = Instance.new("UIStroke", optBtn)
        optBtnStroke.Color = Color3.fromRGB(255, 255, 255)
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

        -- Auto-hide when parent tab becomes invisible
        local tabHideConn = nil
        tabHideConn = RunService.Heartbeat:Connect(function()
            if open and Container and Container.Parent then
                if not Container.Parent.Visible then
                    open = false
                    ListFrame.Visible = false
                end
            end
        end)

        -- Cleanup on destroy
        Container.Destroying:Connect(function()
            if clickAwayConn then clickAwayConn:Disconnect() end
            if tabHideConn then tabHideConn:Disconnect() end
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
    ui.TreeT, ui.TreeC, ui.TreeS, fy, ui.TreeRow = CreateToggle(FarmC,"Auto Tree",fy,"Tree")
    ui.TreeKbBtn = Instance.new("TextButton", ui.TreeRow)
    ui.TreeKbBtn.Size = UDim2.new(0, 50, 0, 20)
    ui.TreeKbBtn.Position = UDim2.new(0.55, 0, 0.5, -10)
    ui.TreeKbBtn.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
    ui.TreeKbBtn.Text = "F2"
    ui.TreeKbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.TreeKbBtn.TextSize = 11
    ui.TreeKbBtn.Font = Enum.Font.GothamMedium
    ui.TreeKbBtn.AutoButtonColor = false
    ui.TreeKbBtn.ZIndex = 52
    Instance.new("UICorner", ui.TreeKbBtn).CornerRadius = UDim.new(0, 6)
    local treeLbl = ui.TreeRow:FindFirstChild("Label")
    if treeLbl then treeLbl.Size = UDim2.new(0.45, 0, 1, 0) end
    fy = fy + 4
    local treeTypeRow = Instance.new("Frame", FarmC)
    treeTypeRow.Size = UDim2.new(1, 0, 0, 28)
    treeTypeRow.Position = UDim2.new(0, 0, 0, fy)
    treeTypeRow.BackgroundTransparency = 1
    local treeTypeLbl = Instance.new("TextLabel", treeTypeRow)
    treeTypeLbl.Size = UDim2.new(0.45, 0, 1, 0)
    treeTypeLbl.BackgroundTransparency = 1
    treeTypeLbl.Text = "Tree Type"
    treeTypeLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        local treeTypeLblStroke = Instance.new("UIStroke", treeTypeLbl)
        treeTypeLblStroke.Color = Color3.fromRGB(255, 255, 255)
        treeTypeLblStroke.Thickness = 2
        treeTypeLblStroke.Transparency = 0.7
    treeTypeLbl.TextSize = 12
    treeTypeLbl.Font = Enum.Font.Gotham
    treeTypeLbl.TextXAlignment = Enum.TextXAlignment.Left
    treeTypeLbl.TextYAlignment = Enum.TextYAlignment.Center
    ui.TreeTypeBtn = Instance.new("TextButton", treeTypeRow)
    ui.TreeTypeBtn.Size = UDim2.new(0, 120, 0, 24)
    ui.TreeTypeBtn.Position = UDim2.new(0.55, 0, 0.5, -12)
    ui.TreeTypeBtn.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
    ui.TreeTypeBtn.Text = "ForestTrees"
    ui.TreeTypeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.TreeTypeBtn.TextSize = 11
    ui.TreeTypeBtn.Font = Enum.Font.GothamMedium
    ui.TreeTypeBtn.AutoButtonColor = false
    ui.TreeTypeBtn.ZIndex = 52
    Instance.new("UICorner", ui.TreeTypeBtn).CornerRadius = UDim.new(0, 6)
    local treeTypes = {"ForestTrees", "SwampTrees"}
    local currentTreeIdx = 1
    ui.TreeTypeBtn.MouseButton1Click:Connect(function()
        currentTreeIdx = currentTreeIdx % #treeTypes + 1
        local newType = treeTypes[currentTreeIdx]
        ui.TreeTypeBtn.Text = newType
        _G.RarityTreeSelection = newType
    end)
    fy = fy + 32
    fy = CreateSection(FarmC,"Auto Farms",fy)
    ui.CorpseT, ui.CorpseC, ui.CorpseS, fy = CreateToggle(FarmC,"Auto Corpse",fy,"Corpse")
    ui.BankT, ui.BankC, ui.BankS, fy = CreateToggle(FarmC,"Auto Bank",fy,"Bank")
    ui.ChestT, ui.ChestC, ui.ChestS, fy = CreateToggle(FarmC,"Auto Chest",fy,"Chest")
    fy = CreateSection(FarmC,"Scanner",fy+5)
    ui.ScanT, ui.ScanC, ui.ScanS, fy = CreateToggle(FarmC,"Saint Scanner",fy,"SaintScanner")
    ui.TeleportBtn, fy = CreateButton(FarmC,"Teleport to Saint",fy,"TeleportBtn")
    ui.TeleportBtn.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
    ui.TeleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.TeleportBtn.Visible = false

    fy = CreateSection(FarmC,"Auto Fish",fy+5)
    ui.FishT, ui.FishC, ui.FishS, fy = CreateToggle(FarmC,"Auto Fish",fy,"Fish")

    -- ESP Tab
    local EspC = TabContents["ESP"]
    local ey = 0
    ey = CreateSection(EspC,"Player ESP",ey)
    ui.EspT, ui.EspCir, ui.EspS, ey = CreateToggle(EspC,"Player ESP",ey,"ESP")

    -- Movement Tab
    ey = ey + 8
    ey = CreateSection(EspC,"Chams",ey)
    ui.ChamsT, ui.ChamsC, ui.ChamsS, ey = CreateToggle(EspC,"Player Chams",ey,"Chams")
    local chamsRow = Instance.new("Frame", EspC)
    chamsRow.Size = UDim2.new(1, 0, 0, 28)
    chamsRow.Position = UDim2.new(0, 0, 0, ey)
    chamsRow.BackgroundTransparency = 1
    local chamsLbl = Instance.new("TextLabel", chamsRow)
    chamsLbl.Size = UDim2.new(0.3, 0, 1, 0)
    chamsLbl.BackgroundTransparency = 1
    chamsLbl.Text = "Color"
    chamsLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    chamsLbl.TextSize = 12
    chamsLbl.Font = Enum.Font.Gotham
    chamsLbl.TextXAlignment = Enum.TextXAlignment.Left
    chamsLbl.TextYAlignment = Enum.TextYAlignment.Center
    ui.ChamsRBox = Instance.new("TextBox", chamsRow)
    ui.ChamsRBox.Size = UDim2.new(0.2, -4, 1, -4)
    ui.ChamsRBox.Position = UDim2.new(0.3, 2, 0, 2)
    ui.ChamsRBox.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
    ui.ChamsRBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.ChamsRBox.PlaceholderText = "R"
    ui.ChamsRBox.Text = "255"
    ui.ChamsRBox.TextSize = 11
    ui.ChamsRBox.Font = Enum.Font.Gotham
    Instance.new("UICorner", ui.ChamsRBox).CornerRadius = UDim.new(0, 4)
    ui.ChamsGBox = Instance.new("TextBox", chamsRow)
    ui.ChamsGBox.Size = UDim2.new(0.2, -4, 1, -4)
    ui.ChamsGBox.Position = UDim2.new(0.5, 2, 0, 2)
    ui.ChamsGBox.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
    ui.ChamsGBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.ChamsGBox.PlaceholderText = "G"
    ui.ChamsGBox.Text = "0"
    ui.ChamsGBox.TextSize = 11
    ui.ChamsGBox.Font = Enum.Font.Gotham
    Instance.new("UICorner", ui.ChamsGBox).CornerRadius = UDim.new(0, 4)
    ui.ChamsBBox = Instance.new("TextBox", chamsRow)
    ui.ChamsBBox.Size = UDim2.new(0.2, -4, 1, -4)
    ui.ChamsBBox.Position = UDim2.new(0.7, 2, 0, 2)
    ui.ChamsBBox.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
    ui.ChamsBBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.ChamsBBox.PlaceholderText = "B"
    ui.ChamsBBox.Text = "0"
    ui.ChamsBBox.TextSize = 11
    ui.ChamsBBox.Font = Enum.Font.Gotham
    Instance.new("UICorner", ui.ChamsBBox).CornerRadius = UDim.new(0, 4)
    ey = ey + 32
    ey = CreateSection(EspC,"Saint ESP",ey)
    ui.SaintEspT, ui.SaintEspC, ui.SaintEspS, ey = CreateToggle(EspC,"Saint ESP",ey,"SaintESP")

    local MovC = TabContents["Movement"]
    local mvy = 0
    mvy = CreateSection(MovC,"Movement",mvy)
    ui.ClickTpT, ui.ClickTpC, ui.ClickTpS, mvy = CreateToggle(MovC,"Click Teleport",mvy,"ClickTp")
    local FlyWarn = Instance.new("TextLabel",MovC)
    FlyWarn.Size = UDim2.new(1,0,0,40)
    FlyWarn.Position = UDim2.new(0,0,0,mvy)
    FlyWarn.BackgroundTransparency = 1
    FlyWarn.Text = "⚠️CAUTION⚠️After 10s of flying, AntiCheat drops HP to 0⚠️DONT TURN OFF FLY AT LOW HP⚠️"
    FlyWarn.TextColor3 = Color3.fromRGB(255, 120, 120)
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
    FlyKbLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        local KbLblStroke = Instance.new("UIStroke", KbLbl)
        KbLblStroke.Color = Color3.fromRGB(255, 255, 255)
        KbLblStroke.Thickness = 2
        KbLblStroke.Transparency = 0.7
        local FlyKbLblStroke = Instance.new("UIStroke", FlyKbLbl)
        FlyKbLblStroke.Color = Color3.fromRGB(255, 255, 255)
        FlyKbLblStroke.Thickness = 2
        FlyKbLblStroke.Transparency = 0.7
    FlyKbLbl.TextSize = 12
    FlyKbLbl.Font = Enum.Font.Gotham
    FlyKbLbl.TextXAlignment = Enum.TextXAlignment.Left
    ui.FlyKbBtn = Instance.new("TextButton",MovC)
    ui.FlyKbBtn.Size = UDim2.new(0,80,0,24)
    ui.FlyKbBtn.Position = UDim2.new(1,-80,0,mvy)
    ui.FlyKbBtn.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
    ui.FlyKbBtn.Text = "E"
    ui.FlyKbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    AttachKbLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        local KbLblStroke = Instance.new("UIStroke", KbLbl)
        KbLblStroke.Color = Color3.fromRGB(255, 255, 255)
        KbLblStroke.Thickness = 2
        KbLblStroke.Transparency = 0.7
        local AttachKbLblStroke = Instance.new("UIStroke", AttachKbLbl)
        AttachKbLblStroke.Color = Color3.fromRGB(255, 255, 255)
        AttachKbLblStroke.Thickness = 2
        AttachKbLblStroke.Transparency = 0.7
    AttachKbLbl.TextSize = 12
    AttachKbLbl.Font = Enum.Font.Gotham
    AttachKbLbl.TextXAlignment = Enum.TextXAlignment.Left
    ui.AttachKbBtn = Instance.new("TextButton", QoLC)
    ui.AttachKbBtn.Size = UDim2.new(0, 80, 0, 24)
    ui.AttachKbBtn.Position = UDim2.new(1, -80, 0, qolY)
    ui.AttachKbBtn.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
    ui.AttachKbBtn.Text = "G"
    ui.AttachKbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.AttachKbBtn.TextSize = 11
    ui.AttachKbBtn.Font = Enum.Font.GothamMedium
    ui.AttachKbBtn.AutoButtonColor = false
    Instance.new("UICorner", ui.AttachKbBtn).CornerRadius = UDim.new(0, 6)

    qolY = qolY + 30
    qolY = CreateSection(QoLC, "Performance", qolY + 8)

    local fogRow = Instance.new("Frame")
    fogRow.Size = UDim2.new(1, 0, 0, 32)
    fogRow.Position = UDim2.new(0, 0, 0, qolY)
    fogRow.BackgroundTransparency = 1
    fogRow.Parent = QoLC
    local fogLbl = Instance.new("TextLabel", fogRow)
    fogLbl.Size = UDim2.new(0.7, 0, 1, 0)
    fogLbl.BackgroundTransparency = 1
    fogLbl.Text = "Remove Fog"
    fogLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        local fogLblStroke = Instance.new("UIStroke", fogLbl)
        fogLblStroke.Color = Color3.fromRGB(255, 255, 255)
        fogLblStroke.Thickness = 2
        fogLblStroke.Transparency = 0.7
    fogLbl.TextSize = 13
    fogLbl.Font = Enum.Font.Gotham
    fogLbl.TextXAlignment = Enum.TextXAlignment.Left
    fogLbl.TextYAlignment = Enum.TextYAlignment.Center
    local fogBtn = Instance.new("TextButton", fogRow)
    fogBtn.Size = UDim2.new(0.3, -5, 1, -4)
    fogBtn.Position = UDim2.new(0.7, 5, 0, 2)
    fogBtn.BackgroundColor3 = Color3.fromRGB(90, 55, 130)
    fogBtn.Text = "Apply"
    fogBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    fogBtn.TextSize = 13
    fogBtn.Font = Enum.Font.GothamMedium
    fogBtn.AutoButtonColor = false
    Instance.new("UICorner", fogBtn).CornerRadius = UDim.new(0, 6)
    fogBtn.MouseEnter:Connect(function()
        TweenService:Create(fogBtn,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(125, 209, 245)}):Play()
    end)
    fogBtn.MouseLeave:Connect(function()
        TweenService:Create(fogBtn,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(90, 55, 130)}):Play()
    end)
    ui.FogBtn = fogBtn
    qolY = qolY + 36

    ui.FullBrightT, ui.FullBrightC, ui.FullBrightS, qolY = CreateToggle(QoLC, "Full Brightness", qolY, "FullBright")

    -- Players & NPCs Tab
    -- Position Tracker
    qolY = qolY + 8
    qolY = CreateSection(QoLC, "Position Tracker", qolY)
    ui.PosTrackerT, ui.PosTrackerC, ui.PosTrackerS, qolY = CreateToggle(QoLC, "Position Tracker", qolY, "PosTracker")
    ui.PosTrackerLbl = Instance.new("TextLabel", QoLC)
    ui.PosTrackerLbl.Size = UDim2.new(1, 0, 0, 20)
    ui.PosTrackerLbl.Position = UDim2.new(0, 0, 0, qolY)
    ui.PosTrackerLbl.BackgroundTransparency = 1
    ui.PosTrackerLbl.Text = "X: --  Y: --  Z: --"
    ui.PosTrackerLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.PosTrackerLbl.TextSize = 12
    ui.PosTrackerLbl.Font = Enum.Font.Gotham
    ui.PosTrackerLbl.TextXAlignment = Enum.TextXAlignment.Left
    qolY = qolY + 24

    -- Copy button
    ui.CopyPosBtn = Instance.new("TextButton", QoLC)
    ui.CopyPosBtn.Size = UDim2.new(1, 0, 0, 32)
    ui.CopyPosBtn.Position = UDim2.new(0, 0, 0, qolY)
    ui.CopyPosBtn.BackgroundColor3 = Color3.fromRGB(90, 55, 130)
    ui.CopyPosBtn.Text = "📋 Copy to Clipboard"
    ui.CopyPosBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.CopyPosBtn.TextSize = 12
    ui.CopyPosBtn.Font = Enum.Font.GothamMedium
    ui.CopyPosBtn.AutoButtonColor = false
    Instance.new("UICorner", ui.CopyPosBtn).CornerRadius = UDim.new(0, 6)

    ui.CopyPosBtn.MouseEnter:Connect(function()
        TweenService:Create(ui.CopyPosBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(125, 209, 245)}):Play()
    end)
    ui.CopyPosBtn.MouseLeave:Connect(function()
        TweenService:Create(ui.CopyPosBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 55, 130)}):Play()
    end)
    ui.CopyPosBtn.MouseButton1Click:Connect(function()
        QoLExtras.CopyCoords()
    end)

    qolY = qolY + 40
    

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
    ui.SpectatePlayerBtn.BackgroundColor3 = Color3.fromRGB(90, 55, 130)
    ui.SpectatePlayerBtn.Text = "Spectate"
    ui.SpectatePlayerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.SpectatePlayerBtn.TextSize = 11
    ui.SpectatePlayerBtn.Font = Enum.Font.GothamMedium
    ui.SpectatePlayerBtn.AutoButtonColor = false
    ui.SpectatePlayerBtn.Parent = PnC
    Instance.new("UICorner", ui.SpectatePlayerBtn).CornerRadius = UDim.new(0, 6)
    ui.SpectatePlayerBtn.MouseEnter:Connect(function()
        TweenService:Create(ui.SpectatePlayerBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(125, 209, 245)}):Play()
    end)
    ui.SpectatePlayerBtn.MouseLeave:Connect(function()
        TweenService:Create(ui.SpectatePlayerBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 55, 130)}):Play()
    end)

    ui.TeleportPlayerBtn = Instance.new("TextButton")
    ui.TeleportPlayerBtn.Name = "TeleportPlayerBtn"
    ui.TeleportPlayerBtn.Size = UDim2.new(0.19, -2, 0, 28)
    ui.TeleportPlayerBtn.Position = UDim2.new(0.77, 4, 0, playerRowY)
    ui.TeleportPlayerBtn.BackgroundColor3 = Color3.fromRGB(90, 55, 130)
    ui.TeleportPlayerBtn.Text = "Teleport"
    ui.TeleportPlayerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.TeleportPlayerBtn.TextSize = 11
    ui.TeleportPlayerBtn.Font = Enum.Font.GothamMedium
    ui.TeleportPlayerBtn.AutoButtonColor = false
    ui.TeleportPlayerBtn.Parent = PnC
    Instance.new("UICorner", ui.TeleportPlayerBtn).CornerRadius = UDim.new(0, 6)
    ui.TeleportPlayerBtn.MouseEnter:Connect(function()
        TweenService:Create(ui.TeleportPlayerBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(125, 209, 245)}):Play()
    end)
    ui.TeleportPlayerBtn.MouseLeave:Connect(function()
        TweenService:Create(ui.TeleportPlayerBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 55, 130)}):Play()
    end)

    ui.PlayerHealthLbl = Instance.new("TextLabel")
    ui.PlayerHealthLbl.Size = UDim2.new(1, 0, 0, 20)
    ui.PlayerHealthLbl.Position = UDim2.new(0, 0, 0, pny)
    ui.PlayerHealthLbl.BackgroundTransparency = 1
    ui.PlayerHealthLbl.Text = "Health: --"
    ui.PlayerHealthLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    ui.TeleportNPCBtn.BackgroundColor3 = Color3.fromRGB(90, 55, 130)
    ui.TeleportNPCBtn.Text = "Teleport"
    ui.TeleportNPCBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.TeleportNPCBtn.TextSize = 11
    ui.TeleportNPCBtn.Font = Enum.Font.GothamMedium
    ui.TeleportNPCBtn.AutoButtonColor = false
    ui.TeleportNPCBtn.Parent = PnC
    Instance.new("UICorner", ui.TeleportNPCBtn).CornerRadius = UDim.new(0, 6)
    ui.TeleportNPCBtn.MouseEnter:Connect(function()
        TweenService:Create(ui.TeleportNPCBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(125, 209, 245)}):Play()
    end)
    ui.TeleportNPCBtn.MouseLeave:Connect(function()
        TweenService:Create(ui.TeleportNPCBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 55, 130)}):Play()
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
    miy = miy + 4
    ui.FpsBox, miy = CreateTextBox(MiscC,"FPS Cap",miy,"60")
    ui.FpsBox.Text = "60"
    ui.FpsBox:GetPropertyChangedSignal("Text"):Connect(function()
        ui.FpsBox.Text = ui.FpsBox.Text:gsub("%D", "")
    end)
    ui.FpsApplyBtn, miy = CreateButton(MiscC,"Apply FPS Cap",miy,"FpsApplyBtn")
    miy = CreateSection(MiscC,"TEST",miy+5)
    ui.SpectatorT, ui.SpectatorC, ui.SpectatorS, miy = CreateToggle(MiscC,"Spectator Mode",miy,"Spectator")
    ui.SpectatorKbBtn = Instance.new("TextButton",MiscC)
    ui.SpectatorKbBtn.Size = UDim2.new(0,80,0,24)
    ui.SpectatorKbBtn.Position = UDim2.new(1,-80,0,miy)
    ui.SpectatorKbBtn.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
    ui.SpectatorKbBtn.Text = "RightCtrl"
    ui.SpectatorKbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.SpectatorKbBtn.TextSize = 11
    ui.SpectatorKbBtn.Font = Enum.Font.GothamMedium
    ui.SpectatorKbBtn.AutoButtonColor = false
    Instance.new("UICorner",ui.SpectatorKbBtn).CornerRadius = UDim.new(0,6)
    miy = miy + 30
    miy = miy + 8
    miy = CreateSection(MiscC, "Moola Spoof", miy)

    -- Moola Spoof TextBox
    ui.MoolaSpoofBox = Instance.new("TextBox", MiscC)
    ui.MoolaSpoofBox.Size = UDim2.new(1, 0, 0, 28)
    ui.MoolaSpoofBox.Position = UDim2.new(0, 0, 0, miy)
    ui.MoolaSpoofBox.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
    ui.MoolaSpoofBox.Text = "discord.gg/nexonix"
    ui.MoolaSpoofBox.PlaceholderText = "Enter text..."
    ui.MoolaSpoofBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.MoolaSpoofBox.PlaceholderColor3 = Color3.fromRGB(100, 60, 140)
    ui.MoolaSpoofBox.TextSize = 12
    ui.MoolaSpoofBox.Font = Enum.Font.GothamMedium
    ui.MoolaSpoofBox.ClearTextOnFocus = false
    Instance.new("UICorner", ui.MoolaSpoofBox).CornerRadius = UDim.new(0, 6)
    miy = miy + 32

    -- Moola Spoof Buttons Row
    local MoolaBtnRow = Instance.new("Frame", MiscC)
    MoolaBtnRow.Size = UDim2.new(1, 0, 0, 32)
    MoolaBtnRow.Position = UDim2.new(0, 0, 0, miy)
    MoolaBtnRow.BackgroundTransparency = 1

    ui.MoolaApplyBtn = Instance.new("TextButton", MoolaBtnRow)
    ui.MoolaApplyBtn.Size = UDim2.new(0.48, -4, 1, 0)
    ui.MoolaApplyBtn.Position = UDim2.new(0, 0, 0, 0)
    ui.MoolaApplyBtn.BackgroundColor3 = Color3.fromRGB(90, 55, 130)
    ui.MoolaApplyBtn.Text = "Apply"
    ui.MoolaApplyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.MoolaApplyBtn.TextSize = 12
    ui.MoolaApplyBtn.Font = Enum.Font.GothamMedium
    ui.MoolaApplyBtn.AutoButtonColor = false
    Instance.new("UICorner", ui.MoolaApplyBtn).CornerRadius = UDim.new(0, 6)
    ui.MoolaApplyBtn.MouseEnter:Connect(function()
        TweenService:Create(ui.MoolaApplyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(125, 209, 245)}):Play()
    end)
    ui.MoolaApplyBtn.MouseLeave:Connect(function()
        TweenService:Create(ui.MoolaApplyBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(90, 55, 130)}):Play()
    end)

    ui.MoolaCancelBtn = Instance.new("TextButton", MoolaBtnRow)
    ui.MoolaCancelBtn.Size = UDim2.new(0.48, -4, 1, 0)
    ui.MoolaCancelBtn.Position = UDim2.new(0.52, 0, 0, 0)
    ui.MoolaCancelBtn.BackgroundColor3 = Color3.fromRGB(125, 209, 245)
    ui.MoolaCancelBtn.Text = "Cancel"
    ui.MoolaCancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ui.MoolaCancelBtn.TextSize = 12
    ui.MoolaCancelBtn.Font = Enum.Font.GothamMedium
    ui.MoolaCancelBtn.AutoButtonColor = false
    Instance.new("UICorner", ui.MoolaCancelBtn).CornerRadius = UDim.new(0, 6)
    ui.MoolaCancelBtn.MouseEnter:Connect(function()
        TweenService:Create(ui.MoolaCancelBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 60, 140)}):Play()
    end)
    ui.MoolaCancelBtn.MouseLeave:Connect(function()
        TweenService:Create(ui.MoolaCancelBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(125, 209, 245)}):Play()
    end)

    miy = miy + 36

    miy = miy + 8
    local KbLbl = Instance.new("TextLabel",MiscC)
    KbLbl.Size = UDim2.new(0.6,0,0,24)
    KbLbl.Position = UDim2.new(0,0,0,miy)
    KbLbl.BackgroundTransparency = 1
    KbLbl.Text = "GUI Keybind"
    KbLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        local KbLblStroke = Instance.new("UIStroke", KbLbl)
        KbLblStroke.Color = Color3.fromRGB(255, 255, 255)
        KbLblStroke.Thickness = 2
        KbLblStroke.Transparency = 0.7
    KbLbl.TextSize = 12
    KbLbl.Font = Enum.Font.Gotham
    KbLbl.TextXAlignment = Enum.TextXAlignment.Left
    ui.KbBtn = Instance.new("TextButton",MiscC)
    ui.KbBtn.Size = UDim2.new(0,80,0,24)
    ui.KbBtn.Position = UDim2.new(1,-80,0,miy)
    ui.KbBtn.BackgroundColor3 = Color3.fromRGB(75, 45, 110)
    ui.KbBtn.Text = "F1"
    ui.KbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    ui.ExecNameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    sy = CreateSection(SetC,"Config Management",sy+5)
    ui.ConfigNameBox, sy = CreateTextBox(SetC,"Config Name",sy,"Enter name...")
    sy = sy + 8
    ui.ConfigDropdown, sy = CreateDropdown(SetC, sy, "Config", "ConfigSelect", 9997)
    -- Auto-fill config name when dropdown selection changes
    task.spawn(function()
        local lastSelection = nil
        while ui.ConfigDropdown and ui.ConfigDropdown.GetSelected do
            local current = ui.ConfigDropdown.GetSelected()
            if current and current ~= "None" and current ~= lastSelection then
                lastSelection = current
                ui.ConfigNameBox.Text = current
                CurrentConfigName = current
            end
            task.wait(0.5)
        end
    end)
    sy = sy + 8
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
    TweenService:Create(btn,TweenInfo.new(0.3),{BackgroundColor3=en and Color3.fromRGB(125, 209, 245) or Color3.fromRGB(90, 55, 130)}):Play()
    TweenService:Create(circ,TweenInfo.new(0.3),{Position=en and UDim2.new(0,18,0,2) or UDim2.new(0,2,0,2),BackgroundColor3=en and Color3.new(1,1,1) or Color3.fromRGB(100, 70, 130)}):Play()
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

local function SafeTeleport(target, instant)
    instant = instant or false
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end
    if hum.Health <= 0 then return false end
    if char:FindFirstChildOfClass("ForceField") then
        task.wait(0.6)
        if char:FindFirstChildOfClass("ForceField") then return false end
    end
    local spawnTime = char:GetAttribute("RaritySpawn")
    if not spawnTime then
        spawnTime = tick()
        char:SetAttribute("RaritySpawn", spawnTime)
    end
    local age = tick() - spawnTime
    if age < 3.5 then
        task.wait(3.5 - age + 0.1)
    end
    hrp.Velocity = Vector3.new(0, 0, 0)
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    task.wait(0.05)
    if typeof(target) == "CFrame" then
        hrp.CFrame = target
    elseif typeof(target) == "Vector3" then
        hrp.CFrame = CFrame.new(target)
    end
    if not instant then
        task.wait(0.1)
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
    return true
end

player.CharacterAdded:Connect(function(char)
    char:SetAttribute("RaritySpawn", tick())
end)

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
            -- Rejoin same server instead of ServerHop
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
        end
        local function holdPrompt(p, targetPart)
            if not p then return end
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            for _ = 1, 3 do
                -- Face the prompt
                if targetPart and targetPart.Parent then
                    local promptPos = targetPart.Position
                    local lookCFrame = CFrame.lookAt(hrp.Position, Vector3.new(promptPos.X, hrp.Position.Y, promptPos.Z))
                    hrp.CFrame = lookCFrame
                end

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
            holdPrompt(nb:FindFirstChildOfClass("ProximityPrompt") or nb.Parent:FindFirstChildOfClass("ProximityPrompt"), nb)
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
                holdPrompt(ns:FindFirstChildOfClass("ProximityPrompt") or ns.Parent:FindFirstChildOfClass("ProximityPrompt"), ns)
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
                    -- Same method as LumberAxe purchase (Choice_1 click)
                    pcall(function() firesignal(b.MouseButton1Click) end)
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
-- CHAMS & SAINT ESP (IIFE)
-- ==========================================
local ChamFuncs = (function()
    local cf = {}
    local Highlights = {}
    local ChamConn = nil
    local SaintEspConn = nil
    local SaintHighlights = {}

    local function getChamsColor()
        local r = tonumber(UI.ChamsRBox.Text) or 255
        local g = tonumber(UI.ChamsGBox.Text) or 0
        local b = tonumber(UI.ChamsBBox.Text) or 0
        return Color3.fromRGB(math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255))
    end

    local function createHighlight(model)
        if not model or Highlights[model] then return end
        local hl = Instance.new("Highlight")
        hl.Name = "RarityChams"
        hl.FillColor = getChamsColor()
        hl.OutlineColor = Color3.new(1, 1, 1)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.Adornee = model
        hl.Parent = model
        Highlights[model] = hl
    end

    local function removeHighlight(model)
        local hl = Highlights[model]
        if hl then hl:Destroy() Highlights[model] = nil end
    end

    function cf.StartChams()
        Notify("👁️ Player Chams active")
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                createHighlight(p.Character)
            end
        end
        ChamConn = RunService.Heartbeat:Connect(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    if not Highlights[p.Character] then
                        createHighlight(p.Character)
                    else
                        Highlights[p.Character].FillColor = getChamsColor()
                    end
                end
            end
            for model, hl in pairs(Highlights) do
                if not model.Parent then
                    hl:Destroy()
                    Highlights[model] = nil
                end
            end
        end)
        Features.Chams.PlayerAdded = Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(function(char)
                if Features.Chams.E then
                    createHighlight(char)
                end
            end)
        end)
    end

    function cf.StopChams()
        Notify("⚫ Player Chams disabled")
        if ChamConn then ChamConn:Disconnect() ChamConn = nil end
        if Features.Chams.PlayerAdded then Features.Chams.PlayerAdded:Disconnect() Features.Chams.PlayerAdded = nil end
        for _, hl in pairs(Highlights) do hl:Destroy() end
        Highlights = {}
    end

    function cf.StartSaintESP()
        Notify("🔮 Saint ESP active")
        SaintEspConn = RunService.Heartbeat:Connect(function()
            for _, hl in pairs(SaintHighlights) do
                if hl and hl.Parent then hl:Destroy() end
            end
            SaintHighlights = {}

            if not Features.SaintESP.E then return end

            for _, obj in ipairs(Workspace:GetChildren()) do
                if table.find(saintsPartNames, obj.Name) and obj:IsA("BasePart") then
                    local isReal = false
                    for _, coord in ipairs(SAINT_COORDS) do
                        if (obj.Position - coord).Magnitude <= 60 then
                            isReal = true
                            break
                        end
                    end
                    if isReal then
                        local hl = Instance.new("Highlight")
                        hl.Name = "RaritySaintESP"
                        hl.FillColor = Color3.fromRGB(125, 209, 245)
                        hl.OutlineColor = Color3.fromRGB(100, 60, 140)
                        hl.FillTransparency = 0.3
                        hl.OutlineTransparency = 0
                        hl.Adornee = obj
                        hl.Parent = obj
                        table.insert(SaintHighlights, hl)
                    end
                end
            end
            task.wait(2)
        end)
    end

    function cf.StopSaintESP()
        Notify("⚫ Saint ESP disabled")
        if SaintEspConn then SaintEspConn:Disconnect() SaintEspConn = nil end
        for _, hl in pairs(SaintHighlights) do
            if hl and hl.Parent then hl:Destroy() end
        end
        SaintHighlights = {}
    end

    return cf
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
        repPart.Name = "_RARITY_REPFOCUS_"
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
        landPlatform.Name = "_RARITY_LAND_"
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
-- VISUAL FUNCTIONS (IIFE)
-- ==========================================
local VisualFuncs = (function()
    local vis = {}
    local Lighting = game:GetService("Lighting")
    local orig = {}
    local fbConn = nil

    function vis.StartFullBright()
        Notify("☀️ Full Brightness active")
        orig.Brightness = Lighting.Brightness
        orig.ClockTime = Lighting.ClockTime
        orig.FogEnd = Lighting.FogEnd
        orig.FogStart = Lighting.FogStart
        orig.GlobalShadows = Lighting.GlobalShadows
        orig.OutdoorAmbient = Lighting.OutdoorAmbient
        orig.Ambient = Lighting.Ambient
        Lighting.Brightness = 10
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
        Lighting.Ambient = Color3.new(1,1,1)
        fbConn = Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
            if Features.FullBright.E then
                Lighting.Brightness = 10
            end
        end)
        Features.FullBright.C = fbConn
    end

    function vis.StopFullBright()
        Notify("⚫ Full Brightness disabled")
        if fbConn then fbConn:Disconnect() fbConn = nil end
        Features.FullBright.C = nil
        if orig.Brightness ~= nil then Lighting.Brightness = orig.Brightness end
        if orig.ClockTime ~= nil then Lighting.ClockTime = orig.ClockTime end
        if orig.FogEnd ~= nil then Lighting.FogEnd = orig.FogEnd end
        if orig.FogStart ~= nil then Lighting.FogStart = orig.FogStart end
        if orig.GlobalShadows ~= nil then Lighting.GlobalShadows = orig.GlobalShadows end
        if orig.OutdoorAmbient ~= nil then Lighting.OutdoorAmbient = orig.OutdoorAmbient end
        if orig.Ambient ~= nil then Lighting.Ambient = orig.Ambient end
        orig = {}
    end

    function vis.RemoveFog()
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.FogColor = Color3.new(1,1,1)
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then
            atm.Density = 0
            atm.Haze = 0
            atm.Glare = 0
        end
        Notify("🌫️ Fog removed", 2)
    end

    return vis
end)()

-- ==========================================
-- POSITION TRACKER & CUSTOM MOOLA (IIFE)
-- ==========================================
local QoLExtras = (function()
    local qe = {}
    local posConn = nil
    local moolaConn = nil
    local originalMoolaText = nil
    local currentPos = nil

    function qe.StartPosTracker()
        posConn = RunService.Heartbeat:Connect(function()
            local char = player.Character
            if not char then
                currentPos = nil
                if UI.PosTrackerLbl then
                    UI.PosTrackerLbl.Text = "X: --  Y: --  Z: --"
                end
                return
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then
                currentPos = nil
                if UI.PosTrackerLbl then
                    UI.PosTrackerLbl.Text = "X: --  Y: --  Z: --"
                end
                return
            end
            local pos = hrp.Position
            currentPos = pos
            if UI.PosTrackerLbl then
                UI.PosTrackerLbl.Text = string.format("X: %.2f  Y: %.2f  Z: %.2f", pos.X, pos.Y, pos.Z)
            end
        end)
    end

    function qe.StopPosTracker()
        if posConn then
            posConn:Disconnect()
            posConn = nil
        end
        currentPos = nil
        if UI.PosTrackerLbl then
            UI.PosTrackerLbl.Text = "X: --  Y: --  Z: --"
        end
    end

    function qe.CopyCoords()
        if not currentPos then
            Notify("❌ No character!", 2)
            return
        end
        -- Raw coordinates only, no wrapper
        local text = string.format("%.2f, %.2f, %.2f", currentPos.X, currentPos.Y, currentPos.Z)
        local copied = false

        -- Try setclipboard (Potassium/Volt)
        if type(setclipboard) == "function" then
            local s, e = pcall(setclipboard, text)
            if s then copied = true end
        end

        -- Fallback to toclipboard
        if not copied and type(toclipboard) == "function" then
            local s, e = pcall(toclipboard, text)
            if s then copied = true end
        end

        -- Fallback: use VIM to select all + copy (Ctrl+C)
        if not copied then
            pcall(function()
                -- Focus the label and select text via VIM
                VIM:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(true, Enum.KeyCode.C, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, Enum.KeyCode.C, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
            end)
        end

        if copied then
            Notify("✅ Coords copied", 2)
            if UI.PosTrackerLbl then
                UI.PosTrackerLbl.Text = "✅ Copied!"
                task.delay(1.5, function()
                    if currentPos and UI.PosTrackerLbl then
                        UI.PosTrackerLbl.Text = string.format("X: %.2f  Y: %.2f  Z: %.2f", currentPos.X, currentPos.Y, currentPos.Z)
                    end
                end)
            end
        else
            Notify("❌ Copy failed - check executor API", 3)
        end
    end

    -- ==========================================
    -- MOOLA SPOOFER V2 LOGIC
    -- ==========================================
    local moolaTargetElement = nil
    local moolaTargetType = nil
    local moolaHeartbeatConn = nil
    local moolaPropertyConn = nil
    local moolaChangedConn = nil
    local moolaActive = false
    local moolaCustomText = "discord.gg/nexonix"

    local function findMoolaElementV2()
        local moolaGui = playerGui:FindFirstChild("MoolaCount")
        if not moolaGui then
            return nil, nil, "MoolaCount not found"
        end

        local function findTextElements(container, depth, results)
            if depth > 5 then return end
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    table.insert(results, {element = child, type = child.ClassName})
                elseif child:IsA("TextBox") then
                    table.insert(results, {element = child, type = "TextBox"})
                end
                findTextElements(child, depth + 1, results)
            end
        end

        local found = {}
        findTextElements(moolaGui, 0, found)

        if #found == 0 then
            return nil, nil, "No text elements inside MoolaCount"
        end

        -- Priority: TextLabel > TextBox > TextButton
        for _, item in ipairs(found) do
            if item.type == "TextLabel" then
                return item.element, item.type, "Found TextLabel: " .. item.element.Name
            end
        end
        for _, item in ipairs(found) do
            if item.type == "TextBox" then
                return item.element, item.type, "Found TextBox: " .. item.element.Name
            end
        end
        return found[1].element, found[1].type, "Found " .. found[1].type .. ": " .. found[1].element.Name
    end

    local function applyMoolaSpoofV2()
        if not moolaTargetElement or not moolaActive then return end
        local text = moolaCustomText
        local success = false

        -- Method 1: Direct Text assignment
        pcall(function()
            if moolaTargetElement.Text ~= text then
                moolaTargetElement.Text = text
                success = true
            end
        end)

        -- Method 2: For TextBox -- also spoof PlaceholderText
        if moolaTargetType == "TextBox" then
            pcall(function()
                if moolaTargetElement.PlaceholderText ~= text then
                    moolaTargetElement.PlaceholderText = text
                end
            end)
        end

        -- Method 3: RichText ContentText is read-only, force overwrite Text
        pcall(function()
            if moolaTargetElement.RichText and moolaTargetElement.ContentText ~= text then
                moolaTargetElement.Text = text
            end
        end)

        return success
    end

    function qe.StartMoolaSpoof(text)
        if moolaActive then return end
        moolaCustomText = text
        if not moolaCustomText or moolaCustomText == "" then
            moolaCustomText = "discord.gg/nexonix"
        end

        local element, elType, msg = findMoolaElementV2()
        if not element then
            Notify("MoolaCount not found", 2)
            
            return
        end

        moolaTargetElement = element
        moolaTargetType = elType
        moolaActive = true

        -- Apply immediately
        applyMoolaSpoofV2()

        -- Method 1: PropertyChangedSignal (catches most changes)
        moolaPropertyConn = element:GetPropertyChangedSignal("Text"):Connect(function()
            if moolaActive and moolaTargetElement then
                task.defer(function()
                    if moolaActive then applyMoolaSpoofV2() end
                end)
            end
        end)

        -- Method 2: Changed event (backup)
        moolaChangedConn = element.Changed:Connect(function(prop)
            if prop == "Text" and moolaActive and moolaTargetElement then
                task.defer(function()
                    if moolaActive then applyMoolaSpoofV2() end
                end)
            end
        end)

        -- Method 3: Aggressive Heartbeat (frame-by-frame backup)
        moolaHeartbeatConn = RunService.Heartbeat:Connect(function()
            if moolaActive and moolaTargetElement and moolaTargetElement.Text ~= moolaCustomText then
                applyMoolaSpoofV2()
            end
        end)

        Notify("Moola spoof active", 2)
    end

    function qe.StopMoolaSpoof()
        moolaActive = false
        if moolaHeartbeatConn then moolaHeartbeatConn:Disconnect() moolaHeartbeatConn = nil end
        if moolaPropertyConn then moolaPropertyConn:Disconnect() moolaPropertyConn = nil end
        if moolaChangedConn then moolaChangedConn:Disconnect() moolaChangedConn = nil end
        moolaTargetElement = nil
        moolaTargetType = nil
        Notify("Moola spoof stopped", 2)
    end
    -- Legacy aliases for compatibility
    function qe.ApplyCustomMoola(text)
        qe.StartMoolaSpoof(text)
    end
    function qe.ResetMoola()
        qe.StopMoolaSpoof()
    end

    -- Global exports for button access
    _G.QoLExtras = qe
    _G.RarityMoolaStart = qe.StartMoolaSpoof
    _G.RarityMoolaStop = qe.StopMoolaSpoof

    -- Connect Moola buttons inside IIFE to ensure access
    task.delay(1, function()
        if UI.MoolaApplyBtn then
            UI.MoolaApplyBtn.MouseButton1Click:Connect(function()
                local text = UI.MoolaSpoofBox.Text
                if not text or text == "" then text = "discord.gg/nexonix" end
                qe.StartMoolaSpoof(text)
            end)
        end
        if UI.MoolaCancelBtn then
            UI.MoolaCancelBtn.MouseButton1Click:Connect(function()
                qe.StopMoolaSpoof()
            end)
        end
    end)

    return qe
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
                                            pcall(function() TeleportService:TeleportToPlaceInstance(PID, sid, player) end)
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
                if not file:find("%.json$") then continue end
                local name = file:gsub(".*[\\/]", ""):gsub("%.json$", "")
                if name and name ~= "" and name ~= "NotSameServers" and name ~= "autoexec" and name ~= "autoload" then
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
        c.TreeKeybind = tostring(TreeKeybind)
        c.TreeType = UI.TreeTypeBtn.Text
        c.NoClip = Features.NoClip.E
        c.Invisible = Features.Invisible.E
        c.Spectator = Features.Spectator.E
        c.FullBright = Features.FullBright.E
        c.Fish = Features.Fish.E
c.Chams = Features.Chams.E
c.ChamsR = tonumber(UI.ChamsRBox.Text) or 255
c.ChamsG = tonumber(UI.ChamsGBox.Text) or 0
c.ChamsB = tonumber(UI.ChamsBBox.Text) or 0
c.SaintESP = Features.SaintESP.E
c.PosTracker = Features.PosTracker.E
c.CustomMoola = UI.MoolaSpoofBox.Text or ""
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

        -- Inline config loading (same approach as AutoLoad)
        local data = (function()
            local path = ConfigFolder.."/"..name..".json"
            if isfile(path) then
                local s,r = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
                if s and type(r)=="table" then return r end
            end
            return nil
        end)()

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
        if data.TreeKeybind then
            local ok2,kc2=pcall(function() return Enum.KeyCode[data.TreeKeybind] end)
            if ok2 and kc2 then TreeKeybind=kc2 UI.TreeKbBtn.Text=data.TreeKeybind end
        end
        if data.TreeType then
        if data.ChamsR then UI.ChamsRBox.Text = tostring(data.ChamsR) end
        if data.ChamsG then UI.ChamsGBox.Text = tostring(data.ChamsG) end
        if data.ChamsB then UI.ChamsBBox.Text = tostring(data.ChamsB) end
        if data.CustomMoola and data.CustomMoola ~= "" then 
            UI.MoolaSpoofBox.Text = data.CustomMoola
            QoLExtras.StartMoolaSpoof(data.CustomMoola)
        end
            UI.TreeTypeBtn.Text = data.TreeType
            _G.RarityTreeSelection = data.TreeType
        end

        local starters = _G.RarityStarters

        for featName, enabled in pairs(data) do
            local isEnabled = (enabled == true) or (enabled == "true") or (enabled == 1)
            if isEnabled and Features[featName] then
                if featName == "Corpse" then AnimToggle(UI.CorpseT, UI.CorpseC, UI.CorpseS, true) end
                if featName == "Bank" then AnimToggle(UI.BankT, UI.BankC, UI.BankS, true) end
                if featName == "Chest" then AnimToggle(UI.ChestT, UI.ChestC, UI.ChestS, true) end
                if featName == "Tree" then AnimToggle(UI.TreeT, UI.TreeC, UI.TreeS, true) end
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
                if featName == "Spectator" then AnimToggle(UI.SpectatorT, UI.SpectatorC, UI.SpectatorS, true) end
                if featName == "FullBright" then AnimToggle(UI.FullBrightT, UI.FullBrightC, UI.FullBrightS, true) end
                if featName == "Fish" then AnimToggle(UI.FishT, UI.FishC, UI.FishS, true) end
                if featName == "Chams" then AnimToggle(UI.ChamsT, UI.ChamsC, UI.ChamsS, true) end
                if featName == "SaintESP" then AnimToggle(UI.SaintEspT, UI.SaintEspC, UI.SaintEspS, true) end

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

-- ==========================================
-- AUTO TREE FARM (from nezua by 55.lua, adapted for rarity.bw)
-- ==========================================
local TreeFuncs = (function()
    local tf = {}

    local selection = "ForestTrees"
    local tree = nil
    local active = false
    local wasActiveBeforeDeath = false
    local ambushhide = Vector3.new(-5971, 242, -3820)
    local bankedseed = false
    local swamp = false
    local autoclick = false
    local bankFull = false
    local chopThread = nil

    local CLICK_COOLDOWN = 0.066
    local CLICK_DURATION = 0.03
    local lastChop = 0
    local vim = game:GetService("VirtualInputManager")

    local userClicking = false
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            userClicking = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            userClicking = false
        end
    end)

    local function equipaxe()
        local axe = player.Backpack:FindFirstChild("LumberAxe")
        if axe then
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:EquipTool(axe) end
        end
    end

    local function getwoodcount()
        local wood = player.Backpack:FindFirstChild("Wood")
        if wood then
            local q = wood:FindFirstChild("Quantity")
            if q then return q.Value end
        end
        return 0
    end

    local function getseedcount()
        local seed = player.Backpack:FindFirstChild("Rokakaka Seed")
        if seed then
            local q = seed:FindFirstChild("Quantity")
            if q then return q.Value end
        end
        return 0
    end

    local function tp(pos)
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        root.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0))
        root.Velocity = Vector3.new(0, 0, 0)
        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end

    local function depositseeds()
        if bankFull then return end
        local banker = workspace:FindFirstChild("NPC") and workspace.NPC:FindFirstChild("Banker")
        if not banker then return end
        tp(banker.HumanoidRootPart.Position)
        task.wait(0.5)
        local cd = banker:FindFirstChildOfClass("ClickDetector")
        if cd then
            fireclickdetector(cd)
            task.wait(1)
        end
        local fullMsg = playerGui:FindFirstChild("DialogueGui", true)
        if fullMsg then
            local mainFrame = fullMsg:FindFirstChild("MainFrame")
            if mainFrame then
                for _, child in pairs(mainFrame:GetDescendants()) do
                    if child:IsA("TextLabel") and child.Text:find("Storage is full") then
                        bankFull = true
                        
                        local closeBtn = mainFrame:FindFirstChild("CloseButton") or mainFrame:FindFirstChild("X")
                        if closeBtn then
                            pcall(function() firesignal(closeBtn.MouseButton1Click) end)
                        end
                        return
                    end
                end
            end
        end
        local gui = playerGui:WaitForChild("DialogueGui", 3)
        if gui then
            local choice = gui.MainFrame.ChoiceList:FindFirstChild("Choice_1")
            if choice then
                pcall(function() firesignal(choice.MouseButton1Click) end)
                task.wait(1)
            end
        end
        local storage = playerGui:WaitForChild("StorageGui", 3)
        if storage then
            for _, child in pairs(storage:GetDescendants()) do
                if child:IsA("TextLabel") and child.Text:find("full") then
                    bankFull = true
                    
                    return
                end
            end
            local btn = storage.MainFrame.BackpackScroll:FindFirstChild("Rokakaka Seed")
            if btn then
                for i = 1, 5 do
                    pcall(function() firesignal(btn.MouseButton1Click) end)
                    task.wait(1)
                end
            end
        end
        task.wait(2)
    end

    local function sellwood()
        local chuck = workspace.NPC:FindFirstChild("ChuckB")
        if not chuck then return end
        tp(chuck.HumanoidRootPart.Position)
        task.wait(0.5)
        local cd = chuck:FindFirstChildOfClass("ClickDetector")
        if cd then
            fireclickdetector(cd)
            task.wait(1.5)
        end
        local gui = playerGui:WaitForChild("DialogueGui", 3)
        if gui then
            local list = gui.MainFrame.ChoiceList
            local attempts = 0
            while list:FindFirstChild("Choice_2") and attempts < 10 do
                local choice = list.Choice_2
                -- Method 1: firesignal
                pcall(function() firesignal(choice.MouseButton1Click) end)
                -- Method 2: VIM click on button position (fallback)
                pcall(function()
                    if choice.AbsolutePosition and choice.AbsoluteSize then
                        local x = choice.AbsolutePosition.X + choice.AbsoluteSize.X / 2
                        local y = choice.AbsolutePosition.Y + choice.AbsoluteSize.Y / 2
                        vim:SendMouseButtonEvent(x, y, 0, true, game, 0)
                        task.wait(0.05)
                        vim:SendMouseButtonEvent(x, y, 0, false, game, 0)
                    end
                end)
                task.wait(0.5)
                attempts = attempts + 1
            end
        end
    end

    local function chop()
        if autoclick then return end
        if userClicking then return end
        local now = tick()
        if now - lastChop < CLICK_COOLDOWN then return end
        local axe = player.Character and (player.Character:FindFirstChild("LumberAxe") or player.Backpack:FindFirstChild("LumberAxe"))
        if not axe then return end
        if not player.Character:FindFirstChild("LumberAxe") then
            equipaxe()
            task.wait(0.15)
        end
        vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(CLICK_DURATION)
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        autoclick = true
        lastChop = now
        task.delay(CLICK_COOLDOWN, function()
            autoclick = false
        end)
    end

    local function stopChop()
        autoclick = false
    end

    local function findbark(t)
        for _, part in pairs(t:GetDescendants()) do
            if part.Name == "TreeBark" and part:IsA("BasePart") then
                return part
            end
        end
    end

    local function gettrees()
        local folder = workspace.Map:FindFirstChild(selection)
        if not folder then return {} end
        local trees = {}
        for _, t in pairs(folder:GetChildren()) do
            if t:IsA("Model") and findbark(t) then
                table.insert(trees, t)
            end
        end
        return trees
    end

    local function nexttree()
        local trees = gettrees()
        if #trees == 0 then return end
        local t = trees[math.random(1, #trees)]
        local bark = findbark(t)
        if bark then
            tree = t
            tp(bark.Position)
        end
    end

    local function isplayernearby()
        local entities = workspace:FindFirstChild("Entities")
        if not entities then return end
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        for _, ent in pairs(entities:GetChildren()) do
            if ent:IsA("Model") then
                local h = ent:FindFirstChild("HumanoidRootPart")
                if h and (h.Position - root.Position).Magnitude < 50 then
                    for _, p in pairs(Players:GetPlayers()) do
                        if p.Name == ent.Name and p ~= player then
                            return p.Name
                        end
                    end
                end
            end
        end
    end

    local function isnpcnearby()
        local entities = workspace:FindFirstChild("Entities")
        if not entities then return false end
        local char = player.Character
        if not char then return false end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        local names = {}
        for _, p in pairs(Players:GetPlayers()) do
            names[p.Name] = true
        end
        for _, ent in pairs(entities:GetChildren()) do
            if ent:IsA("Model") then
                local h = ent:FindFirstChild("HumanoidRootPart")
                if h and (h.Position - root.Position).Magnitude < 50 then
                    if not names[ent.Name] then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function cleanupTrees()
        local target = Vector3.new(-9355.55, 126.95, -4578.25)
        for i = 1, 10 do
            local folder = workspace:FindFirstChild("Map", true) and workspace.Map:FindFirstChild("ForestTrees")
            if folder then
                for _, tree in ipairs(folder:GetChildren()) do
                    local part = tree:FindFirstChildWhichIsA("BasePart")
                    if part and (part.Position - target).Magnitude < 150 then
                        tree:Destroy()
                        return
                    end
                end
            end
            task.wait(0.1)
        end
    end

    local treeHeartbeat = nil

    local function startHeartbeat()
        if treeHeartbeat then return end
        treeHeartbeat = RunService.Heartbeat:Connect(function()
            if not active then return end
            if _G.RarityTreeSelection and _G.RarityTreeSelection ~= selection then
                selection = _G.RarityTreeSelection
                tree = nil
                
                _G.RarityTreeSelection = nil
            end
            local char = player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end

            if not player.Backpack:FindFirstChild("LumberAxe") and not char:FindFirstChild("LumberAxe") then
                stopChop()
                local old = root.CFrame
                local chuck = workspace.NPC:FindFirstChild("ChuckB")
                if chuck then
                    local cd = chuck:FindFirstChildWhichIsA("ClickDetector", true)
                    if cd then
                        root.CFrame = chuck:GetPivot() * CFrame.new(0, 5, 0)
                        task.wait(0.5)
                        fireclickdetector(cd)
                        task.wait(0.5)
                        local gui = playerGui:WaitForChild("DialogueGui", 3)
                        if gui then
                            local list = gui.MainFrame.ChoiceList
                            for i = 1, 2 do
                                local btn = list:FindFirstChild("Choice_1")
                                if btn then
                                    pcall(function() firesignal(btn.MouseButton1Click) end)
                                    task.wait(0.5)
                                end
                            end
                        end
                        root.CFrame = old
                    end
                end
                task.wait(1)
                return
            end

            if not char:FindFirstChild("LumberAxe") then
                equipaxe()
                task.wait(0.3)
            end

            if not autoclick and (not chopThread or coroutine.status(chopThread) == "dead") then
                chopThread = task.spawn(function()
                    while active and autoclick == false do
                        chop()
                        task.wait(0.02)
                    end
                end)
            end

            if not bankFull and not bankedseed and getseedcount() >= 5 then
                stopChop()
                depositseeds()
                bankedseed = true
                if not swamp then
                    swamp = true
                    selection = "SwampTrees"
                end
                task.wait(1)
                return
            end

            if getwoodcount() >= 500 then
                stopChop()
                sellwood()
                task.wait(1)
                return
            end

            if swamp and getseedcount() >= 5 and bankedseed then
                bankedseed = false
                return
            end

            if not tree or not tree.Parent then
                stopChop()
                nexttree()
                return
            end

            if isplayernearby() then
                stopChop()
                nexttree()
                return
            end

            if isnpcnearby() then
                stopChop()
                tp(ambushhide)
                task.wait(10)
                if tree and tree.Parent then
                    local bark = findbark(tree)
                    if bark then tp(bark.Position) end
                end
                return
            end

            local bark = findbark(tree)
            if bark then
                if not bark.CanCollide then
                    stopChop()
                    nexttree()
                else
                    tp(bark.Position)
                end
            end
        end)
    end

    local function stopHeartbeat()
        if treeHeartbeat then
            treeHeartbeat:Disconnect()
            treeHeartbeat = nil
        end
        stopChop()
    end

    function tf.StartTree()
        if active then return end
        active = true
        wasActiveBeforeDeath = true
        autoclick = false
        bankedseed = false
        Notify("🌲 Auto Tree active")
        cleanupTrees()
        startHeartbeat()
        nexttree()
    end

    function tf.StopTree()
        active = false
        wasActiveBeforeDeath = false
        stopHeartbeat()
        Notify("⚫ Auto Tree disabled")
    end

    function tf.SetSelection(sel)
        selection = sel
        tree = nil
        if sel == "SwampTrees" then swamp = true else swamp = false end
        
    end

    function tf.GetSelection() return selection end

    player.CharacterAdded:Connect(function(newChar)
        local newRoot = newChar:WaitForChild("HumanoidRootPart")
        local shouldResume = wasActiveBeforeDeath
        active = false
        autoclick = false
        bankedseed = false
        if not shouldResume then
            return
        end
        task.spawn(function()
            
            task.wait(2)
            
            local chuck = workspace.NPC:FindFirstChild("ChuckB")
            if chuck then
                local cd = chuck:FindFirstChildWhichIsA("ClickDetector", true)
                if cd then
                    newRoot.CFrame = chuck:GetPivot() * CFrame.new(0, 5, 0)
                    task.wait(0.5)
                    fireclickdetector(cd)
                    task.wait(0.5)
                    local gui = playerGui:WaitForChild("DialogueGui", 3)
                    if gui then
                        local list = gui.MainFrame.ChoiceList
                        for i = 1, 2 do
                            local btn = list:FindFirstChild("Choice_1")
                            if btn then
                                pcall(function() firesignal(btn.MouseButton1Click) end)
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end
            
            task.wait(5)
            
            active = true
            wasActiveBeforeDeath = true
            autoclick = false
            bankedseed = false
            startHeartbeat()
            nexttree()
        end)
    end)

    return tf
end)()

-- ==========================================
-- AUTO FISH (IIFE)
-- ==========================================
local FishFuncs = (function()
    local ff = {}
    local active = false
    local fishThread = nil
    local spotTimer = 0
    local currentSpotIdx = 1
    local FISH_SPOTS = {
        Vector3.new(-5000, 45, -3000),
        Vector3.new(-5200, 45, -3100),
        Vector3.new(-4800, 45, -2900),
        Vector3.new(-5100, 45, -2800),
        Vector3.new(-4900, 45, -3200),
    }
    local SPOT_SWITCH_INTERVAL = 480
    local FISH_TYPES = {"Cod", "Bass", "Snapper", "Rusty Mares Leg"}

    local function getRod()
        local bp = player:FindFirstChild("Backpack")
        if bp then
            local rod = bp:FindFirstChild("FishingRod")
            if rod then return rod end
        end
        local char = player.Character
        if char then
            local rod = char:FindFirstChild("FishingRod")
            if rod then return rod end
        end
        return nil
    end

    local function buyRod()
        local daniel = Workspace:FindFirstChild("NPC") and Workspace.NPC:FindFirstChild("Daniel")
        if not daniel then return false end
        local char = player.Character
        if not char then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        hrp.CFrame = CFrame.new(daniel:GetPivot().Position + Vector3.new(0, 5, 0))
        task.wait(0.5)
        local cd = daniel:FindFirstChildOfClass("ClickDetector")
        if cd then
            fireclickdetector(cd)
            task.wait(1)
            local gui = playerGui:WaitForChild("DialogueGui", 3)
            if gui then
                local list = gui.MainFrame.ChoiceList
                for i = 1, 3 do
                    local btn = list:FindFirstChild("Choice_" .. i)
                    if btn and (btn.Text:find("FishingRod") or btn.Text:find("Rod")) then
                        pcall(function() firesignal(btn.MouseButton1Click) end)
                        task.wait(0.5)
                        return getRod() ~= nil
                    end
                end
            end
        end
        return false
    end

    local function equipRod()
        local rod = getRod()
        if not rod then return false end
        local char = player.Character
        if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        if rod.Parent ~= char then
            hum:EquipTool(rod)
            task.wait(0.3)
        end
        return true
    end

    local function freezeHRP()
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.Anchored = true
    end

    local function unfreezeHRP()
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.Anchored = false
    end

    local function tpToSpot(idx)
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local spot = FISH_SPOTS[idx]
        if not spot then return end
        hrp.CFrame = CFrame.new(spot + Vector3.new(0, 5, 0))
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end

    local function castLine()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.1)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        task.wait(2)
    end

    local function waitForBite()
        local start = tick()
        while active do
            local char = player.Character
            if char then
                local fishGui = playerGui:FindFirstChild("FishingGui") or playerGui:FindFirstChild("FishGui")
                if fishGui then return true end
                for _, sound in ipairs(char:GetDescendants()) do
                    if sound:IsA("Sound") and sound.Playing and (sound.Name:find("Splash") or sound.Name:find("Bite")) then
                        return true
                    end
                end
            end
            if tick() - start > 30 then return false end
            task.wait(0.2)
        end
        return false
    end

    local function reelIn()
        local VIM = game:GetService("VirtualInputManager")
        VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(3)
        VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        task.wait(1)
    end

    local function handleQTE()
        local qteGui = playerGui:FindFirstChild("QTEGui") or playerGui:FindFirstChild("QuickTimeEvent")
        if not qteGui then
            for _, gui in ipairs(playerGui:GetChildren()) do
                if gui:IsA("ScreenGui") and (gui.Name:find("QTE") or gui.Name:find("Timing") or gui.Name:find("Fish")) then
                    qteGui = gui
                    break
                end
            end
        end
        if qteGui then
            local start = tick()
            while tick() - start < 5 do
                for _, btn in ipairs(qteGui:GetDescendants()) do
                    if btn:IsA("GuiButton") or btn:IsA("TextButton") then
                        pcall(function() firesignal(btn.MouseButton1Click) end)
                        pcall(function()
                            if btn.AbsolutePosition and btn.AbsoluteSize then
                                local x = btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2
                                local y = btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2
                                VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
                                task.wait(0.05)
                                VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
                            end
                        end)
                    end
                end
                task.wait(0.1)
            end
        end
    end

    local function openChestIfAny()
        local char = player.Character
        if not char then return end
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and item.Name:find("Chest") then
                for _, desc in ipairs(item:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") then
                        pcall(function() fireproximityprompt(desc) end)
                    end
                end
                task.wait(0.5)
            end
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj.Name:find("Chest") and obj:IsA("Model") then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part and (part.Position - hrp.Position).Magnitude < 10 then
                        for _, desc in ipairs(obj:GetDescendants()) do
                            if desc:IsA("ProximityPrompt") then
                                pcall(function() fireproximityprompt(desc) end)
                            end
                        end
                    end
                end
            end
        end
    end

    local function sellFish()
        local daniel = Workspace:FindFirstChild("NPC") and Workspace.NPC:FindFirstChild("Daniel")
        if not daniel then return end
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.CFrame = CFrame.new(daniel:GetPivot().Position + Vector3.new(0, 5, 0))
        task.wait(0.5)
        local cd = daniel:FindFirstChildOfClass("ClickDetector")
        if cd then
            fireclickdetector(cd)
            task.wait(1)
            local gui = playerGui:WaitForChild("DialogueGui", 3)
            if gui then
                local list = gui.MainFrame.ChoiceList
                for i = 1, 5 do
                    local btn = list:FindFirstChild("Choice_" .. i)
                    if btn and (btn.Text:find("Sell") or btn.Text:find("sell")) then
                        pcall(function() firesignal(btn.MouseButton1Click) end)
                        task.wait(0.5)
                        break
                    end
                end
            end
        end
    end

    function ff.StartFish()
        if active then return end
        active = true
        spotTimer = 0
        currentSpotIdx = 1
        Notify("🎣 Auto Fish active")

        fishThread = task.spawn(function()
            while active do
                local char = player.Character
                if not char then
                    player.CharacterAdded:Wait()
                    task.wait(2)
                    char = player.Character
                end

                if not getRod() then
                    Notify("Buying FishingRod...", 2)
                    if not buyRod() then
                        Notify("Failed to buy rod", 3)
                        task.wait(5)
                        continue
                    end
                end

                if not equipRod() then
                    task.wait(1)
                    continue
                end

                tpToSpot(currentSpotIdx)
                task.wait(1)
                freezeHRP()

                local spotStart = tick()
                while active and (tick() - spotStart) < SPOT_SWITCH_INTERVAL do
                    castLine()
                    if waitForBite() then
                        reelIn()
                        handleQTE()
                        openChestIfAny()
                        task.wait(1)
                    else
                        task.wait(2)
                    end
                end

                unfreezeHRP()
                currentSpotIdx = currentSpotIdx % #FISH_SPOTS + 1
                spotTimer = 0
                Notify("Switching fishing spot...", 2)
                task.wait(2)
            end

            unfreezeHRP()
            Notify("⚫ Auto Fish stopped", 3)
        end)
    end

    function ff.StopFish()
        active = false
        if fishThread then
            pcall(function() coroutine.close(fishThread) end)
            fishThread = nil
        end
        unfreezeHRP()
        Notify("⚫ Auto Fish disabled")
    end

    return ff
end)()

_G.RarityStarters = {
    Corpse = FarmFuncs.StartCorpse,
    Bank = FarmFuncs.StartBank,
    Chest = FarmFuncs.StartChest,
    Tree = TreeFuncs.StartTree,
    SaintScanner = ScannerFuncs.StartScanner,
    ESP = ESPFuncs.StartESP,
    ClickTp = MovementFuncs.StartClickTp,
    Fly = MovementFuncs.StartFly,
    RaknetDesync = ExploitFuncs.StartRaknet,
    HideName = ExploitFuncs.StartHide,
    AutoBuy = QoLFuncs.startAutoBuy,
    AttachPlayer = QoLFuncs.startAttach,
    NoClip = NoClipFuncs.StartNoClip,
    Invisible = NoClipFuncs.StartInvisible,
    FullBright = VisualFuncs.StartFullBright,
    Fish = FishFuncs.StartFish,
    Chams = ChamFuncs.StartChams,
    SaintESP = ChamFuncs.StartSaintESP,
    PosTracker = QoLExtras.StartPosTracker
}
_G.RarityStoppers = {
    Corpse = FarmFuncs.StopCorpse,
    Bank = FarmFuncs.StopBank,
    Chest = FarmFuncs.StopChest,
    Tree = TreeFuncs.StopTree,
    SaintScanner = ScannerFuncs.StopScanner,
    ESP = ESPFuncs.StopESP,
    ClickTp = MovementFuncs.StopClickTp,
    Fly = MovementFuncs.StopFly,
    RaknetDesync = ExploitFuncs.StopRaknet,
    HideName = ExploitFuncs.StopHide,
    AutoBuy = QoLFuncs.stopAutoBuy,
    AttachPlayer = QoLFuncs.stopAttach,
    NoClip = NoClipFuncs.StopNoClip,
    Invisible = NoClipFuncs.StopInvisible,
    FullBright = VisualFuncs.StopFullBright,
    Fish = FishFuncs.StopFish,
    Chams = ChamFuncs.StopChams,
    SaintESP = ChamFuncs.StopSaintESP,
    PosTracker = QoLExtras.StopPosTracker
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
ST(UI.TreeT, UI.TreeC, UI.TreeS, "Tree", TreeFuncs.StartTree, TreeFuncs.StopTree)
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
ST(UI.FullBrightT, UI.FullBrightC, UI.FullBrightS, "FullBright", VisualFuncs.StartFullBright, VisualFuncs.StopFullBright)
ST(UI.FishT, UI.FishC, UI.FishS, "Fish", FishFuncs.StartFish, FishFuncs.StopFish)
ST(UI.ChamsT, UI.ChamsC, UI.ChamsS, "Chams", ChamFuncs.StartChams, ChamFuncs.StopChams)
ST(UI.SaintEspT, UI.SaintEspC, UI.SaintEspS, "SaintESP", ChamFuncs.StartSaintESP, ChamFuncs.StopSaintESP)
ST(UI.PosTrackerT, UI.PosTrackerC, UI.PosTrackerS, "PosTracker", QoLExtras.StartPosTracker, QoLExtras.StopPosTracker)

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
            UI.KbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            IsListening = false
            if conn then conn:Disconnect() end
        end
    end)
    task.delay(5, function()
        if IsListening then
            IsListening = false
            UI.KbBtn.Text = tostring(GuiKeybind):gsub("Enum.KeyCode.", "")
            UI.KbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
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
            UI.FlyKbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            IsFlyListening = false
            if conn then conn:Disconnect() end
        end
    end)
    task.delay(5, function()
        if IsFlyListening then
            IsFlyListening = false
            UI.FlyKbBtn.Text = tostring(FlyKeybind):gsub("Enum.KeyCode.", "")
            UI.FlyKbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
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
            UI.SpectatorKbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            IsSpectatorListening = false
            if conn then conn:Disconnect() end
        end
    end)
    task.delay(5, function()
        if IsSpectatorListening then
            IsSpectatorListening = false
            UI.SpectatorKbBtn.Text = tostring(SpectatorKeybind):gsub("Enum.KeyCode.", "")
            UI.SpectatorKbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    if i.KeyCode == TreeKeybind then
        Features.Tree.E = not Features.Tree.E
        AnimToggle(UI.TreeT, UI.TreeC, UI.TreeS, Features.Tree.E)
        if Features.Tree.E then TreeFuncs.StartTree() else TreeFuncs.StopTree() end
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
            elseif at == "Settings" then ts = UDim2.new(0, 400, 0, 420) end
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
if ok and src and #src > 100 then loadstring(src)() else end
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

UI.TreeKbBtn.MouseButton1Click:Connect(function()
    if IsTreeListening then return end
    IsTreeListening = true
    UI.TreeKbBtn.Text = "Press key"
    UI.TreeKbBtn.TextColor3 = Color3.new(1, 1, 1)
    local conn
    conn = UserInputService.InputBegan:Connect(function(i, g)
        if g then return end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            TreeKeybind = i.KeyCode
            UI.TreeKbBtn.Text = tostring(i.KeyCode):gsub("Enum.KeyCode.", "")
            UI.TreeKbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            IsTreeListening = false
            if conn then conn:Disconnect() end
        end
    end)
    task.delay(5, function()
        if IsTreeListening then
            IsTreeListening = false
            UI.TreeKbBtn.Text = tostring(TreeKeybind):gsub("Enum.KeyCode.", "")
            UI.TreeKbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            if conn then conn:Disconnect() end
        end
    end)
end)

UI.FpsApplyBtn.MouseButton1Click:Connect(function()
    local n = tonumber(UI.FpsBox.Text)
    if n and n > 0 then
        pcall(function() setfpscap(n) end)
        _G.RarityFpsCap = n
        _G.RarityFpsCheckTime = 0
        Notify("FPS Cap set to " .. n, 2)
    else
        Notify("Invalid FPS value", 2)
    end
end)

-- Smart FPS Cap restore: only apply if current FPS exceeds the cap
RunService.Heartbeat:Connect(function()
    if not _G.RarityFpsCap or _G.RarityFpsCap <= 0 then return end
    local now = tick()
    -- Check every 2 seconds to avoid constant calls
    if now - (_G.RarityFpsCheckTime or 0) < 2 then return end
    _G.RarityFpsCheckTime = now

    -- Check current FPS via workspace:GetRealPhysicsFPS() or similar
    local currentFps = 60 -- default assumption
    pcall(function()
        if workspace.GetRealPhysicsFPS then
            currentFps = workspace:GetRealPhysicsFPS()
        end
    end)

    -- If current FPS is significantly higher than cap, re-apply
    if currentFps > _G.RarityFpsCap + 10 then
        pcall(function() setfpscap(_G.RarityFpsCap) end)
    end
end)

UI.FogBtn.MouseButton1Click:Connect(VisualFuncs.RemoveFog)

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
            UI.AttachKbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            QoLFuncs.SetIsAttachListening(false)
            if conn then conn:Disconnect() end
        end
    end)
    task.delay(5, function()
        if QoLFuncs.IsAttachListening() then
            QoLFuncs.SetIsAttachListening(false)
            UI.AttachKbBtn.Text = tostring(QoLFuncs.AttachKeybind()):gsub("Enum.KeyCode.", "")
            UI.AttachKbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
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
                    if data.TreeKeybind then
                        local ok2,kc2=pcall(function() return Enum.KeyCode[data.TreeKeybind] end)
                        if ok2 and kc2 then TreeKeybind=kc2 UI.TreeKbBtn.Text=data.TreeKeybind end
                    end
                    if data.TreeType then
                    if data.ChamsR then UI.ChamsRBox.Text = tostring(data.ChamsR) end
                    if data.ChamsG then UI.ChamsGBox.Text = tostring(data.ChamsG) end
                    if data.ChamsB then UI.ChamsBBox.Text = tostring(data.ChamsB) end
                    if data.CustomMoola and data.CustomMoola ~= "" then 
                        UI.MoolaSpoofBox.Text = data.CustomMoola
                        QoLExtras.StartMoolaSpoof(data.CustomMoola)
                    end
                        UI.TreeTypeBtn.Text = data.TreeType
                        _G.RarityTreeSelection = data.TreeType
                    end

                    local starters = _G.RarityStarters

                    for featName, enabled in pairs(data) do
                        local isEnabled = (enabled == true) or (enabled == "true") or (enabled == 1)
                        if isEnabled and Features[featName] then
                            if featName == "Corpse" then AnimToggle(UI.CorpseT, UI.CorpseC, UI.CorpseS, true) end
                            if featName == "Bank" then AnimToggle(UI.BankT, UI.BankC, UI.BankS, true) end
                            if featName == "Chest" then AnimToggle(UI.ChestT, UI.ChestC, UI.ChestS, true) end
                            if featName == "Tree" then AnimToggle(UI.TreeT, UI.TreeC, UI.TreeS, true) end
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
                            if featName == "Spectator" then AnimToggle(UI.SpectatorT, UI.SpectatorC, UI.SpectatorS, true) end
                            if featName == "FullBright" then AnimToggle(UI.FullBrightT, UI.FullBrightC, UI.FullBrightS, true) end
                            if featName == "Fish" then AnimToggle(UI.FishT, UI.FishC, UI.FishS, true) end
                            if featName == "Chams" then AnimToggle(UI.ChamsT, UI.ChamsC, UI.ChamsS, true) end
                            if featName == "SaintESP" then AnimToggle(UI.SaintEspT, UI.SaintEspC, UI.SaintEspS, true) end
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
-- rarity.bw KickDetector
-- Triggers on ANY message containing "detected"
-- No file logging, instant reaction
-- Compatible: Potassium, Volt
-- Game: Bridger: Western (Roblox)
-- ==========================================

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LogService = game:GetService("LogService")
local playerGui = player:WaitForChild("PlayerGui")

-- ==========================================
-- CONFIG
-- ==========================================
local CONFIG = {
    AutoServerHop = true,
    DelayBeforeHop = 0,
    MaxHopRetries = 5,
    HopRetryDelay = 0.5,
    NotifyOnKick = true,
    NotifyOnHop = true,
    -- Universal trigger: ANY message with "detected"
    UniversalPattern = "detected",
    -- Additional specific patterns for faster matching
    FastPatterns = {
        "SERVER KICK MESSAGE",
        "Error Code: 267",
        "PLAYER DISCONNECTED",
        "KICKED",
        "DUMPING",
        "Clearing environment",
        "Destroy script",
    },
    ConsolePollRate = 0.02,  -- 20ms = maximum aggressive
}

-- ==========================================
-- STATE
-- ==========================================
local State = {
    isKicked = false,
    kickReason = nil,
    detectorActive = false,
    connections = {},
    hopInProgress = false,
    lastConsoleIndex = 0,
    guiCheckActive = false,
}

-- ==========================================
-- UTILS
-- ==========================================
local function Notify(text, duration)
    duration = duration or 3
    pcall(function()
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCore("SendNotification", {
            Title = "rarity.bw KickDetector",
            Text = text,
            Duration = duration,
        })
    end)
    
end

-- ==========================================
-- EMERGENCY HOP (zero delay)
-- ==========================================
local function EmergencyHop()
    if State.hopInProgress then return end
    State.hopInProgress = true

    local PID = game.PlaceId
    local CJID = game.JobId

    -- Setup auto-exec for rejoin
    local SCRIPT_URL = "https://raw.githubusercontent.com/kresteq/bridgerAnticheatSUCKS/refs/heads/main/1337.lua"
    local loaderTemplate = [[
repeat task.wait() until game:IsLoaded()
task.wait(1.5)
local url = "%s" .. "?nocache=" .. tostring(tick())
local ok, src = pcall(function() return game:HttpGet(url) end)
if ok and src and #src > 100 then loadstring(src)() else warn("[rarity.bw] AutoExec failed") end
]]
    local loader = string.format(loaderTemplate, SCRIPT_URL)
    if type(queue_on_teleport) == "function" then pcall(queue_on_teleport, loader)
    elseif type(queueonteleport) == "function" then pcall(queueonteleport, loader) end

    -- Try server list
    local AIDs = {}
    pcall(function()
        local data = readfile("NotSameServers.json")
        AIDs = HttpService:JSONDecode(data)
    end)
    if #AIDs == 0 then
        table.insert(AIDs, os.date("!*t").hour)
        pcall(function() writefile("NotSameServers.json", HttpService:JSONEncode(AIDs)) end)
    end

    -- Fast single request
    local url = 'https://games.roblox.com/v1/games/'..PID..'/servers/Public?sortOrder=Desc&limit=100'..'&_nc='..tostring(tick())
    local response
    local httpOk = pcall(function() response = game:HttpGet(url) end)

    if httpOk and response then
        local decodeOk, S = pcall(function() return HttpService:JSONDecode(response) end)
        if decodeOk and S and S.data then
            for _, v in ipairs(S.data) do
                local pl = tonumber(v.playing)
                local mp = tonumber(v.maxPlayers)
                local sid = tostring(v.id)
                if pl and mp and sid and pl >= 1 and pl <= 25 and sid ~= CJID and pl < mp then
                    if not table.find(AIDs, sid) then
                        table.insert(AIDs, sid)
                        pcall(function() writefile("NotSameServers.json", HttpService:JSONEncode(AIDs)) end)
                        if CONFIG.NotifyOnHop then
                            Notify("🚀 HOPPING!", 2)
                        end
                        pcall(function() TeleportService:TeleportToPlaceInstance(PID, sid, player) end)
                        return true
                    end
                end
            end
        end
    end

    -- Fallback
    pcall(function() TeleportService:Teleport(PID, player) end)
    return false
end

-- ==========================================
-- TRIGGER
-- ==========================================
local function TriggerHop(reason, method)
    if State.isKicked then return end
    State.isKicked = true
    State.kickReason = reason

    if CONFIG.NotifyOnKick then
        Notify("⚠️ " .. tostring(reason):sub(1, 80), 5)
    end

    if CONFIG.AutoServerHop then
        EmergencyHop()
    end
end

-- ==========================================
-- DETECTION METHODS
-- ==========================================

-- Method 1: AGGRESSIVE console scanning with universal "detected" trigger
local function MonitorConsole()
    State.lastConsoleIndex = 0
    task.spawn(function()
        while State.detectorActive do
            local success, logs = pcall(function()
                return LogService:GetLogHistory()
            end)
            if success and logs then
                local newLogs = #logs
                if newLogs > State.lastConsoleIndex then
                    -- Check newest first (backwards)
                    for i = newLogs, State.lastConsoleIndex + 1, -1 do
                        local log = logs[i]
                        if log and log.message then
                            local msg = tostring(log.message)
                            local msgLower = msg:lower()

                            --: ANY message containing "detected"
                            if msgLower:find(CONFIG.UniversalPattern, 1, true) then
                                TriggerHop("Detected: " .. msg:sub(1, 100), "Universal:detected")
                                return
                            end

                            -- Fast patterns for immediate known kicks
                            for _, pattern in ipairs(CONFIG.FastPatterns) do
                                if msg:find(pattern, 1, true) then
                                    TriggerHop("Fast: " .. msg:sub(1, 80), "Fast:" .. pattern)
                                    return
                                end
                            end
                        end
                    end
                    State.lastConsoleIndex = newLogs
                end
            end
            task.wait(CONFIG.ConsolePollRate)
        end
    end)
end

-- Method 2: GUI Detection (Disconnected screen)
local function MonitorGui()
    State.guiCheckActive = true
    task.spawn(function()
        while State.guiCheckActive do
            for _, child in ipairs(playerGui:GetChildren()) do
                if child:IsA("ScreenGui") then
                    local name = child.Name:lower()
                    if name:find("error") or name:find("disconnect") or name:find("leave") then
                        for _, desc in ipairs(child:GetDescendants()) do
                            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                                local text = desc.Text:lower()
                                if text:find("kicked") or text:find("disconnected") 
                                   or text:find("moderation") or text:find("error") then
                                    TriggerHop("GUI: " .. desc.Text:sub(1, 50), "GUI")
                                    State.guiCheckActive = false
                                    return
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- Method 3: Player.Parent (removed from game)
local function MonitorParent()
    local conn = player:GetPropertyChangedSignal("Parent"):Connect(function()
        if not State.detectorActive then return end
        if player.Parent ~= Players then
            TriggerHop("Player removed", "Parent")
        end
    end)
    table.insert(State.connections, conn)
end

-- Method 4: CharacterRemoving
local function MonitorCharacter()
    local conn = player.CharacterRemoving:Connect(function()
        if not State.detectorActive then return end
        task.delay(1, function()
            if not player.Character and player.Parent == Players and State.detectorActive and not State.isKicked then
                TriggerHop("Character removed", "Character")
            end
        end)
    end)
    table.insert(State.connections, conn)
end

-- Method 5: Heartbeat freeze
local function MonitorHeartbeat()
    local lastTick = tick()
    local conn = RunService.Heartbeat:Connect(function()
        if not State.detectorActive then return end
        if tick() - lastTick > 3 then
            TriggerHop("Connection frozen", "Heartbeat")
        end
        lastTick = tick()
    end)
    table.insert(State.connections, conn)
end

-- ==========================================
-- PUBLIC API
-- ==========================================
local KickDetector = {}

function KickDetector.Start()
    if State.detectorActive then return end

    State.detectorActive = true
    State.isKicked = false
    State.kickReason = nil
    State.hopInProgress = false
    State.lastConsoleIndex = 0
    State.guiCheckActive = false

    pcall(MonitorConsole)
    pcall(MonitorGui)
    pcall(MonitorParent)
    pcall(MonitorCharacter)
    pcall(MonitorHeartbeat)

    Notify("🛡️ KickDetector active", 2)
end

function KickDetector.Stop()
    State.detectorActive = false
    State.guiCheckActive = false
    for _, conn in ipairs(State.connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    State.connections = {}
    Notify("🛑 KickDetector stopped", 2)
end

function KickDetector.IsKicked() return State.isKicked end
function KickDetector.GetReason() return State.kickReason end

function KickDetector.ForceHop()
    State.isKicked = true
    State.hopInProgress = false
    EmergencyHop()
end

-- ==========================================
-- INIT
-- ==========================================
ConfigFuncs.RefreshConfigListUI()

-- KickDetector auto-start
pcall(function() KickDetector.Start() end)

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

Notify("✅ rarity.bw loaded successfully", 4)
