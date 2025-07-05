local BaseComponent = import("ui/components/BaseComponent")
local UserInputService = game:GetService("UserInputService")

local Dropdown = setmetatable({}, {__index = BaseComponent})
Dropdown.__index = Dropdown

local activeDropdowns = {}

function Dropdown.new(instance, config)
    local dropdown = setmetatable(BaseComponent.new(instance), Dropdown)
    
    config = config or {}
    dropdown.options = config.options or {}
    dropdown.selectedOption = config.defaultOption
    dropdown.callback = config.callback
    dropdown.collapsed = true
    dropdown.maxVisibleOptions = config.maxVisibleOptions or 5
    
    dropdown:setupComponents()
    dropdown:setupInteractions()
    dropdown:setupGlobalHandling()
    
    table.insert(activeDropdowns, dropdown)
    
    return dropdown
end

function Dropdown:setupComponents()
    if not self.instance then return end
    
    -- Main button
    self.button = self.instance:FindFirstChild("Button") or self.instance
    self.label = self.button:FindFirstChild("Label")
    self.arrow = self.button:FindFirstChild("Arrow")
    
    -- Options container
    self.optionsContainer = self.instance:FindFirstChild("Options")
    if not self.optionsContainer then
        self.optionsContainer = Instance.new("Frame")
        self.optionsContainer.Name = "Options"
        self.optionsContainer.BackgroundColor3 = BaseComponent.CONSTANTS.COLORS.PRIMARY
        self.optionsContainer.BorderColor3 = BaseComponent.CONSTANTS.COLORS.ACCENT
        self.optionsContainer.BorderSizePixel = 1
        self.optionsContainer.Position = UDim2.new(0, 0, 1, 2)
        self.optionsContainer.Size = UDim2.new(1, 0, 0, 0)
        self.optionsContainer.Visible = false
        self.optionsContainer.ZIndex = self.instance.ZIndex + 1
        self.optionsContainer.Parent = self.instance
        
        -- Scrolling frame for options
        self.optionsList = Instance.new("ScrollingFrame")
        self.optionsList.Name = "OptionsList"
        self.optionsList.BackgroundTransparency = 1
        self.optionsList.BorderSizePixel = 0
        self.optionsList.Size = UDim2.new(1, 0, 1, 0)
        self.optionsList.ScrollBarThickness = 6
        self.optionsList.ScrollBarImageColor3 = BaseComponent.CONSTANTS.COLORS.ACCENT
        self.optionsList.Parent = self.optionsContainer
        
        -- Layout for options
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = self.optionsList
    else
        self.optionsList = self.optionsContainer:FindFirstChild("OptionsList")
    end
    
    self:updateOptions()
    self:updateSelectedDisplay()
end

function Dropdown:setupInteractions()
    if not self.button then return end
    
    -- Create animations
    self.animations.expand = self:createTween(
        self.optionsContainer,
        {Size = UDim2.new(1, 0, 0, math.min(#self.options * 30, self.maxVisibleOptions * 30))}
    )
    
    self.animations.collapse = self:createTween(
        self.optionsContainer,
        {Size = UDim2.new(1, 0, 0, 0)}
    )
    
    if self.arrow then
        self.animations.arrowDown = self:createTween(
            self.arrow,
            {Rotation = 180}
        )
        
        self.animations.arrowUp = self:createTween(
            self.arrow,
            {Rotation = 0}
        )
    end
    
    -- Button click to toggle
    self:addConnection(self.button.MouseButton1Click, function()
        self:toggle()
    end)
end

function Dropdown:setupGlobalHandling()
    -- Close dropdown when clicking outside
    if #activeDropdowns == 1 then
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                for _, dropdown in ipairs(activeDropdowns) do
                    if dropdown and not dropdown.collapsed then
                        dropdown:collapse()
                    end
                end
            end
        end)
    end
end

function Dropdown:updateOptions()
    if not self.optionsList then return end
    
    -- Clear existing options
    for _, child in ipairs(self.optionsList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Create option buttons
    for i, option in ipairs(self.options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Name = "Option" .. i
        optionButton.BackgroundColor3 = BaseComponent.CONSTANTS.COLORS.PRIMARY
        optionButton.BackgroundTransparency = 1
        optionButton.BorderSizePixel = 0
        optionButton.Size = UDim2.new(1, 0, 0, 30)
        optionButton.Text = option.text or tostring(option)
        optionButton.TextColor3 = BaseComponent.CONSTANTS.COLORS.TEXT_PRIMARY
        optionButton.TextSize = 14
        optionButton.Font = Enum.Font.SourceSans
        optionButton.TextXAlignment = Enum.TextXAlignment.Left
        optionButton.LayoutOrder = i
        optionButton.Parent = self.optionsList
        
        -- Add padding
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim2.new(0, BaseComponent.CONSTANTS.SPACING.MEDIUM)
        padding.Parent = optionButton
        
        -- Hover effect
        local hoverIn = self:createTween(
            optionButton,
            {BackgroundColor3 = BaseComponent.CONSTANTS.COLORS.HOVER}
        )
        
        local hoverOut = self:createTween(
            optionButton,
            {BackgroundColor3 = BaseComponent.CONSTANTS.COLORS.PRIMARY}
        )
        
        optionButton.MouseEnter:Connect(function()
            hoverIn:Play()
        end)
        
        optionButton.MouseLeave:Connect(function()
            hoverOut:Play()
        end)
        
        -- Selection
        optionButton.MouseButton1Click:Connect(function()
            self:selectOption(option, i)
        end)
    end
    
    -- Update canvas size
    self.optionsList.CanvasSize = UDim2.new(0, 0, 0, #self.options * 30)
end

function Dropdown:selectOption(option, index)
    self.selectedOption = option
    self.selectedIndex = index
    
    self:updateSelectedDisplay()
    self:collapse()
    
    if self.callback then
        self.callback(option, index)
    end
end

function Dropdown:updateSelectedDisplay()
    if self.label and self.selectedOption then
        local displayText = self.selectedOption.text or tostring(self.selectedOption)
        self.label.Text = displayText
    end
end

function Dropdown:expand()
    if self.collapsed then
        self.collapsed = false
        self.optionsContainer.Visible = true
        
        if self.animations.expand then
            self.animations.expand:Play()
        end
        
        if self.animations.arrowDown then
            self.animations.arrowDown:Play()
        end
    end
end

function Dropdown:collapse()
    if not self.collapsed then
        self.collapsed = true
        
        if self.animations.collapse then
            self.animations.collapse:Play()
            self.animations.collapse.Completed:Connect(function()
                self.optionsContainer.Visible = false
            end)
        else
            self.optionsContainer.Visible = false
        end
        
        if self.animations.arrowUp then
            self.animations.arrowUp:Play()
        end
    end
end

function Dropdown:toggle()
    if self.collapsed then
        self:expand()
    else
        self:collapse()
    end
end

function Dropdown:setOptions(options)
    self.options = options
    self:updateOptions()
end

function Dropdown:setCallback(callback)
    self.callback = callback
end

function Dropdown:destroy()
    -- Remove from active dropdowns
    local index = table.find(activeDropdowns, self)
    if index then
        table.remove(activeDropdowns, index)
    end
    
    BaseComponent.destroy(self)
end

return Dropdown