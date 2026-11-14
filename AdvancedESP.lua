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
                        local edgeScr = Camera:WorldToViewportPoint(jointPoints.Head + Camera.CFrame.RightVector * (headPart.Size.Y * 0.45))
                        headRadius = math.clamp(math.abs(edgeScr.X - hScr.X), 3, 25)
                    end

                    local hc = entry.Drawings.HeadCircle
                    local hco = entry.Drawings.HeadCircleOutline
                    local center = Vector2.new(hScr.X, hScr.Y)

                    hco.Position = center
                    hco.Radius = headRadius
                    hco.Visible = true

                    hc.Position = center
                    hc.Radius = headRadius
                    hc.Color = skelCol
                    hc.Visible = true
                else
                    entry.Drawings.HeadCircle.Visible = false
                    entry.Drawings.HeadCircleOutline.Visible = false
                end
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
            info.Position = Vector2.new(boxX + boxWidth * 0.5, boxY + boxHeight + 4)
            info.Visible = true
        else
            entry.Drawings.InfoText.Visible = false
        end
    end
end

RunService:BindToRenderStep("AdvancedESP_Vanta", Enum.RenderPriority.Camera.Value + 1, updateESP)

return {
    Config = ESP_CONFIG,
    SetEnabled = function(val) ESP_CONFIG.Enabled = val end,
    SetSkeleton = function(val) ESP_CONFIG.SkeletonEnabled = val end,
    Destroy = function()
        RunService:UnbindFromRenderStep("AdvancedESP_Vanta")
        for _, e in pairs(Entries) do e:Destroy() end
        table.clear(Entries)
    end
}
