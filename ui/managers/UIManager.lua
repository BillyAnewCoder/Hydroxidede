-- Central UI management system
local UIManager = {}

local BaseComponent = import("ui/components/BaseComponent")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Component registry
local components = {}
local themes = {}
local currentTheme = "dark"

-- Default themes
themes.dark = {
    colors = BaseComponent.CONSTANTS.COLORS,
    fonts = {
        primary = Enum.Font.SourceSans,
        secondary = Enum.Font.SourceSansSemibold,
        monospace = Enum.Font.Code
    },
    sizes = {
        text = {
            small = 12,
            medium = 14,
            large = 16,
            xlarge = 18
        }
    }
}

themes.light = {
    colors = {
        PRIMARY = Color3.fromRGB(245, 245, 245),
        SECONDARY = Color3.fromRGB(255, 255, 255),
        ACCENT = Color3.fromRGB(200, 200, 200),
        TEXT_PRIMARY = Color3.fromRGB(33, 33, 33),
        TEXT_SECONDARY = Color3.fromRGB(66, 66, 66),
        TEXT_DISABLED = Color3.fromRGB(158, 158, 158),
        SUCCESS = Color3.fromRGB(76, 175, 80),
        WARNING = Color3.fromRGB(255, 193, 7),
        ERROR = Color3.fromRGB(244, 67, 54),
        HOVER = Color3.fromRGB(235, 235, 235),
        SELECTED = Color3.fromRGB(225, 225, 225)
    },
    fonts = themes.dark.fonts,
    sizes = themes.dark.sizes
}

function UIManager.registerComponent(component)
    table.insert(components, component)
    return component
end

function UIManager.unregisterComponent(component)
    local index = table.find(components, component)
    if index then
        table.remove(components, index)
    end
end

function UIManager.setTheme(themeName)
    local theme = themes[themeName]
    if not theme then
        warn("Theme '" .. themeName .. "' not found")
        return false
    end
    
    currentTheme = themeName
    
    -- Update BaseComponent constants
    for key, value in pairs(theme.colors) do
        BaseComponent.CONSTANTS.COLORS[key] = value
    end
    
    -- Notify all components of theme change
    for _, component in ipairs(components) do
        if component.onThemeChanged then
            component:onThemeChanged(theme)
        end
    end
    
    return true
end

function UIManager.getCurrentTheme()
    return themes[currentTheme]
end

function UIManager.addTheme(name, theme)
    themes[name] = theme
end

function UIManager.createNotification(config)
    config = config or {}
    
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.BackgroundColor3 = config.backgroundColor or BaseComponent.CONSTANTS.COLORS.PRIMARY
    notification.BorderSizePixel = 1
    notification.BorderColor3 = config.borderColor or BaseComponent.CONSTANTS.COLORS.ACCENT
    notification.Size = UDim2.new(0, 300, 0, 80)
    notification.Position = UDim2.new(1, -320, 1, -100)
    
    -- Add to screen
    local screenGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if screenGui then
        notification.Parent = screenGui
    end
    
    -- Create content
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -20, 0, 25)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.Text = config.title or "Notification"
    title.TextColor3 = BaseComponent.CONSTANTS.COLORS.TEXT_PRIMARY
    title.TextSize = 16
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notification
    
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.BackgroundTransparency = 1
    message.Size = UDim2.new(1, -20, 0, 40)
    message.Position = UDim2.new(0, 10, 0, 30)
    message.Text = config.message or ""
    message.TextColor3 = BaseComponent.CONSTANTS.COLORS.TEXT_SECONDARY
    message.TextSize = 14
    message.Font = Enum.Font.SourceSans
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextYAlignment = Enum.TextYAlignment.Top
    message.TextWrapped = true
    message.Parent = notification
    
    -- Animate in
    local slideIn = TweenService:Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -320, 1, -100)}
    )
    
    notification.Position = UDim2.new(1, 0, 1, -100)
    slideIn:Play()
    
    -- Auto-hide after duration
    local duration = config.duration or 3
    game:GetService("Debris"):AddItem(notification, duration + 0.5)
    
    wait(duration)
    
    local slideOut = TweenService:Create(
        notification,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 0, 1, -100)}
    )
    slideOut:Play()
    
    return notification
end

function UIManager.createModal(config)
    config = config or {}
    
    -- Create overlay
    local overlay = Instance.new("Frame")
    overlay.Name = "ModalOverlay"
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.5
    overlay.BorderSizePixel = 0
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.ZIndex = 1000
    
    -- Create modal
    local modal = Instance.new("Frame")
    modal.Name = "Modal"
    modal.BackgroundColor3 = BaseComponent.CONSTANTS.COLORS.PRIMARY
    modal.BorderSizePixel = 1
    modal.BorderColor3 = BaseComponent.CONSTANTS.COLORS.ACCENT
    modal.Size = config.size or UDim2.new(0, 400, 0, 300)
    modal.Position = UDim2.new(0.5, -200, 0.5, -150)
    modal.ZIndex = 1001
    modal.Parent = overlay
    
    -- Add to screen
    local storage = import("rbxassetid://11389137937")
    overlay.Parent = storage
    
    -- Close functionality
    local function closeModal()
        local fadeOut = TweenService:Create(
            overlay,
            TweenInfo.new(0.2),
            {BackgroundTransparency = 1}
        )
        
        fadeOut.Completed:Connect(function()
            overlay:Destroy()
        end)
        
        fadeOut:Play()
    end
    
    -- Close on overlay click
    overlay.MouseButton1Click:Connect(closeModal)
    
    -- Prevent modal clicks from closing
    modal.MouseButton1Click:Connect(function() end)
    
    return modal, closeModal
end

function UIManager.showTooltip(target, text, config)
    config = config or {}
    
    local tooltip = Instance.new("Frame")
    tooltip.Name = "Tooltip"
    tooltip.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
    tooltip.BorderSizePixel = 1
    tooltip.BorderColor3 = BaseComponent.CONSTANTS.COLORS.ACCENT
    tooltip.Size = UDim2.new(0, 200, 0, 30)
    tooltip.ZIndex = 2000
    
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.Text = text
    label.TextColor3 = BaseComponent.CONSTANTS.COLORS.TEXT_PRIMARY
    label.TextSize = 12
    label.Font = Enum.Font.SourceSans
    label.TextWrapped = true
    label.Parent = tooltip
    
    -- Position tooltip
    local mouse = game:GetService("Players").LocalPlayer:GetMouse()
    tooltip.Position = UDim2.new(0, mouse.X + 10, 0, mouse.Y - 40)
    
    -- Add to screen
    local storage = import("rbxassetid://11389137937")
    tooltip.Parent = storage
    
    -- Auto-hide
    game:GetService("Debris"):AddItem(tooltip, config.duration or 2)
    
    return tooltip
end

-- Global keyboard shortcuts
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Ctrl+Shift+H to toggle Hydroxide
    if input.KeyCode == Enum.KeyCode.H and 
       UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 
       UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        
        local interface = import("rbxassetid://11389137937")
        if interface then
            local base = interface:FindFirstChild("Base")
            if base then
                base.Visible = not base.Visible
            end
        end
    end
end)

UIManager.themes = themes
UIManager.components = components

return UIManager