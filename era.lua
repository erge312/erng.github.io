local StarterGui = game:GetService("StarterGui")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local TweenService = game:GetService("TweenService")
local x = 57
local y = 3
local startZ = 30000
local endZ = -49032.99
local stepZ = -2000
local duration = 0.5
local rocketFound = false
local teleportCount = 10
local delayTime = 0.1
local rocketPosition = nil
local printedTeleportMessage = false
local printedChairMessage = false



for z = startZ, endZ, stepZ do
    if rocketFound then break end
    local adjustedY = math.max(y, 3)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local goal = {CFrame = CFrame.new(Vector3.new(x, adjustedY, z))}
    local tween = TweenService:Create(humanoidRootPart, tweenInfo, goal)
    tween:Play()
    tween.Completed:Wait()
    local rocket = workspace.RuntimeItems:FindFirstChild("BottleRocketLauncher")
    if rocket then
        local position = nil
        if rocket:IsA("BasePart") then
            position = rocket.Position
        elseif rocket:IsA("Model") then
            if rocket.PrimaryPart then
                position = rocket.PrimaryPart.Position
            else
                local part = rocket:FindFirstChildWhichIsA("BasePart")
                if part then
                    position = part.Position
                end
            end
        end
        if position then
            rocketPosition = position
            local distance = (humanoidRootPart.Position - rocketPosition).Magnitude
            print("BottleRocketLauncher found at:", distance)
            rocketFound = true
        end
    end
end

if rocketFound and rocketPosition then
    for i = 1, teleportCount do
        humanoidRootPart.CFrame = CFrame.new(rocketPosition)
        if not printedTeleportMessage then
            print("TP to BottleRocketLauncher.")
            printedTeleportMessage = true
        end
        local closestChair = nil
        local closestDistance = math.huge
        for _, item in pairs(workspace.RuntimeItems:GetDescendants()) do
            if item.Name == "Chair" then
                local seat = item:FindFirstChild("Seat")
                if seat then
                    local distance = (humanoidRootPart.Position - seat.Position).Magnitude
                    if distance < closestDistance then
                        closestChair = seat
                        closestDistance = distance
                    end
                end
            end
        end
        if closestChair and not printedChairMessage then
            character:PivotTo(closestChair.CFrame)
            closestChair:Sit(humanoid)
            print("Seated on Chair.")
            printedChairMessage = true
        elseif not closestChair and not printedChairMessage then
            print("No Chair nearby.")
            printedChairMessage = true
        end
        task.wait(delayTime)
    end
else
    warn("BottleRocketLauncher not found.")
end
