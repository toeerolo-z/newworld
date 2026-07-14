-- JJK Hub | Complete Final Version
-- Fixed Auto Farm + Rasheed Quest + All Features

-- Services
local cloneref_ = cloneref or function(x) return x end
local RS   = cloneref_(game:GetService('RunService'))
local PS   = cloneref_(game:GetService('Players'))
local UIS  = cloneref_(game:GetService('UserInputService'))
local TS   = cloneref_(game:GetService('TweenService'))
local VIM  = cloneref_(game:GetService('VirtualInputManager'))
local TP   = cloneref_(game:GetService('TeleportService'))
local HS   = cloneref_(game:GetService('HttpService'))
local LT   = cloneref_(game:GetService('Lighting'))
local Cam  = cloneref_(workspace.CurrentCamera)

local LP = PS.LocalPlayer
if not LP then
    PS:GetPropertyChangedSignal('LocalPlayer'):Wait()
    LP = PS.LocalPlayer
end
LP = cloneref_(LP)

-- Load Linoria
local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

Library.ShowCustomCursor = false
Library.ShowToggleFrameInKeybinds = true
Library.NotifySide = 'Left'

local Window = Library:CreateWindow({
    Title = 'Xes Hub | Kaizen',
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(660, 700),
    ShowCustomCursor = false,
    UnlockMouseWhileOpen = true,
    MenuFadeTime = 0.2,
})

-- ============================================================
-- TABS
-- ============================================================

local Tabs = {
    Main     = Window:AddTab('Combat & Farming'),
    Player   = Window:AddTab('Player'),
    Visuals  = Window:AddTab('Visuals'),
    Misc     = Window:AddTab('Misc'),
    Settings = Window:AddTab('Settings'),
}

local _Combat   = Tabs.Main:AddLeftGroupbox('Combat')
local _CombatR  = Tabs.Main:AddRightGroupbox('Insta Kill')
local _Farming  = Tabs.Main:AddLeftGroupbox('Mob Farm')

local _Player   = Tabs.Player:AddLeftGroupbox('Movement')
local _PlayerR  = Tabs.Player:AddRightGroupbox('Character')
local _Aimbot   = Tabs.Player:AddLeftGroupbox('Aimbot')
local _AimbotR  = Tabs.Player:AddRightGroupbox('Aimbot Settings')

local _Visuals  = Tabs.Visuals:AddLeftGroupbox('Camera')
local _VisualsR = Tabs.Visuals:AddRightGroupbox('Rendering')
local _PlrESP   = Tabs.Visuals:AddLeftGroupbox('Player ESP')

local _Misc     = Tabs.Misc:AddLeftGroupbox('Utility')
local _MiscR    = Tabs.Misc:AddRightGroupbox('Server')
local _World    = Tabs.Misc:AddLeftGroupbox('Combat')

-- ============================================================
-- STATE
-- ============================================================

local State = {
    autoM1 = false,
    instaKill = false,
    autoFarm = false,
    autoFarmNearest = false,
    speedhack = false, speedhackSpeed = 100,
    infJump = false, infJumpHeight = 50,
    noclip = false, noclipConn = nil,
    flying = false, flySpeed = 100,
    aimbotEnabled = false, aimbotActive = false,
    aimbotMode = 'Toggle', aimbotMethod = 'Camera',
    aimbotFOV = 45, aimbotSens = 1,
    aimbotX = 0, aimbotY = 0,
    showFOV = false, teamCheck = false, visibleOnly = false,
    targetPlayers = true,
    playerESP = false,
    freecam = false, freecamSens = 5, freecamSpeed = 1,
    fovChanger = false, camFOV = 70,
    nofog = false,
    xray = false,
    fullbright = false, brightness = 2,
    clickTP = false,
    hitboxSize = 5, hitboxTrans = 0.9,
    hideNotifs = false,
    nearbyNotif = false, nearbyDist = 50, nearbyTable = {},
}

local function notify(msg, dur)
    Library:Notify(msg, dur or 3)
end

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

local function getChar()
    return LP.Character
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild('HumanoidRootPart')
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass('Humanoid')
end

local function getMobList()
    local mobs = {}
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        -- Get regular mobs
        for _, model in ipairs(enemies:GetChildren()) do
            if model:IsA("Model") and model.Name ~= "Bosses" then
                local enemyName = model:GetAttribute("EnemyName") or model.Name
                if enemyName and not mobs[enemyName] then
                    mobs[enemyName] = true
                end
            end
        end
        
        -- Get bosses
        local bossFolder = enemies:FindFirstChild("Bosses")
        if bossFolder then
            for _, model in ipairs(bossFolder:GetChildren()) do
                if model:IsA("Model") then
                    local enemyName = model:GetAttribute("EnemyName") or model.Name
                    if enemyName and not mobs[enemyName] then
                        mobs[enemyName] = true
                    end
                end
            end
        end
    end
    local mobList = {}
    for name, _ in pairs(mobs) do
        table.insert(mobList, name)
    end
    table.sort(mobList)
    return mobList
end

local function getNPCList()
    local npcs = {}
    local questGivers = workspace:FindFirstChild("QuestGivers")
    if questGivers then
        for _, npc in ipairs(questGivers:GetChildren()) do
            if npc:IsA("Model") and npc.Name then
                if not npcs[npc.Name] then
                    npcs[npc.Name] = true
                end
            end
        end
    end
    local npcList = {}
    for name, _ in pairs(npcs) do
        table.insert(npcList, name)
    end
    table.sort(npcList)
    return npcList
end

-- Fly
local flyHRP, flyFrame
local function flyTick(dt)
    if not State.flying then return end
    local c = getChar()
    if not c then return end
    local hrp = c:FindFirstChild('HumanoidRootPart')
    if not hrp then return end
    flyHRP = hrp
    if not flyFrame then flyFrame = hrp.CFrame end
    local cf = Cam.CFrame
    local look = cf.LookVector
    local right = cf.RightVector
    local move = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(look.X,0,look.Z).Unit end
    if UIS:IsKeyDown(Enum.KeyCode.S) then move -= Vector3.new(look.X,0,look.Z).Unit end
    if UIS:IsKeyDown(Enum.KeyCode.A) then move -= Vector3.new(right.X,0,right.Z).Unit end
    if UIS:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(right.X,0,right.Z).Unit end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
    if move.Magnitude > 0 then
        flyFrame = flyFrame + move.Unit * State.flySpeed * dt
    end
    local fwd = Vector3.new(look.X,0,look.Z)
    if fwd.Magnitude > 0 then
        flyFrame = CFrame.new(flyFrame.Position, flyFrame.Position + fwd.Unit)
    end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.CFrame = flyFrame
end

-- Server hop
local function serverHop(minPlayers)
    minPlayers = tonumber(minPlayers) or 0
    local url = 'https://games.roblox.com/v1/games/'..game.PlaceId..'/servers/Public?sortOrder=Asc&limit=100'
    local cursor, found = nil, nil
    repeat
        local ok, res = pcall(function()
            return HS:JSONDecode(game:HttpGet(url..(cursor and '&cursor='..cursor or '')))
        end)
        if not ok or not res then break end
        for _, s in ipairs(res.data or {}) do
            if s.playing >= minPlayers and s.playing < s.maxPlayers and s.id ~= game.JobId then
                found = s; break
            end
        end
        cursor = res.nextPageCursor
    until found or not cursor
    if found then TP:TeleportToPlaceInstance(game.PlaceId, found.id, LP)
    else notify('No server found', 4) end
end

-- ============================================================
-- COMBAT TAB
-- ============================================================

_Combat:AddLabel('── Auto Combat ──')
_Combat:AddToggle('AutoM1', {
    Text = 'Auto M1',
    Default = false,
    Callback = function(v)
        State.autoM1 = v
        if v then
            local remote = game:GetService("ReplicatedStorage")["@rbxts/wcs:source/networking@GlobalEvents"].requestSkill
            task.spawn(function()
                while State.autoM1 do
                    task.wait(0.1)
                    pcall(function()
                        remote:FireServer({
                            buffer = buffer.fromstring("\x1D\x00\x00\x00Movesets/FightingStyles/Fists\x01\x00\x00\x00\x00"),
                            blobs = {}
                        })
                    end)
                end
            end)
        end
    end,
}):AddKeyPicker('AutoM1Keybind', {
    Default = '', SyncToggleState = true, Mode = 'Toggle',
    Text = 'Auto M1 Keybind', NoUI = false,
})

_CombatR:AddLabel('── Insta Kill ──')
_CombatR:AddLabel('> May not work all the time')
_CombatR:AddToggle('InstaKill', {
    Text = 'Insta Kill',
    Default = false,
    Callback = function(v)
        State.instaKill = v
        if v then
            task.spawn(function()
                while State.instaKill do
                    task.wait(0.05)
                    pcall(function()
                        sethiddenproperty(LP, "SimulationRadius", math.huge)
                        local fallHeight = workspace.FallenPartsDestroyHeight - 50
                        local enemies = workspace:FindFirstChild("Enemies")
                        if enemies then
                            for _, obj in pairs(enemies:GetChildren()) do
                                if obj:IsA("Model") and not PS:GetPlayerFromCharacter(obj) and obj.Parent then
                                    local hum = obj:FindFirstChildOfClass("Humanoid")
                                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                                    if hum and hrp and hum.Health > 0 and hum.MaxHealth > 0 and not hrp.Anchored then
                                        hum.Health = 0
                                        hrp.CanCollide = false
                                        hrp.Anchored = false
                                        hrp.AssemblyLinearVelocity = Vector3.zero
                                        hrp.CFrame = CFrame.new(hrp.Position.X, fallHeight, hrp.Position.Z)
                                    end
                                end
                            end
                            
                            local bosses = enemies:FindFirstChild("Bosses")
                            if bosses then
                                for _, obj in pairs(bosses:GetChildren()) do
                                    if obj:IsA("Model") and not PS:GetPlayerFromCharacter(obj) and obj.Parent then
                                        local hum = obj:FindFirstChildOfClass("Humanoid")
                                        local hrp = obj:FindFirstChild("HumanoidRootPart")
                                        if hum and hrp and hum.Health > 0 and hum.MaxHealth > 0 and not hrp.Anchored then
                                            hum.Health = 0
                                            hrp.CanCollide = false
                                            hrp.Anchored = false
                                            hrp.AssemblyLinearVelocity = Vector3.zero
                                            hrp.CFrame = CFrame.new(hrp.Position.X, fallHeight, hrp.Position.Z)
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end,
}):AddKeyPicker('InstaKillKeybind', {
    Default = '', SyncToggleState = true, Mode = 'Toggle',
    Text = 'Insta Kill Keybind', NoUI = false,
})

-- ============================================================
-- FARMING TAB
-- ============================================================

_Farming:AddLabel('── Select Targets ──')
_Farming:AddDropdown('FarmMobs', {
    Values = getMobList(),
    Default = 1,
    Multi = true,
    Text = 'Select Mobs & Bosses',
    Callback = function(_) end,
})

_Farming:AddButton({
    Text = 'Refresh List',
    Func = function()
        Library.Options.FarmMobs:SetValues(getMobList())
        notify('Mob & Boss list refreshed!')
    end,
})

_Farming:AddLabel('── Auto Farm ──')
_Farming:AddToggle('AutoFarm', {
    Text = 'Auto Farm Selected',
    Default = false,
    Callback = function(v)
        State.autoFarm = v
        if v then
            task.spawn(function()
                while State.autoFarm do
                    pcall(function()
                        local ch = LP.Character
                        if not ch then return end
                        local hrp = ch:FindFirstChild('HumanoidRootPart')
                        if not hrp then return end
                        
                        local selected = Library.Options.FarmMobs.Value or {}
                        
                        -- Check if anything is selected
                        local hasSelection = false
                        for _ in pairs(selected) do hasSelection = true; break end
                        
                        if not hasSelection then
                            sethiddenproperty(hrp, 'PhysicsRepRootPart', nil)
                            return
                        end
                        
                        local enemies = workspace:FindFirstChild('Enemies')
                        if not enemies then return end
                        
                        local best, bestDist = nil, math.huge
                        
                        -- Check ALL regular enemies
                        for _, v in pairs(enemies:GetChildren()) do
                            if not v:IsA('Model') or not v.Parent then continue end
                            if v.Name == "Bosses" then continue end
                            
                            local enemyName = v:GetAttribute("EnemyName") or v.Name
                            
                            if selected[enemyName] then
                                local h = v:FindFirstChildOfClass('Humanoid')
                                local r = v:FindFirstChild('HumanoidRootPart')
                                if not h or not r then continue end
                                if h.Health <= 0 or h.MaxHealth <= 0 or r.Anchored then continue end
                                
                                local d = (r.Position - hrp.Position).Magnitude
                                if d < bestDist then 
                                    best = r
                                    bestDist = d 
                                end
                            end
                        end
                        
                        -- Check inside Bosses folder
                        local bossFolder = enemies:FindFirstChild("Bosses")
                        if bossFolder then
                            for _, v in pairs(bossFolder:GetChildren()) do
                                if not v:IsA('Model') or not v.Parent then continue end
                                
                                local enemyName = v:GetAttribute("EnemyName") or v.Name
                                
                                if selected[enemyName] then
                                    local h = v:FindFirstChildOfClass('Humanoid')
                                    local r = v:FindFirstChild('HumanoidRootPart')
                                    if not h or not r then continue end
                                    if h.Health <= 0 or h.MaxHealth <= 0 or r.Anchored then continue end
                                    
                                    local d = (r.Position - hrp.Position).Magnitude
                                    if d < bestDist then 
                                        best = r
                                        bestDist = d 
                                    end
                                end
                            end
                        end
                        
                        if best then
                            local mobPos = best.Position
                            hrp.CFrame = CFrame.lookAt(Vector3.new(mobPos.X, mobPos.Y - 7, mobPos.Z), mobPos)
                            hrp.AssemblyLinearVelocity = Vector3.zero
                            hrp.AssemblyAngularVelocity = Vector3.zero
                            sethiddenproperty(hrp, 'PhysicsRepRootPart', best)
                            best.AssemblyLinearVelocity = Vector3.zero
                            best.AssemblyAngularVelocity = Vector3.zero
                        else
                            sethiddenproperty(hrp, 'PhysicsRepRootPart', nil)
                        end
                    end)
                    task.wait()
                end
                
                -- Cleanup when disabled
                local hrp = getHRP()
                if hrp then sethiddenproperty(hrp, 'PhysicsRepRootPart', nil) end
            end)
        end
    end,
}):AddKeyPicker('AutoFarmKeybind', {
    Default = '', SyncToggleState = true, Mode = 'Toggle',
    Text = 'Auto Farm Keybind', NoUI = false,
})

_Farming:AddToggle('AutoFarmNearest', {
    Text = 'Auto Farm Nearest',
    Default = false,
    Callback = function(v)
        State.autoFarmNearest = v
        if v then
            local conn
            conn = RS.Heartbeat:Connect(function()
                if not State.autoFarmNearest then
                    if conn then conn:Disconnect() end
                    local hrp = getHRP()
                    if hrp then sethiddenproperty(hrp, 'PhysicsRepRootPart', nil) end
                    return
                end
                
                pcall(function()
                    local ch = LP.Character
                    if not ch then return end
                    local hrp = ch:FindFirstChild('HumanoidRootPart')
                    if not hrp then return end
                    
                    local enemies = workspace:FindFirstChild('Enemies')
                    if not enemies then return end
                    
                    local best, bestDist = nil, math.huge
                    
                    for _, v in pairs(enemies:GetChildren()) do
                        if not v:IsA('Model') or not v.Parent then continue end
                        
                        local h = v:FindFirstChildOfClass('Humanoid')
                        local r = v:FindFirstChild('HumanoidRootPart')
                        if not h or not r then continue end
                        if h.Health <= 0 or h.MaxHealth <= 0 or r.Anchored then continue end
                        
                        local d = (r.Position - hrp.Position).Magnitude
                        if d < bestDist then 
                            best = r
                            bestDist = d 
                        end
                    end
                    
                    local bossFolder = enemies:FindFirstChild("Bosses")
                    if bossFolder then
                        for _, v in pairs(bossFolder:GetChildren()) do
                            if not v:IsA('Model') or not v.Parent then continue end
                            
                            local h = v:FindFirstChildOfClass('Humanoid')
                            local r = v:FindFirstChild('HumanoidRootPart')
                            if not h or not r then continue end
                            if h.Health <= 0 or h.MaxHealth <= 0 or r.Anchored then continue end
                            
                            local d = (r.Position - hrp.Position).Magnitude
                            if d < bestDist then 
                                best = r
                                bestDist = d 
                            end
                        end
                    end
                    
                    if best then
                        local mobPos = best.Position
                        hrp.CFrame = CFrame.lookAt(Vector3.new(mobPos.X, mobPos.Y - 7, mobPos.Z), mobPos)
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                        sethiddenproperty(hrp, 'PhysicsRepRootPart', best)
                        best.AssemblyLinearVelocity = Vector3.zero
                        best.AssemblyAngularVelocity = Vector3.zero
                    else
                        sethiddenproperty(hrp, 'PhysicsRepRootPart', nil)
                    end
                end)
            end)
        end
    end,
}):AddKeyPicker('AutoFarmNearestKeybind', {
    Default = '', SyncToggleState = true, Mode = 'Toggle',
    Text = 'Farm Nearest Keybind', NoUI = false,
})

-- Rollback removed as requested

-- Packet Farm removed as requested

-- Auto Raid removed as requested

-- Loot tab removed as requested

-- ============================================================
-- PLAYER TAB
-- ============================================================

_Player:AddLabel('── Movement ──')
_Player:AddToggle('Speedhack', {
    Text = 'Speedhack',
    Default = false,
    Callback = function(p)
        State.speedhack = p
        if p then
            RS:BindToRenderStep('Speedhack', Enum.RenderPriority.Input.Value, function(dt)
                local hrp = getHRP()
                local hum = getHum()
                if hrp and hum and hum.Health > 0 and hum.MoveDirection.Magnitude > 0 then
                    hrp.CFrame += hum.MoveDirection * State.speedhackSpeed * dt
                end
            end)
        else
            RS:UnbindFromRenderStep('Speedhack')
        end
    end,
}):AddKeyPicker('SpeedhackKeybind', {
    Default = 'N', SyncToggleState = true, Mode = 'Toggle',
    Text = 'Speedhack Keybind', NoUI = false,
})
_Player:AddSlider('SpeedhackSpeed', {
    Text = 'Speed', Default = 100, Min = 0, Max = 5000, Rounding = 0, Compact = true,
    Callback = function(p) State.speedhackSpeed = p end,
})

local ijConn = nil
_Player:AddToggle('InfiniteJump', {
    Text = 'Infinite Jump', Default = false,
    Callback = function(p)
        State.infJump = p
        if ijConn then ijConn:Disconnect() ijConn = nil end
        if p then
            ijConn = UIS.JumpRequest:Connect(function()
                local hrp = getHRP()
                if hrp then hrp.Velocity = Vector3.new(hrp.Velocity.X, State.infJumpHeight, hrp.Velocity.Z) end
            end)
        end
    end,
}):AddKeyPicker('InfiniteJumpKeybind', {
    Default = 'H', SyncToggleState = true, Mode = 'Toggle',
    Text = 'Inf Jump Keybind', NoUI = false,
})
_Player:AddSlider('InfiniteJumpHeight', {
    Text = 'Jump Height', Default = 50, Min = 0, Max = 1000, Rounding = 0, Compact = true,
    Callback = function(p) State.infJumpHeight = p end,
})

_Player:AddToggle('Noclip', {
    Text = 'Noclip', Default = false,
    Callback = function(p)
        State.noclip = p
        if State.noclipConn then State.noclipConn:Disconnect() State.noclipConn = nil end
        if p then
            State.noclipConn = RS.RenderStepped:Connect(function()
                local c = getChar()
                if not c then return end
                for _, part in ipairs(c:GetDescendants()) do
                    if part:IsA('BasePart') then part.CanCollide = false end
                end
            end)
        end
    end,
}):AddKeyPicker('NoclipKeybind', {
    Default = '', SyncToggleState = true, Mode = 'Toggle',
    Text = 'Noclip Keybind', NoUI = false,
})

_Player:AddToggle('Fly', {
    Text = 'Fly', Default = false,
    Callback = function(p)
        State.flying = p
        if p then
            flyFrame = nil
            RS:BindToRenderStep('Fly', Enum.RenderPriority.Input.Value, flyTick)
        else
            RS:UnbindFromRenderStep('Fly')
            flyFrame = nil
        end
    end,
}):AddKeyPicker('FlyKeybind', {
    Default = '', SyncToggleState = true, Mode = 'Toggle',
    Text = 'Fly Keybind', NoUI = false,
})
_Player:AddSlider('FlySpeed', {
    Text = 'Fly Speed', Default = 100, Min = 1, Max = 2000, Rounding = 0, Compact = true,
    Callback = function(p) State.flySpeed = p end,
})

-- CHARACTER
_PlayerR:AddLabel('── Actions ──')
_PlayerR:AddButton({ Text = 'Kill Yourself', Func = function()
    local hum = getHum()
    if hum then hum.Health = 0 end
end})

_PlayerR:AddLabel('── Settings ──')
_PlayerR:AddToggle('HideNotifications', {
    Text = 'Hide Notifications',
    Default = false,
    Callback = function(v)
        State.hideNotifs = v
        pcall(function()
            LP.PlayerGui.Notification.Enabled = not v
        end)
    end,
})

_PlayerR:AddToggle('AntiAFK', {
    Text = 'Anti AFK',
    Default = false,
    Callback = function(p)
        if p then
            LP.Idled:Connect(function()
                VIM:SendMouseButtonEvent(0,0,0,true,game,0)
                task.wait()
                VIM:SendMouseButtonEvent(0,0,0,false,game,0)
            end)
        end
    end,
})

-- ============================================================
-- AIMBOT
-- ============================================================

local function getAimbotTargets()
    local result = {}
    for _, plr in ipairs(PS:GetPlayers()) do
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild('HumanoidRootPart') and State.targetPlayers then
            if State.teamCheck and LP.Team and plr.Team == LP.Team then continue end
            table.insert(result, plr.Character)
        end
    end
    return result
end

local function getAimPart(char)
    local v = Library.Options.AimPart and Library.Options.AimPart.Value or 'Head'
    if v == 'Head' then return char:FindFirstChild('Head') end
    if v == 'Torso' then return char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso') end
    if v == 'Random' then
        local parts = {}
        for _, n in ipairs({'Head','HumanoidRootPart','Torso'}) do
            local p = char:FindFirstChild(n); if p then table.insert(parts, p) end
        end
        return parts[math.random(1,#parts)]
    end
    return char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Head')
end

local function isVisible(part)
    if not (part and part.Parent) then return false end
    local c = getChar()
    if not c then return false end
    local ray = Ray.new(Cam.CFrame.Position, (part.Position - Cam.CFrame.Position).Unit * 1000)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {c, Cam})
    return hit and hit:IsDescendantOf(part.Parent)
end

local function getBestTarget()
    local mouse = UIS:GetMouseLocation()
    local best, bestDist = nil, math.huge
    for _, char in ipairs(getAimbotTargets()) do
        local part = getAimPart(char)
        if not (part and part:IsA('BasePart')) then continue end
        local sp, onScreen = Cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local angle = math.deg(math.acos(math.clamp(Cam.CFrame.LookVector:Dot((part.Position - Cam.CFrame.Position).Unit), -1, 1)))
        if angle > State.aimbotFOV / 2 then continue end
        if State.visibleOnly and not isVisible(part) then continue end
        local d = (mouse - Vector2.new(sp.X, sp.Y)).Magnitude
        if d < bestDist then bestDist = d; best = part end
    end
    return best
end

local function getInputType(str)
    if str == 'MB1' then return Enum.UserInputType.MouseButton1
    elseif str == 'MB2' then return Enum.UserInputType.MouseButton2 end
end

local aimbotConn, aimbotAccum = nil, Vector2.zero
local aimbotHoldConns = {}

_Aimbot:AddLabel('── Configuration ──')
_Aimbot:AddDropdown('AimbotMode', {
    Text = 'Mode', Default = 'Toggle',
    Values = {'Toggle','Hold','Always'},
    Callback = function(p)
        State.aimbotMode = p
        if p == 'Always' then State.aimbotActive = true end
    end,
})
_Aimbot:AddDropdown('AimbotMethod', {
    Text = 'Method', Default = 'Camera',
    Values = {'Camera','mousemoverel'},
    Callback = function(p) State.aimbotMethod = p end,
})
_Aimbot:AddDropdown('AimPart', {
    Text = 'Aim Part', Default = 'Head',
    Values = {'Head','Torso','Random'},
    Callback = function() end,
})
local _aimbotKeybind = _Aimbot:AddLabel('Aimbot Keybind'):AddKeyPicker('AimbotKeybind', {
    Default = 'MB2', SyncToggleState = false, Mode = 'Toggle',
    Text = 'Aimbot Keybind', NoUI = true,
    Callback = function()
        if State.aimbotMode == 'Toggle' then State.aimbotActive = not State.aimbotActive end
    end,
})
_Aimbot:AddToggle('Aimbot', {
    Text = 'Aimbot', Default = false,
    Callback = function(p)
        State.aimbotEnabled = p
        if not p then State.aimbotActive = false end
        if p and State.aimbotMode == 'Always' then State.aimbotActive = true end
        for _, c in pairs(aimbotHoldConns) do c:Disconnect() end
        aimbotHoldConns = {}
        table.insert(aimbotHoldConns, UIS.InputBegan:Connect(function(inp, gpe)
            if gpe then return end
            local kt = getInputType(_aimbotKeybind and _aimbotKeybind.Value or '')
            if kt and inp.UserInputType == kt and State.aimbotMode == 'Hold' then
                State.aimbotActive = true
            end
        end))
        table.insert(aimbotHoldConns, UIS.InputEnded:Connect(function(inp, gpe)
            if gpe then return end
            local kt = getInputType(_aimbotKeybind and _aimbotKeybind.Value or '')
            if kt and inp.UserInputType == kt and State.aimbotMode == 'Hold' then
                State.aimbotActive = false
            end
        end))
        if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
        if p then
            aimbotAccum = Vector2.zero
            aimbotConn = RS.RenderStepped:Connect(function()
                if not State.aimbotActive then return end
                local target = getBestTarget()
                if not target then return end
                local pos = target.Position + Vector3.new(State.aimbotX, State.aimbotY, 0)
                local sens = State.aimbotSens
                if State.aimbotMethod == 'Camera' then
                    local lv = Cam.CFrame.LookVector:Lerp((pos - Cam.CFrame.Position).Unit, math.clamp(sens*0.1, 0.01, 1))
                    Cam.CFrame = CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + lv)
                else
                    local sp = Cam:WorldToViewportPoint(pos)
                    local mouse = UIS:GetMouseLocation()
                    aimbotAccum += (Vector2.new(sp.X, sp.Y) - mouse) * sens
                    local clamped = Vector2.new(math.clamp(aimbotAccum.X,-10,10), math.clamp(aimbotAccum.Y,-10,10))
                    mousemoverel(clamped.X, clamped.Y)
                    aimbotAccum -= clamped
                end
            end)
        end
    end,
})

_AimbotR:AddLabel('── Targeting ──')
_AimbotR:AddToggle('TargetPlayers', {
    Text = 'Target Players', Default = true,
    Callback = function(p) State.targetPlayers = p end,
})
_AimbotR:AddToggle('VisibleOnly', {
    Text = 'Visible Only', Default = false,
    Callback = function(p) State.visibleOnly = p end,
})
_AimbotR:AddToggle('TeamCheck', {
    Text = 'Team Check', Default = false,
    Callback = function(p) State.teamCheck = p end,
})
_AimbotR:AddSlider('AimbotSens', {
    Text = 'Sensitivity', Default = 1, Min = 0.1, Max = 5, Rounding = 2, Compact = true,
    Callback = function(p) State.aimbotSens = p end,
})
_AimbotR:AddSlider('AimbotXOffset', {
    Text = 'X Offset', Default = 0, Min = -300, Max = 300, Rounding = 0, Compact = true,
    Callback = function(p) State.aimbotX = p end,
})
_AimbotR:AddSlider('AimbotYOffset', {
    Text = 'Y Offset', Default = 0, Min = -300, Max = 300, Rounding = 0, Compact = true,
    Callback = function(p) State.aimbotY = p end,
})

local fovCircle = nil
local function getFOVScale() return math.tan(math.rad(1)) * (Cam.ViewportSize.Y/2) end
local function updateFOVCircle()
    if fovCircle then
        fovCircle.Position = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
        fovCircle.Radius = State.aimbotFOV * getFOVScale()
    end
end
Cam:GetPropertyChangedSignal('ViewportSize'):Connect(updateFOVCircle)
Cam:GetPropertyChangedSignal('FieldOfView'):Connect(updateFOVCircle)

_AimbotR:AddLabel('── FOV Circle ──')
_AimbotR:AddToggle('ShowFOV', {
    Text = 'Show FOV', Default = false,
    Callback = function(p)
        State.showFOV = p
        if p then
            if not fovCircle then
                fovCircle = Drawing.new('Circle')
                fovCircle.Thickness = 1
                fovCircle.NumSides = 100
                fovCircle.Filled = false
                fovCircle.Color = Color3.fromRGB(255,255,255)
                fovCircle.Radius = State.aimbotFOV * getFOVScale()
                fovCircle.Position = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
            end
            fovCircle.Visible = true
        elseif fovCircle then
            fovCircle.Visible = false
        end
    end,
})
_AimbotR:AddSlider('AimbotFOV', {
    Text = 'Aimbot FOV', Default = 45, Min = 1, Max = 120, Rounding = 0, Compact = true,
    Callback = function(p)
        State.aimbotFOV = p
        if State.showFOV and fovCircle then fovCircle.Radius = p * getFOVScale() end
    end,
})

-- ============================================================
-- VISUALS TAB
-- ============================================================

-- Click TP
local clickTPConn = nil
_Visuals:AddLabel('── Teleport ──')
_Visuals:AddToggle('ClickTP', {
    Text = 'Click To Teleport (RMB)', Default = false,
    Callback = function(p)
        State.clickTP = p
        if clickTPConn then clickTPConn:Disconnect(); clickTPConn = nil end
        if p then
            clickTPConn = UIS.InputBegan:Connect(function(inp, gpe)
                if gpe or inp.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
                local ray = Cam:ScreenPointToRay(inp.Position.X, inp.Position.Y)
                local res = workspace:Raycast(ray.Origin, ray.Direction * 2000)
                if res then
                    local hrp = getHRP()
                    if hrp then hrp.CFrame = CFrame.new(res.Position + Vector3.new(0,3,0)) end
                end
            end)
        end
    end,
}):AddKeyPicker('ClickTPKeybind', {
    Default = '', SyncToggleState = true, Mode = 'Toggle', Text = 'Click TP Keybind', NoUI = false,
})

-- Freecam
local freecamConns = {}
_Visuals:AddLabel('── Camera ──')
_Visuals:AddToggle('Freecam', {
    Text = 'Freecam', Default = false,
    Callback = function(p)
        State.freecam = p
        for _, c in pairs(freecamConns) do c:Disconnect() end
        freecamConns = {}
        if p then
            Cam.CameraType = Enum.CameraType.Scriptable
            local keys = {}
            local rmb = false
            freecamConns[1] = UIS.InputBegan:Connect(function(inp, gpe)
                if gpe then return end
                keys[inp.KeyCode] = true
                if inp.UserInputType == Enum.UserInputType.MouseButton2 then rmb = true end
            end)
            freecamConns[2] = UIS.InputEnded:Connect(function(inp)
                keys[inp.KeyCode] = false
                if inp.UserInputType == Enum.UserInputType.MouseButton2 then rmb = false end
            end)
            freecamConns[3] = RS.RenderStepped:Connect(function(dt)
                if not State.freecam then return end
                if rmb then
                    local delta = UIS:GetMouseDelta()
                    local cf = Cam.CFrame
                    local pitch = cf:ToEulerAngles(Enum.RotationOrder.YZX)
                    local newPitch = math.clamp(math.deg(pitch) - delta.Y * State.freecamSens * 0.1, -85, 85)
                    Cam.CFrame = CFrame.new(cf.Position)
                        * CFrame.Angles(0, -delta.X * State.freecamSens * 0.1 * math.pi/180, 0)
                        * CFrame.Angles(math.rad(newPitch) - pitch, 0, 0)
                        * (cf - cf.Position)
                    UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
                else
                    UIS.MouseBehavior = Enum.MouseBehavior.Default
                end
                local cf2 = Cam.CFrame
                local spd = State.freecamSpeed * dt * 60
                if keys[Enum.KeyCode.W] then Cam.CFrame = cf2 * CFrame.new(0,0,-spd) end
                if keys[Enum.KeyCode.S] then Cam.CFrame = cf2 * CFrame.new(0,0,spd) end
                if keys[Enum.KeyCode.A] then Cam.CFrame = cf2 * CFrame.new(-spd,0,0) end
                if keys[Enum.KeyCode.D] then Cam.CFrame = cf2 * CFrame.new(spd,0,0) end
                if keys[Enum.KeyCode.E] or keys[Enum.KeyCode.Space] then Cam.CFrame = cf2 * CFrame.new(0,spd,0) end
                if keys[Enum.KeyCode.Q] or keys[Enum.KeyCode.LeftControl] then Cam.CFrame = cf2 * CFrame.new(0,-spd,0) end
            end)
        else
            Cam.CameraType = Enum.CameraType.Custom
            UIS.MouseBehavior = Enum.MouseBehavior.Default
        end
    end,
}):AddKeyPicker('FreecamKeybind', {
    Default = '', SyncToggleState = true, Mode = 'Toggle', Text = 'Freecam Keybind', NoUI = false,
})
_Visuals:AddSlider('FreecamSens', {
    Text = 'Freecam Sensitivity', Default = 5, Min = 1, Max = 20, Rounding = 1, Compact = true,
    Callback = function(p) State.freecamSens = p end,
})
_Visuals:AddSlider('FreecamSpeed', {
    Text = 'Freecam Speed', Default = 1, Min = 0.1, Max = 20, Rounding = 1, Compact = true,
    Callback = function(p) State.freecamSpeed = p end,
})

_Visuals:AddToggle('FOVChanger', {
    Text = 'FOV Changer', Default = false,
    Callback = function(p)
        State.fovChanger = p
        Cam.FieldOfView = p and State.camFOV or 70
    end,
})
_Visuals:AddSlider('CameraFOV', {
    Text = 'Camera FOV', Default = 70, Min = 1, Max = 120, Rounding = 0, Compact = true,
    Callback = function(p)
        State.camFOV = p
        if State.fovChanger then Cam.FieldOfView = p end
    end,
})

-- RENDERING
local noFogLoop = nil
_VisualsR:AddLabel('── Environment ──')
_VisualsR:AddToggle('NoFog', {
    Text = 'No Fog', Default = false,
    Callback = function(p)
        State.nofog = p
        if noFogLoop then noFogLoop:Disconnect(); noFogLoop = nil end
        if p then
            noFogLoop = RS.Heartbeat:Connect(function()
                LT.FogEnd = 100000
                LT.FogStart = 0
                for _, v in ipairs(LT:GetChildren()) do
                    if v:IsA('Atmosphere') then v:Destroy() end
                end
            end)
        else
            LT.FogEnd = 100000
        end
    end,
}):AddKeyPicker('NoFogKeybind', {
    Default = '', SyncToggleState = true, Mode = 'Toggle', Text = 'No Fog Keybind', NoUI = false,
})

_VisualsR:AddToggle('NoGlobalShadows', {
    Text = 'No Global Shadows', Default = false,
    Callback = function(p) LT.GlobalShadows = not p end,
})

local fbLoop = nil
_VisualsR:AddLabel('── Lighting ──')
_VisualsR:AddToggle('FullBright', {
    Text = 'FullBright', Default = false,
    Callback = function(p)
        State.fullbright = p
        if fbLoop then fbLoop:Disconnect(); fbLoop = nil end
        if p then
            fbLoop = RS.RenderStepped:Connect(function()
                LT.Brightness = State.brightness
                LT.ClockTime = 14
                LT.FogEnd = 100000
                LT.GlobalShadows = false
                LT.OutdoorAmbient = Color3.fromRGB(128,128,128)
            end)
        else
            LT.Brightness = 1
            LT.ClockTime = 14
            LT.GlobalShadows = true
        end
    end,
}):AddKeyPicker('FullBrightKeybind', {
    Default = '', SyncToggleState = true, Mode = 'Toggle', Text = 'FullBright Keybind', NoUI = false,
})
_VisualsR:AddSlider('Brightness', {
    Text = 'Brightness', Default = 2, Min = 0, Max = 10, Rounding = 1, Compact = true,
    Callback = function(p) State.brightness = p end,
})

local xrayLoop = nil
_VisualsR:AddToggle('XRay', {
    Text = 'XRay', Default = false,
    Callback = function(p)
        State.xray = p
        if xrayLoop then xrayLoop:Disconnect(); xrayLoop = nil end
        if p then
            xrayLoop = RS.RenderStepped:Connect(function()
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA('BasePart') and not v.Parent:FindFirstChildWhichIsA('Humanoid') and not v.Parent.Parent:FindFirstChildWhichIsA('Humanoid') then
                        v.LocalTransparencyModifier = 0.7
                    end
                end
            end)
        else
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA('BasePart') then v.LocalTransparencyModifier = 0 end
            end
        end
    end,
}):AddKeyPicker('XRayKeybind', {
    Default = '', SyncToggleState = true, Mode = 'Toggle', Text = 'XRay Keybind', NoUI = false,
})

_VisualsR:AddLabel('── World ──')
_VisualsR:AddSlider('TimeOfDay', {
    Text = 'Time of Day', Default = 14, Min = 0, Max = 24, Rounding = 1, Compact = true,
    Callback = function(p) LT.ClockTime = p end,
})
_VisualsR:AddSlider('MaxZoom', {
    Text = 'Max Camera Zoom', Default = 400, Min = 0, Max = 2000, Rounding = 0, Compact = true,
    Callback = function(p) LP.CameraMaxZoomDistance = p end,
})

-- ============================================================
-- PLAYER ESP
-- ============================================================

local PlrESP = {
    Enabled = false,
    Color = Color3.fromRGB(0,162,255),
    Active = {},
    Connections = {},
}

local function removePlrESP(char)
    local d = PlrESP.Active[char]
    if not d then return end
    for _, key in ipairs({'text','box','hl','rname'}) do
        local v = d[key]
        if v then
            if key == 'rname' then pcall(function() RS:UnbindFromRenderStep(v) end)
            elseif key == 'hl' then pcall(function() v:Destroy() end)
            else pcall(function() v:Remove() end) end
        end
    end
    PlrESP.Active[char] = nil
end

local function addPlrESP(char)
    if not (char and char:IsA('Model') and not PlrESP.Active[char]) then return end
    local hum = char:FindFirstChildOfClass('Humanoid')
    local hrp = char:FindFirstChild('HumanoidRootPart')
    if not (hum and hrp) then return end

    local text = Drawing.new('Text'); text.Visible=false; text.Center=true; text.Outline=true; text.Color=PlrESP.Color; text.Size=14
    local box = Drawing.new('Square'); box.Filled=false; box.Visible=false; box.Color=PlrESP.Color; box.Thickness=1

    local hl = Instance.new('Highlight')
    hl.Parent=char; hl.FillColor=PlrESP.Color; hl.OutlineColor=PlrESP.Color
    hl.FillTransparency=0.5; hl.OutlineTransparency=0.5
    hl.Enabled = PlrESP.Enabled

    local rname = 'PESP_'..char:GetDebugId()
    RS:BindToRenderStep(rname, Enum.RenderPriority.Camera.Value+1, function()
        if not (char and char.Parent and hum and hrp and PlrESP.Enabled) then removePlrESP(char); return end
        local myHRP = getHRP()
        if not myHRP then return end
        local dist = (hrp.Position - myHRP.Position).Magnitude
        local sp, vis = Cam:WorldToViewportPoint(hrp.Position)
        if dist > 1000 or not vis then
            text.Visible=false; box.Visible=false; hl.Enabled=false; return
        end
        local scale = 1 / math.max(sp.Z * 0.1, 0.001)
        local sw = 250 * scale; local sh = 500 * scale
        local bx = sp.X - sw/2; local by = sp.Y - sh/2
        box.Position=Vector2.new(bx,by); box.Size=Vector2.new(sw,sh); box.Color=PlrESP.Color; box.Visible=true
        text.Text=string.format('%s [%.0f] %.0fm', char.Name, hum.Health, dist)
        text.Position=Vector2.new(sp.X, by-14-2); text.Size=14; text.Color=PlrESP.Color; text.Visible=true
        hl.Enabled = PlrESP.Enabled
        hl.FillColor=PlrESP.Color; hl.OutlineColor=PlrESP.Color
    end)

    PlrESP.Active[char] = {text=text, box=box, hl=hl, rname=rname}
end

_PlrESP:AddLabel('── Player ESP ──')
_PlrESP:AddToggle('PlrESP', {
    Text = 'Player ESP', Default = false,
    Callback = function(p)
        PlrESP.Enabled = p
        if p then
            task.spawn(function()
                while PlrESP.Enabled do
                    for _, plr in ipairs(PS:GetPlayers()) do
                        if plr ~= LP and plr.Character and not PlrESP.Active[plr.Character] then
                            addPlrESP(plr.Character)
                        end
                    end
                    task.wait(0.3)
                end
            end)
            table.insert(PlrESP.Connections, PS.PlayerAdded:Connect(function(plr)
                plr.CharacterAdded:Connect(function(c) if PlrESP.Enabled then addPlrESP(c) end end)
            end))
        else
            for _, c in pairs(PlrESP.Connections) do if c then c:Disconnect() end end
            PlrESP.Connections = {}
            for char in pairs(PlrESP.Active) do removePlrESP(char) end
        end
    end,
}):AddColorPicker('PlrESPColor', {
    Default = PlrESP.Color, Title = 'Player ESP Color', Transparency = 0,
    Callback = function(p)
        PlrESP.Color = p
        for _, d in pairs(PlrESP.Active) do
            if d.text then d.text.Color=p end
            if d.box then d.box.Color=p end
            if d.hl then d.hl.FillColor=p; d.hl.OutlineColor=p end
        end
    end,
}):AddKeyPicker('PlrESPKeybind', {
    Default = '', SyncToggleState = true, Mode = 'Toggle',
    Text = 'Player ESP Keybind', NoUI = false,
})

-- ============================================================
-- MISC TAB
-- ============================================================

-- Nearby notifier
local nearbyConn = nil
_Misc:AddLabel('── Notifications ──')
_Misc:AddToggle('NearbyNotifier', {
    Text = 'Nearby Players Notifier', Default = false,
    Callback = function(p)
        State.nearbyNotif = p
        if nearbyConn then nearbyConn:Disconnect(); nearbyConn = nil end
        if not p then State.nearbyTable = {}; return end
        nearbyConn = RS.Heartbeat:Connect(function()
            local myHRP = getHRP()
            if not myHRP then return end
            for _, plr in ipairs(PS:GetPlayers()) do
                if plr == LP then continue end
                local c = plr.Character
                local hrp = c and c:FindFirstChild('HumanoidRootPart')
                if not hrp then
                    if State.nearbyTable[plr] then
                        State.nearbyTable[plr] = nil
                    end
                    continue
                end
                local dist = (myHRP.Position - hrp.Position).Magnitude
                local wasNearby = State.nearbyTable[plr]
                local isNearby = dist <= State.nearbyDist
                if isNearby and not wasNearby then
                    State.nearbyTable[plr] = true
                    notify(plr.Name..' is nearby ['..math.floor(dist)..'m]', 6)
                elseif not isNearby and wasNearby then
                    State.nearbyTable[plr] = nil
                    notify(plr.Name..' left nearby range', 4)
                end
            end
        end)
    end,
})
_Misc:AddSlider('NearbyDist', {
    Text = 'Nearby Distance', Default = 50, Min = 5, Max = 500, Rounding = 0, Compact = true,
    Callback = function(p) State.nearbyDist = p end,
})

_Misc:AddLabel('── Performance ──')
_Misc:AddToggle('FPSUnlocker', {
    Text = 'FPS Unlocker', Default = false,
    Callback = function(p)
        if not p then setfpscap(60) end
    end,
})
_Misc:AddInput('FPSCap', {
    Default = '144', Numeric = true, Finished = true, Text = 'FPS Cap', Placeholder = '144',
    Callback = function(p)
        pcall(function()
            if Library.Toggles.FPSUnlocker and Library.Toggles.FPSUnlocker.Value then
                setfpscap(tonumber(p) or 144)
            end
        end)
    end,
})

_Misc:AddButton({ Text = 'FPS Boost', Func = function()
    pcall(function()
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA('ParticleEmitter') or v:IsA('Smoke') or v:IsA('Sparkles') or v:IsA('Fire') then v.Enabled=false end
            if v:IsA('BloomEffect') or v:IsA('BlurEffect') or v:IsA('DepthOfFieldEffect') or v:IsA('SunRaysEffect') then v.Enabled=false end
        end
        LT.GlobalShadows = false
    end)
    notify('FPS Boost applied')
end})

-- Teleport to NPCs
_MiscR:AddLabel('── Teleport to NPCs ──')
_MiscR:AddDropdown('TPtoNPC', {
    Values = getNPCList(),
    Default = 1,
    Multi = false,
    Text = 'Select NPC',
    Callback = function(_) end,
})

_MiscR:AddButton({
    Text = 'Refresh NPC List',
    Func = function()
        Library.Options.TPtoNPC:SetValues(getNPCList())
        notify('NPC list refreshed!')
    end,
})

_MiscR:AddButton({
    Text = 'Teleport to NPC',
    Func = function()
        local selectedNPC = Library.Options.TPtoNPC.Value
        local questGivers = workspace:FindFirstChild("QuestGivers")
        
        if questGivers then
            local npc = questGivers:FindFirstChild(selectedNPC)
            if npc and npc:IsA("Model") then
                local hrp = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("RootPart") or npc.PrimaryPart
                if hrp then
                    local playerHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if playerHRP then
                        playerHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, 5)
                        notify("Teleported to " .. selectedNPC)
                    end
                end
            end
        end
    end,
})

_MiscR:AddLabel('── Server ──')
_MiscR:AddButton({ Text = 'Serverhop', Func = function() task.spawn(serverHop) end })
_MiscR:AddButton({ Text = 'Rejoin', Func = function()
    TP:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
end})
_MiscR:AddButton({ Text = 'Copy JobId', Func = function()
    setclipboard(game.JobId)
    notify('Copied: '..game.JobId)
end})

-- Hitbox Expander
local hitboxConn = nil
_World:AddLabel('── Hitbox ──')
_World:AddToggle('HitboxExpander', {
    Text = 'Hitbox Expander', Default = false,
    Callback = function(p)
        if hitboxConn then hitboxConn:Disconnect(); hitboxConn = nil end
        if p then
            hitboxConn = RS.Heartbeat:Connect(function()
                for _, plr in ipairs(PS:GetPlayers()) do
                    if plr ~= LP and plr.Character then
                        local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
                        if hrp then
                            hrp.Size = Vector3.new(State.hitboxSize, State.hitboxSize, State.hitboxSize)
                            hrp.Transparency = State.hitboxTrans
                            hrp.CanCollide = false
                        end
                    end
                end
            end)
        else
            for _, plr in ipairs(PS:GetPlayers()) do
                if plr ~= LP and plr.Character then
                    local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
                    if hrp then hrp.Size=Vector3.new(2,2,1); hrp.Transparency=1 end
                end
            end
        end
    end,
})
_World:AddSlider('HitboxSize', {
    Text = 'Hitbox Size', Default = 5, Min = 0, Max = 20, Rounding = 0, Compact = true,
    Callback = function(p) State.hitboxSize = p end,
})
_World:AddSlider('HitboxTrans', {
    Text = 'Hitbox Transparency', Default = 0.9, Min = 0, Max = 1, Rounding = 1, Compact = true,
    Callback = function(p) State.hitboxTrans = p end,
})

-- ============================================================
-- SETTINGS TAB
-- ============================================================

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetFolder('XesHub')
SaveManager:SetFolder('XesHub/configs')

SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

local _Menu = Tabs.Settings:AddLeftGroupbox('Menu')
_Menu:AddLabel('Menu Keybind'):AddKeyPicker('MenuKeybind', {
    Default = 'RightShift',
    NoUI = false,
    Text = 'Toggle Menu',
    Callback = function() Library:Toggle() end,
})
Library.ToggleKeybind = Library.Options.MenuKeybind

_Menu:AddButton('Unload Script', function() Library:Unload() end)

SaveManager:LoadAutoloadConfig()
Library:OnUnload(function() Library.Unloaded = true end)

notify('Xes Hub | Kaizen Loaded!', 5)
