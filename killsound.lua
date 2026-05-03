local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ========================
-- 🔊 音效（Workspace Sound）
-- ========================
local function getSoundId()
    local s = Workspace:FindFirstChild("xykill")
    if s and s:IsA("Sound") then
        return s.SoundId
    end
    return "rbxassetid://117487354926114"
end

local killSoundId = getSoundId()

-- ========================
-- 🔊 播放（最穩版）
-- ========================
local lastPlay = 0
local COOLDOWN = 0.35

local function playKill()
    if tick() - lastPlay < COOLDOWN then return end
    lastPlay = tick()

    local s = Instance.new("Sound")
    s.SoundId = killSoundId
    s.Volume = 1.5
    s.Parent = SoundService
    s:Play()

    game:GetService("Debris"):AddItem(s, 5)
end

-- ========================
-- 🎯 攻擊紀錄（不依賴 alive）
-- ========================
local lastAttackTime = 0
local ATTACK_WINDOW = 1.0

local function isAttacking()
    return (tick() - lastAttackTime) <= ATTACK_WINDOW
end

-- ========================
-- 🎯 準心鎖定目標
-- ========================
local currentTarget = nil
local lastTargetTime = 0
local TARGET_WINDOW = 0.25

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
-- 📏 距離判定（防亂觸）
-- ========================
local MAX_DISTANCE = 120

local function isValid(char)
    local a = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local b = char and char:FindFirstChild("HumanoidRootPart")

    if not (a and b) then return false end

    return (a.Position - b.Position).Magnitude <= MAX_DISTANCE
end

-- ========================
-- 🧠 擊殺記錄（核心穩定版）
-- ========================
local lastHit = {}

local function setupPlayer(player, char)
    if player == LocalPlayer then return end

    local hum = char:WaitForChild("Humanoid")
    local lastHp = hum.Health

    hum.HealthChanged:Connect(function(hp)
        if hp < lastHp then

            -- 🔥 關鍵：只記錄「你有攻擊 + 你瞄準的人」
            if isAttacking()
            and currentTarget == player
            and (tick() - lastTargetTime <= TARGET_WINDOW)
            and isValid(char)
            then
                lastHit[player] = tick()
            end
        end

        lastHp = hp
    end)

    hum.Died:Connect(function()

        local t = lastHit[player]

        -- 🔥 不依賴 alive（避免整套壞掉）
        if t
        and (tick() - t <= 1.2)
        and currentTarget == player
        then
            playKill()
        end

        lastHit[player] = nil
    end)
end

-- ========================
-- 👥 玩家監聽
-- ========================
for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then
        setupPlayer(p, p.Character)
    end
    p.CharacterAdded:Connect(function(c)
        setupPlayer(p, c)
    end)
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c)
        setupPlayer(p, c)
    end)
end)

print("🔥 Ultra Stable Kill Sound 已啟動")