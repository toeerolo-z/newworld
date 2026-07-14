
--============================ services / locals ============================--
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local VIM               = game:GetService("VirtualInputManager")
local UIS               = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local Debris            = game:GetService("Debris")
local LocalPlayer       = Players.LocalPlayer

local V3     = Vector3.new
local ZERO   = Vector3.zero
local clamp  = math.clamp
local clock  = os.clock
local lookAt = CFrame.lookAt

local FORWARD     = V3(0, 0, 1)
local GUARD_FORCE = V3(1e5, 0, 1e5)

-- verified against Client.Gameplay LoadAnims (line 3788) on 2026-07-07
local ANIMS = {
    BlockRight = 15375405103,          BlockLeft = 15375417546,
    SwipeBlockRight = 123316230501789, SwipeBlockLeft = 100296894124745,
    LongBlockRight = 109779307479864,  LongBlockLeft = 130848044326978,
    StandBlockRight = 16447155536,     StandBlockLeft = 16447214792,
    TwoHandStandBlock = 91320511959716,
    ReachRight = 126884004281505,      ReachLeft = 99895769520149,
    InterceptPass = 88646015596842,
}
local RUN_BLOCKS   = { "Block", "SwipeBlock", "LongBlock" }   -- the game's own variant pools
local STAND_BLOCKS = { "StandBlock", "TwoHandStandBlock" }

local PUSH_ATTRS  = { "Pushed", "Clamped" }
local ANKLE_ATTRS = { "Ankles", "Fall" }
-- stagger/knockdown anims we cancel (Pushes + Falls dicts, incl. the 3 new LayFalls)
local PUSH_ANIM_IDS, ANKLE_ANIM_IDS = {}, {}
for _, id in ipairs({ 15346915273 }) do
    PUSH_ANIM_IDS["rbxassetid://" .. id] = true
end
for _, id in ipairs({ 15448466259, 15448484675, 15448511417, 101141278914491,
                      15449199715, 133485333877856, 139395564243728, 15471296729,
                      112656497338583, 83341511054813, 92080584011177 }) do
    ANKLE_ANIM_IDS["rbxassetid://" .. id] = true
end

--============================ clean prior instance ============================--
if getgenv().__HoopsUtil then pcall(function() getgenv().__HoopsUtil.destroy() end) end
getgenv().__HoopsUtil = {}
local App = getgenv().__HoopsUtil

--============================ config ============================--
App.autoGreen     = false
App.timingOffset  = 0                 -- extra lead seconds; positive = release earlier
App.seedBeforeEnd = 0.06              -- internal: first-guess release lead on fresh curves
App.shootKey      = Enum.KeyCode.E
App.dunkKey       = Enum.KeyCode.Space
App.dunkAnywhere  = false
App.rimTeleport   = false
App.contestIndicator = false
App.infStamina    = false
App.walkSpeedLock = false
App.walkSpeedValue = 30
App.autoGuard     = false
App.guardKey      = Enum.KeyCode.G
App.guardDist     = 5
App.guardMode     = "Blatant"         -- "Blatant" physics snap | "Legit" human-look (walkspeed, reaction delay)
App.guardReaction = 0.18              -- Legit mode: seconds behind the handler's actual position we react
App.autoBlock     = false
App.blockRange    = 14
App.blockOnlyTarget = true
App.autoSteal     = false
App.stealRange    = 10
App.autoIntercept = false
App.interceptRange = 30
App.antiPush      = false
App.antiAnkle     = false
App.antiAfk       = false
App.antiOob       = false
App.ballMagnet    = false
App.reachMult     = 4
App.dribbleMods   = false
App.maxHandles    = false             -- EXPERIMENTAL: block the per-move "Handles" report
App.dribbleGlide  = false
App.glideSpeed    = 26                -- game's own bursts run ~16-20; server lag-backs well past that
App.glideDist     = 10
App.glideDelay    = 0.35
App.spinBot       = false
App.spinSpeed     = 720               -- deg/s; slider caps at 5400 (~15 rev/s)
App.spinMode      = "Smooth"          -- "Smooth" continuous | "Chaos" random facing per frame
App.hasSkillHook  = false
App.teamcheck     = false
App.baseValuesMod = false
App.bvHandleSpeed = 20                -- vanilla 15.8; server rubber-bands past ~24
App.bvMoveShot    = 12                -- vanilla 7.5
App.bvDrift       = 6                 -- vanilla 4.1

--============================ cached lookups ============================--
local Char, HRP, Hum
local function parts()
    local c = LocalPlayer.Character
    if not c then return nil, nil, nil end
    if c ~= Char then
        Char, HRP, Hum = c, c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
    else
        if not (HRP and HRP.Parent) then HRP = c:FindFirstChild("HumanoidRootPart") end
        if not (Hum and Hum.Parent) then Hum = c:FindFirstChildOfClass("Humanoid") end
    end
    return HRP, Hum, c
end

local smCache
local function meterGui()
    if smCache and smCache.Parent then return smCache end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    smCache = pg and pg:FindFirstChild("ShotMeter")
    return smCache
end

local actionsRemote, uiEventRemote
local function getActions()
    if actionsRemote and actionsRemote.Parent then return actionsRemote end
    local lib = ReplicatedStorage:FindFirstChild("Lib")
    local ev  = lib and lib:FindFirstChild("EventsPlayer")
    actionsRemote = ev and ev:FindFirstChild("Actions")
    return actionsRemote
end
local function getUIEvent()
    if uiEventRemote and uiEventRemote.Parent then return uiEventRemote end
    local lib = ReplicatedStorage:FindFirstChild("Lib")
    local ev  = lib and lib:FindFirstChild("EventsPlayer")
    uiEventRemote = ev and ev:FindFirstChild("UIEvent")
    return uiEventRemote
end

-- the client Gameplay controller table: dribble/shot/afk state + the game's own
-- preloaded AnimationTracks (ctrl.Animations). gc scan is expensive -> off-thread, cached.
local ctrl
local ctrlScanning, ctrlScanAt = false, 0
local function findCtrl()
    if ctrl and rawget(ctrl, "DribbleCooldown") ~= nil then return ctrl end
    pcall(function()
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" and rawget(v, "DribbleCooldown") ~= nil
               and rawget(v, "CrossOverCooldown") ~= nil and rawget(v, "CurrentHand") ~= nil then
                ctrl = v
                break
            end
        end
    end)
    return ctrl
end
local function wantCtrl()   -- non-blocking; full-gc scans are pricey so retry ≤ once per 5s
    if ctrl or ctrlScanning then return ctrl end
    if clock() - ctrlScanAt < 5 then return ctrl end
    ctrlScanAt = clock()
    ctrlScanning = true
    task.spawn(function() findCtrl(); ctrlScanning = false end)
    return ctrl
end

-- prefer the game's own loaded tracks (exact markers/lengths); replicate only as fallback
local trackCache = setmetatable({}, { __mode = "k" })
local function getTrack(name)
    local c = ctrl
    local A = c and rawget(c, "Animations")
    local t = A and A[name]
    if t then return t end
    local _, hum = parts()
    local animator = hum and hum:FindFirstChildWhichIsA("Animator")
    if not animator then return nil end
    local cache = trackCache[animator]
    if not cache then cache = {}; trackCache[animator] = cache end
    if cache[name] then return cache[name] end
    local id = ANIMS[name]
    if not id then return nil end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. id
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if ok and track then cache[name] = track; return track end
    return nil
end

--============================ persistence ============================--
-- calib values are release times in seconds (same files as v1; old contexts stay
-- matchable through the any-context fallback + closest-duration seeding)
local CALIB_FILE = "hoops_autogreen_calib2.json"
local PROF_FILE  = "hoops_autogreen_profiles.json"
local calib, profiles = {}, {}
pcall(function()
    if isfile and isfile(CALIB_FILE) then
        local t = HttpService:JSONDecode(readfile(CALIB_FILE))
        if type(t) == "table" then calib = t end
    end
end)
pcall(function()
    if isfile and isfile(PROF_FILE) then
        local t = HttpService:JSONDecode(readfile(PROF_FILE))
        if type(t) == "table" then profiles = t end
    end
end)
App._calib, App._profiles = calib, profiles
-- shared transport residual (server tick load / route drift), learned only from
-- misses on buckets that already green-locked — geometry lives in the buckets,
-- transport lives here, so lag changes never poison learned green spots
App._resid = tonumber(calib.__resid) or 0
-- server acc->time scale (fraction of meter dur per accuracy unit), refined every
-- time a green lands right after a graded miss; 0.11 measured live on d0.4 meters
App._accScale = tonumber(calib.__accScale) or 0.11
local function saveCalib()
    pcall(function() if writefile then writefile(CALIB_FILE, HttpService:JSONEncode(calib)) end end)
end
-- one-time migration: old time-keyed green spots ("ctx_Name:d0.4", t seconds) fold
-- into fraction-keyed buckets ("ctx_Name", gf = t/dur). Locked entries win the merge,
-- then the tightest window. Old keys leave the file on the first save.
do
    local migrated, changed = {}, false
    for k, c in pairs(calib) do
        if type(c) == "table" and type(c.t) == "number" then
            local dur = tonumber(k:match(":d([%d%.]+)"))
            local base = k:match("^(.-):d[%d%.]+$")
            if dur and dur > 0.1 and base then
                local gf = clamp(c.t / dur, 0.3, 1.3)
                local cand = {
                    gf = gf,
                    flo = clamp((c.lo or dur * 0.55) / dur, 0.3, gf),
                    fhi = clamp((c.hi or dur + 0.1) / dur, gf, 1.4),
                    lock = c.g == 1 or nil, ping = c.ping,
                }
                local ex = migrated[base]
                if not ex or (cand.lock and not ex.lock)
                   or ((cand.lock or false) == (ex.lock or false)
                       and (cand.fhi - cand.flo) < (ex.fhi - ex.flo)) then
                    migrated[base] = cand
                end
            end
            calib[k] = nil
            changed = true
        end
    end
    for base, c in pairs(migrated) do
        if type(calib[base]) ~= "table" or not calib[base].gf then calib[base] = c end
    end
    if changed then saveCalib() end
end
local function saveProfiles()
    pcall(function() if writefile then writefile(PROF_FILE, HttpService:JSONEncode(profiles)) end end)
end

--============================ Ball Magnet + Anti OOB hooks ============================--
-- Lib.Settings is table.freeze()d (verified) -> hookfunction the getters in place.
-- All client ball searches route through these as (court, part, range).
App._ballHooks, App._ballHookCalls, App._ballHookMode = {}, 0, nil
local function installBallHooks(verbose)
    if next(App._ballHooks) then return true end
    local ok, err = pcall(function()
        local Settings = require(ReplicatedStorage.Lib.GlobalModules.Settings)
        local frozen = table.isfrozen and table.isfrozen(Settings)
        App._ballHookMode = frozen and "hookfn" or "swap"
        if frozen and type(hookfunction) ~= "function" then
            error("Settings is frozen and this executor lacks hookfunction")
        end
        local function hookEntry(fn, makeWrapper)
            local target = Settings[fn]
            if type(target) ~= "function" then return end
            if frozen then
                local orig
                orig = hookfunction(target, makeWrapper(function(...) return orig(...) end))
                App._ballHooks[fn] = orig
            else
                App._ballHooks[fn] = target
                Settings[fn] = makeWrapper(target)
            end
        end
        for _, fn in ipairs({ "GetAllBalls", "GetActiveBalls", "GetAlleyBalls", "GetAlleyOrReboundBalls" }) do
            hookEntry(fn, function(orig)
                return function(court, part, range, ...)
                    App._ballHookCalls += 1
                    if App.ballMagnet and type(range) == "number" then range = range * App.reachMult end
                    return orig(court, part, range, ...)
                end
            end)
        end
        hookEntry("GetOobParts", function(orig)
            return function(...)
                if App.antiOob then return {} end
                return orig(...)
            end
        end)
    end)
    local n = 0
    for _ in pairs(App._ballHooks) do n += 1 end
    if verbose or n < 5 then
        print(("[Hoops] Ball/OOB hooks: %d/5 mode=%s%s"):format(
            n, tostring(App._ballHookMode), ok and "" or (" ERR: " .. tostring(err))))
    end
    return n > 0
end

-- The hook alone is NOT enough: both Gameplay call sites CACHE the parts list in an
-- upvalue (`if not u149 then u149 = GetOobParts() end`), so a list grabbed before we
-- loaded keeps working forever. But every check ultimately reads the hit part's "OOB"
-- ATTRIBUTE — clearing those attributes locally (server never sees it) kills the
-- verdict no matter which list the raycast used. Restored exactly on toggle-off.
App._oobCleared = App._oobCleared or {}
local function applyAntiOob(enable)
    local bg = workspace:FindFirstChild("BoundsGroup")
    local n = 0
    if enable then
        if bg then
            for _, p in ipairs(bg:GetDescendants()) do
                if p:IsA("BasePart") and p:GetAttribute("OOB") then
                    p:SetAttribute("OOB", false)
                    App._oobCleared[p] = true
                    n += 1
                end
            end
            -- courts streamed in later ship fresh OOB parts -> scrub those on arrival
            if not App._oobWatch then
                App._oobWatch = bg.DescendantAdded:Connect(function(p)
                    if App.antiOob and p:IsA("BasePart") and p:GetAttribute("OOB") then
                        p:SetAttribute("OOB", false)
                        App._oobCleared[p] = true
                    end
                end)
            end
        end
    else
        if App._oobWatch then App._oobWatch:Disconnect(); App._oobWatch = nil end
        for p in pairs(App._oobCleared) do
            if p.Parent then pcall(function() p:SetAttribute("OOB", true) end) end
            n += 1
        end
        App._oobCleared = {}
    end
    return n
end
App._applyAntiOob = applyAntiOob
App._installBallHooks = installBallHooks
installBallHooks(false)

--============================ Dunk From Anywhere hooks ============================--
-- CanPlayerDunk / CanPlayerPutbackDunk are 2-param locals in Client.Gameplay (source
-- lines 723 / 662), CALLED as upvalues of the controller's Input handler. Prior
-- hook/restore cycles leave function CLONES in gc with identical debug info, so a
-- bare gc scan can grab a dead copy — instead we take the exact objects out of the
-- live Input closure's upvalue slots (upvalues are shared references; a stale Input
-- clone still points at the same live targets). Toggle read live -> install once.
App._dunkTargets, App._dunkOrig = {}, {}
local function resolveDunkFns()
    local found = {}
    local scanned = 0
    for _, f in pairs(getgc(false)) do
        if type(f) == "function" and islclosure and islclosure(f) then
            local ok, info = pcall(debug.getinfo, f)
            if ok and info and type(info.source) == "string"
               and info.source:find("Client.Gameplay", 1, true) and info.name == "Input" then
                scanned += 1
                local upvals
                if type(debug.getupvalues) == "function" then
                    local ok2, t = pcall(debug.getupvalues, f)
                    if ok2 and type(t) == "table" then upvals = t end
                end
                if not upvals then
                    upvals = {}
                    for i = 1, (info.nups or 24) do
                        local ok2, _, uv = pcall(debug.getupvalue, f, i)
                        if not ok2 then break end
                        upvals[i] = uv
                    end
                end
                for _, uv in pairs(upvals) do
                    if type(uv) == "function" then
                        local ok3, ui = pcall(debug.getinfo, uv)
                        if ok3 and ui and ui.numparams == 2 then
                            if ui.name == "CanPlayerDunk" then found.CanPlayerDunk = uv
                            elseif ui.name == "CanPlayerPutbackDunk" then found.CanPlayerPutbackDunk = uv end
                        end
                    end
                end
                if found.CanPlayerDunk and found.CanPlayerPutbackDunk then break end
            end
        end
    end
    -- fallback: old-style direct scan (first name match) if no Input closure carried them
    if not (found.CanPlayerDunk and found.CanPlayerPutbackDunk) then
        for _, f in pairs(getgc(false)) do
            if type(f) == "function" and islclosure and islclosure(f) then
                local ok, info = pcall(debug.getinfo, f)
                if ok and info and type(info.source) == "string"
                   and info.source:find("Client.Gameplay", 1, true) and info.numparams == 2 then
                    if info.name == "CanPlayerDunk" and not found.CanPlayerDunk then found.CanPlayerDunk = f
                    elseif info.name == "CanPlayerPutbackDunk" and not found.CanPlayerPutbackDunk then found.CanPlayerPutbackDunk = f end
                end
            end
        end
    end
    return found, scanned
end

local function installDunkAnywhereHooks()
    if App._dunkOrig.CanPlayerDunk and App._dunkOrig.CanPlayerPutbackDunk then return true end
    if type(hookfunction) ~= "function" then
        print("[Hoops] Dunk-Anywhere unavailable — executor lacks hookfunction")
        return false
    end
    local found, viaInput = resolveDunkFns()
    if found.CanPlayerDunk and not App._dunkOrig.CanPlayerDunk then
        App._dunkTargets.CanPlayerDunk = found.CanPlayerDunk
        App._dunkOrig.CanPlayerDunk = hookfunction(found.CanPlayerDunk, function(plr, c)
            if not App.dunkAnywhere then return App._dunkOrig.CanPlayerDunk(plr, c) end
            local ch = plr and plr.Character
            if not (c and ch and ch.PrimaryPart) then return false end
            if not (c.CurrentHoop and c.CurrentHoop.PrimaryPart) and App._nearestHoopModel then
                c.CurrentHoop = App._nearestHoopModel(ch.PrimaryPart.Position)
            end
            if not (c.CurrentHoop and c.CurrentHoop.PrimaryPart) then return false end
            local mag = (ch.PrimaryPart.Position - c.CurrentHoop.PrimaryPart.Position).Magnitude
            c.CloseDunk   = mag < 5
            c.DunkType    = mag < 13 and "Stand" or "Long"
            c.ForceNoDunk = false
            c.DunkTimer   = 0
            return true
        end)
    end
    if found.CanPlayerPutbackDunk and not App._dunkOrig.CanPlayerPutbackDunk then
        App._dunkTargets.CanPlayerPutbackDunk = found.CanPlayerPutbackDunk
        App._dunkOrig.CanPlayerPutbackDunk = hookfunction(found.CanPlayerPutbackDunk, function(plr, c)
            if not App.dunkAnywhere then return App._dunkOrig.CanPlayerPutbackDunk(plr, c) end
            local ch = plr and plr.Character
            if not (c and ch and ch.PrimaryPart) then return false end
            if not (c.CurrentHoop and c.CurrentHoop.PrimaryPart) and App._nearestHoopModel then
                c.CurrentHoop = App._nearestHoopModel(ch.PrimaryPart.Position)
            end
            if not (c.CurrentHoop and c.CurrentHoop.PrimaryPart) then return false end
            c.CloseDunk = false; c.DunkType = "Long"; c.ForceNoDunk = false
            return true
        end)
    end
    local ok = App._dunkOrig.CanPlayerDunk and App._dunkOrig.CanPlayerPutbackDunk
    print(("[Hoops] Dunk-Anywhere hooks: dunk=%s putback=%s (via %s Input closures)"):format(
        App._dunkOrig.CanPlayerDunk and "OK" or "MISSING",
        App._dunkOrig.CanPlayerPutbackDunk and "OK" or "MISSING",
        tostring(viaInput)))
    return ok
end
App._installDunkHooks = installDunkAnywhereHooks

--============================ Max Skills + Anti Clamp hooks ============================--
local BENEFICIAL_SKILLS = {
    ["High Flyer"]=true, ["Quick Handles"]=true, ["Post Technician"]=true,
    ["Lob City"]=true, ["Flashy Shots"]=true, ["Float Maestro"]=true,
    ["Quick Draw"]=true, ["Pick Dodger"]=true, ["Body Control"]=true,
    ["Blow-by Specialist"]=true, ["Slithery"]=true, ["Snatch Artist"]=true,
    ["Break Starter"]=true, ["Posterizer"]=true, ["Rebounder"]=true,
    ["Chase Down Blocker"]=true, ["Paint Protector"]=true,
}
local DENY_ON_SELF = { ["Quick Draw Big"]=true }   -- overwrites Quick Draw at a slower value
local DENY_ON_OPP  = { ["Brick Wall"]=true, ["Lockdown"]=true }

App._settingsHooks   = App._settingsHooks   or {}
App._settingsTargets = App._settingsTargets or {}
local function installSettingsHooks()
    if App._settingsHooks.HasSkill and App._settingsHooks.Teamcheck then return true end
    if type(hookfunction) ~= "function" then
        print("[Hoops] Settings hooks unavailable — executor lacks hookfunction")
        return false
    end
    local ok, Settings = pcall(require, ReplicatedStorage.Lib.GlobalModules.Settings)
    if not (ok and Settings) then return false end
    if not App._settingsHooks.HasSkill and type(Settings.HasSkill) == "function" then
        App._settingsTargets.HasSkill = Settings.HasSkill
        App._settingsHooks.HasSkill = hookfunction(Settings.HasSkill, function(charOrModel, skillName)
            if not App.hasSkillHook then return App._settingsHooks.HasSkill(charOrModel, skillName) end
            if typeof(charOrModel) == "Instance" and charOrModel:IsA("Model") then
                local isSelf = LocalPlayer.Character and (charOrModel == LocalPlayer.Character)
                if isSelf then
                    if DENY_ON_SELF[skillName] then return nil, 1 end
                    if BENEFICIAL_SKILLS[skillName] then return skillName, 5 end
                else
                    if DENY_ON_OPP[skillName] then return nil, 1 end
                end
            end
            return App._settingsHooks.HasSkill(charOrModel, skillName)
        end)
    end
    if not App._settingsHooks.Teamcheck and type(Settings.Teamcheck) == "function" then
        App._settingsTargets.Teamcheck = Settings.Teamcheck
        App._settingsHooks.Teamcheck = hookfunction(Settings.Teamcheck, function(a, b)
            if App.teamcheck and typeof(a) == "Instance" and typeof(b) == "Instance" then
                local myChar = LocalPlayer.Character
                if myChar and (a == myChar or b == myChar
                               or a.Name == LocalPlayer.Name or b.Name == LocalPlayer.Name) then
                    return true
                end
            end
            return App._settingsHooks.Teamcheck(a, b)
        end)
    end
    print(("[Hoops] Settings hooks: HasSkill=%s Teamcheck=%s"):format(
        App._settingsHooks.HasSkill and "OK" or "MISS",
        App._settingsHooks.Teamcheck and "OK" or "MISS"))
    return App._settingsHooks.HasSkill and App._settingsHooks.Teamcheck
end
App._installSettingsHooks = installSettingsHooks

App._handlesBlocked = 0
local function upvalueAt(f, i)
    -- executors disagree on debug.getupvalue returns: (name, value) or just (value)
    local a, b = debug.getupvalue(f, i)
    if b ~= nil then return b end
    return a
end

local function installHandlesProxy()
    if App._acProxy then return true end
    local A = getActions()
    if not A then return false end
    if not (type(debug) == "table" and type(debug.getupvalue) == "function"
            and type(debug.setupvalue) == "function" and type(getgc) == "function") then
        return false
    end
    local targets, restored = {}, 0
    for _, f in pairs(getgc(false)) do
        if type(f) == "function" and islclosure and islclosure(f) then
            local ok, info = pcall(debug.getinfo, f)
            if ok and info and type(info.source) == "string" and info.source:find("Client.Gameplay", 1, true) then
                for i = 1, (info.nups or 0) do
                    local ok2, v = pcall(upvalueAt, f, i)
                    if ok2 then
                        if v == A then
                            targets[#targets + 1] = { f, i }
                            break
                        elseif type(v) == "table" and rawget(v, "FireServer") ~= nil then
                            -- orphan proxy from a previous instance the executor tore
                            -- down without destroy(): re-point at the remote, then
                            -- claim the slot for the fresh proxy below
                            if pcall(debug.setupvalue, f, i, A) then restored += 1 end
                            targets[#targets + 1] = { f, i }
                            break
                        end
                    end
                end
            end
        end
    end
    if #targets == 0 then return false end
    App._acLog = {}
    local proxy = setmetatable({
        FireServer = function(_, payload, ...)
            local log = App._acLog                 -- 50-entry ring of outgoing actions (diagnostics)
            log[#log + 1] = { t = clock(), a = (type(payload) == "table" and tostring(payload.Action)) or typeof(payload) }
            if #log > 50 then table.remove(log, 1) end
            if App.maxHandles and type(payload) == "table" and payload.Action == "Handles" then
                App._handlesBlocked += 1
                return
            end
            return A:FireServer(payload, ...)
        end
    }, { __index = A })
    local set = 0
    for _, t in ipairs(targets) do
        if pcall(debug.setupvalue, t[1], t[2], proxy) then set += 1 end
    end
    if set == 0 then return false end
    App._acProxy, App._acReal, App._acTargets = proxy, A, targets
    print(("[Hoops] Max Dribble Accuracy proxy installed (%d Gameplay call sites%s)"):format(
        set, restored > 0 and (", " .. restored .. " orphaned slots reclaimed") or ""))
    return true
end

local function installHandlesBlock()
    local viaProxy = installHandlesProxy()
    if not viaProxy and not App._acRetry then
        -- Gameplay closures may not exist yet on very early injection — one late retry
        App._acRetry = true
        task.delay(6, function()
            if App.maxHandles then installHandlesProxy() end
        end)
    end
    if not (App._fsOrig or App._namecallOld) then
        getActions()                               -- warm the actionsRemote cache
        local wrap = (type(newcclosure) == "function") and newcclosure or function(f) return f end
        if type(hookfunction) == "function" then
            pcall(function()
                local target = actionsRemote.FireServer
                local orig
                orig = hookfunction(target, wrap(function(self, ...)
                    if App.maxHandles and self == actionsRemote then
                        local a1 = ...
                        if type(a1) == "table" and a1.Action == "Handles" then
                            App._handlesBlocked += 1
                            return
                        end
                    end
                    return orig(self, ...)
                end))
                App._fsTarget, App._fsOrig = target, orig
            end)
        end
        if type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
            local old
            old = hookmetamethod(game, "__namecall", wrap(function(self, ...)
                if App.maxHandles and self == actionsRemote and getnamecallmethod() == "FireServer" then
                    local a1 = ...
                    if type(a1) == "table" and a1.Action == "Handles" then
                        App._handlesBlocked += 1
                        return
                    end
                end
                return old(self, ...)
            end))
            App._namecallOld = old
        end
    end
    if viaProxy then return true end
    if App._fsOrig or App._namecallOld then
        print("[Hoops] Max Dribble Accuracy: hook layers only (proxy scan found no Gameplay call sites yet — retries shortly). If Acc still drops while dribbling, this executor's hooks are game-transparent.")
        return true
    end
    print("[Hoops] Max Dribble Accuracy unavailable — executor lacks setupvalue and hook functions")
    return false
end
App._installHandlesBlock = installHandlesBlock

-- NO cosmetic pin: the game's own "Dribble Acc" label only shows when the value is
-- BELOW 100, so an honest attribute is the built-in verdict for this experiment —
-- label stays hidden while dribbling = server accuracy truly held at 100 (block
-- works); label appears = server decrements some other way (toggle it off).
-- (A pin here hid the label unconditionally and masked whether the block worked.)
App._handlesConn = LocalPlayer:GetAttributeChangedSignal("Handles"):Connect(function()
    App._handlesServer = LocalPlayer:GetAttribute("Handles")   -- last server-pushed value
end)

--============================ Speed Boosts (BaseValues) ============================--
-- true vanilla (read live before any boost): HandleSpeed 15.8, MoveShotSpeed 7.5,
-- DriftSpeed 4.1, VelForce 3000, DunkForce 10000, AlleyDisBoost 15
App._baseValuesOrig = App._baseValuesOrig or {}
local BASE_VALUE_FIXED = {
    VelForce      = 30000,
    AlleyDisBoost = 60,
    DunkForce     = 30000,
}
local BASE_VALUE_KEYS = { "HandleSpeed", "MoveShotSpeed", "DriftSpeed",
                          "VelForce", "AlleyDisBoost", "DunkForce" }
local function applyBaseValues()
    local ok, BV = pcall(require, ReplicatedStorage.Lib.GlobalModules.BaseValues)
    if not (ok and BV) then return false end
    if next(App._baseValuesOrig) == nil then
        for _, k in ipairs(BASE_VALUE_KEYS) do App._baseValuesOrig[k] = BV[k] end
    end
    pcall(function() setreadonly(BV, false) end)
    if App.baseValuesMod then
        BV.HandleSpeed   = App.bvHandleSpeed or 20
        BV.MoveShotSpeed = App.bvMoveShot    or 12
        BV.DriftSpeed    = App.bvDrift       or 6
        for k, v in pairs(BASE_VALUE_FIXED) do BV[k] = v end
    else
        for k, v in pairs(App._baseValuesOrig) do BV[k] = v end
    end
    return true
end
App._applyBaseValues = applyBaseValues

--============================ stamina / speed base values ============================--
local MAX_STAMINA, SPRINT_SPEED = 95, 20
pcall(function()
    local bv = require(ReplicatedStorage.Lib).BaseValues
    MAX_STAMINA  = bv.MaxStamina or MAX_STAMINA
    SPRINT_SPEED = bv.MaxSpeed or SPRINT_SPEED
end)

--============================ hoops / players helpers ============================--
local hoopRims, hoopModels = {}, {}
do
    local hoops = workspace:FindFirstChild("Hoops")
    if hoops then
        for _, h in ipairs(hoops:GetChildren()) do
            local rf = h:FindFirstChild("Rim")
            local rim = rf and rf:FindFirstChild("Rim")
            if rim and rim:IsA("BasePart") then
                hoopRims[#hoopRims + 1] = rim
                if h:IsA("Model") and h.PrimaryPart then
                    hoopModels[#hoopModels + 1] = { model = h, rim = rim }
                end
            end
        end
    end
end
local FALLBACK_HOOP = V3(-582.4843, 11.7339, 311.0625)
local function nearestHoopModel(pos)
    local best, bestD = nil, math.huge
    for i = 1, #hoopModels do
        local e = hoopModels[i]
        if e.model.Parent and e.model.PrimaryPart then
            local d = (e.rim.Position - pos).Magnitude
            if d < bestD then bestD, best = d, e.model end
        end
    end
    return best
end
local function nearestHoopPos(pos)
    local best, bestD = nil, math.huge
    for i = 1, #hoopRims do
        local r = hoopRims[i]
        if r.Parent then
            local d = (r.Position - pos).Magnitude
            if d < bestD then bestD, best = d, r.Position end
        end
    end
    return best or FALLBACK_HOOP
end
App._nearestHoopModel = nearestHoopModel

local function findClosestPlayer()
    local hrp = parts()
    local wp  = workspace:FindFirstChild("Players")
    if not hrp or not wp then return nil end
    local myPos, myName = hrp.Position, LocalPlayer.Name
    local best, bestD = nil, math.huge
    for _, c in ipairs(wp:GetChildren()) do
        if c.Name ~= myName then
            local ohrp = c:FindFirstChild("HumanoidRootPart")
            if ohrp then
                local d = (ohrp.Position - myPos).Magnitude
                if d < bestD then bestD, best = d, c end
            end
        end
    end
    return best
end

--============================ character arming (event-driven) ============================--
-- one place wires every per-character signal: gate attribute clears, body-mover kills,
-- stagger anim cancels, WalkSpeed enforcement. Replaces the old per-frame scans.
local charConns = {}
local function dropCharConns()
    for _, c in ipairs(charConns) do pcall(function() c:Disconnect() end) end
    charConns = {}
end

local function enforceWalkSpeed(hum, ch)
    if App.walkSpeedLock then
        local target = App.walkSpeedValue or 30
        if hum.WalkSpeed ~= target then hum.WalkSpeed = target end
    elseif App.infStamina and ch and ch:GetAttribute("Running") and hum.WalkSpeed < SPRINT_SPEED then
        hum.WalkSpeed = SPRINT_SPEED
    end
end

local function armCharacter(char)
    dropCharConns()
    task.spawn(function()
        local hrp = char:WaitForChild("HumanoidRootPart", 8)
        local hum = char:WaitForChild("Humanoid", 8)
        if not (hrp and hum) then return end

        -- push/ankle gate attributes: clear the instant the server sets them
        for _, attr in ipairs(PUSH_ATTRS) do
            charConns[#charConns + 1] = char:GetAttributeChangedSignal(attr):Connect(function()
                if App.antiPush and char:GetAttribute(attr) == true then char:SetAttribute(attr, false) end
            end)
        end
        for _, attr in ipairs(ANKLE_ATTRS) do
            charConns[#charConns + 1] = char:GetAttributeChangedSignal(attr):Connect(function()
                if App.antiAnkle and char:GetAttribute(attr) == true then
                    char:SetAttribute(attr, false)
                    if hum.PlatformStand then hum.PlatformStand = false end
                    if hum.Sit then hum.Sit = false end
                end
            end)
        end
        charConns[#charConns + 1] = char:GetAttributeChangedSignal("Tired"):Connect(function()
            if App.infStamina and char:GetAttribute("Tired") ~= false then char:SetAttribute("Tired", false) end
        end)
        charConns[#charConns + 1] = char:GetAttributeChangedSignal("BallCooldown"):Connect(function()
            if (App.ballMagnet or App.dribbleMods) and char:GetAttribute("BallCooldown") == true then
                char:SetAttribute("BallCooldown", false)
            end
        end)

        -- one watcher: shove/stagger body movers (anti push/ankle) + dunk approach
        -- AlignPositions (Instant Dunk Travel)
        charConns[#charConns + 1] = hrp.ChildAdded:Connect(function(inst)
            if inst:IsA("BodyVelocity") or inst:IsA("BodyGyro") then
                local n = inst.Name
                if (App.antiPush and n == "Pushed") or (App.antiAnkle and (n == "Ankles" or n == "Fall")) then
                    task.defer(function() pcall(function() inst:Destroy() end) end)
                end
            elseif App.rimTeleport and inst:IsA("AlignPosition") then
                pcall(function()
                    inst.MaxVelocity    = 500
                    inst.Responsiveness = 200
                end)
            end
        end)

        -- stagger/ankle/poster anims die the frame they start (no per-frame scanning)
        local animator = hum:FindFirstChildWhichIsA("Animator") or hum:WaitForChild("Animator", 5)
        if animator then
            charConns[#charConns + 1] = animator.AnimationPlayed:Connect(function(track)
                local anim = track.Animation
                local id = anim and anim.AnimationId
                if id and ((App.antiPush and PUSH_ANIM_IDS[id]) or (App.antiAnkle and ANKLE_ANIM_IDS[id])) then
                    track:Stop(0)
                end
            end)
        end

        charConns[#charConns + 1] = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            enforceWalkSpeed(hum, char)
        end)
        enforceWalkSpeed(hum, char)

        -- 2026-07 build game bug: its cached dribble-burst mover dies with the old
        -- character and is never recreated (cell non-nil) — repair after each spawn
        task.delay(1.5, function()
            if App._repairDribbleMover then App._repairDribbleMover() end
        end)
    end)
end
App._charAdded = LocalPlayer.CharacterAdded:Connect(armCharacter)
if LocalPlayer.Character then armCharacter(LocalPlayer.Character) end

-- Infinite Stamina architecture — two layers, no fighting the server:
--   1) Zero every entry in BaseValues.StaminaCost (Handles/JabStep/HopStep/Jump/Reach/
--      PostMove/HeavyFall/Pushed). The client stamina gates are all `attr >= cost`, so
--      cost=0 means they pass regardless of what stamina reads — no race between
--      server drain-pushes and our restore, no in-between frames where a gate can fail.
--   2) Keep pinning the Stamina attribute + Tired char attr so the UI meter never
--      dips and any code path we haven't audited still sees MaxStamina.
App._staminaCostOrig = App._staminaCostOrig or nil
local function applyStamina(enable)
    local ok, BV = pcall(require, ReplicatedStorage.Lib.GlobalModules.BaseValues)
    if not (ok and BV and type(BV.StaminaCost) == "table") then return end
    if not App._staminaCostOrig then
        local snap = {}; for k, v in pairs(BV.StaminaCost) do snap[k] = v end
        App._staminaCostOrig = snap
    end
    pcall(function() setreadonly(BV, false) end)
    pcall(function() setreadonly(BV.StaminaCost, false) end)
    if enable then
        for k in pairs(BV.StaminaCost) do BV.StaminaCost[k] = 0 end
    else
        for k, v in pairs(App._staminaCostOrig) do BV.StaminaCost[k] = v end
    end
end
App._applyStamina = applyStamina

App._staminaConn = LocalPlayer:GetAttributeChangedSignal("Stamina"):Connect(function()
    if App.infStamina and LocalPlayer:GetAttribute("Stamina") ~= MAX_STAMINA then
        LocalPlayer:SetAttribute("Stamina", MAX_STAMINA)
    end
end)

--============================ block / steal / intercept (game-mirrored) ============================--
local guarding, lockedChar = false, nil
local guardAtt, guardAO, guardBV = nil, nil, nil
local blockPrevActive, blockCooldown = false, 0
local stealCooldown, interceptCooldown = 0, 0

local controlsModule
local function getControls()
    if controlsModule then return controlsModule end
    local ok, pm = pcall(function() return require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule", 5)) end)
    if ok and pm then controlsModule = pm:GetControls() end
    return controlsModule
end

local function liveVelForce()
    local okBV, BV = pcall(require, ReplicatedStorage.Lib.GlobalModules.BaseValues)
    local f = okBV and BV and tonumber(BV.VelForce) or 3000
    return V3(f, 0, f)
end

local function lungeToward(hrp, target, speed, lifetime, name)
    local vel = target and (target.Position - hrp.Position).Unit * speed or hrp.CFrame.LookVector * speed
    local bv = Instance.new("BodyVelocity")
    bv.Name = name; bv.MaxForce = liveVelForce(); bv.Velocity = vel
    bv.Parent = hrp
    Debris:AddItem(bv, lifetime)
end

-- the game's own block: variant anim by run state + side, BlockBall on the "Block"
-- marker, lunge on the "Force" marker, BlockStart on play
local function doBlock(ball)
    local hrp, hum = parts()
    local a = getActions()
    if not (hrp and hum and a) then return end

    local running = Char and Char:GetAttribute("Running") == true
    local side = "Right"
    if ball then side = (hrp.CFrame:ToObjectSpace(ball.CFrame).X < 0) and "Left" or "Right" end
    local pool  = running and RUN_BLOCKS or STAND_BLOCKS
    local base  = pool[math.random(#pool)]
    local track = getTrack(base .. side) or getTrack(base)
    local lunge = running and 14 or 4
    hum.Jump = true                      -- contest height the same instant

    if not track then
        pcall(function() a:FireServer({ Action = "BlockStart" }) end)
        task.delay(0.16, function() pcall(function() a:FireServer({ Action = "BlockBall" }) end) end)
        return
    end
    local c1, c2
    c1 = track:GetMarkerReachedSignal("Block"):Connect(function()
        c1:Disconnect()
        pcall(function() a:FireServer({ Action = "BlockBall" }) end)
    end)
    c2 = track:GetMarkerReachedSignal("Force"):Connect(function()
        c2:Disconnect()
        lungeToward(hrp, ball, lunge, 0.85, "Block")
    end)
    track:Play(0.3)
    pcall(function() a:FireServer({ Action = "BlockStart" }) end)
    task.delay(0.35, function()
        if c1.Connected then c1:Disconnect(); pcall(function() a:FireServer({ Action = "BlockBall" }) end) end
        if c2.Connected then task.delay(0.5, function() pcall(function() c2:Disconnect() end) end) end
    end)
end

-- the game's Reach: side-picked Reach anim, Actions{Reach} on the "Reach" marker,
-- 10-stud lunge toward the ball (Client.Gameplay line ~2719; 4.2s cooldown mirrored)
local function doSteal(ball)
    local hrp = parts()
    local a = getActions()
    if not (hrp and a) then return end
    local now = clock()
    if now - stealCooldown < 4.2 then return end
    if ctrl and (ctrl.Reaching or ctrl.Intercepting or ctrl.HasBall) then return end
    stealCooldown = now

    local side = "Right"
    if ball then side = (hrp.CFrame:ToObjectSpace(ball.CFrame).X < 0) and "Left" or "Right" end
    local track = getTrack("Reach" .. side)
    if not track then
        pcall(function() a:FireServer({ Action = "Reach" }) end)
        return
    end
    local c1
    c1 = track:GetMarkerReachedSignal("Reach"):Connect(function()
        c1:Disconnect()
        pcall(function() a:FireServer({ Action = "Reach" }) end)
    end)
    track:Play(0.3)
    lungeToward(hrp, ball, 10, 0.5, "Reach")
    task.delay(0.6, function()
        if c1.Connected then c1:Disconnect(); pcall(function() a:FireServer({ Action = "Reach" }) end) end
    end)
end

-- the game's pass pick: InterceptPass anim, Actions{Intercept} on the "Catch" marker
local function doIntercept(ball)
    local hrp = parts()
    local a = getActions()
    if not (hrp and a) then return end
    local now = clock()
    if now - interceptCooldown < 4.2 then return end
    if ctrl and (ctrl.Reaching or ctrl.Intercepting or ctrl.HasBall) then return end
    interceptCooldown = now

    local track = getTrack("InterceptPass")
    if not track then
        pcall(function() a:FireServer({ Action = "Intercept" }) end)
        return
    end
    local c1
    c1 = track:GetMarkerReachedSignal("Catch"):Connect(function()
        c1:Disconnect()
        pcall(function() a:FireServer({ Action = "Intercept" }) end)
    end)
    track:Play(0.3)
    task.delay(0.8, function()
        if c1.Connected then c1:Disconnect(); pcall(function() a:FireServer({ Action = "Intercept" }) end) end
    end)
end

--============================ ball watchers (event-driven) ============================--
-- ActiveShot/Blockable flip the instant a real shot releases (server-authored; pump
-- fakes never flip them). Passing flips while a pass is in flight. All three drive
-- Auto Block / Auto Intercept with zero polling.
App._blockWatch = {}
local function pickBlockTarget(hrp)
    if lockedChar and lockedChar.Parent then return lockedChar.Name end
    local wp = workspace:FindFirstChild("Players")
    if not wp then return nil end
    local myPos, look = hrp.Position, hrp.CFrame.LookVector
    local bestDot, targetName
    for _, c in ipairs(wp:GetChildren()) do
        if c.Name ~= LocalPlayer.Name then
            local ohrp = c:FindFirstChild("HumanoidRootPart")
            if ohrp then
                local d = ohrp.Position - myPos
                if d.Magnitude <= (App.blockRange or 14) + 6 then
                    local dot = look:Dot(d.Unit)
                    if dot > 0.3 and (not bestDot or dot > bestDot) then
                        bestDot, targetName = dot, c.Name
                    end
                end
            end
        end
    end
    return targetName
end

local function watchBall(b)
    if not b:IsA("BasePart") or App._blockWatch[b] then return end

    local function onShotFlip()
        if not App.autoBlock then return end
        -- only contest while actively guarding (G held + target locked)
        if not (guarding and lockedChar and lockedChar.Parent) then return end
        if b:GetAttribute("ActiveShot") ~= true and b:GetAttribute("Blockable") ~= true then return end
        local now = clock()
        if now - blockCooldown < 0.8 then return end
        local hrp = parts()
        if not hrp then return end
        if (b.Position - hrp.Position).Magnitude > (App.blockRange or 14) then return end
        local shooter = b:GetAttribute("LastOwner") or b:GetAttribute("CurrentOwner")
        if shooter == LocalPlayer.Name then return end
        if App.blockOnlyTarget then
            local targetName = pickBlockTarget(hrp)
            if not targetName or shooter ~= targetName then return end
        end
        blockCooldown = now
        doBlock(b)
    end

    local function onPassFlip()
        if not App.autoIntercept then return end
        if b:GetAttribute("Passing") ~= true then return end
        local hrp = parts()
        if not hrp then return end
        if (b.Position - hrp.Position).Magnitude > (App.interceptRange or 30) then return end
        local bTeam, myTeam = b:GetAttribute("Team"), LocalPlayer:GetAttribute("Team")
        if bTeam ~= nil and myTeam ~= nil and bTeam == myTeam then return end
        local owner = b:GetAttribute("LastOwner") or b:GetAttribute("CurrentOwner")
        if owner == LocalPlayer.Name then return end
        doIntercept(b)
    end

    App._blockWatch[b] = {
        b:GetAttributeChangedSignal("ActiveShot"):Connect(onShotFlip),
        b:GetAttributeChangedSignal("Blockable"):Connect(onShotFlip),
        b:GetAttributeChangedSignal("Passing"):Connect(onPassFlip),
    }
end
do
    local balls = workspace:FindFirstChild("Balls")
    if balls then
        for _, b in ipairs(balls:GetDescendants()) do watchBall(b) end
        App._ballWatchAdd = balls.DescendantAdded:Connect(watchBall)
    end
end

-- Auto Steal v3: fires at the "perfect moment" — the peak of a dribble move.
-- A ball cradled in a normal dribble sits ~1.5-2 studs from the handler's body;
-- crossovers/hesis/behind-backs swing it out to 3+ studs. The old code polled every
-- 0.25s and reached the first time the ball was in our range regardless of where
-- it was — you'd swipe air on a cradled ball. We now track exposure (ball → owner
-- HRP horizontal distance) every frame and fire on the RISING EDGE past 2.8 studs
-- (an actual move peak, not idle noise). Fallback: ~2s baseline while target is
-- dribbling but never triggers a peak, so a stationary handler still gets stolen.
local stealTargetBall = nil
local stealPrevExp, stealPrevAt = 0, 0
local stealFallbackAt = 0

local function findTargetBall()
    if stealTargetBall and stealTargetBall.Parent
       and lockedChar and stealTargetBall:GetAttribute("CurrentOwner") == lockedChar.Name then
        return stealTargetBall
    end
    stealTargetBall = nil
    if not lockedChar then return nil end
    local balls = workspace:FindFirstChild("Balls")
    if not balls then return nil end
    local name = lockedChar.Name
    for _, b in ipairs(balls:GetChildren()) do
        local p = b:IsA("BasePart") and b or b:FindFirstChildWhichIsA("BasePart")
        if p and p:GetAttribute("CurrentOwner") == name then
            stealTargetBall = p
            return p
        end
    end
    return nil
end

local function tryReach(ball, hrp)
    if clock() - stealCooldown < 4.2 then return end
    if (ball.Position - hrp.Position).Magnitude > (App.stealRange or 10) then return end
    if Char and Char:GetAttribute("Dribbling") == true then return end
    local bTeam, myTeam = ball:GetAttribute("Team"), LocalPlayer:GetAttribute("Team")
    if bTeam ~= nil and myTeam ~= nil and bTeam == myTeam then return end
    doSteal(ball)
end

local function tickSteal()
    if not (guarding and lockedChar and lockedChar.Parent) then
        stealPrevExp, stealPrevAt = 0, 0; stealTargetBall = nil
        return
    end
    if clock() - stealCooldown < 4.2 then return end
    local hrp = parts()
    if not hrp then return end
    local ball = findTargetBall()
    if not ball then stealPrevExp, stealPrevAt = 0, 0 return end
    local ohrp = lockedChar:FindFirstChild("HumanoidRootPart")
    if not ohrp then return end
    local rel = ball.Position - ohrp.Position
    local exp = math.sqrt(rel.X * rel.X + rel.Z * rel.Z)
    local now = clock()
    local prevExp = stealPrevExp
    -- velocity only counts when last frame gave a sample (fresh); a stale prev from
    -- seconds ago would fake a huge outward speed on reacquire
    local fresh = (now - stealPrevAt) < 0.1
    local vel = fresh and (exp - prevExp) / math.max(now - stealPrevAt, 1e-3) or 0
    stealPrevExp, stealPrevAt = exp, now
    -- PREDICTIVE: ball accelerating outward = crossover/behind-back just committed.
    -- The swipe lands a beat AFTER we trigger (reach anim runs to its "Reach" marker
    -- first), so firing while the ball is still travelling out means the hit arrives
    -- AT peak stretch instead of after the ball is back in the cradle.
    if fresh and exp > 2.2 and vel > 8 then
        tryReach(ball, hrp)
        return
    end
    -- CATCH: rising edge past 2.8 studs — a move peak the velocity path missed
    -- (e.g. it started inside a single dropped frame)
    if exp > 2.8 and prevExp <= 2.8 then
        tryReach(ball, hrp)
        return
    end
    -- fallback: they're just cradling and never triggering a peak — poke every 2s
    -- so a stationary handler still gets stolen
    if lockedChar:GetAttribute("Dribbling") == true and now - stealFallbackAt > 2 then
        stealFallbackAt = now
        tryReach(ball, hrp)
    end
end

--============================ Auto Green engine ============================--
-- The server runs the meter and replicates it as the LocalPlayer "Meter" attribute;
-- "MeterActive" brackets the shot; the client fires StopMeter on key-up. Green means
-- the server judged ShotAcc >= 0.99 when StopMeter ARRIVED -> release leads by net
-- lag, which folds into the per-curve calibrated release TIME.
local shot = nil       -- {t0,pts,bucket,released,scheduled,isDunk,ctx,downAt,floored,dur,gf,corr,relAt,plannedF,liveFit}
local pendingVerdict = nil
local shootDownAt, dunkDownAt = 0, 0
local MIN_HOLD = 0.17  -- game's tap window is 0.15s (TappedShoot) -> under it = pump fake;
                       -- kept 1 frame over it so fast layup meters can green (their spot
                       -- sits just past the tap window; 0.20 floored those releases late)

local function sanitizeCtx(s)
    return (tostring(s):gsub("[^%w%-_]", "_"))
end

-- shot context: the game's OWN speed class (ctrl.ShotType set by getShotType right
-- before StartMeter fires — "Normal"/"Fast"/"SuperFast"; DunkType for Space meters).
-- The SERVER picks meter speed from ShotType, so keying by it (NOT ShotName — that's
-- just the animation, and per-anim keys fragmented layups into dozens of contexts
-- that each demanded their own learning shot) gives one curve family per real meter
-- speed; the :dX.X duration suffix separates any residual variation.
-- Falls back to the old velocity heuristic until the controller is found.
local function shotContext(isDunk)
    local c = ctrl
    if c then
        if isDunk then
            return "dunk_" .. sanitizeCtx(rawget(c, "DunkType") or "Base")
        end
        if rawget(c, "IsHopStep") == true then return "SuperFast" end   -- game overrides at fire time
        local st = rawget(c, "ShotType")
        if st then return sanitizeCtx(st) end
    end
    if isDunk then return "dunk" end
    local hrp, hum = parts()
    local airborne = hum and hum.FloorMaterial == Enum.Material.Air or false
    local moving = false
    if hrp then
        local v = hrp.AssemblyLinearVelocity
        moving = (v.X * v.X + v.Z * v.Z) > 9
    end
    if (moving or airborne) and hrp
       and (nearestHoopPos(hrp.Position) - hrp.Position).Magnitude < 14 then
        return "layup"
    end
    if airborne then return "air" end
    if moving then return "move" end
    return "stand"
end

local function profileValueAt(P, t)
    local pts = P.pts
    if #pts == 0 or t < pts[1][1] then return nil end
    for i = 2, #pts do
        local a, b = pts[i - 1], pts[i]
        if b[1] >= t then
            if b[1] == a[1] then return b[2] end
            return a[2] + (b[2] - a[2]) * (t - a[1]) / (b[1] - a[1])
        end
    end
    return nil
end

-- identify the live meter among learned curves: exact context first, then any curve
-- of the same class (dunk vs shot) as a migration fallback for old saves.
-- Error is averaged over the LAST 3 recorded points, not just the newest one —
-- same-context curves of different speeds (layups run d0.4 AND d0.5 meters) look
-- alike at a single early sample and a cross-match poisons the other bucket's
-- calibration; 3-point slope comparison separates them.
local function curveErr(P, pts, n)
    local total, cnt = 0, 0
    for i = math.max(1, n - 2), n do
        local pv = profileValueAt(P, pts[i][1])
        if pv then total += math.abs(pv - pts[i][2]); cnt += 1 end
    end
    if cnt == 0 then return nil end
    return total / cnt
end

local function matchProfile(pts, ctx, isDunk)
    local n = #pts
    if n < 3 then return nil end
    local prefix = (ctx or "stand") .. ":"
    local best, bestErr, bestAny, bestAnyErr
    for key, P in pairs(profiles) do
        local e = curveErr(P, pts, n)
        if e then
            if key:sub(1, #prefix) == prefix then
                if not bestErr or e < bestErr then bestErr, best = e, key end
            else
                local pDunk = P.dunk == true or key:sub(1, 4) == "dunk"
                if pDunk == (isDunk == true) then
                    if not bestAnyErr or e < bestAnyErr then bestAnyErr, bestAny = e, key end
                end
            end
        end
    end
    if best and bestErr <= 0.06 then return best end
    if bestAny and bestAnyErr <= 0.045 then return bestAny, true end   -- true = migrate me
    return nil
end

-- green-spot calibration in FRACTION space: gf = release point as a fraction of the
-- meter duration; [flo..fhi] = latest-known-early .. earliest-known-late; lock =
-- proven green. Live capture showed the same shot's meter wobbling across the
-- d0.4/d0.5 rounding boundary (395 vs 437ms Moving runs): TIME-keyed spots split
-- learning across buckets, while the FRACTION of the ramp is speed-invariant — so
-- buckets key on shot identity alone and scale by each run's own fitted duration.
local function ensureCalib(bucket)
    local c = calib[bucket]
    if type(c) ~= "table" or not c.gf then
        -- seed priority: same shot identity in another speed class (incl. legacy
        -- suffix-less buckets), then same ShotName anywhere, then the mean of
        -- proven spots, then 0.85 (old "duration minus 60ms" default, fraction-ized)
        local base = bucket:match("^(.-):d[%d%.]+$") or bucket
        local name = base:match("_(.+)$")
        local sibling, sibLock, seed, lockSum, lockN
        for k2, c2 in pairs(calib) do
            if k2 ~= bucket and type(c2) == "table" and c2.gf then
                local base2 = k2:match("^(.-):d[%d%.]+$") or k2
                if base2 == base and (not sibling or (c2.lock and not sibLock)) then
                    sibling, sibLock = c2.gf, c2.lock
                end
                if name and not seed and base2:match("_(.+)$") == name then seed = c2.gf end
                if c2.lock then lockSum = (lockSum or 0) + c2.gf; lockN = (lockN or 0) + 1 end
            end
        end
        c = { gf = clamp(sibling or seed or (lockN and lockSum / lockN) or 0.85, 0.3, 1.3),
              flo = 0.4, fhi = 1.3 }
        calib[bucket] = c
    end
    return c
end

local statusSet = function() end
local function fmtStatus(s)
    pcall(statusSet, s)
    local log = App._statusLog
    if not log then log = {}; App._statusLog = log end
    log[#log + 1] = s
    if #log > 14 then table.remove(log, 1) end
end

-- current round-trip in ms: engine ping (one-way seconds) preferred, the game's own
-- GamePing attribute ("75.9ms" string, already RTT) as fallback
local function pingNowMs()
    local ok, p = pcall(function() return LocalPlayer:GetNetworkPing() end)
    if ok and type(p) == "number" and p > 0 and p < 2 then return p * 2000 end
    local a = LocalPlayer:GetAttribute("GamePing")
    local n = a and tonumber(tostring(a):match("[%d%.]+"))
    if n and n > 0 and n < 2000 then return n end
    return nil
end

-- verdict handler: ShotFeedback arrives on the UIEvent remote the moment the server
-- judges the shot — exact ShotAcc float + Release text, no GUI polling.
local function applyVerdict(s, acc, releaseText)
    if not s.bucket then return end
    local dur = s.dur or 0.4
    local c = ensureCalib(s.bucket)
    local F = s.plannedF or c.gf                   -- fraction of the meter we released at
    if not F then return end
    local green = acc and acc >= 0.99 or false
    local txt = string.lower(tostring(releaseText or ""))
    if green then
        -- green right after a graded near-miss pins the server's acc->fraction
        -- scale exactly: |F_green - F_miss| = (1 - acc_miss) * scale. Learned
        -- globally (EWMA) so every bucket's misses become one-shot corrections.
        local lm = c.lm
        if lm and lm.f and lm.a and lm.a > 0.02 and lm.a < 0.985 then
            local cg = math.abs(F - lm.f) / (1 - lm.a)
            if cg > 0.02 and cg < 0.5 then
                App._accScale = clamp(0.7 * (App._accScale or 0.11) + 0.3 * cg, 0.04, 0.3)
                calib.__accScale = App._accScale
            end
        end
        c.lm = nil
        c.gf = F; c.lock = true
        c.flo = math.max(c.flo or 0.4, F - 0.05); c.fhi = math.min(c.fhi or 1.3, F + 0.05)
        local png = pingNowMs()
        if png then c.ping = png end               -- RTT this spot was proven at
        -- a green proves total timing is right: bleed the shared offset toward 0 so
        -- contest/penalty noise on locked buckets can't ratchet it to the clamp
        App._resid = (App._resid or 0) * 0.9
        calib.__resid = App._resid
        saveCalib()
    elseif c.lock and acc and acc <= 0.05 then
        c.lock = nil; saveCalib()                  -- bands moved (patch?): unlock
    elseif c.lock then
        -- a bucket that already PROVED green is missing: the spot didn't move, the
        -- transport did (server tick load / route change). Train the shared residual
        -- all buckets use instead of unlearning this one.
        local dir = 0
        if txt:find("early", 1, true) then dir = 1
        elseif txt:find("late", 1, true) then dir = -1
        elseif acc and acc >= 0.05 and acc <= 0.985 then dir = 1 end
        if dir == -1 and s.floored then dir = 0 end
        if dir ~= 0 then
            local step = clamp(((acc and (1 - acc)) or 0.3) * dur * (App._accScale or 0.11), 0.003, 0.02)
            App._resid = clamp((App._resid or 0) + 0.35 * dir * step, -0.05, 0.05)
            calib.__resid = App._resid
            saveCalib()
        end
    else
        local dir = 0
        if txt:find("early", 1, true) then dir = 1
        elseif txt:find("late", 1, true) then dir = -1
        elseif acc and acc >= 0.05 and acc <= 0.985 then
            -- directionless band label ("Good" etc): past the green the meter tops out
            -- and judges Late/0%, so any mid percent sits on the EARLY side. Without
            -- this, a banded miss (the stuck "always 64%") never moves the window.
            dir = 1
        end
        if dir == -1 and s.floored then dir = 0 end   -- lateness forced by the pump-fake floor
        if dir ~= 0 then
            if dir == 1 then
                if F >= c.fhi - 0.01 then c.fhi = math.min(1.4, F + 0.25) end
                c.flo = math.max(c.flo, F)
            else
                if F <= c.flo + 0.01 then c.flo = math.max(0.3, F - 0.25) end
                c.fhi = math.min(c.fhi, F)
            end
            if c.fhi - c.flo < 0.02 then
                c.flo = math.max(0.3, F - 0.15); c.fhi = math.min(1.4, F + 0.15)
            end
            -- a graded miss jumps toward the computed green; a wipeout (acc ~ 0)
            -- only says "far" -> binary-midpoint the window. The acc slope is
            -- FAMILY-dependent (~9/unit layups vs ~2/unit moving shots, measured
            -- live) and asymmetric around green, so two graded misses on the SAME
            -- side pin the local slope exactly and the jump is (1-acc)/slope;
            -- until a pair exists, fall back to the global scale.
            local newF
            if acc and acc > 0.02 then
                local step
                local lm = c.lm
                if lm and lm.f and lm.a and lm.d == dir
                   and math.abs(F - lm.f) > 0.004 and acc ~= lm.a then
                    local slope = math.abs((acc - lm.a) / (F - lm.f))
                    if slope > 0.5 and slope < 40 then
                        step = clamp((1 - acc) / slope, 0.006, 0.3)
                    end
                end
                step = step or clamp((1 - acc) * (App._accScale or 0.11), 0.006, 0.2)
                newF = clamp(F + dir * step, c.flo + 0.005, c.fhi - 0.005)
                c.lm = { f = F, a = acc, d = dir }
            else
                newF = clamp((c.flo + c.fhi) / 2, c.flo + 0.005, c.fhi - 0.005)
                c.lm = nil
            end
            c.gf = clamp(newF, 0.3, 1.3)
            local png = pingNowMs()
            if png then c.ping = png end           -- fraction tuned AT this RTT
            saveCalib()
        end
    end
    fmtStatus(string.format("Last: %s %s%% | %s | rel %.3f%s | next %.3f [%.2f..%.2f] d=%dms | adj %+dms | ping %s",
        releaseText or "?", acc and string.format("%.1f", acc * 100) or "?",
        s.bucket, F, s.floored and " FLOOR" or "",
        c.gf, c.flo, c.fhi, math.floor(dur * 1000 + 0.5),
        math.floor((App._resid or 0) * 1000 + 0.5),
        tostring(LocalPlayer:GetAttribute("GamePing") or "?")))
end

-- UIEvent dispatcher: the game routes {eventName, data} through this remote to its UI
-- handlers; "ShotFeedback" data = {Player, ShotAcc, Release, Contest, ShotType, ...}
do
    local ev = getUIEvent()
    if ev then
        App._uiEventConn = ev.OnClientEvent:Connect(function(name, data)
            if name ~= "ShotFeedback" or type(data) ~= "table" then return end
            if data.Player ~= LocalPlayer then return end
            local s = pendingVerdict
            if not s then return end
            pendingVerdict = nil
            applyVerdict(s, tonumber(data.ShotAcc), data.Release)
            if shot == s then shot = nil end
        end)
    else
        print("[Hoops] UIEvent remote missing — verdicts fall back to the shot GUI")
    end
end

-- GUI fallback only if the UIEvent remote was missing (kept from v1, trimmed)
local function watchResultGui(s)
    task.spawn(function()
        local sm = meterGui()
        local info = sm and sm:FindFirstChild("Info")
        local base = sm and sm:FindFirstChild("Base")
        local rel  = info and info:FindFirstChild("Release")
        local pct  = info and info:FindFirstChild("ShotPercent")
        local gbar = base and base:FindFirstChild("GreenBar")
        if not (rel and pct and gbar) then if shot == s then shot = nil end return end
        local deadline = clock() + 4
        while clock() < deadline and rel.Visible do task.wait() end
        while clock() < deadline and not rel.Visible do task.wait() end
        if rel.Visible then
            local acc = tonumber(string.match(pct.Text or "", "[%d%.]+"))
            acc = acc and acc / 100 or nil
            if gbar.Visible and (not acc or acc < 0.99) then acc = 1 end
            applyVerdict(s, acc, rel.Text)
        end
        if shot == s then shot = nil end
    end)
end

local function sendRelease(s)
    local key = s.isDunk and App.dunkKey or App.shootKey
    local released = false
    local c = ctrl
    if c and type(c.InputRelease) == "function" then
        released = pcall(function() c:InputRelease(key, LocalPlayer) end)
    end
    if not released then
        pcall(function() VIM:SendKeyEvent(false, key, false, game) end)
    end
    if App._uiEventConn then
        pendingVerdict = s
        task.delay(4, function()
            if pendingVerdict == s then pendingVerdict = nil end
            if shot == s then shot = nil end
        end)
    else
        watchResultGui(s)
    end
end

local function liveFitDur(pts)
    local rates = {}
    for i = 2, #pts do
        local dt = pts[i][1] - pts[i - 1][1]
        local dv = pts[i][2] - pts[i - 1][2]
        if dt >= 0.025 and dv >= 0.05 then rates[#rates + 1] = dt / dv end
    end
    if #rates < 2 then return nil end
    table.sort(rates)
    return clamp(rates[math.ceil(#rates / 2)] * 0.9, 0.15, 3)
end

local function anchorRel(pts, dur)
    if not dur then return 0 end
    -- ramp runs 0.1 -> 1.0, so "dur" (time of the last step) covers a 0.9 v-range
    local rate = dur / 0.9
    local m = 0
    for i = 1, #pts do
        local a = pts[i][1] - (pts[i][2] - 0.1) * rate
        if a < m then m = a end
    end
    return m
end

local function tickShooting()
    local s = shot
    if not s or s.released then return end
    if s.lastN == #s.pts then return end          -- no new meter step since last pass
    s.lastN = #s.pts
    if s.scheduled then
        -- new samples improve the anchor AND (for live-fit runs) the duration
        -- estimate; the scheduler reads s.relAt live, either direction
        if s.dur and s.gf and s.corr then
            if s.liveFit then
                local d2 = liveFitDur(s.pts)
                if d2 then s.dur = d2 end
            end
            local relAt = s.t0 + s.gf * s.dur + s.corr + anchorRel(s.pts, s.dur)
            local floorAt = s.downAt + MIN_HOLD
            if floorAt > relAt then relAt = floorAt; s.floored = true end
            if math.abs(relAt - s.relAt) > 0.004 then s.relAt = relAt end
        end
        return
    end
    if LocalPlayer:GetAttribute("MeterActive") ~= true then return end
    local key, migrate = matchProfile(s.pts, s.ctx, s.isDunk)
    local curveDur
    if key then
        if migrate or not key:find(":", 1, true) then
            -- matched an old-context or pre-context save: copy it into this context so
            -- nothing learned before is ever relearned
            local suffix = key:match(":(.+)$") or ("d" .. string.format("%.1f", (profiles[key] and profiles[key].dur) or 0.4))
            local nk = (s.ctx or "stand") .. ":" .. suffix
            if not profiles[nk] then
                profiles[nk] = profiles[key]
                profiles[nk].dunk = s.isDunk or nil
                saveProfiles()
            end
            if calib[key] and not calib[nk] then calib[nk] = calib[key]; saveCalib() end
            key = nk
        end
        curveDur = profiles[key] and profiles[key].dur
    else
        -- never-seen meter speed: fit the linear ramp live and shoot THIS run,
        -- seeded from the nearest learned green spot (ensureCalib). The completed
        -- run still records the real profile for next time.
        if #s.pts < 3 then return end             -- give matchProfile first claim
        curveDur = liveFitDur(s.pts)
        if not curveDur then return end
        key = (s.ctx or "stand") .. ":d" .. string.format("%.1f", curveDur)
        s.liveFit = true
    end
    -- green-spot bucket = shot identity + SPEED CLASS (":dX" from the curve key).
    -- Measured live: Moving shots run BOTH a ~400ms and a ~538ms meter with green
    -- fractions ~0.87 vs <0.75 — identity-only buckets made the variants fight,
    -- while the fraction handles within-class duration wobble (400 vs 437ms) and
    -- ensureCalib seeds a fresh class from its sibling class's proven fraction.
    local bucket = key
    if not s.isDunk and s.shotName and s.shotName ~= "" then
        local suffix = key:match(":(.+)$")
        if suffix then bucket = (s.ctx or "stand") .. "_" .. s.shotName .. ":" .. suffix end
    end
    local c = ensureCalib(bucket)
    s.bucket = bucket
    s.dur = curveDur or tonumber(key:match(":d([%d%.]+)")) or 0.4
    s.gf = c.gf
    -- transport corrections, kept OUT of the learned fraction: shared residual +
    -- half the RTT drift since this bucket's spot was last tuned
    local corr = (App._resid or 0) - App.timingOffset
    local png = pingNowMs()
    if png and c.ping then corr += (png - c.ping) / 2000 end
    s.corr = corr
    local relAt = s.t0 + s.gf * s.dur + corr + anchorRel(s.pts, s.dur)
    local floorAt = s.downAt + MIN_HOLD
    if floorAt > relAt then relAt = floorAt; s.floored = true end
    s.scheduled = true
    s.relAt = relAt
    local function fireNow()
        if shot == s and not s.released then
            s.released = true
            -- learn in anchor-relative FRACTION of the meter, transport excluded
            local d = (s.dur and s.dur > 0.05) and s.dur or 0.4
            s.plannedF = (s.relAt - s.t0 - anchorRel(s.pts, d) - (s.corr or 0)) / d
            sendRelease(s)
        end
    end
    local delay = relAt - clock()
    if delay <= 0.002 then
        fireNow()
    else
        -- task.delay alone quantizes the release to whatever Heartbeat follows it
        -- (up to a frame late). Sleep to ~30ms out, frame-step to ~6ms out, then
        -- spin the last few ms — lands on the intended clock tick, and re-reads
        -- s.relAt so a mid-wait re-anchor still shifts the landing.
        task.delay(math.max(0, delay - 0.03), function()
            while shot == s and not s.released do
                if (s.relAt - clock()) <= 0.006 then break end
                RunService.Heartbeat:Wait()
            end
            while shot == s and not s.released and clock() < s.relAt do end
            fireNow()
        end)
    end
end

App._shootDown = UIS.InputBegan:Connect(function(input)
    if input.KeyCode == App.shootKey then shootDownAt = clock()
    elseif input.KeyCode == App.dunkKey then dunkDownAt = clock() end
end)

App._meterStep = LocalPlayer:GetAttributeChangedSignal("Meter"):Connect(function()
    if not App.autoGreen then return end
    local v = LocalPlayer:GetAttribute("Meter")
    if type(v) ~= "number" or v <= 0 then return end
    if LocalPlayer:GetAttribute("MeterActive") ~= true then return end
    local t = clock()
    local s = shot
    if not s then
        local c = wantCtrl()
        local isDunk = UIS:IsKeyDown(App.dunkKey)
            or (c and (rawget(c, "IsDunking") == true or rawget(c, "PutBackDunk") == true)) or false
        local keyDownAt = isDunk and dunkDownAt or shootDownAt
        shot = { t0 = t, pts = { { 0, v } }, released = false, scheduled = false,
                 isDunk = isDunk, ctx = shotContext(isDunk),
                 shotName = (c and not isDunk) and sanitizeCtx(rawget(c, "ShotName") or "") or nil,
                 downAt = (t - keyDownAt < 2) and keyDownAt or t }
    elseif v > s.pts[#s.pts][2] then
        s.pts[#s.pts + 1] = { t - s.t0, v }
    end
end)

App._meterActive = LocalPlayer:GetAttributeChangedSignal("MeterActive"):Connect(function()
    if LocalPlayer:GetAttribute("MeterActive") == true then return end
    local s = shot
    if not (s and not s.released) then return end
    -- meter ended without our release: auto-late, manual release, pump fake, or learning shot
    local pts = s.pts
    local lastT, lastV = 0, 0
    if #pts > 0 then lastT, lastV = pts[#pts][1], pts[#pts][2] end
    if s.scheduled and s.bucket and lastV >= 0.97 then
        -- bar filled and the server auto-shot before our scheduled time: pull fhi in
        local c = ensureCalib(s.bucket)
        local d = (s.dur and s.dur > 0.05) and s.dur or (lastT > 0 and lastT) or 0.4
        local fEnd = clamp(lastT / d, 0.5, 1.4)
        c.fhi = math.min(c.fhi, fEnd - 0.02)
        if c.fhi - c.flo < 0.02 then c.flo = math.max(0.3, c.fhi - 0.3) end
        c.gf = clamp((c.flo + c.fhi) / 2, c.flo + 0.005, c.fhi - 0.005)
        c.lock = nil
        saveCalib()
        fmtStatus(("Auto-late (bar topped at %dms before our release). Next fraction %.3f"):format(
            math.floor(lastT * 1000 + 0.5), c.gf))
    elseif #pts >= 4 and lastV >= 0.9 and not matchProfile(pts, s.ctx, s.isDunk) then
        local key = (s.ctx or "stand") .. ":d" .. string.format("%.1f", lastT)
        profiles[key] = { dur = lastT, pts = pts, dunk = s.isDunk or nil }
        saveProfiles()
        fmtStatus(("Learned %s (%d pts) — next shot of this type gets timed"):format(key, #pts))
    end
    shot = nil
end)

local contestUi = nil          -- {gui, label, hl, lastText, lastColor, lastTarget}
local contestSettingsMod = nil -- memoized Lib.GlobalModules.Settings (false = missing)
local contestLastAt = 0

local function contestKindNow()
    local s, c = shot, ctrl
    if (s and s.isDunk) or (c and (rawget(c, "IsDunking") == true or rawget(c, "PutBackDunk") == true)) then
        return "Dunk"
    end
    -- ShotName is set right before StartMeter and goes stale after the shot, so
    -- it's only trusted while the meter is live; pre-shot = default jumper cone
    if c and LocalPlayer:GetAttribute("MeterActive") == true then
        local sn = tostring(rawget(c, "ShotName") or "")
        if sn:find("Rev") then return "RevLayup" end
        if sn:find("Fade") then return "Fade" end
        if sn:find("Lay") then return "Layup" end
        if sn:find("Mov") then return "Moving" end
    end
    return nil
end

-- mirror of ContestPlrs' reach math (intensity estimate only — patch drift here
-- can only miscolor the label, never flip the open/contested verdict)
local function contestRangeOf(dChar, kind, hoopDist)
    local r = 0
    if dChar:GetAttribute("Guarding") then r += 7
    elseif dChar:GetAttribute("Block") then r += 5.5 end
    if kind == "Fade" or kind == "Moving" then r += 0.5
    elseif kind == "Dunk" then r += 3.4 end
    local gm = ReplicatedStorage:FindFirstChild("GameplayMods")
    if gm and gm:GetAttribute("Enabled") then
        local cmod = gm:FindFirstChild("Contest")
        if cmod and cmod:GetAttribute("Enabled") then
            r = math.max(r + (tonumber(cmod:GetAttribute("Range")) or 0), 0)
        end
    end
    return r + ((hoopDist > 30) and 0.5 or -0.1)
end

local function ensureContestUi()
    if contestUi and contestUi.gui.Parent then return contestUi end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local gui = Instance.new("ScreenGui")
    gui.Name = "HoopsContestUi"
    gui.ResetOnSpawn = false
    gui.AutoLocalize = false
    gui.DisplayOrder = 40
    gui.Enabled = false
    local label = Instance.new("TextLabel")
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Position = UDim2.new(0.5, 0, 0.74, 0)
    label.Size = UDim2.new(0.6, 0, 0, 24)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 19
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.TextStrokeTransparency = 0.1   -- hard outline: the label sits over court/brick art
    label.Text = ""
    label.Parent = gui
    local hl = Instance.new("Highlight")
    hl.FillTransparency = 0.82
    hl.OutlineTransparency = 0.15
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    hl.Parent = gui
    gui.Parent = pg
    contestUi = { gui = gui, label = label, hl = hl }
    App._contestGui = gui
    return contestUi
end

local function contestHide()
    local ui = contestUi
    if ui and ui.gui.Enabled then
        ui.gui.Enabled = false
        ui.hl.Enabled = false
        ui.hl.Adornee = nil
        ui.lastTarget = nil
    end
end

local function contestShow(text, color, target)
    local ui = contestUi
    if not ui then return end
    if text ~= ui.lastText then ui.lastText = text; ui.label.Text = text end
    if color ~= ui.lastColor then
        ui.lastColor = color
        ui.label.TextColor3 = color
        ui.hl.OutlineColor = color
        ui.hl.FillColor = color
    end
    if target ~= ui.lastTarget then
        ui.lastTarget = target
        ui.hl.Adornee = target
        ui.hl.Enabled = target ~= nil
    end
    if not ui.gui.Enabled then ui.gui.Enabled = true end
end

local function tickContest()
    local now = clock()
    if now - contestLastAt < 0.09 then return end
    contestLastAt = now
    local hrp, _, ch = parts()
    if not (hrp and ch) then contestHide() return end
    -- live-verified: Dribbling can be true while HasBall is false, and the glide
    -- handler's holding idiom is Dribbling/ctrl.HoldingBall — accept any of them
    -- (a false positive just shows WIDE OPEN; a false negative kills the feature)
    local holding = ch:GetAttribute("HasBall") == true
        or ch:GetAttribute("Dribbling") == true
        or (ctrl and (rawget(ctrl, "HasBall") == true or rawget(ctrl, "HoldingBall") == true))
        or LocalPlayer:GetAttribute("MeterActive") == true
    if not holding then contestHide() return end
    if contestSettingsMod == nil then
        local ok, m = pcall(require, ReplicatedStorage.Lib.GlobalModules.Settings)
        contestSettingsMod = (ok and type(m) == "table" and type(m.ContestPlrs) == "function") and m or false
        if not contestSettingsMod then
            print("[Hoops] Contest Indicator unavailable — Settings.ContestPlrs not found")
        end
    end
    local S = contestSettingsMod
    if not S then contestHide() return end
    if not ensureContestUi() then return end
    local chm = ctrl and rawget(ctrl, "CurrentHoop")
    local hoopModel = (typeof(chm) == "Instance" and chm) or nearestHoopModel(hrp.Position)
    local hoopPart = hoopModel and hoopModel.PrimaryPart
    if not hoopPart then contestHide() return end
    local kind = contestKindNow()
    local ok, contester = pcall(S.ContestPlrs, LocalPlayer, hoopPart, kind)
    if not ok then contestHide() return end
    if not (contester and contester.Parent) then
        contestShow("WIDE OPEN", Color3.fromRGB(0, 217, 0), nil)
        return
    end
    local dChar = contester.Parent
    local dis = (contester.Position - hrp.Position).Magnitude
    local hoopDist = (hrp.Position - (hoopPart.CFrame * CFrame.new(0, 0, 5)).Position).Magnitude
    local range = contestRangeOf(dChar, kind, hoopDist)
    local closeness = (range > 0.1) and clamp(1 - dis / range, 0, 1) or 1
    local txt, col = "Contested", Color3.fromRGB(255, 170, 0)
    if closeness < 0.05 then
        -- inside reach but at its very edge: ContestLvls would label this "Wide
        -- Open", which contradicts the game's own gate having just said contested
        txt, col = "Slightly Contested", Color3.fromRGB(255, 255, 0)
    else
        pcall(function() txt, col = S.ContestLvls(closeness) end)
    end
    contestShow(string.format("%s — %s (%.1f)", string.upper(txt), dChar.Name, dis), col, dChar)
end

--============================ Auto Guard ============================--
local function ensureConstraints(hrp)
    if not (guardAO and guardAO.Parent and guardAtt and guardAtt.Parent == hrp) then
        if guardAO then pcall(function() guardAO:Destroy() end) end
        if guardAtt then pcall(function() guardAtt:Destroy() end) end
        guardAtt = Instance.new("Attachment"); guardAtt.Parent = hrp
        guardAO = Instance.new("AlignOrientation")
        guardAO.Mode = Enum.OrientationAlignmentMode.OneAttachment
        guardAO.Attachment0 = guardAtt
        guardAO.RigidityEnabled = true
        -- torque/responsiveness only matter when rigidity is OFF (Legit mode's smooth turn)
        guardAO.MaxTorque = 1e5
        guardAO.Responsiveness = 25
        guardAO.Enabled = false
        guardAO.Parent = hrp
    end
    if not (guardBV and guardBV.Parent == hrp) then
        if guardBV then pcall(function() guardBV:Destroy() end) end
        guardBV = Instance.new("BodyVelocity")
        guardBV.MaxForce = ZERO
        guardBV.P = 1e4
        guardBV.Velocity = ZERO
        guardBV.Parent = hrp
    end
end

local function setGuardingStance(on)
    local a = getActions()
    if a then pcall(function() a:FireServer({ Action = "Guarding", Val = on }) end) end
end

local guardHist = {}      -- (t,x,z) ideal-spot samples; Legit mode chases the PAST
local guardMoving = false  -- deadzone hysteresis so Legit doesn't micro-shuffle
local guardMoveDir = nil   -- world-space Humanoid:Move the render-bound writer asserts

local function setGuardMove(dir)
    guardMoveDir = dir
    if dir and not App._guardMoveBound then
        App._guardMoveBound = true
        RunService:BindToRenderStep("HoopsGuardMove", Enum.RenderPriority.Last.Value, function()
            local d = guardMoveDir
            local _, hum = parts()
            if d and hum then hum:Move(d, false) end
        end)
    elseif not dir and App._guardMoveBound then
        App._guardMoveBound = false
        pcall(function() RunService:UnbindFromRenderStep("HoopsGuardMove") end)
        local _, hum = parts()
        if hum then pcall(function() hum:Move(ZERO, false) end) end
    end
end

local function stopGuard()
    if not (guarding or lockedChar or App._guardMoveBound) then return end   -- dispatcher calls this every idle frame
    guarding = false; lockedChar = nil
    if guardAO then guardAO.Enabled = false end
    if guardBV then guardBV.MaxForce = ZERO; guardBV.Velocity = ZERO end
    local c = getControls(); if c then pcall(function() c:Enable() end) end
    local _, hum = parts()
    if hum then hum.AutoRotate = true; hum.PlatformStand = false end
    setGuardMove(nil)
    table.clear(guardHist)
    guardMoving = false
    setGuardingStance(false)
end

local function guardDelayedGoal(now, target)
    guardHist[#guardHist + 1] = { t = now, x = target.X, z = target.Z }
    local react = App.guardReaction or 0.18
    while #guardHist > 2 and guardHist[1].t < now - (react + 0.4) do
        table.remove(guardHist, 1)
    end
    local want = now - react
    for i = #guardHist, 1, -1 do
        local a = guardHist[i]
        if a.t <= want then
            local b = guardHist[i + 1]
            if b and b.t > a.t then
                local f = clamp((want - a.t) / (b.t - a.t), 0, 1)
                return V3(a.x + (b.x - a.x) * f, 0, a.z + (b.z - a.z) * f)
            end
            return V3(a.x, 0, a.z)
        end
    end
    local a = guardHist[1]
    return V3(a.x, 0, a.z)   -- buffer younger than the delay (just locked on): chase oldest
end

local function tickGuard()
    local hrp, hum = parts()
    if not hrp or not hum then return end
    local oc = lockedChar
    local ohrp = oc and oc.Parent and oc:FindFirstChild("HumanoidRootPart")
    if not ohrp then stopGuard(); return end

    local oppPos, myPos = ohrp.Position, hrp.Position
    local toHoop = nearestHoopPos(oppPos) - oppPos
    toHoop = V3(toHoop.X, 0, toHoop.Z)
    toHoop = toHoop.Magnitude < 0.1 and FORWARD or toHoop.Unit
    local target = oppPos + toHoop * App.guardDist

    ensureConstraints(hrp)
    local legit = App.guardMode == "Legit"
    local look = V3(oppPos.X, myPos.Y, oppPos.Z)
    if (look - myPos).Magnitude > 0.05 then
        guardAO.RigidityEnabled = not legit   -- Legit: torque-limited turn, no facing snap
        guardAO.CFrame = lookAt(myPos, look)
        guardAO.Enabled = true
    end
    hum.AutoRotate = false

    if legit then
       
        guardBV.MaxForce = ZERO
        local now = clock()
        local goal = guardDelayedGoal(now, target)
        local side = V3(-toHoop.Z, 0, toHoop.X)
        goal += side * (math.noise(now * 0.55, 7.3) * 1.2)
        local flat = V3(goal.X - myPos.X, 0, goal.Z - myPos.Z)
        local dist = flat.Magnitude
        guardMoving = guardMoving and dist > 0.7 or dist > 1.5
        if guardMoving then
            setGuardMove(flat.Unit * clamp(dist / 3, 0.35, 1))   -- ease in near the spot
        else
            setGuardMove(ZERO)   -- stay bound: asserting zero = standing, writer keeps the frame
        end
    else
       
        guardBV.MaxForce = ZERO
        local flat = V3(target.X - myPos.X, 0, target.Z - myPos.Z)
        local dist = flat.Magnitude
        guardMoving = guardMoving and dist > 0.6 or dist > 1.2
        if guardMoving then
            setGuardMove(flat.Unit * clamp(dist / 2, 0.5, 1))   -- full send far out, ease into the spot
        else
            setGuardMove(ZERO)   -- at the spot: hold, facing the man at guardDist (heavy-contest range)
        end
    end
end


local glideLastAt = 0
local glideCeil = nil                 -- adaptive ceiling; nil = slider value untouched
local glideClean = 0
local function glideSpeedNow()
    local s = App.glideSpeed or 26
    if glideCeil and glideCeil < s then s = glideCeil end
    return math.max(14, s)
end


local function monitorLagback(dir, speedUsed)
    task.spawn(function()
        local hrp = parts()
        if not hrp then return end
        local last = hrp.Position
        local t0 = clock()
        while clock() - t0 < 0.8 do
            local dt = RunService.Heartbeat:Wait()
            local hrp2 = parts()
            if not hrp2 then return end
            local p = hrp2.Position
            local step = p - last
            if step.Magnitude > math.max(3, (dt or 0.016) * 90) and step:Dot(dir) < -0.5 then
                glideCeil = math.max(16, math.floor(speedUsed) - 3)
                glideClean = 0
                print(("[Hoops] Glide lag-back (server snap) — auto-capping glide speed at %d"):format(glideCeil))
                return
            end
            last = p
        end
        glideClean += 1
        if glideCeil and glideClean >= 20 then
            glideCeil += 1; glideClean = 0                -- slow re-probe toward the slider
            if glideCeil >= (App.glideSpeed or 26) then glideCeil = nil end
        end
    end)
end


local repairAt = 0
local function repairDribbleMover()
    if type(debug) ~= "table" or type(debug.setupvalue) ~= "function"
       or type(debug.getupvalue) ~= "function" or type(getgc) ~= "function" then return end
    local now = clock()
    if now - repairAt < 5 then return end
    repairAt = now
    local function slotValue(f, i)
        local a, b = debug.getupvalue(f, i)
        if b ~= nil then return b end
        return a
    end
    local function repairFn(f)
        local ok, info = pcall(debug.getinfo, f)
        if not (ok and info) then return 0 end
        local n = 0
        for i = 1, (info.nups or 0) do
            local ok2, v = pcall(slotValue, f, i)
            if ok2 and typeof(v) == "Instance" and v:IsA("BodyVelocity") and v.Parent == nil then
                if pcall(debug.setupvalue, f, i, nil) then n += 1 end
            end
        end
        return n
    end
    local repaired = 0
    if App._acTargets then
        for _, t in ipairs(App._acTargets) do repaired += repairFn(t[1]) end
    else
        for _, f in pairs(getgc(false)) do
            if type(f) == "function" and islclosure and islclosure(f) then
                local ok, info = pcall(debug.getinfo, f)
                if ok and info and type(info.source) == "string" and info.source:find("Client.Gameplay", 1, true) then
                    repaired += repairFn(f)
                end
            end
        end
    end
    if repaired > 0 then
        print(("[Hoops] Repaired %d dead dribble-mover cache slot(s) — moves displace again"):format(repaired))
    end
end
App._repairDribbleMover = repairDribbleMover

local function glideDir(hrp, hum)
    -- dribble moves briefly zero MoveDirection -> momentum, then facing
    local dir = hum.MoveDirection
    if dir.Magnitude < 0.1 then
        local v = hrp.AssemblyLinearVelocity
        dir = (v.X * v.X + v.Z * v.Z) > 4 and V3(v.X, 0, v.Z) or hrp.CFrame.LookVector
    end
    dir = V3(dir.X, 0, dir.Z)
    if dir.Magnitude < 0.05 then return nil end
    return dir.Unit
end

local function applyGlide(hrp, dir)
    local spd = glideSpeedNow()
    local dist = clamp(App.glideDist or 10, 4, spd * 0.6)
    local bv = Instance.new("BodyVelocity")
    bv.Name = "HopStep"                     -- native profile: same name, same force cap
    bv.MaxForce = liveVelForce()
    bv.Velocity = dir * spd
    bv.Parent = hrp
    Debris:AddItem(bv, dist / spd)
    monitorLagback(dir, spd)
end

local function glidePulse(fromMove)
    local now = clock()
    if now - glideLastAt < (App.glideDelay or 0.35) then return end
    local hrp, hum = parts()
    if not (hrp and hum) then return end
    glideLastAt = now
    if not fromMove then
        local dir = glideDir(hrp, hum)
        if dir then applyGlide(hrp, dir) end
        return
    end
    -- Z/X/C move: RIDE-ONLY. Wait briefly for the game's own burst mover and
    -- rescale it in place — its direction (incl. diagonals the move picked) and
    -- cleanup stay native. If no mover activates the move didn't actually fire (jab
    -- step, cooldown, anim gate, held ball) and we must NOT push: the old fallback
    -- pulse here is what shoved you forward on dribble keys with no dribble anim.
    -- 2026-07 build: the mover is a PERSISTENT BodyVelocity named "Handles" reused
    -- across moves (activation = MaxForce+Velocity set on the "Force" anim marker,
    -- zeroed by the game 0.5-0.6s later) — the old fresh-"HopStep"-child-per-move
    -- never appears anymore, so detect the activation EDGE on either name.
    task.spawn(function()
        local deadline = clock() + 0.35
        local bv
        while clock() < deadline do
            local cand = hrp:FindFirstChild("Handles") or hrp:FindFirstChild("HopStep")
            if cand and cand:IsA("BodyVelocity") and cand.MaxForce.X > 1 and cand.Velocity.Magnitude > 1 then
                bv = cand
                break
            end
            task.wait()
        end
        if not bv then
            glideLastAt = 0                          -- no real move: no push, no throttle burn
            if App._repairDribbleMover then App._repairDribbleMover() end  -- self-heal a dead cached mover
            return
        end
        local spd = glideSpeedNow()
        local v = bv.Velocity
        local flat = V3(v.X, 0, v.Z)
        if flat.Magnitude > 1 then
            local dir = flat.Unit
            if flat.Magnitude < spd then bv.Velocity = dir * spd end
            monitorLagback(dir, spd)
        end
    end)
end

-- The game's camera follows the "CamSub" part (CameraSubject; welded to the Torso,
-- so run-anim lean puts it ~1.5 studs off the spin axis). Spinning the HRP makes it
-- ORBIT at spin speed = violent camera shake, worst while moving. While spinning we
-- counter-write the weld's C0 every frame so CamSub stays pinned above the HRP
-- position (camera steady, body still spins); original C0 restores on disable.
local spinYaw = 0
local spinCam = nil   -- {weld, c0, c1, offY, char}
local function spinCamRig()
    local _, _, ch = parts()
    if not ch then return nil end
    if spinCam and spinCam.char == ch and spinCam.weld.Parent then return spinCam end
    if spinCam then pcall(function() spinCam.weld.C0 = spinCam.c0 end) end
    spinCam = nil
    local cs = ch:FindFirstChild("CamSub")
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not (cs and hrp) then return nil end
    for _, j in ipairs(ch:GetDescendants()) do
        if (j:IsA("Weld") or j:IsA("Motor6D")) and (j.Part1 == cs or j.Part0 == cs) and j.Part1 == cs then
            spinCam = { weld = j, c0 = j.C0, c1 = j.C1, char = ch,
                        offY = cs.Position.Y - hrp.Position.Y }
            return spinCam
        end
    end
    return nil
end

local function tickSpin(dt)
    local hrp, hum = parts()
    if not (hrp and hum) then return end
    if hum.AutoRotate then hum.AutoRotate = false end
    if App.spinMode == "Chaos" then
        -- random facing every frame: no wagon-wheel aliasing at replication rate
        -- (smooth spins past ~1800 deg/s look SLOW to other clients) and no
        -- predictable angular velocity for anything that leads your facing
        spinYaw = math.random() * math.pi * 2
    else
        spinYaw = (spinYaw + math.rad(App.spinSpeed or 720) * (dt or 1/60)) % (math.pi * 2)
    end
    local pos = hrp.Position
    local vLin = hrp.AssemblyLinearVelocity
    hrp.CFrame = CFrame.new(pos) * CFrame.Angles(0, spinYaw, 0)
    hrp.AssemblyLinearVelocity = vLin
    -- pin the camera subject: Part1.CFrame = Part0.CFrame * C0 * C1^-1, so
    -- C0 = Part0^-1 * target * C1 puts CamSub at a fixed, unrotated point above us
    local rig = spinCamRig()
    if rig then
        local p0 = rig.weld.Part0
        if p0 then
            rig.weld.C0 = p0.CFrame:ToObjectSpace(CFrame.new(pos + V3(0, rig.offY, 0))) * rig.c1
        end
    end
end
App._spinStop = function()
    local _, hum = parts()
    if hum then hum.AutoRotate = true end
    spinYaw = 0
    if spinCam then
        pcall(function() spinCam.weld.C0 = spinCam.c0 end)
        spinCam = nil
    end
end

--============================ Anti AFK ============================--
-- the game kicks off ctrl.AfkTimer (os.time, reset in Input) -> pin it; VirtualUser
-- handles the engine's built-in 20-minute idle disconnect
local afkStampAt = 0
local function tickAfk()
    local now = clock()
    if now - afkStampAt < 25 then return end
    afkStampAt = now
    local c = wantCtrl()
    if c then pcall(function() c.AfkTimer = os.time() end) end
end
App._idleConn = LocalPlayer.Idled:Connect(function()
    if not App.antiAfk then return end
    pcall(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.05)
        vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end)

--============================ input handlers ============================--
App._guardBegan = UIS.InputBegan:Connect(function(input, gpe)
    if gpe or not App.autoGuard then return end
    if input.KeyCode == App.guardKey then
        lockedChar = findClosestPlayer()
        if lockedChar then
            guarding = true
            local c = getControls(); if c then pcall(function() c:Disable() end) end
            setGuardingStance(true)
        end
    end
end)
App._guardEnded = UIS.InputEnded:Connect(function(input)
    if input.KeyCode == App.guardKey then stopGuard() end
end)

-- glide auto-trigger on dribble-move keys. NO gpe gate: the game consumes Z/X/C via
-- ContextActionService so gameProcessedEvent is TRUE for them; chat safety comes from
-- GetFocusedTextBox instead.
App._glideKeys = UIS.InputBegan:Connect(function(input)
    if not App.dribbleGlide then return end
    if UIS:GetFocusedTextBox() then return end
    local kc = input.KeyCode
    if kc ~= Enum.KeyCode.Z and kc ~= Enum.KeyCode.X and kc ~= Enum.KeyCode.C then return end
    local _, _, ch = parts()
    local holding = ch and ch:GetAttribute("Dribbling") == true
    if not holding and ctrl then holding = ctrl.HoldingBall == true end
    if holding then glidePulse(true) end
end)

--============================ single dispatcher ============================--
-- ctrl table fields have no change signals -> pin them here (cheap field checks);
-- everything signal-capable was moved off the frame loop
-- NOTE: DribbleWindow is deliberately NOT widened here anymore. It's the combo
-- key-BUFFER: the game collects every Z/X/C pressed within the window into one
-- combo string before executing. Widening it to 0.4 made mashed keys chain into
-- strings that match no move ("ZXCZ") -> the game executed NOTHING for seconds.
local function tickCtrlPins()
    local c = ctrl
    if not c then wantCtrl(); return end
    if c.DribbleCooldown == true then c.DribbleCooldown = false end
    if c.CrossOverCooldown == true then c.CrossOverCooldown = false end
    if c.IsCrossOver == true then c.IsCrossOver = false end
    if type(c.PumpfakeCooldown) == "number" and c.PumpfakeCooldown > 0 then c.PumpfakeCooldown = 0 end
end

-- one-time repair: older versions widened the combo window to 0.4 and it can
-- persist in the loaded settings — put it back at the game's 0.2 default
task.spawn(function()
    local c = findCtrl()
    local st = c and rawget(c, "Settings")
    if type(st) == "table" and type(st.DribbleWindow) == "number" and st.DribbleWindow > 0.25 then
        st.DribbleWindow = 0.2
        print("[Hoops] Dribble combo window restored to 0.2 (0.4 was eating mashed inputs)")
    end
end)

App._conn = RunService.Heartbeat:Connect(function(dt)
    if App.autoGreen then tickShooting() elseif shot then shot = nil end
    if App.contestIndicator then tickContest() end
    -- the game's move/dunk callbacks hard-index ctrl.CurrentHoop.PrimaryPart; it can
    -- be nil off-court (lobby park) and every dribble burst then dies mid-callback
    if ctrl and rawget(ctrl, "CurrentHoop") == nil then
        local hrp = parts()
        if hrp then ctrl.CurrentHoop = nearestHoopModel(hrp.Position) end
    end
    if App.dribbleMods then tickCtrlPins() end
    if App.autoSteal then tickSteal() end
    if App.antiAfk then tickAfk() end
    if App.dribbleGlide and UIS:IsKeyDown(Enum.KeyCode.LeftAlt) then glidePulse(false) end
    if App.spinBot then tickSpin(dt) end
    if guarding then
        if App.autoGuard then tickGuard() else stopGuard() end
    end
end)

--============================ EthosSuite UI ============================--
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/toeerolo-z/ethossuiterewrite/refs/heads/main/ethossuite.lua"))()

local Window = Library:CreateWindow({
    Title = "ZERO HUB",
    Version = "v1.0.0",
})

------------------------------------------------------------
-- CATEGORIES + TABS
------------------------------------------------------------
local CatOffense = Window:AddCategory("OFFENSE")
local CatDefense = Window:AddCategory("DEFENSE")
local CatPlayer  = Window:AddCategory("PLAYER")

local ShootTab  = CatOffense:AddTab("Shooting")
local DefTab    = CatDefense:AddTab("Defense")
local MoveTab   = CatPlayer:AddTab("Movement")
local BallTab   = CatPlayer:AddTab("Ball")

------------------------------------------------------------
-- OFFENSE > SHOOTING
------------------------------------------------------------
local GreenBox = ShootTab:AddGroupbox("Auto Green")

GreenBox:AddToggle("HoopsAutoGreen", {
    Text = "Auto Green (shots + dunks)",
    Default = false,
    Description = "Automatically times your shot release for greens",
    Callback = function(v) App.autoGreen = v end,
})

GreenBox:AddSlider("HoopsTimingOffset", {
    Text = "Timing Adjust (ms, + = earlier)",
    Default = 0, Min = -60, Max = 60, Decimals = 0,
    Description = "Fine-tune release timing in milliseconds",
    Callback = function(v) App.timingOffset = v / 1000 end,
})

GreenBox:AddButton({
    Text = "Reset Shot Learning",
    Func = function()
        for k in pairs(calib) do calib[k] = nil end
        saveCalib()
        fmtStatus("Learning reset")
    end,
})

local AwareBox = ShootTab:AddGroupbox("Awareness")

AwareBox:AddToggle("HoopsContestIndicator", {
    Text = "Contest Indicator",
    Default = false,
    Description = "Shows contest level and closest defender when shooting",
    Callback = function(v)
        App.contestIndicator = v
        if not v then contestHide() end
    end,
})

local DunkBox = ShootTab:AddGroupbox("Dunks")

DunkBox:AddToggle("HoopsDunkAnywhere", {
    Text = "Dunk From Anywhere",
    Default = false,
    Description = "Allows dunking from any distance on the court",
    Callback = function(v)
        App.dunkAnywhere = v
        if v then task.spawn(installDunkAnywhereHooks) end
    end,
})

DunkBox:AddToggle("HoopsRimTeleport", {
    Text = "Instant Dunk Travel",
    Default = false,
    Description = "Speeds up the dunk approach to near-instant",
    Callback = function(v) App.rimTeleport = v end,
})

------------------------------------------------------------
-- DEFENSE > DEFENSE
------------------------------------------------------------
local BlockBox = DefTab:AddGroupbox("Blocking")

BlockBox:AddToggle("HoopsAutoBlock", {
    Text = "Auto Block (while guarding)",
    Default = false,
    Description = "Automatically contests shots while you hold guard",
    Callback = function(v) App.autoBlock = v end,
})

BlockBox:AddToggle("HoopsBlockOnlyTarget", {
    Text = "Only Block My Matchup",
    Default = true,
    Description = "Only auto-blocks the player you are guarding",
    Callback = function(v) App.blockOnlyTarget = v end,
})

BlockBox:AddSlider("HoopsBlockRange", {
    Text = "Block Range",
    Default = 14, Min = 6, Max = 30, Decimals = 0,
    Description = "Maximum distance to attempt a block",
    Callback = function(v) App.blockRange = v end,
})

local GuardBox = DefTab:AddGroupbox("Guarding")

GuardBox:AddToggle("HoopsAutoGuard", {
    Text = "Auto Guard (hold G)",
    Default = false,
    Description = "Locks onto the nearest opponent and tracks them while G is held",
    Callback = function(v) App.autoGuard = v end,
})

GuardBox:AddSlider("HoopsGuardDist", {
    Text = "Guard Distance",
    Default = 5, Min = 3, Max = 10, Decimals = 0,
    Description = "How close to stay to the ball handler",
    Callback = function(v) App.guardDist = v end,
})

GuardBox:AddDropdown("HoopsGuardMode", {
    Text = "Guard Style",
    Values = { "Blatant", "Legit" },
    Default = "Blatant",
    Description = "Blatant snaps to position; Legit uses human-like movement",
    Callback = function(v) App.guardMode = v end,
})

GuardBox:AddSlider("HoopsGuardReact", {
    Text = "Legit Reaction Time (ms)",
    Default = 180, Min = 100, Max = 320, Decimals = 0,
    Description = "How many ms behind the handler Legit mode reacts",
    Callback = function(v) App.guardReaction = v / 1000 end,
})

local TakeBox = DefTab:AddGroupbox("Takeaways")

TakeBox:AddToggle("HoopsAutoSteal", {
    Text = "Auto Steal (while guarding)",
    Default = false,
    Description = "Automatically reaches at the peak of dribble moves",
    Callback = function(v) App.autoSteal = v end,
})

TakeBox:AddSlider("HoopsStealRange", {
    Text = "Steal Range",
    Default = 10, Min = 4, Max = 20, Decimals = 0,
    Description = "Maximum distance to attempt a steal",
    Callback = function(v) App.stealRange = v end,
})

TakeBox:AddToggle("HoopsAutoIntercept", {
    Text = "Auto Intercept Passes",
    Default = false,
    Description = "Automatically intercepts enemy passes in range",
    Callback = function(v) App.autoIntercept = v end,
})

TakeBox:AddSlider("HoopsInterceptRange", {
    Text = "Intercept Range",
    Default = 30, Min = 10, Max = 60, Decimals = 0,
    Description = "Maximum distance to attempt a pass interception",
    Callback = function(v) App.interceptRange = v end,
})

------------------------------------------------------------
-- PLAYER > MOVEMENT
------------------------------------------------------------
local StamBox = MoveTab:AddGroupbox("Movement")

StamBox:AddToggle("HoopsInfStamina", {
    Text = "Infinite Stamina",
    Default = false,
    Description = "Zeroes all stamina costs so you never tire",
    Callback = function(v)
        App.infStamina = v
        task.spawn(applyStamina, v)
        if v then
            if LocalPlayer:GetAttribute("Stamina") ~= MAX_STAMINA then LocalPlayer:SetAttribute("Stamina", MAX_STAMINA) end
            local _, _, ch = parts()
            if ch and ch:GetAttribute("Tired") ~= false then ch:SetAttribute("Tired", false) end
        end
    end,
})

StamBox:AddToggle("HoopsWalkSpeedLock", {
    Text = "Speed Boost",
    Default = false,
    Description = "Locks your run speed to a custom value",
    Callback = function(v)
        App.walkSpeedLock = v
        local _, hum, ch = parts()
        if hum then
            if v then enforceWalkSpeed(hum, ch) else hum.WalkSpeed = 16 end
        end
    end,
})

StamBox:AddSlider("HoopsWalkSpeedValue", {
    Text = "Run Speed",
    Default = 30, Min = 16, Max = 60, Decimals = 0,
    Description = "Walk speed value when Speed Boost is on",
    Callback = function(v)
        App.walkSpeedValue = v
        local _, hum, ch = parts()
        if hum and App.walkSpeedLock then enforceWalkSpeed(hum, ch) end
    end,
})

StamBox:AddDivider()

StamBox:AddToggle("HoopsDribbleGlide", {
    Text = "Dribble Glide (Z/X/C moves)",
    Default = false,
    Description = "Adds speed bursts to dribble moves",
    Callback = function(v) App.dribbleGlide = v end,
})

StamBox:AddSlider("HoopsGlideSpeed", {
    Text = "Glide Speed (safe zone 18-30)",
    Default = 26, Min = 18, Max = 34, Decimals = 0,
    Description = "Speed of the glide burst; too high triggers server lag-back",
    Callback = function(v) App.glideSpeed = v end,
})

StamBox:AddSlider("HoopsGlideDelay", {
    Text = "Glide Delay (ms)",
    Default = 350, Min = 150, Max = 800, Decimals = 0,
    Description = "Minimum time between glide bursts",
    Callback = function(v) App.glideDelay = v / 1000 end,
})

StamBox:AddSlider("HoopsGlideDist", {
    Text = "Glide Distance",
    Default = 10, Min = 4, Max = 20, Decimals = 0,
    Description = "How far each glide burst carries",
    Callback = function(v) App.glideDist = v end,
})

local SpinBox = MoveTab:AddGroupbox("Spin Bot")

SpinBox:AddToggle("HoopsSpinBot", {
    Text = "Spin Bot",
    Default = false,
    Description = "Continuously rotates your character",
    Callback = function(v)
        App.spinBot = v
        if not v and App._spinStop then App._spinStop() end
    end,
})

SpinBox:AddSlider("HoopsSpinSpeed", {
    Text = "Spin Speed (deg/s)",
    Default = 720, Min = 90, Max = 5400, Decimals = 0,
    Description = "Rotation speed in degrees per second",
    Callback = function(v) App.spinSpeed = v end,
})

SpinBox:AddDropdown("HoopsSpinMode", {
    Text = "Spin Mode",
    Values = { "Smooth", "Chaos" },
    Default = "Smooth",
    Description = "Smooth = continuous rotation; Chaos = random facing per frame",
    Callback = function(v) App.spinMode = v end,
})

local ProtBox = MoveTab:AddGroupbox("Protection")

ProtBox:AddToggle("HoopsAntiPush", {
    Text = "Anti Push",
    Default = false,
    Description = "Cancels push stagger animations and body movers",
    Callback = function(v) App.antiPush = v end,
})

ProtBox:AddToggle("HoopsAntiAnkle", {
    Text = "Anti Ankle Break",
    Default = false,
    Description = "Cancels ankle break fall animations",
    Callback = function(v) App.antiAnkle = v end,
})

ProtBox:AddToggle("HoopsAntiAfk", {
    Text = "Anti AFK",
    Default = false,
    Description = "Prevents idle kick by resetting the game's AFK timer",
    Callback = function(v) App.antiAfk = v end,
})

ProtBox:AddToggle("HoopsAntiOob", {
    Text = "Anti Out of Bounds",
    Default = false,
    Description = "Clears OOB attributes so you never get called out of bounds",
    Callback = function(v)
        App.antiOob = v
        if v then installBallHooks(true) end
        task.spawn(applyAntiOob, v)
    end,
})

------------------------------------------------------------
-- PLAYER > BALL
------------------------------------------------------------
local HandleBox = BallTab:AddGroupbox("Handling")

HandleBox:AddToggle("HoopsBallMagnet", {
    Text = "Ball Magnet",
    Default = false,
    Description = "Multiplies ball pickup range",
    Callback = function(v)
        App.ballMagnet = v
        if v then installBallHooks(true) end
    end,
})

HandleBox:AddSlider("HoopsReachMult", {
    Text = "Magnet Strength",
    Default = 4, Min = 1, Max = 15, Decimals = 0,
    Description = "Multiplier applied to ball grab range",
    Callback = function(v) App.reachMult = v end,
})

HandleBox:AddToggle("HoopsDribbleMods", {
    Text = "Fast Dribbles (no cooldowns)",
    Default = false,
    Description = "Removes dribble move cooldowns for instant combos",
    Callback = function(v)
        App.dribbleMods = v
        if v then wantCtrl() end
    end,
})

HandleBox:AddToggle("HoopsMaxHandles", {
    Text = "Max Dribble Accuracy",
    Default = false,
    Description = "Blocks the Handles accuracy penalty report to server",
    Callback = function(v)
        App.maxHandles = v
        if v then task.spawn(installHandlesBlock) end
    end,
})

local BoostBox = BallTab:AddGroupbox("Speed Boosts")

BoostBox:AddToggle("HoopsBaseValues", {
    Text = "Enable Speed Boosts",
    Default = false,
    Description = "Modifies BaseValues for faster dribble, shot, and drift speeds",
    Callback = function(v)
        App.baseValuesMod = v
        task.spawn(applyBaseValues)
    end,
})

BoostBox:AddSlider("HoopsBvHandle", {
    Text = "Dribble Speed (game default 15.8)",
    Default = 20, Min = 16, Max = 26, Decimals = 0,
    Description = "HandleSpeed value; server rubber-bands past ~24",
    Callback = function(v)
        App.bvHandleSpeed = v
        if App.baseValuesMod then task.spawn(applyBaseValues) end
    end,
})

BoostBox:AddSlider("HoopsBvMoveShot", {
    Text = "Moving Shot Speed (game default 7.5)",
    Default = 12, Min = 8, Max = 18, Decimals = 0,
    Description = "MoveShotSpeed value",
    Callback = function(v)
        App.bvMoveShot = v
        if App.baseValuesMod then task.spawn(applyBaseValues) end
    end,
})

BoostBox:AddSlider("HoopsBvDrift", {
    Text = "Drift Speed (game default 4.1)",
    Default = 6, Min = 4, Max = 10, Decimals = 0,
    Description = "DriftSpeed value",
    Callback = function(v)
        App.bvDrift = v
        if App.baseValuesMod then task.spawn(applyBaseValues) end
    end,
})

local MatchBox = BallTab:AddGroupbox("Matchup")

MatchBox:AddToggle("HoopsHasSkill", {
    Text = "Max Skills",
    Default = false,
    Description = "Forces all beneficial skills active on your character",
    Callback = function(v)
        App.hasSkillHook = v
        if v then task.spawn(installSettingsHooks) end
    end,
})

MatchBox:AddToggle("HoopsTeamcheck", {
    Text = "Anti Clamp / Screen",
    Default = false,
    Description = "Bypasses teammate collision checks",
    Callback = function(v)
        App.teamcheck = v
        if v then task.spawn(installSettingsHooks) end
    end,
})

------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------
Library:CreateSettingsTab(Window)

--============================ teardown ============================--
App.destroy = function()
    App.autoGreen, App.infStamina, App.autoGuard, App.antiPush, App.ballMagnet = false, false, false, false, false
    App.dribbleMods, App.dribbleGlide, App.spinBot, App.antiOob = false, false, false, false
    App.dunkAnywhere, App.rimTeleport, App.contestIndicator = false, false, false
    App.hasSkillHook, App.teamcheck = false, false
    App.baseValuesMod, App.walkSpeedLock = false, false
    App.autoSteal, App.autoIntercept, App.antiAfk, App.antiAnkle = false, false, false, false
    if App._spinStop then pcall(App._spinStop) end
    if App._dunkTargets and App._dunkOrig then
        for name, target in pairs(App._dunkTargets) do
            local orig = App._dunkOrig[name]
            if target and orig then pcall(function() hookfunction(target, orig) end) end
        end
    end
    if App._settingsTargets and App._settingsHooks then
        for name, target in pairs(App._settingsTargets) do
            local orig = App._settingsHooks[name]
            if target and orig then pcall(function() hookfunction(target, orig) end) end
        end
    end
    if App._applyStamina then pcall(App._applyStamina, false) end
    if App._applyAntiOob then pcall(App._applyAntiOob, false) end
    if App._baseValuesOrig and next(App._baseValuesOrig) then
        pcall(function()
            local BV = require(ReplicatedStorage.Lib.GlobalModules.BaseValues)
            pcall(function() setreadonly(BV, false) end)
            for k, v in pairs(App._baseValuesOrig) do BV[k] = v end
        end)
    end
    if App._ballHooks then
        pcall(function()
            local Settings = require(ReplicatedStorage.Lib.GlobalModules.Settings)
            for fn, orig in pairs(App._ballHooks) do
                if App._ballHookMode == "hookfn" then
                    pcall(function() hookfunction(Settings[fn], orig) end)
                else
                    Settings[fn] = orig
                end
            end
        end)
    end
    pcall(stopGuard)
    dropCharConns()
    App.maxHandles = false
    if App._acTargets and App._acReal then
        for _, t in ipairs(App._acTargets) do
            pcall(function() debug.setupvalue(t[1], t[2], App._acReal) end)
        end
        App._acTargets, App._acProxy, App._acReal = nil, nil, nil
    end
    if App._fsTarget and App._fsOrig then
        pcall(function() hookfunction(App._fsTarget, App._fsOrig) end)
        App._fsTarget, App._fsOrig = nil, nil
    end
    if App._namecallOld and type(hookmetamethod) == "function" then
        pcall(function() hookmetamethod(game, "__namecall", App._namecallOld) end)
        App._namecallOld = nil
    end
    for _, k in ipairs({ "_conn", "_glideKeys", "_ballWatchAdd", "_guardBegan", "_guardEnded",
                         "_meterStep", "_meterActive", "_shootDown", "_charAdded",
                         "_staminaConn", "_uiEventConn", "_idleConn", "_handlesConn" }) do
        local c = App[k]
        if c then pcall(function() c:Disconnect() end) end
    end
    if App._blockWatch then
        for _, conns in pairs(App._blockWatch) do
            for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        end
        App._blockWatch = {}
    end
    if App._contestGui then pcall(function() App._contestGui:Destroy() end) end
    if guardAO then pcall(function() guardAO:Destroy() end) end
    if guardAtt then pcall(function() guardAtt:Destroy() end) end
    if guardBV then pcall(function() guardBV:Destroy() end) end
    if controlsModule then pcall(function() controlsModule:Enable() end) end
    local _, hum = parts()
    if hum then hum.AutoRotate = true; hum.PlatformStand = false end
    pcall(function() Library:Destroy() end)
end

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Hoops Util v2", Text = "Loaded via Zero Hub. Pick your features.", Duration = 5
    })
end)
print("[Hoops] Utility v2 loaded (EthosSuite)")
