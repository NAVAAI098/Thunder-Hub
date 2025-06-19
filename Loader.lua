-- ✅ Platoboost Key GUI + File Save + Countdown + Device Lock

local service = 4533 -- Platoboost Service ID
local secret = "9c62309a-dbc3-4d85-bf6d-c38127ca6999"
local useNonce = true

local submitBtn, getKeyBtn, exitBtn, keyBox, gui

local function showPopup(messageMain, messageSub, isError)
    local popupGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
    popupGui.Name = "NotificationPopup"

    local frame = Instance.new("Frame", popupGui)
    frame.AnchorPoint = Vector2.new(1, 1)
    frame.Position = UDim2.new(1, -20, 1, -20)
    frame.Size = UDim2.new(0, 320, 0, 70)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.ZIndex = 10
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local icon = Instance.new("TextLabel", frame)
    icon.Position = UDim2.new(0, 10, 0, 12)
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Text = isError and "❌" or "✅"
    icon.TextColor3 = isError and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 255, 100)
    icon.Font = Enum.Font.SourceSansBold
    icon.TextSize = 28
    icon.BackgroundTransparency = 1
    icon.ZIndex = 11

    local title = Instance.new("TextLabel", frame)
    title.Position = UDim2.new(0, 50, 0, 5)
    title.Size = UDim2.new(1, -60, 0, 30)
    title.Text = messageMain or "แจ้งเตือน"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.BackgroundTransparency = 1
    title.ZIndex = 11

    local detail = Instance.new("TextLabel", frame)
    detail.Position = UDim2.new(0, 50, 0, 35)
    detail.Size = UDim2.new(1, -60, 0, 20)
    detail.Text = messageSub or ""
    detail.TextColor3 = Color3.fromRGB(220, 220, 220)
    detail.Font = Enum.Font.SourceSans
    detail.TextSize = 16
    detail.TextXAlignment = Enum.TextXAlignment.Left
    detail.BackgroundTransparency = 1
    detail.ZIndex = 11

    task.delay(4, function()
        if popupGui then popupGui:Destroy() end
    end)
end

local onMessage = function(message)
    showPopup("🔔 ระบบแจ้งเตือน", message, false)
end

repeat task.wait(1) until game:IsLoaded() and game.Players.LocalPlayer

local requestSending = false
local fSetClipboard = setclipboard or toclipboard
local fRequest = request or http_request
local fStringChar, fToString, fStringSub = string.char, tostring, string.sub
local fOsTime, fMathRandom, fMathFloor = os.time, math.random, math.floor
local fGetHwid = function() return tostring(game.Players.LocalPlayer.UserId) end
local HttpService = game:GetService("HttpService")

local function lEncode(data) return HttpService:JSONEncode(data) end
local function lDecode(data) return HttpService:JSONDecode(data) end
local function lDigest(input)
    local hash = {}
    for i = 1, #tostring(input) do
        table.insert(hash, string.byte(input, i))
    end
    local hex = ""
    for _, byte in ipairs(hash) do
        hex = hex .. string.format("%02x", byte)
    end
    return hex:sub(1, 64)
end

local host = "https://api.platoboost.com"
local response = fRequest({ Url = host .. "/public/connectivity", Method = "GET" })
if response.StatusCode ~= 200 and response.StatusCode ~= 429 then
    host = "https://api.platoboost.net"
end

-- File Key System
local keyFileName = "PlatoboostKey-" .. fGetHwid() .. ".txt"
local fReadFile = readfile or function() return nil end
local fWriteFile = writefile or function() end
local fDeleteFile = delfile or function() end

local function parseSavedKey()
    if isfile and isfile(keyFileName) then
        local content = fReadFile(keyFileName)
        local key, expireAt = string.match(content, "(.+)|(.+)")
        if key and expireAt then
            local now = os.time()
            local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)Z"
            local y, m, d, h, min, s = expireAt:match(pattern)
            local expireTime = os.time({
                year = tonumber(y), month = tonumber(m), day = tonumber(d),
                hour = tonumber(h), min = tonumber(min), sec = tonumber(s)
            })
            if now < expireTime then
                return key, expireTime
            else
                fDeleteFile(keyFileName)
            end
        end
    end
    return nil
end

local function generateNonce()
    local nonce = ""
    for _ = 1, 16 do
        nonce = nonce .. fStringChar(fMathFloor(fMathRandom() * 26) + 97)
    end
    return nonce
end

function redeemKey(key)
    local nonce = generateNonce()
    local body = {
        identifier = lDigest(fGetHwid()),
        key = key:sub(1, 100)
    }
    if useNonce then body.nonce = nonce end

    local res = fRequest({
        Url = host .. "/public/redeem/" .. service,
        Method = "POST",
        Body = lEncode(body),
        Headers = { ["Content-Type"] = "application/json" }
    })

    if res.StatusCode == 200 then
        local decoded = lDecode(res.Body)
        return decoded.success and decoded.data.valid
    end
    return false
end

function verifyKey(key)
    if requestSending then onMessage("กรุณารอสักครู่...") return false end
    requestSending = true

    local nonce = generateNonce()
    local url = host .. "/public/whitelist/" .. service .. "?identifier=" .. lDigest(fGetHwid()) .. "&key=" .. key:sub(1, 100)
    if useNonce then url = url .. "&nonce=" .. nonce end

    local res = fRequest({ Url = url, Method = "GET" })
    requestSending = false

    if res.StatusCode == 200 then
        local decoded = lDecode(res.Body)
        if decoded.success and decoded.data.valid then return true end
        if key:sub(1, 5) == "FREE_" then return redeemKey(key) end
    end
    return false
end

local function cacheLink()
    local res = fRequest({
        Url = host .. "/public/start",
        Method = "POST",
        Body = lEncode({ service = service, identifier = lDigest(fGetHwid()) }),
        Headers = { ["Content-Type"] = "application/json" }
    })
    if res.StatusCode == 200 then
        local decoded = lDecode(res.Body)
        if decoded.success then
            return true, decoded.data.url
        else
            onMessage(decoded.message)
        end
    end
    return false, ""
end

local function copyLink()
    local ok, link = cacheLink()
    if ok and fSetClipboard then
        fSetClipboard(link)
        showPopup("📗 คัดลอกลิงก์แล้ว", "นำไปวางในเบราว์เซอร์เพื่อรับ Key", false)
    end
end

-- 🟢 เรียกหลัง verifyKey ถูกนิยามแล้ว
local savedKey, savedExpire = parseSavedKey()
if savedKey then
    if verifyKey(savedKey) then
        showPopup("✅ Key ยังไม่หมดอายุ", "กำลังโหลดสคริปต์...", false)
        task.delay(1, function()
            loadstring(game:HttpGet("https://pastebin.com/raw/DTrES0c6"))()
        end)
        return
    else
        fDeleteFile(keyFileName)
    end
end

-- GUI เริ่มที่นี่
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
gui = Instance.new("ScreenGui", playerGui)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 500, 0, 200)
frame.Position = UDim2.new(0.5, -250, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local image = Instance.new("ImageLabel", frame)
image.Size = UDim2.new(0, 100, 0, 100)
image.Position = UDim2.new(0, 10, 0, 20)
image.BackgroundTransparency = 1
image.Image = "rbxassetid://106076048327121"

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(0, 300, 0, 30)
title.Position = UDim2.new(0, 120, 0, 20)
title.Text = "Thunder'Hub"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 24
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left

local subtext = Instance.new("TextLabel", frame)
subtext.Size = UDim2.new(0, 300, 0, 20)
subtext.Position = UDim2.new(0, 120, 0, 55)
subtext.Text = "Get Key for 8 hours."
subtext.TextColor3 = Color3.fromRGB(200, 200, 200)
subtext.Font = Enum.Font.SourceSans
subtext.TextSize = 18
subtext.BackgroundTransparency = 1
subtext.TextXAlignment = Enum.TextXAlignment.Left

local discordText = Instance.new("TextLabel", frame)
discordText.Size = UDim2.new(0, 250, 0, 20)
discordText.Position = UDim2.new(1, -260, 0, 5)
discordText.Text = "discord.gg/Unw78DARDb"
discordText.TextColor3 = Color3.fromRGB(150, 150, 255)
discordText.Font = Enum.Font.SourceSansItalic
discordText.TextSize = 14
discordText.BackgroundTransparency = 1
discordText.TextXAlignment = Enum.TextXAlignment.Right

local liveCountdown = Instance.new("TextLabel", frame)
liveCountdown.Size = UDim2.new(0, 250, 0, 20)
liveCountdown.Position = UDim2.new(1, -260, 0, 25)
liveCountdown.TextColor3 = Color3.fromRGB(255, 255, 180)
liveCountdown.Font = Enum.Font.SourceSansItalic
liveCountdown.TextSize = 14
liveCountdown.BackgroundTransparency = 1
liveCountdown.TextXAlignment = Enum.TextXAlignment.Right

local function updateCountdown()
    task.spawn(function()
        while gui and gui.Parent do
            local expire = savedExpire or (os.time() + 8 * 3600)
            local remain = math.max(0, expire - os.time())
            local hrs = math.floor(remain / 3600)
            local mins = math.floor((remain % 3600) / 60)
            local secs = remain % 60
            liveCountdown.Text = string.format("⏳ เหลือเวลา: %02d:%02d:%02d", hrs, mins, secs)
            task.wait(1)
        end
    end)
end
updateCountdown()

keyBox = Instance.new("TextBox", frame)
keyBox.Size = UDim2.new(0, 300, 0, 30)
keyBox.Position = UDim2.new(0, 120, 0, 80)
keyBox.PlaceholderText = "Enter Key..."
keyBox.Text = ""
keyBox.Font = Enum.Font.SourceSans
keyBox.TextSize = 18
keyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
keyBox.TextColor3 = Color3.new(1, 1, 1)
keyBox.BorderSizePixel = 0
Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 8)

getKeyBtn = Instance.new("TextButton", frame)
getKeyBtn.Size = UDim2.new(0, 180, 0, 35)
getKeyBtn.Position = UDim2.new(0, 120, 1, -45)
getKeyBtn.Text = "🔑 Get Key 8 Hours. (Free)"
getKeyBtn.Font = Enum.Font.SourceSans
getKeyBtn.TextSize = 18
getKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
getKeyBtn.TextColor3 = Color3.new(1, 1, 1)
getKeyBtn.BorderSizePixel = 0
Instance.new("UICorner", getKeyBtn).CornerRadius = UDim.new(0, 8)

submitBtn = Instance.new("TextButton", frame)
submitBtn.Size = UDim2.new(0, 100, 0, 35)
submitBtn.Position = UDim2.new(0, 310, 1, -45)
submitBtn.Text = "Submit ✅"
submitBtn.Font = Enum.Font.SourceSans
submitBtn.TextSize = 18
submitBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
submitBtn.TextColor3 = Color3.new(1, 1, 1)
submitBtn.BorderSizePixel = 0
Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 8)

exitBtn = Instance.new("TextButton", frame)
exitBtn.Size = UDim2.new(0, 100, 0, 35)
exitBtn.Position = UDim2.new(0, 10, 1, -45)
exitBtn.Text = "← Exit"
exitBtn.Font = Enum.Font.SourceSans
exitBtn.TextSize = 18
exitBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
exitBtn.TextColor3 = Color3.new(1, 1, 1)
exitBtn.BorderSizePixel = 0
Instance.new("UICorner", exitBtn).CornerRadius = UDim.new(0, 8)

submitBtn.MouseButton1Click:Connect(function()
    local key = keyBox.Text
    if key == "" or key == nil then
        showPopup("❌ กรุณาใส่ Key", "โปรดกรอก Key ก่อนกด Submit", true)
        return
    end

    if verifyKey(key) then
        local expireTime = os.time() + 8 * 3600
        local expireIso = os.date("!%Y-%m-%dT%H:%M:%SZ", expireTime)
        fWriteFile(keyFileName, key .. "|" .. expireIso)
        showPopup("✅ Key ถูกต้อง", "กำลังโหลดสคริปต์...", false)
        task.delay(1, function()
            gui:Destroy()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/NAVAAI098/Thunder-Hub/refs/heads/main/Jump%20Tower"))()
        end)
    else
        showPopup("❌ Key ไม่ถูกต้อง", "กรุณาตรวจสอบ Key ของคุณอีกครั้ง", true)
    end
end)

getKeyBtn.MouseButton1Click:Connect(copyLink)
exitBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
