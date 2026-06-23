--[[
    XDEMIC CHAT v15.0 – Kick Removed | Delta Executor Ready
    No external dependencies – runs on any executor.
--]]

local Players = game:GetService("Players")
local TweenSvc = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local HttpSvc = game:GetService("HttpService")
local Player = Players.LocalPlayer

-- ============================================================
--  CONFIGURATION
-- ============================================================
local FIREBASE_URL = ""  -- Set your Firebase URL here for multiplayer sync (optional)

-- ============================================================
--  UNIVERSAL HTTP REQUEST WRAPPER (works on all executors)
-- ============================================================
local function makeHttpRequest(options)
    local req = (syn and syn.request) or http_request or request or (http and http.request)
    if req then
        local success, response = pcall(req, options)
        if success then return response end
    end
    return nil
end

-- ============================================================
--  HELPER FUNCTIONS
-- ============================================================
local function make(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    return o
end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

local function stroke(p, col, t)
    local s = Instance.new("UIStroke")
    s.Color = col or Color3.fromRGB(55,55,70)
    s.Thickness = t or 1
    s.Parent = p
end

local function ll(p, dir, sp)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, sp or 4)
    l.Parent = p
end

local function tw(o, t, pr)
    TweenSvc:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), pr):Play()
end

local function getTime()
    local t = os.date("*t")
    return string.format("%02d:%02d", t.hour, t.min)
end

-- ============================================================
--  COLORS
-- ============================================================
local C = {
    WIN    = Color3.fromRGB(30,30,36),
    BG2    = Color3.fromRGB(38,38,46),
    BG3    = Color3.fromRGB(50,50,60),
    TABBAR = Color3.fromRGB(20,20,25),
    INPUT  = Color3.fromRGB(28,28,35),
    BLUE   = Color3.fromRGB(30,120,255),
    SYSBG  = Color3.fromRGB(70,56,8),
    SYSTXT = Color3.fromRGB(255,208,35),
    WHITE  = Color3.fromRGB(255,255,255),
    GRAY   = Color3.fromRGB(135,135,152),
    ME     = Color3.fromRGB(42,42,54),
    THEM   = Color3.fromRGB(42,42,54),
    RED    = Color3.fromRGB(200,48,48),
    GREEN  = Color3.fromRGB(28,185,82),
    GOLD   = Color3.fromRGB(255,215,0),
}

-- ============================================================
--  CREATOR LIST
-- ============================================================
local CREATORS = {
    ["DAVID_BLOX65"] = true,
    ["viraat_shukla18"] = true,
    ["XxClumy_huywr3"] = true,
    ["Hey_ImLexi70"] = true,
    ["VENUS_EDIT"] = true,
}
local function isCreator(name) return CREATORS[name] or false end

-- ============================================================
--  MILESTONE TAGS
-- ============================================================
local MILESTONE_TAGS = {
    {name="🎯", label="Newbie", xp=0},
    {name="⭐", label="Rookie", xp=50},
    {name="🌟", label="Rising Star", xp=150},
    {name="🔥", label="On Fire", xp=300},
    {name="💎", label="Diamond", xp=500},
    {name="👑", label="Royal", xp=800},
    {name="⚡", label="Legend", xp=1200},
    {name="🌊", label="Wave Rider", xp=1800},
    {name="🚀", label="Rocket", xp=2500},
    {name="🌌", label="Cosmic", xp=3500},
    {name="🪐", label="Galactic", xp=5000},
    {name="🌠", label="Stellar", xp=7500},
    {name="🌈", label="Rainbow", xp=10000},
    {name="🏆", label="Champion", xp=15000},
    {name="💀", label="Reaper", xp=20000},
    {name="👾", label="Alien", xp=30000},
    {name="🔥", label="Phoenix", xp=50000},
    {name="👑", label="Emperor", xp=100000},
}

local function getAvailableTags(xp)
    local available = {}
    for _, tag in ipairs(MILESTONE_TAGS) do
        if xp >= tag.xp then table.insert(available, tag) end
    end
    return available
end

-- ============================================================
--  PROFILE DATA
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
        if FIREBASE_URL ~= "" then
            -- broadcast to Firebase (optional)
            local broadcastData = {
                name = Player.Name,
                displayName = ClientProfileData.DisplayName,
                xp = ClientProfileData.XP,
                level = ClientProfileData.Level,
                followers = #FollowSystem.Followers,
                profileImage = ClientProfileData.ProfileImage,
            }
            local success, json = pcall(function() return HttpSvc:JSONEncode(broadcastData) end)
            if success then
                makeHttpRequest({
                    Url = FIREBASE_URL .. "profiles/"..Player.Name..".json",
                    Method = "PUT",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = json,
                })
            end
        end
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
    -- Refresh tags based on XP
    local available = getAvailableTags(ClientProfileData.XP)
    if isCreator(Player.Name) then
        ClientProfileData.Tags = {}
        for _, tag in ipairs(MILESTONE_TAGS) do
            table.insert(ClientProfileData.Tags, tag.name.." "..tag.label)
        end
    else
        ClientProfileData.Tags = {}
        for _, tag in ipairs(available) do
            table.insert(ClientProfileData.Tags, tag.name.." "..tag.label)
        end
    end
    saveProfileData()
end

local function addXP(amount)
    ClientProfileData.XP = ClientProfileData.XP + amount
    ClientProfileData.Level = math.floor(ClientProfileData.XP / 100) + 1
    loadProfileData() -- refresh tags
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
    local already = false
    for i, name in ipairs(FollowSystem.Following) do
        if name == targetName then
            table.remove(FollowSystem.Following, i)
            already = true
            break
        end
    end
    if not already then
        table.insert(FollowSystem.Following, targetName)
    end
    FollowSystem.FollowCount = #FollowSystem.Following
    saveFollowData()
    return not already
end

-- ============================================================
--  BAN SYSTEM (Kick removed)
-- ============================================================
local ScriptBans = {}
local MutedPlayers = { All = false }

local BanMessages = {
    ["ERR_001"] = {title="🚫 Account Suspended", message="Suspended for violating guidelines."},
    ["ERR_005"] = {title="🛡️ Protection Shield", message="Banned by a creator/mod."},
}

local function banPlayer(targetName, errorCode, customMsg)
    ScriptBans[targetName] = true
    local info = BanMessages[errorCode] or BanMessages["ERR_005"]
    if targetName == Player.Name then
        task.delay(1, function()
            Player:Kick("\n["..info.title.."]\n"..(customMsg or info.message).."\nCode: "..errorCode)
        end)
    end
end

local function unbanPlayer(targetName)
    ScriptBans[targetName] = nil
end

-- ============================================================
--  TRANSLATE & COPY
-- ============================================================
local function translateText(text, targetLang)
    if not text or text == "" then return text end
    local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl="..targetLang.."&dt=t&q="..HttpSvc:URLEncode(text)
    local response = makeHttpRequest({Url = url, Method = "GET"})
    if response and response.StatusCode == 200 then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
        if ok and data and data[1] and data[1][1] then
            return data[1][1][1]
        end
    end
    return text
end

local function copyText(text)
    local tb = make("TextBox", {Text=text, Size=UDim2.new(0,1,0,1), BackgroundTransparency=1, TextTransparency=1, Parent=Gui})
    tb:CaptureFocus() tb:ReleaseFocus() tb:Destroy()
end

-- ============================================================
--  UI CREATION
-- ============================================================
local Gui = make("ScreenGui", {Name="XdemicChat", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling, IgnoreGuiInset=true})
Gui.Parent = Player.PlayerGui

-- ============================================================
--  TOAST NOTIFICATION
-- ============================================================
local ToastHolder = make("Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Parent=Gui, ZIndex=999})
local function showToast(title, text, icon)
    local toast = make("Frame", {Size=UDim2.new(0,260,0,70), Position=UDim2.new(1,300,1,-100), BackgroundColor3=C.BG2, Parent=ToastHolder, ZIndex=1000})
    corner(toast, 10) stroke(toast, Color3.fromRGB(80,80,100), 1.2)
    local iconLabel = make("TextLabel", {Size=UDim2.new(0,44,0,44), Position=UDim2.new(0,10,0.5,-22), BackgroundTransparency=1, Text=icon or "💬", TextSize=28, Font=Enum.Font.GothamBold, Parent=toast, ZIndex=1001})
    local t1 = make("TextLabel", {Size=UDim2.new(1,-70,0,20), Position=UDim2.new(0,62,0,10), BackgroundTransparency=1, Text=title, TextColor3=C.WHITE, TextSize=13, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, Parent=toast, ZIndex=1001})
    local t2 = make("TextLabel", {Size=UDim2.new(1,-70,0,30), Position=UDim2.new(0,62,0,28), BackgroundTransparency=1, Text=text, TextColor3=C.GRAY, TextSize=11, Font=Enum.Font.Gotham, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, Parent=toast, ZIndex=1001})
    tw(toast, 0.35, {Position=UDim2.new(1,-270,1,-100)})
    task.delay(4, function()
        tw(toast, 0.3, {Position=UDim2.new(1,300,1,-100)})
        task.wait(0.3) toast:Destroy()
    end)
end

-- ============================================================
--  DRAG MODULE
-- ============================================================
local dragTargets, activeDrag, dragStart, dragPos = {}, nil, Vector2.new(), UDim2.new()
local function makeDraggable(handle, target)
    table.insert(dragTargets, {h=handle, t=target})
end
UIS.InputBegan:Connect(function(inp)
    if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
    local pos = Vector2.new(inp.Position.X, inp.Position.Y)
    for _,dt in ipairs(dragTargets) do
        local a=dt.h.AbsolutePosition; local s=dt.h.AbsoluteSize
        if pos.X>=a.X and pos.X<=a.X+s.X and pos.Y>=a.Y and pos.Y<=a.Y+s.Y then
            activeDrag=dt.t; dragStart=pos; dragPos=dt.t.Position; break
        end
    end
end)
UIS.InputChanged:Connect(function(inp)
    if not activeDrag then return end
    if inp.UserInputType~=Enum.UserInputType.MouseMovement and inp.UserInputType~=Enum.UserInputType.Touch then return end
    local d = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
    activeDrag.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset+d.X, dragPos.Y.Scale, dragPos.Y.Offset+d.Y)
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then activeDrag=nil end
end)

-- ============================================================
--  BUBBLE BUTTON
-- ============================================================
local BubFrame = make("Frame", {Size=UDim2.new(0,54,0,54), Position=UDim2.new(1,-68,1,-92), BackgroundColor3=Color3.fromRGB(45,45,55), BackgroundTransparency=0.08, ZIndex=800, Parent=Gui})
corner(BubFrame,27) stroke(BubFrame, Color3.fromRGB(80,100,200), 1.5)
local Glow = make("Frame", {Size=UDim2.new(1,14,1,14), Position=UDim2.new(0,-7,0,-7), BackgroundColor3=C.BLUE, BackgroundTransparency=0.75, ZIndex=799, Parent=BubFrame})
corner(Glow,34)
local BubBtn = make("TextButton", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="💬", TextSize=26, Font=Enum.Font.GothamBold, TextColor3=C.WHITE, ZIndex=801, Parent=BubFrame})
local NDot = make("Frame", {Size=UDim2.new(0,14,0,14), Position=UDim2.new(1,-4,0,-4), BackgroundColor3=C.RED, Visible=false, ZIndex=802, Parent=BubFrame})
corner(NDot,7)
makeDraggable(BubFrame, BubFrame)

-- ============================================================
--  CHAT WINDOW
-- ============================================================
local chatOpen = false
local urlOpen = false
local currentTab = "SERVER"

local Win = make("Frame", {Size=UDim2.new(0,380,0,320), Position=UDim2.new(0.5,-190,0.5,-160), BackgroundColor3=C.WIN, BackgroundTransparency=0.28, Visible=false, ZIndex=500, Parent=Gui})
corner(Win,16) stroke(Win, Color3.fromRGB(58,58,76), 1.5)
local DragHandle = make("Frame", {Size=UDim2.new(1,-36,0,44), BackgroundTransparency=1, ZIndex=501, Parent=Win})
local XBtn = make("TextButton", {Size=UDim2.new(0,24,0,24), Position=UDim2.new(1,-30,0,10), BackgroundColor3=C.RED, Text="✕", TextColor3=C.WHITE, TextSize=13, Font=Enum.Font.GothamBold, ZIndex=502, Parent=Win})
corner(XBtn,7)

-- Tabs
local TabBar = make("Frame", {Size=UDim2.new(1,0,0,44), BackgroundColor3=C.TABBAR, BackgroundTransparency=0.15, ZIndex=501, Parent=Win})
corner(TabBar,16)
make("Frame", {Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,1,-16), BackgroundColor3=C.TABBAR, BackgroundTransparency=0.15, BorderSizePixel=0, ZIndex=501, Parent=TabBar})
local TabScroll = make("ScrollingFrame", {Size=UDim2.new(1,-34,1,0), BackgroundTransparency=1, ScrollBarThickness=0, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.X, ZIndex=502, Parent=TabBar})
ll(TabScroll, Enum.FillDirection.Horizontal, 0)

local TABS = {{name="SERVER", icon="🌐"},{name="GALLERY", icon="🖼"},{name="PROFILE", icon="⚙️"},{name="VOICE", icon="🎵"},{name="DMs", icon="💬"},{name="LEADERBOARD", icon="🏆"}}
local tabBtns = {}
for i,t in ipairs(TABS) do
    local btn = make("TextButton", {Size=UDim2.new(0,84,1,0), BackgroundTransparency=1, Text=t.icon.." "..t.name, TextSize=10, Font=Enum.Font.GothamBold, TextColor3=C.GRAY, ZIndex=503, LayoutOrder=i, Parent=TabScroll})
    local ul = make("Frame", {Size=UDim2.new(0,50,0,2), Position=UDim2.new(0.5,-25,1,-2), BackgroundColor3=C.BLUE, BackgroundTransparency=1, ZIndex=503, Parent=btn})
    tabBtns[t.name] = {b=btn, ul=ul}
end

local Content = make("Frame", {Size=UDim2.new(1,0,1,-44), Position=UDim2.new(0,0,0,44), BackgroundTransparency=1, ClipsDescendants=true, ZIndex=501, Parent=Win})

-- SERVER PAGE
local SrvPage = make("Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ZIndex=501, Parent=Content})
local MsgScroll = make("ScrollingFrame", {Size=UDim2.new(1,-6,1,-56), Position=UDim2.new(0,3,0,3), BackgroundTransparency=1, ScrollBarThickness=2, ScrollBarImageColor3=C.BLUE, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, ZIndex=502, Parent=SrvPage})
ll(MsgScroll, Enum.FillDirection.Vertical, 5)
make("UIPadding", {PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6), PaddingTop=UDim.new(0,4), Parent=MsgScroll})

local IBar = make("Frame", {Size=UDim2.new(1,-10,0,48), Position=UDim2.new(0,5,1,-52), BackgroundColor3=C.INPUT, BackgroundTransparency=0.1, ZIndex=503, Parent=SrvPage})
corner(IBar,24) stroke(IBar, Color3.fromRGB(58,58,76), 1)
local CInput = make("TextBox", {Size=UDim2.new(1,-120,1,-8), Position=UDim2.new(0,14,0,4), BackgroundTransparency=1, PlaceholderText="iMessage Z-Chat...", PlaceholderColor3=C.GRAY, Text="", TextColor3=C.WHITE, TextSize=13, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, ClearTextOnFocus=false, ZIndex=504, Parent=IBar})
local CamBtn = make("TextButton", {Size=UDim2.new(0,32,0,32), Position=UDim2.new(1,-112,0.5,-16), BackgroundTransparency=1, Text="📷", TextSize=22, ZIndex=504, Parent=IBar})
local MBtn = make("TextButton", {Size=UDim2.new(0,32,0,32), Position=UDim2.new(1,-74,0.5,-16), BackgroundTransparency=1, Text="🌸", TextSize=22, ZIndex=504, Parent=IBar})
local SBtn = make("TextButton", {Size=UDim2.new(0,40,0,40), Position=UDim2.new(1,-46,0.5,-20), BackgroundColor3=C.BLUE, Text="↑", TextColor3=C.WHITE, TextSize=24, Font=Enum.Font.GothamBold, ZIndex=504, Parent=IBar})
corner(SBtn,20)

local URLBox = make("Frame", {Size=UDim2.new(1,-10,0,64), Position=UDim2.new(0,5,1,-124), BackgroundColor3=C.BG2, Visible=false, ZIndex=510, Parent=SrvPage})
corner(URLBox,10) stroke(URLBox, Color3.fromRGB(55,55,72))
local URLInput = make("TextBox", {Size=UDim2.new(1,-80,0,32), Position=UDim2.new(0,5,0,28), BackgroundColor3=C.INPUT, PlaceholderText="rbxassetid://... or https://...", PlaceholderColor3=C.GRAY, Text="", TextColor3=C.WHITE, TextSize=11, Font=Enum.Font.Gotham, ClearTextOnFocus=false, ZIndex=511, Parent=URLBox})
corner(URLInput,6)
local URLSend = make("TextButton", {Size=UDim2.new(0,68,0,32), Position=UDim2.new(1,-73,0,28), BackgroundColor3=C.BLUE, Text="Send 📷", TextColor3=C.WHITE, TextSize=11, Font=Enum.Font.GothamBold, ZIndex=511, Parent=URLBox})
corner(URLSend,6)

-- ============================================================
--  CHAT MESSAGE FUNCTIONS
-- ============================================================
local function addSys(text)
    local f = make("Frame", {Size=UDim2.new(1,-4,0,42), BackgroundColor3=C.SYSBG, BackgroundTransparency=0.1, ZIndex=503, Parent=MsgScroll})
    corner(f,8) stroke(f, Color3.fromRGB(115,90,10))
    make("TextLabel", {Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,7,0,0), BackgroundTransparency=1, Text="⚠ [SYSTEM] : "..text, TextColor3=C.SYSTXT, TextSize=12, Font=Enum.Font.GothamBold, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=504, Parent=f})
    task.delay(0.05, function() MsgScroll.CanvasPosition = Vector2.new(0, MsgScroll.AbsoluteCanvasSize.Y) end)
end

-- BXD-style bubble (overhead)
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

    local displayName = (sender == Player.Name) and ClientProfileData.DisplayName or (p.DisplayName or sender)
    local uid = p.UserId or 0
    local profileImage = "https://www.roblox.com/headshot-thumbnail/image?userId="..uid.."&width=100&height=100&format=png"

    local bb = make("BillboardGui", {Size=UDim2.new(0,280,0,130), StudsOffset=Vector3.new(0,4.2,0), AlwaysOnTop=true, Adornee=head, Parent=head, ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
    local mainFrame = make("Frame", {Size=UDim2.new(1,0,1,-12), BackgroundColor3=C.WIN, BackgroundTransparency=0.1, ZIndex=2, Parent=bb})
    corner(mainFrame,12) stroke(mainFrame, Color3.fromRGB(80,80,120), 1.5)
    local gradient = make("Frame", {Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(50,50,70), BackgroundTransparency=0.3, ZIndex=1, Parent=mainFrame})
    corner(gradient,12)
    local glow = make("Frame", {Size=UDim2.new(1,20,1,20), Position=UDim2.new(0,-10,0,-10), BackgroundColor3=C.BLUE, BackgroundTransparency=0.9, ZIndex=0, Parent=bb})
    corner(glow,20)
    local tail = make("ImageLabel", {Size=UDim2.new(0,20,0,14), Position=UDim2.new(0.5,-10,1,-14), BackgroundTransparency=1, Image="rbxassetid://6034226343", ImageColor3=C.WIN, ZIndex=3, Parent=bb})

    local content = make("Frame", {Size=UDim2.new(1,-8,1,-8), Position=UDim2.new(0,4,0,4), BackgroundTransparency=1, ZIndex=4, Parent=mainFrame})
    ll(content, Enum.FillDirection.Vertical, 4)

    -- Header
    local header = make("Frame", {Size=UDim2.new(1,0,0,28), BackgroundTransparency=1, LayoutOrder=1, Parent=content})
    local hLayout = make("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6), VerticalAlignment=Enum.VerticalAlignment.Center, Parent=header})
    local pfp = make("ImageLabel", {Size=UDim2.new(0,24,0,24), BackgroundColor3=C.BG3, Image=profileImage, LayoutOrder=1, Parent=header})
    corner(pfp,12)
    local nameLabel = make("TextLabel", {Size=UDim2.new(0,150,0,24), BackgroundTransparency=1, Text=displayName, TextColor3=C.WHITE, TextSize=13, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=2, Parent=header})
    if isCreator(sender) then
        local creatorTag = make("TextLabel", {Size=UDim2.new(0,60,0,24), BackgroundTransparency=1, Text="👑 CREATOR", TextColor3=C.GOLD, TextSize=11, Font=Enum.Font.GothamBold, LayoutOrder=3, Parent=header})
    end

    -- Tags (if any)
    local rawTags = Player.PlayerGui:GetAttribute("XdemicProfileData_"..sender)
    local tags = {}
    if rawTags then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(rawTags) end)
        if ok and data and data.tags then tags = data.tags end
    end
    if #tags > 0 then
        local tagsFrame = make("Frame", {Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, LayoutOrder=2, Parent=content})
        local tLayout = make("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,4), Parent=tagsFrame})
        for i=1, math.min(3, #tags) do
            local tagLabel = make("TextLabel", {Size=UDim2.new(0,40,0,18), BackgroundColor3=Color3.fromRGB(60,60,80), Text=tags[i], TextColor3=C.WHITE, TextSize=10, Font=Enum.Font.GothamBold, LayoutOrder=i, Parent=tagsFrame})
            corner(tagLabel,9)
        end
    end

    -- Message
    local msgFrame = make("Frame", {Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, LayoutOrder=3, Parent=content})
    if isImg then
        local imgDisplay = make("ImageLabel", {Size=UDim2.new(0,80,0,80), BackgroundColor3=C.BG3, Image=imgUrl, LayoutOrder=1, Parent=msgFrame})
        corner(imgDisplay,6)
    else
        local msgLabel = make("TextLabel", {Size=UDim2.new(1,-8,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, Text=text, TextColor3=C.WHITE, TextSize=12, Font=Enum.Font.Gotham, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=1, Parent=msgFrame})
    end

    headBubbles[sender] = bb
    -- animate in
    mainFrame.BackgroundTransparency = 1
    tw(mainFrame, 0.3, {BackgroundTransparency=0.1})
    tw(glow, 0.3, {BackgroundTransparency=0.85, Size=UDim2.new(1,30,1,30), Position=UDim2.new(0,-15,0,-15)})
    task.delay(8, function()
        if bb and bb.Parent then
            tw(mainFrame,0.4,{BackgroundTransparency=1})
            tw(tail,0.4,{ImageTransparency=1})
            tw(glow,0.4,{BackgroundTransparency=1})
            task.delay(0.4, function() bb:Destroy() if headBubbles[sender]==bb then headBubbles[sender]=nil end end)
        end
    end)
end

local function addMsg(sender, text, isImg, imgUrl, overrideDisplayName)
    if ScriptBans[sender] then
        if sender == Player.Name then Gui:Destroy(); Player:Kick("\n[XDEMIC CHAT]\nViolation.") end
        return
    end
    if MutedPlayers.All or MutedPlayers[sender] then return end

    local isMe = (sender == Player.Name)
    local pObj = Players:FindFirstChild(sender)
    local uid = pObj and pObj.UserId or 0
    local currentDisplayName = overrideDisplayName or (isMe and ClientProfileData.DisplayName or (pObj and pObj.DisplayName or sender))

    local wrap = make("Frame", {Size=UDim2.new(1,-4,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1, ZIndex=503, Parent=MsgScroll})
    local hLayout = make("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,10), VerticalAlignment=Enum.VerticalAlignment.Top, Parent=wrap})
    local av = make("ImageButton", {Size=UDim2.new(0,36,0,36), BackgroundColor3=C.BG3, Image="https://www.roblox.com/headshot-thumbnail/image?userId="..uid.."&width=100&height=100&format=png", LayoutOrder=1, ZIndex=504, Parent=wrap})
    corner(av,18)
    av.MouseButton1Click:Connect(function() openQuickAction(sender, UIS:GetMouseLocation()) end)

    local bub = make("Frame", {Size=isImg and UDim2.new(0,140,0,140) or UDim2.new(0.82,-46,0,0), AutomaticSize=isImg and Enum.AutomaticSize.None or Enum.AutomaticSize.Y, BackgroundColor3=C.THEM, BackgroundTransparency=0.08, LayoutOrder=2, ZIndex=504, Parent=wrap})
    corner(bub,12)
    if isImg then
        local imgLabel = make("ImageLabel", {Size=UDim2.new(1,-8,1,-8), Position=UDim2.new(0,4,0,4), BackgroundTransparency=1, Image=imgUrl, ZIndex=505, Parent=bub})
        corner(imgLabel,8)
    else
        local lbl = make("TextLabel", {Size=UDim2.new(1,-16,0,0), AutomaticSize=Enum.AutomaticSize.Y, Position=UDim2.new(0,8,0,6), BackgroundTransparency=1, Text="", RichText=true, TextColor3=C.WHITE, TextSize=13, Font=Enum.Font.Gotham, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=505, Parent=bub})
        if isCreator(sender) then
            lbl.Text = "👑 "..currentDisplayName..": "..text
        else
            lbl.Text = "<b>"..currentDisplayName..":</b> "..text
        end
        make("Frame", {Size=UDim2.new(1,0,0,12), BackgroundTransparency=1, ZIndex=504, Parent=bub})
        bub.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton2 then
                showCtx(text, UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y)
            end
        end)
    end

    task.delay(0.05, function() MsgScroll.CanvasPosition = Vector2.new(0, MsgScroll.AbsoluteCanvasSize.Y) end)
    showBubble(sender, text, isImg, imgUrl)
end

-- ============================================================
--  GALLERY PAGE
-- ============================================================
local GalleryPage = make("Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Visible=false, ZIndex=501, Parent=Content})
local GScroll = make("ScrollingFrame", {Size=UDim2.new(1,-6,1,-12), Position=UDim2.new(0,3,0,6), BackgroundTransparency=1, ScrollBarThickness=4, ScrollBarImageColor3=C.BLUE, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, ZIndex=502, Parent=GalleryPage})
make("UIGridLayout", {CellSize=UDim2.new(0,104,0,104), CellPadding=UDim2.new(0,12,0,12), Parent=GScroll})

local function appendToMemeGalleryGrid(url, label)
    local cell = make("ImageButton", {Size=UDim2.new(0,104,0,104), BackgroundColor3=C.BG3, ScaleType=Enum.ScaleType.Stretch, ZIndex=503, Parent=GScroll})
    corner(cell,10) stroke(cell, Color3.fromRGB(55,55,75))
    cell.Image = url  -- we don't cache, just use URL
    local tip = make("TextLabel", {Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,1,-20), BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0.4, Text=label, TextColor3=C.WHITE, TextSize=10, Font=Enum.Font.GothamBold, ZIndex=504, Parent=cell})
    cell.MouseButton1Click:Connect(function()
        addMsg(Player.Name, "", true, url)
        if FIREBASE_URL ~= "" then broadcastPayload(Player.Name, "", true, url) end
        switchTab("SERVER")
    end)
end

local MEMES = {
    {url="https://cdn.discordapp.com/attachments/1487337813039906850/1509446357545390151/0136db63e4832b04191dc4ec6f192ec9.jpg?ex=6a1934f7&is=6a17e377&hm=1cc3d4ffa69be5cf5b6e27c7686304f3d93e439f1b970d246fdb6a759c701dfc&", label="genz kiddo🥀"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509626881052250142/3d44ba854fce0b5fdbfe5f34cb222e52.jpg?ex=6a19dd17&is=6a188b97&hm=3b5ac50e31e228132b49426dacdd025eba512dfe71895764f6b2960dfabe0607&", label="idk"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509628653150146591/Screenshot_20260529_001301_Roblox.jpg?ex=6a19debe&is=6a188d3e&hm=4374cb767be58c97e536a5ad7fe20883d7e13601209eeea4813bf4840ec20f40&", label="shocked dog"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509628653418446868/Screenshot_20260529_001245_Roblox.jpg?ex=6a19debe&is=6a188d3e&hm=926c27d1ef3902401fd6b60654812d3495d366518a6a51abf9fa8573a6df8ef6&", label="big black lips"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509909880855859251/Screenshot_20260529_184001_Roblox.jpg?ex=6a1ae4a8&is=6a199328&hm=d12022142b809a4d62021e1011102e44b04419b9c85fa1cce18309f0c639b9a4&", label="roblox wilding 💀"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509909880121589760/Screenshot_20260529_184040_Roblox.jpg?ex=6a1ae4a8&is=6a199328&hm=873f25684a50fd9159c85584a6d713ac4c144817ea34ccf36ec34eafcfab80b7&", label="fit check 🔥"},
    {url="https://cdn.discordapp.com/attachments/1494973168547270677/1509909879685386411/Screenshot_20260529_184057_Roblox.jpg?ex=6a1ae4a8&is=6a199328&hm=06608b4557c3a921c8d86492d334dd82249fecc1989201f70c657fad6c37d98a&", label="no cap 🧢"},
}
for _,m in ipairs(MEMES) do appendToMemeGalleryGrid(m.url, m.label) end

-- ============================================================
--  PROFILE PAGE
-- ============================================================
local ProfPage = make("Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Visible=false, ZIndex=501, Parent=Content})
make("TextLabel", {Size=UDim2.new(1,0,0,24), Position=UDim2.new(0,0,0,6), BackgroundTransparency=1, Text="✏️  EDIT ACCOUNT PROFILE", TextColor3=C.WHITE, TextSize=14, Font=Enum.Font.GothamBold, ZIndex=502, Parent=ProfPage})

local AvF = make("Frame", {Size=UDim2.new(0,70,0,70), Position=UDim2.new(0.5,-35,0,32), BackgroundColor3=C.BLUE, ZIndex=502, Parent=ProfPage})
corner(AvF,35)
local AvI = make("ImageLabel", {Size=UDim2.new(1,-4,1,-4), Position=UDim2.new(0,2,0,2), BackgroundTransparency=1, Image=ClientProfileData.ProfileImage, ZIndex=503, Parent=AvF})
corner(AvI,33)

local dynamicNameLabel = make("TextLabel", {Size=UDim2.new(1,-12,0,18), Position=UDim2.new(0,6,0,108), BackgroundTransparency=1, Text="Showing Profile: "..ClientProfileData.DisplayName, TextColor3=C.SYSTXT, TextSize=11, Font=Enum.Font.GothamBold, ZIndex=502, Parent=ProfPage})

local function mkBox(ph, y, h)
    local b = make("TextBox", {Size=UDim2.new(1,-14,0,h or 34), Position=UDim2.new(0,7,0,y), BackgroundColor3=C.BG3, BackgroundTransparency=0.15, PlaceholderText=ph, PlaceholderColor3=C.GRAY, Text="", TextColor3=C.WHITE, TextSize=12, Font=Enum.Font.Gotham, ClearTextOnFocus=false, ZIndex=502, Parent=ProfPage})
    corner(b,8) stroke(b, Color3.fromRGB(50,50,68))
    return b
end
local DIn = mkBox("Change Display name...",132); DIn.Text = ClientProfileData.DisplayName
local BIn = mkBox("Write profile bio description...",170,54); BIn.MultiLine = true
local PImageIn = mkBox("Profile Image URL or Roblox User ID...",230,34); PImageIn.Text = ClientProfileData.ProfileImage or ""
local PImageBtn = make("TextButton", {Size=UDim2.new(0,80,0,34), Position=UDim2.new(1,-88,0,230), BackgroundColor3=C.BLUE, Text="Set Image", TextColor3=C.WHITE, TextSize=10, Font=Enum.Font.GothamBold, ZIndex=502, Parent=ProfPage})
corner(PImageBtn,6)
PImageBtn.MouseButton1Click:Connect(function()
    local input = PImageIn.Text
    if input and input ~= "" then
        if tonumber(input) then
            ClientProfileData.ProfileImage = "https://www.roblox.com/headshot-thumbnail/image?userId="..input.."&width=150&height=150&format=png"
            ClientProfileData.RobloxId = tonumber(input)
        elseif string.match(input, "http") then
            ClientProfileData.ProfileImage = input
        else
            ClientProfileData.ProfileImage = "https://www.roblox.com/headshot-thumbnail/image?userId="..Player.UserId.."&width=150&height=150&format=png"
        end
        AvI.Image = ClientProfileData.ProfileImage
        saveProfileData()
        addSys("Profile image updated.")
    end
end)

local SvB = make("TextButton", {Size=UDim2.new(1,-14,0,38), Position=UDim2.new(0,7,0,280), BackgroundColor3=C.BLUE, Text="APPLY CHANGES & SYNC", TextColor3=C.WHITE, TextSize=12, Font=Enum.Font.GothamBold, ZIndex=502, Parent=ProfPage})
corner(SvB,10)
SvB.MouseButton1Click:Connect(function()
    if DIn.Text ~= "" then
        ClientProfileData.DisplayName = DIn.Text
        ClientProfileData.Bio = BIn.Text
        dynamicNameLabel.Text = "Showing Profile: "..ClientProfileData.DisplayName
        saveProfileData()
        addSys("Profile saved.")
        tw(SvB,0.1,{BackgroundColor3=C.GREEN})
        task.delay(0.5, function() tw(SvB,0.2,{BackgroundColor3=C.BLUE}) end)
    end
end)

-- ============================================================
--  DMs PAGE
-- ============================================================
local DMPage = make("Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Visible=false, ZIndex=501, Parent=Content})
local DML = make("ScrollingFrame", {Size=UDim2.new(1,-6,1,-60), Position=UDim2.new(0,3,0,30), BackgroundTransparency=1, ScrollBarThickness=2, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, ZIndex=502, Parent=DMPage})
ll(DML, Enum.FillDirection.Vertical, 4)
local DMS = make("TextBox", {Size=UDim2.new(1,-6,0,32), Position=UDim2.new(0,3,1,-34), BackgroundColor3=C.INPUT, PlaceholderText="🔍  Search username to direct message...", PlaceholderColor3=C.GRAY, Text="", TextColor3=C.WHITE, TextSize=12, Font=Enum.Font.Gotham, ClearTextOnFocus=false, ZIndex=502, Parent=DMPage})
corner(DMS,16)

local CvView = make("Frame", {Size=UDim2.new(1,0,1,0), BackgroundColor3=C.WIN, BackgroundTransparency=0.05, Visible=false, ZIndex=515, Parent=DMPage})
local CvBack = make("TextButton", {Size=UDim2.new(0,62,0,26), Position=UDim2.new(0,4,0,4), BackgroundColor3=C.BG3, Text="← Back", TextColor3=C.WHITE, TextSize=11, Font=Enum.Font.GothamBold, ZIndex=516, Parent=CvView})
corner(CvBack,6)
local CvNm = make("TextLabel", {Size=UDim2.new(1,-80,0,26), Position=UDim2.new(0,72,0,4), BackgroundTransparency=1, Text="DM Target User", TextColor3=C.WHITE, TextSize=12, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=516, Parent=CvView})
local CvScrl = make("ScrollingFrame", {Size=UDim2.new(1,-6,1,-72), Position=UDim2.new(0,3,0,36), BackgroundTransparency=1, ScrollBarThickness=2, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, ZIndex=516, Parent=CvView})
ll(CvScrl, Enum.FillDirection.Vertical, 4)
local CvIB = make("Frame", {Size=UDim2.new(1,-6,0,36), Position=UDim2.new(0,3,1,-38), BackgroundColor3=C.INPUT, ZIndex=516, Parent=CvView})
corner(CvIB,18)
local CvIn = make("TextBox", {Size=UDim2.new(1,-50,1,-6), Position=UDim2.new(0,8,0,3), BackgroundTransparency=1, PlaceholderText="Type response...", PlaceholderColor3=C.GRAY, Text="", TextColor3=C.WHITE, TextSize=12, Font=Enum.Font.Gotham, ClearTextOnFocus=false, ZIndex=517, Parent=CvIB})
local CvSnd = make("TextButton", {Size=UDim2.new(0,30,0,30), Position=UDim2.new(1,-34,0.5,-15), BackgroundColor3=C.BLUE, Text="↑", TextColor3=C.WHITE, TextSize=15, Font=Enum.Font.GothamBold, ZIndex=517, Parent=CvIB})
corner(CvSnd,15)

CvBack.MouseButton1Click:Connect(function() CvView.Visible=false; dmTarget=nil end)

local dmContacts = {}
local DM_STORE = {}
local function dmKey(a,b) local t={a,b} table.sort(t) return t[1].."__"..t[2] end
local function saveConvo(key)
    local ok, enc = pcall(function() return HttpSvc:JSONEncode(DM_STORE[key] or {}) end)
    if ok then pcall(function() Player.PlayerGui:SetAttribute("XD_"..key, enc) end) end
end
local function loadConvo(key)
    if DM_STORE[key] then return DM_STORE[key] end
    local raw = Player.PlayerGui:GetAttribute("XD_"..key)
    if raw then
        local ok, dec = pcall(function() return HttpSvc:JSONDecode(raw) end)
        if ok and dec then DM_STORE[key] = dec; return dec end
    end
    DM_STORE[key] = {}; return {}
end
local function appendDM(key, msg)
    if not DM_STORE[key] then loadConvo(key) end
    table.insert(DM_STORE[key], msg)
    if #DM_STORE[key] > 200 then
        local trim = {}
        for i=#DM_STORE[key]-199, #DM_STORE[key] do table.insert(trim, DM_STORE[key][i]) end
        DM_STORE[key] = trim
    end
    saveConvo(key)
end

local function addDMMsg(scroll, sender, text, ts)
    if ScriptBans[sender] then return end
    local isMe = (sender == Player.Name)
    local b = make("Frame", {Size=UDim2.new(0.76,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, Position=isMe and UDim2.new(0.24,0,0,0) or UDim2.new(0,0,0,0), BackgroundColor3=isMe and C.ME or C.THEM, ZIndex=520, Parent=scroll})
    corner(b,10)
    local l = make("TextLabel", {Size=UDim2.new(1,-10,0,0), AutomaticSize=Enum.AutomaticSize.Y, Position=UDim2.new(0,5,0,5), BackgroundTransparency=1, Text=text, TextColor3=C.WHITE, TextSize=12, Font=Enum.Font.Gotham, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=521, Parent=b})
    make("Frame", {Size=UDim2.new(1,0,0,12), BackgroundTransparency=1, ZIndex=520, Parent=b})
    task.delay(0.05, function() scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y) end)
end

function addDMContact(username)
    if dmContacts[username] or ScriptBans[username] then return end
    dmContacts[username] = true
    local key = dmKey(Player.Name, username)
    local pMatch = Players:FindFirstChild(username)
    local targetId = pMatch and pMatch.UserId or 0
    local row = make("TextButton", {Name=username, Size=UDim2.new(1,-4,0,46), BackgroundColor3=C.BG2, Text="", ZIndex=503, Parent=DML})
    corner(row,8) stroke(row, Color3.fromRGB(50,50,65))
    local pimg = make("ImageLabel", {Size=UDim2.new(0,32,0,32), Position=UDim2.new(0,6,0,7), BackgroundColor3=C.BG3, Image="https://www.roblox.com/headshot-thumbnail/image?userId="..targetId.."&width=100&height=100&format=png", ZIndex=504, Parent=row})
    corner(pimg,16)
    make("TextLabel", {Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,46,0,0), BackgroundTransparency=1, Text="💬 "..username, TextColor3=C.WHITE, TextSize=12, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=504, Parent=row})
    row.MouseButton1Click:Connect(function()
        dmTarget = username
        CvNm.Text = "Direct Chat: @"..username
        CvView.Visible = true
        for _,c in ipairs(CvScrl:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        for _,msg in ipairs(loadConvo(key)) do addDMMsg(CvScrl, msg.s, msg.t, msg.ts) end
    end)
end

local function sendDM()
    if not dmTarget or ScriptBans[dmTarget] then return end
    local txt = CvIn.Text
    if txt == "" then return end
    CvIn.Text = ""
    local key = dmKey(Player.Name, dmTarget)
    appendDM(key, {s=Player.Name, t=txt, ts=getTime()})
    addDMMsg(CvScrl, Player.Name, txt, getTime())
end
CvSnd.MouseButton1Click:Connect(sendDM)
CvIn.FocusLost:Connect(function(ep) if ep then sendDM() end end)
DMS.FocusLost:Connect(function(ep) if ep and DMS.Text ~= "" then addDMContact(DMS.Text); DMS.Text="" end end)

-- VOICE PAGE
local VPage = make("Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Visible=false, ZIndex=501, Parent=Content})
make("TextLabel", {Size=UDim2.new(1,-40,0,60), Position=UDim2.new(0,20,0.4,0), BackgroundTransparency=1, Text="🎵  Spatial Voice Chat Engine Active\nVerify credentials directly in native Core settings.", TextColor3=C.GRAY, TextSize=12, Font=Enum.Font.Gotham, TextWrapped=true, ZIndex=502, Parent=VPage})

-- ============================================================
--  LEADERBOARD PAGE
-- ============================================================
local LeaderboardPage = make("Frame", {Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Visible=false, ZIndex=501, Parent=Content})
make("TextLabel", {Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, Text="🏆 LEADERBOARD", TextColor3=C.WHITE, TextSize=14, Font=Enum.Font.GothamBold, Parent=LeaderboardPage})
local LBScroll = make("ScrollingFrame", {Size=UDim2.new(1,-6,1,-38), Position=UDim2.new(0,3,0,34), BackgroundTransparency=1, ScrollBarThickness=2, ScrollBarImageColor3=C.BLUE, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, Parent=LeaderboardPage})
ll(LBScroll, Enum.FillDirection.Vertical, 2)

local function updateLeaderboard()
    for _, child in ipairs(LBScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    if FIREBASE_URL == "" then
        make("TextLabel", {Size=UDim2.new(1,0,0,60), BackgroundTransparency=1, Text="⚠️ Firebase not configured.\nSet FIREBASE_URL for leaderboard sync.", TextColor3=C.GRAY, TextSize=12, Font=Enum.Font.Gotham, TextWrapped=true, Parent=LBScroll})
        return
    end
    local response = makeHttpRequest({Url = FIREBASE_URL .. "profiles.json?orderBy=\"xp\"&limitToLast=20", Method = "GET"})
    if response and response.StatusCode == 200 then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
        if ok and type(data) == "table" then
            local sorted = {}
            for name, info in pairs(data) do
                table.insert(sorted, {name=name, info=info})
            end
            table.sort(sorted, function(a,b) return (a.info.xp or 0) > (b.info.xp or 0) end)
            for i, entry in ipairs(sorted) do
                local row = make("Frame", {Size=UDim2.new(1,-4,0,32), BackgroundColor3=(i%2==0) and Color3.fromRGB(45,45,55) or Color3.fromRGB(50,50,60), BackgroundTransparency=0.3, Parent=LBScroll})
                corner(row,6)
                local rank = make("TextLabel", {Size=UDim2.new(0,30,1,0), BackgroundTransparency=1, Text=(i<=3) and {"🥇","🥈","🥉"}[i] or "#"..i, TextColor3=C.WHITE, TextSize=12, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Center, Parent=row})
                local nameLabel = make("TextLabel", {Size=UDim2.new(0,90,1,0), Position=UDim2.new(0,34,0,0), BackgroundTransparency=1, Text=entry.info.displayName or entry.name, TextColor3=C.WHITE, TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, Parent=row})
                local stats = make("TextLabel", {Size=UDim2.new(0,90,1,0), Position=UDim2.new(1,-94,0,0), BackgroundTransparency=1, Text="⭐"..(entry.info.xp or 0).."  👥"..(entry.info.followers or 0), TextColor3=C.GRAY, TextSize=10, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Right, Parent=row})
                local followBtn = make("TextButton", {Size=UDim2.new(0,50,1,-4), Position=UDim2.new(1,-148,0,2), BackgroundColor3=C.BLUE, Text="Follow", TextColor3=C.WHITE, TextSize=10, Font=Enum.Font.GothamBold, Parent=row})
                corner(followBtn,4)
                if entry.name == Player.Name then followBtn.Visible = false else
                    local isFollowing = false
                    for _, f in ipairs(FollowSystem.Following) do if f == entry.name then isFollowing = true break end end
                    followBtn.Text = isFollowing and "Unfollow" or "Follow"
                    followBtn.BackgroundColor3 = isFollowing and C.RED or C.BLUE
                    followBtn.MouseButton1Click:Connect(function()
                        local now = followPlayer(entry.name)
                        followBtn.Text = now and "Unfollow" or "Follow"
                        followBtn.BackgroundColor3 = now and C.RED or C.BLUE
                        showToast("Follow", now and "You followed "..entry.name or "You unfollowed "..entry.name, now and "✅" or "❌")
                        updateLeaderboard()
                    end)
                end
            end
        end
    end
end

-- ============================================================
--  QUICK ACTION & CONTEXT MENU
-- ============================================================
local QuickActionMenu = make("Frame", {Size=UDim2.new(0,140,0,66), BackgroundColor3=C.BG2, Visible=false, ZIndex=990, Parent=Gui})
corner(QuickActionMenu,8) stroke(QuickActionMenu, Color3.fromRGB(70,70,95), 1.5)
local qaTargetName = ""
local qaDmBtn = make("TextButton", {Size=UDim2.new(1,0,0,32), BackgroundTransparency=1, Text="💬  Start DM", TextColor3=C.WHITE, TextSize=12, Font=Enum.Font.GothamBold, ZIndex=991, Parent=QuickActionMenu})
make("Frame", {Size=UDim2.new(1,-10,0,1), Position=UDim2.new(0,5,0,32), BackgroundColor3=Color3.fromRGB(60,60,80), ZIndex=991, Parent=QuickActionMenu})
local qaCloseBtn = make("TextButton", {Size=UDim2.new(1,0,0,32), Position=UDim2.new(0,0,0,33), BackgroundTransparency=1, Text="✕  Cancel", TextColor3=C.RED, TextSize=12, Font=Enum.Font.GothamBold, ZIndex=991, Parent=QuickActionMenu})
qaCloseBtn.MouseButton1Click:Connect(function() QuickActionMenu.Visible = false end)

local function openQuickAction(targetUser, pos)
    if targetUser == Player.Name or ScriptBans[targetUser] then return end
    qaTargetName = targetUser
    QuickActionMenu.Position = UDim2.new(0, math.min(pos.X, Gui.AbsoluteSize.X - 145), 0, math.min(pos.Y, Gui.AbsoluteSize.Y - 70))
    QuickActionMenu.Visible = true
end
qaDmBtn.MouseButton1Click:Connect(function()
    QuickActionMenu.Visible = false
    addDMContact(qaTargetName)
    switchTab("DMs")
    for _, item in ipairs(DML:GetChildren()) do
        if item:IsA("TextButton") and item.Name == qaTargetName then
            dmTarget = qaTargetName
            CvNm.Text="Direct Chat: @"..qaTargetName
            CvView.Visible=true
            local key=dmKey(Player.Name, qaTargetName)
            for _,c in ipairs(CvScrl:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
            for _,msg in ipairs(loadConvo(key)) do addDMMsg(CvScrl,msg.s,msg.t,msg.ts) end
            break
        end
    end
end)

-- Context Menu
local CtxMenu = make("Frame", {Size=UDim2.new(0,150,0,96), BackgroundColor3=C.BG2, Visible=false, ZIndex=950, Parent=Gui})
corner(CtxMenu,8) stroke(CtxMenu, Color3.fromRGB(60,60,80), 1)
local ctxCopy = make("TextButton", {Size=UDim2.new(1,0,0,31), BackgroundTransparency=1, Text="  📋  Copy", TextColor3=C.WHITE, TextSize=12, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=951, Parent=CtxMenu})
make("Frame", {Size=UDim2.new(1,-10,0,1), Position=UDim2.new(0,5,0,31), BackgroundColor3=Color3.fromRGB(60,60,80), ZIndex=951, Parent=CtxMenu})
local ctxTrans = make("TextButton", {Size=UDim2.new(1,0,0,31), Position=UDim2.new(0,0,0,33), BackgroundTransparency=1, Text="  🌐  Translate (EN)", TextColor3=C.WHITE, TextSize=12, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=951, Parent=CtxMenu})
make("Frame", {Size=UDim2.new(1,-10,0,1), Position=UDim2.new(0,5,0,64), BackgroundColor3=Color3.fromRGB(60,60,80), ZIndex=951, Parent=CtxMenu})
local ctxClose = make("TextButton", {Size=UDim2.new(1,0,0,31), Position=UDim2.new(0,0,0,65), BackgroundTransparency=1, Text="  ✕  Close", TextColor3=C.RED, TextSize=12, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=951, Parent=CtxMenu})

local ctxText = ""
local function showCtx(text, x, y)
    ctxText = text
    local sw = Gui.AbsoluteSize.X
    local sh = Gui.AbsoluteSize.Y
    CtxMenu.Position = UDim2.new(0, math.min(x, sw-155), 0, math.min(y, sh-100))
    CtxMenu.Visible = true
end
ctxCopy.MouseButton1Click:Connect(function() copyText(ctxText); CtxMenu.Visible = false end)
ctxTrans.MouseButton1Click:Connect(function()
    local translated = translateText(ctxText, "en")
    if translated and translated ~= ctxText then addSys("Translated: "..translated) else addSys("Translation failed.") end
    CtxMenu.Visible = false
end)
ctxClose.MouseButton1Click:Connect(function() CtxMenu.Visible = false end)

UIS.InputBegan:Connect(function(inp)
    if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.Touch then return end
    if CtxMenu.Visible then
        local a=CtxMenu.AbsolutePosition; local s=CtxMenu.AbsoluteSize; local p=inp.Position
        if p.X<a.X or p.X>a.X+s.X or p.Y<a.Y or p.Y>a.Y+s.Y then CtxMenu.Visible=false end
    end
    if QuickActionMenu.Visible then
        local a=QuickActionMenu.AbsolutePosition; local s=QuickActionMenu.AbsoluteSize; local p=inp.Position
        if p.X<a.X or p.X>a.X+s.X or p.Y<a.Y or p.Y>a.Y+s.Y then QuickActionMenu.Visible=false end
    end
end)

-- ============================================================
--  TAB SWITCHING
-- ============================================================
local pages = {SERVER=SrvPage, GALLERY=GalleryPage, PROFILE=ProfPage, VOICE=VPage, DMs=DMPage, LEADERBOARD=LeaderboardPage}
function switchTab(name)
    currentTab = name
    for n, pg in pairs(pages) do pg.Visible = (n == name) end
    for n, t in pairs(tabBtns) do
        if n == name then
            tw(t.b, 0.1, {TextColor3=C.WHITE})
            tw(t.ul, 0.1, {BackgroundTransparency=0})
        else
            tw(t.b, 0.1, {TextColor3=C.GRAY})
            tw(t.ul, 0.1, {BackgroundTransparency=1})
        end
    end
    if name == "LEADERBOARD" then updateLeaderboard() end
    if name ~= "SERVER" then URLBox.Visible = false; urlOpen = false end
end
for name, t in pairs(tabBtns) do
    t.b.MouseButton1Click:Connect(function() switchTab(name) end)
end
switchTab("SERVER")
MBtn.MouseButton1Click:Connect(function() switchTab("GALLERY") end)

-- ============================================================
--  OPEN/CLOSE CHAT
-- ============================================================
local function openChat() chatOpen=true; Win.Visible=true; NDot.Visible=false end
local function closeChat() chatOpen=false; Win.Visible=false; URLBox.Visible=false; urlOpen=false; QuickActionMenu.Visible=false end
XBtn.MouseButton1Click:Connect(closeChat)
BubBtn.MouseButton1Click:Connect(function() if chatOpen then closeChat() else openChat() end end)

-- ============================================================
--  SEND MESSAGE
-- ============================================================
local function broadcastPayload(sender, text, isImg, imgUrl)
    if FIREBASE_URL == "" then return end
    task.spawn(function()
        local data = {sender=sender, displayName=ClientProfileData.DisplayName, text=text, isImg=isImg, imgUrl=imgUrl or "", timestamp=os.time()}
        local success, json = pcall(function() return HttpSvc:JSONEncode(data) end)
        if success then
            makeHttpRequest({Url = FIREBASE_URL .. "global_chat.json", Method="POST", Headers={["Content-Type"]="application/json"}, Body=json})
        end
    end)
end

local function sendMsg()
    local txt = CInput.Text
    if txt == "" then return end
    CInput.Text = ""

    if ScriptBans[Player.Name] then
        addMsg(Player.Name, "IM A PUPPET", false, nil)
        task.wait(0.5)
        Gui:Destroy()
        Player:Kick("\n[XDEMIC CHAT]\nViolation.")
        return
    end

    -- System commands
    if txt == "/clear" then
        for _,c in ipairs(MsgScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        addSys("Cleared.")
        return
    elseif txt == "/help" or txt == "/cmds" then
        addSys("═══════ COMMANDS ═══════")
        addSys("/clear, /profile, /gallery, /dms, /server, /voice, /close, /rejoin, /leaderboard")
        addSys("/follow <user>, /unfollow <user>")
        if isCreator(Player.Name) then
            addSys("👑 CREATOR: /ban <user> [errorCode] [msg]  - e.g. /ban Dave ERR_005 Banned!")
            addSys("/unban <user>")
            addSys("/mute <user> or /mute all")
        end
        addSys("═════════════════════════")
        return
    elseif txt == "/profile" then switchTab("PROFILE") return
    elseif txt == "/gallery" then switchTab("GALLERY") return
    elseif txt == "/dms" then switchTab("DMs") return
    elseif txt == "/server" then switchTab("SERVER") return
    elseif txt == "/voice" then switchTab("VOICE") return
    elseif txt == "/close" then closeChat() return
    elseif txt == "/rejoin" then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, Player) return
    elseif txt == "/leaderboard" then switchTab("LEADERBOARD") return
    elseif string.sub(txt, 1, 8) == "/follow " then
        local target = string.sub(txt, 9)
        if target and target ~= "" then
            local result = followPlayer(target)
            addSys(result and "You followed "..target or "You unfollowed "..target)
        end
        return
    elseif string.sub(txt, 1, 10) == "/unfollow " then
        local target = string.sub(txt, 11)
        if target and target ~= "" then followPlayer(target); addSys("Unfollowed "..target) end
        return
    end

    -- Creator commands (Kick removed)
    if string.sub(txt, 1, 1) == "/" and isCreator(Player.Name) then
        local parts = string.split(txt, " ")
        local cmd = parts[1]
        if cmd == "/ban" then
            local target = parts[2]
            local code = parts[3] or "ERR_005"
            local msg = table.concat(parts, " ", 4)
            if target then
                banPlayer(target, code, msg)
                addSys("Banned "..target.." (Code: "..code..")")
            end
            return
        elseif cmd == "/unban" then
            local target = parts[2]
            if target then unbanPlayer(target); addSys("Unbanned "..target) end
            return
        elseif cmd == "/mute" then
            local target = parts[2]
            if target == "all" then
                MutedPlayers.All = not MutedPlayers.All
                addSys("Global mute: "..tostring(MutedPlayers.All))
            elseif target then
                for _, p in ipairs(Players:GetPlayers()) do
                    if string.lower(p.Name):sub(1, #target) == string.lower(target) then
                        MutedPlayers[p.Name] = not MutedPlayers[p.Name]
                        addSys("Mute "..p.Name..": "..tostring(MutedPlayers[p.Name]))
                        return
                    end
                end
                MutedPlayers[target] = not MutedPlayers[target]
                addSys("Mute "..target..": "..tostring(MutedPlayers[target]))
            end
            return
        end
    end

    -- Normal message
    addXP(1)
    addMsg(Player.Name, txt, false, nil)
    broadcastPayload(Player.Name, txt, false, nil)
end

SBtn.MouseButton1Click:Connect(sendMsg)
CInput.FocusLost:Connect(function(ep) if ep then sendMsg() end end)
CamBtn.MouseButton1Click:Connect(function() urlOpen = not urlOpen; URLBox.Visible = urlOpen end)

URLSend.MouseButton1Click:Connect(function()
    local url = URLInput.Text
    if url == "" then return end
    URLInput.Text = ""; URLBox.Visible = false; urlOpen = false
    if ScriptBans[Player.Name] then
        addMsg(Player.Name, "IM A PUPPET", false, nil)
        task.wait(0.5)
        Gui:Destroy()
        Player:Kick("\n[XDEMIC CHAT]\nViolation.")
        return
    end
    addMsg(Player.Name, "", true, url)
    broadcastPayload(Player.Name, "", true, url)
    -- Save to gallery cache (optional)
    local cache = Player.PlayerGui:GetAttribute("XdemicUserGalleryCache")
    local list = {}
    if cache and cache ~= "" then
        local ok, data = pcall(function() return HttpSvc:JSONDecode(cache) end)
        if ok and type(data) == "table" then list = data end
    end
    table.insert(list, url)
    local ok, enc = pcall(function() return HttpSvc:JSONEncode(list) end)
    if ok then Player.PlayerGui:SetAttribute("XdemicUserGalleryCache", enc) end
end)

-- ============================================================
--  INIT
-- ============================================================
loadProfileData()
addSys("👋 Welcome, "..Player.Name)
addSys("Type /help for commands")
if FIREBASE_URL == "" then
    addSys("⚠️ Multiplayer disabled (set FIREBASE_URL)")
else
    addSys("🛰️ Multiplayer sync active")
end
addSys("🏆 XP system active – send messages to earn tags!")

-- ============================================================
--  FIREBASE BACKGROUND POLLING (optional)
-- ============================================================
if FIREBASE_URL ~= "" then
    task.spawn(function()
        local lastKey = ""
        while task.wait(2) do
            local response = makeHttpRequest({Url = FIREBASE_URL .. "global_chat.json?orderBy=\"$key\"&limitToLast=10", Method="GET"})
            if response and response.StatusCode == 200 then
                local ok, data = pcall(function() return HttpSvc:JSONDecode(response.Body) end)
                if ok and type(data) == "table" then
                    local sorted = {}
                    for k, v in pairs(data) do table.insert(sorted, {key=k, val=v}) end
                    table.sort(sorted, function(a,b) return a.key < b.key end)
                    for _, entry in ipairs(sorted) do
                        if entry.key > lastKey then
                            lastKey = entry.key
                            if entry.val.sender ~= Player.Name then
                                addMsg(entry.val.sender, entry.val.text, entry.val.isImg, entry.val.imgUrl, entry.val.displayName)
                                if not chatOpen then NDot.Visible = true end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================================
--  END OF SCRIPT
-- ============================================================