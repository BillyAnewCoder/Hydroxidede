local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Dropdown = {}
local dropdownCache = {}

-- Enhanced constants
local constants = {
    animationTime = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    colors = {
        hover = Color3.fromRGB(55, 55, 55),
        normal = Color3.fromRGB(35, 35, 35),
        selected = Color3.fromRGB(65, 65, 65)
    }
}

function Dropdown.new(instance, config)
    local dropdown = {}
    config = config or {}
    
    local selection = instance.Selection
    local collapseButton = instance.Collapse
    local label = instance.Label
    
    -- State management
    dropdown.Collapsed = true
    dropdown.Instance = instance
    dropdown.Options = {}
    dropdown.SelectedOption = nil
    dropdown.Callback = config.callback
    dropdown.MaxVisible = config.maxVisible or 5
    
    -- Animation setup
    local expandAnimation = TweenService:Create(selection, constants.animationTime, {
        Size = UDim2.new(1, 0, 0, math.min(#dropdown.Options * 30, dropdown.MaxVisible * 30))
    })
    
    local collapseAnimation = TweenService:Create(selection, constants.animationTime, {
        Size = UDim2.new(1, 0, 0, 0)
    })
    
    -- Collect options
    for _, child in pairs(selection.Clip.List:GetChildren()) do
        if child:IsA("TextButton") then
            table.insert(dropdown.Options, {
                button = child,
                name = child.Name,
                text = child.Text
            })
        end
    end
    
    -- Enhanced option interactions
    for _, option in pairs(dropdown.Options) do
        local button = option.button
        
        -- Hover effects
        local hoverIn = TweenService:Create(button, constants.animationTime, {
            BackgroundColor3 = constants.colors.hover
        })
        local hoverOut = TweenService:Create(button, constants.animationTime, {
            BackgroundColor3 = constants.colors.normal
        })
        
        button.MouseEnter:Connect(function()
            hoverIn:Play()
        end)
        
        button.MouseLeave:Connect(function()
            hoverOut:Play()
        end)
        
        button.MouseButton1Click:Connect(function()
            dropdown:SelectOption(option)
        end)
    end
    
    -- Collapse button interaction
    collapseButton.MouseButton1Click:Connect(function()
        dropdown:Toggle()
    end)
    
    -- Methods
    function dropdown:Toggle()
        if self.Collapsed then
            self:Expand()
        else
            self:Collapse()
        end
    end
    
    function dropdown:Expand()
        if not self.Collapsed then return end
        
        self.Collapsed = false
        selection.Visible = true
        expandAnimation:Play()
        
        -- Update arrow rotation if exists
        local arrow = collapseButton:FindFirstChild("Arrow")
        if arrow then
            TweenService:Create(arrow, constants.animationTime, {
                Rotation = 180
            }):Play()
        end
    end
    
    function dropdown:Collapse()
        if self.Collapsed then return end
        
        self.Collapsed = true
        collapseAnimation:Play()
        
        collapseAnimation.Completed:Connect(function()
            selection.Visible = false
        end)
        
        -- Update arrow rotation if exists
        local arrow = collapseButton:FindFirstChild("Arrow")
        if arrow then
            TweenService:Create(arrow, constants.animationTime, {
                Rotation = 0
            }):Play()
        end
    end
    
    function dropdown:SelectOption(option)
        if not option then return end
        
        -- Update visual state
        if self.SelectedOption then
            TweenService:Create(self.SelectedOption.button, constants.animationTime, {
                BackgroundColor3 = constants.colors.normal
            }):Play()
        end
        
        self.SelectedOption = option
        label.Text = option.text or option.name
        
        TweenService:Create(option.button, constants.animationTime, {
            BackgroundColor3 = constants.colors.selected
        }):Play()
        
        self:Collapse()
        
        -- Trigger callback
        if self.Callback then
            self.Callback(option, self)
        end
    end
    
    function dropdown:SetSelected(optionName)
        for _, option in pairs(self.Options) do
            if option.name == optionName then
                self:SelectOption(option)
                break
            end
        end
    end
    
    function dropdown:SetCallback(callback)
        self.Callback = callback
    end
    
    function dropdown:AddOption(name, text)
        -- Implementation for dynamically adding options
        local button = Instance.new("TextButton")
        button.Name = name
        button.Text = text or name
        button.Parent = selection.Clip.List
        
        local option = {
            button = button,
            name = name,
            text = text
        }
        
        table.insert(self.Options, option)
        
        -- Setup interactions for new option
        local hoverIn = TweenService:Create(button, constants.animationTime, {
            BackgroundColor3 = constants.colors.hover
        })
        local hoverOut = TweenService:Create(button, constants.animationTime, {
            BackgroundColor3 = constants.colors.normal
        })
        
        button.MouseEnter:Connect(function()
            hoverIn:Play()
        end)
        
        button.MouseLeave:Connect(function()
            hoverOut:Play()
        end)
        
        button.MouseButton1Click:Connect(function()
            self:SelectOption(option)
        end)
        
        return option
    end
    
    function dropdown:RemoveOption(optionName)
        for i, option in pairs(self.Options) do
            if option.name == optionName then
                option.button:Destroy()
                table.remove(self.Options, i)
                break
            end
        end
    end
    
    function dropdown:Destroy()
        local index = table.find(dropdownCache, self)
        if index then
            table.remove(dropdownCache, index)
        end
    end
    
    table.insert(dropdownCache, dropdown)
    return dropdown
end

-- Global input handling for auto-collapse
UserInput.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        for _, dropdown in pairs(dropdownCache) do
            if dropdown and not dropdown.Collapsed then
                dropdown:Collapse()
            end
        end
    end
end)

return Dropdown