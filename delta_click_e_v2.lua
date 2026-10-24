-- ULTIMATE REMOTE SPY (Auto-Filter, Re-fire, Safe Thread)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UltSpyGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 650, 0, 450)
Frame.Position = UDim2.new(0.5, -325, 0.5, -225)
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
Title.Text = " Ultimate Spy (Click log to Re-fire)"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
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
        Frame.Size = UDim2.new(0, 250, 0, 30)
        MinBtn.Text = "+"
        for _, v in pairs(Frame:GetChildren()) do
            if v ~= Title and v ~= MinBtn then v.Visible = false end
        end
    else
        Frame.Size = UDim2.new(0, 650, 0, 450)
        MinBtn.Text = "-"
        for _, v in pairs(Frame:GetChildren()) do
            if v ~= Title and v ~= MinBtn then v.Visible = true end
        end
    end
end)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 100, 0, 30)
ToggleBtn.Position = UDim2.new(0, 10, 0, 40)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "Start Spy"
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Parent = Frame

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 100, 0, 30)
ClearBtn.Position = UDim2.new(0, 120, 0, 40)
ClearBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.Text = "Clear Log"
ClearBtn.Font = Enum.Font.SourceSansBold
ClearBtn.Parent = Frame

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -90)
ScrollFrame.Position = UDim2.new(0, 10, 0, 80)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ScrollFrame.BackgroundTransparency = 0.5
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = Frame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Parent = ScrollFrame
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local isSpying = false
local logCount = 0

ToggleBtn.MouseButton1Click:Connect(function()
    isSpying = not isSpying
    ToggleBtn.Text = isSpying and "Stop Spy" or "Start Spy"
    ToggleBtn.BackgroundColor3 = isSpying and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 150, 0)
end)

ClearBtn.MouseButton1Click:Connect(function()
    for _, v in pairs(ScrollFrame:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    logCount = 0
end)

-- Safe Table Parser (Prevents game freeze)
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
                if count >= 5 then tblStr = tblStr .. "..."; break end
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
            
            -- Auto-Filter: Ignore spammy UI/Movement remotes that freeze the game
            local name = string.lower(self.Name)
            if not (name:find("movement") or name:find("character") or name:find("ping") or name:find("mouse") or name:find("camera")) then
                
                local args = {...}
                local argString = parseArgs(...)
                local logText = self.Name .. "(" .. argString .. ")"
                
                -- Create clickable log line
                task.spawn(function()
                    local logBtn = Instance.new("TextButton")
                    logBtn.Size = UDim2.new(1, -10, 0, 25)
                    logBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                    logBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
                    logBtn.Text = logText
                    logBtn.TextXAlignment = Enum.TextXAlignment.Left
                    logBtn.Font = Enum.Font.Code
                    logBtn.TextSize = 12
                    logBtn.Parent = ScrollFrame
                    
                    -- Click to Re-fire the remote
                    logBtn.MouseButton1Click:Connect(function()
                        if method == "FireServer" then
                            self:FireServer(table.unpack(args))
                        else
                            self:InvokeServer(table.unpack(args))
                        end
                        logBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
                        task.wait(0.2)
                        logBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                    end)
                    
                    logCount = logCount + 1
                    -- Limit to 100 logs to prevent lag
                    if logCount > 100 then
                        local oldest = ScrollFrame:FindFirstChildWhichIsA("TextButton")
                        if oldest then oldest:Destroy() end
                    end
                end)
            end
        end
    end
    return oldNamecall(self, ...)
end)

print("Ultimate Spy Loaded.")
