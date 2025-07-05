local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local Interface = import("rbxassetid://11389137937")
local Base = Interface.Base
local Object = Base.MessageBox
local Shadow = Base.MessageBoxShadow

local MessageBox = {}
local MessageType = {}

local selectedButtons
local connections = {}

-- Enhanced constants
local constants = {
    dynamicWidth = Vector2.new(133742069, 25),
    dynamicHeight = Vector2.new(Object.AbsoluteSize.X, 133742069),
    minWidth = 300,
    maxWidth = 600,
    animationTime = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    fadeTime = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
}

MessageType.OK = 1
MessageType.OKCancel = 2
MessageType.YesNo = 3
MessageType.YesNoCancel = 4

function MessageBox.Show(title, message, messageType, firstCallback, secondCallback, thirdCallback)
    -- Clean up previous connections
    MessageBox.Hide()
    
    local first, second, third
    local inner = Object.Inner
    local buttons = inner.Buttons
    
    -- Calculate dynamic sizing
    local titleWidth = TextService:GetTextSize(title, 18, "SourceSansBold", constants.dynamicWidth).X + 20
    local messageWidth = math.max(titleWidth, constants.minWidth)
    messageWidth = math.min(messageWidth, constants.maxWidth)
    
    local messageHeight = TextService:GetTextSize(
        message, 
        16, 
        "SourceSans", 
        Vector2.new(messageWidth - 40, 133742069)
    ).Y + 120
    
    -- Button configuration
    if messageType == MessageType.OK then
        selectedButtons = buttons.OK
        first = selectedButtons.OK
    elseif messageType == MessageType.OKCancel then
        selectedButtons = buttons.OKCancel
        first = selectedButtons.OK
        second = selectedButtons.Cancel
    elseif messageType == MessageType.YesNo then
        selectedButtons = buttons.YesNo
        first = selectedButtons.Yes
        second = selectedButtons.No
    elseif messageType == MessageType.YesNoCancel then
        selectedButtons = buttons.YesNoCancel
        first = selectedButtons.Yes
        second = selectedButtons.No
        third = selectedButtons.Cancel
    else
        return
    end
    
    -- Update content
    Object.Title.Text = title
    inner.Message.Text = message
    
    -- Set size and position
    Object.Size = UDim2.new(0, messageWidth, 0, messageHeight)
    Object.Position = UDim2.new(0.5, -(messageWidth / 2), 0.5, -(messageHeight / 2))
    
    -- Enhanced button styling and interactions
    local function setupButton(button, callback, isDefault)
        if not button then return end
        
        -- Enhanced styling for default button
        if isDefault then
            button.BackgroundColor3 = Color3.fromRGB(65, 105, 225)
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        
        -- Hover effects
        local originalColor = button.BackgroundColor3
        local hoverColor = Color3.new(
            math.min(originalColor.R + 0.1, 1),
            math.min(originalColor.G + 0.1, 1),
            math.min(originalColor.B + 0.1, 1)
        )
        
        local hoverIn = TweenService:Create(button, constants.fadeTime, {
            BackgroundColor3 = hoverColor
        })
        local hoverOut = TweenService:Create(button, constants.fadeTime, {
            BackgroundColor3 = originalColor
        })
        
        connections.hover = button.MouseEnter:Connect(function()
            hoverIn:Play()
        end)
        
        connections.leave = button.MouseLeave:Connect(function()
            hoverOut:Play()
        end)
        
        connections.click = button.MouseButton1Click:Connect(function()
            if callback then
                callback()
            end
            MessageBox.Hide()
        end)
    end
    
    setupButton(first, firstCallback, true)
    setupButton(second, secondCallback, false)
    setupButton(third, thirdCallback, false)
    
    -- Show with enhanced animations
    selectedButtons.Visible = true
    Shadow.Visible = true
    Object.Visible = true
    
    -- Scale animation
    Object.Size = UDim2.new(0, 0, 0, 0)
    local scaleAnimation = TweenService:Create(Object, constants.animationTime, {
        Size = UDim2.new(0, messageWidth, 0, messageHeight)
    })
    
    -- Fade in shadow
    Shadow.BackgroundTransparency = 1
    local shadowAnimation = TweenService:Create(Shadow, constants.fadeTime, {
        BackgroundTransparency = 0.5
    })
    
    scaleAnimation:Play()
    shadowAnimation:Play()
    
    -- Keyboard support
    connections.keyInput = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
            -- Enter key triggers first button (default)
            if first and firstCallback then
                firstCallback()
                MessageBox.Hide()
            end
        elseif input.KeyCode == Enum.KeyCode.Escape then
            -- Escape key cancels
            if messageType == MessageType.OKCancel and secondCallback then
                secondCallback()
            elseif messageType == MessageType.YesNoCancel and thirdCallback then
                thirdCallback()
            end
            MessageBox.Hide()
        end
    end)
end

function MessageBox.Hide()
    -- Disconnect all connections
    for name, connection in pairs(connections) do
        if connection then
            connection:Disconnect()
        end
    end
    connections = {}
    
    if Object.Visible then
        -- Hide with animation
        local hideAnimation = TweenService:Create(Object, constants.fadeTime, {
            Size = UDim2.new(0, 0, 0, 0)
        })
        
        local shadowHide = TweenService:Create(Shadow, constants.fadeTime, {
            BackgroundTransparency = 1
        })
        
        hideAnimation.Completed:Connect(function()
            Shadow.Visible = false
            Object.Visible = false
            if selectedButtons then
                selectedButtons.Visible = false
            end
        end)
        
        hideAnimation:Play()
        shadowHide:Play()
    end
end

-- Enhanced utility functions
function MessageBox.ShowError(title, message, callback)
    return MessageBox.Show(title, message, MessageType.OK, callback)
end

function MessageBox.ShowWarning(title, message, okCallback, cancelCallback)
    return MessageBox.Show(title, message, MessageType.OKCancel, okCallback, cancelCallback)
end

function MessageBox.ShowConfirm(title, message, yesCallback, noCallback)
    return MessageBox.Show(title, message, MessageType.YesNo, yesCallback, noCallback)
end

function MessageBox.ShowQuestion(title, message, yesCallback, noCallback, cancelCallback)
    return MessageBox.Show(title, message, MessageType.YesNoCancel, yesCallback, noCallback, cancelCallback)
end

return MessageBox, MessageType