-- Load Libraries
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/toeerolo-z/ethossuiterewrite/refs/heads/main/ethossuite.lua"))()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

------------------------------------------------------------
-- WINDOW
------------------------------------------------------------
local Window = Library:CreateWindow({
    Title = "Zero Hub",
})

------------------------------------------------------------
-- CATEGORIES + TABS
------------------------------------------------------------
local CatMain      = Window:AddCategory("MAIN")
local CatCharacter = Window:AddCategory("CHARACTER")
local CatNav       = Window:AddCategory("NAVIGATION")
local CatVisuals   = Window:AddCategory("VISUALS")
local CatMisc      = Window:AddCategory("MISC")

local MainTab      = CatMain:AddTab("Main")
local CharacterTab = CatCharacter:AddTab("Character")
local NavTab       = CatNav:AddTab("Navigation")
local VisualsTab   = CatVisuals:AddTab("Visuals")
local MiscTab      = CatMisc:AddTab("Misc")

------------------------------------------------------------
-- MAIN TAB
------------------------------------------------------------


------------------------------------------------------------
-- MAIN TAB — Auto Farm
------------------------------------------------------------
local FarmBox = MainTab:AddGroupbox("Auto Farm")
local CatchBox = MainTab:AddGroupbox("Catch / Release")

local BattleRemote = game.ReplicatedStorage.Remote.Battle
local PetRemote = game.ReplicatedStorage.Remote.Pet
local BattleBindable = game.ReplicatedStorage.Bindable.Battle
local OperateBattle = BattleBindable:FindFirstChild("OperateBattle")
local ClientBattleAnimationComplete = BattleBindable:FindFirstChild("ClientBattleAnimationComplete")
local BattleService = require(game.ReplicatedStorage.Script.Battle.BattleService)
local ActionService = require(game.ReplicatedStorage.Script.Action.ActionService)

-- Poison cancelAction to block "Move" spam
local _origCancelAction = ActionService.cancelAction
ActionService.cancelAction = function(reason)
    if reason == "Move" then return end
    return _origCancelAction(reason)
end

local function isInBattle()
    local ok, b = pcall(BattleService.getCurrentBattle)
    return ok and b ~= nil
end

local _evo = {
    farming = false,
    autoCatch = false,
    autoCancel = false,
    autoRelease = false,
    autoBattle = false,
    inBattle = false,
    battleConns = {},
    catchItemId = 2000015,
    area = nil,
    _areaMap = {},
}

local function getMonsterAreas()
    local list = {}
    local areas = workspace.Scene and workspace.Scene:FindFirstChild("Area")
    if not areas then return list end
    for _, a in ipairs(areas:GetChildren()) do
        if a.Name:find("MonsterArea") then
            local island = a.Name:match("Island(%d+)")
            local area = a.Name:match("MonsterArea(%d+)")
            local sub = a.Name:match("MonsterSubArea(%d+)")
            local label
            if sub then
                label = "Island " .. island .. " - Sub Area " .. sub
            elseif island and area then
                label = "Island " .. island .. " - Area " .. area
            else
                local zone = a.Name:match("World1(.-)MonsterArea")
                if zone and area then
                    label = zone .. " - Area " .. area
                else
                    label = a.Name
                end
            end
            list[#list+1] = {label = label, raw = a.Name}
        end
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    _evo._areaMap = {}
    local labels = {}
    for _, v in ipairs(list) do
        labels[#labels+1] = v.label
        _evo._areaMap[v.label] = v.raw
    end
    return labels
end

local function releaseUnlocked()
    pcall(function()
        local results = {PetRemote.ReqGetPlayerCurrentPetGroup:InvokeServer(LP.UserId)}
        local data = results[2]
        if type(data) ~= "table" then return end
        local toRemove = {}
        for _, pet in pairs(data) do
            if type(pet) == "table" and pet.uuid then
                local locked = pet.locked == true or pet.locked == "true"
                local loved = pet.loved == true or pet.loved == "true"
                if not locked and not loved then
                    toRemove[#toRemove+1] = pet.uuid
                end
            end
        end
        if #toRemove > 0 then
            PetRemote.ReqRemovePets:InvokeServer(toRemove)
        end
    end)
end

local function setupBattleListeners()
    for _, c in ipairs(_evo.battleConns) do pcall(function() c:Disconnect() end) end
    _evo.battleConns = {}

    -- Battle started
    table.insert(_evo.battleConns, BattleBindable.ClientBattleStart.Event:Connect(function()
        _evo.inBattle = true
        if _evo.autoBattle then
            task.wait(1)
            pcall(function() BattleRemote.ReqAutoBattle:InvokeServer(true) end)
        end
    end))

    -- Battle ended
    table.insert(_evo.battleConns, BattleBindable.EndBattle.Event:Connect(function()
        _evo.inBattle = false
    end))
    table.insert(_evo.battleConns, BattleBindable.ClientBattleComplete.Event:Connect(function()
        _evo.inBattle = false
    end))

    -- Catch phase — click actual UI buttons
    table.insert(_evo.battleConns, BattleBindable.ClientBattleCatchPhaseStart.Event:Connect(function()
        task.wait(1)
        local gui = LP:FindFirstChildOfClass("PlayerGui")
        if not gui then return end

        if _evo.autoCancel then
            -- Click GiveUpButton or EscapeButton
            for _, v in ipairs(gui:GetDescendants()) do
                if (v.Name == "GiveUpButton" or v.Name == "EscapeButton") and (v:IsA("TextButton") or v:IsA("ImageButton")) then
                    pcall(function() firesignal(v.Activated) end)
                    pcall(function() firesignal(v.MouseButton1Click) end)
                    break
                end
            end
        elseif _evo.autoCatch then
            -- Click AutoCatchButton
            for _, v in ipairs(gui:GetDescendants()) do
                if v.Name == "AutoCatchButton" and (v:IsA("TextButton") or v:IsA("ImageButton")) then
                    pcall(function() firesignal(v.Activated) end)
                    pcall(function() firesignal(v.MouseButton1Click) end)
                    break
                end
            end
        end
    end))

    -- Fallback settle
    table.insert(_evo.battleConns, BattleRemote.ResSettleBattle.OnClientEvent:Connect(function()
        if not _evo.autoCatch and not _evo.autoCancel then
            task.wait(2)
            _evo.inBattle = false
        end
    end))

    -- Catch result
    table.insert(_evo.battleConns, BattleRemote.ResCatchPet.OnClientEvent:Connect(function()
        task.wait(3)
        _evo.inBattle = false
    end))

    -- Auto release
    table.insert(_evo.battleConns, PetRemote.ResPlayerPetDataChange.OnClientEvent:Connect(function(data)
        if not _evo.autoRelease then return end
        task.wait(2)
        pcall(function()
            if not data or type(data) ~= "table" or not data.petList then return end
            local filterLevel = ({Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5})[_evo.releaseFilter] or 1
            local toRemove = {}
            for uuid, pet in pairs(data.petList) do
                if type(pet) == "table" and not pet.locked and not pet.loved then
                    if (pet.talentId or 0) <= filterLevel then
                        toRemove[#toRemove+1] = uuid
                    end
                end
            end
            if #toRemove > 0 then
                PetRemote.ReqRemovePets:InvokeServer(toRemove)
            end
        end)
    end))
end

setupBattleListeners()

-- Area dropdown
FarmBox:AddDropdown("FarmArea", {
    Text = "Farm Area",
    Values = getMonsterAreas(),
    Default = "",
    Callback = function(v) _evo.area = _evo._areaMap and _evo._areaMap[v] or v end,
})

FarmBox:AddButton({
    Text = "Refresh Areas",
    Func = function()
        if Library.Options["FarmArea"] then
            Library.Options["FarmArea"]:SetValues(getMonsterAreas())
        end
    end,
})

FarmBox:AddToggle("AutoFarm", {
    Text = "Auto Farm",
    Default = false,
    Description = "TPs to creatures",
    Callback = function(v)
        _evo.farming = v
        if not v then return end

        task.spawn(function()
            while _evo.farming do
                if _evo.inBattle or isInBattle() then task.wait(1); continue end
                local char = LP.Character; if not char then task.wait(1); continue end
                local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then task.wait(1); continue end
                local hum = char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health <= 0 then task.wait(1); continue end
                if not _evo.area or _evo.area == "" then task.wait(1); continue end

                local areas = workspace.Scene and workspace.Scene:FindFirstChild("Area")
                if not areas then task.wait(1); continue end
                local area = areas:FindFirstChild(_evo.area)
                if not area then task.wait(1); continue end
                local areaPart = area:FindFirstChild("1")
                if not areaPart then task.wait(1); continue end

                local center = areaPart.Position
                local radius = areaPart.Size.X / 2

                -- TP to area if far
                if (hrp.Position - center).Magnitude > radius then
                    hrp.CFrame = CFrame.new(center + Vector3.new(0, 5, 0))
                    task.wait(1)
                end

                if _evo.inBattle or isInBattle() then continue end

                -- Walk toward spawn then TP onto creatures
                local monsterFolder = workspace.RefreshPoints and workspace.RefreshPoints:FindFirstChild("Monster")
                if monsterFolder then
                    for _, sp in ipairs(monsterFolder:GetChildren()) do
                        if _evo.inBattle or isInBattle() or not _evo.farming then break end
                        if (sp.Position - center).Magnitude < radius then
                            hum:MoveTo(sp.Position)
                            task.wait(1.5)
                            if _evo.inBattle or isInBattle() then break end

                            -- TP onto nearby creatures and jitter with VIM input
                            local VIM = game:GetService("VirtualInputManager")
                            for _, desc in ipairs(workspace:GetDescendants()) do
                                if _evo.inBattle or isInBattle() then break end
                                if desc:IsA("BasePart") and desc:GetAttribute("creatureUid") then
                                    if (desc.Position - hrp.Position).Magnitude < 80 then
                                        hrp.CFrame = CFrame.new(desc.Position)
                                        task.wait(0.1)
                                        local keys = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D}
                                        for j = 1, 6 do
                                            if _evo.inBattle or isInBattle() then break end
                                            local key = keys[math.random(#keys)]
                                            VIM:SendKeyEvent(true, key, false, game)
                                            task.wait(0.2)
                                            VIM:SendKeyEvent(false, key, false, game)
                                            task.wait(0.1)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                task.wait(0.5)
            end
        end)
    end,
})

FarmBox:AddToggle("AutoBattle", {
    Text = "Auto Battle",
    Default = false,
    Description = "Auto fights in battles",
    Callback = function(v)
        _evo.autoBattle = v
        if v and _evo.inBattle then
            pcall(function() BattleRemote.ReqAutoBattle:InvokeServer(true) end)
        end
    end,
})

CatchBox:AddToggle("AutoCatch", {
    Text = "Auto Catch",
    Default = false,
    Description = "Throws ball in catch phase",
    Callback = function(v) _evo.autoCatch = v end,
})

CatchBox:AddToggle("AutoCancel", {
    Text = "Auto Cancel Battle",
    Default = false,
    Description = "Escapes in catch phase",
    Callback = function(v) _evo.autoCancel = v end,
})

------------------------------------------------------------
-- CHARACTER TAB
------------------------------------------------------------
local MoveBox = CharacterTab:AddGroupbox("Movement")
local UtilBox = CharacterTab:AddGroupbox("Utility")

-- Fly
local _flySpeed = 100
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
local _speed = 100
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
local _infJumpH = 50
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

-- Utility
UtilBox:AddButton({
    Text = "Kill Self",
    DoubleClick = true,
    Func = function()
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end,
})

UtilBox:AddDivider()

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

------------------------------------------------------------
-- NAVIGATION TAB
------------------------------------------------------------
local NpcTpBox = NavTab:AddGroupbox("Teleport to NPC")
local ChestTpBox = NavTab:AddGroupbox("Teleport to Chest")
local ChestBox = NavTab:AddGroupbox("Chest Farm")

ChestTpBox:AddDropdown("ChestTPSelect", {
    Text = "Select Chest",
    Values = (function()
        local r = {}
        local chestFolder = workspace.RuntimeCache.RuntimeCacheClient:FindFirstChild("Chest")
        if chestFolder then
            for i, c in ipairs(chestFolder:GetChildren()) do
                r[#r+1] = "Chest " .. i
            end
        end
        return r
    end)(),
    Default = "",
    Callback = function() end,
})

ChestTpBox:AddButton({
    Text = "Teleport",
    Func = function()
        local sel = Library.Flags["ChestTPSelect"]
        if not sel or sel == "" then return end
        local idx = tonumber(sel:match("%d+"))
        if not idx then return end
        local chestFolder = workspace.RuntimeCache.RuntimeCacheClient:FindFirstChild("Chest")
        if not chestFolder then return end
        local chest = chestFolder:GetChildren()[idx]
        if not chest then return end
        local root = chest:FindFirstChild("Root") or chest:FindFirstChildWhichIsA("BasePart")
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if root and hrp then
            hrp.CFrame = CFrame.new(root.Position + Vector3.new(0, 3, 0))
        end
    end,
})

ChestTpBox:AddButton({
    Text = "Refresh Chests",
    Func = function()
        local r = {}
        local chestFolder = workspace.RuntimeCache.RuntimeCacheClient:FindFirstChild("Chest")
        if chestFolder then
            for i, c in ipairs(chestFolder:GetChildren()) do
                r[#r+1] = "Chest " .. i
            end
        end
        if Library.Options["ChestTPSelect"] then
            Library.Options["ChestTPSelect"]:SetValues(r)
        end
    end,
})

local function getNpcNames()
    local names = {}
    local seen = {}
    local npcFolder = workspace.RefreshPoints:FindFirstChild("NPC")
    if not npcFolder then return names end
    for _, v in ipairs(npcFolder:GetChildren()) do
        if not seen[v.Name] then
            seen[v.Name] = true
            names[#names+1] = v.Name
        end
    end
    table.sort(names)
    return names
end

NpcTpBox:AddDropdown("NpcTPSelect", {
    Text = "Select NPC",
    Values = getNpcNames(),
    Default = "",
    Callback = function() end,
})

NpcTpBox:AddButton({
    Text = "Teleport",
    Func = function()
        local sel = Library.Flags["NpcTPSelect"]
        if not sel or sel == "" then return end
        local npcFolder = workspace.RefreshPoints:FindFirstChild("NPC")
        if not npcFolder then return end
        local npc = npcFolder:FindFirstChild(sel)
        if not npc then return end
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(npc.Position + Vector3.new(0, 3, 0))
        end
    end,
})

NpcTpBox:AddButton({
    Text = "Refresh NPCs",
    Func = function()
        if Library.Options["NpcTPSelect"] then
            Library.Options["NpcTPSelect"]:SetValues(getNpcNames())
        end
    end,
})

local _chestFarm = {enabled = false, conn = nil, hopWhenDone = false}

ChestBox:AddToggle("ChestFarm", {
    Text = "Chest Farm",
    Default = false,
    Description = "TPs to all chests and collects",
    Callback = function(v)
        _chestFarm.enabled = v
        if not v then return end
        task.spawn(function()
            while _chestFarm.enabled do
                local chestFolder = workspace.RuntimeCache.RuntimeCacheClient:FindFirstChild("Chest")
                if not chestFolder or #chestFolder:GetChildren() == 0 then
                    if _chestFarm.hopWhenDone then
                        task.wait(2)
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
                    end
                    task.wait(3)
                    continue
                end

                for _, chest in ipairs(chestFolder:GetChildren()) do
                    if not _chestFarm.enabled then break end
                    if not chest.Parent then continue end
                    local root = chest:FindFirstChild("Root")
                    local part = root or chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
                    if not part then continue end
                    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if not hrp then break end
                    hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 2, 0))
                    task.wait(0.5)
                    local VIM = game:GetService("VirtualInputManager")
                    VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.1)
                    VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    task.wait(1)
                    -- Click to redeem rewards
                    VIM:SendMouseButtonEvent(400, 400, 0, true, game, 0)
                    task.wait(0.1)
                    VIM:SendMouseButtonEvent(400, 400, 0, false, game, 0)
                    task.wait(1)
                end
                task.wait(2)
            end
        end)
    end,
})

ChestBox:AddToggle("ChestHop", {
    Text = "Server Hop When Done",
    Default = false,
    Description = "Hops when all chests collected",
    Callback = function(v) _chestFarm.hopWhenDone = v end,
})

------------------------------------------------------------
-- VISUALS TAB
------------------------------------------------------------
local NpcEspBox = VisualsTab:AddGroupbox("NPC ESP")
local ChestEspBox = VisualsTab:AddGroupbox("Chest ESP")

local _npcEspEnabled = false
local _npcHighlights = {}
local _npcLabels = {}
local _npcEspConn = nil
local _npcColor = Color3.fromRGB(100, 200, 255)

local function cleanNpcESP()
    for _, hl in pairs(_npcHighlights) do pcall(function() hl:Destroy() end) end
    for _, bb in pairs(_npcLabels) do pcall(function() bb:Destroy() end) end
    _npcHighlights = {}
    _npcLabels = {}
    if _npcEspConn then _npcEspConn:Disconnect(); _npcEspConn = nil end
end

local function updateNpcESP()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local npcFolder = workspace.RefreshPoints:FindFirstChild("NPC")
    if not npcFolder then return end

    for _, npc in ipairs(npcFolder:GetChildren()) do
        if not npc:IsA("BasePart") then continue end

        if not _npcHighlights[npc] then
            local hl = Instance.new("Highlight")
            hl.FillColor = _npcColor
            hl.FillTransparency = 0.6
            hl.OutlineColor = _npcColor
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = npc
            hl.Parent = game:GetService("CoreGui")
            _npcHighlights[npc] = hl

            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 200, 0, 30)
            bb.StudsOffset = Vector3.new(0, 4, 0)
            bb.AlwaysOnTop = true
            bb.Adornee = npc
            bb.Parent = game:GetService("CoreGui")
            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.TextColor3 = _npcColor
            txt.TextStrokeTransparency = 0
            txt.TextStrokeColor3 = Color3.new(0, 0, 0)
            txt.Font = Enum.Font.GothamBold
            txt.TextSize = 13
            txt.Parent = bb
            _npcLabels[npc] = bb
        end

        local bb = _npcLabels[npc]
        if bb and myHrp then
            local dist = math.floor((npc.Position - myHrp.Position).Magnitude)
            bb:FindFirstChildOfClass("TextLabel").Text = npc.Name .. " [" .. dist .. "m]"
            bb:FindFirstChildOfClass("TextLabel").TextColor3 = _npcColor
        end
        local hl = _npcHighlights[npc]
        if hl then hl.FillColor = _npcColor; hl.OutlineColor = _npcColor end
    end
end

NpcEspBox:AddToggle("NpcESP", {
    Text = "NPC ESP",
    Default = false,
    Description = "Shows NPCs through walls",
    Callback = function(v)
        _npcEspEnabled = v
        if v then
            _npcEspConn = RunService.Heartbeat:Connect(updateNpcESP)
        else
            cleanNpcESP()
        end
    end,
})

NpcEspBox:AddColorPicker("NpcColor", {
    Text = "NPC Color",
    Default = Color3.fromRGB(100, 200, 255),
    Callback = function(c) _npcColor = c end,
})

local _chestEspEnabled = false
local _chestHighlights = {}
local _chestLabels = {}
local _chestEspConn = nil
local _chestColor = Color3.fromRGB(255, 215, 0)

local function cleanChestESP()
    for _, hl in pairs(_chestHighlights) do pcall(function() hl:Destroy() end) end
    for _, bb in pairs(_chestLabels) do pcall(function() bb:Destroy() end) end
    _chestHighlights = {}
    _chestLabels = {}
    if _chestEspConn then _chestEspConn:Disconnect(); _chestEspConn = nil end
end

local function updateChestESP()
    local myHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local chestFolder = workspace.RuntimeCache.RuntimeCacheClient:FindFirstChild("Chest")
    if not chestFolder then return end

    for _, chest in ipairs(chestFolder:GetChildren()) do
        local part = chest:FindFirstChild("Root") or chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
        if not part then continue end

        if not _chestHighlights[chest] then
            local hl = Instance.new("Highlight")
            hl.FillColor = _chestColor
            hl.FillTransparency = 0.4
            hl.OutlineColor = _chestColor
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = chest
            hl.Parent = game:GetService("CoreGui")
            _chestHighlights[chest] = hl

            local bb = Instance.new("BillboardGui")
            bb.Size = UDim2.new(0, 200, 0, 30)
            bb.StudsOffset = Vector3.new(0, 4, 0)
            bb.AlwaysOnTop = true
            bb.Adornee = part
            bb.Parent = game:GetService("CoreGui")
            local txt = Instance.new("TextLabel")
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.TextColor3 = _chestColor
            txt.TextStrokeTransparency = 0
            txt.TextStrokeColor3 = Color3.new(0, 0, 0)
            txt.Font = Enum.Font.GothamBold
            txt.TextSize = 14
            txt.Parent = bb
            _chestLabels[chest] = bb
        end

        local bb = _chestLabels[chest]
        if bb and myHrp then
            local dist = math.floor((part.Position - myHrp.Position).Magnitude)
            bb:FindFirstChildOfClass("TextLabel").Text = "CHEST [" .. dist .. "m]"
            bb:FindFirstChildOfClass("TextLabel").TextColor3 = _chestColor
        end
        local hl = _chestHighlights[chest]
        if hl then hl.FillColor = _chestColor; hl.OutlineColor = _chestColor end
    end

    -- Clean destroyed chests
    for c, hl in pairs(_chestHighlights) do
        if not c.Parent then
            hl:Destroy(); _chestHighlights[c] = nil
            if _chestLabels[c] then _chestLabels[c]:Destroy(); _chestLabels[c] = nil end
        end
    end
end

ChestEspBox:AddToggle("ChestESP", {
    Text = "Chest ESP",
    Default = false,
    Description = "Shows chests through walls",
    Callback = function(v)
        _chestEspEnabled = v
        if v then
            _chestEspConn = RunService.Heartbeat:Connect(updateChestESP)
        else
            cleanChestESP()
        end
    end,
})

ChestEspBox:AddColorPicker("ChestColor", {
    Text = "Chest Color",
    Default = Color3.fromRGB(255, 215, 0),
    Callback = function(c) _chestColor = c end,
})


------------------------------------------------------------
-- MISC TAB
------------------------------------------------------------
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

------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------
Library:CreateSettingsTab(Window)
