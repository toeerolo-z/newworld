-- ZEROHUB UNIVERSAL - CONVERTED TO MACLIB (EXACT VV SYNTAX)

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

-- SERVICES & HELPERS
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

-- CONFIG STATE
local S = {
    speed=100, infJumpH=50, flySpeed=100, tweenSpeed=100,
    aimbotFOV=45, aimbotSens=1, aimbotX=0, aimbotY=0,
    aimbotMode="Toggle", aimbotActive=false, aimbotEnabled=false,
    aimbotMethod="Camera", targetPlayers=true, visibleOnly=false, teamCheck=false,
    brightness=2, freeCamSens=0.3, freeCamSpeed=0.5, fovVal=70,
    hitboxSize=5, hitboxTrans=0.9,
    espDist=1000, espFontSize=14, tracerThick=2,
    mobsRange=1000, mobsDist=0, mobsHeight=0,
}

local _savedPos = nil
local _farmMode = "Behind"
local _farmOffX, _farmOffY, _farmOffZ = 0, 0, 6.5
local _bringRange = 100
local _freezeRange = 100

getgenv()._ZH_autoM1 = false
getgenv()._ZH_autoCrit = false
getgenv()._ZH_autoEquip = false

-- KILL PREVIOUS INSTANCE
if getgenv()._ZHUnload then pcall(getgenv()._ZHUnload); getgenv()._ZHUnload=nil end

-- LOAD MACLIB (EXACT VV METHOD)
local _macSrc = game:HttpGet("https://raw.githubusercontent.com/troidnox/sorrynol/refs/heads/main/zeree")
local _macFn, _macErr = loadstring(_macSrc)
if not _macFn then error("[ZeroHub] MacLib load failed: " .. tostring(_macErr)) end
local MacLib = _macFn()
if not MacLib then error("[ZeroHub] MacLib returned nil") end

-- CREATE WINDOW (EXACT VV SYNTAX)
local Window = MacLib:Window({
    Title    = "<font color=\"rgb(178,120,255)\">Zero</font> <font color=\"rgb(138,79,255)\">Hub</font>",
    Subtitle = "Devil Hunters  |  V.1.0",
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

-- ============================================================
-- GUN DEVIL EMBED (exact from Universal)
-- ============================================================
do
    local _GD_TOKEN   = "MTQ5MjkxNDYwOTU0NjU5NjU3NA.G7oc0b.eQhKKZP2ff0acXyTn0Rbb75UeOxXYEYCQXyp3s"
    local _GD_CHANNEL = "1508585077708161116"
    local _gdAlerted  = false
    local function sendGunDevilEmbed()
        task.spawn(function()
            local reqFn = request or (syn and syn.request) or http_request
            if not reqFn then return end
            local joinScript = string.format("game:GetService('TeleportService'):TeleportToPlaceInstance(%d, \"%s\")", game.PlaceId, game.JobId)
            local body = HS:JSONEncode({ embeds = {{
                title       = "Gun Devil Spawned",
                description = "Gun Devil is in this server.",
                color       = 0x9b59b6,
                fields = {
                    { name = "Players",     value = tostring(#PS:GetPlayers()) .. "/25", inline = true  },
                    { name = "JobId",       value = game.JobId,                          inline = false },
                    { name = "Join Script", value = "```\n" .. joinScript .. "\n```",    inline = false },
                },
                footer    = { text = "discord.gg/zerohub — Zero Hub" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            }}})
            pcall(function()
                reqFn({
                    Url    = "https://discord.com/api/v10/channels/" .. _GD_CHANNEL .. "/messages",
                    Method = "POST",
                    Headers = {
                        ["Authorization"] = "Bot " .. _GD_TOKEN,
                        ["Content-Type"]  = "application/json",
                        ["User-Agent"]    = "DiscordBot (https://discord.com, 10)",
                    },
                    Body = body,
                })
            end)
        end)
    end
    task.spawn(function()
        while true do
            task.wait(3)
            if not _gdAlerted then
                local world = workspace:FindFirstChild("World")
                local ents  = world and world:FindFirstChild("Entities")
                if ents and ents:FindFirstChild("Gun Devil") then
                    _gdAlerted = true
                    notify("⚠ Gun Devil spawned!", 5)
                    sendGunDevilEmbed()
                end
            end
        end
    end)
end

-- CREATE TABS
local TabGroup = Window:TabGroup()
local Tabs = {}
Tabs.Game      = TabGroup:Tab({Name="Main",       Image="swords"})
Tabs.Character = TabGroup:Tab({Name="Character",  Image="person-standing"})
Tabs.Visuals   = TabGroup:Tab({Name="Visuals",    Image="scan-eye"})
Tabs.World      = TabGroup:Tab({Name="World",      Image="map"})
Tabs.Navigation = TabGroup:Tab({Name="Navigation", Image="navigation"})
Tabs.Stats     = TabGroup:Tab({Name="Stats",      Image="activity"})
Tabs.Misc      = TabGroup:Tab({Name="Misc",       Image="layers"})
Tabs.Settings  = TabGroup:Tab({Name="Settings",   Image="sliders-horizontal"})

-- ====== GAME TAB (Main) SECTIONS ======
local GameL   = Tabs.Game:Section({Side="Left",  Name="Player Farm",       Image="users"})
local GameL2  = Tabs.Game:Section({Side="Left",  Name="Mob Farm",          Image="swords"})
local GameL3  = Tabs.Game:Section({Side="Left",  Name="Insta Kill",        Image="zap"})
local GameL4  = Tabs.Game:Section({Side="Left",  Name="Bring",             Image="magnet"})
local GameR   = Tabs.Game:Section({Side="Right", Name="Farm Config",       Image="settings"})
local GameR2  = Tabs.Game:Section({Side="Right", Name="Mission Farm",      Image="flag"})
local GameR3  = Tabs.Game:Section({Side="Right", Name="Freeze",            Image="snowflake"})
local GameR4  = Tabs.Game:Section({Side="Right", Name="Network Ownership", Image="network"})

-- ====== CHARACTER TAB SECTIONS ======
local CharL  = Tabs.Character:Section({Side="Left",  Name="Position",  Image="locate"})
local CharL2 = Tabs.Character:Section({Side="Left",  Name="Movement",  Image="move"})
local CharL3 = Tabs.Character:Section({Side="Left",  Name="Face Lock", Image="crosshair"})
local CharL4 = Tabs.Character:Section({Side="Left",  Name="Morphs",    Image="wand-2"})
local CharR  = Tabs.Character:Section({Side="Right", Name="Player",    Image="shield"})
local CharR2 = Tabs.Character:Section({Side="Right", Name="Combat",    Image="crosshair"})

-- ====== VISUALS TAB SECTIONS ======
local VizL  = Tabs.Visuals:Section({Side="Left",  Name="Player ESP",   Image="user"})
local VizL2 = Tabs.Visuals:Section({Side="Left",  Name="Mob ESP",      Image="skull"})
local VizL3 = Tabs.Visuals:Section({Side="Left",  Name="NPC ESP",      Image="bot"})
local VizR  = Tabs.Visuals:Section({Side="Right", Name="ESP Settings", Image="sliders"})

-- ESP STATE (real Universal logic)
local espEnabled        = false
local espColor          = Color3.fromRGB(255,255,255)
local espActive         = {}
local espConns          = {}
local _plrESP  = { components={}, showName=true,  showHP=false, showDist=false }
local _hue = 0
local mobESPColor2 = Color3.fromRGB(255,100,100)
local npcESPColor2 = Color3.fromRGB(100,220,255)
local _mobESP2 = { components={}, showName=false, showHP=false, showDist=false, rainbow=false }
local _npcESP2 = { components={}, showName=false, showDist=false, rainbow=false }
local _espCount2    = 0
local _mobESPActive = {}; local _mobESPEnabled = false
local _npcESPActive = {}; local _npcESPEnabled = false

-- ============================================================
-- GAME TAB CONTENT (real Universal logic)
-- ============================================================

local farmState = { plrs=false, plrTarget="", mobs=false, mobTarget="" }
local farmConns = {}
local mobLabelMap = {}
local _ownHighlights = {}
local _ownVizConn = nil
local _instaKillConn = nil
local _ikHealthThreshold = 0
local _ikRange = 100
local _bringConn = nil

-- COMBAT PACKET LOOPS (M1 / Critical / Equip)
if not getgenv()._ZH_combatLoopsStarted then
    getgenv()._ZH_combatLoopsStarted = true
    local function getUnreliable() return game:GetService("ReplicatedStorage").Files.Framework.Network.UnreliableRemoteEvent end
    local function getPacketEvent() return game:GetService("ReplicatedStorage").Files.Modules.Shared.Packet.RemoteEvent end
    local CRIT_BUF    = buffer.fromstring("\x03\x05Event\x1C\v\x04Name\v\bCritical\v\x04Args\x16\x1C\x8C\x1C>8\x18Y\xBE\xBE\x19w?\x00")
    local RELEASE_BUF = buffer.fromstring("\x03\x05Event\x1C\v\x04Name\v\x0FReleaseCritical\x00")
    task.spawn(function() while true do task.wait(0.15); if getgenv()._ZH_autoM1 then pcall(function() getUnreliable():FireServer("M1") end) end end end)
    task.spawn(function() while true do task.wait(0.3); if getgenv()._ZH_autoCrit then pcall(function() local e=getPacketEvent(); e:FireServer(CRIT_BUF); task.wait(0.2); e:FireServer(RELEASE_BUF) end) end end end)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if getgenv()._ZH_autoEquip then
                local living  = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Entities")
                local myModel = living and living:FindFirstChild(LP.Name)
                local equipped   = myModel and myModel:FindFirstChild("Weapon")
                local unequipped = myModel and myModel:FindFirstChild("SheathedWeapon")
                if unequipped and not equipped then
                    pcall(function() game:GetService("ReplicatedStorage").Files.Modules.Shared.Packet.RemoteEvent:FireServer(buffer.fromstring("\x03\x05Event\x1C\v\x04Name\v\x0EWeaponInteract\x00")) end)
                end
            end
        end
    end)
end

local function _calcFarmPos(rp)
    local mp=rp.Position; local base
    if _farmMode=="Above" then base=Vector3.new(mp.X,mp.Y+_farmOffZ,mp.Z)
    elseif _farmMode=="Below" then base=Vector3.new(mp.X,mp.Y-_farmOffZ,mp.Z)
    elseif _farmMode=="In Front" then base=mp+rp.CFrame.LookVector*_farmOffZ
    elseif _farmMode=="Behind" then base=mp-rp.CFrame.LookVector*_farmOffZ
    else base=Vector3.new(mp.X,mp.Y-_farmOffZ,mp.Z) end
    return base+Vector3.new(_farmOffX,_farmOffY,0)
end
local function nearestPlayer()
    local hrp=getHRP(); if not hrp then return end
    local best,bestD=nil,math.huge
    for _,plr in ipairs(PS:GetPlayers()) do
        if plr==LP then continue end
        if farmState.plrTarget~="" and plr.Name~=farmState.plrTarget then continue end
        local c=plr.Character; if not c then continue end
        local r=c:FindFirstChild("HumanoidRootPart"); local h=c:FindFirstChildOfClass("Humanoid")
        if not (r and h and h.Health>0) then continue end
        local d=(r.Position-hrp.Position).Magnitude
        if d<bestD then best=c; bestD=d end
    end
    return best
end
local function nearestMob()
    local hrp=getHRP(); if not hrp then return end
    local best,bestD=nil,math.huge
    local living=workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Entities"); if not living then return end
    local targetInfo=(farmState.mobTarget~="" and mobLabelMap[farmState.mobTarget]) or nil
    for _,mob in ipairs(living:GetChildren()) do
        if not mob:IsA("Model") then continue end
        if PS:GetPlayerFromCharacter(mob) then continue end
        if targetInfo then
            local ht=mob:GetAttribute("HollowType"); local hp=mob:GetAttribute("HollowSpawnPreset"); local ig=mob:GetAttribute("GenericHollowSpawn"); local team=mob:GetAttribute("Team")
            local matchHT=targetInfo.HollowType and ht==targetInfo.HollowType
            local matchPreset=targetInfo.HollowPreset and hp==targetInfo.HollowPreset and not targetInfo.HollowType
            local matchGeneric=targetInfo.IsGeneric and ig==true and not targetInfo.HollowType and not targetInfo.HollowPreset
            local matchTeam=targetInfo.Team and team==targetInfo.Team and not targetInfo.HollowType and not targetInfo.HollowPreset
            local matchName=targetInfo.Name~="" and mob.Name==targetInfo.Name and not targetInfo.HollowType and not targetInfo.HollowPreset and not targetInfo.Team
            if not (matchHT or matchPreset or matchGeneric or matchTeam or matchName) then continue end
        end
        local r=mob:FindFirstChild("HumanoidRootPart"); local h=mob:FindFirstChildOfClass("Humanoid")
        if not (r and h and h.Health>0) then continue end
        local d=(r.Position-hrp.Position).Magnitude
        if d<bestD then best=mob; bestD=d end
    end
    return best
end
local function enableFarmCombat() getgenv()._ZH_autoEquip=true; getgenv()._ZH_autoM1=true; getgenv()._ZH_autoCrit=true end
local function disableFarmCombat() getgenv()._ZH_autoEquip=false; getgenv()._ZH_autoM1=false; getgenv()._ZH_autoCrit=false end
local function makeFarmLoop(targetFn, activeKey)
    local lastTgt,pickTime=nil,0
    return RS.Heartbeat:Connect(function()
        if not farmState[activeKey] then return end
        local c=getChar(); if not c then lastTgt=nil; return end
        local hum=c:FindFirstChildOfClass("Humanoid"); if not hum or not hum.RootPart then lastTgt=nil; return end
        if hum.Health<=0 then lastTgt=nil; return end
        local hrp=hum.RootPart; hum.Health=hum.MaxHealth
        local now=tick()
        if not lastTgt or not lastTgt.Parent or not lastTgt:FindFirstChildOfClass("Humanoid") or lastTgt:FindFirstChildOfClass("Humanoid").Health<=0 or now-pickTime>=0.5 then
            lastTgt=targetFn(); pickTime=now
        end
        if lastTgt then
            local rp=lastTgt:FindFirstChild("HumanoidRootPart")
            if rp then
                hrp.CFrame=CFrame.lookAt(_calcFarmPos(rp),rp.Position)
                hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
            end
        else
            pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",nil) end end)
        end
    end)
end

-- PLAYER FARM
GameL:Label({ Text="Player Farm" })
local plrList={"Any (Closest)"}
for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(plrList,plr.Name) end end
Opt.PlrSelect = GameL:Dropdown({ Name="Target Player", Options=plrList, Default=1, Multi=false,
    Callback=function(v) local sel=type(v)=="table" and next(v) or v; farmState.plrTarget=(sel=="Any (Closest)") and "" or tostring(sel) end }, "PlrSelect")
local function updatePlrList()
    local list={"Any (Closest)"}
    for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(list,plr.Name) end end
    if Opt.PlrSelect then pcall(function() Opt.PlrSelect:ClearOptions(); Opt.PlrSelect:InsertOptions(list) end) end
end
PS.PlayerAdded:Connect(function() task.defer(updatePlrList) end)
PS.PlayerRemoving:Connect(function() task.defer(updatePlrList) end)
Tog.AutoFarmPlrs = GameL:Toggle({ Name="Farm Players", Default=false, Keybind=Enum.KeyCode.Unknown,
    Callback=function(p)
        farmState.plrs=p
        if farmConns.plrs then farmConns.plrs:Disconnect(); farmConns.plrs=nil end
        if p then enableFarmCombat(); farmConns.plrs=makeFarmLoop(nearestPlayer,"plrs") else disableFarmCombat() end
    end }, "AutoFarmPlrs")

-- MOB FARM
GameL2:Label({ Text="Mob Farm" })
local function buildMobLabel(mob)
    local hollowType=mob:GetAttribute("HollowType"); local hollowPreset=mob:GetAttribute("HollowSpawnPreset"); local isGeneric=mob:GetAttribute("GenericHollowSpawn"); local team=mob:GetAttribute("Team")
    if hollowType and hollowType~="" then return tostring(hollowType) end
    if hollowPreset and hollowPreset~="" then return tostring(hollowPreset) end
    if isGeneric then return "GenericHollow" end
    if team and team~="" then return tostring(team) end
    if mob.Name~="" then return mob.Name end
    return nil
end
local function scanMobList()
    local list={"Any (Closest)"}; mobLabelMap={}
    local living=workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Entities")
    if living then
        for _,mob in ipairs(living:GetChildren()) do
            if not mob:IsA("Model") then continue end
            if PS:GetPlayerFromCharacter(mob) then continue end
            local label=buildMobLabel(mob)
            if label and not mobLabelMap[label] then
                mobLabelMap[label]={ HollowType=mob:GetAttribute("HollowType"), HollowPreset=mob:GetAttribute("HollowSpawnPreset"), IsGeneric=mob:GetAttribute("GenericHollowSpawn"), Team=mob:GetAttribute("Team"), Name=mob.Name }
                table.insert(list,label)
            end
        end
    end
    table.sort(list,function(a,b) if a=="Any (Closest)" then return true end; if b=="Any (Closest)" then return false end; return a<b end)
    return list
end
Opt.MobSelect = GameL2:Dropdown({ Name="Target Mob", Options=scanMobList(), Default=1, Multi=false,
    Callback=function(v) local sel=type(v)=="table" and next(v) or v; farmState.mobTarget=(sel=="Any (Closest)") and "" or tostring(sel) end }, "MobSelect")
task.spawn(function() while true do task.wait(5); if Opt.MobSelect then pcall(function() Opt.MobSelect:ClearOptions(); Opt.MobSelect:InsertOptions(scanMobList()) end) end end end)
Tog.AutoFarmMobs = GameL2:Toggle({ Name="Autofarm Mobs", Default=false, Keybind=Enum.KeyCode.Unknown,
    Callback=function(p)
        farmState.mobs=p
        if farmConns.mobs then farmConns.mobs:Disconnect(); farmConns.mobs=nil end
        if p then enableFarmCombat(); farmConns.mobs=makeFarmLoop(nearestMob,"mobs") else disableFarmCombat() end
    end }, "AutoFarmMobs")

-- INSTA KILL
local function startInstaKill()
    if _instaKillConn then _instaKillConn:Disconnect() end
    _instaKillConn=RS.Heartbeat:Connect(function()
        local char=getChar(); if not char then return end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then return end
        pcall(function() sethiddenproperty(LP,"MaxSimulationRadius",math.huge); sethiddenproperty(LP,"SimulationRadius",math.huge) end)
        local hrp=getHRP(); if not hrp then return end
        local living=workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Entities"); if not living then return end
        local destroyY=workspace.FallenPartsDestroyHeight
        local range=Opt.IKRange and Opt.IKRange.Value or _ikRange
        local threshold=Opt.IKHealthThreshold and Opt.IKHealthThreshold.Value or _ikHealthThreshold
        for _,mob in ipairs(living:GetChildren()) do
            if not mob:IsA("Model") then continue end
            if PS:GetPlayerFromCharacter(mob) then continue end
            local pp=mob.PrimaryPart; if not pp then continue end
            local mobHum=mob:FindFirstChildOfClass("Humanoid"); if not mobHum then continue end
            if mobHum.Health<=0 then continue end
            if pp.Position.Y<=destroyY then continue end
            if threshold>0 and mobHum.Health>threshold then continue end
            if (pp.Position-hrp.Position).Magnitude>range then continue end
            pcall(function() mobHum.Health=0; mob:PivotTo(CFrame.new(pp.Position.X,destroyY-100,pp.Position.Z)) end)
        end
    end)
end
local function stopInstaKill() if _instaKillConn then _instaKillConn:Disconnect(); _instaKillConn=nil end end
Tog.InstaKillEnabled = GameL3:Toggle({ Name="Insta Kill", Default=false,
    Callback=function(p) if p then startInstaKill() else stopInstaKill() end end }, "InstaKillEnabled")
Opt.IKHealthThreshold = GameL3:Slider({ Name="HP Threshold", Default=0, Minimum=0, Maximum=1000000, Precision=0,
    Callback=function(v) _ikHealthThreshold=v end }, "IKHealthThreshold")
Opt.IKRange = GameL3:Slider({ Name="Range", Default=100, Minimum=10, Maximum=10000, Precision=0,
    Callback=function(v) _ikRange=v end }, "IKRange")
onUnload(function() stopInstaKill() end)

-- BRING
local function stopBringMobs() if _bringConn then _bringConn:Disconnect(); _bringConn=nil end end
local function startBringMobs()
    stopBringMobs()
    _bringConn=RS.Heartbeat:Connect(function()
        local char=getChar(); if not char then return end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then return end
        pcall(function() sethiddenproperty(LP,"MaxSimulationRadius",math.huge); sethiddenproperty(LP,"SimulationRadius",math.huge) end)
        local hrp=getHRP(); if not hrp then return end
        local living=workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Entities"); if not living then return end
        for _,mob in ipairs(living:GetChildren()) do
            if not mob:IsA("Model") then continue end
            if PS:GetPlayerFromCharacter(mob) then continue end
            local pp=mob.PrimaryPart; if not pp then continue end
            if not mob:FindFirstChildOfClass("Humanoid") then continue end
            if (pp.Position-hrp.Position).Magnitude>_bringRange then continue end
            pcall(function() mob:PivotTo(CFrame.new(hrp.Position+Vector3.new(0,0,-5))) end)
        end
    end)
end
Tog.BringMobEnabled = GameL4:Toggle({ Name="Bring Mobs", Default=false,
    Callback=function(p) if p then startBringMobs() else stopBringMobs() end end }, "BringMobEnabled")
Opt.BringRange = GameL4:Slider({ Name="Range", Default=100, Minimum=10, Maximum=10000, Precision=0,
    Callback=function(v) _bringRange=v end }, "BringRange")
onUnload(function() stopBringMobs() end)

-- FARM CONFIG (Position & Combat)
GameR:Label({ Text="Position" })
Opt.FarmMode = GameR:Dropdown({ Name="Position", Options={"Above","Below","In Front","Behind"}, Default=4, Multi=false,
    Callback=function(v) _farmMode=type(v)=="table" and next(v) or v end }, "FarmMode")
Opt.FarmOffsetX = GameR:Slider({ Name="X Offset", Default=0,   Minimum=-50, Maximum=50, Precision=1, Callback=function(v) _farmOffX=v end }, "FarmOffsetX")
Opt.FarmOffsetY = GameR:Slider({ Name="Y Offset", Default=0,   Minimum=-50, Maximum=50, Precision=1, Callback=function(v) _farmOffY=v end }, "FarmOffsetY")
Opt.FarmOffsetZ = GameR:Slider({ Name="Z Offset", Default=6.5, Minimum=0,   Maximum=50, Precision=1, Callback=function(v) _farmOffZ=v end }, "FarmOffsetZ")
GameR:Divider()
GameR:Label({ Text="Combat" })
Tog.AutoM1    = GameR:Toggle({ Name="Kill Aura",            Default=false, Callback=function(p) getgenv()._ZH_autoM1=p end }, "AutoM1")
Tog.AutoCrit  = GameR:Toggle({ Name="Auto Critical Aura",  Default=false, Callback=function(p) getgenv()._ZH_autoCrit=p end }, "AutoCrit")
Tog.AutoEquip = GameR:Toggle({ Name="Auto Equip",    Default=false, Callback=function(p) getgenv()._ZH_autoEquip=p end }, "AutoEquip")

-- MISSION FARM (full framework logic)
do
    local _missionTask=nil
    Tog.MissionFarmEnabled = GameR2:Toggle({ Name="Mission Farm", Default=false,
        Callback=function(p)
            if not p then if _missionTask then pcall(task.cancel,_missionTask); _missionTask=nil end; return end
            _missionTask=task.spawn(function()
                local fw
                for _,v in pairs(getgc(true)) do
                    if type(v)=="table" and rawget(v,"InvokeServer") and rawget(v,"GetModule") then fw=v; break end
                end
                if not fw then notify("Framework not found",3); Tog.MissionFarmEnabled:SetState(false); return end

                local function getRootPart()
                    local ch=LP.Character or LP.CharacterAdded:Wait()
                    return ch:WaitForChild("HumanoidRootPart")
                end

                local function tpTo(target)
                    local root=getRootPart(); if not root.Parent or not target.Parent then return end
                    local tPos=target.Position
                    root.CFrame=CFrame.new(tPos)*CFrame.new(0,0,3)
                    root.AssemblyLinearVelocity=Vector3.zero
                end

                local function stayNearAndPrompt(target, getPromptFrom, timeout)
                    timeout = timeout or 30
                    local start = tick()
                    while LP:GetAttribute("InMission") and (tick()-start)<timeout do
                        if not target or not target.Parent then break end
                        local root=getRootPart()
                        local tPos=target.Position
                        if (root.Position-tPos).Magnitude > 12 then tpTo(target) end
                        -- spam any prompt found
                        local source = getPromptFrom or target
                        if source and source.Parent then
                            local pr = source:FindFirstChildWhichIsA("ProximityPrompt",true)
                            if pr and pr.Enabled then pcall(fireproximityprompt, pr) end
                        end
                        task.wait(0.3)
                    end
                end

                while true do
                    task.wait(1)
                    if not (Tog.MissionFarmEnabled and Tog.MissionFarmEnabled.State) then break end
                    -- wait for any active mission to finish
                    if LP:GetAttribute("InMission") then while LP:GetAttribute("InMission") do task.wait(1) end; task.wait(2) end

                    -- get available missions
                    local locs=fw:InvokeServer("RequestLocationData",{"Cleanup Duty"})
                    local uuid,locName=nil,nil
                    for u,n in pairs(locs) do
                        if n=="Commercial District" or n=="Residential Area" or n=="Outskirts" then uuid=u; locName=n; break end
                    end
                    if not uuid then task.wait(5); continue end

                    -- tp to mission board
                    local root=getRootPart()
                    local tower=workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Destructable")
                    if tower then
                        local ch=tower:GetChildren()
                        if ch[7] then
                            local tp=ch[7]:FindFirstChild("Union")
                            if tp then tpTo(tp); task.wait(0.5) end
                        end
                    end

                    -- engage mission
                    local res=fw:InvokeServer("OverworldMissions",{ Request="Engage", Identification=uuid, Conditions={"Bloodlust","Flawless"}, Directive="Cleanup Duty" })
                    if res~=true then task.wait(3); continue end
                    task.wait(4.5)

                    -- find devil in Effects — keep searching
                    local world=workspace:WaitForChild("World")
                    local effects=world:WaitForChild("Effects")
                    local devil=nil
                    local searchStart=tick()
                    while LP:GetAttribute("InMission") and (tick()-searchStart)<20 do
                        for _,obj in pairs(effects:GetChildren()) do
                            if obj.Name:match("Devil") or obj.Name:match("Curse") or obj.Name:match("Invader") then devil=obj; break end
                        end
                        if devil then break end
                        task.wait(0.5)
                    end
                    if not devil then continue end

                    -- get devil part
                    local dPart=devil:IsA("BasePart") and devil or devil:FindFirstChildWhichIsA("BasePart",true)
                    if not dPart then continue end

                    -- continuously TP to devil and spam prompt until it's gone or mission state changes
                    stayNearAndPrompt(dPart, devil, 60)
                    task.wait(1)

                    -- find TurnIn in the CORRECT location folder
                    local turnIn=nil
                    local turnInSearch=tick()
                    while LP:GetAttribute("InMission") and (tick()-turnInSearch)<15 do
                        local m=world:FindFirstChild("Missions")
                        if m then
                            local cd=m:FindFirstChild("Cleanup Duty")
                            if cd then
                                local loc=cd:FindFirstChild(locName)
                                if loc then
                                    turnIn=loc:FindFirstChild("TurnIn")
                                    if turnIn then break end
                                end
                            end
                        end
                        task.wait(0.5)
                    end
                    if not turnIn or not LP:GetAttribute("InMission") then continue end

                    -- get turnin part
                    local tPart=turnIn:IsA("BasePart") and turnIn or turnIn:FindFirstChildWhichIsA("BasePart",true)
                    if not tPart then continue end

                    -- continuously TP to TurnIn and spam prompt until mission ends
                    stayNearAndPrompt(tPart, turnIn, 30)
                end
            end)
        end }, "MissionFarmEnabled")
    onUnload(function() if _missionTask then pcall(task.cancel,_missionTask); _missionTask=nil end end)
end

-- FREEZE MOB
local _frozenParts={}
local _freezeConn2=nil
local function freezeRoot(v)
    if not v:IsA("BasePart") or v.Name~="HumanoidRootPart" then return end
    local myChar=getChar(); if myChar and v:IsDescendantOf(myChar) then return end
    local living=workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Entities")
    if not living or not v:IsDescendantOf(living) then return end
    if PS:GetPlayerFromCharacter(v.Parent) then return end
    if not v.Parent:FindFirstChildWhichIsA("Humanoid") then return end
    if v:FindFirstChild("xZHFreezeConn") then return end
    local myHRP=getHRP()
    if myHRP and (v.Position-myHRP.Position).Magnitude>_freezeRange then return end
    local frozenCF=v.CFrame
    local tag=Instance.new("StringValue"); tag.Name="xZHFreezeConn"; tag.Parent=v
    local conn=RS.Heartbeat:Connect(function()
        if not v or not v.Parent then conn:Disconnect(); return end
        if not tag.Parent then conn:Disconnect(); return end
        v.AssemblyLinearVelocity=Vector3.zero; v.AssemblyAngularVelocity=Vector3.zero; v.CFrame=frozenCF
    end)
    table.insert(_frozenParts,{conn=conn,tag=tag})
end
local function stopFreezeMob()
    for _,d in ipairs(_frozenParts) do pcall(function() if d.conn then d.conn:Disconnect() end; if d.tag and d.tag.Parent then d.tag:Destroy() end end) end
    _frozenParts={}
    if _freezeConn2 then _freezeConn2:Disconnect(); _freezeConn2=nil end
end
local function startFreezeMob()
    stopFreezeMob()
    local living=workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Entities")
    if living then for _,model in ipairs(living:GetChildren()) do if PS:GetPlayerFromCharacter(model) then continue end; local hrp=model:FindFirstChild("HumanoidRootPart"); if hrp then freezeRoot(hrp) end end end
    _freezeConn2=workspace.DescendantAdded:Connect(function(v)
        if v.Name=="HumanoidRootPart" then local living2=workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Entities"); if living2 and v:IsDescendantOf(living2) then freezeRoot(v) end end
    end)
end
Tog.FreezeMobEnabled = GameR3:Toggle({ Name="Freeze Mob", Default=false,
    Callback=function(p) if p then startFreezeMob() else stopFreezeMob() end end }, "FreezeMobEnabled")
Opt.FreezeRange = GameR3:Slider({ Name="Range", Default=100, Minimum=10, Maximum=10000, Precision=0,
    Callback=function(v) _freezeRange=v; if Tog.FreezeMobEnabled and Tog.FreezeMobEnabled.State then startFreezeMob() end end }, "FreezeRange")
onUnload(function() stopFreezeMob() end)

-- NETWORK OWNERSHIP
local function hasNetworkOwnership(part)
    if isnetworkowner then local ok,r=pcall(isnetworkowner,part); return ok and r end
    local ok,result=pcall(function()
        local myHRP2=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not myHRP2 then return false end
        local ok1,myId=pcall(gethiddenproperty,myHRP2,"NetworkOwnerV3")
        local ok2,partId=pcall(gethiddenproperty,part,"NetworkOwnerV3")
        return ok1 and ok2 and myId~=nil and myId==partId
    end)
    return ok and result
end
local function updateOwnershipViz()
    for part,hl in pairs(_ownHighlights) do if not part or not part.Parent then pcall(function() hl:Destroy() end); _ownHighlights[part]=nil end end
    local ents=workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Entities"); if not ents then return end
    for _,model in ipairs(ents:GetChildren()) do
        if not model:IsA("Model") then continue end
        local hrp2=model:FindFirstChild("HumanoidRootPart"); if not hrp2 then continue end
        if not _ownHighlights[hrp2] then local hl2=Instance.new("Highlight",model); hl2.FillTransparency=0.7; _ownHighlights[hrp2]=hl2 end
        local hl2=_ownHighlights[hrp2]
        local owned=pcall(hasNetworkOwnership,hrp2) and hasNetworkOwnership(hrp2)
        hl2.FillColor=owned and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
        hl2.OutlineColor=hl2.FillColor
    end
end
Tog.ShowOwnership = GameR4:Toggle({ Name="Show Ownership", Default=false,
    Callback=function(p)
        if p then
            if not _ownVizConn then _ownVizConn=RS.Heartbeat:Connect(function() if Tog.ShowOwnership and Tog.ShowOwnership.State then updateOwnershipViz() end end) end
        else
            if _ownVizConn then _ownVizConn:Disconnect(); _ownVizConn=nil end
            for _,hl2 in pairs(_ownHighlights) do pcall(function() hl2:Destroy() end) end
            _ownHighlights={}
        end
    end }, "ShowOwnership")
GameR4:Label({ Text="Green = owned  |  Red = not owned" })
onUnload(function() if _ownVizConn then _ownVizConn:Disconnect() end; for _,hl2 in pairs(_ownHighlights) do pcall(function() hl2:Destroy() end) end end)

-- ============================================================
-- CHARACTER TAB CONTENT
-- ============================================================

-- POSITION
Opt.Coordinates = CharL:Input({ Name="Coordinates", Default="", Placeholder="X, Y, Z", Callback=function() end }, "Coordinates")
CharL:Button({ Name="Tween To", Callback=function() notify("Tween feature",2) end })
CharL:Button({ Name="Copy Position", Callback=function() local hrp=getHRP(); if hrp then setclipboard(tostring(hrp.Position)); notify("Copied") end end })
CharL:Button({ Name="Save Position", Callback=function() local hrp=getHRP(); if hrp then _savedPos=hrp.CFrame; notify("Saved",2) end end })
CharL:Button({ Name="TP to Saved", Callback=function() if not _savedPos then notify("No position saved",2); return end; local hrp=getHRP(); if hrp then hrp.CFrame=_savedPos; hrp.AssemblyLinearVelocity=Vector3.zero end end })

-- MOVEMENT
Tog.Fly = CharL2:Toggle({ Name="Fly", Default=false, Keybind=Enum.KeyCode.Y,
    Callback=function(p)
        if p then
            RS:BindToRenderStep("ZHFly",Enum.RenderPriority.Input.Value,function(dt)
                local c=getChar(); if not c then return end
                local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if not getgenv()._ZH_flyFrame then getgenv()._ZH_flyFrame=hrp.CFrame end
                local frame=getgenv()._ZH_flyFrame; local cf=Cam.CFrame; local mv=Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then mv=mv+cf.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then mv=mv-cf.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then mv=mv-cf.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then mv=mv+cf.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then mv=mv+Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv=mv-Vector3.new(0,1,0) end
                if mv.Magnitude>0 then frame=frame+mv.Unit*S.flySpeed*dt end
                getgenv()._ZH_flyFrame=frame; hrp.AssemblyLinearVelocity=Vector3.zero; hrp.CFrame=frame
            end)
        else RS:UnbindFromRenderStep("ZHFly"); getgenv()._ZH_flyFrame=nil end
    end }, "Fly")
Opt.FlySpeed = CharL2:Slider({ Name="Fly Speed", Default=100, Minimum=0, Maximum=5000, Precision=0,
    Callback=function(v) S.flySpeed=v end }, "FlySpeed")

Tog.Speedhack = CharL2:Toggle({ Name="Speedhack", Default=false, Keybind=Enum.KeyCode.N,
    Callback=function(p)
        if p then
            RS:BindToRenderStep("ZHSpeed",Enum.RenderPriority.Input.Value,function(dt)
                local c=getChar(); if not c then return end
                local hum=c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then return end
                local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if hum.MoveDirection.Magnitude>0 then hrp.CFrame=hrp.CFrame+hum.MoveDirection*S.speed*dt end
            end)
        else RS:UnbindFromRenderStep("ZHSpeed") end
    end }, "Speedhack")
Opt.SpeedhackSpeed = CharL2:Slider({ Name="Speed", Default=100, Minimum=0, Maximum=5000, Precision=0,
    Callback=function(v) S.speed=v end }, "SpeedhackSpeed")

local ijConn=nil
Tog.InfiniteJump = CharL2:Toggle({ Name="Infinite Jump", Default=false, Keybind=Enum.KeyCode.H,
    Callback=function(p)
        if ijConn then ijConn:Disconnect(); ijConn=nil end
        if p then ijConn=UIS.JumpRequest:Connect(function()
            local hrp=getHRP(); if hrp then hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X,S.infJumpH,hrp.AssemblyLinearVelocity.Z) end
        end) end
    end }, "InfiniteJump")
Opt.InfiniteJumpHeight = CharL2:Slider({ Name="Jump Height", Default=50, Minimum=0, Maximum=1000, Precision=0,
    Callback=function(v) S.infJumpH=v end }, "InfiniteJumpHeight")

local noclipConn=nil
Tog.Noclip = CharL2:Toggle({ Name="Noclip", Default=false, Keybind=Enum.KeyCode.Unknown,
    Callback=function(p)
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
        if p then noclipConn=RS.RenderStepped:Connect(function()
            local c=getChar(); if not c then return end
            for _,part in ipairs(c:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=false end end
        end) end
    end }, "Noclip")

-- PLAYER
CharR:Button({ Name="Kill Yourself", Callback=function() local hum=getHum(); if hum then hum.Health=0 end end })
CharR:Divider()

local noAnimsThread=nil
local forcedTracks={}
local origTracks={}
Tog.NoAnims = CharR:Toggle({ Name="No Animations", Default=false,
    Callback=function(p)
        if noAnimsThread then pcall(task.cancel,noAnimsThread); noAnimsThread=nil end
        if p then
            local c=getChar(); if not c then return end
            local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
            local anim=hum:FindFirstChildOfClass("Animator"); if not anim then return end
            local dummy=Instance.new("Animation"); dummy.AnimationId="rbxassetid://109212722752"
            noAnimsThread=task.spawn(function()
                while Tog.NoAnims and Tog.NoAnims.State and hum and hum.Parent do
                    for _,track in ipairs(anim:GetPlayingAnimationTracks()) do
                        if track.Animation.AnimationId~=dummy.AnimationId then
                            if not table.find(origTracks,track) then table.insert(origTracks,track) end
                            pcall(function() track:Stop(); task.defer(track.Destroy,track) end)
                        end
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
    end }, "NoAnims")

local _animSpeedConn=nil
local _animSpeed=1
local function applyAnimSpeed(speed)
    pcall(function()
        local char=getChar(); if not char then return end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local anim=hum:FindFirstChildOfClass("Animator"); if not anim then return end
        for _,track in ipairs(anim:GetPlayingAnimationTracks()) do pcall(function() track:AdjustSpeed(speed) end) end
    end)
end
Tog.AnimSpeed = CharR:Toggle({ Name="Animation Speed", Default=false,
    Callback=function(p)
        if _animSpeedConn then _animSpeedConn:Disconnect(); _animSpeedConn=nil end
        if p then _animSpeedConn=RS.Heartbeat:Connect(function() applyAnimSpeed(_animSpeed) end)
        else applyAnimSpeed(1) end
    end }, "AnimSpeed")
Opt.AnimSpeedSlider = CharR:Slider({ Name="Speed", Default=1, Minimum=0.1, Maximum=200, Precision=1,
    Callback=function(v) _animSpeed=v end }, "AnimSpeedSlider")
CharR:Divider()

Opt.AutoTPHP = CharR:Slider({ Name="HP Threshold", Default=20, Minimum=1, Maximum=99, Precision=0,
    Callback=function() end }, "AutoTPHP")
local _autoTPConn=nil
Tog.AutoTPSafe = CharR:Toggle({ Name="Auto TP on Low HP", Default=false,
    Callback=function(p)
        if _autoTPConn then _autoTPConn:Disconnect(); _autoTPConn=nil end
        if not p then return end
        _autoTPConn=RS.Heartbeat:Connect(function()
            if not _savedPos then return end
            local hum=getHum(); if not hum or hum.Health<=0 then return end
            if (hum.Health/hum.MaxHealth*100)<=(Opt.AutoTPHP and Opt.AutoTPHP.Value or 20) then
                local hrp=getHRP(); if hrp then hrp.CFrame=_savedPos; hrp.AssemblyLinearVelocity=Vector3.zero; notify("Low HP — safe!",2) end
            end
        end)
    end }, "AutoTPSafe")
CharR:Divider()

local afkConn=nil
Tog.AntiAFK = CharR:Toggle({ Name="Anti AFK", Default=true,
    Callback=function(p)
        if afkConn then pcall(task.cancel,afkConn); afkConn=nil end
        if not p then return end
        local VU=cloneref and cloneref(Instance.new("VirtualUser")) or game:GetService("VirtualUser")
        afkConn=task.spawn(function()
            while Tog.AntiAFK and Tog.AntiAFK.State do
                pcall(function() VU:Button2Down(Vector2.zero,Cam.CFrame); task.wait(0.1); VU:Button2Up(Vector2.zero,Cam.CFrame) end)
                task.wait(20)
            end
        end)
    end }, "AntiAFK")
CharR:Divider()

-- DESYNC (Physics)
local desyncThread=nil; local desyncTarget="Nearest"
local function getDesyncPart()
    local myHRP=getHRP(); if not myHRP then return nil end
    if desyncTarget=="Nearest" then
        local best,bestDist=nil,math.huge
        for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP and plr.Character then
            local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then local d=(hrp.Position-myHRP.Position).Magnitude; if d<bestDist then bestDist=d; best=hrp end end
        end end
        return best
    else local plr=PS:FindFirstChild(desyncTarget); return plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") end
end
Tog.Desync = CharR:Toggle({ Name="Physics Desync", Default=false,
    Callback=function(p)
        if desyncThread then pcall(task.cancel,desyncThread); desyncThread=nil end
        if not p then pcall(function() local hrp=getHRP(); if hrp then sethiddenproperty(hrp,"PhysicsRepRootPart",nil) end end); return end
        desyncThread=task.spawn(function()
            local char=LP.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            while RS.Heartbeat:Wait() do
                if LP.Character~=char then break end
                pcall(function() sethiddenproperty(hrp,"PhysicsRepRootPart",getDesyncPart()) end)
            end
        end)
    end }, "Desync")
local dList={"Nearest"}; for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(dList,plr.Name) end end
Opt.DesyncTarget = CharR:Dropdown({ Name="Desync Target", Options=dList, Default=1, Multi=false,
    Callback=function(v) desyncTarget=type(v)=="table" and next(v) or v end }, "DesyncTarget")
PS.PlayerAdded:Connect(function() task.defer(function()
    if Opt.DesyncTarget then local list={"Nearest"}; for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(list,plr.Name) end end; pcall(function() Opt.DesyncTarget:ClearOptions(); Opt.DesyncTarget:InsertOptions(list) end) end
end) end)
PS.PlayerRemoving:Connect(function() task.defer(function()
    if Opt.DesyncTarget then local list={"Nearest"}; for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(list,plr.Name) end end; pcall(function() Opt.DesyncTarget:ClearOptions(); Opt.DesyncTarget:InsertOptions(list) end) end
end) end)

-- RAKNET DESYNC (Risky)
Tog.RaknetDesync = CharR:Toggle({ Name="Raknet Desync", Default=false, Risky=true,
    Callback=function(p)
        local rn=getgenv().raknet
        if p then
            if not rn or not rn.add_send_hook then notify("raknet not available",3); Tog.RaknetDesync:SetState(false); return end
            if shared._zh_desync then pcall(function() rn.remove_send_hook(shared._zh_desync) end) end
            local packets_sent=0; local last_t1=nil
            local function on_send(packet)
                pcall(function()
                    local data=packet.AsBuffer; local pos=0
                    local function ru8()  local v=buffer.readu8(data,pos);  pos=pos+1; return v end
                    local function ru32() local v=buffer.readu32(data,pos); pos=pos+4; return v end
                    local function ru64() local l=ru32(); local h=ru32(); return h*4294967296+l end
                    local id=ru8(); if id~=0x1B then return end
                    local t1=ru64(); local t2=ru64(); local wid=ru8()
                    if wid~=0x85 then return end
                    packets_sent=packets_sent+1
                    local forced_t1=t1
                    if last_t1 and packets_sent%10~=0 then forced_t1=last_t1-1 end
                    last_t1=t1
                    local w=buffer.create(buffer.len(data)); local wp=0
                    local function wu8(v)  buffer.writeu8(w,wp,v);  wp=wp+1 end
                    local function wu32(v) buffer.writeu32(w,wp,v); wp=wp+4 end
                    local function wu64(v) wu32(bit32.band(v,0xFFFFFFFF)); wu32(bit32.rshift(v,32)) end
                    wu8(0x1B); wu64(forced_t1); wu64(t2); wu8(wid)
                    for i=pos,buffer.len(data)-1 do wu8(buffer.readu8(data,i)) end
                    rn.send(buffer.create(wp),packet.Priority,packet.Reliability,packet.OrderingChannel)
                    packet:Block()
                end)
            end
            shared._zh_desync=on_send; rn.add_send_hook(on_send); notify("Desync ON",2)
        else
            if shared._zh_desync and rn and rn.remove_send_hook then pcall(function() rn.remove_send_hook(shared._zh_desync) end); shared._zh_desync=nil end
            notify("Desync OFF",2)
        end
    end }, "RaknetDesync")

-- FAKE LAG (Risky)
Tog.FakeLag = CharR:Toggle({ Name="Fake Lag", Default=false, Risky=true,
    Callback=function(p)
        local rn=getgenv().raknet
        if p then
            if not rn or not rn.add_send_hook then notify("raknet not available",3); Tog.FakeLag:SetState(false); return end
            if shared._zh_fakelag then pcall(function() rn.remove_send_hook(shared._zh_fakelag) end) end
            local queued={}
            local function on_send(packet)
                local lagMs=Opt.FakeLagMs and Opt.FakeLagMs.Value or 200
                table.insert(queued,{ buf=packet.AsBuffer, pri=packet.Priority, rel=packet.Reliability, ord=packet.OrderingChannel, sendAt=tick()+lagMs/1000 })
                packet:Block()
            end
            shared._zh_fakelag=on_send; rn.add_send_hook(on_send)
            task.spawn(function()
                while Tog.FakeLag and Tog.FakeLag.State do
                    local now=tick()
                    for i=#queued,1,-1 do
                        if queued[i].sendAt<=now then local pk=queued[i]; pcall(function() rn.send(pk.buf,pk.pri,pk.rel,pk.ord) end); table.remove(queued,i) end
                    end
                    task.wait(0.016)
                end
                if shared._zh_fakelag and rn and rn.remove_send_hook then pcall(function() rn.remove_send_hook(shared._zh_fakelag) end); shared._zh_fakelag=nil end
                for _,pk in ipairs(queued) do pcall(function() rn.send(pk.buf,pk.pri,pk.rel,pk.ord) end) end
            end)
            notify("Fake Lag ON",2)
        else
            if shared._zh_fakelag and rn and rn.remove_send_hook then pcall(function() rn.remove_send_hook(shared._zh_fakelag) end); shared._zh_fakelag=nil end
            notify("Fake Lag OFF",2)
        end
    end }, "FakeLag")
Opt.FakeLagMs = CharR:Slider({ Name="Lag (ms)", Default=200, Minimum=50, Maximum=2000, Precision=0, Callback=function() end }, "FakeLagMs")
CharR:Divider()

-- AUTO REJOIN
CharR:Label({ Text="Auto Rejoin" })
Tog.AutoRejoin = CharR:Toggle({ Name="Auto Rejoin on Kick", Default=false,
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

-- ============================================================
-- FACE LOCK
-- ============================================================
do
    local FL = { enabled=false, sticky=false, vertInfl=false, smoothing=false, smoothFactor=0.1, stickyTarget=nil, conn=nil }
    local origAutoRotate=nil; local origAutoRotateHum=nil
    local function saveAutoRotate(hum)
        if origAutoRotate==nil then origAutoRotateHum=hum; origAutoRotate=hum.AutoRotate end
        hum.AutoRotate=false
    end
    local function restoreAutoRotate()
        if origAutoRotate~=nil and origAutoRotateHum and origAutoRotateHum.Parent then pcall(function() origAutoRotateHum.AutoRotate=origAutoRotate end) end
        origAutoRotate=nil; origAutoRotateHum=nil
    end
    local function getFLTarget()
        local c=getChar(); if not c then return nil end
        local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
        local ents=workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Entities"); if not ents then return nil end
        local best,bestDist=nil,math.huge
        for _,entity in ipairs(ents:GetChildren()) do
            if entity==c then continue end
            local hum=entity:FindFirstChildWhichIsA("Humanoid"); local root=entity:FindFirstChild("HumanoidRootPart")
            if not hum or not root or hum.Health<=0 then continue end
            local d=(root.Position-hrp.Position).Magnitude
            if d<bestDist then bestDist=d; best={character=entity,humanoid=hum,root=root} end
        end
        return best
    end
    local function startFL()
        if FL.conn then FL.conn:Disconnect(); FL.conn=nil end
        FL.conn=RS.RenderStepped:Connect(function()
            if not FL.enabled then restoreAutoRotate(); FL.stickyTarget=nil; return end
            local c=getChar(); if not c then return end
            local hum=c:FindFirstChildOfClass("Humanoid"); local hrp=c:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp or hum.PlatformStand then return end
            if FL.sticky then FL.stickyTarget=FL.stickyTarget or getFLTarget() end
            local target=FL.stickyTarget or getFLTarget()
            if not target or not target.character.Parent or target.humanoid.Health<=0 then restoreAutoRotate(); FL.stickyTarget=nil; return end
            local targetPos=target.root.Position
            if not FL.vertInfl then targetPos=Vector3.new(targetPos.X,hrp.Position.Y,targetPos.Z) end
            saveAutoRotate(hum)
            local targetCF=CFrame.lookAt(hrp.Position,targetPos)
            if FL.smoothing then local alpha=math.clamp(1-FL.smoothFactor,0,1); hrp.CFrame=hrp.CFrame:Lerp(targetCF,alpha)
            else hrp.CFrame=targetCF end
        end)
    end
    Tog.FaceLockEnabled = CharL3:Toggle({ Name="Face Lock", Default=false, Keybind=Enum.KeyCode.Unknown,
        Callback=function(p)
            FL.enabled=p
            if p then startFL()
            else restoreAutoRotate(); FL.stickyTarget=nil; if FL.conn then FL.conn:Disconnect(); FL.conn=nil end end
        end }, "FaceLockEnabled")
    Tog.FaceLockSticky = CharL3:Toggle({ Name="Sticky Target", Default=false, Callback=function(p) FL.sticky=p; FL.stickyTarget=nil end }, "FaceLockSticky")
    Tog.FaceLockVert = CharL3:Toggle({ Name="Vertical Influence", Default=false, Callback=function(p) FL.vertInfl=p end }, "FaceLockVert")
    Tog.FaceLockSmooth = CharL3:Toggle({ Name="Smoothing", Default=false, Callback=function(p) FL.smoothing=p end }, "FaceLockSmooth")
    Opt.FaceLockSmoothFactor = CharL3:Slider({ Name="Smooth Factor", Default=10, Minimum=1, Maximum=99, Precision=0, Callback=function(v) FL.smoothFactor=v/100 end }, "FaceLockSmoothFactor")
    onUnload(function() FL.enabled=false; restoreAutoRotate(); if FL.conn then FL.conn:Disconnect(); FL.conn=nil end end)
    LP.CharacterAdded:Connect(function() FL.stickyTarget=nil; origAutoRotate=nil; if FL.enabled then task.wait(1); startFL() end end)
end

-- ============================================================
-- MORPHS
-- ============================================================
do
    local function removeClothingAndHead(char)
        if not char then return end
        pcall(function()
            for _,cls in ipairs({"Shirt","Pants"}) do local v=char:FindFirstChildOfClass(cls); if v then v:Destroy() end end
            for _,v in ipairs(char:GetChildren()) do if v:IsA("Accessory") then pcall(function() v:Destroy() end) end end
            local head=char:FindFirstChild("Head")
            if head then head.Transparency=1; for _,v in ipairs(head:GetDescendants()) do if v:IsA("Decal") then v:Destroy() end end end
        end)
    end
    local function attachAccessory(assetId,char,offset,rotation)
        if not char or not assetId then return end
        pcall(function()
            local obj=game:GetObjects("rbxassetid://"..tostring(assetId))[1]; if not obj then return end
            local torso=char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"); if not torso then return end
            obj.Parent=char
            local handle=obj:FindFirstChild("Handle"); if not handle then return end
            local weld=Instance.new("Weld"); weld.Part0=torso; weld.Part1=handle
            weld.C0=CFrame.new(offset or Vector3.zero)*CFrame.Angles(math.rad(rotation and rotation.X or 0),math.rad(rotation and rotation.Y or 0),math.rad(rotation and rotation.Z or 0))
            weld.Parent=handle; handle.Anchored=false
        end)
    end
    local function setShirtPants(shirtId,pantsId,char)
        if not char then return end
        pcall(function()
            if shirtId then local s=char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt",char); s.ShirtTemplate="rbxassetid://"..tostring(shirtId) end
            if pantsId then local p=char:FindFirstChildOfClass("Pants") or Instance.new("Pants",char); p.PantsTemplate="rbxassetid://"..tostring(pantsId) end
        end)
    end
    local MORPHS = {
        ["None"]=nil,
        ["Goku"]=function(c) removeClothingAndHead(c); attachAccessory(96778240725860,c,Vector3.new(0,2.3,0)); setShirtPants(18642081551,13980707182,c) end,
        ["Naruto"]=function(c) removeClothingAndHead(c); attachAccessory(129818847988995,c,Vector3.new(0,1.8,0),Vector3.new(0,-90,0)); setShirtPants(6469644436,2733834231,c) end,
        ["Gojo"]=function(c) removeClothingAndHead(c); attachAccessory(132501783778842,c,Vector3.new(0,1.9,0)); setShirtPants(73084050138865,15312673306,c) end,
        ["Toji"]=function(c) removeClothingAndHead(c); attachAccessory(135664715112347,c,Vector3.new(0,1.7,0)); setShirtPants(121088463088431,16149857407,c) end,
        ["Aizen"]=function(c) removeClothingAndHead(c); attachAccessory(117644781784979,c,Vector3.new(0,1.7,0)); setShirtPants(87853669951881,118029167731205,c) end,
        ["Guts"]=function(c) removeClothingAndHead(c); attachAccessory(117337600216775,c,Vector3.new(0,1.6,0)); setShirtPants(13381096342,13381103162,c) end,
        ["Vasto Lorde"]=function(c) removeClothingAndHead(c); attachAccessory(107798985962651,c,Vector3.new(0,1.7,0)); setShirtPants(15549196125,15886594659,c) end,
        ["Luffy"]=function(c) removeClothingAndHead(c); attachAccessory(103832443149308,c,Vector3.new(0,1.5,0)); setShirtPants(8483860912,6274345723,c) end,
        ["Zero Two"]=function(c) removeClothingAndHead(c); attachAccessory(93023559996037,c,Vector3.new(0,1.2,0)); setShirtPants(6392201226,5896597102,c) end,
    }
    local morphNames={"None"}
    for k in pairs(MORPHS) do if k~="None" then table.insert(morphNames,k) end end
    table.sort(morphNames)
    Opt.MorphSelect = CharL4:Dropdown({ Name="Morph", Options=morphNames, Default=1, Multi=false,
        Callback=function(v)
            local sel=type(v)=="table" and next(v) or v
            if sel=="None" or not sel then return end
            local fn=MORPHS[sel]; if not fn then return end
            local c=LP and LP.Character; if not c then notify("No character",2); return end
            fn(c); notify("Morph: "..sel,3)
        end }, "MorphSelect")
    CharL4:Button({ Name="Reset", Callback=function()
        pcall(function() local char=LP and LP.Character; if not char then return end; local head=char:FindFirstChild("Head"); if head then head.Transparency=0 end; notify("Reload character to fully reset",3) end)
    end})
end

-- COMBAT (AIMBOT) - full working logic from Universal
local aimbotConn=nil
local fovCircle=nil
local function getFOVScale() return Cam.ViewportSize.Y/2/math.tan(math.rad(Cam.FieldOfView/2)) end
local function getAimTargets()
    local list={}
    if S.targetPlayers then
        for _,plr in ipairs(PS:GetPlayers()) do
            if plr~=LP and plr.Character then
                if not S.teamCheck or not LP.Team or plr.Team~=LP.Team then table.insert(list,plr.Character) end
            end
        end
    end
    return list
end
local function getAimPart(char)
    local v=Opt.AimPart and Opt.AimPart.Value or "Head"
    if type(v)=="table" then v=next(v) end
    if v=="Head" then return char:FindFirstChild("Head") end
    if v=="Torso" then return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") end
    if v=="Random" then
        local parts={}; for _,n in ipairs({"Head","HumanoidRootPart","Torso"}) do local p=char:FindFirstChild(n); if p then table.insert(parts,p) end end
        return #parts>0 and parts[math.random(1,#parts)] or nil
    end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
end
local function isVisible(part)
    if not S.visibleOnly then return true end
    local c=getChar(); if not c then return false end
    local ray=Ray.new(Cam.CFrame.Position,(part.Position-Cam.CFrame.Position).Unit*1000)
    local hit=workspace:FindPartOnRayWithIgnoreList(ray,{c,Cam})
    return hit and hit:IsDescendantOf(part.Parent)
end
UIS.InputBegan:Connect(function(inp,gpe)
    if gpe then return end
    local n=inp.UserInputType==Enum.UserInputType.MouseButton1 and "MB1" or inp.UserInputType==Enum.UserInputType.MouseButton2 and "MB2" or inp.KeyCode.Name
    local key=Opt.AimbotKeybind and tostring(Opt.AimbotKeybind.Value) or "MB2"
    if n==key and S.aimbotMode=="Hold" then S.aimbotActive=true end
end)
UIS.InputEnded:Connect(function(inp)
    local n=inp.UserInputType==Enum.UserInputType.MouseButton1 and "MB1" or inp.UserInputType==Enum.UserInputType.MouseButton2 and "MB2" or inp.KeyCode.Name
    local key=Opt.AimbotKeybind and tostring(Opt.AimbotKeybind.Value) or "MB2"
    if n==key and S.aimbotMode=="Hold" then S.aimbotActive=false end
end)

Opt.AimbotMode = CharR2:Dropdown({ Name="Aimbot Mode", Options={"Toggle","Hold","Always"}, Default=1, Multi=false,
    Callback=function(v) S.aimbotMode=type(v)=="table" and next(v) or v; if S.aimbotMode=="Always" then S.aimbotActive=true elseif S.aimbotMode~="Hold" then S.aimbotActive=false end end }, "AimbotMode")
Opt.AimbotMethod = CharR2:Dropdown({ Name="Aimbot Method", Options={"Camera","mousemoverel"}, Default=1, Multi=false,
    Callback=function(v) S.aimbotMethod=type(v)=="table" and next(v) or v end }, "AimbotMethod")
Opt.AimPart = CharR2:Dropdown({ Name="Aim Part", Options={"Head","Torso","Random"}, Default=1, Multi=false, Callback=function() end }, "AimPart")
Opt.AimbotKeybind = CharR2:Keybind({ Name="Aimbot Keybind", Default=Enum.KeyCode.Unknown,
    onBinded=function() if S.aimbotMode=="Toggle" then S.aimbotActive=not S.aimbotActive end end }, "AimbotKeybind")
Tog.Aimbot = CharR2:Toggle({ Name="Aimbot", Default=false,
    Callback=function(p)
        S.aimbotEnabled=p
        if aimbotConn then aimbotConn:Disconnect(); aimbotConn=nil end
        if not p then S.aimbotActive=false; return end
        if S.aimbotMode=="Always" then S.aimbotActive=true end
        local accum=Vector2.zero
        aimbotConn=RS.RenderStepped:Connect(function()
            if not S.aimbotActive then return end
            local vpSize=Cam.ViewportSize; local cx=vpSize.X/2+S.aimbotX; local cy=vpSize.Y/2+S.aimbotY
            local fovPx=math.tan(math.rad(S.aimbotFOV/2))*getFOVScale()
            local best,bestDist=nil,fovPx
            for _,char in ipairs(getAimTargets()) do
                local part=getAimPart(char); if not part then continue end
                local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then continue end
                if not isVisible(part) then continue end
                local sp,onScreen=Cam:WorldToViewportPoint(part.Position); if not onScreen then continue end
                local d=((sp.X-cx)^2+(sp.Y-cy)^2)^0.5; if d<bestDist then bestDist=d; best=part end
            end
            if best then
                local target=best.Position
                if S.aimbotX~=0 or S.aimbotY~=0 then
                    local v=Cam:WorldToViewportPoint(target)
                    local shifted=Vector2.new(v.X+S.aimbotX,v.Y+S.aimbotY)
                    local ray=Cam:ViewportPointToRay(shifted.X,shifted.Y)
                    target=ray.Origin+ray.Direction*100
                end
                if S.aimbotMethod=="Camera" then
                    local t=math.clamp(S.aimbotSens*0.1,0.01,1)
                    local lv=Cam.CFrame.LookVector:Lerp((target-Cam.CFrame.Position).Unit,t)
                    Cam.CFrame=CFrame.new(Cam.CFrame.Position,Cam.CFrame.Position+lv)
                else
                    local sp2=Cam:WorldToViewportPoint(target)
                    local mouse=UIS:GetMouseLocation()
                    accum=accum+(Vector2.new(sp2.X,sp2.Y)-mouse)*S.aimbotSens
                    local cap=10
                    local clamped=Vector2.new(math.clamp(accum.X,-cap,cap),math.clamp(accum.Y,-cap,cap))
                    pcall(function() mousemoverel(clamped.X,clamped.Y) end)
                    accum=accum-clamped
                end
            end
        end)
    end }, "Aimbot")
CharR2:Divider()
Tog.AimbotPlayers = CharR2:Toggle({ Name="Target Players", Default=true, Callback=function(p) S.targetPlayers=p end }, "AimbotPlayers")
Tog.VisibleOnly = CharR2:Toggle({ Name="Visible Only", Default=false, Callback=function(p) S.visibleOnly=p end }, "VisibleOnly")
Tog.TeamCheck = CharR2:Toggle({ Name="Team Check", Default=false, Callback=function(p) S.teamCheck=p end }, "TeamCheck")
Opt.AimbotSens = CharR2:Slider({ Name="Sensitivity", Default=1, Minimum=0.1, Maximum=5, Precision=2, Callback=function(v) S.aimbotSens=v end }, "AimbotSens")
Opt.AimbotXOffset = CharR2:Slider({ Name="X Offset", Default=0, Minimum=-300, Maximum=300, Precision=0, Callback=function(v) S.aimbotX=v end }, "AimbotXOffset")
Opt.AimbotYOffset = CharR2:Slider({ Name="Y Offset", Default=0, Minimum=-300, Maximum=300, Precision=0, Callback=function(v) S.aimbotY=v end }, "AimbotYOffset")
Tog.ShowFOV = CharR2:Toggle({ Name="Show FOV", Default=false,
    Callback=function(p)
        if p then
            if not fovCircle then fovCircle=Drawing.new("Circle"); fovCircle.Thickness=1; fovCircle.NumSides=100; fovCircle.Filled=false; fovCircle.Color=Color3.fromRGB(255,255,255) end
            fovCircle.Radius=S.aimbotFOV*getFOVScale(); fovCircle.Position=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2); fovCircle.Visible=true
        elseif fovCircle then fovCircle.Visible=false end
    end }, "ShowFOV")
Opt.AimbotFOV = CharR2:Slider({ Name="Aimbot FOV", Default=45, Minimum=1, Maximum=120, Precision=0,
    Callback=function(v) S.aimbotFOV=v; if fovCircle and fovCircle.Visible then fovCircle.Radius=v*getFOVScale() end end }, "AimbotFOV")

-- ============================================================
-- VISUALS TAB CONTENT (real Universal ESP logic)
-- ============================================================

-- PLAYER ESP RENDER
local function removeESP(char)
    local d=espActive[char]; if not d then return end
    pcall(function() if d.txt then d.txt:Remove() end end)
    pcall(function() if d.box then d.box:Remove() end end)
    pcall(function() if d.hpFill then d.hpFill:Remove() end end)
    pcall(function() if d.hpBack then d.hpBack:Remove() end end)
    pcall(function() if d.tracer then d.tracer:Remove() end end)
    pcall(function() if d.dot then d.dot:Remove() end end)
    pcall(function() if d.hl then d.hl:Destroy() end end)
    if d.rname then pcall(function() RS:UnbindFromRenderStep(d.rname) end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    if d.dieConn then pcall(function() d.dieConn:Disconnect() end) end
    espActive[char]=nil
end
local function addESP(char, plr)
    if not char or espActive[char] then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); local hrp=char:FindFirstChild("HumanoidRootPart"); local head=char:FindFirstChild("Head")
    if not (hum and hrp and head) then return end
    local txt=Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
    local box=Drawing.new("Square"); box.Filled=false; box.Thickness=1.5; box.Visible=false
    local hpFill=Drawing.new("Square"); hpFill.Filled=true; hpFill.Visible=false
    local hpBack=Drawing.new("Square"); hpBack.Filled=false; hpBack.Thickness=1; hpBack.Color=Color3.new(0,0,0); hpBack.Visible=false
    local tracer=Drawing.new("Line"); tracer.Thickness=1; tracer.Visible=false
    local dot=Drawing.new("Circle"); dot.Radius=4; dot.Filled=true; dot.Visible=false; dot.Thickness=1
    local hl=Instance.new("Highlight",char); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false
    local rname="ZH_ESP_"..char:GetDebugId()
    RS:BindToRenderStep(rname, Enum.RenderPriority.Camera.Value+1, function()
        if not (espEnabled and char and char.Parent) then removeESP(char); return end
        local myHRP=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
        local dist=(hrp.Position-myHRP.Position).Magnitude
        local maxDist=S.espDist or 1000
        local col=espColor or Color3.new(1,1,1)
        if dist>maxDist then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local components=_plrESP.components or {}
        local hasText=components["Text"]; local hasBox=components["Box 2D"]; local hasHP=components["HP Bar"]
        local hasTracer=components["Tracer"]; local hasHighlight=components["Highlight"]; local hasDot=components["Head Dot"]
        local sv,onS=Cam:WorldToViewportPoint(hrp.Position)
        local hv,onH=Cam:WorldToViewportPoint(head.Position)
        if not onS then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local scale=math.clamp(1/(sv.Z*0.04),0.5,3)
        local bw=35*scale; local bh=70*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
        local hpPct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
        local hpCol=Color3.fromHSV(hpPct*0.33,1,1)
        if hasBox then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
        if hasHP then
            local barW=6; local barX=bx-barW-3
            hpBack.Position=Vector2.new(barX-1,by-1); hpBack.Size=Vector2.new(barW+2,bh+2); hpBack.Visible=true
            hpFill.Position=Vector2.new(barX,by+bh*(1-hpPct)); hpFill.Size=Vector2.new(barW,bh*hpPct); hpFill.Color=hpCol; hpFill.Visible=true
        else hpFill.Visible=false; hpBack.Visible=false end
        if hasText then
            local parts={}
            local name=(plr and plr.DisplayName) or char.Name
            if _plrESP.showName then table.insert(parts,name) end
            if _plrESP.showCharName and plr then local cn=plr:GetAttribute("CharacterName"); if cn and cn~="" then table.insert(parts,"("..cn..")") end end
            if _plrESP.showRank and plr then local r=plr:GetAttribute("Rank"); if r then table.insert(parts,"["..r.."]") end end
            if _plrESP.showFaction and plr then local f=plr:GetAttribute("Faction"); if f then table.insert(parts,"{"..f.."}") end end
            if _plrESP.showDiv and plr then local d=plr:GetAttribute("Division"); if d then table.insert(parts,"D"..tostring(d)) end end
            if _plrESP.showHP then table.insert(parts,string.format("[%d/%d]",hum.Health,hum.MaxHealth)) end
            if _plrESP.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end
            txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14
            txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0
        else txt.Visible=false end
        if hasTracer then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
        if hasDot and onH then dot.Position=Vector2.new(hv.X,hv.Y); dot.Color=col; dot.Visible=true else dot.Visible=false end
        hl.Enabled=hasHighlight and espEnabled; hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
    end)
    espActive[char]={ txt=txt, box=box, hpFill=hpFill, hpBack=hpBack, tracer=tracer, dot=dot, hl=hl, rname=rname,
        ancConn=char.AncestryChanged:Connect(function(_,p) if not p then removeESP(char) end end),
        dieConn=hum.Died:Connect(function() task.wait(3); removeESP(char) end) }
end

-- RAINBOW LOOP
RS.Heartbeat:Connect(function(dt)
    _hue=(_hue+dt*0.25)%1
    local rc=Color3.fromHSV(_hue,1,1)
    if S.espRainbow then espColor=rc end
    if _mobESP2.rainbow then mobESPColor2=rc end
    if _npcESP2.rainbow then npcESPColor2=rc end
end)

-- PLAYER ESP UI
Tog.PlayerESPEnabled = VizL:Toggle({ Name="Player ESP", Default=false,
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
            local _eList={}; for c in pairs(espActive) do _eList[#_eList+1]=c end; for _,c in ipairs(_eList) do removeESP(c) end
        end
    end }, "PlayerESPEnabled")
Opt.ESPColor = VizL:Colorpicker({ Name="ESP Color", Default=Color3.fromRGB(255,255,255), Alpha=0, Callback=function(col) espColor=col end }, "ESPColor")
Tog.ESPRainbow  = VizL:Toggle({ Name="Rainbow",  Default=false, Callback=function(p) S.espRainbow=p  end }, "ESPRainbow")
Tog.ESPShowName = VizL:Toggle({ Name="Name",     Default=true,  Callback=function(p) _plrESP.showName=p end }, "ESPShowName")
Tog.ESPShowHP   = VizL:Toggle({ Name="Health",   Default=false, Callback=function(p) _plrESP.showHP=p   end }, "ESPShowHP")
Tog.ESPShowDist = VizL:Toggle({ Name="Distance", Default=false, Callback=function(p) _plrESP.showDist=p end }, "ESPShowDist")
Tog.ESPShowCharName = VizL:Toggle({ Name="Character Name", Default=false, Callback=function(p) _plrESP.showCharName=p end }, "ESPShowCharName")
Tog.ESPShowRank = VizL:Toggle({ Name="Rank", Default=false, Callback=function(p) _plrESP.showRank=p end }, "ESPShowRank")
Tog.ESPShowFaction = VizL:Toggle({ Name="Faction", Default=false, Callback=function(p) _plrESP.showFaction=p end }, "ESPShowFaction")
Tog.ESPShowDiv = VizL:Toggle({ Name="Division", Default=false, Callback=function(p) _plrESP.showDiv=p end }, "ESPShowDiv")
Opt.PlrESPComponents = VizL:Dropdown({ Name="Components", Multi=true, Default={}, Options={"Text","Highlight","Tracer","Box 2D","HP Bar","Head Dot"},
    Callback=function(v) _plrESP.components=v end }, "PlrESPComponents")

-- MOB ESP RENDER
local function removeMobESP(mob)
    local d=_mobESPActive[mob]; if not d then return end
    pcall(function() if d.txt then d.txt:Remove() end end); pcall(function() if d.box then d.box:Remove() end end)
    pcall(function() if d.hpFill then d.hpFill:Remove() end end); pcall(function() if d.hpBack then d.hpBack:Remove() end end)
    pcall(function() if d.tracer then d.tracer:Remove() end end); pcall(function() if d.dot then d.dot:Remove() end end)
    pcall(function() if d.hl then d.hl:Destroy() end end)
    if d.conn then pcall(function() d.conn:Disconnect() end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    _mobESPActive[mob]=nil
end
local function addMobESP(mob)
    if not mob or _mobESPActive[mob] then return end
    local hum=mob:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local hrp=mob:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local head=mob:FindFirstChild("Head")
    local txt=Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
    local box=Drawing.new("Square"); box.Filled=false; box.Thickness=1.5; box.Visible=false
    local hpFill=Drawing.new("Square"); hpFill.Filled=true; hpFill.Visible=false
    local hpBack=Drawing.new("Square"); hpBack.Filled=false; hpBack.Thickness=1; hpBack.Color=Color3.new(0,0,0); hpBack.Visible=false
    local tracer=Drawing.new("Line"); tracer.Thickness=1; tracer.Visible=false
    local dot=Drawing.new("Circle"); dot.Radius=4; dot.Filled=true; dot.Visible=false; dot.Thickness=1
    local hl=Instance.new("Highlight",mob); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false
    _espCount2=_espCount2+1
    local conn=RS.Heartbeat:Connect(function()
        if not (_mobESPEnabled and mob and mob.Parent) then removeMobESP(mob); return end
        local myHRP=getHRP(); if not myHRP then return end
        local col=mobESPColor2; local dist=(hrp.Position-myHRP.Position).Magnitude; local comps=_mobESP2.components or {}
        if dist>(S.espDist or 1000) then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local sv,onS=Cam:WorldToViewportPoint(hrp.Position)
        local hv,onH=head and Cam:WorldToViewportPoint(head.Position)
        if not onS then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local scale=math.clamp(1/(sv.Z*0.04),0.5,3)
        local bw=35*scale; local bh=70*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
        local hpPct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1); local hpCol=Color3.fromHSV(hpPct*0.33,1,1)
        if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
        if comps["HP Bar"] then
            local barW=6; local barX=bx-barW-3
            hpBack.Position=Vector2.new(barX-1,by-1); hpBack.Size=Vector2.new(barW+2,bh+2); hpBack.Visible=true
            hpFill.Position=Vector2.new(barX,by+bh*(1-hpPct)); hpFill.Size=Vector2.new(barW,bh*hpPct); hpFill.Color=hpCol; hpFill.Visible=true
        else hpFill.Visible=false; hpBack.Visible=false end
        if comps["Text"] then
            local parts={}
            if _mobESP2.showName then table.insert(parts,mob.Name) end
            if _mobESP2.showHP then table.insert(parts,string.format("[%d/%d]",hum.Health,hum.MaxHealth)) end
            if _mobESP2.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end
            txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14
            txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0
        else txt.Visible=false end
        if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
        if comps["Head Dot"] and onH and head then dot.Position=Vector2.new(hv.X,hv.Y); dot.Color=col; dot.Visible=true else dot.Visible=false end
        hl.Enabled=comps["Highlight"] and _mobESPEnabled or false
        hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
    end)
    _mobESPActive[mob]={txt=txt,box=box,hpFill=hpFill,hpBack=hpBack,tracer=tracer,dot=dot,hl=hl,conn=conn,
        ancConn=mob.AncestryChanged:Connect(function(_,p) if not p then removeMobESP(mob) end end)}
end
local function scanMobESP()
    local living=workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Entities"); if not living then return end
    for _,m in ipairs(living:GetChildren()) do if m:IsA("Model") and not PS:GetPlayerFromCharacter(m) then addMobESP(m) end end
end
local function stopMobESP() _mobESPEnabled=false; local l={}; for mob in pairs(_mobESPActive) do l[#l+1]=mob end; for _,mob in ipairs(l) do removeMobESP(mob) end end

-- MOB ESP UI
Tog.MobESPEnabled = VizL2:Toggle({ Name="Mob ESP", Default=false,
    Callback=function(p)
        _mobESPEnabled=p
        if p then scanMobESP(); task.spawn(function() while _mobESPEnabled do task.wait(3); scanMobESP() end end) else stopMobESP() end
    end }, "MobESPEnabled")
Opt.MobESPColor2 = VizL2:Colorpicker({ Name="Mob Color", Default=Color3.fromRGB(255,100,100), Alpha=0, Callback=function(c) mobESPColor2=c end }, "MobESPColor2")
Tog.MobESPRainbow2 = VizL2:Toggle({ Name="Rainbow",  Default=false, Callback=function(p) _mobESP2.rainbow=p  end }, "MobESPRainbow2")
Tog.MobESPShowName = VizL2:Toggle({ Name="Name",     Default=false, Callback=function(p) _mobESP2.showName=p end }, "MobESPShowName")
Tog.MobESPShowHP   = VizL2:Toggle({ Name="Health",   Default=false, Callback=function(p) _mobESP2.showHP=p   end }, "MobESPShowHP")
Tog.MobESPShowDist = VizL2:Toggle({ Name="Distance", Default=false, Callback=function(p) _mobESP2.showDist=p end }, "MobESPShowDist")
Opt.MobESPComponents = VizL2:Dropdown({ Name="Components", Multi=true, Default={}, Options={"Text","Highlight","Tracer","Box 2D","HP Bar","Head Dot"},
    Callback=function(v) _mobESP2.components=v end }, "MobESPComponents")
onUnload(function() stopMobESP() end)

-- NPC ESP RENDER
local function removeNPCESP(npc)
    local d=_npcESPActive[npc]; if not d then return end
    pcall(function() if d.txt then d.txt:Remove() end end); pcall(function() if d.box then d.box:Remove() end end)
    pcall(function() if d.hpFill then d.hpFill:Remove() end end); pcall(function() if d.hpBack then d.hpBack:Remove() end end)
    pcall(function() if d.tracer then d.tracer:Remove() end end); pcall(function() if d.dot then d.dot:Remove() end end)
    pcall(function() if d.hl then d.hl:Destroy() end end)
    if d.conn then pcall(function() d.conn:Disconnect() end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    _npcESPActive[npc]=nil
end
local function addNPCESP(npc,label)
    if not npc or _npcESPActive[npc] then return end
    local hrp=npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart; if not hrp then return end
    local hum=npc:FindFirstChildOfClass("Humanoid"); local head=npc:FindFirstChild("Head")
    local txt=Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
    local box=Drawing.new("Square"); box.Filled=false; box.Thickness=1.5; box.Visible=false
    local hpFill=Drawing.new("Square"); hpFill.Filled=true; hpFill.Visible=false
    local hpBack=Drawing.new("Square"); hpBack.Filled=false; hpBack.Thickness=1; hpBack.Color=Color3.new(0,0,0); hpBack.Visible=false
    local tracer=Drawing.new("Line"); tracer.Thickness=1; tracer.Visible=false
    local dot=Drawing.new("Circle"); dot.Radius=4; dot.Filled=true; dot.Visible=false; dot.Thickness=1
    local hl=Instance.new("Highlight",npc); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false
    _espCount2=_espCount2+1
    local conn=RS.Heartbeat:Connect(function()
        if not (_npcESPEnabled and npc and npc.Parent) then removeNPCESP(npc); return end
        local myHRP=getHRP(); if not myHRP then return end
        local col=npcESPColor2; local dist=(hrp.Position-myHRP.Position).Magnitude; local comps=_npcESP2.components or {}
        if dist>(S.espDist or 1000) then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local sv,onS=Cam:WorldToViewportPoint(hrp.Position)
        local hv,onH=head and Cam:WorldToViewportPoint(head.Position)
        if not onS then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local scale=math.clamp(1/(sv.Z*0.04),0.5,3)
        local bw=35*scale; local bh=70*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
        if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
        if comps["HP Bar"] and hum then
            local hpPct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1); local hpCol=Color3.fromHSV(hpPct*0.33,1,1)
            local barW=6; local barX=bx-barW-3
            hpBack.Position=Vector2.new(barX-1,by-1); hpBack.Size=Vector2.new(barW+2,bh+2); hpBack.Visible=true
            hpFill.Position=Vector2.new(barX,by+bh*(1-hpPct)); hpFill.Size=Vector2.new(barW,bh*hpPct); hpFill.Color=hpCol; hpFill.Visible=true
        else hpFill.Visible=false; hpBack.Visible=false end
        if comps["Text"] then
            local parts={}
            if _npcESP2.showName then table.insert(parts,label or npc.Name) end
            if _npcESP2.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end
            txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14
            txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0
        else txt.Visible=false end
        if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
        if comps["Head Dot"] and onH and head then dot.Position=Vector2.new(hv.X,hv.Y); dot.Color=col; dot.Visible=true else dot.Visible=false end
        hl.Enabled=comps["Highlight"] and _npcESPEnabled or false
        hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
    end)
    _npcESPActive[npc]={txt=txt,box=box,hpFill=hpFill,hpBack=hpBack,tracer=tracer,dot=dot,hl=hl,conn=conn,
        ancConn=npc.AncestryChanged:Connect(function(_,p) if not p then removeNPCESP(npc) end end)}
end
local function scanNPCESP()
    local di=workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Dialog"); if not di then return end
    for _,m in ipairs(di:GetChildren()) do if m:IsA("Model") then addNPCESP(m,m.Name) end end
end
local function stopNPCESP() _npcESPEnabled=false; local l={}; for npc in pairs(_npcESPActive) do l[#l+1]=npc end; for _,npc in ipairs(l) do removeNPCESP(npc) end end

-- NPC ESP UI
Tog.NPCESPEnabled = VizL3:Toggle({ Name="NPC ESP", Default=false,
    Callback=function(p)
        _npcESPEnabled=p
        if p then scanNPCESP(); task.spawn(function() while _npcESPEnabled do task.wait(3); scanNPCESP() end end) else stopNPCESP() end
    end }, "NPCESPEnabled")
Opt.NpcESPColor2 = VizL3:Colorpicker({ Name="NPC Color", Default=Color3.fromRGB(100,220,255), Alpha=0, Callback=function(c) npcESPColor2=c end }, "NpcESPColor2")
Tog.NpcESPRainbow2 = VizL3:Toggle({ Name="Rainbow",  Default=false, Callback=function(p) _npcESP2.rainbow=p  end }, "NpcESPRainbow2")
Tog.NpcESPShowName = VizL3:Toggle({ Name="Name",     Default=false, Callback=function(p) _npcESP2.showName=p end }, "NpcESPShowName")
Tog.NpcESPShowDist = VizL3:Toggle({ Name="Distance", Default=false, Callback=function(p) _npcESP2.showDist=p end }, "NpcESPShowDist")
Opt.NpcESPComponents = VizL3:Dropdown({ Name="Components", Multi=true, Default={}, Options={"Text","Highlight","Tracer","Box 2D","HP Bar","Head Dot"},
    Callback=function(v) _npcESP2.components=v end }, "NpcESPComponents")
onUnload(function() stopNPCESP() end)

-- ESP SETTINGS (short names so value boxes don't overlap)
VizR:Label({ Text="Range" })
Opt.ESPDist = VizR:Slider({ Name="Max Distance", Default=1000, Minimum=0, Maximum=10000, Precision=0, Callback=function(v) S.espDist=v end }, "ESPDist")
VizR:Divider()
VizR:Label({ Text="Text" })
Opt.ESPFontSize = VizR:Slider({ Name="Font Size", Default=14, Minimum=8, Maximum=32, Precision=0, Callback=function(v) S.espFontSize=v end }, "ESPFontSize")
VizR:Divider()
VizR:Label({ Text="Highlight" })
Opt.HLFillTrans = VizR:Slider({ Name="Fill Trans", Default=0.5, Minimum=0, Maximum=1, Precision=2, Callback=function(v) S.hlFillTrans=v end }, "HLFillTrans")
Opt.HLOutlineTrans = VizR:Slider({ Name="Outline Trans", Default=0, Minimum=0, Maximum=1, Precision=2, Callback=function(v) S.hlOutlineTrans=v end }, "HLOutlineTrans")
VizR:Divider()
VizR:Label({ Text="Tracer" })
Opt.TracerThick = VizR:Slider({ Name="Tracer Width", Default=1, Minimum=1, Maximum=5, Precision=1, Callback=function(v) S.tracerThick=v end }, "TracerThick")


-- ============================================================
-- WORLD TAB
-- ============================================================
local WorldL2 = Tabs.World:Section({Side="Left",  Name="Detection",   Image="sliders"})
local WorldL3 = Tabs.World:Section({Side="Left",  Name="Utilities",   Image="wrench"})
local WorldL4 = Tabs.World:Section({Side="Left",  Name="Server",      Image="server"})
local WorldR  = Tabs.World:Section({Side="Right", Name="Scene",       Image="scan-eye"})
local WorldR2 = Tabs.World:Section({Side="Right", Name="Camera",      Image="camera"})
local WorldR4 = Tabs.World:Section({Side="Right", Name="Performance", Image="zap"})

-- DETECTION (range/distance/height for attach)
Opt.MobsRange = WorldL2:Slider({ Name="Range", Default=1000, Minimum=0, Maximum=10000, Precision=0, Callback=function(v) S.mobsRange=v end }, "MobsRange")
Opt.MobsDistance = WorldL2:Slider({ Name="Distance", Default=0, Minimum=-50, Maximum=50, Precision=0, Callback=function(v) S.mobsDist=v end }, "MobsDistance")
Opt.MobsHeight = WorldL2:Slider({ Name="Height", Default=0, Minimum=-50, Maximum=50, Precision=0, Callback=function(v) S.mobsHeight=v end }, "MobsHeight")

-- UTILITIES
local nearbyConn=nil; local nearbyTracked={}
Tog.NearbyNotifier = WorldL3:Toggle({ Name="Nearby Players Notifier", Default=false,
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
                        if mag<=dist and not nearbyTracked[hrp] then nearbyTracked[hrp]=true; notify(string.format("%s is nearby [%d]",plr.Name,mag),10)
                        elseif mag>dist and nearbyTracked[hrp] then nearbyTracked[hrp]=nil; notify(string.format("%s left nearby [%d]",plr.Name,mag),10) end
                    end
                end
            end
        end)
    end }, "NearbyNotifier")
Opt.NearbyDist = WorldL3:Slider({ Name="Notifier Distance", Default=500, Minimum=0, Maximum=10000, Precision=0, Callback=function() end }, "NearbyDist")
WorldL3:Button({ Name="Copy Coordinates", Callback=function()
    local hrp=getHRP(); if not hrp then return end
    local p=hrp.Position; local str=math.round(p.X*100)/100 .. ", " .. math.round(p.Y*100)/100 .. ", " .. math.round(p.Z*100)/100
    setclipboard(str); notify("Copied: "..str)
end})

-- SERVER
WorldL4:Button({ Name="Serverhop", Callback=function()
    local ok,res=pcall(function() return HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")) end)
    if ok and res then for _,s in ipairs(res.data or {}) do if s.id~=game.JobId and s.playing<s.maxPlayers then TP:TeleportToPlaceInstance(game.PlaceId,s.id,LP); return end end end
    TP:Teleport(game.PlaceId,LP); notify("No servers found",3)
end})
Opt.MinPlayers = WorldL4:Input({ Name="Min Players", Default="", Placeholder="0", Callback=function() end }, "MinPlayers")
WorldL4:Button({ Name="Serverhop (Min Players)", Callback=function()
    local minP=tonumber(Opt.MinPlayers and Opt.MinPlayers.Value) or 0
    local ok,res=pcall(function() return HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")) end)
    if ok and res then for _,s in ipairs(res.data or {}) do if s.id~=game.JobId and s.playing>=minP and s.playing<s.maxPlayers then TP:TeleportToPlaceInstance(game.PlaceId,s.id,LP); return end end end
    notify("No servers with "..minP.."+ players",3)
end})
WorldL4:Button({ Name="Rejoin", Callback=function() TP:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end })
Opt.JobID = WorldL4:Input({ Name="JobID", Default="", Placeholder="Paste job id...", Callback=function() end }, "JobID")
WorldL4:Button({ Name="Join Server", Callback=function() local id=Opt.JobID and Opt.JobID.Value or ""; if id~="" then TP:TeleportToPlaceInstance(game.PlaceId,id,LP) end end })
WorldL4:Button({ Name="Copy Server JobId", Callback=function() setclipboard(game.JobId); notify(game.JobId.." Copied!",5) end })

-- SCENE (NoFog/NoAtmosphere/FullBright + Spectate)
local specTarget=nil; local specConn=nil
local specList={"-- Select --"}; for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(specList,plr.Name) end end
Opt.SpectatePlayers = WorldR:Dropdown({ Name="Spectate Player", Options=specList, Default=1, Multi=false,
    Callback=function(v) specTarget=type(v)=="table" and next(v) or v end }, "SpectatePlayers")
WorldR:Button({ Name="Spectate / Stop", Callback=function()
    if specConn then pcall(function() specConn:Disconnect() end); specConn=nil; local c=getChar(); Cam.CameraSubject=c and c:FindFirstChildOfClass("Humanoid") or c; Cam.CameraType=Enum.CameraType.Custom; notify("Stopped spectating",2); return end
    local name=specTarget; local plr=PS:FindFirstChild(name or ""); local char=plr and plr.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not hum then notify("Player not found",2); return end
    Cam.CameraSubject=hum; Cam.CameraType=Enum.CameraType.Custom
    specConn=plr.CharacterAdded:Connect(function(c) task.wait(0.5); local h=c:FindFirstChildOfClass("Humanoid"); if h then Cam.CameraSubject=h end end)
    notify("Spectating "..name,2)
end})
local noFogConn=nil
Tog.NoFog = WorldR:Toggle({ Name="No Fog", Default=false,
    Callback=function(p)
        if noFogConn then noFogConn:Disconnect(); noFogConn=nil end
        local atmos=LT:FindFirstChildOfClass("Atmosphere")
        if p then LT.FogStart=1e9; LT.FogEnd=1e9; if atmos then atmos.Density=0; atmos.Haze=0; atmos.Glare=0 end
            noFogConn=LT:GetPropertyChangedSignal("FogEnd"):Connect(function() if LT.FogEnd<1e8 then LT.FogStart=1e9; LT.FogEnd=1e9 end end)
        else LT.FogStart=0; LT.FogEnd=100000; if atmos then atmos.Density=0.395; atmos.Haze=0; atmos.Glare=0 end end
    end }, "NoFog")
Tog.NoAtmosphere = WorldR:Toggle({ Name="No Atmosphere", Default=false,
    Callback=function(p) pcall(function() local atmos=LT:FindFirstChildOfClass("Atmosphere"); if not atmos then return end; if p then atmos.Density=0; atmos.Offset=0; atmos.Haze=0; atmos.Glare=0 else atmos.Density=0.395; atmos.Offset=0; atmos.Haze=0; atmos.Glare=0 end end) end }, "NoAtmosphere")
local fbConn=nil
Tog.FullBright = WorldR:Toggle({ Name="FullBright", Default=false,
    Callback=function(p)
        if fbConn then fbConn:Disconnect(); fbConn=nil end
        if p then fbConn=RS.RenderStepped:Connect(function() LT.Brightness=S.brightness; LT.ClockTime=14; LT.FogEnd=100000; LT.GlobalShadows=false; LT.OutdoorAmbient=Color3.fromRGB(128,128,128) end)
        else LT.Brightness=1; LT.ClockTime=14; LT.FogEnd=1000000; LT.GlobalShadows=true end
    end }, "FullBright")
Opt.Brightness = WorldR:Slider({ Name="Brightness", Default=2, Minimum=0, Maximum=10, Precision=1, Callback=function(v) S.brightness=v end }, "Brightness")

-- CAMERA (Freecam + FOV)
local freecamConns={}
Tog.Freecam = WorldR2:Toggle({ Name="Free Cam", Default=false,
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
            if inp.KeyCode==Enum.KeyCode.W then keys["W"]=true elseif inp.KeyCode==Enum.KeyCode.A then keys["A"]=true
            elseif inp.KeyCode==Enum.KeyCode.S then keys["S"]=true elseif inp.KeyCode==Enum.KeyCode.D then keys["D"]=true
            elseif inp.UserInputType==Enum.UserInputType.MouseButton2 then rmb=true end
        end))
        table.insert(freecamConns, UIS.InputEnded:Connect(function(inp)
            if inp.KeyCode==Enum.KeyCode.W then keys["W"]=false elseif inp.KeyCode==Enum.KeyCode.A then keys["A"]=false
            elseif inp.KeyCode==Enum.KeyCode.S then keys["S"]=false elseif inp.KeyCode==Enum.KeyCode.D then keys["D"]=false
            elseif inp.UserInputType==Enum.UserInputType.MouseButton2 then rmb=false end
        end))
    end }, "Freecam")
Opt.FreeCamSens = WorldR2:Slider({ Name="Sensitivity", Default=0.3, Minimum=0, Maximum=5, Precision=1, Callback=function(v) S.freeCamSens=v end }, "FreeCamSens")
Opt.FreeCamSpeed = WorldR2:Slider({ Name="Speed", Default=0.5, Minimum=0, Maximum=50, Precision=1, Callback=function(v) S.freeCamSpeed=v end }, "FreeCamSpeed")
WorldR2:Divider()
Tog.FOVChanger = WorldR2:Toggle({ Name="FOV Changer", Default=false,
    Callback=function(p) if p then Cam.FieldOfView=S.fovVal else Cam.FieldOfView=70 end end }, "FOVChanger")
Opt.FOV = WorldR2:Slider({ Name="Camera FOV", Default=70, Minimum=0, Maximum=120, Precision=1,
    Callback=function(v) S.fovVal=v; if Tog.FOVChanger and Tog.FOVChanger.State then Cam.FieldOfView=v end end }, "FOV")

-- PERFORMANCE
WorldR4:Button({ Name="Boost FPS", Callback=function()
    pcall(function()
        for _,v in ipairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled=false end
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then v.Enabled=false end
        end
        LT.GlobalShadows=false; LT.Brightness=5; notify("FPS boost applied",3)
    end)
end})

-- ============================================================
-- NAVIGATION TAB
-- ============================================================
local NavL  = Tabs.Navigation:Section({Side="Left",  Name="NPCs",       Image="bot"})
local NavL2 = Tabs.Navigation:Section({Side="Left",  Name="Players",    Image="users"})
local NavL3 = Tabs.Navigation:Section({Side="Left",  Name="Attach",     Image="anchor"})
local NavR  = Tabs.Navigation:Section({Side="Right", Name="Areas",      Image="map-pin"})
local NavR2 = Tabs.Navigation:Section({Side="Right", Name="Saved",      Image="bookmark"})
local NavR3 = Tabs.Navigation:Section({Side="Right", Name="Contracts",  Image="scroll"})

-- NPC TP
do
    local _npcTPTarget=nil; local _npcTPMap={}
    local function refreshNPCList()
        local di=workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Dialog")
        if not di then return {"-- none --"} end
        local myHRP=getHRP(); _npcTPMap={}
        local entries={}
        for _,m in ipairs(di:GetChildren()) do
            local root=m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
            if root then
                local dist=myHRP and math.floor((root.Position-myHRP.Position).Magnitude) or 0
                local label=m.Name.." ["..dist.."m]"
                table.insert(entries,{label=label,dist=dist}); _npcTPMap[label]=m
            end
        end
        table.sort(entries,function(a,b) return a.dist<b.dist end)
        local names={}; for _,e in ipairs(entries) do table.insert(names,e.label) end
        if #names==0 then return {"-- none --"} end; return names
    end
    Opt.NavNPCSelect = NavL:Dropdown({ Name="NPC", Search=true, Options=refreshNPCList(), Default=1, Multi=false, Callback=function(v) _npcTPTarget=type(v)=="table" and next(v) or v end }, "NavNPCSelect")
    NavL:Button({ Name="Refresh", Callback=function() pcall(function() Opt.NavNPCSelect:ClearOptions(); Opt.NavNPCSelect:InsertOptions(refreshNPCList()) end) end})
    NavL:Button({ Name="Teleport", Callback=function()
        if not _npcTPTarget or _npcTPTarget=="-- none --" then return end
        local npc=_npcTPMap[_npcTPTarget]; if not npc or not npc.Parent then notify("NPC gone — refresh",2); return end
        local hrp=getHRP(); if not hrp then return end
        local root=npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
        if root then hrp.CFrame=root.CFrame*CFrame.new(0,0,4); hrp.AssemblyLinearVelocity=Vector3.zero end
    end})
end

-- PLAYER TP
do
    local _plrTPTarget=nil
    local function refreshPlrList()
        local names={}; local myHRP=getHRP()
        for _,p in ipairs(PS:GetPlayers()) do
            if p~=LP and p.Character then
                local root=p.Character:FindFirstChild("HumanoidRootPart")
                local dist=(myHRP and root) and math.floor((root.Position-myHRP.Position).Magnitude) or 0
                table.insert(names, p.Name.." ["..dist.."m]")
            end
        end
        table.sort(names); if #names==0 then return {"-- none --"} end; return names
    end
    Opt.NavPlrSelect = NavL2:Dropdown({ Name="Player", Search=true, Options=refreshPlrList(), Default=1, Multi=false, Callback=function(v) _plrTPTarget=type(v)=="table" and next(v) or v end }, "NavPlrSelect")
    NavL2:Button({ Name="Refresh", Callback=function() pcall(function() Opt.NavPlrSelect:ClearOptions(); Opt.NavPlrSelect:InsertOptions(refreshPlrList()) end) end})
    NavL2:Button({ Name="Teleport", Callback=function()
        if not _plrTPTarget or _plrTPTarget=="-- none --" then return end
        local name=_plrTPTarget:match("^(.-)%s*%[")
        local plr=PS:FindFirstChild(name or "")
        if plr and plr.Character then
            local hrp=getHRP(); local root=plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp and root then hrp.CFrame=root.CFrame*CFrame.new(0,0,5); hrp.AssemblyLinearVelocity=Vector3.zero end
        end
    end})
    PS.PlayerAdded:Connect(function() task.defer(function() pcall(function() Opt.NavPlrSelect:ClearOptions(); Opt.NavPlrSelect:InsertOptions(refreshPlrList()) end) end) end)
    PS.PlayerRemoving:Connect(function() task.defer(function() pcall(function() Opt.NavPlrSelect:ClearOptions(); Opt.NavPlrSelect:InsertOptions(refreshPlrList()) end) end) end)
end

-- AREA TP
do
    local areaPositions = {
        {"Commercial District", CFrame.new(-656,37,-98)},
        {"Residential Area", CFrame.new(-2141,10,-204)},
        {"Outskirts", CFrame.new(-1885,11,-722)},
        {"Outskirts (Far)", CFrame.new(127,66,-1573)},
        {"Construction", CFrame.new(-1547,8,893)},
        {"Garage", CFrame.new(223,15,-285)},
        {"Yakuza HQ", CFrame.new(-1134,6,-995)},
        {"HQ", CFrame.new(-624,6,-100)},
    }
    local areaNames={}; for _,a in ipairs(areaPositions) do table.insert(areaNames,a[1]) end
    local _selArea=areaNames[1]
    NavR:Dropdown({ Name="Area", Options=areaNames, Default=1, Multi=false, Callback=function(v) _selArea=type(v)=="table" and next(v) or v end })
    NavR:Button({ Name="Teleport to Area", Callback=function()
        local hrp=getHRP(); if not hrp then return end
        for _,a in ipairs(areaPositions) do
            if a[1]==_selArea then hrp.CFrame=a[2]*CFrame.new(0,3,0); hrp.AssemblyLinearVelocity=Vector3.zero; notify("TP'd to ".._selArea,2); break end
        end
    end})
end

-- SAVED POSITIONS
do
    local _savedPositions={}; local _selPos=nil
    NavR2:Button({ Name="Save Current Position", Callback=function()
        local hrp=getHRP(); if not hrp then return end
        local name="Pos "..#_savedPositions+1
        _savedPositions[name]=hrp.CFrame
        local names={}; for n in pairs(_savedPositions) do table.insert(names,n) end; table.sort(names)
        pcall(function() if Opt.NavPosSelect then Opt.NavPosSelect:ClearOptions(); Opt.NavPosSelect:InsertOptions(names) end end)
        notify("Saved: "..name,2)
    end})
    Opt.NavPosSelect = NavR2:Dropdown({ Name="Position", Options={"-- none --"}, Default=1, Multi=false, Callback=function(v) _selPos=type(v)=="table" and next(v) or v end })
    NavR2:Button({ Name="Teleport to Saved", Callback=function()
        if not _selPos or not _savedPositions[_selPos] then return end
        local hrp=getHRP(); if not hrp then return end
        hrp.CFrame=_savedPositions[_selPos]; hrp.AssemblyLinearVelocity=Vector3.zero
    end})
    NavR2:Button({ Name="Delete Selected", Callback=function()
        if not _selPos or not _savedPositions[_selPos] then return end
        _savedPositions[_selPos]=nil
        local names={}; for n in pairs(_savedPositions) do table.insert(names,n) end; table.sort(names)
        if #names==0 then names={"-- none --"} end
        pcall(function() Opt.NavPosSelect:ClearOptions(); Opt.NavPosSelect:InsertOptions(names) end)
        notify("Deleted: ".._selPos,2)
    end})
end

-- ATTACH
do
    local _attachOffY=0; local _attachOffZ=0; local _attachRange=1000
    Opt.NavAttachY = NavL3:Slider({ Name="Y Offset", Default=0, Minimum=-50, Maximum=50, Precision=1, Callback=function(v) _attachOffY=v end }, "NavAttachY")
    Opt.NavAttachZ = NavL3:Slider({ Name="Z Offset", Default=0, Minimum=-50, Maximum=50, Precision=1, Callback=function(v) _attachOffZ=v end }, "NavAttachZ")
    Opt.NavAttachR = NavL3:Slider({ Name="Range", Default=1000, Minimum=0, Maximum=10000, Precision=0, Callback=function(v) _attachRange=v end }, "NavAttachR")
    Tog.AttachNearby = NavL3:Toggle({ Name="Attach to Nearest", Default=false,
        Callback=function(p)
            if not p then return end
            task.spawn(function()
                while Tog.AttachNearby and Tog.AttachNearby.State do
                    local myHRP=getHRP(); if not myHRP then task.wait(); continue end
                    for _,plr in ipairs(PS:GetPlayers()) do
                        if plr~=LP and plr.Character then
                            local hrp=plr.Character:FindFirstChild("HumanoidRootPart"); local hum=plr.Character:FindFirstChildOfClass("Humanoid")
                            if hrp and hum and hum.Health>0 and (myHRP.Position-hrp.Position).Magnitude<=_attachRange then
                                tweenTo(hrp.CFrame*CFrame.new(0,_attachOffY,_attachOffZ))
                            end
                        end
                    end
                    task.wait()
                end
            end)
        end }, "AttachNearby")
end

-- CONTRACT TP
do
    local contractNPCs = {
        {"Yakuza Leader",               CFrame.new(-1134,6,-995)},
        {"Yakuza Assistant",            CFrame.new(-1132,6,-991)},
        {"Yakuza Contract Swapper",     CFrame.new(-1153,6,-984)},
        {"Yakuza Contract Terminator",  CFrame.new(-1153,6,-1004)},
        {"Yakuza Contract Debuff Spinner", CFrame.new(-1158,6,-984)},
        {"[Underground] Contract Swapper", CFrame.new(6429,-206,3776)},
        {"[Underground] Contract Terminator", CFrame.new(6415,-206,3758)},
        {"[Underground] Contract Debuff Spinner", CFrame.new(6484,-206,3775)},
        {"Vault Door 1",                CFrame.new(6506,-209,3777)},
        {"Vault Door 2",                CFrame.new(6438,-209,3777)},
        {"Vault Door 3",                CFrame.new(6370,-209,3777)},
    }
    local cNames={}; for _,c in ipairs(contractNPCs) do table.insert(cNames,c[1]) end
    local _selContract=cNames[1]
    NavR3:Dropdown({ Name="Contract NPC", Options=cNames, Default=1, Multi=false, Callback=function(v) _selContract=type(v)=="table" and next(v) or v end })
    NavR3:Button({ Name="Teleport", Callback=function()
        local hrp=getHRP(); if not hrp then return end
        for _,c in ipairs(contractNPCs) do
            if c[1]==_selContract then
                -- Try live NPC first
                local di=workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Dialog")
                local npc=di and di:FindFirstChild(_selContract)
                local root=npc and (npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart"))
                if root then hrp.CFrame=root.CFrame*CFrame.new(0,0,4)
                else hrp.CFrame=c[2]*CFrame.new(0,0,4) end
                hrp.AssemblyLinearVelocity=Vector3.zero
                notify("TP'd to ".._selContract,2); break
            end
        end
    end})
    NavR3:Button({ Name="TP to Yakuza HQ", Callback=function()
        local hrp=getHRP(); if not hrp then return end
        hrp.CFrame=CFrame.new(-1134,6,-995)*CFrame.new(0,0,4); hrp.AssemblyLinearVelocity=Vector3.zero
    end})
    NavR3:Button({ Name="TP to Temptation Door", Callback=function()
        local hrp=getHRP(); if not hrp then return end
        local dialog=workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Dialog")
        if not dialog then return end
        local tempt=dialog:FindFirstChild("TemptationModel")
        if tempt then
            local root=tempt:FindFirstChildWhichIsA("BasePart",true)
            if root then hrp.CFrame=CFrame.new(root.Position)*CFrame.new(0,0,4); hrp.AssemblyLinearVelocity=Vector3.zero; notify("TP'd to Temptation Door",2); return end
        end
        notify("No Temptation Door found",2)
    end})
end

-- TP ON DEATH (moved from Misc)
do
    local _deathPos=nil
    Tog.TPOnDeath = NavL3:Toggle({ Name="TP Back on Death", Default=false,
        Callback=function(p)
            if not p then return end
            local hrp=getHRP()
            if hrp then _deathPos=hrp.CFrame end
            LP.CharacterAdded:Connect(function(char)
                if not (Tog.TPOnDeath and Tog.TPOnDeath.State) or not _deathPos then return end
                local newHRP=char:WaitForChild("HumanoidRootPart",10)
                if newHRP then task.wait(1); newHRP.CFrame=_deathPos; newHRP.AssemblyLinearVelocity=Vector3.zero end
            end)
            local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Died:Connect(function() local h=getHRP(); if h then _deathPos=h.CFrame end end) end
        end }, "TPOnDeath")
end

-- ============================================================
-- STATS TAB
-- ============================================================
do
    local StatsL = Tabs.Stats:Section({Side="Left",  Name="Player Stats", Image="user"})
    local StatsR = Tabs.Stats:Section({Side="Right", Name="Attributes",   Image="list"})

    local USEFUL_ATTRS = {
        "Race","SubRace","Rank","ELO","Guild","Title","CurrentState","ZanpakutoState","Health","MaxHealth",
        "MissionExperience","RankExperience","Reiatsu","MaxReiatsu","Strength","Defense","Speed","Intelligence",
        "Hogyoku","HogyokuFragments","Prestige","KillStreak","Deaths","Kills","Wins","Losses",
        "Element","SubElement","ElementMastery","ElementLevel","RaidExperience","RaidLevel","RaidWins","RaidLosses",
        "RaidKills","RaidStreak","RaidRank","Division","Faction","VerifiedDevilHunter","CharacterName","InNoPvpZone","Loaded",
    }
    local _statsSelected=nil
    local _attrLabels={}
    local _statusLbl=StatsR:Label({ Text="" })
    local MAX_LABELS=40
    for i=1,MAX_LABELS do _attrLabels[i]=StatsR:Label({ Text="" }) end

    local function getEntityModel(name)
        local world=workspace:FindFirstChild("World"); local ents=world and world:FindFirstChild("Entities")
        if not ents then return nil end
        local ent=ents:FindFirstChild(name); if ent then return ent end
        for _,plr in ipairs(PS:GetPlayers()) do if plr.Name==name and plr.Character then local c=ents:FindFirstChild(plr.Character.Name); if c then return c end end end
        return nil
    end
    local function getLP_Entity()
        local world=workspace:FindFirstChild("World"); local ents=world and world:FindFirstChild("Entities")
        return ents and ents:FindFirstChild(LP.Name)
    end
    local function setLbl(lbl,txt) pcall(function() if lbl.SetText then lbl:SetText(txt) elseif lbl.UpdateText then lbl:UpdateText(txt) end end) end
    local function displayStats(name)
        for i=1,MAX_LABELS do setLbl(_attrLabels[i],"") end
        setLbl(_statusLbl,"")
        if not name then return end
        local attrs={}
        if name==LP.Name then
            for k,v in pairs(LP:GetAttributes()) do attrs[k]=v end
            local lpEnt=getLP_Entity(); if lpEnt then for k,v in pairs(lpEnt:GetAttributes()) do attrs[k]=v end end
        else
            local plr=PS:FindFirstChild(name); if plr then for k,v in pairs(plr:GetAttributes()) do attrs[k]=v end end
            local ent=getEntityModel(name); if ent then for k,v in pairs(ent:GetAttributes()) do attrs[k]=v end end
        end
        if not next(attrs) then setLbl(_statusLbl,"No attributes found"); return end
        local i=1
        for _,k in ipairs(USEFUL_ATTRS) do
            if i>MAX_LABELS then break end
            local v=attrs[k]
            if v~=nil and tostring(v)~="" then setLbl(_attrLabels[i],"<font color=\"rgb(180,130,240)\">"..k.."</font>  "..tostring(v)); i=i+1 end
        end
        local usefulSet={}; for _,k in ipairs(USEFUL_ATTRS) do usefulSet[k]=true end
        local extras={}; for k in pairs(attrs) do if not usefulSet[k] then table.insert(extras,k) end end
        table.sort(extras)
        for _,k in ipairs(extras) do
            if i>MAX_LABELS then break end
            local v=attrs[k]
            if v~=nil and tostring(v)~="" then setLbl(_attrLabels[i],"<font color=\"rgb(140,140,180)\">"..k.."</font>  "..tostring(v)); i=i+1 end
        end
        if i==1 then setLbl(_statusLbl,"No attributes found") end
    end
    local _attrConns={}
    local function rebindAttrWatcher(name)
        for _,c in ipairs(_attrConns) do pcall(function() c:Disconnect() end) end; _attrConns={}
        if not name then return end
        local function watchObj(obj) if not obj then return end; table.insert(_attrConns,obj.AttributeChanged:Connect(function() displayStats(name) end)) end
        if name==LP.Name then watchObj(LP); local lpEnt=getLP_Entity(); if lpEnt then watchObj(lpEnt) end
        else local plr=PS:FindFirstChild(name); if plr then watchObj(plr) end; local ent=getEntityModel(name); if ent then watchObj(ent) end end
    end
    local function getPlayerList()
        local list={"-- Select --",LP.Name}
        for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(list,plr.Name) end end
        return list
    end
    Opt.StatsTarget = StatsL:Dropdown({ Name="Select Player", Options=getPlayerList(), Default=1, Multi=false,
        Callback=function(v)
            local sel=type(v)=="table" and next(v) or v
            _statsSelected=(sel~="-- Select --" and sel~="") and sel or nil
            displayStats(_statsSelected); rebindAttrWatcher(_statsSelected)
        end }, "StatsTarget")
    StatsL:Button({ Name="Refresh Stats", Callback=function() if not _statsSelected then notify("Select a player first",2); return end; displayStats(_statsSelected); notify("Refreshed: ".._statsSelected,2) end })
    StatsL:Button({ Name="Refresh Players", Callback=function() if Opt.StatsTarget then pcall(function() Opt.StatsTarget:ClearOptions(); Opt.StatsTarget:InsertOptions(getPlayerList()) end) end; notify("Player list refreshed",2) end })
    PS.PlayerAdded:Connect(function() task.defer(function() if Opt.StatsTarget then pcall(function() Opt.StatsTarget:ClearOptions(); Opt.StatsTarget:InsertOptions(getPlayerList()) end) end end) end)
    PS.PlayerRemoving:Connect(function() task.defer(function() if Opt.StatsTarget then pcall(function() Opt.StatsTarget:ClearOptions(); Opt.StatsTarget:InsertOptions(getPlayerList()) end) end end) end)
end

-- ============================================================
-- MISC TAB
-- ============================================================
local MiscL = Tabs.Misc:Section({Side="Left",  Name="Enhancements", Image="shield-plus"})

-- ENHANCEMENTS
Tog.NoSlow = MiscL:Toggle({ Name="No Stun", Default=false,
    Callback=function(p)
        if p then
            RS:BindToRenderStep("ZHNoStun", Enum.RenderPriority.Input.Value, function()
                local c=getChar(); if not c then return end
                local hum=getHum(); if not hum then return end
                local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if hum.WalkSpeed<20 then hum.WalkSpeed=20 end
                if hum.PlatformStand then hum.PlatformStand=false end
                if hum.Sit then hum.Sit=false end
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true) end)
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true) end)
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false) end)
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,true) end)
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Running,true) end)
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,true) end)
                local state=hum:GetState()
                if state==Enum.HumanoidStateType.GettingUp or state==Enum.HumanoidStateType.FallingDown or state==Enum.HumanoidStateType.Ragdoll then
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
                end
                hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X, math.max(hrp.AssemblyLinearVelocity.Y,-50), hrp.AssemblyLinearVelocity.Z)
            end)
        else RS:UnbindFromRenderStep("ZHNoStun") end
    end }, "NoSlow")
onUnload(function() RS:UnbindFromRenderStep("ZHNoStun") end)

do
    local _mobBreakerConn=nil; local _downVec=Vector3.new(0,-1000,0)
    Tog.MobBreaker = MiscL:Toggle({ Name="Mob Breaker", Default=false,
        Callback=function(p)
            if _mobBreakerConn then _mobBreakerConn:Disconnect(); _mobBreakerConn=nil end
            if not p then return end
            _mobBreakerConn=RS.Heartbeat:Connect(function()
                if not UIS:IsKeyDown(Enum.KeyCode.X) then return end
                local hrp=getHRP(); if not hrp then return end
                hrp.Velocity=(hrp.CFrame.LookVector.Unit*20)+_downVec
            end)
        end }, "MobBreaker")
    onUnload(function() if _mobBreakerConn then _mobBreakerConn:Disconnect(); _mobBreakerConn=nil end end)
end

do
    local _feInvisHook=nil
    Tog.FEInvisibility = MiscL:Toggle({ Name="FE Invisibility", Default=false,
        Callback=function(p)
            if not raknet then notify("FE Invisibility requires raknet API",3); if Tog.FEInvisibility then Tog.FEInvisibility:SetState(false) end; return end
            if p then
                if _feInvisHook then return end
                _feInvisHook=function(packet)
                    if packet.PacketId==0x1B then local buf=packet.AsBuffer; buffer.writeu32(buf,1,0xFFFFFFFF); packet:SetData(buf) end
                end
                raknet.add_send_hook(_feInvisHook)
            else
                if _feInvisHook then pcall(function() raknet.remove_send_hook(_feInvisHook) end); _feInvisHook=nil end
            end
        end }, "FEInvisibility")
    onUnload(function() if _feInvisHook then pcall(function() raknet.remove_send_hook(_feInvisHook) end); _feInvisHook=nil end end)
end

-- NPC TELEPORT
-- ============================================================
-- SETTINGS TAB
-- ============================================================
local SettL = Tabs.Settings:Section({Side="Left",  Name="Interface", Image="layout-dashboard"})
local SettR = Tabs.Settings:Section({Side="Right", Name="Controls",  Image="keyboard"})

-- INTERFACE
SettL:Header({ Text="Interface" })
SettL:Button({ Name="Unload", Callback=function() Window:Unload() end })
SettL:Divider()
Tog.HideUI = SettL:Toggle({ Name="Hide UI", Default=false, Callback=function(p) Window:SetState(not p) end }, "HideUI")
SettL:Divider()
SettL:Slider({ Name="UI Transparency", Default=5, Minimum=0, Maximum=50, Precision=0,
    Callback=function(v) Window:SetTransparency(v/100) end })
SettL:Divider()

-- CONFIG (tween + fly mode used elsewhere)
Opt.TweenMode = SettL:Dropdown({ Name="Tween Mode", Options={"Normal","Safe"}, Default=1, Multi=false, Callback=function() end }, "TweenMode")
Opt.TweenSpeed = SettL:Slider({ Name="Tween Speed", Default=100, Minimum=0, Maximum=700, Precision=0, Callback=function(v) S.tweenSpeed=v end }, "TweenSpeed")
Opt.SafeModeHeight = SettL:Slider({ Name="Safe Height", Default=1000, Minimum=0, Maximum=100000, Precision=0, Callback=function() end }, "SafeModeHeight")
Opt.FlyMode = SettL:Dropdown({ Name="Fly Mode", Options={"MoveDirection","Camera LookVector"}, Default=1, Multi=false, Callback=function() end }, "FlyMode")
SettL:Divider()

-- CONFIG SYSTEM (save/load/autoload built-in section)
MacLib:SetFolder("ZeroHub/configs")
Tabs.Settings:InsertConfigSection("Left")

-- ANTI BAN
Tog.AntiBan = SettL:Toggle({ Name="Anti Ban", Default=true, Callback=function() end }, "AntiBan")

-- CONTROLS
SettR:Header({ Text="Controls" })
SettR:Keybind({ Name="Menu Toggle", Default=Enum.KeyCode.F5, onBinded=function(k) pcall(function() Window:SetKeybind(k) end) end }, "KbMenu")

-- THEME
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

-- Open the first tab by default so the UI isn't blank on load
Tabs.Game:Select()

-- AUTOLOAD CONFIG (loads saved autoload config a few seconds after load)
task.defer(function()
    task.wait(3)
    pcall(function() MacLib:LoadAutoLoadConfig() end)
end)

notify("Zero Hub loaded", 4)
