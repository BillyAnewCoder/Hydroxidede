local UserInput = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local List = {}
local ListButton = {}

local lists = {}
local ctrlHeld = false
local shiftHeld = false

-- Enhanced constants
local constants = {
    tweenTime = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    colors = {
        selected = Color3.fromRGB(65, 65, 65),
        deselected = Color3.fromRGB(35, 35, 35),
        hover = Color3.fromRGB(55, 55, 55),
        multiSelect = Color3.fromRGB(45, 75, 45)
    },
    spacing = 5,
    padding = 15
}

function List.new(instance, config)
    local list = {}
    config = config or {}
    
    instance.CanvasSize = UDim2.new(0, 0, 0, constants.padding)
    
    list.Buttons = {}
    list.Instance = instance
    list.MultiClickEnabled = config.multiSelect or false
    list.Selected = nil
    list.LastSelected = nil
    list.ContextMenu = nil
    list.ContextMenuSelected = nil
    list.OnSelectionChanged = config.onSelectionChanged
    list.FilterFunction = config.filterFunction
    
    -- Enhanced scrolling
    instance.ScrollBarThickness = 8
    instance.ScrollBarImageColor3 = Color3.fromRGB(65, 65, 65)
    instance.ScrollingDirection = Enum.ScrollingDirection.Y
    instance.CanvasPosition = Vector2.new(0, 0)
    
    table.insert(lists, list)
    
    -- Methods
    function list:Clear()
        for instance, listButton in pairs(self.Buttons) do
            if listButton and listButton.Destroy then
                listButton:Destroy()
            end
        end
        
        self.Instance.CanvasSize = UDim2.new(0, 0, 0, constants.padding)
        self.Buttons = {}
        self.Selected = nil
        self.LastSelected = nil
        
        if self.OnSelectionChanged then
            self.OnSelectionChanged({})
        end
    end
    
    function list:Recalculate()
        local newHeight = constants.padding
        
        for instance, listButton in pairs(self.Buttons) do
            if instance.Visible then
                newHeight = newHeight + instance.AbsoluteSize.Y + constants.spacing
            end
        end
        
        self.Instance.CanvasSize = UDim2.new(0, 0, 0, newHeight)
    end
    
    function list:Filter(query)
        if not self.FilterFunction then return end
        
        for instance, listButton in pairs(self.Buttons) do
            local visible = self.FilterFunction(listButton, query)
            instance.Visible = visible
        end
        
        self:Recalculate()
    end
    
    function list:SelectRange(from, to)
        if not self.MultiClickEnabled then return end
        
        local buttons = {}
        for instance, button in pairs(self.Buttons) do
            table.insert(buttons, {instance = instance, button = button})
        end
        
        table.sort(buttons, function(a, b)
            return a.instance.Position.Y.Offset < b.instance.Position.Y.Offset
        end)
        
        local fromIndex, toIndex
        for i, data in ipairs(buttons) do
            if data.button == from then fromIndex = i end
            if data.button == to then toIndex = i end
        end
        
        if fromIndex and toIndex then
            local start, finish = math.min(fromIndex, toIndex), math.max(fromIndex, toIndex)
            for i = start, finish do
                local button = buttons[i].button
                if not table.find(self.Selected, button) then
                    table.insert(self.Selected, button)
                    button.SelectAnimation:Play()
                end
            end
            
            if self.OnSelectionChanged then
                self.OnSelectionChanged(self.Selected)
            end
        end
    end
    
    function list:BindContextMenu(contextMenu)
        self.ContextMenu = contextMenu
    end
    
    function list:BindContextMenuSelected(contextMenu)
        self.ContextMenuSelected = contextMenu
    end
    
    return list
end

function ListButton.new(instance, list, config)
    local listButton = {}
    config = config or {}
    
    local listInstance = list.Instance
    list.Buttons[instance] = listButton
    
    -- Calculate position and update canvas
    if instance.Visible then
        listInstance.CanvasSize = listInstance.CanvasSize + UDim2.new(0, 0, 0, instance.AbsoluteSize.Y + constants.spacing)
    end
    
    instance.Parent = listInstance
    
    -- State management
    listButton.List = list
    listButton.Instance = instance
    listButton.Data = config.data
    listButton.Callback = config.callback
    listButton.RightCallback = config.rightCallback
    listButton.SelectedCallback = config.selectedCallback
    listButton.Selected = false
    
    -- Enhanced animations
    listButton.SelectAnimation = TweenService:Create(instance, constants.tweenTime, { 
        BackgroundColor3 = constants.colors.selected 
    })
    listButton.DeselectAnimation = TweenService:Create(instance, constants.tweenTime, { 
        BackgroundColor3 = constants.colors.deselected 
    })
    listButton.HoverAnimation = TweenService:Create(instance, constants.tweenTime, { 
        BackgroundColor3 = constants.colors.hover 
    })
    listButton.MultiSelectAnimation = TweenService:Create(instance, constants.tweenTime, { 
        BackgroundColor3 = constants.colors.multiSelect 
    })
    
    -- Event connections
    local connections = {}
    
    connections.click = instance.MouseButton1Click:Connect(function()
        if list.MultiClickEnabled and ctrlHeld then
            -- Multi-select mode
            if not list.Selected then
                list.Selected = {}
            end
            
            local foundIndex = table.find(list.Selected, listButton)
            
            if foundIndex then
                table.remove(list.Selected, foundIndex)
                listButton.DeselectAnimation:Play()
                listButton.Selected = false
            else
                table.insert(list.Selected, listButton)
                listButton.MultiSelectAnimation:Play()
                listButton.Selected = true
            end
            
            if listButton.SelectedCallback then
                listButton.SelectedCallback(listButton)
            end
            
            if list.OnSelectionChanged then
                list.OnSelectionChanged(list.Selected)
            end
            
        elseif list.MultiClickEnabled and shiftHeld and list.LastSelected then
            -- Range select mode
            if not list.Selected then
                list.Selected = {}
            end
            list:SelectRange(list.LastSelected, listButton)
            
        else
            -- Single select mode
            if list.Selected then
                for _, selected in pairs(list.Selected) do
                    if selected ~= listButton then
                        selected.DeselectAnimation:Play()
                        selected.Selected = false
                    end
                end
            end
            
            list.Selected = {listButton}
            list.LastSelected = listButton
            listButton.SelectAnimation:Play()
            listButton.Selected = true
            
            if listButton.Callback then
                listButton.Callback(listButton)
            end
            
            if list.OnSelectionChanged then
                list.OnSelectionChanged(list.Selected)
            end
        end
    end)
    
    connections.rightClick = instance.MouseButton2Click:Connect(function()
        if not ctrlHeld then
            if listButton.RightCallback then
                listButton.RightCallback(listButton)
            elseif list.Selected and #list.Selected > 0 and list.ContextMenuSelected then
                list.ContextMenuSelected:Show()
            elseif list.ContextMenu then
                list.ContextMenu:Show()
            end
        end
    end)
    
    connections.hover = instance.MouseEnter:Connect(function()
        if not listButton.Selected then
            listButton.HoverAnimation:Play()
        end
    end)
    
    connections.leave = instance.MouseLeave:Connect(function()
        if not listButton.Selected then
            listButton.DeselectAnimation:Play()
        end
    end)
    
    -- Methods
    function listButton:SetCallback(callback)
        self.Callback = callback
    end
    
    function listButton:SetRightCallback(callback)
        self.RightCallback = callback
    end
    
    function listButton:SetSelectedCallback(callback)
        self.SelectedCallback = callback
    end
    
    function listButton:SetData(data)
        self.Data = data
    end
    
    function listButton:Remove()
        local list = self.List
        local instance = self.Instance
        local listInstance = list.Instance
        
        -- Remove from selection if selected
        if list.Selected then
            local index = table.find(list.Selected, self)
            if index then
                table.remove(list.Selected, index)
            end
        end
        
        -- Update canvas size
        if instance.Visible then
            listInstance.CanvasSize = listInstance.CanvasSize - UDim2.new(0, 0, 0, instance.AbsoluteSize.Y + constants.spacing)
        end
        
        list.Buttons[instance] = nil
        self:Destroy()
    end
    
    function listButton:Destroy()
        for _, connection in pairs(connections) do
            if connection then
                connection:Disconnect()
            end
        end
        
        if self.Instance then
            self.Instance:Destroy()
        end
    end
    
    return listButton
end

-- Enhanced global input handling
oh.Events.ListInputBegan = UserInput.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftControl then
        ctrlHeld = true
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        shiftHeld = true
    elseif not ctrlHeld and not shiftHeld and input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Clear all selections when clicking outside
        for _, list in pairs(lists) do
            if list.Selected then
                for _, listButton in pairs(list.Selected) do
                    listButton.DeselectAnimation:Play()
                    listButton.Selected = false
                end
                list.Selected = nil
                list.LastSelected = nil
                
                if list.OnSelectionChanged then
                    list.OnSelectionChanged({})
                end
            end
        end
    end
end)

oh.Events.ListInputEnded = UserInput.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftControl then
        ctrlHeld = false
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        shiftHeld = false
    end
end)

return List, ListButton