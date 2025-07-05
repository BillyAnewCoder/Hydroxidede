local BaseComponent = import("ui/components/BaseComponent")
local UserInputService = game:GetService("UserInputService")

local List = setmetatable({}, {__index = BaseComponent})
List.__index = List

local ListItem = setmetatable({}, {__index = BaseComponent})
ListItem.__index = ListItem

local activeList = nil
local ctrlHeld = false

function List.new(instance, config)
    local list = setmetatable(BaseComponent.new(instance), List)
    
    config = config or {}
    list.multiSelect = config.multiSelect or false
    list.items = {}
    list.selectedItems = {}
    list.contextMenu = nil
    list.onSelectionChanged = config.onSelectionChanged
    
    list:setupScrolling()
    list:setupInputHandling()
    
    return list
end

function List:setupScrolling()
    if self.instance then
        self.instance.CanvasSize = UDim2.new(0, 0, 0, BaseComponent.CONSTANTS.SPACING.MEDIUM)
        self.instance.ScrollBarThickness = 8
        self.instance.ScrollBarImageColor3 = BaseComponent.CONSTANTS.COLORS.ACCENT
    end
end

function List:setupInputHandling()
    -- Global input handling for multi-select
    if not activeList then
        activeList = self
        
        UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.LeftControl then
                ctrlHeld = true
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 and not ctrlHeld then
                -- Clear selection when clicking outside
                for _, list in pairs({activeList}) do
                    if list and list.selectedItems then
                        list:clearSelection()
                    end
                end
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.LeftControl then
                ctrlHeld = false
            end
        end)
    end
end

function List:addItem(data, template)
    local itemInstance = template:Clone()
    itemInstance.Parent = self.instance
    
    local item = ListItem.new(itemInstance, self, data)
    table.insert(self.items, item)
    
    self:recalculateSize()
    return item
end

function List:removeItem(item)
    local index = table.find(self.items, item)
    if index then
        table.remove(self.items, index)
        item:destroy()
        self:recalculateSize()
    end
end

function List:clearItems()
    for _, item in ipairs(self.items) do
        item:destroy()
    end
    self.items = {}
    self.selectedItems = {}
    self:recalculateSize()
end

function List:recalculateSize()
    local totalHeight = BaseComponent.CONSTANTS.SPACING.MEDIUM
    
    for _, item in ipairs(self.items) do
        if item.instance and item.instance.Visible then
            totalHeight = totalHeight + item.instance.AbsoluteSize.Y + BaseComponent.CONSTANTS.SPACING.SMALL
        end
    end
    
    if self.instance then
        self.instance.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    end
end

function List:selectItem(item, addToSelection)
    if not addToSelection or not self.multiSelect then
        self:clearSelection()
    end
    
    if not table.find(self.selectedItems, item) then
        table.insert(self.selectedItems, item)
        item:setSelected(true)
        
        if self.onSelectionChanged then
            self.onSelectionChanged(self.selectedItems)
        end
    end
end

function List:deselectItem(item)
    local index = table.find(self.selectedItems, item)
    if index then
        table.remove(self.selectedItems, index)
        item:setSelected(false)
        
        if self.onSelectionChanged then
            self.onSelectionChanged(self.selectedItems)
        end
    end
end

function List:clearSelection()
    for _, item in ipairs(self.selectedItems) do
        item:setSelected(false)
    end
    self.selectedItems = {}
    
    if self.onSelectionChanged then
        self.onSelectionChanged(self.selectedItems)
    end
end

function List:setContextMenu(contextMenu)
    self.contextMenu = contextMenu
end

-- ListItem implementation
function ListItem.new(instance, parentList, data)
    local item = setmetatable(BaseComponent.new(instance), ListItem)
    
    item.parentList = parentList
    item.data = data
    item.selected = false
    item.callback = nil
    item.rightCallback = nil
    
    item:setupInteractions()
    item:setupAppearance()
    
    return item
end

function ListItem:setupAppearance()
    local colors = BaseComponent.CONSTANTS.COLORS
    
    self.animations.select = self:createTween(
        self.instance,
        {BackgroundColor3 = colors.SELECTED}
    )
    
    self.animations.deselect = self:createTween(
        self.instance,
        {BackgroundColor3 = colors.SECONDARY}
    )
    
    self.animations.hover = self:createTween(
        self.instance,
        {BackgroundColor3 = colors.HOVER}
    )
end

function ListItem:setupInteractions()
    if not self.instance then return end
    
    self:addConnection(self.instance.MouseButton1Click, function()
        if self.parentList.multiSelect and ctrlHeld then
            if self.selected then
                self.parentList:deselectItem(self)
            else
                self.parentList:selectItem(self, true)
            end
        else
            self.parentList:selectItem(self, false)
            if self.callback then
                self.callback(self)
            end
        end
    end)
    
    self:addConnection(self.instance.MouseButton2Click, function()
        if self.rightCallback then
            self.rightCallback(self)
        elseif self.parentList.contextMenu then
            self.parentList.contextMenu:show()
        end
    end)
    
    self:addConnection(self.instance.MouseEnter, function()
        if not self.selected then
            self.animations.hover:Play()
        end
    end)
    
    self:addConnection(self.instance.MouseLeave, function()
        if not self.selected then
            self.animations.deselect:Play()
        end
    end)
end

function ListItem:setSelected(selected)
    self.selected = selected
    
    if selected then
        self.animations.select:Play()
    else
        self.animations.deselect:Play()
    end
end

function ListItem:setCallback(callback)
    self.callback = callback
end

function ListItem:setRightCallback(callback)
    self.rightCallback = callback
end

return List, ListItem