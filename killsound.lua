local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ========================
-- 🔊 音效取得（全兼容）
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

local killAudio = getAudio()

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
    s.Volume = 0.5
    s.Parent = SoundService
    s:Play()

    game:GetService("Debris"):AddItem(s, 5)
end

-- ========================
-- 🎯 攻擊狀態偵測
-- ========================
local lastAttackTime = 0
local ATTACK_WINDOW = 1.2

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        lastAttackTime = tick()
    end
end)

local function isAttacking()
    return (tick() - lastAttackTime) <= ATTACK_WINDOW
end

-- ========================
-- 📏 距離 + 視角判定
-- ========================
local MAX_DISTANCE = 120
local MAX_ANGLE = 60 -- 視角角度限制

local function isValidTarget(char)
    if not LocalPlayer.Character then return false end

    local hrp1 = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local hrp2 = char:FindFirstChild("HumanoidRootPart")

    if not (hrp1 and hrp2) then return false end

    -- 距離
    local dir = (hrp2.Position - hrp1.Position)
    local dist = dir.Magnitude
    if dist > MAX_DISTANCE then return false end

    -- 視角
    local look = Camera.CFrame.LookVector
    local dot = look:Dot(dir.Unit)
    local angle = math.deg(math.acos(dot))

    return angle <= MAX_ANGLE
end

-- ========================
-- 🧠 血量擊殺判定（核心）
-- ========================
local lastHitTime = {}
local HIT_WINDOW = 1.5

local function setupCharacter(player, char)
    if player == LocalPlayer then return end

    local hum = char:WaitForChild("Humanoid")
    local lastHp = hum.Health

    hum.HealthChanged:Connect(function(hp)
        if hp < lastHp then
            if isAttacking() and isValidTarget(char) then
                lastHitTime[player] = tick()
            end
        end
        lastHp = hp
    end)

    hum.Died:Connect(function()
        local t = lastHitTime[player]

        if t and (tick() - t <= HIT_WINDOW) and isAttacking() then
            play()
        end

        lastHitTime[player] = nil
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
-- 🧠 UI 補強（低權重）
-- ========================
local keywords = {"eliminated","killed","擊殺","消滅"}

LocalPlayer.PlayerGui.DescendantAdded:Connect(function(v)
    if v:IsA("TextLabel") then
        local text = string.lower(v.Text)
        for _, k in ipairs(keywords) do
            if text:find(k) then
                if isAttacking() then
                    play()
                end
                break
            end
        end
    end
end)

-- ========================
-- 🧠 leaderstats 補強（低權重）
-- ========================
task.spawn(function()
    local stats = LocalPlayer:FindFirstChild("leaderstats")
    if not stats then return end

    local kills = stats:FindFirstChild("Kills")
    if not kills then return end

    local last = kills.Value

    kills.Changed:Connect(function(v)
        if v > last then
            play()
        end
        last = v
    end)
end)

print("😈 Ultimate Kill Sound 已啟動（接近0誤判）")