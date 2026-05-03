-- [[ xiaoYo 音效分發版 ]]
-- 檢查執行器環境
if not (writefile and getcustomasset and isfile) then
    game.Players.LocalPlayer:Kick("你的執行器太爛了，不支援自定義音效功能")
    return
end

local function getAudio(name, url)
    if not isfile(name) then
        local success, res = pcall(function()
            return game:HttpGet(url) -- 使用 HttpGet 更簡單
        end)
        if success then writefile(name, res) end
    end
    return getcustomasset(name)
end

-- 設定音效 (範例網址，記得換成你自己的)
local killSound = getAudio("xy_kill.mp3", "https://github.com/xiaoYoCC/rivalsKillSound/blob/1dfea86f260505e92fe52381cdf9c0548c5cb7ff/xykill.mp3")

local function play(id)
    local s = Instance.new("Sound", game:GetService("SoundService"))
    s.SoundId = id
    s.Volume = 2
    s:Play()
    game:GetService("Debris"):AddItem(s, 5)
end

-- Rivals 邏輯
local player = game.Players.LocalPlayer
local kills = player:WaitForChild("leaderstats"):WaitForChild("Kills")

-- 擊殺偵測
kills.Changed:Connect(function()
    play(killSound)
end)

-- 打擊偵測 (監聽 UI 標記)
player.PlayerGui.DescendantAdded:Connect(function(v)
    if v.Name == "Hitmarker" or v.Name:find("Damage") then
        play(hitSound)
    end
end)

print("✨ xiaoYo 雲端音效腳本已載入！")
