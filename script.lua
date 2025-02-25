local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Afonso Scripts",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Example Hub",
   LoadingSubtitle = "by Afonso",
   Theme = "Dark Blue", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = true,
      FolderName = true, -- Create a custom folder for your hub/game
      FileName = "ExampleHub"
   },

   Discord = {
      Enabled = true, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "https://discord.gg/mpTjs9EZ", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = true, -- Set this to true to use our key system
   KeySettings = {
      Title = "Afonso Scripts || keys",
      Subtitle = "Link in discord server",
      Note = "Join discord server from misc tab", -- Use this to tell the user how to get a key
      FileName = "ExampleHubKey", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"premiumkey5"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})

local MainTab = Window:CreateTab("🏠Home", nil) -- Title, Image
local MainSection = MainTab:CreateSection("Main")

Rayfield:Notify({
   Title = "Script executed!",
   Content = "Have fun!",
   Duration = 4,
   Image = nil,
})

local Button = MainTab:CreateButton({
   Name = "Esp",
   Callback = function()
-- Roblox ESP Script
-- Shows players with customizable ESP features: boxes, lines, and distance info

local ESPSettings = {
    Enabled = true,
    BoxesEnabled = true,
    BoxColor = Color3.fromRGB(255, 0, 0), -- Red boxes
    LinesEnabled = true,
    LineColor = Color3.fromRGB(255, 0, 0), -- Red lines
    TextEnabled = true,
    TextColor = Color3.fromRGB(255, 255, 255), -- White text
    TextSize = 14,
    MaxDistance = 1000, -- Maximum distance to render ESP
    TeamCheck = false, -- Set to true to not show ESP for teammates
    -- Add filter settings to prevent incorrect highlighting
    FilterNonPlayerObjects = true, -- Prevents highlighting non-player objects
    FilterGUIElements = true -- Prevents highlighting GUI elements
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local ESPFolder
local SettingsGui

-- Create ESP container
local function CreateESPFolder()
    if CoreGui:FindFirstChild("ESPFolder") then
        CoreGui.ESPFolder:Destroy()
    end
    ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "ESPFolder"
    ESPFolder.Parent = CoreGui
end

-- Utility function to create drawing objects
local function CreateDrawing(type, properties)
    local drawing = Drawing.new(type)
    for property, value in pairs(properties) do
        drawing[property] = value
    end
    return drawing
end

-- Function to get character parts
local function GetCharacterParts(character)
    if not character then return nil end
    
    local parts = {}
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            parts[#parts + 1] = part
        end
    end
    
    return parts
end

-- Validate if object is a valid player character
local function IsValidCharacter(object)
    if not object then return false end
    
    -- Verify it's a character model with required components
    if not object:IsA("Model") then return false end
    if not object:FindFirstChild("Humanoid") then return false end
    if not object:FindFirstChild("HumanoidRootPart") then return false end
    
    -- Check if it belongs to a player
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character == object then
            return true
        end
    end
    
    return false
end

-- Calculate 3D bounding box corners
local function CalculateCorners(character)
    local parts = GetCharacterParts(character)
    if not parts or #parts == 0 then return nil end
    
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    
    for _, part in pairs(parts) do
        local size = part.Size
        local cf = part.CFrame
        
        local corners = {
            cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
            cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
            cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
            cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
            cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
            cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
            cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
            cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2)
        }
        
        for _, corner in pairs(corners) do
            local position = corner.Position
            minX, minY, minZ = math.min(minX, position.X), math.min(minY, position.Y), math.min(minZ, position.Z)
            maxX, maxY, maxZ = math.max(maxX, position.X), math.max(maxY, position.Y), math.max(maxZ, position.Z)
        end
    end
    
    return {
        BottomCorner = Vector3.new(minX, minY, minZ),
        TopCorner = Vector3.new(maxX, maxY, maxZ)
    }
end

-- ESP class for each player
local ESP = {}
ESP.__index = ESP

function ESP.new(player)
    local self = setmetatable({}, ESP)
    
    self.Player = player
    
    -- Create ESP objects immediately
    self.BoxDrawing = CreateDrawing("Square", {
        Thickness = 2,
        Color = ESPSettings.BoxColor,
        Filled = false,
        Visible = false,
        ZIndex = 2
    })
    self.LineDrawing = CreateDrawing("Line", {
        Thickness = 1,
        Color = ESPSettings.LineColor,
        Visible = false,
        ZIndex = 1
    })
    self.TextDrawing = CreateDrawing("Text", {
        Text = "",
        Size = ESPSettings.TextSize,
        Center = true,
        Outline = true,
        Color = ESPSettings.TextColor,
        Visible = false,
        ZIndex = 3
    })
    
    -- Initialize character
    if player.Character then
        self.Character = player.Character
        -- Force an immediate update
        task.spawn(function()
            self:Update()
        end)
    end
    
    -- Handle character respawning with immediate update
    player.CharacterAdded:Connect(function(character)
        self.Character = character
        -- Force an immediate update when character loads
        task.spawn(function()
            self:Update()
        end)
    end)
    
    return self
end

function ESP:Update()
    if not ESPSettings.Enabled then
        self.BoxDrawing.Visible = false
        self.LineDrawing.Visible = false
        self.TextDrawing.Visible = false
        return
    end
    
    -- Extra validation to ensure we only highlight actual player characters
    if not self.Character or not self.Player or not self.Character:FindFirstChild("HumanoidRootPart") or not self.Character:FindFirstChild("Humanoid") then
        self.BoxDrawing.Visible = false
        self.LineDrawing.Visible = false
        self.TextDrawing.Visible = false
        return
    end
    
    -- Additional check to ensure the character is valid
    if ESPSettings.FilterNonPlayerObjects and not IsValidCharacter(self.Character) then
        self.BoxDrawing.Visible = false
        self.LineDrawing.Visible = false
        self.TextDrawing.Visible = false
        return
    end
    
    -- Team check
    if ESPSettings.TeamCheck and self.Player.Team == LocalPlayer.Team then
        self.BoxDrawing.Visible = false
        self.LineDrawing.Visible = false
        self.TextDrawing.Visible = false
        return
    end
    
    -- Get player data
    local humanoidRootPart = self.Character.HumanoidRootPart
    local humanoid = self.Character.Humanoid
    local position = humanoidRootPart.Position
    local distance = (Camera.CFrame.Position - position).Magnitude
    
    -- Check distance
    if distance > ESPSettings.MaxDistance then
        self.BoxDrawing.Visible = false
        self.LineDrawing.Visible = false
        self.TextDrawing.Visible = false
        return
    end
    
    -- Get bounding box
    local corners = CalculateCorners(self.Character)
    if not corners then
        self.BoxDrawing.Visible = false
        self.LineDrawing.Visible = false
        self.TextDrawing.Visible = false
        return
    end
    
    -- Additional size sanity check to avoid large boxes around non-character objects
    local boxWidth = math.abs(corners.TopCorner.X - corners.BottomCorner.X)
    local boxHeight = math.abs(corners.TopCorner.Y - corners.BottomCorner.Y)
    
    if boxWidth > 50 or boxHeight > 50 then
        self.BoxDrawing.Visible = false
        self.LineDrawing.Visible = false
        self.TextDrawing.Visible = false
        return
    end
    
    -- Box ESP
    if ESPSettings.BoxesEnabled then
        local bottomCorner = Camera:WorldToViewportPoint(corners.BottomCorner)
        local topCorner = Camera:WorldToViewportPoint(corners.TopCorner)
        
        if bottomCorner.Z > 0 and topCorner.Z > 0 then
            local width = math.abs(topCorner.X - bottomCorner.X)
            local height = math.abs(topCorner.Y - bottomCorner.Y)
            
            -- Additional size validation to prevent large boxes
            if width < 2000 and height < 2000 and width > 5 and height > 5 then
                self.BoxDrawing.Size = Vector2.new(width, height)
                self.BoxDrawing.Position = Vector2.new(
                    math.min(bottomCorner.X, topCorner.X),
                    math.min(bottomCorner.Y, topCorner.Y)
                )
                self.BoxDrawing.Color = ESPSettings.BoxColor
                self.BoxDrawing.Visible = true
            else
                self.BoxDrawing.Visible = false
            end
        else
            self.BoxDrawing.Visible = false
        end
    else
        self.BoxDrawing.Visible = false
    end
    
    -- Line ESP
    if ESPSettings.LinesEnabled then
        local headPosition = Camera:WorldToViewportPoint(humanoidRootPart.Position + Vector3.new(0, 3, 0))
        
        if headPosition.Z > 0 then
            self.LineDrawing.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            self.LineDrawing.To = Vector2.new(headPosition.X, headPosition.Y)
            self.LineDrawing.Color = ESPSettings.LineColor
            self.LineDrawing.Visible = true
        else
            self.LineDrawing.Visible = false
        end
    else
        self.LineDrawing.Visible = false
    end
    
    -- Text ESP (distance, name, health)
    if ESPSettings.TextEnabled then
        local headPosition = Camera:WorldToViewportPoint(humanoidRootPart.Position + Vector3.new(0, 3, 0))
        
        if headPosition.Z > 0 then
            local roundedDistance = math.floor(distance + 0.5)
            local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100 + 0.5)
            
            self.TextDrawing.Text = string.format("%dm|%s|%d%%", roundedDistance, self.Player.Name, healthPercent)
            self.TextDrawing.Position = Vector2.new(headPosition.X, headPosition.Y - 30)
            self.TextDrawing.Color = ESPSettings.TextColor
            self.TextDrawing.Size = ESPSettings.TextSize
            self.TextDrawing.Visible = true
        else
            self.TextDrawing.Visible = false
        end
    else
        self.TextDrawing.Visible = false
    end
end

function ESP:Remove()
    self.BoxDrawing:Remove()
    self.LineDrawing:Remove()
    self.TextDrawing:Remove()
end

-- Main ESP manager
local ESPManager = {
    Players = {},
    Connections = {}
}

function ESPManager:Start()
    CreateESPFolder()
    
    -- Add existing players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self.Players[player] = ESP.new(player)
        end
    end
    
    -- Handle new players joining
    table.insert(self.Connections, Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            -- Create new ESP instance
            self.Players[player] = ESP.new(player)
            
            -- Notify about new player
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "ESP",
                Text = player.Name .. " joined",
                Duration = 2
            })
        end
    end))
    
    -- Handle players leaving
    table.insert(self.Connections, Players.PlayerRemoving:Connect(function(player)
        if self.Players[player] then
            self.Players[player]:Remove()
            self.Players[player] = nil
        end
    end))
    
    -- Update ESP
    table.insert(self.Connections, RunService.RenderStepped:Connect(function()
        for _, esp in pairs(self.Players) do
            esp:Update()
        end
    end))
    
    -- Create settings GUI
    self:CreateSettingsGUI()
end

function ESPManager:Stop()
    -- Disconnect all connections
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    self.Connections = {}
    
    -- Remove all ESP objects
    for _, esp in pairs(self.Players) do
        esp:Remove()
    end
    self.Players = {}
    
    -- Remove ESP folder
    if ESPFolder then
        ESPFolder:Destroy()
    end
    
    -- Remove GUI
    if SettingsGui then
        SettingsGui:Destroy()
        SettingsGui = nil
    end
end

function ESPManager:ToggleGUI()
    if SettingsGui then
        -- If GUI exists, just show it instead of creating a new one
        SettingsGui.Enabled = true
        return
    end
    self:CreateSettingsGUI()
end

function ESPManager:UpdateAllButtons()
    -- This function updates all button appearances based on current settings
    if not SettingsGui then return end
    
    -- Find and update all toggle buttons
    for _, button in pairs(SettingsGui:GetDescendants()) do
        if button:IsA("TextButton") then
            local buttonText = button.Text
            -- Skip the X button and color button
            if buttonText ~= "X" and not buttonText:find("Change Color") then
                local settingName = buttonText:split(":")[1]:gsub(" ", "")
                
                -- Map button text to setting names
                local settingMap = {
                    ["ESP"] = "Enabled",
                    ["Boxes"] = "BoxesEnabled",
                    ["Lines"] = "LinesEnabled",
                    ["TextInfo"] = "TextEnabled",
                    ["TeamCheck"] = "TeamCheck"
                }
                
                if settingMap[settingName] then
                    local isOn = ESPSettings[settingMap[settingName]]
                    button.Text = settingName .. ": " .. (isOn and "ON" or "OFF")
                    button.BackgroundColor3 = isOn and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
                    button.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end
        end
    end
end

function ESPManager:CreateSettingsGUI()
    -- Check if GUI already exists, if so just show it
    if SettingsGui then
        SettingsGui.Enabled = true
        return
    end
    
    -- Create the ScreenGui with proper ZIndexBehavior
    SettingsGui = Instance.new("ScreenGui")
    SettingsGui.Name = "ESPSettings"
    SettingsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    SettingsGui.Parent = CoreGui
    SettingsGui.ResetOnSpawn = false
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 200, 0, 290)
    Frame.Position = UDim2.new(0, 10, 0, 10)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Frame.BorderSizePixel = 0
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = SettingsGui
    
    -- Title with black background
    local TitleFrame = Instance.new("Frame")
    TitleFrame.Size = UDim2.new(1, 0, 0, 40)
    TitleFrame.Position = UDim2.new(0, 0, 0, 0)
    TitleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TitleFrame.BorderSizePixel = 0
    TitleFrame.Parent = Frame
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -25, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    Title.Font = Enum.Font.SourceSansBold
    Title.Text = "ESP Settings"
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.Parent = TitleFrame
    
    -- Add X button
    local XButton = Instance.new("TextButton")
    XButton.Size = UDim2.new(0, 25, 0, 25)
    XButton.Position = UDim2.new(1, -25, 0, 8)
    XButton.BackgroundTransparency = 1
    XButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    XButton.TextSize = 18
    XButton.Font = Enum.Font.SourceSansBold
    XButton.Text = "X"
    XButton.TextYAlignment = Enum.TextYAlignment.Center
    XButton.Parent = TitleFrame
    
    -- Add X button functionality - now just hides the GUI instead of destroying
    XButton.MouseButton1Click:Connect(function()
        SettingsGui.Enabled = false
    end)
    
    -- Color selection with presets
    local ColorPresets = {
        Color3.fromRGB(255, 0, 0),      -- Red
        Color3.fromRGB(0, 255, 0),      -- Green
        Color3.fromRGB(0, 0, 255),      -- Blue
        Color3.fromRGB(255, 255, 0),    -- Yellow
        Color3.fromRGB(255, 0, 255),    -- Magenta
        Color3.fromRGB(0, 255, 255),    -- Cyan
        Color3.fromRGB(255, 165, 0),    -- Orange
        Color3.fromRGB(128, 0, 128)     -- Purple
    }
    local CurrentColorIndex = 1
    
    local function createButton(text, position, isOn, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 30)
        button.Position = position
        button.Font = Enum.Font.SourceSansBold
        button.TextSize = 16
        button.Text = text
        button.Parent = Frame
        
        -- Update appearance based on state
        local function updateAppearance()
            if text:find("Color") then
                button.BackgroundColor3 = ColorPresets[CurrentColorIndex]
                button.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                button.BackgroundColor3 = isOn and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
                button.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
        end
        
        updateAppearance()
        
        button.MouseButton1Click:Connect(function()
            if text:find("Color") then
                -- Cycle through color presets
                CurrentColorIndex = (CurrentColorIndex % #ColorPresets) + 1
                ESPSettings.BoxColor = ColorPresets[CurrentColorIndex]
                ESPSettings.LineColor = ColorPresets[CurrentColorIndex]
            else
                -- Toggle button state and update ESPSettings
                isOn = not isOn
                button.Text = text:split(":")[1] .. ": " .. (isOn and "ON" or "OFF")
                callback(isOn)
                
                -- Apply notification when main ESP toggle changes
                if text:find("ESP:") then
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "ESP",
                        Text = isOn and "Enabled" or "Disabled",
                        Duration = 2
                    })
                end
            end
            
            updateAppearance()
            -- Update all buttons to ensure UI consistency
            ESPManager:UpdateAllButtons()
        end)
        
        return button
    end
    
    -- Adjust button spacing for compact layout
    local buttonHeight = 30
    local buttonSpacing = 5
    local currentY = 45
    
    -- Create buttons with even spacing
    local espButton = createButton("ESP: " .. (ESPSettings.Enabled and "ON" or "OFF"), 
        UDim2.new(0, 0, 0, currentY), ESPSettings.Enabled, 
        function(value) 
            ESPSettings.Enabled = value 
        end)
    currentY = currentY + buttonHeight + buttonSpacing
    
    local boxesButton = createButton("Boxes: " .. (ESPSettings.BoxesEnabled and "ON" or "OFF"), 
        UDim2.new(0, 0, 0, currentY), ESPSettings.BoxesEnabled, 
        function(value) 
            ESPSettings.BoxesEnabled = value 
        end)
    currentY = currentY + buttonHeight + buttonSpacing
    
    local linesButton = createButton("Lines: " .. (ESPSettings.LinesEnabled and "ON" or "OFF"), 
        UDim2.new(0, 0, 0, currentY), ESPSettings.LinesEnabled, 
        function(value) 
            ESPSettings.LinesEnabled = value 
        end)
    currentY = currentY + buttonHeight + buttonSpacing
    
    local textButton = createButton("Text Info: " .. (ESPSettings.TextEnabled and "ON" or "OFF"), 
        UDim2.new(0, 0, 0, currentY), ESPSettings.TextEnabled, 
        function(value) 
            ESPSettings.TextEnabled = value 
        end)
    currentY = currentY + buttonHeight + buttonSpacing
    
    local teamButton = createButton("Team Check: " .. (ESPSettings.TeamCheck and "ON" or "OFF"), 
        UDim2.new(0, 0, 0, currentY), ESPSettings.TeamCheck, 
        function(value) 
            ESPSettings.TeamCheck = value 
        end)
    currentY = currentY + buttonHeight + buttonSpacing
    
    -- Add filter for non-player objects
    local filterButton = createButton("Filter Non-Players: " .. (ESPSettings.FilterNonPlayerObjects and "ON" or "OFF"), 
        UDim2.new(0, 0, 0, currentY), ESPSettings.FilterNonPlayerObjects, 
        function(value) 
            ESPSettings.FilterNonPlayerObjects = value 
        end)
    currentY = currentY + buttonHeight + buttonSpacing
    
    -- Add color change button
    local colorButton = createButton("Change Color", UDim2.new(0, 0, 0, currentY), true, function()
        -- This is handled in the click event above
    end)
end

-- Keyboard shortcuts
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Toggle ESP with Right Control key
    if input.KeyCode == Enum.KeyCode.RightControl then
        ESPSettings.Enabled = not ESPSettings.Enabled
        -- Update GUI if it exists
        ESPManager:UpdateAllButtons()
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "ESP",
            Text = ESPSettings.Enabled and "Enabled" or "Disabled",
            Duration = 2
        })
    end
    
    -- Toggle GUI with Right Alt key
    if input.KeyCode == Enum.KeyCode.RightAlt then
        ESPManager:ToggleGUI()
    end
end)

-- Start the ESP
ESPManager:Start()
   end,
})

local Toggle = MainTab:CreateToggle({
   Name = "Aim Bot",
   CurrentValue = false,
   Flag = "Toggle1", 
   Callback = function(Value)
       if Value then
           -- Configuration
           local ASSIST_RANGE = 200       -- Maximum range to detect targets
           local UPDATE_RATE = 0.1        -- How often to update targeting
           local HEAD_OFFSET = Vector3.new(0, 0.1, 0)  -- Fine-tune head targeting

           local Players = game:GetService("Players")
           local RunService = game:GetService("RunService")
           local Teams = game:GetService("Teams")
           
           local LocalPlayer = Players.LocalPlayer
           local Camera = workspace.CurrentCamera
           
           -- Function to check if a player is on the same team
           local function isTeammate(player)
               if not LocalPlayer.Team then return false end
               return player.Team == LocalPlayer.Team
           end
           
           -- Function to check if a character is valid target
           local function isValidTarget(character, player)
               if not character then return false end
               
               -- Check if character has necessary parts
               local humanoid = character:FindFirstChild("Humanoid")
               local head = character:FindFirstChild("Head")
               
               -- If it's a player, check team status
               if player then
                   if isTeammate(player) then return false end
               end
               
               return humanoid 
                   and head 
                   and humanoid.Health > 0
           end
           
           -- Function to get nearest target
           local function getNearestTarget()
               local nearestDistance = ASSIST_RANGE
               local nearestTarget = nil
               local playerChar = LocalPlayer.Character
               local playerHead = playerChar and playerChar:FindFirstChild("Head")
               
               if not playerHead then return nil end
               
               -- Check players
               for _, player in pairs(Players:GetPlayers()) do
                   if player ~= LocalPlayer then
                       local character = player.Character
                       if isValidTarget(character, player) then
                           local targetHead = character.Head
                           local distance = (playerHead.Position - targetHead.Position).Magnitude
                           
                           if distance < nearestDistance then
                               nearestDistance = distance
                               nearestTarget = character
                           end
                       end
                   end
               end
               
               -- Check NPCs/monsters (checking multiple possible folder names)
               local possibleFolders = {"NPCs", "Monsters", "Enemies", "Mobs"}
               for _, folderName in pairs(possibleFolders) do
                   local folder = workspace:FindFirstChild(folderName)
                   if folder then
                       for _, npc in pairs(folder:GetChildren()) do
                           if isValidTarget(npc) then
                               local targetHead = npc.Head
                               local distance = (playerHead.Position - targetHead.Position).Magnitude
                               
                               if distance < nearestDistance then
                                   nearestDistance = distance
                                   nearestTarget = npc
                               end
                           end
                       end
                   end
               end
               
               return nearestTarget
           end
           
           -- Function to update camera aim
           local function updateAim()
               local target = getNearestTarget()
               if not target then return end
               
               local targetHead = target.Head
               local aimPosition = targetHead.Position + HEAD_OFFSET
               local playerChar = LocalPlayer.Character
               
               if playerChar and playerChar:FindFirstChild("Head") then
                   -- Calculate aim direction
                   local aimAt = CFrame.lookAt(
                       Camera.CFrame.Position,
                       aimPosition
                   )
                   
                   -- Smoothly interpolate camera rotation
                   Camera.CFrame = Camera.CFrame:Lerp(aimAt, 0.2)
               end
           end
           
           -- Connect update function
           _G.AimAssistConnection = RunService.RenderStepped:Connect(updateAim)
           
       else
           -- Cleanup when toggled off
           if _G.AimAssistConnection then
               _G.AimAssistConnection:Disconnect()
               _G.AimAssistConnection = nil
           end
       end
   end
})

local Toggle = MainTab:CreateToggle({
   Name = "Enhanced Aim Bot",
   CurrentValue = false,
   Flag = "Toggle1", 
   Callback = function(Value)
       if Value then
           -- Configuration
           local ASSIST_RANGE = 200       -- Maximum range to detect targets
           local WALL_CHECK_RANGE = 50    -- Range within which to consider targets even behind walls
           local CLOSE_RANGE = 25         -- Range for super high priority close targets
           local UPDATE_RATE = 0.1        -- How often to update targeting
           local HEAD_OFFSET = Vector3.new(0, 0.1, 0)  -- Fine-tune head targeting
           
           -- Angle configuration
           local MAX_ANGLE = math.rad(180)  -- Maximum angle to consider targets
           local CLOSE_ANGLE = math.rad(90) -- Angle for close range priority boost

           local Players = game:GetService("Players")
           local RunService = game:GetService("RunService")
           local Teams = game:GetService("Teams")
           
           local LocalPlayer = Players.LocalPlayer
           local Camera = workspace.CurrentCamera
           
           -- Function to check if a player is on the same team
           local function isTeammate(player)
               if not LocalPlayer.Team then return false end
               return player.Team == LocalPlayer.Team
           end
           
           -- Function to check if target is visible (accounting for partial cover)
           local function isTargetVisible(targetPosition, sourcePosition)
               -- Check multiple points around the target to handle partial cover
               local checkPoints = {
                   targetPosition,
                   targetPosition + Vector3.new(0, 1, 0),    -- Head level
                   targetPosition + Vector3.new(0.5, 0, 0),  -- Right
                   targetPosition + Vector3.new(-0.5, 0, 0), -- Left
                   targetPosition + Vector3.new(0, 0, 0.5),  -- Front
                   targetPosition + Vector3.new(0, 0, -0.5)  -- Back
               }
               
               for _, point in ipairs(checkPoints) do
                   local ray = Ray.new(sourcePosition, point - sourcePosition)
                   local hit, hitPosition = workspace:FindPartOnRayWithIgnoreList(
                       ray,
                       {LocalPlayer.Character, Camera, workspace:FindFirstChild("Ignore")},
                       false,
                       true
                   )
                   
                   if hit then
                       local distanceToHit = (hitPosition - sourcePosition).Magnitude
                       local distanceToPoint = (point - sourcePosition).Magnitude
                       
                       -- If any point is visible, consider the target partially visible
                       if math.abs(distanceToHit - distanceToPoint) < 5 then
                           return true
                       end
                   else
                       return true
                   end
               end
               
               return false
           end
           
           -- Function to calculate angle to target
           local function getTargetAngle(targetPosition)
               local playerChar = LocalPlayer.Character
               if not playerChar or not playerChar:FindFirstChild("HumanoidRootPart") then return MAX_ANGLE end
               
               local lookVector = Camera.CFrame.LookVector
               local toTarget = (targetPosition - Camera.CFrame.Position).Unit
               
               return math.acos(lookVector:Dot(toTarget))
           end
           
           -- Enhanced priority calculation
           local function calculateTargetPriority(distance, isVisible, health, angle)
               local score = 0
               
               -- Base distance score (higher for closer targets)
               score = score + (ASSIST_RANGE - distance) * 10
               
               -- Massive bonus for close range targets
               if distance < CLOSE_RANGE then
                   score = score + 10000  -- Huge priority boost for close targets
                   
                   -- Additional boost for close targets in front of player
                   if angle < CLOSE_ANGLE then
                       score = score + 5000
                   end
               end
               
               -- Visibility bonus
               if isVisible then
                   score = score + 3000
                   
                   -- Extra bonus for visible targets in close range
                   if distance < CLOSE_RANGE then
                       score = score + 7000
                   end
               end
               
               -- Angle priority (favor targets more in front of player)
               local anglePriority = (MAX_ANGLE - angle) * 1000
               score = score + anglePriority
               
               -- Health consideration (slight preference for lower health targets)
               score = score + (100 - health) * 10
               
               return score
           end
           
           -- Function to check if a character is valid target
           local function isValidTarget(character, player)
               if not character then return false end
               
               local humanoid = character:FindFirstChild("Humanoid")
               local head = character:FindFirstChild("Head")
               
               if player then
                   if isTeammate(player) then return false end
               end
               
               return humanoid 
                   and head 
                   and humanoid.Health > 0
           end
           
           -- Enhanced target selection
           local function getBestTarget()
               local targets = {}
               local playerChar = LocalPlayer.Character
               local playerHead = playerChar and playerChar:FindFirstChild("Head")
               
               if not playerHead then return nil end
               
               for _, player in pairs(Players:GetPlayers()) do
                   if player ~= LocalPlayer then
                       local character = player.Character
                       if isValidTarget(character, player) then
                           local targetHead = character.Head
                           local distance = (playerHead.Position - targetHead.Position).Magnitude
                           
                           if distance < ASSIST_RANGE then
                               local angle = getTargetAngle(targetHead.Position)
                               local isVisible = isTargetVisible(targetHead.Position, playerHead.Position)
                               local health = character.Humanoid.Health
                               
                               -- Consider all close range targets, visible or not
                               if distance < CLOSE_RANGE or isVisible or distance < WALL_CHECK_RANGE then
                                   table.insert(targets, {
                                       character = character,
                                       distance = distance,
                                       priority = calculateTargetPriority(distance, isVisible, health, angle)
                                   })
                               end
                           end
                       end
                   end
               end
               
               table.sort(targets, function(a, b)
                   return a.priority > b.priority
               end)
               
               return targets[1] and targets[1].character or nil
           end
           
           -- Smoother aim function
           local function updateAim()
               local target = getBestTarget()
               if not target then return end
               
               local targetHead = target.Head
               local aimPosition = targetHead.Position + HEAD_OFFSET
               local playerChar = LocalPlayer.Character
               
               if playerChar and playerChar:FindFirstChild("Head") then
                   local aimAt = CFrame.lookAt(
                       Camera.CFrame.Position,
                       aimPosition
                   )
                   
                   -- Dynamic smoothing based on distance
                   local distance = (playerChar.Head.Position - targetHead.Position).Magnitude
                   local smoothness
                   
                   if distance < CLOSE_RANGE then
                       smoothness = 0.6  -- Faster tracking for very close targets
                   else
                       smoothness = math.clamp(0.2 + (distance / ASSIST_RANGE) * 0.3, 0.2, 0.4)
                   end
                   
                   Camera.CFrame = Camera.CFrame:Lerp(aimAt, smoothness)
               end
           end
           
           -- Connect update function
           _G.AimAssistConnection = RunService.RenderStepped:Connect(updateAim)
           
       else
           -- Cleanup when toggled off
           if _G.AimAssistConnection then
               _G.AimAssistConnection:Disconnect()
               _G.AimAssistConnection = nil
           end
       end
   end
})

local Toggle = MainTab:CreateToggle({
   Name = "Xray-visual",
   CurrentValue = false,
   Flag = "Toggle1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
   Callback = function(Value)
          local Players = game:GetService("Players")

for _, part in ipairs(game.Workspace:GetDescendants()) do
    if part:IsA("BasePart") then
        local parentModel = part.Parent
        local isPlayerCharacter = false

        -- Verificar se pertence a um jogador
        if parentModel and parentModel:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(parentModel)
            if player then
                isPlayerCharacter = true
            end
        end

        -- Aplicar transparência apenas se não for de um jogador e não for parte da UI
        if not isPlayerCharacter then
            part.Transparency = 0.3 -- Torna semi-transparente
        end
    end
end
   end,
})

-- For Arsenal specifically:
local InfiniteJumpEnabled = false
local Toggle = MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(Value)
        InfiniteJumpEnabled = Value
    end,
})

-- Try a more aggressive approach for Arsenal
game:GetService("UserInputService").JumpRequest:connect(function()
    if InfiniteJumpEnabled then
        -- Try direct CFrame manipulation instead
        local character = game:GetService("Players").LocalPlayer.Character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 5, 0)
            end
        end
    end
end)

-- Try velocity-based approach for walkspeed
local WalkspeedValue = 16
local Slider = MainTab:CreateSlider({
    Name = "Walkspeed",
    Range = {16, 250},
    Increment = 10,
    Suffix = "Walkspeed",
    CurrentValue = 16,
    Flag = "WalkspeedSlider",
    Callback = function(Value)
        WalkspeedValue = Value
    end,
})

-- Try a loop that uses velocity manipulation instead
spawn(function()
    while wait() do
        local character = game.Players.LocalPlayer.Character
        if character and InfiniteJumpEnabled then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local direction = game:GetService("UserInputService"):GetMovementVector()
                if direction.Magnitude > 0 then
                    local velocity = direction * WalkspeedValue
                    hrp.Velocity = Vector3.new(velocity.X, hrp.Velocity.Y, velocity.Z)
                end
            end
        end
    end
end)

local Button = MainTab:CreateButton({
   Name = "Enhanced Studio View",
   Callback = function()
       -- Toggle state variable
       _G.StudioViewEnabled = not (_G.StudioViewEnabled or false)
       
       -- Clean up existing UI if present
       local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
       if playerGui and playerGui:FindFirstChild("StudioExplorer") then
           playerGui.StudioExplorer:Destroy()
       end
       
       if _G.StudioViewEnabled then
           -- Create a more comprehensive studio explorer
           local screenGui = Instance.new("ScreenGui")
           screenGui.Name = "StudioExplorer"
           screenGui.ResetOnSpawn = false
           screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
           screenGui.Parent = playerGui
           
           -- Main frame
           local mainFrame = Instance.new("Frame")
           mainFrame.Name = "MainFrame"
           mainFrame.Size = UDim2.new(0.4, 0, 0.8, 0)
           mainFrame.Position = UDim2.new(0.6, -10, 0.1, 0)
           mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
           mainFrame.BorderSizePixel = 2
           mainFrame.Parent = screenGui
           
           -- Make the main frame draggable
           local isDragging = false
           local dragInput
           local dragStart
           local startPos
           
           mainFrame.InputBegan:Connect(function(input)
               if input.UserInputType == Enum.UserInputType.MouseButton1 then
                   isDragging = true
                   dragStart = input.Position
                   startPos = mainFrame.Position
               end
           end)
           
           mainFrame.InputEnded:Connect(function(input)
               if input.UserInputType == Enum.UserInputType.MouseButton1 then
                   isDragging = false
               end
           end)
           
           game:GetService("UserInputService").InputChanged:Connect(function(input)
               if input.UserInputType == Enum.UserInputType.MouseMovement and isDragging then
                   local delta = input.Position - dragStart
                   mainFrame.Position = UDim2.new(
                       startPos.X.Scale,
                       startPos.X.Offset + delta.X,
                       startPos.Y.Scale,
                       startPos.Y.Offset + delta.Y
                   )
               end
           end)
           
           -- Title bar
           local titleBar = Instance.new("Frame")
           titleBar.Name = "TitleBar"
           titleBar.Size = UDim2.new(1, 0, 0.05, 0)
           titleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
           titleBar.BorderSizePixel = 0
           titleBar.Parent = mainFrame
           
           local titleText = Instance.new("TextLabel")
           titleText.Name = "Title"
           titleText.Size = UDim2.new(1, -30, 1, 0)
           titleText.Position = UDim2.new(0, 10, 0, 0)
           titleText.BackgroundTransparency = 1
           titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
           titleText.TextXAlignment = Enum.TextXAlignment.Left
           titleText.Text = "Enhanced Explorer"
           titleText.Font = Enum.Font.SourceSansBold
           titleText.TextSize = 16
           titleText.Parent = titleBar
           
           -- Close button
           local closeButton = Instance.new("TextButton")
           closeButton.Name = "CloseButton"
           closeButton.Size = UDim2.new(0, 20, 0, 20)
           closeButton.Position = UDim2.new(1, -25, 0.5, -10)
           closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
           closeButton.Text = "X"
           closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
           closeButton.Font = Enum.Font.SourceSansBold
           closeButton.TextSize = 14
           closeButton.Parent = titleBar
           
           closeButton.MouseButton1Click:Connect(function()
               screenGui:Destroy()
               _G.StudioViewEnabled = false
               print("Enhanced Studio View disabled")
           end)
           
           -- Tab buttons for different views
           local tabFrame = Instance.new("Frame")
           tabFrame.Name = "TabFrame"
           tabFrame.Size = UDim2.new(1, 0, 0.05, 0)
           tabFrame.Position = UDim2.new(0, 0, 0.05, 0)
           tabFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
           tabFrame.BorderSizePixel = 0
           tabFrame.Parent = mainFrame
           
           -- Create tabs
           local tabs = {"Explorer", "Scripts", "Leaderstats", "Output", "Properties"}
           local tabButtons = {}
           local tabWidth = 1 / #tabs
           
           for i, tabName in ipairs(tabs) do
               local tabButton = Instance.new("TextButton")
               tabButton.Name = tabName .. "Tab"
               tabButton.Size = UDim2.new(tabWidth, 0, 1, 0)
               tabButton.Position = UDim2.new((i-1) * tabWidth, 0, 0, 0)
               tabButton.BackgroundColor3 = (i == 1) and Color3.fromRGB(70, 70, 70) or Color3.fromRGB(50, 50, 50)
               tabButton.BorderSizePixel = 0
               tabButton.Text = tabName
               tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
               tabButton.Font = Enum.Font.SourceSans
               tabButton.TextSize = 14
               tabButton.Parent = tabFrame
               
               tabButtons[tabName] = tabButton
           end
           
           -- Content frame for the main view
           local contentFrame = Instance.new("Frame")
           contentFrame.Name = "ContentFrame"
           contentFrame.Size = UDim2.new(1, 0, 0.9, 0)
           contentFrame.Position = UDim2.new(0, 0, 0.1, 0)
           contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
           contentFrame.BorderSizePixel = 0
           contentFrame.Parent = mainFrame
           
           -- Different content frames for each tab
           local explorerFrame = Instance.new("ScrollingFrame")
           explorerFrame.Name = "ExplorerFrame"
           explorerFrame.Size = UDim2.new(1, 0, 1, 0)
           explorerFrame.BackgroundTransparency = 1
           explorerFrame.BorderSizePixel = 0
           explorerFrame.ScrollBarThickness = 6
           explorerFrame.CanvasSize = UDim2.new(0, 0, 10, 0)
           explorerFrame.Visible = true
           explorerFrame.Parent = contentFrame
           
           local scriptsFrame = Instance.new("ScrollingFrame")
           scriptsFrame.Name = "ScriptsFrame"
           scriptsFrame.Size = UDim2.new(1, 0, 1, 0)
           scriptsFrame.BackgroundTransparency = 1
           scriptsFrame.BorderSizePixel = 0
           scriptsFrame.ScrollBarThickness = 6
           scriptsFrame.CanvasSize = UDim2.new(0, 0, 10, 0)
           scriptsFrame.Visible = false
           scriptsFrame.Parent = contentFrame
           
           local leaderstatsFrame = Instance.new("ScrollingFrame")
           leaderstatsFrame.Name = "LeaderstatsFrame"
           leaderstatsFrame.Size = UDim2.new(1, 0, 1, 0)
           leaderstatsFrame.BackgroundTransparency = 1
           leaderstatsFrame.BorderSizePixel = 0
           leaderstatsFrame.ScrollBarThickness = 6
           leaderstatsFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
           leaderstatsFrame.Visible = false
           leaderstatsFrame.Parent = contentFrame
           
           local outputFrame = Instance.new("ScrollingFrame")
           outputFrame.Name = "OutputFrame"
           outputFrame.Size = UDim2.new(1, 0, 1, 0)
           outputFrame.BackgroundTransparency = 1
           outputFrame.BorderSizePixel = 0
           outputFrame.ScrollBarThickness = 6
           outputFrame.CanvasSize = UDim2.new(0, 0, 10, 0)
           outputFrame.Visible = false
           outputFrame.Parent = contentFrame
           
           local propertiesFrame = Instance.new("ScrollingFrame")
           propertiesFrame.Name = "PropertiesFrame"
           propertiesFrame.Size = UDim2.new(1, 0, 1, 0)
           propertiesFrame.BackgroundTransparency = 1
           propertiesFrame.BorderSizePixel = 0
           propertiesFrame.ScrollBarThickness = 6
           propertiesFrame.CanvasSize = UDim2.new(0, 0, 2, 0)
           propertiesFrame.Visible = false
           propertiesFrame.Parent = contentFrame
           
           -- Tab switching functionality
           local contentFrames = {
               Explorer = explorerFrame,
               Scripts = scriptsFrame,
               Leaderstats = leaderstatsFrame,
               Output = outputFrame,
               Properties = propertiesFrame
           }
           
           for name, button in pairs(tabButtons) do
               button.MouseButton1Click:Connect(function()
                   -- Update button colors
                   for _, btn in pairs(tabButtons) do
                       btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                   end
                   button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                   
                   -- Show selected frame, hide others
                   for frameName, frame in pairs(contentFrames) do
                       frame.Visible = (frameName == name)
                   end
               end)
           end
           
           -- Global variables for selected object and script display
           _G.SelectedInstance = nil
           local scriptDisplay = nil
           
           -- Function to read script content
           local function getScriptSource(script)
               local success, source = pcall(function()
                   -- Try to get the script source
                   if script:IsA("LocalScript") or script:IsA("Script") or script:IsA("ModuleScript") then
                       return decompile(script)
                   end
                   return "Cannot read script source"
               end)
               
               if success then
                   return source or "Empty script"
               else
                   return "Failed to read script: " .. tostring(source)
               end
           end
           
           -- Function to display script contents
           local function displayScriptContents(script)
               -- Clear existing content
               if scriptDisplay then
                   scriptDisplay:Destroy()
               end
               
               -- Create script display frame
               scriptDisplay = Instance.new("Frame")
               scriptDisplay.Name = "ScriptDisplay"
               scriptDisplay.Size = UDim2.new(1, -10, 1, -10)
               scriptDisplay.Position = UDim2.new(0, 5, 0, 5)
               scriptDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
               scriptDisplay.BorderSizePixel = 1
               scriptDisplay.Parent = scriptsFrame
               
               -- Script title
               local titleLabel = Instance.new("TextLabel")
               titleLabel.Size = UDim2.new(1, 0, 0, 25)
               titleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
               titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
               titleLabel.Text = script.Name .. " [" .. script.ClassName .. "]"
               titleLabel.Font = Enum.Font.SourceSansBold
               titleLabel.TextSize = 16
               titleLabel.Parent = scriptDisplay
               
               -- Script content
               local contentBox = Instance.new("ScrollingFrame")
               contentBox.Size = UDim2.new(1, 0, 1, -25)
               contentBox.Position = UDim2.new(0, 0, 0, 25)
               contentBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
               contentBox.BorderSizePixel = 0
               contentBox.ScrollBarThickness = 6
               contentBox.CanvasSize = UDim2.new(0, 0, 5, 0)
               contentBox.Parent = scriptDisplay
               
               local sourceText = Instance.new("TextLabel")
               sourceText.Size = UDim2.new(1, -10, 0, 5000) -- Tall enough for most scripts
               sourceText.Position = UDim2.new(0, 5, 0, 5)
               sourceText.BackgroundTransparency = 1
               sourceText.TextColor3 = Color3.fromRGB(200, 200, 200)
               sourceText.TextXAlignment = Enum.TextXAlignment.Left
               sourceText.TextYAlignment = Enum.TextYAlignment.Top
               sourceText.TextSize = 14
               sourceText.Font = Enum.Font.Code
               sourceText.Text = getScriptSource(script)
               sourceText.Parent = contentBox
               
               -- Adjust canvas size based on content
               local textHeight = string.len(sourceText.Text) / 40 * 20 -- Approximate height
               contentBox.CanvasSize = UDim2.new(0, 0, 0, math.max(500, textHeight))
           end
           
           -- Function to collect and display all scripts in the game
           local function collectAllScripts()
               -- Clear existing content
               for _, child in pairs(scriptsFrame:GetChildren()) do
                   child:Destroy()
               end
               
               -- Create list layout
               local scriptsList = Instance.new("ScrollingFrame")
               scriptsList.Name = "ScriptsList"
               scriptsList.Size = UDim2.new(0.4, 0, 1, 0)
               scriptsList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
               scriptsList.BorderSizePixel = 1
               scriptsList.ScrollBarThickness = 6
               scriptsList.CanvasSize = UDim2.new(0, 0, 10, 0)
               scriptsList.Parent = scriptsFrame
               
               local scriptsTitle = Instance.new("TextLabel")
               scriptsTitle.Size = UDim2.new(1, 0, 0, 25)
               scriptsTitle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
               scriptsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
               scriptsTitle.Text = "All Scripts"
               scriptsTitle.Font = Enum.Font.SourceSansBold
               scriptsTitle.TextSize = 16
               scriptsTitle.Parent = scriptsList
               
               -- Content placeholder
               local contentFrame = Instance.new("Frame")
               contentFrame.Name = "ScriptContent"
               contentFrame.Size = UDim2.new(0.6, 0, 1, 0)
               contentFrame.Position = UDim2.new(0.4, 0, 0, 0)
               contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
               contentFrame.BorderSizePixel = 1
               contentFrame.Parent = scriptsFrame
               
               local placeholderText = Instance.new("TextLabel")
               placeholderText.Size = UDim2.new(1, -10, 0, 30)
               placeholderText.Position = UDim2.new(0, 5, 0, 5)
               placeholderText.BackgroundTransparency = 1
               placeholderText.TextColor3 = Color3.fromRGB(200, 200, 200)
               placeholderText.Text = "Select a script to view its contents"
               placeholderText.Font = Enum.Font.SourceSans
               placeholderText.TextSize = 16
               placeholderText.Parent = contentFrame
               
               -- Collect all scripts
               local allScripts = {}
               
               -- Function to find all scripts
               local function findScriptsIn(parent)
                   for _, child in pairs(parent:GetChildren()) do
                       if child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript") then
                           table.insert(allScripts, child)
                       end
                       findScriptsIn(child)
                   end
               end
               
               -- Find scripts in common locations
               findScriptsIn(game:GetService("Workspace"))
               findScriptsIn(game:GetService("ReplicatedStorage"))
               pcall(function() findScriptsIn(game:GetService("ReplicatedFirst")) end)
               pcall(function() findScriptsIn(game:GetService("ServerScriptService")) end)
               pcall(function() findScriptsIn(game:GetService("ServerStorage")) end)
               findScriptsIn(game:GetService("StarterGui"))
               findScriptsIn(game:GetService("StarterPack"))
               findScriptsIn(game:GetService("StarterPlayer"))
               
               -- Sort scripts by name
               table.sort(allScripts, function(a, b)
                   return a.Name < b.Name
               end)
               
               -- Display scripts
               local yPos = 30
               for i, script in ipairs(allScripts) do
                   local scriptButton = Instance.new("TextButton")
                   scriptButton.Size = UDim2.new(1, -10, 0, 25)
                   scriptButton.Position = UDim2.new(0, 5, 0, yPos)
                   scriptButton.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                   scriptButton.TextColor3 = Color3.fromRGB(220, 220, 220)
                   scriptButton.TextXAlignment = Enum.TextXAlignment.Left
                   scriptButton.Text = "  " .. script.Name
                   
                   -- Add icon to indicate script type
                   local iconText
                   if script:IsA("Script") then
                       iconText = "🔧 " -- Server script
                       scriptButton.TextColor3 = Color3.fromRGB(150, 255, 150)
                   elseif script:IsA("LocalScript") then
                       iconText = "🖥️ " -- Local script
                       scriptButton.TextColor3 = Color3.fromRGB(150, 150, 255)
                   else -- ModuleScript
                       iconText = "📦 " -- Module
                       scriptButton.TextColor3 = Color3.fromRGB(255, 255, 150)
                   end
                   
                   scriptButton.Text = iconText .. script.Name .. " (" .. script.ClassName .. ")"
                   scriptButton.Font = Enum.Font.SourceSans
                   scriptButton.TextSize = 14
                   
                   -- Path information
                   local pathInfo = Instance.new("TextLabel")
                   pathInfo.Size = UDim2.new(1, -10, 0, 15)
                   pathInfo.Position = UDim2.new(0, 25, 0, 20)
                   pathInfo.BackgroundTransparency = 1
                   pathInfo.TextColor3 = Color3.fromRGB(180, 180, 180)
                   pathInfo.TextXAlignment = Enum.TextXAlignment.Left
                   pathInfo.Text = "Path: " .. script:GetFullName()
                   pathInfo.Font = Enum.Font.SourceSansItalic
                   pathInfo.TextSize = 12
                   pathInfo.Parent = scriptButton
                   
                   -- Connect click event
                   scriptButton.MouseButton1Click:Connect(function()
                       displayScriptContents(script)
                   end)
                   
                   scriptButton.Parent = scriptsList
                   
                   yPos = yPos + 45
               end
               
               -- Update canvas size
               scriptsList.CanvasSize = UDim2.new(0, 0, 0, yPos + 10)
               
               -- Print script count to output
               print("Found " .. #allScripts .. " scripts in the game")
           end
           
           -- Populate explorer view
           local services = {
               game:GetService("Workspace"),
               game:GetService("Players"),
               game:GetService("ReplicatedStorage"),
               game:GetService("ReplicatedFirst"),
               game:GetService("ServerStorage"),
               game:GetService("ServerScriptService"),
               game:GetService("StarterGui"),
               game:GetService("StarterPack"),
               game:GetService("StarterPlayer"),
               game:GetService("Lighting"),
               game:GetService("SoundService")
           }
           
           local yOffset = 5
           
           -- Function to create a collapsible service section
           local function createServiceSection(service, yPos)
               local expandable = {}
               
               -- Service header
               local header = Instance.new("Frame")
               header.Name = service.Name .. "Header"
               header.Size = UDim2.new(1, -10, 0, 25)
               header.Position = UDim2.new(0, 5, 0, yPos)
               header.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
               header.Parent = explorerFrame
               
               local expandButton = Instance.new("TextButton")
               expandButton.Name = "ExpandButton"
               expandButton.Size = UDim2.new(0, 20, 0, 25)
               expandButton.Position = UDim2.new(0, 0, 0, 0)
               expandButton.BackgroundTransparency = 1
               expandButton.Text = "▶"
               expandButton.TextColor3 = Color3.fromRGB(255, 255, 255)
               expandButton.Font = Enum.Font.SourceSansBold
               expandButton.TextSize = 14
               expandButton.Parent = header
               
               local nameLabel = Instance.new("TextLabel")
               nameLabel.Name = "NameLabel"
               nameLabel.Size = UDim2.new(1, -25, 1, 0)
               nameLabel.Position = UDim2.new(0, 25, 0, 0)
               nameLabel.BackgroundTransparency = 1
               nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
               nameLabel.TextXAlignment = Enum.TextXAlignment.Left
               nameLabel.Text = service.Name
               nameLabel.Font = Enum.Font.SourceSansBold
               nameLabel.TextSize = 14
               nameLabel.Parent = header
               
               -- Container for child items
               local childContainer = Instance.new("Frame")
               childContainer.Name = service.Name .. "Children"
               childContainer.Size = UDim2.new(1, -10, 0, 0)  -- Height will be set based on content
               childContainer.Position = UDim2.new(0, 5, 0, yPos + 27)
               childContainer.BackgroundTransparency = 1
               childContainer.Visible = false
               childContainer.Parent = explorerFrame
               
               -- Recursive function to create expandable items
               local function createExpandableItem(item, xPos, yPos, container)
                   local itemExpanded = false
                   local childrenContainer = nil
                   
                   local itemFrame = Instance.new("Frame")
                   itemFrame.Size = UDim2.new(1, -xPos, 0, 20)
                   itemFrame.Position = UDim2.new(0, xPos, 0, yPos)
                   itemFrame.BackgroundTransparency = 1
                   itemFrame.Parent = container
                   
                   local expandBtn = nil
                   
                   -- Only add expand button if the item has children
                   if #item:GetChildren() > 0 then
                       expandBtn = Instance.new("TextButton")
                       expandBtn.Size = UDim2.new(0, 20, 0, 20)
                       expandBtn.Position = UDim2.new(0, 0, 0, 0)
                       expandBtn.BackgroundTransparency = 1
                       expandBtn.Text = "▶"
                       expandBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                       expandBtn.Font = Enum.Font.SourceSansBold
                       expandBtn.TextSize = 14
                       expandBtn.Parent = itemFrame
                   end
                   
                   -- Item icon based on class
                   local iconLabel = Instance.new("TextLabel")
                   iconLabel.Size = UDim2.new(0, 20, 0, 20)
                   iconLabel.Position = UDim2.new(0, expandBtn and 20 or 0, 0, 0)
                   iconLabel.BackgroundTransparency = 1
                   iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                   
                   -- Set icon based on class
                   if item:IsA("Folder") then
                       iconLabel.Text = "📁"
                   elseif item:IsA("Script") then
                       iconLabel.Text = "🔧"
                       iconLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
                   elseif item:IsA("LocalScript") then
                       iconLabel.Text = "🖥️"
                       iconLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
                   elseif item:IsA("ModuleScript") then
                       iconLabel.Text = "📦"
                       iconLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
                   elseif item:IsA("Part") or item:IsA("MeshPart") then
                       iconLabel.Text = "⬛"
                   elseif item:IsA("Model") then
                       iconLabel.Text = "🔷"
                   else
                       iconLabel.Text = "🔹"
                   end
                   
                   iconLabel.Font = Enum.Font.SourceSans
                   iconLabel.TextSize = 14
                   iconLabel.Parent = itemFrame
                   
                   -- Item name label
                   local nameLabel = Instance.new("TextButton")
                   nameLabel.Size = UDim2.new(1, -(expandBtn and 40 or 20), 1, 0)
                   nameLabel.Position = UDim2.new(0, expandBtn and 40 or 20, 0, 0)
                   nameLabel.BackgroundTransparency = 1
                   nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                   nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                   nameLabel.Text = item.Name .. " [" .. item.ClassName .. "]"
                   nameLabel.Font = Enum.Font.SourceSans
                   nameLabel.TextSize = 14
                   nameLabel.Parent = itemFrame
                   
                   -- Selected item highlighting
                   nameLabel.MouseButton1Click:Connect(function()
                       -- Deselect previous selection if exists
                       if _G.SelectedInstance and _G.SelectedInstance._namelabel then
                           _G.SelectedInstance._namelabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                           _G.SelectedInstance._namelabel.Font = Enum.Font.SourceSans
                       end
                       
                       -- Select this item
                       _G.SelectedInstance = item
                       _G.SelectedInstance._namelabel = nameLabel
                       nameLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
                       nameLabel.Font = Enum.Font.SourceSansBold
                       
                       -- Show properties if relevant
                       if tabButtons["Properties"] then
                           tabButtons["Properties"]:GetPropertyChangedSignal("BackgroundColor3"):Wait()
                           populateProperties(item)
                       end
                       
                       -- If script, show in script tab
                       if item:IsA("Script") or item:IsA("LocalScript") or item:IsA("ModuleScript") then
                           if tabButtons["Scripts"] then
                               tabButtons["Scripts"]:GetPropertyChangedSignal("BackgroundColor3"):Wait()
                               displayScriptContents(item)
                           end
                       end
                   end)
                   
                   local childHeight = 0
                   
                   -- Handle expand functionality if item has children
                   if expandBtn then
                       expandBtn.MouseButton1Click:Connect(function()
                           itemExpanded = not itemExpanded
                           expandBtn.Text = itemExpanded and "▼" or "▶"
                           
                           if itemExpanded then
                               -- Create children container if not exists
                               if not childrenContainer then
                                   childrenContainer = Instance.new("Frame")
                                   childrenContainer.Name = item.Name .. "Children"
                                   childrenContainer.Size = UDim2.new(1, 0, 0, 0)
                                   childrenContainer.Position = UDim2.new(0, 0, 0, 20)
                                   childrenContainer.BackgroundTransparency = 1
                                   childrenContainer.Parent = itemFrame
                                   
                                   -- Populate children
                                   local childYPos = 0
                                   local childItems = {}
                                   
                                   -- Sort children: folders first, then other items
                                   for _, child in pairs(item:GetChildren()) do
                                       table.insert(childItems, child)
                                   end
                                   
                                   table.sort(childItems, function(a, b)
                                       local aIsContainer = a:IsA("Folder") or a:IsA("Model")
                                       local bIsContainer = b:IsA("Folder") or b:IsA("Model")
                                       
                                       if aIsContainer and not bIsContainer then
                                           return true
                                       elseif not aIsContainer and bIsContainer then
                                           return false
                                       else
                                           return a.Name < b.Name
                                       end
                                   end)
                                   
                                   for _, child in ipairs(childItems) do
                                       local newChildHeight = createExpandableItem(child, 20, childYPos, childrenContainer)
                                       childYPos = childYPos + newChildHeight
                                   end
                                   
                                   childHeight = childYPos
                                   childrenContainer.Size = UDim2.new(1, 0, 0, childHeight)
                               end
                               
                               childrenContainer.Visible = true
                           else
                               if childrenContainer then
                                   childrenContainer.Visible = false
                               end
                           end
                           
                           -- Recalculate heights for parent containers
                           local totalHeight = 20 + (itemExpanded and childHeight or 0)
                           itemFrame.Size = UDim2.new(1, -xPos, 0, totalHeight)
                           
                           -- Trigger recalculation up the chain
                           container:GetPropertyChangedSignal("Size"):Fire()
                       end)
                   end
                   
                   return 20 -- Default height for unexpanded item
               end
               
               -- Populate children of service
               local yOffset = 0
               local children = {}
               
               -- Get all children of service
               pcall(function()
                   for _, child in pairs(service:GetChildren()) do
                       table.insert(children, child)
                   end
               end)
               
               -- Sort children: folders first, then other items
               table.sort(children, function(a, b)
                   local aIsContainer = a:IsA("Folder") or a:IsA("Model")
                   local bIsContainer = b:IsA("Folder") or b:IsA("Model")
                   
                   if aIsContainer and not bIsContainer then
                       return true
                   elseif not aIsContainer and bIsContainer then
                       return false
                   else
                       return a.Name < b.Name
                   end
               end)
               
               -- Create items for each child
               for _, child in ipairs(children) do
                   local childHeight = createExpandableItem(child, 10, yOffset, childContainer)
                   yOffset = yOffset + childHeight
               end
               
               childContainer.Size = UDim2.new(1, -10, 0, yOffset)
               
               -- Toggle expand/collapse on click
               local expanded = false
               expandButton.MouseButton1Click:Connect(function()
                   expanded = not expanded
                   expandButton.Text = expanded and "▼" or "▶"
                   childContainer.Visible = expanded
                   
                   -- Recalculate explorer frame canvas size
                   recalculateExplorerCanvas()
               end)
               
               expandable.header = header
               expandable.container = childContainer
               expandable.expanded = expanded
               
               return expandable, 27 -- Return height of header
           end
           
           -- Function to recalculate explorer canvas size
           function recalculateExplorerCanvas()
               local totalHeight = 5
               
               for _, child in pairs(explorerFrame:GetChildren()) do
                   if child:IsA("Frame") and child.Name:find("Header") then
                       totalHeight = totalHeight + child.Size.Y.Offset
                       
                       local childContainer = explorerFrame:FindFirstChild(child.Name:gsub("Header", "Children"))
                       if childContainer and childContainer.Visible then
                           totalHeight = totalHeight + childContainer.Size.Y.Offset
                       end
                   end
               end
               
               explorerFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 10)
           end
           
           -- Function to populate properties panel
           function populateProperties(instance)
               -- Clear existing properties
               for _, child in pairs(propertiesFrame:GetChildren()) do
                   child:Destroy()
               end
               
               -- Instance info header
               local header = Instance.new("Frame")
               header.Name = "InstanceHeader"
               header.Size = UDim2.new(1, -10, 0, 40)
               header.Position = UDim2.new(0, 5, 0, 5)
               header.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
               header.BorderSizePixel = 0
               header.Parent = propertiesFrame
               
               local instanceName = Instance.new("TextLabel")
               instanceName.Size = UDim2.new(1, -10, 0, 20)
               instanceName.Position = UDim2.new(0, 5, 0, 5)
               instanceName.BackgroundTransparency = 1
               instanceName.TextColor3 = Color3.fromRGB(255, 255, 150)
               instanceName.TextXAlignment = Enum.TextXAlignment.Left
               instanceName.Text = instance.Name
               instanceName.Font = Enum.Font.SourceSansBold
               instanceName.TextSize = 16
               instanceName.Parent = header
               
               local instanceClass = Instance.new("TextLabel")
               instanceClass.Size = UDim2.new(1, -10, 0, 15)
               instanceClass.Position = UDim2.new(0, 5, 0, 22)
               instanceClass.BackgroundTransparency = 1
               instanceClass.TextColor3 = Color3.fromRGB(200, 200, 200)
               instanceClass.TextXAlignment = Enum.TextXAlignment.Left
               instanceClass.Text = "Class: " .. instance.ClassName
               instanceClass.Font = Enum.Font.SourceSans
               instanceClass.TextSize = 14
               instanceClass.Parent = header
               
               -- Properties list
               local yPos = 50
               local properties = {}
               
               -- Get all properties
               for _, propertyName in pairs({"Name", "Parent", "Position", "Size", "CFrame", "BrickColor", "Material", "Transparency", "CanCollide", "Anchored", "Massless"}) do
                   -- Check if property exists
                   local success, value = pcall(function()
                       return instance[propertyName]
                   end)
                   
                   if success then
                       table.insert(properties, {
                           name = propertyName,
                           value = value
                       })
                   end
               end
               
               -- Sort properties alphabetically
               table.sort(properties, function(a, b)
                   return a.name < b.name
               end)
               
               -- Display properties
               for _, property in ipairs(properties) do
                   local propFrame = Instance.new("Frame")
                   propFrame.Size = UDim2.new(1, -10, 0, 25)
                   propFrame.Position = UDim2.new(0, 5, 0, yPos)
                   propFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                   propFrame.BorderSizePixel = 0
                   propFrame.Parent = propertiesFrame
                   
                   local propName = Instance.new("TextLabel")
                   propName.Size = UDim2.new(0.4, -5, 1, 0)
                   propName.BackgroundTransparency = 1
                   propName.TextColor3 = Color3.fromRGB(200, 200, 255)
                   propName.TextXAlignment = Enum.TextXAlignment.Left
                   propName.Text = "  " .. property.name
                   propName.Font = Enum.Font.SourceSans
                   propName.TextSize = 14
                   propName.Parent = propFrame
                   
                   local propValue = Instance.new("TextLabel")
                   propValue.Size = UDim2.new(0.6, 0, 1, 0)
                   propValue.Position = UDim2.new(0.4, 0, 0, 0)
                   propValue.BackgroundTransparency = 1
                   propValue.TextColor3 = Color3.fromRGB(255, 255, 255)
                   propValue.TextXAlignment = Enum.TextXAlignment.Left
                   
                   -- Format value based on type
                   local valueText
                   if typeof(property.value) == "Color3" then
                       valueText = string.format("RGB(%d, %d, %d)", 
                           math.floor(property.value.R * 255), 
                           math.floor(property.value.G * 255), 
                           math.floor(property.value.B * 255))
                   elseif typeof(property.value) == "Vector3" then
                       valueText = string.format("(%.2f, %.2f, %.2f)", 
                           property.value.X, property.value.Y, property.value.Z)
                   elseif typeof(property.value) == "UDim2" then
                       valueText = string.format("{%d, %d}, {%d, %d}", 
                           property.value.X.Scale, property.value.X.Offset, 
                           property.value.Y.Scale, property.value.Y.Offset)
                   elseif typeof(property.value) == "Instance" then
                       valueText = property.value.Name
                   elseif typeof(property.value) == "boolean" then
                       valueText = property.value and "true" or "false"
                       propValue.TextColor3 = property.value and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
                   elseif typeof(property.value) == "EnumItem" then
                       valueText = tostring(property.value)
                   else
                       valueText = tostring(property.value)
                   end
                   
                   propValue.Text = valueText
                   propValue.Font = Enum.Font.SourceSans
                   propValue.TextSize = 14
                   propValue.Parent = propFrame
                   
                   yPos = yPos + 27
               end
               
               -- Update canvas size
               propertiesFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 10)
           end
           
           -- Function to populate leaderstats view
           local function populateLeaderstats()
               -- Clear existing items
               for _, child in pairs(leaderstatsFrame:GetChildren()) do
                   child:Destroy()
               end
               
               local yPos = 5
               
               -- Title
               local title = Instance.new("TextLabel")
               title.Size = UDim2.new(1, -10, 0, 30)
               title.Position = UDim2.new(0, 5, 0, yPos)
               title.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
               title.TextColor3 = Color3.fromRGB(255, 255, 255)
               title.Text = "Player Leaderstats"
               title.Font = Enum.Font.SourceSansBold
               title.TextSize = 18
               title.Parent = leaderstatsFrame
               
               yPos = yPos + 35
               
               -- Headers
               local headerFrame = Instance.new("Frame")
               headerFrame.Size = UDim2.new(1, -10, 0, 25)
               headerFrame.Position = UDim2.new(0, 5, 0, yPos)
               headerFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
               headerFrame.Parent = leaderstatsFrame
               
               local playerHeader = Instance.new("TextLabel")
               playerHeader.Size = UDim2.new(0.4, -5, 1, 0)
               playerHeader.BackgroundTransparency = 1
               playerHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
               playerHeader.Text = "Player"
               playerHeader.Font = Enum.Font.SourceSansBold
               playerHeader.TextSize = 14
               playerHeader.Parent = headerFrame
               
               local statsHeader = Instance.new("TextLabel")
               statsHeader.Size = UDim2.new(0.6, 0, 1, 0)
               statsHeader.Position = UDim2.new(0.4, 0, 0, 0)
               statsHeader.BackgroundTransparency = 1
               statsHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
               statsHeader.Text = "Statistics"
               statsHeader.Font = Enum.Font.SourceSansBold
               statsHeader.TextSize = 14
               statsHeader.Parent = headerFrame
               
               yPos = yPos + 30
               
               -- Player entries
               for _, player in pairs(game.Players:GetPlayers()) do
                   local playerFrame = Instance.new("Frame")
                   playerFrame.Size = UDim2.new(1, -10, 0, 30)
                   playerFrame.Position = UDim2.new(0, 5, 0, yPos)
                   playerFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                   playerFrame.Parent = leaderstatsFrame
                   
                   local playerName = Instance.new("TextLabel")
                   playerName.Size = UDim2.new(0.4, -5, 1, 0)
                   playerName.BackgroundTransparency = 1
                   playerName.TextColor3 = Color3.fromRGB(200, 200, 255)
                   playerName.TextXAlignment = Enum.TextXAlignment.Left
                   playerName.Text = "  " .. player.Name
                   playerName.Font = Enum.Font.SourceSans
                   playerName.TextSize = 14
                   playerName.Parent = playerFrame
                   
                   local statsText = ""
                   
                   -- Get leaderstats if exists
                   local leaderstats = player:FindFirstChild("leaderstats")
                   if leaderstats then
                       for _, stat in pairs(leaderstats:GetChildren()) do
                           statsText = statsText .. stat.Name .. ": " .. tostring(stat.Value) .. "   "
                       end
                   else
                       statsText = "No leaderstats found"
                   end
                   
                   local statsLabel = Instance.new("TextLabel")
                   statsLabel.Size = UDim2.new(0.6, -5, 1, 0)
                   statsLabel.Position = UDim2.new(0.4, 0, 0, 0)
                   statsLabel.BackgroundTransparency = 1
                   statsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                   statsLabel.TextXAlignment = Enum.TextXAlignment.Left
                   statsLabel.Text = statsText
                   statsLabel.Font = Enum.Font.SourceSans
                   statsLabel.TextSize = 14
                   statsLabel.Parent = playerFrame
                   
                   yPos = yPos + 35
               end
               
               -- Update canvas size
               leaderstatsFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 10)
           end
           
           -- Function to create output panel
           local function setupOutputPanel()
               -- Clear existing items
               for _, child in pairs(outputFrame:GetChildren()) do
                   child:Destroy()
               end
               
               -- Title
               local title = Instance.new("TextLabel")
               title.Size = UDim2.new(1, -10, 0, 30)
               title.Position = UDim2.new(0, 5, 0, 5)
               title.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
               title.TextColor3 = Color3.fromRGB(255, 255, 255)
               title.Text = "Output Log"
               title.Font = Enum.Font.SourceSansBold
               title.TextSize = 18
               title.Parent = outputFrame
               
               -- Output text area
               local textArea = Instance.new("ScrollingFrame")
               textArea.Name = "OutputText"
               textArea.Size = UDim2.new(1, -10, 1, -40)
               textArea.Position = UDim2.new(0, 5, 0, 40)
               textArea.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
               textArea.BorderSizePixel = 1
               textArea.ScrollBarThickness = 6
               textArea.CanvasSize = UDim2.new(0, 0, 10, 0)
               textArea.Parent = outputFrame
               
               -- Log content
               local outputText = Instance.new("TextLabel")
               outputText.Name = "Content"
               outputText.Size = UDim2.new(1, -10, 0, 5000) -- Make it tall for lots of text
               outputText.Position = UDim2.new(0, 5, 0, 5)
               outputText.BackgroundTransparency = 1
               outputText.TextColor3 = Color3.fromRGB(220, 220, 220)
               outputText.TextXAlignment = Enum.TextXAlignment.Left
               outputText.TextYAlignment = Enum.TextYAlignment.Top
               outputText.Text = "Enhanced Studio Explorer activated\n"
               outputText.Font = Enum.Font.Code
               outputText.TextSize = 14
               outputText.Parent = textArea
               
               -- Capture print/warn/error output
               local oldPrint = print
               local oldWarn = warn
               local oldError = error
               
               -- Redirect print
               print = function(...)
                   local args = {...}
                   local message = ""
                   for i, v in ipairs(args) do
                       message = message .. tostring(v) .. (i < #args and " " or "")
                   end
                   
                   outputText.Text = outputText.Text .. "[INFO] " .. message .. "\n"
                   oldPrint(...)
               end
               
               -- Redirect warn
               warn = function(...)
                   local args = {...}
                   local message = ""
                   for i, v in ipairs(args) do
                       message = message .. tostring(v) .. (i < #args and " " or "")
                   end
                   
                   outputText.Text = outputText.Text .. "[WARN] " .. message .. "\n"
                   oldWarn(...)
               end
               
               -- Store original functions for cleanup
               _G.OriginalPrint = oldPrint
               _G.OriginalWarn = oldWarn
               _G.OriginalError = oldError
               
               print("Output panel ready")
           end
           
           -- Initialize explorer view
           for _, service in ipairs(services) do
               pcall(function()
                   local expandable, height = createServiceSection(service, yOffset)
                   yOffset = yOffset + height
               end)
           end
           
           -- Initialize other tabs
           collectAllScripts()  -- Scripts tab
           populateLeaderstats() -- Leaderstats tab
           setupOutputPanel()   -- Output tab
           
           -- Set up auto-refresh for dynamic data
           spawn(function()
               while _G.StudioViewEnabled do
                   if leaderstatsFrame.Visible then
                       populateLeaderstats()
                   end
                   wait(2)
               end
           end)
           
           -- Final canvas size update
           recalculateExplorerCanvas()
           
           print("Enhanced Studio Explorer activated!")
       else
           print("Enhanced Studio View disabled")
       end
   end
})
                              

local TeleportTab = Window:CreateTab("🌀Teleport", nil) -- Title, Image
local TeleportSection = TeleportTab:CreateSection("Teleport")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Create the dropdown
local Dropdown = TeleportTab:CreateDropdown({
    Name = "Teleport to Player",
    Options = {},  -- Will be populated with player names
    CurrentOption = {},
    MultipleOptions = false,
    Flag = "TeleportDropdown",
    Callback = function(Options)
        if #Options > 0 then
            local selectedPlayer = Options[1]
            local targetPlayer = Players:FindFirstChild(selectedPlayer)
            
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                -- Teleport the local player to the selected player
                LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = 
                    targetPlayer.Character.HumanoidRootPart.CFrame
            end
        end
    end,
})

-- Function to update player list
local function UpdatePlayerList()
    local playerNames = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then  -- Don't include local player in the list
            table.insert(playerNames, player.Name)
        end
    end
    Dropdown:Refresh(playerNames, true) -- Update dropdown options
end

-- Update player list when players join or leave
Players.PlayerAdded:Connect(function()
    UpdatePlayerList()
end)

Players.PlayerRemoving:Connect(function()
    UpdatePlayerList()
end)

-- Initial population of player list
UpdatePlayerList()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- Create a table to store our connections
if not _G.TeleportConnections then
    _G.TeleportConnections = {}
end

local Toggle = TeleportTab:CreateToggle({
    Name = "Teleport to Nearest Player",
    CurrentValue = false,
    Flag = "TeleportToggle",
    Callback = function(Value)
        pcall(function()
            if Value then
                -- Clean up any existing connection first
                if _G.TeleportConnections.Teleport then
                    _G.TeleportConnections.Teleport:Disconnect()
                    _G.TeleportConnections.Teleport = nil
                end
                
                -- Create a new connection
                _G.TeleportConnections.Teleport = RunService.Heartbeat:Connect(function()
                    local nearestPlayer = nil
                    local shortestDistance = math.huge
                    
                    -- Find the nearest player that isn't on our team
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
                            local character = player.Character
                            local localCharacter = LocalPlayer.Character
                            
                            if character and localCharacter 
                                and character:FindFirstChild("HumanoidRootPart") 
                                and localCharacter:FindFirstChild("HumanoidRootPart") then
                                local distance = (character.HumanoidRootPart.Position - localCharacter.HumanoidRootPart.Position).Magnitude
                                if distance < shortestDistance then
                                    shortestDistance = distance
                                    nearestPlayer = player
                                end
                            end
                        end
                    end
                    
                    -- Teleport to the nearest player if one was found
                    if nearestPlayer and nearestPlayer.Character then
                        local character = LocalPlayer.Character
                        if character and character:FindFirstChild("HumanoidRootPart") 
                            and nearestPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            -- Add a small offset to avoid exact position overlap
                            local targetPosition = nearestPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 3, 0)
                            character.HumanoidRootPart.CFrame = CFrame.new(targetPosition)
                        end
                    end
                end)
            else
                -- Safely disconnect when toggle is turned off
                if _G.TeleportConnections.Teleport then
                    _G.TeleportConnections.Teleport:Disconnect()
                    _G.TeleportConnections.Teleport = nil
                end
            end
        end)
    end,
})


local MiscTab = Window:CreateTab("📢Misc", nil) -- Title, Image
local MiscSection = MiscTab:CreateSection("Misc")

local Button = MiscTab:CreateButton({
   Name = "Join Discord",
   Info = "Click to join our Discord server", -- Placeholder for the help section
   Interact = "Join Discord",
   Callback = function()
      setclipboard("https://discord.gg/mpTjs9EZ")
      Rayfield:Notify({
         Title = "Discord Invite",
         Content = "Discord invite copied to clipboard!",
         Duration = 3,
         Image = nil,
      })
   end,
})

local Button = MiscTab:CreateButton({
    Name = "Rejoin",
    Callback = function()
        -- Create notification before rejoining
        Rayfield:Notify({
            Title = "Rejoining Server",
            Content = "Please wait 3 seconds while we reconnect you...",
            Duration = 3,
            Image = nil,
        })
        
        -- Wait for 1 second to allow notification to be seen
        task.wait(1)
        
        -- Get the TeleportService
        local TeleportService = game:GetService("TeleportService")
        local player = game:GetService("Players").LocalPlayer
        
        -- Rejoin the same server
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end,
})

-- Regular Server Hop Button
local ServerHopButton = MiscTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        Rayfield:Notify({
            Title = "Server Hop",
            Content = "Finding a random server...",
            Duration = 3,
            Image = nil,
        })
        
        local TeleportService = game:GetService("TeleportService")
        local HttpService = game:GetService("HttpService")
        local player = game:GetService("Players").LocalPlayer
        
        local function GetRandomServer()
            local servers = {}
            local endpoint = string.format(
                "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100",
                game.PlaceId
            )
            
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(endpoint))
            end)
            
            if success and result and result.data then
                for _, server in ipairs(result.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        table.insert(servers, server)
                    end
                end
            end
            
            return #servers > 0 and servers[math.random(1, #servers)] or nil
        end
        
        local randomServer = GetRandomServer()
        
        if randomServer then
            Rayfield:Notify({
                Title = "Server Found",
                Content = string.format("Joining server with %d players...", randomServer.playing),
                Duration = 3,
                Image = nil,
            })
            
            task.wait(1)
            
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer.id, player)
            end)
        else
            Rayfield:Notify({
                Title = "Server Hop Failed",
                Content = "No available servers found. Try again later.",
                Duration = 3,
                Image = nil,
            })
        end
    end,
})

-- Low Player Server Button
local LowPlayerServerButton = MiscTab:CreateButton({
    Name = "Join Low Player Server",
    Callback = function()
        Rayfield:Notify({
            Title = "Finding Server",
            Content = "Searching for a low population server...",
            Duration = 3,
            Image = nil,
        })
        
        local TeleportService = game:GetService("TeleportService")
        local HttpService = game:GetService("HttpService")
        local player = game:GetService("Players").LocalPlayer
        
        local function GetLowPopulationServer()
            local servers = {}
            local endpoint = string.format(
                "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100",
                game.PlaceId
            )
            
            local success, result = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(endpoint))
            end)
            
            if success and result and result.data then
                for _, server in ipairs(result.data) do
                    -- Look for servers with less than 5 players
                    if server.playing < 5 and server.id ~= game.JobId then
                        table.insert(servers, server)
                    end
                end
                
                -- Sort by player count (ascending)
                table.sort(servers, function(a, b)
                    return a.playing < b.playing
                end)
            end
            
            return #servers > 0 and servers[1] or nil
        end
        
        local lowServer = GetLowPopulationServer()
        
        if lowServer then
            Rayfield:Notify({
                Title = "Low Player Server Found",
                Content = string.format("Joining server with only %d players...", lowServer.playing),
                Duration = 3,
                Image = nil,
            })
            
            task.wait(1)
            
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, lowServer.id, player)
            end)
        else
            Rayfield:Notify({
                Title = "Server Search Failed",
                Content = "No low population servers found. Try again later.",
                Duration = 3,
                Image = nil,
            })
        end
    end,
})

local JobIdInput = MiscTab:CreateInput({
    Name = "Server JobId",
    CurrentValue = "",
    PlaceholderText = "Format: PlaceId:JobId",
    RemoveTextAfterFocusLost = false,
    Flag = "JobIdTeleport",
    Callback = function(Input)
        if Input == "" then return end
        
        local TeleportService = game:GetService("TeleportService")
        
        -- Split the input into PlaceId and JobId using : as separator
        local placeId, jobId = Input:match("(%d+):(.+)")
        
        -- If no : found, check for just numbers (PlaceId) or assume it's a JobId for current game
        if not placeId then
            if Input:match("^%d+$") then
                -- If input is all numbers, treat as PlaceId
                placeId = Input
                jobId = nil
            else
                -- If input contains non-numbers, treat as JobId for current game
                placeId = game.PlaceId
                jobId = Input
            end
        end
        
        -- Convert PlaceId to number
        placeId = tonumber(placeId)
        
        if not placeId then
            Rayfield:Notify({
                Title = "Invalid Input",
                Content = "Invalid PlaceId format",
                Duration = 3,
                Image = nil,
            })
            return
        end
        
        Rayfield:Notify({
            Title = "Teleporting",
            Content = jobId and "Joining specific server..." or "Joining game...",
            Duration = 3,
            Image = nil,
        })
        
        task.wait(3)
        
        local success, error = pcall(function()
            if jobId then
                TeleportService:TeleportToPlaceInstance(placeId, jobId, game.Players.LocalPlayer)
            else
                TeleportService:Teleport(placeId, game.Players.LocalPlayer)
            end
        end)
        
        if not success then
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to teleport. Server might be full or invalid.",
                Duration = 3,
                Image = nil,
            })
            print("Teleport Error:", error)
        end
    end,
})

local LinkInput = MiscTab:CreateInput({
    Name = "Game/Private Server Link",
    CurrentValue = "",
    PlaceholderText = "Paste game or private server link here",
    RemoveTextAfterFocusLost = false,
    Flag = "LinkTeleport",
    Callback = function(Link)
        if Link == "" then return end
        
        local TeleportService = game:GetService("TeleportService")
        
        -- Extract PlaceId and optional PrivateServerId from the link
        local placeId = Link:match("roblox.com/games/(%d+)")
        local privateServerId = Link:match("privateServerLinkCode=([%w%-]+)")
        
        if not placeId then
            Rayfield:Notify({
                Title = "Invalid Link",
                Content = "Please provide a valid Roblox game link",
                Duration = 3,
                Image = nil,
            })
            return
        end
        
        placeId = tonumber(placeId)
        
        Rayfield:Notify({
            Title = "Teleporting",
            Content = "Joining game in 3 seconds...",
            Duration = 3,
            Image = nil,
        })
        
        task.wait(3)
        
        local success, error = pcall(function()
            if privateServerId then
                TeleportService:TeleportToPrivateServer(placeId, privateServerId)
            else
                TeleportService:Teleport(placeId)
            end
        end)
        
        if not success then
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to teleport. Invalid link or server is full.",
                Duration = 3,
                Image = nil,
            })
        end
    end,
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local autoAfkToggleEnabled = false  -- Estado do toggle para Anti-AFK

-- Função para enviar mensagem para prevenir desconexão
local function sendChatMessage()
    -- Envia mensagem para manter o sistema reconhecendo a atividade do jogador
    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("Auto-clicking to prevent AFK disconnection.", "All")
    print("Simulated activity: Preventing AFK disconnection.")
end

-- Função para evitar desconexão por AFK (ao detectar a inatividade do jogador)
local function startAntiAfk()
    -- A cada 10 minutos, envia a mensagem para resetar o timer AFK
    while autoAfkToggleEnabled do
        wait(600)  -- Espera 600 segundos (10 minutos)
        sendChatMessage()  -- Envia a mensagem para manter o jogador ativo
    end
end

-- Parar Anti-AFK (quando toggle é desabilitado)
local function stopAntiAfk()
    autoAfkToggleEnabled = false
    print("Anti-AFK disabled")
end

-- Criar o Toggle no UI para Anti-AFK
local AntiAfkToggle = MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAfkToggle",
    Callback = function(Value)
        if type(Value) == "boolean" then
            autoAfkToggleEnabled = Value
            print("Anti-AFK Enabled: ", autoAfkToggleEnabled)

            if autoAfkToggleEnabled then
                -- Inicia a verificação de Anti-AFK
                startAntiAfk()  
            else
                -- Para a verificação de Anti-AFK
                stopAntiAfk()   
            end
        else
            warn("Expected boolean for Anti-AFK toggle, received: ", type(Value))
        end
    end
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Create the GUI elements for showing position
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = LocalPlayer.PlayerGui
screenGui.Name = "PositionDisplayGui"
screenGui.Enabled = false -- Initially, the GUI is hidden

-- Create the frame to hold the position info
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 100)
frame.Position = UDim2.new(0.5, -150, 0.5, -50)  -- Centered on the screen
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.5
frame.Parent = screenGui

-- Create a TextLabel to display the position
local positionLabel = Instance.new("TextLabel")
positionLabel.Size = UDim2.new(1, 0, 0.8, 0)
positionLabel.Position = UDim2.new(0, 0, 0, 0)
positionLabel.BackgroundTransparency = 1
positionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
positionLabel.TextSize = 18
positionLabel.Text = "Position: X = 0, Y = 0, Z = 0"  -- Initial placeholder text
positionLabel.Parent = frame

-- Create a Close Button (X) to close the GUI
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, -35)  -- Position it at the top right
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 0, 0)
closeButton.TextSize = 20
closeButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
closeButton.BackgroundTransparency = 0.5
closeButton.Parent = frame

-- Update the position display when the button is clicked
local function updatePosition()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local position = character.HumanoidRootPart.Position
        positionLabel.Text = "Position: X = " .. math.floor(position.X) .. ", Y = " .. math.floor(position.Y) .. ", Z = " .. math.floor(position.Z)
    else
        positionLabel.Text = "Player's character not found!"
    end
end

-- Update the position every frame using RunService
game:GetService("RunService").Heartbeat:Connect(function()
    updatePosition()
end)

-- Close the GUI when the close button is clicked
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()  -- This removes the GUI from the screen
end)

-- Create a button using Tab:CreateButton to show the position GUI
local Button = MiscTab:CreateButton({
    Name = "Show Position",  -- Button text
    Callback = function()
        -- Show the position display GUI when the button is clicked
        screenGui.Enabled = true  -- Make the GUI visible
    end,
})

local Toggle = MiscTab:CreateToggle({
   Name = "Blur Names",
   CurrentValue = false,
   Flag = "BlurNamesToggle",
   Callback = function(Value)
       -- Get all name-related UI elements
       local function blurText(guiObject)
           if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") then
               -- Store original text if not already stored
               if not guiObject:GetAttribute("OriginalText") then
                   guiObject:SetAttribute("OriginalText", guiObject.Text)
               end
               
               if Value then
                   -- Check if the text contains a username or name-like pattern
                   local text = guiObject.Text
                   -- Pattern for common username formats
                   local namePattern = "[%w_]+#?%d*"
                   
                   -- Replace any matching text with asterisks
                   local blurredText = text:gsub(namePattern, function(match)
                       return string.rep("*", #match)
                   end)
                   
                   guiObject.Text = blurredText
               else
                   -- Restore original text when toggle is disabled
                   local originalText = guiObject:GetAttribute("OriginalText")
                   if originalText then
                       guiObject.Text = originalText
                   end
               end
           end
       end

       -- Function to process all GUI elements
       local function processGUI()
           -- Process PlayerList
           local playerList = game:GetService("CoreGui"):FindFirstChild("PlayerList")
           if playerList then
               for _, obj in pairs(playerList:GetDescendants()) do
                   blurText(obj)
               end
           end
           
           -- Process chat
           local chat = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Chat")
           if chat then
               for _, obj in pairs(chat:GetDescendants()) do
                   blurText(obj)
               end
           end
           
           -- Process all player GUIs
           for _, obj in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetDescendants()) do
               blurText(obj)
           end
           
           -- Process overhead names
           for _, player in pairs(game:GetService("Players"):GetPlayers()) do
               if player.Character then
                   local head = player.Character:FindFirstChild("Head")
                   if head then
                       local nameGui = head:FindFirstChild("PlayerNameGui")
                       if nameGui then
                           for _, obj in pairs(nameGui:GetDescendants()) do
                               blurText(obj)
                           end
                       end
                   end
               end
           end
       end

       -- Initial processing
       processGUI()

       -- Connect to events for dynamic updates
       if Value then
           _G.BlurNamesConnection = game:GetService("RunService").Heartbeat:Connect(processGUI)
       else
           if _G.BlurNamesConnection then
               _G.BlurNamesConnection:Disconnect()
               _G.BlurNamesConnection = nil
           end
       end
   end
})
