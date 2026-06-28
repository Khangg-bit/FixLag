--[[
    ULTIMATE FPS BOOSTER - Delta Executor
    Tăng FPS tối đa bằng cách:
    - Ép tất cả Texture về SmoothPlastic
    - Tắt toàn bộ đổ bóng (Shadow)
    - Dọn sạch hiệu ứng hạt (Particles)
    - Giảm chất lượng rendering
    - Tắt các hiệu ứng không cần thiết
--]]

-- Services
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

-- Settings
local Settings = {
    Enabled = true,
    TextureToPlastic = true,     -- Ép texture về SmoothPlastic
    DisableShadows = true,       -- Tắt đổ bóng
    RemoveParticles = true,      -- Xóa hiệu ứng hạt
    LowGraphics = true,          -- Giảm chất lượng đồ họa
    DisableEffects = true,       -- Tắt hiệu ứng đặc biệt
    DisableNeon = true,          -- Tắt đèn neon
    ReduceRenderDistance = true, -- Giảm khoảng cách render
    DisableDecals = true,        -- Tắt decals
    DisableTextures = true,      -- Tắt textures
    AutoClean = true,            -- Tự động dọn khi có object mới
    CleanInterval = 3,           -- Thời gian dọn định kỳ (giây)
}

-- Biến lưu connection
local CleanConnection = nil
local NewObjectConnection = nil
local OriginalSettings = {}

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FPSBooster"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local MenuGui
local MainFrame

-- Notify
local function Notify(text, duration)
    pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "FPSNotify"
        gui.Parent = CoreGui
        gui.ResetOnSpawn = false
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 320, 0, 40)
        frame.Position = UDim2.new(0.5, -160, 0, 20)
        frame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
        frame.BorderSizePixel = 0
        frame.Parent = gui
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        
        local glow = Instance.new("Frame")
        glow.Size = UDim2.new(1, 4, 1, 4)
        glow.Position = UDim2.new(0, -2, 0, -2)
        glow.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
        glow.BackgroundTransparency = 0.7
        glow.BorderSizePixel = 0
        glow.ZIndex = 0
        glow.Parent = frame
        Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 12)
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 220, 100)
        label.TextSize = 14
        label.Font = Enum.Font.GothamBold
        label.Parent = frame
        task.delay(duration or 2, function() pcall(function() gui:Destroy() end) end)
    end)
end

-- Toggle
local function CreateToggle(parent, text, yPos, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 32)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 44, 0, 22)
    btn.Position = UDim2.new(1, -48, 0.5, -11)
    btn.BorderSizePixel = 0
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 11)

    local state = default
    local function updateVisual()
        if state then
            btn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
            btn.Text = "ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            btn.Text = "OFF"
        end
    end
    updateVisual()

    btn.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()
        if callback then callback(state) end
    end)

    return {
        GetState = function() return state end,
        SetState = function(s)
            state = s
            updateVisual()
            if callback then callback(state) end
        end
    }
end

-- Tạo Button
local function CreateButton(parent, text, yPos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    return btn
end

-- FPS Counter
local FPSLabel = nil
local function CreateFPSCounter(parent)
    FPSLabel = Instance.new("TextLabel")
    FPSLabel.Size = UDim2.new(1, -20, 0, 30)
    FPSLabel.Position = UDim2.new(0, 10, 0, 10)
    FPSLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    FPSLabel.BorderSizePixel = 0
    FPSLabel.Text = "FPS: --"
    FPSLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
    FPSLabel.TextSize = 14
    FPSLabel.Font = Enum.Font.GothamBold
    FPSLabel.Parent = parent
    Instance.new("UICorner", FPSLabel).CornerRadius = UDim.new(0, 6)
end

local lastFrameTime = tick()
local frameCount = 0
local currentFPS = 0

local function UpdateFPS()
    frameCount = frameCount + 1
    local now = tick()
    local elapsed = now - lastFrameTime
    if elapsed >= 0.5 then
        currentFPS = math.floor(frameCount / elapsed)
        frameCount = 0
        lastFrameTime = now
        if FPSLabel then
            local color
            if currentFPS >= 60 then
                color = Color3.fromRGB(100, 255, 100)
            elseif currentFPS >= 30 then
                color = Color3.fromRGB(255, 200, 50)
            else
                color = Color3.fromRGB(255, 80, 80)
            end
            FPSLabel.Text = "⚡ FPS: " .. currentFPS
            FPSLabel.TextColor3 = color
        end
    end
end

-- LƯU CÀI ĐẶT GỐC
local function SaveOriginalSettings()
    OriginalSettings = {
        GlobalShadows = Lighting.GlobalShadows,
        ShadowSoftness = Lighting.ShadowSoftness,
        Brightness = Lighting.Brightness,
        ExposureCompensation = Lighting.ExposureCompensation,
        BloomEnabled = Lighting.BloomEnabled or false,
        DepthOfFieldEnabled = Lighting.DepthOfFieldEnabled or false,
        SunRaysEnabled = Lighting.SunRaysEnabled or false,
        Technology = Lighting.Technology,
        GraphicsMode = Workspace.GraphicsMode or "Default",
        StreamingEnabled = Workspace.StreamingEnabled,
    }
    pcall(function()
        OriginalSettings.TerrainDecoration = Workspace.Terrain.Decoration
    end)
end

-- KHÔI PHỤC CÀI ĐẶT GỐC
local function RestoreOriginalSettings()
    pcall(function() Lighting.GlobalShadows = OriginalSettings.GlobalShadows end)
    pcall(function() Lighting.ShadowSoftness = OriginalSettings.ShadowSoftness end)
    pcall(function() Lighting.Brightness = OriginalSettings.Brightness end)
    pcall(function() Lighting.ExposureCompensation = OriginalSettings.ExposureCompensation end)
    pcall(function() Lighting.Technology = OriginalSettings.Technology end)
    pcall(function() Workspace.GraphicsMode = OriginalSettings.GraphicsMode end)
    pcall(function() Workspace.StreamingEnabled = OriginalSettings.StreamingEnabled end)
    pcall(function() Workspace.Terrain.Decoration = OriginalSettings.TerrainDecoration end)
end

-- ÉP TEXTURE VỀ SMOOTH PLASTIC
local function SetSmoothPlastic(part)
    if not part:IsA("BasePart") and not part:IsA("UnionOperation") and not part:IsA("MeshPart") then return end
    
    -- Ép Material về SmoothPlastic
    if Settings.TextureToPlastic then
        pcall(function()
            if part.Material ~= Enum.Material.SmoothPlastic then
                part.Material = Enum.Material.SmoothPlastic
            end
        end)
    end
    
    -- Tắt textures
    if Settings.DisableTextures then
        pcall(function()
            if part:FindFirstChild("Texture") then
                part.Texture:Destroy()
            end
            if part:FindFirstChild("Decal") then
                part.Decal:Destroy()
            end
        end)
    end
    
    -- Xóa SurfaceAppearance
    pcall(function()
        local surfaceAppearance = part:FindFirstChild("SurfaceAppearance")
        if surfaceAppearance then
            surfaceAppearance:Destroy()
        end
    end)
end

-- TẮT ĐỔ BÓNG
local function DisableShadows()
    if not Settings.DisableShadows then return end
    
    -- Tắt shadow toàn cục
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 0
    end)
    
    -- Tắt shadow trên từng part
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("UnionOperation") or part:IsA("MeshPart") then
            pcall(function()
                part.CastShadow = false
                part.ShadowZIndex = -1
            end)
        end
    end
    
    -- Tắt sun rays
    pcall(function()
        Lighting.SunRaysEnabled = false
        Lighting.BloomEnabled = false
        Lighting.DepthOfFieldEnabled = false
    end)
end

-- XÓA HIỆU ỨNG HẠT
local function RemoveParticles()
    if not Settings.RemoveParticles then return end
    
    local removedCount = 0
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            pcall(function()
                obj.Enabled = false
                obj:Destroy()
                removedCount = removedCount + 1
            end)
        end
    end
    
    -- Xóa trails
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Trail") then
            pcall(function()
                obj.Enabled = false
                obj:Destroy()
            end)
        end
    end
    
    return removedCount
end

-- GIẢM CHẤT LƯỢNG ĐỒ HỌA
local function ApplyLowGraphics()
    if not Settings.LowGraphics then return end
    
    -- Giảm chất lượng render
    pcall(function()
        Lighting.Technology = Enum.Technology.Compatibility
        Lighting.Brightness = 1.5
        Lighting.ExposureCompensation = 0.1
    end)
    
    -- Giảm graphics mode
    pcall(function()
        Workspace.GraphicsMode = "Direct3D11LowMemory"
        Workspace.StreamingEnabled = true
        Workspace.StreamingMinRadius = 32
        Workspace.StreamingTargetRadius = 64
    end)
    
    -- Giảm chất lượng terrain
    pcall(function()
        Workspace.Terrain.Decoration = false
        Workspace.Terrain.WaterReflectance = 0
        Workspace.Terrain.WaterTransparency = 0.3
    end)
    
    -- Tắt anti-aliasing (qua lighting)
    pcall(function()
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
    end)
end

-- TẮT HIỆU ỨNG ĐẶC BIỆT
local function DisableSpecialEffects()
    if not Settings.DisableEffects then return end
    
    -- Tắt tất cả post-processing
    pcall(function()
        Lighting.BloomEnabled = false
        Lighting.DepthOfFieldEnabled = false
        Lighting.SunRaysEnabled = false
        Lighting.ColorCorrectionEnabled = false
        Lighting.FogEnd = 99999
        Lighting.FogStart = 99998
    end)
    
    -- Xóa hiệu ứng âm thanh không cần
    for _, sound in pairs(Workspace:GetDescendants()) do
        if sound:IsA("Sound") and (sound.Name:lower():find("ambient") or sound.Name:lower():find("wind") or sound.Name:lower():find("bgm")) then
            pcall(function() sound:Stop() end)
        end
    end
end

-- TẮT ĐÈN NEON
local function DisableNeonLights()
    if not Settings.DisableNeon then return end
    
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                if part.Material == Enum.Material.Neon then
                    part.Material = Enum.Material.SmoothPlastic
                end
            end)
        end
    end
    
    -- Tắt PointLight, SpotLight, SurfaceLight
    for _, light in pairs(Workspace:GetDescendants()) do
        if light:IsA("PointLight") or light:IsA("SpotLight") or light:IsA("SurfaceLight") then
            pcall(function()
                light.Enabled = false
                light.Brightness = 0
            end)
        end
    end
end

-- XÓA DECALS
local function RemoveDecals()
    if not Settings.DisableDecals then return end
    
    for _, decal in pairs(Workspace:GetDescendants()) do
        if decal:IsA("Decal") or decal:IsA("Texture") then
            pcall(function() decal:Destroy() end)
        end
    end
end

-- GIẢM KHOẢNG CÁCH RENDER
local function ReduceRenderDistance()
    if not Settings.ReduceRenderDistance then return end
    
    pcall(function()
        Workspace.StreamingEnabled = true
        Workspace.StreamingMinRadius = 16
        Workspace.StreamingTargetRadius = 48
    end)
end

-- QUÉT TOÀN BỘ MAP
local function FullCleanup()
    local startTime = tick()
    local totalCleaned = 0
    
    -- Ép tất cả parts về SmoothPlastic
    local parts = Workspace:GetDescendants()
    for _, part in pairs(parts) do
        if part:IsA("BasePart") or part:IsA("UnionOperation") or part:IsA("MeshPart") then
            SetSmoothPlastic(part)
            totalCleaned = totalCleaned + 1
            
            -- Tắt shadow trên part
            if Settings.DisableShadows then
                pcall(function() part.CastShadow = false end)
            end
        end
    end
    
    -- Áp dụng các cài đặt
    DisableShadows()
    local particlesRemoved = RemoveParticles()
    ApplyLowGraphics()
    DisableSpecialEffects()
    DisableNeonLights()
    RemoveDecals()
    ReduceRenderDistance()
    
    local elapsed = tick() - startTime
    return totalCleaned, particlesRemoved, elapsed
end

-- XỬ LÝ OBJECT MỚI
local function HandleNewObject(obj)
    if not Settings.AutoClean then return end
    if not Settings.Enabled then return end
    
    -- Ép material cho part mới
    if obj:IsA("BasePart") or obj:IsA("UnionOperation") or obj:IsA("MeshPart") then
        SetSmoothPlastic(obj)
        if Settings.DisableShadows then
            pcall(function() obj.CastShadow = false end)
        end
    end
    
    -- Xóa particle mới
    if (obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Trail")) and Settings.RemoveParticles then
        pcall(function()
            obj.Enabled = false
            task.wait(0.1)
            obj:Destroy()
        end)
    end
    
    -- Xóa decal/texture mới
    if (obj:IsA("Decal") or obj:IsA("Texture")) and Settings.DisableDecals then
        pcall(function() obj:Destroy() end)
    end
    
    -- Tắt light mới
    if (obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight")) and Settings.DisableNeon then
        pcall(function() obj.Enabled = false end)
    end
    
    -- Tắt sound effect mới
    if obj:IsA("Sound") and Settings.DisableEffects then
        local name = obj.Name:lower()
        if name:find("ambient") or name:find("wind") or name:find("bgm") or name:find("atmosphere") then
            pcall(function() obj:Stop() end)
        end
    end
end

-- BẬT FPS BOOSTER
local function EnableFPSBooster()
    Settings.Enabled = true
    
    -- Lưu cài đặt gốc
    SaveOriginalSettings()
    
    -- Dọn toàn bộ
    local partsCleaned, particlesRemoved, elapsed = FullCleanup()
    
    -- Theo dõi object mới
    if NewObjectConnection then NewObjectConnection:Disconnect() end
    NewObjectConnection = Workspace.DescendantAdded:Connect(HandleNewObject)
    
    -- Dọn định kỳ
    if CleanConnection then CleanConnection:Disconnect() end
    CleanConnection = RunService.RenderStepped:Connect(function()
        UpdateFPS()
    end)
    
    -- Dọn định kỳ mỗi CleanInterval giây
    coroutine.wrap(function()
        while Settings.Enabled do
            task.wait(Settings.CleanInterval)
            if Settings.Enabled then
                RemoveParticles()
                RemoveDecals()
                DisableNeonLights()
            end
        end
    end)()
    
    Notify("🚀 FPS Booster đã bật! Đã dọn " .. partsCleaned .. " parts", 3)
    print(string.format("FPS Booster: %d parts cleaned, %d particles removed in %.2fs", partsCleaned, particlesRemoved, elapsed))
end

-- TẮT FPS BOOSTER
local function DisableFPSBooster()
    Settings.Enabled = false
    
    -- Ngắt connections
    if CleanConnection then
        CleanConnection:Disconnect()
        CleanConnection = nil
    end
    if NewObjectConnection then
        NewObjectConnection:Disconnect()
        NewObjectConnection = nil
    end
    
    -- Khôi phục cài đặt gốc
    RestoreOriginalSettings()
    
    if FPSLabel then
        FPSLabel.Text = "FPS: OFF"
        FPSLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
    
    Notify("⏸️ FPS Booster đã tắt - Đã khôi phục cài đặt gốc", 3)
end

-- Tạo Menu
local function CreateMenu()
    MenuGui = Instance.new("ScreenGui")
    MenuGui.Name = "FPSBoosterMenu"
    MenuGui.Parent = CoreGui
    MenuGui.ResetOnSpawn = false
    MenuGui.Enabled = true

    MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 280, 0, 450)
    MainFrame.Position = UDim2.new(0, 15, 0, 80)
    MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = MenuGui
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

    -- Border
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1, 4, 1, 4)
    border.Position = UDim2.new(0, -2, 0, -2)
    border.BackgroundColor3 = Color3.fromRGB(255, 170, 30)
    border.BackgroundTransparency = 0.6
    border.BorderSizePixel = 0
    border.ZIndex = 0
    border.Parent = MainFrame
    Instance.new("UICorner", border).CornerRadius = UDim.new(0, 14)

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 42)
    title.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    title.BorderSizePixel = 0
    title.Text = "⚡ FPS BOOSTER"
    title.TextColor3 = Color3.fromRGB(255, 200, 50)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = MainFrame
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    -- FPS Counter
    CreateFPSCounter(MainFrame)

    -- Separator
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, -20, 0, 1)
    sep.Position = UDim2.new(0, 10, 0, 50)
    sep.BackgroundColor3 = Color3.fromRGB(255, 170, 30)
    sep.BackgroundTransparency = 0.7
    sep.BorderSizePixel = 0
    sep.Parent = MainFrame

    -- Toggles
    local y = 60
    
    -- Master Enable
    CreateToggle(MainFrame, "🚀 Bật FPS Booster", y, Settings.Enabled, function(state)
        if state then
            EnableFPSBooster()
        else
            DisableFPSBooster()
        end
    end)
    y = y + 37
    
    -- Texture to Plastic
    CreateToggle(MainFrame, "🔧 Ép SmoothPlastic", y, Settings.TextureToPlastic, function(state)
        Settings.TextureToPlastic = state
        if Settings.Enabled then FullCleanup() end
    end)
    y = y + 37
    
    -- Disable Shadows
    CreateToggle(MainFrame, "🌑 Tắt đổ bóng", y, Settings.DisableShadows, function(state)
        Settings.DisableShadows = state
        if Settings.Enabled then DisableShadows() end
        if not state and Settings.Enabled then
            pcall(function() Lighting.GlobalShadows = OriginalSettings.GlobalShadows end)
        end
    end)
    y = y + 37
    
    -- Remove Particles
    CreateToggle(MainFrame, "✨ Xóa hiệu ứng hạt", y, Settings.RemoveParticles, function(state)
        Settings.RemoveParticles = state
        if Settings.Enabled and state then RemoveParticles() end
    end)
    y = y + 37
    
    -- Low Graphics
    CreateToggle(MainFrame, "📉 Giảm đồ họa", y, Settings.LowGraphics, function(state)
        Settings.LowGraphics = state
        if Settings.Enabled then ApplyLowGraphics() end
    end)
    y = y + 37
    
    -- Disable Effects
    CreateToggle(MainFrame, "🎆 Tắt hiệu ứng", y, Settings.DisableEffects, function(state)
        Settings.DisableEffects = state
        if Settings.Enabled then DisableSpecialEffects() end
    end)
    y = y + 37
    
    -- Disable Neon
    CreateToggle(MainFrame, "💡 Tắt đèn neon", y, Settings.DisableNeon, function(state)
        Settings.DisableNeon = state
        if Settings.Enabled then DisableNeonLights() end
    end)
    y = y + 37
    
    -- Reduce Render
    CreateToggle(MainFrame, "👁 Giảm render xa", y, Settings.ReduceRenderDistance, function(state)
        Settings.ReduceRenderDistance = state
        if Settings.Enabled then ReduceRenderDistance() end
    end)
    y = y + 37
    
    -- Disable Decals
    CreateToggle(MainFrame, "🖼 Xóa decals/textures", y, Settings.DisableDecals, function(state)
        Settings.DisableDecals = state
        if Settings.Enabled then RemoveDecals() end
    end)
    y = y + 37
    
    -- Auto Clean
    CreateToggle(MainFrame, "🔄 Tự động dọn", y, Settings.AutoClean, function(state)
        Settings.AutoClean = state
    end)
    y = y + 47

    -- Buttons
    CreateButton(MainFrame, "🔧 Dọn toàn bộ ngay", y, Color3.fromRGB(255, 150, 30), function()
        if Settings.Enabled then
            local parts, particles, elapsed = FullCleanup()
            Notify("✅ Đã dọn " .. parts .. " parts, " .. particles .. " particles!", 3)
        else
            Notify("⚠️ Hãy bật FPS Booster trước!", 2)
        end
    end)
    y = y + 42
    
    CreateButton(MainFrame, "🔄 Khôi phục gốc", y, Color3.fromRGB(200, 60, 60), function()
        DisableFPSBooster()
        RestoreOriginalSettings()
        Notify("✅ Đã khôi phục cài đặt gốc!", 2)
    end)

    return MenuGui
end

-- Khởi tạo
CreateMenu()

-- FPS Counter update
RunService.RenderStepped:Connect(function()
    if Settings.Enabled then
        UpdateFPS()
    end
end)

-- Auto-enable
task.wait(0.5)
SaveOriginalSettings()
EnableFPSBooster()

-- Cleanup
LocalPlayer.OnTeleport:Connect(function()
    DisableFPSBooster()
    if ScreenGui then ScreenGui:Destroy() end
    if MenuGui then MenuGui:Destroy() end
end)

Notify("⚡ FPS Booster Loaded! Đang tối ưu...", 2)
print("=================================")
print("⚡ ULTIMATE FPS BOOSTER LOADED!")
print("✅ Tự động ép SmoothPlastic")
print("✅ Tắt đổ bóng")
print("✅ Xóa hiệu ứng hạt")
print("✅ Giảm đồ họa")
print("=================================")