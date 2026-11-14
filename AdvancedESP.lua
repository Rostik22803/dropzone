-- language: Lua, file: AdvancedESP.lua, target: Roblox Luau (R6 / R15 / Custom Live Models)
-- Pro-grade Box & Detailed Multi-Joint Skeleton ESP with Corner Accents, Dynamic Health & Snaplines
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- Configuration Table
local ESP_CONFIG = {
    Enabled = true,
    TeamCheck = true,
    MaxDistance = 1500,

    -- Boxes
    BoxType = "Corner", -- "Full" | "Corner" | "3D"
    BoxColor = Color3.fromRGB(255, 60, 60),
    BoxTeamColor = Color3.fromRGB(60, 180, 255),
    BoxThickness = 1.5,
    BoxTransparency = 1,
    CornerRatio = 0.22, -- Length of corner accents

    -- Skeletons
    SkeletonEnabled = true,
    SkeletonColor = Color3.fromRGB(245, 245, 245),
    SkeletonThickness = 1.5,
    SkeletonTransparency = 0.85,
    DetailedFacialRays = true, -- Extended head / spine / collar / shoulder lines

    -- Health Bar & Text
    HealthBar = true,
    HealthBarSide = "Left", -- "Left" | "Right"
    HealthBarWidth = 2,
    ShowInfo = true, -- Name, Distance, Weapon/State
    InfoTextSize = 13,
    Font = 2, -- Drawing font

    -- Snapline / Tracers
    Tracers = false,
    TracerOrigin = "Bottom", -- "Bottom" | "Center" | "Mouse"
    TracerColor = Color3.fromRGB(255, 255, 255),
    TracerThickness = 1
}

local Entries = {}

-- Drawing helper
local function createDrawing(drawType, props)
    local obj = Drawing.new(drawType)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

-- R15 / R6 Joint Hierarchies for Anatomy Skeleton
local SkeletonRig = {
    R15 = {
        -- Head & Spine chain
        {"Head", "UpperTorso"},
        {"UpperTorso", "LowerTorso"},
        
        -- Left Arm chain
        {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"},
        {"LeftLowerArm", "LeftHand"},
        
        -- Right Arm chain
        {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"},
        {"RightLowerArm", "RightHand"},
        
        -- Left Leg chain
        {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"},
        {"LeftLowerLeg", "LeftFoot"},
        
        -- Right Leg chain
        {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"},
        {"RightLowerLeg", "RightFoot"},
    },
    R6 = {
        {"Head", "Torso"},
        {"Torso", "Left Arm"},
        {"Torso", "Right Arm"},
        {"Torso", "Left Leg"},
        {"Torso", "Right Leg"},
    }
}

-- Target entity resolver (Works for standard player characters and custom Live folder models)
local function getTargets()
    local targets = {}
    
    -- Check Live folder if game uses dedicated Live hierarchy
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
    
    -- Standard Players fallback
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

-- Check team affinity via Team or TeamId attribute
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

-- Entry class managing 2D screen primitives
local function createEntry(model)
    local entry = {
        Model = model,
        Drawings = {
            -- Box lines (8 lines for corner box, 4 for full box)
            Box = {},
            BoxOutline = {},
            
            -- Skeletons (pool of lines)
            Skeleton = {},
            
            -- Health bar
            HealthBarBg = createDrawing("Square", { Filled = true, Color = Color3.fromRGB(20, 20, 20), Transparency = 0.8, Visible = false }),
            HealthBarFill = createDrawing("Square", { Filled = true, Color = Color3.fromRGB(0, 255, 120), Transparency = 1, Visible = false }),
            
            -- Labels
            InfoText = createDrawing("Text", { Size = ESP_CONFIG.InfoTextSize, Font = ESP_CONFIG.Font, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255), Visible = false }),
            
            -- Tracer
            Tracer = createDrawing("Line", { Thickness = ESP_CONFIG.TracerThickness, Color = ESP_CONFIG.TracerColor, Visible = false })
        }
    }

    -- Allocate lines for corner box (4 corners * 2 segments = 8 lines)
    for i = 1, 8 do
        entry.Drawings.Box[i] = createDrawing("Line", { Thickness = ESP_CONFIG.BoxThickness, Visible = false })
        entry.Drawings.BoxOutline[i] = createDrawing("Line", { Thickness = ESP_CONFIG.BoxThickness + 1.5, Color = Color3.new(0, 0, 0), Visible = false })
    end

    -- Allocate line pool for skeleton connections
    for i = 1, 24 do
        entry.Drawings.Skeleton[i] = createDrawing("Line", { Thickness = ESP_CONFIG.SkeletonThickness, Color = ESP_CONFIG.SkeletonColor, Visible = false })
    end

    function entry:SetVisible(vis)
        for _, l in ipairs(self.Drawings.Box) do l.Visible = vis end
        for _, l in ipairs(self.Drawings.BoxOutline) do l.Visible = vis end
        for _, l in ipairs(self.Drawings.Skeleton) do l.Visible = vis end
        self.Drawings.HealthBarBg.Visible = vis
        self.Drawings.HealthBarFill.Visible = vis
        self.Drawings.InfoText.Visible = vis
        self.Drawings.Tracer.Visible = vis
    end

    function entry:Destroy()
        for _, list in pairs(self.Drawings) do
            if type(list) == "table" then
                for _, d in pairs(list) do
                    pcall(function() d:Remove() end)
                end
            else
                pcall(function() list:Remove() end)
            end
        end
    end

    return entry
end

-- Render loop
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

    -- Cleanup stale
    for model, entry in pairs(Entries) do
        if not validMap[model] or not model.Parent then
            entry:Destroy()
            Entries[model] = nil
        end
    end

    local camCFrame = Camera.CFrame
    local camPos = camCFrame.Position
    local viewportSize = Camera.ViewportSize

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

        -- Calculate tight bounding box in 2D
        local cframe, size = model:GetBoundingBox()
        local height = size.Y
        local width = math.max(size.X, size.Z) * 0.9

        local topWorld = cframe.Position + Vector3.new(0, height * 0.5 + 0.3, 0)
        local botWorld = cframe.Position - Vector3.new(0, height * 0.5 + 0.3, 0)

        local topScreen, topVisible = Camera:WorldToViewportPoint(topWorld)
        local botScreen, botVisible = Camera:WorldToViewportPoint(botWorld)

        if not topVisible and not botVisible then
            entry:SetVisible(false)
            continue
        end

        local boxHeight = math.abs(botScreen.Y - topScreen.Y)
        local boxWidth = boxHeight * 0.58
        local boxX = math.floor(rootScreen.X - boxWidth * 0.5)
        local boxY = math.floor(topScreen.Y)

        local boxCol = teammate and ESP_CONFIG.BoxTeamColor or ESP_CONFIG.BoxColor

        -------------------------------------------------------------
        -- 1. CORNER / BOUNDING BOX
        -------------------------------------------------------------
        local cornerLen = math.clamp(math.floor(boxWidth * ESP_CONFIG.CornerRatio), 5, 24)
        local bLines = entry.Drawings.Box
        local oLines = entry.Drawings.BoxOutline

        if ESP_CONFIG.BoxType == "Corner" then
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
                bLines[i].Transparency = ESP_CONFIG.BoxTransparency
                bLines[i].Visible = true

                -- Outline underneath for high contrast
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
        -- 2. DETAILED SKELETON
        -------------------------------------------------------------
        local isR15 = hum.RigType == Enum.HumanoidRigType.R15 or model:FindFirstChild("UpperTorso") ~= nil
        local rigPairs = isR15 and SkeletonRig.R15 or SkeletonRig.R6
        local lineIdx = 1

        if ESP_CONFIG.SkeletonEnabled then
            for _, pair in ipairs(rigPairs) do
                local partA = model:FindFirstChild(pair[1])
                local partB = model:FindFirstChild(pair[2])

                if partA and partB and partA:IsA("BasePart") and partB:IsA("BasePart") then
                    local pAScreen, aOnScreen = Camera:WorldToViewportPoint(partA.Position)
                    local pBScreen, bOnScreen = Camera:WorldToViewportPoint(partB.Position)

                    if aOnScreen or bOnScreen then
                        local skLine = entry.Drawings.Skeleton[lineIdx]
                        if skLine then
                            skLine.From = Vector2.new(pAScreen.X, pAScreen.Y)
                            skLine.To = Vector2.new(pBScreen.X, pBScreen.Y)
                            skLine.Color = ESP_CONFIG.SkeletonColor
                            skLine.Transparency = ESP_CONFIG.SkeletonTransparency
                            skLine.Thickness = ESP_CONFIG.SkeletonThickness
                            skLine.Visible = true
                            lineIdx = lineIdx + 1
                        end
                    end
                end
            end

            -- Optional head look-vector ray for facing direction
            local head = model:FindFirstChild("Head")
            if head and ESP_CONFIG.DetailedFacialRays then
                local headCenter = head.Position
                local lookPos = headCenter + (head.CFrame.LookVector * 1.3)
                local hScr, hVis = Camera:WorldToViewportPoint(headCenter)
                local lScr, lVis = Camera:WorldToViewportPoint(lookPos)
                if hVis or lVis then
                    local skLine = entry.Drawings.Skeleton[lineIdx]
                    if skLine then
                        skLine.From = Vector2.new(hScr.X, hScr.Y)
                        skLine.To = Vector2.new(lScr.X, lScr.Y)
                        skLine.Color = Color3.fromRGB(255, 220, 100)
                        skLine.Transparency = 0.9
                        skLine.Thickness = 1
                        skLine.Visible = true
                        lineIdx = lineIdx + 1
                    end
                end
            end
        end

        -- Hide leftover skeleton lines
        for i = lineIdx, #entry.Drawings.Skeleton do
            entry.Drawings.Skeleton[i].Visible = false
        end

        -------------------------------------------------------------
        -- 3. DYNAMIC HEALTH BAR (Color Lerp Green -> Orange -> Red)
        -------------------------------------------------------------
        if ESP_CONFIG.HealthBar then
            local hp = math.clamp(hum.Health, 0, hum.MaxHealth)
            local hpPercent = hp / math.max(hum.MaxHealth, 1)
            local barX = boxX - 6
            local barY = boxY
            local barH = boxHeight

            -- Background
            local bg = entry.Drawings.HealthBarBg
            bg.Position = Vector2.new(barX, barY - 1)
            bg.Size = Vector2.new(ESP_CONFIG.HealthBarWidth + 2, barH + 2)
            bg.Visible = true

            -- Filled Bar
            local fill = entry.Drawings.HealthBarFill
            local fillH = math.floor(barH * hpPercent)
            fill.Position = Vector2.new(barX + 1, barY + (barH - fillH))
            fill.Size = Vector2.new(ESP_CONFIG.HealthBarWidth, fillH)

            -- Interpolate color: Green (120/255) -> Yellow -> Red (0)
            local r = math.clamp((1 - hpPercent) * 2, 0, 1)
            local g = math.clamp(hpPercent * 2, 0, 1)
            fill.Color = Color3.new(r, g, 0)
            fill.Visible = true
        else
            entry.Drawings.HealthBarBg.Visible = false
            entry.Drawings.HealthBarFill.Visible = false
        end

        -------------------------------------------------------------
        -- 4. INFO TEXT (Name + Distance + State)
        -------------------------------------------------------------
        if ESP_CONFIG.ShowInfo then
            local info = entry.Drawings.InfoText
            local displayName = model:GetAttribute("DisplayName") or model.Name
            local stateTag = model:GetAttribute("Knocked") and " [KNOCKED]" or ""
            info.Text = string.format("%s%s\n[%dm]", displayName, stateTag, math.floor(dist))
            info.Position = Vector2.new(boxX + boxWidth * 0.5, boxY + boxHeight + 4)
            info.Visible = true
        else
            entry.Drawings.InfoText.Visible = false
        end

        -------------------------------------------------------------
        -- 5. TRACER SNAPLINE
        -------------------------------------------------------------
        if ESP_CONFIG.Tracers then
            local tr = entry.Drawings.Tracer
            tr.From = Vector2.new(viewportSize.X * 0.5, viewportSize.Y)
            tr.To = Vector2.new(rootScreen.X, botScreen.Y)
            tr.Visible = true
        else
            entry.Drawings.Tracer.Visible = false
        end
    end
end

RunService:BindToRenderStep("AdvancedESP_Vanta", Enum.RenderPriority.Camera.Value + 1, updateESP)

return {
    Config = ESP_CONFIG,
    SetEnabled = function(val) ESP_CONFIG.Enabled = val end,
    SetSkeleton = function(val) ESP_CONFIG.SkeletonEnabled = val end,
    SetBoxType = function(val) ESP_CONFIG.BoxType = val end,
    Destroy = function()
        RunService:UnbindFromRenderStep("AdvancedESP_Vanta")
        for _, e in pairs(Entries) do e:Destroy() end
        table.clear(Entries)
    end
}
