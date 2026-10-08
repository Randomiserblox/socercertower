local function makeGUI(self)
    local screen = Instance.new("ScreenGui")
    screen.Name = "ClickE_GUI"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local parentOk = pcall(function() screen.Parent = CoreGui end)
    if not parentOk then screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 260, 0, 240)
    main.Position = UDim2.new(0, 20, 0.4, 0)
    main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = screen

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    title.BorderSizePixel = 0
    title.Text = "ClickE Recorder (drag me)"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Active = true
    title.Parent = main
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 8)
    tc.Parent = title

    -- Drag by title bar
    local dragging, dragStart, startPos = false, nil, nil
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 20)
    status.Position = UDim2.new(0, 10, 0, 34)
    status.BackgroundTransparency = 1
    status.Text = "Idle | 0 events"
    status.TextColor3 = Color3.fromRGB(180, 180, 180)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = main

    local function makeBtn(text, y, color, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -20, 0, 32)
        b.Position = UDim2.new(0, 10, 0, y)
        b.BackgroundColor3 = color
        b.BorderSizePixel = 0
        b.Text = text
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.Parent = main
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = b
        b.MouseButton1Click:Connect(cb)
        return b
    end

    local recordBtn = makeBtn("Start Recording", 60, Color3.fromRGB(60, 130, 70), function()
        if self.recording then
            self:stopRecording()
            recordBtn.Text = "Start Recording"
            recordBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 70)
        else
            self:startRecording()
            recordBtn.Text = "Stop Recording"
            recordBtn.BackgroundColor3 = Color3.fromRGB(150, 60, 60)
        end
    end)

    makeBtn("Replay", 100, Color3.fromRGB(60, 90, 150), function()
        self:loadRecording()
        self:replay()
    end)

    makeBtn("Clear File", 140, Color3.fromRGB(120, 80, 40), function()
        pcall(function()
            if isfile(RECORD_FILE) then delfile(RECORD_FILE) end
        end)
        self.events = {}
        self:updateStatus()
    end)

    makeBtn("Hide GUI", 180, Color3.fromRGB(60, 60, 70), function()
        main.Visible = false
    end)

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 40, 0, 40)
    toggle.Position = UDim2.new(0, 10, 0.4, 0)
    toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    toggle.BorderSizePixel = 0
    toggle.Text = "CE"
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 14
    toggle.Visible = false
    toggle.Parent = screen
    local tcc = Instance.new("UICorner")
    tcc.CornerRadius = UDim.new(0, 6)
    tcc.Parent = toggle
    toggle.MouseButton1Click:Connect(function()
        main.Visible = true
        toggle.Visible = false
    end)

    main:GetPropertyChangedSignal("Visible"):Connect(function()
        toggle.Visible = not main.Visible
    end)

    self.gui = { screen = screen, status = status, main = main }
    return screen
end
