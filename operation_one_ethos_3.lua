-- Luraph string.byte bypass (decloak protected calls)
local oldStrByte; oldStrByte = hookfunction(string.byte, newcclosure(function(a0, a1)
    if (checkcaller() or type(a0) ~= 'string' or not (a0:sub(1, 1) == '{' and a0:sub(-1) == '}')) then return oldStrByte(a0, a1) end;
    local luraph = getstack(3, 1);
    luraph[1] = luraph[2];
    luraph[5] = #luraph[2];
    setstack(3, 4, luraph[5]);
    return oldStrByte(luraph[1], a1);
end));

-- Kill any previous instance of this script (prevents UI overlay on re-execute)
-- EthosSuite handles this automatically via getgenv()._ZeroWindow

-- Load EthosSuite library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/toeerolo-z/ethossuiterewrite/refs/heads/main/ethossuite.lua"))()

local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

-- track everything this instance creates so we can fully clean up
local _ZH = { conns = {}, renders = {}, drawings = {}, highlights = {}, threads = {} }

------------------------------------------------------------
-- WINDOW
------------------------------------------------------------
local Window = Library:CreateWindow({
    Title = "ZERO HUB",
    Version = "v1.0.0",
    GameName = "Operation One",
})

------------------------------------------------------------
-- CATEGORIES
------------------------------------------------------------
local CatMain     = Window:AddCategory("MAIN")
local CatCharacter = Window:AddCategory("CHARACTER")
local CatVisuals  = Window:AddCategory("VISUALS")
local CatMisc     = Window:AddCategory("MISC")

------------------------------------------------------------
-- TABS
------------------------------------------------------------
local MainTab      = CatMain:AddTab("Aimbot")
local TrigTab      = CatMain:AddTab("Triggerbot")
local CharacterTab = CatCharacter:AddTab("Movement")
local VisualsTab   = CatVisuals:AddTab("Player ESP")
local MiscTab      = CatMisc:AddTab("Misc")

------------------------------------------------------------
-- ESP (Visuals tab)
------------------------------------------------------------
local ESPBox  = VisualsTab:AddGroupbox("Player ESP")
local CompBox = VisualsTab:AddGroupbox("ESP Components")

local _espEnabled = false
local _espActive = {}
local _espConns = {}
local _espComps = { ["Box"] = true }
local _espDist = 1000
local _espTeamCheck = false
local _hue = 0

RunService.Heartbeat:Connect(function(dt) _hue = (_hue + dt * 0.25) % 1 end)

local function makeDrawings()
    return {
        txt = Drawing.new("Text"),
        box = Drawing.new("Square"),
        hpFill = Drawing.new("Square"),
        hpBack = Drawing.new("Square"),
        tracer = Drawing.new("Line"),
        dot = Drawing.new("Circle"),
        outline = Drawing.new("Square"),
    }
end

local function hideDrawings(d)
    d.txt.Visible=false; d.box.Visible=false; d.hpFill.Visible=false; d.hpBack.Visible=false
    d.tracer.Visible=false; d.dot.Visible=false; d.outline.Visible=false
    if d.hl then d.hl.Enabled=false end
    if d.skel then for _, b in ipairs(d.skel) do b.Visible=false end end
end

local function removeESP(plr)
    local d = _espActive[plr]; if not d then return end
    for _, k in ipairs({"txt","box","hpFill","hpBack","tracer","dot","outline"}) do
        if d[k] then pcall(function() d[k]:Remove() end) end
    end
    if d.skel then for _, b in ipairs(d.skel) do pcall(function() b:Remove() end) end end
    if d.hl then pcall(function() d.hl:Destroy() end) end
    _espActive[plr] = nil
end

local function addESP(plr)
    if not plr or plr == LP or _espActive[plr] then return end
    local d = makeDrawings()
    d.txt.Center=true; d.txt.Outline=true; d.txt.Visible=false; d.txt.Size=14
    d.box.Filled=false; d.box.Thickness=1.5; d.box.Visible=false
    d.hpFill.Filled=true; d.hpFill.Visible=false
    d.hpBack.Filled=false; d.hpBack.Thickness=1; d.hpBack.Color=Color3.new(0,0,0); d.hpBack.Visible=false
    d.tracer.Thickness=1; d.tracer.Visible=false
    d.dot.Radius=4; d.dot.Filled=true; d.dot.Visible=false; d.dot.Thickness=1
    d.outline.Filled=false; d.outline.Thickness=3; d.outline.Visible=false
    d.hl = Instance.new("Highlight"); d.hl.FillTransparency=0.5; d.hl.OutlineTransparency=0; d.hl.Enabled=false
    d.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    d.hl.Parent = Cam
    d.lastChar = nil
    d.skel = {}
    for i = 1, 8 do local l = Drawing.new("Line"); l.Thickness = 1; l.Visible = false; d.skel[i] = l end
    _espActive[plr] = d
end

local function getCol(plr)
    if _espComps["Rainbow Outline"] then return Color3.fromHSV(_hue, 1, 1) end
    if plr and plr.Team then
        if plr.Team.Name == "Red" then return Color3.fromRGB(255, 80, 80) end
        return Color3.fromRGB(80, 160, 255)
    end
    return Color3.fromRGB(255, 255, 255)
end

local function getRealChar(plr)
    local uid = plr.UserId
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Model")
            and v:GetAttribute("UserId") == uid
            and v:FindFirstChild("Animate")
            and v:FindFirstChild("HumanoidRootPart")
            and v:FindFirstChildOfClass("Humanoid") then
            return v
        end
    end
    return nil
end

local _vmFolder = workspace:FindFirstChild("Viewmodels")
local function getViewmodel(hrp)
    if not _vmFolder or not hrp then return nil end
    local best, bestD = nil, 12
    for _, vm in ipairs(_vmFolder:GetChildren()) do
        local head = vm:FindFirstChild("head") or vm:FindFirstChild("torso")
        if head then
            local d = (head.Position - hrp.Position).Magnitude
            if d < bestD then best, bestD = vm, d end
        end
    end
    return best
end

-- ESP Render Loop
RunService:BindToRenderStep("ZH_ESP_MAIN", Enum.RenderPriority.Camera.Value + 1, function()
    if _ZH.dead then return end
    if not _espEnabled then return end
    for plr in pairs(_espActive) do
        if not plr or not plr.Parent or plr == LP then hideDrawings(_espActive[plr]); continue end
        if _espTeamCheck and plr.Team and plr.Team == LP.Team then hideDrawings(_espActive[plr]); continue end
        local char = getRealChar(plr)
        if not char then hideDrawings(_espActive[plr]); continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not (hum and hrp and hum.Health > 0) then hideDrawings(_espActive[plr]); continue end
        local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then hideDrawings(_espActive[plr]); continue end
        local dist = (hrp.Position - myHRP.Position).Magnitude
        if dist > _espDist then hideDrawings(_espActive[plr]); continue end
        local vm = getViewmodel(hrp)
        local d = _espActive[plr]
        local pos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
        if not onScreen then hideDrawings(d); continue end
        local sv = Vector2.new(pos.X, pos.Y)
        local hpPct = hum.Health / hum.MaxHealth
        local col = getCol(plr)
        local hpCol = Color3.fromHSV(math.max(0, (hpPct - 0.5) / 0.5 * 0.3), 1, 1)
        local bx, by, bw, bh = sv.X - 25, sv.Y - 35, 50, 70
        local headY = sv.Y - bh/2 - 5

        if _espComps["Box"] then d.box.Position=Vector2.new(bx,by); d.box.Size=Vector2.new(bw,bh); d.box.Color=col; d.box.Visible=true else d.box.Visible=false end
        if _espComps["Outline"] or _espComps["Rainbow Outline"] then d.outline.Position=Vector2.new(bx-1,by-1); d.outline.Size=Vector2.new(bw+2,bh+2); d.outline.Color=_espComps["Rainbow Outline"] and Color3.fromHSV(_hue,1,1) or col; d.outline.Visible=true else d.outline.Visible=false end
        if _espComps["HP"] then local barW=4; local barX=bx-barW-4; d.hpBack.Position=Vector2.new(barX-1,by-1); d.hpBack.Size=Vector2.new(barW+2,bh+2); d.hpBack.Visible=true; d.hpFill.Position=Vector2.new(barX,by+bh*(1-hpPct)); d.hpFill.Size=Vector2.new(barW,bh*hpPct); d.hpFill.Color=hpCol; d.hpFill.Visible=true else d.hpFill.Visible=false; d.hpBack.Visible=false end
        if _espComps["Box HP"] then d.txt.Text=string.format("%s [%d/%d] [%.0fm]",plr.DisplayName,hum.Health,hum.MaxHealth,dist); d.txt.Color=col; d.txt.Size=14; d.txt.Position=Vector2.new(sv.X,by-18); d.txt.Visible=true
        elseif _espComps["Box"] or _espComps["Outline"] then d.txt.Text=string.format("%s [%.0fm]",plr.DisplayName,dist); d.txt.Color=col; d.txt.Size=14; d.txt.Position=Vector2.new(sv.X,by-18); d.txt.Visible=true
        else d.txt.Visible=false end
        if _espComps["Tracers"] then d.tracer.From=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); d.tracer.To=Vector2.new(sv.X,sv.Y+bh/2); d.tracer.Color=col; d.tracer.Thickness=1; d.tracer.Visible=true else d.tracer.Visible=false end
        if _espComps["Head Dot"] then d.dot.Position=Vector2.new(sv.X,headY); d.dot.Color=col; d.dot.Visible=true else d.dot.Visible=false end

        local hlE = _espComps["Highlight"] or _espComps["Rainbow Highlight"] or _espComps["Chams"]
        d.hl.Enabled = hlE
        if hlE then
            if _espComps["Rainbow Highlight"] then
                local rc=Color3.fromHSV(_hue,1,1); d.hl.FillColor=rc; d.hl.OutlineColor=rc; d.hl.FillTransparency=0.25; d.hl.OutlineTransparency=0
            elseif _espComps["Chams"] then
                d.hl.FillColor=col; d.hl.OutlineColor=Color3.new(1,1,1); d.hl.FillTransparency=0.15; d.hl.OutlineTransparency=0
            else
                d.hl.FillColor=col; d.hl.OutlineColor=col; d.hl.FillTransparency=0.5; d.hl.OutlineTransparency=0
            end
        end

        if _espComps["Skeleton"] and vm then
            local function vp(partName)
                local p = vm:FindFirstChild(partName)
                if not p then return nil end
                local pos2, on = Cam:WorldToViewportPoint(p.Position)
                return on and Vector2.new(pos2.X, pos2.Y) or nil
            end
            local head=vp("head"); local torso=vp("torso")
            local arm1=vp("arm1"); local arm2=vp("arm2")
            local leg1=vp("leg1"); local leg2=vp("leg2")
            local sh1=vp("shoulder1"); local sh2=vp("shoulder2")
            local bones = {
                {head,torso},{torso,sh1 or arm1},{sh1 or torso,arm1},
                {torso,sh2 or arm2},{sh2 or torso,arm2},
                {torso,leg1},{torso,leg2},{leg1,leg2}
            }
            for i, b in ipairs(d.skel) do
                local pair = bones[i]
                if pair and pair[1] and pair[2] then
                    b.From=pair[1]; b.To=pair[2]; b.Color=col; b.Thickness=1; b.Visible=true
                else b.Visible=false end
            end
        else
            for _, b in ipairs(d.skel) do b.Visible=false end
        end
    end
end)
table.insert(_ZH.renders, "ZH_ESP_MAIN")

-- ESP UI Elements
ESPBox:AddToggle("ESPEnabled", {
    Text = "Enable ESP",
    Default = false,
    Description = "Shows players through walls",
    Callback = function(p)
        _espEnabled = p
        if p then
            for _, plr in ipairs(Players:GetPlayers()) do addESP(plr) end
            table.insert(_espConns, Players.PlayerAdded:Connect(function(plr) addESP(plr) end))
            table.insert(_espConns, Players.PlayerRemoving:Connect(function(plr) removeESP(plr) end))
            task.spawn(function()
                while _espEnabled do
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LP and not _espActive[plr] then addESP(plr) end
                    end
                    for plr in pairs(_espActive) do
                        if not plr.Parent then removeESP(plr) end
                    end
                    task.wait(1)
                end
            end)
        else
            for _, conn in ipairs(_espConns) do pcall(function() conn:Disconnect() end) end; _espConns = {}
            local list = {}; for plr in pairs(_espActive) do list[#list+1] = plr end
            for _, plr in ipairs(list) do removeESP(plr) end
        end
    end,
})

ESPBox:AddToggle("ESPTeamCheck", {
    Text = "Team Check",
    Default = false,
    Description = "Hide teammates",
    Callback = function(v) _espTeamCheck = v end,
})

ESPBox:AddSlider("ESPDist", {
    Text = "Max Distance",
    Default = 1000,
    Min = 100,
    Max = 10000,
    Decimals = 0,
    Suffix = " studs",
    Description = "ESP render distance",
    Callback = function(v) _espDist = v end,
})

-- ESP Components
CompBox:AddToggle("ESPTracers", {
    Text = "Tracers",
    Default = false,
    Description = "Line from screen to player",
    Callback = function(v) _espComps["Tracers"] = v or nil end,
})
CompBox:AddToggle("ESPOutline", {
    Text = "Outline",
    Default = false,
    Description = "Thick box outline",
    Callback = function(v) _espComps["Outline"] = v or nil end,
})
CompBox:AddToggle("ESPHighlight", {
    Text = "Highlight",
    Default = false,
    Description = "Solid fill on body",
    Callback = function(v) _espComps["Highlight"] = v or nil end,
})
CompBox:AddToggle("ESPBox", {
    Text = "Box",
    Default = true,
    Description = "2D bounding box",
    Callback = function(v) _espComps["Box"] = v or nil end,
})
CompBox:AddToggle("ESPHP", {
    Text = "HP",
    Default = false,
    Description = "Health bar (green to red)",
    Callback = function(v) _espComps["HP"] = v or nil end,
})
CompBox:AddToggle("ESPBoxHP", {
    Text = "Box HP",
    Default = false,
    Description = "Name + health text",
    Callback = function(v) _espComps["Box HP"] = v or nil end,
})
CompBox:AddToggle("ESPHeadDot", {
    Text = "Head Dot",
    Default = false,
    Description = "Dot above player",
    Callback = function(v) _espComps["Head Dot"] = v or nil end,
})
CompBox:AddToggle("ESPSkeleton", {
    Text = "Skeleton",
    Default = false,
    Description = "Lines connecting limbs",
    Callback = function(v) _espComps["Skeleton"] = v or nil end,
})
CompBox:AddToggle("ESPChams", {
    Text = "Chams",
    Default = false,
    Description = "Bright fill + white outline",
    Callback = function(v) _espComps["Chams"] = v or nil end,
})
CompBox:AddToggle("ESPRainbowOutline", {
    Text = "Rainbow Outline",
    Default = false,
    Description = "Cycling rainbow box outline",
    Callback = function(v) _espComps["Rainbow Outline"] = v or nil end,
})
CompBox:AddToggle("ESPRainbowHL", {
    Text = "Rainbow Highlight",
    Default = false,
    Description = "Vibrant cycling rainbow body fill",
    Callback = function(v) _espComps["Rainbow Highlight"] = v or nil end,
})

------------------------------------------------------------
-- AIMBOT (Main tab)
------------------------------------------------------------
local AimBox = MainTab:AddGroupbox("Aimbot")

local _aim = {
    enabled = false,
    mode = "Hold",
    part = "Head",
    smooth = 0.15,
    fov = 120,
    teamCheck = true,
    visibleCheck = false,
    active = false,
    keyHeld = false,
    priority = "Crosshair",
    prediction = 0.15,
    sticky = false,
    stickyTarget = nil,
    headOffset = 0.5,
}

local _fovCircle = Drawing.new("Circle")
_fovCircle.Thickness = 1
_fovCircle.NumSides = 64
_fovCircle.Filled = false
_fovCircle.Color = Color3.fromRGB(255,255,255)
_fovCircle.Visible = false
table.insert(_ZH.drawings, _fovCircle)
local _fovCircleEnabled = false

local function computeAimPos(plr)
    local char = getRealChar(plr)
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not (hum and hrp and hum.Health > 0) then return nil end
    local vm = getViewmodel(hrp)
    local aimPart
    if vm then
        aimPart = (_aim.part == "Head" and vm:FindFirstChild("head")) or vm:FindFirstChild("torso") or vm:FindFirstChild("head")
    end
    if not aimPart then aimPart = hrp end
    local pos = aimPart.Position
    if _aim.part == "Head" and aimPart.Name == "head" then
        pos = pos - Vector3.new(0, _aim.headOffset, 0)
    end
    if _aim.prediction > 0 then
        local ping = LP:GetNetworkPing()
        local vel = hrp.AssemblyLinearVelocity
        pos = pos + vel * (_aim.prediction + ping)
    end
    return pos, aimPart, hum
end

local function posVisible(pos)
    if not _aim.visibleCheck then return true end
    local origin = Cam.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = { LP.Character }
    if _vmFolder then table.insert(ignore, _vmFolder) end
    params.FilterDescendantsInstances = ignore
    local res = workspace:Raycast(origin, pos - origin, params)
    if not res then return true end
    return (res.Position - pos).Magnitude < 6
end

local function getAimTarget()
    local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    if _aim.sticky and _aim.stickyTarget then
        local plr = _aim.stickyTarget
        if plr and plr.Parent and (not _aim.teamCheck or plr.Team ~= LP.Team) then
            local pos, part, hum = computeAimPos(plr)
            if pos then
                local sp = Cam:WorldToViewportPoint(pos)
                local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if d <= _aim.fov and posVisible(pos) then
                    _aim._aimPos = pos
                    return part
                end
            end
        end
        _aim.stickyTarget = nil
    end
    local best, bestScore, bestPos, bestPlr
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        if _aim.teamCheck and plr.Team == LP.Team then continue end
        local pos, part, hum = computeAimPos(plr)
        if not pos then continue end
        local sp, onScreen = Cam:WorldToViewportPoint(pos)
        if not onScreen then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d > _aim.fov then continue end
        if not posVisible(pos) then continue end
        local score
        if _aim.priority == "Distance" then
            local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local tHRP = getRealChar(plr) and getRealChar(plr):FindFirstChild("HumanoidRootPart")
            score = (myHRP and tHRP) and (myHRP.Position - tHRP.Position).Magnitude or d
        elseif _aim.priority == "Low HP" then
            score = hum.Health
        else
            score = d
        end
        if not bestScore or score < bestScore then
            bestScore = score; best = part; bestPos = pos; bestPlr = plr
        end
    end
    if best then
        _aim._aimPos = bestPos
        if _aim.sticky then _aim.stickyTarget = bestPlr end
    end
    return best
end

-- Aimbot render loop
RunService:BindToRenderStep("ZH_AIMBOT", Enum.RenderPriority.Camera.Value + 2, function()
    if _ZH.dead then return end
    if _fovCircleEnabled and _aim.enabled then
        _fovCircle.Radius = _aim.fov
        _fovCircle.Position = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
        _fovCircle.Visible = true
    else
        _fovCircle.Visible = false
    end
    if not _aim.enabled then return end
    local shouldLock
    if _aim.mode == "Always" then shouldLock = true
    elseif _aim.mode == "Hold" then shouldLock = _aim.keyHeld
    else shouldLock = _aim.active end
    if not shouldLock then return end
    local target = getAimTarget()
    if not target then return end
    local aimPos = _aim._aimPos or target.Position
    local camCF = Cam.CFrame
    local goal = CFrame.new(camCF.Position, aimPos)
    local alpha = (_aim.smooth <= 0) and 1 or math.clamp(1 - _aim.smooth, 0.05, 1)
    Cam.CFrame = camCF:Lerp(goal, alpha)
end)
table.insert(_ZH.renders, "ZH_AIMBOT")

-- Aimbot input handling (Hold / Toggle via MB2)
local function aimKeyMatches(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then return true end
    return false
end
table.insert(_ZH.conns, UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if _aim.mode == "Hold" and aimKeyMatches(input) then _aim.keyHeld = true end
    if _aim.mode == "Toggle" and input.UserInputType == Enum.UserInputType.MouseButton2 then
        _aim.active = not _aim.active
    end
end))
table.insert(_ZH.conns, UIS.InputEnded:Connect(function(input)
    if aimKeyMatches(input) then _aim.keyHeld = false end
end))

-- Aimbot UI elements
AimBox:AddToggle("AimbotEnabled", {
    Text = "Enable Aimbot",
    Default = false,
    Description = "Locks camera to nearest enemy",
    Callback = function(v)
        _aim.enabled = v
        if v and _aim.mode == "Always" then _aim.active = true end
    end,
})

AimBox:AddDropdown("AimMode", {
    Text = "Aim Mode",
    Values = {"Hold", "Toggle", "Always"},
    Default = "Hold",
    Description = "How aiming triggers",
    Callback = function(v)
        _aim.mode = v
        _aim.active = (v == "Always")
        _aim.keyHeld = false
    end,
})

AimBox:AddDropdown("AimPart", {
    Text = "Aim Part",
    Values = {"Head", "Torso"},
    Default = "Head",
    Description = "Where to aim",
    Callback = function(v) _aim.part = v end,
})

AimBox:AddDropdown("AimPriority", {
    Text = "Target Priority",
    Values = {"Crosshair", "Distance", "Low HP"},
    Default = "Crosshair",
    Description = "How to pick targets",
    Callback = function(v) _aim.priority = v end,
})

AimBox:AddSlider("AimSmooth", {
    Text = "Smoothness",
    Default = 15,
    Min = 0,
    Max = 95,
    Decimals = 0,
    Suffix = "%",
    Description = "0 = instant, higher = smoother",
    Callback = function(v) _aim.smooth = v / 100 end,
})

AimBox:AddSlider("AimFOV", {
    Text = "FOV",
    Default = 120,
    Min = 10,
    Max = 500,
    Decimals = 0,
    Suffix = "px",
    Description = "Lock radius in pixels",
    Callback = function(v) _aim.fov = v end,
})

AimBox:AddSlider("AimPrediction", {
    Text = "Prediction",
    Default = 15,
    Min = 0,
    Max = 60,
    Decimals = 0,
    Suffix = "%",
    Description = "Lead moving targets (0 = off)",
    Callback = function(v) _aim.prediction = v / 100 end,
})

AimBox:AddSlider("AimHeadOffset", {
    Text = "Head Offset",
    Default = 5,
    Min = 0,
    Max = 20,
    Decimals = 0,
    Description = "Lower head aim point",
    Callback = function(v) _aim.headOffset = v / 10 end,
})

AimBox:AddDivider()

AimBox:AddToggle("AimFOVCircle", {
    Text = "Show FOV Circle",
    Default = false,
    Description = "Draw the FOV radius",
    Callback = function(v) _fovCircleEnabled = v end,
})

AimBox:AddToggle("AimTeamCheck", {
    Text = "Team Check",
    Default = true,
    Description = "Don't aim at teammates",
    Callback = function(v) _aim.teamCheck = v end,
})

AimBox:AddToggle("AimVisibleCheck", {
    Text = "Visible Check",
    Default = false,
    Description = "Only aim at visible enemies",
    Callback = function(v) _aim.visibleCheck = v end,
})

AimBox:AddToggle("AimSticky", {
    Text = "Sticky Target",
    Default = false,
    Description = "Stay locked on one target",
    Callback = function(v) _aim.sticky = v; _aim.stickyTarget = nil end,
})

------------------------------------------------------------
-- SILENT AIM
------------------------------------------------------------
local SilentBox = MainTab:AddGroupbox("Silent Aim")

local _silentAim = { enabled = false, hookInstalled = false }
_G.SilentAimTarget = nil

local function installSilentAimHook()
    if _silentAim.hookInstalled then return true end
    local actor = LP:FindFirstChildWhichIsA('Actor', true)
    if not actor then return false end
    if not run_on_actor then return false end
    run_on_actor(actor, [[
        local old_shootLook = nil;
        local new_shootLook = function(...)
            local returned = { old_shootLook(...) };
            local gunData  = ...;
            if (type(gunData) ~= 'table' or typeof(returned[1]) ~= 'CFrame') then
                return unpack(returned);
            end;
            local target = _G.SilentAimTarget;
            if not target then
                return unpack(returned);
            end;
            return CFrame.new(returned[1].Position, target);
        end;
        local gunHandler = require( game:GetService('ReplicatedStorage').Modules.Items.Item.Gun );
        old_shootLook = hookfunction( rawget(gunHandler, 'get_shoot_look'), new_shootLook);
    ]]);
    _silentAim.hookInstalled = true
    return true
end

local _silentAimConn = nil
local function startSilentAimLoop()
    if _silentAimConn then return end
    _silentAimConn = RunService.Heartbeat:Connect(function()
        if not _silentAim.enabled then _G.SilentAimTarget = nil; return end
        local best, bestDist = nil, math.huge
        local center = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                if _aim.teamCheck and plr.Team and plr.Team == LP.Team then continue end
                local char = getRealChar(plr)
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if char and hum and hum.Health > 0 then
                    local head = char:FindFirstChild("head") or char:FindFirstChild("Head")
                    if head then
                        local sv, onS = Cam:WorldToViewportPoint(head.Position)
                        if onS then
                            local d = (Vector2.new(sv.X, sv.Y) - center).Magnitude
                            if d < bestDist then best, bestDist = head, d end
                        end
                    end
                end
            end
        end
        _G.SilentAimTarget = best and best.Position or nil
    end)
    table.insert(_ZH.conns, _silentAimConn)
end

SilentBox:AddToggle("SilentAim", {
    Text = "Silent Aim",
    Default = false,
    Description = "Redirects bullets to nearest enemy",
    Callback = function(v)
        _silentAim.enabled = v
        if v then
            if not installSilentAimHook() then
                _silentAim.enabled = false
                return
            end
            startSilentAimLoop()
        else
            _G.SilentAimTarget = nil
        end
    end,
})

------------------------------------------------------------
-- TRIGGERBOT
------------------------------------------------------------
local TrigBox = TrigTab:AddGroupbox("Triggerbot")

local _trig = {
    enabled = false,
    mode = "Hold",
    delay = 30,
    teamCheck = true,
    keyHeld = false,
    lastShot = 0,
    cooldown = 80,
}

local _VIM = game:GetService("VirtualInputManager")

local function viewmodelToPlayer(vm)
    local head = vm:FindFirstChild("head") or vm:FindFirstChild("torso")
    if not head then return nil end
    local best, bestD = nil, 12
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local char = getRealChar(plr)
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local d = (head.Position - hrp.Position).Magnitude
        if d < bestD then best = plr; bestD = d end
    end
    return best
end

local function targetUnderCrosshair()
    local origin = Cam.CFrame.Position
    local dir = Cam.CFrame.LookVector * 2000
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = { LP.Character }
    params.FilterDescendantsInstances = ignore
    local res = workspace:Raycast(origin, dir, params)
    if not res then return nil end
    local vm = res.Instance:FindFirstAncestor("Viewmodel")
    if not vm and res.Instance.Parent and res.Instance.Parent:GetAttribute("Viewmodels") then vm = res.Instance.Parent end
    if not vm then
        local cur = res.Instance
        while cur and cur.Parent do
            if cur:GetAttribute("Viewmodels") then vm = cur; break end
            cur = cur.Parent
        end
    end
    if not vm then return nil end
    local plr = viewmodelToPlayer(vm)
    if not plr then return nil end
    if _trig.teamCheck and plr.Team == LP.Team then return nil end
    local char = getRealChar(plr)
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (hum and hum.Health > 0) then return nil end
    return plr
end

local function simClick()
    pcall(function()
        _VIM:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait()
        _VIM:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

local _trigAcquiredAt = nil
RunService:BindToRenderStep("ZH_TRIGGER", Enum.RenderPriority.Camera.Value + 3, function()
    if _ZH.dead then return end
    if not _trig.enabled then return end
    local shouldRun, target
    if _trig.mode == "Silent Aim" then
        shouldRun = _silentAim.enabled and _G.SilentAimTarget ~= nil
        target = _G.SilentAimTarget
    elseif _trig.mode == "Always" then
        shouldRun = true
        target = targetUnderCrosshair()
    else
        shouldRun = _trig.keyHeld
        target = shouldRun and targetUnderCrosshair() or nil
    end
    if not shouldRun then _trigAcquiredAt = nil; return end
    if not target then _trigAcquiredAt = nil; return end
    local now = tick() * 1000
    if not _trigAcquiredAt then _trigAcquiredAt = now; return end
    if now - _trigAcquiredAt < _trig.delay then return end
    if now - _trig.lastShot < _trig.cooldown then return end
    _trig.lastShot = now
    task.spawn(simClick)
end)
table.insert(_ZH.renders, "ZH_TRIGGER")

-- Triggerbot hold key (default C)
table.insert(_ZH.conns, UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if _trig.mode ~= "Hold" then return end
    if input.KeyCode == Enum.KeyCode.C then _trig.keyHeld = true end
end))
table.insert(_ZH.conns, UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.C then _trig.keyHeld = false end
end))

-- Triggerbot UI elements
TrigBox:AddToggle("TriggerEnabled", {
    Text = "Enable Triggerbot",
    Default = false,
    Callback = function(v) _trig.enabled = v end,
})

TrigBox:AddDropdown("TriggerMode", {
    Text = "Trigger Mode",
    Values = {"Hold", "Always", "Silent Aim"},
    Default = "Hold",
    Callback = function(v) _trig.mode = v; _trig.keyHeld = false end,
})

TrigBox:AddSlider("TriggerDelay", {
    Text = "Trigger Delay",
    Default = 30,
    Min = 0,
    Max = 500,
    Decimals = 0,
    Suffix = "ms",
    Description = "Reaction delay in ms",
    Callback = function(v) _trig.delay = v end,
})

TrigBox:AddSlider("TriggerCooldown", {
    Text = "Fire Rate",
    Default = 80,
    Min = 30,
    Max = 500,
    Decimals = 0,
    Suffix = "ms",
    Description = "Min ms between shots",
    Callback = function(v) _trig.cooldown = v end,
})

TrigBox:AddToggle("TriggerTeamCheck", {
    Text = "Team Check",
    Default = true,
    Description = "Don't fire at teammates",
    Callback = function(v) _trig.teamCheck = v end,
})

------------------------------------------------------------
-- CHARACTER (Movement)
------------------------------------------------------------
local MoveBox = CharacterTab:AddGroupbox("Movement")

local _flySpeed = 100
local _speed = 100
local _infJumpH = 50

MoveBox:AddToggle("Fly", {
    Text = "Fly",
    Default = false,
    Description = "Toggle flight",
    Callback = function(p)
        if p then
            RunService:BindToRenderStep("ZHFly", Enum.RenderPriority.Input.Value, function(dt)
                local c = LP.Character; if not c then return end
                local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if not getgenv()._ZH_flyFrame then getgenv()._ZH_flyFrame = hrp.CFrame end
                local frame = getgenv()._ZH_flyFrame
                local cf = Cam.CFrame
                local mv = Vector3.zero
                local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
                local rgt = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z).Unit
                if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + fwd end
                if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - fwd end
                if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - rgt end
                if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + rgt end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.yAxis end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.yAxis end
                if mv.Magnitude > 0 then frame = frame + mv.Unit * _flySpeed * dt end
                local fwd3 = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
                if fwd3.Magnitude > 0 then frame = CFrame.new(frame.Position, frame.Position + fwd3.Unit) end
                getgenv()._ZH_flyFrame = frame
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.CFrame = frame
            end)
        else
            RunService:UnbindFromRenderStep("ZHFly")
            getgenv()._ZH_flyFrame = nil
        end
    end,
})

MoveBox:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = 100,
    Min = 0,
    Max = 5000,
    Decimals = 0,
    Callback = function(v) _flySpeed = v end,
})

MoveBox:AddToggle("Speedhack", {
    Text = "Speedhack",
    Default = false,
    Description = "Move faster",
    Callback = function(p)
        if p then
            RunService:BindToRenderStep("ZHSpeed", Enum.RenderPriority.Input.Value, function(dt)
                local c = LP.Character; if not c then return end
                local hum = c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health <= 0 then return end
                local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if hum.MoveDirection.Magnitude > 0 then hrp.CFrame = hrp.CFrame + hum.MoveDirection * _speed * dt end
            end)
        else
            RunService:UnbindFromRenderStep("ZHSpeed")
        end
    end,
})

MoveBox:AddSlider("SpeedhackSpeed", {
    Text = "Speed",
    Default = 100,
    Min = 0,
    Max = 5000,
    Decimals = 0,
    Callback = function(v) _speed = v end,
})

local _ijConn = nil
MoveBox:AddToggle("InfiniteJump", {
    Text = "Infinite Jump",
    Default = false,
    Callback = function(p)
        if _ijConn then _ijConn:Disconnect(); _ijConn = nil end
        if p then
            _ijConn = UIS.InputBegan:Connect(function(input, gpe)
                if gpe or input.KeyCode ~= Enum.KeyCode.Space then return end
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, _infJumpH, hrp.AssemblyLinearVelocity.Z)
            end)
        end
    end,
})

MoveBox:AddSlider("InfJumpHeight", {
    Text = "Jump Height",
    Default = 50,
    Min = 0,
    Max = 1000,
    Decimals = 0,
    Callback = function(v) _infJumpH = v end,
})

------------------------------------------------------------
-- MISC
------------------------------------------------------------
local StatusBox = MiscTab:AddGroupbox("Anti Status")

local _noSlowConn = nil
StatusBox:AddToggle("NoSlow", {
    Text = "No Slow",
    Default = false,
    Description = "Removes slow/stun/freeze",
    Callback = function(p)
        if _noSlowConn then _noSlowConn:Disconnect(); _noSlowConn = nil end
        if not p then return end
        _noSlowConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local c = LP.Character; if not c then return end
                local status = c:FindFirstChild("Status"); if not status then return end
                for _, v in ipairs(status:GetChildren()) do
                    local n = v.Name:lower()
                    if n:find("slow") or n:find("stun") or n:find("freeze") or n:find("root") or n:find("immobil") then
                        pcall(function() v:Destroy() end)
                    end
                end
                local hum = c:FindFirstChildOfClass("Humanoid")
                if hum and hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
            end)
        end)
    end,
})

-- Anti Grenade Effects
local GrenadeBox = MiscTab:AddGroupbox("Anti Grenades")

-- Anti Flashbang: forces PlayerGui.Flash.Frame to stay transparent
local _antiFlashConn = nil
local _antiFlashChildConn = nil
GrenadeBox:AddToggle("AntiFlash", {
    Text = "Anti Flashbang",
    Default = false,
    Description = "Blocks flashbang white/black screen",
    Callback = function(p)
        if _antiFlashConn then _antiFlashConn:Disconnect(); _antiFlashConn = nil end
        if _antiFlashChildConn then _antiFlashChildConn:Disconnect(); _antiFlashChildConn = nil end
        if not p then return end

        local function blockFlash()
            local pg = LP:FindFirstChild("PlayerGui")
            if not pg then return end
            local flashGui = pg:FindFirstChild("Flash")
            if not flashGui then return end
            local frame = flashGui:FindFirstChild("Frame")
            if not frame then return end
            -- Force transparency to 1 (invisible) every frame
            frame.BackgroundTransparency = 1
        end

        -- Run every render step to override the tween
        _antiFlashConn = RunService.RenderStepped:Connect(blockFlash)

        -- Also watch for the Flash GUI being re-created
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then
            _antiFlashChildConn = pg.DescendantAdded:Connect(function(desc)
                if desc.Name == "Frame" and desc.Parent and desc.Parent.Name == "Flash" then
                    task.defer(function() desc.BackgroundTransparency = 1 end)
                end
            end)
        end
    end,
})

-- Anti Smoke: removes/hides SmokePart instances from workspace
local _antiSmokeConn = nil
local _antiSmokeChildConn = nil
GrenadeBox:AddToggle("AntiSmoke", {
    Text = "Anti Smoke Screen",
    Default = false,
    Description = "Removes smoke grenade clouds",
    Callback = function(p)
        if _antiSmokeConn then _antiSmokeConn:Disconnect(); _antiSmokeConn = nil end
        if _antiSmokeChildConn then _antiSmokeChildConn:Disconnect(); _antiSmokeChildConn = nil end
        if not p then return end

        local function nukeSmoke(part)
            if part.Name == "SmokePart" and part:IsA("BasePart") then
                pcall(function() part.Transparency = 1 end)
                pcall(function() part.CanCollide = false end)
            end
        end

        -- Clear any existing smoke parts
        for _, v in ipairs(workspace:GetChildren()) do
            nukeSmoke(v)
        end

        -- Catch new smoke parts as they spawn
        _antiSmokeChildConn = workspace.ChildAdded:Connect(function(child)
            task.defer(function() nukeSmoke(child) end)
        end)

        -- Also sweep every second in case any slip through
        _antiSmokeConn = RunService.Heartbeat:Connect(function()
            for _, v in ipairs(workspace:GetChildren()) do
                if v.Name == "SmokePart" and v:IsA("BasePart") and v.Transparency < 1 then
                    pcall(function() v.Transparency = 1 end)
                    pcall(function() v.CanCollide = false end)
                end
            end
        end)
    end,
})

-- World Visuals
local LT = game:GetService("Lighting")
local WorldBox = MiscTab:AddGroupbox("World")

local _noFogConn = nil
WorldBox:AddToggle("NoFog", {
    Text = "No Fog",
    Default = false,
    Description = "Removes all fog and haze",
    Callback = function(p)
        if _noFogConn then _noFogConn:Disconnect(); _noFogConn = nil end
        local atmos = LT:FindFirstChildOfClass("Atmosphere")
        if p then
            LT.FogStart = 1e9; LT.FogEnd = 1e9
            if atmos then atmos.Density = 0; atmos.Haze = 0; atmos.Glare = 0 end
            _noFogConn = LT:GetPropertyChangedSignal("FogEnd"):Connect(function()
                if LT.FogEnd < 1e8 then LT.FogStart = 1e9; LT.FogEnd = 1e9 end
            end)
        else
            LT.FogStart = 0; LT.FogEnd = 100000
        end
    end,
})

local _fbConn = nil
local _brightness = 2
WorldBox:AddToggle("FullBright", {
    Text = "FullBright",
    Default = false,
    Description = "Removes darkness/shadows",
    Callback = function(p)
        if _fbConn then _fbConn:Disconnect(); _fbConn = nil end
        if p then
            _fbConn = RunService.RenderStepped:Connect(function()
                LT.Brightness = _brightness; LT.ClockTime = 14; LT.GlobalShadows = false
                LT.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
            end)
        else
            LT.Brightness = 1; LT.GlobalShadows = true
        end
    end,
})

WorldBox:AddSlider("Brightness", {
    Text = "Brightness",
    Default = 2,
    Min = 0,
    Max = 10,
    Decimals = 0,
    Description = "FullBright intensity",
    Callback = function(v) _brightness = v end,
})

local _ambientConn = nil
local _ambR, _ambG, _ambB = 150, 150, 150
local function _ambColor() return Color3.fromRGB(_ambR, _ambG, _ambB) end

WorldBox:AddToggle("AmbientToggle", {
    Text = "Ambient Color",
    Default = false,
    Description = "Tint the world lighting",
    Callback = function(p)
        if _ambientConn then _ambientConn:Disconnect(); _ambientConn = nil end
        if p then
            _ambientConn = RunService.RenderStepped:Connect(function()
                local c = _ambColor(); LT.Ambient = c; LT.OutdoorAmbient = c
            end)
        else
            LT.Ambient = Color3.fromRGB(0, 0, 0); LT.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        end
    end,
})

WorldBox:AddSlider("AmbientR", {
    Text = "Ambient R",
    Default = 150,
    Min = 0,
    Max = 255,
    Decimals = 0,
    Description = "Red",
    Callback = function(v) _ambR = v end,
})

WorldBox:AddSlider("AmbientG", {
    Text = "Ambient G",
    Default = 150,
    Min = 0,
    Max = 255,
    Decimals = 0,
    Description = "Green",
    Callback = function(v) _ambG = v end,
})

WorldBox:AddSlider("AmbientB", {
    Text = "Ambient B",
    Default = 150,
    Min = 0,
    Max = 255,
    Decimals = 0,
    Description = "Blue",
    Callback = function(v) _ambB = v end,
})

local _bloomToggle = false
local _bloom = LT:FindFirstChildOfClass("BloomEffect")

WorldBox:AddToggle("BloomToggle", {
    Text = "Bloom",
    Default = false,
    Description = "Glow/bloom effect",
    Callback = function(p)
        _bloomToggle = p
        if not _bloom then _bloom = LT:FindFirstChildOfClass("BloomEffect") end
        if not _bloom then _bloom = Instance.new("BloomEffect"); _bloom.Parent = LT end
        _bloom.Enabled = p
    end,
})

WorldBox:AddSlider("BloomIntensity", {
    Text = "Bloom Intensity",
    Default = 1,
    Min = 0,
    Max = 10,
    Decimals = 0,
    Callback = function(v)
        if not _bloom then _bloom = LT:FindFirstChildOfClass("BloomEffect") end
        if _bloom then _bloom.Intensity = v end
    end,
})

WorldBox:AddSlider("BloomSize", {
    Text = "Bloom Size",
    Default = 24,
    Min = 0,
    Max = 56,
    Decimals = 0,
    Callback = function(v)
        if not _bloom then _bloom = LT:FindFirstChildOfClass("BloomEffect") end
        if _bloom then _bloom.Size = v end
    end,
})

------------------------------------------------------------
-- SETTINGS (built-in EthosSuite config system)
------------------------------------------------------------
Library:CreateSettingsTab(Window)

------------------------------------------------------------
-- NOTIFY
------------------------------------------------------------
Library:Notify({
    Title = "Zero Hub",
    Description = "Loaded — Operation One",
    Type = "Success",
    Duration = 3,
})
