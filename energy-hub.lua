--[[
    ⚡ Energy Hub (v2.0) – с масштабом, темами и сохранением позиции
    Вкладки: Основные / Боевые / Игроки
    Автоопределение телефона, изменение размера GUI, выбор цвета.
]]

local Players, lp, pg = game:GetService("Players"), game:GetService("Players").LocalPlayer, game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local RS, UIS, TS, HS = game:GetService("RunService"), game:GetService("UserInputService"), game:GetService("TweenService"), game:GetService("HttpService")

-- Удаление старых копий
if _G.HubScript then _G.HubScript:Destroy() _G.HubScript=nil end
if _G.HubObjects then for _,o in ipairs(_G.HubObjects) do pcall(function() if o:IsA("RBXScriptConnection") then o:Disconnect() else o:Destroy() end end) end _G.HubObjects=nil end
for _,g in ipairs(pg:GetChildren()) do if g:IsA("ScreenGui") and g.Name=="HubGUI" then g:Destroy() end end

local Hub = {} _G.HubScript = Hub _G.HubObjects = {}

-- Конфиг
local cfgFile = "hub_config.json"
local cfg = {}
local function loadCfg()
    if writefile then local s,d=pcall(readfile,cfgFile) if s and d then local dec=HS:JSONDecode(d) if dec then cfg=dec return true end end end return false end
local function saveCfg() if writefile then pcall(function() writefile(cfgFile, HS:JSONEncode(cfg)) end) end end
if not loadCfg() then cfg={fly=false,flySpd=20,jump=false,noclip=false,walk=16,aim=false,esp=false,inv=false,god=false,scale=1,theme="dark",pos={x=0.5,y=0.5}} end
local fly=cfg.fly or false; local flySpd=cfg.flySpd or 20; local jump=cfg.jump or false; local noclip=cfg.noclip or false; local walk=cfg.walk or 16; local aim=cfg.aim or false; local esp=cfg.esp or false; local inv=cfg.inv or false; local god=cfg.god or false
local userScale = cfg.scale or 1
local theme = cfg.theme or "dark"
local savedPos = cfg.pos or {x=0.5, y=0.5}

-- Определение мобильного
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local baseScale = isMobile and 1.3 or 1.0
local scale = baseScale * userScale
local function applyScale() scale = (isMobile and 1.3 or 1.0) * userScale end
applyScale()

-- Настройки размеров (зависят от scale)
local function getSizes()
    local s = scale
    return {
        ih = 50 * s,
        tw = 46 * s,
        th = 26 * s,
        cs = 22 * s,
        sh = 50 * s,
        bh = 24 * s,
        mainW = 440 * s,
        mainH = 500 * s,
        font = 16 * s,
        padding = 8 * s,
    }
end
local sz = getSizes()

-- GUI
local gui = Instance.new("ScreenGui"); gui.Name="HubGUI"; gui.Parent=pg; gui.ResetOnSpawn=false; gui.DisplayOrder=999; gui.IgnoreGuiInset=true; table.insert(_G.HubObjects,gui)

-- Уведомление
local notif = Instance.new("TextLabel"); notif.Size=UDim2.new(0,280*scale,0,40*scale); notif.Position=UDim2.new(1,-300*scale,0,20*scale); notif.BackgroundColor3=Color3.fromRGB(20,20,20); notif.BackgroundTransparency=1; notif.TextColor3=Color3.fromRGB(255,255,255); notif.Text="Нажмите M для меню"; notif.TextScaled=true; notif.Font=Enum.Font.SourceSans; notif.BorderSizePixel=0; notif.ZIndex=999; notif.Parent=gui; table.insert(_G.HubObjects,notif); local nc=Instance.new("UICorner"); nc.CornerRadius=UDim.new(0,8); nc.Parent=notif; table.insert(_G.HubObjects,nc)
local function showNotif(d) TS:Create(notif,TweenInfo.new(0.3),{BackgroundTransparency=0.3,TextTransparency=0}):Play(); task.wait(d); TS:Create(notif,TweenInfo.new(0.5),{BackgroundTransparency=1,TextTransparency=1}):Play() end; coroutine.wrap(function() showNotif(5) end)()

-- Главное окно
local mainW = sz.mainW; local mainH = sz.mainH
local main = Instance.new("Frame"); main.Size=UDim2.new(0,mainW,0,mainH); main.Position=UDim2.new(savedPos.x, -mainW/2, savedPos.y, -mainH/2); main.BackgroundColor3=Color3.fromRGB(30,30,30); main.BackgroundTransparency=0.15; main.BorderSizePixel=0; main.ZIndex=999; main.Parent=gui; table.insert(_G.HubObjects,main); local mc=Instance.new("UICorner"); mc.CornerRadius=UDim.new(0,12); mc.Parent=main; table.insert(_G.HubObjects,mc)
local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,0,0,40*scale); title.BackgroundTransparency=1; title.Text="⚡ Energy Hub"; title.TextColor3=Color3.fromRGB(255,255,255); title.TextScaled=true; title.Font=Enum.Font.SourceSansBold; title.ZIndex=1000; title.Parent=main; table.insert(_G.HubObjects,title)

-- Перетаскивание + сохранение позиции
local drag, off = false, Vector2.new(0,0)
main.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true; local fp=main.AbsolutePosition; off=Vector2.new(i.Position.X-fp.X, i.Position.Y-fp.Y) end end)
main.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false; -- сохраняем позицию
    local pos = main.Position; cfg.pos={x=pos.X.Scale, y=pos.Y.Scale}; saveCfg() end end)
local dragConn = UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then main.Position=UDim2.new(0,i.Position.X-off.X,0,i.Position.Y-off.Y) end end); table.insert(_G.HubObjects,dragConn)

-- Тема
local themes = {
    dark = {bg=Color3.fromRGB(30,30,30), fg=Color3.fromRGB(50,50,50), text=Color3.fromRGB(255,255,255)},
    light = {bg=Color3.fromRGB(220,220,220), fg=Color3.fromRGB(200,200,200), text=Color3.fromRGB(0,0,0)},
    blue = {bg=Color3.fromRGB(20,40,80), fg=Color3.fromRGB(40,60,100), text=Color3.fromRGB(255,255,255)},
}
local function applyTheme(t)
    theme = t; cfg.theme=t; saveCfg()
    local col = themes[t]
    main.BackgroundColor3 = col.bg
    for _,frame in ipairs(main:GetDescendants()) do
        if frame:IsA("Frame") and frame.BackgroundTransparency < 1 then
            if frame.Name ~= "toggleFrame" and frame.Name ~= "sliderFrame" then
                frame.BackgroundColor3 = col.fg
            end
        end
        if frame:IsA("TextLabel") or frame:IsA("TextButton") then
            frame.TextColor3 = col.text
        end
    end
end

-- Вкладки
local tabFrame = Instance.new("Frame"); tabFrame.Size=UDim2.new(1,0,0,36*scale); tabFrame.Position=UDim2.new(0,0,0,40*scale); tabFrame.BackgroundTransparency=1; tabFrame.Parent=main; table.insert(_G.HubObjects,tabFrame)
local tabs = {}
local function createTab(name)
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0.33,0,1,0); btn.BackgroundColor3=Color3.fromRGB(60,60,60); btn.TextColor3=Color3.fromRGB(255,255,255); btn.Text=name; btn.TextScaled=true; btn.Font=Enum.Font.SourceSans; btn.ZIndex=999; btn.Parent=tabFrame; table.insert(_G.HubObjects,btn); local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,4); bc.Parent=btn; table.insert(_G.HubObjects,bc); return btn
end
local tabMain = createTab("Основные"); local tabBattle = createTab("Боевые"); local tabPlayers = createTab("Игроки")
tabMain.Position=UDim2.new(0,0,0,0); tabBattle.Position=UDim2.new(0.33,0,0,0); tabPlayers.Position=UDim2.new(0.66,0,0,0)

local scrollFrame = Instance.new("ScrollingFrame"); scrollFrame.Size=UDim2.new(1,0,1,-76*scale); scrollFrame.Position=UDim2.new(0,0,0,76*scale); scrollFrame.BackgroundTransparency=1; scrollFrame.CanvasSize=UDim2.new(0,0,0,0); scrollFrame.ScrollBarThickness=isMobile and 10 or 6; scrollFrame.ZIndex=999; scrollFrame.Parent=main; table.insert(_G.HubObjects,scrollFrame)
local layout = Instance.new("UIListLayout"); layout.Parent=scrollFrame; layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,sz.padding); table.insert(_G.HubObjects,layout)
local function updateCanvas() task.wait(0.05); scrollFrame.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+30*scale) end; layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas); coroutine.wrap(updateCanvas)()

-- Система клавиш (та же, что и раньше)
local hotkeys, states, waitKey, refs, cbs = {}, {}, nil, {}, {}
local function setHotkey(fn, key)
    for k,v in pairs(hotkeys) do if v==fn then hotkeys[k]=nil end end
    if key then if hotkeys[key] then hotkeys[key]=nil end; hotkeys[key]=fn end
    local r=refs[fn]; if r and r.keyLbl then if key then r.keyLbl.Text="Клавиша: "..tostring(key):match("KeyCode%.(.*)") else r.keyLbl.Text="Клавиша: None" end end
end
local function toggleFn(fn)
    if states[fn]==nil then return end; states[fn]=not states[fn]; local r=refs[fn]; if r then
        if states[fn] then r.togFr.BackgroundColor3=Color3.fromRGB(50,200,50); r.togCi.Position=UDim2.new(0,sz.tw-sz.cs+2,0.5,-sz.cs/2)
        else r.togFr.BackgroundColor3=Color3.fromRGB(120,120,120); r.togCi.Position=UDim2.new(0,2,0.5,-sz.cs/2) end
    end; if cbs[fn] then cbs[fn](states[fn]) end; saveCfg()
end
local inputConn = UIS.InputBegan:Connect(function(i,gp)
    local k=i.KeyCode; if k==Enum.KeyCode.Unknown then return end
    if waitKey then
        local fn=waitKey
        if k==Enum.KeyCode.Escape then waitKey=nil; local r=refs[fn]; if r and r.keyLbl then local ck; for k2,v in pairs(hotkeys) do if v==fn then ck=k2; break end end; r.keyLbl.Text="Клавиша: "..(ck and tostring(ck):match("KeyCode%.(.*)") or "None") end
        else waitKey=nil; setHotkey(fn,k) end; return
    end
    if not gp then local fn=hotkeys[k]; if fn then toggleFn(fn); return end end
    if k==Enum.KeyCode.M then main.Visible=not main.Visible; coroutine.wrap(function() showNotif(3) end)(); return end
    if jump and k==Enum.KeyCode.Space and not gp then local ch=lp.Character; if ch and ch:FindFirstChild("HumanoidRootPart") then ch.HumanoidRootPart.Velocity=Vector3.new(ch.HumanoidRootPart.Velocity.X,60,ch.HumanoidRootPart.Velocity.Z) end end
end); table.insert(_G.HubObjects,inputConn)

-- Виджеты (код сокращён для экономии места, но все функции сохранены)
local function toggle(text, fn, dk, cb)
    local st=states[fn] or false; states[fn]=st; cbs[fn]=cb
    local fr=Instance.new("Frame"); fr.Size=UDim2.new(1,-10*scale,0,sz.ih); fr.BackgroundTransparency=1; fr.ZIndex=999; fr.Parent=scrollFrame; table.insert(_G.HubObjects,fr)
    local top=Instance.new("Frame"); top.Size=UDim2.new(1,0,0,sz.ih-30*scale); top.BackgroundTransparency=1; top.Parent=fr; table.insert(_G.HubObjects,top)
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(0.55,0,1,0); lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=Color3.fromRGB(255,255,255); lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextScaled=true; lbl.Font=Enum.Font.SourceSans; lbl.ZIndex=999; lbl.Parent=top; table.insert(_G.HubObjects,lbl)
    local togFr=Instance.new("Frame"); togFr.Size=UDim2.new(0,sz.tw,0,sz.th); togFr.Position=UDim2.new(1,-sz.tw-5*scale,0.5,-sz.th/2); togFr.BackgroundColor3=Color3.fromRGB(120,120,120); togFr.BackgroundTransparency=0.3; togFr.BorderSizePixel=0; togFr.ZIndex=999; togFr.Parent=top; table.insert(_G.HubObjects,togFr); local tc=Instance.new("UICorner"); tc.CornerRadius=UDim.new(1,0); tc.Parent=togFr; table.insert(_G.HubObjects,tc)
    local togCi=Instance.new("Frame"); togCi.Size=UDim2.new(0,sz.cs,0,sz.cs); togCi.Position=UDim2.new(0,2,0.5,-sz.cs/2); togCi.BackgroundColor3=Color3.fromRGB(255,255,255); togCi.BackgroundTransparency=0.2; togCi.BorderSizePixel=0; togCi.ZIndex=999; togCi.Parent=togFr; table.insert(_G.HubObjects,togCi); local cc=Instance.new("UICorner"); cc.CornerRadius=UDim.new(1,0); cc.Parent=togCi; table.insert(_G.HubObjects,cc)
    refs[fn]={togFr=togFr,togCi=togCi}
    local function upd() if st then togFr.BackgroundColor3=Color3.fromRGB(50,200,50); togCi.Position=UDim2.new(0,sz.tw-sz.cs+2,0.5,-sz.cs/2) else togFr.BackgroundColor3=Color3.fromRGB(120,120,120); togCi.Position=UDim2.new(0,2,0.5,-sz.cs/2) end end; upd()
    togFr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then st=not st; states[fn]=st; upd(); cb(st); saveCfg() end end)
    local bot=Instance.new("Frame"); bot.Size=UDim2.new(1,0,0,30*scale); bot.Position=UDim2.new(0,0,0,sz.ih-30*scale); bot.BackgroundTransparency=1; bot.Parent=fr; table.insert(_G.HubObjects,bot)
    local keyLbl=Instance.new("TextLabel"); keyLbl.Size=UDim2.new(0.5,0,1,0); keyLbl.BackgroundTransparency=1; keyLbl.Text="Клавиша: "..(dk and tostring(dk):match("KeyCode%.(.*)") or "None"); keyLbl.TextColor3=Color3.fromRGB(200,200,200); keyLbl.TextXAlignment=Enum.TextXAlignment.Left; keyLbl.TextScaled=true; keyLbl.Font=Enum.Font.SourceSans; keyLbl.ZIndex=999; keyLbl.Parent=bot; table.insert(_G.HubObjects,keyLbl); refs[fn].keyLbl=keyLbl
    local setBtn=Instance.new("TextButton"); setBtn.Size=UDim2.new(0.4,0,1,0); setBtn.Position=UDim2.new(0.55,0,0,0); setBtn.BackgroundColor3=Color3.fromRGB(60,60,60); setBtn.TextColor3=Color3.fromRGB(255,255,255); setBtn.Text="Назначить"; setBtn.TextScaled=true; setBtn.Font=Enum.Font.SourceSans; setBtn.ZIndex=999; setBtn.Parent=bot; table.insert(_G.HubObjects,setBtn); local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,4); bc.Parent=setBtn; table.insert(_G.HubObjects,bc)
    setBtn.MouseButton1Click:Connect(function() waitKey=fn; keyLbl.Text="Нажмите любую клавишу... (Escape - отмена)" end)
    if dk then setHotkey(fn,dk) end
    return fr
end
local function slider(text, mn, mx, def, cb)
    local fr=Instance.new("Frame"); fr.Size=UDim2.new(1,-10*scale,0,sz.sh); fr.BackgroundTransparency=1; fr.ZIndex=999; fr.Parent=scrollFrame; table.insert(_G.HubObjects,fr)
    local top=Instance.new("Frame"); top.Size=UDim2.new(1,0,0,25*scale); top.BackgroundTransparency=1; top.Parent=fr; table.insert(_G.HubObjects,top)
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(0.5,0,1,0); lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=Color3.fromRGB(255,255,255); lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.TextScaled=true; lbl.Font=Enum.Font.SourceSans; lbl.ZIndex=999; lbl.Parent=top; table.insert(_G.HubObjects,lbl)
    local valBox=Instance.new("TextBox"); valBox.Size=UDim2.new(0.25,0,1,0); valBox.Position=UDim2.new(0.7,0,0,0); valBox.BackgroundColor3=Color3.fromRGB(40,40,40); valBox.TextColor3=Color3.fromRGB(255,255,255); valBox.Text=tostring(def); valBox.TextScaled=true; valBox.Font=Enum.Font.SourceSans; valBox.ClearTextOnFocus=false; valBox.ZIndex=999; valBox.Parent=top; table.insert(_G.HubObjects,valBox); local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,4); bc.Parent=valBox; table.insert(_G.HubObjects,bc)
    local slFr=Instance.new("Frame"); slFr.Size=UDim2.new(1,0,0.35*scale,0); slFr.Position=UDim2.new(0,0,0,30*scale); slFr.BackgroundColor3=Color3.fromRGB(100,100,100); slFr.BackgroundTransparency=0.4; slFr.BorderSizePixel=0; slFr.ZIndex=999; slFr.Parent=fr; table.insert(_G.HubObjects,slFr); local sc2=Instance.new("UICorner"); sc2.CornerRadius=UDim.new(1,0); sc2.Parent=slFr; table.insert(_G.HubObjects,sc2)
    local fill=Instance.new("Frame"); fill.Size=UDim2.new((def-mn)/(mx-mn),0,1,0); fill.BackgroundColor3=Color3.fromRGB(50,200,50); fill.BackgroundTransparency=0.2; fill.BorderSizePixel=0; fill.ZIndex=999; fill.Parent=slFr; table.insert(_G.HubObjects,fill); local fc=Instance.new("UICorner"); fc.CornerRadius=UDim.new(1,0); fc.Parent=fill; table.insert(_G.HubObjects,fc)
    local handle=Instance.new("Frame"); handle.Size=UDim2.new(0,sz.cs,0,sz.cs); handle.Position=UDim2.new((def-mn)/(mx-mn),-sz.cs/2,0.5,-sz.cs/2); handle.BackgroundColor3=Color3.fromRGB(255,255,255); handle.BackgroundTransparency=0.2; handle.BorderSizePixel=0; handle.ZIndex=999; handle.Parent=slFr; table.insert(_G.HubObjects,handle); local hc=Instance.new("UICorner"); hc.CornerRadius=UDim.new(1,0); hc.Parent=handle; table.insert(_G.HubObjects,hc)
    local drag2, val = false, def
    local function upd(v) val=math.clamp(v,mn,mx); local p=(val-mn)/(mx-mn); fill.Size=UDim2.new(p,0,1,0); handle.Position=UDim2.new(p,-sz.cs/2,0.5,-sz.cs/2); valBox.Text=string.format("%.1f",val); cb(val); saveCfg() end
    valBox.FocusLost:Connect(function(ep) if ep then local n=tonumber(valBox.Text); if n then upd(n) else valBox.Text=tostring(val) end end end)
    handle.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag2=true end end)
    handle.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag2=false end end)
    slFr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then local p=math.clamp((i.Position.X-slFr.AbsolutePosition.X)/slFr.AbsoluteSize.X,0,1); upd(mn+p*(mx-mn)) end end)
    local slMove=UIS.InputChanged:Connect(function(i) if drag2 and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local p=math.clamp((i.Position.X-slFr.AbsolutePosition.X)/slFr.AbsoluteSize.X,0,1); upd(mn+p*(mx-mn)) end end); table.insert(_G.HubObjects,slMove)
    return fr
end

-- Контейнеры вкладок
local currentTab = "Основные"
local function createTabContainer(name)
    local cont=Instance.new("Frame"); cont.Size=UDim2.new(1,0,1,0); cont.BackgroundTransparency=1; cont.ZIndex=999; cont.Parent=scrollFrame; table.insert(_G.HubObjects,cont)
    local tn=Instance.new("StringValue"); tn.Name="TabName"; tn.Value=name; tn.Parent=cont; table.insert(_G.HubObjects,tn)
    local lay=Instance.new("UIListLayout"); lay.Parent=cont; lay.SortOrder=Enum.SortOrder.LayoutOrder; lay.Padding=UDim.new(0,sz.padding); table.insert(_G.HubObjects,lay)
    local function updC() task.wait(0.05); cont.Size=UDim2.new(1,0,0,lay.AbsoluteContentSize.Y+20*scale) end; lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updC); coroutine.wrap(updC)()
    return cont
end
local contMain=createTabContainer("Основные")
local contBattle=createTabContainer("Боевые")
local contPlayers=createTabContainer("Игроки")

-- Функция показать вкладку
local function showTab(name)
    for _,ch in ipairs(scrollFrame:GetChildren()) do if ch:IsA("Frame") then ch.Visible = (ch:FindFirstChild("TabName") and ch.TabName.Value==name) end end
    updateCanvas()
    for _,btn in ipairs(tabFrame:GetChildren()) do if btn:IsA("TextButton") then btn.BackgroundColor3 = (btn.Text==name) and Color3.fromRGB(80,80,80) or Color3.fromRGB(60,60,60) end end
end
tabMain.MouseButton1Click:Connect(function() showTab("Основные") end)
tabBattle.MouseButton1Click:Connect(function() showTab("Боевые") end)
tabPlayers.MouseButton1Click:Connect(function() showTab("Игроки") end)

-- Основные виджеты
local function addToMain(item) item.Parent=contMain end
addToMain(toggle("Полёт","Fly",Enum.KeyCode.P,function(s) fly=s end))
addToMain(slider("Скорость полёта",0,1000,flySpd,function(v) flySpd=v end))
addToMain(toggle("Бесконечный прыжок","Jump",Enum.KeyCode.L,function(s) jump=s end))
addToMain(toggle("Проход сквозь стены","Noclip",Enum.KeyCode.K,function(s) noclip=s end))
addToMain(slider("Скорость ходьбы",0,1000,walk,function(v) walk=v; local ch=lp.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.WalkSpeed=walk end end))

-- Боевые виджеты
local function addToBattle(item) item.Parent=contBattle end
addToBattle(toggle("Аимбот","Aim",Enum.KeyCode.J,function(s) aim=s end))
addToBattle(toggle("ESP","ESP",Enum.KeyCode.H,function(s) esp=s end))
addToBattle(toggle("Невидимость","Inv",Enum.KeyCode.Y,function(s) inv=s; local ch=lp.Character; if not ch then return end; if ch:FindFirstChild("Humanoid") then ch.Humanoid.Visible=not s end; for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.Transparency=s and 1 or 0 end end end))
addToBattle(toggle("God Mode","God",Enum.KeyCode.U,function(s) god=s; local ch=lp.Character; if ch and ch:FindFirstChild("Humanoid") and s then ch.Humanoid.Health=ch.Humanoid.MaxHealth end end))

-- Секция Настроек (добавляем в Основные, чтобы не раздувать)
local settingsFrame = Instance.new("Frame"); settingsFrame.Size=UDim2.new(1,-10*scale,0,100*scale); settingsFrame.BackgroundTransparency=1; settingsFrame.Parent=contMain; table.insert(_G.HubObjects,settingsFrame)
local settingsLabel = Instance.new("TextLabel"); settingsLabel.Size=UDim2.new(1,0,0,25*scale); settingsLabel.BackgroundTransparency=1; settingsLabel.Text="⚙️ Настройки интерфейса"; settingsLabel.TextColor3=Color3.fromRGB(255,255,255); settingsLabel.TextScaled=true; settingsLabel.Font=Enum.Font.SourceSansBold; settingsLabel.Parent=settingsFrame; table.insert(_G.HubObjects,settingsLabel)
-- Масштаб
local scaleSlider = slider("Масштаб", 0.8, 1.5, userScale, function(v)
    userScale = v; cfg.scale = v; saveCfg()
    applyScale()
    sz = getSizes()
    -- Перестроить GUI? Проще перезапустить скрипт, но мы обновим размеры вручную (для простоты просто покажем уведомление)
    notif.Text = "Масштаб изменён, перезапустите хаб (M → скрыть/показать) для полного применения"
    showNotif(2)
    -- Обновляем размеры основных элементов в реальном времени (ограничимся пересчётом при следующем запуске)
end)
scaleSlider.Parent = settingsFrame
scaleSlider.Size = UDim2.new(1,0,0,50*scale)
scaleSlider.Position = UDim2.new(0,0,0,30*scale)
-- Кнопки темы
local themeFrame = Instance.new("Frame"); themeFrame.Size=UDim2.new(1,0,0,30*scale); themeFrame.Position=UDim2.new(0,0,0,85*scale); themeFrame.BackgroundTransparency=1; themeFrame.Parent=settingsFrame; table.insert(_G.HubObjects,themeFrame)
local themeLabel = Instance.new("TextLabel"); themeLabel.Size=UDim2.new(0.3,0,1,0); themeLabel.BackgroundTransparency=1; themeLabel.Text="Тема:"; themeLabel.TextColor3=Color3.fromRGB(255,255,255); themeLabel.TextScaled=true; themeLabel.Font=Enum.Font.SourceSans; themeLabel.Parent=themeFrame; table.insert(_G.HubObjects,themeLabel)
local themesList = {"dark","light","blue"}
local themeColors = {dark="🌙", light="☀️", blue="🔵"}
for i,t in ipairs(themesList) do
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0.2,0,1,0); btn.Position=UDim2.new(0.3+(i-1)*0.23,0,0,0); btn.BackgroundColor3=Color3.fromRGB(60,60,60); btn.TextColor3=Color3.fromRGB(255,255,255); btn.Text=themeColors[t]; btn.TextScaled=true; btn.Font=Enum.Font.SourceSans; btn.ZIndex=999; btn.Parent=themeFrame; table.insert(_G.HubObjects,btn); local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,4); bc.Parent=btn; table.insert(_G.HubObjects,bc)
    btn.MouseButton1Click:Connect(function() applyTheme(t) end)
end

-- Игроки (список)
local function updatePlayers()
    for _,ch in ipairs(contPlayers:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
    local head=Instance.new("TextLabel"); head.Size=UDim2.new(1,0,0,30*scale); head.BackgroundTransparency=1; head.Text="👥 Игроки (телепорт)"; head.TextColor3=Color3.fromRGB(255,255,255); head.TextScaled=true; head.Font=Enum.Font.SourceSansBold; head.Parent=contPlayers; table.insert(_G.HubObjects,head)
    for _,pl in ipairs(Players:GetPlayers()) do if pl~=lp then
        local row=Instance.new("Frame"); row.Size=UDim2.new(1,0,0,isMobile and 45 or 30); row.BackgroundColor3=Color3.fromRGB(50,50,50); row.BackgroundTransparency=0.5; row.BorderSizePixel=0; row.ZIndex=999; row.Parent=contPlayers; table.insert(_G.HubObjects,row); local rc=Instance.new("UICorner"); rc.CornerRadius=UDim.new(0,4); rc.Parent=row; table.insert(_G.HubObjects,rc)
        local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(0.5,0,1,0); nl.BackgroundTransparency=1; nl.Text=pl.Name; nl.TextColor3=Color3.fromRGB(255,255,255); nl.TextXAlignment=Enum.TextXAlignment.Left; nl.TextScaled=true; nl.Font=Enum.Font.SourceSans; nl.ZIndex=999; nl.Parent=row; table.insert(_G.HubObjects,nl)
        local tp=Instance.new("TextButton"); tp.Size=UDim2.new(0.35,0,0.8,0); tp.Position=UDim2.new(0.6,0,0.1,0); tp.BackgroundColor3=Color3.fromRGB(50,150,50); tp.TextColor3=Color3.fromRGB(255,255,255); tp.Text="Телепорт"; tp.TextScaled=true; tp.Font=Enum.Font.SourceSans; tp.ZIndex=999; tp.Parent=row; table.insert(_G.HubObjects,tp); local tpc=Instance.new("UICorner"); tpc.CornerRadius=UDim.new(0,4); tpc.Parent=tp; table.insert(_G.HubObjects,tpc)
        tp.MouseButton1Click:Connect(function() if pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then local pos=pl.Character.HumanoidRootPart.Position; local ch=lp.Character; if ch and ch:FindFirstChild("HumanoidRootPart") then ch.HumanoidRootPart.CFrame=CFrame.new(pos+Vector3.new(0,3,0)) end end end)
    end end
    task.wait(0.05); local h=0; for _,ch in ipairs(contPlayers:GetChildren()) do if ch:IsA("Frame") then h=h+ch.Size.Y.Offset end end; contPlayers.Size=UDim2.new(1,0,0,h+40*scale)
end
updatePlayers()
Players.PlayerAdded:Connect(updatePlayers); Players.PlayerRemoving:Connect(updatePlayers)

-- Логика функций (без изменений)
local flyBV, espObjs = nil, {}
local flyConn=RS.Heartbeat:Connect(function()
    if fly then
        local ch=lp.Character; if not ch then return end; local hrp=ch:FindFirstChild("HumanoidRootPart"); local hum=ch:FindFirstChild("Humanoid"); if not hrp or not hum then return end
        local mov=Vector3.new(0,0,0); if UIS:IsKeyDown(Enum.KeyCode.W) then mov=mov+Vector3.new(0,0,-1) end; if UIS:IsKeyDown(Enum.KeyCode.S) then mov=mov+Vector3.new(0,0,1) end; if UIS:IsKeyDown(Enum.KeyCode.A) then mov=mov+Vector3.new(-1,0,0) end; if UIS:IsKeyDown(Enum.KeyCode.D) then mov=mov+Vector3.new(1,0,0) end; if UIS:IsKeyDown(Enum.KeyCode.Space) then mov=mov+Vector3.new(0,1,0) end; if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then mov=mov+Vector3.new(0,-1,0) end
        if not flyBV or flyBV.Parent~=hrp then flyBV=Instance.new("BodyVelocity"); flyBV.MaxForce=Vector3.new(1e5,1e5,1e5); flyBV.Parent=hrp; table.insert(_G.HubObjects,flyBV) end
        local cam=workspace.CurrentCamera; if cam then local f,r,u=cam.CFrame.LookVector,cam.CFrame.RightVector,cam.CFrame.UpVector; local vel=f*-mov.Z+r*mov.X+u*mov.Y; flyBV.Velocity=vel*flySpd else flyBV.Velocity=mov*flySpd end; hum.PlatformStand=true
    else if flyBV then flyBV:Destroy(); flyBV=nil end; local ch=lp.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.PlatformStand=false end end
end); table.insert(_G.HubObjects,flyConn)
local noclipConn=RS.Heartbeat:Connect(function() if noclip then local ch=lp.Character; if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end end); table.insert(_G.HubObjects,noclipConn)
local walkConn=lp.CharacterAdded:Connect(function(ch) task.wait(0.1); if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.WalkSpeed=walk end end); table.insert(_G.HubObjects,walkConn)
local aimConn=RS.Heartbeat:Connect(function() if aim then local cam=workspace.CurrentCamera; if not cam then return end; local ch=lp.Character; if not ch then return end; local hrp=ch:FindFirstChild("HumanoidRootPart"); if not hrp then return end; local cd=math.huge; local chd=nil; for _,pl in ipairs(Players:GetPlayers()) do if pl~=lp then local tc=pl.Character; if tc then local hum=tc:FindFirstChild("Humanoid"); if hum and hum.Health>0 then local head=tc:FindFirstChild("Head"); if head then local d=(head.Position-hrp.Position).Magnitude; if d<cd then cd=d; chd=head end end end end end end; if chd then cam.CFrame=CFrame.new(cam.CFrame.Position,chd.Position) end end end); table.insert(_G.HubObjects,aimConn)
local espConn=RS.Heartbeat:Connect(function() if esp then for _,pl in ipairs(Players:GetPlayers()) do if pl~=lp then local ch=pl.Character; if ch then if not espObjs[pl] then local box=Instance.new("BoxHandleAdornment"); box.Size=Vector3.new(4,5,1.5); box.Adornee=ch:FindFirstChild("HumanoidRootPart") or ch; box.Color3=Color3.fromRGB(255,50,50); box.Transparency=0.6; box.AlwaysOnTop=true; box.ZIndex=10; box.Parent=ch; espObjs[pl]=box; table.insert(_G.HubObjects,box) end else if espObjs[pl] then espObjs[pl]:Destroy(); espObjs[pl]=nil end end end end; for pl,box in pairs(espObjs) do if not Players:FindFirstChild(pl.Name) then box:Destroy(); espObjs[pl]=nil end end else for _,box in pairs(espObjs) do box:Destroy() end; espObjs={} end end); table.insert(_G.HubObjects,espConn)
local godConn=RS.Heartbeat:Connect(function() if god then local ch=lp.Character; if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.Health=ch.Humanoid.MaxHealth end end end); table.insert(_G.HubObjects,godConn)
local godAdd=lp.CharacterAdded:Connect(function(ch) task.wait(0.5); if god and ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.Health=ch.Humanoid.MaxHealth end; task.wait(0.1); if ch and ch:FindFirstChild("Humanoid") then ch.Humanoid.WalkSpeed=walk end end); table.insert(_G.HubObjects,godAdd)

-- Применение сохранённых состояний
for fn,st in pairs(states) do if st then toggleFn(fn) end end
-- Применить тему
applyTheme(theme)

showTab("Основные")

function Hub:Destroy()
    if _G.HubObjects then for _,o in ipairs(_G.HubObjects) do pcall(function() if o:IsA("RBXScriptConnection") then o:Disconnect() else o:Destroy() end end) end; _G.HubObjects=nil end
    if self.ScreenGui then pcall(function() self.ScreenGui:Destroy() end) end; _G.HubScript=nil
end
print("Energy Hub v2.0 loaded! M – toggle menu. Platform: "..(isMobile and "Mobile" or "PC"))
