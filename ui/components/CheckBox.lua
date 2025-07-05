local BaseComponent = import("ui/components/BaseComponent")

local CheckBox = setmetatable({}, {__index = BaseComponent})
CheckBox.__index = CheckBox

function CheckBox.new(instance, config)
    local checkbox = setmetatable(BaseComponent.new(instance), CheckBox)
    
    config = config or {}
    checkbox.checked = config.checked or false
    checkbox.text = config.text or ""
    checkbox.callback = config.callback
    
    checkbox:setupComponents()
    checkbox:setupInteractions()
    checkbox:updateDisplay()
    
    return checkbox
end

function CheckBox:setupComponents()
    if not self.instance then return end
    
    -- Find or create components
    self.toggle = self.instance:FindFirstChild("Toggle") or self.instance
    self.label = self.toggle:FindFirstChild("Label")
    self.checkmark = self.toggle:FindFirstChild("Checkmark")
    
    -- Create checkmark if it doesn't exist
    if not self.checkmark then
        self.checkmark = Instance.new("TextLabel")
        self.checkmark.Name = "Checkmark"
        self.checkmark.BackgroundTransparency = 1
        self.checkmark.Size = UDim2.new(1, 0, 1, 0)
        self.checkmark.Text = "✓"
        self.checkmark.TextColor3 = BaseComponent.CONSTANTS.COLORS.SUCCESS
        self.checkmark.TextSize = 16
        self.checkmark.Font = Enum.Font.SourceSansBold
        self.checkmark.TextXAlignment = Enum.TextXAlignment.Center
        self.checkmark.TextYAlignment = Enum.TextYAlignment.Center
        self.checkmark.Parent = self.toggle
    end
    
    -- Set up text label if provided
    if self.text and self.text ~= "" then
        if not self.label then
            self.label = Instance.new("TextLabel")
            self.label.Name = "Label"
            self.label.BackgroundTransparency = 1
            self.label.Position = UDim2.new(1, BaseComponent.CONSTANTS.SPACING.MEDIUM, 0, 0)
            self.label.Size = UDim2.new(0, 200, 1, 0)
            self.label.TextColor3 = BaseComponent.CONSTANTS.COLORS.TEXT_PRIMARY
            self.label.TextSize = 14
            self.label.Font = Enum.Font.SourceSans
            self.label.TextXAlignment = Enum.TextXAlignment.Left
            self.label.TextYAlignment = Enum.TextYAlignment.Center
            self.label.Parent = self.instance
        end
        
        self.label.Text = self.text
    end
end

function CheckBox:setupInteractions()
    if not self.toggle then return end
    
    -- Create animations
    self.animations.checkIn = self:createTween(
        self.checkmark,
        {
            TextTransparency = 0,
            TextStrokeTransparency = 0
        },
        0.1
    )
    
    self.animations.checkOut = self:createTween(
        self.checkmark,
        {
            TextTransparency = 1,
            TextStrokeTransparency = 1
        },
        0.1
    )
    
    self.animations.hoverIn = self:createTween(
        self.toggle,
        {BackgroundColor3 = BaseComponent.CONSTANTS.COLORS.HOVER}
    )
    
    self.animations.hoverOut = self:createTween(
        self.toggle,
        {BackgroundColor3 = BaseComponent.CONSTANTS.COLORS.SECONDARY}
    )
    
    -- Mouse interactions
    self:addConnection(self.toggle.MouseButton1Click, function()
        self:setChecked(not self.checked)
    end)
    
    self:addConnection(self.toggle.MouseEnter, function()
        if self.enabled then
            self.animations.hoverIn:Play()
        end
    end)
    
    self:addConnection(self.toggle.MouseLeave, function()
        if self.enabled then
            self.animations.hoverOut:Play()
        end
    end)
    
    -- Label click support
    if self.label then
        self:addConnection(self.label.MouseButton1Click, function()
            self:setChecked(not self.checked)
        end)
    end
end

function CheckBox:updateDisplay()
    if not self.checkmark then return end
    
    if self.checked then
        self.checkmark.TextTransparency = 0
        self.checkmark.TextStrokeTransparency = 0
    else
        self.checkmark.TextTransparency = 1
        self.checkmark.TextStrokeTransparency = 1
    end
end

function CheckBox:setChecked(checked, silent)
    local oldChecked = self.checked
    self.checked = checked
    
    -- Animate the change
    if checked then
        if self.animations.checkIn then
            self.animations.checkIn:Play()
        end
    else
        if self.animations.checkOut then
            self.animations.checkOut:Play()
        end
    end
    
    -- Call callback if state changed and not silent
    if not silent and oldChecked ~= checked and self.callback then
        self.callback(checked, self)
    end
end

function CheckBox:setCallback(callback)
    self.callback = callback
end

function CheckBox:setText(text)
    self.text = text
    if self.label then
        self.label.Text = text
    end
end

function CheckBox:setEnabled(enabled)
    BaseComponent.setEnabled(self, enabled)
    
    local alpha = enabled and 1 or 0.5
    
    if self.toggle then
        self.toggle.BackgroundTransparency = 1 - (alpha * 0.8)
    end
    
    if self.label then
        self.label.TextTransparency = 1 - alpha
    end
    
    if self.checkmark then
        self.checkmark.TextTransparency = self.checked and (1 - alpha) or 1
    end
end

return CheckBox