-- [[ xiaoYo Rivals 自訂擊殺音效 - 核心代碼 ]]
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- 設定區
local fileName = "xykill.mp3"
local githubRawUrl = "https://raw.githubusercontent.com/xiaoYoCC/rivalsKillSound/main/xykill.mp3"

-- [[ 資源處理函數 ]]
local function getAsset()
    -- 1. 檢查本地 workspace 是否已有檔案
    if isfile and isfile(fileName) then
        print("✅ 偵測到本地音效檔，直接載入")
        return getcustomasset(fileName)
    end
    
    -- 2. 如果沒有本地檔，嘗試自動下載 (給朋友用時很方便)
    if writefile and readfile then
        print("📥 本地無檔案，嘗試從雲端下載...")
        local success, content = pcall(function() return game:HttpGet(githubRawUrl) end)
        if success and content and not content:find("<!DOCTYPE") then
            writefile(fileName, content)
            print("✅ 雲端下載成功")
            return getcustomasset(fileName)
        end
    end
    
    -- 3. 如果都失敗，使用保底音效 ID (避免腳本報錯)
    warn("⚠️ 無法獲取自訂音效，使用預設 ID")
    return "rbxassetid://117487354926114" 
end

local killAudio = getAsset()

-- [[ 播放邏輯 ]]
local function play()
    if not killAudio then return end
    local s = Instance.new("Sound", game:GetService("SoundService"))
    s.SoundId = killAudio
    s.Volume = 3
    s:Play()
    game:GetService("Debris"):AddItem(s, 5)
end

-- [[ Rivals 擊殺偵測系統 ]]
task.spawn(function()
    -- 方式一：偵測 Leaderstats 數值變動 (最穩)
    local stats = player:WaitForChild("leaderstats", 20)
    local kills = stats and stats:WaitForChild("Kills", 20)
    
    if kills then
        local lastKills = kills.Value
        kills.Changed:Connect(function(newVal)
            if newVal > lastKills then
                print("🎯 擊殺成功！播放音效")
                play()
            end
            lastKills = newVal
        end)
    end
    
    -- 方式二：偵測 UI 標籤 (雙重保險)
    player.PlayerGui.DescendantAdded:Connect(function(v)
        if v:IsA("TextLabel") and (v.Text:find("ELIMINATED") or v.Text:find("擊殺")) then
            play()
        end
    end)
end)

-- [[ 測試按鈕 (僅限手機版方便調試) ]]
local sg = Instance.new("ScreenGui", player.PlayerGui)
sg.Name = "xiaoYo_TestUI"
local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 120, 0, 40)
btn.Position = UDim2.new(0.5, -60, 0.05, 0)
btn.Text = "測試音效 (點我)"
btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btn.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", btn)

btn.MouseButton1Click:Connect(function()
    play()
    print("🔊 測試播放中...")
end)

-- 15秒後自動移除測試按鈕
task.delay(15, function() sg:Destroy() end)

print("✨ xiaoYo 腳本加載完畢 -祝你在 Rivals 殺得愉快！")
