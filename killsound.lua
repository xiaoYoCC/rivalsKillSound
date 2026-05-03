-- [[ xiaoYo Rivals 擊殺音效 - 音量調小版 ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local SoundService = game:GetService("SoundService")

-- 1. 取得音效 (讀取你 workspace 裡的檔案)
local function getAudio()
    local fileName = "xykill.mp3"
    if isfile and isfile(fileName) then
        return getcustomasset(fileName)
    end
    -- 如果找不到檔案，用一個官方 ID 當保底測試
    return "rbxassetid://117487354926114"
end

local killAudio = getAudio()

-- 2. 播放函數
local function play()
    if not killAudio then return end
    local s = Instance.new("Sound", SoundService)
    s.SoundId = killAudio
    
    -- 📢 【音量設定在這裡】 
    -- 原本是 5，現在改為 0.5 (大約是原本的 1/10)
    s.Volume = 1 
    
    s:Play()
    game:GetService("Debris"):AddItem(s, 5) -- 5秒後自動刪除音效物件
end

-- 3. 擊殺偵測邏輯 (維持強化版)
task.spawn(function()
    local stats = player:WaitForChild("leaderstats", 30)
    local kills = stats:WaitForChild("Kills", 30)
    local lastKills = kills.Value
    kills.Changed:Connect(function(newVal)
        if newVal > lastKills then
            play()
        end
        lastKills = newVal
    end)
end)

-- 螢幕文字偵測 (手機版最準的方法)
player.PlayerGui.DescendantAdded:Connect(function(v)
    if v:IsA("TextLabel") then
        if v.Text:find("ELIMINATED") or v.Text:find("擊殺") then
            play()
        end
    end
end)

print("✅ 音量已調小至 0.5，偵測系統運行中...")
