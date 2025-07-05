local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Prompts = import("rbxassetid://11389137937").Base.Prompts

local Prompt = {}
local currentPrompt
local connections = {}

-- Enhanced constants
local constants = {
    animationTime = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    fadeTime = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
}

function Prompt.new(instance, config)
    local prompt = {}
    config = config or {}
    
    prompt.Instance = instance
    prompt.Modal = config.modal ~= false
    prompt.CloseOnEscape = config.closeOnEscape ~= false
    prompt.OnShow = config.onShow
    prompt.OnHide = config.onHide
    prompt.Visible = false
    
    -- Setup close button if exists
    local closeButton = instance:FindFirstChild("CloseButton")
    if closeButton then
        closeButton.MouseButton1Click:Connect(function()
            prompt:Hide()
        end)
        
        -- Hover effect for close button
        local hoverIn = TweenService:Create(closeButton, constants.fadeTime, {
            BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        })
        local hoverOut = TweenService:Create(closeButton, constants.fadeTime, {
            BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        })
        
        closeButton.MouseEnter:Connect(function()
            hoverIn:Play()
        end)
        
        closeButton.MouseLeave:Connect(function()
            hoverOut:Play()
        end)
    end
    
    -- Methods
    function prompt:Show(data)
        if currentPrompt and currentPrompt ~= self then
            currentPrompt:Hide()
        end
        
        currentPrompt = self
        self.Visible = true
        
        -- Update content if data provided
        if data then
            self:UpdateContent(data)
        end
        
        -- Show shadow and prompt
        Prompts.PromptShadow.Visible = true
        self.Instance.Visible = true
        
        -- Enhanced show animations
        self.Instance.Size = UDim2.new(0, 0, 0, 0)
        self.Instance.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        local targetSize = data and data.size or UDim2.new(0, 400, 0, 300)
        local targetPosition = UDim2.new(0.5, -targetSize.X.Offset/2, 0.5, -targetSize.Y.Offset/2)
        
        local scaleAnimation = TweenService:Create(self.Instance, constants.animationTime, {
            Size = targetSize,
            Position = targetPosition
        })
        
        -- Fade in shadow
        Prompts.PromptShadow.BackgroundTransparency = 1
        local shadowAnimation = TweenService:Create(Prompts.PromptShadow, constants.fadeTime, {
            BackgroundTransparency = 0.5
        })
        
        scaleAnimation:Play()
        shadowAnimation:Play()
        
        -- Setup modal behavior
        if self.Modal then
            self:SetupModalBehavior()
        end
        
        -- Callback
        if self.OnShow then
            self.OnShow(self, data)
        end
    end
    
    function prompt:Hide()
        if not self.Visible then return end
        
        self.Visible = false
        
        -- Cleanup connections
        for name, connection in pairs(connections) do
            if connection then
                connection:Disconnect()
            end
        end
        connections = {}
        
        -- Hide animations
        local hideAnimation = TweenService:Create(self.Instance, constants.fadeTime, {
            Size = UDim2.new(0, 0, 0, 0)
        })
        
        local shadowHide = TweenService:Create(Prompts.PromptShadow, constants.fadeTime, {
            BackgroundTransparency = 1
        })
        
        hideAnimation.Completed:Connect(function()
            Prompts.PromptShadow.Visible = false
            self.Instance.Visible = false
        end)
        
        hideAnimation:Play()
        shadowHide:Play()
        
        if currentPrompt == self then
            currentPrompt = nil
        end
        
        -- Callback
        if self.OnHide then
            self.OnHide(self)
        end
    end
    
    function prompt:SetupModalBehavior()
        -- Close on shadow click
        connections.shadowClick = Prompts.PromptShadow.MouseButton1Click:Connect(function()
            self:Hide()
        end)
        
        -- Prevent prompt clicks from closing
        connections.promptClick = self.Instance.MouseButton1Click:Connect(function()
            -- Stop propagation
        end)
        
        -- Keyboard handling
        if self.CloseOnEscape then
            connections.keyInput = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                
                if input.KeyCode == Enum.KeyCode.Escape then
                    self:Hide()
                end
            end)
        end
    end
    
    function prompt:UpdateContent(data)
        -- Update title if exists
        local title = self.Instance:FindFirstChild("Title")
        if title and data.title then
            title.Text = data.title
        end
        
        -- Update message if exists
        local message = self.Instance:FindFirstChild("Message")
        if message and data.message then
            message.Text = data.message
        end
        
        -- Update size if provided
        if data.size then
            self.Instance.Size = data.size
        end
    end
    
    function prompt:SetModal(modal)
        self.Modal = modal
    end
    
    function prompt:SetCloseOnEscape(closeOnEscape)
        self.CloseOnEscape = closeOnEscape
    end
    
    function prompt:IsVisible()
        return self.Visible
    end
    
    return prompt
end

-- Utility functions
function Prompt.ShowMessage(title, message, config)
    config = config or {}
    
    -- Create temporary prompt instance
    local promptFrame = Instance.new("Frame")
    promptFrame.Name = "MessagePrompt"
    promptFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    promptFrame.BorderColor3 = Color3.fromRGB(65, 65, 65)
    promptFrame.BorderSizePixel = 1
    promptFrame.Parent = Prompts
    
    -- Add title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = promptFrame
    
    -- Add message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.BackgroundTransparency = 1
    messageLabel.Size = UDim2.new(1, -20, 1, -80)
    messageLabel.Position = UDim2.new(0, 10, 0, 50)
    messageLabel.Text = message
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    messageLabel.TextSize = 14
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextWrapped = true
    messageLabel.Parent = promptFrame
    
    -- Add close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
    closeButton.BorderSizePixel = 0
    closeButton.Size = UDim2.new(0, 80, 0, 30)
    closeButton.Position = UDim2.new(1, -90, 1, -40)
    closeButton.Text = "OK"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 14
    closeButton.Font = Enum.Font.SourceSans
    closeButton.Parent = promptFrame
    
    local prompt = Prompt.new(promptFrame, config)
    
    closeButton.MouseButton1Click:Connect(function()
        prompt:Hide()
        promptFrame:Destroy()
    end)
    
    prompt:Show({
        size = UDim2.new(0, 400, 0, 200)
    })
    
    return prompt
end

return Prompt