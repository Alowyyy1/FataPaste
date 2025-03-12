local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Alowyyy1/FataPaste/refs/heads/libra/linoralib.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Alowyyy1/FataPaste/refs/heads/libra/manage2.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Alowyyy1/FataPaste/refs/heads/libra/manager.lua"))()

local Yield = loadstring(game:HttpGet("https://raw.githubusercontent.com/edgeiy/infiniteyield/master/source"))
local Dex = loadstring(game:HttpGet("https://raw.githubusercontent.com/dyyll/Dex-V5-leak/refs/heads/main/Dex%20V5.lua"))

Library.KeybindFrame.Visible = true

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

-- Управление ESP
local localPlayer = game:GetService("Players").LocalPlayer
local chamsEnabled = false
local chamsObjects = {}
local connections = {
    playerAdded = nil,
    playerRemoving = nil,
    characterAdded = {}
}

local function manageChams(player, action)
    if player == localPlayer then return end
    
    if action == "add" then
        if chamsObjects[player] then
            manageChams(player, "remove")
        end
        
        local function processCharacter(character)
            chamsObjects[player] = {}
            
            for _, part in ipairs(character:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    local adornment = Instance.new("BoxHandleAdornment")
                    adornment.Name = "ChamsAdornment"
                    adornment.Size = part.Size + Vector3.new(0.05, 0.05, 0.05)
                    adornment.AlwaysOnTop = true
                    adornment.ZIndex = 10
                    adornment.Adornee = part
                    adornment.Color3 = player.Team and player.Team.TeamColor.Color or Color3.new(1, 0.2, 0.2)
                    adornment.Transparency = 0.35
                    adornment.Parent = part
                    
                    table.insert(chamsObjects[player], adornment)
                end
            end
            
            connections.characterAdded[player] = character.ChildAdded:Connect(function(child)
                if child:IsA("BasePart") then
                    manageChams(player, "add")
                end
            end)
        end
        
        if player.Character then
            processCharacter(player.Character)
        end
        
        connections.characterAdded[player] = player.CharacterAdded:Connect(processCharacter)
        
    elseif action == "remove" then
        if chamsObjects[player] then
            for _, adornment in ipairs(chamsObjects[player]) do
                pcall(function() adornment:Destroy() end)
            end
            chamsObjects[player] = nil
        end
        
        if connections.characterAdded[player] then
            connections.characterAdded[player]:Disconnect()
            connections.characterAdded[player] = nil
        end
    end
end

local function toggleChams(state)
    chamsEnabled = state
    
    if state then
        connections.playerAdded = game.Players.PlayerAdded:Connect(function(player)
            manageChams(player, "add")
        end)
        
        connections.playerRemoving = game.Players.PlayerRemoving:Connect(function(player)
            manageChams(player, "remove")
        end)
        
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= localPlayer then
                manageChams(player, "add")
            end
        end
    else
        for player, _ in pairs(chamsObjects) do
            manageChams(player, "remove")
        end

        if connections.playerAdded then
            connections.playerAdded:Disconnect()
            connections.playerAdded = nil
        end
        
        if connections.playerRemoving then
            connections.playerRemoving:Disconnect()
            connections.playerRemoving = nil
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

-- Main
local WallhackTab = Window:AddTab("Main(Soon More)")
local WallhackGroup = WallhackTab:AddLeftGroupbox("Player ESP")

WallhackGroup:AddToggle("ChamsToggle", {
    Text = "Enable Player ESP",
    Default = false,
    Callback = function(state)
        toggleChams(state)
    end
}):AddKeyPicker("ChamsToggle_KeyPicker", {
    Default = "RightAlt",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Wall Hack Key",
    NoUI = false
})

Options.ChamsToggle_KeyPicker:OnClick(function()
    Options.ChamsToggle:SetValue(not Options.ChamsToggle.Value)
end)

-- Вкладка Other
local MainTab = Window:AddTab("Other")

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

-- Леваяя колонка: Scripts
local ScriptsGroup = MainTab:AddLeftGroupbox("Scripts")
ScriptsGroup:AddButton('Infinite Yield', function()
    Yield()
end)

ScriptsGroup:AddButton('Dex', function()
    Dex()
end)

-- Правая колонка: Advanced Combat System
local ACSGroup = MainTab:AddRightGroupbox("[ACS] Advanced Combat System")

ACSGroup:AddToggle("WarTycoonToggle", {
    Text = "War Tycoon",
    Default = false,
    Callback = function(state)
        getgenv().WarTycoon = state
    end
})

ACSGroup:AddToggle("WeaponHandsToggle", {
    Text = "Apply Only For Weapon In Hands",
    Default = false,
    Callback = function(state)
        getgenv().WeaponOnHands = state
    end
})

ACSGroup:AddButton('Infinite Ammo (9999)', function()
    modifyWeaponSettings("Ammo", 9999)
    modifyWeaponSettings("ClipSize", 999)
end)

ACSGroup:AddButton('Turn Off Recoil and Spread', function()
    modifyWeaponSettings("VRecoil", 0.01)
    modifyWeaponSettings("HRecoil", 0.01)
    modifyWeaponSettings("MinSpread", 0.01)
    modifyWeaponSettings("MaxSpread", 0.01)
end)

ACSGroup:AddButton('Set Infinite Bullet Distance', function()
    modifyWeaponSettings("Distance", 9999)
end)

local fireRateInput = ACSGroup:AddInput("FireRateInput", {
    Text = "FireRate(It may not work properly)",
    Default = "60",
    Numeric = true
})

ACSGroup:AddButton('Set Fire Rate', function()
    modifyWeaponSettings("FireRate", math.max(tonumber(fireRateInput.Value) or 60, 60))
end)

local bulletCountInput = ACSGroup:AddInput("BulletCountInput", {
    Text = "BulletCount(It may not work properly)",
    Default = "1",
    Numeric = true
})

ACSGroup:AddButton('Set Bullet Count', function()
    modifyWeaponSettings("Bullets", tonumber(bulletCountInput.Value) or 50)
end)

-- Леваяя колонка: Player Protection
local ProtectionGroup = MainTab:AddLeftGroupbox("Player Protection")

-- Поле ввода для кастомного имени
local nameInput = ProtectionGroup:AddInput("NameInput", {
    Text = "Enter the name you want to set",
    Default = "@Protected",
    Numeric = false, -- Разрешаем текст
})

-- Кнопка изменения имени
ProtectionGroup:AddButton('Change Name', function()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    
    if character and character:FindFirstChild("Head") then
        local head = character.Head
        local nameTag = head:FindFirstChild("NameTag")
        
        if nameTag then
            local newName = nameInput.Value -- Берём текст из поля ввода
            if nameTag:FindFirstChild("DisplayName") then
                nameTag.DisplayName.Text = newName
            end
            if nameTag:FindFirstChild("Username") then
                nameTag.Username.Text = newName
            end
        end
    end
end)

-- Вкладка Settings
local settingsTab = Window:AddTab("Settings")

-- Группа для настроек интерфейса
local InterfaceGroup = settingsTab:AddLeftGroupbox("Interface Settings")

-- Переключатель для отображения KeyBinds
InterfaceGroup:AddToggle("KeybindToggle", {
    Text = "Show KeyBinds Menu",
    Default = true, -- По умолчанию включено
    Callback = function(state)
        Library.KeybindFrame.Visible = state
    end
})

-- Инициализация видимости KeyBinds
if Options and Options.KeybindToggle then
    Library.KeybindFrame.Visible = Options.KeybindToggle.Value
else
    warn("Options or Options.KeybindToggle is nil")
end

-- Применение тем и сохранение настроек
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:ApplyToTab(settingsTab)
SaveManager:BuildConfigSection(settingsTab)
ThemeManager:LoadDefaultTheme()
