local BaseComponent = import("ui/components/BaseComponent")
local Button = setmetatable({}, {__index = BaseComponent})
Button.__index = Button

function Button.new(instance, config)
    local button = setmetatable(BaseComponent.new(instance), Button)
    
    config = config or {}
    button.text = config.text or ""
    button.icon = config.icon
    button.callback = config.callback
    button.style = config.style or "primary"
    
    button:setupAppearance()
    button:setupInteractions()
    
    return button
end

function Button:setupAppearance()
    local colors = BaseComponent.CONSTANTS.COLORS
    
    -- Set initial colors based on style
    local styleColors = {
        primary = {
            background = colors.PRIMARY,
            text = colors.TEXT_PRIMARY,
            hover = colors.HOVER
        },
        secondary = {
            background = colors.SECONDARY,
            text = colors.TEXT_SECONDARY,
            hover = colors.ACCENT
        },
        success = {
            background = colors.SUCCESS,
            text = colors.TEXT_PRIMARY,
            hover = Color3.fromRGB(67, 160, 71)
        },
        warning = {
            background = colors.WARNING,
            text = colors.PRIMARY,
            hover = Color3.fromRGB(255, 183, 77)
        },
        error = {
            background = colors.ERROR,
            text = colors.TEXT_PRIMARY,
            hover = Color3.fromRGB(229, 57, 53)
        }
    }
    
    self.colors = styleColors[self.style] or styleColors.primary
    
    if self.instance then
        self.instance.BackgroundColor3 = self.colors.background
        
        local label = self.instance:FindFirstChild("Label")
        if label then
            label.Text = self.text
            label.TextColor3 = self.colors.text
        end
        
        local icon = self.instance:FindFirstChild("Icon")
        if icon and self.icon then
            icon.Image = self.icon
            icon.ImageColor3 = self.colors.text
        end
    end
end

function Button:setupInteractions()
    if not self.instance then return end
    
    -- Create hover animations
    self.animations.hoverIn = self:createTween(
        self.instance,
        {BackgroundColor3 = self.colors.hover}
    )
    
    self.animations.hoverOut = self:createTween(
        self.instance,
        {BackgroundColor3 = self.colors.background}
    )
    
    -- Mouse interactions
    self:addConnection(self.instance.MouseEnter, function()
        if self.enabled then
            self.animations.hoverIn:Play()
        end
    end)
    
    self:addConnection(self.instance.MouseLeave, function()
        if self.enabled then
            self.animations.hoverOut:Play()
        end
    end)
    
    self:addConnection(self.instance.MouseButton1Click, function()
        if self.enabled and self.callback then
            self.callback(self)
        end
    end)
end

function Button:setText(text)
    self.text = text
    local label = self.instance and self.instance:FindFirstChild("Label")
    if label then
        label.Text = text
    end
end

function Button:setIcon(icon)
    self.icon = icon
    local iconElement = self.instance and self.instance:FindFirstChild("Icon")
    if iconElement then
        iconElement.Image = icon
    end
end

function Button:setCallback(callback)
    self.callback = callback
end

function Button:setEnabled(enabled)
    BaseComponent.setEnabled(self, enabled)
    
    if self.instance then
        local alpha = enabled and 1 or 0.5
        self.instance.BackgroundTransparency = 1 - alpha
        
        local label = self.instance:FindFirstChild("Label")
        if label then
            label.TextTransparency = 1 - alpha
        end
        
        local icon = self.instance:FindFirstChild("Icon")
        if icon then
            icon.ImageTransparency = 1 - alpha
        end
    end
end

return Button