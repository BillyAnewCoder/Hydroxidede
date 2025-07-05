local BaseComponent = import("ui/components/BaseComponent")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local ContextMenu = setmetatable({}, {__index = BaseComponent})
ContextMenu.__index = ContextMenu

local ContextMenuItem = setmetatable({}, {__index = BaseComponent})
ContextMenuItem.__index = ContextMenuItem

local currentContextMenu = nil

function ContextMenu.new(items, config)
    local menu = setmetatable(BaseComponent.new(), ContextMenu)
    
    config = config or {}
    menu.items = {}
    menu.minWidth = config.minWidth or 150
    menu.maxWidth = config.maxWidth or 300
    
    menu:createInstance()
    menu:setupItems(items or {})
    menu:setupInputHandling()
    
    return menu
end

function ContextMenu:createInstance()
    -- Create the main container
    self.instance = Instance.new("Frame")
    self.instance.Name = "ContextMenu"
    self.instance.BackgroundColor3 = BaseComponent.CONSTANTS.COLORS.PRIMARY
    self.instance.BorderSizePixel = 1
    self.instance.BorderColor3 = BaseComponent.CONSTANTS.COLORS.ACCENT
    self.instance.Visible = false
    self.instance.ZIndex = 1000
    
    -- Add drop shadow effect
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.7
    shadow.BorderSizePixel = 0
    shadow.Position = UDim2.new(0, 2, 0, 2)
    shadow.Size = UDim2.new(1, 0, 1, 0)
    shadow.ZIndex = 999
    shadow.Parent = self.instance
    
    -- Create items container
    self.itemsContainer = Instance.new("Frame")
    self.itemsContainer.Name = "ItemsContainer"
    self.itemsContainer.BackgroundTransparency = 1
    self.itemsContainer.Size = UDim2.new(1, 0, 1, 0)
    self.itemsContainer.Parent = self.instance
    
    -- Add to storage
    local storage = import("rbxassetid://11389137937").ContextMenus
    self.instance.Parent = storage
end

function ContextMenu:setupItems(itemsData)
    for _, itemData in ipairs(itemsData) do
        self:addItem(itemData)
    end
    
    self:updateSize()
end

function ContextMenu:addItem(itemData)
    local item = ContextMenuItem.new(itemData, self)
    table.insert(self.items, item)
    
    item.instance.Parent = self.itemsContainer
    item.instance.Position = UDim2.new(0, 0, 0, (#self.items - 1) * 30)
    
    self:updateSize()
    return item
end

function ContextMenu:updateSize()
    local maxWidth = self.minWidth
    local totalHeight = 0
    
    -- Calculate required width and height
    for _, item in ipairs(self.items) do
        local textSize = TextService:GetTextSize(
            item.text,
            14,
            Enum.Font.SourceSans,
            Vector2.new(math.huge, 20)
        )
        
        local requiredWidth = textSize.X + 40 + (item.icon and 20 or 0)
        maxWidth = math.max(maxWidth, requiredWidth)
        totalHeight = totalHeight + 30
    end
    
    maxWidth = math.min(maxWidth, self.maxWidth)
    
    -- Update container size
    self.instance.Size = UDim2.new(0, maxWidth, 0, totalHeight)
    
    -- Update item sizes
    for _, item in ipairs(self.items) do
        item.instance.Size = UDim2.new(1, 0, 0, 30)
    end
end

function ContextMenu:setupInputHandling()
    -- Close menu when clicking outside
    self:addConnection(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and self.visible then
            self:hide()
        end
    end)
end

function ContextMenu:show(position)
    if currentContextMenu and currentContextMenu ~= self then
        currentContextMenu:hide()
    end
    
    currentContextMenu = self
    
    -- Set position
    if position then
        self.instance.Position = UDim2.new(0, position.X, 0, position.Y)
    else
        local mouse = game:GetService("Players").LocalPlayer:GetMouse()
        self.instance.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
    end
    
    -- Show with animation
    self.instance.Visible = true
    self.visible = true
    
    local showAnimation = self:createTween(
        self.instance,
        {BackgroundTransparency = 0},
        0.1
    )
    showAnimation:Play()
end

function ContextMenu:hide()
    if not self.visible then return end
    
    local hideAnimation = self:createTween(
        self.instance,
        {BackgroundTransparency = 1},
        0.1
    )
    
    hideAnimation.Completed:Connect(function()
        self.instance.Visible = false
        self.visible = false
    end)
    
    hideAnimation:Play()
    
    if currentContextMenu == self then
        currentContextMenu = nil
    end
end

-- ContextMenuItem implementation
function ContextMenuItem.new(data, parentMenu)
    local item = setmetatable(BaseComponent.new(), ContextMenuItem)
    
    item.parentMenu = parentMenu
    item.text = data.text or "Menu Item"
    item.icon = data.icon
    item.callback = data.callback
    item.enabled = data.enabled ~= false
    
    item:createInstance()
    item:setupInteractions()
    
    return item
end

function ContextMenuItem:createInstance()
    self.instance = Instance.new("TextButton")
    self.instance.Name = "ContextMenuItem"
    self.instance.BackgroundColor3 = BaseComponent.CONSTANTS.COLORS.PRIMARY
    self.instance.BackgroundTransparency = 1
    self.instance.BorderSizePixel = 0
    self.instance.Text = ""
    self.instance.AutoButtonColor = false
    
    -- Create icon
    if self.icon then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.BackgroundTransparency = 1
        icon.Image = self.icon
        icon.Size = UDim2.new(0, 16, 0, 16)
        icon.Position = UDim2.new(0, 8, 0.5, -8)
        icon.ImageColor3 = BaseComponent.CONSTANTS.COLORS.TEXT_PRIMARY
        icon.Parent = self.instance
    end
    
    -- Create label
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Text = self.text
    label.TextColor3 = self.enabled and 
        BaseComponent.CONSTANTS.COLORS.TEXT_PRIMARY or 
        BaseComponent.CONSTANTS.COLORS.TEXT_DISABLED
    label.TextSize = 14
    label.Font = Enum.Font.SourceSans
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Size = UDim2.new(1, self.icon and -32 or -16, 1, 0)
    label.Position = UDim2.new(0, self.icon and 32 or 16, 0, 0)
    label.Parent = self.instance
end

function ContextMenuItem:setupInteractions()
    if not self.enabled then return end
    
    self.animations.hover = self:createTween(
        self.instance,
        {BackgroundColor3 = BaseComponent.CONSTANTS.COLORS.HOVER}
    )
    
    self.animations.normal = self:createTween(
        self.instance,
        {BackgroundColor3 = BaseComponent.CONSTANTS.COLORS.PRIMARY}
    )
    
    self:addConnection(self.instance.MouseEnter, function()
        self.animations.hover:Play()
    end)
    
    self:addConnection(self.instance.MouseLeave, function()
        self.animations.normal:Play()
    end)
    
    self:addConnection(self.instance.MouseButton1Click, function()
        if self.callback then
            self.callback(self)
        end
        self.parentMenu:hide()
    end)
end

return ContextMenu, ContextMenuItem