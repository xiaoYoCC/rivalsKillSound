local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

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
-- 🔊 播放（🔥改成不阻擋連殺）
-- ========================
local function play()
    local s = Instance.new("Sound")
    s.SoundId = getAudio()
    s.Volume = 1.5
    s.Parent = SoundService
    s:Play()

    game:GetService("Debris"):AddItem(s, 5)
end

-- ========================
-- 🎯 攻擊系統
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
-- 🧠 擊殺判定（🔥支援多目標）
-- ========================
local lastHitTime = {}
local HIT_WINDOW = 2.2

local function setupCharacter(player, char)
    if player == LocalPlayer then return end

    local hum = char:WaitForChild("Humanoid")
    local lastHp = hum.Health

    hum.HealthChanged:Connect(function(hp)
        if hp < lastHp then

            if isAttacking()
            and currentTarget == player
            and (tick() - lastTargetTime <= TARGET_LOCK_TIME + 0.4)
            then
                lastHitTime[player] = tick()
            end
        end

        lastHp = hp
    end)

    hum.Died:Connect(function()

        task.delay(0.1, function()

            local t = lastHitTime[player]

            -- 🔥 關鍵：不再檢查 currentTarget（避免多殺失敗）
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
end)

-- ========================
-- 🧠 UI輔助
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

print("🔥 多殺修正版已啟動（每殺必響）")