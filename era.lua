local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Window = WindUI:CreateWindow({
    Folder = "Ringta Scripts",   
    Title = "RINGTA SCRIPTS",
    Icon = "star",
    Author = "ringta",
    Theme = "Dark",
    Size = UDim2.fromOffset(500, 350),
    HasOutline = true,
})

Window:EditOpenButton({
    Title = "Open RINGTA SCRIPTS",
    Icon = "monitor",
    CornerRadius = UDim.new(0, 6),
    StrokeThickness = 2,
    Color = ColorSequence.new(Color3.fromRGB(30, 30, 30), Color3.fromRGB(255, 255, 255)),
    Draggable = true,
})

local Tabs = {
    Main = Window:Tab({ Title = "Main", Icon = "star" }),
    Teleport = Window:Tab({ Title = "Teleport", Icon = "rocket" }),
    Bring = Window:Tab({ Title = "Bring Items", Icon = "package" }),
    Hitbox = Window:Tab({ Title = "Hitbox", Icon = "target" }),
    Misc = Window:Tab({ Title = "Misc", Icon = "tool" }),
}

-- Place this in your WindUI setup, in the Main tab area

local spawnItemsActive = false
local spawnItemsThread
local traderPos = Vector3.new(-37.08, 6.98, -16.33)

Tabs.Main:Toggle({
    Title = "Spawn In Items",
    Default = false,
    Callback = function(state)
        spawnItemsActive = state
        if state then
            spawnItemsThread = task.spawn(function()
                local Players = game:GetService("Players")
                local Workspace = game:GetService("Workspace")
                local VirtualInputManager = game:GetService("VirtualInputManager")
                local camera = Workspace.CurrentCamera
                local player = Players.LocalPlayer

                local center = Vector3.new(0.25, 7.82, -0.65)
                local platformPosition = Vector3.new(-1.88, -40.59, 3.62)
                local maxRadius = 1500
                local radiusStep = 50
                local angleStep = 10
                local delay = 0.05
                local carrotIterations = 15

                local function ensurePlatform()
                    if not Workspace:FindFirstChild("SafePlatform") then
                        local platform = Instance.new("Part")
                        platform.Size = Vector3.new(10, 1, 10)
                        platform.Position = platformPosition - Vector3.new(0, 0.5, 0)
                        platform.Anchored = true
                        platform.Name = "SafePlatform"
                        platform.Parent = Workspace
                    end
                end

                local function lookAt(target)
                    camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
                end

                local function circleMovement(duration)
                    local char = player.Character or player.CharacterAdded:Wait()
                    local root = char:WaitForChild("HumanoidRootPart")
                    local startTime = tick()
                    while tick() - startTime < duration and spawnItemsActive do
                        for radius = 0, maxRadius, radiusStep do
                            for angleDeg = 0, 360, angleStep do
                                if not spawnItemsActive then return end
                                local angleRad = math.rad(angleDeg)
                                local x = center.X + radius * math.cos(angleRad)
                                local z = center.Z + radius * math.sin(angleRad)
                                root.CFrame = CFrame.new(x, center.Y, z)
                                task.wait(delay)
                                if tick() - startTime >= duration then return end
                            end
                        end
                    end
                end

                local function collectCarrots(times)
                    local char = player.Character or player.CharacterAdded:Wait()
                    local root = char:WaitForChild("HumanoidRootPart")
                    for i = 1, times do
                        if not spawnItemsActive then return end
                        local items = {}

                        local carrot = Workspace:FindFirstChild("Items") and Workspace.Items:FindFirstChild("Carrot")
                        local patch = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Foliage") and Workspace.Map.Foliage:FindFirstChild("Carrot Patch")
                        local berry = Workspace:FindFirstChild("Items") and Workspace.Items:FindFirstChild("Berry")

                        if carrot then table.insert(items, carrot) end
                        if patch then table.insert(items, patch) end
                        if berry then table.insert(items, berry) end

                        for _, target in ipairs(items) do
                            if not spawnItemsActive then return end
                            local part = target:IsA("Model") and target.PrimaryPart or target
                            if part then
                                local direction = (part.Position - root.Position).Unit
                                local offsetPos = part.Position - direction * 2
                                root.CFrame = CFrame.new(offsetPos + Vector3.new(0, 2, 0))
                                lookAt(part)
                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                task.wait(0.1)
                                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                break
                            end
                        end

                        task.wait(0.2)
                    end
                end

                ensurePlatform()
                circleMovement(80)
                if not spawnItemsActive then return end

                local char = player.Character or player.CharacterAdded:Wait()
                local root = char:WaitForChild("HumanoidRootPart")
                root.CFrame = CFrame.new(platformPosition)
                task.wait(60)
                while spawnItemsActive do
                    collectCarrots(carrotIterations)
                    if not spawnItemsActive then break end
                    root.CFrame = CFrame.new(platformPosition)
                    task.wait(60)
                end
            end)
        else
            -- When toggled off, teleport to trader and stop everything
            spawnItemsActive = false
            local char = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = CFrame.new(traderPos)
            end
        end
    end
})


Tabs.Main:Divider()
Tabs.Main:Section({ Title = "Auto Do Stuff" })


local ITEM_GROUPS = {
    Food = {"Carrot", "Apple", "Berry"}
}

getgenv().autoConsumeList = {}
for _, item in ipairs(ITEM_GROUPS.Food) do
    getgenv().autoConsumeList[item] = false
end

local collectToggles = {Food = {}}
for _, item in ipairs(ITEM_GROUPS.Food) do
    collectToggles.Food[item] = false
end

local Services = setmetatable({}, {
    __index = function(self, key)
        local suc, service = pcall(game.GetService, game, key)
        if suc and service then
            return service
        end
        return nil
    end
})

local lplr = Services.Players.LocalPlayer

local function consume(item)
    local args = {item}
    Services.ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestConsumeItem"):InvokeServer(unpack(args))
end

local AUTO_CONSUME_ENABLED = false

local function setAutoConsume(state)
    AUTO_CONSUME_ENABLED = state
end

local function setCollectToggles(selectedFoods)
    for food, _ in pairs(collectToggles.Food) do
        collectToggles.Food[food] = false
    end
    for _, food in ipairs(selectedFoods) do
        collectToggles.Food[food] = true
    end
end

local MAX_ITEM_DISTANCE = 20
local function findNearestFoodItem()
    local character = lplr.Character
    if not (character and character:FindFirstChild("HumanoidRootPart")) then
        return nil
    end
    local rootPart = character.HumanoidRootPart
    local closestItem, closestDistance = nil, math.huge
    for _, item in pairs(Services.Workspace:WaitForChild("Items"):GetChildren()) do
        if getgenv().autoConsumeList[item.Name] then
            local primaryPart = item:GetPrimaryPartCFrame().p
            local distance = (rootPart.Position - primaryPart).Magnitude
            if distance < closestDistance and distance <= MAX_ITEM_DISTANCE then
                closestItem = item
                closestDistance = distance
            end
        end
    end
    return closestItem
end

local function consumeInventoryFood()
    local inventory = lplr:FindFirstChild("Inventory")
    if not inventory then return end
    for foodName, _ in pairs(getgenv().autoConsumeList) do
        local item = inventory:FindFirstChild(foodName)
        if item and (item:GetAttribute("RestoreHunger") or item:GetAttribute("RestoreHealth")) and getgenv().autoConsumeList[foodName] then
            consume(item)
        end
    end
end

task.spawn(function()
    while true do
        if AUTO_CONSUME_ENABLED then
            consumeInventoryFood()
            local item = findNearestFoodItem()
            if item and (item:GetAttribute("RestoreHunger") or item:GetAttribute("RestoreHealth")) then
                consume(item)
            end
        end
        task.wait(0.3)
    end
end)

Tabs.Main:Dropdown({
    Title = "Auto Consume: Food",
    Values = ITEM_GROUPS.Food,
    Value = {},
    Multi = true,
    AllowNone = true,
    Callback = function(selected)
        getgenv().autoConsumeList = {}
        for _, food in ipairs(selected) do
            getgenv().autoConsumeList[food] = true
        end
        setCollectToggles(selected)
    end
})

Tabs.Main:Toggle({
    Title = "Auto Consume",
    Default = false,
    Callback = function(state)
        setAutoConsume(state)
    end
})







-----------------------------------------------------------------
-- TELEPORT TAB
-----------------------------------------------------------------
Tabs.Teleport:Button({
    Title="Teleport to Camp",
    Callback=function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(
                13.287363052368164, 3.999999761581421, 0.36212217807769775,
                0.6022269129753113, -2.275036159460342e-08, 0.7983249425888062,
                6.430457055728311e-09, 1, 2.364672191390582e-08,
                -0.7983249425888062, -9.1070981866892e-09, 0.6022269129753113
            )
        end
    end
})
Tabs.Teleport:Button({
    Title="Teleport to Trader",
    Callback=function()
        local pos = Vector3.new(-37.08, 3.98, -16.33)
        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        hrp.CFrame = CFrame.new(pos)
    end
})

Tabs.Teleport:Button({
    Title = "TP to Random Tree",
    Callback = function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:FindFirstChild("HumanoidRootPart", 3)
        if not hrp then return end

        local map = workspace:FindFirstChild("Map")
        if not map then return end
        -- Try to use Foliage or Landmarks for trees
        local foliage = map:FindFirstChild("Foliage") or map:FindFirstChild("Landmarks")
        if not foliage then return end

        -- Gather all "Small Tree" models
        local trees = {}
        for _, obj in ipairs(foliage:GetChildren()) do
            if obj.Name == "Small Tree" and obj:IsA("Model") then
                local trunk = obj:FindFirstChild("Trunk") or obj.PrimaryPart
                if trunk then
                    table.insert(trees, trunk)
                end
            end
        end

        -- Pick a random tree
        if #trees > 0 then
            local trunk = trees[math.random(1, #trees)]
            local treeCFrame = trunk.CFrame
            local rightVector = treeCFrame.RightVector
            local targetPosition = treeCFrame.Position + rightVector * 3
            hrp.CFrame = CFrame.new(targetPosition)
        end
    end
})



-----------------------------------------------------------------
-- BRING TAB
-----------------------------------------------------------------
local function bringItemsByName(name)
    for _, item in ipairs(workspace.Items:GetChildren()) do
        if item.Name:lower():find(name:lower()) then
            local part = item:FindFirstChildWhichIsA("BasePart") or (item:IsA("BasePart") and item)
            if part then
                part.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
end

Tabs.Bring:Button({Title="Bring Everything",Callback=function()
    for _, item in ipairs(workspace.Items:GetChildren()) do
        local part = item:FindFirstChildWhichIsA("BasePart") or item:IsA("BasePart") and item
        if part then
            part.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        end
    end
end})
Tabs.Bring:Button({Title="Auto Cook Meat", Callback=function()
    local campfirePos = Vector3.new(1.87, 4.33, -3.67)
    for _, item in pairs(workspace.Items:GetChildren()) do
        if item:IsA("Model") or item:IsA("BasePart") then
            local name = item.Name:lower()
            if name:find("meat") then
                local part = item:FindFirstChildWhichIsA("BasePart") or item
                if part then
                    part.CFrame = CFrame.new(campfirePos + Vector3.new(math.random(-2,2), 0.5, math.random(-2,2)))
                end
            end
        end
    end
end})
Tabs.Bring:Button({Title="Bring Logs", Callback=function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _, item in pairs(workspace.Items:GetChildren()) do
        if item.Name:lower():find("log") and item:IsA("Model") then
            local main = item:FindFirstChildWhichIsA("BasePart")
            if main then
                main.CFrame = root.CFrame * CFrame.new(math.random(-5,5), 0, math.random(-5,5))
            end
        end
    end
end})
Tabs.Bring:Button({Title="Bring Coal", Callback=function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _, item in pairs(workspace.Items:GetChildren()) do
        if item.Name:lower():find("coal") and item:IsA("Model") then
            local main = item:FindFirstChildWhichIsA("BasePart")
            if main then
                main.CFrame = root.CFrame * CFrame.new(math.random(-5,5), 0, math.random(-5,5))
            end
        end
    end
end})
Tabs.Bring:Button({Title="Bring Meat (Raw + Cooked)", Callback=function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    for _, item in pairs(workspace.Items:GetChildren()) do
        local name = item.Name:lower()
        if (name:find("meat") or name:find("cooked")) and item:IsA("Model") then
            local main = item:FindFirstChildWhichIsA("BasePart")
            if main then
                main.CFrame = root.CFrame * CFrame.new(math.random(-5,5), 0, math.random(-5,5))
            end
        end
    end
end})

Tabs.Bring:Button({Title="Bring Flashlight", Callback=function() bringItemsByName("Flashlight") end})
Tabs.Bring:Button({Title="Bring Nails", Callback=function() bringItemsByName("Nails") end})
Tabs.Bring:Button({Title="Bring Fan", Callback=function() bringItemsByName("Fan") end})
Tabs.Bring:Button({Title="Bring Ammo", Callback=function()
    local keywords = {"ammo"}
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, item in ipairs(workspace.Items:GetChildren()) do
        for _, word in ipairs(keywords) do
            if item.Name:lower():find(word) then
                local part = item:FindFirstChildWhichIsA("BasePart") or (item:IsA("BasePart") and item)
                if part then
                    part.CFrame = root.CFrame + Vector3.new(math.random(-5,5), 0, math.random(-5,5))
                end
            end
        end
    end
end})

Tabs.Bring:Button({Title="Bring Sheet Metal", Callback=function()
    local keyword = "sheet metal"
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, item in ipairs(workspace.Items:GetChildren()) do
        if item.Name:lower():find(keyword) then
            local part = item:FindFirstChildWhichIsA("BasePart") or (item:IsA("BasePart") and item)
            if part then
                part.CFrame = root.CFrame + Vector3.new(math.random(-5,5), 0, math.random(-5,5))
            end
        end
    end
end})
Tabs.Bring:Button({Title="Bring Fuel Canister", Callback=function()
    local keyword = "fuel canister"
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, item in ipairs(workspace.Items:GetChildren()) do
        if item.Name:lower():find(keyword) then
            local part = item:FindFirstChildWhichIsA("BasePart") or (item:IsA("BasePart") and item)
            if part then
                part.CFrame = root.CFrame + Vector3.new(math.random(-5,5), 0, math.random(-5,5))
            end
        end
    end
end})

Tabs.Bring:Button({Title="Bring Tyre", Callback=function()
    local keyword = "tyre"
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, item in ipairs(workspace.Items:GetChildren()) do
        if item.Name:lower():find(keyword) then
            local part = item:FindFirstChildWhichIsA("BasePart") or (item:IsA("BasePart") and item)
            if part then
                part.CFrame = root.CFrame + Vector3.new(math.random(-5,5), 0, math.random(-5,5))
            end
        end
    end
end})

Tabs.Bring:Button({Title="Bring Bandage", Callback=function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, item in ipairs(workspace.Items:GetChildren()) do
        if item:IsA("Model") and item.Name:lower():find("bandage") then
            local part = item:FindFirstChildWhichIsA("BasePart")
            if part then
                part.CFrame = root.CFrame + Vector3.new(0, 2, 0)
            end
        end
    end
end})

Tabs.Bring:Button({Title="Bring Lost Child", Callback=function()
    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model.Name:lower():find("lost") and model:FindFirstChild("HumanoidRootPart") then
            model:PivotTo(LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0))
        end
    end
end})

Tabs.Bring:Button({Title="Bring Revolver", Callback=function()
    for _, item in ipairs(workspace.Items:GetChildren()) do
        if item:IsA("Model") and item.Name:lower():find("revolver") then
            local part = item:FindFirstChildWhichIsA("BasePart")
            if part then
                part.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 2, 0)
            end
        end
    end
end})

-----------------------------------------------------------------
-- HITBOX TAB
-----------------------------------------------------------------
local hitboxSettings = {Wolf=false, Bunny=false, Cultist=false, Show=false, Size=10}

local function updateHitboxForModel(model)
    local root = model:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local name = model.Name:lower()
    local shouldResize =
        (hitboxSettings.Wolf and (name:find("wolf") or name:find("alpha"))) or
        (hitboxSettings.Bunny and name:find("bunny")) or
        (hitboxSettings.Cultist and (name:find("cultist") or name:find("cross")))
    if shouldResize then
        root.Size = Vector3.new(hitboxSettings.Size, hitboxSettings.Size, hitboxSettings.Size)
        root.Transparency = hitboxSettings.Show and 0.5 or 1
        root.Color = Color3.fromRGB(255, 255, 255)
        root.Material = Enum.Material.Neon
        root.CanCollide = false
    end
end

task.spawn(function()
    while true do
        for _, model in ipairs(workspace:GetDescendants()) do
            if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
                updateHitboxForModel(model)
            end
        end
        task.wait(2)
    end
end)

Tabs.Hitbox:Toggle({Title="Expand Wolf Hitbox", Default=false, Callback=function(val) hitboxSettings.Wolf=val end})
Tabs.Hitbox:Toggle({Title="Expand Bunny Hitbox", Default=false, Callback=function(val) hitboxSettings.Bunny=val end})
Tabs.Hitbox:Toggle({Title="Expand Cultist Hitbox", Default=false, Callback=function(val) hitboxSettings.Cultist=val end})
Tabs.Hitbox:Slider({Title="Hitbox Size", Value={Min=2, Max=30, Default=10}, Step=1, Callback=function(val) hitboxSettings.Size=val end})
Tabs.Hitbox:Toggle({Title="Show Hitbox (Transparency)", Default=false, Callback=function(val) hitboxSettings.Show=val end})

-----------------------------------------------------------------
-- MISC TAB
-----------------------------------------------------------------
getgenv().speedEnabled = false
getgenv().speedValue = 28
Tabs.Misc:Toggle({
    Title = "Speed Hack",
    Default = false,
    Callback = function(v)
        getgenv().speedEnabled = v
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = v and getgenv().speedValue or 16 end
    end
})
Tabs.Misc:Slider({
    Title = "Speed Value",
    Value = {Min = 16, Max = 600, Default = 28},
    Step = 1,
    Callback = function(val)
        getgenv().speedValue = val
        if getgenv().speedEnabled then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = val end
        end
    end
})

local showFPS, showPing = true, true
local fpsText, msText = Drawing.new("Text"), Drawing.new("Text")
fpsText.Size, fpsText.Position, fpsText.Color, fpsText.Center, fpsText.Outline, fpsText.Visible =
    16, Vector2.new(Camera.ViewportSize.X-100, 10), Color3.fromRGB(0,255,0), false, true, showFPS
msText.Size, msText.Position, msText.Color, msText.Center, msText.Outline, msText.Visible =
    16, Vector2.new(Camera.ViewportSize.X-100, 30), Color3.fromRGB(0,255,0), false, true, showPing
local fpsCounter, fpsLastUpdate = 0, tick()

RunService.RenderStepped:Connect(function()
    fpsCounter += 1
    if tick() - fpsLastUpdate >= 1 then
        if showFPS then
            fpsText.Text = "FPS: " .. tostring(fpsCounter)
            fpsText.Visible = true
        else
            fpsText.Visible = false
        end
        if showPing then
            local pingStat = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
            local ping = pingStat and math.floor(pingStat:GetValue()) or 0
            msText.Text = "Ping: " .. ping .. " ms"
            if ping <= 60 then
                msText.Color = Color3.fromRGB(0, 255, 0)
            elseif ping <= 120 then
                msText.Color = Color3.fromRGB(255, 165, 0)
            else
                msText.Color = Color3.fromRGB(255, 0, 0)
            end
            msText.Visible = true
        else
            msText.Visible = false
        end
        fpsCounter = 0
        fpsLastUpdate = tick()
    end
end)
Tabs.Misc:Toggle({Title="Show FPS", Default=true, Callback=function(val) showFPS=val; fpsText.Visible=val end})
Tabs.Misc:Toggle({Title="Show Ping (ms)", Default=true, Callback=function(val) showPing=val; msText.Visible=val end})

Tabs.Misc:Button({
    Title = "FPS Boost",
    Callback = function()
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            local lighting = game:GetService("Lighting")
            lighting.Brightness = 0
            lighting.FogEnd = 100
            lighting.GlobalShadows = false
            lighting.EnvironmentDiffuseScale = 0
            lighting.EnvironmentSpecularScale = 0
            lighting.ClockTime = 14
            lighting.OutdoorAmbient = Color3.new(0, 0, 0)
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 1
            end
            for _, obj in ipairs(lighting:GetDescendants()) do
                if obj:IsA("PostEffect") or obj:IsA("BloomEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                    obj.Enabled = false
                end
            end
            for _, obj in ipairs(game:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                    obj.Enabled = false
                elseif obj:IsA("Texture") or obj:IsA("Decal") then
                    obj.Transparency = 1
                end
            end
            for _, part in ipairs(workspace:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CastShadow = false
                end
            end
        end)
        print("✅ FPS Boost Applied")
    end
})
