repeat task.wait() until game:IsLoaded()
task.wait(1)

if getgenv()._ZHUnload then pcall(getgenv()._ZHUnload); getgenv()._ZHUnload=nil end

local RS  = game:GetService("RunService")
local PS  = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LT  = game:GetService("Lighting")
local HS  = game:GetService("HttpService")
local TP  = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cam = workspace.CurrentCamera
local LP  = PS.LocalPlayer

local function getChar() return LP.Character end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local S = {
    speed=100, infJumpH=50, flySpeed=100, tweenSpeed=100,
    aimbotFOV=45, aimbotSens=1, aimbotX=0, aimbotY=0,
    aimbotMode="Toggle", aimbotActive=false, aimbotEnabled=false,
    aimbotMethod="Camera", targetPlayers=true, visibleOnly=false, teamCheck=false,
    brightness=2, freeCamSens=0.3, freeCamSpeed=0.5, fovVal=70,
    espDist=1000, espFontSize=14, tracerThick=2,
    espRainbow=false, hlFillTrans=0.5, hlOutlineTrans=0, espAntiLag=true,
}
_wFPS = 60

local _macSrc = game:HttpGet("https://raw.githubusercontent.com/troidnox/sorrynol/refs/heads/main/zeree")
local _macFn, _macErr = loadstring(_macSrc)
assert(_macFn, "[ZeroHub] MacLib syntax error: " .. tostring(_macErr))
local MacLib = _macFn()
assert(MacLib, "[ZeroHub] MacLib returned nil")

local Window = MacLib:Window({
    Title    = "<font color=\"rgb(178,120,255)\">Zero</font> <font color=\"rgb(138,79,255)\">Hub</font>",
    Subtitle = "Dokkodo",
    Size     = UDim2.fromOffset(980, 760),
    DragStyle = 1,
    ShowUserInfo = false,
    Keybind  = Enum.KeyCode.F5,
    AcrylicBlur = false,
})
MacLib:SetFolder("ZeroHub/dokkodo")

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
    task.defer(function() pcall(function() Window:Notify({Title="Zero Hub", Description=msg, Lifetime=dur or 3}) end) end)
end

local TabGroup = Window:TabGroup()
local Tabs = {}
Tabs.Game      = TabGroup:Tab({Name="Main",       Image="swords"})
Tabs.Character = TabGroup:Tab({Name="Character",  Image="person-standing"})
Tabs.Visuals   = TabGroup:Tab({Name="Visuals",    Image="scan-eye"})
Tabs.World     = TabGroup:Tab({Name="World",      Image="map"})
Tabs.Stats     = TabGroup:Tab({Name="Stats",      Image="activity"})
Tabs.Settings  = TabGroup:Tab({Name="Settings",   Image="sliders-horizontal"})

-- SECTIONS
local GameL   = Tabs.Game:Section({ Side="Left",  Name="Player Farm",  Image="users"     })
local GameL2  = Tabs.Game:Section({ Side="Left",  Name="Mob Farm",     Image="swords"    })
local GameL4  = Tabs.Game:Section({ Side="Left",  Name="Bring",        Image="magnet"    })
local GameL6  = Tabs.Game:Section({ Side="Left",  Name="Insta Kill",   Image="zap"       })
local GameR   = Tabs.Game:Section({ Side="Right", Name="Farm Config",  Image="settings"  })
local GameR3  = Tabs.Game:Section({ Side="Right", Name="Freeze / Breaker", Image="snowflake" })
local GameR4  = Tabs.Game:Section({ Side="Right", Name="Network",      Image="network"   })

local CharL   = Tabs.Character:Section({ Side="Left",  Name="Movement",      Image="move"      })
local CharL2  = Tabs.Character:Section({ Side="Left",  Name="Morphs",        Image="user"      })
local CharR   = Tabs.Character:Section({ Side="Right", Name="Utility",       Image="wrench"    })
local CharR2  = Tabs.Character:Section({ Side="Right", Name="Enhancements",  Image="sparkles"  })
local CharR3  = Tabs.Character:Section({ Side="Right", Name="Aimbot",        Image="crosshair" })

local VizL    = Tabs.Visuals:Section({ Side="Left",  Name="Player ESP",  Image="user"    })
local VizL2   = Tabs.Visuals:Section({ Side="Left",  Name="Mob ESP",     Image="skull"   })
local VizR    = Tabs.Visuals:Section({ Side="Right", Name="ESP Config",  Image="sliders" })

local WorldL2 = Tabs.World:Section({ Side="Left",  Name="Camera",     Image="camera"  })
local WorldR  = Tabs.World:Section({ Side="Right", Name="Visual FX",  Image="sparkle" })
local WorldR2 = Tabs.World:Section({ Side="Right", Name="FPS Boost",  Image="zap"     })
local WorldR3 = Tabs.World:Section({ Side="Right", Name="Tools",      Image="wrench"  })

local SettL   = Tabs.Settings:Section({ Side="Left",  Name="Interface", Image="layout-dashboard" })
local SettR   = Tabs.Settings:Section({ Side="Right", Name="Keybinds",  Image="keyboard"         })


getgenv()._ZHBoxes = getgenv()._ZHBoxes or {}


local _cancelTween = false; local _tweenVersion = 0
local function tweenTo(cf, cancelCheck)
    local hrp=getHRP(); if not hrp then return end
    hrp.AssemblyLinearVelocity=Vector3.zero
    local tweenMode=Opt.TweenMode and Opt.TweenMode.Value or "Normal"
    local target=cf.Position
    local vim=game:GetService("VirtualInputManager")
    pcall(function() vim:SendKeyEvent(true,Enum.KeyCode.W,false,game) end)
    local function releaseW() pcall(function() vim:SendKeyEvent(false,Enum.KeyCode.W,false,game) end) end
    local _toggleFlight=nil; pcall(function() _toggleFlight=ReplicatedStorage:FindFirstChild("Requests") and ReplicatedStorage.Requests:FindFirstChild("ToggleFlight") end)
    _tweenVersion=_tweenVersion+1; local myVersion=_tweenVersion
    local function doLerp(from, to)
        if (to-from).Magnitude<1 then return true end
        if _toggleFlight then pcall(function() _toggleFlight:FireServer(true) end) end
        local done=false; local success=false; local tweenFrame=CFrame.new(from)
        RS:BindToRenderStep("DKDTween",Enum.RenderPriority.Input.Value,function(dt)
            if _tweenVersion~=myVersion then RS:UnbindFromRenderStep("DKDTween"); done=true; return end
            if _cancelTween then _cancelTween=false; releaseW(); RS:UnbindFromRenderStep("DKDTween"); done=true; return end
            if cancelCheck and cancelCheck() then releaseW(); RS:UnbindFromRenderStep("DKDTween"); done=true; return end
            local c=getChar(); if not c then RS:UnbindFromRenderStep("DKDTween"); done=true; return end
            local h=c:FindFirstChild("HumanoidRootPart"); if not h then RS:UnbindFromRenderStep("DKDTween"); done=true; return end
            local mv=to-tweenFrame.Position
            if mv.Magnitude<=1 then h.AssemblyLinearVelocity=Vector3.zero; h.CFrame=CFrame.new(to,to+(to-from).Unit); success=true; RS:UnbindFromRenderStep("DKDTween"); done=true; return end
            tweenFrame=tweenFrame+mv.Unit*S.tweenSpeed*dt
            local hDir=Vector3.new(mv.X,0,mv.Z); if hDir.Magnitude>0 then tweenFrame=CFrame.new(tweenFrame.Position,tweenFrame.Position+hDir.Unit) end
            h.AssemblyLinearVelocity=Vector3.zero; h.CFrame=tweenFrame
        end)
        while not done do task.wait() end
        if _toggleFlight then pcall(function() _toggleFlight:FireServer(false) end) end
        return success
    end
    if tweenMode=="Normal" then
        local p0=hrp.Position; if doLerp(p0,target) then local h=getHRP(); if h then h.CFrame=cf end end
    elseif tweenMode=="Safe" then
        local height=Opt.SafeModeHeight and Opt.SafeModeHeight.Value or 1000
        local up1=Vector3.new(hrp.Position.X,target.Y+height,hrp.Position.Z); hrp.CFrame=CFrame.new(up1)
        local up2=Vector3.new(target.X,target.Y+height,target.Z)
        if doLerp(up1,up2) then local h=getHRP(); if h then h.CFrame=cf end end
    end
    releaseW()
end
local _chestTweenVersion=0
local function tweenToChest(cf,cancelCheck)
    local hrp=getHRP(); if not hrp then return end; hrp.AssemblyLinearVelocity=Vector3.zero
    _chestTweenVersion=_chestTweenVersion+1; local myVersion=_chestTweenVersion
    local target=cf.Position; local tweenFrame=CFrame.new(hrp.Position); local done=false
    RS:BindToRenderStep("DKDChestTween",Enum.RenderPriority.Input.Value-1,function(dt)
        if _chestTweenVersion~=myVersion or (cancelCheck and cancelCheck()) then RS:UnbindFromRenderStep("DKDChestTween"); done=true; return end
        local h=getHRP(); if not h then RS:UnbindFromRenderStep("DKDChestTween"); done=true; return end
        local mv=target-tweenFrame.Position
        if mv.Magnitude<=1 then h.CFrame=cf; RS:UnbindFromRenderStep("DKDChestTween"); done=true; return end
        tweenFrame=tweenFrame+mv.Unit*S.tweenSpeed*dt; h.AssemblyLinearVelocity=Vector3.zero; h.CFrame=CFrame.new(tweenFrame.Position)
    end)
    while not done do task.wait() end
end
local _mobTweenVersion=0
local function tweenToMob(cf,cancelCheck)
    local hrp=getHRP(); if not hrp then return end; hrp.AssemblyLinearVelocity=Vector3.zero
    _mobTweenVersion=_mobTweenVersion+1; local myVersion=_mobTweenVersion
    local target=cf.Position; local tweenFrame=CFrame.new(hrp.Position); local done=false
    RS:BindToRenderStep("DKDMobTween",Enum.RenderPriority.Input.Value-2,function(dt)
        if _mobTweenVersion~=myVersion or (cancelCheck and cancelCheck()) then RS:UnbindFromRenderStep("DKDMobTween"); done=true; return end
        local h=getHRP(); if not h then RS:UnbindFromRenderStep("DKDMobTween"); done=true; return end
        local mv=target-tweenFrame.Position
        if mv.Magnitude<=1 then h.CFrame=cf; RS:UnbindFromRenderStep("DKDMobTween"); done=true; return end
        tweenFrame=tweenFrame+mv.Unit*S.tweenSpeed*dt; h.AssemblyLinearVelocity=Vector3.zero; h.CFrame=CFrame.new(tweenFrame.Position)
    end)
    while not done do task.wait() end
end

local function _getStatus() local c=getChar(); if not c then return end; return c:FindFirstChild("Status") end
local function _injectStatus(name) local s=_getStatus(); if not s then return end; if not s:FindFirstChild(name) then local f=Instance.new("Folder"); f.Name=name; f.Parent=s end end
local function _removeStatus(name) local s=_getStatus(); if not s then return end; local v=s:FindFirstChild(name); if v then v:Destroy() end end
local function _getRemote(name) local ok,r=pcall(function() local req=ReplicatedStorage:FindFirstChild("Requests"); return req and req:FindFirstChild(name) end); return ok and r or nil end

local _PLACE_NAMES={
    ["6270290407"]="VV: ULTIMATUM",["14321102147"]="Fort Adams",["14218523102"]="Soul Society Outskirts",
    ["9854445386"]="Content Deleted",["15645525857"]="Arctic Cave",["14711269481"]="Arctic Plain (OLD)",
    ["15079707729"]="Arctic Plains",["11131834995"]="Hueco Mundo",["14219489601"]="Human World",
    ["9861495985"]="Inner World",["11127942816"]="Las Noches",["121345602945775"]="Matchmaking",
    ["16914874220"]="Menos Forest",["10627960269"]="OLD.",["18972283841"]="Snow Encampment",
    ["12337012844"]="Soul Society",["17083682617"]="The Dangai",["95787471190312"]="The Marsh",
    ["13229243486"]="Tournament",["102123868363969"]="Trade Realm",["132224751888154"]="UPDATE PLACE",
    ["10626511620"]="Valley of Screams",["18416507779"]="VV TEST ZONE",["11780443293"]="Wandenreich",
}
local function serverHop()
    local placeId=game.PlaceId
    local ok,res=pcall(function() return HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..tostring(placeId).."/servers/Public?sortOrder=Asc&limit=100")) end)
    if ok and res then for _,s in ipairs(res.data or {}) do if s.id~=game.JobId and s.playing<s.maxPlayers then launchTP(placeId,s.id); return end end end
    launchTP(placeId,game.JobId)
end

notify("VV Ultimatum loaded", 4)




-- ══════════════════════════════════════════════════════════════════════════════
-- GAME TAB
-- ══════════════════════════════════════════════════════════════════════════════
-- ══════════════════════════════════════════════════════════════════════════════
-- GAME TAB (Main) — adapted from Devil Hunters for workspace.Humanoids
-- ══════════════════════════════════════════════════════════════════════════════

local farmState = { plrs=false, plrTarget="", mobs=false, mobTarget="" }
local farmConns = {}
local _ownHighlights = {}
local _ownVizConn = nil
local _bringConn = nil
local _bringRange = 100
local _freezeRange = 100
local _farmMode="Behind"; local _farmOffX=0; local _farmOffY=0; local _farmOffZ=6.5

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
    local folder=workspace:FindFirstChild("Humanoids"); if not folder then return end
    for _,mob in ipairs(folder:GetChildren()) do
        if not mob:IsA("Model") then continue end
        if PS:GetPlayerFromCharacter(mob) then continue end
        if farmState.mobTarget~="" and mob.Name~=farmState.mobTarget then continue end
        local r=mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChildWhichIsA("BasePart")
        local h=mob:FindFirstChildOfClass("Humanoid")
        if not (r and h and h.Health>0) then continue end
        local d=(r.Position-hrp.Position).Magnitude
        if d<bestD then best=mob; bestD=d end
    end
    return best
end
local function makeFarmLoop(targetFn, activeKey)
    local lastTgt,pickTime=nil,0
    return RS.Heartbeat:Connect(function()
        if not farmState[activeKey] then return end
        local c=getChar(); if not c then lastTgt=nil; return end
        local hum=c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then lastTgt=nil; return end
        local hrp=getHRP(); if not hrp then return end
        local now=tick()
        if not lastTgt or not lastTgt.Parent or not lastTgt:FindFirstChildOfClass("Humanoid") or lastTgt:FindFirstChildOfClass("Humanoid").Health<=0 or now-pickTime>=0.5 then
            lastTgt=targetFn(); pickTime=now
        end
        if lastTgt then
            local rp=lastTgt:FindFirstChild("HumanoidRootPart") or lastTgt:FindFirstChildWhichIsA("BasePart")
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
Opt.PlrSelect = GameL:Dropdown({ Name="Target Player", Options=plrList, Default=1, Multi=false, Search=true,
    Callback=function(v) local sel=type(v)=="table" and next(v) or v; farmState.plrTarget=(sel=="Any (Closest)") and "" or tostring(sel) end }, "PlrSelect")
local function updatePlrList()
    local list={"Any (Closest)"}
    for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(list,plr.Name) end end
    if Opt.PlrSelect then pcall(function() Opt.PlrSelect:ClearOptions(); Opt.PlrSelect:InsertOptions(list) end) end
end
PS.PlayerAdded:Connect(function() task.defer(updatePlrList) end)
PS.PlayerRemoving:Connect(function() task.defer(updatePlrList) end)
Tog.AutoFarmPlrs = GameL:Toggle({ Name="Farm Players", Default=false,
    Callback=function(p)
        farmState.plrs=p
        if farmConns.plrs then farmConns.plrs:Disconnect(); farmConns.plrs=nil end
        if p then getgenv()._DKD_autoM1=true; getgenv()._DKD_autoEquip=true; farmConns.plrs=makeFarmLoop(nearestPlayer,"plrs")
        else getgenv()._DKD_autoM1=false; getgenv()._DKD_autoEquip=false end
    end }, "AutoFarmPlrs")

-- MOB FARM
GameL2:Label({ Text="Mob Farm" })
local function scanMobList()
    local list={"Any (Closest)"}; local seen={}
    local folder=workspace:FindFirstChild("Humanoids")
    if folder then
        for _,mob in ipairs(folder:GetChildren()) do
            if mob:IsA("Model") and not PS:GetPlayerFromCharacter(mob) and not seen[mob.Name] then
                seen[mob.Name]=true; table.insert(list,mob.Name)
            end
        end
    end
    table.sort(list,function(a,b) if a=="Any (Closest)" then return true end; if b=="Any (Closest)" then return false end; return a<b end)
    return list
end
Opt.MobSelect = GameL2:Dropdown({ Name="Target Mob", Options=scanMobList(), Default=1, Multi=false, Search=true,
    Callback=function(v) local sel=type(v)=="table" and next(v) or v; farmState.mobTarget=(sel=="Any (Closest)") and "" or tostring(sel) end }, "MobSelect")
task.spawn(function() while true do task.wait(5); if Opt.MobSelect then pcall(function() Opt.MobSelect:ClearOptions(); Opt.MobSelect:InsertOptions(scanMobList()) end) end end end)
Tog.AutoFarmMobs = GameL2:Toggle({ Name="Autofarm Mobs", Default=false,
    Callback=function(p)
        farmState.mobs=p
        if farmConns.mobs then farmConns.mobs:Disconnect(); farmConns.mobs=nil end
        if p then getgenv()._DKD_autoM1=true; getgenv()._DKD_autoEquip=true; farmConns.mobs=makeFarmLoop(nearestMob,"mobs")
        else getgenv()._DKD_autoM1=false; getgenv()._DKD_autoEquip=false end
    end }, "AutoFarmMobs")

-- FARM CONFIG
GameR:Label({ Text="Position" })
Opt.FarmMode = GameR:Dropdown({ Name="Position", Options={"Above","Below","In Front","Behind"}, Default=4, Multi=false,
    Callback=function(v) _farmMode=type(v)=="table" and next(v) or v end }, "FarmMode")
Opt.FarmOffsetX = GameR:Slider({ Name="X Offset", Default=0, Minimum=-50, Maximum=50, Precision=1, Callback=function(v) _farmOffX=v end }, "FarmOffsetX")
Opt.FarmOffsetY = GameR:Slider({ Name="Y Offset", Default=0, Minimum=-50, Maximum=50, Precision=1, Callback=function(v) _farmOffY=v end }, "FarmOffsetY")
Opt.FarmOffsetZ = GameR:Slider({ Name="Z Offset", Default=6.5, Minimum=0, Maximum=50, Precision=1, Callback=function(v) _farmOffZ=v end }, "FarmOffsetZ")
GameR:Divider()
GameR:Label({ Text="Combat" })
do
    local _abilitiesEvent = nil
    local _inputEvent = nil
    local _mouseEvent = nil
    pcall(function() _abilitiesEvent = game:GetService("ReplicatedStorage").Communication.Abilities end)
    pcall(function() _inputEvent = game:GetService("ReplicatedStorage").Communication.Input end)
    pcall(function() _mouseEvent = game:GetService("ReplicatedStorage").Communication.Mouse end)
    getgenv()._DKD_autoM1 = false
    getgenv()._DKD_autoCrit = false
    getgenv()._DKD_autoGuard = false

    local function getAttackDir()
        local c = getChar(); if not c then return "Front" end
        local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return "Front" end
        local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return "Front" end
        local md = hum.MoveDirection
        if md.Magnitude < 0.05 then return "Front" end
        local local_dir = hrp.CFrame:VectorToObjectSpace(md).Unit
        local x, z = math.round(local_dir.X), math.round(local_dir.Z)
        if math.abs(x) == 1 and math.abs(z) ~= 1 then
            return x < 0 and "Left" or "Right"
        end
        return "Front"
    end

    local function isAerial()
        local c = getChar(); if not c then return false end
        local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return false end
        local s = hum:GetState()
        return s == Enum.HumanoidStateType.Jumping or s == Enum.HumanoidStateType.Freefall
    end

    local function sendMouseUpdate()
        if not _mouseEvent then return end
        pcall(function()
            local cam = workspace.CurrentCamera
            if not cam then return end
            local hit = cam.CFrame + cam.CFrame.LookVector * 60
            _mouseEvent:FireServer("Update", { Hit = hit })
        end)
    end

    if not getgenv()._DKD_combatStarted then
        getgenv()._DKD_combatStarted = true
        -- Kill Aura: directional attack with mouse update + aerial support
        task.spawn(function() while true do task.wait(0.15)
            if getgenv()._DKD_autoM1 and _abilitiesEvent then
                pcall(function()
                    sendMouseUpdate()
                    if _inputEvent then _inputEvent:FireServer("MouseButton1", "Began") end
                    local dir = getAttackDir()
                    local aerial = isAerial()
                    _abilitiesEvent:FireServer("Attack", "Initiate", dir, true, nil, aerial)
                    task.defer(function()
                        if _inputEvent then pcall(function() _inputEvent:FireServer("MouseButton1", "Ended") end) end
                    end)
                end)
            end
        end end)
        -- Auto Critical: fires Heavy + Shove
        task.spawn(function() while true do task.wait(0.3)
            if getgenv()._DKD_autoCrit and _abilitiesEvent then
                pcall(function()
                    if _inputEvent then _inputEvent:FireServer("R", "Began") end
                    _abilitiesEvent:FireServer("Heavy")
                end)
            end
        end end)
        -- Auto Guard: directional guard
        task.spawn(function() while true do task.wait(0.1)
            if getgenv()._DKD_autoGuard and _abilitiesEvent then
                pcall(function()
                    local dir = getAttackDir()
                    _abilitiesEvent:FireServer("Guard", "Start", dir)
                end)
            end
        end end)
    end
    Tog.AutoM1 = GameR:Toggle({ Name="Kill Aura", Default=false, Callback=function(p) getgenv()._DKD_autoM1=p end }, "AutoM1")
    Tog.AutoCrit = GameR:Toggle({ Name="Auto Critical", Default=false, Callback=function(p) getgenv()._DKD_autoCrit=p end }, "AutoCrit")
    Tog.AutoGuard = GameR:Toggle({ Name="Auto Guard", Default=false, Callback=function(p)
        getgenv()._DKD_autoGuard=p
        if not p and _abilitiesEvent then pcall(function() _abilitiesEvent:FireServer("Guard", "Stop") end) end
    end }, "AutoGuard")

    -- Auto Equip (fires Communication.Tools)
    getgenv()._DKD_autoEquip = false
    local _toolsEvent = nil
    pcall(function() _toolsEvent = game:GetService("ReplicatedStorage").Communication.Tools end)
    local function _scanBackpack()
        local list = {"None"}
        local bp = LP:FindFirstChild("Backpack")
        if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then table.insert(list, t.Name) end end end
        local char = getChar()
        if char then for _,t in ipairs(char:GetChildren()) do if t:IsA("Tool") then table.insert(list, t.Name) end end end
        local seen = {}; local unique = {}
        for _,n in ipairs(list) do if not seen[n] then seen[n]=true; table.insert(unique,n) end end
        return unique
    end
    local _equipTarget = "None"
    Opt.EquipSelect = GameR:Dropdown({ Name="Weapon", Options=_scanBackpack(), Default=1, Multi=false, Search=true,
        Callback=function(v) _equipTarget = type(v)=="table" and next(v) or v end }, "EquipSelect")
    task.spawn(function() while true do task.wait(3); if Opt.EquipSelect then pcall(function() Opt.EquipSelect:ClearOptions(); Opt.EquipSelect:InsertOptions(_scanBackpack()) end) end end end)
    Tog.AutoEquip = GameR:Toggle({ Name="Auto Equip", Default=false, Callback=function(p)
        getgenv()._DKD_autoEquip = p
        if not getgenv()._DKD_equipStarted then
            getgenv()._DKD_equipStarted = true
            task.spawn(function()
                while true do
                    task.wait(0.3)
                    if getgenv()._DKD_autoEquip and _toolsEvent and _equipTarget ~= "None" then
                        pcall(function() _toolsEvent:FireServer("Weapon", "Equip", _equipTarget) end)
                    end
                end
            end)
        end
    end }, "AutoEquip")
    onUnload(function() getgenv()._DKD_autoM1=false; getgenv()._DKD_autoCrit=false; getgenv()._DKD_autoEquip=false end)
end

-- BRING MOBS
local function stopBringMobs() if _bringConn then _bringConn:Disconnect(); _bringConn=nil end end
local function startBringMobs()
    stopBringMobs()
    _bringConn=RS.Heartbeat:Connect(function()
        local hrp=getHRP(); if not hrp then return end
        pcall(function() sethiddenproperty(LP,"MaxSimulationRadius",math.huge); sethiddenproperty(LP,"SimulationRadius",math.huge) end)
        local folder=workspace:FindFirstChild("Humanoids"); if not folder then return end
        for _,mob in ipairs(folder:GetChildren()) do
            if not mob:IsA("Model") then continue end
            if PS:GetPlayerFromCharacter(mob) then continue end
            local pp=mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart"); if not pp then continue end
            if not mob:FindFirstChildOfClass("Humanoid") then continue end
            if (pp.Position-hrp.Position).Magnitude>_bringRange then continue end
            pcall(function() mob:PivotTo(CFrame.new(hrp.Position+Vector3.new(0,0,-5))) end)
        end
    end)
end
GameL4:Label({ Text="Bring" })
Tog.BringMobEnabled = GameL4:Toggle({ Name="Bring Mobs", Default=false,
    Callback=function(p) if p then startBringMobs() else stopBringMobs() end end }, "BringMobEnabled")
Opt.BringRange = GameL4:Slider({ Name="Range", Default=100, Minimum=10, Maximum=10000, Precision=0,
    Callback=function(v) _bringRange=v end }, "BringRange")
onUnload(function() stopBringMobs() end)

-- FREEZE MOB
local _frozenParts={}
local _freezeConn2=nil
local function freezeRoot(v)
    if not v:IsA("BasePart") then return end
    local myChar=getChar(); if myChar and v:IsDescendantOf(myChar) then return end
    local folder=workspace:FindFirstChild("Humanoids")
    if not folder or not v:IsDescendantOf(folder) then return end
    if PS:GetPlayerFromCharacter(v.Parent) then return end
    if not v.Parent:FindFirstChildOfClass("Humanoid") then return end
    if v:FindFirstChild("xDKDFreeze") then return end
    local myHRP=getHRP()
    if myHRP and (v.Position-myHRP.Position).Magnitude>_freezeRange then return end
    local frozenCF=v.CFrame
    local tag=Instance.new("StringValue"); tag.Parent=v
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
    local folder=workspace:FindFirstChild("Humanoids")
    if folder then for _,model in ipairs(folder:GetChildren()) do if PS:GetPlayerFromCharacter(model) then continue end; local hrp=model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart"); if hrp then freezeRoot(hrp) end end end
    _freezeConn2=workspace.DescendantAdded:Connect(function(v)
        if v:IsA("BasePart") then local folder2=workspace:FindFirstChild("Humanoids"); if folder2 and v:IsDescendantOf(folder2) then freezeRoot(v) end end
    end)
end
GameR3:Label({ Text="Freeze" })
Tog.FreezeMobEnabled = GameR3:Toggle({ Name="Freeze Mobs", Default=false,
    Callback=function(p) if p then startFreezeMob() else stopFreezeMob() end end }, "FreezeMobEnabled")
Opt.FreezeRange = GameR3:Slider({ Name="Range", Default=100, Minimum=10, Maximum=10000, Precision=0,
    Callback=function(v) _freezeRange=v; if Tog.FreezeMobEnabled and Tog.FreezeMobEnabled.State then startFreezeMob() end end }, "FreezeRange")
onUnload(function() stopFreezeMob() end)

-- NETWORK OWNERSHIP VIEWER
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
    local folder=workspace:FindFirstChild("Humanoids"); if not folder then return end
    for _,model in ipairs(folder:GetChildren()) do
        if not model:IsA("Model") then continue end
        local hrp2=model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart"); if not hrp2 then continue end
        if not _ownHighlights[hrp2] then local hl2=Instance.new("Highlight",model); hl2.FillTransparency=0.7; _ownHighlights[hrp2]=hl2 end
        local hl2=_ownHighlights[hrp2]
        local owned=pcall(hasNetworkOwnership,hrp2) and hasNetworkOwnership(hrp2)
        hl2.FillColor=owned and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0)
        hl2.OutlineColor=hl2.FillColor
    end
end
GameR4:Label({ Text="Network" })
Tog.ShowOwnership = GameR4:Toggle({ Name="Show Ownership", Default=false,
    Callback=function(p)
        if p then
            if not _ownVizConn then _ownVizConn=RS.Heartbeat:Connect(function() if Tog.ShowOwnership and Tog.ShowOwnership.State then updateOwnershipViz() end end) end
        else
            if _ownVizConn then _ownVizConn:Disconnect(); _ownVizConn=nil end
            for _,hl2 in pairs(_ownHighlights) do pcall(function() hl2:Destroy() end) end; _ownHighlights={}
        end
    end }, "ShowOwnership")
GameR4:Label({ Text="Green = owned  |  Red = not" })
onUnload(function() if _ownVizConn then _ownVizConn:Disconnect() end; for _,hl2 in pairs(_ownHighlights) do pcall(function() hl2:Destroy() end) end end)
onUnload(function() if farmConns.plrs then farmConns.plrs:Disconnect() end; if farmConns.mobs then farmConns.mobs:Disconnect() end end)



GameR3:Divider()
GameR3:Label({ Text="Mob Breaker" })
-- AI MOB BREAKER
do
    local _mbThread = nil
    local _mbEvent = nil
    pcall(function() _mbEvent = game:GetService("ReplicatedStorage").Communication.Abilities end)
    Tog.MobBreaker = GameR3:Toggle({ Name="AI Mob Breaker", Default=false,
        Callback=function(p)
            if _mbThread then pcall(task.cancel, _mbThread); _mbThread = nil end
            if not p then return end
            if not _mbEvent then notify("Communication.Abilities not found", 3); Tog.MobBreaker:UpdateState(false); return end
            _mbThread = task.spawn(function()
                while Tog.MobBreaker and Tog.MobBreaker.State do
                    pcall(function() _mbEvent:FireServer("Dash", "Initiate", "Front", false) end)
                    task.wait()
                end
            end)
        end }, "MobBreaker")
    onUnload(function() if _mbThread then pcall(task.cancel, _mbThread); _mbThread = nil end end)
end

-- INSTA KILL
do
    local _ikConn = nil
    local _ikRange = 100
    local _ikThreshold = 0
    local function startIK()
        if _ikConn then _ikConn:Disconnect() end
        _ikConn = RS.Heartbeat:Connect(function()
            local hrp = getHRP(); if not hrp then return end
            pcall(function() sethiddenproperty(LP,"MaxSimulationRadius",math.huge); sethiddenproperty(LP,"SimulationRadius",math.huge) end)
            local folder = workspace:FindFirstChild("Humanoids"); if not folder then return end
            local destroyY = workspace.FallenPartsDestroyHeight
            for _, mob in ipairs(folder:GetChildren()) do
                if not mob:IsA("Model") then continue end
                if PS:GetPlayerFromCharacter(mob) then continue end
                local pp = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
                if not pp then continue end
                local hum = mob:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then continue end
                if pp.Position.Y <= destroyY then continue end
                if _ikThreshold > 0 and hum.Health > _ikThreshold then continue end
                if (pp.Position - hrp.Position).Magnitude > _ikRange then continue end
                pcall(function() hum.Health = 0; mob:PivotTo(CFrame.new(pp.Position.X, destroyY - 100, pp.Position.Z)) end)
            end
        end)
    end
    local function stopIK() if _ikConn then _ikConn:Disconnect(); _ikConn = nil end end
    Tog.InstaKill = GameL6:Toggle({ Name="Insta Kill", Default=false,
        Callback=function(p) if p then startIK() else stopIK() end end }, "InstaKill")
    Opt.IKThreshold = GameL6:Slider({ Name="HP Threshold", Default=0, Minimum=0, Maximum=1000000, Precision=0,
        Callback=function(v) _ikThreshold = v end }, "IKThreshold")
    Opt.IKRange = GameL6:Slider({ Name="Range", Default=100, Minimum=10, Maximum=10000, Precision=0,
        Callback=function(v) _ikRange = v end }, "IKRange")
    onUnload(function() stopIK() end)
end



-- ══════════════════════════════════════════════════════════════════════════════
-- VISUALS TAB (ESP)
-- ══════════════════════════════════════════════════════════════════════════════
local espEnabled=false; local espColor=Color3.fromRGB(255,255,255)
local espActive={}; local espConns={}
local _plrESP={components={["Box 2D"]=true,["Text"]=true,["HP Bar"]=true},showName=true,showHP=true,showDist=true}

local function removeESP(char)
    local d=espActive[char]; if not d then return end
    pcall(function() if d.txt    then d.txt:Remove()    end end)
    pcall(function() if d.box    then d.box:Remove()    end end)
    pcall(function() if d.hpFill then d.hpFill:Remove() end end)
    pcall(function() if d.hpBack then d.hpBack:Remove() end end)
    pcall(function() if d.tracer then d.tracer:Remove() end end)
    pcall(function() if d.dot    then d.dot:Remove()    end end)
    pcall(function() if d.hl     then d.hl:Destroy()    end end)
    if d.rname   then pcall(function() RS:UnbindFromRenderStep(d.rname) end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    if d.dieConn then pcall(function() d.dieConn:Disconnect() end) end
    espActive[char]=nil
end
local function addESP(char,plr)
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
        if dist>(S.espDist or 1000) then
            txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return
        end
        if S.espAntiLag and _wFPS<30 then
            txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return
        end
        local col=espColor or Color3.new(1,1,1)
        local comps=_plrESP.components or {}
        local sv,onS=Cam:WorldToViewportPoint(hrp.Position); local hv,onH=Cam:WorldToViewportPoint(head.Position)
        if not onS then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local scale=math.clamp(1/(sv.Z*0.04),0.5,3)
        local bw=35*scale; local bh=70*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
        local hpPct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
        local hpCol=Color3.fromHSV(hpPct*0.33,1,1)
        if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
        if comps["HP Bar"] then
            local barW=6; local barX=bx-barW-3
            hpBack.Position=Vector2.new(barX-1,by-1); hpBack.Size=Vector2.new(barW+2,bh+2); hpBack.Visible=true
            hpFill.Position=Vector2.new(barX,by+bh*(1-hpPct)); hpFill.Size=Vector2.new(barW,bh*hpPct); hpFill.Color=hpCol; hpFill.Visible=true
        else hpFill.Visible=false; hpBack.Visible=false end
        if comps["Text"] then
            local parts={}; local name=(plr and plr.DisplayName) or char.Name
            if _plrESP.showName then table.insert(parts,name) end
            if _plrESP.showHP   then table.insert(parts,string.format("[%d/%d]",hum.Health,hum.MaxHealth)) end
            if _plrESP.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end
            txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14
            txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0
        else txt.Visible=false end
        if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
        if comps["Head Dot"] and onH then dot.Position=Vector2.new(hv.X,hv.Y); dot.Color=col; dot.Visible=true else dot.Visible=false end
        hl.Enabled=comps["Highlight"] and espEnabled; hl.FillColor=col; hl.OutlineColor=col
        hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
    end)
    espActive[char]={txt=txt,box=box,hpFill=hpFill,hpBack=hpBack,tracer=tracer,dot=dot,hl=hl,rname=rname,
        ancConn=char.AncestryChanged:Connect(function(_,p) if not p then removeESP(char) end end),
        dieConn=hum.Died:Connect(function() task.wait(3); removeESP(char) end)}
end

local _hue=0
local mobESPColor2=Color3.fromRGB(255,100,100); local npcESPColor2=Color3.fromRGB(100,220,255)
local _mobESP2={components={["Box 2D"]=true,["Text"]=true,["HP Bar"]=true},showName=true,showHP=true,showDist=true,rainbow=false}
local _npcESP2={components={["Box 2D"]=true,["Text"]=true},showName=true,showDist=true,rainbow=false}
RS.Heartbeat:Connect(function(dt)
    _hue=(_hue+dt*0.25)%1; local rc=Color3.fromHSV(_hue,1,1)
    if S.espRainbow     then espColor=rc      end
    if _mobESP2.rainbow then mobESPColor2=rc  end
    if _npcESP2.rainbow then npcESPColor2=rc  end
end)


Tog.PlayerESPEnabled = VizL:Toggle({
    Name="Player ESP", Default=false,
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
    end
}, "PlayerESPEnabled")
Opt.ESPColor = VizL:Colorpicker({ Name="ESP Color", Default=Color3.fromRGB(255,255,255), Alpha=0, Callback=function(col) espColor=col end }, "ESPColor")
Tog.ESPRainbow  = VizL:Toggle({ Name="Rainbow",  Default=false, Callback=function(p) S.espRainbow=p  end }, "ESPRainbow")
Tog.ESPShowName = VizL:Toggle({ Name="Name",     Default=true,  Callback=function(p) _plrESP.showName=p end }, "ESPShowName")
Tog.ESPShowHP   = VizL:Toggle({ Name="Health",   Default=true,  Callback=function(p) _plrESP.showHP=p   end }, "ESPShowHP")
Tog.ESPShowDist = VizL:Toggle({ Name="Distance", Default=true,  Callback=function(p) _plrESP.showDist=p end }, "ESPShowDist")
Opt.PlrESPComponents = VizL:Dropdown({
    Name="Components", Multi=true, Default={"Text","Box 2D","HP Bar"}, Options={"Text","Highlight","Tracer","Box 2D","HP Bar","Head Dot"},
    Callback=function(v) _plrESP.components=v end
}, "PlrESPComponents")
VizL:Divider()


VizR:Label({ Text="Range" })
Opt.ESPDist     = VizR:Slider({ Name="Max Distance",  Default=1000, Minimum=0, Maximum=10000, Precision=0, Callback=function(v) S.espDist=v     end }, "ESPDist")
Opt.ESPFontSize = VizR:Slider({ Name="Font Size",      Default=14,   Minimum=8, Maximum=32,   Precision=0, Callback=function(v) S.espFontSize=v end }, "ESPFontSize")
VizR:Divider()
VizR:Label({ Text="Highlight" })
Opt.HLFillTrans    = VizR:Slider({ Name="Fill Trans",    Default=0.5, Minimum=0, Maximum=1, Precision=2, Callback=function(v) S.hlFillTrans=v    end }, "HLFillTrans")
Opt.HLOutlineTrans = VizR:Slider({ Name="Outline Trans", Default=0,   Minimum=0, Maximum=1, Precision=2, Callback=function(v) S.hlOutlineTrans=v end }, "HLOutlineTrans")
VizR:Divider()
VizR:Label({ Text="Tracer" })
Opt.TracerThick = VizR:Slider({ Name="Tracer Width", Default=1, Minimum=1, Maximum=5, Precision=1, Callback=function(v) S.tracerThick=v end }, "TracerThick")
VizR:Divider()
VizR:Label({ Text="Anti-Lag" })
Tog.ESPThrottle = VizR:Toggle({ Name="FPS Guard", Default=true, Callback=function(p) S.espAntiLag=p end }, "ESP_Throttle")
VizR:Label({ Text="Disables ESP when FPS < 30" })


local _mobESPActive={}; local _mobESPEnabled=false
local function removeMobESP(mob)
    local d=_mobESPActive[mob]; if not d then return end
    pcall(function() if d.txt    then d.txt:Remove()    end end)
    pcall(function() if d.box    then d.box:Remove()    end end)
    pcall(function() if d.hpFill then d.hpFill:Remove() end end)
    pcall(function() if d.hpBack then d.hpBack:Remove() end end)
    pcall(function() if d.tracer then d.tracer:Remove() end end)
    pcall(function() if d.dot    then d.dot:Remove()    end end)
    pcall(function() if d.hl     then d.hl:Destroy()    end end)
    if d.conn    then pcall(function() d.conn:Disconnect()    end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    _mobESPActive[mob]=nil
end
local function getMobType2(mob)
    local ht=mob:GetAttribute("HollowType"); if ht and ht~="" then return tostring(ht) end
    return mob.Name:match("^(.-)_[^_]+$") or mob.Name
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
    local conn=RS.Heartbeat:Connect(function()
        if not (_mobESPEnabled and mob and mob.Parent) then removeMobESP(mob); return end
        local myHRP=getHRP(); if not myHRP then return end
        local col=mobESPColor2; local dist=(hrp.Position-myHRP.Position).Magnitude
        local comps=_mobESP2.components or {}
        if dist>(S.espDist or 1000) then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local sv,onS=Cam:WorldToViewportPoint(hrp.Position); local hv,onH=head and Cam:WorldToViewportPoint(head.Position)
        if not onS then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local scale=math.clamp(1/(sv.Z*0.04),0.5,3); local bw=35*scale; local bh=70*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
        local hpPct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1); local hpCol=Color3.fromHSV(hpPct*0.33,1,1)
        if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
        if comps["HP Bar"] then local barW=6; local barX=bx-barW-3; hpBack.Position=Vector2.new(barX-1,by-1); hpBack.Size=Vector2.new(barW+2,bh+2); hpBack.Visible=true; hpFill.Position=Vector2.new(barX,by+bh*(1-hpPct)); hpFill.Size=Vector2.new(barW,bh*hpPct); hpFill.Color=hpCol; hpFill.Visible=true else hpFill.Visible=false; hpBack.Visible=false end
        if comps["Text"] then local parts={}; if _mobESP2.showName then table.insert(parts,getMobType2(mob)) end; if _mobESP2.showHP then table.insert(parts,string.format("[%d/%d]",hum.Health,hum.MaxHealth)) end; if _mobESP2.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end; txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14; txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0 else txt.Visible=false end
        if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
        if comps["Head Dot"] and onH and head then dot.Position=Vector2.new(hv.X,hv.Y); dot.Color=col; dot.Visible=true else dot.Visible=false end
        hl.Enabled=comps["Highlight"] and _mobESPEnabled or false; hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
    end)
    _mobESPActive[mob]={txt=txt,box=box,hpFill=hpFill,hpBack=hpBack,tracer=tracer,dot=dot,hl=hl,conn=conn,
        ancConn=mob.AncestryChanged:Connect(function(_,p) if not p then removeMobESP(mob) end end)}
end
local function scanMobESP2() local living=workspace:FindFirstChild("Humanoids"); if not living then return end; for _,m in ipairs(living:GetChildren()) do if m:IsA("Model") and not PS:GetPlayerFromCharacter(m) then addMobESP(m) end end end
local function stopMobESP() _mobESPEnabled=false; for mob in pairs(_mobESPActive) do removeMobESP(mob) end end

Tog.MobESPEnabled = VizL2:Toggle({
    Name="Mob ESP", Default=false,
    Callback=function(p)
        _mobESPEnabled=p
        if p then scanMobESP2(); task.spawn(function() while _mobESPEnabled do task.wait(3); scanMobESP2() end end)
        else stopMobESP() end
    end
}, "MobESPEnabled")
Opt.MobESPColor2 = VizL2:Colorpicker({ Name="Mob Color", Default=Color3.fromRGB(255,100,100), Alpha=0, Callback=function(c) mobESPColor2=c end }, "MobESPColor2")
Tog.MobESPRainbow2 = VizL2:Toggle({ Name="Rainbow",  Default=false, Callback=function(p) _mobESP2.rainbow=p  end }, "MobESPRainbow2")
Tog.MobESPShowName = VizL2:Toggle({ Name="Name",     Default=true,  Callback=function(p) _mobESP2.showName=p end }, "MobESPShowName")
Tog.MobESPShowHP   = VizL2:Toggle({ Name="Health",   Default=true,  Callback=function(p) _mobESP2.showHP=p   end }, "MobESPShowHP")
Tog.MobESPShowDist = VizL2:Toggle({ Name="Distance", Default=true,  Callback=function(p) _mobESP2.showDist=p end }, "MobESPShowDist")
Opt.MobESPComponents = VizL2:Dropdown({ Name="Components", Multi=true, Default={"Text","Box 2D","HP Bar"}, Options={"Text","Highlight","Tracer","Box 2D","HP Bar","Head Dot"}, Callback=function(v) _mobESP2.components=v end }, "MobESPComponents")
onUnload(function() stopMobESP() end)
VizL2:Divider()


local _npcESPActive={}; local _npcESPEnabled=false
local function removeNPCESP(npc)
    local d=_npcESPActive[npc]; if not d then return end
    for _,k in ipairs({"txt","box","hpFill","hpBack","tracer","dot"}) do if d[k] then pcall(function() d[k]:Remove() end) end end
    if d.hl then pcall(function() d.hl:Destroy() end) end
    if d.conn    then pcall(function() d.conn:Disconnect()    end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    _npcESPActive[npc]=nil
end


-- ══════════════════════════════════════════════════════════════════════════════
-- CHARACTER TAB
-- ══════════════════════════════════════════════════════════════════════════════
Tog.Fly = CharL:Toggle({
    Name="Fly", Default=false, Keybind=Enum.KeyCode.Y,
    Callback=function(p)
        if p then
            RS:BindToRenderStep("DKDFly",Enum.RenderPriority.Input.Value,function(dt)
                local c=getChar(); if not c then return end
                local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if not getgenv()._DKD_flyFrame then getgenv()._DKD_flyFrame=hrp.CFrame end
                local frame=getgenv()._DKD_flyFrame; local cf=Cam.CFrame; local mv=Vector3.zero
                local fmode=Opt.FlyMode and Opt.FlyMode.Value or "MoveDirection"
                if fmode=="MoveDirection" then
                    local fwd=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit; local rgt=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
                    if UIS:IsKeyDown(Enum.KeyCode.W) then mv=mv+fwd end; if UIS:IsKeyDown(Enum.KeyCode.S) then mv=mv-fwd end
                    if UIS:IsKeyDown(Enum.KeyCode.A) then mv=mv-rgt end; if UIS:IsKeyDown(Enum.KeyCode.D) then mv=mv+rgt end
                else
                    local hum=c:FindFirstChildOfClass("Humanoid")
                    if hum and hum.MoveDirection.Magnitude>0 then
                        local fwd2=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit; local rgt2=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
                        mv=mv+fwd2*hum.MoveDirection:Dot(fwd2)+rgt2*hum.MoveDirection:Dot(rgt2)
                    end
                end
                if UIS:IsKeyDown(Enum.KeyCode.Space)       then mv=mv+Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv=mv-Vector3.new(0,1,0) end
                if mv.Magnitude>0 then frame=frame+mv.Unit*S.flySpeed*dt end
                local fwd3=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
                if fwd3.Magnitude>0 then frame=CFrame.new(frame.Position,frame.Position+fwd3.Unit) end
                getgenv()._DKD_flyFrame=frame; hrp.AssemblyLinearVelocity=Vector3.zero; hrp.CFrame=frame
            end)
        else RS:UnbindFromRenderStep("DKDFly"); getgenv()._DKD_flyFrame=nil end
    end
}, "Fly")
Opt.FlySpeed = CharL:Slider({ Name="Fly Speed", Default=100, Minimum=0, Maximum=5000, Precision=0, Callback=function(v) S.flySpeed=v end }, "FlySpeed")
Opt.FlyMode  = CharL:Dropdown({ Name="Fly Mode", Options={"MoveDirection","Camera LookVector"}, Default=1, Multi=false, Callback=function() end }, "FlyMode")
CharL:Divider()
Opt.TweenMode      = CharL:Dropdown({ Name="Safe Mode", Options={"Normal","Safe"}, Default=1, Multi=false, Callback=function() end }, "TweenMode")
Opt.SafeModeHeight = CharL:Slider({ Name="Safe Height", Default=1000, Minimum=0, Maximum=100000, Precision=0, Callback=function() end }, "SafeModeHeight")
CharL:Button({ Name="Cancel Tween", Callback=function() _cancelTween=true end })
Tog.Speedhack = CharL:Toggle({
    Name="Speedhack", Default=false, Keybind=Enum.KeyCode.N,
    Callback=function(p)
        if p then RS:BindToRenderStep("DKDSpeed",Enum.RenderPriority.Input.Value,function(dt)
            local c=getChar(); if not c then return end; local hum=c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then return end
            local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            if hum.MoveDirection.Magnitude>0 then hrp.CFrame=hrp.CFrame+hum.MoveDirection*S.speed*dt end
        end) else RS:UnbindFromRenderStep("DKDSpeed") end
    end
}, "Speedhack")
Opt.SpeedhackSpeed = CharL:Slider({ Name="Speedhack Speed", Default=100, Minimum=0, Maximum=5000, Precision=0, Callback=function(v) S.speed=v end }, "SpeedhackSpeed")
local ijConn=nil
Tog.InfiniteJump = CharL:Toggle({
    Name="Infinite Jump", Default=false, Keybind=Enum.KeyCode.H,
    Callback=function(p)
        if ijConn then ijConn:Disconnect(); ijConn=nil end
        if p then ijConn=UIS.InputBegan:Connect(function(input,gpe)
            if gpe or input.KeyCode~=Enum.KeyCode.Space then return end
            local hrp=getHRP(); if not hrp then return end
            hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X,S.infJumpH,hrp.AssemblyLinearVelocity.Z)
        end) end
    end
}, "InfiniteJump")
Opt.InfiniteJumpHeight = CharL:Slider({ Name="Jump Height", Default=50, Minimum=0, Maximum=1000, Precision=0, Callback=function(v) S.infJumpH=v end }, "InfiniteJumpHeight")
local noclipConn=nil
Tog.Noclip = CharL:Toggle({
    Name="Noclip", Default=false, Keybind=Enum.KeyCode.T,
    Callback=function(p)
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
        if not p then return end
        local cached={}; local lastChar=nil
        noclipConn=RS.Heartbeat:Connect(function()
            local c=getChar()
            if c~=lastChar then cached={}; lastChar=c; if c then for _,d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then cached[#cached+1]=d end end end end
            for _,part in ipairs(cached) do if part.Parent then part.CanCollide=false end end
        end)
    end
}, "Noclip")

-- No Fall Damage
local _noFallConn = nil
Tog.NoFallDmg = CharL:Toggle({
    Name="No Fall Damage", Default=false,
    Callback=function(p)
        if _noFallConn then _noFallConn:Disconnect(); _noFallConn=nil end
        if not p then return end
        local charEvent = nil
        pcall(function() charEvent = game:GetService("ReplicatedStorage").Communication.Character end)
        if not charEvent then notify("Communication.Character not found", 3); Tog.NoFallDmg:UpdateState(false); return end
        _noFallConn = RS.Heartbeat:Connect(function()
            local c = getChar(); if not c then return end
            local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
            local state = hum:GetState()
            if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Landed then
                pcall(function()
                    charEvent:FireServer("Humanoid.StateChanged", nil, "Landed", {
                        Previous = 0,
                        Current = 0
                    })
                end)
            end
        end)
    end
}, "NoFallDmg")
onUnload(function() if _noFallConn then _noFallConn:Disconnect() end end)

CharL:Divider()
local MORPHS={
    ["Goku"]       ={hair=96778240725860, shirt=18642081551,    pants=13980707182   },
    ["Naruto"]     ={hair=129818847988995,shirt=6469644436,     pants=2733834231    },
    ["Gojo"]       ={hair=132501783778842,shirt=73084050138865, pants=15312673306   },
    ["Toji"]       ={hair=135664715112347,shirt=121088463088431,pants=16149857407   },
    ["Aizen"]      ={hair=117644781784979,shirt=87853669951881, pants=118029167731205},
    ["Guts"]       ={hair=117337600216775,shirt=13381096342,    pants=13381103162   },
    ["Vasto Lorde"]={hair=107798985962651,shirt=15549196125,    pants=15886594659   },
    ["Luffy"]      ={hair=103832443149308,shirt=8483860912,     pants=6274345723    },
    ["Zero Two"]   ={hair=93023559996037, shirt=6392201226,     pants=5896597102    },
    ["Yoruichi"]   ={hair=80207230854028, face=82588218846528,  shirt=18842292222,  pants=79431307149311},
}
local function clearMorph(char) for _,v in ipairs(char:GetChildren()) do if v:IsA("Accessory") or v:IsA("Hat") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then pcall(function() v:Destroy() end) end end end
local function addHair(char,id)
    local head=char:FindFirstChild("Head"); if not head then return end
    pcall(function()
        local objs=game:GetObjects("rbxassetid://"..tostring(id)); if not objs or not objs[1] then return end
        local acc=objs[1]; if not (acc:IsA("Accessory") or acc:IsA("Hat")) then return end
        local handle=acc:FindFirstChild("Handle"); if not handle then return end
        local headAtt=head:FindFirstChild("HairAttachment") or head:FindFirstChild("HatAttachment")
        local handleAtt=handle:FindFirstChild("HairAttachment") or handle:FindFirstChild("HatAttachment") or handle:FindFirstChild("BodyFrontAttachment")
        if headAtt and handleAtt then handle.CFrame=head.CFrame*headAtt.CFrame*handleAtt.CFrame:Inverse()
        else handle.CFrame=head.CFrame*CFrame.new(0,head.Size.Y*0.5+handle.Size.Y*0.3,0) end
        local wc=Instance.new("WeldConstraint"); wc.Part0=head; wc.Part1=handle; wc.Parent=handle
        handle.Anchored=false; acc.Parent=char
    end)
end
local function applyMorph(name)
    local char=LP.Character; if not char then return end
    local def=MORPHS[name]; clearMorph(char)
    local head=char:FindFirstChild("Head")
    if head then
        for _,v in ipairs(head:GetChildren()) do if v:IsA("Decal") then v:Destroy() end end
        if def and def.face then head.Transparency=0; local d=Instance.new("Decal"); d.Texture="rbxassetid://"..tostring(def.face); d.Face=Enum.NormalId.Front; d.Parent=head else head.Transparency=def and 1 or 0 end
    end
    if not def then return end
    if def.shirt then local s=char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt",char); s.ShirtTemplate="rbxassetid://"..tostring(def.shirt) end
    if def.pants then local p=char:FindFirstChildOfClass("Pants") or Instance.new("Pants",char); p.PantsTemplate="rbxassetid://"..tostring(def.pants) end
    addHair(char,def.hair)
end
local morphNames={"None"}; for k in pairs(MORPHS) do table.insert(morphNames,k) end; table.sort(morphNames)
Opt.MorphSelect = CharL2:Dropdown({ Name="Morph", Search=true, Options=morphNames, Default=1, Multi=false, Callback=function(v) local sel=type(v)=="table" and next(v) or v; task.spawn(function() applyMorph(sel~="None" and sel or nil) end) end }, "MorphSelect")
Opt.MorphSelect.IgnoreConfig = true
CharL2:Button({ Name="Reset Morph", Callback=function() Opt.MorphSelect:UpdateSelection(1); task.spawn(function() applyMorph(nil) end) end })
CharL2:Divider()
CharR:Button({ Name="Kill Self", Callback=function() local hum=getHum(); if hum then hum.Health=0 end end })
CharR:Divider()
local noAnimsThread=nil; local forcedTracks={}; local origTracks={}
Tog.NoAnims = CharR:Toggle({
    Name="No Anims", Default=false,
    Callback=function(p)
        if noAnimsThread then task.cancel(noAnimsThread); noAnimsThread=nil end
        if p then
            local c=getChar(); if not c then return end; local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
            local anim=hum:FindFirstChildOfClass("Animator"); if not anim then return end
            local dummy=Instance.new("Animation"); dummy.AnimationId="rbxassetid://109212722752"
            noAnimsThread=task.spawn(function()
                while Tog.NoAnims and Tog.NoAnims.State and hum and hum.Parent do
                    for _,track in ipairs(anim:GetPlayingAnimationTracks()) do if track.Animation.AnimationId~=dummy.AnimationId then if not table.find(origTracks,track) then table.insert(origTracks,track) end; pcall(function() track:Stop(); task.defer(track.Destroy,track) end) end end
                    local found=false; for _,track in ipairs(anim:GetPlayingAnimationTracks()) do if track.Animation.AnimationId==dummy.AnimationId then found=true end end
                    if not found then local t=anim:LoadAnimation(dummy); table.insert(forcedTracks,t); t.Priority=Enum.AnimationPriority.Core; t:AdjustSpeed(0); t:Play() end
                    task.wait(0.1)
                end
            end)
        else
            for _,track in pairs(forcedTracks) do pcall(function() track:Stop(); track:Destroy() end) end; forcedTracks={}
            for _,track in pairs(origTracks) do pcall(function() track:Play() end) end; origTracks={}
        end
    end
}, "NoAnims")
;(function()
    local _animSpeedConn=nil; local _animSpeed=1
    local function applyAnimSpeed(speed)
        pcall(function() local char=getChar(); if not char then return end; local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end; local anim=hum:FindFirstChildOfClass("Animator"); if not anim then return end; for _,track in ipairs(anim:GetPlayingAnimationTracks()) do pcall(function() track:AdjustSpeed(speed) end) end end)
    end
    Tog.AnimSpeed = CharR:Toggle({ Name="Anim Speed", Default=false, Callback=function(p) if _animSpeedConn then _animSpeedConn:Disconnect(); _animSpeedConn=nil end; if p then _animSpeedConn=RS.Heartbeat:Connect(function() applyAnimSpeed(_animSpeed) end) else applyAnimSpeed(1) end end }, "AnimSpeed")
    Opt.AnimSpeedSlider = CharR:Slider({ Name="Speed", Default=1, Minimum=0.1, Maximum=200, Precision=1, Callback=function(v) _animSpeed=v end }, "AnimSpeedSlider")
    onUnload(function() if _animSpeedConn then _animSpeedConn:Disconnect(); _animSpeedConn=nil end; applyAnimSpeed(1) end)
end)()
CharR:Divider()

CharR:Divider()
local _savedPos=nil; local _autoTPConn=nil
CharR:Button({ Name="Save Position", Callback=function() local hrp=getHRP(); if hrp then _savedPos=hrp.CFrame end end })
CharR:Button({ Name="TP to Saved",   Callback=function() if not _savedPos then return end; task.spawn(function() tweenTo(_savedPos) end) end })
CharR:Divider()
Opt.AutoTPHP = CharR:Slider({ Name="HP Threshold", Default=20, Minimum=1, Maximum=99, Precision=0, Callback=function() end }, "AutoTPHP")
local _autoTPing=false
Tog.AutoTPSafe = CharR:Toggle({ Name="Auto Retreat", Default=false, Callback=function(p) if _autoTPConn then _autoTPConn:Disconnect(); _autoTPConn=nil end; if not p then return end; _autoTPConn=RS.Heartbeat:Connect(function() if not _savedPos or _autoTPing then return end; local hum=getHum(); if not hum or hum.Health<=0 then return end; if (hum.Health/hum.MaxHealth*100)<=(Opt.AutoTPHP and Opt.AutoTPHP.Value or 20) then _autoTPing=true; task.spawn(function() tweenTo(_savedPos); _autoTPing=false end) end end) end }, "AutoTPSafe")
local afkConn=nil; local _afkLoop=false
Tog.AntiAFK = CharR:Toggle({ Name="Anti AFK", Default=true, Callback=function(p)
    if afkConn then afkConn:Disconnect(); afkConn=nil end
    _afkLoop=p
    if not p then return end
    local function nudge()
        pcall(function()
            local VU=game:GetService("VirtualUser")
            VU:Button2Down(Vector2.zero,workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            VU:Button2Up(Vector2.zero,workspace.CurrentCamera.CFrame)
        end)
    end

    afkConn=LP.Idled:Connect(nudge)

    task.spawn(function()
        while _afkLoop do task.wait(240); if _afkLoop then nudge() end end
    end)
end }, "AntiAFK")
CharR:Divider()
local _noSlowConn=nil
Tog.NoSlow = CharR2:Toggle({ Name="No Slow", Default=false, Callback=function(p) if _noSlowConn then _noSlowConn:Disconnect(); _noSlowConn=nil end; if not p then return end; _noSlowConn=RS.Heartbeat:Connect(function() pcall(function() local s=_getStatus(); if not s then return end; for _,v in ipairs(s:GetChildren()) do local n=v.Name:lower(); if n:find("slow") or n:find("stun") or n:find("freeze") or n:find("root") or n:find("immobil") or n:find("paraly") or n:find("stop") or n:find("bind") or n:find("snare") then pcall(function() v:Destroy() end) end end; local char=LP.Character; local hum=char and char:FindFirstChildOfClass("Humanoid"); if hum and hum.WalkSpeed<16 then hum.WalkSpeed=16 end end) end) end }, "NoSlow")
onUnload(function() if _noSlowConn then _noSlowConn:Disconnect() end end)
;(function()
    local _tpDeathConn=nil; local _tpDeathPos=nil
    Tog.TPOnDeath = CharR2:Toggle({ Name="TP Back on Death", Default=false, Callback=function(p)
        if _tpDeathConn then _tpDeathConn:Disconnect(); _tpDeathConn=nil end; if not p then return end
        local function hookChar(char) if not char then return end; local hum=char:WaitForChild("Humanoid",5); if not hum then return end; local hrp=char:WaitForChild("HumanoidRootPart",5); if not hrp then return end; local saveConn=RS.Heartbeat:Connect(function() if hum.Health>0 then _tpDeathPos=hrp.CFrame end end); hum.Died:Connect(function() saveConn:Disconnect(); if not _tpDeathPos then return end; local savedCF=_tpDeathPos; local newChar=LP.CharacterAdded:Wait(); local newHRP=newChar:WaitForChild("HumanoidRootPart",5); if newHRP and Tog.TPOnDeath and Tog.TPOnDeath.State then newHRP.CFrame=savedCF end end) end
        hookChar(LP.Character); _tpDeathConn=LP.CharacterAdded:Connect(function(char) task.wait(0.1); hookChar(char) end)
    end }, "TPOnDeath")
    onUnload(function() if _tpDeathConn then pcall(function() _tpDeathConn:Disconnect() end) end end)
end)()
CharR2:Divider()
local aimbotConn=nil; local fovCircle=nil; local aimKeyType="MB2"
local function getFOVScale() return Cam.ViewportSize.Y/2/math.tan(math.rad(Cam.FieldOfView/2)) end
local function getAimTargets() local list={}; if S.targetPlayers then for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP and plr.Character then if not S.teamCheck or not LP.Team or plr.Team~=LP.Team then table.insert(list,plr.Character) end end end end; return list end
local function getAimPart(char) local v=Opt.AimPart and Opt.AimPart.Value or "Head"; if v=="Head" then return char:FindFirstChild("Head") end; if v=="Torso" then return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") end; if v=="Random" then local parts={}; for _,n in ipairs({"Head","HumanoidRootPart","Torso"}) do local p=char:FindFirstChild(n); if p then table.insert(parts,p) end end; return #parts>0 and parts[math.random(1,#parts)] or nil end; return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") end
local function isVisible(part) if not S.visibleOnly then return true end; local c=getChar(); if not c then return false end; local origin=Cam.CFrame.Position; local params=RaycastParams.new(); params.FilterDescendantsInstances={c}; params.FilterType=Enum.RaycastFilterType.Exclude; local result=workspace:Raycast(origin,(part.Position-origin),params); if not result then return true end; return result.Instance and result.Instance:IsDescendantOf(part.Parent) end
UIS.InputBegan:Connect(function(inp,gpe) if gpe then return end; local n=inp.UserInputType==Enum.UserInputType.MouseButton1 and "MB1" or inp.UserInputType==Enum.UserInputType.MouseButton2 and "MB2" or inp.KeyCode.Name; if n==aimKeyType and S.aimbotMode=="Hold" then S.aimbotActive=true end end)
UIS.InputEnded:Connect(function(inp) local n=inp.UserInputType==Enum.UserInputType.MouseButton1 and "MB1" or inp.UserInputType==Enum.UserInputType.MouseButton2 and "MB2" or inp.KeyCode.Name; if n==aimKeyType and S.aimbotMode=="Hold" then S.aimbotActive=false end end)
Opt.AimbotMode   = CharR3:Dropdown({ Name="Aimbot Mode",   Options={"Toggle","Hold","Always"}, Default=1, Multi=false, Callback=function(v) S.aimbotMode=type(v)=="table" and next(v) or v; if S.aimbotMode=="Always" then S.aimbotActive=true elseif S.aimbotMode~="Hold" then S.aimbotActive=false end end }, "AimbotMode")
Opt.AimbotMethod = CharR3:Dropdown({ Name="Aimbot Method", Options={"Camera","mousemoverel"},   Default=1, Multi=false, Callback=function(v) S.aimbotMethod=type(v)=="table" and next(v) or v end }, "AimbotMethod")
Opt.AimPart      = CharR3:Dropdown({ Name="Aim Part",      Options={"Head","Torso","Random"},   Default=1, Multi=false, Callback=function() end }, "AimPart")
Opt.AimbotKeybind = CharR3:Keybind({ Name="Aimbot Keybind", Default=Enum.KeyCode.Unknown, onBinded=function(bind) aimKeyType=tostring(bind.Name) end }, "AimbotKeybind")
Tog.Aimbot = CharR3:Toggle({
    Name="Aimbot", Default=false,
    Callback=function(p)
        S.aimbotEnabled=p; if aimbotConn then aimbotConn:Disconnect(); aimbotConn=nil end
        if not p then S.aimbotActive=false; return end
        if S.aimbotMode=="Always" then S.aimbotActive=true end
        local accum=Vector2.zero
        aimbotConn=RS.RenderStepped:Connect(function()
            if not S.aimbotActive then return end
            local vpSize=Cam.ViewportSize; local cx=vpSize.X/2+S.aimbotX; local cy=vpSize.Y/2+S.aimbotY
            local fovPx=math.tan(math.rad(S.aimbotFOV/2))*getFOVScale(); local best,bestDist=nil,fovPx
            for _,char in ipairs(getAimTargets()) do
                local part=getAimPart(char); if not part then continue end
                local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then continue end
                if not isVisible(part) then continue end
                local sp,onScreen=Cam:WorldToViewportPoint(part.Position); if not onScreen then continue end
                local d=((sp.X-cx)^2+(sp.Y-cy)^2)^0.5; if d<bestDist then bestDist=d; best=part end
            end
            if best then
                local target=best.Position
                if S.aimbotX~=0 or S.aimbotY~=0 then local v=Cam:WorldToViewportPoint(target); local shifted=Vector2.new(v.X+S.aimbotX,v.Y+S.aimbotY); local ray=Cam:ViewportPointToRay(shifted.X,shifted.Y); target=ray.Origin+ray.Direction*100 end
                if S.aimbotMethod=="Camera" then local t=math.clamp(S.aimbotSens*0.1,0.01,1); local lv=Cam.CFrame.LookVector:Lerp((target-Cam.CFrame.Position).Unit,t); Cam.CFrame=CFrame.new(Cam.CFrame.Position,Cam.CFrame.Position+lv)
                else local sp2=Cam:WorldToViewportPoint(target); local mouse=UIS:GetMouseLocation(); accum=accum+(Vector2.new(sp2.X,sp2.Y)-mouse)*S.aimbotSens; local cap=10; local clamped=Vector2.new(math.clamp(accum.X,-cap,cap),math.clamp(accum.Y,-cap,cap)); pcall(function() mousemoverel(clamped.X,clamped.Y) end); accum=accum-clamped end
            end
        end)
    end
}, "Aimbot")
Tog.AimbotPlayers = CharR3:Toggle({ Name="Target Players", Default=true,  Callback=function(p) S.targetPlayers=p end }, "AimbotPlayers")
Tog.VisibleOnly   = CharR3:Toggle({ Name="Visible Only",   Default=false, Callback=function(p) S.visibleOnly=p   end }, "VisibleOnly")
Tog.TeamCheck     = CharR3:Toggle({ Name="Team Check",     Default=false, Callback=function(p) S.teamCheck=p     end }, "TeamCheck")
CharR3:Divider()
Opt.AimbotSens    = CharR3:Slider({ Name="Lock Strength",  Default=1,     Minimum=0.1, Maximum=5,   Precision=2, Callback=function(v) S.aimbotSens=v end }, "AimbotSens")
Opt.AimbotXOffset = CharR3:Slider({ Name="X Offset",       Default=0,     Minimum=-300, Maximum=300, Precision=0, Callback=function(v) S.aimbotX=v end }, "AimbotXOffset")
Opt.AimbotYOffset = CharR3:Slider({ Name="Y Offset",       Default=0,     Minimum=-300, Maximum=300, Precision=0, Callback=function(v) S.aimbotY=v end }, "AimbotYOffset")
Tog.ShowFOV = CharR3:Toggle({ Name="Show FOV", Default=false, Callback=function(p) if p then if not fovCircle then fovCircle=Drawing.new("Circle"); fovCircle.Thickness=1; fovCircle.NumSides=100; fovCircle.Filled=false; fovCircle.Color=Color3.fromRGB(255,255,255) end; fovCircle.Radius=S.aimbotFOV*getFOVScale(); fovCircle.Position=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2); fovCircle.Visible=true elseif fovCircle then fovCircle.Visible=false end end }, "ShowFOV")
Opt.AimbotFOV = CharR3:Slider({ Name="Lock FOV", Default=45, Minimum=1, Maximum=120, Precision=0, Callback=function(v) S.aimbotFOV=v; if fovCircle and fovCircle.Visible then fovCircle.Radius=v*getFOVScale() end end }, "AimbotFOV")

onUnload(function()
    RS:UnbindFromRenderStep("DKDSpeed")
    RS:UnbindFromRenderStep("DKDFly")
    RS:UnbindFromRenderStep("DKDTween")
    RS:UnbindFromRenderStep("DKDChestTween")
    RS:UnbindFromRenderStep("DKDMobTween")
    getgenv()._DKD_flyFrame=nil

    if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
    local c=getChar(); if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide=true end) end end end

    if ijConn then ijConn:Disconnect() end
    if _autoTPConn then _autoTPConn:Disconnect() end
    if afkConn then afkConn:Disconnect() end; _afkLoop=false

    if aimbotConn then aimbotConn:Disconnect() end
    if fovCircle then pcall(function() fovCircle:Remove() end) end

    if noAnimsThread then task.cancel(noAnimsThread); noAnimsThread=nil end
    for _,t in pairs(forcedTracks) do pcall(function() t:Stop(); t:Destroy() end) end; forcedTracks={}
    for _,t in pairs(origTracks) do pcall(function() t:Play() end) end; origTracks={}


    if getgenv()._ZHCrosshair then for _,d in ipairs(getgenv()._ZHCrosshair) do pcall(function() d:Remove() end) end; getgenv()._ZHCrosshair=nil end
end)


-- ── RAKNET ─────────────
CharR2:Divider()
CharR2:Label({ Text="RakNet" })
Tog.RaknetDesync = CharR2:Toggle({ Name="Raknet Desync", Default=false, Risky=true,
    Callback=function(p)
        local rn=getgenv().raknet
        if p then
            if not rn or not rn.add_send_hook then notify("raknet not available",3); Tog.RaknetDesync:UpdateState(false); return end
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
Tog.FakeLag = CharR2:Toggle({ Name="Fake Lag", Default=false, Risky=true,
    Callback=function(p)
        local rn=getgenv().raknet
        if p then
            if not rn or not rn.add_send_hook then notify("raknet not available",3); Tog.FakeLag:UpdateState(false); return end
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
Opt.FakeLagMs = CharR2:Slider({ Name="Lag (ms)", Default=200, Minimum=50, Maximum=2000, Precision=0, Callback=function() end }, "FakeLagMs")
onUnload(function() if shared._zh_desync and getgenv().raknet and getgenv().raknet.remove_send_hook then pcall(function() getgenv().raknet.remove_send_hook(shared._zh_desync) end); shared._zh_desync=nil end end)
onUnload(function() if shared._zh_fakelag and getgenv().raknet and getgenv().raknet.remove_send_hook then pcall(function() getgenv().raknet.remove_send_hook(shared._zh_fakelag) end); shared._zh_fakelag=nil end end)


-- ══════════════════════════════════════════════════════════════════════════════
-- WORLD TAB
-- ══

-- Travel Areas
local WorldL = Tabs.World:Section({ Side="Left", Name="Travel Areas", Image="map-pin" })
do
    local _areasRemote = nil
    pcall(function() _areasRemote = game:GetService("ReplicatedStorage").Remotes.Areas end)

    local function getAreas()
        local list = {}
        local areasFolder = workspace:FindFirstChild("Areas")
        if areasFolder then
            for _, area in ipairs(areasFolder:GetChildren()) do
                if area:IsA("Folder") or area:IsA("Model") then
                    table.insert(list, area.Name)
                end
            end
        end
        table.sort(list)
        if #list == 0 then list = {"No areas found"} end
        return list
    end

    local function getDestinations(areaName)
        local list = {}
        local areasFolder = workspace:FindFirstChild("Areas")
        if areasFolder then
            local area = areasFolder:FindFirstChild(areaName)
            if area then
                local paths = area:FindFirstChild("Paths")
                if paths then
                    local torii = paths:FindFirstChild("Torii")
                    if torii then
                        for _, t in ipairs(torii:GetChildren()) do
                            local dest = t.Name:gsub("Torii_", "")
                            table.insert(list, dest)
                        end
                    end
                end
            end
        end
        table.sort(list)
        if #list == 0 then list = {"No destinations"} end
        return list
    end

    local _selectedArea = nil
    local _selectedDest = nil

    Opt.TravelArea = WorldL:Dropdown({ Name="Area", Options=getAreas(), Default=1, Multi=false, Search=true,
        Callback=function(v)
            _selectedArea = type(v)=="table" and next(v) or v
            if _selectedArea and Opt.TravelDest then
                pcall(function()
                    Opt.TravelDest:ClearOptions()
                    Opt.TravelDest:InsertOptions(getDestinations(_selectedArea))
                end)
            end
        end }, "TravelArea")

    Opt.TravelDest = WorldL:Dropdown({ Name="Destination", Options={"Select area first"}, Default=1, Multi=false, Search=true,
        Callback=function(v) _selectedDest = type(v)=="table" and next(v) or v end }, "TravelDest")

    WorldL:Button({ Name="Travel", Callback=function()
        if not _areasRemote then notify("Remotes.Areas not found", 3); return end
        if not _selectedArea or _selectedArea == "No areas found" then notify("Select an area", 2); return end
        if not _selectedDest or _selectedDest == "No destinations" or _selectedDest == "Select area first" then notify("Select a destination", 2); return end
        pcall(function()
            _areasRemote:FireServer("Travel", {
                Area = _selectedArea,
                Destination = _selectedDest
            })
        end)
        notify("Traveling to " .. _selectedDest .. " in " .. _selectedArea, 3)
    end })

    WorldL:Button({ Name="TP to Area Entrance", Callback=function()
        if not _selectedArea then notify("Select an area", 2); return end
        pcall(function()
            local entrance = workspace.Areas[_selectedArea].Paths.Entrance
            local hrp = getHRP(); if not hrp then return end
            hrp.CFrame = entrance.CFrame + Vector3.new(0, 3, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
        end)
        notify("TP'd to " .. _selectedArea .. " entrance", 2)
    end })

    WorldL:Button({ Name="Refresh Areas", Callback=function()
        if Opt.TravelArea then pcall(function() Opt.TravelArea:ClearOptions(); Opt.TravelArea:InsertOptions(getAreas()) end) end
        notify("Areas refreshed", 2)
    end })
end

-- ═══════════════════════════════════════
local function buildSpecList()
    local list={"None"}
    for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(list,plr.Name) end end
    return list
end
local specTarget="None"; local specConn=nil
Opt.SpectatePlayers = WorldL2:Dropdown({ Name="Spectate Player", Search=true, Options=buildSpecList(), Default=1, Multi=false, Callback=function(v) specTarget=type(v)=="table" and next(v) or v end }, "SpectatePlayers")
WorldL2:Button({ Name="Spectate / Stop", Callback=function()
    if specConn then pcall(function() specConn:Disconnect() end); specConn=nil
        local c=getChar(); Cam.CameraSubject=c and c:FindFirstChildOfClass("Humanoid") or c; Cam.CameraType=Enum.CameraType.Custom; return
    end
    local name=tostring(specTarget or ""); local plr=PS:FindFirstChild(name); local char=plr and plr.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    Cam.CameraSubject=hum; Cam.CameraType=Enum.CameraType.Custom
    specConn=plr.CharacterAdded:Connect(function(c) task.wait(0.5); local h=c:FindFirstChildOfClass("Humanoid"); if h then Cam.CameraSubject=h end end)
end})
local noFogConn=nil
Tog.NoFog = WorldL2:Toggle({
    Name="No Fog", Default=false,
    Callback=function(p)
        if noFogConn then noFogConn:Disconnect(); noFogConn=nil end
        local atmos=LT:FindFirstChildOfClass("Atmosphere")
        if p then
            LT.FogStart=1e9; LT.FogEnd=1e9
            if atmos then atmos.Density=0; atmos.Haze=0; atmos.Glare=0 end
            noFogConn=LT:GetPropertyChangedSignal("FogEnd"):Connect(function() if LT.FogEnd<1e8 then LT.FogStart=1e9; LT.FogEnd=1e9 end end)
        else
            LT.FogStart=0; LT.FogEnd=100000
            if atmos then atmos.Density=0.395; atmos.Haze=0; atmos.Glare=0 end
        end
    end
}, "NoFog")
Tog.NoAtmosphere = WorldL2:Toggle({
    Name="No Atmosphere", Default=false,
    Callback=function(p)
        pcall(function()
            local atmos=LT:FindFirstChildOfClass("Atmosphere"); if not atmos then return end
            if p then atmos.Density=0; atmos.Offset=0; atmos.Haze=0; atmos.Glare=0
            else atmos.Density=0.395; atmos.Offset=0; atmos.Haze=0; atmos.Glare=0 end
        end)
    end
}, "NoAtmosphere")
WorldL2:Divider()
local fbConn=nil
Tog.FullBright = WorldL2:Toggle({
    Name="FullBright", Default=false,
    Callback=function(p)
        if fbConn then fbConn:Disconnect(); fbConn=nil end
        if p then fbConn=RS.RenderStepped:Connect(function() LT.Brightness=S.brightness; LT.ClockTime=14; LT.FogEnd=100000; LT.GlobalShadows=false; LT.OutdoorAmbient=Color3.fromRGB(128,128,128) end)
        else LT.Brightness=1; LT.ClockTime=14; LT.FogEnd=1000000; LT.GlobalShadows=true end
    end
}, "FullBright")
Opt.Brightness = WorldL2:Slider({ Name="Brightness", Default=2, Minimum=0, Maximum=10, Precision=1, Callback=function(v) S.brightness=v end }, "Brightness")
WorldL2:Divider()
local _ambientConn=nil; local _ambientColor=Color3.fromRGB(128,128,128)
Tog.CustomAmbient = WorldL2:Toggle({
    Name="World Ambient", Default=false,
    Callback=function(p)
        if _ambientConn then _ambientConn:Disconnect(); _ambientConn=nil end
        if p then _ambientConn=RS.RenderStepped:Connect(function() LT.Ambient=_ambientColor; LT.OutdoorAmbient=_ambientColor end)
        else LT.Ambient=Color3.fromRGB(0,0,0); LT.OutdoorAmbient=Color3.fromRGB(128,128,128) end
    end
}, "CustomAmbient")
Opt.WorldAmbient = WorldL2:Colorpicker({ Name="Ambient Color", Default=Color3.fromRGB(128,128,128), Alpha=0, Callback=function(v) _ambientColor=v end }, "WorldAmbient")
WorldL2:Divider()
local freecamConns={}; local _fcPitch=0; local _fcYaw=0; local _fcPos=Vector3.zero
Tog.Freecam = WorldL2:Toggle({
    Name="Free Cam", Default=false,
    Callback=function(p)
        for _,c in ipairs(freecamConns) do pcall(function() c:Disconnect() end) end; freecamConns={}
        UIS.MouseBehavior=Enum.MouseBehavior.Default
        if not p then Cam.CameraType=Enum.CameraType.Custom; return end
        local cf=Cam.CFrame; _fcPos=cf.Position
        _fcYaw=math.atan2(-cf.LookVector.X,-cf.LookVector.Z)
        _fcPitch=math.asin(math.clamp(cf.LookVector.Y,-1,1))
        Cam.CameraType=Enum.CameraType.Scriptable
        local rmb=false
        table.insert(freecamConns,UIS.InputBegan:Connect(function(inp,gpe) if gpe then return end; if inp.UserInputType==Enum.UserInputType.MouseButton2 then rmb=true end end))
        table.insert(freecamConns,UIS.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton2 then rmb=false; UIS.MouseBehavior=Enum.MouseBehavior.Default end end))
        table.insert(freecamConns,RS.RenderStepped:Connect(function(dt)
            if rmb then local d=UIS:GetMouseDelta(); _fcYaw=_fcYaw-d.X*S.freeCamSens*0.003; _fcPitch=math.clamp(_fcPitch-d.Y*S.freeCamSens*0.003,-1.55,1.55); UIS.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition
            else UIS.MouseBehavior=Enum.MouseBehavior.Default end
            local rot=CFrame.fromEulerAnglesYXZ(_fcPitch,_fcYaw,0)
            local spd=S.freeCamSpeed*dt*20*(UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1)
            if UIS:IsKeyDown(Enum.KeyCode.W)           then _fcPos=_fcPos+rot.LookVector*spd  end
            if UIS:IsKeyDown(Enum.KeyCode.S)           then _fcPos=_fcPos-rot.LookVector*spd  end
            if UIS:IsKeyDown(Enum.KeyCode.A)           then _fcPos=_fcPos-rot.RightVector*spd end
            if UIS:IsKeyDown(Enum.KeyCode.D)           then _fcPos=_fcPos+rot.RightVector*spd end
            if UIS:IsKeyDown(Enum.KeyCode.Space)       then _fcPos=_fcPos+Vector3.yAxis*spd   end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then _fcPos=_fcPos-Vector3.yAxis*spd   end
            Cam.CFrame=CFrame.new(_fcPos)*rot
        end))
    end
}, "Freecam")
Opt.FreeCamSens  = WorldL2:Slider({ Name="Look Sensitivity", Default=0.3, Minimum=0.1, Maximum=5,  Precision=1, Callback=function(v) S.freeCamSens=v  end }, "FreeCamSens")
Opt.FreeCamSpeed = WorldL2:Slider({ Name="Move Speed",       Default=0.5, Minimum=0.1, Maximum=50, Precision=1, Callback=function(v) S.freeCamSpeed=v end }, "FreeCamSpeed")

Tog.FOVChanger = WorldR:Toggle({ Name="Custom FOV", Default=false, Callback=function(p) if p then Cam.FieldOfView=S.fovVal else Cam.FieldOfView=70 end end }, "FOVChanger")
Opt.FOV = WorldR:Slider({ Name="Camera FOV", Default=70, Minimum=0, Maximum=120, Precision=1, Callback=function(v) S.fovVal=v; if Tog.FOVChanger and Tog.FOVChanger.State then Cam.FieldOfView=v end end }, "FOV")
local _cursorConn=nil; local _cursorDot=nil; local _cursorRing=nil
Tog.CustomCursor = WorldR:Toggle({
    Name="Dot Cursor", Default=false,
    Callback=function(p)
        if _cursorConn then _cursorConn:Disconnect(); _cursorConn=nil end
        if _cursorDot  then _cursorDot:Remove();  _cursorDot=nil   end
        if _cursorRing then _cursorRing:Remove(); _cursorRing=nil  end
        game:GetService("UserInputService").MouseIconEnabled=not p
        if not p then return end
        _cursorDot=Drawing.new("Circle"); _cursorDot.Radius=6; _cursorDot.Filled=true; _cursorDot.Visible=true; _cursorDot.Color=Color3.new(1,1,1); _cursorDot.Transparency=1; _cursorDot.Thickness=1
        _cursorRing=Drawing.new("Circle"); _cursorRing.Radius=10; _cursorRing.Filled=false; _cursorRing.Visible=true; _cursorRing.Color=Color3.new(1,1,1); _cursorRing.Transparency=0.8; _cursorRing.Thickness=1.5
        _cursorConn=RS.RenderStepped:Connect(function()
            local mp=game:GetService("UserInputService"):GetMouseLocation()
            _cursorDot.Position=mp; _cursorRing.Position=mp
            local curCol=espColor or Color3.new(1,1,1)
            _cursorDot.Color=curCol; _cursorRing.Color=curCol
        end)
    end
}, "CustomCursor")
Tog.CursorFilled = WorldR:Toggle({ Name="Cursor Dot Filled", Default=true, Callback=function(p) if _cursorDot then _cursorDot.Filled=p end end }, "CursorFilled")
Opt.CursorSize     = WorldR:Slider({ Name="Cursor Size",  Default=6,  Minimum=1, Maximum=20, Precision=0, Callback=function(v) if _cursorDot  then _cursorDot.Radius=v  end end }, "CursorSize")
Opt.CursorRingSize = WorldR:Slider({ Name="Ring Size",    Default=10, Minimum=0, Maximum=30, Precision=0, Callback=function(v) if _cursorRing then _cursorRing.Radius=v end end }, "CursorRingSize")
WorldR:Divider()
Tog.CustomCrosshair = WorldR:Toggle({
    Name="Crosshair", Default=false,
    Callback=function(p)
        if p then
            if not getgenv()._ZHCrosshair then
                local d=Drawing.new("Square"); d.Size=Vector2.new(14,14); d.Position=Vector2.new(Cam.ViewportSize.X/2-7,Cam.ViewportSize.Y/2-7); d.Color=Color3.new(1,1,1); d.Transparency=1; d.Filled=false; d.Thickness=1; d.Visible=true
                local d2=Drawing.new("Line"); d2.From=Vector2.new(Cam.ViewportSize.X/2-6,Cam.ViewportSize.Y/2); d2.To=Vector2.new(Cam.ViewportSize.X/2+6,Cam.ViewportSize.Y/2); d2.Color=Color3.new(1,1,1); d2.Thickness=1; d2.Visible=true
                local d3=Drawing.new("Line"); d3.From=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2-6); d3.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2+6); d3.Color=Color3.new(1,1,1); d3.Thickness=1; d3.Visible=true
                getgenv()._ZHCrosshair={d,d2,d3}
            end
        else
            if getgenv()._ZHCrosshair then for _,d in ipairs(getgenv()._ZHCrosshair) do pcall(function() d:Remove() end) end; getgenv()._ZHCrosshair=nil end
        end
    end
}, "CustomCrosshair")

Tog.AntiLag = WorldR2:Toggle({
    Name="Anti-Lag", Default=false,
    Callback=function(p)
        pcall(function() setfpscap(p and 0 or 60) end)
        local LT3=game:GetService("Lighting")
        if p then LT3.GlobalShadows=false; LT3.Brightness=2; for _,v in ipairs(workspace:GetDescendants()) do if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then pcall(function() v.Enabled=false end) end end
        else LT3.GlobalShadows=true end
    end
}, "AntiLag")
Opt.AntiLagFPSCap = WorldR2:Slider({ Name="FPS Cap", Default=0, Minimum=0, Maximum=360, Precision=0, Callback=function(v) pcall(function() setfpscap(v==0 and math.huge or v) end) end }, "AntiLagFPSCap")
WorldR2:Button({ Name="Boost FPS", Callback=function()
    pcall(function()
        for _,v in ipairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled=false end
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then v.Enabled=false end
        end
        LT.GlobalShadows=false; LT.Brightness=5
    end)
end})
WorldR3:Button({ Name="Copy Coordinates", Callback=function()
    local hrp=getHRP(); if not hrp then return end
    local p=hrp.Position; local str=string.format("%.2f, %.2f, %.2f",p.X,p.Y,p.Z); setclipboard(str)
end})
local nearbyConn=nil; local nearbyTracked={}; local _nearbyTimer=0
Tog.NearbyNotifier = WorldR3:Toggle({
    Name="Nearby Alert", Default=false,
    Callback=function(p)
        if nearbyConn then nearbyConn:Disconnect(); nearbyConn=nil end; nearbyTracked={}
        if not p then return end
        nearbyConn=RS.Heartbeat:Connect(function()
            local now=tick(); if now-_nearbyTimer<0.5 then return end; _nearbyTimer=now
            local myHRP=getHRP(); if not myHRP then return end
            local dist=Opt.NearbyDist and Opt.NearbyDist.Value or 500
            for _,plr in ipairs(PS:GetPlayers()) do
                if plr~=LP and plr.Character then
                    local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local mag=(myHRP.Position-hrp.Position).Magnitude; local id=plr.UserId
                        if mag<=dist and not nearbyTracked[id] then nearbyTracked[id]=true; notify(plr.Name.." is nearby ["..math.floor(mag).."m]",6)
                        elseif mag>dist and nearbyTracked[id] then nearbyTracked[id]=nil; notify(plr.Name.." left range",3) end
                    end
                end
            end
        end)
    end
}, "NearbyNotifier")
Opt.NearbyDist = WorldR3:Slider({ Name="Alert Range", Default=500, Minimum=0, Maximum=10000, Precision=0, Callback=function() end }, "NearbyDist")

onUnload(function()
    if _ambientConn then _ambientConn:Disconnect() end
    if noFogConn then noFogConn:Disconnect(); LT.FogStart=0; LT.FogEnd=100000 end
    if fbConn then fbConn:Disconnect(); LT.GlobalShadows=true; LT.Brightness=1 end
    if specConn then specConn:Disconnect() end
    if _cursorConn then _cursorConn:Disconnect() end
    if _cursorDot  then pcall(function() _cursorDot:Remove() end) end
    if _cursorRing then pcall(function() _cursorRing:Remove() end) end
    UIS.MouseIconEnabled=true
    for _,c in ipairs(freecamConns) do pcall(function() c:Disconnect() end) end
    Cam.FieldOfView=70; Cam.CameraType=Enum.CameraType.Custom; UIS.MouseBehavior=Enum.MouseBehavior.Default
end)


WorldR3:Divider()
WorldR3:Button({ Name="Rejoin", Callback=function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end })
WorldR3:Button({ Name="Server Hop", Callback=function()
    task.spawn(function()
        local ok,res=pcall(function() return HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")) end)
        if ok and res and res.data then
            for _,s in ipairs(res.data) do
                if s.id~=game.JobId and s.playing<s.maxPlayers then TP:TeleportToPlaceInstance(game.PlaceId,s.id,LP); return end
            end
        end
        notify("No server found",3)
    end)
end })
Opt.JobIdInput = WorldR3:Input({ Name="Job ID", Placeholder="paste job id", Callback=function() end }, "JobIdInput")
WorldR3:Button({ Name="Join by Job ID", Callback=function()
    local jid = Opt.JobIdInput and Opt.JobIdInput.Text or ""
    if jid == "" then notify("Enter a Job ID",2); return end
    TP:TeleportToPlaceInstance(game.PlaceId, jid, LP)
end })


-- ══════════════════════════════════════════════════════════════════════════════
-- STATS TAB
-- ══════════════════════════════════════════════════════════════════════════════
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
        local folder=workspace:FindFirstChild("Humanoids")
        if not folder then return nil end
        local ent=folder:FindFirstChild(name); if ent then return ent end
        for _,plr in ipairs(PS:GetPlayers()) do if plr.Name==name and plr.Character then local c=folder:FindFirstChild(plr.Character.Name); if c then return c end end end
        return nil
    end
    local function getLP_Entity()
        local folder=workspace:FindFirstChild("Humanoids")
        return folder and folder:FindFirstChild(LP.Name)
    end
    local function setLbl(lbl,txt) pcall(function() if lbl.UpdateName then lbl:UpdateName(txt) elseif lbl.SetText then lbl:SetText(txt) end end) end
    local function displayStats(name)
        for i=1,MAX_LABELS do setLbl(_attrLabels[i],""); pcall(function() _attrLabels[i]:SetVisibility(false) end) end
        setLbl(_statusLbl,"")
        if not name then return end
        local attrs={}
        -- Gather from all sources
        local function mergeAttrs(obj) if obj then pcall(function() for k,v in pairs(obj:GetAttributes()) do attrs[k]=v end end) end end
        local plr=PS:FindFirstChild(name)
        if plr then
            mergeAttrs(plr)
            local char=plr.Character; if char then mergeAttrs(char); local hum=char:FindFirstChildOfClass("Humanoid"); if hum then mergeAttrs(hum) end end
            local ls=plr:FindFirstChild("leaderstats"); if ls then for _,v in ipairs(ls:GetChildren()) do if v:IsA("ValueBase") then attrs[v.Name]=v.Value end end end
        end
        local ent=getEntityModel(name); mergeAttrs(ent)
        if ent then local hum2=ent:FindFirstChildOfClass("Humanoid"); if hum2 then mergeAttrs(hum2) end end
        if not next(attrs) then setLbl(_statusLbl,"No attributes found for "..name); return end
        setLbl(_statusLbl,"Showing: "..name)
        local i=1
        for _,k in ipairs(USEFUL_ATTRS) do
            if i>MAX_LABELS then break end
            local v=attrs[k]
            if v~=nil and tostring(v)~="" then setLbl(_attrLabels[i],"<font color=\"rgb(180,130,240)\">"..k.."</font>  "..tostring(v)); pcall(function() _attrLabels[i]:SetVisibility(true) end); i=i+1 end
        end
        local usefulSet={}; for _,k in ipairs(USEFUL_ATTRS) do usefulSet[k]=true end
        local extras={}; for k in pairs(attrs) do if not usefulSet[k] then table.insert(extras,k) end end
        table.sort(extras)
        for _,k in ipairs(extras) do
            if i>MAX_LABELS then break end
            local v=attrs[k]
            if v~=nil and tostring(v)~="" then setLbl(_attrLabels[i],"<font color=\"rgb(140,140,180)\">"..k.."</font>  "..tostring(v)); pcall(function() _attrLabels[i]:SetVisibility(true) end); i=i+1 end
        end
        if i==1 then setLbl(_statusLbl,"No attributes found for "..name) end
    end
    local _attrConns={}
    local function rebindAttrWatcher(name)
        for _,c in ipairs(_attrConns) do pcall(function() c:Disconnect() end) end; _attrConns={}
        if not name then return end
        local function watchObj(obj) if not obj then return end; pcall(function() table.insert(_attrConns,obj.AttributeChanged:Connect(function() displayStats(name) end)) end) end
        local plr=PS:FindFirstChild(name)
        if plr then watchObj(plr); local char=plr.Character; if char then watchObj(char); local hum=char:FindFirstChildOfClass("Humanoid"); if hum then watchObj(hum) end end end
        local ent=getEntityModel(name); watchObj(ent); if ent then local hum2=ent:FindFirstChildOfClass("Humanoid"); if hum2 then watchObj(hum2) end end
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


-- ══════════════════════════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ══════════════════════════════════════════════════════════════════════════════
SettL:Header({ Text="Interface" })
SettL:Button({ Name="Unload", Callback=function() Window:Unload() end })
SettL:Divider()
Tog.HideUI = SettL:Toggle({
    Name="Hide UI", Default=false,
    Callback=function(p)
        Window:SetState(not p)
    end
}, "HideUI")
SettL:Divider()
SettL:Slider({ Name="UI Transparency", Default=5, Minimum=0, Maximum=50, Precision=0,
    Callback=function(v) Window:SetTransparency(v / 100) end
})
SettL:Divider()

;(function()
    local _streamerConn=nil; local _streamerRespawnConn=nil
    local function hideChestNames()
        local di=workspace:FindFirstChild("DialogueInteractables"); if not di then return end
        for _,m in ipairs(di:GetChildren()) do
            pcall(function() m.ChestUI.Container.PlayerName.Visible=false end)
        end
    end
    Tog.StreamerMode = SettL:Toggle({
        Name="Streamer Mode", Default=false,
        Callback=function(p)
            if _streamerConn then _streamerConn:Disconnect(); _streamerConn=nil end
            if _streamerRespawnConn then _streamerRespawnConn:Disconnect(); _streamerRespawnConn=nil end
            local nameLabel=LP.PlayerGui:FindFirstChild("MainUI",true) and LP.PlayerGui.MainUI.HUDContainer.TopLeftDetailsContainer:FindFirstChild("PlayerName")
            if p then
                if nameLabel then nameLabel.Visible=false end
                hideChestNames()
                local di=workspace:FindFirstChild("DialogueInteractables")
                if di then
                    _streamerConn=di.DescendantAdded:Connect(function(d)
                        if d.Name=="PlayerName" then task.wait(); pcall(function() d.Visible=false end) end
                    end)
                end
                _streamerRespawnConn=LP.CharacterAdded:Connect(function(nc)
                    if nameLabel then nameLabel.Visible=false end
                end)
            else
                if nameLabel then nameLabel.Visible=true end
                local di=workspace:FindFirstChild("DialogueInteractables")
                if di then
                    for _,m in ipairs(di:GetChildren()) do
                        pcall(function() m.ChestUI.Container.PlayerName.Visible=true end)
                    end
                end
            end
        end
    }, "StreamerMode")
    onUnload(function()
        if _streamerConn then _streamerConn:Disconnect() end
        if _streamerRespawnConn then _streamerRespawnConn:Disconnect() end
    end)
end)()

SettL:Divider()
MacLib:SetFolder("ZeroHub/dokkodo")
Tabs.Settings:InsertConfigSection("Left")

local SettR2 = Tabs.Settings:Section({ Side="Right", Name="Theme", Image="palette" })

SettR:Header({ Text="Controls" })
SettR:Keybind({ Name="Menu Toggle", Default=Enum.KeyCode.F5,
    onBinded=function(k) Window:SetKeybind(k) end
}, "KbMenu")

SettR2:Header({ Text="Theme" })
SettR2:Colorpicker({ Name="Accent Color", Default=Color3.fromRGB(138,79,255), Alpha=0,
    Callback=function(c)
        MacLib:SetAccent(c)
    end
}, "ThemeAccent")
MacLib.Options["ThemeAccent"].ThemeOnly = true
SettR2:Colorpicker({ Name="Background", Default=Color3.fromRGB(12,12,12), Alpha=0,
    Callback=function(c)
        MacLib:SetScheme("BackgroundColor", c)
    end
}, "ThemeBG")
MacLib.Options["ThemeBG"].ThemeOnly = true
SettR2:Colorpicker({ Name="Main Color", Default=Color3.fromRGB(24,24,24), Alpha=0,
    Callback=function(c)
        MacLib:SetScheme("MainColor", c)
    end
}, "ThemeMain")
MacLib.Options["ThemeMain"].ThemeOnly = true
SettR2:Colorpicker({ Name="Outline Color", Default=Color3.fromRGB(45,45,45), Alpha=0,
    Callback=function(c)
        MacLib:SetScheme("OutlineColor", c)
    end
}, "ThemeOutline")
MacLib.Options["ThemeOutline"].ThemeOnly = true


Window:SetTitleUpdater(function(c)
    local r, g, b = math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255)
    local r2 = math.min(255, math.floor(r*1.6))
    local g2 = math.min(255, math.floor(g*1.6))
    local b2 = math.min(255, math.floor(b*1.6))
    local chars = {"Z","e","r","o"," ","H","u","b"}
    local result = ""
    for i, ch in ipairs(chars) do
        local t = (i-1)/(#chars-1)
        local cr = math.floor(r2 + (r-r2)*t)
        local cg = math.floor(g2 + (g-g2)*t)
        local cb = math.floor(b2 + (b-b2)*t)
        if ch == " " then result = result .. " "
        else result = result .. string.format('<font color="rgb(%d,%d,%d)">%s</font>', cr, cg, cb, ch) end
    end
    Window:UpdateTitle(result)
end)

Tabs.Game:Select()
MacLib:LoadAutoLoadConfig()
notify("Dokkodo loaded", 4)
