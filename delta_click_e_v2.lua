-- delta_click_e_v3_gui.lua
-- Records click + E, replay with GUI, drag, auto zoom out.

local ClickERecorder = {}
ClickERecorder.__index = ClickERecorder

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local RECORD_FILE = "delta_click_e_v2.json"
local E_KEY = Enum.KeyCode.E
local REJOIN_WAIT = 5
local CLICK_RANGE = 12
local ZOOM_DISTANCE = 128

local function now() return os.clock() end
local function serialize(v) return { X = v.X, Y = v.Y, Z = v.Z } end
local function deserialize(t) return Vector3.new(t.X, t.Y, t.Z) end
local function serializeCFrame(cf)
    return { pos = serialize(cf.Position), look = serialize(cf.LookVector), right = serialize(cf.RightVector), up = serialize(cf.UpVector) }
end
local function deserializeCFrame(t)
    return CFrame.fromMatrix(deserialize(t.pos), deserialize(t.right), deserialize(t.up))
end

local function forceZoomOut(distance)
    distance = distance or ZOOM_DISTANCE
    local plr = Players.LocalPlayer
    if not plr then return end
    pcall(function()
        plr.CameraMaxZoomDistance = distance
        plr.CameraMinZoomDistance = distance
    end)
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then cam.FieldOfView = 70 end
    end)
end

-- ============ GUI ============
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

-- ============ CORE ============
function ClickERecorder.new()
    local self = setmetatable({}, ClickERecorder)
    self.recording = false
    self.replaying = false
    self.startTime = 0
    self.duration = 0
    self.events = {}
    self.rejoinCount = 0
    self.sessionId = tostring(os.time())
    self.connections = {}
    return self
end

function ClickERecorder:updateStatus()
    if self.gui and self.gui.status then
        if self.recording then
            self.gui.status.Text = string.format("Recording | %d events", #self.events)
        elseif self.replaying then
            self.gui.status.Text = string.format("Replaying | %d events", #self.events)
        else
            self.gui.status.Text = string.format("Idle | %d events", #self.events)
        end
    end
end

function ClickERecorder:startRecording()
    self.events = {}
    self.startTime = now()
    self.recording = true
    self.replaying = false
    self.duration = 0
    self:updateStatus()
    print("[ClickE2] Recording started | session " .. self.sessionId)
end

function ClickERecorder:stopRecording()
    self.recording = false
    self.duration = now() - self.startTime
    local data = { session = self.sessionId, duration = self.duration, events = self.events, rejoinCount = self.rejoinCount }
    local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
    if ok then
        writefile(RECORD_FILE, encoded)
        print("[ClickE2] Saved: " .. RECORD_FILE .. " | events: " .. #self.events)
    else
        warn("[ClickE2] Encode failed")
    end
    self:updateStatus()
end

function ClickERecorder:loadRecording()
    if not isfile(RECORD_FILE) then warn("[ClickE2] No file") return false end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(RECORD_FILE)) end)
    if not ok or not data then warn("[ClickE2] Decode failed") return false end
    self.events = data.events or {}
    self.duration = data.duration or 0
    self.sessionId = data.session or self.sessionId
    self.rejoinCount = data.rejoinCount or 0
    print("[ClickE2] Loaded " .. #self.events .. " events")
    self:updateStatus()
    return true
end

function ClickERecorder:getRoot()
    local plr = Players.LocalPlayer
    if not plr or not plr.Character then return nil end
    return plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChildWhichIsA("BasePart")
end

function ClickERecorder:captureEvent(kind)
    if not self.recording then return end
    local plr = Players.LocalPlayer
    local mouse = plr and plr:GetMouse()
    local target = mouse and mouse.Target
    local hit = mouse and mouse.Hit
    local root = self:getRoot()
    if kind == "click" and not target then return end
    local entry = {
        kind = kind,
        t = now() - self.startTime,
        session = self.sessionId,
        playerCFrame = root and serializeCFrame(root.CFrame) or nil,
        targetName = target and target:GetFullName() or nil,
        targetPos = target and serialize(target.Position) or nil,
        hitPos = hit and serialize(hit.Position) or nil
    }
    table.insert(self.events, entry)
    self:updateStatus()
    print(string.format("[ClickE2] %s t=%.3f target=%s", kind, entry.t, tostring(entry.targetName)))
end

function ClickERecorder:watchInput()
    self.connections.input = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:captureEvent("click")
        elseif input.KeyCode == E_KEY then
            self:captureEvent("e")
        end
    end)
end

function ClickERecorder:findTarget(ev)
    if not ev.targetPos then return nil end
    local want = deserialize(ev.targetPos)
    local best, bestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local root = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
            if root and root.Parent then
                local d = (root.Position - want).Magnitude
                if d <= 8 and d < bestDist then best, bestDist = root, d end
            end
        end
    end
    return best
end

function ClickERecorder:teleportNear(cf)
    local root = self:getRoot()
    if not root then return false end
    return pcall(function()
        local target = deserializeCFrame(cf)
        local offset = (target.LookVector * -1 * CLICK_RANGE) + Vector3.new(0, 3, 0)
        root.CFrame = CFrame.new(target.Position + offset, target.Position)
    end)
end

function ClickERecorder:screenPosOf(part)
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local point, onScreen = cam:WorldToViewportPoint(part.Position)
    if not onScreen then return nil end
    return Vector2.new(point.X, point.Y)
end

function ClickERecorder:realClickAt(pos)
    pcall(function()
        VIM:SendMousePosition(pos)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
end

function ClickERecorder:sendE()
    pcall(function()
        VIM:SendKeyEvent(true, E_KEY, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, E_KEY, false, game)
    end)
end

function ClickERecorder:doClickThenE(ev)
    if ev.playerCFrame then
        self:teleportNear(ev.playerCFrame)
        task.wait(0.2)
    end
    local target = self:findTarget(ev)
    if target then
        local sp = self:screenPosOf(target)
        if sp then
            self:realClickAt(sp)
            task.wait(0.15)
        end
    end
    self:sendE()
    task.wait(0.1)
end

function ClickERecorder:replay()
    if #self.events == 0 then warn("[ClickE2] Nothing to replay") return end
    self.replaying = true
    self.replayStart = now()
    self.eventIndex = 1
    self:updateStatus()
    if self.connections.replay then self.connections.replay:Disconnect() end
    self.connections.replay = RunService.Heartbeat:Connect(function()
        if not self.replaying then return end
        local elapsed = now() - self.replayStart
        while self.eventIndex <= #self.events and self.events[self.eventIndex].t <= elapsed do
            local ev = self.events[self.eventIndex]
            task.spawn(function() self:doClickThenE(ev) end)
            self.eventIndex = self.eventIndex + 1
        end
        if elapsed >= self.duration then
            self.replaying = false
            if self.connections.replay then self.connections.replay:Disconnect() self.connections.replay = nil end
            self:updateStatus()
            print("[ClickE2] Replay finished")
        end
    end)
end

function ClickERecorder:handleRejoin()
    self.rejoinCount = self.rejoinCount + 1
    self:loadRecording()
    task.wait(REJOIN_WAIT)
    self:replay()
    print("[ClickE2] Rejoin #" .. self.rejoinCount .. " handled")
end

function ClickERecorder:watchRejoin()
    self.connections.characterAdded = Players.LocalPlayer.CharacterAdded:Connect(function()
        task.spawn(function() self:handleRejoin() end)
    end)
end

function ClickERecorder:init()
    makeGUI(self)
    self:watchInput()
    self:watchRejoin()
    self:loadRecording()

    forceZoomOut(ZOOM_DISTANCE)
    task.spawn(function()
        while task.wait(2) do
            forceZoomOut(ZOOM_DISTANCE)
        end
    end)

    print("[ClickE2] Ready | GUI loaded")
    return self
end

local recorder = ClickERecorder.new()
recorder:init()
return recorder
