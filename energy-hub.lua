--[[
    ⚡ Energy Hub (оптимизирован для телефона)
    Автоопределение платформы: размеры адаптируются под сенсорный экран.
    Функции: полёт, прыжок, ноклип, аимбот, ESP, невидимость, God Mode,
    телепорт к игроку. Назначение горячих клавиш.
    Сохранение в hub_config.json.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- ================= ОПРЕДЕЛЕНИЕ ПЛАТФОРМЫ =================
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
-- Настройки размеров для мобильной версии
local scale = isMobile and 1.4 or 1.0
local itemHeight = isMobile and 75 or 60
local toggleSize = isMobile and 60 or 50
local toggleHeight = isMobile and 34 or 28
local circleSize = isMobile and 30 or 24
local sliderHeight = isMobile and 70 or 55
local buttonHeight = isMobile and 35 or 25
local fontSize = isMobile and 20 or 16

-- ================= УНИЧТОЖЕНИЕ СТАРЫХ КОПИЙ =================
if _G.HubScript then
    _G.HubScript:Destroy()
    _G.HubScript = nil
end
if _G.HubObjects then
    for _, obj in ipairs(_G.HubObjects) do
        pcall(function() 
            if obj:IsA("RBXScriptConnection") then obj:Disconnect() 
            else obj:Destroy() end 
        end)
    end
    _G.HubObjects = nil
end
for _, gui in ipairs(playerGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name == "HubGUI" then
        gui:Destroy()
    end
end

local Hub = {}
_G.HubScript = Hub
_G.HubObjects = {}

-- ================= СИСТЕМА СОХРАНЕНИЯ =================
local configFileName = "hub_config.json"
local config = {}

local function loadConfig()
    if writefile then
        local success, data = pcall(function() return readfile(configFileName) end)
        if success and data then
            local decoded = HttpService:JSONDecode(data)
            if decoded then config = decoded return true end
        end
    end
    return false
end

local function saveConfig()
    if writefile then
        local data = HttpService:JSONEncode(config)
        pcall(function() writefile(configFileName, data) end)
    end
end

if not loadConfig() then
    config = {
        flyEnabled = false, flySpeed = 20,
        infiniteJumpEnabled = false, noclipEnabled = false,
        walkSpeed = 16,
        aimbotEnabled = false, espEnabled = false,
        invisibleEnabled = false, godModeEnabled = false,
    }
end

local flyEnabled = config.flyEnabled or false
local flySpeed = config.flySpeed or 20
local infiniteJumpEnabled = config.infiniteJumpEnabled or false
local noclipEnabled = config.noclipEnabled or false
local walkSpeedValue = config.walkSpeed or 16
local aimbotEnabled = config.aimbotEnabled or false
local espEnabled = config.espEnabled or false
local invisibleEnabled = config.invisibleEnabled or false
local godModeEnabled = config.godModeEnabled or false

-- ================= СОЗДАНИЕ GUI =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HubGUI"
ScreenGui.Parent = playerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.IgnoreGuiInset = true
Hub.ScreenGui = ScreenGui
table.insert(_G.HubObjects, ScreenGui)

-- Уведомление
local notification = Instance.new("TextLabel")
notification.Size = UDim2.new(0, 280 * (isMobile and 1.3 or 1), 0, 40 * scale)
notification.Position = UDim2.new(1, -300 * (isMobile and 1.3 or 1), 0, 20 * scale)
notification.BackgroundColor3 = Color3.fromRGB(20,20,20)
notification.BackgroundTransparency = 1
notification.TextColor3 = Color3.fromRGB(255,255,255)
notification.Text = "Нажмите M для открытия/закрытия меню"
notification.TextScaled = true
notification.Font = Enum.Font.SourceSans
notification.BorderSizePixel = 0
notification.ZIndex = 999
notification.Parent = ScreenGui
table.insert(_G.HubObjects, notification)
local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0,8)
notifCorner.Parent = notification
table.insert(_G.HubObjects, notifCorner)

local function showNotification(duration)
    TweenService:Create(notification, TweenInfo.new(0.3), {BackgroundTransparency=0.3, TextTransparency=0}):Play()
    task.wait(duration)
    TweenService:Create(notification, TweenInfo.new(0.5), {BackgroundTransparency=1, TextTransparency=1}):Play()
end
coroutine.wrap(function() showNotification(5) end)()

-- Главное окно
local mainSize = isMobile and 500 or 440
local mainHeight = isMobile and 780 or 680
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, mainSize, 0, mainHeight)
MainFrame.Position = UDim2.new(0.5, -mainSize/2, 0.5, -mainHeight/2)
MainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 999
MainFrame.Parent = ScreenGui
table.insert(_G.HubObjects, MainFrame)
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0,12)
UICorner.Parent = MainFrame
table.insert(_G.HubObjects, UICorner)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,40 * scale)
Title.BackgroundTransparency = 1
Title.Text = "⚡ Energy Hub"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextScaled = true
Title.Font = Enum.Font.SourceSansBold
Title.ZIndex = 1000
Title.Parent = MainFrame
table.insert(_G.HubObjects, Title)

-- Перетаскивание
local isDragging = false
local dragOffset = Vector2.new(0,0)
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        local framePos = MainFrame.AbsolutePosition
        dragOffset = Vector2.new(input.Position.X - framePos.X, input.Position.Y - framePos.Y)
    end
end)
MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)
local dragConnection = UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        MainFrame.Position = UDim2.new(0, input.Position.X - dragOffset.X, 0, input.Position.Y - dragOffset.Y)
    end
end)
table.insert(_G.HubObjects, dragConnection)

-- Скролл-контейнер
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1,0,1,-40 * scale)
ScrollFrame.Position = UDim2.new(0,0,0,40 * scale)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.CanvasSize = UDim2.new(0,0,0,0)
ScrollFrame.ScrollBarThickness = isMobile and 10 or 6
ScrollFrame.ZIndex = 999
ScrollFrame.Parent = MainFrame
table.insert(_G.HubObjects, ScrollFrame)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, isMobile and 12 or 8)
table.insert(_G.HubObjects, UIListLayout)

local function updateMainCanvas()
    task.wait(0.05)
    ScrollFrame.CanvasSize = UDim2.new(0,0,0, UIListLayout.AbsoluteContentSize.Y + 30 * scale)
end
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateMainCanvas)
coroutine.wrap(updateMainCanvas)()

-- ================= СИСТЕМА ГОРЯЧИХ КЛАВИШ =================
local hotkeyFunctions = {}
local functionStates = {}
local waitingForKey = nil
local toggleRefs = {}
local toggleCallbacks = {}

local function setHotkey(funcName, keyCode)
    for k,v in pairs(hotkeyFunctions) do if v == funcName then hotkeyFunctions[k]=nil end end
    if keyCode then
        if hotkeyFunctions[keyCode] then hotkeyFunctions[keyCode]=nil end
        hotkeyFunctions[keyCode] = funcName
    end
    local ref = toggleRefs[funcName]
    if ref and ref.keyLabel then
        if keyCode then ref.keyLabel.Text = "Клавиша: " .. tostring(keyCode):match("KeyCode%.(.*)")
        else ref.keyLabel.Text = "Клавиша: None" end
    end
end

local function toggleFunctionByName(funcName)
    if functionStates[funcName] == nil then return end
    functionStates[funcName] = not functionStates[funcName]
    local ref = toggleRefs[funcName]
    if ref then
        if functionStates[funcName] then
            ref.toggleFrame.BackgroundColor3 = Color3.fromRGB(50,200,50)
            ref.toggleCircle.Position = UDim2.new(0, toggleSize - circleSize + 2, 0.5, -circleSize/2)
        else
            ref.toggleFrame.BackgroundColor3 = Color3.fromRGB(120,120,120)
            ref.toggleCircle.Position = UDim2.new(0,2,0.5,-circleSize/2)
        end
    end
    if toggleCallbacks[funcName] then toggleCallbacks[funcName](functionStates[funcName]) end
    saveConfig()
end

-- ЕДИНЫЙ ОБРАБОТЧИК ВВОДА
local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    local key = input.KeyCode
    if key == Enum.KeyCode.Unknown then return end

    if waitingForKey then
        local funcName = waitingForKey
        if key == Enum.KeyCode.Escape then
            waitingForKey = nil
            local ref = toggleRefs[funcName]
            if ref and ref.keyLabel then
                local currentKey = nil
                for k,v in pairs(hotkeyFunctions) do if v == funcName then currentKey = k; break end end
                ref.keyLabel.Text = "Клавиша: " .. (currentKey and tostring(currentKey):match("KeyCode%.(.*)") or "None")
            end
        else
            waitingForKey = nil
            setHotkey(funcName, key)
        end
        return
    end

    if not gameProcessed then
        local funcName = hotkeyFunctions[key]
        if funcName then
            toggleFunctionByName(funcName)
            return
        end
    end

    if key == Enum.KeyCode.M then
        MainFrame.Visible = not MainFrame.Visible
        coroutine.wrap(function() showNotification(3) end)()
        return
    end

    if infiniteJumpEnabled and key == Enum.KeyCode.Space and not gameProcessed then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.Velocity = Vector3.new(char.HumanoidRootPart.Velocity.X, 60, char.HumanoidRootPart.Velocity.Z)
        end
    end
end)
table.insert(_G.HubObjects, inputConnection)

-- ================= ФУНКЦИИ СОЗДАНИЯ ЭЛЕМЕНТОВ (С АДАПТАЦИЕЙ ПОД ТЕЛЕФОН) =================
local function createToggleWithHotkey(labelText, funcName, defaultKey, callback)
    local state = functionStates[funcName] or false
    functionStates[funcName] = state
    toggleCallbacks[funcName] = callback

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,-10 * scale,0,itemHeight)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 999
    frame.Parent = ScrollFrame
    table.insert(_G.HubObjects, frame)

    local topFrame = Instance.new("Frame")
    topFrame.Size = UDim2.new(1,0,0,itemHeight - 30 * scale)
    topFrame.BackgroundTransparency = 1
    topFrame.Parent = frame
    table.insert(_G.HubObjects, topFrame)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true
    label.Font = Enum.Font.SourceSans
    label.ZIndex = 999
    label.Parent = topFrame
    table.insert(_G.HubObjects, label)

    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(0, toggleSize, 0, toggleHeight)
    toggleFrame.Position = UDim2.new(1, -(toggleSize + 5 * scale), 0.5, -toggleHeight/2)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(120,120,120)
    toggleFrame.BackgroundTransparency = 0.3
    toggleFrame.BorderSizePixel = 0
    toggleFrame.ZIndex = 999
    toggleFrame.Parent = topFrame
    table.insert(_G.HubObjects, toggleFrame)
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1,0)
    toggleCorner.Parent = toggleFrame
    table.insert(_G.HubObjects, toggleCorner)

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, circleSize, 0, circleSize)
    toggleCircle.Position = UDim2.new(0,2,0.5,-circleSize/2)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    toggleCircle.BackgroundTransparency = 0.2
    toggleCircle.BorderSizePixel = 0
    toggleCircle.ZIndex = 999
    toggleCircle.Parent = toggleFrame
    table.insert(_G.HubObjects, toggleCircle)
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1,0)
    circleCorner.Parent = toggleCircle
    table.insert(_G.HubObjects, circleCorner)

    toggleRefs[funcName] = {toggleFrame=toggleFrame, toggleCircle=toggleCircle}

    local function updateToggle()
        if state then
            toggleFrame.BackgroundColor3 = Color3.fromRGB(50,200,50)
            toggleCircle.Position = UDim2.new(0, toggleSize - circleSize + 2, 0.5, -circleSize/2)
        else
            toggleFrame.BackgroundColor3 = Color3.fromRGB(120,120,120)
            toggleCircle.Position = UDim2.new(0,2,0.5,-circleSize/2)
        end
    end
    updateToggle()

    toggleFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            state = not state
            functionStates[funcName] = state
            updateToggle()
            callback(state)
            saveConfig()
        end
    end)

    local bottomFrame = Instance.new("Frame")
    bottomFrame.Size = UDim2.new(1,0,0,30 * scale)
    bottomFrame.Position = UDim2.new(0,0,0,itemHeight - 30 * scale)
    bottomFrame.BackgroundTransparency = 1
    bottomFrame.Parent = frame
    table.insert(_G.HubObjects, bottomFrame)

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(0.5,0,1,0)
    keyLabel.BackgroundTransparency = 1
    keyLabel.Text = "Клавиша: " .. (defaultKey and tostring(defaultKey):match("KeyCode%.(.*)") or "None")
    keyLabel.TextColor3 = Color3.fromRGB(200,200,200)
    keyLabel.TextXAlignment = Enum.TextXAlignment.Left
    keyLabel.TextScaled = true
    keyLabel.Font = Enum.Font.SourceSans
    keyLabel.ZIndex = 999
    keyLabel.Parent = bottomFrame
    table.insert(_G.HubObjects, keyLabel)
    toggleRefs[funcName].keyLabel = keyLabel

    local setKeyButton = Instance.new("TextButton")
    setKeyButton.Size = UDim2.new(0.4,0,1,0)
    setKeyButton.Position = UDim2.new(0.55,0,0,0)
    setKeyButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    setKeyButton.TextColor3 = Color3.fromRGB(255,255,255)
    setKeyButton.Text = "Назначить"
    setKeyButton.TextScaled = true
    setKeyButton.Font = Enum.Font.SourceSans
    setKeyButton.ZIndex = 999
    setKeyButton.Parent = bottomFrame
    table.insert(_G.HubObjects, setKeyButton)
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0,4)
    btnCorner.Parent = setKeyButton
    table.insert(_G.HubObjects, btnCorner)

    setKeyButton.MouseButton1Click:Connect(function()
        waitingForKey = funcName
        keyLabel.Text = "Нажмите любую клавишу... (Escape - отмена)"
    end)

    if defaultKey then setHotkey(funcName, defaultKey) end
    return frame
end

local function createSlider(labelText, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,-10 * scale,0,sliderHeight)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 999
    frame.Parent = ScrollFrame
    table.insert(_G.HubObjects, frame)

    local topLine = Instance.new("Frame")
    topLine.Size = UDim2.new(1,0,0,25 * scale)
    topLine.BackgroundTransparency = 1
    topLine.Parent = frame
    table.insert(_G.HubObjects, topLine)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5,0,1,0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true
    label.Font = Enum.Font.SourceSans
    label.ZIndex = 999
    label.Parent = topLine
    table.insert(_G.HubObjects, label)

    local valueBox = Instance.new("TextBox")
    valueBox.Size = UDim2.new(0.25,0,1,0)
    valueBox.Position = UDim2.new(0.7,0,0,0)
    valueBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
    valueBox.TextColor3 = Color3.fromRGB(255,255,255)
    valueBox.Text = tostring(default)
    valueBox.TextScaled = true
    valueBox.Font = Enum.Font.SourceSans
    valueBox.ClearTextOnFocus = false
    valueBox.ZIndex = 999
    valueBox.Parent = topLine
    table.insert(_G.HubObjects, valueBox)
    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0,4)
    boxCorner.Parent = valueBox
    table.insert(_G.HubObjects, boxCorner)

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1,0,0.35 * scale,0)
    sliderFrame.Position = UDim2.new(0,0,0,30 * scale)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(100,100,100)
    sliderFrame.BackgroundTransparency = 0.4
    sliderFrame.BorderSizePixel = 0
    sliderFrame.ZIndex = 999
    sliderFrame.Parent = frame
    table.insert(_G.HubObjects, sliderFrame)
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1,0)
    sliderCorner.Parent = sliderFrame
    table.insert(_G.HubObjects, sliderCorner)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(50,200,50)
    fill.BackgroundTransparency = 0.2
    fill.BorderSizePixel = 0
    fill.ZIndex = 999
    fill.Parent = sliderFrame
    table.insert(_G.HubObjects, fill)
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1,0)
    fillCorner.Parent = fill
    table.insert(_G.HubObjects, fillCorner)

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, circleSize, 0, circleSize)
    handle.Position = UDim2.new((default-min)/(max-min), -circleSize/2, 0.5, -circleSize/2)
    handle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    handle.BackgroundTransparency = 0.2
    handle.BorderSizePixel = 0
    handle.ZIndex = 999
    handle.Parent = sliderFrame
    table.insert(_G.HubObjects, handle)
    local handleCorner = Instance.new("UICorner")
    handleCorner.CornerRadius = UDim.new(1,0)
    handleCorner.Parent = handle
    table.insert(_G.HubObjects, handleCorner)

    local dragging = false
    local value = default

    local function updateSlider(val)
        value = math.clamp(val, min, max)
        local percent = (value - min) / (max - min)
        fill.Size = UDim2.new(percent,0,1,0)
        handle.Position = UDim2.new(percent, -circleSize/2, 0.5, -circleSize/2)
        valueBox.Text = string.format("%.1f", value)
        callback(value)
        saveConfig()
    end

    valueBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local num = tonumber(valueBox.Text)
            if num then updateSlider(num) else valueBox.Text = tostring(value) end
        end
    end)

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local percent = math.clamp((input.Position.X - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
            updateSlider(min + percent * (max - min))
        end
    end)
    local sliderMoveConnection = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = input.Position.X
            local percent = math.clamp((pos - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
            updateSlider(min + percent * (max - min))
        end
    end)
    table.insert(_G.HubObjects, sliderMoveConnection)

    return frame
end

-- ================= СОЗДАНИЕ ПЕРЕКЛЮЧАТЕЛЕЙ =================
createToggleWithHotkey("Полёт", "Fly", Enum.KeyCode.P, function(state) flyEnabled = state end)
createSlider("Скорость полёта", 0, 1000, flySpeed, function(val) flySpeed = val end)

createToggleWithHotkey("Бесконечный прыжок", "InfiniteJump", Enum.KeyCode.L, function(state) infiniteJumpEnabled = state end)
createToggleWithHotkey("Проход сквозь стены", "Noclip", Enum.KeyCode.K, function(state) noclipEnabled = state end)

createSlider("Скорость ходьбы", 0, 1000, walkSpeedValue, function(val)
    walkSpeedValue = val
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = walkSpeedValue end
end)

createToggleWithHotkey("Аимбот", "Aimbot", Enum.KeyCode.J, function(state) aimbotEnabled = state end)
createToggleWithHotkey("ESP", "ESP", Enum.KeyCode.H, function(state) espEnabled = state end)

local function setInvisible(state)
    invisibleEnabled = state
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then humanoid.Visible = not state end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.Transparency = state and 1 or 0 end
    end
end
createToggleWithHotkey("Невидимость", "Invisible", Enum.KeyCode.Y, function(state) setInvisible(state) end)

local function setGodMode(state)
    godModeEnabled = state
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid and state then humanoid.Health = humanoid.MaxHealth end
    end
end
createToggleWithHotkey("God Mode", "GodMode", Enum.KeyCode.U, function(state) setGodMode(state) end)

-- ================= СПИСОК ИГРОКОВ (ТЕЛЕПОРТ) =================
local playerListFrame = Instance.new("Frame")
playerListFrame.Size = UDim2.new(1, -10 * scale, 0, isMobile and 280 or 200)
playerListFrame.BackgroundTransparency = 1
playerListFrame.ZIndex = 999
playerListFrame.Parent = ScrollFrame
table.insert(_G.HubObjects, playerListFrame)

local playerListLabel = Instance.new("TextLabel")
playerListLabel.Size = UDim2.new(1,0,0,30 * scale)
playerListLabel.BackgroundTransparency = 1
playerListLabel.Text = "👥 Игроки (Телепорт)"
playerListLabel.TextColor3 = Color3.fromRGB(255,255,255)
playerListLabel.TextScaled = true
playerListLabel.Font = Enum.Font.SourceSansBold
playerListLabel.ZIndex = 999
playerListLabel.Parent = playerListFrame
table.insert(_G.HubObjects, playerListLabel)

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size = UDim2.new(1,0,1,-30 * scale)
playerScroll.Position = UDim2.new(0,0,0,30 * scale)
playerScroll.BackgroundTransparency = 1
playerScroll.CanvasSize = UDim2.new(0,0,0,0)
playerScroll.ScrollBarThickness = isMobile and 10 or 6
playerScroll.ZIndex = 999
playerScroll.Parent = playerListFrame
table.insert(_G.HubObjects, playerScroll)

local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Parent = playerScroll
playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerListLayout.Padding = UDim.new(0, isMobile and 6 or 3)
table.insert(_G.HubObjects, playerListLayout)

local function updatePlayerCanvas()
    task.wait(0.05)
    playerScroll.CanvasSize = UDim2.new(0,0,0, playerListLayout.AbsoluteContentSize.Y + 10 * scale)
end
playerListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updatePlayerCanvas)

local function updatePlayerList()
    for _, child in ipairs(playerScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1,0,0, isMobile and 45 or 30)
            row.BackgroundColor3 = Color3.fromRGB(50,50,50)
            row.BackgroundTransparency = 0.5
            row.BorderSizePixel = 0
            row.ZIndex = 999
            row.Parent = playerScroll
            table.insert(_G.HubObjects, row)
            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0,4)
            rowCorner.Parent = row
            table.insert(_G.HubObjects, rowCorner)

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.5,0,1,0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextScaled = true
            nameLabel.Font = Enum.Font.SourceSans
            nameLabel.ZIndex = 999
            nameLabel.Parent = row
            table.insert(_G.HubObjects, nameLabel)

            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0.35,0,0.8,0)
            tpBtn.Position = UDim2.new(0.6,0,0.1,0)
            tpBtn.BackgroundColor3 = Color3.fromRGB(50,150,50)
            tpBtn.TextColor3 = Color3.fromRGB(255,255,255)
            tpBtn.Text = "Телепорт"
            tpBtn.TextScaled = true
            tpBtn.Font = Enum.Font.SourceSans
            tpBtn.ZIndex = 999
            tpBtn.Parent = row
            table.insert(_G.HubObjects, tpBtn)
            local tpCorner = Instance.new("UICorner")
            tpCorner.CornerRadius = UDim.new(0,4)
            tpCorner.Parent = tpBtn
            table.insert(_G.HubObjects, tpCorner)
            tpBtn.MouseButton1Click:Connect(function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local pos = player.Character.HumanoidRootPart.Position
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

updatePlayerList()
local playerAddedConn = Players.PlayerAdded:Connect(updatePlayerList)
local playerRemovedConn = Players.PlayerRemoving:Connect(updatePlayerList)
table.insert(_G.HubObjects, playerAddedConn)
table.insert(_G.HubObjects, playerRemovedConn)

-- ================= ЛОГИКА ФУНКЦИЙ =================
local flyBodyVelocity = nil
local espObjects = {}

-- Полёт
local flyConnection = RunService.Heartbeat:Connect(function()
    if flyEnabled then
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChild("Humanoid")
        if not hrp or not humanoid then return end

        local move = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0,0,-1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0,0,1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1,0,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1,0,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move + Vector3.new(0,-1,0) end

        if not flyBodyVelocity or flyBodyVelocity.Parent ~= hrp then
            flyBodyVelocity = Instance.new("BodyVelocity")
            flyBodyVelocity.MaxForce = Vector3.new(1e5,1e5,1e5)
            flyBodyVelocity.Parent = hrp
            table.insert(_G.HubObjects, flyBodyVelocity)
        end
        local camera = workspace.CurrentCamera
        if camera then
            local forward, right, up = camera.CFrame.LookVector, camera.CFrame.RightVector, camera.CFrame.UpVector
            local vel = forward * -move.Z + right * move.X + up * move.Y
            flyBodyVelocity.Velocity = vel * flySpeed
        else
            flyBodyVelocity.Velocity = move * flySpeed
        end
        humanoid.PlatformStand = true
    else
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = false end
    end
end)
table.insert(_G.HubObjects, flyConnection)

-- Ноклип
local noclipConnection = RunService.Heartbeat:Connect(function()
    if noclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)
table.insert(_G.HubObjects, noclipConnection)

-- Скорость ходьбы
local function applyWalkSpeed()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = walkSpeedValue end
end
local charAddedConn = LocalPlayer.CharacterAdded:Connect(applyWalkSpeed)
table.insert(_G.HubObjects, charAddedConn)
applyWalkSpeed()

-- Аимбот
local aimbotConnection = RunService.Heartbeat:Connect(function()
    if aimbotEnabled then
        local camera = workspace.CurrentCamera
        if not camera then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local closestDist = math.huge
        local closestHead = nil
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local targetChar = player.Character
                if targetChar then
                    local humanoid = targetChar:FindFirstChild("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local head = targetChar:FindFirstChild("Head")
                        if head then
                            local dist = (head.Position - hrp.Position).Magnitude
                            if dist < closestDist then
                                closestDist = dist; closestHead = head
                            end
                        end
                    end
                end
            end
        end
        if closestHead then
            camera.CFrame = CFrame.new(camera.CFrame.Position, closestHead.Position)
        end
    end
end)
table.insert(_G.HubObjects, aimbotConnection)

-- ESP
local espConnection = RunService.Heartbeat:Connect(function()
    if espEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local char = player.Character
                if char then
                    if not espObjects[player] then
                        local box = Instance.new("BoxHandleAdornment")
                        box.Size = Vector3.new(4,5,1.5)
                        box.Adornee = char:FindFirstChild("HumanoidRootPart") or char
                        box.Color3 = Color3.fromRGB(255,50,50)
                        box.Transparency = 0.6
                        box.AlwaysOnTop = true
                        box.ZIndex = 10
                        box.Parent = char
                        espObjects[player] = box
                        table.insert(_G.HubObjects, box)
                    end
                else
                    if espObjects[player] then
                        espObjects[player]:Destroy()
                        espObjects[player] = nil
                    end
                end
            end
        end
        for player, box in pairs(espObjects) do
            if not Players:FindFirstChild(player.Name) then
                box:Destroy()
                espObjects[player] = nil
            end
        end
    else
        for _, box in pairs(espObjects) do
            box:Destroy()
        end
        espObjects = {}
    end
end)
table.insert(_G.HubObjects, espConnection)

-- God Mode
local godModeConnection = RunService.Heartbeat:Connect(function()
    if godModeEnabled then
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then humanoid.Health = humanoid.MaxHealth end
        end
    end
end)
table.insert(_G.HubObjects, godModeConnection)

local godCharAddedConn = LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if godModeEnabled then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then humanoid.Health = humanoid.MaxHealth end
    end
    applyWalkSpeed()
end)
table.insert(_G.HubObjects, godCharAddedConn)

-- ================= ПРИМЕНЕНИЕ СОХРАНЁННЫХ СОСТОЯНИЙ =================
for funcName, state in pairs(functionStates) do
    if state then toggleFunctionByName(funcName) end
end

-- ================= МЕТОД УНИЧТОЖЕНИЯ =================
function Hub:Destroy()
    if _G.HubObjects then
        for _, obj in ipairs(_G.HubObjects) do
            pcall(function() 
                if obj:IsA("RBXScriptConnection") then obj:Disconnect() 
                else obj:Destroy() end 
            end)
        end
        _G.HubObjects = nil
    end
    if self.ScreenGui then pcall(function() self.ScreenGui:Destroy() end) end
    _G.HubScript = nil
end

print("Energy Hub загружен! M – меню. Определена платформа: " .. (isMobile and "Телефон" or "ПК") .. ". Элементы адаптированы.")
