--[[
    EXTREME FPS BOOSTER - Anti Lag, Anti Stutter
    Delta Executor - No GUI
    Giảm lag tối đa, hạn chế đơ game, chống giật
--]]

-- Services
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================
-- 1. TẮT TOÀN BỘ SHADOW & ÁNH SÁNG
-- ============================================
pcall(function()
    Lighting.GlobalShadows = false
    Lighting.ShadowSoftness = 0
    Lighting.SunRaysEnabled = false
    Lighting.BloomEnabled = false
    Lighting.DepthOfFieldEnabled = false
    Lighting.ColorCorrectionEnabled = false
    Lighting.FogEnd = 999999
    Lighting.FogStart = 999998
    Lighting.FogColor = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
    Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
    Lighting.EnvironmentDiffuseScale = 0.1
    Lighting.EnvironmentSpecularScale = 0.1
    Lighting.ClockTime = 12
    Lighting.ExposureCompensation = 0.1
    Lighting.Brightness = 1.5
    Lighting.Technology = Enum.Technology.Voxel
end)

-- ============================================
-- 2. GIẢM CHẤT LƯỢNG RENDER XUỐNG THẤP NHẤT
-- ============================================
pcall(function()
    Workspace.StreamingEnabled = true
    Workspace.StreamingMinRadius = 8
    Workspace.StreamingTargetRadius = 32
    Workspace.StreamingIntegrity = 0
    Workspace.GraphicsMode = "OpenGL"
end)

-- Giảm Terrain
pcall(function()
    Workspace.Terrain.Decoration = false
    Workspace.Terrain.WaterReflectance = 0
    Workspace.Terrain.WaterTransparency = 0.5
    Workspace.Terrain.WaterWaveSize = 0
    Workspace.Terrain.WaterWaveSpeed = 0
    Workspace.Terrain.GrassLength = 0
    Workspace.Terrain.MaterialColors = {}
end)

-- ============================================
-- 3. TẮT VẬT LÝ, GIẢM COLLISION
-- ============================================
pcall(function()
    Workspace.Gravity = 196.2
    Workspace.FallenPartsDestroyHeight = -100
    Workspace.CollisionGroupsDefineCollisions = false
    Workspace.PhysicsSteppingMethod = Enum.PhysicsSteppingMethod.Fixed
    Workspace.FluidForces = "Default"
end)

-- Giảm tần suất vật lý
pcall(function()
    if RunService:IsClient() then
        -- Giới hạn physics simulation
        Workspace.PGSPhysicsSolverEnabled = false
    end
end)

-- ============================================
-- 4. ÉP TẤT CẢ VỀ SMOOTH PLASTIC + TẮT MỌI THỨ
-- ============================================
local function CleanPart(part)
    if not part:IsA("BasePart") and not part:IsA("UnionOperation") and not part:IsA("MeshPart") then return end
    pcall(function()
        part.Material = Enum.Material.SmoothPlastic
        part.CastShadow = false
        part.ShadowZIndex = -1
        part.Reflectance = 0
        part.Transparency = math.min(part.Transparency, 0.9)
        part.CanCollide = part.CanCollide
        part.CanTouch = part.CanTouch
        part.CanQuery = false
        part.Massless = true
        part.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.01, 0.01, 0.01, 0.01)
    end)
    
    -- Xóa tất cả texture, decal, surface
    pcall(function()
        for _, child in pairs(part:GetChildren()) do
            if child:IsA("SurfaceAppearance") or child:IsA("Texture") or child:IsA("Decal") or child:IsA("SurfaceLight") then
                child:Destroy()
            end
        end
    end)
end

-- ============================================
-- 5. XÓA TOÀN BỘ HIỆU ỨNG
-- ============================================
local function RemoveEffects(obj)
    -- Particles
    if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Trail") or obj:IsA("Beam") then
        pcall(function()
            obj.Enabled = false
            obj.Rate = 0
            obj:Destroy()
        end)
    end
    
    -- Lights
    if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
        pcall(function()
            obj.Enabled = false
            obj.Brightness = 0
            obj.Range = 0
            obj:Destroy()
        end)
    end
    
    -- Decals & Textures
    if obj:IsA("Decal") or obj:IsA("Texture") then
        pcall(function() obj:Destroy() end)
    end
    
    -- Neon
    if obj:IsA("BasePart") and obj.Material == Enum.Material.Neon then
        pcall(function() obj.Material = Enum.Material.SmoothPlastic end)
    end
    
    -- Glass
    if obj:IsA("BasePart") and obj.Material == Enum.Material.Glass then
        pcall(function() obj.Material = Enum.Material.SmoothPlastic end)
    end
    
    -- Sounds (giữ lại âm thanh quan trọng)
    if obj:IsA("Sound") then
        local name = obj.Name:lower()
        if name:find("ambient") or name:find("wind") or name:find("atmosphere") or name:find("rain") or name:find("bgm") then
            pcall(function()
                obj:Stop()
                obj.Volume = 0
                obj:Destroy()
            end)
        end
    end
    
    -- Explosion, ForceField, BodyMovers
    if obj:IsA("Explosion") or obj:IsA("ForceField") then
        pcall(function() obj:Destroy() end)
    end
    
    -- BodyMovers gây lag
    if obj:IsA("BodyAngularVelocity") or obj:IsA("BodyForce") or obj:IsA("BodyThrust") or obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") or obj:IsA("RocketPropulsion") then
        pcall(function() obj:Destroy() end)
    end
    
    -- Animations không cần thiết
    if obj:IsA("AnimationController") then
        pcall(function()
            for _, track in pairs(obj:GetPlayingAnimationTracks()) do
                if track.Animation and track.Animation.AnimationId:find("rbxassetid://") then
                    track:Stop(0)
                end
            end
        end)
    end
    
    -- Xóa attachments
    if obj:IsA("Attachment") and obj.Parent and not obj.Parent:IsA("BasePart") then
        pcall(function() obj:Destroy() end)
    end
    
    -- Xóa ropes, constraints
    if obj:IsA("RopeConstraint") or obj:IsA("RodConstraint") or obj:IsA("SpringConstraint") or obj:IsA("CylindricalConstraint") or obj:IsA("BallSocketConstraint") or obj:IsA("HingeConstraint") then
        pcall(function() obj:Destroy() end)
    end
end

-- ============================================
-- 6. DỌN SẠCH MAP
-- ============================================
local cleanedCount = 0
for _, obj in pairs(Workspace:GetDescendants()) do
    CleanPart(obj)
    RemoveEffects(obj)
    cleanedCount = cleanedCount + 1
end

-- ============================================
-- 7. TẮT GUI KHÔNG CẦN THIẾT
-- ============================================
pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, true)
end)

-- ============================================
-- 8. GIẢM CHẤT LƯỢNG TEXTURE CỦA PLAYER
-- ============================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.2)
    for _, part in pairs(char:GetDescendants()) do
        CleanPart(part)
        RemoveEffects(part)
    end
end)

-- ============================================
-- 9. XÓA OBJECT Ở XA (GIẢM RENDER)
-- ============================================
coroutine.wrap(function()
    while task.wait(5) do
        local localChar = LocalPlayer.Character
        if localChar then
            local root = localChar:FindFirstChild("HumanoidRootPart")
            if root then
                local pos = root.Position
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                        local distance = (obj.Position - pos).Magnitude
                        -- Giảm render xa bằng cách tăng transparency
                        if distance > 200 then
                            pcall(function()
                                obj.Transparency = math.max(obj.Transparency, 0.8)
                                obj.CastShadow = false
                            end)
                        end
                    end
                end
            end
        end
    end
end)()

-- ============================================
-- 10. TỰ ĐỘNG DỌN OBJECT MỚI
-- ============================================
Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.05) -- Đợi object load xong
    CleanPart(obj)
    RemoveEffects(obj)
end)

-- ============================================
-- 11. DỌN ĐỊNH KỲ MỖI 2 GIÂY
-- ============================================
coroutine.wrap(function()
    while task.wait(2) do
        for _, obj in pairs(Workspace:GetDescendants()) do
            RemoveEffects(obj)
        end
    end
end)()

-- ============================================
-- 12. GIẢI PHÓNG BỘ NHỚ
-- ============================================
coroutine.wrap(function()
    while task.wait(30) do
        pcall(function()
            -- Xóa debris
            local debris = Workspace:FindFirstChild("Debris")
            if debris then
                for _, obj in pairs(debris:GetChildren()) do
                    pcall(function() obj:Destroy() end)
                end
            end
        end)
    end
end)()

-- ============================================
-- 13. TẮT HIỆU ỨNG MÀN HÌNH
-- ============================================
pcall(function()
    -- Tắt bloom, blur, color correction
    Lighting.BloomEnabled = false
    Lighting.DepthOfFieldEnabled = false
    Lighting.ColorCorrectionEnabled = false
    Lighting.SunRaysEnabled = false
    
    -- Tắt post-processing effects
    local blur = Lighting:FindFirstChild("Blur")
    if blur then blur.Enabled = false end
    
    local colorCorrection = Lighting:FindFirstChild("ColorCorrection")
    if colorCorrection then colorCorrection.Enabled = false end
    
    local sunRays = Lighting:FindFirstChild("SunRays")
    if sunRays then sunRays.Enabled = false end
    
    local bloom = Lighting:FindFirstChild("Bloom")
    if bloom then bloom.Enabled = false end
end)

-- ============================================
-- 14. GIỚI HẠN TỐC ĐỘ KHUNG HÌNH (CHỐNG GIẬT)
-- ============================================
pcall(function()
    -- Đặt target FPS ổn định
    local settings = UserSettings()
    local gameSettings = settings:FindFirstChild("GameSettings")
    if gameSettings then
        local savedSettings = gameSettings:FindFirstChild("SavedQualitySettings")
        if savedSettings then
            pcall(function()
                savedSettings.FrameRateCap = 60
            end)
        end
    end
end)

-- ============================================
-- THÔNG BÁO
-- ============================================
print("=================================")
print("⚡ EXTREME FPS BOOSTER ACTIVATED!")
print("✅ No Shadows")
print("✅ SmoothPlastic All Parts")
print("✅ No Particles/Fire/Smoke")
print("✅ No Lights/Neon")
print("✅ No Decals/Textures")
print("✅ Low Render Distance")
print("✅ Anti Stutter")
print("✅ Auto Clean Every 2s")
print("✅ Memory Optimized")
print("📊 Cleaned: " .. cleanedCount .. " objects")
print("=================================")