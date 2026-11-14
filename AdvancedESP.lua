-- language: Lua, file: AdvancedESP.lua, target: Roblox Luau (Executor / Standalone)
-- Ocel-hub: Pro ESP, Chams Engine & Minimalist Monochrome UI
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------
local Config = {
    -- ESP Settings
    ESPEnabled = true,
    TeamCheck = true,
    MaxDistance = 2500,

    -- Boxes
    BoxEnabled = true,
    BoxType = "Corner", -- "Corner" | "Full"
    BoxColor = Color3.fromRGB(240, 240, 240),
    BoxTeamColor = Color3.fromRGB(130, 130, 130),
    BoxThickness = 1.5,
    CornerRatio = 0.22,

    -- Skeletons
    SkeletonEnabled = true,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    SkeletonTeamColor = Color3.fromRGB(120, 120, 120),
    SkeletonThickness = 1.5,
    SkeletonTransparency = 0.95,
    SkeletonOutline = true,
    SkeletonOutlineThickness = 3.0,

    -- Head Circle (Enlarged head indicator)
    HeadCircle = true,
    HeadCircleScale = 1.6, -- 1.6x multiplier for clear readability

    -- Info & Enemy Weapon Display
    ShowInfo = true,
    ShowWeapon = true,
    InfoTextSize = 13,

    -- Health Bar
    HealthBar = true,
    HealthBarWidth = 2,

    -- Chams: Enemies
    EnemyChams = true,
    EnemyChamsType = "Highlight", -- "Highlight" | "Neon" | "Glass" | "ForceField"
    EnemyChamsColor = Color3.fromRGB(255, 255, 255),
    EnemyChamsFillTransparency = 0.5,
    EnemyChamsOutlineColor = Color3.fromRGB(0, 0, 0),
    EnemyChamsOutlineTransparency = 0.0,
    EnemyChamsAlwaysOnTop = true,

    -- Chams: Local Character (3rd person)
    SelfChams = false,
    SelfChamsType = "Highlight",
    SelfChamsColor = Color3.fromRGB(180, 180, 180),
    SelfChamsTransparency = 0.6,

    -- Chams: Viewmodel Arms
    ArmsChams = true,
    ArmsChamsType = "Neon", -- "Neon" | "Glass" | "ForceField" | "Solid"
    ArmsChamsColor = Color3.fromRGB(255, 255, 255),
    ArmsChamsTransparency = 0.2,

    -- Chams: Viewmodel Weapon
    WeaponChams = true,
    WeaponChamsType = "ForceField", -- "Neon" | "Glass" | "ForceField" | "Solid"
    WeaponChamsColor = Color3.fromRGB(200, 200, 200),
    WeaponChamsTransparency = 0.3,

    -- Menu State
    MenuOpen = true
}

local Entries = {}
local HighlightPool = {}
local OriginalMaterialCache = setmetatable({}, { __mode = "k" })

--------------------------------------------------------------------------------
-- DRAWING WRAPPER
--------------------------------------------------------------------------------
local function createDrawing(drawType, props)
    local obj = Drawing.new(drawType)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

--------------------------------------------------------------------------------
-- SKELETON ANATOMY ENGINE
--------------------------------------------------------------------------------
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

        local utCF = upperTorso.CFrame
        local ltCF = lowerTorso.CFrame
        local headCF = head.CFrame

        points.Head = headCF.Position
        points.Neck = utCF:PointToWorldSpace(Vector3.new(0, upperTorso.Size.Y * 0.5, 0))
        points.Chest = utCF.Position
        points.Pelvis = ltCF:PointToWorldSpace(Vector3.new(0, -lowerTorso.Size.Y * 0.4, 0))

        points.LeftShoulder = utCF:PointToWorldSpace(Vector3.new(-upperTorso.Size.X * 0.5, upperTorso.Size.Y * 0.35, 0))
        points.RightShoulder = utCF:PointToWorldSpace(Vector3.new(upperTorso.Size.X * 0.5, upperTorso.Size.Y * 0.35, 0))

        if leftUpperArm and leftLowerArm and leftHand then
            points.LeftElbow = leftLowerArm.CFrame:PointToWorldSpace(Vector3.new(0, leftLowerArm.Size.Y * 0.4, 0))
            points.LeftWrist = leftHand.CFrame.Position
        end

        if rightUpperArm and rightLowerArm and rightHand then
            points.RightElbow = rightLowerArm.CFrame:PointToWorldSpace(Vector3.new(0, rightLowerArm.Size.Y * 0.4, 0))
            points.RightWrist = rightHand.CFrame.Position
        end

        points.LeftHip = ltCF:PointToWorldSpace(Vector3.new(-lowerTorso.Size.X * 0.35, -lowerTorso.Size.Y * 0.4, 0))
        points.RightHip = ltCF:PointToWorldSpace(Vector3.new(lowerTorso.Size.X * 0.35, -lowerTorso.Size.Y * 0.4, 0))

        if leftUpperLeg and leftLowerLeg and leftFoot then
            points.LeftKnee = leftLowerLeg.CFrame:PointToWorldSpace(Vector3.new(0, leftLowerLeg.Size.Y * 0.4, 0))
            points.LeftAnkle = leftFoot.CFrame.Position
        end

        if rightUpperLeg and rightLowerLeg and rightFoot then
            points.RightKnee = rightLowerLeg.CFrame:PointToWorldSpace(Vector3.new(0, rightLowerLeg.Size.Y * 0.4, 0))
            points.RightAnkle = rightFoot.CFrame.Position
        end
    else
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

        points.LeftShoulder = tCF:PointToWorldSpace(Vector3.new(-tSize.X * 0.55, tSize.Y * 0.4, 0))
        points.RightShoulder = tCF:PointToWorldSpace(Vector3.new(tSize.X * 0.55, tSize.Y * 0.4, 0))

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

        points.LeftHip = tCF:PointToWorldSpace(Vector3.new(-tSize.X * 0.35, -tSize.Y * 0.5, 0))
        points.RightHip = tCF:PointToWorldSpace(Vector3.new(tSize.X * 0.35, -tSize.Y * 0.5, 0))

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

local SKELETON_PAIRS = {
    {"Head", "Neck"},
    {"Neck", "Chest"},
    {"Chest", "Pelvis"},
    {"Neck", "LeftShoulder"},
    {"Neck", "RightShoulder"},
    {"LeftShoulder", "LeftElbow"},
    {"LeftElbow", "LeftWrist"},
    {"RightShoulder", "RightElbow"},
    {"RightElbow", "RightWrist"},
    {"Pelvis", "LeftHip"},
    {"Pelvis", "RightHip"},
    {"LeftHip", "LeftKnee"},
    {"LeftKnee", "LeftAnkle"},
    {"RightHip", "RightKnee"},
    {"RightKnee", "RightAnkle"},
}

--------------------------------------------------------------------------------
-- TARGET IDENTIFICATION & WEAPON DETECTION
--------------------------------------------------------------------------------
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

local function getEquippedWeapon(model)
    -- Check Tool instance
    local tool = model:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name
    end

    -- Check attributes (Used widely in competitive projects like dropzone)
    local currentItem = model:GetAttribute("CurrentWeapon") or model:GetAttribute("EquippedWeapon") or model:GetAttribute("Weapon")
    if currentItem and tostring(currentItem) ~= "" then
        return tostring(currentItem)
    end

    -- Check custom weapon models inside character
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("Model") and (child.Name:match("Gun") or child.Name:match("Weapon") or child.Name:match("Rifle") or child.Name:match("Pistol") or child.Name:match("Shotgun")) then
            return child.Name
        end
    end

    return "Fists"
end

--------------------------------------------------------------------------------
-- CHAMS SUBSYSTEM
--------------------------------------------------------------------------------
local function applyHighlightChams(model, configColor, fillTrans, outlineColor, outlineTrans, alwaysOnTop)
    local hl = HighlightPool[model]
    if not hl or hl.Parent == nil then
        hl = Instance.new("Highlight")
        hl.Name = "OcelChams_HL"
        hl.Parent = CoreGui
        HighlightPool[model] = hl
    end

    hl.Adornee = model
    hl.FillColor = configColor
    hl.FillTransparency = fillTrans
    hl.OutlineColor = outlineColor
    hl.OutlineTransparency = outlineTrans
    hl.DepthMode = alwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    hl.Enabled = true
end

local function removeHighlightChams(model)
    local hl = HighlightPool[model]
    if hl then
        hl.Enabled = false
        hl.Adornee = nil
    end
end

local function applyMaterialChams(container, matType, color, trans)
    local rbxMat = Enum.Material.Neon
    if matType == "Glass" then rbxMat = Enum.Material.Glass end
    if matType == "ForceField" then rbxMat = Enum.Material.ForceField end
    if matType == "SmoothPlastic" or matType == "Solid" then rbxMat = Enum.Material.SmoothPlastic end

    for _, part in ipairs(container:GetDescendants()) do
        if part:IsA("BasePart") then
            if not OriginalMaterialCache[part] then
                OriginalMaterialCache[part] = {
                    Material = part.Material,
                    Color = part.Color,
                    Transparency = part.Transparency
                }
            end
            part.Material = rbxMat
            part.Color = color
            part.Transparency = trans
        end
    end
end

local function restoreMaterials(container)
    for _, part in ipairs(container:GetDescendants()) do
        if part:IsA("BasePart") and OriginalMaterialCache[part] then
            local orig = OriginalMaterialCache[part]
            part.Material = orig.Material
            part.Color = orig.Color
            part.Transparency = orig.Transparency
            OriginalMaterialCache[part] = nil
        end
    end
end

local function updateChams()
    -- 1. Enemy Chams
    local targets = getTargets()
    local targetMap = {}
    for _, model in ipairs(targets) do
        targetMap[model] = true
        local teammate = isTeammate(model)
        if Config.EnemyChams and not (Config.TeamCheck and teammate) then
            if Config.EnemyChamsType == "Highlight" then
                applyHighlightChams(
                    model,
                    Config.EnemyChamsColor,
                    Config.EnemyChamsFillTransparency,
                    Config.EnemyChamsOutlineColor,
                    Config.EnemyChamsOutlineTransparency,
                    Config.EnemyChamsAlwaysOnTop
                )
            else
                removeHighlightChams(model)
                applyMaterialChams(model, Config.EnemyChamsType, Config.EnemyChamsColor, Config.EnemyChamsFillTransparency)
            end
        else
            removeHighlightChams(model)
            restoreMaterials(model)
        end
    end

    -- Clean up stale enemy highlights
    for model, hl in pairs(HighlightPool) do
        if not targetMap[model] or not model.Parent then
            hl:Destroy()
            HighlightPool[model] = nil
        end
    end

    -- 2. Self Chams
    local myChar = LocalPlayer.Character
    if myChar then
        if Config.SelfChams then
            applyHighlightChams(myChar, Config.SelfChamsColor, Config.SelfChamsTransparency, Color3.new(0, 0, 0), 0.2, false)
        else
            removeHighlightChams(myChar)
        end
    end

    -- 3. Viewmodel Arms & Weapon Chams
    local vm = Camera:FindFirstChild("Viewmodel") or Camera:FindFirstChild("Arms") or Camera:FindFirstChild("Gun") or Workspace:FindFirstChild("Viewmodel")
    if vm then
        local arms = vm:FindFirstChild("Arms") or vm:FindFirstChild("LeftArm") or vm:FindFirstChild("RightArm")
        if arms and Config.ArmsChams then
            applyMaterialChams(arms, Config.ArmsChamsType, Config.ArmsChamsColor, Config.ArmsChamsTransparency)
        end

        local weapon = vm:FindFirstChild("Weapon") or vm:FindFirstChild("Gun") or vm:FindFirstChild("Item")
        if weapon and Config.WeaponChams then
            applyMaterialChams(weapon, Config.WeaponChamsType, Config.WeaponChamsColor, Config.WeaponChamsTransparency)
        end
    end
end

--------------------------------------------------------------------------------
-- DRAWING ESP ENTRY
--------------------------------------------------------------------------------
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
            HealthBarFill = createDrawing("Square", { Filled = true, Color = Color3.fromRGB(240, 240, 240), Transparency = 1, Visible = false }),
            InfoText = createDrawing("Text", { Size = Config.InfoTextSize, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255), Visible = false }),
            WeaponText = createDrawing("Text", { Size = Config.InfoTextSize - 1, Center = true, Outline = true, Color = Color3.fromRGB(200, 200, 200), Visible = false }),
        }
    }

    for i = 1, 8 do
        entry.Drawings.Box[i] = createDrawing("Line", { Thickness = Config.BoxThickness, Visible = false })
        entry.Drawings.BoxOutline[i] = createDrawing("Line", { Thickness = Config.BoxThickness + 1.5, Color = Color3.fromRGB(0, 0, 0), Visible = false })
    end

    for i = 1, #SKELETON_PAIRS do
        entry.Drawings.SkeletonOutline[i] = createDrawing("Line", {
            Thickness = Config.SkeletonOutlineThickness,
            Color = Color3.fromRGB(10, 10, 10),
            Visible = false
        })
        entry.Drawings.Skeleton[i] = createDrawing("Line", {
            Thickness = Config.SkeletonThickness,
            Color = Config.SkeletonColor,
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
        self.Drawings.WeaponText.Visible = vis
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
    if not Config.ESPEnabled then
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
        if dist > Config.MaxDistance then
            entry:SetVisible(false)
            continue
        end

        local teammate = isTeammate(model)
        if Config.TeamCheck and teammate then
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
        -- SKELETON WITH ENLARGED HEAD
        -------------------------------------------------------------
        if Config.SkeletonEnabled and jointPoints then
            local skelCol = teammate and Config.SkeletonTeamColor or Config.SkeletonColor

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

                        if Config.SkeletonOutline then
                            outline.From = vA
                            outline.To = vB
                            outline.Visible = true
                        else
                            outline.Visible = false
                        end

                        line.From = vA
                        line.To = vB
                        line.Color = skelCol
                        line.Transparency = Config.SkeletonTransparency
                        line.Thickness = Config.SkeletonThickness
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

            -- Head Circle (Enlarged head indicator)
            if Config.HeadCircle and jointPoints.Head then
                local hScr, hVis = Camera:WorldToViewportPoint(jointPoints.Head)
                if hVis then
                    local headPart = model:FindFirstChild("Head")
                    local baseRadius = 5
                    if headPart then
                        local edgeScr = Camera:WorldToViewportPoint(jointPoints.Head + Camera.CFrame.RightVector * (headPart.Size.Y * 0.5))
                        baseRadius = math.clamp(math.abs(edgeScr.X - hScr.X), 4, 32)
                    end
                    local finalRadius = math.floor(baseRadius * Config.HeadCircleScale)

                    local hc = entry.Drawings.HeadCircle
                    local hco = entry.Drawings.HeadCircleOutline
                    local center = Vector2.new(hScr.X, hScr.Y)

                    hco.Position = center
                    hco.Radius = finalRadius
                    hco.Visible = true

                    hc.Position = center
                    hc.Radius = finalRadius
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
        -- CORNER BOX
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
            entry.Drawings.WeaponText.Visible = false
            continue
        end

        local boxHeight = math.abs(botScreen.Y - topScreen.Y)
        local boxWidth = boxHeight * 0.55
        local boxX = math.floor(rootScreen.X - boxWidth * 0.5)
        local boxY = math.floor(topScreen.Y)
        local boxCol = teammate and Config.BoxTeamColor or Config.BoxColor

        if Config.BoxEnabled then
            local cornerLen = math.clamp(math.floor(boxWidth * Config.CornerRatio), 5, 24)
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
                bLines[i].Visible = false
                oLines[i].Visible = false
            end
        end

        -------------------------------------------------------------
        -- HEALTH BAR
        -------------------------------------------------------------
        if Config.HealthBar then
            local hp = math.clamp(hum.Health, 0, hum.MaxHealth)
            local hpPercent = hp / math.max(hum.MaxHealth, 1)
            local barX = boxX - 6
            local barY = boxY
            local barH = boxHeight

            local bg = entry.Drawings.HealthBarBg
            bg.Position = Vector2.new(barX, barY - 1)
            bg.Size = Vector2.new(Config.HealthBarWidth + 2, barH + 2)
            bg.Visible = true

            local fill = entry.Drawings.HealthBarFill
            local fillH = math.floor(barH * hpPercent)
            fill.Position = Vector2.new(barX + 1, barY + (barH - fillH))
            fill.Size = Vector2.new(Config.HealthBarWidth, fillH)

            -- Monochrome gradient or high contrast
            local val = math.clamp(hpPercent, 0.2, 1)
            fill.Color = Color3.new(val, val, val)
            fill.Visible = true
        else
            entry.Drawings.HealthBarBg.Visible = false
            entry.Drawings.HealthBarFill.Visible = false
        end

        -------------------------------------------------------------
        -- INFO & ENEMY WEAPON TEXT
        -------------------------------------------------------------
        if Config.ShowInfo then
            local info = entry.Drawings.InfoText
            local displayName = model:GetAttribute("DisplayName") or model.Name
            local stateTag = model:GetAttribute("Knocked") and " [KNOCKED]" or ""
            info.Text = string.format("%s%s [%dm]", displayName, stateTag, math.floor(dist))
            info.Position = Vector2.new(boxX + boxWidth * 0.5, boxY + boxHeight + 4)
            info.Visible = true

            if Config.ShowWeapon then
                local wText = entry.Drawings.WeaponText
                local equipped = getEquippedWeapon(model)
                wText.Text = string.format("< %s >", string.upper(equipped))
                wText.Position = Vector2.new(boxX + boxWidth * 0.5, boxY + boxHeight + 18)
                wText.Visible = true
            else
                entry.Drawings.WeaponText.Visible = false
            end
        else
            entry.Drawings.InfoText.Visible = false
            entry.Drawings.WeaponText.Visible = false
        end
    end
end

--------------------------------------------------------------------------------
-- MINIMALIST MONOCHROME UI (Ocel-hub)
--------------------------------------------------------------------------------
local function buildMonochromeUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "OcelHub_Monochrome"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Parent safely
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = CoreGui
    else
        screenGui.Parent = CoreGui
    end

    -- Main Window
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 360, 0, 470)
    mainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(45, 45, 45)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    -- Subtle border glow / stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(55, 55, 55)
    stroke.Thickness = 1
    stroke.Parent = mainFrame

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 34)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleLine = Instance.new("Frame")
    titleLine.Size = UDim2.new(1, 0, 0, 1)
    titleLine.Position = UDim2.new(0, 0, 1, -1)
    titleLine.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleLine.BorderSizePixel = 0
    titleLine.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 1, 0)
    titleLabel.Position = UDim2.new(0, 14, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.Text = "OCEL-HUB  //  DROPZONE"
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    -- Content Scroll
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -44)
    scroll.Position = UDim2.new(0, 10, 0, 39)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 520)
    scroll.Parent = mainFrame

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    -- UI Component Helpers
    local function addSection(title)
        local sec = Instance.new("TextLabel")
        sec.Size = UDim2.new(1, 0, 0, 24)
        sec.BackgroundTransparency = 1
        sec.Font = Enum.Font.GothamBold
        sec.Text = string.upper(title)
        sec.TextColor3 = Color3.fromRGB(140, 140, 140)
        sec.TextSize = 11
        sec.TextXAlignment = Enum.TextXAlignment.Left
        sec.Parent = scroll
    end

    local function addToggle(text, defaultState, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        btn.BorderSizePixel = 1
        btn.BorderColor3 = Color3.fromRGB(35, 35, 35)
        btn.AutoButtonColor = false
        btn.Text = ""
        btn.Parent = scroll

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -40, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn

        local status = Instance.new("Frame")
        status.Size = UDim2.new(0, 14, 0, 14)
        status.Position = UDim2.new(1, -24, 0.5, -7)
        status.BackgroundColor3 = defaultState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(30, 30, 30)
        status.BorderSizePixel = 1
        status.BorderColor3 = Color3.fromRGB(60, 60, 60)
        status.Parent = btn

        local state = defaultState
        btn.MouseButton1Click:Connect(function()
            state = not state
            status.BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(30, 30, 30)
            callback(state)
        end)
    end

    local function addCycle(text, options, defaultIdx, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 28)
        frame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
        frame.BorderSizePixel = 1
        frame.BorderColor3 = Color3.fromRGB(35, 35, 35)
        frame.Parent = scroll

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.5, 0, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.Gotham
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.45, 0, 1, -6)
        btn.Position = UDim2.new(0.52, 0, 0, 3)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamMedium
        btn.Text = options[defaultIdx]
        btn.TextColor3 = Color3.fromRGB(240, 240, 240)
        btn.TextSize = 11
        btn.Parent = frame

        local current = defaultIdx
        btn.MouseButton1Click:Connect(function()
            current = (current % #options) + 1
            btn.Text = options[current]
            callback(options[current])
        end)
    end

    -- SECTION: VISUALS
    addSection("Visuals & Skeleton")
    addToggle("ESP Master Toggle", Config.ESPEnabled, function(v) Config.ESPEnabled = v end)
    addToggle("Corner Box", Config.BoxEnabled, function(v) Config.BoxEnabled = v end)
    addToggle("Anatomical Skeleton", Config.SkeletonEnabled, function(v) Config.SkeletonEnabled = v end)
    addToggle("Enlarged Head Circle", Config.HeadCircle, function(v) Config.HeadCircle = v end)
    addToggle("Show Enemy Weapon", Config.ShowWeapon, function(v) Config.ShowWeapon = v end)
    addToggle("Team Check", Config.TeamCheck, function(v) Config.TeamCheck = v end)

    -- SECTION: CHAMS
    addSection("Chams Suite")
    addToggle("Enemy Chams", Config.EnemyChams, function(v) Config.EnemyChams = v end)
    addCycle("Enemy Chams Type", {"Highlight", "Neon", "Glass", "ForceField"}, 1, function(v) Config.EnemyChamsType = v end)
    addToggle("Arms Chams", Config.ArmsChams, function(v) Config.ArmsChams = v end)
    addCycle("Arms Material", {"Neon", "Glass", "ForceField", "Solid"}, 1, function(v) Config.ArmsChamsType = v end)
    addToggle("Weapon Chams", Config.WeaponChams, function(v) Config.WeaponChams = v end)
    addCycle("Weapon Material", {"ForceField", "Neon", "Glass", "Solid"}, 1, function(v) Config.WeaponChamsType = v end)
    addToggle("Self Chams (3rd Person)", Config.SelfChams, function(v) Config.SelfChams = v end)

    -- Toggle Hotkey (Right Shift / Insert)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and (input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert) then
            mainFrame.Visible = not mainFrame.Visible
            Config.MenuOpen = mainFrame.Visible
        end
    end)
end

--------------------------------------------------------------------------------
-- MAIN LOOPS
--------------------------------------------------------------------------------
buildMonochromeUI()

RunService:BindToRenderStep("OcelESP_Render", Enum.RenderPriority.Camera.Value + 1, function()
    updateESP()
    updateChams()
end)

return {
    Config = Config,
    SetMenuVisible = function(val) Config.MenuOpen = val end,
    Destroy = function()
        RunService:UnbindFromRenderStep("OcelESP_Render")
        for _, e in pairs(Entries) do e:Destroy() end
        table.clear(Entries)
        for _, hl in pairs(HighlightPool) do hl:Destroy() end
        table.clear(HighlightPool)
    end
}
