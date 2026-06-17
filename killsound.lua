-- ========================
-- 🔄 自動預約執行
-- ========================
local function autoQueue()
    local scriptURL = "https://raw.githubusercontent.com/xiaoYoCC/rivalsKillSound/main/killsound.lua"
    local queue_func = queue_on_teleport or (syn and syn.queue_on_teleport)
    
    if queue_func then
        queue_func([[
            repeat task.wait() until game:IsLoaded()
            loadstring(game:HttpGet("]] .. scriptURL .. [["))()
        ]])
    end
end

autoQueue()

-- ========================
-- 核心邏輯
-- ========================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ========================
-- 🔊 音效取得 (cache)
-- ========================
local cachedSoundId = nil
local function getAudio()
    if cachedSoundId then return cachedSoundId end

    local s = Workspace:FindFirstChild("xykill")
    if s and s:IsA("Sound") then
        cachedSoundId = s.SoundId
        return cachedSoundId
    end

    local fileName = "xykill.mp3"
    if isfile and isfile(fileName) then
        cachedSoundId = getcustomasset(fileName)
        return cachedSoundId
    end

    cachedSoundId = "rbxassetid://135097031120155"
    return cachedSoundId
end

-- ========================
-- 🔊 播放 (cooldown 防重疊)
-- ========================
local lastPlayTime = 0
local PLAY_COOLDOWN = 0.3

local function play()
    local now = tick()
    if (now - lastPlayTime) < PLAY_COOLDOWN then return end
    lastPlayTime = now

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
local TARGET_LOCK_TIME = 1.2

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
-- 🧠 擊殺判定
-- ========================
local lastHitTime = {}
local HIT_WINDOW = 2.2

local function setupCharacter(player, char)
    if player == LocalPlayer then return end

    local hum = char:WaitForChild("Humanoid")
    local lastHp = hum.Health

    hum.HealthChanged:Connect(function(hp)
        local myChar = LocalPlayer.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myHum or myHum.Health <= 0 then return end

        if hp < lastHp then
            if isAttacking()
            and currentTarget == player
            and (tick() - lastTargetTime <= TARGET_LOCK_TIME)
            then
                lastHitTime[player] = tick()
            end
        end

        lastHp = hp
    end)

    hum.Died:Connect(function()
        task.delay(0.1, function()
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
end)

Players.PlayerRemoving:Connect(function(p)
    lastHitTime[p] = nil
end)

-- ========================
-- 🧠 UI輔助
-- ========================
local keywords = {"eliminated","killed","擊殺","消滅"}

LocalPlayer.PlayerGui.DescendantAdded:Connect(function(v)
    if not v:IsA("TextLabel") then return end

    local myChar = LocalPlayer.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHum or myHum.Health <= 0 then return end

    local text = string.lower(v.Text)
    for _, k in ipairs(keywords) do
        if text:find(k) and isAttacking() then
            play()
            break
        end
    end
end)

print("🔥 多殺修正版已啟動（每殺必響）並已預約自動換服執行")