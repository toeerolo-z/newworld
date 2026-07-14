-- Load Libraries
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/toeerolo-z/ethossuiterewrite/refs/heads/main/ethossuite.lua"))()
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/troidnox/uiihgnnore/refs/heads/main/SensoryESP_Modified.lua"))()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

------------------------------------------------------------
-- WINDOW + TABS
------------------------------------------------------------
local Window = Library:CreateWindow({
    Title = "ZERO HUB",
    Version = "v1.0.0",
})

local CatMain      = Window:AddCategory("MAIN")
local CatCharacter  = Window:AddCategory("CHARACTER")
local CatNav        = Window:AddCategory("NAVIGATION")
local CatVisuals    = Window:AddCategory("VISUALS")
local CatMisc       = Window:AddCategory("MISC")

local MainTab      = CatMain:AddTab("Main")
local CharacterTab = CatCharacter:AddTab("Character")
local NavTab       = CatNav:AddTab("Navigation")
local VisualsTab   = CatVisuals:AddTab("Mob")
local NpcEspTab    = CatVisuals:AddTab("NPC")
local RiftEspTab   = CatVisuals:AddTab("Rift")
local MirrorEspTab = CatVisuals:AddTab("Mirror")
local PlayerEspTab = CatVisuals:AddTab("Player")
local MiscTab      = CatMisc:AddTab("Misc")

------------------------------------------------------------
-- MAIN TAB — Mob Farm
------------------------------------------------------------
local FarmBox   = MainTab:AddGroupbox("Mob Farm")
local FarmCfgBox = MainTab:AddGroupbox("Farm Config")

local _farm = {
    enabled = false,
    mode = "Behind",
    offX = 0, offY = 0, offZ = 6.5,
    autoM1 = false,
    autoCrit = false,
    autoEquip = false,
    weaponName = nil,
    targets = {},
    conn = nil,
    m1Thread = nil,
}

local function getChar() return LP.Character end
local function getHRP() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar(); return c and (c:FindFirstChildOfClass("Humanoid") or c:FindFirstChild("Human")) end

local function getMobName(mob)
    return mob.Name
end

local function scanMobList()
    local list = {"Nearest Mob"}
    local seen = {}
    local mobsFolder = workspace:FindFirstChild("Mobs")
    if not mobsFolder then return list end
    for _, folder in ipairs(mobsFolder:GetChildren()) do
        for _, mob in ipairs(folder:GetChildren()) do
            if mob:IsA("Model") then
                local hum = mob:FindFirstChildOfClass("Humanoid") or mob:FindFirstChild("Human")
                if hum and hum.Health > 0 and mob:GetAttribute("Friendly") ~= true then
                    local name = getMobName(mob)
                    if not seen[name] then
                        seen[name] = true
                        table.insert(list, name)
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a == "Nearest Mob" then return true end
        if b == "Nearest Mob" then return false end
        return a < b
    end)
    return list
end

local function nearestMob()
    local hrp = getHRP(); if not hrp then return end
    local mobsFolder = workspace:FindFirstChild("Mobs"); if not mobsFolder then return end
    local best, bestD = nil, math.huge
    local useFilter = next(_farm.targets) ~= nil and not _farm.targets["Nearest Mob"]
    for _, folder in ipairs(mobsFolder:GetChildren()) do
        for _, mob in ipairs(folder:GetChildren()) do
            if not mob:IsA("Model") then continue end
            local hum = mob:FindFirstChildOfClass("Humanoid") or mob:FindFirstChild("Human")
            local r = mob:FindFirstChild("HumanoidRootPart")
            if not (r and hum and hum.Health > 0) then continue end
            if mob:GetAttribute("Friendly") == true then continue end
            if useFilter and not _farm.targets[getMobName(mob)] then continue end
            local d = (r.Position - hrp.Position).Magnitude
            if d < bestD then best = mob; bestD = d end
        end
    end
    return best
end

local function calcFarmPos(rp)
    local mp = rp.Position
    local flatLook = Vector3.new(rp.CFrame.LookVector.X, 0, rp.CFrame.LookVector.Z)
    if flatLook.Magnitude > 0 then flatLook = flatLook.Unit else flatLook = Vector3.new(0,0,-1) end
    local flatRight = Vector3.new(rp.CFrame.RightVector.X, 0, rp.CFrame.RightVector.Z)
    if flatRight.Magnitude > 0 then flatRight = flatRight.Unit else flatRight = Vector3.new(1,0,0) end
    local base
    if _farm.mode == "Above" then base = mp + Vector3.new(0, _farm.offZ, 0)
    elseif _farm.mode == "Below" then base = mp + Vector3.new(0, -_farm.offZ, 0)
    elseif _farm.mode == "In Front" then base = mp + flatLook * _farm.offZ
    else base = mp - flatLook * _farm.offZ end
    return base + flatRight * _farm.offX + Vector3.new(0, _farm.offY, 0)
end

local function stopFarm()
    _farm.enabled = false
    if _farm.conn then _farm.conn:Disconnect(); _farm.conn = nil end
end

local function getWeapon()
    local char = LP.Character; if not char then return nil end
    if _farm.weaponName and _farm.weaponName ~= "" then
        local w = char:FindFirstChild(_farm.weaponName)
        if w and w:FindFirstChild("Slash") then return w end
    end
    -- Fallback: find any equipped tool with Slash
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") and t:FindFirstChild("Slash") then return t end
    end
    return nil
end

local function fireM1()
    local w = getWeapon()
    if w then w.Slash:FireServer(1) end
end

local function fireCrit()
    local w = getWeapon()
    if w then w.Slash:FireServer(2) end
end

local _lastM1 = 0
local _lastCrit = 0

local function tryEquipWeapon()
    if not _farm.weaponName or _farm.weaponName == "" then return end
    local char = getChar(); if not char then return end
    -- Already equipped?
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and tool.Name == _farm.weaponName then return end
    -- Find in backpack
    local bp = LP:FindFirstChild("Backpack"); if not bp then return end
    local weapon = bp:FindFirstChild(_farm.weaponName)
    if weapon and weapon:IsA("Tool") then
        local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Human")
        if hum then pcall(function() hum:EquipTool(weapon) end) end
    end
end

local function scanWeapons()
    local list = {}
    local seen = {}
    local char = LP.Character
    local bp = LP:FindFirstChild("Backpack")
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and not seen[t.Name] then
                seen[t.Name] = true
                list[#list+1] = t.Name
            end
        end
    end
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and not seen[t.Name] then
                seen[t.Name] = true
                list[#list+1] = t.Name
            end
        end
    end
    table.sort(list)
    return list
end

-- Mob Farm UI
FarmBox:AddDropdown("WeaponSelect", {
    Text = "Weapon",
    Values = scanWeapons(),
    Default = "",
    Callback = function(v) _farm.weaponName = v end,
})

FarmBox:AddButton({
    Text = "Refresh Weapons",
    Func = function()
        if Library.Options["WeaponSelect"] then
            Library.Options["WeaponSelect"]:SetValues(scanWeapons())
        end
    end,
})

local _autoEquipConn = nil
FarmBox:AddToggle("AutoEquip", {
    Text = "Auto Equip",
    Default = false,
    Description = "Keeps weapon equipped",
    Callback = function(v)
        _farm.autoEquip = v
        if _autoEquipConn then _autoEquipConn:Disconnect(); _autoEquipConn = nil end
        if not v then return end
        _autoEquipConn = RunService.Heartbeat:Connect(function()
            tryEquipWeapon()
        end)
    end,
})

FarmBox:AddDivider()

FarmBox:AddDropdown("MobSelect", {
    Text = "Target Mob",
    Values = scanMobList(),
    Default = {"Nearest Mob"},
    Multi = true,
    Callback = function(v) _farm.targets = {}; for _, name in ipairs(v) do _farm.targets[name] = true end end,
})

FarmBox:AddButton({
    Text = "Refresh Mobs",
    Func = function()
        if Library.Options["MobSelect"] then
            Library.Options["MobSelect"]:SetValues(scanMobList())
        end
    end,
})

FarmBox:AddToggle("MobFarm", {
    Text = "Mob Farm",
    Default = false,
    Description = "Farms nearby mobs",
    Callback = function(p)
        _farm.enabled = p
        if _farm.conn then _farm.conn:Disconnect(); _farm.conn = nil end
        if not p then return end
        local lastTgt = nil
        _farm.conn = RunService.Heartbeat:Connect(function()
            if not _farm.enabled then return end
            local c = getChar(); if not c then lastTgt = nil; return end
            local hum = getHum(); local hrp = getHRP()
            if not (hum and hrp) then lastTgt = nil; return end
            if hum.Health <= 0 then lastTgt = nil; return end

            if _farm.autoEquip then tryEquipWeapon() end

            local tHum = lastTgt and (lastTgt:FindFirstChildOfClass("Humanoid") or lastTgt:FindFirstChild("Human"))
            if not lastTgt or not lastTgt.Parent or not tHum or tHum.Health <= 0 or (lastTgt:GetAttribute("Friendly") == true) then
                lastTgt = nearestMob()
            end
            if not lastTgt then return end

            local rp = lastTgt:FindFirstChild("HumanoidRootPart"); if not rp then return end
            local targetPos = calcFarmPos(rp)

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = CFrame.lookAt(targetPos, rp.Position)

            -- Fire combat in loop
            local now = tick()
            if _farm.autoM1 and now - _lastM1 > 0.3 then
                _lastM1 = now
                fireM1()
            end
            if _farm.autoCrit and now - _lastCrit > 0.5 then
                _lastCrit = now
                fireCrit()
            end
        end)
    end,
})

local _m1Conn = nil
local _critConn = nil

FarmBox:AddToggle("AutoM1", {
    Text = "Auto M1",
    Default = false,
    Description = "Swings equipped weapon",
    Callback = function(v)
        _farm.autoM1 = v
        if _m1Conn then _m1Conn:Disconnect(); _m1Conn = nil end
        if not v then return end
        _m1Conn = RunService.Heartbeat:Connect(function()
            local now = tick()
            if now - _lastM1 > 0.3 then
                _lastM1 = now
                fireM1()
            end
        end)
    end,
})

local _critConn2 = nil
FarmBox:AddToggle("AutoCrit", {
    Text = "Auto Critical",
    Default = false,
    Description = "Heavy attacks between swings",
    Callback = function(v)
        _farm.autoCrit = v
        if _critConn2 then _critConn2:Disconnect(); _critConn2 = nil end
        if not v then return end
        _critConn2 = RunService.Heartbeat:Connect(function()
            local now = tick()
            if now - _lastCrit > 0.5 then
                _lastCrit = now
                fireCrit()
            end
        end)
    end,
})

local _lastTech = 0
local _techConn = nil
FarmBox:AddToggle("AutoTechnique", {
    Text = "Auto Technique",
    Default = false,
    Description = "Uses weapon technique",
    Callback = function(v)
        _farm.autoTech = v
        if _techConn then _techConn:Disconnect(); _techConn = nil end
        if not v then return end
        _techConn = RunService.Heartbeat:Connect(function()
            local now = tick()
            if now - _lastTech > 1 then
                _lastTech = now
                pcall(function()
                    local char = LP.Character; if not char then return end
                    local w = char:FindFirstChild(_farm.weaponName)
                    if not w then
                        w = char:FindFirstChildOfClass("Tool")
                    end
                    if not w then return end
                    local slash = w:FindFirstChild("Slash"); if not slash then return end
                    slash:FireServer(3)
                    task.wait(0.3)
                    slash:FireServer(4)
                end)
            end
        end)
    end,
})

-- Farm Config
FarmCfgBox:AddDropdown("FarmMode", {
    Text = "Position",
    Values = {"Behind", "In Front", "Above", "Below"},
    Default = "Behind",
    Callback = function(v) _farm.mode = v end,
})

FarmCfgBox:AddSlider("FarmOffX", {
    Text = "Offset X", Default = 0, Min = -20, Max = 20, Decimals = 1,
    Callback = function(v) _farm.offX = v end,
})

FarmCfgBox:AddSlider("FarmOffY", {
    Text = "Offset Y", Default = 0, Min = -20, Max = 50, Decimals = 1,
    Callback = function(v) _farm.offY = v end,
})

FarmCfgBox:AddSlider("FarmOffZ", {
    Text = "Offset Z", Default = 6.5, Min = 0, Max = 50, Decimals = 1,
    Callback = function(v) _farm.offZ = v end,
})

------------------------------------------------------------
-- ORE FARM
------------------------------------------------------------
local OreFarmBox = MainTab:AddGroupbox("Ore Farm")

local _oreFarm = { enabled = false, conn = nil, zone = "Nearest", lastSwing = 0 }

local function scanOreZones()
    local list = {"Nearest"}
    local oresFolder = workspace:FindFirstChild("Ores"); if not oresFolder then return list end
    for _, folder in ipairs(oresFolder:GetChildren()) do
        local hasAlive = false
        for _, ore in ipairs(folder:GetChildren()) do
            if ore:IsA("Model") and ore:GetAttribute("HP") and ore:GetAttribute("HP") > 0 then
                hasAlive = true; break
            end
        end
        if hasAlive then list[#list+1] = folder.Name end
    end
    table.sort(list, function(a, b)
        if a == "Nearest" then return true end
        if b == "Nearest" then return false end
        return a < b
    end)
    return list
end

local function nearestOre()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local oresFolder = workspace:FindFirstChild("Ores"); if not oresFolder then return nil end
    local best, bestD = nil, math.huge
    for _, folder in ipairs(oresFolder:GetChildren()) do
        if _oreFarm.zone ~= "Nearest" and folder.Name ~= _oreFarm.zone then continue end
        for _, ore in ipairs(folder:GetChildren()) do
            if not ore:IsA("Model") then continue end
            local hp = ore:GetAttribute("HP")
            if not hp or hp <= 0 then continue end
            local base = ore:FindFirstChild("Base") or ore:FindFirstChildWhichIsA("BasePart")
            if not base then continue end
            local d = (base.Position - hrp.Position).Magnitude
            if d < bestD then best = ore; bestD = d end
        end
    end
    return best
end

OreFarmBox:AddDropdown("OreZone", {
    Text = "Ore Zone",
    Values = scanOreZones(),
    Default = "Nearest",
    Callback = function(v) _oreFarm.zone = v end,
})

OreFarmBox:AddButton({
    Text = "Refresh Zones",
    Func = function()
        if Library.Options["OreZone"] then
            Library.Options["OreZone"]:SetValues(scanOreZones())
        end
    end,
})

OreFarmBox:AddToggle("OreFarm", {
    Text = "Ore Farm",
    Default = false,
    Description = "Mines ores automatically",
    Callback = function(p)
        _oreFarm.enabled = p
        if _oreFarm.conn then _oreFarm.conn:Disconnect(); _oreFarm.conn = nil end
        if not p then return end
        local curOre = nil
        _oreFarm.conn = RunService.Heartbeat:Connect(function()
            if not _oreFarm.enabled then return end
            local char = LP.Character; if not char then curOre = nil; return end
            local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            local hum = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("Human")
            if not hum or hum.Health <= 0 then curOre = nil; return end

            -- Auto equip pickaxe
            local pick = char:FindFirstChild("Old Pickaxe")
            if not pick then
                local bp = LP:FindFirstChild("Backpack")
                if bp then
                    for _, t in ipairs(bp:GetChildren()) do
                        if t.Name:lower():find("pick") and t:IsA("Tool") then
                            pcall(function() hum:EquipTool(t) end)
                            break
                        end
                    end
                end
            end

            -- Check if ore dead
            if curOre and (not curOre.Parent or not curOre:GetAttribute("HP") or curOre:GetAttribute("HP") <= 0) then
                curOre = nil
            end
            if not curOre then curOre = nearestOre() end
            if not curOre then return end

            local base = curOre:FindFirstChild("Base") or curOre:FindFirstChildWhichIsA("BasePart")
            if not base then return end

            -- TP to ore
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(base.Position + Vector3.new(0, 3, 0))

            -- Swing pickaxe
            local now = tick()
            if now - _oreFarm.lastSwing > 0.15 then
                _oreFarm.lastSwing = now
                pcall(function()
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        local slash = tool:FindFirstChild("Slash")
                        if slash then slash:FireServer(1) end
                    end
                end)
            end
        end)
    end,
})

-- Semi God Mode
local ExploitBox = MainTab:AddGroupbox("Exploits")

local _semiGodThread = nil
ExploitBox:AddToggle("SemiGodMode", {
    Text = "Semi God Mode",
    Default = false,
    Description = "Constant invincibility frames",
    Callback = function(v)
        if _semiGodThread then task.cancel(_semiGodThread); _semiGodThread = nil end
        if not v then return end
        local rollRemote = game:GetService("ReplicatedStorage").Remotes.Roll
        _semiGodThread = task.spawn(function()
            while Library.Flags["SemiGodMode"] do
                pcall(function() rollRemote:FireServer({Dive = true}) end)
                task.wait(0.05)
                pcall(function() rollRemote:FireServer() end)
                task.wait(0.05)
            end
        end)
    end,
})

------------------------------------------------------------
-- CHARACTER TAB
------------------------------------------------------------
local MoveBox  = CharacterTab:AddGroupbox("Movement")
local MorphBox = CharacterTab:AddGroupbox("Morphs")
local UtilBox  = CharacterTab:AddGroupbox("Utility")

-- Movement vars
local _flySpeed = 100
local _speed = 100
local _infJumpH = 50

-- Fly
local FlyToggle = MoveBox:AddToggle("Fly", {
    Text = "Fly",
    Default = false,
    Description = "Free movement in air",
    Callback = function(p)
        if p then
            RunService:BindToRenderStep("UTFly", Enum.RenderPriority.Input.Value, function(dt)
                local c = LP.Character; if not c then return end
                local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if not getgenv()._UT_flyFrame then getgenv()._UT_flyFrame = hrp.CFrame end
                local frame = getgenv()._UT_flyFrame; local cf = Cam.CFrame; local mv = Vector3.zero
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
                getgenv()._UT_flyFrame = frame; hrp.AssemblyLinearVelocity = Vector3.zero; hrp.CFrame = frame
            end)
        else
            RunService:UnbindFromRenderStep("UTFly"); getgenv()._UT_flyFrame = nil
        end
    end,
})
FlyToggle:AddKeybind({ Default = Enum.KeyCode.Y, Mode = "Toggle" })

MoveBox:AddSlider("FlySpeed", {
    Text = "Fly Speed", Default = 100, Min = 0, Max = 5000, Decimals = 0,
    Callback = function(v) _flySpeed = v end,
})

MoveBox:AddDivider()

-- Speedhack
local SpeedToggle = MoveBox:AddToggle("Speedhack", {
    Text = "Speedhack",
    Default = false,
    Description = "Increased move speed",
    Callback = function(p)
        if p then
            RunService:BindToRenderStep("UTSpeed", Enum.RenderPriority.Input.Value, function(dt)
                local c = LP.Character; if not c then return end
                local hum = c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health <= 0 then return end
                local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if hum.MoveDirection.Magnitude > 0 then hrp.CFrame = hrp.CFrame + hum.MoveDirection * _speed * dt end
            end)
        else
            RunService:UnbindFromRenderStep("UTSpeed")
        end
    end,
})
SpeedToggle:AddKeybind({ Default = Enum.KeyCode.N, Mode = "Toggle" })

MoveBox:AddSlider("SpeedhackSpeed", {
    Text = "Speed", Default = 100, Min = 0, Max = 5000, Decimals = 0,
    Callback = function(v) _speed = v end,
})

MoveBox:AddDivider()

-- Infinite Jump
local _ijConn = nil
local IJToggle = MoveBox:AddToggle("InfiniteJump", {
    Text = "Infinite Jump",
    Default = false,
    Description = "Unlimited jumps",
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
IJToggle:AddKeybind({ Default = Enum.KeyCode.H, Mode = "Toggle" })

MoveBox:AddSlider("InfJumpHeight", {
    Text = "Jump Height", Default = 50, Min = 0, Max = 1000, Decimals = 0,
    Callback = function(v) _infJumpH = v end,
})

MoveBox:AddDivider()

-- Noclip
local _noclipConn = nil
local NoclipToggle = MoveBox:AddToggle("Noclip", {
    Text = "Noclip",
    Default = false,
    Description = "Walk through walls",
    Callback = function(p)
        if _noclipConn then _noclipConn:Disconnect(); _noclipConn = nil end
        if not p then return end
        local cached = {}; local lastChar = nil
        _noclipConn = RunService.Heartbeat:Connect(function()
            local c = LP.Character
            if c ~= lastChar then
                cached = {}; lastChar = c
                if c then for _, d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then cached[#cached+1] = d end end end
            end
            for _, part in ipairs(cached) do if part.Parent then part.CanCollide = false end end
        end)
    end,
})
NoclipToggle:AddKeybind({ Default = Enum.KeyCode.T, Mode = "Toggle" })

------------------------------------------------------------
-- MORPHS
------------------------------------------------------------
local MORPHS = {
    ["Goku"]        = {hair=96778240725860,  shirt=18642081551,     pants=13980707182},
    ["Naruto"]      = {hair=129818847988995, shirt=6469644436,      pants=2733834231},
    ["Gojo"]        = {hair=132501783778842, shirt=73084050138865,   pants=15312673306},
    ["Toji"]        = {hair=135664715112347, shirt=121088463088431,  pants=16149857407},
    ["Aizen"]       = {hair=117644781784979, shirt=87853669951881,   pants=118029167731205},
    ["Guts"]        = {hair=117337600216775, shirt=13381096342,      pants=13381103162},
    ["Vasto Lorde"] = {hair=107798985962651, shirt=15549196125,      pants=15886594659},
    ["Luffy"]       = {hair=103832443149308, shirt=8483860912,       pants=6274345723},
    ["Zero Two"]    = {hair=93023559996037,  shirt=6392201226,       pants=5896597102},
    ["Yoruichi"]    = {hair=80207230854028,  face=82588218846528,    shirt=18842292222, pants=79431307149311},
}

local function clearMorph(char)
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Accessory") or v:IsA("Hat") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then
            pcall(function() v:Destroy() end)
        end
    end
end

local function addHair(char, id)
    local head = char:FindFirstChild("Head"); if not head then return end
    pcall(function()
        local objs = game:GetObjects("rbxassetid://" .. tostring(id))
        if not objs or not objs[1] then return end
        local acc = objs[1]; if not (acc:IsA("Accessory") or acc:IsA("Hat")) then return end
        local handle = acc:FindFirstChild("Handle"); if not handle then return end
        local headAtt = head:FindFirstChild("HairAttachment") or head:FindFirstChild("HatAttachment")
        local handleAtt = handle:FindFirstChild("HairAttachment") or handle:FindFirstChild("HatAttachment") or handle:FindFirstChild("BodyFrontAttachment")
        if headAtt and handleAtt then
            handle.CFrame = head.CFrame * headAtt.CFrame * handleAtt.CFrame:Inverse()
        else
            handle.CFrame = head.CFrame * CFrame.new(0, head.Size.Y * 0.5 + handle.Size.Y * 0.3, 0)
        end
        local wc = Instance.new("WeldConstraint"); wc.Part0 = head; wc.Part1 = handle; wc.Parent = handle
        handle.Anchored = false; acc.Parent = char
    end)
end

local function applyMorph(name)
    local char = LP.Character; if not char then return end
    local def = MORPHS[name]; clearMorph(char)
    local head = char:FindFirstChild("Head")
    if head then
        for _, v in ipairs(head:GetChildren()) do if v:IsA("Decal") then v:Destroy() end end
        if def and def.face then
            head.Transparency = 0
            local d = Instance.new("Decal"); d.Texture = "rbxassetid://" .. tostring(def.face); d.Face = Enum.NormalId.Front; d.Parent = head
        else
            head.Transparency = def and 1 or 0
        end
    end
    if not def then return end
    if def.shirt then local s = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char); s.ShirtTemplate = "rbxassetid://" .. tostring(def.shirt) end
    if def.pants then local p = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char); p.PantsTemplate = "rbxassetid://" .. tostring(def.pants) end
    addHair(char, def.hair)
end

local morphNames = {"None"}
for k in pairs(MORPHS) do table.insert(morphNames, k) end
table.sort(morphNames)

MorphBox:AddDropdown("MorphSelect", {
    Text = "Select Morph",
    Values = morphNames,
    Default = "None",
    Callback = function(v)
        task.spawn(function() applyMorph(v ~= "None" and v or nil) end)
    end,
})

MorphBox:AddButton({
    Text = "Reset Morph",
    Func = function()
        if Library.Options["MorphSelect"] then
            Library.Options["MorphSelect"]:SetValue("None")
        end
        task.spawn(function() applyMorph(nil) end)
    end,
})

------------------------------------------------------------
-- UTILITY
------------------------------------------------------------
UtilBox:AddButton({
    Text = "Kill Self",
    DoubleClick = true,
    Func = function()
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end,
})

UtilBox:AddDivider()

-- No Anims
local _noAnimsThread = nil
local _forcedTracks = {}
local _origTracks = {}
UtilBox:AddToggle("NoAnims", {
    Text = "No Anims",
    Default = false,
    Description = "Locks character pose",
    Callback = function(p)
        if _noAnimsThread then task.cancel(_noAnimsThread); _noAnimsThread = nil end
        if p then
            local c = LP.Character; if not c then return end
            local hum = c:FindFirstChildOfClass("Humanoid"); if not hum then return end
            local anim = hum:FindFirstChildOfClass("Animator"); if not anim then return end
            local dummy = Instance.new("Animation"); dummy.AnimationId = "rbxassetid://109212722752"
            _noAnimsThread = task.spawn(function()
                while Library.Flags["NoAnims"] and hum and hum.Parent do
                    for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
                        if track.Animation.AnimationId ~= dummy.AnimationId then
                            if not table.find(_origTracks, track) then table.insert(_origTracks, track) end
                            pcall(function() track:Stop(); task.defer(track.Destroy, track) end)
                        end
                    end
                    local found = false
                    for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
                        if track.Animation.AnimationId == dummy.AnimationId then found = true end
                    end
                    if not found then
                        local t = anim:LoadAnimation(dummy)
                        table.insert(_forcedTracks, t); t.Priority = Enum.AnimationPriority.Core; t:AdjustSpeed(0); t:Play()
                    end
                    task.wait(0.1)
                end
            end)
        else
            for _, track in pairs(_forcedTracks) do pcall(function() track:Stop(); track:Destroy() end) end; _forcedTracks = {}
            for _, track in pairs(_origTracks) do pcall(function() track:Play() end) end; _origTracks = {}
        end
    end,
})

-- Anim Speed
local _animSpeedConn = nil
local _animSpeed = 1
local function applyAnimSpeed(speed)
    pcall(function()
        local char = LP.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local anim = hum:FindFirstChildOfClass("Animator"); if not anim then return end
        for _, track in ipairs(anim:GetPlayingAnimationTracks()) do
            pcall(function() track:AdjustSpeed(speed) end)
        end
    end)
end

UtilBox:AddToggle("AnimSpeed", {
    Text = "Anim Speed",
    Default = false,
    Description = "Change animation speed",
    Callback = function(p)
        if _animSpeedConn then _animSpeedConn:Disconnect(); _animSpeedConn = nil end
        if p then
            _animSpeedConn = RunService.Heartbeat:Connect(function() applyAnimSpeed(_animSpeed) end)
        else
            applyAnimSpeed(1)
        end
    end,
})

UtilBox:AddSlider("AnimSpeedVal", {
    Text = "Speed Multiplier", Default = 1, Min = 0, Max = 200, Decimals = 1,
    Callback = function(v) _animSpeed = v end,
})

UtilBox:AddDivider()

-- Anti AFK
local _afkConn = nil
local _afkLoop = false
UtilBox:AddToggle("AntiAFK", {
    Text = "Anti AFK",
    Default = true,
    Description = "Stay connected while AFK",
    Callback = function(p)
        if _afkConn then _afkConn:Disconnect(); _afkConn = nil end
        _afkLoop = p
        if not p then return end
        local function nudge()
            pcall(function()
                local VU = game:GetService("VirtualUser")
                VU:Button2Down(Vector2.zero, Cam.CFrame)
                task.wait(0.1)
                VU:Button2Up(Vector2.zero, Cam.CFrame)
            end)
        end
        _afkConn = LP.Idled:Connect(nudge)
        task.spawn(function()
            while _afkLoop do task.wait(240); if _afkLoop then nudge() end end
        end)
    end,
})

UtilBox:AddDivider()

-- RakNet Desync
UtilBox:AddToggle("Desync", {
    Text = "Desync",
    Default = false,
    Description = "Harder to hit",
    Callback = function(p)
        local RakNet = getgenv().raknet or getgenv().rnet
        if not RakNet then return end
        if p then
            RakNet.add_send_hook(function(packet)
                if packet.PacketId == 0x1B then
                    local d = packet.AsBuffer
                    buffer.writeu32(d, 1, 0xFFFFFF)
                    packet:SetData(d)
                end
            end)
        else
            pcall(function() RakNet.remove_send_hook() end)
        end
    end,
})

-- God Mode
UtilBox:AddToggle("GodMode", {
    Text = "God Mode",
    Default = false,
    Description = "Invincibility (executor dependent)",
    Callback = function(v)
        if not v then return end
        local rn = getgenv().raknet
        if not rn or not rn.add_send_hook then return end
        if not (checkcaller and newcclosure and hookmetamethod) then return end
        pcall(function()
            rn.add_send_hook(function(packet)
                if packet.PacketId == 0x1B then
                    local d = packet.AsBuffer
                    buffer.writeu32(d, 1, 0xFFFFFFFF)
                    packet:SetData(d)
                end
            end)
            if replicatesignal and LP.Kill then
                pcall(function() replicatesignal(LP.Kill) end)
            end
            local Enabled = true
            local DesyncTypes = {}
            local downpart = Instance.new("Part", workspace)
            downpart.Size = Vector3.new(2, 1, 2)
            downpart.CanCollide = true
            downpart.Material = Enum.Material.ForceField
            downpart.Anchored = true
            local mouse = LP:GetMouse()
            mouse.Button1Down:Connect(function() Enabled = not Enabled end)
            mouse.Button1Up:Connect(function() Enabled = not Enabled end)
            RunService.Heartbeat:Connect(function()
                if Enabled and LP.Character then
                    local rt = LP.Character:FindFirstChild("HumanoidRootPart")
                    if not rt then return end
                    DesyncTypes[1] = rt.CFrame
                    DesyncTypes[2] = rt.AssemblyLinearVelocity
                    rt.CFrame = rt.CFrame + Vector3.new(0, 1000, 0)
                    downpart.CFrame = rt.CFrame + Vector3.new(0, -2, 0)
                    rt.AssemblyLinearVelocity = Vector3.new(1, 1, 1)
                    RunService.RenderStepped:Wait()
                    rt.CFrame = DesyncTypes[1]
                    rt.AssemblyLinearVelocity = DesyncTypes[2]
                end
            end)
            local hook
            hook = hookmetamethod(game, "__index", newcclosure(function(self, key)
                if Enabled and not checkcaller() and key == "CFrame" and LP.Character then
                    local hum = LP.Character:FindFirstChild("Humanoid")
                    if hum and hum.Health > 0 and self == LP.Character:FindFirstChild("HumanoidRootPart") then
                        return DesyncTypes[1] or CFrame.new()
                    end
                end
                return hook(self, key)
            end))
        end)
    end,
})

------------------------------------------------------------
-- MOB ESP (SensoryESP) — Visuals Tab
------------------------------------------------------------
local MobESPBox   = VisualsTab:AddGroupbox("Mob ESP")
local MobStyleBox = VisualsTab:AddGroupbox("Mob ESP Style")

-- Load ESP once at startup with Enabled = false
-- We toggle Enabled on the LIVE config, never re-call ESP:Load
ESP:Load({
    Enabled = false,
    Players = false,
    LocalPlayer = false,
    LimitFPS = 30,
    MaxDistance = 500,
    DynamicBoxes = true,
    DynamicBoxesCheap = true,
    VisibilityCheckRate = 0.5,

    Boxes = true,
    BoxType = "Normal",
    BoxColor = Color3.fromRGB(255, 80, 80),
    BoxThickness = 1,
    Outlines = { Style = "Full", Color = Color3.fromRGB(0, 0, 0), Thickness = 1 },

    BoxFill = {
        Enabled = false,
        Color = Color3.fromRGB(255, 80, 80),
        Transparency = 0.85,
        Gradient = { Enabled = false, Color1 = Color3.fromRGB(255, 80, 80), Color2 = Color3.fromRGB(255, 200, 50), Color3 = Color3.fromRGB(255, 80, 80), Rotation = 0, Animated = false, Speed = 64, Direction = "Right" },
    },

    HealthBar = {
        Enabled = false,
        Position = "Left",
        SideGap = 3, Width = 5,
        ShowText = false, TextFollowBar = false, HideWhenFullHP = false, FollowGradientColorText = true,
        Font = "Proggy Clean", TextSize = 13,
        Outline = { Style = "Full", Color = Color3.fromRGB(0, 0, 0) },
        Gradient = { Enabled = true, Color1 = Color3.fromRGB(0, 255, 0), Color2 = Color3.fromRGB(255, 255, 0), Color3 = Color3.fromRGB(255, 0, 0) },
    },

    Names = true,
    TextSize = 12,
    TextColor = Color3.fromRGB(255, 255, 255),
    TextOutline = true,
    TextOutlineStyle = "Full",
    TextGap = 3,
    Font = "Proggy Clean",

    Distance = { Enabled = true, Unit = "Meters", StudsPerMeter = 3, Ending = "m", Gap = 3, OutlineStyle = "Full", Font = "Proggy Clean", TextSize = 12, Color = Color3.fromRGB(200, 200, 200) },

    Flags = {
        Enabled = false, Position = "Right", Gap = 2, SideGap = 4, TextGap = 2, OutlineStyle = "Full", Font = "Smallest Pixel-7", TextSize = 9,
        Options = { Idle = true, Moving = true, Jumping = true, Swimming = false },
        Colors = { Idle = Color3.fromRGB(200, 200, 200), Moving = Color3.fromRGB(255, 200, 50), Jumping = Color3.fromRGB(100, 200, 255), Swimming = Color3.fromRGB(65, 65, 255) },
    },

    Skeleton = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0) },

    OffScreenArrows = {
        Enabled = false, Size = 14, Color = Color3.fromRGB(255, 80, 80), OrbitRadius = 100, ArrowMode = "Camera", Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0),
        Names = { Enabled = true, Font = "Smallest Pixel-7", TextSize = 9, Color = Color3.fromRGB(255,255,255), Outline = true, OutlineColor = Color3.fromRGB(0,0,0), Side = "Bottom", Gap = 4 },
        Distance = { Enabled = true, Font = "Smallest Pixel-7", TextSize = 9, Color = Color3.fromRGB(200,200,200), Outline = false, OutlineColor = Color3.fromRGB(0,0,0), Side = "Bottom", Gap = 2 },
    },

    Chams = {
        Enabled = false,
        Type = "Highlight",
        Highlight = { FillColor = Color3.fromRGB(255, 80, 80), FillTransparency = 0.7, OutlineColor = Color3.fromRGB(255, 255, 255), OutlineTransparency = 0, VisibleCheck = false },
        Adornment = { Color = Color3.fromRGB(255, 80, 80), VisibleColor = Color3.fromRGB(0, 255, 0), Transparency = 0.6, AlwaysOnTop = true, VisibleCheck = false },
        MeshChams = { FillColor = Color3.fromRGB(255, 80, 80), FillTransparency = 0.6, OutlineColor = Color3.fromRGB(255, 255, 255), OutlineTransparency = 0, VisibleCheck = false },
    },

    Directories = {
        {
            DisplayName = "",
            Path = "workspace.Mobs",
            Multiple = true,
            Recursive = true,
            Cheap = false,
            NonHuman = false,
            NoStatus = false,
            Contains = {},
            Names = {""},
        },
    },
})

-- Get the LIVE config reference — all UI callbacks modify this directly
local cfg = ESP:GetConfig()

-- Component applier
local function applyComponents(selected)
    local has = {}
    for _, v in ipairs(selected) do has[v] = true end

    cfg.Boxes = has["Boxes"] or has["Corner Boxes"] or false
    cfg.BoxType = has["Corner Boxes"] and "Corner" or "Normal"
    cfg.BoxFill.Enabled = has["Box Fill"] or false
    cfg.Names = has["Names"] or false
    cfg.Distance.Enabled = has["Distance"] or false
    cfg.HealthBar.Enabled = has["Health Bar"] or false
    cfg.Chams.Enabled = has["Chams"] or false
    cfg.Skeleton.Enabled = has["Skeleton"] or false
    cfg.OffScreenArrows.Enabled = has["Off-Screen Arrows"] or false
    cfg.Flags.Enabled = has["Flags"] or false
    cfg.TextOutline = has["Text Outlines"] or false
    cfg.Outlines.Style = has["Box Outlines"] and "Full" or "None"
    cfg.HealthBar.ShowText = has["HP Text"] or false
    cfg.BoxFill.Gradient.Enabled = has["Box Gradient"] or false
end

-- Toggle — just flips Enabled on the live config
MobESPBox:AddToggle("MobESPEnabled", {
    Text = "Enable Mob ESP",
    Default = false,
    Description = "Shows mobs nearby",
    Callback = function(v)
        cfg.Enabled = v
    end,
})

-- Component multi-select
MobESPBox:AddDropdown("MobESPComps", {
    Text = "Components",
    Values = {
        "Boxes", "Corner Boxes", "Box Fill", "Box Gradient", "Box Outlines",
        "Names", "Text Outlines", "Distance",
        "Health Bar", "HP Text",
        "Chams", "Skeleton", "Off-Screen Arrows", "Flags",
    },
    Default = {"Boxes", "Names", "Distance"},
    Multi = true,
    Callback = applyComponents,
})

MobESPBox:AddDropdown("MobChamsType", {
    Text = "Chams Type",
    Values = {"Highlight", "Adornment"},
    Default = "Highlight",
    Callback = function(v) cfg.Chams.Type = v end,
})

MobESPBox:AddDropdown("MobHPPos", {
    Text = "Health Bar Position",
    Values = {"Left", "Right", "Top", "Bottom"},
    Default = "Left",
    Callback = function(v) cfg.HealthBar.Position = v end,
})

MobESPBox:AddDropdown("MobFlagPos", {
    Text = "Flags Position",
    Values = {"Left", "Right"},
    Default = "Right",
    Callback = function(v) cfg.Flags.Position = v end,
})

MobESPBox:AddDivider()

MobESPBox:AddSlider("MobESPFPS", {
    Text = "FPS Limit",
    Default = 30, Min = 10, Max = 144, Decimals = 0, Suffix = " fps",
    Callback = function(v) cfg.LimitFPS = v end,
})

MobESPBox:AddSlider("MobESPDist", {
    Text = "Max Distance",
    Default = 500, Min = 50, Max = 5000, Decimals = 0, Suffix = " studs",
    Callback = function(v) cfg.MaxDistance = v end,
})

------------------------------------------------------------
-- MOB ESP STYLE
------------------------------------------------------------
MobStyleBox:AddColorPicker("MobBoxColor", {
    Text = "Box Color",
    Default = Color3.fromRGB(255, 80, 80),
    Callback = function(c)
        cfg.BoxColor = c
        cfg.BoxFill.Color = c
        cfg.BoxFill.Gradient.Color1 = c
    end,
})

MobStyleBox:AddColorPicker("MobChamsColor", {
    Text = "Chams Fill Color",
    Default = Color3.fromRGB(255, 80, 80),
    Callback = function(c)
        cfg.Chams.Highlight.FillColor = c
        cfg.Chams.Adornment.Color = c
        cfg.Chams.MeshChams.FillColor = c
    end,
})

MobStyleBox:AddColorPicker("MobTextColor", {
    Text = "Text Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        cfg.TextColor = c
        cfg.Distance.Color = c
    end,
})

MobStyleBox:AddColorPicker("MobSkelColor", {
    Text = "Skeleton Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c) cfg.Skeleton.Color = c end,
})

MobStyleBox:AddColorPicker("MobArrowColor", {
    Text = "Arrow Color",
    Default = Color3.fromRGB(255, 80, 80),
    Callback = function(c) cfg.OffScreenArrows.Color = c end,
})

MobStyleBox:AddDivider()

MobStyleBox:AddSlider("MobBoxThick", {
    Text = "Box Thickness",
    Default = 1, Min = 1, Max = 4, Decimals = 0, Suffix = "px",
    Callback = function(v) cfg.BoxThickness = v end,
})

MobStyleBox:AddSlider("MobTextSize", {
    Text = "Text Size",
    Default = 12, Min = 8, Max = 20, Decimals = 0, Suffix = "px",
    Callback = function(v) cfg.TextSize = v; cfg.Distance.TextSize = v end,
})

MobStyleBox:AddSlider("MobChamsTrans", {
    Text = "Chams Fill Transparency",
    Default = 70, Min = 0, Max = 100, Decimals = 0, Suffix = "%",
    Callback = function(v)
        local t = v / 100
        cfg.Chams.Highlight.FillTransparency = t
        cfg.Chams.Adornment.Transparency = t
        cfg.Chams.MeshChams.FillTransparency = t
    end,
})

MobStyleBox:AddSlider("MobFillTrans", {
    Text = "Box Fill Transparency",
    Default = 85, Min = 0, Max = 100, Decimals = 0, Suffix = "%",
    Callback = function(v) cfg.BoxFill.Transparency = v / 100 end,
})

MobStyleBox:AddSlider("MobArrowRadius", {
    Text = "Arrow Orbit Radius",
    Default = 100, Min = 50, Max = 300, Decimals = 0, Suffix = "px",
    Callback = function(v) cfg.OffScreenArrows.OrbitRadius = v end,
})

------------------------------------------------------------
-- NPC ESP
------------------------------------------------------------
local NpcESPBox = NpcEspTab:AddGroupbox("NPC ESP")
local NpcStyleBox = NpcEspTab:AddGroupbox("NPC ESP Style")

local _npcDirEntry = {
    DisplayName = "",
    Path = "workspace.NPCs",
    Multiple = true,
    Recursive = false,
    Cheap = false,
    NonHuman = true,
    NoStatus = true,
    Contains = {},
    Names = {""},
    Config = {
        Boxes = true,
        BoxType = "Normal",
        BoxColor = Color3.fromRGB(100, 200, 255),
        BoxThickness = 1,
        TextOutline = true,
        TextOutlineStyle = "Full",
        TextColor = Color3.fromRGB(100, 200, 255),
        Names = true,
        Outlines = { Style = "Full", Color = Color3.fromRGB(0, 0, 0), Thickness = 1 },
        BoxFill = { Enabled = false, Color = Color3.fromRGB(100, 200, 255), Transparency = 0.85, Gradient = { Enabled = false, Color1 = Color3.fromRGB(100, 200, 255), Color2 = Color3.fromRGB(200, 255, 255), Color3 = Color3.fromRGB(100, 200, 255), Rotation = 0, Animated = false, Speed = 64, Direction = "Right" } },
        Distance = { Enabled = true, Color = Color3.fromRGB(180, 180, 180) },
        HealthBar = { Enabled = false, Position = "Left", SideGap = 3, Width = 5, ShowText = false, TextFollowBar = false, HideWhenFullHP = false, FollowGradientColorText = true, Font = "Proggy Clean", TextSize = 13, Outline = { Style = "Full", Color = Color3.fromRGB(0, 0, 0) }, Gradient = { Enabled = true, Color1 = Color3.fromRGB(0, 255, 0), Color2 = Color3.fromRGB(255, 255, 0), Color3 = Color3.fromRGB(255, 0, 0) } },
        Chams = { Enabled = false, Type = "Highlight", Highlight = { FillColor = Color3.fromRGB(100, 200, 255), FillTransparency = 0.7, OutlineColor = Color3.fromRGB(255, 255, 255), OutlineTransparency = 0, VisibleCheck = false }, Adornment = { Color = Color3.fromRGB(100, 200, 255), VisibleColor = Color3.fromRGB(0, 255, 0), Transparency = 0.6, AlwaysOnTop = true, VisibleCheck = false } },
        Skeleton = { Enabled = false, Color = Color3.fromRGB(100, 200, 255), Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0) },
        OffScreenArrows = { Enabled = false, Size = 14, Color = Color3.fromRGB(100, 200, 255), OrbitRadius = 100, ArrowMode = "Camera", Outline = true, OutlineColor = Color3.fromRGB(0, 0, 0), Names = { Enabled = true, Font = "Smallest Pixel-7", TextSize = 9, Color = Color3.fromRGB(255,255,255), Outline = true, OutlineColor = Color3.fromRGB(0,0,0), Side = "Bottom", Gap = 4 }, Distance = { Enabled = true, Font = "Smallest Pixel-7", TextSize = 9, Color = Color3.fromRGB(200,200,200), Outline = false, OutlineColor = Color3.fromRGB(0,0,0), Side = "Bottom", Gap = 2 } },
        Flags = { Enabled = false, Position = "Right", Gap = 2, SideGap = 4, TextGap = 2, OutlineStyle = "Full", Font = "Smallest Pixel-7", TextSize = 9, Options = { Idle = true, Moving = true, Jumping = true, Swimming = false }, Colors = { Idle = Color3.fromRGB(200, 200, 200), Moving = Color3.fromRGB(255, 200, 50), Jumping = Color3.fromRGB(100, 200, 255), Swimming = Color3.fromRGB(65, 65, 255) } },
    },
}
local _npcEspActive = false

local function npcApplyComponents(selected)
    local has = {}
    for _, v in ipairs(selected) do has[v] = true end
    local c = _npcDirEntry.Config
    c.Boxes = has["Boxes"] or has["Corner Boxes"] or false
    c.BoxType = has["Corner Boxes"] and "Corner" or "Normal"
    c.BoxFill.Enabled = has["Box Fill"] or false
    c.Names = has["Names"] or false
    c.Distance.Enabled = has["Distance"] or false
    c.HealthBar.Enabled = has["Health Bar"] or false
    c.Chams.Enabled = has["Chams"] or false
    c.Skeleton.Enabled = has["Skeleton"] or false
    c.OffScreenArrows.Enabled = has["Off-Screen Arrows"] or false
    c.Flags.Enabled = has["Flags"] or false
    c.TextOutline = has["Text Outlines"] or false
    c.Outlines.Style = has["Box Outlines"] and "Full" or "None"
    c.HealthBar.ShowText = has["HP Text"] or false
    c.BoxFill.Gradient.Enabled = has["Box Gradient"] or false
end

NpcESPBox:AddToggle("NpcESPEnabled", {
    Text = "Enable NPC ESP",
    Default = false,
    Description = "Shows NPCs nearby",
    Callback = function(v)
        _npcEspActive = v
        if v then
            table.insert(cfg.Directories, _npcDirEntry)
        else
            for i, dir in ipairs(cfg.Directories) do
                if dir == _npcDirEntry then
                    table.remove(cfg.Directories, i)
                    break
                end
            end
        end
    end,
})

NpcESPBox:AddDropdown("NpcESPComps", {
    Text = "Components",
    Values = {
        "Boxes", "Corner Boxes", "Box Fill", "Box Gradient", "Box Outlines",
        "Names", "Text Outlines", "Distance",
        "Health Bar", "HP Text",
        "Chams", "Skeleton", "Off-Screen Arrows", "Flags",
    },
    Default = {"Boxes", "Names", "Distance"},
    Multi = true,
    Callback = npcApplyComponents,
})

NpcESPBox:AddDropdown("NpcChamsType", {
    Text = "Chams Type",
    Values = {"Highlight", "Adornment"},
    Default = "Highlight",
    Callback = function(v) _npcDirEntry.Config.Chams.Type = v end,
})

NpcESPBox:AddDropdown("NpcHPPos", {
    Text = "Health Bar Position",
    Values = {"Left", "Right", "Top", "Bottom"},
    Default = "Left",
    Callback = function(v) _npcDirEntry.Config.HealthBar.Position = v end,
})

NpcESPBox:AddDropdown("NpcFlagPos", {
    Text = "Flags Position",
    Values = {"Left", "Right"},
    Default = "Right",
    Callback = function(v) _npcDirEntry.Config.Flags.Position = v end,
})

NpcESPBox:AddDivider()

-- NPC Style
NpcStyleBox:AddColorPicker("NpcBoxColor", {
    Text = "Box Color",
    Default = Color3.fromRGB(100, 200, 255),
    Callback = function(c)
        _npcDirEntry.Config.BoxColor = c
        _npcDirEntry.Config.BoxFill.Color = c
        _npcDirEntry.Config.BoxFill.Gradient.Color1 = c
    end,
})

NpcStyleBox:AddColorPicker("NpcChamsColor", {
    Text = "Chams Fill Color",
    Default = Color3.fromRGB(100, 200, 255),
    Callback = function(c)
        _npcDirEntry.Config.Chams.Highlight.FillColor = c
        _npcDirEntry.Config.Chams.Adornment.Color = c
    end,
})

NpcStyleBox:AddColorPicker("NpcTextColor", {
    Text = "Text Color",
    Default = Color3.fromRGB(100, 200, 255),
    Callback = function(c)
        _npcDirEntry.Config.TextColor = c
        _npcDirEntry.Config.Distance.Color = c
    end,
})

NpcStyleBox:AddColorPicker("NpcSkelColor", {
    Text = "Skeleton Color",
    Default = Color3.fromRGB(100, 200, 255),
    Callback = function(c) _npcDirEntry.Config.Skeleton.Color = c end,
})

NpcStyleBox:AddColorPicker("NpcArrowColor", {
    Text = "Arrow Color",
    Default = Color3.fromRGB(100, 200, 255),
    Callback = function(c) _npcDirEntry.Config.OffScreenArrows.Color = c end,
})

NpcStyleBox:AddDivider()

NpcStyleBox:AddSlider("NpcBoxThick", {
    Text = "Box Thickness",
    Default = 1, Min = 1, Max = 4, Decimals = 0, Suffix = "px",
    Callback = function(v) _npcDirEntry.Config.BoxThickness = v end,
})

NpcStyleBox:AddSlider("NpcTextSize", {
    Text = "Text Size",
    Default = 12, Min = 8, Max = 20, Decimals = 0, Suffix = "px",
    Callback = function(v) _npcDirEntry.Config.TextSize = v; _npcDirEntry.Config.Distance.TextSize = v end,
})

NpcStyleBox:AddSlider("NpcChamsTrans", {
    Text = "Chams Fill Transparency",
    Default = 70, Min = 0, Max = 100, Decimals = 0, Suffix = "%",
    Callback = function(v)
        local t = v / 100
        _npcDirEntry.Config.Chams.Highlight.FillTransparency = t
        _npcDirEntry.Config.Chams.Adornment.Transparency = t
    end,
})

NpcStyleBox:AddSlider("NpcFillTrans", {
    Text = "Box Fill Transparency",
    Default = 85, Min = 0, Max = 100, Decimals = 0, Suffix = "%",
    Callback = function(v) _npcDirEntry.Config.BoxFill.Transparency = v / 100 end,
})

NpcStyleBox:AddSlider("NpcArrowRadius", {
    Text = "Arrow Orbit Radius",
    Default = 100, Min = 50, Max = 300, Decimals = 0, Suffix = "px",
    Callback = function(v) _npcDirEntry.Config.OffScreenArrows.OrbitRadius = v end,
})

------------------------------------------------------------
-- RIFT ESP
------------------------------------------------------------
local RiftBox = RiftEspTab:AddGroupbox("Rift ESP")

local _riftEspEnabled = false
local _riftHighlights = {}
local _riftLabels = {}
local _riftConn = nil
local _riftColor = Color3.fromRGB(180, 50, 255)

local function cleanRiftESP()
    for _, hl in pairs(_riftHighlights) do pcall(function() hl:Destroy() end) end
    for _, bb in pairs(_riftLabels) do pcall(function() bb:Destroy() end) end
    _riftHighlights = {}
    _riftLabels = {}
    if _riftConn then _riftConn:Disconnect(); _riftConn = nil end
end

local function updateRiftESP()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("BasePart") and v.Name:match("RiftSpawn") then
            if not _riftHighlights[v] then
                local hl = Instance.new("Highlight")
                hl.FillColor = _riftColor
                hl.FillTransparency = 0.5
                hl.OutlineColor = _riftColor
                hl.OutlineTransparency = 0
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Adornee = v
                hl.Parent = game:GetService("CoreGui")
                _riftHighlights[v] = hl

                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 200, 0, 30)
                bb.StudsOffset = Vector3.new(0, 5, 0)
                bb.AlwaysOnTop = true
                bb.Adornee = v
                bb.Parent = game:GetService("CoreGui")
                local txt = Instance.new("TextLabel")
                txt.Size = UDim2.new(1, 0, 1, 0)
                txt.BackgroundTransparency = 1
                txt.TextColor3 = _riftColor
                txt.TextStrokeTransparency = 0
                txt.TextStrokeColor3 = Color3.new(0, 0, 0)
                txt.Font = Enum.Font.GothamBold
                txt.TextSize = 14
                txt.Text = "RIFT"
                txt.Parent = bb
                _riftLabels[v] = bb
            end
            -- Update distance text
            local bb = _riftLabels[v]
            if bb and myHrp then
                local dist = math.floor((v.Position - myHrp.Position).Magnitude)
                bb:FindFirstChildOfClass("TextLabel").Text = "RIFT [" .. dist .. "m]"
            end
            -- Update color
            local hl = _riftHighlights[v]
            if hl then hl.FillColor = _riftColor; hl.OutlineColor = _riftColor end
            if bb then bb:FindFirstChildOfClass("TextLabel").TextColor3 = _riftColor end
        end
    end
    -- Clean up destroyed rifts
    for part, hl in pairs(_riftHighlights) do
        if not part.Parent then
            hl:Destroy(); _riftHighlights[part] = nil
            if _riftLabels[part] then _riftLabels[part]:Destroy(); _riftLabels[part] = nil end
        end
    end
end

RiftBox:AddToggle("RiftESPEnabled", {
    Text = "Enable Rift ESP",
    Default = false,
    Description = "Shows rift locations",
    Callback = function(v)
        _riftEspEnabled = v
        if v then
            _riftConn = RunService.Heartbeat:Connect(updateRiftESP)
        else
            cleanRiftESP()
        end
    end,
})

RiftBox:AddColorPicker("RiftColor", {
    Text = "Rift Color",
    Default = Color3.fromRGB(180, 50, 255),
    Callback = function(c) _riftColor = c end,
})

------------------------------------------------------------
-- MIRROR ESP
------------------------------------------------------------
local MirrorBox = MirrorEspTab:AddGroupbox("Mirror ESP")

local _mirrorEspEnabled = false
local _mirrorHighlights = {}
local _mirrorLabels = {}
local _mirrorConn = nil
local _mirrorColor = Color3.fromRGB(255, 200, 50)

local function cleanMirrorESP()
    for _, hl in pairs(_mirrorHighlights) do pcall(function() hl:Destroy() end) end
    for _, bb in pairs(_mirrorLabels) do pcall(function() bb:Destroy() end) end
    _mirrorHighlights = {}
    _mirrorLabels = {}
    if _mirrorConn then _mirrorConn:Disconnect(); _mirrorConn = nil end
end

local function updateMirrorESP()
    local mirrors = workspace:FindFirstChild("Mirrors")
    if not mirrors then return end
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")

    for _, m in ipairs(mirrors:GetChildren()) do
        local part = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart")
        if not part then continue end

        if not _mirrorHighlights[m] then
            local hl = Instance.new("Highlight")
            hl.FillColor = _mirrorColor
            hl.FillTransparency = 0.6
            hl.OutlineColor = _mirrorColor
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = m
            hl.Parent = game:GetService("CoreGui")
            _mirrorHighlights[m] = hl

            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 200, 0, 30)
            bb.StudsOffset = Vector3.new(0, 5, 0)
            bb.AlwaysOnTop = true
            bb.Adornee = part
            bb.Parent = game:GetService("CoreGui")
            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.TextColor3 = _mirrorColor
            txt.TextStrokeTransparency = 0
            txt.TextStrokeColor3 = Color3.new(0, 0, 0)
            txt.Font = Enum.Font.GothamBold
            txt.TextSize = 14
            txt.Text = m.Name
            txt.Parent = bb
            _mirrorLabels[m] = bb
        end

        local bb = _mirrorLabels[m]
        if bb and myHrp then
            local dist = math.floor((part.Position - myHrp.Position).Magnitude)
            bb:FindFirstChildOfClass("TextLabel").Text = m.Name .. " [" .. dist .. "m]"
        end
        local hl = _mirrorHighlights[m]
        if hl then hl.FillColor = _mirrorColor; hl.OutlineColor = _mirrorColor end
        if bb then bb:FindFirstChildOfClass("TextLabel").TextColor3 = _mirrorColor end
    end
end

MirrorBox:AddToggle("MirrorESPEnabled", {
    Text = "Enable Mirror ESP",
    Default = false,
    Description = "Shows mirror locations",
    Callback = function(v)
        _mirrorEspEnabled = v
        if v then
            _mirrorConn = RunService.Heartbeat:Connect(updateMirrorESP)
        else
            cleanMirrorESP()
        end
    end,
})

MirrorBox:AddColorPicker("MirrorColor", {
    Text = "Mirror Color",
    Default = Color3.fromRGB(255, 200, 50),
    Callback = function(c) _mirrorColor = c end,
})

------------------------------------------------------------
-- PLAYER ESP
------------------------------------------------------------
local PlayerBox = PlayerEspTab:AddGroupbox("Player ESP")

local _playerEspEnabled = false
local _playerHighlights = {}
local _playerLabels = {}
local _playerEspConn = nil
local _playerColor = Color3.fromRGB(255, 75, 75)

local function cleanPlayerESP()
    for _, hl in pairs(_playerHighlights) do pcall(function() hl:Destroy() end) end
    for _, bb in pairs(_playerLabels) do pcall(function() bb:Destroy() end) end
    _playerHighlights = {}
    _playerLabels = {}
    if _playerEspConn then _playerEspConn:Disconnect(); _playerEspConn = nil end
end

local function updatePlayerESP()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local char = plr.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            if _playerHighlights[plr] then
                _playerHighlights[plr]:Destroy(); _playerHighlights[plr] = nil
            end
            if _playerLabels[plr] then
                _playerLabels[plr]:Destroy(); _playerLabels[plr] = nil
            end
            continue
        end

        if not _playerHighlights[plr] then
            local hl = Instance.new("Highlight")
            hl.FillColor = _playerColor
            hl.FillTransparency = 0.5
            hl.OutlineColor = _playerColor
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = char
            hl.Parent = game:GetService("CoreGui")
            _playerHighlights[plr] = hl

            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 200, 0, 40)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            bb.Adornee = hrp
            bb.Parent = game:GetService("CoreGui")
            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, 0, 0.5, 0)
            txt.BackgroundTransparency = 1
            txt.TextColor3 = _playerColor
            txt.TextStrokeTransparency = 0
            txt.TextStrokeColor3 = Color3.new(0, 0, 0)
            txt.Font = Enum.Font.GothamBold
            txt.TextSize = 14
            txt.Text = plr.Name
            txt.Parent = bb
            local hp = Instance.new("TextLabel")
            hp.Size = UDim2.new(1, 0, 0.5, 0)
            hp.Position = UDim2.new(0, 0, 0.5, 0)
            hp.BackgroundTransparency = 1
            hp.TextColor3 = Color3.fromRGB(100, 255, 100)
            hp.TextStrokeTransparency = 0
            hp.TextStrokeColor3 = Color3.new(0, 0, 0)
            hp.Font = Enum.Font.GothamBold
            hp.TextSize = 12
            hp.Text = ""
            hp.Name = "HP"
            hp.Parent = bb
            _playerLabels[plr] = bb
        end

        local bb = _playerLabels[plr]
        if bb and myHrp then
            local dist = math.floor((hrp.Position - myHrp.Position).Magnitude)
            local children = bb:GetChildren()
            for _, c in ipairs(children) do
                if c.Name ~= "HP" then
                    c.Text = plr.Name .. " [" .. dist .. "m]"
                    c.TextColor3 = _playerColor
                else
                    c.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                end
            end
        end
        local hl = _playerHighlights[plr]
        if hl then hl.FillColor = _playerColor; hl.OutlineColor = _playerColor end
    end

    -- Clean disconnected players
    for plr, hl in pairs(_playerHighlights) do
        if not plr.Parent then
            hl:Destroy(); _playerHighlights[plr] = nil
            if _playerLabels[plr] then _playerLabels[plr]:Destroy(); _playerLabels[plr] = nil end
        end
    end
end

PlayerBox:AddToggle("PlayerESPEnabled", {
    Text = "Enable Player ESP",
    Default = false,
    Description = "Shows players through walls",
    Callback = function(v)
        _playerEspEnabled = v
        if v then
            _playerEspConn = RunService.Heartbeat:Connect(updatePlayerESP)
        else
            cleanPlayerESP()
        end
    end,
})

PlayerBox:AddColorPicker("PlayerColor", {
    Text = "Player Color",
    Default = Color3.fromRGB(255, 75, 75),
    Callback = function(c) _playerColor = c end,
})

------------------------------------------------------------
-- NAVIGATION — TP to Player
------------------------------------------------------------
local NavPlayerBox = NavTab:AddGroupbox("Teleport to Player")

NavPlayerBox:AddDropdown("PlayerTPSelect", {
    Text = "Select Player",
    Values = (function()
        local r = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then r[#r+1] = plr.Name end
        end
        table.sort(r)
        return r
    end)(),
    Default = "",
    Callback = function() end,
})

NavPlayerBox:AddButton({
    Text = "Teleport",
    Func = function()
        local sel = Library.Flags["PlayerTPSelect"]
        if not sel or sel == "" then return end
        local plr = Players:FindFirstChild(sel)
        if not plr or not plr.Character then return end
        local targetHrp = plr.Character:FindFirstChild("HumanoidRootPart")
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if targetHrp and myHrp then
            myHrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 5)
        end
    end,
})

NavPlayerBox:AddButton({
    Text = "Refresh Players",
    Func = function()
        local r = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then r[#r+1] = plr.Name end
        end
        table.sort(r)
        if Library.Options["PlayerTPSelect"] then
            Library.Options["PlayerTPSelect"]:SetValues(r)
        end
    end,
})

------------------------------------------------------------
-- NAVIGATION — TP to NPC
------------------------------------------------------------
local NavNpcBox = NavTab:AddGroupbox("Teleport to NPC")

-- Build NPC name list from workspace
local _npcNames = {}
do
    local npcs = workspace:FindFirstChild("NPCs")
    if npcs then
        local seen = {}
        for _, npc in ipairs(npcs:GetChildren()) do
            if npc:FindFirstChild("HumanoidRootPart") and not seen[npc.Name] then
                seen[npc.Name] = true
                table.insert(_npcNames, npc.Name)
            end
        end
        table.sort(_npcNames)
    end
end

local _selectedNpc = nil

NavNpcBox:AddDropdown("NpcTPSelect", {
    Text = "Select NPC",
    Values = _npcNames,
    Default = _npcNames[1] or "",
    Callback = function(v) _selectedNpc = v end,
})

NavNpcBox:AddButton({
    Text = "Teleport",
    Func = function()
        if not _selectedNpc then return end
        local npcs = workspace:FindFirstChild("NPCs")
        if not npcs then return end
        for _, npc in ipairs(npcs:GetChildren()) do
            if npc.Name == _selectedNpc then
                local hrp = npc:FindFirstChild("HumanoidRootPart")
                local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp and myHrp then
                    myHrp.CFrame = hrp.CFrame * CFrame.new(0, 0, 5)
                end
                break
            end
        end
    end,
})

NavNpcBox:AddButton({
    Text = "Refresh NPC List",
    Func = function()
        local npcs = workspace:FindFirstChild("NPCs")
        if not npcs then return end
        local newNames = {}
        local seen = {}
        for _, npc in ipairs(npcs:GetChildren()) do
            if npc:FindFirstChild("HumanoidRootPart") and not seen[npc.Name] then
                seen[npc.Name] = true
                table.insert(newNames, npc.Name)
            end
        end
        table.sort(newNames)
        _npcNames = newNames
        if Library.Options["NpcTPSelect"] then
            Library.Options["NpcTPSelect"]:SetValues(newNames)
        end
    end,
})

------------------------------------------------------------
-- NAVIGATION — TP to Rift
------------------------------------------------------------
local NavRiftBox = NavTab:AddGroupbox("Teleport to Rift")

NavRiftBox:AddDropdown("RiftTPSelect", {
    Text = "Select Rift",
    Values = (function()
        local r = {}
        for _, v in ipairs(workspace:GetChildren()) do
            if v:IsA("BasePart") and v.Name:match("RiftSpawn") then
                table.insert(r, v.Name)
            end
        end
        table.sort(r)
        return r
    end)(),
    Default = "",
    Callback = function() end,
})

NavRiftBox:AddButton({
    Text = "Teleport",
    Func = function()
        local sel = Library.Flags["RiftTPSelect"]
        if not sel or sel == "" then return end
        local rift = workspace:FindFirstChild(sel)
        if not rift then return end
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if myHrp then
            myHrp.CFrame = CFrame.new(rift.Position + Vector3.new(0, 5, 0))
        end
    end,
})

NavRiftBox:AddButton({
    Text = "Teleport to Nearest Rift",
    Func = function()
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then return end
        local best, bestDist = nil, math.huge
        for _, v in ipairs(workspace:GetChildren()) do
            if v:IsA("BasePart") and v.Name:match("RiftSpawn") then
                local d = (v.Position - myHrp.Position).Magnitude
                if d < bestDist then best, bestDist = v, d end
            end
        end
        if best then
            myHrp.CFrame = CFrame.new(best.Position + Vector3.new(0, 5, 0))
        end
    end,
})

NavRiftBox:AddButton({
    Text = "Refresh Rift List",
    Func = function()
        local r = {}
        for _, v in ipairs(workspace:GetChildren()) do
            if v:IsA("BasePart") and v.Name:match("RiftSpawn") then
                table.insert(r, v.Name)
            end
        end
        table.sort(r)
        if Library.Options["RiftTPSelect"] then
            Library.Options["RiftTPSelect"]:SetValues(r)
        end
    end,
})

------------------------------------------------------------
-- NAVIGATION — TP to Zone
------------------------------------------------------------
local NavZoneBox = NavTab:AddGroupbox("Teleport to Zone")

local _zoneNames = {}
do
    local zones = workspace:FindFirstChild("Zones")
    if zones then
        local seen = {}
        for _, z in ipairs(zones:GetChildren()) do
            if not seen[z.Name] then
                seen[z.Name] = true
                table.insert(_zoneNames, z.Name)
            end
        end
        table.sort(_zoneNames)
    end
end

NavZoneBox:AddDropdown("ZoneTPSelect", {
    Text = "Select Zone",
    Values = _zoneNames,
    Default = _zoneNames[1] or "",
    Callback = function() end,
})

NavZoneBox:AddButton({
    Text = "Teleport",
    Func = function()
        local sel = Library.Flags["ZoneTPSelect"]
        if not sel or sel == "" then return end
        local zones = workspace:FindFirstChild("Zones")
        if not zones then return end
        for _, z in ipairs(zones:GetChildren()) do
            if z.Name == sel and z:IsA("BasePart") then
                local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    myHrp.CFrame = CFrame.new(z.Position + Vector3.new(0, 5, 0))
                end
                break
            end
        end
    end,
})

------------------------------------------------------------
-- NAVIGATION — TP to Mirror
------------------------------------------------------------
local NavMirrorBox = NavTab:AddGroupbox("Teleport to Mirror")

local _mirrorNames = {}
do
    local mirrors = workspace:FindFirstChild("Mirrors")
    if mirrors then
        for _, m in ipairs(mirrors:GetChildren()) do
            table.insert(_mirrorNames, m.Name)
        end
        table.sort(_mirrorNames)
    end
end

NavMirrorBox:AddDropdown("MirrorTPSelect", {
    Text = "Select Mirror",
    Values = _mirrorNames,
    Default = _mirrorNames[1] or "",
    Callback = function() end,
})

NavMirrorBox:AddButton({
    Text = "Teleport",
    Func = function()
        local sel = Library.Flags["MirrorTPSelect"]
        if not sel or sel == "" then return end
        local mirrors = workspace:FindFirstChild("Mirrors")
        if not mirrors then return end
        for _, m in ipairs(mirrors:GetChildren()) do
            if m.Name == sel then
                local part = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart")
                local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if part and myHrp then
                    myHrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 5, 0))
                end
                break
            end
        end
    end,
})

NavMirrorBox:AddButton({
    Text = "Teleport to Nearest Mirror",
    Func = function()
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then return end
        local mirrors = workspace:FindFirstChild("Mirrors")
        if not mirrors then return end
        local best, bestDist = nil, math.huge
        for _, m in ipairs(mirrors:GetChildren()) do
            local part = m:IsA("BasePart") and m or m:FindFirstChildWhichIsA("BasePart")
            if part then
                local d = (part.Position - myHrp.Position).Magnitude
                if d < bestDist then best, bestDist = part, d end
            end
        end
        if best then
            myHrp.CFrame = CFrame.new(best.Position + Vector3.new(0, 5, 0))
        end
    end,
})

------------------------------------------------------------
-- NAVIGATION — Portals
------------------------------------------------------------
local NavPortalBox = NavTab:AddGroupbox("Teleport to Portal")

local _portalList = {
    { label = "Beach Portal", path = "Map.Beach.Portal.Portal" },
    { label = "Prairie Hole", path = "Map.Prairie.Hole.Teleport" },
    { label = "IceWorld Teleport", path = "Map.IceWorld.Teleport" },
    { label = "IceWorld Elevator", path = "Map.IceWorld.Elevator" },
    { label = "Labyrinth Entrance", path = "Map.NorthSea.Labyrinth.EntranceTrigger" },
    { label = "Monastery Elevator", path = "Map.Monastery.Elevator" },
    { label = "Landfill Elevator", path = "Map.Landfill.BowlElevator.Root" },
    { label = "Denest Plate", path = "Map.Denest.Plate.Plate" },
    { label = "BossIsland Plate", path = "Map.BossIsland.Plate" },
    { label = "TowerIsland Plate", path = "Map.TowerIsland.Plate" },
    { label = "CloudWilds Orb", path = "Map.CloudWilds.Orb.Orb.Core" },
    { label = "Sinister Sea Whirlpool", path = "Map.SinisterSea.Whirlpool" },
}

local _portalLabels = {}
for _, p in ipairs(_portalList) do table.insert(_portalLabels, p.label) end

local _selectedPortal = nil

NavPortalBox:AddDropdown("PortalTPSelect", {
    Text = "Select Portal",
    Values = _portalLabels,
    Default = _portalLabels[1] or "",
    Callback = function(v) _selectedPortal = v end,
})

NavPortalBox:AddButton({
    Text = "Teleport",
    Func = function()
        if not _selectedPortal then return end
        local entry
        for _, p in ipairs(_portalList) do
            if p.label == _selectedPortal then entry = p; break end
        end
        if not entry then return end

        -- Resolve path
        local parts = string.split(entry.path, ".")
        local current = workspace
        for _, name in ipairs(parts) do
            current = current:FindFirstChild(name)
            if not current then return end
        end

        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp or not current:IsA("BasePart") then return end

        -- Teleport to it
        myHrp.CFrame = CFrame.new(current.Position + Vector3.new(0, 3, 0))

        -- Fire TouchInterest
        task.wait(0.2)
        local ti = current:FindFirstChild("TouchInterest") or current:FindFirstChildOfClass("TouchTransmitter")
        if ti then
            firetouchinterest(myHrp, current, 0)
            task.wait(0.1)
            firetouchinterest(myHrp, current, 1)
        end
    end,
})

------------------------------------------------------------
-- NAVIGATION — Gold Chest Farm
------------------------------------------------------------
local NavChestBox = NavTab:AddGroupbox("Gold Chest Farm")

local _chestFarming = false
NavChestBox:AddToggle("GoldChestFarm", {
    Text = "Gold Chest Farm",
    Default = false,
    Description = "Farms all gold chests",
    Callback = function(v)
        _chestFarming = v
        if not v then return end
        task.spawn(function()
            while _chestFarming do
                local gc = workspace:FindFirstChild("GoldChests")
                if not gc then break end
                for _, chest in ipairs(gc:GetChildren()) do
                    if not _chestFarming then break end
                    local root = chest:FindFirstChild("Root")
                    local part = root or chest:FindFirstChildWhichIsA("BasePart")
                    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if part and myHrp then
                        myHrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                        task.wait(1)
                        local prompt = root and root:FindFirstChildOfClass("ProximityPrompt")
                        if prompt then
                            fireproximityprompt(prompt)
                        end
                        task.wait(2)
                    end
                end
                task.wait(3)
            end
        end)
    end,
})

------------------------------------------------------------
-- NAVIGATION — Auto Harvest
------------------------------------------------------------
local NavHarvestBox = NavTab:AddGroupbox("Auto Harvest")

local _harvesting = false
NavHarvestBox:AddToggle("AutoHarvest", {
    Text = "Auto Harvest Items",
    Default = false,
    Description = "TPs to harvestables and picks them",
    Callback = function(v)
        _harvesting = v
        if not v then return end
        task.spawn(function()
            while _harvesting do
                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then task.wait(1); continue end
                for _, desc in ipairs(workspace:GetDescendants()) do
                    if not _harvesting then break end
                    if desc:IsA("ProximityPrompt") and desc.Enabled and (desc.ActionText == "Harvest" or desc.ActionText == "Pick Up") then
                        local part = desc.Parent
                        if part and part:IsA("BasePart") then
                            hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                            task.wait(0.5)
                            pcall(function() fireproximityprompt(desc) end)
                            task.wait(1)
                        end
                    end
                end
                task.wait(3)
            end
        end)
    end,
})

------------------------------------------------------------
-- NAVIGATION — Painting TP
------------------------------------------------------------
local NavPaintBox = NavTab:AddGroupbox("Teleport to Painting")

local function getPaintings()
    local list = {}
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") and desc.ActionText == "Enter" and desc.ObjectText == "Painting" then
            local parent = desc.Parent
            local zone = parent.Parent and parent.Parent.Name or parent.Name
            if not table.find(list, zone) then
                list[#list+1] = zone
            end
        end
    end
    table.sort(list)
    return list
end

NavPaintBox:AddDropdown("PaintingTPSelect", {
    Text = "Select Painting",
    Values = getPaintings(),
    Default = "",
    Callback = function() end,
})

NavPaintBox:AddButton({
    Text = "Teleport",
    Func = function()
        local sel = Library.Flags["PaintingTPSelect"]
        if not sel or sel == "" then return end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.ActionText == "Enter" and desc.ObjectText == "Painting" then
                local parent = desc.Parent
                local zone = parent.Parent and parent.Parent.Name or parent.Name
                if zone == sel and parent:IsA("BasePart") then
                    hrp.CFrame = CFrame.new(parent.Position + Vector3.new(0, 3, 0))
                    break
                end
            end
        end
    end,
})

NavPaintBox:AddButton({
    Text = "Refresh",
    Func = function()
        if Library.Options["PaintingTPSelect"] then
            Library.Options["PaintingTPSelect"]:SetValues(getPaintings())
        end
    end,
})

------------------------------------------------------------
-- MISC
------------------------------------------------------------
local MiscBossBox = MiscTab:AddGroupbox("Boss Spawns")

MiscBossBox:AddButton({
    Text = "SPAWN MAHORAGA",
    DoubleClick = true,
    Func = function()
        local trigger = workspace:FindFirstChild("Map")
            and workspace.Map:FindFirstChild("Landfill")
            and workspace.Map.Landfill:FindFirstChild("LorcanTrigger")
        if not trigger then return end
        local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then return end
        firetouchinterest(myHrp, trigger, 0)
        task.wait(0.1)
        firetouchinterest(myHrp, trigger, 1)
    end,
})

------------------------------------------------------------
-- MISC — Anti Detection
------------------------------------------------------------
local MiscSafetyBox2 = MiscTab:AddGroupbox("Stealth")

local _antiDetectConn = nil
MiscSafetyBox2:AddToggle("AntiDetection", {
    Text = "Anti Detection",
    Default = false,
    Description = "Mobs ignore you",
    Callback = function(v)
        if _antiDetectConn then _antiDetectConn:Disconnect(); _antiDetectConn = nil end
        if not v then return end
        _antiDetectConn = RunService.Heartbeat:Connect(function()
            local char = LP.Character; if not char then return end
            local det = char:FindFirstChild("Detected")
            if det then det:Destroy() end
        end)
    end,
})

local MiscPlayerBox = MiscTab:AddGroupbox("Player")

local _noFallConn = nil
MiscPlayerBox:AddToggle("NoFallDamage", {
    Text = "No Fall Damage",
    Default = false,
    Description = "Negates fall damage",
    Callback = function(v)
        if _noFallConn then _noFallConn:Disconnect(); _noFallConn = nil end
        if not v then return end
        _noFallConn = RunService.Heartbeat:Connect(function()
            local char = LP.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local vel = hrp.AssemblyLinearVelocity
            if vel.Y < -90 then
                hrp.AssemblyLinearVelocity = Vector3.new(vel.X, -90, vel.Z)
            end
        end)
    end,
})

-- Anti Stun
local _antiStunConn = nil
MiscPlayerBox:AddToggle("AntiStun", {
    Text = "Anti Stun",
    Default = false,
    Description = "Clears negative effects",
    Callback = function(p)
        if _antiStunConn then _antiStunConn:Disconnect(); _antiStunConn = nil end
        if not p then return end
        _antiStunConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local char = LP.Character; if not char then return end
                local status = char:FindFirstChild("Status"); if not status then return end
                for _, v in ipairs(status:GetChildren()) do
                    local n = v.Name:lower()
                    if n:find("slow") or n:find("stun") or n:find("freeze") or n:find("root") or n:find("immobil") or n:find("paraly") or n:find("bind") or n:find("snare") then
                        pcall(function() v:Destroy() end)
                    end
                end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
            end)
        end)
    end,
})

-- Remove Knockback
local _noKBConn = nil
MiscPlayerBox:AddToggle("RemoveKnockback", {
    Text = "Remove Knockback",
    Default = false,
    Description = "Cancels knockback forces",
    Callback = function(p)
        if _noKBConn then _noKBConn:Disconnect(); _noKBConn = nil end
        if not p then return end
        _noKBConn = RunService.Heartbeat:Connect(function()
            local char = LP.Character; if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            for _, v in ipairs(hrp:GetChildren()) do
                if v:IsA("BodyVelocity") or v:IsA("BodyPosition") or v:IsA("BodyForce") then
                    if v.Name ~= "WaterForce" and v.Name ~= "BalloonForce" then
                        v:Destroy()
                    end
                end
            end
        end)
    end,
})

-- No Roll Cooldown
local _noRollCDConn = nil
MiscPlayerBox:AddToggle("NoRollCooldown", {
    Text = "No Roll Cooldown",
    Default = false,
    Description = "Removes roll and dive cooldown",
    Callback = function(p)
        if _noRollCDConn then _noRollCDConn:Disconnect(); _noRollCDConn = nil end
        if not p then return end
        _noRollCDConn = RunService.Heartbeat:Connect(function()
            local char = LP.Character; if not char then return end
            local cc = char:FindFirstChild("ClientCooldown")
            if cc then cc:Destroy() end
            if not char:FindFirstChild("FreeRoll") then
                local fr = Instance.new("BoolValue")
                fr.Name = "FreeRoll"
                fr.Parent = char
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, v in ipairs(hrp:GetChildren()) do
                    if v.Name == "DiveForce" or v.Name == "RollForce" then
                        v:Destroy()
                    end
                end
            end
        end)
    end,
})

-- Admin/Mod Kick
local MiscSafetyBox = MiscTab:AddGroupbox("Safety")

local _adminKickConn = nil
MiscSafetyBox:AddToggle("AdminKick", {
    Text = "Kick on Admin/Mod",
    Default = false,
    Description = "Leaves if staff detected",
    Callback = function(p)
        if _adminKickConn then _adminKickConn:Disconnect(); _adminKickConn = nil end
        if not p then return end
        -- Check current players
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP and (plr:GetAttribute("Admin") == true or plr:GetAttribute("Mod") == true) then
                LP:Kick("Staff detected: " .. plr.Name)
                return
            end
        end
        -- Watch for new joins
        _adminKickConn = Players.PlayerAdded:Connect(function(plr)
            task.wait(1)
            if plr:GetAttribute("Admin") == true or plr:GetAttribute("Mod") == true then
                LP:Kick("Staff detected: " .. plr.Name)
            end
        end)
    end,
})

-- Server Hop & Rejoin
local MiscServerBox = MiscTab:AddGroupbox("Server")

MiscServerBox:AddButton({
    Text = "Server Hop",
    Func = function()
        local TP = game:GetService("TeleportService")
        local HS = game:GetService("HttpService")
        local placeId = game.PlaceId
        local ok, res = pcall(function()
            return HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100"))
        end)
        if ok and res then
            for _, s in ipairs(res.data or {}) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    pcall(function() TP:TeleportToPlaceInstance(placeId, s.id, LP) end)
                    return
                end
            end
        end
    end,
})

MiscServerBox:AddButton({
    Text = "Rejoin",
    Func = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
    end,
})

-- Force NPC Dialogue
local MiscNpcBox = MiscTab:AddGroupbox("NPC Interaction")

local _npcDialogNames = {}
do
    local npcs = workspace:FindFirstChild("NPCs")
    if npcs then
        local seen = {}
        for _, npc in ipairs(npcs:GetChildren()) do
            local dc = npc:FindFirstChild("DialogClick", true)
            if dc and dc:IsA("ProximityPrompt") and not seen[npc.Name] then
                seen[npc.Name] = true
                _npcDialogNames[#_npcDialogNames+1] = npc.Name
            end
        end
        table.sort(_npcDialogNames)
    end
end

MiscNpcBox:AddDropdown("ForceDialog", {
    Text = "Force NPC Dialogue",
    Values = _npcDialogNames,
    Default = _npcDialogNames[1] or "",
    Callback = function(v)
        if not v or v == "" then return end
        local npcs = workspace:FindFirstChild("NPCs"); if not npcs then return end
        for _, npc in ipairs(npcs:GetChildren()) do
            if npc.Name == v then
                local dc = npc:FindFirstChild("DialogClick", true)
                if dc and dc:IsA("ProximityPrompt") then
                    fireproximityprompt(dc)
                end
                break
            end
        end
    end,
})

MiscNpcBox:AddButton({
    Text = "Refresh NPC List",
    Func = function()
        local npcs = workspace:FindFirstChild("NPCs"); if not npcs then return end
        local names = {}; local seen = {}
        for _, npc in ipairs(npcs:GetChildren()) do
            local dc = npc:FindFirstChild("DialogClick", true)
            if dc and dc:IsA("ProximityPrompt") and not seen[npc.Name] then
                seen[npc.Name] = true
                names[#names+1] = npc.Name
            end
        end
        table.sort(names)
        _npcDialogNames = names
        if Library.Options["ForceDialog"] then
            Library.Options["ForceDialog"]:SetValues(names)
        end
    end,
})

------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------
Library:CreateSettingsTab(Window)
