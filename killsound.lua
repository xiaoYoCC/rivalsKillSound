local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ========================
-- 🔊 音效取得
-- ========================
local function getAudio()
    local s = Workspace:FindFirstChild("xykill")
    if s and s:IsA("Sound") then
        return s.SoundId
    end

    local fileName = "xykill.mp3"
    if isfile and isfile(fileName) then
        return getcustomasset(fileName)
    end

    return "rbxassetid://117487354926114"
end

-- ========================
-- 🔊 播放
-- ========================
local lastPlay = 0
local COOLDOWN = 0.35

local function play()
    if tick() - lastPlay < COOLDOWN then return end
    lastPlay = tick()

    local s = Instance.new("Sound")
    s.SoundId = getAudio()
    s.Volume = 1.5
    s.Parent = SoundService
    s:Play()

    game:GetService("Debris"):AddItem(s, 5)
end

-- ========================
-- 🎯 攻擊系統（完全保留）
-- ========================
local lastAttackTime = 0
local ATTACK_WINDOW = 1.4

local currentTarget = nil
local lastTargetTime = 0
local TARGET_LOCK_TIME = 0.8

local function isAttacking()
    return (tick() - lastAttackTime) <= ATTACK_WINDOW
end

local function getTarget()
    if not Camera then return nil end

    local ray = Camera:ViewportPointToRay(
        Camera.ViewportSize.X/2,
        Camera.ViewportSize.Y/2
    )

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist

    local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)

    if result and result.Instance then
        local model = result.Instance:FindFirstAncestorOfClass("Model")
        if model then
            return Players:GetPlayerFromCharacter(model)
        end
    end

    return nil
end

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

        lastAttackTime = tick()

        local target = getTarget()
        if target then
            currentTarget = target
            lastTargetTime = tick()
        end
    end
end)

-- ========================
-- 🧠 擊殺判定（保留你版本）
-- ========================
local lastHitTime = {}
local HIT_WINDOW = 2.4

local function setupCharacter(player, char)
    if player == LocalPlayer then return end

    local hum = char:WaitForChild("Humanoid")
    local lastHp = hum.Health

    hum.HealthChanged:Connect(function(hp)
        if hp < lastHp then
            if isAttacking() then
                lastHitTime[player] = tick()
            end
        end
        lastHp = hp
    end)

    hum.Died:Connect(function()
        task.delay(0.15, function()
            local t = lastHitTime[player]
            if t and (tick() - t <= HIT_WINDOW) then
                play()
            end
            lastHitTime[player] = nil
        end)
    end)
end

-- ========================
-- 👥 玩家監聽
-- ========================
for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then
        setupCharacter(p, p.Character)
    end
    p.CharacterAdded:Connect(function(c)
        setupCharacter(p, c)
    end)
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c)
        setupCharacter(p, c)
    end)
end

-- ========================
-- 🧠 UI 判定
-- ========================
local keywords = {"eliminated","killed","擊殺","消滅"}

LocalPlayer.PlayerGui.DescendantAdded:Connect(function(v)
    if v:IsA("TextLabel") then
        local text = string.lower(v.Text)
        for _, k in ipairs(keywords) do
            if text:find(k) and isAttacking() then
                play()
                break
            end
        end
    end
end)

-- ========================
-- 🔔 🔥 你的通知系統（融合）
-- ========================
local sg = Instance.new("ScreenGui")
sg.Name = "NotifyUI"
sg.ResetOnSpawn = false
sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

local activeNotifications = {}

local function updatePos()
    for i, v in ipairs(activeNotifications) do
        v:TweenPosition(
            UDim2.new(1, -240, 0.8, -((#activeNotifications - i) * 65)),
            "Out", "Quart", 0.3, true
        )
    end
end

local function notify(msg)
    local nF = Instance.new("Frame")
    nF.Parent = sg
    nF.Size = UDim2.new(0, 220, 0, 50)
    nF.Position = UDim2.new(1, 50, 0.8, 0)
    nF.BackgroundColor3 = Color3.fromRGB(35,35,40)
    nF.BackgroundTransparency = 0.2

    Instance.new("UICorner", nF).CornerRadius = UDim.new(0,10)
    Instance.new("UIStroke", nF).Color = Color3.fromRGB(200,160,255)

    local nL = Instance.new("TextLabel")
    nL.Parent = nF
    nL.Size = UDim2.new(1,0,1,-5)
    nL.BackgroundTransparency = 1
    nL.Text = msg
    nL.TextColor3 = Color3.new(1,1,1)
    nL.TextSize = 15
    nL.Font = Enum.Font.GothamBold

    local barBG = Instance.new("Frame")
    barBG.Parent = nF
    barBG.Size = UDim2.new(1,-16,0,4)
    barBG.Position = UDim2.new(0,8,1,-8)
    barBG.BackgroundColor3 = Color3.new(0,0,0)
    barBG.ClipsDescendants = true
    Instance.new("UICorner", barBG)

    local bar = Instance.new("Frame")
    bar.Parent = barBG
    bar.Size = UDim2.new(1,0,1,0)
    bar.BackgroundColor3 = Color3.fromRGB(180,120,255)
    Instance.new("UICorner", bar)

    table.insert(activeNotifications, nF)
    updatePos()

    TweenService:Create(bar, TweenInfo.new(2.5), {
        Size = UDim2.new(0,0,1,0)
    }):Play()

    task.delay(2.5, function()
        for i, v in ipairs(activeNotifications) do
            if v == nF then
                table.remove(activeNotifications, i)
                break
            end
        end

        nF:TweenPosition(
            UDim2.new(1,50,nF.Position.Y.Scale,nF.Position.Y.Offset),
            "In","Quart",0.3,true
        )

        task.wait(0.3)
        nF:Destroy()
        updatePos()
    end)
end

-- ========================
-- 🚀 啟動提示
-- ========================
task.delay(1, function()
    notify("🔥 腳本已成功載入")
end)

print("🔥 完整版已啟動（含自訂通知）")