--[[
    Mashle Academy | Xes Hub
    discord.gg/vanthub
]]

-- ── Auto spawn ────────────────────────────────────────────────────────────────
task.spawn(function()
    local LP = game:GetService("Players").LocalPlayer
    while not LP.Character do
        pcall(function() game:GetService("ReplicatedStorage").requests.character.spawn:FireServer() end)
        task.wait(0.2)
    end
end)

-- ── Auto delete loading GUIs ──────────────────────────────────────────────────
task.spawn(function()
    local LP   = game:GetService("Players").LocalPlayer
    local PGui = LP:WaitForChild("PlayerGui")
    local toKill = {"Main Menu","BlackScreenGui","Logo_Loader"}
    while true do
        task.wait(0.5)
        for _, n in ipairs(toKill) do
            local g = PGui:FindFirstChild(n)
            if g then pcall(function() g:Destroy() end) end
        end
    end
end)

-- ── Services ──────────────────────────────────────────────────────────────────
local cloneref = cloneref or function(x) return x end
local RS  = cloneref(game:GetService("RunService"))
local PS  = cloneref(game:GetService("Players"))
local UIS = cloneref(game:GetService("UserInputService"))
local VIM = cloneref(game:GetService("VirtualInputManager"))
local LT  = cloneref(game:GetService("Lighting"))
local HS  = cloneref(game:GetService("HttpService"))
local TP  = cloneref(game:GetService("TeleportService"))
local Cam = cloneref(workspace.CurrentCamera)

local LP = PS.LocalPlayer
LP = cloneref(LP)
if not LP.Character then LP.CharacterAdded:Wait() end

-- ── Linoria ───────────────────────────────────────────────────────────────────
local repo         = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"
local Library      = loadstring(game:HttpGet(repo.."Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))()

Library.ShowCustomCursor       = false
Library.ShowToggleFrameInKeybinds = true
Library.NotifySide             = "Left"

local Window = Library:CreateWindow({
    Title            = "Mashle Academy | Xes Hub",
    Center           = true, AutoShow = true,
    Size             = UDim2.fromOffset(660, 700),
    ShowCustomCursor = false,
    UnlockMouseWhileOpen = true,
    MenuFadeTime     = 0.2,
})

local Opt = Library.Options
local Tog = Library.Toggles
local function notify(msg, dur) Library:Notify(msg, dur or 3) end

-- ── Tabs ──────────────────────────────────────────────────────────────────────
local Tabs = {
    VV      = Window:AddTab("Mashle Academy"),
    Parry   = Window:AddTab("Auto Parry"),
    Player  = Window:AddTab("Player"),
    Visuals = Window:AddTab("Visuals"),
    Misc    = Window:AddTab("Misc"),
    UI      = Window:AddTab("Settings"),
}

local GB = {
    PlayerL  = Tabs.Player:AddLeftGroupbox("Movement"),
    PlayerR  = Tabs.Player:AddRightGroupbox("Character"),
    AimL     = Tabs.Player:AddLeftGroupbox("Aimbot"),
    AimR     = Tabs.Player:AddRightGroupbox("Aimbot Settings"),
    VisL     = Tabs.Visuals:AddLeftGroupbox("Camera"),
    VisR     = Tabs.Visuals:AddRightGroupbox("Rendering"),
    MobESP   = Tabs.Visuals:AddLeftGroupbox("Mob ESP"),
    ESPSet   = Tabs.Visuals:AddLeftGroupbox("ESP Settings"),
    PlrESP   = Tabs.Visuals:AddRightGroupbox("Player ESP"),
    MiscL    = Tabs.Misc:AddLeftGroupbox("Server"),
    MiscR    = Tabs.Misc:AddRightGroupbox("Utility"),
    MiscCom  = Tabs.Misc:AddLeftGroupbox("Combat"),
    VVFarm   = Tabs.VV:AddLeftGroupbox("Farming"),
    VVExpl   = Tabs.VV:AddLeftGroupbox("Exploits"),
    VVTP     = Tabs.VV:AddLeftGroupbox("Teleport"),
    VVCom    = Tabs.VV:AddRightGroupbox("Combat"),
}

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function getChar()  return LP.Character end
local function getHRP()   local c=getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()   local c=getChar() return c and c:FindFirstChildOfClass("Humanoid") end

-- ══════════════════════════════════════════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════════════════════════════════════════
local S = {
    speed=100, infJumpH=50, flySpeed=100,
    noclipConn=nil,
    aimbotMode="Toggle", aimbotMethod="Camera",
    aimbotFOV=45, aimbotSens=1, aimbotX=0, aimbotY=0,
    aimbotActive=false, aimbotEnabled=false,
    teamCheck=false, visibleOnly=false, targetPlayers=true,
    freecamSens=5, freecamSpeed=1, camFOV=70,
    brightness=2,
    nearbyTable={},
    autoChatMsg="gg", autoChatDelay=30,
    hitboxSize=5, hitboxTrans=0.9,
    autoRejoin=false,
}

-- ── Always keep GameplayPaused off ───────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(0.1)
        pcall(function() LP.GameplayPaused = false end)
    end
end)

-- ── Tween TP ─────────────────────────────────────────────────────────────────
local function tweenTo(cf)
    local hrp = getHRP() if not hrp then return end
    hrp.Velocity = Vector3.zero; hrp.AssemblyLinearVelocity = Vector3.zero
    local dist = (hrp.Position - cf.Position).Magnitude
    if dist <= 10 then hrp.CFrame = cf return end
    local start = hrp.Position
    local dur   = dist / math.max(Opt.TweenSpeed and Opt.TweenSpeed.Value or 100, 1)
    local t0    = tick()
    while tick()-t0 < dur do
        hrp.CFrame = CFrame.new(start:Lerp(cf.Position, (tick()-t0)/dur))
        hrp.Velocity = Vector3.zero; task.wait()
    end
    hrp.CFrame = cf
end

-- ── Server hop ────────────────────────────────────────────────────────────────
local function serverHop(minP)
    minP = tonumber(minP) or 0
    local url = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
    local cursor, found = nil, nil
    repeat
        local ok, res = pcall(function() return HS:JSONDecode(game:HttpGet(url..(cursor and "&cursor="..cursor or ""))) end)
        if not ok or not res then break end
        for _, s in ipairs(res.data or {}) do
            if s.playing >= minP and s.playing < s.maxPlayers and s.id ~= game.JobId then
                found = s; break
            end
        end
        cursor = res.nextPageCursor
    until found or not cursor
    if found then TP:TeleportToPlaceInstance(game.PlaceId, found.id, LP)
    else notify("No server found", 4) end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- PLAYER TAB
-- ══════════════════════════════════════════════════════════════════════════════

GB.PlayerL:AddLabel("── Teleport ──")
GB.PlayerL:AddInput("Coordinates", { Default="", Numeric=false, Finished=false, Text="Coordinates", Placeholder="X, Y, Z" })
GB.PlayerL:AddButton({ Text="Tween To", Func=function()
    local s = Opt.Coordinates.Value
    local x,y,z = s:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
    if x then tweenTo(CFrame.new(tonumber(x),tonumber(y),tonumber(z))) else notify("Use format: X, Y, Z") end
end})
GB.PlayerL:AddButton({ Text="Copy Position", Func=function()
    local hrp = getHRP() if hrp then setclipboard(tostring(hrp.Position)); notify("Copied!") end
end})

GB.PlayerL:AddLabel("── Movement ──")

-- Speed
GB.PlayerL:AddToggle("Speedhack", { Text="Speed", Default=false,
    Callback=function(p)
        if p then
            RS:BindToRenderStep("Speedhack", Enum.RenderPriority.Input.Value, function(dt)
                local hrp=getHRP(); local hum=getHum()
                if hrp and hum and hum.Health>0 and hum.MoveDirection.Magnitude>0 then
                    hrp.CFrame = hrp.CFrame + hum.MoveDirection * S.speed * dt
                end
            end)
        else RS:UnbindFromRenderStep("Speedhack") end
    end,
}):AddKeyPicker("SpeedhackKeybind", { Default="N", SyncToggleState=true, Mode="Toggle", Text="Speed Keybind" })
GB.PlayerL:AddSlider("SpeedhackSpeed", { Text="Speed", Default=100, Min=0, Max=5000, Rounding=0, Compact=true, Callback=function(p) S.speed=p end })

-- Inf Jump
local ijConn = nil
GB.PlayerL:AddToggle("InfiniteJump", { Text="Inf Jump", Default=false,
    Callback=function(p)
        if ijConn then ijConn:Disconnect(); ijConn=nil end
        if p then
            ijConn = UIS.JumpRequest:Connect(function()
                local hrp=getHRP() if hrp then hrp.Velocity=Vector3.new(hrp.Velocity.X,S.infJumpH,hrp.Velocity.Z) end
            end)
        end
    end,
}):AddKeyPicker("InfiniteJumpKeybind", { Default="H", SyncToggleState=true, Mode="Toggle", Text="Inf Jump Keybind" })
GB.PlayerL:AddSlider("InfiniteJumpHeight", { Text="Jump Height", Default=50, Min=0, Max=1000, Rounding=0, Compact=true, Callback=function(p) S.infJumpH=p end })

-- Noclip
GB.PlayerL:AddToggle("Noclip", { Text="Noclip", Default=false,
    Callback=function(p)
        if S.noclipConn then S.noclipConn:Disconnect(); S.noclipConn=nil end
        if p then
            S.noclipConn = RS.RenderStepped:Connect(function()
                local c=getChar() if not c then return end
                for _, part in ipairs(c:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide=false end
                end
            end)
        end
    end,
}):AddKeyPicker("NoclipKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="Noclip Keybind" })

-- Fly
local flyFrame = nil
local function flyTick(dt)
    local c=getChar() if not c then return end
    local hrp=c:FindFirstChild("HumanoidRootPart") if not hrp then return end
    if not flyFrame then flyFrame=hrp.CFrame end
    local cf=Cam.CFrame; local move=Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W)           then move+=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit end
    if UIS:IsKeyDown(Enum.KeyCode.S)           then move-=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit end
    if UIS:IsKeyDown(Enum.KeyCode.A)           then move-=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit end
    if UIS:IsKeyDown(Enum.KeyCode.D)           then move+=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit end
    if UIS:IsKeyDown(Enum.KeyCode.Space)       then move+=Vector3.new(0,1,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move-=Vector3.new(0,1,0) end
    if move.Magnitude>0 then flyFrame=flyFrame+move.Unit*S.flySpeed*dt end
    local fwd=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
    if fwd.Magnitude>0 then flyFrame=CFrame.new(flyFrame.Position,flyFrame.Position+fwd.Unit) end
    hrp.AssemblyLinearVelocity=Vector3.zero; hrp.CFrame=flyFrame
end
GB.PlayerL:AddToggle("Fly", { Text="Fly", Default=false,
    Callback=function(p)
        if p then flyFrame=nil; RS:BindToRenderStep("Fly",Enum.RenderPriority.Input.Value,flyTick)
        else RS:UnbindFromRenderStep("Fly"); flyFrame=nil end
    end,
}):AddKeyPicker("FlyKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="Fly Keybind" })
GB.PlayerL:AddSlider("FlySpeed", { Text="Fly Speed", Default=100, Min=1, Max=2000, Rounding=0, Compact=true, Callback=function(p) S.flySpeed=p end })

-- Character
GB.PlayerR:AddLabel("── Actions ──")
GB.PlayerR:AddButton({ Text="Kill Yourself", Func=function() local hum=getHum() if hum then hum.Health=0 end end })

GB.PlayerR:AddLabel("── Modifiers ──")
local noAnimsThread=nil
GB.PlayerR:AddToggle("NoAnims", { Text="No Anims", Default=false,
    Callback=function(p)
        if noAnimsThread then task.cancel(noAnimsThread); noAnimsThread=nil end
        if not p then return end
        local c=getChar() if not c then return end
        local hum=c:FindFirstChildOfClass("Humanoid"); local anim=hum and hum:FindFirstChildOfClass("Animator")
        if not anim then return end
        local blank=Instance.new("Animation"); blank.AnimationId="rbxassetid://10921272275"
        noAnimsThread=task.spawn(function()
            while p and anim and anim.Parent do
                for _,t in pairs(anim:GetPlayingAnimationTracks()) do
                    if t.Animation.AnimationId~=blank.AnimationId then pcall(function() t:Stop();t:Destroy() end) end
                end
                if #anim:GetPlayingAnimationTracks()==0 then
                    pcall(function() local t=anim:LoadAnimation(blank);t.Priority=Enum.AnimationPriority.Core;t:AdjustSpeed(0);t:Play() end)
                end
                task.wait(0.1)
            end
        end)
    end,
}):AddKeyPicker("NoAnimsKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="No Anims Keybind" })

GB.PlayerR:AddLabel("── Settings ──")
GB.PlayerR:AddToggle("AntiAFK", { Text="Anti AFK", Default=false,
    Callback=function(p)
        if p then LP.Idled:Connect(function()
            VIM:SendMouseButtonEvent(0,0,0,true,game,0); task.wait()
            VIM:SendMouseButtonEvent(0,0,0,false,game,0)
        end) end
    end,
})

-- ══════════════════════════════════════════════════════════════════════════════
-- AIMBOT
-- ══════════════════════════════════════════════════════════════════════════════
local function getAimbotTargets()
    local r={}
    for _,plr in ipairs(PS:GetPlayers()) do
        if plr~=LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and S.targetPlayers then
            if S.teamCheck and LP.Team and plr.Team==LP.Team then continue end
            table.insert(r, plr.Character)
        end
    end
    return r
end
local function getAimPart(char)
    local v=Opt.AimPart and Opt.AimPart.Value or "Head"
    if v=="Head"  then return char:FindFirstChild("Head") end
    if v=="Torso" then return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") end
    local parts={} for _,n in ipairs({"Head","HumanoidRootPart"}) do local p=char:FindFirstChild(n) if p then table.insert(parts,p) end end
    return parts[math.random(1,#parts)]
end
local function isVisible(part)
    if not (part and part.Parent) then return false end
    local c=getChar() if not c then return false end
    local ray=Ray.new(Cam.CFrame.Position,(part.Position-Cam.CFrame.Position).Unit*1000)
    local hit=workspace:FindPartOnRayWithIgnoreList(ray,{c,Cam})
    return hit and hit:IsDescendantOf(part.Parent)
end
local function getBestTarget()
    local mouse=UIS:GetMouseLocation(); local best,bestDist=nil,math.huge
    for _,char in ipairs(getAimbotTargets()) do
        local part=getAimPart(char) if not (part and part:IsA("BasePart")) then continue end
        local sp,onScreen=Cam:WorldToViewportPoint(part.Position) if not onScreen then continue end
        local angle=math.deg(math.acos(math.clamp(Cam.CFrame.LookVector:Dot((part.Position-Cam.CFrame.Position).Unit),-1,1)))
        if angle>S.aimbotFOV/2 then continue end
        if S.visibleOnly and not isVisible(part) then continue end
        local d=(mouse-Vector2.new(sp.X,sp.Y)).Magnitude if d<bestDist then bestDist=d;best=part end
    end
    return best
end

GB.AimL:AddLabel("── Configuration ──")
GB.AimL:AddDropdown("AimbotMode", { Text="Mode", Default="Toggle", Values={"Toggle","Hold","Always"}, Callback=function(p) S.aimbotMode=p; if p=="Always" then S.aimbotActive=true end end })
GB.AimL:AddDropdown("AimbotMethod", { Text="Method", Default="Camera", Values={"Camera","mousemoverel"}, Callback=function(p) S.aimbotMethod=p end })
GB.AimL:AddDropdown("AimPart", { Text="Aim Part", Default="Head", Values={"Head","Torso","Random"} })

local aimbotKeybind=GB.AimL:AddLabel("Aimbot Keybind"):AddKeyPicker("AimbotKeybind", {
    Default="MB2", SyncToggleState=false, Mode="Toggle", Text="Aimbot Keybind", NoUI=true,
    Callback=function() if S.aimbotMode=="Toggle" then S.aimbotActive=not S.aimbotActive end end,
})

local aimbotConn=nil; local aimbotAccum=Vector2.zero; local aimbotHoldConns={}
GB.AimL:AddToggle("Aimbot", { Text="Aimbot", Default=false,
    Callback=function(p)
        S.aimbotEnabled=p; if not p then S.aimbotActive=false end
        if p and S.aimbotMode=="Always" then S.aimbotActive=true end
        for _,c in pairs(aimbotHoldConns) do c:Disconnect() end; aimbotHoldConns={}
        if p then
            local function checkKey(inp,down)
                local kt=aimbotKeybind and aimbotKeybind.Value
                if kt=="MB1" and inp.UserInputType==Enum.UserInputType.MouseButton1 then S.aimbotActive=down
                elseif kt=="MB2" and inp.UserInputType==Enum.UserInputType.MouseButton2 then S.aimbotActive=down end
            end
            table.insert(aimbotHoldConns, UIS.InputBegan:Connect(function(inp,gpe) if not gpe and S.aimbotMode=="Hold" then checkKey(inp,true) end end))
            table.insert(aimbotHoldConns, UIS.InputEnded:Connect(function(inp) if S.aimbotMode=="Hold" then checkKey(inp,false) end end))
        end
        if aimbotConn then aimbotConn:Disconnect(); aimbotConn=nil end
        if p then
            aimbotAccum=Vector2.zero
            aimbotConn=RS.RenderStepped:Connect(function()
                if not S.aimbotActive then return end
                local target=getBestTarget() if not target then return end
                local pos=target.Position+Vector3.new(S.aimbotX,S.aimbotY,0)
                if S.aimbotMethod=="Camera" then
                    local lv=Cam.CFrame.LookVector:Lerp((pos-Cam.CFrame.Position).Unit,math.clamp(S.aimbotSens*0.1,0.01,1))
                    Cam.CFrame=CFrame.new(Cam.CFrame.Position,Cam.CFrame.Position+lv)
                else
                    local sp=Cam:WorldToViewportPoint(pos); local mouse=UIS:GetMouseLocation()
                    aimbotAccum+=(Vector2.new(sp.X,sp.Y)-mouse)*S.aimbotSens
                    local clamped=Vector2.new(math.clamp(aimbotAccum.X,-10,10),math.clamp(aimbotAccum.Y,-10,10))
                    mousemoverel(clamped.X,clamped.Y); aimbotAccum-=clamped
                end
            end)
        end
    end,
})

GB.AimR:AddLabel("── Targeting ──")
GB.AimR:AddToggle("TargetPlayers", { Text="Target Players", Callback=function(p) S.targetPlayers=p end })
GB.AimR:AddToggle("VisibleOnly",   { Text="Visible Only",   Callback=function(p) S.visibleOnly=p   end })
GB.AimR:AddToggle("TeamCheck",     { Text="Team Check",     Callback=function(p) S.teamCheck=p     end })
GB.AimR:AddSlider("AimbotSens",    { Text="Sensitivity", Default=1, Min=0.1, Max=5, Rounding=2, Compact=true, Callback=function(p) S.aimbotSens=p end })
GB.AimR:AddSlider("AimbotXOffset", { Text="X Offset", Default=0, Min=-300, Max=300, Rounding=0, Compact=true, Callback=function(p) S.aimbotX=p end })
GB.AimR:AddSlider("AimbotYOffset", { Text="Y Offset", Default=0, Min=-300, Max=300, Rounding=0, Compact=true, Callback=function(p) S.aimbotY=p end })

local fovCircle=nil
local function getFOVScale() return math.tan(math.rad(1))*(Cam.ViewportSize.Y/2) end
local function updateFOVCircle() if fovCircle then fovCircle.Position=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2);fovCircle.Radius=S.aimbotFOV*getFOVScale() end end
Cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateFOVCircle)
Cam:GetPropertyChangedSignal("FieldOfView"):Connect(updateFOVCircle)

GB.AimR:AddLabel("── FOV Circle ──")
GB.AimR:AddToggle("ShowFOV", { Text="Show FOV",
    Callback=function(p)
        if p then
            if not fovCircle then fovCircle=Drawing.new("Circle");fovCircle.Thickness=1;fovCircle.NumSides=100;fovCircle.Filled=false;fovCircle.Color=Color3.fromRGB(255,255,255) end
            fovCircle.Radius=S.aimbotFOV*getFOVScale();fovCircle.Position=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2);fovCircle.Visible=true
        elseif fovCircle then fovCircle.Visible=false end
    end,
})
GB.AimR:AddSlider("AimbotFOV", { Text="Aimbot FOV", Default=45, Min=1, Max=120, Rounding=0, Compact=true,
    Callback=function(p) S.aimbotFOV=p; if fovCircle then fovCircle.Radius=p*getFOVScale() end end })

-- ══════════════════════════════════════════════════════════════════════════════
-- VISUALS TAB
-- ══════════════════════════════════════════════════════════════════════════════

-- Click TP
local clickTPConn=nil
GB.VisL:AddLabel("── Teleport ──")
GB.VisL:AddToggle("ClickTP", { Text="Click TP",
    Callback=function(p)
        if clickTPConn then clickTPConn:Disconnect(); clickTPConn=nil end
        if p then
            clickTPConn=UIS.InputBegan:Connect(function(inp,gpe)
                if gpe or inp.UserInputType~=Enum.UserInputType.MouseButton2 then return end
                local ray=Cam:ScreenPointToRay(inp.Position.X,inp.Position.Y)
                local res=workspace:Raycast(ray.Origin,ray.Direction*2000)
                if res then local hrp=getHRP() if hrp then hrp.CFrame=CFrame.new(res.Position+Vector3.new(0,3,0)) end end
            end)
        end
    end,
}):AddKeyPicker("ClickTPKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="Click TP Keybind" })

-- Spectate
local specState={active=false,target=nil,conns={}}
local function stopSpectate()
    specState.active=false
    for _,c in ipairs(specState.conns) do pcall(function() c:Disconnect() end) end
    specState.conns={}
    local c=getChar() if c then Cam.CameraSubject=c:FindFirstChildOfClass("Humanoid") or c; Cam.CameraType=Enum.CameraType.Custom end
end
GB.VisL:AddLabel("── Spectate ──")
GB.VisL:AddDropdown("SpectateDropdown", { SpecialType="Player", Text="Spectate Player", Callback=function(p) specState.target=p end })
GB.VisL:AddButton({ Text="Spectate / Stop", Func=function()
    if specState.active then stopSpectate(); notify("Stopped spectating"); return end
    local t=specState.target if not t then notify("Select a player first"); return end
    local char=t.Character or t.CharacterAdded:Wait() if not char then notify("No character"); return end
    specState.active=true; Cam.CameraType=Enum.CameraType.Custom
    Cam.CameraSubject=char:FindFirstChildOfClass("Humanoid") or char; notify("Spectating "..t.Name)
    table.insert(specState.conns, t.CharacterAdded:Connect(function(c)
        if not specState.active then return end; task.wait(0.5)
        Cam.CameraSubject=c:FindFirstChildOfClass("Humanoid") or c
    end))
end})

-- Freecam
local freecamConns={}
GB.VisL:AddLabel("── Camera ──")
GB.VisL:AddToggle("Freecam", { Text="Freecam",
    Callback=function(p)
        for _,c in pairs(freecamConns) do c:Disconnect() end; freecamConns={}
        if p then
            Cam.CameraType=Enum.CameraType.Scriptable
            local keys,rmb={},false
            freecamConns[1]=UIS.InputBegan:Connect(function(inp,gpe) if gpe then return end; keys[inp.KeyCode]=true; if inp.UserInputType==Enum.UserInputType.MouseButton2 then rmb=true end end)
            freecamConns[2]=UIS.InputEnded:Connect(function(inp) keys[inp.KeyCode]=false; if inp.UserInputType==Enum.UserInputType.MouseButton2 then rmb=false end end)
            freecamConns[3]=RS.RenderStepped:Connect(function(dt)
                if rmb then
                    local delta=UIS:GetMouseDelta(); local cf=Cam.CFrame
                    local pitch=cf:ToEulerAngles(Enum.RotationOrder.YZX)
                    local newP=math.clamp(math.deg(pitch)-delta.Y*S.freecamSens*0.1,-85,85)
                    Cam.CFrame=CFrame.new(cf.Position)*CFrame.Angles(0,-delta.X*S.freecamSens*0.01*math.pi/18,0)*CFrame.Angles(math.rad(newP)-pitch,0,0)*(cf-cf.Position)
                    UIS.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition
                else UIS.MouseBehavior=Enum.MouseBehavior.Default end
                local spd=S.freecamSpeed*dt*60
                if keys[Enum.KeyCode.W] then Cam.CFrame=Cam.CFrame*CFrame.new(0,0,-spd) end
                if keys[Enum.KeyCode.S] then Cam.CFrame=Cam.CFrame*CFrame.new(0,0,spd)  end
                if keys[Enum.KeyCode.A] then Cam.CFrame=Cam.CFrame*CFrame.new(-spd,0,0) end
                if keys[Enum.KeyCode.D] then Cam.CFrame=Cam.CFrame*CFrame.new(spd,0,0)  end
                if keys[Enum.KeyCode.E] or keys[Enum.KeyCode.Space]       then Cam.CFrame=Cam.CFrame*CFrame.new(0,spd,0)  end
                if keys[Enum.KeyCode.Q] or keys[Enum.KeyCode.LeftControl] then Cam.CFrame=Cam.CFrame*CFrame.new(0,-spd,0) end
            end)
        else Cam.CameraType=Enum.CameraType.Custom; UIS.MouseBehavior=Enum.MouseBehavior.Default end
    end,
}):AddKeyPicker("FreecamKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="Freecam Keybind" })
GB.VisL:AddSlider("FreecamSens",  { Text="Sensitivity", Default=5,   Min=1,   Max=20,   Rounding=1, Compact=true, Callback=function(p) S.freecamSens=p  end })
GB.VisL:AddSlider("FreecamSpeed", { Text="Speed",       Default=1,   Min=0.1, Max=20,   Rounding=1, Compact=true, Callback=function(p) S.freecamSpeed=p end })
GB.VisL:AddToggle("FOVChanger", { Text="FOV", Callback=function(p) Cam.FieldOfView=p and S.camFOV or 70 end })
GB.VisL:AddSlider("CameraFOV", { Text="Camera FOV", Default=70, Min=1, Max=120, Rounding=0, Compact=true,
    Callback=function(p) S.camFOV=p; if Tog.FOVChanger and Tog.FOVChanger.Value then Cam.FieldOfView=p end end })

-- Rendering
local noFogLoop=nil
GB.VisR:AddLabel("── Environment ──")
GB.VisR:AddToggle("NoFog", { Text="No Fog",
    Callback=function(p)
        if noFogLoop then noFogLoop:Disconnect(); noFogLoop=nil end
        if p then
            noFogLoop=RS.Heartbeat:Connect(function()
                LT.FogEnd=100000; LT.FogStart=0
                for _,v in ipairs(LT:GetChildren()) do if v:IsA("Atmosphere") then v:Destroy() end end
            end)
        else LT.FogEnd=100000 end
    end,
}):AddKeyPicker("NoFogKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="No Fog Keybind" })
GB.VisR:AddToggle("NoShadows", { Text="No Shadows", Callback=function(p) LT.GlobalShadows=not p end })

local fbLoop=nil
GB.VisR:AddLabel("── Lighting ──")
GB.VisR:AddToggle("FullBright", { Text="Fullbright",
    Callback=function(p)
        if fbLoop then fbLoop:Disconnect(); fbLoop=nil end
        if p then
            fbLoop=RS.Heartbeat:Connect(function()
                LT.Brightness=S.brightness; LT.ClockTime=14; LT.FogEnd=100000
                LT.GlobalShadows=false; LT.OutdoorAmbient=Color3.fromRGB(128,128,128)
            end)
        else LT.Brightness=1; LT.ClockTime=14; LT.GlobalShadows=true end
    end,
}):AddKeyPicker("FullBrightKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="FullBright Keybind" })
GB.VisR:AddSlider("Brightness", { Text="Brightness", Default=2, Min=0, Max=10, Rounding=1, Compact=true, Callback=function(p) S.brightness=p end })

local xrayLoop=nil
GB.VisR:AddToggle("XRay", { Text="Xray",
    Callback=function(p)
        if xrayLoop then xrayLoop:Disconnect(); xrayLoop=nil end
        if p then
            xrayLoop=RS.Heartbeat:Connect(function()
                for _,v in pairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and not v.Parent:FindFirstChildWhichIsA("Humanoid") and not v.Parent.Parent:FindFirstChildWhichIsA("Humanoid") then
                        v.LocalTransparencyModifier=0.7
                    end
                end
            end)
        else for _,v in pairs(workspace:GetDescendants()) do if v:IsA("BasePart") then v.LocalTransparencyModifier=0 end end end
    end,
}):AddKeyPicker("XRayKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="XRay Keybind" })

GB.VisR:AddLabel("── World ──")
GB.VisR:AddSlider("TimeOfDay", { Text="Time of Day", Default=14, Min=0, Max=24, Rounding=1, Compact=true, Callback=function(p) LT.ClockTime=p end })
GB.VisR:AddSlider("MaxZoom",   { Text="Max Camera Zoom", Default=400, Min=0, Max=2000, Rounding=0, Compact=true, Callback=function(p) LP.CameraMaxZoomDistance=p end })

-- ── ESP — shared system ───────────────────────────────────────────────────────
local ESPCfg = {
    mobColor=Color3.fromRGB(255,255,255), plrColor=Color3.fromRGB(0,162,255),
    hlEnabled=false, hlTrans=0.5,
    tracerColor=Color3.new(1,1,1), tracerThick=2,
    dist=1000, fontSize=14,
    mobs={}, plrs={},
    mobEnabled=false, plrEnabled=false,
    MobTracers={}, MobTracerConns={},
    PlrTracerEnabled=false,
}

local function removeESP(t, model)
    local d=t[model] if not d then return end
    for _,key in ipairs({"text","box","hpBar","hpOut","hl","anc","died","rname"}) do
        local v=d[key] if v then pcall(function()
            if key=="rname" then RS:UnbindFromRenderStep(v)
            elseif key=="anc" or key=="died" then v:Disconnect()
            elseif key=="hl" then v:Destroy()
            else v:Remove() end
        end) end
    end
    t[model]=nil
end

local function addESP(t, model, color)
    if not (model and model:IsA("Model") and not t[model]) then return end
    if t==ESPCfg.mobs and PS:GetPlayerFromCharacter(model) then return end
    local hum=model:FindFirstChildOfClass("Humanoid"); local hrp=model:FindFirstChild("HumanoidRootPart"); local head=model:FindFirstChild("Head")
    if not (hum and hrp and head) then return end
    local text=Drawing.new("Text");text.Visible=false;text.Center=true;text.Outline=true;text.Color=color;text.Size=14
    local box=Drawing.new("Square");box.Filled=false;box.Visible=false;box.Color=color;box.Thickness=1
    local hpO=Drawing.new("Square");hpO.Filled=false;hpO.Visible=false;hpO.Color=Color3.new(1,1,1);hpO.Thickness=1
    local hpB=Drawing.new("Square");hpB.Filled=true;hpB.Visible=false
    local hl=Instance.new("Highlight");hl.Parent=model;hl.FillColor=color;hl.OutlineColor=color
    hl.FillTransparency=ESPCfg.hlTrans;hl.OutlineTransparency=ESPCfg.hlTrans;hl.Enabled=ESPCfg.hlEnabled
    local rname="ESP_"..model:GetDebugId()
    RS:BindToRenderStep(rname,Enum.RenderPriority.Camera.Value+1,function()
        if not (model and model.Parent and hum and hrp and head) then removeESP(t,model);return end
        local myHRP=getHRP() if not myHRP then return end
        local dist=(hrp.Position-myHRP.Position).Magnitude
        local sp,vis=Cam:WorldToViewportPoint(hrp.Position);local _,headVis=Cam:WorldToViewportPoint(head.Position)
        if dist>ESPCfg.dist or not (vis and headVis) then
            text.Visible=false;box.Visible=false;hpB.Visible=false;hpO.Visible=false;hl.Enabled=false;return
        end
        local scale=1/math.max(sp.Z*0.1,0.001);local sw=250*scale;local sh=500*scale;local bw=50*scale
        local hp=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
        local hpClr=Color3.fromRGB(255*(1-hp),255*hp,0);local bx=sp.X-sw/2;local by=sp.Y-sh/2
        box.Position=Vector2.new(bx,by);box.Size=Vector2.new(sw,sh);box.Color=color;box.Visible=true
        hpO.Position=Vector2.new(bx-bw-2,by-1);hpO.Size=Vector2.new(bw+2,sh+2);hpO.Visible=true
        hpB.Position=Vector2.new(bx-bw-1,by+sh*(1-hp));hpB.Size=Vector2.new(bw,sh*hp);hpB.Color=hpClr;hpB.Visible=true
        text.Text=string.format("%s [%.0f/%.0f] %.0fm",model.Name,hum.Health,hum.MaxHealth,dist)
        text.Position=Vector2.new(sp.X,by-ESPCfg.fontSize-2);text.Size=ESPCfg.fontSize;text.Color=color;text.Visible=true
        hl.Enabled=ESPCfg.hlEnabled;hl.FillColor=color;hl.OutlineColor=color
    end)
    t[model]={text=text,box=box,hpBar=hpB,hpOut=hpO,hl=hl,rname=rname,
        anc=model.AncestryChanged:Connect(function(_,p) if not p then removeESP(t,model) end end),
        died=hum.Died:Connect(function() removeESP(t,model) end)}
end

local function removeMobTracer(k)
    if ESPCfg.MobTracers[k] then pcall(function() ESPCfg.MobTracers[k]:Remove() end); ESPCfg.MobTracers[k]=nil end
    if ESPCfg.MobTracerConns[k] then ESPCfg.MobTracerConns[k]:Disconnect(); ESPCfg.MobTracerConns[k]=nil end
end

-- Mob ESP
GB.MobESP:AddLabel("── ESP ──")
GB.MobESP:AddToggle("MobESPEnabled", { Text="Mob ESP",
    Callback=function(p)
        ESPCfg.mobEnabled=p
        if p then
            task.spawn(function()
                while ESPCfg.mobEnabled do
                    for _,folder in ipairs({"Live","Living"}) do
                        local f=workspace:FindFirstChild(folder)
                        if f then for _,v in ipairs(f:GetChildren()) do
                            if v:IsA("Model") and not PS:GetPlayerFromCharacter(v) and not ESPCfg.mobs[v] and v.Name~="Server" then
                                addESP(ESPCfg.mobs,v,ESPCfg.mobColor)
                            end
                        end end
                    end
                    task.wait(0.5)
                end
            end)
        else for m in pairs(ESPCfg.mobs) do removeESP(ESPCfg.mobs,m) end end
    end,
}):AddColorPicker("MobESPColor", { Default=ESPCfg.mobColor, Title="Mob ESP Color", Transparency=0,
    Callback=function(p) ESPCfg.mobColor=p for _,d in pairs(ESPCfg.mobs) do if d.text then d.text.Color=p end if d.box then d.box.Color=p end if d.hl then d.hl.FillColor=p;d.hl.OutlineColor=p end end end,
}):AddKeyPicker("MobESPKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="Mob ESP Keybind" })
GB.MobESP:AddLabel("── Highlight ──")
GB.MobESP:AddToggle("MobHighlight", { Text="Highlight",
    Callback=function(p) ESPCfg.hlEnabled=p for _,d in pairs(ESPCfg.mobs) do if d.hl then d.hl.Enabled=p end end end })
GB.MobESP:AddSlider("MobHighlightTrans", { Text="Highlight Trans", Default=0.5, Min=0, Max=1, Rounding=2, Compact=true,
    Callback=function(p) ESPCfg.hlTrans=p for _,d in pairs(ESPCfg.mobs) do if d.hl then d.hl.FillTransparency=p;d.hl.OutlineTransparency=p end end end })
GB.MobESP:AddLabel("── Tracer ──")
GB.MobESP:AddToggle("MobTracer", { Text="Tracer",
    Callback=function(p)
        ESPCfg.tracerMobEnabled=p
        if not p then for k in pairs(ESPCfg.MobTracers) do removeMobTracer(k) end
        else
            for model in pairs(ESPCfg.mobs) do
                if not ESPCfg.MobTracers[model] then
                    local line=Drawing.new("Line"); ESPCfg.MobTracers[model]=line
                    ESPCfg.MobTracerConns[model]=RS.RenderStepped:Connect(function()
                        if not (model and model.Parent and ESPCfg.tracerMobEnabled) then removeMobTracer(model); return end
                        local hrp=model:FindFirstChild("HumanoidRootPart") if not hrp then return end
                        local sp,vis=Cam:WorldToViewportPoint(hrp.Position)
                        if vis then line.From=Vector2.new(sp.X,sp.Y);line.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y);line.Color=ESPCfg.tracerColor;line.Thickness=ESPCfg.tracerThick;line.Visible=true
                        else line.Visible=false end
                    end)
                end
            end
        end
    end,
}):AddColorPicker("MobTracerColor", { Default=Color3.new(1,1,1), Title="Tracer Color", Transparency=0, Callback=function(p) ESPCfg.tracerColor=p end })
GB.MobESP:AddSlider("MobTracerThick", { Text="Tracer Thickness", Default=2, Min=1, Max=5, Rounding=0, Compact=true, Callback=function(p) ESPCfg.tracerThick=p end })

GB.ESPSet:AddSlider("ESPDistance", { Text="ESP Distance", Default=1000, Min=0, Max=10000, Rounding=0, Compact=true, Callback=function(p) ESPCfg.dist=p end })
GB.ESPSet:AddSlider("ESPFontSize",  { Text="Font Size",   Default=14,   Min=10, Max=30,    Rounding=0, Compact=true, Callback=function(p) ESPCfg.fontSize=p end })

-- Player ESP
GB.PlrESP:AddLabel("── ESP ──")
GB.PlrESP:AddToggle("PlrESPEnabled", { Text="Player ESP",
    Callback=function(p)
        ESPCfg.plrEnabled=p
        if p then
            task.spawn(function()
                while ESPCfg.plrEnabled do
                    for _,plr in ipairs(PS:GetPlayers()) do
                        if plr~=LP and plr.Character and not ESPCfg.plrs[plr.Character] then
                            addESP(ESPCfg.plrs,plr.Character,ESPCfg.plrColor)
                        end
                    end
                    task.wait(0.3)
                end
            end)
        else for c in pairs(ESPCfg.plrs) do removeESP(ESPCfg.plrs,c) end end
    end,
}):AddColorPicker("PlrESPColor", { Default=ESPCfg.plrColor, Title="Player ESP Color", Transparency=0,
    Callback=function(p) ESPCfg.plrColor=p for _,d in pairs(ESPCfg.plrs) do if d.text then d.text.Color=p end if d.box then d.box.Color=p end if d.hl then d.hl.FillColor=p;d.hl.OutlineColor=p end end end,
}):AddKeyPicker("PlrESPKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="Player ESP Keybind" })
GB.PlrESP:AddLabel("── Highlight ──")
GB.PlrESP:AddToggle("PlrHighlight", { Text="Highlight",
    Callback=function(p) for _,d in pairs(ESPCfg.plrs) do if d.hl then d.hl.Enabled=p and ESPCfg.plrEnabled end end end })
GB.PlrESP:AddSlider("PlrHighlightTrans", { Text="Highlight Trans", Default=0.5, Min=0, Max=1, Rounding=2, Compact=true,
    Callback=function(p) for _,d in pairs(ESPCfg.plrs) do if d.hl then d.hl.FillTransparency=p;d.hl.OutlineTransparency=p end end end })
GB.PlrESP:AddLabel("── Tracer ──")
GB.PlrESP:AddToggle("PlrTracer", { Text="Tracer", Default=false, Callback=function(p) ESPCfg.PlrTracerEnabled=p end }
):AddColorPicker("PlrTracerColor", { Default=Color3.new(1,1,1), Title="Tracer Color", Transparency=0, Callback=function(p) ESPCfg.plrTracerColor=p end })
GB.PlrESP:AddSlider("PlrTracerThick", { Text="Tracer Thickness", Default=1, Min=1, Max=5, Rounding=0, Compact=true, Callback=function(p) ESPCfg.plrTracerThick=p end })

-- ══════════════════════════════════════════════════════════════════════════════
-- MISC TAB
-- ══════════════════════════════════════════════════════════════════════════════

local antiAFKConn=nil
GB.MiscL:AddLabel("── Server Actions ──")
GB.MiscL:AddToggle("AntiAFK2", { Text="Anti AFK",
    Callback=function(p)
        if antiAFKConn then antiAFKConn:Disconnect(); antiAFKConn=nil end
        if p then antiAFKConn=LP.Idled:Connect(function()
            VIM:SendMouseButtonEvent(0,0,0,true,game,0); task.wait(); VIM:SendMouseButtonEvent(0,0,0,false,game,0)
        end) end
    end,
})
GB.MiscL:AddLabel("── Join Server ──")
GB.MiscL:AddButton({ Text="Rejoin", Func=function() TP:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end })
GB.MiscL:AddInput("JobID", { Default="", Numeric=false, Finished=false, Text="JobID", Placeholder="Paste job id..." })
GB.MiscL:AddButton({ Text="Join Server", Func=function() TP:TeleportToPlaceInstance(game.PlaceId,Opt.JobID.Value,LP) end })
GB.MiscL:AddButton({ Text="Copy JobId", Func=function() setclipboard(game.JobId); notify("Copied: "..game.JobId) end })

local nearbyConn=nil
GB.MiscR:AddLabel("── Notifications ──")
GB.MiscR:AddToggle("NearbyNotifier", { Text="Nearby Notifier",
    Callback=function(p)
        if nearbyConn then nearbyConn:Disconnect(); nearbyConn=nil end
        S.nearbyTable={}; if not p then return end
        nearbyConn=RS.Heartbeat:Connect(function()
            local myHRP=getHRP() if not myHRP then return end
            for _,plr in ipairs(PS:GetPlayers()) do
                if plr==LP then continue end
                local hrp=plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then S.nearbyTable[plr]=nil; continue end
                local dist=(myHRP.Position-hrp.Position).Magnitude
                local was=S.nearbyTable[plr]; local near=dist<=(Opt.NearbyDist and Opt.NearbyDist.Value or 50)
                if near and not was then S.nearbyTable[plr]=true; notify(plr.Name.." nearby ["..math.floor(dist).."m]",6)
                elseif not near and was then S.nearbyTable[plr]=nil; notify(plr.Name.." left range",4) end
            end
        end)
    end,
})
GB.MiscR:AddSlider("NearbyDist", { Text="Nearby Distance", Default=50, Min=5, Max=500, Rounding=0, Compact=true })

GB.MiscR:AddLabel("── Performance ──")
GB.MiscR:AddToggle("FPSUnlocker", { Text="FPS Unlocker", Callback=function(p) if not p then setfpscap(60) end end })
GB.MiscR:AddInput("FPSCap", { Default="144", Numeric=true, Finished=true, Text="FPS Cap", Placeholder="144",
    Callback=function(p) if Tog.FPSUnlocker and Tog.FPSUnlocker.Value then pcall(function() setfpscap(tonumber(p) or 144) end) end end })
GB.MiscR:AddButton({ Text="FPS Boost", Func=function()
    pcall(function()
        for _,v in pairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Fire") then v.Enabled=false end
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then v.Enabled=false end
        end
        LT.GlobalShadows=false
    end)
    notify("FPS Boost applied")
end})
GB.MiscR:AddButton({ Text="Remove Kill Bricks", Func=function()
    local n=0
    for _,v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local name=v.Name:lower()
            if name:find("kill") or name:find("lava") or name:find("acid") or name:find("damage") or name:find("death") or name:find("void") then
                pcall(function() v.CanTouch=false;v.CanCollide=false;v.Transparency=1 end); n+=1
            end
        end
    end
    notify("Disabled "..n.." kill bricks")
end})

local modConn,leaveOnMod=nil,false
local modKeywords={"mod","admin","staff","developer","dev","owner","manager","moderator"}
GB.MiscR:AddLabel("── Security ──")
GB.MiscR:AddToggle("ModNotifier", { Text="Mod Notifier",
    Callback=function(p)
        if modConn then modConn:Disconnect(); modConn=nil end
        if p then
            modConn=PS.PlayerAdded:Connect(function(plr)
                local n=plr.Name:lower()
                for _,kw in pairs(modKeywords) do
                    if n:find(kw) then notify("Possible mod: "..plr.Name,10)
                        if leaveOnMod then task.wait(0.5); TP:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end; return
                    end
                end
            end)
        end
    end,
})
GB.MiscR:AddToggle("LeaveOnMod", { Text="Leave On Mod", Callback=function(p) leaveOnMod=p end })

GB.MiscR:AddLabel("── Network ──")
GB.MiscR:AddToggle("AutoRejoin", { Text="Auto Rejoin",
    Callback=function(p)
        S.autoRejoin=p
        if p then task.spawn(function()
            while S.autoRejoin do
                task.wait(5); if not S.autoRejoin then break end
                pcall(function()
                    local ping=game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                    if ping>=9999 then TP:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP) end
                end)
            end
        end) end
    end,
})

local statGui=nil
GB.MiscR:AddLabel("── Display ──")
GB.MiscR:AddToggle("ShowStats", { Text="FPS & Ping",
    Callback=function(p)
        if not p then if statGui then statGui:Destroy(); statGui=nil end; return end
        statGui=Instance.new("ScreenGui"); statGui.Name="XesStats"; statGui.ResetOnSpawn=false; statGui.DisplayOrder=999
        statGui.Parent=LP:WaitForChild("PlayerGui")
        local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(0,130,0,40); lbl.Position=UDim2.new(1,-140,0,10)
        lbl.BackgroundColor3=Color3.fromRGB(15,15,15); lbl.BackgroundTransparency=0.3
        lbl.TextColor3=Color3.new(1,1,1); lbl.Font=Enum.Font.Code; lbl.TextSize=13
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.BorderSizePixel=0; lbl.Parent=statGui
        Instance.new("UICorner",lbl).CornerRadius=UDim.new(0,4); local pad=Instance.new("UIPadding",lbl); pad.PaddingLeft=UDim.new(0,6)
        local last=tick()
        RS.RenderStepped:Connect(function()
            if not statGui then return end
            local now=tick(); local fps=math.floor(1/math.max(now-last,0.001)); last=now
            local ping=0; pcall(function() ping=game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
            lbl.Text=string.format("FPS: %d\nPing: %dms",fps,ping)
        end)
    end,
})

GB.MiscR:AddLabel("── Auto Chat ──")
local autoChatOn=false
GB.MiscR:AddToggle("AutoChat", { Text="Auto Chat",
    Callback=function(p)
        autoChatOn=p
        if p then task.spawn(function()
            while autoChatOn do
                task.wait(S.autoChatDelay); if not autoChatOn then break end
                pcall(function()
                    local tc=game:GetService("TextChatService")
                    if tc.ChatVersion==Enum.ChatVersion.TextChatService then
                        local ch=tc:FindFirstChild("TextChannels"); local gen=ch and ch:FindFirstChild("RBXGeneral")
                        if gen then gen:SendAsync(S.autoChatMsg) end
                    else game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(S.autoChatMsg,"All") end
                end)
            end
        end) end
    end,
})
GB.MiscR:AddInput("AutoChatMsg",  { Default="gg", Numeric=false, Finished=true, Text="Chat Message", Placeholder="gg", Callback=function(p) S.autoChatMsg=p end })
GB.MiscR:AddSlider("AutoChatInterval", { Text="Interval (s)", Default=30, Min=5, Max=120, Rounding=0, Compact=true, Callback=function(p) S.autoChatDelay=p end })

local hitboxConn=nil
GB.MiscCom:AddLabel("── Hitbox ──")
GB.MiscCom:AddToggle("HitboxExpander", { Text="Hitbox",
    Callback=function(p)
        if hitboxConn then hitboxConn:Disconnect(); hitboxConn=nil end
        if p then
            hitboxConn=RS.Heartbeat:Connect(function()
                for _,plr in ipairs(PS:GetPlayers()) do
                    if plr~=LP and plr.Character then
                        local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then hrp.Size=Vector3.one*(Opt.HitboxSize and Opt.HitboxSize.Value or 5);hrp.Transparency=Opt.HitboxTrans and Opt.HitboxTrans.Value or 0.9;hrp.CanCollide=false;hrp.LocalTransparencyModifier=0 end
                    end
                end
            end)
        else
            for _,plr in ipairs(PS:GetPlayers()) do
                if plr~=LP and plr.Character then local hrp=plr.Character:FindFirstChild("HumanoidRootPart") if hrp then hrp.Size=Vector3.new(2,2,1);hrp.Transparency=1;hrp.CanCollide=false end end
            end
        end
    end,
})
GB.MiscCom:AddSlider("HitboxSize",  { Text="Hitbox Size",  Default=5,   Min=0, Max=20, Rounding=0, Compact=true })
GB.MiscCom:AddSlider("HitboxTrans", { Text="Transparency", Default=0.9, Min=0, Max=1,  Rounding=1, Compact=true })

-- ══════════════════════════════════════════════════════════════════════════════
-- MASHLE ACADEMY TAB
-- ══════════════════════════════════════════════════════════════════════════════

-- ── Desync (Invisible) ────────────────────────────────────────────────────────
local desyncActive=false; local desyncConn=nil; local desyncPart=nil
GB.VVExpl:AddLabel("── Invisible ──")
GB.VVExpl:AddToggle("VVDesync", { Text="Invisible (Synapse Z)", Default=false,
    Callback=function(p)
        desyncActive=p
        if not p then
            if desyncConn then desyncConn:Disconnect(); desyncConn=nil end
            if desyncPart then desyncPart:Destroy(); desyncPart=nil end
            notify("Desync OFF",2); return
        end
        if not (checkcaller and newcclosure and hookmetamethod) then notify("Unsupported executor",3);Tog.VVDesync:SetValue(false);return end
        notify("Desync ON",2)
        pcall(function() raknet.add_send_hook(function(packet) if packet.PacketId==0x1B then local data=packet.AsBuffer;buffer.writeu32(data,1,0xFFFFFFFF);packet:SetData(data) end end) end)
        pcall(function() replicatesignal(LP.Kill) end)
        local dp=Instance.new("Part",workspace);dp.Size=Vector3.new(2,1,2);dp.CanCollide=true;dp.Material=Enum.Material.ForceField;dp.Anchored=true;desyncPart=dp
        local DT={}
        desyncConn=RS.Heartbeat:Connect(function()
            if not desyncActive then return end
            local c=LP.Character;if not c then return end;local rt=c:FindFirstChild("HumanoidRootPart");if not rt then return end
            DT[1]=rt.CFrame;DT[2]=rt.AssemblyLinearVelocity
            rt.CFrame=rt.CFrame+Vector3.new(0,1000,0);dp.CFrame=rt.CFrame+Vector3.new(0,-2,0);rt.AssemblyLinearVelocity=Vector3.new(1,1,1)
            RS.RenderStepped:Wait();rt.CFrame=DT[1];rt.AssemblyLinearVelocity=DT[2]
        end)
        local _hook;_hook=hookmetamethod(game,"__index",newcclosure(function(self,key)
            if desyncActive and not checkcaller() and key=="CFrame" and LP.Character then
                local hum=LP.Character:FindFirstChild("Humanoid")
                if hum and hum.Health>0 and self==LP.Character:FindFirstChild("HumanoidRootPart") then return DT[1] or CFrame.new() end
            end
            return _hook(self,key)
        end))
    end,
}):AddKeyPicker("VVDesyncKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="Desync Keybind" })

local godV2Conn=nil
GB.VVExpl:AddLabel("── God Mode ──")
GB.VVExpl:AddToggle("GodModeV2", { Text="God Mode", Default=false,
    Callback=function(p)
        if godV2Conn then godV2Conn:Disconnect(); godV2Conn=nil end
        if not p then return end
        pcall(function()
            local UCS2=game:GetService("ReplicatedStorage").Remotes.UpdateCharacterState
            godV2Conn=RS.Heartbeat:Connect(function()
                if not Tog.GodModeV2.Value then return end
                local ping=LP:GetNetworkPing()/2
                pcall(function() UCS2:FireServer(nil,nil,true,"BoolValue","Dodge",true,0.2+ping) end)
            end)
        end)
    end,
}):AddKeyPicker("GodModeV2Keybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="God Mode Keybind" })

local autoSkipConn=nil
GB.VVExpl:AddLabel("── Skip Clash ──")
GB.VVExpl:AddToggle("AutoSkipClash", { Text="Auto Skip Clash", Default=false,
    Callback=function(p)
        if autoSkipConn then autoSkipConn:Disconnect(); autoSkipConn=nil end
        if not p then return end
        pcall(function()
            local ClashEnd=game:GetService("ReplicatedStorage").Remotes.ClashEnd
            autoSkipConn=RS.Heartbeat:Connect(function() if Tog.AutoSkipClash.Value then pcall(function() ClashEnd:FireServer() end) end end)
        end)
    end,
}):AddKeyPicker("AutoSkipClashKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="Skip Clash Keybind" })

-- ── Mob Farm ──────────────────────────────────────────────────────────────────
local farmState={mobActive=false,plrActive=false,mobTarget={},plrTarget="",lastM1=0,lastSkill={},plrLast={}}
local farmConns={mob=nil,plr=nil}

local function nearestLiveModel(filterTable)
    local hrp=getHRP() if not hrp then return end
    local live=workspace:FindFirstChild("Live") if not live then return end
    local best,bestD=nil,math.huge; local hasFilter=next(filterTable)~=nil
    for _,v in pairs(live:GetChildren()) do
        if not v:IsA("Model") then continue end
        if hasFilter then
            local dn=v:GetAttribute("DisplayName") or ""; local matched=false
            for name in pairs(filterTable) do if dn==name or v.Name==name then matched=true;break end end
            if not matched then continue end
        end
        local h=v:FindFirstChildOfClass("Humanoid");local r=v:FindFirstChild("HumanoidRootPart")
        if not (h and r and h.Health>0) then continue end
        if PS:GetPlayerFromCharacter(v) then continue end
        local d=(r.Position-hrp.Position).Magnitude if d<bestD then best=v;bestD=d end
    end
    return best
end

local function nearestPlayer()
    local hrp=getHRP() if not hrp then return end
    local live=workspace:FindFirstChild("Live") if not live then return end
    local best,bestD=nil,math.huge
    for _,plr in ipairs(PS:GetPlayers()) do
        if plr==LP then continue end
        if farmState.plrTarget~="" and plr.Name~=farmState.plrTarget then continue end
        local liveChar=live:FindFirstChild("."..plr.Name) or live:FindFirstChild(plr.Name)
        if not liveChar then continue end
        local r=liveChar:FindFirstChild("HumanoidRootPart");local h=liveChar:FindFirstChildOfClass("Humanoid")
        if not (r and h and h.Health>0) then continue end
        local d=(r.Position-hrp.Position).Magnitude if d<bestD then best=liveChar;bestD=d end
    end
    return best
end

local function makeFarmConn(targetFn, lastTable, activeKey)
    return RS.Heartbeat:Connect(function()
        if not farmState[activeKey] then return end
        local c=getChar() if not c then return end
        local hum=c:FindFirstChildOfClass("Humanoid") if not (hum and hum.RootPart) then return end
        local hrp=hum.RootPart; hum.Health=hum.MaxHealth
        local tgt=targetFn()
        if tgt then
            local rp=tgt:FindFirstChild("HumanoidRootPart") if rp then
                local mp=rp.Position
                hrp.CFrame=CFrame.lookAt(Vector3.new(mp.X,mp.Y-7,mp.Z),mp)
                hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                pcall(sethiddenproperty,hrp,"PhysicsRepRootPart",rp)
                rp.AssemblyLinearVelocity=Vector3.zero; rp.AssemblyAngularVelocity=Vector3.zero
            end
        end
        local now=tick()
        if tgt and now-(lastTable.m1 or 0)>=0.1 then
            pcall(function()
                local ReqMod=game:GetService("ReplicatedStorage").Remotes.RequestModule
                local Data=LP:FindFirstChild("Data"); local wpn=Data and Data:FindFirstChild("Weapon")
                if wpn and wpn.Value~="None" then ReqMod:FireServer(wpn.Value,"NormalAttack",nil) end
            end); lastTable.m1=now
        end
        if tgt then
            pcall(function()
                local ReqMod=game:GetService("ReplicatedStorage").Remotes.RequestModule
                local Data=LP:FindFirstChild("Data"); local mag=Data and Data:FindFirstChild("Magic")
                local CS=c:FindFirstChild("CharacterState"); local ca=CS and CS:FindFirstChild("CanAct")
                if mag and ca and ca.Value then
                    for _,key in ipairs({"Z","X","C"}) do
                        if now-(lastTable[key] or 0)>=0.8 then ReqMod:FireServer(mag.Value,key,nil);lastTable[key]=now;break end
                    end
                end
            end)
        end
    end)
end

local maMobList={"Any (Closest)"}
GB.VVFarm:AddLabel("── Target Mob ──")
GB.VVFarm:AddButton({ Text="Refresh Mob List", Func=function()
    local newList={"Any (Closest)"}; local seen={}
    local live=workspace:FindFirstChild("Live")
    if live then for _,v in ipairs(live:GetChildren()) do
        if v:IsA("Model") and not PS:GetPlayerFromCharacter(v) then
            local dn=v:GetAttribute("DisplayName") or ""; local name=dn~="" and dn or v.Name
            if not seen[name] then seen[name]=true;table.insert(newList,name) end
        end
    end end
    maMobList=newList; Opt.MaMobSelect:SetValues(newList); notify(#newList-1 .." mobs found",2)
end})
GB.VVFarm:AddDropdown("MaMobSelect", { Text="Target Mob", Values=maMobList, Default={}, Multi=true,
    Callback=function(v) farmState.mobTarget=type(v)=="table" and (v["Any (Closest)"] and {} or v) or {} end })
GB.VVFarm:AddLabel("── Auto Farm ──")
GB.VVFarm:AddToggle("MaMobFarm", { Text="Auto Farm", Default=false,
    Callback=function(p)
        farmState.mobActive=p
        if farmConns.mob then farmConns.mob:Disconnect(); farmConns.mob=nil end
        if p then farmConns.mob=makeFarmConn(function() return nearestLiveModel(farmState.mobTarget) end,{m1=0},"mobActive") end
    end,
}):AddKeyPicker("MaMobFarmKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="Auto Farm Keybind" })

GB.VVFarm:AddLabel("── Farm Players ──")
GB.VVFarm:AddDropdown("MaPlrFarmSelect", { Text="Target Player", Values={"Any (Closest)"}, Default=1, Multi=false,
    Callback=function(v) farmState.plrTarget=(v=="Any (Closest)") and "" or tostring(v) end })
GB.VVFarm:AddButton({ Text="Refresh Players", Func=function()
    local list={"Any (Closest)"} for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(list,plr.Name) end end
    Opt.MaPlrFarmSelect:SetValues(list); notify(#list-1 .." players",2)
end})
GB.VVFarm:AddToggle("MaPlrFarm", { Text="Farm Players", Default=false,
    Callback=function(p)
        farmState.plrActive=p
        if farmConns.plr then farmConns.plr:Disconnect(); farmConns.plr=nil end
        if p then farmConns.plr=makeFarmConn(nearestPlayer,{m1=0},"plrActive") end
    end,
}):AddKeyPicker("MaPlrFarmKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="Farm Players Keybind" })

-- ── Combat ────────────────────────────────────────────────────────────────────
local combatConns={}
local csKeys={Z=true,X=true,C=true}
local _RS2=game:GetService("ReplicatedStorage"); local _Rem2=_RS2:WaitForChild("Remotes",10)
local _ReqMod=_Rem2 and _Rem2:WaitForChild("RequestModule",5)

local function withReqMod(fn) if _ReqMod then pcall(fn, _ReqMod) end end

GB.VVCom:AddLabel("── Auto Combat ──")
GB.VVCom:AddToggle("AutoEquip", { Text="Auto Equip", Default=false,
    Callback=function(p)
        if combatConns.equip then combatConns.equip:Disconnect(); combatConns.equip=nil end
        if p then combatConns.equip=RS.Heartbeat:Connect(function()
            withReqMod(function(r) r:FireServer("Misc","WeaponHandler","Equip") end)
        end) end
    end,
})
GB.VVCom:AddToggle("AutoGrip", { Text="Auto Grip", Default=false,
    Callback=function(p)
        if combatConns.grip then combatConns.grip:Disconnect(); combatConns.grip=nil end
        if p then combatConns.grip=RS.Heartbeat:Connect(function()
            withReqMod(function(r) r:FireServer("Misc","Grip",nil) end)
        end) end
    end,
})

local noFallHook=nil
GB.VVCom:AddToggle("NoFallDamage", { Text="No Fall Damage", Default=false,
    Callback=function(p)
        if not p then
            if noFallHook then
                local mt2=getrawmetatable(game)
                pcall(function() setreadonly(mt2,false) end); pcall(function() mt2.__namecall=noFallHook end); pcall(function() setreadonly(mt2,true) end)
                noFallHook=nil
            end
            return
        end
        pcall(function()
            local mt2=getrawmetatable(game); local oldNC=mt2.__namecall; noFallHook=oldNC
            setreadonly(mt2,false)
            mt2.__namecall=newcclosure(function(self,...)
                local method=getnamecallmethod()
                if method=="FireServer" and self==_ReqMod then
                    local args={...}
                    if args[1]=="Misc" and args[2]=="FallDamage" then
                        return _ReqMod:FireServer("Misc","FallDamage",nil,{FallDamageValueTotal=0,FallDamage=0})
                    end
                end
                return oldNC(self,...)
            end)
            setreadonly(mt2,true)
        end)
    end,
})

GB.VVCom:AddToggle("AutoCritical", { Text="Auto Critical", Default=false,
    Callback=function(p)
        if combatConns.crit then combatConns.crit:Disconnect(); combatConns.crit=nil end
        if not p then return end
        pcall(function()
            local Data=LP:WaitForChild("Data",10); local Char=getChar() or LP.CharacterAdded:Wait()
            local CS=Char:WaitForChild("CharacterState",10)
            if not (Data and CS) then notify("Auto Critical: data not ready",3);Tog.AutoCritical:SetValue(false);return end
            local last=0
            combatConns.crit=RS.Heartbeat:Connect(function()
                if not Tog.AutoCritical.Value then return end
                local now=tick(); if now-last<0.1 then return end; last=now
                pcall(function()
                    local ca=CS:FindFirstChild("CanAct"); local weq=CS:FindFirstChild("WeaponEquipped"); local wpn=Data:FindFirstChild("Weapon")
                    if ca and ca.Value and wpn and wpn.Value~="None" and weq and weq.Value then
                        withReqMod(function(r) r:FireServer(wpn.Value,"SpecialAttack",nil) end)
                    end
                end)
            end)
        end)
    end,
})

GB.VVCom:AddToggle("AutoM1", { Text="Auto M1", Default=false,
    Callback=function(p)
        if combatConns.m1 then combatConns.m1:Disconnect(); combatConns.m1=nil end
        if not p then return end
        pcall(function()
            local Data=LP:WaitForChild("Data",10)
            if not Data then notify("Auto M1: data not ready",3);Tog.AutoM1:SetValue(false);return end
            local last=0
            combatConns.m1=RS.Heartbeat:Connect(function()
                if not Tog.AutoM1.Value then return end
                local now=tick(); if now-last<0.1 then return end; last=now
                pcall(function()
                    local wpn=Data:FindFirstChild("Weapon")
                    if wpn and wpn.Value~="None" then withReqMod(function(r) r:FireServer(wpn.Value,"NormalAttack",nil) end) end
                end)
            end)
        end)
    end,
})

GB.VVCom:AddLabel("── Auto Skills ──")
GB.VVCom:AddDropdown("AutoSkillKeys", { Text="Skills", Multi=true, Default={Z=true,X=true,C=true}, Values={"Z","X","C"},
    Callback=function(v) csKeys=type(v)=="table" and v or {} end })
GB.VVCom:AddToggle("AutoSkills", { Text="Auto Skills", Default=false,
    Callback=function(p)
        if combatConns.skill then combatConns.skill:Disconnect(); combatConns.skill=nil end
        if not p then return end
        pcall(function()
            local Data=LP:WaitForChild("Data",10); local Char=getChar() or LP.CharacterAdded:Wait()
            local CS=Char:WaitForChild("CharacterState",10)
            if not (Data and CS) then notify("Auto Skills: data not ready",3);Tog.AutoSkills:SetValue(false);return end
            local last=0
            combatConns.skill=RS.Heartbeat:Connect(function()
                if not Tog.AutoSkills.Value then return end
                local now=tick(); if now-last<0.1 then return end; last=now
                pcall(function()
                    local ca=CS:FindFirstChild("CanAct"); local mag=Data:FindFirstChild("Magic")
                    if ca and ca.Value and mag then
                        for _,key in ipairs({"Z","X","C"}) do
                            if csKeys[key] then withReqMod(function(r) r:FireServer(mag.Value,key,nil) end) end
                        end
                    end
                end)
            end)
        end)
    end,
})

local statInvestConn=nil
GB.VVCom:AddLabel("── Passives ──")
GB.VVCom:AddDropdown("GetPassives", {
    Text = "Passive", Default = 1, Multi = false,
    Values = {"Magic Surge", "Demonic Ascension"},
})
GB.VVCom:AddButton("Activate Passive", function()
    local sel = Opt.GetPassives and Opt.GetPassives.Value
    if not sel then return end
    if sel == "Magic Surge" then
        withReqMod(function(r) r:FireServer("Misc","MagicSurge",nil,{Active=true}) end)
        notify("[xes] surge on",2)
    elseif sel == "Demonic Ascension" then
        withReqMod(function(r) r:FireServer("Misc","DemonicAscension",nil) end)
        notify("[xes] demonic ascension",2)
    end
end)

GB.VVCom:AddLabel("── Stats ──")
GB.VVCom:AddDropdown("StatSelect", {
    Text = "Stat", Default = 1, Multi = false,
    Values = {"Muscle","MagicPower","Durability","Agility","Stamina"},
})
GB.VVCom:AddInput("StatAmount", {
    Default = "1", Numeric = true, Finished = false,
    Text = "Amount", Placeholder = "1",
})
GB.VVCom:AddToggle("AutoInvestStat", { Text="Auto Invest Stat", Default=false,
    Callback=function(p)
        if statInvestConn then statInvestConn:Disconnect(); statInvestConn=nil end
        if not p then return end
        local investRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("InvestStat")
        statInvestConn=RS.Heartbeat:Connect(function()
            pcall(function()
                local stat   = Opt.StatSelect and Opt.StatSelect.Value
                local amount = tonumber(Opt.StatAmount and Opt.StatAmount.Value) or 1
                if not stat then return end
                investRemote:FireServer(stat, amount)
            end)
        end)
    end,
})


local instaKillConn=nil


-- ── Insta Kill ────────────────────────────────────────────────────────────────
GB.VVTP:AddToggle("InstaKill", { Text="Insta Kill", Default=false,
    Callback=function(p)
        if instaKillConn then instaKillConn:Disconnect(); instaKillConn=nil end
        if not p then return end
        instaKillConn=RS.Heartbeat:Connect(function()
            pcall(function()
                sethiddenproperty(LP,"SimulationRadius",math.huge)
                local live=workspace:FindFirstChild("Live") if not live then return end
                local destroyY=workspace.FallenPartsDestroyHeight or -500
                for _,v in ipairs(live:GetChildren()) do
                    if v:IsA("Model") and v~=getChar() and not PS:GetPlayerFromCharacter(v) then
                        local hum=v:FindFirstChildOfClass("Humanoid"); local hrp=v:FindFirstChild("HumanoidRootPart")
                        if hum and hum.Health>0 and hrp then hum.Health=0;hrp.CFrame=CFrame.new(hrp.Position.X,destroyY-100,hrp.Position.Z) end
                    end
                end
            end)
        end)
    end,
}):AddKeyPicker("InstaKillKeybind", { Default="", SyncToggleState=true, Mode="Toggle", Text="Insta Kill Keybind" })

-- ── NPC / Zone / Waygate TP ───────────────────────────────────────────────────
local npcList={"(refresh)"}; local zoneList={"(refresh)"}

local function refreshNPCZones()
    local t={} local nz=workspace:FindFirstChild("NPC_Zones")
    if nz then for _,v in ipairs(nz:GetChildren()) do table.insert(t,v.Name) end; table.sort(t) end
    npcList=#t>0 and t or {"None found"}
end
local function refreshZones()
    local t={} local z=workspace:FindFirstChild("Zones")
    if z then for _,v in ipairs(z:GetChildren()) do table.insert(t,v.Name) end; table.sort(t) end
    zoneList=#t>0 and t or {"None found"}
end
refreshNPCZones(); refreshZones()

local function tpToModel(model)
    local hrp=getHRP() if not hrp or not model then return end
    local pos=model:IsA("BasePart") and model.Position or (model.PrimaryPart and model.PrimaryPart.Position) or model:GetPivot().Position
    hrp.CFrame=CFrame.new(pos+Vector3.new(0,5,0))
end

GB.VVTP:AddLabel("── NPC Zones ──")
GB.VVTP:AddDropdown("NPCZoneSelect", { Text="NPC Zone", Values=npcList, Default=1, Multi=false })
GB.VVTP:AddButton("TP to NPC Zone", function()
    local sel=Opt.NPCZoneSelect and Opt.NPCZoneSelect.Value if not sel then return end
    local target=workspace.NPC_Zones and workspace.NPC_Zones:FindFirstChild(sel)
    if not target then notify("NPC Zone not found",3);return end; tpToModel(target)
end)
GB.VVTP:AddButton("Refresh NPC Zones", function() refreshNPCZones();Opt.NPCZoneSelect:SetValues(npcList);notify("NPC Zones: "..#npcList,2) end)

GB.VVTP:AddLabel("── Zones ──")
GB.VVTP:AddDropdown("ZoneSelect", { Text="Zone", Values=zoneList, Default=1, Multi=false })
GB.VVTP:AddButton("TP to Zone", function()
    local sel=Opt.ZoneSelect and Opt.ZoneSelect.Value if not sel then return end
    local target=workspace.Zones and workspace.Zones:FindFirstChild(sel)
    if not target then notify("Zone not found",3);return end; tpToModel(target)
end)
GB.VVTP:AddButton("Refresh Zones", function() refreshZones();Opt.ZoneSelect:SetValues(zoneList);notify("Zones: "..#zoneList,2) end)

GB.VVTP:AddLabel("── Waygates ──")
local waygateRemote=_Rem2 and _Rem2:FindFirstChild("Waypoint")
local function buildWaygateList()
    local list={}
    pcall(function()
        local data=LP:WaitForChild("Data",5); local mapData=data and data:FindFirstChild("MapData")
        local unlocked=mapData and mapData:FindFirstChild("WaygatesUnlocked")
        if unlocked then for _,v in ipairs(unlocked:GetChildren()) do if v.Value==true then table.insert(list,v.Name) end end end
    end)
    if #list==0 then list={"Tutorial Area","Grassland","East Forest","Dark Forest","Volcano Region","Snowy Peaks","Desert Oasis","Dungeon Entrance","Central Magic Region","Soul Society"} end
    return list
end
local waygateList=buildWaygateList()
GB.VVTP:AddDropdown("WaygateSelect", { Text="Waygate", Values=waygateList, Default=1, Searchable=true })
GB.VVTP:AddButton("Teleport via Waygate", function()
    local sel=Opt.WaygateSelect and Opt.WaygateSelect.Value if not sel then return end
    if not waygateRemote then waygateRemote=_Rem2 and _Rem2:FindFirstChild("Waypoint") end
    if not waygateRemote then notify("Waypoint remote not found",3);return end
    pcall(function() waygateRemote:FireServer(sel) end); notify("Warping to "..sel,2)
end)
GB.VVTP:AddButton("Refresh Waygates", function() waygateList=buildWaygateList();Opt.WaygateSelect:SetValues(waygateList);notify("Waygates: "..#waygateList,2) end)

GB.VVTP:AddLabel("── Trinkets ──")

local trinketList = {"(refresh first)"}


local function getTrinketFolder()
    return workspace:FindFirstChild("Interactables")
        and workspace.Interactables:FindFirstChild("MapLoot")
        and workspace.Interactables.MapLoot:FindFirstChild("SpawnSpots")
end

local function getTrinketPos(model)
    if not model then return nil end
    if model:IsA("BasePart") then return model.Position end
    if model.PrimaryPart then return model.PrimaryPart.Position end
    local any = model:FindFirstChildWhichIsA("BasePart")
    return any and any.Position or model:GetPivot().Position
end

local function tpAndFire(model)
    local hrp = getHRP() if not hrp then return end
    local pos = getTrinketPos(model) if not pos then return end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
    hrp.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.2)
    local pp = model:FindFirstChild("TrinketProximityPrompt")
        or model:FindFirstChildWhichIsA("ProximityPrompt", true)
    if pp then
        fireproximityprompt(pp)
    end
end

GB.VVTP:AddButton("Refresh Trinkets", function()
    local folder = getTrinketFolder()
    if not folder then notify("SpawnSpots not found", 3); return end
    local list = {}
    for _, v in ipairs(folder:GetChildren()) do table.insert(list, v.Name) end
    table.sort(list)
    if #list == 0 then list = {"(none found)"} end
    trinketList = list
    Opt.TrinketSelect:SetValues(list)
    notify(#list .. " trinkets found", 2)
end)

GB.VVTP:AddDropdown("TrinketSelect", {
    Text = "Trinket", Values = trinketList, Default = 1, Searchable = true,
})

GB.VVTP:AddButton("TP to Trinket", function()
    local sel = Opt.TrinketSelect and Opt.TrinketSelect.Value if not sel then return end
    local folder = getTrinketFolder() if not folder then return end
    local model = folder:FindFirstChild(sel) if not model then return end
    tpAndFire(model)
end)



do

local _lastParry=0; local _lastDodge=0; local _connections={}; local _watchedAnims={}
local _savedTimings={}; local _timings={}; local _loggedAnims={}; local _loggedMap={}
local _activeTriggers={}; local _animCooldowns={}; local _activeTriggerMap={}

local TIMINGS_FILE="xes_hub_timings.json"

local function _serTimings()
    local t={}
    for _,e in ipairs(_savedTimings) do table.insert(t,string.format('{"name":%q,"animId":%q,"delay":%s,"minDist":%s,"maxDist":%s,"action":%q}',e.name,e.animId,tostring(e.delay),tostring(e.minDist),tostring(e.maxDist),e.action)) end
    return "["..table.concat(t,",").."]"
end
local function _parseTim(s)
    local r={} for entry in s:gmatch("{(.-)}") do
        local n=entry:match('"name"%s*:%s*"(.-)"');local a=entry:match('"animId"%s*:%s*"(.-)"')
        local d=entry:match('"delay"%s*:%s*([%d%.]+)');local mn=entry:match('"minDist"%s*:%s*([%d%.]+)')
        local mx=entry:match('"maxDist"%s*:%s*([%d%.]+)');local ac=entry:match('"action"%s*:%s*"(.-)"')
        if n and a then table.insert(r,{name=n,animId=a,delay=tonumber(d) or 0,minDist=tonumber(mn) or 0,maxDist=tonumber(mx) or 50,action=ac or "Parry"}) end
    end; return r
end
local function _saveDisk() pcall(function() writefile(TIMINGS_FILE,_serTimings()) end) end
local function _loadDisk()
    local ok,raw=pcall(function() return readfile(TIMINGS_FILE) end)
    if not ok or not raw or raw=="" then return end
    local loaded=_parseTim(raw); _savedTimings={}; _timings={}
    for _,e in ipairs(loaded) do table.insert(_savedTimings,e); if not _timings[e.animId] then _timings[e.animId]={} end; table.insert(_timings[e.animId],e) end
    local ns={} for _,e in ipairs(_savedTimings) do table.insert(ns,e.name) end
    if #ns>0 then Opt.SavedTimings:SetValues(ns);Opt.SavedTimings:SetValue(ns[1]) end
end

-- Floating window helpers
local _BG=Color3.fromRGB(18,18,18);local _TBG=Color3.fromRGB(26,26,26);local _BOR=Color3.fromRGB(80,80,80)
local _CY=Color3.fromRGB(200,200,200);local _WH=Color3.fromRGB(230,230,230);local _DIM=Color3.fromRGB(130,130,130)
local _RED2=Color3.fromRGB(185,50,50);local _SEL=Color3.fromRGB(40,40,40);local _MONO=Enum.Font.Gotham

local function _ni(cls,props,par) local o=Instance.new(cls) for k,v in pairs(props) do o[k]=v end if par then o.Parent=par end return o end
local function _drag(bar,win)
    local on,ds,sp
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then on=true;ds=i.Position;sp=win.Position end end)
    UIS.InputChanged:Connect(function(i) if on and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-ds;win.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then on=false end end)
end
local function _sBtn(par,txt,w,col)
    local b=_ni("TextButton",{Size=UDim2.new(0,w,1,-6),BackgroundColor3=Color3.fromRGB(32,32,32),Text=txt,TextColor3=col or Color3.fromRGB(190,190,190),Font=_MONO,TextSize=11,AutoButtonColor=false,ZIndex=13,Parent=par})
    _ni("UICorner",{CornerRadius=UDim.new(0,4)},b);b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(48,48,48) end);b.MouseLeave:Connect(function() b.BackgroundColor3=Color3.fromRGB(32,32,32) end);return b
end
local function _mWin(pos,sz,title)
    local win=_ni("Frame",{Position=pos,Size=sz,BackgroundColor3=_BG,BorderSizePixel=0,Visible=false,ZIndex=10})
    _ni("UICorner",{CornerRadius=UDim.new(0,3)},win);_ni("UIStroke",{Color=_BOR,Thickness=1},win)
    local tb=_ni("Frame",{Size=UDim2.new(1,0,0,20),BackgroundColor3=_TBG,BorderSizePixel=0,ZIndex=11,Parent=win})
    _ni("UICorner",{CornerRadius=UDim.new(0,3)},tb)
    _ni("Frame",{Position=UDim2.new(0,0,0.5,0),Size=UDim2.new(1,0,0.5,0),BackgroundColor3=_TBG,BorderSizePixel=0,ZIndex=11,Parent=tb})
    _ni("Frame",{Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),BackgroundColor3=_BOR,BorderSizePixel=0,ZIndex=12,Parent=tb})
    _ni("TextLabel",{Position=UDim2.new(0,6,0,0),Size=UDim2.new(1,-26,1,0),BackgroundTransparency=1,Text=title,TextColor3=_CY,Font=_MONO,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=tb})
    local xb=_ni("TextButton",{Position=UDim2.new(1,-22,0.5,-8),Size=UDim2.new(0,16,0,16),BackgroundColor3=Color3.fromRGB(50,22,22),Text="x",TextColor3=Color3.fromRGB(180,80,80),Font=_MONO,TextSize=12,AutoButtonColor=false,ZIndex=13,Parent=tb})
    _ni("UICorner",{CornerRadius=UDim.new(0,4)},xb);xb.MouseEnter:Connect(function() xb.BackgroundColor3=Color3.fromRGB(80,28,28) end);xb.MouseLeave:Connect(function() xb.BackgroundColor3=Color3.fromRGB(50,22,22) end)
    _drag(tb,win);return win,tb,xb
end

local _sg=_ni("ScreenGui",{Name="XesHubFloat",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Global,IgnoreGuiInset=true})
pcall(function() _sg.Parent=game:GetService("CoreGui") end);if not _sg.Parent then _sg.Parent=LP.PlayerGui end

local _lW,_lTB,_lXB=_mWin(UDim2.new(1,-692,0,54),UDim2.new(0,680,0,360),"Animation Logger")
local _vW,_vTB,_vXB=_mWin(UDim2.new(0,6,0.5,-260),UDim2.new(0,420,0,520),"Animation Visualizer")
_lW.Parent=_sg;_vW.Parent=_sg

local _lTR=_ni("Frame",{Position=UDim2.new(1,-126,0,1),Size=UDim2.new(0,104,0,18),BackgroundTransparency=1,ZIndex=12,Parent=_lTB})
_ni("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,3),VerticalAlignment=Enum.VerticalAlignment.Center,Parent=_lTR})
_lXB.Position=UDim2.new(1,-18,0.5,-7);local _clrB=_sBtn(_lTR,"Clear",50,_RED2);local _refB=_sBtn(_lTR,"Refresh",48)
local _lScr=_ni("ScrollingFrame",{Position=UDim2.new(0,0,0,20),Size=UDim2.new(1,0,1,-20),BackgroundColor3=_BG,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=_BOR,CanvasSize=UDim2.new(0,0,0,0),ZIndex=11,Parent=_lW})
_ni("UIPadding",{PaddingLeft=UDim.new(0,5),PaddingTop=UDim.new(0,3),Parent=_lScr})
local _lList=_ni("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0),Parent=_lScr})
_lList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() _lScr.CanvasSize=UDim2.new(0,0,0,_lList.AbsoluteContentSize.Y+4) end)
local _lObjs={}; local _selIdx=nil; local _visOpenWithId

local function _fmt(e) local ds=e.dist and string.format("%.0fm  ",e.dist) or "";local nm=e.animName and "["..e.animName.."]  " or "";local id=e.id:match("(%d+)$") or e.id;return string.format("%s%s%s  --  %s",nm,ds,id,e.source or "?") end
local function _addLine(entry)
    local ord=#_lObjs+1
    local lbl=_ni("TextLabel",{Size=UDim2.new(1,-10,0,14),BackgroundColor3=_BG,BackgroundTransparency=1,Text=_fmt(entry),TextColor3=_WH,Font=_MONO,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=12,LayoutOrder=ord,Parent=_lScr})
    local idx=#_lObjs+1;table.insert(_lObjs,{lbl=lbl,id=entry.id})
    lbl.InputBegan:Connect(function(i)
        if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        if _selIdx and _lObjs[_selIdx] and _lObjs[_selIdx].lbl.Parent then local p=_lObjs[_selIdx];p.lbl.BackgroundColor3=_SEL;p.lbl.TextColor3=_WH;p.lbl.BackgroundTransparency=1 end
        _selIdx=idx;lbl.BackgroundTransparency=0;lbl.BackgroundColor3=_SEL;lbl.TextColor3=_CY
        if setclipboard then setclipboard(entry.id) end
        if Opt.AnimationID then Opt.AnimationID:SetValue(entry.id) end
        Library:Notify("Copied "..entry.id:match("(%d+)$"),1)
        if _vW.Visible then _visOpenWithId(entry.id,entry.entity) end
    end)
    lbl.MouseEnter:Connect(function() if _selIdx==idx then return end;lbl.BackgroundTransparency=0;lbl.BackgroundColor3=Color3.fromRGB(0,20,20) end)
    lbl.MouseLeave:Connect(function() if _selIdx==idx then return end;lbl.BackgroundTransparency=1 end)
    task.defer(function() _lScr.CanvasPosition=Vector2.new(0,math.max(0,_lList.AbsoluteContentSize.Y-_lScr.AbsoluteSize.Y)) end)
end
local function _clrLog() for _,o in ipairs(_lObjs) do pcall(function() o.lbl:Destroy() end) end;_lObjs={};_selIdx=nil;_loggedAnims={};_loggedMap={};_lScr.CanvasSize=UDim2.new(0,0,0,0) end
_clrB.MouseButton1Click:Connect(function() _clrLog();Library:Notify("Cleared",1.5) end)
_refB.MouseButton1Click:Connect(function() Library:Notify(#_lObjs.." lines",1.5) end)
_lXB.MouseButton1Click:Connect(function() _lW.Visible=false;if Tog.EnableLogger then Tog.EnableLogger:SetValue(false) end end)

-- Visualizer
local _vp=_ni("ViewportFrame",{Position=UDim2.new(0,6,0,26),Size=UDim2.new(1,-12,0,300),BackgroundColor3=Color3.fromRGB(6,6,10),ZIndex=11,Parent=_vW})
_ni("UICorner",{CornerRadius=UDim.new(0,3)},_vp);_ni("UIStroke",{Color=_BOR,Thickness=1},_vp)
_vp.LightColor=Color3.fromRGB(220,220,220);_vp.LightDirection=Vector3.new(-1,-2,-0.5);_vp.Ambient=Color3.fromRGB(140,140,140)
local _vpW=Instance.new("WorldModel");_vpW.Parent=_vp
local _vpH=_ni("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="enter id -> play",TextColor3=_DIM,Font=_MONO,TextSize=11,ZIndex=12,Parent=_vp})
local _vStat=_ni("TextLabel",{Position=UDim2.new(0,6,0,330),Size=UDim2.new(1,-12,0,12),BackgroundTransparency=1,Text="not loaded",TextColor3=_DIM,Font=_MONO,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=11,Parent=_vW})
local _idF=_ni("Frame",{Position=UDim2.new(0,6,0,346),Size=UDim2.new(1,-12,0,20),BackgroundColor3=_TBG,ZIndex=11,Parent=_vW})
_ni("UICorner",{CornerRadius=UDim.new(0,3)},_idF);_ni("UIStroke",{Color=_BOR,Thickness=1},_idF)
local _idBox=_ni("TextBox",{Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,5,0,0),BackgroundTransparency=1,Text="",PlaceholderText="rbxassetid://0",PlaceholderColor3=_DIM,TextColor3=_CY,Font=_MONO,TextSize=10,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=12,Parent=_idF})
local _cRow=_ni("Frame",{Position=UDim2.new(0,6,0,400),Size=UDim2.new(1,-12,0,22),BackgroundTransparency=1,ZIndex=11,Parent=_vW})
_ni("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Center,Padding=UDim.new(0,4),Parent=_cRow})
local function _vB(sym,col) local bg=Color3.fromRGB(30,30,30);local b=_ni("TextButton",{Size=UDim2.new(0,64,1,0),BackgroundColor3=bg,Text=sym,TextColor3=col or Color3.fromRGB(200,200,200),Font=_MONO,TextSize=13,AutoButtonColor=false,ZIndex=12,Parent=_cRow});_ni("UICorner",{CornerRadius=UDim.new(0,5)},b);b.MouseEnter:Connect(function() b.BackgroundColor3=Color3.fromRGB(50,50,50) end);b.MouseLeave:Connect(function() b.BackgroundColor3=bg end);return b end
local _bRestart=_vB("|<");local _bPlay=_vB("P",_CY);local _bStop=_vB("[]",_RED2)
local _eRow=_ni("Frame",{Position=UDim2.new(0,6,0,384),Size=UDim2.new(1,-12,0,12),BackgroundTransparency=1,ZIndex=11,Parent=_vW})
local _loopB=_ni("TextButton",{Size=UDim2.new(0.5,-2,1,0),BackgroundTransparency=1,Text="loop: on",TextColor3=_CY,Font=_MONO,TextSize=11,AutoButtonColor=false,ZIndex=12,Parent=_eRow})
local _spdB=_ni("TextButton",{Position=UDim2.new(0.5,2,0,0),Size=UDim2.new(0.5,-2,1,0),BackgroundTransparency=1,Text="speed: 1.0x",TextColor3=_DIM,Font=_MONO,TextSize=11,AutoButtonColor=false,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=12,Parent=_eRow})
local _tlBg=_ni("Frame",{Position=UDim2.new(0,6,0,370),Size=UDim2.new(1,-12,0,10),BackgroundColor3=_TBG,ZIndex=11,Parent=_vW});_ni("UICorner",{CornerRadius=UDim.new(0,5)},_tlBg);_ni("UIStroke",{Color=_BOR,Thickness=1},_tlBg)
local _tlF=_ni("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=_CY,BorderSizePixel=0,ZIndex=12,Parent=_tlBg});_ni("UICorner",{CornerRadius=UDim.new(0,5)},_tlF)
local _tlH=_ni("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",AutoButtonColor=false,ZIndex=14,Parent=_tlBg})
local _tLbl=_ni("TextLabel",{Position=UDim2.new(0,6,0,326),Size=UDim2.new(1,-12,0,12),BackgroundTransparency=1,Text="0.000 / 0.000  (0ms)",TextColor3=_DIM,Font=_MONO,TextSize=11,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=11,Parent=_vW})
local _iLbl=_ni("TextLabel",{Position=UDim2.new(0,6,0,442),Size=UDim2.new(1,-12,0,11),BackgroundTransparency=1,Text="",TextColor3=_DIM,Font=_MONO,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=11,Parent=_vW})

local _V={cam=nil,model=nil,anim8r=nil,animObj=nil,track=nil,hb=nil,paused=false,length=0,loop=true,speed=1,speeds={0.25,0.5,1,1.5,2},spIdx=3,rotY=math.pi}
local function _vSet(msg,col) _vStat.Text=msg;_vStat.TextColor3=col or _DIM end
local function _vClean()
    if _V.hb then _V.hb:Disconnect();_V.hb=nil end
    if _V.track then pcall(function()_V.track:Stop(0)end);pcall(function()_V.track:Destroy()end);_V.track=nil end
    if _V.animObj then pcall(function()_V.animObj:Destroy()end);_V.animObj=nil end
    if _V.model then pcall(function()_V.model:Destroy()end);_V.model=nil end
    if _V.cam then pcall(function()_V.cam:Destroy()end);_V.cam=nil end
    _V.anim8r=nil;_V.length=0;_V.paused=false
    _tlF.Size=UDim2.new(0,0,1,0);_tLbl.Text="0.000 / 0.000  (0ms)";_iLbl.Text=""
    _bPlay.Text="P";_bPlay.TextColor3=_CY;_vpH.Visible=true;_vSet("not loaded")
end
local function _vLoad(animId,srcModel)
    _vClean();_vSet("cloning...")
    local char=(srcModel and srcModel.Parent and srcModel) or LP.Character;if not char then _vSet("no character",_RED2);return end
    local restored={}
    pcall(function() for _,d in ipairs(char:GetDescendants()) do if not d.Archivable then d.Archivable=true;table.insert(restored,d) end end;if not char.Archivable then char.Archivable=true;table.insert(restored,char) end end)
    local clone;pcall(function() clone=char:Clone() end)
    for _,d in ipairs(restored) do pcall(function() d.Archivable=false end) end
    if not clone then _vSet("using fallback...",_DIM);pcall(function() local hd=LP:GetHumanoidDescription();clone=PS:CreateHumanoidModelFromDescription(hd,Enum.HumanoidRigType.R15) end);if not clone then _vSet("clone failed",_RED2);return end end
    for _,d in ipairs(clone:GetDescendants()) do if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() elseif d:IsA("BasePart") then d.Anchored=false;d.CanCollide=false;d.CastShadow=false end end
    local root=clone:FindFirstChild("HumanoidRootPart");if root then root.Anchored=true;root.CFrame=CFrame.new(0,0,0) end
    clone.Parent=_vpW;_V.model=clone
    local hum=clone:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop(0) end end);pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Running,false) end);pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false) end) end
    local a8=hum and (hum:FindFirstChildOfClass("Animator") or _ni("Animator",{},hum)) or (function() local ctrl=clone:FindFirstChildWhichIsA("AnimationController",true) or _ni("AnimationController",{},clone);return ctrl:FindFirstChildOfClass("Animator") or _ni("Animator",{},ctrl) end)()
    _V.anim8r=a8
    local cam=_ni("Camera",{Parent=_vp});_vp.CurrentCamera=cam;_V.cam=cam
    if root then local ox=math.sin(_V.rotY)*7.5;local oz=math.cos(_V.rotY)*7.5;cam.CFrame=CFrame.new(root.Position+Vector3.new(ox,2.5,oz),root.Position+Vector3.new(0,1.5,0)) end
    local animObj=_ni("Animation",{AnimationId=animId});local track;local ok,err=pcall(function() track=a8:LoadAnimation(animObj) end)
    if not ok or not track then animObj:Destroy();_vSet("load failed: "..(err or "?"),_RED2);return end
    _V.animObj=animObj;_V.track=track;track.Looped=_V.loop;track:Play(0.1,1,_V.speed);_V.paused=false
    _bPlay.Text="||";_bPlay.TextColor3=Color3.fromRGB(200,100,255);_vpH.Visible=false
    task.spawn(function()
        local t0=os.clock();repeat task.wait(0.05) until (_V.track and _V.track.Length>0) or (os.clock()-t0>0.5)
        if _V.track then _V.length=_V.track.Length;local num=animId:match("(%d+)$") or "?";_vSet("playing  rbxassetid://"..num,_CY);_iLbl.Text=string.format("id: %s   len: %.3fs",num,_V.length) end
    end)
    _V.hb=RS.Heartbeat:Connect(function()
        if not _V.track then return end
        if _V.track.Length>0 and _V.length~=_V.track.Length then _V.length=_V.track.Length end
        local tp=_V.track.TimePosition;local len=math.max(_V.length,0.001)
        _tlF.Size=UDim2.new(math.clamp(tp/len,0,1),0,1,0);_tLbl.Text=string.format("%.3f / %.3f  (%dms)",tp,len,math.floor(tp*1000))
        if _V.cam and _V.model then local r2=_V.model:FindFirstChild("HumanoidRootPart");if r2 then local ox=math.sin(_V.rotY)*7.5;local oz=math.cos(_V.rotY)*7.5;_V.cam.CFrame=CFrame.new(r2.Position+Vector3.new(ox,2.5,oz),r2.Position+Vector3.new(0,1.5,0)) end end
    end)
end

local _vpDrag=false;local _vpLX=0
_vp.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _vpDrag=true;_vpLX=i.Position.X end end)
UIS.InputChanged:Connect(function(i) if _vpDrag and i.UserInputType==Enum.UserInputType.MouseMovement then local dx=i.Position.X-_vpLX;_vpLX=i.Position.X;_V.rotY=_V.rotY+dx*0.012 end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then _vpDrag=false end end)

local _scr=false;local _scrWP=false
local function _scrSeek(x)
    if not _V.track or _V.length<=0 then return end
    local a=_tlBg.AbsolutePosition;local s=_tlBg.AbsoluteSize;local t=math.clamp((x-a.X)/s.X,0,1)*_V.length
    if not _V.track.IsPlaying then _V.track:Play(0,1,0) end;_V.track:AdjustSpeed(0);_V.track.TimePosition=t
end
_tlH.MouseButton1Down:Connect(function() if not _V.track or _V.length<=0 then return end;_scr=true;_scrWP=_V.paused;_V.paused=true;_scrSeek(UIS:GetMouseLocation().X) end)
UIS.InputChanged:Connect(function(i) if _scr and i.UserInputType==Enum.UserInputType.MouseMovement then _scrSeek(i.Position.X) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 and _scr then _scr=false;if not _scrWP and _V.track then _V.track:AdjustSpeed(_V.speed);_V.paused=false;_bPlay.Text="||";_bPlay.TextColor3=Color3.fromRGB(200,100,255);_vSet("playing",_CY) end end end)
_bPlay.MouseButton1Click:Connect(function() if not _V.track then local id=_idBox.Text;if id==""then _vSet("enter an id first",_DIM)return end;if not id:find("rbxassetid://")then id="rbxassetid://"..id end;_vLoad(id)return end;if _V.paused then _V.track:AdjustSpeed(_V.speed);_V.paused=false;_bPlay.Text="||";_bPlay.TextColor3=Color3.fromRGB(200,100,255);_vSet("playing",_CY) else _V.track:AdjustSpeed(0);_V.paused=true;_bPlay.Text="P";_bPlay.TextColor3=_CY;_vSet("paused",_DIM) end end)
_bRestart.MouseButton1Click:Connect(function() if _V.track then _V.track.TimePosition=0;if _V.paused then _V.track:AdjustSpeed(_V.speed);_V.paused=false;_bPlay.Text="||";_bPlay.TextColor3=Color3.fromRGB(200,100,255) end;_vSet("playing",_CY) end end)
_bStop.MouseButton1Click:Connect(function() _vClean() end)
_loopB.MouseButton1Click:Connect(function() _V.loop=not _V.loop;_loopB.Text="loop: "..(_V.loop and "on" or "off");_loopB.TextColor3=_V.loop and _CY or _DIM;if _V.track then _V.track.Looped=_V.loop end end)
_spdB.MouseButton1Click:Connect(function() _V.spIdx=(_V.spIdx%#_V.speeds)+1;_V.speed=_V.speeds[_V.spIdx];_spdB.Text=string.format("speed: %.2fx",_V.speed);if _V.track and not _V.paused then _V.track:AdjustSpeed(_V.speed) end end)
_idBox.FocusLost:Connect(function(enter) if enter and _idBox.Text~="" then local id=_idBox.Text;if not id:find("rbxassetid://")then id="rbxassetid://"..id end;_vLoad(id) end end)
_vXB.MouseButton1Click:Connect(function() _vW.Visible=false;_vClean();if Tog.ShowVisualizer then Tog.ShowVisualizer:SetValue(false) end end)
_visOpenWithId=function(id,entity) _vW.Visible=true;if Tog.ShowVisualizer then Tog.ShowVisualizer:SetValue(true) end;_idBox.Text=id;if not id:find("rbxassetid://")then id="rbxassetid://"..id end;_vLoad(id,entity) end

-- Linoria UI
local PBox=Tabs.Parry:AddLeftGroupbox("Auto Parry");local TBox=Tabs.Parry:AddLeftGroupbox("Timing Builder");local LBox=Tabs.Parry:AddRightGroupbox("Animation Logger")
PBox:AddToggle("AutoParry",{Text="Enable Auto Parry",Default=false}):AddKeyPicker("AutoParryKey",{Default="None",Text="Auto Parry",Mode="Toggle"})
PBox:AddToggle("ShowHitbox",{Text="Show Hitboxes",Default=false})
PBox:AddDivider()
PBox:AddToggle("FOVCheck",{Text="FOV Check",Default=false,Tooltip="Only parry if the enemy is facing you"})
PBox:AddToggle("ClosestOnly",{Text="Closest Enemy Only",Default=false})
PBox:AddToggle("HitboxDirCheck",{Text="Hitbox Direction Check",Default=false})

TBox:AddDropdown("SavedTimings",{Text="Saved Timings",Values={"--"},Default=1,Multi=false})
Opt.SavedTimings:OnChanged(function()
    local s=Opt.SavedTimings.Value;if not s or s=="--" then return end
    for _,e in ipairs(_savedTimings) do if e.name==s then Opt.TimingName:SetValue(e.name);Opt.AnimationID:SetValue(e.animId);Opt.DelayS:SetValue(tostring(math.floor(e.delay*1000)));Opt.MinDist:SetValue(e.minDist);Opt.MaxDist:SetValue(e.maxDist);Opt.Action:SetValue(e.action);break end end
end)
TBox:AddInput("TimingName",{Text="Name",Default="",Placeholder="e.g. monster m1"})
TBox:AddInput("AnimationID",{Text="Animation ID",Default="",Placeholder="rbxassetid://123456"})
TBox:AddInput("DelayS",{Text="Delay (ms)",Default="200",Placeholder="e.g. 350",Numeric=true})
TBox:AddSlider("MinDist",{Text="Min Distance",Min=0,Max=100,Default=0,Rounding=0})
TBox:AddSlider("MaxDist",{Text="Max Distance",Min=0,Max=200,Default=25,Rounding=0})
TBox:AddDropdown("Action",{Text="Action",Values={"Parry","Dodge","Block Start","Block End"},Default=1})
TBox:AddButton({Text="Preview in Visualizer",Func=function() local id=Opt.AnimationID.Value;if not id or id==""then Library:Notify("Enter Animation ID!",2)return end;if not id:find("rbxassetid://")then id="rbxassetid://"..id end;_visOpenWithId(id) end})
TBox:AddButton({Text="Save Timing",Func=function()
    local n=Opt.TimingName.Value;local a=Opt.AnimationID.Value;if n==""or a==""then Library:Notify("Fill Name & Animation ID!",3)return end
    for _,e in ipairs(_savedTimings) do if e.animId==a and e.name~=n then Library:Notify('Already saved as "'..e.name..'"',3)return end end
    if not a:find("rbxassetid://")then a="rbxassetid://"..a end;Opt.AnimationID:SetValue(a)
    for i=#_savedTimings,1,-1 do if _savedTimings[i].name==n then local aid=_savedTimings[i].animId;if _timings[aid] then for j,t in ipairs(_timings[aid]) do if t.name==n then table.remove(_timings[aid],j);break end end;if #_timings[aid]==0 then _timings[aid]=nil end end;table.remove(_savedTimings,i) end end
    local e={name=n,animId=a,delay=(tonumber(Opt.DelayS.Value) or 0)/1000,minDist=Opt.MinDist.Value,maxDist=Opt.MaxDist.Value,action=Opt.Action.Value}
    table.insert(_savedTimings,e);if not _timings[a] then _timings[a]={} end;table.insert(_timings[a],e)
    local ns={};for _,x in ipairs(_savedTimings) do table.insert(ns,x.name) end;Opt.SavedTimings:SetValues(ns);Opt.SavedTimings:SetValue(n);_saveDisk();Library:Notify("Saved: "..n,2)
end})
TBox:AddButton({Text="Delete Selected",Func=function()
    local s=Opt.SavedTimings.Value;if not s or s=="--" then return end
    for i,e in ipairs(_savedTimings) do if e.name==s then if _timings[e.animId] then for j,t in ipairs(_timings[e.animId]) do if t.name==e.name then table.remove(_timings[e.animId],j);break end end;if #_timings[e.animId]==0 then _timings[e.animId]=nil end end;table.remove(_savedTimings,i);break end end
    local ns={};for _,e in ipairs(_savedTimings) do table.insert(ns,e.name) end;if#ns==0 then ns={"--"}end;Opt.SavedTimings:SetValues(ns);Opt.SavedTimings:SetValue(ns[1]);_saveDisk()
end})
TBox:AddButton({Text="Delete ALL",Func=function() _savedTimings={};_timings={};Opt.SavedTimings:SetValues({"--"});Opt.SavedTimings:SetValue("--");_saveDisk();Library:Notify("All deleted",2) end})
TBox:AddDivider()
TBox:AddButton({Text="Export (clipboard)",Func=function()
    local ls={};for _,e in ipairs(_savedTimings) do table.insert(ls,string.format('  ["%s"]={name="%s",delay=%.2f,minDist=%d,maxDist=%d,action="%s"}',e.animId,e.name,e.delay,e.minDist,e.maxDist,e.action)) end
    if setclipboard then setclipboard("local TIMINGS={\n"..table.concat(ls,",\n").."\n}") end;Library:Notify("Copied!",2)
end})

LBox:AddLabel("Logged Animations")
LBox:AddToggle("EnableLogger",{Text="Enable Logger",Default=false}):AddKeyPicker("LoggerKey",{Default="None",Text="Toggle Logger",Mode="Toggle"})
LBox:AddSlider("LogRadius",{Text="Log Radius (studs)",Min=5,Max=300,Default=100,Rounding=0,Suffix="m"})
LBox:AddDivider()
LBox:AddToggle("ShowVisualizer",{Text="Animation Visualizer",Default=false}):AddKeyPicker("VisualizerKey",{Default="None",Text="Toggle Visualizer",Mode="Toggle"})
Tog.EnableLogger:OnChanged(function() _lW.Visible=Tog.EnableLogger.Value end)
Tog.ShowVisualizer:OnChanged(function() _vW.Visible=Tog.ShowVisualizer.Value;if not Tog.ShowVisualizer.Value then _vClean() end end)

task.defer(_loadDisk)

-- Auto parry logic
local function _stL(c) return string.lower(tostring(c and c:GetAttribute("CurrentState") or "")) end
local function _rtt()
    local n=game:GetService("Stats"):FindFirstChild("Network");local s=n and n:FindFirstChild("ServerStatsItem");local d=s and s:FindFirstChild("Data Ping")
    return d and d:GetValue()/1000 or 0.05
end

local _UCS2=_Rem2 and _Rem2:WaitForChild("UpdateCharacterState",5)
local _CharState=getChar() and getChar():FindFirstChild("CharacterState")
LP.CharacterAdded:Connect(function(c) _CharState=c:FindFirstChild("CharacterState") end)

local _parryCD=false
local function _sBlock(st) pcall(function() if _UCS2 then _UCS2:FireServer("Blocking",st) end end) end
local function _sDodge()
    pcall(function() if _UCS2 then _UCS2:FireServer(nil,nil,true,"BoolValue","Dodge",true,0.2+_rtt()/2) end end)
    pcall(function() if _ReqMod then _ReqMod:FireServer("Misc","Dash","GroundBack",{DashCooldown=2}) end end)
end
local function _sParry()
    if _parryCD then return false end;_parryCD=true;task.delay(0.5,function() _parryCD=false end)
    pcall(function() if _ReqMod then _ReqMod:FireServer("Misc","Parry",nil) end end);return true
end
local function _cParry() return (os.clock()-_lastParry)>=0.12 and not _parryCD end
local function _cDodge()
    if (os.clock()-_lastDodge)<1.75 then return false end
    local c=LP.Character;if not c then return false end
    if _CharState and (_CharState:FindFirstChild("Stun") or _CharState:FindFirstChild("Knocked") or _CharState:FindFirstChild("Ragdoll")) then return false end
    return true
end
local function _doParry()
    if not Tog.AutoParry.Value then return end
    if _cParry() then if _sParry() then _lastParry=os.clock() end elseif _cDodge() then _sDodge();_lastDodge=os.clock() end
end
local function _distTo(root) local c=LP.Character;if not c then return nil end;local r=c:FindFirstChild("HumanoidRootPart");if not (r and root) then return nil end;return(r.Position-root.Position).Magnitude end

local function _doLog(id,src,dist,entityRef,animName)
    if not Tog.EnableLogger or not Tog.EnableLogger.Value then return end
    local numId=id:match("%?id=(%d+)") or id:match("rbxassetid://(%d+)") or id:match("^(%d+)$")
    if numId then id="rbxassetid://"..numId end
    if id==""or id=="rbxassetid://0" then return end
    local maxR=Opt.LogRadius and Opt.LogRadius.Value or 100;if dist and dist>maxR then return end
    local mk=id.."|"..(src or "");if _loggedMap[mk] then return end;_loggedMap[mk]=true
    local entry={id=id,source=src or "Unknown",dist=dist,entity=entityRef,animName=animName}
    table.insert(_loggedAnims,1,entry);if #_loggedAnims>120 then local old=table.remove(_loggedAnims);_loggedMap[(old.id or "").."|"..(old.source or "")]=nil end
    if _lW.Visible then _addLine(entry) end
end

local _Deb=game:GetService("Debris")
local function _vizHB(root,col)
    if not (Tog.ShowHitbox and Tog.ShowHitbox.Value) or not root then return end
    local p=Instance.new("Part");p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Material=Enum.Material.ForceField;p.Color=col or Color3.fromRGB(80,200,255);p.Transparency=0.35;p.Size=Vector3.new(6,6,8);p.CFrame=CFrame.new(root.Position+root.CFrame.LookVector*4);p.Parent=workspace;_Deb:AddItem(p,0.4)
    local h=Instance.new("SelectionBox");h.Adornee=root.Parent;h.Color3=col or Color3.fromRGB(80,200,255);h.LineThickness=0.04;h.SurfaceTransparency=0.9;h.SurfaceColor3=col or Color3.fromRGB(80,200,255);h.Parent=workspace;_Deb:AddItem(h,0.4)
end

RS.PreSimulation:Connect(function()
    for i=#_activeTriggers,1,-1 do
        local v=_activeTriggers[i]
        if os.clock()-(v.created or 0)>1 then table.remove(_activeTriggers,i)
        elseif not v.root or not v.root.Parent then table.remove(_activeTriggers,i)
        elseif not v.track.IsPlaying then
            if v.track.TimePosition<v.triggerTime and v.track.TimePosition>0 then
                table.remove(_activeTriggers,i)
                if Tog.AutoParry and Tog.AutoParry.Value then
                    if v.action=="Parry" then if _cParry() then if _sParry() then _lastParry=os.clock() end end
                    elseif v.action=="Block Start" then _sBlock(true);elseif v.action=="Block End" then _sBlock(false)
                    elseif v.action=="Dodge" then if _cDodge() then _sDodge();_lastDodge=os.clock() end end
                end
            else table.remove(_activeTriggers,i) end
        elseif v.track.TimePosition>=v.triggerTime then
            table.remove(_activeTriggers,i)
            local lD=_distTo(v.root)
            if lD and lD>=(v.minDist or 0) and lD<=(v.maxDist or 25) then
                local hc=v.action=="Parry" and Color3.fromRGB(80,200,255) or v.action=="Dodge" and Color3.fromRGB(255,200,80) or Color3.fromRGB(80,255,80)
                _vizHB(v.root,hc)
                if Tog.AutoParry and Tog.AutoParry.Value then
                    if v.action=="Parry" then if _cParry() then if _sParry() then _lastParry=os.clock() end end
                    elseif v.action=="Block Start" then _sBlock(true);elseif v.action=="Block End" then _sBlock(false)
                    elseif v.action=="Dodge" then if _cDodge() then _sDodge();_lastDodge=os.clock() end end
                end
            end
        end
    end
end)

local function _facing(root) local c=LP.Character;if not c then return false end;local r=c:FindFirstChild("HumanoidRootPart");if not r then return false end;return root.CFrame.LookVector:Dot((r.Position-root.Position).Unit)>0.7 end
local function _closest(root) local c=LP.Character;if not c then return true end;local r=c:FindFirstChild("HumanoidRootPart");if not r then return true end;local d=(r.Position-root.Position).Magnitude;for _,v in ipairs(workspace:GetChildren()) do if v:IsA("Model") and v~=c then local vr=v:FindFirstChild("HumanoidRootPart");local vh=v:FindFirstChildOfClass("Humanoid");if vr and vh and vh.Health>0 and (r.Position-vr.Position).Magnitude<d-1 then return false end end end;return true end
local function _inFront(root) local c=LP.Character;if not c then return false end;local r=c:FindFirstChild("HumanoidRootPart");if not r then return false end;return root.CFrame.LookVector:Dot((r.Position-root.Position).Unit)>0.6 end

local function _watchAnim(animator)
    if _watchedAnims[animator] then return end;_watchedAnims[animator]=true
    table.insert(_connections,animator.Destroying:Connect(function() _watchedAnims[animator]=nil end))
    local entity=animator:FindFirstAncestorWhichIsA("Model");local src=entity and entity.Name or "Unknown"
    table.insert(_connections,animator.AnimationPlayed:Connect(function(track)
        if entity and entity==LP.Character then return end
        if track.Length and track.Length<0.2 then return end
        local aid=tostring(track.Animation and track.Animation.AnimationId or "")
        local num=aid:match("%?id=(%d+)") or aid:match("rbxassetid://(%d+)") or aid:match("^(%d+)$")
        if num then aid="rbxassetid://"..num end
        if aid~="" then local root=entity and entity:FindFirstChild("HumanoidRootPart");local d=root and _distTo(root);task.defer(_doLog,aid,src,d,entity,track.Name~="" and track.Name or nil) end
        local tList=_timings[aid];if not tList then return end
        local root=entity and entity:FindFirstChild("HumanoidRootPart");if not root then return end
        local d=_distTo(root);if not d then return end
        if Tog.FOVCheck and Tog.FOVCheck.Value and not _facing(root) then return end
        if Tog.HitboxDirCheck and Tog.HitboxDirCheck.Value and not _inFront(root) then return end
        if Tog.ClosestOnly and Tog.ClosestOnly.Value and not _closest(root) then return end
        for _,t in ipairs(tList) do
            local minD=t.minDist or 0;local maxD=(t.maxDist and t.maxDist>0) and t.maxDist or 25
            if d>=minD and d<=maxD then
                local ck=aid..t.name..tostring(entity)
                if not _animCooldowns[ck] or os.clock()-_animCooldowns[ck]>=0.1 then
                    _animCooldowns[ck]=os.clock()
                    local vel=root.AssemblyLinearVelocity.Magnitude
                    local tTime=math.max((t.delay or 0)-_rtt()/2-math.clamp(vel/50,0,0.1),0)
                    if #_activeTriggers<100 then table.insert(_activeTriggers,{track=track,triggerTime=tTime,src=src,action=t.action or "Parry",root=root,minDist=minD,maxDist=maxD,created=os.clock()}) end
                end
            end
        end
    end))
end

local function _watchChar(char)
    if not char then return end
    table.insert(_connections,char:GetAttributeChangedSignal("CurrentState"):Connect(function()
        local s=_stL(char);local root=char:FindFirstChild("HumanoidRootPart");if not root then return end
        local d=_distTo(root);if not d or d>90 then return end
        if s:find("attack") or s:find("skill") or s:find("m1") or s:find("critical") or s:find("swing") or s:find("combo") or s:find("cast") or s:find("ability") then _doParry() end
    end))
    local vals=char:FindFirstChild("Values")
    if vals then table.insert(_connections,vals:GetAttributeChangedSignal("M1Active"):Connect(function()
        if vals:GetAttribute("M1Active")==true then local root=char:FindFirstChild("HumanoidRootPart");if not root then return end;local d=_distTo(root);if not d or d>90 then return end;_doParry() end
    end)) end
end
local function _watchPlr(p)
    if p==LP then return end
    local function onChar(c) task.wait();_watchChar(c);for _,d in next,c:GetDescendants() do if d:IsA("Animator") then _watchAnim(d) end end end
    if p.Character then onChar(p.Character) end;table.insert(_connections,p.CharacterAdded:Connect(onChar))
end

table.insert(_connections,workspace.DescendantAdded:Connect(function(d)
    if d:IsA("Animator") then _watchAnim(d)
    elseif d:IsA("AnimationController") then local a=d:FindFirstChildOfClass("Animator");if a then _watchAnim(a) end;table.insert(_connections,d.ChildAdded:Connect(function(c) if c:IsA("Animator") then _watchAnim(c) end end)) end
end))

local function _fullScan() for _,d in next,workspace:GetDescendants() do if d:IsA("Animator") then _watchAnim(d) elseif d:IsA("AnimationController") then local a=d:FindFirstChildOfClass("Animator");if a then _watchAnim(a) end end end end
_fullScan();task.delay(3,_fullScan)
for _,p in next,PS:GetPlayers() do _watchPlr(p) end
table.insert(_connections,PS.PlayerAdded:Connect(_watchPlr))

Library:OnUnload(function()
    _vClean()
    for _,c in ipairs(_connections) do pcall(function() c:Disconnect() end) end
    _connections={}; pcall(function() _sg:Destroy() end)
end)

end -- AUTO PARRY SCOPE

-- ══════════════════════════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ══════════════════════════════════════════════════════════════════════════════
ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetFolder("XesHub"); ThemeManager:ApplyTheme("Jester")
SaveManager:SetFolder("XesHub/configs")

local UILeft=Tabs.UI:AddLeftGroupbox("Menu"); local UIRight=Tabs.UI:AddRightGroupbox("Appearance")
UILeft:AddLabel("── Keybind ──")
local menuKB=UILeft:AddLabel("Toggle Menu"):AddKeyPicker("MenuKeybind", { Default="RightShift", NoUI=false, Text="Toggle Menu", Callback=function() Library:Toggle() end })
Library.ToggleKeybind=menuKB
UILeft:AddLabel("── Interface ──")
UILeft:AddToggle("ShowKeybinds", { Text="Keybinds Panel", Default=true, Callback=function(p) if Library.KeybindFrame then Library.KeybindFrame.Visible=p end end })
UILeft:AddButton("Unload Script", function() Library:Unload() end)

local streamConn=nil
UILeft:AddToggle("StreamableMode", { Text="Streamable Mode", Default=false,
    Callback=function(p)
        if streamConn then streamConn:Disconnect(); streamConn=nil end
        if not p then return end
        local PGui=LP.PlayerGui
        for _,v in pairs(PGui:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then pcall(function() v.Text="discord.gg/vanthub" end) end
        end
        streamConn=PGui.DescendantAdded:Connect(function(v)
            if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then pcall(function() v.Text="discord.gg/vanthub" end) end
        end)
    end,
})

ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:BuildConfigSection(Tabs.UI)
SaveManager:LoadAutoloadConfig()

Library:Notify("XES Hub Loaded!", 5)
