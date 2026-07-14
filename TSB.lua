-- Obfuscator string decoder (still required by a few encrypted lookups below)
L_38 = math.floor;
L_39 = math.random;
L_40 = table.remove;
L_41 = {};
L_42 = string.char;
L_43 = 0;
L_44 = 2;
L_45 = {};
L_46 = {};
L_47 = 256;
L_48 = 1;
L_49 = L_48 < 0;
L_50 = 1 - L_48;
while true do
    L_50 = L_50 + L_48;
    local L_51 = L_50 <= L_47;
    local L_52 = not L_49 and L_51;
    local L_53 = L_50 >= L_47;
    if (not L_49 or not L_53) and not L_52 then
        break;
    end;
    L_41[L_50] = L_50;
end;
L_54 = #L_41 == 0;
repeat
    local L_55 = L_40(L_41, (L_39(1, #L_41)));
    L_46[L_55] = L_42(L_55 - 1);
until #L_41 == 0;
L_56 = {};
L_66 = function(...)
    if #L_56 == 0 then
        L_43 = (L_43 * 69 + 23304973265507) % 35184372088832;
        local L_57 = L_44 ~= 1;
        repeat
            L_44 = L_44 * 154 % 257;
        until L_44 ~= 1;
        local L_58 = L_44 % 32;
        local L_59 = L_38(L_43 / 2 ^ (13 - (L_44 - L_58) / 32)) % 4294967296 / 2 ^ L_58;
        local L_60 = L_38(L_59 % 1 * 4294967296) + L_38(L_59);
        local L_61 = L_60 % 65536;
        local L_62 = (L_60 - L_61) / 65536;
        local L_63 = L_61 % 256;
        local L_64 = (L_61 - L_63) / 256;
        local L_65 = L_62 % 256;
        L_56 = { L_63, L_64, L_65, (L_62 - L_65) / 256 };
    end;
    return table.remove(L_56);
end;
L_67 = {};
L_68 = setmetatable({}, { __index = L_67, __metatable = nil });
L_81 = function(L_69, L_70, ...)
    local L_71 = L_67;
    if not L_71[L_70] then
        L_56 = {};
        local L_72 = L_46;
        L_43 = L_70 % 35184372088832;
        local L_73 = 1;
        L_44 = L_70 % 255 + 2;
        local L_74 = string.len(L_69);
        L_71[L_70] = "";
        local L_75 = 126;
        local L_76 = L_73 < 0;
        local L_77 = 1 - L_73;
        while true do
            L_77 = L_77 + L_73;
            local L_78 = L_77 <= L_74;
            local L_79 = not L_76 and L_78;
            local L_80 = L_77 >= L_74;
            if (not L_76 or not L_80) and not L_79 then
                break;
            end;
            L_75 = (string.byte(L_69, L_77) + L_66() + L_75) % 256;
            L_71[L_70] = L_71[L_70] .. L_72[L_75 + 1];
        end;
    end;
    return L_70;
end;

-- Zero Hub -- native ethossuite build (no WindUI shim, no bundled library)
-- UI loaded the same way gakuran does it.
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/toeerolo-z/ethossuiterewrite/refs/heads/main/ethossuite.lua"))()

------------------------------------------------------------------------
-- NATIVE ADAPTER
-- Maps the exact method names the feature layer calls onto ethossuite's
-- real API. This is NOT WindUI -- every call is a direct passthrough to
-- Library / Window / Category / Tab / Groupbox native methods.
------------------------------------------------------------------------
local ZERO_ICON = "rbxassetid://110986193868731"

local function stripTitle(t)
    t = tostring(t or "")
    t = t:gsub("<[^>]+>", "")        -- drop rich-text <stroke> wrappers
    t = t:gsub("%[NEW%]", ""):gsub("%[REWORKED%]", ""):gsub("%[CHANGED%]", ""):gsub("%[COMING SOON%]", "")
    t = t:gsub("%s+", " ")
    return (t:match("^%s*(.-)%s*$")) or t
end

local flagN = 0
local usedFlags = {}
local function flagFor(label)
    label = tostring(label or ""):gsub("<[^>]+>", ""):gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if label == "" then flagN = flagN + 1; return "ZH_" .. flagN end
    local base, f, i = "ZH_" .. label, "ZH_" .. label, 1
    while usedFlags[f] do i = i + 1; f = base .. "_" .. i end
    usedFlags[f] = true
    return f
end

-- element host: wraps a native Groupbox, exposes the WindUI-style verbs the
-- features call, each forwarding to the native Add* method.
local function ElementHost(getBox, ownerTab)
    local H = { _tab = ownerTab }
    local box
    local function gb() if not box then box = getBox() end return box end

    function H:Toggle(o)
        o = o or {}
        return gb():AddToggle(flagFor(o.Title or "Toggle"), {
            Text = o.Title or "Toggle", Default = o.Value, Callback = o.Callback,
        })
    end
    function H:Slider(o)
        o = o or {}; local v = o.Value or {}
        return gb():AddSlider(flagFor(o.Title or "Slider"), {
            Text = o.Title or "Slider",
            Min = v.Min or 0, Max = v.Max or 100,
            Default = v.Default or v.Min or 0,
            Decimals = v.Decimals or 0, Suffix = o.Suffix or "",
            Callback = o.Callback,
        })
    end
    function H:Dropdown(o)
        o = o or {}
        return gb():AddDropdown(flagFor(o.Title or "Dropdown"), {
            Text = o.Title or "Dropdown", Values = o.Values or {},
            Default = o.Value, Multi = o.Multi, Callback = o.Callback,
        })
    end
    function H:Button(o)
        o = o or {}
        gb():AddButton({ Text = o.Title or "Button", Func = o.Callback })
        return H
    end
    function H:Input(o)
        o = o or {}
        return gb():AddInput(flagFor(o.Title or "Input"), {
            Text = o.Title or "Input", Default = o.Value or "",
            Placeholder = o.Placeholder, Finished = o.Finished, Callback = o.Callback,
        })
    end
    function H:Colorpicker(o)
        o = o or {}
        return gb():AddColorPicker(flagFor((o.Title or "Color") .. "_col"), {
            Text = o.Title or "Color",
            Default = o.Default or Color3.fromRGB(255, 255, 255),
            Callback = o.Callback,
        })
    end
    function H:Keybind(o)
        o = o or {}
        local tgl = gb():AddToggle(flagFor((o.Title or "Keybind") .. "_kb"), {
            Text = o.Title or "Keybind", Default = false,
        })
        if tgl.AddKeybind then
            tgl:AddKeybind({ Key = Enum.KeyCode[o.Value] or Enum.KeyCode.K, Mode = "Toggle", Callback = o.Callback })
        end
        return tgl
    end
    function H:Divider() gb():AddDivider(); return H end
    -- ethossuite has no paragraph; render as a label-ish divider+button-free note
    function H:Paragraph(o)
        o = o or {}
        local b = gb()
        if b.AddTable then
            pcall(function() b:AddTable({ { stripTitle(o.Title), stripTitle(o.Desc) } }) end)
        else
            b:AddDivider()
        end
        return H
    end
    function H:Label(o) return H:Paragraph(o) end
    -- a Section is just another native groupbox on the same tab
    function H:Section(o)
        o = o or {}
        local sBox = ownerTab:AddGroupbox(stripTitle(o.Title or "Section"))
        return ElementHost(function() return sBox end, ownerTab)
    end
    function H:Select() if ownerTab and ownerTab.Select then ownerTab:Select() end end
    return H
end

-- window wrapper: features call Window:Tab / Window:Dialog / Window:SetSize etc.
-- Tabs are routed into real categories by title instead of one flat list.
local TAB_CATEGORY = {
    ["Supa"] = "COMBAT",
    ["Kitty Tech"] = "COMBAT",
    ["Kyoto Combo"] = "COMBAT",
    ["Instant Twisted"] = "COMBAT",
    ["Kiba"] = "COMBAT",
    ["Tech Helper"] = "COMBAT",
    ["Hook Dash [Beta]"] = "DASHES",
    ["Loop Dash"] = "DASHES",
    ["Loop Dash v2"] = "DASHES",
    ["Lethal Dash"] = "DASHES",
    ["M1 Reset"] = "AUTOMATION",
    ["AutoBlock"] = "AUTOMATION",
    ["Auto Counter"] = "AUTOMATION",
    ["HitboxAbuse (PC ONLY)"] = "AUTOMATION",
    ["Animations"] = "MISC",
    ["Utilities"] = "MISC",
    ["Settings"] = "SETTINGS",
    ["Backdash Cancel"] = "COMING SOON",
    ["Comatetive"] = "COMING SOON",
    ["Supa REWORK"] = "COMING SOON",
    ["Wall Extend"] = "COMING SOON",
    ["Uppercut Jump"] = "COMING SOON",
}
local CATEGORY_ORDER = { "COMBAT", "DASHES", "AUTOMATION", "MISC", "SETTINGS", "COMING SOON" }

local function WindowWrap(win)
    local W = { _win = win }
    local cats = {}

    local function getCat(name)
        if not cats[name] then cats[name] = win:AddCategory(name) end
        return cats[name]
    end
    -- pre-create in a fixed order so the sidebar reads cleanly
    for _, name in ipairs(CATEGORY_ORDER) do getCat(name) end

    function W:Tab(o)
        o = o or {}
        local title = stripTitle(o.Title or "Tab")
        local catName = TAB_CATEGORY[title] or "COMBAT"
        local tab = getCat(catName):AddTab(title)
        local host = ElementHost(function() return tab:AddGroupbox("Options") end, tab)
        host._realTab = tab
        if o.Opened and tab.Select then pcall(function() tab:Select() end) end
        return host
    end

    -- native no-op-ish passthroughs (features call these; keep them alive)
    function W:SetSize(s)         if win.SetSize then pcall(function() win:SetSize(s) end) end end
    function W:SetToggleKey(k)    win.ToggleKey = k end
    function W:Tag() end
    function W:CreateTopbarButton() end
    function W:HideBackdrop()     if win.HideBackdrop then pcall(function() win:HideBackdrop() end) end end
    function W:ShowBackdrop()     if win.ShowBackdrop then pcall(function() win:ShowBackdrop() end) end end
    function W:SetMinimized(v)    if win.SetMinimized then pcall(function() win:SetMinimized(v) end) end end
    function W:SetExecutions(n)   if win.SetExecutions then pcall(function() win:SetExecutions(n) end) end end
    function W:Unload()           if win.Unload then pcall(function() win:Unload() end) end end
    function W:AddCategory(name)  return win:AddCategory(name) end
    function W:Dialog(o)
        o = o or {}
        Library:Notify({ Title = o.Title or "Zero Hub", Description = o.Content or "", Duration = 5 })
        local b = o.Buttons
        if b and b[1] and b[1].Callback then task.defer(b[1].Callback) end
    end
    return W
end

-- L_82 = the UI facade the feature layer talks to (Notify / SetTheme / CreateWindow / etc.)
L_82 = {}
function L_82:Notify(o)
    o = o or {}
    Library:Notify({
        Title = o.Title or "Zero Hub",
        Description = o.Content or o.Description or "",
        Duration = o.Duration or 3,
        Type = o.Type or "Info",
    })
end
function L_82:Popup(_, o) L_82:Notify(o) end
function L_82:SetTheme() end
function L_82:GetThemes() return { "Default" } end
function L_82:GetCurrentTheme() return "Default" end
function L_82:OnThemeChange() end
function L_82:SetFont() end
function L_82:CreateWindow(cfg)
    cfg = cfg or {}
    local win = Library:CreateWindow({
        Title = "Zero",                       -- renamed from "Zero Hub v1.0"
        Icon = cfg.Icon or ZERO_ICON,
        Author = cfg.Author,
        Folder = cfg.Folder or "ZeroHub",
    })
    Window = WindowWrap(win)                   -- global, exactly what the features expect
    -- no native CreateSettingsTab: the feature layer has its own Settings tab,
    -- now filed under the SETTINGS category. Two settings tabs was the confusing part.
    return Window
end

L_83 = game:GetService("Players");
L_84 = game:GetService("RunService");
L_85 = game:GetService("TweenService");
L_86 = game:GetService("UserInputService");
L_87 = game:GetService("Workspace");
L_88 = nil;
pcall(function(...)
    L_88 = game:GetService("VirtualInputManager");
    return ;
end);
L_100 = function(L_89, L_90, L_91, L_92, ...)
    local L_93 = L_89;
    local L_94 = L_90;
    local L_95 = L_91;
    local L_96 = L_92;
    pcall(function(...)
        if not L_88 or type(L_88.SendKeyEvent) ~= "function" then
            local L_97 = rawget(_G, "syn");
            if not L_97 or type(L_97.virtual_input) ~= "function" then
                local L_98 = rawget(_G, "VirtualInputManager") or rawget(_G, "virtualinputmanager");
                if not L_98 or type(L_98.SendKeyEvent) ~= "function" then
                    local L_99 = nil;
                    pcall(function(...)
                        L_99 = game:GetService("VirtualUser");
                        return ;
                    end);
                    if not L_99 or type(L_99.SetKeyDown) ~= "function" then
                        return ;
                    end;
                    pcall(function(...)
                        if not L_93 then
                            L_99:SetKeyUp(tostring(L_94));
                        else
                            L_99:SetKeyDown(tostring(L_94));
                        end;
                        return ;
                    end);
                    return ;
                end;
                pcall(function(...)
                    L_98:SendKeyEvent(L_93, L_94, L_95 or false, L_96 or game);
                    return ;
                end);
                return ;
            end;
            pcall(function(...)
                L_97.virtual_input(L_94, L_93);
                return ;
            end);
            return ;
        end;
        L_88:SendKeyEvent(L_93, L_94, L_95 or false, L_96 or game);
        return ;
    end);
    return ;
end;
Instance.new("TextLabel").RichText = true;
if not L_88 or type(L_88.SendKeyEvent) ~= "function" then
    L_88 = L_88 or {};
    L_88.SendKeyEvent = function(L_101, L_102, L_103, L_104, L_105, ...)
        L_100(L_102, L_103, L_104, L_105);
        return ;
    end;
end;
game:GetService("HttpService");
L_106 = L_83.LocalPlayer;
while not L_106 do
    task.wait();
    L_106 = L_83.LocalPlayer;
end;
L_107 = { supaDelay = 0.1, supaSpeed = 1, supaBehindOffset = 5, supaLockPercent = 50, supaRandomMovement = 6, supaBehindEnabled = true, supaV2Delay = 0.1, kakyoDistance = 20, kakyoMoveDuration = 0.15, kakyoStartDelay = 100, kakyoAutoRotateLockTime = 250, supaV2Speed = 1, supaV2RandomAngle = 30, supaV2TeleportDistance = 4, dashclipTargetAnimationId = "10479335397", dashclipEnableDuration = 0.55, dashclipScanInterval = 5, loopDelay = 0.16, loopRadius = 6, loopMinTargetDist = 15, loopMaxHeight = 10, loopSteps = 100, loopDashCount = 6, loopDashInterval = 0.08, loopSettleTime = 0.12, loopSettleHold = 0.6, autoSurfEnabled = false, autoWhirlwindDunkEnabled = false, slideM1Enabled = false, autoDownSlamEnabled = false, autoTwistedEnabled = false, kyotoDelay = 250, m1ResetDistance = 25.5, m1ResetRotation = 65, autoCounterDistance = 13, detectBuffer = 0.02, extraDelay = 0.05, cooldown = 1, underOffset = 3, techHelperDelay = 0.3, techHelperHold = 0.15, techHelperLookUp = true, techHelperLockPercent = 50, lethalDashDelay = 0.1, loopReworkAnimDetectId = "10503381238", loopReworkBlockAnimId = "10471478869" };
L_108 = Enum.KeyCode.K;
L_109 = { ["rbxassetid://10503381238"] = true, ["rbxassetid://13379003796"] = true };
L_110 = { supa = false, supaV2 = false, loop = false, kyoto = false, lethal = false, sideDashEnabled = false, sideDashMobileMode = false, sideDashFakeMobile = false, sideDashDistance = 35, sideDashRange = 2, sideDashCooldown = 1, sideDashShow = true, sideDashDelay = 0.11, sideDashSmoothness = 0.4, sideDashPrediction = 0.3, sideDashSilent = false, sideDashReach = 6.5, sideDashSpeedN = 110, sideDashDuration = 0.15, sideDashTargetColorR = 173, sideDashTargetColorG = 216, sideDashTargetColorB = 230, dashclipEnabled = false, dashclipActive = false, dashclipUnloaded = false, upperGrasp = false, upperGraspCooldown = false, upperGraspSearchRadius = 70, upperGraspTweenTime = 10, upperGraspAfterDelay = 14, upperGraspCooldownSeconds = 50, autoSurf = false, autoWhirlwindDunk = false, slideM1 = false, autoDownSlam = false, autoTwisted = false, autoLockJump = false, autoLockJumpUnloaded = false, autoLockJumpDebounce = false, autoLockJumpBlocked = false, autoLockJumpWaitDetect = 16, autoLockJumpWaitJump = 0, autoLockJumpWaitRemote = 1, autoLockJumpLockDuration = 20, autoLockJumpTargetRadius = 20, autoLockJumpCooldown = 50, autoLockJumpResponsiveness = 600, yoyo = false, yoyoDistanceLimit = 10, yoyoCooldownActive = false, kakyoAutoEnabled = false, kakyoDetected = false, kakyoHeartbeatConn = nil, kakyoDoKyotoRunning = false, kakyoDoKyotoWatcher = nil, mouseDash = false, mouseDashDelay = 500, stretchScreenValue = 100, arrowIndicator = false, speedBoost = false, speedValue = 0.1, sigmaESP = false, sigmaColor = Color3.fromRGB(255, 0, 0), m1Catch = false, hitboxColor = Color3.fromRGB(255, 0, 0), jumpBoost = false, jumpValue = 7.2, gravityValue = 192.6, fovValue = 70, noDashCooldown = false, noFatigue = false, emotesExtraSlots = false, emotesSearchBar = false, loopRework = false, loopReworkUnloaded = false, loopReworkDebounce = false, loopReworkBlocked = false, loopReworkWaitDetect = 1, loopReworkWaitJump = 0, loopReworkWaitRemote = 1, loopReworkLockDuration = 15, loopReworkTargetRadius = 50, loopReworkCooldown = 10, loopReworkResponsiveness = 600, m1Range = 13, m1Hold = 200, m1Pred = 0, autoJump = false, counterESP = false, noStun = false, noSlow = false, stopAnimations = false, onlyTorsoCollisions = false, m1Reset = false, m1Block = false, instantTwisted = false, autoCounter = false, avatarChangerUserId = "", noClip = false, noEndLag = false, espName = false, espHighlight = false, espHRPBox = false, espPlayerCount = false, m2Block = false, vfxColorChanger = "None", fastDash = false, downSlam = false, respawnAtDeath = false, fpsBoost = false, counterToxic = false, showCharacter = false, techHelper = false, dashTimer = false };
L_111 = { m1BlockConnection = nil, sideDashConnections = {} };
L_82:SetTheme("Zero Purple");
L_82:Popup(L_82, {
    Title = "Zero Hub",
    Icon = "lucide:smile",
    Content = "Credits: zero / 74q4 | discord.gg/zerohub",
    Buttons = {
        {
            Title = "Enjoy!",
            Icon = "lucide:heart",
            Variant = "Primary",
            Callback = function(...)
                return ;
            end
        }
    }
});
Window = L_82:CreateWindow({
    Title = "Zero Hub v1.0",
    Icon = "rbxassetid://110986193868731",
    Author = "zero / 74q4",
    Folder = "ZeroHub",
    Size = UDim2.fromOffset(650, 550),
    Theme = "Zero Purple",
    HideSearchBar = false,
    NewElements = true,
    SideBarWidth = 200,
    HidePanelBackground = false,
    Background = "rbxassetid://110986193868731",
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function(...)
            L_82:Notify({ Title = "Zero Hub", Content = "Credits: zero / 74q4 | discord.gg/zerohub", Duration = 3 });
            return ;
        end
    },
});
Window:Tag({ Title = "Zero Hub", Color = Color3.fromHex("#8C50FF") });
Window:CreateTopbarButton("theme-switcher", "geist:logo-discord", function(...)
    local L_134 = "https://discord.gg/zerohub";
    if setclipboard then
        pcall(function(...)
            setclipboard(L_134);
            return ;
        end);
    end;
    L_82:Notify({ Title = "Discord copied!", Content = "Join Zero Hub: discord.gg/zerohub", Icon = "geist:logo-discord", Duration = 3 });
    return ;
end, 990);
Window:CreateTopbarButton("zero-hub-credits", "lucide:heart", function(...)
    local L_135 = "Credits: zero / 74q4 | https://discord.gg/zerohub";
    if setclipboard then
        pcall(function(...)
            setclipboard(L_135);
            return ;
        end);
    end;
    L_82:Notify({ Title = "Zero Hub", Content = "Credits: zero / 74q4", Icon = "lucide:heart", Duration = 3 });
    return ;
end, 990);
L_138 = { SupaTech = Window:Tab({ Title = "Supa ", Icon = "lucide:sword", Opened = true }), SideDash = Window:Tab({ Title = "Hook Dash [Beta]<stroke color=\"#2e7a10\" thickness=\"2\" transparency=\"0.25\" joins=\"miter\">[NEW]</stroke>", Icon = "geist:anchor", Opened = true }), LoopDash = Window:Tab({ Title = "Loop Dash", Icon = "lucide:refresh-ccw-dot", Opened = true }), LoopDashv2 = Window:Tab({ Title = "Loop Dash v2<stroke color=\"#2e7a10\" thickness=\"2\" transparency=\"0.25\" joins=\"miter\">[NEW]</stroke>", Icon = "lucide:refresh-ccw-dot", Opened = true }), KittyTech = Window:Tab({ Title = "Kitty Tech<stroke color=\"#2e7a10\" thickness=\"2\" transparency=\"0.25\" joins=\"miter\">[NEW]</stroke>", Icon = "lucide:cat", Opened = true }), KAKYO = Window:Tab({ Title = "Kyoto Combo<stroke color=\"#021d3b\" thickness=\"2\" transparency=\"0.25\" joins=\"miter\">[REWORKED]</stroke>", Icon = "lucide:step-forward", Opened = true }), LethalDash = Window:Tab({ Title = "Lethal Dash<stroke color=\"#021d3b\" thickness=\"2\" transparency=\"0.25\" joins=\"miter\">[REWORKED]</stroke>", Icon = "geist:arrow-up-down", Opened = true }), M1Reset = Window:Tab({ Title = "M1 Reset<stroke color=\"#021d3b\" thickness=\"2\" transparency=\"0.25\" joins=\"miter\">[CHANGED]</stroke>", Icon = "geist:clock-dashed", Opened = true }), InstantTwisted = Window:Tab({ Title = "Instant Twisted", Icon = "lucide:corner-up-right", Opened = true }), AutoBlock = Window:Tab({ Title = "AutoBlock<stroke color=\"#2e7a10\" thickness=\"2\" transparency=\"0.25\" joins=\"miter\">[NEW]</stroke>", Icon = "lucide:shield", Opened = true }), YOYO = Window:Tab({ Title = "Kiba<stroke color=\"#021d3b\" thickness=\"2\" transparency=\"0.25\" joins=\"miter\">[REWORKED]</stroke>", Icon = "lucide:crosshair", Opened = true }), AutoCounter = Window:Tab({ Title = "Auto Counter<stroke color=\"#021d3b\" thickness=\"2\" transparency=\"0.25\" joins=\"miter\">[REWORKED]</stroke>", Icon = "lucide:shield-user", Opened = true }), HitboxAbuse = Window:Tab({ Title = "HitboxAbuse (PC ONLY)<stroke color=\"#2e7a10\" thickness=\"2\" transparency=\"0.25\" joins=\"miter\">[NEW]</stroke>", Icon = "geist:box", Opened = true }), TechHelper = Window:Tab({ Title = "Tech Helper<stroke color=\"#021d3b\" thickness=\"2\" transparency=\"0.25\" joins=\"miter\">[CHANGED]</stroke>", Icon = "lucide:hand-helping", Opened = true }), Animations = Window:Tab({ Title = "Animations<stroke color=\"#021d3b\" thickness=\"2\" transparency=\"0.25\" joins=\"miter\">[CHANGED]</stroke>", Icon = "lucide:play", Opened = true }), Utilities = Window:Tab({ Title = "Utilities<stroke color=\"#021d3b\" thickness=\"2\" transparency=\"0.25\" joins=\"miter\">[CHANGED]</stroke>", Icon = "lucide:square-plus", Opened = true }), Settings = Window:Tab({ Title = "Settings", Icon = "lucide:settings", Opened = true }), GOG = Window:Tab({ Title = "Backdash Cancel<stroke color=\"#ff7300\" thickness=\"2\" transparency=\"0.50\" joins=\"miter\">[COMING SOON]</stroke>", Icon = "geist:lock-closed", Locked = true, Opened = true }), Mzd1Reset = Window:Tab({ Title = "Comatetive<stroke color=\"#ff7300\" thickness=\"2\" transparency=\"0.50\" joins=\"miter\">[COMING SOON]</stroke>", Icon = "geist:lock-closed", Locked = true, Opened = true }), M1zzqReset = Window:Tab({ Title = "Supa REWORK<stroke color=\"#ff7300\" thickness=\"2\" transparency=\"0.50\" joins=\"miter\">[COMING SOON]</stroke>", Icon = "geist:lock-closed", Locked = true, Opened = true }), M1Rdzqeset = Window:Tab({ Title = "Wall Extend<stroke color=\"#ff7300\" thickness=\"2\" transparency=\"0.50\" joins=\"miter\">[COMING SOON]</stroke>", Icon = "geist:lock-closed", Locked = true, Opened = true }), M1Rsqeset = Window:Tab({ Title = "Uppercut Jump<stroke color=\"#ff7300\" thickness=\"2\" transparency=\"0.50\" joins=\"miter\">[COMING SOON]</stroke>", Icon = "geist:lock-closed", Locked = true, Opened = true }) };
L_138.SupaTech:Select();
Window:Dialog({
    Icon = "rbxassetid://110986193868731",
    Title = "Zero Hub v1.0",
    Content = "Zero Hub for TSB\nCredits: zero / 74q4\nDiscord: discord.gg/zerohub\n\nAll original features included — no key required.",
    Buttons = {
        {
            Title = "Confirm",
            Callback = function(...)
                print("[Zero Hub] Loaded — credits: zero / 74q4 | discord.gg/zerohub");
                return ;
            end
        }
    }
});
L_139 = { None = nil, ["Saitama Death Counter"] = Vector3.new(-64.56, 29.25, 20336.1), Atomic = Vector3.new(1064.54, 131.29, 23007.78), Sky = Vector3.new(373.62, 10343.44, -253.37), Corner = Vector3.new(-154.55, 439.51, -367.67), ["Left Mountain"] = Vector3.new(-17.4, 652.52, -391.01), ["Right Mountain"] = Vector3.new(776.64, 677.12, 99.28), ["Middle Mountain"] = Vector3.new(370.56, 628.29, -505.2), ["Middle of Map"] = Vector3.new(129.66, 440.75, -42.03), ["Base Plate"] = Vector3.new(1065.75, 20.63, 23041.6) };
L_140 = { playerAddedConn = nil, characterAddedConns = {}, npcChildAddedConns = {}, destroyingConn = nil };
onlyTorsoCollisionsConnections = L_140;
setOnlyTorsoCollisions = function(L_141, ...)
    if L_110.onlyTorsoCollisions then
        if L_141 and L_141.Parent then
            local L_142 = { ipairs(L_141:GetDescendants()) };
            local L_143 = L_142[1];
            local L_144 = L_142[2];
            local L_145 = L_142[3];
            while true do
                local L_146;
                L_145, L_146 = L_143(L_144, L_145);
                if not L_145 then
                    break;
                end;
                if L_146:IsA("BasePart") then
                    local L_147 = string.find(string.lower(L_146.Name), "torso");
                    isTorso = L_147;
                    if not isTorso then
                        L_146.CanCollide = false;
                    else
                        L_146.CanCollide = true;
                    end;
                end;
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
handleNewCharacter = function(L_148, ...)
    local L_149 = L_148;
    if L_149 then
        if L_149:FindFirstChild("HumanoidRootPart") or L_149:FindFirstChild("Torso") then
            setOnlyTorsoCollisions(L_149);
            local L_152 = L_149.DescendantAdded:Connect(function(L_150, ...)
                if L_110.onlyTorsoCollisions and L_150:IsA("BasePart") then
                    local L_151 = string.find(string.lower(L_150.Name), "torso");
                    isTorso = L_151;
                    L_150.CanCollide = isTorso and true or false;
                end;
                return ;
            end);
            charConn = L_152;
            onlyTorsoCollisionsConnections.characterAddedConns[L_149] = charConn;
            L_149.AncestryChanged:Connect(function(L_153, L_154, ...)
                if not L_154 then
                    local L_155 = onlyTorsoCollisionsConnections.characterAddedConns[L_149];
                    conn = L_155;
                    if conn then
                        pcall(function(...)
                            conn:Disconnect();
                            return ;
                        end);
                    end;
                    onlyTorsoCollisionsConnections.characterAddedConns[L_149] = nil;
                end;
                return ;
            end);
            return ;
        end;
        return ;
    end;
    return ;
end;
handleNPCs = function(...)
    local L_156 = { ipairs(L_87:GetDescendants()) };
    local L_157 = L_156[2];
    local L_158 = L_156[3];
    local L_159 = L_156[1];
    while true do
        local L_160;
        L_158, L_160 = L_159(L_157, L_158);
        if not L_158 then
            break;
        end;
        local L_161 = L_160;
        if L_161:IsA("Model") and L_161.Name == "Weakest Dummy" then
            setOnlyTorsoCollisions(L_161);
            local L_164 = L_161.DescendantAdded:Connect(function(L_162, ...)
                if L_110.onlyTorsoCollisions and L_162:IsA("BasePart") then
                    local L_163 = string.find(string.lower(L_162.Name), "torso");
                    isTorso = L_163;
                    L_162.CanCollide = isTorso and true or false;
                end;
                return ;
            end);
            npcConn = L_164;
            onlyTorsoCollisionsConnections.npcChildAddedConns[L_161] = npcConn;
            L_161.AncestryChanged:Connect(function(L_165, L_166, ...)
                if not L_166 then
                    local L_167 = onlyTorsoCollisionsConnections.npcChildAddedConns[L_161];
                    conn2 = L_167;
                    if conn2 then
                        pcall(function(...)
                            conn2:Disconnect();
                            return ;
                        end);
                    end;
                    onlyTorsoCollisionsConnections.npcChildAddedConns[L_161] = nil;
                end;
                return ;
            end);
        end;
    end;
    return ;
end;
setupOnlyTorsoCollisions = function(...)
    if onlyTorsoCollisionsConnections.playerAddedConn then
        pcall(function(...)
            onlyTorsoCollisionsConnections.playerAddedConn:Disconnect();
            return ;
        end);
        onlyTorsoCollisionsConnections.playerAddedConn = nil;
    end;
    if onlyTorsoCollisionsConnections.destroyingConn then
        pcall(function(...)
            onlyTorsoCollisionsConnections.destroyingConn:Disconnect();
            return ;
        end);
        onlyTorsoCollisionsConnections.destroyingConn = nil;
    end;
    local L_168 = { pairs(onlyTorsoCollisionsConnections.characterAddedConns) };
    local L_169 = L_168[3];
    local L_170 = L_168[2];
    local L_171 = L_168[1];
    while true do
        local L_172;
        L_169, L_172 = L_171(L_170, L_169);
        if not L_169 then
            break;
        end;
        local L_173 = L_172;
        if L_173 then
            pcall(function(...)
                L_173:Disconnect();
                return ;
            end);
        end;
    end;
    onlyTorsoCollisionsConnections.characterAddedConns = {};
    local L_174 = { pairs(onlyTorsoCollisionsConnections.npcChildAddedConns) };
    local L_175 = L_174[1];
    local L_176 = L_174[2];
    local L_177 = L_174[3];
    while true do
        local L_178;
        L_177, L_178 = L_175(L_176, L_177);
        if not L_177 then
            break;
        end;
        local L_179 = L_178;
        if L_179 then
            pcall(function(...)
                L_179:Disconnect();
                return ;
            end);
        end;
    end;
    onlyTorsoCollisionsConnections.npcChildAddedConns = {};
    if L_110.onlyTorsoCollisions then
        onlyTorsoCollisionsConnections.playerAddedConn = L_83.PlayerAdded:Connect(function(L_180, ...)
            local L_181 = L_180;
            if L_180 then
                L_181 = L_180.Character;
            end;
            if L_181 then
                handleNewCharacter(L_180.Character);
            end;
            if L_180 then
                L_180.CharacterAdded:Connect(handleNewCharacter);
            end;
            return ;
        end);
        local L_182 = { ipairs(L_83:GetPlayers()) };
        local L_183 = L_182[2];
        local L_184 = L_182[3];
        local L_185 = L_182[1];
        while true do
            local L_186;
            L_184, L_186 = L_185(L_183, L_184);
            if not L_184 then
                break;
            end;
            if L_186 ~= L_106 then
                if L_186.Character then
                    handleNewCharacter(L_186.Character);
                end;
                L_186.CharacterAdded:Connect(handleNewCharacter);
            end;
        end;
        handleNPCs();
        return ;
    end;
    return ;
end;
sigmaActive = false;
sigmaConnections = {};
SigmaCreateHighlight = function(L_187, ...)
    if L_187 then
        local L_188 = { pairs(L_87:GetChildren()) };
        local L_189 = L_188[1];
        local L_190 = L_188[2];
        local L_191 = L_188[3];
        while true do
            local L_192;
            L_191, L_192 = L_189(L_190, L_191);
            if not L_191 then
                break;
            end;
            if L_192:IsA("Highlight") and L_192.Adornee == L_187 then
                L_192:Destroy();
            end;
        end;
        local L_193 = Instance.new("Highlight");
        highlight = L_193;
        highlight.Adornee = L_187;
        highlight.FillColor = L_110.sigmaColor;
        highlight.OutlineColor = L_110.sigmaColor;
        highlight.FillTransparency = 0.2;
        highlight.OutlineTransparency = 0;
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop;
        highlight.Parent = L_87;
        task.delay(3, function(...)
            if highlight and highlight.Parent then
                highlight:Destroy();
            end;
            return ;
        end);
        return ;
    end;
    return ;
end;
SigmaHookAllPlayers = function(...)
    local L_194 = { pairs(sigmaConnections) };
    local L_195 = L_194[2];
    local L_196 = L_194[1];
    local L_197 = L_194[3];
    while true do
        local L_198;
        L_197, L_198 = L_196(L_195, L_197);
        if not L_197 then
            break;
        end;
        L_198:Disconnect();
    end;
    sigmaConnections = {};
    if sigmaActive then
        local L_199 = { pairs(L_83:GetPlayers()) };
        local L_200 = L_199[1];
        local L_201 = L_199[3];
        local L_202 = L_199[2];
        while true do
            local L_203;
            L_201, L_203 = L_200(L_202, L_201);
            if not L_201 then
                break;
            end;
            if L_203.Character then
                SigmaHookCharacter(L_203.Character);
            end;
            local L_205 = L_203.CharacterAdded:Connect(function(L_204, ...)
                task.wait(1);
                SigmaHookCharacter(L_204);
                return ;
            end);
            table.insert(sigmaConnections, L_205);
        end;
        return ;
    end;
    return ;
end;
SigmaHookCharacter = function(L_206, ...)
    local L_207 = L_206;
    if L_207 then
        local L_208 = L_207:WaitForChild("Humanoid", 2);
        if L_208 then
            local L_211 = L_208.AnimationPlayed:Connect(function(L_209, ...)
                if sigmaActive then
                    local L_210 = tostring(L_209.Animation.AnimationId):match("%d+");
                    if L_210 then
                        L_210 = L_210 == "12351854556" or (L_210 == "15311685628" or (L_210 == "78521642007560" or (L_210 == "69696969696969696" or (L_210 == "13380567856786255751" or L_210 == "134775786876786767678406437626"))));
                    end;
                    if L_210 then
                        SigmaCreateHighlight(L_207);
                    end;
                    return ;
                end;
                return ;
            end);
            table.insert(sigmaConnections, L_211);
            return ;
        end;
        return ;
    end;
    return ;
end;
SigmaToggle = function(L_212, ...)
    sigmaActive = L_212;
    L_110.sigmaESP = L_212;
    if not L_212 then
        local L_213 = { pairs(L_87:GetChildren()) };
        local L_214 = L_213[1];
        local L_215 = L_213[3];
        local L_216 = L_213[2];
        while true do
            local L_217;
            L_215, L_217 = L_214(L_216, L_215);
            if not L_215 then
                break;
            end;
            if L_217:IsA("Highlight") then
                L_217:Destroy();
            end;
        end;
        local L_218 = { pairs(sigmaConnections) };
        local L_219 = L_218[2];
        local L_220 = L_218[3];
        local L_221 = L_218[1];
        while true do
            local L_222;
            L_220, L_222 = L_221(L_219, L_220);
            if not L_220 then
                break;
            end;
            L_222:Disconnect();
        end;
        sigmaConnections = {};
    else
        task.wait(0.5);
        SigmaHookAllPlayers();
    end;
    return ;
end;
SigmaTest = function(...)
    if L_106.Character then
        SigmaCreateHighlight(L_106.Character);
    end;
    return ;
end;
if L_110.sigmaESP then
    task.wait(3);
    SigmaToggle(true);
end;
hookDashAddHighlight = function(L_223, ...)
    if L_223 then
        pcall(function(...)
            if L_111.hookDashHighlight then
                L_111.hookDashHighlight:Destroy();
                L_111.hookDashHighlight = nil;
            end;
            return ;
        end);
        local L_224 = Instance.new("Highlight");
        L_224.Name = "HookDashHighlight";
        L_224.FillTransparency = 0.8;
        L_224.OutlineTransparency = 0.3;
        L_224.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop;
        if hookDashColor then
            pcall(function(...)
                L_224.OutlineColor = hookDashColor;
                L_224.FillColor = hookDashColor;
                return ;
            end);
        end;
        if typeof(L_223) ~= "Instance" or not L_223:IsA("Player") then
            if typeof(L_223) ~= "Instance" or not L_223:IsA("Model") then
                L_224.Parent = L_87;
            else
                L_224.Adornee = L_223;
                L_224.Parent = L_223;
            end;
        elseif not L_223.Character then
            L_224.Parent = L_87;
        else
            L_224.Adornee = L_223.Character;
            L_224.Parent = L_223.Character;
        end;
        L_111.hookDashHighlight = L_224;
        return ;
    end;
    return ;
end;
hookDashRemoveHighlight = function(...)
    if L_111.hookDashHighlight then
        pcall(function(...)
            L_111.hookDashHighlight:Destroy();
            return ;
        end);
        L_111.hookDashHighlight = nil;
    end;
    return ;
end;
hookDashGetDummy = function(...)
    return L_87:FindFirstChild("Live") and L_87.Live:FindFirstChild("Weakest Dummy");
end;
hookDashGetTargetFromMouse = function(...)
    local L_225 = nil;
    pcall(function(...)
        L_225 = L_106:GetMouse();
        return ;
    end);
    if L_225 then
        local L_226 = nil;
        pcall(function(...)
            L_226 = L_225.Hit.p;
            return ;
        end);
        if L_226 then
            local L_227 = hookDashGetDummy();
            local L_228 = L_227;
            if L_227 then
                L_228 = L_227:FindFirstChild("HumanoidRootPart") and L_227.HumanoidRootPart.Position;
            end;
            local L_229 = nil;
            local L_230 = math.huge;
            local L_231 = { pairs(L_83:GetPlayers()) };
            local L_232 = L_231[1];
            local L_233 = L_231[2];
            local L_234 = L_231[3];
            while true do
                local L_235;
                L_234, L_235 = L_232(L_233, L_234);
                if not L_234 then
                    break;
                end;
                if L_235 ~= L_106 and (L_235.Character and L_235.Character:FindFirstChild("HumanoidRootPart")) then
                    local L_236 = (L_235.Character.HumanoidRootPart.Position - L_226).Magnitude;
                    if L_236 < L_230 then
                        L_230 = L_236;
                        L_229 = L_235;
                    end;
                end;
            end;
            local L_237 = L_227;
            if L_227 then
                if L_228 then
                    L_228 = (L_228 - L_226).Magnitude < L_230;
                end;
                L_237 = L_228;
            end;
            if L_237 then
                L_229 = L_227;
            end;
            return L_229;
        end;
        return nil;
    end;
    return nil;
end;
hookDashTouchSelect = function(L_238, ...)
    local L_239 = (L_87.CurrentCamera or workspace.CurrentCamera):ScreenPointToRay(L_238.X, L_238.Y);
    local L_240 = RaycastParams.new();
    L_240.FilterDescendantsInstances = { L_106.Character };
    L_240.FilterType = Enum.RaycastFilterType.Blacklist;
    local L_241 = L_87:Raycast(L_239.Origin, L_239.Direction * 1000, L_240);
    if L_241 then
        local L_242 = L_241.Instance and L_241.Instance:FindFirstAncestorOfClass("Model");
        if L_242 then
            local L_243 = L_83:GetPlayerFromCharacter(L_242);
            if not L_243 then
                local L_244 = L_242;
                if L_242 then
                    L_244 = L_242:FindFirstChild("HumanoidRootPart");
                end;
                if L_244 then
                    local L_245 = hookDashGetDummy();
                    if L_242 == L_245 then
                        if L_111.hookDashTarget ~= L_245 then
                            hookDashRemoveHighlight();
                            L_111.hookDashTarget = L_245;
                            hookDashAddHighlight(L_245);
                            L_111.hookDashToggled = true;
                            hookDashDebug("Touch: selected dummy");
                        else
                            hookDashRemoveHighlight();
                            L_111.hookDashTarget = nil;
                            L_111.hookDashToggled = false;
                            hookDashDebug("Touch: deselected dummy");
                        end;
                    end;
                end;
            elseif L_111.hookDashTarget ~= L_243 then
                hookDashRemoveHighlight();
                L_111.hookDashTarget = L_243;
                hookDashAddHighlight(L_243.Character);
                L_111.hookDashToggled = true;
                hookDashDebug("Touch: selected player", L_243.Name);
            else
                hookDashRemoveHighlight();
                L_111.hookDashTarget = nil;
                L_111.hookDashToggled = false;
                hookDashDebug("Touch: deselected player", L_243.Name);
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
hookDashSelectNearest = function(...)
    local L_246 = hookDashGetTargetFromMouse();
    if not L_246 then
        hookDashDebug("SelectNearest: no target found");
    else
        hookDashRemoveHighlight();
        L_111.hookDashTarget = L_246;
        if typeof(L_246) ~= "Instance" or (not L_246:IsA("Player") or not L_246.Character) then
            hookDashAddHighlight(L_246);
            hookDashDebug("Selected model/dummy");
        else
            hookDashAddHighlight(L_246.Character);
            hookDashDebug("Selected player:", L_246.Name);
        end;
        L_111.hookDashToggled = true;
    end;
    return ;
end;
hookDashEnsureLV = function(L_247, ...)
    if L_247 then
        if not L_111.hookDashAtt or not L_111.hookDashAtt.Parent then
            L_111.hookDashAtt = Instance.new("Attachment", L_247);
        end;
        if not L_111.hookDashLV or not L_111.hookDashLV.Parent then
            local L_248 = Instance.new("LinearVelocity");
            L_248.Attachment0 = L_111.hookDashAtt;
            L_248.MaxForce = math.huge;
            L_248.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector;
            L_248.RelativeTo = Enum.ActuatorRelativeTo.World;
            L_248.Parent = L_247;
            L_111.hookDashLV = L_248;
        end;
        return L_111.hookDashLV;
    end;
    return nil;
end;
hookDashStopLV = function(...)
    if L_111.hookDashLV then
        pcall(function(...)
            L_111.hookDashLV.VectorVelocity = Vector3.new();
            L_111.hookDashLV:Destroy();
            return ;
        end);
        L_111.hookDashLV = nil;
    end;
    if L_111.hookDashAtt then
        pcall(function(...)
            L_111.hookDashAtt:Destroy();
            return ;
        end);
        L_111.hookDashAtt = nil;
    end;
    return ;
end;
hookDashPerformFallback = function(...)
    if hookDash and L_111.hookDashTarget then
        local L_249 = L_106.Character;
        if L_249 then
            local L_250 = L_249:FindFirstChild("HumanoidRootPart");
            if L_250 then
                local L_251 = L_111.hookDashTarget;
                local L_252 = if typeof(L_251) == "Instance" and L_251:IsA("Player") then L_251.Character and L_251.Character:FindFirstChild("HumanoidRootPart") else L_251:FindFirstChild("HumanoidRootPart");
                if L_252 then
                    local L_253 = L_252.AssemblyLinearVelocity or Vector3.new();
                    local L_254 = L_252.CFrame.RightVector * (hookDashRange or 2) + L_253 * (hookDashPrediction or 0.3);
                    local L_255 = Vector3.new(L_252.Position.X + L_254.X, L_250.Position.Y, L_252.Position.Z + L_254.Z);
                    hookDashDebug("Fallback dash to", L_255);
                    pcall(function(...)
                        if fireDash then
                            fireDash(L_249);
                        end;
                        return ;
                    end);
                    local L_256 = Instance.new("Attachment", L_250);
                    local L_257 = Instance.new("LinearVelocity");
                    L_257.Attachment0 = L_256;
                    L_257.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
                    L_257.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector;
                    L_257.RelativeTo = Enum.ActuatorRelativeTo.World;
                    local L_258 = L_255 - L_250.Position;
                    if not (L_258.Magnitude > 0) then
                        L_257.VectorVelocity = Vector3.new(0, 0, 0);
                    else
                        L_257.VectorVelocity = L_258.Unit * (hookDashSpeedN or 110);
                    end;
                    L_257.Parent = L_250;
                    L_111.hookDashLV = L_257;
                    L_111.hookDashAtt = L_256;
                    task.delay(hookDashDuration or 0.15, function(...)
                        pcall(function(...)
                            if L_111.hookDashLV then
                                L_111.hookDashLV:Destroy();
                            end;
                            if L_111.hookDashAtt then
                                L_111.hookDashAtt:Destroy();
                            end;
                            return ;
                        end);
                        L_111.hookDashLV = nil;
                        L_111.hookDashAtt = nil;
                        return ;
                    end);
                    return ;
                end;
                hookDashDebug("Fallback: no target HRP");
                return ;
            end;
            hookDashDebug("Fallback: no HRP");
            return ;
        end;
        hookDashDebug("Fallback: no character");
        return ;
    end;
    return ;
end;
hookDashPerformFull = function(...)
    local L_295 = {
        pcall(function(...)
            if not hookDash or not L_111.hookDashTarget then
                error("no hookDash or no target");
            end;
            local L_259 = L_106.Character;
            if not L_259 then
                error("no character");
            end;
            local L_260 = L_259:FindFirstChild("HumanoidRootPart");
            if not L_260 then
                error("no hrp");
            end;
            if L_260.Position.Y > 442 then
                error("Y too high");
            end;
            local L_261 = L_111.hookDashTarget;
            local L_262 = if typeof(L_261) == "Instance" and L_261:IsA("Player") then L_261.Character and L_261.Character:FindFirstChild("HumanoidRootPart") else L_261:FindFirstChild("HumanoidRootPart");
            if not L_262 then
                error("no target hrp");
            end;
            if (L_262.CFrame.Position - L_260.CFrame.Position).Magnitude > (hookDashDistance or (distance or 35)) then
                error("too far");
            end;
            pcall(function(...)
                if fireDash then
                    fireDash(L_259);
                end;
                return ;
            end);
            click = true;
            f = false;
            noClip = false;
            m = true;
            a = true;
            task.spawn(function(...)
                task.delay(hookDashDuration or (duration or 0.15), function(...)
                    silent = false;
                    m = false;
                    noClip = true;
                    q = true;
                    local L_263 = nil;
                    L_263 = L_84.Stepped:Connect(function(...)
                        hookDash_aimlock(L_111.hookDashTarget);
                        task.delay(0.5, function(...)
                            if L_263 then
                                L_263:Disconnect();
                            end;
                            return ;
                        end);
                        return ;
                    end);
                    task.wait(cooldown or 1);
                    f = true;
                    return ;
                end);
                return ;
            end);
            task.spawn(function(...)
                task.delay(hookDashDelay or (delay or 0.11), function(...)
                    hookDash_simulateLeftClickMobile();
                    click = false;
                    return ;
                end);
                return ;
            end);
            local L_264 = (L_262.Position - L_260.Position).Unit;
            local L_265 = L_262.CFrame.LookVector;
            local L_266 = Vector3.new(L_264.X, 0, L_264.Z).Unit;
            local L_267 = Vector3.new(L_266.Z, 0, -L_266.X);
            local L_268 = Vector3.new(-L_266.Z, 0, L_266.X);
            local L_269 = L_262.Position + L_267 * (hookDashRange or (range or 2));
            local L_270 = L_262.Position + L_268 * (hookDashRange or (range or 2));
            local L_271 = (L_269 - L_260.Position).Unit;
            local L_272 = (L_270 - L_260.Position).Unit;
            if not ((L_262.Position + L_262.CFrame.RightVector * (hookDashRange or (range or 2)) - L_260.CFrame.Position).Magnitude < (L_262.Position + -L_262.CFrame.RightVector * (hookDashRange or (range or 2)) - L_260.CFrame.Position).Magnitude) then
                if not (L_265:Dot(L_264) < 0) then
                    silent = true;
                    hookDash_pressQA();
                    if L_259:FindFirstChildOfClass("Humanoid") then
                        L_259:FindFirstChildOfClass("Humanoid").AutoRotate = false;
                    end;
                    local L_273 = nil;
                    L_273 = L_84.Stepped:Connect(function(...)
                        if m then
                            hookDash_silentAim(L_111.hookDashTarget, -1);
                            return ;
                        end;
                        L_273:Disconnect();
                        return ;
                    end);
                else
                    silent = true;
                    hookDash_pressQD();
                    if L_259:FindFirstChildOfClass("Humanoid") then
                        L_259:FindFirstChildOfClass("Humanoid").AutoRotate = false;
                    end;
                    local L_274 = nil;
                    L_274 = L_84.Stepped:Connect(function(...)
                        if m then
                            hookDash_silentAim(L_111.hookDashTarget, 1);
                            return ;
                        end;
                        L_274:Disconnect();
                        return ;
                    end);
                end;
            elseif not (L_265:Dot(L_264) < 0) then
                silent = true;
                hookDash_pressQD();
                if L_259:FindFirstChildOfClass("Humanoid") then
                    L_259:FindFirstChildOfClass("Humanoid").AutoRotate = false;
                end;
                local L_275 = nil;
                L_275 = L_84.Stepped:Connect(function(...)
                    if m then
                        hookDash_silentAim(L_111.hookDashTarget, 1);
                        return ;
                    end;
                    L_275:Disconnect();
                    return ;
                end);
            else
                silent = true;
                hookDash_pressQA();
                if L_259:FindFirstChildOfClass("Humanoid") then
                    L_259:FindFirstChildOfClass("Humanoid").AutoRotate = false;
                end;
                local L_276 = nil;
                L_276 = L_84.Stepped:Connect(function(...)
                    if m then
                        hookDash_silentAim(L_111.hookDashTarget, -1);
                        return ;
                    end;
                    L_276:Disconnect();
                    return ;
                end);
            end;
            while m do
                task.wait();
                if not L_111.hookDashTarget or L_111.hookDashTarget ~= hookDashGetDummy() then
                    if L_111.hookDashTarget and (typeof(L_111.hookDashTarget) == "Instance" and (L_111.hookDashTarget:IsA("Player") and L_111.hookDashTarget.Character)) then
                        local L_277 = L_106.Character and L_106.Character:FindFirstChild("HumanoidRootPart");
                        local L_278 = L_111.hookDashTarget.Character.HumanoidRootPart.AssemblyLinearVelocity;
                        local L_279 = L_111.hookDashTarget.Character.HumanoidRootPart.Position + L_267 * (hookDashRange or (range or 2)) + L_278 * (hookDashPrediction or (prediction or 0.3));
                        local L_280 = L_111.hookDashTarget.Character.HumanoidRootPart.Position + L_268 * (hookDashRange or (range or 2)) + L_278 * (hookDashPrediction or (prediction or 0.3));
                        local L_281 = L_279 + L_271 * (hookDashReach or (reach or 6.5));
                        local L_282 = L_280 + L_272 * (hookDashReach or (reach or 6.5));
                        local L_283 = Vector3.new(L_281.X, L_277.Position.Y, L_281.Z);
                        local L_284 = Vector3.new(L_282.X, L_277.Position.Y, L_282.Z);
                        local L_285 = if (L_111.hookDashTarget.Character.HumanoidRootPart.Position + L_111.hookDashTarget.Character.HumanoidRootPart.CFrame.RightVector * (hookDashRange or (range or 2)) - L_277.CFrame.Position).Magnitude < (L_111.hookDashTarget.Character.HumanoidRootPart.Position + -L_111.hookDashTarget.Character.HumanoidRootPart.CFrame.RightVector * (hookDashRange or (range or 2)) - L_277.CFrame.Position).Magnitude then { CFrame = CFrame.new(L_283) } else { CFrame = CFrame.new(L_284) };
                        hookDash_setDashVelocity(L_277, L_285.CFrame.Position, hookDashDuration or (duration or 0.15));
                        task.delay(hookDashDuration or (duration or 0.15), function(...)
                            m = false;
                            hookDashStopLV();
                            return ;
                        end);
                    end;
                else
                    local L_286 = L_106.Character and L_106.Character:FindFirstChild("HumanoidRootPart");
                    local L_287 = L_111.hookDashTarget.HumanoidRootPart.AssemblyLinearVelocity;
                    local L_288 = L_111.hookDashTarget.HumanoidRootPart.Position + L_267 * (hookDashRange or (range or 2)) + L_287 * (hookDashPrediction or (prediction or 0.3));
                    local L_289 = L_111.hookDashTarget.HumanoidRootPart.Position + L_268 * (hookDashRange or (range or 2)) + L_287 * (hookDashPrediction or (prediction or 0.3));
                    local L_290 = L_288 + L_271 * (hookDashReach or (reach or 6.5));
                    local L_291 = L_289 + L_272 * (hookDashReach or (reach or 6.5));
                    local L_292 = Vector3.new(L_290.X, L_286.Position.Y, L_290.Z);
                    local L_293 = Vector3.new(L_291.X, L_286.Position.Y, L_291.Z);
                    local L_294 = if (L_111.hookDashTarget.HumanoidRootPart.Position + L_111.hookDashTarget.HumanoidRootPart.CFrame.RightVector * (hookDashRange or (range or 2)) - L_286.CFrame.Position).Magnitude < (L_111.hookDashTarget.HumanoidRootPart.Position + -L_111.hookDashTarget.HumanoidRootPart.CFrame.RightVector * (hookDashRange or (range or 2)) - L_286.CFrame.Position).Magnitude then { CFrame = CFrame.new(L_292) } else { CFrame = CFrame.new(L_293) };
                    hookDash_setDashVelocity(L_286, L_294.CFrame.Position, hookDashDuration or (duration or 0.15));
                    task.delay(hookDashDuration or (duration or 0.15), function(...)
                        m = false;
                        hookDashStopLV();
                        return ;
                    end);
                end;
            end;
            hookDashDebug("PerformFull: success");
            return ;
        end)
    };
    local L_296 = L_295[2];
    if L_295[1] then
        return true;
    end;
    local L_297 = hookDashDebug;
    local L_298 = "PerformFull failed:";
    local L_299 = L_296;
    if not L_296 then
        L_299 = "unknown error";
    end;
    L_297(L_298, L_299);
    return false, L_296;
end;
hookDashSetup = function(...)
    pcall(function(...)
        if L_111.hookDashInput then
            L_111.hookDashInput:Disconnect();
            L_111.hookDashInput = nil;
        end;
        return ;
    end);
    L_111.hookDashInput = uis.InputBegan:Connect(function(L_300, L_301, ...)
        local L_302 = L_300;
        if not L_301 then
            if L_302.UserInputType ~= Enum.UserInputType.Touch then
                if L_302.UserInputType == Enum.UserInputType.Keyboard then
                    if L_302.KeyCode ~= Enum.KeyCode.V then
                        if L_302.KeyCode ~= Enum.KeyCode.C then
                            return ;
                        end;
                        if hookDash then
                            if L_111.hookDashTarget or target then
                                local L_306 = {
                                    pcall(function(...)
                                        local L_303 = { hookDashPerformFull() };
                                        local L_304 = L_303[2];
                                        if not L_303[1] then
                                            local L_305 = error;
                                            if not L_304 then
                                                L_304 = "performfull failed";
                                            end;
                                            L_305(L_304);
                                        end;
                                        return ;
                                    end)
                                };
                                local L_307 = L_306[1];
                                local L_308 = L_306[2];
                                if L_307 then
                                    hookDashDebug("C: full perform invoked successfully");
                                else
                                    hookDashDebug("Full attempt failed, falling back. err:", L_308);
                                    pcall(function(...)
                                        hookDashPerformFallback();
                                        return ;
                                    end);
                                end;
                                return ;
                            end;
                            hookDashDebug("C pressed but no target");
                            return ;
                        end;
                        return ;
                    end;
                    if hookDash then
                        toogle = not toogle;
                        if not toogle then
                            if target then
                                pcall(function(...)
                                    if target ~= hookDashGetDummy() then
                                        hookDashRemoveHighlight(target.Character);
                                    else
                                        hookDashRemoveHighlight();
                                    end;
                                    return ;
                                end);
                                target = nil;
                            end;
                            L_111.hookDashTarget = nil;
                            L_111.hookDashToggled = false;
                            hookDashDebug("V: toggled off");
                        else
                            local L_309 = math.huge;
                            lastmagnitude = L_309;
                            pcall(function(...)
                                hookDashGetTargetFromMouse();
                                return ;
                            end);
                            if target then
                                pcall(function(...)
                                    if target ~= hookDashGetDummy() then
                                        hookDashAddHighlight(target.Character);
                                    else
                                        hookDashAddHighlight(target);
                                    end;
                                    return ;
                                end);
                                L_111.hookDashTarget = target;
                                L_111.hookDashToggled = true;
                                hookDashDebug("V: selected target (from original globals)", type(target) == "table" and tostring(target) or tostring(target and target.Name or "model"));
                            end;
                        end;
                        return ;
                    end;
                    return ;
                end;
                return ;
            end;
            if hookDash then
                pcall(function(...)
                    hookDashTouchSelect(L_302.Position);
                    return ;
                end);
                return ;
            end;
            return ;
        end;
        return ;
    end);
    pcall(function(...)
        if L_111.hookDashPlayerRemoving then
            L_111.hookDashPlayerRemoving:Disconnect();
            L_111.hookDashPlayerRemoving = nil;
        end;
        return ;
    end);
    L_111.hookDashPlayerRemoving = L_83.PlayerRemoving:Connect(function(L_310, ...)
        if L_111.hookDashTarget == L_310 then
            hookDashRemoveHighlight();
            L_111.hookDashTarget = nil;
            L_111.hookDashToggled = false;
            hookDashDebug("Player removed - cleared target");
        end;
        return ;
    end);
    pcall(function(...)
        if L_111.hookDashWatcher then
            L_111.hookDashWatcher:Disconnect();
            L_111.hookDashWatcher = nil;
        end;
        return ;
    end);
    L_111.hookDashWatcher = L_84.Heartbeat:Connect(function(...)
        if hookDash then
            local L_311 = L_111.hookDashTarget or target;
            if L_311 then
                local L_314 = {
                    pcall(function(...)
                        if typeof(L_311) ~= "Instance" or not L_311:IsA("Player") then
                            if typeof(L_311) ~= "Instance" or not L_311:IsA("Model") then
                                return false;
                            end;
                            local L_312 = L_311:FindFirstChildOfClass("Humanoid");
                            if L_312 then
                                L_312 = L_312.Health > 0;
                            end;
                            return L_312;
                        end;
                        local L_313 = L_311.Character and L_311.Character:FindFirstChildOfClass("Humanoid");
                        if L_313 then
                            L_313 = L_313.Health > 0;
                        end;
                        return L_313;
                    end)
                };
                local L_315 = L_314[2];
                if not L_314[1] or not L_315 then
                    hookDashRemoveHighlight();
                    L_111.hookDashTarget = nil;
                    L_111.hookDashToggled = false;
                    target = nil;
                    toogle = false;
                    hookDashDebug("Target died or removed - cleared");
                end;
                return ;
            end;
            return ;
        end;
        return ;
    end);
    hookDashDebug("HookDash setup complete");
    return ;
end;
hookDashStop = function(...)
    pcall(function(...)
        if L_111.hookDashInput then
            L_111.hookDashInput:Disconnect();
            L_111.hookDashInput = nil;
        end;
        return ;
    end);
    pcall(function(...)
        if L_111.hookDashPlayerRemoving then
            L_111.hookDashPlayerRemoving:Disconnect();
            L_111.hookDashPlayerRemoving = nil;
        end;
        return ;
    end);
    pcall(function(...)
        if L_111.hookDashWatcher then
            L_111.hookDashWatcher:Disconnect();
            L_111.hookDashWatcher = nil;
        end;
        return ;
    end);
    pcall(function(...)
        if L_111.hookDashCharAdded then
            L_111.hookDashCharAdded:Disconnect();
            L_111.hookDashCharAdded = nil;
        end;
        return ;
    end);
    hookDashRemoveHighlight();
    L_111.hookDashTarget = nil;
    L_111.hookDashToggled = false;
    target = nil;
    toogle = false;
    pcall(function(...)
        hookDashStopLV();
        return ;
    end);
    hookDashDebug("HookDash stopped and cleaned");
    return ;
end;
L_138.KittyTech:Paragraph({ Title = "Kitty Tech", Desc = "Ping-based tech presets (W.I.P)", Image = "swords", ImageSize = 20, Color = Color3.fromHex("#ff6b6b") });
L_316 = { Enabled = false };
L_317 = { dashDelayBefore = 0.01, postDashWait = 0.06, cooldownTime = 4.8, orbitRadius = 3, orbitHeight = 1, spinDuration = 0.6, lockStart = 0.26, lockDuration = 0.35, targetDistance = 12, attachmentDuration = 0.5, pingMs = 60 };
L_320 = function(L_318, ...)
    local L_319 = math.clamp(L_318 or 60, 10, 600);
    return math.clamp(L_319 / 1000 * 1.3, 0.03, 0.22);
end;
L_317.postDashWait = L_320(L_317.pingMs);
L_321 = {};
L_322 = nil;
L_323 = nil;
L_324 = nil;
L_325 = nil;
L_326 = false;
L_327 = { ["10503381238"] = true, ["13379003796"] = true };
L_328 = { ["10479335397"] = true, ["13380255751"] = true };
L_335 = function(...)
    if L_322 then
        L_322:Destroy();
        L_322 = nil;
    end;
    if L_323 then
        L_323:Destroy();
        L_323 = nil;
    end;
    if L_324 then
        L_324:Disconnect();
        L_324 = nil;
    end;
    if L_325 then
        L_325:Destroy();
        L_325 = nil;
    end;
    local L_329 = L_106.Character and L_106.Character:FindFirstChild("HumanoidRootPart");
    if L_329 then
        local L_330 = { ipairs(L_329:GetChildren()) };
        local L_331 = L_330[1];
        local L_332 = L_330[3];
        local L_333 = L_330[2];
        while true do
            local L_334;
            L_332, L_334 = L_331(L_333, L_332);
            if not L_332 then
                break;
            end;
            if L_334:IsA("Attachment") or L_334.Name == "HasSnapped" then
                L_334:Destroy();
            end;
        end;
    end;
    return ;
end;
L_348 = function(L_336, ...)
    local L_337 = L_336;
    L_335();
    if L_337 and L_106.Character then
        L_325 = Instance.new("Part");
        L_325.Size = Vector3.new(0.5, 0.5, 0.5);
        L_325.Transparency = 1;
        L_325.Anchored = true;
        L_325.CanCollide = false;
        L_325.Name = "KittyFollowPart";
        L_325.Parent = L_87;
        local L_338 = Instance.new("Attachment", L_106.Character.HumanoidRootPart);
        local L_339 = Instance.new("Attachment", L_325);
        local L_340 = Instance.new("Attachment", L_106.Character.HumanoidRootPart);
        local L_341 = Instance.new("Attachment", L_325);
        L_322 = Instance.new("AlignPosition");
        L_322.Attachment0 = L_338;
        L_322.Attachment1 = L_339;
        L_322.RigidityEnabled = true;
        L_322.Responsiveness = 200;
        L_322.MaxForce = math.huge;
        L_322.Parent = L_106.Character.HumanoidRootPart;
        L_323 = Instance.new("AlignOrientation");
        L_323.Attachment0 = L_340;
        L_323.Attachment1 = L_341;
        L_323.RigidityEnabled = true;
        L_323.Responsiveness = 200;
        L_323.MaxTorque = math.huge;
        L_323.Parent = L_106.Character.HumanoidRootPart;
        local L_342 = 0;
        L_324 = L_84.RenderStepped:Connect(function(L_343, ...)
            if L_337 and (L_337.Parent and (L_106.Character and L_106.Character.HumanoidRootPart)) then
                L_342 = L_342 + L_343;
                if L_316.Enabled then
                    local L_344 = L_337.Position + Vector3.new(0, L_317.orbitHeight, 0);
                    local L_345 = math.rad(360) * (L_342 / L_317.spinDuration);
                    local L_346 = L_344 + Vector3.new(math.cos(L_345) * L_317.orbitRadius, 0, math.sin(L_345) * L_317.orbitRadius);
                    L_325.CFrame = CFrame.new(L_346, L_337.Position);
                    if not L_106.Character.HumanoidRootPart:FindFirstChild("HasSnapped") then
                        L_106.Character.HumanoidRootPart.CFrame = CFrame.new(L_346, L_337.Position);
                        local L_347 = Instance.new("BoolValue");
                        L_347.Name = "HasSnapped";
                        L_347.Parent = L_106.Character.HumanoidRootPart;
                    end;
                    if L_342 >= L_317.lockStart and L_342 <= L_317.lockStart + L_317.lockDuration then
                        L_325.CFrame = CFrame.new(L_106.Character.HumanoidRootPart.Position, L_337.Position);
                    end;
                    return ;
                end;
                L_335();
                return ;
            end;
            L_335();
            return ;
        end);
        return ;
    end;
    return ;
end;
L_359 = function(...)
    local L_349 = nil;
    local L_350 = L_317.targetDistance;
    local L_351 = { ipairs(L_87:GetDescendants()) };
    local L_352 = L_351[3];
    local L_353 = L_351[1];
    local L_354 = L_351[2];
    while true do
        local L_355;
        L_352, L_355 = L_353(L_354, L_352);
        if not L_352 then
            break;
        end;
        if L_355:IsA("Model") and L_355 ~= L_106.Character then
            local L_356 = L_355:FindFirstChildOfClass("Humanoid");
            local L_357 = L_355:FindFirstChild("HumanoidRootPart") or (L_355:FindFirstChild("Torso") or L_355:FindFirstChild("UpperTorso"));
            if L_356 then
                L_356 = L_356.Health > 0 and L_357;
            end;
            if L_356 then
                local L_358 = (L_106.Character.HumanoidRootPart.Position - L_357.Position).Magnitude;
                if L_358 < L_350 then
                    L_350 = L_358;
                    L_349 = L_357;
                end;
            end;
        end;
    end;
    return L_349;
end;
L_361 = function(L_360, ...)
    if L_360 then
        task.wait(L_317.postDashWait);
        L_88:SendKeyEvent(true, Enum.KeyCode.Q, false, game);
        L_88:SendKeyEvent(false, Enum.KeyCode.Q, false, game);
        L_348(L_360);
        task.delay(L_317.attachmentDuration, L_335);
        return ;
    end;
    return ;
end;
L_365 = function(L_362, ...)
    if L_316.Enabled and not L_326 then
        local L_363 = string.match(L_362.Animation.AnimationId, "%d+");
        if not L_328[L_363] then
            if L_327[L_363] then
                L_326 = true;
                task.delay(L_317.dashDelayBefore, function(...)
                    local L_364 = L_359();
                    if L_364 then
                        L_361(L_364);
                    end;
                    return ;
                end);
                task.delay(L_317.cooldownTime, function(...)
                    L_326 = false;
                    return ;
                end);
            end;
            return ;
        end;
        L_326 = true;
        task.delay(L_317.cooldownTime, function(...)
            L_326 = false;
            return ;
        end);
        return ;
    end;
    return ;
end;
L_370 = function(L_366, ...)
    local L_367 = L_366:FindFirstChildOfClass("Humanoid");
    local L_368 = L_366:FindFirstChild("HumanoidRootPart");
    local L_369 = L_367;
    if L_367 then
        L_369 = L_368;
    end;
    if L_369 then
        L_367.AnimationPlayed:Connect(L_365);
    end;
    return ;
end;
if L_106.Character then
    L_370(L_106.Character);
end;
L_106.CharacterAdded:Connect(L_370);
L_138.KittyTech:Toggle({
    Title = "Enable Kitty Tech",
    Value = L_316.Enabled,
    Callback = function(L_371, ...)
        L_316.Enabled = L_371;
        if not L_371 then
            L_335();
        end;
        return ;
    end
});
L_138.KittyTech:Dropdown({
    Title = "Ping Preset",
    Values = { "10ms", "40ms ", "60MS", "100mS", "200ms" },
    Value = "60ms (Default)",
    Callback = function(L_372, ...)
        local L_373 = { ["10ms (LAN)"] = 10, ["40ms (Good)"] = 40, ["60ms (Default)"] = 60, ["100ms (High)"] = 100, ["200ms (Very High)"] = 200 };
        L_317.pingMs = L_373[L_372] or 60;
        L_317.postDashWait = L_320(L_317.pingMs);
        return ;
    end
});
L_138.KittyTech:Slider({
    Title = "Custom Ping (ms)",
    Value = { Min = 10, Max = 400, Default = L_317.pingMs },
    Callback = function(L_374, ...)
        L_317.pingMs = tonumber(L_374);
        L_317.postDashWait = L_320(L_317.pingMs);
        return ;
    end
});
L_138.KittyTech:Paragraph({ Title = "Sorry !", Desc = "Other configs will come in feture updates !", Image = "lucide:sad", ImageSize = 20, Color = Color3.fromHex("#ff6b6b") });
L_138.AutoBlock:Paragraph({ Title = "AutoBlock (W.I.P)", Desc = "Automatically blocks stuff \226\128\148 work in progress", Image = "shield", ImageSize = 20, Color = Color3.fromHex("#0984e3") });
L_375 = { Enabled = false, M1AfterBlock = false, BlockDistance = 20 };
L_376 = {};
L_377 = { 10469493270, 10469630950, 10469639222, 10469643643, 13532562418, 13532600125, 13532604085, 13294471966, 13491635433, 13296577783, 13295919399, 13295936866, 13370310513, 13390230973, 13378751717, 13378708199, 14004222985, 13997092940, 14001963401, 14136436157, 15259161390, 15240216931, 15240176873, 15162694192, 16515503507, 16515520431, 16515448089, 16552234590, 17889458563, 17889461810, 17889471098, 17889290569, 123005629431309, 100059874351664, 104895379416340 };
L_378 = { [10479335397] = true, [13380255751] = true, [134775406437630] = true };
L_379 = { [10468665991] = true, [10466974800] = true, [10471336737] = true, [12510170988] = true, [12272894215] = true, [12296882427] = true, [12307656616] = true, [101588604872680] = true, [105442749844050] = true, [109617620932970] = true, [131820095363270] = true, [135289891173400] = true, [125955606488860] = true, [12534735382] = true, [12502664044] = true, [12509505723] = true, [12618271998] = true, [12684390285] = true, [13376869471] = true, [13294790250] = true, [13376962659] = true, [13501296372] = true, [13556985475] = true, [145162735010] = true, [14046756619] = true, [14299135500] = true, [14351441234] = true, [15290930205] = true, [15145462680] = true, [15295895753] = true, [15295336270] = true, [16139108718] = true, [16515850153] = true, [16431491215] = true, [16597322398] = true, [16597912086] = true, [17799224866] = true, [17838006839] = true, [17857788598] = true, [18179181663] = true, [113166426814230] = true, [116753755471636] = true, [116153572280460] = true, [114095570398450] = true, [77509627104305] = true };
L_380 = {};
L_381 = false;
L_386 = function(L_382, L_383, ...)
    local L_384 = L_106.Character;
    if L_384 then
        local L_385 = L_384:FindFirstChild("Communicate");
        if L_385 then
            L_385:FireServer({ Goal = "KeyPress", Key = Enum.KeyCode.F });
            if not L_383 then
                task.wait(L_382 - 0.0001);
            else
                task.wait(0.35);
            end;
            L_385:FireServer({ Goal = "KeyRelease", Key = Enum.KeyCode.F });
            if L_375.M1AfterBlock and not L_381 then
                L_381 = true;
                task.spawn(function(...)
                    L_385:FireServer({ Goal = "LeftClick", Mobile = true });
                    task.wait(0.3);
                    L_385:FireServer({ Goal = "LeftClickRelease", Mobile = true });
                    task.wait(0.55);
                    L_381 = false;
                    return ;
                end);
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
L_412 = function(...)
    if L_376.heartbeat then
        L_376.heartbeat:Disconnect();
    end;
    L_376.heartbeat = L_84.Heartbeat:Connect(function(...)
        if L_375.Enabled then
            local L_387 = L_106.Character;
            local L_388 = L_387;
            if L_387 then
                L_388 = L_387:FindFirstChild("HumanoidRootPart");
            end;
            local L_389 = L_387;
            if L_387 then
                L_389 = L_387:FindFirstChild("Head");
            end;
            if L_388 and L_389 then
                local L_390 = L_87:FindFirstChild("Live");
                if L_390 then
                    local L_391 = { pairs(L_390:GetChildren()) };
                    local L_392 = L_391[3];
                    local L_393 = L_391[1];
                    local L_394 = L_391[2];
                    while true do
                        local L_395;
                        L_392, L_395 = L_393(L_394, L_392);
                        if not L_392 then
                            break;
                        end;
                        if L_395:IsA("Model") and L_395 ~= L_387 then
                            local L_396 = L_395:FindFirstChildOfClass("Humanoid");
                            local L_397 = L_395:FindFirstChild("HumanoidRootPart");
                            local L_398 = L_396;
                            if L_396 then
                                L_398 = L_397;
                            end;
                            if L_398 then
                                local L_399 = (L_397.Position - L_389.Position).Unit;
                                if L_389.CFrame.LookVector:Dot(L_399) > 0.6 then
                                    local L_400 = { pairs(L_396:GetPlayingAnimationTracks()) };
                                    local L_401 = L_400[3];
                                    local L_402 = L_400[2];
                                    local L_403 = L_400[1];
                                    while true do
                                        local L_404;
                                        L_401, L_404 = L_403(L_402, L_401);
                                        if not L_401 then
                                            break;
                                        end;
                                        local L_405 = L_404.Animation;
                                        local L_406 = L_405;
                                        if L_405 then
                                            L_406 = L_405.AnimationId;
                                        end;
                                        if L_406 then
                                            local L_407 = tonumber(string.match(L_405.AnimationId, "%d+"));
                                            if L_407 then
                                                local L_408 = tostring(L_395) .. "_" .. tostring(L_407);
                                                local L_409 = (L_388.Position - L_397.Position).Magnitude;
                                                local L_410 = false;
                                                local L_411 = 0.6;
                                                if not L_379[L_407] or not (L_409 <= L_375.BlockDistance) then
                                                    if not L_378[L_407] or not (L_409 <= L_375.BlockDistance) then
                                                        if table.find(L_377, L_407) and L_409 <= L_375.BlockDistance then
                                                            L_410 = true;
                                                        end;
                                                    else
                                                        L_411 = 0.6;
                                                        L_410 = true;
                                                    end;
                                                else
                                                    L_410 = true;
                                                    L_411 = 1.1;
                                                end;
                                                if L_410 then
                                                    L_410 = not L_380[L_408] or tick() - L_380[L_408] >= L_411;
                                                end;
                                                if L_410 then
                                                    L_380[L_408] = tick();
                                                    task.spawn(function(...)
                                                        L_386(L_411, L_378[L_407] and true or false);
                                                        return ;
                                                    end);
                                                end;
                                            end;
                                        end;
                                    end;
                                end;
                            end;
                        end;
                    end;
                    return ;
                end;
                return ;
            end;
            return ;
        end;
        return ;
    end);
    return ;
end;
L_413 = function(...)
    if L_376.heartbeat then
        L_376.heartbeat:Disconnect();
        L_376.heartbeat = nil;
    end;
    return ;
end;
L_138.AutoBlock:Toggle({
    Title = "Enable AutoBlock",
    Value = L_375.Enabled,
    Callback = function(L_414, ...)
        L_375.Enabled = L_414;
        if not L_414 then
            L_413();
        else
            L_412();
        end;
        return ;
    end
});
L_138.AutoBlock:Toggle({
    Title = "M1 After Block",
    Value = L_375.M1AfterBlock,
    Callback = function(L_415, ...)
        L_375.M1AfterBlock = L_415;
        return ;
    end
});
L_138.AutoBlock:Slider({
    Title = "Block Distance (studs)",
    Value = { Min = 5, Max = 30, Default = L_375.BlockDistance },
    Callback = function(L_416, ...)
        L_375.BlockDistance = tonumber(L_416);
        return ;
    end
});
L_429 = function(L_417, L_418, ...)
    if not L_418 then
        L_418 = math.huge;
    end;
    if L_417 then
        local L_419 = L_417:FindFirstChild("HumanoidRootPart");
        if L_419 then
            local L_420 = L_87:FindFirstChild("Live");
            if L_420 then
                local L_421 = nil;
                local L_422 = { ipairs(L_420:GetChildren()) };
                local L_423 = L_422[3];
                local L_424 = L_422[1];
                local L_425 = L_422[2];
                while true do
                    local L_426;
                    L_423, L_426 = L_424(L_425, L_423);
                    if not L_423 then
                        break;
                    end;
                    if L_426:IsA("Model") and L_426 ~= L_417 then
                        local L_427 = L_426:FindFirstChild("HumanoidRootPart");
                        if L_427 then
                            local L_428 = (L_419.Position - L_427.Position).Magnitude;
                            if L_428 < L_418 then
                                L_418 = L_428;
                                L_421 = L_426;
                            end;
                        end;
                    end;
                end;
                return L_421;
            end;
            return nil;
        end;
        return nil;
    end;
    return nil;
end;
L_433 = function(L_430, ...)
    if L_430 then
        local L_431 = L_430:FindFirstChild("Communicate");
        if L_431 and typeof(L_431.FireServer) == "function" then
            local L_432 = { { Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress" } };
            pcall(function(...)
                L_431:FireServer(unpack(L_432));
                return ;
            end);
        end;
        return ;
    end;
    return ;
end;
L_447 = function(L_434, L_435, ...)
    local L_436 = RaycastParams.new();
    L_436.FilterType = Enum.RaycastFilterType.Blacklist;
    local L_437 = "FilterDescendantsInstances";
    if not L_435 then
        L_435 = {};
    end;
    L_436[L_437] = L_435;
    local L_438 = { pairs(L_87:GetDescendants()) };
    local L_439 = L_438[1];
    local L_440 = L_438[2];
    local L_441 = L_438[3];
    while true do
        local L_442;
        L_441, L_442 = L_439(L_440, L_441);
        if not L_441 then
            break;
        end;
        if L_442:IsA("BasePart") and (L_442.Name:find("Tree") or (L_442.Name:find("Leaf") or L_442.Name:find("Foliage"))) then
            table.insert(L_436.FilterDescendantsInstances, L_442);
        end;
    end;
    local L_443 = L_434 + Vector3.new(0, 80, 0);
    local L_444 = Vector3.new(0, -300, 0);
    local L_445 = L_87:Raycast(L_443, L_444, L_436);
    local L_446 = L_445;
    if L_445 then
        L_446 = L_445.Position;
    end;
    if not L_446 then
        return L_434.Y;
    end;
    return L_445.Position.Y;
end;
L_448 = {};
L_449 = L_68;
L_459 = function(L_450, ...)
    if L_450 then
        local L_451 = L_450:FindFirstChildOfClass("Humanoid");
        if L_451 then
            local L_452 = L_451:FindFirstChildOfClass("Animator");
            if L_452 then
                local L_453 = { ipairs(L_452:GetPlayingAnimationTracks()) };
                local L_454 = L_453[2];
                local L_455 = L_453[3];
                local L_456 = L_453[1];
                while true do
                    local L_457;
                    L_455, L_457 = L_456(L_454, L_455);
                    if not L_455 then
                        break;
                    end;
                    local L_458 = L_457;
                    pcall(function(...)
                        L_458:Stop();
                        return ;
                    end);
                end;
                return ;
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
L_460 = { [L_449[L_81("M\224\167\169", 18284043870530)]] = nil, Red = Color3.fromRGB(255, 0, 0), Green = Color3.fromRGB(0, 255, 0), Blue = Color3.fromRGB(0, 0, 255), Yellow = Color3.fromRGB(255, 255, 0), Purple = Color3.fromRGB(128, 0, 128), Orange = Color3.fromRGB(255, 165, 0), Pink = Color3.fromRGB(255, 192, 203), Cyan = Color3.fromRGB(0, 255, 255), Lime = Color3.fromRGB(0, 255, 0), Teal = Color3.fromRGB(0, 128, 128), Lavender = Color3.fromRGB(230, 230, 250), Navy = Color3.fromRGB(0, 0, 128), Magenta = Color3.fromRGB(255, 0, 255), Olive = Color3.fromRGB(128, 128, 0), Maroon = Color3.fromRGB(128, 0, 0), Silver = Color3.fromRGB(192, 192, 192), Turquoise = Color3.fromRGB(64, 224, 208), Gold = Color3.fromRGB(255, 215, 0), Coral = Color3.fromRGB(255, 127, 80), ["Sky Blue"] = Color3.fromRGB(135, 206, 235), ["Slate Gray"] = Color3.fromRGB(112, 128, 144), White = Color3.fromRGB(255, 255, 255) };
L_463 = function(L_461, ...)
    local L_462 = typeof;
    if L_462 then
        L_462 = typeof(L_461) == "Color3";
    end;
    if not L_462 then
        if type(L_461) ~= "table" or (not L_461.Color or typeof(L_461.Color) ~= "Color3") then
            if type(L_461) ~= "string" then
                return nil;
            end;
            return L_460[L_461];
        end;
        return L_461.Color;
    end;
    return L_461;
end;
L_468 = function(L_464, L_465, ...)
    local L_466 = L_464;
    local L_467 = L_465;
    if L_466 and L_467 then
        if not L_466:IsA("ParticleEmitter") and (not L_466:IsA("Trail") and not L_466:IsA("Beam")) then
            if not L_466:IsA("PointLight") and (not L_466:IsA("SpotLight") and not L_466:IsA("SurfaceLight")) then
                if L_466:IsA("BillboardGui") or (L_466:IsA("Frame") or L_466:IsA("TextLabel")) then
                end;
                return ;
            end;
            pcall(function(...)
                L_466.Color = L_467;
                return ;
            end);
            return ;
        end;
        pcall(function(...)
            L_466.Color = ColorSequence.new(L_467);
            return ;
        end);
        return ;
    end;
    return ;
end;
L_478 = function(L_469, L_470, ...)
    if L_469 then
        if L_448.DescendantAdded then
            pcall(function(...)
                L_448.DescendantAdded:Disconnect();
                return ;
            end);
            L_448.DescendantAdded = nil;
        end;
        if L_470 then
            local L_471 = { ipairs(L_469:GetDescendants()) };
            local L_472 = L_471[3];
            local L_473 = L_471[1];
            local L_474 = L_471[2];
            while true do
                local L_475;
                L_472, L_475 = L_473(L_474, L_472);
                if not L_472 then
                    break;
                end;
                L_468(L_475, L_470);
            end;
            L_448.DescendantAdded = L_469.DescendantAdded:Connect(function(L_476, ...)
                local L_477 = L_463(L_110.vfxColorChanger);
                if L_477 then
                    L_468(L_476, L_477);
                end;
                return ;
            end);
            return ;
        end;
        return ;
    end;
    return ;
end;
L_482 = function(...)
    if L_448.CharacterAdded then
        pcall(function(...)
            L_448.CharacterAdded:Disconnect();
            return ;
        end);
        L_448.CharacterAdded = nil;
    end;
    if L_448.DescendantAdded then
        pcall(function(...)
            L_448.DescendantAdded:Disconnect();
            return ;
        end);
        L_448.DescendantAdded = nil;
    end;
    local L_479 = L_463(L_110.vfxColorChanger);
    if L_479 then
        if L_106 and L_106.Character then
            L_478(L_106.Character, L_479);
        end;
        L_448.CharacterAdded = L_106.CharacterAdded:Connect(function(L_480, ...)
            local L_481 = L_463(L_110.vfxColorChanger);
            if L_481 then
                L_478(L_480, L_481);
            end;
            return ;
        end);
    end;
    return ;
end;
L_483 = function(...)
    if L_448.CharacterAdded then
        pcall(function(...)
            L_448.CharacterAdded:Disconnect();
            return ;
        end);
        L_448.CharacterAdded = nil;
    end;
    if L_448.DescendantAdded then
        pcall(function(...)
            L_448.DescendantAdded:Disconnect();
            return ;
        end);
        L_448.DescendantAdded = nil;
    end;
    return ;
end;
pcall(function(...)
    L_482();
    return ;
end);
L_495 = function(L_484, L_485, L_486, L_487, ...)
    local L_488 = L_106:FindFirstChild("Backpack");
    if L_488 then
        local L_489 = { ipairs(L_488:GetChildren()) };
        local L_490 = L_489[3];
        local L_491 = L_489[1];
        local L_492 = L_489[2];
        while true do
            local L_493;
            L_490, L_493 = L_491(L_492, L_490);
            if not L_490 then
                break;
            end;
            if L_493.Name == L_484 then
                L_493:Destroy();
            end;
        end;
        local L_494 = Instance.new("Tool");
        L_494.Name = L_484;
        L_494.ToolTip = L_485;
        L_494.RequiresHandle = false;
        L_494.CanBeDropped = false;
        if L_486 then
            L_494.TextureId = L_486;
        end;
        if L_487 then
            L_494.Activated:Connect(L_487);
        end;
        L_494.Parent = L_488;
        return L_494;
    end;
    return ;
end;
L_496 = false;
L_497 = {};
L_498 = L_87.CurrentCamera;
L_501 = function(...)
    local L_499 = L_106.Character;
    local L_500 = L_499;
    if L_499 then
        L_500 = L_499:FindFirstChildOfClass("Humanoid");
    end;
    return L_499, L_500;
end;
L_515 = function(...)
    local L_502 = { L_501() };
    local L_503 = L_502[2];
    local L_504 = L_502[1];
    if L_503 then
        local L_505 = L_503:FindFirstChildOfClass("Animator");
        if L_505 then
            local L_506 = {
                pcall(function(...)
                    return L_505:GetPlayingAnimationTracks();
                end)
            };
            local L_507 = L_506[1];
            local L_508 = L_506[2];
            if L_507 then
                L_507 = L_508;
            end;
            if L_507 then
                local L_509 = { ipairs(L_508) };
                local L_510 = L_509[1];
                local L_511 = L_509[3];
                local L_512 = L_509[2];
                while true do
                    local L_513;
                    L_511, L_513 = L_510(L_512, L_511);
                    if not L_511 then
                        break;
                    end;
                    local L_514 = L_513;
                    pcall(function(...)
                        L_514:Stop();
                        return ;
                    end);
                end;
            end;
        end;
    end;
    return ;
end;
L_525 = function(L_516, ...)
    local L_517 = { L_501() };
    local L_518 = L_517[2];
    local L_519 = L_517[1];
    if L_518 then
        local L_520 = L_518:FindFirstChildOfClass("Animator");
        if not L_520 then
            L_520 = Instance.new("Animator");
            L_520.Parent = L_518;
        end;
        local L_521 = L_497[L_516];
        if not L_521 then
            L_521 = Instance.new("Animation");
            L_521.AnimationId = "rbxassetid://" .. tostring(L_516);
            L_497[L_516] = L_521;
        end;
        local L_522 = {
            pcall(function(...)
                return L_520:LoadAnimation(L_521);
            end)
        };
        local L_523 = L_522[1];
        local L_524 = L_522[2];
        if L_523 and L_524 then
            L_524.Priority = Enum.AnimationPriority.Action;
            L_524:Play();
            pcall(function(...)
                L_524:AdjustSpeed(1.1);
                return ;
            end);
            return L_524;
        end;
        return ;
    end;
    return ;
end;
L_538 = function(L_526, ...)
    local L_527 = L_526;
    if not L_496 then
        L_496 = true;
        local L_528 = { L_501() };
        local L_529 = L_528[2];
        local L_530 = L_528[1];
        if L_530 then
            L_530 = L_530:FindFirstChild("HumanoidRootPart");
        end;
        local L_531 = L_530;
        if L_531 then
            pcall(function(...)
                L_531.CFrame = L_531.CFrame * CFrame.Angles(0, math.rad(L_527), 0);
                local L_532 = L_498 and L_498.CFrame.Position or L_531.Position + Vector3.new(0, 5, 0);
                local L_533 = L_532.Y;
                local L_534 = L_532 - L_531.Position;
                local L_535 = Vector3.new(L_534.X, 0, L_534.Z);
                local L_536 = CFrame.fromAxisAngle(Vector3.yAxis, math.rad(L_527)) * L_535;
                local L_537 = L_531.Position + L_536;
                if L_498 and L_498:IsA("Camera") then
                    L_498.CFrame = CFrame.lookAt(Vector3.new(L_537.X, L_533, L_537.Z), L_531.Position);
                end;
                return ;
            end);
        end;
        L_496 = false;
        return ;
    end;
    return ;
end;
L_546 = function(L_539, L_540, L_541, ...)
    if not L_496 then
        L_496 = true;
        local L_542 = { L_501() };
        local L_543 = L_542[1];
        local L_544 = L_542[2];
        if L_543 then
            L_543 = L_543:FindFirstChild("HumanoidRootPart");
        end;
        if L_543 then
            local L_545 = L_85:Create(L_543, TweenInfo.new(L_541, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = L_543.CFrame * CFrame.new(L_539 * L_540, 0, 0) });
            pcall(function(...)
                L_545:Play();
                return ;
            end);
            if L_545 then
                pcall(function(...)
                    L_545.Completed:Wait();
                    return ;
                end);
            end;
            pcall(function(...)
                L_545:Destroy();
                return ;
            end);
        end;
        L_496 = false;
        return ;
    end;
    return ;
end;
L_557 = function(L_547, L_548, L_549, L_550, L_551, ...)
    if not L_496 then
        L_496 = true;
        local L_552 = { L_501() };
        local L_553 = L_552[2];
        local L_554 = L_552[1];
        if L_554 then
            L_554 = L_554:FindFirstChild("HumanoidRootPart");
        end;
        if L_554 then
            local L_555 = Instance.new("BodyVelocity");
            local L_556 = L_554.CFrame.RightVector * L_547 * L_548 + Vector3.new(0, L_549, 0);
            if L_556.Magnitude == 0 then
                L_556 = Vector3.new(0, 1, 0);
            end;
            L_555.Velocity = L_556.Unit * L_550;
            L_555.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
            L_555.Parent = L_554;
            task.delay(L_551, function(...)
                pcall(function(...)
                    L_555:Destroy();
                    return ;
                end);
                return ;
            end);
        end;
        L_496 = false;
        return ;
    end;
    return ;
end;
L_567 = function(...)
    if not L_86.TouchEnabled then
        pcall(L_515);
        pcall(function(...)
            L_525(10480793962);
            return ;
        end);
        pcall(function(...)
            L_546(1, L_107.m1ResetDistance, 0.24);
            return ;
        end);
        pcall(function(...)
            L_538(L_107.m1ResetRotation);
            return ;
        end);
        task.wait(0.004);
        pcall(function(...)
            L_88:SendKeyEvent(true, Enum.KeyCode.Q, false, game);
            L_88:SendKeyEvent(false, Enum.KeyCode.Q, false, game);
            return ;
        end);
        return ;
    end;
    local L_558 = L_106.Character;
    if L_558 then
        local L_559 = L_558:FindFirstChildOfClass("Humanoid");
        local L_560 = L_68;
        local L_561 = L_558.FindFirstChild;
        local L_562 = L_560[L_81("\1652la;\200(\"\248\136\184\200`\168\145\148", 24639384562897)];
        local L_563 = not L_559;
        local L_564 = L_561(L_558, L_562);
        if not L_563 then
            L_563 = not L_564;
        end;
        if not L_563 then
            local L_565 = Instance.new("Animation");
            L_565.AnimationId = "rbxassetid://10480793962";
            L_559:LoadAnimation(L_565):Play();
            local L_566 = L_85:Create(L_564, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = L_564.CFrame * CFrame.new(1 * L_107.m1ResetDistance, 0, 0) });
            L_566:Play();
            L_566.Completed:Wait();
            L_564.CFrame = L_564.CFrame * CFrame.Angles(0, math.rad(L_107.m1ResetRotation), 0);
            task.wait(0.004);
            L_433(L_558);
            return ;
        end;
        return ;
    end;
    return ;
end;
L_585 = function(L_568, L_569, ...)
    if L_110.supa then
        if L_568 and L_569 then
            local L_570 = L_568:FindFirstChild("HumanoidRootPart");
            local L_571 = L_569:FindFirstChild("HumanoidRootPart");
            if L_570 and L_571 then
                task.wait(L_107.supaDelay);
                if L_110.supa then
                    L_433(L_568);
                    task.wait(0.02);
                    local L_572 = L_571.Position;
                    local L_573 = Vector3.new(L_572.X, L_572.Y - L_107.underOffset, L_572.Z);
                    local L_574 = L_572 - L_570.Position;
                    if L_574.Magnitude == 0 then
                        L_574 = Vector3.new(0, 0, 1);
                    end;
                    local L_575 = L_574.Unit;
                    local L_576 = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5);
                    if L_576.Magnitude == 0 then
                        L_576 = Vector3.new(0.1, 0, 0);
                    end;
                    local L_577 = L_107.supaLockPercent / 100;
                    local L_578 = (L_575 * L_577 + L_576.Unit * (1 - L_577)).Unit;
                    local L_579 = L_572 + Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit * L_107.supaRandomMovement;
                    local L_580 = L_85:Create(L_570, TweenInfo.new(0.2 / L_107.supaSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(L_573, L_579) });
                    L_580:Play();
                    L_580.Completed:Wait();
                    if L_107.supaBehindEnabled then
                        local L_581 = L_571.Position - L_570.Position;
                        if L_581.Magnitude == 0 then
                            L_581 = Vector3.new(0, 0, 1);
                        end;
                        local L_582 = L_571.Position - L_581.Unit * L_107.supaBehindOffset;
                        local L_583 = Vector3.new(L_582.X, L_570.Position.Y, L_582.Z);
                        local L_584 = L_85:Create(L_570, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(L_583, L_571.Position) });
                        L_584:Play();
                        L_584.Completed:Wait();
                    end;
                    if L_110.supa then
                        L_433(L_568);
                    end;
                    return ;
                end;
                return ;
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
L_602 = function(L_586, ...)
    local L_587 = L_586;
    if L_111.supa then
        L_111.supa:Disconnect();
        L_111.supa = nil;
    end;
    if L_110.supa then
        local L_588 = L_587:FindFirstChild("Humanoid");
        if L_588 then
            local L_589 = false;
            local L_590 = false;
            local L_591 = false;
            L_111.supa = L_84.Heartbeat:Connect(function(...)
                local L_592 = false;
                if L_587.Parent then
                    if L_587:FindFirstChild("HumanoidRootPart") then
                        local L_593 = false;
                        local L_594 = { ipairs(L_588:GetPlayingAnimationTracks()) };
                        local L_595 = L_594[3];
                        local L_596 = L_594[2];
                        local L_597 = L_594[1];
                        repeat
                            local L_598;
                            L_595, L_598 = L_597(L_596, L_595);
                            if not L_595 then
                                L_592 = true;
                            end;
                            if L_592 then
                                break;
                            end;
                        until L_598.Animation and L_109[L_598.Animation.AnimationId];
                        if not L_592 then
                            L_593 = true;
                        end;
                        L_592 = false;
                        local L_599 = L_593;
                        if L_593 then
                            L_599 = not L_589 and (not L_590 and not L_591);
                        end;
                        if not L_599 then
                            if not L_593 then
                                L_590 = false;
                            end;
                        else
                            L_589 = true;
                            L_590 = true;
                            L_591 = true;
                            task.spawn(function(...)
                                task.wait(L_107.detectBuffer);
                                task.wait(L_107.extraDelay);
                                local L_600 = L_429(L_587, 50);
                                local L_601 = L_600;
                                if L_600 then
                                    L_601 = L_110.supa;
                                end;
                                if L_601 then
                                    L_585(L_587, L_600);
                                end;
                                L_589 = false;
                                task.delay(L_107.cooldown, function(...)
                                    L_591 = false;
                                    return ;
                                end);
                                return ;
                            end);
                        end;
                        return ;
                    end;
                    return ;
                end;
                return ;
            end);
            return ;
        end;
        return ;
    end;
    return ;
end;
L_615 = function(L_603, L_604, ...)
    if L_110.supaV2 then
        if L_603 and L_604 then
            local L_605 = L_603:FindFirstChild("HumanoidRootPart");
            local L_606 = L_604:FindFirstChild("HumanoidRootPart");
            if L_605 and L_606 then
                task.wait(L_107.supaV2Delay);
                if L_110.supaV2 then
                    L_433(L_603);
                    task.wait(0.02);
                    local L_607 = L_606.Position;
                    local L_608 = math.rad(math.random(-L_107.supaV2RandomAngle, L_107.supaV2RandomAngle));
                    local L_609 = (L_607 - L_605.Position).Unit;
                    local L_610 = Vector3.new(-L_609.Z, 0, L_609.X);
                    local L_611 = L_609 * math.cos(L_608) + L_610 * math.sin(L_608);
                    local L_612 = L_606.Position + L_611 * L_107.supaV2TeleportDistance;
                    local L_613 = Vector3.new(L_612.X, L_607.Y - L_107.underOffset, L_612.Z);
                    local L_614 = L_85:Create(L_605, TweenInfo.new(0.2 / L_107.supaV2Speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(L_613, L_607) });
                    L_614:Play();
                    L_614.Completed:Wait();
                    if L_110.supaV2 then
                        L_433(L_603);
                    end;
                    return ;
                end;
                return ;
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
L_632 = function(L_616, ...)
    local L_617 = L_616;
    if L_111.supaV2 then
        L_111.supaV2:Disconnect();
        L_111.supaV2 = nil;
    end;
    if L_110.supaV2 then
        local L_618 = L_617:FindFirstChild("Humanoid");
        if L_618 then
            local L_619 = false;
            local L_620 = false;
            local L_621 = false;
            L_111.supaV2 = L_84.Heartbeat:Connect(function(...)
                local L_622 = false;
                if L_617.Parent then
                    if L_617:FindFirstChild("HumanoidRootPart") then
                        local L_623 = false;
                        local L_624 = { ipairs(L_618:GetPlayingAnimationTracks()) };
                        local L_625 = L_624[3];
                        local L_626 = L_624[2];
                        local L_627 = L_624[1];
                        repeat
                            local L_628;
                            L_625, L_628 = L_627(L_626, L_625);
                            if not L_625 then
                                L_622 = true;
                            end;
                            if L_622 then
                                break;
                            end;
                        until L_628.Animation and L_109[L_628.Animation.AnimationId];
                        if not L_622 then
                            L_623 = true;
                        end;
                        L_622 = false;
                        local L_629 = L_623;
                        if L_623 then
                            L_629 = not L_619 and (not L_620 and not L_621);
                        end;
                        if not L_629 then
                            if not L_623 then
                                L_620 = false;
                            end;
                        else
                            L_619 = true;
                            L_620 = true;
                            L_621 = true;
                            task.spawn(function(...)
                                task.wait(L_107.detectBuffer);
                                task.wait(L_107.extraDelay);
                                local L_630 = L_429(L_617, 50);
                                local L_631 = L_630;
                                if L_630 then
                                    L_631 = L_110.supaV2;
                                end;
                                if L_631 then
                                    L_615(L_617, L_630);
                                end;
                                L_619 = false;
                                task.delay(L_107.cooldown, function(...)
                                    L_621 = false;
                                    return ;
                                end);
                                return ;
                            end);
                        end;
                        return ;
                    end;
                    return ;
                end;
                return ;
            end);
            return ;
        end;
        return ;
    end;
    return ;
end;
L_633 = {};
L_634 = {};
L_635 = {};
L_636 = nil;
L_637 = nil;
L_643 = function(L_638, L_639, ...)
    if L_639 ~= L_106 and not L_633[L_639] then
        local L_640 = L_638:FindFirstChild("Head");
        if L_640 then
            local L_641 = Instance.new("BillboardGui");
            L_641.Size = UDim2.new(0, 140, 0, 24);
            L_641.StudsOffset = Vector3.new(0, 2.2, 0);
            L_641.AlwaysOnTop = true;
            L_641.Adornee = L_640;
            L_641.Parent = L_640;
            local L_642 = Instance.new("TextLabel", L_641);
            L_642.Size = UDim2.new(1, 0, 1, 0);
            L_642.BackgroundTransparency = 1;
            L_642.Text = L_639.Name;
            L_642.TextColor3 = Color3.fromRGB(170, 240, 240);
            L_642.TextStrokeTransparency = 0.5;
            L_642.TextScaled = true;
            L_642.Font = Enum.Font.GothamBold;
            L_633[L_639] = L_641;
            return ;
        end;
        return ;
    end;
    return ;
end;
L_645 = function(L_644, ...)
    if L_633[L_644] then
        L_633[L_644]:Destroy();
    end;
    L_633[L_644] = nil;
    return ;
end;
L_649 = function(L_646, L_647, ...)
    if L_647 ~= L_106 and not L_634[L_647] then
        local L_648 = Instance.new("Highlight");
        L_648.FillTransparency = 1;
        L_648.OutlineTransparency = 0;
        L_648.OutlineColor = Color3.fromRGB(255, 80, 80);
        L_648.Adornee = L_646;
        L_648.Parent = L_646;
        L_634[L_647] = L_648;
        return ;
    end;
    return ;
end;
L_651 = function(L_650, ...)
    if L_634[L_650] then
        L_634[L_650]:Destroy();
    end;
    L_634[L_650] = nil;
    return ;
end;
L_656 = function(L_652, L_653, ...)
    if L_653 ~= L_106 and not L_635[L_653] then
        local L_654 = L_652:FindFirstChild("HumanoidRootPart");
        if L_654 then
            local L_655 = Instance.new("BoxHandleAdornment");
            L_655.Adornee = L_654;
            L_655.AlwaysOnTop = true;
            L_655.ZIndex = 5;
            L_655.Size = Vector3.new(2, 2, 1);
            L_655.Color3 = Color3.fromRGB(170, 0, 255);
            L_655.Transparency = 0.45;
            L_655.Parent = L_654;
            L_635[L_653] = L_655;
            return ;
        end;
        return ;
    end;
    return ;
end;
L_658 = function(L_657, ...)
    if L_635[L_657] then
        L_635[L_657]:Destroy();
    end;
    L_635[L_657] = nil;
    return ;
end;
L_660 = function(...)
    if not L_636 then
        L_636 = Instance.new("ScreenGui");
        L_636.ResetOnSpawn = false;
        L_636.Parent = L_106:WaitForChild("PlayerGui");
        local L_659 = Instance.new("TextLabel", L_636);
        L_659.Size = UDim2.new(0, 180, 0, 36);
        L_659.Position = UDim2.new(1, -190, 0, 10);
        L_659.BackgroundTransparency = 0.35;
        L_659.BackgroundColor3 = Color3.fromRGB(20, 20, 20);
        L_659.TextColor3 = Color3.fromRGB(0, 255, 200);
        L_659.Font = Enum.Font.GothamBold;
        L_659.TextSize = 18;
        L_637 = L_84.RenderStepped:Connect(function(...)
            L_659.Text = "Players: " .. #L_83:GetPlayers();
            return ;
        end);
        return ;
    end;
    return ;
end;
L_661 = function(...)
    if L_637 then
        L_637:Disconnect();
    end;
    if L_636 then
        L_636:Destroy();
    end;
    L_636 = nil;
    L_637 = nil;
    return ;
end;
L_667 = function(...)
    local L_662 = { ipairs(L_83:GetPlayers()) };
    local L_663 = L_662[3];
    local L_664 = L_662[2];
    local L_665 = L_662[1];
    while true do
        local L_666;
        L_663, L_666 = L_665(L_664, L_663);
        if not L_663 then
            break;
        end;
        if L_666 ~= L_106 then
            if not L_110.espName or not L_666.Character then
                L_645(L_666);
            else
                L_643(L_666.Character, L_666);
            end;
            if not L_110.espHighlight or not L_666.Character then
                L_651(L_666);
            else
                L_649(L_666.Character, L_666);
            end;
            if not L_110.espHRPBox or not L_666.Character then
                L_658(L_666);
            else
                L_656(L_666.Character, L_666);
            end;
        end;
    end;
    if not L_110.espPlayerCount then
        L_661();
    else
        L_660();
    end;
    return ;
end;
L_83.PlayerAdded:Connect(function(L_668, ...)
    L_668.CharacterAdded:Connect(function(...)
        L_667();
        return ;
    end);
    return ;
end);
L_83.PlayerRemoving:Connect(function(L_669, ...)
    L_645(L_669);
    L_651(L_669);
    L_658(L_669);
    return ;
end);
L_720 = function(L_670, L_671, ...)
    local L_672 = L_670;
    local L_673 = L_671;
    if L_110.loop then
        if L_672 and L_673 then
            local L_674 = L_672:FindFirstChild("HumanoidRootPart");
            local L_675 = L_673:FindFirstChild("HumanoidRootPart");
            if L_674 and L_675 then
                task.wait(L_107.loopDelay);
                if L_110.loop then
                    local L_684 = function(L_676, L_677, ...)
                        local L_678 = RaycastParams.new();
                        L_678.FilterType = Enum.RaycastFilterType.Blacklist;
                        local L_679 = "FilterDescendantsInstances";
                        if not L_677 then
                            L_677 = {};
                        end;
                        L_678[L_679] = L_677;
                        local L_680 = L_676 + Vector3.new(0, 80, 0);
                        local L_681 = Vector3.new(0, -300, 0);
                        local L_682 = L_87:Raycast(L_680, L_681, L_678);
                        local L_683 = L_682;
                        if L_682 then
                            L_683 = L_682.Position;
                        end;
                        if not L_683 then
                            return L_676.Y;
                        end;
                        return L_682.Position.Y;
                    end;
                    local L_685 = L_684(L_674.Position, { L_672 });
                    local L_686 = math.min(L_674.Position.Y - L_685, L_107.loopMaxHeight);
                    if L_686 < 0.5 then
                        L_686 = 2;
                    end;
                    pcall(function(...)
                        L_433(L_672);
                        return ;
                    end);
                    local L_687 = tick();
                    local L_688 = L_687 + 0.5;
                    local L_689 = math.pi * 2;
                    local L_690 = L_674.Position - L_675.Position;
                    local L_691 = math.atan2(L_690.Z, L_690.X);
                    local L_692 = tick() - L_107.loopDashInterval;
                    local L_693 = math.random() * 1000;
                    local L_694 = nil;
                    L_694 = L_84.Heartbeat:Connect(function(...)
                        if L_110.loop and (L_672.Parent and (L_673.Parent and (L_674.Parent and L_675.Parent))) then
                            local L_695 = tick();
                            if not (L_695 >= L_688) then
                                local L_696 = L_695 - L_687;
                                local L_697 = math.clamp(L_696 / 0.5, 0, 1);
                                local L_698 = L_691 + L_689 * L_697;
                                local L_699 = L_675.Position;
                                local L_700 = math.sin((L_697 * 12 + L_693) * math.pi * 2) * 0.12;
                                local L_701 = math.cos((L_697 * 9 + L_693 * 0.7) * math.pi * 2) * 0.09;
                                local L_702 = L_107.loopRadius + math.sin((L_697 * 6 + L_693) * 1.7) * 0.35;
                                local L_703 = Vector3.new(math.cos(L_698), 0, math.sin(L_698)) * L_702 + Vector3.new(L_700, 0, L_701);
                                local L_704 = L_684(L_699, { L_672, L_673 }) + math.min(L_686, L_107.loopMaxHeight);
                                local L_705 = Vector3.new(L_699.X + L_703.X, L_704, L_699.Z + L_703.Z);
                                local L_706 = L_698 + L_689 / L_107.loopSteps;
                                local L_707 = Vector3.new(math.cos(L_706), 0, math.sin(L_706)) * L_702 + Vector3.new(L_700, 0, L_701);
                                local L_708 = Vector3.new(L_699.X + L_707.X, L_704, L_699.Z + L_707.Z);
                                L_674.CFrame = CFrame.new(L_705, L_708);
                                if L_695 - L_692 >= L_107.loopDashInterval then
                                    L_692 = L_695;
                                    pcall(function(...)
                                        L_433(L_672);
                                        return ;
                                    end);
                                end;
                                return ;
                            end;
                            if L_694 then
                                L_694:Disconnect();
                            end;
                            local L_709 = L_675.Position;
                            local L_710 = L_684(L_709, { L_672, L_673 }) + math.min(L_686, L_107.loopMaxHeight);
                            local L_711 = Vector3.new(L_709.X, L_710, L_709.Z);
                            local L_712 = CFrame.new(L_711, L_709 + Vector3.new(0, 0.1, 0));
                            local L_713 = L_85:Create(L_674, TweenInfo.new(L_107.loopSettleTime, Enum.EasingStyle.Quad), { CFrame = L_712 });
                            L_713:Play();
                            L_713.Completed:Wait();
                            local L_714 = Instance.new("BodyPosition");
                            L_714.MaxForce = Vector3.new(100000, 100000, 100000);
                            L_714.P = 10000;
                            L_714.D = 100;
                            L_714.Position = L_711;
                            L_714.Parent = L_674;
                            local L_715 = Instance.new("BodyGyro");
                            L_715.MaxTorque = Vector3.new(100000, 100000, 100000);
                            L_715.P = 5000;
                            L_715.D = 100;
                            L_715.CFrame = L_712;
                            L_715.Parent = L_674;
                            local L_716 = nil;
                            L_716 = L_84.Heartbeat:Connect(function(...)
                                if L_715.Parent and (L_675.Parent and L_674.Parent) then
                                    local L_717 = L_674.CFrame.LookVector;
                                    local L_718 = L_675.Position - L_674.Position;
                                    if L_718.Magnitude > 0 then
                                        L_718 = L_718.Unit;
                                    end;
                                    local L_719 = L_717 + L_718;
                                    if L_719.Magnitude > 0 then
                                        L_715.CFrame = CFrame.new(L_674.Position, L_674.Position + L_719.Unit);
                                    end;
                                    return ;
                                end;
                                if L_716 then
                                    L_716:Disconnect();
                                end;
                                return ;
                            end);
                            task.delay(L_107.loopSettleHold, function(...)
                                if L_716 then
                                    L_716:Disconnect();
                                end;
                                if L_714.Parent then
                                    L_714:Destroy();
                                end;
                                if L_715.Parent then
                                    L_715:Destroy();
                                end;
                                return ;
                            end);
                            return ;
                        end;
                        if L_694 then
                            L_694:Disconnect();
                        end;
                        return ;
                    end);
                    return ;
                end;
                return ;
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
L_745 = function(L_721, ...)
    local L_722 = L_721;
    if L_111.loop then
        L_111.loop:Disconnect();
        L_111.loop = nil;
    end;
    if L_110.loop then
        local L_723 = L_722:FindFirstChild("Humanoid");
        if L_723 then
            local L_724 = false;
            local L_725 = false;
            local L_726 = false;
            L_111.loop = L_84.Heartbeat:Connect(function(...)
                local L_727 = false;
                if L_722.Parent then
                    if L_722:FindFirstChild("HumanoidRootPart") then
                        local L_728 = false;
                        local L_729 = { ipairs(L_723:GetPlayingAnimationTracks()) };
                        local L_730 = L_729[2];
                        local L_731 = L_729[1];
                        local L_732 = L_729[3];
                        repeat
                            local L_733;
                            L_732, L_733 = L_731(L_730, L_732);
                            if not L_732 then
                                L_727 = true;
                            end;
                            if L_727 then
                                break;
                            end;
                        until L_733.Animation and L_109[L_733.Animation.AnimationId];
                        if not L_727 then
                            L_728 = true;
                        end;
                        L_727 = false;
                        if L_728 then
                            L_728 = not L_724 and (not L_725 and not L_726);
                        end;
                        if not L_728 then
                            L_725 = false;
                        else
                            L_724 = true;
                            L_725 = true;
                            L_726 = true;
                            task.spawn(function(...)
                                local L_734 = false;
                                task.wait(L_107.detectBuffer);
                                task.wait(0.045);
                                local L_735 = 0;
                                local L_736 = 0.01;
                                repeat
                                    if not (L_735 < L_107.loopDelay) then
                                        local L_737 = L_429(L_722, L_107.loopMinTargetDist);
                                        local L_738 = L_737;
                                        if L_737 then
                                            L_738 = L_110.loop;
                                        end;
                                        if L_738 then
                                            L_720(L_722, L_737);
                                        end;
                                        L_724 = false;
                                        task.delay(L_107.cooldown, function(...)
                                            L_726 = false;
                                            return ;
                                        end);
                                        return ;
                                    end;
                                    task.wait(L_736);
                                    L_735 = L_735 + L_736;
                                    if not L_110.loop then
                                        L_724 = false;
                                        return ;
                                    end;
                                    local L_739 = false;
                                    local L_740 = { ipairs(L_723:GetPlayingAnimationTracks()) };
                                    local L_741 = L_740[2];
                                    local L_742 = L_740[1];
                                    local L_743 = L_740[3];
                                    repeat
                                        local L_744;
                                        L_743, L_744 = L_742(L_741, L_743);
                                        if not L_743 then
                                            L_734 = true;
                                        end;
                                        if L_734 then
                                            break;
                                        end;
                                    until L_744.Animation and L_109[L_744.Animation.AnimationId];
                                    if not L_734 then
                                        L_739 = true;
                                    end;
                                    L_734 = false;
                                until not L_739;
                                L_724 = false;
                                return ;
                            end);
                        end;
                        return ;
                    end;
                    return ;
                end;
                return ;
            end);
            return ;
        end;
        return ;
    end;
    return ;
end;
L_754 = function(...)
    if L_110.lethal then
        local L_746 = Enum;
        local L_747 = L_68;
        local L_748 = L_81;
        local L_750 = function(L_749, ...)
            L_88:SendKeyEvent(true, L_749, false, game);
            task.wait(0.05);
            L_88:SendKeyEvent(false, L_749, false, game);
            return ;
        end;
        L_750(L_746[L_747[L_748("\225z\030^\017\239d", 20804569376215)]].Two);
        task.wait(2.2);
        L_750(Enum.KeyCode.Space);
        local L_751 = L_106.Character or L_106.CharacterAdded:Wait();
        local L_752 = L_751:FindFirstChildOfClass("Humanoid");
        if L_752 then
            L_752:ChangeState(Enum.HumanoidStateType.Jumping);
        end;
        L_750(Enum.KeyCode.Q);
        task.wait(0.25);
        local L_753 = L_751:FindFirstChild("HumanoidRootPart");
        if L_753 then
            L_753.CFrame = L_753.CFrame * CFrame.Angles(0, math.rad(180), 0);
        end;
        task.wait(0.25);
        if L_753 then
            L_753.CFrame = L_753.CFrame * CFrame.Angles(0, math.rad(180), 0);
        end;
        return ;
    end;
    return ;
end;
L_755 = "rbxassetid://12273188754";
KAKYO_DETECT_ANIM = L_755;
L_756 = "rbxassetid://10480793962";
KAKYO_KYOTO_ANIM = L_756;
KAKYO_safeSendKey = function(L_757, ...)
    local L_758 = L_757;
    pcall(function(...)
        if not L_88 or type(L_88.SendKeyEvent) ~= "function" then
            local L_759 = rawget(_G, "syn");
            if not L_759 or type(L_759.virtual_input) ~= "function" then
                local L_760 = nil;
                pcall(function(...)
                    L_760 = game:GetService("VirtualUser");
                    return ;
                end);
                if not L_760 or type(L_760.SetKeyDown) ~= "function" then
                    return ;
                end;
                pcall(function(...)
                    L_760:SetKeyDown(tostring(L_758));
                    L_760:SetKeyUp(tostring(L_758));
                    return ;
                end);
                return ;
            end;
            pcall(function(...)
                L_759.virtual_input(L_758, true);
                L_759.virtual_input(L_758, false);
                return ;
            end);
            return ;
        end;
        L_88:SendKeyEvent(true, L_758, false, game);
        L_88:SendKeyEvent(false, L_758, false, game);
        return ;
    end);
    return ;
end;
KAKYO_stopAllAnimations = function(L_761, ...)
    local L_762 = L_761;
    pcall(function(...)
        local L_763 = { ipairs(L_762:GetPlayingAnimationTracks()) };
        local L_764 = L_763[3];
        local L_765 = L_763[1];
        local L_766 = L_763[2];
        while true do
            local L_767;
            L_764, L_767 = L_765(L_766, L_764);
            if not L_764 then
                break;
            end;
            L_767:Stop();
        end;
        return ;
    end);
    return ;
end;
KAKYO_performSingleMove = function(L_768, L_769, L_770, L_771, L_772, ...)
    local L_773 = L_768;
    if L_773 and L_773.Parent then
        local L_774 = L_773.Position + L_769 * L_771;
        local L_775, L_776 = CFrame.new(L_774, L_774 + L_770), not L_772;
        if not L_776 then
            L_776 = L_772 <= 0.05;
        end;
        if not L_776 then
            local L_777 = TweenInfo.new(L_772, Enum.EasingStyle.Linear, Enum.EasingDirection.Out);
            local L_778 = L_85:Create(L_773, L_777, { CFrame = L_775 });
            local L_779 = false;
            local L_780 = nil;
            L_780 = L_778.Completed:Connect(function(...)
                L_779 = true;
                if L_780 then
                    L_780:Disconnect();
                    L_780 = nil;
                end;
                return ;
            end);
            L_778:Play();
            while not L_779 do
                L_84.Heartbeat:Wait();
            end;
            pcall(function(...)
                if L_773 and L_773.Parent then
                    L_773.CFrame = L_775;
                end;
                return ;
            end);
            return ;
        end;
        pcall(function(...)
            if L_773 and L_773.Parent then
                L_773.CFrame = L_775;
            end;
            return ;
        end);
        return ;
    end;
    return ;
end;
KAKYO_DoKyoto = function(...)
    if not kakyoDoKyotoRunning then
        kakyoDoKyotoRunning = true;
        local L_799 = {
            pcall(function(...)
                local L_781 = L_106.Character;
                if L_781 then
                    local L_782 = L_781:FindFirstChildOfClass("Humanoid");
                    if L_781 then
                        L_781 = L_781:FindFirstChild("HumanoidRootPart");
                    end;
                    local L_783 = L_781;
                    if L_782 and L_783 then
                        pcall(function(...)
                            KAKYO_safeSendKey(Enum.KeyCode.One);
                            return ;
                        end);
                        pcall(function(...)
                            KAKYO_stopAllAnimations(L_782);
                            return ;
                        end);
                        local L_784 = Instance.new("Animation");
                        L_784.AnimationId = KAKYO_KYOTO_ANIM;
                        local L_785 = L_782:LoadAnimation(L_784);
                        pcall(function(...)
                            L_785:Play();
                            return ;
                        end);
                        local L_786 = L_782.AutoRotate;
                        if L_786 ~= false then
                            pcall(function(...)
                                L_782.AutoRotate = false;
                                return ;
                            end);
                        end;
                        if kakyoDoKyotoWatcher then
                            pcall(function(...)
                                kakyoDoKyotoWatcher:Disconnect();
                                return ;
                            end);
                            kakyoDoKyotoWatcher = nil;
                        end;
                        if L_782.GetPropertyChangedSignal then
                            local L_787 = L_782:GetPropertyChangedSignal("AutoRotate"):Connect(function(...)
                                if L_782.AutoRotate == true then
                                    pcall(function(...)
                                        L_782.AutoRotate = false;
                                        return ;
                                    end);
                                end;
                                return ;
                            end);
                            kakyoDoKyotoWatcher = L_787;
                        end;
                        spawn(function(...)
                            local L_788 = tonumber(kakyoAutoRotateLockTime) or 0.5;
                            local L_789 = tick();
                            while tick() - L_789 < L_788 do
                                if not L_782 or not L_782.Parent then
                                    return ;
                                end;
                                L_84.Heartbeat:Wait();
                            end;
                            pcall(function(...)
                                if kakyoDoKyotoWatcher then
                                    kakyoDoKyotoWatcher:Disconnect();
                                    kakyoDoKyotoWatcher = nil;
                                end;
                                if L_782 and L_782.Parent then
                                    L_782.AutoRotate = L_786;
                                end;
                                return ;
                            end);
                            return ;
                        end);
                        local L_790 = L_783.CFrame.LookVector;
                        local L_791 = Vector3.new(L_790.X, 0, L_790.Z);
                        if L_791.Magnitude == 0 then
                            L_791 = Vector3.new(0, 0, 1);
                        end;
                        local L_792 = L_791.Unit;
                        local L_793 = L_783.CFrame.RightVector;
                        local L_794 = Vector3.new(L_793.X, 0, L_793.Z);
                        if L_794.Magnitude == 0 then
                            L_794 = Vector3.new(1, 0, 0);
                        end;
                        local L_795 = L_794.Unit;
                        local L_796 = tonumber(kakyoMoveDuration) or 0.2;
                        local L_797 = tonumber(kakyoDistance) or 20;
                        local L_798 = coroutine.create(function(...)
                            KAKYO_performSingleMove(L_783, L_792, L_795, L_797, L_796);
                            return ;
                        end);
                        coroutine.resume(L_798);
                        pcall(function(...)
                            KAKYO_safeSendKey(Enum.KeyCode.Two);
                            return ;
                        end);
                        while coroutine.status(L_798) ~= "dead" do
                            L_84.Heartbeat:Wait();
                        end;
                        return ;
                    end;
                    return ;
                end;
                return ;
            end)
        };
        local L_800 = L_799[1];
        local L_801 = L_799[2];
        if not L_800 then
            warn("", L_801);
        end;
        kakyoDoKyotoRunning = false;
        return ;
    end;
    return ;
end;
KAKYO_findToolByName = function(L_802, ...)
    local L_803 = L_106:FindFirstChild("Backpack");
    if L_803 then
        local L_804 = L_803:FindFirstChild(L_802);
        if L_804 then
            return L_804;
        end;
    end;
    local L_805 = L_106.Character;
    if L_805 then
        local L_806 = L_805:FindFirstChild(L_802);
        if L_806 then
            return L_806;
        end;
    end;
    return nil;
end;
KAKYO_DetectorHeartbeat = function(...)
    if kakyoAutoEnabled then
        local L_807 = L_106.Character;
        if L_807 then
            local L_808 = L_807:FindFirstChildOfClass("Humanoid");
            if L_808 then
                local L_809 = { pairs(L_808:GetPlayingAnimationTracks()) };
                local L_810 = L_809[1];
                local L_811 = L_809[2];
                local L_812 = L_809[3];
                repeat
                    local L_813;
                    L_812, L_813 = L_810(L_811, L_812);
                    if not L_812 then
                        return ;
                    end;
                until L_813.Animation and (L_813.Animation.AnimationId == KAKYO_DETECT_ANIM and not kakyoDetected);
                kakyoDetected = true;
                task.delay(3, function(...)
                    kakyoDetected = false;
                    return ;
                end);
                task.spawn(function(...)
                    local L_814 = tick();
                    while tick() - L_814 < 1.4 do
                        if not kakyoAutoEnabled then
                            return ;
                        end;
                        L_84.Heartbeat:Wait();
                    end;
                    if kakyoAutoEnabled then
                        local L_815 = tick();
                        while tick() - L_815 < 0.1 do
                            if not kakyoAutoEnabled then
                                return ;
                            end;
                            L_84.Heartbeat:Wait();
                        end;
                        if kakyoAutoEnabled then
                            local L_816 = KAKYO_findToolByName("Lethal Whirlwind Stream");
                            local L_817 = tonumber(kakyoStartDelay) or 0;
                            local L_818 = tick();
                            while tick() - L_818 < L_817 do
                                if not kakyoAutoEnabled then
                                    return ;
                                end;
                                L_84.Heartbeat:Wait();
                            end;
                            if L_816 then
                                local L_819 = L_106.Character and L_106.Character:FindFirstChild("Communicate");
                                if L_819 and L_819.FireServer then
                                    pcall(function(...)
                                        L_819:FireServer({ Tool = L_816, Goal = "Console Move" });
                                        return ;
                                    end);
                                end;
                            end;
                            if kakyoAutoEnabled and not kakyoDoKyotoRunning then
                                pcall(function(...)
                                    KAKYO_DoKyoto();
                                    return ;
                                end);
                            end;
                            return ;
                        end;
                        return ;
                    end;
                    return ;
                end);
                return ;
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
KAKYO_Start = function(...)
    if kakyoHeartbeatConn then
        pcall(function(...)
            kakyoHeartbeatConn:Disconnect();
            return ;
        end);
        kakyoHeartbeatConn = nil;
    end;
    local L_820 = L_84.Heartbeat:Connect(KAKYO_DetectorHeartbeat);
    kakyoHeartbeatConn = L_820;
    kakyoAutoEnabled = true;
    return ;
end;
KAKYO_Stop = function(...)
    if kakyoHeartbeatConn then
        pcall(function(...)
            kakyoHeartbeatConn:Disconnect();
            return ;
        end);
        kakyoHeartbeatConn = nil;
    end;
    if kakyoDoKyotoWatcher then
        pcall(function(...)
            kakyoDoKyotoWatcher:Disconnect();
            return ;
        end);
        kakyoDoKyotoWatcher = nil;
    end;
    kakyoAutoEnabled = false;
    return ;
end;
if kakyoAutoEnabled then
    KAKYO_Start();
end;
L_821 = function(...)
    if L_110.instantTwisted then
        pcall(function(...)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/InstantTwistedRevamp/main/Protected_7455521176683315.lua"))();
            return ;
        end);
        return ;
    end;
    return ;
end;
L_822 = {};
L_823 = { ["rbxassetid://10479335397"] = true, ["rbxassetid://13380255751"] = true, ["rbxassetid://134775406437626"] = true };
L_824 = { ["rbxassetid://10469493270"] = true, ["rbxassetid://10469630950"] = true, ["rbxassetid://10469639222"] = true, ["rbxassetid://10469643643"] = true };
L_828 = function(L_825, L_826, L_827, ...)
    return (L_825 - L_826).Magnitude <= L_827;
end;
L_831 = function(...)
    local L_829 = L_106.Backpack:FindFirstChild("Prey's Peril");
    if L_829 then
        L_106.Character.Communicate:FireServer({ Tool = L_829, Goal = "Console Move" });
    end;
    local L_830 = L_106.Backpack:FindFirstChild("Split Second Counter");
    if L_830 then
        L_106.Character.Communicate:FireServer({ Tool = L_830, Goal = "Console Move" });
    end;
    return ;
end;
setupAutoCounter = function(...)
    if L_111.autoCounter then
        L_111.autoCounter:Disconnect();
        L_111.autoCounter = nil;
    end;
    L_111.autoCounter = L_84.Heartbeat:Connect(function(...)
        if L_110.autoCounter then
            local L_832 = L_106.Character;
            if L_832 and L_832:FindFirstChild("HumanoidRootPart") then
                local L_833 = L_832.HumanoidRootPart;
                local L_834 = { pairs(workspace.Live:GetChildren()) };
                local L_835 = L_834[2];
                local L_836 = L_834[3];
                local L_837 = L_834[1];
                while true do
                    local L_838;
                    L_836, L_838 = L_837(L_835, L_836);
                    if not L_836 then
                        break;
                    end;
                    if L_838:IsA("Model") and (L_838 ~= L_832 and L_838:FindFirstChild("HumanoidRootPart")) then
                        local L_839 = L_838:FindFirstChildOfClass("Humanoid");
                        if L_839 then
                            L_839 = L_839:FindFirstChildOfClass("Animator");
                        end;
                        if L_839 then
                            local L_840 = L_839.GetPlayingAnimationTracks;
                            local L_841 = { pairs(L_840(L_839)) };
                            local L_842 = L_841[3];
                            local L_843 = L_841[2];
                            local L_844 = L_841[1];
                            while true do
                                local L_845;
                                L_842, L_845 = L_844(L_843, L_842);
                                if not L_842 then
                                    break;
                                end;
                                local L_846 = L_845.Animation.AnimationId;
                                local L_847 = L_838:GetDebugId() .. L_846;
                                local L_848 = L_107.autoCounterDistance or 13;
                                if not L_823[L_846] and not L_824[L_846] or not L_828(L_833.Position, L_838.HumanoidRootPart.Position, L_848) then
                                    L_822[L_847] = nil;
                                elseif not L_822[L_847] then
                                    L_822[L_847] = true;
                                    if not L_823[L_846] then
                                        L_831();
                                    else
                                        task.delay(0.0001, L_831);
                                    end;
                                end;
                            end;
                        end;
                    end;
                end;
                return ;
            end;
            return ;
        end;
        return ;
    end);
    return ;
end;
yoyoAlignPos = nil;
yoyoAlignOri = nil;
yoyoRenderConn = nil;
yoyoTargetOffsetPart = nil;
yoyoCooldown = false;
yoyoDetach = function(...)
    if yoyoAlignPos then
        yoyoAlignPos:Destroy();
        yoyoAlignPos = nil;
    end;
    if yoyoAlignOri then
        yoyoAlignOri:Destroy();
        yoyoAlignOri = nil;
    end;
    if yoyoRenderConn then
        yoyoRenderConn:Disconnect();
        yoyoRenderConn = nil;
    end;
    if yoyoTargetOffsetPart then
        yoyoTargetOffsetPart:Destroy();
        yoyoTargetOffsetPart = nil;
    end;
    local L_849 = L_106.Character;
    char = L_849;
    if char then
        local L_850 = char:FindFirstChild("HumanoidRootPart");
        hrp = L_850;
        if hrp then
            local L_851 = { ipairs(hrp:GetChildren()) };
            local L_852 = L_851[2];
            local L_853 = L_851[1];
            local L_854 = L_851[3];
            while true do
                local L_855;
                L_854, L_855 = L_853(L_852, L_854);
                if not L_854 then
                    break;
                end;
                if L_855:IsA("Attachment") or L_855.Name == "HasSnapped" then
                    L_855:Destroy();
                end;
            end;
        end;
    end;
    return ;
end;
yoyoAttach = function(L_856, ...)
    local L_857 = L_856;
    yoyoDetach();
    if L_106.Character then
        local L_858 = Instance.new("Part");
        yoyoTargetOffsetPart = L_858;
        yoyoTargetOffsetPart.Size = Vector3.new(0.5, 0.5, 0.5);
        yoyoTargetOffsetPart.Transparency = 1;
        yoyoTargetOffsetPart.Anchored = true;
        yoyoTargetOffsetPart.CanCollide = false;
        yoyoTargetOffsetPart.Name = "YOYOFollowPart";
        yoyoTargetOffsetPart.Parent = L_87;
        local L_859 = L_106.Character:FindFirstChild("HumanoidRootPart");
        hrp = L_859;
        if hrp then
            local L_860 = Instance.new("Attachment", hrp);
            att0 = L_860;
            local L_861 = Instance.new("Attachment", yoyoTargetOffsetPart);
            att1 = L_861;
            local L_862 = Instance.new("Attachment", hrp);
            ori0 = L_862;
            local L_863 = Instance.new("Attachment", yoyoTargetOffsetPart);
            ori1 = L_863;
            local L_864 = Instance.new("AlignPosition");
            yoyoAlignPos = L_864;
            yoyoAlignPos.Attachment0 = att0;
            yoyoAlignPos.Attachment1 = att1;
            yoyoAlignPos.RigidityEnabled = true;
            yoyoAlignPos.Responsiveness = 200;
            yoyoAlignPos.MaxForce = math.huge;
            yoyoAlignPos.Parent = hrp;
            local L_865 = Instance.new("AlignOrientation");
            yoyoAlignOri = L_865;
            yoyoAlignOri.Attachment0 = ori0;
            yoyoAlignOri.Attachment1 = ori1;
            yoyoAlignOri.RigidityEnabled = true;
            yoyoAlignOri.Responsiveness = 200;
            yoyoAlignOri.MaxTorque = math.huge;
            yoyoAlignOri.Parent = hrp;
            local L_868 = L_84.RenderStepped:Connect(function(...)
                if L_110.yoyo and (L_857 and L_857.Parent) then
                    if L_106.Character and hrp.Parent then
                        local L_866 = L_857.CFrame * CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(85), 0, 0);
                        offset = L_866;
                        yoyoTargetOffsetPart.CFrame = offset;
                        if not hrp:FindFirstChild("HasSnapped") then
                            hrp.CFrame = offset;
                            local L_867 = Instance.new("BoolValue");
                            tag = L_867;
                            tag.Name = "HasSnapped";
                            tag.Parent = hrp;
                        end;
                        return ;
                    end;
                    yoyoDetach();
                    return ;
                end;
                yoyoDetach();
                return ;
            end);
            yoyoRenderConn = L_868;
            return ;
        end;
        return ;
    end;
    return ;
end;
yoyoGetClosestValidTarget = function(...)
    local L_869 = L_106.Character;
    char = L_869;
    if char then
        local L_870 = char:FindFirstChild("HumanoidRootPart");
        hrp = L_870;
        if hrp then
            closest = nil;
            local L_871 = L_110.yoyoDistanceLimit;
            shortest = L_871;
            local L_872 = L_87:FindFirstChild("Live");
            live = L_872;
            if live then
                local L_873 = { pairs(live:GetChildren()) };
                local L_874 = L_873[3];
                local L_875 = L_873[2];
                local L_876 = L_873[1];
                while true do
                    local L_877;
                    L_874, L_877 = L_876(L_875, L_874);
                    if not L_874 then
                        break;
                    end;
                    if L_877:IsA("Model") and L_877 ~= char then
                        local L_878 = L_877:FindFirstChild("HumanoidRootPart");
                        targetHRP = L_878;
                        local L_879 = L_877:FindFirstChildOfClass("Humanoid");
                        hum = L_879;
                        if targetHRP and (hum and hum.Health > 0) then
                            local L_880 = (targetHRP.Position - hrp.Position).Magnitude;
                            dist = L_880;
                            if dist <= shortest and (L_877.Name == "Weakest Dummy" or L_83:GetPlayerFromCharacter(L_877)) then
                                local L_881 = targetHRP;
                                closest = L_881;
                                local L_882 = dist;
                                shortest = L_882;
                            end;
                        end;
                    end;
                end;
                return closest;
            end;
            return nil;
        end;
        return nil;
    end;
    return nil;
end;
L_883 = { ["10503381238"] = true, ["13379003796"] = true };
yoyoAnimationIDs = L_883;
L_884 = { ["10479335397"] = true, ["13380255751"] = true };
yoyoCooldownAnimations = L_884;
yoyoOnAnimationPlayed = function(L_885, ...)
    if L_110.yoyo and not yoyoCooldown then
        local L_886 = string.match(L_885.Animation.AnimationId, "%d+");
        animId = L_886;
        if not yoyoCooldownAnimations[animId] then
            if yoyoAnimationIDs[animId] then
                yoyoCooldown = true;
                task.delay(0.32, function(...)
                    if L_110.yoyo then
                        pcall(function(...)
                            L_433(L_106.Character);
                            return ;
                        end);
                        local L_887 = yoyoGetClosestValidTarget();
                        targetHRP = L_887;
                        if targetHRP then
                            yoyoAttach(targetHRP);
                            task.delay(0.5, yoyoDetach);
                        end;
                        return ;
                    end;
                    return ;
                end);
                task.delay(4.8, function(...)
                    yoyoCooldown = false;
                    return ;
                end);
            end;
        else
            yoyoCooldown = true;
            task.delay(4.8, function(...)
                yoyoCooldown = false;
                return ;
            end);
        end;
        return ;
    end;
    return ;
end;
setupYOYOCharacter = function(L_888, ...)
    if L_111.yoyo then
        L_111.yoyo:Disconnect();
        L_111.yoyo = nil;
    end;
    yoyoDetach();
    if L_110.yoyo then
        local L_889 = L_888:FindFirstChildOfClass("Humanoid");
        humanoid = L_889;
        if humanoid then
            L_111.yoyo = humanoid.AnimationPlayed:Connect(yoyoOnAnimationPlayed);
            return ;
        end;
        return ;
    end;
    return ;
end;
if L_110.yoyo and L_106.Character then
    setupYOYOCharacter(L_106.Character);
end;
L_106.CharacterAdded:Connect(function(L_890, ...)
    task.wait(0.5);
    if L_110.yoyo then
        setupYOYOCharacter(L_890);
    end;
    return ;
end);
L_903 = function(...)
    if L_111.noClip then
        L_111.noClip:Disconnect();
        L_111.noClip = nil;
    end;
    if L_110.noClip then
        L_111.noClip = L_84.Stepped:Connect(function(...)
            if L_110.noClip then
                local L_891 = { ipairs(L_83:GetPlayers()) };
                local L_892 = L_891[3];
                local L_893 = L_891[2];
                local L_894 = L_891[1];
                while true do
                    local L_895;
                    L_892, L_895 = L_894(L_893, L_892);
                    if not L_892 then
                        break;
                    end;
                    if L_895 ~= L_106 then
                        local L_896 = L_895.Character;
                        if L_896 then
                            local L_897 = L_896.GetDescendants;
                            local L_898 = { ipairs(L_897(L_896)) };
                            local L_899 = L_898[2];
                            local L_900 = L_898[3];
                            local L_901 = L_898[1];
                            while true do
                                local L_902;
                                L_900, L_902 = L_901(L_899, L_900);
                                if not L_900 then
                                    break;
                                end;
                                if L_902:IsA("BasePart") then
                                    L_902.CanCollide = false;
                                end;
                            end;
                        end;
                    end;
                end;
                return ;
            end;
            return ;
        end);
        return ;
    end;
    return ;
end;
L_904 = {};
L_905 = nil;
L_906 = {};
L_907 = true;
L_908 = nil;
L_909 = nil;
L_910 = nil;
loopReworkSafeDestroy = function(L_911, ...)
    local L_912 = L_911;
    if L_912 and L_912.Parent then
        pcall(function(...)
            L_912:Destroy();
            return ;
        end);
    end;
    return ;
end;
loopReworkGetCharParts = function(...)
    local L_913 = L_106.Character;
    if L_913 then
        local L_914 = L_913:FindFirstChildOfClass("Humanoid");
        local L_915 = L_913:FindFirstChild("HumanoidRootPart");
        local L_916 = L_914;
        if L_914 then
            L_916 = L_915;
        end;
        if not L_916 then
            return nil;
        end;
        return L_913, L_914, L_915;
    end;
    return nil;
end;
loopReworkFireDashQW = function(...)
    local L_917 = L_106.Character;
    if L_917 then
        local L_918 = L_917:FindFirstChild("Communicate");
        if L_918 and typeof(L_918.FireServer) == "function" then
            local L_919 = { { Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress" } };
            pcall(function(...)
                L_918:FireServer(unpack(L_919));
                return ;
            end);
        end;
        return ;
    end;
    return ;
end;
loopReworkFindBestTarget = function(L_920, ...)
    local L_921 = L_920 or L_110.loopReworkTargetRadius;
    local L_922 = L_87:FindFirstChild("Live");
    if L_922 then
        local L_923 = { loopReworkGetCharParts() };
        local L_924 = L_923[2];
        local L_925 = L_923[3];
        local L_926 = L_923[1];
        if L_925 then
            local L_927 = nil;
            local L_928 = L_922.GetChildren;
            local L_929 = { ipairs(L_928(L_922)) };
            local L_930 = L_929[2];
            local L_931 = L_929[3];
            local L_932 = L_929[1];
            while true do
                local L_933;
                L_931, L_933 = L_932(L_930, L_931);
                if not L_931 then
                    break;
                end;
                local L_934 = L_933;
                if L_933 then
                    L_934 = L_933:IsA("Model") and L_933 ~= L_106.Character;
                end;
                if L_934 then
                    local L_935 = L_933:FindFirstChild("HumanoidRootPart");
                    local L_936 = L_933:FindFirstChildOfClass("Humanoid");
                    local L_937 = L_935;
                    if L_935 then
                        if L_936 then
                            L_936 = L_936.Health > 0;
                        end;
                        L_937 = L_936;
                    end;
                    if L_937 and (L_933.Name == "Weakest Dummy" or L_83:GetPlayerFromCharacter(L_933) ~= nil) then
                        local L_938 = (L_935.Position - L_925.Position).Magnitude;
                        if L_938 <= L_921 then
                            L_921 = L_938;
                            L_927 = L_935;
                        end;
                    end;
                end;
            end;
            return L_927;
        end;
        return nil;
    end;
    return nil;
end;
loopReworkModelHasBlockingAnim = function(L_939, ...)
    if L_939 and L_939.Parent then
        local L_940 = L_939:FindFirstChildOfClass("Humanoid");
        if L_940 then
            local L_941 = {
                pcall(function(...)
                    return L_940:GetPlayingAnimationTracks();
                end)
            };
            local L_942 = L_941[1];
            local L_943 = L_941[2];
            if L_942 then
                L_942 = L_943;
            end;
            if not L_942 then
                local L_944 = { ipairs(L_940:GetChildren()) };
                local L_945 = L_944[2];
                local L_946 = L_944[3];
                local L_947 = L_944[1];
                repeat
                    local L_948;
                    L_946, L_948 = L_947(L_945, L_946);
                    if not L_946 then
                        return false;
                    end;
                until L_948:IsA("Animation") and tostring(L_948.AnimationId or ""):find(L_107.loopReworkBlockAnimId, 1, true);
                return true;
            end;
            local L_949 = { ipairs(L_943) };
            local L_950 = L_949[2];
            local L_951 = L_949[1];
            local L_952 = L_949[3];
            repeat
                local L_953;
                L_952, L_953 = L_951(L_950, L_952);
                if not L_952 then
                    return false;
                end;
                local L_954 = L_953;
                if L_953 then
                    L_954 = L_953.Animation;
                end;
            until L_954 and tostring(L_953.Animation.AnimationId or ""):find(L_107.loopReworkBlockAnimId, 1, true);
            return true;
        end;
        return false;
    end;
    return false;
end;
loopReworkScanForBlockingAnim = function(...)
    local L_955 = L_87:FindFirstChild("Live");
    if L_955 then
        local L_956 = L_955.GetChildren;
        local L_957 = { ipairs(L_956(L_955)) };
        local L_958 = L_957[2];
        local L_959 = L_957[1];
        local L_960 = L_957[3];
        local L_961;
        repeat
            repeat
                L_960, L_961 = L_959(L_958, L_960);
                if not L_960 then
                    return false;
                end;
                local L_962 = L_961;
                if L_961 then
                    L_962 = L_961:IsA("Model") and L_961 ~= L_106.Character;
                end;
            until L_962;
            local L_963 = L_961:FindFirstChildOfClass("Humanoid");
            if L_963 then
                L_963 = L_963.Health > 0;
            end;
        until L_963 and loopReworkModelHasBlockingAnim(L_961);
        return true, L_961;
    end;
    return false;
end;
loopReworkStartHorizontalLockLerp = function(L_964, L_965, ...)
    local L_966 = L_964;
    local L_967 = L_965;
    if L_966 and L_966.Parent then
        local L_968 = { loopReworkGetCharParts() };
        local L_969 = L_968[2];
        local L_970, L_971 = L_968[3], L_968[1];
        if L_970 and L_969 then
            if not (L_967 <= 0) then
                local L_972 = tick();
                local L_973 = nil;
                L_973 = L_84.RenderStepped:Connect(function(L_974, ...)
                    if not L_110.loopReworkBlocked and L_110.loopRework then
                        if L_966 and L_966.Parent then
                            local L_975 = L_970.Position;
                            local L_976 = Vector3.new(L_966.Position.X, L_975.Y, L_966.Position.Z);
                            if not ((L_976 - L_975).Magnitude < 0.001) then
                                local L_977 = CFrame.new(L_975, L_976);
                                local L_978 = L_110.loopReworkResponsiveness;
                                local L_979 = math.clamp(L_978, 1, 10000);
                                local L_980;
                                if not (L_979 >= 1000) then
                                    local L_981 = 1 - math.exp(-0.02 * L_979 * L_974);
                                    L_980 = math.clamp(L_981, 0, 1);
                                else
                                    L_980 = 1;
                                end;
                                if not (L_980 >= 0.999999) then
                                    local L_982 = L_970.CFrame:Lerp(L_977, L_980);
                                    local L_983 = CFrame.new(L_975) * CFrame.fromMatrix(Vector3.new(), L_982.RightVector, L_982.UpVector);
                                    pcall(function(...)
                                        L_970.CFrame = L_983;
                                        return ;
                                    end);
                                else
                                    pcall(function(...)
                                        L_970.CFrame = L_977;
                                        return ;
                                    end);
                                end;
                            end;
                            if not (tick() - L_972 >= L_967) then
                                return ;
                            end;
                            if L_973 then
                                L_973:Disconnect();
                            end;
                            return ;
                        end;
                        if L_973 then
                            L_973:Disconnect();
                        end;
                        return ;
                    end;
                    if L_973 then
                        L_973:Disconnect();
                    end;
                    return ;
                end);
                return function(...)
                    if L_973 then
                        pcall(function(...)
                            L_973:Disconnect();
                            return ;
                        end);
                    end;
                    return ;
                end;
            end;
            return nil;
        end;
        return nil;
    end;
    return nil;
end;
loopReworkCancelActiveLockAndRestore = function(...)
    if L_905 then
        pcall(L_905);
        L_905 = nil;
    end;
    local L_984 = L_106.Character;
    local L_985 = nil;
    if L_984 then
        L_985 = L_984:FindFirstChildOfClass("Humanoid");
    end;
    pcall(function(...)
        if L_985 and L_985.Parent then
            L_985.AutoRotate = true;
        end;
        return ;
    end);
    return ;
end;
loopReworkForceJumpUpdateCharacter = function(L_986, ...)
    if L_986 then
        L_908 = L_986;
        L_909 = L_986:FindFirstChildOfClass("Humanoid");
        L_910 = L_986:FindFirstChild("HumanoidRootPart") or L_986:FindFirstChild("Torso");
        return ;
    end;
    L_908 = nil;
    L_909 = nil;
    L_910 = nil;
    return ;
end;
loopReworkForceJumpDoJump = function(L_987, L_988, ...)
    local L_989 = L_987;
    local L_990 = L_988;
    if L_110.ForceJumpEnabled ~= false then
        if L_907 then
            L_907 = false;
            pcall(function(...)
                if L_989 and L_989.Parent then
                    L_989.PlatformStand = false;
                    L_989.Jump = true;
                    L_989:ChangeState(Enum.HumanoidStateType.Jumping);
                end;
                return ;
            end);
            if L_990 and L_990.Parent then
                pcall(function(...)
                    local L_991 = L_990.AssemblyLinearVelocity;
                    local L_992 = L_110.ForceJumpUpwardVelocity or 52;
                    L_990.AssemblyLinearVelocity = Vector3.new(L_991.X, L_992, L_991.Z);
                    return ;
                end);
                pcall(function(...)
                    local L_993 = L_990.Velocity;
                    local L_994 = L_110.ForceJumpUpwardVelocity or 52;
                    L_990.Velocity = Vector3.new(L_993.X, L_994, L_993.Z);
                    return ;
                end);
            end;
            local L_995 = (L_110.ForceJumpDebounceTime or 18) / 100;
            delay(L_995, function(...)
                L_907 = true;
                return ;
            end);
            return true;
        end;
        return true;
    end;
    return false;
end;
loopReworkForceJumpSetup = function(...)
    if not L_906.charAdded then
        L_906.charAdded = L_106.CharacterAdded:Connect(function(L_996, ...)
            task.wait(1);
            loopReworkForceJumpUpdateCharacter(L_996);
            return ;
        end);
        if L_106.Character then
            loopReworkForceJumpUpdateCharacter(L_106.Character);
        end;
        return ;
    end;
    return ;
end;
loopReworkForceJumpUnload = function(...)
    if L_906.charAdded then
        pcall(function(...)
            L_906.charAdded:Disconnect();
            return ;
        end);
        L_906.charAdded = nil;
    end;
    L_908 = nil;
    L_909 = nil;
    L_910 = nil;
    L_907 = true;
    return ;
end;
loopReworkRunSequence = function(...)
    if not L_110.loopReworkDebounce and (L_110.loopRework and not L_110.loopReworkBlocked) then
        L_110.loopReworkDebounce = true;
        local L_997 = L_110.loopReworkWaitDetect / 10;
        local L_998 = L_110.loopReworkWaitJump / 10;
        local L_999 = L_110.loopReworkWaitRemote / 10;
        local L_1000 = L_110.loopReworkLockDuration / 10;
        local L_1001 = L_110.loopReworkCooldown / 10;
        local L_1002 = tick();
        while tick() - L_1002 < L_997 do
            if not L_110.loopRework or L_110.loopReworkBlocked then
                L_110.loopReworkDebounce = false;
                return ;
            end;
            L_84.Heartbeat:Wait();
        end;
        if L_110.loopRework and not L_110.loopReworkBlocked then
            local L_1003 = { loopReworkGetCharParts() };
            local L_1004 = L_1003[1];
            local L_1005, L_1006 = L_1003[2], L_1003[3];
            if L_1005 and L_1006 then
                local L_1007 = nil;
                pcall(function(...)
                    L_1007 = L_1005.AutoRotate;
                    return ;
                end);
                pcall(function(...)
                    L_1005.AutoRotate = false;
                    return ;
                end);
                if L_110.ForceJumpEnabled ~= false then
                    loopReworkForceJumpSetup();
                    loopReworkForceJumpUpdateCharacter(L_1004);
                    if not loopReworkForceJumpDoJump(L_1005, L_1006) then
                        pcall(function(...)
                            L_1005.Jump = true;
                            L_1005:ChangeState(Enum.HumanoidStateType.Jumping);
                            return ;
                        end);
                    end;
                else
                    pcall(function(...)
                        L_1005.Jump = true;
                        L_1005:ChangeState(Enum.HumanoidStateType.Jumping);
                        return ;
                    end);
                end;
                local L_1008 = tick();
                while tick() - L_1008 < L_998 do
                    if not L_110.loopRework or L_110.loopReworkBlocked then
                        pcall(function(...)
                            if L_1005 and (L_1005.Parent and L_1007 ~= nil) then
                                L_1005.AutoRotate = L_1007;
                            end;
                            return ;
                        end);
                        L_110.loopReworkDebounce = false;
                        return ;
                    end;
                    L_84.Heartbeat:Wait();
                end;
                if L_110.loopRework and not L_110.loopReworkBlocked then
                    loopReworkFireDashQW();
                    local L_1009 = tick();
                    while tick() - L_1009 < L_999 do
                        if not L_110.loopRework or L_110.loopReworkBlocked then
                            pcall(function(...)
                                if L_1005 and (L_1005.Parent and L_1007 ~= nil) then
                                    L_1005.AutoRotate = L_1007;
                                end;
                                return ;
                            end);
                            L_110.loopReworkDebounce = false;
                            return ;
                        end;
                        L_84.Heartbeat:Wait();
                    end;
                    if L_110.loopRework and not L_110.loopReworkBlocked then
                        local L_1010 = loopReworkFindBestTarget();
                        local L_1011 = nil;
                        local L_1012 = L_1010;
                        if L_1010 then
                            L_1012 = not L_110.loopReworkBlocked;
                        end;
                        if L_1012 then
                            L_1011 = loopReworkStartHorizontalLockLerp(L_1010, L_1000);
                            L_905 = L_1011;
                        end;
                        local L_1013 = tick() + math.max(L_1000, 1.2);
                        task.spawn(function(...)
                            while tick() < L_1013 and (L_110.loopRework and not L_110.loopReworkBlocked) do
                                pcall(function(...)
                                    if L_1005 and L_1005.Parent then
                                        L_1005.AutoRotate = false;
                                    end;
                                    return ;
                                end);
                                L_84.Heartbeat:Wait();
                            end;
                            pcall(function(...)
                                if L_1005 and (L_1005.Parent and L_1007 ~= nil) then
                                    L_1005.AutoRotate = L_1007;
                                end;
                                return ;
                            end);
                            return ;
                        end);
                        task.delay(L_1000, function(...)
                            if L_1011 then
                                pcall(L_1011);
                                L_905 = nil;
                            end;
                            return ;
                        end);
                        task.delay(L_1001, function(...)
                            L_110.loopReworkDebounce = false;
                            return ;
                        end);
                        return ;
                    end;
                    pcall(function(...)
                        if L_1005 and (L_1005.Parent and L_1007 ~= nil) then
                            L_1005.AutoRotate = L_1007;
                        end;
                        return ;
                    end);
                    L_110.loopReworkDebounce = false;
                    return ;
                end;
                pcall(function(...)
                    if L_1005 and (L_1005.Parent and L_1007 ~= nil) then
                        L_1005.AutoRotate = L_1007;
                    end;
                    return ;
                end);
                L_110.loopReworkDebounce = false;
                return ;
            end;
            L_110.loopReworkDebounce = false;
            return ;
        end;
        L_110.loopReworkDebounce = false;
        return ;
    end;
    return ;
end;
loopReworkOnAnimationPlayed = function(L_1014, ...)
    if L_110.loopRework and (not L_110.loopReworkDebounce and not L_110.loopReworkBlocked) then
        if L_1014 and L_1014.Animation then
            local L_1015 = tostring(L_1014.Animation.AnimationId or "");
            if L_1015 == L_107.loopReworkAnimDetectId or L_1015:find(L_107.loopReworkAnimDetectId, 1, true) then
                task.spawn(loopReworkRunSequence);
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
loopReworkHookCharacter = function(...)
    if L_904.anim then
        pcall(function(...)
            L_904.anim:Disconnect();
            return ;
        end);
        L_904.anim = nil;
    end;
    local L_1016 = L_106.Character;
    if L_1016 then
        local L_1017 = L_1016:FindFirstChildOfClass("Humanoid");
        if L_1017 then
            L_904.anim = L_1017.AnimationPlayed:Connect(loopReworkOnAnimationPlayed);
        end;
        return ;
    end;
    return ;
end;
loopReworkStartBlockChecker = function(...)
    if L_904.blockChecker then
        pcall(function(...)
            L_904.blockChecker:Disconnect();
            return ;
        end);
        L_904.blockChecker = nil;
    end;
    local L_1018 = 0;
    L_904.blockChecker = L_84.Heartbeat:Connect(function(L_1019, ...)
        if L_110.loopRework then
            L_1018 = L_1018 + L_1019;
            if not (L_1018 < 0.12) then
                L_1018 = 0;
                local L_1020 = { loopReworkScanForBlockingAnim() };
                local L_1021 = L_1020[2];
                local L_1022 = L_1020[1];
                local L_1023 = L_1022;
                if L_1022 then
                    L_1023 = not L_110.loopReworkBlocked;
                end;
                if not L_1023 then
                    if not L_1022 and L_110.loopReworkBlocked then
                        L_110.loopReworkBlocked = false;
                        if L_110.loopRework then
                            loopReworkHookCharacter();
                        end;
                    end;
                else
                    L_110.loopReworkBlocked = true;
                    loopReworkCancelActiveLockAndRestore();
                    if L_904.anim then
                        pcall(function(...)
                            L_904.anim:Disconnect();
                            return ;
                        end);
                        L_904.anim = nil;
                    end;
                end;
                return ;
            end;
            return ;
        end;
        return ;
    end);
    return ;
end;
loopReworkSetupLoopRework = function(...)
    if L_110.loopRework then
        loopReworkHookCharacter();
        loopReworkStartBlockChecker();
        if L_904.charAdded then
            pcall(function(...)
                L_904.charAdded:Disconnect();
                return ;
            end);
        end;
        L_904.charAdded = L_106.CharacterAdded:Connect(function(...)
            task.wait(1);
            if L_110.loopRework then
                loopReworkHookCharacter();
            end;
            return ;
        end);
        loopReworkForceJumpSetup();
        return ;
    end;
    if L_904.anim then
        pcall(function(...)
            L_904.anim:Disconnect();
            return ;
        end);
        L_904.anim = nil;
    end;
    if L_904.blockChecker then
        pcall(function(...)
            L_904.blockChecker:Disconnect();
            return ;
        end);
        L_904.blockChecker = nil;
    end;
    if L_904.charAdded then
        pcall(function(...)
            L_904.charAdded:Disconnect();
            return ;
        end);
        L_904.charAdded = nil;
    end;
    loopReworkCancelActiveLockAndRestore();
    L_110.loopReworkDebounce = false;
    L_110.loopReworkBlocked = false;
    return ;
end;
L_1029 = function(...)
    if L_111.m2Block then
        L_111.m2Block:Disconnect();
        L_111.m2Block = nil;
    end;
    if L_110.m2Block then
        L_111.m2Block = L_86.InputBegan:Connect(function(L_1024, L_1025, ...)
            if not L_1025 and L_1024.UserInputType == Enum.UserInputType.MouseButton2 then
                L_88:SendKeyEvent(true, Enum.KeyCode.F, false, game);
            end;
            return ;
        end);
        local L_1028 = L_86.InputEnded:Connect(function(L_1026, L_1027, ...)
            if not L_1027 and L_1026.UserInputType == Enum.UserInputType.MouseButton2 then
                L_88:SendKeyEvent(false, Enum.KeyCode.F, false, game);
            end;
            return ;
        end);
        L_111.m2BlockEnd = L_1028;
        return ;
    end;
    return ;
end;
L_1035 = function(...)
    if L_111.m1BlockConnection then
        L_111.m1BlockConnection:Disconnect();
        L_111.m1BlockConnection = nil;
    end;
    if L_110.m1Block then
        local L_1030 = L_83.LocalPlayer;
        if not L_1030 then
            warn("");
            return ;
        end;
        if not L_1030.Character then
            L_1030.CharacterAdded:Wait();
        end;
        local L_1031 = L_1030:GetMouse();
        if not L_1031 then
            warn("");
            return ;
        end;
        L_111.m1BlockConnection = L_1031.Button1Down:Connect(function(...)
            local L_1032 = L_1030.Character;
            if not L_1032 then
                warn("");
            else
                local L_1033 = L_1032:WaitForChild("Communicate", 5);
                if not L_1033 then
                    warn("");
                else
                    local L_1034 = { { Goal = "KeyRelease", Key = Enum.KeyCode.F } };
                    L_1033:FireServer(unpack(L_1034));
                end;
            end;
            return ;
        end);
    end;
    return ;
end;
L_1056 = function(...)
    if L_111.downSlam then
        L_111.downSlam:Disconnect();
        L_111.downSlam = nil;
    end;
    if L_110.downSlam then
        local L_1036 = L_106.Character;
        local L_1037 = nil;
        local L_1038 = nil;
        local L_1039 = { ["rbxassetid://10469639222"] = true, ["rbxassetid://13532604085"] = true, ["rbxassetid://13295919399"] = true, ["rbxassetid://13378751717"] = true, ["rbxassetid://14001963401"] = true, ["rbxassetid://15240176873"] = true, ["rbxassetid://16515448089"] = true, ["rbxassetid://17889471098"] = true, ["rbxassetid://104895379416342"] = true };
        local L_1046 = function(...)
            if L_1038 then
                local L_1040 = { ipairs(L_87:WaitForChild("Live"):GetChildren()) };
                local L_1041 = L_1040[2];
                local L_1042 = L_1040[1];
                local L_1043 = L_1040[3];
                repeat
                    local L_1044;
                    repeat
                        L_1043, L_1044 = L_1042(L_1041, L_1043);
                        if not L_1043 then
                            return false;
                        end;
                    until L_1044:IsA("Model") and L_1044 ~= L_1036;
                    local L_1045 = L_1044:FindFirstChild("HumanoidRootPart");
                    if L_1045 then
                        L_1045 = (L_1045.Position - L_1038.Position).Magnitude <= 15;
                    end;
                until L_1045 and (L_83:GetPlayerFromCharacter(L_1044) or L_1044.Name == "Weakest Dummy");
                return true;
            end;
            return false;
        end;
        local L_1052 = function(...)
            if L_1038 and L_1037 then
                if L_1046() then
                    L_85:Create(L_1038, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = L_1038.CFrame + Vector3.new(0, 6, 0) }):Play();
                    local L_1047 = { ipairs({ Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.GettingUp }) };
                    local L_1048 = L_1047[2];
                    local L_1049 = L_1047[1];
                    local L_1050 = L_1047[3];
                    while true do
                        local L_1051;
                        L_1050, L_1051 = L_1049(L_1048, L_1050);
                        if not L_1050 then
                            break;
                        end;
                        if L_1037:GetState() == L_1051 then
                            L_1037:ChangeState(Enum.HumanoidStateType.Physics);
                            task.wait();
                        end;
                    end;
                    L_1037:ChangeState(Enum.HumanoidStateType.Jumping);
                    return ;
                end;
                return ;
            end;
            return ;
        end;
        local L_1054 = function(...)
            if L_1037 then
                L_1037.AnimationPlayed:Connect(function(L_1053, ...)
                    if L_110.downSlam and (L_1053.Animation and L_1039[L_1053.Animation.AnimationId]) then
                        L_1052();
                    end;
                    return ;
                end);
            end;
            return ;
        end;
        local L_1055 = function(...)
            L_1036 = L_106.Character or L_106.CharacterAdded:Wait();
            L_1037 = L_1036:WaitForChild("Humanoid");
            L_1038 = L_1036:WaitForChild("HumanoidRootPart");
            L_1054();
            return ;
        end;
        L_1055();
        L_106.CharacterAdded:Connect(L_1055);
        return ;
    end;
    return ;
end;
L_1057 = {};
L_1070 = function(L_1058, L_1059, ...)
    local L_1060 = L_1058:FindFirstChild("Torso") or L_1058:FindFirstChild("UpperTorso");
    if L_1060 then
        local L_1061 = Instance.new("BillboardGui");
        L_1061.Name = "ArrowBillboard";
        L_1061.Adornee = L_1060;
        L_1061.Size = UDim2.new(4, 0, 2, 0);
        L_1061.StudsOffset = Vector3.new(0, 5, 0);
        L_1061.AlwaysOnTop = true;
        L_1061.Parent = L_1060;
        local L_1062 = Instance.new("TextLabel");
        L_1062.Size = UDim2.new(1, 0, 1, 0);
        L_1062.BackgroundTransparency = 1;
        L_1062.Text = "\226\172\135";
        L_1062.Font = Enum.Font.GothamBold;
        L_1062.TextScaled = true;
        L_1062.TextColor3 = Color3.fromRGB(255, 0, 0);
        L_1062.Parent = L_1061;
        task.spawn(function(...)
            while L_1061 and L_1061.Parent do
                local L_1063 = 1;
                local L_1064 = 0.05;
                local L_1065 = L_1064 < 0;
                local L_1066 = 0 - L_1064;
                while true do
                    L_1066 = L_1066 + L_1064;
                    local L_1067 = L_1066 <= L_1063;
                    local L_1068 = not L_1065 and L_1067;
                    local L_1069 = L_1066 >= L_1063;
                    if not (L_1065 and L_1069 or L_1068) or (not L_1061 or (not L_1061.Parent or not L_110.arrowIndicator)) then
                        break;
                    end;
                    L_1062.TextColor3 = Color3.new(1, 0, 0):Lerp(Color3.new(0.5, 0, 0), math.sin(L_1066 * math.pi));
                    task.wait(0.1);
                end;
            end;
            return ;
        end);
        L_1059.Stopped:Connect(function(...)
            if L_1061 then
                L_1061:Destroy();
            end;
            return ;
        end);
        return ;
    end;
    return ;
end;
L_1074 = function(L_1071, ...)
    local L_1072 = L_1071;
    if L_1057[L_1072] then
        L_1057[L_1072]:Disconnect();
        L_1057[L_1072] = nil;
    end;
    if L_110.arrowIndicator then
        L_1057[L_1072] = L_1072.AnimationPlayed:Connect(function(L_1073, ...)
            if L_110.arrowIndicator then
                if L_1073.Animation.AnimationId == "rbxassetid://10470389827" then
                    L_1070(L_1072.Parent, L_1073);
                end;
                return ;
            end;
            return ;
        end);
        return ;
    end;
    return ;
end;
L_1089 = function(...)
    local L_1075 = { pairs(L_1057) };
    local L_1076 = L_1075[2];
    local L_1077 = L_1075[1];
    local L_1078 = L_1075[3];
    while true do
        local L_1079;
        L_1078, L_1079 = L_1077(L_1076, L_1078);
        if not L_1078 then
            break;
        end;
        if L_1079.Connected then
            L_1079:Disconnect();
        end;
    end;
    L_1057 = {};
    if L_110.arrowIndicator then
        local L_1080 = { ipairs(L_83:GetPlayers()) };
        local L_1081 = L_1080[3];
        local L_1082 = L_1080[1];
        local L_1083 = L_1080[2];
        while true do
            local L_1084;
            L_1081, L_1084 = L_1082(L_1083, L_1081);
            if not L_1081 then
                break;
            end;
            if L_1084.Character then
                local L_1085 = L_1084.Character:FindFirstChildOfClass("Humanoid");
                if L_1085 then
                    L_1074(L_1085);
                end;
            end;
        end;
        L_83.PlayerAdded:Connect(function(L_1086, ...)
            L_1086.CharacterAdded:Connect(function(L_1087, ...)
                local L_1088 = L_1087:WaitForChild("Humanoid");
                L_1074(L_1088);
                return ;
            end);
            return ;
        end);
        return ;
    end;
    return ;
end;
L_1090 = { ["rbxassetid://10503381238"] = true, ["rbxassetid://13379003796"] = true };
UpperGraspAnimIds = L_1090;
UpperGraspConnections = {};
UpperGraspMatchAnimId = function(L_1091, ...)
    if L_1091 then
        local L_1092 = tostring(L_1091);
        if not UpperGraspAnimIds[L_1092] then
            local L_1093 = L_1092:match("(%d+)");
            if L_1093 then
                if UpperGraspAnimIds[L_1093] then
                    return true;
                end;
                if UpperGraspAnimIds["rbxassetid://" .. L_1093] then
                    return true;
                end;
            end;
            return false;
        end;
        return true;
    end;
    return false;
end;
UpperGraspFindClosestTarget = function(L_1094, L_1095, ...)
    local L_1096 = L_110.upperGraspSearchRadius;
    local L_1097 = L_87:FindFirstChild("Live");
    if L_1097 then
        local L_1098 = nil;
        local L_1099 = { ipairs(L_1097:GetChildren()) };
        local L_1100 = L_1099[1];
        local L_1101 = L_1099[3];
        local L_1102 = L_1099[2];
        while true do
            local L_1103;
            L_1101, L_1103 = L_1100(L_1102, L_1101);
            if not L_1101 then
                break;
            end;
            if L_1103:IsA("Model") and L_1103 ~= L_1094 then
                local L_1104 = L_1103:FindFirstChild("Torso") or (L_1103:FindFirstChild("UpperTorso") or (L_1103:FindFirstChild("HumanoidRootPart") or L_1103:FindFirstChild("Head")));
                local L_1105 = L_1104;
                if L_1104 then
                    L_1105 = L_1104.Position;
                end;
                if L_1105 then
                    local L_1106 = (L_1095.Position - L_1104.Position).Magnitude;
                    if L_1106 <= L_1096 then
                        L_1096 = L_1106;
                        L_1098 = L_1104;
                    end;
                end;
            end;
        end;
        return L_1098;
    end;
    return nil;
end;
UpperGraspPerformGrasp = function(...)
    if L_110.upperGrasp then
        local L_1107 = L_106.Character;
        if L_1107 then
            local L_1108 = L_1107:FindFirstChild("HumanoidRootPart");
            local L_1109 = L_1107:FindFirstChild("Humanoid");
            if L_1108 and L_1109 then
                local L_1110 = UpperGraspFindClosestTarget(L_1107, L_1108);
                if L_1110 then
                    local L_1111 = L_1110.Position + Vector3.new(0, 5, 0);
                    local L_1112 = L_110.upperGraspTweenTime / 100;
                    pcall(function(...)
                        local L_1113 = L_85:Create(L_1108, TweenInfo.new(L_1112, Enum.EasingStyle.Linear), { CFrame = CFrame.new(L_1111) });
                        L_1113:Play();
                        L_1113.Completed:Wait();
                        return ;
                    end);
                end;
                local L_1114 = L_106.Backpack and L_106.Backpack:FindFirstChild("Hunterzzzzz's Grasp");
                local L_1115 = L_1107:FindFirstChild("Communicate");
                local L_1116 = L_1114;
                if L_1114 then
                    L_1116 = L_1115;
                end;
                if L_1116 then
                    local L_1117 = { [1] = { Tool = L_1114, Goal = "Console Move" } };
                    pcall(function(...)
                        L_1115:FireServer(unpack(L_1117));
                        return ;
                    end);
                end;
                return ;
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
UpperGraspOnAnimationPlayed = function(L_1118, ...)
    if L_110.upperGrasp then
        if not L_110.upperGraspCooldown then
            if L_1118 and L_1118.Animation then
                local L_1119 = L_1118.Animation.AnimationId;
                if UpperGraspMatchAnimId(L_1119) then
                    L_110.upperGraspCooldown = true;
                    local L_1120 = L_110.upperGraspAfterDelay / 100;
                    task.delay(L_1120, function(...)
                        if L_110.upperGrasp then
                            pcall(UpperGraspPerformGrasp);
                            local L_1121 = L_110.upperGraspCooldownSeconds / 10;
                            task.delay(L_1121, function(...)
                                L_110.upperGraspCooldown = false;
                                return ;
                            end);
                            return ;
                        end;
                        local L_1122 = L_110.upperGraspCooldownSeconds / 10;
                        task.delay(L_1122, function(...)
                            L_110.upperGraspCooldown = false;
                            return ;
                        end);
                        return ;
                    end);
                end;
                return ;
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
UpperGraspHookCharacter = function(...)
    if UpperGraspConnections.anim then
        pcall(function(...)
            UpperGraspConnections.anim:Disconnect();
            return ;
        end);
        UpperGraspConnections.anim = nil;
    end;
    local L_1123 = L_106.Character;
    if L_1123 then
        local L_1124 = L_1123:FindFirstChild("Humanoid");
        if L_1124 then
            UpperGraspConnections.anim = L_1124.AnimationPlayed:Connect(UpperGraspOnAnimationPlayed);
        end;
        return ;
    end;
    return ;
end;
SetupUpperGrasp = function(...)
    if UpperGraspConnections.anim then
        pcall(function(...)
            UpperGraspConnections.anim:Disconnect();
            return ;
        end);
        UpperGraspConnections.anim = nil;
    end;
    if UpperGraspConnections.charAdded then
        pcall(function(...)
            UpperGraspConnections.charAdded:Disconnect();
            return ;
        end);
        UpperGraspConnections.charAdded = nil;
    end;
    if L_110.upperGrasp then
        UpperGraspHookCharacter();
        UpperGraspConnections.charAdded = L_106.CharacterAdded:Connect(function(L_1125, ...)
            task.wait(0.9);
            if L_110.upperGrasp then
                UpperGraspHookCharacter(L_1125);
            end;
            return ;
        end);
        L_82:Notify({ Title = "Upper Grasp", Content = "Enabled - Will trigger on dash animations", Duration = 3, Icon = "lucide:hand" });
        return ;
    end;
    L_110.upperGraspCooldown = false;
    return ;
end;
task.spawn(function(...)
    task.wait(3);
    if L_110.upperGrasp then
        SetupUpperGrasp();
    end;
    return ;
end);
sideDashConnections = {};
target = nil;
L_1126 = game.Workspace.Live:FindFirstChild("Weakest Dummy");
dummy = L_1126;
toggle = false;
q = true;
f = true;
m = true;
a = true;
noClip = false;
click = false;
silent = false;
L_1127 = math.huge;
lastmagnitude = L_1127;
mobileDashGui = nil;
lastTapTime = 0;
L_1128 = game.Players.LocalPlayer:GetMouse();
mouse = L_1128;
getTargetColor = function(...)
    return Color3.fromRGB(L_110.sideDashTargetColorR, L_110.sideDashTargetColorG, L_110.sideDashTargetColorB);
end;
setTargetColorFromColor3 = function(L_1129, ...)
    if type(L_1129) == "table" and L_1129.Color then
        L_1129 = L_1129.Color;
    end;
    if L_1129 then
        L_110.sideDashTargetColorR = math.clamp(math.floor(L_1129.R * 255 + 0.5), 0, 255);
        L_110.sideDashTargetColorG = math.clamp(math.floor(L_1129.G * 255 + 0.5), 0, 255);
        L_110.sideDashTargetColorB = math.clamp(math.floor(L_1129.B * 255 + 0.5), 0, 255);
        updateTargetColor();
        return ;
    end;
    return ;
end;
updateTargetColor = function(...)
    if target then
        local L_1130 = target == dummy and target or target.Character;
        char = L_1130;
        removeHighlight(char);
        if L_110.sideDashShow then
            addHighlight(char);
        end;
    end;
    return ;
end;
dash = function(...)
    local L_1131 = game:GetService("Players");
    Playerss = L_1131;
    local L_1132 = Playerss.LocalPlayer.Character.Communicate;
    Communicatee = L_1132;
    Communicatee:FireServer({ Dash = Enum.KeyCode.A, Key = Enum.KeyCode.Q, Goal = "KeyPress" });
    return ;
end;
dashLV = nil;
dashAtt = nil;
ensureLV = function(L_1133, ...)
    local L_1134 = dashAtt or Instance.new("Attachment", L_1133);
    dashAtt = L_1134;
    if not dashLV then
        local L_1135 = Instance.new("LinearVelocity");
        dashLV = L_1135;
        dashLV.Attachment0 = dashAtt;
        dashLV.MaxForce = math.huge;
        dashLV.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector;
        dashLV.RelativeTo = Enum.ActuatorRelativeTo.World;
        dashLV.Parent = L_1133;
    end;
    return dashLV;
end;
setDashVelocity = function(L_1136, L_1137, L_1138, ...)
    local L_1139 = ensureLV(L_1136);
    lv = L_1139;
    local L_1140 = Vector3.new(L_1137.X, L_1136.Position.Y, L_1137.Z);
    flatTarget = L_1140;
    local L_1141 = flatTarget - L_1136.Position;
    delta = L_1141;
    local L_1142 = delta / math.max(L_1138, 0.01);
    needed = L_1142;
    lv.VectorVelocity = Vector3.new(needed.X, 0, needed.Z);
    return ;
end;
stopDash = function(...)
    if dashLV then
        dashLV.VectorVelocity = Vector3.new();
        dashLV:Destroy();
        dashLV = nil;
    end;
    if dashAtt then
        dashAtt:Destroy();
        dashAtt = nil;
    end;
    return ;
end;
addHighlight = function(L_1143, ...)
    if L_1143 and L_110.sideDashShow then
        local L_1144 = Instance.new("Highlight");
        highlight = L_1144;
        highlight.Parent = L_1143;
        highlight.OutlineColor = getTargetColor();
        highlight.FillColor = getTargetColor();
        highlight.FillTransparency = 0.8;
        highlight.OutlineTransparency = 0.3;
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop;
        return ;
    end;
    return ;
end;
removeHighlight = function(L_1145, ...)
    local L_1146 = { ipairs(L_1145:GetDescendants()) };
    local L_1147 = L_1146[2];
    local L_1148 = L_1146[1];
    local L_1149 = L_1146[3];
    while true do
        local L_1150;
        L_1149, L_1150 = L_1148(L_1147, L_1149);
        if not L_1149 then
            break;
        end;
        if L_1150:IsA("Highlight") then
            L_1150:Destroy();
        end;
    end;
    return ;
end;
silentAim = function(L_1151, L_1152, ...)
    local L_1153 = game.Players.LocalPlayer.Character.HumanoidRootPart;
    humm = L_1153;
    if L_1151 == nil or L_1151 ~= dummy then
        if L_1151 ~= nil and L_1151 ~= dummy then
            local L_1154 = L_1151.Character:FindFirstChild("Right Arm");
            get = L_1154;
            local L_1155 = get.CFrame.Position - humm.CFrame.Position;
            directionMM = L_1155;
            local L_1156 = CFrame.fromAxisAngle(Vector3.new(0, L_1152, 0), math.rad(140)) * directionMM;
            newDirection = L_1156;
            local L_1157 = get.CFrame.Position + newDirection;
            ddirect = L_1157;
            local L_1158 = Vector3.new(ddirect.X, humm.CFrame.Position.Y, ddirect.Z);
            n = L_1158;
            local L_1159 = CFrame.new(humm.CFrame.Position, n);
            finalCF = L_1159;
            humm.CFrame = humm.CFrame:Lerp(finalCF, L_110.sideDashSmoothness);
        end;
    else
        local L_1160 = L_1151:FindFirstChild("Right Arm");
        get = L_1160;
        local L_1161 = get.CFrame.Position - humm.CFrame.Position;
        directionMM = L_1161;
        local L_1162 = CFrame.fromAxisAngle(Vector3.new(0, L_1152, 0), math.rad(140)) * directionMM;
        newDirection = L_1162;
        local L_1163 = get.CFrame.Position + newDirection;
        ddirect = L_1163;
        local L_1164 = Vector3.new(ddirect.X, humm.CFrame.Position.Y, ddirect.Z);
        n = L_1164;
        local L_1165 = CFrame.new(humm.CFrame.Position, n);
        finalCF = L_1165;
        humm.CFrame = humm.CFrame:Lerp(finalCF, L_110.sideDashSmoothness);
    end;
    return ;
end;
aimlock = function(L_1166, ...)
    local L_1167 = workspace.CurrentCamera;
    cam = L_1167;
    if L_1166 == nil or L_1166 ~= dummy then
        if L_1166 ~= nil and L_1166 ~= dummy then
            local L_1168 = Vector3.new(L_1166.Character.HumanoidRootPart.CFrame.Position.X, 438, L_1166.Character.HumanoidRootPart.CFrame.Position.Z);
            vv = L_1168;
            cam.CFrame = CFrame.new(cam.CFrame.Position, vv);
        end;
    else
        local L_1169 = Vector3.new(L_1166.HumanoidRootPart.CFrame.Position.X, 438, L_1166.HumanoidRootPart.CFrame.Position.Z);
        vv = L_1169;
        cam.CFrame = CFrame.new(cam.CFrame.Position, vv);
    end;
    return ;
end;
deselectTarget = function(...)
    if target then
        local L_1170 = target == dummy and target or target.Character;
        char = L_1170;
        removeHighlight(char);
        target = nil;
        toggle = false;
    end;
    return ;
end;
getdiddy = function(L_1171, ...)
    local L_1172 = game.Workspace.Live:FindFirstChild("Weakest Dummy");
    dummy = L_1172;
    local L_1173 = workspace.CurrentCamera:ScreenPointToRay(L_1171.X, L_1171.Y);
    ray = L_1173;
    local L_1174 = RaycastParams.new();
    params = L_1174;
    params.FilterDescendantsInstances = { game.Players.LocalPlayer.Character };
    params.FilterType = Enum.RaycastFilterType.Blacklist;
    local L_1175 = workspace:Raycast(ray.Origin, ray.Direction * 1000, params);
    hit = L_1175;
    if not hit then
        deselectTarget();
    else
        local L_1176 = hit.Instance:FindFirstAncestorOfClass("Model");
        model = L_1176;
        local L_1177 = game.Players:GetPlayerFromCharacter(model);
        plr = L_1177;
        local L_1178 = plr or (model == dummy and dummy or nil);
        selected = L_1178;
        if selected then
            if selected ~= target then
                deselectTarget();
                local L_1179 = selected;
                target = L_1179;
                local L_1180 = target == dummy and target or target.Character;
                char = L_1180;
                addHighlight(char);
                toggle = true;
            else
                deselectTarget();
            end;
        end;
    end;
    return ;
end;
GetTarget = function(...)
    local L_1181 = game.Workspace.Live:FindFirstChild("Weakest Dummy");
    dummy = L_1181;
    local L_1182 = game.Players.LocalPlayer:GetMouse().Hit.p;
    mousepos = L_1182;
    local L_1183 = math.huge;
    lastmagnitude = L_1183;
    local L_1184 = nil;
    local L_1185 = { pairs(game.Players:GetPlayers()) };
    local L_1186 = L_1185[1];
    local L_1187 = L_1185[3];
    local L_1188 = L_1185[2];
    while true do
        local L_1189;
        L_1187, L_1189 = L_1186(L_1188, L_1187);
        if not L_1187 then
            break;
        end;
        if L_1189 ~= game.Players.LocalPlayer and L_1189.Character then
            local L_1190 = L_1189.Character.HumanoidRootPart.CFrame.Position;
            charpos = L_1190;
            if (charpos - mousepos).Magnitude < lastmagnitude then
                local L_1191 = (charpos - mousepos).Magnitude;
                lastmagnitude = L_1191;
                L_1184 = L_1189;
            end;
        end;
    end;
    if dummy and (dummy.HumanoidRootPart and (dummy.HumanoidRootPart.Position - mousepos).Magnitude < lastmagnitude) then
        L_1184 = dummy;
    end;
    if not L_1184 then
        deselectTarget();
    elseif L_1184 ~= target then
        deselectTarget();
        target = L_1184;
        local L_1192 = target == dummy and target or target.Character;
        char = L_1192;
        addHighlight(char);
        toggle = true;
    else
        deselectTarget();
    end;
    return ;
end;
simulateLeftClickMobile = function(...)
    if click then
        local L_1193 = game.Players.LocalPlayer.Character.Communicate;
        Communicate = L_1193;
        local L_1194 = { Goal = "KeyRelease", Key = Enum.KeyCode.F };
        args = { L_1194 };
        game.Players.LocalPlayer.Character:WaitForChild("Communicate"):FireServer(unpack(args));
        Communicate:FireServer({ Mobile = true, Goal = "LeftClick" });
        Communicate:FireServer({ Mobile = true, Goal = "LeftClickRelease" });
    end;
    return ;
end;
pressQA = function(...)
    if q == true then
        q = false;
        local L_1195 = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait();
        c = L_1195;
        local L_1196 = c:WaitForChild("Humanoid");
        h = L_1196;
        local L_1197 = h:FindFirstChildOfClass("Animator") or Instance.new("Animator", h);
        a = L_1197;
        local L_1198 = Instance.new("Animation");
        anim = L_1198;
        anim.AnimationId = "rbxassetid://10480796021";
        a:LoadAnimation(anim):Play();
    end;
    return ;
end;
pressQD = function(...)
    if q == true then
        q = false;
        local L_1199 = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait();
        c = L_1199;
        local L_1200 = c:WaitForChild("Humanoid");
        h = L_1200;
        local L_1201 = h:FindFirstChildOfClass("Animator") or Instance.new("Animator", h);
        a = L_1201;
        local L_1202 = Instance.new("Animation");
        anim = L_1202;
        anim.AnimationId = "rbxassetid://10480793962";
        a:LoadAnimation(anim):Play();
    end;
    return ;
end;
performDash = function(...)
    if toggle and target then
        local L_1203 = game.Players.LocalPlayer.Character;
        if L_1203 then
            local L_1204 = L_1203:FindFirstChild("HumanoidRootPart");
            p = L_1204;
            if p then
                if not (p.Position.Y > 442) then
                    local L_1205 = target == dummy and target.HumanoidRootPart or target.Character.HumanoidRootPart;
                    targetHRP = L_1205;
                    if targetHRP and not (targetHRP.Position.Y > 448) then
                        if not ((targetHRP.CFrame.Position - p.CFrame.Position).Magnitude > L_110.sideDashDistance) and f then
                            click = true;
                            f = false;
                            noClip = false;
                            m = true;
                            a = true;
                            dash();
                            task.spawn(function(...)
                                task.delay(L_110.sideDashDuration, function(...)
                                    silent = false;
                                    m = false;
                                    noClip = true;
                                    q = true;
                                    task.spawn(function(...)
                                        local L_1206 = game:GetService("RunService").Stepped:Connect(function(...)
                                            aimlock(target);
                                            task.delay(0.5, function(...)
                                                ran:Disconnect();
                                                return ;
                                            end);
                                            return ;
                                        end);
                                        ran = L_1206;
                                        return ;
                                    end);
                                    task.wait(L_110.sideDashCooldown);
                                    f = true;
                                    return ;
                                end);
                                return ;
                            end);
                            task.spawn(function(...)
                                task.delay(L_110.sideDashDelay, function(...)
                                    simulateLeftClickMobile();
                                    click = false;
                                    return ;
                                end);
                                return ;
                            end);
                            local L_1207 = (targetHRP.Position - p.Position).Unit;
                            direction = L_1207;
                            local L_1208 = targetHRP.CFrame.LookVector;
                            forward = L_1208;
                            local L_1209 = Vector3.new(direction.X, 0, direction.Z).Unit;
                            di = L_1209;
                            local L_1210 = Vector3.new(di.Z, 0, -di.X);
                            jok = L_1210;
                            local L_1211 = Vector3.new(-di.Z, 0, di.X);
                            jok2 = L_1211;
                            local L_1212 = targetHRP.Position + jok * L_110.sideDashRange;
                            des = L_1212;
                            local L_1213 = targetHRP.Position + jok2 * L_110.sideDashRange;
                            des100 = L_1213;
                            local L_1214 = (des - p.Position).Unit;
                            des1 = L_1214;
                            local L_1215 = (des100 - p.Position).Unit;
                            des70 = L_1215;
                            if not ((targetHRP.Position + targetHRP.CFrame.RightVector * L_110.sideDashRange - p.CFrame.Position).Magnitude < (targetHRP.Position + -targetHRP.CFrame.RightVector * L_110.sideDashRange - p.CFrame.Position).Magnitude) then
                                if not (forward:Dot(direction) < 0) then
                                    if forward:Dot(direction) > 0 then
                                        silent = true;
                                        pressQA();
                                        L_1203.Humanoid.AutoRotate = false;
                                        local L_1219 = game:GetService("RunService").Stepped:Connect(function(...)
                                            local L_1216 = L_1203.HumanoidRootPart;
                                            p = L_1216;
                                            local L_1217 = targetHRP.Position + targetHRP.CFrame.RightVector * L_110.sideDashRange;
                                            des = L_1217;
                                            local L_1218 = targetHRP.Position + -targetHRP.CFrame.RightVector * L_110.sideDashRange;
                                            des100 = L_1218;
                                            silentAim(target, -1);
                                            if not m then
                                                run:Disconnect();
                                            end;
                                            return ;
                                        end);
                                        run = L_1219;
                                        sideDashConnections.silentRun = run;
                                    end;
                                else
                                    silent = true;
                                    pressQD();
                                    L_1203.Humanoid.AutoRotate = false;
                                    local L_1223 = game:GetService("RunService").Stepped:Connect(function(...)
                                        local L_1220 = L_1203.HumanoidRootPart;
                                        p = L_1220;
                                        local L_1221 = targetHRP.Position + targetHRP.CFrame.RightVector * L_110.sideDashRange;
                                        des = L_1221;
                                        local L_1222 = targetHRP.Position + -targetHRP.CFrame.RightVector * L_110.sideDashRange;
                                        des100 = L_1222;
                                        silentAim(target, 1);
                                        if not m then
                                            run:Disconnect();
                                        end;
                                        return ;
                                    end);
                                    run = L_1223;
                                    sideDashConnections.silentRun = run;
                                end;
                            elseif not (forward:Dot(direction) < 0) then
                                if forward:Dot(direction) > 0 then
                                    silent = true;
                                    pressQD();
                                    L_1203.Humanoid.AutoRotate = false;
                                    local L_1227 = game:GetService("RunService").Stepped:Connect(function(...)
                                        local L_1224 = L_1203.HumanoidRootPart;
                                        p = L_1224;
                                        local L_1225 = targetHRP.Position + targetHRP.CFrame.RightVector * L_110.sideDashRange;
                                        des = L_1225;
                                        local L_1226 = targetHRP.Position + -targetHRP.CFrame.RightVector * L_110.sideDashRange;
                                        des100 = L_1226;
                                        silentAim(target, 1);
                                        if not m then
                                            run:Disconnect();
                                        end;
                                        return ;
                                    end);
                                    run = L_1227;
                                    sideDashConnections.silentRun = run;
                                end;
                            else
                                silent = true;
                                pressQA();
                                L_1203.Humanoid.AutoRotate = false;
                                local L_1231 = game:GetService("RunService").Stepped:Connect(function(...)
                                    local L_1228 = L_1203.HumanoidRootPart;
                                    p = L_1228;
                                    local L_1229 = targetHRP.Position + targetHRP.CFrame.RightVector * L_110.sideDashRange;
                                    des = L_1229;
                                    local L_1230 = targetHRP.Position + -targetHRP.CFrame.RightVector * L_110.sideDashRange;
                                    des100 = L_1230;
                                    silentAim(target, -1);
                                    if not m then
                                        run:Disconnect();
                                    end;
                                    return ;
                                end);
                                run = L_1231;
                                sideDashConnections.silentRun = run;
                            end;
                            dashLoop = nil;
                            local L_1242 = game:GetService("RunService").Heartbeat:Connect(function(...)
                                if m then
                                    local L_1232 = L_1203.HumanoidRootPart;
                                    p = L_1232;
                                    local L_1233 = targetHRP.AssemblyLinearVelocity;
                                    pred = L_1233;
                                    local L_1234 = targetHRP.Position + jok * L_110.sideDashRange + pred * L_110.sideDashPrediction;
                                    des = L_1234;
                                    local L_1235 = targetHRP.Position + jok2 * L_110.sideDashRange + pred * L_110.sideDashPrediction;
                                    des100 = L_1235;
                                    local L_1236 = des + des1 * L_110.sideDashReach;
                                    des2 = L_1236;
                                    local L_1237 = des100 + des70 * L_110.sideDashReach;
                                    des50 = L_1237;
                                    local L_1238 = Vector3.new(des50.X, p.Position.Y, des50.Z);
                                    fDes2 = L_1238;
                                    local L_1239 = Vector3.new(des2.X, p.Position.Y, des2.Z);
                                    fDes = L_1239;
                                    ps = nil;
                                    if not ((targetHRP.Position + targetHRP.CFrame.RightVector * L_110.sideDashRange - p.CFrame.Position).Magnitude < (targetHRP.Position + -targetHRP.CFrame.RightVector * L_110.sideDashRange - p.CFrame.Position).Magnitude) then
                                        local L_1240 = CFrame.new(fDes2);
                                        ps = L_1240;
                                    else
                                        local L_1241 = CFrame.new(fDes);
                                        ps = L_1241;
                                    end;
                                    setDashVelocity(p, ps.Position, L_110.sideDashDuration);
                                    return ;
                                end;
                                if dashLoop then
                                    pcall(function(...)
                                        dashLoop:Disconnect();
                                        return ;
                                    end);
                                    dashLoop = nil;
                                end;
                                return ;
                            end);
                            dashLoop = L_1242;
                            sideDashConnections.dashLoop = dashLoop;
                            task.delay(L_110.sideDashDuration, function(...)
                                m = false;
                                stopDash();
                                return ;
                            end);
                            return ;
                        end;
                        return ;
                    end;
                    return ;
                end;
                return ;
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
createMobileDashButton = function(...)
    if not mobileDashGui then
        local L_1243 = Instance.new("ScreenGui");
        mobileDashGui = L_1243;
        mobileDashGui.Parent = game:GetService("CoreGui");
        mobileDashGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
        local L_1244 = Instance.new("ImageButton");
        dashButton = L_1244;
        dashButton.Parent = mobileDashGui;
        dashButton.Position = UDim2.new(0.9, 0, 0.8, 0);
        dashButton.Size = UDim2.new(0, 60, 0, 60);
        dashButton.BackgroundColor3 = Color3.fromRGB(12, 12, 12);
        dashButton.BackgroundTransparency = 0.3;
        dashButton.Image = "rbxassetid://12443244342";
        dashButton.ImageColor3 = Color3.fromRGB(255, 0, 0);
        dashButton.Draggable = true;
        dashButton.Active = true;
        dashButton.Selectable = true;
        dashButton.MouseButton1Click:Connect(performDash);
        local L_1245 = Instance.new("UICorner");
        uicorner = L_1245;
        uicorner.CornerRadius = UDim.new(0, 10);
        uicorner.Parent = dashButton;
        return ;
    end;
    return ;
end;
setupFakeMobile = function(...)
    sideDashConnections.fakeMouse = mouse.Button1Down:Connect(function(...)
        if os.clock() - lastTapTime < 0.3 then
            getdiddy(Vector2.new(mouse.X, mouse.Y));
        end;
        local L_1246 = os.clock();
        lastTapTime = L_1246;
        return ;
    end);
    return ;
end;
cleanupFakeMobile = function(...)
    if sideDashConnections.fakeMouse then
        sideDashConnections.fakeMouse:Disconnect();
        sideDashConnections.fakeMouse = nil;
    end;
    return ;
end;
setupSideDash = function(...)
    local L_1247 = game:GetService("UserInputService");
    uis = L_1247;
    local L_1248 = game:GetService("UserInputService");
    U = L_1248;
    local L_1249 = workspace.CurrentCamera;
    C = L_1249;
    local L_1250 = game:GetService("Players");
    P = L_1250;
    local L_1251 = game.Players.LocalPlayer.Character;
    if L_1251 then
        sideDashConnections.autoRotate = L_1251.Humanoid:GetPropertyChangedSignal("AutoRotate"):Connect(function(...)
            if L_110.sideDashSilent and L_1251.Humanoid.AutoRotate then
                L_1251.Humanoid.AutoRotate = false;
            end;
            return ;
        end);
    end;
    sideDashConnections.characterAdded = game.Players.LocalPlayer.CharacterAdded:Connect(function(L_1252, ...)
        local L_1253 = L_1252;
        L_1251 = L_1253;
        sideDashConnections.autoRotate = L_1253:WaitForChild("Humanoid"):GetPropertyChangedSignal("AutoRotate"):Connect(function(...)
            if L_110.sideDashSilent and L_1253.Humanoid.AutoRotate then
                L_1253.Humanoid.AutoRotate = false;
            end;
            return ;
        end);
        return ;
    end);
    sideDashConnections.playerRemoving = game.Players.PlayerRemoving:Connect(function(L_1254, ...)
        if target == L_1254 then
            if target.Character then
                removeHighlight(target.Character);
            end;
            target = nil;
            toggle = false;
        end;
        return ;
    end);
    sideDashConnections.healthLoop = game:GetService("RunService").Heartbeat:Connect(function(...)
        if toggle then
            local L_1255 = game.Workspace.Live:FindFirstChild("Weakest Dummy");
            dummy = L_1255;
            if target == nil or target ~= dummy then
                if target ~= nil and target ~= dummy then
                    local L_1256 = target.Character:FindFirstChild("Humanoid");
                    oppo = L_1256;
                    if oppo and oppo.Health == 0 then
                        toggle = false;
                        removeHighlight(target.Character);
                        target = nil;
                    end;
                end;
            elseif target.Humanoid.Health == 0 then
                toggle = false;
                removeHighlight(target);
                target = nil;
            end;
        end;
        return ;
    end);
    sideDashConnections.touchInput = U.InputBegan:Connect(function(L_1257, L_1258, ...)
        if not L_1258 then
            if L_1257.UserInputType == Enum.UserInputType.Touch then
                if os.clock() - lastTapTime < 0.3 then
                    getdiddy(L_1257.Position);
                end;
                local L_1259 = os.clock();
                lastTapTime = L_1259;
            end;
            return ;
        end;
        return ;
    end);
    sideDashConnections.keyInput = uis.InputBegan:Connect(function(L_1260, L_1261, ...)
        if not L_1261 then
            L_1261 = not L_110.sideDashEnabled;
        end;
        if not L_1261 then
            if L_1260.UserInputType == Enum.UserInputType.Keyboard then
                if L_1260.KeyCode == Enum.KeyCode.V then
                    GetTarget();
                end;
                if L_1260.KeyCode == Enum.KeyCode.C then
                    performDash();
                end;
            end;
            return ;
        end;
        return ;
    end);
    if L_110.sideDashMobileMode then
        createMobileDashButton();
    end;
    if L_110.sideDashFakeMobile then
        setupFakeMobile();
    end;
    return ;
end;
cleanupSideDash = function(...)
    local L_1262 = { pairs(sideDashConnections) };
    local L_1263 = L_1262[2];
    local L_1264 = L_1262[3];
    local L_1265 = L_1262[1];
    while true do
        local L_1266;
        L_1264, L_1266 = L_1265(L_1263, L_1264);
        if not L_1264 then
            break;
        end;
        if L_1266 then
            L_1266:Disconnect();
        end;
    end;
    sideDashConnections = {};
    if target then
        local L_1267 = target == dummy and target or target.Character;
        char = L_1267;
        removeHighlight(char);
    end;
    target = nil;
    toggle = false;
    stopDash();
    silent = false;
    if game.Players.LocalPlayer.Character then
        game.Players.LocalPlayer.Character.Humanoid.AutoRotate = true;
    end;
    if mobileDashGui then
        mobileDashGui:Destroy();
        mobileDashGui = nil;
    end;
    return ;
end;
L_1268 = L_138.HitboxAbuse;
L_1268:Paragraph({ Title = "Hitbox Abuse (W.I.P)", Desc = "Side M1[THIS ONLY WORKS FOR PC FOR NOW!]", Image = "geist:box", ImageSize = 20, Color = Color3.fromHex("#26067e") });
L_1269 = { Enabled = false, Angle = 45, Duration = 50, Delay = 0, SilentLock = false, simpleShowHitbox = false };
L_1270 = {};
L_1282 = function(L_1271, ...)
    local L_1272 = L_106.Character;
    if L_1272 then
        local L_1273 = L_1272:FindFirstChild("HumanoidRootPart");
        if L_1273 then
            local L_1274 = L_1272:FindFirstChildOfClass("Humanoid");
            local L_1275 = L_1274 and L_1274.AutoRotate;
            if L_1274 then
                L_1274.AutoRotate = false;
            end;
            L_1273.CFrame = L_1273.CFrame * CFrame.Angles(0, math.rad(L_1271), 0);
            local L_1276 = L_498 and L_498.CFrame.Position or L_1273.Position + Vector3.new(0, 5, 0);
            local L_1277 = L_1276.Y;
            local L_1278 = L_1276 - L_1273.Position;
            local L_1279 = Vector3.new(L_1278.X, 0, L_1278.Z);
            local L_1280 = CFrame.fromAxisAngle(Vector3.yAxis, math.rad(L_1271)) * L_1279;
            local L_1281 = L_1273.Position + L_1280;
            if L_498 and L_498:IsA("Camera") then
                L_498.CFrame = CFrame.lookAt(Vector3.new(L_1281.X, L_1277, L_1281.Z), L_1273.Position);
            end;
            if L_1274 then
                task.delay(L_1269.Duration / 1000, function(...)
                    if L_1274 and L_1274.Parent then
                        L_1274.AutoRotate = L_1275;
                    end;
                    return ;
                end);
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
L_1283 = function(...)
    task.delay(L_1269.Duration / 1000, function(...)
        L_1282(-L_1269.Angle);
        return ;
    end);
    return ;
end;
L_1288 = function(...)
    local L_1284 = L_106.Character;
    if L_1284 then
        local L_1285 = L_1284:FindFirstChild("HumanoidRootPart");
        if L_1285 then
            local L_1286 = L_1284:FindFirstChildOfClass("Humanoid");
            local L_1287 = L_1286 and L_1286.AutoRotate;
            if L_1286 then
                L_1286.AutoRotate = false;
            end;
            L_1285.CFrame = L_1285.CFrame * CFrame.Angles(0, math.rad(L_1269.Angle), 0);
            if L_1286 then
                task.delay(L_1269.Duration / 1000, function(...)
                    if L_1286 and L_1286.Parent then
                        L_1286.AutoRotate = L_1287;
                        L_1285.CFrame = L_1285.CFrame * CFrame.Angles(0, math.rad(-L_1269.Angle), 0);
                    end;
                    return ;
                end);
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
L_1291 = function(...)
    if L_1270.InputHandler then
        L_1270.InputHandler:Disconnect();
        L_1270.InputHandler = nil;
    end;
    if L_1269.Enabled then
        L_1270.InputHandler = L_86.InputBegan:Connect(function(L_1289, L_1290, ...)
            if L_1269.Enabled and not L_1290 then
                if L_1289.UserInputType == Enum.UserInputType.MouseButton1 then
                    task.wait(L_1269.Delay / 1000);
                    if not L_1269.SilentLock then
                        L_1282(L_1269.Angle);
                        L_1283();
                    else
                        L_1288();
                    end;
                end;
                return ;
            end;
            return ;
        end);
    end;
    return ;
end;
L_1292 = { hitboxPart = nil, selectionBox = nil, offsetCFrame = nil, renderSteppedConn = nil };
L_1269.hitboxColor = L_1269.hitboxColor or Color3.fromRGB(255, 0, 0);
L_1297 = function(...)
    if L_1292.renderSteppedConn then
        L_1292.renderSteppedConn:Disconnect();
        L_1292.renderSteppedConn = nil;
    end;
    if L_1292.selectionBox then
        L_1292.selectionBox:Destroy();
        L_1292.selectionBox = nil;
    end;
    if L_1292.hitboxPart then
        L_1292.hitboxPart:Destroy();
        L_1292.hitboxPart = nil;
    end;
    L_1292.offsetCFrame = nil;
    if L_1269.simpleShowHitbox then
        local L_1293 = L_83.LocalPlayer;
        if L_1293 then
            if (L_1293.Character or L_1293.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart", 5) then
                local L_1294 = Instance.new("Part");
                L_1294.Name = "ScriptSimpleHitboxVisual_HitboxAbuse";
                L_1294.Size = Vector3.new(8, 5, 8);
                L_1294.Transparency = 1;
                L_1294.Anchored = true;
                L_1294.CanCollide = false;
                L_1294.Parent = workspace;
                L_1292.hitboxPart = L_1294;
                local L_1295 = Instance.new("SelectionBox");
                L_1295.Name = "ScriptSimpleHitboxVisual_Outline";
                L_1295.Adornee = L_1294;
                L_1295.LineThickness = 0.05;
                L_1295.Color3 = L_1269.hitboxColor or Color3.fromRGB(255, 0, 0);
                L_1295.Transparency = 0.5;
                L_1295.Parent = L_1294;
                L_1292.selectionBox = L_1295;
                L_1292.offsetCFrame = CFrame.new(0, 0, -(L_1294.Size.Z / 2 - 1));
                L_1292.renderSteppedConn = L_84.RenderStepped:Connect(function(...)
                    local L_1296 = L_1293.Character;
                    if L_1296 then
                        L_1296 = L_1296:FindFirstChild("HumanoidRootPart");
                    end;
                    if L_1269.simpleShowHitbox and (L_1296 and (L_1296.Parent and (L_1292.hitboxPart and L_1292.hitboxPart.Parent))) then
                        if L_1292.hitboxPart and L_1292.offsetCFrame then
                            L_1292.hitboxPart.CFrame = L_1296.CFrame * L_1292.offsetCFrame;
                        end;
                        if L_1292.selectionBox and L_1292.selectionBox.Color3 ~= L_1269.hitboxColor then
                            L_1292.selectionBox.Color3 = L_1269.hitboxColor;
                        end;
                        return ;
                    end;
                    if L_1292.renderSteppedConn then
                        L_1292.renderSteppedConn:Disconnect();
                        L_1292.renderSteppedConn = nil;
                    end;
                    if L_1292.selectionBox then
                        L_1292.selectionBox:Destroy();
                        L_1292.selectionBox = nil;
                    end;
                    if L_1292.hitboxPart then
                        L_1292.hitboxPart:Destroy();
                        L_1292.hitboxPart = nil;
                    end;
                    L_1292.offsetCFrame = nil;
                    return ;
                end);
                return ;
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
L_1268:Toggle({
    Title = "Enable ",
    Value = L_1269.Enabled,
    Callback = function(L_1298, ...)
        L_1269.Enabled = L_1298;
        L_1291();
        return ;
    end
});
L_1268:Toggle({
    Title = "Silent Lock",
    Value = L_1269.SilentLock,
    Callback = function(L_1299, ...)
        L_1269.SilentLock = L_1299;
        return ;
    end
});
L_138.HitboxAbuse:Toggle({
    Title = "Simple Show Hitbox",
    Value = L_1269.simpleShowHitbox,
    Callback = function(L_1300, ...)
        L_1269.simpleShowHitbox = L_1300;
        L_1297();
        return ;
    end
});
L_138.HitboxAbuse:Colorpicker({
    Title = "Hitbox Color",
    Desc = "Pick a color for the hitbox outline",
    Default = L_1269.hitboxColor or Color3.fromRGB(255, 0, 0),
    Transparency = 0,
    Locked = false,
    Callback = function(L_1301, ...)
        local L_1302 = type(L_1301) == "table" and L_1301.Color or L_1301;
        L_1269.hitboxColor = L_1302;
        if L_1292.selectionBox then
            L_1292.selectionBox.Color3 = L_1302;
        end;
        return ;
    end
});
L_1268:Slider({
    Title = "Angle (degrees)",
    Value = { Min = 0, Max = 180, Default = L_1269.Angle },
    Callback = function(L_1303, ...)
        L_1269.Angle = L_1303;
        return ;
    end
});
L_1268:Slider({
    Title = "Duration (ms)",
    Value = { Min = 10, Max = 500, Default = L_1269.Duration },
    Callback = function(L_1304, ...)
        L_1269.Duration = L_1304;
        return ;
    end
});
L_1268:Slider({
    Title = "Delay (ms)",
    Value = { Min = 0, Max = 200, Default = L_1269.Delay },
    Callback = function(L_1305, ...)
        L_1269.Delay = L_1305;
        return ;
    end
});
L_1309 = function(L_1306, ...)
    local L_1307 = workspace.CurrentCamera;
    local L_1308 = L_1306 / 100;
    L_1307.CFrame = L_1307.CFrame * CFrame.new(0, 0, 0, 1, 0, 0, 0, L_1308, 0, 0, 0, 1);
    return ;
end;
L_1310 = nil;
L_1311 = function(...)
    if L_1310 then
        L_1310:Disconnect();
        L_1310 = nil;
    end;
    if L_110.stretchScreenValue ~= 100 then
        L_1310 = L_84.RenderStepped:Connect(function(...)
            L_1309(L_110.stretchScreenValue);
            return ;
        end);
    end;
    return ;
end;
L_1320 = function(...)
    if L_111.respawnAtDeath then
        L_111.respawnAtDeath:Disconnect();
        L_111.respawnAtDeath = nil;
    end;
    if L_110.respawnAtDeath then
        getgenv().RespawnAtDeathPos = true;
        getgenv()._LastDeathPosition = nil;
        local L_1316 = function(...)
            local L_1312 = L_106.Character or L_106.CharacterAdded:Wait();
            local L_1313 = L_1312:FindFirstChildOfClass("Humanoid");
            local L_1314 = L_1312:FindFirstChild("HumanoidRootPart");
            local L_1315 = L_1313;
            if L_1313 then
                L_1315 = L_1314;
            end;
            if L_1315 then
                L_111.diedConn = L_1313.Died:Connect(function(...)
                    if L_110.respawnAtDeath then
                        getgenv()._LastDeathPosition = L_1314.Position;
                    end;
                    return ;
                end);
            end;
            return ;
        end;
        L_111.respawnAtDeath = L_106.CharacterAdded:Connect(function(L_1317, ...)
            if L_110.respawnAtDeath then
                local L_1318 = getgenv()._LastDeathPosition;
                if L_1318 then
                    local L_1319 = L_1317:WaitForChild("HumanoidRootPart", 5);
                    if L_1319 then
                        L_1319.CFrame = CFrame.new(L_1318 + Vector3.new(0, 3, 0));
                    end;
                end;
                getgenv()._LastDeathPosition = nil;
                L_1316();
                return ;
            end;
            return ;
        end);
        L_1316();
        return ;
    end;
    return ;
end;
L_1321 = nil;
L_1322 = false;
L_1323 = false;
L_1327 = function(L_1324, ...)
    local L_1325 = L_87.CurrentCamera;
    if L_1325 then
        local L_1326 = L_1325.ViewportSize / 2;
        L_88:SendMouseButtonEvent(L_1326.X, L_1326.Y, 0, L_1324, game, 0);
        return ;
    end;
    return ;
end;
L_1329 = function(L_1328, ...)
    if not L_1322 then
        L_1322 = true;
        L_1327(true);
        task.delay(L_1328 / 1000, function(...)
            L_1327(false);
            L_1322 = false;
            return ;
        end);
        return ;
    end;
    return ;
end;
L_1333 = function(L_1330, ...)
    if L_1330 and L_1330 ~= L_106.Character then
        local L_1331 = L_1330:FindFirstChildOfClass("Humanoid");
        local L_1332 = L_1330:FindFirstChild("HumanoidRootPart");
        if L_1331 then
            if L_1332 then
                L_1332 = L_1331.Health > 0;
            end;
            L_1331 = L_1332;
        end;
        return L_1331;
    end;
    return false;
end;
L_1336 = function(L_1334, L_1335, ...)
    return L_1334.Position + L_1334.Velocity * (L_1335 / 100);
end;
L_1341 = function(L_1337, L_1338, L_1339, ...)
    if L_1338 then
        local L_1340 = L_1337.CFrame:PointToObjectSpace(L_1338);
        return L_1340.Z < 0 and (math.abs(L_1340.X) <= L_1339.X / 2 and (math.abs(L_1340.Y) <= L_1339.Y / 2 and math.abs(L_1340.Z) <= L_1339.Z / 2));
    end;
    return false;
end;
L_1358 = function(...)
    local L_1342 = L_106.Character;
    local L_1343 = L_1342;
    if L_1342 then
        L_1343 = L_1342:FindFirstChild("HumanoidRootPart");
    end;
    if L_1343 then
        local L_1344 = L_110.m1Range;
        local L_1345 = Vector3.new(4, 4, L_1344);
        local L_1346 = L_1343.CFrame * CFrame.new(0, 0, -(L_1344 / 2));
        local L_1347 = OverlapParams.new();
        L_1347.FilterType = Enum.RaycastFilterType.Exclude;
        L_1347.FilterDescendantsInstances = { L_1342 };
        local L_1348 = L_87:GetPartBoundsInBox(L_1346, L_1345, L_1347);
        local L_1349 = L_110.m1Pred;
        local L_1350 = { ipairs(L_1348) };
        local L_1351 = L_1350[1];
        local L_1352 = L_1350[2];
        local L_1353 = L_1350[3];
        repeat
            local L_1354;
            repeat
                local L_1355;
                repeat
                    local L_1356;
                    L_1353, L_1356 = L_1351(L_1352, L_1353);
                    if not L_1353 then
                        return false;
                    end;
                    L_1355 = L_1356:FindFirstAncestorOfClass("Model");
                until L_1333(L_1355);
                L_1354 = L_1355:FindFirstChild("HumanoidRootPart");
            until L_1354;
            local L_1357 = L_1336(L_1354, L_1349);
        until L_1341(L_1343, L_1357, L_1345);
        return true;
    end;
    return false;
end;
L_1361 = function(...)
    if L_1321 then
        L_1321:Disconnect();
    end;
    L_1321 = L_84.Heartbeat:Connect(function(...)
        local L_1359 = L_1358();
        local L_1360 = L_1359;
        if L_1359 then
            L_1360 = not L_1323 and not L_1322;
        end;
        if L_1360 then
            L_1323 = true;
            L_1329(L_110.m1Hold);
        end;
        if not L_1359 then
            L_1323 = false;
        end;
        return ;
    end);
    return ;
end;
L_1362 = function(...)
    if L_1321 then
        L_1321:Disconnect();
        L_1321 = nil;
    end;
    L_1323 = false;
    L_1322 = false;
    return ;
end;
L_1364 = function(L_1363, ...)
    if not L_1363 then
        L_1362();
    else
        L_1361();
    end;
    return ;
end;
L_1422 = function(...)
    if L_110.fpsBoost then
        local L_1365 = game:GetService("Lighting");
        local L_1366 = game:GetService("Players");
        game:GetService("UserInputService");
        local L_1367 = L_1366.LocalPlayer;
        local L_1368 = true;
        local L_1369 = workspace.Map;
        if true then
            if L_1369:FindFirstChild("GrassBottom") then
                L_1369.GrassBottom:Destroy();
            end;
            if L_1369:FindFirstChild("GrassTop") then
                L_1369.GrassTop:Destroy();
            end;
            if L_1369:FindFirstChild("Grass") then
                L_1369.Grass:Destroy();
            end;
        end;
        if true and L_1369:FindFirstChild("Trash") then
            L_1369.Trash:Destroy();
        end;
        if true and L_1369:FindFirstChild("Trees") then
            L_1369.Trees:Destroy();
        end;
        if true then
            if L_1369:FindFirstChild("Walls") then
                L_1369.Walls:Destroy();
            end;
            if L_1369:FindFirstChild("GrassTop") then
                L_1369.GrassTop:Destroy();
            end;
            if L_1369:FindFirstChild("Grass") then
                L_1369.Grass:Destroy();
            end;
        end;
        if L_1368 then
            if L_1369:FindFirstChild("Total Kills Leaderboard") then
                L_1369["Total Kills Leaderboard"]:Destroy();
            end;
            if L_1369:FindFirstChild("Total Kills Leaderboard Real") then
                L_1369["Total Kills Leaderboard Real"]:Destroy();
            end;
        end;
        if true and L_1369:FindFirstChild("Benchs") then
            L_1369.Benchs:Destroy();
        end;
        if true then
            local L_1370 = { pairs(workspace:GetDescendants()) };
            local L_1371 = L_1370[1];
            local L_1372 = L_1370[3];
            local L_1373 = L_1370[2];
            while true do
                local L_1374;
                L_1372, L_1374 = L_1371(L_1373, L_1372);
                if not L_1372 then
                    break;
                end;
                if L_1374:IsA("BasePart") then
                    L_1374.CastShadow = false;
                end;
            end;
        end;
        if true and workspace:FindFirstChild("Thrown") then
            local L_1375 = { pairs(workspace.Thrown:GetChildren()) };
            local L_1376 = L_1375[2];
            local L_1377 = L_1375[3];
            local L_1378 = L_1375[1];
            while true do
                local L_1379;
                L_1377, L_1379 = L_1378(L_1376, L_1377);
                if not L_1377 then
                    break;
                end;
                if L_1379.Name ~= "Aurora" and L_1379.Name ~= "Donation Leaderboard" then
                    L_1379:Destroy();
                end;
            end;
            if L_1368 then
                L_1368 = workspace.Thrown:FindFirstChild("Donation Leaderboard");
            end;
            if L_1368 then
                workspace.Thrown["Donation Leaderboard"]:Destroy();
            end;
        end;
        pcall(function(...)
            settings().Rendering.QualityLevel = 1;
            return ;
        end);
        pcall(function(...)
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01;
            return ;
        end);
        pcall(function(...)
            settings().Physics.ThrottleAdjustTime = 5;
            return ;
        end);
        L_1365.FogEnd = 1000000;
        L_1365.FogStart = 1000000;
        L_1365.FogColor = Color3.new(0, 0, 0);
        L_1365.GlobalShadows = false;
        L_1365.Brightness = 2;
        L_1365.ClockTime = 12;
        L_1365.EnvironmentDiffuseScale = 0;
        L_1365.EnvironmentSpecularScale = 0;
        L_1365.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5);
        local L_1380 = { ipairs(workspace:GetDescendants()) };
        local L_1381 = L_1380[2];
        local L_1382 = L_1380[3];
        local L_1383 = L_1380[1];
        while true do
            local L_1384;
            L_1382, L_1384 = L_1383(L_1381, L_1382);
            if not L_1382 then
                break;
            end;
            local L_1385 = L_1384;
            if L_1385:IsA("ParticleEmitter") or (L_1385:IsA("Trail") or (L_1385:IsA("Fire") or (L_1385:IsA("Smoke") or L_1385:IsA("Sparkles")))) then
                pcall(function(...)
                    L_1385:Destroy();
                    return ;
                end);
            end;
            if L_1385:IsA("Part") or (L_1385:IsA("MeshPart") or L_1385:IsA("UnionOperation")) then
                L_1385.Material = Enum.Material.SmoothPlastic;
                L_1385.Reflectance = 0;
                L_1385.CastShadow = false;
            end;
            if L_1385:IsA("Decal") or (L_1385:IsA("Texture") or L_1385:IsA("SurfaceGui")) then
                pcall(function(...)
                    L_1385:Destroy();
                    return ;
                end);
            end;
            if L_1385:IsA("Light") then
                pcall(function(...)
                    L_1385:Destroy();
                    return ;
                end);
            end;
        end;
        if workspace:FindFirstChildOfClass("Terrain") then
            workspace.Terrain.Decoration = false;
            workspace.Terrain.WaterWaveSize = 0;
            workspace.Terrain.WaterWaveSpeed = 0;
            workspace.Terrain.WaterReflectance = 0;
            workspace.Terrain.WaterTransparency = 1;
        end;
        getgenv().Settings = getgenv().Settings or {};
        Settings.Limb = Settings.Limb or {};
        Settings.Limb.Arms = Settings.Limb.Arms == nil and true or Settings.Limb.Arms;
        Settings.Limb.Legs = Settings.Limb.Legs == nil and true or Settings.Limb.Legs;
        Settings.Shiftlock = Settings.Shiftlock == nil and true or Settings.Shiftlock;
        if not getgenv().executed then
            local L_1392 = function(L_1386, ...)
                local L_1387 = L_1386;
                if L_1387 then
                    local L_1388 = {
                        pcall(function(...)
                            return L_1387.Character;
                        end)
                    };
                    local L_1389 = L_1388[1];
                    local L_1390 = L_1388[2];
                    if L_1389 and L_1390 then
                        local L_1391 = L_1390:FindFirstChildOfClass("Humanoid");
                        if not L_1391 then
                            pcall(function(...)
                                L_1387:LoadCharacter();
                                return ;
                            end);
                        else
                            pcall(function(...)
                                L_1391.Health = 0;
                                return ;
                            end);
                            task.wait(0.15);
                            if L_1387.Character == L_1390 then
                                pcall(function(...)
                                    L_1387:LoadCharacter();
                                    return ;
                                end);
                            end;
                        end;
                        return ;
                    end;
                    pcall(function(...)
                        L_1387:LoadCharacter();
                        return ;
                    end);
                    return ;
                end;
                return ;
            end;
            local L_1393 = nil;
            L_1393 = hookmetamethod(game, "__namecall", function(L_1394, ...)
                local L_1395 = L_1394;
                local L_1396 = getnamecallmethod();
                local L_1397 = { ... };
                local L_1398 = {
                    pcall(function(...)
                        return L_1395 and L_1395.Name;
                    end)
                };
                local L_1399 = L_1398[2];
                if L_1398[1] and (L_1399 == "Communicate" and (L_1396 == "FireServer" and (type(L_1397[1]) == "table" and L_1397[1].Goal == "Reset"))) then
                    task.spawn(function(...)
                        L_1392(L_1367);
                        return ;
                    end);
                end;
                return L_1393(L_1395, ...);
            end);
            local L_1400 = nil;
            L_1400 = hookmetamethod(game, "__newindex", function(L_1401, L_1402, L_1403, ...)
                local L_1404 = L_1401;
                local L_1405 = L_1402;
                local L_1406 = {
                    pcall(function(...)
                        return L_1405;
                    end)
                };
                local L_1407 = L_1406[1];
                local L_1408 = L_1406[2];
                if L_1407 then
                    L_1407 = L_1408 == "Parent";
                end;
                if L_1407 then
                    local L_1409 = pcall(function(...)
                        return L_1404:IsA("ParticleEmitter");
                    end) and L_1404:IsA("ParticleEmitter");
                    if L_1403 == workspace:FindFirstChild("Thrown") or L_1409 then
                        pcall(function(...)
                            L_1404:Destroy();
                            return ;
                        end);
                        return nil;
                    end;
                end;
                return L_1400(L_1404, L_1405, L_1403);
            end);
            if workspace:FindFirstChild("Thrown") then
                workspace.Thrown.ChildAdded:Connect(function(L_1410, ...)
                    local L_1411 = L_1410;
                    task.wait();
                    pcall(function(...)
                        L_1411:Destroy();
                        return ;
                    end);
                    return ;
                end);
            end;
            local L_1417 = function(L_1412, ...)
                local L_1413 = L_1412;
                if L_1412 then
                    L_1413 = L_1412.Parent;
                end;
                if L_1413 then
                    local L_1414 = L_1412:FindFirstChild("HumanoidRootPart");
                    if L_1414 then
                        L_1414.ChildAdded:Connect(function(L_1415, ...)
                            local L_1416 = L_1415;
                            if L_1415 then
                                L_1416 = L_1415.Name == "dodgevelocity";
                            end;
                            if not L_1416 then
                                if L_1415 then
                                    L_1415 = (L_1415.Name == "moveme" or L_1415.Name == "Sound") and false;
                                end;
                                if L_1415 then
                                end;
                            end;
                            return ;
                        end);
                        return ;
                    end;
                    return ;
                end;
                return ;
            end;
            local L_1419 = function(...)
                local L_1418 = L_1367.Character or L_1367.CharacterAdded:Wait();
                if L_1418:WaitForChild("HumanoidRootPart", 5) then
                    L_1417(L_1418);
                end;
                return ;
            end;
            if L_1367.Character then
                task.spawn(L_1419);
            end;
            L_1367.CharacterAdded:Connect(function(...)
                task.wait(0.1);
                pcall(L_1419);
                return ;
            end);
            getgenv().executed = true;
        end;
        workspace.DescendantAdded:Connect(function(L_1420, ...)
            local L_1421 = L_1420;
            if L_1421:IsA("ParticleEmitter") or (L_1421:IsA("Trail") or (L_1421:IsA("Fire") or (L_1421:IsA("Smoke") or L_1421:IsA("Sparkles")))) then
                pcall(function(...)
                    L_1421:Destroy();
                    return ;
                end);
            end;
            if L_1421:IsA("Part") or (L_1421:IsA("MeshPart") or L_1421:IsA("UnionOperation")) then
                L_1421.Material = Enum.Material.SmoothPlastic;
                L_1421.Reflectance = 0;
                L_1421.CastShadow = false;
            end;
            if L_1421:IsA("Decal") or L_1421:IsA("Texture") then
                pcall(function(...)
                    L_1421:Destroy();
                    return ;
                end);
            end;
            return ;
        end);
        return ;
    end;
    return ;
end;
L_1423 = {};
L_1429 = function(L_1424, ...)
    local L_1425 = L_1424;
    if L_1425 then
        local L_1426 = {
            pcall(function(...)
                if not L_1425.Animation or not L_1425.Animation.AnimationId then
                    return L_1425.AnimationId;
                end;
                return L_1425.Animation.AnimationId;
            end)
        };
        local L_1427 = L_1426[1];
        local L_1428 = L_1426[2];
        if L_1427 and L_1428 then
            return tostring(L_1428):match("%d+");
        end;
        return nil;
    end;
    return nil;
end;
L_1433 = function(L_1430, ...)
    if L_1430 and L_1430:IsDescendantOf(L_87) then
        local L_1431 = Instance.new("Highlight");
        L_1431.Name = "CounterESP_Highlight";
        L_1431.Adornee = L_1430;
        L_1431.Parent = L_87;
        L_1431.FillColor = Color3.fromRGB(255, 0, 0);
        L_1431.OutlineColor = Color3.fromRGB(80, 0, 0);
        L_1431.FillTransparency = 0;
        L_1431.OutlineTransparency = 0.5;
        task.spawn(function(...)
            task.wait(1.5);
            if L_1431 and L_1431.Parent then
                local L_1432 = L_85:Create(L_1431, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { FillTransparency = 1, OutlineTransparency = 1 });
                L_1432:Play();
                L_1432.Completed:Connect(function(...)
                    if L_1431 and L_1431.Parent then
                        L_1431:Destroy();
                    end;
                    return ;
                end);
            end;
            return ;
        end);
        return ;
    end;
    return ;
end;
L_1440 = function(L_1434, ...)
    local L_1435 = L_1434;
    if L_1423[L_1435] then
        L_1423[L_1435]:Disconnect();
        L_1423[L_1435] = nil;
    end;
    if counterESP then
        L_1423[L_1435] = L_1435.AnimationPlayed:Connect(function(L_1436, ...)
            local L_1437 = L_1429(L_1436);
            if L_1437 then
                L_1437 = L_1437 == "12351854556" or (L_1437 == "15311685628" or L_1437 == "78521642007560");
            end;
            if L_1437 then
                local L_1438 = L_1435.Parent;
                local L_1439 = L_1438;
                if L_1438 then
                    L_1439 = L_1438:IsA("Model");
                end;
                if L_1439 then
                    L_1433(L_1438);
                end;
            end;
            return ;
        end);
        return ;
    end;
    return ;
end;
L_1453 = function(...)
    local L_1441 = { pairs(L_1423) };
    local L_1442 = L_1441[1];
    local L_1443 = L_1441[2];
    local L_1444 = L_1441[3];
    while true do
        local L_1445;
        L_1444, L_1445 = L_1442(L_1443, L_1444);
        if not L_1444 then
            break;
        end;
        if L_1445.Connected then
            L_1445:Disconnect();
        end;
    end;
    L_1423 = {};
    if counterESP then
        local L_1446 = { ipairs(L_87:GetDescendants()) };
        local L_1447 = L_1446[3];
        local L_1448 = L_1446[1];
        local L_1449 = L_1446[2];
        while true do
            local L_1450;
            L_1447, L_1450 = L_1448(L_1449, L_1447);
            if not L_1447 then
                break;
            end;
            if L_1450:IsA("Humanoid") then
                L_1440(L_1450);
            end;
        end;
        L_87.DescendantAdded:Connect(function(L_1451, ...)
            local L_1452 = L_1451;
            if counterESP then
                if L_1452:IsA("Humanoid") then
                    task.delay(0.01, function(...)
                        L_1440(L_1452);
                        return ;
                    end);
                end;
                return ;
            end;
            return ;
        end);
        return ;
    end;
    return ;
end;
L_83 = L_83 or game:GetService("Players");
L_84 = L_84 or game:GetService("RunService");
L_87 = L_87 or game:GetService("Workspace");
L_106 = L_106 or L_83.LocalPlayer;
L_1454 = tspeed or 0.1;
tspeed = L_1454;
L_1455 = tpwalking or false;
tpwalking = L_1455;
L_1456 = character or L_106.Character;
character = L_1456;
L_1457 = humanoid or character and character:FindFirstChildOfClass("Humanoid");
humanoid = L_1457;
L_1458 = humanoidRootPart or character and character:FindFirstChild("HumanoidRootPart");
humanoidRootPart = L_1458;
L_1459 = Teleports or { Middle = CFrame.new(148, 441, 27), AtomicRoom = CFrame.new(1079, 155, 23003), DeathCounter = CFrame.new(-92, 29, 20347), Baseplate = CFrame.new(968, 20, 23088), Mountain1 = CFrame.new(266, 699, 458), Mountain2 = CFrame.new(551, 630, -265), Mountain3 = CFrame.new(-107, 642, -328) };
Teleports = L_1459;
L_106.CharacterAdded:Connect(function(L_1460, ...)
    character = L_1460;
    local L_1461 = L_1460:WaitForChild("Humanoid");
    humanoid = L_1461;
    local L_1462 = L_1460:WaitForChild("HumanoidRootPart");
    humanoidRootPart = L_1462;
    return ;
end);
TeleportTo = function(L_1463, ...)
    if humanoidRootPart and Teleports[L_1463] then
        humanoidRootPart.CFrame = Teleports[L_1463];
    end;
    return ;
end;
L_84.Heartbeat:Connect(function(...)
    if not humanoid or not humanoidRootPart then
        local L_1464 = L_106.Character;
        if L_1464 then
            local L_1465 = humanoid or L_1464:FindFirstChildOfClass("Humanoid");
            humanoid = L_1465;
            local L_1466 = humanoidRootPart or L_1464:FindFirstChild("HumanoidRootPart");
            humanoidRootPart = L_1466;
        end;
    end;
    local L_1467 = tpwalking;
    local L_1468 = tspeed;
    if L_110 then
        if L_110.speedBoost ~= nil then
            L_1467 = L_110.speedBoost;
        end;
        if L_110.speedValue ~= nil then
            L_1468 = L_110.speedValue;
        end;
    end;
    if L_1467 then
        L_1467 = humanoid and (humanoidRootPart and (humanoid.MoveDirection and humanoid.MoveDirection.Magnitude > 0));
    end;
    if L_1467 and L_1468 then
        humanoidRootPart.CFrame = humanoidRootPart.CFrame + humanoid.MoveDirection * L_1468;
    end;
    if humanoid then
        if L_110 and L_110.jumpBoost ~= nil then
            humanoid.UseJumpPower = not L_110.jumpBoost;
        end;
        if L_110 and L_110.jumpValue ~= nil then
            humanoid.JumpHeight = L_110.jumpValue;
        end;
    end;
    if L_110 and L_110.gravityValue ~= nil then
        L_87.Gravity = L_110.gravityValue;
    end;
    if L_87.CurrentCamera and (L_110 and L_110.fovValue ~= nil) then
        L_87.CurrentCamera.FieldOfView = L_110.fovValue;
    end;
    if not L_110 then
        L_87:SetAttribute("NoDashCooldown", L_87:GetAttribute("NoDashCooldown"));
        L_87:SetAttribute("NoFatigue", L_87:GetAttribute("NoFatigue"));
    else
        L_87:SetAttribute("NoDashCooldown", L_110.noDashCooldown == true);
        L_87:SetAttribute("NoFatigue", L_110.noFatigue == true);
        L_106:SetAttribute("ExtraSlots", L_110.emotesExtraSlots == true);
        L_106:SetAttribute("EmoteSearchBar", L_110.emotesSearchBar == true);
    end;
    return ;
end);
dashclipActiveConnections = {};
dashclipConnectedHumanoids = {};
dashclipOriginalCanCollide = {};
dashclipNoclipToken = 0;
dashclipInitialized = false;
dashclipSafeDisconnect = function(L_1469, ...)
    local L_1470 = L_1469;
    if L_1470 then
        pcall(function(...)
            if type(L_1470.Disconnect) ~= "function" then
                if type(L_1470.disconnect) == "function" then
                    L_1470:disconnect();
                end;
            else
                L_1470:Disconnect();
            end;
            return ;
        end);
        return ;
    end;
    return ;
end;
dashclipDisconnectAll = function(...)
    local L_1471 = { ipairs(dashclipActiveConnections) };
    local L_1472 = L_1471[2];
    local L_1473 = L_1471[1];
    local L_1474 = L_1471[3];
    while true do
        local L_1475;
        L_1474, L_1475 = L_1473(L_1472, L_1474);
        if not L_1474 then
            break;
        end;
        dashclipSafeDisconnect(L_1475);
    end;
    dashclipActiveConnections = {};
    dashclipConnectedHumanoids = {};
    return ;
end;
dashclipStoreConnection = function(L_1476, ...)
    if L_1476 then
        table.insert(dashclipActiveConnections, L_1476);
        return L_1476;
    end;
    return ;
end;
dashclipEnableNoclip = function(...)
    if not L_110.dashclipUnloaded then
        if not L_110.dashclipActive then
            L_110.dashclipActive = true;
            local L_1477 = { ipairs(L_87:GetDescendants()) };
            local L_1478 = L_1477[2];
            local L_1479 = L_1477[3];
            local L_1480 = L_1477[1];
            while true do
                local L_1481;
                L_1479, L_1481 = L_1480(L_1478, L_1479);
                if not L_1479 then
                    break;
                end;
                local L_1482 = L_1481;
                if not L_1482:IsA("Model") then
                    if L_1482:IsA("BasePart") then
                        local L_1483 = L_1482:FindFirstAncestorOfClass("Model");
                        if L_1483 then
                            L_1483 = L_1483:FindFirstChildOfClass("Humanoid");
                        end;
                        if L_1483 then
                            if dashclipOriginalCanCollide[L_1482] == nil then
                                pcall(function(...)
                                    dashclipOriginalCanCollide[L_1482] = L_1482.CanCollide;
                                    return ;
                                end);
                            end;
                            pcall(function(...)
                                L_1482.CanCollide = false;
                                return ;
                            end);
                        end;
                    end;
                else
                    local L_1484 = nil;
                    if pcall(function(...)
                        return L_1482:FindFirstChildOfClass("Humanoid");
                    end) then
                        L_1484 = L_1482:FindFirstChildOfClass("Humanoid");
                    end;
                    if L_1484 then
                        local L_1485 = { ipairs(L_1482:GetDescendants()) };
                        local L_1486 = L_1485[1];
                        local L_1487 = L_1485[2];
                        local L_1488 = L_1485[3];
                        while true do
                            local L_1489;
                            L_1488, L_1489 = L_1486(L_1487, L_1488);
                            if not L_1488 then
                                break;
                            end;
                            local L_1490 = L_1489;
                            if L_1490:IsA("BasePart") then
                                if dashclipOriginalCanCollide[L_1490] == nil then
                                    pcall(function(...)
                                        dashclipOriginalCanCollide[L_1490] = L_1490.CanCollide;
                                        return ;
                                    end);
                                end;
                                pcall(function(...)
                                    L_1490.CanCollide = false;
                                    return ;
                                end);
                            end;
                        end;
                    end;
                end;
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
dashclipDisableNoclip = function(...)
    local L_1491 = { pairs(dashclipOriginalCanCollide) };
    local L_1492 = L_1491[2];
    local L_1493 = L_1491[3];
    local L_1494 = L_1491[1];
    while true do
        local L_1495;
        L_1493, L_1495 = L_1494(L_1492, L_1493);
        if not L_1493 then
            break;
        end;
        local L_1496 = L_1493;
        local L_1497 = L_1495;
        if L_1496 and L_1496.Parent then
            pcall(function(...)
                L_1496.CanCollide = L_1497;
                return ;
            end);
        end;
    end;
    dashclipOriginalCanCollide = {};
    L_110.dashclipActive = false;
    return ;
end;
dashclipTriggerNoclipWithTimer = function(...)
    if not L_110.dashclipUnloaded and L_110.dashclipEnabled then
        dashclipEnableNoclip();
        local L_1498 = dashclipNoclipToken + 1;
        dashclipNoclipToken = L_1498;
        local L_1499 = dashclipNoclipToken;
        task.delay(L_107.dashclipEnableDuration, function(...)
            if not L_110.dashclipUnloaded then
                if L_1499 == dashclipNoclipToken then
                    dashclipDisableNoclip();
                end;
                return ;
            end;
            return ;
        end);
        return ;
    end;
    return ;
end;
dashclipOnTargetAnimationDetected = function(...)
    if not L_110.dashclipUnloaded then
        if L_110.dashclipEnabled then
            dashclipTriggerNoclipWithTimer();
            return ;
        end;
        return ;
    end;
    return ;
end;
dashclipConnectToHumanoid = function(L_1500, ...)
    local L_1501 = L_1500;
    if not L_110.dashclipUnloaded and L_1501 then
        if not dashclipConnectedHumanoids[L_1501] then
            dashclipConnectedHumanoids[L_1501] = true;
            local L_1507 = L_1501.AnimationPlayed:Connect(function(L_1502, ...)
                local L_1503 = L_1502;
                if L_1503 then
                    local L_1504 = nil;
                    pcall(function(...)
                        local L_1505 = L_1503.Animation;
                        local L_1506 = L_1505;
                        if L_1505 then
                            L_1506 = L_1505.AnimationId;
                        end;
                        if L_1506 then
                            L_1504 = tostring(L_1505.AnimationId):match("%d+");
                        end;
                        return ;
                    end);
                    if L_1504 == L_107.dashclipTargetAnimationId then
                        dashclipOnTargetAnimationDetected();
                    end;
                    return ;
                end;
                return ;
            end);
            dashclipStoreConnection(L_1507);
            local L_1508 = L_1501.Died:Connect(function(...)
                dashclipConnectedHumanoids[L_1501] = nil;
                return ;
            end);
            dashclipStoreConnection(L_1508);
            local L_1511 = L_1501.AncestryChanged:Connect(function(L_1509, L_1510, ...)
                if not L_1510 then
                    dashclipConnectedHumanoids[L_1501] = nil;
                    dashclipSafeDisconnect(ancestryConn);
                end;
                return ;
            end);
            dashclipStoreConnection(L_1511);
            return ;
        end;
        return ;
    end;
    return ;
end;
dashclipAggressiveScanAndConnect = function(...)
    if not L_110.dashclipUnloaded then
        local L_1512 = { ipairs(L_87:GetDescendants()) };
        local L_1513 = L_1512[3];
        local L_1514 = L_1512[2];
        local L_1515 = L_1512[1];
        while true do
            local L_1516;
            L_1513, L_1516 = L_1515(L_1514, L_1513);
            if not L_1513 then
                break;
            end;
            if L_1516:IsA("Humanoid") then
                pcall(dashclipConnectToHumanoid, L_1516);
            end;
            if L_1516:IsA("Model") then
                local L_1517 = L_1516:FindFirstChildOfClass("Humanoid");
                if L_1517 then
                    pcall(dashclipConnectToHumanoid, L_1517);
                end;
            end;
        end;
        local L_1518 = { ipairs(L_87:GetChildren()) };
        local L_1519 = L_1518[2];
        local L_1520 = L_1518[1];
        local L_1521 = L_1518[3];
        while true do
            local L_1522;
            L_1521, L_1522 = L_1520(L_1519, L_1521);
            if not L_1521 then
                break;
            end;
            local L_1523 = tostring(L_1522.Name):lower();
            if L_1523:find("live") or (L_1523:find("players") or L_1523:find("files")) then
                local L_1524 = { ipairs(L_1522:GetDescendants()) };
                local L_1525 = L_1524[2];
                local L_1526 = L_1524[1];
                local L_1527 = L_1524[3];
                while true do
                    local L_1528;
                    L_1527, L_1528 = L_1526(L_1525, L_1527);
                    if not L_1527 then
                        break;
                    end;
                    if not L_1528:IsA("Humanoid") then
                        if L_1528:IsA("Model") then
                            local L_1529 = L_1528:FindFirstChildOfClass("Humanoid");
                            if L_1529 then
                                pcall(dashclipConnectToHumanoid, L_1529);
                            end;
                        end;
                    else
                        pcall(dashclipConnectToHumanoid, L_1528);
                    end;
                end;
            end;
        end;
        return ;
    end;
    return ;
end;
dashclipWatchForNewHumanoids = function(...)
    local L_1535 = L_87.DescendantAdded:Connect(function(L_1530, ...)
        local L_1531 = L_1530;
        if not L_110.dashclipUnloaded then
            if not L_1531:IsA("Humanoid") then
                if L_1531:IsA("Model") then
                    local L_1532 = L_1531:FindFirstChildOfClass("Humanoid");
                    if L_1532 then
                        pcall(dashclipConnectToHumanoid, L_1532);
                        return ;
                    end;
                    task.spawn(function(...)
                        local L_1533 = {
                            pcall(function(...)
                                return L_1531:WaitForChild("Humanoid", 3);
                            end)
                        };
                        local L_1534 = L_1533[2];
                        if L_1533[1] and L_1534 then
                            pcall(dashclipConnectToHumanoid, L_1534);
                        end;
                        return ;
                    end);
                end;
                return ;
            end;
            pcall(dashclipConnectToHumanoid, L_1531);
            return ;
        end;
        return ;
    end);
    dashclipStoreConnection(L_1535);
    return ;
end;
dashclipStartPeriodicScan = function(...)
    local L_1536 = nil;
    local L_1537 = 0;
    L_1536 = L_84.Heartbeat:Connect(function(L_1538, ...)
        if not L_110.dashclipUnloaded then
            L_1537 = L_1537 + L_1538;
            if L_1537 >= L_107.dashclipScanInterval then
                L_1537 = 0;
                dashclipAggressiveScanAndConnect();
            end;
            return ;
        end;
        dashclipSafeDisconnect(L_1536);
        return ;
    end);
    dashclipStoreConnection(L_1536);
    return ;
end;
dashclipWatchLocalPlayerAnimations = function(...)
    local L_1545 = function(L_1539, ...)
        local L_1540 = L_1539;
        if L_1540 then
            task.wait(1);
            local L_1541 = L_1540:FindFirstChildOfClass("Humanoid");
            if not L_1541 then
                task.spawn(function(...)
                    local L_1542 = {
                        pcall(function(...)
                            return L_1540:WaitForChild("Humanoid", 5);
                        end)
                    };
                    local L_1543 = L_1542[1];
                    local L_1544 = L_1542[2];
                    if L_1543 then
                        L_1543 = L_1544;
                    end;
                    if L_1543 then
                        pcall(dashclipConnectToHumanoid, L_1544);
                    end;
                    return ;
                end);
            else
                pcall(dashclipConnectToHumanoid, L_1541);
            end;
            return ;
        end;
        return ;
    end;
    if L_106.Character then
        pcall(L_1545, L_106.Character);
    end;
    dashclipStoreConnection(L_106.CharacterAdded:Connect(function(L_1546, ...)
        if not L_110.dashclipUnloaded then
            pcall(L_1545, L_1546);
            return ;
        end;
        return ;
    end));
    return ;
end;
dashclipSetupFeature = function(...)
    if not L_110.dashclipUnloaded then
        if L_110.dashclipEnabled then
            dashclipDisconnectAll();
            dashclipAggressiveScanAndConnect();
            dashclipWatchForNewHumanoids();
            dashclipStartPeriodicScan();
            dashclipWatchLocalPlayerAnimations();
            dashclipInitialized = true;
            return ;
        end;
        return ;
    end;
    return ;
end;
dashclipUnload = function(...)
    L_110.dashclipUnloaded = true;
    L_110.dashclipEnabled = false;
    pcall(function(...)
        dashclipDisableNoclip();
        return ;
    end);
    dashclipDisconnectAll();
    dashclipInitialized = false;
    return ;
end;
task.spawn(function(...)
    task.wait(3);
    if L_110.dashclipEnabled then
        dashclipSetupFeature();
    end;
    return ;
end);
L_106.CharacterAdded:Connect(function(L_1547, ...)
    task.wait(2);
    if L_110.dashclipEnabled and not L_110.dashclipUnloaded and not dashclipInitialized then
        dashclipSetupFeature();
    end;
    return ;
end);
L_1548 = game:GetService("ReplicatedStorage");
L_1549 = game:GetService("TextChatService");
L_1550 = {};
L_1551 = { "EZ clap \240\159\146\128", "Is your keyboard broken or what? \226\140\168\239\184\143", "mommy wants counter", "counter if love men", "Simon says: touch some grass \240\159\140\177", "learn howtocounter", "L + ratio + ez + git gud", "Bro countered the wind \240\159\146\128", "get rekt noob", "You must be new here \240\159\144\163", "Counter like the good boy you are", "why are you trying to dap me up \240\159\152\173", "You call that *playing*? \240\159\152\173", "never play this game again noob", "Is that the best your expensive gaming chair can do?", "Did you accidentally select the 'easy' mode for me?", "hi", "I wud say gud gme but u wud hav to know how to play d game first", "You fatherless 6 7 mom \240\159\146\128", "zero / 74q4 is 10x better than you \240\159\153\143", "go to steal a brairot newbie", "Yeah, ez\226\128\166 effort carrying that ego", "I\226\128\153ve seen noobs do better \240\159\144\163", "my cat can play better than that", "get good", "ez", "L", "COUNTER IF YOU LIKE BIG MEN", "Mommy says POOKIE COUNTER!~", "Go back to training mode \240\159\143\139\239\184\143", "Are you even trying? \240\159\165\177", "I\226\128\153ve seen bots do more damage \240\159\164\150", "EZ like Sunday morning \226\152\128\239\184\143", "Simon says: stay in spawn \240\159\154\171", "Bro thinks it\226\128\153s a tutorial \240\159\146\128", "Go next, this one\226\128\153s over \240\159\171\160", "simon says ur so bad i can't even say nothing to you", "even chro is better than you", "404: skill not found \226\154\160\239\184\143" };
L_1552 = { ["12351854556"] = true, ["15311685628"] = true, ["78521642007560"] = true };
L_1557 = function(L_1553, ...)
    local L_1554 = L_1553;
    if not L_1549 or (not L_1549.TextChannels or not L_1549.TextChannels:FindFirstChild("RBXGeneral")) or not pcall(function(...)
        L_1549.TextChannels.RBXGeneral:SendAsync(L_1554);
        return ;
    end) then
        local L_1555 = L_1548:FindFirstChild("DefaultChatSystemChatEvents");
        if L_1555 then
            L_1555 = L_1555:FindFirstChild("SayMessageRequest");
        end;
        local L_1556 = L_1555;
        if L_1556 then
            pcall(function(...)
                L_1556:FireServer(L_1554, "All");
                return ;
            end);
        end;
        return ;
    end;
    return ;
end;
L_1564 = function(L_1558, L_1559, ...)
    if L_110.counterToxic then
        if L_1558.Animation and L_1558.Animation.AnimationId then
            if L_1552[tostring(L_1558.Animation.AnimationId):match("%d+")] then
                local L_1560 = L_1559.Parent;
                if L_1560 then
                    L_1560 = L_1560:FindFirstChild("HumanoidRootPart");
                end;
                local L_1561 = L_106.Character;
                if L_1561 then
                    L_1561 = L_1561:FindFirstChild("HumanoidRootPart");
                end;
                local L_1562 = L_1560;
                if L_1560 then
                    L_1562 = L_1561;
                end;
                if L_1562 and (L_1560.Position - L_1561.Position).Magnitude <= 6 then
                    local L_1563 = L_1551[math.random(1, #L_1551)];
                    L_1557(L_1563);
                end;
                return ;
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
L_1568 = function(L_1565, ...)
    local L_1566 = L_1565;
    if L_1550[L_1566] then
        L_1550[L_1566]:Disconnect();
        L_1550[L_1566] = nil;
    end;
    if L_110.counterToxic then
        L_1550[L_1566] = L_1566.AnimationPlayed:Connect(function(L_1567, ...)
            L_1564(L_1567, L_1566);
            return ;
        end);
        return ;
    end;
    return ;
end;
setupCounterToxic = function(...)
    local L_1569 = { pairs(L_1550) };
    local L_1570 = L_1569[1];
    local L_1571 = L_1569[3];
    local L_1572 = L_1569[2];
    while true do
        local L_1573;
        L_1571, L_1573 = L_1570(L_1572, L_1571);
        if not L_1571 then
            break;
        end;
        if L_1573.Connected then
            L_1573:Disconnect();
        end;
    end;
    L_1550 = {};
    if L_110.counterToxic then
        local L_1574 = { ipairs(L_83:GetPlayers()) };
        local L_1575 = L_1574[1];
        local L_1576 = L_1574[2];
        local L_1577 = L_1574[3];
        while true do
            local L_1578;
            L_1577, L_1578 = L_1575(L_1576, L_1577);
            if not L_1577 then
                break;
            end;
            if L_1578 ~= L_106 and L_1578.Character then
                local L_1579 = L_1578.Character:FindFirstChildOfClass("Humanoid");
                if L_1579 then
                    L_1568(L_1579);
                end;
            end;
            L_1578.CharacterAdded:Connect(function(L_1580, ...)
                local L_1581 = L_1580:WaitForChild("Humanoid");
                L_1568(L_1581);
                return ;
            end);
        end;
        return ;
    end;
    return ;
end;
L_1582 = game:GetService("Debris");
L_1583 = 250;
L_1584 = 0.25;
L_1585 = 5;
L_1586 = 0.22;
L_1587 = { ["10480796021"] = true, ["10480793962"] = true };
L_111.fastDash = L_111.fastDash or nil;
L_1603 = function(L_1588, ...)
    if L_111.fastDash then
        L_111.fastDash:Disconnect();
        L_111.fastDash = nil;
    end;
    if L_110.fastDash then
        if L_1588 then
            local L_1589 = L_1588:FindFirstChildOfClass("Humanoid");
            local L_1590 = "HumanoidRootPart";
            local L_1591 = L_1588.FindFirstChild;
            local L_1592 = not L_1589;
            local L_1593 = L_1591(L_1588, L_1590);
            if not L_1592 then
                L_1592 = not L_1593;
            end;
            if not L_1592 then
                L_111.fastDash = L_1589.AnimationPlayed:Connect(function(L_1594, ...)
                    local L_1595 = L_1594;
                    local L_1596 = {
                        pcall(function(...)
                            return L_1595.Animation and tostring(L_1595.Animation.AnimationId);
                        end)
                    };
                    local L_1597 = L_1596[1];
                    local L_1598 = L_1596[2];
                    if L_1597 and L_1598 then
                        local L_1599 = L_1598:match("%d+");
                        if L_1599 and L_1587[L_1599] then
                            pcall(function(...)
                                local L_1600 = L_1599 == "10480796021" and -1 or 1;
                                local L_1601 = L_1593.CFrame.RightVector * L_1600;
                                local L_1602 = Instance.new("BodyVelocity");
                                L_1602.Velocity = L_1601 * L_1583;
                                L_1602.MaxForce = Vector3.new(100000, 0, 100000);
                                L_1602.Parent = L_1593;
                                L_1582:AddItem(L_1602, L_1584);
                                L_1593.CFrame = L_1593.CFrame + L_1601 * L_1585;
                                task.delay(L_1586, function(...)
                                    if L_1595 and L_1595.IsPlaying then
                                        pcall(function(...)
                                            L_1595:Stop();
                                            return ;
                                        end);
                                    end;
                                    return ;
                                end);
                                return ;
                            end);
                            return ;
                        end;
                        return ;
                    end;
                    return ;
                end);
                return ;
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
if L_106.Character then
    task.spawn(function(...)
        if L_110.fastDash then
            L_1603(L_106.Character);
        end;
        return ;
    end);
end;
L_106.CharacterAdded:Connect(function(L_1604, ...)
    task.wait(0.5);
    if L_110.fastDash then
        L_1603(L_1604);
    end;
    return ;
end);
L_1633 = function(...)
    if L_110.showCharacter then
        if not _G.a then
            _G.a = true;
            local L_1605 = game:GetService("Players");
            local L_1606 = { KJ = "rbxassetid://17140853847", Sorcerer = "rbxassetid://15143528348", Tech = "rbxassetid://113596928331434" };
            local L_1607 = "rbxassetid://12252402662";
            local L_1613 = function(L_1608, ...)
                local L_1609 = L_1608;
                if not L_1606[L_1609] then
                    local L_1610 = L_1605.LocalPlayer:WaitForChild("PlayerGui");
                    local L_1611 = {
                        pcall(function(...)
                            return L_1610.TopbarPlus.TopbarContainer.UnnamedIcon.DropdownContainer.DropdownFrame[L_1609].IconButton.IconImage.Image;
                        end)
                    };
                    local L_1612 = L_1611[2];
                    return L_1611[1] and L_1612 or L_1607;
                end;
                return L_1606[L_1609];
            end;
            local L_1620 = function(L_1614, ...)
                if L_1614.Character then
                    local L_1615 = L_1614.Character:WaitForChild("Head");
                    local L_1616 = L_1615:FindFirstChild("b");
                    if L_1616 then
                        L_1616:Destroy();
                    end;
                    local L_1617 = L_1614:GetAttribute("Character");
                    if L_1617 then
                        local L_1618 = Instance.new("BillboardGui");
                        L_1618.Name = "b";
                        L_1618.Size = UDim2.new(2, 0, 2, 0);
                        L_1618.AlwaysOnTop = true;
                        L_1618.MaxDistance = 50;
                        L_1618.Adornee = L_1615;
                        L_1618.Parent = L_1615;
                        L_1618.StudsOffset = Vector3.new(0, 2.5, 0);
                        local L_1619 = Instance.new("ImageLabel");
                        L_1619.Size = UDim2.new(1, 0, 1, 0);
                        L_1619.BackgroundTransparency = 1;
                        L_1619.Image = L_1613(L_1617);
                        L_1619.Parent = L_1618;
                        return ;
                    end;
                    return ;
                end;
                return ;
            end;
            local L_1621 = L_1605;
            local L_1622 = "PlayerAdded";
            local L_1625 = function(L_1623, ...)
                local L_1624 = L_1623;
                L_1624.CharacterAdded:Connect(function(...)
                    L_1620(L_1624);
                    return ;
                end);
                L_1624:GetAttributeChangedSignal("Character"):Connect(function(...)
                    if L_1624.Character then
                        L_1620(L_1624);
                    end;
                    return ;
                end);
                if L_1624.Character then
                    L_1620(L_1624);
                end;
                return ;
            end;
            L_1621[L_1622]:Connect(L_1625);
            L_1605.PlayerRemoving:Connect(function(L_1626, ...)
                if L_1626.Character and L_1626.Character:FindFirstChild("Head") then
                    local L_1627 = L_1626.Character.Head:FindFirstChild("b");
                    if L_1627 then
                        L_1627:Destroy();
                    end;
                end;
                return ;
            end);
            local L_1628 = { ipairs(L_1605:GetPlayers()) };
            local L_1629 = L_1628[3];
            local L_1630 = L_1628[2];
            local L_1631 = L_1628[1];
            while true do
                local L_1632;
                L_1629, L_1632 = L_1631(L_1630, L_1629);
                if not L_1629 then
                    break;
                end;
                L_1625(L_1632);
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
L_1684 = function(...)
    if L_111.dashTimer then
        L_111.dashTimer:Disconnect();
        L_111.dashTimer = nil;
    end;
    if L_110.dashTimer then
        local L_1634 = game:GetService("Players");
        local L_1635 = 4.9;
        local L_1636 = 0.1;
        local L_1637 = { "10479335397", "15955393872", "16310343179", "15943915877", "16023456135", "15944317351", "15997042291", "16311141574", "18181589384", "131492147325921", "13380255751" };
        local L_1644 = function(L_1638, ...)
            local L_1639 = L_1638:WaitForChild("PlayerGui");
            local L_1640 = L_1639:FindFirstChild("CooldownSlider");
            if not L_1640 then
                local L_1641 = Instance.new("ScreenGui");
                L_1641.Name = "CooldownSlider";
                L_1641.ResetOnSpawn = false;
                L_1641.Parent = L_1639;
                local L_1642 = Instance.new("Frame");
                L_1642.Name = "Main";
                L_1642.Size = UDim2.new(0, 120, 0, 6);
                L_1642.Position = UDim2.new(0.5, 0, 0, 10);
                L_1642.AnchorPoint = Vector2.new(0.5, 0);
                L_1642.BackgroundColor3 = Color3.fromRGB(30, 30, 30);
                L_1642.BorderSizePixel = 0;
                L_1642.Visible = false;
                L_1642.Parent = L_1641;
                local L_1643 = Instance.new("Frame");
                L_1643.Name = "Fill";
                L_1643.Size = UDim2.new(1, 0, 1, 0);
                L_1643.BackgroundColor3 = Color3.fromRGB(255, 0, 0);
                L_1643.BorderSizePixel = 0;
                L_1643.Parent = L_1642;
                return L_1642, L_1643;
            end;
            return L_1640.Main, L_1640.Fill;
        end;
        local L_1652 = function(L_1645, L_1646, L_1647, ...)
            if not L_1645:GetAttribute("Active") then
                L_1645:SetAttribute("Active", true);
                L_1645.Visible = true;
                local L_1648 = tick();
                while true do
                    local L_1649 = tick() - L_1648;
                    if L_1649 >= L_1647 then
                        break;
                    end;
                    local L_1650 = math.clamp(1 - L_1649 / L_1647, 0, 1);
                    L_1646.Size = UDim2.new(L_1650, 0, 1, 0);
                    local L_1651 = 1 - L_1650;
                    L_1646.BackgroundColor3 = Color3.new(L_1650, L_1651, 0);
                    task.wait(0.03);
                end;
                L_1645.Visible = false;
                L_1645:SetAttribute("Active", false);
                return ;
            end;
            return ;
        end;
        local L_1674 = function(L_1653, ...)
            local L_1654 = false;
            local L_1655 = false;
            local L_1656 = { L_1644(L_1653) };
            local L_1657 = L_1656[2];
            local L_1658 = 0;
            local L_1659 = L_1656[1];
            local L_1660 = L_1657;
            while L_1653.Parent do
                task.wait(L_1636);
                if L_1653.Character then
                    local L_1661 = L_1653.Character:FindFirstChild("Humanoid");
                    if L_1661 then
                        local L_1662 = L_1661.GetPlayingAnimationTracks;
                        local L_1663 = { pairs(L_1662(L_1661)) };
                        local L_1664 = L_1663[1];
                        local L_1665 = L_1663[3];
                        local L_1666 = L_1663[2];
                        while true do
                            repeat
                                L_1655 = false;
                                local L_1667;
                                L_1665, L_1667 = L_1664(L_1666, L_1665);
                                if not L_1665 then
                                    L_1654 = true;
                                    break;
                                end;
                                local L_1668 = L_1667.Animation and tostring(L_1667.Animation.AnimationId) or "";
                                local L_1669 = { ipairs(L_1637) };
                                local L_1670 = L_1669[3];
                                local L_1671 = L_1669[2];
                                local L_1672 = L_1669[1];
                                repeat
                                    local L_1673;
                                    L_1670, L_1673 = L_1672(L_1671, L_1670);
                                    if not L_1670 then
                                        L_1655 = true;
                                    end;
                                    if L_1655 then
                                        break;
                                    end;
                                until L_1668:find(L_1673, 1, true) and tick() - L_1658 >= 5;
                            until not L_1655;
                            if L_1654 then
                                L_1654 = false;
                                break;
                            end;
                            L_1658 = tick();
                            task.spawn(function(...)
                                L_1652(L_1659, L_1660, L_1635);
                                return ;
                            end);
                        end;
                    end;
                end;
            end;
            return ;
        end;
        local L_1675 = L_1634.PlayerAdded;
        local L_1676 = L_1675.Connect;
        local L_1677 = L_1634.GetPlayers;
        L_1676(L_1675, function(L_1678, ...)
            task.spawn(L_1674, L_1678);
            return ;
        end);
        local L_1679 = { ipairs(L_1677(L_1634)) };
        local L_1680 = L_1679[2];
        local L_1681 = L_1679[1];
        local L_1682 = L_1679[3];
        while true do
            local L_1683;
            L_1682, L_1683 = L_1681(L_1680, L_1682);
            if not L_1682 then
                break;
            end;
            task.spawn(L_1674, L_1683);
        end;
        return ;
    end;
    return ;
end;
L_1687 = function(L_1685, ...)
    if L_1685 then
        local L_1686 = L_106.Character or L_106.CharacterAdded:Wait();
        (L_1686:FindFirstChild("HumanoidRootPart") or L_1686:WaitForChild("HumanoidRootPart")).CFrame = CFrame.new(L_1685);
        return ;
    end;
    return ;
end;
L_1688 = "12296113986";
AutoLockJumpAnimDetectId = L_1688;
L_1689 = "10471478869";
AutoLockJumpBlockAnimId = L_1689;
AutoLockJumpConnections = {};
AutoLockJumpActiveLockCleanup = nil;
L_110.autoLockJumpForceJumpHeight = 52;
AutoLockJumpSafeDestroy = function(L_1690, ...)
    local L_1691 = L_1690;
    if L_1691 and L_1691.Parent then
        pcall(function(...)
            L_1691:Destroy();
            return ;
        end);
    end;
    return ;
end;
AutoLockJumpGetCharParts = function(...)
    local L_1692 = L_106.Character;
    if L_1692 then
        local L_1693 = L_1692:FindFirstChildOfClass("Humanoid");
        local L_1694 = L_1692:FindFirstChild("HumanoidRootPart");
        local L_1695 = L_1693;
        if L_1693 then
            L_1695 = L_1694;
        end;
        if not L_1695 then
            return nil;
        end;
        return L_1692, L_1693, L_1694;
    end;
    return nil;
end;
AutoLockJumpFireDashQW = function(...)
    local L_1696 = L_106.Character;
    if L_1696 then
        local L_1697 = L_1696:FindFirstChild("Communicate");
        if L_1697 and typeof(L_1697.FireServer) == "function" then
            local L_1698 = { { Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress" } };
            pcall(function(...)
                L_1697:FireServer(unpack(L_1698));
                return ;
            end);
        end;
        return ;
    end;
    return ;
end;
AutoLockJumpFindBestTarget = function(L_1699, ...)
    local L_1700 = L_1699 or L_110.autoLockJumpTargetRadius;
    local L_1701 = L_87:FindFirstChild("Live");
    if L_1701 then
        local L_1702 = { AutoLockJumpGetCharParts() };
        local L_1703 = L_1702[2];
        local L_1704 = L_1702[1];
        local L_1705 = L_1702[3];
        if L_1705 then
            local L_1706 = nil;
            local L_1707 = L_1701.GetChildren;
            local L_1708 = { ipairs(L_1707(L_1701)) };
            local L_1709 = L_1708[2];
            local L_1710 = L_1708[1];
            local L_1711 = L_1708[3];
            while true do
                local L_1712;
                L_1711, L_1712 = L_1710(L_1709, L_1711);
                if not L_1711 then
                    break;
                end;
                local L_1713 = L_1712;
                if L_1712 then
                    L_1713 = L_1712:IsA("Model") and L_1712 ~= L_106.Character;
                end;
                if L_1713 then
                    local L_1714 = L_1712:FindFirstChild("HumanoidRootPart");
                    local L_1715 = L_1712:FindFirstChildOfClass("Humanoid");
                    local L_1716 = L_1714;
                    if L_1714 then
                        if L_1715 then
                            L_1715 = L_1715.Health > 0;
                        end;
                        L_1716 = L_1715;
                    end;
                    if L_1716 and (L_1712.Name == "Weakest Dummy" or L_83:GetPlayerFromCharacter(L_1712) ~= nil) then
                        local L_1717 = (L_1714.Position - L_1705.Position).Magnitude;
                        if L_1717 <= L_1700 then
                            L_1700 = L_1717;
                            L_1706 = L_1714;
                        end;
                    end;
                end;
            end;
            return L_1706;
        end;
        return nil;
    end;
    return nil;
end;
AutoLockJumpModelHasBlockingAnim = function(L_1718, ...)
    if L_1718 and L_1718.Parent then
        local L_1719 = L_1718:FindFirstChildOfClass("Humanoid");
        if L_1719 then
            local L_1720 = {
                pcall(function(...)
                    return L_1719:GetPlayingAnimationTracks();
                end)
            };
            local L_1721 = L_1720[2];
            if not L_1720[1] or not L_1721 then
                local L_1722 = { ipairs(L_1719:GetChildren()) };
                local L_1723 = L_1722[2];
                local L_1724 = L_1722[3];
                local L_1725 = L_1722[1];
                repeat
                    local L_1726;
                    L_1724, L_1726 = L_1725(L_1723, L_1724);
                    if not L_1724 then
                        return false;
                    end;
                until L_1726:IsA("Animation") and tostring(L_1726.AnimationId or ""):find(AutoLockJumpBlockAnimId, 1, true);
                return true;
            end;
            local L_1727 = { ipairs(L_1721) };
            local L_1728 = L_1727[2];
            local L_1729 = L_1727[3];
            local L_1730 = L_1727[1];
            repeat
                local L_1731;
                L_1729, L_1731 = L_1730(L_1728, L_1729);
                if not L_1729 then
                    return false;
                end;
                local L_1732 = L_1731;
                if L_1731 then
                    L_1732 = L_1731.Animation;
                end;
            until L_1732 and tostring(L_1731.Animation.AnimationId or ""):find(AutoLockJumpBlockAnimId, 1, true);
            return true;
        end;
        return false;
    end;
    return false;
end;
AutoLockJumpScanForBlockingAnim = function(...)
    local L_1733 = L_87:FindFirstChild("Live");
    if L_1733 then
        local L_1734 = { ipairs(L_1733:GetChildren()) };
        local L_1735 = L_1734[1];
        local L_1736 = L_1734[3];
        local L_1737 = L_1734[2];
        local L_1738;
        repeat
            repeat
                L_1736, L_1738 = L_1735(L_1737, L_1736);
                if not L_1736 then
                    return false;
                end;
                local L_1739 = L_1738;
                if L_1738 then
                    L_1739 = L_1738:IsA("Model") and L_1738 ~= L_106.Character;
                end;
            until L_1739;
            local L_1740 = L_1738:FindFirstChildOfClass("Humanoid");
            if L_1740 then
                L_1740 = L_1740.Health > 0;
            end;
        until L_1740 and AutoLockJumpModelHasBlockingAnim(L_1738);
        return true, L_1738;
    end;
    return false;
end;
AutoLockJumpStartHorizontalLockLerp = function(L_1741, L_1742, ...)
    local L_1743 = L_1741;
    local L_1744 = L_1742;
    if L_1743 and L_1743.Parent then
        local L_1745 = { AutoLockJumpGetCharParts() };
        local L_1746 = L_1745[1];
        local L_1747, L_1748 = L_1745[3], L_1745[2];
        if L_1747 and L_1748 then
            if not (L_1744 <= 0) then
                local L_1749 = tick();
                local L_1750 = nil;
                L_1750 = L_84.RenderStepped:Connect(function(L_1751, ...)
                    if not L_110.autoLockJumpBlocked and L_110.autoLockJump then
                        if L_1743 and L_1743.Parent then
                            local L_1752 = L_1747.Position;
                            local L_1753 = Vector3.new(L_1743.Position.X, L_1752.Y, L_1743.Position.Z);
                            if not ((L_1753 - L_1752).Magnitude < 0.001) then
                                local L_1754 = CFrame.new(L_1752, L_1753);
                                local L_1755 = L_110.autoLockJumpResponsiveness;
                                local L_1756 = math.clamp(L_1755, 1, 10000);
                                local L_1757;
                                if not (L_1756 >= 1000) then
                                    local L_1758 = 1 - math.exp(-0.02 * L_1756 * L_1751);
                                    L_1757 = math.clamp(L_1758, 0, 1);
                                else
                                    L_1757 = 1;
                                end;
                                if not (L_1757 >= 0.999999) then
                                    local L_1759 = L_1747.CFrame:Lerp(L_1754, L_1757);
                                    local L_1760 = CFrame.new(L_1752) * CFrame.fromMatrix(Vector3.new(), L_1759.RightVector, L_1759.UpVector);
                                    pcall(function(...)
                                        L_1747.CFrame = L_1760;
                                        return ;
                                    end);
                                else
                                    pcall(function(...)
                                        L_1747.CFrame = L_1754;
                                        return ;
                                    end);
                                end;
                            end;
                            if not (tick() - L_1749 >= L_1744) then
                                return ;
                            end;
                            if L_1750 then
                                L_1750:Disconnect();
                            end;
                            return ;
                        end;
                        if L_1750 then
                            L_1750:Disconnect();
                        end;
                        return ;
                    end;
                    if L_1750 then
                        L_1750:Disconnect();
                    end;
                    return ;
                end);
                return function(...)
                    if L_1750 then
                        pcall(function(...)
                            L_1750:Disconnect();
                            return ;
                        end);
                    end;
                    return ;
                end;
            end;
            return nil;
        end;
        return nil;
    end;
    return nil;
end;
AutoLockJumpCancelActiveLockAndRestore = function(...)
    if AutoLockJumpActiveLockCleanup then
        pcall(AutoLockJumpActiveLockCleanup);
        AutoLockJumpActiveLockCleanup = nil;
    end;
    local L_1761 = L_106.Character;
    if L_1761 then
        L_1761 = L_1761:FindFirstChildOfClass("Humanoid");
    end;
    local L_1762 = L_1761;
    if L_1762 then
        pcall(function(...)
            L_1762.AutoRotate = true;
            return ;
        end);
    end;
    return ;
end;
AutoLockJumpRunSequence = function(...)
    if not L_110.autoLockJumpDebounce and (L_110.autoLockJump and not L_110.autoLockJumpBlocked) then
        L_110.autoLockJumpDebounce = true;
        local L_1763 = L_110.autoLockJumpWaitDetect / 10;
        local L_1764 = L_110.autoLockJumpWaitJump / 10;
        local L_1765 = L_110.autoLockJumpWaitRemote / 10;
        local L_1766 = L_110.autoLockJumpLockDuration / 10;
        local L_1767 = L_110.autoLockJumpCooldown / 10;
        local L_1768 = tick();
        while tick() - L_1768 < L_1763 do
            if not L_110.autoLockJump or L_110.autoLockJumpBlocked then
                L_110.autoLockJumpDebounce = false;
                return ;
            end;
            L_84.Heartbeat:Wait();
        end;
        local L_1769 = { AutoLockJumpGetCharParts() };
        local L_1770 = L_1769[1];
        local L_1771, L_1772 = L_1769[2], L_1769[3];
        if L_1771 and L_1772 then
            local L_1773 = L_1771.AutoRotate;
            L_1771.AutoRotate = false;
            pcall(function(...)
                L_1771.Jump = true;
                L_1771:ChangeState(Enum.HumanoidStateType.Jumping);
                L_1771.Velocity = Vector3.new(L_1771.Velocity.X, L_110.autoLockJumpForceJumpHeight, L_1771.Velocity.Z);
                return ;
            end);
            local L_1774 = tick();
            while tick() - L_1774 < L_1764 do
                if not L_110.autoLockJump or L_110.autoLockJumpBlocked then
                    L_1771.AutoRotate = L_1773;
                    L_110.autoLockJumpDebounce = false;
                    return ;
                end;
                L_84.Heartbeat:Wait();
            end;
            AutoLockJumpFireDashQW();
            local L_1775 = tick();
            while tick() - L_1775 < L_1765 do
                if not L_110.autoLockJump or L_110.autoLockJumpBlocked then
                    L_1771.AutoRotate = L_1773;
                    L_110.autoLockJumpDebounce = false;
                    return ;
                end;
                L_84.Heartbeat:Wait();
            end;
            local L_1776 = AutoLockJumpFindBestTarget();
            local L_1777 = nil;
            local L_1778 = L_1776;
            if L_1776 then
                L_1778 = not L_110.autoLockJumpBlocked;
            end;
            if L_1778 then
                L_1777 = AutoLockJumpStartHorizontalLockLerp(L_1776, L_1766);
                AutoLockJumpActiveLockCleanup = L_1777;
            end;
            local L_1779 = tick() + math.max(L_1766, 1.2);
            task.spawn(function(...)
                while tick() < L_1779 and (L_110.autoLockJump and not L_110.autoLockJumpBlocked) do
                    L_1771.AutoRotate = false;
                    L_84.Heartbeat:Wait();
                end;
                L_1771.AutoRotate = L_1773;
                return ;
            end);
            task.delay(L_1766, function(...)
                if L_1777 then
                    pcall(L_1777);
                    AutoLockJumpActiveLockCleanup = nil;
                end;
                return ;
            end);
            task.delay(L_1767, function(...)
                L_110.autoLockJumpDebounce = false;
                return ;
            end);
            return ;
        end;
        L_110.autoLockJumpDebounce = false;
        return ;
    end;
    return ;
end;
AutoLockJumpOnAnimationPlayed = function(L_1780, ...)
    if L_110.autoLockJump and (not L_110.autoLockJumpDebounce and not L_110.autoLockJumpBlocked) then
        if L_1780 and L_1780.Animation then
            local L_1781 = tostring(L_1780.Animation.AnimationId or "");
            if L_1781 == AutoLockJumpAnimDetectId or L_1781:find(AutoLockJumpAnimDetectId, 1, true) then
                task.spawn(AutoLockJumpRunSequence);
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
AutoLockJumpHookCharacter = function(...)
    if AutoLockJumpConnections.anim then
        pcall(function(...)
            AutoLockJumpConnections.anim:Disconnect();
            return ;
        end);
        AutoLockJumpConnections.anim = nil;
    end;
    local L_1782 = L_106.Character;
    if L_1782 then
        local L_1783 = L_1782:FindFirstChildOfClass("Humanoid");
        if L_1783 then
            AutoLockJumpConnections.anim = L_1783.AnimationPlayed:Connect(AutoLockJumpOnAnimationPlayed);
        end;
        return ;
    end;
    return ;
end;
AutoLockJumpStartBlockChecker = function(...)
    if AutoLockJumpConnections.blockChecker then
        pcall(function(...)
            AutoLockJumpConnections.blockChecker:Disconnect();
            return ;
        end);
        AutoLockJumpConnections.blockChecker = nil;
    end;
    local L_1784 = 0;
    AutoLockJumpConnections.blockChecker = L_84.Heartbeat:Connect(function(L_1785, ...)
        if L_110.autoLockJump then
            L_1784 = L_1784 + L_1785;
            if not (L_1784 < 0.12) then
                L_1784 = 0;
                local L_1786 = { AutoLockJumpScanForBlockingAnim() };
                local L_1787 = L_1786[2];
                local L_1788 = L_1786[1];
                local L_1789 = L_1788;
                if L_1788 then
                    L_1789 = not L_110.autoLockJumpBlocked;
                end;
                if not L_1789 then
                    if not L_1788 and L_110.autoLockJumpBlocked then
                        L_110.autoLockJumpBlocked = false;
                        if L_110.autoLockJump then
                            AutoLockJumpHookCharacter();
                        end;
                    end;
                else
                    L_110.autoLockJumpBlocked = true;
                    AutoLockJumpCancelActiveLockAndRestore();
                    if AutoLockJumpConnections.anim then
                        pcall(function(...)
                            AutoLockJumpConnections.anim:Disconnect();
                            return ;
                        end);
                        AutoLockJumpConnections.anim = nil;
                    end;
                end;
                return ;
            end;
            return ;
        end;
        return ;
    end);
    return ;
end;
SetupAutoLockJump = function(...)
    if L_110.autoLockJump then
        AutoLockJumpHookCharacter();
        AutoLockJumpStartBlockChecker();
        if AutoLockJumpConnections.charAdded then
            pcall(function(...)
                AutoLockJumpConnections.charAdded:Disconnect();
                return ;
            end);
        end;
        AutoLockJumpConnections.charAdded = L_106.CharacterAdded:Connect(function(...)
            task.wait(0.1);
            if L_110.autoLockJump then
                AutoLockJumpHookCharacter();
            end;
            return ;
        end);
        return ;
    end;
    if AutoLockJumpConnections.anim then
        pcall(function(...)
            AutoLockJumpConnections.anim:Disconnect();
            return ;
        end);
        AutoLockJumpConnections.anim = nil;
    end;
    if AutoLockJumpConnections.blockChecker then
        pcall(function(...)
            AutoLockJumpConnections.blockChecker:Disconnect();
            return ;
        end);
        AutoLockJumpConnections.blockChecker = nil;
    end;
    if AutoLockJumpConnections.charAdded then
        pcall(function(...)
            AutoLockJumpConnections.charAdded:Disconnect();
            return ;
        end);
        AutoLockJumpConnections.charAdded = nil;
    end;
    AutoLockJumpCancelActiveLockAndRestore();
    L_110.autoLockJumpDebounce = false;
    L_110.autoLockJumpBlocked = false;
    return ;
end;
task.spawn(function(...)
    task.wait(3);
    if L_110.autoLockJump then
        SetupAutoLockJump();
    end;
    return ;
end);
L_1797 = function(...)
    if getgenv()._StopAnimationsGlobalConnection then
        getgenv()._StopAnimationsGlobalConnection:Disconnect();
        getgenv()._StopAnimationsGlobalConnection = nil;
    end;
    getgenv().Stop = L_110.stopAnimations;
    if not L_110.stopAnimations then
        getgenv().Stop = false;
    else
        local L_1793 = function(L_1790, ...)
            if L_1790 then
                L_1790.AnimationPlayed:Connect(function(L_1791, ...)
                    local L_1792 = L_1791;
                    if getgenv().Stop then
                        pcall(function(...)
                            L_1792:Stop();
                            return ;
                        end);
                    end;
                    return ;
                end);
                return ;
            end;
            return ;
        end;
        local L_1796 = function(L_1794, ...)
            local L_1795 = L_1794:WaitForChildOfClass("Humanoid", 5);
            if not L_1795 then
                warn("");
            else
                L_1793(L_1795);
            end;
            return ;
        end;
        if L_106.Character then
            task.spawn(function(...)
                L_1796(L_106.Character);
                return ;
            end);
        end;
        getgenv()._StopAnimationsGlobalConnection = L_106.CharacterAdded:Connect(L_1796);
    end;
    return ;
end;
L_1798 = nil;
L_1802 = function(L_1799, ...)
    if not L_1799 then
        if L_1798 then
            L_1798:Disconnect();
            L_1798 = nil;
        end;
    else
        L_1798 = L_84.Heartbeat:Connect(function(...)
            local L_1800 = L_106.Character;
            if L_1800 then
                L_1800 = L_1800:FindFirstChild("Humanoid");
            end;
            local L_1801 = L_1800;
            if L_1800 then
                L_1801 = L_1800:GetState() == Enum.HumanoidStateType.Running;
            end;
            if L_1801 then
                L_1800:ChangeState(Enum.HumanoidStateType.Jumping);
            end;
            return ;
        end);
    end;
    return ;
end;
L_1803 = "10479335397";
L_1804 = { characterAdded = nil, currentCharacter = { animPlayed = nil, ancestryChanged = nil }, aimingLoop = nil };
L_1805 = 0;
L_1806 = nil;
L_1814 = function(...)
    if not L_1804.aimingLoop and L_1806 then
        local L_1807 = L_1806:FindFirstChild("HumanoidRootPart");
        if L_1807 then
            local L_1808 = L_83.LocalPlayer:GetMouse();
            L_1804.aimingLoop = L_84.RenderStepped:Connect(function(...)
                if not (tick() >= L_1805) and (L_1806 and (L_1806.Parent and L_110.mouseDash)) then
                    local L_1809 = {
                        pcall(function(...)
                            return L_1808.Hit.Position;
                        end)
                    };
                    local L_1810 = L_1809[1];
                    local L_1811 = L_1809[2];
                    if L_1810 then
                        L_1810 = L_1811;
                    end;
                    if L_1810 then
                        local L_1812 = Vector3.new(L_1811.X, L_1807.Position.Y, L_1811.Z);
                        local L_1813 = CFrame.new(L_1807.Position, L_1812);
                        pcall(function(...)
                            L_1807.CFrame = L_1813;
                            return ;
                        end);
                    end;
                    return ;
                end;
                if L_1804.aimingLoop then
                    L_1804.aimingLoop:Disconnect();
                    L_1804.aimingLoop = nil;
                end;
                return ;
            end);
            return ;
        end;
        return ;
    end;
    return ;
end;
L_1822 = function(L_1815, ...)
    local L_1816 = L_1815;
    if L_110.mouseDash then
        local L_1817 = {
            pcall(function(...)
                return L_1816.Animation;
            end)
        };
        local L_1818 = L_1817[1];
        local L_1819 = L_1817[2];
        if L_1818 and L_1819 then
            local L_1820 = tostring(L_1819.AnimationId or L_1819);
            if string.find(L_1820, L_1803, 1, true) then
                local L_1821 = L_110.mouseDashDelay / 1000;
                L_1805 = tick() + L_1821;
                L_1814();
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
L_1834 = function(L_1823, ...)
    if L_1804.currentCharacter.animPlayed then
        L_1804.currentCharacter.animPlayed:Disconnect();
        L_1804.currentCharacter.animPlayed = nil;
    end;
    if L_1804.currentCharacter.ancestryChanged then
        L_1804.currentCharacter.ancestryChanged:Disconnect();
        L_1804.currentCharacter.ancestryChanged = nil;
    end;
    if L_1804.aimingLoop then
        L_1804.aimingLoop:Disconnect();
        L_1804.aimingLoop = nil;
    end;
    L_1805 = 0;
    L_1806 = nil;
    if L_110.mouseDash then
        local L_1824 = L_1823:WaitForChild("Humanoid", 5);
        if L_1824 then
            L_1806 = L_1823;
            L_1804.currentCharacter.animPlayed = L_1824.AnimationPlayed:Connect(L_1822);
            local L_1825 = {
                pcall(function(...)
                    return L_1824:GetPlayingAnimationTracks();
                end)
            };
            local L_1826 = L_1825[2];
            if L_1825[1] and L_1826 then
                local L_1827 = { ipairs(L_1826) };
                local L_1828 = L_1827[1];
                local L_1829 = L_1827[2];
                local L_1830 = L_1827[3];
                while true do
                    local L_1831;
                    L_1830, L_1831 = L_1828(L_1829, L_1830);
                    if not L_1830 then
                        break;
                    end;
                    L_1822(L_1831);
                end;
            end;
            L_1804.currentCharacter.ancestryChanged = L_1823.AncestryChanged:Connect(function(L_1832, L_1833, ...)
                if not L_1833 then
                    if L_1804.aimingLoop then
                        L_1804.aimingLoop:Disconnect();
                        L_1804.aimingLoop = nil;
                    end;
                    if L_1804.currentCharacter.animPlayed then
                        L_1804.currentCharacter.animPlayed:Disconnect();
                        L_1804.currentCharacter.animPlayed = nil;
                    end;
                    if L_1804.currentCharacter.ancestryChanged then
                        L_1804.currentCharacter.ancestryChanged:Disconnect();
                        L_1804.currentCharacter.ancestryChanged = nil;
                    end;
                    L_1806 = nil;
                end;
                return ;
            end);
            return ;
        end;
        return ;
    end;
    return ;
end;
L_1835 = function(...)
    if L_1804.characterAdded then
        L_1804.characterAdded:Disconnect();
        L_1804.characterAdded = nil;
    end;
    if L_1804.currentCharacter.animPlayed then
        L_1804.currentCharacter.animPlayed:Disconnect();
        L_1804.currentCharacter.animPlayed = nil;
    end;
    if L_1804.currentCharacter.ancestryChanged then
        L_1804.currentCharacter.ancestryChanged:Disconnect();
        L_1804.currentCharacter.ancestryChanged = nil;
    end;
    if L_1804.aimingLoop then
        L_1804.aimingLoop:Disconnect();
        L_1804.aimingLoop = nil;
    end;
    L_1805 = 0;
    L_1806 = nil;
    if L_110.mouseDash then
        L_1804.characterAdded = L_106.CharacterAdded:Connect(L_1834);
        if L_106.Character then
            L_1834(L_106.Character);
        end;
    end;
    return ;
end;
L_1836 = "rbxassetid://12309835105";
autoSurfAnimationId = L_1836;
autoSurfActive = false;
autoSurfIsTweening = false;
autoSurfCharConnection = nil;
autoSurfRenderConnection = nil;
setupAutoSurf = function(...)
    if autoSurfCharConnection then
        autoSurfCharConnection:Disconnect();
        autoSurfCharConnection = nil;
    end;
    if autoSurfRenderConnection then
        autoSurfRenderConnection:Disconnect();
        autoSurfRenderConnection = nil;
    end;
    if L_110.autoSurf then
        autoSurfActive = true;
        L_501 = function(...)
            return L_106.Character or L_106.CharacterAdded:Wait();
        end;
        isTargetAnimPlaying = function(...)
            local L_1837 = L_501():FindFirstChildOfClass("Humanoid");
            if L_1837 then
                local L_1838 = L_1837.GetPlayingAnimationTracks;
                local L_1839 = { ipairs(L_1838(L_1837)) };
                local L_1840 = L_1839[3];
                local L_1841 = L_1839[2];
                local L_1842 = L_1839[1];
                repeat
                    local L_1843;
                    L_1840, L_1843 = L_1842(L_1841, L_1840);
                    if not L_1840 then
                        return false;
                    end;
                until L_1843.Animation and L_1843.Animation.AnimationId == autoSurfAnimationId;
                return true;
            end;
            return false;
        end;
        local L_1847 = L_84.RenderStepped:Connect(function(...)
            if autoSurfActive and not autoSurfIsTweening then
                if isTargetAnimPlaying() then
                    autoSurfIsTweening = true;
                    task.wait(0.6);
                    local L_1844 = L_501():FindFirstChild("HumanoidRootPart");
                    if L_1844 then
                        L_1844.Anchored = false;
                        local L_1845 = L_1844.CFrame.LookVector.Unit;
                        local L_1846 = L_85:Create(L_1844, TweenInfo.new(0.78), { CFrame = L_1844.CFrame + L_1845 * 50 });
                        L_1846:Play();
                        L_1846.Completed:Wait();
                    end;
                    task.wait(1.5);
                    autoSurfIsTweening = false;
                end;
                return ;
            end;
            return ;
        end);
        autoSurfRenderConnection = L_1847;
        local L_1848 = L_106.CharacterAdded:Connect(function(...)
            task.wait(1);
            L_501();
            return ;
        end);
        autoSurfCharConnection = L_1848;
        return ;
    end;
    return ;
end;
L_1849 = "rbxassetid://12296113986";
autoWhirlwindDunkAnimationId = L_1849;
autoWhirlwindDunkIsTeleporting = false;
autoWhirlwindDunkLastTrack = nil;
autoWhirlwindDunkConnection = nil;
setupAutoWhirlwindDunk = function(...)
    if autoWhirlwindDunkConnection then
        autoWhirlwindDunkConnection:Disconnect();
        autoWhirlwindDunkConnection = nil;
    end;
    if L_110.autoWhirlwindDunk then
        local L_1861 = L_84.RenderStepped:Connect(function(...)
            local L_1850 = false;
            local L_1851 = L_106.Character;
            if L_1851 and not autoWhirlwindDunkIsTeleporting then
                local L_1852 = L_1851:FindFirstChildWhichIsA("Humanoid");
                local L_1853 = "HumanoidRootPart";
                local L_1854 = not L_1852;
                local L_1855 = L_1851:FindFirstChild(L_1853);
                if not L_1854 then
                    L_1854 = not L_1855;
                end;
                if not L_1854 then
                    local L_1856 = { ipairs(L_1852:GetPlayingAnimationTracks()) };
                    local L_1857 = L_1856[3];
                    local L_1858 = L_1856[2];
                    local L_1859 = L_1856[1];
                    local L_1860;
                    repeat
                        L_1857, L_1860 = L_1859(L_1858, L_1857);
                        if not L_1857 then
                            L_1850 = true;
                        end;
                        if L_1850 then
                            break;
                        end;
                    until L_1860.Animation and L_1860.Animation.AnimationId == autoWhirlwindDunkAnimationId;
                    if L_1850 or autoWhirlwindDunkLastTrack ~= L_1860 then
                        if not L_1850 then
                            autoWhirlwindDunkLastTrack = L_1860;
                            autoWhirlwindDunkIsTeleporting = true;
                            task.delay(1, function(...)
                                if L_1855 and L_1855.Parent then
                                    L_1855.CFrame = L_1855.CFrame + Vector3.new(0, 70, 0);
                                end;
                                autoWhirlwindDunkIsTeleporting = false;
                                return ;
                            end);
                        end;
                        L_1850 = false;
                        if autoWhirlwindDunkLastTrack and not autoWhirlwindDunkLastTrack.IsPlaying then
                            autoWhirlwindDunkLastTrack = nil;
                        end;
                        return ;
                    end;
                    return ;
                end;
                return ;
            end;
            return ;
        end);
        autoWhirlwindDunkConnection = L_1861;
        return ;
    end;
    return ;
end;
L_1862 = { ["10480796021"] = true, ["10480793962"] = true };
slideM1TargetIDs = L_1862;
slideM1AnimConnection = nil;
slideM1CharConnection = nil;
slideM1ToggleState = false;
setupSlideM1 = function(...)
    if slideM1AnimConnection then
        slideM1AnimConnection:Disconnect();
        slideM1AnimConnection = nil;
    end;
    if slideM1CharConnection then
        slideM1CharConnection:Disconnect();
        slideM1CharConnection = nil;
    end;
    if L_110.slideM1 then
        slideM1ToggleState = true;
        setupForCharacter = function(L_1863, ...)
            local L_1864 = L_1863:WaitForChild("Humanoid", 3);
            local L_1865 = L_1864;
            if L_1864 then
                L_1865 = L_1864:FindFirstChildOfClass("Animator");
            end;
            local L_1866 = L_1863:FindFirstChild("Communicate");
            if L_1864 and (L_1865 and L_1866) then
                local L_1867 = false;
                if slideM1AnimConnection then
                    slideM1AnimConnection:Disconnect();
                end;
                local L_1870 = L_1865.AnimationPlayed:Connect(function(L_1868, ...)
                    if slideM1ToggleState then
                        local L_1869 = L_1868.Animation.AnimationId:match("%d+");
                        if L_1869 then
                            L_1869 = slideM1TargetIDs[L_1869] and not L_1867;
                        end;
                        if L_1869 then
                            L_1867 = true;
                            L_1866:FireServer({ Mobile = true, Goal = "LeftClick" });
                            L_1866:FireServer({ Goal = "LeftClickRelease", Mobile = true });
                            task.delay(1.5, function(...)
                                L_1867 = false;
                                return ;
                            end);
                        end;
                        return ;
                    end;
                    return ;
                end);
                slideM1AnimConnection = L_1870;
                return ;
            end;
            return ;
        end;
        if L_106.Character then
            setupForCharacter(L_106.Character);
        end;
        local L_1872 = L_106.CharacterAdded:Connect(function(L_1871, ...)
            task.wait(1);
            if slideM1ToggleState then
                setupForCharacter(L_1871);
            end;
            return ;
        end);
        slideM1CharConnection = L_1872;
        return ;
    end;
    return ;
end;
autoTwistedEnabled = false;
autoTwistedCooldown = false;
autoTwistedAnimationConnection = nil;
autoTwistedCharAddedConnection = nil;
L_1873 = "rbxassetid://13294471966";
autoTwistedAnimationId = L_1873;
autoTwistedDelayBeforeRemote = 0.23;
autoTwistedUseRemote = function(...)
    if autoTwistedEnabled then
        local L_1874 = L_106.Character;
        local L_1875 = L_1874;
        if L_1874 then
            L_1875 = L_1874:FindFirstChild("Communicate");
        end;
        if L_1875 then
            local L_1876 = { [1] = { Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress" } };
            args = L_1876;
            L_1874.Communicate:FireServer(unpack(args));
        end;
        return ;
    end;
    return ;
end;
autoTwistedStepBack = function(...)
    if autoTwistedEnabled then
        local L_1877 = L_106.Character and L_106.Character:FindFirstChild("HumanoidRootPart");
        if L_1877 then
            L_1877.CFrame = L_1877.CFrame * CFrame.new(0, 0, 3.4);
        end;
        return ;
    end;
    return ;
end;
autoTwistedBindAnimationDetection = function(...)
    local L_1879 = (L_106.Character or L_106.CharacterAdded:Wait()):WaitForChild("Humanoid").AnimationPlayed:Connect(function(L_1878, ...)
        if autoTwistedEnabled then
            if L_1878.Animation and (L_1878.Animation.AnimationId == autoTwistedAnimationId and not autoTwistedCooldown) then
                autoTwistedCooldown = true;
                task.delay(autoTwistedDelayBeforeRemote, function(...)
                    if autoTwistedEnabled then
                        autoTwistedStepBack();
                        autoTwistedUseRemote();
                        return ;
                    end;
                    return ;
                end);
                task.delay(5, function(...)
                    autoTwistedCooldown = false;
                    return ;
                end);
            end;
            return ;
        end;
        return ;
    end);
    autoTwistedAnimationConnection = L_1879;
    return ;
end;
setupAutoTwisted = function(...)
    if autoTwistedAnimationConnection then
        autoTwistedAnimationConnection:Disconnect();
        autoTwistedAnimationConnection = nil;
    end;
    if autoTwistedCharAddedConnection then
        autoTwistedCharAddedConnection:Disconnect();
        autoTwistedCharAddedConnection = nil;
    end;
    if L_110.autoTwisted then
        autoTwistedEnabled = true;
        autoTwistedBindAnimationDetection();
        local L_1880 = L_106.CharacterAdded:Connect(function(...)
            task.wait(1);
            if autoTwistedEnabled then
                autoTwistedBindAnimationDetection();
            end;
            return ;
        end);
        autoTwistedCharAddedConnection = L_1880;
        return ;
    end;
    return ;
end;
L_1907 = function(...)
    if L_111.techHelper then
        L_111.techHelper:Disconnect();
        L_111.techHelper = nil;
    end;
    if L_110.techHelper then
        local L_1881 = "10479335397";
        local L_1889 = function(L_1882, ...)
            local L_1883 = L_1882:FindFirstChild("HumanoidRootPart");
            local L_1884, L_1885 = L_1882:FindFirstChildOfClass("Humanoid"), not L_1883;
            if not L_1885 then
                L_1885 = not L_1884;
            end;
            if not L_1885 then
                if not L_1883:FindFirstChild("TechHelperActive") then
                    local L_1886 = Instance.new("BoolValue", L_1883);
                    L_1886.Name = "TechHelperActive";
                    local L_1887 = L_1884.AutoRotate;
                    L_1884.AutoRotate = false;
                    L_1883.Velocity = Vector3.zero;
                    local L_1888 = Instance.new("BodyGyro");
                    L_1888.MaxTorque = Vector3.new(100000, 100000, 100000);
                    L_1888.P = 8000;
                    L_1888.D = 40;
                    if not L_107.techHelperLookUp then
                        L_1888.CFrame = L_1883.CFrame * CFrame.Angles(math.rad(-90), 0, 0);
                    else
                        L_1888.CFrame = L_1883.CFrame * CFrame.Angles(math.rad(90), 0, 0);
                    end;
                    L_1888.Parent = L_1883;
                    task.delay(L_107.techHelperHold, function(...)
                        L_1888:Destroy();
                        L_1884.AutoRotate = L_1887;
                        L_1886:Destroy();
                        return ;
                    end);
                    return ;
                end;
                return ;
            end;
            return ;
        end;
        local L_1895 = function(L_1890, L_1891, ...)
            local L_1892 = L_1891;
            L_1890.AnimationPlayed:Connect(function(L_1893, ...)
                if L_110.techHelper then
                    local L_1894 = L_1893.Animation;
                    if L_1894 then
                        L_1894 = string.find(tostring(L_1894.AnimationId), L_1881, 1, true);
                    end;
                    if L_1894 then
                        task.wait(L_107.techHelperDelay);
                        L_1889(L_1892);
                    end;
                    return ;
                end;
                return ;
            end);
            return ;
        end;
        local L_1900 = function(L_1896, ...)
            local L_1897 = L_1896;
            local L_1898 = L_1897:FindFirstChildOfClass("Humanoid");
            if L_1898 then
                L_1895(L_1898, L_1897);
            end;
            L_1897.ChildAdded:Connect(function(L_1899, ...)
                if L_1899:IsA("Humanoid") then
                    L_1895(L_1899, L_1897);
                end;
                return ;
            end);
            return ;
        end;
        local L_1901 = { ipairs(L_83:GetPlayers()) };
        local L_1902 = L_1901[2];
        local L_1903 = L_1901[3];
        local L_1904 = L_1901[1];
        while true do
            local L_1905;
            L_1903, L_1905 = L_1904(L_1902, L_1903);
            if not L_1903 then
                break;
            end;
            if L_1905.Character then
                L_1900(L_1905.Character);
            end;
            L_1905.CharacterAdded:Connect(L_1900);
        end;
        L_83.PlayerAdded:Connect(function(L_1906, ...)
            L_1906.CharacterAdded:Connect(L_1900);
            return ;
        end);
        if L_106 and L_106.Character then
            L_1900(L_106.Character);
        end;
        return ;
    end;
    return ;
end;
L_106.CharacterAdded:Connect(function(L_1908, ...)
    task.wait(0.5);
    if L_110.supa then
        L_602(L_1908);
    end;
    if L_110.supaV2 then
        L_632(L_1908);
    end;
    if L_110.loop then
        L_745(L_1908);
    end;
    if L_110.autoCounter then
        setupAutoCounter();
    end;
    if L_110.noClip then
        L_903();
    end;
    if L_110.m2Block then
        L_1029();
    end;
    if L_110.kiba then
        setupKiba();
    end;
    if L_110.downSlam then
        L_1056();
    end;
    if L_110.autoSurf then
        setupAutoSurf();
    end;
    if L_110.autoWhirlwindDunk then
        setupAutoWhirlwindDunk();
    end;
    if L_110.slideM1 then
        setupSlideM1();
    end;
    if L_110.autoDownSlam then
        setupAutoDownSlam();
    end;
    if L_110.autoTwisted then
        setupAutoTwisted();
    end;
    if L_110.respawnAtDeath then
        L_1320();
    end;
    if L_110.fpsBoost then
        L_1422();
    end;
    if L_110.counterToxic then
        setupCounterToxic();
    end;
    if L_110.showCharacter then
        L_1633();
    end;
    if L_110.dashTimer then
        L_1684();
    end;
    if L_110.techHelper then
        L_1907();
    end;
    return ;
end);
L_1909 = false;
L_1910 = 0;
L_1911 = nil;
L_1917 = function(L_1912, ...)
    if L_1911 then
        L_1911:Disconnect();
        L_1911 = nil;
    end;
    if L_110.noEndLag then
        if L_1912 then
            local L_1913 = L_1912:FindFirstChildOfClass("Humanoid");
            local L_1914 = L_1913;
            if L_1913 then
                L_1914 = L_1913:FindFirstChildOfClass("Animator");
            end;
            if L_1913 and L_1914 then
                L_1911 = L_1914.AnimationPlayed:Connect(function(L_1915, ...)
                    local L_1916 = L_1915.Animation.AnimationId:match("%d+");
                    if L_1916 == "10480793962" or L_1916 == "10480796021" then
                        L_1909 = true;
                        L_1910 = os.clock() + 0.85;
                        task.delay(0.85, function(...)
                            L_1909 = false;
                            return ;
                        end);
                    end;
                    return ;
                end);
                return ;
            end;
            return ;
        end;
        return ;
    end;
    return ;
end;
L_86.InputBegan:Connect(function(L_1918, L_1919, ...)
    if not L_1919 and L_110.noEndLag then
        if L_1918.KeyCode == Enum.KeyCode.Q and (L_1909 and os.clock() <= L_1910) then
            local L_1920 = L_106.Character;
            if L_1920 then
                L_1920 = L_1920:FindFirstChild("Communicate");
            end;
            local L_1921 = L_1920;
            if L_1921 then
                pcall(function(...)
                    L_1921:FireServer({ Dash = Enum.KeyCode.W, Key = Enum.KeyCode.Q, Goal = "KeyPress" });
                    return ;
                end);
            end;
            L_1909 = false;
        end;
        return ;
    end;
    return ;
end);
L_106.CharacterAdded:Connect(function(L_1922, ...)
    task.wait(0.5);
    if L_110.noEndLag then
        L_1917(L_1922);
    end;
    return ;
end);
if L_106.Character and L_110.noEndLag then
    L_1917(L_106.Character);
end;
L_1923 = {};
L_1930 = function(...)
    if L_106.Character then
        local L_1924 = { ipairs(L_1923) };
        local L_1925 = L_1924[3];
        local L_1926 = L_1924[2];
        local L_1927 = L_1924[1];
        while true do
            local L_1928;
            L_1925, L_1928 = L_1927(L_1926, L_1925);
            if not L_1925 then
                break;
            end;
            local L_1929 = L_1928;
            pcall(function(...)
                L_1929:Destroy();
                return ;
            end);
        end;
    end;
    L_1923 = {};
    return ;
end;
L_1936 = function(L_1931, ...)
    if L_1931 and L_1931 ~= "" then
        local L_1932 = tostring(L_1931):gsub("%s+", "");
        if L_1932 ~= "" then
            local L_1933 = tonumber(L_1932);
            if not L_1933 then
                local L_1934 = {
                    pcall(function(...)
                        return L_83:GetUserIdFromNameAsync(L_1932);
                    end)
                };
                local L_1935 = L_1934[2];
                if not L_1934[1] or type(L_1935) ~= "number" then
                    warn(" '" .. tostring(L_1932) .. "'. Error:", L_1935);
                    return nil;
                end;
                return L_1935;
            end;
            return math.floor(L_1933);
        end;
        return nil;
    end;
    return nil;
end;
L_1937 = nil;
L_1938 = nil;
L_1942 = function(L_1939, ...)
    if not L_1939 then
        if L_1937 then
            L_1937:Disconnect();
        end;
        L_1937 = nil;
    else
        L_1937 = L_84.RenderStepped:Connect(function(...)
            local L_1940 = L_106.Character;
            if L_1940 then
                if L_1940:FindFirstChild("Stunned") then
                    pcall(function(...)
                        L_1940.Stunned:Destroy();
                        return ;
                    end);
                end;
                local L_1941 = L_1940:FindFirstChild("Humanoid");
                if L_1941 then
                    L_1941.PlatformStand = false;
                    if L_1941.WalkSpeed == 0 then
                        L_1941.WalkSpeed = 16;
                    end;
                end;
                return ;
            end;
            return ;
        end);
    end;
    return ;
end;
L_1946 = function(L_1943, ...)
    if not L_1943 then
        if L_1938 then
            L_1938:Disconnect();
        end;
        L_1938 = nil;
    else
        L_1938 = L_84.RenderStepped:Connect(function(...)
            local L_1944 = L_106.Character;
            if L_1944 then
                local L_1945 = L_1944:FindFirstChild("Humanoid");
                if L_1945 then
                    if L_1945.WalkSpeed < 20 then
                        L_1945.WalkSpeed = 20;
                    end;
                    L_1945.PlatformStand = false;
                end;
                return ;
            end;
            return ;
        end);
    end;
    return ;
end;
L_1972 = function(L_1947, ...)
    local L_1948 = L_1947;
    if L_1948 and type(L_1948) == "number" then
        L_1930();
        L_82:Notify({ Title = "Avatar Changer", Content = "Loading avatar for UserId: " .. tostring(L_1948), Duration = 2 });
        local L_1949 = nil;
        if pcall(function(...)
            L_1949 = L_83:GetHumanoidDescriptionFromUserId(L_1948);
            return ;
        end) and L_1949 then
            local L_1950 = L_106.Character;
            if L_1950 then
                if L_1950:FindFirstChildOfClass("Humanoid") then
                    local L_1951 = { ipairs(L_1950:GetChildren()) };
                    local L_1952 = L_1951[3];
                    local L_1953 = L_1951[2];
                    local L_1954 = L_1951[1];
                    while true do
                        local L_1955;
                        L_1952, L_1955 = L_1954(L_1953, L_1952);
                        if not L_1952 then
                            break;
                        end;
                        if L_1955:IsA("Shirt") or (L_1955:IsA("Pants") or (L_1955:IsA("ShirtGraphic") or L_1955:IsA("Accessory"))) then
                            L_1955:Destroy();
                        end;
                    end;
                    local L_1956 = Enum.HumanoidRigType.R15;
                    if L_1950:FindFirstChild("Torso") then
                        L_1956 = Enum.HumanoidRigType.R6;
                    end;
                    local L_1957 = nil;
                    if pcall(function(...)
                        L_1957 = L_83:CreateHumanoidModelFromDescription(L_1949, L_1956);
                        return ;
                    end) and L_1957 then
                        local L_1958 = { ipairs(L_1957:GetChildren()) };
                        local L_1959 = L_1958[2];
                        local L_1960 = L_1958[3];
                        local L_1961 = L_1958[1];
                        while true do
                            local L_1962;
                            L_1960, L_1962 = L_1961(L_1959, L_1960);
                            if not L_1960 then
                                break;
                            end;
                            if not L_1962:IsA("Shirt") and (not L_1962:IsA("Pants") and not L_1962:IsA("ShirtGraphic")) then
                                if not L_1962:IsA("Accessory") then
                                    if L_1962:IsA("BodyColors") then
                                        local L_1963 = L_1950:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors", L_1950);
                                        L_1963.HeadColor = L_1962.HeadColor;
                                        L_1963.LeftArmColor = L_1962.LeftArmColor;
                                        L_1963.RightArmColor = L_1962.RightArmColor;
                                        L_1963.LeftLegColor = L_1962.LeftLegColor;
                                        L_1963.RightLegColor = L_1962.RightLegColor;
                                        L_1963.TorsoColor = L_1962.TorsoColor;
                                        table.insert(L_1923, L_1963);
                                    end;
                                else
                                    local L_1964 = L_1962:Clone();
                                    local L_1965 = L_1964:FindFirstChild("Handle");
                                    if L_1965 then
                                        local L_1966 = L_1965:FindFirstChildWhichIsA("Attachment");
                                        if not L_1966 then
                                            local L_1967 = L_1950:FindFirstChild("Head");
                                            if L_1967 then
                                                local L_1968 = Instance.new("WeldConstraint");
                                                L_1968.Part0 = L_1965;
                                                L_1968.Part1 = L_1967;
                                                L_1968.Parent = L_1965;
                                                L_1965.CFrame = L_1967.CFrame;
                                            end;
                                        else
                                            local L_1969 = L_1950:FindFirstChild(L_1966.Name, true);
                                            if L_1969 then
                                                local L_1970 = Instance.new("Weld");
                                                L_1970.Name = "AccessoryWeld";
                                                L_1970.Part0 = L_1969.Parent;
                                                L_1970.Part1 = L_1965;
                                                L_1970.C0 = L_1969.CFrame;
                                                L_1970.C1 = L_1966.CFrame;
                                                L_1970.Parent = L_1965;
                                            end;
                                        end;
                                        L_1965.CanCollide = false;
                                        L_1965.Massless = true;
                                    end;
                                    L_1964.Parent = L_1950;
                                    table.insert(L_1923, L_1964);
                                end;
                            else
                                local L_1971 = L_1962:Clone();
                                L_1971.Parent = L_1950;
                                table.insert(L_1923, L_1971);
                            end;
                        end;
                        pcall(function(...)
                            L_1957:Destroy();
                            return ;
                        end);
                        L_82:Notify({ Title = "Avatar Changer", Content = "Avatar successfully copied!", Duration = 3 });
                        return ;
                    end;
                    warn("");
                    L_82:Notify({ Title = "Avatar Changer", Content = "Failed to create avatar model.", Duration = 3 });
                    return ;
                end;
                warn("");
                L_82:Notify({ Title = "Avatar Changer", Content = "Humanoid not found.", Duration = 3 });
                return ;
            end;
            warn("");
            L_82:Notify({ Title = "Avatar Changer", Content = "Player character not found.", Duration = 3 });
            return ;
        end;
        warn("", L_1948);
        L_82:Notify({ Title = "Avatar Changer", Content = "Failed to fetch avatar for UserId: " .. tostring(L_1948), Duration = 3 });
        return ;
    end;
    warn("", L_1948);
    L_82:Notify({ Title = "Avatar Changer", Content = "Invalid UserId/Name provided.", Duration = 3 });
    return ;
end;
L_1975 = function(...)
    local L_1973 = L_110.avatarChangerUserId;
    if L_1973 and L_1973 ~= "" then
        local L_1974 = L_1936(L_1973);
        if L_1974 then
            task.spawn(L_1972, L_1974);
            return ;
        end;
        L_82:Notify({ Title = "Avatar Changer", Content = "Could not resolve UserId from input: " .. tostring(L_1973), Duration = 3 });
        return ;
    end;
    L_82:Notify({ Title = "Avatar Changer", Content = "Please enter a UserId or Username.", Duration = 3 });
    return ;
end;
L_138.SupaTech:Paragraph({ Title = "Supa Tech", Desc = "Dash in them", Image = "lucide:sword", ImageSize = 20, Color = Color3.fromHex("#ff6b6b") });
L_138.SupaTech:Toggle({
    Title = "Enable Feature",
    Value = L_110.supa,
    Callback = function(L_1976, ...)
        L_110.supa = L_1976;
        if not L_1976 then
            if L_111.supa then
                L_111.supa:Disconnect();
                L_111.supa = nil;
            end;
        elseif L_106.Character then
            L_602(L_106.Character);
        end;
        return ;
    end
});
L_138.SupaTech:Toggle({
    Title = "Helper",
    Desc = "Use this to headtab",
    Value = L_110.upperGrasp,
    Callback = function(L_1977, ...)
        L_110.upperGrasp = L_1977;
        SetupUpperGrasp();
        if not L_1977 then
            L_82:Notify({ Title = "Upper Grasp", Content = "Disabled", Duration = 2, Icon = "lucide:hand" });
        end;
        return ;
    end
});
L_138.SupaTech:Toggle({
    Title = "Teleport Behind",
    Value = L_107.supaBehindEnabled,
    Callback = function(L_1978, ...)
        L_107.supaBehindEnabled = L_1978;
        return ;
    end
});
L_138.SupaTech:Slider({
    Title = "Supa Delay (ms)",
    Value = { Min = 0, Max = 500, Default = L_107.supaDelay * 1000 },
    Callback = function(L_1979, ...)
        L_107.supaDelay = tonumber(L_1979) / 1000;
        return ;
    end
});
L_138.SupaTech:Slider({
    Title = "Supa Speed (x10)",
    Value = { Min = 5, Max = 25, Default = L_107.supaSpeed * 10 },
    Callback = function(L_1980, ...)
        L_107.supaSpeed = tonumber(L_1980) / 10;
        return ;
    end
});
L_138.SupaTech:Slider({
    Title = "Supa Behind Offset",
    Value = { Min = 2, Max = 10, Default = L_107.supaBehindOffset },
    Callback = function(L_1981, ...)
        L_107.supaBehindOffset = tonumber(L_1981);
        return ;
    end
});
L_138.SupaTech:Slider({
    Title = "Lock Percentage",
    Value = { Min = 0, Max = 100, Default = L_107.supaLockPercent },
    Callback = function(L_1982, ...)
        L_107.supaLockPercent = tonumber(L_1982);
        return ;
    end
});
L_138.SupaTech:Slider({
    Title = "Random Movement",
    Value = { Min = 0, Max = 10, Default = L_107.supaRandomMovement },
    Callback = function(L_1983, ...)
        L_107.supaRandomMovement = tonumber(L_1983);
        return ;
    end
});
L_138.SideDash:Paragraph({ Title = "Hook Dash", Desc = "Side dash like a pro !(V to choose target C to do hook dash, if ur mobile double tap on someone)", Image = "geist:anchor", ImageSize = 20, Color = Color3.fromHex("#ff6b6b") });
L_138.SideDash:Toggle({
    Title = "Enable Hook Dash",
    Value = L_110.sideDashEnabled,
    Callback = function(L_1984, ...)
        L_110.sideDashEnabled = L_1984;
        if not L_1984 then
            cleanupSideDash();
        else
            setupSideDash();
        end;
        local L_1985 = L_82;
        local L_1986 = "Title";
        local L_1987 = "Side Dash Assist";
        local L_1988 = "Content";
        if L_1984 then
            L_1984 = "Enabled";
        end;
        if not L_1984 then
            L_1984 = "Disabled";
        end;
        L_1985:Notify({ [L_1986] = L_1987, [L_1988] = L_1984, Duration = 2 });
        return ;
    end
});
L_1989 = L_138.SideDash;
L_1990 = "Title";
L_1991 = "Target Color";
L_1992 = "Desc";
L_1993 = "Pick the highlight color";
L_1994 = "Default";
L_1995 = Color3.fromRGB;
L_1996 = L_110.sideDashTargetColorR;
L_1997 = L_110;
L_1998 = L_68;
L_1999 = L_1996 or 255;
L_2000 = L_1997[L_1998[L_81("l\247\204\179\131\169A\128\219*\181EFAn9g\172\179\224", 14871430109965)]];
L_2001 = L_110;
L_1989:Colorpicker({
    [L_1990] = L_1991,
    [L_1992] = L_1993,
    [L_1994] = L_1995(L_1999, L_2000 or 0, L_2001.sideDashTargetColorB or 0),
    Transparency = 0,
    Locked = false,
    Callback = function(L_2002, ...)
        local L_2003 = type(L_2002) == "table" and L_2002.Color or L_2002;
        setTargetColorFromColor3(L_2003);
        L_82:Notify({ Title = "SideDash", Content = "Target color updated", Duration = 1 });
        return ;
    end
});
L_138.SideDash:Toggle({
    Title = "Mobile Mode",
    Value = L_110.sideDashMobileMode,
    Callback = function(L_2004, ...)
        L_110.sideDashMobileMode = L_2004;
        if L_110.sideDashEnabled then
            if not L_2004 then
                if mobileDashGui then
                    mobileDashGui:Destroy();
                    mobileDashGui = nil;
                end;
            else
                createMobileDashButton();
            end;
        end;
        return ;
    end
});
L_138.SideDash:Toggle({
    Title = "Show Highlight",
    Value = L_110.sideDashShow,
    Callback = function(L_2005, ...)
        L_110.sideDashShow = L_2005;
        updateTargetColor();
        return ;
    end
});
L_138.SideDash:Paragraph({ Title = "Sorry !", Desc = "Other configs will come in feture updates !", Image = "geist:anchor", ImageSize = 20, Color = Color3.fromHex("#ff6b6b") });
L_138.LoopDash:Paragraph({ Title = "Loop Dash", Desc = "Do a loop while dashing", Image = "lucide:refresh-ccw-dot", ImageSize = 20, Color = Color3.fromHex("#4ecdc4") });
L_138.LoopDash:Toggle({
    Title = "Enable Feature",
    Value = L_110.loop,
    Callback = function(L_2006, ...)
        L_110.loop = L_2006;
        if not L_2006 then
            if L_111.loop then
                L_111.loop:Disconnect();
                L_111.loop = nil;
            end;
        elseif L_106.Character then
            L_745(L_106.Character);
        end;
        return ;
    end
});
L_138.LoopDash:Slider({
    Title = "Loop Delay ",
    Value = { Min = 0, Max = 500, Default = L_107.loopDelay * 1000 },
    Callback = function(L_2007, ...)
        L_107.loopDelay = tonumber(L_2007) / 1000;
        return ;
    end
});
L_138.LoopDash:Slider({
    Title = "Loop Radius",
    Value = { Min = 2, Max = 10, Default = L_107.loopRadius },
    Callback = function(L_2008, ...)
        L_107.loopRadius = tonumber(L_2008);
        return ;
    end
});
L_138.LoopDashv2:Paragraph({ Title = "Loop Dash v2 / Rework", Desc = "Just better loop dash, can also be used for oreo tech !", Image = "lucide:refresh-ccw-dot", ImageSize = 20, Color = Color3.fromHex("#4ecdc4") });
L_138.LoopDashv2:Toggle({
    Title = "LoopDash v2 Enabled",
    Value = L_110.loopRework,
    Callback = function(L_2009, ...)
        L_110.loopRework = L_2009;
        loopReworkSetupLoopRework();
        local L_2010 = L_82;
        local L_2011 = "Title";
        local L_2012 = "LoopDash v2";
        local L_2013 = "Content";
        local L_2014 = L_2009;
        if L_2009 then
            L_2014 = "ENABLED";
        end;
        if not L_2014 then
            L_2014 = "DISABLED";
        end;
        local L_2015 = "Icon";
        if L_2009 then
            L_2009 = "lucide:check";
        end;
        if not L_2009 then
            L_2009 = "lucide:x";
        end;
        L_2010:Notify({ [L_2011] = L_2012, [L_2013] = L_2014, [L_2015] = L_2009, Duration = 2 });
        return ;
    end
});
L_138.LoopDashv2:Toggle({
    Title = "Jump Assist",
    Desc = "Use this for oreo tech !",
    Value = L_110.ForceJumpEnabled,
    Callback = function(L_2016, ...)
        L_110.ForceJumpEnabled = L_2016;
        if not L_2016 then
            loopReworkForceJumpUnload();
        else
            loopReworkForceJumpSetup();
            loopReworkForceJumpUpdateCharacter(L_106.Character);
        end;
        return ;
    end
});
L_138.LoopDashv2:Slider({
    Title = "Jump hight",
    Value = { Min = 10, Max = 100, Default = L_110.ForceJumpUpwardVelocity or 52 },
    Callback = function(L_2017, ...)
        L_110.ForceJumpUpwardVelocity = L_2017;
        return ;
    end
});
L_138.LoopDashv2:Slider({
    Title = "Delay ",
    Value = { Min = 0, Max = 10, Default = L_110.loopReworkWaitDetect },
    Callback = function(L_2018, ...)
        L_110.loopReworkWaitDetect = L_2018;
        return ;
    end
});
L_138.LoopDashv2:Slider({
    Title = "First Flick Delay",
    Value = { Min = 0, Max = 10, Default = L_110.loopReworkWaitRemote },
    Callback = function(L_2019, ...)
        L_110.loopReworkWaitRemote = L_2019;
        return ;
    end
});
L_138.LoopDashv2:Slider({
    Title = "Smoothness",
    Value = { Min = 1, Max = 1000, Default = L_110.loopReworkResponsiveness },
    Callback = function(L_2020, ...)
        L_110.loopReworkResponsiveness = L_2020;
        return ;
    end
});
L_138.KAKYO:Paragraph({ Title = "Auto Kyoto tech!", Desc = "Flowing water into lethal", Image = "lucide:step-forward", ImageSize = 20, Color = Color3.fromHex("#052f8a") });
L_138.KAKYO:Toggle({
    Title = "Auto Kyoto",
    Value = kakyoAutoEnabled,
    Callback = function(L_2021, ...)
        kakyoAutoEnabled = L_2021;
        if not L_2021 then
            KAKYO_Stop();
        else
            KAKYO_Start();
        end;
        return ;
    end
});
L_138.KAKYO:Slider({
    Title = "Distance",
    Value = { Min = 0, Max = 50, Default = kakyoDistance },
    Callback = function(L_2022, ...)
        local L_2023 = math.floor(tonumber(L_2022) or kakyoDistance);
        kakyoDistance = L_2023;
        return ;
    end
});
L_138.KAKYO:Slider({
    Title = "Delay",
    Value = { Min = 1, Max = 1000, Default = math.floor((kakyoStartDelay or 0) * 1000) },
    Callback = function(L_2024, ...)
        local L_2025 = (tonumber(L_2024) or 0) / 1000;
        kakyoStartDelay = L_2025;
        return ;
    end
});
L_138.KAKYO:Toggle({
    Title = "Auto Hunter Surf",
    Value = L_110.autoSurf,
    Callback = function(L_2026, ...)
        L_110.autoSurf = L_2026;
        if not L_2026 then
            if autoSurfCharConnection then
                autoSurfCharConnection:Disconnect();
                autoSurfCharConnection = nil;
            end;
            if autoSurfRenderConnection then
                autoSurfRenderConnection:Disconnect();
                autoSurfRenderConnection = nil;
            end;
            autoSurfActive = false;
            autoSurfIsTweening = false;
        else
            setupAutoSurf();
        end;
        return ;
    end
});
L_138.LethalDash:Paragraph({ Title = "Lethal Dash", Desc = "Lethal water into a dash", Image = "geist:arrow-up-down", ImageSize = 20, Color = Color3.fromHex("#eb4d4b") });
L_138.LethalDash:Toggle({
    Title = "Enable LethalDash",
    Value = L_110.autoLockJump,
    Callback = function(L_2027, ...)
        L_110.autoLockJump = L_2027;
        SetupAutoLockJump();
        if L_2027 then
        end;
        return ;
    end
});
L_138.LethalDash:Slider({
    Title = "First flick delay",
    Value = { Min = 0, Max = 10, Default = L_110.autoLockJumpWaitRemote },
    Callback = function(L_2028, ...)
        L_110.autoLockJumpWaitRemote = tonumber(L_2028);
        return ;
    end
});
L_138.LethalDash:Slider({
    Title = "Smoothness",
    Value = { Min = 20, Max = 1000, Default = L_110.autoLockJumpResponsiveness },
    Callback = function(L_2029, ...)
        L_110.autoLockJumpResponsiveness = tonumber(L_2029);
        return ;
    end
});
L_138.LethalDash:Toggle({
    Title = "Auto Lethal Dunk",
    Value = L_110.autoWhirlwindDunk,
    Callback = function(L_2030, ...)
        L_110.autoWhirlwindDunk = L_2030;
        if not L_2030 then
            if autoWhirlwindDunkConnection then
                autoWhirlwindDunkConnection:Disconnect();
                autoWhirlwindDunkConnection = nil;
            end;
            autoWhirlwindDunkIsTeleporting = false;
            autoWhirlwindDunkLastTrack = nil;
        else
            setupAutoWhirlwindDunk();
        end;
        return ;
    end
});
L_138.M1Reset:Button({
    Title = "Execute M1 Reset Script",
    Icon = "zap",
    Callback = function(...)
        loadstring("            local Players=game:GetService(\"Players\");local Plr=Players.LocalPlayer;local UIS=game:GetService(\"UserInputService\");local TweenService=game:GetService(\"TweenService\");local RunService=game:GetService(\"RunService\");local Workspace=game:GetService(\"Workspace\");local ReplicatedStorage=game:GetService(\"ReplicatedStorage\");local VIM;pcall(function()VIM=game:GetService(\"VirtualInputManager\")end)VIM=VIM or rawget(_G,\"VirtualInputManager\") or (rawget(_G,\"syn\") and rawget(_G,\"syn\").virtual_input) or rawget(_G,\"virtualinputmanager\");local KEYBINDS={M1_RESET=Enum.KeyCode.R,EMOTE_DASH=Enum.KeyCode.T};getgenv().connections=getgenv().connections or {} if type(getgenv().connections)==\"table\"then for _,c in ipairs(getgenv().connections)do pcall(function()if c and c.Disconnect then c:Disconnect()end end)end end;getgenv().connections={};local function chooseGuiParent(timeout)timeout=timeout or 2;if type(gethui)==\"function\"then local ok,g=pcall(gethui)if ok and g then return g end end;if Plr then local s=tick() while tick()-s<timeout do if Plr:FindFirstChild(\"PlayerGui\")then return Plr.PlayerGui end task.wait(0.05)end if Plr:FindFirstChild(\"PlayerGui\")then return Plr.PlayerGui end end;local ok,core=pcall(function()return game:GetService(\"CoreGui\")end)if ok and core then return core end;return game:GetService(\"StarterGui\")end;local GuiParent=chooseGuiParent(3);pcall(function()for _,name in ipairs({\"M1_RESET_UI\",\"TSB_UI\",\"M1ResetUI\"})do local old=GuiParent:FindFirstChild(name)if old then old:Destroy()end end end);local function protectGui(g)local _syn=rawget(_G,\"syn\")if _syn and type(_syn.protect_gui)==\"function\"then pcall(function()_syn.protect_gui(g)end)end end;local Themes={{name=\"Dark\",Panel=Color3.fromRGB(30,30,30),Button=Color3.fromRGB(50,50,50),Accent=Color3.fromRGB(200,200,200),Text=Color3.fromRGB(255,255,255)},{name=\"Gray\",Panel=Color3.fromRGB(60,60,60),Button=Color3.fromRGB(80,80,80),Accent=Color3.fromRGB(150,150,150),Text=Color3.fromRGB(255,255,255)},{name=\"Black\",Panel=Color3.fromRGB(20,20,20),Button=Color3.fromRGB(40,40,40),Accent=Color3.fromRGB(100,100,100),Text=Color3.fromRGB(255,255,255)},{name=\"Neon\",Panel=Color3.fromRGB(10,10,10),Button=Color3.fromRGB(0,200,255),Accent=Color3.fromRGB(255,0,255),Text=Color3.fromRGB(255,255,255)},{name=\"Cyber\",Panel=Color3.fromRGB(15,15,20),Button=Color3.fromRGB(35,35,45),Accent=Color3.fromRGB(0,255,150),Text=Color3.fromRGB(255,255,255)}};local themeIndex,Theme=1,Themes[1];local function roundify(inst,r)local c=Instance.new(\"UICorner\")c.CornerRadius=UDim.new(0,r or 12)c.Parent=inst end;local function stroke(inst,color,thickness,trans)local s=Instance.new(\"UIStroke\")s.Color=color or Theme.Accent s.Thickness=thickness or 1 s.Transparency=trans or 0.5 s.Parent=inst end;local rootGui=nil;local floats={};local isPerformingAction=false;local animCache={};local camera=Workspace.CurrentCamera;local function getCharacter()local char=Plr and Plr.Character;local humanoid=char and char:FindFirstChildOfClass(\"Humanoid\");return char,humanoid end;local function Stopallanimation()local _,humanoid=getCharacter() if humanoid then local animator=humanoid:FindFirstChildOfClass(\"Animator\") if animator then local success,tracks=pcall(function()return animator:GetPlayingAnimationTracks()end) if success and tracks then for _,track in ipairs(tracks)do pcall(function()track:Stop()end)end end end end end;local function playAnimation(animationId)local _,humanoid=getCharacter() if not humanoid then return end;local animator=humanoid:FindFirstChildOfClass(\"Animator\") if not animator then animator=Instance.new(\"Animator\") animator.Parent=humanoid end;local animation=animCache[animationId] if not animation then animation=Instance.new(\"Animation\") animation.AnimationId=\"rbxassetid://\"..tostring(animationId) animCache[animationId]=animation end;local ok,animTrack=pcall(function()return animator:LoadAnimation(animation)end) if not ok or not animTrack then return end;animTrack.Priority=Enum.AnimationPriority.Action;animTrack:Play();pcall(function()animTrack:AdjustSpeed(1.2)end);return animTrack end;local function rotateCharacter(degrees) if isPerformingAction then return end;isPerformingAction=true;local character,_=getCharacter() local rootPart=character and character:FindFirstChild(\"HumanoidRootPart\") if rootPart then pcall(function() rootPart.CFrame=rootPart.CFrame*CFrame.Angles(0,math.rad(degrees),0);local camPos=camera and camera.CFrame.Position or rootPart.Position+Vector3.new(0,5,0);local camY=camPos.Y;local distanceVec=camPos-rootPart.Position;local flatVec=Vector3.new(distanceVec.X,0,distanceVec.Z);local rotatedVec=CFrame.fromAxisAngle(Vector3.yAxis,math.rad(degrees))*flatVec;local newCamPos=rootPart.Position+rotatedVec;if camera and camera:IsA(\"Camera\") then camera.CFrame=CFrame.lookAt(Vector3.new(newCamPos.X,camY,newCamPos.Z),rootPart.Position) end end) end;isPerformingAction=false end;local function sideDash(direction,distance,duration) if isPerformingAction then return end;isPerformingAction=true;local character,_=getCharacter() local rootPart=character and character:FindFirstChild(\"HumanoidRootPart\") if rootPart then local tween=TweenService:Create(rootPart,TweenInfo.new(duration,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{CFrame=rootPart.CFrame*CFrame.new(direction*distance,0,0)}) pcall(function()tween:Play()end) if tween then pcall(function()tween.Completed:Wait()end) end pcall(function()tween:Destroy()end) end;isPerformingAction=false end;local function impulseDash(direction,distance,height,power,duration) if isPerformingAction then return end;isPerformingAction=true;local character,_=getCharacter() local rootPart=character and character:FindFirstChild(\"HumanoidRootPart\") if rootPart then local force=Instance.new(\"BodyVelocity\") local vec=(rootPart.CFrame.RightVector*direction*distance+Vector3.new(0,height,0)) if vec.Magnitude==0 then vec=Vector3.new(0,1,0) end;force.Velocity=vec.Unit*power;force.MaxForce=Vector3.new(math.huge,math.huge,math.huge);force.Parent=rootPart;task.delay(duration,function() pcall(function()force:Destroy()end) end) end;isPerformingAction=false end;local function doM1Reset() Stopallanimation();pcall(function()playAnimation(10480793962)end);pcall(function()sideDash(1,26,0.22)end);pcall(function()rotateCharacter(70)end);task.wait(0.003);pcall(function() if VIM and type(VIM.SendKeyEvent)==\"function\" then VIM:SendKeyEvent(true,Enum.KeyCode.Q,false,game) VIM:SendKeyEvent(false,Enum.KeyCode.Q,false,game) end end) end;local function doEmoteDash() Stopallanimation();pcall(function()playAnimation(10480793962)end);pcall(function()rotateCharacter(90)end);pcall(function()impulseDash(1,38,8,95,0.27)end) end;local vimAvailable=(VIM and type(VIM.SendKeyEvent)==\"function\");rootGui=Instance.new(\"ScreenGui\") rootGui.Name=\"M1_RESET_UI\" rootGui.ResetOnSpawn=false rootGui.IgnoreGuiInset=true rootGui.DisplayOrder=9999 rootGui.ZIndexBehavior=Enum.ZIndexBehavior.Global;local function setRootParent() local parent=(Plr and Plr:FindFirstChild(\"PlayerGui\")) or game:GetService(\"CoreGui\") or game:GetService(\"StarterGui\");local ok=pcall(function() rootGui.Parent=parent end);if ok and rootGui.Parent then return true end;local alt=chooseGuiParent(2);local ok2=pcall(function() rootGui.Parent=alt end);return ok2 and rootGui.Parent end;setRootParent();protectGui(rootGui);local function applyTheme() for _,inst in ipairs(rootGui:GetDescendants())do if inst:IsA(\"TextLabel\") or inst:IsA(\"TextButton\") then inst.TextColor3=Theme.Text end if inst:IsA(\"Frame\") then inst.BackgroundColor3=Theme.Panel end if inst:IsA(\"TextButton\") and inst.Name~=\"MobileBtn\" then inst.BackgroundColor3=Theme.Button end local s=inst:FindFirstChildOfClass(\"UIStroke\") if s then pcall(function() s.Color=Theme.Accent end) end end for _,f in ipairs(floats)do if f then f.BackgroundColor3=Theme.Button f.TextColor3=Theme.Text local s=f:FindFirstChildOfClass(\"UIStroke\") if s then pcall(function() s.Color=Theme.Accent end) end end end end;local Intro=Instance.new(\"Frame\",rootGui) Intro.Size=UDim2.fromOffset(300,160) Intro.Position=UDim2.new(0.5,-150,0.1,-200) Intro.BackgroundColor3=Theme.Panel Intro.BackgroundTransparency=0.15 roundify(Intro,14) stroke(Intro,Theme.Accent,1,0.5);local IntroTxt=Instance.new(\"TextLabel\",Intro) IntroTxt.Size=UDim2.fromScale(1,1) IntroTxt.BackgroundTransparency=1 IntroTxt.TextColor3=Theme.Text IntroTxt.Font=Enum.Font.GothamBold IntroTxt.TextSize=20 IntroTxt.TextWrapped=true IntroTxt.Text=\"M1 Reset by dovi!\\nKeybinds: R = M1 Reset | T = Emote Dash\" pcall(function()TweenService:Create(Intro,TweenInfo.new(0.5,Enum.EasingStyle.Bounce,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,-150,0.1,0)}):Play()end) task.delay(4,function() pcall(function()TweenService:Create(Intro,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.new(0.5,-150,0.1,-200)}):Play()end) task.wait(0.4) pcall(function() if Intro and Intro.Parent then Intro:Destroy() end end) end);local Panel=Instance.new(\"Frame\",rootGui) Panel.Size=UDim2.new(0,190,0,200) Panel.Position=UDim2.new(0,20,0.5,0) Panel.BackgroundColor3=Theme.Panel Panel.BackgroundTransparency=1 roundify(Panel,16) stroke(Panel,Theme.Accent,1,0.5) pcall(function()TweenService:Create(Panel,TweenInfo.new(0.4),{BackgroundTransparency=0.2}):Play()end);do local dragging,dragInput,dragStart,startPos=false,nil,nil,nil;Panel.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true dragInput=input dragStart=input.Position startPos=Panel.Position input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end) end end);Panel.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end end);RunService.RenderStepped:Connect(function() if dragging and dragInput and dragStart and startPos then local delta=dragInput.Position-dragStart Panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y) end end) end;local Header=Instance.new(\"Frame\",Panel) Header.Size=UDim2.new(1,0,0,34) Header.BackgroundTransparency=1;local Title=Instance.new(\"TextLabel\",Header) Title.Size=UDim2.new(1,-130,1,0) Title.Position=UDim2.new(0,12,0,0) Title.BackgroundTransparency=1 Title.Text=\"M1 reset by dovi!\" Title.Font=Enum.Font.GothamBlack Title.TextSize=16 Title.TextColor3=Theme.Text Title.TextXAlignment=Enum.TextXAlignment.Left;local ThemeBtn=Instance.new(\"TextButton\",Header) ThemeBtn.Size=UDim2.new(0,100,0,30) ThemeBtn.Position=UDim2.new(1,-110,0.5,-15) ThemeBtn.BackgroundColor3=Theme.Button ThemeBtn.TextColor3=Theme.Text ThemeBtn.Font=Enum.Font.GothamBold ThemeBtn.TextSize=14 ThemeBtn.Text=\"Theme: \"..Theme.name roundify(ThemeBtn,10) stroke(ThemeBtn,Theme.Accent,1,0.5) ThemeBtn.MouseButton1Click:Connect(function() themeIndex=themeIndex%#Themes+1 Theme=Themes[themeIndex] ThemeBtn.Text=\"Theme: \"..Theme.name applyTheme() end);local factoryButtons={} local function makeBtn(text,y,cb) local b=Instance.new(\"TextButton\",Panel) b.Size=UDim2.new(1,-24,0,44) b.Position=UDim2.new(0,12,0,y) b.BackgroundColor3=Theme.Button b.TextColor3=Theme.Text b.Font=Enum.Font.GothamBold b.TextSize=16 b.Text=text roundify(b,12) stroke(b,Theme.Accent,1,0.5) b.AutoButtonColor=false b.MouseEnter:Connect(function() pcall(function()TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=Theme.Accent,Size=UDim2.new(1,-22,0,46)}):Play()end) end) b.MouseLeave:Connect(function() pcall(function()TweenService:Create(b,TweenInfo.new(0.15),{BackgroundColor3=Theme.Button,Size=UDim2.new(1,-24,0,44)}):Play()end) end) b.MouseButton1Down:Connect(function() pcall(function()TweenService:Create(b,TweenInfo.new(0.1),{Size=UDim2.new(1,-26,0,42)}):Play()end) end) b.MouseButton1Up:Connect(function() pcall(function()TweenService:Create(b,TweenInfo.new(0.1),{Size=UDim2.new(1,-22,0,46)}):Play()end) end) b.MouseButton1Click:Connect(function() task.spawn(function() pcall(cb) end) end) table.insert(factoryButtons,b) return b end;local btnM1=makeBtn(\"M1 Reset\",54,doM1Reset) local btnEmote=makeBtn(\"Emote Dash\",104,doEmoteDash) local btnUnload=makeBtn(\"Unload\",154,function() for _,c in ipairs(getgenv().connections)do pcall(function() if c and c.Disconnect then c:Disconnect() end end) end getgenv().connections={} pcall(function()rootGui:Destroy()end) end);local mobileMode=false;local function createFloat(btn,idx) task.wait(0.1) local screenSize=camera and camera.ViewportSize or Vector2.new(1920,1080) local baseX=20+(idx-1)*150 local baseY=screenSize.Y-100 local f=Instance.new(\"TextButton\",rootGui) f.Size=UDim2.new(0,140,0,45) f.Position=UDim2.new(0,math.clamp(baseX,12,screenSize.X-150),0,math.clamp(baseY,12,screenSize.Y-60)) f.BackgroundColor3=Theme.Button f.TextColor3=Theme.Text f.Font=btn.Font f.TextSize=btn.TextSize f.Text=btn.Text roundify(f,12) stroke(f,Theme.Accent,1,0.5) f.ZIndex=100 f.BackgroundTransparency=1 f.TextTransparency=1 pcall(function()TweenService:Create(f,TweenInfo.new(0.3),{BackgroundTransparency=0,TextTransparency=0}):Play()end) f.MouseButton1Click:Connect(function() if f.Text:match(\"M1\") then pcall(doM1Reset) elseif f.Text:match(\"Emote\") then pcall(doEmoteDash) end end) do local dragging,dragInput,dragStart,startPos=false,nil,nil,nil f.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true dragInput=input dragStart=input.Position startPos=Vector2.new(f.Position.X.Offset,f.Position.Y.Offset) input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end) end end) f.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end end) local conn conn=RunService.RenderStepped:Connect(function() if dragging and dragInput and dragStart and startPos then local delta=dragInput.Position-dragStart local newPos=startPos+Vector2.new(delta.X,delta.Y) f.Position=UDim2.new(0,newPos.X,0,newPos.Y) end end) f.AncestryChanged:Connect(function() if not f.Parent and conn then conn:Disconnect() end end) end return f end;local MobileBtn=Instance.new(\"TextButton\",Panel) MobileBtn.Size=UDim2.new(0,100,0,30) MobileBtn.Position=UDim2.new(1,-110,1,5) MobileBtn.BackgroundColor3=Theme.Button MobileBtn.TextColor3=Theme.Text MobileBtn.Font=Enum.Font.GothamBold MobileBtn.TextSize=14 MobileBtn.Text=\"Mobile: OFF\" roundify(MobileBtn,10) stroke(MobileBtn,Theme.Accent,1,0.5) MobileBtn.MouseButton1Click:Connect(function() mobileMode=not mobileMode MobileBtn.Text=mobileMode and \"Mobile: ON\" or \"Mobile: OFF\" if mobileMode then pcall(function()TweenService:Create(Panel,TweenInfo.new(0.3),{Size=UDim2.new(0,160,0,100)}):Play()end) Panel.Position=UDim2.new(0,20,0.6,0) btnM1.Visible=false btnEmote.Visible=false pcall(function()TweenService:Create(btnUnload,TweenInfo.new(0.3),{Position=UDim2.new(0,12,0,54)}):Play()end) floats={} table.insert(floats,createFloat(btnM1,1)) table.insert(floats,createFloat(btnEmote,2)) else for _,f in ipairs(floats)do pcall(function()TweenService:Create(f,TweenInfo.new(0.2),{BackgroundTransparency=1,TextTransparency=1}):Play()end) task.wait(0.3) pcall(function()f:Destroy()end) end floats={} pcall(function()TweenService:Create(Panel,TweenInfo.new(0.3),{Size=UDim2.new(0,190,0,200)}):Play()end) Panel.Position=UDim2.new(0,20,0.5,0) btnM1.Visible=true btnEmote.Visible=true pcall(function()TweenService:Create(btnUnload,TweenInfo.new(0.3),{Position=UDim2.new(0,12,0,154)}):Play()end) end end);applyTheme();local connInput=UIS.InputBegan:Connect(function(input,gpe) if gpe then return end if UIS:GetFocusedTextBox() then return end if input.UserInputType~=Enum.UserInputType.Keyboard then return end if input.KeyCode==KEYBINDS.M1_RESET then pcall(doM1Reset) elseif input.KeyCode==KEYBINDS.EMOTE_DASH then pcall(doEmoteDash) end end) table.insert(getgenv().connections,connInput)\n        ")();
        return ;
    end
});
L_138.M1Reset:Toggle({
    Title = "No End Lag",
    Value = L_110.noEndLag,
    Callback = function(L_2031, ...)
        L_110.noEndLag = L_2031;
        if not L_2031 then
            if L_1911 then
                L_1911:Disconnect();
                L_1911 = nil;
            end;
            L_1909 = false;
            L_82:Notify({ Title = "No End Lag", Content = "Disabled", Duration = 2 });
        else
            if L_106.Character then
                L_1917(L_106.Character);
            end;
            L_82:Notify({ Title = "No End Lag", Content = "Enabled", Duration = 2 });
        end;
        return ;
    end
});
L_138.InstantTwisted:Paragraph({ Title = "Instant Twisted", Desc = "4m1 into a dash", Image = "lucide:corner-up-right", ImageSize = 20, Color = Color3.fromHex("#00b894") });
L_138.InstantTwisted:Toggle({
    Title = "Enable Instant Twisted",
    Value = L_110.instantTwisted,
    Callback = function(L_2032, ...)
        L_110.instantTwisted = L_2032;
        if L_2032 then
            L_821();
        end;
        return ;
    end
});
L_138.InstantTwisted:Toggle({
    Title = "Normal twisted",
    Value = L_110.autoTwisted,
    Callback = function(L_2033, ...)
        L_110.autoTwisted = L_2033;
        if not L_2033 then
            if autoTwistedAnimationConnection then
                autoTwistedAnimationConnection:Disconnect();
                autoTwistedAnimationConnection = nil;
            end;
            if autoTwistedCharAddedConnection then
                autoTwistedCharAddedConnection:Disconnect();
                autoTwistedCharAddedConnection = nil;
            end;
        else
            setupAutoTwisted();
        end;
        return ;
    end
});
L_138.AutoCounter:Paragraph({ Title = "Auto Counter", Desc = "Automatically counter attacks", Image = "lucide:shield", ImageSize = 20, Color = Color3.fromHex("#0984e3") });
L_138.AutoCounter:Toggle({
    Title = "Enable Feature",
    Value = L_110.autoCounter,
    Callback = function(L_2034, ...)
        L_110.autoCounter = L_2034;
        if not L_2034 then
            if L_111.autoCounter then
                L_111.autoCounter:Disconnect();
                L_111.autoCounter = nil;
            end;
        else
            setupAutoCounter();
        end;
        return ;
    end
});
L_138.AutoCounter:Slider({
    Title = "Counter Distance",
    Value = { Min = 5, Max = 20, Default = L_107.autoCounterDistance },
    Callback = function(L_2035, ...)
        L_107.autoCounterDistance = tonumber(L_2035);
        return ;
    end
});
L_138.YOYO:Paragraph({ Title = "Kiba Tech", Desc = "uhh dash and look up...idk :3", Image = "lucide:crosshair", ImageSize = 20, Color = Color3.fromHex("#ff6b6b") });
L_138.YOYO:Toggle({
    Title = "Enable Kiba Tech",
    Value = L_110.yoyo,
    Callback = function(L_2036, ...)
        L_110.yoyo = L_2036;
        if not L_2036 then
            yoyoDetach();
            if L_111.yoyo then
                L_111.yoyo:Disconnect();
                L_111.yoyo = nil;
            end;
        elseif L_106.Character then
            setupYOYOCharacter(L_106.Character);
        end;
        return ;
    end
});
L_138.TechHelper:Paragraph({ Title = "Tech Helper", Desc = "helps with techs....duhh", Image = "lucide:hand-helping", ImageSize = 20, Color = Color3.fromHex("#a29bfe") });
L_138.TechHelper:Toggle({
    Title = "Enable Feature",
    Value = L_110.techHelper,
    Callback = function(L_2037, ...)
        L_110.techHelper = L_2037;
        if not L_2037 then
            if L_111.techHelper then
                L_111.techHelper:Disconnect();
                L_111.techHelper = nil;
            end;
        else
            L_1907();
        end;
        return ;
    end
});
L_138.TechHelper:Slider({
    Title = "Tech Helper Delay (ms)",
    Value = { Min = 100, Max = 500, Default = L_107.techHelperDelay * 1000 },
    Callback = function(L_2038, ...)
        L_107.techHelperDelay = tonumber(L_2038) / 1000;
        return ;
    end
});
L_138.TechHelper:Slider({
    Title = "Tech Helper Hold (ms)",
    Value = { Min = 50, Max = 500, Default = L_107.techHelperHold * 1000 },
    Callback = function(L_2039, ...)
        L_107.techHelperHold = tonumber(L_2039) / 1000;
        return ;
    end
});
L_138.TechHelper:Toggle({
    Title = "Tech Helper Look Up",
    Value = L_107.techHelperLookUp,
    Callback = function(L_2040, ...)
        L_107.techHelperLookUp = L_2040;
        return ;
    end
});
L_138.TechHelper:Slider({
    Title = "Tech Helper Lock Percentage",
    Value = { Min = 0, Max = 100, Default = L_107.techHelperLockPercent },
    Callback = function(L_2041, ...)
        L_107.techHelperLockPercent = tonumber(L_2041);
        return ;
    end
});
L_138.TechHelper:Divider();
L_138.TechHelper:Toggle({
    Title = "Enable M1 Catch",
    Value = L_110.m1Catch,
    Callback = function(L_2042, ...)
        L_110.m1Catch = L_2042;
        L_1364(L_2042);
        local L_2043 = L_82;
        local L_2044 = "Title";
        local L_2045 = "M1 Catch";
        local L_2046 = "Content";
        if L_2042 then
            L_2042 = "Enabled";
        end;
        if not L_2042 then
            L_2042 = "Disabled";
        end;
        L_2043:Notify({ [L_2044] = L_2045, [L_2046] = L_2042, Duration = 2 });
        return ;
    end
});
L_138.TechHelper:Slider({
    Title = "M1 Catch Range (studs)",
    Value = { Min = 2, Max = 20, Default = L_110.m1Range },
    Callback = function(L_2047, ...)
        L_110.m1Range = tonumber(L_2047);
        return ;
    end
});
L_138.TechHelper:Slider({
    Title = "M1 Catch Hold (ms)",
    Value = { Min = 10, Max = 1000, Default = L_110.m1Hold },
    Callback = function(L_2048, ...)
        L_110.m1Hold = tonumber(L_2048);
        return ;
    end
});
L_138.TechHelper:Slider({
    Title = "M1 Catch Prediction %",
    Value = { Min = 0, Max = 100, Default = L_110.m1Pred },
    Callback = function(L_2049, ...)
        L_110.m1Pred = tonumber(L_2049);
        return ;
    end
});
L_138.TechHelper:Divider();
L_138.TechHelper:Toggle({
    Title = "Fast Dash",
    Desc = "NOT COMPATIBLE WITH MOST FETURES",
    Value = L_110.fastDash,
    Callback = function(L_2050, ...)
        L_110.fastDash = L_2050;
        if not L_2050 then
            if L_111.fastDash then
                L_111.fastDash:Disconnect();
                L_111.fastDash = nil;
            end;
            L_82:Notify({ Title = "Fast Dash", Content = "Disabled", Duration = 2 });
        else
            if L_106.Character then
                L_1603(L_106.Character);
            end;
            L_82:Notify({ Title = "Fast Dash", Content = "Enabled", Duration = 2 });
        end;
        return ;
    end
});
L_138.TechHelper:Toggle({
    Title = "Only Torso Collisions",
    Value = L_110.onlyTorsoCollisions,
    Callback = function(L_2051, ...)
        L_110.onlyTorsoCollisions = L_2051;
        setupOnlyTorsoCollisions();
        local L_2052 = L_82;
        local L_2053 = "Title";
        local L_2054 = "Only Torso Collisions";
        local L_2055 = "Content";
        if L_2051 then
            L_2051 = "Only Torso Collisions enabled";
        end;
        if not L_2051 then
            L_2051 = "Only Torso Collisions disabled";
        end;
        L_2052:Notify({ [L_2053] = L_2054, [L_2055] = L_2051, Duration = 3 });
        return ;
    end
});
L_138.TechHelper:Divider();
L_138.TechHelper:Toggle({
    Title = "Enable MouseDash",
    Value = L_110.mouseDash,
    Callback = function(L_2056, ...)
        L_110.mouseDash = L_2056;
        L_1835();
        return ;
    end
});
L_138.TechHelper:Slider({
    Title = "MouseDash Delay (ms)",
    Value = { Min = 500, Max = 3000, Default = L_110.mouseDashDelay },
    Callback = function(L_2057, ...)
        L_110.mouseDashDelay = L_2057;
        return ;
    end
});
L_2058 = { Name = "Baldy To Sorcerer", URL = "https://raw.githubusercontent.com/Onihub-sigma/OniHub-Gojo-Public/refs/heads/main/Gojo%20Onihub%20Public.txt" };
L_2059 = { Name = "GAROU TO V1", URL = "https://raw.githubusercontent.com/Nova2ezz/GarouToV1/refs/heads/main/GarouToV1.txt" };
L_2060 = { Name = "SUNG JIN WOO USE NINJA", URL = "https://raw.githubusercontent.com/Nova2ezz/nova2ezz-SungjiWoo/refs/heads/main/Protected_7939201355282604.txt" };
L_2061 = { Name = "ATOMIC SAMOURAI TO VERGIL", URL = "https://raw.githubusercontent.com/Nova2ezz/vergilmoveset/refs/heads/main/Protected_9080797627073616.txt" };
L_2062 = { Name = "JJS GOJO v3", URL = "https://raw.githubusercontent.com/damir512/jjsgojov3/main/SaitamaToGojoV3_SOURCE-obfuscated_2.txt" };
L_2063 = { Name = "GAROU TO KJ", URL = "https://raw.githubusercontent.com/damir512/garoukjv1maybeidk/main/Protected_2460290213750059.txt" };
L_2064 = { Name = "MINOS PRIME", URL = "https://raw.githubusercontent.com/S1gmaGuy/MinosPrimeFixed/refs/heads/main/ThefixIsSoSigma" };
L_2065 = { Name = "ATOMIC TO YUTA", URL = "https://raw.githubusercontent.com/damir512/AtomicToYuta/main/Protected_8122576078506000.txt" };
L_2066 = { Name = "OKRAUN", URL = "https://raw.githubusercontent.com/damir512/hakari/main/Protected_5980408162046394.txt" };
L_2067 = { Name = "TODO", URL = "https://raw.githubusercontent.com/Nova2ezz/Todo-moveset/refs/heads/main/Todo" };
L_2068 = { Name = "Blady To Mahito", URL = "https://raw.githubusercontent.com/Kenjihin69/Kenjihin69/refs/heads/main/Mahitotsbupdate" };
L_2069 = { Name = "Sonic.Exe", URL = "https://raw.githubusercontent.com/Nova2ezz/sonic-exe-moveset-3/refs/heads/main/3" };
L_2070 = { Name = "APOPHENIA V2 EDUCATION", URL = "https://raw.githubusercontent.com/Reapvitalized/TSB/main/APOPHENIA.lua" };
L_2071 = { Name = "Atomic To Sukuna", URL = "https://raw.githubusercontent.com/zyrask/Nexus-Base/main/atomic-blademaster%20to%20sukuna" };
L_2072 = { Name = "Kyra KJ", URL = "https://gist.githubusercontent.com/GoldenHeads25/fe3178dff916f988d319c3bd5e4fc01/raw/b250ee6f967c4e84195a76ab7915fb1d79b53326/gistfile1.txt" };
L_2073 = { Name = "Kyra Gojo", URL = "https://raw.githubusercontent.com/skibidtoiletfan2007/BaldBald BaldyToSorcerer/main/Latest.lua" };
L_2074 = { Name = "Luffy", URL = "https://github.com/aggiealledge/obfuscated-scripts/raw/refs/heads/main/Protected_7732857839120517.txt" };
L_2075 = { Name = "Shinjin", URL = "https://raw.githubusercontent.com/Kenjihin69/Kenjihin69/refs/heads/main/Shinji%20tp%20exploit" };
L_2076 = { Name = "SUKUNA", URL = "https://raw.githubusercontent.com/damir512/whendoesbrickdie/main/tspno.txt" };
L_2077 = { Name = "Sans", URL = "https://paste.ee/r/rF9d3" };
L_2078 = { Name = "Cosminc GAROU", URL = "https://pastebin.com/raw/kT3Z8rse" };
L_2079 = { Name = "SONIC .EXE", URL = "https://pastefy.app/4zLt8a2P/raw" };
L_2080 = { Name = "WALLY WEST", URL = "https://raw.githubusercontent.com/Nova2ezz/west/refs/heads/main/Protected_4638864115822087.lua.txt" };
L_2081 = { Name = "LAIFU", URL = "https://paste.ee/r/Knl1L56b" };
L_2082 = { Name = "BEERUS", URL = "https://raw.githubusercontent.com/sparksnaps/Beerus-The-Destroyer/refs/heads/main/Lua" };
L_2083 = { Name = "MADARA", URL = "https://raw.githubusercontent.com/LolnotaKid/SCRIPTSBYVEUX/refs/heads/main/BoombasticLol.lua.txt" };
L_2084 = { Name = "GoldenHead", URL = "https://raw.githubusercontent.com/Kenjihin69/Kenjihin69/refs/heads/main/Saitama%20to%20golden%20sigma" };
L_2085 = { Name = "GOJO moveset BEST", URL = "https://raw.githubusercontent.com/Kenjihin69/Kenjihin69/refs/heads/main/Saitama%20to%20golden%20sigma" };
L_2086 = { Name = "MASTERY DEKU", URL = "https://pastebin.com/raw/xKextYP5" };
L_2087 = { Name = "TRASHCAN", URL = "https://raw.githubusercontent.com/yes1nt/yes/refs/heads/main/Trashcan%20Man" };
L_2088 = { Name = "Star Glitcher (Euphoria)", URL = "https://paste.ee/r/mmQkO" };
L_2089 = { Name = "Dio", URL = "https://raw.githubusercontent.com/ThanakritScript/StandUserCilent/refs/heads/main/DioBeta.lua" };
L_2090 = { Name = "Mastery Deku", URL = "https://pastebin.com/raw/xKextYP5" };
L_2091 = { Name = "A-Train", URL = "https://paste.ee/r/AnZ5j" };
L_2092 = { Name = "Goku", URL = "https://rawscripts.net/raw/The-Strongest-Battlegrounds-Goku-Moveset-V2-17977" };
L_2093 = { Name = "Shinjuku Yuji", URL = "https://raw.githubusercontent.com/Kenjihin69/Kenjihin69/refs/heads/main/Yuji%20early%20access" };
L_2094 = { Name = "Multiple moves", URL = "https://raw.githubusercontent.com/Reapvitalized/TSB/refs/heads/main/SG_DEMO.lua" };
L_2095 = { Name = "1x1x1", URL = "https://gist.githubusercontent.com/GoldenHeads2/900e87ffc32f3c740930ccb106dd6abf/raw/358c5bf0f0a6aa25946718288dab006e3ae7e1d4/gistfile1.txt" };
L_2096 = { Name = "Chainsaw Man", URL = "https://gist.githubusercontent.com/GoldenHeads2/0fd8d36993c850f3fac89e5adf793076/raw/ab4f5a42bd0b2e24a32a46301d533ea849ca771c/gistfile1.txt" };
L_2097 = { ipairs({ L_2058, L_2059, L_2060, L_2061, L_2062, L_2063, L_2064, L_2065, L_2066, L_2067, L_2068, L_2069, L_2070, L_2071, L_2072, L_2073, L_2074, L_2075, L_2076, L_2077, L_2078, L_2079, L_2080, L_2081, L_2082, L_2083, L_2084, L_2085, L_2086, L_2087, L_2088, L_2089, L_2090, L_2091, L_2092, L_2093, L_2094, L_2095, L_2096 }) };
L_2098 = L_2097[1];
L_2099 = L_2097[3];
L_2100 = L_2097[2];
while true do
    local L_2101;
    L_2099, L_2101 = L_2098(L_2100, L_2099);
    if not L_2099 then
        break;
    end;
    local L_2102 = L_2101;
    L_138.Animations:Button({
        Title = L_2102.Name,
        Callback = function(...)
            loadstring(game:HttpGet(L_2102.URL))();
            L_82:Notify({ Title = "Animation Loaded", Content = L_2102.Name .. " animation script loaded", Duration = 3 });
            return ;
        end
    });
end;
L_138.Utilities:Paragraph({ Title = "Utilities", Desc = "Various utility features (QOF)", Image = "lucide:square-plus", ImageSize = 20, Color = Color3.fromHex("#b2bec3") });
L_2103 = game:GetService("Lighting");
L_2104 = nil;
L_2111 = function(...)
    local L_2105 = { ipairs(L_2103:GetChildren()) };
    local L_2106 = L_2105[3];
    local L_2107 = L_2105[2];
    local L_2108 = L_2105[1];
    while true do
        local L_2109;
        L_2106, L_2109 = L_2108(L_2107, L_2106);
        if not L_2106 then
            break;
        end;
        local L_2110 = L_2109;
        if L_2110:IsA("Sky") or (L_2110:IsA("ColorCorrectionEffect") or (L_2110:IsA("BloomEffect") or (L_2110:IsA("DepthOfFieldEffect") or (L_2110:IsA("SunRaysEffect") or L_2110:IsA("Atmosphere"))))) then
            pcall(function(...)
                L_2110:Destroy();
                return ;
            end);
        end;
    end;
    return ;
end;
L_2112 = false;
L_2113 = {};
L_2114 = {};
L_2115 = nil;
L_2129 = function(...)
    if not L_2112 then
        L_2112 = true;
        local L_2116 = { "Ambient", "ClockTime", "GeographicLatitude", "Brightness", "ColorShift_Bottom", "ColorShift_Top", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows", "OutdoorAmbient", "ExposureCompensation", "FogEnd", "FogStart", "FogColor", "ShadowSoftness" };
        local L_2117 = { ipairs(L_2116) };
        local L_2118 = L_2117[1];
        local L_2119 = L_2117[2];
        local L_2120 = L_2117[3];
        while true do
            local L_2121;
            L_2120, L_2121 = L_2118(L_2119, L_2120);
            if not L_2120 then
                break;
            end;
            local L_2122 = L_2121;
            pcall(function(...)
                L_2113[L_2122] = L_2103[L_2122];
                return ;
            end);
        end;
        local L_2123 = { ipairs(L_2103:GetChildren()) };
        local L_2124 = L_2123[1];
        local L_2125 = L_2123[2];
        local L_2126 = L_2123[3];
        while true do
            local L_2127;
            L_2126, L_2127 = L_2124(L_2125, L_2126);
            if not L_2126 then
                break;
            end;
            local L_2128 = L_2127;
            if L_2128:IsA("Atmosphere") or (L_2128:IsA("Sky") or (L_2128:IsA("ColorCorrectionEffect") or (L_2128:IsA("BloomEffect") or (L_2128:IsA("DepthOfFieldEffect") or L_2128:IsA("SunRaysEffect"))))) then
                pcall(function(...)
                    table.insert(L_2114, L_2128:Clone());
                    return ;
                end);
            end;
        end;
        return ;
    end;
    return ;
end;
L_2143 = function(...)
    if L_2115 then
        pcall(function(...)
            L_2115:Disconnect();
            return ;
        end);
        L_2115 = nil;
    end;
    L_2111();
    local L_2130 = { pairs(L_2113) };
    local L_2131 = L_2130[2];
    local L_2132 = L_2130[3];
    local L_2133 = L_2130[1];
    while true do
        local L_2134;
        L_2132, L_2134 = L_2133(L_2131, L_2132);
        if not L_2132 then
            break;
        end;
        local L_2135 = L_2132;
        local L_2136 = L_2134;
        pcall(function(...)
            L_2103[L_2135] = L_2136;
            return ;
        end);
    end;
    local L_2137 = { ipairs(L_2114) };
    local L_2138 = L_2137[3];
    local L_2139 = L_2137[1];
    local L_2140 = L_2137[2];
    while true do
        local L_2141;
        L_2138, L_2141 = L_2139(L_2140, L_2138);
        if not L_2138 then
            break;
        end;
        local L_2142 = L_2141;
        pcall(function(...)
            L_2142:Clone().Parent = L_2103;
            return ;
        end);
    end;
    L_2113 = {};
    L_2114 = {};
    L_2112 = false;
    L_2104 = nil;
    return ;
end;
L_2144 = { Stars = { Ambient = Color3.fromRGB(107, 107, 107), OutdoorAmbient = Color3.fromRGB(115, 93, 137), ColorShift_Bottom = Color3.fromRGB(219, 3, 246), ColorShift_Top = Color3.fromRGB(144, 6, 177), Enviroment = 0.4, Brightness = 0.05, Exposure = 0.8, Lat = 60, Time = 10, Shadows = true }, Warm = { Ambient = Color3.fromRGB(58, 58, 58), OutdoorAmbient = Color3.fromRGB(127, 116, 79), ColorShift_Bottom = Color3.fromRGB(219, 3, 246), ColorShift_Top = Color3.fromRGB(144, 6, 177), Enviroment = 0.5, Brightness = 0.2, Exposure = 0.6, Lat = 310, Time = 13, Shadows = true }, Galaxy = { Ambient = Color3.fromRGB(101, 101, 101), OutdoorAmbient = Color3.fromRGB(131, 77, 122), ColorShift_Bottom = Color3.fromRGB(219, 3, 246), ColorShift_Top = Color3.fromRGB(144, 6, 177), Enviroment = 0.5, Brightness = 0.2, Exposure = 0.7, Lat = 0, Time = 15.25, Shadows = true }, Sunset = { Ambient = Color3.fromRGB(93, 59, 88), OutdoorAmbient = Color3.fromRGB(128, 94, 100), ColorShift_Bottom = Color3.fromRGB(213, 173, 117), ColorShift_Top = Color3.fromRGB(255, 255, 255), Enviroment = 0.5, Brightness = 0.2, Exposure = 0.8, Lat = 325, Time = 11, Shadows = true }, Morning = { Ambient = Color3.fromRGB(101, 72, 51), OutdoorAmbient = Color3.fromRGB(175, 132, 119), ColorShift_Bottom = Color3.fromRGB(213, 161, 134), ColorShift_Top = Color3.fromRGB(203, 167, 102), Enviroment = 0.3, Brightness = 1, Exposure = 0.7, Lat = 326, Time = 16.333333333333, Shadows = true }, Ocean = { Ambient = Color3.fromRGB(79, 54, 101), OutdoorAmbient = Color3.fromRGB(162, 118, 175), ColorShift_Bottom = Color3.fromRGB(213, 10, 180), ColorShift_Top = Color3.fromRGB(103, 68, 203), Enviroment = 0.4, Brightness = 0.2, Exposure = 1, Lat = 306, Time = 10, Shadows = true } };
L_2155 = function(L_2145, L_2146, L_2147, ...)
    if L_2145 and L_2144[L_2145] then
        local L_2148 = L_2144[L_2145];
        local L_2149 = Instance.new("Sky");
        local L_2150 = { pairs(L_2146) };
        local L_2151 = L_2150[2];
        local L_2152 = L_2150[3];
        local L_2153 = L_2150[1];
        while true do
            local L_2154;
            L_2152, L_2154 = L_2153(L_2151, L_2152);
            if not L_2152 then
                break;
            end;
            L_2149[L_2152] = L_2154;
        end;
        L_2149.Parent = L_2103;
        if L_2147 then
            pcall(L_2147);
        end;
        L_2103.Brightness = L_2148.Brightness;
        L_2103.ExposureCompensation = L_2148.Exposure;
        L_2103.EnvironmentDiffuseScale = L_2148.Enviroment;
        L_2103.EnvironmentSpecularScale = L_2148.Enviroment;
        L_2103.Ambient = L_2148.Ambient;
        L_2103.OutdoorAmbient = L_2148.OutdoorAmbient;
        L_2103.GeographicLatitude = L_2148.Lat;
        L_2103.ClockTime = L_2148.Time;
        if L_2115 then
            pcall(function(...)
                L_2115:Disconnect();
                return ;
            end);
            L_2115 = nil;
        end;
        L_2115 = L_2103:GetPropertyChangedSignal("ClockTime"):Connect(function(...)
            L_2103.ClockTime = L_2148.Time;
            return ;
        end);
        L_2103.GlobalShadows = L_2148.Shadows;
        L_2103.ShadowSoftness = 0.08;
        pcall(function(...)
            if sethiddenproperty then
                sethiddenproperty(L_2103, "Technology", "Future");
            end;
            return ;
        end);
        return ;
    end;
    return ;
end;
L_2224 = {
    ["Rain Shader"] = function(...)
        local L_2156 = Instance.new("Sky", L_2103);
        L_2156.SkyboxBk = "http://www.roblox.com/asset/?id=4495864450";
        L_2156.SkyboxDn = "http://www.roblox.com/asset/?id=4495864887";
        L_2156.SkyboxFt = "http://www.roblox.com/asset/?id=4495865458";
        L_2156.SkyboxLf = "http://www.roblox.com/asset/?id=4495866035";
        L_2156.SkyboxRt = "http://www.roblox.com/asset/?id=4495866584";
        L_2156.SkyboxUp = "http://www.roblox.com/asset/?id=4495867486";
        local L_2157 = Instance.new("ColorCorrectionEffect", L_2103);
        L_2157.Brightness = 0.05;
        L_2157.Contrast = 0.05;
        L_2157.TintColor = Color3.fromRGB(170, 170, 170);
        return ;
    end,
    ["Nebula Shader"] = function(...)
        local L_2158 = Instance.new("Sky", L_2103);
        L_2158.SkyboxBk = "http://www.roblox.com/asset/?id=15983968922";
        L_2158.SkyboxDn = "http://www.roblox.com/asset/?id=15983966825";
        L_2158.SkyboxFt = "http://www.roblox.com/asset/?id=15983965025";
        L_2158.SkyboxLf = "http://www.roblox.com/asset/?id=15983967420";
        L_2158.SkyboxRt = "http://www.roblox.com/asset/?id=15983966246";
        L_2158.SkyboxUp = "http://www.roblox.com/asset/?id=15983964246";
        local L_2159 = Instance.new("ColorCorrectionEffect", L_2103);
        L_2159.Brightness = 0.05;
        L_2159.Contrast = -0.02;
        L_2159.TintColor = Color3.fromRGB(105, 72, 255);
        return ;
    end,
    ["Night Shader"] = function(...)
        local L_2160 = Instance.new("Sky", L_2103);
        L_2160.SkyboxUp = "http://www.roblox.com/asset/?id=12064131";
        L_2160.SkyboxLf = "http://www.roblox.com/asset/?id=12063984";
        L_2160.SkyboxFt = "http://www.roblox.com/asset/?id=12064121";
        L_2160.SkyboxBk = "http://www.roblox.com/asset/?id=12064107";
        L_2160.SkyboxDn = "http://www.roblox.com/asset/?id=12064152";
        L_2160.SkyboxRt = "http://www.roblox.com/asset/?id=12064115";
        local L_2161 = Instance.new("ColorCorrectionEffect", L_2103);
        L_2161.Brightness = 0.07;
        L_2161.Contrast = -0.07;
        L_2161.TintColor = Color3.fromRGB(44, 70, 187);
        return ;
    end,
    ["Stars Shader"] = function(...)
        local L_2162 = Instance.new("Sky");
        L_2162.SkyboxUp = "rbxassetid://5559302033";
        L_2162.SkyboxLf = "rbxassetid://5559292825";
        L_2162.SkyboxFt = "rbxassetid://5559300879";
        L_2162.SkyboxBk = "rbxassetid://5559289158";
        L_2162.SkyboxDn = "rbxassetid://5559290893";
        L_2162.SkyboxRt = "rbxassetid://5559302989";
        L_2162.Parent = L_2103;
        local L_2163 = Instance.new("DepthOfFieldEffect", L_2103);
        L_2163.FarIntensity = 0.12;
        L_2163.NearIntensity = 0.3;
        L_2163.FocusDistance = 20;
        L_2163.InFocusRadius = 17;
        local L_2164 = Instance.new("ColorCorrectionEffect", L_2103);
        L_2164.TintColor = Color3.fromRGB(245, 200, 245);
        L_2164.Brightness = 0;
        L_2164.Contrast = 0.2;
        L_2164.Saturation = -0.1;
        local L_2165 = Instance.new("BloomEffect", L_2103);
        L_2165.Intensity = 0.4;
        L_2165.Size = 12;
        L_2165.Threshold = 0.2;
        L_2103.Brightness = L_2144.Stars.Brightness;
        L_2103.ExposureCompensation = L_2144.Stars.Exposure;
        L_2103.EnvironmentDiffuseScale = L_2144.Stars.Enviroment;
        L_2103.EnvironmentSpecularScale = L_2144.Stars.Enviroment;
        L_2103.Ambient = L_2144.Stars.Ambient;
        L_2103.OutdoorAmbient = L_2144.Stars.OutdoorAmbient;
        L_2103.GeographicLatitude = L_2144.Stars.Lat;
        L_2103.ClockTime = L_2144.Stars.Time;
        if L_2115 then
            pcall(function(...)
                L_2115:Disconnect();
                return ;
            end);
        end;
        L_2115 = L_2103:GetPropertyChangedSignal("ClockTime"):Connect(function(...)
            L_2103.ClockTime = L_2144.Stars.Time;
            return ;
        end);
        L_2103.GlobalShadows = L_2144.Stars.Shadows;
        L_2103.ShadowSoftness = 0.08;
        pcall(function(...)
            if sethiddenproperty then
                sethiddenproperty(L_2103, "Technology", "Future");
            end;
            return ;
        end);
        return ;
    end,
    ["Warm Shader"] = function(...)
        local L_2166 = Instance.new("Sky");
        L_2166.SkyboxUp = "http://www.roblox.com/asset?id=232707707";
        L_2166.SkyboxLf = "http://www.roblox.com/asset?id=232708001";
        L_2166.SkyboxFt = "http://www.roblox.com/asset?id=232707879";
        L_2166.SkyboxBk = "http://www.roblox.com/asset?id=232707959";
        L_2166.SkyboxDn = "http://www.roblox.com/asset?id=232707790";
        L_2166.SkyboxRt = "http://www.roblox.com/asset?id=232707983";
        L_2166.Parent = L_2103;
        local L_2167 = Instance.new("DepthOfFieldEffect", L_2103);
        L_2167.FarIntensity = 0.12;
        L_2167.NearIntensity = 0.3;
        L_2167.FocusDistance = 20;
        L_2167.InFocusRadius = 17;
        local L_2168 = Instance.new("BloomEffect", L_2103);
        L_2168.Intensity = 0.6;
        L_2168.Size = 12;
        L_2168.Threshold = 0.2;
        local L_2169 = Instance.new("ColorCorrectionEffect", L_2103);
        L_2169.TintColor = Color3.fromRGB(255, 255, 255);
        L_2169.Brightness = 0;
        L_2169.Contrast = 0.3;
        L_2169.Saturation = 0.2;
        local L_2170 = Instance.new("SunRaysEffect", L_2103);
        L_2170.Enabled = true;
        L_2170.Intensity = 0.003;
        L_2170.Spread = 1;
        L_2103.Brightness = L_2144.Warm.Brightness;
        L_2103.ExposureCompensation = L_2144.Warm.Exposure;
        L_2103.EnvironmentDiffuseScale = L_2144.Warm.Enviroment;
        L_2103.EnvironmentSpecularScale = L_2144.Warm.Enviroment;
        L_2103.Ambient = L_2144.Warm.Ambient;
        L_2103.OutdoorAmbient = L_2144.Warm.OutdoorAmbient;
        L_2103.GeographicLatitude = L_2144.Warm.Lat;
        L_2103.ClockTime = L_2144.Warm.Time;
        if L_2115 then
            pcall(function(...)
                L_2115:Disconnect();
                return ;
            end);
        end;
        L_2115 = L_2103:GetPropertyChangedSignal("ClockTime"):Connect(function(...)
            L_2103.ClockTime = L_2144.Warm.Time;
            return ;
        end);
        L_2103.GlobalShadows = L_2144.Warm.Shadows;
        L_2103.ShadowSoftness = 0.08;
        pcall(function(...)
            if sethiddenproperty then
                sethiddenproperty(L_2103, "Technology", "Future");
            end;
            return ;
        end);
        return ;
    end,
    ["Galaxy Shader"] = function(...)
        local L_2171 = Instance.new("Sky");
        L_2171.SkyboxUp = "rbxassetid://1903391299";
        L_2171.SkyboxLf = "rbxassetid://1903388369";
        L_2171.SkyboxFt = "rbxassetid://1903389258";
        L_2171.SkyboxBk = "rbxassetid://1903390348";
        L_2171.SkyboxDn = "rbxassetid://1903391981";
        L_2171.SkyboxRt = "rbxassetid://1903387293";
        L_2171.Parent = L_2103;
        local L_2172 = Instance.new("DepthOfFieldEffect", L_2103);
        L_2172.FarIntensity = 0.12;
        L_2172.NearIntensity = 0.3;
        L_2172.FocusDistance = 20;
        L_2172.InFocusRadius = 17;
        local L_2173 = Instance.new("BloomEffect", L_2103);
        L_2173.Intensity = 0.6;
        L_2173.Size = 12;
        L_2173.Threshold = 0.2;
        local L_2174 = Instance.new("SunRaysEffect", L_2103);
        L_2174.Enabled = true;
        L_2174.Intensity = 0.003;
        L_2174.Spread = 1;
        local L_2175 = Instance.new("ColorCorrectionEffect", L_2103);
        L_2175.TintColor = Color3.fromRGB(245, 240, 255);
        L_2175.Brightness = -0.04;
        L_2175.Contrast = 0.2;
        L_2175.Saturation = 0.2;
        L_2103.Brightness = L_2144.Galaxy.Brightness;
        L_2103.ExposureCompensation = L_2144.Galaxy.Exposure;
        L_2103.EnvironmentDiffuseScale = L_2144.Galaxy.Enviroment;
        L_2103.EnvironmentSpecularScale = L_2144.Galaxy.Enviroment;
        L_2103.Ambient = L_2144.Galaxy.Ambient;
        L_2103.OutdoorAmbient = L_2144.Galaxy.OutdoorAmbient;
        L_2103.GeographicLatitude = L_2144.Galaxy.Lat;
        L_2103.ClockTime = L_2144.Galaxy.Time;
        if L_2115 then
            pcall(function(...)
                L_2115:Disconnect();
                return ;
            end);
        end;
        L_2115 = L_2103:GetPropertyChangedSignal("ClockTime"):Connect(function(...)
            L_2103.ClockTime = L_2144.Galaxy.Time;
            return ;
        end);
        L_2103.GlobalShadows = L_2144.Galaxy.Shadows;
        L_2103.ShadowSoftness = 0.08;
        pcall(function(...)
            if sethiddenproperty then
                sethiddenproperty(L_2103, "Technology", "Future");
            end;
            return ;
        end);
        return ;
    end,
    ["Sunset Shader"] = function(...)
        local L_2176 = Instance.new("Sky");
        L_2176.SkyboxUp = "rbxassetid://2670644331";
        L_2176.SkyboxLf = "rbxassetid://2670643070";
        L_2176.SkyboxFt = "rbxassetid://2670643214";
        L_2176.SkyboxBk = "rbxassetid://2670643994";
        L_2176.SkyboxDn = "rbxassetid://2670643365";
        L_2176.SkyboxRt = "rbxassetid://2670644173";
        L_2176.Parent = L_2103;
        local L_2177 = Instance.new("ColorCorrectionEffect", L_2103);
        L_2177.Enabled = true;
        L_2177.Brightness = 0.13;
        L_2177.Contrast = 0.4;
        L_2177.Saturation = 0.06;
        L_2177.TintColor = Color3.fromRGB(255, 230, 245);
        local L_2178 = Instance.new("DepthOfFieldEffect", L_2103);
        L_2178.FarIntensity = 0.12;
        L_2178.NearIntensity = 0.3;
        L_2178.FocusDistance = 20;
        L_2178.InFocusRadius = 17;
        local L_2179 = Instance.new("BloomEffect", L_2103);
        L_2179.Intensity = 0.4;
        L_2179.Size = 12;
        L_2179.Threshold = 0.2;
        L_2103.Brightness = L_2144.Sunset.Brightness;
        L_2103.ExposureCompensation = L_2144.Sunset.Exposure;
        L_2103.EnvironmentDiffuseScale = L_2144.Sunset.Enviroment;
        L_2103.EnvironmentSpecularScale = L_2144.Sunset.Enviroment;
        L_2103.Ambient = L_2144.Sunset.Ambient;
        L_2103.OutdoorAmbient = L_2144.Sunset.OutdoorAmbient;
        L_2103.GeographicLatitude = L_2144.Sunset.Lat;
        L_2103.ClockTime = L_2144.Sunset.Time;
        if L_2115 then
            pcall(function(...)
                L_2115:Disconnect();
                return ;
            end);
        end;
        L_2115 = L_2103:GetPropertyChangedSignal("ClockTime"):Connect(function(...)
            L_2103.ClockTime = L_2144.Sunset.Time;
            return ;
        end);
        L_2103.GlobalShadows = L_2144.Sunset.Shadows;
        L_2103.ShadowSoftness = 0.08;
        pcall(function(...)
            if sethiddenproperty then
                sethiddenproperty(L_2103, "Technology", "Future");
            end;
            return ;
        end);
        return ;
    end,
    ["Morning Shader"] = function(...)
        local L_2180 = Instance.new("Sky");
        L_2180.SkyboxUp = "http://www.roblox.com/asset/?id=458016792";
        L_2180.SkyboxLf = "http://www.roblox.com/asset/?id=458016655";
        L_2180.SkyboxFt = "http://www.roblox.com/asset/?id=458016532";
        L_2180.SkyboxBk = "http://www.roblox.com/asset/?id=458016711";
        L_2180.SkyboxDn = "http://www.roblox.com/asset/?id=458016826";
        L_2180.SkyboxRt = "http://www.roblox.com/asset/?id=458016782";
        L_2180.Parent = L_2103;
        local L_2181 = Instance.new("BloomEffect", L_2103);
        L_2181.Enabled = true;
        L_2181.Threshold = 0.24;
        L_2181.Size = 8;
        L_2181.Intensity = 0.5;
        local L_2182 = Instance.new("SunRaysEffect", L_2103);
        L_2182.Enabled = true;
        L_2182.Intensity = 0.05;
        L_2182.Spread = 0.4;
        local L_2183 = Instance.new("ColorCorrectionEffect", L_2103);
        L_2183.Saturation = 0.14;
        L_2183.Brightness = -0.1;
        L_2183.Contrast = 0.14;
        local L_2184 = Instance.new("DepthOfFieldEffect", L_2103);
        L_2184.FarIntensity = 0.2;
        L_2184.InFocusRadius = 17;
        L_2184.FocusDistance = 20;
        L_2184.NearIntensity = 0.3;
        L_2103.Brightness = L_2144.Morning.Brightness;
        L_2103.ExposureCompensation = L_2144.Morning.Exposure;
        L_2103.EnvironmentDiffuseScale = L_2144.Morning.Enviroment;
        L_2103.EnvironmentSpecularScale = L_2144.Morning.Enviroment;
        L_2103.Ambient = L_2144.Morning.Ambient;
        L_2103.OutdoorAmbient = L_2144.Morning.OutdoorAmbient;
        L_2103.GeographicLatitude = L_2144.Morning.Lat;
        L_2103.ClockTime = L_2144.Morning.Time;
        if L_2115 then
            pcall(function(...)
                L_2115:Disconnect();
                return ;
            end);
        end;
        L_2115 = L_2103:GetPropertyChangedSignal("ClockTime"):Connect(function(...)
            L_2103.ClockTime = L_2144.Morning.Time;
            return ;
        end);
        L_2103.GlobalShadows = L_2144.Morning.Shadows;
        L_2103.ShadowSoftness = 0.08;
        pcall(function(...)
            if sethiddenproperty then
                sethiddenproperty(L_2103, "Technology", "Future");
            end;
            return ;
        end);
        return ;
    end,
    ["Ocean Shader"] = function(...)
        local L_2185 = Instance.new("Sky");
        L_2185.SkyboxUp = "http://www.roblox.com/asset/?id=5260824661";
        L_2185.SkyboxLf = "http://www.roblox.com/asset/?id=5260800833";
        L_2185.SkyboxFt = "http://www.roblox.com/asset/?id=5260817288";
        L_2185.SkyboxBk = "http://www.roblox.com/asset/?id=5260808177";
        L_2185.SkyboxDn = "http://www.roblox.com/asset/?id=5260653793";
        L_2185.SkyboxRt = "http://www.roblox.com/asset/?id=5260811073";
        L_2185.Parent = L_2103;
        local L_2186 = Instance.new("BloomEffect", L_2103);
        L_2186.Enabled = true;
        L_2186.Threshold = 0.4;
        L_2186.Size = 12;
        L_2186.Intensity = 0.5;
        local L_2187 = Instance.new("ColorCorrectionEffect", L_2103);
        L_2187.Brightness = -0.03;
        L_2187.Contrast = 0.16;
        L_2187.Saturation = 0.06;
        L_2187.TintColor = Color3.fromRGB(220, 175, 255);
        local L_2188 = Instance.new("DepthOfFieldEffect", L_2103);
        L_2188.FarIntensity = 0.12;
        L_2188.InFocusRadius = 17;
        L_2188.FocusDistance = 20;
        L_2188.NearIntensity = 0.3;
        L_2103.Brightness = L_2144.Ocean.Brightness;
        L_2103.ExposureCompensation = L_2144.Ocean.Exposure;
        L_2103.EnvironmentDiffuseScale = L_2144.Ocean.Enviroment;
        L_2103.EnvironmentSpecularScale = L_2144.Ocean.Enviroment;
        L_2103.Ambient = L_2144.Ocean.Ambient;
        L_2103.OutdoorAmbient = L_2144.Ocean.OutdoorAmbient;
        L_2103.GeographicLatitude = L_2144.Ocean.Lat;
        L_2103.ClockTime = L_2144.Ocean.Time;
        if L_2115 then
            pcall(function(...)
                L_2115:Disconnect();
                return ;
            end);
        end;
        L_2115 = L_2103:GetPropertyChangedSignal("ClockTime"):Connect(function(...)
            L_2103.ClockTime = L_2144.Ocean.Time;
            return ;
        end);
        L_2103.GlobalShadows = L_2144.Ocean.Shadows;
        L_2103.ShadowSoftness = 0.08;
        pcall(function(...)
            if sethiddenproperty then
                sethiddenproperty(L_2103, "Technology", "Future");
            end;
            return ;
        end);
        return ;
    end,
    ["Dark Shader"] = function(...)
        local L_2189 = Instance.new("ColorCorrectionEffect", L_2103);
        L_2189.Brightness = 0;
        L_2189.Contrast = 0;
        L_2189.Saturation = -0.3;
        L_2189.TintColor = Color3.fromRGB(255, 255, 255);
        L_2189.Enabled = true;
        local L_2190 = Instance.new("Atmosphere", L_2103);
        L_2190.Density = 0.296;
        L_2190.Offset = 0;
        L_2190.Color = Color3.fromRGB(199, 170, 107);
        L_2190.Decay = Color3.fromRGB(92, 60, 13);
        L_2190.Glare = 0;
        L_2190.Haze = 0;
        local L_2191 = Instance.new("Sky", L_2103);
        L_2191.SkyboxBk = "http://www.roblox.com/asset/?id=245972325";
        L_2191.SkyboxDn = "http://www.roblox.com/asset/?id=245972441";
        L_2191.SkyboxFt = "http://www.roblox.com/asset/?id=245972389";
        L_2191.SkyboxLf = "http://www.roblox.com/asset/?id=245972361";
        L_2191.SkyboxRt = "http://www.roblox.com/asset/?id=245972302";
        L_2191.SkyboxUp = "http://www.roblox.com/asset/?id=245972410";
        local L_2192 = "Ambient";
        local L_2193 = Color3.fromRGB(44, 33, 19);
        local L_2194 = "ClockTime";
        local L_2195 = "GeographicLatitude";
        local L_2196 = "Brightness";
        local L_2197 = "ColorShift_Bottom";
        local L_2198 = Color3.fromRGB(0, 0, 0);
        local L_2199 = "ColorShift_Top";
        local L_2200 = Color3.fromRGB(0, 0, 0);
        local L_2201 = "EnvironmentDiffuseScale";
        local L_2202 = "EnvironmentSpecularScale";
        local L_2203 = "GlobalShadows";
        local L_2204 = "OutdoorAmbient";
        local L_2205 = Color3.fromRGB(115, 115, 115);
        local L_2206 = "ExposureCompensation";
        local L_2207 = "FogEnd";
        local L_2208 = "FogStart";
        local L_2209 = "FogColor";
        local L_2210 = Color3.fromRGB(93, 93, 93);
        local L_2211 = { [L_2192] = L_2193, [L_2194] = 7.3, [L_2195] = 41.7333, [L_2196] = 1.1, [L_2197] = L_2198, [L_2199] = L_2200, [L_2201] = 0.1, [L_2202] = 0, [L_2203] = true, [L_2204] = L_2205, [L_2206] = -0.8, [L_2207] = 600, [L_2208] = 20, [L_2209] = L_2210 };
        local L_2212 = { pairs(L_2211) };
        local L_2213 = L_2212[1];
        local L_2214 = L_2212[2];
        local L_2215 = L_2212[3];
        while true do
            local L_2216;
            L_2215, L_2216 = L_2213(L_2214, L_2215);
            if not L_2215 then
                break;
            end;
            local L_2217 = L_2215;
            local L_2218 = L_2216;
            pcall(function(...)
                L_2103[L_2217] = L_2218;
                return ;
            end);
        end;
        return ;
    end,
    ["Realistic Shader"] = function(...)
        local L_2221 = {
            pcall(function(...)
                local L_2219 = game:HttpGet("https://raw.githubusercontent.com/warprbx/NightRewrite/refs/heads/main/Night/Games/Shader.lua");
                if L_2219 then
                    local L_2220 = loadstring(L_2219);
                    if L_2220 then
                        L_2220();
                    end;
                end;
                return ;
            end)
        };
        local L_2222 = L_2221[1];
        local L_2223 = L_2221[2];
        if not L_2222 then
            warn("", L_2223);
        end;
        return ;
    end
};
L_2225 = "None";
L_2226 = "Rain Shader";
L_2227 = "Nebula Shader";
L_2228 = "Night Shader";
L_2229 = "Stars Shader";
L_2230 = "Warm Shader";
L_2231 = "Galaxy Shader";
L_2232 = "Sunset Shader";
L_2233 = "Morning Shader";
L_2234 = "Ocean Shader";
L_2235 = "Dark Shader";
L_2236 = "Realistic Shader";
L_138.Utilities:Dropdown({
    Title = "Shader Hub",
    Values = { L_2225, L_2226, L_2227, L_2228, L_2229, L_2230, L_2231, L_2232, L_2233, L_2234, L_2235, L_2236 },
    Value = "None",
    Callback = function(L_2237, ...)
        if L_2104 and L_2104 ~= "None" then
            L_2143();
        end;
        if L_2237 ~= "None" then
            if L_2224[L_2237] then
                L_2129();
                L_2111();
                pcall(L_2224[L_2237]);
                L_2104 = L_2237;
                L_82:Notify({ Title = "Shader Applied", Content = L_2237, Duration = 2 });
            end;
        else
            L_2104 = nil;
            L_82:Notify({ Title = "Shader Disabled", Content = "Original lighting restored.", Duration = 2 });
        end;
        return ;
    end
});
L_138.Utilities:Colorpicker({
    Title = "VFX Color",
    Desc = "Pick a custom VFX color",
    Default = L_463(L_110.vfxColorChanger) or Color3.fromRGB(255, 255, 255),
    Transparency = 0,
    Locked = false,
    Callback = function(L_2238, ...)
        local L_2239 = type(L_2238) == "table" and L_2238.Color or L_2238;
        L_110.vfxColorChanger = L_2239;
        L_482();
        return ;
    end
});
L_2240 = {};
L_2241 = { pairs(L_460) };
L_2242 = L_2241[3];
L_2243 = L_2241[2];
L_2244 = L_2241[1];
while true do
    local L_2245;
    L_2242, L_2245 = L_2244(L_2243, L_2242);
    if not L_2242 then
        break;
    end;
    table.insert(L_2240, L_2242);
end;
table.sort(L_2240);
L_138.Utilities:Dropdown({
    Title = "Teleport",
    Values = { "None", "Saitama Death Counter", "Atomic", "Sky", "Corner", "Left Mountain", "Right Mountain", "Middle Mountain", "Middle of Map", "Base Plate" },
    Value = "None",
    Callback = function(L_2246, ...)
        L_1687(L_139[L_2246]);
        return ;
    end
});
L_138.Utilities:Divider();
L_2247 = L_138.Utilities:Section({ Title = "Avatar Changer", Desc = "Change your avatar to someone else using username / id", Image = "user", Opened = true, ImageSize = 20, Color = Color3.fromHex("#a29bfe") });
AvatarChangerSection = L_2247;
AvatarChangerSection:Input({
    Title = "User ID",
    Value = L_110.avatarChangerUserId,
    Placeholder = "Enter UserId or Username",
    Callback = function(L_2248, ...)
        L_110.avatarChangerUserId = tostring(L_2248);
        return ;
    end
});
AvatarChangerSection:Button({
    Title = "Force Avatar Change",
    Icon = "refresh-cw",
    Callback = function(...)
        L_1975();
        return ;
    end
});
AvatarChangerSection:Button({
    Title = "Headless Korblox",
    Icon = "user-x",
    Callback = function(...)
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Headless-Korblox-47269"))();
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "Counter ESP",
    Value = L_110.sigmaESP,
    Callback = function(L_2249, ...)
        SigmaToggle(L_2249);
        local L_2250 = L_82;
        local L_2251 = "Title";
        local L_2252 = "Counter ESP";
        local L_2253 = "Content";
        if L_2249 then
            L_2249 = "Enabled";
        end;
        if not L_2249 then
            L_2249 = "Disabled";
        end;
        L_2250:Notify({ [L_2251] = L_2252, [L_2253] = L_2249, Duration = 2 });
        return ;
    end
});
L_138.Utilities:Colorpicker({
    Title = "Highlight Color",
    Desc = "Color for Counter esp",
    Default = L_110.sigmaColor,
    Transparency = 0,
    Locked = false,
    Callback = function(L_2254, ...)
        local L_2255 = type(L_2254) == "table" and L_2254.Color or L_2254;
        L_110.sigmaColor = L_2255;
        L_82:Notify({ Title = "Counter ESP", Content = "Color updated", Duration = 1 });
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "Block Indicator",
    Value = L_110.arrowIndicator,
    Callback = function(L_2256, ...)
        L_110.arrowIndicator = L_2256;
        L_1089();
        local L_2257 = L_82;
        local L_2258 = "Title";
        local L_2259 = "Arrow Indicator";
        local L_2260 = "Content";
        if L_2256 then
            L_2256 = "Enabled";
        end;
        if not L_2256 then
            L_2256 = "Disabled";
        end;
        L_2257:Notify({ [L_2258] = L_2259, [L_2260] = L_2256, Duration = 2 });
        return ;
    end
});
L_138.Utilities:Divider();
L_138.Utilities:Toggle({
    Title = "DashClip Enabled",
    Desc = "Noclip when dashing",
    Value = L_110.dashclipEnabled,
    Callback = function(L_2261, ...)
        L_110.dashclipEnabled = L_2261;
        if not L_2261 then
            dashclipDisableNoclip();
            L_82:Notify({ Title = "DashClip", Content = "Disabled", Icon = "lucide:x", Duration = 2 });
        else
            L_110.dashclipUnloaded = false;
            dashclipSetupFeature();
            L_82:Notify({ Title = "DashClip", Content = "Enabled", Icon = "lucide:check", Duration = 2 });
        end;
        return ;
    end
});
L_138.Utilities:Slider({
    Title = "Noclip Duration",
    Value = { Min = 100, Max = 2000, Default = L_107.dashclipEnableDuration * 1000 },
    Callback = function(L_2262, ...)
        L_107.dashclipEnableDuration = L_2262 / 1000;
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "No Clip Players",
    Value = L_110.noClip,
    Callback = function(L_2263, ...)
        L_110.noClip = L_2263;
        if not L_2263 then
            if L_111.noClip then
                L_111.noClip:Disconnect();
                L_111.noClip = nil;
            end;
        else
            L_903();
        end;
        return ;
    end
});
L_138.Utilities:Divider();
L_138.Utilities:Toggle({
    Title = "ESP Name",
    Value = L_110.espName,
    Callback = function(L_2264, ...)
        L_110.espName = L_2264;
        L_667();
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "Highlight Players",
    Value = L_110.espHighlight,
    Callback = function(L_2265, ...)
        L_110.espHighlight = L_2265;
        L_667();
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "Torso esp",
    Value = L_110.espHRPBox,
    Callback = function(L_2266, ...)
        L_110.espHRPBox = L_2266;
        L_667();
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "Player Counts",
    Value = L_110.espPlayerCount,
    Callback = function(L_2267, ...)
        L_110.espPlayerCount = L_2267;
        L_667();
        return ;
    end
});
L_138.Utilities:Divider();
L_138.Utilities:Toggle({
    Title = "M2 Block",
    Value = L_110.m2Block,
    Callback = function(L_2268, ...)
        L_110.m2Block = L_2268;
        if not L_2268 then
            if L_111.m2Block then
                L_111.m2Block:Disconnect();
                L_111.m2Block = nil;
            end;
            if L_111.m2BlockEnd then
                L_111.m2BlockEnd:Disconnect();
                L_111.m2BlockEnd = nil;
            end;
        else
            L_1029();
        end;
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "M1 Block (Compatible with M2 Block)",
    Value = L_110.m1Block,
    Callback = function(L_2269, ...)
        L_110.m1Block = L_2269;
        L_1035();
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "M1 Slide",
    Value = L_110.slideM1,
    Callback = function(L_2270, ...)
        L_110.slideM1 = L_2270;
        if not L_2270 then
            if slideM1AnimConnection then
                slideM1AnimConnection:Disconnect();
                slideM1AnimConnection = nil;
            end;
            if slideM1CharConnection then
                slideM1CharConnection:Disconnect();
                slideM1CharConnection = nil;
            end;
            slideM1ToggleState = false;
        else
            setupSlideM1();
        end;
        return ;
    end
});
L_138.Utilities:Divider();
L_138.Utilities:Slider({
    Title = "StretchScreen",
    Value = { Min = 1, Max = 100, Default = L_110.stretchScreenValue },
    Callback = function(L_2271, ...)
        L_110.stretchScreenValue = L_2271;
        L_1311();
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "True Down Slam",
    Value = L_110.downSlam,
    Callback = function(L_2272, ...)
        L_110.downSlam = L_2272;
        if not L_2272 then
            if L_111.downSlam then
                L_111.downSlam:Disconnect();
                L_111.downSlam = nil;
            end;
        else
            L_1056();
        end;
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "Respawn at Death",
    Value = L_110.respawnAtDeath,
    Callback = function(L_2273, ...)
        L_110.respawnAtDeath = L_2273;
        if not L_2273 then
            if L_111.respawnAtDeath then
                L_111.respawnAtDeath:Disconnect();
                L_111.respawnAtDeath = nil;
            end;
            if L_111.diedConn then
                L_111.diedConn:Disconnect();
                L_111.diedConn = nil;
            end;
        else
            L_1320();
        end;
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "FPS Boost",
    Value = L_110.fpsBoost,
    Callback = function(L_2274, ...)
        L_110.fpsBoost = L_2274;
        if not L_2274 then
            L_82:Notify({ Title = "FPS Boost", Content = "FPS Boost disabled", Duration = 3 });
        else
            L_1422();
            L_82:Notify({ Title = "FPS Boost", Content = "FPS Boost enabled", Duration = 3 });
        end;
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "Auto Jump(cuz why not)",
    Value = L_110.autoJump,
    Callback = function(L_2275, ...)
        L_110.autoJump = L_2275;
        L_1802(L_2275);
        local L_2276 = L_82;
        local L_2277 = "Title";
        local L_2278 = "Auto Jump";
        local L_2279 = "Content";
        if L_2275 then
            L_2275 = "Enabled";
        end;
        if not L_2275 then
            L_2275 = "Disabled";
        end;
        L_2276:Notify({ [L_2277] = L_2278, [L_2279] = L_2275, Duration = 2 });
        return ;
    end
});
L_138.Utilities:Divider();
L_138.Utilities:Toggle({
    Title = "No Stun",
    Value = L_110.noStun,
    Callback = function(L_2280, ...)
        L_110.noStun = L_2280;
        L_1942(L_2280);
        local L_2281 = L_82;
        local L_2282 = "Title";
        local L_2283 = "No Stun";
        local L_2284 = "Content";
        if L_2280 then
            L_2280 = "Enabled";
        end;
        if not L_2280 then
            L_2280 = "Disabled";
        end;
        L_2281:Notify({ [L_2282] = L_2283, [L_2284] = L_2280, Duration = 2 });
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "No Slow",
    Image = "bird",
    Value = L_110.noSlow,
    Callback = function(L_2285, ...)
        L_110.noSlow = L_2285;
        L_1946(L_2285);
        local L_2286 = L_82;
        local L_2287 = "Title";
        local L_2288 = "No Slow";
        local L_2289 = "Content";
        if L_2285 then
            L_2285 = "Enabled";
        end;
        if not L_2285 then
            L_2285 = "Disabled";
        end;
        L_2286:Notify({ [L_2287] = L_2288, [L_2289] = L_2285, Duration = 2 });
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "No Dash Cooldown",
    Icon = "zap",
    Image = "help-circle",
    Value = L_110.noDashCooldown,
    Callback = function(L_2290, ...)
        L_110.noDashCooldown = L_2290;
        local L_2291 = L_82;
        local L_2292 = "Title";
        local L_2293 = "No Dash Cooldown";
        local L_2294 = "Content";
        if L_2290 then
            L_2290 = "Enabled";
        end;
        if not L_2290 then
            L_2290 = "Disabled";
        end;
        L_2291:Notify({ [L_2292] = L_2293, [L_2294] = L_2290, Duration = 2 });
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "No Fatigue",
    Value = L_110.noFatigue,
    Callback = function(L_2295, ...)
        L_110.noFatigue = L_2295;
        local L_2296 = L_82;
        local L_2297 = "Title";
        local L_2298 = "No Fatigue";
        local L_2299 = "Content";
        if L_2295 then
            L_2295 = "Enabled";
        end;
        if not L_2295 then
            L_2295 = "Disabled";
        end;
        L_2296:Notify({ [L_2297] = L_2298, [L_2299] = L_2295, Duration = 2 });
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "Emotes Extra Slots",
    Value = L_110.emotesExtraSlots,
    Callback = function(L_2300, ...)
        L_110.emotesExtraSlots = L_2300;
        local L_2301 = L_82;
        local L_2302 = "Title";
        local L_2303 = "Emotes Extra Slots";
        local L_2304 = "Content";
        if L_2300 then
            L_2300 = "Enabled";
        end;
        if not L_2300 then
            L_2300 = "Disabled";
        end;
        L_2301:Notify({ [L_2302] = L_2303, [L_2304] = L_2300, Duration = 2 });
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "Emotes Search Bar",
    Value = L_110.emotesSearchBar,
    Callback = function(L_2305, ...)
        L_110.emotesSearchBar = L_2305;
        local L_2306 = L_82;
        local L_2307 = "Title";
        local L_2308 = "Emotes Search Bar";
        local L_2309 = "Content";
        if L_2305 then
            L_2305 = "Enabled";
        end;
        if not L_2305 then
            L_2305 = "Disabled";
        end;
        L_2306:Notify({ [L_2307] = L_2308, [L_2309] = L_2305, Duration = 2 });
        return ;
    end
});
L_138.Utilities:Divider();
L_138.Utilities:Toggle({
    Title = "Speed Boost",
    Value = L_110.speedBoost,
    Callback = function(L_2310, ...)
        L_110.speedBoost = L_2310;
        local L_2311 = L_82;
        local L_2312 = "Title";
        local L_2313 = "Speed Boost";
        local L_2314 = "Content";
        if L_2310 then
            L_2310 = "Enabled";
        end;
        if not L_2310 then
            L_2310 = "Disabled";
        end;
        L_2311:Notify({ [L_2312] = L_2313, [L_2314] = L_2310, Duration = 2 });
        return ;
    end
});
L_138.Utilities:Slider({
    Title = "Speed Value",
    Value = { Min = 0, Max = 5, Default = L_110.speedValue },
    Callback = function(L_2315, ...)
        L_110.speedValue = L_2315;
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "Jump Boost",
    Value = L_110.jumpBoost,
    Callback = function(L_2316, ...)
        L_110.jumpBoost = L_2316;
        local L_2317 = L_82;
        local L_2318 = "Title";
        local L_2319 = "Jump Boost";
        local L_2320 = "Content";
        if L_2316 then
            L_2316 = "Enabled";
        end;
        if not L_2316 then
            L_2316 = "Disabled";
        end;
        L_2317:Notify({ [L_2318] = L_2319, [L_2320] = L_2316, Duration = 2 });
        return ;
    end
});
L_138.Utilities:Slider({
    Title = "Jump Height",
    Value = { Min = 7.2, Max = 500, Default = L_110.jumpValue },
    Callback = function(L_2321, ...)
        L_110.jumpValue = L_2321;
        return ;
    end
});
L_138.Utilities:Slider({
    Title = "Gravity",
    Value = { Min = 0, Max = 192.6, Default = L_110.gravityValue },
    Callback = function(L_2322, ...)
        L_110.gravityValue = L_2322;
        return ;
    end
});
L_138.Utilities:Slider({
    Title = "FOV",
    Value = { Min = 0, Max = 120, Default = L_110.fovValue },
    Callback = function(L_2323, ...)
        L_110.fovValue = L_2323;
        return ;
    end
});
L_138.Utilities:Divider();
L_138.Utilities:Toggle({
    Title = "Counter Toxic",
    Value = L_110.counterToxic,
    Callback = function(L_2324, ...)
        L_110.counterToxic = L_2324;
        if not L_2324 then
            _G.E = false;
            L_82:Notify({ Title = "Counter Toxic", Content = "Counter Toxic disabled", Duration = 3 });
        else
            setupCounterToxic();
            L_82:Notify({ Title = "Counter Toxic", Content = "Counter Toxic enabled", Duration = 3 });
        end;
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "Show Character",
    Value = L_110.showCharacter,
    Callback = function(L_2325, ...)
        L_110.showCharacter = L_2325;
        if not L_2325 then
            _G.a = false;
            local L_2326 = { ipairs(game:GetService("Players"):GetPlayers()) };
            local L_2327 = L_2326[1];
            local L_2328 = L_2326[2];
            local L_2329 = L_2326[3];
            while true do
                local L_2330;
                L_2329, L_2330 = L_2327(L_2328, L_2329);
                if not L_2329 then
                    break;
                end;
                if L_2330.Character and L_2330.Character:FindFirstChild("Head") then
                    local L_2331 = L_2330.Character.Head:FindFirstChild("b");
                    if L_2331 then
                        L_2331:Destroy();
                    end;
                end;
            end;
            L_82:Notify({ Title = "Show Character", Content = "Show Character disabled", Duration = 3 });
        else
            L_1633();
            L_82:Notify({ Title = "Show Character", Content = "Show Character enabled", Duration = 3 });
        end;
        return ;
    end
});
L_138.Utilities:Toggle({
    Title = "Dash Timer",
    Value = L_110.dashTimer,
    Callback = function(L_2332, ...)
        L_110.dashTimer = L_2332;
        if not L_2332 then
            if L_111.dashTimer then
                L_111.dashTimer:Disconnect();
                L_111.dashTimer = nil;
            end;
            L_82:Notify({ Title = "Dash Timer", Content = "Dash Timer disabled", Duration = 3 });
        else
            L_1684();
            L_82:Notify({ Title = "Dash Timer", Content = "Dash Timer enabled", Duration = 3 });
        end;
        return ;
    end
});
L_138.Settings:Paragraph({ Title = "Zero Hub", Desc = "Credits: zero / 74q4 | discord.gg/zerohub", Image = "heart", ImageSize = 20, Color = Color3.fromHex("#ff6b6b") });
L_138.Settings:Paragraph({ Title = "Customize Interface", Desc = "Personalize your experience", Image = "palette", ImageSize = 20, Color = "White" });
L_138.Settings:Keybind({
    Title = "Keybind",
    Desc = "Keybind to open ui",
    Value = "K",
    Callback = function(L_2333, ...)
        Window:SetToggleKey(Enum.KeyCode[L_2333]);
        return ;
    end
});
themes = {};
L_2334 = { pairs(L_82:GetThemes()) };
L_2335 = L_2334[1];
L_2336 = L_2334[3];
L_2337 = L_2334[2];
while true do
    local L_2338;
    L_2336, L_2338 = L_2335(L_2337, L_2336);
    if not L_2336 then
        break;
    end;
    themes[#themes + 1] = L_2336;
end;
table.sort(themes);
canchangetheme = true;
canchangedropdown = true;
L_2340 = L_138.Settings:Dropdown({
    Title = "Select Theme",
    Values = themes,
    SearchBarEnabled = true,
    MenuWidth = 280,
    Value = L_82:GetCurrentTheme() or "Zero Purple",
    Callback = function(L_2339, ...)
        canchangedropdown = false;
        L_82:SetTheme(L_2339);
        L_82:Notify({ Title = "Theme Applied", Content = L_2339, Icon = "palette", Duration = 2 });
        canchangedropdown = true;
        return ;
    end
});
themeDropdown = L_2340;
L_82:OnThemeChange(function(L_2341, ...)
    canchangetheme = false;
    ThemeToggle:Set(L_2341 == "Dark");
    canchangetheme = true;
    return ;
end);
L_2342 = { Default = "rbxassetid://12187377325", ["Gotham Black"] = "rbxassetid://12187867864" };
Fonts = L_2342;
FontNames = {};
L_2343 = { pairs(Fonts) };
L_2344 = L_2343[2];
L_2345 = L_2343[1];
L_2346 = L_2343[3];
while true do
    local L_2347;
    L_2346, L_2347 = L_2345(L_2344, L_2346);
    if not L_2346 then
        break;
    end;
    FontNames[#FontNames + 1] = L_2346;
end;
table.sort(FontNames);
L_2348 = "Default";
DefaultFontName = L_2348;
L_2349 = { pairs(Fonts) };
L_2350 = L_2349[3];
L_2351 = L_2349[2];
L_2352 = L_2349[1];
repeat
    local L_2353;
    L_2350, L_2353 = L_2352(L_2351, L_2350);
    if not L_2350 then
        L_0 = true;
    end;
    if L_0 then
        break;
    end;
until Fonts[L_2350] == "rbxassetid://12187377325";
if not L_0 then
    DefaultFontName = L_2350;
end;
L_0 = false;
pcall(function(...)
    L_82:SetFont(Fonts[DefaultFontName]);
    return ;
end);
if L_86.TouchEnabled then
    Window:SetSize(UDim2.fromOffset(500, 400));
    local L_2354 = {
        Name = "M1 Reset",
        Callback = function(...)
            L_110.m1Reset = not L_110.m1Reset;
            return ;
        end
    };
    local L_2355 = {
        Name = "Supa Tech",
        Callback = function(...)
            L_110.supa = not L_110.supa;
            return ;
        end
    };
    local L_2356 = {
        Name = "Loop Dash",
        Callback = function(...)
            L_110.loop = not L_110.loop;
            return ;
        end
    };
    local L_2357 = { ipairs({ L_2354, L_2355, L_2356 }) };
    local L_2358 = L_2357[3];
    local L_2359 = L_2357[1];
    local L_2360 = L_2357[2];
    while true do
        local L_2361;
        L_2358, L_2361 = L_2359(L_2360, L_2358);
        if not L_2358 then
            break;
        end;
        L_138.Settings:Button({ Title = L_2361.Name, Callback = L_2361.Callback });
    end;
    L_138.Settings:Paragraph({ Title = "Mobile Mode", Desc = "Optimized for touch screens", Image = "smartphone", ImageSize = 20, Color = Color3.fromHex("#f9ca24") });
end;
if math.random(1, 900) == 1 then
    local L_2362 = nil;
    local L_2363;
    L_2363 = function(...)
        if L_2362 then
            L_2362:Destroy();
        end;
        L_2362 = Instance.new("Part");
        L_2362.Size = Vector3.new(10, 10, 0.1);
        L_2362.Position = Vector3.new(152.889038 + math.cos(math.random() * math.pi * 2) * math.random() * 150, 443.754395, 26.8562851 + math.sin(math.random() * math.pi * 2) * math.random() * 150);
        L_2362.Anchored = true;
        L_2362.CanCollide = false;
        L_2362.Transparency = 1;
        local L_2364 = Instance.new("BillboardGui");
        L_2364.Size = UDim2.new(10, 0, 10, 0);
        L_2364.AlwaysOnTop = true;
        L_2364.Parent = L_2362;
        local L_2365 = Instance.new("ImageLabel");
        L_2365.Size = UDim2.new(1, 0, 1, 0);
        L_2365.BackgroundTransparency = 1;
        L_2365.Image = "rbxassetid://102608555927384";
        L_2365.Parent = L_2364;
        L_2362.Touched:Connect(function(L_2366, ...)
            if L_2366.Parent:FindFirstChild("Humanoid") then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/ArchIsDead/Arch-Vault/refs/heads/main/GrowAGarden_dupe_op.txt"))();
                L_2363();
            end;
            return ;
        end);
        L_2362.Parent = game:GetService("Workspace");
        return ;
    end;
    L_2363();
    L_82:Notify({ Title = "CuteCat", Content = "It's watching... YOU!", Duration = 5 });
end;
game:GetService("Players").LocalPlayer.Chatted:Connect(function(L_2367, ...)
    if L_2367 == "CuteCat" then
        local L_2368 = nil;
        local L_2369;
        L_2369 = function(...)
            if L_2368 then
                L_2368:Destroy();
            end;
            L_2368 = Instance.new("Part");
            L_2368.Size = Vector3.new(10, 10, 0.1);
            L_2368.Position = Vector3.new(152.889038 + math.cos(math.random() * math.pi * 2) * math.random() * 150, 443.754395, 26.8562851 + math.sin(math.random() * math.pi * 2) * math.random() * 150);
            L_2368.Anchored = true;
            L_2368.CanCollide = false;
            L_2368.Transparency = 1;
            local L_2370 = Instance.new("BillboardGui");
            L_2370.Size = UDim2.new(10, 0, 10, 0);
            L_2370.AlwaysOnTop = true;
            L_2370.Parent = L_2368;
            local L_2371 = Instance.new("ImageLabel");
            L_2371.Size = UDim2.new(1, 0, 1, 0);
            L_2371.BackgroundTransparency = 1;
            L_2371.Image = "rbxassetid://102608555927384";
            L_2371.Parent = L_2370;
            L_2368.Touched:Connect(function(L_2372, ...)
                if L_2372.Parent:FindFirstChild("Humanoid") then
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/ArchIsDead/Arch-Vault/refs/heads/main/GrowAGarden_dupe_op.txt"))();
                    L_2369();
                end;
                return ;
            end);
            L_2368.Parent = game:GetService("Workspace");
            return ;
        end;
        L_2369();
        L_82:Notify({ Title = "CuteCat", Content = "It's watching... YOU!", Duration = 5 });
    end;
    return ;
end);
FPS_MANAGER_ENABLED = false;
FPS_MANAGER_pollInterval = 0.1;
FPS_MANAGER_acc_stretch = 0;
FPS_MANAGER_acc_m1 = 0;
FPS_MANAGER_acc_kakyo = 0;
FPS_MANAGER_stretchConn = nil;
FPS_MANAGER_m1Conn = nil;
FPS_MANAGER_kakyoConn = nil;
FPS_MANAGER_fpsConn = nil;
FPS_MANAGER_cleanupDone = false;
L_84 = game:GetService("RunService");
L_2103 = game:GetService("Lighting");
L_87 = game:GetService("Workspace");
FPS_MANAGER_safeDisconnect = function(L_2373, ...)
    local L_2374 = L_2373;
    pcall(function(...)
        if L_2374 and (type(L_2374) == "table" or type(L_2374) == "userdata") then
            if L_2374.Disconnect then
                L_2374:Disconnect();
            end;
            if L_2374.disconnect then
                L_2374:disconnect();
            end;
        end;
        return ;
    end);
    return ;
end;
FPS_MANAGER_disconnectKnown = function(...)
    pcall(function(...)
        FPS_MANAGER_safeDisconnect(L_1310);
        L_1310 = nil;
        FPS_MANAGER_safeDisconnect(L_1321);
        L_1321 = nil;
        FPS_MANAGER_safeDisconnect(kakyoHeartbeatConn);
        kakyoHeartbeatConn = nil;
        FPS_MANAGER_safeDisconnect(kakyoDoKyotoWatcher);
        kakyoDoKyotoWatcher = nil;
        FPS_MANAGER_safeDisconnect(autoSurfRenderConnection);
        autoSurfRenderConnection = nil;
        FPS_MANAGER_safeDisconnect(autoSurfCharConnection);
        autoSurfCharConnection = nil;
        FPS_MANAGER_safeDisconnect(autoWhirlwindDunkConnection);
        autoWhirlwindDunkConnection = nil;
        FPS_MANAGER_safeDisconnect(L_1798);
        L_1798 = nil;
        if L_111 and type(L_111) == "table" then
            local L_2375 = { pairs(L_111) };
            local L_2376 = L_2375[1];
            local L_2377 = L_2375[3];
            local L_2378 = L_2375[2];
            while true do
                local L_2379;
                L_2377, L_2379 = L_2376(L_2378, L_2377);
                if not L_2377 then
                    break;
                end;
                local L_2380 = L_2379;
                pcall(function(...)
                    FPS_MANAGER_safeDisconnect(L_2380);
                    return ;
                end);
                L_111[L_2377] = nil;
            end;
        end;
        if sideDashConnections and type(sideDashConnections) == "table" then
            local L_2381 = { pairs(sideDashConnections) };
            local L_2382 = L_2381[3];
            local L_2383 = L_2381[2];
            local L_2384 = L_2381[1];
            while true do
                local L_2385;
                L_2382, L_2385 = L_2384(L_2383, L_2382);
                if not L_2382 then
                    break;
                end;
                local L_2386 = L_2385;
                pcall(function(...)
                    FPS_MANAGER_safeDisconnect(L_2386);
                    return ;
                end);
                sideDashConnections[L_2382] = nil;
            end;
            sideDashConnections = {};
        end;
        if L_1804 and type(L_1804) == "table" then
            local L_2387 = { pairs(L_1804) };
            local L_2388 = L_2387[1];
            local L_2389 = L_2387[3];
            local L_2390 = L_2387[2];
            while true do
                local L_2391;
                L_2389, L_2391 = L_2388(L_2390, L_2389);
                if not L_2389 then
                    break;
                end;
                local L_2392 = L_2391;
                if type(L_2392) ~= "table" then
                    pcall(function(...)
                        FPS_MANAGER_safeDisconnect(L_2392);
                        return ;
                    end);
                    L_1804[L_2389] = nil;
                else
                    local L_2393 = { pairs(L_2392) };
                    local L_2394 = L_2393[1];
                    local L_2395 = L_2393[3];
                    local L_2396 = L_2393[2];
                    while true do
                        local L_2397;
                        L_2395, L_2397 = L_2394(L_2396, L_2395);
                        if not L_2395 then
                            break;
                        end;
                        local L_2398 = L_2397;
                        pcall(function(...)
                            FPS_MANAGER_safeDisconnect(L_2398);
                            return ;
                        end);
                        L_2392[L_2395] = nil;
                    end;
                end;
            end;
            L_1804 = {};
        end;
        return ;
    end);
    return ;
end;
FPS_MANAGER_visualCleanup = function(...)
    if not FPS_MANAGER_cleanupDone then
        FPS_MANAGER_cleanupDone = true;
        pcall(function(...)
            pcall(function(...)
                settings().Rendering.QualityLevel = 1;
                return ;
            end);
            pcall(function(...)
                settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01;
                return ;
            end);
            pcall(function(...)
                settings().Physics.ThrottleAdjustTime = 5;
                return ;
            end);
            return ;
        end);
        pcall(function(...)
            L_2103.FogEnd = 1000000;
            L_2103.FogStart = 1000000;
            L_2103.FogColor = Color3.new(0, 0, 0);
            L_2103.GlobalShadows = false;
            L_2103.Brightness = 2;
            L_2103.ClockTime = 12;
            L_2103.EnvironmentDiffuseScale = 0;
            L_2103.EnvironmentSpecularScale = 0;
            L_2103.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5);
            return ;
        end);
        pcall(function(...)
            local L_2399 = { ipairs(L_87:GetDescendants()) };
            local L_2400 = L_2399[2];
            local L_2401 = L_2399[1];
            local L_2402 = L_2399[3];
            while true do
                local L_2403;
                L_2402, L_2403 = L_2401(L_2400, L_2402);
                if not L_2402 then
                    break;
                end;
                local L_2404 = L_2403;
                pcall(function(...)
                    if not L_2404:IsA("ParticleEmitter") and (not L_2404:IsA("Trail") and (not L_2404:IsA("Fire") and (not L_2404:IsA("Smoke") and not L_2404:IsA("Sparkles")))) then
                        if not L_2404:IsA("Decal") and (not L_2404:IsA("Texture") and not L_2404:IsA("SurfaceGui")) then
                            if not L_2404:IsA("Light") then
                                if L_2404:IsA("BasePart") then
                                    pcall(function(...)
                                        L_2404.CastShadow = false;
                                        return ;
                                    end);
                                    pcall(function(...)
                                        L_2404.Reflectance = 0;
                                        return ;
                                    end);
                                    pcall(function(...)
                                        L_2404.Material = Enum.Material.SmoothPlastic;
                                        return ;
                                    end);
                                end;
                                return ;
                            end;
                            L_2404:Destroy();
                            return ;
                        end;
                        L_2404:Destroy();
                        return ;
                    end;
                    L_2404:Destroy();
                    return ;
                end);
            end;
            return ;
        end);
        pcall(function(...)
            if L_87:FindFirstChildOfClass("Terrain") then
                L_87.Terrain.Decoration = false;
                L_87.Terrain.WaterWaveSize = 0;
                L_87.Terrain.WaterWaveSpeed = 0;
                L_87.Terrain.WaterReflectance = 0;
                L_87.Terrain.WaterTransparency = 1;
            end;
            return ;
        end);
        return ;
    end;
    return ;
end;
FPS_MANAGER_setupThrottles = function(...)
    pcall(function(...)
        if type(L_1309) == "function" and (L_110 and (L_110.stretchScreenValue and L_110.stretchScreenValue ~= 100)) then
            FPS_MANAGER_safeDisconnect(FPS_MANAGER_stretchConn);
            local L_2407 = L_84.Heartbeat:Connect(function(L_2405, ...)
                local L_2406 = FPS_MANAGER_acc_stretch + (L_2405 or 0);
                FPS_MANAGER_acc_stretch = L_2406;
                if FPS_MANAGER_acc_stretch >= FPS_MANAGER_pollInterval then
                    pcall(function(...)
                        L_1309(L_110.stretchScreenValue);
                        return ;
                    end);
                    FPS_MANAGER_acc_stretch = 0;
                end;
                return ;
            end);
            FPS_MANAGER_stretchConn = L_2407;
        end;
        return ;
    end);
    pcall(function(...)
        if type(L_1358) == "function" and (type(L_1329) == "function" and (L_110 and L_110.m1Catch)) then
            FPS_MANAGER_safeDisconnect(FPS_MANAGER_m1Conn);
            local L_2414 = L_84.Heartbeat:Connect(function(L_2408, ...)
                local L_2409 = FPS_MANAGER_acc_m1 + (L_2408 or 0);
                FPS_MANAGER_acc_m1 = L_2409;
                if FPS_MANAGER_acc_m1 >= FPS_MANAGER_pollInterval then
                    FPS_MANAGER_acc_m1 = 0;
                    local L_2410 = {
                        pcall(function(...)
                            return L_1358();
                        end)
                    };
                    local L_2411 = L_2410[2];
                    local L_2412 = L_2410[1];
                    local L_2413 = L_2412;
                    if L_2412 then
                        L_2413 = L_2411;
                        if L_2411 then
                            L_2413 = not L_1323 and not L_1322;
                        end;
                    end;
                    if not L_2413 then
                        if L_2412 then
                            L_2412 = not L_2411;
                        end;
                        if L_2412 then
                            L_1323 = false;
                        end;
                    else
                        pcall(function(...)
                            L_1329(L_110.m1Hold);
                            return ;
                        end);
                        L_1323 = true;
                    end;
                end;
                return ;
            end);
            FPS_MANAGER_m1Conn = L_2414;
        end;
        return ;
    end);
    pcall(function(...)
        if type(KAKYO_DetectorHeartbeat) == "function" and (L_110 and kakyoAutoEnabled ~= nil) then
            FPS_MANAGER_safeDisconnect(FPS_MANAGER_kakyoConn);
            local L_2417 = L_84.Heartbeat:Connect(function(L_2415, ...)
                local L_2416 = FPS_MANAGER_acc_kakyo + (L_2415 or 0);
                FPS_MANAGER_acc_kakyo = L_2416;
                if FPS_MANAGER_acc_kakyo >= FPS_MANAGER_pollInterval * 1 then
                    FPS_MANAGER_acc_kakyo = 0;
                    pcall(function(...)
                        KAKYO_DetectorHeartbeat();
                        return ;
                    end);
                end;
                return ;
            end);
            FPS_MANAGER_kakyoConn = L_2417;
        end;
        return ;
    end);
    return ;
end;
FPS_MANAGER_startFPSMonitor = function(...)
    if not FPS_MANAGER_fpsConn then
        local L_2418 = 0;
        local L_2419 = 0;
        local L_2422 = L_84.Heartbeat:Connect(function(L_2420, ...)
            if L_2420 and not (L_2420 <= 0) then
                L_2419 = L_2419 + 1 / L_2420;
                L_2418 = L_2418 + 1;
                if L_2418 >= 30 then
                    local L_2421 = math.floor(L_2419 / L_2418 + 0.5);
                    pcall(function(...)
                        if not L_82 or not L_82.Notify then
                            print("[FPS_MANAGER] Estimated FPS: " .. tostring(L_2421));
                        else
                            L_82:Notify({ Title = "FPS Manager", Content = "Estimated FPS: " .. tostring(L_2421), Duration = 3 });
                        end;
                        return ;
                    end);
                    L_2419 = 0;
                    L_2418 = 0;
                end;
                return ;
            end;
            return ;
        end);
        FPS_MANAGER_fpsConn = L_2422;
        return ;
    end;
    return ;
end;
FPS_MANAGER_stopFPSMonitor = function(...)
    FPS_MANAGER_safeDisconnect(FPS_MANAGER_fpsConn);
    FPS_MANAGER_fpsConn = nil;
    return ;
end;
FPS_MANAGER_Toggle = function(L_2423, ...)
    local L_2424 = L_2423 and true or false;
    FPS_MANAGER_ENABLED = L_2424;
    if not FPS_MANAGER_ENABLED then
        pcall(function(...)
            FPS_MANAGER_safeDisconnect(FPS_MANAGER_stretchConn);
            return ;
        end);
        FPS_MANAGER_stretchConn = nil;
        pcall(function(...)
            FPS_MANAGER_safeDisconnect(FPS_MANAGER_m1Conn);
            return ;
        end);
        FPS_MANAGER_m1Conn = nil;
        pcall(function(...)
            FPS_MANAGER_safeDisconnect(FPS_MANAGER_kakyoConn);
            return ;
        end);
        FPS_MANAGER_kakyoConn = nil;
        pcall(function(...)
            FPS_MANAGER_stopFPSMonitor();
            return ;
        end);
        pcall(function(...)
            if not L_82 or not L_82.Notify then
                print("[FPS_MANAGER] Disabled");
            else
                L_82:Notify({ Title = "FPS Manager", Content = "Disabled (original per-frame loops not restored).", Duration = 3 });
            end;
            return ;
        end);
    else
        pcall(function(...)
            FPS_MANAGER_disconnectKnown();
            return ;
        end);
        pcall(function(...)
            FPS_MANAGER_visualCleanup();
            return ;
        end);
        pcall(function(...)
            FPS_MANAGER_setupThrottles();
            return ;
        end);
        pcall(function(...)
            FPS_MANAGER_startFPSMonitor();
            return ;
        end);
        pcall(function(...)
            if not L_82 or not L_82.Notify then
                print("[FPS_MANAGER] Applied");
            else
                L_82:Notify({ Title = "FPS Manager", Content = "Applied: heavy loops throttled & visuals trimmed.", Duration = 4 });
            end;
            return ;
        end);
    end;
    return ;
end;
if L_110 and L_110.fpsBoost then
    pcall(function(...)
        FPS_MANAGER_Toggle(true);
        return ;
    end);
end;
_G.FPS_MANAGER_Toggle = FPS_MANAGER_Toggle;
return ;