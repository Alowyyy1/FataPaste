local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/FakeAngles/PasteWare/refs/heads/main/linoralib.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/FakeAngles/PasteWare/refs/heads/main/manage2.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/FakeAngles/PasteWare/refs/heads/main/manager.lua"))()

Library.KeybindFrame.Visible = false

-- Глобальные настройки
getgenv().WarTycoon = false
getgenv().WeaponOnHands = false
getgenv().FOVEnabled = false
getgenv().CurrentFOV = 70

-- Система FOV
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local function UpdateFOV()
    if getgenv().FOVEnabled then
        Camera.FieldOfView = getgenv().CurrentFOV
    else
        Camera.FieldOfView = 70
    end
end

RunService.RenderStepped:Connect(UpdateFOV)

-- Модификация оружия
local function modifyWeaponSettings(property, value)
    local function safeSearch(parent)
        pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ModuleScript") then
                    local success, module = pcall(require, child)
                    if success and module[property] ~= nil then
                        if type(module[property]) == "table" then
                            if property == "VRecoil" or property == "HRecoil" then
                                module[property][1] = value
                                module[property][2] = value
                            else
                                for k in pairs(module[property]) do
                                    module[property][k] = value
                                end
                            end
                        else
                            local minValues = {
                                FireRate = 60,
                                BSpeed = 100,
                                Distance = 50,
                                Ammo = 1,
                                ClipSize = 1
                            }
                            
                            local safeValue = math.max(
                                tonumber(value) or 0,
                                minValues[property] or 0
                            )
                            module[property] = safeValue
                        end
                    end
                end
                safeSearch(child)
            end
        end)
    end

    local player = game:GetService("Players").LocalPlayer
    local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack")
    local character = player.Character or player:WaitForChild("CharacterAdded"):Wait()

    if not getgenv().WeaponOnHands then
        safeSearch(backpack)
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") then
                safeSearch(tool)
            end
        end
    else
        local equipped = character:FindFirstChildOfClass("Tool")
        if equipped then safeSearch(equipped) end
    end

    if getgenv().WarTycoon then
        local configs = game:GetService("ReplicatedStorage"):WaitForChild("Configurations")
        local weaponsFolder = configs:WaitForChild("ACS_Guns")

        local function processWeapon(tool)
            local weaponName = tool.Name
            local weaponConfig = weaponsFolder:FindFirstChild(weaponName)
            if weaponConfig then safeSearch(weaponConfig) end
        end

        if getgenv().WeaponOnHands then
            local equipped = character:FindFirstChildOfClass("Tool")
            if equipped then processWeapon(equipped) end
        else
            for _, tool in ipairs(backpack:GetChildren()) do
                processWeapon(tool)
            end
        end
    end
end

-- Интерфейс
local Window = Library:CreateWindow({
    Title = 'FataPasta  |  github.com/Alowyyy1',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Вкладка Aim
local AimTab = Window:AddTab("Aim")
local AimGroup = AimTab:AddLeftGroupbox("Aim Settings")

-- Добавляем кнопку для загрузки и выполнения скрипта SilentAim
AimGroup:AddButton("Inject SilentAim", function()
    local success, result = pcall(function()
        local script = game:HttpGet("https://raw.githubusercontent.com/Alowyyy1/margancovka/refs/heads/main/silent.lua")
        loadstring(script)()
    end)
    
    if not success then
        warn("Ошибка при загрузке SilentAim: " .. tostring(result))
    else
        print("SilentAim успешно загружен и выполнен!")
    end
end)

-- Вкладка Main
local MainTab = Window:AddTab("Main")

-- Левая колонка: Camera Settings
local CameraGroup = MainTab:AddLeftGroupbox("Camera Settings")
CameraGroup:AddToggle("FOVToggle", {
    Text = "Change FOV",
    Default = false,
    Callback = function(state)
        getgenv().FOVEnabled = state
        UpdateFOV()
    end
})

CameraGroup:AddSlider("FOVSlider", {
    Text = "FOV Value",
    Default = 70,
    Min = 30,
    Max = 120,
    Rounding = 0,
    Callback = function(value)
        getgenv().CurrentFOV = value
        if getgenv().FOVEnabled then
            UpdateFOV()
        end
    end
})

-- Правая колонка: Advanced Combat System
local ACSGroup = MainTab:AddRightGroupbox("[ACS] Advanced Combat System")

ACSGroup:AddToggle("WarTycoonToggle", {
    Text = "War Tycoon Mode",
    Default = false,
    Callback = function(state)
        getgenv().WarTycoon = state
    end
})

ACSGroup:AddToggle("WeaponHandsToggle", {
    Text = "Weapon In Hands",
    Default = false,
    Callback = function(state)
        getgenv().WeaponOnHands = state
    end
})

ACSGroup:AddButton('INF AMMO', function()
    modifyWeaponSettings("Ammo", 9999)
    modifyWeaponSettings("ClipSize", 999)
end)

ACSGroup:AddButton('NO RECOIL | NO SPREAD', function()
    modifyWeaponSettings("VRecoil", 0.01)
    modifyWeaponSettings("HRecoil", 0.01)
    modifyWeaponSettings("MinSpread", 0.01)
    modifyWeaponSettings("MaxSpread", 0.01)
end)

ACSGroup:AddButton('INF BULLET DISTANCE', function()
    modifyWeaponSettings("Distance", 9999)
end)

local fireRateInput = ACSGroup:AddInput("FireRateInput", {
    Text = "Fire Rate",
    Default = "888",
    Numeric = true
})

ACSGroup:AddButton('CHANGE FIRE RATE', function()
    modifyWeaponSettings("FireRate", math.max(tonumber(fireRateInput.Value) or 60, 60))
end)

local bulletCountInput = ACSGroup:AddInput("BulletCountInput", {
    Text = "Bullet Count",
    Default = "50",
    Numeric = true
})

ACSGroup:AddButton('MULTI BULLETS', function()
    modifyWeaponSettings("Bullets", tonumber(bulletCountInput.Value) or 50)
end)

-- Вкладка Settings
local settingsTab = Window:AddTab("Settings")
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:ApplyToTab(settingsTab)
SaveManager:BuildConfigSection(settingsTab)
ThemeManager:LoadDefaultTheme()