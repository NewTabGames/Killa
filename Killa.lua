local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local raw_getgenv = (typeof(getgenv) == "function" and getgenv) or nil
local function getExecEnv()
    if raw_getgenv then
        local ok, g = pcall(raw_getgenv)
        if ok and typeof(g) == "table" then return g end
    end
    return _G or {}
end

local aimbotEnabled = false
local aimbotAlwaysOn = false
local isAiming = false
local targetPartName = "Head"
local teamCheck = false
local includeNpcs = true
local visibleCheck = false
local fovRadius = 120
local showFov = true
local smoothness = 4
local movementPrediction = true
local predictionLead = 1.0
local movementCompEnabled = true

local speedHackEnabled = false
local customWalkSpeed = 18
local jumpHackEnabled = false
local customJumpPower = 50
local noclipEnabled = false
local noclipConn = nil

local espHighlightsEnabled = true
local espNametagsEnabled = true
local espShowDistance = true
local espTracersEnabled = false
local espTeamCheck = false
local espOnlyInFov = false
local espFillColor = Color3.fromRGB(255, 60, 60)
local espOutlineColor = Color3.fromRGB(255, 255, 255)
local espFillTransparency = 0.75
local espOutlineTransparency = 0

local crosshairEnabled = false
local crosshairStyle = "Classic Plus"
local crosshairColorName = "Cyan"
local crosshairColor = Color3.fromRGB(0, 212, 255)
local crosshairSize = 10
local crosshairThickness = 2
local crosshairGap = 4
local crosshairTransparency = 0
local crosshairDot = false
local crosshairDotShape = "Circle"
local crosshairDotSize = 4
local crosshairOutline = true
local crosshairChroma = false
local crosshairTargetReaction = true
local crosshairDynamicSpread = true
local crosshairSpin = false
local crosshairSpinSpeed = 90
local crosshairCurrentRotation = 0
local currentAimbotTarget = nil

local crosshairColorPresets = {
    ["Cyan"] = Color3.fromRGB(0, 212, 255),
    ["Green"] = Color3.fromRGB(50, 255, 100),
    ["Red"] = Color3.fromRGB(255, 60, 60),
    ["White"] = Color3.fromRGB(255, 255, 255),
    ["Yellow"] = Color3.fromRGB(255, 230, 0),
    ["Purple"] = Color3.fromRGB(200, 80, 255),
    ["Orange"] = Color3.fromRGB(255, 140, 0),
    ["Pink"] = Color3.fromRGB(255, 110, 180),
    ["Lime"] = Color3.fromRGB(160, 255, 40),
    ["Gold"] = Color3.fromRGB(255, 195, 40),
    ["Black"] = Color3.fromRGB(20, 20, 20),
}

local autoSaveEnabled = true
local menuToggleKey = Enum.KeyCode.RightShift
local isKeybinding = false
local bottomLabel = nil

local function updateBottomKeyLabel()
    if bottomLabel then
        bottomLabel.Text = "Press [" .. menuToggleKey.Name .. "] to Toggle Menu"
    end
end

local isMenuOpen = true
local isMinimized = false
local isScriptUnloaded = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HoodTestingKillaGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999

local guiParent = nil
pcall(function()
    if gethui then
        guiParent = gethui()
    elseif CoreGui then
        guiParent = CoreGui
    end
end)
if not guiParent and localPlayer then
    guiParent = localPlayer:FindFirstChildOfClass("PlayerGui")
end
screenGui.Parent = guiParent or CoreGui

local circleFrame = Instance.new("Frame")
circleFrame.Name = "FovCircle"
circleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
circleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
circleFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
circleFrame.BackgroundTransparency = 1
circleFrame.BorderSizePixel = 0
circleFrame.Visible = showFov
circleFrame.Parent = screenGui

local circleStroke = Instance.new("UIStroke")
circleStroke.Color = Color3.fromRGB(0, 180, 216)
circleStroke.Thickness = 1.5
circleStroke.Transparency = 0.2
circleStroke.Parent = circleFrame

local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent = circleFrame

local crosshairContainer = Instance.new("Frame")
crosshairContainer.Name = "CustomCrosshair"
crosshairContainer.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairContainer.Size = UDim2.new(0, 200, 0, 200)
crosshairContainer.BackgroundTransparency = 1
crosshairContainer.BorderSizePixel = 0
crosshairContainer.Visible = crosshairEnabled
crosshairContainer.Parent = screenGui

local mainCrosshairBundle = nil
local previewCrosshairBundle = nil

local function createCrosshairBundle(parentContainer)
    local bundle = {}
    bundle.container = parentContainer

    local rotator = Instance.new("Frame")
    rotator.Name = "Rotator"
    rotator.AnchorPoint = Vector2.new(0.5, 0.5)
    rotator.Position = UDim2.new(0.5, 0, 0.5, 0)
    rotator.Size = UDim2.new(1, 0, 1, 0)
    rotator.BackgroundTransparency = 1
    rotator.BorderSizePixel = 0
    rotator.Parent = parentContainer
    bundle.rotator = rotator

    local function makePart(name, parent)
        local part = Instance.new("Frame")
        part.Name = name
        part.BorderSizePixel = 0
        part.BackgroundColor3 = crosshairColor
        part.Parent = parent or rotator

        local stroke = Instance.new("UIStroke")
        stroke.Name = "Outline"
        stroke.Color = Color3.fromRGB(0, 0, 0)
        stroke.Thickness = 1
        stroke.Enabled = crosshairOutline
        stroke.Parent = part

        return part, stroke
    end

    local dot, dotStroke = makePart("Dot", rotator)
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot
    bundle.dot = dot
    bundle.dotStroke = dotStroke
    bundle.dotCorner = dotCorner

    local top, topStroke = makePart("Top", rotator)
    local bottom, bottomStroke = makePart("Bottom", rotator)
    local left, leftStroke = makePart("Left", rotator)
    local right, rightStroke = makePart("Right", rotator)
    bundle.top = top
    bundle.topStroke = topStroke
    bundle.bottom = bottom
    bundle.bottomStroke = bottomStroke
    bundle.left = left
    bundle.leftStroke = leftStroke
    bundle.right = right
    bundle.rightStroke = rightStroke

    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = 0
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    circle.Parent = rotator

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

    local circleStroke = Instance.new("UIStroke")
    circleStroke.Name = "CircleStroke"
    circleStroke.Color = crosshairColor
    circleStroke.Thickness = crosshairThickness
    circleStroke.Parent = circle
    bundle.circle = circle
    bundle.circleStroke = circleStroke

    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.AnchorPoint = Vector2.new(0.5, 0.5)
    box.Position = UDim2.new(0.5, 0, 0.5, 0)
    box.Parent = rotator

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Name = "BoxStroke"
    boxStroke.Color = crosshairColor
    boxStroke.Thickness = crosshairThickness
    boxStroke.Parent = box
    bundle.box = box
    bundle.boxStroke = boxStroke

    local chevLeft, chevLeftStroke = makePart("ChevLeft", rotator)
    local chevRight, chevRightStroke = makePart("ChevRight", rotator)
    bundle.chevLeft = chevLeft
    bundle.chevLeftStroke = chevLeftStroke
    bundle.chevRight = chevRight
    bundle.chevRightStroke = chevRightStroke

    local blade2Pivot = Instance.new("Frame")
    blade2Pivot.Name = "Blade2Pivot"
    blade2Pivot.AnchorPoint = Vector2.new(0.5, 0.5)
    blade2Pivot.Position = UDim2.new(0.5, 0, 0.5, 0)
    blade2Pivot.Size = UDim2.new(1, 0, 1, 0)
    blade2Pivot.BackgroundTransparency = 1
    blade2Pivot.BorderSizePixel = 0
    blade2Pivot.Rotation = 120
    blade2Pivot.Parent = rotator

    local blade2, blade2Stroke = makePart("Blade2", blade2Pivot)

    local blade3Pivot = Instance.new("Frame")
    blade3Pivot.Name = "Blade3Pivot"
    blade3Pivot.AnchorPoint = Vector2.new(0.5, 0.5)
    blade3Pivot.Position = UDim2.new(0.5, 0, 0.5, 0)
    blade3Pivot.Size = UDim2.new(1, 0, 1, 0)
    blade3Pivot.BackgroundTransparency = 1
    blade3Pivot.BorderSizePixel = 0
    blade3Pivot.Rotation = 240
    blade3Pivot.Parent = rotator

    local blade3, blade3Stroke = makePart("Blade3", blade3Pivot)

    bundle.blade2Pivot = blade2Pivot
    bundle.blade2 = blade2
    bundle.blade2Stroke = blade2Stroke
    bundle.blade3Pivot = blade3Pivot
    bundle.blade3 = blade3
    bundle.blade3Stroke = blade3Stroke

    return bundle
end

local function updateCrosshairBundle(bundle, colorOverride, gapOverride, rotAngleOverride)
    if not bundle or not bundle.container then return end

    local color = colorOverride or crosshairColorPresets[crosshairColorName] or crosshairColor
    local gap = gapOverride or crosshairGap
    local trans = math.clamp(crosshairTransparency / 100, 0, 0.95)

    local baseRot = 0
    if crosshairStyle == "X-Shape" or crosshairStyle == "Diamond" then
        baseRot = 45
    end
    local dynamicRot = crosshairSpin and (rotAngleOverride or crosshairCurrentRotation) or 0
    local finalRot = (baseRot + dynamicRot) % 360
    if bundle.rotator then
        bundle.rotator.Rotation = finalRot
    end

    local showDot = (crosshairStyle == "Dot" or crosshairStyle == "Crosshair + Dot" or crosshairStyle == "Circle + Dot" or crosshairDot)
    local isPlus = (crosshairStyle == "Classic Plus" or crosshairStyle == "Crosshair + Dot" or crosshairStyle == "Circle + Cross" or crosshairStyle == "X-Shape")
    local isT = (crosshairStyle == "T-Shape")
    local isCircle = (crosshairStyle == "Circle" or crosshairStyle == "Circle + Dot" or crosshairStyle == "Circle + Cross")
    local isBox = (crosshairStyle == "Box" or crosshairStyle == "Diamond")
    local isChevron = (crosshairStyle == "Chevron")
    local isTri = (crosshairStyle == "Tri-Blade")

    if bundle.dot then
        bundle.dot.Visible = showDot
        if showDot then
            local dSize = crosshairDotSize
            bundle.dot.Size = UDim2.new(0, dSize, 0, dSize)
            bundle.dot.AnchorPoint = Vector2.new(0.5, 0.5)
            bundle.dot.Position = UDim2.new(0.5, 0, 0.5, 0)
            bundle.dot.BackgroundColor3 = color
            bundle.dot.BackgroundTransparency = trans
            if bundle.dotCorner then
                bundle.dotCorner.CornerRadius = (crosshairDotShape == "Circle") and UDim.new(1, 0) or UDim.new(0, 0)
            end
            if bundle.dotStroke then
                bundle.dotStroke.Enabled = crosshairOutline
                bundle.dotStroke.Transparency = trans
            end
        end
    end

    if bundle.top then
        bundle.top.Visible = isPlus or isTri
        if bundle.top.Visible then
            bundle.top.Size = UDim2.new(0, crosshairThickness, 0, crosshairSize)
            bundle.top.AnchorPoint = Vector2.new(0.5, 1)
            bundle.top.Position = UDim2.new(0.5, 0, 0.5, -gap)
            bundle.top.BackgroundColor3 = color
            bundle.top.BackgroundTransparency = trans
            if bundle.topStroke then
                bundle.topStroke.Enabled = crosshairOutline
                bundle.topStroke.Transparency = trans
            end
        end
    end

    if bundle.bottom then
        bundle.bottom.Visible = isPlus or isT
        if bundle.bottom.Visible then
            bundle.bottom.Size = UDim2.new(0, crosshairThickness, 0, crosshairSize)
            bundle.bottom.AnchorPoint = Vector2.new(0.5, 0)
            bundle.bottom.Position = UDim2.new(0.5, 0, 0.5, gap)
            bundle.bottom.BackgroundColor3 = color
            bundle.bottom.BackgroundTransparency = trans
            if bundle.bottomStroke then
                bundle.bottomStroke.Enabled = crosshairOutline
                bundle.bottomStroke.Transparency = trans
            end
        end
    end

    if bundle.left then
        bundle.left.Visible = isPlus or isT
        if bundle.left.Visible then
            bundle.left.Size = UDim2.new(0, crosshairSize, 0, crosshairThickness)
            bundle.left.AnchorPoint = Vector2.new(1, 0.5)
            bundle.left.Position = UDim2.new(0.5, -gap, 0.5, 0)
            bundle.left.BackgroundColor3 = color
            bundle.left.BackgroundTransparency = trans
            if bundle.leftStroke then
                bundle.leftStroke.Enabled = crosshairOutline
                bundle.leftStroke.Transparency = trans
            end
        end
    end

    if bundle.right then
        bundle.right.Visible = isPlus or isT
        if bundle.right.Visible then
            bundle.right.Size = UDim2.new(0, crosshairSize, 0, crosshairThickness)
            bundle.right.AnchorPoint = Vector2.new(0, 0.5)
            bundle.right.Position = UDim2.new(0.5, gap, 0.5, 0)
            bundle.right.BackgroundColor3 = color
            bundle.right.BackgroundTransparency = trans
            if bundle.rightStroke then
                bundle.rightStroke.Enabled = crosshairOutline
                bundle.rightStroke.Transparency = trans
            end
        end
    end

    if bundle.circle then
        bundle.circle.Visible = isCircle
        if isCircle then
            local diam = (crosshairSize + gap) * 2
            bundle.circle.Size = UDim2.new(0, diam, 0, diam)
            if bundle.circleStroke then
                bundle.circleStroke.Color = color
                bundle.circleStroke.Thickness = crosshairThickness
                bundle.circleStroke.Transparency = trans
            end
        end
    end

    if bundle.box then
        bundle.box.Visible = isBox
        if isBox then
            local side = (crosshairSize + gap) * 2
            bundle.box.Size = UDim2.new(0, side, 0, side)
            if bundle.boxStroke then
                bundle.boxStroke.Color = color
                bundle.boxStroke.Thickness = crosshairThickness
                bundle.boxStroke.Transparency = trans
            end
        end
    end

    if bundle.chevLeft and bundle.chevRight then
        bundle.chevLeft.Visible = isChevron
        bundle.chevRight.Visible = isChevron
        if isChevron then
            bundle.chevLeft.Size = UDim2.new(0, crosshairSize, 0, crosshairThickness)
            bundle.chevLeft.AnchorPoint = Vector2.new(1, 0.5)
            bundle.chevLeft.Position = UDim2.new(0.5, 0, 0.5, -gap)
            bundle.chevLeft.Rotation = 35
            bundle.chevLeft.BackgroundColor3 = color
            bundle.chevLeft.BackgroundTransparency = trans
            if bundle.chevLeftStroke then
                bundle.chevLeftStroke.Enabled = crosshairOutline
                bundle.chevLeftStroke.Transparency = trans
            end

            bundle.chevRight.Size = UDim2.new(0, crosshairSize, 0, crosshairThickness)
            bundle.chevRight.AnchorPoint = Vector2.new(0, 0.5)
            bundle.chevRight.Position = UDim2.new(0.5, 0, 0.5, -gap)
            bundle.chevRight.Rotation = -35
            bundle.chevRight.BackgroundColor3 = color
            bundle.chevRight.BackgroundTransparency = trans
            if bundle.chevRightStroke then
                bundle.chevRightStroke.Enabled = crosshairOutline
                bundle.chevRightStroke.Transparency = trans
            end
        end
    end

    if bundle.blade2 and bundle.blade3 then
        bundle.blade2.Visible = isTri
        bundle.blade3.Visible = isTri
        if isTri then
            bundle.blade2.Size = UDim2.new(0, crosshairThickness, 0, crosshairSize)
            bundle.blade2.AnchorPoint = Vector2.new(0.5, 1)
            bundle.blade2.Position = UDim2.new(0.5, 0, 0.5, -gap)
            bundle.blade2.BackgroundColor3 = color
            bundle.blade2.BackgroundTransparency = trans
            if bundle.blade2Stroke then
                bundle.blade2Stroke.Enabled = crosshairOutline
                bundle.blade2Stroke.Transparency = trans
            end

            bundle.blade3.Size = UDim2.new(0, crosshairThickness, 0, crosshairSize)
            bundle.blade3.AnchorPoint = Vector2.new(0.5, 1)
            bundle.blade3.Position = UDim2.new(0.5, 0, 0.5, -gap)
            bundle.blade3.BackgroundColor3 = color
            bundle.blade3.BackgroundTransparency = trans
            if bundle.blade3Stroke then
                bundle.blade3Stroke.Enabled = crosshairOutline
                bundle.blade3Stroke.Transparency = trans
            end
        end
    end
end

local function updateCrosshair()
    if not crosshairContainer then return end
    crosshairContainer.Visible = crosshairEnabled

    local color = crosshairColorPresets[crosshairColorName] or crosshairColor
    crosshairColor = color

    local spinAngle = crosshairSpin and crosshairCurrentRotation or 0

    if mainCrosshairBundle then
        updateCrosshairBundle(mainCrosshairBundle, color, crosshairGap, spinAngle)
    end
    if previewCrosshairBundle then
        updateCrosshairBundle(previewCrosshairBundle, color, crosshairGap, spinAngle)
    end
end

mainCrosshairBundle = createCrosshairBundle(crosshairContainer)
updateCrosshair()

local function isTeammate(otherPlayer)
    if not otherPlayer or otherPlayer == localPlayer then
        return true
    end

    local myTeam = localPlayer.Team
    local theirTeam = otherPlayer.Team

    if myTeam then
        local tName = string.lower(myTeam.Name)
        if string.find(tName, "ffa") or string.find(tName, "free for all") then
            return false
        end
    end
    if theirTeam then
        local tName = string.lower(theirTeam.Name)
        if string.find(tName, "ffa") or string.find(tName, "free for all") then
            return false
        end
    end

    if not myTeam and not theirTeam then
        return false
    end

    if myTeam and theirTeam then
        return myTeam == theirTeam
    end

    if localPlayer.TeamColor and otherPlayer.TeamColor then
        local defaultGrey = BrickColor.new("Medium stone grey")
        if localPlayer.TeamColor ~= defaultGrey or otherPlayer.TeamColor ~= defaultGrey then
            return localPlayer.TeamColor == otherPlayer.TeamColor
        end
    end

    if localPlayer.Neutral or otherPlayer.Neutral then
        return false
    end

    local myChar = localPlayer.Character
    local theirChar = otherPlayer.Character

    local myTeamVal = localPlayer:FindFirstChild("Team") or (myChar and myChar:FindFirstChild("Team"))
    local theirTeamVal = otherPlayer:FindFirstChild("Team") or (theirChar and theirChar:FindFirstChild("Team"))
    if myTeamVal and theirTeamVal then
        if myTeamVal:IsA("ValueBase") and theirTeamVal:IsA("ValueBase") then
            return myTeamVal.Value == theirTeamVal.Value
        end
    end

    local myLeaderstats = localPlayer:FindFirstChild("leaderstats")
    local theirLeaderstats = otherPlayer:FindFirstChild("leaderstats")
    if myLeaderstats and theirLeaderstats then
        local myLeadTeam = myLeaderstats:FindFirstChild("Team")
        local theirLeadTeam = theirLeaderstats:FindFirstChild("Team")
        if myLeadTeam and theirLeadTeam and myLeadTeam:IsA("ValueBase") and theirLeadTeam:IsA("ValueBase") then
            return myLeadTeam.Value == theirLeadTeam.Value
        end
    end

    local myTeamAttr = localPlayer:GetAttribute("Team") or (myChar and myChar:GetAttribute("Team"))
    local theirTeamAttr = otherPlayer:GetAttribute("Team") or (theirChar and theirChar:GetAttribute("Team"))
    if myTeamAttr ~= nil and theirTeamAttr ~= nil then
        return myTeamAttr == theirTeamAttr
    end

    return false
end

local function isPartVisible(part, character)
    if not part then return false end
    local origin = camera.CFrame.Position
    local destination = part.Position
    local direction = destination - origin

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local ignoreList = { camera }
    if localPlayer.Character then
        table.insert(ignoreList, localPlayer.Character)
    end
    raycastParams.FilterDescendantsInstances = ignoreList
    raycastParams.IgnoreWater = true

    local maxAttempts = 5
    for _ = 1, maxAttempts do
        local result = workspace:Raycast(origin, direction, raycastParams)
        if not result then
            return true
        end
        local hitInstance = result.Instance
        if hitInstance:IsDescendantOf(character) then
            return true
        end
        if hitInstance.Transparency > 0.9 or not hitInstance.CanCollide then
            table.insert(ignoreList, hitInstance)
            raycastParams.FilterDescendantsInstances = ignoreList
        else
            return false
        end
    end

    return false
end

local highlightFolder = nil
local function getHighlightFolder()
    if highlightFolder and highlightFolder.Parent then
        return highlightFolder
    end
    highlightFolder = Instance.new("Folder")
    highlightFolder.Name = "HTK_HighlightFolder"
    pcall(function()
        highlightFolder.Parent = workspace.CurrentCamera or workspace
    end)
    return highlightFolder
end

local activeHighlights = {}
local activeNametags = {}
local activeTracers = {}
local tracerFolder = nil

local function getOrCreateHighlight(character)
    if not character or not character.Parent then return nil end
    local hl = activeHighlights[character]
    local folder = getHighlightFolder()
    if not hl or not hl.Parent then
        if hl then
            pcall(function() hl:Destroy() end)
        end
        hl = Instance.new("Highlight")
        hl.Name = "HTK_Highlight"
        hl.FillTransparency = espFillTransparency
        hl.FillColor = espFillColor
        hl.OutlineColor = espOutlineColor
        hl.OutlineTransparency = espOutlineTransparency
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = character
        hl.Enabled = true
        pcall(function()
            hl.Parent = folder
        end)
        activeHighlights[character] = hl
    else
        hl.Adornee = character
        hl.Enabled = true
        hl.FillTransparency = espFillTransparency
        hl.FillColor = espFillColor
        hl.OutlineColor = espOutlineColor
        hl.OutlineTransparency = espOutlineTransparency
    end
    return hl
end

local function clearHighlights()
    for char, hl in pairs(activeHighlights) do
        if hl then
            pcall(function() hl:Destroy() end)
        end
    end
    activeHighlights = {}
end

local function getOrCreateNametag(character, displayName)
    local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character.PrimaryPart
    if not head then return nil end

    local tag = activeNametags[character]
    if not tag or not tag.Parent then
        if tag then
            pcall(function() tag:Destroy() end)
        end
        local bbg = Instance.new("BillboardGui")
        bbg.Name = "HTK_Nametag"
        bbg.Adornee = head
        bbg.Size = UDim2.new(0, 160, 0, 26)
        bbg.StudsOffset = Vector3.new(0, 2.2, 0)
        bbg.AlwaysOnTop = true
        bbg.ResetOnSpawn = false
        bbg.Enabled = true

        local label = Instance.new("TextLabel")
        label.Name = "Text"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextStrokeTransparency = 0.2
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.TextSize = 12
        label.Font = Enum.Font.GothamBold
        label.Parent = bbg

        pcall(function()
            bbg.Parent = screenGui
        end)
        activeNametags[character] = bbg
        tag = bbg
    else
        tag.Adornee = head
        tag.Enabled = true
    end
    return tag
end

local function clearNametags()
    for char, tag in pairs(activeNametags) do
        if tag then
            pcall(function() tag:Destroy() end)
        end
    end
    activeNametags = {}
end

local function getTracerFolder()
    if tracerFolder and tracerFolder.Parent then
        return tracerFolder
    end
    tracerFolder = Instance.new("Folder")
    tracerFolder.Name = "HTK_TracerFolder"
    pcall(function()
        tracerFolder.Parent = screenGui
    end)
    return tracerFolder
end

local function getOrCreateTracer(character)
    local line = activeTracers[character]
    if not line or not line.Parent then
        if line then
            pcall(function() line:Destroy() end)
        end
        local f = Instance.new("Frame")
        f.Name = "Tracer"
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.BorderSizePixel = 0
        f.BackgroundColor3 = espFillColor or Color3.fromRGB(255, 60, 60)
        f.BackgroundTransparency = 0.2
        f.ZIndex = 1
        f.Visible = false
        pcall(function()
            f.Parent = getTracerFolder()
        end)
        activeTracers[character] = f
        line = f
    end
    return line
end

local function clearTracers()
    for char, line in pairs(activeTracers) do
        if line then
            pcall(function() line:Destroy() end)
        end
    end
    activeTracers = {}
end

local cachedTargetEntities = nil
local lastTargetEntityScan = 0

local function getAllTargetEntities()
    local now = tick()
    if cachedTargetEntities and (now - lastTargetEntityScan < 0.035) then
        return cachedTargetEntities
    end
    lastTargetEntityScan = now

    local list = {}
    local seenChars = {}
    if localPlayer.Character then
        seenChars[localPlayer.Character] = true
    end

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= localPlayer then
            local character = otherPlayer.Character
            if character and character.Parent then
                seenChars[character] = true
                table.insert(list, {
                    player = otherPlayer,
                    character = character,
                    name = otherPlayer.DisplayName or otherPlayer.Name,
                    isNpc = false,
                })
            end
        end
    end

    if includeNpcs then
        local function checkModel(model)
            if model and model:IsA("Model") and not seenChars[model] then
                local hum = model:FindFirstChildOfClass("Humanoid")
                local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Head") or model.PrimaryPart
                if hum and root and hum.Health > 0 then
                    seenChars[model] = true
                    table.insert(list, {
                        player = nil,
                        character = model,
                        name = model.Name,
                        isNpc = true,
                    })
                end
            end
        end

        for _, child in ipairs(workspace:GetChildren()) do
            checkModel(child)
        end

        local commonFolders = { "Dummies", "Bots", "NPCs", "Zombies", "Enemies", "Targets", "Spawns", "Map" }
        for _, folderName in ipairs(commonFolders) do
            local folder = workspace:FindFirstChild(folderName)
            if folder then
                for _, child in ipairs(folder:GetChildren()) do
                    checkModel(child)
                end
            end
        end
    end

    cachedTargetEntities = list
    return list
end

local function getEligiblePlayers(onlyFov)
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local list = {}
    local entities = getAllTargetEntities()

    for _, entry in ipairs(entities) do
        local eligible = false
        if entry.isNpc then
            eligible = true
        else
            eligible = (not espTeamCheck) or (not isTeammate(entry.player))
        end

        if eligible then
            local character = entry.character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or character.PrimaryPart
            local isAlive = (not humanoid) or (humanoid.Health > 0)

            if rootPart and isAlive then
                if onlyFov then
                    local screenPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                    if onScreen then
                        local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                        if dist2D <= fovRadius then
                            table.insert(list, {
                                player = entry.player,
                                character = character,
                                name = entry.name,
                                part = rootPart,
                                humanoid = humanoid,
                            })
                        end
                    end
                else
                    table.insert(list, {
                        player = entry.player,
                        character = character,
                        name = entry.name,
                        part = rootPart,
                        humanoid = humanoid,
                    })
                end
            end
        end
    end
    return list
end

local function resolveTargetPart(character)
    if not character then return nil end
    if targetPartName == "Legs" then
        return character:FindFirstChild("LeftUpperLeg")
            or character:FindFirstChild("RightUpperLeg")
            or character:FindFirstChild("Left Leg")
            or character:FindFirstChild("Right Leg")
            or character:FindFirstChild("LowerTorso")
            or character:FindFirstChild("HumanoidRootPart")
            or character.PrimaryPart
    elseif targetPartName == "UpperTorso" or targetPartName == "Torso" then
        return character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("LowerTorso")
            or character:FindFirstChild("HumanoidRootPart")
            or character.PrimaryPart
    end
    return character:FindFirstChild(targetPartName)
        or character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
end

local cachedMuzzleVelocity = 900
local lastCheckedTool = nil

local function updateCurrentWeaponStats()
    local char = localPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool == lastCheckedTool then return end
    lastCheckedTool = tool
    if not tool then
        cachedMuzzleVelocity = 900
        return
    end

    local acs = tool:FindFirstChild("ACS_Settings")
    if acs and acs:IsA("ModuleScript") then
        local ok, mod = pcall(function() return require(acs) end)
        if ok and typeof(mod) == "table" then
            if typeof(mod.MuzzleVelocity) == "number" and mod.MuzzleVelocity > 0 then
                cachedMuzzleVelocity = mod.MuzzleVelocity
            else
                cachedMuzzleVelocity = 900
            end
            return
        end
    end
    cachedMuzzleVelocity = 900
end

local lastPingCheck = 0
local cachedPing = 0.05

local function getNetworkPing()
    local now = tick()
    if now - lastPingCheck > 0.5 then
        lastPingCheck = now
        pcall(function()
            local stats = game:GetService("Stats")
            local net = stats and stats:FindFirstChild("Network")
            local ssi = net and net:FindFirstChild("ServerStatsItem")
            local dataPing = ssi and ssi:FindFirstChild("Data Ping")
            if dataPing then
                cachedPing = math.clamp(dataPing:GetValue() / 1000, 0.015, 0.3)
            end
        end)
    end
    return cachedPing
end

local function getPlayersInFov()
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local inFov = {}
    local entities = getAllTargetEntities()

    for _, entry in ipairs(entities) do
        local eligible = false
        if entry.isNpc then
            eligible = true
        else
            eligible = (not teamCheck) or (not isTeammate(entry.player))
        end

        if eligible then
            local character = entry.character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local targetPart = resolveTargetPart(character)
            local isAlive = (not humanoid) or (humanoid.Health > 0)
            if targetPart and isAlive then
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist2D = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist2D <= fovRadius then
                        table.insert(inFov, {
                            player = entry.player,
                            character = character,
                            name = entry.name,
                            part = targetPart,
                            dist2D = dist2D,
                        })
                    end
                end
            end
        end
    end

    return inFov
end

local function getTargetPlayer(playersInFov)
    local mousePos = UserInputService:GetMouseLocation()
    local bestTarget = nil
    local bestScore = math.huge

    for _, entry in ipairs(playersInFov) do
        local allowed = true
        if visibleCheck then
            allowed = isPartVisible(entry.part, entry.character)
        end

        if allowed then
            local screenPos = camera:WorldToScreenPoint(entry.part.Position)
            local score = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            if score < bestScore then
                bestScore = score
                bestTarget = entry
            end
        end
    end

    return bestTarget
end

local modalFreer = Instance.new("TextButton")
modalFreer.Name = "ModalFreer"
modalFreer.Size = UDim2.new(0, 0, 0, 0)
modalFreer.Position = UDim2.new(0, 0, 0, 0)
modalFreer.BackgroundTransparency = 1
modalFreer.Text = ""
modalFreer.Modal = true
modalFreer.Visible = isMenuOpen
modalFreer.Parent = screenGui

local function ensureMouseFreedIfThirdPerson()
    if isScriptUnloaded or isMenuOpen then return end
    local cam = workspace.CurrentCamera or camera
    if not cam then return end
    local char = localPlayer and localPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then
        local camDist = (cam.CFrame.Position - cam.Focus.Position).Magnitude
        if camDist > 1.0 and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
                pcall(function()
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                end)
            end
            if not UserInputService.MouseIconEnabled then
                pcall(function()
                    UserInputService.MouseIconEnabled = true
                end)
            end
        end
    end
end

local mainFrame = nil
local function setMenuOpen(open)
    isMenuOpen = open
    if mainFrame then
        mainFrame.Visible = isMenuOpen
    end
    if modalFreer then
        modalFreer.Visible = isMenuOpen
    end
    if isMenuOpen then
        pcall(function()
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end)
    else
        task.defer(ensureMouseFreedIfThirdPerson)
    end
end

mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 410, 0, 430)
mainFrame.Position = UDim2.new(0, 60, 0, 60)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

setMenuOpen(true)

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 45, 58)
mainStroke.Thickness = 1.2
mainStroke.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 10)
titleFix.Position = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -90, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "HOOD TESTING  <font color='#00b4d8'><b>KILLA</b></font>"
titleLabel.RichText = true
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Name = "MinBtn"
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.AnchorPoint = Vector2.new(1, 0.5)
minBtn.Position = UDim2.new(1, -38, 0.5, 0)
minBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 48)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
minBtn.TextSize = 16
minBtn.Font = Enum.Font.GothamBold
minBtn.AutoButtonColor = true
minBtn.Parent = titleBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.Position = UDim2.new(1, -6, 0.5, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 25, 25)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.AutoButtonColor = true
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

local contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, 0, 1, -38)
contentFrame.Position = UDim2.new(0, 0, 0, 38)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -20, 0, 32)
tabBar.Position = UDim2.new(0, 10, 0, 8)
tabBar.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
tabBar.BorderSizePixel = 0
tabBar.Parent = contentFrame

local tabBarCorner = Instance.new("UICorner")
tabBarCorner.CornerRadius = UDim.new(0, 8)
tabBarCorner.Parent = tabBar

local function createTabButton(id, text, index)
    local btn = Instance.new("TextButton")
    btn.Name = id:sub(1,1):upper() .. id:sub(2) .. "TabBtn"
    btn.Size = UDim2.new(1/6, -3, 1, -4)
    btn.Position = UDim2.new((index - 1) / 6, 2, 0, 2)
    btn.BackgroundColor3 = (index == 1) and Color3.fromRGB(0, 180, 216) or Color3.fromRGB(28, 28, 36)
    btn.Text = text
    btn.TextColor3 = (index == 1) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
    btn.TextSize = 10.5
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = tabBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    return btn
end

local aimTabBtn = createTabButton("aim", "Aimbot", 1)
local espTabBtn = createTabButton("esp", "ESP", 2)
local mobTabBtn = createTabButton("mob", "Mobility", 3)
local utilTabBtn = createTabButton("util", "Utility", 4)
local crossTabBtn = createTabButton("cross", "Crosshair", 5)
local configTabBtn = createTabButton("config", "Config", 6)

local pagesFrame = Instance.new("Frame")
pagesFrame.Name = "Pages"
pagesFrame.Size = UDim2.new(1, -20, 1, -78)
pagesFrame.Position = UDim2.new(0, 10, 0, 48)
pagesFrame.BackgroundTransparency = 1
pagesFrame.Parent = contentFrame

local function createScrollPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 80)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Parent = pagesFrame

    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 6)
    list.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingRight = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent = page

    return page
end

local aimPage = createScrollPage("AimPage")
local espPage = createScrollPage("EspPage")
local mobPage = createScrollPage("MobilityPage")
local utilPage = createScrollPage("UtilityPage")
local crossPage = createScrollPage("CrosshairPage")
local configPage = createScrollPage("ConfigPage")
espPage.Visible = false
mobPage.Visible = false
utilPage.Visible = false
crossPage.Visible = false
configPage.Visible = false

local tabButtonMap = {
    aim = aimTabBtn,
    esp = espTabBtn,
    mob = mobTabBtn,
    util = utilTabBtn,
    cross = crossTabBtn,
    config = configTabBtn,
}

local tabPageMap = {
    aim = aimPage,
    esp = espPage,
    mob = mobPage,
    util = utilPage,
    cross = crossPage,
    config = configPage,
}

local function selectTab(tabName)
    for id, btn in pairs(tabButtonMap) do
        local isActive = (id == tabName)
        btn.BackgroundColor3 = isActive and Color3.fromRGB(0, 180, 216) or Color3.fromRGB(28, 28, 36)
        btn.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
    end

    for id, page in pairs(tabPageMap) do
        page.Visible = (id == tabName)
    end
end

aimTabBtn.MouseButton1Click:Connect(function()
    selectTab("aim")
end)

espTabBtn.MouseButton1Click:Connect(function()
    selectTab("esp")
end)

mobTabBtn.MouseButton1Click:Connect(function()
    selectTab("mob")
end)

utilTabBtn.MouseButton1Click:Connect(function()
    selectTab("util")
end)

crossTabBtn.MouseButton1Click:Connect(function()
    selectTab("cross")
end)

configTabBtn.MouseButton1Click:Connect(function()
    selectTab("config")
end)

minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    contentFrame.Visible = not isMinimized
    mainFrame.Size = isMinimized and UDim2.new(0, 410, 0, 38) or UDim2.new(0, 410, 0, 430)
    minBtn.Text = isMinimized and "+" or "-"
end)

local function createSectionHeader(parent, titleText)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundTransparency = 1
    header.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = string.upper(titleText)
    label.TextColor3 = Color3.fromRGB(0, 180, 216)
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = header

    return header
end

local function createToggle(parent, labelText, defaultValue, callback)
    local state = defaultValue
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 20)
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, -8, 0.5, 0)
    btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 216) or Color3.fromRGB(45, 45, 58)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = row

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(1, 0)
    btnCorner.Parent = btn

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = state and UDim2.new(1, -9, 0.5, 0) or UDim2.new(0, 9, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = btn

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 216) or Color3.fromRGB(45, 45, 58)
        knob.Position = state and UDim2.new(1, -9, 0.5, 0) or UDim2.new(0, 9, 0.5, 0)
        callback(state)
    end)

    return {
        Set = function(val)
            state = val
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 216) or Color3.fromRGB(45, 45, 58)
            knob.Position = state and UDim2.new(1, -9, 0.5, 0) or UDim2.new(0, 9, 0.5, 0)
            callback(state)
        end,
    }
end

local function createSlider(parent, labelText, minVal, maxVal, defaultVal, callback)
    local curVal = defaultVal
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 48)
    container.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    container.BorderSizePixel = 0
    container.Parent = parent

    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = UDim.new(0, 6)
    containerCorner.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 0, 22)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0.3, -10, 0, 22)
    valLabel.Position = UDim2.new(0.7, 0, 0, 4)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(defaultVal)
    valLabel.TextColor3 = Color3.fromRGB(0, 180, 216)
    valLabel.TextSize = 13
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    valLabel.Parent = container

    local bar = Instance.new("TextButton")
    bar.Size = UDim2.new(1, -20, 0, 6)
    bar.Position = UDim2.new(0, 10, 0, 32)
    bar.BackgroundColor3 = Color3.fromRGB(45, 45, 58)
    bar.Text = ""
    bar.AutoButtonColor = false
    bar.Parent = container

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar

    local fill = Instance.new("Frame")
    local pct = math.clamp((curVal - minVal) / (maxVal - minVal), 0, 1)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 180, 216)
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local sliding = false
    local function updateFromInput(input)
        local posX = math.clamp(input.Position.X - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
        local ratio = posX / bar.AbsoluteSize.X
        curVal = math.floor(minVal + (maxVal - minVal) * ratio)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        valLabel.Text = tostring(curVal)
        callback(curVal)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            updateFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromInput(input)
        end
    end)

    return {
        Set = function(val)
            curVal = math.clamp(val, minVal, maxVal)
            local r = (curVal - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(r, 0, 1, 0)
            valLabel.Text = tostring(curVal)
            callback(curVal)
        end,
    }
end

local function createSelector(parent, labelText, options, defaultIndex, callback)
    local idx = defaultIndex or 1
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.48, 0, 0, 22)
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, -8, 0.5, 0)
    btn.BackgroundColor3 = Color3.fromRGB(36, 36, 48)
    btn.Text = options[idx]
    btn.TextColor3 = Color3.fromRGB(0, 180, 216)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = true
    btn.Parent = row

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        idx = (idx % #options) + 1
        btn.Text = options[idx]
        callback(options[idx])
    end)

    return {
        Set = function(newOpt)
            for i, opt in ipairs(options) do
                if opt == newOpt then
                    idx = i
                    btn.Text = opt
                    callback(opt)
                    break
                end
            end
        end,
    }
end

local function createKeybind(parent, labelText, defaultKeyCode, callback)
    local currentKey = defaultKeyCode or Enum.KeyCode.RightShift
    if typeof(currentKey) == "string" then
        local ok, code = pcall(function() return Enum.KeyCode[currentKey] end)
        if ok and code then
            currentKey = code
        else
            currentKey = Enum.KeyCode.RightShift
        end
    end

    local isListening = false
    local listenConn = nil

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    row.BorderSizePixel = 0
    row.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 6)
    rowCorner.Parent = row

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(220, 220, 230)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.48, 0, 0, 22)
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, -8, 0.5, 0)
    btn.BackgroundColor3 = Color3.fromRGB(36, 36, 48)
    btn.Text = "[" .. currentKey.Name .. "]"
    btn.TextColor3 = Color3.fromRGB(0, 180, 216)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = true
    btn.Parent = row

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(60, 60, 75)
    btnStroke.Thickness = 1
    btnStroke.Parent = btn

    local function stopListening()
        if listenConn then
            listenConn:Disconnect()
            listenConn = nil
        end
        isListening = false
        task.delay(0.05, function()
            isKeybinding = false
        end)
        pcall(function()
            btn.Text = "[" .. currentKey.Name .. "]"
            btn.TextColor3 = Color3.fromRGB(0, 180, 216)
            btnStroke.Color = Color3.fromRGB(60, 60, 75)
        end)
    end

    btn.MouseButton1Click:Connect(function()
        if isListening then
            stopListening()
            return
        end

        isListening = true
        isKeybinding = true
        btn.Text = "[...]"
        btn.TextColor3 = Color3.fromRGB(255, 180, 50)
        btnStroke.Color = Color3.fromRGB(255, 180, 50)

        if listenConn then
            listenConn:Disconnect()
            listenConn = nil
        end

        listenConn = UserInputService.InputBegan:Connect(function(input, gpe)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local pressedKey = input.KeyCode
                if pressedKey == Enum.KeyCode.Unknown then return end

                if pressedKey == Enum.KeyCode.Escape then
                    stopListening()
                    return
                end

                currentKey = pressedKey
                stopListening()
                callback(currentKey)
            end
        end)
    end)

    return {
        Set = function(newKey)
            if typeof(newKey) == "string" then
                local ok, code = pcall(function() return Enum.KeyCode[newKey] end)
                if ok and code then
                    newKey = code
                else
                    return
                end
            end
            if typeof(newKey) == "EnumItem" then
                currentKey = newKey
                if isListening then
                    stopListening()
                else
                    btn.Text = "[" .. currentKey.Name .. "]"
                    btn.TextColor3 = Color3.fromRGB(0, 180, 216)
                    btnStroke.Color = Color3.fromRGB(60, 60, 75)
                end
                callback(currentKey)
            end
        end,
        GetKey = function()
            return currentKey
        end,
        Cancel = function()
            if isListening then
                stopListening()
            end
        end,
    }
end

local function createButton(parent, labelText, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(36, 36, 48)
    btn.Text = labelText
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = true
    btn.Parent = row

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(60, 60, 75)
    btnStroke.Thickness = 1
    btnStroke.Parent = btn

    btn.MouseButton1Click:Connect(function()
        callback()
    end)

    return btn
end

local CONFIG_FOLDER = "HoodTestingKilla"
local CONFIG_FILE = "HoodTestingKilla/settings.json"
local uiControls = {}
local configStatusLabel = nil
local saveDebounce = false

local function saveConfig()
    local data = {
        aimbot = {
            enabled = aimbotEnabled,
            alwaysOn = aimbotAlwaysOn,
            targetPart = targetPartName,
            teamCheck = teamCheck,
            includeNpcs = includeNpcs,
            visibleCheck = visibleCheck,
            smoothness = smoothness,
            showFov = showFov,
            fovRadius = fovRadius,
            movementPrediction = movementPrediction,
            predictionLead = predictionLead,
            movementComp = movementCompEnabled,
        },
        mobility = {
            speedHack = speedHackEnabled,
            customWalkSpeed = customWalkSpeed,
            jumpHack = jumpHackEnabled,
            customJumpPower = customJumpPower,
            noclip = noclipEnabled,
        },
        esp = {
            highlights = espHighlightsEnabled,
            nametags = espNametagsEnabled,
            showDistance = espShowDistance,
            tracers = espTracersEnabled,
            teamCheck = espTeamCheck,
            includeNpcs = includeNpcs,
            onlyInFov = espOnlyInFov,
        },
        crosshair = {
            enabled = crosshairEnabled,
            style = crosshairStyle,
            color = crosshairColorName,
            size = crosshairSize,
            thickness = crosshairThickness,
            gap = crosshairGap,
            transparency = crosshairTransparency,
            dot = crosshairDot,
            dotShape = crosshairDotShape,
            dotSize = crosshairDotSize,
            outline = crosshairOutline,
            chroma = crosshairChroma,
            targetReaction = crosshairTargetReaction,
            dynamicSpread = crosshairDynamicSpread,
            spin = crosshairSpin,
            spinSpeed = crosshairSpinSpeed,
        },
        menuKey = menuToggleKey.Name,
        autoSave = autoSaveEnabled,
    }

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)

    if not ok or not encoded then
        if configStatusLabel then
            configStatusLabel.Text = "Status: JSON encode failed"
            configStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        return false
    end

    local saveOk = pcall(function()
        if makefolder and isfolder and not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end
        if writefile then
            writefile(CONFIG_FILE, encoded)
        end
    end)

    if saveOk then
        if configStatusLabel then
            configStatusLabel.Text = "Status: Settings Saved (" .. os.date("%X") .. ")"
            configStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
        end
        return true
    else
        if configStatusLabel then
            configStatusLabel.Text = "Status: Write failed (Executor unsupported)"
            configStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        return false
    end
end

local function triggerAutoSave()
    if not autoSaveEnabled then return end
    if isScriptUnloaded then return end
    if saveDebounce then return end
    saveDebounce = true
    task.delay(0.25, function()
        saveDebounce = false
        if isScriptUnloaded or not autoSaveEnabled then return end
        pcall(saveConfig)
    end)
end

local function loadConfig()
    local hasFile = false
    pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            hasFile = true
        end
    end)

    if not hasFile then
        if configStatusLabel then
            configStatusLabel.Text = "Status: No saved config found"
            configStatusLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
        end
        return false
    end

    local content = nil
    local readOk = pcall(function()
        if readfile then
            content = readfile(CONFIG_FILE)
        end
    end)

    if not readOk or not content or content == "" then
        if configStatusLabel then
            configStatusLabel.Text = "Status: Read failed"
            configStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        return false
    end

    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(content)
    end)

    if not decodeOk or typeof(data) ~= "table" then
        if configStatusLabel then
            configStatusLabel.Text = "Status: Invalid JSON format"
            configStatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        return false
    end

    if data.aimbot and typeof(data.aimbot) == "table" then
        if data.aimbot.enabled ~= nil and uiControls.aimbotEnabled then uiControls.aimbotEnabled.Set(data.aimbot.enabled) end
        if data.aimbot.alwaysOn ~= nil and uiControls.aimbotAlwaysOn then uiControls.aimbotAlwaysOn.Set(data.aimbot.alwaysOn) end
        if data.aimbot.targetPart and uiControls.targetPart then uiControls.targetPart.Set(data.aimbot.targetPart) end
        if data.aimbot.teamCheck ~= nil and uiControls.teamCheck then uiControls.teamCheck.Set(data.aimbot.teamCheck) end
        if data.aimbot.includeNpcs ~= nil and uiControls.includeNpcsAim then uiControls.includeNpcsAim.Set(data.aimbot.includeNpcs) end
        if data.aimbot.visibleCheck ~= nil and uiControls.visibleCheck then uiControls.visibleCheck.Set(data.aimbot.visibleCheck) end
        if data.aimbot.smoothness and uiControls.smoothness then uiControls.smoothness.Set(data.aimbot.smoothness) end
        if data.aimbot.showFov ~= nil and uiControls.showFov then uiControls.showFov.Set(data.aimbot.showFov) end
        if data.aimbot.fovRadius and uiControls.fovRadius then uiControls.fovRadius.Set(data.aimbot.fovRadius) end
        if data.aimbot.movementPrediction ~= nil and uiControls.movementPrediction then uiControls.movementPrediction.Set(data.aimbot.movementPrediction) end
        if data.aimbot.predictionLead ~= nil and uiControls.predictionLead then uiControls.predictionLead.Set(math.floor(data.aimbot.predictionLead * 100)) end
        if data.aimbot.movementComp ~= nil and uiControls.movementComp then uiControls.movementComp.Set(data.aimbot.movementComp) end
    end

    local mobData = (data.mobility and typeof(data.mobility) == "table" and data.mobility) or (data.mods and typeof(data.mods) == "table" and data.mods)
    if mobData then
        if mobData.speedHack ~= nil and uiControls.speedHack then uiControls.speedHack.Set(mobData.speedHack) end
        if mobData.customWalkSpeed and uiControls.customWalkSpeed then uiControls.customWalkSpeed.Set(mobData.customWalkSpeed) end
        if mobData.jumpHack ~= nil and uiControls.jumpHack then uiControls.jumpHack.Set(mobData.jumpHack) end
        if mobData.customJumpPower and uiControls.customJumpPower then uiControls.customJumpPower.Set(mobData.customJumpPower) end
        if mobData.noclip ~= nil and uiControls.noclip then uiControls.noclip.Set(mobData.noclip) end
    end

    if data.esp and typeof(data.esp) == "table" then
        if data.esp.highlights ~= nil and uiControls.espHighlights then uiControls.espHighlights.Set(data.esp.highlights) end
        if data.esp.nametags ~= nil and uiControls.espNametags then uiControls.espNametags.Set(data.esp.nametags) end
        if data.esp.showDistance ~= nil and uiControls.espShowDistance then uiControls.espShowDistance.Set(data.esp.showDistance) end
        if data.esp.tracers ~= nil and uiControls.espTracers then uiControls.espTracers.Set(data.esp.tracers) end
        if data.esp.teamCheck ~= nil and uiControls.espTeamCheck then uiControls.espTeamCheck.Set(data.esp.teamCheck) end
        if data.esp.includeNpcs ~= nil and uiControls.includeNpcsEsp then uiControls.includeNpcsEsp.Set(data.esp.includeNpcs) end
        if data.esp.onlyInFov ~= nil and uiControls.espOnlyInFov then uiControls.espOnlyInFov.Set(data.esp.onlyInFov) end
    end

    if data.crosshair and typeof(data.crosshair) == "table" then
        if data.crosshair.enabled ~= nil and uiControls.crosshairEnabled then uiControls.crosshairEnabled.Set(data.crosshair.enabled) end
        if data.crosshair.style and uiControls.crosshairStyle then uiControls.crosshairStyle.Set(data.crosshair.style) end
        if data.crosshair.color and uiControls.crosshairColor then uiControls.crosshairColor.Set(data.crosshair.color) end
        if data.crosshair.size and uiControls.crosshairSize then uiControls.crosshairSize.Set(data.crosshair.size) end
        if data.crosshair.thickness and uiControls.crosshairThickness then uiControls.crosshairThickness.Set(data.crosshair.thickness) end
        if data.crosshair.gap ~= nil and uiControls.crosshairGap then uiControls.crosshairGap.Set(data.crosshair.gap) end
        if data.crosshair.transparency ~= nil and uiControls.crosshairTransparency then uiControls.crosshairTransparency.Set(data.crosshair.transparency) end
        if data.crosshair.dot ~= nil and uiControls.crosshairDot then uiControls.crosshairDot.Set(data.crosshair.dot) end
        if data.crosshair.dotShape and uiControls.crosshairDotShape then uiControls.crosshairDotShape.Set(data.crosshair.dotShape) end
        if data.crosshair.dotSize and uiControls.crosshairDotSize then uiControls.crosshairDotSize.Set(data.crosshair.dotSize) end
        if data.crosshair.outline ~= nil and uiControls.crosshairOutline then uiControls.crosshairOutline.Set(data.crosshair.outline) end
        if data.crosshair.chroma ~= nil and uiControls.crosshairChroma then uiControls.crosshairChroma.Set(data.crosshair.chroma) end
        if data.crosshair.targetReaction ~= nil and uiControls.crosshairTargetReaction then uiControls.crosshairTargetReaction.Set(data.crosshair.targetReaction) end
        if data.crosshair.dynamicSpread ~= nil and uiControls.crosshairDynamicSpread then uiControls.crosshairDynamicSpread.Set(data.crosshair.dynamicSpread) end
        if data.crosshair.spin ~= nil and uiControls.crosshairSpin then uiControls.crosshairSpin.Set(data.crosshair.spin) end
        if data.crosshair.spinSpeed and uiControls.crosshairSpinSpeed then uiControls.crosshairSpinSpeed.Set(data.crosshair.spinSpeed) end
    end

    if data.menuKey and uiControls.menuKey then
        uiControls.menuKey.Set(data.menuKey)
    end

    if data.autoSave ~= nil and uiControls.autoSave then
        uiControls.autoSave.Set(data.autoSave)
    end

    if configStatusLabel then
        configStatusLabel.Text = "Status: Settings Loaded (" .. os.date("%X") .. ")"
        configStatusLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
    end
    return true
end

local function resetDefaults()
    if uiControls.aimbotEnabled then uiControls.aimbotEnabled.Set(false) end
    if uiControls.aimbotAlwaysOn then uiControls.aimbotAlwaysOn.Set(false) end
    if uiControls.targetPart then uiControls.targetPart.Set("Head") end
    if uiControls.teamCheck then uiControls.teamCheck.Set(false) end
    if uiControls.includeNpcsAim then uiControls.includeNpcsAim.Set(true) end
    if uiControls.visibleCheck then uiControls.visibleCheck.Set(false) end
    if uiControls.smoothness then uiControls.smoothness.Set(4) end
    if uiControls.showFov then uiControls.showFov.Set(true) end
    if uiControls.fovRadius then uiControls.fovRadius.Set(120) end
    if uiControls.movementPrediction then uiControls.movementPrediction.Set(true) end
    if uiControls.predictionLead then uiControls.predictionLead.Set(100) end
    if uiControls.movementComp then uiControls.movementComp.Set(true) end
    if uiControls.speedHack then uiControls.speedHack.Set(false) end
    if uiControls.customWalkSpeed then uiControls.customWalkSpeed.Set(18) end
    if uiControls.jumpHack then uiControls.jumpHack.Set(false) end
    if uiControls.customJumpPower then uiControls.customJumpPower.Set(50) end
    if uiControls.noclip then uiControls.noclip.Set(false) end

    if uiControls.espHighlights then uiControls.espHighlights.Set(true) end
    if uiControls.espNametags then uiControls.espNametags.Set(true) end
    if uiControls.espShowDistance then uiControls.espShowDistance.Set(true) end
    if uiControls.espTracers then uiControls.espTracers.Set(false) end
    if uiControls.espTeamCheck then uiControls.espTeamCheck.Set(false) end
    if uiControls.includeNpcsEsp then uiControls.includeNpcsEsp.Set(true) end
    if uiControls.espOnlyInFov then uiControls.espOnlyInFov.Set(false) end

    if uiControls.crosshairEnabled then uiControls.crosshairEnabled.Set(false) end
    if uiControls.crosshairStyle then uiControls.crosshairStyle.Set("Classic Plus") end
    if uiControls.crosshairColor then uiControls.crosshairColor.Set("Cyan") end
    if uiControls.crosshairSize then uiControls.crosshairSize.Set(10) end
    if uiControls.crosshairThickness then uiControls.crosshairThickness.Set(2) end
    if uiControls.crosshairGap then uiControls.crosshairGap.Set(4) end
    if uiControls.crosshairTransparency then uiControls.crosshairTransparency.Set(0) end
    if uiControls.crosshairDot then uiControls.crosshairDot.Set(false) end
    if uiControls.crosshairDotShape then uiControls.crosshairDotShape.Set("Circle") end
    if uiControls.crosshairDotSize then uiControls.crosshairDotSize.Set(4) end
    if uiControls.crosshairOutline then uiControls.crosshairOutline.Set(true) end
    if uiControls.crosshairChroma then uiControls.crosshairChroma.Set(false) end
    if uiControls.crosshairTargetReaction then uiControls.crosshairTargetReaction.Set(true) end
    if uiControls.crosshairDynamicSpread then uiControls.crosshairDynamicSpread.Set(true) end
    if uiControls.crosshairSpin then uiControls.crosshairSpin.Set(false) end
    if uiControls.crosshairSpinSpeed then uiControls.crosshairSpinSpeed.Set(90) end

    if uiControls.menuKey then uiControls.menuKey.Set("RightShift") end
    if uiControls.autoSave then uiControls.autoSave.Set(true) end

    saveConfig()

    if configStatusLabel then
        configStatusLabel.Text = "Status: Reset to Defaults"
        configStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    end
end

createSectionHeader(aimPage, "Aimbot Settings")

uiControls.aimbotEnabled = createToggle(aimPage, "Enable Aimbot", aimbotEnabled, function(val)
    aimbotEnabled = val
    triggerAutoSave()
end)

uiControls.aimbotAlwaysOn = createToggle(aimPage, "Always On (Disable Hold Key)", aimbotAlwaysOn, function(val)
    aimbotAlwaysOn = val
    triggerAutoSave()
end)

uiControls.targetPart = createSelector(aimPage, "Target Part", { "Head", "UpperTorso", "HumanoidRootPart", "Legs" }, 1, function(selected)
    targetPartName = selected
    triggerAutoSave()
end)

uiControls.teamCheck = createToggle(aimPage, "Team Check", teamCheck, function(val)
    teamCheck = val
    triggerAutoSave()
end)

uiControls.includeNpcsAim = createToggle(aimPage, "Include NPCs / Dummies", includeNpcs, function(val)
    includeNpcs = val
    if uiControls.includeNpcsEsp then
        uiControls.includeNpcsEsp.Set(val)
    end
    triggerAutoSave()
end)

uiControls.visibleCheck = createToggle(aimPage, "Visible Check (Walls)", visibleCheck, function(val)
    visibleCheck = val
    triggerAutoSave()
end)

uiControls.smoothness = createSlider(aimPage, "Smoothness", 1, 15, smoothness, function(val)
    smoothness = val
    triggerAutoSave()
end)

uiControls.showFov = createToggle(aimPage, "Show FOV Circle", showFov, function(val)
    showFov = val
    if circleFrame then
        circleFrame.Visible = val
    end
    triggerAutoSave()
end)

uiControls.fovRadius = createSlider(aimPage, "FOV Radius", 30, 300, fovRadius, function(val)
    fovRadius = val
    if circleFrame then
        circleFrame.Size = UDim2.new(0, val * 2, 0, val * 2)
    end
    triggerAutoSave()
end)

uiControls.movementPrediction = createToggle(aimPage, "Movement Prediction", movementPrediction, function(val)
    movementPrediction = val
    triggerAutoSave()
end)

uiControls.predictionLead = createSlider(aimPage, "Prediction Strength (%)", 1, 250, math.floor(predictionLead * 100), function(val)
    predictionLead = val / 100
    triggerAutoSave()
end)

uiControls.movementComp = createToggle(aimPage, "Movement Compensation", movementCompEnabled, function(val)
    movementCompEnabled = val
    triggerAutoSave()
end)

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local AMMO_CRATE_POS = Vector3.new(140.4, 144.0, -290.0)
local VEST_CRATE_POS = Vector3.new(134.1, 144.0, -295.0)

local function isNearCrate(targetPos, maxDist)
    local char = localPlayer and localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    return (root.Position - targetPos).Magnitude <= (maxDist or 18)
end

local function pressFKey(duration)
    if not isNearCrate(AMMO_CRATE_POS, 18) and not isNearCrate(VEST_CRATE_POS, 18) then
        return
    end

    duration = duration or 0.2
    pcall(function()
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        end
    end)
    pcall(function()
        if keypress then keypress(0x46) end
    end)

    task.wait(duration)

    pcall(function()
        if VirtualInputManager then
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end
    end)
    pcall(function()
        if keyrelease then keyrelease(0x46) end
    end)
end

local function getAmmoPrompts()
    local prompts = {}
    local seen = {}

    local function addPrompt(p)
        if p and p:IsA("ProximityPrompt") and not seen[p] then
            local part = p.Parent
            local pos = (part and part:IsA("BasePart") and part.Position) or AMMO_CRATE_POS
            if (pos - AMMO_CRATE_POS).Magnitude <= 18 then
                seen[p] = true
                table.insert(prompts, p)
            end
        end
    end

    local nueva = workspace:FindFirstChild("NUEVA MAPA")
    if nueva then
        local aa = nueva:FindFirstChild("ARMOR & AMMO")
        if aa then
            for _, desc in ipairs(aa:GetDescendants()) do
                if desc:IsA("ProximityPrompt") then
                    local name = string.upper(desc.Parent and desc.Parent.Name or "")
                    local act = string.upper(tostring(desc.ActionText))
                    local obj = string.upper(tostring(desc.ObjectText))
                    if string.find(name, "AMMO") or string.find(act, "AMMO") or string.find(obj, "AMMO") or string.find(act, "TAKE") then
                        addPrompt(desc)
                    end
                end
            end
        end
    end

    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") and not seen[desc] then
            local part = desc.Parent
            if part and part:IsA("BasePart") and (part.Position - AMMO_CRATE_POS).Magnitude <= 18 then
                addPrompt(desc)
            end
        end
    end

    return prompts
end

local function getVestPrompt()
    local nueva = workspace:FindFirstChild("NUEVA MAPA")
    if nueva then
        local aa = nueva:FindFirstChild("ARMOR & AMMO")
        local vp = aa and aa:FindFirstChild("VEST PROX")
        local giver = vp and vp:FindFirstChild("Giver")
        local prompt = giver and giver:FindFirstChildOfClass("ProximityPrompt")
        if prompt then return prompt end
    end
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") then
            local part = desc.Parent
            if part and part:IsA("BasePart") and (part.Position - VEST_CRATE_POS).Magnitude <= 18 then
                return desc
            end
        end
    end
    return nil
end

local function optimizeUtilityPrompts()
    local prompts = getAmmoPrompts()
    for _, p in ipairs(prompts) do
        pcall(function()
            p.RequiresLineOfSight = false
            p.HoldDuration = 0
            p.MaxActivationDistance = 45
        end)
    end
    local vp = getVestPrompt()
    if vp then
        pcall(function()
            vp.RequiresLineOfSight = false
            vp.HoldDuration = 0
            vp.MaxActivationDistance = 45
        end)
    end
end

local function triggerProximityPrompt(prompt)
    if not prompt or not prompt.Parent then return false end

    local part = prompt.Parent
    if not part:IsA("BasePart") then return false end
    local isAmmo = (part.Position - AMMO_CRATE_POS).Magnitude <= 18
    local isVest = (part.Position - VEST_CRATE_POS).Magnitude <= 18
    if not isAmmo and not isVest then
        return false
    end

    pcall(function()
        prompt.RequiresLineOfSight = false
        prompt.HoldDuration = 0
    end)

    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        end
    end)

    local cratePos = isAmmo and AMMO_CRATE_POS or VEST_CRATE_POS
    if isNearCrate(cratePos, 18) then
        local key = prompt.KeyboardKeyCode or Enum.KeyCode.F
        pcall(function()
            if VirtualInputManager then
                VirtualInputManager:SendKeyEvent(true, key, false, game)
            end
        end)
        pcall(function()
            if keypress then keypress(0x46) end
        end)

        task.wait(0.2)

        pcall(function()
            if VirtualInputManager then
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            end
        end)
        pcall(function()
            if keyrelease then keyrelease(0x46) end
        end)

        pcall(function()
            if prompt.InputHoldBegin and prompt.InputHoldEnd then
                prompt:InputHoldBegin()
                task.wait(0.04)
                prompt:InputHoldEnd()
            end
        end)
    end

    return true
end

local WEAPON_PROFILES = {
    { pattern = "double", max = 2, keys = { "shells", "shell", "ammo" } },
    { pattern = "barrel", max = 2, keys = { "shells", "shell", "ammo" } },
    { pattern = "db", max = 2, keys = { "shells", "shell", "ammo" } },
    { pattern = "revolver", max = 6, keys = { "ammo", "bullets", "mag" } },
    { pattern = "tactical", max = 8, keys = { "shells", "shell", "ammo" } },
    { pattern = "shotgun", max = 5, keys = { "shells", "shell", "ammo" } },
    { pattern = "rpg", max = 1, keys = { "rockets", "rocket", "ammo" } },
    { pattern = "rocket", max = 1, keys = { "rockets", "rocket", "ammo" } },
    { pattern = "glock", max = 15, keys = { "ammo", "bullets", "mag" } },
    { pattern = "silencer", max = 12, keys = { "ammo", "bullets", "mag" } },
    { pattern = "smg", max = 30, keys = { "ammo", "bullets", "mag" } },
    { pattern = "p90", max = 50, keys = { "ammo", "bullets", "mag" } },
    { pattern = "rifle", max = 30, keys = { "ammo", "bullets", "mag" } },
    { pattern = "ar", max = 30, keys = { "ammo", "bullets", "mag" } },
    { pattern = "ak", max = 30, keys = { "ammo", "bullets", "mag" } },
    { pattern = "lmg", max = 100, keys = { "ammo", "bullets", "mag" } },
    { pattern = "drum", max = 50, keys = { "ammo", "bullets", "mag" } },
    { pattern = "flamethrower", max = 100, keys = { "fuel", "gas", "ammo" } },
}

local function isGuiElementActive(gui)
    if not gui or not gui:IsA("GuiObject") then return false end
    if not gui.Visible or gui.TextTransparency >= 0.99 then return false end
    local p = gui.Parent
    while p and p:IsA("GuiObject") do
        if not p.Visible then return false end
        p = p.Parent
    end
    if p and p:IsA("LayerCollector") then
        if not p.Enabled then return false end
    end
    return true
end

local function isBlacklistedLabel(combined)
    for _, bad in ipairs({
        "health", "hp", "armor", "shield", "cash", "money", "%$", "coin", "wallet", "bank",
        "bounty", "stamina", "energy", "hunger", "food", "player", "leaderboard", "playerlist",
        "score", "kill", "death", "kd", "ping", "fps", "level", "xp", "exp", "clock", "time",
        "chat", "menu", "shop", "store", "dialog", "prompt", "badge", "profile", "crosshair"
    }) do
        if string.find(combined, bad) then
            return true
        end
    end
    return false
end

local function isWeaponAmmoDepleted()
    local char = localPlayer and localPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool then return false end

    local toolName = string.lower(tool.Name)
    local isGun = false
    local curAmmo = nil
    local storedAmmo = nil
    local detectedCapacity = nil
    local textEmptyDetected = false

    local prioritizedKeys = {}
    for _, profile in ipairs(WEAPON_PROFILES) do
        if string.find(toolName, profile.pattern) then
            isGun = true
            detectedCapacity = profile.max
            for _, k in ipairs(profile.keys) do
                table.insert(prioritizedKeys, k)
            end
            break
        end
    end

    for _, k in ipairs({
        "ammo", "currentammo", "ammoingun", "mag", "magazine", "clip", "clips",
        "bullets", "bullet", "shells", "shell", "buckshot", "rockets", "rocket",
        "loaded", "shots", "round", "rounds", "fuel", "count", "remaining"
    }) do
        table.insert(prioritizedKeys, k)
    end

    if tool:FindFirstChild("ACS_Settings") or tool:FindFirstChild("ACS_Animations")
        or tool:FindFirstChild("GunClient") or tool:FindFirstChild("Client") or tool:FindFirstChild("GunScript")
        or tool:FindFirstChild("WeaponServer") or tool:FindFirstChild("GunServer")
        or tool:FindFirstChild("Setting") or tool:FindFirstChild("Settings") then
        isGun = true
    end

    local acsModule = tool:FindFirstChild("ACS_Settings")
    if acsModule and acsModule:IsA("ModuleScript") then
        local ok, mod = pcall(function() return require(acsModule) end)
        if ok and typeof(mod) == "table" and typeof(mod.Ammo) == "number" then
            detectedCapacity = mod.Ammo
            isGun = true
        end
    end

    for _, desc in ipairs(tool:GetDescendants()) do
        local n = string.lower(desc.Name)
        if not string.find(n, "max") and not string.find(n, "stored") and not string.find(n, "reserve") then
            for _, key in ipairs(prioritizedKeys) do
                if n == key then
                    if desc:IsA("IntValue") or desc:IsA("NumberValue") then
                        curAmmo = desc.Value
                        isGun = true
                        break
                    elseif desc:IsA("StringValue") then
                        local cStr, rStr = string.match(desc.Value, "(%d+)%s*[/|\\]%s*(%d+)")
                        if cStr then
                            curAmmo = tonumber(cStr)
                            storedAmmo = tonumber(rStr)
                            isGun = true
                            break
                        else
                            local num = tonumber(string.match(desc.Value, "%d+"))
                            if num then
                                curAmmo = num
                                isGun = true
                                break
                            end
                        end
                    end
                end
            end
            if curAmmo ~= nil then break end
        end
    end

    if storedAmmo == nil then
        for _, desc in ipairs(tool:GetDescendants()) do
            local n = string.lower(desc.Name)
            if string.find(n, "stored") or string.find(n, "reserve") or string.find(n, "backup") or string.find(n, "totalammo") then
                if desc:IsA("IntValue") or desc:IsA("NumberValue") then
                    storedAmmo = desc.Value
                    isGun = true
                    break
                end
            end
        end
    end

    if curAmmo == nil then
        for _, key in ipairs(prioritizedKeys) do
            local a = tool:GetAttribute(key) or tool:GetAttribute(string.upper(string.sub(key, 1, 1)) .. string.sub(key, 2))
            if typeof(a) == "number" then
                curAmmo = a
                isGun = true
                break
            elseif typeof(a) == "string" then
                local num = tonumber(string.match(a, "%d+"))
                if num then
                    curAmmo = num
                    isGun = true
                    break
                end
            end
        end
    end

    if storedAmmo == nil then
        local dataFolder = localPlayer:FindFirstChild("DataFolder")
        local inv = dataFolder and (dataFolder:FindFirstChild("Inventory") or dataFolder:FindFirstChild("Information"))
        if inv then
            for _, item in ipairs(inv:GetChildren()) do
                local iName = string.lower(item.Name)
                if string.find(iName, "ammo") or string.find(iName, "shell") or string.find(iName, "bullet") or string.find(iName, "rocket") or string.find(iName, "gauge") then
                    for _, kw in ipairs({ "revolver", "shotgun", "barrel", "rifle", "smg", "glock", "silencer", "rpg", "lmg", "ak" }) do
                        if string.find(toolName, kw) and string.find(iName, kw) then
                            if item:IsA("IntValue") or item:IsA("NumberValue") then
                                storedAmmo = item.Value
                                isGun = true
                            end
                            break
                        end
                    end
                    if storedAmmo ~= nil then break end
                end
            end
        end
    end

    local pgui = localPlayer:FindFirstChildOfClass("PlayerGui")
    if pgui then
        for _, desc in ipairs(pgui:GetDescendants()) do
            if desc:IsA("TextLabel") and isGuiElementActive(desc) then
                local labelName = string.lower(desc.Name)
                local parentName = desc.Parent and string.lower(desc.Parent.Name) or ""
                local grandName = desc.Parent and desc.Parent.Parent and string.lower(desc.Parent.Parent.Name) or ""
                local combined = labelName .. " " .. parentName .. " " .. grandName

                if not isBlacklistedLabel(combined) then
                    local text = desc.Text
                    local textUpper = string.upper(text)

                    if string.find(textUpper, "EMPTY") or string.find(textUpper, "OUT OF AMMO")
                        or string.find(textUpper, "NO AMMO") or string.find(textUpper, "RELOAD") then
                        textEmptyDetected = true
                        isGun = true
                        break
                    end

                    local isAmmoContainer = string.find(labelName, "ammo") or string.find(labelName, "mag") or string.find(labelName, "clip")
                        or string.find(labelName, "bullet") or string.find(labelName, "shell") or string.find(labelName, "rocket")
                        or string.find(parentName, "ammo") or string.find(parentName, "gun") or string.find(parentName, "weapon")
                        or string.find(parentName, "acs") or string.find(parentName, "bullet") or string.find(parentName, "shell")
                        or string.find(grandName, "ammo") or string.find(grandName, "weapon")

                    if isAmmoContainer then
                        local cStr, rStr = string.match(text, "(%d+)%s*[/|\\]%s*(%d+)")
                        if cStr and rStr then
                            curAmmo = tonumber(cStr)
                            storedAmmo = tonumber(rStr)
                            isGun = true
                            break
                        end

                        local bracketed = string.match(text, "%[%s*(%d+)%s*%]")
                        if bracketed then
                            curAmmo = tonumber(bracketed)
                            isGun = true
                            break
                        end

                        local numWithWord = string.match(text, "(%d+)%s*[A-Za-z]+")
                        if numWithWord then
                            curAmmo = tonumber(numWithWord)
                            isGun = true
                            break
                        end

                        local single = string.match(text, "^%s*(%d+)%s*$")
                        if single then
                            curAmmo = tonumber(single)
                            isGun = true
                            break
                        end
                    elseif curAmmo == nil then
                        local cStr, rStr = string.match(text, "(%d+)%s*[/|\\]%s*(%d+)")
                        if cStr and rStr then
                            local cNum = tonumber(cStr)
                            local rNum = tonumber(rStr)
                            if (detectedCapacity and rNum == detectedCapacity) or (rNum and rNum <= 100) then
                                curAmmo = cNum
                                storedAmmo = rNum
                                isGun = true
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    if not isGun then
        return false
    end

    if textEmptyDetected then
        return true
    end

    if curAmmo ~= nil and curAmmo <= 0 then
        return true
    end

    if storedAmmo ~= nil and storedAmmo <= 0 and (curAmmo == nil or curAmmo <= 0) then
        return true
    end

    return false
end

local isAmmoRefilling = false
local function refillAmmo()
    if isAmmoRefilling or isScriptUnloaded then return end
    isAmmoRefilling = true

    task.spawn(function()
        local char = localPlayer and localPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            isAmmoRefilling = false
            return
        end

        local prompts = getAmmoPrompts()
        local bestPrompt = prompts[1]
        local promptPos = AMMO_CRATE_POS

        if bestPrompt and bestPrompt.Parent and bestPrompt.Parent:IsA("BasePart") then
            promptPos = bestPrompt.Parent.Position
        end

        local dist = (promptPos - root.Position).Magnitude

        if dist > 15 then
            local oldCF = root.CFrame
            local standPos = promptPos + Vector3.new(0, 1.5, 2)
            local targetCF = CFrame.lookAt(standPos, promptPos)

            root.CFrame = targetCF
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
            task.wait(0.25)

            if isNearCrate(AMMO_CRATE_POS, 18) then
                local promptOk = false
                if bestPrompt then
                    promptOk = triggerProximityPrompt(bestPrompt)
                end
                if not promptOk then
                    pressFKey(0.25)
                end
                task.wait(0.15)
            end

            if root and root.Parent then
                root.CFrame = oldCF
                pcall(function()
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        else
            local promptOk = false
            if bestPrompt then
                promptOk = triggerProximityPrompt(bestPrompt)
            end
            if not promptOk then
                pressFKey(0.25)
            end
        end

        task.wait(1.0)
        isAmmoRefilling = false
    end)
end

local isVestBlinking = false
local function equipVest()
    if isVestBlinking or isScriptUnloaded then return end
    isVestBlinking = true

    task.spawn(function()
        local char = localPlayer and localPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            isVestBlinking = false
            return
        end

        local prompt = getVestPrompt()
        local promptPos = VEST_CRATE_POS
        if prompt and prompt.Parent and prompt.Parent:IsA("BasePart") then
            promptPos = prompt.Parent.Position
        end

        local dist = (promptPos - root.Position).Magnitude

        if dist > 15 then
            local oldCF = root.CFrame
            local standPos = promptPos + Vector3.new(0, 1.5, 2)
            local targetCF = CFrame.lookAt(standPos, promptPos)

            root.CFrame = targetCF
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
            task.wait(0.25)

            if isNearCrate(VEST_CRATE_POS, 18) then
                local promptOk = false
                if prompt then
                    promptOk = triggerProximityPrompt(prompt)
                end
                if not promptOk then
                    pressFKey(0.25)
                end
                task.wait(0.15)
            end

            if root and root.Parent then
                root.CFrame = oldCF
                pcall(function()
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        else
            local promptOk = false
            if prompt then
                promptOk = triggerProximityPrompt(prompt)
            end
            if not promptOk then
                pressFKey(0.25)
            end
        end

        task.wait(1.0)
        isVestBlinking = false
    end)
end

local function updateNoclip()
    if noclipEnabled then
        if not noclipConn then
            noclipConn = RunService.Stepped:Connect(function()
                if not noclipEnabled or isScriptUnloaded then return end
                local char = localPlayer.Character
                if char then
                    for _, child in ipairs(char:GetChildren()) do
                        if child:IsA("BasePart") and child.CanCollide then
                            child.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end
        pcall(function()
            local char = localPlayer.Character
            if char then
                for _, child in ipairs(char:GetChildren()) do
                    if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
                        child.CanCollide = true
                    end
                end
            end
        end)
    end
end

createSectionHeader(mobPage, "Player Mobility")

uiControls.speedHack = createToggle(mobPage, "Enable Custom WalkSpeed", speedHackEnabled, function(val)
    speedHackEnabled = val
    if not val then
        pcall(function()
            local hum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 10 end
        end)
    end
    triggerAutoSave()
end)

uiControls.customWalkSpeed = createSlider(mobPage, "Movement Speed", 10, 50, customWalkSpeed, function(val)
    customWalkSpeed = val
    triggerAutoSave()
end)

uiControls.jumpHack = createToggle(mobPage, "Enable Custom JumpPower", jumpHackEnabled, function(val)
    jumpHackEnabled = val
    if not val then
        pcall(function()
            local hum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = 30 end
        end)
    end
    triggerAutoSave()
end)

uiControls.customJumpPower = createSlider(mobPage, "Jump Height / Power", 30, 120, customJumpPower, function(val)
    customJumpPower = val
    triggerAutoSave()
end)

uiControls.noclip = createToggle(mobPage, "Noclip (Walk Through Walls)", noclipEnabled, function(val)
    noclipEnabled = val
    updateNoclip()
    triggerAutoSave()
end)

createSectionHeader(utilPage, "Ammo & Armor Utilities")

createButton(utilPage, "Instant Refill Ammo", function()
    refillAmmo()
end)

createButton(utilPage, "Instant Wear Armor (Vest)", function()
    equipVest()
end)

createSectionHeader(utilPage, "Map Teleports")

createButton(utilPage, "Teleport to Ammo Crate", function()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(140.4, 144.0, -290.0)
    end
end)

createButton(utilPage, "Teleport to Vest (Armor)", function()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(134.1, 144.0, -295.0)
    end
end)

createButton(utilPage, "Teleport to Attachments", function()
    local char = localPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(136.9, 142.1, -324.7)
    end
end)

createSectionHeader(espPage, "ESP Visuals")

uiControls.espHighlights = createToggle(espPage, "Player Highlights", espHighlightsEnabled, function(val)
    espHighlightsEnabled = val
    if not val then
        clearHighlights()
    end
    triggerAutoSave()
end)

uiControls.espNametags = createToggle(espPage, "Player Nametags", espNametagsEnabled, function(val)
    espNametagsEnabled = val
    if not val and not espShowDistance then
        clearNametags()
    end
    triggerAutoSave()
end)

uiControls.espShowDistance = createToggle(espPage, "Show Distance", espShowDistance, function(val)
    espShowDistance = val
    if not val and not espNametagsEnabled then
        clearNametags()
    end
    triggerAutoSave()
end)

uiControls.espTracers = createToggle(espPage, "Player Tracers", espTracersEnabled, function(val)
    espTracersEnabled = val
    if not val then
        clearTracers()
    end
    triggerAutoSave()
end)

uiControls.espTeamCheck = createToggle(espPage, "ESP Team Check", espTeamCheck, function(val)
    espTeamCheck = val
    clearHighlights()
    clearNametags()
    clearTracers()
    triggerAutoSave()
end)

uiControls.includeNpcsEsp = createToggle(espPage, "Include NPCs / Dummies", includeNpcs, function(val)
    includeNpcs = val
    clearHighlights()
    clearNametags()
    clearTracers()
    triggerAutoSave()
end)

uiControls.espOnlyInFov = createToggle(espPage, "Only Inside FOV", espOnlyInFov, function(val)
    espOnlyInFov = val
    clearHighlights()
    clearNametags()
    clearTracers()
    triggerAutoSave()
end)

local previewCard = Instance.new("Frame")
previewCard.Name = "CrosshairPreviewCard"
previewCard.Size = UDim2.new(1, 0, 0, 105)
previewCard.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
previewCard.BorderSizePixel = 0
previewCard.ClipsDescendants = true
previewCard.Parent = crossPage

local previewCorner = Instance.new("UICorner")
previewCorner.CornerRadius = UDim.new(0, 8)
previewCorner.Parent = previewCard

local previewStroke = Instance.new("UIStroke")
previewStroke.Color = Color3.fromRGB(38, 38, 52)
previewStroke.Thickness = 1
previewStroke.Parent = previewCard

local guideH = Instance.new("Frame")
guideH.Size = UDim2.new(1, 0, 0, 1)
guideH.Position = UDim2.new(0, 0, 0.5, 0)
guideH.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
guideH.BorderSizePixel = 0
guideH.Parent = previewCard

local guideV = Instance.new("Frame")
guideV.Size = UDim2.new(0, 1, 1, 0)
guideV.Position = UDim2.new(0.5, 0, 0, 0)
guideV.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
guideV.BorderSizePixel = 0
guideV.Parent = previewCard

local previewBadge = Instance.new("TextLabel")
previewBadge.Size = UDim2.new(0, 120, 0, 18)
previewBadge.Position = UDim2.new(0, 10, 0, 6)
previewBadge.BackgroundTransparency = 1
previewBadge.Text = "LIVE PREVIEW"
previewBadge.TextColor3 = Color3.fromRGB(120, 120, 145)
previewBadge.TextSize = 10
previewBadge.Font = Enum.Font.GothamBold
previewBadge.TextXAlignment = Enum.TextXAlignment.Left
previewBadge.Parent = previewCard

local previewContainer = Instance.new("Frame")
previewContainer.Name = "PreviewCenter"
previewContainer.Size = UDim2.new(0, 100, 0, 100)
previewContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
previewContainer.AnchorPoint = Vector2.new(0.5, 0.5)
previewContainer.BackgroundTransparency = 1
previewContainer.BorderSizePixel = 0
previewContainer.Parent = previewCard

previewCrosshairBundle = createCrosshairBundle(previewContainer)

createSectionHeader(crossPage, "General Settings")

uiControls.crosshairEnabled = createToggle(crossPage, "Enable Custom Crosshair", crosshairEnabled, function(val)
    crosshairEnabled = val
    updateCrosshair()
    triggerAutoSave()
end)

uiControls.crosshairStyle = createSelector(crossPage, "Crosshair Style", {
    "Classic Plus",
    "Crosshair + Dot",
    "Dot",
    "T-Shape",
    "X-Shape",
    "Chevron",
    "Circle",
    "Circle + Dot",
    "Circle + Cross",
    "Box",
    "Diamond",
    "Tri-Blade"
}, 1, function(selected)
    crosshairStyle = selected
    updateCrosshair()
    triggerAutoSave()
end)

uiControls.crosshairColor = createSelector(crossPage, "Crosshair Color", {
    "Cyan",
    "Green",
    "Red",
    "White",
    "Yellow",
    "Purple",
    "Orange",
    "Pink",
    "Lime",
    "Gold",
    "Black"
}, 1, function(selected)
    crosshairColorName = selected
    updateCrosshair()
    triggerAutoSave()
end)

uiControls.crosshairOutline = createToggle(crossPage, "Dark Outline / Shadow", crosshairOutline, function(val)
    crosshairOutline = val
    updateCrosshair()
    triggerAutoSave()
end)

createSectionHeader(crossPage, "Geometry & Sizing")

uiControls.crosshairSize = createSlider(crossPage, "Size", 2, 40, crosshairSize, function(val)
    crosshairSize = val
    updateCrosshair()
    triggerAutoSave()
end)

uiControls.crosshairThickness = createSlider(crossPage, "Thickness", 1, 8, crosshairThickness, function(val)
    crosshairThickness = val
    updateCrosshair()
    triggerAutoSave()
end)

uiControls.crosshairGap = createSlider(crossPage, "Center Gap", 0, 30, crosshairGap, function(val)
    crosshairGap = val
    updateCrosshair()
    triggerAutoSave()
end)

uiControls.crosshairTransparency = createSlider(crossPage, "Transparency (%)", 0, 80, crosshairTransparency, function(val)
    crosshairTransparency = val
    updateCrosshair()
    triggerAutoSave()
end)

createSectionHeader(crossPage, "Center Dot")

uiControls.crosshairDot = createToggle(crossPage, "Center Dot", crosshairDot, function(val)
    crosshairDot = val
    updateCrosshair()
    triggerAutoSave()
end)

uiControls.crosshairDotShape = createSelector(crossPage, "Dot Shape", { "Circle", "Square" }, 1, function(selected)
    crosshairDotShape = selected
    updateCrosshair()
    triggerAutoSave()
end)

uiControls.crosshairDotSize = createSlider(crossPage, "Dot Size", 1, 14, crosshairDotSize, function(val)
    crosshairDotSize = val
    updateCrosshair()
    triggerAutoSave()
end)

createSectionHeader(crossPage, "Dynamic Effects & Animations")

uiControls.crosshairChroma = createToggle(crossPage, "Rainbow / Chroma RGB", crosshairChroma, function(val)
    crosshairChroma = val
    updateCrosshair()
    triggerAutoSave()
end)

uiControls.crosshairTargetReaction = createToggle(crossPage, "Target Hover / Lock Alert", crosshairTargetReaction, function(val)
    crosshairTargetReaction = val
    updateCrosshair()
    triggerAutoSave()
end)

uiControls.crosshairDynamicSpread = createToggle(crossPage, "Dynamic Movement Spread", crosshairDynamicSpread, function(val)
    crosshairDynamicSpread = val
    updateCrosshair()
    triggerAutoSave()
end)

uiControls.crosshairSpin = createToggle(crossPage, "Spinning Crosshair", crosshairSpin, function(val)
    crosshairSpin = val
    if not val then
        crosshairCurrentRotation = 0
    end
    updateCrosshair()
    triggerAutoSave()
end)

uiControls.crosshairSpinSpeed = createSlider(crossPage, "Spin Speed (deg/s)", 30, 360, crosshairSpinSpeed, function(val)
    crosshairSpinSpeed = val
    updateCrosshair()
    triggerAutoSave()
end)

updateCrosshair()

createSectionHeader(configPage, "Configuration & Profiles")

uiControls.menuKey = createKeybind(configPage, "Menu Toggle Keybind", menuToggleKey, function(newKey)
    menuToggleKey = newKey
    updateBottomKeyLabel()
    triggerAutoSave()
end)

uiControls.autoSave = createToggle(configPage, "Auto-Save Changes", autoSaveEnabled, function(val)
    autoSaveEnabled = val
end)

createButton(configPage, "Save Settings Now", function()
    saveConfig()
end)

createButton(configPage, "Load Saved Settings", function()
    loadConfig()
end)

createButton(configPage, "Reset to Defaults", function()
    resetDefaults()
end)

createSectionHeader(configPage, "Script Management")

createButton(configPage, "Unload", function()
    cleanup()
end)

local statusRow = Instance.new("Frame")
statusRow.Size = UDim2.new(1, 0, 0, 32)
statusRow.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
statusRow.BorderSizePixel = 0
statusRow.Parent = configPage

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 6)
statusCorner.Parent = statusRow

configStatusLabel = Instance.new("TextLabel")
configStatusLabel.Size = UDim2.new(1, -20, 1, 0)
configStatusLabel.Position = UDim2.new(0, 10, 0, 0)
configStatusLabel.BackgroundTransparency = 1
configStatusLabel.Text = "Status: Ready"
configStatusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
configStatusLabel.TextSize = 12
configStatusLabel.Font = Enum.Font.GothamMedium
configStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
configStatusLabel.Parent = statusRow

task.spawn(function()
    task.wait(0.1)
    loadConfig()
end)

bottomLabel = Instance.new("TextLabel")
bottomLabel.Size = UDim2.new(1, 0, 0, 22)
bottomLabel.Position = UDim2.new(0, 0, 1, -24)
bottomLabel.BackgroundTransparency = 1
bottomLabel.Text = "Press [" .. menuToggleKey.Name .. "] to Toggle Menu"
bottomLabel.TextColor3 = Color3.fromRGB(110, 110, 130)
bottomLabel.TextSize = 11
bottomLabel.Font = Enum.Font.Gotham
bottomLabel.Parent = contentFrame

local renderConn = nil
local inputBeganConn = nil
local inputEndedConn = nil
local inputChangedConn = nil
local charChildRemovedConn = nil
local charAddedConn = nil

local function cleanup()
    if autoSaveEnabled then
        pcall(saveConfig)
    end
    isScriptUnloaded = true
    if uiControls.menuKey and uiControls.menuKey.Cancel then
        pcall(uiControls.menuKey.Cancel)
    end
    if renderConn then
        renderConn:Disconnect()
        renderConn = nil
    end
    if inputBeganConn then
        inputBeganConn:Disconnect()
        inputBeganConn = nil
    end
    if inputEndedConn then
        inputEndedConn:Disconnect()
        inputEndedConn = nil
    end
    if inputChangedConn then
        inputChangedConn:Disconnect()
        inputChangedConn = nil
    end
    if charChildRemovedConn then
        charChildRemovedConn:Disconnect()
        charChildRemovedConn = nil
    end
    if charAddedConn then
        charAddedConn:Disconnect()
        charAddedConn = nil
    end
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    pcall(function()
        local char = localPlayer.Character
        if char then
            for _, child in ipairs(char:GetChildren()) do
                if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
                    child.CanCollide = true
                end
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 10
                hum.JumpPower = 30
            end
            local ct = char:FindFirstChild("CameraTilt")
            if ct and ct:IsA("LocalScript") then
                ct.Enabled = true
            end
        end
    end)
    clearHighlights()
    clearNametags()
    clearTracers()
    if highlightFolder then
        pcall(function() highlightFolder:Destroy() end)
        highlightFolder = nil
    end
    if tracerFolder then
        pcall(function() tracerFolder:Destroy() end)
        tracerFolder = nil
    end
    if crosshairContainer then
        pcall(function() crosshairContainer:Destroy() end)
        crosshairContainer = nil
    end
    mainCrosshairBundle = nil
    previewCrosshairBundle = nil
    if modalFreer then
        pcall(function() modalFreer:Destroy() end)
        modalFreer = nil
    end
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
    pcall(function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    end)
end

closeBtn.MouseButton1Click:Connect(function()
    cleanup()
end)

inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            isAiming = true
        end
    end

    if not isKeybinding and not UserInputService:GetFocusedTextBox() and menuToggleKey ~= Enum.KeyCode.Unknown and input.KeyCode == menuToggleKey then
        setMenuOpen(not isMenuOpen)
    end
end)

inputEndedConn = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = false
    end
end)

inputChangedConn = UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        task.defer(ensureMouseFreedIfThirdPerson)
    end
end)

local function hookCharacterTools(char)
    if charChildRemovedConn then
        charChildRemovedConn:Disconnect()
        charChildRemovedConn = nil
    end
    if not char then return end
    charChildRemovedConn = char.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            task.defer(ensureMouseFreedIfThirdPerson)
        end
    end)
end

if localPlayer and localPlayer.Character then
    hookCharacterTools(localPlayer.Character)
end
if localPlayer then
    charAddedConn = localPlayer.CharacterAdded:Connect(hookCharacterTools)
end

renderConn = RunService.RenderStepped:Connect(function(deltaTime)
    if isScriptUnloaded then return end

    if isMenuOpen then
        if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
            pcall(function()
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end)
        end
        if not UserInputService.MouseIconEnabled then
            pcall(function()
                UserInputService.MouseIconEnabled = true
            end)
        end
    else
        ensureMouseFreedIfThirdPerson()
    end

    camera = workspace.CurrentCamera or camera
    if not camera then return end

    if circleFrame then
        circleFrame.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
        circleFrame.Visible = showFov
    end

    local eligiblePlayers = getEligiblePlayers(espOnlyInFov)

    if espHighlightsEnabled then
        local currentChars = {}
        for _, entry in ipairs(eligiblePlayers) do
            currentChars[entry.character] = true
            getOrCreateHighlight(entry.character)
        end
        for char, hl in pairs(activeHighlights) do
            if not currentChars[char] then
                if hl then
                    pcall(function() hl:Destroy() end)
                end
                activeHighlights[char] = nil
            end
        end
    else
        clearHighlights()
    end

    if espNametagsEnabled or espShowDistance then
        local currentChars = {}
        for _, entry in ipairs(eligiblePlayers) do
            currentChars[entry.character] = true
            local tag = getOrCreateNametag(entry.character, entry.name)
            if tag then
                local label = tag:FindFirstChild("Text")
                if label then
                    local nameText = entry.name or (entry.player and entry.player.DisplayName) or "Target"
                    local distText = ""
                    if espShowDistance and localPlayer.Character then
                        local myRoot = localPlayer.Character:FindFirstChild("HumanoidRootPart") or localPlayer.Character.PrimaryPart
                        local head = entry.character:FindFirstChild("Head") or entry.part
                        if myRoot and head then
                            local dist = math.floor((head.Position - myRoot.Position).Magnitude)
                            distText = string.format("[%dm]", dist)
                        end
                    end

                    if espNametagsEnabled and distText ~= "" then
                        label.Text = nameText .. " " .. distText
                    elseif espNametagsEnabled then
                        label.Text = nameText
                    elseif distText ~= "" then
                        label.Text = distText
                    else
                        label.Text = ""
                    end
                end
            end
        end
        for char, tag in pairs(activeNametags) do
            if not currentChars[char] then
                if tag then
                    pcall(function() tag:Destroy() end)
                end
                activeNametags[char] = nil
            end
        end
    else
        clearNametags()
    end

    if espTracersEnabled then
        local currentChars = {}
        local origin = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
        for _, entry in ipairs(eligiblePlayers) do
            currentChars[entry.character] = true
            local targetPart = entry.character:FindFirstChild("HumanoidRootPart") or entry.character:FindFirstChild("Head") or entry.part
            if targetPart then
                local sPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                local line = getOrCreateTracer(entry.character)
                if line then
                    if onScreen and sPos.Z > 0 then
                        local target2D = Vector2.new(sPos.X, sPos.Y)
                        local diff = target2D - origin
                        local length = diff.Magnitude
                        local angle = math.deg(math.atan2(diff.Y, diff.X))
                        local mid = (origin + target2D) / 2

                        line.Size = UDim2.new(0, length, 0, 1.5)
                        line.Position = UDim2.new(0, mid.X, 0, mid.Y)
                        line.Rotation = angle
                        line.BackgroundColor3 = espFillColor or Color3.fromRGB(255, 60, 60)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                end
            end
        end
        for char, line in pairs(activeTracers) do
            if not currentChars[char] then
                if line then
                    pcall(function() line:Destroy() end)
                end
                activeTracers[char] = nil
            end
        end
    else
        clearTracers()
    end

    if speedHackEnabled then
        local char = localPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= customWalkSpeed then
            pcall(function() hum.WalkSpeed = customWalkSpeed end)
        end
    end

    if jumpHackEnabled then
        local char = localPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.JumpPower ~= customJumpPower then
            pcall(function() hum.JumpPower = customJumpPower end)
        end
    end

    if crosshairEnabled or (isMenuOpen and previewCrosshairBundle) then
        if crosshairSpin then
            crosshairCurrentRotation = (crosshairCurrentRotation + crosshairSpinSpeed * deltaTime) % 360
        else
            crosshairCurrentRotation = 0
        end

        local activeColor = crosshairColorPresets[crosshairColorName] or crosshairColor
        local isTargetActive = false

        if crosshairTargetReaction then
            if currentAimbotTarget and currentAimbotTarget.character then
                isTargetActive = true
            else
                local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                local eligible = getEligiblePlayers(false)
                for _, entry in ipairs(eligible) do
                    local char = entry.character
                    local part = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or entry.part)
                    if part then
                        local sPos, onScreen = camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local dist2D = (Vector2.new(sPos.X, sPos.Y) - center).Magnitude
                            if dist2D < (crosshairSize + crosshairGap + 16) then
                                isTargetActive = true
                                break
                            end
                        end
                    end
                end
            end
        end

        if isTargetActive then
            activeColor = Color3.fromRGB(255, 45, 45)
        elseif crosshairChroma then
            activeColor = Color3.fromHSV((tick() * 0.4) % 1, 0.85, 1)
        end

        local activeGap = crosshairGap
        if crosshairDynamicSpread and localPlayer.Character then
            local root = localPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then
                local vel = root.AssemblyLinearVelocity
                local horizontalSpeed = Vector2.new(vel.X, vel.Z).Magnitude
                local jumpSpread = math.abs(vel.Y) > 2 and 4 or 0
                local moveSpread = math.clamp(horizontalSpeed * 0.22, 0, 10)
                activeGap = crosshairGap + moveSpread + jumpSpread
            end
        end

        local currentRot = crosshairSpin and crosshairCurrentRotation or 0
        if crosshairEnabled and mainCrosshairBundle then
            updateCrosshairBundle(mainCrosshairBundle, activeColor, activeGap, currentRot)
        end
        if isMenuOpen and previewCrosshairBundle then
            updateCrosshairBundle(previewCrosshairBundle, activeColor, crosshairGap, currentRot)
        end
    end

    if not aimbotEnabled then
        currentAimbotTarget = nil
        return
    end

    local aimingNow = aimbotAlwaysOn or isAiming
    if aimingNow then
        local playersInFov = getPlayersInFov()
        local targetEntry = getTargetPlayer(playersInFov)
        currentAimbotTarget = targetEntry
        if targetEntry and targetEntry.part then
            local aimPos = targetEntry.part.Position

            local smoothnessDelay = (smoothness > 1) and ((smoothness - 1) * 0.008) or 0

            local localVel = Vector3.zero
            if movementCompEnabled and smoothnessDelay > 0 then
                local localChar = localPlayer and localPlayer.Character
                local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
                local localHum = localChar and localChar:FindFirstChildOfClass("Humanoid")

                if localRoot and localRoot:IsA("BasePart") then
                    localVel = localRoot.AssemblyLinearVelocity
                end

                if localVel.Magnitude > 85 then
                    localVel = localVel.Unit * 85
                end

                if localHum and localHum.FloorMaterial ~= Enum.Material.Air then
                    if localVel.Y < 1 and localVel.Y > -5 then
                        localVel = Vector3.new(localVel.X, 0, localVel.Z)
                    end
                end
            end

            if movementPrediction then
                updateCurrentWeaponStats()

                local targetChar = targetEntry.character
                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
                local targetVel = Vector3.zero

                if targetRoot and targetRoot:IsA("BasePart") then
                    targetVel = targetRoot.AssemblyLinearVelocity
                elseif targetEntry.part:IsA("BasePart") then
                    targetVel = targetEntry.part.AssemblyLinearVelocity
                end

                if targetVel.Magnitude > 85 then
                    targetVel = targetVel.Unit * 85
                end

                if targetHum and targetHum.FloorMaterial ~= Enum.Material.Air then
                    if targetVel.Y < 1 and targetVel.Y > -5 then
                        targetVel = Vector3.new(targetVel.X, 0, targetVel.Z)
                    end
                end

                local camPos = camera.CFrame.Position
                local dist = (aimPos - camPos).Magnitude
                local travelTime = dist / math.max(cachedMuzzleVelocity, 150)

                local pingLead = getNetworkPing() * 0.65

                local ballisticLead = targetVel * (travelTime + pingLead) * predictionLead
                local smoothLead = Vector3.zero
                if smoothnessDelay > 0 then
                    if movementCompEnabled then
                        smoothLead = (targetVel - localVel) * smoothnessDelay
                    else
                        smoothLead = targetVel * smoothnessDelay
                    end
                end

                aimPos = aimPos + ballisticLead + smoothLead
            elseif movementCompEnabled and smoothnessDelay > 0 then
                aimPos = aimPos - (localVel * smoothnessDelay)
            end

            local currentCFrame = camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, aimPos)
            local alpha = 1
            if smoothness > 1 then
                local rate = 90 / (smoothness - 1)
                alpha = math.clamp(1 - math.exp(-rate * deltaTime), 0.05, 1)
            end
            camera.CFrame = currentCFrame:Lerp(targetCFrame, alpha)
        end
    else
        currentAimbotTarget = nil
    end
end)
