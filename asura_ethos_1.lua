--==============================================================
-- Asura  •  Auto-Farm + Player Utility (EthosSuite)
-- Game: [UPDATE!] Asura  (PlaceId 13358463560, GameId 4652005960)
--
-- HOW THE STAT FARM WORKS (reverse-engineered):
--   Every training minigame LocalScript (PlayerGui.<X>Gain.Main) checks:
--       if _G.Replica.Data.Gamepass.AutoMacro.Enabled == true then auto-play
--   The game's shared _G is reachable via getrenv()._G and is WRITABLE.
--   Setting AutoMacro.Enabled = true makes the game auto-complete every
--   training minigame perfectly (the server grants the stat from the
--   client's minigame answers — no gamepass purchase needed).
--   Stations start by firing their ClickDetector (MaxActivationDistance 20).
--
--   Treadmill  → reads LP attribute "Treadmill" (Stamina/Speed/Fat)
--   SquatRack  → auto-picks LowerMuscle
--   BenchPress → auto-picks (upper muscle)
--   Pull-up    → auto-picks
--   Each cycle ~60s, then re-fire.
--
-- Verified executor caps: fireclickdetector, hookfunction, getrenv,
--   getconnections, queue_on_teleport.
--==============================================================

if getgenv and getgenv().Asura_Loaded then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Asura", Text = "Already loaded.", Duration = 3
        })
    end)
    return
end
if getgenv then getgenv().Asura_Loaded = true end

--========================== SERVICES ==========================
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local VirtualUser      = game:GetService("VirtualUser")
local VirtualInput     = game:GetService("VirtualInputManager")

local LP   = Players.LocalPlayer
local Cam  = workspace.CurrentCamera
local G    = (getgenv and getgenv()) or _G

--========================== HELPERS ===========================
local function getChar() return LP.Character end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local PLAYERS = Players:GetPlayers()
local function _refreshPlayers() PLAYERS = Players:GetPlayers() end
Players.PlayerAdded:Connect(_refreshPlayers)
Players.PlayerRemoving:Connect(function() task.defer(_refreshPlayers) end)

local _envCache
local function gameG()
    if _envCache then return _envCache end
    local ok, g = pcall(function() return getrenv()._G end)
    if ok and g then _envCache = g; return g end
    return _G
end

local function getReplicaData()
    local g = gameG()
    if g and g.Replica and g.Replica.Data then return g.Replica.Data end
    return nil
end

local function ensureAutoMacro()
    if (getgenv and getgenv() or _G).AsuraEating then return end
    pcall(function()
        local data = getReplicaData()
        if not data then return end
        local gp = data.Gamepass
        if not gp then return end
        if type(gp.AutoMacro) ~= "table" then gp.AutoMacro = {} end
        gp.AutoMacro.Bought  = true
        gp.AutoMacro.Enabled = true
    end)
end

local Events = ReplicatedStorage:FindFirstChild("Events")
local function ev(name)
    return Events and Events:FindFirstChild(name)
end
local function fireEv(name, ...)
    local r = ev(name)
    if not r then return false end
    local args = {...}
    return pcall(function()
        if r:IsA("RemoteEvent") then r:FireServer(table.unpack(args))
        elseif r:IsA("RemoteFunction") then return r:InvokeServer(table.unpack(args)) end
    end)
end

--========================= PERSISTENCE ========================
local SAVE = "asura_cfg_" .. tostring(LP.Name) .. ".json"
local _is, _rd, _wr = (isfile or function() return false end), (readfile or function() return "" end), (writefile or function() end)
local HttpService = game:GetService("HttpService")
local cfg = { Treadmill = "Stamina", CycleWait = 62, SavedPos = {}, DepositAmount = 0, WithdrawAmount = 0 }
pcall(function()
    if _is(SAVE) then
        local d = HttpService:JSONDecode(_rd(SAVE))
        if type(d) == "table" then for k, v in pairs(d) do cfg[k] = v end end
    end
end)
local function saveCfg() pcall(function() _wr(SAVE, HttpService:JSONEncode(cfg)) end) end

--========================= ETHOSSUITE =========================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/toeerolo-z/ethossuiterewrite/refs/heads/main/ethossuite.lua"))()

local Window = Library:CreateWindow({
    Title = "ZERO HUB — Asura",
    Version = "v1.0.0",
})

local function notify(t, c, d)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = t or "Asura", Text = c or "", Duration = d or 3,
        })
    end)
end
if getgenv then getgenv().Asura_Notify = notify end

--========================= STATE ==============================
local F = {
    Treadmill = false, Squat = false, Bench = false, Pullup = false,
    Striking = false, TrainAll = false, AntiAFK = false,
}

local function disableAutoMacro()
    pcall(function()
        local data = getReplicaData()
        local gp = data and data.Gamepass
        if gp and type(gp.AutoMacro) == "table" then gp.AutoMacro.Enabled = false end
    end)
end
local function anyTrainingActive()
    local mf = Library.Toggles and Library.Toggles.AsuraAutoMacro
    if mf and mf.Value then return true end
    return (F.Treadmill or F.Squat or F.Bench or F.Pullup or F.TrainAll or F.Striking) and true or false
end
local function syncAutoMacro()
    if anyTrainingActive() then ensureAutoMacro() else disableAutoMacro() end
end

--==============================================================
-- STATION HANDLING
--==============================================================
local STATIONS = {
    Treadmill = { folder = "Treadmills",   statAttr = "Treadmill" },
    Squat     = { folder = "SquatRacks" },
    Bench     = { folder = "BenchPresses" },
    Pullup    = { folder = "Pull-ups" },
}

local function stationPart(model)
    return model.PrimaryPart or model:FindFirstChild("Center") or model:FindFirstChildWhichIsA("BasePart", true)
end

local function stationOccupied(m)
    local o = m:GetAttribute("OccupantUserId")
    o = o and tonumber(o)
    return o ~= nil and o ~= 0 and o ~= LP.UserId
end

local function nearestStationModel(folderName)
    local T = workspace:FindFirstChild("Trainings")
    local f = T and T:FindFirstChild(folderName)
    if not f then return nil end
    local hrp = getHRP()
    local best, bestD
    local fbBest, fbD
    for _, m in ipairs(f:GetChildren()) do
        if m:IsA("Model") then
            local p = stationPart(m)
            if p then
                local d = hrp and (p.Position - hrp.Position).Magnitude or 0
                if not fbD or d < fbD then fbBest, fbD = m, d end
                if not stationOccupied(m) and (not bestD or d < bestD) then best, bestD = m, d end
            end
        end
    end
    return best or fbBest
end

local function trainingShouldPause()
    if G.AsuraEating then return true end
    if G.AsuraEatOn then
        local d = getReplicaData()
        local h = d and tonumber(d.Hunger)
        if h and h <= (tonumber(G.AsuraEatThreshold) or 30) then return true end
    end
    return false
end

local function fireStation(key)
    local conf = STATIONS[key]
    if not conf then return false end
    local t0 = tick()
    while trainingShouldPause() and (tick() - t0) < 60 do task.wait(0.4) end
    ensureAutoMacro()
    local m = nearestStationModel(conf.folder)
    if not m then return false end
    local p = stationPart(m)
    local hrp = getHRP()
    if hrp and p then
        if (hrp.Position - p.Position).Magnitude > 15 then
            pcall(function() hrp.CFrame = CFrame.new(p.Position + Vector3.new(0, 3, 0)) end)
            task.wait(0.25)
        end
    end
    if conf.statAttr then
        local val = (key == "Treadmill") and cfg.Treadmill or "Stamina"
        pcall(function() LP:SetAttribute(conf.statAttr, val) end)
    end
    task.wait(0.35)
    local cd = m:FindFirstChildWhichIsA("ClickDetector", true)
    if cd and fireclickdetector then
        fireclickdetector(cd)
        return true
    end
    return false
end

local function stationLoop(key, flagName)
    task.spawn(function()
        while F[flagName] do
            ensureAutoMacro()
            fireStation(key)
            local waited = 0
            local cw = tonumber(cfg.CycleWait) or 62
            while F[flagName] and waited < cw do
                task.wait(1); waited = waited + 1
            end
        end
    end)
end

------------------------------------------------------------
-- CATEGORIES + TABS
------------------------------------------------------------
local CatTrain   = Window:AddCategory("TRAINING")
local CatPlayer  = Window:AddCategory("PLAYER")
local CatMisc    = Window:AddCategory("MISC")
local CatVisuals = Window:AddCategory("VISUALS")

local StationsTab = CatTrain:AddTab("Stations")
local RoadworkTab = CatTrain:AddTab("Roadwork")
local EatTab      = CatTrain:AddTab("Auto Eat")

local PlayerTab   = CatPlayer:AddTab("Player")
local CombatTab   = CatPlayer:AddTab("Combat")
local StaffTab    = CatPlayer:AddTab("Staff Alert")
local StatsTab    = CatPlayer:AddTab("Stats")

local BankTab     = CatMisc:AddTab("Bank")
local JobTab      = CatMisc:AddTab("Jobs")
local TeleportTab = CatMisc:AddTab("Teleport")

local EspTab      = CatVisuals:AddTab("ESP")
local ChatTab     = CatVisuals:AddTab("Chat Spy")

------------------------------------------------------------
-- TRAINING > STATIONS
------------------------------------------------------------
local MacroBox   = StationsTab:AddGroupbox("Auto Macro")
local StationBox = StationsTab:AddGroupbox("Individual Stations")
local CycleBox   = StationsTab:AddGroupbox("Cycle Config")

MacroBox:AddToggle("AsuraAutoMacro", {
    Text = "Unlock Auto Macro",
    Default = false,
    Description = "Unlocks the game's built-in AutoMacro so training minigames auto-complete",
    Callback = function(v)
        if v then
            task.spawn(function()
                while getgenv().Asura_Loaded and Library.Toggles and Library.Toggles.AsuraAutoMacro and Library.Toggles.AsuraAutoMacro.Value do
                    ensureAutoMacro()
                    task.wait(2)
                end
            end)
            notify("Auto Macro", "Unlocked — trainings will auto-complete", 4)
        else
            syncAutoMacro()
            notify("Auto Macro", "Disabled", 3)
        end
    end,
})

MacroBox:AddDropdown("AsuraTreadStat", {
    Text = "Treadmill Stat",
    Values = {"Stamina", "Speed", "Fat"},
    Default = cfg.Treadmill or "Stamina",
    Callback = function(o) cfg.Treadmill = o; saveCfg() end,
})

StationBox:AddToggle("AsuraTreadmill", {
    Text = "Auto Treadmill",
    Default = false,
    Description = "Auto-runs the treadmill station on a loop",
    Callback = function(v) F.Treadmill = v; syncAutoMacro(); if v then stationLoop("Treadmill", "Treadmill") end end,
})

StationBox:AddToggle("AsuraSquat", {
    Text = "Auto Squat Rack",
    Default = false,
    Description = "Auto-runs the squat rack station on a loop",
    Callback = function(v) F.Squat = v; syncAutoMacro(); if v then stationLoop("Squat", "Squat") end end,
})

StationBox:AddToggle("AsuraBench", {
    Text = "Auto Bench Press",
    Default = false,
    Description = "Auto-runs the bench press station on a loop",
    Callback = function(v) F.Bench = v; syncAutoMacro(); if v then stationLoop("Bench", "Bench") end end,
})

StationBox:AddToggle("AsuraPullup", {
    Text = "Auto Pull-up",
    Default = false,
    Description = "Auto-runs the pull-up station on a loop",
    Callback = function(v) F.Pullup = v; syncAutoMacro(); if v then stationLoop("Pullup", "Pullup") end end,
})

StationBox:AddDivider()

StationBox:AddToggle("AsuraTrainAll", {
    Text = "Auto Train ALL (rotate)",
    Default = false,
    Description = "Rotates through all four stations automatically",
    Callback = function(v)
        F.TrainAll = v
        syncAutoMacro()
        if not v then return end
        task.spawn(function()
            local order = {"Treadmill","Squat","Bench","Pullup"}
            local i = 1
            while F.TrainAll do
                ensureAutoMacro()
                fireStation(order[i])
                i = (i % #order) + 1
                local waited, cw = 0, (tonumber(cfg.CycleWait) or 62)
                while F.TrainAll and waited < cw do task.wait(1); waited = waited + 1 end
            end
        end)
    end,
})

StationBox:AddToggle("AsuraStriking", {
    Text = "Auto Striking (punching bag)",
    Default = false,
    Description = "Auto-punches the nearest punching bag",
    Callback = function(v)
        F.Striking = v
        syncAutoMacro()
        if not v then return end
        task.spawn(function()
            while F.Striking do
                while trainingShouldPause() and F.Striking do task.wait(0.5) end
                local T = workspace:FindFirstChild("Trainings")
                local best, bestD
                if T then
                    local hrp = getHRP()
                    for _, m in ipairs(T:GetChildren()) do
                        if m.Name == "PunchingBag" and m:IsA("Model") and not stationOccupied(m) then
                            local p = stationPart(m)
                            if p and hrp then
                                local d = (p.Position - hrp.Position).Magnitude
                                if not bestD or d < bestD then best, bestD = m, d end
                            end
                        end
                    end
                end
                local hrp = getHRP()
                if best and hrp then
                    local p = stationPart(best)
                    if p and (hrp.Position - p.Position).Magnitude > 12 then
                        pcall(function() hrp.CFrame = CFrame.new(p.Position + (p.CFrame.LookVector * 4), p.Position) end)
                        task.wait(0.2)
                    end
                end
                for _ = 1, 5 do
                    if not F.Striking then break end
                    pcall(function()
                        VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                        VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                    end)
                    task.wait(0.25)
                end
                task.wait(0.1)
            end
        end)
        notify("Striking", "Auto-punching nearest bag", 3)
    end,
})

CycleBox:AddSlider("AsuraCycle", {
    Text = "Cycle Wait (sec)",
    Default = cfg.CycleWait or 62,
    Min = 30, Max = 90, Decimals = 0,
    Callback = function(v) cfg.CycleWait = v; saveCfg() end,
})

CycleBox:AddButton({
    Text = "Train Once (Treadmill)",
    Func = function() ensureAutoMacro(); fireStation("Treadmill"); notify("Train", "Treadmill fired", 2) end,
})

------------------------------------------------------------
-- TRAINING > ROADWORK
------------------------------------------------------------
local RoadworkBox = RoadworkTab:AddGroupbox("Auto Roadwork")

local autoRoadwork = false
local roadworkStat = "Stamina"
local roadworkPace = 0.6
local RW_GYM = Vector3.new(-2061, 9, -1646)

pcall(function()
    ReplicatedStorage.Events.RoadworkGain.OnClientInvoke = function() return roadworkStat end
end)

local function rwTool()
    local char = getChar()
    for _, w in ipairs({ char, LP:FindFirstChild("Backpack") }) do
        if w then for _, c in ipairs(w:GetChildren()) do
            if c:IsA("Tool") and c.Name:find("Roadwork") then return c end
        end end
    end
    return nil
end
local function rwActive()
    local c = getChar(); return c and c:GetAttribute("Training") == "Roadwork"
end

local function rwStart()
    local hrp, char, hum = getHRP(), getChar(), getHum()
    if not hrp or not char then return false end
    local tool = rwTool()
    if not tool then
        pcall(function() hrp.CFrame = CFrame.new(RW_GYM + Vector3.new(0, 3, 0)) end)
        task.wait(0.3)
        local gymP = workspace:FindFirstChild("MapMisc")
        gymP = gymP and gymP:FindFirstChild("Purchases")
        gymP = gymP and gymP:FindFirstChild("GYM")
        if gymP then
            for _, c in ipairs(gymP:GetChildren()) do
                if c.Name == "Roadwork Training" then
                    local pp = (c:IsA("BasePart") and c) or c:FindFirstChildWhichIsA("BasePart", true)
                    if pp and (pp.Position - RW_GYM).Magnitude < 50 then
                        local cd = c:FindFirstChildWhichIsA("ClickDetector", true)
                        if cd and fireclickdetector then fireclickdetector(cd); fireclickdetector(cd, 32) end
                        break
                    end
                end
            end
        end
        task.wait(0.7)
        pcall(function() ReplicatedStorage.Events.InventoryEvent:FireServer({ "Combat","Push Up","Sit Up","Squat","Roadwork Training","","","","" }) end)
        task.wait(0.6)
        tool = rwTool()
    end
    if tool then
        pcall(function() if tool.Parent ~= char and hum then hum:EquipTool(tool) end end)
        task.wait(0.3)
        pcall(function() tool:Activate() end)
        task.wait(1)
    end
    return rwActive()
end

local function rwTouchCP(c)
    local hrp, char = getHRP(), getChar()
    if not hrp then return end
    local target = c.Position + Vector3.new(0, 3, 0)
    local t0 = tick()
    while tick() - t0 < (roadworkPace or 1.5) do
        if not autoRoadwork then return end
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.CFrame = CFrame.new(target)
        end)
        if firetouchinterest then
            for _, pn in ipairs({ "HumanoidRootPart", "Left Leg", "Right Leg", "Torso" }) do
                local bp = char and char:FindFirstChild(pn)
                if bp then pcall(function() firetouchinterest(bp, c, 0); firetouchinterest(bp, c, 1) end) end
            end
        end
        task.wait(0.15)
    end
end

local function rwRunRoute()
    local gym = workspace:FindFirstChild("Roadworks")
    gym = gym and gym:FindFirstChild("GYM")
    if not gym then return end
    local cps = {}
    for _, c in ipairs(gym:GetChildren()) do if c:IsA("BasePart") and tonumber(c.Name) then cps[tonumber(c.Name)] = c end end
    for i = 1, 10 do
        if not autoRoadwork then return end
        local c = cps[i]
        if c then
            rwTouchCP(c)
            local ch = getChar()
            if ch and ch:GetAttribute("Training") ~= "Roadwork" then break end
        end
    end
end

RoadworkBox:AddDropdown("AsuraRWStat", {
    Text = "Roadwork Stat",
    Values = {"Stamina", "Speed"},
    Default = "Stamina",
    Callback = function(o) roadworkStat = o end,
})

RoadworkBox:AddSlider("AsuraRWPace", {
    Text = "Pace (sec/checkpoint)",
    Default = 0.5, Min = 0, Max = 4, Decimals = 1,
    Description = "Higher = safer, lower = faster",
    Callback = function(v) roadworkPace = math.max(v, 0.45) end,
})

RoadworkBox:AddToggle("AsuraRoadwork", {
    Text = "Auto Roadwork",
    Default = false,
    Description = "Trains roadwork by running checkpoint route automatically",
    Callback = function(v)
        autoRoadwork = v
        if not v then return end
        notify("Auto Roadwork", "Training " .. roadworkStat .. "...", 3)
        task.spawn(function()
            while autoRoadwork do
                if trainingShouldPause() then
                    task.wait(0.5)
                else
                    if not rwActive() then rwStart() end
                    if autoRoadwork and not trainingShouldPause() and rwActive() then rwRunRoute() end
                    task.wait(0.5)
                end
            end
        end)
    end,
})

------------------------------------------------------------
-- TRAINING > AUTO EAT
------------------------------------------------------------
local EatBox = EatTab:AddGroupbox("Auto Eat")

local autoEat = false
local eatThreshold = 30
G.AsuraEatThreshold = 30

local function getHunger()
    local d = getReplicaData()
    return d and tonumber(d.Hunger) or 100
end

local FOOD_SHOPS = {
    { name = "Chicken",       shop = "Burger" },
    { name = "Cheeseburger",  shop = "Burger" },
    { name = "Milkshake",     shop = "Burger" },
    { name = "Sushi",         shop = "Sushi" },
    { name = "Ramen",         shop = "Sushi" },
    { name = "Protein Shake", shop = "GYM Rats" },
}

local function purchasesFolder()
    local p = workspace:FindFirstChild("MapMisc"); return p and p:FindFirstChild("Purchases")
end
local function foodNode(foodName, shopName)
    local pur = purchasesFolder(); local shop = pur and pur:FindFirstChild(shopName)
    return shop and shop:FindFirstChild(foodName)
end
local function foodAmount(foodName)
    local d = getReplicaData()
    local it = d and d.Items and d.Items[foodName]
    return it and tonumber(it.Amount) or 0
end
local function totalFood()
    local n = 0
    for _, e in ipairs(FOOD_SHOPS) do n = n + foodAmount(e.name) end
    return n
end
local function findFoodTool(foodName)
    for _, w in ipairs({ getChar(), LP:FindFirstChild("Backpack") }) do
        if w then for _, c in ipairs(w:GetChildren()) do
            if c:IsA("Tool") and c.Name == foodName then return c end
        end end
    end
    return nil
end

local function buyToMax(foodName, shopName)
    local node = foodNode(foodName, shopName)
    local cd = node and node:FindFirstChildWhichIsA("ClickDetector", true)
    if not cd then return end
    local prev, stale = foodAmount(foodName), 0
    for _ = 1, 14 do
        pcall(function() fireclickdetector(cd) end)
        task.wait(1.1)
        local a = foodAmount(foodName)
        if a <= prev then stale = stale + 1 else stale = 0 end
        prev = a
        if stale >= 2 then break end
    end
end

local function stockFood()
    local hrp = getHRP(); if not hrp then return end
    local saved = hrp.CFrame
    for _, e in ipairs(FOOD_SHOPS) do
        local node = foodNode(e.name, e.shop)
        local p = node and ((node:IsA("BasePart") and node) or node:FindFirstChildWhichIsA("BasePart", true))
        if p then
            pcall(function() hrp.CFrame = CFrame.new(p.Position + Vector3.new(0, 3, 0)) end)
            task.wait(0.4)
            buyToMax(e.name, e.shop)
        end
    end
    if getHRP() then pcall(function() getHRP().CFrame = saved end) end
end

local function eatFromInventory(target)
    target = target or 95
    local char, hum = getChar(), getHum()
    for _, e in ipairs(FOOD_SHOPS) do
        local foodName = e.name
        while getHunger() < target and foodAmount(foodName) > 0 do
            local tool = findFoodTool(foodName)
            if not tool then break end
            pcall(function() if tool.Parent ~= char and hum then hum:EquipTool(tool) end end)
            task.wait(0.2)
            pcall(function() tool:Activate() end)
            task.wait(1.3)
            char, hum = getChar(), getHum()
        end
        if getHunger() >= target then break end
    end
end

EatBox:AddSlider("AsuraEatThreshold", {
    Text = "Eat When Hunger Below (%)",
    Default = 30, Min = 5, Max = 90, Decimals = 0,
    Callback = function(v) eatThreshold = v; G.AsuraEatThreshold = v end,
})

EatBox:AddButton({
    Text = "Stock Food (buy max)",
    Func = function()
        task.spawn(function() stockFood(); notify("Auto Eat", "Stocked food to max", 2) end)
    end,
})

EatBox:AddToggle("AsuraAutoEat", {
    Text = "Auto Eat",
    Default = false,
    Description = "Eats from inventory when hunger drops below threshold; restocks when out",
    Callback = function(v)
        autoEat = v
        G.AsuraEatOn = v
        if not v then return end
        notify("Auto Eat", "Eats from inventory at < " .. eatThreshold .. "%; restocks when out", 4)
        task.spawn(function()
            local g = getgenv and getgenv() or _G
            while autoEat do
                if getHunger() < eatThreshold then
                    g.AsuraEating = true
                    local wasTraining = anyTrainingActive()
                    if wasTraining then
                        disableAutoMacro()
                        task.wait(0.5)
                    end
                    eatFromInventory(95)
                    if totalFood() <= 0 and getHunger() < eatThreshold then
                        stockFood()
                        eatFromInventory(95)
                    end
                    g.AsuraEating = false
                    if wasTraining then ensureAutoMacro() end
                end
                task.wait(2)
            end
            (getgenv and getgenv() or _G).AsuraEating = false
        end)
    end,
})

------------------------------------------------------------
-- PLAYER > PLAYER
------------------------------------------------------------
local UtilBox   = PlayerTab:AddGroupbox("Utility")
local SprintBox = PlayerTab:AddGroupbox("Auto Sprint")
local DashBox   = PlayerTab:AddGroupbox("Dash")

UtilBox:AddToggle("AsuraAntiAFK", {
    Text = "Anti-AFK",
    Default = false,
    Description = "Prevents you from being kicked for inactivity",
    Callback = function(v) F.AntiAFK = v; if v then notify("Anti-AFK", "Enabled", 2) end end,
})

UtilBox:AddButton({
    Text = "Reset Character",
    Func = function() local h = getHum(); if h then h.Health = 0 end end,
})

UtilBox:AddButton({
    Text = "Anti-AFK Teleport",
    Func = function() fireEv("AntiAfkTp"); notify("Anti-AFK", "Fired", 2) end,
})

-- Auto Sprint
local autoSprint = false
local sprintHeld = false
local RUN_WS = 45
local sprintTrack
local sprintInfo

do
    local EventCore = ev("EventCore")
    if EventCore then
        EventCore.OnClientEvent:Connect(function(...)
            local t = { ... }
            if t[1] == "pInfo" and type(t[2]) == "table" then sprintInfo = t[2] end
        end)
    end
end
local function runOk()
    local v = sprintInfo
    if not v then return true end
    if (tonumber(v.Stun) or 0) > 0 or (tonumber(v.ActionStun) or 0) > 0 or (tonumber(v.CombatStun) or 0) > 0 then return false end
    if v.Blocking and v.Blocking.Block then return false end
    if (tonumber(v.Paralyze) or 0) > 0 then return false end
    return true
end
local function sprintFOV(fov)
    pcall(function() game:GetService("TweenService"):Create(workspace.CurrentCamera, TweenInfo.new(0.25), { FieldOfView = fov }):Play() end)
end
local function getSprintTrack()
    if sprintTrack then return sprintTrack end
    local hum = getHum()
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return nil end
    local a = Instance.new("Animation"); a.AnimationId = "rbxassetid://13368457704"
    local ok, track = pcall(function() return animator:LoadAnimation(a) end)
    if ok and track then
        track.Priority = Enum.AnimationPriority.Action
        track.Looped = true
        sprintTrack = track
    end
    return sprintTrack
end
LP.CharacterAdded:Connect(function() sprintTrack = nil end)
local function startFakeSprint()
    sprintHeld = true
    sprintFOV(80)
end
local function stopFakeSprint()
    sprintHeld = false
    if sprintTrack then pcall(function() sprintTrack:Stop(0.15) end) end
    local hum = getHum()
    if hum then pcall(function() hum.WalkSpeed = 16 end) end
    sprintFOV(70)
end

RunService.Heartbeat:Connect(function()
    if not (autoSprint and sprintHeld) then return end
    local hum = getHum()
    if not hum then return end
    if runOk() then
        if hum.WalkSpeed ~= RUN_WS then pcall(function() hum.WalkSpeed = RUN_WS end) end
        local t = getSprintTrack()
        if t and not t.IsPlaying then pcall(function() t:Play(0.1) end) end
    else
        if sprintTrack and sprintTrack.IsPlaying then pcall(function() sprintTrack:Stop(0.1) end) end
    end
end)

SprintBox:AddToggle("AsuraAutoSprint", {
    Text = "Auto Sprint (W = run, no stamina)",
    Default = false,
    Description = "Hold W to run at full speed without stamina drain",
    Callback = function(v)
        autoSprint = v
        if v then notify("Auto Sprint", "Hold W to run — no stamina drain", 3)
        else stopFakeSprint() end
    end,
})

UserInputService.InputBegan:Connect(function(input, gpe)
    if not autoSprint or gpe then return end
    if input.KeyCode == Enum.KeyCode.W then
        local hrp = getHRP()
        if hrp and not hrp.Anchored then startFakeSprint() end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if autoSprint and input.KeyCode == Enum.KeyCode.W then stopFakeSprint() end
end)

-- No Dash Stamina Drain
G.AsuraNoDashDrain = false
do
    local FunctionCore = ev("FunctionCore")
    local RunRemote = ev("EventCore")
    if FunctionCore and getnamecallmethod and hookmetamethod and not G.AsuraDashNamecallHooked then
        G.AsuraDashNamecallHooked = true
        local old
        local function hook(self, ...)
            local m = getnamecallmethod()
            if m == "InvokeServer" then
                if G.AsuraNoDashDrain and self == FunctionCore then
                    local a = { ... }
                    if a[1] == "CanDash" then
                        local c = LP.Character
                        return (c and c:GetAttribute("DashDistance")) or 45
                    end
                end
            elseif m == "FireServer" then
                if autoSprint and self == RunRemote then
                    local a = { ... }
                    if a[1] == "Run" and a[2] == "Start" and a[3] == true then return end
                end
            end
            return old(self, ...)
        end
        pcall(function() old = hookmetamethod(game, "__namecall", (newcclosure and newcclosure(hook)) or hook) end)
    end
end

DashBox:AddToggle("AsuraDashNoDrain", {
    Text = "No Dash Stamina Drain",
    Default = false,
    Description = "Dashing no longer drains stamina",
    Callback = function(v)
        G.AsuraNoDashDrain = v
        notify("Dash", v and "Dashing drains no stamina" or "Dash stamina back to normal", 3)
    end,
})

------------------------------------------------------------
-- PLAYER > COMBAT
------------------------------------------------------------
local PerfBlockBox = CombatTab:AddGroupbox("Auto Perfect Block")
local BarrierBox   = CombatTab:AddGroupbox("No Barrier")

local autoPB = false
local PB = { isBlocking = false, blockUntil = 0, lastFresh = 0, lastTrigger = 0 }
local STRIKE_TIME = 0.2
local BlockEvent = ev("EventCore")
local M1_IDS = {
    ["13368463652"] = true, ["13368477320"] = true, ["13368478004"] = true,
    ["13368479173"] = true, ["13368479982"] = true, ["13368480637"] = true,
}
local function isM1(animId)
    local n = tostring(animId):match("%d+")
    return n ~= nil and M1_IDS[n] == true
end
local function combatToolFor()
    for _, w in ipairs({ getChar(), LP:FindFirstChild("Backpack") }) do
        if w then for _, t in ipairs(w:GetChildren()) do
            if t:IsA("Tool") and (t:GetAttribute("CombatTool") or t:GetAttribute("SkillTool") or t.Name == "Combat") then return t end
        end end
    end
end
local function pbSetBlock(on)
    if on == PB.isBlocking or not BlockEvent then return end
    if on then
        local c, hum, tool = getChar(), getHum(), combatToolFor()
        if tool and hum and tool.Parent ~= c then pcall(function() hum:EquipTool(tool) end) end
        pcall(function() BlockEvent:FireServer("Block", true) end)
    else
        pcall(function() BlockEvent:FireServer("Block", false) end)
    end
    PB.isBlocking = on
end
local function pbFresh()
    if not BlockEvent then return end
    local c, hum, tool = getChar(), getHum(), combatToolFor()
    if tool and hum and tool.Parent ~= c then pcall(function() hum:EquipTool(tool) end) end
    pcall(function() BlockEvent:FireServer("Block", false) end)
    pcall(function() BlockEvent:FireServer("Block", true) end)
    PB.isBlocking = true
    PB.lastFresh = tick()
end
local function m1Incoming()
    local myHrp = getHRP(); if not myHrp then return false end
    local myPos = myHrp.Position
    for _, p in ipairs(PLAYERS) do
        if p ~= LP and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 and (hrp.Position - myPos).Magnitude <= 12 then
                local an = hum:FindFirstChildOfClass("Animator")
                if an then
                    for _, tr in ipairs(an:GetPlayingAnimationTracks()) do
                        local anim = tr.Animation
                        if anim and isM1(anim.AnimationId) and tr.TimePosition >= STRIKE_TIME then return true end
                    end
                end
            end
        end
    end
    return false
end

PerfBlockBox:AddToggle("AsuraAutoPB", {
    Text = "Auto Perfect Block",
    Default = false,
    Description = "Frame-perfect block on enemy M1s — no counter",
    Callback = function(v)
        autoPB = v
        if v then
            notify("Auto Perfect Block", "Frame-perfect block on enemy M1s only — no counter", 4)
            G.AsuraPBCount = 0
            task.spawn(function()
                local lastPB = false
                while autoPB and not G.Asura_Unloaded do
                    if m1Incoming() and tick() - PB.lastTrigger > 0.22 then
                        PB.lastTrigger = tick()
                        pbFresh()
                        PB.blockUntil = tick() + 0.2
                    end
                    if PB.isBlocking and tick() > PB.blockUntil then pbSetBlock(false) end
                    local pbf = sprintInfo and sprintInfo.Blocking and sprintInfo.Blocking.PerfectBlock
                    if pbf and not lastPB then G.AsuraPBCount = (G.AsuraPBCount or 0) + 1 end
                    lastPB = pbf
                    task.wait(0.02)
                end
                pbSetBlock(false)
            end)
        else
            pbSetBlock(false)
        end
    end,
})

PerfBlockBox:AddSlider("AsuraPBTiming", {
    Text = "PB Timing (ms)",
    Default = 200, Min = 0, Max = 500, Decimals = 0,
    Description = "Block when enemy M1 animation reaches this position",
    Callback = function(val) STRIKE_TIME = (tonumber(val) or 200) / 1000 end,
})

-- No Barrier (Champions GYM)
local noBarrier = false
local disabledBarriers = {}
local gymAnchor = nil
local gymKickStreak = 0
local _gymRegionCache
local function gymRegion()
    if _gymRegionCache and _gymRegionCache.Parent then return _gymRegionCache end
    local r = workspace:FindFirstChild("Regions")
    _gymRegionCache = r and r:FindFirstChild("Champion's GYM")
    return _gymRegionCache
end
local function inGymBox(pos)
    local gym = gymRegion()
    if not gym then return false end
    local rel = gym.CFrame:PointToObjectSpace(pos)
    local s = gym.Size
    return math.abs(rel.X) <= s.X / 2 + 3 and math.abs(rel.Y) <= s.Y / 2 + 6 and math.abs(rel.Z) <= s.Z / 2 + 3
end
local function forEachGymBarrier(fn)
    local gym, mapF = gymRegion(), workspace:FindFirstChild("Map")
    if not (gym and mapF) then return end
    local s = gym.Size + Vector3.new(50, 40, 50)
    for _, d in ipairs(mapF:GetDescendants()) do
        if d:IsA("BasePart") and d.CanCollide and d.Transparency >= 0.9 and d.Size.Magnitude > 1 then
            local rel = gym.CFrame:PointToObjectSpace(d.Position)
            if math.abs(rel.X) <= s.X / 2 and math.abs(rel.Y) <= s.Y / 2 and math.abs(rel.Z) <= s.Z / 2 then
                if not (d.Size.Y < 2 and d.Size.X > 12 and d.Size.Z > 12) then fn(d) end
            end
        end
    end
end
local function gymKickStep(dt)
    if not noBarrier or G.Asura_Unloaded then return end
    local hrp = getHRP(); if not hrp then return end
    if not gymAnchor then gymAnchor = hrp.CFrame; return end
    if not inGymBox(gymAnchor.Position) then gymAnchor = hrp.CFrame; return end
    local hum = getHum()
    if hum and hum.MoveDirection.Magnitude > 0 then
        gymAnchor = gymAnchor + hum.MoveDirection * (hum.WalkSpeed * dt)
    end
    pcall(function() hrp.CFrame = gymAnchor end)
end

BarrierBox:AddToggle("AsuraNoBarrierGym", {
    Text = "No Barrier (Champions Gym)",
    Default = false,
    Description = "Walk into Champions Gym — auto-undoes the server region kick",
    Callback = function(v)
        noBarrier = v
        pcall(function() RunService:UnbindFromRenderStep("AsuraGymKick") end)
        if v then
            notify("No Barrier", "Champions Gym: walk in — region kick auto-undone", 4)
            task.spawn(function()
                local i = 0
                while noBarrier and not G.Asura_Unloaded do
                    if i % 20 == 0 then forEachGymBarrier(function(p) disabledBarriers[p] = true end) end
                    i = i + 1
                    for p in pairs(disabledBarriers) do
                        if p and p.Parent then if p.CanCollide then pcall(function() p.CanCollide = false end) end else disabledBarriers[p] = nil end
                    end
                    task.wait(0.5)
                end
            end)
            gymAnchor, gymKickStreak = nil, 0
            pcall(function() RunService:BindToRenderStep("AsuraGymKick", Enum.RenderPriority.Camera.Value - 1, gymKickStep) end)
        else
            for p in pairs(disabledBarriers) do if p and p.Parent then pcall(function() p.CanCollide = true end) end end
            disabledBarriers = {}
            notify("No Barrier", "Champions Gym barriers restored", 3)
        end
    end,
})

------------------------------------------------------------
-- PLAYER > STAFF ALERT
------------------------------------------------------------
local StaffBox = StaffTab:AddGroupbox("Staff Detection")

local STAFF_GROUP = game.CreatorId
local STAFF_IDS = {
    [1033637684] = "Head of Staff", [3146736271] = "Head of Staff",
    [1599099191] = "Co-Creator",    [10899664576] = "Co-Creator",
}
local STAFF_ROLES = {
    ["Co-Creators"] = true, ["Studio Developers"] = true, ["Developers+"] = true,
    ["Developers"] = true, ["Head of Staff"] = true, ["Head Admin"] = true,
    ["HeadAdmin"] = true, ["Admin"] = true, ["Moderator"] = true,
    ["Trial Moderator"] = true, ["Trial"] = true,
}
local staffAlertOn = true
local staffCache   = {}
local staffAlerted = {}

local function staffRole(p)
    local cached = staffCache[p.UserId]
    if cached ~= nil then return cached or nil end
    local result
    if STAFF_IDS[p.UserId] then
        result = STAFF_IDS[p.UserId]
    else
        local ok, role = pcall(function() return p:GetRoleInGroup(STAFF_GROUP) end)
        if ok and role and STAFF_ROLES[role] then
            result = role
        else
            local ok2, rank = pcall(function() return p:GetRankInGroup(STAFF_GROUP) end)
            if ok2 and tonumber(rank) and rank >= 250 then result = (ok and role) or ("Rank " .. rank) end
        end
    end
    staffCache[p.UserId] = result or false
    return result
end

local function checkStaff(p)
    if not staffAlertOn or p == LP or staffAlerted[p.UserId] then return end
    local role = staffRole(p)
    if role then
        staffAlerted[p.UserId] = true
        notify("STAFF IN SERVER", ("%s (@%s) — %s"):format(p.DisplayName, p.Name, role), 12)
        warn(("[Asura] STAFF DETECTED: %s (@%s) — %s"):format(p.DisplayName, p.Name, role))
    end
end

local function scanStaff()
    task.spawn(function()
        for _, p in ipairs(Players:GetPlayers()) do checkStaff(p) end
    end)
end

StaffBox:AddToggle("AsuraStaffAlert", {
    Text = "Staff Alert",
    Default = true,
    Description = "Alerts when a staff member is in the server",
    Callback = function(v)
        staffAlertOn = v
        if v then notify("Staff Alert", "Watching for staff...", 3); scanStaff() end
    end,
})

StaffBox:AddButton({
    Text = "Re-scan for Staff",
    Func = function()
        staffCache = {}; staffAlerted = {}; scanStaff(); notify("Staff Alert", "Re-scanned", 2)
    end,
})

Players.PlayerAdded:Connect(function(p) task.wait(1.5); checkStaff(p) end)
Players.PlayerRemoving:Connect(function(p) staffAlerted[p.UserId] = nil; staffCache[p.UserId] = nil end)
task.spawn(function()
    while not G.Asura_Unloaded do
        task.wait(15)
        if staffAlertOn then scanStaff() end
    end
end)
scanStaff()

------------------------------------------------------------
-- PLAYER > STATS
------------------------------------------------------------
local StatsBox = StatsTab:AddGroupbox("My Stats")

local function fmtTime(sec)
    sec = tonumber(sec) or 0
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    return ("%dh %dm"):format(h, m)
end

local function buildStats()
    local d = getReplicaData()
    if not d then return "Stats not loaded yet (rejoin or wait)." end
    local function g(k, default) local v = d[k]; if v == nil then return default or 0 end return v end
    local lines = {
        "-- Currency --",
        ("Cash: %s     Bank: %s"):format(tostring(g("Cash")), tostring(g("Bank"))),
        ("Asura Coins: %s     Vouchers: %s"):format(tostring(g("AsuraCoins")), tostring(g("Vouchers"))),
        "",
        "-- Power & Style --",
        ("Total Power: %s"):format(tostring(g("TotalPower"))),
        ("Style: %s     Style EXP: %s"):format(tostring(g("Style","-")), tostring(g("StyleEXP"))),
        ("Brawl EXP: %s"):format(tostring(g("BrawlEXP"))),
        "",
        "-- Body --",
        ("Upper Muscle: %s     Lower Muscle: %s"):format(tostring(g("UpperMuscle")), tostring(g("LowerMuscle"))),
        ("Fat: %s     Protein: %s     Hunger: %.0f"):format(tostring(g("Fat")), tostring(g("Protein")), tonumber(g("Hunger")) or 0),
        "",
        "-- Progress --",
        ("Trial: %s     Highest Stage: %s"):format(tostring(g("CurrentTrial")), tostring(g("HighestStage"))),
        ("Grips: %s     Skills: %s     Passives: %s"):format(tostring(g("Grips")), tostring(g("SkillsLearned")), tostring(g("PassivesLearned"))),
        "",
        "-- Ranked --",
        ("Ranked Points: %s     ELO: %s"):format(tostring(g("RankedPoints")), tostring(g("ELO"))),
        ("Wins: %s     Losses: %s"):format(tostring(g("RankedWins")), tostring(g("RankedLosses"))),
        "",
        "-- Misc --",
        ("Playtime: %s     Jobs: %s     Trades: %s"):format(fmtTime(g("Playtime")), tostring(g("TotalCompletedJobs")), tostring(g("TotalTrades"))),
    }
    local sc = LP.PlayerGui:FindFirstChild("StatCheck")
    local sf = sc and sc:FindFirstChild("Frame")
    local statsF = sf and sf:FindFirstChild("StatsFrame")
    statsF = statsF and statsF:FindFirstChild("Stats")
    if statsF then
        lines[#lines+1] = ""
        lines[#lines+1] = "-- Trained Stats --"
        for _, sn in ipairs({ "Strength", "Stamina", "Speed", "Durability", "StrikingSpeed" }) do
            local f = statsF:FindFirstChild(sn)
            if f then
                local val = f:FindFirstChild("Value")
                local mult = f:FindFirstChild("Multiplier")
                local disp = (sn == "StrikingSpeed") and "Striking Speed" or sn
                lines[#lines+1] = ("%s: %s %s"):format(disp,
                    val and tostring(val.Text) or "?",
                    mult and ("(" .. tostring(mult.Text) .. ")") or "")
            end
        end
    end
    local ch = getChar()
    if ch and ch:GetAttribute("Training") then
        lines[#lines+1] = ("Currently Training: %s"):format(tostring(ch:GetAttribute("Training")))
    end
    return table.concat(lines, "\n")
end

local function refreshStats()
    return buildStats()
end

StatsBox:AddButton({
    Text = "Refresh Stats (console)",
    Func = function()
        local t = refreshStats()
        print("===== ASURA STATS =====\n" .. t)
        notify("Stats", "Printed to console (F9)", 3)
    end,
})

StatsBox:AddButton({
    Text = "Copy Stats to Clipboard",
    Func = function()
        local t = buildStats()
        if setclipboard then setclipboard(t); notify("Stats", "Copied to clipboard", 3) else notify("Stats", "No clipboard fn", 3) end
    end,
})

StatsBox:AddDivider()

-- Custom Stat Check
do
    local g = getgenv and getgenv() or _G
    if not g.AsuraStatHook then
        g.AsuraStatHook = true
        g.AsuraStatCache = g.AsuraStatCache or {}
        pcall(function()
            ReplicatedStorage.Events.StatCheck.OnClientEvent:Connect(function(p1, p2)
                if type(p1) == "table" then
                    g.AsuraStatCache.stats = p1
                    g.AsuraStatCache.mult = p2
                end
            end)
        end)
    end
end

local function openStatCheck()
    local d = getReplicaData()
    local scGui = LP.PlayerGui:FindFirstChild("StatCheck")
    if not scGui or not d then notify("Stat Check", "UI not found", 3); return end
    local frame = scGui:FindFirstChild("Frame")
    local statsF = frame and frame:FindFirstChild("StatsFrame")
    statsF = statsF and statsF:FindFirstChild("Stats")
    local stats2 = frame and frame:FindFirstChild("Stats")
    local g = getgenv and getgenv() or _G
    local cache = g.AsuraStatCache or {}

    if cache.stats and statsF then
        for _, n in ipairs({ "Strength", "Stamina", "Speed", "Durability", "StrikingSpeed" }) do
            local f = statsF:FindFirstChild(n)
            if f then
                local cv = cache.stats[n]
                if f:FindFirstChild("Value") and cv and cv.Value then f.Value.Text = ("%.3f"):format(cv.Value) end
                if f:FindFirstChild("Multiplier") and cache.mult and cache.mult[n] then f.Multiplier.Text = ("x%.3f"):format(cache.mult[n]) end
            end
        end
    end
    local function setLbl(name, txt) local l = stats2 and stats2:FindFirstChild(name); if l then l.Text = txt end end
    setLbl("LabelUpperMuscle", ("Upper Muscle: %.3f KG"):format(tonumber(d.UpperMuscle) or 0))
    setLbl("LabelLowerMuscle", ("Lower Muscle: %.3f KG"):format(tonumber(d.LowerMuscle) or 0))
    setLbl("LabelFat", ("Fat: %.3f KG"):format(tonumber(d.Fat) or 0))
    setLbl("LabelEmployeeLevel", "Employee Level: " .. tostring(d.EmployeeLevel or 1))
    setLbl("LabelPlaytime", ("Playtime: %.2f Hours"):format((tonumber(d.Playtime) or 0) / 3600))
    setLbl("LabelGrips", "Grips: " .. tostring(d.Grips or 0))
    local nameLbl = stats2 and stats2:FindFirstChild("LabelName")
    if nameLbl then nameLbl.Text = (d.PlayerName and d.PlayerName.Name or LP.Name) .. " " .. (d.PlayerName and d.PlayerName.Clan or "") end
    local tp = frame and frame:FindFirstChild("TotalPowerNumber")
    if tp then tp.Text = "(" .. ("%.3f"):format((tonumber(d.TotalPower) or 0) + (tonumber(d.UpperMuscle) or 0)/2 + (tonumber(d.LowerMuscle) or 0)/2 + (tonumber(d.Fat) or 0)*2) .. ")" end

    scGui.Enabled = true
end

StatsBox:AddButton({
    Text = "Open Stat Check (free)",
    Func = function() openStatCheck(); notify("Stat Check", "Opened (free)", 2) end,
})

local statLive = false
StatsBox:AddToggle("AsuraStatLive", {
    Text = "Auto-refresh (live)",
    Default = false,
    Callback = function(v)
        statLive = v
        if v then
            task.spawn(function()
                while statLive do
                    refreshStats()
                    task.wait(1)
                end
            end)
        end
    end,
})

------------------------------------------------------------
-- MISC > BANK
------------------------------------------------------------
local BankBox = BankTab:AddGroupbox("Bank")

local BankRemote = ev("Bank")
local autoDeposit, autoWithdraw = false, false
local function curCash() local d = getReplicaData(); return math.floor(tonumber(d and d.Cash) or 0) end
local function curBank() local d = getReplicaData(); return math.floor(tonumber(d and d.Bank) or 0) end

local function bankPos()
    return Vector3.new(-1777.375, 4.3, -1445.82)
end
local function bankAction(action, amount)
    amount = math.floor(tonumber(amount) or 0)
    if not BankRemote or amount <= 0 then return false end
    local hrp = getHRP(); if not hrp then return false end
    local saved = hrp.CFrame
    pcall(function() hrp.CFrame = CFrame.new(bankPos() + Vector3.new(0, 4, 0)) end)
    task.wait(0.45)
    pcall(function() BankRemote:FireServer(action, tostring(amount)) end)
    task.wait(0.2)
    pcall(function() local h = getHRP(); if h then h.CFrame = saved end end)
    return true
end

BankBox:AddSlider("AsuraDepositAmt", {
    Text = "Deposit Amount (0 = all)",
    Default = cfg.DepositAmount or 0,
    Min = 0, Max = 1000000, Decimals = 0,
    Description = "Set to 0 to deposit all cash",
    Callback = function(v) cfg.DepositAmount = v; saveCfg() end,
})

BankBox:AddSlider("AsuraWithdrawAmt", {
    Text = "Withdraw Amount",
    Default = cfg.WithdrawAmount or 0,
    Min = 0, Max = 1000000, Decimals = 0,
    Callback = function(v) cfg.WithdrawAmount = v; saveCfg() end,
})

BankBox:AddToggle("AsuraAutoDeposit", {
    Text = "Auto Deposit",
    Default = false,
    Description = "Automatically deposits cash to bank on a loop",
    Callback = function(v)
        autoDeposit = v
        if not v then return end
        autoWithdraw = false
        pcall(function() Library.Toggles.AsuraAutoWithdraw:SetValue(false) end)
        notify("Bank", (cfg.DepositAmount > 0) and ("Auto-depositing in $" .. cfg.DepositAmount .. " chunks") or "Auto-depositing ALL cash", 3)
        task.spawn(function()
            while autoDeposit and not G.Asura_Unloaded do
                local c = curCash()
                local amt
                if cfg.DepositAmount > 0 then
                    if c >= cfg.DepositAmount then amt = cfg.DepositAmount end
                elseif c >= 1 then amt = c end
                if amt then bankAction("Deposit", amt) end
                task.wait(5)
            end
        end)
    end,
})

BankBox:AddToggle("AsuraAutoWithdraw", {
    Text = "Auto Withdraw",
    Default = false,
    Description = "Automatically withdraws from bank on a loop",
    Callback = function(v)
        autoWithdraw = v
        if not v then return end
        autoDeposit = false
        pcall(function() Library.Toggles.AsuraAutoDeposit:SetValue(false) end)
        if (cfg.WithdrawAmount or 0) <= 0 then notify("Bank", "Set a withdraw amount first", 3); return end
        notify("Bank", "Auto-withdrawing $" .. cfg.WithdrawAmount .. " each cycle", 3)
        task.spawn(function()
            while autoWithdraw and not G.Asura_Unloaded do
                local amt = math.min(cfg.WithdrawAmount or 0, curBank())
                if amt >= 1 then bankAction("Withdraw", amt) end
                task.wait(5)
            end
        end)
    end,
})

BankBox:AddButton({
    Text = "Deposit All Now",
    Func = function()
        local c = curCash()
        if c >= 1 then bankAction("Deposit", c); notify("Bank", "Deposited $" .. c, 2) else notify("Bank", "No cash to deposit", 2) end
    end,
})

BankBox:AddButton({
    Text = "Withdraw Now",
    Func = function()
        local amt = math.min(cfg.WithdrawAmount or 0, curBank())
        if amt >= 1 then bankAction("Withdraw", amt); notify("Bank", "Withdrew $" .. amt, 2) else notify("Bank", "Set amount / bank empty", 2) end
    end,
})

------------------------------------------------------------
-- MISC > JOBS
------------------------------------------------------------
local JobBox  = JobTab:AddGroupbox("Auto Job Farm")
local CodeBox = JobTab:AddGroupbox("Codes")
local HopBox  = JobTab:AddGroupbox("Server")

local EventCoreR = ev("EventCore")
local autoJob = false

local function replCash() local d = getReplicaData(); return d and tonumber(d.Cash) or 0 end
local function hasCrate() local c = getChar(); return c and c:FindFirstChild("Crate") ~= nil end
local function isDeliveryJob()
    local j = LP:GetAttribute("JobDescription")
    return j and tostring(j):lower():find("deliver") ~= nil
end

local function markerTarget()
    local jobs = workspace:FindFirstChild("MapMisc"); jobs = jobs and jobs:FindFirstChild("Jobs")
    if not jobs then return nil end
    for _, c in ipairs(LP.PlayerGui:GetDescendants()) do
        if c:IsA("BillboardGui") and c.Enabled and c.Adornee and c.Adornee:IsDescendantOf(jobs) then
            return c.Adornee
        end
    end
    return nil
end

local function visitMarker(part, checkFn, timeout)
    local hrp = getHRP()
    if not hrp or not part then return false end
    local base = part.Position
    pcall(function() hrp.CFrame = CFrame.new(base + Vector3.new(0, 6, 0)) end)
    local t0 = tick()
    while tick() - t0 < (timeout or 6) do
        if not autoJob then return false end
        pcall(function()
            local p = hrp.Position
            if math.abs(p.X - base.X) > 4 or math.abs(p.Z - base.Z) > 4 then
                hrp.CFrame = CFrame.new(base + Vector3.new(0, 6, 0))
            end
        end)
        if checkFn() then return true end
        task.wait(0.15)
    end
    return false
end

local function runAutoJob()
    task.spawn(function()
        while autoJob do
            local hrp = getHRP()
            if not hrp then
                task.wait(1)
            elseif not isDeliveryJob() then
                if LP:GetAttribute("JobDescription") then EventCoreR:FireServer("CancelJob"); task.wait(0.4) end
                EventCoreR:FireServer("Job"); task.wait(0.7)
            else
                local cashBefore = replCash()
                local target
                for _ = 1, 20 do
                    target = markerTarget()
                    if target or not autoJob then break end
                    task.wait(0.2)
                end
                if target and not hasCrate() then
                    local pickupPos = target.Position
                    visitMarker(target, hasCrate, 6)
                    if hasCrate() then
                        task.wait(0.4)
                        local dest
                        for _ = 1, 20 do dest = markerTarget(); if dest or not autoJob then break end task.wait(0.2) end
                        if dest then
                            local dist = (pickupPos - dest.Position).Magnitude
                            local travel = math.clamp(dist / 30 + 1.5, 3, 22)
                            local t0 = tick()
                            while tick() - t0 < travel do
                                if not autoJob then break end
                                task.wait(0.3)
                            end
                            if autoJob then
                                visitMarker(dest, function() return replCash() > cashBefore end, 6)
                            end
                        end
                    end
                elseif target and hasCrate() then
                    local t0 = tick()
                    while tick() - t0 < 12 do if not autoJob then break end task.wait(0.3) end
                    if autoJob then visitMarker(target, function() return replCash() > cashBefore end, 6) end
                else
                    task.wait(0.5)
                end
                if replCash() > cashBefore then
                    notify("Auto Job", "Delivered +$" .. (replCash() - cashBefore), 2)
                end
                task.wait(0.3)
            end
        end
    end)
end

JobBox:AddToggle("AsuraAutoJob", {
    Text = "Auto Deliver Crate",
    Default = false,
    Description = "Rerolls until crate delivery, then auto-completes the route",
    Callback = function(v)
        autoJob = v
        if v then
            if not EventCoreR then notify("Auto Job", "EventCore not found", 3); return end
            runAutoJob()
            notify("Auto Job", "Farming crate deliveries...", 3)
        else
            local hrp = getHRP()
            if hrp then pcall(function() hrp.Anchored = false end) end
        end
    end,
})

-- Codes
CodeBox:AddButton({
    Text = "Redeem Code (from clipboard)",
    Func = function()
        local code
        pcall(function() code = getclipboard and getclipboard() end)
        if code and #code > 0 then
            local ok, res = fireEv("Codes", code)
            notify("Codes", "Redeemed: " .. code .. (res and (" -> " .. tostring(res)) or ""), 4)
        else
            notify("Codes", "Copy a code to clipboard first", 3)
        end
    end,
})

-- Server Hop
local ASURA_LOADER_PATH = "C:\\Users\\Samir\\Downloads\\script\\asura.lua"
local function queueReload()
    local fn = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if not fn then return false end
    local code = "task.wait(3) pcall(function() local f=[[" .. ASURA_LOADER_PATH .. "]] if isfile and isfile(f) then loadstring(readfile(f))() end end)"
    local ok = pcall(fn, code)
    return ok
end

local function hopEmptyMyRegion(strictEmpty)
    notify("Server Hop", "Finding an empty server in your region...", 3)
    local placeId = game.PlaceId
    local servers = {}
    local cursor
    for page = 1, 6 do
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
        if cursor then url = url .. "&cursor=" .. cursor end
        local ok, raw = pcall(function() return game:HttpGetAsync(url) end)
        if not ok then break end
        local data
        local ok2 = pcall(function() data = HttpService:JSONDecode(raw) end)
        if not ok2 or type(data) ~= "table" or not data.data then break end
        for _, s in ipairs(data.data) do
            if s.id and s.id ~= game.JobId and s.playing and s.maxPlayers
               and s.playing < s.maxPlayers and s.ping then
                servers[#servers+1] = s
            end
        end
        if data.nextPageCursor and data.nextPageCursor ~= "" then cursor = data.nextPageCursor else break end
    end
    if #servers == 0 then notify("Server Hop", "No joinable servers found.", 4); return end

    local minPing = math.huge
    for _, s in ipairs(servers) do if s.ping < minPing then minPing = s.ping end end
    local band = math.max(40, minPing * 0.6)
    local cands = {}
    for _, s in ipairs(servers) do
        if s.ping <= minPing + band then
            if (not strictEmpty) or s.playing == 0 then cands[#cands+1] = s end
        end
    end
    if #cands == 0 then
        for _, s in ipairs(servers) do if s.ping <= minPing + band then cands[#cands+1] = s end end
    end
    table.sort(cands, function(a, b)
        if a.playing ~= b.playing then return a.playing < b.playing end
        return a.ping < b.ping
    end)
    local chosen = cands[1]
    if not chosen then notify("Server Hop", "No region match found.", 4); return end

    queueReload()
    notify("Server Hop", ("Hopping -> %d players, %dms ping"):format(chosen.playing, math.floor(chosen.ping)), 4)
    task.wait(0.3)
    local ok = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen.id, LP) end)
    if not ok then pcall(function() TeleportService:Teleport(game.PlaceId, LP) end) end
end

HopBox:AddButton({
    Text = "Hop to Empty Server",
    Func = function() task.spawn(function() hopEmptyMyRegion(false) end) end,
})

HopBox:AddButton({
    Text = "Server Hop (any)",
    Func = function()
        local placeId = game.PlaceId
        local ok, res = pcall(function() return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(placeId) .. "/servers/Public?sortOrder=Asc&limit=100")) end)
        if ok and res then for _, s in ipairs(res.data or {}) do if s.id ~= game.JobId and s.playing < s.maxPlayers then pcall(function() TeleportService:TeleportToPlaceInstance(placeId, s.id, LP) end); return end end end
    end,
})

HopBox:AddButton({
    Text = "Rejoin",
    Func = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP) end,
})

------------------------------------------------------------
-- MISC > TELEPORT
------------------------------------------------------------
local TpBox   = TeleportTab:AddGroupbox("Quick Teleport")
local SaveBox = TeleportTab:AddGroupbox("Saved Positions")

local TP_PLACES = {
    { "7th Collections (Clothing)", "7th Collections" },
    { "2016 Cuts (Barber)", "2016 Cuts" },
    { "GYM", "GYM" },
    { "Burger", "Burger" },
    { "Sushi", "Sushi" },
    { "Bank", "Bank" },
    { "Stat Check", "Stat Check" },
    { "Spawn", "Spawn" },
}
local function tpToNamed(name)
    local hrp = getHRP(); if not hrp then return false end
    for _, folderName in ipairs({ "Locations", "Regions" }) do
        local f = workspace:FindFirstChild(folderName)
        local c = f and f:FindFirstChild(name)
        local p = c and ((c:IsA("BasePart") and c) or c:FindFirstChildWhichIsA("BasePart", true))
        if p then
            pcall(function() hrp.CFrame = CFrame.new(p.Position + Vector3.new(0, 3, 0)) end)
            return true
        end
    end
    return false
end

for _, place in ipairs(TP_PLACES) do
    TpBox:AddButton({
        Text = "TP: " .. place[1],
        Func = function()
            if tpToNamed(place[2]) then notify("TP", place[1], 2) else notify("TP", "Not found: " .. place[2], 3) end
        end,
    })
end

local _saveSlot = 1
SaveBox:AddSlider("AsuraSaveSlot", {
    Text = "Save Slot",
    Default = 1, Min = 1, Max = 5, Decimals = 0,
    Callback = function(v) _saveSlot = v end,
})

SaveBox:AddButton({
    Text = "Save Current Position",
    Func = function()
        local hrp = getHRP(); if not hrp then return end
        local p = hrp.Position
        local n = "slot" .. _saveSlot
        cfg.SavedPos[n] = {p.X, p.Y, p.Z}; saveCfg()
        notify("Saved", "Slot " .. _saveSlot, 2)
    end,
})

SaveBox:AddButton({
    Text = "TP to Saved Position",
    Func = function()
        local n = "slot" .. _saveSlot
        local hrp = getHRP(); local v = cfg.SavedPos[n]
        if hrp and v then hrp.CFrame = CFrame.new(v[1], v[2]+3, v[3]); notify("TP", "Slot " .. _saveSlot, 2)
        else notify("TP", "Slot " .. _saveSlot .. " empty", 2) end
    end,
})

------------------------------------------------------------
-- VISUALS > ESP
------------------------------------------------------------
local EspBox = EspTab:AddGroupbox("ESP")

local ESP = {
    playerOn = false,
    placeOn  = false,
    maxDist  = 2000,
    players  = {},
    places   = {},
}

local ESP_FOLDER = Instance.new("Folder")
ESP_FOLDER.Name = "Asura_ESP"
pcall(function() ESP_FOLDER.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)

local function fmtPower(n)
    if n >= 1e6 then return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
    else return tostring(math.floor(n)) end
end

local function makeBB(adornee, color, w, h)
    local bb = Instance.new("BillboardGui")
    bb.Name = "AsuraESP"
    bb.Adornee = adornee
    bb.Size = UDim2.fromOffset(w or 150, h or 30)
    bb.StudsOffset = Vector3.new(0, 2.9, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = ESP.maxDist
    bb.LightInfluence = 0
    bb.Parent = ESP_FOLDER
    local tl = Instance.new("TextLabel")
    tl.Name = "L"
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.fromScale(1, 1)
    tl.Font = Enum.Font.GothamSemibold
    tl.TextSize = 12
    tl.TextColor3 = color or Color3.fromRGB(255,255,255)
    tl.TextStrokeTransparency = 0.35
    tl.TextStrokeColor3 = Color3.new(0,0,0)
    tl.RichText = true
    tl.Parent = bb
    return bb, tl
end

local function ensurePlayerESP(p)
    local c = p.Character
    local head = c and (c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart"))
    if not head then return nil end
    local e = ESP.players[p]
    if not e then
        local bb, tl = makeBB(head, Color3.fromRGB(125,200,255), 178, 46)
        e = { bb = bb, tl = tl, char = c }
        ESP.players[p] = e
    elseif e.bb.Adornee ~= head then
        e.bb.Adornee = head
        e.char = c
    end
    if c and (not e.hl or e.hl.Parent ~= c) then
        if e.hl then pcall(function() e.hl:Destroy() end) end
        local hl = Instance.new("Highlight")
        hl.Name = "AsuraChams"
        hl.Adornee = c
        hl.FillColor = Color3.fromRGB(0, 120, 255)
        hl.FillTransparency = 0.5
        hl.OutlineColor = Color3.fromRGB(120, 210, 255)
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = ESP_FOLDER
        e.hl = hl
    end
    return e
end

local function buildPlaces()
    for _, folderName in ipairs({"Locations", "Regions"}) do
        local f = workspace:FindFirstChild(folderName)
        if f then
            for _, c in ipairs(f:GetChildren()) do
                local part = (c:IsA("BasePart") and c)
                    or (c:IsA("Model") and (c.PrimaryPart or c:FindFirstChildWhichIsA("BasePart", true)))
                if part and not ESP.places[part] and c.Name:lower() ~= "default" then
                    local nm = c.Name
                    if #nm > 22 then nm = nm:sub(1, 22) end
                    local bb, tl = makeBB(part, Color3.fromRGB(255,210,90))
                    ESP.places[part] = { bb = bb, tl = tl, name = nm }
                end
            end
        end
    end
end

local function clearESP()
    for p, e in pairs(ESP.players) do
        pcall(function() e.bb:Destroy() end)
        if e.hl then pcall(function() e.hl:Destroy() end) end
        ESP.players[p] = nil
    end
    for k, e in pairs(ESP.places) do pcall(function() e.bb:Destroy() end); ESP.places[k] = nil end
end

EspBox:AddToggle("AsuraPlayerESP", {
    Text = "Player ESP",
    Default = false,
    Description = "Shows player name, clan, HP, distance, and held item through walls",
    Callback = function(v) ESP.playerOn = v end,
})

EspBox:AddToggle("AsuraPlaceESP", {
    Text = "Market / Place ESP",
    Default = false,
    Description = "Shows locations and markets through walls",
    Callback = function(v) ESP.placeOn = v; if v then buildPlaces() end end,
})

EspBox:AddSlider("AsuraEspDist", {
    Text = "ESP Max Distance",
    Default = 2000, Min = 200, Max = 10000, Decimals = 0,
    Callback = function(v)
        ESP.maxDist = v
        for _, e in pairs(ESP.players) do e.bb.MaxDistance = v end
        for _, e in pairs(ESP.places) do e.bb.MaxDistance = v end
    end,
})

EspBox:AddButton({
    Text = "Clear ESP",
    Func = function() clearESP(); notify("ESP", "Cleared", 2) end,
})

-- ESP render loop
do
    local acc = 0
    local hiddenWhenOff = false
    RunService.Heartbeat:Connect(function(dt)
        if G.Asura_Unloaded then return end
        if not (ESP.playerOn or ESP.placeOn) then
            if not hiddenWhenOff then
                for _, e in pairs(ESP.players) do e.bb.Enabled = false; if e.hl then e.hl.Enabled = false end end
                for _, e in pairs(ESP.places) do e.bb.Enabled = false end
                hiddenWhenOff = true
            end
            return
        end
        hiddenWhenOff = false

        acc = acc + dt
        if acc < 0.05 then return end
        acc = 0

        local myHrp = getHRP()
        local myPos = myHrp and myHrp.Position
        if not myPos then return end
        local maxD = ESP.maxDist

        if ESP.playerOn then
            for _, p in ipairs(PLAYERS) do
                if p ~= LP then
                    local e = ensurePlayerESP(p)
                    local ad = e and e.bb.Adornee
                    if ad then
                        local dist = (ad.Position - myPos).Magnitude
                        local show = dist <= maxD
                        e.bb.Enabled = show
                        if e.hl then e.hl.Enabled = show end
                        if show then
                            local hum = e.hum
                            if not hum or hum.Parent ~= e.char then
                                hum = e.char and e.char:FindFirstChildOfClass("Humanoid"); e.hum = hum
                            end
                            local clan = p:GetAttribute("Clan"); if clan == nil or clan == "" then clan = "-" end
                            local tp = (tonumber(p:GetAttribute("TP")) or 0) * 10
                            local hpPct = (hum and hum.MaxHealth > 0) and math.floor(hum.Health / hum.MaxHealth * 100 + 0.5) or 0
                            local txt = string.format(
                                "<b>%s</b> <font color='#9fdcff'>[%s]</font>\n<font color='#8dff8d'>%d%%</font> | %dm\n<font color='#ffcf4d'>%s TP</font>",
                                p.DisplayName or p.Name, tostring(clan),
                                hpPct, math.floor(dist), fmtPower(tp))
                            local held = e.char and e.char:FindFirstChildOfClass("Tool")
                            if held then
                                txt = txt .. string.format("\n<font color='#ff9d5c'>%s</font>", held.Name)
                            end
                            e.tl.Text = txt
                            local wantH = held and 60 or 46
                            if e.bb.Size.Y.Offset ~= wantH then e.bb.Size = UDim2.fromOffset(178, wantH) end
                        end
                    end
                end
            end
        elseif next(ESP.players) then
            for _, e in pairs(ESP.players) do e.bb.Enabled = false; if e.hl then e.hl.Enabled = false end end
        end

        if ESP.placeOn then
            for part, e in pairs(ESP.places) do
                if part.Parent then
                    local dist = (part.Position - myPos).Magnitude
                    local show = dist <= maxD
                    e.bb.Enabled = show
                    if show then e.tl.Text = string.format("<font color='#ffd25a'>%s</font>\n%dm", e.name, math.floor(dist)) end
                else
                    pcall(function() e.bb:Destroy() end)
                    ESP.places[part] = nil
                end
            end
        elseif next(ESP.places) then
            for _, e in pairs(ESP.places) do e.bb.Enabled = false end
        end
    end)
end

Players.PlayerRemoving:Connect(function(p)
    local e = ESP.players[p]
    if e then
        pcall(function() e.bb:Destroy() end)
        if e.hl then pcall(function() e.hl:Destroy() end) end
        ESP.players[p] = nil
    end
end)

------------------------------------------------------------
-- VISUALS > CHAT SPY
------------------------------------------------------------
local ChatBox = ChatTab:AddGroupbox("Chat Spy")

local chatSpyOn = false
local chatGui, chatScroll
local chatMsgs = {}
local chatOrder = 0
local chatConnected = false

local CHAT_COLORS = {
    Color3.fromRGB(253, 41, 67), Color3.fromRGB(1, 162, 255), Color3.fromRGB(2, 184, 87),
    Color3.fromRGB(107, 50, 124), Color3.fromRGB(218, 133, 65), Color3.fromRGB(245, 205, 48),
    Color3.fromRGB(232, 186, 200), Color3.fromRGB(215, 197, 154), Color3.fromRGB(102, 124, 0),
    Color3.fromRGB(255, 152, 220), Color3.fromRGB(124, 92, 70), Color3.fromRGB(58, 125, 21),
}
local function nameColor(name)
    local value = 0
    for i = 1, #name do value = (value + string.byte(name, i) * i) % 2147483647 end
    return CHAT_COLORS[(value % #CHAT_COLORS) + 1]
end

local function makeChatGui()
    if chatGui then return end
    chatGui = Instance.new("ScreenGui")
    chatGui.Name = "AsuraChatSpy"
    chatGui.ResetOnSpawn = false
    chatGui.DisplayOrder = 50
    chatGui.IgnoreGuiInset = false
    pcall(function() chatGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)

    local frame = Instance.new("Frame")
    frame.Name = "ChatFrame"
    frame.Size = UDim2.fromOffset(430, 200)
    frame.Position = UDim2.fromOffset(16, 16)
    frame.BackgroundColor3 = Color3.fromRGB(25, 27, 33)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = chatGui
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 0, 22)
    title.Position = UDim2.fromOffset(10, 4)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(235, 235, 235)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Chat"
    title.Parent = frame

    chatScroll = Instance.new("ScrollingFrame")
    chatScroll.Size = UDim2.new(1, -12, 1, -34)
    chatScroll.Position = UDim2.fromOffset(6, 30)
    chatScroll.BackgroundTransparency = 1
    chatScroll.BorderSizePixel = 0
    chatScroll.ScrollBarThickness = 4
    chatScroll.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120)
    chatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    chatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    chatScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    chatScroll.Parent = frame
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 3)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = chatScroll
    local pad = Instance.new("UIPadding"); pad.PaddingRight = UDim.new(0, 4); pad.Parent = chatScroll
end

local function addChat(playerName, text)
    if not (chatSpyOn and chatScroll) then return end
    local col = nameColor(playerName)
    local hex = string.format("%02X%02X%02X", math.floor(col.R * 255), math.floor(col.G * 255), math.floor(col.B * 255))
    local safe = tostring(text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    chatOrder = chatOrder + 1
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -4, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Top
    lbl.TextWrapped = true
    lbl.RichText = true
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextStrokeTransparency = 0.6
    lbl.LayoutOrder = chatOrder
    lbl.Text = string.format("<font color=\"#%s\">[%s]:</font> %s", hex, playerName, safe)
    lbl.Parent = chatScroll
    chatMsgs[#chatMsgs + 1] = lbl
    if #chatMsgs > 60 then
        local oldest = table.remove(chatMsgs, 1)
        pcall(function() oldest:Destroy() end)
    end
    task.defer(function()
        if chatScroll then chatScroll.CanvasPosition = Vector2.new(0, chatScroll.AbsoluteCanvasSize.Y) end
    end)
end

local function connectChat()
    if chatConnected then return end
    chatConnected = true
    local function hook(p)
        pcall(function()
            p.Chatted:Connect(function(msg) addChat(p.Name, msg) end)
        end)
    end
    for _, p in ipairs(Players:GetPlayers()) do hook(p) end
    Players.PlayerAdded:Connect(hook)
end

ChatBox:AddToggle("AsuraChatSpy", {
    Text = "Chat Spy",
    Default = false,
    Description = "Shows everyone's chat messages in an overlay window",
    Callback = function(v)
        chatSpyOn = v
        if v then
            makeChatGui()
            connectChat()
            if chatGui then chatGui.Enabled = true end
            addChat("System", "Chat Spy enabled - showing all chat.")
        else
            if chatGui then chatGui.Enabled = false end
        end
    end,
})

ChatBox:AddButton({
    Text = "Clear Chat",
    Func = function()
        for _, l in ipairs(chatMsgs) do pcall(function() l:Destroy() end) end
        chatMsgs = {}
    end,
})

------------------------------------------------------------
-- SPECTATE (runtime integration — clicks leaderboard names)
------------------------------------------------------------
do
    local Camera = workspace.CurrentCamera
    local spectating = nil
    local specConn = nil
    local entryLabels = {}
    local RED = Color3.fromRGB(255, 45, 45)

    local function localHum()
        local c = LP.Character
        return c and c:FindFirstChildOfClass("Humanoid")
    end

    local function restoreColors()
        for _, l in pairs(entryLabels) do
            pcall(function() l.TextColor3 = l:GetAttribute("OrigColor") or Color3.fromRGB(255, 255, 255) end)
        end
    end

    local function stopSpectate()
        spectating = nil
        if specConn then pcall(function() specConn:Disconnect() end); specConn = nil end
        pcall(function() Camera.CameraSubject = localHum() end)
        restoreColors()
    end

    local function spectate(realName, lbl)
        if spectating == realName then stopSpectate(); return end
        if specConn then pcall(function() specConn:Disconnect() end); specConn = nil end
        restoreColors()
        local p = Players:FindFirstChild(realName)
        if not p then return end
        local function point()
            local ch = p.Character
            local h = ch and ch:FindFirstChildOfClass("Humanoid")
            if h then pcall(function() Camera.CameraSubject = h end) end
        end
        point()
        specConn = p.CharacterAdded:Connect(function()
            task.wait(0.6)
            if spectating == realName then point() end
        end)
        spectating = realName
        if lbl then pcall(function() lbl.TextColor3 = RED end) end
    end

    local function hookEntry(entry)
        if not (entry and entry:IsA("GuiObject")) then return end
        local realName = entry:GetAttribute("RealName")
        if not realName then return end
        local lbl = entry:FindFirstChild("LabelName")
        local btn = entry:FindFirstChild("Button")
        if lbl then
            entryLabels[realName] = lbl
            if lbl:GetAttribute("OrigColor") == nil then lbl:SetAttribute("OrigColor", lbl.TextColor3) end
            if spectating == realName then pcall(function() lbl.TextColor3 = RED end) end
        end
        if btn and btn:IsA("GuiButton") then
            btn.MouseButton1Click:Connect(function() spectate(realName, lbl) end)
        end
    end

    task.spawn(function()
        local lb = LP.PlayerGui:WaitForChild("Leaderboard", 30)
        local sf = lb and lb:WaitForChild("ScrollingFrame", 30)
        if not sf then return end
        for _, e in ipairs(sf:GetChildren()) do hookEntry(e) end
        sf.ChildAdded:Connect(function(e) task.wait(0.15); hookEntry(e) end)
    end)

    Players.PlayerRemoving:Connect(function(p)
        if p.Name == spectating then stopSpectate() end
    end)
    LP.CharacterAdded:Connect(function()
        task.wait(1)
        if not spectating then pcall(function() Camera.CameraSubject = localHum() end) end
    end)
end

------------------------------------------------------------
-- SETTINGS + UNLOAD
------------------------------------------------------------
Library:CreateSettingsTab(Window)

-- Anti-AFK (always-on listener)
LP.Idled:Connect(function()
    if F.AntiAFK then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)

disableAutoMacro()
refreshStats()
notify("Asura", "Loaded (EthosSuite)", 6)
print("[Asura] Loaded. Replica data =", getReplicaData() ~= nil)
