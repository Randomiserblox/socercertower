-- ULTIMATE SPY (Copy Per Log, No Lag)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UltSpyGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 500, 0, 300)
Frame.Position = UDim2.new(0, 20, 0, 80) -- Moved to top left so it doesn't block you
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0, 255, 255)
Frame.Parent = ScreenGui
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Text = " Ultimate Spy (Click 📋 to Copy)"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.Parent = Frame

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -30, 0, 0)
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Text = "-"
MinBtn.Font = Enum.Font.SourceSansBold
MinBtn.TextSize = 20
MinBtn.Parent = Frame

local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Frame.Size = UDim2.new(0, 150, 0, 30)
        MinBtn.Text = "+"
        for _, v in pairs(Frame:GetChildren()) do
            if v ~= Title and v ~= MinBtn then v.Visible = false end
        end
    else
        Frame.Size = UDim2.new(0, 500, 0, 300)
        MinBtn.Text = "-"
        for _, v in pairs(Frame:GetChildren()) do
            if v ~= Title and v ~= MinBtn then v.Visible = true end
        end
    end
end)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 80, 0, 25)
ToggleBtn.Position = UDim2.new(0, 10, 0, 40)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "Start"
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = Frame

local CopyAllBtn = Instance.new("TextButton")
CopyAllBtn.Size = UDim2.new(0, 80, 0, 25)
CopyAllBtn.Position = UDim2.new(0, 100, 0, 40)
CopyAllBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
CopyAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyAllBtn.Text = "Copy All"
CopyAllBtn.Font = Enum.Font.SourceSansBold
CopyAllBtn.TextSize = 12
CopyAllBtn.Parent = Frame

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 80, 0, 25)
ClearBtn.Position = UDim2.new(0, 190, 0, 40)
ClearBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.Text = "Clear"
ClearBtn.Font = Enum.Font.SourceSansBold
ClearBtn.TextSize = 12
ClearBtn.Parent = Frame

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -80)
ScrollFrame.Position = UDim2.new(0, 10, 0, 75)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ScrollFrame.BackgroundTransparency = 0.5
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.Parent = Frame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = ScrollFrame
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 2)

local isSpying = false
local fullLog = ""

ToggleBtn.MouseButton1Click:Connect(function()
    isSpying = not isSpying
    ToggleBtn.Text = isSpying and "Stop" or "Start"
    ToggleBtn.BackgroundColor3 = isSpying and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 150, 0)
end)

ClearBtn.MouseButton1Click:Connect(function()
    for _, v in pairs(ScrollFrame:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    fullLog = ""
end)

CopyAllBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(fullLog)
        CopyAllBtn.Text = "Copied!"
        task.wait(1)
        CopyAllBtn.Text = "Copy All"
    end
end)

local function parseArgs(...)
    local args = {...}
    local parsed = {}
    for i, v in ipairs(args) do
        if type(v) == "string" then
            table.insert(parsed, '"' .. v .. '"')
        elseif type(v) == "Instance" then
            table.insert(parsed, v.Name)
        elseif type(v) == "table" then
            local tblStr = "{"
            local count = 0
            for k, val in pairs(v) do
                if count >= 4 then tblStr = tblStr .. "..."; break end
                tblStr = tblStr .. tostring(k) .. "=" .. tostring(val) .. ", "
                count = count + 1
            end
            table.insert(parsed, tblStr .. "}")
        else
            table.insert(parsed, tostring(v))
        end
    end
    return table.concat(parsed, ", ")
end

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if isSpying and not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
        if typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction")) then
            
            local name = string.lower(self.Name)
            -- Filter out spammy remotes so game doesn't freeze
            if not (name:find("movement") or name:find("character") or name:find("ping") or name:find("mouse") or name:find("camera")) then
                
                local args = {...}
                local argString = parseArgs(...)
                
                -- Format exactly how you would write it in a script
                local codeString = string.format('%s:%s(%s)', self:GetFullName(), method, argString)
                
                task.spawn(function()
                    -- Container for the log line and copy button
                    local LogFrame = Instance.new("Frame")
                    LogFrame.Size = UDim2.new(1, -5, 0, 25)
                    LogFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                    LogFrame.Parent = ScrollFrame
                    
                    local TextLabel = Instance.new("TextLabel")
                    TextLabel.Size = UDim2.new(1, -30, 1, 0)
                    TextLabel.BackgroundTransparency = 1
                    TextLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    TextLabel.Text = codeString
                    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                    TextLabel.Font = Enum.Font.Code
                    TextLabel.TextSize = 11
                    TextLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    TextLabel.Parent = LogFrame
                    
                    local CopyBtn = Instance.new("TextButton")
                    CopyBtn.Size = UDim2.new(0, 25, 0, 25)
                    CopyBtn.Position = UDim2.new(1, -25, 0, 0)
                    CopyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    CopyBtn.Text = "📋"
                    CopyBtn.Font = Enum.Font.SourceSansBold
                    CopyBtn.TextSize = 14
                    CopyBtn.Parent = LogFrame
                    
                    CopyBtn.MouseButton1Click:Connect(function()
                        if setclipboard then
                            setclipboard(codeString)
                            CopyBtn.Text = "✅"
                            task.wait(1)
                            CopyBtn.Text = "📋"
                        end
                    end)
                    
                    fullLog = fullLog .. codeString .. "\n"
                end)
            end
        end
    end
    return oldNamecall(self, ...)
end)

print("Ultimate Spy Loaded.")
