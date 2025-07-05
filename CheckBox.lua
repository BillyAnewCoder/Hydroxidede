local CheckBox = {}

-- Enhanced CheckBox with better animations and state management
function CheckBox.new(instance, config)
    local checkBox = {}
    config = config or {}
    
    local toggle = instance:FindFirstChild("Toggle") or instance
    local label = toggle:FindFirstChild("Label")
    
    -- State management
    checkBox.Enabled = config.enabled or (label and label.Text == '✓') or false
    checkBox.Instance = instance
    checkBox.Callback = nil
    checkBox.Text = config.text or ""
    
    -- Animation setup
    local TweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    local checkAnimation = TweenService:Create(label, tweenInfo, {
        TextTransparency = 0,
        TextStrokeTransparency = 0
    })
    
    local uncheckAnimation = TweenService:Create(label, tweenInfo, {
        TextTransparency = 1,
        TextStrokeTransparency = 1
    })
    
    local hoverAnimation = TweenService:Create(toggle, tweenInfo, {
        BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    })
    
    local normalAnimation = TweenService:Create(toggle, tweenInfo, {
        BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    })
    
    -- Event connections
    local connections = {}
    
    connections.click = toggle.MouseButton1Click:Connect(function()
        checkBox:Toggle()
    end)
    
    connections.hover = toggle.MouseEnter:Connect(function()
        hoverAnimation:Play()
    end)
    
    connections.leave = toggle.MouseLeave:Connect(function()
        normalAnimation:Play()
    end)
    
    -- Methods
    function checkBox:Toggle()
        self.Enabled = not self.Enabled
        self:UpdateDisplay()
        
        if self.Callback then
            self.Callback(self.Enabled, self)
        end
    end
    
    function checkBox:SetEnabled(enabled)
        self.Enabled = enabled
        self:UpdateDisplay()
    end
    
    function checkBox:UpdateDisplay()
        if self.Enabled then
            label.Text = '✓'
            checkAnimation:Play()
        else
            uncheckAnimation:Play()
            uncheckAnimation.Completed:Connect(function()
                label.Text = ''
            end)
        end
    end
    
    function checkBox:SetCallback(callback)
        self.Callback = callback
    end
    
    function checkBox:SetText(text)
        self.Text = text
        if label then
            label.Text = self.Enabled and '✓' or ''
        end
    end
    
    function checkBox:Destroy()
        for _, connection in pairs(connections) do
            if connection then
                connection:Disconnect()
            end
        end
        connections = {}
    end
    
    -- Initialize display
    checkBox:UpdateDisplay()
    
    return checkBox
end

return CheckBox