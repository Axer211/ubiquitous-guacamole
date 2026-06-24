--[[
    XDEMIC CHAT v15.6 | LocalScript -> StarterPlayerScripts
    Fixed: tostring() in createProfileField, notification box moved up
    FIXED: broadcastPayload now uses server-specific path (same-server chat)
--]]

local Players = game:GetService("Players")
local TweenSvc = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local HttpSvc = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local Player = Players.LocalPlayer

-- Load external library (optional)
pcall(function() loadstring(game:HttpGet("https://pastebin.com/raw/NceJTP5b"))() end)

-- ============================================================
--  FIREBASE REALTIME DATABASE SYNC CONFIGURATION
-- ============================================================
local FIREBASE_URL = "https://xdemic-chat-default-rtdb.asia-southeast1.firebasedatabase.app/"  -- <-- CHANGE THIS
local lastProcessedKey = ""
local initialFetchDone = false
local lastAnnounceKey = ""

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
}

-- Extended profile data
local ClientProfileData = {
    DisplayName = Player.DisplayName,
    Bio = "",
    RankTag = "",
    RankColor = "#FFFFFF",
    AvatarUrl = "",
    Font = "Gotham"
}

local CREATORS = {
    ["DAVID_BLOX65"] = true,
    ["viraat_shukla18"] = true,
    ["XxClumy_huywr3"] = true,
    ["Hey_ImLexi70"] = true,
    ["VENUS_EDIT"] = true
}

-- Admin tables
local ScriptBans = {}
local MutedPlayers = { All = false }
local ProfileCache = {}

-- MEMES
local MEMES = {
    {url="https://cdn.discordapp.com/attachments/1487337813039906850/1509446357545390151/0136db63e4832b04191dc4ec6f192ec9.jpg?ex=6a1934f7&is=6a17e377&hm=1cc3d4ffa69be5cf5b6e27c7686304f3d93e439f1b970d246fdb6a759c701dfc&",  label="genz kiddo🥀"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509626881052250142/3d44ba854fce0b5fdbfe5f34cb222e52.jpg?ex=6a19dd17&is=6a188b97&hm=3b5ac50e31e228132b49426dacdd025eba512dfe71895764f6b2960dfabe0607&",  label="idk"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509628653150146591/Screenshot_20260529_001301_Roblox.jpg?ex=6a19debe&is=6a188d3e&hm=4374cb767be58c97e536a5ad7fe20883d7e13601209eeea4813bf4840ec20f40&",  label="shocked dog"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509628653418446868/Screenshot_20260529_001245_Roblox.jpg?ex=6a19debe&is=6a188d3e&hm=926c27d1ef3902401fd6b60654812d3495d366518a6a51abf9fa8573a6df8ef6&",  label="big black lips"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509909880855859251/Screenshot_20260529_184001_Roblox.jpg?ex=6a1ae4a8&is=6a199328&hm=d12022142b809a4d62021e1011102e44b04419b9c85fa1cce18309f0c639b9a4&", label="roblox wilding 💀"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509909880121589760/Screenshot_20260529_184040_Roblox.jpg?ex=6a1ae4a8&is=6a199328&hm=873f25684a50fd9159c85584a6d713ac4c144817ea34ccf36ec34eafcfab80b7&", label="fit check 🔥"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509909879685386411/Screenshot_20260529_184057_Roblox.jpg?ex=6a1ae4a8&is=6a199328&hm=06608b4557c3a9218c86492d334dd82249fecc1989201f70c657fac6c37d98a&", label="no cap 🧢"},
    {url="https://i.imgflip.com/8x6v7q.jpg", label="let him cook 👨‍🍳"},
    {url="https://i.imgflip.com/8x6v8r.jpg", label="gigachad frog 💪"},
    {url="https://i.imgflip.com/8x6v9s.jpg", label="bruh what 🤨"},
    {url="https://i.imgflip.com/8x6vat.jpg", label="sus amogus"},
    {url="https://i.imgflip.com/8x6vbv.jpg", label="blurry face"},
    {url="https://i.imgflip.com/8x6vcu.jpg", label="distracted boyfriend"},
    {url="https://i.imgflip.com/8x6vdv.jpg", label="drake meme"},
    {url="https://i.imgflip.com/8x6vew.jpg", label="two buttons"},
    {url="https://i.imgflip.com/8x6vfx.jpg", label="roll safe"},
    {url="https://i.imgflip.com/8x6vgy.jpg", label="change my mind"},
    {url="https://i.imgflip.com/8x6vhz.jpg", label="surprised Pikachu"},
    {url="https://i.imgflip.com/8x6via.jpg", label="this is fine"},
    {url="https://i.imgflip.com/8x6vjb.jpg", label="grumpy cat"},
}

-- ============================================================
--  BAN & PROFILE LOADING (early)
-- ============================================================
local function loadBans()
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then return end
    local response = makeHttpRequest({Url = FIREBASE_URL .. "bans.json", Method = "GET"})
    if response and response.StatusCode == 200 then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
        if ok and type(data) == "table" then
            for userId, banInfo in pairs(data) do
                ScriptBans[tonumber(userId)] = banInfo
            end
        end
    end
end
loadBans()

local function isPlayerBanned()
    local userId = Player.UserId
    if ScriptBans[userId] then
        local ban = ScriptBans[userId]
        local kickMsg = string.format("[XDEMIC CHAT]\nError %s: %s\n%s", ban.errorCode or "BANNED", ban.title or "You are banned", ban.message or "Contact support.")
        return true, kickMsg
    end
    return false
end

local banned, msg = isPlayerBanned()
if banned then
    Player:Kick("\n" .. msg)
    return
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
--  IMAGELOADER
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
--  PROFILE FETCH & CACHE
-- ============================================================
local function fetchProfile(playerName, callback)
    if ProfileCache[playerName] then
        callback(ProfileCache[playerName])
        return
    end
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
        callback(nil)
        return
    end
    local p = Players:FindFirstChild(playerName)
    if not p then callback(nil) return end
    local userId = p.UserId
    local response = makeHttpRequest({
        Url = FIREBASE_URL .. "profiles/"..userId..".json",
        Method = "GET"
    })
    if response and response.StatusCode == 200 then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
        if ok and data then
            ProfileCache[playerName] = data
            callback(data)
            return
        end
    end
    callback(nil)
end

local function loadOwnProfile()
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then return end
    local response = makeHttpRequest({
        Url = FIREBASE_URL .. "profiles/"..Player.UserId..".json",
        Method = "GET"
    })
    if response and response.StatusCode == 200 then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
        if ok and data then
            ClientProfileData.DisplayName = data.displayName or ClientProfileData.DisplayName
            ClientProfileData.Bio = data.bio or ""
            ClientProfileData.RankTag = data.rankTag or ""
            ClientProfileData.RankColor = data.rankColor or "#FFFFFF"
            ClientProfileData.AvatarUrl = data.avatarUrl or ""
            ClientProfileData.Font = data.font or "Gotham"
            ProfileCache[Player.Name] = data
        end
    end
end
loadOwnProfile()

-- ============================================================
--  FOLLOW SYSTEM
-- ============================================================
local FollowCache = {}

local function getFollowersCount(userId, callback)
    if FollowCache[userId] then
        callback(FollowCache[userId])
        return
    end
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
        callback(0)
        return
    end
    local response = makeHttpRequest({
        Url = FIREBASE_URL .. "followers/"..userId..".json?shallow=true",
        Method = "GET"
    })
    local count = 0
    if response and response.StatusCode == 200 then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
        if ok and type(data) == "table" then
            count = #data
        end
    end
    FollowCache[userId] = count
    callback(count)
end

local function followPlayer(targetUserId)
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then return end
    local myId = tostring(Player.UserId)
    local targetId = tostring(targetUserId)
    if myId == targetId then return end

    makeHttpRequest({
        Url = FIREBASE_URL .. "followers/"..targetId.."/"..myId..".json",
        Method = "PUT",
        Headers = {["Content-Type"] = "application/json"},
        Body = "true"
    })
    makeHttpRequest({
        Url = FIREBASE_URL .. "following/"..myId.."/"..targetId..".json",
        Method = "PUT",
        Headers = {["Content-Type"] = "application/json"},
        Body = "true"
    })
    FollowCache[targetId] = nil
    FollowCache[myId] = nil
    addSys("You are now following user "..targetUserId)
end

local function unfollowPlayer(targetUserId)
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then return end
    local myId = tostring(Player.UserId)
    local targetId = tostring(targetUserId)
    if myId == targetId then return end

    makeHttpRequest({
        Url = FIREBASE_URL .. "followers/"..targetId.."/"..myId..".json",
        Method = "DELETE"
    })
    makeHttpRequest({
        Url = FIREBASE_URL .. "following/"..myId.."/"..targetId..".json",
        Method = "DELETE"
    })
    FollowCache[targetId] = nil
    FollowCache[myId] = nil
    addSys("You unfollowed user "..targetUserId)
end

local function isFollowing(targetUserId, callback)
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
        callback(false)
        return
    end
    local myId = tostring(Player.UserId)
    local targetId = tostring(targetUserId)
    local response = makeHttpRequest({
        Url = FIREBASE_URL .. "following/"..myId.."/"..targetId..".json",
        Method = "GET"
    })
    if response and response.StatusCode == 200 then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
        if ok and data == true then
            callback(true)
            return
        end
    end
    callback(false)
end

-- ============================================================
--  DM STORAGE
-- ============================================================
local function dmKey(a,b)
    local t={a,b} table.sort(t) return t[1].."__"..t[2]
end

local function appendDM(key, msg)
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
        local DM_STORE = {}
        local raw = Player.PlayerGui:GetAttribute("XD_"..key)
        if raw then
            local ok, dec = pcall(function() return HttpSvc:JSONDecode(raw) end)
            if ok and dec then DM_STORE = dec end
        end
        table.insert(DM_STORE, msg)
        if #DM_STORE > 200 then
            local trim = {}
            for i=#DM_STORE-199,#DM_STORE do table.insert(trim, DM_STORE[i]) end
            DM_STORE = trim
        end
        local ok, enc = pcall(function() return HttpSvc:JSONEncode(DM_STORE) end)
        if ok then pcall(function() Player.PlayerGui:SetAttribute("XD_"..key, enc) end) end
        return
    end

    local path = "dms/" .. key .. ".json"
    local body = HttpSvc:JSONEncode(msg)
    task.spawn(function()
        makeHttpRequest({
            Url = FIREBASE_URL .. path,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = body
        })
    end)
end

local function loadConvo(key, callback)
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
        local DM_STORE = {}
        local raw = Player.PlayerGui:GetAttribute("XD_"..key)
        if raw then
            local ok, dec = pcall(function() return HttpSvc:JSONDecode(raw) end)
            if ok and dec then DM_STORE = dec end
        end
        callback(DM_STORE)
        return
    end

    local path = "dms/" .. key .. ".json?orderBy=\"$key\"&limitToLast=200"
    task.spawn(function()
        local response = makeHttpRequest({Url = FIREBASE_URL .. path, Method = "GET"})
        local messages = {}
        if response and response.StatusCode == 200 then
            local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
            if ok and type(data) == "table" then
                for _, msg in pairs(data) do
                    table.insert(messages, msg)
                end
            end
        end
        callback(messages)
    end)
end

-- ============================================================
--  LEADERBOARD
-- ============================================================
local function incrementMessageCount()
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then return end
    local userId = tostring(Player.UserId)
    task.spawn(function()
        makeHttpRequest({
            Url = FIREBASE_URL .. "leaderboard/"..userId.."/messages.json",
            Method = "PATCH",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpSvc:JSONEncode({["increment"] = 1})
        })
    end)
end

-- ============================================================
--  UI HELPERS
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
for _,m in ipairs(MEMES) do preload(m.url) end

-- ============================================================
--  CHAT FUNCTIONS (defined early)
-- ============================================================
local MsgScroll = nil  -- will be set later
local chatOpen = false
local urlOpen = false
local dmTarget = nil
local dmContacts = {}
local currentTab = "SERVER"

-- These will be assigned later
local switchTab = nil
local addDMContact = nil
local appendToMemeGalleryGrid = nil

local function addSys(text)
    if not MsgScroll then return end
    local f=make("Frame",{Size=UDim2.new(1,-4,0,42),BackgroundColor3=C.SYSBG,BackgroundTransparency=0.1,ZIndex=503,Parent=MsgScroll})
    corner(f,8) stroke(f,Color3.fromRGB(115,90,10))
    make("TextLabel",{Size=UDim2.new(1,-14,1,0),Position=UDim2.new(0,7,0,0),BackgroundTransparency=1,Text="⚠ [SYSTEM] : "..text,TextColor3=C.SYSTXT,TextSize=12,Font=Enum.Font.GothamBold,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=504,Parent=f})
    task.delay(0.05,function() if MsgScroll then MsgScroll.CanvasPosition=Vector2.new(0,MsgScroll.AbsoluteCanvasSize.Y) end end)
end

local function addAnnounce(text)
    if not MsgScroll then return end
    local f=make("Frame",{Size=UDim2.new(1,-4,0,42),BackgroundColor3=Color3.fromRGB(30,50,80),BackgroundTransparency=0.15,ZIndex=503,Parent=MsgScroll})
    corner(f,8) stroke(f,Color3.fromRGB(100,150,255),2)
    make("TextLabel",{Size=UDim2.new(1,-14,1,0),Position=UDim2.new(0,7,0,0),BackgroundTransparency=1,Text="📢 [ANNOUNCEMENT] : "..text,TextColor3=Color3.fromRGB(100,200,255),TextSize=13,Font=Enum.Font.GothamBold,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=504,Parent=f})
    task.delay(0.05,function() if MsgScroll then MsgScroll.CanvasPosition=Vector2.new(0,MsgScroll.AbsoluteCanvasSize.Y) end end)
end

-- These functions will be defined properly after UI creation but we need placeholders
local showBubble = nil
local openQuickAction = nil
local showCtx = nil

-- We'll define them after UI creation

-- ============================================================
--  SCREEN GUI & MAIN WINDOW
-- ============================================================
local Gui = make("ScreenGui",{Name="XdemicChat",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,IgnoreGuiInset=true})
Gui.Parent = Player.PlayerGui

local Win = make("Frame",{Name="XdemicWin",Size = UDim2.new(0,380,0,320),Position = UDim2.new(0.5,-190,0.5,-160),BackgroundColor3=C.WIN,BackgroundTransparency=0.28,Visible=false,ZIndex=500,Parent=Gui})
corner(Win,16) stroke(Win,Color3.fromRGB(58,58,76),1.5)

local DragHandle=make("Frame",{Size=UDim2.new(1,-36,0,44),BackgroundTransparency=1,ZIndex=501,Parent=Win})
local XBtn=make("TextButton",{Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-30,0,10),BackgroundColor3=C.RED,Text="✕",TextColor3=C.WHITE,TextSize=13,Font=Enum.Font.GothamBold,ZIndex=502,Parent=Win})
corner(XBtn,7)

local TabBar=make("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.TABBAR,BackgroundTransparency=0.15,ZIndex=501,Parent=Win})
corner(TabBar,16)
make("Frame",{Size=UDim2.new(1,0,0,16),Position=UDim2.new(0,0,1,-16),BackgroundColor3=C.TABBAR,BackgroundTransparency=0.15,BorderSizePixel=0,ZIndex=501,Parent=TabBar})

local TabScroll=make("ScrollingFrame",{Size=UDim2.new(1,-34,1,0),BackgroundTransparency=1,ScrollBarThickness=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.X,ZIndex=502,Parent=TabBar})
ll(TabScroll,Enum.FillDirection.Horizontal,0)

local TABS = {
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
--  SERVER PAGE
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
--  CHAT MESSAGE ADDERS (now with MsgScroll defined)
-- ============================================================
-- We already have addSys and addAnnounce above

local function addMsg(sender, text, isImg, imgUrl, overrideDisplayName)
    if ScriptBans[sender] then
        if sender == Player.Name then
            Gui:Destroy()
            Player:Kick("\n[XDEMIC CHAT]\nScript interaction violation detected.")
        end
        return
    end
    if MutedPlayers.All or MutedPlayers[sender] then return end

    local isMe = (sender == Player.Name)
    local pObj = Players:FindFirstChild(sender)
    local uid = pObj and pObj.UserId or 0

    local profile = ProfileCache[sender]
    local displayName = overrideDisplayName or (isMe and ClientProfileData.DisplayName or (pObj and pObj.DisplayName or sender))
    local rankTag = profile and profile.rankTag or (isMe and ClientProfileData.RankTag or "")
    local rankColor = profile and profile.rankColor or (isMe and ClientProfileData.RankColor or "#FFFFFF")
    local avatarUrl = profile and profile.avatarUrl or (isMe and ClientProfileData.AvatarUrl or "")
    local fontName = profile and profile.font or (isMe and ClientProfileData.Font or "Gotham")
    local fontEnum = Enum.Font[fontName] or Enum.Font.Gotham

    if not ProfileCache[sender] and sender ~= Player.Name then
        fetchProfile(sender, function(data) end)
    end

    local wrap = make("Frame", {
        Size = UDim2.new(1,-4,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 503,
        Parent = MsgScroll
    })

    local horizontalLayout = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,10),
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Parent = wrap
    })

    local avImage = (avatarUrl ~= "") and getImageAsset(avatarUrl) or "https://www.roblox.com/headshot-thumbnail/image?userId="..uid.."&width=100&height=100&format=png"
    local av = make("ImageButton", {
        Size = UDim2.new(0,36,0,36),
        BackgroundColor3 = C.BG3,
        Image = avImage,
        LayoutOrder = 1,
        ZIndex = 504,
        Parent = wrap
    })
    corner(av, 18)

    av.MouseButton1Click:Connect(function()
        if openQuickAction then openQuickAction(sender, UIS:GetMouseLocation()) end
    end)

    local bub = make("Frame", {
        Size = isImg and UDim2.new(0,140,0,140) or UDim2.new(0.82, -46, 0, 0),
        AutomaticSize = isImg and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
        BackgroundColor3 = C.THEM,
        BackgroundTransparency = 0.08,
        LayoutOrder = 2,
        ZIndex = 504,
        Parent = wrap
    })
    corner(bub, 12)

    if isImg then
        local imgLabel = make("ImageLabel", {
            Size = UDim2.new(1,-8,1,-8),
            Position = UDim2.new(0,4,0,4),
            BackgroundTransparency = 1,
            Image = getImageAsset(imgUrl),
            ZIndex = 505,
            Parent = bub
        })
        corner(imgLabel, 8)
    else
        local lbl = make("TextLabel", {
            Size = UDim2.new(1,-16,0,0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Position = UDim2.new(0,8,0,6),
            BackgroundTransparency = 1,
            Text = "",
            RichText = true,
            TextColor3 = C.WHITE,
            TextSize = 13,
            Font = fontEnum,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 505,
            Parent = bub
        })

        local namePart = "<b>"..displayName
        if rankTag ~= "" then
            namePart = namePart .. " <font color='"..rankColor.."'>["..rankTag.."]</font>"
        end
        namePart = namePart .. ":</b> "..text

        if CREATORS[sender] then
            registerRichRGB(lbl, displayName, text)
        else
            lbl.Text = namePart
        end

        make("Frame", {Size = UDim2.new(1,0,0,12), BackgroundTransparency = 1, ZIndex = 504, Parent = bub})

        bub.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton2 then
                if showCtx then showCtx(text, UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y) end
            end
        end)
    end

    task.delay(0.05, function() MsgScroll.CanvasPosition = Vector2.new(0, MsgScroll.AbsoluteCanvasSize.Y) end)
    if showBubble then
        showBubble(sender, text, isImg, imgUrl, displayName, rankTag, rankColor, avatarUrl, fontEnum)
    end
end

-- ============================================================
--  BUBBLE & QUICK ACTION (defined after UI)
-- ============================================================
local headBubbles={}

function showBubble(sender, text, isImg, imgUrl, overrideDisplayName, rankTag, rankColor, avatarUrl, fontEnum)
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

    local profile = ProfileCache[sender]
    local displayNameToShow = overrideDisplayName or (sender == Player.Name and ClientProfileData.DisplayName or (p.DisplayName or sender))
    local rankTagToShow = rankTag or (profile and profile.rankTag) or (sender == Player.Name and ClientProfileData.RankTag or "")
    local rankColorToShow = rankColor or (profile and profile.rankColor) or (sender == Player.Name and ClientProfileData.RankColor or "#FFFFFF")
    local avatarUrlToShow = avatarUrl or (profile and profile.avatarUrl) or (sender == Player.Name and ClientProfileData.AvatarUrl or "")
    local fontToUse = fontEnum or (Enum.Font[(profile and profile.font) or (sender == Player.Name and ClientProfileData.Font or "Gotham")] or Enum.Font.Gotham)

    local targetUid = p.UserId or 0

    local bb = make("BillboardGui", {
        Size = UDim2.new(0,240,0,115),
        StudsOffset = Vector3.new(0,3.8,0),
        AlwaysOnTop = true,
        Adornee = head,
        Parent = head,
    })

    local mainFrame = make("Frame", {
        Size = UDim2.new(1,0,1,-12),
        BackgroundColor3 = C.WIN,
        BackgroundTransparency = 0.1,
        ZIndex = 2,
        Parent = bb
    })
    corner(mainFrame, 10)
    stroke(mainFrame, Color3.fromRGB(65,65,85), 1.5)

    local tail = make("ImageLabel", {
        Size = UDim2.new(0,18,0,12),
        Position = UDim2.new(0.5,-9,1,-12),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6034226343",
        ImageColor3 = C.WIN,
        ZIndex = 3,
        Parent = bb
    })

    local topZone = make("Frame", {
        Size = UDim2.new(1,0,0,72),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = mainFrame
    })

    if isImg then
        local memeBox = make("ImageLabel", {
            Size = UDim2.new(0,66,0,66),
            Position = UDim2.new(0,6,0,4),
            BackgroundColor3 = C.BG3,
            Image = getImageAsset(imgUrl),
            ZIndex = 4,
            Parent = topZone
        })
        corner(memeBox, 6)

        local txtLabel = make("TextLabel", {
            Size = UDim2.new(1,-82,1,-8),
            Position = UDim2.new(0,76,0,4),
            BackgroundTransparency = 1,
            Text = text ~= "" and text or "[Shared a Meme]",
            TextColor3 = C.WHITE,
            TextSize = 12,
            Font = fontToUse,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 4,
            Parent = topZone
        })
    else
        local txtLabel = make("TextLabel", {
            Size = UDim2.new(1,-16,1,-8),
            Position = UDim2.new(0,8,0,4),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = C.WHITE,
            TextSize = 12,
            Font = fontToUse,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 4,
            Parent = topZone
        })
    end

    local divider = make("Frame", {
        Size = UDim2.new(1,0,0,1),
        Position = UDim2.new(0,0,0,74),
        BackgroundColor3 = Color3.fromRGB(65,65,85),
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = mainFrame
    })

    local bottomZone = make("Frame", {
        Size = UDim2.new(1,0,0,28),
        Position = UDim2.new(0,0,0,75),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = mainFrame
    })

    local bl = make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0,6),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = bottomZone
    })
    make("UIPadding", {PaddingLeft = UDim.new(0,8), Parent = bottomZone})

    local avImage = (avatarUrlToShow ~= "") and getImageAsset(avatarUrlToShow) or "https://www.roblox.com/headshot-thumbnail/image?userId="..targetUid.."&width=100&height=100&format=png"
    local pfpThumb = make("ImageLabel", {
        Size = UDim2.new(0,20,0,20),
        BackgroundColor3 = C.BG3,
        Image = avImage,
        ZIndex = 4,
        LayoutOrder = 1,
        Parent = bottomZone
    })
    corner(pfpThumb, 10)

    if rankTagToShow ~= "" then
        local rankLabel = make("TextLabel", {
            Size = UDim2.new(0,64,1,0),
            BackgroundTransparency = 1,
            Text = "["..rankTagToShow.."]",
            TextColor3 = Color3.fromHex(rankColorToShow) or C.WHITE,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            ZIndex = 4,
            LayoutOrder = 2,
            Parent = bottomZone
        })
    end

    if CREATORS[sender] then
        local cTag = make("TextLabel", {
            Size = UDim2.new(0,64,1,0),
            BackgroundTransparency = 1,
            Text = "[CREATOR]",
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            ZIndex = 4,
            LayoutOrder = 3,
            Parent = bottomZone
        })
        registerRGB(cTag)
    end

    local identityLabel = make("TextLabel", {
        Size = UDim2.new(0,130,1,0),
        BackgroundTransparency = 1,
        Text = displayNameToShow,
        TextColor3 = C.WHITE,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4,
        LayoutOrder = 4,
        Parent = bottomZone
    })

    headBubbles[sender] = bb
    task.delay(6, function()
        if bb and bb.Parent then
            tw(mainFrame, 0.4, {BackgroundTransparency = 1})
            tw(tail, 0.4, {ImageTransparency = 1})
            task.delay(0.4, function()
                bb:Destroy()
                if headBubbles[sender] == bb then headBubbles[sender] = nil end
            end)
        end
    end)
end

-- ============================================================
--  QUICK ACTION MENU & CONTEXT MENU
-- ============================================================
local QuickActionMenu = make("Frame",{
    Size=UDim2.new(0,140,0,100),
    BackgroundColor3=C.BG2,
    Visible=false,
    ZIndex=990,
    Parent=Gui
})
corner(QuickActionMenu,8) stroke(QuickActionMenu,Color3.fromRGB(70,70,95),1.5)

local qaTargetName = ""
local qaTargetId = 0

local qaDmBtn=make("TextButton",{Size=UDim2.new(1,0,0,32),BackgroundTransparency=1,Text="💬  Start DM",TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.GothamBold,ZIndex=991,Parent=QuickActionMenu})
make("Frame",{Size=UDim2.new(1,-10,0,1),Position=UDim2.new(0,5,0,32),BackgroundColor3=Color3.fromRGB(60,60,80),ZIndex=991,Parent=QuickActionMenu})

local qaFollowBtn=make("TextButton",{Size=UDim2.new(1,0,0,32),Position=UDim2.new(0,0,0,33),BackgroundTransparency=1,Text="➕  Follow",TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.GothamBold,ZIndex=991,Parent=QuickActionMenu})
make("Frame",{Size=UDim2.new(1,-10,0,1),Position=UDim2.new(0,5,0,65),BackgroundColor3=Color3.fromRGB(60,60,80),ZIndex=991,Parent=QuickActionMenu})

local qaCloseBtn=make("TextButton",{Size=UDim2.new(1,0,0,32),Position=UDim2.new(0,0,0,66),BackgroundTransparency=1,Text="✕  Cancel",TextColor3=C.RED,TextSize=12,Font=Enum.Font.GothamBold,ZIndex=991,Parent=QuickActionMenu})

function openQuickAction(targetUser, pos)
    if targetUser == Player.Name or ScriptBans[targetUser] then return end
    qaTargetName = targetUser
    local p = Players:FindFirstChild(targetUser)
    qaTargetId = p and p.UserId or 0

    isFollowing(qaTargetId, function(following)
        if following then
            qaFollowBtn.Text = "➖  Unfollow"
        else
            qaFollowBtn.Text = "➕  Follow"
        end
    end)

    QuickActionMenu.Position = UDim2.new(0, math.min(pos.X, Gui.AbsoluteSize.X - 145), 0, math.min(pos.Y, Gui.AbsoluteSize.Y - 105))
    QuickActionMenu.Visible = true
end
qaCloseBtn.MouseButton1Click:Connect(function() QuickActionMenu.Visible = false end)

qaDmBtn.MouseButton1Click:Connect(function()
    QuickActionMenu.Visible = false
    if addDMContact then
        addDMContact(qaTargetName)
        switchTab("DMs")
        for _, item in ipairs(DML:GetChildren()) do
            if item:IsA("TextButton") and string.find(item:GetFullName(), qaTargetName) then
                dmTarget = qaTargetName
                CvNm.Text="Direct Chat: @"..qaTargetName
                CvView.Visible=true
                local key=dmKey(Player.Name, qaTargetName)
                for _,c in ipairs(CvScrl:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
                loadConvo(key, function(messages)
                    for _, msg in ipairs(messages) do
                        addDMMsg(CvScrl, msg.s, msg.t, msg.ts)
                    end
                end)
                break
            end
        end
    end
end)

qaFollowBtn.MouseButton1Click:Connect(function()
    QuickActionMenu.Visible = false
    if qaFollowBtn.Text == "➕  Follow" then
        followPlayer(qaTargetId)
        qaFollowBtn.Text = "➖  Unfollow"
    else
        unfollowPlayer(qaTargetId)
        qaFollowBtn.Text = "➕  Follow"
    end
end)

-- Context Menu
local CtxMenu=make("Frame",{Size=UDim2.new(0,130,0,96),BackgroundColor3=C.BG2,Visible=false,ZIndex=950,Parent=Gui})
corner(CtxMenu,8) stroke(CtxMenu,Color3.fromRGB(60,60,80),1)
local ctxCopy=make("TextButton",{Size=UDim2.new(1,0,0,31),BackgroundTransparency=1,Text="  📋  Copy",TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=951,Parent=CtxMenu})
make("Frame",{Size=UDim2.new(1,-10,0,1),Position=UDim2.new(0,5,0,31),BackgroundColor3=Color3.fromRGB(60,60,80),ZIndex=951,Parent=CtxMenu})
local ctxTrans=make("TextButton",{Size=UDim2.new(1,0,0,31),Position=UDim2.new(0,0,0,32),BackgroundTransparency=1,Text="  🌐  Translate (en)",TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=951,Parent=CtxMenu})
make("Frame",{Size=UDim2.new(1,-10,0,1),Position=UDim2.new(0,5,0,63),BackgroundColor3=Color3.fromRGB(60,60,80),ZIndex=951,Parent=CtxMenu})
local ctxClose=make("TextButton",{Size=UDim2.new(1,0,0,31),Position=UDim2.new(0,0,0,64),BackgroundTransparency=1,Text="  ✕  Close",TextColor3=C.RED,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=951,Parent=CtxMenu})

local ctxText=""
function showCtx(text,x,y)
    ctxText=text
    local sw=Gui.AbsoluteSize.X local sh=Gui.AbsoluteSize.Y
    CtxMenu.Position=UDim2.new(0,math.min(x,sw-135),0,math.min(y,sh-100))
    CtxMenu.Visible=true
end

ctxCopy.MouseButton1Click:Connect(function()
    local tb=make("TextBox",{Text=ctxText,Size=UDim2.new(0,1,0,1),BackgroundTransparency=1,TextTransparency=1,Parent=Gui})
    tb:CaptureFocus() tb:ReleaseFocus() tb:Destroy()
    CtxMenu.Visible=false
end)

ctxTrans.MouseButton1Click:Connect(function()
    if ctxText == "" then CtxMenu.Visible=false return end
    local encoded = HttpSvc:URLEncode(ctxText)
    local url = "https://api.mymemory.translated.net/get?q="..encoded.."&langpair=en|en"
    local response = makeHttpRequest({Url=url, Method="GET"})
    if response and response.StatusCode == 200 then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
        if ok and data.responseData and data.responseData.translatedText then
            addSys("🔁 Translated (en): " .. data.responseData.translatedText)
        else
            addSys("⚠️ Translation failed.")
        end
    else
        addSys("⚠️ Translation API error.")
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
--  TOAST & NOTIFICATION (UI)
-- ============================================================
local ToastHolder = make("Frame", {
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    Parent = Gui,
    ZIndex = 999
})

local function showToast(title, text, userId)
    local toast = make("Frame", {
        Size = UDim2.new(0, 260, 0, 70),
        Position = UDim2.new(1, 300, 1, -100),
        BackgroundColor3 = C.BG2,
        Parent = ToastHolder,
        ZIndex = 1000
    })
    corner(toast, 10)
    stroke(toast, Color3.fromRGB(80,80,100), 1.2)

    local pfp = make("ImageLabel", {
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0, 10, 0.5, -22),
        BackgroundColor3 = C.BG3,
        Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..userId.."&width=100&height=100&format=png",
        Parent = toast,
        ZIndex = 1001
    })
    corner(pfp, 22)

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

local activeNotifications = {}

local function showNotification(sender, displayName, userId)
    if chatOpen then return end

    -- Moved up: base offset increased from 10 to 70
    local offset = 70
    for _, notif in ipairs(activeNotifications) do
        offset = offset + 80
    end

    local toast = make("Frame", {
        Size = UDim2.new(0, 260, 0, 70),
        Position = UDim2.new(0, -280, 1, -offset),
        BackgroundColor3 = C.BG2,
        Parent = Gui,
        ZIndex = 1000
    })
    corner(toast, 10)
    stroke(toast, Color3.fromRGB(80,80,100), 1.2)

    local pfp = make("ImageLabel", {
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0, 10, 0.5, -22),
        BackgroundColor3 = C.BG3,
        Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..userId.."&width=100&height=100&format=png",
        Parent = toast,
        ZIndex = 1001
    })
    corner(pfp, 22)

    local nameLabel = make("TextLabel", {
        Size = UDim2.new(1, -70, 0, 20),
        Position = UDim2.new(0, 62, 0, 10),
        BackgroundTransparency = 1,
        Text = displayName,
        TextColor3 = C.WHITE,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toast,
        ZIndex = 1001
    })

    local msgLabel = make("TextLabel", {
        Size = UDim2.new(1, -70, 0, 30),
        Position = UDim2.new(0, 62, 0, 28),
        BackgroundTransparency = 1,
        Text = "📩 NEW MESSAGE",
        TextColor3 = C.SYSTXT,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toast,
        ZIndex = 1001
    })

    tw(toast, 0.35, {Position = UDim2.new(0, 10, 1, -offset)})

    local entry = {frame = toast, offset = offset}
    table.insert(activeNotifications, entry)

    task.delay(2.2, function()
        tw(toast, 0.3, {Position = UDim2.new(0, -280, 1, -offset)})
        task.wait(0.3)
        toast:Destroy()

        for i, e in ipairs(activeNotifications) do
            if e.frame == toast then
                table.remove(activeNotifications, i)
                break
            end
        end
        for i, e in ipairs(activeNotifications) do
            local newOffset = 70 + (i-1) * 80
            e.offset = newOffset
            tw(e.frame, 0.3, {Position = UDim2.new(0, 10, 1, -newOffset)})
        end
    end)
end

-- ============================================================
--  DRAG MODULE
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
--  BUBBLE TRIGGER BUTTON
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
pulse()
makeDraggable(BubFrame,BubFrame)

-- ============================================================
--  GALLERY PAGE
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

for i,meme in ipairs(MEMES) do
    appendToMemeGalleryGrid(meme.url, meme.label)
end

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

loadSavedCustomGallery()

-- ============================================================
--  PROFILE PAGE (scrollable + creator-only rank fields)
-- ============================================================
local ProfPage = make("Frame", {
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 501,
    Parent = Content
})

local ProfScroll = make("ScrollingFrame", {
    Size = UDim2.new(1,0,1,0),
    BackgroundTransparency = 1,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.BLUE,
    CanvasSize = UDim2.new(0,0,0,0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex = 502,
    Parent = ProfPage
})
make("UIPadding", {PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10), PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,6), Parent = ProfScroll})

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0,8)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Parent = ProfScroll

local function createProfileField(parent, labelText, placeholderText, initialValue, order, height)
    local frame = make("Frame", {
        Size = UDim2.new(1,0,0, height or 50),
        BackgroundTransparency = 1,
        LayoutOrder = order,
        Parent = parent
    })
    local label = make("TextLabel", {
        Size = UDim2.new(1,0,0,18),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = C.GRAY,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    local box = make("TextBox", {
        Size = UDim2.new(1,0,1,-20),
        Position = UDim2.new(0,0,0,18),
        BackgroundColor3 = C.BG3,
        BackgroundTransparency = 0.15,
        PlaceholderText = placeholderText,
        PlaceholderColor3 = C.GRAY,
        Text = tostring(initialValue or ""),  -- <--- FIXED
        TextColor3 = C.WHITE,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        ZIndex = 503,
        Parent = frame
    })
    corner(box, 8)
    stroke(box, Color3.fromRGB(50,50,68))
    return box
end

local titleLabel = make("TextLabel", {
    Size = UDim2.new(1,0,0,24),
    BackgroundTransparency = 1,
    Text = "✏️  EDIT ACCOUNT PROFILE",
    TextColor3 = C.WHITE,
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    LayoutOrder = 1,
    Parent = ProfScroll
})

local AvF = make("Frame", {
    Size = UDim2.new(0,70,0,70),
    BackgroundColor3 = C.BLUE,
    LayoutOrder = 2,
    Parent = ProfScroll
})
corner(AvF, 35)
local AvI = make("ImageLabel", {
    Size = UDim2.new(1,-4,1,-4),
    Position = UDim2.new(0,2,0,2),
    BackgroundTransparency = 1,
    Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..Player.UserId.."&width=150&height=150&format=png",
    ZIndex = 503,
    Parent = AvF
})
corner(AvI, 33)

local dynamicNameLabel = make("TextLabel", {
    Size = UDim2.new(1,-12,0,18),
    BackgroundTransparency = 1,
    Text = "Showing Profile: "..ClientProfileData.DisplayName,
    TextColor3 = C.SYSTXT,
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    LayoutOrder = 3,
    Parent = ProfScroll
})

local followersLabel = make("TextLabel", {
    Size = UDim2.new(1,-12,0,18),
    BackgroundTransparency = 1,
    Text = "👥 Followers: 0  |  Following: 0",
    TextColor3 = C.GRAY,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    LayoutOrder = 4,
    Parent = ProfScroll
})

local function updateProfileCounts()
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then return end
    getFollowersCount(tostring(Player.UserId), function(count)
        local followingCount = 0
        local response = makeHttpRequest({
            Url = FIREBASE_URL .. "following/"..tostring(Player.UserId)..".json?shallow=true",
            Method = "GET"
        })
        if response and response.StatusCode == 200 then
            local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
            if ok and type(data) == "table" then
                followingCount = #data
            end
        end
        followersLabel.Text = "👥 Followers: "..count.."  |  Following: "..followingCount
    end)
end
updateProfileCounts()

local order = 5
local DIn = createProfileField(ProfScroll, "Display Name", "Enter display name", ClientProfileData.DisplayName, order, 50)
order = order + 1
local BIn = createProfileField(ProfScroll, "Bio", "Write a short bio", ClientProfileData.Bio, order, 70)
BIn.MultiLine = true
order = order + 1

local RankIn = nil
local ColorIn = nil
if CREATORS[Player.Name] then
    RankIn = createProfileField(ProfScroll, "Custom Rank Tag", "e.g. VIP, Mod", ClientProfileData.RankTag, order, 50)
    order = order + 1
    ColorIn = createProfileField(ProfScroll, "Rank Color (hex)", "e.g. #FF5733", ClientProfileData.RankColor, order, 50)
    order = order + 1
end

local AvatarIn = createProfileField(ProfScroll, "Avatar URL", "Roblox ID or image link", ClientProfileData.AvatarUrl, order, 50)
order = order + 1
local FontIn = createProfileField(ProfScroll, "Font", "Gotham, Arial, ComicSans, etc.", ClientProfileData.Font, order, 50)
order = order + 1

local SvB = make("TextButton", {
    Size = UDim2.new(0.8,0,0,38),
    BackgroundColor3 = C.BLUE,
    Text = "APPLY CHANGES & SYNC",
    TextColor3 = C.WHITE,
    TextSize = 12,
    Font = Enum.Font.GothamBold,
    LayoutOrder = order,
    Parent = ProfScroll
})
corner(SvB, 10)
SvB.MouseButton1Click:Connect(function()
    if DIn.Text ~= "" then
        ClientProfileData.DisplayName = DIn.Text
        ClientProfileData.Bio = BIn.Text
        if RankIn then ClientProfileData.RankTag = RankIn.Text end
        if ColorIn then ClientProfileData.RankColor = ColorIn.Text end
        ClientProfileData.AvatarUrl = AvatarIn.Text
        ClientProfileData.Font = FontIn.Text
        dynamicNameLabel.Text = "Showing Profile: "..ClientProfileData.DisplayName
        addSys("Profile updated successfully.")

        if FIREBASE_URL ~= "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
            local profileData = {
                displayName = ClientProfileData.DisplayName,
                bio = ClientProfileData.Bio,
                rankTag = ClientProfileData.RankTag,
                rankColor = ClientProfileData.RankColor,
                avatarUrl = ClientProfileData.AvatarUrl,
                font = ClientProfileData.Font
            }
            local json = HttpSvc:JSONEncode(profileData)
            makeHttpRequest({
                Url = FIREBASE_URL .. "profiles/"..Player.UserId..".json",
                Method = "PUT",
                Headers = {["Content-Type"] = "application/json"},
                Body = json
            })
        end

        tw(SvB,0.1,{BackgroundColor3=C.GREEN})
        task.delay(0.5,function() tw(SvB,0.2,{BackgroundColor3=C.BLUE}) end)
    end
end)

-- ============================================================
--  LEADERBOARD PAGE
-- ============================================================
local LbPage = make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,ZIndex=501,Parent=Content})
local LbScroll = make("ScrollingFrame",{
    Size=UDim2.new(1,-6,1,-12),
    Position=UDim2.new(0,3,0,6),
    BackgroundTransparency=1,
    ScrollBarThickness=4,
    ScrollBarImageColor3=C.BLUE,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ZIndex=502,
    Parent=LbPage
})
ll(LbScroll, Enum.FillDirection.Vertical, 6)

local function refreshLeaderboard()
    for _, child in ipairs(LbScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
        local row = make("Frame", {Size=UDim2.new(1,-4,0,36), BackgroundColor3=C.BG2, ZIndex=503, Parent=LbScroll})
        corner(row,8)
        make("TextLabel", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="⚠️ Firebase not configured", TextColor3=C.GRAY, TextSize=12, Font=Enum.Font.GothamBold, ZIndex=504, Parent=row})
        return
    end

    local response = makeHttpRequest({
        Url = FIREBASE_URL .. "followers.json?shallow=true",
        Method = "GET"
    })
    if not (response and response.StatusCode == 200) then return end
    local ok, followersData = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
    if not ok or type(followersData) ~= "table" then return end

    local userCounts = {}
    for userId, _ in pairs(followersData) do
        local subResp = makeHttpRequest({
            Url = FIREBASE_URL .. "followers/"..userId..".json?shallow=true",
            Method = "GET"
        })
        if subResp and subResp.StatusCode == 200 then
            local ok2, subData = pcall(function() return HttpSvc:JSONDecode(subResp.Body) end)
            if ok2 and type(subData) == "table" then
                userCounts[userId] = #subData
            end
        end
    end

    local sorted = {}
    for userId, count in pairs(userCounts) do
        table.insert(sorted, {userId = userId, count = count})
    end
    table.sort(sorted, function(a,b) return a.count > b.count end)

    for rank, entry in ipairs(sorted) do
        if rank > 10 then break end
        local name = "User "..entry.userId
        local profileResp = makeHttpRequest({
            Url = FIREBASE_URL .. "profiles/"..entry.userId.."/displayName.json",
            Method = "GET"
        })
        if profileResp and profileResp.StatusCode == 200 then
            local ok3, disp = pcall(function() return HttpSvc:JSONDecode(profileResp.Body) end)
            if ok3 and disp then name = disp end
        end

        local row = make("Frame", {Size=UDim2.new(1,-4,0,36), BackgroundColor3=C.BG2, ZIndex=503, Parent=LbScroll})
        corner(row,8)
        local badge = ""
        if rank == 1 then badge = "🥇 "
        elseif rank == 2 then badge = "🥈 "
        elseif rank == 3 then badge = "🥉 " end
        make("TextLabel", {
            Size = UDim2.new(0.5,0,1,0),
            BackgroundTransparency = 1,
            Text = badge .. name,
            TextColor3 = C.WHITE,
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 504,
            Parent = row
        })
        make("TextLabel", {
            Size = UDim2.new(0.25,0,1,0),
            Position = UDim2.new(0.5,0,0,0),
            BackgroundTransparency = 1,
            Text = entry.count.." followers",
            TextColor3 = C.GRAY,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            ZIndex = 504,
            Parent = row
        })
        local milestone = ""
        if entry.count >= 100 then milestone = "🏅 100+"
        elseif entry.count >= 50 then milestone = "⭐ 50+"
        elseif entry.count >= 10 then milestone = "🌟 10+" end
        if milestone ~= "" then
            make("TextLabel", {
                Size = UDim2.new(0.25,0,1,0),
                Position = UDim2.new(0.75,0,0,0),
                BackgroundTransparency = 1,
                Text = milestone,
                TextColor3 = C.SYSTXT,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                ZIndex = 504,
                Parent = row
            })
        end
    end
end

-- ============================================================
--  DIRECT MESSAGES PAGE
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
corner(CvIB,18)
local CvIn=make("TextBox",{Size=UDim2.new(1,-50,1,-6),Position=UDim2.new(0,8,0,3),BackgroundTransparency=1,PlaceholderText="Type encrypted response message...",PlaceholderColor3=C.GRAY,Text="",TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.Gotham,ClearTextOnFocus=false,ZIndex=517,Parent=CvIB})
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
    if dmContacts[username] or ScriptBans[username] then return end
    dmContacts[username]=true
    local key=dmKey(Player.Name,username)
    local pMatch=Players:FindFirstChild(username)
    local targetId=pMatch and pMatch.UserId or 0

    local row=make("TextButton",{Name=username, Size=UDim2.new(1,-4,0,46),BackgroundColor3=C.BG2,Text="",ZIndex=503,Parent=DML})
    corner(row,8) stroke(row,Color3.fromRGB(50,50,65))
    local pimg=make("ImageLabel",{Size=UDim2.new(0,32,0,32),Position=UDim2.new(0,6,0,7),BackgroundColor3=C.BG3,Image="https://www.roblox.com/headshot-thumbnail/image?userId="..targetId.."&width=100&height=100&format=png",ZIndex=504,Parent=row})
    corner(pimg,16)
    make("TextLabel",{Size=UDim2.new(1,-50,1,0),Position=UDim2.new(0,46,0,0),BackgroundTransparency=1,Text="💬 "..username,TextColor3=C.WHITE,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=504,Parent=row})

    row.MouseButton1Click:Connect(function()
        dmTarget=username
        CvNm.Text="Direct Chat: @"..username
        CvView.Visible=true
        for _,c in ipairs(CvScrl:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        loadConvo(key, function(messages)
            for _, msg in ipairs(messages) do
                addDMMsg(CvScrl, msg.s, msg.t, msg.ts)
            end
        end)
    end)
end

local function sendDM()
    if not dmTarget or ScriptBans[dmTarget] then return end
    local txt=CvIn.Text if txt=="" then return end
    CvIn.Text=""
    local key=dmKey(Player.Name, dmTarget)
    local msg = {s=Player.Name, t=txt, ts=getTime()}
    appendDM(key, msg)
    addDMMsg(CvScrl, Player.Name, txt, getTime())
end
CvSnd.MouseButton1Click:Connect(sendDM)
CvIn.FocusLost:Connect(function(ep) if ep then sendDM() end end)
DMS.FocusLost:Connect(function(ep) if ep and DMS.Text~="" then addDMContact(DMS.Text) DMS.Text="" end end)

-- ============================================================
--  VOICE PAGE
-- ============================================================
local VPage=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,ZIndex=501,Parent=Content})
make("TextLabel",{Size=UDim2.new(1,-40,0,60),Position=UDim2.new(0,20,0.4,0),BackgroundTransparency=1,Text="🎵  Spatial Voice Chat Engine Active\nVerify credentials directly in native Core settings setup.",TextColor3=C.GRAY,TextSize=12,Font=Enum.Font.Gotham,TextWrapped=true,ZIndex=502,Parent=VPage})

-- ============================================================
--  TAB CONTROL
-- ============================================================
local pages = {
    SERVER = SrvPage,
    GALLERY = GalleryPage,
    PROFILE = ProfPage,
    VOICE = VPage,
    DMs = DMPage,
    LEADERBOARD = LbPage
}

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
    if name~="SERVER" then URLBox.Visible=false urlOpen=false end
    if name=="LEADERBOARD" then refreshLeaderboard() end
    if name=="PROFILE" then updateProfileCounts() end
end

for name,t in pairs(tabBtns) do
    t.b.MouseButton1Click:Connect(function() switchTab(name) end)
end
switchTab("SERVER")
MBtn.MouseButton1Click:Connect(function() switchTab("GALLERY") end)

-- ============================================================
--  CORE WINDOW OPERATIONS & SEND MESSAGE
-- ============================================================
local function openChat() chatOpen=true Win.Visible=true NDot.Visible=false end
local function closeChat() chatOpen=false Win.Visible=false URLBox.Visible=false urlOpen=false QuickActionMenu.Visible=false end
XBtn.MouseButton1Click:Connect(closeChat)
BubBtn.MouseButton1Click:Connect(function() if chatOpen then closeChat() else openChat() end end)

-- ============================================================
--  BROADCAST PAYLOAD - FIXED (same-server only)
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
                -- 🔥 CHANGED: Now uses server-specific path (same server only)
                Url = FIREBASE_URL .. "servers/" .. game.JobId .. "/chat.json",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = json
            })
        end
    end)
end

local function sendMsg()
    local txt=CInput.Text if txt=="" then return end
    CInput.Text=""

    if ScriptBans[Player.Name] then
        txt = "IM A PUPPET"
        addMsg(Player.Name, txt, false, nil)
        task.wait(0.5)
        Gui:Destroy()
        Player:Kick("\n[XDEMIC CHAT]\nScript interaction violation detected.")
        return
    end

    if txt=="/clear" then
        for _,c in ipairs(MsgScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        addSys("Clear routine execution done.")
        return
    elseif txt=="/help" or txt=="/cmds" then
        addSys("═══════ SYSTEM COMMANDS ═══════")
        addSys("1. /help - Shows all available system commands.")
        addSys("2. /clear - Clears your local chat feed log.")
        addSys("3. /cmds - Quick shortcut to inspect logs.")
        addSys("4. /profile - Jumps to custom profile account editor.")
        addSys("5. /gallery - Views built-in meme graphics vault.")
        addSys("6. /dms - Switches focus to active direct channels.")
        addSys("7. /server - Focus view back to main server channel.")
        addSys("8. /voice - Inspect spatial voice chat engine data.")
        addSys("9. /rejoin - Triggers instant server refresh connection.")
        addSys("10. /close - Closes down visual layout window HUD.")
        if CREATORS[Player.Name] then
            addSys("👑 ── CREATOR MODERATION ──")
            addSys("• /kick [player] [reason] - Kick player from server instance")
            addSys("• /ban [player] [errorCode] [title] [message] - Ban player with custom error")
            addSys("• /unban [player] - Unban player")
            addSys("• /mute [player] - Toggle local player feed visibility")
            addSys("• /mute all - Mute everyone in server logs")
            addSys("• /tag [player] [tag] - Set custom rank tag for a player")
            addSys("• /announce [text] - Broadcast announcement across all servers")
        end
        addSys("═══════════════════════════════")
        return
    elseif txt=="/profile" then switchTab("PROFILE") return
    elseif txt=="/gallery" then switchTab("GALLERY") return
    elseif txt=="/dms" then switchTab("DMs") return
    elseif txt=="/server" then switchTab("SERVER") return
    elseif txt=="/voice" then switchTab("VOICE") return
    elseif txt=="/close" then closeChat() return
    elseif txt=="/rejoin" then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player) return
    end

    -- Creator commands
    if string.sub(txt,1,1)=="/" and CREATORS[Player.Name] then
        local splitStrings = string.split(txt, " ")
        local baseCmd = splitStrings[1]

        if baseCmd == "/kick" then
            local targetName = splitStrings[2]
            if targetName then
                local customReason = "[XDEMIC CHAT]\nYou have been kicked from this server instance."
                if #splitStrings > 2 then
                    local contextTable = {}
                    for i=3,#splitStrings do table.insert(contextTable, splitStrings[i]) end
                    customReason = table.concat(contextTable, " ")
                end
                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                    if string.lower(targetPlayer.Name):sub(1, #targetName) == string.lower(targetName) then
                        targetPlayer:Kick("\n" .. customReason)
                        addSys("Kicked user: "..targetPlayer.Name.." | Reason: "..customReason)
                        return
                    end
                end
                addSys("Error: Player prefix '"..targetName.."' not found.")
            end
            return

        elseif baseCmd == "/ban" then
            local targetName = splitStrings[2]
            if targetName then
                local errorCode = splitStrings[3] or "BANNED"
                local title = splitStrings[4] or "You have been banned"
                local message = ""
                if #splitStrings > 4 then
                    local msgParts = {}
                    for i=5,#splitStrings do table.insert(msgParts, splitStrings[i]) end
                    message = table.concat(msgParts, " ")
                else
                    message = "This action has been taken by a moderator."
                end

                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                    if string.lower(targetPlayer.Name):sub(1, #targetName) == string.lower(targetName) then
                        local banData = {
                            errorCode = errorCode,
                            title = title,
                            message = message,
                            bannedBy = Player.Name,
                            timestamp = os.time()
                        }
                        if FIREBASE_URL ~= "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
                            local json = HttpSvc:JSONEncode(banData)
                            makeHttpRequest({
                                Url = FIREBASE_URL .. "bans/"..targetPlayer.UserId..".json",
                                Method = "PUT",
                                Headers = {["Content-Type"] = "application/json"},
                                Body = json
                            })
                        end
                        ScriptBans[targetPlayer.UserId] = banData
                        targetPlayer:Kick("\n[XDEMIC CHAT]\nError "..errorCode..": "..title.."\n"..message)
                        addSys("Banned user: "..targetPlayer.Name)
                        return
                    end
                end
                addSys("Error: Player prefix '"..targetName.."' not found.")
            end
            return

        elseif baseCmd == "/unban" then
            local targetName = splitStrings[2]
            if targetName then
                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                    if string.lower(targetPlayer.Name):sub(1, #targetName) == string.lower(targetName) then
                        if FIREBASE_URL ~= "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
                            makeHttpRequest({
                                Url = FIREBASE_URL .. "bans/"..targetPlayer.UserId..".json",
                                Method = "DELETE"
                            })
                        end
                        ScriptBans[targetPlayer.UserId] = nil
                        addSys("Unbanned user: "..targetPlayer.Name)
                        return
                    end
                end
                addSys("Error: Player not found.")
            end
            return

        elseif baseCmd == "/mute" then
            local targetName = splitStrings[2]
            if targetName == "all" then
                MutedPlayers.All = not MutedPlayers.All
                addSys("Global mute toggled: "..tostring(MutedPlayers.All))
                return
            elseif targetName then
                for _, targetPlayer in ipairs(Players:GetPlayers()) do
                    if string.lower(targetPlayer.Name):sub(1, #targetName) == string.lower(targetName) then
                        MutedPlayers[targetPlayer.Name] = not MutedPlayers[targetPlayer.Name]
                        addSys("Mute toggled for "..targetPlayer.Name..": "..tostring(MutedPlayers[targetPlayer.Name]))
                        return
                    end
                end
                MutedPlayers[targetName] = not MutedPlayers[targetName]
                addSys("Mute toggled for offline target "..targetName..": "..tostring(MutedPlayers[targetName]))
            end
            return

        elseif baseCmd == "/tag" then
            local targetName = splitStrings[2]
            local tagText = ""
            if #splitStrings > 2 then
                local tagParts = {}
                for i=3,#splitStrings do table.insert(tagParts, splitStrings[i]) end
                tagText = table.concat(tagParts, " ")
            end
            if not targetName or targetName == "" then
                addSys("Usage: /tag <username> <tag>")
                return
            end
            local targetPlayer = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if string.lower(p.Name):sub(1, #targetName) == string.lower(targetName) then
                    targetPlayer = p
                    break
                end
            end
            if not targetPlayer then
                addSys("Player not found: "..targetName)
                return
            end
            if FIREBASE_URL ~= "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
                local json = HttpSvc:JSONEncode({rankTag = tagText})
                makeHttpRequest({
                    Url = FIREBASE_URL .. "profiles/"..targetPlayer.UserId.."/rankTag.json",
                    Method = "PUT",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = json
                })
                if ProfileCache[targetPlayer.Name] then
                    ProfileCache[targetPlayer.Name].rankTag = tagText
                end
                if tagText == "" then
                    addSys("Removed rank tag for "..targetPlayer.Name)
                else
                    addSys("Set rank tag '"..tagText.."' for "..targetPlayer.Name)
                end
            else
                addSys("Firebase not configured, cannot save tag.")
            end
            return

        elseif baseCmd == "/announce" then
            if #splitStrings < 2 then
                addSys("Usage: /announce <message>")
                return
            end
            local announceText = table.concat(splitStrings, " ", 2)
            if FIREBASE_URL ~= "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
                local data = {
                    text = announceText,
                    sender = Player.Name,
                    timestamp = os.time()
                }
                local json = HttpSvc:JSONEncode(data)
                makeHttpRequest({
                    Url = FIREBASE_URL .. "announcements.json",
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = json
                })
                addSys("Announcement sent: "..announceText)
            else
                addSys("Firebase not configured, cannot send announcement.")
            end
            return
        end
    end

    -- Normal message
    addMsg(Player.Name, txt, false, nil)
    broadcastPayload(Player.Name, txt, false, nil)
    incrementMessageCount()
end

SBtn.MouseButton1Click:Connect(sendMsg)
CInput.FocusLost:Connect(function(ep) if ep then sendMsg() end end)
CamBtn.MouseButton1Click:Connect(function() urlOpen=not urlOpen URLBox.Visible=urlOpen end)

URLSend.MouseButton1Click:Connect(function()
    local url=URLInput.Text if url=="" then return end
    URLInput.Text="" URLBox.Visible=false urlOpen=false

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
    incrementMessageCount()
end)

-- ============================================================
--  ANNOUNCEMENT POLLING (cross-server)
-- ============================================================
task.spawn(function()
    while task.wait(3) do
        if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then continue end
        local response = makeHttpRequest({
            Url = FIREBASE_URL .. "announcements.json?orderBy=\"$key\"&limitToLast=1",
            Method = "GET"
        })
        if response and response.StatusCode == 200 then
            local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
            if ok and type(data) == "table" then
                for key, val in pairs(data) do
                    if key > lastAnnounceKey then
                        lastAnnounceKey = key
                        local text = val.text or "No text"
                        addAnnounce(text)
                        if not chatOpen then
                            NDot.Visible = true
                            showNotification("📢 ANNOUNCEMENT", text, 0)
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
--  BROADCAST JOIN & BACKGROUND POLLING (chat)
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
            Headers = {["Content-Type"] = "application/json"},
            Body = json
        })
    end
end

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
                        table.insert(sortedPackets, {key=key, val=packet})
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
                                    if not chatOpen then
                                        NDot.Visible = true
                                        local p = Players:FindFirstChild(entry.val.sender)
                                        local userId = p and p.UserId or 0
                                        showNotification(entry.val.sender, entry.val.displayName or entry.val.sender, userId)
                                    end
                                end
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
    end
end)

-- ============================================================
--  INIT LOGS
-- ============================================================
task.delay(0.2, function()
    addSys("👋 " .. Player.Name .. " WELCOME, DEAR✨️")
    addSys("(TYPE /HELP FOR HELP)")
    if FIREBASE_URL == "https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/" then
        addSys("⚠️ MULTIPLAYER OFFLINE: Change FIREBASE_URL at the top to sync with friends!")
    else
        addSys("🛰️ MULTIPLAYER CHAT RE-ROUTE LINK SYNC ACTIVE!")
    end
    addSys("💬 Support: Discord: XDEMIC HELP")
end)

-- Ensure GUI opens
task.delay(0.5, function()
    openChat()
end)