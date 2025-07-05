-- Base component class for all UI elements
local BaseComponent = {}
BaseComponent.__index = BaseComponent

local TweenService = game:GetService("TweenService")

-- Constants for consistent styling
local CONSTANTS = {
    ANIMATION = {
        FADE_TIME = 0.15,
        SLIDE_TIME = 0.25,
        EASE_STYLE = Enum.EasingStyle.Quad,
        EASE_DIRECTION = Enum.EasingDirection.Out
    },
    COLORS = {
        PRIMARY = Color3.fromRGB(45, 45, 45),
        SECONDARY = Color3.fromRGB(35, 35, 35),
        ACCENT = Color3.fromRGB(65, 65, 65),
        TEXT_PRIMARY = Color3.fromRGB(255, 255, 255),
        TEXT_SECONDARY = Color3.fromRGB(200, 200, 200),
        TEXT_DISABLED = Color3.fromRGB(127, 127, 127),
        SUCCESS = Color3.fromRGB(76, 175, 80),
        WARNING = Color3.fromRGB(255, 193, 7),
        ERROR = Color3.fromRGB(244, 67, 54),
        HOVER = Color3.fromRGB(55, 55, 55),
        SELECTED = Color3.fromRGB(65, 65, 65)
    },
    SPACING = {
        SMALL = 4,
        MEDIUM = 8,
        LARGE = 16,
        XLARGE = 24
    }
}

function BaseComponent.new(instance)
    local component = setmetatable({}, BaseComponent)
    
    component.instance = instance
    component.connections = {}
    component.animations = {}
    component.children = {}
    component.visible = true
    component.enabled = true
    
    return component
end

function BaseComponent:createTween(target, properties, duration, style, direction)
    duration = duration or CONSTANTS.ANIMATION.FADE_TIME
    style = style or CONSTANTS.ANIMATION.EASE_STYLE
    direction = direction or CONSTANTS.ANIMATION.EASE_DIRECTION
    
    local tweenInfo = TweenInfo.new(duration, style, direction)
    return TweenService:Create(target, tweenInfo, properties)
end

function BaseComponent:addConnection(event, callback)
    local connection = event:Connect(callback)
    table.insert(self.connections, connection)
    return connection
end

function BaseComponent:addChild(child)
    table.insert(self.children, child)
    return child
end

function BaseComponent:setVisible(visible)
    self.visible = visible
    if self.instance then
        self.instance.Visible = visible
    end
end

function BaseComponent:setEnabled(enabled)
    self.enabled = enabled
    -- Override in subclasses for specific behavior
end

function BaseComponent:destroy()
    -- Disconnect all connections
    for _, connection in ipairs(self.connections) do
        if connection then
            connection:Disconnect()
        end
    end
    
    -- Stop all animations
    for _, animation in pairs(self.animations) do
        if animation then
            animation:Cancel()
        end
    end
    
    -- Destroy children
    for _, child in ipairs(self.children) do
        if child and child.destroy then
            child:destroy()
        end
    end
    
    -- Destroy instance
    if self.instance then
        self.instance:Destroy()
    end
    
    -- Clear references
    self.connections = {}
    self.animations = {}
    self.children = {}
end

BaseComponent.CONSTANTS = CONSTANTS
return BaseComponent