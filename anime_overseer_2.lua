pcall(function()
    if queue_on_teleport and getgenv()._AO_script then
        queue_on_teleport(getgenv()._AO_script)
    end
end)

repeat task.wait() until game:IsLoaded()
task.wait(1)

task.spawn(function()
    local lp = game:GetService("Players").LocalPlayer
    while task.wait() do lp.GameplayPaused = false end
end)

local RS  = game:GetService("RunService")
local PS  = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS  = game:GetService("TweenService")
local LT  = game:GetService("Lighting")
local HS  = game:GetService("HttpService")
local TP  = game:GetService("TeleportService")
local Cam = workspace.CurrentCamera
local LP  = PS.LocalPlayer

local function getChar() return LP.Character end
local function getHRP() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end

if getgenv()._AOUnload then pcall(getgenv()._AOUnload); getgenv()._AOUnload = nil end

local _setId = setthreadidentity or (syn and syn.set_thread_identity) or setidentity
if _setId then pcall(_setId, 8) end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/toeerolo-z/ethossuiterewrite/refs/heads/main/ethossuite.lua"))()
local Window = Library:CreateWindow({ Title = "ZERO HUB", Version = "Anime Overseer" })

local function notify(msg, dur)
    task.defer(function()
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Anime Overseer", Text = msg, Duration = dur or 3
            })
        end)
    end)
end

------------------------------------------------------------
-- GAME DATA
------------------------------------------------------------
local _Packages    = game:GetService("ReplicatedStorage"):WaitForChild("Packages")
local _Infos       = game:GetService("ReplicatedStorage"):WaitForChild("Infos")
local _Replion     = require(_Packages:WaitForChild("Replion"))
local _DataReplion = _Replion.Client:WaitReplion("Data", 30)
local _PlayerInfo  = require(_Infos:WaitForChild("PlayerInfo"))
local _Milestone   = require(_Infos:WaitForChild("Milestone"))
local _Battlepasses = require(_Infos:WaitForChild("Battlepasses"))
local _Traits      = require(_Infos:WaitForChild("Traits"))
local _Merchant    = require(_Infos:WaitForChild("Merchant"))
local _ItemsModule = require(_Infos:WaitForChild("Items"))
local function _getReplion() return _DataReplion end

local _Warp = require(_Packages:WaitForChild("Warp"))

-- All Warp remotes lazy-initialized. Warp.Client() blocks forever if the server
-- hasn't registered the event yet. Lazy init means nothing hangs at startup.
local _warpCache = {}
local function _warp(name)
    if _warpCache[name] then return _warpCache[name] end
    if _setId then pcall(_setId, 2) end
    pcall(function() _warpCache[name] = _Warp.Client(name) end)
    if _setId then pcall(_setId, 8) end
    return _warpCache[name]
end

------------------------------------------------------------
-- SHARED: unit dropdown builder
------------------------------------------------------------
local function _buildUnitList()
    local rep = _getReplion()
    if not rep then return {}, {} end
    local equipped = rep:Get({ "EquippedUnits" }) or {}
    local units = rep:Get({ "Units" }) or {}
    local names, map = {}, {}
    for slot, uuid in pairs(equipped) do
        local uData = units[uuid]
        if uData and uData.Name then
            local label = uData.Name .. " [" .. tostring(slot) .. "]"
            names[#names + 1] = label
            map[label] = uuid
        end
    end
    table.sort(names)
    return names, map
end
local _unitNames, _unitMap = _buildUnitList()

------------------------------------------------------------
-- TABS
------------------------------------------------------------
local CatMacro = Window:AddCategory("MACRO")
local CatJoin  = Window:AddCategory("AUTO JOIN")
local CatMisc  = Window:AddCategory("MISC")
local CatHook  = Window:AddCategory("WEBHOOK")

local MacroTab    = CatMacro:AddTab("Macro")
local JoinTab     = CatJoin:AddTab("Auto Join")
local RewardsTab  = CatMisc:AddTab("Rewards")
local SummonTab   = CatMisc:AddTab("Summon")
local UnitsTab    = CatMisc:AddTab("Units")
local MerchantTab = CatMisc:AddTab("Merchant")
local RerollTab   = CatMisc:AddTab("Reroll")
local WebhookTab  = CatHook:AddTab("Webhook")

local MacroBox = MacroTab:AddGroupbox("Macro")
local StreamerBox = MacroTab:AddGroupbox("Streamer Mode")

-- Hide Name (Streamer Mode) — replaces player name and display name everywhere
local _streamerAlias = "ZEROHUB"
StreamerBox:AddInput("StreamerAlias", { Text = "Alias", Default = "ZEROHUB", Placeholder = "Hidden name...",
    Callback = function(v) _streamerAlias = (v ~= "" and v) or "ZEROHUB" end })

getgenv()._AO_streamerMode = false
StreamerBox:AddToggle("StreamerMode", { Text = "Hide Name", Default = false,
    Description = "Replaces your name and display name everywhere including overhead",
    Callback = function(p) getgenv()._AO_streamerMode = p
        task.spawn(function()
            local playerName = LP.Name
            local displayName = LP.DisplayName
            local function scrubText(instance)
                pcall(function()
                    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
                        local t = instance.Text
                        if t:find(playerName) or t:find(displayName) then
                            instance.Text = t:gsub(playerName, _streamerAlias):gsub(displayName, _streamerAlias)
                        end
                    end
                end)
            end
            local function scrubChar()
                pcall(function()
                    local char = LP.Character; if not char then return end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                        if p then hum.DisplayName = _streamerAlias else hum.DisplayName = displayName end
                    end
                    -- Scrub BillboardGui TextLabels on character (TitleGui etc)
                    for _, desc in ipairs(char:GetDescendants()) do scrubText(desc) end
                end)
            end
            local function scrubAll()
                scrubChar()
                local pg = LP:FindFirstChild("PlayerGui")
                if pg then for _, desc in ipairs(pg:GetDescendants()) do scrubText(desc) end end
            end
            scrubAll()
            local conn1, conn2, conn3
            local pg = LP:FindFirstChild("PlayerGui")
            if p and pg then
                conn1 = pg.DescendantAdded:Connect(function(desc)
                    if not getgenv()._AO_streamerMode then return end
                    task.wait(0.1); scrubText(desc)
                end)
            end
            if p then
                conn2 = LP.CharacterAdded:Connect(function(char)
                    if not getgenv()._AO_streamerMode then return end
                    task.wait(1); scrubChar()
                    -- Watch new BillboardGuis on character
                    conn3 = char.DescendantAdded:Connect(function(desc)
                        if not getgenv()._AO_streamerMode then return end
                        task.wait(0.1); scrubText(desc)
                    end)
                end)
                -- Also watch current character descendants
                local char = LP.Character
                if char then
                    conn3 = char.DescendantAdded:Connect(function(desc)
                        if not getgenv()._AO_streamerMode then return end
                        task.wait(0.1); scrubText(desc)
                    end)
                end
            end
            while getgenv()._AO_streamerMode do scrubAll(); task.wait(2) end
            if conn1 then conn1:Disconnect() end
            if conn2 then conn2:Disconnect() end
            if conn3 then conn3:Disconnect() end
            -- Restore
            pcall(function()
                local char = LP.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.DisplayName = displayName end
                    for _, desc in ipairs(char:GetDescendants()) do
                        pcall(function()
                            if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Text:find(_streamerAlias) then
                                desc.Text = desc.Text:gsub(_streamerAlias, displayName)
                            end
                        end)
                    end
                end
                local pg = LP:FindFirstChild("PlayerGui")
                if pg then
                    for _, desc in ipairs(pg:GetDescendants()) do
                        pcall(function()
                            if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Text:find(_streamerAlias) then
                                desc.Text = desc.Text:gsub(_streamerAlias, displayName)
                            end
                        end)
                    end
                end
            end)
        end)
    end })

-- Auto Vote Start — StartMatch:Fire(false)
getgenv()._AO_autoVoteStart = false
MacroBox:AddToggle("AutoVoteStart", { Text = "Auto Vote Start", Default = false,
    Description = "Automatically votes to start when in a match lobby",
    Callback = function(p) getgenv()._AO_autoVoteStart = p; if not p then return end
        task.spawn(function() while getgenv()._AO_autoVoteStart do
            pcall(function() _warp("StartMatch"):Fire(false) end)
            task.wait(2) end end)
    end })

-- Auto Skip Wave — SkipIntermission:Fire(true)
getgenv()._AO_autoSkip = false
MacroBox:AddToggle("AutoSkipWave", { Text = "Auto Skip Wave", Default = false,
    Description = "Skips wave intermission automatically",
    Callback = function(p) getgenv()._AO_autoSkip = p; if not p then return end
        task.spawn(function() while getgenv()._AO_autoSkip do
            pcall(function() local r = _warp("SkipIntermission"); if r then r:Fire(true) end end)
            task.wait(1) end end)
    end })

-- Auto Replay — VoteForNext:Fire(true, "Retry") after match ends
getgenv()._AO_autoReplay = false
MacroBox:AddToggle("AutoReplay", { Text = "Auto Replay", Default = false,
    Description = "Votes to retry the same map after a match ends",
    Callback = function(p) getgenv()._AO_autoReplay = p; if not p then return end
        task.spawn(function() while getgenv()._AO_autoReplay do
            pcall(function() local r = _warp("VoteForNext"); if r then r:Fire(true, "Retry") end end)
            task.wait(2) end end)
    end })

-- Auto Next — VoteForNext:Fire(true, "Next") after match ends
getgenv()._AO_autoNext = false
MacroBox:AddToggle("AutoNext", { Text = "Auto Next", Default = false,
    Description = "Votes to advance to the next act after a win",
    Callback = function(p) getgenv()._AO_autoNext = p; if not p then return end
        task.spawn(function() while getgenv()._AO_autoNext do
            pcall(function() local r = _warp("VoteForNext"); if r then r:Fire(true, "Next") end end)
            task.wait(2) end end)
    end })

-- Auto Leave — QuitPlayer:Fire(true)
getgenv()._AO_autoLeave = false
MacroBox:AddToggle("AutoLeave", { Text = "Auto Leave", Default = false,
    Description = "Leaves the match automatically",
    Callback = function(p) getgenv()._AO_autoLeave = p; if not p then return end
        task.spawn(function() while getgenv()._AO_autoLeave do
            pcall(function() _warp("QuitPlayer"):Fire(true) end)
            task.wait(2) end end)
    end })

local GameplayBox = MacroTab:AddGroupbox("Gameplay")

-- Smart Auto Play — full overnight farm loop:
-- Enables autoplay, skips intermissions, auto replays, auto upgrades all units
getgenv()._AO_smartAutoPlay = false
GameplayBox:AddToggle("SmartAutoPlay", { Text = "Smart Auto Play", Default = false,
    Description = "Full AFK farm: autoplay + skip waves + auto replay + auto upgrade all units",
    Callback = function(p) getgenv()._AO_smartAutoPlay = p; if not p then return end
        -- Autoplay + skip + replay loop
        task.spawn(function()
            while getgenv()._AO_smartAutoPlay do
                pcall(function() _warp("SetAutoplay"):Invoke(5) end)
                pcall(function() local r = _warp("SkipIntermission"); if r then r:Fire(true) end end)
                pcall(function() local r = _warp("VoteForNext"); if r then r:Fire(true, "Retry") end end)
                task.wait(2)
            end
        end)
        -- Auto upgrade all units loop
        task.spawn(function()
            while getgenv()._AO_smartAutoPlay do
                pcall(function()
                    local rep = _getReplion(); if not rep then return end
                    local equipped = rep:Get({"EquippedUnits"}) or {}
                    for slot, _ in pairs(equipped) do
                        pcall(function() _warp("SetAutoUpgrade"):Fire(true, slot) end)
                    end
                end)
                task.wait(10)
            end
        end)
    end })

GameplayBox:AddDivider()

-- Game Speed — SetGamespeed:Invoke(5, speedName)
GameplayBox:AddDropdown("GameSpeed", { Text = "Game Speed", Values = { "1x", "2x", "3x (Gamepass)" }, Default = "1x",
    Callback = function(v)
        task.spawn(function()
            local map = { ["1x"] = "First", ["2x"] = "Second", ["3x (Gamepass)"] = "Third" }
            pcall(function() _warp("SetGamespeed"):Invoke(5, map[v] or "First") end)
        end)
    end })

GameplayBox:AddDivider()

-- Auto Upgrade Units — loops SetAutoUpgrade for all equipped slots
getgenv()._AO_autoUpgradeUnits = false
GameplayBox:AddToggle("AutoUpgradeUnits", { Text = "Auto Upgrade Units", Default = false,
    Description = "Keeps auto-upgrade enabled on all equipped unit slots",
    Callback = function(p) getgenv()._AO_autoUpgradeUnits = p; if not p then return end
        task.spawn(function() while getgenv()._AO_autoUpgradeUnits do
            pcall(function()
                local rep = _getReplion(); if not rep then return end
                local equipped = rep:Get({"EquippedUnits"}) or {}
                for slot, _ in pairs(equipped) do
                    pcall(function() _warp("SetAutoUpgrade"):Fire(true, slot) end)
                    task.wait(0.3)
                end
            end)
            task.wait(10)
        end end)
    end })

GameplayBox:AddDivider()

-- Auto Buy Stat Upgrades — BuyUpgrade:Invoke(5, upgradeName)
local _upgradeNames = { "Yen Generator", "Yen Storage", "Rift Health", "Placement Area" }
getgenv()._AO_autoBuyUpgrade = false
GameplayBox:AddDropdown("UpgradeTarget", { Text = "Upgrade", Values = _upgradeNames, Default = "Yen Generator",
    Callback = function() end })
GameplayBox:AddToggle("AutoBuyUpgrade", { Text = "Auto Buy Upgrades", Default = false,
    Description = "Continuously buys the selected upgrade until max or out of yen",
    Callback = function(p) getgenv()._AO_autoBuyUpgrade = p; if not p then return end
        task.spawn(function()
            local target = (Library.Options and Library.Options["UpgradeTarget"] and Library.Options["UpgradeTarget"].Value) or "Yen Generator"
            while getgenv()._AO_autoBuyUpgrade do
                local ok, result = pcall(function() return _warp("BuyUpgrade"):Invoke(5, target) end)
                if not ok or not result then
                    notify("Upgrade maxed or out of yen", 3)
                    getgenv()._AO_autoBuyUpgrade = false
                    if Library.Options and Library.Options["AutoBuyUpgrade"] then Library.Options["AutoBuyUpgrade"]:SetValue(false) end
                    break
                end
                task.wait(0.15)
            end
        end)
    end })
local JoinBox     = JoinTab:AddGroupbox("Auto Join Map")
local ChallengeBox = JoinTab:AddGroupbox("Auto Join Challenge")
local RaidJoinBox  = JoinTab:AddGroupbox("Auto Join Raid")

-- ── Map data from Gamemodes module ──
local _Gamemodes = require(_Infos:WaitForChild("Gamemodes"))
local _storyUniverses = {}
local _storyWorldNames = {} -- universe -> { [actNum] = actName }
for universe, uData in pairs(_Gamemodes.Story) do
    if type(uData) == "table" and uData.Worlds then
        _storyUniverses[#_storyUniverses + 1] = universe
        _storyWorldNames[universe] = {}
        for idx, wData in pairs(uData.Worlds) do
            if type(wData) == "table" then
                _storyWorldNames[universe][tonumber(idx)] = wData.Name or ("Act " .. tostring(idx))
            end
        end
    end
end
table.sort(_storyUniverses)

local _difficulties = { "Easy", "Normal", "Hard", "Nightmare" }
local _mapTypes = { "Story", "Stage" }

-- ── Auto Join Map ──
-- CreateMatch:Fire(true, {Type, Universe, Act, Difficulty, OnlyFriends, DifficultyScale})
local _mapType = "Story"
local _mapUniverse = nil
local _mapAct = 1
local _mapDifficulty = "Easy"
local _mapFriendsOnly = false
local _mapMatchmaking = false

JoinBox:AddDropdown("MapType", { Text = "Select Category", Values = _mapTypes, Default = "Story",
    Callback = function(v) _mapType = v end })
JoinBox:AddDropdown("MapUniverse", { Text = "Select Map", Values = _storyUniverses, Default = nil,
    Callback = function(v)
        _mapUniverse = v
        -- Update act dropdown with world names for this universe
        if Library.Options and Library.Options["MapAct"] and _storyWorldNames[v] then
            local actNames = {}
            local sorted = {}
            for idx in pairs(_storyWorldNames[v]) do sorted[#sorted+1] = idx end
            table.sort(sorted)
            for _, idx in ipairs(sorted) do actNames[#actNames+1] = tostring(idx) .. " - " .. _storyWorldNames[v][idx] end
            Library.Options["MapAct"]:SetValues(actNames)
        end
    end })
JoinBox:AddDropdown("MapAct", { Text = "Select Act", Values = { "1", "2", "3", "4", "5", "6", "7", "8" }, Default = "1",
    Callback = function(v) _mapAct = tonumber(v:match("^(%d+)")) or 1 end })
JoinBox:AddDropdown("MapDifficulty", { Text = "Select Difficulty", Values = _difficulties, Default = "Easy",
    Callback = function(v) _mapDifficulty = v end })
JoinBox:AddToggle("MapFriends", { Text = "Friends Only", Default = false,
    Callback = function(v) _mapFriendsOnly = v end })
JoinBox:AddToggle("MapMatchmaking", { Text = "Global Matchmaking", Default = false,
    Callback = function(v) _mapMatchmaking = v end })

getgenv()._AO_autoJoinMap = false
JoinBox:AddToggle("AutoJoinMap", { Text = "Auto Join Map", Default = false,
    Description = "Creates and auto-joins the selected map",
    Callback = function(p) getgenv()._AO_autoJoinMap = p; if not p then return end
        if not _mapUniverse then notify("Select a map first", 2)
            getgenv()._AO_autoJoinMap = false
            if Library.Options and Library.Options["AutoJoinMap"] then Library.Options["AutoJoinMap"]:SetValue(false) end return end
        task.spawn(function()
            local data = { Type = _mapType, Universe = _mapUniverse, Act = _mapAct,
                Difficulty = _mapDifficulty, OnlyFriends = _mapFriendsOnly, DifficultyScale = 100 }
            while getgenv()._AO_autoJoinMap do
                if LP:GetAttribute("InMatch") then task.wait(2); continue end
                pcall(function()
                    if _mapMatchmaking then local gm = _warp("CreateGlobalMatch"); if gm then gm:Invoke(10, data) end
                    else _warp("CreateMatch"):Fire(true, data) end
                end)
                notify("Joining " .. _mapUniverse .. " Act " .. _mapAct, 3)
                task.wait(3)
            end
        end)
    end })

-- ── Auto Join Challenge ──
-- CreateMatch:Fire(true, {Type="Challenges", Category, Slot, OnlyFriends})
local _chalCategories = { "Hourly", "Daily", "Weekly" }
local _chalCategory = "Daily"
local _chalFriendsOnly = false
local _chalMatchmaking = false

ChallengeBox:AddDropdown("ChalCategory", { Text = "Select Challenge", Values = _chalCategories, Default = "Daily",
    Callback = function(v) _chalCategory = v end })
ChallengeBox:AddToggle("ChalFriends", { Text = "Friends Only", Default = false,
    Callback = function(v) _chalFriendsOnly = v end })
ChallengeBox:AddToggle("ChalMatchmaking", { Text = "Global Matchmaking", Default = false,
    Callback = function(v) _chalMatchmaking = v end })

getgenv()._AO_autoJoinChal = false
ChallengeBox:AddToggle("AutoJoinChallenge", { Text = "Auto Join Challenge", Default = false,
    Description = "Creates and auto-joins the selected challenge",
    Callback = function(p) getgenv()._AO_autoJoinChal = p; if not p then return end
        task.spawn(function()
            while getgenv()._AO_autoJoinChal do
                if LP:GetAttribute("InMatch") then task.wait(2); continue end
                pcall(function()
                    local data = { Type = "Challenges", Category = _chalCategory, Slot = 1, OnlyFriends = _chalFriendsOnly }
                    if _chalMatchmaking then local gm = _warp("CreateGlobalMatch"); if gm then gm:Invoke(10, data) end
                    else _warp("CreateMatch"):Fire(true, data) end
                end)
                notify("Joining " .. _chalCategory .. " challenge", 3)
                task.wait(3)
            end
        end)
    end })

-- ── Auto Join Raid ──
-- CreateMatch:Fire(true, {Type="Raids", Universe="Infinity Express", Act=1, Difficulty="", OnlyFriends})
local _raidNames = {}
local _raidWorldNames = {}
for raidName, rData in pairs(_Gamemodes.Raids) do
    if type(rData) == "table" then
        _raidNames[#_raidNames + 1] = raidName
        _raidWorldNames[raidName] = {}
        if rData.Worlds then
            for idx, wData in pairs(rData.Worlds) do
                if type(wData) == "table" then
                    _raidWorldNames[raidName][tonumber(idx)] = wData.Name or ("Act " .. tostring(idx))
                end
            end
        end
    end
end
table.sort(_raidNames)

local _raidSelected = _raidNames[1]
local _raidAct = 1
local _raidFriendsOnly = false
local _raidMatchmaking = false

RaidJoinBox:AddDropdown("RaidName", { Text = "Select Raid", Values = _raidNames, Default = _raidNames[1],
    Callback = function(v)
        _raidSelected = v
        if Library.Options and Library.Options["RaidAct"] and _raidWorldNames[v] then
            local actNames = {}
            local sorted = {}
            for idx in pairs(_raidWorldNames[v]) do sorted[#sorted+1] = idx end
            table.sort(sorted)
            for _, idx in ipairs(sorted) do actNames[#actNames+1] = tostring(idx) .. " - " .. _raidWorldNames[v][idx] end
            Library.Options["RaidAct"]:SetValues(actNames)
        end
    end })
RaidJoinBox:AddDropdown("RaidAct", { Text = "Select Act", Values = { "1", "2", "3" }, Default = "1",
    Callback = function(v) _raidAct = tonumber(v:match("^(%d+)")) or 1 end })
RaidJoinBox:AddToggle("RaidFriends", { Text = "Friends Only", Default = false,
    Callback = function(v) _raidFriendsOnly = v end })
RaidJoinBox:AddToggle("RaidMatchmaking", { Text = "Global Matchmaking", Default = false,
    Callback = function(v) _raidMatchmaking = v end })

getgenv()._AO_autoJoinRaid = false
RaidJoinBox:AddToggle("AutoJoinRaid", { Text = "Auto Join Raid", Default = false,
    Description = "Creates and auto-joins the selected raid",
    Callback = function(p) getgenv()._AO_autoJoinRaid = p; if not p then return end
        if not _raidSelected then notify("Select a raid first", 2)
            getgenv()._AO_autoJoinRaid = false
            if Library.Options and Library.Options["AutoJoinRaid"] then Library.Options["AutoJoinRaid"]:SetValue(false) end return end
        task.spawn(function()
            while getgenv()._AO_autoJoinRaid do
                if LP:GetAttribute("InMatch") then task.wait(2); continue end
                pcall(function()
                    local data = { Type = "Raids", Universe = _raidSelected, Act = _raidAct,
                        Difficulty = "", OnlyFriends = _raidFriendsOnly, DifficultyScale = 100 }
                    if _raidMatchmaking then local gm = _warp("CreateGlobalMatch"); if gm then gm:Invoke(10, data) end
                    else _warp("CreateMatch"):Fire(true, data) end
                end)
                notify("Joining " .. _raidSelected .. " Act " .. _raidAct, 3)
                task.wait(3)
            end
        end)
    end })

-- (Game features moved to Macro tab)

------------------------------------------------------------
-- REWARDS
------------------------------------------------------------
local RewardsBox = RewardsTab:AddGroupbox("Rewards")

getgenv()._AO_autoDaily = false
RewardsBox:AddToggle("AutoDaily", { Text = "Auto Claim Daily Login", Default = false,
    Description = "Claims your daily login reward automatically",
    Callback = function(p) getgenv()._AO_autoDaily = p; if not p then return end
        task.spawn(function() while getgenv()._AO_autoDaily do pcall(function()
            local rep = _getReplion(); if not rep then return end
            local dl = rep:Get({"DailyLogin"}); if type(dl) == "table" and dl.Day then
                local claimed = dl.Claimed or {}
                if not claimed[dl.Day] then _warp("ClaimDaily"):Fire(true, dl.Day); notify("Claimed daily day "..tostring(dl.Day), 3) end
            end end); task.wait(30) end end)
    end })

RewardsBox:AddDivider()
getgenv()._AO_autoQuests = false
RewardsBox:AddToggle("AutoQuests", { Text = "Auto Claim All Quests", Default = false,
    Description = "Claims all completed quests automatically",
    Callback = function(p) getgenv()._AO_autoQuests = p; if not p then return end
        task.spawn(function() while getgenv()._AO_autoQuests do pcall(function()
            local rep = _getReplion(); if not rep then return end
            local quests = rep:Get({"Quests"}); if type(quests) ~= "table" then return end
            for from, cat in pairs(quests) do if type(cat) == "table" then
                for idx, d in pairs(cat) do if type(d) == "table" and d.Completed and not d.Claimed then
                    _warp("ClaimQuest"):Fire(true, "One", from, idx); task.wait(0.4)
                end end end end
        end); task.wait(15) end end)
    end })

RewardsBox:AddDivider()
getgenv()._AO_autoPlaytime = false
RewardsBox:AddToggle("AutoPlaytime", { Text = "Auto Claim Playtime Rewards", Default = false,
    Description = "Claims playtime rewards as they unlock",
    Callback = function(p) getgenv()._AO_autoPlaytime = p; if not p then return end
        task.spawn(function() local total = #_PlayerInfo.FreeRewards
            while getgenv()._AO_autoPlaytime do pcall(function()
                local rep = _getReplion(); if not rep then return end
                local fr = rep:Get({"FreeRewards"}); if type(fr) ~= "table" then return end
                local claimed = fr.Claimed or {}
                for i = 1, total do if not claimed[i] and not claimed[tostring(i)] then
                    _warp("ClaimFreeReward"):Fire(true, i); task.wait(0.5) end end
            end); task.wait(15) end end)
    end })

RewardsBox:AddDivider()
getgenv()._AO_autoConquests = false
RewardsBox:AddToggle("AutoConquests", { Text = "Auto Claim Achievements", Default = false,
    Description = "Claims completed conquest quests and rewards",
    Callback = function(p) getgenv()._AO_autoConquests = p; if not p then return end
        task.spawn(function() while getgenv()._AO_autoConquests do pcall(function()
            local rep = _getReplion(); if not rep then return end
            local conquests = rep:Get({"Conquests", "Normal"}); if type(conquests) ~= "table" then return end
            for name, cData in pairs(conquests) do if type(cData) == "table" and type(cData.Quests) == "table" then
                for idx, q in pairs(cData.Quests) do if type(q) == "table" and q.Completed and not q.Claimed then
                    pcall(function() _warp("ClaimConquestReward"):Invoke(5, "Normal", name, idx) end); task.wait(0.5) end end
                if cData.Completed and not cData.Claimed then
                    pcall(function() _warp("ClaimConquestReward"):Invoke(5, "Normal", name) end); task.wait(0.5) end
            end end end); task.wait(20) end end)
    end })

RewardsBox:AddDivider()
getgenv()._AO_autoMilestone = false
RewardsBox:AddToggle("AutoMilestone", { Text = "Auto Claim Level Milestone", Default = false,
    Description = "Claims level milestone rewards you qualify for",
    Callback = function(p) getgenv()._AO_autoMilestone = p; if not p then return end
        task.spawn(function() while getgenv()._AO_autoMilestone do pcall(function()
            local rep = _getReplion(); if not rep then return end
            local level = rep:Get({"Level"}); if not level then return end
            local claimed = rep:Get({"Milestone"}) or {}
            for i, ms in ipairs(_Milestone) do
                local needed = tonumber(ms.NeedLevel or ms.Level)
                if needed and level >= needed and not claimed[i] and not claimed[tostring(i)] then
                    _warp("ClaimMilestone"):Fire(true, i); notify("Claimed milestone "..tostring(needed), 3); task.wait(0.5) end
            end end); task.wait(30) end end)
    end })

RewardsBox:AddDivider()
getgenv()._AO_autoBP = false
RewardsBox:AddToggle("AutoBattlePass", { Text = "Auto Claim Battle Pass", Default = false,
    Description = "Claims all unlocked battle pass rewards",
    Callback = function(p) getgenv()._AO_autoBP = p; if not p then return end
        task.spawn(function() while getgenv()._AO_autoBP do pcall(function()
            local rep = _getReplion(); if not rep then return end
            local bp = rep:Get({"Battlepasses", _Battlepasses.CurrentPass}); if type(bp) ~= "table" then return end
            local lvl = bp.Level or 0; local cm = bp.Claimed or {}; local unclaimed = false
            for i = 1, lvl do local e = cm[i] or cm[tostring(i)]
                if type(e) == "table" then if not e.Free then unclaimed = true; break end
                else unclaimed = true; break end end
            if unclaimed then _warp("CollectBattlepass"):Invoke(5, "All", {}) end
        end); task.wait(30) end end)
    end })

RewardsBox:AddDivider()
getgenv()._AO_autoIndex = false
RewardsBox:AddToggle("AutoIndex", { Text = "Auto Claim Unit Index", Default = false,
    Description = "Claims all newly discovered units from the index",
    Callback = function(p) getgenv()._AO_autoIndex = p; if not p then return end
        task.spawn(function() while getgenv()._AO_autoIndex do pcall(function()
            local rep = _getReplion(); if not rep then return end
            local disc = rep:Get({"DiscoveredUnitsToClaim"})
            if type(disc) == "table" and next(disc) then
                _warp("ClaimDiscoveredUnit"):Fire(true, "All"); notify("Claimed unit index", 3) end
        end); task.wait(15) end end)
    end })

------------------------------------------------------------
-- SUMMON
------------------------------------------------------------
local SummonBox = SummonTab:AddGroupbox("Auto Summon")

-- SummonUnit:Fire(true, bannerIndex, amount)
-- Banner 1 = Default, Banner 2 = Selection. 50 gems per summon.
-- Track replion Units table to detect new pulls and match target.
local _summonBanner = 1
local _summonAmount = 10

-- Build summonable unit list for target dropdown
local _summonableNames = {}
local _summonableRarityMap = {}
do
    local UnitsInfo = require(_Infos:WaitForChild("Units"))
    for name, data in pairs(UnitsInfo) do
        if type(data) == "table" and not data.NotSummonable and data.Rarity then
            _summonableNames[#_summonableNames + 1] = name
            _summonableRarityMap[name] = data.Rarity
        end
    end
    table.sort(_summonableNames)
end
local _summonRarities = { "Rare", "Epic", "Legendary", "Mythic", "Secret", "Celestial" }

SummonBox:AddDropdown("SummonBanner", { Text = "Banner", Values = { "Default", "Selection" }, Default = "Default",
    Callback = function(v) _summonBanner = v == "Selection" and 2 or 1 end })
SummonBox:AddDropdown("SummonAmount", { Text = "Per Pull", Values = { "1", "10" }, Default = "10",
    Callback = function(v) _summonAmount = tonumber(v) or 10 end })

local _summonTargetUnit = nil
local _summonTargetRarity = nil
SummonBox:AddDropdown("SummonTargetUnit", { Text = "Stop At Unit (optional)", Values = _summonableNames, Default = nil,
    Callback = function(v) _summonTargetUnit = v end })
SummonBox:AddDropdown("SummonTargetRarity", { Text = "Stop At Rarity (optional)", Values = _summonRarities, Default = nil,
    Callback = function(v) _summonTargetRarity = v end })

local _RARITY_RANK = { Rare = 1, Epic = 2, Legendary = 3, Mythic = 4, Secret = 5, Celestial = 6, Rift = 7 }

getgenv()._AO_autoSummon = false
SummonBox:AddToggle("AutoSummon", { Text = "Auto Summon", Default = false,
    Description = "Summons until target unit/rarity is pulled, or out of gems",
    Callback = function(p) getgenv()._AO_autoSummon = p; if not p then return end
        task.spawn(function()
            local banner = _summonBanner; local amount = _summonAmount; local pulls = 0
            local wantUnit = _summonTargetUnit; local wantRarity = _summonTargetRarity
            local wantRarityRank = wantRarity and _RARITY_RANK[wantRarity] or 0
            local UnitsInfo = require(_Infos:WaitForChild("Units"))

            while getgenv()._AO_autoSummon do
                local rep = _getReplion(); if not rep then task.wait(1); continue end
                local gems = rep:Get({"Gems"}) or 0
                if gems < 50 * amount then
                    notify("Out of gems after " .. pulls .. " pulls", 3)
                    break
                end

                -- Snapshot unit UUIDs before pull
                local before = {}
                local unitsTbl = rep:Get({"Units"}) or {}
                for uuid in pairs(unitsTbl) do before[uuid] = true end

                pcall(function() _warp("SummonUnit"):Fire(true, banner, amount) end)
                pulls = pulls + 1
                task.wait(0.6)

                -- Check new units
                local found = false
                pcall(function()
                    local after = rep:Get({"Units"}) or {}
                    for uuid, data in pairs(after) do
                        if not before[uuid] and type(data) == "table" then
                            local unitName = data.Name or ""
                            local unitRarity = UnitsInfo[unitName] and UnitsInfo[unitName].Rarity or ""
                            if wantUnit and unitName == wantUnit then found = true end
                            if wantRarity and (_RARITY_RANK[unitRarity] or 0) >= wantRarityRank then found = true end
                        end
                    end
                end)

                if found then
                    notify("Got target! (" .. pulls .. " pulls)", 4)
                    break
                end
                task.wait(0.4)
            end
            getgenv()._AO_autoSummon = false
            if Library.Options and Library.Options["AutoSummon"] then Library.Options["AutoSummon"]:SetValue(false) end
        end)
    end })

------------------------------------------------------------
-- UNITS (Level, Craft, Specialization)
------------------------------------------------------------
local LevelBox = UnitsTab:AddGroupbox("Level Increase")
local CraftBox = UnitsTab:AddGroupbox("Craft & Specialization")

-- Shared refresh button at top
LevelBox:AddButton({ Text = "Refresh Unit List", Func = function()
    _unitNames, _unitMap = _buildUnitList()
    for _, key in ipairs({"LevelUnit", "SpecUnit"}) do
        if Library.Options and Library.Options[key] then
            Library.Options[key]:SetValues(_unitNames)
        end
    end
    notify("Unit list refreshed", 2)
end })

-- Auto Level Increase — IncreaseLevelCap:Invoke(5, uuid)
local _levelSelectedUUID = nil
LevelBox:AddDropdown("LevelUnit", { Text = "Unit", Values = _unitNames, Default = nil,
    Callback = function(v) _levelSelectedUUID = _unitMap[v] end })

getgenv()._AO_autoLevel = false
LevelBox:AddToggle("AutoLevel", { Text = "Auto Level Increase", Default = false,
    Description = "Uses Special Glasses to max level cap on the selected unit (max 4 increases)",
    Callback = function(p) getgenv()._AO_autoLevel = p; if not p then return end
        if not _levelSelectedUUID then notify("Select a unit first", 2)
            getgenv()._AO_autoLevel = false
            if Library.Options and Library.Options["AutoLevel"] then Library.Options["AutoLevel"]:SetValue(false) end return end
        task.spawn(function() local uuid = _levelSelectedUUID
            while getgenv()._AO_autoLevel do pcall(function()
                local rep = _getReplion(); if not rep then return end
                local glasses = rep:Get({"Items", "Special Glasses"}) or 0; if glasses <= 0 then return end
                local uData = rep:Get({"Units", uuid}); if not uData then return end
                local increased = uData.LevelIncreased or 0
                if increased < 4 then
                    local ok = pcall(function() _warp("IncreaseLevelCap"):Invoke(5, uuid) end)
                    if ok then notify("Leveled " .. (uData.Name or "unit"), 3) end
                else
                    notify("Max level cap reached", 3); getgenv()._AO_autoLevel = false
                    if Library.Options and Library.Options["AutoLevel"] then Library.Options["AutoLevel"]:SetValue(false) end
                end end); task.wait(1) end end)
    end })

-- Auto Craft — CraftItem:Invoke(5, itemName, quantity)
local _craftableItems = {}
do
    local base = _ItemsModule.Base or _ItemsModule
    for name, data in pairs(base) do
        if type(data) == "table" and data.Craft then _craftableItems[#_craftableItems + 1] = name end
    end
    table.sort(_craftableItems)
end

local _selectedCraft = nil
local _craftQuantity = 1
CraftBox:AddDropdown("CraftItem", { Text = "Item to Craft", Values = _craftableItems, Default = nil,
    Callback = function(v) _selectedCraft = v end })
CraftBox:AddSlider("CraftQty", { Text = "Quantity", Default = 1, Min = 1, Max = 99, Decimals = 0,
    Callback = function(v) _craftQuantity = v end })

getgenv()._AO_autoCraft = false
CraftBox:AddToggle("AutoCraft", { Text = "Auto Craft", Default = false,
    Description = "Crafts the selected item at the chosen quantity",
    Callback = function(p) getgenv()._AO_autoCraft = p; if not p then return end
        if not _selectedCraft then notify("Select an item first", 2)
            getgenv()._AO_autoCraft = false
            if Library.Options and Library.Options["AutoCraft"] then Library.Options["AutoCraft"]:SetValue(false) end return end
        task.spawn(function() local item = _selectedCraft; local qty = _craftQuantity
            local ok, result = pcall(function() return _warp("CraftItem"):Invoke(5, item, qty) end)
            if ok and result then notify("Crafted " .. qty .. "x " .. item, 3)
            else notify("Craft failed — check materials/gold", 3) end
            getgenv()._AO_autoCraft = false
            if Library.Options and Library.Options["AutoCraft"] then Library.Options["AutoCraft"]:SetValue(false) end
        end)
    end })

CraftBox:AddDivider()

-- Auto Specialization — SetEspecialization:Invoke(5, uuid, "Confirm", mode)
local _specSelectedUUID = nil
CraftBox:AddDropdown("SpecUnit", { Text = "Unit", Values = _unitNames, Default = nil,
    Callback = function(v) _specSelectedUUID = _unitMap[v] end })
CraftBox:AddDropdown("SpecMode", { Text = "Mode", Values = { "Fast", "Price" }, Default = "Fast",
    Callback = function() end })

getgenv()._AO_autoSpec = false
CraftBox:AddToggle("AutoSpec", { Text = "Auto Specialization", Default = false,
    Description = "Sets specialization on the selected unit (uses Yellow Stars)",
    Callback = function(p) getgenv()._AO_autoSpec = p; if not p then return end
        if not _specSelectedUUID then notify("Select a unit first", 2)
            getgenv()._AO_autoSpec = false
            if Library.Options and Library.Options["AutoSpec"] then Library.Options["AutoSpec"]:SetValue(false) end return end
        task.spawn(function() local uuid = _specSelectedUUID
            local mode = (Library.Options and Library.Options["SpecMode"] and Library.Options["SpecMode"].Value) or "Fast"
            pcall(function() _warp("SetEspecialization"):Invoke(5, uuid, "Confirm", mode) end)
            notify("Specialization set", 3)
            getgenv()._AO_autoSpec = false
            if Library.Options and Library.Options["AutoSpec"] then Library.Options["AutoSpec"]:SetValue(false) end
        end)
    end })

------------------------------------------------------------
-- MERCHANT
------------------------------------------------------------
local GoldBox = MerchantTab:AddGroupbox("Gold Merchant")
local RaidBox = MerchantTab:AddGroupbox("Raids Merchant")

-- Gold Merchant — BuyMerchantItem:Invoke(5, "Gold", itemIndex, quantity)
local _goldItemNames = {}
local _goldItemIndexMap = {}
for i, item in ipairs(_Merchant.GoldMerchant.Items) do
    _goldItemNames[#_goldItemNames + 1] = item.Name
    _goldItemIndexMap[item.Name] = i
end

local _selectedGoldItem = nil
local _goldQty = 1
GoldBox:AddDropdown("GoldItem", { Text = "Item", Values = _goldItemNames, Default = nil,
    Callback = function(v) _selectedGoldItem = v end })
GoldBox:AddSlider("GoldQty", { Text = "Quantity", Default = 1, Min = 1, Max = 99, Decimals = 0,
    Callback = function(v) _goldQty = v end })
GoldBox:AddButton({ Text = "Buy", Func = function()
    if not _selectedGoldItem then notify("Select an item first", 2); return end
    local idx = _goldItemIndexMap[_selectedGoldItem]
    if not idx then notify("Item not found", 2); return end
    task.spawn(function()
        local ok, _, msg = pcall(function() return _warp("BuyMerchantItem"):Invoke(5, "Gold", idx, _goldQty) end)
        if ok then notify("Bought " .. _goldQty .. "x " .. _selectedGoldItem, 3)
        else notify("Purchase failed", 3) end
    end)
end })

-- Raids Merchant — BuyMerchantItem:Invoke(5, "Raids", itemIndex, quantity)
local _raidItemNames = {}
local _raidItemIndexMap = {}
for i, item in ipairs(_Merchant.RaidsMerchant.Items) do
    _raidItemNames[#_raidItemNames + 1] = item.Name
    _raidItemIndexMap[item.Name] = i
end

local _selectedRaidItem = nil
local _raidQty = 1
RaidBox:AddDropdown("RaidItem", { Text = "Item", Values = _raidItemNames, Default = nil,
    Callback = function(v) _selectedRaidItem = v end })
RaidBox:AddSlider("RaidQty", { Text = "Quantity", Default = 1, Min = 1, Max = 99, Decimals = 0,
    Callback = function(v) _raidQty = v end })
RaidBox:AddButton({ Text = "Buy", Func = function()
    if not _selectedRaidItem then notify("Select an item first", 2); return end
    local idx = _raidItemIndexMap[_selectedRaidItem]
    if not idx then notify("Item not found", 2); return end
    task.spawn(function()
        local ok, _, msg = pcall(function() return _warp("BuyMerchantItem"):Invoke(5, "Raids", idx, _raidQty) end)
        if ok then notify("Bought " .. _raidQty .. "x " .. _selectedRaidItem, 3)
        else notify("Purchase failed", 3) end
    end)
end })

------------------------------------------------------------
-- REROLL (Classes + Traits)
------------------------------------------------------------
local ClassBox = RerollTab:AddGroupbox("Auto Class Reroll")
local TraitBox = RerollTab:AddGroupbox("Auto Trait Reroll")

local _CLASS_RANK = { D = 1, C = 2, B = 3, A = 4, S = 5, X = 6, Z = 7 }
local _STAT_NAMES = { "Damage", "Health", "Cooldown", "Range", "Speed" }

-- Build trait rarity rank
local _TRAIT_RARITY_RANK = { Rare = 1, Epic = 2, Legendary = 3, Mythic = 4 }
local _traitNames = {}
for name in pairs(_Traits) do
    if type(_Traits[name]) == "table" and _Traits[name].Rarity then
        _traitNames[#_traitNames + 1] = name
    end
end
table.sort(_traitNames)

ClassBox:AddButton({ Text = "Refresh Unit List", Func = function()
    _unitNames, _unitMap = _buildUnitList()
    for _, key in ipairs({"RerollUnit", "TraitUnit", "LevelUnit", "SpecUnit"}) do
        if Library.Options and Library.Options[key] then Library.Options[key]:SetValues(_unitNames) end
    end
    notify("Unit list refreshed", 2)
end })

-- Auto Class Reroll — RollNewClassToUnit:Invoke(5, uuid, "All")
local _rerollSelectedUUID = nil
ClassBox:AddDropdown("RerollUnit", { Text = "Unit", Values = _unitNames, Default = nil,
    Callback = function(v) _rerollSelectedUUID = _unitMap[v] end })

local _rerollTargetGrade = "S"
ClassBox:AddDropdown("RerollTarget", { Text = "Stop At Grade", Values = { "B", "A", "S", "X", "Z" }, Default = "S",
    Callback = function(v) _rerollTargetGrade = v end })

getgenv()._AO_autoClassReroll = false
ClassBox:AddToggle("AutoClassReroll", { Text = "Auto Class Reroll", Default = false,
    Description = "Rerolls all stats until every one reaches the target grade",
    Callback = function(p) getgenv()._AO_autoClassReroll = p; if not p then return end
        if not _rerollSelectedUUID then notify("Select a unit first", 2)
            getgenv()._AO_autoClassReroll = false
            if Library.Options and Library.Options["AutoClassReroll"] then Library.Options["AutoClassReroll"]:SetValue(false) end return end
        task.spawn(function() local uuid = _rerollSelectedUUID; local targetRank = _CLASS_RANK[_rerollTargetGrade] or 5; local rolls = 0
            while getgenv()._AO_autoClassReroll do
                local done = true
                pcall(function()
                    local rep = _getReplion(); if not rep then done = false; return end
                    local uData = rep:Get({"Units", uuid}); if not uData or type(uData.Status) ~= "table" then done = false; return end
                    for _, stat in ipairs(_STAT_NAMES) do
                        local cls = uData.Status[stat]; local grade = type(cls) == "table" and cls[1] or cls
                        if type(grade) == "string" then if (_CLASS_RANK[grade] or 0) < targetRank then done = false end
                        else done = false end
                    end end)
                if done then notify("All stats at " .. _rerollTargetGrade .. "! (" .. rolls .. " rolls)", 4)
                    if getgenv()._AO_webhookClassReroll then
                        _sendWebhook("Class Reroll Complete!", "All stats reached " .. _rerollTargetGrade .. " in " .. rolls .. " rolls", 65280, {
                            { name = "Target Grade", value = _rerollTargetGrade, inline = true },
                            { name = "Rolls", value = tostring(rolls), inline = true },
                            { name = "Player", value = LP.Name, inline = true },
                        })
                    end
                    getgenv()._AO_autoClassReroll = false
                    if Library.Options and Library.Options["AutoClassReroll"] then Library.Options["AutoClassReroll"]:SetValue(false) end break end
                pcall(function() _warp("RollNewClassToUnit"):Invoke(5, uuid, "All") end)
                rolls = rolls + 1; task.wait(0.35)
            end end)
    end })

-- Auto Trait Reroll — RollNewTrait:Fire(true, uuid)
local _traitSelectedUUID = nil
TraitBox:AddDropdown("TraitUnit", { Text = "Unit", Values = _unitNames, Default = nil,
    Callback = function(v) _traitSelectedUUID = _unitMap[v] end })

local _targetTrait = nil
TraitBox:AddDropdown("TargetTrait", { Text = "Stop At Trait", Values = _traitNames, Default = nil,
    Callback = function(v) _targetTrait = v end })

local _targetTraitRarity = nil
TraitBox:AddDropdown("TargetTraitRarity", { Text = "Or Stop At Rarity", Values = { "Epic", "Legendary", "Mythic" }, Default = nil,
    Callback = function(v) _targetTraitRarity = v end })

getgenv()._AO_autoTraitReroll = false
TraitBox:AddToggle("AutoTraitReroll", { Text = "Auto Trait Reroll", Default = false,
    Description = "Rerolls traits until the target trait or rarity is hit (uses Trait Disks)",
    Callback = function(p) getgenv()._AO_autoTraitReroll = p; if not p then return end
        if not _traitSelectedUUID then notify("Select a unit first", 2)
            getgenv()._AO_autoTraitReroll = false
            if Library.Options and Library.Options["AutoTraitReroll"] then Library.Options["AutoTraitReroll"]:SetValue(false) end return end
        if not _targetTrait and not _targetTraitRarity then notify("Select a target trait or rarity", 2)
            getgenv()._AO_autoTraitReroll = false
            if Library.Options and Library.Options["AutoTraitReroll"] then Library.Options["AutoTraitReroll"]:SetValue(false) end return end
        task.spawn(function() local uuid = _traitSelectedUUID; local rolls = 0
            local wantTrait = _targetTrait; local wantRarity = _targetTraitRarity
            local wantRarityRank = wantRarity and _TRAIT_RARITY_RANK[wantRarity] or 0
            while getgenv()._AO_autoTraitReroll do
                local done = false
                pcall(function()
                    local rep = _getReplion(); if not rep then return end
                    local uData = rep:Get({"Units", uuid}); if not uData then return end
                    local currentTrait = uData.Trait or ""
                    if wantTrait and currentTrait == wantTrait then done = true; return end
                    if wantRarity and currentTrait ~= "" then
                        local tData = _Traits[currentTrait]
                        if tData and (_TRAIT_RARITY_RANK[tData.Rarity] or 0) >= wantRarityRank then done = true end
                    end
                end)
                if done then notify("Got target trait! (" .. rolls .. " rolls)", 4)
                    if getgenv()._AO_webhookTraitReroll then
                        _sendWebhook("Trait Reroll Complete!", "Got target in " .. rolls .. " rolls", 11141290, {
                            { name = "Target", value = (wantTrait or wantRarity or "Any"), inline = true },
                            { name = "Rolls", value = tostring(rolls), inline = true },
                            { name = "Player", value = LP.Name, inline = true },
                        })
                    end
                    getgenv()._AO_autoTraitReroll = false
                    if Library.Options and Library.Options["AutoTraitReroll"] then Library.Options["AutoTraitReroll"]:SetValue(false) end break end
                pcall(function() _warp("RollNewTrait"):Fire(true, uuid) end)
                rolls = rolls + 1; task.wait(0.35)
            end end)
    end })

------------------------------------------------------------
-- WEBHOOK
------------------------------------------------------------
local WebhookBox = WebhookTab:AddGroupbox("Configuration")
local WebhookEventsBox = WebhookTab:AddGroupbox("Events")

-- Webhook sender using executor HTTP
local _webhookUrl = ""
local function _sendWebhook(title, description, color, fields)
    if _webhookUrl == "" then return end
    local httpFn = (syn and syn.request) or request or http_request or (http and http.request)
    if not httpFn then return end
    local embed = {
        title = title,
        description = description,
        color = color or 5793266,
        fields = fields or {},
        footer = { text = "Zero Hub • Anime Overseer" },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }
    pcall(function()
        httpFn({
            Url = _webhookUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = game:GetService("HttpService"):JSONEncode({
                embeds = { embed },
            }),
        })
    end)
end

-- Expose globally so other features can call it
getgenv()._AO_sendWebhook = _sendWebhook

WebhookBox:AddInput("WebhookURL", {
    Text = "Discord Webhook URL",
    Default = "",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(v) _webhookUrl = v end,
})

WebhookBox:AddButton({ Text = "Test Webhook", Func = function()
    _sendWebhook("Test Notification", "Webhook is working!", 65280, {
        { name = "Player", value = LP.Name, inline = true },
        { name = "Game", value = "Anime Overseer", inline = true },
    })
    notify("Webhook test sent", 2)
end })

-- Event toggles
getgenv()._AO_webhookSummon = false
getgenv()._AO_webhookMinRarity = "Mythic"
getgenv()._AO_webhookClassReroll = false
getgenv()._AO_webhookTraitReroll = false

WebhookEventsBox:AddToggle("WebhookSummon", { Text = "Notify on Summon", Default = false,
    Description = "Sends a webhook when you pull a unit at or above the target rarity",
    Callback = function(v) getgenv()._AO_webhookSummon = v end })

WebhookEventsBox:AddDropdown("WebhookMinRarity", { Text = "Minimum Rarity", Values = { "Epic", "Legendary", "Mythic", "Secret", "Celestial" }, Default = "Mythic",
    Callback = function(v) getgenv()._AO_webhookMinRarity = v end })

WebhookEventsBox:AddDivider()

WebhookEventsBox:AddToggle("WebhookClassReroll", { Text = "Notify on Class Reroll Done", Default = false,
    Description = "Sends a webhook when auto class reroll hits the target",
    Callback = function(v) getgenv()._AO_webhookClassReroll = v end })

WebhookEventsBox:AddToggle("WebhookTraitReroll", { Text = "Notify on Trait Reroll Done", Default = false,
    Description = "Sends a webhook when auto trait reroll hits the target",
    Callback = function(v) getgenv()._AO_webhookTraitReroll = v end })

WebhookEventsBox:AddDivider()

getgenv()._AO_webhookItemDrop = false
WebhookEventsBox:AddToggle("WebhookItemDrop", { Text = "Notify on Match Rewards", Default = false,
    Description = "Sends a webhook when you receive items from a match",
    Callback = function(v) getgenv()._AO_webhookItemDrop = v end })

-- Item drop watcher: track item quantities and report changes
task.spawn(function()
    pcall(function()
        local rep = _getReplion(); if not rep then return end
        local _lastItems = {}
        -- Snapshot current items
        local items = rep:Get({"Items"}) or {}
        for k, v in pairs(items) do
            if type(v) == "number" then _lastItems[k] = v end
        end
        -- Listen for item changes
        rep:OnChange({ "Items" }, function(action, key, value)
            if not getgenv()._AO_webhookItemDrop then return end
            if type(value) ~= "number" then return end
            local prev = _lastItems[key] or 0
            local diff = value - prev
            _lastItems[key] = value
            if diff > 0 then
                _sendWebhook("Item Received!", "+" .. diff .. "x " .. tostring(key), 3447003, {
                    { name = "Item", value = tostring(key), inline = true },
                    { name = "Amount", value = "+" .. tostring(diff), inline = true },
                    { name = "Total", value = tostring(value), inline = true },
                })
            end
        end)
    end)
end)

-- Summon watcher: listen for new units added to replion
task.spawn(function()
    pcall(function()
        local rep = _getReplion(); if not rep then return end
        local UnitsInfo = require(_Infos:WaitForChild("Units"))
        rep:OnChange({ "Units" }, function(action, key, value)
            if not getgenv()._AO_webhookSummon then return end
            if action ~= "Set" and action ~= "Insert" then return end
            if type(value) ~= "table" or not value.Name then return end
            local unitName = value.Name
            local unitRarity = UnitsInfo[unitName] and UnitsInfo[unitName].Rarity or "Unknown"
            local minRank = _RARITY_RANK[getgenv()._AO_webhookMinRarity] or 4
            local unitRank = _RARITY_RANK[unitRarity] or 0
            if unitRank >= minRank then
                _sendWebhook("Unit Obtained!", unitName, ({
                    Epic = 5793266, Legendary = 16750848, Mythic = 11141290,
                    Secret = 16711680, Celestial = 16766720, Rift = 65535,
                })[unitRarity] or 5793266, {
                    { name = "Unit", value = unitName, inline = true },
                    { name = "Rarity", value = unitRarity, inline = true },
                    { name = "Player", value = LP.Name, inline = true },
                })
            end
        end)
    end)
end)

------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------
Library:CreateSettingsTab(Window)

------------------------------------------------------------
-- UNLOAD
------------------------------------------------------------
getgenv()._AOUnload = function()
    getgenv()._AO_autoVoteStart = false
    getgenv()._AO_autoSkip = false
    getgenv()._AO_autoReplay = false
    getgenv()._AO_autoNext = false
    getgenv()._AO_autoLeave = false
    getgenv()._AO_smartAutoPlay = false
    getgenv()._AO_autoUpgradeUnits = false
    getgenv()._AO_autoBuyUpgrade = false
    getgenv()._AO_autoSummon = false
    getgenv()._AO_autoDaily = false
    getgenv()._AO_autoQuests = false
    getgenv()._AO_autoPlaytime = false
    getgenv()._AO_autoConquests = false
    getgenv()._AO_autoMilestone = false
    getgenv()._AO_autoBP = false
    getgenv()._AO_autoIndex = false
    getgenv()._AO_autoLevel = false
    getgenv()._AO_autoCraft = false
    getgenv()._AO_autoSpec = false
    getgenv()._AO_autoClassReroll = false
    getgenv()._AO_autoTraitReroll = false
    getgenv()._AO_autoJoinMap = false
    getgenv()._AO_autoJoinChal = false
    getgenv()._AO_autoJoinRaid = false
    pcall(function() Library:Destroy() end)
    getgenv()._AOUnload = nil
end

notify("Anime Overseer loaded", 4)
