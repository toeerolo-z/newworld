repeat task.wait() until game:IsLoaded()
task.wait(1)

task.spawn(function()
    local Players = game:GetService("Players")
    local ContentProvider = game:GetService("ContentProvider")
    local Player = Players.LocalPlayer or Players.PlayerAdded:Wait()

    local isfunctionhooked = isfunctionhooked or ishooked or is_function_hooked or function() return false end
    local getfenv = getfenv()

    local Remote  = Instance.new("RemoteEvent")
    local Remote2 = Instance.new("RemoteEvent")

    local x = game:GetService("AnimationFromVideoCreatorService")
    pcall(function()
        hookfunc(x.CreateJob, function(...) return "blocked" end)
    end)

    local ids = {
        "1352543873","12978095818","12977615774","10804731440",
        "5448127505","11389137937","5042114982","125451561960633",
        "118425905671666","95268421208163","107640924738262",
        "74833786606286","9886659406","103134660123798",
        "139785960036434","136413657454848","87089195419529",
        "6065775281","4544052033","4113050383","5147488592",
        "129697930","5147695474","3523243755","4911962991",
        "5147488658","5054663650","1204397029","6578871732",
        "1427967925","6579106223","5034718180","6425281788",
        "6511490623","5034718129","9619665977","6282522798",
        "12977615774","137842439297855","6401617475","6065821980",
        "112264959079193","110803789420086","169476802","10055842438",
    }

    local global = { "CobaltInitialized", "Bypassed_Dex", "UtopiaSpy" }

    local detected = false
    local function punish(reason)
        if detected then return end
        detected = true
        warn("[ANTI TAMPER]: "..reason)
        pcall(function() Player:Kick("Unauthorized Environment") end)
        while true do end
    end

    task.spawn(function()
        while true do
            for _, assetid in ids do
                local success, status = pcall(function()
                    return ContentProvider:GetAssetFetchStatus(`rbxassetid://{assetid}`)
                end)
                if success and status == Enum.AssetFetchStatus.Success then
                    punish("Illegal Asset Fetched"); return
                end
            end
            task.wait(0.3)
        end
    end)

    for _, illegalassetid in ids do
        ContentProvider:GetAssetFetchStatusChangedSignal(`rbxassetid://{illegalassetid}`):Connect(function(status)
            if status == Enum.AssetFetchStatus.Success then
                punish("Illegal Asset Status Changed")
            end
        end)
    end

    task.spawn(function()
        while task.wait(1) do
            for _, g in global do
                pcall(function()
                    if rawget(getgenv(), g) ~= nil then
                        punish("Illegal Global: "..g)
                    end
                end)
            end
        end
    end)

    task.spawn(function()
        while task.wait() do
            pcall(function()
                if isfunctionhooked(isfunctionhooked)
                or isfunctionhooked(getfenv.isfunctionhooked)
                or isfunctionhooked(getrenv().collectgarbage)
                or isfunctionhooked(game.HttpGet)
                or isfunctionhooked(request)
                or isfunctionhooked(getfenv.request)
                or isfunctionhooked(ContentProvider.GetAssetFetchStatusChangedSignal)
                or isfunctionhooked(ContentProvider.GetAssetFetchStatus)
                or isfunctionhooked(getfenv.loadstring)
                or isfunctionhooked(loadstring)
                or isfunctionhooked(Remote.FireServer)
                then
                    punish("blacklisted")
                end
            end)
        end
    end)
end)

local RS  = game:GetService("RunService")
local PS  = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LT  = game:GetService("Lighting")
local HS  = game:GetService("HttpService")
local TP  = game:GetService("TeleportService")
local Cam = workspace.CurrentCamera
local LP  = PS.LocalPlayer

local function getChar() return LP.Character end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local _real_raknet = rawget(_G, "raknet")
local raknet = {}
raknet.add_send_hook = function(fn)
    local rn = rawget(_G, "raknet") or _real_raknet
    if rn then return rn:add_send_hook(fn) end
end
raknet.remove_send_hook = function(hook)
    local rn = rawget(_G, "raknet") or _real_raknet
    if rn then return rn:remove_send_hook(hook) end
end

local function tweenTo(cf)
    local hrp = getHRP(); if not hrp then return end
    hrp.AssemblyLinearVelocity = Vector3.zero
    local tweenMode = Opt and Opt.TweenMode and (type(Opt.TweenMode.Value)=="table" and next(Opt.TweenMode.Value) or Opt.TweenMode.Value) or "Normal"
    local tweenSpeed = Opt and Opt.TweenSpeed and Opt.TweenSpeed.Value or 100
    local target = cf.Position
    if tweenMode == "Normal" then
        if (hrp.Position - target).Magnitude <= 10 then hrp.CFrame = cf; return end
        local t0 = tick(); local p0 = hrp.Position; local dur = (target - p0).Magnitude / tweenSpeed
        while tick()-t0 < dur do
            local a = (tick()-t0)/dur; hrp.CFrame = CFrame.new(p0:Lerp(target, a), target); hrp.AssemblyLinearVelocity = Vector3.zero; task.wait()
        end
        hrp.CFrame = cf
    elseif tweenMode == "Safe" then
        local height = Opt and Opt.SafeModeHeight and Opt.SafeModeHeight.Value or 1000
        local up1 = Vector3.new(hrp.Position.X, target.Y + height, hrp.Position.Z)
        hrp.CFrame = CFrame.new(up1)
        local up2 = Vector3.new(target.X, target.Y + height, target.Z)
        local t0 = tick(); local dur = (up2-up1).Magnitude / tweenSpeed
        while tick()-t0 < dur do
            local a = (tick()-t0)/dur; hrp.CFrame = CFrame.new(up1:Lerp(up2, a), up2); hrp.AssemblyLinearVelocity = Vector3.zero; task.wait()
        end
        hrp.CFrame = cf
    end
end

local S = {
    speed=100, infJumpH=50, flySpeed=100, flyMode="MoveDirection",
    brightness=2, freeCamSens=0.3, freeCamSpeed=0.5, fovVal=70,

    espDist=1000, espFontSize=14,
    tracerThick=2, tracerColor=Color3.new(1,1,1),
    plrESPColor=Color3.fromRGB(255,255,255), plrHighlightTrans=0.5,
    mobsRange=1000, mobsDist=0, mobsHeight=0,
}

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local libSrc, themeSrc, saveSrc, done = nil, nil, nil, 0
local function dl(url, cb) task.spawn(function() local ok,r=pcall(function() return game:HttpGet(url) end); if ok and r then cb(r) end; done=done+1 end) end
dl(repo.."Library.lua",             function(r) libSrc=r   end)
dl(repo.."addons/ThemeManager.lua", function(r) themeSrc=r end)
dl(repo.."addons/SaveManager.lua",  function(r) saveSrc=r  end)
while done < 3 do task.wait(0.1) end

local Library      = loadstring(libSrc)()
local ThemeManager = loadstring(themeSrc)()
local SaveManager  = loadstring(saveSrc)()

local Window = Library:CreateWindow({
    Title            = "A Universal Time",
    Footer           = "A Universal Time  |  V.0.0.1",
    Icon             = 83109184888967,
    Font             = Enum.Font.Code,
    Center           = true,
    AutoShow         = false,
    ShowCustomCursor = true,
    NotifySide       = "Left",
    Size             = UDim2.fromOffset(870, 720),
    Resizable        = true,
    EnableSidebarResize = true,
    MinSize          = Vector2.new(800, 600),
})

local _LOADING_FLAG = "ZeroHub/vvu_seen_loading.txt"
local _hasSeenLoading = pcall(function()
    local f = readfile(_LOADING_FLAG)
    return f == "1"
end) and (function()
    local ok, v = pcall(readfile, _LOADING_FLAG)
    return ok and v == "1"
end)()

if not _hasSeenLoading then
    local _Loading = Library:CreateLoading({
        Title       = "A Universal Time",
        Icon        = 86441407905385,
        TotalSteps  = 6,
        ShowSidebar = true,
        WindowWidth = 640,
    })
    _Loading:SetMessage("Initializing A Universal Time")
    _Loading:SetDescription("Please wait...")
    _Loading:ShowSidebarPage(true)

    _Loading.Sidebar:AddLabel('<font color="rgb(200,130,240)"><b>A Universal Time</b></font>  V.0.0.1')
    _Loading.Sidebar:AddLabel("Game  Universal")
    _Loading.Sidebar:AddDivider()
    _Loading.Sidebar:AddLabel("Player  <b>" .. LP.Name .. "</b>")
    _Loading.Sidebar:AddLabel("Server  " .. tostring(game.JobId):sub(1,14) .. "...")
    _Loading.Sidebar:AddDivider()

    local _charReady = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") ~= nil
    local _sideCharLbl = _Loading.Sidebar:AddLabel("Character  " .. (_charReady and '<font color="rgb(200,130,240)">Ready</font>' or '<font color="rgb(255,100,80)">Loading...</font>'))

    local _initPing = 0
    pcall(function() _initPing = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end)
    _Loading.Sidebar:AddLabel("Ping  " .. _initPing .. " ms")

    _Loading:SetCurrentStep(1)
    _Loading:SetDescription("Waiting for character to load...")
    local _cWait = 0
    while not (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")) and _cWait < 10 do
        task.wait(0.3); _cWait = _cWait + 0.3
    end
    pcall(function() _sideCharLbl:SetText('Character  <font color="rgb(200,130,240)">Ready</font>') end)
    task.wait(0.4)

    _Loading:SetCurrentStep(2)
    _Loading:SetDescription("Connecting to game services...")
    task.wait(0.8)

    _Loading:SetCurrentStep(3)
    _Loading:SetDescription("Loading ESP & detection systems...")
    task.wait(0.9)

    _Loading:SetCurrentStep(4)
    _Loading:SetDescription("Building interface...")
    task.wait(0.7)

    _Loading:SetCurrentStep(5)
    _Loading:SetDescription("Applying A Universal Time theme...")
    task.wait(0.6)

    _Loading:SetCurrentStep(6)
    _Loading:SetDescription('<font color="rgb(200,130,240)">All systems ready. Welcome, ' .. LP.Name .. ".</font>")
    task.wait(0.6)

    pcall(function() writefile(_LOADING_FLAG, "1") end)

    _Loading:Continue()
else
    local _Loading = Library:CreateLoading({
        Title      = "A Universal Time",
        Icon       = 86441407905385,
        TotalSteps = 1,
    })
    _Loading:SetMessage("A Universal Time")
    _Loading:SetDescription("Loading...")
    _Loading:SetCurrentStep(1)
    task.wait(0.1)
    _Loading:Continue()
end
local Opt = Library.Options
local Tog = Library.Toggles
local notify = function(msg, dur) Library:Notify(msg, dur or 3) end

local fbConn       = nil
local clickTPConn  = nil
local chatGui      = nil
local _cursorConn  = nil
local _cursorDot   = nil

local _watermark = Library:AddDraggableLabel("⊙ A Universal Time")
local _wFrameTimer = tick(); local _wFrames = 0; local _wFPS = 60
RS.RenderStepped:Connect(function()
    _wFrames = _wFrames + 1
    if tick() - _wFrameTimer >= 1 then
        _wFPS = _wFrames; _wFrames = 0; _wFrameTimer = tick()
    end
    local ping = 0
    pcall(function()
        ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    end)
    _watermark:SetText(string.format("⊙ A Universal Time  |  %d fps  |  %d ms", _wFPS, ping))
end)
Library.ShowToggleFrameInKeybinds = true
local Tabs = {
    Farming  = Window:AddTab("Farming",    "wheat"),
    Quests   = Window:AddTab("Quests",     "scroll-text"),
    Misc     = Window:AddTab("Misc",       "puzzle"),
    Main     = Window:AddTab("Character",  "user"),
    World    = Window:AddTab("World",      "globe"),
    Visuals  = Window:AddTab("Visuals",    "eye"),
    Settings = Window:AddTab("Settings",   "settings"),
}

local _Player   = Tabs.Main:AddLeftGroupbox("Position", "crosshair")
local _Movement = Tabs.Main:AddRightGroupbox("Movement", "wind")
_Player:AddInput("Coordinates", {Default="", Numeric=false, Finished=false, Text="Coordinates", Placeholder="X, Y, Z"})
_Player:AddButton({Text="Tween To", Func=function()
    local x,y,z = Opt.Coordinates.Value:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
    if x then tweenTo(CFrame.new(tonumber(x),tonumber(y),tonumber(z))) else notify("Use format: X, Y, Z",2) end
end})
_Player:AddButton({Text="Copy Position", Func=function()
    local hrp=getHRP(); if hrp then setclipboard(tostring(hrp.Position)); notify("Copied "..tostring(hrp.Position)) end
end})

_Movement:AddToggle("Fly", {Text="Fly", Default=false,
    Callback=function(p)
        if p then
            RS:BindToRenderStep("AUTFly", Enum.RenderPriority.Input.Value, function(dt)
                local c=getChar(); if not c then return end
                local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if not getgenv()._AUT_flyFrame then getgenv()._AUT_flyFrame = hrp.CFrame end
                local frame = getgenv()._AUT_flyFrame
                local cf = Cam.CFrame
                local mv = Vector3.zero
                local fmode = Opt.FlyMode and (type(Opt.FlyMode.Value)=="table" and next(Opt.FlyMode.Value) or Opt.FlyMode.Value) or "MoveDirection"
                if fmode == "MoveDirection" then
                    local fwd = Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit
                    local rgt = Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
                    if UIS:IsKeyDown(Enum.KeyCode.W) then mv=mv+fwd end
                    if UIS:IsKeyDown(Enum.KeyCode.S) then mv=mv-fwd end
                    if UIS:IsKeyDown(Enum.KeyCode.A) then mv=mv-rgt end
                    if UIS:IsKeyDown(Enum.KeyCode.D) then mv=mv+rgt end
                else
                    local hum=c:FindFirstChildOfClass("Humanoid")
                    if hum and hum.MoveDirection.Magnitude>0 then
                        local fwd2=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit
                        local rgt2=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
                        mv=mv+fwd2*hum.MoveDirection:Dot(fwd2)+rgt2*hum.MoveDirection:Dot(rgt2)
                    end
                end
                if UIS:IsKeyDown(Enum.KeyCode.Space)       then mv=mv+Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv=mv-Vector3.new(0,1,0) end
                if mv.Magnitude>0 then frame=frame+mv.Unit*S.flySpeed*dt end
                local fwd3=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
                if fwd3.Magnitude>0 then frame=CFrame.new(frame.Position, frame.Position+fwd3.Unit) end
                getgenv()._AUT_flyFrame=frame
                hrp.AssemblyLinearVelocity=Vector3.zero; hrp.CFrame=frame
            end)
        else RS:UnbindFromRenderStep("AUTFly"); getgenv()._AUT_flyFrame=nil end
    end}):AddKeyPicker("FlyKeybind",{Default="Y",SyncToggleState=true,Mode="Toggle",Text="Fly Keybind"})
_Movement:AddSlider("FlySpeed",{Text="Fly Speed",Default=100,Min=0,Max=5000,Rounding=0,Compact=true,Callback=function(v) S.flySpeed=v end})

_Movement:AddToggle("Speedhack", {Text="Speedhack", Default=false,
    Callback=function(p)
        if p then
            RS:BindToRenderStep("VVUSpeed", Enum.RenderPriority.Input.Value, function(dt)
                local c=getChar(); if not c then return end
                local hum=c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then return end
                local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if hum.MoveDirection.Magnitude>0 then hrp.CFrame=hrp.CFrame+hum.MoveDirection*S.speed*dt end
            end)
        else RS:UnbindFromRenderStep("VVUSpeed") end
    end}):AddKeyPicker("SpeedhackKeybind",{Default="N",SyncToggleState=true,Mode="Toggle",Text="Speedhack Keybind"})
_Movement:AddSlider("SpeedhackSpeed",{Text="Speedhack Speed",Default=100,Min=0,Max=5000,Rounding=0,Compact=true,Callback=function(v) S.speed=v end})

local ijConn=nil
_Movement:AddToggle("InfiniteJump",{Text="Infinite Jump",Default=false,
    Callback=function(p)
        if ijConn then ijConn:Disconnect(); ijConn=nil end
        if p then ijConn=UIS.JumpRequest:Connect(function()
            local hrp=getHRP(); if hrp then hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X,S.infJumpH,hrp.AssemblyLinearVelocity.Z) end
        end) end
    end}):AddKeyPicker("InfiniteJumpKeybind",{Default="H",SyncToggleState=true,Mode="Toggle",Text="Infinite Jump Keybind"})
_Movement:AddSlider("InfiniteJumpHeight",{Text="Jump Height",Default=50,Min=0,Max=1000,Rounding=0,Compact=true,Callback=function(v) S.infJumpH=v end})

local noclipConn=nil
_Movement:AddToggle("Noclip",{Text="Noclip",Default=false,
    Callback=function(p)
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
        if p then noclipConn=RS.RenderStepped:Connect(function()
            local c=getChar(); if not c then return end
            for _,part in ipairs(c:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=false end end
        end) end
    end}):AddKeyPicker("NoclipKeybind",{Default="",SyncToggleState=true,Mode="Toggle",Text="Noclip Keybind"})

local _Safety = Tabs.Main:AddRightGroupbox("Safety", "shield-alert")

_Safety:AddButton({Text="Kill Yourself", Func=function() local hum=getHum(); if hum then hum.Health=0 end end})

local noAnimsThread=nil; local forcedTracks={}; local origTracks={}
_Safety:AddToggle("NoAnims",{Text="No Animations",Default=false,
    Callback=function(p)
        if noAnimsThread then task.cancel(noAnimsThread); noAnimsThread=nil end
        if p then
            local c=getChar(); if not c then return end
            local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
            local anim=hum:FindFirstChildOfClass("Animator"); if not anim then return end
            local dummy=Instance.new("Animation"); dummy.AnimationId="rbxassetid://109212722752"
            noAnimsThread=task.spawn(function()
                while Tog.NoAnims and Tog.NoAnims.Value and hum and hum.Parent do
                    for _,track in ipairs(anim:GetPlayingAnimationTracks()) do
                        if track.Animation.AnimationId~=dummy.AnimationId then
                            if not table.find(origTracks,track) then table.insert(origTracks,track) end
                            pcall(function() track:Stop(); task.defer(track.Destroy,track) end)
                        end
                    end
                    local found=false
                    for _,track in ipairs(anim:GetPlayingAnimationTracks()) do
                        if track.Animation.AnimationId==dummy.AnimationId then found=true end
                    end
                    if not found then
                        local t=anim:LoadAnimation(dummy); table.insert(forcedTracks,t)
                        t.Priority=Enum.AnimationPriority.Core; t:AdjustSpeed(0); t:Play()
                    end
                    task.wait(0.1)
                end
            end)
        else
            for _,track in pairs(forcedTracks) do pcall(function() track:Stop(); track:Destroy() end) end
            forcedTracks={}
            for _,track in pairs(origTracks) do pcall(function() track:Play() end) end
            origTracks={}
        end
    end}):AddKeyPicker("NoAnimsKeybind",{Default="",SyncToggleState=true,Mode="Toggle",Text="No Anims Keybind"})

do
    local _animSpeedConn = nil
    local _animSpeed = 1
    local function applyAnimSpeed(speed)
        pcall(function()
            local char = getChar(); if not char then return end
            local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
            local anim = hum:FindFirstChildOfClass("Animator"); if not anim then return end
            for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
                pcall(function() track:AdjustSpeed(speed) end)
            end
        end)
    end
    _Safety:AddToggle("AnimSpeed",{Text="Animation Speed",Default=false,
        Callback=function(p)
            if _animSpeedConn then _animSpeedConn:Disconnect(); _animSpeedConn=nil end
            if p then
                _animSpeedConn = RS.Heartbeat:Connect(function() applyAnimSpeed(_animSpeed) end)
            else
                applyAnimSpeed(1)
            end
        end})
    _Safety:AddSlider("AnimSpeedSlider",{Text="Speed",Default=1,Min=0.1,Max=200,Rounding=1,Compact=true,
        Callback=function(v) _animSpeed=v end})
end

local _savedPos=nil; local _autoTPConn=nil
_Player:AddButton({Text="Save Position",Func=function() local hrp=getHRP(); if hrp then _savedPos=hrp.CFrame; notify("Saved",2) end end})
_Player:AddButton({Text="TP to Saved",Func=function() if not _savedPos then notify("No position saved",2); return end; local hrp=getHRP(); if hrp then hrp.CFrame=_savedPos; hrp.AssemblyLinearVelocity=Vector3.zero end end})
_Safety:AddSlider("AutoTPHP",{Text="HP Threshold %",Default=20,Min=1,Max=99,Rounding=0,Compact=true})
_Safety:AddToggle("AutoTPSafe",{Text="Auto TP on Low HP",Default=false,
    Callback=function(p)
        if _autoTPConn then _autoTPConn:Disconnect(); _autoTPConn=nil end
        if not p then return end
        _autoTPConn=RS.Heartbeat:Connect(function()
            if not _savedPos then return end; local hum=getHum(); if not hum or hum.Health<=0 then return end
            if (hum.Health/hum.MaxHealth*100)<=(Opt.AutoTPHP and Opt.AutoTPHP.Value or 20) then
                local hrp=getHRP(); if hrp then hrp.CFrame=_savedPos; hrp.AssemblyLinearVelocity=Vector3.zero; notify("Low HP — safe!",2) end
            end
        end)
    end})

local _desyncHook = nil
_Safety:AddToggle("Desync", {Text="Desync", Default=false, Callback=function(p)
    if _desyncHook then
        pcall(function() raknet.remove_send_hook(_desyncHook) end)
        _desyncHook = nil
    end
    if not p then return end
    pcall(function()
        _desyncHook = raknet.add_send_hook(function(packet)
            if not packet then return end
            if packet.PacketId == 0x1B then
                local buf = packet.AsBuffer
                buffer.writeu32(buf, 1, 0xFFFFFFFF)
                packet:SetData(buf)
            end
        end)
    end)
end})
local afkConn = nil

_Safety:AddDivider()
_Safety:AddLabel("Auto Rejoin")
_Safety:AddToggle("AutoRejoin",{Text="Auto Rejoin on Kick",Default=false,Callback=function(p)
    if p then
        LP.OnTeleport:Connect(function(state)
            if not (Tog.AutoRejoin and Tog.AutoRejoin.Value) then return end
            if state==Enum.TeleportState.Failed or state==Enum.TeleportState.Started then
                task.wait(3); pcall(function() TP:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end)
            end
        end)
        game.Close:Connect(function()
            if not (Tog.AutoRejoin and Tog.AutoRejoin.Value) then return end
            pcall(function() TP:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end)
        end)
        notify("Auto Rejoin ON",2)
    end
end})
_Safety:AddToggle("AntiAFK",{Text="Anti AFK",Default=true,
    Callback=function(p)
        if afkConn then afkConn:Disconnect(); afkConn=nil end
        if p then afkConn=LP.Idled:Connect(function() local VU=game:GetService("VirtualUser"); VU:Button2Down(Vector2.zero,Cam.CFrame); task.wait(0.1); VU:Button2Up(Vector2.zero,Cam.CFrame) end) end
    end})

local _Attach    = Tabs.World:AddLeftGroupbox("Attach",     "anchor")
local _Range     = Tabs.World:AddRightGroupbox("Range",     "radar")
local _MiscTools = Tabs.World:AddRightGroupbox("Tools",     "hammer")
local _MiscServer= Tabs.World:AddRightGroupbox("Server",    "network")
local _MiscPerf  = Tabs.World:AddRightGroupbox("Performance","zap")

_Attach:AddToggle("AttachNearby",{Text="Attach to Nearby Players",Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AttachNearby and Tog.AttachNearby.Value do
                local myHRP=getHRP(); if not myHRP then task.wait(); continue end
                local range=Opt.MobsRange and Opt.MobsRange.Value or 1000
                for _,plr in ipairs(PS:GetPlayers()) do
                    if plr~=LP and plr.Character then
                        local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
                        local hum=plr.Character:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.Health>0 and (myHRP.Position-hrp.Position).Magnitude<=range then
                            local offset=CFrame.new(0, Opt.MobsHeight and Opt.MobsHeight.Value or 0, Opt.MobsDistance and Opt.MobsDistance.Value or 0)
                            tweenTo(hrp.CFrame * offset)
                        end
                    end
                end
                task.wait()
            end
        end)
    end}):AddKeyPicker("AttachNearbyKeybind",{Default="",SyncToggleState=true,Mode="Toggle",Text="Attach Nearby"})

_Attach:AddToggle("AttachSelected",{Text="Attach to Selected Player",Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AttachSelected and Tog.AttachSelected.Value do
                local myHRP=getHRP(); if not myHRP then task.wait(); continue end
                local val=Opt.AttachTargetPlayer and (type(Opt.AttachTargetPlayer.Value)=="table" and next(Opt.AttachTargetPlayer.Value) or Opt.AttachTargetPlayer.Value)
                local plr=type(val)=="string" and PS:FindFirstChild(val) or val
                if plr and plr~=LP and plr.Character then
                    local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
                    local hum=plr.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health>0 then
                        local offset=CFrame.new(0, Opt.MobsHeight and Opt.MobsHeight.Value or 0, Opt.MobsDistance and Opt.MobsDistance.Value or 0)
                        tweenTo(hrp.CFrame * offset)
                    end
                end
                task.wait()
            end
        end)
    end}):AddKeyPicker("AttachSelectedKeybind",{Default="",SyncToggleState=true,Mode="Toggle",Text="Attach Selected"})
_Attach:AddDropdown("AttachTargetPlayer",{SpecialType="Player",ExcludeLocalPlayer=true,Text="Attach Target",Callback=function() end})
_Range:AddSlider("MobsRange",{Text="Range",Default=1000,Min=0,Max=10000,Rounding=0,Compact=true})
_Range:AddSlider("MobsDistance",{Text="Distance",Default=0,Min=-50,Max=50,Rounding=0,Compact=true})
_Range:AddSlider("MobsHeight",{Text="Height",Default=0,Min=-50,Max=50,Rounding=0,Compact=true})

local nearbyConn=nil; local nearbyTracked={}
_MiscTools:AddToggle("NearbyNotifier",{Text="Nearby Players Notifier",Default=false,
    Callback=function(p)
        if nearbyConn then nearbyConn:Disconnect(); nearbyConn=nil end; nearbyTracked={}
        if not p then return end
        nearbyConn=RS.Heartbeat:Connect(function()
            local myHRP=getHRP(); if not myHRP then return end
            local dist=Opt.NearbyDist and Opt.NearbyDist.Value or 500
            for _,plr in ipairs(PS:GetPlayers()) do
                if plr~=LP and plr.Character then
                    local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local mag=(myHRP.Position-hrp.Position).Magnitude
                        if mag<=dist and not nearbyTracked[hrp] then
                            nearbyTracked[hrp]=true; notify(string.format("%s is nearby [%d]",plr.Name,mag),10)
                        elseif mag>dist and nearbyTracked[hrp] then
                            nearbyTracked[hrp]=nil; notify(string.format("%s left nearby [%d]",plr.Name,mag),10)
                        end
                    end
                end
            end
        end)
    end})
_MiscTools:AddSlider("NearbyDist",{Text="Notifier Distance",Default=500,Min=0,Max=10000,Rounding=0,Compact=true})
_MiscServer:AddButton({Text="Serverhop", Func=function()
    local ok,res=pcall(function() return HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")) end)
    if ok and res then for _,s in ipairs(res.data or {}) do if s.id~=game.JobId and s.playing<s.maxPlayers then TP:TeleportToPlaceInstance(game.PlaceId,s.id,LP); return end end end
    TP:Teleport(game.PlaceId,LP); notify("No servers found",3)
end})
_MiscServer:AddInput("MinPlayers",{Default="",Numeric=true,Finished=false,Text="Min Players",Placeholder="0"})
_MiscServer:AddButton({Text="Serverhop (Min Players)", Func=function()
    local minP=tonumber(Opt.MinPlayers and Opt.MinPlayers.Value) or 0
    local ok,res=pcall(function() return HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")) end)
    if ok and res then for _,s in ipairs(res.data or {}) do if s.id~=game.JobId and s.playing>=minP and s.playing<s.maxPlayers then TP:TeleportToPlaceInstance(game.PlaceId,s.id,LP); return end end end
    notify("No servers with "..minP.."+ players",3)
end})
_MiscServer:AddButton({Text="Rejoin", Func=function() TP:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end})
_MiscServer:AddInput("JobID",{Default="",Numeric=false,Finished=false,Text="JobID",Placeholder="Paste job id..."})
_MiscServer:AddButton({Text="Join Server", Func=function() local id=Opt.JobID and Opt.JobID.Value or ""; if id~="" then TP:TeleportToPlaceInstance(game.PlaceId,id,LP) end end})
_MiscServer:AddButton({Text="Copy Server JobId", Func=function() setclipboard(game.JobId); notify(game.JobId.." Copied!",5) end})
_MiscPerf:AddToggle("AntiLag",{Text="Anti-Lag",Default=false,
    Tooltip="Unlocks FPS, disables shadows, removes unnecessary rendering",
    Callback=function(p)
        pcall(function() setfpscap(p and 0 or 60) end)
        local LT3=game:GetService("Lighting")
        if p then
            LT3.GlobalShadows=false; LT3.Brightness=2
            for _,v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                    pcall(function() v.Enabled=false end)
                end
            end
        else
            LT3.GlobalShadows=true
        end
        notify("Anti-Lag "..(p and "ON" or "OFF"),2)
    end})
local _antiLagDep=_MiscPerf:AddDependencyBox()
_antiLagDep:AddSlider("AntiLagFPSCap",{Text="FPS Cap",Default=0,Min=0,Max=360,Rounding=0,Compact=true,
    Tooltip="0 = unlimited",
    Callback=function(v) pcall(function() setfpscap(v==0 and math.huge or v) end) end})
_antiLagDep:SetupDependencies({{Tog.AntiLag, true}})
_MiscPerf:AddButton({Text="Boost FPS", Func=function()
    pcall(function()
        for _,v in ipairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled=false end
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then v.Enabled=false end
        end
        LT.GlobalShadows=false; LT.Brightness=5; notify("FPS boost applied",3)
    end)
end})
_MiscTools:AddButton({Text="Copy Coordinates", Func=function()
    local hrp=getHRP(); if not hrp then return end
    local p=hrp.Position; local str=string.format("%.2f, %.2f, %.2f",p.X,p.Y,p.Z); setclipboard(str); notify("Copied: "..str)
end})

local specTarget=nil; local specConn=nil
local _WorldCam = Tabs.World:AddLeftGroupbox("Camera",     "video")

_WorldCam:AddDropdown("SpectatePlayers",{SpecialType="Player",Text="Spectate Player",Callback=function(v) specTarget=v end})
_WorldCam:AddButton({Text="Spectate / Stop", Func=function()
    if specConn then pcall(function() specConn:Disconnect() end); specConn=nil
        local c=getChar(); Cam.CameraSubject=c and c:FindFirstChildOfClass("Humanoid") or c; Cam.CameraType=Enum.CameraType.Custom; notify("Stopped"); return
    end
    local name=type(specTarget)=="table" and next(specTarget) or tostring(specTarget or "")
    local plr=PS:FindFirstChild(name); local char=plr and plr.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not hum then notify("Player not found",2); return end
    Cam.CameraSubject=hum; Cam.CameraType=Enum.CameraType.Custom
    specConn=plr.CharacterAdded:Connect(function(c) task.wait(0.5); local h=c:FindFirstChildOfClass("Humanoid"); if h then Cam.CameraSubject=h end end)
    notify("Spectating "..name)
end})

local noFogConn=nil
_WorldCam:AddToggle("NoFog",{Text="No Fog",Default=false,
    Tooltip="Removes fog and atmosphere haze without triggering anticheat",
    Callback=function(p)
        if noFogConn then noFogConn:Disconnect(); noFogConn=nil end
        local atmos = LT:FindFirstChildOfClass("Atmosphere")
        if p then
            LT.FogStart=1e9; LT.FogEnd=1e9
            if atmos then atmos.Density=0; atmos.Haze=0; atmos.Glare=0 end
            noFogConn = LT:GetPropertyChangedSignal("FogEnd"):Connect(function()
                if LT.FogEnd < 1e8 then LT.FogStart=1e9; LT.FogEnd=1e9 end
            end)
        else
            LT.FogStart=0; LT.FogEnd=100000
            if atmos then atmos.Density=0.395; atmos.Haze=0; atmos.Glare=0 end
        end
    end}):AddKeyPicker("NoFogKeybind",{Default="",SyncToggleState=true,Mode="Toggle",Text="No Fog Keybind"})

_WorldCam:AddToggle("NoAtmosphere",{Text="No Atmosphere",Default=false,
    Callback=function(p)
        pcall(function()
            local atmos = LT:FindFirstChildOfClass("Atmosphere")
            if not atmos then return end
            if p then
                atmos.Density=0; atmos.Offset=0; atmos.Haze=0; atmos.Glare=0
            else
                atmos.Density=0.395; atmos.Offset=0; atmos.Haze=0; atmos.Glare=0
            end
        end)
    end})

_WorldCam:AddToggle("FullBright",{Text="FullBright",Default=false,
    Callback=function(p)
        if fbConn then fbConn:Disconnect(); fbConn=nil end
        if p then fbConn=RS.RenderStepped:Connect(function() LT.Brightness=S.brightness; LT.ClockTime=14; LT.FogEnd=100000; LT.GlobalShadows=false; LT.OutdoorAmbient=Color3.fromRGB(128,128,128) end)
        else LT.Brightness=1; LT.ClockTime=14; LT.FogEnd=1000000; LT.GlobalShadows=true end
    end}):AddKeyPicker("FullBrightKeybind",{Default="",SyncToggleState=true,Mode="Toggle",Text="FullBright Keybind"})
_WorldCam:AddSlider("Brightness",{Text="Brightness",Default=2,Min=0,Max=10,Rounding=1,Compact=true,Callback=function(v) S.brightness=v end})

local freecamConns={}
_WorldCam:AddToggle("Freecam",{Text="Free Cam",Default=false,
    Callback=function(p)
        for _,c in ipairs(freecamConns) do pcall(function() c:Disconnect() end) end; freecamConns={}
        if not p then Cam.CameraType=Enum.CameraType.Custom; return end
        Cam.CameraType=Enum.CameraType.Scriptable
        local keys={}; local rmb=false
        table.insert(freecamConns, RS.RenderStepped:Connect(function()
            if rmb then
                local d=UIS:GetMouseDelta(); local cf=Cam.CFrame
                local ax=cf*CFrame.Angles(-math.rad(d.Y)*S.freeCamSens,0,0)
                Cam.CFrame=CFrame.Angles(0,-math.rad(d.X)*S.freeCamSens,0)*(ax-ax.Position)+ax.Position
                UIS.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition
            else UIS.MouseBehavior=Enum.MouseBehavior.Default end
            if keys["W"] then Cam.CFrame=Cam.CFrame*CFrame.new(0,0,-S.freeCamSpeed) end
            if keys["S"] then Cam.CFrame=Cam.CFrame*CFrame.new(0,0,S.freeCamSpeed) end
            if keys["A"] then Cam.CFrame=Cam.CFrame*CFrame.new(-S.freeCamSpeed,0,0) end
            if keys["D"] then Cam.CFrame=Cam.CFrame*CFrame.new(S.freeCamSpeed,0,0) end
        end))
        table.insert(freecamConns, UIS.InputBegan:Connect(function(inp)
            if inp.KeyCode==Enum.KeyCode.W then keys["W"]=true
            elseif inp.KeyCode==Enum.KeyCode.A then keys["A"]=true
            elseif inp.KeyCode==Enum.KeyCode.S then keys["S"]=true
            elseif inp.KeyCode==Enum.KeyCode.D then keys["D"]=true
            elseif inp.UserInputType==Enum.UserInputType.MouseButton2 then rmb=true end
        end))
        table.insert(freecamConns, UIS.InputEnded:Connect(function(inp)
            if inp.KeyCode==Enum.KeyCode.W then keys["W"]=false
            elseif inp.KeyCode==Enum.KeyCode.A then keys["A"]=false
            elseif inp.KeyCode==Enum.KeyCode.S then keys["S"]=false
            elseif inp.KeyCode==Enum.KeyCode.D then keys["D"]=false
            elseif inp.UserInputType==Enum.UserInputType.MouseButton2 then rmb=false end
        end))
    end}):AddKeyPicker("FreeCamKeybind",{Default="",SyncToggleState=true,Mode="Toggle",Text="Freecam Keybind"})
_WorldCam:AddSlider("FreeCamSens",{Text="Sensitivity",Default=0.3,Min=0,Max=5,Rounding=1,Compact=true,Callback=function(v) S.freeCamSens=v end})
_WorldCam:AddSlider("FreeCamSpeed",{Text="Speed",Default=0.5,Min=0,Max=50,Rounding=1,Compact=true,Callback=function(v) S.freeCamSpeed=v end})

local _VisualsL = Tabs.World:AddRightGroupbox("Visuals",   "sun")

_VisualsL:AddToggle("FOVChanger",{Text="FOV Changer",Default=false,
    Callback=function(p) if p then Cam.FieldOfView=S.fovVal else Cam.FieldOfView=70 end end})
_VisualsL:AddSlider("FOV",{Text="Camera FOV",Default=70,Min=0,Max=120,Rounding=1,Compact=true,Callback=function(v) S.fovVal=v; if Tog.FOVChanger and Tog.FOVChanger.Value then Cam.FieldOfView=v end end})

local _cursorRing = nil
_VisualsL:AddToggle("CustomCursor",{Text="Custom Cursor",Default=false,
    Callback=function(p)
        if _cursorConn then _cursorConn:Disconnect(); _cursorConn=nil end
        if _cursorDot  then _cursorDot:Remove();  _cursorDot=nil  end
        if _cursorRing then _cursorRing:Remove(); _cursorRing=nil end
        UIS.MouseIconEnabled = not p
        if not p then return end
        _cursorDot = Drawing.new("Circle")
        _cursorDot.Radius=6; _cursorDot.Filled=true; _cursorDot.Visible=true
        _cursorDot.Color=Color3.new(1,1,1); _cursorDot.Transparency=1; _cursorDot.Thickness=1
        _cursorRing = Drawing.new("Circle")
        _cursorRing.Radius=10; _cursorRing.Filled=false; _cursorRing.Visible=true
        _cursorRing.Color=Color3.new(1,1,1); _cursorRing.Transparency=0.8; _cursorRing.Thickness=1.5
        _cursorConn = RS.RenderStepped:Connect(function()
            local mp=UIS:GetMouseLocation()
            _cursorDot.Position=mp; _cursorRing.Position=mp
            local curCol = espColor or Color3.new(1,1,1)
            _cursorDot.Color=curCol; _cursorRing.Color=curCol
        end)
    end})
_VisualsL:AddToggle("CursorFilled",{Text="Cursor Dot Filled",Default=true,
    Callback=function(p) if _cursorDot then _cursorDot.Filled=p end end})
_VisualsL:AddSlider("CursorSize",{Text="Cursor Size",Default=6,Min=1,Max=20,Rounding=0,Compact=true,
    Callback=function(v) if _cursorDot then _cursorDot.Radius=v end end})
_VisualsL:AddSlider("CursorRingSize",{Text="Ring Size",Default=10,Min=0,Max=30,Rounding=0,Compact=true,
    Callback=function(v)
        if _cursorRing then _cursorRing.Radius=v end
    end})
_VisualsL:AddToggle("CustomCrosshair",{Text="Custom Crosshair",Default=false,
    Callback=function(p)
        if p then
            if not getgenv()._ZHCrosshair then
                local d=Drawing.new("Square")
                d.Size=Vector2.new(14,14); d.Position=Vector2.new(Cam.ViewportSize.X/2-7,Cam.ViewportSize.Y/2-7)
                d.Color=Color3.new(1,1,1); d.Transparency=1; d.Filled=false; d.Thickness=1; d.Visible=true
                local d2=Drawing.new("Line")
                d2.From=Vector2.new(Cam.ViewportSize.X/2-6,Cam.ViewportSize.Y/2)
                d2.To=Vector2.new(Cam.ViewportSize.X/2+6,Cam.ViewportSize.Y/2)
                d2.Color=Color3.new(1,1,1); d2.Thickness=1; d2.Visible=true
                local d3=Drawing.new("Line")
                d3.From=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2-6)
                d3.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2+6)
                d3.Color=Color3.new(1,1,1); d3.Thickness=1; d3.Visible=true
                getgenv()._ZHCrosshair={d,d2,d3}
            end
        else
            if getgenv()._ZHCrosshair then
                for _,d in ipairs(getgenv()._ZHCrosshair) do pcall(function() d:Remove() end) end
                getgenv()._ZHCrosshair=nil
            end
        end
    end})
_VisualsL:AddToggle("ClickTP",{Text="Click TP",Default=false,
    Callback=function(p)
        if clickTPConn then clickTPConn:Disconnect(); clickTPConn=nil end
        if p then clickTPConn=UIS.InputBegan:Connect(function(inp,gpe)
            if gpe or inp.UserInputType~=Enum.UserInputType.MouseButton2 then return end
            local ray=Cam:ScreenPointToRay(inp.Position.X,inp.Position.Y)
            local res=workspace:Raycast(ray.Origin,ray.Direction*2000)
            if res then local hrp=getHRP(); if hrp then hrp.CFrame=CFrame.new(res.Position+Vector3.new(0,3,0)); hrp.AssemblyLinearVelocity=Vector3.zero end end
        end) end
    end}):AddKeyPicker("ClickTPKeybind",{Default="",SyncToggleState=true,Mode="Toggle",Text="Click TP Keybind"})

local espEnabled        = false
local espColor          = Color3.fromRGB(255, 255, 255)
local espActive         = {}
local espConns          = {}
local tracerLines       = {}
local tracerConns       = {}
local tracerEnabled     = false
local espHighlight      = false
local espHighlightTrans = 0.5

local _plrESP  = { components={}, showName=true,  showHP=false, showDist=false }

local function removeESP(char)
    local d = espActive[char]; if not d then return end
    pcall(function() if d.txt     then d.txt:Remove()     end end)
    pcall(function() if d.box     then d.box:Remove()     end end)
    pcall(function() if d.hpFill  then d.hpFill:Remove()  end end)
    pcall(function() if d.hpBack  then d.hpBack:Remove()  end end)
    pcall(function() if d.tracer  then d.tracer:Remove()  end end)
    pcall(function() if d.dot     then d.dot:Remove()     end end)
    pcall(function() if d.hl      then d.hl:Destroy()     end end)
    if d.rname   then pcall(function() RS:UnbindFromRenderStep(d.rname) end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    if d.dieConn then pcall(function() d.dieConn:Disconnect() end) end
    espActive[char] = nil
end

local function addESP(char, plr)
    if not char or espActive[char] then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not (hum and hrp and head) then return end

    local txt    = Drawing.new("Text");   txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
    local box    = Drawing.new("Square"); box.Filled=false; box.Thickness=1.5; box.Visible=false
    local hpFill = Drawing.new("Square"); hpFill.Filled=true;  hpFill.Visible=false
    local hpBack = Drawing.new("Square"); hpBack.Filled=false; hpBack.Thickness=1; hpBack.Color=Color3.new(0,0,0); hpBack.Visible=false
    local tracer = Drawing.new("Line");   tracer.Thickness=1; tracer.Visible=false
    local dot    = Drawing.new("Circle"); dot.Radius=4; dot.Filled=true; dot.Visible=false; dot.Thickness=1

    local hl = Instance.new("Highlight", char)
    hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false

    local rname = "ZH_ESP_"..char:GetDebugId()
    RS:BindToRenderStep(rname, Enum.RenderPriority.Camera.Value+1, function()
        if not (espEnabled and char and char.Parent) then removeESP(char); return end

        local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local dist = (hrp.Position - myHRP.Position).Magnitude
        local maxDist = S.espDist or 1000

        local col = espColor or Color3.new(1,1,1)

        if dist > maxDist then
            txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false
            tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return
        end

        local components = _plrESP.components or {}
        local hasText      = components["Text"]
        local hasBox       = components["Box 2D"]
        local hasHP        = components["HP Bar"]
        local hasTracer    = components["Tracer"]
        local hasHighlight = components["Highlight"]
        local hasDot       = components["Head Dot"]

        local sv, onS  = Cam:WorldToViewportPoint(hrp.Position)
        local hv, onH  = Cam:WorldToViewportPoint(head.Position)
        if not onS then
            txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false
            tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return
        end

        local scale = math.clamp(1 / (sv.Z * 0.04), 0.5, 3)
        local bw    = 35  * scale
        local bh    = 70  * scale
        local bx    = sv.X - bw/2
        local by    = sv.Y - bh/2

        local hpPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local hpCol = Color3.fromHSV(hpPct * 0.33, 1, 1)

        if hasBox then
            box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true
        else box.Visible=false end

        if hasHP then
            local barW  = 6
            local barX  = bx - barW - 3
            hpBack.Position=Vector2.new(barX-1,by-1); hpBack.Size=Vector2.new(barW+2,bh+2); hpBack.Visible=true
            hpFill.Position=Vector2.new(barX,by+bh*(1-hpPct)); hpFill.Size=Vector2.new(barW,bh*hpPct); hpFill.Color=hpCol; hpFill.Visible=true
        else hpFill.Visible=false; hpBack.Visible=false end

        if hasText then
            local parts = {}
            local name = (plr and plr.DisplayName) or char.Name
            if _plrESP.showName then table.insert(parts, name) end
            if _plrESP.showHP   then table.insert(parts, string.format("[%d/%d]", hum.Health, hum.MaxHealth)) end
            if _plrESP.showDist then table.insert(parts, string.format("[%.0fm]", dist)) end
            txt.Text = table.concat(parts, " ")
            txt.Color = col
            txt.Size  = S.espFontSize or 14
            txt.Position = Vector2.new(sv.X, by - (S.espFontSize or 14) - 2)
            txt.Visible = #parts > 0
        else txt.Visible=false end

        if hasTracer then
            tracer.From = Vector2.new(sv.X, sv.Y)
            tracer.To   = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
            tracer.Color = col; tracer.Thickness = S.tracerThick or 1; tracer.Visible=true
        else tracer.Visible=false end

        if hasDot and onH then
            dot.Position=Vector2.new(hv.X, hv.Y); dot.Color=col; dot.Visible=true
        else dot.Visible=false end

        hl.Enabled          = hasHighlight and espEnabled
        hl.FillColor        = col
        hl.OutlineColor     = col
        hl.FillTransparency = S.hlFillTrans or 0.5
        hl.OutlineTransparency = S.hlOutlineTrans or 0
    end)

    espActive[char] = {
        txt=txt, box=box, hpFill=hpFill, hpBack=hpBack, tracer=tracer, dot=dot, hl=hl,
        rname   = rname,
        ancConn = char.AncestryChanged:Connect(function(_,p) if not p then removeESP(char) end end),
        dieConn = hum.Died:Connect(function() task.wait(3); removeESP(char) end),
    }
end

local _hue = 0

local _PlayerESP = Tabs.Visuals:AddLeftGroupbox("Player ESP","user-check")

_PlayerESP:AddToggle("PlayerESPEnabled", {
    Text="Enable", Default=false,
    Callback=function(p)
        espEnabled=p
        if p then
            local function hook(plr)
                if plr==LP then return end
                if plr.Character then task.spawn(addESP,plr.Character,plr) end
                table.insert(espConns,plr.CharacterAdded:Connect(function(c) task.wait(0.25); addESP(c,plr) end))
            end
            for _,plr in ipairs(PS:GetPlayers()) do hook(plr) end
            table.insert(espConns,PS.PlayerAdded:Connect(hook))
            table.insert(espConns,PS.PlayerRemoving:Connect(function(plr) if plr.Character then removeESP(plr.Character) end end))
        else
            for _,conn in ipairs(espConns) do pcall(function() conn:Disconnect() end) end
            espConns={}
            for char in pairs(espActive) do removeESP(char) end
        end
    end
}):AddColorPicker("ESPColor",{Default=Color3.fromRGB(255,255,255),Title="Color",Transparency=0,
    Callback=function(col) espColor=col end
}):AddKeyPicker("ESPToggleKey",{Default="",SyncToggleState=true,Mode="Toggle",Text="ESP Toggle"})
_PlayerESP:AddToggle("ESPRainbow",  {Text="Rainbow",  Default=false, Callback=function(p) S.espRainbow=p  end})
_PlayerESP:AddToggle("ESPShowName", {Text="Name",     Default=false, Callback=function(p) _plrESP.showName=p end})
_PlayerESP:AddToggle("ESPShowHP",   {Text="Health",   Default=false, Callback=function(p) _plrESP.showHP=p   end})
_PlayerESP:AddToggle("ESPShowDist", {Text="Distance", Default=false, Callback=function(p) _plrESP.showDist=p end})
_PlayerESP:AddDropdown("PlrESPComponents",{Text="Components",Multi=true,Default={},
    Values={"Text","Highlight","Tracer","Box 2D","HP Bar","Head Dot"},
    Callback=function(v) _plrESP.components=v end})
local _ESPSettings = Tabs.Visuals:AddRightGroupbox("ESP Settings","sliders-horizontal")

_ESPSettings:AddDivider()
_ESPSettings:AddLabel("Range")
_ESPSettings:AddSlider("ESPDist",{Text="Max Distance",Default=1000,Min=0,Max=10000,Rounding=0,Compact=true,
    Callback=function(v) S.espDist=v end})

_ESPSettings:AddDivider()
_ESPSettings:AddLabel("Highlight")
_ESPSettings:AddSlider("HLFillTrans",{Text="Fill Transparency",Default=0.5,Min=0,Max=1,Rounding=2,Compact=true,
    Callback=function(v) S.hlFillTrans=v end})
_ESPSettings:AddSlider("HLOutlineTrans",{Text="Outline Transparency",Default=0,Min=0,Max=1,Rounding=2,Compact=true,
    Callback=function(v) S.hlOutlineTrans=v end})

_ESPSettings:AddDivider()
_ESPSettings:AddLabel("Tracer")
_ESPSettings:AddSlider("TracerThick",{Text="Thickness",Default=1,Min=1,Max=5,Rounding=1,Compact=true,
    Callback=function(v) S.tracerThick=v end})

_ESPSettings:AddDivider()
_ESPSettings:AddLabel("Anti-Lag")
_ESPSettings:AddToggle("ESPAntiLag",{Text="Anti-Lag",Default=true,
    Callback=function(p) S.espAntiLag=p end})
_ESPSettings:AddLabel("Disables ESP when FPS < 30")

local _mobESPActive  = {}; local _mobESPEnabled = false
local mobESPColor2   = Color3.fromRGB(255,100,100)
local _mobESP2       = {components={}, showName=false, showHP=false, showDist=false, rainbow=false}

local function removeMobESP(mob)
    local d = _mobESPActive[mob]; if not d then return end
    pcall(function() if d.txt    then d.txt:Remove()    end end)
    pcall(function() if d.box    then d.box:Remove()    end end)
    pcall(function() if d.hpFill then d.hpFill:Remove() end end)
    pcall(function() if d.hpBack then d.hpBack:Remove() end end)
    pcall(function() if d.tracer then d.tracer:Remove() end end)
    pcall(function() if d.dot    then d.dot:Remove()    end end)
    pcall(function() if d.hl     then d.hl:Destroy()    end end)
    if d.conn    then pcall(function() d.conn:Disconnect()    end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    _mobESPActive[mob] = nil
end

local function addMobESP(mob)
    if not mob or _mobESPActive[mob] then return end
    local hum  = mob:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local hrp  = mob:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local head = mob:FindFirstChild("Head")
    local txt    = Drawing.new("Text");   txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
    local box    = Drawing.new("Square"); box.Filled=false; box.Thickness=1.5; box.Visible=false
    local hpFill = Drawing.new("Square"); hpFill.Filled=true; hpFill.Visible=false
    local hpBack = Drawing.new("Square"); hpBack.Filled=false; hpBack.Thickness=1; hpBack.Color=Color3.new(0,0,0); hpBack.Visible=false
    local tracer = Drawing.new("Line");   tracer.Thickness=1; tracer.Visible=false
    local dot    = Drawing.new("Circle"); dot.Radius=4; dot.Filled=true; dot.Visible=false; dot.Thickness=1
    local hl     = Instance.new("Highlight",mob); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false
    local conn = RS.Heartbeat:Connect(function()
        if not (_mobESPEnabled and mob and mob.Parent) then removeMobESP(mob); return end
        local myHRP = getHRP(); if not myHRP then return end
        local col   = mobESPColor2
        local dist  = (hrp.Position - myHRP.Position).Magnitude
        local comps = _mobESP2.components or {}
        if dist > (S.espDist or 1000) then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local sv,onS = Cam:WorldToViewportPoint(hrp.Position)
        local hv,onH = head and Cam:WorldToViewportPoint(head.Position)
        if not onS then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local scale=math.clamp(1/(sv.Z*0.04),0.5,3); local bw=35*scale; local bh=70*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
        local hpPct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1); local hpCol=Color3.fromHSV(hpPct*0.33,1,1)
        if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
        if comps["HP Bar"] then local barW=6; local barX=bx-barW-3; hpBack.Position=Vector2.new(barX-1,by-1); hpBack.Size=Vector2.new(barW+2,bh+2); hpBack.Visible=true; hpFill.Position=Vector2.new(barX,by+bh*(1-hpPct)); hpFill.Size=Vector2.new(barW,bh*hpPct); hpFill.Color=hpCol; hpFill.Visible=true else hpFill.Visible=false; hpBack.Visible=false end
        if comps["Text"] then local parts={}; if _mobESP2.showName then table.insert(parts,mob.Name) end; if _mobESP2.showHP then table.insert(parts,string.format("[%d/%d]",hum.Health,hum.MaxHealth)) end; if _mobESP2.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end; txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14; txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0 else txt.Visible=false end
        if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
        if comps["Head Dot"] and onH and head then dot.Position=Vector2.new(hv.X,hv.Y); dot.Color=col; dot.Visible=true else dot.Visible=false end
        hl.Enabled=comps["Highlight"] and _mobESPEnabled or false; hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
    end)
    _mobESPActive[mob]={txt=txt,box=box,hpFill=hpFill,hpBack=hpBack,tracer=tracer,dot=dot,hl=hl,conn=conn,
        ancConn=mob.AncestryChanged:Connect(function(_,p) if not p then removeMobESP(mob) end end)}
end

local function scanMobESP()
    local living = workspace:FindFirstChild("Living"); if not living then return end
    for _, m in ipairs(living:GetChildren()) do
        if m:IsA("Model") and not PS:GetPlayerFromCharacter(m) then addMobESP(m) end
    end
end
local function stopMobESP() _mobESPEnabled=false; for mob in pairs(_mobESPActive) do removeMobESP(mob) end end

local _npcESPActive  = {}; local _npcESPEnabled = false
local npcESPColor2   = Color3.fromRGB(100,220,255)
local _npcESP2       = {components={}, showName=false, showDist=false, rainbow=false}

RS.Heartbeat:Connect(function(dt)
    _hue = (_hue + dt * 0.25) % 1
    local rc = Color3.fromHSV(_hue, 1, 1)
    if S.espRainbow      then espColor     = rc end
    if _mobESP2.rainbow  then mobESPColor2 = rc end
    if _npcESP2.rainbow  then npcESPColor2 = rc end
end)

local function removeNPCESP(npc)
    local d = _npcESPActive[npc]; if not d then return end
    pcall(function() if d.txt    then d.txt:Remove()    end end)
    pcall(function() if d.hl     then d.hl:Destroy()    end end)
    if d.conn    then pcall(function() d.conn:Disconnect()    end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    _npcESPActive[npc] = nil
end

local function addNPCESP(npc, label)
    if not npc or _npcESPActive[npc] then return end
    local hrp = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart; if not hrp then return end
    local txt = Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
    local hl  = Instance.new("Highlight",npc); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false
    local conn = RS.Heartbeat:Connect(function()
        if not (_npcESPEnabled and npc and npc.Parent) then removeNPCESP(npc); return end
        local myHRP = getHRP(); if not myHRP then return end
        local col  = npcESPColor2
        local dist = (hrp.Position - myHRP.Position).Magnitude
        local comps = _npcESP2.components or {}
        if dist > (S.espDist or 1000) then txt.Visible=false; hl.Enabled=false; return end
        local sv,onS = Cam:WorldToViewportPoint(hrp.Position)
        if not onS then txt.Visible=false; hl.Enabled=false; return end
        if comps["Text"] then local parts={}; if _npcESP2.showName then table.insert(parts,label or npc.Name) end; if _npcESP2.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end; txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14; txt.Position=Vector2.new(sv.X,sv.Y-20); txt.Visible=#parts>0 else txt.Visible=false end
        hl.Enabled=comps["Highlight"] and _npcESPEnabled or false; hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
    end)
    _npcESPActive[npc]={txt=txt,hl=hl,conn=conn,
        ancConn=npc.AncestryChanged:Connect(function(_,p) if not p then removeNPCESP(npc) end end)}
end

local function scanNPCESP()
    local npcs = workspace:FindFirstChild("NPCs"); if not npcs then return end
    for _, obj in ipairs(npcs:GetChildren()) do
        if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
            addNPCESP(obj, obj.Name)
        end
    end
end
local function stopNPCESP() _npcESPEnabled=false; for npc in pairs(_npcESPActive) do removeNPCESP(npc) end end

local _MobESP  = Tabs.Visuals:AddLeftGroupbox("Mob ESP",  "swords")
local _NPCYESP = Tabs.Visuals:AddRightGroupbox("NPC ESP", "user-round")

_MobESP:AddToggle("MobESPEnabled",{Text="Enable",Default=false,
    Callback=function(p)
        _mobESPEnabled=p
        if p then scanMobESP(); task.spawn(function() while _mobESPEnabled do task.wait(3); scanMobESP() end end)
        else stopMobESP() end
    end}):AddColorPicker("MobESPColor2",{Default=Color3.fromRGB(255,100,100),Title="Color",Transparency=0,
    Callback=function(c) mobESPColor2=c end})
_MobESP:AddToggle("MobESPRainbow2",  {Text="Rainbow",  Default=false, Callback=function(p) _mobESP2.rainbow=p  end})
_MobESP:AddToggle("MobESPShowName",  {Text="Name",     Default=false, Callback=function(p) _mobESP2.showName=p end})
_MobESP:AddToggle("MobESPShowHP",    {Text="Health",   Default=false, Callback=function(p) _mobESP2.showHP=p   end})
_MobESP:AddToggle("MobESPShowDist",  {Text="Distance", Default=false, Callback=function(p) _mobESP2.showDist=p end})
_MobESP:AddDropdown("MobESPComponents",{Text="Components",Multi=true,Default={},
    Values={"Text","Highlight","Tracer","Box 2D","HP Bar","Head Dot"},
    Callback=function(v) _mobESP2.components=v end})
Library.OnUnload(function() stopMobESP() end)

_NPCYESP:AddToggle("NPCESPEnabled",{Text="Enable",Default=false,
    Callback=function(p)
        _npcESPEnabled=p
        if p then scanNPCESP(); task.spawn(function() while _npcESPEnabled do task.wait(3); scanNPCESP() end end)
        else stopNPCESP() end
    end}):AddColorPicker("NpcESPColor2",{Default=Color3.fromRGB(100,220,255),Title="Color",Transparency=0,
    Callback=function(c) npcESPColor2=c end})
_NPCYESP:AddToggle("NpcESPRainbow2",  {Text="Rainbow",  Default=false, Callback=function(p) _npcESP2.rainbow=p  end})
_NPCYESP:AddToggle("NpcESPShowName",  {Text="Name",     Default=false, Callback=function(p) _npcESP2.showName=p end})
_NPCYESP:AddToggle("NpcESPShowDist",  {Text="Distance", Default=false, Callback=function(p) _npcESP2.showDist=p end})
_NPCYESP:AddDropdown("NpcESPComponents",{Text="Components",Multi=true,Default={},
    Values={"Text","Highlight","Tracer","Box 2D","HP Bar","Head Dot"},
    Callback=function(v) _npcESP2.components=v end})
Library.OnUnload(function() stopNPCESP() end)

local _Settings    = Tabs.Settings:AddLeftGroupbox("Settings", "sliders-horizontal")

_Settings:AddDropdown("TweenMode",{Values={"Normal","Safe"},Default=1,Multi=false,Text="Tween Mode"})
_Settings:AddSlider("TweenSpeed",{Text="Tween Speed",Default=100,Min=0,Max=700,Rounding=0,Compact=true})
_Settings:AddSlider("SafeModeHeight",{Text="Safe Mode Height",Default=1000,Min=0,Max=100000,Rounding=0,Compact=true})
_Settings:AddDropdown("FlyMode",{Values={"MoveDirection","Camera LookVector"},Default=2,Multi=false,Text="Fly Mode"})

local _UISettings  = Tabs.Settings:AddRightGroupbox("UI", "layout-dashboard")

_UISettings:AddButton({Text="Unload", Func=function() Library:Unload() end})
_UISettings:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind",{Default="End",NoUI=true,Text="Menu Keybind"})
Library.ToggleKeybind=Library.Options.MenuKeybind
_UISettings:AddToggle("KeybindPanel",{Text="Keybinds Menu",Default=true,
    Callback=function(p) if Library.KeybindFrame then Library.KeybindFrame.Visible=p end end})

Library.OnUnload(function()
    RS:UnbindFromRenderStep("VVUSpeed"); RS:UnbindFromRenderStep("AUTFly")
    for char,_ in pairs(espActive) do removeESP(char) end
    for _,line in pairs(tracerLines) do pcall(function() line:Remove() end) end
    for _,c in ipairs(freecamConns) do pcall(function() c:Disconnect() end) end
    if chatGui then chatGui:Destroy() end
    if _cursorConn  then _cursorConn:Disconnect() end
    if _cursorDot   then pcall(function() _cursorDot:Remove()  end) end
    if _cursorRing  then pcall(function() _cursorRing:Remove() end) end
    UIS.MouseIconEnabled = true
end)

ThemeManager:SetLibrary(Library)
ThemeManager:SetDefaultTheme({
    AccentColor     = Color3.fromRGB(114, 72, 122),
    MainColor       = Color3.fromRGB(18, 10, 28),
    BackgroundColor = Color3.fromRGB(21, 15, 29),
    OutlineColor    = Color3.fromRGB(80, 35, 130),
    FontColor       = Color3.fromRGB(255, 255, 255),
})

ThemeManager:SetFolder("ZeroHub/aut")
SaveManager:SetIgnoreIndexes({})
SaveManager:SetFolder("ZeroHub/aut_configs")
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:ApplyToGroupbox(Tabs.Settings:AddLeftGroupbox("Theme", "palette"))

do
    local _Morphs  = Tabs.Main:AddLeftGroupbox("Morphs", "sparkles")

    local function removeClothingAndHead(char)
        if not char then return end
        pcall(function()
            for _, cls in ipairs({"Shirt","Pants"}) do
                local v = char:FindFirstChildOfClass(cls); if v then v:Destroy() end
            end
            for _, v in ipairs(char:GetChildren()) do
                if v:IsA("Accessory") then pcall(function() v:Destroy() end) end
            end
            local head = char:FindFirstChild("Head")
            if head then
                head.Transparency = 1
                for _, v in ipairs(head:GetDescendants()) do if v:IsA("Decal") then v:Destroy() end end
            end
        end)
    end

    local function attachAccessory(assetId, char, offset, rotation)
        if not char or not assetId then return end
        pcall(function()
            local obj = game:GetObjects("rbxassetid://"..tostring(assetId))[1]; if not obj then return end
            local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"); if not torso then return end
            obj.Parent = char
            local handle = obj:FindFirstChild("Handle"); if not handle then return end
            local weld = Instance.new("Weld")
            weld.Part0 = torso; weld.Part1 = handle
            weld.C0 = CFrame.new(offset or Vector3.zero) * CFrame.Angles(
                math.rad(rotation and rotation.X or 0),
                math.rad(rotation and rotation.Y or 0),
                math.rad(rotation and rotation.Z or 0))
            weld.Parent = handle; handle.Anchored = false
        end)
    end

    local function setShirtPants(shirtId, pantsId, char)
        if not char then return end
        pcall(function()
            if shirtId then
                local s = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
                s.ShirtTemplate = "rbxassetid://"..tostring(shirtId)
            end
            if pantsId then
                local p = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)
                p.PantsTemplate = "rbxassetid://"..tostring(pantsId)
            end
        end)
    end

    local MORPHS = {
        ["None"]        = nil,
        ["Goku"]        = function(c) removeClothingAndHead(c); attachAccessory(96778240725860,  c, Vector3.new(0,2.3,0)); setShirtPants(18642081551,     13980707182,     c) end,
        ["Naruto"]      = function(c) removeClothingAndHead(c); attachAccessory(129818847988995, c, Vector3.new(0,1.8,0), Vector3.new(0,-90,0)); setShirtPants(6469644436, 2733834231, c) end,
        ["Gojo"]        = function(c) removeClothingAndHead(c); attachAccessory(132501783778842, c, Vector3.new(0,1.9,0)); setShirtPants(73084050138865,   15312673306,     c) end,
        ["Toji"]        = function(c) removeClothingAndHead(c); attachAccessory(135664715112347, c, Vector3.new(0,1.7,0)); setShirtPants(121088463088431,  16149857407,     c) end,
        ["Aizen"]       = function(c) removeClothingAndHead(c); attachAccessory(117644781784979, c, Vector3.new(0,1.7,0)); setShirtPants(87853669951881,   118029167731205, c) end,
        ["Guts"]        = function(c) removeClothingAndHead(c); attachAccessory(117337600216775, c, Vector3.new(0,1.6,0)); setShirtPants(13381096342,      13381103162,     c) end,
        ["Vasto Lorde"] = function(c) removeClothingAndHead(c); attachAccessory(107798985962651, c, Vector3.new(0,1.7,0)); setShirtPants(15549196125,      15886594659,     c) end,
        ["Luffy"]       = function(c) removeClothingAndHead(c); attachAccessory(103832443149308, c, Vector3.new(0,1.5,0)); setShirtPants(8483860912,       6274345723,      c) end,
        ["Zero Two"]    = function(c) removeClothingAndHead(c); attachAccessory(93023559996037,  c, Vector3.new(0,1.2,0)); setShirtPants(6392201226,       5896597102,      c) end,
    }

    local morphNames = {"None"}
    for k in pairs(MORPHS) do if k ~= "None" then table.insert(morphNames, k) end end
    table.sort(morphNames)

    _Morphs:AddDropdown("MorphSelect", {
        Text="Morph", Values=morphNames, Default=1, Multi=false,
        Callback=function(v)
            local sel = type(v)=="table" and next(v) or v
            if sel == "None" or not sel then return end
            local fn = MORPHS[sel]; if not fn then return end
            local c = LP and LP.Character; if not c then notify("No character",2); return end
            fn(c); notify("Morph: "..sel, 3)
        end})
    pcall(function()
        local _morphVP = _Morphs:AddViewport("MorphPreview", {
            Height=120, AutoFocus=true, Interactive=true, Clone=true,
        })
        getgenv()._ZHMorphVP = _morphVP
    end)

    _Morphs:AddButton({Text="Reset", Func=function()
        pcall(function()
            local char = LP and LP.Character; if not char then return end
            local head = char:FindFirstChild("Head")
            if head then head.Transparency = 0 end
            notify("Reload character to fully reset", 3)
        end)
    end})
end

local _MiscBypass = Tabs.Misc:AddLeftGroupbox("Bypass Scripts", "terminal")

local _invMenuConn = nil
_MiscBypass:AddToggle("BypassInventory", {Text="Open Inventory Menu", Default=false,
    Callback=function(p)
        if _invMenuConn then _invMenuConn:Disconnect(); _invMenuConn = nil end
        if not p then
            pcall(function()
                LP.PlayerGui.UI.Menus.Visible = false
                LP.PlayerGui.UI.Menus.Inventory.Visible = false
            end)
            return
        end
        _invMenuConn = RS.Heartbeat:Connect(function()
            if not (Tog.BypassInventory and Tog.BypassInventory.Value) then
                if _invMenuConn then _invMenuConn:Disconnect(); _invMenuConn = nil end; return
            end
            pcall(function()
                LP.PlayerGui.UI.Menus.Visible = true
                LP.PlayerGui.UI.Menus.Inventory.Visible = true
            end)
        end)
    end})

_MiscBypass:AddButton({Text="Open Ability Menu", Func=function()
    pcall(function()
        LP.PlayerGui.UI.Menus.Visible = not LP.PlayerGui.UI.Menus.Visible
        LP.PlayerGui.UI.Menus.Ability.Visible = not LP.PlayerGui.UI.Menus.Ability.Visible
    end)
end})

_MiscBypass:AddButton({Text="Open Shop Menu", Func=function()
    pcall(function()
        LP.PlayerGui.UI.Menus.Visible = not LP.PlayerGui.UI.Menus.Visible
        LP.PlayerGui.UI.Menus.Products.Visible = not LP.PlayerGui.UI.Menus.Products.Visible
    end)
end})

_MiscBypass:AddButton({Text="Open Quest Menu", Func=function()
    pcall(function()
        LP.PlayerGui.UI.Menus.Visible = not LP.PlayerGui.UI.Menus.Visible
        LP.PlayerGui.UI.Menus.Quests.Visible = not LP.PlayerGui.UI.Menus.Quests.Visible
    end)
end})

_MiscBypass:AddButton({Text="Open Crafting Menu", Func=function()
    pcall(function()
        LP.PlayerGui.UI.Gameplay.Crafting.Visible = not LP.PlayerGui.UI.Gameplay.Crafting.Visible
    end)
end})

_MiscBypass:AddButton({Text="Respawn Character", Func=function()
    pcall(function()
        local loc = LP.Character.HumanoidRootPart.CFrame
        LP.Character.Humanoid:ChangeState(15)
        LP.CharacterAdded:Wait()
        repeat task.wait(0.15) until LP.Character:FindFirstChild("HumanoidRootPart")
        task.wait(0.5)
        LP.Character.HumanoidRootPart.CFrame = loc
    end)
end})

_MiscBypass:AddButton({Text="Reset Character", Func=function()
    pcall(function() LP.Character.Humanoid:ChangeState(15) end)
end})

local _questFarmingBossesDropdown
local _questFarmingMobDropdown

local _QuestList = Tabs.Quests:AddLeftGroupbox("Quests List", "scroll-text")

local _questStatusLabel = _QuestList:AddLabel("No active quests.")
task.spawn(function()
    while true do
        task.wait(0.75)
        pcall(function()
            local lines = LP:WaitForChild("QuestLines"):GetChildren()
            if #lines == 0 then
                _questStatusLabel:SetText("No active quests.")
            else
                local names = {}
                for _, q in ipairs(lines) do
                    table.insert(names, q.Name)
                end
                _questStatusLabel:SetText(table.concat(names, "\n"))
            end
        end)
    end
end)

_QuestList:AddButton({Text="Open Quest Menu", Func=function()
    pcall(function()
        LP.PlayerGui.UI.Menus.Visible = not LP.PlayerGui.UI.Menus.Visible
        LP.PlayerGui.UI.Menus.Quests.Visible = not LP.PlayerGui.UI.Menus.Quests.Visible
    end)
end})

local _QuestSettings = Tabs.Quests:AddRightGroupbox("Quest Settings", "settings-2")

_QuestSettings:AddLabel("1. Only one quest at a time.")
_QuestSettings:AddDivider()
_QuestSettings:AddLabel("2. Enable Auto Stats or Auto Collect Rewards.")
_QuestSettings:AddDivider()
_QuestSettings:AddLabel("3. Don't use Farming tab during a quest.")
_QuestSettings:AddDivider()
_QuestSettings:AddLabel("4. Item farm auto-enables during quests.")
_QuestSettings:AddDivider()
_QuestSettings:AddLabel("5. Press Start Auto Quest to begin.")
_QuestSettings:AddDivider()
_QuestSettings:AddLabel("6. To stop: disable quest + Clear Config.")
_QuestSettings:AddDivider()
_QuestSettings:AddLabel("7. Auto Quest stopping = doing non-mob tasks.")
_QuestSettings:AddDivider()

local _startQuestToggle
_startQuestToggle = _QuestSettings:AddToggle("StartAutoQuest", {Text="Start Auto Quest", Default=false,
    Callback=function(p)
        if not p then return end
        if Tog.StartFarmingMobs    and not Tog.StartFarmingMobs.Value    then pcall(function() Tog.StartFarmingMobs:SetValue(true)    end) end
        if Tog.StartFarmingItems   and not Tog.StartFarmingItems.Value   then pcall(function() Tog.StartFarmingItems:SetValue(true)   end) end
        if Tog.AutoSellInventory   and not Tog.AutoSellInventory.Value   then pcall(function() Tog.AutoSellInventory:SetValue(true)   end) end
        if Tog.AutoStoreItems      and not Tog.AutoStoreItems.Value      then pcall(function() Tog.AutoStoreItems:SetValue(true)      end) end
        if Tog.AutoCollectChests   and not Tog.AutoCollectChests.Value   then pcall(function() Tog.AutoCollectChests:SetValue(true)   end) end
        if Tog.AutoEquipSpecs      and not Tog.AutoEquipSpecs.Value      then pcall(function() Tog.AutoEquipSpecs:SetValue(true)      end) end
        notify("Quest session started!", 4)
    end})

_QuestSettings:AddButton({Text="Clear Quest Config", Func=function()
    pcall(function() _startQuestToggle:SetValue(false) end)
    for _, key in ipairs({"StartFarmingMobs","StartFarmingItems","AutoSellInventory","AutoStoreItems","AutoCollectChests","AutoEquipSpecs"}) do
        pcall(function() if Tog[key] then Tog[key]:SetValue(false) end end)
    end
    notify("Quest session cleared.", 3)
end})

local _QuestBosses = Tabs.Quests:AddRightGroupbox("Auto Bosses", "swords")

local function _qBossLoop(toggleKey, questArgs, bossSelFn)
    task.spawn(function()
        while Tog[toggleKey] and Tog[toggleKey].Value do
            pcall(function()
                game:GetService("ReplicatedStorage")
                    :WaitForChild("ReplicatedModules"):WaitForChild("KnitPackage"):WaitForChild("Knit")
                    :WaitForChild("Services"):WaitForChild("DialogueService"):WaitForChild("RF")
                    :WaitForChild("CheckDialogue"):InvokeServer(unpack(questArgs))
            end)
            task.wait(5)
        end
    end)
    if bossSelFn then task.spawn(bossSelFn) end
end

_QuestBosses:AddToggle("AutofarmDragonKnight", {Text="Autofarm Dragon Knight", Default=false,
    Callback=function(p)
        if not p then return end
        _qBossLoop("AutofarmDragonKnight",
            {"Slayer_Quest","Dragon Knight"},
            function()
                if Opt.FarmingBossesSelect then pcall(function() Opt.FarmingBossesSelect:SetValue({["The Knight"]=true}) end) end
                if Opt.FarmingMobSelect    then pcall(function() Opt.FarmingMobSelect:SetValue("Guardians") end) end
            end)
    end})

_QuestBosses:AddToggle("AutofarmTheBearer", {Text="Autofarm The Bearer", Default=false,
    Callback=function(p)
        if not p then return end
        _qBossLoop("AutofarmTheBearer",
            {"Slayer_Quest","Finger Bearer"},
            function()
                if Opt.FarmingBossesSelect then pcall(function() Opt.FarmingBossesSelect:SetValue({["The Bearer"]=true}) end) end
                if Opt.FarmingMobSelect    then pcall(function() Opt.FarmingMobSelect:SetValue("Curses") end) end
                if Opt.StoreItemsSelect    then pcall(function() Opt.StoreItemsSelect:SetValue({["Sukuna's Finger"]=true}) end) end
                if Opt.ExcludeItemsSelect  then pcall(function() Opt.ExcludeItemsSelect:SetValue({["Sukuna's Finger"]=true}) end) end
            end)
    end})

_QuestBosses:AddToggle("AutofarmKuroKuro", {Text="Autofarm Kuro Kuro", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AutofarmKuroKuro and Tog.AutofarmKuroKuro.Value do
                pcall(function()
                    game:GetService("ReplicatedStorage").ReplicatedModules.KnitPackage.Knit.Services.DialogueService.RF.CheckDialogue
                        :InvokeServer("Save_The_Village_Adventure")
                end)
                task.wait(5)
            end
        end)
        task.spawn(function()
            if Opt.FarmingBossesSelect then pcall(function() Opt.FarmingBossesSelect:SetValue({["Kuro"]=true}) end) end
            if Opt.FarmingMobSelect    then pcall(function() Opt.FarmingMobSelect:SetValue("Curses") end) end
        end)
    end})

_QuestBosses:AddToggle("AutofarmGojoHalf", {Text="Autofarm Gojo Half", Default=false,
    Callback=function(p)
        if not p then return end
        _qBossLoop("AutofarmGojoHalf",
            {"Slayer_Quest","Gojo"},
            function()
                if Opt.FarmingBossesSelect then pcall(function() Opt.FarmingBossesSelect:SetValue({["Gojo"]=true}) end) end
                if Opt.FarmingMobSelect    then pcall(function() Opt.FarmingMobSelect:SetValue("Curses") end) end
            end)
    end})

local _QuestHakis = Tabs.Quests:AddLeftGroupbox("Auto Hakis", "zap")

local _dialogueRF = function(...)
    local args = {...}
    pcall(function()
        game:GetService("ReplicatedStorage").ReplicatedModules.KnitPackage.Knit.Services.DialogueService.RF.CheckDialogue
            :InvokeServer(unpack(args))
    end)
end

_QuestHakis:AddToggle("AutofarmBusoHaki", {Text="Autofarm Busoshoku Haki", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AutofarmBusoHaki and Tog.AutofarmBusoHaki.Value do
                _dialogueRF("Agent's Secret"); task.wait(0.35)
            end
        end)
        task.spawn(function()
            while Tog.AutofarmBusoHaki and Tog.AutofarmBusoHaki.Value do
                pcall(function()
                    if LP.QuestLines["Agent's Secret"]["Agent's Secret"]["Defeat [Kuro]"].Value ~= 1 then
                        if Opt.FarmingBossesSelect then Opt.FarmingBossesSelect:SetValue({["Kuro"]=true}) end
                        _dialogueRF("Save_The_Village_Adventure")
                    elseif LP.QuestLines["Agent's Secret"]["Agent's Secret"]["Defeat [Pirate]"].Value ~= 100 then
                        if Opt.FarmingMobSelect then Opt.FarmingMobSelect:SetValue("Pirates") end
                    else
                        if Opt.FarmingMobSelect then Opt.FarmingMobSelect:SetValue("Curses") end
                    end
                end)
                task.wait(1)
            end
        end)
    end})

_QuestHakis:AddToggle("AutofarmKenHaki", {Text="Autofarm Kenbunshoku Haki", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AutofarmKenHaki and Tog.AutofarmKenHaki.Value do
                _dialogueRF("Muri's Venture"); task.wait(0.35)
            end
        end)
        task.spawn(function()
            while Tog.AutofarmKenHaki and Tog.AutofarmKenHaki.Value do
                pcall(function()
                    if LP.QuestLines["Muri's Venture"]["Muri's Venture"]["Defeat [Crocodile]"].Value ~= 1 then
                        if Opt.FarmingBossesSelect then Opt.FarmingBossesSelect:SetValue({["Surgeon of Death"]=true,["Tower"]=true,["Crocodile"]=true}) end
                        if Opt.FarmingMobSelect    then Opt.FarmingMobSelect:SetValue("Pirates") end
                    elseif LP.QuestLines["Muri's Venture"]["Muri's Venture"]["Defeat [Pirate]"].Value ~= 250 then
                        if Opt.FarmingMobSelect then Opt.FarmingMobSelect:SetValue("Pirates") end
                    else
                        if Opt.FarmingMobSelect then Opt.FarmingMobSelect:SetValue("Curses") end
                    end
                end)
                task.wait(1)
            end
        end)
    end})

_QuestHakis:AddToggle("AutofarmHaoHaki", {Text="Autofarm Haoshoku Haki", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AutofarmHaoHaki and Tog.AutofarmHaoHaki.Value do
                _dialogueRF("Bob's Sacred Path"); task.wait(0.35)
            end
        end)
        task.spawn(function()
            while Tog.AutofarmHaoHaki and Tog.AutofarmHaoHaki.Value do
                pcall(function()
                    if LP.QuestLines["Bob's Sacred Path"]["Bob's Sacred Path"]["Defeat [Pirate]"].Value ~= 500 then
                        if Opt.FarmingBossesSelect then Opt.FarmingBossesSelect:SetValue({["Surgeon of Death"]=true,["Shanks"]=true,["Luffy"]=true,["Whitebeard"]=true}) end
                        if Opt.FarmingMobSelect    then Opt.FarmingMobSelect:SetValue("Pirates") end
                    else
                        if Opt.FarmingMobSelect then Opt.FarmingMobSelect:SetValue("Curses") end
                    end
                end)
                task.wait(1)
            end
        end)
    end})

local _QuestSpecs = Tabs.Quests:AddLeftGroupbox("Auto Specs", "star")

local _cmoonToggle
_cmoonToggle = _QuestSpecs:AddToggle("AutofarmCMoonMIH", {Text="Auto CMoon / MIH Quest", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            pcall(function()
                local abilityName = LP:WaitForChild("Data"):WaitForChild("Ability"):GetAttribute("AbilityName")
                if abilityName ~= "White Snake" and abilityName ~= "C-Moon" then
                    _cmoonToggle:SetValue(false)
                    notify("Requires White Snake or C-Moon", 4)
                    return
                end
            end)
        end)
        task.wait(0.35)
        task.spawn(function()
            while Tog.AutofarmCMoonMIH and Tog.AutofarmCMoonMIH.Value do
                _dialogueRF("C-Moon Quest")
                _dialogueRF("MIH Quest")
                task.wait(5)
            end
        end)
    end})

local _twohToggle
_twohToggle = _QuestSpecs:AddToggle("AutofarmTWOH", {Text="Autofarm TWOH Quest", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            pcall(function()
                local abilityName = LP:WaitForChild("Data"):WaitForChild("Ability"):GetAttribute("AbilityName")
                if abilityName ~= "The World" then
                    _twohToggle:SetValue(false)
                    notify("Requires The World", 4)
                    return
                end
            end)
        end)
        task.spawn(function()
            while Tog.AutofarmTWOH and Tog.AutofarmTWOH.Value do
                _dialogueRF("TWOH Quest"); task.wait(5)
            end
        end)
    end})

local _killuaToggle
_killuaToggle = _QuestSpecs:AddToggle("AutofarmKillua", {Text="Auto Killua Quest", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            pcall(function()
                local abilityName = LP:WaitForChild("Data"):WaitForChild("Ability"):GetAttribute("AbilityName")
                if abilityName ~= "Standless" then
                    _killuaToggle:SetValue(false)
                    notify("Requires Standless", 4)
                    return
                end
            end)
        end)
        task.spawn(function()
            while Tog.AutofarmKillua and Tog.AutofarmKillua.Value do
                _dialogueRF("Godspeed"); task.wait(5)
            end
        end)
    end})

local _FarmInfo = Tabs.Farming:AddLeftGroupbox("Information", "bar-chart-2")

local _lblTotalCoins  = _FarmInfo:AddLabel("Total UCoins — loading...")
local _lblTotalShards = _FarmInfo:AddLabel("Total UShards — loading...")
local _lblTotalEvents = _FarmInfo:AddLabel("Total UEvents — loading...")
_FarmInfo:AddLabel(" ")
local _lblGainCoins   = _FarmInfo:AddLabel("Gained UCoins — 0")
local _lblGainShards  = _FarmInfo:AddLabel("Gained UShards — 0")
local _lblGainEvents  = _FarmInfo:AddLabel("Gained UEvents — 0")

do
    local _sessCoins, _sessShards, _sessEvents = 0, 0, 0
    local _lastCoins, _lastShards, _lastEvents = nil, nil, nil
    task.spawn(function()
        while task.wait(1) do
            pcall(function()
                local c = LP.Data.UCoins.Value or 0
                local s = LP.Data.Currency.Value or 0
                local e = LP.Data.EventCurrency.Value or 0
                if _lastCoins  then _sessCoins  = _sessCoins  + math.max(0, c - _lastCoins)  end
                if _lastShards then _sessShards = _sessShards + math.max(0, s - _lastShards) end
                if _lastEvents then _sessEvents = _sessEvents + math.max(0, e - _lastEvents) end
                _lastCoins=c; _lastShards=s; _lastEvents=e
                _lblTotalCoins:SetText("Total UCoins — "  .. tostring(c))
                _lblTotalShards:SetText("Total UShards — " .. tostring(s))
                _lblTotalEvents:SetText("Total UEvents — " .. tostring(e))
                _lblGainCoins:SetText("Gained UCoins — "  .. tostring(_sessCoins))
                _lblGainShards:SetText("Gained UShards — " .. tostring(_sessShards))
                _lblGainEvents:SetText("Gained UEvents — " .. tostring(_sessEvents))
            end)
        end
    end)
end

local _FarmSell = Tabs.Farming:AddLeftGroupbox("Selling Features", "coins")

local _storeSelected = {}

local _excludedItems = {
    "Aja Stone","Altered Steel Ball","Ancient Sword","Arrow","Azakana Mask",
    "Baroque Works Contractor Den Den","Bisento","Blood of Joseph","Bone","Bouquet Of Flowers",
    "Busoshoku Manual","Candy Cutlass Blade","Chest Key","Coal","Coal Loot","Corrupted Soul",
    "Cosmic Fragments","Cursed Apple","Cursed Arm","Cursed Orb","Death Painting","DIO's Bone",
    "DIO's Diary","Dragon Ball","Evil Fragments","Eyes of the Saint's Corpse","Frog",
    "Gojo's Blindfold","Golden Hook","Gomu Gomu no mi","Green Baby","Gun Parts","Haoshoku Manual",
    "Haki Shard","Hamon Imbued Frog","Heart","Heart of the Saint's Corpse","Heavenly Nectar",
    "Heavenly Restriction Awakening","Hito Hito No Mi: Model Nika","Inhumane Spirit",
    "Inverted Spear of Heaven","Joestar Blood Vial","Kenbunshoku Manual","Kinetic Orb",
    "King of Curses Shard","Knight's Sword","Kuma's Bible","Law's Cap","Leg's Of The Saint's Corpse",
    "Light Of Hope","Limitless Technique Scroll","Locacaca","Mahoraga's Calamity Force",
    "Manual of Gryphon's Techniques","Meat On A Bone","Meat On Bone","Metal Loot","Mero Devil Fruit",
    "Mero Mero No Mi","Monochromatic Orb","Mysterious Fragment","Mysterious Hat","Nanotech Fragment",
    "Ope Devil Fruit","Ope Ope No Mi","Playful Cloud","Pumpkin","Remembrance of the Fallen",
    "Remembrance of the Sorcerer Killer","Remembrance of the Strongest","Remembrance of the Vessel",
    "Requiem Arrow","Ribcage Of The Saint's Corpse","Shadow's Calamity Force","Shank's Calamity Force",
    "Shaper's Essence","Shrine Item","Simple Domain Essence","Slime Energy","Sorcerer Killer Shard",
    "Spin Energy Fragment","Split Soul Katana","Sukuna's Calamity Force","Sukuna's Finger",
    "Suna Devil Fruit","Suna Suna No Mi","Tales of the Universe","The Denizen of Hell's Calamity Force",
    "The Vessel Shard","Umbra's Calamity Force","Vampire Mask","Vampire Mask & Vial of Blood",
    "Vial of Blood","Watch","West Blue juice","Wheel of Dharma","Whitebeard's Calamity Force","Yo-Yo"
}

local _excludeSellSelected = {}
local _excludeSellDropdown = _FarmSell:AddDropdown("ExcludeItemsSelect", {
    Text="Exclude Items", Values=_excludedItems, Default={}, Multi=true,
    Callback=function(v)
        _excludeSellSelected = {}
        for item, _ in pairs(v) do table.insert(_excludeSellSelected, item) end
    end})

local _sellSelectAllState = false
_FarmSell:AddButton({Text="Select Everything", Func=function()
    if not _sellSelectAllState then
        local all = {}; for _, v in ipairs(_excludedItems) do all[v] = true end
        _excludeSellDropdown:SetValue(all)
    else
        _excludeSellDropdown:SetValue({})
    end
    _sellSelectAllState = not _sellSelectAllState
end})

local _sellDelay = 10
_FarmSell:AddSlider("SellDelay", {Text="Sell Delay", Default=10, Min=5, Max=350, Rounding=0, Compact=true,
    Callback=function(v) _sellDelay=v end})

_FarmSell:AddToggle("AutoSellInventory", {Text="Auto Sell Inventory", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AutoSellInventory and Tog.AutoSellInventory.Value do
                pcall(function()
                    local remote = game:GetService("ReplicatedStorage")
                        :WaitForChild("ReplicatedModules"):WaitForChild("KnitPackage"):WaitForChild("Knit")
                        :WaitForChild("Services"):WaitForChild("ShopService"):WaitForChild("RE"):WaitForChild("Signal")
                    local args = {[1]="BlackMarketBulkSellItems", [2]={}}
                    local storeEnabled = Tog.AutoStoreItems and Tog.AutoStoreItems.Value
                    for _, x in ipairs(LP.Backpack:GetChildren()) do
                        if x:IsA("Tool") then
                            local excluded = table.find(_excludeSellSelected, x.Name)
                            local wantStore = storeEnabled and _storeSelected and table.find(_storeSelected, x.Name)
                            if not excluded and not wantStore then
                                table.insert(args[2], {x:GetAttribute("ItemId"), x:GetAttribute("UUID"), 1})
                            end
                        end
                    end
                    remote:FireServer(unpack(args))
                end)
                task.wait(_sellDelay)
            end
        end)
    end})

_FarmSell:AddButton({Text="Teleport To Black Market", Func=function()
    pcall(function()
        local spawnPoints = {
            CFrame.new(2447.40454,981.932434,112.544067,-0.00852715969,0,-0.999963641,0,1,0,0.999963641,0,-0.00852715969),
            CFrame.new(2016.10645,921.7771,1062.49072,-1,0,0,0,1,0,0,0,-1),
            CFrame.new(2028.34277,1063.17847,-768.278137,-0.77425468,0,0.632874191,0,1,0,-0.632874191,0,-0.77425468),
            CFrame.new(961.53418,1009.49963,-436.7435,-0.996708274,0,0.0810758993,0,1,0,-0.0810758993,0,-0.996708274),
        }
        local bm = workspace.NPCS:FindFirstChild("Black Market")
        if bm then
            local hrp = bm:FindFirstChild("HumanoidRootPart")
            if hrp then
                LP.Character.HumanoidRootPart.CFrame = hrp.CFrame
            else
                for _, cf in ipairs(spawnPoints) do
                    task.wait(0.25); LP.Character.HumanoidRootPart.CFrame = cf
                    hrp = bm:FindFirstChild("HumanoidRootPart")
                    if hrp then LP.Character.HumanoidRootPart.CFrame = hrp.CFrame; break end
                end
            end
        else
            notify("Black Market is not here...", 2)
        end
    end)
end})

local _FarmStore = Tabs.Farming:AddLeftGroupbox("Storing Features", "archive")

local _storeDropdown = _FarmStore:AddDropdown("StoreItemsSelect", {
    Text="Selected Items to Store", Values=_excludedItems, Default={}, Multi=true,
    Callback=function(v)
        _storeSelected = {}
        for item, _ in pairs(v) do table.insert(_storeSelected, item) end
    end})

local _storeSelectAllState = false
_FarmStore:AddButton({Text="Select Everything", Func=function()
    if not _storeSelectAllState then
        local all = {}; for _, v in ipairs(_excludedItems) do all[v] = true end
        _storeDropdown:SetValue(all)
    else
        _storeDropdown:SetValue({})
    end
    _storeSelectAllState = not _storeSelectAllState
end})

_FarmStore:AddToggle("AutoStoreItems", {Text="Auto Store Items", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AutoStoreItems and Tog.AutoStoreItems.Value do
                pcall(function()
                    local inv = game:GetService("ReplicatedStorage").ReplicatedModules.KnitPackage.Knit.Services.InventoryService.RF.GetCapacity
                        :InvokeServer("ItemInventory")
                    local cc, mc
                    for k, v in pairs(inv) do
                        if k == "CurrentCapacity" then cc = v
                        elseif k == "MaxCapacity" then mc = v end
                    end
                    if cc ~= mc then
                        if not LP.PlayerGui.UI.Gameplay.Character.Info:FindFirstChild("CombatTag").Visible then
                            for _, x in ipairs(LP.Backpack:GetChildren()) do
                                for _, k in ipairs(_storeSelected) do
                                    if x.Name == k then
                                        LP.Character:FindFirstChild("Humanoid"):EquipTool(x)
                                        game:GetService("ReplicatedStorage"):WaitForChild("ReplicatedModules"):WaitForChild("KnitPackage"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("InventoryService"):WaitForChild("RE"):WaitForChild("ItemInventory")
                                            :FireServer({["AddItems"]=true})
                                        task.wait(0.15)
                                        LP.Character:FindFirstChild("Humanoid"):UnequipTools()
                                    end
                                end
                            end
                        end
                    end
                end)
                task.wait(0.035)
            end
        end)
    end})

local _FarmTraits = Tabs.Farming:AddLeftGroupbox("Trait Features", "shuffle")

local _traitList = {
    "Frostbite","Prime","Overconfident Prime","Solar","Icarus Solar","Cursed","Undying Cursed",
    "Vampiric","Ancient Vampiric","Gluttonous","Festering Gluttonous","Voided","Abyssal Voided",
    "Gambler","Idle Death Gambler","Overflowing","Torrential Overflowing","Deferred","Fractured Deferred",
    "True","Vitriolic True","Cultivation","Soul Reaping Cultivation","Economic","Greedy Economic",
    "Angelic","Fallen Angelic","Godly","Egotistic Godly","Temporal","FTL Temporal","Spiritual",
    "Psychotic Spiritual","Ryoiki","Heavenly Restricted Ryoiki","RCT","Automatic RCT"
}
local _wantedTraits = {"Godly","Egotistic Godly"}

_FarmTraits:AddDropdown("TraitSelect", {
    Text="Select Traits", Values=_traitList, Default={["Godly"]=true,["Egotistic Godly"]=true}, Multi=true,
    Callback=function(v)
        _wantedTraits = {}
        for t, _ in pairs(v) do table.insert(_wantedTraits, t) end
    end})

_FarmTraits:AddToggle("AutoPickTraitsV1", {Text="Auto Pick Traits (V1)", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AutoPickTraitsV1 and Tog.AutoPickTraitsV1.Value do
                pcall(function()
                    local traitHand = LP.PlayerGui.UI.Gameplay:FindFirstChild("TraitHand")
                    if traitHand and traitHand.Visible then
                        for _, slot in ipairs(traitHand:GetChildren()) do
                            if slot:IsA("Frame") then
                                local traitName = slot:FindFirstChild("TraitName")
                                if traitName and table.find(_wantedTraits, traitName.Text) then
                                    local btn = slot:FindFirstChild("SelectButton")
                                    if btn then btn.MouseButton1Click:Fire() end
                                    return
                                end
                            end
                        end
                        local skip = traitHand:FindFirstChild("SkipButton") or traitHand:FindFirstChild("Discard")
                        if skip then skip.MouseButton1Click:Fire() end
                    end
                end)
                task.wait(0.1)
            end
        end)
    end})

local _FarmFeatures = Tabs.Farming:AddRightGroupbox("Farming Features", "sword")

local _mobList = {
    Thugs     = {"Thug"},
    Prisoners = {"Fleeing"},
    Hooligans = {"Hooligan"},
    Pirates   = {"Pirat"},
    Guardians = {"Guard"},
    Curses    = {"Juju","Flyhead","Ropp","Mantis"},
}
local _selectedBosses = {}
local _selectedMob    = "Curses"
local _currentList    = _mobList.Curses
local _selectedOffsetY = 5

local _bossList = {
    "Whitebeard","Surgeon of Death","Shanks","Mahoraga","The Strongest Of Today",
    "The Sorcerer killer","The Strongest In History","The Vessel","The Bearer","The Knight",
    "The Honored One","The Clown","Diavolo, The Boss","Kars","Luffy","Kuro","Dio","Tower","Crocodile"
}

_FarmFeatures:AddDropdown("FarmingBossesSelect", {
    Text="Select Bosses", Values=_bossList, Default={}, Multi=true,
    Callback=function(v)
        _selectedBosses = {}
        for boss, state in pairs(v) do if state then table.insert(_selectedBosses, boss) end end
        _currentList = table.clone(_mobList[_selectedMob] or _mobList.Curses)
        for _, b in ipairs(_selectedBosses) do table.insert(_currentList, b) end
    end})

_FarmFeatures:AddDropdown("FarmingMobSelect", {
    Text="Select Mob", Values={"Curses","Prisoners","Pirates","Guardians","Hooligans","Thugs"}, Default=1, Multi=false,
    Callback=function(v)
        _selectedMob = type(v)=="table" and next(v) or v
        _currentList = table.clone(_mobList[_selectedMob] or _mobList.Curses)
        for _, b in ipairs(_selectedBosses) do table.insert(_currentList, b) end
    end})

_FarmFeatures:AddSlider("FarmDistanceY", {Text="Select Distance Y", Default=5, Min=1, Max=25, Rounding=0, Compact=true,
    Callback=function(v) _selectedOffsetY=v end})

local _attackList = {"Q","E","R","T","G","Y","V","H","J","X","B","U","K","Z","C"}
local _selectedMoveset = {}

_FarmFeatures:AddDropdown("FarmAttacksSelect", {
    Text="Select Attacks", Values=_attackList, Default={}, Multi=true,
    Callback=function(v)
        _selectedMoveset = {}
        for atk, _ in pairs(v) do table.insert(_selectedMoveset, atk) end
    end})

_FarmFeatures:AddToggle("AutoHoldAttacks", {Text="Auto Use Hold+ Attacks Mode", Default=false, Callback=function() end})

_FarmFeatures:AddLabel("— Miscellaneous —")

_FarmFeatures:AddToggle("AutoInstaKill", {Text="Auto Insta Kill Mobs", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            local conn
            conn = RS.RenderStepped:Connect(function()
                if not (Tog.AutoInstaKill and Tog.AutoInstaKill.Value) then conn:Disconnect(); return end
                pcall(function()
                    for _, k in ipairs(workspace.Living:GetChildren()) do
                        if k:IsA("Model") and k:FindFirstChild("Head") and k.Head ~= LP.Character.Head then
                            if (k.Head.Position - LP.Character.Head.Position).Magnitude <= 35 then
                                local hum = k:FindFirstChildOfClass("Humanoid")
                                if hum and hum.Health > 0 then
                                    local thresh = (hum.MaxHealth * (Opt.InstaKillThreshold and Opt.InstaKillThreshold.Value or 45)) / 100
                                    if hum.Health <= thresh then hum.Health = 0; hum.MaxHealth = 0 end
                                end
                            end
                        end
                    end
                end)
            end)
        end)
    end})

_FarmFeatures:AddSlider("InstaKillThreshold", {Text="Insta Kill Threshold %", Default=45, Min=10, Max=100, Rounding=0, Compact=true, Callback=function() end})

local _ascensionLimitToggle
_FarmFeatures:AddInput("AscensionLimiter", {Default="99999", Numeric=true, Finished=false, Text="Ascension Limiter", Placeholder="99999"})

_ascensionLimitToggle = _FarmFeatures:AddToggle("AutoAscend", {Text="Auto Ascend Ability", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AutoAscend and Tog.AutoAscend.Value do
                pcall(function()
                    local data = LP:WaitForChild("Data"):WaitForChild("Ability")
                    local lvl  = data:GetAttribute("AbilityLevel")
                    local rank = data:GetAttribute("AscensionRank")
                    local lim  = tonumber(Opt.AscensionLimiter and Opt.AscensionLimiter.Value) or 99999
                    if lvl == 200 and lim > rank then
                        game:GetService("ReplicatedStorage"):WaitForChild("ReplicatedModules"):WaitForChild("KnitPackage"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("LevelService"):WaitForChild("RF"):WaitForChild("AscendAbility")
                            :InvokeServer(data.Value)
                    elseif lim <= rank then
                        _ascensionLimitToggle:SetValue(false)
                        notify("Ascension Limiter reached — stopped.", 4)
                    end
                end)
                task.wait(0.75)
            end
        end)
    end})

_FarmFeatures:AddLabel("— Cooldowns —")

local function _getMoveset()
    local moves = {}
    pcall(function()
        for _, v in ipairs(LP.PlayerGui.UI.Gameplay.Moves:GetChildren()) do
            if v:IsA("TextButton") and v.Name ~= "Rush Attack" and v.Name ~= "NextMove"
                and v.Name ~= "Quickstep" and v.Name ~= "Block" and v.Name ~= "Pose" then
                table.insert(moves, v.Name)
            end
        end
    end)
    return moves
end

local _selectedMoveset2 = {}
local _cdDropdown = _FarmFeatures:AddDropdown("CooldownMovesSelect", {
    Text="Select Moves", Values=_getMoveset(), Default={}, Multi=true,
    Callback=function(v)
        _selectedMoveset2 = {}
        for m, _ in pairs(v) do table.insert(_selectedMoveset2, m) end
    end})

_FarmFeatures:AddButton({Text="Refresh Movesets", Func=function()
    local moves = _getMoveset()
    _cdDropdown:SetValues(moves)
    notify("Moveset refreshed", 3)
end})

_FarmFeatures:AddToggle("MultiSupportModeCD", {Text="Multi Support Mode CD", Default=false, Callback=function() end})

_FarmFeatures:AddToggle("AutoResetCooldowns", {Text="Auto Reset Attack Cooldowns", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AutoResetCooldowns and Tog.AutoResetCooldowns.Value do
                pcall(function()
                    if #_selectedMoveset2 == 0 then return end
                    local cdDetected = false
                    local multiMode = Tog.MultiSupportModeCD and Tog.MultiSupportModeCD.Value
                    if multiMode then
                        local allCD = true
                        for _, v in ipairs(_selectedMoveset2) do
                            if not LP:FindFirstChild("Cooldowns"):FindFirstChild(v) then allCD=false; break end
                        end
                        if allCD then cdDetected = true end
                    else
                        for _, v in ipairs(_selectedMoveset2) do
                            if LP:FindFirstChild("Cooldowns"):FindFirstChild(v) then cdDetected=true; break end
                        end
                    end
                    if cdDetected and LP.Character.Humanoid.Health ~= 0 then
                        LP.Character.Humanoid:ChangeState(15)
                    end
                end)
                task.wait(0.0075)
            end
        end)
    end})

_FarmFeatures:AddLabel("— Auto Equip / Rewards / Stats —")

_FarmFeatures:AddToggle("AutoEquipSpecs", {Text="Auto Equip Specs", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AutoEquipSpecs and Tog.AutoEquipSpecs.Value do
                pcall(function()
                    if not workspace.Living[LP.Name].StatesFolder.StandOn.Value then
                        game:GetService("ReplicatedStorage"):WaitForChild("ReplicatedModules"):WaitForChild("KnitPackage"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("MoveInputService"):WaitForChild("RF"):WaitForChild("FireInput")
                            :InvokeServer("Q")
                    end
                end)
                task.wait(0.45)
            end
        end)
    end})

_FarmFeatures:AddToggle("AutoCollectRewards", {Text="Auto Collect Rewards", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AutoCollectRewards and Tog.AutoCollectRewards.Value do
                pcall(function() LP.PlayerGui.UI.Gameplay.ChestRoll.Visible = false end)
                task.wait(0.45)
            end
        end)
        task.spawn(function()
            while Tog.AutoCollectRewards and Tog.AutoCollectRewards.Value do
                pcall(function()
                    for _, v in ipairs(LP.PlayerGui.UI.Menus.Rewards.Tabs.Playtime.ScrollBar:GetChildren()) do
                        if v.ClassName == "Frame" then
                            game:GetService("ReplicatedStorage"):WaitForChild("ReplicatedModules"):WaitForChild("KnitPackage"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("ShopService"):WaitForChild("RF"):WaitForChild("ClaimPlaytimeReward")
                                :InvokeServer(tonumber(v.Name))
                        end
                    end
                end)
                task.wait(1.15)
            end
        end)
        task.spawn(function()
            while Tog.AutoCollectRewards and Tog.AutoCollectRewards.Value do
                pcall(function()
                    for i = 1, 7 do
                        game:GetService("ReplicatedStorage"):WaitForChild("ReplicatedModules"):WaitForChild("KnitPackage"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("ShopService"):WaitForChild("RF"):WaitForChild("ClaimDailyReward")
                            :InvokeServer(i)
                    end
                end)
                task.wait(1.15)
            end
        end)
    end})

_FarmFeatures:AddDropdown("StatsSelect", {
    Text="Select Stats", Values={"Attack","Health","Defense","Special"}, Default={["Attack"]=true}, Multi=true,
    Callback=function() end})

_FarmFeatures:AddToggle("AutoApplyStats", {Text="Auto Apply Stats", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AutoApplyStats and Tog.AutoApplyStats.Value do
                pcall(function()
                    local stats = {Special=0, Defense=0, Health=0, Attack=0}
                    local sel = Opt.StatsSelect and Opt.StatsSelect.Value or {}
                    for stat, on in pairs(sel) do if on then stats[stat] = 1 end end
                    game:GetService("ReplicatedStorage"):WaitForChild("ReplicatedModules"):WaitForChild("KnitPackage"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("StatService"):WaitForChild("RF"):WaitForChild("ApplyStats")
                        :InvokeServer(LP.Data.Ability.Value, stats)
                end)
                task.wait(0.15)
            end
        end)
    end})

_FarmFeatures:AddLabel("— Auto Collect Chests —")

local _foundItem = false
_FarmFeatures:AddToggle("AutoCollectChests", {Text="Auto Collect Chests", Default=false,
    Callback=function(p)
        if not p then return end
        _foundItem = false
        task.spawn(function()
            while Tog.AutoCollectChests and Tog.AutoCollectChests.Value do
                pcall(function() LP.PlayerGui.UI.Gameplay.ChestRoll.Visible = false end)
                task.wait(0.0015)
            end
        end)
        task.spawn(function()
            while Tog.AutoCollectChests and Tog.AutoCollectChests.Value do
                local rootPart = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if not _foundItem then
                    for _, chestName in ipairs({"Common_Chest","Epic_Chest","Rare_Chest","Legendary_Chest"}) do
                        local chest = workspace:FindFirstChild(chestName)
                        if chest then
                            local wl = chest:FindFirstChild("Whitelisted")
                            local prox = chest:FindFirstChild("ProximityAttachment")
                            local prompt = prox and prox:FindFirstChild("Interaction")
                            local isWL = wl and wl:FindFirstChild(tostring(LP.UserId))
                            if isWL and isWL:IsA("BoolValue") and prompt and prompt:IsA("ProximityPrompt") then
                                rootPart.CFrame = chest.CFrame
                                prompt.RequiresLineOfSight = false; prompt.HoldDuration = 0
                                prompt:InputHoldBegin(); prompt:InputHoldEnd()
                                break
                            end
                        end
                    end
                end
                task.wait(0.015)
            end
        end)
    end})

_FarmFeatures:AddLabel("— Main Farming —")

local _farmMobsThread = nil
_FarmFeatures:AddToggle("StartFarmingMobs", {Text="Start Farming Mobs", Default=false,
    Callback=function(p)
        if _farmMobsThread then task.cancel(_farmMobsThread); _farmMobsThread = nil end
        if not p then
            pcall(function()
                local hum = getHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end)
            return
        end
        _foundItem = false
        _farmMobsThread = task.spawn(function()
            local RS2 = game:GetService("ReplicatedStorage")
            local inputRF = RS2:WaitForChild("ReplicatedModules"):WaitForChild("KnitPackage")
                :WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("MoveInputService")
                :WaitForChild("RF"):WaitForChild("FireInput")
            while Tog.StartFarmingMobs and Tog.StartFarmingMobs.Value do
                pcall(function()
                    local char = getChar(); if not char then return end
                    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health <= 0 then return end
                    local hrpSelf = char:FindFirstChild("HumanoidRootPart"); if not hrpSelf then return end
                    local headSelf = char:FindFirstChild("Head"); if not headSelf then return end

                    hum:ChangeState(Enum.HumanoidStateType.Physics)
                    hrpSelf.AssemblyLinearVelocity = Vector3.zero

                    local closest, closestDist = nil, math.huge
                    for _, k in ipairs(workspace.Living:GetChildren()) do
                        if k:IsA("Model") and PS:GetPlayerFromCharacter(k) == nil then
                            local kHead = k:FindFirstChild("Head")
                            local kHRP  = k:FindFirstChild("HumanoidRootPart")
                            local kHum  = k:FindFirstChildOfClass("Humanoid")
                            if kHead and kHRP and kHum and kHum.Health > 0 then
                                local nameMatch = false
                                for _, n in ipairs(_currentList) do
                                    if string.find(k.Name, n) then nameMatch = true; break end
                                end
                                if nameMatch then
                                    local d = (kHRP.Position - hrpSelf.Position).Magnitude
                                    if d < closestDist then closestDist = d; closest = k end
                                end
                            end
                        end
                    end

                    if not closest then return end
                    local targetHRP = closest:FindFirstChild("HumanoidRootPart"); if not targetHRP then return end

                    hrpSelf.CFrame = CFrame.new(
                        targetHRP.Position - Vector3.new(0, _selectedOffsetY, 0),
                        targetHRP.Position
                    )
                    hrpSelf.AssemblyLinearVelocity = Vector3.zero

                    if #_selectedMoveset > 0 then
                        for _, atk in ipairs(_selectedMoveset) do
                            if not (Tog.StartFarmingMobs and Tog.StartFarmingMobs.Value) then break end
                            pcall(function()
                                if Tog.AutoHoldAttacks and Tog.AutoHoldAttacks.Value then
                                    inputRF:InvokeServer(atk.."+")
                                else
                                    inputRF:InvokeServer(atk)
                                end
                            end)
                            task.wait(0.1)
                        end
                    end
                    pcall(function() inputRF:InvokeServer("MouseButton1") end)
                end)
                task.wait(0.15)
            end
            pcall(function()
                local hum = getHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end)
        end)
    end})

_FarmFeatures:AddToggle("StartFarmingItems", {Text="Start Farming Items", Default=false,
    Callback=function(p)
        if not p then return end
        _foundItem = false
        task.spawn(function()
            while Tog.StartFarmingItems and Tog.StartFarmingItems.Value do
                pcall(function()
                    local spawns = {workspace.ItemSpawns.StandardItems, workspace.ItemSpawns.DevilFruits, workspace.ItemSpawns.Meteors}
                    local closest, closestDist, count = nil, math.huge, 0
                    _foundItem = false
                    for _, folder in pairs(spawns) do
                        for _, k in pairs(folder:GetChildren()) do
                            if #k:GetChildren() > 0 then
                                for _, b in pairs(k:GetChildren()) do
                                    if b:IsA("BasePart") then
                                        count = count + 1
                                        local d = (LP.Character.HumanoidRootPart.Position - b.Position).Magnitude
                                        if d < closestDist then closestDist=d; closest=b end
                                    end
                                end
                            end
                        end
                    end
                    if count > 0 then _foundItem = true end
                    if _foundItem and LP.Character.Humanoid.Health ~= 0 then
                        LP.Character:SetPrimaryPartCFrame(closest.CFrame * CFrame.new(0,10,0))
                        local prox = closest:FindFirstChild("ProximityAttachment") and closest.ProximityAttachment:FindFirstChild("Interaction")
                        if prox then
                            prox.MaxActivationDistance=120; prox.RequiresLineOfSight=false; prox.HoldDuration=0
                            prox:InputHoldBegin(); prox:InputHoldEnd()
                        end
                    end
                end)
                task.wait(0.075)
            end
        end)
    end})

_FarmFeatures:AddLabel("— Alternate Farming —")

local _farmNearestThread = nil
_FarmFeatures:AddToggle("AutofarmNearest", {Text="Autofarm Nearest Boss / Mob", Default=false,
    Callback=function(p)
        if _farmNearestThread then task.cancel(_farmNearestThread); _farmNearestThread = nil end
        if not p then
            pcall(function()
                local hum = getHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end)
            return
        end
        _farmNearestThread = task.spawn(function()
            local RS2 = game:GetService("ReplicatedStorage")
            local inputRF = RS2:WaitForChild("ReplicatedModules"):WaitForChild("KnitPackage")
                :WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("MoveInputService")
                :WaitForChild("RF"):WaitForChild("FireInput")
            while Tog.AutofarmNearest and Tog.AutofarmNearest.Value do
                pcall(function()
                    local char = getChar(); if not char then return end
                    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health <= 0 then return end
                    local hrpSelf = char:FindFirstChild("HumanoidRootPart"); if not hrpSelf then return end

                    hum:ChangeState(Enum.HumanoidStateType.Physics)
                    hrpSelf.AssemblyLinearVelocity = Vector3.zero

                    local closest, closestDist = nil, math.huge
                    for _, k in ipairs(workspace.Living:GetChildren()) do
                        if k:IsA("Model") and PS:GetPlayerFromCharacter(k) == nil then
                            local kHRP = k:FindFirstChild("HumanoidRootPart")
                            local kHum = k:FindFirstChildOfClass("Humanoid")
                            if kHRP and kHum and kHum.Health > 0 then
                                local d = (kHRP.Position - hrpSelf.Position).Magnitude
                                if d <= 1500 and d < closestDist then closest = k; closestDist = d end
                            end
                        end
                    end

                    if not closest then return end
                    local targetHRP = closest:FindFirstChild("HumanoidRootPart"); if not targetHRP then return end

                    hrpSelf.CFrame = CFrame.new(
                        targetHRP.Position - Vector3.new(0, _selectedOffsetY, 0),
                        targetHRP.Position
                    )
                    hrpSelf.AssemblyLinearVelocity = Vector3.zero

                    if #_selectedMoveset > 0 then
                        for _, atk in ipairs(_selectedMoveset) do
                            if not (Tog.AutofarmNearest and Tog.AutofarmNearest.Value) then break end
                            pcall(function() inputRF:InvokeServer(atk) end)
                            task.wait(0.1)
                        end
                    end
                    pcall(function() inputRF:InvokeServer("MouseButton1") end)
                end)
                task.wait(0.15)
            end
            pcall(function()
                local hum = getHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
            end)
        end)
    end})

local _FarmCrates = Tabs.Farming:AddRightGroupbox("Crates Features", "package")

_FarmCrates:AddDropdown("SkinCratesAmount", {
    Text="Select How Many Crates", Values={"1","10"}, Default=1, Multi=false,
    Callback=function() end})

_FarmCrates:AddToggle("AutoBuySkinCrates", {Text="Auto Buy Normal Skin Crates", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AutoBuySkinCrates and Tog.AutoBuySkinCrates.Value do
                pcall(function()
                    local amount = Opt.SkinCratesAmount and (type(Opt.SkinCratesAmount.Value)=="table" and next(Opt.SkinCratesAmount.Value) or Opt.SkinCratesAmount.Value) or "1"
                    game:GetService("ReplicatedStorage"):WaitForChild("ReplicatedModules"):WaitForChild("KnitPackage"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("ShopService"):WaitForChild("RF"):WaitForChild("BuySkinCrate")
                        :InvokeServer("Skin_Crate", "UShards", tonumber(amount))
                end)
                task.wait(0.075)
            end
        end)
    end})

local _FarmSkins = Tabs.Farming:AddRightGroupbox("Skin Manager Features", "trash-2")

local _excludedSkins = {
    "The Strongest In History","The Strongest Of Today","Urzan","Igris","KCR","Shadow Legs",
    "Ama No Murakumo","Futuristic Queen","Creeper Queen","True Asgore","DJ Noob","Noob","Galizur",
    "Party Starter","DTWHV","Cypher","TWR","Seele","VOXEL // SHAPER","The Virtuoso","2099","Fallen",
    "Big Q","V2","HSTWR","MOCE","Frost","Santa Claus","D4C: Lovestruck","D4C: Easter",
    "Nocturnus: Risen Sun","Neptune","Hellish Crimson","Heart Dawn","Sinister Blade",
    "Reaper: Peppermint","Reaper: Heartsickle","Made In Christmas","Snow Queen","Eye of the Tiger",
    "Phantom Queen","Queen O'Lantern","Garfield Queen","Love O' Lantern","HALLOW",
    "Star Platinum: GOLD","Shadow Dio: Loveless","Blizzard Shaper","D4C:LT: Lovestruck","CTWR",
    "Candy Platinum","Glacier Gladiator","Skellington","Krampus","KQ: Abomination",
    "OCEAN // SAILOR","HEART // SHAPER","King Crimson: Discipline",
}

local function _autoDeleteSkins(rarity, toggleKey)
    task.spawn(function()
        while Tog[toggleKey] and Tog[toggleKey].Value do
            pcall(function()
                if not LP.PlayerGui.UI.Gameplay.Character.Info:FindFirstChild("CombatTag").Visible then
                    local invRF = game:GetService("ReplicatedStorage").ReplicatedModules.KnitPackage.Knit.Services.InventoryService.RF.GetItems
                    local delRE = game:GetService("ReplicatedStorage").ReplicatedModules.KnitPackage.Knit.Services.InventoryService.RE.SkinInventory
                    for _, v in pairs(invRF:InvokeServer("SkinInventory")) do
                        if v._Rarity == rarity and not v._UnusualInfo and not v._Premium
                            and v._Tradeable ~= false and not table.find(_excludedSkins, v._DisplayName) then
                            delRE:FireServer({["Remove"]=true, ["UUID"]=v._UUID, ["ItemId"]=v._ItemId})
                            return
                        end
                    end
                end
            end)
            task.wait(0.015)
        end
    end)
end

_FarmSkins:AddToggle("AutoDeleteEventSkins",     {Text="Auto Delete Event Skins",     Default=false, Callback=function(p) if p then _autoDeleteSkins(6,"AutoDeleteEventSkins")     end end})
_FarmSkins:AddToggle("AutoDeleteMythicSkins",    {Text="Auto Delete Mythic Skins",    Default=false, Callback=function(p) if p then _autoDeleteSkins(7,"AutoDeleteMythicSkins")    end end})
_FarmSkins:AddToggle("AutoDeleteLegendarySkins", {Text="Auto Delete Legendary Skins", Default=false, Callback=function(p) if p then _autoDeleteSkins(5,"AutoDeleteLegendarySkins") end end})
_FarmSkins:AddToggle("AutoDeleteEpicSkins",      {Text="Auto Delete Epic Skins",      Default=false, Callback=function(p) if p then _autoDeleteSkins(4,"AutoDeleteEpicSkins")      end end})
_FarmSkins:AddToggle("AutoDeleteRareSkins",      {Text="Auto Delete Rare Skins",      Default=false, Callback=function(p) if p then _autoDeleteSkins(3,"AutoDeleteRareSkins")      end end})
_FarmSkins:AddLabel("(Keeps Unusuals and Unobtainables)")

SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

if Tog.AutoHideUI and Tog.AutoHideUI.Value then
    pcall(function() Window:Toggle(false) end)
end

notify("⊙ A Universal Time", 5)
