local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local TabSelector = {}

local Base = import("rbxassetid://11389137937").Base
local Tabs = Base.Tabs.Container
local Pages = Base.Body.Pages

local MessageBox, MessageType = import("ui/controls/MessageBox")

local requiredMethods = {
    ConstantScanner = import("modules/ConstantScanner").RequiredMethods,
    UpvalueScanner = import("modules/UpvalueScanner").RequiredMethods,
    ScriptScanner = import("modules/ScriptScanner").RequiredMethods,
    ModuleScanner = import("modules/ModuleScanner").RequiredMethods,
    ClosureSpy = import("modules/ClosureSpy").RequiredMethods,
    RemoteSpy = import("modules/RemoteSpy").RequiredMethods
}

-- Enhanced constants
local constants = {
    fadeLength = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    slideLength = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    colors = {
        tabSelected = Color3.fromRGB(65, 65, 65),
        iconSelected = Color3.fromRGB(255, 255, 255),
        tabUnselected = Color3.fromRGB(35, 35, 35),
        iconUnselected = Color3.fromRGB(127, 127, 127),
        tabHover = Color3.fromRGB(55, 55, 55),
        iconHover = Color3.fromRGB(200, 200, 200)
    }
}

local selectedTab 
local selectedPage = Pages.Home
local animationCache = {}
local tabHistory = {}

local function methodsCheck(methods)
    local globalMethods = oh.Methods
    local missingMethods = ""

    for methodName in pairs(methods) do
        if not globalMethods[methodName] then
            missingMethods = missingMethods .. methodName .. ", "
        end
    end

    return (missingMethods ~= "" and missingMethods:sub(1, -3)) or nil
end

local function selectTab(tabName, addToHistory)
    local methodsFound = requiredMethods[tabName]
    local missingMethods = methodsFound and methodsCheck(methodsFound)

    if missingMethods then
        return MessageBox.Show(
            "Your exploit does not support this section",
            "The following functions are missing from your exploit: " .. missingMethods,
            MessageType.OK
        )
    end

    local tab = Tabs:FindFirstChild(tabName)
    local page = Pages:FindFirstChild(tabName)

    if not tab or not page then
        warn("Tab or page not found: " .. tabName)
        return false
    end

    -- Add to history
    if addToHistory ~= false and selectedTab and selectedTab.Name ~= tabName then
        table.insert(tabHistory, selectedTab.Name)
        if #tabHistory > 10 then
            table.remove(tabHistory, 1)
        end
    end

    -- Deselect current tab
    if selectedTab then
        local tabAnimation = animationCache[selectedTab]
        if tabAnimation then
            tabAnimation.unselected:Play()
            tabAnimation.iconUnselected:Play()
        end
    end

    -- Hide current page with slide animation
    if selectedPage then
        local slideOut = TweenService:Create(selectedPage, constants.slideLength, {
            Position = UDim2.new(-1, 0, 0, 0)
        })
        slideOut:Play()
        slideOut.Completed:Connect(function()
            selectedPage.Visible = false
            selectedPage.Position = UDim2.new(0, 0, 0, 0)
        end)
    end

    -- Show new page with slide animation
    page.Position = UDim2.new(1, 0, 0, 0)
    page.Visible = true
    local slideIn = TweenService:Create(page, constants.slideLength, {
        Position = UDim2.new(0, 0, 0, 0)
    })
    slideIn:Play()

    -- Update tab appearance
    tab.BackgroundColor3 = constants.colors.tabSelected
    tab.Icon.ImageColor3 = constants.colors.iconSelected

    -- Update status with enhanced formatting
    local statusText = page.Name:gsub("(%u)", function(c) 
        return " " .. c 
    end):gsub("^%s+", "")
    oh.setStatus(statusText)
    
    selectedTab = tab
    selectedPage = page
    
    -- Trigger page-specific initialization if available
    if page:FindFirstChild("Initialize") then
        require(page.Initialize)()
    end
    
    return true
end

-- Enhanced tab setup with better animations and interactions
for _, tab in pairs(Tabs:GetChildren()) do
    if tab:IsA("ImageButton") then
        -- Create enhanced animations
        local selected = TweenService:Create(tab, constants.fadeLength, { 
            BackgroundColor3 = constants.colors.tabSelected 
        })
        local unselected = TweenService:Create(tab, constants.fadeLength, { 
            BackgroundColor3 = constants.colors.tabUnselected 
        })
        local hover = TweenService:Create(tab, constants.fadeLength, { 
            BackgroundColor3 = constants.colors.tabHover 
        })
        
        local iconSelected = TweenService:Create(tab.Icon, constants.fadeLength, { 
            ImageColor3 = constants.colors.iconSelected 
        })
        local iconUnselected = TweenService:Create(tab.Icon, constants.fadeLength, { 
            ImageColor3 = constants.colors.iconUnselected 
        })
        local iconHover = TweenService:Create(tab.Icon, constants.fadeLength, { 
            ImageColor3 = constants.colors.iconHover 
        })

        animationCache[tab] = {
            selected = selected,
            unselected = unselected,
            hover = hover,
            iconSelected = iconSelected,
            iconUnselected = iconUnselected,
            iconHover = iconHover
        }

        -- Click handling
        tab.MouseButton1Click:Connect(function()
            if selectedTab ~= tab and Tabs:FindFirstChild(tab.Name) then
                selectTab(tab.Name)
            end
        end)

        -- Enhanced hover effects
        tab.MouseEnter:Connect(function()
            if selectedPage ~= Pages:FindFirstChild(tab.Name) then
                hover:Play()
                iconHover:Play()
            end
        end)

        tab.MouseLeave:Connect(function()
            if selectedPage ~= Pages:FindFirstChild(tab.Name) then
                unselected:Play()
                iconUnselected:Play()
            end
        end)
        
        -- Add tooltip on hover
        local tooltip
        tab.MouseEnter:Connect(function()
            wait(1) -- Delay before showing tooltip
            if tab:IsDescendantOf(game) then
                tooltip = Instance.new("TextLabel")
                tooltip.Name = "Tooltip"
                tooltip.BackgroundColor3 = Color3.fromRGB(33, 33, 33)
                tooltip.BorderColor3 = Color3.fromRGB(65, 65, 65)
                tooltip.BorderSizePixel = 1
                tooltip.Size = UDim2.new(0, 100, 0, 25)
                tooltip.Position = UDim2.new(0, tab.AbsolutePosition.X, 0, tab.AbsolutePosition.Y - 30)
                tooltip.Text = tab.Name
                tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
                tooltip.TextSize = 12
                tooltip.Font = Enum.Font.SourceSans
                tooltip.Parent = Base
                
                -- Fade in tooltip
                tooltip.BackgroundTransparency = 1
                tooltip.TextTransparency = 1
                TweenService:Create(tooltip, constants.fadeLength, {
                    BackgroundTransparency = 0,
                    TextTransparency = 0
                }):Play()
            end
        end)
        
        tab.MouseLeave:Connect(function()
            if tooltip then
                TweenService:Create(tooltip, constants.fadeLength, {
                    BackgroundTransparency = 1,
                    TextTransparency = 1
                }).Completed:Connect(function()
                    tooltip:Destroy()
                    tooltip = nil
                end)
            end
        end)
    end
end

-- Keyboard shortcuts for tab navigation
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Ctrl+Tab for next tab
    if input.KeyCode == Enum.KeyCode.Tab and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local tabs = {}
        for _, tab in pairs(Tabs:GetChildren()) do
            if tab:IsA("ImageButton") then
                table.insert(tabs, tab)
            end
        end
        
        if #tabs > 0 then
            local currentIndex = table.find(tabs, selectedTab) or 1
            local nextIndex = (currentIndex % #tabs) + 1
            selectTab(tabs[nextIndex].Name)
        end
    end
    
    -- Ctrl+Shift+Tab for previous tab
    if input.KeyCode == Enum.KeyCode.Tab and 
       UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 
       UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        
        local tabs = {}
        for _, tab in pairs(Tabs:GetChildren()) do
            if tab:IsA("ImageButton") then
                table.insert(tabs, tab)
            end
        end
        
        if #tabs > 0 then
            local currentIndex = table.find(tabs, selectedTab) or 1
            local prevIndex = currentIndex == 1 and #tabs or currentIndex - 1
            selectTab(tabs[prevIndex].Name)
        end
    end
    
    -- Alt+Left for tab history back
    if input.KeyCode == Enum.KeyCode.Left and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
        if #tabHistory > 0 then
            local previousTab = table.remove(tabHistory)
            selectTab(previousTab, false)
        end
    end
end)

-- Enhanced utility functions
function TabSelector.SelectTab(tabName)
    return selectTab(tabName)
end

function TabSelector.GetSelectedTab()
    return selectedTab and selectedTab.Name
end

function TabSelector.GetTabHistory()
    return tabHistory
end

function TabSelector.ClearHistory()
    tabHistory = {}
end

function TabSelector.IsTabAvailable(tabName)
    local methodsFound = requiredMethods[tabName]
    if not methodsFound then return true end
    
    local missingMethods = methodsCheck(methodsFound)
    return missingMethods == nil
end

function TabSelector.GetAvailableTabs()
    local available = {}
    for _, tab in pairs(Tabs:GetChildren()) do
        if tab:IsA("ImageButton") and TabSelector.IsTabAvailable(tab.Name) then
            table.insert(available, tab.Name)
        end
    end
    return available
end

return TabSelector