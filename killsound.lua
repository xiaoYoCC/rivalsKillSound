local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ========================
-- 🎧 音效（Workspace版）
-- ========================
local function getSoundId()
    local s = Workspace:FindFirstChild("xykill")
    if s and s:IsA("Sound") then
        return s.SoundId
    end
    return "rbxassetid://117487354926114"
end

local killAudio = getSoundId()

-- ========================
-- 🔊 播放（防重複）
-- ========================
local lastPlay = 0
local COOLDOWN = 0.4

local function play()
    if tick() - lastPlay < COOLDOWN then return end
    lastPlay = tick()

    local s = Instance.new("Sound")
    s.SoundId = killAudio
    s.Volume = 1.5
    s.Parent = SoundService
    s:Play()

    game:GetService("Debris"):AddItem(s, 5)
end

-- ========================
-- 🧠 存活判定（關鍵）
-- ========================
local function isAlive()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    return hum and hum.Health > 0
end

-- ========================
-- 🎯 攻擊 + 鎖定
-- ========================
local lastAttackTime = 0
local ATTACK_WINDOW = 1.2

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
    if not isAlive() then return end

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
-- 📏 距離 + 視角
-- ========================
local MAX_DISTANCE = 120
local MAX_ANGLE = 60

local function isValidTarget(char)
    if not LocalPlayer.Character then return false end

    local a = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local b = char:FindFirstChild("HumanoidRootPart")

    if not (a and b) then return false end

    local dir = (b.Position - a.Position)
    if dir.Magnitude > MAX_DISTANCE then return false end

    local dot = Camera.CFrame.LookVector:Dot(dir.Unit)
    local angle = math.deg(math.acos(dot))

    return angle <= MAX_ANGLE
end

-- ========================
-- 🧠 擊殺判定（修正版核心）
-- ========================
local lastHitByYou = {}
local HIT_WINDOW = 1.5

local function setupCharacter(player, char)
    if player == LocalPlayer then return end

    local hum = char:WaitForChild("Humanoid")
    local lastHp = hum.Health

    hum.HealthChanged:Connect(function(hp)
        if hp < lastHp then
            if isAlive()
            and isAttacking()
            and currentTarget == player
            and isValidTarget(char)
            and (tick() - lastTargetTime <= TARGET_LOCK_TIME)
            then
                lastHitByYou[player] = tick()
            end
        end
        lastHp = hp
    end)

    hum.Died:Connect(function()
        if not isAlive() then return end -- 🔥 觀戰/死亡直接封鎖

        local t = lastHitByYou[player]

        if t
        and (tick() - t <= HIT_WINDOW)
        and currentTarget == player
        then
            play()
        end

        lastHitByYou[player] = nil
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
end)

-- ========================
-- 🧠 UI（只在活著時允許）
-- ========================
local keywords = {"eliminated","killed","擊殺","消滅"}

LocalPlayer.PlayerGui.DescendantAdded:Connect(function(v)
    if not isAlive() then return end

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

print("🔥 Stable Kill Sound 已啟動（觀戰/誤觸已封鎖）")