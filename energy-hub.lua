--[[
    ⚡ HUB – стабильная версия с ESP и старым дизайном
    Фичи:
    - Полёт (скорость до 1000)
    - Бесконечный прыжок
    - Проход сквозь стены (Noclip)
    - Скорость ходьбы (до 1000)
    - Full Bright
    - ESP (рамки вокруг игроков)
    - Телепорт к игроку
    - Назначение горячих клавиш
    - Раздел "Настройки": автозагрузка, сброс конфига
    - Автосохранение / загрузка
    - Автоматическая разблокировка мыши при запуске и восстановление при закрытии
    - Старый дизайн (без ярких градиентов)

    Горячие клавиши по умолчанию:
    P – Полёт
    L – Бесконечный прыжок
    K – Ноклип
    B – Full Bright
    E – ESP
    M – Открыть/закрыть меню
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

-- ===== Уничтожение старых копий (только своих) =====
for _, gui in ipairs(playerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name == "HubGUI" then gui:Destroy() end
end
if _G.HubScript then _G.HubScript:Destroy() end
if _G.HubObjects then for _, o in ipairs(_G.HubObjects) do pcall(o.Destroy, o) end end
_G.HubObjects = {}
local Hub = {}; _G.HubScript = Hub

-- ===== РАЗБЛОКИРОВКА МЫШИ =====
local originalMouseBehavior = UserInputService.MouseBehavior
local originalMouseIcon = UserInputService.MouseIconEnabled
UserInputService.MouseBehavior = Enum.MouseBehavior.Default
UserInputService.MouseIconEnabled = true

-- ===== Конфигурация =====
local CONFIG_FILE = "hub_config.json"
local config = { autoload = true }

local function loadConfig()
    if writefile then
        local ok, data = pcall(readfile, CONFIG_FILE)
        if ok and data then
            local decoded = HttpService:JSONDecode(data)
            if decoded then config = decoded; return true end
        end
    end
    return false
end

local function saveConfig()
    if writefile then
        local data = HttpService:JSONEncode(config)
        pcall(writefile, CONFIG_FILE, data)
    end
end

loadConfig()
local autoload = config.autoload ~= false

-- Переменные состояний
local flyEnabled = config.fly or false
local flySpeed = config.flySpeed or 20
local jumpEnabled = config.jump or false
local noclipEnabled = config.noclip or false
local walkSpeedVal = config.walkSpeed or 16
local fullBrightEnabled = config.fullBright or false
local espEnabled = config.esp or false

local hotkeys = config.hotkeys or {
    fly = "P", jump = "L", noclip = "K", fullBright = "B", esp = "E", menu = "M"
}

-- ===== СОЗДАНИЕ GUI (старый дизайн) =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HubGUI"
ScreenGui.Parent = playerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.IgnoreGuiInset = true
table.insert(_G.HubObjects, ScreenGui)

-- Уведомление
local note = Instance.new("TextLabel")
note.Size = UDim2.new(0, 280, 0, 36)
note.Position = UDim2.new(1, -300, 0, 16)
note.BackgroundColor3 = Color3.fromRGB(20,20,25)
note.BackgroundTransparency = 0.3
note.TextColor3 = Color3.fromRGB(255,255,255)
note.Text = "Нажмите " .. hotkeys.menu .. " для меню"
note.TextScaled = true
note.Font = Enum.Font.SourceSans
note.BorderSizePixel = 0
note.ZIndex = 999
note.Parent = ScreenGui
local nCorner = Instance.new("UICorner"); nCorner.CornerRadius = UDim.new(0,8); nCorner.Parent = note
table.insert(_G.HubObjects, note)

local function showNote(duration)
    TweenService:Create(note, TweenInfo.new(0.3), {BackgroundTransparency=0.3, TextTransparency=0}):Play()
    task.wait(duration)
    TweenService:Create(note, TweenInfo.new(0.5), {BackgroundTransparency=1, TextTransparency=1}):Play()
end
coroutine.wrap(function() showNote(5) end)()

-- Главное окно + тень
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 440, 0, 620)
MainFrame.Position = UDim2.new(0.5, -220, 0.5, -310)
MainFrame.BackgroundColor3 = Color3.fromRGB(30,30,35)
MainFrame.BackgroundTransparency = 0.12
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 999
MainFrame.Parent = ScreenGui
local mCorner = Instance.new("UICorner"); mCorner.CornerRadius = UDim.new(0,14); mCorner.Parent = MainFrame

local shadow = Instance.new("Frame")
shadow.Size = MainFrame.Size + UDim2.new(0,4,0,4)
shadow.Position = MainFrame.Position - UDim2.new(0,2,0,2)
shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
shadow.BackgroundTransparency = 0.5
shadow.BorderSizePixel = 0
shadow.ZIndex = 998
shadow.Parent = ScreenGui
local sCorner = Instance.new("UICorner"); sCorner.CornerRadius = UDim.new(0,16); sCorner.Parent = shadow
table.insert(_G.HubObjects, shadow)
table.insert(_G.HubObjects, MainFrame)

-- Заголовок (простой)
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,44)
Title.BackgroundTransparency = 1
Title.Text = "⚡ HUB"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextScaled = true
Title.Font = Enum.Font.SourceSansBold
Title.ZIndex = 1000
Title.Parent = MainFrame
table.insert(_G.HubObjects, Title)

-- Перетаскивание
local drag = false; local offset = Vector2.new(0,0)
MainFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        drag = true; local pos = MainFrame.AbsolutePosition
        offset = Vector2.new(inp.Position.X - pos.X, inp.Position.Y - pos.Y)
    end
end)
MainFrame.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then drag = false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        MainFrame.Position = UDim2.new(0, inp.Position.X - offset.X, 0, inp.Position.Y - offset.Y)
        shadow.Position = MainFrame.Position - UDim2.new(0,2,0,2)
    end
end)

-- Скролл
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1,0,1,-44)
Scroll.Position = UDim2.new(0,0,0,44)
Scroll.BackgroundTransparency = 1
Scroll.CanvasSize = UDim2.new(0,0,0,0)
Scroll.ScrollBarThickness = 4
Scroll.ZIndex = 999
Scroll.Parent = MainFrame
table.insert(_G.HubObjects, Scroll)

local Layout = Instance.new("UIListLayout")
Layout.Parent = Scroll
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0,8)

local function updateCanvas()
    task.wait(0.05)
    Scroll.CanvasSize = UDim2.new(0,0,0, Layout.AbsoluteContentSize.Y + 20)
end
Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
coroutine.wrap(updateCanvas)()

-- ===== Вспомогательные функции для GUI =====
local toggleRefs = {}
local functionStates = {}
local hotkeyFunctions = {}
local waitingForKey = nil

local function createToggle(text, icon, funcName, defaultKey, callback)
    local state = functionStates[funcName] or false
    functionStates[funcName] = state

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,-12,0,52)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 999
    frame.Parent = Scroll
    table.insert(_G.HubObjects, frame)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = icon .. " " .. text
    label.TextColor3 = Color3.fromRGB(235,235,240)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true
    label.Font = Enum.Font.SourceSans
    label.ZIndex = 999
    label.Parent = frame
    table.insert(_G.HubObjects, label)

    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0,50,0,26)
    toggleBg.Position = UDim2.new(1,-56,0.5,-13)
    toggleBg.BackgroundColor3 = state and Color3.fromRGB(52,199,89) or Color3.fromRGB(130,130,140)
    toggleBg.BackgroundTransparency = 0.3
    toggleBg.BorderSizePixel = 0
    toggleBg.ZIndex = 999
    toggleBg.Parent = frame
    local bgCorner = Instance.new("UICorner"); bgCorner.CornerRadius = UDim.new(1,0); bgCorner.Parent = toggleBg
    table.insert(_G.HubObjects, toggleBg)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0,22,0,22)
    circle.Position = state and UDim2.new(0,26,0.5,-11) or UDim2.new(0,2,0.5,-11)
    circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    circle.BackgroundTransparency = 0.15
    circle.BorderSizePixel = 0
    circle.ZIndex = 999
    circle.Parent = toggleBg
    local circCorner = Instance.new("UICorner"); circCorner.CornerRadius = UDim.new(1,0); circCorner.Parent = circle
    table.insert(_G.HubObjects, circle)

    toggleRefs[funcName] = {bg = toggleBg, circle = circle}

    local function updateUI()
        if state then
            toggleBg.BackgroundColor3 = Color3.fromRGB(52,199,89)
            circle.Position = UDim2.new(0,26,0.5,-11)
        else
            toggleBg.BackgroundColor3 = Color3.fromRGB(130,130,140)
            circle.Position = UDim2.new(0,2,0.5,-11)
        end
    end
    updateUI()

    toggleBg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            state = not state
            functionStates[funcName] = state
            updateUI()
            callback(state)
            saveConfig()
        end
    end)

    local bottom = Instance.new("Frame")
    bottom.Size = UDim2.new(1,0,0,18)
    bottom.Position = UDim2.new(0,0,0,34)
    bottom.BackgroundTransparency = 1
    bottom.Parent = frame
    table.insert(_G.HubObjects, bottom)

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(0.5,0,1,0)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Text = "⌨ " .. (defaultKey or "None")
    keyLabel.TextColor3 = Color3.fromRGB(170,170,180)
    keyLabel.TextXAlignment = Enum.TextXAlignment.Left
    keyLabel.TextScaled = true
    keyLabel.Font = Enum.Font.SourceSans
    keyLabel.ZIndex = 999
    keyLabel.Parent = bottom
    table.insert(_G.HubObjects, keyLabel)

    local setBtn = Instance.new("TextButton")
    setBtn.Size = UDim2.new(0.35,0,1,0)
    setBtn.Position = UDim2.new(0.6,0,0,0)
    setBtn.BackgroundColor3 = Color3.fromRGB(50,55,70)
    setBtn.TextColor3 = Color3.fromRGB(255,255,255)
    setBtn.Text = "Назначить"
    setBtn.TextScaled = true
    setBtn.Font = Enum.Font.SourceSans
    setBtn.ZIndex = 999
    setBtn.Parent = bottom
    local btnCorner = Instance.new("UICorner"); btnCorner.CornerRadius = UDim.new(0,4); btnCorner.Parent = setBtn
    table.insert(_G.HubObjects, setBtn)

    setBtn.MouseButton1Click:Connect(function()
        waitingForKey = funcName
        keyLabel.Text = "⏳ Нажмите клавишу..."
    end)

    toggleRefs[funcName].keyLabel = keyLabel

    if defaultKey then
        local kc = Enum.KeyCode[defaultKey]
        if kc then
            for k,v in pairs(hotkeyFunctions) do if v == funcName then hotkeyFunctions[k]=nil end end
            hotkeyFunctions[kc] = funcName
        end
    end

    return frame
end

local function createSlider(text, icon, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,-12,0,52)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 999
    frame.Parent = Scroll
    table.insert(_G.HubObjects, frame)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5,0,0.5,0)
    label.BackgroundTransparency = 1
    label.Text = icon .. " " .. text
    label.TextColor3 = Color3.fromRGB(235,235,240)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true
    label.Font = Enum.Font.SourceSans
    label.ZIndex = 999
    label.Parent = frame
    table.insert(_G.HubObjects, label)

    local valBox = Instance.new("TextBox")
    valBox.Size = UDim2.new(0.3,0,0.5,0)
    valBox.Position = UDim2.new(0.7,0,0,0)
    valBox.BackgroundColor3 = Color3.fromRGB(45,45,55)
    valBox.TextColor3 = Color3.fromRGB(255,255,255)
    valBox.Text = tostring(default)
    valBox.TextScaled = true
    valBox.Font = Enum.Font.SourceSans
    valBox.ClearTextOnFocus = false
    valBox.ZIndex = 999
    valBox.Parent = frame
    local boxCorner = Instance.new("UICorner"); boxCorner.CornerRadius = UDim.new(0,4); boxCorner.Parent = valBox
    table.insert(_G.HubObjects, valBox)

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1,0,0.3,0)
    sliderBg.Position = UDim2.new(0,0,0.55,0)
    sliderBg.BackgroundColor3 = Color3.fromRGB(80,85,100)
    sliderBg.BackgroundTransparency = 0.4
    sliderBg.BorderSizePixel = 0
    sliderBg.ZIndex = 999
    sliderBg.Parent = frame
    local sCorner2 = Instance.new("UICorner"); sCorner2.CornerRadius = UDim.new(1,0); sCorner2.Parent = sliderBg
    table.insert(_G.HubObjects, sliderBg)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(52,199,89)
    fill.BackgroundTransparency = 0.2
    fill.BorderSizePixel = 0
    fill.ZIndex = 999
    fill.Parent = sliderBg
    local fCorner = Instance.new("UICorner"); fCorner.CornerRadius = UDim.new(1,0); fCorner.Parent = fill
    table.insert(_G.HubObjects, fill)

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0,14,0,14)
    handle.Position = UDim2.new((default-min)/(max-min), -7, 0.5, -7)
    handle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    handle.BackgroundTransparency = 0.2
    handle.BorderSizePixel = 0
    handle.ZIndex = 999
    handle.Parent = sliderBg
    local hCorner = Instance.new("UICorner"); hCorner.CornerRadius = UDim.new(1,0); hCorner.Parent = handle
    table.insert(_G.HubObjects, handle)

    local dragging = false
    local value = default

    local function updateSlider(val)
        value = math.clamp(val, min, max)
        local perc = (value - min) / (max - min)
        fill.Size = UDim2.new(perc,0,1,0)
        handle.Position = UDim2.new(perc, -7, 0.5, -7)
        valBox.Text = string.format("%.1f", value)
        callback(value)
        saveConfig()
    end

    valBox.FocusLost:Connect(function(enter)
        if enter then
            local num = tonumber(valBox.Text)
            if num then updateSlider(num) else valBox.Text = tostring(value) end
        end
    end)

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    handle.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    sliderBg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            local perc = math.clamp((inp.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            updateSlider(min + perc * (max - min))
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local pos = inp.Position.X
            local perc = math.clamp((pos - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            updateSlider(min + perc * (max - min))
        end
    end)

    return frame
end

-- ===== РАЗДЕЛЫ МЕНЮ =====

-- Основные функции
local h1 = Instance.new("TextLabel")
h1.Size = UDim2.new(1,-12,0,28)
h1.BackgroundTransparency = 1
h1.Text = "✦ Основные функции"
h1.TextColor3 = Color3.fromRGB(220,220,230)
h1.TextScaled = true
h1.Font = Enum.Font.SourceSansBold
h1.ZIndex = 999
h1.Parent = Scroll
table.insert(_G.HubObjects, h1)

createToggle("Полёт", "✈", "fly", hotkeys.fly, function(s) flyEnabled = s; config.fly = s end)
createSlider("Скорость полёта", "⏱", 0, 1000, flySpeed, function(v) flySpeed = v; config.flySpeed = v end)

createToggle("Бесконечный прыжок", "🦘", "jump", hotkeys.jump, function(s) jumpEnabled = s; config.jump = s end)
createToggle("Проход сквозь стены", "🚪", "noclip", hotkeys.noclip, function(s) noclipEnabled = s; config.noclip = s end)

createSlider("Скорость ходьбы", "🏃", 0, 1000, walkSpeedVal, function(v)
    walkSpeedVal = v; config.walkSpeed = v
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = v end
end)

createToggle("Full Bright", "☀", "fullBright", hotkeys.fullBright, function(s)
    fullBrightEnabled = s; config.fullBright = s
    if s then
        Lighting.Ambient = Color3.fromRGB(255,255,255)
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
    else
        Lighting.Ambient = Color3.fromRGB(127,127,127)
        Lighting.Brightness = 1
        Lighting.OutdoorAmbient = Color3.fromRGB(127,127,127)
    end
end)

-- ESP
createToggle("ESP (рамки)", "👁", "esp", hotkeys.esp, function(s)
    espEnabled = s; config.esp = s
end)

-- Телепорт
local h2 = Instance.new("TextLabel")
h2.Size = UDim2.new(1,-12,0,28)
h2.BackgroundTransparency = 1
h2.Text = "👥 Телепорт к игроку"
h2.TextColor3 = Color3.fromRGB(220,220,230)
h2.TextScaled = true
h2.Font = Enum.Font.SourceSansBold
h2.ZIndex = 999
h2.Parent = Scroll
table.insert(_G.HubObjects, h2)

local playerFrame = Instance.new("Frame")
playerFrame.Size = UDim2.new(1,-12,0,160)
playerFrame.BackgroundTransparency = 1
playerFrame.ZIndex = 999
playerFrame.Parent = Scroll
table.insert(_G.HubObjects, playerFrame)

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size = UDim2.new(1,0,1,0)
playerScroll.BackgroundTransparency = 1
playerScroll.CanvasSize = UDim2.new(0,0,0,0)
playerScroll.ScrollBarThickness = 4
playerScroll.ZIndex = 999
playerScroll.Parent = playerFrame
table.insert(_G.HubObjects, playerScroll)

local playerLayout = Instance.new("UIListLayout")
playerLayout.Parent = playerScroll
playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerLayout.Padding = UDim.new(0,4)

local function updatePlayerCanvas()
    task.wait(0.05)
    playerScroll.CanvasSize = UDim2.new(0,0,0, playerLayout.AbsoluteContentSize.Y + 10)
end
playerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatePlayerCanvas)

local function refreshPlayers()
    for _, child in ipairs(playerScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1,0,0,30)
            row.BackgroundColor3 = Color3.fromRGB(45,50,65)
            row.BackgroundTransparency = 0.5
            row.BorderSizePixel = 0
            row.ZIndex = 999
            row.Parent = playerScroll
            local rCorner = Instance.new("UICorner"); rCorner.CornerRadius = UDim.new(0,6); rCorner.Parent = row
            table.insert(_G.HubObjects, row)

            local name = Instance.new("TextLabel")
            name.Size = UDim2.new(0.5,0,1,0)
            name.BackgroundTransparency = 1
            name.Text = plr.Name
            name.TextColor3 = Color3.fromRGB(255,255,255)
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.TextScaled = true
            name.Font = Enum.Font.SourceSans
            name.ZIndex = 999
            name.Parent = row
            table.insert(_G.HubObjects, name)

            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0.35,0,0.8,0)
            tpBtn.Position = UDim2.new(0.6,0,0.1,0)
            tpBtn.BackgroundColor3 = Color3.fromRGB(52,152,219)
            tpBtn.TextColor3 = Color3.fromRGB(255,255,255)
            tpBtn.Text = "Телепорт"
            tpBtn.TextScaled = true
            tpBtn.Font = Enum.Font.SourceSans
            tpBtn.ZIndex = 999
            tpBtn.Parent = row
            local btnCorner2 = Instance.new("UICorner"); btnCorner2.CornerRadius = UDim.new(0,4); btnCorner2.Parent = tpBtn
            table.insert(_G.HubObjects, tpBtn)

            tpBtn.MouseButton1Click:Connect(function()
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local pos = plr.Character.HumanoidRootPart.Position
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
                    end
                end
            end)
        end
    end
    updatePlayerCanvas()
end

refreshPlayers()
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)

-- Настройки
local h3 = Instance.new("TextLabel")
h3.Size = UDim2.new(1,-12,0,28)
h3.BackgroundTransparency = 1
h3.Text = "⚙ Настройки"
h3.TextColor3 = Color3.fromRGB(220,220,230)
h3.TextScaled = true
h3.Font = Enum.Font.SourceSansBold
h3.ZIndex = 999
h3.Parent = Scroll
table.insert(_G.HubObjects, h3)

-- Автозагрузка
local autoLoadState = autoload
local autoFrame = Instance.new("Frame")
autoFrame.Size = UDim2.new(1,-12,0,40)
autoFrame.BackgroundTransparency = 1
autoFrame.ZIndex = 999
autoFrame.Parent = Scroll
table.insert(_G.HubObjects, autoFrame)

local autoLabel = Instance.new("TextLabel")
autoLabel.Size = UDim2.new(0.7,0,1,0)
autoLabel.BackgroundTransparency = 1
autoLabel.Text = "🔄 Автозагрузка при входе"
autoLabel.TextColor3 = Color3.fromRGB(235,235,240)
autoLabel.TextXAlignment = Enum.TextXAlignment.Left
autoLabel.TextScaled = true
autoLabel.Font = Enum.Font.SourceSans
autoLabel.ZIndex = 999
autoLabel.Parent = autoFrame
table.insert(_G.HubObjects, autoLabel)

local autoToggle = Instance.new("Frame")
autoToggle.Size = UDim2.new(0,50,0,26)
autoToggle.Position = UDim2.new(1,-56,0.5,-13)
autoToggle.BackgroundColor3 = autoLoadState and Color3.fromRGB(52,199,89) or Color3.fromRGB(130,130,140)
autoToggle.BackgroundTransparency = 0.3
autoToggle.BorderSizePixel = 0
autoToggle.ZIndex = 999
autoToggle.Parent = autoFrame
local atCorner = Instance.new("UICorner"); atCorner.CornerRadius = UDim.new(1,0); atCorner.Parent = autoToggle
table.insert(_G.HubObjects, autoToggle)

local autoCircle = Instance.new("Frame")
autoCircle.Size = UDim2.new(0,22,0,22)
autoCircle.Position = autoLoadState and UDim2.new(0,26,0.5,-11) or UDim2.new(0,2,0.5,-11)
autoCircle.BackgroundColor3 = Color3.fromRGB(255,255,255)
autoCircle.BackgroundTransparency = 0.15
autoCircle.BorderSizePixel = 0
autoCircle.ZIndex = 999
autoCircle.Parent = autoToggle
local acCorner = Instance.new("UICorner"); acCorner.CornerRadius = UDim.new(1,0); acCorner.Parent = autoCircle
table.insert(_G.HubObjects, autoCircle)

autoToggle.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        autoLoadState = not autoLoadState
        config.autoload = autoLoadState
        saveConfig()
        if autoLoadState then
            autoToggle.BackgroundColor3 = Color3.fromRGB(52,199,89)
            autoCircle.Position = UDim2.new(0,26,0.5,-11)
        else
            autoToggle.BackgroundColor3 = Color3.fromRGB(130,130,140)
            autoCircle.Position = UDim2.new(0,2,0.5,-11)
        end
    end
end)

-- Кнопка сброса
local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0.8,0,0,32)
resetBtn.Position = UDim2.new(0.1,0,0,0)
resetBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
resetBtn.TextColor3 = Color3.fromRGB(255,255,255)
resetBtn.Text = "🗑 Сбросить все настройки"
resetBtn.TextScaled = true
resetBtn.Font = Enum.Font.SourceSans
resetBtn.ZIndex = 999
resetBtn.Parent = Scroll
local resCorner = Instance.new("UICorner"); resCorner.CornerRadius = UDim.new(0,8); resCorner.Parent = resetBtn
table.insert(_G.HubObjects, resetBtn)

resetBtn.MouseButton1Click:Connect(function()
    config = {
        fly = false, flySpeed = 20,
        jump = false, noclip = false,
        walkSpeed = 16, fullBright = false,
        esp = false,
        autoload = true,
        hotkeys = { fly = "P", jump = "L", noclip = "K", fullBright = "B", esp = "E", menu = "M" }
    }
    saveConfig()
    -- Перезагружаем скрипт
    _G.HubScript:Destroy()
    -- Повторный запуск текущего скрипта (если в исполнителе)
    loadstring(game:HttpGet("rbxassetid://" .. scriptid))() -- можно заменить на свой способ
    -- Для простоты просто сообщим
    print("Настройки сброшены. Перезапустите скрипт.")
end)

-- ===== ЛОГИКА ФУНКЦИЙ =====

-- Полёт
local flyBV = nil
RunService.Heartbeat:Connect(function()
    if flyEnabled then
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum then return end

        local move = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0,0,-1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0,0,1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1,0,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1,0,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move + Vector3.new(0,-1,0) end

        if not flyBV or flyBV.Parent ~= hrp then
            flyBV = Instance.new("BodyVelocity")
            flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
            flyBV.Parent = hrp
            table.insert(_G.HubObjects, flyBV)
        end
        local cam = workspace.CurrentCamera
        if cam then
            local f, r, u = cam.CFrame.LookVector, cam.CFrame.RightVector, cam.CFrame.UpVector
            local vel = f * -move.Z + r * move.X + u * move.Y
            flyBV.Velocity = vel * flySpeed
        else
            flyBV.Velocity = move * flySpeed
        end
        hum.PlatformStand = true
    else
        if flyBV then flyBV:Destroy(); flyBV=nil end
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = false end
    end
end)

-- Бесконечный прыжок
UserInputService.InputBegan:Connect(function(inp, gp)
    if jumpEnabled and inp.KeyCode == Enum.KeyCode.Space and not gp then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.Velocity = Vector3.new(
                char.HumanoidRootPart.Velocity.X,
                60,
                char.HumanoidRootPart.Velocity.Z
            )
        end
    end
end)

-- Ноклип
RunService.Heartbeat:Connect(function()
    if noclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

-- Скорость ходьбы
local function applyWalk()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = walkSpeedVal
    end
end
LocalPlayer.CharacterAdded:Connect(applyWalk)
applyWalk()

-- Full Bright уже применён при создании

-- ESP
local espObjects = {}
RunService.Heartbeat:Connect(function()
    if espEnabled then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local char = plr.Character
                if char then
                    if not espObjects[plr] then
                        local box = Instance.new("BoxHandleAdornment")
                        box.Size = Vector3.new(4, 5, 1.5)
                        box.Adornee = char:FindFirstChild("HumanoidRootPart") or char
                        box.Color3 = Color3.fromRGB(255, 50, 50)
                        box.Transparency = 0.6
                        box.AlwaysOnTop = true
                        box.ZIndex = 10
                        box.Parent = char
                        espObjects[plr] = box
                        table.insert(_G.HubObjects, box)
                    end
                else
                    if espObjects[plr] then
                        espObjects[plr]:Destroy()
                        espObjects[plr] = nil
                    end
                end
            end
        end
        for plr, box in pairs(espObjects) do
            if not Players:FindFirstChild(plr.Name) then
                box:Destroy()
                espObjects[plr] = nil
            end
        end
    else
        for _, box in pairs(espObjects) do
            box:Destroy()
        end
        espObjects = {}
    end
end)

-- ===== ОБРАБОТЧИК ГОРЯЧИХ КЛАВИШ =====
UserInputService.InputBegan:Connect(function(inp, gp)
    local key = inp.KeyCode
    if key == Enum.KeyCode.Unknown then return end

    if waitingForKey then
        local funcName = waitingForKey
        waitingForKey = nil
        local keyStr = tostring(key):match("KeyCode%.(.*)")
        for k,v in pairs(hotkeyFunctions) do if v == funcName then hotkeyFunctions[k]=nil end end
        hotkeyFunctions[key] = funcName
        if funcName == "fly" then hotkeys.fly = keyStr
        elseif funcName == "jump" then hotkeys.jump = keyStr
        elseif funcName == "noclip" then hotkeys.noclip = keyStr
        elseif funcName == "fullBright" then hotkeys.fullBright = keyStr
        elseif funcName == "esp" then hotkeys.esp = keyStr
        elseif funcName == "menu" then hotkeys.menu = keyStr
        end
        config.hotkeys = hotkeys
        saveConfig()
        local ref = toggleRefs[funcName]
        if ref and ref.keyLabel then ref.keyLabel.Text = "⌨ " .. keyStr end
        return
    end

    if not gp then
        local funcName = hotkeyFunctions[key]
        if funcName then
            if funcName == "fly" then
                local state = not flyEnabled
                flyEnabled = state; config.fly = state
                local ref = toggleRefs["fly"]
                if ref then
                    functionStates["fly"] = state
                    if state then
                        ref.bg.BackgroundColor3 = Color3.fromRGB(52,199,89)
                        ref.circle.Position = UDim2.new(0,26,0.5,-11)
                    else
                        ref.bg.BackgroundColor3 = Color3.fromRGB(130,130,140)
                        ref.circle.Position = UDim2.new(0,2,0.5,-11)
                    end
                end
                saveConfig()
            elseif funcName == "jump" then
                jumpEnabled = not jumpEnabled; config.jump = jumpEnabled
                local ref = toggleRefs["jump"]
                if ref then
                    functionStates["jump"] = jumpEnabled
                    if jumpEnabled then
                        ref.bg.BackgroundColor3 = Color3.fromRGB(52,199,89)
                        ref.circle.Position = UDim2.new(0,26,0.5,-11)
                    else
                        ref.bg.BackgroundColor3 = Color3.fromRGB(130,130,140)
                        ref.circle.Position = UDim2.new(0,2,0.5,-11)
                    end
                end
                saveConfig()
            elseif funcName == "noclip" then
                noclipEnabled = not noclipEnabled; config.noclip = noclipEnabled
                local ref = toggleRefs["noclip"]
                if ref then
                    functionStates["noclip"] = noclipEnabled
                    if noclipEnabled then
                        ref.bg.BackgroundColor3 = Color3.fromRGB(52,199,89)
                        ref.circle.Position = UDim2.new(0,26,0.5,-11)
                    else
                        ref.bg.BackgroundColor3 = Color3.fromRGB(130,130,140)
                        ref.circle.Position = UDim2.new(0,2,0.5,-11)
                    end
                end
                saveConfig()
            elseif funcName == "fullBright" then
                fullBrightEnabled = not fullBrightEnabled; config.fullBright = fullBrightEnabled
                if fullBrightEnabled then
                    Lighting.Ambient = Color3.fromRGB(255,255,255)
                    Lighting.Brightness = 2
                    Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
                else
                    Lighting.Ambient = Color3.fromRGB(127,127,127)
                    Lighting.Brightness = 1
                    Lighting.OutdoorAmbient = Color3.fromRGB(127,127,127)
                end
                local ref = toggleRefs["fullBright"]
                if ref then
                    functionStates["fullBright"] = fullBrightEnabled
                    if fullBrightEnabled then
                        ref.bg.BackgroundColor3 = Color3.fromRGB(52,199,89)
                        ref.circle.Position = UDim2.new(0,26,0.5,-11)
                    else
                        ref.bg.BackgroundColor3 = Color3.fromRGB(130,130,140)
                        ref.circle.Position = UDim2.new(0,2,0.5,-11)
                    end
                end
                saveConfig()
            elseif funcName == "esp" then
                espEnabled = not espEnabled; config.esp = espEnabled
                local ref = toggleRefs["esp"]
                if ref then
                    functionStates["esp"] = espEnabled
                    if espEnabled then
                        ref.bg.BackgroundColor3 = Color3.fromRGB(52,199,89)
                        ref.circle.Position = UDim2.new(0,26,0.5,-11)
                    else
                        ref.bg.BackgroundColor3 = Color3.fromRGB(130,130,140)
                        ref.circle.Position = UDim2.new(0,2,0.5,-11)
                    end
                end
                saveConfig()
            end
            return
        end
    end

    if key == Enum.KeyCode[hotkeys.menu] then
        MainFrame.Visible = not MainFrame.Visible
        shadow.Visible = MainFrame.Visible
        coroutine.wrap(function() showNote(2) end)()
    end
end)

-- ===== ПРИМЕНЕНИЕ СОХРАНЁННЫХ СОСТОЯНИЙ =====
for funcName, state in pairs(functionStates) do
    if state then
        if funcName == "fly" then
            flyEnabled = true
            local ref = toggleRefs["fly"]
            if ref then ref.bg.BackgroundColor3 = Color3.fromRGB(52,199,89); ref.circle.Position = UDim2.new(0,26,0.5,-11) end
        elseif funcName == "jump" then
            jumpEnabled = true
            local ref = toggleRefs["jump"]
            if ref then ref.bg.BackgroundColor3 = Color3.fromRGB(52,199,89); ref.circle.Position = UDim2.new(0,26,0.5,-11) end
        elseif funcName == "noclip" then
            noclipEnabled = true
            local ref = toggleRefs["noclip"]
            if ref then ref.bg.BackgroundColor3 = Color3.fromRGB(52,199,89); ref.circle.Position = UDim2.new(0,26,0.5,-11) end
        elseif funcName == "fullBright" then
            fullBrightEnabled = true
            Lighting.Ambient = Color3.fromRGB(255,255,255)
            Lighting.Brightness = 2
            Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
            local ref = toggleRefs["fullBright"]
            if ref then ref.bg.BackgroundColor3 = Color3.fromRGB(52,199,89); ref.circle.Position = UDim2.new(0,26,0.5,-11) end
        elseif funcName == "esp" then
            espEnabled = true
            local ref = toggleRefs["esp"]
            if ref then ref.bg.BackgroundColor3 = Color3.fromRGB(52,199,89); ref.circle.Position = UDim2.new(0,26,0.5,-11) end
        end
    end
end

-- ===== ЗАКРЫТИЕ СКРИПТА (восстановление мыши) =====
function Hub:Destroy()
    UserInputService.MouseBehavior = originalMouseBehavior
    UserInputService.MouseIconEnabled = originalMouseIcon
    if _G.HubObjects then
        for _, obj in ipairs(_G.HubObjects) do
            pcall(obj.Destroy, obj)
        end
        _G.HubObjects = nil
    end
    if self.ScreenGui then pcall(self.ScreenGui.Destroy, self.ScreenGui) end
    _G.HubScript = nil
end

print("⚡ HUB загружен! Нажмите " .. hotkeys.menu .. " для меню. Мышь разблокирована.")
