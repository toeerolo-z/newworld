
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- kill any previous instance before starting
if getgenv()._ZHUnload then pcall(getgenv()._ZHUnload); getgenv()._ZHUnload=nil end
pcall(function() local RS=game:GetService("RunService")
    for _,n in ipairs({"VVUFly","VVUSpeed","VVUTween","VVUMobTween","VVUChestTween","VVUServerESP"}) do
        RS:UnbindFromRenderStep(n)
    end
end)
local NetworkManager = nil
local Old = nil
pcall(function()
    NetworkManager = require(ReplicatedStorage.SharedModules.NetworkManager)
    Old = hookfunction(NetworkManager.FireServer, newcclosure(function(self, Name, ...)
        if Name == "ProcessDamage" then warn("blocked"); return end
        return Old(self, Name, ...)
    end))
end)

repeat task.wait() until game:IsLoaded()
task.wait(3)
-- wait for Requests to replicate before anything accesses it
ReplicatedStorage:WaitForChild("Requests", 30)

local RS  = game:GetService("RunService")
local PS  = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LT  = game:GetService("Lighting")
local HS  = game:GetService("HttpService")
local TP  = game:GetService("TeleportService")
local Cam = workspace.CurrentCamera
local LP  = PS.LocalPlayer

local function launchTP(placeId, jobId)
    local ok = pcall(function() game:GetService("ExperienceService"):LaunchExperience({placeId=placeId,gameInstanceId=jobId}) end)
    if not ok then pcall(function() TP:TeleportToPlaceInstance(placeId, jobId or game.JobId, LP) end) end
end
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
assert(MacLib, "[ZeroHub] MacLib returned nil — runtime error during load")

local Window = MacLib:Window({
    Title    = "<font color=\"rgb(178,120,255)\">Zero</font> <font color=\"rgb(138,79,255)\">Hub</font>",
    Subtitle = "VV Ultimatum  |  V.2.1",
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
        pcall(function() Window:Notify({ Title="VV Ultimatum", Description=msg, Lifetime=dur or 3 }) end)
    end)
end
local TabGroup = Window:TabGroup()
local Tabs = {}
Tabs.Game      = TabGroup:Tab({ Name="Main",       Image="swords"             })
Tabs.Character = TabGroup:Tab({ Name="Character",  Image="person-standing"    })
Tabs.AutoParry = TabGroup:Tab({ Name="Auto Parry", Image="shield-check"       })
Tabs.Visuals   = TabGroup:Tab({ Name="Visuals",    Image="scan-eye"           })
Tabs.World     = TabGroup:Tab({ Name="World",      Image="map"                })
Tabs.Nav       = TabGroup:Tab({ Name="Navigation", Image="navigation"         })
Tabs.Misc      = TabGroup:Tab({ Name="Misc",       Image="layers"             })
Tabs.Settings  = TabGroup:Tab({ Name="Settings",   Image="sliders-horizontal" })

local GameL   = Tabs.Game:Section({ Side="Left",  Name="Player Farm",    Image="users"             })
local GameL2  = Tabs.Game:Section({ Side="Left",  Name="Mob Farm",       Image="swords"            })
local GameL4  = Tabs.Game:Section({ Side="Left",  Name="Auto Sell",      Image="dollar-sign"       })
local GameL5  = Tabs.Game:Section({ Side="Left",  Name="Auto Store",     Image="archive"           })
local GameR   = Tabs.Game:Section({ Side="Right", Name="Farm Config",    Image="settings"          })
local GameR2  = Tabs.Game:Section({ Side="Right", Name="Auto Skill",     Image="zap"               })
local GameR3  = Tabs.Game:Section({ Side="Right", Name="Item Notifier",  Image="bell"              })
local GameR4  = Tabs.Game:Section({ Side="Right", Name="Quest Helper",   Image="map-pin"           })
local GameR5  = Tabs.Game:Section({ Side="Right", Name="Auto Raid",      Image="sword"             })
local GameR6  = Tabs.Game:Section({ Side="Right", Name="Gauntlet",       Image="trophy"            })
local CharL   = Tabs.Character:Section({ Side="Left",  Name="Movement",  Image="move"              })
local CharL2  = Tabs.Character:Section({ Side="Left",  Name="Morphs",    Image="user"              })
local CharR   = Tabs.Character:Section({ Side="Right", Name="Utility",   Image="wrench"            })
local CharR2  = Tabs.Character:Section({ Side="Right", Name="Enhancements", Image="sparkles"       })
local CharR3  = Tabs.Character:Section({ Side="Right", Name="Aimbot",    Image="crosshair"         })
local APL     = Tabs.AutoParry:Section({ Side="Left",  Name="Auto Parry", Image="shield-check"     })
local APL2    = Tabs.AutoParry:Section({ Side="Left",  Name="Face Lock",  Image="scan-face"        })
local APL3    = Tabs.AutoParry:Section({ Side="Left",  Name="Timing Builder", Image="clock"        })
local APR     = Tabs.AutoParry:Section({ Side="Right", Name="Community Timings", Image="globe"     })
local APR2    = Tabs.AutoParry:Section({ Side="Right", Name="Anim Logger", Image="list"            })
local APR3    = Tabs.AutoParry:Section({ Side="Right", Name="Whitelist",  Image="shield-check"     })
local VizL    = Tabs.Visuals:Section({ Side="Left",  Name="Player ESP",  Image="user"              })
local VizL2   = Tabs.Visuals:Section({ Side="Left",  Name="Mob ESP",     Image="swords"            })
local VizL3   = Tabs.Visuals:Section({ Side="Left",  Name="Chest ESP",   Image="package"           })
local VizR    = Tabs.Visuals:Section({ Side="Right", Name="ESP Config",  Image="settings"          })
local VizR2   = Tabs.Visuals:Section({ Side="Right", Name="NPC ESP",     Image="bot"               })
local VizR3   = Tabs.Visuals:Section({ Side="Right", Name="Portal ESP",  Image="circle-dot"        })
local VizR4   = Tabs.Visuals:Section({ Side="Right", Name="Marker ESP",  Image="map-pin"           })
local VizL4   = Tabs.Visuals:Section({ Side="Left",  Name="Quest ESP",   Image="map-pin"           })
local WorldL2 = Tabs.World:Section({ Side="Left",  Name="Camera",       Image="camera"            })
local WorldR  = Tabs.World:Section({ Side="Right", Name="Visual FX",    Image="sparkle"           })
local WorldR2 = Tabs.World:Section({ Side="Right", Name="FPS Boost",    Image="zap"               })
local WorldR3 = Tabs.World:Section({ Side="Right", Name="Tools",        Image="wrench"            })
local NavL    = Tabs.Nav:Section({ Side="Left",  Name="Teleport",       Image="navigation"        })
local NavL2   = Tabs.Nav:Section({ Side="Left",  Name="Game Teleports", Image="map-pin"           })
local NavL3   = Tabs.Nav:Section({ Side="Left",  Name="Chest Farm",     Image="package"           })
local NavR    = Tabs.Nav:Section({ Side="Right", Name="Attach",         Image="anchor"            })
local NavR2   = Tabs.Nav:Section({ Side="Right", Name="Attach Config",  Image="settings"          })
local MiscL4  = Tabs.Misc:Section({ Side="Left",  Name="Ownership",        Image="shield"       })
local MiscL5  = Tabs.Misc:Section({ Side="Left",  Name="Hogyoku Sniper",   Image="crosshair"    })
local MiscR   = Tabs.Misc:Section({ Side="Right", Name="Abilities",        Image="sparkles"     })
local MiscR2  = Tabs.Misc:Section({ Side="Right", Name="Anti Status",      Image="shield-check" })
local MiscR3  = Tabs.Misc:Section({ Side="Right", Name="Auto Hop",          Image="zap"          })
local SettL   = Tabs.Settings:Section({ Side="Left",  Name="Interface", Image="layout-dashboard"  })
local SettR   = Tabs.Settings:Section({ Side="Right", Name="Keybinds",  Image="keyboard"          })

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
    local _toggleFlight=ReplicatedStorage.Requests:FindFirstChild("ToggleFlight")
    _tweenVersion=_tweenVersion+1; local myVersion=_tweenVersion
    local function doLerp(from, to)
        if (to-from).Magnitude<1 then return true end
        if _toggleFlight then pcall(function() _toggleFlight:FireServer(true) end) end
        local done=false; local success=false; local tweenFrame=CFrame.new(from)
        RS:BindToRenderStep("VVUTween",Enum.RenderPriority.Input.Value,function(dt)
            if _tweenVersion~=myVersion then RS:UnbindFromRenderStep("VVUTween"); done=true; return end
            if _cancelTween then _cancelTween=false; releaseW(); RS:UnbindFromRenderStep("VVUTween"); done=true; return end
            if cancelCheck and cancelCheck() then releaseW(); RS:UnbindFromRenderStep("VVUTween"); done=true; return end
            local c=getChar(); if not c then RS:UnbindFromRenderStep("VVUTween"); done=true; return end
            local h=c:FindFirstChild("HumanoidRootPart"); if not h then RS:UnbindFromRenderStep("VVUTween"); done=true; return end
            local mv=to-tweenFrame.Position
            if mv.Magnitude<=1 then h.AssemblyLinearVelocity=Vector3.zero; h.CFrame=CFrame.new(to,to+(to-from).Unit); success=true; RS:UnbindFromRenderStep("VVUTween"); done=true; return end
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
    RS:BindToRenderStep("VVUChestTween",Enum.RenderPriority.Input.Value-1,function(dt)
        if _chestTweenVersion~=myVersion or (cancelCheck and cancelCheck()) then RS:UnbindFromRenderStep("VVUChestTween"); done=true; return end
        local h=getHRP(); if not h then RS:UnbindFromRenderStep("VVUChestTween"); done=true; return end
        local mv=target-tweenFrame.Position
        if mv.Magnitude<=1 then h.CFrame=cf; RS:UnbindFromRenderStep("VVUChestTween"); done=true; return end
        tweenFrame=tweenFrame+mv.Unit*S.tweenSpeed*dt; h.AssemblyLinearVelocity=Vector3.zero; h.CFrame=CFrame.new(tweenFrame.Position)
    end)
    while not done do task.wait() end
end
local _mobTweenVersion=0
local function tweenToMob(cf,cancelCheck)
    local hrp=getHRP(); if not hrp then return end; hrp.AssemblyLinearVelocity=Vector3.zero
    _mobTweenVersion=_mobTweenVersion+1; local myVersion=_mobTweenVersion
    local target=cf.Position; local tweenFrame=CFrame.new(hrp.Position); local done=false
    RS:BindToRenderStep("VVUMobTween",Enum.RenderPriority.Input.Value-2,function(dt)
        if _mobTweenVersion~=myVersion or (cancelCheck and cancelCheck()) then RS:UnbindFromRenderStep("VVUMobTween"); done=true; return end
        local h=getHRP(); if not h then RS:UnbindFromRenderStep("VVUMobTween"); done=true; return end
        local mv=target-tweenFrame.Position
        if mv.Magnitude<=1 then h.CFrame=cf; RS:UnbindFromRenderStep("VVUMobTween"); done=true; return end
        tweenFrame=tweenFrame+mv.Unit*S.tweenSpeed*dt; h.AssemblyLinearVelocity=Vector3.zero; h.CFrame=CFrame.new(tweenFrame.Position)
    end)
    while not done do task.wait() end
end

local function _getStatus() local c=getChar(); if not c then return end; return c:FindFirstChild("Status") end
local function _injectStatus(name) local s=_getStatus(); if not s then return end; if not s:FindFirstChild(name) then local f=Instance.new("Folder"); f.Name=name; f.Parent=s end end
local function _removeStatus(name) local s=_getStatus(); if not s then return end; local v=s:FindFirstChild(name); if v then v:Destroy() end end
local function _getRemote(name) local req=ReplicatedStorage:FindFirstChild("Requests"); return req and req:FindFirstChild(name) end

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


Tog.Fly = CharL:Toggle({
    Name="Fly", Default=false, Keybind=Enum.KeyCode.Y,
    Callback=function(p)
        if p then
            RS:BindToRenderStep("VVUFly",Enum.RenderPriority.Input.Value,function(dt)
                local c=getChar(); if not c then return end
                local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if not getgenv()._VVU_flyFrame then getgenv()._VVU_flyFrame=hrp.CFrame end
                local frame=getgenv()._VVU_flyFrame; local cf=Cam.CFrame; local mv=Vector3.zero
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
                getgenv()._VVU_flyFrame=frame; hrp.AssemblyLinearVelocity=Vector3.zero; hrp.CFrame=frame
            end)
        else RS:UnbindFromRenderStep("VVUFly"); getgenv()._VVU_flyFrame=nil end
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
        if p then RS:BindToRenderStep("VVUSpeed",Enum.RenderPriority.Input.Value,function(dt)
            local c=getChar(); if not c then return end; local hum=c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then return end
            local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            if hum.MoveDirection.Magnitude>0 then hrp.CFrame=hrp.CFrame+hum.MoveDirection*S.speed*dt end
        end) else RS:UnbindFromRenderStep("VVUSpeed") end
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
local _autoRespLoop=false
Tog.AutoRespawnLoop = CharR:Toggle({ Name="Auto Respawn", Default=false, Callback=function(p) _autoRespLoop=p; if not p then return end; task.spawn(function() while _autoRespLoop do pcall(function() local btn=LP.PlayerGui.MainUI.HUDContainer.DeathScreen.Options:GetChildren()[3].TextButton; firesignal(btn.MouseButton1Click) end); task.wait(0.1) end end) end }, "AutoRespawnLoop")
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
CharR2:Label({ Text="⚠ RAKNET NEEDED TURN IT ON IN YOUR EXECUTOR SETTINGS ⚠" })
CharR2:Label({ Text="⚠ AFTER ENABLING IT WILL RESET YOU ⚠" })
do
    local RakNet = raknet or rnet
    local Hooked = false
    local function Hook(Packet)
        if Packet.PacketId == 0x1B then
            local Buffer = Packet.AsBuffer
            buffer.writeu32(Buffer, 1, 0xFFFFFF)
            Packet:SetData(Buffer)
        end
    end
    Tog.RakNetDesync = CharR2:Toggle({
        Name="Invisibility", Default=false, Keybind=Enum.KeyCode.F,
        Callback=function(p)
            if not RakNet then notify("RakNet not found", 3); Tog.RakNetDesync:UpdateState(false); return end
            if p and not Hooked then
                RakNet.add_send_hook(Hook)
                Hooked = true
                task.delay(1, function()
                    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Health = 0 end
                end)
            elseif not p and Hooked then
                RakNet.remove_send_hook(Hook)
                Hooked = false
            end
        end
    }, "RakNetDesync")
    onUnload(function() if Hooked and RakNet then pcall(function() RakNet.remove_send_hook(Hook) end); Hooked=false end end)
end
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
    RS:UnbindFromRenderStep("VVUSpeed")
    RS:UnbindFromRenderStep("VVUFly")
    RS:UnbindFromRenderStep("VVUTween")
    RS:UnbindFromRenderStep("VVUChestTween")
    RS:UnbindFromRenderStep("VVUMobTween")
    getgenv()._VVU_flyFrame=nil

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

    _autoRespLoop=false

    if getgenv()._ZHCrosshair then for _,d in ipairs(getgenv()._ZHCrosshair) do pcall(function() d:Remove() end) end; getgenv()._ZHCrosshair=nil end
end)


local farmState = { plrs=false, plrTarget="", mobs=false, mobTargets={}, croc=false }
local _farmMode="Behind"; local _farmOffX=0; local _farmOffY=0; local _farmOffZ=6.5
local function _calcFarmPos(rp)
    local mp=rp.Position
    local flatLook=Vector3.new(rp.CFrame.LookVector.X,0,rp.CFrame.LookVector.Z).Unit
    local flatRight=Vector3.new(rp.CFrame.RightVector.X,0,rp.CFrame.RightVector.Z).Unit
    local base
    if     _farmMode=="Above"    then base=mp+Vector3.new(0,_farmOffZ,0)
    elseif _farmMode=="Below"    then base=mp+Vector3.new(0,-_farmOffZ,0)
    elseif _farmMode=="In Front" then base=mp+flatLook*_farmOffZ
    else                              base=mp-flatLook*_farmOffZ end
    return base+flatRight*_farmOffX+Vector3.new(0,_farmOffY,0)
end
local farmConns={}
getgenv()._VVU_autoM1=false; getgenv()._VVU_autoCrit=false; getgenv()._VVU_autoEquip=false
getgenv()._VVU_autoRes=false; getgenv()._VVU_autoGrip=false; getgenv()._VVU_combatLoopsStarted=false

-- re-enable combat after respawn if farm is active
LP.CharacterAdded:Connect(function()
    task.wait(2)
    if farmState.mobs or farmState.plrs or farmState.croc then
        enableFarmCombat()
    end
end)
if not getgenv()._VVU_combatLoopsStarted then
    getgenv()._VVU_combatLoopsStarted=true
    local RS2=game:GetService("ReplicatedStorage")
    task.spawn(function() while true do task.wait(0.15); if getgenv()._VVU_autoM1 then pcall(function() RS2.Requests.Combat:FireServer("LightAttack",true,false) end) end end end)
    task.spawn(function() while true do task.wait(0.15); if getgenv()._VVU_autoCrit then pcall(function() RS2.Requests.Combat:FireServer("HeavyAttack",true) end) end end end)
    task.spawn(function()
        while true do task.wait(0.5)
            if getgenv()._VVU_autoGrip then pcall(function()
                local ents=workspace:FindFirstChild("Living"); if not ents then return end
                for _,mob in ipairs(ents:GetChildren()) do
                    if PS:GetPlayerFromCharacter(mob) or mob==LP.Character then continue end
                    local h=mob:FindFirstChildOfClass("Humanoid"); if h and h.Health>0 then
                        RS2.Requests.Grip:FireServer(mob); break
                    end
                end
            end) end
        end
    end)
    task.spawn(function()
        while true do task.wait(0.5)
            if getgenv()._VVU_autoRes then pcall(function()
                local living=workspace:FindFirstChild("Living"); local myModel=living and living:FindFirstChild(LP.Name)
                local status=myModel and myModel:FindFirstChild("Status"); local partialRes=status and status:FindFirstChild("PartialResActive")
                if not (partialRes and partialRes.Value) then RS2.Requests.FastWeaponRelease:FireServer(nil,nil) end
            end) end
        end
    end)
    task.spawn(function()
        while true do task.wait(0.5)
            if getgenv()._VVU_autoEquip then pcall(function()
                local living=workspace:FindFirstChild("Living"); local myModel=living and living:FindFirstChild(LP.Name)
                local status=myModel and myModel:FindFirstChild("Status"); local we=status and status:FindFirstChild("WeaponEquipped")
                if not (we and we.Value) then RS2.Requests.Combat:FireServer("ToggleWeapon") end
            end) end
        end
    end)
end
local function enableFarmCombat()
    getgenv()._VVU_autoEquip=true; getgenv()._VVU_autoM1=true; getgenv()._VVU_autoCrit=true; getgenv()._VVU_autoGrip=true
end
local function disableFarmCombat()
    getgenv()._VVU_autoEquip=false; getgenv()._VVU_autoM1=false; getgenv()._VVU_autoCrit=false; getgenv()._VVU_autoGrip=false
end
local _farmSkillFire=nil

local function getMobType(mob)
    if mob:GetAttribute("Team") == "BossGauntlet" then return "Gauntlet Boss" end
    local ht=mob:GetAttribute("HollowType"); if ht and ht~="" then return tostring(ht) end
    local name = mob.Name:match("^(.-)_[^_]+$") or mob.Name
    if name == "" then return "Unknown NPC" end
    return name
end

local function makeFarmLoop(targetFn, activeKey, killWait)
    local lastTgt=nil; local killCooldown=0; killWait=killWait or 3
    local inPosition=false; local tweening=false
    return RS.Heartbeat:Connect(function()
        if not farmState[activeKey] then return end
        local c=getChar(); if not c then lastTgt=nil; return end
        local hum=c:FindFirstChildOfClass("Humanoid")
        if not hum or not hum.RootPart then lastTgt=nil; return end
        if hum.Health<=0 then lastTgt=nil; killCooldown=0; inPosition=false; tweening=false; disableFarmCombat(); return end
        local hrp=hum.RootPart; hum.Health=hum.MaxHealth
        local tHum=lastTgt and lastTgt:FindFirstChildOfClass("Humanoid")
        local mobDied=lastTgt and (not lastTgt.Parent or not tHum or tHum.Health<=0)
        if not lastTgt or mobDied then
            if mobDied and killCooldown==0 then killCooldown=tick() end
            if killCooldown>0 and tick()-killCooldown<killWait then disableFarmCombat(); return end
            killCooldown=0; lastTgt=targetFn(); inPosition=false; tweening=false
        end
        if not lastTgt then inPosition=false; tweening=false; disableFarmCombat(); pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",nil) end end); return end
        local rp=lastTgt:FindFirstChild("HumanoidRootPart"); if not rp then return end
        if _farmSkillFire then _farmSkillFire() end
        local targetPos=_calcFarmPos(rp)
        local dist=(hrp.Position-targetPos).Magnitude
        local offsetDist=(_farmOffX^2+_farmOffY^2+_farmOffZ^2)^0.5
        if dist>offsetDist+8 then
            inPosition=false; disableFarmCombat()
            if not tweening then
                tweening=true
                task.spawn(function()
                    tweenTo(CFrame.lookAt(_calcFarmPos(rp),rp.Position),function() return not farmState[activeKey] end)
                    tweening=false
                end)
            end
        else
            tweening=false
            if not inPosition then
                inPosition=true
                pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
            end
            enableFarmCombat()
            hrp.AssemblyLinearVelocity=Vector3.zero
            hrp.AssemblyAngularVelocity=Vector3.zero
            hrp.CFrame=CFrame.lookAt(targetPos,rp.Position)
        end
    end)
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
        local d=(r.Position-hrp.Position).Magnitude; if d<bestD then best=c; bestD=d end
    end
    return best
end
local function nearestMob()
    local hrp=getHRP(); if not hrp then return end
    local ents=workspace:FindFirstChild("Living"); if not ents then return end
    local best,bestD=nil,math.huge
    local useFilter=next(farmState.mobTargets)~=nil and not farmState.mobTargets["Nearest Mob"]
    for _,mob in ipairs(ents:GetChildren()) do
        if mob==LP.Character then continue end
        if PS:GetPlayerFromCharacter(mob) then continue end
        if mob:GetAttribute("TrainingDummy") then continue end
        local r=mob:FindFirstChild("HumanoidRootPart"); local h=mob:FindFirstChildOfClass("Humanoid")
        if not (r and h and h.Health>0) then continue end
        if useFilter and not farmState.mobTargets[getMobType(mob)] then continue end
        local d=(r.Position-hrp.Position).Magnitude; if d<bestD then best=mob; bestD=d end
    end
    return best
end


;(function()
    local function buildPlrList()
        local list={"Any (Closest)"}
        for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(list,plr.Name) end end
        return list
    end
    Opt.PlrSelect = GameL:Dropdown({
        Name="Target Player", Search=true, Options=buildPlrList(), Default=1, Multi=false,
        Callback=function(v)
            local sel=type(v)=="table" and next(v) or v
            farmState.plrTarget=tostring(sel or "")
        end
    }, "PlrSelect")
    Opt.PlrSelect.IgnoreConfig = true
    GameL:Button({ Name="Refresh Players", Callback=function()
        pcall(function() Opt.PlrSelect:ClearOptions(); Opt.PlrSelect:InsertOptions(buildPlrList()) end)
    end})
end)()
Tog.AutoFarmPlrs = GameL:Toggle({
    Name="Farm Players", Default=false, Keybind=Enum.KeyCode.Unknown,
    Callback=function(p)
        farmState.plrs=p
        if farmConns.plrs then farmConns.plrs:Disconnect(); farmConns.plrs=nil end
        if p then farmConns.plrs=makeFarmLoop(nearestPlayer,"plrs") else disableFarmCombat() end
    end
}, "AutoFarmPlrs")

local function scanMobList()
    local list={"Nearest Mob"}; local seen={}
    local ents=workspace:FindFirstChild("Living")
    if ents then
        for _,mob in ipairs(ents:GetChildren()) do
            if PS:GetPlayerFromCharacter(mob) or mob==LP.Character then continue end
            if mob:GetAttribute("TrainingDummy") then continue end
            local h=mob:FindFirstChildOfClass("Humanoid"); if not (h and h.Health>0) then continue end
            local t=getMobType(mob); if not seen[t] then table.insert(list,t); seen[t]=true end
        end
        table.sort(list, function(a,b)
            if a=="Nearest Mob" then return true end; if b=="Nearest Mob" then return false end; return a<b
        end)
    end
    return list
end
Opt.MobSelect = GameL2:Dropdown({
    Name="Target Mob", Search=true, Options=scanMobList(), Default={"Nearest Mob"}, Multi=true,
    Callback=function(v) farmState.mobTargets=(type(v)=="table") and v or {} end
}, "MobSelect")
GameL2:Button({ Name="Refresh Mobs", Callback=function()
    pcall(function() Opt.MobSelect:ClearOptions(); Opt.MobSelect:InsertOptions(scanMobList()) end)
end})
Tog.AutoFarmMobs = GameL2:Toggle({
    Name="Mob Farm", Default=false, Keybind=Enum.KeyCode.Unknown,
    Callback=function(p)
        farmState.mobs=p
        if farmConns.mobs then farmConns.mobs:Disconnect(); farmConns.mobs=nil end
        if not p then disableFarmCombat(); return end
        local lastTgt,killCooldown,tweening,lastMobType,mobInPosition=nil,0,false,nil,false
        farmConns.mobs=RS.Heartbeat:Connect(function()
            if not farmState.mobs then return end
            local c=getChar(); if not c then lastTgt=nil; tweening=false; return end
            local hum=c:FindFirstChildOfClass("Humanoid"); local hrp=hum and hum.RootPart
            if not hum or not hrp then lastTgt=nil; tweening=false; return end
            if hum.Health<=0 then lastTgt=nil; killCooldown=0; tweening=false; mobInPosition=false; disableFarmCombat(); return end
            local tHum=lastTgt and lastTgt:FindFirstChildOfClass("Humanoid")
            local mobDied=lastTgt and (not lastTgt.Parent or not tHum or tHum.Health<=0)
            if not lastTgt or mobDied then
                if mobDied then

                    if lastTgt then lastMobType=getMobType(lastTgt) end
                    if killCooldown==0 then killCooldown=tick() end
                end
                if killCooldown>0 and tick()-killCooldown<4 then
                    disableFarmCombat()
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    return
                end
                killCooldown=0

                local nextTgt = nil
                if lastMobType then
                    local ents=workspace:FindFirstChild("Living")
                    if ents then
                        local hrpPos=hrp.Position; local best,bestD=nil,math.huge
                        for _,mob in ipairs(ents:GetChildren()) do
                            if mob==LP.Character or PS:GetPlayerFromCharacter(mob) then continue end
                            if mob:GetAttribute("TrainingDummy") then continue end
                            local r=mob:FindFirstChild("HumanoidRootPart"); local h=mob:FindFirstChildOfClass("Humanoid")
                            if not (r and h and h.Health>0) then continue end
                            if getMobType(mob)==lastMobType then
                                local d=(r.Position-hrpPos).Magnitude
                                if d<bestD then best=mob; bestD=d end
                            end
                        end
                        nextTgt=best
                    end
                end
                lastTgt = nextTgt or nearestMob()
                tweening=false; mobInPosition=false
            end
            if not lastTgt then tweening=false; disableFarmCombat(); return end
            local rp=lastTgt:FindFirstChild("HumanoidRootPart"); if not rp then return end
            if _farmSkillFire then _farmSkillFire() end
            local mp=rp.Position
            local flatLook=Vector3.new(rp.CFrame.LookVector.X,0,rp.CFrame.LookVector.Z).Unit
            local flatRight=Vector3.new(rp.CFrame.RightVector.X,0,rp.CFrame.RightVector.Z).Unit
            local base
            if     _farmMode=="Above"    then base=mp+Vector3.new(0,_farmOffZ,0)
            elseif _farmMode=="Below"    then base=mp+Vector3.new(0,-_farmOffZ,0)
            elseif _farmMode=="In Front" then base=mp+flatLook*_farmOffZ
            else                              base=mp-flatLook*_farmOffZ end
            local targetPos=CFrame.new(base+flatRight*_farmOffX+Vector3.new(0,_farmOffY,0))
            local dist=(hrp.Position-targetPos.Position).Magnitude
            local offsetDist=(_farmOffX^2+_farmOffY^2+_farmOffZ^2)^0.5
            local tweenThresh=offsetDist+8
            if dist>tweenThresh then
                disableFarmCombat(); mobInPosition=false
                if not tweening then
                    tweening=true; local snapMob=rp.Position
                    task.spawn(function()
                        pcall(function() tweenToMob(targetPos,function() return not farmState.mobs or (rp.Position-snapMob).Magnitude>3 end) end)
                        tweening=false
                    end)
                end
            else
                tweening=false
                if not mobInPosition then mobInPosition=true end
                pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
                enableFarmCombat()
                hrp.AssemblyLinearVelocity=Vector3.zero
                hrp.AssemblyAngularVelocity=Vector3.zero
                hrp.CFrame=CFrame.lookAt(targetPos.Position,rp.Position)
            end
        end)
    end
}, "AutoFarmMobs")
Opt.TweenSpeed = GameL2:Slider({ Name="Tween Speed", Default=100, Minimum=10, Maximum=5000, Precision=0, Callback=function(v) S.tweenSpeed=v end }, "TweenSpeed")

-- ═══ GAUNTLET ═══
do
    local _gauntletRunning = false
    local _gauntletConn = nil
    local NetworkManager = require(game.ReplicatedStorage.SharedModules.NetworkManager)

    GameR6:Label({ Text="Must be in Fort Adams" })

    Opt.GauntletSelect = GameR6:Dropdown({
        Name="Gauntlet", Options={"4 - The Terrible","1 - Dangerous Wanderer","2 - Predator Chain","3 - Unparalleled Strength","5 - The Other Side"},
        Default=1, Multi=false, Callback=function() end
    }, "GauntletSelect")

    Tog.AutoGauntlet = GameR6:Toggle({
        Name="Auto Gauntlet Farm", Default=false,
        Callback=function(p)
            _gauntletRunning = p
            if _gauntletConn then _gauntletConn:Disconnect(); _gauntletConn = nil end
            if not p then return end
            local sel = Opt.GauntletSelect and Opt.GauntletSelect.Value or "4 - The Terrible"
            local id = tonumber(tostring(sel):match("^(%d+)")) or 4
            -- Tween to gauntlet area first
            local spawnFolder = workspace.Debris.GauntletSpawns:FindFirstChild("Albrecht")
            if spawnFolder then
                local sp = spawnFolder:FindFirstChild("1")
                if sp then
                    pcall(function() tweenToMob(CFrame.new(sp.Position + Vector3.new(0, 5, 0)), function() return not _gauntletRunning end) end)
                end
            end
            task.wait(1)
            pcall(function() NetworkManager:FireServer("StartGauntlet", id) end)
            task.wait(2)
            pcall(function() Opt.MobSelect:ClearOptions(); Opt.MobSelect:InsertOptions(scanMobList()) end)
            farmState.mobTargets = {["Gauntlet Boss"] = true}
            if not farmState.mobs then
                farmState.mobs = true
                if Tog.AutoFarmMobs then Tog.AutoFarmMobs:UpdateState(true) end
            end
            notify("Gauntlet " .. id .. " started")
            _gauntletConn = RS.Heartbeat:Connect(function()
                if not _gauntletRunning then return end
                local ents = workspace:FindFirstChild("Living")
                if not ents then return end
                local hasGauntletMob = false
                for _, mob in ipairs(ents:GetChildren()) do
                    if mob:GetAttribute("Team") == "BossGauntlet" then
                        hasGauntletMob = true
                        -- Auto grip: check if mob is knocked via Status.Knocked value
                        local status = mob:FindFirstChild("Status")
                        if status then
                            local knockedVal = status:FindFirstChild("Knocked")
                            if knockedVal and knockedVal:IsA("NumberValue") and knockedVal.Value > 0 then
                                pcall(function() game.ReplicatedStorage.Requests.Grip:FireServer(mob.Name) end)
                            end
                        end
                        break
                    end
                end
                if not hasGauntletMob then
                    task.wait(3)
                    pcall(function()
                        -- Tween back to gauntlet area
                        local spawnFolder = workspace.Debris.GauntletSpawns:FindFirstChild("Albrecht")
                        if spawnFolder then
                            local sp = spawnFolder:FindFirstChild("1")
                            if sp then pcall(function() tweenToMob(CFrame.new(sp.Position + Vector3.new(0, 5, 0)), function() return not _gauntletRunning end) end) end
                        end
                        task.wait(1)
                        NetworkManager:FireServer("StartGauntlet", id)
                        task.wait(2)
                        pcall(function() Opt.MobSelect:ClearOptions(); Opt.MobSelect:InsertOptions(scanMobList()) end)
                    end)
                end
            end)
        end
    }, "AutoGauntlet")

    -- Standalone auto grip toggle for any knocked mob
    Tog.AutoGrip = GameR6:Toggle({
        Name="Auto Grip", Default=false,
        Callback=function(p)
            if Connections["AutoGrip"] then Connections["AutoGrip"]:Disconnect(); Connections["AutoGrip"]=nil end
            if not p then return end
            Connections["AutoGrip"] = RS.Heartbeat:Connect(function()
                local ents = workspace:FindFirstChild("Living"); if not ents then return end
                for _, mob in ipairs(ents:GetChildren()) do
                    if PS:GetPlayerFromCharacter(mob) or mob:GetAttribute("TrainingDummy") then continue end
                    local status = mob:FindFirstChild("Status")
                    if status then
                        local knockedVal = status:FindFirstChild("Knocked")
                        if knockedVal and knockedVal:IsA("NumberValue") and knockedVal.Value > 0 then
                            pcall(function() game.ReplicatedStorage.Requests.Grip:FireServer(mob.Name) end)
                        end
                    end
                end
            end)
        end
    }, "AutoGrip")

    onUnload(function() _gauntletRunning=false; if _gauntletConn then _gauntletConn:Disconnect() end end)
end

;(function()
    local _bossSelected={}
    Opt.BossFarmSelect = GameL2:Dropdown({
        Name="Boss", Search=true, Options={"Crocodile King","Argus","Lord Nivis","Nix","Shamballa","Giant Dragonfly","Frigus","The Parasite","Securis","Mammoth Hollow","Calamitas"},
        Default=nil, Multi=true, Callback=function(v) _bossSelected=type(v)=="table" and v or {} end
    }, "BossFarmSelect")
    local _bossRunning=false; local _bossTweening=false
    local function stopBossFarm()
        _bossRunning=false; _bossTweening=false
        farmState.croc=false; if farmConns.croc then farmConns.croc:Disconnect(); farmConns.croc=nil end
        disableFarmCombat()
    end
    LP.CharacterAdded:Connect(function() task.wait(1); _bossTweening=false end)
    -- Respawn handler: waits for a NEW living character (not the dead body)
    local function waitForRespawn()
        local oldChar=getChar()
        local newChar=nil
        local conn; conn=LP.CharacterAdded:Connect(function(c) newChar=c end)
        local t0=tick()
        while not newChar and tick()-t0<30 do task.wait(0.2) end
        conn:Disconnect()
        if not newChar then newChar=getChar() end
        if newChar then
            local t1=tick()
            while tick()-t1<10 do
                local hum=newChar:FindFirstChildOfClass("Humanoid")
                local hrp=newChar:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health>0 then break end
                task.wait(0.2)
            end
        end
        task.wait(1)
    end
    local _bossConfigs={
        ["Crocodile King"]={find=function() return workspace.Living and workspace.Living:FindFirstChild("The Crocodile King") end, x=0,y=20.4,z=6.5},
        ["Argus"]          ={find=function() return workspace.Living and workspace.Living:FindFirstChild("Argus") end,           x=4.5,y=11.8,z=6.5},
        ["Lord Nivis"]     ={find=function() return workspace.Living and workspace.Living:FindFirstChild("Lord Nivis") end,      x=0,y=10.6,z=6.5},
        ["Giant Dragonfly"]={find=function() return workspace.Living and workspace.Living:FindFirstChild("Giant Dragonfly") end, x=0,y=14.3,z=6.7},
        ["Frigus"]         ={find=function() return workspace.Living and workspace.Living:FindFirstChild("Frigus") end,          x=-0.2,y=7,z=8.1},
        ["The Parasite"]   ={find=function() return workspace.Living and workspace.Living:FindFirstChild("The Parasite") end,    x=0,y=0,z=6.5},
        ["Securis"]        ={find=function() return workspace.Living and workspace.Living:FindFirstChild("Securis") end,         x=0,y=0,z=6.5},
        ["Mammoth Hollow"] ={find=function() return workspace.Living and workspace.Living:FindFirstChild("Mammoth Hollow") end,  x=14.3,y=50,z=45.8},
        ["Junichiro"]      ={find=function() return workspace.Living and workspace.Living:FindFirstChild("Junichiro") end,       x=0,y=0,z=6.5},
    }
    local function startMultiBossLoop(names)
        local _argusGoneSince=nil; local _argusParked=false
        task.spawn(function()
            while _bossRunning do
                local c=getChar(); local hum=c and c:FindFirstChildOfClass("Humanoid"); local hrp=hum and hum.RootPart
                if not (c and hum and hrp) then task.wait(0.1); continue end
                if hum.Health<=0 then disableFarmCombat(); waitForRespawn(); continue end
                
                local target,offX,offY,offZ
                for _,name in ipairs(names) do
                    local cfg=_bossConfigs[name]; if not cfg then continue end
                    local t=cfg.find(); if not t then continue end
                    local bHum=t:FindFirstChildOfClass("Humanoid")
                    if bHum and bHum.Health>0 then target=t; offX=cfg.x; offY=cfg.y; offZ=cfg.z; break end
                end
                
                if not target then
                    disableFarmCombat(); _bossTweening=false
                    -- Argus spawn-park: if Argus is selected but not spawned, tween to spawn after 5s
                    local argusSelected=false
                    for _,n in ipairs(names) do if n=="Argus" then argusSelected=true; break end end
                    if argusSelected then
                        if not _argusGoneSince then _argusGoneSince=tick(); _argusParked=false end
                        if tick()-_argusGoneSince>=2 and not _argusParked then
                            _argusParked=true
                            local parkPos=CFrame.new(-1913.26025390625, 536.9530639648438, -2540.353759765625)
                            task.spawn(function()
                                pcall(function() tweenToMob(parkPos, function()
                                    if not _bossRunning then return true end
                                    if workspace.Living and workspace.Living:FindFirstChild("Argus") then return true end
                                    return false
                                end) end)
                            end)
                        end
                    else
                        _argusGoneSince=nil; _argusParked=false
                    end
                    task.wait(0.1); continue
                end
                _argusGoneSince=nil; _argusParked=false
                
                local rp=target:FindFirstChild("HumanoidRootPart"); if not rp then task.wait(0.1); continue end
                local mp=rp.Position
                local flatLook=Vector3.new(rp.CFrame.LookVector.X,0,rp.CFrame.LookVector.Z).Unit
                local flatRight=Vector3.new(rp.CFrame.RightVector.X,0,rp.CFrame.RightVector.Z).Unit
                local targetPos=CFrame.new(mp - flatLook*offZ + flatRight*offX + Vector3.new(0,offY,0))
                local dist=(hrp.Position-targetPos.Position).Magnitude
                local bossOffDist=(offX^2+offY^2+offZ^2)^0.5
                
                if dist>bossOffDist+8 then
                    disableFarmCombat()
                    if not _bossTweening then
                        _bossTweening=true
                        task.spawn(function() pcall(function() tweenToMob(targetPos,function() return not _bossRunning end) end); _bossTweening=false end)
                    end
                else
                    _bossTweening=false; enableFarmCombat()
                    hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                    pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
                    hrp.CFrame=CFrame.lookAt(targetPos.Position,rp.Position)
                end
                task.wait()
            end
        end)
    end
    local _DODGE_ANIMS={
        ["rbxassetid://17838591203"]=2.5,["rbxassetid://17838591987"]=2.5,
        ["rbxassetid://17838592800"]=2.5,["rbxassetid://17838593550"]=2.5,
    }
    Tog.BossFarm = GameL2:Toggle({
        Name="Boss Farm", Default=false, Keybind=Enum.KeyCode.Unknown,
        Callback=function(p)
            stopBossFarm()
            if not p then return end
            _bossRunning=true
            local names={}; for name,on in pairs(_bossSelected) do if on then table.insert(names,name) end end
            if #names==0 then notify("Select a boss first",3); _bossRunning=false; return end
            local hasCal=_bossSelected["Calamitas"]; local hasNix=_bossSelected["Nix"]; local hasGiantDragonfly=_bossSelected["Giant Dragonfly"]; local nonSpecial={}
            for _,n in ipairs(names) do if n~="Calamitas" and n~="Nix" and n~="Giant Dragonfly" and n~="Lord Nivis" then table.insert(nonSpecial,n) end end
            if #nonSpecial>0 then startMultiBossLoop(nonSpecial) end
            if hasNix then
                task.spawn(function()
                    local vim=game:GetService("VirtualInputManager")
                    local function hasShard()
                        return LP.Backpack:FindFirstChild("Frostvein Shard")
                            or (LP.Character and LP.Character:FindFirstChild("Frostvein Shard"))
                    end
                    local nixHealCF=CFrame.new(-2197.20751953125,497.1107177734375,1397.9189453125)
                    local spawnCF=CFrame.new(-2410.928466796875,266.1025085449219,992.0736694335938)

                    while _bossRunning do
                        -- Phase 1: farm BearHollow/PantherHollow until shard
                        if not hasShard() then
                            while _bossRunning and not hasShard() do
                                local living=workspace:FindFirstChild("Living")
                                if living and living:FindFirstChild("Nix") then break end
                                local c=getChar(); local hum=c and c:FindFirstChildOfClass("Humanoid"); local hrp=hum and hum.RootPart
                                if not (c and hum and hrp) then task.wait(0.1); continue end
                                if hum.Health<=0 then disableFarmCombat(); waitForRespawn(); continue end
                                local target,bestD=nil,math.huge
                                if living then
                                    for _,mob in ipairs(living:GetChildren()) do
                                        if PS:GetPlayerFromCharacter(mob) then continue end
                                        if mob:GetAttribute("HollowType")~="BearHollow" then continue end
                                        local r=mob:FindFirstChild("HumanoidRootPart"); local h=mob:FindFirstChildOfClass("Humanoid")
                                        if not (r and h and h.Health>0) then continue end
                                        local d=(r.Position-hrp.Position).Magnitude
                                        if d<bestD then target=mob; bestD=d end
                                    end
                                    if not target then
                                        for _,mob in ipairs(living:GetChildren()) do
                                            if PS:GetPlayerFromCharacter(mob) then continue end
                                            if mob:GetAttribute("HollowType")~="PantherHollow" then continue end
                                            local r=mob:FindFirstChild("HumanoidRootPart"); local h=mob:FindFirstChildOfClass("Humanoid")
                                            if not (r and h and h.Health>0) then continue end
                                            local d=(r.Position-hrp.Position).Magnitude
                                            if d<bestD then target=mob; bestD=d end
                                        end
                                    end
                                end
                                if not target then disableFarmCombat(); task.wait(0.5); continue end
                                local rp=target:FindFirstChild("HumanoidRootPart"); if not rp then task.wait(0.1); continue end
                                local targetCF=rp.CFrame*CFrame.new(0,0,4)
                                local dist=(hrp.Position-targetCF.Position).Magnitude
                                if dist>10 then
                                    disableFarmCombat()
                                    if not _bossTweening then
                                        _bossTweening=true
                                        task.spawn(function()
                                            pcall(function() tweenToMob(targetCF,function() return not _bossRunning or hasShard() end) end)
                                            _bossTweening=false
                                        end)
                                    end
                                else
                                    _bossTweening=false; enableFarmCombat()
                                    hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                                    pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
                                    hrp.CFrame=CFrame.lookAt(targetCF.Position,rp.Position)
                                end
                                task.wait()
                            end
                        end
                        if not _bossRunning then break end

                        -- Phase 2+3: tween to spawn, equip shard, spam T until Nix spawns
                        local living=workspace:FindFirstChild("Living")
                        if not (living and living:FindFirstChild("Nix")) then
                            disableFarmCombat(); _bossTweening=false
                            pcall(function() tweenToMob(spawnCF,function() return not _bossRunning end) end)
                            if not _bossRunning then break end
                            local eHum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                            if eHum then
                                for _=1,5 do
                                    if LP.Character and LP.Character:FindFirstChild("Frostvein Shard") then break end
                                    local shard=LP.Backpack:FindFirstChild("Frostvein Shard")
                                    if shard then pcall(function() eHum:EquipTool(shard) end) end
                                    task.wait(0.3)
                                end
                            end
                            -- keep spamming T until Nix spawns, tween back if drifted
                            while _bossRunning do
                                local l=workspace:FindFirstChild("Living")
                                if l and l:FindFirstChild("Nix") then break end
                                local h=getHRP()
                                if h and (h.Position-spawnCF.Position).Magnitude>5 then
                                    pcall(function() tweenToMob(spawnCF,function() return not _bossRunning or (workspace:FindFirstChild("Living") and workspace.Living:FindFirstChild("Nix")) end) end)
                                end
                                pcall(function() vim:SendKeyEvent(true,Enum.KeyCode.T,false,game); task.wait(0.05); vim:SendKeyEvent(false,Enum.KeyCode.T,false,game) end)
                                task.wait(0.3)
                            end
                        end
                        if not _bossRunning then break end

                        local _nixOrbiting=false; local _nixOrbitAngle=0
                        -- animation detector for orbit dodge
                        task.spawn(function()
                            local NIX_DODGE_ANIM="127359882437058"
                            local _lastNixDodge=nil
                            while _bossRunning do
                                pcall(function()
                                    if _nixOrbiting then return end
                                    local nix=workspace.Living and workspace.Living:FindFirstChild("Nix"); if not nix then return end
                                    local nixHum=nix:FindFirstChildOfClass("Humanoid"); local anim=nixHum and nixHum:FindFirstChildOfClass("Animator"); if not anim then return end
                                    for _,t in ipairs(anim:GetPlayingAnimationTracks()) do
                                        local id=tostring(t.Animation.AnimationId):match("%d+$")
                                        if id==NIX_DODGE_ANIM and _lastNixDodge~=id then
                                            _lastNixDodge=id; _nixOrbiting=true
                                            task.delay(4,function() _nixOrbiting=false; task.delay(2,function() if _lastNixDodge==id then _lastNixDodge=nil end end) end)
                                            break
                                        end
                                    end
                                end)
                                task.wait(0.05)
                            end
                        end)
                        -- Phase 5: farm Nix, retreat on low HP, loop back when Nix dies
                        while _bossRunning do
                            local c=getChar(); local hum=c and c:FindFirstChildOfClass("Humanoid"); local hrp=hum and hum.RootPart
                            if not (c and hum and hrp) then task.wait(0.1); continue end
                            if hum.Health<=0 then disableFarmCombat(); waitForRespawn(); continue end
                            if _nixOrbiting then
                                disableFarmCombat(); _bossTweening=false
                                local nix2=workspace.Living and workspace.Living:FindFirstChild("Nix")
                                local rp2=nix2 and nix2:FindFirstChild("HumanoidRootPart")
                                if rp2 then
                                    _nixOrbitAngle=_nixOrbitAngle+15*task.wait()
                                    local ox=rp2.Position.X+math.cos(_nixOrbitAngle)*25
                                    local oz=rp2.Position.Z+math.sin(_nixOrbitAngle)*25
                                    hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                                    hrp.CFrame=CFrame.new(ox,rp2.Position.Y+24.8,oz)*CFrame.Angles(0,-_nixOrbitAngle,0)
                                else task.wait(0.1) end
                                continue
                            end
                            local nix=workspace.Living and workspace.Living:FindFirstChild("Nix")
                            if not nix then
                                -- Nix died - wait for chest to be taken before farming for next shard
                                disableFarmCombat(); _bossTweening=false
                                local chestTaken=false
                                local startWait=os.clock()
                                while not chestTaken and (os.clock()-startWait)<10 do
                                    if not workspace.DialogueInteractables:FindFirstChildOfClass("Model") then
                                        chestTaken=true; break
                                    end
                                    task.wait(0.1)
                                end
                                task.wait(1); break
                            end
                            local rp=nix:FindFirstChild("HumanoidRootPart"); if not rp then task.wait(0.1); continue end
                            local targetPos=rp.CFrame*CFrame.new(0,24.8,17.1)
                            local dist=(hrp.Position-targetPos.Position).Magnitude
                            if dist>10 then
                                disableFarmCombat()
                                if not _bossTweening then
                                    _bossTweening=true
                                    task.spawn(function() pcall(function() tweenToMob(targetPos,function() return not _bossRunning end) end); _bossTweening=false end)
                                end
                            else
                                _bossTweening=false; enableFarmCombat()
                                hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                                pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
                                hrp.CFrame=CFrame.lookAt(targetPos.Position,rp.Position)
                            end
                            task.wait()
                        end
                    end
                end)
            end
            local hasCal = _bossSelected["Calamitas"]
            if hasCal then
                task.spawn(function()
                    local CAL_DODGE_ANIMS={
                        ["123027684175200"]=true,["104549708275048"]=true,
                        ["126948192880374"]=true,["123903488088917"]=true
                    }
                    -- dodge animation remover
                    task.spawn(function()
                        while _bossRunning do
                            pcall(function()
                                local cal=workspace.Living and workspace.Living:FindFirstChild("Calamitas"); if not cal then return end
                                local calHum=cal:FindFirstChildOfClass("Humanoid"); if not calHum then return end
                                local animator=calHum:FindFirstChildOfClass("Animator"); if not animator then return end
                                for _,t in ipairs(animator:GetPlayingAnimationTracks()) do
                                    local id=tostring(t.Animation.AnimationId):match("%d+$")
                                    if id and CAL_DODGE_ANIMS[id] then
                                        pcall(function() t:Stop(0) end)
                                        pcall(function() t:AdjustSpeed(0) end)
                                    end
                                end
                            end)
                            task.wait(0.05)
                        end
                    end)
                    -- farm Calamitas: fixed offset
                    while _bossRunning do
                        local c=getChar(); local hum=c and c:FindFirstChildOfClass("Humanoid"); local hrp=hum and hum.RootPart
                        if not (c and hum and hrp) then task.wait(0.1); continue end
                        if hum.Health<=0 then disableFarmCombat(); waitForRespawn(); continue end
                        local cal=workspace.Living and workspace.Living:FindFirstChild("Calamitas")
                        if not cal then
                            disableFarmCombat(); _bossTweening=false; task.wait(1); break
                        end
                        local rp=cal:FindFirstChild("HumanoidRootPart"); if not rp then task.wait(0.1); continue end
                        local targetPos=CFrame.new(rp.Position.X - 1.2, rp.Position.Y + 30.5, rp.Position.Z + 12.6)
                        local dist=(hrp.Position-targetPos.Position).Magnitude
                        if dist>10 then
                            disableFarmCombat()
                            if not _bossTweening then
                                _bossTweening=true
                                task.spawn(function() pcall(function() tweenToMob(targetPos,function() return not _bossRunning end) end); _bossTweening=false end)
                            end
                        else
                            _bossTweening=false; enableFarmCombat()
                            hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                            pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
                            hrp.CFrame=CFrame.lookAt(targetPos.Position,rp.Position)
                        end
                        task.wait()
                    end
                end)
            end
            if hasGiantDragonfly then
                task.spawn(function()
                    local _dragonOrbiting=false; local _dragonOrbitAngle=0
                    -- animation detector for orbit dodge
                    task.spawn(function()
                        local DRAGON_DODGE_ANIM="115495827589598"
                        local _lastDragonDodge=nil
                        while _bossRunning do
                            pcall(function()
                                if _dragonOrbiting then return end
                                local dragon=workspace.Living and workspace.Living:FindFirstChild("Giant Dragonfly"); if not dragon then return end
                                local dragonHum=dragon:FindFirstChildOfClass("Humanoid"); local anim=dragonHum and dragonHum:FindFirstChildOfClass("Animator"); if not anim then return end
                                for _,t in ipairs(anim:GetPlayingAnimationTracks()) do
                                    local id=tostring(t.Animation.AnimationId):match("%d+$")
                                    if id==DRAGON_DODGE_ANIM and _lastDragonDodge~=id then
                                        _lastDragonDodge=id; _dragonOrbiting=true
                                        task.delay(3,function() _dragonOrbiting=false; task.delay(2,function() if _lastDragonDodge==id then _lastDragonDodge=nil end end) end)
                                        break
                                    end
                                end
                            end)
                            task.wait(0.05)
                        end
                    end)
                    -- farm Giant Dragonfly, orbit dodge on animation
                    while _bossRunning do
                        local c=getChar(); local hum=c and c:FindFirstChildOfClass("Humanoid"); local hrp=hum and hum.RootPart
                        if not (c and hum and hrp) then task.wait(0.1); continue end
                        if hum.Health<=0 then disableFarmCombat(); waitForRespawn(); continue end
                        if _dragonOrbiting then
                            disableFarmCombat(); _bossTweening=false
                            local dragon=workspace.Living and workspace.Living:FindFirstChild("Giant Dragonfly")
                            local rp=dragon and dragon:FindFirstChild("HumanoidRootPart")
                            if rp then
                                _dragonOrbitAngle=_dragonOrbitAngle+15*task.wait()
                                local ox=rp.Position.X+math.cos(_dragonOrbitAngle)*25
                                local oz=rp.Position.Z+math.sin(_dragonOrbitAngle)*25
                                hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                                hrp.CFrame=CFrame.new(ox,48,oz)*CFrame.Angles(0,-_dragonOrbitAngle,0)
                            else task.wait(0.1) end
                            continue
                        end
                        local dragon=workspace.Living and workspace.Living:FindFirstChild("Giant Dragonfly")
                        if not dragon then
                            disableFarmCombat(); _bossTweening=false; task.wait(1); break
                        end
                        local rp=dragon:FindFirstChild("HumanoidRootPart"); if not rp then task.wait(0.1); continue end
                        local targetPos=rp.CFrame*CFrame.new(0,14.3,6.7)
                        local dist=(hrp.Position-targetPos.Position).Magnitude
                        if dist>10 then
                            disableFarmCombat()
                            if not _bossTweening then
                                _bossTweening=true
                                task.spawn(function() pcall(function() tweenToMob(targetPos,function() return not _bossRunning end) end); _bossTweening=false end)
                            end
                        else
                            _bossTweening=false; enableFarmCombat()
                            hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                            pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
                            hrp.CFrame=CFrame.lookAt(targetPos.Position,rp.Position)
                        end
                        task.wait()
                    end
                end)
            end
            local hasLordNivis=_bossSelected["Lord Nivis"]
            if hasLordNivis then
                task.spawn(function()
                    local _nivisOrbiting=false; local _nivisOrbitAngle=0
                    -- animation detector for orbit dodge
                    task.spawn(function()
                        local NIVIS_DODGE_ANIMS={
                            ["121890671665317"]=3,
                            ["83118719637202"]=5,
                            ["86978856932820"]=1.6,
                            ["99036187968467"]=2.88,
                        }
                        local _lastNivisDodge=nil
                        while _bossRunning do
                            pcall(function()
                                if _nivisOrbiting then return end
                                local nivis=workspace.Living and workspace.Living:FindFirstChild("Lord Nivis"); if not nivis then return end
                                local nivisHum=nivis:FindFirstChildOfClass("Humanoid"); local anim=nivisHum and nivisHum:FindFirstChildOfClass("Animator"); if not anim then return end
                                for _,t in ipairs(anim:GetPlayingAnimationTracks()) do
                                    local id=tostring(t.Animation.AnimationId):match("%d+$")
                                    if NIVIS_DODGE_ANIMS[id] and _lastNivisDodge~=id then
                                        _lastNivisDodge=id; _nivisOrbiting=true
                                        local orbitDur=NIVIS_DODGE_ANIMS[id]
                                        task.delay(orbitDur,function() _nivisOrbiting=false; task.delay(2,function() if _lastNivisDodge==id then _lastNivisDodge=nil end end) end)
                                        break
                                    end
                                end
                            end)
                            task.wait(0.05)
                        end
                    end)
                    -- farm Lord Nivis, orbit dodge on animation
                    while _bossRunning do
                        local c=getChar(); local hum=c and c:FindFirstChildOfClass("Humanoid"); local hrp=hum and hum.RootPart
                        if not (c and hum and hrp) then task.wait(0.1); continue end
                        if hum.Health<=0 then disableFarmCombat(); waitForRespawn(); continue end
                        if _nivisOrbiting then
                            disableFarmCombat(); _bossTweening=false
                            local nivis=workspace.Living and workspace.Living:FindFirstChild("Lord Nivis")
                            local rp=nivis and nivis:FindFirstChild("HumanoidRootPart")
                            if rp then
                                _nivisOrbitAngle=_nivisOrbitAngle+15*task.wait()
                                local ox=rp.Position.X+math.cos(_nivisOrbitAngle)*25
                                local oz=rp.Position.Z+math.sin(_nivisOrbitAngle)*25
                                hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                                hrp.CFrame=CFrame.new(ox,rp.Position.Y+25,oz)*CFrame.Angles(0,-_nivisOrbitAngle,0)
                            else task.wait(0.1) end
                            continue
                        end
                        local nivis=workspace.Living and workspace.Living:FindFirstChild("Lord Nivis")
                        if not nivis then
                            disableFarmCombat(); _bossTweening=false; task.wait(1); break
                        end
                        local rp=nivis:FindFirstChild("HumanoidRootPart"); if not rp then task.wait(0.1); continue end
                        local targetPos=rp.CFrame*CFrame.new(0,10.6,6.5)
                        local dist=(hrp.Position-targetPos.Position).Magnitude
                        if dist>10 then
                            disableFarmCombat()
                            if not _bossTweening then
                                _bossTweening=true
                                task.spawn(function() pcall(function() tweenToMob(targetPos,function() return not _bossRunning end) end); _bossTweening=false end)
                            end
                        else
                            _bossTweening=false; enableFarmCombat()
                            hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                            pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
                            hrp.CFrame=CFrame.lookAt(targetPos.Position,rp.Position)
                        end
                        task.wait()
                    end
                end)
            end
        end
    }, "BossFarm")
    onUnload(function() stopBossFarm() end)
end)()

Tog.AutoTakeBossChest = GameL2:Toggle({
    Name="Auto Boss Chest", Default=false,
    Callback=function(p)
        local _running=p
        if not p then return end
        local function getMyNames()
            local names={LP.Name}
            pcall(function() if LP.DisplayName~="" and LP.DisplayName~=LP.Name then table.insert(names,LP.DisplayName) end end)
            pcall(function()
                local cn=LP.PlayerGui.MainUI.HUDContainer.TopLeftDetailsContainer.PlayerName.ContentText
                if cn and cn~="" then table.insert(names,cn) end
            end)
            return names
        end
        local function isMyChest(m)
            local ok,cn=pcall(function() return m.ChestUI.Container.PlayerName.ContentText end)
            if not ok or not cn or cn=="" then return true end -- can't tell, assume ours
            local myNames=getMyNames()
            for _,n in ipairs(myNames) do if cn:find(n,1,true) then return true end end
            return false
        end
        local function collectChest(m)
            -- method 1: RemoteEvent
            for _,v in ipairs(m:GetDescendants()) do
                if v:IsA("RemoteEvent") then pcall(function() v:FireServer("Take","All") end); pcall(function() v:FireServer() end) end
            end
            -- method 2: ProximityPrompt
            for _,v in ipairs(m:GetDescendants()) do
                if v:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(v) end) end
            end
            -- method 3: ClickDetector
            local hrp=getHRP()
            for _,v in ipairs(m:GetDescendants()) do
                if v:IsA("ClickDetector") then
                    pcall(function() fireclickdetector(v) end)
                    if hrp and v.Parent then pcall(function() firetouchinterest(hrp,v.Parent,0) end) end
                end
            end
            -- method 4: touch
            if hrp then
                for _,v in ipairs(m:GetDescendants()) do
                    if v:IsA("BasePart") then pcall(function() firetouchinterest(hrp,v,0) end); pcall(function() firetouchinterest(hrp,v,1) end) end
                end
            end
        end
        -- loop 1: spam collect on all interactables
        task.spawn(function()
            while _running and Tog.AutoTakeBossChest.State do
                pcall(function()
                    local di=workspace:FindFirstChild("DialogueInteractables"); if not di then return end
                    for _,child in ipairs(di:GetChildren()) do
                        local re=child:FindFirstChildOfClass("RemoteEvent"); if re then pcall(function() re:FireServer("Take","All") end) end
                    end
                end); task.wait(0.1)
            end
        end)
        -- loop 2: find & tween to chests
        task.spawn(function()
            local _hadChests=false; local _lastMoveTick=0; local _chestSeen={}
            while _running and Tog.AutoTakeBossChest.State do
                pcall(function()
                    local hrp=getHRP(); if not hrp then return end
                    local di=workspace:FindFirstChild("DialogueInteractables"); if not di then return end
                    local foundChest=false
                    for _,m in ipairs(di:GetChildren()) do
                        if not Tog.AutoTakeBossChest.State then return end
                        if not (m:IsA("Model") and m.Name:find("Chest") and m.Parent) then continue end
                        local pp=m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                        if not pp or (hrp.Position-pp.Position).Magnitude>300 then continue end
                        foundChest=true
                        if not _chestSeen[m] then _chestSeen[m]=tick() end
                        if tick()-_chestSeen[m]<0.5 then continue end
                        collectChest(m)
                        local timedOut=false; local timer=task.delay(3,function() timedOut=true end)
                        pcall(function() tweenToChest(pp.CFrame*CFrame.new(0,3,0),function() return not Tog.AutoTakeBossChest.State or not pp.Parent or timedOut end) end)
                        task.cancel(timer)
                        if m.Parent then collectChest(m) end
                    end
                    if foundChest then _hadChests=true
                    elseif _hadChests and tick()-_lastMoveTick>3 then
                        _hadChests=false; _lastMoveTick=tick(); _chestSeen={}
                        local leftPos=hrp.Position-hrp.CFrame.RightVector*30
                        task.spawn(function() pcall(function() tweenToChest(CFrame.new(leftPos),function() return not Tog.AutoTakeBossChest.State end) end) end)
                    end
                end); task.wait(0.1)
            end
        end)
    end
}, "AutoTakeBossChest")
;(function()
    local _eatConn=nil
    Tog.AutoEatPart = GameL2:Toggle({
        Name="Auto Eat Hollow Part", Default=false,
        Callback=function(p)
            if _eatConn then _eatConn:Disconnect(); _eatConn=nil end
            if not p then return end
            _eatConn=RS.Heartbeat:Connect(function()
                local hrp=getHRP(); if not hrp then return end
                local best,bestDist=nil,20
                local root=workspace:FindFirstChild("Debris") or workspace
                for _,v in ipairs(root:GetDescendants()) do
                    if not v:IsA("ProximityPrompt") then continue end
                    local pp=v.Parent; if not (pp and pp:IsA("BasePart")) then continue end
                    local dist=(hrp.Position-pp.Position).Magnitude
                    if dist<bestDist then best=v; bestDist=dist end
end
                if best then pcall(function() fireproximityprompt(best) end) end
            end)
        end
    }, "AutoEatPart")
    onUnload(function() if _eatConn then _eatConn:Disconnect() end end)
end)()

local _chestRunning=false
Tog.ChestTPEnabled = NavL3:Toggle({
    Name="Chest Farm", Default=false,
    Callback=function(p)
        _chestRunning=p
        if not p then return end
        task.spawn(function()
            while _chestRunning do
                local di=workspace:FindFirstChild("DialogueInteractables")
                if not di then task.wait(2); continue end
                local chests={}
                for _,v in ipairs(di:GetChildren()) do
                    if v:IsA("Model") and v.Name:find("ChestTemplate") then table.insert(chests,v) end
                end
                if #chests==0 then task.wait(2); continue end
                for _,chest in ipairs(chests) do
                    if not _chestRunning then break end
                    if not chest or not chest.Parent then continue end
                    local hrp=getHRP(); if not hrp then break end
                    local pp=chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
                    if not pp or not pp.Parent then continue end
                    -- try RemoteEvent first (same as boss chest farm)
                    local re=chest:FindFirstChildOfClass("RemoteEvent")
                    if re then
                        pcall(function() re:FireServer("Take","All") end)
                    else
                        -- fall back: tween to chest and fire prompts
                        pcall(function() tweenTo(pp.CFrame*CFrame.new(0,3,0),function() return not _chestRunning end) end)
                        if not chest.Parent then continue end
                        task.wait(0.3)
                        pcall(function()
                            if not chest.Parent then return end
                            for _,v in ipairs(chest:GetDescendants()) do
                                if v:IsA("ProximityPrompt") then fireproximityprompt(v)
                                elseif v:IsA("ClickDetector") then firetouchinterest(hrp,v.Parent,false); fireclickdetector(v) end
                            end
                        end)
                        task.wait(3)
                    end
                    task.wait(0.3)
                end
                task.wait(0.5)
            end
        end)
    end
}, "ChestTPEnabled")
onUnload(function() _chestRunning=false end)


GameR:Label({ Text="Position" })
Opt.FarmMode    = GameR:Dropdown({ Name="Position", Options={"Above","Below","In Front","Behind"}, Default=4, Multi=false, Callback=function(v) _farmMode=type(v)=="table" and next(v) or v end }, "FarmMode")
Opt.FarmOffsetX = GameR:Slider({ Name="X Offset", Default=0,   Minimum=-50, Maximum=50, Precision=1, Callback=function(v) _farmOffX=v end }, "FarmOffsetX")
Opt.FarmOffsetY = GameR:Slider({ Name="Y Offset", Default=0,   Minimum=-50, Maximum=50, Precision=1, Callback=function(v) _farmOffY=v end }, "FarmOffsetY")
Opt.FarmOffsetZ = GameR:Slider({ Name="Z Offset", Default=6.5, Minimum=0,   Maximum=50, Precision=1, Callback=function(v) _farmOffZ=v end }, "FarmOffsetZ")
GameR:Divider()
GameR:Label({ Text="Combat" })
Tog.AutoEquip = GameR:Toggle({ Name="Auto Equip Weapon",      Default=false, Callback=function(p) getgenv()._VVU_autoEquip=p end }, "AutoEquip")
Tog.AutoGrip  = GameR:Toggle({ Name="Auto Grip",              Default=false, Callback=function(p) getgenv()._VVU_autoGrip=p  end }, "AutoGrip")
Tog.AutoRes   = GameR:Toggle({ Name="Res/Shikai/Volt Weapon", Default=false, Callback=function(p) getgenv()._VVU_autoRes=p   end }, "AutoRes")
Tog.AutoM1    = GameR:Toggle({ Name="Kill Aura",              Default=false, Callback=function(p) getgenv()._VVU_autoM1=p    end }, "AutoM1")
Tog.AutoCrit  = GameR:Toggle({ Name="Auto Critical Aura",     Default=false, Callback=function(p) getgenv()._VVU_autoCrit=p  end }, "AutoCrit")

;(function()
    local _skillRemote; pcall(function() _skillRemote=ReplicatedStorage.Requests.UseSkill end)
    local _skillRunning=false; local _skillCooldowns={}
    local function _isSkill(tool) if not tool:IsA("Tool") then return false end; local ok=pcall(function() return tool.SkillName end); return ok end
    local function _getSkillList()
        local seen,skills={},{}
        local bp=LP.Backpack; if bp then for _,v in ipairs(bp:GetChildren()) do if _isSkill(v) and not seen[v.Name] then seen[v.Name]=true; table.insert(skills,v.Name) end end end
        local c=LP.Character; if c then for _,v in ipairs(c:GetChildren()) do if _isSkill(v) and not seen[v.Name] then seen[v.Name]=true; table.insert(skills,v.Name) end end end
        table.sort(skills); return #skills>0 and skills or {"(no skills found)"}
    end
    local function _refreshList() if Opt.AutoSkillSelect then task.defer(function() pcall(function() Opt.AutoSkillSelect:ClearOptions(); Opt.AutoSkillSelect:InsertOptions(_getSkillList()) end) end) end end
    _farmSkillFire=function()
        if not _skillRemote then return end
        local selected=Opt.AutoSkillSelect and Opt.AutoSkillSelect.Value; if not selected or not next(selected) then return end
        local c=getChar(); if not c then return end; local now=tick()
        for skillName,on in pairs(selected) do
            if on and (not _skillCooldowns[skillName] or now-_skillCooldowns[skillName]>=0.3) then
                local item=LP.Backpack:FindFirstChild(skillName) or c:FindFirstChild(skillName)
                if item then pcall(function() _skillRemote:FireServer(skillName,item,{HoldingSpace=false}) end); _skillCooldowns[skillName]=now end
            end
        end
end
    Opt.AutoSkillSelect = GameR2:Dropdown({ Name="Skills", Search=true, Options={"-- loading --"}, Default=nil, Multi=true, Callback=function() end }, "AutoSkillSelect")
    Tog.AutoSkillEnabled = GameR2:Toggle({ Name="Auto Use Skill", Default=false, Keybind=Enum.KeyCode.Unknown, Callback=function(p) _skillRunning=p; if not p then return end; task.spawn(function() while _skillRunning do _farmSkillFire(); task.wait(0.1) end end) end }, "AutoSkillEnabled")
    Tog.AutoSkillAll = GameR2:Toggle({ Name="Auto Use All Skills", Default=false, Keybind=Enum.KeyCode.Unknown, Callback=function(p) if not p then return end; task.spawn(function() while Tog.AutoSkillAll and Tog.AutoSkillAll.State do if _skillRemote then local c=getChar(); local now=tick(); for _,src in ipairs({LP.Backpack,c}) do if src then for _,item in ipairs(src:GetChildren()) do if _isSkill(item) then if not _skillCooldowns[item.Name] or now-_skillCooldowns[item.Name]>=0.3 then pcall(function() _skillRemote:FireServer(item.Name,item,{HoldingSpace=false}) end); _skillCooldowns[item.Name]=now end end end end end end; task.wait(0.1) end end) end }, "AutoSkillAll")
    GameR2:Divider()
    local _elemAbilRemote; pcall(function() _elemAbilRemote=ReplicatedStorage.Requests.UseAbility end)
    Opt.ElemAbilSelect = GameR2:Dropdown({ Name="Element Ability", Options={"1","2","3","4","5"}, Default=nil, Multi=true, Callback=function() end }, "ElemAbilSelect")
    Tog.ElemAbilEnabled = GameR2:Toggle({ Name="Auto Use Ability", Default=false, Keybind=Enum.KeyCode.Unknown, Callback=function(p) if not p then return end; task.spawn(function() while Tog.ElemAbilEnabled and Tog.ElemAbilEnabled.State do local sel=Opt.ElemAbilSelect and Opt.ElemAbilSelect.Value; if sel and next(sel) then for numStr in pairs(sel) do if not (Tog.ElemAbilEnabled and Tog.ElemAbilEnabled.State) then break end; if _elemAbilRemote then pcall(function() _elemAbilRemote:FireServer(tonumber(numStr) or 1) end) end; task.wait(0.5) end else task.wait(0.5) end end end) end }, "ElemAbilEnabled")
    task.spawn(function() task.wait(1); _refreshList() end)
    LP.Backpack.ChildAdded:Connect(_refreshList); LP.Backpack.ChildRemoved:Connect(_refreshList)
    LP.CharacterAdded:Connect(function(c) task.wait(1); _refreshList(); c.ChildAdded:Connect(function(v) if _isSkill(v) then _refreshList() end end) end)
    onUnload(function() _skillRunning=false end)
end)()

;(function()
    local AttemptSell=ReplicatedStorage.Requests:WaitForChild("AttemptSell")
    local _sellRunning=false; local _sellRarities={}; local _sellExclude={}; local _sellExcludeTraits={}
    local _ToolInfo=nil; local _PlayerData=nil; local _SellAcc=nil
    local function _getToolInfo() if not _ToolInfo then pcall(function() _ToolInfo=require(game.ReplicatedStorage.SharedAssets.Info.ToolInfo) end) end; return _ToolInfo end
    local function _getPlayerData() if not _PlayerData then pcall(function() _PlayerData=require(game.ReplicatedStorage.SharedModules.PlayerData) end) end; return _PlayerData end
    local function _getSellAcc() if not _SellAcc then pcall(function() _SellAcc=require(game.ReplicatedStorage.SharedAssets.Info.Accessories) end) end; return _SellAcc end
    local function _isSkillItem(tool) if not tool:IsA("Tool") then return false end; local ok=pcall(function() return tool.SkillName end); return ok end
    local function _buildSellTraitList()
        local acc=_getSellAcc(); local list={}
        if acc and acc.ModifierPool then for _,mod in pairs(acc.ModifierPool) do if mod.Prefix then table.insert(list,mod.Prefix) end end end
        table.sort(list); if #list==0 then list={"No traits found"} end; return list
    end
    local function _getItemTraitSell(item)
        local acc=_getSellAcc(); if not acc then return nil end
        local pd=_getPlayerData(); if not pd then return nil end
        local uid=item:GetAttribute("U_ID"); if not uid then return nil end
        local charData=pd:GetCharacterData(LP); if not charData then return nil end
        for _,inv in ipairs(charData.Inventory) do
            if inv.U_ID==uid and inv.Trait then
                local mod=acc.ModifierPool and acc.ModifierPool[inv.Trait]
                if mod and mod.Prefix then return mod.Prefix end
                local ok2,prefix2=pcall(function() return acc:GetAccessoryPrefix(inv) end)
                if ok2 and prefix2 then return prefix2 end
                return "Trait#"..tostring(inv.Trait)
            end
        end
        return nil
    end
    local function _buildSellList()
        local items={}; for _,item in ipairs(LP.Backpack:GetChildren()) do if item:IsA("Tool") and not _isSkillItem(item) then table.insert(items,item.Name) end end
        table.sort(items); if #items==0 then items={"Empty"} end
        pcall(function() if Opt.SellSelect then Opt.SellSelect:ClearOptions(); Opt.SellSelect:InsertOptions(items) end end)
        pcall(function() if Opt.ExcludeSelect then Opt.ExcludeSelect:ClearOptions(); Opt.ExcludeSelect:InsertOptions(items) end end)
    end
    local function _getRarity(item)
        local ti=_getToolInfo(); if not ti then return nil end; local pd=_getPlayerData(); if not pd then return nil end
        local id=item:GetAttribute("ItemId"); if not id then return nil end; local uid=item:GetAttribute("U_ID"); if not uid then return nil end
        local charData=pd:GetCharacterData(LP); if not charData then return nil end
        local itemData=nil; for _,inv in ipairs(charData.Inventory) do if inv.U_ID==uid then itemData=inv; break end end
        local info=ti:GetItemFromId(id); if not info then return nil end
        local ok,str=pcall(function() return info:GetRarityStr(itemData,true) end)
        if not ok or not str then return nil end; return (str:gsub("<[^>]+>",""))
    end
    local function _shouldSell(item) if not next(_sellRarities) then return true end; local rarity=_getRarity(item); if not rarity then return true end; return _sellRarities[rarity]==true end
    Opt.SellRarities  = GameL4:Dropdown({ Name="Sell Rarities", Options={"Common","Uncommon","Rare","Epic","Legendary"}, Default=nil, Multi=true, Callback=function(v) _sellRarities=v end }, "SellRarities")
    Opt.SellSelect    = GameL4:Dropdown({ Name="Items", Search=true,         Options={"--"}, Default=nil, Multi=true, Callback=function() end }, "SellSelect")
    Opt.ExcludeSelect = GameL4:Dropdown({ Name="Exclude Items", Search=true,  Options={"--"}, Default=nil, Multi=true, Callback=function(v) _sellExclude=type(v)=="table" and v or {} end }, "ExcludeSelect")
    GameL4:Divider()
    Opt.SellExcludeTraits = GameL4:Dropdown({ Name="Exclude Traits", Search=true, Options=_buildSellTraitList(), Default=nil, Multi=true, Callback=function(v) _sellExcludeTraits=type(v)=="table" and v or {} end }, "SellExcludeTraits")
    Tog.AutoSellEnabled = GameL4:Toggle({ Name="Auto Sell", Default=false, Callback=function(p) _sellRunning=p; if not p then return end; task.spawn(function() while _sellRunning do local sel=Opt.SellSelect and Opt.SellSelect.Value or {}; for _,item in ipairs(LP.Backpack:GetChildren()) do if not item:IsA("Tool") or _isSkillItem(item) then continue end; local uuid=item:GetAttribute("U_ID"); if not uuid then continue end; if item.Name=="Frostvein Shard" then continue end; if _sellExclude[item.Name] then continue end; local trait=_getItemTraitSell(item); if trait and _sellExcludeTraits[trait] then continue end; local byRarity=next(_sellRarities) and _shouldSell(item); local byName=sel[item.Name]; if byRarity or byName then pcall(function() AttemptSell:FireServer(uuid,item,1) end) end end; task.wait(0.5) end end) end }, "AutoSellEnabled")
    GameL4:Button({ Name="Refresh Sell List", Callback=_buildSellList })
    task.spawn(function() task.wait(3); _buildSellList() end)
    LP.Backpack.ChildAdded:Connect(function() task.defer(_buildSellList) end)
    LP.Backpack.ChildRemoved:Connect(function() task.defer(_buildSellList) end)
    onUnload(function() _sellRunning=false end)
end)()

;(function()
    local AttemptBank=ReplicatedStorage.Requests:WaitForChild("AttemptBank")
    local _ToolInfoB=nil; local _PlayerDataB=nil
    local function _bTI() if not _ToolInfoB then pcall(function() _ToolInfoB=require(game.ReplicatedStorage.SharedAssets.Info.ToolInfo) end) end; return _ToolInfoB end
    local function _bPD() if not _PlayerDataB then pcall(function() _PlayerDataB=require(game.ReplicatedStorage.SharedModules.PlayerData) end) end; return _PlayerDataB end
    local function _isSkillItemB(tool) if not tool:IsA("Tool") then return false end; local ok=pcall(function() return tool.SkillName end); return ok end
    local function _getItemRarityB(id, uid, inventory)
        local ti=_bTI(); if not ti then return nil end
        local itemData=nil; for _,inv in ipairs(inventory) do if inv.U_ID==uid then itemData=inv; break end end
        local info=ti:GetItemFromId(id); if not info then return nil end
        local ok,str=pcall(function() return info:GetRarityStr(itemData,true) end)
        if not ok or not str then return nil end; return str:gsub("<[^>]+>","")
    end

    -- ── AUTO STORE ────────────────────────────────────────────────────────────
    local _storeRunning=false; local _storeRarities={}; local _storeItems={}; local _storeExclude={}; local _storeExcludeTraits={}; local _storeSelectTraits={}
    local _AccessoriesB=nil
    local function _bAcc() if not _AccessoriesB then pcall(function() _AccessoriesB=require(game.ReplicatedStorage.SharedAssets.Info.Accessories) end) end; return _AccessoriesB end
    local function _getItemTrait(id, uid, inventory)
        local acc=_bAcc(); if not acc then return nil end
        for _,inv in ipairs(inventory) do
            if inv.U_ID==uid and inv.Trait then
                local ok,prefix=pcall(function() return acc:GetAccessoryPrefix(inv) end)
                if ok and prefix then return prefix end
                -- fallback: use raw trait ID
                local mod=acc.ModifierPool and acc.ModifierPool[inv.Trait]
                if mod then return mod.Prefix end
                return "Trait#"..tostring(inv.Trait)
            end
        end
        return nil
    end
    local function _buildTraitList()
        local acc=_bAcc(); local list={}
        if acc and acc.ModifierPool then
            for id, mod in pairs(acc.ModifierPool) do
                if mod.Prefix then table.insert(list, mod.Prefix) end
            end
        end
        table.sort(list)
        if #list==0 then list={"No traits found"} end
        return list
    end
    local function _shouldStore(item, inventory)
        local id=item:GetAttribute("ItemId"); local uid=item:GetAttribute("U_ID")
        if not id or not uid then return false end
        local trait=_getItemTrait(id,uid,inventory)
        -- Exclude traits always wins
        if trait and _storeExcludeTraits[trait] then return false end
        -- If specific traits are selected in Store Traits, store items with those traits
        if next(_storeSelectTraits) then
            if trait and _storeSelectTraits[trait] then return true end
        end
        -- Otherwise fall through to rarity/item filters
        local hasR=next(_storeRarities); local hasI=next(_storeItems)
        if not hasR and not hasI and not next(_storeSelectTraits) then return true end
        if hasR then local r=_getItemRarityB(id,uid,inventory); if r and _storeRarities[r] then return true end end
        if hasI and _storeItems[item.Name] then return true end
        return false
    end
    local function _buildStoreList()
        local items={}; for _,item in ipairs(LP.Backpack:GetChildren()) do if item:IsA("Tool") and not _isSkillItemB(item) then table.insert(items,item.Name) end end
        table.sort(items); if #items==0 then items={"Empty"} end
        pcall(function() if Opt.StoreItemSelect then Opt.StoreItemSelect:ClearOptions(); Opt.StoreItemSelect:InsertOptions(items) end end)
        pcall(function() if Opt.StoreExcludeSelect then Opt.StoreExcludeSelect:ClearOptions(); Opt.StoreExcludeSelect:InsertOptions(items) end end)
    end
    Opt.StoreRarities   = GameL5:Dropdown({ Name="Rarities", Options={"Common","Uncommon","Rare","Epic","Legendary"}, Default=nil, Multi=true, Callback=function(v) _storeRarities=type(v)=="table" and v or {} end }, "StoreRarities")
    Opt.StoreItemSelect = GameL5:Dropdown({ Name="Items", Search=true, Options={"--"}, Default=nil, Multi=true, Callback=function(v) _storeItems=type(v)=="table" and v or {} end }, "StoreItemSelect")
    Opt.StoreExcludeSelect = GameL5:Dropdown({ Name="Exclude Items", Search=true, Options={"--"}, Default=nil, Multi=true, Callback=function(v) _storeExclude=type(v)=="table" and v or {} end }, "StoreExcludeSelect")
    GameL5:Divider()
    Opt.StoreTraits = GameL5:Dropdown({ Name="Store Traits", Search=true, Options=_buildTraitList(), Default=nil, Multi=true, Callback=function(v) _storeSelectTraits=type(v)=="table" and v or {} end }, "StoreTraits")
    Opt.StoreExcludeTraits = GameL5:Dropdown({ Name="Exclude Traits", Search=true, Options=_buildTraitList(), Default=nil, Multi=true, Callback=function(v) _storeExcludeTraits=type(v)=="table" and v or {} end }, "StoreExcludeTraits")
    Tog.AutoStoreEnabled = GameL5:Toggle({ Name="Auto Store", Default=false, Callback=function(p)
        _storeRunning=p; if not p then return end
        task.spawn(function()
            while _storeRunning do
                local pd=_bPD(); local charData=pd and pd:GetCharacterData(LP)
                local inventory=charData and charData.Inventory or {}
                for _,item in ipairs(LP.Backpack:GetChildren()) do
                    if not item:IsA("Tool") or _isSkillItemB(item) then continue end
                    if _storeExclude[item.Name] then continue end
                    if not _shouldStore(item, inventory) then continue end
                    local id=item:GetAttribute("ItemId"); local uid=item:GetAttribute("U_ID")
                    pcall(function() AttemptBank:InvokeServer({Id=id, U_ID=uid, Amount=1}) end)
                end
                task.wait(0.5)
            end
        end)
    end }, "AutoStoreEnabled")
    GameL5:Button({ Name="Refresh Items", Callback=_buildStoreList })
    task.spawn(function() task.wait(3); _buildStoreList() end)
    LP.Backpack.ChildAdded:Connect(function() task.defer(_buildStoreList) end)
    LP.Backpack.ChildRemoved:Connect(function() task.defer(_buildStoreList) end)
    onUnload(function() _storeRunning=false end)
    GameL5:Divider()
    do
        local _bankUpgradeThread = nil
        Tog.AutoBankSlot = GameL5:Toggle({
            Name="Auto Upgrade Bank Slot", Default=false,
            Callback=function(p)
                if _bankUpgradeThread then pcall(task.cancel, _bankUpgradeThread); _bankUpgradeThread=nil end
                if not p then return end
                pcall(function() AttemptBank:InvokeServer({ BuySlot = true }) end)
                _bankUpgradeThread = task.spawn(function()
                    while Tog.AutoBankSlot and Tog.AutoBankSlot.State do
                        pcall(function() AttemptBank:InvokeServer({ BuySlot = true }) end)
                        task.wait(1)
                    end
                end)
            end }, "AutoBankSlot")
        onUnload(function() if _bankUpgradeThread then pcall(task.cancel, _bankUpgradeThread) end end)
    end
end)()

;(function()
    local _whRunning=false; local _whConn=nil; local _whRarities={}; local _whQueue={}; local _whSeen={}
    local _whToolInfo=nil; local _whPlrData=nil
    local function _whTI() if not _whToolInfo then pcall(function() _whToolInfo=require(game.ReplicatedStorage.SharedAssets.Info.ToolInfo) end) end; return _whToolInfo end
    local function _whPD() if not _whPlrData then pcall(function() _whPlrData=require(game.ReplicatedStorage.SharedModules.PlayerData) end) end; return _whPlrData end
    local function _isSkillItem2(tool) if not tool:IsA("Tool") then return false end; local ok=pcall(function() return tool.SkillName end); return ok end
    local function _whRarityAndName(item)
        local ti=_whTI(); local pd=_whPD(); if not ti or not pd then return nil,item.Name end
        local id=item:GetAttribute("ItemId"); local uid=item:GetAttribute("U_ID"); if not id or not uid then return nil,item.Name end
        local charData=pd:GetCharacterData(LP); if not charData then return nil,item.Name end
        local inv=nil; for _,v in ipairs(charData.Inventory) do if v.U_ID==uid then inv=v; break end end
        local info=ti:GetItemFromId(id); if not info then return nil,item.Name end
        local ok1,str=pcall(function() return info:GetRarityStr(inv,true) end)
        local ok2,name=pcall(function() return info:GetName(inv) end)
        return (ok1 and str) and (str:gsub("<[^>]+>","")) or nil, (ok2 and name) or item.Name
    end
    local function _sendWebhook(url, lines)
        local reqFn = request or (syn and syn.request) or http_request or (http and http.request)
        if not reqFn or url == "" then return end
        local hasLeg = false
        for _, l in ipairs(lines) do if l:find("Legendary") then hasLeg = true; break end end
        local desc = table.concat(lines, "\n")
        local ok, body = pcall(function()
            return HS:JSONEncode({
                content = hasLeg and "@everyone 💰 **LEGENDARY DROP** 💰" or nil,
                embeds = {{
                    title = "Item Drop — " .. LP.Name,
                    description = desc,
                    color = hasLeg and 16766720 or 5793266,
                    footer = { text = "VV Ultimatum • Zero Hub" }
                }}
            })
        end)
        if not ok then return end
        pcall(function() reqFn({ Url=url, Method="POST", Headers={["Content-Type"]="application/json"}, Body=body }) end)
    end

    local function _onItemAdded(item)
        if not _whRunning then return end
        if not item:IsA("Tool") or _isSkillItem2(item) then return end
        if item.Name == "Frostvein Shard" then return end
        local uid = item:GetAttribute("U_ID")
        if not uid or _whSeen[uid] then return end
        _whSeen[uid] = true
        task.spawn(function()
            task.wait(0.3)
            if not item.Parent then return end
            local rarity, name = _whRarityAndName(item)
            if next(_whRarities) then if not rarity or not _whRarities[rarity] then return end end
            local url = Opt.WebhookURL and Opt.WebhookURL.Text or ""
            if url == "" then return end
            local line = name .. (rarity and (" (" .. rarity .. ")") or "")
            _sendWebhook(url, { line })
        end)
    end

    Opt.WebhookURL = GameR3:Input({ Name="Webhook URL", Placeholder="https://discord.com/api/webhooks/...", AcceptedCharacters="All", Callback=function() end }, "WebhookURL")
    GameR3:Button({ Name="Test Webhook", Callback=function()
        local url = Opt.WebhookURL and Opt.WebhookURL.Text or ""
        if url == "" then notify("Enter a webhook URL first", 2); return end
        task.spawn(function() _sendWebhook(url, {"Test Item (Legendary)"}) end)
        notify("Webhook sent", 2)
    end})
    Opt.WebhookRarities = GameR3:Dropdown({ Name="Rarities", Options={"Common","Uncommon","Rare","Epic","Legendary"}, Default=nil, Multi=true, Callback=function(v) _whRarities=v end }, "WebhookRarities")
    Tog.WebhookEnabled = GameR3:Toggle({
        Name="Notify on Drop", Default=false,
        Callback=function(p)
            _whRunning=p; _whSeen={}
            if _whConn then _whConn:Disconnect(); _whConn=nil end
            if not p then return end
            task.spawn(function() _whTI(); _whPD() end)
            -- watch backpack AND character (some games add to character first)
            _whConn=LP.Backpack.ChildAdded:Connect(_onItemAdded)
            if LP.Character then
                LP.Character.ChildAdded:Connect(function(item) task.defer(function() _onItemAdded(item) end) end)
            end
            LP.CharacterAdded:Connect(function(c)
                c.ChildAdded:Connect(function(item) task.defer(function() _onItemAdded(item) end) end)
            end)
        end
    }, "WebhookEnabled")
    onUnload(function() _whRunning=false; if _whConn then _whConn:Disconnect() end end)
end)()

-- ── QUEST HELPER ─────────────────────────────────────────────────────────────
;(function()
    local _PD = nil; pcall(function() _PD = require(ReplicatedStorage.SharedModules.PlayerData) end)
    local _QC = nil; pcall(function() _QC = require(ReplicatedStorage.SharedAssets.Info.QuestCache) end)
    local _DI = workspace:FindFirstChild("DialogueInteractables")

    local function _getCD()
        if not _PD then return nil end
        local ok, cd = pcall(function() return _PD:GetCharacterData(LP) end)
        return ok and cd or nil
    end

    local function _getQI(id)
        if not _QC or not id then return nil end
        local ok, info = pcall(function() return _QC:GetInfoFromId(id) end)
        return ok and info or nil
    end

    -- QuestId attribute only — QuestLine is a Configuration (no .Value)
    local function _findNPC(questId)
        if not _DI then return nil end
        local sid = tostring(questId)
        for _, npc in ipairs(_DI:GetChildren()) do
            local qid = npc:GetAttribute("QuestId")
            if qid and tostring(qid) == sid then return npc end
        end
        return nil
end

    local function _getPrompt(npc)
        if not npc then return nil end
        for _, v in ipairs(npc:GetDescendants()) do
            if v:IsA("ProximityPrompt") then return v end
        end
        return nil
    end

    local function _getRoot(npc)
        if not npc then return nil end
        return npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
    end

    -- ── Labels ───────────────────────────────────────────────────────────────

    GameR4:Divider()

    -- ── Get All Available Quests ──────────────────────────────────────────────
    -- Uses QuestAvailable attribute set by the game's NPC client script
    GameR4:Button({ Name="List Available Quests", Callback=function()
        if not _DI then notify("DialogueInteractables not found",2); return end
        local cd = _getCD()
        local found = {}
        for _, npc in ipairs(_DI:GetChildren()) do
            local available = npc:GetAttribute("QuestAvailable")
            local qid = npc:GetAttribute("QuestId")
            if available then
                local info = qid and _getQI(qid)
                local title = info and info.QuestTitle or (qid and tostring(qid) or npc.Name)
                table.insert(found, title.." ("..npc.Name..")")
            end
end
        if #found == 0 then
            notify("No available quests found nearby",3)
        else
            notify("Available: "..table.concat(found, " | "), 8)
        end
    end})

    -- ── NPC Dropdown for Tween ────────────────────────────────────────────────
    local function _buildNPCList()
        local list = {"Auto (tracked quest)"}
        if not _DI then return list end
        for _, npc in ipairs(_DI:GetChildren()) do
            local qid = npc:GetAttribute("QuestId")
            if qid then
                local info = _getQI(qid)
                local label = (info and info.QuestTitle or tostring(qid)).." / "..npc.Name
                table.insert(list, label)
            elseif npc:GetAttribute("MissionGiver") then
                table.insert(list, "[Missions] "..npc.Name)
            end
        end
        return list
    end

    Opt.QuestNPCSelect = GameR4:Dropdown({
        Name="Select NPC", Options=_buildNPCList(), Default=1, Multi=false,
        Callback=function() end
    }, "QuestNPCSelect")

    GameR4:Button({ Name="Refresh NPC List", Callback=function()
        pcall(function()
            Opt.QuestNPCSelect:ClearOptions()
            Opt.QuestNPCSelect:InsertOptions(_buildNPCList())
        end)
    end})

    local function _resolveSelectedNPC()
        local sel = Opt.QuestNPCSelect and Opt.QuestNPCSelect.Value
        if not sel or sel == "Auto (tracked quest)" or sel == "" then
            -- use tracked quest
            local cd = _getCD(); if not cd then return nil end
            local id = cd.CurrentQuestID; if not id or id==-1 then return nil end
            return _findNPC(id)
        end
        -- find by label match
        if not _DI then return nil end
        for _, npc in ipairs(_DI:GetChildren()) do
            if sel:find(npc.Name, 1, true) then return npc end
        end
        return nil
    end

    GameR4:Divider()

    GameR4:Divider()

    GameR4:Button({ Name="Tween to NPC", Callback=function()
        local npc = _resolveSelectedNPC()
        if not npc then notify("No NPC selected or no tracked quest",3); return end
        local root = _getRoot(npc); if not root then notify("NPC has no root",2); return end
        task.spawn(function() tweenTo(root.CFrame * CFrame.new(0,0,5)) end)
        notify("Tweening to "..npc.Name, 2)
    end})

    GameR4:Button({ Name="Talk to NPC", Callback=function()
        local npc = _resolveSelectedNPC()
        if not npc then notify("No NPC selected or no tracked quest",3); return end
        local prompt = _getPrompt(npc); if not prompt then notify("No ProximityPrompt on "..npc.Name,3); return end
        pcall(fireproximityprompt, prompt)
        notify("Fired prompt on "..npc.Name, 2)
    end})

    GameR4:Button({ Name="Go & Talk", Callback=function()
        local npc = _resolveSelectedNPC()
        if not npc then notify("No NPC selected or no tracked quest",3); return end
        local root = _getRoot(npc); if not root then notify("NPC has no root",2); return end
        task.spawn(function()
            notify("Heading to "..npc.Name.."...", 2)
            tweenTo(root.CFrame * CFrame.new(0,0,5))
            task.wait(0.5)
            local prompt = _getPrompt(npc)
            if prompt then pcall(fireproximityprompt, prompt); notify("Talking to "..npc.Name, 2) end
        end)
    end})

    GameR4:Divider()

    -- ── Tween to All Quest NPCs ───────────────────────────────────────────────
    local _tweenAllRunning = false

    Tog.TweenAllQuestNPCs = GameR4:Toggle({
        Name="Tween to All Quest NPCs", Default=false,
        Callback=function(p)
            _tweenAllRunning = p
            if not p then _cancelTween = true; return end
            task.spawn(function()
                if not _DI then notify("DialogueInteractables not found",2); return end
                local npcs = {}
                for _, npc in ipairs(_DI:GetChildren()) do
                    if npc:GetAttribute("QuestAvailable") then
                        table.insert(npcs, npc)
                    end
                end
                if #npcs == 0 then
                    notify("No available quest NPCs found",3)
                    _tweenAllRunning = false
                    if Tog.TweenAllQuestNPCs then Tog.TweenAllQuestNPCs:UpdateState(false) end
                    return
                end
                notify("Visiting "..#npcs.." quest NPCs...", 3)
                for _, npc in ipairs(npcs) do
                    if not _tweenAllRunning then break end
                    local root = _getRoot(npc); if not root then continue end
                    tweenTo(root.CFrame * CFrame.new(0, 0, 5))
                    task.wait(0.4)
                    if not _tweenAllRunning then break end
                    local prompt = _getPrompt(npc)
                    if prompt then
                        pcall(fireproximityprompt, prompt)
                        notify("Talked to "..npc.Name, 2)
                        task.wait(2)
                    end
                end
                _tweenAllRunning = false
                if Tog.TweenAllQuestNPCs then Tog.TweenAllQuestNPCs:UpdateState(false) end
                notify("Done visiting all quest NPCs", 3)
            end)
        end
    }, "TweenAllQuestNPCs")

    onUnload(function() _tweenAllRunning = false end)

    GameR4:Divider()

    local _autoDialogEnabled = false
    Tog.AutoQuestDialogue = GameR4:Toggle({
        Name="Auto Quest Dialogue", Default=false,
        Callback=function(p)
            _autoDialogEnabled = p
            if p then
                local _priority = {
                    "task","quest","accept","complete","turn","about",
                    "mission","yes","sure","okay","give","receive","begin"
                }
                pcall(function()
                    ReplicatedStorage.Requests.Dialogue.OnClientInvoke = function(data)
                        if not _autoDialogEnabled then return end
                        local responses = (type(data)=="table" and data.Responses) or {}
                        if #responses == 0 then return end
                        local nonLeave = {}
                        for _, r in ipairs(responses) do
                            local id = type(r)=="string" and r or (r.Id or "")
                            if id ~= "Leave" then table.insert(nonLeave, id) end
                        end
                        if #nonLeave == 0 then return "Leave" end
                        for _, kw in ipairs(_priority) do
                            for _, id in ipairs(nonLeave) do
                                if id:lower():find(kw) then return id end
                            end
                        end
                        return nonLeave[1]
                    end
                end)
            else
                pcall(function() ReplicatedStorage.Requests.Dialogue.OnClientInvoke = nil end)
            end
        end
    }, "AutoQuestDialogue")
end)()

;(function()
    local TeleportToServer=ReplicatedStorage.Requests:WaitForChild("TeleportToServer")
    local _raids={
        ["Soul Society Outskirts"]={PlaceId=14218523102, ReserveServerCode="_xjr7JA0AFKIUc6fGVfjKYU5C868SFpDiXjbMDX75P_ecX1PAwAAAA2"},
        ["Soul Society"]          ={PlaceId=12337012844, ReserveServerCode="Uv-pYOQYNxf560p5ZT_eSpsFSuXtr9JCkxXc8zuTj8ps4FffAgAAAA2"},
        ["Las Noches"]            ={PlaceId=11127942816, ReserveServerCode="MkxUKSweAir5-XJRQiFcdby4TU7JJUJAhIrVxcYr7-mg7kaXAgAAAA2"},
        ["Wandenreich"]           ={PlaceId=11780443293, ReserveServerCode="FmKhJAd5QlVTfOOQ8kVWSaEvHcX_iwhFngK2Fyx2zNqdTCu-AgAAAA2"},
        ["Hueco Mundo"]           ={PlaceId=11131834995, ReserveServerCode="HHV4VUCjNMfOqVcBRLksifTD1L4orYBErowuqh7JDGNzUoKXAgAAAA2"},
        ["Human World"]           ={PlaceId=14219489601, ReserveServerCode="rDs2DI12Pdf-7u_WJ79X46drbMiTt3BBkUgVu-N_3NtBMYxPAwAAAA2"},
    }
    local _raidKeys={"Soul Society Outskirts","Soul Society","Las Noches","Wandenreich","Hueco Mundo","Human World"}
    local _selectedRaid=_raidKeys[1]
    Opt.RaidSelect=GameR5:Dropdown({
        Name="Raid", Options=_raidKeys, Default=1, Multi=false,
        Callback=function(v) _selectedRaid=type(v)=="table" and next(v) or v end
    },"RaidSelect")
    GameR5:Button({Name="Join Raid",Callback=function()
        local raid=_raids[_selectedRaid]; if not raid then return end
        pcall(function() TeleportToServer:InvokeServer({PlaceId=raid.PlaceId,ReserveServerCode=raid.ReserveServerCode}) end)
        notify("Joining ".._selectedRaid,2)
    end})
end)()
onUnload(function()
    getgenv()._VVU_autoM1=false; getgenv()._VVU_autoCrit=false; getgenv()._VVU_autoEquip=false
    getgenv()._VVU_autoGrip=false; getgenv()._VVU_autoRes=false
    for _,conn in pairs(farmConns) do if conn then conn:Disconnect() end end
end)


;(function()
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
local function scanMobESP2() local living=workspace:FindFirstChild("Living"); if not living then return end; for _,m in ipairs(living:GetChildren()) do if m:IsA("Model") and not PS:GetPlayerFromCharacter(m) then addMobESP(m) end end end
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
    local conn=RS.Heartbeat:Connect(function()
        if not (_npcESPEnabled and npc and npc.Parent) then removeNPCESP(npc); return end
        local myHRP=getHRP(); if not myHRP then return end
        local col=npcESPColor2; local dist=(hrp.Position-myHRP.Position).Magnitude
        local comps=_npcESP2.components or {}
        if dist>(S.espDist or 1000) then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local sv,onS=Cam:WorldToViewportPoint(hrp.Position); local hv,onH=head and Cam:WorldToViewportPoint(head.Position)
        if not onS then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local scale=math.clamp(1/(sv.Z*0.04),0.5,3); local bw=35*scale; local bh=70*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
        if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
        if comps["HP Bar"] and hum then local hpPct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1); local hpCol=Color3.fromHSV(hpPct*0.33,1,1); local barW=6; local barX=bx-barW-3; hpBack.Position=Vector2.new(barX-1,by-1); hpBack.Size=Vector2.new(barW+2,bh+2); hpBack.Visible=true; hpFill.Position=Vector2.new(barX,by+bh*(1-hpPct)); hpFill.Size=Vector2.new(barW,bh*hpPct); hpFill.Color=hpCol; hpFill.Visible=true else hpFill.Visible=false; hpBack.Visible=false end
        if comps["Text"] then local parts={}; if _npcESP2.showName then table.insert(parts,label or npc.Name) end; if _npcESP2.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end; txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14; txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0 else txt.Visible=false end
        if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
        if comps["Head Dot"] and onH and head then dot.Position=Vector2.new(hv.X,hv.Y); dot.Color=col; dot.Visible=true else dot.Visible=false end
        hl.Enabled=comps["Highlight"] and _npcESPEnabled or false; hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
    end)
    _npcESPActive[npc]={txt=txt,box=box,hpFill=hpFill,hpBack=hpBack,tracer=tracer,dot=dot,hl=hl,conn=conn,
        ancConn=npc.AncestryChanged:Connect(function(_,p) if not p then removeNPCESP(npc) end end)}
end
local function scanNPCESP2() local di=workspace:FindFirstChild("DialogueInteractables"); if not di then return end; for _,m in ipairs(di:GetChildren()) do if m:IsA("Model") then addNPCESP(m,m.Name) end end end
local function stopNPCESP() _npcESPEnabled=false; for npc in pairs(_npcESPActive) do removeNPCESP(npc) end end

Tog.NPCESPEnabled = VizR2:Toggle({
    Name="NPC ESP", Default=false,
    Callback=function(p) _npcESPEnabled=p; if p then scanNPCESP2(); task.spawn(function() while _npcESPEnabled do task.wait(3); scanNPCESP2() end end) else stopNPCESP() end end
}, "NPCESPEnabled")
Opt.NpcESPColor2 = VizR2:Colorpicker({ Name="NPC Color", Default=Color3.fromRGB(100,220,255), Alpha=0, Callback=function(c) npcESPColor2=c end }, "NpcESPColor2")
Tog.NpcESPRainbow2 = VizR2:Toggle({ Name="Rainbow",  Default=false, Callback=function(p) _npcESP2.rainbow=p  end }, "NpcESPRainbow2")
Tog.NpcESPShowName = VizR2:Toggle({ Name="Name",     Default=true,  Callback=function(p) _npcESP2.showName=p end }, "NpcESPShowName")
Tog.NpcESPShowDist = VizR2:Toggle({ Name="Distance", Default=true,  Callback=function(p) _npcESP2.showDist=p end }, "NpcESPShowDist")
Opt.NpcESPComponents = VizR2:Dropdown({ Name="Components", Multi=true, Default={"Text","Box 2D"}, Options={"Text","Highlight","Tracer","Box 2D","HP Bar","Head Dot"}, Callback=function(v) _npcESP2.components=v end }, "NpcESPComponents")
onUnload(function() stopNPCESP() end)
end)()
VizR2:Divider()


;(function()
    local _chestESPActive={}; local _chestESPEnabled=false; local _chestESPColor=Color3.fromRGB(255,215,0)
    local _chestESP2={components={},showName=true,showDist=true}
    local function removeChestESP(chest)
        local d=_chestESPActive[chest]; if not d then return end
        for _,k in ipairs({"txt","box","tracer"}) do if d[k] then pcall(function() d[k]:Remove() end) end end
        if d.hl then pcall(function() d.hl:Destroy() end) end
        if d.conn then pcall(function() d.conn:Disconnect() end) end
        if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
        _chestESPActive[chest]=nil
    end
    local function addChestESP(chest)
        if not chest or _chestESPActive[chest] then return end
        if not chest.Name:find("ChestTemplate") then return end
        local anchor=chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart"); if not anchor then return end
        local txt=Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
        local box=Drawing.new("Square"); box.Filled=false; box.Thickness=1.5; box.Visible=false
        local tracer=Drawing.new("Line"); tracer.Thickness=1; tracer.Visible=false
        local hl=Instance.new("Highlight",chest); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false
        local conn=RS.Heartbeat:Connect(function()
            if not (_chestESPEnabled and chest and chest.Parent) then removeChestESP(chest); return end
            local myHRP=getHRP(); if not myHRP then return end
            local col=_chestESPColor; local dist=(anchor.Position-myHRP.Position).Magnitude
            local comps=_chestESP2.components or {}
            if dist>(S.espDist or 1000) then txt.Visible=false; box.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            local sv,onS=Cam:WorldToViewportPoint(anchor.Position)
            if not onS then txt.Visible=false; box.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            local scale=math.clamp(1/(sv.Z*0.04),0.5,3); local bw=30*scale; local bh=30*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
            if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
            if comps["Text"] then local parts={}; if _chestESP2.showName then table.insert(parts,chest.Name:gsub("ChestTemplate","Chest")) end; if _chestESP2.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end; txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14; txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0 else txt.Visible=false end
            if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
            hl.Enabled=comps["Highlight"] and _chestESPEnabled or false; hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
        end)
        _chestESPActive[chest]={txt=txt,box=box,tracer=tracer,hl=hl,conn=conn,
            ancConn=chest.AncestryChanged:Connect(function(_,p) if not p then removeChestESP(chest) end end)}
end
    local function scanChestESP() local di=workspace:FindFirstChild("DialogueInteractables"); if not di then return end; for _,m in ipairs(di:GetChildren()) do if m:IsA("Model") and m.Name:find("ChestTemplate") then addChestESP(m) end end end
    local function stopChestESP() _chestESPEnabled=false; for c in pairs(_chestESPActive) do removeChestESP(c) end end
    local VizL = VizL3
    Tog.ChestESPEnabled = VizL:Toggle({
        Name="Chest ESP", Default=false,
        Callback=function(p) _chestESPEnabled=p; if p then scanChestESP(); task.spawn(function() while _chestESPEnabled do task.wait(3); scanChestESP() end end); local di=workspace:FindFirstChild("DialogueInteractables"); if di then di.ChildAdded:Connect(function(m) task.wait(0.2); if _chestESPEnabled then addChestESP(m) end end) end else stopChestESP() end end
    }, "ChestESPEnabled")
    Opt.ChestESPColor = VizL:Colorpicker({ Name="Chest Color", Default=Color3.fromRGB(255,215,0), Alpha=0, Callback=function(c) _chestESPColor=c end }, "ChestESPColor")
    Tog.ChestESPShowName = VizL:Toggle({ Name="Name",     Default=true, Callback=function(p) _chestESP2.showName=p end }, "ChestESPShowName")
    Tog.ChestESPShowDist = VizL:Toggle({ Name="Distance", Default=true, Callback=function(p) _chestESP2.showDist=p end }, "ChestESPShowDist")
    Opt.ChestESPComponents = VizL:Dropdown({ Name="Components", Multi=true, Default=nil, Options={"Text","Highlight","Tracer","Box 2D"}, Callback=function(v) _chestESP2.components=v end }, "ChestESPComponents")
    onUnload(function() stopChestESP() end)
end)()


;(function()
    local _portalESPActive={}; local _portalESPEnabled=false; local _portalESPColor=Color3.fromRGB(0,180,255)
    local _portalESP2={components={},showName=true,showDist=true}
    local function removePortalESP(portal) local d=_portalESPActive[portal]; if not d then return end; for _,k in ipairs({"txt","box","tracer"}) do if d[k] then pcall(function() d[k]:Remove() end) end end; if d.hl then pcall(function() d.hl:Destroy() end) end; if d.conn then pcall(function() d.conn:Disconnect() end) end; if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end; _portalESPActive[portal]=nil end
    local function addPortalESP(portal)
        if not portal or _portalESPActive[portal] then return end
        if not portal:IsA("BasePart") or portal.Name~="Portal" then return end
        local txt=Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
        local box=Drawing.new("Square"); box.Filled=false; box.Thickness=1.5; box.Visible=false
        local tracer=Drawing.new("Line"); tracer.Thickness=1; tracer.Visible=false
        local hl=Instance.new("Highlight",portal); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false
        local conn=RS.Heartbeat:Connect(function()
            if not (_portalESPEnabled and portal and portal.Parent) then removePortalESP(portal); return end
            local myHRP=getHRP(); if not myHRP then return end
            local col=_portalESPColor; local dist=(portal.Position-myHRP.Position).Magnitude
            local comps=_portalESP2.components or {}
            if dist>(S.espDist or 1000) then txt.Visible=false; box.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            local sv,onS=Cam:WorldToViewportPoint(portal.Position)
            if not onS then txt.Visible=false; box.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            local scale=math.clamp(1/(sv.Z*0.04),0.5,3); local bw=30*scale; local bh=30*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
            if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
            if comps["Text"] then local parts={}; if _portalESP2.showName then table.insert(parts,"Portal") end; if _portalESP2.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end; txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14; txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0 else txt.Visible=false end
            if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
            hl.Enabled=comps["Highlight"] and _portalESPEnabled or false; hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
        end)
        _portalESPActive[portal]={txt=txt,box=box,tracer=tracer,hl=hl,conn=conn,
            ancConn=portal.AncestryChanged:Connect(function(_,p) if not p then removePortalESP(portal) end end)}
    end
    local function scanPortalESP() local spawns=workspace:FindFirstChild("Debris") and workspace.Debris:FindFirstChild("PortalSpawns"); if not spawns then return end; for _,child in ipairs(spawns:GetChildren()) do addPortalESP(child) end end
    local function stopPortalESP() _portalESPEnabled=false; for p in pairs(_portalESPActive) do removePortalESP(p) end end
    local VizR = VizR3
    Tog.PortalESPEnabled = VizR3:Toggle({
        Name="Portal ESP", Default=false,
        Callback=function(p) _portalESPEnabled=p; if p then scanPortalESP(); local spawns=workspace:FindFirstChild("Debris") and workspace.Debris:FindFirstChild("PortalSpawns"); if spawns then spawns.ChildAdded:Connect(function(child) task.wait(0.2); if _portalESPEnabled then addPortalESP(child) end end) end else stopPortalESP() end end
    }, "PortalESPEnabled")
    Opt.PortalESPColor = VizR3:Colorpicker({ Name="Portal Color", Default=Color3.fromRGB(0,180,255), Alpha=0, Callback=function(c) _portalESPColor=c end }, "PortalESPColor")
    Tog.PortalESPShowName = VizR3:Toggle({ Name="Name",     Default=true, Callback=function(p) _portalESP2.showName=p end }, "PortalESPShowName")
    Tog.PortalESPShowDist = VizR3:Toggle({ Name="Distance", Default=true, Callback=function(p) _portalESP2.showDist=p end }, "PortalESPShowDist")
    Opt.PortalESPComponents = VizR3:Dropdown({ Name="Components", Multi=true, Default=nil, Options={"Text","Highlight","Tracer","Box 2D"}, Callback=function(v) _portalESP2.components=v end }, "PortalESPComponents")
    onUnload(function() stopPortalESP() end)
end)()


;(function()
    local _questESPActive={}; local _questESPEnabled=false; local _questESPColor=Color3.fromRGB(0,255,80)
    local _questESP2={components={},showName=true,showDist=true}

    local function removeQuestESP(npc)
        local d=_questESPActive[npc]; if not d then return end
        pcall(function() if d.txt    then d.txt:Remove()     end end)
        pcall(function() if d.box    then d.box:Remove()     end end)
        pcall(function() if d.tracer then d.tracer:Remove()  end end)
        pcall(function() if d.hl     then d.hl:Destroy()     end end)
        pcall(function() if d.conn   then d.conn:Disconnect() end end)
        pcall(function() if d.ancConn then d.ancConn:Disconnect() end end)
        _questESPActive[npc]=nil
    end

    local function addQuestESP(npc)
        if not npc or _questESPActive[npc] then return end
        if not npc:GetAttribute("QuestAvailable") then return end
        local hrp=npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart; if not hrp then return end
        local txt=Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
        local box=Drawing.new("Square"); box.Filled=false; box.Thickness=1.5; box.Visible=false
        local tracer=Drawing.new("Line"); tracer.Thickness=1; tracer.Visible=false
        local hl=Instance.new("Highlight",npc); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false
        local conn=RS.Heartbeat:Connect(function()
            if not (_questESPEnabled and npc and npc.Parent) then removeQuestESP(npc); return end
            if not npc:GetAttribute("QuestAvailable") then removeQuestESP(npc); return end
            local myHRP=getHRP(); if not myHRP then return end
            local col=_questESPColor; local dist=(hrp.Position-myHRP.Position).Magnitude
            local comps=_questESP2.components or {}
            if dist>(S.espDist or 1000) then txt.Visible=false; box.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            local sv,onS=Cam:WorldToViewportPoint(hrp.Position)
            if not onS then txt.Visible=false; box.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            local scale=math.clamp(1/(sv.Z*0.04),0.5,3); local bw=35*scale; local bh=70*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
            if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
            if comps["Text"] then
                local parts={}
                if _questESP2.showName then table.insert(parts,npc.Name) end
                if _questESP2.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end
                txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14
                txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0
            else txt.Visible=false end
            if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
            hl.Enabled=comps["Highlight"] and _questESPEnabled or false; hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
        end)
        _questESPActive[npc]={txt=txt,box=box,tracer=tracer,hl=hl,conn=conn,
            ancConn=npc.AncestryChanged:Connect(function(_,p) if not p then removeQuestESP(npc) end end)}
end

    local function scanQuestESP()
        local di=workspace:FindFirstChild("DialogueInteractables"); if not di then return end
        for _,m in ipairs(di:GetChildren()) do if m:IsA("Model") then addQuestESP(m) end end
    end
    local function stopQuestESP() _questESPEnabled=false; for npc in pairs(_questESPActive) do removeQuestESP(npc) end end

    Tog.QuestESPEnabled = VizL4:Toggle({
        Name="Quest ESP", Default=false,
        Callback=function(p)
            _questESPEnabled=p
            if p then
                scanQuestESP()
                task.spawn(function() while _questESPEnabled do task.wait(3); scanQuestESP() end end)
            else
                stopQuestESP()
            end
        end
    }, "QuestESPEnabled")
    Opt.QuestESPColor    = VizL4:Colorpicker({ Name="Quest Color", Default=Color3.fromRGB(0,255,80), Alpha=0, Callback=function(c) _questESPColor=c end }, "QuestESPColor")
    Tog.QuestESPShowName = VizL4:Toggle({ Name="Name",       Default=true, Callback=function(p) _questESP2.showName=p end }, "QuestESPShowName")
    Tog.QuestESPShowDist = VizL4:Toggle({ Name="Distance",   Default=true, Callback=function(p) _questESP2.showDist=p end }, "QuestESPShowDist")
    Opt.QuestESPComponents = VizL4:Dropdown({ Name="Components", Multi=true, Default=nil, Options={"Text","Highlight","Tracer","Box 2D"}, Callback=function(v) _questESP2.components=v end }, "QuestESPComponents")
    onUnload(function() stopQuestESP() end)
end)()

;(function()
    local _markerESPActive  = {}
    local _markerESPEnabled = false
    local _markerESPColor   = Color3.fromRGB(255, 165, 0)
    local _markerESP2       = { components={}, showName=true, showDist=true }

    local function removeMarkerESP(obj)
        local d=_markerESPActive[obj]; if not d then return end
        pcall(function() if d.txt    then d.txt:Remove()    end end)
        pcall(function() if d.tracer then d.tracer:Remove() end end)
        pcall(function() if d.hl     then d.hl:Destroy()    end end)
        pcall(function() if d.conn   then d.conn:Disconnect() end end)
        pcall(function() if d.ancConn then d.ancConn:Disconnect() end end)
        _markerESPActive[obj]=nil
    end

    local function addMarkerESP(obj, label)
        if not obj or _markerESPActive[obj] then return end
        local part=obj:IsA("BasePart") and obj or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
        if not part then return end
        local txt    = Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
        local tracer = Drawing.new("Line"); tracer.Thickness=1; tracer.Visible=false
        local hl     = Instance.new("Highlight"); hl.Adornee=obj; hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false; hl.Parent=obj
        local conn=RS.Heartbeat:Connect(function()
            if not (_markerESPEnabled and obj and obj.Parent) then removeMarkerESP(obj); return end
            local myHRP=getHRP(); if not myHRP then return end
            local col=_markerESPColor
            local dist=(part.Position-myHRP.Position).Magnitude
            local comps=_markerESP2.components or {}
            if dist>(S.espDist or 1000) then txt.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            local sv,onS=Cam:WorldToViewportPoint(part.Position)
            if not onS then txt.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            if comps["Text"] then
                local parts={}
                if _markerESP2.showName then table.insert(parts, label or obj.Name) end
                if _markerESP2.showDist then table.insert(parts, string.format("[%.0fm]",dist)) end
                txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14
                txt.Position=Vector2.new(sv.X,sv.Y-20); txt.Visible=#parts>0
            else txt.Visible=false end
            if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
            hl.Enabled=comps["Highlight"] and _markerESPEnabled or false
            hl.FillColor=col; hl.OutlineColor=col
        end)
        _markerESPActive[obj]={txt=txt,tracer=tracer,hl=hl,conn=conn,
            ancConn=obj.AncestryChanged:Connect(function(_,p) if not p then removeMarkerESP(obj) end end)}
end

    local function scanMarkerESP()
        local debris=workspace:FindFirstChild("Debris"); if not debris then return end
        for _,child in ipairs(debris:GetChildren()) do
            if child.Name:find("Marker") then
                if child:IsA("Model") or child:IsA("BasePart") then addMarkerESP(child, child.Name) end
                for _,sub in ipairs(child:GetChildren()) do
                    if sub:IsA("BasePart") or sub:IsA("Model") then addMarkerESP(sub, child.Name..": "..sub.Name) end
                end
            end
        end
    end

    local function stopMarkerESP() _markerESPEnabled=false; for obj in pairs(_markerESPActive) do removeMarkerESP(obj) end end

    Tog.MarkerESPEnabled = VizR4:Toggle({
        Name="Marker ESP", Default=false,
        Callback=function(p)
            _markerESPEnabled=p
            if p then
                scanMarkerESP()
                task.spawn(function() while _markerESPEnabled do task.wait(5); scanMarkerESP() end end)
            else stopMarkerESP() end
        end
    }, "MarkerESPEnabled")
    Opt.MarkerESPColor    = VizR4:Colorpicker({ Name="Color",    Default=Color3.fromRGB(255,165,0), Alpha=0, Callback=function(c) _markerESPColor=c end }, "MarkerESPColor")
    Tog.MarkerESPShowName = VizR4:Toggle({ Name="Name",     Default=true, Callback=function(p) _markerESP2.showName=p end }, "MarkerESPShowName")
    Tog.MarkerESPShowDist = VizR4:Toggle({ Name="Distance", Default=true, Callback=function(p) _markerESP2.showDist=p end }, "MarkerESPShowDist")
    Opt.MarkerESPComponents = VizR4:Dropdown({ Name="Components", Multi=true, Default=nil,
        Options={"Text","Highlight","Tracer"},
        Callback=function(v) _markerESP2.components=v end
    }, "MarkerESPComponents")
    onUnload(function() stopMarkerESP() end)
end)()


;(function()
local _wFrameTimer=tick(); local _wFrames=0; _wFPS=60; local _wPingTimer=0; local _wPing=0
RS.RenderStepped:Connect(function()
    _wFrames=_wFrames+1; local now=tick()
    if now-_wFrameTimer>=1 then _wFPS=_wFrames; _wFrames=0; _wFrameTimer=now end
    if now-_wPingTimer>=1 then pcall(function() _wPing=math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end); _wPingTimer=now end
end)
onUnload(function()
    local _el={}; for c in pairs(espActive) do _el[#_el+1]=c end; for _,c in ipairs(_el) do removeESP(c) end
end)


local specTarget=nil; local specConn=nil
local function buildSpecList()
    local list={"--"}; for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(list,plr.Name) end end; return list
end
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


local _coordInput=nil
Opt.Coordinates = NavL:Input({ Name="Coordinates", Placeholder="X, Y, Z", AcceptedCharacters="All", Callback=function() end }, "Coordinates")
NavL:Button({ Name="Tween To", Callback=function()
    local v=Opt.Coordinates and Opt.Coordinates.Text or ""
    local x,y,z=v:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
    if x then task.spawn(function() tweenTo(CFrame.new(tonumber(x),tonumber(y),tonumber(z))) end) end
end})
NavL:Button({ Name="Copy Position", Callback=function()
    local hrp=getHRP(); if hrp then setclipboard(tostring(hrp.Position)) end
end})
NavL:Divider()
local clickTPConn=nil
Tog.ClickTP = NavL:Toggle({
    Name="Click TP", Default=false,
    Callback=function(p)
        if clickTPConn then clickTPConn:Disconnect(); clickTPConn=nil end
        if p then clickTPConn=UIS.InputBegan:Connect(function(inp,gpe)
            if gpe or inp.UserInputType~=Enum.UserInputType.MouseButton2 then return end
            local ray=Cam:ScreenPointToRay(inp.Position.X,inp.Position.Y)
            local res=workspace:Raycast(ray.Origin,ray.Direction*2000)
            if res then task.spawn(function() tweenTo(CFrame.new(res.Position+Vector3.new(0,3,0))) end) end
        end) end
    end
}, "ClickTP")


NavL2:Label({ Text="NPC Teleport" })
local _npcTPMap={}; local _npcListPending=false
local function _buildNPCList()
    if _npcListPending then return end; _npcListPending=true
    task.defer(function()
        _npcListPending=false
        local di=workspace:FindFirstChild("DialogueInteractables"); if not di then return end
        local list={}; _npcTPMap={}
        for _,model in ipairs(di:GetChildren()) do
            if not model:IsA("Model") then continue end
            local hrp=model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
            if hrp and not _npcTPMap[model.Name] then _npcTPMap[model.Name]=hrp.CFrame; table.insert(list,model.Name) end
        end
        table.sort(list); if #list==0 then list={"No NPCs found"} end
        pcall(function() if Opt.NPCSelect then Opt.NPCSelect:ClearOptions(); Opt.NPCSelect:InsertOptions(list) end end)
    end)
end
Opt.NPCSelect = NavL2:Dropdown({ Name="NPC", Search=true, Options={"--"}, Default=1, Multi=false, Callback=function() end }, "NPCSelect")
NavL2:Button({ Name="Teleport to NPC", Callback=function()
    local sel=Opt.NPCSelect and Opt.NPCSelect.Value; if not sel or not _npcTPMap[sel] then return end
    task.spawn(function() tweenTo(_npcTPMap[sel]*CFrame.new(0,0,4)) end)
end})
task.spawn(function() task.wait(1); _buildNPCList(); local di=workspace:FindFirstChild("DialogueInteractables"); if di then di.ChildAdded:Connect(function() task.wait(0.5); _buildNPCList() end); di.ChildRemoved:Connect(function() task.wait(0.5); _buildNPCList() end) end end)


NavL2:Divider()
NavL2:Label({ Text="Location Teleport" })
local _locTPMap={}
local function _buildLocList()
    local lm=workspace:FindFirstChild("Debris") and workspace.Debris:FindFirstChild("LocationMarkers"); if not lm then return end
    local list={}; _locTPMap={}
    for _,child in ipairs(lm:GetChildren()) do
        local part=child:IsA("BasePart") and child or (child:IsA("Model") and (child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")))
        if part and not _locTPMap[child.Name] then _locTPMap[child.Name]=part.CFrame; table.insert(list,child.Name) end
    end
    table.sort(list); if #list==0 then list={"No locations found"} end
    pcall(function() if Opt.LocSelect then Opt.LocSelect:ClearOptions(); Opt.LocSelect:InsertOptions(list) end end)
end
Opt.LocSelect = NavL2:Dropdown({ Name="Location", Search=true, Options={"--"}, Default=1, Multi=false, Callback=function() end }, "LocSelect")
NavL2:Button({ Name="Teleport to Location", Callback=function()
    local sel=Opt.LocSelect and Opt.LocSelect.Value; if not sel or not _locTPMap[sel] then return end
    task.spawn(function() tweenTo(_locTPMap[sel]*CFrame.new(0,0,4)) end)
end})
task.spawn(function() task.wait(1); _buildLocList() end)


NavL2:Divider()
NavL2:Label({ Text="Map Teleporter" })
local MapData = {
	{ Name = "Soul Society Outskirts", PlaceId = 14218523102 },
	{ Name = "Arctic Plains", PlaceId = 15079707729 },
	{ Name = "Las Noches", PlaceId = 11127942816 },
	{ Name = "Soul Society", PlaceId = 12337012844 },
	{ Name = "Wandenreich", PlaceId = 11780443293 },
	{ Name = "Hueco Mundo", PlaceId = 11131834995 },
	{ Name = "Snowy Mountain", PlaceId = 14321102147 },
	{ Name = "Arctic Cave", PlaceId = 15645525857 },
	{ Name = "Snow Camp", PlaceId = 18972283841 },
	{ Name = "Outskirts Swamp", PlaceId = 95787471190312 },
	{ Name = "Menos Forest", PlaceId = 16914874220 },
	{ Name = "Human World", PlaceId = 14219489601 }
}
local _mapNames={}; for _,m in ipairs(MapData) do table.insert(_mapNames,m.Name) end
Opt.MapSelect = NavL2:Dropdown({ Name="Map", Search=true, Options=_mapNames, Default=1, Multi=false, Callback=function() end }, "MapSelect")
NavL2:Button({ Name="Teleport to Map", Callback=function()
	local sel=Opt.MapSelect and Opt.MapSelect.Value; if not sel then return end
	local map=nil; for _,m in ipairs(MapData) do if m.Name==sel then map=m; break end end
	if not map then return end
	local TeleportToServer=ReplicatedStorage:FindFirstChild("Requests") and ReplicatedStorage.Requests:FindFirstChild("TeleportToServer")
	if not TeleportToServer then return end
	pcall(function() TeleportToServer:InvokeServer({ PlaceId=map.PlaceId, ReserveServerCode="", IsRaid=true }) end)
end})

NavL2:Divider()
NavL2:Label({ Text="Must be in Soul Society Outskirts" })
NavL2:Button({ Name="Insta TP to Marsh", Callback=function()
    local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local marsh=workspace.Debris:FindFirstChild("MarshTeleporters"); if not marsh then return end
    for _,child in ipairs(marsh:GetChildren()) do
        if child:IsA("BasePart") then pcall(firetouchinterest, child, hrp, 0) end
    end
end})
NavL2:Divider()
NavL2:Label({ Text="Must be in Marsh" })
NavL2:Button({ Name="Insta TP to Soul Society Outskirts", Callback=function()
    local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local tp=workspace.Debris:FindFirstChild("Teleporter")
    if tp and tp:IsA("BasePart") then pcall(firetouchinterest, tp, hrp, 0) end
end})

NavL2:Divider()
NavL2:Label({ Text="Dangai Portal" })
NavL2:Button({ Name="Tween to Portal", Callback=function()
    local spawns=workspace:FindFirstChild("Debris") and workspace.Debris:FindFirstChild("PortalSpawns"); if not spawns then return end
    for _,child in ipairs(spawns:GetChildren()) do
        if child.Name=="Portal" and child:IsA("BasePart") then task.spawn(function() tweenTo(child.CFrame*CFrame.new(0,0,5)) end); return end
    end
end})


Tog.AttachNearby = NavR:Toggle({
    Name="Attach Nearby", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AttachNearby and Tog.AttachNearby.State do
                local myHRP=getHRP(); if not myHRP then task.wait(0.1); continue end
                local range=Opt.MobsRange and Opt.MobsRange.Value or 1000
                local best,bestD=nil,range
                for _,plr in ipairs(PS:GetPlayers()) do
                    if plr~=LP and plr.Character then
                        local hrp=plr.Character:FindFirstChild("HumanoidRootPart"); local hum=plr.Character:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.Health>0 then local d=(myHRP.Position-hrp.Position).Magnitude; if d<bestD then best=hrp; bestD=d end end
                    end
                end
                if best then
                    local offset=CFrame.new(0,Opt.MobsHeight and Opt.MobsHeight.Value or 0,Opt.MobsDistance and Opt.MobsDistance.Value or 0)
                    myHRP.CFrame=best.CFrame*offset; myHRP.AssemblyLinearVelocity=Vector3.zero
                end
                task.wait(0.1)
            end
        end)
    end
}, "AttachNearby")
NavR:Divider()
end)()
;(function()
    local function buildAttachPlrList() local l={"--"}; for _,p in ipairs(PS:GetPlayers()) do if p~=LP then table.insert(l,p.Name) end end; return l end
    Opt.AttachTargetPlayer = NavR:Dropdown({ Name="Attach Target", Search=true, Options=buildAttachPlrList(), Default=1, Multi=false, Callback=function() end }, "AttachTargetPlayer")
end)()
Tog.AttachSelected = NavR:Toggle({
    Name="Attach Player", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AttachSelected and Tog.AttachSelected.State do
                local myHRP=getHRP(); if not myHRP then task.wait(); continue end
                local val=Opt.AttachTargetPlayer and Opt.AttachTargetPlayer.Value
                local plr=type(val)=="string" and PS:FindFirstChild(val) or val
                if plr and plr~=LP and plr.Character then
                    local hrp=plr.Character:FindFirstChild("HumanoidRootPart"); local hum=plr.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health>0 then
                        local offset=CFrame.new(0,Opt.MobsHeight and Opt.MobsHeight.Value or 0,Opt.MobsDistance and Opt.MobsDistance.Value or 0)
                        tweenTo(hrp.CFrame*offset)
end
                end
                task.wait()
            end
        end)
    end
}, "AttachSelected")
Opt.MobsRange    = NavR2:Slider({ Name="Range",    Default=1000, Minimum=0,   Maximum=10000, Precision=0, Callback=function() end }, "MobsRange")
Opt.MobsDistance = NavR2:Slider({ Name="Distance", Default=0,    Minimum=-50, Maximum=50,   Precision=0, Callback=function() end }, "MobsDistance")
Opt.MobsHeight   = NavR2:Slider({ Name="Height",   Default=0,    Minimum=-50, Maximum=50,   Precision=0, Callback=function() end }, "MobsHeight")
NavR2:Divider()

-- World Portal
NavR2:Label({ Text = "World Portal" })

-- display name → { internal Id for portal, placeId for server hop }
local _WORLDS = {
    ["Fort Adams"]             = { id="SnowyMountain",        placeId=14219489601         },
    ["Soul Society Outskirts"] = { id="SoulSocietyOutskirts", placeId=121345602945775     },
    ["Las Noches"]             = { id="LasNoches",            placeId=119777193083785     },
    ["Wandenreich"]            = { id="Wandenreich",          placeId=11780443293         },
    ["Soul Society"]           = { id="SoulSociety",          placeId=13229243486         },
    ["Hueco Mundo"]            = { id="HuecoMundo",           placeId=18972283841         },
    ["Human World"]            = { id="HumanWorld",           placeId=10626511620         },
    ["Menos Forest"]           = { id="MenosForest",          placeId=12337012844         },
    ["Arctic Plains"]          = { id="ArcticPlains",         placeId=17083682617         },
    ["Arctic Cave"]            = { id="ArcticCave",           placeId=102123868363969     },
    ["Snow Encampment"]        = { id="SnowCamp",             placeId=9861495985          },
    ["The Marsh"]              = { id="OutskirtsSwamp",       placeId=14321102147         },
    ["Trade Realm"]            = { id="TradeRealm",           placeId=95787471190312      },
    ["Inner World"]            = { id="InnerWorld",           placeId=15645525857         },
    ["Valley of Screams"]      = { id="ValleyOfScreams",      placeId=16914874220         },
    ["Dangai"]                 = { id="Dangai",               placeId=6270290407          },
    ["Tournament"]             = { id="Tournament",           placeId=11131834995         },
    ["Hub"]                    = { id="Hub",                  placeId=11127942816         },
}

local _worldList = {}
for name in pairs(_WORLDS) do table.insert(_worldList, name) end
table.sort(_worldList)

local _portalUnlocked = false

local function _hookAllWorlds()
    local IdMap = require(ReplicatedStorage.SharedAssets.Info.PlaceIds.IDMap.MainGame)
    local allWorldsList = {}
    for _, name in next, IdMap do table.insert(allWorldsList, name) end

    -- hook GetCharacterData so every caller gets unlocked data
    pcall(function()
        local PD = require(ReplicatedStorage.SharedModules.PlayerData)
        local origGCD = PD.GetCharacterData
        PD.GetCharacterData = function(self, player)
            local cd = origGCD(self, player)
            if cd and player == LP then
                cd.UnlockedHueco = true
                if cd.QuestData and cd.QuestData.CompletedQuests then
                    cd.QuestData.CompletedQuests["40"]  = true
                    cd.QuestData.CompletedQuests["114"] = true
                end
            end
            return cd
        end
    end)

    -- hook GetJoinablePlaces to return all worlds
    local GJP = require(ReplicatedStorage.SharedModules.Places.GetJoinablePlaces)
    hookfunction(GJP, function() return allWorldsList end)

    -- hook the WorldPortal OnClientEvent handler's upvalues
    -- to catch any secondary checks inside the LocalScript
    pcall(function()
        local conns = getconnections(ReplicatedStorage.Requests.WorldPortal.OnClientEvent)
        for _, conn in ipairs(conns) do
            local fn = conn.Function
            if not fn then continue end
            for _, uv in ipairs(getupvalues(fn)) do
                if type(uv) == "function" then
                    -- if it's GetJoinablePlaces inside the handler, hook it too
                    pcall(function()
                        local uvInner = getupvalues(uv)
                        if uvInner and #uvInner > 0 then
                            hookfunction(uv, function() return allWorldsList end)
                        end
                    end)
                end
            end
        end
    end)

    -- hook parseChoiceTbl (upvalue [2]) so RadialWheel UI shows all worlds
    hookfunction(
        getupvalues(require(ReplicatedStorage.SharedModules.UIManager.Components.Prompts.RadialWheel))[2],
        function()
            local all = {}
            for _, name in next, IdMap do
                all[#all + 1] = { AppearAs = name, Id = name }
            end
            return all
        end
    )
end

Tog.UnlockAllWorlds = NavR2:Toggle({
    Name    = "Unlock All Worlds",
    Default = false,
    Callback = function(p)
        if not p or _portalUnlocked then return end
        pcall(_hookAllWorlds)
        _portalUnlocked = true
        notify("All worlds unlocked", 2)
    end
}, "UnlockAllWorlds")

NavR2:Divider()

Opt.WorldHopSelect = NavR2:Dropdown({
    Name     = "World",
    Search   = true,
    Options  = _worldList,
    Default  = 1,
    Multi    = false,
    Callback = function() end
}, "WorldHopSelect")

NavR2:Button({
    Name = "Insta Portal TP",
    Callback = function()
        local sel = Opt.WorldHopSelect and Opt.WorldHopSelect.Value
        if not sel then notify("Select a world", 2); return end
        local w = _WORLDS[sel]
        if not w then notify("World not mapped", 2); return end
        notify("Portaling to " .. sel .. "...", 3)
        pcall(function()
            -- hook GetJoinablePlaces to return only our world
            local GJP = require(ReplicatedStorage.SharedModules.Places.GetJoinablePlaces)
            hookfunction(GJP, function() return { w.id } end)
            -- hook parseChoiceTbl to show only our world in UI
            hookfunction(
                getupvalues(require(ReplicatedStorage.SharedModules.UIManager.Components.Prompts.RadialWheel))[2],
                function() return {{ AppearAs = w.id, Id = w.id }} end
            )
            ReplicatedStorage.Requests.WorldPortal:FireServer()
        end)
        -- RadialWheel waits 0.5s then blocks on InputBegan:Wait()
        -- one choice = auto-hovered, fire click to confirm
        task.spawn(function()
            task.wait(0.6)
            pcall(function()
                firesignal(game:GetService("UserInputService").InputBegan,
                    {UserInputType=Enum.UserInputType.MouseButton1,
                     KeyCode=Enum.KeyCode.Unknown,
                     Delta=Vector3.zero,
                     Position=Vector3.zero}, false)
            end)
        end)
    end
})

NavR2:Button({
    Name = "Hop to World",
    Callback = function()
        local sel = Opt.WorldHopSelect and Opt.WorldHopSelect.Value
        if not sel then notify("Select a world", 2); return end
        local w = _WORLDS[sel]
        if not w then notify("World not mapped", 2); return end
        notify("Portaling to " .. sel .. "...", 3)
        pcall(function()
            local GJP = require(ReplicatedStorage.SharedModules.Places.GetJoinablePlaces)
            hookfunction(GJP, function() return { w.id } end)
            hookfunction(
                getupvalues(require(ReplicatedStorage.SharedModules.UIManager.Components.Prompts.RadialWheel))[2],
                function() return {{ AppearAs = w.id, Id = w.id }} end
            )
            ReplicatedStorage.Requests.WorldPortal:FireServer()
        end)
    end
})

NavR2:Button({
    Name = "Open Portal UI",
    Callback = function()
        if not _portalUnlocked then pcall(_hookAllWorlds); _portalUnlocked = true end
        pcall(function() ReplicatedStorage.Requests.WorldPortal:FireServer() end)
    end
})



onUnload(function()
    if clickTPConn then clickTPConn:Disconnect() end
    if nearbyConn then nearbyConn:Disconnect() end
end)

;(function()
    local HOG="Hogyoku Shard"
    local _sniperConn=nil; local _sniperTarget="Any"
    local _notifConn=nil; local _notifSeen={}

    local function playersWithHog()
        local list={"Any"}
        for _,plr in ipairs(PS:GetPlayers()) do
            if plr~=LP and plr.Backpack:FindFirstChild(HOG) then
                table.insert(list,plr.Name)
            end
        end
        return list
    end

    local function nearestHogTarget()
        local hrp=getHRP(); if not hrp then return end
        local best,bestD=nil,math.huge
        for _,plr in ipairs(PS:GetPlayers()) do
            if plr==LP then continue end
            if _sniperTarget~="Any" and plr.Name~=_sniperTarget then continue end
            if not plr.Backpack:FindFirstChild(HOG) then continue end
            local c=plr.Character; if not c then continue end
            local r=c:FindFirstChild("HumanoidRootPart"); local h=c:FindFirstChildOfClass("Humanoid")
            if not (r and h and h.Health>0) then continue end
            local d=(r.Position-hrp.Position).Magnitude
            if d<bestD then best=c; bestD=d end
        end
        return best
    end

    Opt.SniperSelect = MiscL5:Dropdown({
        Name="Target", Options={"Any"}, Default=1, Multi=false,
        Callback=function(v) _sniperTarget=type(v)=="table" and next(v) or (v or "Any") end
    }, "SniperSelect")
    MiscL5:Button({ Name="Scan Players", Callback=function()
        pcall(function()
            Opt.SniperSelect:ClearOptions()
            Opt.SniperSelect:InsertOptions(playersWithHog())
        end)
    end})
    Tog.HogyokuSniper = MiscL5:Toggle({
        Name="Hog Sniper", Default=false, Keybind=Enum.KeyCode.Unknown,
        Callback=function(p)
            farmState.plrs=p
            if _sniperConn then _sniperConn:Disconnect(); _sniperConn=nil end
            if p then _sniperConn=makeFarmLoop(nearestHogTarget,"plrs")
            else disableFarmCombat() end
        end
    }, "HogyokuSniper")

    MiscL5:Divider()

    Tog.HogNotifier = MiscL5:Toggle({
        Name="Hog Notifier", Default=false,
        Callback=function(p)
            if _notifConn then _notifConn:Disconnect(); _notifConn=nil end
            _notifSeen={}
            if not p then return end
            _notifConn=RS.Heartbeat:Connect(function()
                for _,plr in ipairs(PS:GetPlayers()) do
                    if plr==LP then continue end
                    if plr.Backpack:FindFirstChild(HOG) and not _notifSeen[plr.Name] then
                        _notifSeen[plr.Name]=true
                        notify(plr.Name.." has a Hogyoku Shard!",5)
                        -- refresh scan dropdown
                        pcall(function() Opt.SniperSelect:ClearOptions(); Opt.SniperSelect:InsertOptions(playersWithHog()) end)
                    elseif not plr.Backpack:FindFirstChild(HOG) then
                        _notifSeen[plr.Name]=nil
                    end
                end
            end)
        end
    }, "HogNotifier")

    onUnload(function()
        if _sniperConn then _sniperConn:Disconnect() end
        if _notifConn then _notifConn:Disconnect() end
    end)
end)()


MiscL4:Divider()
local _ownHighlights={}; local _ownVizConn=nil
local _ownedColor=Color3.fromRGB(0,255,0); local _notOwnedColor=Color3.fromRGB(255,0,0)
local function hasNetworkOwnership(part)
    if isnetworkowner then local ok,r=pcall(isnetworkowner,part); return ok and r end
    local ok,result=pcall(function()
        local myHRP2=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not myHRP2 then return false end
        local ok1,myId=pcall(gethiddenproperty,myHRP2,"NetworkOwnerV3"); local ok2,partId=pcall(gethiddenproperty,part,"NetworkOwnerV3")
        return ok1 and ok2 and myId~=nil and myId==partId
    end)
    return ok and result
end
local function updateOwnershipViz()
    for part,hl in pairs(_ownHighlights) do if not part or not part.Parent then pcall(function() hl:Destroy() end); _ownHighlights[part]=nil end end
    local ents=workspace:FindFirstChild("Living"); if not ents then return end
    for _,model in ipairs(ents:GetChildren()) do
        if not model:IsA("Model") then continue end
        local hrp2=model:FindFirstChild("HumanoidRootPart"); if not hrp2 then continue end
        if not _ownHighlights[hrp2] then local hl2=Instance.new("Highlight",model); hl2.FillTransparency=0.7; _ownHighlights[hrp2]=hl2 end
        local hl2=_ownHighlights[hrp2]
        local owned=pcall(hasNetworkOwnership,hrp2) and hasNetworkOwnership(hrp2)
        hl2.FillColor=owned and _ownedColor or _notOwnedColor
        hl2.OutlineColor=hl2.FillColor
    end
end
Tog.ShowOwnership = MiscL4:Toggle({
    Name="Show Ownership", Default=false,
    Callback=function(p)
        if p then
            if not _ownVizConn then _ownVizConn=RS.Heartbeat:Connect(function() if Tog.ShowOwnership and Tog.ShowOwnership.State then updateOwnershipViz() end end) end
        else
            if _ownVizConn then _ownVizConn:Disconnect(); _ownVizConn=nil end
            for _,hl2 in pairs(_ownHighlights) do pcall(function() hl2:Destroy() end) end; _ownHighlights={}
        end
    end
}, "ShowOwnership")
MiscL4:Divider()
Opt.OwnedColor    = MiscL4:Colorpicker({ Name="Owned Color",     Default=Color3.fromRGB(0,255,0), Alpha=0, Callback=function(c) _ownedColor=c    end }, "OwnedColor")
Opt.NotOwnedColor = MiscL4:Colorpicker({ Name="Not Owned Color", Default=Color3.fromRGB(255,0,0), Alpha=0, Callback=function(c) _notOwnedColor=c end }, "NotOwnedColor")
onUnload(function()
    if _ownVizConn then _ownVizConn:Disconnect() end
    for _,hl2 in pairs(_ownHighlights) do pcall(function() hl2:Destroy() end) end
end)


MiscR:Divider()
Tog.AutoClash = MiscR:Toggle({
    Name="Auto Clash", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            local function getClashEvent()
                for _,obj in ipairs(getnilinstances()) do if obj.Name=="ClashEvent" and obj:IsA("RemoteEvent") then return obj end end
            end
            while Tog.AutoClash and Tog.AutoClash.State do
                local living=workspace:FindFirstChild("Living"); local myModel=living and living:FindFirstChild(LP.Name)
                local status=myModel and myModel:FindFirstChild("Status")
                if status and (status:FindFirstChild("Clashing") or status:FindFirstChild("InGeki")) then
                    local ev=getClashEvent(); if ev then pcall(function() ev:FireServer(math.pi*0.8) end) end
                end
                task.wait(0.05)
            end
        end)
    end
}, "AutoClash")
Tog.AutoKidoChant = MiscR:Toggle({
    Name="Auto Kido Chant", Default=false,
    Callback=function(p)
        local chant=ReplicatedStorage.Requests:WaitForChild("ChantMinigame")
        if p then chant.OnClientInvoke=function() return true end else chant.OnClientInvoke=nil end
    end
}, "AutoKidoChant")
local _meditateConn=nil
Tog.AutoMeditate = MiscR:Toggle({
    Name="Auto Meditate", Default=false,
    Callback=function(p)
        if _meditateConn then _meditateConn:Disconnect(); _meditateConn=nil end
        if not p then return end
        _meditateConn=RS.Heartbeat:Connect(function()
            pcall(function()
                local living=workspace:FindFirstChild("Living"); if not living then return end
                local myModel=living:FindFirstChild(LP.Name); if not myModel then return end
                local s=myModel:FindFirstChild("Status"); if not s then return end
                if not s:FindFirstChild("Meditating") and not s:FindFirstChild("InCombat") then
                    local r=_getRemote("Meditate"); if r then r:FireServer() end
                end
            end)
        end)
    end
}, "AutoMeditate")
onUnload(function() if _meditateConn then _meditateConn:Disconnect() end end)
MiscR:Divider()
task.spawn(function()
    local _noCombatConn=nil; local _noCombatThread=nil
    Tog.NoCombatTag = MiscR:Toggle({
        Name="No Combat Tag", Default=false,
        Callback=function(p)
            if _noCombatConn then _noCombatConn:Disconnect(); _noCombatConn=nil end
            if _noCombatThread then task.cancel(_noCombatThread); _noCombatThread=nil end
            if not p then return end
            local CS=game:GetService("CollectionService")
            _noCombatConn=CS:GetInstanceAddedSignal("InCombat"):Connect(function(instance) if instance==LP then CS:RemoveTag(LP,"InCombat") end end)
            _noCombatThread=task.spawn(function() while true do if CS:HasTag(LP,"InCombat") then CS:RemoveTag(LP,"InCombat") end; task.wait(0.05) end end)
        end
    }, "NoCombatTag")
    onUnload(function() if _noCombatConn then _noCombatConn:Disconnect() end; if _noCombatThread then task.cancel(_noCombatThread) end end)
end)
MiscR:Divider()
;(function()
    local SP={conns={}}
    SP.RS=RS; SP.LP=LP
    SP.getLivStat=function() local living=workspace:FindFirstChild("Living"); if not living then return nil end; local m=living:FindFirstChild(LP.Name); if not m then return nil end; return m:FindFirstChild("Status") end
    SP.getCharStat=function() local c=LP.Character; if not c then return nil end; return c:FindFirstChild("Status") end
    SP.clearStatuses=function(statusFolder,nameList) if not statusFolder then return end; for _,name in ipairs(nameList) do local v=statusFolder:FindFirstChild(name); if v then pcall(function() v:Destroy() end) end end end
    Tog.NoFallDmg = MiscR2:Toggle({
        Name="No Fall Damage", Default=true,
        Callback=function(p)
            if SP.conns.fall then SP.conns.fall:Disconnect(); SP.conns.fall=nil end
            if p then
                pcall(function() _injectStatus("FallImmunity") end)
                SP.conns.fall=RS.Heartbeat:Connect(function() pcall(function() _injectStatus("FallImmunity") end) end)
            else pcall(function() _removeStatus("FallImmunity") end) end
end
    }, "NoFallDmg")
    Tog.NoStun = MiscR2:Toggle({
        Name="No Stun", Default=false,
        Callback=function(p)
            if SP.conns.stunHook  then SP.conns.stunHook:Disconnect();  SP.conns.stunHook=nil  end
            if SP.conns.stunSweep then SP.conns.stunSweep:Disconnect(); SP.conns.stunSweep=nil end
            if not p then return end
            local function hookStunStatus(s)
                if not s then return end
                SP.conns.stunHook=s.ChildAdded:Connect(function(child) if child.Name=="Stunned" or child.Name=="AttackingCanBlock" then task.defer(function() pcall(function() child:Destroy() end) end) end end)
                SP.clearStatuses(s,{"Stunned","AttackingCanBlock"})
            end
            hookStunStatus(SP.getLivStat())
            SP.conns.stunSweep=RS.Heartbeat:Connect(function() pcall(function() local s=SP.getLivStat(); SP.clearStatuses(s,{"Stunned","AttackingCanBlock"}); if not SP.conns.stunHook then hookStunStatus(s) end end) end)
        end
    }, "NoStun")
    Tog.NoRagdoll = MiscR2:Toggle({
        Name="No Ragdoll", Default=false,
        Callback=function(p)
            if SP.conns.ragdollHook  then SP.conns.ragdollHook:Disconnect();  SP.conns.ragdollHook=nil  end
            if SP.conns.ragdollState then SP.conns.ragdollState:Disconnect(); SP.conns.ragdollState=nil end
            if SP.conns.ragdollSweep then SP.conns.ragdollSweep:Disconnect(); SP.conns.ragdollSweep=nil end
            if not p then return end
            local function restoreChar(char)
                if not char then return end
                for _,bsc in ipairs(char:GetDescendants()) do
                    if bsc:IsA("BallSocketConstraint") then
                        local motorName=bsc.Name:gsub("SOCKET",""); local motor=bsc.Parent:FindFirstChild(motorName); local part0Val=bsc:FindFirstChild("Part0")
                        if motor and part0Val and part0Val.Value then pcall(function() motor.Part0=part0Val.Value end); pcall(function() bsc:Destroy() end) end
                    end
                end
                for _,v in ipairs(char:GetDescendants()) do if v:IsA("BasePart") and v.Name=="RAGDOLL_COLLIDER" then pcall(function() v:Destroy() end) end end
                local hum=char:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum.PlatformStand=false; hum.AutoRotate=true; hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false); hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false) end) end
            end
            local function hookRagdollStatus(s,char)
                if not s then return end
                SP.conns.ragdollHook=s.ChildAdded:Connect(function(child)
                    if child.Name=="Ragdoll" or child.Name=="Ragdolled" then task.defer(function() pcall(function() child:Destroy() end); restoreChar(char) end) end
                end)
                SP.clearStatuses(s,{"Ragdoll","Ragdolled"})
            end
            hookRagdollStatus(SP.getLivStat(),LP.Character)
            SP.conns.ragdollSweep=RS.Heartbeat:Connect(function()
                pcall(function() local s=SP.getLivStat(); SP.clearStatuses(s,{"Ragdoll","Ragdolled"}); if not SP.conns.ragdollHook then hookRagdollStatus(s,LP.Character) end end)
            end)
            SP.conns.ragdollState=LP.CharacterAdded:Connect(function(char) task.wait(0.5); hookRagdollStatus(SP.getLivStat(),char) end)
        end
    }, "NoRagdoll")
    onUnload(function()
        for _,c in pairs(SP.conns) do if c then pcall(function() c:Disconnect() end) end end
    end)
end)()

do
    local _hopConn=nil; local _hopRadius=20
    Tog.AutoHop = MiscR3:Toggle({ Name="Hop on Player Near", Default=false, Callback=function(p)
        if _hopConn then _hopConn:Disconnect(); _hopConn=nil end
        if not p then return end
        _hopConn=RS.Heartbeat:Connect(function()
            local char=LP.Character; if not char then return end
            local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            for _,plr in ipairs(PS:GetPlayers()) do
                if plr~=LP and plr.Character then
                    local orp=plr.Character:FindFirstChild("HumanoidRootPart")
                    if orp and (hrp.Position-orp.Position).Magnitude<=_hopRadius then
                        _hopConn:Disconnect(); _hopConn=nil
                        Tog.AutoHop:UpdateState(false)
                        serverHop(); return
                    end
                end
            end
        end)
    end }, "AutoHop")
    Opt.HopRadius = MiscR3:Slider({ Name="Radius", Default=20, Minimum=5, Maximum=150, Precision=0, Callback=function(v) _hopRadius=v end }, "HopRadius")
    onUnload(function() if _hopConn then _hopConn:Disconnect(); _hopConn=nil end end)
end




do
    local MiscTutorial = Tabs.Misc:Section({ Side="Left", Name="Auto Tutorial", Image="book-open" })
    Tog.AutoTutorial = MiscTutorial:Toggle({ Name="Auto Tutorial Skip", Default=false,
        Callback=function(p)
            if p then
                task.spawn(function()


local cref = cloneref or function(o) return o end
local gameRef = cref(game)

local function getService(name)
	return cref(gameRef:GetService(name))
end

local Players    = getService("Players")
local RS         = getService("ReplicatedStorage")
local RunService = getService("RunService")
local CS         = getService("CollectionService")

local lp       = cref(Players.LocalPlayer)
local Requests = RS:WaitForChild("Requests")
local WS       = cref(workspace)

if getgenv().FA_Tutorial then
	pcall(function() getgenv().FA_Tutorial._stop() end)
end

local _active = true
local function stopped() return not _active end

getgenv().FA_Tutorial = {
	_stop = function()
		_active = false
	end
}

local function wait_until(fn, timeout, interval)
	timeout  = timeout  or 60
	interval = interval or 0.25
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		if stopped() then return false end
		local ok, v = pcall(fn)
		if ok and v then return true end
		task.wait(interval)
	end
	return false
end

local function getChar()
	return (WS:FindFirstChild("Living") and WS.Living:FindFirstChild(lp.Name))
		or lp.Character
end

local _vim
local function getVIM()
	if _vim then return _vim end
	local ok, inst = pcall(Instance.new, "VirtualInputManager")
	if ok and inst and type(inst.SendMouseButtonEvent) == "function" then
		_vim = cref(inst)
		return _vim
	end
	return nil
end

local function vimM1(x, y)
	local vim = getVIM()
	if not vim then return end
	x, y = x or 0, y or 0
	pcall(function() vim:SendMouseButtonEvent(x, y, 0, true,  gameRef, 0) end)
	task.wait(0.04)
	pcall(function() vim:SendMouseButtonEvent(x, y, 0, false, gameRef, 0) end)
end

local function vimKey(keyCode)
	local vim = getVIM()
	if not vim then return end
	pcall(function() vim:SendKeyEvent(true,  keyCode, false, gameRef, 0) end)
	task.wait(0.05)
	pcall(function() vim:SendKeyEvent(false, keyCode, false, gameRef, 0) end)
end

local function fireOptionButton(btn)
	if not btn or not btn:IsA("GuiObject") then return end
	pcall(function()
		if getconnections then
			for _, sig in ipairs({ "MouseButton1Click", "Activated", "MouseButton1Down", "MouseButton1Up" }) do
				local ev = btn[sig]
				if ev then
					for _, c in ipairs(getconnections(ev)) do
						c:Fire()
					end
				end
			end
		end
	end)
	if btn:IsA("GuiButton") then
		pcall(function() btn:Activate() end)
	end
	local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		local parent = btn.Parent
		if parent and parent:IsA("GuiObject") then
			pos, size = parent.AbsolutePosition, parent.AbsoluteSize
		end
	end
	if size.X > 0 and size.Y > 0 then
		vimM1(pos.X + size.X * 0.5, pos.Y + size.Y * 0.5)
	end
end

local function fireGui(btn)
	if not btn then return end
	fireOptionButton(btn)
end

local function clickGui(btn)
	if not btn or not btn:IsA("GuiObject") then return end
	if not btn.Visible then return end
	local pos  = btn.AbsolutePosition
	local size = btn.AbsoluteSize
	if size.X > 0 and size.Y > 0 then
		vimM1(pos.X + size.X * 0.5, pos.Y + size.Y * 0.5)
	end
	fireOptionButton(btn)
end

local function spamM1(duration)
	local t0 = os.clock()
	while os.clock() - t0 < duration do
		if stopped() then return end
		vimM1(0, 0)
		task.wait(0.15)
	end
end

local function getDeathScreen()
	local pg   = lp:FindFirstChild("PlayerGui")
	local main = pg   and pg:FindFirstChild("MainUI")
	local hud  = main and main:FindFirstChild("HUDContainer")
	return hud and hud:FindFirstChild("DeathScreen")
end

local function clickDeathScreenButtons()
	local ds = getDeathScreen()
	if not ds or not ds.Visible then return end

	local options = ds:FindFirstChild("Options")
	if options then
		for _, child in ipairs(options:GetChildren()) do
			if child.Name == "Template" or not child:IsA("GuiObject") then
				continue
			end
			if not child.Visible then continue end
			local locked = child:FindFirstChild("Locked")
			if locked and locked:IsA("GuiObject") and locked.Visible then
				continue
			end
			local tb = child:FindFirstChild("TextButton")
			if tb and tb:IsA("GuiButton") then clickGui(tb) end
			local cn = child:FindFirstChild("CharacterName")
			if cn and cn:IsA("GuiButton") then clickGui(cn) end
		end
	end

	local timer = ds:FindFirstChild("RespawnTimer")
	if timer and timer:IsA("GuiObject") and timer.Visible then
		clickGui(timer)
	end
end

local function waitForDeathScreen(timeout)
	return wait_until(function()
		local ds = getDeathScreen()
		return ds and ds.Visible
	end, timeout or 15, 0.1)
end

local function isAlive()
	local char = getChar()
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0
end

local function waitForRespawn(timeout)
	timeout = timeout or 60
	return wait_until(function()
		local ds = getDeathScreen()
		if ds and ds.Visible then return false end
		return isAlive()
	end, timeout, 0.2)
end

local function touchPart(part)
	if not part then return false end
	local root = getChar()
	root = root and root:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local bp = part
	if part.Name == "TouchInterest" or part.ClassName == "TouchInterest" then
		bp = part.Parent
	end
	if not bp or not bp:IsA("BasePart") then return false end
	local fn = firetouchinterest or fireTouchInterest
	if type(fn) ~= "function" then return false end
	pcall(fn, root, bp, 0)
	task.wait(0.1)
	pcall(fn, root, bp, 1)
	return true
end

local function interactNPC(name)
	local folder = WS:FindFirstChild("DialogueInteractables")
	local model  = folder and folder:FindFirstChild(name)
	if not model then return false end
	local pp = model:FindFirstChild("ProximityPrompt", true)
	if pp then
		pcall(function()
			if type(fireproximityprompt) == "function" then
				fireproximityprompt(pp, 0)
			else
				pp:InputHoldBegin()
				task.wait(0.05)
				pp:InputHoldEnd()
			end
		end)
	end
	pcall(function()
		Requests.Interactable_Interact:FireServer(model)
	end)
	task.wait(1.2)
	return true
end

local function getDialogue()
	local pg   = lp:FindFirstChild("PlayerGui")
	local main = pg   and pg:FindFirstChild("MainUI")
	local hud  = main and main:FindFirstChild("HUDContainer")
	return hud and hud:FindFirstChild("Dialogue")
end

local function getOptionFrame()
	local dlg = getDialogue()
	return dlg and dlg:FindFirstChild("OptionFrame")
end

local function normalizeLabelText(label)
	if not label or not label:IsA("TextLabel") then return "" end
	return (label.Text or label.ContentText or ""):gsub("%s+", " "):lower():match("^%s*(.-)%s*$") or ""
end

-- OptionFrame.ResponseTemplate where Label.Text == "2. No" -> fire sibling Button
local function findNoOptionButton()
	local frame = getOptionFrame()
	if not frame then return nil end

	for _, template in ipairs(frame:GetChildren()) do
		if template.Name ~= "ResponseTemplate" then continue end
		local label = template:FindFirstChild("Label")
		if not label or not label:IsA("TextLabel") then continue end
		local txt = normalizeLabelText(label)
		if txt ~= "2. no" then continue end
		local btn = template:FindFirstChild("Button")
		if btn and (btn:IsA("GuiButton") or btn:IsA("ImageButton") or btn:IsA("TextButton")) then
			return btn
		end
	end

	return nil
end

local function clickNoOption(btn)
	btn = btn or findNoOptionButton()
	if not btn then return false end
	fireOptionButton(btn)
	vimKey(Enum.KeyCode.Two)
	return true
end

local function burstNoOption(btn)
	btn = btn or findNoOptionButton()
	if not btn then return end
	for _ = 1, 8 do
		fireOptionButton(btn)
		task.wait(0.02)
	end
	vimKey(Enum.KeyCode.Two)
end

-- always on Heartbeat poll: death screen -> respawn -> dialogue -> instant 2.No -> m1 spam
local function runPostDeathLoop(timeout)
	timeout = timeout or 120
	local noFired = false
	local t0 = os.clock()
	local lastM1 = 0
	local conn

	conn = RunService.Heartbeat:Connect(function()
		if stopped() or os.clock() - t0 >= timeout then
			conn:Disconnect()
			return
		end

		local ds = getDeathScreen()
		if ds and ds.Visible then
			clickDeathScreenButtons()
		end

		local btn = findNoOptionButton()
		if btn then
			if not noFired then
				noFired = true
				clickNoOption(btn)
				task.spawn(function() burstNoOption(btn) end)
			else
				fireOptionButton(btn)
			end
		end

		local now = os.clock()
		local m1Gap = noFired and 0.05 or 0.1
		if now - lastM1 >= m1Gap then
			vimM1(0, 0)
			lastM1 = now
		end

		if noFired and not findNoOptionButton() and not dialogueStillOpen() then
			conn:Disconnect()
		end
	end)

	while conn.Connected and os.clock() - t0 < timeout do
		if stopped() then break end
		task.wait(0.1)
	end

	if conn.Connected then conn:Disconnect() end
end

local function dialogueStillOpen()
	local dlg = getDialogue()
	return dlg and dlg.Visible
end

local function waitForLostSpirit()
	return wait_until(function()
		local char = getChar()
		if not char then return false end
		local head = char:FindFirstChild("Head")
		local hrp  = char:FindFirstChild("HumanoidRootPart")
		local hum  = char:FindFirstChildOfClass("Humanoid")
		if not head or not hrp or not hum then return false end
		if hum.Health <= 0 then return false end
		if head.Material ~= Enum.Material.ForceField then return false end
		if not CS:HasTag(char, "Loaded") then return false end
		return true
	end, 120, 0.3)
end

local function run()
	if not waitForLostSpirit() then return end

	for _, name in ipairs({ "TutorialTip1", "TutorialTip2", "TutorialTip3", "Francis" }) do
		if stopped() then return end
		interactNPC(name)
	end

	if stopped() then return end

	local meteor = WS.Debris:FindFirstChild("GelumMeteorTrigger")
	local border = WS.Debris:FindFirstChild("BossBorderActivation")

	if meteor then touchPart(meteor) end
	task.wait(0.5)
	if border then touchPart(border) end

	local gelumFound = wait_until(function()
		return WS.Living:FindFirstChild("Gelum") ~= nil
	end, 90, 0.25)

	if not gelumFound then
		if meteor then touchPart(meteor) end
		task.wait(0.3)
		if border then touchPart(border) end
		gelumFound = wait_until(function()
			return WS.Living:FindFirstChild("Gelum") ~= nil
		end, 60, 0.25)
	end

	if not gelumFound then return end

	task.wait(8)

	pcall(function()
		if replicatesignal and lp.Kill then
			replicatesignal(lp.Kill)
		end
	end)
	task.wait(0.3)

	spamM1(5)
	runPostDeathLoop(120)
end

task.spawn(run)

                end)
                notify("Tutorial skip started", 3)
            else
                pcall(function() if getgenv().FA_Tutorial then getgenv().FA_Tutorial._stop() end end)
                notify("Tutorial skip stopped", 3)
            end
        end
    }, "AutoTutorial")
    onUnload(function() pcall(function() if getgenv().FA_Tutorial then getgenv().FA_Tutorial._stop() end end) end)
end


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
MacLib:SetFolder("ZeroHub/configs")
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


task.spawn(function()
    if not getgenv()._ZH_AP then getgenv()._ZH_AP = {} end
    local AP = getgenv()._ZH_AP
    AP.Players    = PS
    AP.RunSvc     = RS
    AP.CoreGui    = game:GetService("CoreGui")
    AP.UIS        = UIS
    AP.Debris     = game:GetService("Debris")
    AP.lp         = LP
    AP.Controls   = nil; pcall(function() AP.Controls=require(game:GetService("ReplicatedStorage").SharedModules.ControlHandler) end)
    AP.timings      = AP.timings      or {}
    AP.savedTimings = AP.savedTimings or {}
    AP.activeTriggers = AP.activeTriggers or {}
    AP.animCooldowns  = AP.animCooldowns  or {}
    AP.watchedAnims   = AP.watchedAnims   or {}
    AP.posHistory     = AP.posHistory     or {}
    AP.loggedAnims    = {}  -- always reset so re-execution sees fresh mobs
    AP.loggedMap      = {}  -- always reset so re-execution sees fresh mobs
    AP.conns          = AP.conns          or {}
    AP.whitelist      = AP.whitelist      or {}
    AP.logBlacklist   = AP.logBlacklist   or {}
    AP.parryCD   = false
    AP.lastParry = 0
    AP.lastDodge = 0

    AP.TIMINGS_FILE = "ZeroHub/ap_timings.json"

    AP.WHITE = Color3.fromRGB(255,255,255)
    AP.DIM   = Color3.fromRGB(180,180,180)
    AP.HINT  = Color3.fromRGB(100,100,100)
    AP.BORD  = Color3.fromRGB(255,255,255)
    AP.ACC   = Color3.fromRGB(138,79,255)
    AP.GREEN = Color3.fromRGB(138,79,255)
    AP.BG    = Color3.fromRGB(15,15,15)
    AP.CARD  = Color3.fromRGB(22,22,22)
    AP.FONT  = Enum.Font.GothamMedium
    AP.FONT_FACE = Font.new("rbxassetid://12187365364")

    local _AP_DEFAULTS = {["rbxassetid://14071703407"]={d=0.755,m=45.9},["rbxassetid://102209137660745"]={d=0.5,m=85.0},["rbxassetid://83845561115126"]={d=0.8,m=155.0,a="Counter",DD="Counter"},["rbxassetid://131948862232554"]={d=0.55,m=85.9,R=2,RD=0.2},["rbxassetid://76408620562507"]={d=0.52,m=155.0},["rbxassetid://87538964089411"]={d=0.97,m=155.0},["rbxassetid://123716588791139"]={d=1.11,m=155.0,R=2,RD=0.9},["rbxassetid://119044608330966"]={d=0.33,m=85.0},["rbxassetid://107665358601410"]={d=0.4,m=155.0},["rbxassetid://100918285736290"]={d=0.8,m=155.0,a="Dodge"},["rbxassetid://111458184388856"]={d=0.46,m=155.0},["rbxassetid://82358037666428"]={d=0.75,m=155.0},["rbxassetid://82208537198225"]={d=0.4,m=155.0},["rbxassetid://17139363450"]={d=0.25,m=155.0,a="Dodge",DD="Backward"},["rbxassetid://18216211089"]={d=0.33,m=85.9},["rbxassetid://17164100610"]={d=0.6,m=155.0,a="Dodge"},["rbxassetid://14071657488"]={d=0.425,m=45.9},["rbxassetid://114970955237325"]={d=0.55,m=85.9},["rbxassetid://126131534219589"]={d=0.96,m=155.0},["rbxassetid://96588462841509"]={d=0.345,m=85.9},["rbxassetid://14242178912"]={d=0.68,m=155.0},["rbxassetid://120555974534750"]={d=0.39,m=85.9},["rbxassetid://14070514579"]={d=0.35,m=96.0},["rbxassetid://88502759164358"]={d=1.25,m=85.0},["rbxassetid://17389534922"]={d=0.61,m=85.0},["rbxassetid://115338865375824"]={d=0.52,m=85.9},["rbxassetid://121894488404971"]={d=1.05,m=75.9},["rbxassetid://14069271130"]={d=0.1,m=85.0},["rbxassetid://14071268751"]={d=0.71,m=85.0},["rbxassetid://115495827589598"]={d=1.38,m=85.0},["rbxassetid://83118719637202"]={d=1.2,m=155.0},["rbxassetid://113482097227296"]={d=0.6,m=355.0},["rbxassetid://17799541604"]={d=0.56,m=85.9},["rbxassetid://14069935839"]={d=0.385,m=85.9},["rbxassetid://17732755849"]={d=0.55,m=85.0},["rbxassetid://117433677744400"]={d=0.32,m=85.0},["rbxassetid://124559676483896"]={d=0.345,m=85.9},["rbxassetid://108402061040328"]={d=0.62,m=85.9},["rbxassetid://140223371973489"]={d=0.8,m=155.0},["rbxassetid://14070207166"]={d=0.36,m=85.9},["rbxassetid://97222680543132"]={d=0.48,m=125.0},["rbxassetid://18212119639"]={d=1.3,m=155.0},["rbxassetid://13835138543"]={d=0.37,m=155.0},["rbxassetid://81126939104199"]={d=0,m=85.0,a="Dodge Forward",DD="Forward"},["rbxassetid://100232105166419"]={d=0.86,m=155.0},["rbxassetid://14071654671"]={d=0.467,m=65.9},["rbxassetid://16417803802"]={d=0.45,m=85.0},["rbxassetid://118809616230577"]={d=0.345,m=85.9},["rbxassetid://121072695683680"]={d=0.47,m=155.0},["rbxassetid://12130625590"]={d=0.9,m=155.0},["rbxassetid://14069224323"]={d=0.47,m=50.0,a="Dodge",DD="Backward",SD=0.295,MA=true},["rbxassetid://13839637848"]={d=0.52,m=85.9},["rbxassetid://18100571274"]={d=0.38,m=85.9},["rbxassetid://14071640490"]={d=0.767,m=70.9},["rbxassetid://110620209403887"]={d=0.54,m=155.0},["rbxassetid://18227540151"]={d=0.34,m=85.9},["rbxassetid://134906714771353"]={d=0.51,m=85.0},["rbxassetid://118925530415750"]={d=0.46,m=155.0},["rbxassetid://14071644383"]={d=0.6,m=45.9},["rbxassetid://17797537608"]={d=0.45,m=155.0},["rbxassetid://14071712668"]={d=1.48,m=200.9},["rbxassetid://134281749755415"]={d=0.5,m=155.0},["rbxassetid://17635242780"]={d=1.63,m=265.5},["rbxassetid://98238404943510"]={d=0.38,m=155.0},["rbxassetid://14071698381"]={d=1.05,m=225.0},["rbxassetid://115246475163144"]={d=0.7,m=155.9,a="Dodge",DD="Right"},["rbxassetid://14071614685"]={d=0.395,m=48.0},["rbxassetid://242076158"]={d=0.85,m=65.0},["rbxassetid://80432589993088"]={d=2.0,m=155.0,a="Dodge"},["rbxassetid://88261348097917"]={d=0.42,m=85.9},["rbxassetid://104856245052955"]={d=0.68,m=155.0},["rbxassetid://17384025359"]={d=0.52,m=85.0},["rbxassetid://11324326957"]={d=0.55,m=155.0},["rbxassetid://14071548275"]={d=0.515,m=25.9},["rbxassetid://14071801422"]={d=0.425,m=50.0,SD=0.5,MA=true},["rbxassetid://81948214903930"]={d=2.25,m=155.0},["rbxassetid://77221013526883"]={d=0.2,m=85.9,FB=true},["rbxassetid://14071797324"]={d=0.415,m=105.9},["rbxassetid://14071571850"]={d=0.6,m=100.0},["rbxassetid://94697228325859"]={d=0.475,m=85.0},["rbxassetid://129087511219728"]={d=0.25,m=85.9},["rbxassetid://14069933789"]={d=0.385,m=85.9},["rbxassetid://14070310188"]={d=0.6,m=140.0,FB=true},["rbxassetid://14070502124"]={d=0.56,m=75.9},["rbxassetid://95990465493386"]={d=0.75,m=155.0},["rbxassetid://11130826551"]={d=0.83,m=85.9},["rbxassetid://98251084212732"]={d=1.32,m=155.0},["rbxassetid://17891445162"]={d=0.45,m=155.0},["rbxassetid://102813187141061"]={d=1.0,m=85.0},["rbxassetid://14070165536"]={d=0.38,m=85.9},["rbxassetid://123903488088917"]={d=6.0,m=355.0},["rbxassetid://14070287232"]={d=0.367,m=85.9},["rbxassetid://85051757500909"]={d=0.17,m=85.0},["rbxassetid://72352073483435"]={d=0.44,m=85.9},["rbxassetid://16749240878"]={d=0.37,m=85.9},["rbxassetid://17150140878"]={d=0.43,m=85.0},["rbxassetid://14071267348"]={d=0.343,m=85.9},["rbxassetid://120995953643120"]={d=0.95,m=155.0},["rbxassetid://137122650392334"]={d=0.9,m=85.9},["rbxassetid://14774660926"]={d=1.1,m=155.0},["rbxassetid://14071106531"]={d=0.46,m=95.9},["rbxassetid://79135580829944"]={d=0.7,m=155.0,R=2,RD=0.85},["rbxassetid://13838989601"]={d=0.7,m=85.0},["rbxassetid://119744649456014"]={d=0.49,m=85.9},["rbxassetid://116747075490261"]={d=0.2,m=90.0,a="Dodge",DD="Backward",R=10,RD=0.15},["rbxassetid://91983451624365"]={d=0.54,m=155.0},["rbxassetid://126037393769736"]={d=1.15,m=85.0},["rbxassetid://81357129424702"]={d=0.44,m=64.0},["rbxassetid://126795164668224"]={d=0.345,m=85.9},["rbxassetid://91370102211257"]={d=0.45,m=85.0},["rbxassetid://105054906074054"]={d=0.85,m=85.9,R=2},["rbxassetid://71344941441736"]={d=0.2,m=85.0,a="Dodge",DD="Backward"},["rbxassetid://84523300592719"]={d=0.5,m=155.0},["rbxassetid://111873467408104"]={d=0.48,m=155.0},["rbxassetid://133971760638507"]={d=0.81,m=85.0,a="Dodge",DD="Right"},["rbxassetid://85652792138826"]={d=0.65,m=85.9},["rbxassetid://129929048368854"]={d=0.71,m=155.0},["rbxassetid://17070474389"]={d=1.25,m=155.0},["rbxassetid://127273322918288"]={d=1.65,m=85.9},["rbxassetid://14068997392"]={d=0.42,m=85.9,TD=25},["rbxassetid://13912077428"]={d=0.46,m=155.0},["rbxassetid://86288682164163"]={d=0.8,m=155.0},["rbxassetid://14071708829"]={d=0.682,m=170.0,a="Dodge Forward",DD="Forward"},["rbxassetid://140290004738395"]={d=0.45,m=155.0},["rbxassetid://109175080835575"]={d=0.51,m=85.9},["rbxassetid://13913720963"]={d=0.62,m=155.0,a="Counter",DD="Counter"},["rbxassetid://98889835047651"]={d=0.48,m=155.0},["rbxassetid://14071599225"]={d=0.74,m=150.0},["rbxassetid://14070467433"]={d=0.367,m=85.9},["rbxassetid://130503867267860"]={d=0.27,m=155.9,R=3,RD=0.345},["rbxassetid://14071690484"]={d=0.388,m=85.9,R=2,RD=0.42},["rbxassetid://14070913872"]={d=0.35,m=85.0},["rbxassetid://15292355772"]={d=0.45,m=85.0,R=3,RD=0.6},["rbxassetid://11361697224"]={d=0.45,m=85.9},["rbxassetid://129343427417751"]={d=0.7,m=155.0},["rbxassetid://14071652427"]={d=0.5,m=45.9},["rbxassetid://77232950889467"]={d=0.9,m=55.0},["rbxassetid://16760430281"]={d=1.4,m=85.9,FB=true,RD=3.5},["rbxassetid://86790480323481"]={d=0.5,m=85.0},["rbxassetid://101692991762744"]={d=0.58,m=85.0},["rbxassetid://14295044446"]={d=0.55,m=155.0},["rbxassetid://105441075909070"]={d=0.55,m=85.9},["rbxassetid://121903551026415"]={d=0.55,m=155.0},["rbxassetid://129075747508051"]={d=0.13,m=85.9},["rbxassetid://80503383167824"]={d=0.5,m=155.0},["rbxassetid://14070515867"]={d=0.35,m=96.0},["rbxassetid://14071595510"]={d=0.1,m=70.0,RD=0.0,TD=70},["rbxassetid://125731355555983"]={d=0.9,m=155.0},["rbxassetid://75729004732047"]={d=1.3,m=60.0},["rbxassetid://17165722027"]={d=0.52,m=155.0},["rbxassetid://14069126339"]={d=0.44,m=85.9},["rbxassetid://80983604006772"]={d=0.577,m=85.0},["rbxassetid://95861963574403"]={d=0.23,m=85.9},["rbxassetid://103578292653211"]={d=0.75,m=155.0},["rbxassetid://138199113509312"]={d=0.37,m=129.0,TD=30},["rbxassetid://115140436410496"]={d=0.49,m=155.0},["rbxassetid://17165710737"]={d=0.52,m=155.0},["rbxassetid://16669192163"]={d=0.81,m=85.0},["rbxassetid://14069440034"]={d=0.42,m=25.0,a="Dodge",DD="Backward",TD=15},["rbxassetid://106755593162256"]={d=0.65,m=95.9,a="Dodge",DD="Right"},["rbxassetid://139737111340430"]={d=0.42,m=85.0},["rbxassetid://74259506691554"]={d=0.247,m=32.0},["rbxassetid://92726072580750"]={d=0.3,m=85.0},["rbxassetid://17154401086"]={d=0.46,m=155.0},["rbxassetid://11361464104"]={d=0.45,m=85.9},["rbxassetid://15325122671"]={d=0.715,m=175.9},["rbxassetid://96020812931018"]={d=0.56,m=85.0},["rbxassetid://14089184318"]={d=0.55,m=85.0},["rbxassetid://104694319353269"]={d=0.44,m=85.0},["rbxassetid://106707347714801"]={d=1.14,m=155.0,a="Dodge"},["rbxassetid://127232666335591"]={d=0.42,m=85.9},["rbxassetid://108322405941111"]={d=0.53,m=85.9},["rbxassetid://129772250557967"]={d=0.2,m=85.0},["rbxassetid://15294979898"]={d=0.65,m=155.0},["rbxassetid://14071681337"]={d=0.2,m=121.0,a="Dodge",DD="Backward",R=3,RD=0.1,TD=25.1},["rbxassetid://134536112580394"]={d=0.75,m=85.0},["rbxassetid://14069942258"]={d=0.385,m=85.9},["rbxassetid://14069991336"]={d=0.55,m=85.0},["rbxassetid://82297694940107"]={d=0.43,m=85.0},["rbxassetid://108362353709475"]={d=0.7,m=85.0},["rbxassetid://14321472472"]={d=0.5,m=155.0},["rbxassetid://14110203809"]={d=1.15,m=155.0},["rbxassetid://122969699986265"]={d=0.5,m=155.0},["rbxassetid://14071798998"]={d=0.72,m=75.9},["rbxassetid://110940320473628"]={d=0.36,m=85.9},["rbxassetid://81281779521042"]={d=0.51,m=85.9},["rbxassetid://128442405437130"]={d=0.1657,m=44.5,RD=0.1},["rbxassetid://14071717687"]={d=0.2,m=85.0,a="Dodge",DD="Backward",R=4,RD=0.1},["rbxassetid://16874792738"]={d=0.51,m=155.0,a="Dodge"},["rbxassetid://125555789564402"]={d=0.5,m=35.0,R=2,RD=0.92},["rbxassetid://89621003793324"]={d=0.35,m=85.9},["rbxassetid://133407056421612"]={d=0.95,m=155.0,a="Dodge",DD="Right"},["rbxassetid://116049660693261"]={d=0.4,m=155.0},["rbxassetid://131531097390532"]={d=0.565,m=85.9},["rbxassetid://140143377555139"]={d=0.75,m=85.9},["rbxassetid://14070466276"]={d=0.367,m=85.9},["rbxassetid://14071283646"]={d=0.34,m=85.9},["rbxassetid://14070276168"]={d=0.35,m=85.9},["rbxassetid://14069241762"]={d=0.327,m=85.9},["rbxassetid://85281995413999"]={d=0.34,m=85.9,TD=20},["rbxassetid://97204612494471"]={d=0.75,m=45.9,a="Dodge",DD="Right"},["rbxassetid://118676062823815"]={d=0.25,m=85.0},["rbxassetid://4953054079"]={d=0.75,m=65.0},["rbxassetid://128776740703837"]={d=0.32,m=85.9,RD=0.3},["rbxassetid://16916034284"]={d=0.76,m=110.0},["rbxassetid://127467965933909"]={d=0.26,m=85.9},["rbxassetid://17386520462"]={d=0.6,m=155.0},["rbxassetid://14071813841"]={d=0.3,m=25.9},["rbxassetid://14070210472"]={d=0.36,m=85.9},["rbxassetid://72903085433723"]={d=1.0,m=115.0},["rbxassetid://130867999752530"]={d=0.45,m=155.0},["rbxassetid://89350742361115"]={d=0.565,m=85.0},["rbxassetid://14411112489"]={d=0.9,m=85.0},["rbxassetid://76447568872156"]={d=0.49,m=85.0},["rbxassetid://89020106755004"]={d=0.467,m=85.9},["rbxassetid://93437441193278"]={d=0.97,m=85.0},["rbxassetid://120108509419137"]={d=0.7,m=85.0},["rbxassetid://85733968676546"]={d=1.1,m=155.0},["rbxassetid://14040293266"]={d=0.47,m=85.0},["rbxassetid://85599301703737"]={d=0.47,m=85.0},["rbxassetid://74676987861261"]={d=0.37,m=85.9},["rbxassetid://93604577018528"]={d=0.48,m=85.0},["rbxassetid://127035949667623"]={d=0.35,m=85.0},["rbxassetid://131174800505496"]={d=0.67,m=155.0},["rbxassetid://94789046961279"]={d=0.1,m=25.9,FB=true},["rbxassetid://139579159639413"]={d=0.37,m=65.0},["rbxassetid://14071685205"]={d=0.53,m=85.9},["rbxassetid://119333842262474"]={d=0.52,m=85.9},["rbxassetid://137401035174373"]={d=0.86,m=155.0},["rbxassetid://14070208109"]={d=0.36,m=85.9},["rbxassetid://100399765010279"]={d=0.75,m=85.9},["rbxassetid://139921399810889"]={d=0.25,m=85.0},["rbxassetid://88897668319799"]={d=1.15,m=85.0},["rbxassetid://93244733898052"]={d=0.4,m=155.0},["rbxassetid://87482526599421"]={d=0.4,m=85.9,FB=true,MA=true},["rbxassetid://14071419173"]={d=0.86,m=155.0,RD=0.85},["rbxassetid://104296721489281"]={d=0.49,m=155.0},["rbxassetid://127367360034401"]={d=0.65,m=155.0},["rbxassetid://109741257019603"]={d=0.55,m=85.9},["rbxassetid://88553317021063"]={d=0.35,m=85.0},["rbxassetid://9834199222"]={d=0.73,m=155.0},["rbxassetid://17429351656"]={d=0.46,m=155.0},["rbxassetid://134030338249685"]={d=0.46,m=85.9,TD=30},["rbxassetid://14071642506"]={d=0.795,m=155.9},["rbxassetid://16813404274"]={d=0.53,m=155.0},["rbxassetid://80651761610614"]={d=0.8,m=155.0},["rbxassetid://17606123405"]={d=0.03,m=50.0,MA=true,TD=23},["rbxassetid://17891436342"]={d=0.45,m=155.0},["rbxassetid://13959320065"]={d=0.15,m=85.0},["rbxassetid://14069239027"]={d=0.327,m=85.9},["rbxassetid://91657425744872"]={d=0.8,m=155.0},["rbxassetid://17379729903"]={d=0.2,m=100.9,a="Dodge",DD="Backward",R=6,RD=0.1},["rbxassetid://106481421699123"]={d=0.55,m=85.9},["rbxassetid://17165716229"]={d=0.52,m=155.0},["rbxassetid://17377962445"]={d=1.3,m=155.0},["rbxassetid://106024374850709"]={d=0.7,m=85.0},["rbxassetid://130828418546825"]={d=0.65,m=85.9},["rbxassetid://16914044613"]={d=0.305,m=155.9},["rbxassetid://126027419442216"]={d=1.6,m=155.0,a="Counter",DD="Counter"},["rbxassetid://14071795665"]={d=0.42,m=55.9},["rbxassetid://17836796987"]={d=0.32,m=95.0},["rbxassetid://105242552416030"]={d=0.44,m=85.0},["rbxassetid://100480352106961"]={d=0.22,m=45.9,TD=15},["rbxassetid://17891409381"]={d=0.46,m=155.0},["rbxassetid://71922325917635"]={d=0.55,m=155.0},["rbxassetid://14070910344"]={d=0.35,m=85.0},["rbxassetid://17438387812"]={d=0.33,m=85.9},["rbxassetid://80778758544772"]={d=0.51,m=75.9},["rbxassetid://17759824327"]={d=0.56,m=155.0},["rbxassetid://14069938678"]={d=0.385,m=85.9},["rbxassetid://122680227249211"]={d=0.42,m=85.9},["rbxassetid://76587771013330"]={d=0.75,m=155.0},["rbxassetid://131379644960537"]={d=0.35,m=85.9},["rbxassetid://90193916772797"]={d=1.108,m=95.9},["rbxassetid://70797365741544"]={d=0.38,m=85.0},["rbxassetid://92718849009328"]={d=0.43,m=31.5},["rbxassetid://93227313880429"]={d=1.82,m=155.0},["rbxassetid://14070284327"]={d=0.367,m=85.9},["rbxassetid://131208019886712"]={d=0.31,m=85.9},["rbxassetid://81841736775961"]={d=0.95,m=155.0},["rbxassetid://14070072624"]={d=0.37,m=85.9},["rbxassetid://16932406623"]={d=0.8,m=85.0},["rbxassetid://136421047195977"]={d=1.5,m=85.0},["rbxassetid://106323240907104"]={d=0.53,m=155.0},["rbxassetid://114673758853916"]={d=0.27,m=60.0,SD=0.315,MA=true,TD=7},["rbxassetid://86139988631532"]={d=0.42,m=85.9},["rbxassetid://14069170145"]={d=0.315,m=85.9,a="Dodge",DD="Backward"},["rbxassetid://81155234848931"]={d=1.05,m=85.9},["rbxassetid://136816311133870"]={d=1.65,m=85.9},["rbxassetid://15492898099"]={d=0.68,m=85.9},["rbxassetid://139107338108722"]={d=0.35,m=85.0},["rbxassetid://16417788544"]={d=0.45,m=85.0},["rbxassetid://82636526806960"]={d=0.345,m=85.9},["rbxassetid://107341319270768"]={d=1.21,m=155.0},["rbxassetid://15560352579"]={d=0.4,m=85.0},["rbxassetid://102248870664763"]={d=0.39,m=85.9},["rbxassetid://14069237877"]={d=0.327,m=85.9},["rbxassetid://17440095233"]={d=0.33,m=85.9},["rbxassetid://79069029683112"]={d=0.6,m=85.9},["rbxassetid://83450269786196"]={d=0.65,m=85.0},["rbxassetid://17096102205"]={d=0.34,m=85.9,R=3,RD=0.335},["rbxassetid://14071818194"]={d=0.45,m=100.0,SD=0.45,RD=0.0,TD=24},["rbxassetid://6950979119"]={d=0.75,m=45.0},["rbxassetid://14024378591"]={d=1.4,m=155.0},["rbxassetid://90110426533114"]={d=0.57,m=85.0},["rbxassetid://17393090779"]={d=0.765,m=100.9},["rbxassetid://90883933480570"]={d=0.5,m=85.0},["rbxassetid://73253387909359"]={d=0.55,m=155.0},["rbxassetid://14071563707"]={d=0.42,m=50.0,SD=0.37,MA=true,TD=15},["rbxassetid://14071359557"]={d=0.51,m=25.9},["rbxassetid://14070464898"]={d=0.367,m=85.9},["rbxassetid://17891413295"]={d=0.46,m=155.0},["rbxassetid://14069236613"]={d=0.15,m=85.0,RD=0.0},["rbxassetid://17503565535"]={d=0.5,m=53.0},["rbxassetid://140404988445506"]={d=0.85,m=115.0},["rbxassetid://14071686875"]={d=1.1,m=355.9,RD=0.0},["rbxassetid://90711851688653"]={d=1.3,m=85.0},["rbxassetid://10233289802"]={d=0.45,m=155.0},["rbxassetid://14174950477"]={d=0.78,m=155.0},["rbxassetid://82153040102041"]={d=0.41,m=70.0},["rbxassetid://17150208141"]={d=0.72,m=85.0,a="Dodge"},["rbxassetid://17150117745"]={d=0.41,m=85.0},["rbxassetid://11121384790"]={d=0.96,m=85.9,a="Dodge",DD="Backward"},["rbxassetid://14008868242"]={d=1.36,m=65.0},["rbxassetid://102383192983641"]={d=1.33,m=155.0},["rbxassetid://118905193577697"]={d=0.625,m=25.9},["rbxassetid://18550826407"]={d=0.58,m=155.0},["rbxassetid://130063843642034"]={d=0.85,m=155.0},["rbxassetid://14071527834"]={d=0.505,m=25.9},["rbxassetid://14071719657"]={d=0.773,m=45.9},["rbxassetid://95697567730594"]={d=1.18,m=85.9,RD=0.0},["rbxassetid://98690955288984"]={d=0.285,m=65.9,RD=0.42},["rbxassetid://97959867705714"]={d=0.05,m=200.0},["rbxassetid://17086022325"]={d=0.73,m=155.0},["rbxassetid://98985723174711"]={d=0.255,m=53.0,R=3,RD=0.45},["rbxassetid://14081740500"]={d=2.0,m=64.0},["rbxassetid://114906950684626"]={d=0.48,m=80.0},["rbxassetid://94711451296707"]={d=0.225,m=85.9},["rbxassetid://7790499106"]={d=1.24,m=125.0},["rbxassetid://105929615471866"]={d=0.4,m=155.0},["rbxassetid://16914040729"]={d=0.365,m=155.9},["rbxassetid://93027619369767"]={d=0.397,m=85.9},["rbxassetid://10556820962"]={d=0.75,m=155.0},["rbxassetid://132632186855720"]={d=1.9,m=155.0},["rbxassetid://92536257210823"]={d=0.31,m=85.9},["rbxassetid://17388003798"]={d=1.0,m=155.0},["rbxassetid://124281421943100"]={d=0.79,m=155.0},["rbxassetid://91024048697296"]={d=0.37,m=96.0},["rbxassetid://90810365643236"]={d=0.565,m=85.9},["rbxassetid://14089397611"]={d=0.31,m=85.0},["rbxassetid://87183944060766"]={d=0.55,m=85.9},["rbxassetid://14070468724"]={d=0.367,m=85.9},["rbxassetid://87577652741355"]={d=0.58,m=155.0},["rbxassetid://86467321400139"]={d=0.25,m=85.0},["rbxassetid://84998819909632"]={d=0.4,m=85.0},["rbxassetid://16289594735"]={d=1.15,m=155.0},["rbxassetid://84479771102404"]={d=0.35,m=85.0},["rbxassetid://15303181958"]={d=0.5,m=155.0},["rbxassetid://82453804188050"]={d=0.67,m=9.0},["rbxassetid://101893689811136"]={d=0.75,m=125.0},["rbxassetid://79540534193576"]={d=0.405,m=85.9},["rbxassetid://75267727271833"]={d=0.55,m=85.9},["rbxassetid://101204849408982"]={d=0.6,m=55.9},["rbxassetid://16506076761"]={d=1.2,m=155.0},["rbxassetid://77556741941431"]={d=0.35,m=85.9},["rbxassetid://125690921255391"]={d=0.55,m=85.9,RD=0.0},["rbxassetid://107439297045997"]={d=0.72,m=85.0},["rbxassetid://17819993121"]={d=0.55,m=85.9},["rbxassetid://103617733361971"]={d=0.6,m=155.0},["rbxassetid://74169851821770"]={d=0.27,m=90.0},["rbxassetid://74129368411216"]={d=0.27,m=85.9,RD=0.0,TD=30},["rbxassetid://72314971115391"]={d=0.31,m=85.9},["rbxassetid://17732749500"]={d=0.55,m=85.0},["rbxassetid://14071558168"]={d=0.74,m=35.9},["rbxassetid://18988722884"]={d=1.525,m=13.0},["rbxassetid://86978856932820"]={d=0.85,m=155.0},["rbxassetid://94911220984648"]={d=0.71,m=155.0},["rbxassetid://18838379311"]={d=0.675,m=255.9},["rbxassetid://14071606661"]={d=1.15,m=255.9},["rbxassetid://18747296734"]={d=0.327,m=85.9},["rbxassetid://89345246529875"]={d=0.49,m=155.0},["rbxassetid://18311963013"]={d=0.1,m=45.9,a="Dodge",DD="Backward",SD=0.05},["rbxassetid://107587403308198"]={d=0.76,m=85.0},["rbxassetid://14071596676"]={d=0.4,m=20.0},["rbxassetid://18239954322"]={d=0.45,m=70.0,SD=0.45,MA=true,TD=15},["rbxassetid://14080407911"]={d=0.45,m=65.9,R=2,RD=0.5},["rbxassetid://110422647795027"]={d=0.28,m=85.9},["rbxassetid://123688081756316"]={d=0.7,m=85.0},["rbxassetid://17772694260"]={d=0.21,m=85.9},["rbxassetid://17715931850"]={d=0.27,m=55.0},["rbxassetid://14069243455"]={d=0.327,m=85.9},["rbxassetid://14070286355"]={d=0.367,m=85.9},["rbxassetid://97597705019778"]={d=1.53,m=155.0},["rbxassetid://120885591427489"]={d=0.67,m=85.0},["rbxassetid://115880291306156"]={d=0.52,m=85.9},["rbxassetid://17606129627"]={d=0.57,m=85.9,a="Dodge",DD="Backward",R=6,RD=0.03},["rbxassetid://17594142156"]={d=0.645,m=99.0,SD=0.585,MA=true},["rbxassetid://135471287664129"]={d=0.43,m=85.0,a="Counter",DD="Counter"},["rbxassetid://17188382622"]={d=0.56,m=85.0},["rbxassetid://14080162667"]={d=0.31,m=160.0,FB=true},["rbxassetid://17150093453"]={d=0.63,m=85.0},["rbxassetid://78020267794128"]={d=0.55,m=155.0},["rbxassetid://91233168287060"]={d=0.43,m=85.9},["rbxassetid://14071700196"]={d=0.8,m=107.0,FB=true},["rbxassetid://14069285542"]={d=0.34,m=85.9},["rbxassetid://14069916307"]={d=0.505,m=45.0},["rbxassetid://96040009026472"]={d=0.58,m=85.0},["rbxassetid://17197222741"]={d=0.28,m=85.9,a="Dodge",DD="Backward",SD=0.1,MA=true},["rbxassetid://13912276004"]={d=0.6,m=155.0},["rbxassetid://17133373301"]={d=0.84,m=155.9},["rbxassetid://17045896116"]={d=0.15,m=85.0,FB=true,TD=35},["rbxassetid://14071538689"]={d=0.4,m=45.9,a="Dodge",DD="Right",R=5,RD=0.1},["rbxassetid://116760342954434"]={d=0.52,m=155.0},["rbxassetid://17891450790"]={d=0.45,m=155.0},["rbxassetid://94492045799378"]={d=0.295,m=25.9},["rbxassetid://16897422592"]={d=0.562,m=191.9},["rbxassetid://111605608602213"]={d=0.35,m=85.9},["rbxassetid://18775500687"]={d=0.6,m=155.0,a="Dodge"},["rbxassetid://109472251202443"]={d=0.3,m=85.9,a="Dodge",DD="Backward"},["rbxassetid://16749243263"]={d=0.29,m=85.9},["rbxassetid://108141441255434"]={d=0.68,m=155.0},["rbxassetid://119247893528062"]={d=0.895,m=145.9,a="Dodge Forward",DD="Forward"},["rbxassetid://11361552631"]={d=0.45,m=85.9},["rbxassetid://91983784248298"]={d=0.46,m=85.0},["rbxassetid://100694155460860"]={d=0.73,m=155.9},["rbxassetid://136909500655901"]={d=0.5,m=85.9},["rbxassetid://17891447960"]={d=0.45,m=155.0},["rbxassetid://113857139743696"]={d=0.42,m=85.0},["rbxassetid://126639158002945"]={d=0,m=150.9},["rbxassetid://121924577484731"]={d=0.85,m=155.0},["rbxassetid://127410288003428"]={d=1.1,m=155.0},["rbxassetid://17269260858"]={d=0.99,m=155.0},["rbxassetid://14327026699"]={d=0.63,m=85.0},["rbxassetid://80960587783764"]={d=0.44,m=85.0},["rbxassetid://16749241651"]={d=0.29,m=85.9},["rbxassetid://135011974106375"]={d=1.77,m=135.0},["rbxassetid://14306789551"]={d=0.15,m=125.9,a="Dodge",DD="Right"},["rbxassetid://17109178988"]={d=0.52,m=155.0,R=2,RD=0.68},["rbxassetid://14149150084"]={d=0.8,m=85.0,FB=true},["rbxassetid://14070209278"]={d=0.36,m=85.9},["rbxassetid://109162896875607"]={d=0.58,m=85.9},["rbxassetid://17166793932"]={d=0.52,m=155.0},["rbxassetid://93259021366820"]={d=0.45,m=155.0},["rbxassetid://14070911281"]={d=0.35,m=85.0},["rbxassetid://14148978250"]={d=0.36,m=85.0,a="Dodge",DD="Right"},["rbxassetid://89555251847018"]={d=0.35,m=85.0},["rbxassetid://100170492443384"]={d=1.05,m=155.0,R=2,RD=0.9},["rbxassetid://95137636416866"]={d=0.2,m=85.0,a="Dodge",DD="Backward"},["rbxassetid://17413093522"]={d=0.74,m=155.0},["rbxassetid://18187286815"]={d=0.33,m=85.0,TD=28},["rbxassetid://96681964533604"]={d=0.9,m=85.9},["rbxassetid://140288583730996"]={d=0.55,m=85.9},["rbxassetid://17528739240"]={d=0.375,m=65.9},["rbxassetid://109765533633852"]={d=0.95,m=155.0},["rbxassetid://14070512628"]={d=0.35,m=96.0},["rbxassetid://14071815365"]={d=0.15,m=85.0},["rbxassetid://14071812213"]={d=0.34,m=85.0},["rbxassetid://14070470232"]={d=0.367,m=85.9},["rbxassetid://14071803324"]={d=0.367,m=55.9},["rbxassetid://99814751557477"]={d=0.36,m=155.9,R=2,RD=0.4},["rbxassetid://14071710790"]={d=1.0,m=255.9,a="Dodge",DD="Right"},["rbxassetid://14071705811"]={d=0.72,m=155.9},["rbxassetid://17139510110"]={d=0.85,m=155.0},["rbxassetid://14071666095"]={d=0.4,m=160.0},["rbxassetid://14071664552"]={d=0.557,m=115.9,RD=0.12},["rbxassetid://14070399544"]={d=0.33,m=85.0},["rbxassetid://107490655083042"]={d=0.5255,m=25.9},["rbxassetid://14071653586"]={d=0.7,m=35.9},["rbxassetid://99141883243394"]={d=0.73,m=115.0},["rbxassetid://75781859971583"]={d=0.9,m=155.0},["rbxassetid://14071650108"]={d=0.47,m=21.9},["rbxassetid://14628756235"]={d=2.1,m=85.0,a="Dodge"},["rbxassetid://14071648861"]={d=0.375,m=31.9},["rbxassetid://139167828097095"]={d=1.2,m=155.0},["rbxassetid://17357310642"]={d=0.1,m=85.0,a="Dodge",DD="Backward"},["rbxassetid://16927392556"]={d=0.75,m=85.0},["rbxassetid://94383844938706"]={d=0.65,m=85.0},["rbxassetid://17188386684"]={d=0.56,m=85.0},["rbxassetid://18252557061"]={d=0.45,m=155.0},["rbxassetid://14071555902"]={d=0.488,m=255.9},["rbxassetid://105078231452435"]={d=0.16,m=85.9,a="Dodge",DD="Right"},["rbxassetid://14071632343"]={d=0.6,m=201.0},["rbxassetid://75011734604623"]={d=0.2,m=85.0},["rbxassetid://86509163598473"]={d=0.6,m=155.0,a="Dodge"},["rbxassetid://14071628131"]={d=0.6,m=65.9},["rbxassetid://14071620528"]={d=0.29,m=185.9},["rbxassetid://17797262740"]={d=0.5,m=155.0},["rbxassetid://113186823024754"]={d=0.413,m=45.9},["rbxassetid://98885971685801"]={d=0.89,m=155.0},["rbxassetid://91608694318547"]={d=0.6,m=85.0,a="Dodge"},["rbxassetid://14071616956"]={d=0.8,m=270.9,a="Dodge",DD="Right",RD=0.0},["rbxassetid://134479234715522"]={d=0.5,m=85.0},["rbxassetid://14071292129"]={d=0.34,m=85.9},["rbxassetid://16417798771"]={d=0.45,m=85.0},["rbxassetid://74564651506542"]={d=0.7,m=155.0},["rbxassetid://14069947713"]={d=2.27,m=34.0},["rbxassetid://14070908969"]={d=0.35,m=85.0},["rbxassetid://17086024936"]={d=0.78,m=155.0},["rbxassetid://14071608032"]={d=0.56,m=55.9},["rbxassetid://11123981295"]={d=0.77,m=155.0},["rbxassetid://18791446076"]={d=0.7,m=155.0,a="Dodge"},["rbxassetid://74701342732989"]={d=0.55,m=155.0},["rbxassetid://16749242463"]={d=0.29,m=85.9},["rbxassetid://86167148086945"]={d=1.0,m=85.0},["rbxassetid://130821883699985"]={d=0.48,m=155.0},["rbxassetid://96140377913164"]={d=2.0,m=85.0},["rbxassetid://94463254603007"]={d=0.7,m=155.0},["rbxassetid://14071559270"]={d=0.43,m=71.0},["rbxassetid://83478022548253"]={d=1.12,m=85.0},["rbxassetid://17162226428"]={d=0.6,m=155.0,a="Dodge"},["rbxassetid://13912155686"]={d=0.46,m=155.0},["rbxassetid://71890767479760"]={d=0.35,m=85.9},["rbxassetid://127359882437058"]={d=2.05,m=155.0,a="Dodge"},["rbxassetid://105056646850750"]={d=0.44,m=85.0},["rbxassetid://14071540115"]={d=0.295,m=95.9},["rbxassetid://17404358557"]={d=0.9,m=155.9,a="Dodge",DD="Right"},["rbxassetid://14071536135"]={d=0.25,m=25.9},["rbxassetid://131792181773633"]={d=0.52,m=155.0},["rbxassetid://14071534340"]={d=0.39,m=65.9,R=2,RD=0.55},["rbxassetid://14071532590"]={d=0.5,m=85.0,a="Dodge Forward",DD="Forward"},["rbxassetid://14071794187"]={d=0.817,m=100.0},["rbxassetid://135088445025559"]={d=0.4,m=155.0},["rbxassetid://86850231217100"]={d=0.47,m=155.0},["rbxassetid://138581249464604"]={d=1.0,m=85.0},["rbxassetid://14071280369"]={d=0.2,m=85.9,a="Dodge",DD="Backward",R=4,RD=0.1},["rbxassetid://126249213151642"]={d=0.42,m=105.9,a="Dodge",DD="Right"},["rbxassetid://17826113901"]={d=0.6,m=155.0},["rbxassetid://128875759494501"]={d=0.68,m=85.0},["rbxassetid://13854505129"]={d=0.53,m=85.0},["rbxassetid://136829645940931"]={d=0.78,m=155.0},["rbxassetid://8863229939"]={d=3.1,m=155.0},["rbxassetid://122690692083575"]={d=0.4,m=155.0},["rbxassetid://14071317012"]={d=0.42,m=155.9},["rbxassetid://14071610897"]={d=0.35,m=155.9,TD=40},["rbxassetid://16417792446"]={d=0.45,m=85.0},["rbxassetid://83974667129266"]={d=0.46,m=85.0},["rbxassetid://17732915133"]={d=0.57,m=155.0},["rbxassetid://11324326025"]={d=0.55,m=155.0},["rbxassetid://138644029603579"]={d=1.2,m=155.0},["rbxassetid://107635960154911"]={d=0.52,m=155.0},["rbxassetid://14071246624"]={d=0.417,m=85.9},["rbxassetid://14071141305"]={d=0.42,m=85.9,a="Dodge",DD="Backward"},["rbxassetid://17734074151"]={d=0.56,m=155.0},["rbxassetid://14069454554"]={d=0.34,m=85.9},["rbxassetid://14070917839"]={d=0.7,m=85.0},["rbxassetid://17438415897"]={d=0.7,m=85.9},["rbxassetid://14070912619"]={d=0.35,m=85.0},["rbxassetid://110206475548168"]={d=0.35,m=85.0},["rbxassetid://14071112886"]={d=0.455,m=84.0,SD=0.41},["rbxassetid://130632119775037"]={d=0.15,m=175.5},["rbxassetid://14150489371"]={d=1.05,m=155.0},["rbxassetid://103319060602038"]={d=0.49,m=85.0},["rbxassetid://14070513782"]={d=0.35,m=96.0},["rbxassetid://138554043667476"]={d=0.5,m=155.0},["rbxassetid://133830116940613"]={d=0.15,m=12.9},["rbxassetid://105831547424472"]={d=0.467,m=55.9},["rbxassetid://110833564069919"]={d=0.31,m=85.9},["rbxassetid://75249392211553"]={d=1.03,m=155.0,a="Dodge"},["rbxassetid://134801845956597"]={d=0.55,m=155.0},["rbxassetid://81782950825595"]={d=1.0,m=155.0},["rbxassetid://134720868148122"]={d=0.15,m=85.0,TD=20},["rbxassetid://126843720892013"]={d=0.86,m=35.0},["rbxassetid://130863537121533"]={d=0.45,m=85.0},["rbxassetid://14070285319"]={d=0.367,m=85.9},["rbxassetid://79441716695622"]={d=0.58,m=85.0},["rbxassetid://14149049058"]={d=0,m=55.9,FB=true},["rbxassetid://94860056861084"]={d=0.68,m=85.9},["rbxassetid://14070196670"]={d=0.64,m=85.9},["rbxassetid://17086023674"]={d=0.74,m=155.0},["rbxassetid://122823331494331"]={d=0.55,m=155.0},["rbxassetid://14069940723"]={d=0.385,m=85.9},["rbxassetid://126904584967925"]={d=0.31,m=85.9},["rbxassetid://14080660172"]={d=0.367,m=85.9},["rbxassetid://102789825443579"]={d=0.75,m=155.0},["rbxassetid://139926815993252"]={d=0.7,m=85.0},["rbxassetid://17438374906"]={d=0.33,m=85.9},["rbxassetid://101892073899926"]={d=0.5,m=155.0},["rbxassetid://125128540782753"]={d=0.35,m=85.9},["rbxassetid://130719155551615"]={d=1.1,m=155.0},["rbxassetid://118172369009535"]={d=0.7,m=155.0,a="Counter",DD="Counter"},["rbxassetid://14068264382"]={d=0.38,m=85.9},["rbxassetid://131177999571320"]={d=2.75,m=155.0},["rbxassetid://80488615257685"]={d=1.9,m=155.0},["rbxassetid://17744158153"]={d=0.45,m=155.0},["rbxassetid://114171067278127"]={d=0.81,m=155.0,R=2,RD=2.36},["rbxassetid://11156433078"]={d=0.63,m=155.0,a="Counter",DD="Counter"},["rbxassetid://71416929825712"]={d=0.75,m=155.0},["rbxassetid://138083299270154"]={d=0.353,m=26.5},["rbxassetid://75995869780371"]={d=0.53,m=85.9},["rbxassetid://13831954897"]={d=0.56,m=155.0},["rbxassetid://121890671665317"]={d=1.65,m=155.0},["rbxassetid://107844891272072"]={d=0.45,m=155.0},["rbxassetid://131232074612126"]={d=0.335,m=85.9},["rbxassetid://119722707701744"]={d=0.75,m=155.0},["rbxassetid://130736346183436"]={d=0.29,m=85.9},["rbxassetid://13885352496"]={d=0.95,m=85.0},["rbxassetid://17592436346"]={d=0,m=25.9,a="Dodge Forward",DD="Forward"},["rbxassetid://127093663476052"]={d=0.55,m=85.9},["rbxassetid://98693595418815"]={d=0.7,m=85.9},["rbxassetid://18236080952"]={d=0.85,m=155.0},["rbxassetid://121157216919751"]={d=0.38,m=25.9},["rbxassetid://120453052558932"]={d=0.2075,m=55.9},["rbxassetid://76491120300796"]={d=0.55,m=155.0},["rbxassetid://17096338395"]={d=0,m=85.9},["rbxassetid://14110194908"]={d=1.15,m=155.0},["rbxassetid://13064481711"]={d=0.82,m=155.0},["rbxassetid://17154399253"]={d=0.46,m=155.0},["rbxassetid://78283854597167"]={d=0.28,m=85.0},["rbxassetid://11151794033"]={d=0.68,m=85.9},["rbxassetid://17188670401"]={d=0.3,m=85.0,R=3,RD=0.25},["rbxassetid://107848116205888"]={d=0.87,m=85.9},["rbxassetid://104868257303962"]={d=0.55,m=85.9},["rbxassetid://89900583582792"]={d=0.85,m=155.0},["rbxassetid://101335267600724"]={d=0.2,m=85.9},["rbxassetid://101840599825967"]={d=0.234,m=85.9},["rbxassetid://101485195772910"]={d=0.5,m=85.0},["rbxassetid://100291377596872"]={d=0.65,m=45.9,a="Dodge",DD="Right"},["rbxassetid://14327905929"]={d=0.61,m=85.0},["rbxassetid://17611714755"]={d=0.68,m=85.0},["rbxassetid://16915850752"]={d=0.75,m=155.0},["rbxassetid://89138308293602"]={d=1.5,m=177.0},["rbxassetid://122856352478950"]={d=0.8,m=85.0},["rbxassetid://14089180282"]={d=0.55,m=85.0},["rbxassetid://79538586424400"]={d=0.82,m=155.0},["rbxassetid://83097070172817"]={d=1.38,m=85.0,a="Dodge"},["rbxassetid://17485764600"]={d=1.05,m=155.0},["rbxassetid://14089285097"]={d=0.65,m=85.0,a="Dodge"},["rbxassetid://107507023089925"]={d=0.9,m=145.0},["rbxassetid://107574429239718"]={d=1.15,m=85.0},["rbxassetid://76754008387126"]={d=0.43,m=85.9},["rbxassetid://74973280679545"]={d=0.43,m=85.9},["rbxassetid://18502608558"]={d=0.303,m=45.9},["rbxassetid://130168360103868"]={d=0.443,m=75.9},["rbxassetid://14327924170"]={d=0.61,m=85.0},["rbxassetid://9780037814"]={d=0.67,m=155.0},["rbxassetid://135906726244054"]={d=0.51,m=85.9},["rbxassetid://110400553220434"]={d=0.4,m=155.0},["rbxassetid://97272630388005"]={d=0.4,m=155.0},["rbxassetid://132052485145774"]={d=0.9,m=155.0},["rbxassetid://11361791134"]={d=0.45,m=85.9},["rbxassetid://130053309887427"]={d=0.7,m=155.0},["rbxassetid://118973147039779"]={d=0.95,m=155.0,a="Dodge"},["rbxassetid://91338444719203"]={d=0.68,m=155.0},["rbxassetid://83656019534647"]={d=0.81,m=155.0},["rbxassetid://11434435930"]={d=1.15,m=155.0},["rbxassetid://17429347710"]={d=0.46,m=155.0},["rbxassetid://14040288114"]={d=0.47,m=85.0},["rbxassetid://14071635270"]={d=0.667,m=255.0,a="Dodge",DD="Right",SD=0.675,MA=true,TD=26.3},["rbxassetid://16889680733"]={d=0.35,m=115.9,R=2,RD=0.7},["rbxassetid://113101872248044"]={d=0.85,m=155.0},["rbxassetid://123458031797396"]={d=0.48,m=85.9},["rbxassetid://17165729310"]={d=0.63,m=155.0}}
    AP.parseTimings=function(raw)
        local ok,data=pcall(function() return game:GetService("HttpService"):JSONDecode(raw) end)
        if not ok or type(data)~="table" then return {} end
        local out={}
        for _,e in ipairs(data) do
            if e.animId and e.name then
                local id=e.animId; local nid=id:match("%?id=(%d+)") or id:match("rbxassetid://(%d+)") or id:match("^(%d+)$")
                if nid then id="rbxassetid://"..nid end
                table.insert(out,{
                    name=e.name, animId=id,
                    delay=tonumber(e.delay) or 0,
                    minDist=tonumber(e.minDist) or 0,
                    maxDist=tonumber(e.maxDist) or 25,
                    action=e.action or "Parry",
                    DodgeDirection=e.DodgeDirection or "None",
                    FullHoldBlock=e.FullHoldBlock or false,
                    MovingAttack=e.MovingAttack or false,
                    Repeat=tonumber(e.Repeat) or 1,
                    RepeatDelay=tonumber(e.RepeatDelay) or 0.35,
                    StartDelay=tonumber(e.StartDelay) or 0,
                    TriggerDistance=tonumber(e.TriggerDistance) or 12,
                })
            end
        end
        return out
    end
    AP.saveTimings=function()
        local out={}
        for _,e in ipairs(AP.savedTimings) do table.insert(out,{
            name=e.name, animId=e.animId, delay=e.delay, minDist=e.minDist, maxDist=e.maxDist, action=e.action,
            DodgeDirection=e.DodgeDirection, FullHoldBlock=e.FullHoldBlock, MovingAttack=e.MovingAttack,
            Repeat=e.Repeat, RepeatDelay=e.RepeatDelay, StartDelay=e.StartDelay, TriggerDistance=e.TriggerDistance,
        }) end
        pcall(function() writefile(AP.TIMINGS_FILE,game:GetService("HttpService"):JSONEncode(out)) end)
    end
    AP.loadTimings=function()
        local ok,raw=pcall(function() return readfile(AP.TIMINGS_FILE) end)
        if not ok or not raw or raw=="" then raw="[]" end
        local loaded=AP.parseTimings(raw)
        AP.savedTimings={}; AP.timings={}
        local savedIds={}
        for _,e in ipairs(loaded) do
            table.insert(AP.savedTimings,e)
            if not AP.timings[e.animId] then AP.timings[e.animId]={} end
            table.insert(AP.timings[e.animId],e)
            savedIds[e.animId]=true
        end
        -- merge built-in defaults into BOTH tables so they show in UI
        for aid, cfg in pairs(_AP_DEFAULTS) do
            if not savedIds[aid] then
                local action = cfg.a or "Parry"
                local e = {
                    name = aid:match("(%d+)$") or aid,
                    animId = aid,
                    delay = cfg.d or 0,
                    minDist = 0,
                    maxDist = cfg.m or 25,
                    action = action,
                    DodgeDirection = cfg.DD or "None",
                    FullHoldBlock = cfg.FB or false,
                    MovingAttack = cfg.MA or false,
                    Repeat = cfg.R or 1,
                    RepeatDelay = cfg.RD or 0.35,
                    StartDelay = cfg.SD or 0,
                    TriggerDistance = cfg.TD or 12,
                }
                table.insert(AP.savedTimings,e)
                AP.timings[aid] = {e}
            end
        end
        local ns={}; for _,e in ipairs(AP.savedTimings) do table.insert(ns,e.name) end
        pcall(function()
            Opt.APSavedTimings:ClearOptions()
            Opt.APSavedTimings:InsertOptions(#ns>0 and ns or {"--"})
            Opt.APSavedTimings:UpdateSelection(1)
        end)
        pcall(function() AP.parryCountLbl.Text=#AP.savedTimings.." in table" end)
    end

    AP.inst=function(cls,props,parent)
        local obj=Instance.new(cls)
        for k,v in pairs(props or {}) do pcall(function() obj[k]=v end) end
        if parent then obj.Parent=parent end
        return obj
    end
    AP.makeWin=function(sg, pos, sz, title)

        local win=AP.inst("Frame",{Position=pos,Size=sz,BackgroundColor3=AP.BG,BackgroundTransparency=0.05,BorderSizePixel=0,ZIndex=10,Visible=false,Parent=sg})
        AP.inst("UICorner",{CornerRadius=UDim.new(0,10)},win)
        AP.inst("UIStroke",{Color=AP.BORD,Thickness=1,Transparency=0.9},win)

        local bar=AP.inst("Frame",{Position=UDim2.new(0,0,0,0),Size=UDim2.new(1,0,0,31),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=11,Parent=win})

        local dotsFrame = AP.inst("Frame",{Position=UDim2.new(0,0,0,0),Size=UDim2.new(0,56,1,0),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=12,Parent=bar})
        AP.inst("UIListLayout",{Padding=UDim.new(0,5),FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Center},dotsFrame)
        AP.inst("UIPadding",{PaddingLeft=UDim.new(0,11)},dotsFrame)

        local dotColors = {Color3.fromRGB(255,96,87), Color3.fromRGB(255,189,46), Color3.fromRGB(30,30,30)}
        for _, col in ipairs(dotColors) do
            local dot = AP.inst("Frame",{Size=UDim2.fromOffset(8,8),BackgroundColor3=col,BorderSizePixel=0,ZIndex=12,Parent=dotsFrame})
            AP.inst("UICorner",{CornerRadius=UDim.new(1,0)},dot)
            local s = Instance.new("UIStroke"); s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Color=Color3.new(1,1,1); s.Transparency=0.9; s.Parent=dot
        end

        -- gradient on "Zero Hub" part of title
        local function gradTitle(t)
            local chars = {"Z","e","r","o"," ","H","u","b"}
            local c1r,c1g,c1b = 178,120,255
            local c2r,c2g,c2b = 138,79,255
            local grad = ""
            for i, ch in ipairs(chars) do
                local x = (i-1)/(#chars-1)
                local r = math.floor(c1r + (c2r-c1r)*x)
                local g = math.floor(c1g + (c2g-c1g)*x)
                local b = math.floor(c1b + (c2b-c1b)*x)
                if ch == " " then grad = grad .. " "
                else grad = grad .. string.format('<font color="rgb(%d,%d,%d)">%s</font>', r, g, b, ch) end
            end
            local rest = t:sub(9) -- everything after "Zero Hub"
            return grad .. rest
        end

        local drag=AP.inst("TextLabel",{Position=UDim2.new(0,56,0,0),Size=UDim2.new(1,-56,1,0),BackgroundTransparency=1,Text=gradTitle(title),RichText=true,TextColor3=AP.WHITE,FontFace=AP.FONT_FACE,TextSize=15,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,Parent=bar})

        AP.inst("Frame",{Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),BackgroundColor3=AP.BORD,BackgroundTransparency=0.9,BorderSizePixel=0,ZIndex=11,Parent=bar})

        local xBtn=AP.inst("TextButton",{Position=UDim2.new(0,3,0.5,-8),Size=UDim2.new(0,16,0,16),BackgroundTransparency=1,Text="",ZIndex=13,FontFace=AP.FONT_FACE,TextSize=1,Parent=bar})

        local dragging=false; local dragStart=Vector2.zero; local startPos=win.Position
        drag.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; dragStart=i.Position; startPos=win.Position end end)
        AP.UIS.InputChanged:Connect(function(i)
            if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                local d=i.Position-dragStart
                win.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
            end
        end)
        AP.UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
        return win,xBtn
    end


    AP.V = {
        cam=nil, model=nil, anim8r=nil, animObj=nil, track=nil,
        hb=nil, paused=false, length=0, loop=true, speed=1,
        speeds={0.25,0.5,1,1.5,2}, spIdx=3,
        rotY=math.pi, rotX=0.3, targetRotY=math.pi, targetRotX=0.3,
        zoom=7.5, targetZoom=7.5,
    }
    AP.scrubbing=false; AP.scrubWasPaused=false
    AP.vpDragging=false; AP.vpLastX=0; AP.vpLastY=0


    AP.sg=AP.inst("ScreenGui",{Name="ZeroHubAutoParry",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Global,IgnoreGuiInset=true})
    pcall(function() AP.sg.Parent=AP.CoreGui end)
    if not AP.sg.Parent then AP.sg.Parent=LP.PlayerGui end


    AP.visWin,AP.visX=AP.makeWin(AP.sg,UDim2.new(0,8,0.5,-384),UDim2.new(0,548,0,768),"Zero Hub  ·  Visualizer")
    AP.visX.MouseButton1Click:Connect(function()
        AP.visWin.Visible=false
        if Tog.APShowViz then Tog.APShowViz:UpdateState(false) end
    end)


    local vpCtrlBar=AP.inst("Frame",{Position=UDim2.new(0,8,0,37),Size=UDim2.new(1,-16,0,28),BackgroundTransparency=1,ZIndex=11,Parent=AP.visWin})
    local function makeVPBtn(txt,xOff)
        local b=AP.inst("TextButton",{Position=UDim2.new(0,xOff,0,0),Size=UDim2.new(0,56,1,0),
            BackgroundColor3=AP.CARD,Text=txt,TextColor3=AP.DIM,FontFace=AP.FONT_FACE,TextSize=12,AutoButtonColor=false,ZIndex=12,Parent=vpCtrlBar})
        AP.inst("UICorner",{CornerRadius=UDim.new(0,5)},b); AP.inst("UIStroke",{Color=AP.BORD,Thickness=1,Transparency=0.9},b)
        b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(35,35,35); b.TextColor3=AP.WHITE end)
        b.MouseLeave:Connect(function() b.BackgroundColor3=AP.CARD; b.TextColor3=AP.DIM end)
        return b
    end
    AP.gridBtn=makeVPBtn("Grid",0); AP.spinBtn=makeVPBtn("Spin",60); AP.resetBtn=makeVPBtn("Reset",120)
    AP.gridBtn.BackgroundColor3=Color3.fromRGB(35,35,35); AP.gridBtn.TextColor3=AP.WHITE


    AP.vpFrame=AP.inst("ViewportFrame",{Position=UDim2.new(0,8,0,71),Size=UDim2.new(1,-16,0,360),
        BackgroundColor3=Color3.fromRGB(8,8,16),ZIndex=11,Parent=AP.visWin})
    AP.inst("UICorner",{CornerRadius=UDim.new(0,6)},AP.vpFrame)
    AP.inst("UIStroke",{Color=AP.BORD,Thickness=1,Transparency=0.9},AP.vpFrame)
    AP.vpFrame.LightColor=Color3.fromRGB(255,255,255); AP.vpFrame.LightDirection=Vector3.new(-0.5,-1,-0.5)
    AP.vpFrame.Ambient=Color3.fromRGB(85,80,100)
    AP.vpWorld=Instance.new("WorldModel"); AP.vpWorld.Parent=AP.vpFrame
    AP.vpHint=AP.inst("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        Text="load an animation to preview",TextColor3=AP.HINT,FontFace=AP.FONT_FACE,TextSize=13,ZIndex=12,Parent=AP.vpFrame})
    AP.vpFrame.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            AP.vpDragging=true; AP.vpLastX=i.Position.X; AP.vpLastY=i.Position.Y
        end
    end)


    AP.visStat=AP.inst("TextLabel",{Position=UDim2.new(0,8,0,437),Size=UDim2.new(0,80,0,16),
        BackgroundTransparency=1,Text="Not loaded",TextColor3=AP.WHITE,FontFace=AP.FONT_FACE,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,Parent=AP.visWin})
    AP.visIdLbl=AP.inst("TextLabel",{Position=UDim2.new(0,92,0,437),Size=UDim2.new(1,-100,0,16),
        BackgroundTransparency=1,Text="",TextColor3=AP.ACC,FontFace=AP.FONT_FACE,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=11,Parent=AP.visWin})


    local tlLeft=AP.inst("TextLabel",{Position=UDim2.new(0,8,0,458),Size=UDim2.new(0,62,0,12),
        BackgroundTransparency=1,Text="00:00.00",TextColor3=AP.HINT,FontFace=AP.FONT_FACE,TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,Parent=AP.visWin})
    local tlRight=AP.inst("TextLabel",{Position=UDim2.new(1,-70,0,458),Size=UDim2.new(0,62,0,12),
        BackgroundTransparency=1,Text="00:00.00",TextColor3=AP.HINT,FontFace=AP.FONT_FACE,TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Right,ZIndex=11,Parent=AP.visWin})
    AP.tlBg=AP.inst("Frame",{Position=UDim2.new(0,8,0,472),Size=UDim2.new(1,-16,0,8),
        BackgroundColor3=Color3.fromRGB(30,30,30),BorderSizePixel=0,ZIndex=11,Parent=AP.visWin})
    AP.inst("UICorner",{CornerRadius=UDim.new(1,0)},AP.tlBg)
    AP.inst("UIStroke",{Color=AP.BORD,Thickness=1,Transparency=0.9},AP.tlBg)
    AP.tlFill=AP.inst("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=AP.ACC,BorderSizePixel=0,ZIndex=12,Parent=AP.tlBg})
    AP.inst("UICorner",{CornerRadius=UDim.new(1,0)},AP.tlFill)
    AP.tlHit=AP.inst("TextButton",{Size=UDim2.new(1,0,4,0),Position=UDim2.new(0,0,-1.5,0),
        BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=14,Parent=AP.tlBg})
    AP.tlLeft=tlLeft; AP.tlRight=tlRight


    local ctrlRow=AP.inst("Frame",{Position=UDim2.new(0,8,0,486),Size=UDim2.new(1,-16,0,34),BackgroundTransparency=1,ZIndex=11,Parent=AP.visWin})
    local function mkCtrl(sym,xOff,w)
        local b=AP.inst("TextButton",{Position=UDim2.new(0,xOff,0,0),Size=UDim2.new(0,w or 36,1,0),
            BackgroundColor3=AP.CARD,Text=sym,TextColor3=AP.WHITE,FontFace=AP.FONT_FACE,TextSize=13,AutoButtonColor=false,ZIndex=12,Parent=ctrlRow})
        AP.inst("UICorner",{CornerRadius=UDim.new(0,6)},b); AP.inst("UIStroke",{Color=AP.BORD,Thickness=1,Transparency=0.9},b)
        b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(35,35,35) end)
        b.MouseLeave:Connect(function() b.BackgroundColor3=AP.CARD end)
        return b
    end
    AP.btnRestart=mkCtrl("|◀",0); AP.btnPlay=mkCtrl("▶",40,42); AP.btnStop=mkCtrl("■",86)
    AP.loopBtn=mkCtrl("↺",126); AP.speedBtn=mkCtrl("1×",166,44)
    AP.setPlayState=function(playing) AP.btnPlay.Text=playing and "| |" or "▶"; AP.btnPlay.TextColor3=AP.WHITE end


    local spdRow=AP.inst("Frame",{Position=UDim2.new(0,8,0,526),Size=UDim2.new(1,-16,0,24),BackgroundTransparency=1,ZIndex=11,Parent=AP.visWin})
    AP.inst("TextLabel",{Size=UDim2.new(0,48,1,0),BackgroundTransparency=1,Text="Speed:",
        TextColor3=AP.DIM,FontFace=AP.FONT_FACE,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=spdRow})
    local spdTrack=AP.inst("Frame",{Position=UDim2.new(0,52,0.5,-3),Size=UDim2.new(1,-96,0,6),
        BackgroundColor3=Color3.fromRGB(30,30,30),BorderSizePixel=0,ZIndex=12,Parent=spdRow})
    AP.inst("UICorner",{CornerRadius=UDim.new(1,0)},spdTrack); AP.inst("UIStroke",{Color=AP.BORD,Thickness=1,Transparency=0.9},spdTrack)
    AP.spdFill=AP.inst("Frame",{Size=UDim2.new(0.5,0,1,0),BackgroundColor3=AP.ACC,BorderSizePixel=0,ZIndex=13,Parent=spdTrack})
    AP.inst("UICorner",{CornerRadius=UDim.new(1,0)},AP.spdFill)
    AP.spdHandle=AP.inst("Frame",{Position=UDim2.new(0.5,-5,0.5,-5),Size=UDim2.new(0,10,0,10),
        BackgroundColor3=AP.WHITE,BorderSizePixel=0,ZIndex=14,Parent=spdTrack})
    AP.inst("UICorner",{CornerRadius=UDim.new(1,0)},AP.spdHandle)
    AP.spdLbl=AP.inst("TextLabel",{Position=UDim2.new(1,-38,0,0),Size=UDim2.new(0,38,1,0),
        BackgroundTransparency=1,Text="1.00×",TextColor3=AP.WHITE,FontFace=AP.FONT_FACE,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Right,ZIndex=12,Parent=spdRow})
    AP.spdSlider=spdTrack


    local zoomRow=AP.inst("Frame",{Position=UDim2.new(0,8,0,556),Size=UDim2.new(1,-16,0,24),BackgroundTransparency=1,ZIndex=11,Parent=AP.visWin})
    AP.inst("TextLabel",{Size=UDim2.new(0,48,1,0),BackgroundTransparency=1,Text="Zoom:",
        TextColor3=AP.DIM,FontFace=AP.FONT_FACE,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=zoomRow})
    local zoomTrack=AP.inst("Frame",{Position=UDim2.new(0,52,0.5,-3),Size=UDim2.new(1,-96,0,6),
        BackgroundColor3=Color3.fromRGB(30,30,30),BorderSizePixel=0,ZIndex=12,Parent=zoomRow})
    AP.inst("UICorner",{CornerRadius=UDim.new(1,0)},zoomTrack); AP.inst("UIStroke",{Color=AP.BORD,Thickness=1,Transparency=0.9},zoomTrack)
    local zFill=AP.inst("Frame",{Size=UDim2.new(0.5,0,1,0),BackgroundColor3=AP.ACC,BorderSizePixel=0,ZIndex=13,Parent=zoomTrack})
    AP.inst("UICorner",{CornerRadius=UDim.new(1,0)},zFill)
    local zHandle=AP.inst("Frame",{Position=UDim2.new(0.5,-5,0.5,-5),Size=UDim2.new(0,10,0,10),
        BackgroundColor3=AP.WHITE,BorderSizePixel=0,ZIndex=14,Parent=zoomTrack})
    AP.inst("UICorner",{CornerRadius=UDim.new(1,0)},zHandle)
    AP.zoomLbl=AP.inst("TextLabel",{Position=UDim2.new(1,-38,0,0),Size=UDim2.new(0,38,1,0),
        BackgroundTransparency=1,Text="7.5",TextColor3=AP.WHITE,FontFace=AP.FONT_FACE,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Right,ZIndex=12,Parent=zoomRow})
    AP.zoomSlider=zoomTrack; AP.zoomFill=zFill; AP.zoomHandle=zHandle


    local timeRow=AP.inst("Frame",{Position=UDim2.new(0,8,0,586),Size=UDim2.new(1,-16,0,28),BackgroundTransparency=1,ZIndex=11,Parent=AP.visWin})
    AP.inst("TextLabel",{Size=UDim2.new(0,34,1,0),BackgroundTransparency=1,Text="Time:",
        TextColor3=AP.DIM,FontFace=AP.FONT_FACE,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=timeRow})
    local function mkInfoBox(txt,xOff,w)
        local f=AP.inst("Frame",{Position=UDim2.new(0,xOff,0,3),Size=UDim2.new(0,w,1,-6),
            BackgroundColor3=AP.CARD,BorderSizePixel=0,ZIndex=12,Parent=timeRow})
        AP.inst("UICorner",{CornerRadius=UDim.new(0,4)},f); AP.inst("UIStroke",{Color=AP.BORD,Thickness=1,Transparency=0.9},f)
        local lbl=AP.inst("TextLabel",{Size=UDim2.new(1,-4,1,0),Position=UDim2.new(0,2,0,0),
            BackgroundTransparency=1,Text=txt,TextColor3=AP.WHITE,FontFace=AP.FONT_FACE,TextSize=11,ZIndex=13,Parent=f})
        return lbl
    end
    AP.timeFull=mkInfoBox("0.00 / 0.00",38,110); AP.timeScrub=mkInfoBox("0.000s",154,74); AP.fpsBox=mkInfoBox("60 FPS",234,60)


    AP.inst("Frame",{Position=UDim2.new(0,8,0,620),Size=UDim2.new(1,-16,0,1),BackgroundColor3=AP.BORD,BackgroundTransparency=0.9,BorderSizePixel=0,ZIndex=11,Parent=AP.visWin})
    AP.inst("TextLabel",{Position=UDim2.new(0,8,0,626),Size=UDim2.new(0.5,0,0,18),
        BackgroundTransparency=1,Text="Parry Builder",TextColor3=AP.WHITE,FontFace=AP.FONT_FACE,TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,Parent=AP.visWin})
    AP.parryCountLbl=AP.inst("TextLabel",{Position=UDim2.new(0.5,0,0,626),Size=UDim2.new(0.5,-8,0,18),
        BackgroundTransparency=1,Text="0 in table",TextColor3=AP.DIM,FontFace=AP.FONT_FACE,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Right,ZIndex=11,Parent=AP.visWin})


    -- row 1: action buttons
    local btnRow1=AP.inst("Frame",{Position=UDim2.new(0,8,0,648),Size=UDim2.new(1,-16,0,26),BackgroundTransparency=1,ZIndex=11,Parent=AP.visWin})
    AP.inst("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),Parent=btnRow1})
    -- row 2: utility buttons
    local btnRow2=AP.inst("Frame",{Position=UDim2.new(0,8,0,678),Size=UDim2.new(1,-16,0,26),BackgroundTransparency=1,ZIndex=11,Parent=AP.visWin})
    AP.inst("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),Parent=btnRow2})
    local function mkBtn(row,txt,col)
        local b=AP.inst("TextButton",{Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
            BackgroundColor3=AP.CARD,Text=txt,TextColor3=col or AP.WHITE,FontFace=AP.FONT_FACE,TextSize=12,AutoButtonColor=false,ZIndex=12,Parent=row})
        AP.inst("UICorner",{CornerRadius=UDim.new(0,6)},b); AP.inst("UIStroke",{Color=col or AP.BORD,Thickness=1,Transparency=col and 0 or 0.9},b)
        AP.inst("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},b)
        b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(35,35,35) end)
        b.MouseLeave:Connect(function() b.BackgroundColor3=AP.CARD end)
        return b
    end
    -- row 1: action adders
    AP.dodgeBtn    = mkBtn(btnRow1,"+ Dodge",nil);     AP.dodgeFwdBtn = mkBtn(btnRow1,"+ Dodge Fwd",nil)
    AP.parryBtn    = mkBtn(btnRow1,"+ Parry",nil);     AP.counterBtn  = mkBtn(btnRow1,"+ Counter",nil)
    AP.blockOnBtn  = mkBtn(btnRow1,"+ Block On",nil);  AP.blockOffBtn = mkBtn(btnRow1,"+ Block Off",nil)
    AP.feintBtn    = mkBtn(btnRow1,"+ Feint",nil);     AP.tableBtn    = mkBtn(btnRow1,"+ Table",nil)
    -- row 2: utility
    AP.clearBtn    = mkBtn(btnRow2,"Clear",nil)
    AP.exportBtn   = mkBtn(btnRow2,"Export",nil);      AP.exportAllBtn= mkBtn(btnRow2,"Export All",nil)


    AP.inst("TextLabel",{Position=UDim2.new(0,8,0,710),Size=UDim2.new(1,-16,0,36),
        BackgroundTransparency=1,Text="Tip: Drag viewport to orbit  ·  Scroll to zoom  ·  Click markers to jump",
        TextColor3=AP.HINT,FontFace=AP.FONT_FACE,TextSize=11,TextWrapped=true,ZIndex=11,Parent=AP.visWin})


    local _gridEnabled,_spinEnabled=true,false
    AP.gridBtn.MouseButton1Click:Connect(function()
        _gridEnabled=not _gridEnabled
        AP.gridBtn.BackgroundColor3=_gridEnabled and Color3.fromRGB(35,35,35) or AP.CARD
        AP.gridBtn.TextColor3=_gridEnabled and AP.WHITE or AP.DIM
    end)
    AP.spinBtn.MouseButton1Click:Connect(function()
        _spinEnabled=not _spinEnabled
        AP.spinBtn.BackgroundColor3=_spinEnabled and Color3.fromRGB(35,35,35) or AP.CARD
        AP.spinBtn.TextColor3=_spinEnabled and AP.WHITE or AP.DIM
        if _spinEnabled then task.spawn(function() while _spinEnabled and AP.visWin.Visible do AP.V.targetRotY=AP.V.targetRotY+0.018; task.wait() end end) end
    end)
    AP.resetBtn.MouseButton1Click:Connect(function() AP.V.targetRotY=0.3; AP.V.targetRotX=0.15; AP.V.targetZoom=6 end)

    AP.vSet=function(msg,col) AP.visStat.Text=msg; AP.visStat.TextColor3=col or AP.DIM end

    AP.vClean=function()
        if AP.V.hb    then AP.V.hb:Disconnect(); AP.V.hb=nil end
        if AP.V.track  then pcall(function()AP.V.track:Stop(0)end); pcall(function()AP.V.track:Destroy()end); AP.V.track=nil end
        if AP.V.animObj then pcall(function()AP.V.animObj:Destroy()end); AP.V.animObj=nil end
        if AP.V.model   then pcall(function()AP.V.model:Destroy()end); AP.V.model=nil end
        if AP.V.cam     then pcall(function()AP.V.cam:Destroy()end); AP.V.cam=nil end
        for _,c in ipairs(AP.vpWorld:GetChildren()) do pcall(function()c:Destroy()end) end
        AP.V.anim8r=nil; AP.V.length=0; AP.V.paused=false
        AP.tlFill.Size=UDim2.new(0,0,1,0); AP.timeFull.Text="0.00 / 0.00"; AP.timeScrub.Text="0.000s"
        if AP.tlLeft then AP.tlLeft.Text="00:00.00" end
        if AP.tlRight then AP.tlRight.Text="00:00.00" end
        AP.setPlayState(false); AP.vpHint.Visible=true
        AP.visStat.Text="Not loaded"; AP.visIdLbl.Text=""
    end

    AP.vLoad=function(animId,sourceModel)
        AP.vClean()
        local char=(sourceModel and sourceModel.Parent and sourceModel) or LP.Character
        if not char then AP.vSet("no character",AP.RED); return end
        local restored={}
        pcall(function()
            for _,d in ipairs(char:GetDescendants()) do if not d.Archivable then d.Archivable=true; table.insert(restored,d) end end
            if not char.Archivable then char.Archivable=true; table.insert(restored,char) end
        end)
        local clone; pcall(function() clone=char:Clone() end)
        for _,d in ipairs(restored) do pcall(function()d.Archivable=false end) end
        if not clone then
            pcall(function()
                local hd=AP.Players:GetHumanoidDescriptionFromUserId(AP.lp.UserId)
                clone=AP.Players:CreateHumanoidModelFromDescription(hd,Enum.HumanoidRigType.R15)
            end)
            if not clone then AP.vSet("clone failed",AP.RED); return end
        end
        for _,d in ipairs(clone:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy()
            elseif d:IsA("BasePart") then d.Anchored=false; d.CanCollide=false; d.CastShadow=false end
        end
        local root=clone:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored=true; root.CFrame=CFrame.new(0,0,0) end
        clone.Parent=AP.vpWorld; AP.V.model=clone
        local hum=clone:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop(0) end end)
            pcall(function()hum:SetStateEnabled(Enum.HumanoidStateType.Running,false)end)
            pcall(function()hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)end)
        end
        local anim8r
        if hum then
            anim8r=hum:FindFirstChildOfClass("Animator") or Instance.new("Animator",hum)
        else
            local ctrl=clone:FindFirstChildWhichIsA("AnimationController",true) or Instance.new("AnimationController",clone)
            anim8r=ctrl:FindFirstChildOfClass("Animator") or Instance.new("Animator",ctrl)
        end
        AP.V.anim8r=anim8r
        local cam=Instance.new("Camera")
        if root then
            AP.V.zoom=AP.V.targetZoom
            local ox=math.sin(AP.V.rotY)*math.cos(AP.V.rotX)*AP.V.zoom
            local oy=math.sin(AP.V.rotX)*AP.V.zoom
            local oz=math.cos(AP.V.rotY)*math.cos(AP.V.rotX)*AP.V.zoom
            cam.CFrame=CFrame.new(root.Position+Vector3.new(ox,oy+1.5,oz),root.Position+Vector3.new(0,1.5,0))
        end
        AP.vpFrame.CurrentCamera=cam; AP.V.cam=cam
        local animObj=Instance.new("Animation"); animObj.AnimationId=animId
        local track; local ok2,err=pcall(function() track=anim8r:LoadAnimation(animObj) end)
        if not ok2 or not track then animObj:Destroy(); AP.vSet("load failed"..(err and ": "..tostring(err) or ""),AP.RED); return end
        AP.V.animObj=animObj; AP.V.track=track
        track.Looped=AP.V.loop; track:Play(0.1,1,AP.V.speed)
        AP.V.paused=false; AP.setPlayState(true); AP.vpHint.Visible=false
        task.spawn(function()
            local t0=os.clock()
            repeat task.wait(0.05) until (AP.V.track and AP.V.track.Length>0) or (os.clock()-t0>0.5)
            if AP.V.track then
                AP.V.length=AP.V.track.Length
                AP.visStat.Text="Playing ID:"; AP.visIdLbl.Text=animId:match("(%d+)$") or "?"
            end
        end)
        AP.V.hb=AP.RunSvc.Heartbeat:Connect(function()
            if not AP.V.track then return end
            if AP.V.track.Length>0 and AP.V.length~=AP.V.track.Length then AP.V.length=AP.V.track.Length end
            local tp=AP.V.track.TimePosition; local len=math.max(AP.V.length,0.001)
            AP.tlFill.Size=UDim2.new(math.clamp(tp/len,0,1),0,1,0)
            AP.timeFull.Text=string.format("%.2f / %.2f",tp,len)
            AP.timeScrub.Text=string.format("%.3fs",tp)
            if AP.tlLeft then AP.tlLeft.Text=string.format("%02d:%02d.%02d",math.floor(tp/60),math.floor(tp)%60,math.floor((tp%1)*100)) end
            if AP.tlRight then AP.tlRight.Text=string.format("%02d:%02d.%02d",math.floor(len/60),math.floor(len)%60,math.floor((len%1)*100)) end
            if AP.V.cam and AP.V.model then
                local r2=AP.V.model:FindFirstChild("HumanoidRootPart")
                if r2 then
                    AP.V.zoom=AP.V.zoom+(AP.V.targetZoom-AP.V.zoom)*0.18
                    AP.V.rotY=AP.V.rotY+(AP.V.targetRotY-AP.V.rotY)*0.18
                    AP.V.rotX=AP.V.rotX+(AP.V.targetRotX-AP.V.rotX)*0.18
                    local ox=math.sin(AP.V.rotY)*math.cos(AP.V.rotX)*AP.V.zoom
                    local oy=math.sin(AP.V.rotX)*AP.V.zoom
                    local oz=math.cos(AP.V.rotY)*math.cos(AP.V.rotX)*AP.V.zoom
                    AP.V.cam.CFrame=CFrame.new(r2.Position+Vector3.new(ox,oy+1.5,oz),r2.Position+Vector3.new(0,1.5,0))
                end
            end
        end)
    end

    AP.visOpenWithId=function(id,entityRef)
        if not id:find("rbxassetid://") then id="rbxassetid://"..id end
        AP.visWin.Visible=true
        if Tog.APShowViz and not Tog.APShowViz.State then Tog.APShowViz:UpdateState(true) end
        if Opt.APAnimationID then Opt.APAnimationID:UpdateText(id) end
        AP.vLoad(id,entityRef)
    end


    AP.scrubSeek=function(xPos)
        if not AP.V.track or AP.V.length<=0 then return end
        local a=AP.tlBg.AbsolutePosition; local s=AP.tlBg.AbsoluteSize
        local t=math.clamp((xPos-a.X)/s.X,0,1)*AP.V.length
        if not AP.V.track.IsPlaying then AP.V.track:Play(0,1,0) end
        AP.V.track:AdjustSpeed(0); AP.V.track.TimePosition=t
    end
    AP.tlHit.MouseButton1Down:Connect(function()
        if not AP.V.track or AP.V.length<=0 then return end
        AP.scrubbing=true; AP.scrubWasPaused=AP.V.paused; AP.V.paused=true
        AP.scrubSeek(AP.UIS:GetMouseLocation().X)
    end)
    AP.UIS.InputChanged:Connect(function(i)
        if AP.scrubbing and i.UserInputType==Enum.UserInputType.MouseMovement then AP.scrubSeek(i.Position.X) end
        if AP.vpDragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            AP.V.targetRotY=AP.V.targetRotY+(i.Position.X-AP.vpLastX)*0.012
            AP.V.targetRotX=AP.V.targetRotX+(i.Position.Y-AP.vpLastY)*0.008
            AP.vpLastX=i.Position.X; AP.vpLastY=i.Position.Y
        end
        if i.UserInputType==Enum.UserInputType.MouseWheel and AP.visWin and AP.visWin.Visible then
            local mp=AP.UIS:GetMouseLocation()
            local ap=AP.vpFrame.AbsolutePosition; local as=AP.vpFrame.AbsoluteSize
            if mp.X>=ap.X and mp.X<=ap.X+as.X and mp.Y>=ap.Y and mp.Y<=ap.Y+as.Y then
                AP.V.targetZoom=math.max(0.5,AP.V.targetZoom-i.Position.Z*1.5)
            end
        end
    end)
    AP.UIS.InputEnded:Connect(function(i)
        if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        if AP.scrubbing then
            AP.scrubbing=false
            if not AP.scrubWasPaused and AP.V.track then AP.V.track:AdjustSpeed(AP.V.speed); AP.V.paused=false; AP.setPlayState(true) end
        end
        AP.vpDragging=false
    end)


    AP.btnPlay.MouseButton1Click:Connect(function()
        if not AP.V.track then
            local id=Opt.APAnimationID and Opt.APAnimationID.Text or ""
            if id=="" then AP.vSet("enter id in UI",AP.DIM); return end
            if not id:find("rbxassetid://") then id="rbxassetid://"..id end
            AP.vLoad(id); return
        end
        if AP.V.paused then AP.V.track:AdjustSpeed(AP.V.speed); AP.V.paused=false; AP.setPlayState(true); AP.visStat.Text="Playing ID:"
        else AP.V.track:AdjustSpeed(0); AP.V.paused=true; AP.setPlayState(false); AP.visStat.Text="Paused" end
    end)
    AP.btnRestart.MouseButton1Click:Connect(function()
        if not AP.V.track then return end
        AP.V.track.TimePosition=0
        if AP.V.paused then AP.V.track:AdjustSpeed(AP.V.speed); AP.V.paused=false; AP.setPlayState(true) end
        AP.visStat.Text="Playing ID:"
    end)
    AP.btnStop.MouseButton1Click:Connect(function() AP.vClean() end)
    AP.loopBtn.MouseButton1Click:Connect(function()
        AP.V.loop=not AP.V.loop
        AP.loopBtn.BackgroundColor3=AP.V.loop and Color3.fromRGB(50,20,90) or AP.CARD
        if AP.V.track then AP.V.track.Looped=AP.V.loop end
    end)
    AP.speedBtn.MouseButton1Click:Connect(function()
        AP.V.spIdx=(AP.V.spIdx%#AP.V.speeds)+1; AP.V.speed=AP.V.speeds[AP.V.spIdx]
        AP.speedBtn.Text=string.format("%.2f×",AP.V.speed)
        if AP.V.track and not AP.V.paused then AP.V.track:AdjustSpeed(AP.V.speed) end
    end)


    do
        local spdDrag=false
        spdTrack.InputBegan:Connect(function(i)
            if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            spdDrag=true
            local pct=math.clamp((i.Position.X-spdTrack.AbsolutePosition.X)/spdTrack.AbsoluteSize.X,0,1)
            AP.V.speed=0.1+pct*4.9; AP.spdFill.Size=UDim2.new(pct,0,1,0); AP.spdHandle.Position=UDim2.new(pct,-5,0.5,-5)
            AP.spdLbl.Text=string.format("%.2f×",AP.V.speed)
            if AP.V.track and not AP.V.paused then AP.V.track:AdjustSpeed(AP.V.speed) end
        end)
        AP.UIS.InputChanged:Connect(function(i)
            if not spdDrag or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
            local pct=math.clamp((i.Position.X-spdTrack.AbsolutePosition.X)/spdTrack.AbsoluteSize.X,0,1)
            AP.V.speed=0.1+pct*4.9; AP.spdFill.Size=UDim2.new(pct,0,1,0); AP.spdHandle.Position=UDim2.new(pct,-5,0.5,-5)
            AP.spdLbl.Text=string.format("%.2f×",AP.V.speed)
            if AP.V.track and not AP.V.paused then AP.V.track:AdjustSpeed(AP.V.speed) end
        end)
        AP.UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then spdDrag=false end end)
    end


    do
        local zDrag=false
        zoomTrack.InputBegan:Connect(function(i)
            if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
            zDrag=true
            local pct=math.clamp((i.Position.X-zoomTrack.AbsolutePosition.X)/zoomTrack.AbsoluteSize.X,0,1)
            AP.V.targetZoom=0.5+pct*19.5; zFill.Size=UDim2.new(pct,0,1,0); zHandle.Position=UDim2.new(pct,-5,0.5,-5)
            AP.zoomLbl.Text=string.format("%.1f",AP.V.targetZoom)
        end)
        AP.UIS.InputChanged:Connect(function(i)
            if not zDrag or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
            local pct=math.clamp((i.Position.X-zoomTrack.AbsolutePosition.X)/zoomTrack.AbsoluteSize.X,0,1)
            AP.V.targetZoom=0.5+pct*19.5; zFill.Size=UDim2.new(pct,0,1,0); zHandle.Position=UDim2.new(pct,-5,0.5,-5)
            AP.zoomLbl.Text=string.format("%.1f",AP.V.targetZoom)
        end)
        AP.UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then zDrag=false end end)
    end


    local function mkParryEntry(action)
        if not AP.V.track then notify("Load an animation first",2); return end
        local tp=AP.V.track.TimePosition
        local id=Opt.APAnimationID and Opt.APAnimationID.Text or ""
        local name=Opt.APTimingName and Opt.APTimingName.Text or ""
        if id=="" then notify("No animation ID",2); return end
        if name=="" then name=(id:match("(%d+)$") or "?").."_"..action:lower() end
        if not id:find("rbxassetid://") then id="rbxassetid://"..id end

        if AP.timings[id] then
            for _,e in ipairs(AP.timings[id]) do
                if e.name==name and e.action==action then notify("Already saved as: "..name.." ("..action..")",2); return end
            end
        end
        local dist0=Opt.APMinDist and Opt.APMinDist.Value or 0
        local dist1=Opt.APMaxDist and Opt.APMaxDist.Value or 25
        local e={name=name,animId=id,delay=tp,minDist=dist0,maxDist=dist1,action=action,
            DodgeDirection=Opt.APDodgeDir and Opt.APDodgeDir.Value or "None",
            FullHoldBlock=(Opt.APFullBlock and Opt.APFullBlock.Value=="true") or false,
            MovingAttack=(Opt.APMovingAtk and Opt.APMovingAtk.Value=="true") or false,
            Repeat=Opt.APRepeat and Opt.APRepeat.Value or 1,
            RepeatDelay=Opt.APRepeatDelay and Opt.APRepeatDelay.Value or 0.35,
            StartDelay=Opt.APStartDelay and Opt.APStartDelay.Value or 0,
            TriggerDistance=Opt.APTriggerDist and Opt.APTriggerDist.Value or 12,
        }
        table.insert(AP.savedTimings,e)
        if not AP.timings[id] then AP.timings[id]={} end; table.insert(AP.timings[id],e)
        local ns={}; for _,x in ipairs(AP.savedTimings) do table.insert(ns,x.name) end
        pcall(function() Opt.APSavedTimings:ClearOptions(); Opt.APSavedTimings:InsertOptions(ns); Opt.APSavedTimings:UpdateSelection(name) end)
        AP.saveTimings()
        local n=#AP.savedTimings; AP.parryCountLbl.Text=n.." in table"
        notify(action.." saved: "..name.." @ "..string.format("%.3fs",tp),2)
    end
    AP.dodgeBtn.MouseButton1Click:Connect(function() mkParryEntry("Dodge") end)
    AP.dodgeFwdBtn.MouseButton1Click:Connect(function() mkParryEntry("Dodge Forward") end)
    AP.parryBtn.MouseButton1Click:Connect(function() mkParryEntry("Parry") end)
    AP.counterBtn.MouseButton1Click:Connect(function() mkParryEntry("Counter") end)
    AP.blockOnBtn.MouseButton1Click:Connect(function() mkParryEntry("Block Start") end)
    AP.blockOffBtn.MouseButton1Click:Connect(function() mkParryEntry("Block End") end)
    AP.feintBtn.MouseButton1Click:Connect(function() mkParryEntry("Feint") end)
    AP.tableBtn.MouseButton1Click:Connect(function() mkParryEntry(Opt.APAction and Opt.APAction.Value or "Parry") end)
    AP.clearBtn.MouseButton1Click:Connect(function()
        AP.savedTimings={}; AP.timings={}; AP.commAutoLoaded=true
        AP.saveTimings(); AP.parryCountLbl.Text="0 in table"
        task.defer(function()
            pcall(function()
                Opt.APSavedTimings:SetValue(nil)
                Opt.APSavedTimings:ClearOptions()
                Opt.APSavedTimings:InsertOptions({"--"})
                Opt.APSavedTimings:UpdateSelection(1)
            end)
        end)
        notify("Table cleared",2)
    end)
    AP.exportBtn.MouseButton1Click:Connect(function()
        local ls={};for _,e in ipairs(AP.savedTimings) do table.insert(ls,string.format('  ["%s"]={name="%s",delay=%.3f,minDist=%d,maxDist=%d,action="%s"}',e.animId,e.name,e.delay,e.minDist,e.maxDist,e.action)) end
        if setclipboard then setclipboard("local TIMINGS={\n"..table.concat(ls,",\n").."\n}") end; notify("Exported!",2)
    end)
    AP.exportAllBtn.MouseButton1Click:Connect(function()
        if setclipboard then setclipboard(AP.serializeTimings and AP.serializeTimings() or "{}") end; notify("Exported All!",2)
    end)


    AP.logWin,AP.logX=AP.makeWin(AP.sg,UDim2.new(1,-700,0,50),UDim2.new(0,680,0,740),"Zero Hub  ·  Logger")
    AP.logX.MouseButton1Click:Connect(function() AP.logWin.Visible=false; if Tog.APEnableLogger then Tog.APEnableLogger:UpdateState(false) end end)
    local loggedRow=AP.inst("Frame",{Position=UDim2.new(0,8,0,38),Size=UDim2.new(1,-16,0,28),BackgroundColor3=AP.CARD,BorderSizePixel=0,ZIndex=12,Parent=AP.logWin})
    AP.inst("UICorner",{CornerRadius=UDim.new(0,6)},loggedRow); AP.inst("UIStroke",{Color=AP.BORD,Thickness=1,Transparency=0.9},loggedRow)
    AP.loggedCountLbl=AP.inst("TextLabel",{Position=UDim2.new(0,10,0,0),Size=UDim2.new(1,-16,1,0),BackgroundTransparency=1,Text="Logged: 0",TextColor3=AP.WHITE,FontFace=AP.FONT_FACE,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=13,Parent=loggedRow})
    AP.logScroll=AP.inst("ScrollingFrame",{Position=UDim2.new(0,8,0,72),Size=UDim2.new(1,-16,1,-80),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=AP.ACC,CanvasSize=UDim2.new(0,0,0,0),ZIndex=12,Parent=AP.logWin})
    AP.logList=AP.inst("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5),Parent=AP.logScroll})
    AP.logList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() AP.logScroll.CanvasSize=UDim2.new(0,0,0,AP.logList.AbsoluteContentSize.Y+8) end)
    AP.inst("UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4),Parent=AP.logScroll})
    AP.logLineObjs={}; AP.selObj=nil
    local function updCount() if AP.loggedCountLbl then AP.loggedCountLbl.Text="Logged: "..#AP.logLineObjs end end

    local function mkLogBtn(parent,xOff)
        local b=AP.inst("TextButton",{Position=UDim2.new(1,xOff,0.5,-14),Size=UDim2.new(0,28,0,28),
            BackgroundColor3=AP.CARD,Text="",AutoButtonColor=false,ZIndex=15,Parent=parent})
        AP.inst("UICorner",{CornerRadius=UDim.new(0,6)},b)
        AP.inst("UIStroke",{Color=AP.BORD,Thickness=1,Transparency=0.9},b)
        b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(35,35,35) end)
        b.MouseLeave:Connect(function() b.BackgroundColor3=AP.CARD end)
        return b
    end

    AP.addLogLine=function(entry)
        local numId=entry.id:match("(%d+)$") or entry.id
        local animName=entry.animName or numId
        local distTxt=entry.dist and string.format(" · %.0fm",entry.dist) or ""
        local srcTxt=(entry.source and entry.source~="Unknown" and entry.source or "?")..distTxt

        local card=AP.inst("Frame",{Size=UDim2.new(1,0,0,68),BackgroundColor3=AP.CARD,BorderSizePixel=0,ZIndex=13,LayoutOrder=#AP.logLineObjs+1,Parent=AP.logScroll})
        AP.inst("UICorner",{CornerRadius=UDim.new(0,8)},card)
        AP.inst("UIStroke",{Color=AP.BORD,Thickness=1,Transparency=0.9},card)

        local nameLbl=AP.inst("TextLabel",{Position=UDim2.new(0,12,0,8),Size=UDim2.new(1,-100,0,20),
            BackgroundTransparency=1,Text=animName,TextColor3=AP.WHITE,FontFace=AP.FONT_FACE,TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=14,Parent=card})
        AP.inst("TextLabel",{Position=UDim2.new(0,12,0,30),Size=UDim2.new(1,-100,0,14),
            BackgroundTransparency=1,Text=srcTxt,TextColor3=AP.DIM,FontFace=AP.FONT_FACE,TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=14,Parent=card})
        AP.inst("TextLabel",{Position=UDim2.new(0,12,0,46),Size=UDim2.new(1,-100,0,14),
            BackgroundTransparency=1,Text=numId,TextColor3=AP.HINT,FontFace=AP.FONT_FACE,TextSize=10,
            TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=14,Parent=card})

        -- copy button (original hand-drawn icon)
        local copyBtn=mkLogBtn(card,-104)
        do
            local s1=AP.inst("Frame",{Position=UDim2.new(0,5,0,7),Size=UDim2.new(0,13,0,13),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=16,Parent=copyBtn})
            AP.inst("UICorner",{CornerRadius=UDim.new(0,2)},s1); AP.inst("UIStroke",{Color=AP.DIM,Thickness=1.5},s1)
            local s2=AP.inst("Frame",{Position=UDim2.new(0,10,0,8),Size=UDim2.new(0,13,0,13),BackgroundColor3=AP.CARD,BorderSizePixel=0,ZIndex=17,Parent=copyBtn})
            AP.inst("UICorner",{CornerRadius=UDim.new(0,2)},s2); AP.inst("UIStroke",{Color=AP.WHITE,Thickness=1.5},s2)
        end
        -- add button
        local addBtn=mkLogBtn(card,-68)
        AP.inst("TextLabel",{Position=UDim2.new(0,0,0,0),Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="+",TextColor3=AP.WHITE,FontFace=AP.FONT_FACE,TextSize=18,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=16,Parent=addBtn})
        -- block button (original hand-drawn lock icon)
        local blockBtn=mkLogBtn(card,-32)
        do
            local lid=AP.inst("Frame",{Position=UDim2.new(0,6,0,6),Size=UDim2.new(0,16,0,3),BackgroundColor3=AP.WHITE,BorderSizePixel=0,ZIndex=16,Parent=blockBtn})
            AP.inst("UICorner",{CornerRadius=UDim.new(0,1)},lid)
            AP.inst("Frame",{Position=UDim2.new(0,5,0,-2),Size=UDim2.new(0,6,0,3),BackgroundColor3=AP.WHITE,BorderSizePixel=0,ZIndex=16,Parent=lid})
            local body=AP.inst("Frame",{Position=UDim2.new(0,7,0,11),Size=UDim2.new(0,14,0,12),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=16,Parent=blockBtn})
            AP.inst("UICorner",{CornerRadius=UDim.new(0,2)},body); AP.inst("UIStroke",{Color=AP.WHITE,Thickness=1.5},body)
            local function vline(xOff) AP.inst("Frame",{Position=UDim2.new(0,xOff,0,2),Size=UDim2.new(0,1.5,1,-4),BackgroundColor3=AP.WHITE,BorderSizePixel=0,ZIndex=17,Parent=body}) end
            vline(4); vline(8)
        end

        local obj={card=card,lbl=nameLbl,id=entry.id,source=entry.source or "",entity=entry.entity}
        table.insert(AP.logLineObjs,obj)
        updCount()

        local function deselPrev()
            if AP.selObj then
                pcall(function() AP.selObj.card.BackgroundColor3=AP.CARD; AP.selObj.lbl.TextColor3=AP.WHITE end)
                AP.selObj=nil
            end
        end

        local function onSelect()
            deselPrev()
            AP.selObj=obj
            card.BackgroundColor3=Color3.fromRGB(28,15,55); nameLbl.TextColor3=AP.ACC
            if setclipboard then setclipboard(entry.id) end
            if Opt.APAnimationID then Opt.APAnimationID:UpdateText(entry.id) end
            local linked=AP.timings and AP.timings[entry.id]
            if linked and #linked>0 then
                local names={}; for _,t in ipairs(linked) do table.insert(names,t.name) end
                notify("ID "..numId.." → "..table.concat(names,", "),3)
            else
                notify("Copied: "..numId,2)
            end
            if AP.visOpenWithId then AP.visOpenWithId(entry.id,entry.entity) end
        end

        local function onAdd()
            if AP.timings[entry.id] and #AP.timings[entry.id]>0 then notify("Already saved: "..animName,2); return end
            local e={name=animName,animId=entry.id,delay=0,minDist=0,maxDist=25,action="Parry",
                DodgeDirection="None",FullHoldBlock=false,MovingAttack=false,Repeat=1,RepeatDelay=0.35,StartDelay=0,TriggerDistance=12}
            table.insert(AP.savedTimings,e)
            if not AP.timings[entry.id] then AP.timings[entry.id]={} end
            table.insert(AP.timings[entry.id],e)
            local ns={}; for _,x in ipairs(AP.savedTimings) do table.insert(ns,x.name) end
            pcall(function() Opt.APSavedTimings:ClearOptions(); Opt.APSavedTimings:InsertOptions(ns); Opt.APSavedTimings:UpdateSelection(animName) end)
            if Opt.APTimingName  then Opt.APTimingName:UpdateText(animName)  end
            if Opt.APAnimationID then Opt.APAnimationID:UpdateText(entry.id) end
            AP.saveTimings(); notify("Added: "..animName.."  (tweak delay in builder)",2)
        end

        local function onBlock()
            AP.logBlacklist[entry.id]=true
            AP.loggedMap[entry.id]=nil
            if AP.selObj==obj then AP.selObj=nil end
            for i,o in ipairs(AP.logLineObjs) do
                if o==obj then table.remove(AP.logLineObjs,i); break end
            end
            pcall(function() card:Destroy() end)
            updCount(); notify("Blocked: "..animName,2)
        end

        local zone=AP.inst("TextButton",{Position=UDim2.new(0,0,0,0),Size=UDim2.new(1,-110,1,0),BackgroundTransparency=1,Text="",ZIndex=15,Parent=card})
        zone.MouseButton1Click:Connect(onSelect)
        copyBtn.MouseButton1Click:Connect(onSelect)
        addBtn.MouseButton1Click:Connect(onAdd)
        blockBtn.MouseButton1Click:Connect(onBlock)
        card.MouseEnter:Connect(function() if AP.selObj~=obj then card.BackgroundColor3=Color3.fromRGB(32,32,32) end end)
        card.MouseLeave:Connect(function() if AP.selObj~=obj then card.BackgroundColor3=AP.CARD end end)
        task.defer(function()
            local atBottom=AP.logScroll.CanvasPosition.Y>=(AP.logList.AbsoluteContentSize.Y-AP.logScroll.AbsoluteSize.Y-80)
            if atBottom then AP.logScroll.CanvasPosition=Vector2.new(0,math.max(0,AP.logList.AbsoluteContentSize.Y-AP.logScroll.AbsoluteSize.Y)) end
        end)
    end

    AP.clearLog=function()
        for _,o in ipairs(AP.logLineObjs) do pcall(function() if o.card then o.card:Destroy() end end) end
        AP.logLineObjs={}; AP.selObj=nil; AP.loggedAnims={}; AP.loggedMap={}
        AP.logScroll.CanvasSize=UDim2.new(0,0,0,0); updCount()
    end


    AP.stL=function(c) return string.lower(tostring(c and c:GetAttribute("CurrentState") or "")) end
    AP.rtt=function() local n=game:GetService("Stats"):FindFirstChild("Network"); local s=n and n:FindFirstChild("ServerStatsItem"); local d=s and s:FindFirstChild("Data Ping"); local v=d and d:GetValue()/1000 or 0.05; return math.clamp(v,0.02,0.4) end
    pcall(function() AP.Combat  = ReplicatedStorage.Requests.Combat end)
    pcall(function() AP.Dash    = ReplicatedStorage.Requests.Dash end)
    pcall(function() AP.Counter = ReplicatedStorage.Requests.RedCounter end)
    AP.sBlock=function(st) pcall(function() AP.Combat:FireServer("Block",st) end); return true end
    AP.sDodge=function() pcall(function() AP.Dash:InvokeServer("RightVector",-73) end) end
    AP.sDodgeFwd=function() pcall(function() AP.Dash:InvokeServer("LookVector",-73) end) end
    AP.sCounter=function() pcall(function() AP.Counter:FireServer() end) end
    AP.sFeint=function() pcall(function() AP.Combat:FireServer("Feint") end) end
    AP.sParry=function()
        if AP.parryCD then return false end
        local rtt=AP.rtt()
        -- under lag the parry window needs to stay open longer
        local blockHold=math.max(0.25, 0.25+rtt)
        local cdTime=math.max(0.2, 0.15+rtt*0.5)
        AP.parryCD=true; task.delay(cdTime, function() AP.parryCD=false end)
        AP.sBlock(true)
        task.defer(function() AP.sBlock(true) end)
        task.delay(blockHold, function() AP.sBlock(false) end)
        return true
    end
    AP.cParry=function()
        if AP.parryCD then return false end
        local char=AP.lp.Character
        if not char then return false end
        if char:GetAttribute("ParryCooldown") then return false end
        local state=char:GetAttribute("CurrentState")
        if state=="Unconscious" then return false end
        if state=="Blocking" or state=="ParrySuccess" then return false end
        local living=workspace:FindFirstChild("Living")
        local myModel=living and living:FindFirstChild(AP.lp.Name)
        local status=myModel and myModel:FindFirstChild("Status")
        local blockingVal=status and status:FindFirstChild("Blocking")
        if blockingVal and blockingVal.Value>0 then return false end
        local attackSlowVal=status and status:FindFirstChild("AttackSlow")
        if attackSlowVal and attackSlowVal.Value>0 then return false end
        local atkVal=status and status:FindFirstChild("Attacking")
        local attacking=atkVal and atkVal.Value and atkVal.Value>0
        if not attacking and AP.Controls then
            local ok=pcall(function() if AP.Controls:IsActionHeld("Block") then error() end end); if not ok then return false end
        end
        return true
    end
    AP.cDodge=function()
        if (os.clock()-AP.lastDodge)<1.75 then return false end
        local char=AP.lp.Character; if not char then return false end
        local s=AP.stL(char); if s:find("dash") or s:find("dodge") then return false end
        return true
    end
    AP.doParry=function()
        if not Tog.APAutoParry or not Tog.APAutoParry.State then return end
        if AP.cParry() then if AP.sParry() then AP.lastParry=os.clock() end
        elseif AP.cDodge() then AP.sDodge(); AP.lastDodge=os.clock() end
    end


    local PH_MAX=6
    AP.recordPos=function(root) if not root or not root.Parent then return end; local h=AP.posHistory[root]; if not h then h={}; AP.posHistory[root]=h end; table.insert(h,{pos=root.Position,t=os.clock()}); if #h>PH_MAX then table.remove(h,1) end end
    AP.getVelocity=function(root) local h=AP.posHistory[root]; if not h or #h<2 then return Vector3.zero end; local newest=h[#h]; local oldest=h[1]; local dt=newest.t-oldest.t; if dt<=0 then return Vector3.zero end; return (newest.pos-oldest.pos)/dt end
    AP.extrapolatePos=function(root,ahead) if not root or not root.Parent then return nil end; return root.Position+AP.getVelocity(root)*ahead end
    AP.distTo=function(root) local c=AP.lp.Character; if not c then return nil end; local r=c:FindFirstChild("HumanoidRootPart"); if not r or not root then return nil end; local extraPos=AP.extrapolatePos(root,0.1) or root.Position; return (r.Position-extraPos).Magnitude end

    AP.doLogAnim=function(id,src,dist,entityRef,animName)
        if not Tog.APEnableLogger or not Tog.APEnableLogger.State then return end
        local numId=id:match("%?id=(%d+)") or id:match("rbxassetid://(%d+)") or id:match("^(%d+)$")
        if numId then id="rbxassetid://"..numId end
        if id=="" or id=="rbxassetid://0" then return end
        if AP.logBlacklist[id] then return end
        local maxR=Opt.APLogRadius and Opt.APLogRadius.Value or 1000
        if dist and dist>maxR then return end
        if AP.loggedMap[id] then return end
        AP.loggedMap[id]=true
        local entry={id=id,source=src or "Unknown",dist=dist,entity=entityRef,animName=animName}
        table.insert(AP.loggedAnims,entry)
        if #AP.loggedAnims>120 then
            local old=table.remove(AP.loggedAnims,1)
            AP.loggedMap[old.id]=nil
        end
        AP.addLogLine(entry)
    end
    AP.visualizeHitbox=function(root,col)
        if not Tog.APShowHitbox or not Tog.APShowHitbox.State then return end
        if not root then return end
        local hbX=Opt.APHitboxX and Opt.APHitboxX.Value or 0
        local hbY=Opt.APHitboxY and Opt.APHitboxY.Value or 0
        local hbZ=Opt.APHitboxZ and Opt.APHitboxZ.Value or 4
        local c=col or Color3.fromRGB(138,79,255)
        local p=Instance.new("Part")
        p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; p.CastShadow=false
        p.Transparency=1; p.Size=Vector3.new(6,6,8)
        p.CFrame=CFrame.new(root.Position+root.CFrame.RightVector*hbX+Vector3.new(0,hbY,0)+root.CFrame.LookVector*hbZ)
        p.Parent=workspace
        local sel=Instance.new("SelectionBox")
        sel.Adornee=p; sel.Color3=c; sel.LineThickness=0.06
        sel.SurfaceColor3=c; sel.SurfaceTransparency=0.78
        sel.Parent=workspace
        AP.Debris:AddItem(p,0.4); AP.Debris:AddItem(sel,0.4)
    end


    AP.RunSvc.PreSimulation:Connect(function()
        for _,v in ipairs(AP.activeTriggers) do if v.root and v.root.Parent then AP.recordPos(v.root) end end
        for i=#AP.activeTriggers,1,-1 do
            local v=AP.activeTriggers[i]; local remove=false; local fire=false
            if os.clock()-(v.created or 0)>1 then remove=true
            elseif not v.root or not v.root.Parent then remove=true
            elseif not v.track.IsPlaying then if v.track.TimePosition<v.triggerTime and v.track.TimePosition>0 then remove=true;fire=true else remove=true end
            elseif v.track.TimePosition>=v.triggerTime then remove=true;fire=true end
            if remove then table.remove(AP.activeTriggers,i) end
            if fire and Tog.APAutoParry and Tog.APAutoParry.State then
                local timeLeft=math.max((v.triggerTime or 0)-(v.track and v.track.TimePosition or 0),0)
                local extraPos=AP.extrapolatePos(v.root,timeLeft)
                local mc=AP.lp.Character; local mr=mc and mc:FindFirstChild("HumanoidRootPart")
                local liveD=mr and extraPos and (mr.Position-extraPos).Magnitude or AP.distTo(v.root)
                if liveD and liveD>=(v.minDist or 0) and liveD<=(v.maxDist or 25) then
                    if Tog.APPlayersOnly and Tog.APPlayersOnly.State and not v.isPlayer then
                    elseif Tog.APMobsOnly and Tog.APMobsOnly.State and v.isPlayer then
                    else
                    AP.visualizeHitbox(v.root, v.action=="Parry" and Color3.fromRGB(138,79,255) or Color3.fromRGB(252,190,57))
                    local dispName=(v.name~="" and v.name) or (v.src or "?")
                    if Tog.APNotifyAction and Tog.APNotifyAction.State then notify(v.action.."  →  "..dispName, 2) end
                    if     v.action=="Parry"      then if AP.cParry() then if AP.sParry() then AP.lastParry=os.clock() end end
                    elseif v.action=="Block Start" then AP.sBlock(true); task.delay(1.5, function() AP.sBlock(false) end)
                    elseif v.action=="Block End"   then AP.sBlock(false)
                    elseif v.action=="Dodge"         then if AP.cDodge() then AP.sDodge(); AP.lastDodge=os.clock() end
                    elseif v.action=="Dodge Forward" then if AP.cDodge() then AP.sDodgeFwd(); AP.lastDodge=os.clock() end
                    elseif v.action=="Counter"       then AP.sCounter()
                    elseif v.action=="Feint"         then AP.sFeint()
                    elseif v.action=="M1+Feint"      then AP.sFeint()
                    end
                    end  -- players/mobs only
                end
            end
        end
    end)


    AP.isFacingYou=function(er) local mc=AP.lp.Character; if not mc then return false end; local mr=mc:FindFirstChild("HumanoidRootPart"); if not mr then return false end; return er.CFrame.LookVector:Dot((mr.Position-er.Position).Unit)>0.7 end
    AP.isClosestThreat=function(root) local mc=AP.lp.Character; if not mc then return true end; local mr=mc:FindFirstChild("HumanoidRootPart"); if not mr then return true end; local md=(mr.Position-root.Position).Magnitude; for _,v in ipairs(workspace:GetChildren()) do if v:IsA("Model") and v~=mc then local r=v:FindFirstChild("HumanoidRootPart"); local h=v:FindFirstChildOfClass("Humanoid"); if r and h and h.Health>0 and (mr.Position-r.Position).Magnitude<md-1 then return false end end end; return true end
    AP.isInFrontHitbox=function(root) local mc=AP.lp.Character; if not mc then return false end; local mr=mc:FindFirstChild("HumanoidRootPart"); if not mr then return false end; return root.CFrame.LookVector:Dot((mr.Position-root.Position).Unit)>0.6 end
    AP.watchAnimator=function(animator)
        if AP.watchedAnims[animator] then return end; AP.watchedAnims[animator]=true
        table.insert(AP.conns,animator.Destroying:Connect(function() AP.watchedAnims[animator]=nil; AP.posHistory[animator]=nil end))
        local entity=animator:FindFirstAncestorWhichIsA("Model"); local src=entity and entity.Name or "Unknown"
        local c=animator.AnimationPlayed:Connect(function(track)
            local isOwn = entity and entity==AP.lp.Character
            if isOwn and not (Tog.APLogSelf and Tog.APLogSelf.State) then return end

            -- log ALL animations (including looped/short) so the logger sees everything
            local aid=tostring(track.Animation and track.Animation.AnimationId or "")
            local nid=aid:match("%?id=(%d+)") or aid:match("rbxassetid://(%d+)") or aid:match("^(%d+)$")
            if nid then aid="rbxassetid://"..nid end
            if aid~="" then if not (AP.logBlacklist and AP.logBlacklist[aid]) then local root2=entity and entity:FindFirstChild("HumanoidRootPart"); task.defer(AP.doLogAnim,aid,src,root2 and AP.distTo(root2),entity,(track.Name~="" and track.Name~="Animation" and track.Name~="animation") and track.Name or nil) end end
            -- parry filters: skip looped/short/whitelisted animations
            if track.Length and track.Length>0 and track.Length<0.1 then return end
            if track.Looped then return end
            if AP.whitelist then local plr=PS:GetPlayerFromCharacter(entity); if plr and AP.whitelist[plr.Name] then return end end
            local tList=AP.timings[aid]; if not tList then return end
            local root=entity and entity:FindFirstChild("HumanoidRootPart"); if not root then return end
            local d=AP.distTo(root); if not d then return end
            local hbRange=Opt.APHitboxRange and Opt.APHitboxRange.Value or 15
            local hbX=Opt.APHitboxX and Opt.APHitboxX.Value or 0; local hbY=Opt.APHitboxY and Opt.APHitboxY.Value or 0; local hbZ=Opt.APHitboxZ and Opt.APHitboxZ.Value or 4
            local mc2=AP.lp.Character; local mr2=mc2 and mc2:FindFirstChild("HumanoidRootPart")
            local offsetPos=root.Position+root.CFrame.RightVector*hbX+Vector3.new(0,hbY,0)+root.CFrame.LookVector*hbZ
            local offsetDist=mr2 and (mr2.Position-offsetPos).Magnitude or d
            if offsetDist>hbRange then return end
            if Tog.APFOVCheck and Tog.APFOVCheck.State and not AP.isFacingYou(root) then return end
            if Tog.APHitboxDirCheck and Tog.APHitboxDirCheck.State and not AP.isInFrontHitbox(root) then return end
            if Tog.APClosestOnly and Tog.APClosestOnly.State and not AP.isClosestThreat(root) then return end
            for _,t in ipairs(tList) do
                local minD=t.minDist or 0; local maxD=(t.maxDist and t.maxDist>0) and t.maxDist or 25
                if d>=minD and d<=maxD then
                    local cdKey=aid..t.name..tostring(entity)
                    if not AP.animCooldowns[cdKey] or os.clock()-AP.animCooldowns[cdKey]>=0.1 then
                        AP.animCooldowns[cdKey]=os.clock()
                        local vel=root.AssemblyLinearVelocity.Magnitude
                        local triggerTime=math.max((t.delay or 0)-AP.rtt()-math.clamp(vel/50,0,0.08),0)
                        if #AP.activeTriggers<100 then
                            local isPlr=AP.Players:GetPlayerFromCharacter(entity)~=nil
                            table.insert(AP.activeTriggers,{track=track,triggerTime=triggerTime,src=src,action=t.action or "Parry",name=t.name or "",root=root,minDist=minD,maxDist=maxD,isPlayer=isPlr,created=os.clock()})
                        end
                    end
                end
            end
        end)
        table.insert(AP.conns,c)
    end
    AP.watchPlayer=function(p)
        if p==AP.lp then return end
        local function onChar(c) task.wait(); for _,d in next,c:GetDescendants() do if d:IsA("Animator") then AP.watchAnimator(d) end end end
        if p.Character then onChar(p.Character) end
        table.insert(AP.conns,p.CharacterAdded:Connect(onChar))
    end
    table.insert(AP.conns,workspace.DescendantAdded:Connect(function(d)
        if d:IsA("Animator") then AP.watchAnimator(d)
        elseif d:IsA("AnimationController") then
            local a=d:FindFirstChildOfClass("Animator"); if a then AP.watchAnimator(a) end
            table.insert(AP.conns,d.ChildAdded:Connect(function(c) if c:IsA("Animator") then AP.watchAnimator(c) end end))
        end
    end))
    AP.fullScan=function() for _,d in next,workspace:GetDescendants() do if d:IsA("Animator") then AP.watchAnimator(d) elseif d:IsA("AnimationController") then local a=d:FindFirstChildOfClass("Animator"); if a then AP.watchAnimator(a) end end end end
    AP.fullScan(); task.delay(3,AP.fullScan)
    for _,p in next,AP.Players:GetPlayers() do AP.watchPlayer(p) end
    table.insert(AP.conns,AP.Players.PlayerAdded:Connect(AP.watchPlayer))


    Tog.APAutoParry = APL:Toggle({ Name="Auto Parry", Default=false, Callback=function() end }, "APAutoParry")
    Tog.APNotifyAction = APL:Toggle({ Name="Action Notify", Default=false, Callback=function() end }, "APNotifyAction")
    Tog.APShowHitbox = APL:Toggle({ Name="Show Hitboxes", Default=false, Callback=function() end }, "APShowHitbox")
    APL:Divider()
    Tog.APFOVCheck       = APL:Toggle({ Name="FOV Check",    Default=false, Callback=function() end }, "APFOVCheck")
    Tog.APClosestOnly    = APL:Toggle({ Name="Closest Only", Default=false, Callback=function() end }, "APClosestOnly")
    Tog.APHitboxDirCheck = APL:Toggle({ Name="Dir Check",    Default=false, Callback=function() end }, "APHitboxDirCheck")
    APL:Divider()
    Tog.APPlayersOnly = APL:Toggle({ Name="Players Only", Default=false, Callback=function() end }, "APPlayersOnly")
    Tog.APMobsOnly    = APL:Toggle({ Name="Mobs Only",    Default=false, Callback=function() end }, "APMobsOnly")
    APL:Divider()
    Opt.APHitboxRange = APL:Slider({ Name="Range",    Default=200, Minimum=1,   Maximum=500, Precision=0, Callback=function() end }, "APHitboxRange")
    Opt.APHitboxX     = APL:Slider({ Name="Hitbox X", Default=0,  Minimum=-20, Maximum=20,  Precision=1, Callback=function() end }, "APHitboxX")
    Opt.APHitboxY     = APL:Slider({ Name="Hitbox Y", Default=0,  Minimum=-20, Maximum=20,  Precision=1, Callback=function() end }, "APHitboxY")
    Opt.APHitboxZ     = APL:Slider({ Name="Hitbox Z", Default=4,  Minimum=-20, Maximum=20,  Precision=1, Callback=function() end }, "APHitboxZ")


    AP.FL={conn=nil,stickyTarget=nil,arStore={stored=false,data=nil,value=nil}}
    local function flRestoreAR() local st=AP.FL.arStore; if not st.stored then return end; pcall(function() st.data.AutoRotate=st.value end); st.stored=false end
    local function flGetTarget()
        local char=LP.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end
        local living=workspace:FindFirstChild("Living"); if not living then return nil end
        local best,bestDist=nil,math.huge
        for _,ent in next,living:GetChildren() do
            if ent==char or PS:GetPlayerFromCharacter(ent) then continue end
            local hum=ent:FindFirstChildWhichIsA("Humanoid"); local root=ent:FindFirstChild("HumanoidRootPart")
            if not hum or not root or hum.Health<=0 then continue end
            local d=(root.Position-hrp.Position).Magnitude; if d<bestDist then bestDist=d; best={hum=hum,root=root} end
        end
        return best
    end
    Tog.FaceLock = APL2:Toggle({
        Name="Face Lock", Default=false,
        Callback=function(p)
            if AP.FL.conn then AP.FL.conn:Disconnect(); AP.FL.conn=nil end
            flRestoreAR(); AP.FL.stickyTarget=nil
            if not p then return end
            AP.FL.conn=RS.RenderStepped:Connect(function()
                local char=LP.Character; if not char then return end
                local hum=char:FindFirstChildWhichIsA("Humanoid"); local hrp=char:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp or hum.PlatformStand then flRestoreAR(); return end
                if Tog.FLStickyTarget and Tog.FLStickyTarget.State then AP.FL.stickyTarget=AP.FL.stickyTarget or flGetTarget() else AP.FL.stickyTarget=nil end
                local t=AP.FL.stickyTarget or flGetTarget()
                if not t or not t.root.Parent or t.hum.Health<=0 then flRestoreAR(); AP.FL.stickyTarget=nil; return end
                local targetPos=t.root.Position
                if not (Tog.FLVertical and Tog.FLVertical.State) then targetPos=Vector3.new(targetPos.X,hrp.Position.Y,targetPos.Z) end
                local st=AP.FL.arStore; if not st.stored then st.data=hum; st.value=hum.AutoRotate; st.stored=true end
                hum.AutoRotate=false
                local targetCF=CFrame.lookAt(hrp.Position,targetPos)
                if Tog.FLSmoothing and Tog.FLSmoothing.State then hrp.CFrame=hrp.CFrame:Lerp(targetCF,0.2) else hrp.CFrame=targetCF end
            end)
        end
    }, "FaceLock")
    Tog.FLStickyTarget = APL2:Toggle({ Name="Sticky Target", Default=false, Callback=function() end }, "FLStickyTarget")
    Tog.FLVertical     = APL2:Toggle({ Name="Vertical",      Default=false, Callback=function() end }, "FLVertical")
    Tog.FLSmoothing    = APL2:Toggle({ Name="Smooth",        Default=false, Callback=function() end }, "FLSmoothing")
    onUnload(function() if AP.FL.conn then AP.FL.conn:Disconnect() end; flRestoreAR() end)
    APL2:Divider()

    Opt.APSavedTimings = APL3:Dropdown({ Name="Saved Timings", Search=true, Options={"--"}, Default=1, Multi=false, Callback=function(v)
        local s=type(v)=="table" and next(v) or v; if not s or s=="--" then return end
        for _,e in ipairs(AP.savedTimings) do
            if e.name==s then
                pcall(function()
                    Opt.APTimingName:UpdateText(e.name); Opt.APAnimationID:UpdateText(e.animId)
                    Opt.APDelayS:UpdateText(tostring(math.floor(e.delay*1000)))
                    Opt.APMinDist:UpdateValue(e.minDist or 0); Opt.APMaxDist:UpdateValue(e.maxDist or 25)
                    Opt.APAction:UpdateSelection(e.action or "Parry")
                    Opt.APDodgeDir:UpdateSelection(e.DodgeDirection or "None")
                    Opt.APFullBlock:UpdateSelection(e.FullHoldBlock and "true" or "false")
                    Opt.APMovingAtk:UpdateSelection(e.MovingAttack and "true" or "false")
                    Opt.APRepeat:UpdateValue(e.Repeat or 1)
                    Opt.APRepeatDelay:UpdateValue(e.RepeatDelay or 0.35)
                    Opt.APStartDelay:UpdateValue(e.StartDelay or 0)
                    Opt.APTriggerDist:UpdateValue(e.TriggerDistance or 12)
                end); break
            end
        end
    end }, "APSavedTimings")
    Opt.APTimingName  = APL3:Input({ Name="Name",           Placeholder="e.g. monster m1",    AcceptedCharacters="All",     Callback=function() end }, "APTimingName")
    Opt.APAnimationID = APL3:Input({ Name="Animation ID",   Placeholder="rbxassetid://123456", AcceptedCharacters="All",     Callback=function() end }, "APAnimationID")
    Opt.APDelayS      = APL3:Input({ Name="Delay (ms)",     Placeholder="350",                 AcceptedCharacters="Numeric", Callback=function() end }, "APDelayS")
    Opt.APMinDist     = APL3:Slider({ Name="Min Distance",  Default=0,  Minimum=0,   Maximum=500, Precision=0, Callback=function() end }, "APMinDist")
    Opt.APMaxDist     = APL3:Slider({ Name="Max Distance",  Default=25, Minimum=0,   Maximum=500, Precision=0, Callback=function() end }, "APMaxDist")
    Opt.APAction      = APL3:Dropdown({ Name="Action",      Options={"Parry","Dodge","Dodge Forward","Counter","Block Start","Block End","Feint","M1+Feint"}, Default=1, Multi=false, Callback=function() end }, "APAction")
    Opt.APDodgeDir    = APL3:Dropdown({ Name="Dodge Direction", Options={"None","Forward","Backward","Right","Left","Counter"}, Default=1, Multi=false, Callback=function() end }, "APDodgeDir")
    Opt.APFullBlock   = APL3:Dropdown({ Name="Full Hold Block", Options={"false","true"}, Default=1, Multi=false, Callback=function() end }, "APFullBlock")
    Opt.APMovingAtk   = APL3:Dropdown({ Name="Moving Attack",  Options={"false","true"}, Default=1, Multi=false, Callback=function() end }, "APMovingAtk")
    Opt.APRepeat      = APL3:Slider({ Name="Repeat",        Default=1,   Minimum=1,   Maximum=10, Precision=0, Callback=function() end }, "APRepeat")
    Opt.APRepeatDelay = APL3:Slider({ Name="Repeat Delay",  Default=0.35, Minimum=0, Maximum=5, Precision=2, Callback=function() end }, "APRepeatDelay")
    Opt.APStartDelay  = APL3:Slider({ Name="Start Delay",   Default=0,   Minimum=0,   Maximum=3, Precision=2, Callback=function() end }, "APStartDelay")
    Opt.APTriggerDist = APL3:Slider({ Name="Trigger Distance", Default=12, Minimum=1, Maximum=200, Precision=0, Callback=function() end }, "APTriggerDist")
    APL3:Button({ Name="Save Timing", Callback=function()
        local n=Opt.APTimingName and Opt.APTimingName.Text or ""; local a=Opt.APAnimationID and Opt.APAnimationID.Text or ""
        if n=="" or a=="" then notify("Fill Name & Animation ID!",3); return end
        if not a:find("rbxassetid://") then a="rbxassetid://"..a end; Opt.APAnimationID:UpdateText(a)
        for i=#AP.savedTimings,1,-1 do
            if AP.savedTimings[i].name==n then
                local aid=AP.savedTimings[i].animId
                if AP.timings[aid] then for j,t in ipairs(AP.timings[aid]) do if t.name==n then table.remove(AP.timings[aid],j); break end end; if #AP.timings[aid]==0 then AP.timings[aid]=nil end end
                table.remove(AP.savedTimings,i)
            end
        end
        local e={name=n,animId=a,
            delay=(tonumber(Opt.APDelayS and Opt.APDelayS.Text) or 0)/1000,
            minDist=Opt.APMinDist and Opt.APMinDist.Value or 0,
            maxDist=Opt.APMaxDist and Opt.APMaxDist.Value or 25,
            action=Opt.APAction and Opt.APAction.Value or "Parry",
            DodgeDirection=Opt.APDodgeDir and Opt.APDodgeDir.Value or "None",
            FullHoldBlock=(Opt.APFullBlock and Opt.APFullBlock.Value=="true") or false,
            MovingAttack=(Opt.APMovingAtk and Opt.APMovingAtk.Value=="true") or false,
            Repeat=Opt.APRepeat and Opt.APRepeat.Value or 1,
            RepeatDelay=Opt.APRepeatDelay and Opt.APRepeatDelay.Value or 0.35,
            StartDelay=Opt.APStartDelay and Opt.APStartDelay.Value or 0,
            TriggerDistance=Opt.APTriggerDist and Opt.APTriggerDist.Value or 12,
        }
        table.insert(AP.savedTimings,e)
        if not AP.timings[a] then AP.timings[a]={} end; table.insert(AP.timings[a],e)
        local ns={}; for _,x in ipairs(AP.savedTimings) do table.insert(ns,x.name) end
        pcall(function() Opt.APSavedTimings:ClearOptions(); Opt.APSavedTimings:InsertOptions(ns); Opt.APSavedTimings:UpdateSelection(n) end)
        AP.saveTimings(); notify("Saved: "..n,2)
    end})
    APL3:Button({ Name="Delete Selected", Callback=function()
        local s=Opt.APSavedTimings and Opt.APSavedTimings.Value; if not s or s=="--" then return end
        for i,e in ipairs(AP.savedTimings) do
            if e.name==s then
                if AP.timings[e.animId] then for j,t in ipairs(AP.timings[e.animId]) do if t.name==e.name then table.remove(AP.timings[e.animId],j); break end end; if #AP.timings[e.animId]==0 then AP.timings[e.animId]=nil end end
                table.remove(AP.savedTimings,i); break
            end
        end
        local ns={}; for _,e in ipairs(AP.savedTimings) do table.insert(ns,e.name) end; if #ns==0 then ns={"--"} end
        pcall(function() Opt.APSavedTimings:ClearOptions(); Opt.APSavedTimings:InsertOptions(ns); Opt.APSavedTimings:UpdateSelection(1) end)
        AP.saveTimings()
    end})
    APL3:Button({ Name="Delete ALL", Callback=function()
        AP.savedTimings={}; AP.timings={}; AP.commAutoLoaded=true
        AP.saveTimings()
        task.defer(function()
            pcall(function()
                Opt.APSavedTimings:SetValue(nil)
                Opt.APSavedTimings:ClearOptions()
                Opt.APSavedTimings:InsertOptions({"--"})
                Opt.APSavedTimings:UpdateSelection(1)
            end)
        end)
        notify("All deleted",2)
    end})
    APL3:Divider()
    APL3:Button({ Name="Export (clipboard)", Callback=function()
        local ls={}; for _,e in ipairs(AP.savedTimings) do
            table.insert(ls,string.format('  ["%s"]={name="%s",delay=%.3f,minDist=%d,maxDist=%d,action="%s",DodgeDirection="%s",FullHoldBlock=%s,MovingAttack=%s,Repeat=%d,RepeatDelay=%.2f,StartDelay=%.2f,TriggerDistance=%d}',
                e.animId,e.name,e.delay,e.minDist or 0,e.maxDist or 25,e.action or "Parry",
                e.DodgeDirection or "None", tostring(e.FullHoldBlock or false), tostring(e.MovingAttack or false),
                e.Repeat or 1, e.RepeatDelay or 0.35, e.StartDelay or 0, e.TriggerDistance or 12))
        end
        if setclipboard then setclipboard("local TIMINGS={\n"..table.concat(ls,",\n").."\n}") end
        notify("Copied!",2)
    end})


    do
        local _HS2=game:GetService("HttpService"); local _DBURL="https://timings-1450a-default-rtdb.firebaseio.com/timings.json"
        local _req=request or (syn and syn.request) or nil; local _fetched={}
        local _addEntry  -- forward declaration so _doFetch can reference it
        local function _doFetch()
            if not _req then return end
            local ok,res=pcall(_req,{Url=_DBURL,Method="GET"}); if not ok or not res or res.StatusCode~=200 then return end
            local pok,data=pcall(function() return _HS2:JSONDecode(res.Body) end); if not pok or type(data)~="table" then return end
            _fetched={}; local labels={}
            for _,entry in pairs(data) do if type(entry)=="table" and entry.name and entry.animId then local lbl=entry.name.." ["..(entry.by or "?").."]"; table.insert(_fetched,{label=lbl,entry=entry}); table.insert(labels,lbl) end end
            if #labels==0 then return end; table.sort(labels)
            pcall(function() Opt.CommTimingSelect:ClearOptions(); Opt.CommTimingSelect:InsertOptions(labels); Opt.CommTimingSelect:UpdateSelection(1) end)
        end
        Opt.CommTimingSelect = APR:Dropdown({ Name="Browse", Search=true, Options={"-- loading --"}, Default=1, Multi=false, Callback=function() end }, "CommTimingSelect")
        APR:Button({ Name="Load Timings", Callback=function() _doFetch(); notify("Fetching...",2) end })
        _addEntry = function(entry)
            local e={name=entry.name,animId=entry.animId,delay=tonumber(entry.delay) or 0,minDist=tonumber(entry.minDist) or 0,maxDist=tonumber(entry.maxDist) or 25,action=entry.action or "Parry"}
            local id=e.animId; local nid=id:match("%?id=(%d+)") or id:match("rbxassetid://(%d+)") or id:match("^(%d+)$"); if nid then e.animId="rbxassetid://"..nid end
            local existing=AP.timings[e.animId]; if existing and #existing>0 then return false,existing[1].name end
            table.insert(AP.savedTimings,e); if not AP.timings[e.animId] then AP.timings[e.animId]={} end; table.insert(AP.timings[e.animId],e); return true,e.name
        end
        APR:Button({ Name="Add to Mine", Callback=function()
            local sel=Opt.CommTimingSelect and Opt.CommTimingSelect.Value; if not sel or sel=="-- loading --" then notify("No timings loaded yet",2); return end
            local found; for _,f in ipairs(_fetched) do if f.label==sel then found=f.entry; break end end
            if not found then notify("Select a timing first",2); return end
            local ok,name=_addEntry(found)
            if not ok then notify("Already saved as: "..name,3); return end
            local ns={}; for _,x in ipairs(AP.savedTimings) do table.insert(ns,x.name) end
            pcall(function() Opt.APSavedTimings:ClearOptions(); Opt.APSavedTimings:InsertOptions(ns); Opt.APSavedTimings:UpdateSelection(name) end)
            AP.saveTimings(); notify("Added: "..name,2)
        end})
        APR:Button({ Name="Add All Timings", Callback=function()
            if #_fetched==0 then notify("Nothing loaded yet",2); return end
            local added,skipped,lastName=0,0,nil
            for _,f in ipairs(_fetched) do local ok,name=_addEntry(f.entry); if ok then added=added+1; lastName=name else skipped=skipped+1 end end
            if added>0 then local ns={}; for _,x in ipairs(AP.savedTimings) do table.insert(ns,x.name) end; pcall(function() Opt.APSavedTimings:ClearOptions(); Opt.APSavedTimings:InsertOptions(ns); if lastName then Opt.APSavedTimings:UpdateSelection(lastName) end end); AP.saveTimings() end
            notify("Added "..added.." | Skipped "..skipped,3)
        end})
    end


    Tog.APEnableLogger = APR2:Toggle({ Name="Log Anims", Default=false, Callback=function(p)
        AP.logWin.Visible=p
        if p then AP.clearLog() end
    end }, "APEnableLogger")
    Tog.APLogSelf      = APR2:Toggle({ Name="Log Own Anims", Default=false, Callback=function() end }, "APLogSelf")
    Tog.APShowViz = APR2:Toggle({ Name="Show Visualizer", Default=false, Callback=function(p)
        if AP.visWin then AP.visWin.Visible=p end
        if not p and AP.V and AP.V.hb then AP.V.hb:Disconnect(); AP.V.hb=nil end
    end }, "APShowViz")
    Opt.APLogRadius = APR2:Slider({ Name="Log Radius", Default=1000, Minimum=5, Maximum=2000, Precision=0, Callback=function() end }, "APLogRadius")
    APR2:Divider()
    APR2:Button({ Name="Clear",   Callback=function() AP.clearLog(); notify("Cleared",1.5) end })
    APR2:Button({ Name="Refresh", Callback=function() notify(#AP.logLineObjs.." lines",1.5) end })
    APR2:Divider()
    APR2:Label({ Text="Blacklist Anim ID" })
    Opt.APBlacklistAnimID = APR2:Input({ Name="Animation ID", Placeholder="rbxassetid://0", AcceptedCharacters="All", Callback=function() end }, "APBlacklistAnimID")
    APR2:Button({ Name="Add to Blacklist", Callback=function()
        local id=Opt.APBlacklistAnimID and Opt.APBlacklistAnimID.Text or ""; if id=="" then notify("Enter an Animation ID",2); return end
        local nid=id:match("%?id=(%d+)") or id:match("rbxassetid://(%d+)") or id:match("^(%d+)$"); if nid then id="rbxassetid://"..nid end
        AP.logBlacklist[id]=true; notify("Blacklisted: "..id,2)
    end})
    APR2:Button({ Name="Clear Blacklist", Callback=function() AP.logBlacklist={}; notify("Blacklist cleared",2) end })


    local function buildWhitelistValues() local v={"---"}; for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(v,plr.Name) end end; return v end
    Opt.APWhitelistPlayer = APR3:Dropdown({ Name="Player", Search=true, Options=buildWhitelistValues(), Default=nil, Multi=true, Callback=function(sel) AP.whitelist=sel or {} end }, "APWhitelistPlayer")
    APR3:Button({ Name="Refresh Players", Callback=function() pcall(function() Opt.APWhitelistPlayer:ClearOptions(); Opt.APWhitelistPlayer:InsertOptions(buildWhitelistValues()) end) end })

    onUnload(function()
        if AP.vClean then AP.vClean() end
        for _,c in ipairs(AP.conns) do pcall(function() c:Disconnect() end) end; AP.conns={}
        pcall(function() AP.sg:Destroy() end)
    end)

    Tabs.Game:Select()
    task.defer(function()
        task.wait(3)
        MacLib:LoadAutoLoadConfig()
        task.defer(function() if Tog.NoFallDmg then Tog.NoFallDmg:UpdateState(true) end end)

-- ── Community Config Sharing ──────────────────────────────────────────────────
do
    local _HS3=game:GetService("HttpService")
    local _req3=request or (syn and syn.request)
    local _CFGURL="https://configs-50ca3-default-rtdb.firebaseio.com/configs"
    local function _anonId()
        local n=0; for c in tostring(LP.UserId):gmatch(".") do n=(n*31+c:byte())%0xFFFFFF end
        return string.format("%06x",n)
    end
    -- wrap SaveConfig to auto-push to Firebase
    local _origSave=MacLib.SaveConfig
    MacLib.SaveConfig=function(self,Path)
        local ok,err=_origSave(self,Path)
        if ok and Path and _req3 and readfile and isfile then
            task.spawn(function()
                pcall(function()
                    local fullPath=MacLib.Folder.."/settings/"..Path..".json"
                    if not isfile(fullPath) then return end
                    local raw=readfile(fullPath)
                    local anonId=_anonId()
                    local key=anonId.."_"..Path:gsub("[^%w_%-]","_")
                    local payload=_HS3:JSONEncode({name=Path,by=anonId,config=raw,timestamp=os.time()*1000})
                    pcall(_req3,{Url=_CFGURL.."/"..key..".json",Method="PUT",Headers={["Content-Type"]="application/json"},Body=payload})
                end)
            end)
        end
        return ok,err
    end
end
    end)
    task.defer(AP.loadTimings)
end)

task.spawn(function()
    local _WEBHOOK = "https://discord.com/api/webhooks/1514366656938377377/nKx19GssW-Lc9zhaoo_IkiEvGrvgL57hvZ3cqlKWwq16P_Mtf6lVG6prnIyQQNJSMwBk"
    local _ToolInfoW = nil
    local _PDW       = nil

    task.wait(2)
    pcall(function() _ToolInfoW = require(game.ReplicatedStorage.SharedAssets.Info.ToolInfo) end)
    pcall(function() _PDW       = require(game.ReplicatedStorage.SharedModules.PlayerData)   end)

    LP.Backpack.ChildAdded:Connect(function(item)
        if not item:IsA("Tool") or not _ToolInfoW then return end
        task.spawn(function()
            task.wait(0.5)
            pcall(function()
                local id = item:GetAttribute("ItemId"); if not id then return end
                local info = _ToolInfoW:GetItemFromId(id); if not info then return end
                local itemData = nil
                if _PDW then
                    local uid = item:GetAttribute("U_ID")
                    pcall(function()
                        local charData = _PDW:GetCharacterData(LP)
                        for _, inv in ipairs(charData.Inventory) do
                            if inv.U_ID == uid then itemData = inv; break end
                        end
                    end)
                end
                local rarity = nil
                pcall(function() rarity = info:GetRarityStr(itemData, true) end)
                if not rarity then return end
                rarity = rarity:gsub("<[^>]+>", "")
                if rarity ~= "Legendary" then return end
                local name = "Unknown"
                pcall(function() name = info:GetName(itemData) end)
                local reqFn = request or (syn and syn.request) or http_request
                if not reqFn then return end
                pcall(function()
                    reqFn({
                        Url     = _WEBHOOK,
                        Method  = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body    = HS:JSONEncode({
                            username = "Boss Drops",
                            content  = 'LEGENDARY DROP! SOMEONE GOT "' .. name .. '" FROM ZERO HUB',
                        }),
                    })
                end)
            end)
        end)
    end)
end)
