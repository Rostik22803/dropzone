--[[
    ESP Controller: 2D Bounding Boxes & Skeleton Bones
    Target: Roblox Luau (Client Controller / Standalone Executor compatible)
    Works with R15 and R6 rigs, adapts to standard workspace.Live or Players
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local ESP = {
    Enabled = true,
    Boxes = true,
    BoxType = "2D", -- "2D" or "Corner"
    BoxColor = Color3.fromRGB(255, 60, 60),
    BoxThickness = 1.5,
    BoxTransparency = 0.9,

    Skeletons = true,
    SkeletonColor = Color3.fromRGB(0, 220, 255),
    SkeletonThickness = 1.5,
    SkeletonTransparency = 0.9,

    ShowNames = true,
    ShowDistance = true,
    TextSize = 13,
    TextColor = Color3.fromRGB(255, 255, 255),

    MaxDistance = 1000,
    TeamCheck = true,
}

local R15_BONES = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
}

local R6_BONES = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"},
}

local DRAWING_AVAILABLE = pcall(function()
    local test = Drawing.new("Line")
    test:Remove()
end)

local RenderCache = {}

local function createDrawing(objType, props)
    local obj = Drawing.new(objType)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

local ScreenGui = nil
if not DRAWING_AVAILABLE then
    local lp = Players.LocalPlayer
    local pg = lp and lp:FindFirstChildOfClass("PlayerGui")
    if pg then
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "ESP_Overlay"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.Parent = pg
    end
end

local function isTeamMate(char)
    local lp = Players.LocalPlayer
    if not lp then return false end
    
    local myChar = lp.Character
    if myChar and myChar == char then return true end

    -- ReplicatedStorage Participant check
    local rs = game:GetService("ReplicatedStorage")
    local success, Participant = pcall(function()
        return require(rs.Shared.Util.Participant)
    end)
    if success and Participant and Participant.sameTeam and myChar then
        local st = Participant.sameTeam(myChar, char)
        if st ~= nil then return st end
    end

    -- Standard team / player check
    local player = Players:GetPlayerFromCharacter(char)
    if player and lp.Team and player.Team then
        return player.Team == lp.Team
    end

    return false
end

local function getTargetModels()
    local list = {}
    local live = Workspace:FindFirstChild("Live")
    if live then
        for _, child in ipairs(live:GetChildren()) do
            if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then
                table.insert(list, child)
            end
        end
    else
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= Players.LocalPlayer and pl.Character then
                table.insert(list, pl.Character)
            end
        end
    end
    return list
end

local function cleanModelCache(model)
    local data = RenderCache[model]
    if not data then return end

    if data.Lines then
        for _, line in ipairs(data.Lines) do
            if DRAWING_AVAILABLE then
                line:Remove()
            else
                line:Destroy()
            end
        end
    end

    if data.Box then
        if DRAWING_AVAILABLE then
            data.Box:Remove()
        else
            data.Box:Destroy()
        end
    end

    if data.Text then
        if DRAWING_AVAILABLE then
            data.Text:Remove()
        else
            data.Text:Destroy()
        end
    end

    RenderCache[model] = nil
end

local function getOrCreateData(model)
    local data = RenderCache[model]
    if data then return data end

    data = {
        Lines = {},
        Box = nil,
        Text = nil
    }

    if DRAWING_AVAILABLE then
        data.Box = createDrawing("Square", {
            Thickness = ESP.BoxThickness,
            Filled = false,
            Transparency = ESP.BoxTransparency,
            Visible = false
        })
        data.Text = createDrawing("Text", {
            Size = ESP.TextSize,
            Center = true,
            Outline = true,
            Transparency = 1,
            Visible = false
        })
    else
        if ScreenGui then
            local boxFrame = Instance.new("Frame")
            boxFrame.BackgroundTransparency = 1
            boxFrame.BorderSizePixel = math.floor(ESP.BoxThickness)
            boxFrame.Visible = false
            boxFrame.Parent = ScreenGui
            data.Box = boxFrame

            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.TextSize = ESP.TextSize
            label.Font = Enum.Font.SourceSansBold
            label.TextColor3 = ESP.TextColor
            label.TextStrokeTransparency = 0.2
            label.Visible = false
            label.Parent = ScreenGui
            data.Text = label
        end
    end

    RenderCache[model] = data
    return data
end

local function updateBoneLine(lineObj, p1, p2, color, thickness)
    if DRAWING_AVAILABLE then
        lineObj.From = Vector2.new(p1.X, p1.Y)
        lineObj.To = Vector2.new(p2.X, p2.Y)
        lineObj.Color = color
        lineObj.Thickness = thickness
        lineObj.Transparency = ESP.SkeletonTransparency
        lineObj.Visible = true
    else
        local startPos = Vector2.new(p1.X, p1.Y)
        local endPos = Vector2.new(p2.X, p2.Y)
        local dist = (endPos - startPos).Magnitude
        local angle = math.atan2(endPos.Y - startPos.Y, endPos.X - startPos.X)

        lineObj.Size = UDim2.fromOffset(dist, thickness)
        lineObj.Position = UDim2.fromOffset((startPos.X + endPos.X) / 2, (startPos.Y + endPos.Y) / 2)
        lineObj.Rotation = math.deg(angle)
        lineObj.BackgroundColor3 = color
        lineObj.Visible = true
    end
end

local function hideModel(data)
    if not data then return end
    if data.Box then data.Box.Visible = false end
    if data.Text then data.Text.Visible = false end
    for _, l in ipairs(data.Lines) do
        l.Visible = false
    end
end

function ESP.Step()
    if not ESP.Enabled then
        for _, data in pairs(RenderCache) do
            hideModel(data)
        end
        return
    end

    Camera = Workspace.CurrentCamera
    if not Camera then return end

    local models = getTargetModels()
    local activeModels = {}

    for _, model in ipairs(models) do
        activeModels[model] = true

        local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
        local hum = model:FindFirstChildOfClass("Humanoid")

        if not root or not hum or hum.Health <= 0 or (ESP.TeamCheck and isTeamMate(model)) then
            hideModel(RenderCache[model])
            continue
        end

        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        local dist = rootPos.Z

        if not onScreen or dist > ESP.MaxDistance or dist <= 0 then
            hideModel(RenderCache[model])
            continue
        end

        local data = getOrCreateData(model)

        -- 1. Скелет (Bones)
        if ESP.Skeletons then
            local isR15 = hum.RigType == Enum.HumanoidRigType.R15
            local bonePairs = isR15 and R15_BONES or R6_BONES
            local needed = #bonePairs

            while #data.Lines < needed do
                if DRAWING_AVAILABLE then
                    local l = createDrawing("Line", { Thickness = ESP.SkeletonThickness, Visible = false })
                    table.insert(data.Lines, l)
                elseif ScreenGui then
                    local f = Instance.new("Frame")
                    f.AnchorPoint = Vector2.new(0.5, 0.5)
                    f.BorderSizePixel = 0
                    f.Visible = false
                    f.Parent = ScreenGui
                    table.insert(data.Lines, f)
                end
            end

            for i = needed + 1, #data.Lines do
                data.Lines[i].Visible = false
            end

            for i, pair in ipairs(bonePairs) do
                local pA = model:FindFirstChild(pair[1])
                local pB = model:FindFirstChild(pair[2])
                local line = data.Lines[i]

                if pA and pB and pA:IsA("BasePart") and pB:IsA("BasePart") then
                    local posA, visA = Camera:WorldToViewportPoint(pA.Position)
                    local posB, visB = Camera:WorldToViewportPoint(pB.Position)

                    if visA and visB then
                        updateBoneLine(line, posA, posB, ESP.SkeletonColor, ESP.SkeletonThickness)
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end
        else
            for _, l in ipairs(data.Lines) do
                l.Visible = false
            end
        end

        -- 2. 2D Bounding Box
        if ESP.Boxes then
            local cf, size = model:GetBoundingBox()
            local corners = {
                Vector3.new(cf.X + size.X/2, cf.Y + size.Y/2, cf.Z + size.Z/2),
                Vector3.new(cf.X - size.X/2, cf.Y + size.Y/2, cf.Z + size.Z/2),
                Vector3.new(cf.X + size.X/2, cf.Y - size.Y/2, cf.Z + size.Z/2),
                Vector3.new(cf.X - size.X/2, cf.Y - size.Y/2, cf.Z + size.Z/2),
                Vector3.new(cf.X + size.X/2, cf.Y + size.Y/2, cf.Z - size.Z/2),
                Vector3.new(cf.X - size.X/2, cf.Y + size.Y/2, cf.Z - size.Z/2),
                Vector3.new(cf.X + size.X/2, cf.Y - size.Y/2, cf.Z - size.Z/2),
                Vector3.new(cf.X - size.X/2, cf.Y - size.Y/2, cf.Z - size.Z/2),
            }

            local minX, minY = math.huge, math.huge
            local maxX, maxY = -math.huge, -math.huge
            local allInBounds = true

            for _, corner in ipairs(corners) do
                local p, visible = Camera:WorldToViewportPoint(corner)
                if not visible then
                    allInBounds = false
                    break
                end
                minX = math.min(minX, p.X)
                maxX = math.max(maxX, p.X)
                minY = math.min(minY, p.Y)
                maxY = math.max(maxY, p.Y)
            end

            if allInBounds and maxX > minX and maxY > minY then
                local w = maxX - minX
                local h = maxY - minY

                if DRAWING_AVAILABLE then
                    data.Box.Position = Vector2.new(minX, minY)
                    data.Box.Size = Vector2.new(w, h)
                    data.Box.Color = ESP.BoxColor
                    data.Box.Thickness = ESP.BoxThickness
                    data.Box.Visible = true
                else
                    data.Box.Position = UDim2.fromOffset(minX, minY)
                    data.Box.Size = UDim2.fromOffset(w, h)
                    data.Box.BorderColor3 = ESP.BoxColor
                    data.Box.Visible = true
                end

                -- Текст (Имя + Дистанция)
                if data.Text and (ESP.ShowNames or ESP.ShowDistance) then
                    local labelText = ""
                    if ESP.ShowNames then
                        labelText = model.Name
                    end
                    if ESP.ShowDistance then
                        labelText = labelText .. string.format(" [%dm]", math.floor(dist))
                    end

                    if DRAWING_AVAILABLE then
                        data.Text.Text = labelText
                        data.Text.Color = ESP.TextColor
                        data.Text.Position = Vector2.new(minX + w / 2, minY - ESP.TextSize - 3)
                        data.Text.Visible = true
                    else
                        data.Text.Text = labelText
                        data.Text.Position = UDim2.fromOffset(minX + w / 2 - 100, minY - ESP.TextSize - 6)
                        data.Text.Size = UDim2.fromOffset(200, 20)
                        data.Text.Visible = true
                    end
                elseif data.Text then
                    data.Text.Visible = false
                end
            else
                if data.Box then data.Box.Visible = false end
                if data.Text then data.Text.Visible = false end
            end
        else
            if data.Box then data.Box.Visible = false end
            if data.Text then data.Text.Visible = false end
        end
    end

    -- Очистка кэша исчезнувших моделей
    for model in pairs(RenderCache) do
        if not activeModels[model] or not model.Parent then
            cleanModelCache(model)
        end
    end
end

function ESP.Init()
    RunService:BindToRenderStep("ESP_Step", Enum.RenderPriority.Camera.Value + 1, ESP.Step)
    print("[ESP] Initialized: Boxes & Skeletons")
end

function ESP.Destroy()
    RunService:UnbindFromRenderStep("ESP_Step")
    for model in pairs(RenderCache) do
        cleanModelCache(model)
    end
    if ScreenGui then
        ScreenGui:Destroy()
    end
    print("[ESP] Destroyed")
end

-- Автозапуск
ESP.Init()

return ESP
