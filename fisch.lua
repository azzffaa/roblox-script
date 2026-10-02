--[[
    AZZ HUB | Fisch Minimalist
    Theme : Monochrome (Black BG / White Accent)
    Mode  : Anti-Lag, Autosave, Profile Preset
]]

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer

--// CONFIG STORE
local CONFIG = {
    Transparency   = 0.15,
    LowPerf        = false,

    AutoFish       = false,
    CastPower      = "Perfect",
    ProgressSpeed  = 100,
    BarModifier    = 0.8,
    AutoReel       = true,
    ReelDelay      = 0.35,

    AutoSpear      = false,
    SpearRarity    = "All",
    SpearFilter    = "",
    SpearLocation  = "Current",
    SpearDelay     = 0.6,

    AutoSell       = false,
    SellPriority   = "Shady",
    KeepRarity     = "Legendary",

    Jitter         = true,
    PanicKey       = Enum.KeyCode.RightShift,
}

local PRESET_SLOTS = {}
local TRACKER = { sessionStart = tick(), totalC = 0, fishCount = 0 }
local CONFIG_FILE = "AzzHub_Fisch_Config.json"

--// LOAD / SAVE
local function saveConfig()
    pcall(function()
        if writefile then writefile(CONFIG_FILE, HttpService:JSONEncode(CONFIG)) end
    end)
end

local function loadConfig()
    pcall(function()
        if readfile and isfile and isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            for k, v in pairs(data) do CONFIG[k] = v end
        end
    end)
end
loadConfig()

--// LOW PERF MODE
local function applyLowPerf(state)
    CONFIG.LowPerf = state
    pcall(function()
        Lighting.GlobalShadows = not state
        Lighting.FogEnd        = state and 200 or 100000
        Lighting.Brightness    = state and 0 or 2
        settings().Rendering.QualityLevel = state and Enum.QualityLevel.Level01 or Enum.QualityLevel.Level10

        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
                obj.Enabled = not state
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = state and 1 or 0
            end
        end
    end)
end

--// GUI CORE
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AzzHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = LP:WaitForChild("PlayerGui") end

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 420, 0, 520)
Main.Position = UDim2.new(0.5, -210, 0.5, -260)
Main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Main.BackgroundTransparency = CONFIG.Transparency
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(255, 255, 255)
Stroke.Thickness = 1
Stroke.Transparency = 0.6
Stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundTransparency = 1
Title.Text = "AZZ HUB  //  FISCH"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Parent = Main

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -52)
Scroll.Position = UDim2.new(0, 8, 0, 44)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

--// HELPERS
local function newSection(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.BackgroundTransparency = 1
    lbl.Text = "— " .. text
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Parent = Scroll
    return lbl
end

local function newButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = CONFIG.Transparency
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.AutoButtonColor = false
    btn.Parent = Scroll

    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Thickness = 1
    s.Transparency = 0.5
    s.Parent = btn

    btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0.35 end)
    btn.MouseLeave:Connect(function() btn.BackgroundTransparency = CONFIG.Transparency end)
    btn.MouseButton1Click:Connect(function() callback(btn) end)
    return btn
end

local function newToggle(text, key, callback)
    local btn = newButton(text .. "  :  " .. (CONFIG[key] and "ON" or "OFF"), function()
        CONFIG[key] = not CONFIG[key]
        btn.Text = text .. "  :  " .. (CONFIG[key] and "ON" or "OFF")
        if callback then callback(CONFIG[key]) end
        saveConfig()
    end)
    return btn
end

local function newSlider(text, key, min, max, isDecimal, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.BackgroundTransparency = 1
    frame.Parent = Scroll

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 16)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. "  :  " .. tostring(CONFIG[key])
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Parent = frame

    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, 0, 0, 14)
    bar.Position = UDim2.new(0, 0, 0, 20)
    bar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bar.BackgroundTransparency = CONFIG.Transparency
    bar.Text = ""
    bar.AutoButtonColor = false
    bar.Parent = frame

    local bs = Instance.new("UIStroke")
    bs.Color = Color3.fromRGB(255, 255, 255)
    bs.Thickness = 1
    bs.Transparency = 0.5
    bs.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((CONFIG[key] - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.BackgroundTransparency = 0.3
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local dragging = false

    local function update(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = min + (max - min) * rel
        if not isDecimal then val = math.floor(val + 0.5) end
        CONFIG[key] = val
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = text .. "  :  " .. tostring(val)
        if callback then callback(val) end
        saveConfig()
    end

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    return frame
end

--// GUI BUILD
newSection("CORE")
newSlider("GUI Transparency", "Transparency", 0, 0.9, true)
newButton("Low Performance Mode  :  " .. (CONFIG.LowPerf and "ON" or "OFF"), function(b)
    applyLowPerf(not CONFIG.LowPerf)
    b.Text = "Low Performance Mode  :  " .. (CONFIG.LowPerf and "ON" or "OFF")
    saveConfig()
end)

newSection("AUTO FISHING")
newToggle("Auto Fishing", "AutoFish")
newButton("Cast Power  :  " .. CONFIG.CastPower, function(b)
    local order = {"Weak","Meh","Good","Perfect","Instant"}
    local idx = table.find(order, CONFIG.CastPower) or 1
    CONFIG.CastPower = order[(idx % #order) + 1]
    b.Text = "Cast Power  :  " .. CONFIG.CastPower
    saveConfig()
end)
newSlider("Progress Speed (%)", "ProgressSpeed", 0, 2000, false)
newSlider("Bar Modifier", "BarModifier", 0.1, 2.0, true)
newSlider("Reel Delay", "ReelDelay", 0.1, 2.0, true)

newSection("AUTO SPEAR")
newToggle("Auto Spear", "AutoSpear")
newButton("Rarity Filter  :  " .. CONFIG.SpearRarity, function(b)
    local order = {"All","Common","Uncommon","Rare","Legendary","Mythic"}
    local idx = table.find(order, CONFIG.SpearRarity) or 1
    CONFIG.SpearRarity = order[(idx % #order) + 1]
    b.Text = "Rarity Filter  :  " .. CONFIG.SpearRarity
    saveConfig()
end)
newSlider("Spear Delay", "SpearDelay", 0.1, 3.0, true)

newSection("AUTO SELL")
newToggle("Auto Sell", "AutoSell")
newButton("Priority  :  " .. CONFIG.SellPriority, function(b)
    local order = {"Shady","Normal","Storage"}
    local idx = table.find(order, CONFIG.SellPriority) or 1
    CONFIG.SellPriority = order[(idx % #order) + 1]
    b.Text = "Priority  :  " .. CONFIG.SellPriority
    saveConfig()
end)

newSection("PRESET")
newButton("Save Preset", function()
    table.insert(PRESET_SLOTS, HttpService:JSONEncode(CONFIG))
    print("[AZZ] Preset saved:", #PRESET_SLOTS)
end)
newButton("Load Last Preset", function()
    local last = PRESET_SLOTS[#PRESET_SLOTS]
    if last then
        local d = HttpService:JSONDecode(last)
        for k, v in pairs(d) do CONFIG[k] = v end
        saveConfig()
        print("[AZZ] Preset loaded")
    end
end)

newSection("TRACKER")
local trackerLbl = Instance.new("TextLabel")
trackerLbl.Size = UDim2.new(1, 0, 0, 44)
trackerLbl.BackgroundTransparency = 1
trackerLbl.Text = "C$/h  :  0\nFish   :  0"
trackerLbl.Font = Enum.Font.Gotham
trackerLbl.TextSize = 11
trackerLbl.TextXAlignment = Enum.TextXAlignment.Left
trackerLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
trackerLbl.Parent = Scroll

task.spawn(function()
    while task.wait(2) do
        local hrs = (tick() - TRACKER.sessionStart) / 3600
        local rate = hrs > 0 and math.floor(TRACKER.totalC / hrs) or 0
        trackerLbl.Text = string.format("C$/h  :  %d\nFish   :  %d", rate, TRACKER.fishCount)
    end
end)

--// PANIC KEY
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == CONFIG.PanicKey then
        Main.Visible = not Main.Visible
    end
end)

--// AUTO FISHING LOOP
task.spawn(function()
    while task.wait(0.2) do
        if CONFIG.AutoFish then
            local jitter = CONFIG.Jitter and math.random(50, 250) / 1000 or 0
            task.wait(CONFIG.ReelDelay + jitter)
            -- TODO: hook remote Fisch
            TRACKER.fishCount += 1
        end
    end
end)

--// AUTO SPEAR LOOP
task.spawn(function()
    while task.wait(0.2) do
        if CONFIG.AutoSpear then
            task.wait(CONFIG.SpearDelay)
            -- TODO: scan fish + throw spear
        end
    end
end)

--// AUTO SELL LOOP
task.spawn(function()
    while task.wait(1) do
        if CONFIG.AutoSell then
            -- TODO: sell shady / storage
        end
    end
end)

--// AUTOSAVE
task.spawn(function()
    while task.wait(30) do saveConfig() end
end)

print("[AZZ HUB] Fisch Minimalist loaded. Panic key: RightShift")
