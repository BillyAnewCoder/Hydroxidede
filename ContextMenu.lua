local Assets = import("rbxassetid://5042114982").Controls
local Storage = import("rbxassetid://11389137937").ContextMenus

local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local client = Players.LocalPlayer
local mouse = client:GetMouse()

local ContextMenuButton = {}
local ContextMenu = {}

local currentContextMenu
local constants = {
    fadeLength = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    textWidth = Vector2.new(1337420, 20),
    colors = {
        hover = Color3.fromRGB(55, 55, 55),
        normal = Color3.fromRGB(35, 35, 35),
        text = Color3.fromRGB(255, 255, 255),
        textHover = Color3.fromRGB(255, 255, 255),
        textDisabled = Color3.fromRGB(127, 127, 127)
    }
}

function ContextMenuButton.new(icon, text, config)
    local contextMenuButton = {}
    config = config or {}
    
    local instance = Assets.ContextMenuButton:Clone()
    local label = instance.Label
    local iconElement = instance.Icon
    
    -- Enhanced animations
    local enterAnimation = TweenService:Create(instance, constants.fadeLength, { 
        BackgroundColor3 = constants.colors.hover 
    })
    local leaveAnimation = TweenService:Create(instance, constants.fadeLength, { 
        BackgroundColor3 = constants.colors.normal 
    })
    
    local textEnterAnimation = TweenService:Create(label, constants.fadeLength, { 
        TextTransparency = 0 
    })
    local textLeaveAnimation = TweenService:Create(label, constants.fadeLength, { 
        TextTransparency = 0.2 
    })
    
    -- Setup
    label.Text = text
    iconElement.Image = icon
    contextMenuButton.Enabled = config.enabled ~= false
    contextMenuButton.Instance = instance
    contextMenuButton.Callback = config.callback
    
    -- State management
    local function updateState()
        local alpha = contextMenuButton.Enabled and 1 or 0.5
        instance.BackgroundTransparency = 1 - (alpha * 0.8)
        label.TextTransparency = 1 - alpha
        iconElement.ImageTransparency = 1 - alpha
        label.TextColor3 = contextMenuButton.Enabled and constants.colors.text or constants.colors.textDisabled
    end
    
    -- Event connections
    local connections = {}
    
    connections.click = instance.MouseButton1Click:Connect(function()
        if contextMenuButton.Enabled and contextMenuButton.Callback then
            contextMenuButton.Callback(contextMenuButton)
        end
    end)
    
    connections.enter = instance.MouseEnter:Connect(function()
        if contextMenuButton.Enabled then
            enterAnimation:Play()
            textEnterAnimation:Play()
        end
    end)
    
    connections.leave = instance.MouseLeave:Connect(function()
        if contextMenuButton.Enabled then
            leaveAnimation:Play()
            textLeaveAnimation:Play()
        end
    end)
    
    -- Methods
    function contextMenuButton:SetIcon(newIcon)
        iconElement.Image = newIcon
    end
    
    function contextMenuButton:SetText(newText)
        label.Text = newText
    end
    
    function contextMenuButton:SetCallback(callback)
        self.Callback = callback
    end
    
    function contextMenuButton:SetEnabled(enabled)
        self.Enabled = enabled
        updateState()
    end
    
    function contextMenuButton:Destroy()
        for _, connection in pairs(connections) do
            if connection then
                connection:Disconnect()
            end
        end
        if instance then
            instance:Destroy()
        end
    end
    
    -- Initialize state
    updateState()
    
    return contextMenuButton
end

function ContextMenu.new(contextMenuButtons, config)
    local contextMenu = {}
    config = config or {}
    
    local instance = Assets.ContextMenu:Clone()
    local instanceWidth = config.minWidth or 150
    local instanceHeight = 0
    
    instance.Parent = Storage
    contextMenu.Instance = instance
    contextMenu.Visible = false
    contextMenu.Buttons = contextMenuButtons or {}
    contextMenu.AutoClose = config.autoClose ~= false
    
    -- Calculate size and setup buttons
    for _, contextMenuButton in pairs(contextMenu.Buttons) do
        local buttonInstance = contextMenuButton.Instance
        local textWidth = TextService:GetTextSize(
            buttonInstance.Label.Text, 
            18, 
            "SourceSans", 
            constants.textWidth
        ).X
        
        buttonInstance.Parent = instance.List
        buttonInstance.TextWrapped = false
        
        local buttonWidth = buttonInstance.Icon.AbsoluteSize.X + textWidth + 32
        instanceWidth = math.max(instanceWidth, buttonWidth)
        instanceHeight = instanceHeight + buttonInstance.AbsoluteSize.Y
    end
    
    instance.Size = UDim2.new(0, instanceWidth, 0, instanceHeight)
    instance.Visible = false
    
    -- Enhanced show/hide animations
    local showAnimation = TweenService:Create(instance, constants.fadeLength, {
        BackgroundTransparency = 0,
        Size = UDim2.new(0, instanceWidth, 0, instanceHeight)
    })
    
    local hideAnimation = TweenService:Create(instance, constants.fadeLength, {
        BackgroundTransparency = 1,
        Size = UDim2.new(0, instanceWidth, 0, 0)
    })
    
    -- Methods
    function contextMenu:Show(position)
        if currentContextMenu and currentContextMenu ~= self then
            currentContextMenu:Hide()
        end
        
        currentContextMenu = self
        
        -- Position calculation with screen bounds checking
        local posX = position and position.X or mouse.X
        local posY = position and position.Y or mouse.Y
        
        -- Ensure menu stays on screen
        local screenSize = workspace.CurrentCamera.ViewportSize
        if posX + instanceWidth > screenSize.X then
            posX = screenSize.X - instanceWidth - 10
        end
        if posY + instanceHeight > screenSize.Y then
            posY = screenSize.Y - instanceHeight - 10
        end
        
        instance.Position = UDim2.new(0, posX, 0, posY)
        instance.Visible = true
        self.Visible = true
        
        showAnimation:Play()
    end
    
    function contextMenu:Hide()
        if not self.Visible then return end
        
        hideAnimation:Play()
        hideAnimation.Completed:Connect(function()
            instance.Visible = false
            self.Visible = false
        end)
        
        if currentContextMenu == self then
            currentContextMenu = nil
        end
    end
    
    function contextMenu:AddButton(button)
        table.insert(self.Buttons, button)
        button.Instance.Parent = instance.List
        -- Recalculate size if needed
    end
    
    function contextMenu:RemoveButton(button)
        local index = table.find(self.Buttons, button)
        if index then
            table.remove(self.Buttons, index)
            button:Destroy()
        end
    end
    
    function contextMenu:Destroy()
        for _, button in pairs(self.Buttons) do
            if button and button.Destroy then
                button:Destroy()
            end
        end
        if instance then
            instance:Destroy()
        end
    end
    
    return contextMenu
end

-- Global input handling for auto-close
UserInput.InputEnded:Connect(function(input)
    if currentContextMenu and input.UserInputType == Enum.UserInputType.MouseButton1 then
        if currentContextMenu.AutoClose then
            currentContextMenu:Hide()
        end
    end
end)

return ContextMenu, ContextMenuButton