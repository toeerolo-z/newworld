-- Zero Hub | Criminality
-- EthosSuite UI — all Criminality features wired in
-- Every section scoped in do...end to stay under the 200 local register limit
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/toeerolo-z/ethossuiterewrite/refs/heads/main/ethossuite.lua"))()

local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local UIS              = game:GetService("UserInputService")
local RS               = game:GetService("ReplicatedStorage")
local Lighting         = game:GetService("Lighting")
local SoundService     = game:GetService("SoundService")
local StarterGui       = game:GetService("StarterGui")
local GuiService       = game:GetService("GuiService")
local LP               = Players.LocalPlayer
local Cam              = workspace.CurrentCamera

-- Shared cross-section state
local S = {}
getgenv().ZH_CRIM = S

S.charStats = function(name)
    local cs = RS:FindFirstChild("CharStats"); return cs and cs:FindFirstChild(name) or nil
end
S.setv = function(parent, name, value)
    if not parent then return end
    local o = parent:FindFirstChild(name); if o and o.Value ~= value then o.Value = value end
end
S.notify = function(title, text)
    pcall(function() StarterGui:SetCore("SendNotification", { Title = title, Text = tostring(text), Duration = 4 }) end)
end
S.isGunTool = function(tool)
    if not tool then return false end
    local cfg = tool:FindFirstChild("Config")
    if not (cfg and cfg:IsA("ModuleScript")) then return false end
    local ok, c = pcall(require, cfg)
    local gun = ok and type(c) == "table" and (c.BulletsPerShot ~= nil or c.StoredAmmo ~= nil)
    if gun then
        local bs = type(c.BulletSettings) == "table" and c.BulletSettings
        if S.aim then S.aim.bulletVel = (bs and tonumber(bs.Velocity)) or 0 end
    end
    return gun
end
S.isDowned = function(plr, char)
    local s = S.charStats(plr.Name or (typeof(plr) == "Instance" and plr.Name) or "")
    if s then
        local d = s:FindFirstChild("Downed") or s:FindFirstChild("SRagdolled")
        if d and d:IsA("BoolValue") and d.Value then return true end
        local rt = s:FindFirstChild("RagdollTime")
        if rt then local sr = rt:FindFirstChild("SRagdolled"); if sr and sr.Value == true then return true end end
    end
    return false
end

------------------------------------------------------------
-- WINDOW + TABS
------------------------------------------------------------
local Window = Library:CreateWindow({ Title = "ZERO HUB", Version = "v1.0.0" })

local CatMain    = Window:AddCategory("MAIN")
local CatVisuals = Window:AddCategory("VISUALS")
local CatMisc    = Window:AddCategory("MISC")

local CombatTab  = CatMain:AddTab("Combat")
local GunModTab  = CatMain:AddTab("Gun Mods")
local AntiTab    = CatMain:AddTab("Anti-Effects")
local PEspTab    = CatVisuals:AddTab("Player ESP")
local OEspTab    = CatVisuals:AddTab("Object ESP")
local WorldTab   = CatVisuals:AddTab("World")
local MoveTab    = CatMisc:AddTab("Movement")
local AutoTab    = CatMisc:AddTab("Automation")
local MeleeTab   = CatMisc:AddTab("Melee")
local BankTab    = CatMisc:AddTab("Banking & Shop")
local UtilTab    = CatMisc:AddTab("Utility")

------------------------------------------------------------
-- TARGET SELECTION
------------------------------------------------------------
do
    local TargetBox = CombatTab:AddGroupbox("Target Selection")

    local T = {
        ShowFOV = false, FOV = 120, TargetClosest = true, MaxRange = 0,
        BodyPart = "Head", VisibilityCheck = false, TeamCheck = false,
        IgnoreDowned = true, IgnoreForcefield = true,
        FOVColor = Color3.fromRGB(255, 255, 255), Current = nil,
    }
    S.tgt = T

    local fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1; fovCircle.NumSides = 48; fovCircle.Filled = false
    fovCircle.Color = T.FOVColor; fovCircle.Visible = false

    local function hasForcefield(char) return char:FindFirstChildOfClass("ForceField") ~= nil end

    local function tgtVisible(cam, char, part)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { LP.Character, cam }
        local origin = cam.CFrame.Position
        local dir = part.Position - origin
        local res = workspace:Raycast(origin, dir, params)
        if not res then return true end
        return res.Instance:IsDescendantOf(char)
    end

    function T.get()
        local cam = workspace.CurrentCamera; if not cam then return nil end
        local myChar = LP.Character; local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local center = cam.ViewportSize / 2
        local best, bestScore = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local char = plr.Character; local part = char and char:FindFirstChild(T.BodyPart)
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if char and part and hum and hum.Health > 0 then
                    local skip = false
                    if T.IgnoreDowned and S.isDowned(plr, char) then skip = true end
                    if not skip and T.IgnoreForcefield and hasForcefield(char) then skip = true end
                    if not skip and T.MaxRange > 0 and myHrp then
                        if (myHrp.Position - part.Position).Magnitude > T.MaxRange then skip = true end
                    end
                    if not skip then
                        local sp, on = cam:WorldToViewportPoint(part.Position)
                        if on then
                            local d2 = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if d2 <= T.FOV then
                                if not (T.VisibilityCheck and not tgtVisible(cam, char, part)) then
                                    local score = T.TargetClosest and d2 or (myHrp and (myHrp.Position - part.Position).Magnitude or d2)
                                    if score < bestScore then bestScore = score; best = { player = plr, part = part, pos = part.Position, char = char } end
                                end
                            end
                        end
                    end
                end
            end
        end
        T.Current = best; return best
    end

    RunService.RenderStepped:Connect(function()
        pcall(function()
            local cam = workspace.CurrentCamera
            if T.ShowFOV and cam then
                fovCircle.Position = cam.ViewportSize / 2; fovCircle.Radius = T.FOV
                fovCircle.Color = T.FOVColor; fovCircle.Visible = true
            else fovCircle.Visible = false end
            T.get()
        end)
    end)

    TargetBox:AddToggle("ShowFOV", { Text = "Show FOV Circle", Default = false, Callback = function(v) T.ShowFOV = v end })
    TargetBox:AddSlider("FOVSize", { Text = "FOV (px)", Default = 120, Min = 10, Max = 800, Decimals = 0, Callback = function(v) T.FOV = v end })
    TargetBox:AddToggle("VisCheck", { Text = "Visibility Check", Default = false, Description = "Only target visible players", Callback = function(v) T.VisibilityCheck = v end })
    TargetBox:AddToggle("IgnoreDowned", { Text = "Ignore Downed", Default = true, Callback = function(v) T.IgnoreDowned = v end })
    TargetBox:AddToggle("IgnoreFF", { Text = "Ignore Forcefield", Default = true, Callback = function(v) T.IgnoreForcefield = v end })
    TargetBox:AddToggle("TargetClosest", { Text = "Target Closest to Crosshair", Default = true, Callback = function(v) T.TargetClosest = v end })
    TargetBox:AddSlider("MaxRange", { Text = "Max Range (0=inf)", Default = 0, Min = 0, Max = 2000, Decimals = 0, Callback = function(v) T.MaxRange = v end })
    TargetBox:AddDropdown("BodyPart", { Text = "Body Part", Default = "Head", Values = {"Head","Torso","HumanoidRootPart","Left Arm","Right Arm","Left Leg","Right Leg"}, Callback = function(v) T.BodyPart = v end })
    TargetBox:AddColorPicker("FOVColor", { Text = "FOV Color", Default = Color3.fromRGB(255,255,255), Callback = function(c) T.FOVColor = c end })
end

------------------------------------------------------------
-- SILENT AIM + HIT EFFECTS
------------------------------------------------------------
do
    local AimBox = CombatTab:AddGroupbox("Silent Aim")
    local HitBox = CombatTab:AddGroupbox("Hit Effects")

    local A = {
        enabled = false, NoSpread = false, AlwaysHead = false, Predict = false,
        Wallbang = false, bulletVel = 0, FiringOnly = true, HitChance = 100,
        Snapline = false, SnaplineFrom = "crosshair", gunEquipped = false,
        forcedTarget = nil, redirects = 0, hooked = false,
        SnaplineColor = Color3.fromRGB(255, 255, 255),
    }
    S.aim = A

    local gameGMP
    pcall(function()
        for _, o in ipairs(getgc(true)) do
            if type(o) == "table" and type(rawget(o, "GVF")) == "function"
                and type(rawget(o, "GetMousePoint")) == "function" then
                gameGMP = rawget(o, "GetMousePoint"); break
            end
        end
    end)

    local function refreshGun()
        local char = LP.Character
        A.gunEquipped = S.isGunTool(char and char:FindFirstChildOfClass("Tool"))
    end
    local charConns = {}
    local function watchChar(char)
        for _, c in ipairs(charConns) do pcall(function() c:Disconnect() end) end; charConns = {}
        refreshGun()
        charConns[#charConns+1] = char.ChildAdded:Connect(function() task.wait(); refreshGun() end)
        charConns[#charConns+1] = char.ChildRemoved:Connect(function() task.wait(); refreshGun() end)
    end
    if LP.Character then watchChar(LP.Character) end
    LP.CharacterAdded:Connect(watchChar)

    local function currentTarget()
        local T = S.tgt; return (T and T.get and T.get()) or (T and T.Current)
    end
    local function firing()
        if not A.FiringOnly then return true end
        return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    end

    -- Hit Effects
    local HF = { HitSound = false, HitNotify = false, Tracers = false, Volume = 2,
        TracerLife = 0.35, TracerColor = Color3.fromRGB(180, 140, 255), shots = 0, hits = 0 }
    getgenv().CRIM_HITFX = HF

    local hitSnd = Instance.new("Sound")
    hitSnd.SoundId = "rbxasset://sounds/electronicpingshort.wav"; hitSnd.Volume = HF.Volume; hitSnd.Parent = SoundService

    local MAXTR = 16; local trLines, trData = {}, {}
    for i = 1, MAXTR do local l = Drawing.new("Line"); l.Thickness = 1.5; l.Visible = false; trLines[i] = l end
    local trNext = 1
    local hitNote = Drawing.new("Text"); hitNote.Size = 18; hitNote.Center = true; hitNote.Outline = true; hitNote.Visible = false
    local noteUntil = 0

    local function charOf(part)
        local m = part and part.Parent
        for _ = 1, 3 do
            if not m or m == workspace or m == game then return nil end
            if m:FindFirstChildOfClass("Humanoid") then return m end; m = m.Parent
        end; return nil
    end

    function HF.onShot(origin, hitPart, hitPos)
        HF.shots += 1
        if HF.Tracers and typeof(origin) == "Vector3" and typeof(hitPos) == "Vector3" then
            trData[trNext] = { a = origin, b = hitPos, t0 = os.clock() }; trNext = trNext % MAXTR + 1
        end
        if not (HF.HitSound or HF.HitNotify) then return end
        if typeof(hitPart) ~= "Instance" then return end
        local char = charOf(hitPart)
        if not char or char == LP.Character then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        HF.hits += 1
        local head = (hitPart.Name == "Head")
        if HF.HitSound then hitSnd.Volume = HF.Volume; hitSnd.PlaybackSpeed = head and 1.35 or 1; pcall(hitSnd.Play, hitSnd) end
        if HF.HitNotify then
            local pl = Players:GetPlayerFromCharacter(char)
            hitNote.Text = ("HIT  %s  [%s]"):format(pl and pl.Name or char.Name, hitPart.Name)
            hitNote.Color = head and Color3.fromRGB(255, 120, 60) or Color3.fromRGB(235, 235, 235)
            noteUntil = os.clock() + 0.9
        end
    end

    RunService.RenderStepped:Connect(function()
        local now = os.clock(); local cam = workspace.CurrentCamera
        for i = 1, MAXTR do
            local d, l = trData[i], trLines[i]
            if d and cam then
                local age = now - d.t0
                if age > HF.TracerLife or not HF.Tracers then trData[i] = nil; l.Visible = false
                else
                    local p1 = cam:WorldToViewportPoint(d.a); local p2, on2 = cam:WorldToViewportPoint(d.b)
                    if on2 or p1.Z > 0 then
                        l.From = Vector2.new(p1.X, p1.Y); l.To = Vector2.new(p2.X, p2.Y)
                        l.Color = HF.TracerColor; l.Transparency = 1 - (age / HF.TracerLife); l.Visible = true
                    else l.Visible = false end
                end
            elseif l.Visible then l.Visible = false end
        end
        if noteUntil > 0 then
            if now >= noteUntil or not HF.HitNotify then noteUntil = 0; hitNote.Visible = false
            elseif cam then
                hitNote.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2 + 46)
                hitNote.Transparency = math.clamp((noteUntil - now) / 0.35, 0, 1); hitNote.Visible = true
            end
        end
    end)

    -- Hook RayHandler.CastRay
    local RH = require(RS.NewModules.Shared.Services.RayHandler)
    local origCast

    local function aimWrapper(ray, filter, opts, u17)
        local gunRay = A.gunEquipped and typeof(ray) == "Ray"
            and type(opts) == "table" and opts.type == "g" and firing()
        if gunRay and (A.enabled or A.NoSpread) then
            pcall(function()
                local origin = ray.Origin; local aimPoint, fromTarget
                if A.enabled or A.forcedTarget then
                    local tgt = A.forcedTarget or currentTarget()
                    if tgt and tgt.pos and (A.HitChance >= 100 or math.random(1, 100) <= A.HitChance) then
                        aimPoint = tgt.pos; fromTarget = true
                        local ch = tgt.player and tgt.player.Character
                        if A.AlwaysHead and ch then local head = ch:FindFirstChild("Head"); if head then aimPoint = head.Position end end
                        if A.Predict and ch and A.bulletVel > 100 then
                            local rp = ch:FindFirstChild("HumanoidRootPart")
                            if rp then aimPoint = aimPoint + rp.AssemblyLinearVelocity * ((aimPoint - origin).Magnitude / A.bulletVel) end
                        end
                    end
                end
                if not aimPoint and A.NoSpread and gameGMP then aimPoint = gameGMP() end
                if aimPoint then
                    if fromTarget and A.Wallbang and type(filter) == "table" then
                        local map = workspace:FindFirstChild("Map"); if map then filter[#filter + 1] = map end
                    end
                    local toAim = aimPoint - origin
                    if toAim.Magnitude > 0 then ray = Ray.new(origin, toAim); A.redirects += 1 end
                end
            end)
        end
        local hitfx = getgenv().CRIM_HITFX
        if gunRay and hitfx and (hitfx.HitSound or hitfx.HitNotify or hitfx.Tracers) then
            local r = table.pack(origCast(ray, filter, opts, u17))
            pcall(hitfx.onShot, ray.Origin, r[1], r[2])
            return table.unpack(r, 1, r.n)
        end
        return origCast(ray, filter, opts, u17)
    end

    if type(hookfunction) == "function" and type(RH) == "table" and type(RH.CastRay) == "function" then
        local ok, orig = pcall(hookfunction, RH.CastRay, aimWrapper)
        if ok and orig then origCast = orig; A.hooked = true end
    end

    -- Snapline
    local snapLine = Drawing.new("Line"); snapLine.Thickness = 1; snapLine.Visible = false
    RunService.RenderStepped:Connect(function()
        pcall(function()
            if (A.enabled or A.forcedTarget) and A.Snapline and A.gunEquipped then
                local tgt = A.forcedTarget or currentTarget(); local cam = workspace.CurrentCamera
                if tgt and tgt.pos and cam then
                    local sp, on = cam:WorldToViewportPoint(tgt.pos)
                    if on then
                        local vp = cam.ViewportSize; local from
                        if A.SnaplineFrom == "center" then from = vp / 2
                        elseif A.SnaplineFrom == "bottom" then from = Vector2.new(vp.X / 2, vp.Y)
                        else
                            if gameGMP then local aim = gameGMP(); local ap = cam:WorldToViewportPoint(aim); from = Vector2.new(ap.X, ap.Y)
                            else local m = UIS:GetMouseLocation(); local ins = GuiService:GetGuiInset(); from = Vector2.new(m.X - ins.X, m.Y - ins.Y) end
                        end
                        snapLine.From = from; snapLine.To = Vector2.new(sp.X, sp.Y); snapLine.Color = A.SnaplineColor; snapLine.Visible = true; return
                    end
                end
            end
            snapLine.Visible = false
        end)
    end)

    -- UI
    AimBox:AddToggle("SilentAim", { Text = "Silent Aim", Default = false, Description = "Redirects bullet rays to the selected target", Callback = function(v) A.enabled = v end })
    AimBox:AddToggle("AimNoSpread", { Text = "No Spread (Aim)", Default = false, Callback = function(v) A.NoSpread = v end })
    AimBox:AddToggle("AlwaysHead", { Text = "Always Head", Default = false, Callback = function(v) A.AlwaysHead = v end })
    AimBox:AddToggle("Predict", { Text = "Prediction", Default = false, Callback = function(v) A.Predict = v end })
    AimBox:AddToggle("Wallbang", { Text = "Wallbang", Default = false, Callback = function(v) A.Wallbang = v end })
    AimBox:AddToggle("FiringOnly", { Text = "Firing Only", Default = true, Callback = function(v) A.FiringOnly = v end })
    AimBox:AddSlider("HitChance", { Text = "Hit Chance (%)", Default = 100, Min = 1, Max = 100, Decimals = 0, Callback = function(v) A.HitChance = v end })
    AimBox:AddToggle("Snapline", { Text = "Snapline", Default = false, Callback = function(v) A.Snapline = v end })
    AimBox:AddDropdown("SnapFrom", { Text = "Snapline Origin", Default = "crosshair", Values = {"crosshair","center","bottom"}, Callback = function(v) A.SnaplineFrom = v end })
    AimBox:AddColorPicker("SnapColor", { Text = "Snapline Color", Default = Color3.fromRGB(255,255,255), Callback = function(c) A.SnaplineColor = c end })

    HitBox:AddToggle("HitSound", { Text = "Hit Sound", Default = false, Callback = function(v) HF.HitSound = v end })
    HitBox:AddToggle("HitNotify", { Text = "Hit Notification", Default = false, Callback = function(v) HF.HitNotify = v end })
    HitBox:AddToggle("BulletTracers", { Text = "Bullet Tracers", Default = false, Callback = function(v) HF.Tracers = v end })
    HitBox:AddSlider("HitVolume", { Text = "Hit Volume", Default = 2, Min = 0, Max = 10, Decimals = 1, Callback = function(v) HF.Volume = v end })
    HitBox:AddSlider("TracerLife", { Text = "Tracer Lifetime", Default = 0.35, Min = 0.1, Max = 2, Decimals = 2, Callback = function(v) HF.TracerLife = v end })
    HitBox:AddColorPicker("TracerColor", { Text = "Tracer Color", Default = Color3.fromRGB(180,140,255), Callback = function(c) HF.TracerColor = c end })
end

------------------------------------------------------------
-- RAGEBOT
------------------------------------------------------------
do
    local RageBox = CombatTab:AddGroupbox("Ragebot")
    local R = { enabled = false, range = 350, needsGun = true, bodyPart = "Head", pulseDelay = 0.07, fires = 0 }
    local holding = false; local lastPulse = 0; local lastGunSeen = 0

    local function press()
        if holding then return end; holding = true; R.fires += 1
        if type(mouse1press) == "function" then pcall(mouse1press)
        elseif type(mouse1click) == "function" then pcall(mouse1click); holding = false end
    end
    local function release()
        if not holding then return end; holding = false
        if type(mouse1release) == "function" then pcall(mouse1release) end
    end
    local function pulse()
        local now = tick(); if now - lastPulse < (R.pulseDelay or 0.07) then return end; lastPulse = now
        if holding then release() end; R.fires += 1
        if type(mouse1click) == "function" then pcall(mouse1click)
        elseif type(mouse1press) == "function" and type(mouse1release) == "function" then pcall(mouse1press); task.wait(0.01); pcall(mouse1release) end
    end

    local function isAutoFire(tool)
        if not tool then return false end
        local cfg = tool:FindFirstChild("Config")
        if cfg and cfg:IsA("ModuleScript") then
            local ok, c = pcall(require, cfg)
            if ok and type(c) == "table" then
                local fm = (type(c.FireModeSettings) == "table" and c.FireModeSettings.FireMode) or c.FireMode
                if fm then return tostring(fm):lower():find("auto") ~= nil end
            end
        end; return false
    end
    local function gunEquipped()
        local c = LP.Character
        if S.isGunTool(c and c:FindFirstChildOfClass("Tool")) then return true end
        return S.aim and S.aim.gunEquipped == true
    end
    local function currentAmmo(tool)
        if not tool then return nil end
        for _, container in ipairs({ tool:FindFirstChild("Values"), tool }) do
            if container then for _, v in ipairs(container:GetChildren()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    local n = v.Name:lower()
                    if n == "ammo" or n == "mag" or n:find("ammo") or n:find("mag") or n:find("bullet") or n:find("clip") or n:find("rounds") then return v.Value end
                end
            end end
        end; return nil
    end
    local function canSee(part, char)
        local T = S.tgt; if not (T and T.VisibilityCheck) then return true end
        local cam = workspace.CurrentCamera; if not cam then return true end
        local p = RaycastParams.new(); p.FilterType = Enum.RaycastFilterType.Exclude; p.FilterDescendantsInstances = { LP.Character, cam }
        local res = workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, p)
        return (not res) or res.Instance:IsDescendantOf(char)
    end
    local function findClosest()
        local myChar = LP.Character; local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart"); if not myHrp then return nil end
        local chars = workspace:FindFirstChild("Characters"); if not chars then return nil end
        local best, bestD = nil, R.range
        for _, m in ipairs(chars:GetChildren()) do
            if m:IsA("Model") and m.Name ~= LP.Name then
                local hum = m:FindFirstChildOfClass("Humanoid"); local part = m:FindFirstChild(R.bodyPart) or m:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and part and not S.isDowned(m, m) then
                    local d = (myHrp.Position - part.Position).Magnitude
                    if d < bestD and canSee(part, m) then bestD = d; best = { player = Players:GetPlayerFromCharacter(m) or { Name = m.Name }, part = part, pos = part.Position, char = m } end
                end
            end
        end; return best
    end
    local function clearAim() if S.aim then S.aim.forcedTarget = nil end end

    RunService.Heartbeat:Connect(function()
        local now = tick()
        if not R.enabled then release(); clearAim(); return end
        if R.needsGun then
            if gunEquipped() then lastGunSeen = now elseif now - lastGunSeen > 0.3 then release(); clearAim(); return end
        end
        local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
        local ammo = currentAmmo(tool)
        if ammo ~= nil and ammo <= 0 then release(); clearAim(); return end
        local tgt = findClosest()
        if tgt and S.aim then
            S.aim.forcedTarget = tgt; S.aim.gunEquipped = true
            if isAutoFire(tool) then press() else pulse() end
        else release(); clearAim() end
    end)

    RageBox:AddToggle("Ragebot", { Text = "Ragebot", Default = false, Description = "Auto-aims and auto-fires at closest enemy", Callback = function(v) R.enabled = v; if not v then release(); clearAim() end end })
    RageBox:AddSlider("RageRange", { Text = "Range (studs)", Default = 350, Min = 10, Max = 2000, Decimals = 0, Callback = function(v) R.range = v end })
    RageBox:AddToggle("RageNeedsGun", { Text = "Require Gun", Default = true, Callback = function(v) R.needsGun = v end })
    RageBox:AddSlider("RagePulseDelay", { Text = "Pulse Delay (s)", Default = 0.07, Min = 0.01, Max = 0.5, Decimals = 2, Callback = function(v) R.pulseDelay = v end })
    RageBox:AddDropdown("RageBodyPart", { Text = "Body Part", Default = "Head", Values = {"Head","Torso","HumanoidRootPart"}, Callback = function(v) R.bodyPart = v end })
end

------------------------------------------------------------
-- GUN MODS + AUTO RELOAD
------------------------------------------------------------
do
    local GunBox = GunModTab:AddGroupbox("Gun Mods")
    local ReloadBox = GunModTab:AddGroupbox("Auto Reload")

    local G = {
        NoRecoil = false, NoSpread = false, PerfectAccuracy = false, NoBulletDrop = false,
        RapidFire = false, RapidFireMult = 2, ForceFireMode = false, FireMode = "Auto",
        InstantEquip = false, InstantHit = false, calls = 0, hooked = false,
    }

    local DeepCopy       = require(RS.NewModules.Shared.Extensions.DeepCopy)
    local GetConfigAddon = require(RS.NewModules.Shared.Extensions.GetConfigAddon)
    local GC_Func        = require(RS.NewModules.Shared.Extensions.GetConfig)

    local function anyOn()
        return G.NoRecoil or G.NoSpread or G.PerfectAccuracy or G.NoBulletDrop
            or G.RapidFire or G.ForceFireMode or G.InstantEquip or G.InstantHit
    end
    local function isGunConfig(cfg)
        return type(cfg) == "table" and (cfg.FireModeSettings ~= nil or cfg.BulletSettings ~= nil
            or cfg.Recoil ~= nil or cfg.Spread ~= nil or cfg.FireRate ~= nil and cfg.Accuracy ~= nil)
    end
    local function modify(cfg)
        if type(cfg) ~= "table" or not anyOn() or not isGunConfig(cfg) then return end
        pcall(function()
            if G.NoRecoil then
                cfg.Recoil = 0; cfg.AngleX_Min = 0; cfg.AngleX_Max = 0; cfg.AngleY_Min = 0; cfg.AngleY_Max = 0
                cfg.AngleZ_Min = 0; cfg.AngleZ_Max = 0; cfg.CameraRecoilingEnabled = false
                if type(cfg.SprayLerp) == "table" then cfg.SprayLerp.AngleX = 0; cfg.SprayLerp.AngleY = 0; cfg.SprayLerp.AngleZ = 0; cfg.SprayLerp.AngleY2 = 0 end
            end
            if G.NoSpread or G.PerfectAccuracy then cfg.Spread = 0; cfg.Accuracy = 0; cfg.WalkSpreadIncrease = 1; cfg.CrouchSpreadReduction = 1 end
            if G.NoBulletDrop and type(cfg.BulletSettings) == "table" then cfg.BulletSettings.Acceleration = Vector3.new(0, 0, 0) end
            if G.RapidFire and type(cfg.FireRate) == "number" then cfg.FireRate = cfg.FireRate * (G.RapidFireMult or 2) end
            if G.ForceFireMode and type(cfg.FireModeSettings) == "table" then cfg.FireModeSettings.FireMode = G.FireMode; cfg.FireModeSettings.CanSwitch = true end
            if G.InstantEquip then cfg.EquipTime = 0; if type(cfg.EquipAnimSpeed) == "number" then cfg.EquipAnimSpeed = math.max(cfg.EquipAnimSpeed, 1) * 3 end end
            if G.InstantHit and type(cfg.BulletSettings) == "table" then cfg.BulletSettings.Velocity = 10000; cfg.BulletSettings.Acceleration = Vector3.new(0, 0, 0) end
        end)
    end

    local depth = 0; local origGC
    local function hook(tool)
        G.calls += 1; local cfg
        if origGC then local ok, c = pcall(origGC, tool); if ok then cfg = c end end
        if cfg == nil then
            pcall(function()
                if typeof(tool) ~= "Instance" then return end
                local cm = tool:FindFirstChild("Config"); if not cm then return end
                local c2 = DeepCopy(require(cm))
                if c2 and depth == 0 then depth += 1; c2 = GetConfigAddon(tool, c2); depth -= 1 end; cfg = c2
            end)
        end
        if cfg then modify(cfg) end; return cfg
    end
    if type(hookfunction) == "function" and type(GC_Func) == "function" then
        local ok, orig = pcall(hookfunction, GC_Func, hook); if ok then origGC = orig; G.hooked = true end
    end

    GunBox:AddToggle("GunNoRecoil", { Text = "No Recoil", Default = false, Callback = function(v) G.NoRecoil = v end })
    GunBox:AddToggle("GunNoSpread", { Text = "No Spread", Default = false, Callback = function(v) G.NoSpread = v end })
    GunBox:AddToggle("GunNoDrop", { Text = "No Bullet Drop", Default = false, Callback = function(v) G.NoBulletDrop = v end })
    GunBox:AddToggle("GunRapidFire", { Text = "Rapid Fire", Default = false, Callback = function(v) G.RapidFire = v end })
    GunBox:AddSlider("RapidMult", { Text = "Fire Rate Multiplier", Default = 2, Min = 1, Max = 10, Decimals = 0, Callback = function(v) G.RapidFireMult = v end })
    GunBox:AddToggle("ForceFireMode", { Text = "Force Fire Mode", Default = false, Callback = function(v) G.ForceFireMode = v end })
    GunBox:AddDropdown("FireModeDD", { Text = "Fire Mode", Default = "Auto", Values = {"Auto","Semi","Burst"}, Callback = function(v) G.FireMode = v end })
    GunBox:AddToggle("InstantEquip", { Text = "Instant Equip", Default = false, Callback = function(v) G.InstantEquip = v end })
    GunBox:AddToggle("InstantHit", { Text = "Instant Hit", Default = false, Callback = function(v) G.InstantHit = v end })

    -- Auto Reload
    local RL = { Enabled = false, reloads = 0 }; local ammoConn; local lastPress = 0
    local function watchTool(tool)
        if ammoConn then pcall(function() ammoConn:Disconnect() end); ammoConn = nil end
        if not (tool and tool:IsA("Tool")) then return end
        local vals = tool:FindFirstChild("Values"); local ammo = vals and vals:FindFirstChild("SERVER_Ammo"); local stored = vals and vals:FindFirstChild("SERVER_StoredAmmo")
        if not (ammo and stored) then return end
        ammoConn = ammo:GetPropertyChangedSignal("Value"):Connect(function()
            if not RL.Enabled then return end; if ammo.Value > 0 or stored.Value <= 0 then return end
            if tool.Parent ~= LP.Character then return end; if os.clock() - lastPress < 1.5 then return end
            if UIS:GetFocusedTextBox() then return end; lastPress = os.clock()
            task.spawn(function()
                task.wait(0.15)
                if RL.Enabled and ammo.Value <= 0 and tool.Parent == LP.Character and type(keypress) == "function" then
                    keypress(0x52); task.wait(0.05); if type(keyrelease) == "function" then keyrelease(0x52) end; RL.reloads += 1
                end
            end)
        end)
    end
    local rlConns = {}
    local function watchRLChar(char)
        for _, k in ipairs({ "rAdd", "rRem" }) do if rlConns[k] then pcall(function() rlConns[k]:Disconnect() end) end end
        rlConns.rAdd = char.ChildAdded:Connect(function(c) if c:IsA("Tool") then task.wait(); watchTool(c) end end)
        rlConns.rRem = char.ChildRemoved:Connect(function(c) if c:IsA("Tool") and ammoConn then pcall(function() ammoConn:Disconnect() end); ammoConn = nil end end)
        local t = char:FindFirstChildOfClass("Tool"); if t then watchTool(t) end
    end
    if LP.Character then watchRLChar(LP.Character) end; LP.CharacterAdded:Connect(watchRLChar)

    ReloadBox:AddToggle("AutoReload", { Text = "Auto Reload", Default = false, Description = "Presses R when magazine empties", Callback = function(v) RL.Enabled = v end })
end

------------------------------------------------------------
-- ANTI-EFFECTS
------------------------------------------------------------
do
    local AntiBox     = AntiTab:AddGroupbox("Anti-Effects")
    local AntiGrenBox = AntiTab:AddGroupbox("Anti-Grenades")

    local C = {}; S.crim = C

    RunService.Heartbeat:Connect(function()
        pcall(function()
            local s = S.charStats(LP.Name); if not s then return end
            if C.NoRagdoll then
                S.setv(s, "NoRagdoll", true)
                local rt = s:FindFirstChild("RagdollTime")
                if rt then if rt.Value ~= 0 then rt.Value = 0 end
                    S.setv(rt, "RagdollSwitch", false); S.setv(rt, "RagdollSwitch2", false)
                    S.setv(rt, "SRagdolled", false); S.setv(rt, "RagdollTime2", 0) end
            end
            if C.NoFallDamage then
                local cur = s:FindFirstChild("Currents")
                if cur and not cur:FindFirstChild("IGZNFD") then local v = Instance.new("BoolValue"); v.Name = "IGZNFD"; v:SetAttribute("VANTA", true); v.Parent = cur end
            else local cur = s:FindFirstChild("Currents"); local v = cur and cur:FindFirstChild("IGZNFD"); if v and v:GetAttribute("VANTA") then v:Destroy() end end
            if C.NoConcussion then S.setv(s, "ConcussionProof", 1); S.setv(s, "ConcussionProofEXPLOSION", 1) end
            if C.NoTearGas or C.NoPepperSpray then S.setv(s, "NoFlameGasStun", true) end
            if C.NoBarbwire then S.setv(s, "BleedProof", 1) end
            if C.AntiCombatLog then local tags = s:FindFirstChild("Tags"); if tags then for _, t in ipairs(tags:GetChildren()) do t:Destroy() end end end
        end)
    end)

    AntiBox:AddToggle("NoRagdoll", { Text = "No Ragdoll", Default = false, Callback = function(v) C.NoRagdoll = v end })
    AntiBox:AddToggle("NoFallDmg", { Text = "No Fall Damage", Default = false, Callback = function(v) C.NoFallDamage = v end })
    AntiBox:AddToggle("NoConcuss", { Text = "No Concussion", Default = false, Callback = function(v) C.NoConcussion = v end })
    AntiBox:AddToggle("NoBarbwire", { Text = "No Barbwire Bleed", Default = false, Callback = function(v) C.NoBarbwire = v end })
    AntiBox:AddToggle("AntiCombatLog", { Text = "Anti Combat Log", Default = false, Callback = function(v) C.AntiCombatLog = v end })

    AntiGrenBox:AddToggle("NoTearGas", { Text = "No Tear Gas", Default = false, Callback = function(v) C.NoTearGas = v end })
    AntiGrenBox:AddToggle("NoPepper", { Text = "No Pepper Spray", Default = false, Callback = function(v) C.NoPepperSpray = v end })

    -- Smoke / Flash / ShellShock
    local noSmoke, noFlash, noShellShock = false, false, false
    local function isSmokeFx(d)
        if not (d:IsA("ParticleEmitter") or d:IsA("Smoke")) then return false end
        local n = d.Name:lower(); local p = d.Parent; local pn = p and p.Name:lower() or ""
        return n:find("smoke") ~= nil or n:find("gas") ~= nil or pn:find("smoke") ~= nil or pn:find("gas") ~= nil
    end
    local function killSmoke(d) pcall(function() d.Enabled = false; if d:IsA("ParticleEmitter") then d:Clear() end end) end
    local function killInst(d) pcall(function() d:Destroy() end) end

    workspace.DescendantAdded:Connect(function(d) if noSmoke and isSmokeFx(d) then killSmoke(d) end end)

    local flashCamConn
    local function watchFlashCam()
        if flashCamConn then pcall(function() flashCamConn:Disconnect() end) end
        local cam = workspace.CurrentCamera; if not cam then return end
        flashCamConn = cam.ChildAdded:Connect(function(d) if noFlash and d.Name == "BlindEffect" then killInst(d) end end)
    end
    watchFlashCam()
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchFlashCam)

    task.spawn(function()
        local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui", 10)
        if pg then pg.ChildAdded:Connect(function(d) if noFlash and d.Name == "FlashedGUI" then killInst(d) end end) end
        local bs = RS:FindFirstChild("Storage"); bs = bs and bs:FindFirstChild("FrameworkStuff"); bs = bs and bs:FindFirstChild("BlindSounds")
        if bs then bs.ChildAdded:Connect(function(d) if noFlash then killInst(d) end end) end
        for _, gname in ipairs({ "Main", "Radios" }) do
            local grp = SoundService:FindFirstChild(gname)
            if grp then grp.ChildAdded:Connect(function(d) if noShellShock and d.ClassName == "EqualizerSoundEffect" and d.Name == "EqualizerSoundEffect" then killInst(d) end end) end
        end
    end)

    AntiGrenBox:AddToggle("NoSmoke", { Text = "No Smoke Screen", Default = false, Callback = function(v)
        noSmoke = v; if v then for _, d in ipairs(workspace:GetDescendants()) do if isSmokeFx(d) then killSmoke(d) end end end
    end })
    AntiGrenBox:AddToggle("NoFlash", { Text = "No Flash", Default = false, Callback = function(v) noFlash = v end })
    AntiGrenBox:AddToggle("NoShellShock", { Text = "No Shell Shock", Default = false, Callback = function(v) noShellShock = v end })
end

------------------------------------------------------------
-- PLAYER ESP
------------------------------------------------------------
do
    local PlayerEspBox = PEspTab:AddGroupbox("Player ESP")
    local EspCfgBox    = PEspTab:AddGroupbox("ESP Config")

    local E = {
        Enabled = false, Box = true, Name = true, Health = true, Distance = true, HeldItem = true,
        Tracer = false, Skeleton = false, HeadDot = false, Chams = false,
        Filled = false, Bold = true, MaxDistance = 0, TextSize = 13, Font = 2, TracerOrigin = "bottom",
        ChamsFillTransparency = 0.5, ChamsOutlineTransparency = 0,
    }
    E.Colors = {
        Box = Color3.fromRGB(235, 80, 80), Name = Color3.fromRGB(255, 255, 255),
        Distance = Color3.fromRGB(210, 210, 210), HeldItem = Color3.fromRGB(255, 210, 120),
        Tracer = Color3.fromRGB(235, 80, 80), Skeleton = Color3.fromRGB(255, 255, 255),
        HeadDot = Color3.fromRGB(235, 80, 80), ChamsFill = Color3.fromRGB(235, 80, 80),
        ChamsOutline = Color3.fromRGB(255, 255, 255),
        HealthHigh = Color3.fromRGB(80, 200, 120), HealthLow = Color3.fromRGB(220, 60, 60),
    }

    local BONES = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}

    local chamsHolder
    local function makeHolder()
        local f = Instance.new("Folder"); f.Name = "ZH_Chams"
        local ok, hui = pcall(function() return gethui and gethui() end)
        f.Parent = (ok and hui) or LP:FindFirstChildOfClass("PlayerGui") or game:GetService("CoreGui"); return f
    end
    local function ensureHolder() if not chamsHolder or not chamsHolder.Parent then chamsHolder = makeHolder() end; return chamsHolder end
    chamsHolder = makeHolder()

    local tracked = {}

    local function mkText()
        local m = Drawing.new("Text"); m.Center = true; m.Outline = true; m.Visible = false
        local b = Drawing.new("Text"); b.Center = true; b.Outline = false; b.Visible = false; return { m = m, b = b }
    end
    local function setText(slot, txt, pos, color)
        slot.m.Text = txt; slot.m.Size = E.TextSize; slot.m.Font = E.Font; slot.m.Position = pos; slot.m.Color = color; slot.m.Visible = true
        if E.Bold then slot.b.Text = txt; slot.b.Size = E.TextSize; slot.b.Font = E.Font; slot.b.Position = pos + Vector2.new(1, 0); slot.b.Color = color; slot.b.Visible = true
        else slot.b.Visible = false end
    end
    local function hideText(slot) slot.m.Visible = false; slot.b.Visible = false end
    local function rmText(slot) pcall(function() slot.m:Remove() end); pcall(function() slot.b:Remove() end) end

    local function buildFor(plr)
        if tracked[plr] then return tracked[plr] end
        local t = {}
        t.box = Drawing.new("Square"); t.box.Thickness = 1; t.box.Filled = false; t.box.Visible = false
        t.boxFill = Drawing.new("Square"); t.boxFill.Thickness = 1; t.boxFill.Filled = true; t.boxFill.Transparency = 0.3; t.boxFill.Visible = false
        t.name = mkText(); t.dist = mkText(); t.held = mkText()
        t.healthBg = Drawing.new("Line"); t.healthBg.Thickness = 3; t.healthBg.Color = Color3.new(0,0,0); t.healthBg.Visible = false
        t.healthFg = Drawing.new("Line"); t.healthFg.Thickness = 1; t.healthFg.Visible = false
        t.tracer = Drawing.new("Line"); t.tracer.Thickness = 1; t.tracer.Visible = false
        t.headdot = Drawing.new("Circle"); t.headdot.Thickness = 1; t.headdot.Radius = 3; t.headdot.NumSides = 12; t.headdot.Filled = false; t.headdot.Visible = false
        t.bones = {}; for i = 1, #BONES do local l = Drawing.new("Line"); l.Thickness = 1; l.Visible = false; t.bones[i] = l end
        t.chams = Instance.new("Highlight"); t.chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; t.chams.Enabled = false; t.chams.Parent = ensureHolder()
        tracked[plr] = t
        local function grab(c) t.char = c; t.hum = c and c:FindFirstChildOfClass("Humanoid"); t.chams.Adornee = c end
        grab(plr.Character); t.addConn = plr.CharacterAdded:Connect(grab); return t
    end

    local function hideAll(t)
        t.box.Visible = false; t.boxFill.Visible = false; hideText(t.name); hideText(t.dist); hideText(t.held)
        t.healthBg.Visible = false; t.healthFg.Visible = false; t.tracer.Visible = false; t.headdot.Visible = false
        for _, b in ipairs(t.bones) do b.Visible = false end; t.chams.Enabled = false
    end

    local function destroyFor(plr)
        local t = tracked[plr]; if not t then return end
        if t.addConn then pcall(function() t.addConn:Disconnect() end) end
        for _, k in ipairs({"box","boxFill","healthBg","healthFg","tracer","headdot"}) do pcall(function() t[k]:Remove() end) end
        rmText(t.name); rmText(t.dist); rmText(t.held)
        for _, b in ipairs(t.bones) do pcall(function() b:Remove() end) end
        pcall(function() t.chams:Destroy() end); tracked[plr] = nil
    end

    RunService.RenderStepped:Connect(function()
        if not E.Enabled then return end
        local cam = workspace.CurrentCamera; if not cam then return end
        local myChar = LP.Character; local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart"); local vp = cam.ViewportSize
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local t = tracked[plr] or buildFor(plr)
                local char = plr.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local head = char and char:FindFirstChild("Head"); local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not t.chams or not t.chams.Parent then t.chams = Instance.new("Highlight"); t.chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; t.chams.Enabled = false; t.chams.Parent = ensureHolder() end
                if t.chams.Adornee ~= char then t.chams.Adornee = char end
                if not (char and hrp and head and hum and hum.Health > 0) then hideAll(t) else
                    local dist = myHrp and (myHrp.Position - hrp.Position).Magnitude or 0
                    if E.MaxDistance > 0 and dist > E.MaxDistance then hideAll(t) else
                        t.chams.Enabled = E.Chams
                        if E.Chams then t.chams.FillColor = E.Colors.ChamsFill; t.chams.OutlineColor = E.Colors.ChamsOutline; t.chams.FillTransparency = E.ChamsFillTransparency; t.chams.OutlineTransparency = E.ChamsOutlineTransparency end
                        local topS = table.pack(cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.8, 0)))
                        local botS = table.pack(cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.2, 0)))
                        if not (topS[2] or botS[2]) then
                            hideText(t.name); hideText(t.dist); hideText(t.held); t.box.Visible = false; t.boxFill.Visible = false
                            t.healthBg.Visible = false; t.healthFg.Visible = false; t.tracer.Visible = false; t.headdot.Visible = false
                            for _, b in ipairs(t.bones) do b.Visible = false end
                        else
                            local tp, bp = topS[1], botS[1]; local h = math.abs(bp.Y - tp.Y); local w = h * 0.55
                            local cx = (tp.X + bp.X) / 2; local topY = math.min(tp.Y, bp.Y)
                            if E.Box then t.box.Size = Vector2.new(w, h); t.box.Position = Vector2.new(cx - w/2, topY); t.box.Color = E.Colors.Box; t.box.Visible = true else t.box.Visible = false end
                            if E.Filled and E.Box then t.boxFill.Size = Vector2.new(w, h); t.boxFill.Position = Vector2.new(cx - w/2, topY); t.boxFill.Color = E.Colors.Box; t.boxFill.Visible = true else t.boxFill.Visible = false end
                            if E.Name then setText(t.name, plr.Name, Vector2.new(cx, topY - E.TextSize - 2), E.Colors.Name) else hideText(t.name) end
                            local lineY = topY + h + 1
                            if E.Distance then setText(t.dist, ("%dm"):format(dist), Vector2.new(cx, lineY), E.Colors.Distance); lineY = lineY + E.TextSize + 1 else hideText(t.dist) end
                            if E.HeldItem then local tool = char:FindFirstChildOfClass("Tool"); if tool then setText(t.held, "["..tool.Name.."]", Vector2.new(cx, lineY), E.Colors.HeldItem) else hideText(t.held) end else hideText(t.held) end
                            if E.Health then
                                local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1); local bx = cx - w/2 - 4
                                t.healthBg.From = Vector2.new(bx, topY); t.healthBg.To = Vector2.new(bx, topY + h)
                                t.healthFg.From = Vector2.new(bx, topY + h*(1-frac)); t.healthFg.To = Vector2.new(bx, topY + h)
                                t.healthFg.Color = E.Colors.HealthLow:Lerp(E.Colors.HealthHigh, frac); t.healthBg.Visible = true; t.healthFg.Visible = true
                            else t.healthBg.Visible = false; t.healthFg.Visible = false end
                            if E.Tracer then
                                local from = Vector2.new(vp.X/2, vp.Y)
                                if E.TracerOrigin == "top" then from = Vector2.new(vp.X/2, 0) elseif E.TracerOrigin == "center" then from = vp/2 end
                                t.tracer.From = from; t.tracer.To = Vector2.new(cx, topY + h); t.tracer.Color = E.Colors.Tracer; t.tracer.Visible = true
                            else t.tracer.Visible = false end
                            if E.HeadDot then local hs = table.pack(cam:WorldToViewportPoint(head.Position))
                                if hs[2] then t.headdot.Position = Vector2.new(hs[1].X, hs[1].Y); t.headdot.Color = E.Colors.HeadDot; t.headdot.Visible = true else t.headdot.Visible = false end
                            else t.headdot.Visible = false end
                            if E.Skeleton then
                                for i, pair in ipairs(BONES) do local a = char:FindFirstChild(pair[1]); local b = char:FindFirstChild(pair[2]); local bone = t.bones[i]
                                    if a and b then local as = table.pack(cam:WorldToViewportPoint(a.Position)); local bs = table.pack(cam:WorldToViewportPoint(b.Position))
                                        if as[2] and bs[2] then bone.From = Vector2.new(as[1].X, as[1].Y); bone.To = Vector2.new(bs[1].X, bs[1].Y); bone.Color = E.Colors.Skeleton; bone.Visible = true else bone.Visible = false end
                                    else bone.Visible = false end end
                            else for _, b in ipairs(t.bones) do b.Visible = false end end
                        end
                    end
                end
            end
        end
    end)
    Players.PlayerRemoving:Connect(destroyFor)

    PlayerEspBox:AddToggle("PlayerESP", { Text = "Player ESP", Default = false, Callback = function(v) E.Enabled = v; if not v then for _, t in pairs(tracked) do hideAll(t) end end end })
    PlayerEspBox:AddToggle("ESPBox", { Text = "Box", Default = true, Callback = function(v) E.Box = v end })
    PlayerEspBox:AddToggle("ESPFilled", { Text = "Filled Box", Default = false, Callback = function(v) E.Filled = v end })
    PlayerEspBox:AddToggle("ESPName", { Text = "Name", Default = true, Callback = function(v) E.Name = v end })
    PlayerEspBox:AddToggle("ESPHealth", { Text = "Health Bar", Default = true, Callback = function(v) E.Health = v end })
    PlayerEspBox:AddToggle("ESPDist", { Text = "Distance", Default = true, Callback = function(v) E.Distance = v end })
    PlayerEspBox:AddToggle("ESPHeld", { Text = "Held Item", Default = true, Callback = function(v) E.HeldItem = v end })
    PlayerEspBox:AddToggle("ESPTracer", { Text = "Tracers", Default = false, Callback = function(v) E.Tracer = v end })
    PlayerEspBox:AddToggle("ESPSkeleton", { Text = "Skeleton", Default = false, Callback = function(v) E.Skeleton = v end })
    PlayerEspBox:AddToggle("ESPHeadDot", { Text = "Head Dot", Default = false, Callback = function(v) E.HeadDot = v end })
    PlayerEspBox:AddToggle("ESPChams", { Text = "Chams", Default = false, Callback = function(v) E.Chams = v end })
    PlayerEspBox:AddToggle("ESPBold", { Text = "Bold Text", Default = true, Callback = function(v) E.Bold = v end })

    EspCfgBox:AddSlider("ESPMaxDist", { Text = "Max Distance (0=inf)", Default = 0, Min = 0, Max = 5000, Decimals = 0, Callback = function(v) E.MaxDistance = v end })
    EspCfgBox:AddSlider("ESPTextSize", { Text = "Text Size", Default = 13, Min = 8, Max = 28, Decimals = 0, Callback = function(v) E.TextSize = v end })
    EspCfgBox:AddSlider("ChamsFillTrans", { Text = "Chams Fill Transparency", Default = 0.5, Min = 0, Max = 1, Decimals = 2, Callback = function(v) E.ChamsFillTransparency = v end })
    EspCfgBox:AddSlider("ChamsOutTrans", { Text = "Chams Outline Transparency", Default = 0, Min = 0, Max = 1, Decimals = 2, Callback = function(v) E.ChamsOutlineTransparency = v end })
    EspCfgBox:AddDropdown("TracerOrigin", { Text = "Tracer Origin", Default = "bottom", Values = {"bottom","top","center"}, Callback = function(v) E.TracerOrigin = v end })
    EspCfgBox:AddColorPicker("BoxColor", { Text = "Box Color", Default = E.Colors.Box, Callback = function(c) E.Colors.Box = c end })
    EspCfgBox:AddColorPicker("NameColor", { Text = "Name Color", Default = E.Colors.Name, Callback = function(c) E.Colors.Name = c end })
    EspCfgBox:AddColorPicker("TracerColorP", { Text = "Tracer Color", Default = E.Colors.Tracer, Callback = function(c) E.Colors.Tracer = c end })
    EspCfgBox:AddColorPicker("ChamsFillColor", { Text = "Chams Fill", Default = E.Colors.ChamsFill, Callback = function(c) E.Colors.ChamsFill = c end })
end

------------------------------------------------------------
-- OBJECT ESP
------------------------------------------------------------
do
    local ObjEspBox = OEspTab:AddGroupbox("Object ESP")
    local ScrapCfgBox = OEspTab:AddGroupbox("Scrap Config")

    local O = { Enabled = false, Scrap = false, ATM = false, Dealer = false, Safe = false, Register = false,
        MaxDistance = 0, TextSize = 13, Dot = true, Bold = true, Font = 2, ScrapShowType = true }
    O.Colors = { Scrap = Color3.fromRGB(120, 220, 120), ATM = Color3.fromRGB(120, 200, 255),
        Dealer = Color3.fromRGB(255, 190, 90), Safe = Color3.fromRGB(255, 120, 120), Register = Color3.fromRGB(230, 150, 255) }
    local ScrapMap = {
        S1 = { name = "S1", color = Color3.fromRGB(150, 150, 150) }, S2 = { name = "S2", color = Color3.fromRGB(120, 220, 120) },
        S3 = { name = "S3", color = Color3.fromRGB(120, 200, 255) }, C1 = { name = "C1", color = Color3.fromRGB(255, 190, 90) },
        P  = { name = "P",  color = Color3.fromRGB(230, 150, 255) }, I24= { name = "I24", color = Color3.fromRGB(255, 215, 0) },
        EE = { name = "EE", color = Color3.fromRGB(255, 120, 200) }, HP = { name = "HP", color = Color3.fromRGB(255, 90, 90) },
    }

    local registry = {}
    local function pivotPos(inst) local ok, cf = pcall(function() return inst:GetPivot() end); if ok and cf then return cf.Position end
        local pp = inst:FindFirstChildWhichIsA("BasePart", true); return pp and pp.Position or nil end
    local function add(inst, cat)
        if registry[inst] or not inst:IsA("Model") then return end; local pos = pivotPos(inst); if not pos then return end
        local text = Drawing.new("Text"); text.Size = O.TextSize; text.Center = true; text.Outline = true; text.Color = O.Colors[cat] or Color3.new(1,1,1); text.Visible = false
        local textB = Drawing.new("Text"); textB.Center = true; textB.Outline = false; textB.Visible = false
        local dot = Drawing.new("Circle"); dot.Radius = 3; dot.NumSides = 10; dot.Filled = true; dot.Color = O.Colors[cat] or Color3.new(1,1,1); dot.Visible = false
        local broken = inst:FindFirstChild("Broken", true)
        registry[inst] = { cat = cat, subtype = inst.Name, pos = pos, text = text, textB = textB, dot = dot, broken = (broken and broken:IsA("BoolValue")) and broken or nil }
    end
    local function remove(inst) local e = registry[inst]; if not e then return end; pcall(function() e.text:Remove() end); pcall(function() e.textB:Remove() end); pcall(function() e.dot:Remove() end); registry[inst] = nil end
    local function hideE(e) e.text.Visible = false; e.textB.Visible = false; e.dot.Visible = false end

    local function regContainer(container, cat, nameMatch)
        if not container then return end
        for _, c in ipairs(container:GetChildren()) do if c:IsA("Model") and (not nameMatch or c.Name:lower():find(nameMatch, 1, true)) then add(c, cat) end end
        container.ChildAdded:Connect(function(c) task.wait(0.1); if c:IsA("Model") and (not nameMatch or c.Name:lower():find(nameMatch, 1, true)) then add(c, cat) end end)
        container.ChildRemoved:Connect(function(c) remove(c) end)
    end
    do local map = workspace:FindFirstChild("Map"); local filt = workspace:FindFirstChild("Filter")
        regContainer(filt and filt:FindFirstChild("SpawnedPiles"), "Scrap")
        regContainer(map and map:FindFirstChild("ATMz"), "ATM"); regContainer(map and map:FindFirstChild("Shopz"), "Dealer")
        regContainer(map and map:FindFirstChild("BredMakurz"), "Safe", "safe"); regContainer(map and map:FindFirstChild("BredMakurz"), "Register", "register") end

    RunService.RenderStepped:Connect(function()
        if not O.Enabled then return end; local cam = workspace.CurrentCamera; if not cam then return end
        local myChar = LP.Character; local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart"); local myPos = myHrp and myHrp.Position
        for inst, e in pairs(registry) do
            local show = O[e.cat] and (inst.Parent ~= nil) and not (e.broken and e.broken.Value == true)
            if not show then hideE(e) else
                local dist = myPos and (myPos - e.pos).Magnitude or 0
                if O.MaxDistance > 0 and dist > O.MaxDistance then hideE(e) else
                    local s, on = cam:WorldToViewportPoint(e.pos)
                    if not on then hideE(e) else
                        local col = O.Colors[e.cat] or Color3.new(1,1,1); local name = e.cat
                        if e.cat == "Scrap" and O.ScrapShowType and e.subtype then local m = ScrapMap[e.subtype]; if m then col = m.color; name = m.name else name = e.subtype end end
                        local label = ("%s [%dm]"):format(name, dist); local pos2 = Vector2.new(s.X, s.Y - O.TextSize - 2)
                        e.text.Text = label; e.text.Size = O.TextSize; e.text.Font = O.Font; e.text.Color = col; e.text.Position = pos2; e.text.Visible = true
                        if O.Bold then e.textB.Text = label; e.textB.Size = O.TextSize; e.textB.Font = O.Font; e.textB.Color = col; e.textB.Position = pos2 + Vector2.new(1, 0); e.textB.Visible = true else e.textB.Visible = false end
                        if O.Dot then e.dot.Position = Vector2.new(s.X, s.Y); e.dot.Color = col; e.dot.Visible = true else e.dot.Visible = false end
                    end
                end
            end
        end
    end)

    ObjEspBox:AddToggle("ObjESP", { Text = "Object ESP", Default = false, Callback = function(v) O.Enabled = v; if not v then for _, e in pairs(registry) do hideE(e) end end end })
    ObjEspBox:AddToggle("ObjScrap", { Text = "Scrap", Default = false, Callback = function(v) O.Scrap = v end })
    ObjEspBox:AddToggle("ObjATM", { Text = "ATM", Default = false, Callback = function(v) O.ATM = v end })
    ObjEspBox:AddToggle("ObjDealer", { Text = "Dealer", Default = false, Callback = function(v) O.Dealer = v end })
    ObjEspBox:AddToggle("ObjSafe", { Text = "Safe", Default = false, Callback = function(v) O.Safe = v end })
    ObjEspBox:AddToggle("ObjRegister", { Text = "Register", Default = false, Callback = function(v) O.Register = v end })
    ObjEspBox:AddSlider("ObjMaxDist", { Text = "Max Distance (0=inf)", Default = 0, Min = 0, Max = 5000, Decimals = 0, Callback = function(v) O.MaxDistance = v end })
    ObjEspBox:AddSlider("ObjTextSize", { Text = "Text Size", Default = 13, Min = 8, Max = 28, Decimals = 0, Callback = function(v) O.TextSize = v end })
    ObjEspBox:AddToggle("ObjDot", { Text = "Dot Marker", Default = true, Callback = function(v) O.Dot = v end })
    ObjEspBox:AddToggle("ObjBold", { Text = "Bold Text", Default = true, Callback = function(v) O.Bold = v end })
    ScrapCfgBox:AddToggle("ScrapShowType", { Text = "Show Scrap Type", Default = true, Callback = function(v) O.ScrapShowType = v end })
    ScrapCfgBox:AddColorPicker("ScrapColor", { Text = "Scrap Color", Default = O.Colors.Scrap, Callback = function(c) O.Colors.Scrap = c end })
    ScrapCfgBox:AddColorPicker("ATMColor", { Text = "ATM Color", Default = O.Colors.ATM, Callback = function(c) O.Colors.ATM = c end })
    ScrapCfgBox:AddColorPicker("DealerColor", { Text = "Dealer Color", Default = O.Colors.Dealer, Callback = function(c) O.Colors.Dealer = c end })
    ScrapCfgBox:AddColorPicker("SafeColor", { Text = "Safe Color", Default = O.Colors.Safe, Callback = function(c) O.Colors.Safe = c end })
    ScrapCfgBox:AddColorPicker("RegisterColor", { Text = "Register Color", Default = O.Colors.Register, Callback = function(c) O.Colors.Register = c end })
end

------------------------------------------------------------
-- WORLD (Full Bright / No Fog)
------------------------------------------------------------
do
    local orig = { Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
        FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd, ClockTime = Lighting.ClockTime, GlobalShadows = Lighting.GlobalShadows,
        EnvDiffuse = Lighting.EnvironmentDiffuseScale, EnvSpecular = Lighting.EnvironmentSpecularScale }
    local function atmosphere() return Lighting:FindFirstChildOfClass("Atmosphere") end
    local origAtmo; do local a = atmosphere(); if a then origAtmo = { Density = a.Density, Haze = a.Haze, Glare = a.Glare } end end
    local fullBright, noFog, applying = false, false, false

    local function applyLighting()
        if applying then return end; applying = true
        pcall(function()
            if fullBright then Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false
                Lighting.Ambient = Color3.fromRGB(150, 150, 150); Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
                Lighting.EnvironmentDiffuseScale = 1; Lighting.EnvironmentSpecularScale = 1
            else Lighting.Brightness = orig.Brightness; Lighting.GlobalShadows = orig.GlobalShadows
                Lighting.Ambient = orig.Ambient; Lighting.OutdoorAmbient = orig.OutdoorAmbient
                Lighting.EnvironmentDiffuseScale = orig.EnvDiffuse; Lighting.EnvironmentSpecularScale = orig.EnvSpecular end
            local a = atmosphere()
            if noFog then Lighting.FogEnd = 1e9; Lighting.FogStart = 0; if a then a.Density = 0; a.Haze = 0; a.Glare = 0 end
            else Lighting.FogEnd = orig.FogEnd; Lighting.FogStart = orig.FogStart; if a and origAtmo then a.Density = origAtmo.Density; a.Haze = origAtmo.Haze; a.Glare = origAtmo.Glare end end
        end); applying = false
    end

    Lighting.Changed:Connect(function() if (noFog or fullBright) and not applying then applyLighting() end end)
    local atmoConn
    local function hookAtmo() local a = atmosphere(); if not a then return end; if atmoConn then pcall(function() atmoConn:Disconnect() end) end
        atmoConn = a.Changed:Connect(function() if noFog and not applying then applyLighting() end end) end
    hookAtmo()
    Lighting.ChildAdded:Connect(function(c) if c:IsA("Atmosphere") then if origAtmo == nil then origAtmo = { Density = c.Density, Haze = c.Haze, Glare = c.Glare } end; hookAtmo(); applyLighting() end end)

    local LightBox = WorldTab:AddGroupbox("Lighting"); local FogBox = WorldTab:AddGroupbox("Fog")
    LightBox:AddToggle("FullBright", { Text = "Full Bright", Default = false, Callback = function(v) fullBright = v; applyLighting() end })
    FogBox:AddToggle("NoFog", { Text = "No Fog", Default = false, Callback = function(v) noFog = v; applyLighting() end })
end

------------------------------------------------------------
-- MOVEMENT (Stamina, Speed, Noclip, Fly Jump)
------------------------------------------------------------
do
    local MoveBox = MoveTab:AddGroupbox("Movement")

    -- Infinite Stamina
    local STAM = { enabled = false, max = 100, ctrlT = nil, wsConfig = nil }
    S.stam = STAM; getgenv().CRIM_STAM = STAM

    local sigT, DownedCheck, sigTries = nil, nil, 0
    local function findSignals()
        if DownedCheck or sigTries >= 3 then return end; sigTries += 1
        pcall(function()
            for _, o in ipairs(getgc(true)) do
                if type(o) == "table" then
                    if not DownedCheck and type(rawget(o, "GVF")) == "function" and type(rawget(o, "DownedCheck")) == "function" then sigT = o; DownedCheck = rawget(o, "DownedCheck") end
                    if not STAM.wsConfig and type(rawget(o, "DefaultWalkSpeed")) == "number" and type(rawget(o, "RunWalkSpeed")) == "number" then STAM.wsConfig = o end
                    if DownedCheck and STAM.wsConfig then break end
                end
            end
        end)
    end
    findSignals()

    local spawnedAt = os.clock()
    local function safeToRefill()
        if sigT then local ia = rawget(sigT, "IsAlive"); if type(ia) == "function" then local ok, a = pcall(ia); if ok and a == false then return false end elseif ia == false then return false end end
        if DownedCheck then local ok, d = pcall(DownedCheck); if ok and d == true then return false end end
        if os.clock() - spawnedAt < 4 then return false end
        local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if not h or h.Health <= 0 then return false end; if h.PlatformStand then return false end
        local ok, st = pcall(h.GetState, h)
        if ok and (st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.Dead) then return false end
        return true
    end

    local ctrlT, lastCtrl, tries = nil, nil, 0
    local function findController()
        if ctrlT then return true end
        if type(getconnections) ~= "function" or not (debug and debug.getupvalues) then return false end
        local foundT
        pcall(function()
            for _, con in ipairs(getconnections(RunService.Heartbeat)) do
                local f = con.Function
                if type(f) == "function" and con.Connected ~= false then
                    local okk, ups = pcall(debug.getupvalues, f)
                    if okk and ups then for i = 1, #ups do local u = ups[i]
                        if type(u) == "table" and u ~= lastCtrl and rawget(u, "S") ~= nil and rawget(u, "WS") ~= nil then foundT = u; return end
                    end end
                end
            end
        end)
        ctrlT = foundT; STAM.ctrlT = foundT; return ctrlT ~= nil
    end
    local function startFinder(delay)
        task.spawn(function()
            if delay and delay > 0 then task.wait(delay) end
            while (not ctrlT) and tries < 10 and getgenv().CRIM_STAM == STAM do tries += 1; pcall(findController); if ctrlT then break end; task.wait(1) end
        end)
    end
    startFinder()

    LP.CharacterAdded:Connect(function()
        spawnedAt = os.clock(); lastCtrl = ctrlT or lastCtrl; ctrlT = nil; STAM.ctrlT = nil; tries = 0; startFinder(1.5)
        if not DownedCheck then task.delay(2, function() pcall(findSignals) end) end
    end)

    local acc = 0
    RunService.Heartbeat:Connect(function(dt)
        if not STAM.enabled then return end; acc = acc + dt; if acc < 0.1 then return end; acc = 0
        if not ctrlT then return end; if not safeToRefill() then return end
        local ok, sv = pcall(function() return rawget(ctrlT, "S") end)
        if ok and type(sv) == "number" and sv < STAM.max then pcall(function() ctrlT.S = STAM.max end) end
    end)

    MoveBox:AddToggle("InfStamina", { Text = "Infinite Stamina", Default = false, Callback = function(v) STAM.enabled = v; if v and not ctrlT then pcall(findController) end end })
    MoveBox:AddDivider()

    -- Walk Speed
    local wsEnabled = false; local wsValue = 16; local wsOrigCfg = nil
    MoveBox:AddToggle("WalkSpeedToggle", { Text = "Walk Speed", Default = false, Callback = function(v)
        wsEnabled = v
        if v then
            local cfg = STAM.wsConfig
            if cfg then if wsOrigCfg == nil then wsOrigCfg = { d = cfg.DefaultWalkSpeed, r = cfg.RunWalkSpeed } end; cfg.DefaultWalkSpeed = wsValue; cfg.RunWalkSpeed = wsValue end
            local ct2 = STAM.ctrlT; if ct2 and rawget(ct2, "WS") ~= nil then ct2.WS = wsValue end
            local sv = S.charStats(LP.Name); if sv then S.setv(sv, "RepWalkSpeed", wsValue) end
        else if wsOrigCfg then local cfg = STAM.wsConfig; if cfg then cfg.DefaultWalkSpeed = wsOrigCfg.d; cfg.RunWalkSpeed = wsOrigCfg.r end; wsOrigCfg = nil end end
    end })
    MoveBox:AddSlider("WalkSpeedVal", { Text = "Speed", Default = 16, Min = 0, Max = 200, Decimals = 0, Callback = function(v)
        wsValue = v; if wsEnabled then
            local cfg = STAM.wsConfig; if cfg then cfg.DefaultWalkSpeed = v; cfg.RunWalkSpeed = v end
            local ct2 = STAM.ctrlT; if ct2 and rawget(ct2, "WS") ~= nil then ct2.WS = v end
            local sv = S.charStats(LP.Name); if sv then S.setv(sv, "RepWalkSpeed", v) end end
    end })
    MoveBox:AddDivider()

    -- Noclip
    local noclipConn
    MoveBox:AddToggle("Noclip", { Text = "Noclip", Default = false, Callback = function(p)
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        if not p then return end
        noclipConn = RunService.Stepped:Connect(function()
            local c = LP.Character; if not c then return end
            for _, pp in ipairs(c:GetChildren()) do if pp:IsA("BasePart") and pp.CanCollide then pp.CanCollide = false end end
        end)
    end })
    MoveBox:AddDivider()

    -- Fly Jump
    local flyJumpEnabled = false; local flyJumpPower = 70
    UIS.JumpRequest:Connect(function()
        if not flyJumpEnabled then return end
        local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not r then return end
        task.defer(function() local v = r.AssemblyLinearVelocity; r.AssemblyLinearVelocity = Vector3.new(v.X, flyJumpPower, v.Z) end)
    end)
    MoveBox:AddToggle("FlyJump", { Text = "Fly Jump", Default = false, Callback = function(v) flyJumpEnabled = v end })
    MoveBox:AddSlider("FlyJumpPower", { Text = "Jump Power", Default = 70, Min = 10, Max = 300, Decimals = 0, Callback = function(v) flyJumpPower = v end })
end

------------------------------------------------------------
-- MELEE AURA + AUTO FINISH
------------------------------------------------------------
do
    local MeleeBox = MeleeTab:AddGroupbox("Melee Aura")
    local FinishBox = MeleeTab:AddGroupbox("Auto Finish")

    local M = { Aura = false, AutoFinish = false, BreakCrates = false, Mode = "Legit",
        Range = 12, delay = 0.35, FinishKey = 0x46, FinishReach = 4.5, finishDelay = 0.8, finishRetry = 2.5,
        swings = 0, hits = 0, crates = 0, finishes = 0 }
    local lastSwing, lastFinish = 0, 0; local finishCD = setmetatable({}, { __mode = "k" })

    local GVF; pcall(function() for _, o in ipairs(getgc(true)) do if type(o) == "table" and type(rawget(o, "GVF")) == "function" then GVF = rawget(o, "GVF"); break end end end)

    local function mCharStats(name)
        if GVF then local ok, f = pcall(GVF, name); if ok and typeof(f) == "Instance" then return f end end
        for _, d in ipairs(RS:GetChildren()) do if d.Name == "CharStats" then return d:FindFirstChild(name) end end
    end
    local function meleeEquipped()
        local c = LP.Character; local tool = c and c:FindFirstChildOfClass("Tool"); if not tool then return false end
        local cfg = tool:FindFirstChild("Config"); if not (cfg and cfg:IsA("ModuleScript")) then return true end
        local ok, t = pcall(require, cfg); if ok and type(t) == "table" and (t.BulletsPerShot ~= nil or t.StoredAmmo ~= nil) then return false end; return true
    end
    local function mIsDowned(char)
        local f = mCharStats(char.Name); local d = f and f:FindFirstChild("Downed"); if d then return d.Value == true end
        local h = char:FindFirstChildOfClass("Humanoid"); return h ~= nil and h.Health <= 0
    end
    local function nearestEnemy(myPos, wantDowned)
        local chars = workspace:FindFirstChild("Characters"); if not chars then return nil end; local best, bestD = nil, M.Range
        for _, m in ipairs(chars:GetChildren()) do if m:IsA("Model") and m.Name ~= LP.Name then
            local hrp = m:FindFirstChild("HumanoidRootPart"); local hum = m:FindFirstChildOfClass("Humanoid")
            if hrp and hum then local downed = mIsDowned(m)
                if (wantDowned and downed) or (not wantDowned and not downed and hum.Health > 0) then local d = (myPos - hrp.Position).Magnitude; if d <= bestD then bestD = d; best = m end end
            end end end; return best
    end

    local RCHB; pcall(function() local n = RS:FindFirstChild("NewModules"); n = n and n:FindFirstChild("Shared"); n = n and n:FindFirstChild("Services"); n = n and n:FindFirstChild("RCHB"); if n then RCHB = require(n) end end)

    local function findHB()
        if not RCHB then return nil end
        local function try(inst) if typeof(inst) ~= "Instance" then return nil end; local hb; pcall(function() hb = RCHB:GetHitbox(inst) end)
            if type(hb) == "table" and hb.ONHAUIEVEN then return hb end; return nil end
        local G = type(getrenv) == "function" and getrenv()._G; local VM = type(G) == "table" and rawget(G, "VM")
        if type(VM) == "table" then for _, k in ipairs({"CloneTool","Current"}) do local holder = rawget(VM, k)
            if typeof(holder) == "Instance" then for _, p in ipairs(holder:GetChildren()) do local hb = try(p); if hb then return hb end end end end end
        local c = LP.Character; local tool = c and c:FindFirstChildOfClass("Tool")
        if tool then for _, p in ipairs(tool:GetChildren()) do if p:IsA("BasePart") then local hb = try(p); if hb then return hb end end end end
        if c then for _, n in ipairs({"Right Arm","Left Arm","RightHand","LeftHand"}) do local hb = try(c:FindFirstChild(n)); if hb then return hb end end end; return nil
    end
    local function visiblePart(model)
        for _, n in ipairs({"Torso","UpperTorso","Head","LowerTorso"}) do local p = model:FindFirstChild(n); if p and p:IsA("BasePart") and p.Transparency < 1 then return p end end
        for _, p in ipairs(model:GetChildren()) do if p:IsA("BasePart") and p.Transparency < 1 and p.Name ~= "HumanoidRootPart" then return p end end; return nil
    end
    local function confirmRay(fromPos, part, sibOk)
        local dir = part.Position - fromPos; if dir.Magnitude < 0.05 then return part.Position end
        local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Whitelist; rp.IgnoreWater = true
        local map = workspace:FindFirstChild("Map"); rp.FilterDescendantsInstances = map and { part, map } or { part }
        local r = workspace:Raycast(fromPos, dir.Unit * 6, rp); if r and (r.Instance == part or (sibOk and r.Instance.Parent == part.Parent)) then return r.Position end; return nil
    end
    local function nearestCrate(myPos)
        local map = workspace:FindFirstChild("Map"); local bm = map and map:FindFirstChild("BredMakurz"); if not bm then return nil end
        local op = OverlapParams.new(); op.FilterType = Enum.RaycastFilterType.Whitelist; op.FilterDescendantsInstances = { bm }
        local best, bestD
        for _, p in ipairs(workspace:GetPartBoundsInRadius(myPos, 7, op)) do if p.Parent and p.Parent.Parent == bm then local d = (p.Position - myPos).Magnitude; if not bestD or d < bestD then bestD = d; best = p end end end; return best
    end
    local function clickOnce()
        if type(mouse1click) == "function" then pcall(mouse1click)
        elseif type(mouse1press) == "function" and type(mouse1release) == "function" then pcall(mouse1press); task.wait(0.02); pcall(mouse1release) end
    end
    local function pressExecute()
        if UIS:GetFocusedTextBox() then return false end; local key = M.FinishKey or 0x46; if type(keypress) ~= "function" then return false end
        pcall(keypress, key); task.wait(0.03); if type(keyrelease) == "function" then pcall(keyrelease, key) end; return true
    end

    RunService.Heartbeat:Connect(function()
        if not (M.Aura or M.AutoFinish or M.BreakCrates) then return end; if not meleeEquipped() then return end
        local c = LP.Character; local hrp = c and c:FindFirstChild("HumanoidRootPart"); if not hrp then return end; local now = tick()
        if M.AutoFinish and (now - lastFinish >= M.finishDelay) then
            local dv = nearestEnemy(hrp.Position, true)
            if dv then local recent = finishCD[dv]; if not (recent and (now - recent) < M.finishRetry) then
                local torso = dv:FindFirstChild("Torso") or dv:FindFirstChild("UpperTorso")
                if torso and (torso.Position - hrp.Position).Magnitude <= M.FinishReach then lastFinish = now; finishCD[dv] = now; if pressExecute() then M.finishes += 1 end; return end end end
        end
        if now - lastSwing < M.delay then return end
        local target = M.Aura and nearestEnemy(hrp.Position, false) or nil; local part, isCrate
        if target then part = visiblePart(target) elseif M.BreakCrates then part = nearestCrate(hrp.Position); isCrate = part ~= nil end
        if not part then return end; local hitPos = confirmRay(hrp.Position, part, isCrate); if not hitPos then return end
        local back = hrp.Position - hitPos; local lastPos = back.Magnitude > 0.1 and (hitPos + back.Unit * 1.5) or hitPos
        lastSwing = now; M.swings += 1; clickOnce()
        local model = part.Parent
        task.delay(0.15, function()
            if not (part.Parent == model and model.Parent) then return end; local hb = findHB(); if not (hb and hb.ONHAUIEVEN) then return end
            if type(hb.HitTargets) == "table" then if hb.HitTargets[model] then return end; hb.HitTargets[model] = true end
            if pcall(function() hb.ONHAUIEVEN:Fire(part, model, hitPos, lastPos) end) then if isCrate then M.crates += 1 else M.hits += 1 end end
        end)
    end)

    MeleeBox:AddToggle("MeleeAura", { Text = "Melee Aura", Default = false, Callback = function(v) M.Aura = v end })
    MeleeBox:AddToggle("BreakCrates", { Text = "Break Crates", Default = false, Callback = function(v) M.BreakCrates = v end })
    MeleeBox:AddDropdown("MeleeMode", { Text = "Mode", Default = "Legit", Values = {"Legit","Blatant"}, Callback = function(v) M.Mode = v end })
    MeleeBox:AddSlider("MeleeRange", { Text = "Range", Default = 12, Min = 3, Max = 30, Decimals = 0, Callback = function(v) M.Range = v end })
    MeleeBox:AddSlider("MeleeDelay", { Text = "Swing Delay", Default = 0.35, Min = 0.1, Max = 1, Decimals = 2, Callback = function(v) M.delay = v end })
    FinishBox:AddToggle("AutoFinish", { Text = "Auto Finish", Default = false, Callback = function(v) M.AutoFinish = v end })
    FinishBox:AddSlider("FinishReach", { Text = "Finish Reach", Default = 4.5, Min = 2, Max = 10, Decimals = 1, Callback = function(v) M.FinishReach = v end })
end

------------------------------------------------------------
-- AUTOMATION
------------------------------------------------------------
do
    local AutoDoorBox   = AutoTab:AddGroupbox("Doors")
    local AutoPickupBox = AutoTab:AddGroupbox("Auto Pickup & Interact")
    local AutoLPBox     = AutoTab:AddGroupbox("Auto Lockpick")

    local A = { Enabled = false, AutoDoor = false, AutoClose = false, AutoUnlock = false, AutoKnock = false, DoorRange = 16,
        AutoATM = false, AutoShop = false, AutoVending = false, MoneyRange = 4.5,
        AutoScrap = false, ScrapRange = 12, InstantInteract = false, Interval = 0.30, fires = 0 }
    local cooldown = {}; local autoAcc = 0
    local doors, atms, shops, vendos, scrap, tools, cash = {}, {}, {}, {}, {}, {}, {}

    local function onCD(obj, secs) local now = os.clock(); local last = cooldown[obj]; if last and (now - last) < secs then return true end; cooldown[obj] = now; return false end
    local function alive() local c = LP.Character; local h = c and c:FindFirstChildOfClass("Humanoid"); return h ~= nil and h.Health > 0, c, (c and c:FindFirstChild("HumanoidRootPart")) end
    local function mapFolder(name) local map = workspace:FindFirstChild("Map"); return map and map:FindFirstChild(name) end
    local function firstBase(model) return model:FindFirstChild("DoorBase") or model:FindFirstChildWhichIsA("BasePart", true) end
    local function pickKnob(model, myPos)
        local k1, k2 = model:FindFirstChild("Knob1"), model:FindFirstChild("Knob2")
        if k1 and k2 then return ((k1.Position - myPos).Magnitude <= (k2.Position - myPos).Magnitude) and k1 or k2 end; return k1 or k2 or model:FindFirstChild("DoorBase")
    end
    local function interactPart(model)
        if model:IsA("BasePart") then return model end; local pa = model:FindFirstChild("posA", true); if pa and pa.Parent and pa.Parent:IsA("BasePart") then return pa.Parent end
        local mp = model:FindFirstChild("MainPart"); if mp and mp:IsA("BasePart") then return mp end; return model:FindFirstChildWhichIsA("BasePart", true)
    end

    local function indexDoors() local f = mapFolder("Doors"); if not f then return end
        for _, d in ipairs(f:GetChildren()) do if d:IsA("Model") and d:FindFirstChild("Values") and d:FindFirstChild("Events") then local b = firstBase(d); if b then doors[d] = b end end end
        f.ChildAdded:Connect(function(d) task.wait(0.15); if d:IsA("Model") and d:FindFirstChild("Values") and d:FindFirstChild("Events") then local b = firstBase(d); if b then doors[d] = b end end end)
        f.ChildRemoved:Connect(function(d) doors[d] = nil end) end
    local function indexInto(folderName, tbl) local f = mapFolder(folderName); if not f then return end
        for _, m in ipairs(f:GetChildren()) do local p = interactPart(m); if p then tbl[p] = m end end
        f.ChildAdded:Connect(function(m) task.wait(0.15); local p = interactPart(m); if p then tbl[p] = m end end)
        f.ChildRemoved:Connect(function(m) for p, mm in pairs(tbl) do if mm == m then tbl[p] = nil end end end) end
    local function indexScrap() local filt = workspace:FindFirstChild("Filter"); local f = filt and filt:FindFirstChild("SpawnedPiles"); if not f then return end
        for _, m in ipairs(f:GetChildren()) do if m:IsA("Model") then local p = m:FindFirstChildWhichIsA("BasePart", true); if p then scrap[m] = p end end end
        f.ChildAdded:Connect(function(m) task.wait(0.1); if m:IsA("Model") then local p = m:FindFirstChildWhichIsA("BasePart", true); if p then scrap[m] = p end end end)
        f.ChildRemoved:Connect(function(m) scrap[m] = nil end) end
    local function indexDrops() local filt = workspace:FindFirstChild("Filter"); if not filt then return end
        local st = filt:FindFirstChild("SpawnedTools"); local sb = filt:FindFirstChild("SpawnedBread")
        if st then for _, m in ipairs(st:GetChildren()) do local h = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart", true); if h then tools[m] = h end end
            st.ChildAdded:Connect(function(m) task.wait(0.1); local h = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart", true); if h then tools[m] = h end end)
            st.ChildRemoved:Connect(function(m) tools[m] = nil end) end
        if sb then for _, m in ipairs(sb:GetChildren()) do local p = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart", true); if p then cash[m] = p end end
            sb.ChildAdded:Connect(function(m) task.wait(0.1); local p = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart", true); if p then cash[m] = p end end)
            sb.ChildRemoved:Connect(function(m) cash[m] = nil end) end end
    indexDoors(); indexScrap(); indexDrops(); indexInto("ATMz", atms); indexInto("Shopz", shops)
    do local vm = mapFolder("VendingMachines") or mapFolder("Vending"); if vm then for _, m in ipairs(vm:GetChildren()) do local p = interactPart(m); if p then vendos[p] = m end end end end

    local function serviceDoor(d, base, myPos)
        local dist = (base.Position - myPos).Magnitude; local V = d.Values; local ad = V:FindFirstChild("ActiveDistance")
        local reach = math.min(A.DoorRange, (ad and ad.Value or A.DoorRange) + 2); if dist > reach then return end; if V.Broken.Value then return end
        if V.Busy.Value or V.Busy2.Value or V.Busy3.Value then return end; local tog = d.Events:FindFirstChild("Toggle"); if not tog then return end
        local knob = pickKnob(d, myPos)
        if A.AutoUnlock and V.Locked.Value and V:FindFirstChild("CanLock") and V.CanLock.Value then
            local lock = d:FindFirstChild("Lock"); if lock and not onCD(d, 1.25) then tog:FireServer("Unlock", lock) end; return end
        if V.Locked.Value then if A.AutoKnock and knob and d.DoorBase:FindFirstChild("KnockPos") and not onCD(d, 2.0) then tog:FireServer("Knock", knob) end; return end
        if A.AutoDoor and not V.Open.Value then if knob and not onCD(d, 0.9) then tog:FireServer("Open", knob) end
        elseif A.AutoClose and V.Open.Value then if knob and not onCD(d, 0.9) then tog:FireServer("Close", knob) end end
    end
    local function serviceMoney(part, model, myPos, remote, cd)
        if not remote then return end; if (part.Position - myPos).Magnitude > A.MoneyRange + 1 then return end
        local V = model:FindFirstChild("Values")
        if V then if (V:FindFirstChild("Broken") and V.Broken.Value) or (V:FindFirstChild("Busy") and V.Busy.Value) or (V:FindFirstChild("Stuck") and V.Stuck.Value) then return end end
        if not onCD(part, cd) then
            if remote:IsA("RemoteEvent") then remote:FireServer(part) elseif remote:IsA("BindableEvent") then remote:Fire(part) elseif remote:IsA("BindableFunction") then remote:Invoke(part) end end
    end

    RunService.Heartbeat:Connect(function(dt)
        if not A.Enabled then return end; autoAcc = autoAcc + dt; if autoAcc < A.Interval then return end; autoAcc = 0
        local ok, char, hrp = alive(); if not ok or not hrp then return end; local myPos = hrp.Position
        if A.AutoDoor or A.AutoClose or A.AutoUnlock or A.AutoKnock then for d, base in pairs(doors) do if d.Parent and base.Parent then pcall(serviceDoor, d, base, myPos) else doors[d] = nil end end end
        local Events2 = RS:FindFirstChild("Events2")
        if A.AutoATM and Events2 then local r = Events2:FindFirstChild("ATM"); for p, m in pairs(atms) do if p.Parent then pcall(serviceMoney, p, m, myPos, r, 1.5) else atms[p] = nil end end end
        if A.AutoShop and Events2 then local r = Events2:FindFirstChild("Shop"); for p, m in pairs(shops) do if p.Parent then pcall(serviceMoney, p, m, myPos, r, 2.0) else shops[p] = nil end end end
        if A.AutoVending and Events2 then local r = Events2:FindFirstChild("VendingMachine"); for p, m in pairs(vendos) do if p.Parent then pcall(serviceMoney, p, m, myPos, r, 2.0) else vendos[p] = nil end end end
        if A.AutoScrap then
            local Events = RS:FindFirstChild("Events"); local pic = Events and Events:FindFirstChild("PIC_PU")
            local tlo = Events and Events:FindFirstChild("PIC_TLO"); local czd = Events and Events:FindFirstChild("CZDPZUS")
            if pic then for pile, part in pairs(scrap) do if pile.Parent and part.Parent then
                local jzu = pile:GetAttribute("jzu"); if type(jzu) == "string" and (part.Position - myPos).Magnitude <= A.ScrapRange and not onCD(pile, 1.0) then pic:FireServer(string.reverse(jzu)) end
            else scrap[pile] = nil end end end
            if tlo then for item, part in pairs(tools) do if item.Parent and part.Parent and (part.Position - myPos).Magnitude <= A.ScrapRange and not onCD(item, 1.0) then tlo:FireServer(part) elseif not item.Parent then tools[item] = nil end end end
            if czd then for item, part in pairs(cash) do if item.Parent and part.Parent and (part.Position - myPos).Magnitude <= A.ScrapRange and not onCD(item, 1.0) then czd:FireServer(part) elseif not item.Parent then cash[item] = nil end end end
        end
    end)

    AutoDoorBox:AddToggle("AutoEnabled", { Text = "Enable Automation", Default = false, Callback = function(v) A.Enabled = v end })
    AutoDoorBox:AddToggle("AutoDoor", { Text = "Auto Open Doors", Default = false, Callback = function(v) A.AutoDoor = v end })
    AutoDoorBox:AddToggle("AutoClose", { Text = "Auto Close Doors", Default = false, Callback = function(v) A.AutoClose = v end })
    AutoDoorBox:AddToggle("AutoUnlock", { Text = "Auto Unlock", Default = false, Callback = function(v) A.AutoUnlock = v end })
    AutoDoorBox:AddToggle("AutoKnock", { Text = "Auto Knock", Default = false, Callback = function(v) A.AutoKnock = v end })
    AutoDoorBox:AddSlider("DoorRange", { Text = "Door Range", Default = 16, Min = 5, Max = 50, Decimals = 0, Callback = function(v) A.DoorRange = v end })
    AutoPickupBox:AddToggle("AutoScrap", { Text = "Auto Pickup Scrap/Tools/Cash", Default = false, Callback = function(v) A.AutoScrap = v end })
    AutoPickupBox:AddSlider("ScrapRange", { Text = "Pickup Range", Default = 12, Min = 3, Max = 50, Decimals = 0, Callback = function(v) A.ScrapRange = v end })
    AutoPickupBox:AddToggle("AutoATM", { Text = "Auto ATM Interact", Default = false, Callback = function(v) A.AutoATM = v end })
    AutoPickupBox:AddToggle("AutoShopI", { Text = "Auto Shop Interact", Default = false, Callback = function(v) A.AutoShop = v end })
    AutoPickupBox:AddToggle("AutoVending", { Text = "Auto Vending Machine", Default = false, Callback = function(v) A.AutoVending = v end })
    AutoPickupBox:AddToggle("InstantInteract", { Text = "Instant Interact", Default = false, Callback = function(v)
        A.InstantInteract = v; if v then for _, d in ipairs(workspace:GetDescendants()) do if typeof(d) == "Instance" and d:IsA("ProximityPrompt") then pcall(function() d.HoldDuration = 0 end) end end
            workspace.DescendantAdded:Connect(function(d) if A.InstantInteract and typeof(d) == "Instance" and d:IsA("ProximityPrompt") then pcall(function() d.HoldDuration = 0 end) end end) end
    end })

    -- Auto Lockpick
    local lpEnabled = false
    task.spawn(function()
        local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui", 10); if not pg then return end
        pg.ChildAdded:Connect(function(ch)
            if lpEnabled and ch.Name == "LockpickGUI" then task.spawn(function() pcall(function()
                local mf = ch:FindFirstChild("MF"); if not mf then return end
                local lpf = mf:FindFirstChild("LP_Frame"); local frames = lpf and lpf:FindFirstChild("Frames"); local btn = mf:FindFirstChild("MobileButton")
                if not (frames and btn) then return end; task.wait(0.12); if not lpEnabled or ch.Parent == nil then return end
                local n = 0; for _, f in ipairs(frames:GetChildren()) do if f:IsA("GuiObject") and f.Name:sub(1, 1) == "B" and f.Visible then n += 1 end end; if n < 1 then n = 3 end
                for _ = 1, n do if ch.Parent == nil then break end
                    local ok = pcall(firesignal, btn.MouseButton1Down, "lol")
                    if not ok then local ok2, cons = pcall(getconnections, btn.MouseButton1Down); if ok2 and cons then for _, c in ipairs(cons) do pcall(function() c:Fire("lol") end) end end end
                    task.wait() end
            end) end) end
        end)
    end)
    AutoLPBox:AddToggle("AutoLockpick", { Text = "Auto Lockpick", Default = false, Callback = function(v) lpEnabled = v end })
end

------------------------------------------------------------
-- BANKING & SHOP
------------------------------------------------------------
do
    local BankBox = BankTab:AddGroupbox("Auto Banking")
    local ShopBox = BankTab:AddGroupbox("Auto Shop")

    -- Auto Deposit / Allowance
    local B = { AutoDeposit = false, AutoAllowance = false, KeepCash = 0, deposits = 0, claims = 0, busy = false }
    local Events = RS:WaitForChild("Events", 10); local BankATM = Events and Events:FindFirstChild("ATM"); local BankCLM = Events and Events:FindFirstChild("CLMZALOW")

    local atmParts
    local function getAtmParts() if atmParts then return atmParts end; atmParts = {}
        pcall(function() local f = workspace:FindFirstChild("Map"); f = f and f:FindFirstChild("ATMz"); if not f then return end
            for _, d in ipairs(f:GetDescendants()) do if d:IsA("BasePart") and d:FindFirstChild("posA") then atmParts[#atmParts + 1] = d end end end); return atmParts end
    local function nearestAtm() local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end; local best, bd
        for _, p in ipairs(getAtmParts()) do if p.Parent then local dist = (p.Position - hrp.Position).Magnitude; if dist < 18 and (not bd or dist < bd) then best, bd = p, dist end end end; return best end

    local function onAtmOpened()
        if B.busy or not (B.AutoDeposit or B.AutoAllowance) then return end; B.busy = true
        task.spawn(function() task.wait(0.4); local atm = nearestAtm()
            local pbd = RS:FindFirstChild("PlayerbaseData2"); local me = pbd and pbd:FindFirstChild(LP.Name)
            if atm and me then
                if B.AutoAllowance and BankCLM then local na = me:FindFirstChild("NextAllowance"); local cl = na and na:FindFirstChild("Claim")
                    if cl and cl.Value == true then local ok, r1, r2 = pcall(BankCLM.InvokeServer, BankCLM, atm, nil); if ok and r1 then B.claims += 1 end; S.notify("Allowance", ok and (r2 or r1) or "fail") end end
                if B.AutoDeposit and BankATM then local cash = me:FindFirstChild("Cash"); local amt = cash and math.floor((cash.Value or 0) - (B.KeepCash or 0)) or 0
                    if amt >= 1 then local ok, s1, s2 = pcall(BankATM.InvokeServer, BankATM, "DP", amt, atm); if ok and s1 then B.deposits += 1 end; S.notify("Deposit", ok and (s2 or s1) or "fail") end end
            end; B.busy = false end)
    end
    task.spawn(function() local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui", 10)
        local cg = pg and pg:WaitForChild("CoreGUI", 10); local af = cg and cg:WaitForChild("ATMFrame", 10)
        if not af then return end; af:GetPropertyChangedSignal("Visible"):Connect(function() if af.Visible then onAtmOpened() end end) end)

    BankBox:AddToggle("AutoDeposit", { Text = "Auto Deposit", Default = false, Callback = function(v) B.AutoDeposit = v end })
    BankBox:AddToggle("AutoAllowance", { Text = "Auto Claim Allowance", Default = false, Callback = function(v) B.AutoAllowance = v end })
    BankBox:AddSlider("KeepCash", { Text = "Keep Cash Amount", Default = 0, Min = 0, Max = 50000, Decimals = 0, Callback = function(v) B.KeepCash = v end })

    -- Auto Shop
    local SP = { AutoSell = false, AutoRefill = false, AutoLockpicks = false, LockpickCount = 3, sold = 0, refills = 0, bought = 0, busy = false }
    local SHOP1 = RS:WaitForChild("Events"):WaitForChild("SSHPRMTE1", 10)
    local catMap
    local function catOf(name)
        if not catMap then catMap = {}; pcall(function() local st = RS:WaitForChild("Storage", 5); local IS = st and st:WaitForChild("ItemStats", 5)
            for _, folder in ipairs(IS:GetChildren()) do for _, e in ipairs(folder:GetChildren()) do catMap[e.Name] = { cat = folder.Name, entry = e } end end end) end; return catMap[name] end
    local function myTools() local out = {}; local bp = LP:FindFirstChild("Backpack"); if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then out[#out+1] = t end end end
        local c = LP.Character; if c then for _, t in ipairs(c:GetChildren()) do if t:IsA("Tool") then out[#out+1] = t end end end; return out end
    local function invoke(cat, item, action)
        local pg = LP:FindFirstChild("PlayerGui"); local cg = pg and pg:FindFirstChild("CoreGUI")
        local sv = cg and cg:FindFirstChild("ShopValue"); local st = cg and cg:FindFirstChild("ShopType"); local bz = cg and cg:FindFirstChild("BuyZoneValue")
        if not (SHOP1 and sv and sv.Value and st) then return false end; local fromBank = false
        pcall(function() local G = getrenv()._G; fromBank = G.GSettings and G.GSettings.ShopFromBank == true end)
        local ok, s1 = pcall(SHOP1.InvokeServer, SHOP1, st.Value, cat, item, sv.Value, action, fromBank, bz and bz.Value or nil, nil, nil); return ok and s1 == true end

    task.spawn(function() local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui", 10)
        local cg = pg and pg:WaitForChild("CoreGUI", 10); local sf = cg and cg:WaitForChild("ShopFrame", 10); if not sf then return end
        sf:GetPropertyChangedSignal("Visible"):Connect(function()
            if not sf.Visible or SP.busy then return end; if not (SP.AutoSell or SP.AutoRefill or SP.AutoLockpicks) then return end; SP.busy = true
            task.spawn(function() task.wait(0.6); pcall(function() local budget = 20
                if SP.AutoSell then for _, t in ipairs(myTools()) do if budget <= 0 then break end; if t.Name:sub(1, 4) == "val_" then
                    local m = catOf(t.Name); local e = m and m.entry; if e and e:FindFirstChild("Sellable") and e.Sellable.Value then if invoke(m.cat, t.Name, "Sell") then SP.sold += 1 end; budget -= 1; task.wait(0.35) end end end end
                if SP.AutoRefill then for _, t in ipairs(myTools()) do if budget <= 0 then break end; local m = catOf(t.Name)
                    if m and m.entry:FindFirstChild("ResupplyGun") then if invoke(m.cat, t.Name, "ResupplyAmmo") then SP.refills += 1 end; budget -= 1; task.wait(0.35)
                        local vals = t:FindFirstChild("Values"); if vals and vals:FindFirstChild("SERVER_Ammo2") and budget > 0 then if invoke(m.cat, t.Name, "ResupplyAmmo2") then SP.refills += 1 end; budget -= 1; task.wait(0.35) end end end end
                if SP.AutoLockpicks then local have = 0; for _, t in ipairs(myTools()) do if t.Name == "Lockpick" then have += 1 end end
                    while have < (SP.LockpickCount or 0) and budget > 0 do if not invoke("Misc", "Lockpick", "Buy") then break end; SP.bought += 1; have += 1; budget -= 1; task.wait(0.35) end end
            end); SP.busy = false end) end) end)

    ShopBox:AddToggle("AutoSell", { Text = "Auto Sell Valuables", Default = false, Callback = function(v) SP.AutoSell = v end })
    ShopBox:AddToggle("AutoRefill", { Text = "Auto Refill Ammo", Default = false, Callback = function(v) SP.AutoRefill = v end })
    ShopBox:AddToggle("AutoLockpicks", { Text = "Auto Buy Lockpicks", Default = false, Callback = function(v) SP.AutoLockpicks = v end })
    ShopBox:AddSlider("LockpickCount", { Text = "Lockpick Target Count", Default = 3, Min = 1, Max = 10, Decimals = 0, Callback = function(v) SP.LockpickCount = v end })
end

------------------------------------------------------------
-- UTILITY
------------------------------------------------------------
do
    local UtilBox  = UtilTab:AddGroupbox("Utility")
    local GuardBox = UtilTab:AddGroupbox("Anti-Moderator")

    -- Anti AFK
    local afkConn
    UtilBox:AddToggle("AntiAFK", { Text = "Anti AFK", Default = true, Callback = function(p)
        if afkConn then afkConn:Disconnect(); afkConn = nil end
        if p then afkConn = LP.Idled:Connect(function() pcall(function() local VU = game:GetService("VirtualUser"); VU:Button2Down(Vector2.zero, Cam.CFrame); task.wait(0.1); VU:Button2Up(Vector2.zero, Cam.CFrame) end) end) end
    end })
    UtilBox:AddButton({ Text = "Server Hop", Func = function()
        local TP = game:GetService("TeleportService"); local HS = game:GetService("HttpService"); local placeId = game.PlaceId
        local ok, res = pcall(function() return HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100")) end)
        if ok and res then for _, sv in ipairs(res.data or {}) do if sv.id ~= game.JobId and sv.playing < sv.maxPlayers then pcall(function() TP:TeleportToPlaceInstance(placeId, sv.id, LP) end); return end end end
    end })
    UtilBox:AddButton({ Text = "Rejoin", Func = function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end })

    -- Anti-Moderator
    local G = { Enabled = false, AutoLeave = true, RankMin = 50, GroupId = 4165692, found = {}, checked = {} }
    local function guardCheck(pl, stagger)
        if pl == LP or G.checked[pl] then return end; G.checked[pl] = true
        task.spawn(function()
            if stagger and stagger > 0 then task.wait(stagger) end
            local ok, rank = pcall(pl.GetRankInGroup, pl, G.GroupId); if not ok or type(rank) ~= "number" or rank < G.RankMin then return end
            local role = "rank " .. rank; pcall(function() role = pl:GetRoleInGroup(G.GroupId) .. " (rank " .. rank .. ")" end)
            G.found[pl.Name] = role; S.notify("Anti-Mod", "STAFF: " .. pl.Name .. " — " .. role)
            if G.Enabled and G.AutoLeave then task.wait(0.3); pcall(function() LP:Kick("Left: staff '" .. pl.Name .. "' present") end) end
        end)
    end
    Players.PlayerAdded:Connect(function(pl) if G.Enabled then guardCheck(pl) end end)
    Players.PlayerRemoving:Connect(function(pl) G.checked[pl] = nil end)

    GuardBox:AddToggle("AntiMod", { Text = "Anti-Moderator", Default = false, Callback = function(v) G.Enabled = v; if v then for i, pl in ipairs(Players:GetPlayers()) do guardCheck(pl, i * 0.05) end end end })
    GuardBox:AddToggle("AutoLeave", { Text = "Auto Leave on Staff", Default = true, Callback = function(v) G.AutoLeave = v end })
    GuardBox:AddSlider("RankMin", { Text = "Min Staff Rank", Default = 50, Min = 1, Max = 255, Decimals = 0, Callback = function(v) G.RankMin = v end })
end

------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------
Library:CreateSettingsTab(Window)
