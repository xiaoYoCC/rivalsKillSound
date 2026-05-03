-- [[ xiaoYo 擊殺音效穩定版 ]]
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- 確保環境支援
if not (writefile and getcustomasset and isfile) then
    print("❌ 執行器不支援自定義音效")
    return
end

-- 自動下載音效函數
local function getAudio(name, url)
    if not isfile(name) then
        local success, res = pcall(function() return game:HttpGet(url) end)
        if success then 
            writefile(name, res) 
        else
            return nil
        end
    end
    return getcustomasset(name)
end

-- 注意：這裡的 MP3 網址也要是 RAW 格式！
local killSound = getAudio("xykill.mp3", "https://raw.githubusercontent.com/xiaoYoCC/rivalsKillSound/main/xykill.mp3")

local function play()
    if not killSound then return end
    local s = Instance.new("Sound", game:GetService("SoundService"))
    s.SoundId = killSound
    s.Volume = 3
    s:Play()
    game:GetService("Debris"):AddItem(s, 5)
end

-- Rivals 擊殺偵測 (Leaderstats 方式最穩)
task.spawn(function()
    local stats = player:WaitForChild("leaderstats", 20)
    local kills = stats:WaitForChild("Kills", 20)
    kills.Changed:Connect(function()
        print("🎯 偵測到擊殺！播放音效")
        play()
    end)
end)

print("✅ 腳本已成功執行！等待擊殺中...")
