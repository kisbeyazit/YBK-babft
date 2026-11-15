-- Voltra Prototype Engine (Core Script)
-- Made with Love by Vyrusspcs

_G.X = _G.X or {}
local X = _G.X

local libSuccess, libResult = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Vyrusspcs/weshkyv2/refs/heads/main/server/libtest.lua"))()
end)
X.library = libSuccess and libResult or nil

local listSuccess, listResult = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Vyrusspcs/weshkyv2/refs/heads/main/server/listing.lua"))()
end)
X.listing = listSuccess and listResult or nil

local colorSuccess, colorResult = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Vyrusspcs/weshkyv2/refs/heads/main/special/extras/blockcolors.lua"))()
end)
local NormalColorBlock = colorSuccess and colorResult or {}

local lz4Success, lz4Result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Vyrusspcs/weshkyv2/refs/heads/main/others/LZ4.lua"))()
end)
local LZ4 = lz4Success and lz4Result or nil

local apikey = "i-know-the-key-is-visible-please-be-kind"
X.ReplicatedStorage = game:GetService("ReplicatedStorage")
X.HttpService = game:GetService("HttpService")
X.Players = game:GetService("Players")
X.Workspace = game:GetService("Workspace")

if not isfolder("VoltaraBuildStorage") then
    pcall(function()
        makefolder("VoltaraBuildStorage")
        workspace.CheckCodeFunction:InvokeServer("=D")
        workspace.CheckCodeFunction:InvokeServer("=p")
    end)
end

local MainHighlight = X.Workspace:FindFirstChild("Global_Preview_Highlight")
if not MainHighlight then
    MainHighlight = Instance.new("Highlight")
    MainHighlight.Name = "Global_Preview_Highlight"
    MainHighlight.FillColor = Color3.fromRGB(83, 101, 153)
    MainHighlight.OutlineColor = Color3.fromRGB(14, 17, 26)
    MainHighlight.FillTransparency = 0.85
    MainHighlight.OutlineTransparency = 0.3
    MainHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    MainHighlight.Parent = X.Workspace
end

X.CurrentZone = nil
local BuildingParts = X.ReplicatedStorage:FindFirstChild("BuildingParts")

-- Base64 Encoder/Decoder
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b64lookup = {}
for i = 1, 64 do b64lookup[string.sub(b64chars, i, i)] = i - 1 end

function X.Base64Encode(data)
    local out = {}
    local len = #data
    for i = 1, len, 3 do
        local a = string.byte(data, i)
        local b = i + 1 <= len and string.byte(data, i + 1) or 0
        local c = i + 2 <= len and string.byte(data, i + 2) or 0
        local n = a * 65536 + b * 256 + c
        out[#out + 1] = string.sub(b64chars, math.floor(n / 262144) + 1, math.floor(n / 262144) + 1)
        out[#out + 1] = string.sub(b64chars, math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
        out[#out + 1] = i + 1 <= len and string.sub(b64chars, math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1) or "="
        out[#out + 1] = i + 2 <= len and string.sub(b64chars, n % 64 + 1, n % 64 + 1) or "="
    end
    return table.concat(out)
end

function X.Base64Decode(data)
    data = data:gsub("[^A-Za-z0-9+/=]", "")
    local out = {}
    for i = 1, #data, 4 do
        local a = b64lookup[string.sub(data, i, i)] or 0
        local b = b64lookup[string.sub(data, i + 1, i + 1)] or 0
        local c = b64lookup[string.sub(data, i + 2, i + 2)] or 0
        local d = b64lookup[string.sub(data, i + 3, i + 3)] or 0
        local n = a * 262144 + b * 4096 + c * 64 + d
        out[#out + 1] = string.char(math.floor(n / 65536) % 256)
        if string.sub(data, i + 2, i + 2) ~= "=" then out[#out + 1] = string.char(math.floor(n / 256) % 256) end
        if string.sub(data, i + 3, i + 3) ~= "=" then out[#out + 1] = string.char(n % 256) end
    end
    return table.concat(out)
end

X.Config = {
    zones = {
        blue = workspace:FindFirstChild("Really blueZone"),
        yellow = workspace:FindFirstChild("New YellerZone"),
        red = workspace:FindFirstChild("Really redZone"),
        magenta = workspace:FindFirstChild("MagentaZone"),
        black = workspace:FindFirstChild("BlackZone"),
        white = workspace:FindFirstChild("WhiteZone"),
        green = workspace:FindFirstChild("CamoZone"),
    },
    speedMode = 4,
    safeMode = false,
}

local BuildPreview = workspace:FindFirstChild("BuildPreview") or Instance.new("Model")
BuildPreview.Name = "BuildPreview"
BuildPreview.Parent = workspace

local player = X.Players.LocalPlayer
local playerData = player:FindFirstChild("Data")
local deg = 57.29577951308232

X.CFrame_new = CFrame.new
X.math_floor = math.floor
X.math_rad = math.rad
X.table_insert = table.insert

local remoteInvoke = Instance.new("RemoteFunction").InvokeServer
local workspaceChildren = workspace.GetChildren

local rotX, rotY, rotZ = 0, 0, 0
local moveMultiplier = 1

function X.ColorsAreEqual(color1, color2, tolerance)
    tolerance = tolerance or 0.01
    return math.abs(color1.R - color2.R) <= tolerance and
           math.abs(color1.G - color2.G) <= tolerance and
           math.abs(color1.B - color2.B) <= tolerance
end

function X.ShouldPaintBlock(blockName, targetColor)
    local defaultColorData = NormalColorBlock[blockName]
    if not defaultColorData then return true end
    local defaultColor = Color3.new(defaultColorData[1] or 1, defaultColorData[2] or 1, defaultColorData[3] or 1)
    return not X.ColorsAreEqual(targetColor, defaultColor)
end

-- Progress Bar UI
local existingGui = game:GetService("CoreGui"):FindFirstChild("progressBar")
if existingGui then existingGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "progressBar"
screenGui.Parent = game:GetService("CoreGui")

local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressContainer"
progressBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
progressBar.BackgroundTransparency = 0.025
progressBar.BorderSizePixel = 0
progressBar.Position = UDim2.new(0, 10, 1, -97)
progressBar.Size = UDim2.new(0, 300, 0, 90)
progressBar.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = progressBar

local progressText = Instance.new("TextLabel")
progressText.BackgroundTransparency = 1
progressText.Position = UDim2.new(0, 15, 0, 43)
progressText.Size = UDim2.new(1, -30, 0, 14)
progressText.Font = Enum.Font.GothamBold
progressText.Text = "0%"
progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
progressText.TextSize = 12
progressText.Parent = progressBar

local actionText = Instance.new("TextLabel")
actionText.BackgroundTransparency = 1
actionText.Position = UDim2.new(0, 15, 0, 67)
actionText.Size = UDim2.new(1, -30, 0, 14)
actionText.Font = Enum.Font.GothamBold
actionText.Text = "Ready"
actionText.TextColor3 = Color3.fromRGB(200, 200, 200)
actionText.TextSize = 11
actionText.Parent = progressBar

function X.SetStatus(msg)
    actionText.Text = msg
end

function X.UpdateProgression(val)
    if type(val) == "number" then
        progressText.Text = math.min(math.floor(val), 100) .. "%"
    else
        progressText.Text = tostring(val)
    end
end

function X.GetPlot()
    return X.Config.zones[tostring(player.Team)] or workspace:FindFirstChild("Really blueZone")
end

function X.ListBuilds()
    if not isfolder("VoltaraBuildStorage") then return {} end
    local files = listfiles("VoltaraBuildStorage")
    local builds = {}
    for _, file in ipairs(files) do
        if file:sub(-6) == ".Build" or file:sub(-7) == ".vBuild" then
            local fileName = file:match("([^/\\]+)$") or file
            local extLen = (file:sub(-6) == ".Build" and 6 or 7)
            local buildName = fileName:sub(1, #fileName - extLen)
            table.insert(builds, {name = buildName, path = file})
        end
    end
    return builds
end

function X.ClearPreview(chunked)
    local children = workspaceChildren(BuildPreview)
    for i, child in ipairs(children) do
        child:Destroy()
        if chunked and i % 500 == 0 then
            task.wait()
        end
    end
end

-- UI Initialization Check
if X.library then
    local mainColor = Color3.fromRGB(53, 63, 119)
    local window = X.library.new({
        text = "Voltara Auto Build",
        size = Vector2.new(360, 538),
        shadow = 0,
        transparency = 0.25,
        color = mainColor,
        boardcolor = Color3.fromRGB(21, 22, 23),
        rounding = 5,
        animation = 0.1,
        position = UDim2.new(0, 310, 0, 40),
    })
    window.open()
    
    local mainTab = window.new({ text = "Main" })
    mainTab:show()
    
    mainTab.new("button", {
        text = "Core Engine Active",
    })
end

print("Voltara Prototype Engine successfully loaded.")
