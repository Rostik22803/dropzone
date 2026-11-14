-- language: Lua, file: AdvancedESP.lua, target: Roblox Luau (Executor / Standalone)
-- High-Definition Anatomical Skeleton & Corner Box ESP
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local ESP_CONFIG = {
    Enabled = true,
    TeamCheck = true,
    MaxDistance = 2000,

    -- Box Options
    BoxEnabled = true,
    BoxType = "Corner", -- "Corner" | "Full"
    BoxColor = Color3.fromRGB(255, 65, 65),
    BoxTeamColor = Color3.fromRGB(65, 180, 255),
    BoxThickness = 1.5,
    BoxOutline = true,
    BoxOutlineColor = Color3.fromRGB(0, 0, 0),
    CornerRatio = 0.22,

    -- Skeleton Options
    SkeletonEnabled = true,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    SkeletonTeamColor = Color3.fromRGB(180, 230, 255),
    SkeletonThickness = 1.5,
    SkeletonTransparency = 0.9,
    SkeletonOutline = true, -- Black outline behind every bone line for crisp 3D look
    SkeletonOutlineColor = Color3.fromRGB(15, 15, 15),
    SkeletonOutlineThickness = 3.0,

    -- Head Circle
    HeadCircle = true,
    HeadCircleColor = Color3.fromRGB(255, 255, 255),
    HeadCircleScale = 1.6,
    ShowWeapon = true,

    -- Health Bar
    HealthBar = true,
    HealthBarWidth = 2,

    -- Text Info
    ShowInfo = true,
    InfoTextSize = 13,
}

local Entries = {}

local function createDrawing(drawType, props)
    local obj = Drawing.new(drawType)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

-- Hierarchical joint-to-joint calculation
-- Computes precise 3D joint anchors (shoulders, elbows, wrists, hips, knees, ankles, neck)
local function getJointPoints(char, isR15)
    local points = {}

    if isR15 then
        local head = char:FindFirstChild("Head")
        local upperTorso = char:FindFirstChild("UpperTorso")
        local lowerTorso = char:FindFirstChild("LowerTorso")
        local leftUpperArm = char:FindFirstChild("LeftUpperArm")
        local leftLowerArm = char:FindFirstChild("LeftLowerArm")
        local leftHand = char:FindFirstChild("LeftHand")
        local rightUpperArm = char:FindFirstChild("RightUpperArm")
        local rightLowerArm = char:FindFirstChild("RightLowerArm")
        local rightHand = char:FindFirstChild("RightHand")
        local leftUpperLeg = char:FindFirstChild("LeftUpperLeg")
        local leftLowerLeg = char:FindFirstChild("LeftLowerLeg")
        local leftFoot = char:FindFirstChild("LeftFoot")
        local rightUpperLeg = char:FindFirstChild("RightUpperLeg")
        local rightLowerLeg = char:FindFirstChild("RightLowerLeg")
        local rightFoot = char:FindFirstChild("RightFoot")

        if not (head and upperTorso and lowerTorso) then return nil end

        -- Spine Anchors
        local utCF = upperTorso.CFrame
        local ltCF = lowerTorso.CFrame
        local headCF = head.CFrame

        points.Head = headCF.Position
        points.Neck = utCF:PointToWorldSpace(Vector3.new(0, upperTorso.Size.Y * 0.5, 0))
        points.Chest = utCF.Position
        points.Pelvis = ltCF:PointToWorldSpace(Vector3.new(0, -lowerTorso.Size.Y * 0.4, 0))

        -- Shoulders
        points.LeftShoulder = utCF:PointToWorldSpace(Vector3.new(-upperTorso.Size.X * 0.5, upperTorso.Size.Y * 0.35, 0))
        points.RightShoulder = utCF:PointToWorldSpace(Vector3.new(upperTorso.Size.X * 0.5, upperTorso.Size.Y * 0.35, 0))

        -- Left Arm
        if leftUpperArm and leftLowerArm and leftHand then
            points.LeftElbow = leftLowerArm.CFrame:PointToWorldSpace(Vector3.new(0, leftLowerArm.Size.Y * 0.4, 0))
            points.LeftWrist = leftHand.CFrame.Position
        end

        -- Right Arm
        if rightUpperArm and rightLowerArm and rightHand then
            points.RightElbow = rightLowerArm.CFrame:PointToWorldSpace(Vector3.new(0, rightLowerArm.Size.Y * 0.4, 0))
            points.RightWrist = rightHand.CFrame.Position
        end

        -- Hips
        points.LeftHip = ltCF:PointToWorldSpace(Vector3.new(-lowerTorso.Size.X * 0.35, -lowerTorso.Size.Y * 0.4, 0))
        points.RightHip = ltCF:PointToWorldSpace(Vector3.new(lowerTorso.Size.X * 0.35, -lowerTorso.Size.Y * 0.4, 0))

        -- Left Leg
        if leftUpperLeg and leftLowerLeg and leftFoot then
            points.LeftKnee = leftLowerLeg.CFrame:PointToWorldSpace(Vector3.new(0, leftLowerLeg.Size.Y * 0.4, 0))
            points.LeftAnkle = leftFoot.CFrame.Position
        end

        -- Right Leg
        if rightUpperLeg and rightLowerLeg and rightFoot then
            points.RightKnee = rightLowerLeg.CFrame:PointToWorldSpace(Vector3.new(0, rightLowerLeg.Size.Y * 0.4, 0))
            points.RightAnkle = rightFoot.CFrame.Position
        end

    else
        -- R6 Rig
        local head = char:FindFirstChild("Head")
        local torso = char:FindFirstChild("Torso")
        local leftArm = char:FindFirstChild("Left Arm")
        local rightArm = char:FindFirstChild("Right Arm")
        local leftLeg = char:FindFirstChild("Left Leg")
        local rightLeg = char:FindFirstChild("Right Leg")

        if not (head and torso) then return nil end

        local tCF = torso.CFrame
        local tSize = torso.Size

        points.Head = head.Position
        points.Neck = tCF:PointToWorldSpace(Vector3.new(0, tSize.Y * 0.5, 0))
        points.Chest = tCF.Position
        points.Pelvis = tCF:PointToWorldSpace(Vector3.new(0, -tSize.Y * 0.5, 0))

        -- Collar & Shoulders
        points.LeftShoulder = tCF:PointToWorldSpace(Vector3.new(-tSize.X * 0.55, tSize.Y * 0.4, 0))
        points.RightShoulder = tCF:PointToWorldSpace(Vector3.new(tSize.X * 0.55, tSize.Y * 0.4, 0))

        -- Arms with Elbow midpoint
        if leftArm then
            local laCF = leftArm.CFrame
            local laSize = leftArm.Size
            points.LeftElbow = laCF.Position
            points.LeftWrist = laCF:PointToWorldSpace(Vector3.new(0, -laSize.Y * 0.45, 0))
        end

        if rightArm then
            local raCF = rightArm.CFrame
            local raSize = rightArm.Size
            points.RightElbow = raCF.Position
            points.RightWrist = raCF:PointToWorldSpace(Vector3.new(0, -raSize.Y * 0.45, 0))
        end

        -- Hips
        points.LeftHip = tCF:PointToWorldSpace(Vector3.new(-tSize.X * 0.35, -tSize.Y * 0.5, 0))
        points.RightHip = tCF:PointToWorldSpace(Vector3.new(tSize.X * 0.35, -tSize.Y * 0.5, 0))

        -- Legs with Knee midpoint
        if leftLeg then
            local llCF = leftLeg.CFrame
            local llSize = leftLeg.Size
            points.LeftKnee = llCF.Position
            points.LeftAnkle = llCF:PointToWorldSpace(Vector3.new(0, -llSize.Y * 0.45, 0))
        end

        if rightLeg then
            local rlCF = rightLeg.CFrame
            local rlSize = rightLeg.Size
            points.RightKnee = rlCF.Position
            points.RightAnkle = rlCF:PointToWorldSpace(Vector3.new(0, -rlSize.Y * 0.45, 0))
        end
    end

    return points
end

-- Anatomical Connections (Pairs of points)
local SKELETON_PAIRS = {
    -- Spine & Head
    {"Head", "Neck"},
    {"Neck", "Chest"},
    {"Chest", "Pelvis"},

    -- Collarbone / Shoulder span
    {"Neck", "LeftShoulder"},
    {"Neck", "RightShoulder"},

    -- Left Arm
    {"LeftShoulder", "LeftElbow"},
    {"LeftElbow", "LeftWrist"},

    -- Right Arm
    {"RightShoulder", "RightElbow"},
    {"RightElbow", "RightWrist"},

    -- Pelvis / Hips
    {"Pelvis", "LeftHip"},
    {"Pelvis", "RightHip"},

    -- Left Leg
    {"LeftHip", "LeftKnee"},
    {"LeftKnee", "LeftAnkle"},

    -- Right Leg
    {"RightHip", "RightKnee"},
    {"RightKnee", "RightAnkle"},
}

local function getTargets()
    local targets = {}
    local liveFolder = Workspace:FindFirstChild("Live")
    if liveFolder then
        for _, model in ipairs(liveFolder:GetChildren()) do
            if model:IsA("Model") and model ~= LocalPlayer.Character then
                local hum = model:FindFirstChildOfClass("Humanoid")
                local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
                if hum and root and hum.Health > 0 and model:GetAttribute("Eliminated") ~= true then
                    table.insert(targets, model)
                end
            end
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            if hum and root and hum.Health > 0 and not table.find(targets, char) then
                table.insert(targets, char)
            end
        end
    end
    return targets
end

local function isTeammate(model)
    local plr = Players:GetPlayerFromCharacter(model)
    if plr and LocalPlayer.Team and plr.Team then
        return plr.Team == LocalPlayer.Team
    end
    local myChar = LocalPlayer.Character
    if myChar then
        local myTeam = myChar:GetAttribute("TeamId")
        local targetTeam = model:GetAttribute("TeamId")
        if myTeam and targetTeam then
            return myTeam == targetTeam
        end
    end
    return false
end

local function createEntry(model)
    local entry = {
        Model = model,
        Drawings = {
            Box = {},
            BoxOutline = {},
            Skeleton = {},
            SkeletonOutline = {},
            HeadCircle = createDrawing("Circle", { Filled = false, Thickness = 1.5, Visible = false }),
            HeadCircleOutline = createDrawing("Circle", { Filled = false, Thickness = 3.0, Color = Color3.fromRGB(0, 0, 0), Visible = false }),
            HealthBarBg = createDrawing("Square", { Filled = true, Color = Color3.fromRGB(15, 15, 15), Transparency = 0.8, Visible = false }),
            HealthBarFill = createDrawing("Square", { Filled = true, Color = Color3.fromRGB(0, 255, 120), Transparency = 1, Visible = false }),
            InfoText = createDrawing("Text", { Size = ESP_CONFIG.InfoTextSize, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255), Visible = false }),
        }
    }

    for i = 1, 8 do
        entry.Drawings.Box[i] = createDrawing("Line", { Thickness = ESP_CONFIG.BoxThickness, Visible = false })
        entry.Drawings.BoxOutline[i] = createDrawing("Line", { Thickness = ESP_CONFIG.BoxThickness + 1.5, Color = ESP_CONFIG.BoxOutlineColor, Visible = false })
    end

    local boneCount = #SKELETON_PAIRS
    for i = 1, boneCount do
        entry.Drawings.SkeletonOutline[i] = createDrawing("Line", {
            Thickness = ESP_CONFIG.SkeletonOutlineThickness,
            Color = ESP_CONFIG.SkeletonOutlineColor,
            Visible = false
        })
        entry.Drawings.Skeleton[i] = createDrawing("Line", {
            Thickness = ESP_CONFIG.SkeletonThickness,
            Color = ESP_CONFIG.SkeletonColor,
            Visible = false
        })
    end

    function entry:SetVisible(vis)
        for _, l in ipairs(self.Drawings.Box) do l.Visible = vis end
        for _, l in ipairs(self.Drawings.BoxOutline) do l.Visible = vis end
        for _, l in ipairs(self.Drawings.Skeleton) do l.Visible = vis end
        for _, l in ipairs(self.Drawings.SkeletonOutline) do l.Visible = vis end
        self.Drawings.HeadCircle.Visible = vis
        self.Drawings.HeadCircleOutline.Visible = vis
        self.Drawings.HealthBarBg.Visible = vis
        self.Drawings.HealthBarFill.Visible = vis
        self.Drawings.InfoText.Visible = vis
    end

    function entry:Destroy()
        for _, list in pairs(self.Drawings) do
            if type(list) == "table" then
                for _, d in pairs(list) do pcall(function() d:Remove() end) end
            else
                pcall(function() list:Remove() end)
            end
        end
    end

    return entry
end

local function updateESP()
    Camera = Workspace.CurrentCamera
    if not Camera then return end
    if not ESP_CONFIG.Enabled then
        for _, e in pairs(Entries) do e:SetVisible(false) end
        return
    end

    local validModels = getTargets()
    local validMap = {}

    for _, model in ipairs(validModels) do
        validMap[model] = true
        if not Entries[model] then
            Entries[model] = createEntry(model)
        end
    end

    for model, entry in pairs(Entries) do
        if not validMap[model] or not model.Parent then
            entry:Destroy()
            Entries[model] = nil
        end
    end

    local camPos = Camera.CFrame.Position

    for model, entry in pairs(Entries) do
        local hum = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
        if not hum or not root or hum.Health <= 0 then
            entry:SetVisible(false)
            continue
        end

        local rootPos = root.Position
        local dist = (rootPos - camPos).Magnitude
        if dist > ESP_CONFIG.MaxDistance then
            entry:SetVisible(false)
            continue
        end

        local teammate = isTeammate(model)
        if ESP_CONFIG.TeamCheck and teammate then
            entry:SetVisible(false)
            continue
        end

        local rootScreen, onScreen = Camera:WorldToViewportPoint(rootPos)
        if not onScreen then
            entry:SetVisible(false)
            continue
        end

        local isR15 = hum.RigType == Enum.HumanoidRigType.R15 or model:FindFirstChild("UpperTorso") ~= nil
        local jointPoints = getJointPoints(model, isR15)

        -------------------------------------------------------------
        -- 1. DETAILED SKELETON WITH OUTLINES & JOINTS
        -------------------------------------------------------------
        if ESP_CONFIG.SkeletonEnabled and jointPoints then
            local skelCol = teammate and ESP_CONFIG.SkeletonTeamColor or ESP_CONFIG.SkeletonColor

            for idx, pair in ipairs(SKELETON_PAIRS) do
                local posA = jointPoints[pair[1]]
                local posB = jointPoints[pair[2]]
                local line = entry.Drawings.Skeleton[idx]
                local outline = entry.Drawings.SkeletonOutline[idx]

                if posA and posB and line and outline then
                    local scrA, visA = Camera:WorldToViewportPoint(posA)
                    local scrB, visB = Camera:WorldToViewportPoint(posB)

                    if visA or visB then
                        local vA = Vector2.new(scrA.X, scrA.Y)
                        local vB = Vector2.new(scrB.X, scrB.Y)

                        if ESP_CONFIG.SkeletonOutline then
                            outline.From = vA
                            outline.To = vB
                            outline.Visible = true
                        else
                            outline.Visible = false
                        end

                        line.From = vA
                        line.To = vB
                        line.Color = skelCol
                        line.Transparency = ESP_CONFIG.SkeletonTransparency
                        line.Thickness = ESP_CONFIG.SkeletonThickness
                        line.Visible = true
                    else
                        line.Visible = false
                        outline.Visible = false
                    end
                elseif line then
                    line.Visible = false
                    if outline then outline.Visible = false end
                end
            end

            -- Head Circle
            if ESP_CONFIG.HeadCircle and jointPoints.Head then
                local hScr, hVis = Camera:WorldToViewportPoint(jointPoints.Head)
                if hVis then
                    local headPart = model:FindFirstChild("Head")
                    local headRadius = 4
                    if headPart then
                        local edgeScr = Camera:WorldToViewportPoint(jointPoints.Head + Camera.CFrame.RightVector * (headPart.Size.Y * 0.45 * ESP_CONFIG.HeadCircleScale))
                        headRadius = math.clamp(math.abs(edgeScr.X - hScr.X), 4, 60)
                    end

                    local hc = entry.Drawings.HeadCircle
                    local hco = entry.Drawings.HeadCircleOutline
                    local center = Vector2.new(hScr.X, hScr.Y)

                    hco.Position = center
                    hco.Radius = headRadius
                    hco.Visible = true

                    hc.Position = center
                    hc.Radius = headRadius
                    hc.Color = ESP_CONFIG.HeadCircleColor
                    hc.Visible = true
                else
                    entry.Drawings.HeadCircle.Visible = false
                    entry.Drawings.HeadCircleOutline.Visible = false
                end
            else
                entry.Drawings.HeadCircle.Visible = false
                entry.Drawings.HeadCircleOutline.Visible = false
            end
        else
            for _, l in ipairs(entry.Drawings.Skeleton) do l.Visible = false end
            for _, l in ipairs(entry.Drawings.SkeletonOutline) do l.Visible = false end
            entry.Drawings.HeadCircle.Visible = false
            entry.Drawings.HeadCircleOutline.Visible = false
        end

        -------------------------------------------------------------
        -- 2. CORNER BOXES
        -------------------------------------------------------------
        local cframe, size = model:GetBoundingBox()
        local height = size.Y
        local topWorld = cframe.Position + Vector3.new(0, height * 0.5 + 0.3, 0)
        local botWorld = cframe.Position - Vector3.new(0, height * 0.5 + 0.3, 0)

        local topScreen, topVis = Camera:WorldToViewportPoint(topWorld)
        local botScreen, botVis = Camera:WorldToViewportPoint(botWorld)

        if not topVis and not botVis then
            for i = 1, 8 do
                entry.Drawings.Box[i].Visible = false
                entry.Drawings.BoxOutline[i].Visible = false
            end
            entry.Drawings.HealthBarBg.Visible = false
            entry.Drawings.HealthBarFill.Visible = false
            entry.Drawings.InfoText.Visible = false
            continue
        end

        local boxHeight = math.abs(botScreen.Y - topScreen.Y)
        local boxWidth = boxHeight * 0.55
        local boxX = math.floor(rootScreen.X - boxWidth * 0.5)
        local boxY = math.floor(topScreen.Y)
        local boxCol = teammate and ESP_CONFIG.BoxTeamColor or ESP_CONFIG.BoxColor

        if ESP_CONFIG.BoxEnabled then
            local cornerLen = math.clamp(math.floor(boxWidth * ESP_CONFIG.CornerRatio), 5, 24)
            local bLines = entry.Drawings.Box
            local oLines = entry.Drawings.BoxOutline

            -- Top-Left
            bLines[1].From = Vector2.new(boxX, boxY); bLines[1].To = Vector2.new(boxX + cornerLen, boxY)
            bLines[2].From = Vector2.new(boxX, boxY); bLines[2].To = Vector2.new(boxX, boxY + cornerLen)
            -- Top-Right
            bLines[3].From = Vector2.new(boxX + boxWidth, boxY); bLines[3].To = Vector2.new(boxX + boxWidth - cornerLen, boxY)
            bLines[4].From = Vector2.new(boxX + boxWidth, boxY); bLines[4].To = Vector2.new(boxX + boxWidth, boxY + cornerLen)
            -- Bottom-Left
            bLines[5].From = Vector2.new(boxX, boxY + boxHeight); bLines[5].To = Vector2.new(boxX + cornerLen, boxY + boxHeight)
            bLines[6].From = Vector2.new(boxX, boxY + boxHeight); bLines[6].To = Vector2.new(boxX, boxY + boxHeight - cornerLen)
            -- Bottom-Right
            bLines[7].From = Vector2.new(boxX + boxWidth, boxY + boxHeight); bLines[7].To = Vector2.new(boxX + boxWidth - cornerLen, boxY + boxHeight)
            bLines[8].From = Vector2.new(boxX + boxWidth, boxY + boxHeight); bLines[8].To = Vector2.new(boxX + boxWidth, boxY + boxHeight - cornerLen)

            for i = 1, 8 do
                bLines[i].Color = boxCol
                bLines[i].Visible = true
                oLines[i].From = bLines[i].From
                oLines[i].To = bLines[i].To
                oLines[i].Visible = true
            end
        else
            for i = 1, 8 do
                entry.Drawings.Box[i].Visible = false
                entry.Drawings.BoxOutline[i].Visible = false
            end
        end

        -------------------------------------------------------------
        -- 3. HEALTH BAR
        -------------------------------------------------------------
        if ESP_CONFIG.HealthBar then
            local hp = math.clamp(hum.Health, 0, hum.MaxHealth)
            local hpPercent = hp / math.max(hum.MaxHealth, 1)
            local barX = boxX - 6
            local barY = boxY
            local barH = boxHeight

            local bg = entry.Drawings.HealthBarBg
            bg.Position = Vector2.new(barX, barY - 1)
            bg.Size = Vector2.new(ESP_CONFIG.HealthBarWidth + 2, barH + 2)
            bg.Visible = true

            local fill = entry.Drawings.HealthBarFill
            local fillH = math.floor(barH * hpPercent)
            fill.Position = Vector2.new(barX + 1, barY + (barH - fillH))
            fill.Size = Vector2.new(ESP_CONFIG.HealthBarWidth, fillH)

            local r = math.clamp((1 - hpPercent) * 2, 0, 1)
            local g = math.clamp(hpPercent * 2, 0, 1)
            fill.Color = Color3.new(r, g, 0)
            fill.Visible = true
        else
            entry.Drawings.HealthBarBg.Visible = false
            entry.Drawings.HealthBarFill.Visible = false
        end

        -------------------------------------------------------------
        -- 4. INFO TEXT
        -------------------------------------------------------------
        if ESP_CONFIG.ShowInfo then
            local info = entry.Drawings.InfoText
            local displayName = model:GetAttribute("DisplayName") or model.Name
            local stateTag = model:GetAttribute("Knocked") and " [KNOCKED]" or ""
            info.Text = string.format("%s%s [%dm]", displayName, stateTag, math.floor(dist))
            if ESP_CONFIG.ShowWeapon then
                local tool = model:FindFirstChildOfClass("Tool")
                local equipped = model:GetAttribute("Equipped") or model:GetAttribute("UsingItem") or (tool and tool.Name)
                info.Text = info.Text .. "\n[" .. tostring(equipped or "Empty hands") .. "]"
            end
            info.Position = Vector2.new(boxX + boxWidth * 0.5, boxY + boxHeight + 4)
            info.Visible = true
        else
            entry.Drawings.InfoText.Visible = false
        end
    end
end

-- Mobile hub; all visual mutations are restored on disable/unload.
local UserInputService = game:GetService("UserInputService")
local hub_connections = {}
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(hub_connections, connection)
    return connection
end
local function cham_config()
    return {Enabled = false, Style = "Solid", Color = Color3.new(1, 1, 1), Transparency = 0.45, ThroughWalls = true}
end
local Hub = {
    Enemy = cham_config(), Hands = cham_config(), Weapon = cham_config(), Self = cham_config(),
    Aim = {Enabled = false, Silent = false, FOV = 140, Smooth = 12, Visible = true, Part = "Head", ShowFOV = true},
}
local styles = {"Solid", "Outline", "Neon", "Glass", "ForceField", "Metal", "Wire", "Pulse", "Rainbow"}
local materials = {Neon = Enum.Material.Neon, Glass = Enum.Material.Glass, ForceField = Enum.Material.ForceField, Metal = Enum.Material.Metal}
local effects = Instance.new("Folder")
effects.Name = "OcelEffects"
effects.Parent = Workspace
local cham_records = {}
local target_part
local silent_status = "not connected"
local camera_controller, original_aim_ray, wrapped_aim_ray
local stopped = false

local function clear_record(part, record)
    if record.box then record.box:Destroy() end
    if part.Parent and record.modified then
        part.Color = record.color
        part.Material = record.material
        part.Transparency = record.transparency
        part.Reflectance = record.reflectance
    end
    cham_records[part] = nil
end

local function update_chams()
    local wanted = {}
    local function collect(root, config, filter)
        if not root or not config.Enabled then return end
        for _, part in ipairs(root:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and (not filter or filter(part)) then
                -- Do not reveal invisible helper parts or hitboxes.
                local old = cham_records[part]
                if (old and old.transparency or part.Transparency) < 1 then wanted[part] = config end
            end
        end
    end
    local character = LocalPlayer.Character
    collect(character, Hub.Self)
    local viewmodel = Camera and Camera:FindFirstChild("Viewmodel")
    local function is_arm(part)
        local cursor = part
        local arm = false
        while cursor and cursor ~= viewmodel do
            local name = cursor.Name:lower()
            if cursor:GetAttribute("WeaponId") then return false end
            if name:find("arm") or name:find("hand") then arm = true end
            cursor = cursor.Parent
        end
        return arm
    end
    collect(viewmodel, Hub.Hands, is_arm)
    collect(viewmodel, Hub.Weapon, function(part) return not is_arm(part) end)
    if not viewmodel and character then
        collect(character, Hub.Hands, function(part)
            return part.Name:lower():find("arm") or part.Name:lower():find("hand")
        end)
        collect(character:FindFirstChildOfClass("Tool"), Hub.Weapon)
    end
    local count = 0
    for _, model in ipairs(getTargets()) do
        local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
        if root and Camera and not isTeammate(model) and (root.Position - Camera.CFrame.Position).Magnitude <= ESP_CONFIG.MaxDistance then
            local _, visible = Camera:WorldToViewportPoint(root.Position)
            if visible and count < 16 then collect(model, Hub.Enemy); count = count + 1 end
        end
    end
    for part, record in pairs(cham_records) do
        if not wanted[part] or not part.Parent then clear_record(part, record) end
    end
    for part, config in pairs(wanted) do
        local record = cham_records[part]
        if not record then
            record = {color = part.Color, material = part.Material, transparency = part.Transparency, reflectance = part.Reflectance}
            cham_records[part] = record
        end
        local color = config.Style == "Rainbow" and Color3.fromHSV((os.clock() * 0.15) % 1, 0.8, 1) or config.Color
        local transparency = config.Transparency
        if config.Style == "Pulse" then transparency = math.clamp(transparency + math.sin(os.clock() * 3) * 0.2, 0, 1) end
        local wire = config.Style == "Wire" or config.Style == "Outline"
        if not record.box or record.wire ~= wire then
            if record.box then record.box:Destroy() end
            record.box = Instance.new(wire and "SelectionBox" or "BoxHandleAdornment")
            record.box.Adornee = part
            record.box.Parent = effects
            record.wire = wire
        end
        local box = record.box
        box.Color3 = color
        if wire then
            box.LineThickness = config.Style == "Wire" and 0.025 or 0.06
            box.SurfaceTransparency = 1
            box.Transparency = transparency
            -- SelectionBox does not expose AlwaysOnTop.
        else
            box.Size = part.Size + Vector3.new(0.015, 0.015, 0.015)
            box.AlwaysOnTop = config.ThroughWalls
            box.ZIndex = 2
            box.Transparency = transparency
        end
        local material = materials[config.Style]
        if material then
            part.Material = material
            part.Color = color
            part.Transparency = transparency
            part.Reflectance = config.Style == "Metal" and 0.45 or 0
            record.modified = true
        elseif record.modified then
            part.Material = record.material
            part.Color = record.color
            part.Transparency = record.transparency
            part.Reflectance = record.reflectance
            record.modified = false
        end
    end
end

local fov_circle = createDrawing("Circle", {Filled = false, Thickness = 1, Color = Color3.new(1, 1, 1), Transparency = 0.6, Visible = false, NumSides = 64})
local function update_aim(dt)
    target_part = nil
    if not Camera then return end
    local aim = Hub.Aim
    local center = Camera.ViewportSize * 0.5
    fov_circle.Position = center
    fov_circle.Radius = aim.FOV
    fov_circle.Visible = aim.ShowFOV and (aim.Enabled or aim.Silent)
    if not (aim.Enabled or aim.Silent) then return end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {effects, Camera}
    if LocalPlayer.Character then table.insert(exclude, LocalPlayer.Character) end
    params.FilterDescendantsInstances = exclude
    local best = aim.FOV
    for _, model in ipairs(getTargets()) do
        if not isTeammate(model) and not model:GetAttribute("Knocked") then
            local part = model:FindFirstChild(aim.Part) or model:FindFirstChild("HumanoidRootPart")
            if part and part:IsA("BasePart") and (part.Position - Camera.CFrame.Position).Magnitude <= ESP_CONFIG.MaxDistance then
                local screen, visible = Camera:WorldToViewportPoint(part.Position)
                local distance = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                if visible and distance < best then
                    local hit = aim.Visible and Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
                    if not hit or hit.Instance:IsDescendantOf(model) then best = distance; target_part = part end
                end
            end
        end
    end
    if target_part and aim.Enabled and not UserInputService:GetFocusedTextBox() then
        Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, target_part.Position), 1 - math.exp(-aim.Smooth * dt))
    end
end

-- Use the dump's aim-ray API, not a global Raycast/remote hook.
task.spawn(function()
    local client = game:GetService("ReplicatedStorage"):FindFirstChild("Client")
    local module = client and client:FindFirstChild("CameraController", true)
    if not module or not module:IsA("ModuleScript") then silent_status = "CameraController not found"; return end
    local ok, controller = pcall(require, module)
    if stopped then return end
    if not ok or type(controller) ~= "table" or type(controller.getAimRay) ~= "function" then
        silent_status = "getAimRay unavailable"; return
    end
    camera_controller = controller
    original_aim_ray = controller.getAimRay
    wrapped_aim_ray = function(...)
        local origin, direction = original_aim_ray(...)
        if Hub.Aim.Silent and target_part and target_part.Parent and typeof(origin) == "Vector3" then
            local delta = target_part.Position - origin
            if delta.Magnitude > 0.001 then return origin, delta.Unit end
        end
        return origin, direction
    end
    local assigned = pcall(function() controller.getAimRay = wrapped_aim_ray end)
    silent_status = assigned and "connected" or "controller is read-only"
end)

local gui = Instance.new("ScreenGui")
gui.Name = "OcelHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 100
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
local function instance(class, properties, parent)
    local object = Instance.new(class)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end
local function round(object, radius)
    instance("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, object)
end
local function button(parent, text, size)
    local object = instance("TextButton", {Size = size or UDim2.new(1, 0, 0, 44), BackgroundColor3 = Color3.fromRGB(29, 29, 29), TextColor3 = Color3.new(1, 1, 1), TextSize = 14, Font = Enum.Font.GothamMedium, Text = text, BorderSizePixel = 0, AutoButtonColor = true}, parent)
    round(object, 8)
    return object
end
local watermark = button(gui, "OCEL / HUB   •   MENU", UDim2.fromOffset(192, 44))
watermark.Position = UDim2.fromOffset(14, 10)
local panel = instance("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.54), Size = UDim2.fromOffset(420, 470), BackgroundColor3 = Color3.fromRGB(12, 12, 12), BorderSizePixel = 0}, gui)
round(panel, 14)
instance("UIStroke", {Color = Color3.fromRGB(75, 75, 75), Thickness = 1}, panel)
local scale = instance("UIScale", {Scale = 1}, panel)
local title = instance("TextLabel", {Position = UDim2.fromOffset(18, 8), Size = UDim2.new(1, -36, 0, 42), BackgroundTransparency = 1, Text = "Ocel-hub", TextColor3 = Color3.new(1, 1, 1), TextSize = 23, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}, panel)
local tabs = instance("Frame", {Position = UDim2.fromOffset(14, 58), Size = UDim2.new(1, -28, 0, 42), BackgroundTransparency = 1}, panel)
instance("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)}, tabs)
local content = instance("ScrollingFrame", {Position = UDim2.fromOffset(14, 112), Size = UDim2.new(1, -28, 1, -126), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.new(1, 1, 1), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y}, panel)
local active_page = "ESP"
local drag_input, drag_update
local function clear_page()
    drag_input, drag_update = nil, nil
    content.ScrollingEnabled = true
    for _, child in ipairs(content:GetChildren()) do child:Destroy() end
    instance("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, content)
    instance("UIPadding", {PaddingBottom = UDim.new(0, 12), PaddingRight = UDim.new(0, 8)}, content)
    content.CanvasPosition = Vector2.zero
end
local function toggle(label, config, key)
    local control = button(content, "")
    local function refresh() control.Text = label .. "   /   " .. (config[key] and "ON" or "OFF") end
    refresh()
    control.Activated:Connect(function() config[key] = not config[key]; refresh() end)
end
local function cycle(label, config, key, choices)
    local control = button(content, label .. "   /   " .. tostring(config[key]))
    control.Activated:Connect(function()
        config[key] = choices[((table.find(choices, config[key]) or 0) % #choices) + 1]
        control.Text = label .. "   /   " .. tostring(config[key])
    end)
end
local function slider(label, config, key, minimum, maximum, step)
    local row = instance("Frame", {Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = Color3.fromRGB(24, 24, 24), BorderSizePixel = 0}, content)
    round(row, 8)
    local text = instance("TextLabel", {Position = UDim2.fromOffset(12, 3), Size = UDim2.new(1, -24, 0, 26), BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left}, row)
    local track = button(row, "", UDim2.new(1, -24, 0, 28))
    track.Position = UDim2.fromOffset(12, 30)
    local fill = instance("Frame", {BackgroundColor3 = Color3.fromRGB(205, 205, 205), BorderSizePixel = 0, Active = false}, track)
    round(fill, 6)
    local function refresh()
        text.Text = label .. "   " .. string.format("%.2f", config[key])
        fill.Size = UDim2.new((config[key] - minimum) / (maximum - minimum), 0, 1, 0)
    end
    local function update(x)
        local alpha = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        config[key] = math.clamp(math.floor((minimum + alpha * (maximum - minimum)) / step + 0.5) * step, minimum, maximum)
        refresh()
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag_input, drag_update = input, update
            content.ScrollingEnabled = false
            update(input.Position.X)
        end
    end)
    refresh()
end
local function color_picker(config)
    local values = {R = config.Color.R, G = config.Color.G, B = config.Color.B}
    for _, channel in ipairs({"R", "G", "B"}) do
        local proxy = setmetatable({}, {__index = function(_, key) return values[key] end, __newindex = function(_, key, value)
            values[key] = value
            config.Color = Color3.new(values.R, values.G, values.B)
        end})
        slider("Color " .. channel, proxy, channel, 0, 1, 0.01)
    end
end
local selected_chams = "Enemy"
local show_page
show_page = function(page)
    active_page = page
    clear_page()
    for _, tab in ipairs(tabs:GetChildren()) do
        if tab:IsA("TextButton") then tab.BackgroundColor3 = tab.Name == page and Color3.fromRGB(225, 225, 225) or Color3.fromRGB(29, 29, 29); tab.TextColor3 = tab.Name == page and Color3.new(0, 0, 0) or Color3.new(1, 1, 1) end
    end
    if page == "ESP" then
        toggle("ESP", ESP_CONFIG, "Enabled")
        toggle("Team check", ESP_CONFIG, "TeamCheck")
        toggle("Boxes", ESP_CONFIG, "BoxEnabled")
        toggle("Skeleton", ESP_CONFIG, "SkeletonEnabled")
        toggle("Head circle", ESP_CONFIG, "HeadCircle")
        slider("Head size", ESP_CONFIG, "HeadCircleScale", 1, 3, 0.1)
        toggle("Health", ESP_CONFIG, "HealthBar")
        toggle("Names / distance", ESP_CONFIG, "ShowInfo")
        toggle("Held item", ESP_CONFIG, "ShowWeapon")
        slider("Max distance", ESP_CONFIG, "MaxDistance", 100, 3000, 50)
    elseif page == "CHAMS" then
        local choose = button(content, "Target   /   " .. selected_chams)
        choose.Activated:Connect(function()
            local choices = {"Enemy", "Hands", "Weapon", "Self"}
            selected_chams = choices[(table.find(choices, selected_chams) % #choices) + 1]
            show_page(page)
        end)
        local config = Hub[selected_chams]
        toggle("Chams", config, "Enabled")
        cycle("Style", config, "Style", styles)
        toggle("Through walls (filled styles)", config, "ThroughWalls")
        slider("Transparency", config, "Transparency", 0, 1, 0.01)
        color_picker(config)
    elseif page == "AIM" then
        toggle("Aim / camera", Hub.Aim, "Enabled")
        toggle("Silent aim / aim ray", Hub.Aim, "Silent")
        toggle("Visibility check", Hub.Aim, "Visible")
        toggle("Show FOV", Hub.Aim, "ShowFOV")
        cycle("Target part", Hub.Aim, "Part", {"Head", "HumanoidRootPart"})
        slider("FOV radius", Hub.Aim, "FOV", 30, 400, 5)
        slider("Aim speed", Hub.Aim, "Smooth", 1, 30, 1)
        button(content, "Silent API: " .. silent_status)
    else
        button(content, "Tap the watermark to hide / show")
        button(content, "Mobile • 16 enemy cham limit • 10 Hz")
        local unload = button(content, "Unload Ocel-hub")
        unload.Activated:Connect(function() if Hub.Destroy then Hub.Destroy() end end)
    end
end
for _, name in ipairs({"ESP", "CHAMS", "AIM", "HUB"}) do
    local tab = button(tabs, name, UDim2.new(0.25, -5, 1, 0))
    tab.Name = name
    tab.Activated:Connect(function() show_page(name) end)
end
connect(watermark.Activated, function() panel.Visible = not panel.Visible end)
connect(UserInputService.InputChanged, function(input)
    if drag_update and (input == drag_input or (drag_input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)) then drag_update(input.Position.X) end
end)
connect(UserInputService.InputEnded, function(input)
    if input == drag_input then drag_input, drag_update = nil, nil; content.ScrollingEnabled = true end
end)
local elapsed = 0
local function update_hub(dt)
    local viewport = Camera and Camera.ViewportSize or Vector2.new(800, 600)
    scale.Scale = math.min(1, (viewport.X - 24) / 420, (viewport.Y - 90) / 470)
    update_aim(dt)
    elapsed = elapsed + dt
    if elapsed >= 0.1 then elapsed = 0; update_chams() end
end
show_page("ESP")
RunService:BindToRenderStep("AdvancedESP_Vanta", Enum.RenderPriority.Camera.Value + 1, function(dt)
    updateESP()
    update_hub(dt)
end)

Hub.Destroy = function()
    if stopped then return end
    stopped = true
    RunService:UnbindFromRenderStep("AdvancedESP_Vanta")
    for _, connection in ipairs(hub_connections) do connection:Disconnect() end
    if camera_controller and camera_controller.getAimRay == wrapped_aim_ray then
        pcall(function() camera_controller.getAimRay = original_aim_ray end)
    end
    for part, record in pairs(cham_records) do clear_record(part, record) end
    for _, entry in pairs(Entries) do entry:Destroy() end
    table.clear(Entries)
    fov_circle:Remove()
    effects:Destroy()
    gui:Destroy()
end

return {
    Config = ESP_CONFIG,
    Hub = Hub,
    SetEnabled = function(val) ESP_CONFIG.Enabled = val end,
    SetSkeleton = function(val) ESP_CONFIG.SkeletonEnabled = val end,
    Destroy = Hub.Destroy,
}
