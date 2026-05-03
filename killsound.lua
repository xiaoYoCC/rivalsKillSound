local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ========================
-- 🔊 音效取得（修正：不快取）
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
-- 🔊 播放（穩定版）
-- ========================
local lastPlay = 0
local COOLDOWN = 0.35

local function play()
    if tick() - lastPlay < COOLDOWN then return end
    lastPlay = tick()

    local s = Instance.new("Sound")
    s.SoundId = getAudio() -- 🔥 每次即時抓，避免第一次失效
    s.Volume = 0.5
    s.Parent = SoundService
    s:Play()

    game:GetService("Debris"):AddItem(s, 5)
end

-- ========================
-- 🎯 攻擊 + 鎖定
-- ========================
local lastAttackTime = 0
local ATTACK_WINDOW = 1.4 -- 🔥 放寬一點（原本太緊）

local currentTarget = nil
local lastTargetTime = 0
local TARGET_LOCK_TIME = 0.35

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
-- 🧠 擊殺判定（修正核心）
-- ========================
local lastHitTime = {}
local HIT_WINDOW = 2.2 -- 🔥 關鍵：修你「要打兩次才觸發」

local function setupCharacter(player, char)
    if player == LocalPlayer then return end

    local hum = char:WaitForChild("Humanoid")
    local lastHp = hum.Health

    hum.HealthChanged:Connect(function(hp)
        if hp < lastHp then

            if isAttacking()
            and isValidTarget(char)
            and currentTarget == player
            and (tick() - lastTargetTime <= TARGET_LOCK_TIME + 0.4) -- 🔥 補延遲
            then
                lastHitTime[player] = tick()
            end
        end

        lastHp = hp
    end)

    hum.Died:Connect(function()

        -- 🔥 延遲避免 Roblox death sync 問題
        task.delay(0.15, function()

            local t = lastHitTime[player]

            if t
            and (tick() - t <= HIT_WINDOW)
            and currentTarget == player
            then
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
end)

-- ========================
-- 🧠 UI（保留但安全）
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

print("🔥 已修正版：穩定擊殺音效系統")