-- Load Libraries
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/toeerolo-z/ethossuiterewrite/refs/heads/main/ethossuite.lua"))()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera
local _cloneref = cloneref or (getgenv and getgenv().cloneref) or (syn and syn.cloneref) or function(o) return o end
local Workspace = _cloneref(workspace)

------------------------------------------------------------
-- WINDOW
------------------------------------------------------------
local Window = Library:CreateWindow({
    Title = "ZERO HUB",
    Version = "v1.0.0",
})

------------------------------------------------------------
-- CATEGORIES + TABS
------------------------------------------------------------
local CatMain    = Window:AddCategory("MAIN")
local CatVisuals = Window:AddCategory("VISUALS")
local CatMisc    = Window:AddCategory("MISC")

local CombatTab  = CatMain:AddTab("Combat")
local MatchTab   = CatMain:AddTab("Matchmaking")

local PEspTab    = CatVisuals:AddTab("Player ESP")
local NEspTab    = CatVisuals:AddTab("NPC ESP")
local LootTab    = CatVisuals:AddTab("Loot ESP")
local ExtractTab = CatVisuals:AddTab("Extraction ESP")
local EspCfgTab  = CatVisuals:AddTab("ESP Config")
local WorldTab   = CatVisuals:AddTab("World")

local MoveTab    = CatMisc:AddTab("Movement")
local UtilTab    = CatMisc:AddTab("Utility")

------------------------------------------------------------
-- MAIN > COMBAT
------------------------------------------------------------
local CombatBox = CombatTab:AddGroupbox("Combat")
local GunBox    = CombatTab:AddGroupbox("Gun Mods")

-- Infinite Stamina
local _infStamConn = nil
CombatBox:AddToggle("InfStamina", {
    Text = "Infinite Stamina",
    Default = false,
    Description = "Gives you infinite stamina so you can sprint forever",
    Callback = function(v)
        if _infStamConn then _infStamConn:Disconnect(); _infStamConn = nil end
        if not v then return end
        local State = debug.getupvalue(getrenv().shared.staminaFunction, 1)
        _infStamConn = RunService.Heartbeat:Connect(function()
            State.current = 204
        end)
    end,
})

-- Shoot Redirection (Silent Aim)
local _shootRedirEnabled = false
local _shootRedirHook = nil
local _shootRedirFOV = 500

local function getClosestEnemyHead()
    local myChar = LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local myPos = myHRP.Position
    local closest, bestDist = nil, _shootRedirFOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local d = (head.Position - myPos).Magnitude
                if d < bestDist then bestDist = d; closest = head end
            end
        end
    end
    for _, child in ipairs(Workspace:GetDescendants()) do
        if child:IsA("Model") and child:GetAttribute("AI") == true then
            local head = child:FindFirstChild("Head")
            local hum = child:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local d = (head.Position - myPos).Magnitude
                if d < bestDist then bestDist = d; closest = head end
            end
        end
    end
    return closest
end

CombatBox:AddToggle("ShootRedirect", {
    Text = "Shoot Redirection",
    Default = false,
    Description = "Redirects your bullets to the nearest enemy head automatically",
    Callback = function(v)
        _shootRedirEnabled = v
        if v then
            if _shootRedirHook then return end
            local Vector3__namecall
            Vector3__namecall = hookmetamethod(Vector3.zero, "__namecall", newcclosure(function(self, ...)
                if _shootRedirEnabled and debug.info(3, "n") == "getHitPos" and getnamecallmethod() == "Lerp" then
                    local head = getClosestEnemyHead()
                    if head then return head.Position end
                end
                return Vector3__namecall(self, ...)
            end))
            _shootRedirHook = Vector3__namecall
        end
    end,
})

CombatBox:AddSlider("ShootRedirFOV", {
    Text = "Aim FOV (studs)", Default = 500, Min = 10, Max = 2000, Decimals = 0,
    Description = "Max distance to lock onto enemies",
    Callback = function(v) _shootRedirFOV = v end,
})

-- No Recoil (FIXED — caches gun table once, zeros per frame, no getgc spam)
local _noRecoilEnabled = false
local _noRecoilConn = nil
local _cachedGunTables = {}

local function cacheGunTables()
    _cachedGunTables = {}
    local gc = getgc(true)
    for i = 1, #gc do
        pcall(function()
            local obj = gc[i]
            if type(obj) == "table" and rawget(obj, "recoil") and type(rawget(obj, "recoil")) == "table" and rawget(obj, "crosshairRadius") then
                _cachedGunTables[#_cachedGunTables+1] = obj
            end
        end)
        if i % 5000 == 0 then task.wait() end
    end
end

GunBox:AddToggle("NoRecoil", {
    Text = "No Recoil",
    Default = false,
    Description = "Removes all weapon recoil so your aim stays perfectly still",
    Callback = function(v)
        _noRecoilEnabled = v
        if _noRecoilConn then _noRecoilConn:Disconnect(); _noRecoilConn = nil end
        if not v then return end
        task.spawn(cacheGunTables)
        _noRecoilConn = RunService.Heartbeat:Connect(function()
            if not _noRecoilEnabled then return end
            for _, t in ipairs(_cachedGunTables) do
                pcall(function()
                    local r = t.recoil
                    if r then
                        r.vPunchBase = 0; r.hPunchBase = 0; r.dPunchBase = 0
                        r.recoilPunch = 0; r.maxRecoilPower = 0; r.minRecoilPower = 0
                    end
                end)
            end
        end)
    end,
})

-- No Spread (FIXED — same cached table approach)
GunBox:AddToggle("NoSpread", {
    Text = "No Spread",
    Default = false,
    Description = "Removes bullet spread so every shot goes exactly where you aim",
    Callback = function(v)
        if not v then return end
        if #_cachedGunTables == 0 then task.spawn(cacheGunTables) end
        task.spawn(function()
            task.wait(0.5)
            for _, t in ipairs(_cachedGunTables) do
                pcall(function()
                    t.crosshairRadius = 0
                    t.crosshairShoveSize = 0
                end)
            end
        end)
    end,
})

GunBox:AddButton({
    Text = "Refresh Gun Cache",
    Func = function()
        task.spawn(function()
            cacheGunTables()
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Gun Cache", Text = #_cachedGunTables .. " gun tables cached", Duration = 3
                })
            end)
        end)
    end,
})

------------------------------------------------------------
-- MAIN > MATCHMAKING
------------------------------------------------------------
local MatchBox = MatchTab:AddGroupbox("Matchmaking")

MatchBox:AddToggle("AutoJoinMM", {
    Text = "Auto Join Match Make",
    Default = false,
    Description = "Automatically joins the matchmaker queue",
    Callback = function(v)
        if v then
            local Event = game:GetService("ReplicatedStorage").Matchmake.JoinMatchMaker
            Event:InvokeServer(true)
        end
    end,
})

------------------------------------------------------------
-- SHARED ESP HELPERS
------------------------------------------------------------
local function getEquippedWeapon(char)
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Tool") and c.Name ~= "Fists" then return c.Name end
    end
    return nil
end

local _espCfg = {
    showName = true, showHP = true, showDist = true, showWeapon = true, showState = true,
    maxDist = 2000, fontSize = 21, tracers = false, boxes = true, hpBar = true,
    highlight = true, headDot = false, hlFill = 0.5, hlOutline = 0,
}

local function makeDrawingSet()
    local txt    = Drawing.new("Text"); txt.Center = true; txt.Outline = true; txt.Visible = false; txt.Size = _espCfg.fontSize
    local box    = Drawing.new("Square"); box.Filled = false; box.Thickness = 1.5; box.Visible = false
    local hpFill = Drawing.new("Square"); hpFill.Filled = true; hpFill.Visible = false
    local hpBack = Drawing.new("Square"); hpBack.Filled = false; hpBack.Thickness = 1; hpBack.Color = Color3.new(0,0,0); hpBack.Visible = false
    local tracer = Drawing.new("Line"); tracer.Thickness = 1; tracer.Visible = false
    local dot    = Drawing.new("Circle"); dot.Radius = 4; dot.Filled = true; dot.Visible = false; dot.Thickness = 1
    local hl     = Instance.new("Highlight"); hl.FillTransparency = 0.5; hl.OutlineTransparency = 0; hl.Enabled = false; hl.Parent = game:GetService("CoreGui")
    return {txt=txt, box=box, hpFill=hpFill, hpBack=hpBack, tracer=tracer, dot=dot, hl=hl}
end

local function hideAll(d)
    if d.txt then d.txt.Visible = false end
    if d.box then d.box.Visible = false end
    if d.hpFill then d.hpFill.Visible = false end
    if d.hpBack then d.hpBack.Visible = false end
    if d.tracer then d.tracer.Visible = false end
    if d.dot then d.dot.Visible = false end
    if d.hl then d.hl.Enabled = false end
end

local function destroyDrawingSet(d)
    pcall(function() if d.txt then d.txt:Remove() end end)
    pcall(function() if d.box then d.box:Remove() end end)
    pcall(function() if d.hpFill then d.hpFill:Remove() end end)
    pcall(function() if d.hpBack then d.hpBack:Remove() end end)
    pcall(function() if d.tracer then d.tracer:Remove() end end)
    pcall(function() if d.dot then d.dot:Remove() end end)
    pcall(function() if d.hl then d.hl:Destroy() end end)
end

local function renderESPFrame(d, char, hrp, head, hum, col, cfg, enabledFlag, label1, label2)
    if not (enabledFlag and char and char.Parent and hrp and hrp.Parent) then hideAll(d); return false end
    local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then hideAll(d); return true end
    local dist = (hrp.Position - myHRP.Position).Magnitude
    if dist > (cfg.maxDist or _espCfg.maxDist or 2000) then hideAll(d); return true end
    local sv, onS = Cam:WorldToViewportPoint(hrp.Position)
    local hv, onH = Cam:WorldToViewportPoint(head.Position)
    if not onS then hideAll(d); return true end

    local footPart = char:FindFirstChild("Left Leg") or char:FindFirstChild("LeftFoot") or hrp
    local topWorld = head.Position + Vector3.new(0, head.Size.Y/2 + 0.3, 0)
    local botWorld = footPart.Position - Vector3.new(0, footPart.Size.Y/2, 0)
    local topSV = Cam:WorldToViewportPoint(topWorld)
    local botSV = Cam:WorldToViewportPoint(botWorld)
    local bh = math.max(20, math.abs(botSV.Y - topSV.Y))
    local bw = bh * 0.55; local bx = sv.X - bw/2; local by = topSV.Y
    local hpPct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
    local hpCol = Color3.fromHSV(hpPct * 0.33, 1, 1)

    if _espCfg.boxes then d.box.Position = Vector2.new(bx, by); d.box.Size = Vector2.new(bw, bh); d.box.Color = col; d.box.Visible = true
    else d.box.Visible = false end

    if _espCfg.hpBar then
        local barW = 4; local barX = bx - barW - 3
        d.hpBack.Position = Vector2.new(barX-1, by-1); d.hpBack.Size = Vector2.new(barW+2, bh+2); d.hpBack.Visible = true
        d.hpFill.Position = Vector2.new(barX, by + bh*(1-hpPct)); d.hpFill.Size = Vector2.new(barW, bh*hpPct); d.hpFill.Color = hpCol; d.hpFill.Visible = true
    else d.hpFill.Visible = false; d.hpBack.Visible = false end

    local fs = _espCfg.fontSize or 21
    d.txt.Size = fs; d.txt.Color = col
    d.txt.Text = (label2 and label2 ~= "") and (label1 .. "\n" .. label2) or label1
    d.txt.Position = Vector2.new(sv.X, by - fs - 2); d.txt.Visible = label1 ~= ""

    if _espCfg.tracers then
        d.tracer.From = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y)
        d.tracer.To = Vector2.new(sv.X, sv.Y); d.tracer.Color = col; d.tracer.Visible = true
    else d.tracer.Visible = false end

    if _espCfg.headDot and onH then d.dot.Position = Vector2.new(hv.X, hv.Y); d.dot.Color = col; d.dot.Visible = true
    else d.dot.Visible = false end

    d.hl.Adornee = char; d.hl.Enabled = _espCfg.highlight; d.hl.FillColor = col; d.hl.OutlineColor = col
    d.hl.FillTransparency = _espCfg.hlFill; d.hl.OutlineTransparency = _espCfg.hlOutline
    return true
end

------------------------------------------------------------
-- VISUALS > PLAYER ESP
------------------------------------------------------------
local PlayerEspBox = PEspTab:AddGroupbox("Player ESP")
local _espEnabled = false
local _espColor = Color3.fromRGB(255, 255, 255)
local _espActive = {}
local _espConns = {}

local function getPlayerStateFlags(char)
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return "" end
    local f = {}
    if hum:GetAttribute("Downed") then f[#f+1]="DOWN" end; if hum:GetAttribute("Carried") then f[#f+1]="CARRIED" end
    if hum:GetAttribute("Burning") then f[#f+1]="BURN" end; if hum:GetAttribute("Contaminated") then f[#f+1]="CONTAM" end
    if hum:GetAttribute("Ragdoll") then f[#f+1]="RAG" end; if hum:GetAttribute("Tired") then f[#f+1]="TIRED" end
    if hum:GetAttribute("Overweight") then f[#f+1]="HEAVY" end
    if char:GetAttribute("aim") then f[#f+1]="AIM" end; if char:GetAttribute("crouch") then f[#f+1]="CROUCH" end
    if char:GetAttribute("prone") then f[#f+1]="PRONE" end; if char:GetAttribute("sprint") then f[#f+1]="SPRINT" end
    return table.concat(f, " | ")
end

local function removeESP(char)
    local d = _espActive[char]; if not d then return end
    destroyDrawingSet(d)
    if d.rname then pcall(function() RunService:UnbindFromRenderStep(d.rname) end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    if d.dieConn then pcall(function() d.dieConn:Disconnect() end) end
    _espActive[char] = nil
end

local function addESP(char, plr)
    if not char or _espActive[char] then return end
    local hum = char:WaitForChild("Humanoid", 10); local hrp = char:WaitForChild("HumanoidRootPart", 10)
    local head = char:WaitForChild("Head", 10)
    if not (hum and hrp and head) or not _espEnabled or _espActive[char] then return end

    local d = makeDrawingSet()
    local rname = "HV_ESP_" .. char:GetDebugId()

    RunService:BindToRenderStep(rname, Enum.RenderPriority.Camera.Value + 1, function()
        local parts = {}; local name = (plr and plr.DisplayName) or char.Name
        if _espCfg.showName then parts[#parts+1] = name end
        if _espCfg.showHP then parts[#parts+1] = string.format("[%d/%d]", hum.Health, hum.MaxHealth) end
        if _espCfg.showDist then
            local myH = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if myH then parts[#parts+1] = string.format("[%.0fm]", (hrp.Position - myH.Position).Magnitude) end
        end
        local l1 = table.concat(parts, " ")
        local l2p = {}
        if _espCfg.showWeapon then local w = getEquippedWeapon(char); if w then l2p[#l2p+1] = w end end
        if _espCfg.showState then local s = getPlayerStateFlags(char); if s ~= "" then l2p[#l2p+1] = s end end
        if not renderESPFrame(d, char, hrp, head, hum, _espColor, _espCfg, _espEnabled, l1, table.concat(l2p, " | ")) then
            removeESP(char)
        end
    end)

    d.rname = rname
    d.ancConn = char.AncestryChanged:Connect(function(_, p) if not p then removeESP(char) end end)
    d.dieConn = hum.Died:Connect(function() task.wait(3); removeESP(char) end)
    _espActive[char] = d
end

local function hookPlayer(plr)
    if plr == LP then return end
    if plr.Character then task.spawn(addESP, plr.Character, plr) end
    local conn = plr.CharacterAdded:Connect(function(c) task.spawn(addESP, c, plr) end)
    table.insert(_espConns, conn)
end

PlayerEspBox:AddToggle("PlayerESP", {
    Text = "Player ESP", Default = false, Description = "Shows all players through walls with health, weapon, and state info",
    Callback = function(v)
        _espEnabled = v
        if v then
            for _, plr in ipairs(Players:GetPlayers()) do hookPlayer(plr) end
            table.insert(_espConns, Players.PlayerAdded:Connect(hookPlayer))
            table.insert(_espConns, Players.PlayerRemoving:Connect(function(plr) if plr.Character then removeESP(plr.Character) end end))
        else
            for _, c in ipairs(_espConns) do pcall(function() c:Disconnect() end) end; _espConns = {}
            local l = {}; for c in pairs(_espActive) do l[#l+1] = c end; for _, c in ipairs(l) do removeESP(c) end
        end
    end,
})
PlayerEspBox:AddColorPicker("ESPColor", { Text = "ESP Color", Default = Color3.fromRGB(255,255,255), Callback = function(c) _espColor = c end })
PlayerEspBox:AddToggle("ESPName", { Text = "Name", Default = true, Callback = function(v) _espCfg.showName = v end })
PlayerEspBox:AddToggle("ESPHP", { Text = "Health", Default = true, Callback = function(v) _espCfg.showHP = v end })
PlayerEspBox:AddToggle("ESPDist", { Text = "Distance", Default = true, Callback = function(v) _espCfg.showDist = v end })
PlayerEspBox:AddToggle("ESPWeapon", { Text = "Weapon", Default = true, Callback = function(v) _espCfg.showWeapon = v end })
PlayerEspBox:AddToggle("ESPState", { Text = "State Flags", Default = true, Callback = function(v) _espCfg.showState = v end })

------------------------------------------------------------
-- VISUALS > NPC ESP
------------------------------------------------------------
local NpcEspBox = NEspTab:AddGroupbox("NPC ESP")
local _npcEspEnabled = false; local _npcEspColor = Color3.fromRGB(255, 120, 50)
local _npcEspActive = {}; local _npcScanConn = nil
local _npcCfg = { showName=true, showHP=true, showDist=true, showWeapon=true, showFaction=true, showAIState=true, showCombat=true, maxDist=2000 }

local function getNpcFlags(char)
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return "" end
    local f = {}
    if _npcCfg.showFaction then local t = hum:GetAttribute("Team"); if t then f[#f+1]=(tostring(t):match("^(.-)%.") or tostring(t)):upper() end end
    if _npcCfg.showAIState then local d = hum:GetAttribute("DEBUG_STATE"); if d then f[#f+1]=tostring(d):gsub("^CHAR_",""):gsub("_"," ") end end
    if _npcCfg.showCombat then
        if char:GetAttribute("onFight") then f[#f+1]="FIGHT" end; if char:GetAttribute("aim") then f[#f+1]="AIM" end
        if char:GetAttribute("reload") then f[#f+1]="RELOAD" end; if hum:GetAttribute("Downed") then f[#f+1]="DOWN" end
    end
    return table.concat(f, " | ")
end

local function removeNpcESP(char)
    local d = _npcEspActive[char]; if not d then return end; destroyDrawingSet(d)
    if d.rname then pcall(function() RunService:UnbindFromRenderStep(d.rname) end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    if d.dieConn then pcall(function() d.dieConn:Disconnect() end) end
    _npcEspActive[char] = nil
end

local function addNpcESP(char)
    if not char or _npcEspActive[char] or char:GetAttribute("AI") ~= true then return end
    local hum = char:WaitForChild("Humanoid",10); local hrp = char:WaitForChild("HumanoidRootPart",10); local head = char:WaitForChild("Head",10)
    if not (hum and hrp and head) or not _npcEspEnabled or _npcEspActive[char] then return end
    local d = makeDrawingSet(); local rname = "HV_NESP_" .. char:GetDebugId()

    RunService:BindToRenderStep(rname, Enum.RenderPriority.Camera.Value + 1, function()
        local p = {}
        if _npcCfg.showName then p[#p+1] = "[NPC] " .. char.Name end
        if _npcCfg.showHP then p[#p+1] = string.format("[%d/%d]", hum.Health, hum.MaxHealth) end
        if _npcCfg.showDist then local m = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if m then p[#p+1] = string.format("[%.0fm]", (hrp.Position - m.Position).Magnitude) end end
        local l2p = {}; local w = getEquippedWeapon(char); if w and _npcCfg.showWeapon then l2p[#l2p+1] = w end
        local sf = getNpcFlags(char); if sf ~= "" then l2p[#l2p+1] = sf end
        if not renderESPFrame(d, char, hrp, head, hum, _npcEspColor, _npcCfg, _npcEspEnabled, table.concat(p, " "), table.concat(l2p, " | ")) then removeNpcESP(char) end
    end)
    d.rname = rname
    d.ancConn = char.AncestryChanged:Connect(function(_, p) if not p then removeNpcESP(char) end end)
    d.dieConn = hum.Died:Connect(function() task.wait(3); removeNpcESP(char) end)
    _npcEspActive[char] = d
end

local function scanForNPCs()
    local pc = {}; for _, p in ipairs(Players:GetPlayers()) do if p.Character then pc[p.Character] = true end end
    local function scan(f, depth) if depth > 3 then return end
        for _, c in ipairs(f:GetChildren()) do
            if c:IsA("Model") and not pc[c] and c:GetAttribute("AI") == true and not _npcEspActive[c] then
                local h = c:FindFirstChildOfClass("Humanoid"); if h and h.Health > 0 then task.spawn(addNpcESP, c) end
            end
            if c:IsA("Folder") or c:IsA("Model") then scan(c, depth+1) end
        end
    end; scan(workspace, 0)
end

NpcEspBox:AddToggle("NpcESP", { Text = "NPC ESP", Default = false, Description = "Shows all AI enemies through walls with faction, weapon, and AI state",
    Callback = function(v) _npcEspEnabled = v
        if v then scanForNPCs()
            if _npcScanConn then _npcScanConn:Disconnect() end; local alive = true
            _npcScanConn = {Disconnect = function() alive = false end}
            task.spawn(function() while alive and _npcEspEnabled do task.wait(2); if alive then scanForNPCs() end end end)
        else if _npcScanConn then _npcScanConn:Disconnect(); _npcScanConn = nil end
            local l = {}; for c in pairs(_npcEspActive) do l[#l+1] = c end; for _, c in ipairs(l) do removeNpcESP(c) end end
    end })
NpcEspBox:AddColorPicker("NpcESPColor", { Text = "NPC Color", Default = Color3.fromRGB(255,120,50), Callback = function(c) _npcEspColor = c end })
NpcEspBox:AddToggle("NpcName", { Text = "Name", Default = true, Callback = function(v) _npcCfg.showName = v end })
NpcEspBox:AddToggle("NpcHP", { Text = "Health", Default = true, Callback = function(v) _npcCfg.showHP = v end })
NpcEspBox:AddToggle("NpcDist", { Text = "Distance", Default = true, Callback = function(v) _npcCfg.showDist = v end })
NpcEspBox:AddToggle("NpcWeapon", { Text = "Weapon", Default = true, Callback = function(v) _npcCfg.showWeapon = v end })
NpcEspBox:AddToggle("NpcFaction", { Text = "Faction", Default = true, Callback = function(v) _npcCfg.showFaction = v end })
NpcEspBox:AddToggle("NpcAIState", { Text = "AI State", Default = true, Callback = function(v) _npcCfg.showAIState = v end })
NpcEspBox:AddToggle("NpcCombat", { Text = "Combat Flags", Default = true, Callback = function(v) _npcCfg.showCombat = v end })

------------------------------------------------------------
-- VISUALS > LOOT ESP (391 crates: Wooden Crate, Duffel Bag, Cash Register, Cabinet)
------------------------------------------------------------
local LootBox = LootTab:AddGroupbox("Loot ESP")
local _lootEspEnabled = false; local _lootColor = Color3.fromRGB(100, 255, 100); local _lootActive = {}; local _lootMaxDist = 500

local function removeLootESP(obj)
    local d = _lootActive[obj]; if not d then return end
    pcall(function() if d.txt then d.txt:Remove() end end)
    pcall(function() if d.hl then d.hl:Destroy() end end)
    if d.rname then pcall(function() RunService:UnbindFromRenderStep(d.rname) end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    _lootActive[obj] = nil
end

local function addLootESP(obj)
    if not obj or _lootActive[obj] then return end
    local part = obj:IsA("BasePart") and obj or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
    if not part then return end
    local txt = Drawing.new("Text"); txt.Center = true; txt.Outline = true; txt.Visible = false; txt.Size = 18; txt.Color = _lootColor
    local hl = Instance.new("Highlight"); hl.FillTransparency = 0.7; hl.OutlineTransparency = 0; hl.FillColor = _lootColor
    hl.OutlineColor = _lootColor; hl.Enabled = false; hl.Adornee = obj; hl.Parent = game:GetService("CoreGui")
    local rname = "HV_LOOT_" .. obj:GetDebugId()

    RunService:BindToRenderStep(rname, Enum.RenderPriority.Camera.Value + 1, function()
        if not (_lootEspEnabled and obj and obj.Parent and part and part.Parent) then removeLootESP(obj); return end
        local myH = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not myH then txt.Visible = false; hl.Enabled = false; return end
        local dist = (part.Position - myH.Position).Magnitude
        if dist > _lootMaxDist then txt.Visible = false; hl.Enabled = false; return end
        local sv, onS = Cam:WorldToViewportPoint(part.Position)
        if not onS then txt.Visible = false; hl.Enabled = false; return end
        txt.Text = string.format("%s [%.0fm]", obj.Name, dist); txt.Position = Vector2.new(sv.X, sv.Y - 20)
        txt.Color = _lootColor; txt.Visible = true; hl.Enabled = true; hl.FillColor = _lootColor; hl.OutlineColor = _lootColor
    end)
    _lootActive[obj] = { txt = txt, hl = hl, rname = rname,
        ancConn = obj.AncestryChanged:Connect(function(_, p) if not p then removeLootESP(obj) end end) }
end

local _lootScanConn = nil
LootBox:AddToggle("LootESP", { Text = "Loot / Crate ESP", Default = false, Description = "Shows all loot crates, duffel bags, cash registers, and cabinets through walls",
    Callback = function(v) _lootEspEnabled = v
        if v then
            local crates = workspace:FindFirstChild("Crates", true)
            if crates then for _, c in ipairs(crates:GetChildren()) do
                if c:IsA("Model") or c:IsA("BasePart") then task.spawn(addLootESP, c) end
                if c:IsA("Folder") then for _, sub in ipairs(c:GetChildren()) do if sub:IsA("Model") or sub:IsA("BasePart") then task.spawn(addLootESP, sub) end end end
            end end
            if _lootScanConn then _lootScanConn:Disconnect() end
            local alive = true; _lootScanConn = {Disconnect = function() alive = false end}
            task.spawn(function() while alive and _lootEspEnabled do task.wait(5)
                if not alive then return end
                if crates then for _, c in ipairs(crates:GetDescendants()) do
                    if (c:IsA("Model") or c:IsA("BasePart")) and not _lootActive[c] and not c:IsA("Folder") then task.spawn(addLootESP, c) end
                end end
            end end)
        else
            if _lootScanConn then _lootScanConn:Disconnect(); _lootScanConn = nil end
            local l = {}; for c in pairs(_lootActive) do l[#l+1] = c end; for _, c in ipairs(l) do removeLootESP(c) end
        end
    end })
LootBox:AddColorPicker("LootColor", { Text = "Loot Color", Default = Color3.fromRGB(100,255,100), Callback = function(c) _lootColor = c end })
LootBox:AddSlider("LootMaxDist", { Text = "Max Distance", Default = 500, Min = 50, Max = 5000, Decimals = 0, Callback = function(v) _lootMaxDist = v end })

------------------------------------------------------------
-- VISUALS > EXTRACTION ESP
------------------------------------------------------------
local ExtractBox = ExtractTab:AddGroupbox("Extraction Points")
local _extractEnabled = false; local _extractColor = Color3.fromRGB(50, 200, 255); local _extractActive = {}

local function removeExtractESP(obj)
    local d = _extractActive[obj]; if not d then return end
    pcall(function() if d.txt then d.txt:Remove() end end)
    pcall(function() if d.beam then d.beam:Destroy() end end)
    if d.rname then pcall(function() RunService:UnbindFromRenderStep(d.rname) end) end
    _extractActive[obj] = nil
end

local function addExtractESP(obj)
    if _extractActive[obj] then return end
    local txt = Drawing.new("Text"); txt.Center = true; txt.Outline = true; txt.Visible = false; txt.Size = 22; txt.Color = _extractColor
    local rname = "HV_EXT_" .. obj:GetDebugId()

    RunService:BindToRenderStep(rname, Enum.RenderPriority.Camera.Value + 1, function()
        if not (_extractEnabled and obj and obj.Parent) then removeExtractESP(obj); return end
        local myH = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not myH then txt.Visible = false; return end
        local dist = (obj.Position - myH.Position).Magnitude
        local sv, onS = Cam:WorldToViewportPoint(obj.Position)
        if not onS then txt.Visible = false; return end
        txt.Text = string.format("EXTRACT [%.0fm]", dist); txt.Position = Vector2.new(sv.X, sv.Y - 25)
        txt.Color = _extractColor; txt.Visible = true
    end)
    _extractActive[obj] = { txt = txt, rname = rname }
end

ExtractBox:AddToggle("ExtractESP", { Text = "Extraction ESP", Default = false, Description = "Shows all extraction points with distance markers",
    Callback = function(v) _extractEnabled = v
        if v then
            for _, c in ipairs(workspace:GetDescendants()) do
                if c.Name == "extractionMarker" and c:IsA("BasePart") then task.spawn(addExtractESP, c) end
            end
        else
            local l = {}; for c in pairs(_extractActive) do l[#l+1] = c end; for _, c in ipairs(l) do removeExtractESP(c) end
        end
    end })
ExtractBox:AddColorPicker("ExtractColor", { Text = "Extract Color", Default = Color3.fromRGB(50,200,255), Callback = function(c) _extractColor = c end })

------------------------------------------------------------
-- VISUALS > ESP CONFIG
------------------------------------------------------------
local SharedCfgBox = EspCfgTab:AddGroupbox("Shared Config")
SharedCfgBox:AddToggle("CfgBoxes", { Text = "Boxes", Default = true, Callback = function(v) _espCfg.boxes = v end })
SharedCfgBox:AddToggle("CfgHPBar", { Text = "HP Bar", Default = true, Callback = function(v) _espCfg.hpBar = v end })
SharedCfgBox:AddToggle("CfgHighlight", { Text = "Highlight", Default = true, Callback = function(v) _espCfg.highlight = v end })
SharedCfgBox:AddToggle("CfgTracers", { Text = "Tracers", Default = false, Callback = function(v) _espCfg.tracers = v end })
SharedCfgBox:AddToggle("CfgHeadDot", { Text = "Head Dot", Default = false, Callback = function(v) _espCfg.headDot = v end })
SharedCfgBox:AddSlider("CfgMaxDist", { Text = "Max Distance", Default = 2000, Min = 0, Max = 10000, Decimals = 0, Callback = function(v) _espCfg.maxDist = v; _npcCfg.maxDist = v end })
SharedCfgBox:AddSlider("CfgFontSize", { Text = "Font Size", Default = 21, Min = 8, Max = 32, Decimals = 0, Callback = function(v) _espCfg.fontSize = v end })
SharedCfgBox:AddSlider("CfgFillTrans", { Text = "Fill Transparency", Default = 0.5, Min = 0, Max = 1, Decimals = 2, Callback = function(v) _espCfg.hlFill = v end })
SharedCfgBox:AddSlider("CfgOutTrans", { Text = "Outline Transparency", Default = 0, Min = 0, Max = 1, Decimals = 2, Callback = function(v) _espCfg.hlOutline = v end })

------------------------------------------------------------
-- VISUALS > WORLD
------------------------------------------------------------
do
    local Lighting = game:GetService("Lighting"); local writeSignal = RunService.RenderStepped; local writeConn = nil
    local original = { Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient, Brightness=Lighting.Brightness,
        ExposureCompensation=Lighting.ExposureCompensation, FogEnd=Lighting.FogEnd, FogStart=Lighting.FogStart, FogColor=Lighting.FogColor, GlobalShadows=Lighting.GlobalShadows }
    local ccFx = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    local fullBright, noFog, ambientOn = false, false, false
    local ambR, ambG, ambB = 128, 128, 180; local FB_AMB = Color3.fromRGB(255,255,255); local ambCol = Color3.fromRGB(ambR,ambG,ambB)
    local function tick()
        if fullBright then Lighting.Ambient = FB_AMB; Lighting.OutdoorAmbient = FB_AMB; Lighting.Brightness = 2.5; Lighting.ExposureCompensation = 0.15
            if ccFx then ccFx.Brightness = 0.05 end end
        if noFog then Lighting.FogEnd = 1e10; Lighting.FogStart = 1e10 end
        if ambientOn then Lighting.Ambient = ambCol end
    end
    local function refresh()
        if fullBright or noFog or ambientOn then if not writeConn then writeConn = writeSignal:Connect(tick) end
        else if writeConn then writeConn:Disconnect(); writeConn = nil end
            Lighting.Ambient=original.Ambient; Lighting.OutdoorAmbient=original.OutdoorAmbient; Lighting.Brightness=original.Brightness
            Lighting.ExposureCompensation=original.ExposureCompensation; Lighting.FogEnd=original.FogEnd; Lighting.FogStart=original.FogStart end
    end
    local LightBox = WorldTab:AddGroupbox("Lighting"); local FogBox = WorldTab:AddGroupbox("Fog"); local AmbientBox = WorldTab:AddGroupbox("Ambient")
    LightBox:AddToggle("FullBright", { Text = "Full Bright", Default = false, Description = "Makes everything fully lit with no shadows", Callback = function(v) fullBright = v; refresh() end })
    FogBox:AddToggle("NoFog", { Text = "No Fog", Default = false, Description = "Removes all fog for infinite visibility", Callback = function(v) noFog = v; refresh() end })
    AmbientBox:AddSlider("AmbR", { Text = "Ambient R", Min = 0, Max = 255, Default = 128, Rounding = 0, Callback = function(v) ambR = v; ambCol = Color3.fromRGB(ambR,ambG,ambB) end })
    AmbientBox:AddSlider("AmbG", { Text = "Ambient G", Min = 0, Max = 255, Default = 128, Rounding = 0, Callback = function(v) ambG = v; ambCol = Color3.fromRGB(ambR,ambG,ambB) end })
    AmbientBox:AddSlider("AmbB", { Text = "Ambient B", Min = 0, Max = 255, Default = 180, Rounding = 0, Callback = function(v) ambB = v; ambCol = Color3.fromRGB(ambR,ambG,ambB) end })
    AmbientBox:AddToggle("AmbEnable", { Text = "Apply Ambient", Default = false, Description = "Applies custom ambient color to the world", Callback = function(v) ambientOn = v; refresh() end })
end

------------------------------------------------------------
-- MISC > MOVEMENT
------------------------------------------------------------
local MoveBox = MoveTab:AddGroupbox("Movement")

local _flySpeed = 100
local FlyToggle = MoveBox:AddToggle("Fly", { Text = "Fly", Default = false, Description = "Free flight in any direction using WASD + Space/Ctrl",
    Callback = function(p)
        if p then RunService:BindToRenderStep("UTFly", Enum.RenderPriority.Input.Value, function(dt)
            local c = LP.Character; if not c then return end; local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            if not getgenv()._UT_flyFrame then getgenv()._UT_flyFrame = hrp.CFrame end
            local cf = Cam.CFrame; local mv = Vector3.zero
            local fwd = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z).Unit; local rgt = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z).Unit
            if UIS:IsKeyDown(Enum.KeyCode.W) then mv = mv + fwd end; if UIS:IsKeyDown(Enum.KeyCode.S) then mv = mv - fwd end
            if UIS:IsKeyDown(Enum.KeyCode.A) then mv = mv - rgt end; if UIS:IsKeyDown(Enum.KeyCode.D) then mv = mv + rgt end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.yAxis end; if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.yAxis end
            if mv.Magnitude > 0 then getgenv()._UT_flyFrame = getgenv()._UT_flyFrame + mv.Unit * _flySpeed * dt end
            local fwd3 = Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
            if fwd3.Magnitude > 0 then getgenv()._UT_flyFrame = CFrame.new(getgenv()._UT_flyFrame.Position, getgenv()._UT_flyFrame.Position + fwd3.Unit) end
            hrp.AssemblyLinearVelocity = Vector3.zero; hrp.CFrame = getgenv()._UT_flyFrame
        end) else RunService:UnbindFromRenderStep("UTFly"); getgenv()._UT_flyFrame = nil end
    end })
FlyToggle:AddKeybind({ Default = Enum.KeyCode.Y, Mode = "Toggle" })
MoveBox:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 100, Min = 0, Max = 5000, Decimals = 0, Callback = function(v) _flySpeed = v end })
MoveBox:AddDivider()

local _speed = 100
local SpeedToggle = MoveBox:AddToggle("Speedhack", { Text = "Walk Speed", Default = false, Description = "Increases your movement speed beyond normal",
    Callback = function(p)
        if p then RunService:BindToRenderStep("UTSpeed", Enum.RenderPriority.Input.Value, function(dt)
            local c = LP.Character; if not c then return end; local hum = c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health <= 0 then return end
            local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            if hum.MoveDirection.Magnitude > 0 then hrp.CFrame = hrp.CFrame + hum.MoveDirection * _speed * dt end
        end) else RunService:UnbindFromRenderStep("UTSpeed") end
    end })
SpeedToggle:AddKeybind({ Default = Enum.KeyCode.N, Mode = "Toggle" })
MoveBox:AddSlider("SpeedVal", { Text = "Speed", Default = 100, Min = 0, Max = 5000, Decimals = 0, Callback = function(v) _speed = v end })
MoveBox:AddDivider()

local _noclipConn = nil
local NoclipToggle = MoveBox:AddToggle("Noclip", { Text = "Noclip", Default = false, Description = "Walk through walls and all solid objects",
    Callback = function(p) if _noclipConn then _noclipConn:Disconnect(); _noclipConn = nil end; if not p then return end
        local cached = {}; local lastChar = nil
        _noclipConn = RunService.Heartbeat:Connect(function() local c = LP.Character
            if c ~= lastChar then cached = {}; lastChar = c; if c then for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then cached[#cached+1] = d end end end end
            for _, part in ipairs(cached) do if part.Parent then part.CanCollide = false end end end)
    end })
NoclipToggle:AddKeybind({ Default = Enum.KeyCode.T, Mode = "Toggle" })
MoveBox:AddDivider()

local _infJumpH = 50; local _ijConn = nil
local IJToggle = MoveBox:AddToggle("InfiniteJump", { Text = "Infinite Jump", Default = false, Description = "Jump in mid-air as many times as you want",
    Callback = function(p) if _ijConn then _ijConn:Disconnect(); _ijConn = nil end
        if p then _ijConn = UIS.InputBegan:Connect(function(input, gpe) if gpe or input.KeyCode ~= Enum.KeyCode.Space then return end
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, _infJumpH, hrp.AssemblyLinearVelocity.Z) end) end
    end })
IJToggle:AddKeybind({ Default = Enum.KeyCode.H, Mode = "Toggle" })

------------------------------------------------------------
-- MISC > UTILITY
------------------------------------------------------------
local UtilBox = UtilTab:AddGroupbox("Utility")

-- Anti AFK
local _afkConn = nil
UtilBox:AddToggle("AntiAFK", { Text = "Anti AFK", Default = true, Description = "Prevents you from being kicked for inactivity",
    Callback = function(p) if _afkConn then _afkConn:Disconnect(); _afkConn = nil end
        if p then _afkConn = LP.Idled:Connect(function() pcall(function()
            local VU = game:GetService("VirtualUser"); VU:Button2Down(Vector2.zero, Cam.CFrame); task.wait(0.1); VU:Button2Up(Vector2.zero, Cam.CFrame)
        end) end) end
    end })

-- Server Hop
UtilBox:AddButton({ Text = "Server Hop", Func = function()
    local TP = game:GetService("TeleportService"); local HS = game:GetService("HttpService"); local placeId = game.PlaceId
    local ok, res = pcall(function() return HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100")) end)
    if ok and res then for _, s in ipairs(res.data or {}) do if s.id ~= game.JobId and s.playing < s.maxPlayers then pcall(function() TP:TeleportToPlaceInstance(placeId, s.id, LP) end); return end end end
end })

-- Rejoin
UtilBox:AddButton({ Text = "Rejoin", Func = function()
    game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
end })

------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------
Library:CreateSettingsTab(Window)
