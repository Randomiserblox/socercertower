-- delta_click_e_v2.lua
-- Records the unit you clicked + E, then on replay:
-- teleport near the unit, move mouse onto the unit's screen spot, click it, press E.

local ClickERecorder = {}
ClickERecorder.__index = ClickERecorder

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local Workspace = game:GetService("Workspace")

local RECORD_FILE = "delta_click_e_v2.json"
local E_KEY = Enum.KeyCode.E
local REJOIN_WAIT = 5
local CLICK_RANGE = 12
local MAX_RECHECK_TRIES = 15
local RECHECK_INTERVAL = 1

local function now() return os.clock() end
local function serialize(v) return { X = v.X, Y = v.Y, Z = v.Z } end
local function deserialize(t) return Vector3.new(t.X, t.Y, t.Z) end
local function serializeCFrame(cf)
    return { pos = serialize(cf.Position), look = serialize(cf.LookVector), right = serialize(cf.RightVector), up = serialize(cf.UpVector) }
end
local function deserializeCFrame(t)
    return CFrame.fromMatrix(deserialize(t.pos), deserialize(t.right), deserialize(t.up))
end

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
    self.lastRecheck = 0
    self.pending = {}
    return self
end

function ClickERecorder:startRecording()
    self.events = {}
    self.startTime = now()
    self.recording = true
    self.replaying = false
    self.duration = 0
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
        targetClass = target and target.ClassName or nil,
        targetPos = target and serialize(target.Position) or nil,
        hitPos = hit and serialize(hit.Position) or nil
    }
    table.insert(self.events, entry)
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
                if d <= 8 and d < bestDist then
                    best, bestDist = root, d
                end
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
    local ok = pcall(function()
        VIM:SendMousePosition(pos)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
    end)
    if not ok then
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
            task.wait(0.05)
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
        end)
    end
    return ok
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

function ClickERecorder:bindKeys()
    self.connections.manual = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.R then
            if not self.recording then self:startRecording() else self:stopRecording() end
        elseif input.KeyCode == Enum.KeyCode.P then
            self:loadRecording()
            self:replay()
        end
    end)
end

function ClickERecorder:init()
    self:watchInput()
    self:watchRejoin()
    self:bindKeys()
    self:loadRecording()
    print("[ClickE2] Ready | R record, P replay")
    return self
end

local recorder = ClickERecorder.new()
recorder:init()
return recorder
