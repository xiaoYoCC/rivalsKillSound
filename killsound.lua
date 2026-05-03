-- [[ xiaoYo Rivals 自訂擊殺音效系統 ]]
-- 核心檢查：確保執行器支援必要的函數
if not (writefile and getcustomasset and isfile) then
    return warn("❌ 你的執行器不支援自定義資產功能（getcustomasset）")
end

local function getAudio(name, url)
    local path = name
    if not isfile(path) then
        print("📥 正在從 GitHub 下載音效...")
        local success, content = pcall(function() return game:HttpGet(url) end)
        if success and content then
            writefile(path, content)
            print("✅ 音效下載成功：" .. name)
        else
            warn("❌ 下載失敗，請檢查網路或網址")
            return nil
        end
    end
    return getcustomasset(path)
end

-- [[ 設定區 ]]
-- 這裡使用轉換後的 Raw 網址
local killAudioID = getAudio("xykill.mp3", "https://raw.githubusercontent.com/xiaoYoCC/rivalsKillSound/main/xykill.mp3")

local function playKillSound()
    if not killAudioID then return end
    local sound = Instance.new("Sound")
    sound.SoundId = killAudioID
    sound.Volume = 2.5
    sound.Parent = game:GetService("SoundService")
    sound.PlayOnRemove = true
    sound:Play()
    sound:Destroy()
end

--------------------------------------------------
-- 🎯 Rivals 擊殺偵測邏輯
--------------------------------------------------
local player = game.Players.LocalPlayer

-- 方式 A：監控 Leaderstats (最準確的擊殺判定)
task.spawn(function()
    local stats = player:WaitForChild("leaderstats", 10)
    if stats then
        local kills = stats:WaitForChild("Kills", 10)
        if kills then
            kills.Changed:Connect(function()
                -- 只要擊殺數變動，就播放音效
                playKillSound()
            end)
        end
    end
end)

-- 方式 B：監控擊殺提示 UI (雙重保險)
player.PlayerGui.DescendantAdded:Connect(function(desc)
    -- Rivals 的擊殺 UI 標籤通常包含 "Kill" 或 "Eliminated"
    if desc.Name == "KillFeedItem" or (desc:IsA("TextLabel") and desc.Text:find("ELIMINATED")) then
        playKillSound()
    end
end)

print("✨ xiaoYo 擊殺音效腳本已啟動！")
print("🔊 目前載入：xykill.mp3")
