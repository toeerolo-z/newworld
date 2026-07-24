local oldStrByte; oldStrByte = hookfunction(string.byte, newcclosure(function(a0, a1)
    if (checkcaller() or type(a0) ~= 'string' or not (a0:sub(1, 1) == '{' and a0:sub(-1) == '}')) then return oldStrByte(a0, a1) end
    local luraph = getstack(3, 1)
    luraph[1] = luraph[2]
    luraph[5] = #luraph[2]
    setstack(3, 4, luraph[5])
    return oldStrByte(luraph[1], a1)
end))

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/toeerolo-z/ethossuiterewrite/refs/heads/main/ethossuite.lua"))()

local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

local Window = Library:CreateWindow({
    Title = "ZERO HUB",
    Version = "v1.1.1",
    GameName = "Operation One",
})

local CatMain    = Window:AddCategory("MAIN")
local CatVisuals = Window:AddCategory("VISUALS")
local CatMisc    = Window:AddCategory("MISC")

local CombatTab  = CatMain:AddTab("Combat")
local PEspTab    = CatVisuals:AddTab("Player ESP")
local EspCfgTab  = CatVisuals:AddTab("ESP Config")
local WorldTab   = CatVisuals:AddTab("World")
local MoveTab    = CatMisc:AddTab("Movement")
local UtilTab    = CatMisc:AddTab("Utility")

local _vmFolder = workspace:FindFirstChild("Viewmodels")

local function getRealChar(plr)
    local uid = plr.UserId
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("Model") and v:GetAttribute("UserId") == uid and v:FindFirstChild("Animate") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChildOfClass("Humanoid") then
            return v
        end
    end
    return nil
end

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

local _espCfg = {
    boxes = true, outline = false, hpBar = false, boxHP = false, tracers = false, headDot = false,
    highlight = false, chams = false, rainbowOutline = false, rainbowHighlight = false, skeleton = false,
    maxDist = 1000, teamCheck = false,
}

local _hue = 0
RunService.Heartbeat:Connect(function(dt) _hue = (_hue + dt * 0.25) % 1 end)

local function makeDrawingSet()
    local txt = Drawing.new("Text"); txt.Center = true; txt.Outline = true; txt.Visible = false; txt.Size = 14
    local box = Drawing.new("Square"); box.Filled = false; box.Thickness = 1.5; box.Visible = false
    local outl = Drawing.new("Square"); outl.Filled = false; outl.Thickness = 3; outl.Visible = false
    local hpFill = Drawing.new("Square"); hpFill.Filled = true; hpFill.Visible = false
    local hpBack = Drawing.new("Square"); hpBack.Filled = false; hpBack.Thickness = 1; hpBack.Color = Color3.new(0, 0, 0); hpBack.Visible = false
    local tracer = Drawing.new("Line"); tracer.Thickness = 1; tracer.Visible = false
    local dot = Drawing.new("Circle"); dot.Radius = 4; dot.Filled = true; dot.Visible = false; dot.Thickness = 1
    local hl = Instance.new("Highlight"); hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.Enabled = false
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = game:GetService("CoreGui")
    local skel = {}
    for i = 1, 8 do local l = Drawing.new("Line"); l.Thickness = 1; l.Visible = false; skel[i] = l end
    return { txt = txt, box = box, outline = outl, hpFill = hpFill, hpBack = hpBack, tracer = tracer, dot = dot, hl = hl, skel = skel }
end

local function hideAll(d)
    d.txt.Visible = false; d.box.Visible = false; d.outline.Visible = false
    d.hpFill.Visible = false; d.hpBack.Visible = false; d.tracer.Visible = false; d.dot.Visible = false
    d.hl.Enabled = false
    for _, b in ipairs(d.skel) do b.Visible = false end
end

local function destroyDrawingSet(d)
    for _, k in ipairs({"txt", "box", "outline", "hpFill", "hpBack", "tracer", "dot"}) do pcall(function() d[k]:Remove() end) end
    for _, b in ipairs(d.skel) do pcall(function() b:Remove() end) end
    pcall(function() d.hl:Destroy() end)
end

local function getCol(plr)
    if _espCfg.rainbowOutline then return Color3.fromHSV(_hue, 1, 1) end
    if plr and plr.Team then
        if plr.Team.Name == "Red" then return Color3.fromRGB(255, 80, 80) end
        return Color3.fromRGB(80, 160, 255)
    end
    return Color3.fromRGB(255, 255, 255)
end

local _espEnabled = false
local _espActive = {}
local _espConns = {}

local function removeESP(plr)
    local d = _espActive[plr]; if not d then return end
    destroyDrawingSet(d)
    if d.rname then pcall(function() RunService:UnbindFromRenderStep(d.rname) end) end
    _espActive[plr] = nil
end

local function addESP(plr)
    if not plr or plr == LP or _espActive[plr] then return end
    local d = makeDrawingSet()
    local rname = "ZH_ESP_" .. plr.UserId

    RunService:BindToRenderStep(rname, Enum.RenderPriority.Camera.Value + 1, function()
        if not (_espEnabled and plr and plr.Parent and plr ~= LP) then hideAll(d); return end
        if _espCfg.teamCheck and plr.Team and plr.Team == LP.Team then hideAll(d); return end
        local char = getRealChar(plr)
        if not char then hideAll(d); return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not (hum and hrp and hum.Health > 0) then hideAll(d); return end
        local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then hideAll(d); return end
        local dist = (hrp.Position - myHRP.Position).Magnitude
        if dist > _espCfg.maxDist then hideAll(d); return end
        local sv, onScreen = Cam:WorldToViewportPoint(hrp.Position)
        if not onScreen then hideAll(d); return end

        local vm = getViewmodel(hrp)
        local col = getCol(plr)
        local maxHP = math.max(hum.MaxHealth, 1)
        local hpPct = math.clamp(hum.Health / maxHP, 0, 1)
        local hpCol = Color3.fromHSV(hpPct * 0.33, 1, 1)
        local bx, by, bw, bh = sv.X - 25, sv.Y - 35, 50, 70

        if _espCfg.boxes then
            d.box.Position = Vector2.new(bx, by); d.box.Size = Vector2.new(bw, bh); d.box.Color = col; d.box.Visible = true
        else d.box.Visible = false end

        if _espCfg.outline or _espCfg.rainbowOutline then
            local oc = _espCfg.rainbowOutline and Color3.fromHSV(_hue, 1, 1) or col
            d.outline.Position = Vector2.new(bx - 1, by - 1); d.outline.Size = Vector2.new(bw + 2, bh + 2); d.outline.Color = oc; d.outline.Visible = true
        else d.outline.Visible = false end

        if _espCfg.hpBar then
            local barW, barX = 4, bx - 8
            d.hpBack.Position = Vector2.new(barX - 1, by - 1); d.hpBack.Size = Vector2.new(barW + 2, bh + 2); d.hpBack.Visible = true
            d.hpFill.Position = Vector2.new(barX, by + bh * (1 - hpPct)); d.hpFill.Size = Vector2.new(barW, bh * hpPct); d.hpFill.Color = hpCol; d.hpFill.Visible = true
        else d.hpFill.Visible = false; d.hpBack.Visible = false end

        if _espCfg.boxHP then
            d.txt.Text = string.format("%s [%d/%d] [%.0fm]", plr.DisplayName, hum.Health, hum.MaxHealth, dist)
        elseif _espCfg.boxes or _espCfg.outline then
            d.txt.Text = string.format("%s [%.0fm]", plr.DisplayName, dist)
        else d.txt.Visible = false end
        if _espCfg.boxHP or _espCfg.boxes or _espCfg.outline then
            d.txt.Color = col; d.txt.Size = 14; d.txt.Position = Vector2.new(sv.X, by - 18); d.txt.Visible = true
        end

        if _espCfg.tracers then
            d.tracer.From = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y)
            d.tracer.To = Vector2.new(sv.X, sv.Y + bh / 2); d.tracer.Color = col; d.tracer.Visible = true
        else d.tracer.Visible = false end

        if _espCfg.headDot then
            d.dot.Position = Vector2.new(sv.X, sv.Y - bh / 2 - 5); d.dot.Color = col; d.dot.Visible = true
        else d.dot.Visible = false end

        local hlActive = _espCfg.highlight or _espCfg.rainbowHighlight or _espCfg.chams
        d.hl.Adornee = char; d.hl.Enabled = hlActive
        if hlActive then
            if _espCfg.rainbowHighlight then
                local rc = Color3.fromHSV(_hue, 1, 1)
                d.hl.FillColor = rc; d.hl.OutlineColor = rc; d.hl.FillTransparency = 0.25; d.hl.OutlineTransparency = 0
            elseif _espCfg.chams then
                d.hl.FillColor = col; d.hl.OutlineColor = Color3.new(1, 1, 1); d.hl.FillTransparency = 0.15; d.hl.OutlineTransparency = 0
            else
                d.hl.FillColor = col; d.hl.OutlineColor = col; d.hl.FillTransparency = 0.5; d.hl.OutlineTransparency = 0
            end
        end

        if _espCfg.skeleton and vm then
            local function vp(partName)
                local p = vm:FindFirstChild(partName); if not p then return nil end
                local pos2, on = Cam:WorldToViewportPoint(p.Position)
                return on and Vector2.new(pos2.X, pos2.Y) or nil
            end
            local head2 = vp("head"); local torso = vp("torso")
            local arm1 = vp("arm1"); local arm2 = vp("arm2")
            local leg1 = vp("leg1"); local leg2 = vp("leg2")
            local sh1 = vp("shoulder1"); local sh2 = vp("shoulder2")
            local bones = {
                {head2, torso}, {torso, sh1 or arm1}, {sh1 or torso, arm1},
                {torso, sh2 or arm2}, {sh2 or torso, arm2},
                {torso, leg1}, {torso, leg2}, {leg1, leg2}
            }
            for i, b in ipairs(d.skel) do
                local pair = bones[i]
                if pair and pair[1] and pair[2] then
                    b.From = pair[1]; b.To = pair[2]; b.Color = col; b.Thickness = 1; b.Visible = true
                else b.Visible = false end
            end
        else
            for _, b in ipairs(d.skel) do b.Visible = false end
        end
    end)

    d.rname = rname
    _espActive[plr] = d
end

local function hookPlayer(plr)
    if plr == LP then return end
    addESP(plr)
end

local PlayerEspBox = PEspTab:AddGroupbox("Player ESP")

PlayerEspBox:AddToggle("ESPEnabled", {
    Text = "Player ESP", Default = false, Description = "Shows players through walls",
    Callback = function(v)
        _espEnabled = v
        if v then
            for _, plr in ipairs(Players:GetPlayers()) do hookPlayer(plr) end
            table.insert(_espConns, Players.PlayerAdded:Connect(hookPlayer))
            table.insert(_espConns, Players.PlayerRemoving:Connect(function(plr) removeESP(plr) end))
        else
            for _, c in ipairs(_espConns) do pcall(function() c:Disconnect() end) end; _espConns = {}
            local l = {}; for plr in pairs(_espActive) do l[#l + 1] = plr end
            for _, plr in ipairs(l) do removeESP(plr) end
        end
    end,
})

PlayerEspBox:AddToggle("ESPTeamCheck", { Text = "Team Check", Default = false, Description = "Hide teammates",
    Callback = function(v) _espCfg.teamCheck = v end })

PlayerEspBox:AddSlider("ESPDist", { Text = "Max Distance", Default = 1000, Min = 100, Max = 10000, Decimals = 0, Suffix = " studs",
    Callback = function(v) _espCfg.maxDist = v end })

local CompBox = EspCfgTab:AddGroupbox("Components")
local EffectsBox = EspCfgTab:AddGroupbox("Effects")

CompBox:AddToggle("CfgBox", { Text = "Box", Default = true, Callback = function(v) _espCfg.boxes = v end })
CompBox:AddToggle("CfgOutline", { Text = "Outline", Default = false, Callback = function(v) _espCfg.outline = v end })
CompBox:AddToggle("CfgHP", { Text = "HP Bar", Default = false, Callback = function(v) _espCfg.hpBar = v end })
CompBox:AddToggle("CfgBoxHP", { Text = "Box HP", Default = false, Description = "Name + health text", Callback = function(v) _espCfg.boxHP = v end })
CompBox:AddToggle("CfgTracers", { Text = "Tracers", Default = false, Callback = function(v) _espCfg.tracers = v end })
CompBox:AddToggle("CfgHeadDot", { Text = "Head Dot", Default = false, Callback = function(v) _espCfg.headDot = v end })
CompBox:AddToggle("CfgSkeleton", { Text = "Skeleton", Default = false, Callback = function(v) _espCfg.skeleton = v end })

EffectsBox:AddToggle("CfgHighlight", { Text = "Highlight", Default = false, Callback = function(v) _espCfg.highlight = v end })
EffectsBox:AddToggle("CfgChams", { Text = "Chams", Default = false, Description = "Bright fill + white outline", Callback = function(v) _espCfg.chams = v end })
EffectsBox:AddToggle("CfgRainbowOutline", { Text = "Rainbow Outline", Default = false, Callback = function(v) _espCfg.rainbowOutline = v end })
EffectsBox:AddToggle("CfgRainbowHL", { Text = "Rainbow Highlight", Default = false, Callback = function(v) _espCfg.rainbowHighlight = v end })

local AimBox = CombatTab:AddGroupbox("Aimbot")

local _aim = {
    enabled = false, mode = "Hold", part = "Head", smooth = 0.15, fov = 120,
    teamCheck = true, visibleCheck = false, active = false, keyHeld = false,
    priority = "Crosshair", prediction = 0.15, sticky = false, stickyTarget = nil, headOffset = 0.5,
}

local _fovCircle = Drawing.new("Circle")
_fovCircle.Thickness = 1; _fovCircle.Filled = false
_fovCircle.Color = Color3.fromRGB(255, 255, 255); _fovCircle.Visible = false
local _fovVisible = false

local function computeAimPos(plr)
    local char = getRealChar(plr); if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not (hum and hrp and hum.Health > 0) then return nil end
    local vm = getViewmodel(hrp)
    local aimPart
    if vm then aimPart = (_aim.part == "Head" and vm:FindFirstChild("head")) or vm:FindFirstChild("torso") or vm:FindFirstChild("head") end
    if not aimPart then aimPart = hrp end
    local pos = aimPart.Position
    if _aim.part == "Head" and aimPart.Name == "head" then pos = pos - Vector3.new(0, _aim.headOffset, 0) end
    if _aim.prediction > 0 then
        pos = pos + hrp.AssemblyLinearVelocity * (_aim.prediction + LP:GetNetworkPing())
    end
    return pos, aimPart, hum
end

local function posVisible(pos)
    if not _aim.visibleCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = { LP.Character }
    if _vmFolder then table.insert(ignore, _vmFolder) end
    params.FilterDescendantsInstances = ignore
    local res = workspace:Raycast(Cam.CFrame.Position, pos - Cam.CFrame.Position, params)
    if not res then return true end
    return (res.Position - pos).Magnitude < 6
end

local function getAimTarget()
    local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    if _aim.sticky and _aim.stickyTarget then
        local plr = _aim.stickyTarget
        if plr and plr.Parent and (not _aim.teamCheck or plr.Team ~= LP.Team) then
            local pos, part = computeAimPos(plr)
            if pos then
                local sp = Cam:WorldToViewportPoint(pos)
                if (Vector2.new(sp.X, sp.Y) - center).Magnitude <= _aim.fov and posVisible(pos) then
                    _aim._aimPos = pos; return part
                end
            end
        end
        _aim.stickyTarget = nil
    end
    local best, bestScore, bestPos, bestPlr
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        if _aim.teamCheck and plr.Team == LP.Team then continue end
        local pos, part, hum = computeAimPos(plr); if not pos then continue end
        local sp, onScreen = Cam:WorldToViewportPoint(pos); if not onScreen then continue end
        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if d > _aim.fov then continue end
        if not posVisible(pos) then continue end
        local score
        if _aim.priority == "Distance" then
            local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local tHRP = getRealChar(plr) and getRealChar(plr):FindFirstChild("HumanoidRootPart")
            score = (myHRP and tHRP) and (myHRP.Position - tHRP.Position).Magnitude or d
        elseif _aim.priority == "Low HP" then score = hum.Health
        else score = d end
        if not bestScore or score < bestScore then bestScore = score; best = part; bestPos = pos; bestPlr = plr end
    end
    if best then _aim._aimPos = bestPos; if _aim.sticky then _aim.stickyTarget = bestPlr end end
    return best
end

RunService:BindToRenderStep("ZH_AIMBOT", Enum.RenderPriority.Camera.Value + 2, function()
    if _fovVisible and _aim.enabled then
        _fovCircle.Radius = _aim.fov; _fovCircle.Position = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2); _fovCircle.Visible = true
    else _fovCircle.Visible = false end
    if not _aim.enabled then return end
    local shouldLock
    if _aim.mode == "Always" then shouldLock = true
    elseif _aim.mode == "Hold" then shouldLock = _aim.keyHeld
    else shouldLock = _aim.active end
    if not shouldLock then return end
    local target = getAimTarget(); if not target then return end
    local aimPos = _aim._aimPos or target.Position
    local alpha = (_aim.smooth <= 0) and 1 or math.clamp(1 - _aim.smooth, 0.05, 1)
    Cam.CFrame = Cam.CFrame:Lerp(CFrame.new(Cam.CFrame.Position, aimPos), alpha)
end)

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if _aim.mode == "Hold" and input.UserInputType == Enum.UserInputType.MouseButton2 then _aim.keyHeld = true end
    if _aim.mode == "Toggle" and input.UserInputType == Enum.UserInputType.MouseButton2 then _aim.active = not _aim.active end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then _aim.keyHeld = false end
end)

AimBox:AddToggle("AimEnabled", { Text = "Enable Aimbot", Default = false, Description = "Locks camera to nearest enemy",
    Callback = function(v) _aim.enabled = v; if v and _aim.mode == "Always" then _aim.active = true end end })

AimBox:AddDropdown("AimMode", { Text = "Aim Mode", Values = {"Hold", "Toggle", "Always"}, Default = "Hold",
    Callback = function(v) _aim.mode = v; _aim.active = (v == "Always"); _aim.keyHeld = false end })

AimBox:AddDropdown("AimPart", { Text = "Aim Part", Values = {"Head", "Torso"}, Default = "Head",
    Callback = function(v) _aim.part = v end })

AimBox:AddDropdown("AimPriority", { Text = "Target Priority", Values = {"Crosshair", "Distance", "Low HP"}, Default = "Crosshair",
    Callback = function(v) _aim.priority = v end })

AimBox:AddSlider("AimSmooth", { Text = "Smoothness", Default = 15, Min = 0, Max = 95, Decimals = 0, Suffix = "%",
    Callback = function(v) _aim.smooth = v / 100 end })

AimBox:AddSlider("AimFOV", { Text = "FOV", Default = 120, Min = 10, Max = 500, Decimals = 0, Suffix = "px",
    Callback = function(v) _aim.fov = v end })

AimBox:AddSlider("AimPrediction", { Text = "Prediction", Default = 15, Min = 0, Max = 60, Decimals = 0, Suffix = "%",
    Callback = function(v) _aim.prediction = v / 100 end })

AimBox:AddSlider("AimHeadOffset", { Text = "Head Offset", Default = 5, Min = 0, Max = 20, Decimals = 0,
    Callback = function(v) _aim.headOffset = v / 10 end })

AimBox:AddDivider()

AimBox:AddToggle("AimFOVCircle", { Text = "Show FOV Circle", Default = false,
    Callback = function(v) _fovVisible = v end })

AimBox:AddToggle("AimTeamCheck", { Text = "Team Check", Default = true,
    Callback = function(v) _aim.teamCheck = v end })

AimBox:AddToggle("AimVisibleCheck", { Text = "Visible Check", Default = false,
    Callback = function(v) _aim.visibleCheck = v end })

AimBox:AddToggle("AimSticky", { Text = "Sticky Target", Default = false,
    Callback = function(v) _aim.sticky = v; _aim.stickyTarget = nil end })

local _origLighting = {
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness,
    FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart, GlobalShadows = Lighting.GlobalShadows,
}
local _fullBright, _noFog, _ambientOn = false, false, false
local _brightness = 2
local _ambR, _ambG, _ambB = 150, 150, 150
local _ambCol = Color3.fromRGB(_ambR, _ambG, _ambB)
local _worldConn = nil

local function worldTick()
    if _fullBright then Lighting.Brightness = _brightness; Lighting.ClockTime = 14; Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150) end
    if _noFog then Lighting.FogStart = 1e9; Lighting.FogEnd = 1e9
        local atmos = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmos then atmos.Density = 0; atmos.Haze = 0; atmos.Glare = 0 end
    end
    if _ambientOn then Lighting.Ambient = _ambCol; Lighting.OutdoorAmbient = _ambCol end
end

local function worldRefresh()
    if _fullBright or _noFog or _ambientOn then
        if not _worldConn then _worldConn = RunService.RenderStepped:Connect(worldTick) end
    else
        if _worldConn then _worldConn:Disconnect(); _worldConn = nil end
        Lighting.Brightness = _origLighting.Brightness; Lighting.GlobalShadows = _origLighting.GlobalShadows
        Lighting.Ambient = _origLighting.Ambient; Lighting.OutdoorAmbient = _origLighting.OutdoorAmbient
        Lighting.FogEnd = _origLighting.FogEnd; Lighting.FogStart = _origLighting.FogStart
    end
end

local LightBox = WorldTab:AddGroupbox("Lighting")
local FogBox = WorldTab:AddGroupbox("Fog")
local AmbientBox = WorldTab:AddGroupbox("Ambient")
local BloomBox = WorldTab:AddGroupbox("Bloom")

LightBox:AddToggle("FullBright", { Text = "Full Bright", Default = false, Description = "Removes darkness and shadows",
    Callback = function(v) _fullBright = v; worldRefresh() end })

LightBox:AddSlider("Brightness", { Text = "Brightness", Default = 2, Min = 0, Max = 10, Decimals = 0,
    Callback = function(v) _brightness = v end })

FogBox:AddToggle("NoFog", { Text = "No Fog", Default = false, Description = "Removes all fog and haze",
    Callback = function(v) _noFog = v; worldRefresh() end })

AmbientBox:AddToggle("AmbientToggle", { Text = "Apply Ambient", Default = false, Description = "Applies custom ambient color",
    Callback = function(v) _ambientOn = v; worldRefresh() end })

AmbientBox:AddSlider("AmbR", { Text = "Ambient R", Default = 150, Min = 0, Max = 255, Decimals = 0,
    Callback = function(v) _ambR = v; _ambCol = Color3.fromRGB(_ambR, _ambG, _ambB) end })

AmbientBox:AddSlider("AmbG", { Text = "Ambient G", Default = 150, Min = 0, Max = 255, Decimals = 0,
    Callback = function(v) _ambG = v; _ambCol = Color3.fromRGB(_ambR, _ambG, _ambB) end })

AmbientBox:AddSlider("AmbB", { Text = "Ambient B", Default = 150, Min = 0, Max = 255, Decimals = 0,
    Callback = function(v) _ambB = v; _ambCol = Color3.fromRGB(_ambR, _ambG, _ambB) end })

local _bloom = Lighting:FindFirstChildOfClass("BloomEffect")

BloomBox:AddToggle("BloomToggle", { Text = "Bloom", Default = false, Description = "Glow effect",
    Callback = function(v)
        if not _bloom then _bloom = Lighting:FindFirstChildOfClass("BloomEffect") end
        if not _bloom then _bloom = Instance.new("BloomEffect"); _bloom.Parent = Lighting end
        _bloom.Enabled = v
    end })

BloomBox:AddSlider("BloomIntensity", { Text = "Bloom Intensity", Default = 1, Min = 0, Max = 10, Decimals = 0,
    Callback = function(v) if not _bloom then _bloom = Lighting:FindFirstChildOfClass("BloomEffect") end; if _bloom then _bloom.Intensity = v end end })

BloomBox:AddSlider("BloomSize", { Text = "Bloom Size", Default = 24, Min = 0, Max = 56, Decimals = 0,
    Callback = function(v) if not _bloom then _bloom = Lighting:FindFirstChildOfClass("BloomEffect") end; if _bloom then _bloom.Size = v end end })

local MoveBox = MoveTab:AddGroupbox("Movement")

local _flySpeed = 100
local FlyToggle = MoveBox:AddToggle("Fly", { Text = "Fly", Default = false, Description = "Free flight with WASD + Space/Ctrl",
    Callback = function(p)
        if p then
            RunService:BindToRenderStep("ZHFly", Enum.RenderPriority.Input.Value, function(dt)
                local c = LP.Character; if not c then return end
                local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if not getgenv()._ZH_flyFrame then getgenv()._ZH_flyFrame = hrp.CFrame end
                local cf = Cam.CFrame; local mv = Vector3.zero
                local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit
                local rgt = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z).Unit
                if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + fwd end
                if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - fwd end
                if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - rgt end
                if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + rgt end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.yAxis end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.yAxis end
                if mv.Magnitude > 0 then getgenv()._ZH_flyFrame = getgenv()._ZH_flyFrame + mv.Unit * _flySpeed * dt end
                local fwd3 = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
                if fwd3.Magnitude > 0 then getgenv()._ZH_flyFrame = CFrame.new(getgenv()._ZH_flyFrame.Position, getgenv()._ZH_flyFrame.Position + fwd3.Unit) end
                hrp.AssemblyLinearVelocity = Vector3.zero; hrp.CFrame = getgenv()._ZH_flyFrame
            end)
        else RunService:UnbindFromRenderStep("ZHFly"); getgenv()._ZH_flyFrame = nil end
    end })
FlyToggle:AddKeybind({ Default = Enum.KeyCode.Y, Mode = "Toggle" })
MoveBox:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 100, Min = 0, Max = 5000, Decimals = 0,
    Callback = function(v) _flySpeed = v end })
MoveBox:AddDivider()

local _speed = 100
local SpeedToggle = MoveBox:AddToggle("Speedhack", { Text = "Walk Speed", Default = false, Description = "Increases movement speed",
    Callback = function(p)
        if p then
            RunService:BindToRenderStep("ZHSpeed", Enum.RenderPriority.Input.Value, function(dt)
                local c = LP.Character; if not c then return end
                local hum = c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health <= 0 then return end
                local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if hum.MoveDirection.Magnitude > 0 then hrp.CFrame = hrp.CFrame + hum.MoveDirection * _speed * dt end
            end)
        else RunService:UnbindFromRenderStep("ZHSpeed") end
    end })
SpeedToggle:AddKeybind({ Default = Enum.KeyCode.N, Mode = "Toggle" })
MoveBox:AddSlider("SpeedVal", { Text = "Speed", Default = 100, Min = 0, Max = 5000, Decimals = 0,
    Callback = function(v) _speed = v end })
MoveBox:AddDivider()

local _infJumpH = 50
local _ijConn = nil
local IJToggle = MoveBox:AddToggle("InfiniteJump", { Text = "Infinite Jump", Default = false,
    Callback = function(p)
        if _ijConn then _ijConn:Disconnect(); _ijConn = nil end
        if p then _ijConn = UIS.InputBegan:Connect(function(input, gpe)
            if gpe or input.KeyCode ~= Enum.KeyCode.Space then return end
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, _infJumpH, hrp.AssemblyLinearVelocity.Z)
        end) end
    end })
IJToggle:AddKeybind({ Default = Enum.KeyCode.H, Mode = "Toggle" })
MoveBox:AddSlider("InfJumpHeight", { Text = "Jump Height", Default = 50, Min = 0, Max = 1000, Decimals = 0,
    Callback = function(v) _infJumpH = v end })

local StatusBox = UtilTab:AddGroupbox("Anti Status")
local GrenadeBox = UtilTab:AddGroupbox("Anti Grenades")

local _noSlowConn = nil
StatusBox:AddToggle("NoSlow", { Text = "No Slow", Default = false, Description = "Removes slow/stun/freeze",
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
    end })

local _antiFlashConn, _antiFlashChildConn = nil, nil
GrenadeBox:AddToggle("AntiFlash", { Text = "Anti Flashbang", Default = false, Description = "Blocks flashbang screen effects",
    Callback = function(p)
        if _antiFlashConn then _antiFlashConn:Disconnect(); _antiFlashConn = nil end
        if _antiFlashChildConn then _antiFlashChildConn:Disconnect(); _antiFlashChildConn = nil end
        if not p then return end
        local function blockFlash()
            local pg = LP:FindFirstChild("PlayerGui"); if not pg then return end
            local flashGui = pg:FindFirstChild("Flash"); if not flashGui then return end
            local frame = flashGui:FindFirstChild("Frame"); if not frame then return end
            frame.BackgroundTransparency = 1
        end
        _antiFlashConn = RunService.RenderStepped:Connect(blockFlash)
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then
            _antiFlashChildConn = pg.DescendantAdded:Connect(function(desc)
                if desc.Name == "Frame" and desc.Parent and desc.Parent.Name == "Flash" then task.defer(function() desc.BackgroundTransparency = 1 end) end
            end)
        end
    end })

local _antiSmokeConn, _antiSmokeChildConn = nil, nil
GrenadeBox:AddToggle("AntiSmoke", { Text = "Anti Smoke Screen", Default = false, Description = "Removes smoke grenade clouds",
    Callback = function(p)
        if _antiSmokeConn then _antiSmokeConn:Disconnect(); _antiSmokeConn = nil end
        if _antiSmokeChildConn then _antiSmokeChildConn:Disconnect(); _antiSmokeChildConn = nil end
        if not p then return end
        local function nukeSmoke(part)
            if part.Name == "SmokePart" and part:IsA("BasePart") then
                pcall(function() part.Transparency = 1 end); pcall(function() part.CanCollide = false end)
            end
        end
        for _, v in ipairs(workspace:GetChildren()) do nukeSmoke(v) end
        _antiSmokeChildConn = workspace.ChildAdded:Connect(function(child) task.defer(function() nukeSmoke(child) end) end)
        _antiSmokeConn = RunService.Heartbeat:Connect(function()
            for _, v in ipairs(workspace:GetChildren()) do
                if v.Name == "SmokePart" and v:IsA("BasePart") and v.Transparency < 1 then
                    pcall(function() v.Transparency = 1 end); pcall(function() v.CanCollide = false end)
                end
            end
        end)
    end })

Library:CreateSettingsTab(Window)

Library:Notify({
    Title = "Zero Hub",
    Description = "Loaded — Operation One v1.1.1",
    Type = "Success",
    Duration = 3,
})
