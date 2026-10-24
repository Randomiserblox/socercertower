-- ADVANCED REMOTE SPY (Auto-Farm Reverse Engineering)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AdvSpyGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 600, 0, 400)
Frame.Position = UDim2.new(0.5, -300, 0.5, -200)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0, 255, 255)
Frame.Parent = ScreenGui
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.TextColor3 = Color3.fromRGB(0, 255, 255)
Title.Text = " Advanced Remote Spy - Copy & Paste Ready"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 120, 0, 30)
ToggleBtn.Position = UDim2.new(0, 10, 0, 40)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text = "Start Spy"
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.Parent = Frame

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0, 100, 0, 30)
CopyBtn.Position = UDim2.new(0, 140, 0, 40)
CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyBtn.Text = "Copy All"
CopyBtn.Font = Enum.Font.SourceSansBold
CopyBtn.Parent = Frame

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 100, 0, 30)
ClearBtn.Position = UDim2.new(0, 250, 0, 40)
ClearBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.Text = "Clear"
ClearBtn.Font = Enum.Font.SourceSansBold
ClearBtn.Parent = Frame

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, -20, 1, -90)
TextBox.Position = UDim2.new(0, 10, 0, 80)
TextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextBox.BackgroundTransparency = 0.3
TextBox.TextColor3 = Color3.fromRGB(0, 255, 0)
TextBox.Font = Enum.Font.Code
TextBox.TextSize = 12
TextBox.TextXAlignment = Enum.TextXAlignment.Left
TextBox.TextYAlignment = Enum.TextYAlignment.Top
TextBox.MultiLine = true
TextBox.TextEditable = false
TextBox.Text = ""
TextBox.ClearTextOnFocus = false
TextBox.Parent = Frame

local isSpying = false
local fullLog = ""

ToggleBtn.MouseButton1Click:Connect(function()
    isSpying = not isSpying
    ToggleBtn.Text = isSpying and "Stop Spy" or "Start Spy"
    ToggleBtn.BackgroundColor3 = isSpying and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(0, 150, 0)
end)

ClearBtn.MouseButton1Click:Connect(function()
    TextBox.Text = ""
    fullLog = ""
end)

CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(fullLog)
        CopyBtn.Text = "Copied!"
        task.wait(1)
        CopyBtn.Text = "Copy All"
    else
        CopyBtn.Text = "No Clipboard"
    end
end)

-- Advanced Argument Parser (Handles Tables, Instances, etc.)
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
            for k, val in pairs(v) do
                tblStr = tblStr .. tostring(k) .. "=" .. tostring(val) .. ", "
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
        if typeof(self) == "Instance" and (self:IsA("RemoteEvent") or self:IsA("RemoteFunction") or self:IsA("UnreliableRemoteEvent")) then
            
            local args = parseArgs(...)
            local logLine = string.format("%s:%s(%s)\n", self:GetFullName(), method, args)
            
            fullLog = fullLog .. logLine
            TextBox.Text = TextBox.Text .. logLine
            
            -- Auto-scroll to bottom
            TextBox.CursorPosition = #TextBox.Text + 1
        end
    end
    return oldNamecall(self, ...)
end)

print("Advanced Spy Loaded.")
