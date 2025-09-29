-- // Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ================= AIMBOT VARIABLES =================
local AimbotEnabled = {
    LowArcOn = false,
    HighArcOn = false,
    MixedArcOn = false,
}
local CamlockEnabled = {
    LowArcOn = false,
    HighArcOn = false,
    AutoShootOn = false,
}
local ShotDelay = 0.32
local ArcOffset = 0
local YAxis = 0
local AimOffsetEnabled = false
local AimOffsetX = 0

-- ================= RANGE INDICATOR VARIABLES =================
local RangeIndicatorEnabled = false
local characterHighlight
local cachedGoal, cachedGoalDistance, lastGoalUpdate = nil, nil, 0

-- ================= ANTI-FALL VARIABLES =================
local AntiFallEnabled = false
local antiFallConnection
local currentAntiFallBoxes = {}

-- ================= ANTI-TRAVEL VARIABLES =================
local AntiTravelEnabled = false
local cachedJumpCons = {}

-- ================= ANTI-OOB VARIABLES =================
local AntiOOBEnabled = false
local deletedOOBs = {}
local fakeFloor

-- ================= UTILITY FUNCTIONS =================
local function IsHoldingBasketball()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("Basketball") and char.Basketball:FindFirstChild("Ball")
end

local function GetGoal()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil, nil end
    local closest, bestDist = nil, math.huge
    local charPos = char.HumanoidRootPart.Position
    local myTeam = LocalPlayer.Team

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name == "Goal" and obj:FindFirstChild("Swish") then
            local hoopTeam = obj:FindFirstChild("Team") and obj.Team.Value or nil
            if hoopTeam == nil or hoopTeam ~= myTeam then
                local dist = (obj.Position - charPos).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    closest = obj
                end
            end
        end
    end
    return closest, bestDist
end

local function LowArc(distance)
    if distance >= 58 and distance < 59 then return 23 end
    if distance >= 59 and distance < 60 then return 27 end
    if distance >= 60 and distance < 61 then return 35 end
    if distance >= 61 and distance < 62 then return 37 end
    if distance >= 62 and distance < 63 then return 22 end
    if distance >= 63 and distance < 64 then return 26 end
    if distance >= 64 and distance < 65 then return 28 end
    if distance >= 65 and distance < 66 then return 32 end
    if distance >= 66 and distance < 67 then return 35 end
    if distance >= 67 and distance < 67.6 then return 24 end
    if distance >= 67.6 and distance < 68 then return 25 end
    if distance >= 68 and distance < 68.6 then return 26 end
    if distance >= 68.6 and distance < 69 then return 27 end
    if distance >= 69 and distance < 70 then return 30 end
    if distance >= 70 and distance < 70.6 then return 31 end
    if distance >= 70.6 and distance < 71 then return 32 end
    if distance >= 71 and distance < 72 then return 35 end
    if distance >= 72 and distance < 72.6 then return 38 end
    if distance >= 72.6 and distance <= 73 then return 39 end
    if distance < 58 then return 20 end
    if distance > 73 then return 45 end
end

local function HighArc(distance)
    if distance >= 57 and distance < 60 then return 75
    elseif distance >= 60 and distance < 62 then return 70
    elseif distance >= 62 and distance < 64 then return 65
    elseif distance >= 64 and distance < 66 then return 59
    elseif distance >= 66 and distance < 68 then return 47
    elseif distance >= 68 and distance < 70 then return 70
    elseif distance >= 70 and distance < 72 then return 65
    elseif distance >= 72 and distance < 73 then return 61
    else return 0 end
end

local function Velocify(target, distance)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return target end
    local velocity = char.HumanoidRootPart.Velocity
    local travel = distance / 50
    local calc = velocity * travel * 0.06
    return target + Vector3.new(calc.X, 0, calc.Z)
end

local function ShootLow()
    local goal, distance = GetGoal()
    if not goal then return end
    -- Set power based on distance
    if distance >= 57 and distance < 62 then
        LocalPlayer:SetAttribute('Power', 75)
    elseif distance >= 62 and distance < 67 then
        LocalPlayer:SetAttribute('Power', 80)
    elseif distance >= 67 and distance < 74 then
        LocalPlayer:SetAttribute('Power', 85)
    end
    local char = LocalPlayer.Character
    local cameraPos = char.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0) - (Camera.CFrame.LookVector * 10)
    Camera.CFrame = CFrame.new(
        cameraPos,
        Velocify(goal.Position, distance) + Vector3.new(0, LowArc(distance) + ArcOffset, 0)
    )
    local cx = Camera.ViewportSize.X / 2
    if AimOffsetEnabled then
        cx = cx + (AimOffsetX or 0)
    end
    local cy = Camera.ViewportSize.Y / 2 + YAxis
    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
end

local function ShootHigh()
    local goal, distance = GetGoal()
    if not goal then return end
    -- Set power based on distance
    if distance >= 57 and distance < 68 then
        LocalPlayer:SetAttribute('Power', 80)
    elseif distance >= 68 and distance < 74 then
        LocalPlayer:SetAttribute('Power', 85)
    end
    local char = LocalPlayer.Character
    local cameraPos = char.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0) - (Camera.CFrame.LookVector * 10)
    Camera.CFrame = CFrame.new(
        cameraPos,
        Velocify(goal.Position, distance) + Vector3.new(0, HighArc(distance) + ArcOffset, 0)
    )
    local cx = Camera.ViewportSize.X / 2
    if AimOffsetEnabled then
        cx = cx + (AimOffsetX or 0)
    end
    local cy = Camera.ViewportSize.Y / 2 + YAxis
    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
end

local function SetupAimbot(char)
    local humanoid = char:WaitForChild("Humanoid")
    local jumpConn
    local isProcessing = false
    local lastJumpTime = 0
    local JUMP_COOLDOWN = 0.1

    jumpConn = humanoid.Jumping:Connect(function()
        local currentTime = tick()
        if isProcessing or (currentTime - lastJumpTime) < JUMP_COOLDOWN then
            return
        end

        if not (AimbotEnabled.LowArcOn or AimbotEnabled.HighArcOn or AimbotEnabled.MixedArcOn) then
            return
        end

        if not IsHoldingBasketball() then
            return
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp or hrp.Velocity.Y > 2 then
            return
        end

        isProcessing = true
        lastJumpTime = currentTime

        local oldCFrame = Camera.CFrame
        local oldFOV = Camera.FieldOfView
        local oldSubject = Camera.CameraSubject
        local oldCameraType = Camera.CameraType

        task.spawn(function()
            if ShotDelay > 0 then
                task.wait(ShotDelay)
            end

            local goal, distance = GetGoal()
            if not goal then
                isProcessing = false
                return
            end

            local shotFired = false

            if AimbotEnabled.MixedArcOn then
                local canLow = (distance >= 58 and distance <= 74)
                local canHigh = (distance >= 57 and distance <= 74)

                if canLow and canHigh then
                    if math.random() > 0.5 then
                        ShootLow()
                    else
                        ShootHigh()
                    end
                    shotFired = true
                elseif canLow then
                    ShootLow()
                    shotFired = true
                elseif canHigh then
                    ShootHigh()
                    shotFired = true
                end
            elseif AimbotEnabled.LowArcOn and (distance >= 58 and distance <= 74) then
                ShootLow()
                shotFired = true
            elseif AimbotEnabled.HighArcOn and (distance >= 57 and distance <= 74) then
                ShootHigh()
                shotFired = true
            end

            if shotFired then
                task.wait()
                Camera.CFrame = oldCFrame
                Camera.FieldOfView = oldFOV
                Camera.CameraSubject = oldSubject
                Camera.CameraType = oldCameraType
            end

            isProcessing = false
        end)
    end)

    LocalPlayer.CharacterAdded:Connect(function(newChar)
        if jumpConn then jumpConn:Disconnect() end
        SetupAimbot(newChar)
    end)
end

-- ================= CAMLOCK =================
local camlockConn
local lastCameraCFrame = nil

local function AdjustCamlock()
    if not (CamlockEnabled.LowArcOn or CamlockEnabled.HighArcOn) or not IsHoldingBasketball() then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local goal, distance = GetGoal()
    if not goal or not (distance >= 57 and distance <= 74) then return end

    -- Set power based on distance
    if CamlockEnabled.LowArcOn then
        if distance >= 57 and distance < 62 then
            LocalPlayer:SetAttribute('Power', 75)
        elseif distance >= 62 and distance < 67 then
            LocalPlayer:SetAttribute('Power', 80)
        elseif distance >= 67 and distance < 74 then
            LocalPlayer:SetAttribute('Power', 85)
        end
    elseif CamlockEnabled.HighArcOn then
        if distance >= 57 and distance < 68 then
            LocalPlayer:SetAttribute('Power', 80)
        elseif distance >= 68 and distance < 74 then
            LocalPlayer:SetAttribute('Power', 85)
        end
    end

    -- Instantly lock camera to aim at hoop center, follow character position
    local arc = CamlockEnabled.LowArcOn and LowArc(distance) or HighArc(distance)
    arc = arc + ArcOffset
    local targetPos = Velocify(goal.Position, distance) + Vector3.new(0, arc, 0)
    local basePos = char.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0)
    local lookDirection = (targetPos - basePos).Unit
    local currentPos = basePos - (lookDirection * 10) -- Offset 10 studs behind character
    local newCFrame = CFrame.new(currentPos, targetPos)

    -- Only update if CFrame has changed significantly to prevent flickering
    if not lastCameraCFrame or (newCFrame.Position - lastCameraCFrame.Position).Magnitude > 0.1 or
       (newCFrame.LookVector - lastCameraCFrame.LookVector).Magnitude > 0.01 then
        Camera.CameraType = Enum.CameraType.Scriptable
        Camera.CFrame = newCFrame
        lastCameraCFrame = newCFrame
    end
end

local function StartCamlock()
    if camlockConn then camlockConn:Disconnect() end
    lastCameraCFrame = nil
    camlockConn = RunService.PreRender:Connect(AdjustCamlock)
end

local function StopCamlock()
    if camlockConn then
        camlockConn:Disconnect()
        camlockConn = nil
    end
    lastCameraCFrame = nil
    if Camera.CameraType ~= Enum.CameraType.Custom then
        Camera.CameraType = Enum.CameraType.Custom
    end
end

local function SetupCamlock(char)
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.Jumping:Connect(function()
        if not (CamlockEnabled.LowArcOn or CamlockEnabled.HighArcOn) or not IsHoldingBasketball() then return end
        StartCamlock()
        if CamlockEnabled.AutoShootOn then
            task.spawn(function()
                task.wait(ShotDelay)
                local goal, distance = GetGoal()
                if not goal or not (distance >= 57 and distance <= 74) then return end
                local cx = Camera.ViewportSize.X / 2
                if AimOffsetEnabled then
                    cx = cx + (AimOffsetX or 0)
                end
                local cy = Camera.ViewportSize.Y / 2 + YAxis
                VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
                StopCamlock()
            end)
        end
    end)
    humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Landed or not IsHoldingBasketball() then
            StopCamlock()
        end
    end)
    -- Detect manual shooting to stop Camlock
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not (CamlockEnabled.LowArcOn or CamlockEnabled.HighArcOn) or not IsHoldingBasketball() then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            StopCamlock()
        end
    end)
end

if LocalPlayer.Character then
    SetupCamlock(LocalPlayer.Character)
    SetupAimbot(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(char)
    SetupCamlock(char)
    SetupAimbot(char)
end)

-- ================= RANGE INDICATOR =================
local rangeIndicatorConn

local function CreateRangeIndicator()
    if not characterHighlight then
        characterHighlight = Instance.new("Highlight")
        characterHighlight.Name = "RangeHighlight"
        characterHighlight.FillColor = Color3.fromRGB(0, 255, 0)
        characterHighlight.OutlineColor = Color3.fromRGB(0, 255, 0)
        characterHighlight.FillTransparency = 0.5
        characterHighlight.OutlineTransparency = 0
        characterHighlight.Enabled = false
        characterHighlight.Parent = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    end
end

local function UpdateRangeIndicator()
    if not RangeIndicatorEnabled or not IsHoldingBasketball() then
        if characterHighlight then characterHighlight.Enabled = false end
        return
    end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        if characterHighlight then characterHighlight.Enabled = false end
        return
    end

    if tick() - lastGoalUpdate >= 1 then
        cachedGoal, cachedGoalDistance = GetGoal()
        lastGoalUpdate = tick()
    end

    characterHighlight.Enabled = cachedGoalDistance and (cachedGoalDistance >= 57 and cachedGoalDistance <= 74)
end

local function StartRangeIndicator()
    CreateRangeIndicator()
    if rangeIndicatorConn then rangeIndicatorConn:Disconnect() end
    rangeIndicatorConn = RunService.Heartbeat:Connect(function()
        task.spawn(function()
            UpdateRangeIndicator()
            task.wait(1) -- Increased interval to reduce lag
        end)
    end)
end

local function StopRangeIndicator()
    if rangeIndicatorConn then
        rangeIndicatorConn:Disconnect()
        rangeIndicatorConn = nil
    end
    if characterHighlight then
        characterHighlight.Enabled = false
        characterHighlight:Destroy()
        characterHighlight = nil
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if characterHighlight then
        characterHighlight.Parent = char
    end
    if RangeIndicatorEnabled then
        StartRangeIndicator()
    end
end)

-- ================= ANTI-FALL =================
local function StartAntiFall()
    if antiFallConnection then antiFallConnection:Disconnect() end
    antiFallConnection = RunService.Heartbeat:Connect(function()
        if not AntiFallEnabled then return end
        local myChar = LocalPlayer.Character
        if not myChar then return end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local allPlayers = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = plr.Character.HumanoidRootPart
                table.insert(allPlayers, {player = plr, distance = (myHRP.Position - hrp.Position).Magnitude})
            end
        end

        table.sort(allPlayers, function(a,b) return a.distance < b.distance end)
        local closestPlayers = {}
        for i = 1, math.min(3,#allPlayers) do table.insert(closestPlayers, allPlayers[i].player) end

        for plr,_ in pairs(currentAntiFallBoxes) do
            local stillClosest = false
            for _, cp in ipairs(closestPlayers) do
                if plr == cp then stillClosest = true break end
            end
            if not stillClosest then
                currentAntiFallBoxes[plr]:Destroy()
                currentAntiFallBoxes[plr] = nil
            end
        end

        for _, cp in ipairs(closestPlayers) do
            if not currentAntiFallBoxes[cp] then
                local head = cp.Character:FindFirstChild("Head")
                if head then
                    local box = Instance.new("Part")
                    box.Name = "AntiFallBox"
                    box.Size = Vector3.new(3,3,3)
                    box.Transparency = 1
                    box.Anchored = true
                    box.CanCollide = true
                    box.Material = Enum.Material.SmoothPlastic
                    box.CFrame = head.CFrame
                    box.Parent = Workspace
                    currentAntiFallBoxes[cp] = box
                end
            end
        end

        for plr, box in pairs(currentAntiFallBoxes) do
            if plr.Character and plr.Character:FindFirstChild("Head") then
                box.CFrame = plr.Character.Head.CFrame
            end
        end
    end)
end

local function StopAntiFall()
    if antiFallConnection then antiFallConnection:Disconnect() antiFallConnection = nil end
    for _, box in pairs(currentAntiFallBoxes) do
        box:Destroy()
    end
    currentAntiFallBoxes = {}
end

local function SetAntiFall(on)
    AntiFallEnabled = on
    if on then StartAntiFall() else StopAntiFall() end
end

-- ================= ANTI-TRAVEL =================
local function CacheExistingJumpCons(hum)
    local list = {}
    pcall(function()
        for _, c in ipairs(getconnections(hum.Jumping)) do
            table.insert(list, c)
        end
    end)
    cachedJumpCons[hum] = list
end

local function DisableCachedJumpCons(hum)
    local list = cachedJumpCons[hum]
    if not list then return end
    for _, c in ipairs(list) do
        pcall(function() c:Disable() end)
    end
end

local function EnableCachedJumpCons(hum)
    local list = cachedJumpCons[hum]
    if not list then return end
    for _, c in ipairs(list) do
        pcall(function() c:Enable() end)
    end
    cachedJumpCons[hum] = nil
end

local function SetAntiTravel(on)
    AntiTravelEnabled = on
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if on then
        CacheExistingJumpCons(hum)
        DisableCachedJumpCons(hum)
    else
        EnableCachedJumpCons(hum)
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and AntiTravelEnabled then
        CacheExistingJumpCons(hum)
        DisableCachedJumpCons(hum)
    end
end)

-- ================= ANTI-OOB =================
local function DeleteOOB()
    deletedOOBs = {}
    local courts = Workspace:FindFirstChild("Courts")
    if courts then
        for _, court in pairs(courts:GetChildren()) do
            local oob = court:FindFirstChild("OOB")
            if oob then
                deletedOOBs[court] = oob:Clone()
                oob:Destroy()
            end
        end
    end
end

local function RestoreOOB()
    for court, oobClone in pairs(deletedOOBs) do
        if court and court.Parent and oobClone then
            oobClone.Parent = court
        end
    end
    deletedOOBs = {}
end

local function CreateFakeFloor()
    if fakeFloor then return fakeFloor end

    fakeFloor = Instance.new("Part")
    fakeFloor.Size = Vector3.new(2000, 5, 1000)
    fakeFloor.Anchored = true
    fakeFloor.CanCollide = true
    fakeFloor.Transparency = 1
    fakeFloor.Position = Vector3.new(0, 49, 0)
    fakeFloor.Name = "AntiOOBFloor"
    fakeFloor.Parent = Workspace
    return fakeFloor
end

local function SetAntiOOB(on)
    AntiOOBEnabled = on
    if on then
        DeleteOOB()
        CreateFakeFloor().CanCollide = true
    else
        RestoreOOB()
        if fakeFloor then
            fakeFloor.CanCollide = false
        end
    end
end

RunService.RenderStepped:Connect(function()
    if AntiOOBEnabled then
        local courts = Workspace:FindFirstChild("Courts")
        if courts then
            for _, court in pairs(courts:GetChildren()) do
                local oob = court:FindFirstChild("OOB")
                if oob then
                    oob:Destroy()
                end
            end
        end
        if fakeFloor then
            fakeFloor.CanCollide = true
        else
            CreateFakeFloor()
        end
    end
end)

-- ================= SPEED MULTIPLIER =================
local SpeedMultiplier = 1

local function ApplySpeed()
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 * SpeedMultiplier
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid").WalkSpeed = 16 * SpeedMultiplier
    if AntiTravelEnabled then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            CacheExistingJumpCons(hum)
            DisableCachedJumpCons(hum)
        end
    end
end)

-- ================= SPAWN FUNCTIONS =================
local function SpawnBall()
    local args = { "Spawn Ball" }
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("sbEvent"):FireServer(unpack(args))
    end)
end

local function SpawnVehicle()
    local args = { "Toggle" }
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("vehicleEvent"):FireServer(unpack(args))
    end)
end

local function ClaimLukesReward()
    local args = { "1111528852" }
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClaimRewardEvent"):FireServer(unpack(args))
    end)
end

local function ClickToTravel()
    local args = { "Travel" }
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("sbEvent"):FireServer(unpack(args))
    end)
end

-- ================= HUB UI =================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()

-- Create the main window
local Window = Library:CreateWindow({
    Title = "Hoopz | 2xr's hub",
    Footer = "v1.0.0",
    ToggleKeybind = Enum.KeyCode.RightControl,
    Center = true,
    AutoShow = true
})

-- Tabs
local HomeTab = Window:AddTab("Home", "house")
local UISettingsTab = Window:AddTab({
    Name = "UI Settings",
    Description = "Customize the UI",
    Icon = "settings"
})

-- Groupboxes
local AimbotGroup = HomeTab:AddLeftGroupbox("Aimbot", "crosshair")
local CamlockGroup = HomeTab:AddLeftGroupbox("Camlock", "arrow-big-up-dash")
local ExtraGroup = HomeTab:AddRightGroupbox("Extra", "dollar-sign")
local MiscGroup = HomeTab:AddRightGroupbox("Misc", "star")

-- ================= AIMBOT SETTINGS =================
AimbotGroup:AddToggle("HighArcAimbot", {
    Text = "High Arc Aimbot",
    Tooltip = "Aimbot with High Arc Trajectory",
    Default = false,
    Callback = function(Value)
        AimbotEnabled.HighArcOn = Value
    end
}):AddKeyPicker("HighArcAimbotKey", {
    Text = "High Arc Aimbot Key",
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle"
})

AimbotGroup:AddToggle("LowArcAimbot", {
    Text = "Low Arc Aimbot",
    Tooltip = "Aimbot with Low Arc Trajectory",
    Default = false,
    Callback = function(Value)
        AimbotEnabled.LowArcOn = Value
    end
}):AddKeyPicker("LowArcAimbotKey", {
    Text = "Low Arc Aimbot Key",
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle"
})

AimbotGroup:AddToggle("MixedArcAimbot", {
    Text = "Mixed Arc Aimbot",
    Tooltip = "Randomly shoots with Low or High arc",
    Default = false,
    Callback = function(Value)
        AimbotEnabled.MixedArcOn = Value
    end
}):AddKeyPicker("MixedArcAimbotKey", {
    Text = "Mixed Arc Aimbot Key",
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle"
})

AimbotGroup:AddToggle("AimOffset", {
    Text = "Enable Aim Offset",
    Tooltip = "Adjust shot horizontally on mobile",
    Default = false,
    Callback = function(Value)
        AimOffsetEnabled = Value
    end
}):AddKeyPicker("AimOffsetKey", {
    Text = "Aim Offset Key",
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle"
})

AimbotGroup:AddSlider("XOffset", {
    Text = "X Offset",
    Default = 0,
    Min = 40,
    Max = 70,
    Rounding = 0,
    Callback = function(Value)
        AimOffsetX = Value
    end
})

-- ================= CAMLOCK SETTINGS =================
CamlockGroup:AddToggle("HighArcCamlock", {
    Text = "High Arc Camlock",
    Tooltip = "Enables High Arc Camlock",
    Default = false,
    Callback = function(Value)
        CamlockEnabled.HighArcOn = Value
        if Value then
            CamlockEnabled.LowArcOn = false
            Library.Options.LowArcCamlock:SetValue(false)
        elseif not CamlockEnabled.LowArcOn then
            StopCamlock()
        end
    end
}):AddKeyPicker("HighArcCamlockKey", {
    Text = "High Arc Camlock Key",
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle"
})

CamlockGroup:AddToggle("LowArcCamlock", {
    Text = "Low Arc Camlock",
    Tooltip = "Enables Low Arc Camlock",
    Default = false,
    Callback = function(Value)
        CamlockEnabled.LowArcOn = Value
        if Value then
            CamlockEnabled.HighArcOn = false
            Library.Options.HighArcCamlock:SetValue(false)
        elseif not CamlockEnabled.HighArcOn then
            StopCamlock()
        end
    end
}):AddKeyPicker("LowArcCamlockKey", {
    Text = "Low Arc Camlock Key",
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle"
})

CamlockGroup:AddToggle("CamlockAutoShoot", {
    Text = "Camlock Auto-Shoot",
    Tooltip = "Automatically shoots with Camlock",
    Default = false,
    Callback = function(Value)
        CamlockEnabled.AutoShootOn = Value and (CamlockEnabled.LowArcOn or CamlockEnabled.HighArcOn)
    end
}):AddKeyPicker("CamlockAutoShootKey", {
    Text = "Camlock Auto-Shoot Key",
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle"
})

-- ================= EXTRA SETTINGS =================
ExtraGroup:AddSlider("SpeedSlider", {
    Text = "Speed Multiplier [Default 1x]",
    Default = 1,
    Min = 1,
    Max = 1.2,
    Rounding = 2,
    Callback = function(Value)
        SpeedMultiplier = Value
        ApplySpeed()
    end
})

ExtraGroup:AddToggle("RangeIndicator", {
    Text = "Range Indicator",
    Tooltip = "Highlights character green if ur in aimbot range",
    Default = false,
    Callback = function(Value)
        RangeIndicatorEnabled = Value
        if Value then
            StartRangeIndicator()
        else
            StopRangeIndicator()
        end
    end
}):AddKeyPicker("RangeIndicatorKey", {
    Text = "Range Indicator Key",
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle"
})

ExtraGroup:AddToggle("AntiFall", {
    Text = "Anti-Fall",
    Tooltip = "Prevents getting dropped by opponents",
    Default = false,
    Callback = function(Value)
        SetAntiFall(Value)
    end
}):AddKeyPicker("AntiFallKey", {
    Text = "Anti-Fall Key",
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle"
})

ExtraGroup:AddToggle("AntiTravel", {
    Text = "Anti-Travel",
    Tooltip = "Allows jumping with the ball",
    Default = false,
    Callback = function(Value)
        SetAntiTravel(Value)
    end
}):AddKeyPicker("AntiTravelKey", {
    Text = "Anti-Travel Key",
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle"
})

ExtraGroup:AddToggle("AntiOOB", {
    Text = "Anti-OOB",
    Tooltip = "Prevents out-of-bounds violations",
    Default = false,
    Callback = function(Value)
        SetAntiOOB(Value)
    end
}):AddKeyPicker("AntiOOBKey", {
    Text = "Anti-OOB Key",
    Default = "None",
    SyncToggleState = true,
    Mode = "Toggle"
})

-- ================= MISC SETTINGS =================
MiscGroup:AddButton({
    Text = "Spawn Ball PRAC AREA",
    Tooltip = "Spawns a ball in the practice area",
    Func = function()
        SpawnBall()
    end
})

MiscGroup:AddButton({
    Text = "Spawn Vehicle",
    Tooltip = "Spawns/Despawns a vehicle",
    Func = function()
        SpawnVehicle()
    end
})

MiscGroup:AddButton({
    Text = "Claim Lukes Following Rewards",
    Tooltip = "Claims Luke's following rewards",
    Func = function()
        ClaimLukesReward()
    end
})

MiscGroup:AddButton({
    Text = "[Click to Travel (Trolling)]",
    Tooltip = "Triggers travel action for trolling",
    Func = function()
        ClickToTravel()
    end
})

-- ================= UI SETTINGS =================
local MenuGroup = UISettingsTab:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = false,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end
})

MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end
})

MenuGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        local DPI = tonumber(Value)
        Library:SetDPIScale(DPI)
    end
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind",
    Callback = function(Value)
        print("[cb] Menu keybind toggled:", Value)
    end,
    ChangedCallback = function(New)
        print("[cb] Menu keybind changed:", New)
    end
})

MenuGroup:AddButton({
    Text = "Unload",
    Func = function()
        Library:Unload()
    end,
    Tooltip = "Unloads the script"
})

-- Addons: SaveManager and ThemeManager
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua"))()

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("Umbral")
SaveManager:SetFolder("Umbral")
SaveManager:BuildConfigSection(UISettingsTab)
ThemeManager:ApplyToTab(UISettingsTab)
SaveManager:LoadAutoloadConfig()

-- Set custom menu keybind
Library.ToggleKeybind = Library.Options.MenuKeybind

-- Show watermark
Library:SetWatermarkVisibility(true)
local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local WatermarkConnection = RunService.RenderStepped:Connect(function()
    FrameCounter += 1
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end
    Library:SetWatermark(('Umbral | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ))
end)

-- Enable custom cursor (controlled by UI Settings toggle)
Library.ShowCustomCursor = false

-- Show the UI
Library:Toggle(true)
