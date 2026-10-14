-- Kiểm tra dịch vụ và người chơi
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Xóa UI cũ nếu có để tránh trùng lặp
if CoreGui:FindFirstChild("DungLevelCheckGUI") then
    CoreGui.DungLevelCheckGUI:Destroy()
end

-- Biến lưu trạng thái cấu hình
local activeWebhook = ""
local selectedInterval = 300 -- Mặc định 5 phút (300 giây)
local isRunning = false
local connectionThread = nil

-- Bảng định nghĩa màu sắc cho UI
local ColorThemes = {
    ["Đen"] = {Main = Color3.fromRGB(20, 20, 25), Top = Color3.fromRGB(35, 35, 45), Text = Color3.fromRGB(255, 255, 255)},
    ["Trắng"] = {Main = Color3.fromRGB(240, 240, 245), Top = Color3.fromRGB(210, 210, 220), Text = Color3.fromRGB(30, 30, 30)},
    ["Xám"] = {Main = Color3.fromRGB(70, 70, 80), Top = Color3.fromRGB(90, 90, 100), Text = Color3.fromRGB(255, 255, 255)},
    ["Aqua"] = {Main = Color3.fromRGB(20, 50, 60), Top = Color3.fromRGB(30, 80, 95), Text = Color3.fromRGB(255, 255, 255)},
    ["Xanh Nước"] = {Main = Color3.fromRGB(20, 35, 65), Top = Color3.fromRGB(35, 60, 110), Text = Color3.fromRGB(255, 255, 255)},
    ["Tím"] = {Main = Color3.fromRGB(45, 20, 60), Top = Color3.fromRGB(75, 35, 95), Text = Color3.fromRGB(255, 255, 255)},
    ["Xanh Lá Nhạt"] = {Main = Color3.fromRGB(35, 60, 45), Top = Color3.fromRGB(55, 95, 70), Text = Color3.fromRGB(255, 255, 255)}
}

-- Tạo ScreenGui chính
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DungLevelCheckGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Khung chính của Menu (Main Frame)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = ColorThemes["Đen"].Main
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -160)
MainFrame.Size = UDim2.new(0, 350, 0, 320)
MainFrame.Active = true
MainFrame.Draggable = true -- Cho phép kéo thả GUI

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Thanh tiêu đề (TopBar)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = ColorThemes["Đen"].Top
TopBar.BorderSizePixel = 0
TopBar.Size = UDim2.new(1, 0, 0, 40)

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 10)
TopBarCorner.Parent = TopBar

-- Tiêu đề text
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = TopBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.Size = UDim2.new(0, 250, 1, 0)
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Text = "📊 DungLevel Check"
TitleLabel.TextColor3 = ColorThemes["Đen"].Text
TitleLabel.TextSize = 17
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Nút Thu Nhỏ / Phóng To (-)
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Parent = TopBar
MinimizeButton.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
MinimizeButton.Position = UDim2.new(1, -35, 0.5, -12)
MinimizeButton.Size = UDim2.new(0, 24, 0, 24)
MinimizeButton.Font = Enum.Font.SourceSansBold
MinimizeButton.Text = "-"
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.TextSize = 18

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinimizeButton

-- Khu vực chứa nội dung bên trong
local ContentContainer = Instance.new("ScrollingFrame")
ContentContainer.Name = "ContentContainer"
ContentContainer.Parent = MainFrame
ContentContainer.Active = true
ContentContainer.BackgroundTransparency = 1
ContentContainer.Position = UDim2.new(0, 15, 0, 50)
ContentContainer.Size = UDim2.new(1, -30, 1, -60)
ContentContainer.CanvasSize = UDim2.new(0, 0, 0, 260)
ContentContainer.ScrollBarThickness = 4

-- 1. Ô nhập Webhook URL (Trống mặc định)
local WebhookLabel = Instance.new("TextLabel")
WebhookLabel.Parent = ContentContainer
WebhookLabel.BackgroundTransparency = 1
WebhookLabel.Size = UDim2.new(1, 0, 0, 20)
WebhookLabel.Font = Enum.Font.SourceSansBold
WebhookLabel.Text = "Discord Webhook URL:"
WebhookLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
WebhookLabel.TextSize = 14
WebhookLabel.TextXAlignment = Enum.TextXAlignment.Left

local WebhookInput = Instance.new("TextBox")
WebhookInput.Name = "WebhookInput"
WebhookInput.Parent = ContentContainer
WebhookInput.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
WebhookInput.Position = UDim2.new(0, 0, 0, 22)
WebhookInput.Size = UDim2.new(1, 0, 0, 32)
WebhookInput.ClearTextOnFocus = false
WebhookInput.Font = Enum.Font.SourceSans
WebhookInput.PlaceholderText = "Dán link Webhook vào đây..."
WebhookInput.Text = "" -- Đã xoá Webhook cá nhân
WebhookInput.TextColor3 = Color3.fromRGB(255, 255, 255)
WebhookInput.TextSize = 13
WebhookInput.TextXAlignment = Enum.TextXAlignment.Left

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = WebhookInput

-- 2. Chọn Mốc Thời Gian
local TimeLabel = Instance.new("TextLabel")
TimeLabel.Parent = ContentContainer
TimeLabel.BackgroundTransparency = 1
TimeLabel.Position = UDim2.new(0, 0, 0, 60)
TimeLabel.Size = UDim2.new(1, 0, 0, 20)
TimeLabel.Font = Enum.Font.SourceSansBold
TimeLabel.Text = "Chọn Thời Gian Gửi:"
TimeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TimeLabel.TextSize = 14
TimeLabel.TextXAlignment = Enum.TextXAlignment.Left

local TimeButtonHolder = Instance.new("Frame")
TimeButtonHolder.Parent = ContentContainer
TimeButtonHolder.BackgroundTransparency = 1
TimeButtonHolder.Position = UDim2.new(0, 0, 0, 82)
TimeButtonHolder.Size = UDim2.new(1, 0, 0, 30)

local TimeLayout = Instance.new("UIListLayout")
TimeLayout.Parent = TimeButtonHolder
TimeLayout.FillDirection = Enum.FillDirection.Horizontal
TimeLayout.Padding = UDim.new(0, 5)

local intervals = {
    {name = "3m", seconds = 180},
    {name = "5m", seconds = 300},
    {name = "10m", seconds = 600},
    {name = "30m", seconds = 1800},
    {name = "60m", seconds = 3600}
}
local timeButtons = {}

for _, info in ipairs(intervals) do
    local btn = Instance.new("TextButton")
    btn.Parent = TimeButtonHolder
    btn.Size = UDim2.new(0, 59, 0, 28)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = info.name
    btn.TextSize = 13
    btn.BackgroundColor3 = (info.seconds == 300) and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(50, 50, 65)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    timeButtons[info.seconds] = btn
    
    btn.MouseButton1Click:Connect(function()
        selectedInterval = info.seconds
        for sec, b in pairs(timeButtons) do
            b.BackgroundColor3 = (sec == selectedInterval) and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(50, 50, 65)
        end
    end)
end

-- 3. Chọn Màu Giao Diện (Theme Color)
local ThemeLabel = Instance.new("TextLabel")
ThemeLabel.Parent = ContentContainer
ThemeLabel.BackgroundTransparency = 1
ThemeLabel.Position = UDim2.new(0, 0, 0, 118)
ThemeLabel.Size = UDim2.new(1, 0, 0, 20)
ThemeLabel.Font = Enum.Font.SourceSansBold
ThemeLabel.Text = "Chọn Màu Giao Diện UI:"
ThemeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ThemeLabel.TextSize = 14
ThemeLabel.TextXAlignment = Enum.TextXAlignment.Left

local ThemeScroll = Instance.new("ScrollingFrame")
ThemeScroll.Parent = ContentContainer
ThemeScroll.BackgroundTransparency = 1
ThemeScroll.Position = UDim2.new(0, 0, 0, 140)
ThemeScroll.Size = UDim2.new(1, 0, 0, 32)
ThemeScroll.CanvasSize = UDim2.new(0, 520, 0, 0)
ThemeScroll.ScrollBarThickness = 2

local ThemeLayout = Instance.new("UIListLayout")
ThemeLayout.Parent = ThemeScroll
ThemeLayout.FillDirection = Enum.FillDirection.Horizontal
ThemeLayout.Padding = UDim.new(0, 5)

local themeNames = {"Đen", "Trắng", "Xám", "Aqua", "Xanh Nước", "Tím", "Xanh Lá Nhạt"}

for _, name in ipairs(themeNames) do
    local tBtn = Instance.new("TextButton")
    tBtn.Parent = ThemeScroll
    tBtn.Size = UDim2.new(0, 70, 0, 26)
    tBtn.Font = Enum.Font.SourceSansBold
    tBtn.Text = name
    tBtn.TextSize = 12
    tBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    tBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 6)
    tCorner.Parent = tBtn
    
    tBtn.MouseButton1Click:Connect(function()
        local theme = ColorThemes[name]
        if theme then
            MainFrame.BackgroundColor3 = theme.Main
            TopBar.BackgroundColor3 = theme.Top
            TitleLabel.TextColor3 = theme.Text
        end
    end)
end

-- 4. Nút Bật / Tắt Theo Dõi
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ContentContainer
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
ToggleButton.Position = UDim2.new(0, 0, 0, 185)
ToggleButton.Size = UDim2.new(1, 0, 0, 38)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Text = "▶ BẮT ĐẦU THEO DÕI"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 15

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleButton

-- Hàm lấy Level Blox Fruits
local function getPlayerLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    if data then
        local level = data:FindFirstChild("Level")
        if level then
            return level.Value
        end
    end
    return "Không xác định"
end

-- Hàm gửi thông tin qua Webhook
local function sendToDiscord(username, level, statusText, targetWebhook)
    if not targetWebhook or targetWebhook == "" then return end

    local data = {
        ["content"] = "",
        ["embeds"] = {
            {
                ["title"] = "📊 **DungLevel Check - Blox Fruits**",
                ["color"] = 65280,
                ["fields"] = {
                    {
                        ["name"] = "👤 **Username:**",
                        ["value"] = tostring(username),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "⭐ **Level Hiện Tại:**",
                        ["value"] = tostring(level),
                        ["inline"] = true
                    },
                    {
                        ["name"] = "📌 **Trạng Thái:**",
                        ["value"] = tostring(statusText),
                        ["inline"] = false
                    }
                },
                ["footer"] = {
                    ["text"] = "DungLevel Check • " .. os.date("%H:%M:%S - %d/%m/%Y")
                }
            }
        }
    }

    local jsonBody = HttpService:JSONEncode(data)
    local requestFunc = syn and syn.request or http_request or request or HttpPost
    
    if requestFunc then
        pcall(function()
            requestFunc({
                Url = targetWebhook,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonBody
            })
        end)
    end
end

-- Thu nhỏ / Phóng to
local isMinimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame:TweenSize(UDim2.new(0, 350, 0, 40), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        ContentContainer.Visible = false
        MinimizeButton.Text = "+"
    else
        MainFrame:TweenSize(UDim2.new(0, 350, 0, 320), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        ContentContainer.Visible = true
        MinimizeButton.Text = "-"
    end
end)

-- Bật / Tắt Theo Dõi
ToggleButton.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    activeWebhook = WebhookInput.Text
    
    if isRunning then
        if activeWebhook == "" or activeWebhook == " " then
            warn("Vui lòng điền Webhook URL trước khi bật!")
            isRunning = false
            return
        end
        
        ToggleButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        ToggleButton.Text = "⏹ DỪNG THEO DÕI"
        WebhookInput.TextEditable = false
        
        connectionThread = task.spawn(function()
            local username = LocalPlayer.Name
            local lastLevel = nil
            
            local currentLevel = getPlayerLevel()
            sendToDiscord(username, currentLevel, "🚀 Bắt đầu theo dõi từ DungLevel Check!", activeWebhook)
            lastLevel = currentLevel
            
            while isRunning do
                local elapsed = 0
                while elapsed < selectedInterval and isRunning do
                    task.wait(1)
                    elapsed = elapsed + 1
                end
                
                if not isRunning then break end
                
                currentLevel = getPlayerLevel()
                if currentLevel ~= lastLevel then
                    sendToDiscord(username, currentLevel, "🎉 Chúc mừng! Người chơi vừa lên cấp!", activeWebhook)
                    lastLevel = currentLevel
                else
                    sendToDiscord(username, currentLevel, "⏰ Cập nhật định kỳ.", activeWebhook)
                end
            end
        end)
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        ToggleButton.Text = "▶ BẮT ĐẦU THEO DÕI"
        WebhookInput.TextEditable = true
        if connectionThread then
            task.cancel(connectionThread)
            connectionThread = nil
        end
    end
end)
