--[[
    AZZ HUB | Fisch Minimalist
    Theme : Monochrome (Black BG / White Accent)
    UI    : Lunor-Style (Title Bar + Minimize + Close)
]]

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

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
local MINIMIZED = false

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

-- Main Window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 440, 0, 540)
Main.Position = UDim2.new(0.5, -220, 0.5, -270)
Main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Main.BackgroundTransparency = CONFIG.Transparency
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 1
MainStroke.Transparency = 0.7
MainStroke.Parent = Main

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = Main

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TitleBar.BackgroundTransparency = CONFIG.Transparency
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local TitleStroke = Instance.new("UIStroke")
TitleStroke.Color = Color3.fromRGB(255, 255, 255)
TitleStroke.Thickness = 1
TitleStroke.Transparency = 0.7
TitleStroke.Parent = TitleBar

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

-- Title Text
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -100, 1, 0)
TitleLabel.Position = UDim2.new(0, 16, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "AZZ HUB  //  FISCH"
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 14
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Button Container (Top Right)
local BtnFrame = Instance.new("Frame")
BtnFrame.Size = UDim2.new(0, 80, 0, 40)
BtnFrame.Position = UDim2.new(1, -80, 0, 0)
BtnFrame.BackgroundTransparency = 1
BtnFrame.Parent = TitleBar

local BtnLayout = Instance.new("UIListLayout")
BtnLayout.FillDirection = Enum.FillDirection.Horizontal
BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
BtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
BtnLayout.Padding = UDim.new(0, 4)
BtnLayout.Parent = BtnFrame

-- Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MinimizeBtn.BackgroundTransparency = CONFIG.Transparency
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "—"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 14
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.AutoButtonColor = false
MinimizeBtn.Parent = BtnFrame

local MinStroke = Instance.new("UIStroke")
MinStroke.Color = Color3.fromRGB(255, 255, 255)
MinStroke.Thickness = 1
MinStroke.Transparency = 0.7
MinStroke.Parent = MinimizeBtn

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeBtn

MinimizeBtn.MouseEnter:Connect(function() MinimizeBtn.BackgroundTransparency = 0.3 end)
MinimizeBtn.MouseLeave:Connect(function() MinimizeBtn.BackgroundTransparency = CONFIG.Transparency end)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
CloseBtn.BackgroundTransparency = CONFIG.Transparency
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = BtnFrame

local CloseStroke = Instance.new("UIStroke")
CloseStroke.Color = Color3.fromRGB(255, 255, 255)
CloseStroke.Thickness = 1
CloseStroke.Transparency = 0.7
CloseStroke.Parent = CloseBtn

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseEnter:Connect(function() CloseBtn.BackgroundTransparency = 0.3 end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.BackgroundTransparency = CONFIG.Transparency end)

-- Content Container
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -40)
Content.Position = UDim2.new(0, 0, 0, 40)
Content.BackgroundTransparency = 1
Content.Parent = Main

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -16)
Scroll.Position = UDim2.new(0, 8, 0, 8)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Content

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 8)
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
    s.Transparency = 0.6
    s.Parent = btn

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn

    btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0.3 end)
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
    frame.Size = UDim2.new(1, 0, 0, 44)
    frame.BackgroundTransparency = 1
    frame.Parent = Scroll

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. "  :  " .. tostring(CONFIG[key])
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Parent = frame

    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, 0, 0, 16)
    bar.Position = UDim2.new(0, 0, 0, 22)
    bar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bar.BackgroundTransparency = CONFIG.Transparency
    bar.Text = ""
    bar.AutoButtonColor = false
    bar.Parent = frame

    local bs = Instance.new("UIStroke")
    bs.Color = Color3.fromRGB(255, 255, 255)
    bs.Thickness = 1
    bs.Transparency = 0.6
    bs.Parent = bar

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 4)
    bc.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((CONFIG[key] - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.BackgroundTransparency = 0.3
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 4)
    fc.Parent = fill

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

--// MINIMIZE / CLOSE LOGIC
local originalSize = Main.Size
local minimizedSize = UDim2.new(0, 440, 0, 40)

MinimizeBtn.MouseButton1Click:Connect(function()
    MINIMIZED = not MINIMIZED
    if MINIMIZED then
        Content.Visible = false
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = minimizedSize}):Play()
    else
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = originalSize}):Play()
        task.wait(0.25)
        Content.Visible = true
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

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

--// PANIC KEY (buka/tutup GUI)
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == CONFIG.PanicKey then
        Main.Visible = not Main.Visible
        if not Main.Visible then
            MINIMIZED = false
            Content.Visible = true
            Main.Size = originalSize
        end
    end
end)

--// AUTO FISHING LOOP
task.spawn(function()
    while task.wait(0.2) do
        if CONFIG.AutoFish then
            local jitter = CONFIG.Jitter and math.random(50, 250) / 1000 or 0
            task.wait(CONFIG.ReelDelay + jitter)
            TRACKER.fishCount += 1
        end
    end
end)

--// AUTO SPEAR LOOP
task.spawn(function()
    while task.wait(0.2) do
        if CONFIG.AutoSpear then
            task.wait(CONFIG.SpearDelay)
        end
    end
end)

--// AUTO SELL LOOP
task.spawn(function()
    while task.wait(1) do
        if CONFIG.AutoSell then
            -- TODO
        end
    end
end)

--// AUTOSAVE
task.spawn(function()
    while task.wait(30) do saveConfig() end
end)

print("[AZZ HUB] Loaded. Panic key: RightShift")
