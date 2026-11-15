local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vyrusspcs/weshkyv2/refs/heads/main/server/libtest.lua"))()

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local UiColor = "53, 63, 119"
local r, g, b = string.match(UiColor, "(%d+),%s*(%d+),%s*(%d+)")
local mainColor = Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))

local window = library.new({
    text = "Second Module",
    size = Vector2.new(368, 540),
    shadow = 0,
    transparency = 0.25,
    color = mainColor,
    boardcolor = Color3.fromRGB(21, 22, 23),
    rounding = 5,
    animation = 0.1,
    position = UDim2.new(0, 678, 0, 40),
})

window.open()

local mainTab = window.new({ text = "Auto Farm" })
local databaseTab = window.new({ text = "Database" })
local specialTab = window.new({ text = "Special" })
local clientTab = window.new({ text = "Client" })
local creditsTab = window.new({ text = "Credits" })
mainTab:show()

--------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------

local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local TriggerChest = workspace.BoatStages.NormalStages.TheEnd.GoldenChest.Trigger

local initialGold = 0
local initialGoldBlocks = 0
local goldBlocksUpdateThread = nil
local goldUpdateThread = nil
local farmStartTime = 0
local pausedTime = 0
local farmTimer = nil
local isTimerRunning = false

local weshkyPartsByName = {}

local positions = {
    Vector3.new(-72.31890106201172, 91.17544555664062, 1191.0478515625),   -- Weshky1
    Vector3.new(-52.304874420166016, 58.03061294555664, 1769.4705810546875), -- Weshky2
    Vector3.new(-27.725244522094727, 67.33195495605469, 2471.45361328125), -- Weshky3
    Vector3.new(-44.12211608886719, 69.04801177978516, 3165.256591796875), -- Weshky4
    Vector3.new(-53.77952194213867, 74.39949798583984, 3990.331298828125), -- Weshky5
    Vector3.new(-39.26005935668945, 83.18901824951172, 4824.65087890625), -- Weshky6
    Vector3.new(-52.22807312011719, 67.77399444580078, 5682.07421875), -- Weshky7
    Vector3.new(-82.22046661376953, 50.52703094482422, 6260.56982421875), -- Weshky8
    Vector3.new(-38.067955017089844, 105.63947296142578, 7167.95263671875), -- Weshky9
    Vector3.new(-49.93274688720703, 57.78563690185547, 7731.59375), -- Weshky0
}

local partNames = {
    "Weshky1", "Weshky2", "Weshky3", "Weshky4", "Weshky5",
    "Weshky6", "Weshky7", "Weshky8", "Weshky9", "Weshky0"
}

for i, pos in ipairs(positions) do
    local name = partNames[i]
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Transparency = 1
    part.Size = Vector3.new(6, 1, 6)
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.TopSurface = Enum.SurfaceType.Smooth
    part.Position = pos
    part.Parent = workspace

    weshkyPartsByName[name] = part
end

local textureId = "rbxassetid://137722555800117"
local decalName = "Weshky doing its own thing?!"

for _, name in ipairs(partNames) do
    local part = weshkyPartsByName[name]
    if part then
        local decal = Instance.new("Decal")
        decal.Texture = textureId
        decal.Name = decalName
        decal.Face = Enum.NormalId.Top
        decal.Parent = part
    end
end

isFarming = false

local isFarmingThreadRunning = false
local shouldStopFarming = false
local farmLoopCount = 0
local TriggerChestOriginalCFrame = CFrame.new(-521.271667, -9.89999485, 172.898331, 0.855194747, -6.33011084e-08, 0.518306851, 1.27484903e-08, 1, 1.01095843e-07, -0.518306851, -7.98490021e-08, 0.855194747)

local function autoDismissResults()
    local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end
    local resultsGui = playerGui:FindFirstChild("RiverResults")
    if resultsGui then
        local frame = resultsGui:FindFirstChild("Frame")
        if frame and frame.Visible then
            workspace.ClaimRiverResultsGold:FireServer()
            frame.Visible = false
            pcall(function()
                game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
            end)
        end
    end
end

local function waitForCharacter()
    local plr = game.Players.LocalPlayer
    local char = plr.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        char = plr.CharacterAdded:Wait()
        char:WaitForChild("HumanoidRootPart")
        task.wait(0.5)
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then
        char = plr.CharacterAdded:Wait()
        char:WaitForChild("HumanoidRootPart")
        task.wait(0.5)
    end
    return char
end

local function safeTeleport(targetCFrame, maxRetries)
    maxRetries = maxRetries or 3
    for attempt = 1, maxRetries do
        if shouldStopFarming then return false end
        local char = waitForCharacter()
        if not char then return false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end

        hrp.CFrame = targetCFrame
        task.wait(0.15)

        hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - targetCFrame.Position).Magnitude < 20 then
            return true
        end
    end
    return false
end

local function holdPosition(duration)
    local elapsed = 0
    while elapsed < duration and not shouldStopFarming do
        autoDismissResults()
        task.wait(0.1)
        elapsed = elapsed + 0.1

        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                waitForCharacter()
                return false
            end
        end
    end
    return not shouldStopFarming
end

function StartFarmNormal()
    if isFarmingThreadRunning then return end
    isFarming = true
    isFarmingThreadRunning = true
    shouldStopFarming = false
    farmLoopCount = 0

    local stages = {
        { name = "Start",  part = weshkyPartsByName.Weshky1, wait = 2.4 },
        { name = "Stage1", part = weshkyPartsByName.Weshky2, wait = 2.3 },
        { name = "Stage2", part = weshkyPartsByName.Weshky3, wait = 2.3 },
        { name = "Stage3", part = weshkyPartsByName.Weshky4, wait = 2.3 },
        { name = "Stage4", part = weshkyPartsByName.Weshky5, wait = 2.3 },
        { name = "Stage5", part = weshkyPartsByName.Weshky6, wait = 2.3 },
        { name = "Stage6", part = weshkyPartsByName.Weshky7, wait = 2.3 },
        { name = "Stage7", part = weshkyPartsByName.Weshky8, wait = 2.3 },
        { name = "Stage8", part = weshkyPartsByName.Weshky9, wait = 2.3 },
        { name = "End",    part = weshkyPartsByName.Weshky0, wait = 1.5, isEnd = true },
    }

    while isFarming and not shouldStopFarming do
        autoDismissResults()

        if farmLoopCount > 0 then
            holdPosition(5)
        end
        if shouldStopFarming then break end

        local char = waitForCharacter()
        if not char or shouldStopFarming then break end

        farmLoopCount = farmLoopCount + 1
        local loopFailed = false

        for _, stage in ipairs(stages) do
            if shouldStopFarming then break end
            if not stage.part then continue end

            local targetCFrame = stage.part.CFrame + Vector3.new(0, 2, 0)

            local arrived = safeTeleport(targetCFrame, 5)
            if shouldStopFarming then break end
            if not arrived then
                loopFailed = true
                break
            end

            local held = holdPosition(stage.wait)
            if shouldStopFarming then break end
            if not held then
                loopFailed = true
                break
            end

            if stage.isEnd then
                if TriggerChest and not shouldStopFarming then
                    local endChar = game.Players.LocalPlayer.Character
                    local hrp = endChar and endChar:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        TriggerChest.CFrame = hrp.CFrame
                        holdPosition(1.2)
                        if shouldStopFarming then break end
                        TriggerChest.CFrame = TriggerChestOriginalCFrame
                    end
                end

                task.wait(0.3)
                pcall(function()
                    workspace.ClaimRiverResultsGold:FireServer()
                end)
                task.wait(0.5)

                autoDismissResults()
                task.wait(0.3)
                autoDismissResults()
            end
        end

        if loopFailed and not shouldStopFarming then
            waitForCharacter()
            task.wait(1)
            autoDismissResults()
        end
    end

    isFarmingThreadRunning = false
    shouldStopFarming = false
end

function StopFarm()
    isFarming = false
    shouldStopFarming = true

    local plr = game.Players.LocalPlayer
    if not plr then return end

    task.wait(0.2)
    local character = plr.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            rootPart.CFrame = CFrame.new(0, -615, 0)
        end
    end
end

local function AntiAFK()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Vyrusspcs/weshkyv2/refs/heads/main/special/antiafk.lua"))()
end

local farmFolder = mainTab.new("folder", {
    text = "Autofarm",
})

local farmTimeLabel = farmFolder.new("label", { 
    text = "Farming time: 00:00:00" 
})

local currentGoldLabel = farmFolder.new("label", { 
    text = "Current Gold: 0" 
})

local farmedGoldBlocksLabel = farmFolder.new("label", { 
    text = "Gold Blocks Farmed: 0" 
})

local farmedGoldLabel = farmFolder.new("label", {
    text = "Gold Farmed: 0"
})

local farmLoopsLabel = farmFolder.new("label", {
    text = "Farm Loops: 0"
})

local function updateFarmTime()
    if isTimerRunning then
        local elapsedTime = (os.time() - farmStartTime) + pausedTime

        local hours = math.floor(elapsedTime / 3600)
        local minutes = math.floor((elapsedTime % 3600) / 60)
        local seconds = elapsedTime % 60

        farmTimeLabel.setText(string.format("Farming time: %02d:%02d:%02d", hours, minutes, seconds))
        farmLoopsLabel.setText("Farm Loops: " .. tostring(farmLoopCount))
    end
end

local function UpdateGoldDisplay()
    pcall(function()
        local goldGui = player.PlayerGui:FindFirstChild("GoldGui")
        if goldGui and goldGui:FindFirstChild("Frame") then
            local amountLabel = goldGui.Frame:FindFirstChild("Amount")
            if amountLabel and amountLabel:IsA("TextLabel") then
                local cleanText = amountLabel.Text:gsub("[^%d]", "")
                local currentGold = tonumber(cleanText) or 0
                                
                if initialGold == 0 then
                    initialGold = currentGold
                end
                
                local farmed = currentGold - initialGold
                farmedGoldLabel.setText("Gold Farmed: " .. farmed)
            end
        end
    end)
end

local function UpdateGoldBlocksDisplay()
    pcall(function()
        local goldBlocksValue = game:GetService("Players").LocalPlayer.Data.GoldBlock.Value
        local currentGoldBlocks = tonumber(goldBlocksValue) or 0

        if initialGoldBlocks == 0 then
            initialGoldBlocks = currentGoldBlocks
        end

        local farmed = currentGoldBlocks - initialGoldBlocks
        farmedGoldBlocksLabel.setText("Gold Blocks Farmed: " .. farmed)
    end)
end

local function UpdateCurrentGoldDisplay()
    pcall(function()
        local goldGui = player.PlayerGui:FindFirstChild("GoldGui")
        if goldGui and goldGui:FindFirstChild("Frame") then
            local amountLabel = goldGui.Frame:FindFirstChild("Amount")
            if amountLabel and amountLabel:IsA("TextLabel") then
                local cleanText = amountLabel.Text:gsub("[^%d]", "")
                local currentGold = tonumber(cleanText) or 0
                currentGoldLabel.setText("Current Gold: " .. currentGold)
            end
        end
    end)
end

local function StartGoldUpdate()
    if goldUpdateThread then return end
    
    goldUpdateThread = task.spawn(function()
        while true do
            UpdateGoldDisplay()
            UpdateGoldBlocksDisplay()
            task.wait(0.5)
        end
    end)
end

farmFolder.new("button", {
    text = "Reset Counters",
}).event:Connect(function()
    initialGold = 0
    initialGoldBlocks = 0
    farmStartTime = os.time()
    pausedTime = 0
    farmLoopCount = 0

    farmedGoldLabel.setText("Gold Farmed: 0")
    farmedGoldBlocksLabel.setText("Gold Blocks Farmed: 0")
    farmTimeLabel.setText("Farming time: 00:00:00")
    farmLoopsLabel.setText("Farm Loops: 0")
    
    UpdateCurrentGoldDisplay()
    
    if webhookEnabled then
        task.spawn(function()
            task.wait(1)
            -- SendWebhook()
        end)
    end
    
    if isTimerRunning then
        farmStartTime = os.time()
    end
end)

local currentGoldUpdateThread = nil
local function StartCurrentGoldUpdate()
    if currentGoldUpdateThread then return end
    
    currentGoldUpdateThread = task.spawn(function()
        while true do
            UpdateCurrentGoldDisplay()
            task.wait(1)
        end
    end)
end

farmFolder.new("switch", {
    text = "Autofarm",
}).event:Connect(function(state)
    if state then
        isFarming = true
        isTimerRunning = true
        
        if initialGoldBlocks == 0 then
            local goldBlocksValue = game:GetService("Players").LocalPlayer.Data.GoldBlock.Value
            initialGoldBlocks = tonumber(goldBlocksValue) or 0
        end
        
        if initialGold == 0 then
            UpdateGoldDisplay()
        end
        
        StartGoldUpdate()
        farmStartTime = os.time()
        
        if farmTimer then
            farmTimer:Disconnect()
        end
        
        farmTimer = game:GetService("RunService").Heartbeat:Connect(function()
            updateFarmTime()
        end)
        
        task.spawn(function()
            while isFarming do
                autoDismissResults()
                task.wait(1)
            end
        end)

        StartFarmNormal()
    else
        isFarming = false
        isTimerRunning = false
        
        pausedTime = (os.time() - farmStartTime) + pausedTime
        
        if farmTimer then
            farmTimer:Disconnect()
            farmTimer = nil
        end
        
        if goldUpdateThread then
            task.cancel(goldUpdateThread)
            goldUpdateThread = nil
        end
        
        StopFarm()
        updateFarmTime()
    end
end)

farmFolder.open()

local webhookUrl = ""
local webhookEnabled = false
local webhookInterval = 300
local webhookThread = nil

local webhookFolder = mainTab.new("folder", {
    text = "Webhook Notifications",
})

webhookFolder.new("input", {
    text = "Webhook URL",
    placeholder = "https://...",
}).event:Connect(function(value)
    webhookUrl = value
end)

webhookFolder.new("slider", {
    text = "Update Interval (seconds)",
    min = 60,
    max = 3600,
    value = 300,
    floating = 0,
}).event:Connect(function(value)
    webhookInterval = value
end)

webhookFolder.new("switch", {
    text = "Enable Webhook",
}).event:Connect(function(state)
    webhookEnabled = state
end)

webhookFolder.open()

--------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------

local BuildDatabase = databaseTab.new("dropdown", {
    text = "Select Build",
})

local dropdownObjects = {}
local selectedBuild = nil
local buildsFolder = "WeshkyBuildStorage"

-- Yerel dosya fonksiyonları çakışmasını önlemek için güvenli sarmalayıcılar
pcall(function()
    if not isfolder(buildsFolder) then
        makefolder(buildsFolder)
    end
end)

local function fetchBuildsFromGitHub()
    local builds = {}
    local success, response = pcall(function()
        return game:HttpGet("https://api.github.com/repos/Vyrusspcs/weshkyv2/contents/database/builds")
    end)
    
    if success then
        local files = HttpService:JSONDecode(response)
        for _, file in ipairs(files) do
            if file.type == "file" and file.name:match("%.Build$") then
                table.insert(builds, {
                    name = file.name:gsub("%.Build$", ""),
                    download_url = file.download_url,
                    path = file.path
                })
            end
        end
    end
    
    return builds
end

local function downloadBuild(buildName, downloadUrl)
    local success, content = pcall(function()
        return game:HttpGet(downloadUrl)
    end)
    
    if success then
        local filePath = buildsFolder .. "/" .. buildName .. ".Build"
        writefile(filePath, content)
        return true
    end
    return false
end

local function listLocalBuilds()
    local builds = {}
    pcall(function()
        if isfolder(buildsFolder) then
            for _, file in ipairs(listfiles(buildsFolder)) do
                if file:match("%.Build$") then
                    local fileName = file:match("[^\\/]+$")
                    local buildName = fileName:gsub("%.Build$", "")
                    table.insert(builds, {
                        name = buildName,
                        path = file,
                        isLocal = true
                    })
                end
            end
        end
    end)
    return builds
end

local function refreshBuildsList()
    if BuildDatabase.isopen then
        BuildDatabase:close()
    end
    
    dropdownObjects = {}
    
    local localBuilds = listLocalBuilds()
    for _, build in ipairs(localBuilds) do
        local dropdownObj = BuildDatabase.new(build.name .. " (Local)")
        dropdownObjects[build.name] = {object = dropdownObj, data = build}
    end
    
    local onlineBuilds = fetchBuildsFromGitHub()
    for _, build in ipairs(onlineBuilds) do
        local dropdownObj = BuildDatabase.new(build.name)
        dropdownObjects[build.name] = {object = dropdownObj, data = build}
    end
    
    if #localBuilds == 0 and #onlineBuilds == 0 then
        BuildDatabase.new("No builds found - Check GitHub")
    end
    
    if not BuildDatabase.isopen then
        BuildDatabase:open()
    end
end

BuildDatabase.event:Connect(function(option)
    if option:find("(Local)") then
        local buildName = option:gsub(" %(Local%)", "")
        if dropdownObjects[buildName] then
            selectedBuild = dropdownObjects[buildName].data
        end
    elseif option ~= "No builds found - Check GitHub" then
        if dropdownObjects[option] then
            selectedBuild = dropdownObjects[option].data
        end
    end
end)

databaseTab.new("button", {
    text = "Download Selected Build",
}).event:Connect(function()
    if not selectedBuild then return end
    if selectedBuild.isLocal then return end
    
    downloadBuild(selectedBuild.name, selectedBuild.download_url)
    task.wait(1)
    refreshBuildsList()
end)

refreshBuildsList()

local characterFolder = clientTab.new("folder", {
    text = "Character Settings",
})

local speedSlider = characterFolder.new("slider", {
    text = "Walkspeed",
    min = 0,
    max = 200,
    value = humanoid.WalkSpeed,
})

speedSlider.event:Connect(function(value)
    if humanoid then
        humanoid.WalkSpeed = value
    end
end)

local jumppowerSlider = characterFolder.new("slider", {
    text = "JumpPower",
    min = 0,
    max = 200,
    value = humanoid.JumpPower,
})

jumppowerSlider.event:Connect(function(value)
    if humanoid then
        humanoid.JumpPower = value
    end
end)

characterFolder.new("button", {
    text = "Reset to Default",
}).event:Connect(function()
    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50

        speedSlider.set(16)
        jumppowerSlider.set(50)
    end
end)

characterFolder.open()

local mapFolder = clientTab.new("folder", {
    text = "Map Settings",
})

mapFolder.new("button", {
    text = "Remove Water Damage",
}).event:Connect(function()
    local water = workspace:FindFirstChild("Water")
    if water then
        water:Destroy()
    end
end)

mapFolder.open()

local fakeGoldFolder = clientTab.new("folder", {
    text = "Fake Gold Amount",
})

local GiveGoldAmount = nil

fakeGoldFolder.new("input", {
    text = "Gold Amount",
    placeholder = "2351981125",
}).event:Connect(function(value)
    GiveGoldAmount = tonumber(value)
end)

fakeGoldFolder.new("button", {
    text = "Set Fake Gold",
}).event:Connect(function()
    if GiveGoldAmount and type(GiveGoldAmount) == "number" then
        game:GetService("Players").LocalPlayer.Data.Gold.Value = GiveGoldAmount
    end
end)

fakeGoldFolder.open()

-------------------------------------------------------------------------------------------- Exclusive
-------------------------------------------------------------------------------------------- Exclusive
-------------------------------------------------------------------------------------------- Exclusive

local eggCanonFolder = specialTab.new("folder", {
    text = "Egg Canon Farm",
})

eggCanonFolder.new("button", {
    text = "Start Egg Canon Farm",
}).event:Connect(function()
    loadstring(game:HttpGet(('https://raw.githubusercontent.com/Vyrusspcs/weshkyv2/refs/heads/main/special/eggcanon.lua'),true))()
end)

local tpplace = specialTab.new("folder", {
    text = "Teleport Place",
})

tpplace.new("button", {
    text = "Inner Cloud",
}).event:Connect(function()
    TeleportService:Teleport(1930863474, game.Players.LocalPlayer)
end)

tpplace.new("button", {
    text = "Chrismas",
}).event:Connect(function()
    TeleportService:Teleport(1930866268, game.Players.LocalPlayer)
end)

tpplace.new("button", {
    text = "Halloween",
}).event:Connect(function()
    TeleportService:Teleport(1930665568, game.Players.LocalPlayer)
end)

-------------------------------------------------------------------------------------------- Credits
-------------------------------------------------------------------------------------------- Credits
-------------------------------------------------------------------------------------------- Credits

local creditsFolder = creditsTab.new("folder", {
    text = "Credits",
})
creditsFolder.new("label", {
    text = "Creator and Main Scripter: Sxirbes (Zenith)",
})

creditsFolder.new("button", {
    text = "Join our Discord",
}).event:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Vyrusspcs/weshkyv2/refs/heads/main/client/external/discord.lua"))()
end)

creditsFolder.open()

AntiAFK()

pcall(function()
    for _, v in next, getconnections(game:GetService("Players").LocalPlayer.Idled) do
        v:Disable()
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        UpdateCurrentGoldDisplay()
    end
end)
