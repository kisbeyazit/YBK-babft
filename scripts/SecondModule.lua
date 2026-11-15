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
    size = Vector2.new(500, 540),
    shadow = 0,
    transparency = 0.25,
    color = mainColor,
    boardcolor = Color3.fromRGB(21, 22, 23),
    rounding = 5,
    animation = 0.1,
    position = UDim2.new(0, 400, 0, 40),
})

window.open()

-- Sekmeler ve Arayüz Bileşenleri
local tab1 = window.new({
    title = "Auto Farm"
})

local tab2 = window.new({
    title = "Data & Build"
})

-- Örnek bir Farm Bölümü
local section1 = tab1.section({
    text = "Autofarm",
    side = "left"
})

section1.label({
    text = "Farming time: 00:00:00"
})

section1.label({
    text = "Current Gold: 285"
})

section1.button({
    text = "Autofarm",
    callback = function()
        print("Autofarm başlatıldı!")
    end
})
