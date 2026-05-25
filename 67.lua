-- ==========================================
-- Adonis Bypass Framework (Optimized)
-- Original Author: xiaomao8090
-- Based on: https://github.com/xiaomao8090/Adonis-Bypass-Framework
-- Optimized for: rarity.bw / Bridger: Western
-- Supported Executors: Potassium, Volt, Synapse Z, Seliware, Madium
-- ==========================================

local AdonisBypass = {}
local BypassActive = false

-- Executor capability detection
local hasHookFunction = type(hookfunction) == "function"
local hasNewCClosure = type(newcclosure) == "function"
local hasGetRawMeta = type(getrawmetatable) == "function"
local hasGetGc = type(getgc) == "function"
local hasGetCallingScript = type(getcallingscript) == "function"
local hasGetNamecallMethod = type(getnamecallmethod) == "function"
local hasCheckCaller = type(checkcaller) == "function"

if not (hasHookFunction and hasNewCClosure and hasGetRawMeta) then
    warn("[AdonisBypass] Missing critical functions. Bypass may not work fully.")
end

-- ==========================================
-- LAYER 3: Metatable Protection
-- Saves original __index/__newindex/__namecall
-- ==========================================
local OriginalMeta = {}
local function SaveMetatables()
    local mt = getrawmetatable and getrawmetatable(game)
    if not mt then return end

    OriginalMeta.__index = mt.__index
    OriginalMeta.__newindex = mt.__newindex
    OriginalMeta.__namecall = mt.__namecall

    if setreadonly then
        pcall(function()
            setreadonly(mt, false)
        end)
    end
end

-- ==========================================
-- LAYER 4: Remote Interception
-- Blocks suspicious FireServer/InvokeServer calls
-- SAFE: Only blocks kick/ban/detect, NOT stamina/antitool
-- ==========================================
local BlockedPatterns = {
    "kick", "ban", "detect", "anticheat", "adminlog"
}

local function IsBlockedRemote(name)
    if not name then return false end
    name = tostring(name):lower()
    for _, pattern in ipairs(BlockedPatterns) do
        if name:find(pattern, 1, true) then
            return true, pattern
        end
    end
    return false
end

local function SetupRemoteInterception()
    if not hasGetRawMeta then return end

    local mt = getrawmetatable(game)
    if not mt then return end

    local oldNamecall = mt.__namecall
    if not oldNamecall then return end

    mt.__namecall = newcclosure(function(self, ...)
        if checkcaller and checkcaller() then
            return oldNamecall(self, ...)
        end

        local method = getnamecallmethod and getnamecallmethod()
        if method ~= "FireServer" and method ~= "InvokeServer" then
            return oldNamecall(self, ...)
        end

        local name = self.Name or self.name or ""
        local blocked, pattern = IsBlockedRemote(name)

        if blocked then
            return nil
        end

        return oldNamecall(self, ...)
    end)

    local remoteEvent = Instance.new("RemoteEvent")
    local remoteFunc = Instance.new("RemoteFunction")

    local oldFireServer = remoteEvent.FireServer
    local oldInvokeServer = remoteFunc.InvokeServer

    pcall(function()
        hookfunction(oldFireServer, newcclosure(function(self, ...)
            local blocked, pattern = IsBlockedRemote(self.Name)
            if blocked then
                return nil
            end
            return oldFireServer(self, ...)
        end))
    end)

    pcall(function()
        hookfunction(oldInvokeServer, newcclosure(function(self, ...)
            local blocked, pattern = IsBlockedRemote(self.Name)
            if blocked then
                return nil
            end
            return oldInvokeServer(self, ...)
        end))
    end)

    remoteEvent:Destroy()
    remoteFunc:Destroy()
end

-- ==========================================
-- LAYER 6: Hide Exploit Traces
-- Cleans up common executor globals
-- ==========================================
local function HideTraces()
    local traces = {
        "syn", "gethui", "KRNL_LOADED", "OXYGEN_LOADED", 
        "FLUXUS_LOADED", "CODEX_LOADED", "delta_loaded",
        "is_synapse_function", "is_krnl_function"
    }

    for _, trace in ipairs(traces) do
        if getgenv and getgenv()[trace] ~= nil then
            pcall(function()
                getgenv()[trace] = nil
            end)
        end
        if _G[trace] ~= nil then
            pcall(function()
                _G[trace] = nil
            end)
        end
    end
end

-- ==========================================
-- LAYER 10: GUI Detection Blocking
-- Hides suspicious GUI elements from Adonis scans
-- ==========================================
local function SetupGUIDetectionBlocking()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    if not player then return end

    local playerGui = player:WaitForChild("PlayerGui")

    local suspiciousTexts = {
        "detected", "kicked", "banned", "exploit", "cheat",
        "unauthorized", "hacking", "injection"
    }

    local function CheckAndHideGui(gui)
        if not gui or not gui:IsA("GuiObject") then return end

        if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
            local text = gui.Text or ""
            text = text:lower()
            for _, susp in ipairs(suspiciousTexts) do
                if text:find(susp, 1, true) then
                    gui.Visible = false
                    gui.Text = ""
                    break
                end
            end
        end

        for _, child in ipairs(gui:GetChildren()) do
            CheckAndHideGui(child)
        end
    end

    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") then
            CheckAndHideGui(gui)
        end
    end

    playerGui.ChildAdded:Connect(function(child)
        if child:IsA("ScreenGui") then
            task.wait(0.1)
            CheckAndHideGui(child)
        end
    end)
end

-- ==========================================
-- LAYER 11: Call Stack Spoofing
-- Spoofs getcallingscript() to hide exploit origin
-- ==========================================
local function SetupCallStackSpoofing()
    if not hasGetCallingScript then return end

    local oldGetCallingScript = getcallingscript

    pcall(function()
        hookfunction(getcallingscript, newcclosure(function()
            if checkcaller and checkcaller() then
                local Players = game:GetService("Players")
                local player = Players.LocalPlayer
                if player then
                    local playerScripts = player:WaitForChild("PlayerScripts", 1)
                    if playerScripts then
                        for _, script in ipairs(playerScripts:GetChildren()) do
                            if script:IsA("LocalScript") then
                                return script
                            end
                        end
                    end
                end
                local starterPlayer = game:GetService("StarterPlayer")
                local starterScripts = starterPlayer:FindFirstChild("StarterPlayerScripts")
                if starterScripts then
                    for _, script in ipairs(starterScripts:GetChildren()) do
                        if script:IsA("LocalScript") then
                            return script
                        end
                    end
                end
            end
            return oldGetCallingScript()
        end))
    end)
end

-- ==========================================
-- LAYER 13: Detected Function Hook
-- Hooks Adonis Detected function via getgc
-- ==========================================
local function HookDetectedFunction()
    if not hasGetGc then
        warn("[AdonisBypass] getgc not available, Layer 13 skipped")
        return
    end

    local DetectedHooked = false
    local Attempts = 0
    local MaxAttempts = 50

    local function TryHook()
        if DetectedHooked then return true end
        if Attempts >= MaxAttempts then return false end
        Attempts = Attempts + 1

        local gc = getgc()
        if not gc then return false end

        for _, obj in ipairs(gc) do
            if type(obj) == "function" then
                local info = debug.getinfo(obj)
                if info and info.name == "Detected" then
                    local upvalues = debug.getupvalues and debug.getupvalues(obj)
                    if upvalues then
                        for _, upv in pairs(upvalues) do
                            if type(upv) == "table" and upv.RLocked ~= nil then
                                pcall(function()
                                    hookfunction(obj, newcclosure(function(...)
                                        return nil
                                    end))
                                end)
                                DetectedHooked = true
                                return true
                            end
                        end
                    end
                end
            end
        end

        return false
    end

    if TryHook() then
        return
    end

    local conn
    conn = game:GetService("RunService").Heartbeat:Connect(function()
        if TryHook() then
            conn:Disconnect()
        elseif Attempts >= MaxAttempts then
            conn:Disconnect()
            warn("[AdonisBypass] Layer 13: Failed to hook Detected after " .. MaxAttempts .. " attempts")
        end
    end)
end

-- ==========================================
-- LAYER 7: Player.Kick Hook
-- Blocks player:Kick() calls
-- ==========================================
local function SetupKickHook()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    if not player then return end

    local oldKick = player.Kick

    pcall(function()
        hookfunction(player.Kick, newcclosure(function(self, reason)
            if self == player then
                warn("[AdonisBypass] Blocked Kick: " .. tostring(reason))
                return nil
            end
            return oldKick(self, reason)
        end))
    end)
end

-- ==========================================
-- MAIN INITIALIZATION
-- ==========================================
function AdonisBypass.Start()
    if BypassActive then return end
    BypassActive = true

    SaveMetatables()
    pcall(HideTraces)
    pcall(SetupRemoteInterception)
    pcall(SetupCallStackSpoofing)
    pcall(SetupKickHook)
    pcall(SetupGUIDetectionBlocking)

    task.spawn(function()
        pcall(HookDetectedFunction)
    end)
end

AdonisBypass.Start()
getgenv().AdonisBypass = AdonisBypass
