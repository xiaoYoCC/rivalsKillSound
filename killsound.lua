-- [[ xiaoYo Rivals 擊殺音效 - 雲端自動版 ]]
local player = game.Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- 下載器
local function getAudio(name, url)
    if not isfile(name) then
        local success, content = pcall(function() return game:HttpGet(url) end)
        if success and content then
            writefile(name, content)
            print("✅ 下載成功: " .. name)
        else
            return nil
        end
    end
    return getcustomasset(name)
end

-- 🎵 這裡我已經幫你換成 Raw 直鏈了
local killAudio = getAudio("xykill.mp3", "https://raw.githubusercontent.com/xiaoYoCC/rivalsKillSound/main/xykill.mp3")

-- 播放函數
local function play()
    if not killAudio then return end
    local s = Instance.new("Sound", game:GetService("SoundService"))
    s.SoundId = killAudio
    s.Volume = 3
    s:Play()
    game:GetService("Debris"):AddItem(s, 5)
end

-- 🎯 Rivals 擊殺偵測邏輯
task.spawn(function()
    local stats = player:WaitForChild("leaderstats", 30)
    local kills = stats:WaitForChild("Kills", 30)
    kills.Changed:Connect(function()
        play()
    end)
end)

print("🚀 xiaoYo 擊殺音效系統已載入！")
