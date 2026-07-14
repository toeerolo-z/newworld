pcall(function()
    if queue_on_teleport and getgenv()._ZH_script then
        queue_on_teleport(getgenv()._ZH_script)
    end
end)

repeat task.wait() until game:IsLoaded()
task.wait(1)

task.spawn(function()
    local lp = game:GetService("Players").LocalPlayer
    while task.wait() do
        lp.GameplayPaused = false
    end
end)

local RS  = game:GetService("RunService")
local PS  = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS  = game:GetService("TweenService")
local LT  = game:GetService("Lighting")
local HS  = game:GetService("HttpService")
local TP  = game:GetService("TeleportService")
local Cam = workspace.CurrentCamera
local LP  = PS.LocalPlayer

local function getChar() return LP.Character end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function _safeTP(cf)
    local char = getChar()
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local x, y, z = cf.X, cf.Y, cf.Z
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}
    local hit = workspace:Raycast(Vector3.new(x, y + 60, z), Vector3.new(0, -300, 0), params)
    local landY = hit and (hit.Position.Y + 4) or (y + 4)
    root.CFrame = CFrame.new(x, landY, z)
    root.AssemblyLinearVelocity = Vector3.zero
    return true
end

local S = {
    speed=100, infJumpH=50, flySpeed=100, tweenSpeed=100,
    brightness=2, freeCamSens=0.3, freeCamSpeed=0.5, fovVal=70,
    flyMode="MoveDirection",
}

local _savedPos = nil

if getgenv()._ZHUnload then pcall(getgenv()._ZHUnload); getgenv()._ZHUnload=nil end

local _macSrc = game:HttpGet("https://raw.githubusercontent.com/troidnox/sorrynol/refs/heads/main/zeree")
local _macFn, _macErr = loadstring(_macSrc)
if not _macFn then error("[ZeroHub] MacLib load failed: " .. tostring(_macErr)) end
local MacLib = _macFn()
if not MacLib then error("[ZeroHub] MacLib returned nil") end

local Window = MacLib:Window({
    Title    = "<font color=\"rgb(178,120,255)\">Zero</font> <font color=\"rgb(138,79,255)\">Hub</font>",
    Subtitle = "Above The Rim",
    Image    = "rbxassetid://83109184888967",
    Size     = UDim2.fromOffset(980, 760),
    DragStyle = 1,
    DisabledWindowControls = {},
    ShowUserInfo = false,
    Keybind  = Enum.KeyCode.F5,
    AcrylicBlur = false,
})

local Opt = {}
local Tog = {}

local _cleanupFns = {}
local function onUnload(fn) table.insert(_cleanupFns, fn) end
Window.onUnloaded(function()
    for _, fn in ipairs(_cleanupFns) do pcall(fn) end
    getgenv()._ZHUnload=nil
end)
getgenv()._ZHUnload=function() Window:Unload() end

local function notify(msg, dur)
    task.defer(function()
        pcall(function() Window:Notify({Title="Zero Hub", Description=msg, Lifetime=dur or 3}) end)
    end)
end

local TabGroup = Window:TabGroup()
local Tabs = {}
Tabs.Game      = TabGroup:Tab({Name="Main",       Image="target"})
Tabs.Character = TabGroup:Tab({Name="Character",  Image="circle-dot"})
Tabs.Utility   = TabGroup:Tab({Name="Utility",    Image="star"})
Tabs.Settings  = TabGroup:Tab({Name="Settings",   Image="sliders-horizontal"})

-- ═══════════════════════════════════════════════════════════════
--  MAIN TAB — AUTO GREEN
-- ═══════════════════════════════════════════════════════════════

local MainL = Tabs.Game:Section({Side="Left", Name="Shooting", Image="target"})
local MainR = Tabs.Game:Section({Side="Right", Name="Stat Editor", Image="trophy"})

do
    local _agEnabled = false
    local _agAnimConn = nil
    local _agCharConn = nil
    local _agOffset = 0
    local _statsNet = game:GetService("Stats").Network
    local _inputRemote = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Network"):WaitForChild("Input")

    local function getOneWaySec()
        local ok, ping = pcall(function()
            return _statsNet.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if ok and ping and ping > 0 then
            return (ping / 2) / 1000
        end
        return 0.05
    end

    local function releaseShot()
        pcall(function()
            _inputRemote:FireServer({
                Enabled = false,
                Action = "Shoot",
                Time = workspace:GetServerTimeNow()
            })
        end)
    end

    local function hookCharacter(char)
        if _agAnimConn then _agAnimConn:Disconnect(); _agAnimConn = nil end
        if not char then return end
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        local animator = hum:WaitForChild("Animator", 5)
        if not animator then return end

        _agAnimConn = animator.AnimationPlayed:Connect(function(track)
            if not _agEnabled then return end
            if char:GetAttribute("Action") ~= "Shooting" then return end

            local ok, peakTime = pcall(function() return track:GetTimeOfKeyframe("Peak") end)
            if not ok then
                ok, peakTime = pcall(function() return track:GetTimeOfKeyframe("Release") end)
            end
            if not ok or not peakTime then return end

            -- Server scores the shot when the release packet ARRIVES (~one-way latency later).
            -- The animation advances by (oneWay * track.Speed) during that trip, so we release
            -- EARLIER by that much. Target lands at server-side timing 0.94 (green center).
            local greenCenter = peakTime * 0.94
            local latencyLead = getOneWaySec() * track.Speed
            local targetTime = greenCenter - latencyLead + (_agOffset / 1000) * track.Speed
            if targetTime < 0 then targetTime = 0 end

            local fired = false
            local watchConn
            watchConn = RS.PreRender:Connect(function()
                if not track.IsPlaying or fired or not _agEnabled then
                    if watchConn then watchConn:Disconnect() end
                    return
                end
                if track.TimePosition >= targetTime then
                    fired = true
                    watchConn:Disconnect()
                    if char:GetAttribute("Action") == "Shooting" then
                        releaseShot()
                    end
                end
            end)
        end)
    end

    local function wireUp()
        local charsFolder = workspace:FindFirstChild("Characters")
        if not charsFolder then return end
        local char = charsFolder:FindFirstChild(LP.Name)
        if char then hookCharacter(char) end

        if _agCharConn then _agCharConn:Disconnect(); _agCharConn = nil end
        _agCharConn = charsFolder.ChildAdded:Connect(function(child)
            task.wait(0.5)
            if child.Name == LP.Name then hookCharacter(child) end
        end)
    end

    local function tearDown()
        if _agAnimConn then _agAnimConn:Disconnect(); _agAnimConn = nil end
        if _agCharConn then _agCharConn:Disconnect(); _agCharConn = nil end
    end

    Tog.AutoGreen = MainL:Toggle({ Name="Auto Green", Default=false, Keybind=Enum.KeyCode.G,
        Callback=function(p)
            _agEnabled = p
            if p then
                wireUp()
                notify("Auto Green ON", 2)
            else
                tearDown()
                notify("Auto Green OFF", 2)
            end
        end }, "AutoGreen")
    MainL:Label({ Text="Perfects your shot timing automatically" })

    MainL:Divider()

    Opt.AGOffset = MainL:Slider({ Name="Timing Offset", Default=0, Minimum=-100, Maximum=100, Precision=0,
        Callback=function(v) _agOffset = v end }, "AGOffset")
    MainL:Label({ Text="Negative = earlier release, Positive = later" })

    onUnload(function()
        _agEnabled = false
        tearDown()
    end)
end

do
    local _isEnabled = false
    local _stamConn = nil
    local _sprintConn = nil
    local _inputRemote = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Network"):WaitForChild("Input")

    local function wireStamina()
        local charsFolder = workspace:FindFirstChild("Characters")
        if not charsFolder then return end
        local char = charsFolder:FindFirstChild(LP.Name)
        if not char then return end

        if _stamConn then _stamConn:Disconnect(); _stamConn = nil end
        if _sprintConn then _sprintConn:Disconnect(); _sprintConn = nil end

        _stamConn = RS.Heartbeat:Connect(function()
            if not _isEnabled then return end
            pcall(function() char:SetAttribute("Stamina", char:GetAttribute("MaxStamina") or 100) end)
        end)

        _sprintConn = char:GetAttributeChangedSignal("Sprinting"):Connect(function()
            if not _isEnabled then return end
            if char:GetAttribute("Sprinting") == false then
                task.delay(0.05, function()
                    if not _isEnabled then return end
                    pcall(function()
                        _inputRemote:FireServer({ Enabled = true, Action = "Sprint", Time = workspace:GetServerTimeNow() })
                    end)
                end)
            end
        end)
    end

    local function tearStamina()
        if _stamConn then _stamConn:Disconnect(); _stamConn = nil end
        if _sprintConn then _sprintConn:Disconnect(); _sprintConn = nil end
    end

    MainL:Divider()

    Tog.InfStamina = MainL:Toggle({ Name="Infinite Stamina", Default=false,
        Callback=function(p)
            _isEnabled = p
            if p then
                wireStamina()
                notify("Inf Stamina ON", 2)
            else
                tearStamina()
                notify("Inf Stamina OFF", 2)
            end
        end }, "InfStamina")
    MainL:Label({ Text="Never run out of energy on the court" })

    onUnload(function()
        _isEnabled = false
        tearStamina()
    end)

    local charsFolder = workspace:FindFirstChild("Characters")
    if charsFolder then
        charsFolder.ChildAdded:Connect(function(child)
            task.wait(0.5)
            if child.Name == LP.Name and _isEnabled then wireStamina() end
        end)
    end
end

do
    local _statConn = nil
    local _statOverrides = {}
    local _cachedStatsTable = nil
    local _selectedStat = "ThreePointShot"

    local function findMyStats()
        if _cachedStatsTable then return _cachedStatsTable end
        local myChar = _charsFolder and _charsFolder:FindFirstChild(LP.Name)
        if not myChar then return nil end
        for _, obj in getgc(true) do
            if type(obj) == "table" and rawget(obj, "ThreePointShot") ~= nil and rawget(obj, "BallHandle") ~= nil and rawget(obj, "Speed") ~= nil and rawget(obj, "Steal") ~= nil then
                _cachedStatsTable = obj
                return obj
            end
        end
        return nil
    end

    local statNames = {"Three Point","Mid Range","Driving Layup","Ball Handle","Speed","Steal","Block","Rebound","Strength","Perimeter D","Interior D"}
    local statKeys = {
        ["Three Point"]="ThreePointShot", ["Mid Range"]="MidRangeShot", ["Driving Layup"]="DrivingLayup",
        ["Ball Handle"]="BallHandle", ["Speed"]="Speed", ["Steal"]="Steal", ["Block"]="Block",
        ["Rebound"]="Rebound", ["Strength"]="Strength", ["Perimeter D"]="PerimeterDefense", ["Interior D"]="InteriorDefense",
    }
    local allKeys = {"ThreePointShot","MidRangeShot","DrivingLayup","BallHandle","Speed","Steal","Block","Rebound","Strength","PerimeterDefense","InteriorDefense"}

    Tog.StatEditor = MainR:Toggle({ Name="Stat Editor", Default=false,
        Callback=function(p)
            if _statConn then _statConn:Disconnect(); _statConn = nil end
            _cachedStatsTable = nil
            if not p then
                _statOverrides = {}
                notify("Stat Editor OFF", 2)
                return
            end
            _statConn = RS.Heartbeat:Connect(function()
                local stats = findMyStats()
                if not stats then return end
                for key, val in _statOverrides do
                    rawset(stats, key, val)
                end
            end)
            notify("Stat Editor ON", 2)
        end }, "StatEditor")
    MainR:Label({ Text="Boost your player's attributes" })

    MainR:Divider()

    Opt.StatSelect = MainR:Dropdown({ Name="Stat", Options=statNames, Default=1, Multi=false,
        Callback=function(v)
            local sel = type(v) == "table" and next(v) or v
            _selectedStat = statKeys[sel] or "ThreePointShot"
            local cur = _statOverrides[_selectedStat] or 80
            if Opt.StatValue then pcall(function() Opt.StatValue:Set(cur) end) end
        end }, "StatSelect")

    Opt.StatValue = MainR:Slider({ Name="Value", Default=80, Minimum=0, Maximum=99, Precision=0,
        Callback=function(v)
            if _selectedStat then
                _statOverrides[_selectedStat] = v
            end
        end }, "StatValue")

    MainR:Divider()

    MainR:Button({ Name="Max All Stats", Callback=function()
        for _, key in ipairs(allKeys) do _statOverrides[key] = 99 end
        if Opt.StatValue then pcall(function() Opt.StatValue:Set(99) end) end
        notify("All stats maxed", 2)
    end})

    MainR:Button({ Name="Reset All Stats", Callback=function()
        _statOverrides = {}
        _cachedStatsTable = nil
        if Opt.StatValue then pcall(function() Opt.StatValue:Set(80) end) end
        notify("Stats reset", 2)
    end})

    onUnload(function()
        if _statConn then _statConn:Disconnect() end
        _statOverrides = {}
    end)

    if _charsFolder then
        _charsFolder.ChildAdded:Connect(function(child)
            if child.Name == LP.Name then task.wait(1); _cachedStatsTable = nil end
        end)
    end
end

-- ROSTER (character selector — any character, no ownership check)
do
    local _selectRemote = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Network"):WaitForChild("SelectCharacter")
    local RS2 = game:GetService("ReplicatedStorage")

    -- Build the character list dynamically from the Characters folder
    local roster = {}
    local rosterFolder = RS2:FindFirstChild("Characters")
    if rosterFolder then
        for _, mod in rosterFolder:GetChildren() do
            if mod:IsA("ModuleScript") then
                table.insert(roster, mod.Name)
            end
        end
        table.sort(roster)
    end
    if #roster == 0 then roster = {"Darren"} end

    local _selectedRoster = roster[1]

    MainR:Divider()
    MainR:Header({ Text="Roster" })

    Opt.RosterSelect = MainR:Dropdown({ Name="Character", Options=roster, Default=1, Multi=false,
        Callback=function(v)
            _selectedRoster = type(v) == "table" and next(v) or v
        end }, "RosterSelect")

    MainR:Button({ Name="Select Character", Callback=function()
        if not _selectedRoster then return end
        pcall(function() _selectRemote:FireServer({ Name = _selectedRoster }) end)
        notify("Selected "..tostring(_selectedRoster), 2)
    end})
    MainR:Label({ Text="Play as any character on the roster" })
end

-- ═══════════════════════════════════════════════════════════════
--  CHARACTER TAB
-- ═══════════════════════════════════════════════════════════════

local CharL = Tabs.Character:Section({Side="Left",  Name="Movement",  Image="zap"})
local CharR = Tabs.Character:Section({Side="Right", Name="Defense",    Image="shield"})

-- Shared cached movement controller ref — one GC scan, used by all features
local _cachedMovCtrl = nil
local function getMovCtrl()
    if _cachedMovCtrl and _cachedMovCtrl.Proxy and _cachedMovCtrl.Data then return _cachedMovCtrl end
    for _,obj in getgc(true) do
        if type(obj)=="table" and rawget(obj,"Proxy") ~= nil and rawget(obj,"MoveDirection") ~= nil and rawget(obj,"Data") ~= nil then
            _cachedMovCtrl = obj
            return obj
        end
    end
    return nil
end
-- Refresh cache on character respawn
local _charsFolder = workspace:FindFirstChild("Characters")
if _charsFolder then
    _charsFolder.ChildAdded:Connect(function(child)
        if child.Name == LP.Name then task.wait(1); _cachedMovCtrl = nil; getMovCtrl() end
    end)
end

-- ── MOVEMENT (LEFT) ──────────────────────────────────────────

-- FLY
Tog.Fly = CharL:Toggle({ Name="Fly", Default=false, Keybind=Enum.KeyCode.Y,
    Callback=function(p)
        if p then
            RS:BindToRenderStep("ZHFly",Enum.RenderPriority.Camera.Value+1,function(dt)
                local mc=getMovCtrl(); if not mc or not mc.Proxy then return end
                local proxyHRP=mc.Proxy:FindFirstChild("HumanoidRootPart"); if not proxyHRP then return end
                if not getgenv()._ZH_flyFrame then getgenv()._ZH_flyFrame=proxyHRP.CFrame end
                local frame=getgenv()._ZH_flyFrame; local cf=Cam.CFrame; local mv=Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then mv=mv+cf.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then mv=mv-cf.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then mv=mv-cf.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then mv=mv+cf.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then mv=mv+Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv=mv-Vector3.new(0,1,0) end
                if mv.Magnitude>0 then frame=frame+mv.Unit*S.flySpeed*dt end
                getgenv()._ZH_flyFrame=frame
                mc.Proxy:PivotTo(frame)
                local lv=proxyHRP:FindFirstChildWhichIsA("LinearVelocity")
                if lv then lv.VectorVelocity=Vector3.zero end
            end)
        else RS:UnbindFromRenderStep("ZHFly"); getgenv()._ZH_flyFrame=nil end
    end }, "Fly")
CharL:Label({ Text="Fly freely around the court" })
Opt.FlySpeed = CharL:Slider({ Name="Fly Speed", Default=100, Minimum=0, Maximum=5000, Precision=0,
    Callback=function(v) S.flySpeed=v end }, "FlySpeed")

CharL:Divider()

-- SPEEDHACK
do
    local _origSpeed = nil
    local _origBSpeed = nil
    local _speedConn = nil
    Tog.Speedhack = CharL:Toggle({ Name="Speedhack", Default=false, Keybind=Enum.KeyCode.N,
        Callback=function(p)
            if _speedConn then _speedConn:Disconnect(); _speedConn=nil end
            if p then
                _speedConn=RS.Heartbeat:Connect(function()
                    local mc=getMovCtrl(); if not mc or not mc.Data then return end
                    if not _origSpeed then _origSpeed=mc.Data.Speed; _origBSpeed=mc.Data.bSpeed end
                    mc.Data.Speed=S.speed
                    mc.Data.bSpeed=S.speed
                end)
            else
                local mc=getMovCtrl()
                if mc and mc.Data and _origSpeed then mc.Data.Speed=_origSpeed; mc.Data.bSpeed=_origBSpeed end
                _origSpeed=nil; _origBSpeed=nil
            end
        end }, "Speedhack")
    CharL:Label({ Text="Override your court speed" })
    Opt.SpeedhackSpeed = CharL:Slider({ Name="Speed", Default=25, Minimum=1, Maximum=200, Precision=0,
        Callback=function(v) S.speed=v end }, "SpeedhackSpeed")

    onUnload(function()
        RS:UnbindFromRenderStep("ZHFly"); getgenv()._ZH_flyFrame=nil
        if _speedConn then _speedConn:Disconnect() end
        local mc=getMovCtrl()
        if mc and mc.Data and _origSpeed then mc.Data.Speed=_origSpeed; mc.Data.bSpeed=_origBSpeed end
    end)
end

-- ── DEFENSE (RIGHT) ──────────────────────────────────────────

-- ANTI CONTEST
do
    local _acConn = nil
    Tog.AntiContest = CharR:Toggle({ Name="Anti Contest", Default=false,
        Callback=function(p)
            if _acConn then _acConn:Disconnect(); _acConn = nil end
            if not p then return end
            _acConn = RS.Heartbeat:Connect(function()
                if not _charsFolder then return end
                for _, ch in _charsFolder:GetChildren() do
                    if ch.Name ~= LP.Name then
                        pcall(function() ch:SetAttribute("Guard", false) end)
                        pcall(function() ch:SetAttribute("PerimeterD", 0) end)
                        pcall(function() ch:SetAttribute("InteriorD", 0) end)
                        pcall(function() ch:SetAttribute("Boxout", false) end)
                        if ch:GetAttribute("Action") == "Blocking" then
                            pcall(function() ch:SetAttribute("Action", "") end)
                        end
                    end
                end
            end)
        end }, "AntiContest")
    CharR:Label({ Text="Reduces opponent contest on your shots" })
    onUnload(function() if _acConn then _acConn:Disconnect() end end)
end

CharR:Divider()

-- AUTO GUARD
do
    local _agdConn = nil
    local _agdGuarding = false
    local _agdRange = 20
    local _agdBlockCd = 0
    local _inputRemote = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Network"):WaitForChild("Input")

    local function hasTheBall(ch)
        -- Signal 1: Ball ObjectValue populated
        local ball = ch:FindFirstChild("Ball")
        if ball and ball:IsA("ObjectValue") and ball.Value ~= nil then return true end
        -- Signal 2: on-ball action states
        local action = ch:GetAttribute("Action") or ""
        if action == "Shooting" or action == "Dribbling" or action == "Passing" then return true end
        -- Signal 3: visible held Basketball mesh (transparency < 1 when holding)
        local mesh = ch:FindFirstChild("Basketball")
        if mesh and mesh:IsA("BasePart") and mesh.Transparency < 1 then return true end
        return false
    end

    local function findBallCarrier()
        if not _charsFolder then return nil end
        local myChar = _charsFolder:FindFirstChild(LP.Name)
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

        -- Pass 1: explicit ball-carrier signals
        for _, ch in _charsFolder:GetChildren() do
            if ch.Name ~= LP.Name and hasTheBall(ch) then
                local hrp = ch:FindFirstChild("HumanoidRootPart")
                if hrp then return ch, hrp end
            end
        end

        -- Pass 2: fall back to nearest opponent (guard man even if ball signal is unclear)
        if myHRP then
            local best, bestHRP, bestDist = nil, nil, math.huge
            for _, ch in _charsFolder:GetChildren() do
                if ch.Name ~= LP.Name then
                    local hrp = ch:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local d = (hrp.Position - myHRP.Position).Magnitude
                        if d < bestDist then bestDist = d; best = ch; bestHRP = hrp end
                    end
                end
            end
            if best then return best, bestHRP end
        end
        return nil, nil
    end

    Tog.AutoGuard = CharR:Toggle({ Name="Auto Guard", Default=false,
        Callback=function(p)
            if _agdConn then _agdConn:Disconnect(); _agdConn = nil end
            _agdGuarding = false
            if not p then
                pcall(function() _inputRemote:FireServer({Enabled=false, Action="Guard"}) end)
                return
            end
            _agdConn = RS.Heartbeat:Connect(function(dt)
                local myChar = _charsFolder and _charsFolder:FindFirstChild(LP.Name)
                if not myChar then return end
                local myHRP = myChar:FindFirstChild("HumanoidRootPart")
                if not myHRP then return end
                local myBall = myChar:FindFirstChild("Ball")
                if myBall and myBall.Value ~= nil then
                    if _agdGuarding then
                        _agdGuarding = false
                        pcall(function() _inputRemote:FireServer({Enabled=false, Action="Guard"}) end)
                    end
                    return
                end

                local carrier, carrierHRP = findBallCarrier()
                if not carrier then
                    if _agdGuarding then
                        _agdGuarding = false
                        pcall(function() _inputRemote:FireServer({Enabled=false, Action="Guard"}) end)
                    end
                    return
                end

                local dist = (carrierHRP.Position - myHRP.Position).Magnitude
                local inRange = dist <= _agdRange

                if inRange and not _agdGuarding then
                    _agdGuarding = true
                    pcall(function() _inputRemote:FireServer({Enabled=true, Action="Guard"}) end)
                elseif not inRange and _agdGuarding then
                    _agdGuarding = false
                    pcall(function() _inputRemote:FireServer({Enabled=false, Action="Guard"}) end)
                end

                if inRange then
                    local mc = getMovCtrl()
                    if mc and mc.Proxy then
                        local proxyHRP = mc.Proxy:FindFirstChild("HumanoidRootPart")
                        if proxyHRP then
                            -- Contest zone: 2.5 studs in front of the opponent's facing direction
                            local carrierLook = carrierHRP.CFrame.LookVector
                            local contestSpot = carrierHRP.Position + Vector3.new(carrierLook.X, 0, carrierLook.Z).Unit * 2.5
                            contestSpot = Vector3.new(contestSpot.X, proxyHRP.Position.Y, contestSpot.Z)

                            local toSpot = contestSpot - proxyHRP.Position
                            local flat = Vector3.new(toSpot.X, 0, toSpot.Z)
                            local moveSpeed = (mc.Data and mc.Data.Speed or 17) * 2.2 -- move fast to catch up

                            local newPos
                            if flat.Magnitude > 0.5 then
                                local step = flat.Unit * math.min(moveSpeed * dt, flat.Magnitude)
                                newPos = proxyHRP.Position + step
                            else
                                newPos = proxyHRP.Position
                            end
                            -- Face the opponent to maximize contest angle
                            local faceCF = CFrame.lookAt(newPos, Vector3.new(carrierHRP.Position.X, newPos.Y, carrierHRP.Position.Z))
                            mc.Proxy:PivotTo(faceCF)
                            local lv = proxyHRP:FindFirstChildWhichIsA("LinearVelocity")
                            if lv then lv.VectorVelocity = Vector3.zero end
                        end
                    end

                    -- Block: fire Rebound (verified: sets Action to "Blocking") when opponent shoots
                    local carrierAction = carrier:GetAttribute("Action") or ""
                    local now = tick()
                    if carrierAction == "Shooting" and dist <= 12 and (now - _agdBlockCd) > 0.6 then
                        _agdBlockCd = now
                        pcall(function()
                            _inputRemote:FireServer({Enabled=true, Action="Rebound"})
                            task.delay(0.45, function()
                                _inputRemote:FireServer({Enabled=false, Action="Rebound"})
                            end)
                        end)
                    end
                end
            end)
        end }, "AutoGuard")
    CharR:Label({ Text="Locks the contest zone and blocks shots" })
    Opt.AutoGuardRange = CharR:Slider({ Name="Guard Range", Default=25, Minimum=5, Maximum=60, Precision=0,
        Callback=function(v) _agdRange = v end }, "AutoGuardRange")
    onUnload(function()
        if _agdConn then _agdConn:Disconnect() end
        if _agdGuarding then pcall(function() _inputRemote:FireServer({Enabled=false, Action="Guard"}) end) end
    end)
end





-- ═══════════════════════════════════════════════════════════════
--  UTILITY TAB
-- ═══════════════════════════════════════════════════════════════

local UtilL = Tabs.Utility:Section({Side="Left",  Name="Player",       Image="circle-dot"})
local UtilR = Tabs.Utility:Section({Side="Right", Name="Server",       Image="globe"})

-- NO SLOW
do
    local _nsConn = nil
    Tog.NoSlow = UtilL:Toggle({ Name="No Slow", Default=false,
        Callback=function(p)
            if _nsConn then _nsConn:Disconnect(); _nsConn = nil end
            if not p then return end
            local maxSpeed = nil
            _nsConn = RS.Heartbeat:Connect(function()
                local mc = getMovCtrl(); if not mc or not mc.Data then return end
                local cur = mc.Data.Speed
                if not maxSpeed or cur > maxSpeed then maxSpeed = cur end
                if cur < maxSpeed then
                    mc.Data.Speed = maxSpeed
                    mc.Data.bSpeed = maxSpeed
                end
            end)
        end }, "NoSlow")
    UtilL:Label({ Text="Prevents speed drops from dribbling or guarding" })
    onUnload(function() if _nsConn then _nsConn:Disconnect() end end)
end

UtilL:Divider()

Tog.AntiAFK = UtilL:Toggle({ Name="Anti AFK", Default=true,
    Callback=function(p)
        if getgenv()._ZH_afkConn then pcall(task.cancel,getgenv()._ZH_afkConn); getgenv()._ZH_afkConn=nil end
        if not p then return end
        local VU=cloneref and cloneref(Instance.new("VirtualUser")) or game:GetService("VirtualUser")
        getgenv()._ZH_afkConn=task.spawn(function()
            while Tog.AntiAFK and Tog.AntiAFK.State do
                pcall(function() VU:Button2Down(Vector2.zero,Cam.CFrame); task.wait(0.1); VU:Button2Up(Vector2.zero,Cam.CFrame) end)
                task.wait(20)
            end
        end)
    end }, "AntiAFK")
UtilL:Label({ Text="Prevents you from getting kicked for being idle" })

UtilL:Divider()

Tog.AutoRejoin = UtilL:Toggle({ Name="Auto Rejoin on Kick", Default=false,
    Callback=function(p)
        if p then
            LP.OnTeleport:Connect(function(state)
                if not (Tog.AutoRejoin and Tog.AutoRejoin.State) then return end
                if state==Enum.TeleportState.Failed or state==Enum.TeleportState.Started then
                    task.wait(3); pcall(function() TP:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end)
                end
            end)
            game.Close:Connect(function()
                if not (Tog.AutoRejoin and Tog.AutoRejoin.State) then return end
                pcall(function() TP:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end)
            end)
            notify("Auto Rejoin ON",2)
        end
    end }, "AutoRejoin")
UtilL:Label({ Text="Automatically rejoins if you get disconnected" })

UtilR:Header({ Text="Server" })
UtilR:Button({ Name="Serverhop", Callback=function()
    local ok,res=pcall(function() return HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")) end)
    if ok and res then for _,s in ipairs(res.data or {}) do if s.id~=game.JobId and s.playing<s.maxPlayers then TP:TeleportToPlaceInstance(game.PlaceId,s.id,LP); return end end end
    TP:Teleport(game.PlaceId,LP); notify("No servers found",3)
end})
Opt.MinPlayers = UtilR:Input({ Name="Min Players", Default="", Placeholder="0", Callback=function() end }, "MinPlayers")
UtilR:Button({ Name="Serverhop (Min Players)", Callback=function()
    local minP=tonumber(Opt.MinPlayers and Opt.MinPlayers.Value) or 0
    local ok,res=pcall(function() return HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")) end)
    if ok and res then for _,s in ipairs(res.data or {}) do if s.id~=game.JobId and s.playing>=minP and s.playing<s.maxPlayers then TP:TeleportToPlaceInstance(game.PlaceId,s.id,LP); return end end end
    notify("No servers with "..minP.."+ players",3)
end})
UtilR:Button({ Name="Rejoin", Callback=function() TP:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end })
Opt.JobID = UtilR:Input({ Name="JobID", Default="", Placeholder="Paste job id...", Callback=function() end }, "JobID")
UtilR:Button({ Name="Join Server", Callback=function() local id=Opt.JobID and Opt.JobID.Value or ""; if id~="" then TP:TeleportToPlaceInstance(game.PlaceId,id,LP) end end })
UtilR:Button({ Name="Copy Server JobId", Callback=function() setclipboard(game.JobId); notify(game.JobId.." Copied!",5) end })

-- ═══════════════════════════════════════════════════════════════
--  SETTINGS TAB
-- ═══════════════════════════════════════════════════════════════

local SettL = Tabs.Settings:Section({Side="Left",  Name="Interface", Image="layout-dashboard"})
local SettR = Tabs.Settings:Section({Side="Right", Name="Controls",  Image="gamepad-2"})

SettL:Header({ Text="Interface" })
SettL:Button({ Name="Unload", Callback=function() Window:Unload() end })
SettL:Divider()
Tog.HideUI = SettL:Toggle({ Name="Hide UI", Default=false, Callback=function(p) Window:SetState(not p) end }, "HideUI")
SettL:Divider()
SettL:Slider({ Name="UI Transparency", Default=5, Minimum=0, Maximum=50, Precision=0,
    Callback=function(v) Window:SetTransparency(v/100) end })
SettL:Divider()

Opt.TweenMode = SettL:Dropdown({ Name="Tween Mode", Options={"Normal","Safe"}, Default=1, Multi=false, Callback=function() end }, "TweenMode")
Opt.TweenSpeed = SettL:Slider({ Name="Tween Speed", Default=100, Minimum=0, Maximum=700, Precision=0, Callback=function(v) S.tweenSpeed=v end }, "TweenSpeed")
Opt.SafeModeHeight = SettL:Slider({ Name="Safe Height", Default=1000, Minimum=0, Maximum=100000, Precision=0, Callback=function() end }, "SafeModeHeight")
Opt.FlyMode = SettL:Dropdown({ Name="Fly Mode", Options={"MoveDirection","Camera LookVector"}, Default=1, Multi=false,
    Callback=function(v)
        local sel = type(v) == "table" and next(v) or v
        S.flyMode = sel or "MoveDirection"
    end }, "FlyMode")
SettL:Divider()

MacLib:SetFolder("ZeroHub/configs")
Tabs.Settings:InsertConfigSection("Left")

Tog.AntiBan = SettL:Toggle({ Name="Anti Ban", Default=true, Callback=function() end }, "AntiBan")

SettR:Header({ Text="Controls" })
SettR:Keybind({ Name="Menu Toggle", Default=Enum.KeyCode.F5, onBinded=function(k) pcall(function() Window:SetKeybind(k) end) end }, "KbMenu")

local SettR2 = Tabs.Settings:Section({ Side="Right", Name="Theme", Image="palette" })
SettR2:Header({ Text="Theme" })
SettR2:Colorpicker({ Name="Accent Color", Default=Color3.fromRGB(138,79,255), Alpha=0,
    Callback=function(c) pcall(function() MacLib:SetAccent(c) end) end }, "ThemeAccent")
if MacLib.Options and MacLib.Options["ThemeAccent"] then MacLib.Options["ThemeAccent"].ThemeOnly=true end
SettR2:Colorpicker({ Name="Background", Default=Color3.fromRGB(12,12,12), Alpha=0,
    Callback=function(c) pcall(function() MacLib:SetScheme("BackgroundColor",c) end) end }, "ThemeBG")
if MacLib.Options and MacLib.Options["ThemeBG"] then MacLib.Options["ThemeBG"].ThemeOnly=true end
SettR2:Colorpicker({ Name="Main Color", Default=Color3.fromRGB(24,24,24), Alpha=0,
    Callback=function(c) pcall(function() MacLib:SetScheme("MainColor",c) end) end }, "ThemeMain")
if MacLib.Options and MacLib.Options["ThemeMain"] then MacLib.Options["ThemeMain"].ThemeOnly=true end
SettR2:Colorpicker({ Name="Outline Color", Default=Color3.fromRGB(45,45,45), Alpha=0,
    Callback=function(c) pcall(function() MacLib:SetScheme("OutlineColor",c) end) end }, "ThemeOutline")
if MacLib.Options and MacLib.Options["ThemeOutline"] then MacLib.Options["ThemeOutline"].ThemeOnly=true end

-- ═══════════════════════════════════════════════════════════════
--  DEFAULT TAB + AUTOLOAD
-- ═══════════════════════════════════════════════════════════════

Tabs.Game:Select()

task.defer(function()
    task.wait(3)
    pcall(function() MacLib:LoadAutoLoadConfig() end)
end)

notify("Zero Hub loaded", 4)
