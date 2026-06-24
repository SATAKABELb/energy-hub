--[[
    ⚡ Energy Hub (исправленное изменение размера с HipHeight)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Удаление старых копий
if _G.HubScript then _G.HubScript:Destroy() _G.HubScript=nil end
if _G.HubObjects then for _,o in ipairs(_G.HubObjects) do pcall(function() if o:IsA("RBXScriptConnection") then o:Disconnect() else o:Destroy() end end) end _G.HubObjects=nil end
for _,g in ipairs(playerGui:GetChildren()) do if g:IsA("ScreenGui") and g.Name=="HubGUI" then g:Destroy() end end

local Hub = {} _G.HubScript = Hub _G.HubObjects = {}

-- Конфиг
local cfgFile = "hub_config.json"
local cfg = {}
local function loadCfg()
    if writefile then local s,d=pcall(readfile,cfgFile) if s and d then local dec=HttpService:JSONDecode(d) if dec then cfg=dec return true end end end return false end
local function saveCfg() if writefile then pcall(function() writefile(cfgFile, HttpService:JSONEncode(cfg)) end) end end
if not loadCfg() then cfg={fly=false,flySpd=20,jump=false,noclip=false,walk=16,aim=false,esp=false,inv=false,god=false,scale=1,pos={x=0.5,y=0.5}} end
local fly=cfg.fly or false
local flySpd=cfg.flySpd or 20
local jump=cfg.jump or false
local noclip=cfg.noclip or false
local walk=cfg.walk or 16
local aim=cfg.aim or false
local esp=cfg.esp or false
local inv=cfg.inv or false
local god=cfg.god or false
local charScale=cfg.scale or 1
local savedPos=cfg.pos or {x=0.5,y=0.5}

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local scale = isMobile and 1.3 or 1.0
local ih = isMobile and 65 or 50
local tw = isMobile and 56 or 46
local th = isMobile and 32 or 26
local cs = isMobile and 28 or 22
local sh = isMobile and 65 or 50

-- ================= ФУНКЦИЯ ИЗМЕНЕНИЯ РАЗМЕРА (С HipHeight) =================
local originalData = {} -- key = character, value = {parts = {}, hipHeight = 0}

local function applyScale(character, newScale)
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    -- Если масштаб == 1, сбрасываем до исходного
    if newScale == 1 then
        local data = originalData[character]
        if data then
            for part, origSize in pairs(data.parts) do
                if part and part.Parent then
                    part.Size = origSize
                    part.CFrame = data.origCFrames[part]
                end
            end
            humanoid.HipHeight = data.hipHeight
            originalData[character] = nil
        end
        return
    end

    -- Сохраняем исходные данные при первом применении
    if not originalData[character] then
        local data = {parts = {}, origCFrames = {}, hipHeight = humanoid.HipHeight}
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part ~= rootPart then
                data.parts[part] = part.Size
                data.origCFrames[part] = part.CFrame
            end
        end
        originalData[character] = data
    end

    local data = originalData[character]
    local rootPos = rootPart.Position

    -- Применяем масштаб
    for part, origSize in pairs(data.parts) do
        if part and part.Parent then
            -- Масштабируем размер
            part.Size = origSize * newScale
            -- Масштабируем позицию относительно корня
            local origCFrame = data.origCFrames[part]
            if origCFrame then
                local relPos = origCFrame.Position - rootPos
                local newPos = rootPos + relPos * newScale
                local newCFrame = CFrame.new(newPos) * (origCFrame - origCFrame.Position)
                part.CFrame = newCFrame
            end
        end
    end

    -- Корректируем HipHeight, чтобы персонаж стоял на земле
    humanoid.HipHeight = data.hipHeight * newScale
end

-- Применяем сохранённый масштаб при загрузке
local function applySavedScale(character)
    if character and charScale and charScale ~= 1 then
        task.wait(0.1)
        applyScale(character, charScale)
    end
end

-- ================= GUI =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HubGUI"
ScreenGui.Parent = playerGui
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.IgnoreGuiInset = true
Hub.ScreenGui = ScreenGui
table.insert(_G.HubObjects, ScreenGui)

-- Уведомление
local notif = Instance.new("TextLabel")
notif.Size = UDim2.new(0,280*scale,0,40*scale)
notif.Position = UDim2.new(1,-300*scale,0,20*scale)
notif.BackgroundColor3 = Color3.fromRGB(20,20,20)
notif.BackgroundTransparency = 1
notif.TextColor3 = Color3.fromRGB(255,255,255)
notif.Text = "Нажмите M для меню"
notif.TextScaled = true
notif.Font = Enum.Font.SourceSans
notif.BorderSizePixel = 0
notif.ZIndex = 999
notif.Parent = ScreenGui
table.insert(_G.HubObjects, notif)
local nc = Instance.new("UICorner")
nc.CornerRadius = UDim.new(0,8)
nc.Parent = notif
table.insert(_G.HubObjects, nc)

local function showNotif(d)
    TweenService:Create(notif, TweenInfo.new(0.3), {BackgroundTransparency=0.3,TextTransparency=0}):Play()
    task.wait(d)
    TweenService:Create(notif, TweenInfo.new(0.5), {BackgroundTransparency=1,TextTransparency=1}):Play()
end
coroutine.wrap(function() showNotif(5) end)()

-- Главное окно
local mainW = isMobile and 500 or 440
local mainH = isMobile and 600 or 520
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0,mainW,0,mainH)
MainFrame.Position = UDim2.new(savedPos.x, -mainW/2, savedPos.y, -mainH/2)
MainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 999
MainFrame.Parent = ScreenGui
table.insert(_G.HubObjects, MainFrame)
local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0,12)
mc.Parent = MainFrame
table.insert(_G.HubObjects, mc)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1,0,0,40*scale)
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
MainFrame.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        local fp = MainFrame.AbsolutePosition
        dragOffset = Vector2.new(i.Position.X - fp.X, i.Position.Y - fp.Y)
    end
end)
MainFrame.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
        local pos = MainFrame.Position
        cfg.pos = {x = pos.X.Scale, y = pos.Y.Scale}
        saveCfg()
    end
end)
local dragConn = UserInputService.InputChanged:Connect(function(i)
    if isDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        MainFrame.Position = UDim2.new(0, i.Position.X - dragOffset.X, 0, i.Position.Y - dragOffset.Y)
    end
end)
table.insert(_G.HubObjects, dragConn)

-- Вкладки
local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(1,0,0,36*scale)
tabFrame.Position = UDim2.new(0,0,0,40*scale)
tabFrame.BackgroundTransparency = 1
tabFrame.Parent = MainFrame
table.insert(_G.HubObjects, tabFrame)

local function createTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.33,0,1,0)
    btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.Text = name
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSans
    btn.ZIndex = 999
    btn.Parent = tabFrame
    table.insert(_G.HubObjects, btn)
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0,4)
    bc.Parent = btn
    table.insert(_G.HubObjects, bc)
    return btn
end

local tabMain = createTab("Основные")
local tabBattle = createTab("Боевые")
local tabPlayers = createTab("Игроки")
tabMain.Position = UDim2.new(0,0,0,0)
tabBattle.Position = UDim2.new(0.33,0,0,0)
tabPlayers.Position = UDim2.new(0.66,0,0,0)

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1,0,1,-76*scale)
ScrollFrame.Position = UDim2.new(0,0,0,76*scale)
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
    ScrollFrame.CanvasSize = UDim2.new(0,0,0, UIListLayout.AbsoluteContentSize.Y + 30*scale)
end
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateMainCanvas)
coroutine.wrap(updateMainCanvas)()

-- ================= СИСТЕМА КЛАВИШ =================
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
            ref.toggleCircle.Position = UDim2.new(0, tw - cs + 2, 0.5, -cs/2)
        else
            ref.toggleFrame.BackgroundColor3 = Color3.fromRGB(120,120,120)
            ref.toggleCircle.Position = UDim2.new(0,2,0.5,-cs/2)
        end
    end
    if toggleCallbacks[funcName] then toggleCallbacks[funcName](functionStates[funcName]) end
    saveCfg()
end

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
        coroutine.wrap(function() showNotif(3) end)()
        return
    end

    if jump and key == Enum.KeyCode.Space and not gameProcessed then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.Velocity = Vector3.new(char.HumanoidRootPart.Velocity.X, 60, char.HumanoidRootPart.Velocity.Z)
        end
    end
end)
table.insert(_G.HubObjects, inputConnection)

-- ================= ВИДЖЕТЫ =================
local function createToggle(text, funcName, defaultKey, callback)
    local state = functionStates[funcName] or false
    functionStates[funcName] = state
    toggleCallbacks[funcName] = callback

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,-10*scale,0,ih)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 999
    frame.Parent = ScrollFrame
    table.insert(_G.HubObjects, frame)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1,0,0,ih-30*scale)
    top.BackgroundTransparency = 1
    top.Parent = frame
    table.insert(_G.HubObjects, top)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.55,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextScaled = true
    lbl.Font = Enum.Font.SourceSans
    lbl.ZIndex = 999
    lbl.Parent = top
    table.insert(_G.HubObjects, lbl)

    local togFr = Instance.new("Frame")
    togFr.Size = UDim2.new(0,tw,0,th)
    togFr.Position = UDim2.new(1,-tw-5*scale,0.5,-th/2)
    togFr.BackgroundColor3 = Color3.fromRGB(120,120,120)
    togFr.BackgroundTransparency = 0.3
    togFr.BorderSizePixel = 0
    togFr.ZIndex = 999
    togFr.Parent = top
    table.insert(_G.HubObjects, togFr)
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(1,0)
    tc.Parent = togFr
    table.insert(_G.HubObjects, tc)

    local togCi = Instance.new("Frame")
    togCi.Size = UDim2.new(0,cs,0,cs)
    togCi.Position = UDim2.new(0,2,0.5,-cs/2)
    togCi.BackgroundColor3 = Color3.fromRGB(255,255,255)
    togCi.BackgroundTransparency = 0.2
    togCi.BorderSizePixel = 0
    togCi.ZIndex = 999
    togCi.Parent = togFr
    table.insert(_G.HubObjects, togCi)
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(1,0)
    cc.Parent = togCi
    table.insert(_G.HubObjects, cc)

    toggleRefs[funcName] = {toggleFrame = togFr, toggleCircle = togCi}

    local function updateToggle()
        if state then
            togFr.BackgroundColor3 = Color3.fromRGB(50,200,50)
            togCi.Position = UDim2.new(0, tw - cs + 2, 0.5, -cs/2)
        else
            togFr.BackgroundColor3 = Color3.fromRGB(120,120,120)
            togCi.Position = UDim2.new(0,2,0.5,-cs/2)
        end
    end
    updateToggle()

    togFr.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            state = not state
            functionStates[funcName] = state
            updateToggle()
            callback(state)
            saveCfg()
        end
    end)

    local bot = Instance.new("Frame")
    bot.Size = UDim2.new(1,0,0,30*scale)
    bot.Position = UDim2.new(0,0,0,ih-30*scale)
    bot.BackgroundTransparency = 1
    bot.Parent = frame
    table.insert(_G.HubObjects, bot)

    local keyLbl = Instance.new("TextLabel")
    keyLbl.Size = UDim2.new(0.5,0,1,0)
    keyLbl.BackgroundTransparency = 1
    keyLbl.Text = "Клавиша: " .. (defaultKey and tostring(defaultKey):match("KeyCode%.(.*)") or "None")
    keyLbl.TextColor3 = Color3.fromRGB(200,200,200)
    keyLbl.TextXAlignment = Enum.TextXAlignment.Left
    keyLbl.TextScaled = true
    keyLbl.Font = Enum.Font.SourceSans
    keyLbl.ZIndex = 999
    keyLbl.Parent = bot
    table.insert(_G.HubObjects, keyLbl)
    toggleRefs[funcName].keyLabel = keyLbl

    local setBtn = Instance.new("TextButton")
    setBtn.Size = UDim2.new(0.4,0,1,0)
    setBtn.Position = UDim2.new(0.55,0,0,0)
    setBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    setBtn.TextColor3 = Color3.fromRGB(255,255,255)
    setBtn.Text = "Назначить"
    setBtn.TextScaled = true
    setBtn.Font = Enum.Font.SourceSans
    setBtn.ZIndex = 999
    setBtn.Parent = bot
    table.insert(_G.HubObjects, setBtn)
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0,4)
    bc.Parent = setBtn
    table.insert(_G.HubObjects, bc)

    setBtn.MouseButton1Click:Connect(function()
        waitingForKey = funcName
        keyLbl.Text = "Нажмите любую клавишу... (Escape - отмена)"
    end)

    if defaultKey then setHotkey(funcName, defaultKey) end
    return frame
end

local function createSlider(text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,-10*scale,0,sh)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 999
    frame.Parent = ScrollFrame
    table.insert(_G.HubObjects, frame)

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1,0,0,25*scale)
    top.BackgroundTransparency = 1
    top.Parent = frame
    table.insert(_G.HubObjects, top)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.5,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextScaled = true
    lbl.Font = Enum.Font.SourceSans
    lbl.ZIndex = 999
    lbl.Parent = top
    table.insert(_G.HubObjects, lbl)

    local valBox = Instance.new("TextBox")
    valBox.Size = UDim2.new(0.25,0,1,0)
    valBox.Position = UDim2.new(0.7,0,0,0)
    valBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
    valBox.TextColor3 = Color3.fromRGB(255,255,255)
    valBox.Text = tostring(default)
    valBox.TextScaled = true
    valBox.Font = Enum.Font.SourceSans
    valBox.ClearTextOnFocus = false
    valBox.ZIndex = 999
    valBox.Parent = top
    table.insert(_G.HubObjects, valBox)
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0,4)
    bc.Parent = valBox
    table.insert(_G.HubObjects, bc)

    local slFr = Instance.new("Frame")
    slFr.Size = UDim2.new(1,0,0.35*scale,0)
    slFr.Position = UDim2.new(0,0,0,30*scale)
    slFr.BackgroundColor3 = Color3.fromRGB(100,100,100)
    slFr.BackgroundTransparency = 0.4
    slFr.BorderSizePixel = 0
    slFr.ZIndex = 999
    slFr.Parent = frame
    table.insert(_G.HubObjects, slFr)
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(1,0)
    sc.Parent = slFr
    table.insert(_G.HubObjects, sc)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(50,200,50)
    fill.BackgroundTransparency = 0.2
    fill.BorderSizePixel = 0
    fill.ZIndex = 999
    fill.Parent = slFr
    table.insert(_G.HubObjects, fill)
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1,0)
    fc.Parent = fill
    table.insert(_G.HubObjects, fc)

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0,cs,0,cs)
    handle.Position = UDim2.new((default-min)/(max-min), -cs/2, 0.5, -cs/2)
    handle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    handle.BackgroundTransparency = 0.2
    handle.BorderSizePixel = 0
    handle.ZIndex = 999
    handle.Parent = slFr
    table.insert(_G.HubObjects, handle)
    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(1,0)
    hc.Parent = handle
    table.insert(_G.HubObjects, hc)

    local dragging = false
    local value = default

    local function updateSlider(val)
        value = math.clamp(val, min, max)
        local percent = (value - min) / (max - min)
        fill.Size = UDim2.new(percent,0,1,0)
        handle.Position = UDim2.new(percent, -cs/2, 0.5, -cs/2)
        valBox.Text = string.format("%.2f", value)
        callback(value)
        saveCfg()
    end

    valBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local num = tonumber(valBox.Text)
            if num then updateSlider(num) else valBox.Text = tostring(value) end
        end
    end)

    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    slFr.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            local percent = math.clamp((i.Position.X - slFr.AbsolutePosition.X) / slFr.AbsoluteSize.X, 0, 1)
            updateSlider(min + percent * (max - min))
        end
    end)
    local sliderMove = UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local percent = math.clamp((i.Position.X - slFr.AbsolutePosition.X) / slFr.AbsoluteSize.X, 0, 1)
            updateSlider(min + percent * (max - min))
        end
    end)
    table.insert(_G.HubObjects, sliderMove)

    return frame
end

-- ================= КОНТЕЙНЕРЫ ВКЛАДОК =================
local function createTabContainer()
    local cont = Instance.new("Frame")
    cont.Size = UDim2.new(1,0,1,0)
    cont.BackgroundTransparency = 1
    cont.ZIndex = 999
    cont.Parent = ScrollFrame
    table.insert(_G.HubObjects, cont)
    local lay = Instance.new("UIListLayout")
    lay.Parent = cont
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0, isMobile and 12 or 8)
    table.insert(_G.HubObjects, lay)
    local function updateCont()
        task.wait(0.05)
        cont.Size = UDim2.new(1,0,0, lay.AbsoluteContentSize.Y + 20*scale)
    end
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCont)
    coroutine.wrap(updateCont)()
    local tag = Instance.new("StringValue")
    tag.Name = "TabName"
    tag.Parent = cont
    table.insert(_G.HubObjects, tag)
    return cont
end

local contMain = createTabContainer()
local contBattle = createTabContainer()
local contPlayers = createTabContainer()
contMain.TabName.Value = "Основные"
contBattle.TabName.Value = "Боевые"
contPlayers.TabName.Value = "Игроки"

local function showTab(name)
    for _, ch in ipairs(ScrollFrame:GetChildren()) do
        if ch:IsA("Frame") and ch:FindFirstChild("TabName") then
            ch.Visible = (ch.TabName.Value == name)
        end
    end
    updateMainCanvas()
    for _, btn in ipairs(tabFrame:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.BackgroundColor3 = (btn.Text == name) and Color3.fromRGB(80,80,80) or Color3.fromRGB(60,60,60)
        end
    end
end

tabMain.MouseButton1Click:Connect(function() showTab("Основные") end)
tabBattle.MouseButton1Click:Connect(function() showTab("Боевые") end)
tabPlayers.MouseButton1Click:Connect(function() showTab("Игроки") end)

-- ================= ЗАПОЛНЕНИЕ ВКЛАДОК =================
local function addMain(item) item.Parent = contMain end
local function addBattle(item) item.Parent = contBattle end

addMain(createToggle("Полёт", "Fly", Enum.KeyCode.P, function(s) fly = s end))
addMain(createSlider("Скорость полёта", 0, 1000, flySpd, function(v) flySpd = v end))
addMain(createToggle("Бесконечный прыжок", "Jump", Enum.KeyCode.L, function(s) jump = s end))
addMain(createToggle("Проход сквозь стены", "Noclip", Enum.KeyCode.K, function(s) noclip = s end))
addMain(createSlider("Скорость ходьбы", 0, 1000, walk, function(v)
    walk = v
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = walk end
end))

-- ИЗМЕНЕНИЕ РАЗМЕРА (ИСПРАВЛЕННО)
addMain(createSlider("Размер персонажа", 0.5, 3.0, charScale, function(v)
    charScale = v
    cfg.scale = v
    saveCfg()
    local char = LocalPlayer.Character
    if char then
        applyScale(char, v)
    end
end))

addBattle(createToggle("Аимбот", "Aim", Enum.KeyCode.J, function(s) aim = s end))
addBattle(createToggle("ESP", "ESP", Enum.KeyCode.H, function(s) esp = s end))
addBattle(createToggle("Невидимость", "Inv", Enum.KeyCode.Y, function(s)
    inv = s
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then humanoid.Visible = not s end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = s and 1 or 0
        end
    end
end))
addBattle(createToggle("God Mode", "God", Enum.KeyCode.U, function(s)
    god = s
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") and s then
        char.Humanoid.Health = char.Humanoid.MaxHealth
    end
end))

-- Игроки
local function updatePlayers()
    for _, ch in ipairs(contPlayers:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1,0,0,30*scale)
    header.BackgroundTransparency = 1
    header.Text = "👥 Игроки (Телепорт)"
    header.TextColor3 = Color3.fromRGB(255,255,255)
    header.TextScaled = true
    header.Font = Enum.Font.SourceSansBold
    header.Parent = contPlayers
    table.insert(_G.HubObjects, header)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1,0,0,isMobile and 45 or 30)
            row.BackgroundColor3 = Color3.fromRGB(50,50,50)
            row.BackgroundTransparency = 0.5
            row.BorderSizePixel = 0
            row.ZIndex = 999
            row.Parent = contPlayers
            table.insert(_G.HubObjects, row)
            local rc = Instance.new("UICorner")
            rc.CornerRadius = UDim.new(0,4)
            rc.Parent = row
            table.insert(_G.HubObjects, rc)

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Size = UDim2.new(0.5,0,1,0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = player.Name
            nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextScaled = true
            nameLbl.Font = Enum.Font.SourceSans
            nameLbl.ZIndex = 999
            nameLbl.Parent = row
            table.insert(_G.HubObjects, nameLbl)

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
            local tpc = Instance.new("UICorner")
            tpc.CornerRadius = UDim.new(0,4)
            tpc.Parent = tpBtn
            table.insert(_G.HubObjects, tpc)
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
    task.wait(0.05)
    local totalH = 0
    for _, ch in ipairs(contPlayers:GetChildren()) do
        if ch:IsA("Frame") then totalH = totalH + ch.Size.Y.Offset end
    end
    contPlayers.Size = UDim2.new(1,0,0,totalH + 40*scale)
end

updatePlayers()
Players.PlayerAdded:Connect(updatePlayers)
Players.PlayerRemoving:Connect(updatePlayers)

-- ================= ЛОГИКА ФУНКЦИЙ =================
local flyBV = nil
local espObjs = {}

-- Полёт
local flyConn = RunService.Heartbeat:Connect(function()
    if fly then
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
            local f,r,u = cam.CFrame.LookVector, cam.CFrame.RightVector, cam.CFrame.UpVector
            local vel = f * -move.Z + r * move.X + u * move.Y
            flyBV.Velocity = vel * flySpd
        else
            flyBV.Velocity = move * flySpd
        end
        hum.PlatformStand = true
    else
        if flyBV then flyBV:Destroy(); flyBV = nil end
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then char.Humanoid.PlatformStand = false end
    end
end)
table.insert(_G.HubObjects, flyConn)

-- Ноклип
local noclipConn = RunService.Heartbeat:Connect(function()
    if noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)
table.insert(_G.HubObjects, noclipConn)

-- Скорость ходьбы
local function applyWalkSpeed()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = walk end
end
local charAddedWalk = LocalPlayer.CharacterAdded:Connect(function(ch)
    task.wait(0.1)
    applyWalkSpeed()
    if charScale ~= 1 then
        applyScale(ch, charScale)
    end
end)
table.insert(_G.HubObjects, charAddedWalk)
applyWalkSpeed()

-- Аимбот
local aimConn = RunService.Heartbeat:Connect(function()
    if aim then
        local cam = workspace.CurrentCamera
        if not cam then return end
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
                    local hum = targetChar:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 then
                        local head = targetChar:FindFirstChild("Head")
                        if head then
                            local dist = (head.Position - hrp.Position).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                closestHead = head
                            end
                        end
                    end
                end
            end
        end
        if closestHead then
            cam.CFrame = CFrame.new(cam.CFrame.Position, closestHead.Position)
        end
    end
end)
table.insert(_G.HubObjects, aimConn)

-- ESP
local espConn = RunService.Heartbeat:Connect(function()
    if esp then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local char = player.Character
                if char then
                    if not espObjs[player] then
                        local box = Instance.new("BoxHandleAdornment")
                        box.Size = Vector3.new(4,5,1.5)
                        box.Adornee = char:FindFirstChild("HumanoidRootPart") or char
                        box.Color3 = Color3.fromRGB(255,50,50)
                        box.Transparency = 0.6
                        box.AlwaysOnTop = true
                        box.ZIndex = 10
                        box.Parent = char
                        espObjs[player] = box
                        table.insert(_G.HubObjects, box)
                    end
                else
                    if espObjs[player] then
                        espObjs[player]:Destroy()
                        espObjs[player] = nil
                    end
                end
            end
        end
        for player, box in pairs(espObjs) do
            if not Players:FindFirstChild(player.Name) then
                box:Destroy()
                espObjs[player] = nil
            end
        end
    else
        for _, box in pairs(espObjs) do
            box:Destroy()
        end
        espObjs = {}
    end
end)
table.insert(_G.HubObjects, espConn)

-- God Mode
local godConn = RunService.Heartbeat:Connect(function()
    if god then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = char.Humanoid.MaxHealth
        end
    end
end)
table.insert(_G.HubObjects, godConn)

local godCharAdded = LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if god and char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Health = char.Humanoid.MaxHealth
    end
    applyWalkSpeed()
    if charScale ~= 1 then
        applyScale(char, charScale)
    end
end)
table.insert(_G.HubObjects, godCharAdded)

-- Применяем масштаб при загрузке
task.wait(0.5)
if charScale ~= 1 then
    local char = LocalPlayer.Character
    if char then
        applyScale(char, charScale)
    end
end

-- Применяем сохранённые состояния
for fn, st in pairs(functionStates) do
    if st then toggleFunctionByName(fn) end
end

showTab("Основные")

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

print("Energy Hub загружен! M – меню. Размер персонажа корректно работает с HipHeight.")
