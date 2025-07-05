local CoreGui = game:GetService("CoreGui")
local UserInput = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local Interface = import("rbxassetid://11389137937")

if oh.Cache["ui/main"] then
    return Interface
end

import("ui/controls/TabSelector")
local MessageBox, MessageType = import("ui/controls/MessageBox")

-- Enhanced module loading with better error handling
local RemoteSpy, ClosureSpy, ScriptScanner, ModuleScanner, UpvalueScanner, ConstantScanner

local function loadModules()
    local modules = {
        {"ui/modules/RemoteSpy", "RemoteSpy"},
        {"ui/modules/ClosureSpy", "ClosureSpy"},
        {"ui/modules/ScriptScanner", "ScriptScanner"},
        {"ui/modules/ModuleScanner", "ModuleScanner"},
        {"ui/modules/UpvalueScanner", "UpvalueScanner"},
        {"ui/modules/ConstantScanner", "ConstantScanner"}
    }
    
    local loadedModules = {}
    local failedModules = {}
    
    for _, moduleInfo in ipairs(modules) do
        local path, name = moduleInfo[1], moduleInfo[2]
        local success, result = pcall(import, path)
        
        if success then
            loadedModules[name] = result
        else
            table.insert(failedModules, {name = name, error = result})
        end
    end
    
    -- Assign loaded modules
    RemoteSpy = loadedModules.RemoteSpy
    ClosureSpy = loadedModules.ClosureSpy
    ScriptScanner = loadedModules.ScriptScanner
    ModuleScanner = loadedModules.ModuleScanner
    UpvalueScanner = loadedModules.UpvalueScanner
    ConstantScanner = loadedModules.ConstantScanner
    
    -- Handle failed modules
    if #failedModules > 0 then
        local errorMessage = "Failed to load the following modules:\n\n"
        for _, failed in ipairs(failedModules) do
            errorMessage = errorMessage .. failed.name .. ": " .. failed.error .. "\n"
        end
        
        if #failedModules == #modules then
            errorMessage = errorMessage .. "\nThe UI has updated, please rejoin and restart. If you get this message more than once, screenshot this message and report it in the Hydroxide server."
        else
            errorMessage = errorMessage .. "\nSome features may not work correctly."
        end
        
        MessageBox.Show("Module Loading Error", errorMessage, MessageType.OK, function()
            if #failedModules == #modules then
                Interface:Destroy()
            end
        end)
    end
end

-- Load modules with error handling
xpcall(loadModules, function(err)
    local message = "Critical error loading Hydroxide modules:\n\n" .. err
    MessageBox.Show("Critical Error", message, MessageType.OK, function()
        Interface:Destroy() 
    end)
end)

-- Enhanced constants with better positioning and animations
local constants = {
    opened = UDim2.new(0.5, -325, 0.5, -175),
    closed = UDim2.new(0.5, -325, 0, -400),
    reveal = UDim2.new(0.5, -15, 0, 20),
    conceal = UDim2.new(0.5, -15, 0, -75),
    animationTime = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    fadeTime = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
}

local Open = Interface.Open
local Base = Interface.Base
local Drag = Base.Drag
local Status = Base.Status
local Collapse = Drag.Collapse
local Title = Drag.Title

-- Enhanced status management
local statusHistory = {}
local maxStatusHistory = 10

function oh.setStatus(text)
    local timestamp = os.date("%H:%M:%S")
    local statusText = '• Status: ' .. text
    
    Status.Text = statusText
    
    -- Add to history
    table.insert(statusHistory, {
        text = text,
        timestamp = timestamp,
        full = statusText
    })
    
    if #statusHistory > maxStatusHistory then
        table.remove(statusHistory, 1)
    end
    
    -- Animate status change
    local originalColor = Status.TextColor3
    Status.TextColor3 = Color3.fromRGB(100, 255, 100)
    
    TweenService:Create(Status, constants.fadeTime, {
        TextColor3 = originalColor
    }):Play()
end

function oh.getStatus()
    return Status.Text:gsub('• Status: ', '')
end

function oh.getStatusHistory()
    return statusHistory
end

-- Enhanced dragging with constraints and snapping
local dragging = false
local dragStart = nil
local startPos = nil
local snapDistance = 20

local function snapToEdges(position)
    local screenSize = workspace.CurrentCamera.ViewportSize
    local baseSize = Base.AbsoluteSize
    
    local x = position.X.Offset
    local y = position.Y.Offset
    
    -- Snap to edges
    if x < snapDistance then
        x = 0
    elseif x + baseSize.X > screenSize.X - snapDistance then
        x = screenSize.X - baseSize.X
    end
    
    if y < snapDistance then
        y = 0
    elseif y + baseSize.Y > screenSize.Y - snapDistance then
        y = screenSize.Y - baseSize.Y
    end
    
    return UDim2.new(0, x, 0, y)
end

Drag.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local dragEnded 

        dragging = true
        dragStart = input.Position
        startPos = Base.Position

        -- Visual feedback
        TweenService:Create(Base, constants.fadeTime, {
            BackgroundTransparency = 0.1
        }):Play()

        dragEnded = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                dragEnded:Disconnect()
                
                -- Snap to edges
                local snappedPosition = snapToEdges(Base.Position)
                TweenService:Create(Base, constants.fadeTime, {
                    Position = snappedPosition,
                    BackgroundTransparency = 0
                }):Play()
            end
        end)
    end
end)

oh.Events.Drag = UserInput.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        local delta = input.Position - dragStart
        local newPosition = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
        
        Base.Position = newPosition
    end
end)

-- Enhanced open/close animations
local function openInterface()
    Open:TweenPosition(constants.conceal, "Out", "Back", 0.3)
    Base:TweenPosition(constants.opened, "Out", "Back", 0.3)
    
    -- Animate title
    if Title then
        TweenService:Create(Title, constants.fadeTime, {
            TextTransparency = 0
        }):Play()
    end
    
    oh.setStatus("Interface opened")
end

local function closeInterface()
    Base:TweenPosition(constants.closed, "Out", "Back", 0.3)
    Open:TweenPosition(constants.reveal, "Out", "Back", 0.3)
    
    oh.setStatus("Interface minimized")
end

Open.MouseButton1Click:Connect(openInterface)
Collapse.MouseButton1Click:Connect(closeInterface)

-- Enhanced hover effects for buttons
local function setupButtonHover(button, hoverColor, normalColor)
    local hoverIn = TweenService:Create(button, constants.fadeTime, {
        BackgroundColor3 = hoverColor or Color3.fromRGB(55, 55, 55)
    })
    local hoverOut = TweenService:Create(button, constants.fadeTime, {
        BackgroundColor3 = normalColor or Color3.fromRGB(35, 35, 35)
    })
    
    button.MouseEnter:Connect(function()
        hoverIn:Play()
    end)
    
    button.MouseLeave:Connect(function()
        hoverOut:Play()
    end)
end

setupButtonHover(Open)
setupButtonHover(Collapse)

-- Keyboard shortcuts
UserInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Ctrl+Shift+H to toggle interface
    if input.KeyCode == Enum.KeyCode.H and 
       UserInput:IsKeyDown(Enum.KeyCode.LeftControl) and 
       UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then
        
        if Base.Position == constants.opened then
            closeInterface()
        else
            openInterface()
        end
    end
    
    -- Escape to close interface
    if input.KeyCode == Enum.KeyCode.Escape and Base.Position == constants.opened then
        closeInterface()
    end
end)

-- Enhanced interface setup with better error handling
local function setupInterface()
    Interface.Name = HttpService:GenerateGUID(false)
    
    -- Try to use hidden GUI first
    if getHui then
        local success, result = pcall(function()
            Interface.Parent = getHui()
        end)
        
        if not success then
            warn("Failed to parent to hidden GUI: " .. result)
            Interface.Parent = CoreGui
        end
    else
        -- Protect GUI if syn is available
        if syn and syn.protect_gui then
            syn.protect_gui(Interface)
        end
        
        Interface.Parent = CoreGui
    end
    
    -- Set initial status
    oh.setStatus("Hydroxide loaded successfully")
end

-- Initialize interface
xpcall(setupInterface, function(err)
    warn("Failed to setup interface: " .. err)
    Interface.Parent = CoreGui
end)

-- Memory management
local function cleanup()
    -- Disconnect all events
    for name, event in pairs(oh.Events) do
        if event and event.Disconnect then
            event:Disconnect()
        end
    end
    
    -- Clear caches
    oh.Cache = {}
    
    -- Destroy interface
    if Interface then
        Interface:Destroy()
    end
end

-- Register cleanup
oh.Events.InterfaceCleanup = game:GetService("Players").PlayerRemoving:Connect(cleanup)

-- Auto-save position
local lastPosition = constants.opened
spawn(function()
    while Interface.Parent do
        if Base.Position ~= lastPosition then
            lastPosition = Base.Position
            -- Could save to file here if writefile is available
        end
        wait(1)
    end
end)

return Interface